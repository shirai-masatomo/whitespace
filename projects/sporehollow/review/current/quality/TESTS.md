# 実施した検証

通常セーブと別のテストデータ、GPUは非対話デスクトップ・OpenGL・30fps・Dummy音声。OSのポインタは操作せず、InputEventをゲームへ送信。

最終ビルドでは物流台帳・3日間の観測を再実行。その他の関連試験は各修正時点で実行し、描画・入力の最終確認を22枚の撮影ランで行いました。全回帰を無条件に反復していません。

| 記録 | 成功 / 全チェック |
|---|---|
| [quality-ledger](quality-ledger.json) | 15 / 15 |
| [quality-journey](quality-journey.json) | 16 / 16 |
| [integrated-work](integrated-work.json) | 30 / 30 |
| [integrated-input](integrated-input.json) | 29 / 29 |
| [explicit-storage](explicit-storage.json) | 12 / 12 |
| [work-food-chain](work-food-chain.json) | 34 / 34 |
| [livestock09](livestock09.json) | 23 / 23 |
| [colony-tasks09](colony-tasks09.json) | 26 / 26 |
| [review02](review02.json) | 40 / 40 |
| [visible-boundary](visible-boundary.json) | 51 / 51 |
| [terrain-generation](terrain-generation.json) | 130 / 130 |
| [mountains](mountains.json) | 58 / 58 |
| [ui-survey](ui-survey.json) | 31 / 31 |
| [close-entry](close-entry.json) | 2 / 2 |
| [resume-entry](resume-entry.json) | 3 / 3 |

GPU実行ログ：SCRIPT ERROR / ERROR **0**。描画・選択対象切替、徴兵中の無効状態、9匹の実ホイール、2人目の実クリック、建築完成・交渉はui-survey.jsonへ記録。

40所有→8予約→8携行→現場→消費、物資競合、備蓄通路を別住人が塞ぐ→理由付き待機→解除後配送をquality-ledgerで確認。

通常3日間はseed31の2方針。日次の隔離保存／読込を含む。終了条件と最終状態はquality-journey.json。生存は面白さの評価と分離。

EXE：旧保存fixtureの読込、終了、再起動、保存復帰、ID継続を既存ライフサイクル検証で確認。候補と配布先のSHA256一致を確認後、同じ起動先へ置換。

未検証：人間の実操作・実音・IME、多数人GPU FPS、全商品／全Tooltip／全ズーム、全敵の長期AI。fixture上の2住人は通常募集の実装を意味しません。
