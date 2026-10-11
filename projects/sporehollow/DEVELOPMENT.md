# 開発と後片付け

現行フォルダを再利用し、Gitで変更履歴を管理します。通常のEXEと既存の最新版ショートカットは各1つです。旧版はソース履歴から再ビルドします。

```powershell
./dev.ps1 test -Suites biome01
./dev.ps1 build -Suites review02,biome01
./tools/isolated_visual.ps1 -Scenario probe
./dev.ps1 clean
```

buildは候補EXEを非対話デスクトップで起動・終了・再開してから既存EXEへ反映します。起動中なら置換せず止まります。成功・失敗のどちらでも自分の一時出力を片づけ、必要なログ・結果・画像はreview/current/verificationに集約します。Godotツールは1セットを残し、展開済みの配布アーカイブと再生成可能なキャッシュは削除します。

Play.cmd/dev.ps1 playは同じ配布EXEを起動。editorだけは明示操作で現行ソースを開きます。通常セーブと検証データは分離します。

整理は確認済みの対象だけです。保護対象や不明な内容がある一時フォルダ、実行中のプロセス、未保存ソースは自動削除しません。過去コピーの履歴はrefs/archive/retiredへ統合して保全しています。
