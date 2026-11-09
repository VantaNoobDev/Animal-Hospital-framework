--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Signal = require(ReplicatedStorage.Packages.Signal)

-- Red networking --
const ClassDataSynced = require(ReplicatedStorage.Network.ClassDataSynced):Client()
const ClassPurchased = require(ReplicatedStorage.Network.ClassPurchased):Client()
const ClassLeveledUp = require(ReplicatedStorage.Network.ClassLeveledUp):Client()
const PurchaseClass = require(ReplicatedStorage.Network.PurchaseClass)

const ClassClient = {}

-- Types --
export type ClassEntry = {
	Owned: boolean,
	Level: number,
	Exp: number,
}

-- States --
local OwnedClasses: {
	[string]: ClassEntry,
} = {}

ClassClient.ClassPurchased = Signal.new()
ClassClient.ClassLeveledUp = Signal.new()
ClassClient.PurchaseFailed = Signal.new()

-- Incoming from server --
const function OnClassDataSynced(FullData: {})
	OwnedClasses = FullData :: { [string]: ClassEntry }
end

const function OnClassPurchased(ClassId: string, Entry: {})
	OwnedClasses[ClassId] = Entry :: ClassEntry

	ClassClient.ClassPurchased:Fire(ClassId)
end

const function OnClassLeveledUp(ClassId: string, NewLevel: number)
	const Entry = OwnedClasses[ClassId]

	if Entry then
		Entry.Level = NewLevel
	end

	ClassClient.ClassLeveledUp:Fire(ClassId, NewLevel)
end

ClassDataSynced:On(OnClassDataSynced)
ClassPurchased:On(OnClassPurchased)
ClassLeveledUp:On(OnClassLeveledUp)

-- Outgoing requests --
function ClassClient.RequestPurchase(ClassId: string)
	local Success, DidPurchase = PurchaseClass:Call(ClassId):Await()

	if not Success or not DidPurchase then
		ClassClient.PurchaseFailed:Fire(ClassId, "Purchase failed")
		return
	end
end

-- Reads --
function ClassClient.IsOwned(ClassId: string): boolean
	const Entry = OwnedClasses[ClassId]

	return Entry ~= nil and Entry.Owned
end

function ClassClient.GetLevel(ClassId: string): number
	const Entry = OwnedClasses[ClassId]

	return if Entry then Entry.Level else 0
end

function ClassClient.GetAllOwned(): {
	[string]: ClassEntry,
}
	return OwnedClasses
end

return ClassClient
