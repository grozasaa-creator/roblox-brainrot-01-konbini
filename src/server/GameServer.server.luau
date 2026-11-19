-- サーバーの起動点。街を作り、各サービスを初期化し、プレイヤーの出入りを配線する。
local Players = game:GetService("Players")

local PlayerState = require(script.Parent.PlayerState)
local SaveService = require(script.Parent.SaveService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local BaseService = require(script.Parent.BaseService)
local SpawnService = require(script.Parent.SpawnService)
local CarryService = require(script.Parent.CarryService)
local StealService = require(script.Parent.StealService)
local ActionService = require(script.Parent.ActionService)
local PatrolBot = require(script.Parent.PatrolBot)
local TideService = require(script.Parent.TideService)
local Notice = require(script.Parent.Notice)
local Config = require(game.ReplicatedStorage.Shared.Config)

local world = WorldBuilder.build()
BaseService.init(world)
SpawnService.init(world)
SpawnService.onCatch = CarryService.pickUp
CarryService.init()
StealService.init()
ActionService.init()
PatrolBot.init(world)
TideService.init()

local function onPlayerAdded(player: Player)
	local saved = SaveService.load(player)
	PlayerState.create(player, saved)
	local base = BaseService.assign(player)
	if not base then
		Notice.send(player, "Town is full. Spectating until a base frees up.", "warn")
	end
	player.CharacterAdded:Connect(function(character)
		CarryService.hookCharacter(player, character)
		-- CharacterAutoLoads を切っているので、倒れたら自分たちで復活させる。
		character:WaitForChild("Humanoid").Died:Connect(function()
			task.wait(Players.RespawnTime)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
	player:LoadCharacter()
	PlayerState.push(player)
end

local function onPlayerRemoving(player: Player)
	CarryService.drop(player, false)
	SaveService.save(player)
	BaseService.release(player)
	PlayerState.remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_SECONDS)
		for _, player in ipairs(Players:GetPlayers()) do
			SaveService.save(player)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		SaveService.save(player)
	end
end)
