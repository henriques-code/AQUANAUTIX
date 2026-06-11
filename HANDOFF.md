# AQUANAUTIX — Handoff para novo chat

> Copia este ficheiro (ou a secção «Prompt rápido») para iniciar um chat Cursor/Claude com contexto completo.
> **Última actualização:** 11 Jun 2026 · commit `da3ca79` · branch `main` = `origin/main`

---

## Prompt rápido (colar no chat)

```
És o engenheiro principal da app Flutter AQUANAUTIX (mono-repo). Responde em português de Portugal. Diagnóstico antes de mudanças grandes. Diff mínimo.

Repo: C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX · branch main · último commit da3ca79

ESCOPO
- App Flutter (lib/, pubspec, android/, assets/): ✅ foco principal
- Supabase (supabase/migrations/): ✅ 8 migrations versionadas; pendente rate limits + Edge Functions
- Site V2/: ❌ NÃO MEXER sem AUTORIZO explícito (produção aquanautix.vercel.app inalterada)
- Design/UI: ❌ NÃO MEXER sem AUTORIZO explícito
- Secrets: .env + tools/local_secrets.ps1 (nunca commitar sk_)

STACK (verificar no código)
- lib/screens/ + lib/core/ + lib/features/home/ + lib/features/community/
- Mapa: flutter_map (ArcGIS/OSM/OpenSeaMap) — Mapbox SDK só bootstrap token, NÃO rendering (MIUI)
- Oráculo: Open-Meteo + Nominatim em lib/core/tides/ · pesquisa local (planeamento) OK
- Auth: Supabase + Google Sign-In (com.aquanautix.app)
- Monetização: RevenueCat parcial · trial 3 dias PRO local (SubscriptionStore)

NAVEGAÇÃO: 7 tabs lazy — Início(0) · Oráculo(1) · Mapa(2) · Vision(3) · Log(4) · Perfil(5) · Comunidade(6)
- home.dart: _tabCache (uma tab de cada vez) — NÃO usar IndexedStack com 7 ecrãs (bloqueia MIUI)
- Tab COMUN.: lib/screens/comunidade.dart · label aqx_l10n.tabCommunity
- GpsBootstrap.ensurePermission() no 1.º frame após login
- GPS: banner inline no Início se recusar; pull-to-refresh = fix GPS 12s → invalidate Oráculo → reload

DISPOSITIVO TESTE: WWZLYDXWYXT8PV5D (Xiaomi Android 13)
  .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
  flutter analyze

INÍCIO
- loadDashboard(forceRefresh) · knownCoords no OracleDataService.fetch
- Tap spot → pendingMapFocus · tap comunidade → pendingCommunityProfile + tab 6 + sheet Ghost

ORÁCULO
- OracleConditionsFold · CTAs Log/Mapa/Comunidade (tab 6, não Logbook)
- Evitar flutter_animate + IntrinsicHeight em SingleChildScrollView (ecrã preto)

SUPABASE
- Guia: supabase/README_setup.md
- Deploy: supabase link --project-ref ycmvqokcfzxkpinvcyhk && supabase db push
- Pendente remoto: confirmar db push · rate limits · Edge Functions (oracle, vision-identify)

DOCS: AQUANAUTIX_CONTEXT.md · CLAUDE.md · README.md · ECOSYSTEM.md · HANDOFF.md
BACKLOG: .cursor/rules/proximos-movimentos.mdc (P1–P17)

PENDENTE P0/P1: RevenueCat produtos/gates · onboarding.dart · push Janela de Ouro · Sprint C assets spots

TAREFA DESTE CHAT:
[DESCREVER AQUI]
```

---

## Commits recentes (referência)

| Commit | Descrição |
|--------|-----------|
| `da3ca79` | feat(app): tab Comunidade, perfil Ghost, GPS MIUI pull-to-refresh |
| `7773a3c` | feat(home): tap username comunidade (base navegação) |
| `e7a276b` | fix(home): GPS Início, maré MSL, spots→mapa, Cabo Espichel |
| `b571b12` | feat(i18n): selector PT/ES/EN no login |
| `8cdeb64` | feat(app): Ghost badge, mini-mapa Oráculo, fixes MIUI |

