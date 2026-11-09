--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const StartDialogue = require(ReplicatedStorage.Network.StartDialogue):Client()
const Dialogue = require(script.Parent.Parent.Components.DialogueComponents)
const DialogueMarkup = require(script.Parent.Parent.Utils.DialogueMarkup)

StartDialogue:On(function(Payload)
	if type(Payload) ~= "table" or type(Payload.Text) ~= "string" then
		warn("Received invalid dialogue payload")
		return
	end

	Dialogue.SendText(DialogueMarkup.Format(Payload.Text))
end)

return {}
