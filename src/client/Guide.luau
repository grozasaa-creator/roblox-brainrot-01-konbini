-- Visual guidance. Decides the player's current goal, then shows it without relying on reading:
-- neon chevrons running from the player to the goal, a highlight and bobbing arrow on the target,
-- a light pillar over base/pad goals and a small distance tag. Also tells the HUD which step is active.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rarity = require(Shared.Rarity)
local Shapes = require(Shared.Shapes)

local ClientState = require(script.Parent.ClientState)
local UiKit = require(script.Parent.UiKit)

local Guide = {}

local player = Players.LocalPlayer
local COLORS = {
	catch = Color3.fromRGB(255, 232, 90),
	home = Color3.fromRGB(110, 255, 200),
	place = Color3.fromRGB(110, 255, 200),
	collect = Color3.fromRGB(255, 190, 80),
	safe = Color3.fromRGB(255, 90, 110),
}
local TRAIL_REACH = 3.4
local TRAIL_Y = 1.3

local fx
local trail = {}
local topArrow
local pillar
local tagPart
local tagLabel
local highlight
local goal = nil
local goalColor = COLORS.catch

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function myRoot()
	local ch = player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function insideSafe(pos, s)
	if s and s.basePos and (flat(pos) - flat(s.basePos)).Magnitude <= Config.BaseRadius + 1 then
		return true
	end
	local K = Config.Konbini
	return math.abs(pos.X - K.Center.X) <= K.HalfX and pos.Z >= K.Center.Z - K.HalfZ and pos.Z <= K.SpawnPad.Z + 8
end

local function nearest(list, from, project)
	local best, bestD = nil, math.huge
	for _, item in ipairs(list) do
		local p = project(item)
		if p then
			local d = (flat(p) - flat(from)).Magnitude
			if d < bestD then
				best, bestD = item, d
			end
		end
	end
	return best, bestD
end

local function catchableWild(s)
	local out = {}
	for _, m in ipairs(CollectionService:GetTagged("Brainrot")) do
		if m:GetAttribute("Wild") and m.PrimaryPart and Rarity.indexOf(m:GetAttribute("Rarity") or "Common") <= s.tier then
			table.insert(out, m)
		end
	end
	return out
end

local function myEmptyPedestals()
	local out = {}
	for _, p in ipairs(CollectionService:GetTagged("Pedestal")) do
		if p:GetAttribute("OwnerUserId") == player.UserId and not p:GetAttribute("Filled") then
			table.insert(out, p)
		end
	end
	return out
end

local function myCollectPad(s)
	for _, p in ipairs(CollectionService:GetTagged("CollectPad")) do
		if p:GetAttribute("BaseIndex") == s.baseIndex then
			return p
		end
	end
	return nil
end

-- returns { pos, kind, label, target? } and sets the HUD step
local function chooseGoal(s, rootPos)
	local tide = ClientState.tide
	if s.stunLeft > 0 then
		ClientState.setGoal(1, "Stunned by security!")
		return nil
	end

	if tide.active and not insideSafe(rootPos, s) then
		local home = s.basePos or Config.Konbini.SpawnPad
		ClientState.setGoal(2, "TIDE! Get inside a base")
		return { pos = home, kind = "safe", label = "SAFE HERE", pillar = true }
	end

	if s.carrying then
		if s.basePos and (flat(rootPos) - flat(s.basePos)).Magnitude < Config.BaseRadius - 2 then
			local ped, _ = nearest(myEmptyPedestals(), rootPos, function(p)
				return p.Position
			end)
			if ped then
				ClientState.setGoal(2, "Place it on a glowing pedestal")
				return { pos = ped.Position, kind = "place", label = "PLACE HERE", target = ped, arrowOffset = 4 }
			end
			ClientState.setGoal(3, "Base full - collect and upgrade")
			local pad = myCollectPad(s)
			return pad and { pos = pad.Position, kind = "collect", label = "COLLECT $", pillar = true } or nil
		end
		ClientState.setGoal(2, "Carry it to YOUR base")
		if s.basePos then
			return { pos = s.basePos, kind = "home", label = "YOUR BASE", pillar = true }
		end
		return nil
	end

	local pending = s.pending or 0
	if s.filled > 0 and pending >= 15 then
		local pad = myCollectPad(s)
		if pad then
			ClientState.setGoal(3, "Step on the gold pad: collect $")
			return { pos = pad.Position, kind = "collect", label = "COLLECT $", pillar = true }
		end
	end

	local canUpgrade = (s.nextTierCost ~= nil and s.money >= s.nextTierCost) or s.money >= s.rebirthCost
	local wild = nearest(catchableWild(s), rootPos, function(m)
		return m.PrimaryPart.Position
	end)
	if canUpgrade then
		ClientState.setGoal(4, "Upgrade ready - press the glowing button")
	else
		ClientState.setGoal(1, "Catch a brainrot - hold E")
	end
	if wild then
		return { pos = wild.PrimaryPart.Position, kind = "catch", label = "CATCH!", target = wild, arrowOffset = (wild:GetAttribute("Height") or 4) + 3 }
	end
	return { pos = Vector3.new(0, 0, Config.Lane.Z), kind = "catch", label = "CATCH HERE" }
end

