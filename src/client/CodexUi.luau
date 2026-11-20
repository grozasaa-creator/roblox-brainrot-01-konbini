-- Codex: a list of all 15 characters. Found ones show name, rarity and income; unseen ones are "???".
-- Each row is a frame of column labels, so no text can run past its own cell.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Characters = require(Shared.Characters)
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)

local UiKit = require(script.Parent.UiKit)
local ClientState = require(script.Parent.ClientState)

local CodexUi = {}

local C = UiKit.Colors
local panel
local countLabel
local rows = {}

local ROW_H = 46

local function makeRow(parent, def, order)
	local row = UiKit.frame(parent, {
		Size = UDim2.new(1, -8, 0, ROW_H),
		BackgroundColor3 = C.PanelLight,
		LayoutOrder = order,
	})
	UiKit.corner(row, 0.2)
	local swatch = UiKit.frame(row, {
		Position = UDim2.fromScale(0.015, 0.2),
		Size = UDim2.fromScale(0.04, 0.6),
		BackgroundColor3 = C.Dim,
	})
	UiKit.corner(swatch, 0.5)
	local name = UiKit.label(row, "???", { Position = UDim2.fromScale(0.07, 0), Size = UDim2.fromScale(0.4, 1), TextXAlignment = Enum.TextXAlignment.Left }, { MaxText = 22, pad = 0.12 })
	local rar = UiKit.label(row, "", { Position = UDim2.fromScale(0.48, 0), Size = UDim2.fromScale(0.2, 1) }, { MaxText = 18, pad = 0.15 })
	local inc = UiKit.label(row, "", { Position = UDim2.fromScale(0.69, 0), Size = UDim2.fromScale(0.3, 1), TextColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Right }, { MaxText = 18, pad = 0.15 })
	return { swatch = swatch, name = name, rar = rar, inc = inc, def = def }
end

local function refresh(s)
	if not panel then
		return
	end
	local found = 0
	for _, r in ipairs(rows) do
		local seen = s.seen[r.def.id] == true
		local col = Rarity.get(Rarity.indexOf(r.def.rarity)).color
		if seen then
			found += 1
			r.swatch.BackgroundColor3 = col
			r.name.Text = r.def.name
			r.name.TextColor3 = col
			r.rar.Text = string.upper(r.def.rarity)
			r.rar.TextColor3 = col
			r.inc.Text = Economy.money(r.def.income) .. "/s"
		else
			r.swatch.BackgroundColor3 = C.Dim
			r.name.Text = "???"
			r.name.TextColor3 = C.Dim
			r.rar.Text = string.upper(r.def.rarity)
			r.rar.TextColor3 = C.Dim
			r.inc.Text = "?"
		end
	end
	countLabel.Text = "CODEX  " .. found .. "/" .. #Characters.List
end

function CodexUi.toggle()
	if panel then
		panel.Visible = not panel.Visible
	end
end

function CodexUi.start()
	local gui = UiKit.screenGui("KonbiniCodex", 4)
	panel = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.72),
		Visible = false,
	})
	UiKit.limitSize(panel, 300, 260, 720, 560)
	UiKit.corner(panel, 0.04)
	UiKit.stroke(panel, C.Pink, 3)

	countLabel = UiKit.label(panel, "CODEX", { Position = UDim2.fromScale(0.04, 0.02), Size = UDim2.fromScale(0.7, 0.09), TextColor3 = C.Pink, TextXAlignment = Enum.TextXAlignment.Left }, { MaxText = 34, pad = 0.06 })
	local close = UiKit.button(panel, "X", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.97, 0.025),
		Size = UDim2.fromScale(0.09, 0.08),
		BackgroundColor3 = C.Red,
	}, { MaxText = 26 })
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.fromScale(0.03, 0.13)
	scroll.Size = UDim2.fromScale(0.94, 0.84)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = panel
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	for i, def in ipairs(Characters.List) do
		rows[i] = makeRow(scroll, def, i)
	end

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	ClientState.SnapshotChanged:Connect(refresh)
	if ClientState.snapshot then
		refresh(ClientState.snapshot)
	end
end

return CodexUi
