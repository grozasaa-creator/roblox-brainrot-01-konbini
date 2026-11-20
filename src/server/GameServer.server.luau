-- Entry point. Builds the world, wires the services together (they never require each other in a
-- circle; callbacks are connected here) and runs the player lifecycle.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Rarity = require(Shared.Rarity)
local Characters = require(Shared.Characters)

local Server = script.Parent
local PlayerState = require(Server.PlayerState)
local Notice = require(Server.Notice)
local SaveService = require(Server.SaveService)
local WorldBuilder = require(Server.WorldBuilder)
local BaseService = require(Server.BaseService)
local SpawnService = require(Server.SpawnService)
local CarryService = require(Server.CarryService)
local StealService = require(Server.StealService)
local TideService = require(Server.TideService)
local PatrolBot = require(Server.PatrolBot)
local ActionService = require(Server.ActionService)

local remotes = Remotes.server()
PlayerState.init(remotes)
Notice.init(remotes)

local world = WorldBuilder.build()
BaseService.init(world)
SpawnService.init()
PatrolBot.init(world)
TideService.init(world, remotes)
ActionService.init(remotes)

-- callbacks that would otherwise make the services require each other
BaseService.onSteal = StealService.attempt
CarryService.onDropped = SpawnService.spawnDropped

SpawnService.onCatch = function(player, model)
	local st = PlayerState.get(player)
	local char = player.Character
	if not st or not char or not SpawnService.has(model) then
		return
	end
	if st.carrying then
		Notice.send(player, "Hands full - run it to your base first", "bad")
		return
	end
	if os.clock() < st.stunUntil then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	local target = model.PrimaryPart
	if not root or not target or (root.Position - target.Position).Magnitude > 22 then
		return
	end
	local rarityIdx = Rarity.indexOf(model:GetAttribute("Rarity") or "Common")
	if rarityIdx > st.tier then
		local need = Rarity.get(rarityIdx)
		Notice.send(player, need.name .. " needs the " .. need.name .. " tier - upgrade first", "bad")
		return
	end
	local charId = model:GetAttribute("CharId")
	local mutation = model:GetAttribute("Mutation")
	SpawnService.remove(model)
	CarryService.pick(player, charId, mutation)
	local def = Characters.get(charId)
	Notice.send(player, "Got " .. def.name .. "! Run to your base", "good")
end

local function onCharacter(player, character)
	local hum = character:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end
	CarryService.refreshSpeed(player)
	PlayerState.push(player)
	hum.Died:Connect(function()
		local st = PlayerState.get(player)
		if st and st.carrying then
			CarryService.drop(player)
		end
		task.delay(2, function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
end

local function onPlayer(player)
	local saved = SaveService.load(player)
	PlayerState.create(player, saved)
	BaseService.assign(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	player:LoadCharacter()
	PlayerState.push(player)
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	local st = PlayerState.get(player)
	if st and st.carrying then
		CarryService.drop(player)
	end
	SaveService.save(player, st)
	BaseService.release(player)
	PlayerState.remove(player)
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		SaveService.save(p, PlayerState.get(p))
	end
end)

-- slow loops: income every quarter second, client snapshot every half second, autosave
local accIncome, accPush, accSave = 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	accIncome += dt
	accPush += dt
	accSave += dt
	if accIncome >= 0.25 then
		BaseService.tick(accIncome)
		accIncome = 0
	end
	if accPush >= 0.5 then
		accPush = 0
		for player in pairs(PlayerState.all()) do
			PlayerState.push(player)
		end
	end
	if accSave >= Config.AutosaveSeconds then
		accSave = 0
		for player, st in pairs(PlayerState.all()) do
			task.spawn(SaveService.save, player, st)
		end
	end
end)
