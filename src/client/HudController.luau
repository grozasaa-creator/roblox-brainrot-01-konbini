-- 画面上の表示。お金・毎秒収益・操作ボタン・お知らせ・高波の警告帯。左上は Roblox のメニューがあるので避ける。
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Economy = require(ReplicatedStorage.Shared.Economy)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local HudController = {}

local NOTICE_COLORS = {
	info = Color3.fromRGB(255, 255, 255),
	good = Color3.fromRGB(120, 255, 150),
	bad = Color3.fromRGB(255, 110, 110),
	warn = Color3.fromRGB(255, 220, 80),
}

local function makeLabel(parent: Instance, name: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	return label
end

local function makeButton(parent: Instance, name: string, order: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.LayoutOrder = order
	button.Size = UDim2.fromOffset(176, 52)
	button.BackgroundColor3 = Color3.fromRGB(30, 26, 52)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 255, 240)
	stroke.Thickness = 2
	stroke.Parent = button
	return button
end

function HudController.create(playerGui: PlayerGui)
	local hud = { state = nil, listeners = {} }
	local actionRemote = Remotes.get("Action")
	local stateRemote = Remotes.get("State")
	local noticeRemote = Remotes.get("Notice")

	local gui = Instance.new("ScreenGui")
	gui.Name = "KonbiniHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui

	local moneyLabel = makeLabel(gui, "Money", UDim2.fromOffset(360, 48), UDim2.new(0.5, -180, 0, 8), 40)
	moneyLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
	local incomeLabel = makeLabel(gui, "Income", UDim2.fromOffset(360, 26), UDim2.new(0.5, -180, 0, 54), 20)
	incomeLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	local carryLabel = makeLabel(gui, "Carry", UDim2.fromOffset(460, 26), UDim2.new(0.5, -230, 0, 82), 18)
	local rebirthLabel = makeLabel(gui, "Rebirth", UDim2.fromOffset(200, 24), UDim2.new(1, -212, 0, 10), 18)
	rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right
	rebirthLabel.TextColor3 = Color3.fromRGB(255, 130, 220)

	local noticeLabel = makeLabel(gui, "Notice", UDim2.fromOffset(620, 34), UDim2.new(0.5, -310, 0, 112), 22)
	noticeLabel.TextTransparency = 1
	noticeLabel.TextStrokeTransparency = 1

	local banner = Instance.new("Frame")
	banner.Name = "TideBanner"
	banner.Size = UDim2.fromOffset(640, 84)
	banner.Position = UDim2.new(0.5, -320, 0, 150)
	banner.BackgroundColor3 = Color3.fromRGB(10, 90, 100)
	banner.BackgroundTransparency = 0.25
	banner.Visible = false
	banner.Parent = gui
	local bannerCorner = Instance.new("UICorner")
	bannerCorner.Parent = banner
	local bannerText = makeLabel(banner, "Text", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 30)
	bannerText.TextColor3 = Color3.fromRGB(150, 255, 245)
	local bannerStroke = Instance.new("UIStroke")
	bannerStroke.Color = Color3.fromRGB(60, 255, 235)
	bannerStroke.Thickness = 3
	bannerStroke.Parent = banner

	local bar = Instance.new("Frame")
	bar.Name = "ButtonBar"
	bar.Size = UDim2.fromOffset(920, 56)
	bar.Position = UDim2.new(0.5, -460, 1, -70)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local tierButton = makeButton(bar, "UnlockTier", 1)
	local bootsButton = makeButton(bar, "Boots", 2)
	local rebirthButton = makeButton(bar, "RebirthButton", 3)
	local codexButton = makeButton(bar, "CodexButton", 4)
	codexButton.Text = "CODEX  [C]"
	tierButton.Activated:Connect(function()
		actionRemote:FireServer("UnlockTier")
	end)
	bootsButton.Activated:Connect(function()
		actionRemote:FireServer("Boots")
	end)
	rebirthButton.Activated:Connect(function()
		actionRemote:FireServer("Rebirth")
	end)
	codexButton.Activated:Connect(function()
		for _, callback in ipairs(hud.listeners) do
			callback("toggleCodex")
		end
	end)

	local function refresh(state)
		hud.state = state
		moneyLabel.Text = "$" .. Economy.formatMoney(state.money)
		incomeLabel.Text = "+$" .. Economy.formatMoney(state.income) .. " / sec"
		rebirthLabel.Text = "REBIRTH " .. state.rebirths .. "  (x" .. Economy.rebirthMultiplier(state.rebirths) .. ")"
		if state.carrying then
			carryLabel.Text = "CARRYING! Run to your base!   [Q] drop"
			carryLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
		else
			carryLabel.Text = state.lockLeft > 0 and ("Base LOCKED  " .. state.lockLeft .. "s") or "Catch brainrots (hold E)"
			carryLabel.TextColor3 = state.lockLeft > 0 and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(220, 220, 255)
		end
		if state.tierCost then
			local nextRarity = Rarity.list[state.tier + 1]
			tierButton.Text = "UNLOCK " .. string.upper(nextRarity.name) .. "\n$" .. Economy.formatMoney(state.tierCost)
		else
			tierButton.Text = "ALL TIERS\nUNLOCKED"
		end
		bootsButton.Text = state.bootsCost and ("DASH BOOTS Lv" .. (state.boots + 1) .. "\n$" .. Economy.formatMoney(state.bootsCost)) or "BOOTS MAX"
		rebirthButton.Text = "REBIRTH\n$" .. Economy.formatMoney(state.rebirthCost)
		rebirthButton.UIStroke.Color = state.money >= state.rebirthCost and Color3.fromRGB(255, 130, 220) or Color3.fromRGB(120, 255, 240)
		for _, callback in ipairs(hud.listeners) do
			callback("state", state)
		end
	end
	stateRemote.OnClientEvent:Connect(refresh)

	local noticeToken = 0
	noticeRemote.OnClientEvent:Connect(function(text: string, kind: string)
		noticeToken += 1
		local token = noticeToken
		noticeLabel.Text = text
		noticeLabel.TextColor3 = NOTICE_COLORS[kind] or NOTICE_COLORS.info
		noticeLabel.TextTransparency = 0
		noticeLabel.TextStrokeTransparency = 0.3
		task.delay(3, function()
			if token == noticeToken then
				TweenService:Create(noticeLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			end
		end)
	end)

	function hud.showBanner(text: string?)
		banner.Visible = text ~= nil
		if text then
			bannerText.Text = text
		end
	end

	function hud.listen(callback)
		table.insert(hud.listeners, callback)
	end

	return hud
end

return HudController
