-- Feedback layer: toasts for server notices, the NEON TIDE warning banner with countdown, a cyan tint while
-- the wave is out, and a camera shake when it hits you.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UiKit = require(script.Parent.UiKit)
local ClientState = require(script.Parent.ClientState)

local Effects = {}

local C = UiKit.Colors
local KIND_COLORS = { good = C.Mint, bad = C.Red, info = C.Gold }

local toastBox
local banner, bannerText
local tint
local shakeUntil = 0

local function toast(text, kind)
	local color = KIND_COLORS[kind] or C.Gold
	local row = UiKit.frame(toastBox, {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundTransparency = 0.12,
	})
	UiKit.corner(row, 0.3)
	UiKit.stroke(row, color, 2)
	UiKit.label(row, text, { Size = UDim2.fromScale(1, 1), TextColor3 = color }, { MaxText = 22, pad = 0.14 })
	task.delay(3.2, function()
		local t = TweenService:Create(row, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
		t:Play()
		t.Completed:Wait()
		row:Destroy()
	end)
	-- keep the stack short
	local kids = {}
	for _, k in ipairs(toastBox:GetChildren()) do
		if k:IsA("Frame") then
			table.insert(kids, k)
		end
	end
	if #kids > 4 then
		kids[1]:Destroy()
	end
end

local function setBanner(text, color)
	bannerText.Text = text
	bannerText.TextColor3 = color
	banner.Visible = text ~= ""
end

local function onTide(phase, dir, seconds)
	local tide = ClientState.tide
	if phase == "warn" then
		tide.active = true
		tide.phase = "warn"
		tide.dir = dir
		tide.endsAt = os.clock() + seconds
		tint.TintColor = Color3.fromRGB(255, 220, 235)
	elseif phase == "go" then
		tide.active = true
		tide.phase = "go"
		tide.endsAt = os.clock() + seconds
	elseif phase == "end" then
		tide.active = false
		tide.phase = "none"
		setBanner("", C.Red)
		tint.TintColor = Color3.new(1, 1, 1)
	elseif phase == "hit" then
		shakeUntil = os.clock() + 0.6
	end
end

function Effects.start(remotes)
	local gui = UiKit.screenGui("KonbiniFx", 5)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	toastBox = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromScale(0.4, 0.22),
		BackgroundTransparency = 1,
	})
	UiKit.limitSize(toastBox, 220, 60, 520, 240)
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Padding = UDim.new(0, 4)
	list.Parent = toastBox

	banner = UiKit.frame(gui, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.17),
		Size = UDim2.fromScale(0.5, 0.085),
		BackgroundColor3 = Color3.fromRGB(70, 10, 50),
		BackgroundTransparency = 0.05,
		Visible = false,
	})
	UiKit.limitSize(banner, 260, 40, 760, 72)
	UiKit.corner(banner, 0.26)
	UiKit.stroke(banner, C.Red, 4)
	bannerText = UiKit.label(banner, "", { Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack }, { MaxText = 32, pad = 0.12 })

	tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "TideTint"
	tint.Parent = Lighting

	remotes.Notice.OnClientEvent:Connect(toast)
	remotes.Tide.OnClientEvent:Connect(onTide)

	RunService.RenderStepped:Connect(function()
		local tide = ClientState.tide
		local now = os.clock()
		if tide.phase == "warn" then
			local left = math.max(0, math.ceil(tide.endsAt - now))
			local pulse = 0.5 + 0.5 * math.sin(now * 8)
			local from = tide.dir == 1 and "WEST" or "EAST"
			setBanner("NEON TIDE FROM THE " .. from .. " IN " .. left .. "s - GET INSIDE A BASE!", C.Red:Lerp(Color3.new(1, 1, 1), pulse * 0.6))
		elseif tide.phase == "go" then
			setBanner("NEON TIDE IS HERE - STAY IN A SAFE ZONE!", C.Red)
		end

		local ch = Players.LocalPlayer.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			if now < shakeUntil then
				hum.CameraOffset = Vector3.new((math.random() - 0.5) * 1.6, (math.random() - 0.5) * 1.6, 0)
			elseif hum.CameraOffset ~= Vector3.zero then
				hum.CameraOffset = Vector3.zero
			end
		end
	end)
end

return Effects
