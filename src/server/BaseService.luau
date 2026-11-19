-- 拠点の割り当て・台座へのキャラ配置・毎秒収益の蓄積・回収・ロック・安全地帯の判定。
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Economy = require(game.ReplicatedStorage.Shared.Economy)
local CharacterModel = require(game.ReplicatedStorage.Shared.CharacterModel)
local PlayerState = require(script.Parent.PlayerState)
local Notice = require(script.Parent.Notice)

local BaseService = {}

local bases = {}
local shelters = {}
local visuals = {} -- [baseIndex][台座番号] = 台座上のモデル

-- StealService が差し込む。台座から盗む処理（循環 require を避けるため）。
BaseService.onStealFromPedestal = nil

local STORED_SCALE = 0.6

local function clearVisual(baseIndex: number, slotIndex: number)
	local model = visuals[baseIndex] and visuals[baseIndex][slotIndex]
	if model then
		model:Destroy()
		visuals[baseIndex][slotIndex] = nil
	end
end

local function showVisual(base, slotIndex: number, slot)
	clearVisual(base.index, slotIndex)
	local model = CharacterModel.build(slot.charId, slot.mutation)
	model:ScaleTo(STORED_SCALE)
	local pedestal = base.pedestals[slotIndex]
	local top = pedestal.Position + Vector3.new(0, 0.7, 0)
	local lookAt = Vector3.new(base.center.X, top.Y, base.center.Z)
	model:PivotTo(CFrame.lookAt(top, lookAt) * CFrame.Angles(0, math.pi, 0))
	model:SetAttribute("BaseIndex", base.index)
	model:SetAttribute("SlotIndex", slotIndex)
	model:SetAttribute("Stored", true)
	local body = model:FindFirstChild("Body")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.UIOffset = Vector2.new(0, 60)
	prompt.Parent = body
	prompt.Triggered:Connect(function(thief)
		if BaseService.onStealFromPedestal then
			BaseService.onStealFromPedestal(thief, base.index, slotIndex)
		end
	end)
	model.Parent = base.folder
	visuals[base.index] = visuals[base.index] or {}
	visuals[base.index][slotIndex] = model
end

local function updateSign(base)
	local gui = base.gate:FindFirstChild("OwnerSign")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "OwnerSign"
		gui.Size = UDim2.fromOffset(260, 60)
		gui.StudsOffset = Vector3.new(0, 5, 0)
		gui.AlwaysOnTop = false
		gui.MaxDistance = 260
		gui.Parent = base.gate
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextStrokeTransparency = 0
		label.Parent = gui
	end
	local label = gui.Label
	if base.owner then
		label.Text = base.owner.DisplayName .. "'s BASE"
		label.TextColor3 = base.color
	else
		label.Text = "FREE BASE"
		label.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

function BaseService.init(world)
	bases = world.bases
	shelters = world.shelters
	for _, base in ipairs(bases) do
		updateSign(base)
		for slotIndex, pedestal in ipairs(base.pedestals) do
			pedestal.CollectPrompt.Triggered:Connect(function(player)
				BaseService.collect(player, base.index, slotIndex)
			end)
		end
		base.gate.LockPrompt.Triggered:Connect(function(player)
			BaseService.lock(player, base.index)
		end)
	end

	local sinceTick = 0
	RunService.Heartbeat:Connect(function(dt)
		for player, state in pairs(PlayerState.all()) do
			for slotIndex, slot in pairs(state.slots) do
				local rate = Economy.incomePerSecond(slot.charId, slot.mutation, state.rebirths)
				local cap = rate * Config.METER_CAP_SECONDS
				state.meters[slotIndex] = math.min(cap, (state.meters[slotIndex] or 0) + rate * dt)
			end
		end
		sinceTick += dt
		if sinceTick >= 0.5 then
			sinceTick = 0
			BaseService.refreshDisplays()
		end
	end)
end

function BaseService.refreshDisplays()
	for player, state in pairs(PlayerState.all()) do
		local base = state.baseIndex and bases[state.baseIndex]
		if base then
			for slotIndex, pedestal in ipairs(base.pedestals) do
				pedestal:SetAttribute("Meter", math.floor(state.meters[slotIndex] or 0))
				local slot = state.slots[slotIndex]
				pedestal:SetAttribute("Income", slot and Economy.incomePerSecond(slot.charId, slot.mutation, state.rebirths) or 0)
			end
			local locked = os.clock() < state.lockUntil
			base.gate.Color = locked and Color3.fromRGB(255, 40, 40) or base.color
		end
		PlayerState.push(player)
	end
end

