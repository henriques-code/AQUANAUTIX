# AQUANAUTIX — Central de contexto

**Última revisão estrutural:** Maio 2026 (alinhar com `lib/screens` + `lib/core`).

## Estrutura do repositório (mono-repo)

```
AQUANAUTIX/
├── lib/                      # App Flutter — main.dart, app.dart, screens/, core/
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
├── tools/                    # Raiz: Flutter/env (`flutter_run_with_env.ps1`, …)
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
- **Ecrãs:** `home` (tabs), `oraculo` (COSTA/RIO, índice, mini-cards, **pesquisa de local Nominatim** para planeamento além do GPS, cartão isco/cana/técnica), `mapa`, `vision`, `logbook`, `perfil`, `paywall`, `splash`, fluxos login/password.
- **`lib/core`:** `OracleDataService` + `lib/core/tides/` (Open‑Meteo, Nominatim search/reverse, cache), `lib/core/l10n/`, espécies/compliance, vision, estado (contexto pesca, subscrição, `app_locale_store`), comunidade (repo/store).
- Design system Midnight Deep Sea (`screens/_shared.dart`).
- Pendente: monetização RC estável em produção, gates PRO/Elite completos; extender i18n a ecrãs fora de Oráculo/Home se o produto o exigir.

## Estado Site V2

- Mapa 3D, spots PT/ES, lojas de isco, Oráculo, waitlist (localStorage-first)
- Pendente: Formspree com endpoint real, restrição de URL do token Mapbox no dashboard

## Próximos passos (sugestão)

1. Batimetria / opacidade terra — afinar se ainda em curso
2. Formspree — endpoint `formspree.io/f/…`
3. RevenueCat — produtos PRO
4. Ecrã monetização Flutter
5. Domínio `aquanautix.com`

## Regras de trabalho

- Não alterar módulos protegidos do site sem **AUTORIZO** explícito (ver `.cursorrules` / `CLAUDE.md`).
- Backup antes de alterações grandes ao `index.html`.
- Após mudanças Flutter relevantes: `flutter analyze`.

## Design system (referência)

- `--bg: #000814` · `--cyan: #00F5FF` · `--amber: #F3C64D` · `--hint: #8AADBE`
- Títulos: Orbitron · Corpo: IBM Plex Sans
