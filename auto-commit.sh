#!/usr/bin/env bash
# AQUANAUTIX — commit e push automático
#
# Uso:
#   ./auto-commit.sh "mensagem descritiva do que mudou"
#
# O que faz:
#   1. git add -A
#   2. Remove do staging qualquer ficheiro sensível apanhado por engano
#   3. git commit -m "<mensagem>"
#   4. git push origin <branch actual> (detecta o nome real da branch)
#
# Se o push falhar por falta de autenticação, o script avisa e sugere
# configurar uma chave SSH ou um Personal Access Token — nunca insere
# credenciais no repositório.

set -euo pipefail

MSG="${1:-}"

if [ -z "$MSG" ]; then
  echo "Uso: ./auto-commit.sh \"mensagem descritiva\""
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "Erro: não estás dentro de um repositório git."
  exit 1
fi
cd "$REPO_ROOT"

BRANCH="$(git symbolic-ref --short -q HEAD || echo "")"
if [ -z "$BRANCH" ]; then
  echo "Erro: não foi possível determinar a branch actual (HEAD destacado?)."
  exit 1
fi

echo "→ Repositório: $REPO_ROOT"
echo "→ Branch actual: $BRANCH"
echo "→ A adicionar alterações (git add -A)..."
git add -A

# Nunca commitar ficheiros sensíveis, mesmo que tenham entrado por engano no staging.
SENSITIVE_PATTERNS=(".env" "local_secrets.ps1" ".pem" ".key" "sbp_" "sk_")

STAGED_FILES="$(git diff --cached --name-only || true)"
if [ -n "$STAGED_FILES" ]; then
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
      if [[ "$file" == *"$pattern"* ]]; then
        echo "⚠️  A remover do commit por ser sensível: $file"
        git restore --staged -- "$file" 2>/dev/null || git reset -- "$file" 2>/dev/null || true
        break
      fi
    done
  done <<< "$STAGED_FILES"
fi

if git diff --cached --quiet; then
  echo "Nada para commitar (sem alterações depois de filtrar ficheiros sensíveis)."
  exit 0
fi

echo "→ A criar commit..."
git commit -m "$MSG"

echo "→ A tentar push para origin/$BRANCH..."
PUSH_OUTPUT="$(git push origin "$BRANCH" 2>&1)" && PUSH_OK=1 || PUSH_OK=0
echo "$PUSH_OUTPUT"

if [ "$PUSH_OK" = "1" ]; then
  echo "✅ Commit e push concluídos com sucesso para origin/$BRANCH."
  exit 0
fi

if echo "$PUSH_OUTPUT" | grep -qi "must be made through a pull request\|protected branch\|GH013"; then
  # Branch protegida (exige PR) — cria um branch novo a partir do commit actual e envia-o.
  NEW_BRANCH="auto-commit/$(date +%Y%m%d-%H%M%S)"
  echo ""
  echo "⚠️  A branch '$BRANCH' está protegida no GitHub (exige Pull Request)."
  echo "→ A criar branch '$NEW_BRANCH' com o mesmo commit e a enviá-lo..."
  git branch "$NEW_BRANCH"
  if git push origin "$NEW_BRANCH"; then
    REMOTE_URL="$(git remote get-url origin | sed -E 's#\.git$##')"
    if [[ "$REMOTE_URL" =~ ^git@github\.com:(.+)$ ]]; then
      REMOTE_URL="https://github.com/${BASH_REMATCH[1]}"
    elif [[ "$REMOTE_URL" =~ ^ssh://git@github\.com/(.+)$ ]]; then
      REMOTE_URL="https://github.com/${BASH_REMATCH[1]}"
    fi
    echo "✅ Branch '$NEW_BRANCH' enviado com sucesso."
    echo "   Abre um Pull Request aqui:"
    echo "   $REMOTE_URL/compare/$BRANCH...$NEW_BRANCH?expand=1"
  else
    echo "❌ Também falhou o push do branch novo. Verifica a autenticação (ver sugestões abaixo)."
    exit 1
  fi
else
  echo ""
  echo "❌ O commit foi feito localmente, mas o push falhou."
  echo "   Causas mais comuns:"
  echo "   - Falta autenticação com o GitHub (sem SSH key nem token guardado)."
  echo "   - A branch remota tem alterações que não tens localmente (precisa de pull/rebase)."
  echo ""
  echo "   Sugestões para configurar push automático sem pedir password sempre:"
  echo "   1) SSH:   ssh-keygen -t ed25519 -C \"o-teu-email@exemplo.com\""
  echo "             depois adiciona a chave pública em https://github.com/settings/keys"
  echo "             e muda o remote: git remote set-url origin git@github.com:<user>/<repo>.git"
  echo "   2) Token: cria um Personal Access Token em https://github.com/settings/tokens"
  echo "             e garante que 'git config credential.helper' está definido"
  echo "             (ex.: 'manager' no Windows) para o Git guardar a credencial."
  echo ""
  exit 1
fi
