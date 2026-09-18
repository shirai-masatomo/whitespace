$env:Path = "C:\Program Files\nodejs;$env:Path"
Set-Location $PSScriptRoot

& "C:\Program Files\nodejs\npm.cmd" run dev -- --host 127.0.0.1 *> ".vite-dev.stdout.log"
