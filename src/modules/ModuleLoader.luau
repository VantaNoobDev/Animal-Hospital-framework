-- No strict mode here because require(module) errors and annoys me because it looks ugly.
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Promise = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Promise"))

--[[
	ModuleLoader
	------------
	load*       -> synchronous, returns the module value(s), errors on failure
	load*Async  -> returns a Promise that resolves with the module value(s)

	Everything that takes a parent/instance only loads ModuleScripts and ignores the rest.
]]

const ModuleLoader = {}

--// Internal helpers
const function toModules(Instances: { Instance }): { ModuleScript }
	const Modules = {}

	for _, Item in Instances do
		if Item:IsA("ModuleScript") then
			table.insert(Modules, Item)
		end
	end

	return Modules
end

const function getAncestors(Item: Instance): { Instance }
	const Ancestors = {}
	local Current = Item.Parent

	while Current do
		table.insert(Ancestors, Current)
		Current = Current.Parent
	end

	return Ancestors
end

--// Single module
function ModuleLoader.load(Module: ModuleScript): any
	assert(
		typeof(Module) == "Instance" and Module:IsA("ModuleScript"),
		`Invalid module: expected ModuleScript, got {typeof(Module) == "Instance" and Module.ClassName or typeof(Module)}`
	)

	return require(Module)
end

function ModuleLoader.loadAsync(Module: ModuleScript): any
	return Promise.try(function()
		return ModuleLoader.load(Module)
	end)
end

--// Lists
function ModuleLoader.loadAll(Modules: { ModuleScript }): { any }
	const Loaded = {}

	for _, Module in Modules do
		table.insert(Loaded, ModuleLoader.load(Module))
	end

	return Loaded
end

-- Loads every module at the same time (each in its own Promise).
function ModuleLoader.loadAllAsync(Modules: { ModuleScript }): any
	const Pending: { any } = {}

	for _, Module in Modules do
		const Task: any = ModuleLoader.loadAsync(Module)
		table.insert(Pending, Task)
	end

	return Promise.all(Pending)
end

--// Hierarchy
function ModuleLoader.loadChildren(Parent: Instance): { any }
	return ModuleLoader.loadAll(toModules(Parent:GetChildren()))
end

function ModuleLoader.loadChildrenAsync(Parent: Instance): any
	return ModuleLoader.loadAllAsync(toModules(Parent:GetChildren()))
end

function ModuleLoader.loadDescendants(Parent: Instance): { any }
	return ModuleLoader.loadAll(toModules(Parent:GetDescendants()))
end

function ModuleLoader.loadDescendantsAsync(Parent: Instance): any
	return ModuleLoader.loadAllAsync(toModules(Parent:GetDescendants()))
end

-- Loads every ModuleScript above Instance, nearest parent first.
function ModuleLoader.loadAncestors(Item: Instance): { any }
	return ModuleLoader.loadAll(toModules(getAncestors(Item)))
end

function ModuleLoader.loadAncestorsAsync(Item: Instance): any
	return ModuleLoader.loadAllAsync(toModules(getAncestors(Item)))
end

return table.freeze(ModuleLoader)
