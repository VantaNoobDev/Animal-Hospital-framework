--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Red networking --
const ClassDataSynced = require(ReplicatedStorage.Network.ClassDataSynced):Server()
const ClassPurchased = require(ReplicatedStorage.Network.ClassPurchased):Server()
const ClassLeveledUp = require(ReplicatedStorage.Network.ClassLeveledUp):Server()
const PurchaseClass = require(ReplicatedStorage.Network.PurchaseClass)

const ClassService = {}

-- Types --
export type ClassDefinition = {
	read Id: string,
	read Name: string,
	read CostCoins: number?, -- Nil means Robux-only.
	read MaxLevel: number,
	read PerkValuesByLevel: { number }, -- Index 1 = level 1 value.
}

export type PlayerClassData = {
	[string]: { -- ClassId.
		Owned: boolean,
		Level: number,
		Exp: number,
	},
}

export type ReadOnlyPlayerClassData = {
	read [string]: {
		read Owned: boolean,
		read Level: number,
		read Exp: number,
	},
}

-- Definitions --
ClassService.Classes = {
	Intern = {
		Id = "Intern",
		Name = "Intern",
		CostCoins = 0,
		MaxLevel = 1,
		PerkValuesByLevel = { 0 },
	},
	Nurse = {
		Id = "Nurse",
		Name = "Nurse",
		CostCoins = 500,
		MaxLevel = 5,
		PerkValuesByLevel = { 0.05, 0.08, 0.11, 0.14, 0.18 }, -- % faster treatment application.
	},
	Surgeon = {
		Id = "Surgeon",
		Name = "Surgeon",
		CostCoins = 2500,
		MaxLevel = 5,
		PerkValuesByLevel = { 0.10, 0.16, 0.22, 0.28, 0.35 }, -- % reduced chance of a botched OperatingRoom treatment.
	},
	Secretary = {
		Id = "Secretary",
		Name = "Secretary",
		CostCoins = 1200,
		MaxLevel = 5,
		PerkValuesByLevel = { 1, 1, 2, 2, 3 }, -- Extra visible trait revealed at check-in.
	},
} :: { [string]: ClassDefinition }

table.freeze(ClassService.Classes)

-- States --
const PlayerClassData: { [Player]: PlayerClassData } = setmetatable({}, { __mode = "k" }) :: { [Player]: PlayerClassData }

-- Public API --
function ClassService.InitPlayer(Player: Player, SavedData: PlayerClassData?)
	const Data = SavedData or {}

	if GameConfig.Classes.AutoGrantIntern and not Data.Intern then
		Data.Intern = { Owned = true, Level = 1, Exp = 0 }
	end

	PlayerClassData[Player] = Data
	ClassDataSynced:Fire(Player, Data)
end

function ClassService.RemovePlayer(Player: Player)
	PlayerClassData[Player] = nil
end

function ClassService.PurchaseClass(Player: Player, ClassId: string): boolean
	const Data = PlayerClassData[Player]
	const Definition = ClassService.Classes[ClassId]

	if not Data or not Definition then
		return false
	end

	if Data[ClassId] and Data[ClassId].Owned and not GameConfig.Classes.AllowRepurchase then
		return false
	end

	const Entry = { Owned = true, Level = 1, Exp = 0 }
	Data[ClassId] = Entry

	ClassPurchased:Fire(Player, ClassId, Entry)
	return true
end

function ClassService.AddExp(Player: Player, ClassId: string, Amount: number)
	const Data = PlayerClassData[Player]
	if not Data or not Data[ClassId] or not Data[ClassId].Owned then
		return
	end

	const Entry = Data[ClassId]
	const Definition = ClassService.Classes[ClassId]
	if not Definition then
		return
	end

	if Amount < 0 and not GameConfig.Classes.AllowNegativeExp then
		return
	end

	Entry.Exp = math.max(0, Entry.Exp + Amount)

	while Entry.Exp >= GameConfig.Classes.ExpPerLevel and Entry.Level < Definition.MaxLevel do
		Entry.Exp -= GameConfig.Classes.ExpPerLevel
		Entry.Level += 1
		ClassLeveledUp:Fire(Player, ClassId, Entry.Level)
	end
end

PurchaseClass:SetCallback(function(Player: Player, ClassId: string)
	return ClassService.PurchaseClass(Player, ClassId)
end)

function ClassService.GetPerkValue(Player: Player, ClassId: string): number
	const Data = PlayerClassData[Player]
	const Definition = ClassService.Classes[ClassId]

	if not Data or not Definition or not Data[ClassId] or not Data[ClassId].Owned then
		return 0
	end

	const Level = Data[ClassId].Level
	return Definition.PerkValuesByLevel[Level] or 0
end

function ClassService.GetPlayerClassData(Player: Player): ReadOnlyPlayerClassData?
	return PlayerClassData[Player]
end

return ClassService
