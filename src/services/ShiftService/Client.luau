--!strict
--!native

-- Services & Modules --
const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Signal = require(ReplicatedStorage.Packages.Signal)
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Red networking --
const ShiftStarted = require(ReplicatedStorage.Network.ShiftStarted):Client()
const ShiftEnded = require(ReplicatedStorage.Network.ShiftEnded):Client()

const ShiftClient = {}

-- Types --
type LocalShiftState = {
	Number: number,
	TimeRemaining: number,
	Active: boolean,
}

-- States --
const State: LocalShiftState = {
	Number = 0,
	TimeRemaining = 0,
	Active = false,
}

ShiftClient.ShiftStarted = Signal.new()
ShiftClient.ShiftEnded = Signal.new()
ShiftClient.TimeUpdated = Signal.new()

-- Incoming from server --
const function OnShiftStarted(ShiftNumber: number)
	State.Number = ShiftNumber
	State.TimeRemaining = GameConfig.Shift.BaseDuration
	State.Active = true

	ShiftClient.ShiftStarted:Fire(ShiftNumber)
end

const function OnShiftEnded(ShiftNumber: number, Survived: boolean)
	State.Active = false
	State.TimeRemaining = 0

	ShiftClient.ShiftEnded:Fire(ShiftNumber, Survived)
end

ShiftStarted:On(OnShiftStarted)
ShiftEnded:On(OnShiftEnded)

-- Local timer --
RunService.RenderStepped:Connect(function(DeltaTime: number)
	if not State.Active then
		return
	end

	State.TimeRemaining = math.max(State.TimeRemaining - DeltaTime, 0)

	ShiftClient.TimeUpdated:Fire(State.TimeRemaining)
end)

-- Reads --
function ShiftClient.GetShiftNumber(): number
	return State.Number
end

function ShiftClient.GetTimeRemaining(): number
	return State.TimeRemaining
end

function ShiftClient.IsActive(): boolean
	return State.Active
end

return ShiftClient
