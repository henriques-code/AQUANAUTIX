#!/usr/bin/env bash
# AQUANAUTIX — verificação pré-beta (sem custos de loja)
# Uso: ./tools/launch_beta_verify.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="${HOME}/flutter/bin:${PATH}"

RED='\033[0;31m'
GREEN='\033[0;32m'
AMBER='\033[0;33m'
NC='\033[0m'

pass=0
fail=0
warn=0

ok()   { echo -e "${GREEN}✓${NC} $1"; pass=$((pass + 1)); }
bad()  { echo -e "${RED}✗${NC} $1"; fail=$((fail + 1)); }
note() { echo -e "${AMBER}!${NC} $1"; warn=$((warn + 1)); }

echo "═══ AQUANAUTIX launch_beta_verify ═══"
echo ""

# ── Flutter ──────────────────────────────────────────────
if command -v flutter >/dev/null 2>&1; then
  flutter pub get >/dev/null
  if flutter analyze >/dev/null 2>&1; then
    ok "flutter analyze — 0 issues"
  else
    bad "flutter analyze — falhou"
  fi

  if [[ ! -f assets/video_bg.mp4 ]]; then
    if command -v ffmpeg >/dev/null 2>&1; then
      ffmpeg -y -f lavfi -i color=c=black:s=64x64:d=0.5 -c:v libx264 -pix_fmt yuv420p assets/video_bg.mp4 >/dev/null 2>&1 || true
    fi
  fi

  if flutter test >/dev/null 2>&1; then
    ok "flutter test — todos passam"
  else
    bad "flutter test — falhou"
  fi
else
  note "Flutter SDK não encontrado — saltar analyze/test"
fi

# ── Android manifest ─────────────────────────────────────
if grep -q 'RECORD_AUDIO' android/app/src/main/AndroidManifest.xml 2>/dev/null; then
  bad "AndroidManifest ainda declara RECORD_AUDIO"
else
  ok "AndroidManifest sem RECORD_AUDIO"
fi

if grep -q 'AQUANAUTIX' android/app/src/main/AndroidManifest.xml 2>/dev/null; then
  ok "Label launcher AQUANAUTIX"
else
  note "Label launcher não é AQUANAUTIX"
fi

# ── Legal in-app ─────────────────────────────────────────
for f in lib/core/legal/aqx_legal_urls.dart lib/core/legal/legal_document_sheet.dart; do
  if [[ -f "$f" ]]; then
    ok "Legal: $(basename "$f")"
  else
    bad "Em falta: $f"
  fi
done

# ── Supabase ─────────────────────────────────────────────
MIG_COUNT=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')
if [[ "$MIG_COUNT" -ge 15 ]]; then
  ok "Migrations SQL: $MIG_COUNT ficheiros"
else
  note "Migrations SQL: $MIG_COUNT (esperado ≥15)"
fi

for fn in revenuecat-webhook sync-subscription-tier; do
  if [[ -f "supabase/functions/$fn/index.ts" ]]; then
    ok "Edge Function: $fn"
  else
    bad "Edge Function em falta: $fn"
  fi
done

if [[ -f supabase/migrations/20260703120000_subscription_tier_sync.sql ]]; then
  ok "Migration tier sync RC"
else
  bad "Migration subscription_tier_sync em falta"
fi

# ── Monetização Flutter ────────────────────────────────────
if [[ -f lib/core/monetization/subscription_tier_sync_service.dart ]]; then
  ok "SubscriptionTierSyncService"
else
  bad "SubscriptionTierSyncService em falta"
fi

# ── Assets marketing (aviso, não bloqueia) ───────────────
MISSING_ASSETS=0
for asset in \
  assets/robalo_scanner.png \
  assets/marketing/spots/cabo_da_roca.jpg \
  assets/marketing/catches/oracle_hero_pescador.jpg; do
  if [[ ! -f "$asset" ]]; then
    MISSING_ASSETS=$((MISSING_ASSETS + 1))
  fi
done
if [[ "$MISSING_ASSETS" -eq 0 ]]; then
  ok "Assets marketing principais presentes"
else
  note "$MISSING_ASSETS assets marketing em falta (ver assets/README.md)"
fi

# ── Docs plano ───────────────────────────────────────────
if [[ -f docs/LAUNCH_BETA_PLAN.md ]]; then
  ok "docs/LAUNCH_BETA_PLAN.md"
else
  bad "Plano beta em falta"
fi

# ── P2 secrets (se .env presente) ────────────────────────
if [[ -f "$ROOT/.env" ]]; then
  if "$ROOT/tools/verify_p2_secrets.sh" >/dev/null 2>&1; then
    ok "P2 .env — chaves RC webhook presentes"
  else
    note "P2 .env — chaves em falta (corre ./tools/verify_p2_secrets.sh)"
  fi
else
  note "P2: .env ausente — secrets no PC local (AQUANAUTIX/.env)"
fi

# ── Secrets / Play (manual — só aviso) ───────────────────
echo ""
echo "── Verificações manuais (não bloqueiam script) ──"
note "P2 remoto: após .env OK → configure_p2_secrets.ps1 + webhook RC"
note "P3: Play Console + internal testing (requer pagamento)"

echo ""
echo "═══ Resultado: ${GREEN}${pass} OK${NC} · ${AMBER}${warn} avisos${NC} · ${RED}${fail} falhas${NC} ═══"

if [[ "$fail" -gt 0 ]]; then
  exit 1
fi
exit 0
