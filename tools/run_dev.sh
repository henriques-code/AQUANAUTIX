#!/usr/bin/env bash
# run_dev.sh — corre a app Flutter com tokens do .env ou variáveis de ambiente (--dart-define)
# Paridade com tools/run_dev.ps1 (Windows).
#
# Uso:
#   ./tools/run_dev.sh              # device por defeito do Flutter
#   ./tools/run_dev.sh -d chrome    # web (Cloud)
#   ./tools/run_dev.sh --dry-run    # lista chaves configuradas, sem valores
#
# Cloud: define secrets Cursor OU ./tools/bootstrap_env_from_secrets.sh antes de correr.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

DEVICE=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Uso: ./tools/run_dev.sh [-d DEVICE] [--dry-run]

  -d DEVICE     Dispositivo Flutter (ex.: chrome, linux)
  --dry-run     Mostra estado das chaves (sem valores) e sai
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      DEVICE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento desconhecido: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

env_load_config

if [[ $DRY_RUN -eq 1 ]]; then
  echo "▶  run_dev.sh dry-run (repo: $ENV_REPO_ROOT)"
  echo "    .env: $([[ -f "$ENV_FILE" ]] && echo presente || echo ausente)"
  echo ""
  for k in "${ENV_CORE_KEYS[@]}"; do
    if [[ -n "${ENV_VALUES[$k]:-}" ]]; then
      echo "  OK   $k"
    else
      echo "  VAZIO $k"
    fi
  done
  if env_has_supabase_app_config; then
    echo ""
    echo "  Supabase app: configurado"
  else
    echo ""
    echo "  Supabase app: NÃO configurado (Início pode falhar)"
  fi
  exit 0
fi

if [[ ! -f "$ENV_FILE" ]] && ! env_has_supabase_app_config; then
  echo "AVISO: sem .env e sem SUPABASE_* no ambiente — modo limitado." >&2
  echo "       Cloud: secrets Cursor ou ./tools/bootstrap_env_from_secrets.sh" >&2
fi

mapfile -t DART_DEFINES < <(env_build_dart_define_flags)
env_export_mapbox_downloads_token

cd "$ENV_REPO_ROOT"

echo "▶  flutter run ${DEVICE:+-d $DEVICE }[+ dart-defines]" >&2

if [[ -n "$DEVICE" ]]; then
  exec flutter run -d "$DEVICE" "${DART_DEFINES[@]}"
else
  exec flutter run "${DART_DEFINES[@]}"
fi
