-- 夜のコンビニ街をコードで組み立てる。道・ベルト・シェルター（コンビニ）・拠点6つ・街灯・遠景ビル・夜の照明。
local Lighting = game:GetService("Lighting")

local Config = require(game.ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(120, 255, 130),
	Color3.fromRGB(255, 200, 70),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(255, 130, 210),
}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Cylinder は X 軸が高さなので、Z 周りに 90 度回して縦向きにする。
local function makeDisc(parent: Instance, name: string, height: number, diameter: number, position: Vector3, color: Color3, material: Enum.Material?)
	local disc = makePart(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, material)
	disc.Shape = Enum.PartType.Cylinder
	return disc
end

local function addSign(part: Part, text: string, color: Color3, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = color
	label.Parent = gui
end

local function buildLighting()
	Lighting.ClockTime = 20.5
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 60, 110)
	Lighting.EnvironmentDiffuseScale = 0.4
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(120, 90, 190)
	atmosphere.Decay = Color3.fromRGB(60, 30, 110)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 36
	bloom.Threshold = 1.1
	bloom.Parent = Lighting
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "WarnTint"
	correction.Saturation = 0.15
	correction.Contrast = 0.1
	correction.Parent = Lighting
end

local function buildRoads(town: Folder)
	local roadColor = Color3.fromRGB(34, 34, 44)
	makePart(town, "RoadX", Vector3.new(600, 0.2, 24), CFrame.new(0, 0.1, 0), roadColor, Enum.Material.Asphalt)
	makePart(town, "RoadZ", Vector3.new(24, 0.2, 600), CFrame.new(0, 0.11, 0), roadColor, Enum.Material.Asphalt)
	for x = -280, 280, 20 do
		makePart(town, "Dash", Vector3.new(8, 0.05, 0.6), CFrame.new(x, 0.25, 9), Color3.fromRGB(255, 230, 120), Enum.Material.Neon)
		makePart(town, "Dash", Vector3.new(8, 0.05, 0.6), CFrame.new(x, 0.25, -9), Color3.fromRGB(255, 230, 120), Enum.Material.Neon)
	end
end

