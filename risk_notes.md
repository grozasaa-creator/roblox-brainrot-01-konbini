# risk_notes（Konbini Brainrot）

| 失敗パターン | 対策 |
|---|---|
| Studio 無しでは実機の動作確認ができない（Luau は構文のみ検査済み） | luau-compile で全ファイル通過を確認。初回の Studio 再生で出力ウィンドウを見て修正する |
| スクリーンショットを実機で撮れない | 捏造画像で代用しない。本人が Studio で撮影するか、MCP のあるセッションで撮る |
| 公開前にサムネ・アイコンが Roblox の審査を通る必要がある | 本人がダッシュボードで作業。最終の Public ボタンは本人 |
| 状態の置き場が増えて不整合 | 状態は PlayerState に一本化。クライアントは表示のみ |
| 録画中に書いていないファイルは transcripts_witnessed で落ちる | game.rbxl・PLAY.json・screenshots は録画中に保存する |