function BaseService.assign(player: Player)
	local state = PlayerState.get(player)
	for _, base in ipairs(bases) do
		if not base.owner then
			base.owner = player
			state.baseIndex = base.index
			player.RespawnLocation = base.spawn
			updateSign(base)
			for slotIndex, slot in pairs(state.slots) do
				showVisual(base, slotIndex, slot)
			end
			return base
		end
	end
	return nil
end

function BaseService.release(player: Player)
	local state = PlayerState.get(player)
	if not state or not state.baseIndex then
		return
	end
	local base = bases[state.baseIndex]
	for slotIndex in pairs(state.slots) do
		clearVisual(base.index, slotIndex)
	end
	base.owner = nil
	base.gate.Color = base.color
	updateSign(base)
	state.baseIndex = nil
end

function BaseService.getBaseOf(player: Player)
	local state = PlayerState.get(player)
	return state and state.baseIndex and bases[state.baseIndex] or nil
end

function BaseService.isLocked(state): boolean
	return os.clock() < state.lockUntil
end

-- 空いている台座に置く。置けたら台座番号、満杯なら nil。
function BaseService.placeCharacter(player: Player, charId: string, mutation: string?)
	local state = PlayerState.get(player)
	local base = state and state.baseIndex and bases[state.baseIndex]
	if not base then
		return nil
	end
	for slotIndex = 1, Config.PEDESTALS_PER_BASE do
		if not state.slots[slotIndex] then
			state.slots[slotIndex] = { charId = charId, mutation = mutation }
			state.meters[slotIndex] = 0
			PlayerState.registerCodex(state, charId, mutation)
			showVisual(base, slotIndex, state.slots[slotIndex])
			return slotIndex
		end
	end
	return nil
end

-- 台座から外して中身を返す（盗まれたとき・転生のとき）。
function BaseService.removeSlot(player: Player, slotIndex: number)
	local state = PlayerState.get(player)
	local slot = state and state.slots[slotIndex]
	if not slot then
		return nil
	end
	state.slots[slotIndex] = nil
	state.meters[slotIndex] = nil
	if state.baseIndex then
		clearVisual(state.baseIndex, slotIndex)
	end
	return slot
end

function BaseService.collect(player: Player, baseIndex: number, slotIndex: number)
	local state = PlayerState.get(player)
	if not state or state.baseIndex ~= baseIndex then
		return
	end
	local amount = math.floor(state.meters[slotIndex] or 0)
	if amount <= 0 then
		return
	end
	state.meters[slotIndex] = (state.meters[slotIndex] or 0) - amount
	PlayerState.addMoney(state, amount)
	Notice.send(player, "+$" .. Economy.formatMoney(amount), "good")
	PlayerState.push(player)
end

function BaseService.lock(player: Player, baseIndex: number)
	local state = PlayerState.get(player)
	if not state or state.baseIndex ~= baseIndex then
		Notice.send(player, "That is not your base.", "bad")
		return
	end
	if state.money < Config.LOCK_COST then
		Notice.send(player, "Not enough money to lock the base.", "bad")
		return
	end
	state.money -= Config.LOCK_COST
	state.lockUntil = math.max(os.clock(), state.lockUntil) + Config.LOCK_SECONDS
	Notice.send(player, "Base locked. Thieves cannot take your pedestals.", "good")
	PlayerState.push(player)
end

function BaseService.rebirthReset(player: Player)
	local state = PlayerState.get(player)
	for slotIndex in pairs(state.slots) do
		clearVisual(state.baseIndex, slotIndex)
	end
	state.slots = {}
	state.meters = {}
end

local function insideBase(position: Vector3): boolean
	for _, base in ipairs(bases) do
		local dx = position.X - base.center.X
		local dz = position.Z - base.center.Z
		if dx * dx + dz * dz <= Config.BASE_RADIUS * Config.BASE_RADIUS then
			return true
		end
	end
	return false
end

-- 自分の拠点の中か（持ち帰りの収納判定）。
function BaseService.isInOwnBase(player: Player, position: Vector3): boolean
	local base = BaseService.getBaseOf(player)
	if not base then
		return false
	end
	local dx = position.X - base.center.X
	local dz = position.Z - base.center.Z
	return dx * dx + dz * dz <= (Config.BASE_RADIUS - 4) ^ 2
end

-- 高波に対する安全地帯（拠点の中かコンビニの中）。
function BaseService.isSafe(position: Vector3): boolean
	if insideBase(position) then
		return true
	end
	for _, s in ipairs(shelters) do
		if math.abs(position.X - s.cx) <= s.hx and math.abs(position.Z - s.cz) <= s.hz then
			return true
		end
	end
	return false
end

return BaseService
