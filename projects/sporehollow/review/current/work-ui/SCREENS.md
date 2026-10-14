# CPU確認資料（実ゲーム撮影ではありません）

- [変更前／後の短い比較GIF](motion-before-after.gif)：左c88c1fc2、右今回。採掘・伐採・建築の左右、共通の固定足元・同一時刻。36フレーム、12fps、約3秒。正式4素材は同じ。
- [変更後の段階比較](work-motion-comparison.png)／[変更後GIF](work-motion.gif)。実作業イベントとの接続はwork-motion.jsonで別途検証。
- [1280×800のUI比較](ui-layouts-1280.png)／[1600×1000のUI比較](ui-layouts-1600.png)：実Controlの論理座標を同倍率で並べた下部UI確認図。背景やスキンの完全再現ではない。
- [1280全体座標](architect-1280.png)／[1600全体座標](architect-1600.png)。メインモードとカテゴリの上下関係を確認。

座標の原本はui-layouts.json、モーション描画命令はmotion-draw-commands.json。通常デスクトップでゲームを自動起動せずに出力。再現ツールはtools/render_work_ui.pyとtools/render_work_motion.py。
