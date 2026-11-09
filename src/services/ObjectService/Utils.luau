--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Modules = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Modules")

const NumberUtil = require(Modules:WaitForChild("NumberUtil"))
const RequireUtil = require(Modules:WaitForChild("RequireUtil"))

--[[
	Shared by ObjectServiceServer and ObjectServiceClient so both sides agree on
	where templates live, how values are validated, and how fast clients may interact.
]]

const Utils = {}

--// Constants
Utils.TEMPLATE_PATH = table.freeze({ "Assets", "Objects" }) -- under ReplicatedStorage
Utils.CLIENT_POOL_WARM_COUNT = 5
Utils.INTERACT_RATE_CAPACITY = 5 -- burst size
Utils.INTERACT_RATE_REFILL = 2.5 -- interactions per second

--// Validation
-- Health and damage must be real, positive, finite numbers (rejects NaN, inf, 0, negatives, non-numbers)
function Utils.IsPositiveFinite(Value: unknown): boolean
	return type(Value) == "number" and NumberUtil.IsFinite(Value) and Value > 0
end

--// Lookup
-- Waits for ReplicatedStorage.Assets.Objects and errors with the full path if it is missing.
function Utils.GetTemplateFolder(): Instance
	return RequireUtil.WaitForPath(ReplicatedStorage, Utils.TEMPLATE_PATH)
end

return table.freeze(Utils)
