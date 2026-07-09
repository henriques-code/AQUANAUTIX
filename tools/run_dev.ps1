# run_dev.ps1 - Flutter com tokens do .env via --dart-define
# Uso:
#   .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
#   .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D -Miui

param(
    [string]$d = "",
    [switch]$Miui,
    [switch]$SkipBuild
)

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env nao encontrado em $root"
    exit 1
}

$jbr = "C:\Program Files\Android\Android Studio\jbr"
if (Test-Path $jbr) {
    $env:JAVA_HOME = $jbr
    $env:PATH = "$jbr\bin;" + $env:PATH
}

function Ensure-AdbPath {
    $adbPath = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools"
    if (-not (Test-Path $adbPath)) {
        Write-Warning "ADB nao encontrado em $adbPath"
        return $false
    }
    if ($env:PATH -notlike "*platform-tools*") {
        $env:PATH = $env:PATH + ";" + $adbPath
    }
    return $true
}

function Restart-Adb {
    if (-not (Ensure-AdbPath)) { return $false }
    & adb kill-server 2>$null
    Start-Sleep -Milliseconds 600
    & adb start-server 2>&1 | Out-Null
    return $true
}

function Get-AdbDeviceState([string]$deviceId) {
    # Devolve 'device', 'unauthorized', 'offline' ou $null (nao encontrado).
    if (-not (Ensure-AdbPath)) { return $null }
    $lines = & adb devices 2>&1
    foreach ($line in $lines) {
        if ($line -match '^\s*(\S+)\s+(device|unauthorized|offline)\s*') {
            $id = $Matches[1]
            $state = $Matches[2]
            if (-not $deviceId -or $id -eq $deviceId) { return $state }
        }
    }
    return $null
}

function Test-AdbDevice([string]$deviceId) {
    return (Get-AdbDeviceState $deviceId) -eq 'device'
}

