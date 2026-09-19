# 言語ジェンガの起動

リポジトリルートから、Node.js環境で実行します。

```powershell
cd projects/language-jenga/app/nadameyo
npm.cmd ci
npm.cmd run dev -- --host 127.0.0.1 --port 5183 --strictPort
```

[ブラウザで開く](http://127.0.0.1:5183/)。他のサーバーが使用中なら空きポートを指定します。停止はCtrl+C。

初期画面は「雨の駅前」。層を選ぶ→抜く/変える→絵・返答・理由を見る→一手戻す、を試してください。3層以上抜いて相合傘を維持したら「この場面を確定」。別の結果で確定しても組み直せます。

旧「宥めよ」は画面上部から切替。言語ジェンガの盤面は切替で保持しますが、ブラウザ再読込では保存しません。LLMや外部APIは不要です。

検証コマンドは npm.cmd test / npm.cmd run lint / npm.cmd run build。依存の更新は今回行っていません。辞書レビュー生成は npm.cmd run review:intents（辞書作業時だけ）。

[規則](../../docs/SPEC.md) / [現在地・確認範囲](../../PROJECT_STATE.md) / [環境メモ](../../docs/COMMAND_LOG.md)
