-- NEON TIDE: a glowing wall that sweeps across the whole map along X, alternating direction.
-- Bases and the konbini are safe. Anyone caught outside drops what they carry and gets thrown.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)
local WorldBuilder = require(script.Parent.WorldBuilder)

local TideService = {}

local world = nil
local remotes = nil
local running = false
local nextDir = 1
local hitAt = {}

local function buildWall(x)
	local T = Config.Tide
	local wall = Instance.new("Part")
	wall.Name = "NeonTide"
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanTouch = false
	wall.CanQuery = false
	wall.CastShadow = false
	wall.Size = Vector3.new(T.Thickness, T.Height, T.HalfSpan * 2.4)
	wall.Position = Vector3.new(x, T.Height / 2, 0)
	wall.Color = Color3.fromRGB(70, 245, 255)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.35
	wall.Parent = Workspace

	local crest = Instance.new("Part")
	crest.Name = "Crest"
	crest.Anchored = false -- rides on the anchored wall through the weld
	crest.Massless = true
	crest.CanCollide = false
	crest.CanTouch = false
	crest.CanQuery = false
	crest.CastShadow = false
	crest.Size = Vector3.new(T.Thickness + 2, 2.4, T.HalfSpan * 2.4)
	crest.Color = Color3.fromRGB(255, 80, 230)
	crest.Material = Enum.Material.Neon
	crest.Parent = wall
	crest.Position = wall.Position + Vector3.new(0, T.Height / 2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = wall
	weld.Part1 = crest
	weld.Parent = crest
	return wall
end

local function hitPlayers(wall, dir)
	local T = Config.Tide
	local now = os.clock()
	for _, player in ipairs(Players:GetPlayers()) do
		local ch = player.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			local p = root.Position
			local near = math.abs(p.X - wall.Position.X) < T.Thickness / 2 + 3
			if near and p.Y < T.Height and not WorldBuilder.isSafe(world, p) and now - (hitAt[player] or 0) > 3 then
				hitAt[player] = now
				CarryService.drop(player)
				root.AssemblyLinearVelocity = Vector3.new(dir * T.Knockback, 45, 0)
				hum.PlatformStand = true
				task.delay(1.4, function()
					if hum.Parent then
						hum.PlatformStand = false
					end
				end)
				Notice.send(player, "Swept by the NEON TIDE!", "bad")
				remotes.Tide:FireClient(player, "hit", dir, 0)
			end
		end
	end
end

-- runs one full wave: warning, sweep, end. dir = 1 sweeps toward +X, -1 toward -X
function TideService.startNow(dir)
	if running then
		return false
	end
	running = true
	dir = (dir == -1) and -1 or 1
	local T = Config.Tide

	remotes.Tide:FireAllClients("warn", dir, T.Warning)
	task.wait(T.Warning)

	local startX = -dir * T.HalfSpan
	local wall = buildWall(startX)
	remotes.Tide:FireAllClients("go", dir, T.Travel)

	local t0 = os.clock()
	while true do
		local t = os.clock() - t0
		if t >= T.Travel then
			break
		end
		local x = startX + dir * (t / T.Travel) * T.HalfSpan * 2
		wall.Position = Vector3.new(x, T.Height / 2, 0)
		hitPlayers(wall, dir)
		RunService.Heartbeat:Wait()
	end
	wall:Destroy()
	remotes.Tide:FireAllClients("end", dir, 0)
	running = false
	return true
end

function TideService.init(builtWorld, r)
	world = builtWorld
	remotes = r
	task.spawn(function()
		task.wait(Config.Tide.FirstDelay)
		local rng = Random.new()
		while true do
			TideService.startNow(nextDir)
			nextDir = -nextDir
			task.wait(rng:NextNumber(Config.Tide.MinGap, Config.Tide.MaxGap))
		end
	end)
end

return TideService
