-- Wild brainrot: spawn at the west end of the lane, drift east, vanish at the far end. Dropped characters
-- sit where they fell for a while so anyone can grab them.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rarity = require(Shared.Rarity)
local Mutations = require(Shared.Mutations)
local Characters = require(Shared.Characters)
local CharacterModel = require(Shared.CharacterModel)

local SpawnService = {}

-- set by GameServer: (player, model) -> void
SpawnService.onCatch = nil

local rng = Random.new()
local wild = {} -- model -> { drift = number, expires = number?, phase = number, y = number, x = number, z = number }
local folder = nil
local sinceSpawn = 0

local FACE_EAST = CFrame.Angles(0, -math.pi / 2, 0)

local function countCommon()
	local n = 0
	for model in pairs(wild) do
		if model:GetAttribute("Rarity") == "Common" then
			n += 1
		end
	end
	return n
end

local function wildCount()
	local n = 0
	for _ in pairs(wild) do
		n += 1
	end
	return n
end

local function attachPrompt(model)
	local root = model.PrimaryPart
	local h = model:GetAttribute("Height") or 4
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, h * 0.5, 0)
	att.Parent = root
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "Catch"
	pr.ActionText = "Catch (hold)"
	pr.ObjectText = model.Name
	pr.HoldDuration = Config.CatchHold
	pr.MaxActivationDistance = 13
	pr.RequiresLineOfSight = false
	pr.KeyboardKeyCode = Enum.KeyCode.E
	pr.Parent = att
	pr.Triggered:Connect(function(player)
		if SpawnService.onCatch and wild[model] then
			SpawnService.onCatch(player, model)
		end
	end)
end

local function register(charId, mutation, x, z, drift, lifetime)
	local at = CFrame.new(x, 0, z) * FACE_EAST
	local model = CharacterModel.build(charId, mutation, at, true, 1)
	model:SetAttribute("Wild", true)
	model:SetAttribute("Price", 0)
	model.Parent = folder
	attachPrompt(model)
	wild[model] = {
		drift = drift,
		expires = lifetime and (os.clock() + lifetime) or nil,
		phase = rng:NextNumber() * 6.28,
		x = x,
		z = z,
	}
	return model
end

local function pickCharacter(forceCommon)
	local rIdx = forceCommon and 1 or Rarity.roll(rng)
	local list = Characters.ByRarity[Rarity.get(rIdx).name]
	return list[rng:NextInteger(1, #list)]
end

function SpawnService.spawnLane()
	if wildCount() >= Config.Lane.MaxWild then
		return
	end
	local L = Config.Lane
	local def = pickCharacter(countCommon() < 2)
	local span = L.Width / 2 - 3
	local z = L.Z + (rng:NextNumber() * 2 - 1) * span
	register(def.id, Mutations.roll(rng), -L.HalfLength, z, L.Speed, nil)
end

function SpawnService.spawnDropped(charId, mutation, pos)
	register(charId, mutation, pos.X, pos.Z, 0, 25)
end

function SpawnService.remove(model)
	if wild[model] then
		wild[model] = nil
		model:Destroy()
	end
end

function SpawnService.has(model)
	return wild[model] ~= nil
end

function SpawnService.init()
	folder = Instance.new("Folder")
	folder.Name = "Wild"
	folder.Parent = Workspace

	-- a few characters already on the lane so the first screen is never empty
	local L = Config.Lane
	for i = 1, 4 do
		local def = pickCharacter(i <= 2)
		local x = -L.HalfLength + i * 30
		local z = L.Z + (rng:NextNumber() * 2 - 1) * (L.Width / 2 - 3)
		register(def.id, Mutations.roll(rng), x, z, L.Speed, nil)
	end

	RunService.Heartbeat:Connect(function(dt)
		sinceSpawn += dt
		if sinceSpawn >= L.SpawnEvery then
			sinceSpawn = 0
			SpawnService.spawnLane()
		end
		local now = os.clock()
		for model, w in pairs(wild) do
			if not model.Parent or (w.expires and now > w.expires) or w.x > L.HalfLength then
				wild[model] = nil
				model:Destroy()
			else
				w.x += w.drift * dt
				local bob = math.sin(now * 3 + w.phase) * 0.35
				model:PivotTo(CFrame.new(w.x, 0.4 + bob, w.z) * FACE_EAST)
			end
		end
	end)
end

return SpawnService
