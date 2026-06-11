# AQUANAUTIX

**App de pesca desportiva de elite para o mercado ibérico (Portugal + Espanha).**

> Oráculo de previsão · Mapa costeiro · Vision Scanner IA · Ghost Mode · Comunidade anónima

Site em produção: [aquanautix.vercel.app](https://aquanautix.vercel.app)

**Última revisão doc:** 11 Jun 2026 · app `da3ca79` · 7 tabs (incl. Comunidade)

---

## Estrutura do projecto

```
AQUANAUTIX/
├── lib/                          # App Flutter
│   ├── main.dart                 # Bootstrap: Supabase, Mapbox token, RevenueCat, analytics
│   ├── app.dart                  # MaterialApp / tema Midnight Deep Sea
│   ├── screens/                  # home (7 tabs), oraculo, mapa, vision, logbook, perfil, comunidade, …
│   │   └── widgets/              # Oráculo: decision, conditions_fold, metrics, timeline, weather grid
│   ├── features/
│   │   ├── home/                 # Início dashboard (data/domain/presentation)
│   │   └── community/            # Sheet perfil Ghost
│   └── core/                     # tides, location, community, vision, species, Supabase, l10n
├── assets/
│   ├── video_bg.mp4              # Splash / login
│   ├── marketing/spots/          # Cabo Espichel, Peniche, Sesimbra
│   ├── marketing/catches/        # Fotos espécies (demo comunidade)
│   ├── data/species_ibero.json
│   └── icons/
├── android/ · ios/ · windows/    # Plataformas
├── supabase/                     # Migrations SQL (8) + README_setup.md
├── Site V2/                      # Site marketing Vercel (NÃO alterar sem AUTORIZO)
├── tools/                        # run_dev.ps1, sync_check.ps1, install_git_hooks.ps1
├── AQUANAUTIX_CONTEXT.md         # Contexto técnico detalhado
├── CLAUDE.md                     # Instruções IA
├── ECOSYSTEM.md                  # Serviços, env, sincronização
├── HANDOFF.md                    # Prompt para novos chats
└── README.md                     # Este ficheiro
```

---

## Stack técnica

### App Flutter
| Camada | Tecnologia |
|---|---|
| Framework | Flutter SDK ≥ 3.3 (`pubspec.yaml`) |
| Arquitectura | `screens/` + `core/` + `features/home|community/` · StatefulWidget + ValueNotifier |
| Backend | Supabase (`supabase_flutter`) — Auth, Postgres, Storage |
| Mapas (render) | **`flutter_map`** — ArcGIS satélite, OSM, OpenSeaMap (`mapa.dart`) |
| Mapbox SDK | Só `MapboxOptions.setAccessToken()` no bootstrap — **não** usado para render (MIUI) |
| Marés / tempo | Open‑Meteo + Nominatim (`lib/core/tides/`) |
| GPS | `geolocator` — `gps_access.dart`, `gps_bootstrap.dart` (MIUI-safe) |
| Monetização | RevenueCat (`purchases_flutter`) — parcial |
| Vision IA | OpenAI via core (roadmap: Edge Function) |
| i18n | Login PT/ES/EN · resto app PT/ES |

### Site V2
HTML + CSS + JS · Mapbox GL JS v3.3.0 · SunCalc · Deploy Vercel (`Site V2/`)

---

## Navegação da app (7 tabs)

| # | Tab | Ecrã |
|---|-----|------|
| 0 | INÍCIO | Dashboard: tempo, maré, spots, preview comunidade |
| 1 | ORÁCULO | Score, condições 12h, meteorologia, planeamento |
| 2 | MAPA | Spots PT/ES, `flutter_map`, batimetria |
| 3 | VISION | Scanner IA espécies |
| 4 | LOG | Logbook capturas |
| 5 | PERFIL | Conta, planos PRO/ELITE |
| 6 | COMUN. | Feed Ghost · perfis públicos sem coords |

Tabs **lazy** (`_tabCache` em `home.dart`) — uma tab montada de cada vez (fix MIUI).

---

## Design System — Midnight Deep Sea

| Token | Valor |
|---|---|
| `--bg` | `#000814` |
| `--cyan` | `#00F5FF` |
| `--amber` | `#F3C64D` |
| `--hint` | `#8AADBE` |

**Tipografia:** Orbitron · IBM Plex Sans · Share Tech Mono

---

## Modelo de negócio

| Plano | Preço | Destaques |
|---|---|---|
| **FREE** | €0 | Oráculo básico · Logbook · Vision limitado |
| **PRO** | €4.99/mês ou €39.99/ano | Oráculo completo · Ghost · spots PRO |
| **ELITE** | €59.99/ano | Tudo PRO + posicionamento premium |

**Trial:** 3 dias PRO (estado local) · RevenueCat pendente para compra real

---

## Arrancar em desenvolvimento

### Pré-requisitos
- Flutter 3.x+ no PATH
- Android SDK (dispositivo físico recomendado — MIUI)
- `.env` na raiz + opcional `tools/local_secrets.ps1`

### Comandos
```powershell
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"

flutter pub get
flutter analyze

# Dispositivo teste Xiaomi
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
```

### Supabase (backend)
```powershell
supabase link --project-ref ycmvqokcfzxkpinvcyhk
supabase db push
```

### Site V2
```powershell
cd "Site V2"
.\_local_server.ps1          # http://localhost:8080
vercel --prod                # aquanautix.vercel.app
```

---

## Estado actual (Jun 2026)

| Feature | Estado |
|---|---|
| 7 tabs + Comunidade Ghost | ✅ |
| Início GPS + pull-to-refresh | ✅ MIUI testado |
| Oráculo Sprint 1 + fold 12h | ✅ |
| Mapa flutter_map + spots | ✅ |
| Vision Scanner | ✅ |
| Logbook | ✅ |
| Login Supabase + Google | ✅ |
| i18n login PT/ES/EN | ✅ |
| RevenueCat gates reais | 🔄 |
| Push Janela de Ouro | 🔄 EM BREVE |
| Onboarding 1.ª vez | 🔄 |
| Site V2 vs app 7 tabs | ⏸️ Protótipos desalinhados (normal) |

---

## Documentação

| Ficheiro | Conteúdo |
|----------|----------|
| [AQUANAUTIX_CONTEXT.md](AQUANAUTIX_CONTEXT.md) | Histórico sessões, ficheiros, decisões |
| [CLAUDE.md](CLAUDE.md) | Regras engenharia + estado MIUI |
| [ECOSYSTEM.md](ECOSYSTEM.md) | Serviços, `.env`, matriz sincronização |
| [HANDOFF.md](HANDOFF.md) | Prompt copy-paste para novos chats |
| [supabase/README_setup.md](supabase/README_setup.md) | Migrations e buckets |

---

## Privacidade

- Ghost Mode: coordenadas exactas nunca em feed público (`zone_id` ~5 km)
- Compliance PT/ES: tamanhos mínimos e vedas (`species_ibero.json`)
- `.env` nunca vai para Git

---

*AQUANAUTIX — Instrumento de pesca de elite. Feito em Portugal para o mundo.*
