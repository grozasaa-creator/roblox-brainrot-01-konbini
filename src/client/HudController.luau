-- The always-on HUD: objective banner, four-step tracker, wallet, carry panel and the upgrade buttons.
-- Everything is built through UiKit so text can never spill out of its frame.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Economy)
local Rarity = require(Shared.Rarity)
local Characters = require(Shared.Characters)
local Config = require(Shared.Config)

local UiKit = require(script.Parent.UiKit)
local ClientState = require(script.Parent.ClientState)

local C = UiKit.Colors

local HudController = {}

local STEPS = {
	{ "1", "CATCH", Color3.fromRGB(255, 226, 90) },
	{ "2", "RUN HOME", Color3.fromRGB(110, 255, 200) },
	{ "3", "COLLECT $", Color3.fromRGB(255, 190, 80) },
	{ "4", "UPGRADE", Color3.fromRGB(255, 120, 225) },
}

local ui = {}
local sendAction = nil
local openCodex = nil

local function twoLineButton(parent, x, title, onClick)
	local b = UiKit.button(parent, "", {
		Position = UDim2.fromScale(x, 0),
		Size = UDim2.fromScale(0.235, 1),
		BackgroundColor3 = C.PanelLight,
	})
	b.Text = ""
	local top = UiKit.label(b, title, { Position = UDim2.fromScale(0, 0.02), Size = UDim2.fromScale(1, 0.5), Font = Enum.Font.GothamBlack }, { MaxText = 24, pad = 0.06 })
	local bottom = UiKit.label(b, "", { Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.46), TextColor3 = C.Gold }, { MaxText = 20, pad = 0.06 })
	local stroke = UiKit.stroke(b, C.Dim, 2)
	b.Activated:Connect(onClick)
	return { button = b, top = top, bottom = bottom, stroke = stroke }
end

local function buildTop(gui)
	local banner = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.012),
		Size = UDim2.fromScale(0.44, 0.075),
		BackgroundColor3 = C.Panel,
		BackgroundTransparency = 0.1,
	})
	UiKit.limitSize(banner, 240, 38, 700, 64)
	UiKit.corner(banner, 0.28)
	UiKit.stroke(banner, C.Gold, 3)
	ui.objective = UiKit.label(banner, "Catch a brainrot", { Size = UDim2.fromScale(1, 1), TextColor3 = C.Gold, Font = Enum.Font.GothamBlack }, { MaxText = 30, pad = 0.12 })

	local row = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.095),
		Size = UDim2.fromScale(0.44, 0.058),
		BackgroundTransparency = 1,
	})
	UiKit.limitSize(row, 240, 28, 700, 46)
	ui.chips = {}
	for i, s in ipairs(STEPS) do
		local chip = UiKit.frame(row, {
			Position = UDim2.fromScale((i - 1) * 0.25, 0),
			Size = UDim2.fromScale(0.235, 1),
			BackgroundColor3 = C.Panel,
			BackgroundTransparency = 0.25,
		})
		UiKit.corner(chip, 0.3)
		local stroke = UiKit.stroke(chip, C.Dim, 2)
		local label = UiKit.label(chip, s[1] .. " " .. s[2], { Size = UDim2.fromScale(1, 1), TextColor3 = C.Dim }, { MaxText = 20, pad = 0.1 })
		ui.chips[i] = { frame = chip, stroke = stroke, label = label, color = s[3] }
	end
end

local function buildWallet(gui)
	local panel = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.988, 0.012),
		Size = UDim2.fromScale(0.2, 0.15),
		BackgroundTransparency = 0.1,
	})
	UiKit.limitSize(panel, 150, 84, 280, 130)
	UiKit.corner(panel, 0.16)
	UiKit.stroke(panel, C.Mint, 2)
	ui.money = UiKit.label(panel, "$0", { Size = UDim2.fromScale(1, 0.52), TextColor3 = C.Mint, Font = Enum.Font.GothamBlack }, { MaxText = 38, pad = 0.05 })
	ui.rate = UiKit.label(panel, "+$0/s", { Position = UDim2.fromScale(0, 0.52), Size = UDim2.fromScale(1, 0.24), TextColor3 = C.Gold }, { MaxText = 20, pad = 0.05 })
	ui.rebirth = UiKit.label(panel, "REBIRTH 0", { Position = UDim2.fromScale(0, 0.76), Size = UDim2.fromScale(1, 0.22), TextColor3 = C.Pink }, { MaxText = 16, pad = 0.05 })

	local codex = UiKit.button(gui, "CODEX [C]", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.988, 0.175),
		Size = UDim2.fromScale(0.1, 0.05),
		BackgroundColor3 = C.PanelLight,
	}, { MaxText = 20 })
	UiKit.limitSize(codex, 92, 28, 150, 42)
	codex.Activated:Connect(function()
		if openCodex then
			openCodex()
		end
	end)
end

local function buildCarry(gui)
	local panel = UiKit.frame(gui, {
		Position = UDim2.fromScale(0.014, 0.16),
		Size = UDim2.fromScale(0.18, 0.12),
		BackgroundTransparency = 0.1,
		Visible = false,
	})
	UiKit.limitSize(panel, 140, 66, 250, 100)
	UiKit.corner(panel, 0.16)
	ui.carryStroke = UiKit.stroke(panel, C.Gold, 3)
	UiKit.label(panel, "CARRYING", { Size = UDim2.fromScale(1, 0.22), TextColor3 = C.Dim }, { MaxText = 14, pad = 0.05 })
	ui.carryName = UiKit.label(panel, "", { Position = UDim2.fromScale(0, 0.22), Size = UDim2.fromScale(1, 0.38), Font = Enum.Font.GothamBlack }, { MaxText = 26, pad = 0.04 })
	local drop = UiKit.button(panel, "DROP [Q]", {
		Position = UDim2.fromScale(0.1, 0.64),
		Size = UDim2.fromScale(0.8, 0.31),
		BackgroundColor3 = C.Red,
	}, { MaxText = 18, pad = 0.1 })
	drop.Activated:Connect(function()
		sendAction("Drop")
	end)
	ui.carryPanel = panel
