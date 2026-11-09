--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const PatientDefinitions = require(ReplicatedStorage.Shared.Services.PatientService.PatientServiceUtils)
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

const AnomalyDetectionService = require(script.Parent.Parent.AnomalyService.AnomalyServiceServer)

-- Red networking --
const PatientSpawned = require(ReplicatedStorage.Network.PatientSpawned):Server()
const PatientResolved = require(ReplicatedStorage.Network.PatientResolved):Server()
const AssignRoom = require(ReplicatedStorage.Network.AssignRoom):Server()
const ResolveCheckIn = require(ReplicatedStorage.Network.ResolveCheckIn)
const ApplyTreatment = require(ReplicatedStorage.Network.ApplyTreatment)

const PatientService = {}

-- Types --
export type ActivePatient = {
	read Id: string,
	read Template: PatientDefinitions.PatientTemplate,
	read IsAnomaly: boolean,
	read RolledTraits: { PatientDefinitions.Trait },
	Registered: boolean,
	Treated: boolean,
	AssignedRoom: PatientDefinitions.RoomId,
}

-- States --
local ActivePatients: { [string]: ActivePatient } = {}
local NextPatientId = 0

-- Private API --
const function GenerateId(): string
	NextPatientId += 1

	return GameConfig.Patients.IdPrefix .. tostring(NextPatientId)
end

const function PickRandomSpecies(): PatientDefinitions.PatientTemplate
	const SpeciesList: { PatientDefinitions.PatientTemplate } = {}

	for _, Template in pairs(PatientDefinitions.Species) do
		table.insert(SpeciesList, Template)
	end

	return SpeciesList[math.random(1, #SpeciesList)]
end

-- Validation --
const ValidRooms: { [string]: boolean } = {
	CheckIn = true,
	GeneralCare = true,
	OperatingRoom = true,
	Quarantine = true,
}

const function IsValidRoom(Room: string): boolean
	return ValidRooms[Room] == true
end

-- Public API --
function PatientService.SpawnPatient(AnomalyChance: number): ActivePatient
	local Template
	if GameConfig.Patients.RandomSpecies then
		Template = PickRandomSpecies()
	else
		-- Use a concrete template even when random species are disabled.
		Template = PatientDefinitions.Species.Dog
	end
	const IsAnomaly = math.random() < AnomalyChance

	const Patient: ActivePatient = {
		Id = GenerateId(),
		Template = Template,
		IsAnomaly = IsAnomaly,
		RolledTraits = AnomalyDetectionService.RollTraits(IsAnomaly),
		Registered = false,
		Treated = false,
		AssignedRoom = GameConfig.Patients.InitialRoom :: PatientDefinitions.RoomId,
	}

	ActivePatients[Patient.Id] = Patient

	PatientSpawned:FireAll({
		Id = Patient.Id,
		Species = Template.Species,
		VisibleTraitDescriptions = AnomalyDetectionService.GetVisibleDescriptions(Patient.RolledTraits),
	})

	return Patient
end

function PatientService.ResolveCheckIn(PatientId: string, PlayerAdmitted: boolean): boolean
	const Patient = ActivePatients[PatientId]

	if not Patient then
		warn("PatientService.ResolveCheckIn: unknown patient " .. PatientId)

		return false
	end

	if Patient.Registered and not GameConfig.Patients.AllowMultipleCheckInResolutions then
		return false
	end

	Patient.Registered = true

	local CorrectDecision = (PlayerAdmitted and not Patient.IsAnomaly) or (not PlayerAdmitted and Patient.IsAnomaly)

	return CorrectDecision
end

function PatientService.AssignRoom(PatientId: string, Room: PatientDefinitions.RoomId): boolean
	if not IsValidRoom(Room) then
		return false
	end

	local Patient = ActivePatients[PatientId]

	if not Patient or (GameConfig.Patients.RequireCheckInBeforeRoom and not Patient.Registered) or Patient.Treated then
		return false
	end

	Patient.AssignedRoom = Room

	return Room == Patient.Template.CorrectRoom
end

function PatientService.ApplyTreatment(PatientId: string, TreatmentId: PatientDefinitions.TreatmentId): boolean
	const Patient = ActivePatients[PatientId]

	if not Patient or (GameConfig.Patients.RequireCheckInBeforeRoom and not Patient.Registered) or Patient.Treated then
		return false
	end

	if GameConfig.Patients.RequireCorrectRoomForTreatment and Patient.AssignedRoom ~= Patient.Template.CorrectRoom then
		return false
	end

	const IsValid = table.find(Patient.Template.ValidTreatments, TreatmentId) ~= nil

	if IsValid then
		Patient.Treated = true
		if GameConfig.Patients.ClearPatientOnSuccessfulTreatment then
			task.defer(PatientService.ClearPatient, PatientId)
		end
	end

	return IsValid
end

function PatientService.GetPatient(PatientId: string): ActivePatient?
	return ActivePatients[PatientId]
end

function PatientService.ClearPatient(PatientId: string)
	if not ActivePatients[PatientId] then
		return
	end

	ActivePatients[PatientId] = nil

	PatientResolved:FireAll(PatientId)
end

function PatientService.ClearAll()
	const PatientIds = {}

	for PatientId in ActivePatients do
		table.insert(PatientIds, PatientId)
	end

	ActivePatients = {}

	for _, PatientId in PatientIds do
		PatientResolved:FireAll(PatientId)
	end
end

-- Red Functions --
ResolveCheckIn:SetCallback(function(Player: Player, PatientId: string, PlayerAdmitted: boolean)
	warn(Player.Name .. " has resolved the check in.")
	return PatientService.ResolveCheckIn(PatientId, PlayerAdmitted)
end)

ApplyTreatment:SetCallback(function(Player: Player, PatientId: string, TreatmentId: string)
	warn(Player.Name .. " has applied treatment.")
	return PatientService.ApplyTreatment(PatientId, TreatmentId :: PatientDefinitions.TreatmentId)
end)

-- Red Events --
AssignRoom:On(function(Player: Player, PatientId: string, Room: string)
	if not IsValidRoom(Room) then
		warn("PatientService.AssignRoom: invalid room from " .. Player.Name)
		return
	end

	warn(Player.Name .. " has assigned a room.")
	PatientService.AssignRoom(PatientId, Room :: PatientDefinitions.RoomId)
end)

return PatientService
