-- キャラを持つ・遅くなる・落とす・拠点で収納する。持っている間だけ盗みの対象になる。
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Characters = require(game.ReplicatedStorage.Shared.Characters)
local Economy = require(game.ReplicatedStorage.Shared.Economy)
local CharacterModel = require(game.ReplicatedStorage.Shared.CharacterModel)
local PlayerState = require(script.Parent.PlayerState)
local BaseService = require(script.Parent.BaseService)
local SpawnService = require(script.Parent.SpawnService)
local Notice = require(script.Parent.Notice)

local CarryService = {}

-- StealService が差し込む。持ち歩き中のキャラを奪う処理。
CarryService.onStealFromCarrier = nil

local CARRY_SCALE = 0.55

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function CarryService.applySpeed(player: Player)
	local state = PlayerState.get(player)
	local humanoid = getHumanoid(player)
	if not state or not humanoid then
		return
	end
	local speed = Economy.walkSpeed(state.boots)
	if state.carrying then
		speed *= Config.CARRY_SLOW
	end
	humanoid.WalkSpeed = speed
end

local function removeCarriedModel(player: Player)
	local character = player.Character
	local old = character and character:FindFirstChild("CarriedBrainrot")
	if old then
		old:Destroy()
	end
end

-- 頭の上にモデルを載せる。見た目だけの付属物で、当たり判定なし。
local function attachModel(player: Player, charId: string, mutation: string?)
	local root = getRoot(player)
	if not root then
		return
	end
	removeCarriedModel(player)
	local model = CharacterModel.build(charId, mutation)
	model.Name = "CarriedBrainrot"
	model:ScaleTo(CARRY_SCALE)
	model:SetAttribute("CarrierUserId", player.UserId)
	model:PivotTo(root.CFrame * CFrame.new(0, 3.1, 0))
	local body = model:FindFirstChild("Body")
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			if part ~= body then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = body
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.UIOffset = Vector2.new(0, 60)
	prompt.Parent = body
	prompt.Triggered:Connect(function(thief)
		if CarryService.onStealFromCarrier then
			CarryService.onStealFromCarrier(thief, player)
		end
	end)
	model.Parent = player.Character
end

function CarryService.isCarrying(player: Player): boolean
	local state = PlayerState.get(player)
	return state ~= nil and state.carrying ~= nil
end

-- 野良キャラを捕まえた。持てたら true（呼び出し側が野良モデルを消す）。
function CarryService.pickUp(player: Player, wildModel: Model): boolean
	local state = PlayerState.get(player)
	if not state or state.carrying or not getRoot(player) then
		if state and state.carrying then
			Notice.send(player, "You are already carrying one. Run it to your base!", "bad")
		end
		return false
	end
	local mutation = wildModel:GetAttribute("Mutation")
	if mutation == "" then
		mutation = nil
	end
	CarryService.give(player, wildModel:GetAttribute("CharId"), mutation)
	return true
end

-- 持たせる（捕獲・盗みの共通口）。
function CarryService.give(player: Player, charId: string, mutation: string?)
	local state = PlayerState.get(player)
	state.carrying = { charId = charId, mutation = mutation }
	attachModel(player, charId, mutation)
	CarryService.applySpeed(player)
	local def = Characters.byId[charId]
	Notice.send(player, "Caught " .. def.name .. "! Run to your base!", "good")
	PlayerState.push(player)
end

-- 持っているキャラを手放して野良に戻す（高波・警備ロボ・Qキー）。
function CarryService.drop(player: Player, scatter: boolean?)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return
	end
	local carried = state.carrying
	state.carrying = nil
	removeCarriedModel(player)
	CarryService.applySpeed(player)
	local root = getRoot(player)
	if root and scatter ~= false then
		local offset = Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
		SpawnService.spawnWild(carried.charId, carried.mutation, root.Position + offset)
	end
	PlayerState.push(player)
end

-- 持っているものを消して中身だけ返す（盗まれたとき）。
function CarryService.take(player: Player)
	local state = PlayerState.get(player)
	if not state or not state.carrying then
		return nil
	end
	local carried = state.carrying
	state.carrying = nil
	removeCarriedModel(player)
	CarryService.applySpeed(player)
	PlayerState.push(player)
	return carried
end

local function tryStore(player: Player)
	local state = PlayerState.get(player)
	local root = getRoot(player)
	if not state or not state.carrying or not root then
		return
	end
	if not BaseService.isInOwnBase(player, root.Position) then
		return
	end
	local carried = state.carrying
	local slotIndex = BaseService.placeCharacter(player, carried.charId, carried.mutation)
	if not slotIndex then
		Notice.send(player, "Base is full! Spend money or rebirth.", "warn")
		return
	end
	state.carrying = nil
	removeCarriedModel(player)
	CarryService.applySpeed(player)
	Notice.send(player, "Stored " .. Characters.byId[carried.charId].name .. " on pedestal " .. slotIndex .. "!", "good")
	PlayerState.push(player)
end

function CarryService.init()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		for _, player in ipairs(Players:GetPlayers()) do
			tryStore(player)
		end
	end)
end

-- キャラが死ぬ・消えたら持ち物は街に戻る。
function CarryService.hookCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	local state = PlayerState.get(player)
	if state then
		state.carrying = nil
	end
	CarryService.applySpeed(player)
	humanoid.Died:Connect(function()
		CarryService.drop(player, true)
	end)
end

return CarryService
