# AQUANAUTIX

**App de pesca desportiva de elite para o mercado ibérico (Portugal + Espanha).**

> Oráculo de previsão · Batimetria GEBCO · Vision Scanner IA · Ghost Mode · Offline-first

Site em produção: [aquanautix.vercel.app](https://aquanautix.vercel.app)

---

## Estrutura do projecto

```
AQUANAUTIX/
├── lib/                          # App Flutter (ecrãs + serviços; ver também AQUANAUTIX_CONTEXT.md)
│   ├── main.dart                 # Bootstrap: analytics, Supabase, stores, orientação
│   ├── app.dart                  # MaterialApp / tema
│   ├── screens/                  # Oráculo, Mapa, Vision, Logbook, Perfil, Paywall, …
│   │   └── widgets/              # Oráculo: aqx_pressable (3D + AqxMeteoRevealButton), decision, conditions_fold, metrics, timeline, community, weather grid, location sheet
│   └── core/                     # analytics, tides, location/gps_access, community, vision, species, state, Supabase
│   # Nota: roadmap histórico previa lib/features/* (auth, prediction, …); o código actual
│   # está maioritariamente em screens/ + core/. Alinhar docs ao abrir PRs de refactor.
├── assets/
│   ├── videos/login_bg.mp4       # Vídeo hero login (Android/iOS)
│   ├── images/login_bg.jpg       # Fallback imagem login
│   ├── icons/fish_silhouette.svg
│   └── data/
├── android/                      # Plataforma Android (gerada)
├── supabase/                     # Backend: migrations SQL + README_setup.md
│   ├── migrations/
│   └── scripts/
├── windows/                      # Plataforma Windows (gerada)
├── Site V2/                      # Site marketing + protótipos
│   ├── index.html                # Landing principal (produção Vercel)
│   ├── app-prototype.html        # Demo interactiva da app (tabs)
│   ├── app-5screens.html         # Mockup 5 ecrãs mobile
│   ├── monetization-prototype.html # Protótipo 5 páginas monetização
│   ├── images/                   # Assets visuais e mockups
│   ├── vercel.json               # cleanUrls: true
│   └── .vercel/                  # Link Vercel CLI
├── pubspec.yaml                  # Dependências Flutter
├── .env                          # Chaves (não versionado)
├── CLAUDE.md                     # Instruções para assistentes IA
└── README.md                     # Este ficheiro
```

---

## Stack técnica

### App Flutter
| Camada | Tecnologia |
|---|---|
| Framework | Flutter (SDK em `pubspec.yaml`, tipicamente Dart ≥3.3) |
| Arquitectura | `lib/screens` + `lib/core` — widgets com estado local, stores / `ValueNotifier` |
| Backend | Supabase (`supabase_flutter`) |
| Mapas | Mapbox Maps Flutter (`mapbox_maps_flutter`, ver `pubspec.yaml`) |
| Marés / tempo / geo | Open‑Meteo via `http`; Nominatim (OSM) para pesquisa de local e reverse geocode |
| Monetização | RevenueCat (`purchases_flutter`) |
| Vision IA | OpenAI (integração em core; Edge Function em roadmap) |
| Networking | `package:http` |
| Analytics | Serviço próprio + Supabase `analytics_events` (ver `lib/core/services/analytics_*.dart`) |
| i18n | `flutter_localizations` · strings PT/ES (`lib/core/l10n/`) · locale por país GPS onde aplicável |

### Site V2
| Camada | Tecnologia |
|---|---|
| Frontend | HTML + CSS + JS puro |
| Mapas | Mapbox GL JS v3.3.0 |
| Solunar | SunCalc |
| Deploy | Vercel (cleanUrls) |

---

## Design System — Midnight Deep Sea

| Token | Valor |
|---|---|
| `--bg` | `#000814` |
| `--bg3` | `#071428` |
| `--cyan` | `#00F5FF` |
| `--amber` | `#F3C64D` |
| `--hint` | `#8AADBE` |

**Tipografia:** Orbitron (títulos) · IBM Plex Sans (corpo) · Share Tech Mono (dados)

---

## Modelo de negócio

| Plano | Preço | Destaques |
|---|---|---|
| **FREE** | €0 para sempre | Oráculo básico · 1 spot · Logbook · IA Visão 2x/mês |
| **PRO** | €4.99/mês ou €39.99/ano (paywall na app; alinhar com lojas) | Oráculo completo · GEBCO · IA · Ghost Mode |
| **ELITE** | €59.99/ano | Tudo PRO + posicionamento premium (ver produto) |

**Trial:** 3 dias PRO na app (estado local + `hasProEntitlement`) · RevenueCat pendente para trial/compra real

---

## Arrancar em desenvolvimento

### Pré-requisitos
- Flutter 3.41.7+ (`C:\src\flutter\bin` ou PATH configurado)
- Android Studio + SDK (para target Android)
- Ficheiro `.env` na raiz com as chaves

### Variáveis de ambiente (`.env`)
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
MAPBOX_ACCESS_TOKEN=pk.eyJ...
MAPBOX_DOWNLOAD_TOKEN=sk.eyJ...
```

### Comandos
```powershell
# Adicionar Flutter ao PATH (sessão actual)
$env:PATH += ";C:\src\flutter\bin"

# Instalar dependências
flutter pub get

# Verificar dispositivos
flutter devices

# Correr no Android físico (recomendado — env + secrets locais)
.\tools\run_dev.ps1 -d <device-id>

# Correr no Windows (limitado: sem Mapbox nem vídeo)
flutter run -d windows

# Analisar código
flutter analyze
```

### Site V2 — servidor local
```powershell
cd "Site V2"
.\_local_server.ps1
# → http://localhost:8080
```

### Site V2 — deploy produção
```powershell
cd "Site V2"
vercel --prod
```

---

## Estado actual (Jun 2026)

### App Flutter
| Feature | Estado |
|---|---|
| Splash animada (AQUANAUTIX emerge) | ✅ Funcional |
| Login / Registo (Supabase Auth) | ✅ Funcional |
| GPS + fallback regional (sem dados demo) | ✅ Banner inline no Início · cache GPS · Open‑Meteo regional |
| Oráculo Sprint 1 + fold condições 12h | ✅ OracleConditionsFold · selector espécie no card isco · CTAs Log/Mapa · botões 3D |
| Oráculo + grelha meteorologia (16 cartões, accordion) | ✅ Open‑Meteo + marine API · AqxMeteoRevealButton |
| Fix MIUI (Início/Oráculo responsivos pós-login) | ✅ Tabs lazy · sem modal GPS automático · layout Oráculo estável |
| Pesquisa local Nominatim (modo planeamento) | ✅ Funcional |
| Calendário solunar | ✅ Estrutura completa |
| Mapa Mapbox + spots | ✅ Android/iOS (sem Windows) |
| Vision Scanner IA | ✅ Estrutura completa |
| Logbook de capturas | ✅ Estrutura completa |
| Compliance PT/ES | ✅ Espécies + medidas legais |
| Perfil + Planos | ✅ UI com preços correctos |
| RevenueCat | 🔄 A configurar produtos |
| Package name | ✅ `com.aquanautix.app` |

### Site V2
| Ficheiro | Estado |
|---|---|
| `index.html` | ✅ Produção — preços actualizados |
| `monetization-prototype.html` | ✅ 5 páginas + hero underwater |
| `app-5screens.html` | ✅ 5 ecrãs mobile mockup |
| `app-prototype.html` | ✅ Demo interactiva |

---

## Próximos passos prioritários

1. **RevenueCat** — configurar produtos PRO (€4.99/mês, €39.99/ano) e ELITE (€59.99/ano)
2. **Push Janela de Ouro** — notificações PRO (UI EM BREVE)
3. **Onboarding Flutter** — ligar `onboarding.dart` ao arranque (primeira vez)
4. **Domínio** — apontar `aquanautix.app` para Vercel

---

## Notas importantes

- `.env` **nunca** vai para git — contém chaves Supabase e Mapbox
- `forceProEntitlement = true` em `subscription_service.dart` — modo dev, desactivar antes de produção
- Mapbox e video_player **não funcionam no Windows desktop** — usar Android/iOS
- Ghost Mode: coordenadas reais nunca saem do dispositivo; fuzzing ~3km em partilhas públicas

---

## Privacidade e compliance

- Spots privados por defeito (Ghost Mode)
- Fuzzing geográfico ~3km em partilhas públicas
- Privacidade diferencial em heatmaps (k-anonimato)
- RGPD compliant (PT + ES)
- Compliance legal PT/ES integrado (tamanhos mínimos, vedas)

---

*AQUANAUTIX — Instrumento de pesca de elite. Feito em Portugal para o mundo.*
