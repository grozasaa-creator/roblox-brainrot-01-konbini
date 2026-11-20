# HANDOVER: Konbini Brainrot v2 (2026-11-20)

## 現在状態
- 全30 .luau が luau-compile を通過。luau-analyze は Roblox グローバル由来以外の指摘なし。
- rojo で game.rbxl ビルド成功。`MAKEFUN_OUTPUT_DIR=out node main.ts` は終了コード0、dossier.json 生成。
- git commit 済み（push は本人）。

## 未決・未確認
- Studio での実プレイ未確認（コンパイルと静的解析のみ）。パトロール軌道84、ガイド矢印、PromptGate の挙動は要実機。
- TOUR.json の keys/call 形式はキット記述を要約から再現したもの。要確認。
- 抜いた: 実機スクリーンショットの撮り直し（既存4枚を使用）。
