# shellcheck shell=bash
# Partilhado por tools/verify_env.sh, tools/run_dev.sh, tools/bootstrap_env_from_secrets.sh
# Manter em sync com tools/run_dev.ps1

ENV_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_REPO_ROOT}/.env"

# Chaves injectadas na app via --dart-define (run_dev.ps1)
ENV_CORE_KEYS=(
  MAPBOX_ACCESS_TOKEN
  SUPABASE_URL
  SUPABASE_ANON_KEY
  OPENAI_API_KEY
  REVENUECAT_API_KEY_ANDROID
)

ENV_RC_OPTIONAL_KEYS=(
  REVENUECAT_API_KEY_IOS
  REVENUECAT_ENTITLEMENT_PRO
  REVENUECAT_ENTITLEMENT_ELITE
  REVENUECAT_PACKAGE_PRO_MONTHLY
  REVENUECAT_PACKAGE_PRO_ANNUAL
  REVENUECAT_PACKAGE_ELITE_ANNUAL
  SUPABASE_RESET_REDIRECT
)

ENV_RC_DEFAULTS=(
  REVENUECAT_ENTITLEMENT_PRO=pro
  REVENUECAT_ENTITLEMENT_ELITE=elite
  REVENUECAT_PACKAGE_PRO_MONTHLY=pro_monthly
  REVENUECAT_PACKAGE_PRO_ANNUAL=pro_annual
  REVENUECAT_PACKAGE_ELITE_ANNUAL=elite_annual
)

ENV_SUPABASE_RESET_DEFAULT='https://aquanautix.vercel.app/reset-password'

# Só CLI — nunca dart-define
ENV_CLI_ONLY_KEYS=(
  SUPABASE_ACCESS_TOKEN
)

# Secrets Cursor / bootstrap (app + cli opcionais)
ENV_BOOTSTRAP_KEYS=(
  SUPABASE_URL
  SUPABASE_ANON_KEY
  MAPBOX_ACCESS_TOKEN
  MAPBOX_DOWNLOADS_TOKEN
  MAPBOX_DOWNLOAD_TOKEN
  OPENAI_API_KEY
  OPENAI_CHAT_MODEL
  REVENUECAT_API_KEY_ANDROID
  REVENUECAT_API_KEY_IOS
  REVENUECAT_ENTITLEMENT_PRO
  REVENUECAT_ENTITLEMENT_ELITE
  REVENUECAT_PACKAGE_PRO_MONTHLY
  REVENUECAT_PACKAGE_PRO_ANNUAL
  REVENUECAT_PACKAGE_ELITE_ANNUAL
  SUPABASE_RESET_REDIRECT
  SUPABASE_ACCESS_TOKEN
)

declare -gA ENV_VALUES=()

env_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

env_unquote() {
  local v="$1"
  v="$(env_trim "$v")"
  if [[ ( "$v" == \"*\" && "$v" == *\" ) || ( "$v" == \'*\' && "$v" == *\' ) ]]; then
    v="${v:1:${#v}-2}"
  fi
  printf '%s' "$(env_trim "$v")"
}

# Carrega .env do disco (se existir) para ENV_VALUES
env_load_dotenv_file() {
  local path="${1:-$ENV_FILE}"
  [[ -f "$path" ]] || return 0
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(env_trim "$line")"
    [[ -z "$line" ]] && continue
    [[ "$line" != *"="* ]] && continue
    key="$(env_trim "${line%%=*}")"
    val="$(env_unquote "${line#*=}")"
    [[ -n "$key" ]] && ENV_VALUES["$key"]="$val"
  done < "$path"
}

# Variáveis de ambiente sobrepõem .env (prioridade para Cloud secrets)
env_apply_process_env() {
  local k
  for k in "${ENV_CORE_KEYS[@]}" "${ENV_RC_OPTIONAL_KEYS[@]}" "${ENV_CLI_ONLY_KEYS[@]}" \
    MAPBOX_DOWNLOADS_TOKEN MAPBOX_DOWNLOAD_TOKEN OPENAI_CHAT_MODEL; do
    if [[ -n "${!k:-}" ]]; then
      ENV_VALUES["$k"]="${!k}"
    fi
  done
}

env_load_config() {
  ENV_VALUES=()
  env_load_dotenv_file "$ENV_FILE"
  env_apply_process_env
  env_apply_rc_defaults
  env_apply_supabase_reset_default
}

env_apply_rc_defaults() {
  local pair key val
  for pair in "${ENV_RC_DEFAULTS[@]}"; do
    key="${pair%%=*}"
    val="${pair#*=}"
    if [[ -z "${ENV_VALUES[$key]:-}" ]]; then
      ENV_VALUES["$key"]="$val"
    fi
  done
}

env_apply_supabase_reset_default() {
  if [[ -z "${ENV_VALUES[SUPABASE_RESET_REDIRECT]:-}" ]]; then
    ENV_VALUES[SUPABASE_RESET_REDIRECT]="$ENV_SUPABASE_RESET_DEFAULT"
  fi
}

env_export_mapbox_downloads_token() {
  local token=""
  if [[ -n "${ENV_VALUES[MAPBOX_DOWNLOADS_TOKEN]:-}" ]]; then
    token="${ENV_VALUES[MAPBOX_DOWNLOADS_TOKEN]}"
  elif [[ -n "${ENV_VALUES[MAPBOX_DOWNLOAD_TOKEN]:-}" ]]; then
    token="${ENV_VALUES[MAPBOX_DOWNLOAD_TOKEN]}"
  fi
  if [[ -n "$token" ]]; then
    export MAPBOX_DOWNLOADS_TOKEN="$token"
  fi
}

# Imprime flags --dart-define= (paridade run_dev.ps1)
env_build_dart_define_flags() {
  local k v
  for k in "${ENV_CORE_KEYS[@]}"; do
    v="${ENV_VALUES[$k]:-}"
    printf '%s\n' "--dart-define=${k}=${v}"
  done
  for k in "${ENV_RC_OPTIONAL_KEYS[@]}"; do
    v="${ENV_VALUES[$k]:-}"
    printf '%s\n' "--dart-define=${k}=${v}"
  done
}

env_has_supabase_app_config() {
  [[ -n "${ENV_VALUES[SUPABASE_URL]:-}" && -n "${ENV_VALUES[SUPABASE_ANON_KEY]:-}" ]]
}
