--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("PatientResolved", function(PatientId)
	assert(type(PatientId) == "string", "Expected PatientId to be a string, got " .. typeof(PatientId))

	return PatientId
end)
