-- What a player is hauling. State lives in PlayerState.carrying; this module owns the visual on the
-- character and the walk-speed penalty that goes with it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local CharacterModel = require(Shared.CharacterModel)

local PlayerState = require(script.Parent.PlayerState)

local CarryService = {}

-- set by GameServer: (charId, mutation, position) -> void; puts a dropped character back on the ground
CarryService.onDropped = nil

local CARRY_SCALE = 0.55

local function rootOf(player)
	local ch = player.Character
	return ch and ch:FindFirstChild("HumanoidRootPart"), ch
end

function CarryService.refreshSpeed(player)
	local st = PlayerState.get(player)
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not st or not hum then
		return
	end
	if os.clock() < st.stunUntil then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		return
	end
	hum.UseJumpPower = true
	hum.JumpPower = Config.JumpPower
	hum.WalkSpeed = Economy.walkSpeed(Config.BaseWalkSpeed, st.boots, st.carrying ~= nil, Config.CarrySpeedFactor)
end

local function removeVisual(player)
	local ch = player.Character
	local old = ch and ch:FindFirstChild("Carried")
	if old then
		old:Destroy()
	end
end

-- visual only; callers decide what happens to the state
local function attachVisual(player, charId, mutation)
	local root, ch = rootOf(player)
	if not root then
		return
	end
	removeVisual(player)
	-- feet of the little copy rest just above the head
	local model = CharacterModel.build(charId, mutation, root.CFrame * CFrame.new(0, 3.4, 0), false, CARRY_SCALE)
	model.Name = "Carried"
	model:SetAttribute("Carried", true)
	local mroot = model.PrimaryPart
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = mroot
	weld.Parent = mroot
	model.Parent = ch
end

function CarryService.pick(player, charId, mutation)
	local st = PlayerState.get(player)
	if not st then
		return false
	end
	st.carrying = { charId = charId, mutation = mutation or "None" }
	st.seen[charId] = true
	attachVisual(player, charId, st.carrying.mutation)
	CarryService.refreshSpeed(player)
	PlayerState.push(player)
	return true
end

-- empties the hands without dropping anything (used when placing)
function CarryService.clear(player)
	local st = PlayerState.get(player)
	if not st then
		return
	end
	st.carrying = nil
	removeVisual(player)
	CarryService.refreshSpeed(player)
	PlayerState.push(player)
end

-- puts the carried character on the ground where the player stands
function CarryService.drop(player)
	local st = PlayerState.get(player)
	if not st or not st.carrying then
		return false
	end
	local c = st.carrying
	local root = rootOf(player)
	local pos = root and root.Position or nil
	CarryService.clear(player)
	if pos and CarryService.onDropped then
		CarryService.onDropped(c.charId, c.mutation, Vector3.new(pos.X, 0, pos.Z))
	end
	return true
end

return CarryService
