-- Name tags over wild and placed brainrot: name in rarity colour, rarity + income underneath.
-- Wild ones the player cannot catch yet say so, so the yellow guide never points at a dead end.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)

local UiKit = require(script.Parent.UiKit)
local ClientState = require(script.Parent.ClientState)

local LabelBillboard = {}

local tags = {} -- model -> { sub = TextLabel, rarityIdx = number }

local function attach(model)
	if tags[model] or model:GetAttribute("Carried") then
		return
	end
	local root = model.PrimaryPart or model:WaitForChild("Root", 5)
	if not root then
		return
	end
	local rName = model:GetAttribute("Rarity") or "Common"
	local rIdx = Rarity.indexOf(rName)
	local color = Rarity.get(rIdx).color
	local mut = model:GetAttribute("Mutation")
	local prefix = (mut and mut ~= "None") and (string.upper(mut) .. " ") or ""

	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Adornee = root
	bb.Size = UDim2.fromOffset(190, 56)
	bb.StudsOffsetWorldSpace = Vector3.new(0, (model:GetAttribute("Height") or 4) + 2.2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 140
	bb.Parent = root

	local box = UiKit.frame(bb, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.2 })
	UiKit.corner(box, 0.22)
	UiKit.stroke(box, color, 2)
	UiKit.label(box, prefix .. model.Name, { Size = UDim2.fromScale(1, 0.55), TextColor3 = color, Font = Enum.Font.GothamBlack }, { MaxText = 24, pad = 0.05 })
	local sub = UiKit.label(box, "", { Position = UDim2.fromScale(0, 0.55), Size = UDim2.fromScale(1, 0.42), TextColor3 = UiKit.Colors.Text }, { MaxText = 18, pad = 0.05 })

	tags[model] = { sub = sub, rarityIdx = rIdx, rarityName = rName }
	LabelBillboard.refresh(model)
end

function LabelBillboard.refresh(model)
	local t = tags[model]
	if not t then
		return
	end
	local s = ClientState.snapshot
	local income = Economy.money(model:GetAttribute("Income") or 0)
	local text = string.upper(t.rarityName) .. "  " .. income .. "/s"
	if model:GetAttribute("Wild") and s and t.rarityIdx > s.tier then
		text = "NEEDS " .. string.upper(t.rarityName) .. " TIER"
		t.sub.TextColor3 = UiKit.Colors.Red
	else
		t.sub.TextColor3 = UiKit.Colors.Text
	end
	t.sub.Text = text
end

function LabelBillboard.start()
	local function consider(inst)
		task.spawn(attach, inst)
	end
	for _, m in ipairs(CollectionService:GetTagged("Brainrot")) do
		consider(m)
	end
	CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(consider)
	CollectionService:GetInstanceRemovedSignal("Brainrot"):Connect(function(m)
		tags[m] = nil
	end)
	ClientState.SnapshotChanged:Connect(function()
		for model in pairs(tags) do
			if model.Parent then
				LabelBillboard.refresh(model)
			else
				tags[model] = nil
			end
		end
	end)
end

return LabelBillboard
