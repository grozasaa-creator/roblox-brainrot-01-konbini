-- 盗み。持ち歩き中のキャラ、または鍵のかかっていない拠点の台座から奪って自分で持つ。
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Characters = require(game.ReplicatedStorage.Shared.Characters)
local PlayerState = require(script.Parent.PlayerState)
local BaseService = require(script.Parent.BaseService)
local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)

local StealService = {}

local function canSteal(thief: Player): boolean
	local state = PlayerState.get(thief)
	if not state then
		return false
	end
	if state.carrying then
		Notice.send(thief, "Your hands are full. Store your brainrot first.", "bad")
		return false
	end
	if os.clock() < state.stealCooldownUntil then
		return false
	end
	return true
end

local function markCooldown(thief: Player)
	PlayerState.get(thief).stealCooldownUntil = os.clock() + Config.STEAL_COOLDOWN_SECONDS
end

-- 持ち歩き中のキャラを奪う。拠点の中にいる持ち主からは奪えない。
local function stealFromCarrier(thief: Player, victim: Player)
	if thief == victim or not canSteal(thief) then
		return
	end
	local victimRoot = victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
	if victimRoot and BaseService.isSafe(victimRoot.Position) and BaseService.isInOwnBase(victim, victimRoot.Position) then
		Notice.send(thief, "Can't steal inside their base!", "bad")
		return
	end
	local carried = CarryService.take(victim)
	if not carried then
		return
	end
	markCooldown(thief)
	CarryService.give(thief, carried.charId, carried.mutation)
	Notice.send(victim, thief.DisplayName .. " stole your " .. Characters.byId[carried.charId].name .. "!", "bad")
end

local function stealFromPedestal(thief: Player, baseIndex: number, slotIndex: number)
	if not canSteal(thief) then
		return
	end
	local base = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		if state and state.baseIndex == baseIndex then
			base = player
		end
	end
	if not base or base == thief then
		return
	end
	local ownerState = PlayerState.get(base)
	if BaseService.isLocked(ownerState) then
		Notice.send(thief, "That base is locked!", "bad")
		return
	end
	local slot = BaseService.removeSlot(base, slotIndex)
	if not slot then
		return
	end
	markCooldown(thief)
	CarryService.give(thief, slot.charId, slot.mutation)
	Notice.send(base, thief.DisplayName .. " stole " .. Characters.byId[slot.charId].name .. " from your base!", "bad")
	PlayerState.push(base)
end

function StealService.init()
	CarryService.onStealFromCarrier = stealFromCarrier
	BaseService.onStealFromPedestal = stealFromPedestal
end

return StealService
