# verify_revenuecat.ps1 — valida .env + estado mínimo para P0 RevenueCat
# Uso: .\tools\verify_revenuecat.ps1

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

Write-Host "`n=== AQUANAUTIX · RevenueCat P0 ===" -ForegroundColor Cyan

if (-not (Test-Path $envFile)) {
    Write-Host "ERRO: .env não encontrado em $root" -ForegroundColor Red
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

$required = @(
    "REVENUECAT_API_KEY_ANDROID",
    "REVENUECAT_ENTITLEMENT_PRO",
    "REVENUECAT_ENTITLEMENT_ELITE",
    "REVENUECAT_PACKAGE_PRO_MONTHLY",
    "REVENUECAT_PACKAGE_PRO_ANNUAL",
    "REVENUECAT_PACKAGE_ELITE_ANNUAL"
)

$ok = $true
foreach ($key in $required) {
    $val = $defines[$key]
    if ($val) {
        $preview = if ($key -like "*KEY*") { $val.Substring(0, [Math]::Min(8, $val.Length)) + "…" } else { $val }
        Write-Host "  OK  $key = $preview" -ForegroundColor Green
    } else {
        Write-Host "  FALTA  $key" -ForegroundColor Red
        $ok = $false
    }
}

Write-Host "`nDashboard (manual):" -ForegroundColor Yellow
Write-Host "  1. Play Console → aquanautix_pro_monthly / pro_annual / elite_annual"
Write-Host "  2. RevenueCat → entitlements pro + elite"
Write-Host "  3. Offering default → packages pro_monthly, pro_annual, elite_annual"
Write-Host "  4. Teste: .\tools\run_dev.ps1 -d <device> → Paywall → Restaurar compras"
Write-Host ""

if (-not $ok) { exit 1 }
Write-Host "Variáveis locais OK. Falta configurar Play Console + RC se offerings vazias." -ForegroundColor Cyan
