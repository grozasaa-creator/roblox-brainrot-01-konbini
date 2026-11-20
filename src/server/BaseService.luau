-- Bases: ownership, pedestal contents, the income meters and the collect actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)
local Characters = require(Shared.Characters)
local CharacterModel = require(Shared.CharacterModel)

local PlayerState = require(script.Parent.PlayerState)
local Notice = require(script.Parent.Notice)
local CarryService = require(script.Parent.CarryService)

local BaseService = {}

-- set by GameServer: (player, pedestalPart) -> void
BaseService.onSteal = nil

local world = nil

local FREE = Color3.fromRGB(90, 255, 235)
local IDLE = Color3.fromRGB(150, 150, 175)

local function baseOf(index)
	return world.bases[index]
end

local function setSign(base, text)
	for _, label in ipairs(base.signLabels) do
		label.Text = text
	end
end

local function clearPedestalVisual(base, slot)
	local m = base.models[slot]
	if m then
		m.model:Destroy()
		base.models[slot] = nil
	end
	local ped = base.pedestals[slot]
	ped.part:SetAttribute("Filled", false)
	ped.part:SetAttribute("Income", 0)
	ped.part:SetAttribute("Meter", 0)
end

-- make the base's pedestals match the owner's slots
function BaseService.refresh(player)
	local st = PlayerState.get(player)
	if not st or not st.baseIndex then
		return
	end
	local base = baseOf(st.baseIndex)
	for s = 1, Config.PedestalsPerBase do
		local data = st.slots[s]
		local ped = base.pedestals[s]
		local cached = base.models[s]
		if data then
			local key = data.charId .. "|" .. data.mutation
			if not cached or cached.key ~= key then
				clearPedestalVisual(base, s)
				local at = CFrame.new(ped.pos + Vector3.new(0, 2.4, 0))
				local model = CharacterModel.build(data.charId, data.mutation, at, true, 1)
				model:SetAttribute("Placed", true)
				model:SetAttribute("Wild", false)
				model.Parent = base.folder
				base.models[s] = { key = key, model = model }
			end
			local def = Characters.get(data.charId)
			local inc = Economy.income(data.charId, data.mutation, st.rebirths)
			ped.part:SetAttribute("Filled", true)
			ped.part:SetAttribute("Income", inc)
			ped.part:SetAttribute("Meter", math.floor(data.meter))
			ped.frame.Color = Rarity.get(Rarity.indexOf(def.rarity)).color
		else
			clearPedestalVisual(base, s)
			ped.frame.Color = FREE
		end
		ped.part:SetAttribute("OwnerUserId", player.UserId)
	end
	base.owner = player
	setSign(base, string.upper(player.DisplayName) .. "'S BASE")
end

function BaseService.assign(player)
	local st = PlayerState.get(player)
	for _, base in ipairs(world.bases) do
		if not base.owner then
			base.owner = player
			st.baseIndex = base.index
			st.basePos = base.center
			st.gatePos = base.gate
			BaseService.refresh(player)
			return base
		end
	end
	Notice.send(player, "Server is full - no free base", "bad")
	return nil
end

function BaseService.release(player)
	for _, base in ipairs(world.bases) do
		if base.owner == player then
			for s = 1, Config.PedestalsPerBase do
				clearPedestalVisual(base, s)
				base.pedestals[s].part:SetAttribute("OwnerUserId", 0)
				base.pedestals[s].frame.Color = IDLE
			end
			base.owner = nil
			setSign(base, "FREE BASE")
		end
	end
end

