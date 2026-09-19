# DIVE DIVE — PROJECT STATE

更新: 2026-09-19

## 現在地

**Phase 3 / 海のプレイグラウンド試作 / CHANGES・SELF_CONTINUE**。最新人間コメントは「まだレビューする段階ではない」。人間待ちは完了。深度延長より最初の数分、横・内部・外側の探索を優先し、報告だけで停止しない。

- 海上開始、自然沈降/E急降下/Space浮上、450mの既存経路とシームレス救助を維持。
- 右の浅海に歩ける連続岩礁、ケルプ林、縦穴、二つの口を持つ洞窟。内部の空気溜まりへ泳ぎ、歩いて別出口へ潜れる。屋根/外側/反対口も実操作で到達。
- 左の巨大泡/曲がる潮流/岩アーチは別候補。18案を比較中。板状地形・長い草・格子状水面を棄却/改修。**面白さPASSではない**。
- 最新出力: **build/windows-preview/DIVE DIVE.exe**。人間試遊済みbuild/windowsと旧windows-realは保持。[起動](README.md) / [評価入口](REVIEW_PACKET.md) / [自己批評](AI_REVIEW.md)。
- Godot 4.7.2、Windows、日本語、Forward+ / Compatibility、独自生成素材。Steam/保存/450m以深は未実装。

## 確認済み

現在ブランチ `codex/dive-dive-playground` の探索試作。`check -BuildFolder windows-preview` 成功: format/lint/依存整合性、ルール479・シーン430・音57・実衝突689・探索19・新空間57・入水5、既存11実経路、Windows Release build/EXE headless起動。上面メッシュ2688点は補助証拠。

Forward+/GLで桟橋→岩礁歩行→縦穴→洞窟歩行→別出口を連続入力、屋根/外側/逆向きは別試走。Forward+入水と配布EXE120フレームも成功。画面外・無音・非捕捉。人間のプロセスは触っていない。CIはpush後に当該commitで確認する（ローカル成功と区別）。

理想操縦の洞窟横断37.42秒、横方向132m。外側経路23.28秒/酸素10.47%残、急降下多用は21.5秒で酸素切れ。屋根へ12.03秒、逆口→空気溜まり8.33秒。初見時間・面白さの証明ではない。[実測](review/playground.json)。

## 未解決と次

1. DD-058: 上向き時の白く広すぎる太陽光、主人公のフレーミングを改善。入水の印象はまだ未合格。
2. DD-060: 新しい藻庭の接触も救助地点へ反映。現在は即補給のみで、旧足場の藻だけが帰還地点を更新する。
3. DD-061: 洞窟の入口/奥行き/輪郭を自然写真に照らして改善。屋根を歩くだけで終わらない発見を比較する。

見えた全地形を踏破済みとはしない。洞窟の形、岩の材質、海藻の規則性、140m以降の反復が弱い。音色/別GPU/長時間/初見探索は未確認。外部AIレビューは旧450m対象で、新試作へのPASSではない。HUMAN_DIRECTION / EXTERNAL_AI_REVIEWを必読。

## 再実行と環境

`./tools/setup.ps1` → `./dev.ps1 check -BuildFolder windows-preview`。新画面は`visual-playground`/`visual-entry`、既存は`visual`/`visual-reef`/`visual-discovery`。`-Renderer gl_compatibility`で比較。Actionsはheadless、画質はローカルGPU。

使用中EXEを上書きしない。GPUは画面外・Dummy音声・非捕捉、自分のプロセスだけ終了。exit 0でもERRORログは失敗。詳細ログはartifacts、過去はGit。

実衝突は連続掃引カプセル。足場IDを持たない地形でも接地/歩行できるよう分離。穴へ落ちた試走は縁を回る経路と分け、壁を弱めて解決しない。洞窟の空気判定は箱でなく内部形状、浮力判定は頭と足を区別。水面は洞窟境界に沿う連続メッシュ。これらの失敗原因を再調査しないこと。
