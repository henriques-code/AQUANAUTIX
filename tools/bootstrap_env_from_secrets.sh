#!/usr/bin/env bash
# Gera .env na raiz a partir de variáveis de ambiente (secrets Cursor Cloud).
# Nunca sobrescreve .env existente. Nunca imprime valores.
#
# Uso (após configurar secrets na Cloud):
#   ./tools/bootstrap_env_from_secrets.sh
#   ./tools/verify_env.sh
#   ./tools/run_dev.sh -d chrome

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

if [[ -f "$ENV_FILE" ]]; then
  echo "OK: .env já existe em $ENV_FILE — não sobrescrito."
  exit 0
fi

written=0
skipped=0

{
  echo "# Gerado por tools/bootstrap_env_from_secrets.sh — não versionar"
  echo "# $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  for k in "${ENV_BOOTSTRAP_KEYS[@]}"; do
    if [[ -n "${!k:-}" ]]; then
      # Valores sem aspas; evita quebrar .env com espaços simples
      printf '%s=%s\n' "$k" "${!k}"
      ((written++)) || true
    else
      ((skipped++)) || true
    fi
  done
} > "$ENV_FILE"

if [[ $written -eq 0 ]]; then
  rm -f "$ENV_FILE"
  echo "ERRO: nenhuma variável de ambiente encontrada. Configura secrets Cursor (SUPABASE_URL, SUPABASE_ANON_KEY, …)." >&2
  exit 1
fi

chmod 600 "$ENV_FILE" 2>/dev/null || true

echo "OK: .env criado em $ENV_FILE ($written chaves escritas, $skipped em falta no ambiente)."

if ! "$SCRIPT_DIR/verify_env.sh" >/dev/null 2>&1; then
  echo "AVISO: verify_env.sh reportou chaves em falta — completa secrets ou edita .env manualmente." >&2
  exit 2
fi

echo "OK: verify_env.sh passou."
