--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Function("PurchaseClass", function(ClassId)
	assert(type(ClassId) == "string", "PurchaseClass: ClassId must be a string")

	return ClassId
end, function(ClassId)
	if not ClassId then
		return
	end
end)
