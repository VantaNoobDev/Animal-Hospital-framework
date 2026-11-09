--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("ClassLeveledUp", function(ClassId, NewLevel)
	assert(type(ClassId) == "string", "ClassLeveledUp: ClassId must be a string")
	assert(type(NewLevel) == "number", "ClassLeveledUp: NewLevel must be a number")

	return ClassId, NewLevel
end)
