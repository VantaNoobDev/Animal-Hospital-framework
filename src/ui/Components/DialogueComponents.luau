--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
const Typewrite = require(ReplicatedStorage.UI.Utils.Typewrite)
const View = require(ReplicatedStorage.UI.Views.DialogueView)

const DialogueComponents = {}

local MessageId: number = 0

function DialogueComponents.SendText(Text: string)
	MessageId += 1
	const CurrentMessageId = MessageId

	View.Clear()
	View.Show()

	Typewrite.Type(View.GetTextLabel(), Text, GameConfig.Dialogue.TypewriteDelay):Wait()

	if CurrentMessageId ~= MessageId then
		return
	end

	task.delay(GameConfig.Dialogue.AutoHideDelay, function()
		if CurrentMessageId ~= MessageId then
			return
		end

		View.Hide()
		View.Clear()
	end)
end

function DialogueComponents.Hide()
	MessageId += 1
	View.Hide()
	View.Clear()
end

return DialogueComponents
