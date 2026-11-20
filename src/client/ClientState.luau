-- The client's copy of server state plus the current guidance goal. Other modules listen to the events.

local ClientState = {
	snapshot = nil,
	goal = { step = 1, text = "" },
	tide = { active = false, phase = "none", dir = 1, endsAt = 0 },
}

local snapshotChanged = Instance.new("BindableEvent")
local goalChanged = Instance.new("BindableEvent")

ClientState.SnapshotChanged = snapshotChanged.Event
ClientState.GoalChanged = goalChanged.Event

function ClientState.setSnapshot(s)
	ClientState.snapshot = s
	snapshotChanged:Fire(s)
end

function ClientState.setGoal(step, text)
	local g = ClientState.goal
	if g.step ~= step or g.text ~= text then
		ClientState.goal = { step = step, text = text }
		goalChanged:Fire(ClientState.goal)
	end
end

return ClientState
