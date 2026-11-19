-- キャラの頭上ラベル（名前・レア度・変異・$/秒）と、台座のメーター表示。タグを見て自動で付ける。
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(ReplicatedStorage.Shared.Characters)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Economy = require(ReplicatedStorage.Shared.Economy)

local LabelBillboard = {}

local function addText(parent: Instance, name: string, order: number, text: string, color: Color3, scale: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.LayoutOrder = order
	label.Size = UDim2.new(1, 0, scale, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

local function attachCharacterLabel(model: Instance)
	local body = model:FindFirstChild("Body")
	if not body or body:FindFirstChild("BrainrotLabel") then
		return
	end
	local def = Characters.byId[model:GetAttribute("CharId")]
	if not def then
		return
	end
	local rarity = Rarity.byName[def.rarity]
	local mutationId = model:GetAttribute("Mutation")
	local mutation = mutationId ~= "" and Mutations.byId[mutationId] or nil
	local income = def.income * (mutation and mutation.multiplier or 1)

	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(230, 92)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (model:GetAttribute("Height") or 6) * (model:GetScale()) * 0.5 + 3.5, 0)
	gui.MaxDistance = 130
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Parent = body
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = gui

	local nameText = (mutation and (mutation.id .. " ") or "") .. def.name
	addText(gui, "Name", 1, nameText, mutation and mutation.color or Color3.new(1, 1, 1), 0.36)
	addText(gui, "Rarity", 2, string.upper(def.rarity), rarity.name == "Secret" and Color3.fromRGB(255, 255, 255) or rarity.color, 0.28)
	addText(gui, "Income", 3, "$" .. Economy.formatMoney(income) .. " / sec", Color3.fromRGB(120, 255, 150), 0.36)
	if rarity.name == "Mythic" then
		body:AddTag("Rainbow")
	end
end

local function attachPedestalLabel(pedestal: Instance)
	if pedestal:FindFirstChild("MeterLabel") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "MeterLabel"
	gui.Adornee = pedestal
	gui.Size = UDim2.fromOffset(170, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	gui.MaxDistance = 60
	gui.LightInfluence = 0
	gui.Parent = pedestal
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 235, 120)
	label.TextStrokeTransparency = 0
	label.Parent = gui

	local function update()
		local meter = pedestal:GetAttribute("Meter") or 0
		local income = pedestal:GetAttribute("Income") or 0
		if income > 0 then
			label.Text = "$" .. Economy.formatMoney(meter) .. "  (+" .. Economy.formatMoney(income) .. "/s)"
		else
			label.Text = "EMPTY"
			label.TextColor3 = Color3.fromRGB(150, 150, 170)
		end
	end
	pedestal:GetAttributeChangedSignal("Meter"):Connect(update)
	pedestal:GetAttributeChangedSignal("Income"):Connect(update)
	update()
end

function LabelBillboard.start()
	for _, model in ipairs(CollectionService:GetTagged("Brainrot")) do
		attachCharacterLabel(model)
	end
	CollectionService:GetInstanceAddedSignal("Brainrot"):Connect(function(model)
		-- 子の Part が複製される前に呼ばれることがあるので、Body が届くまで待つ。
		task.spawn(function()
			model:WaitForChild("Body", 5)
			attachCharacterLabel(model)
		end)
	end)
	for _, pedestal in ipairs(CollectionService:GetTagged("Pedestal")) do
		attachPedestalLabel(pedestal)
	end
	CollectionService:GetInstanceAddedSignal("Pedestal"):Connect(attachPedestalLabel)
end

return LabelBillboard
