# 宥めよ

5回の言葉で、相手が話せるところまで近づく会話ゲーム。WhiteSpaceの自由に変更できる試作です。

## 起動

このREADMEがあるフォルダで実行します。

```powershell
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1 --port 5174 --strictPort
```

[アプリを開く](http://127.0.0.1:5174/)。ポートが使用中なら失敗するので別ポートを明示してください。Node.js 24.16.0 / npm 11.13.0で確認。必要時はPATHに `C:\Program Files\nodejs` を追加するかnpm.cmdをフルパスで実行します。

PowerShellスクリプトが使える環境では `./start-dev.ps1 -Port 5174` でも起動できます。スクリプト自身のフォルダを使うためworktreeを混同しません。Ctrl+Cで停止します。

## 遊び方

[言語比較ラボ](http://127.0.0.1:5174/#compare) はゲームと独立した実験画面です。レビュー3例＋生成25例を辞書とローカルLLMに渡し、判定・根拠・理由・時間・失敗を比較します。モデルはゲーム標準には使いません。画面切替で入力・状態はリセットされます。

このworktreeでは別のPowerShellで `./start-local-model.ps1` を起動すると取得済みモデルを利用できます。新環境の導入、容量・版・実測条件は [LOCAL_MODEL](../../docs/LOCAL_MODEL.md) を参照。モデルなしでも辞書だけ試せます。CLIによる実測は `npm.cmd run compare:language`（既存の実測JSONを上書きするので別条件では先に出力名を変更）。

信頼0・緊張2から開始し、信頼4で成功、緊張5または発言切れで失敗。謝る・聞く・安心を伝える言葉を試し、相手の反応を読んで次を入力します。

未分類や判断保留は数値を変えず、発言数だけ1消費。同じ文では信頼が増えません。強い言葉の直後に新しい謝罪をすると緊張を1戻せます。終了後に振り返りと再挑戦が表示されます。

## 検証・開発

```powershell
npm.cmd run test
npm.cmd run lint
npm.cmd run build
npm.cmd run review:intents
```

テストは言語評価・ゲーム進行・返答・モデル契約/APIの28件。開発画面の「開発用：判定の内訳」で一致語と判断理由を見られます。本番ビルドではゲームの開発パネルは非表示ですが、独立した比較ラボは利用可能です。モデルAPIはVite dev/previewに付属し、distのみの静的配信には含まれません。

| ファイル | 役割 |
| --- | --- |
| src/App.jsx / App.css / index.css | 入力・画面・見た目 |
| src/lib/intentMatcher.js | 入力・履歴・状態を受け取る言語評価境界 |
| src/lib/gameEngine.js | 反復・歩み寄り・数値更新・終了条件 |
| src/lib/responses.js | 文脈に応じた返答・変化説明・振り返り |
| src/data/intent-dictionary.json | 88採用・43保留・13除外、全候補の理由と出典 |
| test/ | 重要な判定と状態遷移のテスト |
| scripts/generate-intent-review.mjs | 辞書と現行判定からレビュー一覧を生成 |

[アプリの状態](APP_STATE.md) / [詳細仕様](../../SPEC.md) / [画面確認](../../docs/PLAYTEST_2026-09-05.md) / [次の作業](../../TODO.md)
