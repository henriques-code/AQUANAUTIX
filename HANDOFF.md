# AQUANAUTIX — Handoff para novo chat

> Copia este ficheiro (ou a secção «Prompt rápido») para iniciar um chat Cursor/Claude com contexto completo.
> **Última actualização:** 25 Jun 2026 · branch `feat/p5-golden-window-push` · 3 commits à frente de `main`

---

## Prompt rápido (colar no chat)

```
És o engenheiro principal da app Flutter AQUANAUTIX (mono-repo). Responde em português de Portugal. Diagnóstico antes de mudanças grandes. Diff mínimo.

Repo: C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX · branch feat/p5-golden-window-push · último commit fa6bc8a

ESCOPO
- App Flutter (lib/, pubspec, android/, assets/): ✅ foco principal
- Supabase (supabase/migrations/): ⚠️ alinhar local↔remoto (ver secção Supabase abaixo)
- Site V2/: ❌ NÃO MEXER sem AUTORIZO explícito (produção aquanautix.vercel.app)
- Design/UI: ❌ NÃO MEXER sem AUTORIZO explícito
- Secrets: .env + tools/local_secrets.ps1 (nunca commitar sk_, ghp_, sbp_)

STACK (verificar no código — não confiar só neste prompt)
- lib/screens/ + lib/core/ + lib/features/home/ + lib/features/community/
- Mapa: flutter_map (ArcGIS/OSM/OpenSeaMap) — Mapbox SDK só bootstrap token, NÃO rendering (MIUI)
  → Camadas V1: batimetria GEBCO (WMSTileLayerOptions), regulamentos GeoJSON, heatmap comunidade, filtro espécies, lojas dinâmicas
  → P4 blur pins PRO/ELITE + banner FOMO · 53 spots reais PT+ES (técnica/cana/profundidade)
- Oráculo: Open-Meteo + Nominatim em lib/core/tides/ · pesquisa local (planeamento) OK
  → Card ISCO+TÉCNICA: BaitTechniqueService (10 espécies, confiança por mês/habitat/maré)
- Notificações: GoldenWindowNotificationService (P5 local — PRO diário, FREE 1×/semana)
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
  MIUI: adb devices vazio → cabo/driver USB · INSTALL_FAILED_USER_RESTRICTED → adb push + pm install (ver HANDOFF.md)
  Fix Mapa GEBCO: usar wmsOptions (não urlTemplate com {bbox-epsg-3857}) — já em fa6bc8a

INÍCIO (lib/features/home/)
- loadDashboard(forceRefresh) · knownCoords no OracleDataService.fetch
- Tap spot → pendingMapFocus · tap comunidade → pendingCommunityProfile + tab 6 + sheet Ghost

ORÁCULO (lib/screens/oraculo.dart) — estado Jun 2026
- OracleDecisaoFold: hero · score pulse · janela âmbar · mini-mapa · pack PRO
- Card ISCO+TÉCNICA (P3): entre DecisaoFold e ConditionsFold; BaitTechniqueService
- OracleConditionsFold colapsável (meteorologia 16 cartões abaixo)
- Evitar flutter_animate + IntrinsicHeight em SingleChildScrollView (ecrã preto MIUI)

MAPA (lib/screens/mapa.dart)
- fishing_spots + bait_shops via repositórios Supabase + fallback offline
- FilterChip espécies no sheet · pins/lista filtrados · fotos reais por espécie
- Batimetria GEBCO: TileLayer(wmsOptions: WMSTileLayerOptions(...))
- P4: blur/cadeado spots PRO/ELITE para FREE

SUPABASE
- Projecto: ycmvqokcfzxkpinvcyhk.supabase.co
- Guia: supabase/README_setup.md
- ⚠️ migration list desalinhado (25 Jun): local 20260619000000 + 20260625000000 · remoto 20260625104633 + 20260625105126
- Correr: .\tools\supabase_with_env.ps1 db push --yes (após rever diff)

DOCS: AQUANAUTIX_CONTEXT.md · CLAUDE.md · HANDOFF.md · SYNC_WORKFLOW.md
BACKLOG: .cursor/rules/proximos-movimentos.mdc (P1–P17)

PENDENTE P0/P1
1. Merge feat/p5-golden-window-push → main (PR no GitHub — main protegida)
2. Alinhar migrations Supabase local=remoto
3. RevenueCat — produtos PRO/ELITE no dashboard + gates reais
4. Onboarding — ligar onboarding.dart ao arranque (1.ª vez)
5. P1 Assistente IA conversacional (backlog)

TAREFA DESTE CHAT:
[DESCREVER AQUI]
```

---

## Commits recentes (referência)

| Commit | Branch | Descrição |
|--------|--------|-----------|
| `fa6bc8a` | feat/p5-golden-window-push | fix(mapa): GEBCO WMSTileLayerOptions + security RLS fishing_spots + blur PRO |
| `7a52ccc` | feat/p5-golden-window-push | feat(spots): 53 spots reais PT+ES com técnica/cana/profundidade |
| `68b6af8` | feat/p5-golden-window-push | feat(notif): P5 Janela de Ouro push local (PRO diário, FREE 1×/semana) |
| `0b0e7d4` | main | feat(mapa): P4 blur pins PRO/ELITE + banner FOMO |
| `075508a` | main | feat(oraculo+mapa): P3 isco+técnica, P7 lojas dinâmicas |
| `1468f5b` | main | feat(mapa): camadas V1 batimetria, regulamentos, heatmap, filtro espécies |

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
| Notificações P5 | `lib/core/notifications/golden_window_notification_service.dart` |
| Oráculo P3 | `lib/core/fishing/bait_technique_service.dart` |
| Supabase app | `lib/core/supabase_bootstrap.dart`, `community/`, `catch_photos/` |
| Supabase repo | `supabase/migrations/` (15+ ficheiros), `supabase/README_setup.md` |
| Assets dados | `assets/data/fishing_regulations_pt_es.geojson` |

---

## Sincronização ecossistema (25 Jun 2026)

| Componente | Estado |
|------------|--------|
| App Flutter `lib/` | ✅ `fa6bc8a` (feat/p5-golden-window-push) |
| GitHub branch activa | ✅ `feat/p5-golden-window-push` pushed |
| GitHub `main` | ⚠️ Protegida — merge via PR (branch 3 commits à frente) |
| Docs (CONTEXT, HANDOFF) | ✅ actualizados 25 Jun 2026 |
| Site V2 produção | ⏸️ Sem alterações (AUTORIZO) |
| Supabase remoto | ⚠️ migration list desalinhado — correr `.\tools\supabase_with_env.ps1 db push --yes` |
| Edge Functions | ❌ Não versionadas no repo |
| RevenueCat / Lojas | 🔄 Parcial (P0 pausado até Play Console $25) |

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

1. **Merge PR** — `feat/p5-golden-window-push` → `main`
2. **Alinhar Supabase** — `db push` + rever migrations órfãs no remoto
3. **P0 RevenueCat** — Play Console $25 + produtos PRO/ELITE (`REVENUECAT_SETUP.md`)
4. **Onboarding** — ligar `onboarding.dart` ao arranque (primeira vez)
5. **P1 Assistente IA** — chat conversacional com contexto GPS/spot/maré
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
