param([switch]$Pull)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runtime = Join-Path $repo '.local-llm/ollama/ollama.exe'
if (-not (Test-Path -LiteralPath $runtime)) { throw 'Ollamaの配置方法は docs/LOCAL_MODEL.md を参照してください。' }
$env:OLLAMA_HOST = '127.0.0.1:11435'
$env:OLLAMA_MODELS = Join-Path $repo '.local-llm/models'
$env:OLLAMA_NO_CLOUD = '1'
$env:OLLAMA_NUM_PARALLEL = '1'
$env:OLLAMA_MAX_LOADED_MODELS = '1'
if ($Pull) { & $runtime pull qwen3.5:2b-q4_K_M }
else { & $runtime serve }
exit $LASTEXITCODE
