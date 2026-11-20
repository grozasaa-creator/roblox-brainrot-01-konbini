# risk_notes（Konbini Brainrot v2）

| 失敗パターン | 対策 |
|---|---|
| Studio 無しでは実機動作を確認できない（構文のみ luau-compile で検査） | 全 .luau を luau-compile に通す。サーバー権威・pcall・nil ガードを多めにし、初回の Studio 再生で出力ウィンドウを確認する（未確認） |
| 画面が暗い（v1 実プレイで真っ暗） | ClockTime を夕景に固定し Ambient/OutdoorAmbient/Brightness/ExposureCompensation を強めに設定。地面・台座・拠点床は明るい色にする |
| 何をすればよいか分からない | 次の目的地へ光る矢印と柱・ハイライト・目的帯・手順チップをクライアントで出す（Guide）。静的な看板と道順灯も置く |
| GUI 文字が枠からはみ出す | 全 TextLabel/TextButton を UiKit 経由で作り TextScaled・TextWrapped・UITextSizeConstraint を必ず付け、枠は Scale 指定にする |
| 状態の置き場が増えて不整合 | 状態は PlayerState に一本化。クライアントは snapshot を表示するだけ |
| 循環 require | サービス間の呼び出しは GameServer で配線するコールバック（onCatch など）で行う |
| ゲートの source_matches_place | src/ を rojo build で game.rbxl に焼き、手で Studio 編集して上書きしない |
