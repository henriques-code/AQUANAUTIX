# AQUANAUTIX — Central de contexto

**Última revisão estructural:** 25 Jun 2026 — P5 push Janela de Ouro local; P4 blur mapa; 53 spots PT+ES; fix GEBCO WMS; RLS fishing_spots; P3 isco+técnica; P7 lojas dinâmicas; camadas mapa V1.

## Estrutura do repositório (mono-repo)

```
AQUANAUTIX/
├── lib/                      # App Flutter — main.dart, app.dart, screens/ (+ widgets/), core/
├── pubspec.yaml              # Dependências Flutter
├── assets/                   # Imagens, vídeos e dados da app Flutter
├── Site V2/                  # Site estático + deploy Vercel
│   ├── index.html            # Landing principal (Mapbox, Oráculo, waitlist, …)
│   ├── video_bg.mp4          # Vídeo hero / fundos (mesma pasta que index.html)
│   ├── vercel.json           # cleanUrls, etc.
│   ├── .vercel/              # Link Vercel (criado com `vercel link` dentro de Site V2)
│   ├── app-prototype.html    # Protótipo SPA ecrãs app
│   ├── app-demo.html         # Demo shell app
│   ├── app-5screens.html     # Mock multi-ecrã (se usado)
│   ├── monetization-prototype.html
│   ├── community-prototype.html, mapa-prototype.html  # protótipos UI
│   ├── images/               # Marketing, hero, capturas de ecrã
│   ├── package.json          # Puppeteer local + npm scripts de screenshot
│   └── tools/                # screenshot.js … screenshot4.js → grava em images/
├── tools/                    # Raiz: `run_dev.ps1` (arranque com env), `convert_mockups.py`
├── supabase/                 # Migrations SQL + setup (Auth, DB, Storage)
│   ├── migrations/           # app_insights, community, catch_photos
│   ├── scripts/
│   └── README_setup.md
├── HANDOFF.md                  # Handoff novos chats
├── ECOSYSTEM.md                # Serviços e sincronização
├── CLAUDE.md                   # Instruções para assistentes IA
├── .cursorrules                # Regras do projecto (PT)
└── AQUANAUTIX_CONTEXT.md       # Este ficheiro
```

**Deploy Vercel:** corre `vercel` / `vercel link` a partir da pasta **`Site V2/`** (é aí que existe `vercel.json` e, após link, `.vercel/project.json`).

**Servidor local do site:** `Site V2/_local_server.ps1` → tipicamente `http://localhost:8080`.

**Screenshots (Puppeteer):** na pasta `Site V2`, com `npm install` feito, usa por exemplo `npm run screenshot:plans` (ver `package.json` → scripts `screenshot:*`). Os scripts vivem em `Site V2/tools/`.

## Stack