---

## Fix MIUI — não reverter

**Sintoma:** Início/Oráculo renderizavam mas não respondiam a toques; Oráculo ecrã preto; refresh sem efeito.

**Causas corrigidas:**
- `showModalBottomSheet` GPS → barrier modal invisível
- `IndexedStack` com múltiplos tabs → sobrecarga MIUI (substituído por `_tabCache`)
- `flutter_animate` + `IntrinsicHeight` em scroll → `RenderBox was not laid out`
- Pull-to-refresh carregava dados antes do GPS e reutilizava cache Oráculo

**Solução actual:**
- `home.dart` → `_tabCache` lazy (7 tabs); `FittedBox` nos labels da nav
- `gps_bootstrap.dart` + `gps_access.dart` → `forceLocationManager`, `forceRefresh`, retry accuracy
- `inicio_dashboard_screen.dart` → pull-to-refresh: GPS primeiro, depois `loadDashboard(forceRefresh: true)`
- `home_repository_impl.dart` → obtém fix dentro do load; invalida Oráculo no refresh
- `oraculo.dart` → alturas fixas, init em `postFrameCallback`

---

## Ficheiros-chave

| Área | Ficheiros |
|------|-----------|
| Shell / tabs | `lib/screens/home.dart`, `lib/core/state/home_tab_index.dart` |
| Início | `lib/features/home/presentation/inicio_dashboard_screen.dart`, `home_repository_impl.dart` |
| Comunidade | `lib/screens/comunidade.dart`, `lib/features/community/presentation/community_ghost_profile_sheet.dart`, `lib/core/community/community_public_profile.dart` |
| Oráculo | `lib/screens/oraculo.dart`, `widgets/oracle_conditions_fold.dart`, `oracle_weather_details_grid.dart` |
| GPS | `lib/core/location/gps_access.dart`, `gps_bootstrap.dart`, `widgets/location_access_sheet.dart` |
| Dados | `lib/core/tides/oracle_data_service.dart`, `oracle_hourly_score.dart` |
| Mapa | `lib/screens/mapa.dart` |
| Supabase app | `lib/core/supabase_bootstrap.dart`, `community/`, `catch_photos/` |
| Supabase repo | `supabase/migrations/` (8 ficheiros), `supabase/README_setup.md` |

---

## Sincronização ecossistema (11 Jun 2026)

| Componente | Estado |
|------------|--------|
| App Flutter `lib/` | ✅ `da3ca79` |
| GitHub `main` | ✅ push feito |
| Docs (CONTEXT, CLAUDE, HANDOFF, ECOSYSTEM, README) | ✅ alinhados nesta revisão |
| Site V2 produção | ⏸️ Sem alterações (AUTORIZO) — protótipos ainda 5/6 ecrãs |
| Supabase remoto | ⚠️ Correr `supabase db push` para aplicar 8 migrations |
| Edge Functions | ❌ Não versionadas no repo |
| RevenueCat / Lojas | 🔄 Parcial |

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
2. **Supabase remoto** — `db push`; rate limits + Edge Functions no repo
3. **Onboarding** — ligar `onboarding.dart` ao arranque (primeira vez)
4. **P5 Push Janela de Ouro** — backend + permissões (UI EM BREVE)
5. **Sprint C** — manifest spots, renomear `cabo_da_roca.jpg` → `cabo_espichel.jpg`
6. Domínio `aquanautix.app` → Vercel

Ver lista completa: `.cursor/rules/proximos-movimentos.mdc`

---

## Regras permanentes

- Não alterar **Site V2** nem **design/UI** sem AUTORIZO explícito
- Após alterações Flutter: `flutter analyze`
- Spots: Ghost Mode — nunca coordenadas exactas em público
- RevenueCat mobile: SDK keys públicas (`goog_` / `appl_`), nunca `sk_`

---

*Tarefa deste chat → preencher na secção «Prompt rápido» antes de colar.*
