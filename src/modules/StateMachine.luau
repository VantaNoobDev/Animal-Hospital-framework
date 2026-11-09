--!strict
--!native

--[[
	StateMachine
	------------
	Small, reusable finite state machine.

	Usage:
		const Machine = StateMachine.new({
			Initial = "Idle",
			States = {
				Idle = {
					Transitions = { "Working" },          -- optional allow-list (nil = any state)
					Events = { Start = "Working" },       -- Machine:Send("Start")
				},
				Working = {
					Guard = function(From) return true end, -- can this state be entered?
					OnEnter = function(Context, From, ...)
						-- Context.Trove is cleaned automatically when this state exits
						Context.Trove:Add(function() print("left Working") end)
					end,
					OnUpdate = function(Context, DeltaTime) end,
					Timeout = { Duration = 5, To = "Idle" }, -- auto transition
				},
			},
		})

		Machine:Start()
		Machine:Transition("Working")
		Machine.Changed:Connect(function(To, From) end)

	Notes:
		- Transitions requested from inside OnEnter/OnExit are queued and run
		  after the current transition finishes (never re-entrant).
		- Callbacks are error-isolated (pcall + warn). Avoid yielding inside them,
		  a yield keeps the machine "busy" and queues further transitions.
		- Destroy() cleans the active state's Trove but does NOT call OnExit.
]]

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Packages = ReplicatedStorage:WaitForChild("Packages")

const Promise = require(Packages:WaitForChild("Promise"))
const Signal = require(Packages:WaitForChild("Signal"))
const Trove = require(Packages:WaitForChild("Trove"))

--// Types
-- (Structural types on purpose: the Wally shims re-export values only, not package types.)
type TroveLike = {
	Add: (self: TroveLike, Object: any, CleanupMethod: string?) -> any,
	Connect: (self: TroveLike, Signal: any, Callback: (...any) -> ...any) -> any,
	AddPromise: (self: TroveLike, Promise: any) -> any,
	Clean: (self: TroveLike) -> (),
	Destroy: (self: TroveLike) -> (),
}

type ConnectionLike = {
	Disconnect: (self: ConnectionLike) -> (),
	Connected: boolean,
}

type ChangedSignal<State> = {
	Connect: (self: ChangedSignal<State>, Callback: (To: State, From: State?) -> ()) -> ConnectionLike,
	Once: (self: ChangedSignal<State>, Callback: (To: State, From: State?) -> ()) -> ConnectionLike,
	Fire: (self: ChangedSignal<State>, To: State, From: State?) -> (),
	Wait: (self: ChangedSignal<State>) -> (State, State?),
	Destroy: (self: ChangedSignal<State>) -> (),
}

export type StateContext<State> = {
	Machine: StateMachine<State>,
	Trove: TroveLike,
	From: State?,
}

export type StateConfig<State> = {
	Transitions: { State }?,
	Events: { [string]: State | (Context: StateContext<State>, ...any) -> State? }?,
	Guard: ((From: State, ...any) -> boolean)?,
	OnEnter: ((Context: StateContext<State>, ...any) -> ())?,
	OnExit: ((Context: StateContext<State>, To: State) -> ())?,
	OnUpdate: ((Context: StateContext<State>, DeltaTime: number) -> ())?,
	Timeout: { Duration: number, To: State }?,
}

export type StateMachineConfig<State> = {
	Initial: State,
	States: { [State]: StateConfig<State> },
	HistorySize: number?,
}

export type StateMachine<State> = {
	Changed: ChangedSignal<State>,
	Start: (self: StateMachine<State>, ...any) -> (),
	Transition: (self: StateMachine<State>, To: State, ...any) -> boolean,
	Send: (self: StateMachine<State>, Event: string, ...any) -> boolean,
	Can: (self: StateMachine<State>, To: State, ...any) -> boolean,
	GetState: (self: StateMachine<State>) -> State?,
	Is: (self: StateMachine<State>, Target: State) -> boolean,
	GetPrevious: (self: StateMachine<State>) -> State?,
	GetHistory: (self: StateMachine<State>) -> { State },
	Update: (self: StateMachine<State>, DeltaTime: number) -> (),
	WaitForState: (self: StateMachine<State>, Target: State, Timeout: number?) -> any,
	Destroy: (self: StateMachine<State>) -> (),
}

