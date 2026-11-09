--!strict
--!native

-- Central gameplay configuration.
-- Most balancing should be possible by editing this module only.

const GameConfig = {
	Shift = {
		BaseDuration = 90,
		BasePatientInterval = 8,
		IntervalScalePerShift = 0.92,
		MinimumPatientInterval = 1.5,
		BaseAnomalyChance = 0.15,
		AnomalyChanceScalePerShift = 0.02,
		MaximumAnomalyChance = 0.6,
		StartPatientImmediately = true,
	},

	Sanity = {
		Max = 100,
		WarningThreshold = 40,
		CriticalThreshold = 15,
		BaseDrainPerMinute = 9,
		DrainScalePerShift = 0.03,
		ReplicationInterval = 0.1,
		ReplicationEpsilon = 0.001,
		PassiveDrainEnabled = true,
	},

	Anomalies = {
		MinTraits = 2,
		MaxTraits = 4,
		RedHerringChance = 0.08,
		RedHerringMaxWeight = 0.35,
	},

	Patients = {
		IdPrefix = "Patient_",
		InitialRoom = "CheckIn",
		RequireCheckInBeforeRoom = true,
		RequireCorrectRoomForTreatment = true,
		AllowMultipleCheckInResolutions = false,
		ClearPatientOnSuccessfulTreatment = false,
		RandomSpecies = true,
	},

	Classes = {
		ExpPerLevel = 100,
		AllowRepurchase = false,
		AllowNegativeExp = false,
		AutoGrantIntern = true,
	},

	Dialogue = {
		InitializationDelay = 1,
		AutoHideDelay = 3,
		TypewriteDelay = 0.03,
	},
}

table.freeze(GameConfig)
table.freeze(GameConfig.Anomalies)
table.freeze(GameConfig.Classes)
table.freeze(GameConfig.Dialogue)
table.freeze(GameConfig.Patients)
table.freeze(GameConfig.Sanity)
table.freeze(GameConfig.Shift)
return GameConfig
