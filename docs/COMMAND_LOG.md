# Command Log

このファイルは、重要なコマンド実行を累積して記録するためのログです。

方針:

- 実行日時は JST で記録する。
- 生ログをそのまま貼らず、目的・コマンド・結果・補足を簡潔に残す。
- `PROJECT_STATE.md` を更新するタイミングで、このファイルも必要に応じて更新する。
- 認証情報、トークン、秘密情報、不要な巨大ログは記録しない。

## 2026-05-29 01:11:51 +09:00

目的:

- コマンドログ運用を開始する。
- ここまでの重要コマンド履歴を、後から追える形で整理する。

実行:

```powershell
Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
```

結果:

- 現在時刻は `2026-05-29 01:11:51 +09:00`。

補足:

- これ以前のコマンドは、会話ログと `PROJECT_STATE.md` を元にした後追い記録。

## 2026-05-29 01:11:51 +09:00 以前の後追い記録

目的:

- Vite + React の初期プロトタイプを作成し、GitHub に共有する。

主な実行:

```powershell
winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
node -v
npm -v
npm.cmd -v
where.exe node
where.exe npm
& 'C:\Program Files\nodejs\node.exe' '.npm-cache\_npx\1415fee72ff6294b\node_modules\create-vite\index.js' prototypes/001-nadameyo --template react
& 'C:\Program Files\nodejs\npm.cmd' install
git config --global --add safe.directory C:/Users/masat/Documents/codex_test
git config --global user.name "shirai-masatomo"
git config --global user.email "18278416+shirai-masatomo@users.noreply.github.com"
git add .
git commit -m "Add initial Vite React prototype"
git remote add origin https://github.com/shirai-masatomo/whitespace.git
git push -u origin main
git add .gitignore PROJECT_STATE.md
git commit -m "Update project state and local git ignores"
git push
```

結果:

- Node.js LTS `v24.16.0` と npm `11.13.0` を利用可能にした。
- `npm create vite@latest ...` は `Access is denied` で失敗した。
- `create-vite` 本体を正式な Node.js で直接実行し、`prototypes/001-nadameyo` の作成に成功した。
- `npm.cmd install` により依存パッケージをインストールした。
- GitHub リポジトリ `https://github.com/shirai-masatomo/whitespace` に push した。

補足:

- Windows PowerShell では `npm` が `npm.ps1` の Execution Policy で止まるため、`npm.cmd` を使う。
- Codex 内では通常の `node` / `npm` の PATH 解決が Windows PowerShell と異なるため、必要に応じてフルパス指定または権限付き実行を使う。
- `.npm-cache/`、`node_modules/`、`.git-acl-before.txt` は Git 管理対象外。

## 2026-05-29 01:11:51 +09:00 以降

目的:

- コマンドログ運用をリポジトリに追加する。
- `PROJECT_STATE.md` と同じタイミングでコマンドログを更新・コミットする運用にする。

実行:

```powershell
git status --short
git add PROJECT_STATE.md docs/COMMAND_LOG.md
git commit -m "Add command log"
git push
```

結果:

- `docs/COMMAND_LOG.md` を追加。
- `PROJECT_STATE.md` にコマンドログ運用を追記。

補足:

- Git操作はCodex通常実行では `.git/index.lock` の権限問題があるため、権限付き実行を使う。