type QueuedTransition<State> = {
	To: State,
	Args: { n: number, [number]: any },
}

--// Constants
const DEFAULT_HISTORY_SIZE = 10
const MAX_QUEUE_DRAIN = 64

--// Constructor
const StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new<State>(Config: StateMachineConfig<State>): StateMachine<State>
	assert(Config.States[Config.Initial] ~= nil, `Initial state "{tostring(Config.Initial)}" is not defined`)

	-- Fail fast on typos so a bad config never reaches runtime
	for Name, StateConfig in Config.States do
		for _, Target in StateConfig.Transitions or {} do
			assert(Config.States[Target] ~= nil, `State "{tostring(Name)}" allows unknown transition "{tostring(Target)}"`)
		end

		for Event, Handler in StateConfig.Events or {} do
			if type(Handler) ~= "function" then
				assert(
					Config.States[Handler :: State] ~= nil,
					`State "{tostring(Name)}" event "{Event}" targets unknown state "{tostring(Handler)}"`
				)
			end
		end

		if StateConfig.Timeout then
			assert(StateConfig.Timeout.Duration > 0, `State "{tostring(Name)}" has an invalid Timeout.Duration`)
			assert(
				Config.States[StateConfig.Timeout.To] ~= nil,
				`State "{tostring(Name)}" Timeout targets unknown state "{tostring(StateConfig.Timeout.To)}"`
			)
		end
	end

	const MachineTrove: TroveLike = Trove.new()

	return setmetatable({
		Changed = MachineTrove:Add(Signal.new()),

		_config = Config,
		_machineTrove = MachineTrove,
		_stateTrove = MachineTrove:Add(Trove.new()),
		_context = nil,
		_state = nil,
		_history = {},
		_historySize = math.max(1, Config.HistorySize or DEFAULT_HISTORY_SIZE),
		_queue = {},
		_busy = false,
		_started = false,
		_destroyed = false,
	}, StateMachine) :: any
end

--// Internal helpers
function StateMachine:_call(Label: string, Callback: (...any) -> ...any, ...: any): (boolean, any)
	const Ok, Result = xpcall(Callback :: any, function(Error)
		return debug.traceback(tostring(Error), 2)
	end, ...)

	if not Ok then
		warn(`[StateMachine] {Label} failed:\n{Result}`)
	end

	return Ok, Result
end

function StateMachine:_enter(To: any, From: any, ...: any)
	const ToConfig = self._config.States[To]

	self._state = To
	self._context = {
		Machine = self,
		Trove = self._stateTrove,
		From = From,
	}

	table.insert(self._history, To)
	if #self._history > self._historySize then
		table.remove(self._history, 1)
	end

	if ToConfig.OnEnter then
		self:_call(`{tostring(To)}.OnEnter`, ToConfig.OnEnter, self._context, From, ...)
	end

	-- Only arm the timeout if OnEnter didn't already leave (queued transitions run later, so state is stable here)
	if ToConfig.Timeout and self._state == To then
		const Timeout = ToConfig.Timeout
		self._stateTrove:Add(task.delay(Timeout.Duration, function()
			if not self._destroyed and self._state == To then
				self:Transition(Timeout.To)
			end
		end))
	end
end

function StateMachine:_execute(To: any, ...: any): boolean
	const From = self._state

	if self._destroyed or not self._started or From == nil or From == To then
		return false
	end

	const FromConfig = self._config.States[From]
	const ToConfig = self._config.States[To]

	if FromConfig.Transitions and not table.find(FromConfig.Transitions, To) then
		return false
	end

	if ToConfig.Guard then
		const Ok, Allowed = self:_call(`{tostring(To)}.Guard`, ToConfig.Guard, From, ...)
		if not Ok or Allowed ~= true then
			return false
		end
	end

	self._busy = true

	if FromConfig.OnExit then
		self:_call(`{tostring(From)}.OnExit`, FromConfig.OnExit, self._context, To)
	end

	self._stateTrove:Clean()
	self:_enter(To, From, ...)

	self._busy = false

	self.Changed:Fire(To, From)

	return true
end

