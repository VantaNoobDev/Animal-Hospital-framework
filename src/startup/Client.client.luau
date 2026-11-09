--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- WaitForChild everywhere: on the client, replication is not guaranteed to be finished when this runs
const Shared = ReplicatedStorage:WaitForChild("Shared")
const Modules = Shared:WaitForChild("Modules")

const ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))
const Bootstrapper = require(Modules:WaitForChild("Bootstrapper"))

-- Packet namespaces must exist before any controller touches them.
ModuleLoader.loadDescendants(ReplicatedStorage:WaitForChild("Network"))

-- Every module under Shared.Services is required and its init() is called.
Bootstrapper.initAll(Shared:WaitForChild("Services"))
	:andThen(function()
		print("Client services initialized")
	end)
	:catch(warn)
