-- 変異3種。出現時にランダムで付き、収入と価格が倍になる。
local Mutations = {}

Mutations.list = {
	{ id = "Gold", multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Metal },
	{ id = "Neon", multiplier = 3, chance = 0.04, color = Color3.fromRGB(60, 255, 230), material = Enum.Material.Neon },
	{ id = "Glitch", multiplier = 5, chance = 0.015, color = Color3.fromRGB(255, 40, 200), material = Enum.Material.Neon },
}

Mutations.byId = {}
for _, m in ipairs(Mutations.list) do
	Mutations.byId[m.id] = m
end

-- 変異なしは nil を返す。レアな変異ほど先に判定する。
function Mutations.roll(): string?
	for i = #Mutations.list, 1, -1 do
		local m = Mutations.list[i]
		if math.random() < m.chance then
			return m.id
		end
	end
	return nil
end

function Mutations.multiplierOf(mutationId: string?): number
	if mutationId and Mutations.byId[mutationId] then
		return Mutations.byId[mutationId].multiplier
	end
	return 1
end

return Mutations