function StateMachine:_drain()
	local Processed = 0

	while #self._queue > 0 and not self._destroyed do
		Processed += 1
		if Processed > MAX_QUEUE_DRAIN then
			table.clear(self._queue)
			warn("[StateMachine] Transition queue exceeded limit, possible transition loop")
			return
		end

		const Next: QueuedTransition<any> = table.remove(self._queue, 1) :: any
		self:_execute(Next.To, table.unpack(Next.Args, 1, Next.Args.n))
	end
end

--// Lifecycle
function StateMachine:Start(...: any)
	assert(not self._destroyed, "Cannot start a destroyed StateMachine")
	assert(not self._started, "StateMachine already started")

	self._started = true
	self._busy = true
	self:_enter(self._config.Initial, nil, ...)
	self._busy = false

	self.Changed:Fire(self._config.Initial, nil)
	self:_drain()
end

function StateMachine:Destroy()
	if self._destroyed then
		return
	end

	self._destroyed = true
	table.clear(self._queue)
	self._machineTrove:Destroy() -- cleans state trove, destroys Changed, cancels pending waits
end

--// Transitions
function StateMachine:Transition(To: any, ...: any): boolean
	assert(not self._destroyed, "Cannot transition a destroyed StateMachine")
	assert(self._config.States[To] ~= nil, `Unknown state "{tostring(To)}"`)

	-- Requested mid-transition: queue it (returns true = accepted for later, validated when it runs)
	if self._busy then
		table.insert(self._queue, { To = To, Args = table.pack(...) })
		return true
	end

	const Result = self:_execute(To, ...)
	self:_drain()

	return Result
end

function StateMachine:Send(Event: string, ...: any): boolean
	if self._destroyed or not self._started then
		return false
	end

	const StateConfig = self._config.States[self._state]
	const Handler: any = StateConfig.Events and StateConfig.Events[Event]

	if Handler == nil then
		return false
	end

	if type(Handler) == "function" then
		const Ok, Target = self:_call(`{tostring(self._state)}.Events.{Event}`, Handler, self._context, ...)
		if not Ok or Target == nil then
			return false
		end

		return self:Transition(Target, ...)
	end

	return self:Transition(Handler, ...)
end

function StateMachine:Can(To: any, ...: any): boolean
	if self._destroyed or not self._started or self._config.States[To] == nil or self._state == To then
		return false
	end

	const FromConfig = self._config.States[self._state]
	if FromConfig.Transitions and not table.find(FromConfig.Transitions, To) then
		return false
	end

	const Guard = self._config.States[To].Guard
	if Guard then
		const Ok, Allowed = self:_call(`{tostring(To)}.Guard`, Guard, self._state, ...)
		return Ok and Allowed == true
	end

	return true
end

function StateMachine:Update(DeltaTime: number)
	if self._destroyed or not self._started or self._busy then
		return
	end

	const OnUpdate = self._config.States[self._state].OnUpdate
	if OnUpdate then
		self:_call(`{tostring(self._state)}.OnUpdate`, OnUpdate, self._context, DeltaTime)
		self:_drain()
	end
end

--// Queries
function StateMachine:GetState()
	return self._state
end

function StateMachine:Is(Target: any): boolean
	return self._state == Target
end

function StateMachine:GetPrevious()
	return self._history[#self._history - 1]
end

function StateMachine:GetHistory()
	return table.clone(self._history)
end

--// Async
function StateMachine:WaitForState(Target: any, Timeout: number?)
	assert(self._config.States[Target] ~= nil, `Unknown state "{tostring(Target)}"`)

	local Pending = Promise.new(function(Resolve, _, OnCancel)
		if self._state == Target then
			Resolve(Target)
			return
		end

		local Connection: ConnectionLike? = nil

		Connection = self.Changed:Connect(function(To)
			if To == Target then
				if Connection then
					Connection:Disconnect()
				end
				Resolve(To)
			end
		end)

		OnCancel(function()
			if Connection then
				Connection:Disconnect()
			end
		end)
	end)

	if Timeout then
		Pending = Pending:timeout(Timeout, `Timed out waiting for state "{tostring(Target)}"`)
	end

	return self._machineTrove:AddPromise(Pending)
end

return table.freeze(StateMachine)
