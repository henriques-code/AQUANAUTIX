# AQUANAUTIX — Handoff para novo chat

> Copia este ficheiro (ou a secção «Prompt rápido») para iniciar um chat Cursor/Claude com contexto completo.
> **Última actualização:** 9 Jun 2026 · commit `425df2e`

---

## Prompt rápido (colar no chat)

```
És o engenheiro principal da app Flutter AQUANAUTIX (mono-repo). Responde em português de Portugal. Diagnóstico antes de mudanças grandes. Diff mínimo.

Repo: C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX · branch main · último commit 425df2e

ESCOPO
- App Flutter (lib/, pubspec, android/, assets/): ✅ foco principal
- Supabase (supabase/migrations/): ✅ migrations versionadas; pendente rate limits + Edge Functions
- Site V2/: ❌ NÃO MEXER sem AUTORIZO explícito
- Design/UI: ❌ NÃO MEXER sem AUTORIZO explícito
- Secrets: .env + tools/local_secrets.ps1 (nunca commitar sk_)

STACK (verificar no código)
- lib/screens/ + lib/core/ + lib/features/home/ · StatefulWidget + ValueNotifier
- Mapa: flutter_map (ArcGIS/OSM/OpenSeaMap) — Mapbox SDK só bootstrap, NÃO rendering (MIUI)
- Oráculo: Open-Meteo + Nominatim em lib/core/tides/ · pesquisa local (planeamento) OK
- Auth: Supabase + Google Sign-In (com.aquanautix.app)
- Monetização: RevenueCat parcial · trial 3 dias PRO local (SubscriptionStore)

NAVEGAÇÃO: 6 tabs — Início · Oráculo · Mapa · Vision · Log · Perfil
- home.dart: tabs LAZY (_tabCache) — NÃO usar IndexedStack com 6 ecrãs (bloqueia MIUI)
- Sem modal GPS automático ao login — banner inline no Início

DISPOSITIVO TESTE: WWZLYDXWYXT8PV5D (Xiaomi Android 13)
  .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
  flutter analyze

ORÁCULO (estado actual)
- OracleConditionsFold (métricas + timeline 12h)
- Selector espécie no card isco/cana · CTAs Log/Mapa (pendingMapFocus)
- Evitar flutter_animate + IntrinsicHeight em SingleChildScrollView (ecrã preto)

SUPABASE
- Pasta supabase/ versionada · guia: supabase/README_setup.md
- Deploy: supabase link --project-ref ycmvqokcfzxkpinvcyhk && supabase db push
- Pendente: rate limits, Edge Functions (oracle, vision-identify, market-*)

DOCS: AQUANAUTIX_CONTEXT.md · CLAUDE.md · README.md · ECOSYSTEM.md
BACKLOG: .cursor/rules/proximos-movimentos.mdc (P1–P17)

PENDENTE P0/P1: RevenueCat produtos/gates · onboarding.dart · migrations remotas · push Janela de Ouro

TAREFA DESTE CHAT:
[DESCREVER AQUI]
```

---

## Commits recentes (referência)

| Commit | Descrição |
|--------|-----------|
| `425df2e` | docs + Supabase (analytics_events, config.toml, contexto MIUI) |
| `678ff0f` | fix(app): desbloquear Início e Oráculo após login no MIUI |
| `3217a4d` | feat(oraculo): fold condições 12h, GPS, CTAs, logbook |
| `e81633c` | refactor(oraculo): selector espécie no card isco/cana |
| `f39cd26` | feat(oraculo): botões 3D mix A+B |

---

## Fix MIUI — não reverter

**Sintoma:** Início/Oráculo renderizavam mas não respondiam a toques; Oráculo ecrã preto.

**Causas corrigidas:**
- `showModalBottomSheet` GPS → barrier modal invisível
- `IndexedStack` com 6 tabs → sobrecarga MIUI
- `flutter_animate` + `IntrinsicHeight` em scroll → `RenderBox was not laid out`

**Solução actual:**
- `home.dart` → `_tabCache` (lazy, uma tab de cada vez)
- GPS → banner inline no Início (dismissível), não modal automático
- `oraculo.dart` → alturas fixas, sem animate em scroll, init em `postFrameCallback`
- `gps_access.dart` → cache, `tryGetFixQuick()`, fallback stale/regional

---

## Ficheiros-chave

| Área | Ficheiros |
|------|-----------|
| Shell / tabs | `lib/screens/home.dart`, `lib/core/state/home_tab_index.dart` |
| Início | `lib/features/home/presentation/inicio_dashboard_screen.dart`, `home_repository_impl.dart` |
| Oráculo | `lib/screens/oraculo.dart`, `widgets/oracle_conditions_fold.dart`, `oracle_weather_details_grid.dart` |
| GPS | `lib/core/location/gps_access.dart`, `widgets/location_access_sheet.dart` |
| Dados | `lib/core/tides/oracle_data_service.dart`, `oracle_hourly_score.dart` |
| Mapa | `lib/screens/mapa.dart` |
| Supabase app | `lib/core/supabase_bootstrap.dart`, `community/`, `catch_photos/` |
| Supabase repo | `supabase/migrations/`, `supabase/README_setup.md` |

---

## Comandos frequentes

```powershell
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"

# App com env
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D

# Análise
flutter analyze

# Supabase (CLI instalada + login)
supabase link --project-ref ycmvqokcfzxkpinvcyhk
supabase db push

# Install MIUI bloqueado
adb push build\app\outputs\flutter-apk\app-debug.apk /data/local/tmp/app-debug.apk
adb shell pm install -r -t /data/local/tmp/app-debug.apk
```

---

## Backlog prioritário (produto)

1. **P0 RevenueCat** — produtos PRO/ELITE + gates reais (`REVENUECAT_SETUP.md`)
2. **Onboarding** — ligar `onboarding.dart` ao arranque (primeira vez)
3. **Supabase remoto** — `db push`; adicionar rate limits + Edge Functions ao repo
4. **P5 Push Janela de Ouro** — backend + permissões (UI EM BREVE)
5. Domínio `aquanautix.app` → Vercel

Ver lista completa: `.cursor/rules/proximos-movimentos.mdc`

---

## Regras permanentes

- Não alterar **Site V2** nem **design/UI** sem AUTORIZO explícito
- Não commitar/push sem pedido explícito
- Após alterações Flutter: `flutter analyze`
- Spots: Ghost Mode — nunca coordenadas exactas em público
- RevenueCat mobile: SDK keys públicas (`goog_` / `appl_`), nunca `sk_`

---

*Tarefa deste chat → preencher na secção «Prompt rápido» antes de colar.*
