--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("ShiftEnded", function(ShiftNumber, Survived)
	assert(type(ShiftNumber) == "number", "ShiftNumber must be a number")
	assert(type(Survived) == "boolean", "Survived must be a boolean")

	return ShiftNumber, Survived
end)
