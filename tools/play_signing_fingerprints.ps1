# play_signing_fingerprints.ps1 - SHA-1/SHA-256 para Google Play + OAuth
# Uso: .\tools\play_signing_fingerprints.ps1

Write-Host ""
Write-Host "=== AQUANAUTIX - Signing fingerprints ===" -ForegroundColor Cyan
Write-Host "Package: com.aquanautix.app" -ForegroundColor Gray
Write-Host ""

$debugKeystore = Join-Path $env:USERPROFILE ".android\debug.keystore"
if (Test-Path $debugKeystore) {
    Write-Host "DEBUG keystore ($debugKeystore):" -ForegroundColor Yellow
    & keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android 2>$null |
        Select-String -Pattern "SHA1:|SHA256:"
} else {
    Write-Host "DEBUG keystore nao encontrado em $debugKeystore" -ForegroundColor Red
}

$root = Split-Path $PSScriptRoot -Parent
$keyProps = Join-Path $root "android\key.properties"
if (Test-Path $keyProps) {
    $props = @{}
    Get-Content $keyProps | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $p = $line -split "=", 2
            if ($p.Count -eq 2) { $props[$p[0].Trim()] = $p[1].Trim() }
        }
    }
    $storeFile = $props["storeFile"]
    if ($storeFile -and (Test-Path $storeFile)) {
        Write-Host ""
        Write-Host "RELEASE keystore ($storeFile):" -ForegroundColor Yellow
        & keytool -list -v -keystore $storeFile -alias $props["keyAlias"] -storepass $props["storePassword"] 2>$null |
            Select-String -Pattern "SHA1:|SHA256:"
    }
} else {
    Write-Host ""
    Write-Host "Sem android/key.properties - release signing nao configurado." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Regista SHA-1 em Google Cloud OAuth e Play Console Integridade da app." -ForegroundColor Cyan
Write-Host ""
