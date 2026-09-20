# DIVE DIVE — PROJECT STATE

更新: 2026-09-20

## 現在地

**Phase 3 / 海のプレイグラウンド試作 / CHANGES・SELF_CONTINUE**。最新人間コメントは「まだレビューする段階ではない」。人間待ちは完了。深度延長より最初の数分、横・内部・外側の探索を優先し、報告だけで停止しない。

- 海上開始、自然沈降/E急降下/Space浮上、450mの既存経路とシームレス救助を維持。
- 右の浅海に歩ける連続岩礁、ケルプ林、縦穴、二つの口を持つ洞窟。内部の空気溜まりへ泳ぎ、歩いて別出口へ潜れる。屋根/外側/反対口も実操作で到達。
- 左の巨大泡/曲がる潮流/岩アーチは別候補。18案を比較中。板状地形・長い草・格子状水面を棄却/改修。**面白さPASSではない**。
- 洞窟側面の泡上昇流に乗る/横へ離れる/Eで逆らう試作。2秒無入力で8.90m浮上（OFFは9m沈降）。弱い周期も上向きになる流量へ再調整。側面→泡→屋根の藻→上穴→洞内を22.90秒で周回。
- 最新出力: **build/windows-preview/DIVE DIVE.exe**。人間試遊済みbuild/windowsと旧windows-realは保持。[起動](README.md) / [評価入口](REVIEW_PACKET.md) / [自己批評](AI_REVIEW.md)。
- Godot 4.7.2、Windows、日本語、Forward+ / Compatibility、独自生成素材。Steam/保存/450m以深は未実装。

## 確認済み

現在ブランチ `codex/dive-dive-playground` の探索試作。`check -BuildFolder windows-preview` 成功: format/lint/依存整合性、ルール479・シーン430・音57・実衝突689・探索19・新空間129・入水6、既存11実経路、Windows Release build/EXE headless起動。上面メッシュ2688点は補助証拠。

Forward+/GLで桟橋→岩礁歩行→縦穴→洞窟歩行→別出口→125mへ連続入力。屋根/外側/側面穴/逆口は別試走。両方式で配布EXE120フレーム成功。画面外・無音・非捕捉。CI: 最初の探索commit `dec6b4a` は[成功](https://github.com/shirai-masatomo/whitespace/actions/runs/35447154864)。以後の改善差分は再push後に確認する。

理想操縦の洞窟横断37.73秒/横132m、125m合流まで57.67秒。外側の通常/Eはともに約18.3秒で補給へ到達し、途中の最低酸素は31.73/8.33%。同じ途中地点で酸素35%なら、側面の空気洞へ5.65秒で生還、外側継続は8.75秒で酸素切れ。旧比較には縁の足止めと異なる到達精度が混ざっていたため訂正。初見時間/面白さの証明ではない。[実測](review/playground.json)。

## 未解決と次

1. DD-058: 海藻の均等配置/過密を棄却し、群落と補給地点の空きへ。入水30〜60秒の視線の抜けと海らしさは未合格。
2. DD-061/063: 上下の穴と泡が周回で繋がった。非対称な壁/水際へ改善したが、材質と出口後の未知への誘いは弱い。
3. DD-054: 最初の数分の変化。横探索の後、140m以降の岩列を場所/現象へ置き換える候補を試す。

新しい藻5群落も訪問した安全位置へ救助し、操作復帰まで実検証。見上げカメラを変更する案は主人公の体で穴が隠れるため棄却し、既存の距離を保持。新穴の通常/E落下、縁の60/15Hz実衝突、藻5群落の救助を検証。入水の品質全体は未合格。

GitHub同期: `dec6b4a`までpush済み、[下書きPR #2](https://github.com/shirai-masatomo/whitespace/pull/2)とCI成功。`2f31230`以後の追加送信は自動承認レビューが「この内容を指定先へ送る明示許可がない」と拒否。既存公開repo・admin/push権限・main一致を確認済みでも再拒否されたため、ユーザーへ送信許可を質問中。返答前に別経路で送信しない。ローカル実装/検証は実施可能。ゲーム自体をHUMAN_REVIEWへ戻す理由ではない。

見えた全地形を踏破済みとはしない。岩の材質、海藻の形、初見で場所に気付く手掛かり、140m以降の反復が弱い。音色/別GPU/長時間/初見探索は未確認。main `6a07b8b` の9/20版EXTERNAL_AI_REVIEW/HUMAN_DIRECTIONをmerge済み。外部指摘は巨大泡/潮流/穴までの探索試作対象で、今回の周回へのPASSではない。HUMAN_DIRECTION / EXTERNAL_AI_REVIEWを必読。

## 再実行と環境

`./tools/setup.ps1` → `./dev.ps1 check -BuildFolder windows-preview`。新画面は`visual-playground`/`visual-entry`、既存は`visual`/`visual-reef`/`visual-discovery`。`-Renderer gl_compatibility`で比較。Actionsはheadless、画質はローカルGPU。

使用中EXEを上書きしない。GPUは画面外・Dummy音声・非捕捉、自分のプロセスだけ終了。exit 0でもERRORログは失敗。詳細ログはartifacts、過去はGit。今回の全checkは`recursive-final-check.log`、周回の両GPUは`loop-final-*.log`。

実衝突は連続掃引カプセル。足場IDを持たない地形でも接地/歩行できるよう分離。穴へ落ちた試走は縁を回る経路と分け、壁を弱めて解決しない。洞窟の空気判定は箱でなく内部形状、浮力判定は頭と足を区別。水面は洞窟境界に沿う連続メッシュ。これらの失敗原因を再調査しないこと。
