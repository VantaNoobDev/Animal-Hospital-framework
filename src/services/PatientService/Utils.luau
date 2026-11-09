--!strict
--!native

const PatientDefinitions = {}

-- Types --

export type TreatmentId = "Bandage" | "Splint" | "Antibiotic" | "Sedative" | "Surgery"

export type RoomId = "CheckIn" | "GeneralCare" | "OperatingRoom" | "Quarantine"

export type Trait = {
	Id: string,
	Description: string,
	Weight: number,
}

export type PatientTemplate = {
	read Species: string,
	read BaseHealth: number,
	read ValidTreatments: { TreatmentId },
	read CorrectRoom: RoomId,
}

-- Species dictionary type.
-- The keys are species names and the values are PatientTemplates.
export type SpeciesMap = {
	[string]: PatientTemplate,
}

-- Patient species --

PatientDefinitions.Species = {
	Dog = {
		Species = "Dog",
		BaseHealth = 100,
		ValidTreatments = {
			"Bandage",
			"Antibiotic",
		},
		CorrectRoom = "GeneralCare",
	} :: PatientTemplate,

	Cat = {
		Species = "Cat",
		BaseHealth = 80,
		ValidTreatments = {
			"Bandage",
			"Sedative",
		},
		CorrectRoom = "GeneralCare",
	} :: PatientTemplate,

	Rabbit = {
		Species = "Rabbit",
		BaseHealth = 60,
		ValidTreatments = {
			"Splint",
			"Antibiotic",
		},
		CorrectRoom = "Quarantine",
	} :: PatientTemplate,

	Bird = {
		Species = "Bird",
		BaseHealth = 40,
		ValidTreatments = {
			"Splint",
		},
		CorrectRoom = "OperatingRoom",
	} :: PatientTemplate,
} :: SpeciesMap

-- Traits --

-- Anomaly patients roll 2-4 traits.
-- Normal patients rarely receive one low-weight red herring.

PatientDefinitions.Traits = {
	{
		Id = "NoBlink",
		Description = "Hasn't blinked the entire check-in",
		Weight = 0.35,
	} :: Trait,

	{
		Id = "WrongShadow",
		Description = "Shadow doesn't match its posture",
		Weight = 0.4,
	} :: Trait,

	{
		Id = "RepeatsPhrase",
		Description = "Repeats the same line if you ask twice",
		Weight = 0.3,
	} :: Trait,

	{
		Id = "ColdToTouch",
		Description = "Temperature reads abnormally low on scan",
		Weight = 0.45,
	} :: Trait,

	{
		Id = "StaresAtCamera",
		Description = "Looks directly at the security camera",
		Weight = 0.5,
	} :: Trait,

	{
		Id = "WrongFileNumber",
		Description = "Intake file number doesn't match the ledger",
		Weight = 0.4,
	} :: Trait,
}

-- Freeze the tables after construction.
table.freeze(PatientDefinitions.Species)
table.freeze(PatientDefinitions.Traits)

return PatientDefinitions