function Wait-AdbDevice([string]$deviceId, [int]$seconds = 25) {
    $warnedUnauthorized = $false
    for ($i = 0; $i -lt $seconds; $i++) {
        $state = Get-AdbDeviceState $deviceId
        if ($state -eq 'device') { return $true }
        if ($state -eq 'unauthorized' -and -not $warnedUnauthorized) {
            Write-Warning "Dispositivo $deviceId pediu autorizacao USB. Verifica o telemovel e aceita o popup 'Permitir depuracao USB' (marca 'sempre permitir')."
            $warnedUnauthorized = $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

$defines = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) {
            $defines[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
}

$coreDefines = @(
    "MAPBOX_ACCESS_TOKEN=$($defines['MAPBOX_ACCESS_TOKEN'])",
    "SUPABASE_URL=$($defines['SUPABASE_URL'])",
    "SUPABASE_ANON_KEY=$($defines['SUPABASE_ANON_KEY'])",
    "OPENAI_API_KEY=$($defines['OPENAI_API_KEY'])",
    "REVENUECAT_API_KEY_ANDROID=$($defines['REVENUECAT_API_KEY_ANDROID'])"
)

$rcDefaults = @{
    'REVENUECAT_ENTITLEMENT_PRO'      = 'pro'
    'REVENUECAT_ENTITLEMENT_ELITE'    = 'elite'
    'REVENUECAT_PACKAGE_PRO_MONTHLY'  = 'pro_monthly'
    'REVENUECAT_PACKAGE_PRO_ANNUAL'   = 'pro_annual'
    'REVENUECAT_PACKAGE_ELITE_ANNUAL' = 'elite_annual'
}
foreach ($key in $rcDefaults.Keys) {
    if (-not $defines.ContainsKey($key) -or -not $defines[$key]) {
        $defines[$key] = $rcDefaults[$key]
    }
}

if (-not $defines.ContainsKey('SUPABASE_RESET_REDIRECT') -or -not $defines['SUPABASE_RESET_REDIRECT']) {
    $defines['SUPABASE_RESET_REDIRECT'] = 'https://aquanautix.vercel.app/reset-password'
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

$mapboxDownloadsToken = $null
if ($defines.ContainsKey('MAPBOX_DOWNLOADS_TOKEN') -and $defines['MAPBOX_DOWNLOADS_TOKEN']) {
    $mapboxDownloadsToken = $defines['MAPBOX_DOWNLOADS_TOKEN']
} elseif ($defines.ContainsKey('MAPBOX_DOWNLOAD_TOKEN') -and $defines['MAPBOX_DOWNLOAD_TOKEN']) {
    $mapboxDownloadsToken = $defines['MAPBOX_DOWNLOAD_TOKEN']
}

if ($mapboxDownloadsToken) {
    $env:MAPBOX_DOWNLOADS_TOKEN = $mapboxDownloadsToken
    $env:MAPBOX_DOWNLOAD_TOKEN = $mapboxDownloadsToken
}

Set-Location $root

if ($Miui) {
    if (-not $d) {
        Write-Error "Modo -Miui requer -d <device_id>"
        exit 1
    }

    Write-Host "[MIUI] Reiniciar ADB e verificar $d" -ForegroundColor Cyan
    if (-not (Restart-Adb)) { exit 1 }
    if (-not (Wait-AdbDevice $d)) {
        Write-Error "Dispositivo $d nao detectado. USB debugging + autorizar PC + Instalar via USB (MIUI)."
        exit 1
    }

    $apk = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"

    if (-not $SkipBuild) {
        Write-Host "[MIUI] flutter build apk --debug (1a build Mapbox pode demorar 10-15 min)" -ForegroundColor Cyan
        & flutter build apk --debug --verbose @dartDefines
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }

    if (-not (Test-Path $apk)) {
        Write-Error "APK nao encontrado: $apk"
        exit 1
    }

    Write-Host "[MIUI] adb push + install" -ForegroundColor Cyan
    $pushOut = & adb -s $d push $apk /data/local/tmp/app-debug.apk 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $pushOut
        exit $LASTEXITCODE
    }
    if ($pushOut) { Write-Host $pushOut }
    & adb -s $d shell pm install -r -t /data/local/tmp/app-debug.apk
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Instalacao falhou. MIUI: desactivar optimizacao para a app."
        exit 1
    }

    Write-Host "[MIUI] flutter run (APK pre-instalado)" -ForegroundColor Cyan
    & flutter run -d $d "--use-application-binary=$apk" @dartDefines
    exit $LASTEXITCODE
}

if ($d) {
    Ensure-AdbPath | Out-Null
    if (-not (Test-AdbDevice $d)) {
        # So reiniciar o servidor ADB (disruptivo, pode desligar a ligacao USB
        # por instantes) quando o dispositivo NAO esta ja visivel e a funcionar.
        Write-Host "[ADB] $d nao esta visivel - a reiniciar servidor ADB e a aguardar..." -ForegroundColor Yellow
        Restart-Adb | Out-Null
        if (-not (Wait-AdbDevice $d 25)) {
            $state = Get-AdbDeviceState $d
            if (-not $state) { $state = 'nao detectado' }
            Write-Error @"
Dispositivo $d nao ficou disponivel no ADB apos 25s (estado: $state).
Verifica:
  1) Cabo USB liga dados (nao so carregamento) e a porta USB.
  2) 'Depuracao USB' activa em Definicoes > Opcoes de programador.
  3) Popup 'Permitir depuracao USB' aceite no telemovel (activa 'sempre permitir deste computador').
  4) Se o problema persistir, tenta: .\tools\run_dev.ps1 -d $d -Miui
"@
            exit 1
        }
    }
}

$deviceFlag = if ($d) { @('-d', $d) } else { @() }
$apk = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"

if ($SkipBuild -and $d -and (Test-Path $apk)) {
    Write-Host "[SkipBuild] APK existente - a saltar Gradle (arranque ~30-60s)" -ForegroundColor Cyan
    & flutter run -d $d "--use-application-binary=$apk" @dartDefines
    exit $LASTEXITCODE
}

Write-Host "flutter run $($deviceFlag -join ' ') [+ dart-defines]" -ForegroundColor Cyan
Write-Host 'APK ja compilado? Use: .\tools\run_dev.ps1 -d <device> -SkipBuild' -ForegroundColor DarkGray
Write-Host 'Xiaomi lento? Use: .\tools\run_dev.ps1 -d <device> -Miui -SkipBuild' -ForegroundColor DarkGray

& flutter run @deviceFlag @dartDefines
