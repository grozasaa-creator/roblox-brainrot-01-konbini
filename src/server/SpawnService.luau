-- 街を歩く野良キャラと、中央ベルトを流れる売り物キャラの出現・移動・購入。
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Characters = require(game.ReplicatedStorage.Shared.Characters)
local Rarity = require(game.ReplicatedStorage.Shared.Rarity)
local Mutations = require(game.ReplicatedStorage.Shared.Mutations)
local Economy = require(game.ReplicatedStorage.Shared.Economy)
local CharacterModel = require(game.ReplicatedStorage.Shared.CharacterModel)
local PlayerState = require(script.Parent.PlayerState)
local BaseService = require(script.Parent.BaseService)
local Notice = require(script.Parent.Notice)

local SpawnService = {}

-- GameServer が差し込む。野良キャラを捕まえたときの処理（CarryService 側）。
SpawnService.onCatch = nil

local wilds = {} -- { model =, target =, nextTurn = }
local beltItems = {} -- { model =, x = }
local shelters = {}
local wildFolder
local beltFolder
local clock = 0

local function pickDefinition(rarityName: string)
	local pool = Characters.byRarity[rarityName]
	return pool[math.random(1, #pool)]
end

local function inBlockedZone(x: number, z: number): boolean
	if math.abs(z) < 10 and math.abs(x) < Config.BELT_HALF_LENGTH + 6 then
		return true
	end
	for _, s in ipairs(shelters) do
		if math.abs(x - s.cx) < s.hx + 4 and math.abs(z - s.cz) < s.hz + 4 then
			return true
		end
	end
	return false
end

local function randomStreetPoint(): Vector3
	for _ = 1, 12 do
		local angle = math.random() * math.pi * 2
		local radius = math.sqrt(math.random()) * Config.WILD_AREA_RADIUS
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		if not inBlockedZone(x, z) then
			return Vector3.new(x, 0, z)
		end
	end
	return Vector3.new(0, 0, 30)
end

function SpawnService.spawnWild(charId: string, mutation: string?, position: Vector3?)
	local model = CharacterModel.build(charId, mutation)
	model:SetAttribute("Wild", true)
	local pos = position or randomStreetPoint()
	model:PivotTo(CFrame.new(pos.X, 0, pos.Z))

	local body = model:FindFirstChild("Body")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CatchPrompt"
	prompt.ActionText = "Catch"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = Config.CATCH_HOLD_SECONDS
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		if model:GetAttribute("Taken") then
			return
		end
		if SpawnService.onCatch and SpawnService.onCatch(player, model) then
			model:SetAttribute("Taken", true)
			SpawnService.removeWild(model)
		end
	end)

	model.Parent = wildFolder
	table.insert(wilds, { model = model, target = randomStreetPoint(), nextTurn = clock + 4 + math.random() * 4 })
	return model
end

function SpawnService.removeWild(model: Model)
	for i, wild in ipairs(wilds) do
		if wild.model == model then
			table.remove(wilds, i)
			break
		end
	end
	model:Destroy()
end

function SpawnService.countWilds(): number
	return #wilds
end

local function spawnBeltItem()
	local rarity = Rarity.pickWeighted(nil, true)
	local def = pickDefinition(rarity.name)
	local mutation = Mutations.roll()
	local model = CharacterModel.build(def.id, mutation)
	model:ScaleTo(0.8)
	local price = Economy.price(def.id, mutation)
	model:SetAttribute("Price", price)

	local body = model:FindFirstChild("Body")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy $" .. Economy.formatMoney(price)
	prompt.ObjectText = model.Name .. " (" .. def.rarity .. ")"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player)
		SpawnService.buy(player, model)
	end)

	model:PivotTo(CFrame.new(-Config.BELT_HALF_LENGTH, 0.7, 0))
	model.Parent = beltFolder
	table.insert(beltItems, { model = model, x = -Config.BELT_HALF_LENGTH })
end

function SpawnService.buy(player: Player, model: Model)
	local state = PlayerState.get(player)
	if not state or model:GetAttribute("Sold") then
		return
	end
	local charId = model:GetAttribute("CharId")
	local mutation = model:GetAttribute("Mutation")
	if mutation == "" then
		mutation = nil
	end
	local rarity = Rarity.byName[model:GetAttribute("Rarity")]
	if rarity.order > state.tier then
		Notice.send(player, "Unlock the " .. rarity.name .. " tier first (bottom bar).", "bad")
		return
	end
	local price = model:GetAttribute("Price")
	if state.money < price then
		Notice.send(player, "Not enough money.", "bad")
		return
	end
	if not state.baseIndex then
		return
	end
	local slotIndex = BaseService.placeCharacter(player, charId, mutation)
	if not slotIndex then
		Notice.send(player, "Your base is full (rebirth for a fresh start).", "bad")
		return
	end
	state.money -= price
	model:SetAttribute("Sold", true)
	for i, item in ipairs(beltItems) do
		if item.model == model then
			table.remove(beltItems, i)
			break
		end
	end
	model:Destroy()
	Notice.send(player, "Bought " .. Characters.byId[charId].name .. "!", "good")
	PlayerState.push(player)
end

function SpawnService.init(world)
	shelters = world.shelters
	wildFolder = Instance.new("Folder")
	wildFolder.Name = "Wild"
	wildFolder.Parent = workspace
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "Belt"
	beltFolder.Parent = workspace

	RunService.Heartbeat:Connect(function(dt)
		clock += dt
		for _, wild in ipairs(wilds) do
			local model = wild.model
			local pos = model:GetPivot().Position
			local flat = Vector3.new(wild.target.X - pos.X, 0, wild.target.Z - pos.Z)
			if flat.Magnitude < 2 or clock > wild.nextTurn then
				wild.target = randomStreetPoint()
				wild.nextTurn = clock + 4 + math.random() * 4
			else
				local step = flat.Unit * Config.WILD_SPEED * dt
				local newPos = pos + step
				local hop = math.abs(math.sin(clock * 6 + pos.X)) * 0.5
				model:PivotTo(CFrame.lookAt(Vector3.new(newPos.X, hop, newPos.Z), Vector3.new(wild.target.X, hop, wild.target.Z)) * CFrame.Angles(0, math.pi, 0))
			end
		end
		for i = #beltItems, 1, -1 do
			local item = beltItems[i]
			item.x += Config.BELT_SPEED * dt
			if item.x > Config.BELT_HALF_LENGTH then
				item.model:Destroy()
				table.remove(beltItems, i)
			else
				item.model:PivotTo(CFrame.new(item.x, 0.7, 0))
			end
		end
	end)

	task.spawn(function()
		while true do
			-- 起動直後は街が空に見えないよう、足りない分を一気に補充する。
			while #wilds < Config.WILD_MAX // 2 do
				local first = Rarity.pickWeighted()
				SpawnService.spawnWild(pickDefinition(first.name).id, Mutations.roll(), nil)
			end
			if #wilds < Config.WILD_MAX then
				local rarity = Rarity.pickWeighted()
				local def = pickDefinition(rarity.name)
				SpawnService.spawnWild(def.id, Mutations.roll(), nil)
			end
			task.wait(Config.WILD_RESPAWN_SECONDS)
		end
	end)
	task.spawn(function()
		while true do
			spawnBeltItem()
			task.wait(Config.BELT_SPAWN_SECONDS)
		end
	end)
end

return SpawnService
