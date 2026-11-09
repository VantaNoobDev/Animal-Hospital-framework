--!strict
--!native

const TableUtil = {}

--// Internal helpers
const function deepCopy(Value: any, Seen: { [any]: any }): any
	if type(Value) ~= "table" then
		return Value
	end

	-- Shared or cyclic references are copied once and re-used
	const Existing = Seen[Value]
	if Existing ~= nil then
		return Existing
	end

	const Result = {}
	Seen[Value] = Result

	-- Keys are intentionally NOT copied: tables used as keys rely on identity
	for Key, Child in Value do
		Result[Key] = deepCopy(Child, Seen)
	end

	-- Keep class behaviour (methods via __index). Locked metatables return a string, so ignore those.
	const Metatable = getmetatable(Value)
	if type(Metatable) == "table" then
		setmetatable(Result, Metatable)
	end

	return Result
end

const function deepFreeze(Value: any, Seen: { [any]: boolean })
	if type(Value) ~= "table" or Seen[Value] then
		return
	end

	Seen[Value] = true

	for _, Child in Value do
		deepFreeze(Child, Seen)
	end

	if not table.isfrozen(Value) then
		table.freeze(Value)
	end
end

--// Copies
function TableUtil.DeepCopy<T>(Value: T): T
	return deepCopy(Value, {})
end

function TableUtil.ShallowCopy<T>(Value: T & {}): T
	return table.clone(Value)
end

--// Mutation
function TableUtil.DeepFreeze<T>(Value: T): T
	deepFreeze(Value, {})
	return Value
end

--// Inspection
function TableUtil.Count(Dictionary: { [unknown]: unknown }): number
	local Count = 0
	for _ in Dictionary do
		Count += 1
	end
	return Count
end

return table.freeze(TableUtil)
