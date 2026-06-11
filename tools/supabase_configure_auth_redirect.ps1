# Configura redirect URLs de auth no projecto Supabase (recovery password).
# Requer SUPABASE_ACCESS_TOKEN no .env (Dashboard → Account → Access Tokens).
#
# Uso: .\tools\supabase_configure_auth_redirect.ps1

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    Write-Error ".env não encontrado"
    exit 1
}

$defines = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) { $defines[$parts[0].Trim()] = $parts[1].Trim() }
    }
}

$token = $defines['SUPABASE_ACCESS_TOKEN']
$url = $defines['SUPABASE_URL']
if (-not $token -or -not $url) {
    Write-Error "Faltam SUPABASE_ACCESS_TOKEN ou SUPABASE_URL no .env"
    exit 1
}

if ($url -notmatch 'https://([^.]+)\.supabase\.co') {
    Write-Error "SUPABASE_URL inválido"
    exit 1
}
$ref = $Matches[1]

$redirectList = @(
    'aquanautix://reset-password'
    'aquanautix://**'
    'https://aquanautix.vercel.app/**'
    'http://localhost:3000/**'
) -join ','

$body = @{
    site_url       = 'https://aquanautix.vercel.app'
    uri_allow_list = $redirectList
} | ConvertTo-Json

Write-Host "▶  PATCH auth config projecto $ref" -ForegroundColor Cyan
$r = Invoke-RestMethod `
    -Uri "https://api.supabase.com/v1/projects/$ref/config/auth" `
    -Method PATCH `
    -Headers @{
        Authorization  = "Bearer $token"
        'Content-Type' = 'application/json'
    } `
    -Body $body

Write-Host "✓ site_url:" $r.site_url
Write-Host "✓ uri_allow_list:" $r.uri_allow_list
Write-Host ""
Write-Host "Confirma no Dashboard: Authentication → URL Configuration" -ForegroundColor Yellow