end

local function buildButtons(gui)
	local row = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.985),
		Size = UDim2.fromScale(0.56, 0.105),
		BackgroundTransparency = 1,
	})
	UiKit.limitSize(row, 320, 52, 780, 78)
	ui.tierBtn = twoLineButton(row, 0, "TIER", function() sendAction("BuyTier") end)
	ui.bootsBtn = twoLineButton(row, 0.255, "BOOTS", function() sendAction("BuyBoots") end)
	ui.rebirthBtn = twoLineButton(row, 0.51, "REBIRTH", function() sendAction("Rebirth") end)
	ui.lockBtn = twoLineButton(row, 0.765, "LOCK BASE", function() sendAction("Lock") end)
end

local function setChip(i, active)
	local chip = ui.chips[i]
	if active then
		chip.frame.BackgroundTransparency = 0
		chip.frame.BackgroundColor3 = chip.color
		chip.stroke.Color = Color3.new(1, 1, 1)
		chip.label.TextColor3 = Color3.fromRGB(30, 25, 60)
	else
		chip.frame.BackgroundTransparency = 0.25
		chip.frame.BackgroundColor3 = C.Panel
		chip.stroke.Color = C.Dim
		chip.label.TextColor3 = C.Dim
	end
end

local function refreshGoal(goal)
	ui.objective.Text = goal.text
	for i = 1, #STEPS do
		setChip(i, i == goal.step)
	end
end

local function refreshState(s)
	ui.money.Text = Economy.money(s.money)
	ui.rate.Text = "+" .. Economy.money(s.income) .. "/s"
	ui.rebirth.Text = "REBIRTH " .. s.rebirths .. "  |  " .. s.tierName:upper()

	ui.carryPanel.Visible = s.carrying ~= nil
	if s.carrying then
		local def = Characters.get(s.carrying.charId)
		local mut = s.carrying.mutation ~= "None" and (s.carrying.mutation:upper() .. " ") or ""
		ui.carryName.Text = mut .. def.name
		local col = Rarity.get(Rarity.indexOf(def.rarity)).color
		ui.carryName.TextColor3 = col
		ui.carryStroke.Color = col
	end

	if s.nextTierName then
		ui.tierBtn.top.Text = "UNLOCK " .. s.nextTierName:upper()
		ui.tierBtn.bottom.Text = Economy.money(s.nextTierCost)
	else
		ui.tierBtn.top.Text = "ALL TIERS"
		ui.tierBtn.bottom.Text = "UNLOCKED"
	end
	if s.bootsCost then
		ui.bootsBtn.top.Text = "BOOTS " .. s.boots .. "/" .. Economy.BootsMax
		ui.bootsBtn.bottom.Text = Economy.money(s.bootsCost)
	else
		ui.bootsBtn.top.Text = "BOOTS MAX"
		ui.bootsBtn.bottom.Text = "FAST!"
	end
	ui.rebirthBtn.top.Text = "REBIRTH"
	ui.rebirthBtn.bottom.Text = Economy.money(s.rebirthCost)
	if s.lockLeft > 0 then
		ui.lockBtn.top.Text = "LOCKED"
		ui.lockBtn.bottom.Text = math.ceil(s.lockLeft) .. "s left"
	else
		ui.lockBtn.top.Text = "LOCK BASE"
		ui.lockBtn.bottom.Text = Economy.money(Config.LockCost) .. " / " .. Config.LockSeconds .. "s"
	end

	ui.afford = {
		tier = s.nextTierCost ~= nil and s.money >= s.nextTierCost,
		boots = s.bootsCost ~= nil and s.money >= s.bootsCost,
		rebirth = s.money >= s.rebirthCost,
	}
end

function HudController.start(actionFn, codexFn)
	sendAction = actionFn
	openCodex = codexFn
	local gui = UiKit.screenGui("KonbiniHud", 2)
	buildTop(gui)
	buildWallet(gui)
	buildCarry(gui)
	buildButtons(gui)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	refreshGoal(ClientState.goal)
	ClientState.GoalChanged:Connect(refreshGoal)
	ClientState.SnapshotChanged:Connect(refreshState)
	if ClientState.snapshot then
		refreshState(ClientState.snapshot)
	end

	-- affordable upgrade buttons pulse so the eye lands on them
	RunService.Heartbeat:Connect(function()
		local a = ui.afford
		if not a then
			return
		end
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 6)
		local function glow(btn, on)
			if on then
				btn.stroke.Color = C.Pink:Lerp(Color3.new(1, 1, 1), pulse)
				btn.stroke.Thickness = 3 + pulse * 3
				btn.button.BackgroundColor3 = C.PanelLight:Lerp(C.Pink, 0.35 * pulse)
			else
				btn.stroke.Color = C.Dim
				btn.stroke.Thickness = 2
				btn.button.BackgroundColor3 = C.PanelLight
			end
		end
		glow(ui.tierBtn, a.tier)
		glow(ui.bootsBtn, a.boots)
		glow(ui.rebirthBtn, a.rebirth)
	end)
	return gui
end

return HudController
