--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("ClassDataSynced", function(FullData)
	assert(type(FullData) == "table", "Expected FullData to be a table, got " .. typeof(FullData))

	return FullData
end)
