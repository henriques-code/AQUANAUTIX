# AQUANAUTIX — Central de contexto

**Última revisão estrutural:** 18 Mai 2026 — sessão Home: solunar badge, pressão, direcção vento, nome utilizador.

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
- **Ecrãs:** `home` (tabs; WeatherCard com solunar badge, saudação personalizada com nome Supabase), `oraculo` (COSTA/RIO, índice, mini-cards, **pesquisa de local Nominatim** para planeamento além do GPS, cartão isco/cana/técnica), `mapa`, `vision`, `logbook`, `perfil`, `paywall`, `splash`, fluxos login/password.
- **`lib/core`:** `OracleDataService` + `lib/core/tides/` (Open‑Meteo, Nominatim search/reverse, cache), `lib/core/l10n/` (AqxL10n completo — PT/ES — cobre Oráculo, Home, Mapa), espécies/compliance, vision, estado (contexto pesca, subscrição, `app_locale_store`), comunidade (repo/store).
- Design system Midnight Deep Sea (`screens/_shared.dart`).
- **`lib/features/home/`:** arquitectura feature-first (data/domain/presentation); `WeatherData` com `solunarScore`; `HomeRepositoryImpl` usa `moonFishingFactor` + nome real do utilizador via Supabase metadata.
- Pendente: monetização RC estável em produção, gates PRO/Elite completos; extender i18n a ecrãs fora de Oráculo/Home se o produto o exigir.

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
- `google_sign_in: ^6.2.1` (resolvido como 6.3.0)
- `crypto: ^3.0.3` (resolvido como 3.0.7 — transitivo, mantido)

**Atenção**
- `android/app/google-services.json` é uma **pasta vazia** criada por engano — deve ser substituída pelo ficheiro JSON real do Firebase/Google Cloud Console e adicionada ao `.gitignore`

## Estado Site V2

- Mapa 3D, spots PT/ES, lojas de isco, Oráculo, waitlist (localStorage-first)
- Pendente: Formspree com endpoint real, restrição de URL do token Mapbox no dashboard

## Próximos passos (sugestão)

1. **Google Sign-In** — testar em dispositivo com SHA-1 registado; confirmar login end-to-end
2. **`google-services.json`** — substituir pasta por ficheiro JSON real; adicionar ao `.gitignore`
3. **RevenueCat** — configurar produtos PRO/ELITE no dashboard e testar gates
4. **Onboarding Flutter** — ecrãs de boas-vindas pós-login
5. Formspree — endpoint `formspree.io/f/…`
6. Domínio `aquanautix.app`

## Regras de trabalho

- Não alterar módulos protegidos do site sem **AUTORIZO** explícito (ver `.cursorrules` / `CLAUDE.md`).
- Backup antes de alterações grandes ao `index.html`.
- Após mudanças Flutter relevantes: `flutter analyze`.

## Design system (referência)

- `--bg: #000814` · `--cyan: #00F5FF` · `--amber: #F3C64D` · `--hint: #8AADBE`
- Títulos: Orbitron · Corpo: IBM Plex Sans
