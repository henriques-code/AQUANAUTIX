# AQUANAUTIX — Handoff para novo chat

> Copia este ficheiro (ou a secção «Prompt rápido») para iniciar um chat Cursor/Claude com contexto completo.
> **Última actualização:** 16 Jun 2026 · commit `49107bf` · branch `main` = `origin/main` (PR #5 merged)

---

## Prompt rápido (colar no chat)

```
És o engenheiro principal da app Flutter AQUANAUTIX (mono-repo). Responde em português de Portugal. Diagnóstico antes de mudanças grandes. Diff mínimo.

Repo: C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX · branch main · último commit 49107bf

ESCOPO
- App Flutter (lib/, pubspec, android/, assets/): ✅ foco principal
- Supabase (supabase/migrations/): ✅ 9 migrations versionadas; pendente db push remoto · rate limits · Edge Functions
- Site V2/: ❌ NÃO MEXER sem AUTORIZO explícito (produção aquanautix.vercel.app)
- Design/UI: ❌ NÃO MEXER sem AUTORIZO explícito
- Secrets: .env + tools/local_secrets.ps1 (nunca commitar sk_, ghp_, sbp_)

STACK (verificar no código — não confiar só neste prompt)
- lib/screens/ + lib/core/ + lib/features/home/ + lib/features/community/
- Mapa: flutter_map (ArcGIS/OSM/OpenSeaMap) — Mapbox SDK só bootstrap token, NÃO rendering (MIUI)
- Oráculo: Open-Meteo + Nominatim em lib/core/tides/ · pesquisa local (planeamento) OK
- Auth: Supabase + Google Sign-In (com.aquanautix.app)
- Monetização: RevenueCat parcial · trial 3 dias PRO local (SubscriptionStore)

NAVEGAÇÃO: 7 tabs lazy — Início(0) · Oráculo(1) · Mapa(2) · Vision(3) · Log(4) · Perfil(5) · Comunidade(6)
- home.dart: _tabCache (só tab activa montada) — NÃO usar IndexedStack com 7 ecrãs (bloqueia MIUI)
- Tab COMUN.: lib/screens/comunidade.dart
- GpsBootstrap.ensurePermission() no 1.º frame após login
- GPS: banner inline no Início se recusar; pull-to-refresh = fix GPS 12s → invalidate Oráculo → reload

DISPOSITIVO TESTE: WWZLYDXWYXT8PV5D (Xiaomi 22031116BG, Android 13)
  .\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
  flutter analyze
  MIUI install bloqueado → build apk + adb push + pm install + --use-application-binary (ver HANDOFF.md)

INÍCIO (lib/features/home/)
- loadDashboard(forceRefresh) · knownCoords no OracleDataService.fetch
- Tap spot → pendingMapFocus · tap comunidade → pendingCommunityProfile + tab 6 + sheet Ghost

ORÁCULO (lib/screens/oraculo.dart) — estado actual Jun 2026
- OracleDecisaoFold: hero oracle_hero_pescador.jpg · score pulse · janela âmbar · mini-mapa
- oracle_conversion_pack.dart: linha decisão · faixa PRO sticky · drawer «PRO 3 dias grátis» → PaywallScreen
- Espécie alvo chips · CTAs IR PESCAR / REGISTAR CAPTURA · GHOST 2 cards · card spot PRO
- OracleConditionsFold colapsável (meteorologia 16 cartões abaixo)
- Mini-mapa blur + cadeado FREE · CTAs «Comparar 3 sítios (PRO)» / «Alertar janela (PRO) · EM BREVE»
- Widgets: oracle_decisao_fold, oracle_hero_decision, oracle_conversion_pack, oracle_pro_spot_teaser, oracle_community_photo_row, oracle_conditions_collapsible, oracle_conditions_fold, oracle_weather_details_grid
- Evitar flutter_animate + IntrinsicHeight em SingleChildScrollView (ecrã preto MIUI)

SUPABASE
- Projecto: ycmvqokcfzxkpinvcyhk.supabase.co
- Guia: supabase/README_setup.md
- Deploy: supabase link --project-ref ycmvqokcfzxkpinvcyhk && supabase db push
- Nova migration local: 20260616174757_storage_no_public_listing.sql (sem listagem pública buckets)

DOCS: AQUANAUTIX_CONTEXT.md · CLAUDE.md · README.md · ECOSYSTEM.md · SYNC_WORKFLOW.md · HANDOFF.md
BACKLOG PRODUTO: .cursor/rules/proximos-movimentos.mdc (P1–P17)

PENDENTE P0/P1
1. RevenueCat — produtos PRO/ELITE no dashboard + gates reais
2. supabase db push (9 migrations)
3. Onboarding — ligar onboarding.dart ao arranque (1.ª vez)
4. Push Janela de Ouro (P5) — backend; UI já tem EM BREVE
5. Sprint C — manifest spots · renomear cabo_da_roca.jpg → cabo_espichel.jpg

TAREFA DESTE CHAT:
[DESCREVER AQUI]
```

---

## Commits recentes (referência)

| Commit | Descrição |
|--------|-----------|
| `49107bf` | feat(oraculo): mockup Decisão + pack PRO + docs + security (PR #5 squash merge) |
| `98e1952` | feat(oraculo): layout mockup Decisão — hero pescador, fold CTAs |
| `cc359ab` | chore(security): gitignore + pre-commit contra PAT GitHub |
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
| Oráculo | `lib/screens/oraculo.dart`, `widgets/oracle_decisao_fold.dart`, `oracle_conversion_pack.dart`, `oracle_hero_decision.dart`, `oracle_conditions_fold.dart`, `oracle_weather_details_grid.dart` |
| GPS | `lib/core/location/gps_access.dart`, `gps_bootstrap.dart`, `widgets/location_access_sheet.dart` |
| Dados | `lib/core/tides/oracle_data_service.dart`, `oracle_hourly_score.dart` |
| Mapa | `lib/screens/mapa.dart` |
| Supabase app | `lib/core/supabase_bootstrap.dart`, `community/`, `catch_photos/` |
| Supabase repo | `supabase/migrations/` (9 ficheiros), `supabase/README_setup.md` |

---

## Sincronização ecossistema (16 Jun 2026)

| Componente | Estado |
|------------|--------|
| App Flutter `lib/` | ✅ `49107bf` |
| GitHub `main` | ✅ PR #5 merged · squash |
| Docs (CONTEXT, CLAUDE, HANDOFF, ECOSYSTEM, README) | ✅ alinhados nesta revisão |
| Site V2 produção | ⏸️ Sem alterações (AUTORIZO) |
| Supabase remoto | ⚠️ Correr `supabase db push` (9 migrations; nova: storage no public listing) |
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
flutter build apk --debug
adb push build\app\outputs\flutter-apk\app-debug.apk /data/local/tmp/app-debug.apk
adb shell pm install -r -t /data/local/tmp/app-debug.apk
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D -- --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
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
