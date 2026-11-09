--!strict
--!native

--// Types
export type ObjectPool<T> = {
	Acquire: (self: ObjectPool<T>) -> T,
	Release: (self: ObjectPool<T>, Object: T) -> (),
	Warm: (self: ObjectPool<T>, Count: number) -> (),
	AvailableCount: (self: ObjectPool<T>) -> number,
	Destroy: (self: ObjectPool<T>) -> (),
}

type ObjectPoolInternal<T> = ObjectPool<T> & {
	_factory: () -> T,
	_reset: ((T) -> ())?,
	_destroy: ((T) -> ())?,
	_maxSize: number?,
	_available: { T },
	_inPool: { [T]: boolean },
	_owned: { [T]: boolean },
	_destroyed: boolean,
}

--// Constructor
const ObjectPool = {}
ObjectPool.__index = ObjectPool

-- Reset runs on every Release. MaxSize (optional) caps how many idle objects are kept; extras are destroyed.
function ObjectPool.new<T>(Factory: () -> T, Reset: ((T) -> ())?, Destroy: ((T) -> ())?, MaxSize: number?): ObjectPool<T>
	assert(MaxSize == nil or MaxSize >= 0, "MaxSize must be >= 0")

	return setmetatable({
		_factory = Factory,
		_reset = Reset,
		_destroy = Destroy,
		_maxSize = MaxSize,
		_available = {},
		_inPool = {},
		-- Weak keys: objects handed out and then lost don't stay alive just because the pool created them
		_owned = setmetatable({}, { __mode = "k" }),
		_destroyed = false,
	}, ObjectPool) :: any
end

--// Internal helpers
const function create<T>(self: ObjectPoolInternal<T>): T
	const Object = self._factory()
	self._owned[Object] = true
	return Object
end

const function isFull<T>(self: ObjectPoolInternal<T>): boolean
	const MaxSize = self._maxSize
	return MaxSize ~= nil and #self._available >= MaxSize
end

--// Pool operations
function ObjectPool.Acquire<T>(self: ObjectPoolInternal<T>): T
	assert(not self._destroyed, "Cannot acquire from a destroyed ObjectPool")

	const Object = table.remove(self._available)
	if Object ~= nil then
		self._inPool[Object] = nil
		return Object
	end

	return create(self)
end

function ObjectPool.Release<T>(self: ObjectPoolInternal<T>, Object: T)
	assert(not self._destroyed, "Cannot release into a destroyed ObjectPool")
	assert(self._owned[Object], "Object does not belong to this ObjectPool")
	assert(not self._inPool[Object], "Object was released twice")

	if self._reset then
		self._reset(Object)
	end

	if isFull(self) then
		self._owned[Object] = nil
		if self._destroy then
			self._destroy(Object)
		end
		return
	end

	self._inPool[Object] = true
	table.insert(self._available, Object)
end

-- Pre-creates idle objects. They come straight from the factory so Reset is not run on them.
function ObjectPool.Warm<T>(self: ObjectPoolInternal<T>, Count: number)
	assert(not self._destroyed, "Cannot warm a destroyed ObjectPool")

	for _ = 1, math.max(0, math.floor(Count)) do
		if isFull(self) then
			break
		end

		const Object = create(self)
		self._inPool[Object] = true
		table.insert(self._available, Object)
	end
end

function ObjectPool.AvailableCount<T>(self: ObjectPoolInternal<T>): number
	return #self._available
end

--// Cleanup
-- Destroys idle objects only. Objects still checked out are the caller's responsibility.
function ObjectPool.Destroy<T>(self: ObjectPoolInternal<T>)
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._destroy then
		for _, Object in self._available do
			self._destroy(Object)
		end
	end

	table.clear(self._available)
	table.clear(self._inPool)
	table.clear(self._owned)
end

return table.freeze(ObjectPool)
