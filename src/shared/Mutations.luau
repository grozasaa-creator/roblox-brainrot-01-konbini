-- Rare cosmetic mutations that multiply a character's income.

local Mutations = {}

Mutations.None = "None"

Mutations.Defs = {
	Gold   = { mult = 2, chance = 0.08,  tint = Color3.fromRGB(255, 205, 60),  material = Enum.Material.Metal },
	Neon   = { mult = 3, chance = 0.04,  tint = Color3.fromRGB(70, 255, 235),  material = Enum.Material.Neon },
	Glitch = { mult = 5, chance = 0.015, tint = Color3.fromRGB(255, 70, 225),  material = Enum.Material.Neon },
}

-- stable order for rolling so results do not depend on pairs()
Mutations.Order = { "Gold", "Neon", "Glitch" }

function Mutations.multiplier(name)
	local d = Mutations.Defs[name]
	return d and d.mult or 1
end

function Mutations.roll(rng)
	local r = rng:NextNumber()
	local edge = 0
	-- check rarest first so the 1.5% really is 1.5%
	for i = #Mutations.Order, 1, -1 do
		local name = Mutations.Order[i]
		edge += Mutations.Defs[name].chance
		if r < edge then
			return name
		end
	end
	return Mutations.None
end

return Mutations
