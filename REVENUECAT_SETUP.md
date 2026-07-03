# RevenueCat — Guia de Configuração Completa

**Estado:** SDK integrado · auth bridge Supabase↔RC · produtos por publicar no Play Console

---

## Checklist P0 (código ✅ · dashboard manual)

| Item | Estado |
|------|--------|
| `RevenueCatService.configure()` no arranque | ✅ |
| `SubscriptionStore.syncFromRevenueCat()` + listener | ✅ |
| `SubscriptionAuthBridge` — `logIn`/`logOut` Supabase | ✅ |
| Paywall — resolve package por ID + fallback `PackageType` | ✅ |
| Trial 3 dias — local (`startTrialIfNeeded`), sem compra forçada | ✅ |
| Restauro — `hasProEntitlement` (inclui trial) | ✅ |
| Bypass local (`_activateLocal`) só em `kDebugMode` | ✅ |
| Perfil FREE manual só em `kDebugMode` | ✅ |
| `run_dev.ps1` — defaults package IDs | ✅ |
| Produtos Play Console + Offering RC publicada | ⏳ manual |
| Gates dinâmicos (`SubscriptionGate`) — mapa/vision/log | ✅ |
| Script `tools/verify_revenuecat.ps1` | ✅ |

---

## 1. Google Play Console — Criar produtos de subscrição

**Guia completo passo-a-passo:** [`tools/PLAY_CONSOLE_SETUP.md`](tools/PLAY_CONSOLE_SETUP.md)

