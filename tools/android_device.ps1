# Funcoes partilhadas ADB / Android fisico (MIUI-safe).
# Dot-source: . "$PSScriptRoot\android_device.ps1"

$script:DefaultAndroidDeviceId = 'WWZLYDXWYXT8PV5D'

function Get-AdbExe {
    $adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
    if (-not (Test-Path $adbPath)) {
        return $null
    }
    if ($env:PATH -notlike '*platform-tools*') {
        $env:PATH = $env:PATH + ';' + (Split-Path $adbPath -Parent)
    }
    return $adbPath
}

function Restart-AdbDaemon {
    $adb = Get-AdbExe
    if (-not $adb) {
        Write-Warning "ADB nao encontrado. Instala Android SDK platform-tools."
        return $false
    }
    & $adb kill-server 2>$null
    Start-Sleep -Milliseconds 500
    & $adb start-server 2>&1 | Out-Null
    return $true
}

function Get-AdbDeviceLines {
    $adb = Get-AdbExe
    if (-not $adb) { return @() }
    return @(& $adb devices -l 2>&1 | Where-Object { $_ -match '^\S+\s+(device|unauthorized|offline)' })
}

function Get-AdbDeviceState {
    param([string]$DeviceId)
    foreach ($line in (Get-AdbDeviceLines)) {
        if ($line -match '^\s*(\S+)\s+(device|unauthorized|offline)\b') {
            if (-not $DeviceId -or $Matches[1] -eq $DeviceId) {
                return $Matches[2]
            }
        }
    }
    return $null
}

function Wait-AdbDeviceReady {
    param(
        [string]$DeviceId,
        [int]$TimeoutSec = 45
    )
    $warnedUnauthorized = $false
    $warnedMissing = $false
    for ($i = 0; $i -lt $TimeoutSec; $i++) {
        $state = Get-AdbDeviceState $DeviceId
        if ($state -eq 'device') { return $true }
        if ($state -eq 'unauthorized' -and -not $warnedUnauthorized) {
            Write-Host ''
            Write-Host '>>> OLHA O TELEMOVEL: aceita "Permitir depuracao USB" (marca "sempre permitir") <<<' -ForegroundColor Yellow
            Write-Host ''
            $warnedUnauthorized = $true
        }
        if ($state -eq 'offline' -and ($i % 8) -eq 0) {
            Write-Host '[ADB] Dispositivo offline — desliga e volta a ligar o cabo USB (modo dados).' -ForegroundColor DarkYellow
        }
        if (-not $state -and -not $warnedMissing -and $i -ge 5) {
            Write-Host '[ADB] A aguardar cabo USB / dispositivo...' -ForegroundColor DarkYellow
            $warnedMissing = $true
        }
        Start-Sleep -Seconds 1
    }
    return $false
}

function Test-AdbDeviceStable {
    param(
        [string]$DeviceId,
        [int]$Checks = 3,
        [int]$IntervalMs = 400
    )
    for ($i = 0; $i -lt $Checks; $i++) {
        if ((Get-AdbDeviceState $DeviceId) -ne 'device') { return $false }
        Start-Sleep -Milliseconds $IntervalMs
    }
    return $true
}

function Assert-FlutterDevice {
    param([string]$DeviceId)

    $out = & flutter devices 2>&1 | Out-String
    if ($out -match [regex]::Escape($DeviceId)) { return $true }

    Write-Host '[ADB] Flutter ainda nao ve o telemovel — a aguardar 5s...' -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    $out = & flutter devices 2>&1 | Out-String
    return ($out -match [regex]::Escape($DeviceId))
}

