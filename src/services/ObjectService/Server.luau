--!strict
--!native

const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Shared = ReplicatedStorage:WaitForChild("Shared")
const RequireUtil = require(Shared:WaitForChild("Modules"):WaitForChild("RequireUtil"))

const Promise = RequireUtil.Require(ReplicatedStorage, { "Packages", "Promise" })
const Signal = RequireUtil.Require(ReplicatedStorage, { "Packages", "Signal" })

-- Direct requires (not RequireUtil.Require) so first-party types keep working
const RateLimiter = require(Shared.Modules.RateLimiter)
const Network = require(ReplicatedStorage.Network.ObjectPackets)
const Utils = require(Shared.Services.ObjectService.ObjectServiceUtils)

-- Types

export type ObjectInfo = {
	Id: number,
	Name: string,
	Pivot: CFrame,
	Health: number,
	MaxHealth: number,
}

type SignalLike<T...> = {
	Connect: (self: SignalLike<T...>, Callback: (T...) -> ()) -> any,
	Once: (self: SignalLike<T...>, Callback: (T...) -> ()) -> any,
	Fire: (self: SignalLike<T...>, T...) -> (),
	Wait: (self: SignalLike<T...>) -> T...,
}

const Server = {
	-- Fired when a client interacts with one of its own objects (validated + rate limited)
	ObjectInteracted = Signal.new() :: SignalLike<Player, ObjectInfo>,
	-- Fired after an object's health reaches 0 and it has been removed
	ObjectBroken = Signal.new() :: SignalLike<Player, ObjectInfo>,
}

-- Private state

-- Weak KEYS: entries disappear with the Player. (The old weak VALUES let the GC delete live registries.)
const _objects = setmetatable({} :: { [Player]: { [number]: ObjectInfo } }, { __mode = "k" })
const _limiter = RateLimiter.new(Utils.INTERACT_RATE_CAPACITY, Utils.INTERACT_RATE_REFILL)

local _templates: Instance? = nil
local _nextObjectId = 0
local _initPromise: any = nil

-- Internal functions

-- Callers get copies so they can't change server state by accident
const function snapshot(object: ObjectInfo): ObjectInfo
	return table.clone(object)
end

const function getTemplate(name: string): Model
	assert(_templates, "ObjectService is not initialized")

	const template = _templates:FindFirstChild(name)

	assert(template and template:IsA("Model"), `Invalid object template: {name}`)

	return template
end

const function getPlayerObjects(player: Player): { [number]: ObjectInfo }
	const objects = _objects[player]

	assert(objects, `No object registry for {player.Name}`)

	return objects
end

const function createObjectInfo(name: string, pivot: CFrame): ObjectInfo
	const template = getTemplate(name)
	const health = template:GetAttribute("Health")

	assert(Utils.IsPositiveFinite(health), `Invalid Health attribute: {name}`)

	_nextObjectId += 1

	return {
		Id = _nextObjectId,
		Name = name,
		Pivot = pivot,
		Health = health :: number,
		MaxHealth = health :: number,
	}
end

const function addPlayer(player: Player)
	if _objects[player] then
		return
	end

	_objects[player] = {}
end

const function removePlayer(player: Player)
	_objects[player] = nil
	_limiter:Remove(player)
end

const function onInteract(id: number, player: Player?)
	if not player or not _limiter:Allow(player) then
		return
	end

	-- Clients can send any id. Only objects registered to THIS player count.
	const objects = _objects[player]
	const object = objects and objects[id]

	if not object then
		return
	end

	Server.ObjectInteracted:Fire(player, snapshot(object))
end

-- Public API

function Server.getObject(player: Player, id: number): ObjectInfo?
	const objects = _objects[player]
	const object = objects and objects[id]

	return if object then snapshot(object) else nil
end

function Server.spawnObject(player: Player, name: string, pivot: CFrame)
	return Promise.try(function()
		local objects = getPlayerObjects(player)
		local object = createObjectInfo(name, pivot)

		objects[object.Id] = object

		Network.packets.SpawnObject.sendTo({
			Id = object.Id,
			Name = object.Name,
			Pivot = object.Pivot,
			Health = object.Health,
		}, player)

		return snapshot(object)
	end)
end

function Server.despawnObject(player: Player, id: number): ()
	const objects = _objects[player]

	if not objects or not objects[id] then
		return
	end

	objects[id] = nil

	Network.packets.RemoveObject.sendTo(id, player)
end

function Server.damageObject(player: Player, id: number, amount: number)
	return Promise.try(function()
		assert(Utils.IsPositiveFinite(amount), "Invalid damage amount")

		const objects = getPlayerObjects(player)
		const object = objects[id]

		-- Broken objects are removed from the registry immediately, so "missing" also covers "already broken"
		assert(object, `Object {id} does not exist`)

		object.Health = math.max(0, object.Health - amount)

		const broken = object.Health <= 0

		Network.packets.UpdateObject.sendTo({
			Id = object.Id,
			Health = object.Health,
			Broken = broken,
		}, player)

		if broken then
			objects[id] = nil
			Server.ObjectBroken:Fire(player, snapshot(object))
		end

		return object.Health
	end)
end

-- Resolves once the service is ready. Rejects (and keeps rejecting) if setup fails, e.g. the
-- template folder is missing, so the problem shows up at startup instead of on first spawn.
function Server.init()
	if _initPromise then
		return _initPromise
	end

	_initPromise = Promise.try(function()
		_templates = Utils.GetTemplateFolder()

		Network.packets.InteractWithObject.listen(onInteract)

		Players.PlayerAdded:Connect(addPlayer)
		Players.PlayerRemoving:Connect(removePlayer)

		for _, player in Players:GetPlayers() do
			addPlayer(player)
		end
	end)

	return _initPromise
end

return table.freeze(Server)
