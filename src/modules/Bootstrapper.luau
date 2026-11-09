--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Packages = ReplicatedStorage:WaitForChild("Packages")
const Modules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")

const Promise = require(Packages:WaitForChild("Promise"))
const ModuleLoader = require(Modules:WaitForChild("ModuleLoader"))

--[[
	Bootstrapper
	------------
	Requires every ModuleScript under a folder (recursively) and calls `init()` on the ones that
	export it. Modules are loaded and initialised concurrently, so a module must not rely on a
	sibling having finished its init. The returned Promise rejects with the failing module's
	full name if any load or init fails.
]]

const Bootstrapper = {}

function Bootstrapper.initAll(Folder: Folder | Model): any
	const Pending: { any } = {}

	for _, Child in Folder:GetChildren() do
		if Child:IsA("Folder") or Child:IsA("Model") then
			table.insert(Pending, Bootstrapper.initAll(Child))
		elseif Child:IsA("ModuleScript") then
			const Task: any = ModuleLoader.loadAsync(Child)
				:andThen(function(Loaded: any)
					if type(Loaded) == "table" and type(Loaded.init) == "function" then
						return (Loaded.init :: () -> any)()
					end

					return nil
				end)
				:catch(function(Error: any)
					return Promise.reject(`{Child:GetFullName()}: {tostring(Error)}`)
				end)

			table.insert(Pending, Task)
		end
	end

	return Promise.all(Pending)
end

return table.freeze(Bootstrapper)
