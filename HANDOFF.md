# AQUANAUTIX — Handoff para novo chat

> Copia este ficheiro (ou a secção «Prompt rápido») para iniciar um chat Cursor/Claude com contexto completo.
> **Última actualização:** 18 Jun 2026 · branches `feat/mapa-camadas-v1` + `feat/oracle-p3-bait-technique` · PRs pendentes merge → main

---

## Prompt rápido (colar no chat)

```
És o engenheiro principal da app Flutter AQUANAUTIX (mono-repo). Responde em português de Portugal. Diagnóstico antes de mudanças grandes. Diff mínimo.

Repo: C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX · branch feat/oracle-p3-bait-technique · último commit 4f355b7

ESCOPO
- App Flutter (lib/, pubspec, android/, assets/): ✅ foco principal
- Supabase (supabase/migrations/): ✅ 13 migrations aplicadas (fishing_spots + bait_shops com PostGIS + seed PT/ES)
- Site V2/: ❌ NÃO MEXER sem AUTORIZO explícito (produção aquanautix.vercel.app)
- Design/UI: ❌ NÃO MEXER sem AUTORIZO explícito
- Secrets: .env + tools/local_secrets.ps1 (nunca commitar sk_, ghp_, sbp_)

STACK (verificar no código — não confiar só neste prompt)
- lib/screens/ + lib/core/ + lib/features/home/ + lib/features/community/
- Mapa: flutter_map (ArcGIS/OSM/OpenSeaMap) — Mapbox SDK só bootstrap token, NÃO rendering (MIUI)
  → Camadas V1: batimetria GEBCO, regulamentos GeoJSON, heatmap comunidade, filtro espécies, lojas dinâmicas
- Oráculo: Open-Meteo + Nominatim em lib/core/tides/ · pesquisa local (planeamento) OK
  → Card ISCO+TÉCNICA: BaitTechniqueService (10 espécies, confiança por mês/habitat/maré)
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
- Card ISCO+TÉCNICA (P3): entre DecisaoFold e ConditionsFold; usa BaitTechniqueService; oculto se espécie vazia
- OracleConditionsFold colapsável (meteorologia 16 cartões abaixo)
- Mini-mapa blur + cadeado FREE · CTAs «Comparar 3 sítios (PRO)» / «Alertar janela (PRO) · EM BREVE»
- Widgets: oracle_decisao_fold, oracle_hero_decision, oracle_conversion_pack, oracle_pro_spot_teaser, oracle_community_photo_row, oracle_conditions_collapsible, oracle_conditions_fold, oracle_weather_details_grid
- Evitar flutter_animate + IntrinsicHeight em SingleChildScrollView (ecrã preto MIUI)

SUPABASE
- Projecto: ycmvqokcfzxkpinvcyhk.supabase.co
- Guia: supabase/README_setup.md
- 13 migrations aplicadas local=remoto (verificado sync_check.ps1 18 Jun 2026)
- Tabelas novas: fishing_spots (PostGIS, RLS FREE/PRO/ELITE, 5 spots seed), bait_shops (PostGIS, RLS pública, 55 lojas PT/ES)

DOCS: AQUANAUTIX_CONTEXT.md · CLAUDE.md · README.md · ECOSYSTEM.md · SYNC_WORKFLOW.md · HANDOFF.md
BACKLOG PRODUTO: .cursor/rules/proximos-movimentos.mdc (P1–P17)

PENDENTE P0/P1
1. Merge PRs → main: feat/mapa-camadas-v1 + feat/oracle-p3-bait-technique (ambos em review no GitHub)
2. RevenueCat — produtos PRO/ELITE no dashboard + gates reais
3. P4 Blur Mapa — spots PRO/ELITE desfocados + cadeado (FOMO visual FREE→PRO)
4. Onboarding — ligar onboarding.dart ao arranque (1.ª vez)
5. Push Janela de Ouro (P5) — backend; UI já tem EM BREVE

TAREFA DESTE CHAT:
[DESCREVER AQUI]
```

---

## Commits recentes (referência)

| Commit | Branch | Descrição |
|--------|--------|-----------|
| `4f355b7` | feat/oracle-p3-bait-technique | feat(mapa): P7 lojas de isco dinâmicas via Supabase |
| `f0674ae` | feat/oracle-p3-bait-technique | feat(oraculo): P3 card isco+técnica por espécie alvo |
| `1bfbe09` | feat/mapa-camadas-v1 | feat(mapa): camadas V1 — batimetria, regulamentos, heatmap, filtro espécies |
| `0c72e84` | feat/fishing-spots-oracle-rig | feat: fishing spots Supabase, rig Oracle P3 e polish monetização/UI |
| `49107bf` | main | feat(oraculo): mockup Decisão + pack PRO + docs + security (PR #5) |

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
| Mapa | `lib/screens/mapa.dart`, `lib/core/spots/fishing_spot*.dart`, `lib/core/spots/bait_shop*.dart`, `lib/core/regulations/fishing_regulation_zone.dart`, `lib/core/community/community_heatmap_repository.dart` |
| Oráculo P3 | `lib/core/fishing/bait_technique_service.dart` |
| Supabase app | `lib/core/supabase_bootstrap.dart`, `community/`, `catch_photos/` |
| Supabase repo | `supabase/migrations/` (13 ficheiros), `supabase/README_setup.md` |
| Assets dados | `assets/data/fishing_regulations_pt_es.geojson` |

---

## Sincronização ecossistema (18 Jun 2026)

| Componente | Estado |
|------------|--------|
| App Flutter `lib/` | ✅ `4f355b7` (feat/oracle-p3-bait-technique) |
| GitHub branches | ✅ feat/mapa-camadas-v1 + feat/oracle-p3-bait-technique pushed |
| GitHub `main` | ⚠️ 2 PRs pendentes de merge (mapa-camadas-v1 + oracle-p3-bait-technique) |
| Docs (CONTEXT, HANDOFF) | ✅ actualizados 18 Jun 2026 |
| Site V2 produção | ⏸️ Sem alterações (AUTORIZO) |
| Supabase remoto | ✅ 13 migrations local=remoto · fishing_spots + bait_shops aplicados |
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

1. **Merge PRs** — feat/mapa-camadas-v1 + feat/oracle-p3-bait-technique → main
2. **P4 Blur Mapa** — spots PRO/ELITE desfocados + cadeado FREE (FOMO visual)
3. **P0 RevenueCat** — produtos PRO/ELITE + gates reais (`REVENUECAT_SETUP.md`)
4. **Onboarding** — ligar `onboarding.dart` ao arranque (primeira vez)
5. **P5 Push Janela de Ouro** — backend + permissões (UI EM BREVE)
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
