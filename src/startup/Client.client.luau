--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")
<<<<<<< HEAD

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
=======
const Require = require(ReplicatedStorage.Shared.Modules.Require) :: any

const Services = Require(ReplicatedStorage, { "Shared", "Services" }) :: any
const Controllers = Require(ReplicatedStorage, { "UI", "Controllers" }) :: any

const PatientService = require(Require(Services, { "PatientService", "PatientServiceClient" })) :: any
const ClassService = require(Require(Services, { "ClassService", "ClassServiceClient" })) :: any
const SanityService = require(Require(Services, { "SanityService", "SanityServiceClient" })) :: any
const ShiftService = require(Require(Services, { "ShiftService", "ShiftServiceClient" })) :: any

const DialogueController = require(Require(Controllers, { "DialogueController" })) :: any

const MultipleAsserts = require(Require(ReplicatedStorage, { "Shared, Modules, MultipleAsserts" })) :: any

MultipleAsserts.All({ PatientService, ClassService, SanityService, ShiftService, DialogueController }, "Not found.")
>>>>>>> 3fb7852 (Revert "Sixth version.")
