#!/usr/bin/env bash
# Carrega .env e executa Supabase CLI (paridade supabase_with_env.ps1).
# Uso:
#   ./tools/supabase_with_env.sh projects list
#   ./tools/supabase_with_env.sh link --project-ref ycmvqokcfzxkpinvcyhk
#   ./tools/supabase_with_env.sh db push --yes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/env_common.sh
source "$SCRIPT_DIR/lib/env_common.sh"

env_load_config

if [[ -n "${ENV_VALUES[SUPABASE_ACCESS_TOKEN]:-}" ]]; then
  export SUPABASE_ACCESS_TOKEN="${ENV_VALUES[SUPABASE_ACCESS_TOKEN]}"
fi

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "ERRO: SUPABASE_ACCESS_TOKEN em falta no .env" >&2
  echo "      Adiciona sbp_... ao .env (gitignored) ou: npx supabase login" >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  npx supabase --help
  exit $?
fi

cd "$ENV_REPO_ROOT"
npx supabase "$@"
