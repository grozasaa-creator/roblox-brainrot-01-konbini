# HANDOVER（現在状態のみ）

## できている
- src/（shared 7・server 13・client 6）を実装。全 luau が luau-compile を通過、`rojo build` で game.rbxl（約39KB）を生成。
- main.ts に1行追加済み、.gitignore 作成済み、README・TOUR.json・前提カード・risk_notes を更新。
- main.ts の2回実行でコピー物のハッシュは同一（ただし screenshots が空なので dossier.json は作れず終了コード1）。

## 本人待ち / 未決
- Studio で game.rbxl を開き、File → Publish to Roblox → Create new game（名前・説明にドット入りの URL 風文字列を入れない）。ログイン画面なら「ログイン待ち」。
- 公開後に place_id / universe_id を PLAY.json へ。`node cli/makefun.mjs check --repo <repo> --play-code 0`（0〜3）で play code を取り、Game Settings の説明に貼る。
- Studio で実機プレイして screenshots/ に 3〜4 枚（各 256KiB 以下、1-cover.png が Roblox の最初のサムネと同一）。TOUR.json の名前は 1-cover / 2-catch / 3-base / 4-tide。
- Creator Dashboard でアイコン・サムネ・説明・ジャンル・年齢質問まで進め、最後の Public ボタンは本人。
- 録画の封印（~/.makefun/record-roblox-brainrot-01.pid を kill）と kit の check、提出。

## 抜いた
- Luau の実機動作は未確認（Studio を操作する手段がこのセッションに無い）。型検査は Roblox グローバル未登録のため構文のみ確認。
- スクリーンショット未作成（偽の画像で代用しない）。
