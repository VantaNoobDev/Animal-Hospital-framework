--!strict
--!native

--// Constants
const DEFAULT_EPSILON = 1e-5

const NumberUtil = {}

--// Validation
function NumberUtil.IsFinite(Value: number): boolean
	return Value == Value and Value > -math.huge and Value < math.huge
end

function NumberUtil.Approximately(A: number, B: number, Epsilon: number?): boolean
	return math.abs(A - B) <= (Epsilon or DEFAULT_EPSILON)
end

--// Math helpers
function NumberUtil.Lerp(A: number, B: number, Alpha: number): number
	return A + (B - A) * Alpha
end

function NumberUtil.MapRange(Value: number, InMin: number, InMax: number, OutMin: number, OutMax: number): number
	assert(InMin ~= InMax, "InMin and InMax must be different")
	return OutMin + (Value - InMin) * (OutMax - OutMin) / (InMax - InMin)
end

--// Formatting helpers
function NumberUtil.RoundTo(Value: number, DecimalPlaces: number): number
	if not NumberUtil.IsFinite(Value) then
		return Value
	end

	const Scale = 10 ^ DecimalPlaces
	return math.round(Value * Scale) / Scale
end

-- 1234567.89 -> "1,234,567" (decimals are dropped, sign is kept)
function NumberUtil.FormatWithCommas(Value: number): string
	if not NumberUtil.IsFinite(Value) then
		return tostring(Value)
	end

	const Whole = math.floor(math.abs(Value))
	const Sign = if Value < 0 and Whole > 0 then "-" else ""
	local Digits = string.format("%d", Whole)

	repeat
		local Replaced: number
		Digits, Replaced = string.gsub(Digits, "^(%d+)(%d%d%d)", "%1,%2")
	until Replaced == 0

	return Sign .. Digits
end

return table.freeze(NumberUtil)
