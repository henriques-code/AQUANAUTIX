#!/usr/bin/env bash
# Injecta secrets P2 do .env local no Supabase remoto (Edge Functions).
# NUNCA imprime valores. NUNCA commita .env.
#
# Pré-requisitos no .env:
#   SUPABASE_ACCESS_TOKEN=sbp_...
#   REVENUECAT_SECRET_API_KEY=sk_...
#   REVENUECAT_WEBHOOK_AUTHORIZATION=Bearer aquanautix-rc-wh-...
#
# Uso:
#   ./tools/verify_p2_secrets.sh
#   ./tools/configure_p2_secrets.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

PROJECT_REF="${SUPABASE_PROJECT_REF:-ycmvqokcfzxkpinvcyhk}"

env_load_config

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: .env não encontrado em $ENV_FILE" >&2
  exit 1
fi

for required in SUPABASE_ACCESS_TOKEN REVENUECAT_SECRET_API_KEY REVENUECAT_WEBHOOK_AUTHORIZATION; do
  if [[ -z "${ENV_VALUES[$required]:-}" ]]; then
    echo "ERRO: $required em falta no .env — corre ./tools/verify_p2_secrets.sh" >&2
    exit 1
  fi
done

export SUPABASE_ACCESS_TOKEN="${ENV_VALUES[SUPABASE_ACCESS_TOKEN]}"

tmp="$(mktemp)"
chmod 600 "$tmp"
trap 'rm -f "$tmp"' EXIT

{
  printf 'REVENUECAT_SECRET_API_KEY=%s\n' "${ENV_VALUES[REVENUECAT_SECRET_API_KEY]}"
  printf 'REVENUECAT_WEBHOOK_AUTHORIZATION=%s\n' "${ENV_VALUES[REVENUECAT_WEBHOOK_AUTHORIZATION]}"
  if [[ -n "${ENV_VALUES[REVENUECAT_ENTITLEMENT_PRO]:-}" ]]; then
    printf 'REVENUECAT_ENTITLEMENT_PRO=%s\n' "${ENV_VALUES[REVENUECAT_ENTITLEMENT_PRO]}"
  fi
  if [[ -n "${ENV_VALUES[REVENUECAT_ENTITLEMENT_ELITE]:-}" ]]; then
    printf 'REVENUECAT_ENTITLEMENT_ELITE=%s\n' "${ENV_VALUES[REVENUECAT_ENTITLEMENT_ELITE]}"
  fi
} > "$tmp"

echo "A injectar secrets P2 no projecto $PROJECT_REF (valores não mostrados)…"

cd "$ENV_REPO_ROOT"
npx supabase secrets set --env-file "$tmp" --project-ref "$PROJECT_REF" --yes

echo ""
echo "OK: secrets Edge Functions actualizados."
echo ""
echo "Passo manual no RevenueCat (uma vez):"
echo "  1. app.revenuecat.com → Integrations → Webhooks"
echo "  2. URL: https://${PROJECT_REF}.supabase.co/functions/v1/revenuecat-webhook"
echo "  3. Authorization header = mesmo valor que REVENUECAT_WEBHOOK_AUTHORIZATION no .env"
echo "  4. Eventos: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, UNCANCELLATION, BILLING_ISSUE"
