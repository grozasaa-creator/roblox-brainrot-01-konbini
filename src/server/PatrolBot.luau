-- 夜の警備ロボ。巡回し、キャラを持って視界に入ったプレイヤーを追い、触れたら落とさせる。
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)
local BaseService = require(script.Parent.BaseService)
local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)

local PatrolBot = {}

local bots = {}

local function buildBotModel(index: number): Model
	local model = Instance.new("Model")
	model.Name = "SecurityBot" .. index
	local function part(name, size, offset, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.Color = color
		p.Material = material or Enum.Material.Metal
		p.CFrame = CFrame.new(offset)
		p.Parent = model
		return p
	end
	part("Torso", Vector3.new(4, 5, 3), Vector3.new(0, 4.5, 0), Color3.fromRGB(35, 45, 90))
	part("Head", Vector3.new(3.4, 2.6, 3), Vector3.new(0, 8.2, 0), Color3.fromRGB(60, 70, 120))
	local eye = part("Visor", Vector3.new(3, 0.7, 0.3), Vector3.new(0, 8.3, 1.55), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	part("Siren", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 10.2, 0), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
	part("LegL", Vector3.new(1.4, 3, 1.4), Vector3.new(-1, 1.5, 0), Color3.fromRGB(25, 30, 60))
	part("LegR", Vector3.new(1.4, 3, 1.4), Vector3.new(1, 1.5, 0), Color3.fromRGB(25, 30, 60))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 40, 40)
	light.Range = 20
	light.Parent = eye
	model.WorldPivot = CFrame.new()
	model:SetAttribute("Bot", true)
	return model
end

local function nearestCarrier(position: Vector3)
	local best, bestDist = nil, Config.PATROL_SIGHT
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if state and state.carrying and root and not BaseService.isSafe(root.Position) then
			local dist = (root.Position - position).Magnitude
			if dist < bestDist then
				best, bestDist = player, dist
			end
		end
	end
	return best
end

function PatrolBot.init(world)
	local points = world.patrolPoints
	local folder = Instance.new("Folder")
	folder.Name = "PatrolBots"
	folder.Parent = workspace
	for i = 1, Config.PATROL_BOT_COUNT do
		local model = buildBotModel(i)
		local startPoint = points[(i - 1) * 4 + 1]
		model:PivotTo(CFrame.new(startPoint))
		model.Parent = folder
		table.insert(bots, { model = model, waypoint = (i - 1) * 4 + 1, stunUntil = 0 })
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, bot in ipairs(bots) do
			if os.clock() >= bot.stunUntil then
				local pos = bot.model:GetPivot().Position
				local target = nearestCarrier(pos)
				local goal, speed
				if target then
					goal = target.Character.HumanoidRootPart.Position
					speed = Config.CHASE_SPEED
				else
					goal = points[bot.waypoint]
					speed = Config.PATROL_SPEED
				end
				local flat = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
				if not target and flat.Magnitude < 3 then
					bot.waypoint = bot.waypoint % #points + 1
				elseif flat.Magnitude > 0.1 then
					local step = flat.Unit * math.min(speed * dt, flat.Magnitude)
					local newPos = Vector3.new(pos.X + step.X, 0, pos.Z + step.Z)
					bot.model:PivotTo(CFrame.lookAt(newPos, newPos + flat.Unit) * CFrame.Angles(0, math.pi, 0))
				end
				if target and flat.Magnitude < 5 then
					CarryService.drop(target, true)
					Notice.send(target, "Security bot caught you! You dropped it.", "bad")
					bot.stunUntil = os.clock() + Config.PATROL_STUN_SECONDS
				end
			end
		end
	end)
end

return PatrolBot
