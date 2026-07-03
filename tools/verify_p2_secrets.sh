#!/usr/bin/env bash
# Audita chaves P2 no .env — NUNCA imprime valores.
# Uso: ./tools/verify_p2_secrets.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

env_load_config

echo "=== AQUANAUTIX · verificação P2 (Edge Functions / RC webhook) ==="
echo "    .env: $([[ -f "$ENV_FILE" ]] && echo "presente" || echo "AUSENTE — coloca .env na raiz do repo")"
echo ""

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: .env não encontrado em $ENV_FILE" >&2
  echo "      Todas as chaves devem estar no .env local (gitignored)." >&2
  exit 1
fi

ok=0
fail=0

check() {
  local key="$1" kind="$2"
  if [[ -n "${ENV_VALUES[$key]:-}" ]]; then
    echo "  OK   $key ($kind)"
    ((ok++)) || true
  else
    echo "  FALTA $key ($kind)"
    ((fail++)) || true
  fi
}

echo "CLI Supabase:"
check SUPABASE_ACCESS_TOKEN "cli — supabase secrets set"
echo ""
echo "Edge Functions (revenuecat-webhook + sync-subscription-tier):"
check REVENUECAT_SECRET_API_KEY "edge — API secret RC (sk_...)"
check REVENUECAT_WEBHOOK_AUTHORIZATION "edge — header Authorization no dashboard RC"
check REVENUECAT_ENTITLEMENT_PRO "edge — opcional (default: pro)"
check REVENUECAT_ENTITLEMENT_ELITE "edge — opcional (default: elite)"
echo ""
echo "App (run_dev — já no verify_env.sh):"
check SUPABASE_URL "app"
check SUPABASE_ANON_KEY "app"
check REVENUECAT_API_KEY_ANDROID "app"

echo ""
if [[ $fail -eq 0 ]]; then
  echo "P2 .env OK ($ok chaves). Próximo: ./tools/configure_p2_secrets.sh (ou .ps1 no Windows)"
  echo "Depois: RevenueCat → Webhooks → Authorization = valor de REVENUECAT_WEBHOOK_AUTHORIZATION"
  exit 0
fi

echo "Resumo: $ok presentes, $fail em falta — completa o .env na raiz AQUANAUTIX."
exit 1
