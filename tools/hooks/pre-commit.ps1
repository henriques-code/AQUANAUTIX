# AQUANAUTIX pre-commit - bloqueia segredos no staging area.
# Instalado via: .\tools\install_git_hooks.ps1

$ErrorActionPreference = "Stop"
$script:fail = $false

function Write-Block {
    param([string]$Message)
    Write-Host "pre-commit BLOQUEADO: $Message" -ForegroundColor Red
    $script:fail = $true
}

$staged = @(git diff --cached --name-only --diff-filter=ACM 2>$null)
if ($staged.Count -eq 0) { exit 0 }

$blockedPathPatterns = @(
    '.env',
    '.env.',
    'local_secrets.ps1',
    'google-services.json',
    'GoogleService-Info.plist',
    'key.properties',
    '.keystore',
    '.jks',
    'androidkey.properties'
)

foreach ($f in $staged) {
    $base = Split-Path -Leaf $f
    $norm = ($f -replace '\\', '/').ToLowerInvariant()

    if ($base -eq '.env' -or $norm -match '(^|/)\.env(\.|$)') {
        Write-Block "ficheiro sensivel staged: $f (.env nunca vai para Git)"
        continue
    }

    foreach ($pat in $blockedPathPatterns) {
        if ($base -like "*$pat*" -or $norm -like "*$pat*") {
            Write-Block "ficheiro sensivel staged: $f (padrao: $pat)"
            break
        }
    }
}

$secretPatterns = @(
    @{ Label = 'OpenAI secret (sk-)';       Regex = 'sk-proj-[A-Za-z0-9_-]{10,}' },
    @{ Label = 'OpenAI secret (sk-)';       Regex = 'sk-[A-Za-z0-9]{20,}' },
    @{ Label = 'Supabase CLI token (sbp_)'; Regex = 'sbp_[A-Za-z0-9]{10,}' },
    @{ Label = 'Supabase service role key'; Regex = 'SUPABASE_SERVICE_ROLE(?:_KEY)?\s*=\s*[''"]?eyJ' },
    @{ Label = 'RevenueCat secret (sk_)';   Regex = 'sk_[A-Za-z0-9]{10,}' }
)

$textExtensions = @(
    '.dart', '.yaml', '.yml', '.json', '.md', '.html', '.js', '.css',
    '.sql', '.ps1', '.sh', '.xml', '.gradle', '.kts', '.properties', '.toml', '.txt'
)

foreach ($f in $staged) {
    $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
    if ($textExtensions -notcontains $ext) { continue }

    $content = git show ":$f" 2>$null
    if (-not $content) { continue }

    foreach ($sp in $secretPatterns) {
        if ($content -match $sp.Regex) {
            Write-Block "$($sp.Label) detectado em $f - usa .env ou local_secrets.ps1"
            break
        }
    }
}

if ($script:fail) {
    Write-Host ""
    Write-Host "Commit cancelado. Remove do staging: git restore --staged FICHEIRO" -ForegroundColor Yellow
    Write-Host "Segredos locais: .env (gitignored) e tools/local_secrets.ps1" -ForegroundColor Yellow
    exit 1
}

exit 0