local function setAdornee(target)
	if highlight.Adornee ~= target then
		highlight.Adornee = target
	end
end

local function hideAll()
	for _, c in ipairs(trail) do
		c.right.Transparency = 1
		c.left.Transparency = 1
	end
	topArrow.right.Transparency = 1
	topArrow.left.Transparency = 1
	pillar.Transparency = 1
	tagLabel.Visible = false
	setAdornee(nil)
end

local function build()
	fx = Instance.new("Folder")
	fx.Name = "GuideFx"
	fx.Parent = Workspace

	for i = 1, Config.Guide.ChevronCount do
		local r, l = Shapes.chevron(fx, CFrame.new(0, -50, 0), TRAIL_REACH, 0.8, COLORS.catch, Enum.Material.Neon, 1)
		trail[i] = { right = r, left = l }
	end
	local r, l = Shapes.chevron(fx, CFrame.new(0, -50, 0), 3.2, 1.0, COLORS.catch, Enum.Material.Neon, 1)
	topArrow = { right = r, left = l }

	pillar = Instance.new("Part")
	pillar.Name = "GoalPillar"
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.CanTouch = false
	pillar.CanQuery = false
	pillar.CastShadow = false
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(120, 3.2, 3.2)
	pillar.Material = Enum.Material.Neon
	pillar.Transparency = 1
	pillar.Parent = fx

	tagPart = Instance.new("Part")
	tagPart.Name = "GoalTag"
	tagPart.Anchored = true
	tagPart.CanCollide = false
	tagPart.CanTouch = false
	tagPart.CanQuery = false
	tagPart.Transparency = 1
	tagPart.Size = Vector3.new(1, 1, 1)
	tagPart.Parent = fx
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(210, 54)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 600
	bb.Parent = tagPart
	tagLabel = UiKit.label(bb, "", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = UiKit.Colors.Panel,
		Font = Enum.Font.GothamBlack,
	}, { MaxText = 26, pad = 0.12 })
	UiKit.corner(tagLabel, 0.3)

	highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = fx
end

local function paint(color)
	for _, c in ipairs(trail) do
		c.right.Color = color
		c.left.Color = color
	end
	topArrow.right.Color = color
	topArrow.left.Color = color
	pillar.Color = color
	highlight.FillColor = color
	highlight.OutlineColor = Color3.new(1, 1, 1)
	tagLabel.TextColor3 = color
end

local function animate(root)
	local g = goal
	if not g then
		hideAll()
		return
	end
	local now = os.clock()
	local from = flat(root.Position)
	local to = flat(g.pos)
	local delta = to - from
	local dist = delta.Magnitude

	if goalColor ~= COLORS[g.kind] then
		goalColor = COLORS[g.kind]
		paint(goalColor)
	end

	-- trail: chevrons march toward the goal
	local dir = dist > 0.1 and delta.Unit or Vector3.new(0, 0, -1)
	local showTrail = dist > Config.Guide.NearGoal
	for i, c in ipairs(trail) do
		local d = 6 + (i - 1) * Config.Guide.ChevronSpacing
		if showTrail and d < dist - 2 then
			local pos = from + dir * d + Vector3.new(0, TRAIL_Y, 0)
			Shapes.placeChevron(c.right, c.left, CFrame.lookAt(pos, pos + dir), TRAIL_REACH)
			local fade = 0.15 + 0.7 * (0.5 + 0.5 * math.sin(now * 7 - i * 0.9))
			c.right.Transparency = fade
			c.left.Transparency = fade
		else
			c.right.Transparency = 1
			c.left.Transparency = 1
		end
	end

	-- arrow bobbing over a specific target
	if g.arrowOffset then
		local bob = math.sin(now * 5) * 0.8
		local pos = g.pos + Vector3.new(0, g.arrowOffset + bob, 0)
		Shapes.placeChevron(topArrow.right, topArrow.left, CFrame.lookAt(pos, pos + Vector3.new(0, -1, 0), Vector3.new(0, 0, 1)), 3.2)
		topArrow.right.Transparency = 0
		topArrow.left.Transparency = 0
		setAdornee(g.target)
	else
		topArrow.right.Transparency = 1
		topArrow.left.Transparency = 1
		setAdornee(nil)
	end

	-- tall light pillar so far-away base/pad goals can be seen from anywhere
	if g.pillar then
		pillar.CFrame = CFrame.new(g.pos.X, 60, g.pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		pillar.Transparency = 0.45 + 0.2 * math.sin(now * 3)
	else
		pillar.Transparency = 1
	end

	-- distance tag
	local tagY = (g.arrowOffset or 14) + 4
	tagPart.Position = g.pos + Vector3.new(0, tagY, 0)
	tagLabel.Visible = true
	tagLabel.Text = g.label .. "  " .. math.floor(dist) .. "m"
end

function Guide.start()
	build()
	paint(goalColor)
	local acc = 1
	RunService.Heartbeat:Connect(function(dt)
		local root = myRoot()
		local s = ClientState.snapshot
		if not root or not s then
			hideAll()
			return
		end
		acc += dt
		if acc >= 0.12 then
			acc = 0
			goal = chooseGoal(s, root.Position)
			if goal and goal.target and not goal.target.Parent then
				goal = nil
			end
		end
		animate(root)
	end)
end

return Guide
