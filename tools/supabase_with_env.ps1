# Carrega .env (e opcionalmente local_secrets.ps1) e executa Supabase CLI.
# Uso:
#   .\tools\supabase_with_env.ps1 projects list
#   .\tools\supabase_with_env.ps1 link --project-ref ycmvqokcfzxkpinvcyhk
#   .\tools\supabase_with_env.ps1 db push --yes
#
# No .env (local, gitignored):
#   SUPABASE_ACCESS_TOKEN=sbp_...

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SupabaseArgs
)

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"

function Import-DotEnvFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) { return }
        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) { return }
        $key = $parts[0].Trim()
        $val = $parts[1].Trim().Trim('"').Trim("'")
        if ($key) {
            Set-Item -Path "env:$key" -Value $val
        }
    }
}

Import-DotEnvFile -Path $envFile

$localSecrets = Join-Path $PSScriptRoot "local_secrets.ps1"
if (Test-Path $localSecrets) {
    . $localSecrets
}

if (-not $env:SUPABASE_ACCESS_TOKEN) {
    Write-Error @"
SUPABASE_ACCESS_TOKEN em falta.
Adiciona ao .env (gitignored):
  SUPABASE_ACCESS_TOKEN=sbp_...
Ou corre: npx supabase login
"@
    exit 1
}

if ($SupabaseArgs.Count -eq 0) {
    npx supabase --help
    exit $LASTEXITCODE
}

npx supabase @SupabaseArgs
exit $LASTEXITCODE
