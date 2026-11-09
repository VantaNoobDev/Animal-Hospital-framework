--!strict
--!native

--// Types
export type RateLimiter = {
	Allow: (self: RateLimiter, Key: unknown, Cost: number?) -> boolean,
	Remove: (self: RateLimiter, Key: unknown) -> (),
	Prune: (self: RateLimiter) -> (),
	Clear: (self: RateLimiter) -> (),
}

type Bucket = { Tokens: number, UpdatedAt: number }

type RateLimiterInternal = RateLimiter & {
	_capacity: number,
	_refillPerSecond: number,
	_buckets: { [any]: Bucket },
	_lastPrune: number,
}

--// Constants
const PRUNE_INTERVAL = 30

--// Constructor
const RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(Capacity: number, RefillPerSecond: number): RateLimiter
	assert(Capacity > 0, "Capacity must be positive")
	assert(RefillPerSecond > 0, "RefillPerSecond must be positive")

	return setmetatable({
		_capacity = Capacity,
		_refillPerSecond = RefillPerSecond,
		-- Weak keys so a destroyed Player (or any table key) can't be kept alive by its bucket
		_buckets = setmetatable({}, { __mode = "k" }),
		_lastPrune = os.clock(),
	}, RateLimiter) :: any
end

--// Bucket operations
-- Returns true and spends Cost tokens if the key has enough, otherwise false and nothing is spent.
-- A Cost above Capacity can never be allowed.
function RateLimiter.Allow(self: RateLimiterInternal, Key: unknown, Cost: number?): boolean
	const ActualCost = Cost or 1
	const Now = os.clock()

	if Now - self._lastPrune >= PRUNE_INTERVAL then
		self:Prune()
	end

	local Bucket = self._buckets[Key]

	if Bucket then
		const Elapsed = Now - Bucket.UpdatedAt
		Bucket.Tokens = math.min(self._capacity, Bucket.Tokens + Elapsed * self._refillPerSecond)
		Bucket.UpdatedAt = Now
	else
		Bucket = { Tokens = self._capacity, UpdatedAt = Now }
		self._buckets[Key] = Bucket
	end

	if Bucket.Tokens < ActualCost then
		return false
	end

	Bucket.Tokens -= ActualCost
	return true
end

function RateLimiter.Remove(self: RateLimiterInternal, Key: unknown)
	self._buckets[Key] = nil
end

-- Drops buckets that have fully refilled. This is lossless: a missing bucket starts full anyway.
-- Runs automatically every PRUNE_INTERVAL seconds from Allow.
function RateLimiter.Prune(self: RateLimiterInternal)
	const Now = os.clock()

	for Key, Bucket in self._buckets do
		if Bucket.Tokens + (Now - Bucket.UpdatedAt) * self._refillPerSecond >= self._capacity then
			self._buckets[Key] = nil
		end
	end

	self._lastPrune = Now
end

function RateLimiter.Clear(self: RateLimiterInternal)
	table.clear(self._buckets)
end

return table.freeze(RateLimiter)
