# Injecta secrets P2 do .env local no Supabase remoto (Edge Functions).
# NUNCA imprime valores completos. NUNCA commita .env.
#
# Uso (PowerShell, na raiz AQUANAUTIX):
#   .\tools\verify_p2_secrets.ps1
#   .\tools\configure_p2_secrets.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"
$projectRef = if ($env:SUPABASE_PROJECT_REF) { $env:SUPABASE_PROJECT_REF } else { "ycmvqokcfzxkpinvcyhk" }

if (-not (Test-Path $envFile)) {
    Write-Error ".env não encontrado em $root — coloca todas as chaves na raiz AQUANAUTIX."
}

$defines = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $defines[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
        }
    }
}

$required = @(
    "SUPABASE_ACCESS_TOKEN",
    "REVENUECAT_SECRET_API_KEY",
    "REVENUECAT_WEBHOOK_AUTHORIZATION"
)
foreach ($key in $required) {
    if (-not $defines[$key]) {
        Write-Error "$key em falta no .env — corre .\tools\verify_p2_secrets.ps1"
    }
}

$env:SUPABASE_ACCESS_TOKEN = $defines["SUPABASE_ACCESS_TOKEN"]

$tmp = [System.IO.Path]::GetTempFileName()
try {
    $lines = @(
        "REVENUECAT_SECRET_API_KEY=$($defines['REVENUECAT_SECRET_API_KEY'])",
        "REVENUECAT_WEBHOOK_AUTHORIZATION=$($defines['REVENUECAT_WEBHOOK_AUTHORIZATION'])"
    )
    if ($defines["REVENUECAT_ENTITLEMENT_PRO"]) {
        $lines += "REVENUECAT_ENTITLEMENT_PRO=$($defines['REVENUECAT_ENTITLEMENT_PRO'])"
    }
    if ($defines["REVENUECAT_ENTITLEMENT_ELITE"]) {
        $lines += "REVENUECAT_ENTITLEMENT_ELITE=$($defines['REVENUECAT_ENTITLEMENT_ELITE'])"
    }
    Set-Content -Path $tmp -Value $lines -Encoding UTF8

    Write-Host "A injectar secrets P2 no projecto $projectRef (valores não mostrados)…" -ForegroundColor Cyan
    Push-Location $root
    npx supabase secrets set --env-file $tmp --project-ref $projectRef --yes
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Pop-Location

    Write-Host "`nOK: secrets Edge Functions actualizados." -ForegroundColor Green
    Write-Host @"

Passo manual no RevenueCat (uma vez):
  1. app.revenuecat.com → Integrations → Webhooks
  2. URL: https://$projectRef.supabase.co/functions/v1/revenuecat-webhook
  3. Authorization header = mesmo valor que REVENUECAT_WEBHOOK_AUTHORIZATION no .env
  4. Eventos: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, UNCANCELLATION, BILLING_ISSUE
"@ -ForegroundColor Yellow
}
finally {
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
}
