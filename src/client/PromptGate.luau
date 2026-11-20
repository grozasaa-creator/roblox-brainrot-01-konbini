-- The server creates every ProximityPrompt switched as it likes; this client-side pass opens only the
-- ones that make sense for this player right now (place / collect / steal on pedestals, catch on wild).
-- The server still validates every trigger, so this is purely about showing the right thing.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarity = require(Shared.Rarity)

local ClientState = require(script.Parent.ClientState)

local PromptGate = {}

local me = Players.LocalPlayer

local function setEnabled(prompt, on)
	if prompt and prompt.Enabled ~= on then
		prompt.Enabled = on
	end
end

local function gatePedestal(ped, s)
	local anchor = ped:FindFirstChild("PromptAnchor")
	if not anchor then
		return
	end
	local owner = ped:GetAttribute("OwnerUserId") or 0
	local filled = ped:GetAttribute("Filled") == true
	local mine = owner == me.UserId
	local carrying = s.carrying ~= nil
	local stunned = s.stunLeft > 0

	setEnabled(anchor:FindFirstChild("Place"), mine and carrying and not filled and not stunned)
	setEnabled(anchor:FindFirstChild("Collect"), mine and filled and (ped:GetAttribute("Meter") or 0) >= 1)
	setEnabled(anchor:FindFirstChild("Steal"), owner ~= 0 and not mine and filled and not carrying and not stunned)
end

local function gateWild(model, s)
	local prompt = model:FindFirstChild("Catch", true)
	if not prompt then
		return
	end
	local idx = Rarity.indexOf(model:GetAttribute("Rarity") or "Common")
	setEnabled(prompt, s.carrying == nil and idx <= s.tier and s.stunLeft <= 0)
end

function PromptGate.start()
	task.spawn(function()
		while true do
			local s = ClientState.snapshot
			if s then
				for _, ped in ipairs(CollectionService:GetTagged("Pedestal")) do
					gatePedestal(ped, s)
				end
				for _, m in ipairs(CollectionService:GetTagged("Brainrot")) do
					if m:GetAttribute("Wild") then
						gateWild(m, s)
					end
				end
			end
			task.wait(0.15)
		end
	end)
end

return PromptGate
