-- DataStore への保存と読み込み。Studio で API が許可されていなくても失敗を握って続行する。
local DataStoreService = game:GetService("DataStoreService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local PlayerState = require(script.Parent.PlayerState)

local SaveService = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	end
end

local function keyOf(player: Player): string
	return "player_" .. tostring(player.UserId)
end

function SaveService.load(player: Player)
	if not store then
		return nil
	end
	local ok, data = pcall(function()
		return store:GetAsync(keyOf(player))
	end)
	if ok and type(data) == "table" then
		return data
	end
	return nil
end

function SaveService.save(player: Player)
	local state = PlayerState.get(player)
	if not store or not state then
		return
	end
	pcall(function()
		store:SetAsync(keyOf(player), PlayerState.serialize(state))
	end)
end

return SaveService
