--!strict
--!native

-- Services & Modules --
const ReplicatedStorage = game:GetService("ReplicatedStorage")

const PatientDefinitions = require(ReplicatedStorage.Shared.Services.PatientService.PatientServiceUtils)
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

const AnomalyService = {}

-- Private API --
-- Fisher-Yates keeps the trait selection unbiased before the requested amount is taken.
const function ShuffledTraitPool(): { PatientDefinitions.Trait }
	const Pool = table.clone(PatientDefinitions.Traits)

	for Index = #Pool, 2, -1 do
		const SwapIndex = math.random(1, Index)

		Pool[Index], Pool[SwapIndex] = Pool[SwapIndex], Pool[Index]
	end

	return Pool
end

-- Public API --
function AnomalyService.RollTraits(IsAnomaly: boolean): { PatientDefinitions.Trait }
	const Pool = ShuffledTraitPool()

	if IsAnomaly then
		const Count = math.random(GameConfig.Anomalies.MinTraits, GameConfig.Anomalies.MaxTraits)

		const Rolled: { PatientDefinitions.Trait } = {}

		for Index = 1, math.min(Count, #Pool) do
			table.insert(Rolled, Pool[Index])
		end

		return Rolled
	end

	if math.random() < GameConfig.Anomalies.RedHerringChance then
		const LowWeightPool: { PatientDefinitions.Trait } = {}

		for _, TraitData in Pool do
			if TraitData.Weight <= GameConfig.Anomalies.RedHerringMaxWeight then
				table.insert(LowWeightPool, TraitData)
			end
		end

		if #LowWeightPool > 0 then
			return {
				LowWeightPool[math.random(1, #LowWeightPool)],
			}
		end
	end

	return {}
end

function AnomalyService.GetVisibleDescriptions(Traits: { PatientDefinitions.Trait }): { string }
	const Descriptions: { string } = {}

	for _, TraitData in Traits do
		table.insert(Descriptions, TraitData.Description)
	end

	return Descriptions
end

function AnomalyService.GetSuspicionScore(Traits: { PatientDefinitions.Trait }): number
	local Total: number = 0

	for _, TraitData in Traits do
		Total += TraitData.Weight
	end

	return math.min(Total, 1)
end

return AnomalyService
