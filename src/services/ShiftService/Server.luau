--!strict
--!native

-- Services & Modules --
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const PatientService = require(script.Parent.Parent.PatientService.PatientServiceServer)
const SanityService = require(script.Parent.Parent.SanityService.SanityServiceServer)
const Signal = require(ReplicatedStorage.Packages.Signal) :: any
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Red networking --
const ShiftStarted = require(ReplicatedStorage.Network.ShiftStarted):Server()
const ShiftEnded = require(ReplicatedStorage.Network.ShiftEnded):Server()

const ShiftService = {}

-- Types --
type ShiftState = {
	Number: number,
	Active: boolean,
	TimeRemaining: number,
	NextSpawnIn: number,
}

export type ReadOnlyShiftState = {
	read Number: number,
	read Active: boolean,
	read TimeRemaining: number,
	read NextSpawnIn: number,
}

-- States --
local CurrentShift: ShiftState? = nil

-- Internal server signals --
ShiftService.ShiftStarted = Signal.new()
ShiftService.ShiftEnded = Signal.new()

-- Private API --
const function GetPatientInterval(ShiftNumber: number): number
	return math.max(GameConfig.Shift.MinimumPatientInterval, GameConfig.Shift.BasePatientInterval * (GameConfig.Shift.IntervalScalePerShift ^ ShiftNumber))
end

const function GetAnomalyChance(ShiftNumber: number): number
	return math.min(GameConfig.Shift.BaseAnomalyChance + (ShiftNumber * GameConfig.Shift.AnomalyChanceScalePerShift), GameConfig.Shift.MaximumAnomalyChance)
end

const function EndShift(Survived: boolean)
	const Shift = CurrentShift

	if not Shift then
		return
	end

	const ShiftNumber = Shift.Number

	Shift.Active = false

	PatientService.ClearAll()

	ShiftService.ShiftEnded:Fire(ShiftNumber, Survived)

	ShiftEnded:FireAll(ShiftNumber, Survived)

	CurrentShift = nil
end

-- Public API --
function ShiftService.StartShift(ShiftNumber: number)
	CurrentShift = {
		Number = ShiftNumber,
		Active = true,
		TimeRemaining = GameConfig.Shift.BaseDuration,
		NextSpawnIn = if GameConfig.Shift.StartPatientImmediately then 0 else GetPatientInterval(ShiftNumber),
	}

	for _, Player in Players:GetPlayers() do
		SanityService.SetShiftDrainScale(Player, ShiftNumber)
	end

	ShiftService.ShiftStarted:Fire(ShiftNumber)

	ShiftStarted:FireAll(ShiftNumber)
end

function ShiftService.Tick(DeltaTime: number)
	const Shift = CurrentShift

	if not Shift or not Shift.Active then
		return
	end

	Shift.TimeRemaining -= DeltaTime
	Shift.NextSpawnIn -= DeltaTime

	if Shift.TimeRemaining <= 0 then
		EndShift(true)
		return
	end

	if Shift.NextSpawnIn <= 0 then
		const AnomalyChance = GetAnomalyChance(Shift.Number)

		PatientService.SpawnPatient(AnomalyChance)

		Shift.NextSpawnIn = GetPatientInterval(Shift.Number)
	end
end

function ShiftService.FailShift()
	EndShift(false)
end

function ShiftService.GetCurrentShift(): ReadOnlyShiftState?
	return CurrentShift
end

-- Sanity depletion automatically fails the shift.
SanityService.SanityDepleted:Connect(function()
	const Shift = CurrentShift

	if Shift and Shift.Active then
		ShiftService.FailShift()
	end
end)

return ShiftService
