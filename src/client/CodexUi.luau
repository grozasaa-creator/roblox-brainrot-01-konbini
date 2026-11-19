-- 図鑑パネル。15キャラの発見状況と、見つけた変異（Gold / Neon / Glitch）を表示する。C キーかボタンで開閉。
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(ReplicatedStorage.Shared.Characters)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Mutations = require(ReplicatedStorage.Shared.Mutations)
local Economy = require(ReplicatedStorage.Shared.Economy)

local CodexUi = {}

local function mutationFlags(entry): string
	local found = {}
	for _, mutation in ipairs(Mutations.list) do
		if entry and entry[mutation.id] then
			table.insert(found, mutation.id)
		end
	end
	return #found > 0 and table.concat(found, " / ") or "-"
end

function CodexUi.create(playerGui: PlayerGui, hud)
	local gui = Instance.new("ScreenGui")
	gui.Name = "KonbiniCodex"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(640, 440)
	panel.Position = UDim2.new(0.5, -320, 0.5, -220)
	panel.BackgroundColor3 = Color3.fromRGB(20, 18, 36)
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 130, 220)
	stroke.Thickness = 3
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 44)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 26
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = panel

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 48)
	list.Size = UDim2.new(1, -24, 1, -60)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list

	local rows = {}
	for index, def in ipairs(Characters.list) do
		local row = Instance.new("TextLabel")
		row.LayoutOrder = index
		row.Size = UDim2.new(1, -8, 0, 26)
		row.BackgroundColor3 = Color3.fromRGB(34, 30, 56)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.GothamBold
		row.TextSize = 15
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = Color3.new(1, 1, 1)
		row.Parent = list
		rows[def.id] = row
	end

	local function refresh(state)
		local owned = 0
		for _, def in ipairs(Characters.list) do
			local entry = state.codex[def.id]
			local row = rows[def.id]
			if entry then
				owned += 1
				row.Text = string.format("  %s   [%s]   $%s/s   x%d   Mutations: %s", def.name, def.rarity, Economy.formatMoney(def.income), entry.count, mutationFlags(entry))
				row.TextColor3 = Rarity.byName[def.rarity].color
			else
				row.Text = "  ???   [" .. def.rarity .. "]"
				row.TextColor3 = Color3.fromRGB(110, 110, 130)
			end
		end
		title.Text = "CODEX  " .. owned .. " / " .. #Characters.list
	end

	hud.listen(function(event, state)
		if event == "toggleCodex" then
			gui.Enabled = not gui.Enabled
		elseif event == "state" then
			refresh(state)
		end
	end)
end

return CodexUi
