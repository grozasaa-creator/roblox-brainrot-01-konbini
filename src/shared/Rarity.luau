-- Rarity ladder. Index 1 is the lowest. A player's "tier" is the highest index they may catch.

local Rarity = {}

Rarity.List = {
	{ name = "Common",    weight = 52,  color = Color3.fromRGB(190, 200, 215), tierCost = 0 },
	{ name = "Rare",      weight = 26,  color = Color3.fromRGB(80, 165, 255),  tierCost = 500 },
	{ name = "Epic",      weight = 13,  color = Color3.fromRGB(195, 105, 255), tierCost = 6000 },
	{ name = "Legendary", weight = 6,   color = Color3.fromRGB(255, 195, 45),  tierCost = 70000 },
	{ name = "Mythic",    weight = 2.5, color = Color3.fromRGB(255, 85, 105),  tierCost = 700000 },
	{ name = "Secret",    weight = 0.5, color = Color3.fromRGB(60, 255, 205),  tierCost = 6000000 },
}

Rarity.Count = #Rarity.List

function Rarity.get(index)
	return Rarity.List[math.clamp(index, 1, Rarity.Count)]
end

function Rarity.indexOf(name)
	for i, r in ipairs(Rarity.List) do
		if r.name == name then
			return i
		end
	end
	return 1
end

-- weighted pick of a rarity index; rng is a Random
function Rarity.roll(rng)
	local total = 0
	for _, r in ipairs(Rarity.List) do
		total += r.weight
	end
	local pick = rng:NextNumber() * total
	for i, r in ipairs(Rarity.List) do
		pick -= r.weight
		if pick <= 0 then
			return i
		end
	end
	return 1
end

return Rarity
