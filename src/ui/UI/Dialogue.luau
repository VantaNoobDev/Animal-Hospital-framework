--!strict
--!native

const RunService = game:GetService("RunService")
const ServerStorage = game:GetService("ServerStorage")

if not RunService:IsServer() then
	return {}
end

const Dialogue = {}

function Dialogue:Initialize(Player: Player)
	const Template = ServerStorage:WaitForChild("UIs"):WaitForChild("DialogueTemplate") :: ScreenGui

	const Clone = Template:Clone()
	Clone.Enabled = false
	Clone.Name = "DialogueUI"
	Clone.Parent = Player:WaitForChild("PlayerGui")
end

return Dialogue
