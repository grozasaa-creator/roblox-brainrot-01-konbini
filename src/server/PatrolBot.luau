-- Security robots: hover round the plaza on a wide loop, and chase anyone outside a safe zone who gets
-- close. A catch stuns the victim and knocks what they carry out of their hands.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local PlayerState = require(script.Parent.PlayerState)
local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)
local WorldBuilder = require(script.Parent.WorldBuilder)

local PatrolBot = {}

local world = nil
local bots = {}

local HOVER = 3.2

local function makeBot(index)
	local model = Instance.new("Model")
	model.Name = "PatrolBot" .. index

	local function piece(name, size, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Size = size
		p.Color = color
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.Parent = model
		return p
	end

	local body = piece("Body", Vector3.new(3.6, 3.4, 3.4), Color3.fromRGB(255, 135, 55), Enum.Material.SmoothPlastic)
	local head = piece("Head", Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(70, 70, 95), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	local eye = piece("Visor", Vector3.new(2.2, 0.7, 0.5), Color3.fromRGB(255, 50, 60), Enum.Material.Neon)
	local siren = piece("Siren", Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, Enum.PartType.Ball)
	model.PrimaryPart = body

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 80, 70)
	light.Range = 18
	light.Brightness = 1.8
	light.Parent = siren

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(150, 36)
	bb.StudsOffset = Vector3.new(0, 4.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 160
	bb.Parent = body
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.fromScale(1, 1)
	tag.BackgroundColor3 = Color3.fromRGB(190, 30, 40)
	tag.Text = "SECURITY"
	tag.TextColor3 = Color3.new(1, 1, 1)
	tag.Font = Enum.Font.GothamBlack
	tag.TextScaled = true
	tag.Parent = bb
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 22
	limit.MinTextSize = 6
	limit.Parent = tag
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = tag

	model.Parent = Workspace
	return { model = model, body = body, head = head, eye = eye, siren = siren, pos = Vector3.zero, yaw = 0 }
end

local function place(bot)
	local cf = CFrame.new(bot.pos) * CFrame.Angles(0, bot.yaw, 0)
	bot.body.CFrame = cf
	bot.head.CFrame = cf * CFrame.new(0, 2.7, 0)
	bot.eye.CFrame = cf * CFrame.new(0, 2.7, -1.2)
	bot.siren.CFrame = cf * CFrame.new(0, 4.4, 0)
end

local function nearestTarget(bot)
	local best, bestD = nil, Config.Patrol.Sight
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local st = PlayerState.get(player)
		local ch = player.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if st and root and hum and hum.Health > 0 and now >= st.stunUntil and not WorldBuilder.isSafe(world, root.Position) then
			local d = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(bot.pos.X, 0, bot.pos.Z)).Magnitude
			if d < bestD then
				best, bestD = player, d
			end
		end
	end
	return best, bestD
end

local function stun(player)
	local st = PlayerState.get(player)
	if not st then
		return
	end
	st.stunUntil = os.clock() + Config.Patrol.StunSeconds
	CarryService.drop(player)
	CarryService.refreshSpeed(player)
	Notice.send(player, "Caught by security! Stunned " .. Config.Patrol.StunSeconds .. "s", "bad")
	task.delay(Config.Patrol.StunSeconds + 0.05, function()
		CarryService.refreshSpeed(player)
		PlayerState.push(player)
	end)
	PlayerState.push(player)
end

local function step(bot, dt)
	local P = Config.Patrol
	local target, dist = nearestTarget(bot)
	local goal, speed

	if target then
		local root = target.Character.HumanoidRootPart
		goal = Vector3.new(root.Position.X, HOVER, root.Position.Z)
		speed = P.Chase
		bot.siren.Color = Color3.fromRGB(255, 255, 255)
		if dist < 4.5 then
			stun(target)
		end
	else
		-- ride the loop: aim a little ahead of our current polar angle
		local a = math.atan2(bot.pos.Z, bot.pos.X) + 0.18
		goal = Vector3.new(math.cos(a) * P.Orbit, HOVER, math.sin(a) * P.Orbit)
		speed = P.Walk
		bot.siren.Color = Color3.fromRGB(255, 60, 60)
	end

	local to = goal - bot.pos
	local flat = Vector3.new(to.X, 0, to.Z)
	if flat.Magnitude > 0.05 then
		local move = math.min(flat.Magnitude, speed * dt)
		bot.pos += flat.Unit * move
		bot.pos = Vector3.new(bot.pos.X, HOVER + math.sin(os.clock() * 4 + bot.phase) * 0.25, bot.pos.Z)
		bot.yaw = math.atan2(-flat.X, -flat.Z)
	end
	place(bot)
end

function PatrolBot.init(builtWorld)
	world = builtWorld
	for i = 1, Config.Patrol.Count do
		local bot = makeBot(i)
		local a = (i - 1) * math.pi + 0.8
		bot.pos = Vector3.new(math.cos(a) * Config.Patrol.Orbit, HOVER, math.sin(a) * Config.Patrol.Orbit)
		bot.phase = i * 1.7
		place(bot)
		table.insert(bots, bot)
	end
	RunService.Heartbeat:Connect(function(dt)
		for _, bot in ipairs(bots) do
			step(bot, dt)
		end
	end)
end

return PatrolBot
