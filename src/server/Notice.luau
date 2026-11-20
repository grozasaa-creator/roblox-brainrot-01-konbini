-- One-line toasts from server to a single player. kind: "good" | "bad" | "info".

local Notice = {}

local remotes = nil

function Notice.init(r)
	remotes = r
end

function Notice.send(player, text, kind)
	if remotes and player and player.Parent then
		remotes.Notice:FireClient(player, text, kind or "info")
	end
end

return Notice
