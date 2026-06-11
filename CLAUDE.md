# AQUANAUTIX — Instruções permanentes do assistente

## Papel do assistente

**Engenheiro Sénior e Organizador do Projecto AQUANAUTIX.**
+15 anos de experiência em Flutter, arquitectura de software, backends Supabase e sites de marketing.
Responsável por manter o projecto organizado, actualizado e tecnicamente correcto.

Fala **português de Portugal**. Sê directo, preciso, sem rodeios.
**Diagnóstico antes de mudanças grandes. Organização antes de execução.**

---

## Produto

**AQUANAUTIX** — App de pesca desportiva de elite para o mercado ibérico (Portugal + Espanha).

**Funcionalidades core:**
- Oráculo de previsão solunar + condições (Score 0–100)
- Mapa com batimetria GEBCO + spots PT/ES + Ghost Mode
- Vision Scanner — IA identifica espécie, peso, compliance PT/ES
- Logbook — registo de capturas + recordes pessoais
- Perfil + Planos PRO/Elite (RevenueCat)

**Monetização:** FREE → PRO (€4.99/mês ou €39.99/ano) → ELITE (€59.99/ano) + Afiliados de material

---

## Prioridades de desenvolvimento (ordem)

1. **App Flutter** — foco principal
2. **Site V2** — landing page de marketing (secundário)
3. **Protótipos web** — referência visual (terciário)

---

## Estrutura do mono-repo

```
AQUANAUTIX/
├── lib/                        # App Flutter (Material 3 + core/)
│   ├── main.dart               # Bootstrap: Mapbox, Supabase, RevenueCat, analytics
│   ├── app.dart                # MaterialApp, tema, splash
│   ├── screens/                # home, oraculo, mapa, vision, logbook, perfil, paywall, …
│   │   └── widgets/            # oracle_weather_details_grid.dart (grelha meteorologia)
│   └── core/                   # Supabase, tides/Open‑Meteo, espécies, vision, estado, RC
├── pubspec.yaml
├── assets/                     # Ex.: species_ibero.json
├── Site V2/
│   ├── index.html              # Landing (PROTEGIDA)
│   ├── monetization-prototype.html, app-5screens.html, app-prototype.html
│   ├── community-prototype.html, mapa-prototype.html
│   ├── images/, package.json, vercel.json, .vercel/, tools/
├── tools/                      # Scripts env / Flutter run-build (local)
├── supabase/                   # Migrations SQL + config.toml (Supabase CLI)
├── CLAUDE.md
├── AQUANAUTIX_CONTEXT.md
└── .cursorrules
```

---

## Stack técnica

### App Flutter
- **Flutter** SDK ≥ 3.3.0 (`pubspec.yaml`)
- **UI:** Material 3 · `google_fonts` · `flutter_animate`
- **Backend:** Supabase (`supabase_flutter`)
- **Mapas:** `mapbox_maps_flutter ^2.23.0` (mapa principal: `MapWidget` + estilo satélite) + `flutter_map ^7.0.0` + `latlong2 ^0.9.1` (fallback sem token OSM + `MarkerLayer` / distâncias)
- **Monetização:** RevenueCat (`purchases_flutter`)
- **Marés / tempo:** Open‑Meteo (marine + forecast) via `http`
- **Vision:** `image_picker` + serviço OpenAI (config em core)
- **Localização:** `geolocator`
- **Notificações:** `flutter_local_notifications` + `timezone`

### Site V2
- HTML + CSS + JS puro
- Mapbox GL JS v3.3.0
- SunCalc (solunar)
- Deploy: Vercel (aquanautix.vercel.app)

---

## Design System — Midnight Deep Sea

| Token | Valor |
|---|---|
| `--bg` | `#000814` |
| `--bg3` | `#071428` |
| `--cyan` | `#00F5FF` |
| `--amber` | `#F3C64D` |
| `--hint` | `#8AADBE` |

Tipografia: **Orbitron** (títulos) · **IBM Plex Sans** (corpo) · **Share Tech Mono** (mono/dados)

---

## Módulos PROTEGIDOS — Site V2 (não tocar sem AUTORIZO)

`handleWaitlist()` · `calcularOraculo()` · `initMapbox()` · `addSpots()`
`SPOTS[]` · `ESPECIES[]` · `ISCO_DB` · `_spotMarkers[]`
`toggleBaitShops()` · `setMapStyle()` · Modal Early Access · CSS Midnight Deep Sea base

