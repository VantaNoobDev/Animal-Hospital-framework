--!strict
--!native

<<<<<<< HEAD
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const Modules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")

const ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))
const Bootstrapper = require(Modules:WaitForChild("Bootstrapper"))

-- Packet namespaces must exist before any service touches them. Loading the whole
-- folder means new packet files are picked up without editing this script.
ModuleLoader.loadDescendants(ReplicatedStorage:WaitForChild("Network"))

-- Every module under ServerScriptService.Services is required and its init() is called.
Bootstrapper.initAll(ServerScriptService:WaitForChild("Services"))
	:andThen(function()
		print("Server services initialized")
	end)
	:catch(warn)
=======
const Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const Require = require(ReplicatedStorage.Shared:WaitForChild("Modules"):WaitForChild("Require")) :: any

const Services = game:GetService("ServerScriptService").Services

const PatientService = require(Require(Services, { "PatientService", "PatientServiceServer" })) :: any
const SanityService = require(Require(Services, { "SanityService", "SanityServiceServer" })) :: any
const ShiftService = require(Require(Services, { "ShiftService", "ShiftServiceServer" })) :: any
const AnomalyService = require(Require(Services, { "AnomalyService", "AnomalyServiceServer" })) :: any
const ClassService = require(Require(Services, { "ClassService", "ClassServiceServer" })) :: any
const DialogueService = require(Require(Services, { "DialogueService", "DialogueServiceServer" })) :: any

const MultipleAsserts = require(Require(ReplicatedStorage, { "Shared", "Modules", "MultipleAsserts" })) :: any

MultipleAsserts(
	{ PatientService, SanityService, ShiftService, AnomalyService, ClassService, DialogueService },
	"Not found."
)

const function OnPlayerAdded(Player: Player)
	ClassService.InitPlayer(Player)
	SanityService.InitPlayer(Player)
	task.delay(10, function()
		DialogueService.Start(
			Player,
			"This is an _cs_intro_cs_ for the game. It will explain the _rs_basics_rs_ of how to play and what to do."
		)
	end)
end

const function OnPlayerRemoving(Player: Player)
	ClassService.RemovePlayer(Player)
	SanityService.RemovePlayer(Player)
	DialogueService.RemovePlayer(Player)
end

for _, Player in Players:GetPlayers() do
	OnPlayerAdded(Player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

RunService.Heartbeat:Connect(function(DeltaTime: number)
	ShiftService.Tick(DeltaTime)
end)

ShiftService.StartShift(1)
>>>>>>> 3fb7852 (Revert "Sixth version.")
