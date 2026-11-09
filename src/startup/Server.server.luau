--!strict
--!native

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
