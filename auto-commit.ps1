# AQUANAUTIX — commit e push automático (equivalente PowerShell do auto-commit.sh)
#
# Uso:
#   .\auto-commit.ps1 "mensagem descritiva do que mudou"
#
# O que faz:
#   1. git add -A
#   2. Remove do staging qualquer ficheiro sensível apanhado por engano
#   3. git commit -m "<mensagem>"
#   4. git push origin <branch actual> (detecta o nome real da branch)

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Mensagem
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "Não estás dentro de um repositório git."
    exit 1
}
Set-Location $repoRoot

$branch = git symbolic-ref --short -q HEAD
if (-not $branch) {
    Write-Error "Não foi possível determinar a branch actual (HEAD destacado?)."
    exit 1
}

Write-Host "-> Repositorio: $repoRoot"
Write-Host "-> Branch actual: $branch"
Write-Host "-> A adicionar alteracoes (git add -A)..."
git add -A

# Nunca commitar ficheiros sensíveis, mesmo que tenham entrado por engano no staging.
$sensitivePatterns = @(".env", "local_secrets.ps1", ".pem", ".key", "sbp_", "sk_")

$stagedFiles = git diff --cached --name-only
foreach ($file in $stagedFiles) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    foreach ($pattern in $sensitivePatterns) {
        if ($file -like "*$pattern*") {
            Write-Host "AVISO: a remover do commit por ser sensivel: $file"
            git restore --staged -- "$file" 2>$null
            if ($LASTEXITCODE -ne 0) { git reset -- "$file" 2>$null }
            break
        }
    }
}

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "Nada para commitar (sem alteracoes depois de filtrar ficheiros sensiveis)."
    exit 0
}

Write-Host "-> A criar commit..."
git commit -m $Mensagem

Write-Host "-> A tentar push para origin/$branch..."
$pushOutput = git push origin $branch 2>&1
$pushOutput | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: commit e push concluidos com sucesso para origin/$branch."
    exit 0
}

$pushText = $pushOutput -join "`n"
if ($pushText -match "must be made through a pull request|protected branch|GH013") {
    $newBranch = "auto-commit/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host ""
    Write-Host "AVISO: a branch '$branch' esta protegida no GitHub (exige Pull Request)."
    Write-Host "-> A criar branch '$newBranch' com o mesmo commit e a envia-lo..."
    git branch $newBranch
    git push origin $newBranch
    if ($LASTEXITCODE -eq 0) {
        $remoteUrl = (git remote get-url origin) -replace '\.git$', ''
        Write-Host "OK: branch '$newBranch' enviado com sucesso."
        Write-Host "   Abre um Pull Request aqui:"
        Write-Host "   $remoteUrl/compare/$branch...$newBranch`?expand=1"
    } else {
        Write-Host "ERRO: tambem falhou o push do branch novo. Verifica a autenticacao (ver sugestoes abaixo)."
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "ERRO: o commit foi feito localmente, mas o push falhou."
    Write-Host "   Causas mais comuns:"
    Write-Host "   - Falta autenticacao com o GitHub (sem SSH key nem token guardado)."
    Write-Host "   - A branch remota tem alteracoes que nao tens localmente (precisa de pull/rebase)."
    Write-Host ""
    Write-Host "   Sugestoes para configurar push automatico sem pedir password sempre:"
    Write-Host "   1) SSH:   ssh-keygen -t ed25519 -C `"o-teu-email@exemplo.com`""
    Write-Host "             depois adiciona a chave publica em https://github.com/settings/keys"
    Write-Host "             e muda o remote: git remote set-url origin git@github.com:<user>/<repo>.git"
    Write-Host "   2) Token: cria um Personal Access Token em https://github.com/settings/tokens"
    Write-Host "             e garante que 'git config credential.helper' esta definido"
    Write-Host "             (ja esta como 'manager' neste PC) para o Git guardar a credencial."
    Write-Host ""
    exit 1
}
