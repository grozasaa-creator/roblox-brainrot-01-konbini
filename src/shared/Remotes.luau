-- One folder of RemoteEvents. The server creates it, the client waits for it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER = "KonbiniRemotes"
local NAMES = { "State", "Action", "Notice", "Tide" }

local Remotes = {}

function Remotes.server()
	assert(RunService:IsServer(), "Remotes.server called on the client")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER
		folder.Parent = ReplicatedStorage
	end
	local out = {}
	for _, n in ipairs(NAMES) do
		local ev = folder:FindFirstChild(n)
		if not ev then
			ev = Instance.new("RemoteEvent")
			ev.Name = n
			ev.Parent = folder
		end
		out[n] = ev
	end
	return out
end

function Remotes.client()
	local folder = ReplicatedStorage:WaitForChild(FOLDER)
	local out = {}
	for _, n in ipairs(NAMES) do
		out[n] = folder:WaitForChild(n)
	end
	return out
end

return Remotes
