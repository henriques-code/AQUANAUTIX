# Audita chaves P2 no .env — mostra só OK/FALTA (nunca valores completos de secrets).
# Uso: .\tools\verify_p2_secrets.ps1

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

Write-Host "`n=== AQUANAUTIX · verificação P2 (Edge Functions / RC webhook) ===" -ForegroundColor Cyan

if (-not (Test-Path $envFile)) {
    Write-Host "ERRO: .env não encontrado em $root" -ForegroundColor Red
    Write-Host "      Coloca todas as chaves no .env na raiz AQUANAUTIX (gitignored)." -ForegroundColor Yellow
    exit 1
}

$defines = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $defines[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

function Test-Key {
    param([string]$Key, [string]$Kind, [switch]$Secret)
    if ($defines[$Key]) {
        if ($Secret) {
            $preview = $defines[$Key].Substring(0, [Math]::Min(6, $defines[$Key].Length)) + "…"
            Write-Host "  OK  $Key ($Kind) [$preview]" -ForegroundColor Green
        } else {
            Write-Host "  OK  $Key ($Kind)" -ForegroundColor Green
        }
        return $true
    }
    Write-Host "  FALTA  $Key ($Kind)" -ForegroundColor Red
    return $false
}

$ok = $true
Write-Host "`nCLI Supabase:"
$ok = (Test-Key "SUPABASE_ACCESS_TOKEN" "cli" -Secret) -and $ok
Write-Host "`nEdge Functions:"
$ok = (Test-Key "REVENUECAT_SECRET_API_KEY" "edge sk_" -Secret) -and $ok
$ok = (Test-Key "REVENUECAT_WEBHOOK_AUTHORIZATION" "edge webhook header" -Secret) -and $ok
Test-Key "REVENUECAT_ENTITLEMENT_PRO" "opcional" | Out-Null
Test-Key "REVENUECAT_ENTITLEMENT_ELITE" "opcional" | Out-Null
Write-Host "`nApp:"
$ok = (Test-Key "SUPABASE_URL" "app") -and $ok
$ok = (Test-Key "SUPABASE_ANON_KEY" "app" -Secret) -and $ok
$ok = (Test-Key "REVENUECAT_API_KEY_ANDROID" "app" -Secret) -and $ok

Write-Host ""
if ($ok) {
    Write-Host "P2 .env OK. Próximo: .\tools\configure_p2_secrets.ps1" -ForegroundColor Cyan
    exit 0
}
Write-Host "Completa o .env e volta a correr este script." -ForegroundColor Red
exit 1
