-- The single home of per-player game state. Services mutate it; the client only ever sees snapshots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)

local PlayerState = {}

local states = {}
local remotes = nil

function PlayerState.init(r)
	remotes = r
end

local function blank()
	return {
		money = 0,
		rebirths = 0,
		tier = 1,
		boots = 0,
		slots = {}, -- [1..PedestalsPerBase] = { charId, mutation, meter }
		seen = {}, -- charId -> true (codex)
		carrying = nil, -- { charId, mutation }
		baseIndex = nil,
		basePos = nil,
		gatePos = nil,
		lockUntil = 0,
		stealReadyAt = 0,
		stunUntil = 0,
	}
end

function PlayerState.create(player, saved)
	local st = blank()
	if saved then
		st.money = tonumber(saved.money) or 0
		st.rebirths = tonumber(saved.rebirths) or 0
		st.tier = math.clamp(tonumber(saved.tier) or 1, 1, Rarity.Count)
		st.boots = math.clamp(tonumber(saved.boots) or 0, 0, Economy.BootsMax)
		for id, v in pairs(saved.seen or {}) do
			if v then
				st.seen[id] = true
			end
		end
		for _, s in ipairs(saved.slots or {}) do
			local i = tonumber(s.slot)
			if i and i >= 1 and i <= Config.PedestalsPerBase and s.c then
				st.slots[i] = { charId = s.c, mutation = s.m or "None", meter = tonumber(s.t) or 0 }
			end
		end
	end
	states[player] = st
	return st
end

function PlayerState.get(player)
	return states[player]
end

function PlayerState.remove(player)
	states[player] = nil
end

function PlayerState.all()
	return states
end

function PlayerState.firstFreeSlot(st)
	for i = 1, Config.PedestalsPerBase do
		if not st.slots[i] then
			return i
		end
	end
	return nil
end

function PlayerState.totalIncome(st)
	local sum = 0
	for i = 1, Config.PedestalsPerBase do
		local s = st.slots[i]
		if s then
			sum += Economy.income(s.charId, s.mutation, st.rebirths)
		end
	end
	return sum
end

function PlayerState.pending(st)
	local sum = 0
	for i = 1, Config.PedestalsPerBase do
		local s = st.slots[i]
		if s then
			sum += s.meter
		end
	end
	return sum
end

function PlayerState.filledCount(st)
	local n = 0
	for i = 1, Config.PedestalsPerBase do
		if st.slots[i] then
			n += 1
		end
	end
	return n
end

function PlayerState.snapshot(st)
	local nextTier = st.tier < Rarity.Count and Rarity.get(st.tier + 1) or nil
	return {
		money = st.money,
		rebirths = st.rebirths,
		tier = st.tier,
		tierName = Rarity.get(st.tier).name,
		nextTierName = nextTier and nextTier.name or nil,
		nextTierCost = nextTier and nextTier.tierCost or nil,
		boots = st.boots,
		bootsCost = st.boots < Economy.BootsMax and Economy.bootsCost(st.boots) or nil,
		rebirthCost = Economy.rebirthCost(st.rebirths),
		income = PlayerState.totalIncome(st),
		pending = PlayerState.pending(st),
		filled = PlayerState.filledCount(st),
		carrying = st.carrying and { charId = st.carrying.charId, mutation = st.carrying.mutation } or nil,
		baseIndex = st.baseIndex,
		basePos = st.basePos,
		gatePos = st.gatePos,
		lockLeft = math.max(0, st.lockUntil - os.clock()),
		stunLeft = math.max(0, st.stunUntil - os.clock()),
		seen = st.seen,
	}
end

function PlayerState.push(player)
	local st = states[player]
	if st and remotes then
		remotes.State:FireClient(player, PlayerState.snapshot(st))
	end
end

return PlayerState
