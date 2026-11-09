--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("ClassPurchased", function(ClassId, Entry)
	assert(type(ClassId) == "string", "ClassPurchased: ClassId must be a string")
	assert(type(Entry) == "table", "ClassPurchased: Entry must be a table")

	return ClassId, Entry
end)
