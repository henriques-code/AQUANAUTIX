# AQUANAUTIX — Central de contexto

**Última revisão estrutural:** 9 Jun 2026 — fixes MIUI (Início/Oráculo responsivos), fold condições 12h, selector espécie no card isco.

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
├── CLAUDE.md                 # Instruções para assistentes IA
├── .cursorrules              # Regras do projecto (PT)
└── AQUANAUTIX_CONTEXT.md     # Este ficheiro
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
- **Navegação:** `AquanautixHome` com **6 tabs** — Início · Oráculo · Mapa · Vision · Log · Perfil (via `HomeTabIndex`).
- **Ecrãs:** `home` (6 tabs lazy `_tabCache`; WeatherCard compacto + barra solunar, Condições Favoráveis horárias com score Oráculo, grid 3×spots com fotos locais, comunidade 3 entradas compactas com fotos de espécies), `oraculo` (**Sprint 1 + fold 9 Jun:** card **Decisão**, **`OracleConditionsFold`** (métricas + timeline 12h), strip **Comunidade Ghost**, accordion meteorologia 16 cartões + `AqxMeteoRevealButton`, COSTA/RIO, chips espécie no card isco/cana, pesquisa Nominatim, fallback **regional Open‑Meteo** sem GPS, banner GPS **inline** no Início, CTAs registar captura / mapa / comunidade), `mapa`, `vision`, `logbook`, `perfil`, `paywall`, `splash`, fluxos login/password.
- **`lib/screens/widgets/`:** `aqx_pressable.dart` (botões 3D neon/glass + `AqxMeteoRevealButton` ABRIR), `oracle_decision_card.dart`, `oracle_fishing_metrics_grid.dart`, `oracle_conditions_fold.dart` (card unificado condições 12h), `oracle_timeline_24h.dart`, `oracle_community_strip.dart`, `location_access_sheet.dart`, `oracle_weather_details_grid.dart` (16 cartões 3D; marés 2D; correntes).
- **`lib/core/location/`:** `gps_access.dart` — cache memória, single-flight, `tryGetFixQuick()`, `cachedFix`/`cachedFixStale` (Início / Oráculo).
- **`lib/core/tides/`:** `oracle_hourly_score.dart` — score horário solunar+nuvens+chuva (timeline + Início).
- **`lib/core/community/`:** `community_demo_posts.dart` — feed Ghost offline quando Supabase vazio.
- **`lib/core`:** `OracleDataService` + tides/Nominatim, `supabase_bootstrap.dart`, `community/`, `catch_photos/`, espécies/compliance, vision, estado (`logbook_tab_index`, `home_tab_index`).
- **`supabase/`:** migrations Postgres (insights, comunidade Ghost, catch_photos PostGIS) — ver `supabase/README_setup.md`.
- Design system Midnight Deep Sea (`screens/_shared.dart`).
- **`lib/features/home/`:** arquitectura feature-first (data/domain/presentation); `WeatherData` com `solunarScore`, `windDir`, `pressure`; `HomeRepositoryImpl` usa `moonFishingFactor` + score Oráculo horário; spots em `assets/marketing/spots/` (Cabo da Roca, Peniche, Sesimbra — Wikimedia); comunidade em `assets/marketing/catches/` (BrunoPescas, Nuno_Sesimbra, Miguel_Peniche); cards compactos com `Image.asset`.
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

### Sessão 9 Jun 2026

**Oráculo — fold condições + selector espécie (`e81633c`, `3217a4d`)**
- **`oracle_conditions_fold.dart`** — card unificado (métricas 2×3 + timeline 12h); sparklines vento/ondas; tap expande meteorologia.
- **Selector espécie** movido para o card isco/cana/técnica (removido do topo).
- **Timeline 12h** — legenda, janela de ouro, gráfico maré maior; score horário via `oracle_hourly_score.dart`.
- **CTAs** «Registar captura» / «Ver no mapa» — `HomeTabIndex` + `pendingMapFocus` no `mapa.dart`.
- **Open‑Meteo** — `windSparkline`, `waveSparkline`, `wavePeriodS` no repositório de marés.
- **Logbook** — fix crash «Nova captura» (`_NovaCapturaSheet` StatefulWidget).

**Fix MIUI — Início e Oráculo bloqueados pós-login (`678ff0f`)**
- **Causa:** `showModalBottomSheet` GPS criava barrier modal invisível; `IndexedStack` montava 6 tabs em paralelo (sobrecarga MIUI); `flutter_animate` + `IntrinsicHeight` em scroll causavam `RenderBox was not laid out` (ecrã preto Oráculo).
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
- `assets/marketing/spots/` — Cabo da Roca, Peniche (porto de pesca), Sesimbra (marina); bundlados offline
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

## Próximos passos (sugestão)

1. **RevenueCat** — configurar produtos PRO/ELITE no dashboard e testar gates
2. **Onboarding Flutter** — ligar `onboarding.dart` ao fluxo de arranque (só na primeira vez)
3. **Google Sign-In** — testar em dispositivo com SHA-1 registado; confirmar login end-to-end
4. **Formspree** — endpoint `formspree.io/f/…` no site
5. **Domínio** `aquanautix.app`

## Regras de trabalho

- Não alterar módulos protegidos do site sem **AUTORIZO** explícito (ver `.cursorrules` / `CLAUDE.md`).
- Backup antes de alterações grandes ao `index.html`.
- Após mudanças Flutter relevantes: `flutter analyze`.

## Design system (referência)

- `--bg: #000814` · `--cyan: #00F5FF` · `--amber: #F3C64D` · `--hint: #8AADBE`
- Títulos: Orbitron · Corpo: IBM Plex Sans
