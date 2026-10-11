# バイオーム01：通常EXEへの反映

ユーザーの明示指示で、既存の「確認入口/最新開発版.lnk」が起動するEXEを更新しました。ゲームを自動起動していません。実装428e568cad8669aa9e89a910026c3b8bf22e8b27、ソースHEAD e0d3276、素材b0e917a11f205190dde0136165a72c189f39e275。

新EXE SHA256：12F276EE0D84FA5F65BCE90CF51BBFE2FDA8D9CF8596DEE3503E8119C92161B5。
旧EXE SHA256：A10287B62CE93C985891982C3A8B4B2B2CB67BD58722349A8113A8FA22110C1C。

- [前後21組／42PNG](SCREENS.md)、[原本ハッシュ](IMAGE_MANIFEST.json)
- [新EXEの旧セーブ互換21項目、失敗0](delivery/compat/biome-compat.json)
- [終了保存](delivery/lifecycle/close-entry.json)・[別プロセス自動再開](delivery/lifecycle/resume-entry.json)：5項目、失敗0
- [前後の描画監査](after/isolation.json)・[終了再開の監査](delivery/lifecycle/isolation.json)
- [反映記録](delivery/deployment.json)

WinSta0以外の非対話デスクトップ、NonInteractive=true、DesktopMatched=true、タイムアウトなし。GPU描画、無音・30fps・直列、専用APPDATAで確認しました。通常デスクトップへ表示・入力していません。

通常EXEが動いていないことを確認し、旧版を退避して更新。通常セーブ・履歴・起動スクリプト・既存ショートカットは全件ハッシュ一致。セーブ原本や実行EXEはGitHub資料へ混入させていません。

全景、像付近、疎林、岩場、乾いた土地、夜の代表原本で新しい地形が表示されることを確認。21構図の撮影は完了しましたが、全構図の人間による最終評価、追加の実操作、人間の快適さと実GPU FPSは未確認です。固定30fpsの画像取得をFPS合格とは扱いません。

続きの保存は地形だけを追加し、樹木・岩・物資・住人・仕事を再配置しません。新しい自然物分布を見るには新規マップが必要ですが、既存セーブを初期化する必要はありません。新規開始は現在状態を履歴へ保管する既存の確認付き操作を使います。
