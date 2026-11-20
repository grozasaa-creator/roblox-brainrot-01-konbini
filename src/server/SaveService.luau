-- DataStore persistence. Every call is pcall-guarded: in Studio without API access the game simply
-- runs without saving.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Characters = require(Shared.Characters)

local SaveService = {}

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.StoreName)
	end)
	if ok then
		store = result
	end
end

local function keyFor(player)
	return "u" .. player.UserId
end

function SaveService.load(player)
	if not store then
		return nil
	end
	local ok, data = pcall(function()
		return store:GetAsync(keyFor(player))
	end)
	if ok and type(data) == "table" then
		-- drop characters that no longer exist
		local keep = {}
		for _, s in ipairs(data.slots or {}) do
			if Characters.get(s.c) then
				table.insert(keep, s)
			end
		end
		data.slots = keep
		return data
	end
	return nil
end

function SaveService.save(player, st)
	if not store or not st then
		return false
	end
	local payload = {
		money = st.money,
		rebirths = st.rebirths,
		tier = st.tier,
		boots = st.boots,
		seen = st.seen,
		slots = {},
	}
	for i = 1, Config.PedestalsPerBase do
		local s = st.slots[i]
		if s then
			table.insert(payload.slots, { slot = i, c = s.charId, m = s.mutation, t = math.floor(s.meter) })
		end
	end
	local ok = pcall(function()
		store:SetAsync(keyFor(player), payload)
	end)
	return ok
end

return SaveService
