--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Red = require(ReplicatedStorage.Packages.Red)


-- Network Contract --
return Red.Event("StartDialogue", function(Payload)
	assert(type(Payload) == "table", "Expected dialogue payload to be a table")
	assert(type(Payload.Text) == "string", "Expected Payload.Text to be a string")

	return Payload
end)
