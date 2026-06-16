# AQUANAUTIX - Verificacao de sincronizacao (app + supabase + git)
# Uso: .\tools\sync_check.ps1
# Exit 0 = OK ou avisos; Exit 1 = falha critica (analyze ou secrets staged)

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$fail = $false
Write-Host ""
Write-Host "=== AQUANAUTIX sync_check ===" -ForegroundColor Cyan

# 1. Segredos no staging
Write-Host ""
Write-Host "[1/4] Seguranca (staging area)..." -ForegroundColor Yellow
$staged = git diff --cached --name-only 2>$null
$blocked = @(".env", "local_secrets.ps1", "google-services.json", "key.properties", "credentials.json")
$blockedNamePatterns = @("ghp_", "github_pat_", "Token Git", "token git")
foreach ($f in $staged) {
    foreach ($b in $blocked) {
        if ($f -like "*$b*") {
            Write-Host "  BLOQUEADO: $f parece conter segredos!" -ForegroundColor Red
            $fail = $true
        }
    }
    foreach ($np in $blockedNamePatterns) {
        if ($f -like "*$np*") {
            Write-Host "  BLOQUEADO: $f (nome sensivel: $np)" -ForegroundColor Red
            $fail = $true
        }
    }
}
if (-not $fail) {
    Write-Host "  OK - nenhum ficheiro sensivel staged" -ForegroundColor Green
}

# 2. Flutter analyze
Write-Host ""
Write-Host "[2/4] flutter analyze lib/ ..." -ForegroundColor Yellow
flutter analyze lib/
if ($LASTEXITCODE -ne 0) {
    Write-Host "  FALHA - corrigir antes de commit" -ForegroundColor Red
    $fail = $true
} else {
    Write-Host "  OK" -ForegroundColor Green
}

# 3. Git status
Write-Host ""
Write-Host "[3/4] Git..." -ForegroundColor Yellow
$branch = git rev-parse --abbrev-ref HEAD 2>$null
$ahead = git rev-list --count origin/main..HEAD 2>$null
if ($null -eq $ahead) { $ahead = "?" }
Write-Host "  Branch: $branch | Ahead of origin/main: $ahead commit(s)"
git status -sb

# 4. Supabase migrations (se token no .env)
Write-Host ""
Write-Host "[4/4] Supabase migration list..." -ForegroundColor Yellow
$envFile = Join-Path $root ".env"
$hasToken = $false
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*SUPABASE_ACCESS_TOKEN\s*=\s*\S+') { $hasToken = $true }
    }
}
if ($hasToken) {
    & (Join-Path $PSScriptRoot "supabase_with_env.ps1") migration list
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  AVISO - migration list falhou (token ou link?)" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  SKIP - SUPABASE_ACCESS_TOKEN ausente no .env" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "=== Fim sync_check ===" -ForegroundColor Cyan
if ($fail) { exit 1 }
exit 0