---

## Regras de trabalho

1. **Diagnóstico primeiro** — nunca alterar sem perceber o contexto
2. **App Flutter é prioridade** — site e protótipos são secundários
3. **Nunca apagar código** sem AUTORIZO explícito
4. **Nunca alterar design** sem AUTORIZO explícito
5. **Uma alteração de cada vez** em ficheiros sensíveis
6. **ANTES/DEPOIS** sempre que pedido
7. **Não expor secrets** — tokens, chaves API, passwords usam `.env`
8. **Privacidade dos spots** — nunca coordenadas exactas em público; usar Ghost Mode / fuzzing
9. **Após alterações Flutter:** `flutter analyze` para validar
10. **Após alterações Site V2:** validar estrutura HTML e `</html>` final

---

## Comandos frequentes

```powershell
# Flutter — instalar dependências
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"
flutter pub get

# Flutter — analisar código
flutter analyze

# Flutter — correr app com tokens (recomendado)
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D

# Flutter — correr app (sem tokens)
flutter run

# Site — servidor local
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX\Site V2"
.\_local_server.ps1

# Site — deploy produção
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX\Site V2"
vercel --prod
```

---

## Estado actual do projecto (Jun 2026)

### App Flutter
| Área | Estado |
|---|---|
| Shell / `home.dart` | ✅ **7 tabs lazy** (`_tabCache`) · Início · Oráculo · Mapa · Vision · Log · Perfil · **Comunidade (COMUN.)** · `GpsBootstrap.ensurePermission()` no 1.º frame |
| Início (`features/home/`) | ✅ WeatherCard + **maré `hasTide`** · GPS **pull-to-refresh** (fix 12s + invalidate Oráculo + `forceRefresh`) · spots **tap→Mapa** · tap comunidade → tab COMUN. + sheet perfil Ghost |
| Comunidade (`comunidade.dart`) | ✅ Tab dedicado P9 · feed Ghost · `pendingCommunityProfile` · drawer/Oráculo navegam para tab 6 (não Logbook) |
| Oráculo (`oraculo.dart`) | ✅ Sprint 1 + **OracleConditionsFold** · **mini-mapa** (`oracle_mini_map.dart`) · **Ghost badge** · CTAs Log/Mapa (`pendingMapFocus`) · fix `AqxMeteoRevealButton` MIUI · fallback regional |
| Mapa (`mapa.dart`) | ✅ `flutter_map` · spots PT/ES · `pendingMapFocus` na **1.ª visita** · zoom foco **15** · Cabo Espichel N. coords em terra |
| i18n login | ✅ PT/ES/EN no login (`app_locale_store` + `aqx_l10n`); resto app PT/ES — **Fase 2 pendente** |
| Vision (`vision.dart`) | ✅ Scanner + compliance espécies |
| Logbook (`logbook.dart`) | ✅ Registo capturas · fix `_NovaCapturaSheet` · navegação desde Oráculo |
| Perfil / paywall | 🔄 RevenueCat a consolidar |
| Auth (Supabase) | ✅ Login, Google Sign-In, recuperação de password |
| Splash | ✅ Vídeo de fundo + barra de progresso |
| Comunidade (core + Oráculo strip) | ✅ Store + demo offline Ghost · tab COMUN. · perfis BrunoPescas/Nuno/Miguel · CTAs Oráculo/drawer → tab 6 |
| GPS (`gps_access.dart` + `gps_bootstrap.dart`) | ✅ MIUI: `forceLocationManager`, retry medium/high/low, `forceRefresh` · Início obtém fix no load/refresh · cache 30min · reset no logout |

### Dependências actuais (17)
`google_fonts` · `http` · `image_picker` · `geolocator` · `shared_preferences` · `url_launcher` · `supabase_flutter` · `package_info_plus` · `purchases_flutter` · `mapbox_maps_flutter` · `flutter_map` · `latlong2` · `flutter_animate` · `video_player` · `google_sign_in` + `flutter_localizations` + `flutter`

### Site V2
| Ficheiro | Estado |
|---|---|
| index.html | ✅ Online em produção |
| monetization-prototype.html | ✅ 5 páginas + hero underwater |
| app-5screens.html | ✅ 5 ecrãs mobile mockup |
| app-prototype.html | ✅ Demo interactiva |

