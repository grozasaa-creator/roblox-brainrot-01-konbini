-- Keyboard shortcuts: Q drops what you carry, C opens the codex. Touch players use the HUD buttons.

local ContextActionService = game:GetService("ContextActionService")

local CarryInput = {}

function CarryInput.start(sendAction, toggleCodex)
	ContextActionService:BindAction("KonbiniDrop", function(_, state)
		if state == Enum.UserInputState.Begin then
			sendAction("Drop")
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Q)

	ContextActionService:BindAction("KonbiniCodex", function(_, state)
		if state == Enum.UserInputState.Begin then
			toggleCodex()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.C)
end

return CarryInput
