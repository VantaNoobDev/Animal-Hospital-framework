--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("ShiftStarted", function(ShiftNumber)
	assert(type(ShiftNumber) == "number", "ShiftStarted: ShiftNumber must be a number")

	return ShiftNumber
end)