- **Flutter:** app móvel — Supabase, Mapbox Maps, etc.
- **Site V2:** HTML/CSS/JS + Mapbox GL JS v3.3.0 + SunCalc
- **Produção:** [aquanautix.vercel.app](https://aquanautix.vercel.app)
- **Mapbox:** token apenas em variáveis de ambiente / dashboard Mapbox — **nunca** em ficheiros versionados.

## Estado Flutter

- **`lib/main.dart` / `app.dart`:** bootstrap Supabase, RevenueCat, analytics, tema, `flutter_localizations` e locale derivado de GPS (PT/ES).
- **Navegação:** `AquanautixHome` com **7 tabs lazy** — Início · Oráculo · Mapa · Vision · Log · Perfil · **Comunidade** (via `HomeTabIndex`; índice 6 = `communityTabIndex`).
- **Ecrãs:** `home` (7 tabs lazy `_tabCache`; Início com WeatherCard, pull-to-refresh GPS, spots→mapa, comunidade→tab COMUN.), `comunidade` (feed Ghost + sheet perfil), `oraculo` (**OracleDecisaoFold** mockup — hero pescador, linha decisão, faixa PRO sticky, drawer trial, GHOST cards, spot PRO; **OracleConditionsFold** colapsável; strip Comunidade → tab 6; Nominatim; GPS inline), `mapa` (`flutter_map`), `vision`, `logbook`, `perfil`, `paywall`, `splash`, login/password.
- **`lib/screens/widgets/` (Oráculo):** `oracle_decisao_fold.dart`, `oracle_hero_decision.dart`, `oracle_conversion_pack.dart` (decision line + sticky PRO + drawer), `oracle_mockup_header.dart`, `oracle_community_photo_row.dart`, `oracle_pro_spot_teaser.dart`, `oracle_conditions_collapsible.dart`, `oracle_conditions_fold.dart`, `oracle_decision_card.dart`, `oracle_fishing_metrics_grid.dart`, `oracle_timeline_24h.dart`, `oracle_community_strip.dart`, `oracle_mini_map.dart`, `oracle_weather_details_grid.dart`, `aqx_pressable.dart`, `location_access_sheet.dart`.
- **`lib/core/fishing/bait_technique_service.dart`** — `BaitRecommendation` (bait, rodType, technique, techniqueDesc, confidence) + `BaitTechniqueService.recommend()` para 10 espécies ibéricas; confiança ajustada por mês, habitat e maré.
- **`lib/core/spots/fishing_spot.dart` + `fishing_spot_repository.dart`** — modelo `FishingSpot` com PostGIS, `fetchNearby`, `fetchBySpecies`, fallback offline.
- **`lib/core/spots/bait_shop.dart` + `bait_shop_repository.dart`** — modelo `BaitShop` com `isOpen`, `photoUrl`, `mapsQuery`; `fetchNearby` via Supabase + fallback 10 lojas.
- **`lib/core/regulations/fishing_regulation_zone.dart`** — modelo GeoJSON para zonas regulamentadas (proibido/licença_especial/defeso_temp).
- **`lib/core/community/community_heatmap_repository.dart`** — agrega capturas Ghost por geohash ~5 km; fallback demo.
- **`lib/core/location/`:** `gps_access.dart` — cache memória, single-flight, `tryGetFix`/`tryGetFixQuick`, `forceRefresh`, `AndroidSettings(forceLocationManager)` (MIUI); `gps_bootstrap.dart` — permissão no arranque + `refreshFix` em background.
- **`lib/screens/comunidade.dart` + `lib/features/community/`:** tab **COMUN.** — feed Ghost, sheet perfil público (`community_ghost_profile_sheet.dart`, `community_public_profile.dart`); tap no Início → `pendingCommunityProfile` + tab Comunidade.
- **`lib/core/tides/`:** `oracle_hourly_score.dart` — score horário solunar+nuvens+chuva (timeline + Início).
- **`lib/core/community/`:** `community_demo_posts.dart` — feed Ghost offline quando Supabase vazio.
- **`lib/core`:** `OracleDataService` + tides/Nominatim, `supabase_bootstrap.dart`, `community/`, `catch_photos/`, espécies/compliance, vision, estado (`logbook_tab_index`, `home_tab_index`).
- **`supabase/`:** 13 migrations aplicadas (insights, comunidade Ghost, catch_photos PostGIS, **fishing_spots** + **bait_shops** com PostGIS + RLS tier FREE/PRO/ELITE, 55 lojas seed PT/ES, 5 spots seed) — ver `supabase/README_setup.md`.
- Design system Midnight Deep Sea (`screens/_shared.dart`).
- **`lib/features/home/`:** arquitectura feature-first (data/domain/presentation); `WeatherData` com `solunarScore`, `windDir`, `pressure`, `hasTide`; `HomeRepositoryImpl.loadDashboard(forceRefresh)` — obtém GPS dentro do load, invalida Oráculo no refresh, `knownCoords` no fetch; pull-to-refresh: GPS primeiro (12s) → invalidate → reload; spots em `assets/marketing/spots/` (**Cabo Espichel**, Peniche, Sesimbra) com **lat/lon** e tap → `pendingMapFocus`; `CommunityActivityCard` clicável → perfil Ghost.
- **`lib/core/widgets/aqx_ghost_mode_badge.dart`:** badge Ghost (hex ciano + pill âmbar) — substitui 👻 em Oráculo, Logbook, Mapa, Vision, comunidade.
- **`assets/marketing/catches/`** — dourada, robalo, sargo; **`oracle_hero_pescador.jpg`** (hero Oráculo mockup).
- **`lib/screens/widgets/oracle_mini_map.dart`:** mini-mapa no hero Oráculo (GPS/planeamento + CTA VER MAPA; blur FREE via `oracle_hero_decision.dart`).
- **`lib/core/l10n/aqx_l10n.dart` + `app_locale_store.dart`:** login **PT/ES/EN** (Fase 1); resto da app PT/ES; `setLocale` bloqueia override GPS.
- **`lib/core/supabase_bootstrap.dart`:** `isSupabaseReady` / `supabaseClientOrNull` — evita crash `Supabase.instance` antes de init.
- Pendente: monetização RC estável em produção, gates PRO/Elite completos; push Janela de Ouro (EM BREVE na UI).

### Sessão 8 Jun 2026

**Oráculo — Sprint 1 funcional (`a218224`)**
- **Decisão:** `oracle_decision_card.dart` — score, janela, razões (vento/ondas reais), alvo espécie (chips), CTAs Log/Mapa.
- **Métricas:** `oracle_fishing_metrics_grid.dart` — Maré, Vento, Ondas, Temp. água, Corrente, Pressão (COSTA/RIO).
- **Timeline:** `oracle_timeline_24h.dart` + `oracle_hourly_score.dart` — próximas 12h score + curva maré.
- **Comunidade:** `oracle_community_strip.dart` + `community_demo_posts.dart` — preview Ghost; botões VER COMUNIDADE / PARTILHAR 👻.
- **GPS:** `gps_access.dart`, `location_access_sheet.dart` — banner **inline** no Início (sem modal automático pós-login); sheet manual se necessário; banner âmbar no Oráculo; **Activar GPS** / **Pesquisar local**; fallback regional (`TideMapPreset`) com dados Open‑Meteo reais.
- **Logbook:** `logbook_tab_index.dart` — `pendingAction` abre sheet nova captura / novo post ao navegar desde Oráculo.
- **Meteorologia:** accordion «Meteorologia completa» (fechado por defeito); gráfico marés 2D legível.
- **`home.dart`:** `HomeTabIndex.pendingOraclePlaceSearch` abre pesquisa no Oráculo; **`HomeTabIndex.pendingMapFocus`** centra mapa a partir de CTAs.

**Oráculo — Botões 3D mix A+B (`f39cd26`)**
- **`aqx_pressable.dart`:** `AqxNeonButton` / `AqxNeonCompactButton` (CTAs acção) + `AqxGlassButton` / `AqxGlassChip` / `AqxGlassSegmentToggle` (secundários); scale 3D, haptic e `SystemSound.click`.
- Integrado em decision card, comunidade, banner/sheet GPS, toggle COSTA/RIO e chips espécie.

### Sessão 10 Jun 2026

**Commits em `main` (push feito)**
- `8cdeb64` — Sprint **A** (`AqxGhostModeBadge`) + Sprint **B** (`oracle_mini_map.dart`); fix `AqxMeteoRevealButton` (unbounded width no accordion MIUI).
- `b571b12` — **i18n Fase 1:** pills PT|ES|EN no login; `AppLocaleStore.setLocale`; `Locale('en')` em `supportedLocales`.

**Commits (`e7a276b`, `7773a3c`, `da3ca79`) — push feito**
- **GPS Início + pull-to-refresh** — `gps_bootstrap.dart`, `forceRefresh`, MIUI `forceLocationManager`; invalidate Oráculo no refresh.
- **`home_repository_impl.dart`** — `loadDashboard(forceRefresh)`; `hasTide`; bundle GPS com `knownCoords`.
- **Spots → Mapa** — `FeaturedSpot` lat/lon; Cabo Espichel `38.4162,-9.2178`; Peniche `39.3545,-9.3835`.
- **Tab Comunidade (7.º)** — `comunidade.dart`, perfil Ghost, drawer/Oráculo → tab 6.

**Pendente:** Sprint C (manifest spots), i18n Fase 2, renomear `cabo_da_roca.jpg` → `cabo_espichel.jpg`.

### Sessão 9 Jun 2026

**Oráculo — fold condições + selector espécie (`e81633c`, `3217a4d`)**
- **`oracle_conditions_fold.dart`** — card unificado (métricas 2×3 + timeline 12h); sparklines vento/ondas; tap expande meteorologia.
- **Selector espécie** movido para o card isco/cana/técnica (removido do topo).
- **Timeline 12h** — legenda, janela de ouro, gráfico maré maior; score horário via `oracle_hourly_score.dart`.
- **CTAs** «Registar captura» / «Ver no mapa» — `HomeTabIndex` + `pendingMapFocus` no `mapa.dart`.
- **Open‑Meteo** — `windSparkline`, `waveSparkline`, `wavePeriodS` no repositório de marés.
- **Logbook** — fix crash «Nova captura» (`_NovaCapturaSheet` StatefulWidget).

**Fix MIUI — Início e Oráculo bloqueados pós-login (`678ff0f`)**
- **Causa:** modal GPS invisível; `IndexedStack` com vários tabs em paralelo (sobrecarga MIUI); `flutter_animate` + `IntrinsicHeight` em scroll (ecrã preto Oráculo).
- **`home.dart`** — tabs **lazy** via `_tabCache` (só tab activa montada); **sem** modal GPS automático ao entrar.
- **`inicio_dashboard_screen.dart`** — `instantFallback` imediato; load em background; banner GPS **inline** (dismissível), não modal.
- **`home_repository_impl.dart`** — zero `requestPermission` no load; coords de cache GPS ou regional; Oracle com `planningPlace`; meteo em paralelo.
- **`weather_card.dart`** — removido `flutter_animate` (evita jank MIUI).
- **`oraculo.dart`** — `Scaffold(kBg)`; init sempre em `postFrameCallback`; `_effectivePlanningPlace()`; removido lazy bootstrap; alturas fixas onde havia `IntrinsicHeight`; sem shimmer `.animate()`.
- **`oracle_weather_details_grid.dart`** — fix layout; header meteorologia + `AqxMeteoRevealButton`.
- **`gps_access.dart` / `oracle_data_service.dart`** — fetch GPS não bloqueante; fallback cache/stale.
- **`community_store.dart`** — `loadFeed` com `Future.delayed(Duration.zero)` (evita `setState during build`).
- **Dispositivo teste:** Xiaomi `WWZLYDXWYXT8PV5D` — install via `.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D` (MIUI pode exigir `adb push` + `pm install -r -t`).

### Sessão 5 Jun 2026

**Oráculo — Grelha meteorologia (`lib/screens/oraculo.dart`, `lib/screens/widgets/oracle_weather_details_grid.dart`)**
- Substituição das mini-cards horizontais por grelha 2 colunas (referência `Imagens/preview.webp`)
- 16 cartões: temperatura, sensação, nebulosidade, precipitação, vento, humidade, UV, IQA, pólen, visibilidade, pressão, sol, lua, fase da lua, **marés**, **correntes**
- Dados: `OpenMeteoTidesRepository.fetchWeatherDetails` (forecast + marine `sea_level_height_msl` / `ocean_current_*` + air-quality AQI/pólen)
- `WeatherDetailsSnapshot` + fallback; integração com bundle Oráculo (`tideHeightM`, `tideRangeM`, fase enchente/vazante)
- Gráficos CustomPaint 3D (bússola vento, onda marés isométrica, correntes oceânicas, barras humidade/precipitação, etc.)
- Pull-to-refresh no Oráculo (`invalidateCache` + reload score + meteorologia)
- Commits: `4b02d96` (código), `256d472` (screenshots `Imagens/`)

**Home — Início dashboard (`lib/features/home/`)**
- `assets/marketing/spots/` — Cabo Espichel (ficheiro `cabo_da_roca.jpg`), Peniche, Sesimbra; bundlados offline; coords em `FeaturedSpot`
- `assets/marketing/catches/` — dourada, robalo, sargo (Wikimedia); comunidade com 3 entradas
- `WeatherCard` — layout 4 colunas compacto; `SolunarProgressBar` com peixes animados
- `HourlyCondition` — score Oráculo + badge MELHOR; chips em linha sem scroll
- `FeaturedSpotCard` / `CommunityActivityCard` — suporte `Image.asset` + fallback `Image.network`
- `home.dart` — "Ver todas" e "Ver mapa" navegam para Oráculo/Mapa
- Commits: `9c4ad75` (Condições Actuais), `50ae0ee` (spots/comunidade/assets)

### Sessão 18 Mai 2026

**Home — WeatherCard + Solunar (`lib/features/home/`)**
- `WeatherData` — novo campo `solunarScore: int` (default 0)
- `HomeRepositoryImpl._getUserDisplayName()` — lê primeiro nome do utilizador a partir de metadados Supabase: `full_name` → `name` → `display_name` → email prefix → fallback `'Pescador'`
- `HomeRepositoryImpl.loadDashboard()` — `solunarScore` calculado em tempo real via `moonFishingFactor(now)` (factor 0–1 × 100)
- `WeatherCard` — recebe `AqxL10n t`; nova secção `_SolunarBar` abaixo das stats:
  - Barra `LinearProgressIndicator` com cor dinâmica: âmbar ≥75, ciano ≥50, ciano atenuado abaixo
  - Score numérico (Orbitron 13) + etiqueta de qualidade (EXCELENTE / BOM / MODERADO / FRACO)
- `AqxL10n` — strings novas: `homeStatSolunar`, `scoreLabel(int)`, `homeGreetingPersonalized(hour, name)`, `pressureStable/Variable/StableShort/VariableShort`, tabs `tabHome`, `homeSectionConditions/Spots/Community`, `homeVerTodas/Mapa`, `homeLoadError/Retry`, `homeStatWind/Waves/Tide/Moon`

### Sessão 15 Mai 2026

**Splash Screen (`lib/screens/splash_screen.dart`)**
- Vídeo de fundo: `assets/video_bg.mp4` via `video_player`
- Barra de progresso ciano 3 px (sem dots de paginação)
- Navega directamente para `LoginModuleScreen`

**Login Screen (`lib/screens/login_module.dart`)**
- Redesign completo com vídeo de fundo e overlay escuro
- **Google Sign-In real** via `google_sign_in: ^6.3.0` + Supabase `signInWithIdToken`
- `serverClientId` = Web Client ID do Google Cloud Console
- `idToken` null-check explícito (sem crash)
- Sem nonce (removido — causa erro "nonce mismatch" no Android)
- Botão "Entrar como Convidado" corrigido → `Navigator.pushReplacement` para `AquanautixHome`
- Apple Sign-In: placeholder "Em breve"

**Android**
- `applicationId` mudado de `com.example.aquanautix` → `com.aquanautix.app`
- `namespace` actualizado em `build.gradle.kts`
- `package="com.aquanautix.app"` no `AndroidManifest.xml`
- `MainActivity.kt` movido para `kotlin/com/aquanautix/app/`
- Meta-data Google Play Services adicionada ao `AndroidManifest.xml`

**Google Cloud Console / Supabase**
- OAuth Client ID Android: `com.aquanautix.app` + SHA-1 debug keystore
- SHA-1 debug: `EF:B4:5A:36:17:EF:BA:5D:4E:FE:C3:A9:20:EC:80:98:41:61:90:23`
- OAuth Client ID Web (serverClientId): `141446877512-0ibqum1ik8hkpao5mquohe14eu42kmtb.apps.googleusercontent.com`
- Supabase Dashboard: Google provider activado com ambos os Client IDs

**Packages adicionados**
- `google_sign_in: ^6.2.1`

**Resolvido (2 Jun 2026)**
- `android/app/google-services.json/` — pasta órfã removida (não era usada; auth via Supabase OAuth)
- `.gitignore` reforçado: cobre `google-services.json` (ficheiro + pasta) + `GoogleService-Info.plist`

## Estado Site V2

- Mapa 3D, spots PT/ES, lojas de isco, Oráculo, waitlist (localStorage-first)
- Pendente: Formspree com endpoint real, restrição de URL do token Mapbox no dashboard

## Sessão 2 Jun 2026 — Limpeza e organização

**Segurança**
- Pasta órfã `android/app/google-services.json/` removida (conteúdo era `client_id` público, nunca esteve no git)
- `.gitignore` reforçado para cobrir Firebase + iOS (`GoogleService-Info.plist`)

**Assets**
- 7 mockups de design movidos de `assets/` → `prototypes/design-mockups/` (com `git mv`, histórico preservado)
- `assets/videos/login_bg.mp4` removido — duplicado exacto de `assets/video_bg.mp4` (7.5 MB recuperados)
- `assets/` agora só contém ficheiros usados pela app: `data/`, `icons/`, `onboarding/`, `robalo_scanner.png`, `video_bg.mp4`

**Código morto**
- `lib/screens/onboarding/slides/vision_scanner_slide.dart` removido (605 linhas, zero imports)
- `oracle_live_widgets.dart` confirmado como **activo** (glifo de peixe animado no Oráculo)
- Cluster `tide_reference_ports` / `tide_offset_store` / `tide_location_prefs` **mantido** — dados reais de 18 portos PT/ES para feature futura de calibração de marés

**Dependências**
- Removidas 6 dependências não usadas: `speech_to_text`, `qr_flutter`, `crypto`, `flutter_local_notifications`, `timezone`, `flutter_timezone`
- `pubspec.yaml`: 23 → 17 dependências; `pubspec.lock`: menos 15 pacotes transitivos

### Sessão 11 Jun 2026

**Tab Comunidade + perfil Ghost**
- **7.º tab** `COMUN.` em `home.dart` — `ComunidadeScreen` (`lib/screens/comunidade.dart`)
- `community_public_profile.dart` + `community_ghost_profile_sheet.dart` — perfis mock BrunoPescas, Nuno_Sesimbra, Miguel_Peniche (sem coords)
- Início: tap card comunidade → `HomeTabIndex.pendingCommunityProfile` + tab 6 → sheet
- Drawer e Oráculo: navegam para tab Comunidade (não Logbook sub-tab)
- `aqx_l10n.tabCommunity` · labels nav com `FittedBox`

**GPS MIUI + pull-to-refresh (Início)**
- `gps_bootstrap.dart` — permissão no arranque; `refreshFix` 12s
- `gps_access.dart` — `forceRefresh`, `AndroidSettings(forceLocationManager)`, retry medium/high/low
- `loadDashboard(forceRefresh)` — obtém GPS no load; invalida Oráculo; `knownCoords` em `OracleDataService.fetch`
- Pull-to-refresh: GPS → invalidate → reload (fix confirmado em dispositivo Xiaomi)

**Outros**
- `logbook.dart` — fix `pendingTab` com post-frame callback
- `perfil.dart` — `GpsBootstrap.reset()` no logout

### Sessão 18 Jun 2026

**Mapa V1 — Camadas de informação (`1bfbe09`, `feat/mapa-camadas-v1`)**
- **Fishing Spots Supabase:** `fishing_spots` table com PostGIS, RLS FREE/PRO/ELITE, 5 spots seed PT/ES; `FishingSpotRepository` com `fetchNearby`/`fetchBySpecies` e fallback offline.
- **P2 Batimetria GEBCO:** `TileLayer` com `WMSTileLayerOptions` GEBCO (opacidade 55%) no modo COSTA; toggle no sheet de camadas; `SnackBar` em modo RIO. **Fix 25 Jun:** substituído `urlTemplate` com `{bbox-epsg-3857}` (crash MIUI) por `wmsOptions`.
- **P3 Regulamentos PT+ES:** `PolygonLayer` com GeoJSON `fishing_regulations_pt_es.geojson`; tap em polígono → `BottomSheet` com detalhes e link DGRM/MITERD; cores distintas por tipo (proibido=vermelho, licença_especial=âmbar, defeso_temp=laranja).
- **P4 Heatmap Comunidade:** `CommunityHeatmapRepository`; `MarkerLayer` com círculos translúcidos (raio ∝ catchCount); ciano PRO / branco FREE; tap → tab Comunidade.
- **P5 Filtro Espécies:** `FilterChip` horizontal no sheet de spots; `_filteredSpots` filtra pins e lista; fotos reais por espécie (assets locais + Wikimedia); lojas próximas respeitam filtro.
- **Fix web:** `mapbox_config.dart` guarda `kIsWeb` para evitar crash `bool.fromEnvironment` no Chrome.

**P3 Isco+Técnica no Oráculo (`f0674ae`, `feat/oracle-p3-bait-technique`)**
- `BaitTechniqueService.recommend()` — 10 espécies, confiança ajustada por mês/habitat/maré.
- Card «ISCO + TÉCNICA» no `oraculo.dart` entre `OracleDecisaoFold` e `OracleConditionsFold`; oculto se espécie não definida.

**P7 Lojas de Isco Dinâmicas (`4f355b7`, `feat/oracle-p3-bait-technique`)**
- `bait_shops` table Supabase (PostGIS + RLS + 55 lojas seed PT/ES); `BaitShop` + `BaitShopRepository`; `_loadBaitShops()` no arranque do mapa; pins verdes dinâmicos; sheet top 15 por distância.
- Migration `20260617000001_bait_shops.sql` aplicada ao remoto.

**Estado branches (18 Jun 2026)**
- `feat/mapa-camadas-v1` — pushed, PR pendente merge → main
- `feat/oracle-p3-bait-technique` — pushed, inclui P3+P7, PR pendente merge → main
- `main` local — 2 commits à frente de `origin/main` (aguarda PRs)

### Sessão 25 Jun 2026

**P5 Push Janela de Ouro local (`68b6af8`, `feat/p5-golden-window-push`)**
- `GoldenWindowNotificationService` — `flutter_local_notifications`; canal `aqx_golden_window`; PRO 1×/dia, FREE 1×/semana; init em `main.dart`.

**53 Spots reais PT+ES (`7a52ccc`)**
- Migration `20260619000000_spots_real_data_and_fields.sql`; dados técnica/cana/profundidade no Supabase.

**P4 Blur Mapa + Security (`0b0e7d4`, `fa6bc8a`)**
- Pins PRO/ELITE desfocados + cadeado para FREE; banner FOMO spots bloqueados.
- RLS `fishing_spots` corrigido — policies PRO/ELITE verificam `user_profiles.tier` (`20260625000000_fishing_spots_rls_tier_check.sql`).

**Estado branch (25 Jun 2026)**
- `feat/p5-golden-window-push` — 3 commits à frente de `main`; pushed para GitHub; PR pendente merge.

### Sessão 16 Jun 2026

**Oráculo — layout mockup Decisão (`98e1952`)**
- **`OracleDecisaoFold`** — ordem mockup `Imagens/oraculo-decisao-mockup-full.png`: hero fullwidth + score pulse + janela âmbar + mini-mapa.
- **`oracle_hero_decision.dart`** — asset `assets/marketing/catches/oracle_hero_pescador.jpg`; CTAs IR PESCAR / REGISTAR CAPTURA; espécie alvo chips + isco/cana.
- **`oracle_community_photo_row.dart`** — GHOST 2 cards lado a lado; **`oracle_pro_spot_teaser.dart`** — card spot PRO bloqueado.
- **`oracle_conditions_collapsible.dart`** — condições 12h colapsáveis abaixo do fold.

**Oráculo — pack conversão PRO (`34b4e38`)**
- **`oracle_conversion_pack.dart`** — `OracleDecisionCopy.line()`, `OracleDecisionLine`, `OracleProStickyStrip`, `showOracleProUnlockSheet()` → PaywallScreen.
- Linha decisão («Vale ir pescar agora — janela fecha às X»); faixa sticky PRO; drawer «PRO 3 dias grátis →».
- Mini-mapa com blur + cadeado FREE; CTAs «Comparar 3 sítios (PRO)» / «Alertar janela (PRO) · EM BREVE».
- Gancho comunidade «X capturas perto · PRO vê zona 5 km»; card spot PRO tap → drawer.

**Segurança + repo (`cc359ab`, `63a674e`)**
- `.gitignore` reforçado (PAT, local_secrets); pre-commit bloqueia `ghp_` / `github_pat_`.
- Branch protection ruleset; `Imagens/` gitignored (screenshots locais).

**Supabase (`20260616174757_storage_no_public_listing.sql`)**
- Remove listagem pública `storage.objects` nos buckets catch-photos / community-photos; `getPublicUrl()` mantém-se.

**Deploy MIUI (Xiaomi `WWZLYDXWYXT8PV5D`)**
- Workaround: `adb push` + `pm install -r -t` + `run_dev.ps1 --use-application-binary=...`.

## Próximos passos (sugestão)

1. **Merge PRs** — `feat/mapa-camadas-v1` e `feat/oracle-p3-bait-technique` → main via GitHub
2. **RevenueCat** — configurar produtos PRO/ELITE no dashboard e testar gates
3. **Onboarding Flutter** — ligar `onboarding.dart` ao fluxo de arranque (só na primeira vez)
4. **P4 Blur Mapa** — spots PRO/ELITE desfocados + cadeado para utilizadores FREE
5. **P5 Push Janela de Ouro** — backend + permissões (UI já tem EM BREVE)
6. **Domínio** `aquanautix.app`

## Regras de trabalho

- Não alterar módulos protegidos do site sem **AUTORIZO** explícito (ver `.cursorrules` / `CLAUDE.md`).
- Backup antes de alterações grandes ao `index.html`.
- Após mudanças Flutter relevantes: `flutter analyze`.

## Design system (referência)

- `--bg: #000814` · `--cyan: #00F5FF` · `--amber: #F3C64D` · `--hint: #8AADBE`
- Títulos: Orbitron · Corpo: IBM Plex Sans
