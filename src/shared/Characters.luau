-- キャラ名簿（全て独自キャラ）。parts は Part の組み合わせで作る見た目、face は目を付ける位置。
-- s=形(Block/Ball/Cylinder/Wedge) size=大きさ pos=足元基準の位置 rot=回転(度) c=色 m=素材 t=透明度 rainbow=虹色循環
local function V(x, y, z)
	return Vector3.new(x, y, z)
end
local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local Characters = {}

Characters.list = {
	-- Common
	{
		id = "potato", name = "Pom-Pom Potato", rarity = "Common", income = 1,
		face = { pos = V(0, 2.5, 1.45), eye = 0.8 },
		parts = {
			{ s = "Ball", size = V(3, 3.4, 3), pos = V(0, 2, 0), c = C(196, 150, 100), m = Enum.Material.Sand },
			{ s = "Block", size = V(0.3, 1.2, 0.3), pos = V(0, 4.2, 0), c = C(80, 190, 80) },
			{ s = "Ball", size = V(0.9, 0.5, 0.9), pos = V(0.9, 4.6, 0), c = C(80, 190, 80) },
		},
	},
	{
		id = "tofu", name = "Nuru-Nuru Tofu", rarity = "Common", income = 2,
		face = { pos = V(0, 2.1, 1.55), eye = 0.8 },
		parts = {
			{ s = "Block", size = V(3, 3, 3), pos = V(0, 1.6, 0), c = C(248, 246, 236), m = Enum.Material.SmoothPlastic },
			{ s = "Block", size = V(1.2, 0.4, 1.2), pos = V(0, 3.3, 0), c = C(90, 50, 30) },
			{ s = "Block", size = V(0.4, 1.2, 0.4), pos = V(0.5, 2.8, 1.6), c = C(90, 50, 30) },
		},
	},
	{
		id = "sandal", name = "Bururun Sandal", rarity = "Common", income = 2,
		face = { pos = V(0, 1.7, 1.05), eye = 0.6 },
		parts = {
			{ s = "Block", size = V(2.6, 0.8, 5), pos = V(0, 0.4, 0), c = C(60, 120, 200) },
			{ s = "Block", size = V(2.6, 1.8, 1.4), pos = V(0, 1.7, 0.4), c = C(240, 120, 60) },
			{ s = "Block", size = V(0.5, 1.4, 0.5), pos = V(1, 1.6, -1.2), c = C(240, 120, 60) },
			{ s = "Block", size = V(0.5, 1.4, 0.5), pos = V(-1, 1.6, -1.2), c = C(240, 120, 60) },
		},
	},
	{
		id = "umbrella", name = "Mochi Umbrella", rarity = "Common", income = 3,
		face = { pos = V(0, 2.3, 0.5), eye = 0.7 },
		parts = {
			{ s = "Cylinder", size = V(4, 0.6, 0.6), rot = V(0, 0, 90), pos = V(0, 2, 0), c = C(245, 245, 245) },
			{ s = "Ball", size = V(5.6, 3.2, 5.6), pos = V(0, 4.4, 0), c = C(255, 180, 210), m = Enum.Material.SmoothPlastic },
			{ s = "Block", size = V(0.6, 0.6, 1.4), pos = V(0, 0.4, 0.5), c = C(40, 40, 40) },
		},
	},
	-- Rare
	{
		id = "gachaneko", name = "Gacha Neko", rarity = "Rare", income = 8,
		face = { pos = V(0, 4.8, 1.75), eye = 0.9 },
		parts = {
			{ s = "Block", size = V(3, 3, 2.6), pos = V(0, 1.5, 0), c = C(255, 150, 60) },
			{ s = "Ball", size = V(3.8, 3.8, 3.8), pos = V(0, 4.8, 0), c = C(170, 230, 255), m = Enum.Material.Glass, t = 0.35 },
			{ s = "Block", size = V(0.9, 1.1, 0.7), pos = V(-1.2, 6.9, 0), c = C(255, 150, 60) },
			{ s = "Block", size = V(0.9, 1.1, 0.7), pos = V(1.2, 6.9, 0), c = C(255, 150, 60) },
			{ s = "Block", size = V(0.4, 0.4, 2.6), pos = V(0, 0.8, -2), c = C(255, 150, 60) },
		},
	},
	{
		id = "negi", name = "Negi Samurai", rarity = "Rare", income = 11,
		face = { pos = V(0, 4.2, 1.1), eye = 0.7 },
		parts = {
			{ s = "Block", size = V(2.4, 4.4, 2), pos = V(0, 2.2, 0), c = C(240, 240, 235) },
			{ s = "Block", size = V(1.5, 3.8, 1.5), pos = V(0, 6.2, 0), c = C(60, 190, 80), m = Enum.Material.Grass },
			{ s = "Block", size = V(0.3, 0.3, 4.4), pos = V(1.8, 2.6, 0.4), c = C(170, 170, 185), m = Enum.Material.Metal },
			{ s = "Block", size = V(2.6, 0.5, 2.1), pos = V(0, 3.0, 0), c = C(180, 40, 40) },
		},
	},
	{
		id = "oden", name = "Oden Bozu", rarity = "Rare", income = 15,
		face = { pos = V(0, 3.8, 1.35), eye = 0.7 },
		parts = {
			{ s = "Cylinder", size = V(8.4, 0.35, 0.35), rot = V(0, 0, 90), pos = V(0, 4.2, 0), c = C(190, 150, 90) },
			{ s = "Ball", size = V(3, 3, 3), pos = V(0, 1.6, 0), c = C(210, 170, 110) },
			{ s = "Ball", size = V(3.2, 3.2, 3.2), pos = V(0, 4.6, 0), c = C(250, 245, 235) },
			{ s = "Ball", size = V(2.8, 2.8, 2.8), pos = V(0, 7.4, 0), c = C(120, 70, 40) },
		},
	},
	-- Epic
	{
		id = "ramendragon", name = "Ramen Ryu", rarity = "Epic", income = 40,
		face = { pos = V(0, 4.9, 1.6), eye = 0.9 },
		parts = {
			{ s = "Ball", size = V(5, 3.4, 5), pos = V(0, 1.7, 0), c = C(200, 50, 50) },
			{ s = "Ball", size = V(3.4, 3.2, 3.4), pos = V(0, 4.9, 0), c = C(70, 200, 110) },
			{ s = "Block", size = V(0.4, 0.4, 3.6), pos = V(-1.7, 4.4, 2.2), rot = V(0, 20, 0), c = C(255, 220, 90), m = Enum.Material.Neon },
			{ s = "Block", size = V(0.4, 0.4, 3.6), pos = V(1.7, 4.4, 2.2), rot = V(0, -20, 0), c = C(255, 220, 90), m = Enum.Material.Neon },
			{ s = "Block", size = V(0.6, 1.6, 0.6), pos = V(-1, 7, 0), c = C(255, 245, 200) },
			{ s = "Block", size = V(0.6, 1.6, 0.6), pos = V(1, 7, 0), c = C(255, 245, 200) },
		},
	},
	{
		id = "vendingboss", name = "Vending Boss", rarity = "Epic", income = 60,
		face = { pos = V(0, 5.6, 1.6), eye = 1.0 },
		parts = {
			{ s = "Block", size = V(4.4, 7.4, 3), pos = V(0, 3.7, 0), c = C(210, 40, 50), m = Enum.Material.Metal },
			{ s = "Block", size = V(3.4, 2.2, 0.3), pos = V(0, 2.6, 1.55), c = C(90, 220, 255), m = Enum.Material.Neon },
			{ s = "Block", size = V(0.8, 0.3, 0.3), pos = V(1.5, 4.2, 1.55), c = C(30, 30, 30) },
			{ s = "Block", size = V(1.4, 1.4, 0.3), pos = V(0, 0.9, 1.55), c = C(30, 30, 30) },
		},
	},
	{
		id = "bagghost", name = "Reji-bukuro Ghost", rarity = "Epic", income = 80,
		face = { pos = V(0, 3.8, 2), eye = 0.9 },
		parts = {
			{ s = "Ball", size = V(4.2, 5.4, 4.2), pos = V(0, 3.4, 0), c = C(245, 250, 255), m = Enum.Material.Glass, t = 0.25 },
			{ s = "Block", size = V(0.5, 2.2, 0.5), pos = V(-2.4, 4.6, 0), rot = V(0, 0, 20), c = C(245, 250, 255), t = 0.25 },
			{ s = "Block", size = V(0.5, 2.2, 0.5), pos = V(2.4, 4.6, 0), rot = V(0, 0, -20), c = C(245, 250, 255), t = 0.25 },
			{ s = "Block", size = V(3.2, 0.5, 2.4), pos = V(0, 0.4, 0), c = C(160, 220, 200), t = 0.4 },
		},
	},
	-- Legendary
	{
		id = "karaageking", name = "Karaage King", rarity = "Legendary", income = 250, scale = 1.5,
		face = { pos = V(0, 3.9, 3.1), eye = 1.1 },
		parts = {
			{ s = "Ball", size = V(7, 6, 6.4), pos = V(0, 3.4, 0), c = C(232, 168, 60), m = Enum.Material.Sand },
			{ s = "Ball", size = V(2.4, 2.2, 2.4), pos = V(-2.2, 5.2, 1), c = C(210, 140, 40), m = Enum.Material.Sand },
			{ s = "Block", size = V(5, 1.2, 5), pos = V(0, 6.9, 0), c = C(255, 215, 60), m = Enum.Material.Neon },
			{ s = "Wedge", size = V(1, 1.6, 1), pos = V(-2, 8.3, 0), c = C(255, 215, 60), m = Enum.Material.Neon },
			{ s = "Wedge", size = V(1, 1.6, 1), pos = V(0, 8.3, 0), c = C(255, 215, 60), m = Enum.Material.Neon },
			{ s = "Wedge", size = V(1, 1.6, 1), pos = V(2, 8.3, 0), c = C(255, 215, 60), m = Enum.Material.Neon },
		},
	},
	{
		id = "signaluncle", name = "Neon Signal Ojisan", rarity = "Legendary", income = 500, scale = 1.4,
		face = { pos = V(0, 5.2, 1.1), eye = 0.8 },
		parts = {
			{ s = "Block", size = V(1.6, 9, 1.6), pos = V(0, 4.5, 0), c = C(90, 90, 100), m = Enum.Material.Metal },
			{ s = "Block", size = V(5, 3.4, 2), pos = V(0, 9.2, 0), c = C(30, 30, 38) },
			{ s = "Ball", size = V(1.9, 1.9, 1.9), pos = V(-1.6, 9.2, 1.1), c = C(255, 40, 40), m = Enum.Material.Neon },
			{ s = "Ball", size = V(1.9, 1.9, 1.9), pos = V(0, 9.2, 1.1), c = C(255, 220, 40), m = Enum.Material.Neon },
			{ s = "Ball", size = V(1.9, 1.9, 1.9), pos = V(1.6, 9.2, 1.1), c = C(40, 255, 100), m = Enum.Material.Neon },
		},
	},
	-- Mythic
	{
		id = "clerk2am", name = "2AM Store Manager", rarity = "Mythic", income = 1500, scale = 1.5,
		face = { pos = V(0, 8.4, 1.7), eye = 1.0 },
		parts = {
			{ s = "Block", size = V(4.4, 7.2, 3), pos = V(0, 3.6, 0), c = C(30, 60, 150) },
			{ s = "Block", size = V(4.5, 1, 3.1), pos = V(0, 5.2, 0), c = C(240, 240, 240) },
			{ s = "Ball", size = V(3.6, 3.8, 3.6), pos = V(0, 8.4, 0), c = C(240, 200, 170) },
			{ s = "Block", size = V(3.8, 0.9, 3.8), pos = V(0, 10.2, 0), c = C(230, 50, 60) },
			{ s = "Block", size = V(1.6, 0.7, 0.2), pos = V(1.2, 5.6, 1.6), c = C(120, 255, 200), m = Enum.Material.Neon },
			{ s = "Cylinder", size = V(0.6, 7, 7), rot = V(0, 90, 0), pos = V(0, 8.4, -0.3), c = C(255, 255, 255), m = Enum.Material.Neon, t = 0.5, rainbow = true },
		},
	},
	{
		id = "spaceonigiri", name = "Uchu Onigiri", rarity = "Mythic", income = 4000, scale = 1.5,
		face = { pos = V(0, 5.3, 2.4), eye = 1.0 },
		parts = {
			{ s = "Wedge", size = V(6, 6.4, 5), rot = V(0, 180, 0), pos = V(0, 3.2, 0), c = C(248, 248, 250) },
			{ s = "Block", size = V(4, 2.6, 0.3), pos = V(0, 1.6, 2.3), c = C(25, 35, 30) },
			{ s = "Ball", size = V(9.5, 9.5, 9.5), pos = V(0, 3.8, 0), c = C(255, 255, 255), m = Enum.Material.Neon, t = 0.82, rainbow = true },
		},
	},
	-- Secret
	{
		id = "open24", name = "24-Hours Open", rarity = "Secret", income = 15000, scale = 1.8,
		face = { pos = V(0, 7.4, 1.2), eye = 1.3 },
		parts = {
			{ s = "Cylinder", size = V(1.6, 10, 10), rot = V(0, 90, 0), pos = V(0, 7, 0), c = C(15, 15, 18), m = Enum.Material.Metal },
			{ s = "Cylinder", size = V(0.4, 10.8, 10.8), rot = V(0, 90, 0), pos = V(0, 7, 0.6), c = C(255, 255, 255), m = Enum.Material.Neon, t = 0.2 },
			{ s = "Block", size = V(0.5, 3.6, 0.3), pos = V(0, 8.6, 1.1), c = C(255, 70, 70), m = Enum.Material.Neon },
			{ s = "Block", size = V(3, 0.5, 0.3), pos = V(1.4, 7, 1.1), rot = V(0, 0, 25), c = C(255, 70, 70), m = Enum.Material.Neon },
			{ s = "Block", size = V(3, 1, 1), pos = V(0, 0.5, 0), c = C(15, 15, 18), m = Enum.Material.Metal },
			{ s = "Block", size = V(2, 6.4, 2), pos = V(0, 2.5, 0), c = C(15, 15, 18), m = Enum.Material.Metal },
		},
	},
}

Characters.byId = {}
Characters.byRarity = {}
for _, def in ipairs(Characters.list) do
	Characters.byId[def.id] = def
	Characters.byRarity[def.rarity] = Characters.byRarity[def.rarity] or {}
	table.insert(Characters.byRarity[def.rarity], def)
end

return Characters
