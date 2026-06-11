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

---

## 1. Google Play Console — Criar produtos de subscrição

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

## Variáveis `.env` completas (referência)

```
# Supabase
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...

# Mapbox
MAPBOX_ACCESS_TOKEN=pk.ey...
MAPBOX_DOWNLOADS_TOKEN=sk.ey...

# OpenAI
OPENAI_API_KEY=sk-...

# RevenueCat
REVENUECAT_API_KEY_ANDROID=goog_...
REVENUECAT_API_KEY_IOS=appl_...
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
