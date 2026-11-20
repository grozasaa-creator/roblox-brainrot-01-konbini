-- Everything a client may ask for through the Action remote. Each handler validates against PlayerState;
-- the client's request is only a request.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)

local PlayerState = require(script.Parent.PlayerState)
local Notice = require(script.Parent.Notice)
local CarryService = require(script.Parent.CarryService)
local BaseService = require(script.Parent.BaseService)

local ActionService = {}

local handlers = {}

function handlers.Drop(player)
	CarryService.drop(player)
end

function handlers.BuyTier(player, st)
	if st.tier >= Rarity.Count then
		Notice.send(player, "Top rarity already unlocked", "info")
		return
	end
	local nxt = Rarity.get(st.tier + 1)
	if st.money < nxt.tierCost then
		Notice.send(player, nxt.name .. " tier costs " .. Economy.money(nxt.tierCost), "bad")
		return
	end
	st.money -= nxt.tierCost
	st.tier += 1
	Notice.send(player, "You can now catch " .. nxt.name .. "!", "good")
end

function handlers.BuyBoots(player, st)
	if st.boots >= Economy.BootsMax then
		Notice.send(player, "Boots are maxed", "info")
		return
	end
	local cost = Economy.bootsCost(st.boots)
	if st.money < cost then
		Notice.send(player, "Boots cost " .. Economy.money(cost), "bad")
		return
	end
	st.money -= cost
	st.boots += 1
	CarryService.refreshSpeed(player)
	Notice.send(player, "Faster boots! Level " .. st.boots, "good")
end

function handlers.Rebirth(player, st)
	local cost = Economy.rebirthCost(st.rebirths)
	if st.money < cost then
		Notice.send(player, "Rebirth costs " .. Economy.money(cost), "bad")
		return
	end
	CarryService.clear(player)
	st.money = 0
	st.tier = 1
	st.slots = {}
	st.rebirths += 1
	BaseService.refresh(player)
	Notice.send(player, "REBIRTH " .. st.rebirths .. "! Income bonus +" .. (Economy.RebirthBonus * 100) .. "%", "good")
end

function handlers.Lock(player)
	BaseService.lock(player)
end

function handlers.Collect(player)
	BaseService.collect(player, nil)
end

function ActionService.init(remotes)
	remotes.Action.OnServerEvent:Connect(function(player, action)
		if type(action) ~= "string" then
			return
		end
		local fn = handlers[action]
		local st = PlayerState.get(player)
		if not fn or not st then
			return
		end
		fn(player, st)
		PlayerState.push(player)
	end)
end

return ActionService
