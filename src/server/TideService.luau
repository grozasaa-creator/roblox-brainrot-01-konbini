-- ネオン高波。予告（サイレン表示）→ 街を横断 → 安全地帯の外にいるプレイヤーは持ち物を落とす。
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local BaseService = require(script.Parent.BaseService)
local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)

local TideService = {}

local tideRemote = Remotes.get("Tide")

local function makeWave(direction: number): Part
	local wave = Instance.new("Part")
	wave.Name = "NeonTide"
	wave.Anchored = true
	wave.CanCollide = false
	wave.CanQuery = false
	wave.Size = Vector3.new(Config.TIDE_THICKNESS, 34, Config.TIDE_HALF_SPAN * 2)
	wave.Color = Color3.fromRGB(60, 255, 235)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.35
	wave.CFrame = CFrame.new(-direction * Config.TIDE_HALF_SPAN, 17, 0)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(60, 255, 235)
	light.Range = 60
	light.Brightness = 4
	light.Parent = wave
	wave.Parent = workspace
	return wave
end

local function runTide(direction: number)
	local wave = makeWave(direction)
	local elapsed = 0
	local hitThisTide = {}
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.min(1, elapsed / Config.TIDE_TRAVEL_SECONDS)
		local x = (-1 + 2 * alpha) * direction * Config.TIDE_HALF_SPAN
		wave.CFrame = CFrame.new(x, 17, 0)
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and not hitThisTide[player] and math.abs(root.Position.X - x) < Config.TIDE_THICKNESS / 2 + 3 then
				if not BaseService.isSafe(root.Position) then
					hitThisTide[player] = true
					if CarryService.isCarrying(player) then
						CarryService.drop(player, true)
						Notice.send(player, "The Neon Tide swept you away! You dropped it.", "bad")
					end
					root:ApplyImpulse(Vector3.new(direction * 900, 500, 0) * root.AssemblyMass)
				end
			end
		end
		if alpha >= 1 then
			connection:Disconnect()
			wave:Destroy()
		end
	end)
end

function TideService.init()
	task.spawn(function()
		task.wait(Config.TIDE_FIRST_SECONDS)
		local direction = 1
		while true do
			tideRemote:FireAllClients("warn", Config.TIDE_WARN_SECONDS)
			Notice.broadcast("NEON TIDE INCOMING! Get inside a base or a konbini!", "warn")
			task.wait(Config.TIDE_WARN_SECONDS)
			tideRemote:FireAllClients("go", Config.TIDE_TRAVEL_SECONDS)
			runTide(direction)
			direction = -direction
			task.wait(Config.TIDE_TRAVEL_SECONDS)
			tideRemote:FireAllClients("end", 0)
			task.wait(math.random(Config.TIDE_MIN_SECONDS, Config.TIDE_MAX_SECONDS))
		end
	end)
end

return TideService
