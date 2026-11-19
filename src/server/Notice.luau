-- 画面に出す短いお知らせ（警告・成功・失敗）をクライアントへ送る。
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local Notice = {}

local noticeRemote = Remotes.get("Notice")

-- kind: "info" | "good" | "bad" | "warn"
function Notice.send(player: Player, text: string, kind: string?)
	noticeRemote:FireClient(player, text, kind or "info")
end

function Notice.broadcast(text: string, kind: string?)
	noticeRemote:FireAllClients(text, kind or "info")
end

return Notice
