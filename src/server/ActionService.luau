-- 画面ボタン・キー入力から届く操作（転生・ブーツ・レア度解放・手放す）をサーバーで検証して実行する。
local Config = require(game.ReplicatedStorage.Shared.Config)
local Economy = require(game.ReplicatedStorage.Shared.Economy)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerState = require(script.Parent.PlayerState)
local BaseService = require(script.Parent.BaseService)
local CarryService = require(script.Parent.CarryService)
local Notice = require(script.Parent.Notice)

local ActionService = {}

local actionRemote = Remotes.get("Action")

local function rebirth(player: Player, state)
	local cost = Economy.rebirthCost(state.rebirths)
	if state.money < cost then
		Notice.send(player, "Rebirth needs $" .. Economy.formatMoney(cost) .. ".", "bad")
		return
	end
	CarryService.drop(player, false)
	BaseService.rebirthReset(player)
	state.money = Config.START_MONEY
	state.rebirths += 1
	state.tier = 1
	state.boots = 0
	CarryService.applySpeed(player)
	Notice.send(player, "REBIRTH " .. state.rebirths .. "! Income x" .. Economy.rebirthMultiplier(state.rebirths), "good")
end

local function buyBoots(player: Player, state)
	if state.boots >= Config.BOOTS_MAX_LEVEL then
		Notice.send(player, "Boots are maxed.", "info")
		return
	end
	local cost = Economy.bootsCost(state.boots)
	if state.money < cost then
		Notice.send(player, "Boots cost $" .. Economy.formatMoney(cost) .. ".", "bad")
		return
	end
	state.money -= cost
	state.boots += 1
	CarryService.applySpeed(player)
	Notice.send(player, "Dash boots level " .. state.boots .. "!", "good")
end

local function unlockTier(player: Player, state)
	local cost = Economy.nextTierCost(state.tier)
	if not cost then
		Notice.send(player, "Every rarity tier is unlocked.", "info")
		return
	end
	if state.money < cost then
		Notice.send(player, "Next tier costs $" .. Economy.formatMoney(cost) .. ".", "bad")
		return
	end
	state.money -= cost
	state.tier += 1
	Notice.send(player, "New rarity tier unlocked on the belt!", "good")
end

function ActionService.init()
	actionRemote.OnServerEvent:Connect(function(player, action)
		local state = PlayerState.get(player)
		if not state or type(action) ~= "string" then
			return
		end
		if action == "Rebirth" then
			rebirth(player, state)
		elseif action == "Boots" then
			buyBoots(player, state)
		elseif action == "UnlockTier" then
			unlockTier(player, state)
		elseif action == "Drop" then
			CarryService.drop(player, true)
		end
		PlayerState.push(player)
	end)
end

return ActionService
