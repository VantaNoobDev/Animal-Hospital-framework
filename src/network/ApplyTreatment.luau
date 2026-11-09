--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)

-- Network Contract --
return Red.Function("ApplyTreatment", function(PatientId, TreatmentId)
	assert(type(PatientId) == "string", "Expected PatientId to be a string, got " .. typeof(PatientId))
	assert(type(TreatmentId) == "string", "Expected TreatmentId to be a string, got " .. typeof(TreatmentId))

	return PatientId, TreatmentId
end, function(IsValid)
	assert(type(IsValid) == "boolean", "Expected IsValid to be a boolean, got " .. typeof(IsValid))

	return IsValid
end)
