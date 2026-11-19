-- プレイヤーごとの状態の唯一の置き場。お金・所持・台座・図鑑は全てここ（サーバー権威）。
local Config = require(game.ReplicatedStorage.Shared.Config)
local Economy = require(game.ReplicatedStorage.Shared.Economy)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local PlayerState = {}

local states = {}
local stateRemote = Remotes.get("State")

function PlayerState.create(player: Player, saved)
	saved = saved or {}
	local state = {
		money = saved.money or Config.START_MONEY,
		rebirths = saved.rebirths or 0,
		tier = saved.tier or 1,
		boots = saved.boots or 0,
		codex = saved.codex or {},
		slots = saved.slots or {}, -- [台座番号] = { charId =, mutation = }
		meters = {}, -- [台座番号] = 貯まった収益
		carrying = nil, -- { charId =, mutation = }
		baseIndex = nil,
		lockUntil = 0,
		stealCooldownUntil = 0,
	}
	states[player] = state
	return state
end

function PlayerState.get(player: Player)
	return states[player]
end

function PlayerState.remove(player: Player)
	states[player] = nil
end

function PlayerState.all()
	return states
end

function PlayerState.incomePerSecond(state): number
	local total = 0
	for _, slot in pairs(state.slots) do
		total += Economy.incomePerSecond(slot.charId, slot.mutation, state.rebirths)
	end
	return total
end

function PlayerState.registerCodex(state, charId: string, mutationId: string?)
	local entry = state.codex[charId]
	if not entry then
		entry = { count = 0 }
		state.codex[charId] = entry
	end
	entry.count += 1
	if mutationId and mutationId ~= "" then
		entry[mutationId] = true
	end
end

function PlayerState.addMoney(state, amount: number)
	state.money += amount
end

-- クライアントへ見せる表示用の写し。値の変更は必ずサーバー側で行い、ここは読み取り専用。
function PlayerState.push(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local carryingName = nil
	if state.carrying then
		carryingName = state.carrying.charId
	end
	stateRemote:FireClient(player, {
		money = state.money,
		rebirths = state.rebirths,
		tier = state.tier,
		boots = state.boots,
		bootsMax = Config.BOOTS_MAX_LEVEL,
		income = PlayerState.incomePerSecond(state),
		codex = state.codex,
		carrying = carryingName,
		carryingMutation = state.carrying and state.carrying.mutation or nil,
		lockLeft = math.max(0, math.ceil(state.lockUntil - os.clock())),
		rebirthCost = Economy.rebirthCost(state.rebirths),
		bootsCost = state.boots < Config.BOOTS_MAX_LEVEL and Economy.bootsCost(state.boots) or nil,
		tierCost = Economy.nextTierCost(state.tier),
		lockCost = Config.LOCK_COST,
	})
end

function PlayerState.serialize(state)
	return {
		money = state.money,
		rebirths = state.rebirths,
		tier = state.tier,
		boots = state.boots,
		codex = state.codex,
		slots = state.slots,
	}
end

return PlayerState
