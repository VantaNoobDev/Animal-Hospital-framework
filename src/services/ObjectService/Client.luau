--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Shared = ReplicatedStorage:WaitForChild("Shared")
const RequireUtil = require(Shared:WaitForChild("Modules"):WaitForChild("RequireUtil"))

const Signal = RequireUtil.Require(ReplicatedStorage, { "Packages", "Signal" })

-- Direct requires (not RequireUtil.Require) so the first-party types below keep working
const ObjectPoolModule = require(Shared:WaitForChild("Modules"):WaitForChild("ObjectPool"))
const Network = require(ReplicatedStorage:WaitForChild("Network"):WaitForChild("ObjectPackets"))
const Utils = require(Shared:WaitForChild("Services"):WaitForChild("ObjectService"):WaitForChild("ObjectServiceUtils"))

-- Types

type ModelPool = ObjectPoolModule.ObjectPool<Model>

type ClientObject = {
	Id: number,
	Name: string,
	Model: Model,
	Health: number,
}

type SpawnObjectData = {
	Id: number,
	Name: string,
	Pivot: CFrame,
	Health: number,
}

type UpdateObjectData = {
	Id: number,
	Health: number,
	Broken: boolean,
}

type SignalLike<T...> = {
	Connect: (self: SignalLike<T...>, Callback: (T...) -> ()) -> any,
	Once: (self: SignalLike<T...>, Callback: (T...) -> ()) -> any,
	Fire: (self: SignalLike<T...>, T...) -> (),
	Wait: (self: SignalLike<T...>) -> T...,
}

const Controller = {
	ObjectSpawned = Signal.new() :: SignalLike<ClientObject>,
	ObjectRemoved = Signal.new() :: SignalLike<number>,
}

-- Private state

const _objects: { [number]: ClientObject } = {}
const _pools: { [string]: ModelPool } = {}

local _templates: Instance? = nil
local _folder: Folder? = nil
local _initialized = false

-- Internal functions

const function createPool(name: string): ModelPool
	assert(_templates, "ObjectService client is not initialized")

	const template = _templates:FindFirstChild(name)

	assert(template and template:IsA("Model"), `Missing client object template: {name}`)

	return ObjectPoolModule.new(function()
		return template:Clone()
	end, function(model: Model)
		model.Parent = nil
		model:PivotTo(CFrame.identity)
		model:SetAttribute("Id", nil)
		model:SetAttribute("Health", template:GetAttribute("Health"))
	end, function(model: Model)
		model:Destroy()
	end)
end

const function getPool(name: string): ModelPool
	const pool = _pools[name]

	if pool then
		return pool
	end

	const newPool = createPool(name)
	newPool:Warm(Utils.CLIENT_POOL_WARM_COUNT)

	_pools[name] = newPool

	return newPool
end

const function spawnObject(data: SpawnObjectData)
	if _objects[data.Id] then
		return
	end

	assert(_folder, "ObjectService client is not initialized")

	const pool = getPool(data.Name)
	const model = pool:Acquire()

	model:SetAttribute("Id", data.Id)
	model:SetAttribute("Health", data.Health)

	model:PivotTo(data.Pivot)
	model.Parent = _folder

	const object: ClientObject = {
		Id = data.Id,
		Name = data.Name,
		Model = model,
		Health = data.Health,
	}

	_objects[data.Id] = object

	Controller.ObjectSpawned:Fire(object)
end

const function updateObject(data: UpdateObjectData)
	const object = _objects[data.Id]

	if not object then
		return
	end

	object.Health = data.Health
	object.Model:SetAttribute("Health", data.Health)

	if data.Broken then
		Controller.despawnObject(data.Id)
	end
end

-- Public API

function Controller.getObject(id: number): ClientObject?
	return _objects[id]
end

function Controller.despawnObject(id: number): ()
	const object = _objects[id]

	if not object then
		return
	end

	_objects[id] = nil

	const pool = _pools[object.Name]

	if pool then
		pool:Release(object.Model)
	else
		object.Model:Destroy()
	end

	Controller.ObjectRemoved:Fire(id)
end

-- Asks the server to interact with an object. The server validates ownership and rate limits it.
function Controller.interact(id: number): ()
	if not _objects[id] then
		return
	end

	Network.packets.InteractWithObject.send(id)
end

function Controller.init(): ()
	if _initialized then
		return
	end

	-- Resolve templates first: if Assets/Objects is missing this errors with the full path
	-- and leaves the controller uninitialized, instead of half-connecting listeners.
	_templates = Utils.GetTemplateFolder()

	_initialized = true

	const folder = Instance.new("Folder")
	folder.Name = "LocalObjects"
	folder.Parent = workspace
	_folder = folder

	Network.packets.SpawnObject.listen(spawnObject)
	Network.packets.UpdateObject.listen(updateObject)

	Network.packets.RemoveObject.listen(function(id: number)
		Controller.despawnObject(id)
	end)
end

return table.freeze(Controller)