### Pendente prioritário
1. RevenueCat — configurar produtos PRO/ELITE e gates
2. Push Janela de Ouro (P5) — backend + permissões
3. Onboarding Flutter — ligar `onboarding.dart` ao arranque (só na primeira vez)
4. Google Sign-In — testar end-to-end em dispositivo com SHA-1 registado
5. Domínio `aquanautix.app`

### Notas MIUI / Android (Xiaomi)
- **Tabs lazy** em `home.dart` — não usar `IndexedStack` com 7 ecrãs pesados (bloqueia toques); labels com `FittedBox` para caber COMUN.
- **GPS Início** — `GpsBootstrap` no arranque; pull-to-refresh aguarda fix antes do reload; banner inline só se recusar; `adb kill-server` se device não aparecer.
- **Oráculo:** evitar `flutter_animate` + `IntrinsicHeight` dentro de `SingleChildScrollView`.
- **Install bloqueado:** `adb push build/app/outputs/flutter-apk/app-debug.apk` + `adb shell pm install -r -t /data/local/tmp/app-debug.apk`.
- **Dispositivo teste:** `WWZLYDXWYXT8PV5D` · `.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D`.

---

## Notas Mapa — App Flutter

- **Renderer:** `flutter_map ^7.0.2` puro — sem SDK nativo Mapbox (evita ecrã preto em PlatformView nos Xiaomi/MIUI).
- **Tile providers (sem autenticação):**
  - **COSTA/MAR:** `ArcGIS World Imagery` (satélite) + `ArcGIS World Transportation` (estradas, transparente)
  - **RIO/BARRAGEM:** `tile.openstreetmap.org` (topográfico)
  - **Náutico:** `tiles.openseamap.org/seamark` (toggle via botão layers, `_showSeamarks`)
- **URL ArcGIS:** usa `{z}/{y}/{x}` (y antes de x) — diferente do padrão OSM `{z}/{x}/{y}`.
- **Pins custom Canvas** (`_createPinPng` + `_PinKind` enum) — gerados em PNG 96×96 via `PictureRecorder`, cache em `_pinPngCache`:
  - `freeSharkFin` → barbatana ciano + ondas dentro de teardrop
  - `proCrosshair` → crosshair azul `#007BFF` + teardrop
  - `eliteCompassRose` → rosa dos ventos 8 pontas âmbar + glow dourado + teardrop
  - `savedTeardrop` → teardrop vermelho sólido + ponto branco
  - `baitFishingHouse` → casa costeira verde + cana de pesca + anzol + ondas
  - `communityHexAvatar` → cristal hexagonal ciano + silhueta pescador (pronto para foto real P9)
- **Legenda redesenhada:** pill escuro com indicadores coloridos circulares + símbolos (▲⊕✦♦⌂⬡) + labels mono.
- **Onboarding pendente:** usar pins num slide animado "Descobre os Spots" (cada pin cai com bounce + label explicativa → trigger FOMO ELITE).
- **FishingModeStore:** `ValueNotifier<bool>` singleton partilhado com Oráculo; listener em `initState`/`dispose`; `setState(_rioMode)` reconstrói o TileLayer.
- **Zoom:** `initialZoom: 6.5`, `maxZoom: 19.0`.
- **Sheet spots:** `AnimatedContainer` + `ClipRect` (começa fechado).
- **Dispositivo de teste:** `WWZLYDXWYXT8PV5D` (Xiaomi 22031116BG, Android 13); usar `.\tools\run_dev.ps1 -d <id>`.
- **Mapbox SDK** (`mapbox_maps_flutter`) — mantido no `pubspec.yaml` para `MapboxOptions.setAccessToken()` no bootstrap; NÃO usado para rendering.

## Notas Mapbox (Site V2)

- Instância global: `aquaMap3D`
- `bearing: 0` em todos os `easeTo` / `flyTo`
- Centro: `[-8.5, 39.5]`, zoom: `5.5`
- `IntersectionObserver` inicializa quando `#mapa-live` está visível
- **Modo actual:** mapa substituído por imagem estática (`4_spots.png`) — observer desligado

---

## Âncoras principais do Site V2

`#hero` · `#mapa-live` · `#mapa` · `#oraculo` · `#atividade-peixe`
`#ghost` · `#especies` · `#isco-calc` · `#features-all` · `#compare`
`#plans` · `#app-demo` · `#testimonials` · `#waitlist` · `#download`
