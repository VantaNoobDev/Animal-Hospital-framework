--!strict
--!native

-- Services & Modules --
const Players = game:GetService("Players")
const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Signal = require(ReplicatedStorage.Packages.Signal) :: any
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Red networking --
const SanityChanged = require(ReplicatedStorage.Network.SanityChanged):Server()

const SanityService = {}

-- Types --
type SanityState = {
	Value: number,
	DrainMultiplier: number,
	LastReplicatedValue: number,
}

-- States --
const PlayerSanity: {
	[Player]: SanityState,
} = setmetatable({}, { __mode = "k" }) :: { [Player]: SanityState }

SanityService.SanityDepleted = Signal.new()
SanityService.SanityChanged = Signal.new()

-- Private API --
const function ClampSanity(Value: number): number
	return math.clamp(Value, 0, GameConfig.Sanity.Max)
end

-- Public API --
function SanityService.InitPlayer(Player: Player)
	PlayerSanity[Player] = {
		Value = GameConfig.Sanity.Max,
		DrainMultiplier = 1,
		LastReplicatedValue = GameConfig.Sanity.Max,
	}
	SanityChanged:Fire(Player, GameConfig.Sanity.Max)
end

function SanityService.RemovePlayer(Player: Player)
	PlayerSanity[Player] = nil
end

function SanityService.SetShiftDrainScale(Player: Player, ShiftNumber: number)
	const State = PlayerSanity[Player]

	if not State then
		return
	end

	State.DrainMultiplier = 1 + (ShiftNumber * GameConfig.Sanity.DrainScalePerShift)
end

function SanityService.Restore(Player: Player, Amount: number)
	const State = PlayerSanity[Player]

	if not State then
		return
	end

	State.Value = ClampSanity(State.Value + Amount)
	State.LastReplicatedValue = State.Value

	SanityService.SanityChanged:Fire(Player, State.Value)
	SanityChanged:Fire(Player, State.Value)
end

function SanityService.Drain(Player: Player, Amount: number)
	const State = PlayerSanity[Player]

	if not State then
		return
	end

	State.Value = ClampSanity(State.Value - Amount)

	SanityService.SanityChanged:Fire(Player, State.Value)

	if State.Value <= 0 then
		SanityService.SanityDepleted:Fire(Player)
	end
end

function SanityService.GetSanity(Player: Player): number
	const State = PlayerSanity[Player]

	return if State then State.Value else 0
end

-- Passive sanity loss --
-- The accumulator batches replication so sanity is not sent every Heartbeat.
local ReplicationAccumulator = 0

RunService.Heartbeat:Connect(function(DeltaTime: number)
	if GameConfig.Sanity.PassiveDrainEnabled then
		for Player, State in PlayerSanity do
			if State.Value > 0 then
				SanityService.Drain(
					Player,
					GameConfig.Sanity.BaseDrainPerMinute / 60 * State.DrainMultiplier * DeltaTime
				)
			end
		end
	end

	ReplicationAccumulator += DeltaTime
	if ReplicationAccumulator < GameConfig.Sanity.ReplicationInterval then
		return
	end
	ReplicationAccumulator = 0

	for Player, State in PlayerSanity do
		if math.abs(State.Value - State.LastReplicatedValue) > GameConfig.Sanity.ReplicationEpsilon then
			State.LastReplicatedValue = State.Value
			SanityChanged:Fire(Player, State.Value)
		end
	end
end)

Players.PlayerAdded:Connect(SanityService.InitPlayer)

Players.PlayerRemoving:Connect(SanityService.RemovePlayer)

return SanityService
