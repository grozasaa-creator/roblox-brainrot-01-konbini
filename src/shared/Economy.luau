-- 収入・価格・転生・ブーツ・レア度解放の計算。全てここに集める（サーバー・クライアント共通）。
local Config = require(script.Parent.Config)
local Characters = require(script.Parent.Characters)
local Mutations = require(script.Parent.Mutations)
local Rarity = require(script.Parent.Rarity)

local Economy = {}

function Economy.rebirthMultiplier(rebirths: number): number
	return 1 + Config.REBIRTH_BONUS * rebirths
end

function Economy.incomePerSecond(charId: string, mutationId: string?, rebirths: number): number
	local def = Characters.byId[charId]
	return def.income * Mutations.multiplierOf(mutationId) * Economy.rebirthMultiplier(rebirths)
end

function Economy.price(charId: string, mutationId: string?): number
	local def = Characters.byId[charId]
	return math.floor(def.income * Mutations.multiplierOf(mutationId) * Config.PRICE_PER_INCOME)
end

function Economy.rebirthCost(rebirths: number): number
	return Config.REBIRTH_BASE_COST * (rebirths + 1)
end

function Economy.bootsCost(level: number): number
	return Config.BOOTS_BASE_COST * (4 ^ level)
end

function Economy.walkSpeed(bootsLevel: number): number
	return Config.WALK_SPEED + Config.BOOTS_SPEED_PER_LEVEL * bootsLevel
end

-- 次に解放できるレア度の価格。全部解放済みなら nil。
function Economy.nextTierCost(tier: number): number?
	local nextRarity = Rarity.list[tier + 1]
	if not nextRarity then
		return nil
	end
	return nextRarity.tierCost
end

function Economy.formatMoney(n: number): string
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

return Economy
