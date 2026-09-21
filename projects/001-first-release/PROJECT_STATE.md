# DIVE DIVE — PROJECT STATE

更新: 2026-09-21

**Phase 3 / L1現実海層〜L2生物層導入の試作 / CHANGES / 定期自律開発PAUSED**。

## 現在遊べる範囲

現実装は設計上の深度目安を圧縮して試作中。海上→32mの岩盤・段丘→80〜110mの浅い海底と谷→160mから岸壁→約450mの砂の海底→一つの岩の隙間→曲がる暗い狭路→約585mで巨大空間へ→タコとの遭遇→約680mの水球まで、同じシーン内で繋がる。

意味上は **L1-P0〜L1-P4 → L1-G → L2-P0 → L2-P1 / L2-P2遭遇試作**。深度値を機械的に1000m/3000mへ引き延ばさず、場所の質を先に上げる。L2全体、ボス戦、L3以降は作っていない。

水球は通過可能で触れると即補給。自然沈降5m/s、E15m/s・酸素2.5倍、Space6m/s、水平7m/s。酸素0の救助は訪問済みの浅い安全地点へ戻る。水球帰還後も泳ぎ続けられ、見えない足場は作らない。

出力: `build/windows-agent/DIVE DIVE.exe` / `build/DIVE-DIVE-windows.zip`。[起動方法](README.md) / [代表3画面](REVIEW_PACKET.md)。

## 最新実装と検証

最新の実装/content commitは `00612b2`。その後のcommitは方針・外部レビュー・TASKSのhandoff同期。

丸い穴の案は排水口に見えたため、細長い入口と両肩の岩盤、回り込む接近へ修正。狭路全体を照らす水球案は照射範囲を縮小。真っ黒だったタコには接近に伴う局所照明を調整。形状は自作の仮モデル。

海面から最後まで実プレイヤー入力で199.5秒、途中位置変更/救助/ロードなし。新区間35確認。節目checkは rules 567、scene 457、surface 2688、actual player collision 689 failures=0、既存11経路、Windows export/配布EXE headlessを通過。GitHub Actions run #222 / `00612b2` は success。

## 未解決・次

完成品質・面白さの合格ではない。

1. **DD-078 / P0**: L1-P4→L1-G→L2-P0。砂地の広い生成面、入口の読み、閉じた管状狭路を、噛み合う巨大岩体・不均一な幅/高さ・段階的な圧迫へ作り直す。
2. **DD-067/068/065/070 / P0**: L1の大面・板状岩盤・160m岸壁・岩階段/段丘・プレイアブル密度を通常画面の場所品質で改善。後半追加で先送りしない。
3. **DD-080 / P0**: 新スクショ方針に従い `review/` を再監査。要求フェーズの2〜4枚と意図的な前後比較以外の古い確認画像を参照確認後に整理する。
4. **DD-079 / P1**: タコの球体胴/均一放射腕の仮モデル感を減らし、影→腕→本体の段階認識を改善。ボス戦へ広げない。

## 同期・運用

正本は `origin/main` の HUMAN_DIRECTION / EXTERNAL_AI_REVIEW。

- main `fbeeba6`: HUMAN_DIRECTIONをL/P/G分類、少数ルート→収束、L1-G隙間、L2狭窄→解放、高速試作、スクショ整理へ更新。
- main `26349f7`: AUTONOMYを高速試作/正本handoff/PC非干渉方針へ同期。
- main `874523b`: EXTERNAL_AI_REVIEWを `reviewed_through: 00612b2` へ更新。判定 CHANGES / SELF_CONTINUE。
- active branchは同じHUMAN_DIRECTION / EXTERNAL_AI_REVIEWを取り込み、TASKSへDD-078/079/080および既存L1品質P0を反映済み。

[下書きPR #2](https://github.com/shirai-masatomo/whitespace/pull/2)、branch `codex/dive-dive-playground`。30分の常設再開は**PAUSEDのまま**。通常は軽い変更箇所確認、重い検証は節目だけ。GPUは画面外・無音・非捕捉、人間のプロセスへ干渉しない。
