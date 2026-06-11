# run_dev.ps1 — corre a app Flutter com os tokens do .env via --dart-define
# Uso: .\tools\run_dev.ps1            (escolhe device automaticamente)
#      .\tools\run_dev.ps1 -d chrome  (forçar device)

param(
    [string]$d = ""
)

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env não encontrado em $root"
    exit 1
}

# Lê o .env: ignora comentários e linhas vazias
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

# Constrói os flags --dart-define para as chaves relevantes
$coreDefines = @(
    "MAPBOX_ACCESS_TOKEN=$($defines['MAPBOX_ACCESS_TOKEN'])",
    "SUPABASE_URL=$($defines['SUPABASE_URL'])",
    "SUPABASE_ANON_KEY=$($defines['SUPABASE_ANON_KEY'])",
    "OPENAI_API_KEY=$($defines['OPENAI_API_KEY'])",
    "REVENUECAT_API_KEY_ANDROID=$($defines['REVENUECAT_API_KEY_ANDROID'])"
)

# Defines opcionais RevenueCat — defaults alinhados com REVENUECAT_SETUP.md
$rcDefaults = @{
    'REVENUECAT_ENTITLEMENT_PRO'       = 'pro'
    'REVENUECAT_ENTITLEMENT_ELITE'     = 'elite'
    'REVENUECAT_PACKAGE_PRO_MONTHLY'   = 'pro_monthly'
    'REVENUECAT_PACKAGE_PRO_ANNUAL'    = 'pro_annual'
    'REVENUECAT_PACKAGE_ELITE_ANNUAL'  = 'elite_annual'
}
foreach ($key in $rcDefaults.Keys) {
    if (-not $defines.ContainsKey($key) -or -not $defines[$key]) {
        $defines[$key] = $rcDefaults[$key]
    }
}

$rcOptional = @(
    'REVENUECAT_API_KEY_IOS',
    'REVENUECAT_ENTITLEMENT_PRO',
    'REVENUECAT_ENTITLEMENT_ELITE',
    'REVENUECAT_PACKAGE_PRO_MONTHLY',
    'REVENUECAT_PACKAGE_PRO_ANNUAL',
    'REVENUECAT_PACKAGE_ELITE_ANNUAL',
    'SUPABASE_RESET_REDIRECT'
)
$optDefines = $rcOptional | ForEach-Object { "$_=$($defines[$_])" }

$dartDefines = ($coreDefines + $optDefines) | ForEach-Object { "--dart-define=$_" }

# Exporta token de downloads da Mapbox para Gradle (Maven auth).
# Aceita ambas as chaves por compatibilidade.
$mapboxDownloadsToken = $null
if ($defines.ContainsKey('MAPBOX_DOWNLOADS_TOKEN') -and $defines['MAPBOX_DOWNLOADS_TOKEN']) {
    $mapboxDownloadsToken = $defines['MAPBOX_DOWNLOADS_TOKEN']
} elseif ($defines.ContainsKey('MAPBOX_DOWNLOAD_TOKEN') -and $defines['MAPBOX_DOWNLOAD_TOKEN']) {
    $mapboxDownloadsToken = $defines['MAPBOX_DOWNLOAD_TOKEN']
}

if ($mapboxDownloadsToken) {
    $env:MAPBOX_DOWNLOADS_TOKEN = $mapboxDownloadsToken
}

# Garante que o ADB (Android SDK platform-tools) está no PATH
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools"
if ((Test-Path $adbPath) -and ($env:PATH -notlike "*platform-tools*")) {
    $env:PATH += ";$adbPath"
}

$deviceFlag = if ($d) { @("-d", $d) } else { @() }

Write-Host "▶  flutter run $($deviceFlag -join ' ') [+ dart-defines]" -ForegroundColor Cyan

Set-Location $root
& flutter run @deviceFlag @dartDefines
