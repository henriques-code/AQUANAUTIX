# Instala hooks Git versionados (pre-commit seguranca).
# Uso: .\tools\install_git_hooks.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$hooksDir = Join-Path $root ".git\hooks"
$preCommitHook = Join-Path $hooksDir "pre-commit"
$hookScript = Join-Path $PSScriptRoot "hooks\pre-commit.ps1"

if (-not (Test-Path (Join-Path $root ".git"))) {
    Write-Error "Nao e um repositorio Git: $root"
}

if (-not (Test-Path $hookScript)) {
    Write-Error "Script em falta: $hookScript"
}

New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null

# Wrapper invocavel pelo Git for Windows (sh) e fallback directo
$wrapper = @"
#!/bin/sh
# AQUANAUTIX pre-commit — gerado por tools/install_git_hooks.ps1
ROOT="`$(git rev-parse --show-toplevel)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "`$ROOT/tools/hooks/pre-commit.ps1"
exit `$?
"@

[System.IO.File]::WriteAllText($preCommitHook, $wrapper + "`n")

Write-Host "Hook instalado: $preCommitHook" -ForegroundColor Green
Write-Host "Teste: git commit (bloqueia .env no staging)" -ForegroundColor Cyan
