-- Taking a character off someone else's pedestal. Holding the prompt is the "hold 0.8s" cost;
-- the server re-checks everything because the prompt state on the client is only a hint.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Characters = require(Shared.Characters)

local PlayerState = require(script.Parent.PlayerState)
local Notice = require(script.Parent.Notice)
local CarryService = require(script.Parent.CarryService)
local BaseService = require(script.Parent.BaseService)

local StealService = {}

function StealService.attempt(thief, ped)
	local ownerId = ped:GetAttribute("OwnerUserId")
	local owner = ownerId and Players:GetPlayerByUserId(ownerId)
	if not owner or owner == thief then
		return
	end
	local ts, os_ = PlayerState.get(thief), PlayerState.get(owner)
	if not ts or not os_ then
		return
	end
	local now = os.clock()
	local slot = ped:GetAttribute("Slot")
	local data = os_.slots[slot]
	if not data then
		return
	end
	if ts.carrying then
		Notice.send(thief, "Your hands are full", "bad")
		return
	end
	if now < os_.lockUntil then
		Notice.send(thief, "That base is locked!", "bad")
		return
	end
	if now < ts.stealReadyAt then
		Notice.send(thief, "Steal cooling down", "bad")
		return
	end

	os_.slots[slot] = nil
	ts.stealReadyAt = now + Config.StealCooldown
	BaseService.refresh(owner)
	CarryService.pick(thief, data.charId, data.mutation)

	local def = Characters.get(data.charId)
	Notice.send(thief, "Stolen " .. def.name .. "! Run to your base!", "good")
	Notice.send(owner, thief.DisplayName .. " stole your " .. def.name .. "!", "bad")
	PlayerState.push(owner)
end

return StealService
