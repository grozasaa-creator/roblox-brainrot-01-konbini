-- キー入力。Q で持っているキャラを手放す、C で図鑑。判定はサーバー側で行う。
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local CarryInput = {}

function CarryInput.start(hud)
	local actionRemote = Remotes.get("Action")
	ContextActionService:BindAction("DropCarried", function(_, inputState)
		if inputState == Enum.UserInputState.Begin and hud.state and hud.state.carrying then
			actionRemote:FireServer("Drop")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q)
	ContextActionService:BindAction("ToggleCodex", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			for _, callback in ipairs(hud.listeners) do
				callback("toggleCodex")
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C)
end

return CarryInput