local function buildBelt(town: Folder)
	local half = Config.BELT_HALF_LENGTH
	makePart(town, "BeltSurface", Vector3.new(half * 2, 0.6, 8), CFrame.new(0, 0.4, 0), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
	for _, z in ipairs({ -4.4, 4.4 }) do
		makePart(town, "BeltRail", Vector3.new(half * 2, 0.5, 0.5), CFrame.new(0, 0.9, z), Color3.fromRGB(80, 255, 255), Enum.Material.Neon)
	end
	local title = makePart(town, "BeltTitle", Vector3.new(26, 4, 0.6), CFrame.new(0, 14, -10), Color3.fromRGB(20, 20, 30))
	addSign(title, "SUSHI-BELT  BUY A BRAINROT", Color3.fromRGB(80, 255, 255), Enum.NormalId.Front)
	makePart(town, "BeltTitlePostA", Vector3.new(0.8, 14, 0.8), CFrame.new(-12, 7, -10), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
	makePart(town, "BeltTitlePostB", Vector3.new(0.8, 14, 0.8), CFrame.new(12, 7, -10), Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
end

-- コンビニ型シェルター。高波の間はここも安全地帯になる。返り値は XZ の矩形リスト。
local function buildShelters(town: Folder)
	local shelters = {}
	local names = { "NIGHT MART", "OPEN 24H", "ONIGIRI", "RAMEN BAR" }
	local colors = { Color3.fromRGB(80, 255, 160), Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 210, 70), Color3.fromRGB(110, 170, 255) }
	local spots = { Vector3.new(-85, 0, 55), Vector3.new(85, 0, 55), Vector3.new(-85, 0, -55), Vector3.new(85, 0, -55) }
	for i, spot in ipairs(spots) do
		local folder = Instance.new("Folder")
		folder.Name = "Konbini" .. i
		folder.Parent = town
		local facing = spot.Z > 0 and -1 or 1 -- 開口は中央（ベルト）側
		local w, h, d = 30, 14, 24
		makePart(folder, "Floor", Vector3.new(w, 0.5, d), CFrame.new(spot.X, 0.25, spot.Z), Color3.fromRGB(225, 225, 235))
		makePart(folder, "BackWall", Vector3.new(w, h, 1), CFrame.new(spot.X, h / 2, spot.Z - facing * d / 2), Color3.fromRGB(235, 240, 250))
		makePart(folder, "WallL", Vector3.new(1, h, d), CFrame.new(spot.X - w / 2, h / 2, spot.Z), Color3.fromRGB(235, 240, 250))
		makePart(folder, "WallR", Vector3.new(1, h, d), CFrame.new(spot.X + w / 2, h / 2, spot.Z), Color3.fromRGB(235, 240, 250))
		makePart(folder, "Roof", Vector3.new(w + 2, 1, d + 2), CFrame.new(spot.X, h + 0.5, spot.Z), colors[i])
		local sign = makePart(folder, "Sign", Vector3.new(w - 4, 4, 0.6), CFrame.new(spot.X, h + 3.5, spot.Z + facing * (d / 2 + 0.5)), Color3.fromRGB(15, 15, 25))
		addSign(sign, names[i], colors[i], facing == -1 and Enum.NormalId.Front or Enum.NormalId.Back)
		for s = -1, 1 do
			makePart(folder, "Shelf", Vector3.new(6, 6, 2), CFrame.new(spot.X + s * 9, 3, spot.Z - facing * 8), Color3.fromRGB(255, 255, 255)).Material = Enum.Material.Metal
			makePart(folder, "Goods", Vector3.new(5, 0.8, 1.6), CFrame.new(spot.X + s * 9, 4, spot.Z - facing * 7.6), colors[(i + s) % 4 + 1], Enum.Material.Neon)
		end
		local light = Instance.new("PointLight")
		light.Range = 36
		light.Brightness = 2
		light.Color = colors[i]
		light.Parent = folder:FindFirstChild("Roof")
		table.insert(shelters, { cx = spot.X, cz = spot.Z, hx = w / 2, hz = d / 2 })
	end
	return shelters
end

local function buildBases(town: Folder)
	local bases = {}
	for i = 1, Config.BASE_COUNT do
		local angle = math.rad((i - 1) * (360 / Config.BASE_COUNT))
		local center = Vector3.new(math.cos(angle) * Config.BASE_RING_RADIUS, 0, math.sin(angle) * Config.BASE_RING_RADIUS)
		local inward = (-center).Unit
		local color = BASE_COLORS[i]

		local folder = Instance.new("Folder")
		folder.Name = "Base" .. i
		folder.Parent = town

		makeDisc(folder, "FloorGlow", 0.3, Config.BASE_RADIUS * 2 + 3, center + Vector3.new(0, 0.2, 0), color, Enum.Material.Neon)
		makeDisc(folder, "Floor", 0.5, Config.BASE_RADIUS * 2, center + Vector3.new(0, 0.5, 0), Color3.fromRGB(38, 32, 56), Enum.Material.Slate)

		local pedestals = {}
		for j = 1, Config.PEDESTALS_PER_BASE do
			local a = math.rad((j - 1) * (360 / Config.PEDESTALS_PER_BASE) + 22.5)
			local pos = center + Vector3.new(math.cos(a) * Config.PEDESTAL_RING_RADIUS, 1.1, math.sin(a) * Config.PEDESTAL_RING_RADIUS)
			local pedestal = makeDisc(folder, "Pedestal" .. j, 1.2, 7, pos, Color3.fromRGB(60, 55, 80), Enum.Material.Metal)
			local glow = makeDisc(folder, "PedestalGlow" .. j, 0.15, 7.6, pos + Vector3.new(0, 0.62, 0), color, Enum.Material.Neon)
			glow.CanCollide = false
			pedestal:SetAttribute("BaseIndex", i)
			pedestal:SetAttribute("PedestalIndex", j)
			pedestal:SetAttribute("Meter", 0)
			pedestal:AddTag("Pedestal")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "CollectPrompt"
			prompt.ActionText = "Collect"
			prompt.ObjectText = "Pedestal " .. j
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 11
			prompt.RequiresLineOfSight = false
			prompt.Parent = pedestal
			pedestals[j] = pedestal
		end

		-- 門（ロックの操作盤）。中央側の縁に立てる。
		local gatePos = center + inward * (Config.BASE_RADIUS - 2)
		local gateCF = CFrame.lookAt(gatePos + Vector3.new(0, 7, 0), gatePos + Vector3.new(0, 7, 0) + inward)
		local gate = makePart(folder, "Gate", Vector3.new(16, 3, 1), gateCF, color, Enum.Material.Neon)
		for _, side in ipairs({ -1, 1 }) do
			local postPos = gatePos + gateCF.RightVector * (side * 8)
			makePart(folder, "GatePost", Vector3.new(1.2, 14, 1.2), CFrame.new(postPos.X, 7, postPos.Z), Color3.fromRGB(50, 50, 64), Enum.Material.Metal)
		end
		local lockPrompt = Instance.new("ProximityPrompt")
		lockPrompt.Name = "LockPrompt"
		lockPrompt.ActionText = "Lock base"
		lockPrompt.ObjectText = "$" .. Config.LOCK_COST .. " / " .. Config.LOCK_SECONDS .. "s"
		lockPrompt.HoldDuration = 0.4
		lockPrompt.MaxActivationDistance = 16
		lockPrompt.RequiresLineOfSight = false
		lockPrompt.Parent = gate
		gate:SetAttribute("BaseIndex", i)
		gate:AddTag("BaseGate")

		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "Spawn"
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Enabled = true
		spawn.Size = Vector3.new(8, 0.4, 8)
		spawn.Position = center + inward * 8 + Vector3.new(0, 1, 0)
		spawn.Color = color
		spawn.Material = Enum.Material.Neon
		spawn.Transparency = 0.5
		spawn.CanCollide = false
		spawn.Parent = folder

		bases[i] = {
			index = i,
			center = center,
			folder = folder,
			pedestals = pedestals,
			gate = gate,
			spawn = spawn,
			color = color,
			owner = nil,
		}
	end
	return bases
end

local function buildLamps(town: Folder)
	for i = 1, 20 do
		local a = math.rad(i * 18)
		local r = i % 2 == 0 and 62 or 112
		local pos = Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		makePart(town, "LampPole", Vector3.new(0.6, 12, 0.6), CFrame.new(pos.X, 6, pos.Z), Color3.fromRGB(70, 70, 80), Enum.Material.Metal)
		local head = makePart(town, "LampHead", Vector3.new(2, 1, 2), CFrame.new(pos.X, 12.5, pos.Z), Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 30
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(255, 210, 150)
		light.Parent = head
	end
end

local function buildSkyline(town: Folder)
	local rng = Random.new(7)
	for i = 1, 36 do
		local a = math.rad(i * 10)
		local r = 330
		local h = rng:NextInteger(40, 120)
		local width = rng:NextInteger(18, 34)
		local cf = CFrame.new(math.cos(a) * r, h / 2, math.sin(a) * r) * CFrame.Angles(0, -a, 0)
		local building = makePart(town, "Skyline", Vector3.new(width, h, width), cf, Color3.fromRGB(26, 24, 40))
		building.CanCollide = false
		local strip = makePart(town, "SkylineNeon", Vector3.new(width + 0.4, 1.2, width + 0.4), cf * CFrame.new(0, h / 2 - 3 - rng:NextInteger(0, 20), 0), BASE_COLORS[i % 6 + 1], Enum.Material.Neon)
		strip.CanCollide = false
	end
end

-- 返り値: bases（拠点）, shelters（安全地帯の矩形）, patrolPoints（警備ロボの巡回路）
function WorldBuilder.build()
	buildLighting()
	local town = Instance.new("Folder")
	town.Name = "Town"
	town.Parent = workspace
	buildRoads(town)
	buildBelt(town)
	local shelters = buildShelters(town)
	local bases = buildBases(town)
	buildLamps(town)
	buildSkyline(town)

	local patrolPoints = {}
	for i = 1, 8 do
		local a = math.rad(i * 45 + 22.5)
		patrolPoints[i] = Vector3.new(math.cos(a) * Config.PATROL_RADIUS, 0, math.sin(a) * Config.PATROL_RADIUS)
	end
	return { town = town, bases = bases, shelters = shelters, patrolPoints = patrolPoints }
end

return WorldBuilder
