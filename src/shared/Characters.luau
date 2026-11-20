-- The 15 brainrot characters. Each is a handful of primitive parts stacked above a feet origin (y = 0),
-- facing -Z. `face` places the two eyes; everything else is `parts`.

local Characters = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- part constructors: size then centre offset
local function ball(sx, sy, sz, ox, oy, oz, color, extra)
	return { shape = "Ball", size = Vector3.new(sx, sy, sz), off = Vector3.new(ox, oy, oz), color = color, extra = extra }
end
local function block(sx, sy, sz, ox, oy, oz, color, extra)
	return { shape = "Block", size = Vector3.new(sx, sy, sz), off = Vector3.new(ox, oy, oz), color = color, extra = extra }
end
-- width/height/depth as seen in the world; the builder turns it upright
local function cyl(w, h, d, ox, oy, oz, color, extra)
	return { shape = "Cyl", size = Vector3.new(w, h, d), off = Vector3.new(ox, oy, oz), color = color, extra = extra }
end

Characters.List = {
	{
		id = "potato", name = "Potato Pal", rarity = "Common", income = 1, height = 3.6,
		face = { y = 1.8, z = -1.35, gap = 0.55, size = 0.55 },
		parts = {
			ball(3.0, 2.8, 2.8, 0, 1.5, 0, rgb(185, 135, 82)),
			ball(0.8, 0.8, 0.8, -1.6, 1.3, 0, rgb(170, 120, 70)),
			ball(0.8, 0.8, 0.8, 1.6, 1.3, 0, rgb(170, 120, 70)),
			block(0.35, 0.9, 0.35, 0, 3.1, 0, rgb(90, 190, 90)),
		},
	},
	{
		id = "tofu", name = "Tofu Bro", rarity = "Common", income = 2, height = 3.4,
		face = { y = 1.6, z = -1.25, gap = 0.55, size = 0.5 },
		parts = {
			block(2.5, 2.5, 2.5, 0, 1.3, 0, rgb(248, 243, 228)),
			block(1.1, 0.45, 1.1, 0, 2.75, 0, rgb(130, 78, 46)),
		},
	},
	{
		id = "sandal", name = "Sandal Sensei", rarity = "Common", income = 2, height = 3.8,
		face = { y = 2.3, z = -1.9, gap = 0.5, size = 0.5 },
		parts = {
			block(2.8, 0.8, 4.4, 0, 0.45, 0, rgb(205, 155, 95)),
			block(2.9, 0.6, 0.9, 0, 1.05, -0.4, rgb(70, 100, 215)),
			ball(2.2, 2.2, 2.2, 0, 2.2, -0.8, rgb(245, 205, 155)),
		},
	},
	{
		id = "umbrella", name = "Umbrella Uncle", rarity = "Common", income = 3, height = 5.2,
		face = { y = 3.5, z = -1.9, gap = 0.7, size = 0.6 },
		parts = {
			cyl(0.45, 3.2, 0.45, 0, 1.6, 0, rgb(95, 95, 110)),
			ball(4.4, 2.4, 4.4, 0, 3.7, 0, rgb(85, 165, 255)),
			block(0.5, 0.5, 0.5, 0, 0.3, -0.7, rgb(95, 95, 110)),
		},
	},
	{
		id = "gachaneko", name = "Gacha Neko", rarity = "Rare", income = 8, height = 5.4,
		face = { y = 3.4, z = -1.35, gap = 0.6, size = 0.6 },
		parts = {
			ball(3.0, 2.8, 3.0, 0, 1.4, 0, rgb(255, 150, 200)),
			ball(3.0, 3.0, 3.0, 0, 3.4, 0, rgb(255, 232, 246)),
			block(0.9, 1.1, 0.5, -0.95, 5.0, 0, rgb(255, 150, 200)),
			block(0.9, 1.1, 0.5, 0.95, 5.0, 0, rgb(255, 150, 200)),
		},
	},
	{
		id = "negi", name = "Negi Knight", rarity = "Rare", income = 11, height = 6.2,
		face = { y = 3.4, z = -0.85, gap = 0.5, size = 0.5 },
		parts = {
			cyl(1.8, 1.8, 1.8, 0, 0.9, 0, rgb(250, 250, 245)),
			cyl(1.7, 4.4, 1.7, 0, 3.0, 0, rgb(115, 205, 95)),
			ball(2.4, 1.2, 1.4, 0, 5.6, 0, rgb(60, 150, 70)),
			block(0.4, 2.6, 0.4, 1.4, 3.2, 0, rgb(175, 175, 190)),
		},
	},
	{
		id = "oden", name = "Oden Skewer", rarity = "Epic", income = 15, height = 6.6,
		face = { y = 3.5, z = -1.25, gap = 0.55, size = 0.5 },
		parts = {
			cyl(0.3, 6.6, 0.3, 0, 3.3, 0, rgb(205, 175, 125)),
			ball(2.5, 2.5, 2.5, 0, 1.4, 0, rgb(252, 247, 232)),
			ball(2.5, 2.5, 2.5, 0, 3.5, 0, rgb(215, 165, 105)),
			ball(2.5, 2.5, 2.5, 0, 5.4, 0, rgb(255, 235, 170)),
		},
	},
	{
		id = "ramendragon", name = "Ramen Dragon", rarity = "Epic", income = 40, height = 5.8,
		face = { y = 3.5, z = -1.2, gap = 0.55, size = 0.55 },
		parts = {
			cyl(4.6, 1.8, 4.6, 0, 0.9, 0, rgb(205, 50, 55)),
			block(3.8, 0.6, 3.8, 0, 2.0, 0, rgb(255, 222, 110)),
			ball(2.5, 2.5, 2.5, 0, 3.5, 0, rgb(70, 205, 125)),
			block(0.45, 1.1, 0.45, -0.75, 4.9, 0, rgb(250, 250, 245)),
			block(0.45, 1.1, 0.45, 0.75, 4.9, 0, rgb(250, 250, 245)),
		},
	},
	{
		id = "vendingboss", name = "Vending Boss", rarity = "Legendary", income = 60, height = 7.2,
		face = { y = 6.1, z = -1.45, gap = 0.7, size = 0.6 },
		parts = {
			block(4.2, 6.6, 2.9, 0, 3.5, 0, rgb(225, 45, 55)),
			block(3.1, 3.2, 0.3, 0, 4.0, -1.5, rgb(130, 215, 255), { mat = Enum.Material.Neon }),
			block(1.3, 0.8, 0.3, 0, 1.6, -1.5, rgb(35, 35, 45)),
			block(0.9, 3.2, 0.9, -2.6, 3.9, 0, rgb(205, 42, 52)),
			block(0.9, 3.2, 0.9, 2.6, 3.9, 0, rgb(205, 42, 52)),
		},
	},
	{
		id = "bagghost", name = "Bag Ghost", rarity = "Legendary", income = 80, height = 6.6,
		face = { y = 3.4, z = -1.9, gap = 0.7, size = 0.65 },
		parts = {
			ball(4.2, 4.6, 4.2, 0, 2.9, 0, rgb(250, 250, 255)),
			block(3.4, 1.4, 3.4, 0, 0.8, 0, rgb(238, 238, 248)),
			block(0.3, 1.6, 0.3, -0.7, 5.9, 0, rgb(235, 235, 245)),
			block(0.3, 1.6, 0.3, 0.7, 5.9, 0, rgb(235, 235, 245)),
		},
	},
	{
		id = "karaageking", name = "Karaage King", rarity = "Mythic", income = 250, height = 7.0,
		face = { y = 2.7, z = -2.25, gap = 0.9, size = 0.8 },
		parts = {
			ball(4.8, 4.4, 4.8, 0, 2.4, 0, rgb(218, 152, 62)),
			block(3.2, 0.9, 3.2, 0, 5.0, 0, rgb(255, 215, 0), { mat = Enum.Material.Metal }),
			block(0.7, 1.3, 0.7, -1.1, 6.0, 0, rgb(255, 215, 0), { mat = Enum.Material.Metal }),
			block(0.7, 1.6, 0.7, 0, 6.1, 0, rgb(255, 215, 0), { mat = Enum.Material.Metal }),
			block(0.7, 1.3, 0.7, 1.1, 6.0, 0, rgb(255, 215, 0), { mat = Enum.Material.Metal }),
		},
	},
	{
		id = "signaluncle", name = "Signal Uncle", rarity = "Mythic", income = 500, height = 8.0,
		face = { y = 6.6, z = -0.3, gap = 0.7, size = 0.6 },
		parts = {
			block(2.4, 0.6, 2.4, 0, 0.3, 0, rgb(120, 120, 135)),
			cyl(0.5, 7.0, 0.5, 0, 3.8, 0, rgb(175, 175, 188)),
			block(3.6, 3.4, 0.4, 0, 6.1, 0, rgb(255, 205, 40)),
			block(2.6, 0.7, 0.45, 0, 5.1, -0.02, rgb(35, 35, 40)),
		},
	},
	{
		id = "clerk2am", name = "2AM Clerk", rarity = "Secret", income = 1500, height = 7.0,
		face = { y = 5.4, z = -1.1, gap = 0.55, size = 0.5 },
		parts = {
			block(0.9, 1.7, 0.9, -0.7, 0.85, 0, rgb(40, 40, 65)),
			block(0.9, 1.7, 0.9, 0.7, 0.85, 0, rgb(40, 40, 65)),
			block(2.7, 2.9, 1.7, 0, 3.1, 0, rgb(60, 70, 120)),
			ball(2.3, 2.3, 2.3, 0, 5.4, 0, rgb(255, 218, 185)),
			block(2.5, 0.55, 2.5, 0, 6.5, 0, rgb(235, 60, 85)),
			block(0.9, 0.45, 0.1, 0.7, 3.7, -0.88, rgb(250, 250, 250)),
		},
	},
	{
		id = "spaceonigiri", name = "Space Onigiri", rarity = "Secret", income = 4000, height = 6.2,
		face = { y = 3.2, z = -2.0, gap = 0.8, size = 0.7 },
		parts = {
			ball(4.2, 3.9, 4.2, 0, 2.4, 0, rgb(252, 252, 250)),
			block(3.3, 1.8, 4.3, 0, 1.2, 0, rgb(25, 35, 35)),
			ball(5.4, 5.4, 5.4, 0, 2.9, 0, rgb(185, 232, 255), { mat = Enum.Material.Glass, transparency = 0.6 }),
		},
	},
	{
		id = "open24", name = "Open 24", rarity = "Secret", income = 15000, height = 6.8,
		face = { y = 4.4, z = -0.8, gap = 0.9, size = 0.8 },
		parts = {
			block(0.9, 1.3, 0.9, -1.6, 0.65, 0, rgb(70, 70, 90)),
			block(0.9, 1.3, 0.9, 1.6, 0.65, 0, rgb(70, 70, 90)),
			block(6.2, 5.2, 1.5, 0, 3.9, 0, rgb(255, 255, 255)),
			block(5.6, 0.6, 0.25, 0, 2.5, -0.8, rgb(60, 255, 145), { mat = Enum.Material.Neon }),
			block(5.6, 0.6, 0.25, 0, 1.7, -0.8, rgb(255, 70, 190), { mat = Enum.Material.Neon }),
			ball(0.9, 0.9, 0.9, 0, 6.8, 0, rgb(255, 245, 120), { mat = Enum.Material.Neon }),
		},
	},
}

Characters.ById = {}
Characters.ByRarity = {}
for _, c in ipairs(Characters.List) do
	Characters.ById[c.id] = c
	Characters.ByRarity[c.rarity] = Characters.ByRarity[c.rarity] or {}
	table.insert(Characters.ByRarity[c.rarity], c)
end

function Characters.get(id)
	return Characters.ById[id]
end

return Characters