function Ensure-AdbDevice {
    param([string]$DeviceId)

    if (-not (Get-AdbExe)) { return $false }

    if (Test-AdbDeviceStable $DeviceId) { return $true }

    $state = Get-AdbDeviceState $DeviceId
    Write-Host "[ADB] A preparar ligacao a $DeviceId (estado inicial: $(if ($state) { $state } else { 'nao detectado' }))..." -ForegroundColor Yellow

    # Nao matar o servidor se o dispositivo ja estava OK — evita offline/unauthorized.
    if ($state -ne 'device') {
        Restart-AdbDaemon | Out-Null
    }

    if (Wait-AdbDeviceReady $DeviceId 45) {
        return (Test-AdbDeviceStable $DeviceId)
    }

    $state = Get-AdbDeviceState $DeviceId
    if ($state -eq 'unauthorized') {
        Write-Host '[ADB] Revoga autorizacoes USB no telemovel (Opcoes programador) e religa o cabo.' -ForegroundColor Yellow
    }

    Restart-AdbDaemon | Out-Null
    if (-not (Wait-AdbDeviceReady $DeviceId 30)) { return $false }
    return (Test-AdbDeviceStable $DeviceId)
}

function Get-ConnectedAndroidDeviceIds {
    $ids = @()
    foreach ($line in (Get-AdbDeviceLines)) {
        if ($line -match '^\s*(\S+)\s+device\b') {
            $id = $Matches[1]
            if ($id -notmatch '^emulator-') {
                $ids += $id
            }
        }
    }
    return $ids
}

function Resolve-AndroidDeviceId {
    param([string]$RequestedId)

    if ($RequestedId) { return $RequestedId }

    $ids = Get-ConnectedAndroidDeviceIds
    if ($ids.Count -eq 1) { return $ids[0] }
    if ($ids -contains $script:DefaultAndroidDeviceId) { return $script:DefaultAndroidDeviceId }
    if ($ids.Count -gt 0) { return $ids[0] }

    return $script:DefaultAndroidDeviceId
}

function Test-IsPhysicalAndroidDevice {
    param([string]$DeviceId)
    $adb = Get-AdbExe
    if (-not $adb) { return $false }
    $out = & $adb -s $DeviceId shell getprop ro.product.model 2>$null
    return ($LASTEXITCODE -eq 0 -and $out)
}

function Install-ApkMiuiSafe {
    param(
        [string]$DeviceId,
        [string]$ApkPath
    )

    $adb = Get-AdbExe
    if (-not $adb) { return $false }
    if (-not (Test-Path $ApkPath)) {
        Write-Error "APK nao encontrado: $ApkPath"
        return $false
    }

    Write-Host "[MIUI] adb push + pm install (-r -t)" -ForegroundColor Cyan
    $pushOut = & $adb -s $DeviceId push $ApkPath /data/local/tmp/app-debug.apk 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host $pushOut
        return $false
    }
    if ($pushOut) { Write-Host $pushOut }

    $installOut = & $adb -s $DeviceId shell pm install -r -t /data/local/tmp/app-debug.apk 2>&1
    Write-Host $installOut
    if ($LASTEXITCODE -ne 0) {
        Write-Error @"
Instalacao falhou no MIUI. No telemovel:
  1) Opcoes de programador > Instalar via USB = ON
  2) Desactiva optimizacao de bateria para esta app
  3) Aceita popup de instalacao se aparecer
"@
        return $false
    }
    return $true
}

function Test-ApkNeedsRebuild {
    param(
        [string]$Root,
        [string]$ApkPath
    )

    if (-not (Test-Path $ApkPath)) { return $true }

    $apkTime = (Get-Item $ApkPath).LastWriteTimeUtc

    foreach ($file in @('pubspec.yaml', 'pubspec.lock')) {
        $p = Join-Path $Root $file
        if ((Test-Path $p) -and (Get-Item $p).LastWriteTimeUtc -gt $apkTime) {
            return $true
        }
    }

    foreach ($dir in @('lib', 'assets', 'android')) {
        $base = Join-Path $Root $dir
        if (-not (Test-Path $base)) { continue }
        $newest = Get-ChildItem $base -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending |
            Select-Object -First 1
        if ($newest -and $newest.LastWriteTimeUtc -gt $apkTime) {
            return $true
        }
    }

    return $false
}
