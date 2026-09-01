# run_dev.ps1 - Flutter com tokens do .env + deploy MIUI-safe (Xiaomi)
# Uso recomendado (1 comando, faz tudo):
#   .\tools\run_dev.ps1
#   .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
# Forcar rebuild: .\tools\run_dev.ps1 -Rebuild
# Saltar build (APK ja actual): .\tools\run_dev.ps1 -SkipBuild

param(
    [string]$d = "",
    [switch]$Miui,
    [switch]$NoMiui,
    [switch]$SkipBuild,
    [switch]$Rebuild,
    [switch]$Fast,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'android_device.ps1')

$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) {
    Write-Error ".env nao encontrado em $root"
    exit 1
}

$jbr = 'C:\Program Files\Android\Android Studio\jbr'
if (Test-Path $jbr) {
    $env:JAVA_HOME = $jbr
    $env:PATH = "$jbr\bin;" + $env:PATH
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

if ($defines.ContainsKey('MAPBOX_DOWNLOADS_TOKEN') -and $defines['MAPBOX_DOWNLOADS_TOKEN']) {
    $env:MAPBOX_DOWNLOADS_TOKEN = $defines['MAPBOX_DOWNLOADS_TOKEN']
    $env:MAPBOX_DOWNLOAD_TOKEN = $defines['MAPBOX_DOWNLOADS_TOKEN']
} elseif ($defines.ContainsKey('MAPBOX_DOWNLOAD_TOKEN') -and $defines['MAPBOX_DOWNLOAD_TOKEN']) {
    $env:MAPBOX_DOWNLOADS_TOKEN = $defines['MAPBOX_DOWNLOAD_TOKEN']
    $env:MAPBOX_DOWNLOAD_TOKEN = $defines['MAPBOX_DOWNLOAD_TOKEN']
}

Set-Location $root

$deviceId = Resolve-AndroidDeviceId $d
$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-debug.apk'

$needsBuild = $false
if ($Fast) {
    $SkipBuild = $true
    Write-Host '[run_dev] Modo -Fast: instalar APK existente (sem Gradle)' -ForegroundColor Green
} elseif ($Rebuild) {
    $needsBuild = $true
} elseif (-not $SkipBuild) {
    $needsBuild = Test-ApkNeedsRebuild $root $apk
    if ($needsBuild) {
        Write-Host '[run_dev] Codigo/assets mudaram — rebuild necessario. Para saltar: -Fast ou -SkipBuild' -ForegroundColor Yellow
    }
}

# Build ANTES de exigir ADB (podes compilar enquanto religas o cabo).
if ($needsBuild) {
    Write-Host '[run_dev] flutter build apk --debug (inclui assets/species — 1a vez ~10-15 min)' -ForegroundColor Cyan
    & flutter build apk --debug @dartDefines
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

if (-not (Ensure-AdbDevice $deviceId)) {
    $state = Get-AdbDeviceState $deviceId
    if (-not $state) { $state = 'nao detectado' }
    Write-Error @"
Dispositivo $deviceId indisponivel (estado: $state).
Checklist:
  1) Cabo USB com dados (nao so carregamento)
  2) Depuracao USB ON (Opcoes de programador)
  3) Aceitar popup 'Permitir depuracao USB' no telemovel
  4) MIUI: 'Instalar via USB' ON
  5) Testar: adb devices
"@
    exit 1
}

$useMiuiPipeline = -not $NoMiui
if ($useMiuiPipeline -and -not (Test-IsPhysicalAndroidDevice $deviceId)) {
    $useMiuiPipeline = $false
}
if ($Miui) { $useMiuiPipeline = $true }

if ($useMiuiPipeline) {
    Write-Host "[run_dev] Modo Android fisico (MIUI-safe) -> $deviceId" -ForegroundColor Cyan

    if (-not $needsBuild) {
        Write-Host '[run_dev] APK actual - a saltar Gradle' -ForegroundColor Green
    }

    if (-not (Test-Path $apk)) {
        Write-Error "APK nao encontrado: $apk"
        exit 1
    }

    if (-not (Install-ApkMiuiSafe -DeviceId $deviceId -ApkPath $apk)) {
        exit 1
    }

    if (-not (Assert-FlutterDevice $deviceId)) {
        Write-Error "ADB OK mas Flutter nao ve $deviceId. Desliga/liga o cabo e corre de novo."
        exit 1
    }

    Write-Host '[run_dev] flutter attach (hot reload) com APK pre-instalado' -ForegroundColor Cyan
    $runArgs = @('run', '-d', $deviceId, "--use-application-binary=$apk") + $dartDefines + $FlutterArgs
    & flutter @runArgs
    exit $LASTEXITCODE
}

# Emulador / desktop / fallback
if ($needsBuild -and (Test-Path $apk)) {
    & flutter run -d $deviceId "--use-application-binary=$apk" @dartDefines @FlutterArgs
} elseif ($needsBuild) {
    & flutter run -d $deviceId @dartDefines @FlutterArgs
} elseif (Test-Path $apk) {
    & flutter run -d $deviceId "--use-application-binary=$apk" @dartDefines @FlutterArgs
} else {
    & flutter run -d $deviceId @dartDefines @FlutterArgs
}
exit $LASTEXITCODE
