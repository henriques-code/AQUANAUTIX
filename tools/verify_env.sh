#!/usr/bin/env bash
# Verifica .env e/ou variáveis de ambiente — NUNCA imprime valores.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

env_load_config

if [[ ! -f "$ENV_FILE" ]] && [[ ${#ENV_VALUES[@]} -eq 0 ]]; then
  echo "ERRO: sem .env em $ENV_FILE e sem variáveis de ambiente relevantes."
  echo "      Cloud: configura secrets Cursor e corre ./tools/bootstrap_env_from_secrets.sh"
  exit 1
fi

ok=0
fail_optional=0
required_fail=0

check_key() {
  local key="$1" kind="$2"
  if [[ -n "${ENV_VALUES[$key]:-}" ]]; then
    echo "  OK   $key ($kind)"
    ((ok++)) || true
  else
    echo "  FALTA $key ($kind)"
    if [[ "$kind" == "app" ]]; then
      ((required_fail++)) || true
    else
      ((fail_optional++)) || true
    fi
  fi
}

echo "=== Configuração de secrets (AQUANAUTIX) ==="
echo "    .env: $([[ -f "$ENV_FILE" ]] && echo "presente ($ENV_FILE)" || echo "ausente — só env vars")"
echo ""
echo "Obrigatórias para app (run_dev.ps1 / run_dev.sh):"
for k in "${ENV_CORE_KEYS[@]}"; do check_key "$k" "app"; done
echo ""
echo "Opcionais app:"
for k in "${ENV_RC_OPTIONAL_KEYS[@]}" MAPBOX_DOWNLOADS_TOKEN MAPBOX_DOWNLOAD_TOKEN OPENAI_CHAT_MODEL; do
  check_key "$k" "opcional"
done
echo ""
echo "CLI Supabase (supabase_with_env.ps1 — não vai para a app):"
for k in "${ENV_CLI_ONLY_KEYS[@]}"; do check_key "$k" "cli"; done

known=()
for k in "${ENV_CORE_KEYS[@]}" "${ENV_RC_OPTIONAL_KEYS[@]}" "${ENV_CLI_ONLY_KEYS[@]}" \
  MAPBOX_DOWNLOADS_TOKEN MAPBOX_DOWNLOAD_TOKEN OPENAI_CHAT_MODEL; do
  known+=("$k")
done
extra=()
for k in "${!ENV_VALUES[@]}"; do
  found=0
  for x in "${known[@]}"; do [[ "$x" == "$k" ]] && found=1; done
  [[ $found -eq 0 && -n "${ENV_VALUES[$k]}" ]] && extra+=("$k")
done
if [[ ${#extra[@]} -gt 0 ]]; then
  echo ""
  echo "Outras chaves configuradas (não listadas em run_dev):"
  for k in "${extra[@]}"; do echo "  INFO $k"; done
fi

echo ""
echo "Resumo: $ok presentes, $required_fail obrigatórias em falta (${#ENV_CORE_KEYS[@]} esperadas), $fail_optional opcionais/cli em falta"
[[ $required_fail -eq 0 ]] && exit 0 || exit 2
