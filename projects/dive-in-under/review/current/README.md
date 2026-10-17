# Dive In Under — 確認入口

**0.4.3 / 既存UI改善＋やや斜めの構図＋残敵4候補。基準5点は採用済み、新規4点は未採用。工程1全体は未完了。**

PCの同じ `確認入口.lnk` → [Play.cmd](Play.cmd) または [画像付き比較ページ](index.html)。[Windows ZIP](../../build/DiveInUnder-foundation-windows-x64.zip) / [現在のEXE](../../build/releases/04778428be0e0d7c74b23240707cde6403f04704-9fd9b00a/DiveInUnder.exe) / [操作・保存手順](../../tools/PLAY.txt) / [環境](../../docs/DEVELOPMENT.md) / [SHA](build-manifest.json) / [安全切替記録](local-release.json)。EXEとPCKを同じ場所へ展開します。

実行ソース `04778428be0e0d7c74b23240707cde6403f04704`、Godot `4.7.2.stable.official.ed1daf0bf`。旧EXE/PCKと使用中プロセスを保持し、新しい検証済みreleaseへの参照だけ更新しました。通常デスクトップへの自動起動は行っていません。

## 今回の小単位

1. **0.4.2 UI改善**：控えめな羊皮紙繊維・真鍮枠・見出し帯・装備11行/既存能力効果。自己レビューで無効ボタン幅と文字/枠の余白を修正し再検証。[町の前後](index.html#town) / [0.4.2証拠](README-0.4.2.md)。5素材の採用表示も更新済み。
2. **0.4.3 構図**：最新指示「参考のようにやや斜め視点」を反映。既存背景を1.04倍で静的クロップ、敵を左奥、主人公を右手前へ。612×270の絵領域で足元は敵(171,208)、主人公(416,236)。画面構図だけの決定で、隊列/前後衛/配下のルールは未実装・未決定です。
3. **残敵4候補**：納品のSHAと9原稿すべてを照合。アルファ16以上の本体境界＋4px余白をAtlas表示範囲にし、微小アルファで本体が縮むのを防止。原画は無変更。コウモリは18px浮く静止配置案。採用はまだ宣言しません。

## 実EXEと素材の比較

| 内容 | 実画面 |
| --- | --- |
| 新規候補 | [E01 地底ネズミ](51-enemy-rat.png) / [E02 粘菌スライム](52-enemy-slime.png) / [E03 鉄羽コウモリ](53-enemy-bat.png) / [E05 岩甲虫](54-enemy-beetle.png) |
| 斜め配置 | [E04](55-oblique-goblin.png) / [B10](56-oblique-boss.png) / [変更前0.4.2](45-ui-battle.png) |
| 他画面 | [タイトル](57-oblique-title.png) / [探索](58-oblique-exploration.png) / [町](44-ui-town.png) / [結果](49-ui-result.png) |

町・結果の44/49画像は同じUIの0.4.2収録です。[採用5点と未採用4点の一覧](visual-candidates.md) / [画像制作への共通引継ぎ](../../docs/IMAGE_PRODUCTION_HANDOFF.md) / [今回画面のSHAと監査](oblique-evidence.json)。

## 回帰と配布の証拠

- [142](oblique-tests.log)＋[180](oblique-loop-tests.log)＋[44](oblique-campaign-tests.log)チェック、ヘッドレスUI、Windowsビルド成功。[隔離290操作](oblique-campaign-isolated-campaign-complete.json) / [ヘッドレス290操作](oblique-campaign-headless-campaign-complete.json) / [別EXE保存再開](oblique-campaign-isolated-campaign-final.json)。
- クリア/保存SHAは従来と一致。通常13探索・死亡1・帰還11、初回死亡は別で1回。6種すべてで全身が領域内、原画9枚SHA一致を確認。[隔離監査](oblique-campaign-isolated-isolation-complete.json) / [GPUログ](oblique-campaign-isolated-complete.log)。
- コア・データ・保存・探索方針の差分なし。新規4画像以外のPNGは不変。1000seedのローカル再計算は省略し、今回CIの厳密比較を別記録します。[従来1000seed全文JSON.gz](visual-campaign-repeat.json.gz) / [日本語要約](visual-campaign-repeat.txt)。
- UI単位0.4.2の[PR CIは成功](https://github.com/shirai-masatomo/whitespace/actions/runs/39032622680)、head7bc5f34、checkout0cc6b1e。[CI ZIP](https://github.com/shirai-masatomo/whitespace/actions/runs/39032622680/artifacts/12100624678) / [ログ](https://github.com/shirai-masatomo/whitespace/actions/runs/39032622680/artifacts/12101301288) / [記録](ci-ui-refinement.json)。並行pushは後続更新によりキャンセル。0.4.3とは分離します。

[Draft PR #5](https://github.com/shirai-masatomo/whitespace/pull/5) / [最新CI Checks](https://github.com/shirai-masatomo/whitespace/pull/5/checks)。

## 残項目

4候補と斜め構図の節目レビュー。ネズミは横向き寄り、スライム/甲虫は上面が見え、コウモリは浮き量を含めて判断します。現在は2D素材の配置で奥行きを表現しており、原画のカメラ角度は変えていません。より明確な斜め俯瞰が必要なら、広い床面と奥行き方向を持つ背景、双方の3/4向き静止画が追加仕様候補です。まず現在の実画面を比較します。

PXの装飾・装備アイコン配置との一致、別解像度、OS物理入力、長時間試遊は未達/未検証。完全な同時セーブ書込み排他は未対応。工程1全体は未完了。仲間・隊列ルール・全スキル・耐久・工程2・モーションは追加していません。
