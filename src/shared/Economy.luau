-- All money maths in one place so server and client never disagree.

local Characters = require(script.Parent.Characters)
local Mutations = require(script.Parent.Mutations)

local Economy = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

Economy.RebirthBonus = 0.5
Economy.BootsMax = 3
Economy.BootsSpeedEach = 3

-- income per second of one placed character
function Economy.income(charId, mutation, rebirths)
	local def = Characters.get(charId)
	if not def then
		return 0
	end
	local bonus = 1 + Economy.RebirthBonus * (rebirths or 0)
	return def.income * Mutations.multiplier(mutation) * bonus
end

-- the "worth" shown on labels
function Economy.value(charId, mutation)
	local def = Characters.get(charId)
	if not def then
		return 0
	end
	return def.income * Mutations.multiplier(mutation) * 25
end

function Economy.rebirthCost(rebirths)
	return 100000 * (rebirths + 1)
end

function Economy.bootsCost(level)
	return 300 * 4 ^ level
end

function Economy.walkSpeed(baseSpeed, bootsLevel, carrying, carryFactor)
	local s = baseSpeed + bootsLevel * Economy.BootsSpeedEach
	if carrying then
		s *= carryFactor
	end
	return s
end

function Economy.format(n)
	n = math.floor(n + 1e-6)
	if n < 1000 then
		return tostring(n)
	end
	local idx = 1
	local v = n
	while v >= 1000 and idx < #SUFFIXES do
		v /= 1000
		idx += 1
	end
	local text = string.format(v < 10 and "%.2f" or (v < 100 and "%.1f" or "%.0f"), v)
	return text .. SUFFIXES[idx]
end

function Economy.money(n)
	return "$" .. Economy.format(n)
end

return Economy