local function placeOn(player, ped)
	local st = PlayerState.get(player)
	if not st or not st.carrying then
		return
	end
	local slot = ped:GetAttribute("Slot")
	if ped:GetAttribute("BaseIndex") ~= st.baseIndex then
		Notice.send(player, "That is not your base - run to your glowing one!", "bad")
		return
	end
	if st.slots[slot] then
		return
	end
	local c = st.carrying
	st.slots[slot] = { charId = c.charId, mutation = c.mutation, meter = 0 }
	CarryService.clear(player)
	BaseService.refresh(player)
	local def = Characters.get(c.charId)
	Notice.send(player, def.name .. " placed! +" .. Economy.money(Economy.income(c.charId, c.mutation, st.rebirths)) .. "/s", "good")
	PlayerState.push(player)
end

-- move every pedestal's meter into the wallet (slot == nil) or just one
function BaseService.collect(player, slot)
	local st = PlayerState.get(player)
	if not st then
		return 0
	end
	local total = 0
	for s = 1, Config.PedestalsPerBase do
		local data = st.slots[s]
		if data and data.meter > 0 and (slot == nil or slot == s) then
			total += data.meter
			data.meter = 0
		end
	end
	if total >= 1 then
		st.money += math.floor(total)
		if st.baseIndex then
			for s = 1, Config.PedestalsPerBase do
				baseOf(st.baseIndex).pedestals[s].part:SetAttribute("Meter", 0)
			end
		end
		Notice.send(player, "+" .. Economy.money(total), "good")
		PlayerState.push(player)
	end
	return total
end

function BaseService.lock(player)
	local st = PlayerState.get(player)
	if not st or not st.baseIndex then
		return
	end
	if st.money < Config.LockCost then
		Notice.send(player, "Lock needs " .. Economy.money(Config.LockCost), "bad")
		return
	end
	st.money -= Config.LockCost
	st.lockUntil = os.clock() + Config.LockSeconds
	Notice.send(player, "Base locked for " .. Config.LockSeconds .. "s", "good")
	PlayerState.push(player)
end

-- advance every owner's meters; called a few times a second by GameServer
function BaseService.tick(dt)
	local now = os.clock()
	for player, st in pairs(PlayerState.all()) do
		if st.baseIndex then
			local base = baseOf(st.baseIndex)
			for s = 1, Config.PedestalsPerBase do
				local data = st.slots[s]
				if data then
					local inc = Economy.income(data.charId, data.mutation, st.rebirths)
					data.meter = math.min(data.meter + inc * dt, inc * Config.MeterCap)
					local shown = math.floor(data.meter)
					local ped = base.pedestals[s].part
					if ped:GetAttribute("Meter") ~= shown then
						ped:SetAttribute("Meter", shown)
					end
				end
			end
			local locked = now < st.lockUntil
			base.ring.Color = locked and Color3.fromRGB(255, 70, 70) or base.hue
			if locked then
				setSign(base, "LOCKED " .. math.ceil(st.lockUntil - now))
			elseif base.lastLocked then
				setSign(base, string.upper(player.DisplayName) .. "'S BASE")
			end
			base.lastLocked = locked
		end
	end
end

function BaseService.init(builtWorld)
	world = builtWorld
	for _, base in ipairs(world.bases) do
		for s = 1, Config.PedestalsPerBase do
			local ped = base.pedestals[s].part
			ped.PromptAnchor.Place.Triggered:Connect(function(player)
				placeOn(player, ped)
			end)
			ped.PromptAnchor.Collect.Triggered:Connect(function(player)
				local st = PlayerState.get(player)
				if st and st.baseIndex == base.index then
					BaseService.collect(player, s)
				end
			end)
			ped.PromptAnchor.Steal.Triggered:Connect(function(player)
				if BaseService.onSteal then
					BaseService.onSteal(player, ped)
				end
			end)
		end

		-- stepping on the gold pad in the middle empties every meter at once
		local debounce = {}
		base.collectPad.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player then
				return
			end
			local st = PlayerState.get(player)
			if not st or st.baseIndex ~= base.index or debounce[player] then
				return
			end
			debounce[player] = true
			BaseService.collect(player, nil)
			task.delay(0.7, function()
				debounce[player] = nil
			end)
		end)
	end
end

return BaseService
