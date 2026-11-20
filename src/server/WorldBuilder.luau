-- Builds every static thing in the town: lighting extras, plaza, lane, konbini, six bases and the
-- signage that tells a new player what to do. Returns a table describing the bases for other services.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Shapes = require(Shared.Shapes)

local WorldBuilder = {}

local PLASTIC = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon

local function part(parent, name, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or PLASTIC
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function cylinder(parent, name, diameter, height, pos, color, material, extra)
	local p = part(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, extra)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function decoration(extra)
	extra = extra or {}
	extra.CanCollide = false
	extra.CanTouch = false
	extra.CanQuery = false
	extra.CastShadow = false
	return extra
end

-- text painted on one face of a part; TextScaled so it can never overflow
local function faceText(target, face, text, textColor, bgColor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = target
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = bgColor or Color3.new(0, 0, 0)
	label.BackgroundTransparency = bgColor and 0 or 1
	label.Text = text
	label.TextColor3 = textColor
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0.06, 0)
	pad.PaddingRight = UDim.new(0.06, 0)
	pad.Parent = label
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 6
	limit.MaxTextSize = 200
	limit.Parent = label
	return label
end

local function billboard(parent, text, color, size, studsUp)
	local bb = Instance.new("BillboardGui")
	bb.Size = size or UDim2.fromOffset(220, 64)
	bb.StudsOffset = Vector3.new(0, studsUp or 0, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 400
	bb.Parent = parent
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
	l.BackgroundTransparency = 0.15
	l.Text = text
	l.TextColor3 = color
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.TextWrapped = true
	l.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = l
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.14, 0)
	pad.PaddingBottom = UDim.new(0.14, 0)
	pad.PaddingLeft = UDim.new(0.08, 0)
	pad.PaddingRight = UDim.new(0.08, 0)
	pad.Parent = l
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 8
	limit.MaxTextSize = 40
	limit.Parent = l
	return bb, l
end

local function lamp(parent, pos, warm)
	local pole = cylinder(parent, "LampPole", 0.7, 11, pos + Vector3.new(0, 5.5, 0), Color3.fromRGB(95, 90, 125), PLASTIC)
	pole.CFrame = CFrame.new(pos + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local bulb = part(parent, "LampBulb", Vector3.new(2.4, 2.4, 2.4), CFrame.new(pos + Vector3.new(0, 11.8, 0)), warm, NEON, decoration())
	bulb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = warm
	light.Range = 46
	light.Brightness = 2.2
	light.Shadows = false
	light.Parent = bulb
end

local function baseHue(i)
	return Color3.fromHSV(((i - 1) / Config.BaseCount + 0.02) % 1, 0.55, 1)
end

local function setupLighting()
	Lighting.ClockTime = 19
	Lighting.Brightness = 3.5
	Lighting.Ambient = Color3.fromRGB(140, 130, 190)
	Lighting.OutdoorAmbient = Color3.fromRGB(165, 155, 215)
	Lighting.ExposureCompensation = 0.9
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ColorShift_Top = Color3.fromRGB(255, 210, 240)
	Lighting.FogEnd = 100000

	for _, cls in ipairs({ "Sky", "Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect" }) do
		local old = Lighting:FindFirstChildOfClass(cls)
		if old then
			old.Parent = nil
		end
	end

	local sky = Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.22
	atmo.Offset = 0.2
	atmo.Color = Color3.fromRGB(190, 170, 235)
	atmo.Decay = Color3.fromRGB(255, 170, 215)
	atmo.Glare = 0.2
	atmo.Haze = 0.6
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.04
	cc.Contrast = 0.08
	cc.Saturation = 0.2
	cc.Parent = Lighting
end

-- ground colour is set by the project file's Ground part; recolour here too so scripts and file agree
local function paintGround()
	local g = Workspace:FindFirstChild("Ground")
	if g then
		g.Color = Color3.fromRGB(104, 100, 150)
		g.Material = PLASTIC
	end
end

local function buildPlaza(root)
	cylinder(root, "Plaza", 104, 0.3, Vector3.new(0, 0.15, 0), Color3.fromRGB(178, 170, 222), PLASTIC)
	cylinder(root, "PlazaRim", 108, 0.2, Vector3.new(0, 0.1, 0), Color3.fromRGB(255, 190, 235), NEON, decoration())

	-- the drifting lane
	local L = Config.Lane
	part(root, "Lane", Vector3.new(L.HalfLength * 2 + 8, 0.3, L.Width), CFrame.new(0, 0.2, L.Z), Color3.fromRGB(150, 146, 192), PLASTIC, decoration())
	for _, dz in ipairs({ -L.Width / 2, L.Width / 2 }) do
		part(root, "LaneEdge", Vector3.new(L.HalfLength * 2 + 8, 0.2, 0.7), CFrame.new(0, 0.34, L.Z + dz), Color3.fromRGB(80, 255, 240), NEON, decoration())
	end
	-- chevrons on the road show which way things drift
	for x = -L.HalfLength + 8, L.HalfLength - 8, 16 do
		Shapes.chevron(root, CFrame.lookAt(Vector3.new(x, 0.5, L.Z), Vector3.new(x + 1, 0.5, L.Z)), 4.5, 0.9, Color3.fromRGB(255, 240, 120), NEON, 0.1)
	end
end

local function buildKonbini(root)
	local K = Config.Konbini
	local c = K.Center
	local folder = Instance.new("Folder")
	folder.Name = "Konbini"
	folder.Parent = root

	part(folder, "Shell", Vector3.new(K.HalfX * 2, 14, K.HalfZ * 2), CFrame.new(c.X, 7, c.Z), Color3.fromRGB(245, 245, 252), PLASTIC)
	part(folder, "RoofStripe", Vector3.new(K.HalfX * 2 + 0.6, 1.6, K.HalfZ * 2 + 0.6), CFrame.new(c.X, 14.4, c.Z), Color3.fromRGB(40, 190, 120), PLASTIC)
	part(folder, "RoofStripe2", Vector3.new(K.HalfX * 2 + 0.7, 0.7, K.HalfZ * 2 + 0.7), CFrame.new(c.X, 13.2, c.Z), Color3.fromRGB(60, 120, 255), PLASTIC)

	local frontZ = c.Z + K.HalfZ
	part(folder, "Window", Vector3.new(K.HalfX * 2 - 10, 7, 0.4), CFrame.new(c.X, 6.2, frontZ + 0.1), Color3.fromRGB(190, 235, 255), NEON, decoration({ Transparency = 0.35 }))
	local sign = part(folder, "Sign", Vector3.new(46, 7.5, 1.4), CFrame.new(c.X, 20, frontZ - 1), Color3.fromRGB(25, 20, 55), PLASTIC)
	faceText(sign, Enum.NormalId.Back, "KONBINI", Color3.fromRGB(255, 245, 120), nil)
	part(folder, "SignGlow", Vector3.new(47, 0.6, 1.6), CFrame.new(c.X, 16, frontZ - 1), Color3.fromRGB(255, 90, 200), NEON, decoration())

	-- vending machines along the front
	local cols = { Color3.fromRGB(255, 95, 95), Color3.fromRGB(95, 200, 255), Color3.fromRGB(255, 215, 85) }
	for i = 1, 6 do
		local x = -24 + (i - 1) * 9.6
		part(folder, "Vending", Vector3.new(4, 7, 3), CFrame.new(x, 3.5, frontZ + 2.2), cols[(i - 1) % 3 + 1], PLASTIC)
		part(folder, "VendingGlass", Vector3.new(3, 4, 0.3), CFrame.new(x, 4.2, frontZ + 3.7), Color3.fromRGB(255, 255, 255), NEON, decoration())
	end

	-- spawn pad: the player starts here
	local pad = Instance.new("SpawnLocation")
	pad.Name = "SpawnPad"
	pad.Anchored = true
	pad.Size = Vector3.new(14, 1, 14)
	pad.CFrame = CFrame.new(K.SpawnPad)
	pad.Color = Color3.fromRGB(80, 255, 170)
	pad.Material = NEON
	pad.Neutral = true
	pad.Duration = 0
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.Parent = folder
	billboard(pad, "START HERE", Color3.fromRGB(255, 245, 120), UDim2.fromOffset(240, 60), 8)

	-- arrow trail from the pad down onto the lane
	for z = K.SpawnPad.Z + 9, 0, 6 do
		Shapes.chevron(folder, CFrame.lookAt(Vector3.new(0, 0.6, z), Vector3.new(0, 0.6, z + 1)), 5, 1.1, Color3.fromRGB(255, 240, 80), NEON, 0)
	end
	return folder
end

-- a downward neon arrow hovering over the lane's centre
local function buildLaneMarker(root)
	local L = Config.Lane
	local folder = Instance.new("Folder")
	folder.Name = "LaneMarker"
	folder.Parent = root
	local top = Vector3.new(0, 26, L.Z)
	for i = 0, 2 do
		local y = 26 - i * 4
		Shapes.chevron(folder, CFrame.lookAt(Vector3.new(0, y, L.Z), Vector3.new(0, y - 1, L.Z), Vector3.new(0, 0, 1)), 6, 1.2, Color3.fromRGB(255, 240, 80), NEON, i * 0.2)
	end
	local anchor = part(folder, "MarkerAnchor", Vector3.new(1, 1, 1), CFrame.new(top + Vector3.new(0, 7, 0)), Color3.new(1, 1, 1), PLASTIC, decoration({ Transparency = 1 }))
	billboard(anchor, "CATCH HERE", Color3.fromRGB(255, 245, 120), UDim2.fromOffset(240, 60), 0)
end

-- four-sided pillar in the plaza that spells out the loop with big numbers
local function buildStepPillar(root)
	local pos = Vector3.new(0, 0, 34)
	local pillar = part(root, "StepPillar", Vector3.new(9, 16, 9), CFrame.new(pos + Vector3.new(0, 8, 0)), Color3.fromRGB(35, 30, 75), PLASTIC)
	local steps = {
		{ "1  CATCH", Color3.fromRGB(255, 240, 120) },
		{ "2  RUN HOME", Color3.fromRGB(120, 255, 190) },
		{ "3  COLLECT $", Color3.fromRGB(255, 200, 90) },
		{ "4  UPGRADE", Color3.fromRGB(255, 130, 230) },
	}
	local faces = { Enum.NormalId.Front, Enum.NormalId.Right, Enum.NormalId.Back, Enum.NormalId.Left }
	for i, f in ipairs(faces) do
		faceText(pillar, f, steps[i][1], steps[i][2], nil)
	end
	part(root, "StepPillarCap", Vector3.new(10, 1, 10), CFrame.new(pos + Vector3.new(0, 16.5, 0)), Color3.fromRGB(255, 130, 230), NEON, decoration())
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 1.6
	light.Color = Color3.fromRGB(255, 220, 255)
	light.Parent = pillar
end

local function buildLamps(root)
	local warm = Color3.fromRGB(255, 225, 150)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2 + 0.26
		lamp(root, Vector3.new(math.cos(a) * 54, 0, math.sin(a) * 54), warm)
	end
	-- a couple of extra lamps lighting the konbini front
	lamp(root, Vector3.new(-40, 0, -30), warm)
	lamp(root, Vector3.new(40, 0, -30), warm)
end

local function buildSkyline(root)
	local rng = Random.new(77)
	local folder = Instance.new("Folder")
	folder.Name = "Skyline"
	folder.Parent = root
	for i = 1, 36 do
		local a = (i / 36) * math.pi * 2
		local r = 300 + rng:NextNumber() * 55
		local h = 22 + rng:NextNumber() * 48
		local w = 16 + rng:NextNumber() * 18
		local hue = rng:NextNumber()
		local pos = Vector3.new(math.cos(a) * r, h / 2, math.sin(a) * r)
		local b = part(folder, "Tower", Vector3.new(w, h, w), CFrame.new(pos) * CFrame.Angles(0, a, 0), Color3.fromHSV(hue, 0.25, 0.7), PLASTIC)
		for f = 1, 3 do
			part(folder, "Window", Vector3.new(w + 0.2, 1.2, w + 0.2), CFrame.new(pos.X, f * h / 4, pos.Z) * CFrame.Angles(0, a, 0), Color3.fromHSV(hue, 0.6, 1), NEON, decoration())
		end
		b.CanCollide = true
	end
end

local function buildBase(root, i)
	local a = math.rad(30 + 60 * (i - 1))
	local center = Vector3.new(math.cos(a) * Config.BaseRingRadius, 0, math.sin(a) * Config.BaseRingRadius)
	local dirIn = (-center).Unit
	local gate = center + dirIn * Config.BaseRadius
	local hue = baseHue(i)

	local folder = Instance.new("Folder")
	folder.Name = "Base" .. i
	folder.Parent = root

	cylinder(folder, "Floor", Config.BaseRadius * 2, 0.8, Vector3.new(center.X, 0.4, center.Z), hue:Lerp(Color3.new(1, 1, 1), 0.55), PLASTIC)
	local ring = cylinder(folder, "SafeRing", Config.BaseRadius * 2 + 1.5, 0.3, Vector3.new(center.X, 0.75, center.Z), hue, NEON, decoration())
	local inner = cylinder(folder, "SafeInner", Config.BaseRadius * 2 - 2.5, 0.35, Vector3.new(center.X, 0.78, center.Z), hue:Lerp(Color3.new(1, 1, 1), 0.55), PLASTIC, decoration())
	inner.Transparency = 0

	-- tall beacon so a base can be spotted from anywhere
	local beacon = cylinder(folder, "Beacon", 3, 130, Vector3.new(center.X, 65, center.Z), hue, NEON, decoration({ Transparency = 0.55 }))
	beacon.CFrame = CFrame.new(center.X, 65, center.Z) * CFrame.Angles(0, 0, math.rad(90))

	-- collect pad in the middle
	local padPart = cylinder(folder, "CollectPad", 9, 0.5, Vector3.new(center.X, 1.05, center.Z), Color3.fromRGB(255, 215, 70), NEON, { CanCollide = false })
	padPart:SetAttribute("BaseIndex", i)
	CollectionService:AddTag(padPart, "CollectPad")
	billboard(padPart, "$ COLLECT", Color3.fromRGB(255, 235, 120), UDim2.fromOffset(200, 54), 5)

	-- pedestals
	local pedestals = {}
	for s = 1, Config.PedestalsPerBase do
		local pa = (s - 1) / Config.PedestalsPerBase * math.pi * 2
		local pp = Vector3.new(center.X + math.cos(pa) * Config.PedestalRingRadius, 0, center.Z + math.sin(pa) * Config.PedestalRingRadius)
		local frame = cylinder(folder, "Frame" .. s, 7.4, 0.3, pp + Vector3.new(0, 0.95, 0), Color3.fromRGB(90, 255, 235), NEON, decoration())
		local ped = cylinder(folder, "Pedestal" .. s, 5, 1.6, pp + Vector3.new(0, 1.6, 0), Color3.fromRGB(240, 238, 255), PLASTIC)
		ped:SetAttribute("BaseIndex", i)
		ped:SetAttribute("Slot", s)
		ped:SetAttribute("OwnerUserId", 0)
		ped:SetAttribute("Filled", false)
		ped:SetAttribute("Meter", 0)
		CollectionService:AddTag(ped, "Pedestal")
		local att = Instance.new("Attachment")
		att.Name = "PromptAnchor"
		att.Position = Vector3.new(0, 1.5, 0)
		att.Parent = ped
		local function prompt(name, action, hold)
			local pr = Instance.new("ProximityPrompt")
			pr.Name = name
			pr.ActionText = action
			pr.ObjectText = "Pedestal " .. s
			pr.HoldDuration = hold
			pr.MaxActivationDistance = 11
			pr.RequiresLineOfSight = false
			pr.KeyboardKeyCode = Enum.KeyCode.E
			pr.Enabled = false -- the client opens the one that applies
			pr.Parent = att
			return pr
		end
		prompt("Place", "Place brainrot", Config.PlaceHold)
		prompt("Collect", "Collect $", Config.CollectHold)
		prompt("Steal", "STEAL!", Config.StealHold)
		pedestals[s] = { part = ped, frame = frame, pos = pp }
	end

	-- gate: posts, sign, glowing path out to the plaza
	local right = dirIn:Cross(Vector3.new(0, 1, 0)).Unit
	for _, side in ipairs({ -1, 1 }) do
		part(folder, "GatePost", Vector3.new(1.6, 12, 1.6), CFrame.new(gate + right * side * 8 + Vector3.new(0, 6, 0)), hue, NEON, decoration())
	end
	local signCF = CFrame.lookAt(gate + Vector3.new(0, 12.5, 0), gate + Vector3.new(0, 12.5, 0) + dirIn)
	local signPart = part(folder, "GateSign", Vector3.new(17, 4.4, 0.8), signCF, Color3.fromRGB(25, 20, 55), PLASTIC, decoration())
	local signFront = faceText(signPart, Enum.NormalId.Front, "FREE BASE", hue, nil)
	local signBack = faceText(signPart, Enum.NormalId.Back, "FREE BASE", hue, nil)
	part(folder, "GateBar", Vector3.new(18, 0.6, 1), signCF * CFrame.new(0, 2.6, 0), hue, NEON, decoration())

	local pathLen = (gate - Vector3.new(0, 0, 0)).Magnitude - 52
	local steps = math.floor(pathLen / 9)
	for n = 1, steps do
		local at = gate + dirIn * (n * 9 - 4)
		-- chevrons point from the plaza toward the base
		Shapes.chevron(folder, CFrame.lookAt(Vector3.new(at.X, 0.5, at.Z), Vector3.new(at.X, 0.5, at.Z) - dirIn), 4.5, 0.9, hue, NEON, 0)
	end

	return {
		index = i,
		center = center,
		gate = gate,
		hue = hue,
		folder = folder,
		ring = ring,
		pedestals = pedestals,
		collectPad = padPart,
		signLabels = { signFront, signBack },
		owner = nil,
		models = {},
	}
end

function WorldBuilder.build()
	setupLighting()
	paintGround()

	local root = Instance.new("Folder")
	root.Name = "World"
	root.Parent = Workspace

	buildPlaza(root)
	buildKonbini(root)
	buildLaneMarker(root)
	buildStepPillar(root)
	buildLamps(root)
	buildSkyline(root)

	local bases = {}
	for i = 1, Config.BaseCount do
		bases[i] = buildBase(root, i)
	end
	return { root = root, bases = bases }
end

-- true when a world position is inside a base disc or the konbini block (the tide and robots skip these)
function WorldBuilder.isSafe(world, pos)
	for _, b in ipairs(world.bases) do
		local dx, dz = pos.X - b.center.X, pos.Z - b.center.Z
		if dx * dx + dz * dz <= (Config.BaseRadius + 2) ^ 2 then
			return true
		end
	end
	local K = Config.Konbini
	if math.abs(pos.X - K.Center.X) <= K.HalfX + 4 and pos.Z >= K.Center.Z - K.HalfZ - 4 and pos.Z <= K.SpawnPad.Z + 10 then
		return true
	end
	return false
end

return WorldBuilder