Em [play.google.com/console](https://play.google.com/console) → app `com.aquanautix.app` → Monetização → Produtos → Subscrições:

| Product ID | Nome | Preço | Período |
|------------|------|-------|---------|
| `aquanautix_pro_monthly` | AQUANAUTIX PRO Mensal | €4.99 | Mensal |
| `aquanautix_pro_annual` | AQUANAUTIX PRO Anual | €39.99 | Anual |
| `aquanautix_elite_annual` | AQUANAUTIX ELITE Anual | €59.99 | Anual |

**Trial:** configurar 3 dias de trial gratuito em cada produto PRO.

---

## 2. RevenueCat Dashboard — Entitlements

Em [app.revenuecat.com](https://app.revenuecat.com) → projecto AQUANAUTIX → Entitlements:

| Identifier | Descrição |
|-----------|-----------|
| `pro` | Acesso PRO (Vision, Oráculo avançado, Logbook completo) |
| `elite` | Acesso ELITE (tudo PRO + spots premium + IA ilimitada) |

---

## 3. RevenueCat Dashboard — Products

Entitlements → Products → Add:

| Store Product ID | Entitlement |
|-----------------|-------------|
| `aquanautix_pro_monthly` | `pro` |
| `aquanautix_pro_annual` | `pro` |
| `aquanautix_elite_annual` | `elite` |

---

## 4. RevenueCat Dashboard — Offering

Offerings → New Offering → identifier: `default`

Packages a criar dentro da offering:

| Package Identifier | Product | Tipo |
|-------------------|---------|------|
| `pro_monthly` | `aquanautix_pro_monthly` | Monthly |
| `pro_annual` | `aquanautix_pro_annual` | Annual |
| `elite_annual` | `aquanautix_elite_annual` | Annual |

---

## 5. Actualizar `.env` local

Após criar os packages, adicionar ao `.env`:

```
REVENUECAT_PACKAGE_PRO_MONTHLY=pro_monthly
REVENUECAT_PACKAGE_PRO_ANNUAL=pro_annual
REVENUECAT_PACKAGE_ELITE_ANNUAL=elite_annual
```

O `run_dev.ps1` já passa estes valores automaticamente via `--dart-define`.

---

## 6. Verificar integração

```powershell
# Correr em modo debug com RC configurado
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
```

Verificar no logcat (RC debug mode activo em kDebugMode):
- `[Purchases] - DEBUG` → SDK inicializado
- Offerings carregadas com 3 packages
- Trial 3 dias disponível

---

## 7. Gates na app (automático após compra/restauro)

| Recurso | Regra |
|---------|--------|
| Spots PRO no mapa | `hasProEntitlement` (PRO, ELITE ou trial 3d) |
| Spots ELITE | plano `elite` |
| Vision (limite FREE) | `hasProEntitlement` |
| Alertas Início | `hasProEntitlement` |
| Comunidade/Logbook locked | paywall até PRO |

Após compra ou **Restaurar compras**, `SubscriptionStore.syncFromRevenueCat()` actualiza gates sem reiniciar a app.

---

## 8. Webhook RevenueCat → `user_profiles.tier` (Supabase)

O RLS de `fishing_spots` cruza `user_profiles.tier`. A app chama `RevenueCat.logIn(supabaseUserId)` — o webhook e a Edge Function mantêm o tier alinhado.

### 8.1 Edge Functions (repo)

| Função | JWT | Papel |
|--------|-----|--------|
| `revenuecat-webhook` | ❌ | POST do dashboard RC → consulta API RC → `sync_user_subscription_tier` |
| `sync-subscription-tier` | ✅ | App autenticada → sync imediato pós-compra |

### 8.2 Secrets Supabase (Dashboard → Edge Functions → Secrets)

| Secret | Origem no `.env` local |
|--------|------------------------|
| `REVENUECAT_SECRET_API_KEY` | RevenueCat → Project → API keys → **Secret** (`sk_...`) |
| `REVENUECAT_WEBHOOK_AUTHORIZATION` | String aleatória longa (ex. `Bearer aquanautix-rc-wh-...`) |
| `REVENUECAT_ENTITLEMENT_PRO` | `pro` (opcional, default) |
| `REVENUECAT_ENTITLEMENT_ELITE` | `elite` (opcional, default) |

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` são injectados automaticamente pelo Supabase.

**Automatizar a partir do `.env` (recomendado — Windows):**

```powershell
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"
.\tools\verify_p2_secrets.ps1      # audita chaves sem expor valores
.\tools\configure_p2_secrets.ps1   # supabase secrets set (usa SUPABASE_ACCESS_TOKEN do .env)
```

Linux / Cloud Agent:

```bash
./tools/verify_p2_secrets.sh
./tools/configure_p2_secrets.sh
```

O `.env` na raiz do repo contém **todas** as chaves — nunca versionar. Ver também `SUPABASE_ACCESS_TOKEN=sbp_...` para o CLI.

### 8.3 Configurar webhook no RevenueCat

1. [app.revenuecat.com](https://app.revenuecat.com) → Project → **Integrations** → **Webhooks**
2. URL: `https://ycmvqokcfzxkpinvcyhk.supabase.co/functions/v1/revenuecat-webhook`
3. **Authorization header:** mesmo valor que `REVENUECAT_WEBHOOK_AUTHORIZATION`
4. Eventos: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`, `UNCANCELLATION`, `BILLING_ISSUE`
5. Ambiente: Production + Sandbox (testes)

### 8.4 Fluxo na app

1. Login Supabase → `SubscriptionAuthBridge` → `RC.logIn(userId)` → `sync-subscription-tier`
2. Compra / restauro → `SubscriptionStore.syncFromRevenueCat()` → `sync-subscription-tier`
3. Renovação / expiração → webhook RC → `revenuecat-webhook`

### 8.5 Migration SQL

`supabase/migrations/20260703120000_subscription_tier_sync.sql` — função `public.sync_user_subscription_tier` (só `service_role`).

---

## Variáveis `.env` completas (referência)

```
# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...

# CLI Supabase (só local — nunca dart-define)
SUPABASE_ACCESS_TOKEN=sbp_...

# Mapbox
MAPBOX_ACCESS_TOKEN=pk.ey...
MAPBOX_DOWNLOADS_TOKEN=sk.ey...

# OpenAI
OPENAI_API_KEY=sk-...

# RevenueCat
REVENUECAT_API_KEY_ANDROID=goog_...
REVENUECAT_API_KEY_IOS=appl_...
REVENUECAT_SECRET_API_KEY=sk_...          # só Edge Functions / CLI — nunca na app
REVENUECAT_WEBHOOK_AUTHORIZATION=Bearer ... # header webhook RC + secret Supabase
REVENUECAT_ENTITLEMENT_PRO=pro
REVENUECAT_ENTITLEMENT_ELITE=elite
REVENUECAT_PACKAGE_PRO_MONTHLY=pro_monthly
REVENUECAT_PACKAGE_PRO_ANNUAL=pro_annual
REVENUECAT_PACKAGE_ELITE_ANNUAL=elite_annual
```

---

## Nota importante

O código já funciona em **modo local** (sem RC configurado):
- Em debug: `_activateLocal()` simula compra/trial sem passar pela loja
- Gates de PRO respondem ao `SubscriptionStore` local
- Quando RC estiver configurado no dashboard, basta fornecer as API keys e os packages — sem tocar no código
