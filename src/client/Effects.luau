-- 見た目の演出。虹色循環・グリッチの点滅・高波の警告時の赤み・警告帯の表示。ゲームの結果には関わらない。
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local Effects = {}

function Effects.start(hud)
	local warnTint = Instance.new("ColorCorrectionEffect")
	warnTint.Name = "WarnTint"
	warnTint.Parent = Lighting

	local tideRemote = Remotes.get("Tide")
	tideRemote.OnClientEvent:Connect(function(phase: string, seconds: number)
		if phase == "warn" then
			hud.showBanner("NEON TIDE INCOMING!  Get inside a base or a konbini!")
			TweenService:Create(warnTint, TweenInfo.new(1), { TintColor = Color3.fromRGB(255, 190, 190) }):Play()
		elseif phase == "go" then
			hud.showBanner("THE TIDE IS HERE!  Stay inside!")
			TweenService:Create(warnTint, TweenInfo.new(0.5), { TintColor = Color3.fromRGB(190, 255, 250) }):Play()
		else
			hud.showBanner(nil)
			TweenService:Create(warnTint, TweenInfo.new(1.5), { TintColor = Color3.new(1, 1, 1) }):Play()
		end
	end)

	local glitchSeed = 0
	RunService.RenderStepped:Connect(function()
		local hue = (os.clock() * 0.25) % 1
		for _, part in ipairs(CollectionService:GetTagged("Rainbow")) do
			if part:IsA("BasePart") then
				part.Color = Color3.fromHSV(hue, 0.8, 1)
			end
		end
		glitchSeed += 1
		if glitchSeed % 6 == 0 then
			for _, part in ipairs(CollectionService:GetTagged("Glitch")) do
				if part:IsA("BasePart") then
					part.Transparency = math.random() < 0.2 and 0.6 or 0
				end
			end
		end
	end)
end

return Effects
