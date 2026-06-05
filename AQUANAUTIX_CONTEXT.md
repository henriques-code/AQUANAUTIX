# AQUANAUTIX — Central de contexto

**Última revisão estrutural:** 5 Jun 2026 — grelha meteorologia Oráculo (16 cartões 3D, Marés/Correntes, Open‑Meteo marine/AQI).

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
- **Ecrãs:** `home` (6 tabs; WeatherCard compacto + barra solunar, Condições Favoráveis horárias com score Oráculo, grid 3×spots com fotos locais, comunidade 3 entradas compactas com fotos de espécies), `oraculo` (COSTA/RIO, índice, **grelha «Detalhes de meteorologia»** 16 cartões brancos com gráficos 3D, cartões **Marés** + **Correntes**, pull-to-refresh, **pesquisa Nominatim**, cartão isco/cana/técnica), `mapa`, `vision`, `logbook`, `perfil`, `paywall`, `splash`, fluxos login/password.
- **`lib/screens/widgets/`:** `oracle_weather_details_grid.dart` — grelha meteorologia (CustomPainters: vento, IQA, lua, marés isométricas, correntes oceânicas, etc.).
- **`lib/core`:** `OracleDataService` (`lastCoords`, `invalidateCache`) + `lib/core/tides/` (`weather_details_snapshot.dart`, `fetchWeatherDetails` Open‑Meteo + marine + air-quality; Nominatim search/reverse; cache; portos PT/ES em `tide_reference_ports.dart`), `lib/core/l10n/` (AqxL10n PT/ES), espécies/compliance, vision, estado, comunidade (repo/store).
- Design system Midnight Deep Sea (`screens/_shared.dart`).
- **`lib/features/home/`:** arquitectura feature-first (data/domain/presentation); `WeatherData` com `solunarScore`, `windDir`, `pressure`; `HomeRepositoryImpl` usa `moonFishingFactor` + score Oráculo horário; spots em `assets/marketing/spots/` (Cabo da Roca, Peniche, Sesimbra — Wikimedia); comunidade em `assets/marketing/catches/` (BrunoPescas, Nuno_Sesimbra, Miguel_Peniche); cards compactos com `Image.asset`.
- Pendente: monetização RC estável em produção, gates PRO/Elite completos; extender i18n a ecrãs fora de Oráculo/Home se o produto o exigir.

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
