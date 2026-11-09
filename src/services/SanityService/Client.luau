--!strict
--!native

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const Signal = require(ReplicatedStorage.Packages.Signal)
const GameSettings = require(ReplicatedStorage.Shared.Config:WaitForChild("GameConfig"))

-- Red networking --
const SanityChanged = require(ReplicatedStorage.Network.SanityChanged):Client()

const SanityClient = {}

-- Configuration --
const MAX_SANITY: number = GameSettings.Sanity.Max
const WARNING_THRESHOLD: number = GameSettings.Sanity.WarningThreshold
const CRITICAL_THRESHOLD: number = GameSettings.Sanity.CriticalThreshold

-- States --
local CurrentSanity: number = MAX_SANITY
local WasInWarning: boolean = false
local WasInCritical: boolean = false

SanityClient.SanityChanged = Signal.new()
SanityClient.EnteredWarning = Signal.new()
SanityClient.EnteredCritical = Signal.new()
SanityClient.Depleted = Signal.new()

-- Incoming from server --
const function OnSanityChanged(NewValue: number)
	CurrentSanity = NewValue

	const Normalized: number = NewValue / MAX_SANITY

	SanityClient.SanityChanged:Fire(NewValue, Normalized)

	const InWarning: boolean = NewValue <= WARNING_THRESHOLD

	const InCritical: boolean = NewValue <= CRITICAL_THRESHOLD

	if InWarning and not WasInWarning then
		SanityClient.EnteredWarning:Fire()
	end

	if InCritical and not WasInCritical then
		SanityClient.EnteredCritical:Fire()
	end

	WasInWarning = InWarning
	WasInCritical = InCritical

	if NewValue <= 0 then
		SanityClient.Depleted:Fire()
	end
end

SanityChanged:On(OnSanityChanged)

-- Reads --
function SanityClient.GetSanity(): number
	return CurrentSanity
end

function SanityClient.GetNormalized(): number
	return CurrentSanity / MAX_SANITY
end

return SanityClient
