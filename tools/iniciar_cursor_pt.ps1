# Arranca o Cursor em portugues (pt-br) — interface VS Code traduzida.
$cursorExe = 'C:\Program Files\cursorIA\Cursor.exe'
$cursorCmd = 'C:\Program Files\cursorIA\resources\app\bin\cursor.cmd'

if (-not (Test-Path $cursorExe)) {
    Write-Error "Cursor nao encontrado em $cursorExe"
    exit 1
}

$localeFile = Join-Path $env:APPDATA 'Cursor\User\locale.json'
$argvFile = Join-Path $env:APPDATA 'Cursor\argv.json'
$userArgv = Join-Path $env:USERPROFILE '.cursor\argv.json'

@{
    locale = 'pt-br'
} | ConvertTo-Json | Set-Content -Path $localeFile -Encoding UTF8

$argv = @{
    'enable-crash-reporter' = $true
    'crash-reporter-id'    = 'dcccc21d-7522-459d-8797-e9c188ca947f'
    locale                 = 'pt-br'
}
$argv | ConvertTo-Json | Set-Content -Path $argvFile -Encoding UTF8
$argv | ConvertTo-Json | Set-Content -Path $userArgv -Encoding UTF8

Write-Host "A fechar instancias Cursor..." -ForegroundColor Cyan
Get-Process -Name 'Cursor' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

Write-Host "A arrancar Cursor em portugues (--locale=pt-br)..." -ForegroundColor Cyan
Start-Process -FilePath $cursorExe -ArgumentList '--locale=pt-br'
