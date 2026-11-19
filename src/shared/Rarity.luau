-- 6段階のレア度。order が大きいほど希少。weight は野良スポーン時の重み、belt はベルトで買えるか。
local Rarity = {}

Rarity.list = {
	{ name = "Common", order = 1, color = Color3.fromRGB(235, 235, 235), weight = 52, belt = true, tierCost = 0 },
	{ name = "Rare", order = 2, color = Color3.fromRGB(70, 150, 255), weight = 26, belt = true, tierCost = 500 },
	{ name = "Epic", order = 3, color = Color3.fromRGB(180, 90, 255), weight = 13, belt = true, tierCost = 6000 },
	{ name = "Legendary", order = 4, color = Color3.fromRGB(255, 200, 40), weight = 6, belt = false, tierCost = 70000 },
	{ name = "Mythic", order = 5, color = Color3.fromRGB(255, 90, 200), weight = 2.5, belt = false, tierCost = 700000 },
	{ name = "Secret", order = 6, color = Color3.fromRGB(20, 20, 20), weight = 0.5, belt = false, tierCost = 6000000 },
}

Rarity.byName = {}
for _, r in ipairs(Rarity.list) do
	Rarity.byName[r.name] = r
end

function Rarity.pickWeighted(maxOrder: number?, beltOnly: boolean?)
	local total = 0
	for _, r in ipairs(Rarity.list) do
		if (not maxOrder or r.order <= maxOrder) and (not beltOnly or r.belt) then
			total += r.weight
		end
	end
	local roll = math.random() * total
	for _, r in ipairs(Rarity.list) do
		if (not maxOrder or r.order <= maxOrder) and (not beltOnly or r.belt) then
			roll -= r.weight
			if roll <= 0 then
				return r
			end
		end
	end
	return Rarity.list[1]
end

return Rarity
