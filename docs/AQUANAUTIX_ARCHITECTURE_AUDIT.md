# AQUANAUTIX — Architecture Audit (Phase 0)

**Data:** 5 Setembro 2026  
**Âmbito:** auditoria do repositório existente. Sem implementação de Affiliate Engine, Content Engine, MCPs novos, alterações à app ou à produção.  
**Método:** leitura do código versionado (`lib/`, `supabase/`, `tools/`, `test/`, docs), `pubspec.yaml`, migrations, Edge Functions e regras Cursor. `Site V2/` está em `.cursorignore`; o estado do site foi cruzado com documentação interna, não com o HTML de produção linha a linha nesta sessão.

**Veredicto:** o projecto **não está vazio**. É um mono-repo de produto real (app Android Flutter + landing + backend Supabase), com dívida documental forte e um motor de afiliados ainda em **mockup**. A plataforma alargada (afiliados, conteúdo, publicação, analytics de receita) **ainda não existe** como sistema; deve ser **sobreposta** à arquitectura actual, não substituí-la.

---

## 1. Stack actual

| Camada | Tecnologia | Notas |
|--------|------------|--------|
| App | Flutter SDK `>=3.3.0 <4.0.0`, Dart, Material 3, tema escuro | `pubspec.yaml` `aquanautix` `1.0.0+1` |
| Estado | `StatefulWidget` + `ValueNotifier` / stores em `lib/core/state/` | Sem BLoC, Riverpod, get_it, Hive, Dio |
| Backend | Supabase (Auth, Postgres + PostGIS, Storage, Edge Functions, RLS) | Cliente `supabase_flutter ^2.12.4` |
| Mapas (app) | `flutter_map` + ArcGIS / OSM / OpenSeaMap | Render real |
| Mapbox (app) | `mapbox_maps_flutter` | Só bootstrap de token — **não** render (MIUI / ecrã preto) |
| Marés / meteo | Open-Meteo (HTTP, sem chave) + Nominatim OSM | Pipeline em `lib/core/tides/` |
| Marés oficiais | Edge Function `oracle-tides` | Porto oficial → fallback FES / cliente Open-Meteo |
| IA Vision | Edge Function `vision-scan` → OpenAI (`gpt-4o` por omissão) | Chave **não** vai no APK |
| Monetização | `purchases_flutter` + `SubscriptionStore` (trial 3 dias local) | Play Console / compras reais **bloqueadas** (P0 humano) |
| Auth social | `google_sign_in` + email/password Supabase | Package `com.aquanautix.app` |
| Notificações | `flutter_local_notifications` + `timezone` | Janela de Ouro **local** (não FCM) |
| i18n | `aqx_l10n.dart` | Login PT/ES/EN; resto PT/ES |
| CI | GitHub Actions `flutter-ci.yml` | `flutter analyze` + `flutter test`; APK debug informativo |
| Website | `Site V2/` HTML/CSS/JS, Mapbox GL JS, SunCalc, Vercel | Protegido: não alterar sem **AUTORIZO** |
| Desktop | pasta `windows/` | Secundário |
| iOS | **Pasta `ios/` ausente no repo** | README ainda lista `ios/` — desactualizado |

Dependências Flutter relevantes: `http`, `image_picker`, `geolocator`, `shared_preferences`, `url_launcher`, `package_info_plus`, `google_fonts`, `flutter_animate`, `video_player`, `share_plus`, `path_provider`.

**Não existe no código:** React app, Node API própria, Amazon Product Advertising API, Creatomate/Remotion, publishers TikTok/Instagram/YouTube, scoring de produtos, state machine de aprovação humana, `AUTO_PUBLISH`, `AMAZON_ASSOCIATE_TAG` centralizado.

---

## 2. Estrutura de directórios

```
AQUANAUTIX/
├── lib/                    # App Flutter (prioridade)
│   ├── main.dart           # Bootstrap
│   ├── app.dart            # MaterialApp
│   ├── screens/            # Ecrãs + widgets Oráculo / Vision / loja mock
│   ├── features/home/      # Dashboard Início (data/domain/presentation)
│   ├── features/community/ # Sheets perfil Ghost
│   └── core/               # Lógica (tides, vision, spots, monetization, …)
├── assets/                 # Espécies, regulamentos GeoJSON, marketing, splash mp4 (gitignored)
├── android/                # Play / MIUI
├── windows/
├── test/                   # 8 ficheiros Dart
├── supabase/
│   ├── migrations/         # 20 ficheiros SQL
│   ├── functions/          # vision-scan, oracle, oracle-tides, RC webhook, sync-tier
│   └── config.toml
├── tools/                  # env, run_dev, sync, Play, hooks
├── Site V2/                # Landing (protegida)
├── prototypes/             # Mockups HTML
├── docs/                   # Só LAUNCH_BETA_PLAN.md
├── Logo Aquanautix/        # Assets de marca
└── docs de raiz            # CLAUDE.md, HANDOFF.md, ECOSYSTEM.md, …
```

`lib/core/` (módulos reais): `affiliate`, `auth`, `catch_photos`, `community`, `config`, `fishing`, `l10n`, `legal`, `location`, `map`, `monetization`, `notifications`, `regulations`, `services`, `species`, `spots`, `state`, `theme`, `tides`, `vision`, `widgets`.

**Afiliados hoje:** um único ficheiro de catálogo demo (`lib/core/affiliate/affiliate_product_catalog.dart`) + ecrã/mockup. **Não** há `affiliate/scoring|providers|links|approvals`.

---

## 3. Arquitectura

### 3.1 Forma actual (produto de pesca)

```
[Android Flutter]
    → GPS (geolocator, workarounds MIUI)
    → Open-Meteo / Nominatim (cliente)
    → flutter_map (tiles públicos)
    → Supabase (anon + JWT utilizador): Auth, Postgres, Storage, Functions
    → RevenueCat SDK (keys públicas goog_/appl_ via --dart-define)
    → Edge: vision-scan (OpenAI), oracle-tides, sync-subscription-tier, revenuecat-webhook
[Site V2]
    → Vercel estático + Mapbox GL + waitlist (Formspree, segundo ECOSYSTEM.md)
```

Não há API Gateway AQUANAUTIX. O “backend” **é** o Supabase.

### 3.2 Separação pedida vs realidade

| Motor conceptual | Estado no repo |
|------------------|----------------|
| APP | Implementada (`lib/`) |
| WEBSITE | Implementada (`Site V2/`), pausa de edição |
| BACKEND | Edge Functions + Postgres; sem serviço Node/Go próprio |
| DATABASE | Supabase Postgres + PostGIS |
| AI SERVICES | Vision via Edge; chat `oracle` órfão; sem `AIProvider` |
| AFFILIATE ENGINE | Mockup UI + lista hardcoded |
| CONTENT ENGINE | Partilha Vision (PNG + `share_plus`); sem scripts/vídeo |
| PUBLISHING ENGINE | Inexistente |
| ANALYTICS | Eventos de produto (`analytics_events`); não métricas de afiliado/receita de conteúdo |

### 3.3 Padrão de estado

Stores globais: `FishingContextStore`, `SubscriptionStore`, `AppLocaleStore`, `HomeTabIndex`, `LogbookTabIndex`, `FishingModeStore`. Só **Início** tem layering Clean-ish. O resto é ecrã + `core/`.

### 3.4 Arranque (`main.dart`)

Mapbox token → Analytics contexto → Supabase (se `--dart-define`) → `app_open` → contexto de pesca → locale → catálogo espécies → RevenueCat → `SubscriptionStore` → notificações Janela de Ouro → prefetch Oráculo → `SplashScreen` → home 7 tabs lazy.

---

## 4. Funcionalidades concluídas (código)

| Área | Evidência |
|------|-----------|
| Shell 7 tabs lazy | `home.dart` `_tabCache` (Início, Oráculo, Mapa, Vision, Log, Perfil, Comunidade) |
| Auth email + Google + reset HTTPS | `login_module.dart`, `password_recovery`, `ResetPasswordScreen` |
| Oráculo (GPS + planeamento Nominatim) | `OracleDataService`, `osm_place_search`, scoring solunar |
| Toggle COSTA/RIO | `FishingModeStore` + `fetchRiver` / caudais |
| Mapa spots + lojas + camadas | `mapa.dart`, repositórios spots/bait_shops, GEBCO WMS, regulamentos GeoJSON, heatmap |
| Blur spots PRO/ELITE (FREE) | `SubscriptionGate` + mapa |
| Vision + compliance catálogo | `VisionScanService` → `vision-scan` + `SpeciesCatalog` |
| Partilha Vision | `VisionShareService` / card / sheet |
| Comunidade Ghost | `community_posts` + zona, nunca lat/lng públicos |
| Catch photos georreferenciadas | `catch_photos` + trigger PostGIS |
| Paywall + gates | `PaywallScreen`, `SubscriptionGate`, trial 3 dias |
| Sync tier servidor | RPC `sync_user_subscription_tier` + Edge `sync-subscription-tier` + webhook RC |
| Analytics funil app | `AnalyticsService` → `analytics_events` |
| Onboarding 1.ª vez | Ligado em `splash_screen.dart` via `OnboardingScreen.shouldShow()` |
| i18n login | PT/ES/EN |
| Loja afiliada (visual) | Drawer + Perfil → `AffiliateShopScreen` (mockup) |
| CI analyze/test | `.github/workflows/flutter-ci.yml` |
| Higiene secrets | `.gitignore`, hook pre-commit, `OPENAI_API_KEY` excluída de dart-define |

---

## 5. Funcionalidades incompletas ou só parciais

| Item | Estado |
|------|--------|
| Compras Play / RevenueCat em produção | Código pronto; **Play Console ~25 USD** e offerings reais pendentes (P0 humano) |
| Assistente IA conversacional (backlog P1) | Eventos analytics `assistant_*`; Edge `oracle` **não** chamada pelo Flutter |
| Vision “loop viral” animado (sprint P2) | Share existe; sprint de animação/confiança 0→% ainda é foco de produto |
| Logbook pessoal | **Só SharedPreferences** `logbook_capturas_v1` — não é tabela Supabase |
| Afiliados reais (Amazon.es, Decathlon, tags, cliques) | Copy no mockup; **zero** links tagged, tracking, aprovações |
| Content / video / publishers | Inexistentes |
| Push remoto (FCM) Janela de Ouro | Só local |
| iOS | Sem projecto `ios/` no repo |
| Domínio `aquanautix.app` | Checklist release; site público documentado como `aquanautix.vercel.app` |
| Google Places / OpenWeather no cliente | Docs antigas; **sem** uso em `.dart` actual |
| Migrations `market_mvp` / `function_rate_limits` | Referidas em checklists; **não** estão em `supabase/migrations/` |
| Edge `vision-identify`, `market-recommendations`, `market-track-click` | Checklists; **não** existem — o Vision real é `vision-scan` |
| Testes (DoD beta: 20/20) | 8 ficheiros; smoke widget mínimo; **sem** testes de scoring afiliado / state machine |
| Documentação `docs/ARCHITECTURE.md` etc. | Pedido da Phase 1 — **ainda não criado** (só este audit + `LAUNCH_BETA_PLAN.md`) |

---

## 6. Supabase

**Projecto documentado:** `ycmvqokcfzxkpinvcyhk.supabase.co`  
**Init cliente:** `String.fromEnvironment('SUPABASE_URL' | 'SUPABASE_ANON_KEY')`. Sem chaves → modo convidado (`canUseSupabase == false`).

### 6.1 Tabelas / objectos (migrations presentes)

| Domínio | Objectos |
|---------|----------|
| Insights | `app_insights`, `app_insights_v2` |
| Perfis / Ghost | `user_profiles`, `community_posts`, `community_reactions` |
| Capturas foto | `catch_photos` + geometry + lat/lng trigger |
| Analytics | `analytics_events` (+ abuse guard Set 2026) |
| Mapa | `fishing_spots`, `bait_shops` + RLS por tier |
| Monetização | `sync_user_subscription_tier` (SECURITY DEFINER, pensado para service_role / Edge) |
| Storage | buckets `catch-photos`, `community-photos`; hardening listing |
| PostGIS | RPC hardening / `st_estimatedextent` |

**Não há** tabelas `affiliate_products`, `content_pieces`, `publish_jobs`, `content_analytics`.

### 6.2 Edge Functions (repo)

| Função | JWT (`config.toml`) | Papel |
|--------|---------------------|--------|
| `vision-scan` | `verify_jwt = false` | OpenAI visão; **risco de custo** se URL for conhecida |
| `oracle` | `verify_jwt = true` | Chat OpenAI; **órfã** no cliente Flutter |
| `oracle-tides` | `verify_jwt = false` | Agregação marés (serviço público-like) |
| `sync-subscription-tier` | `verify_jwt = true` | Lê RC server-side, escreve tier |
| `revenuecat-webhook` | `verify_jwt = false` (webhook) | Auth por header partilhado |

### 6.3 RLS / segurança de dados (já correcta na app)

- Cliente **nunca** deve actualizar `user_profiles.tier` directamente.
- Feed público usa `zone_label`, não coordenadas exactas.
- Logbook pessoal **não** está no backend (inconsistência de “captura”).

**Regra desta auditoria:** **não substituir** Supabase. Qualquer Affiliate/Content Engine deve ser **migrations novas** + RLS, nunca schema paralelo sem confirmação.

---

## 7. APIs

| API | Onde | Auth |
|-----|------|------|
| Open-Meteo forecast/marine | Cliente Flutter | Nenhuma |
| Nominatim search/reverse | Cliente Flutter | User-Agent; ~1 req/s |
| OpenAI Chat Completions | Edge `vision-scan`, `oracle` | `OPENAI_API_KEY` no ambiente da função |
| RevenueCat SDK | App | SDK key pública `goog_` / `appl_` |
| RevenueCat REST | Edge webhook / sync-tier | Secret só servidor |
| Supabase PostgREST / Auth / Storage / Functions | App + Edge | anon + user JWT; service_role só Edge |
| Tiles ArcGIS / OSM / OpenSeaMap / GEBCO WMS | App mapa | Públicas |
| Formspree | Site (docs) | Endpoint público waitlist |
| Amazon PA-API / Associates | — | **Não integrado** |

Não há scraping Amazon no código. Qualquer integração futura deve ser `AmazonProvider` **autorizado**, não scraping.

---

## 8. Autenticação

- Supabase Auth: email/password, Google Sign-In, PKCE, `detectSessionInUri`.
- Recuperação: `SUPABASE_RESET_REDIRECT` (default `https://aquanautix.vercel.app/reset-password`).
- `LoginSessionStore`: “lembrar-me” + email local.
- `user_profiles` criado de forma lazy (sync de tier / primeiro post), não obrigatoriamente no signup.
- Sessão guest: app corre sem Supabase (Oráculo/Mapa com APIs públicas; Vision e Comunidade reais degradam).

---

## 9. Secrets e variáveis de ambiente

**Mecanismo real (2026):** `.env` na raiz (gitignored) + opcional `tools/local_secrets.ps1` → `tools/run_dev.ps1` / `run_dev.sh` injectam **`--dart-define`**. **Não** há `flutter_dotenv` no `pubspec.yaml` (ECOSYSTEM.md está errado neste ponto).

**Entram na app (ENV_CORE + opcionais RC):**

- `MAPBOX_ACCESS_TOKEN`
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `SUPABASE_RESET_REDIRECT`
- `REVENUECAT_API_KEY_ANDROID` / `_IOS`
- entitlements e package IDs RC

**Não entram no APK (correcto):**

- `OPENAI_API_KEY` (só secret Edge / bootstrap local)
- `SUPABASE_ACCESS_TOKEN` (CLI)
- `SUPABASE_SERVICE_ROLE_KEY`
- `REVENUECAT_SECRET_API_KEY`, `REVENUECAT_WEBHOOK_AUTHORIZATION`

**Ausente (a criar na Phase 1, centralizado, não espalhado):**

- `AMAZON_MARKETPLACE`, `AMAZON_ASSOCIATE_TAG`
- `AUTO_PUBLISH`, `PUBLISHING_MODE`
- config de video/publisher providers

**Riscos documentados (não revalidados no HTML nesta sessão):** token Mapbox no JS do site; restringir no dashboard Mapbox. Anon key no cliente é esperado (RLS é a defesa).

**Esta auditoria não lê nem cita `.env`.**

---

## 10. OpenAI / Vision

**Fluxo actual:** foto (`image_picker`, compressão) → `VisionScanService.analyzeImageBytes` → `functions.invoke('vision-scan')` → JSON `{scientific_name, length_cm, weight_kg, confidence_0_100}` → match `SpeciesCatalog` → compliance PT/ES.

**Segurança:** chave OpenAI só no servidor. `response_format: json_object` + parse defensivo. Sem `AIProvider` / Claude adapter.

**Lacunas:** `verify_jwt = false` em `vision-scan`; CORS `*`; sem rate limit visível no TS; modelo via `OPENAI_CHAT_MODEL` ou `gpt-4o` (custo). Estimativas de peso/comprimento são **inferência do modelo**, não medição AR (P15).

**Chat:** `supabase/functions/oracle/index.ts` é protótipo P1; comentário no código confirma que o Flutter **não** a invoca.

Não existe `lib/core/config/openai_config.dart` (ainda referido em `PLANO_CORRECAO.md`).

---

## 11. Mapbox

- App: `mapbox_config.dart` — token compile-time; `initMapboxIfConfigured()`; **mapa visível = flutter_map**.
- Download token (`MAPBOX_DOWNLOADS_TOKEN` / `MAPBOX_DOWNLOAD_TOKEN`) para builds nativos SDK, não para tiles OSM.
- Site: Mapbox GL JS (documentação); instância `aquaMap3D`; restrições de URL recomendadas no checklist de release.

Não duplicar Mapbox como renderer da app sem resolver MIUI.

---

## 12. Frontend (app)

- Tema Midnight Deep Sea (`app_colors`, `_shared.dart`).
- Navegação: 7 tabs; **não** usar `IndexedStack` com todos os ecrãs (bloqueio MIUI).
- Dispositivo de teste documentado: Xiaomi `WWZLYDXWYXT8PV5D`.
- Design/UI: regra de projecto — **sem alteração visual sem AUTORIZO**.
- Loja afiliada: UI mock + banner “em desenvolvimento”; grelha de produtos Unsplash/assets; **sem** `url_launcher` para ASIN.

---

## 13. Backend

Backend = Supabase. Observabilidade: `debugPrint` analytics; Edge `console.error` sem dumps de chave (bom). Não há logging estruturado com `correlation_id` transversal app↔edge.

Não existe worker de conteúdo, fila de publicação, nem cache de respostas LLM para produtos.

---

## 14. Website

- Pasta `Site V2/`, deploy Vercel `aquanautix.vercel.app`.
- Papel: marketing, waitlist, ponte reset-password, protótipos.
- **Não** é o runtime do Affiliate/Content Engine.
- Regras: módulos protegidos (`handleWaitlist`, `calcularOraculo`, `initMapbox`, `SPOTS[]`, …). Phase 1 **não** deve editar o site.

---

## 15. Problemas encontrados

1. **Documentação divergente do código** — `ECOSYSTEM.md`, `SECURITY_DEPLOY_CHECKLIST.md`, `supabase/README_setup.md`, `README.md`, `PLANO_CORRECAO.md` descrevem `flutter_dotenv`, `vision-identify`, pasta `functions/` ausente, 9 migrations, OpenWeather/Places, Comunidade “não ligada”. O código já passou esse estado.
2. **`vision-scan` sem JWT** — qualquer cliente com anon key (ou abuso se a função for invocável sem sessão) pode gastar OpenAI.
3. **Dois modelos de “captura”** — logbook local vs `catch_photos` / `community_posts`.
4. **Afiliados: copy vs capacidade** — UI promete Decathlon/Amazon; catálogo sem URLs, ASIN, tag, scores, estados.
5. **Checklists de “market MVP”** apontam para schema/functions que **nunca foram versionados**.
6. **Edge `oracle` órfã** — superfície OpenAI extra se deployada.
7. **Testes fracos** relativamente ao DoD de beta.
8. **Sem `ios/`** — iOS não é um alvo compilável neste clone.
9. **P0 receita** depende de conta Play, não de mais código de compra.
10. **Handoff/contexto** com datas Jun/Jul 2026 e branches antigas — risco de agentes “corrigirem” o que já está feito.

---

## 16. Riscos

| Risco | Severidade | Notas |
|-------|------------|--------|
| Custo OpenAI (Vision / oracle) | Alta | JWT off no Vision; sem quota por user visível no código |
| Escalação de tier | Mitigado | RPC + Edge + RLS; não reabrir escrita de `tier` no cliente |
| Privacidade spots | Mitigado se se seguir Ghost | Não guardar lat/lng em conteúdo público |
| Token Mapbox no site | Média | Restringir URLs |
| Play billing não testado | Alta para receita app | Gates usam trial local + RC se keys existirem |
| Scraping Amazon “para preencher catálogo” | Alta legal | **Proibido** nesta arquitectura |
| Publicação automática redes | Alta reputação/compliance | `AUTO_PUBLISH=false` obrigatório na fase experimental |
| Substituir Flutter/Supabase | Existencial | Destrói o produto actual |
| Secrets em docs/git | Processo | Hooks existem; nunca citar valores |

---

## 17. Dívida técnica

- Docs e checklists não actualizados após Vision Edge, 20 migrations, functions no repo.
- Arquitectura híbrida: Início “clean”, resto monolítico em screens.
- `flutter_animate` ainda na app — perigoso no Oráculo (histórico ecrã preto MIUI).
- Analytics de produto sem dashboards de receita de afiliados.
- Sem abstracções `AIProvider` / `VideoProvider` / `Publisher` / `AmazonProvider`.
- Sem cache de resultados LLM.
- Asset `video_bg.mp4` gitignored — CI gera placeholder.
- Duplicados de marca (`Logo Aquanautix - Cópia`).
- Regras Cursor: sync/secrets/backlog fortes; **falta** regra afiliados/conteúdo/segurança de publicação (Phase 1).

---

## 18. Recomendações (sem implementar agora)

1. **Manter** Flutter + Supabase + Edge como backend. Phase 1 = contratos e pastas `docs/` + `.cursor/rules/` pequenas, não rewrite.
2. **Corrigir docs** na Phase 1 (ECOSYSTEM, SECURITY checklist, README supabase) para nomes reais: `vision-scan`, lista de functions, dart-define.
3. **Antes do motor de afiliados:** endurecer `vision-scan` (`verify_jwt=true` + auth app) — é segurança/custo, não feature nova de conteúdo.
4. **Afiliados:** schema novo no Supabase + serviço server-side; app só consome produtos `APPROVED` / `READY_TO_PUBLISH`; mockup actual pode permanecer até haver dados.
5. **Amazon:** um módulo de config (`AMAZON_MARKETPLACE=ES`, tag Associates) + `AmazonProvider` stub; zero scraping.
6. **State machine humana** no backend; `AUTO_PUBLISH=false`; `PUBLISHING_MODE=MANUAL`.
7. **Scoring 100 pts** em Dart ou SQL **testável**, com campos FACT / INFERENCE / ESTIMATE — nunca “em alta” sem evidência.
8. **Não instalar MCPs** extra até um caso de uso (ex.: só se um publisher oficial o exigir). Cursor já tem Supabase/Vercel/etc.; Zapier não é necessário para Phase 1.
9. **Não** abrir Site V2, P1 chat IA, P16 spots IA, nem compras Play novas neste trilho até autorização.
10. **Testes** na primeira lógica crítica: scoring, validação de links tagged, transições de estado, fórmulas CTR/EPC.

---

## 19. Roadmap (alinhado ao pedido; não saltar fases)

| Fase | Objectivo | Relação com o repo actual |
|------|-----------|---------------------------|
| **0 AUDIT** | Este documento | Feito |
| **1 ARCHITECTURE** | Contratos, docs `docs/*`, rules Cursor, config central, esboço pastas `affiliate/` `content/` **sem** ligar produção | Sobrepor; não apagar `lib/core/affiliate` mock |
| **2 AFFILIATE ENGINE** | Modelo produto, scoring, AmazonProvider stub, migrations, RLS | Novo schema; UI mock pode ler API depois |
| **3 CONTENT ENGINE** | Objecto conteúdo PT-PT, hooks/scripts, `AIProvider` | Edge nova; validar JSON Schema; cache |
| **4 HUMAN APPROVAL** | Estados DISCOVERED → ARCHIVED | Nenhuma publicação sem humano |
| **5 VIDEO GENERATION** | `VideoProvider` + adapters vazios | Sem lock-in Creatomate |
| **6 ANALYTICS** | Impressions → commission, CTR, CR, EPC, RPM | Separar de `analytics_events` da app ou namespaced |
| **7 DRAFT PUBLISHING** | `Publisher` + drafts manuais | `PUBLISHING_MODE=DRAFT` |
| **8 AUTOMATED PUBLISHING** | Só com flag explícita | Default `AUTO_PUBLISH=false` |
| **9 OPTIMIZATION** | Custo LLM, scoring, receita | Depois de dados reais |

**Justificação para não saltar:** o mock de loja não tem dados nem aprovação; publicar ou gerar vídeo agora seria teatro e risco de compliance.

---

## 20. Proposta de integração do Affiliate Engine (só desenho)

**Princípio:** o motor vive **ao lado** da app de pesca, no mesmo Postgres, com RLS. A app Flutter continua a ser o produto; a loja passa de catálogo estático a **vista** de produtos aprovados.

```
[Discovery job / humano]
    → AmazonProvider (API autorizada) | import CSV
    → products (status=DISCOVERED)
    → scoring (FACT vs ESTIMATE)
    → PENDING_PRODUCT_APPROVAL
    → [humano] APPROVED | REJECTED
    → Content Engine (mais tarde)
    → PENDING_CONTENT_APPROVAL → …
    → Publisher (MANUAL)
[Flutter AffiliateShop]
    → SELECT produtos APPROVED/READY (nunca rascunhos)
    → abre affiliate_url já tagged (gerado no servidor)
[Analytics]
    → clicks/orders/commission (receita), não só views
```

**Pastas conceptuais (Phase 1, ainda sem código de negócio):**

- `affiliate/products|scoring|providers|links|approvals|analytics`
- Config única: marketplace ES, associate tag, `AUTO_PUBLISH=false`
- App: manter `AffiliateProductCatalog` como fallback offline até a API existir
- **Não** misturar com `analytics_events` de funil Oráculo/paywall sem prefixo de domínio (`affiliate_*`)

**Fora de Phase 1:** implementação de scoring, migrations de produtos, MCPs, mudanças de UI da loja (precisam AUTORIZO de design).

---

## MCP (avaliação — não instalar)

Nenhum MCP adicional é necessário para Phase 1. Os conectores já presentes no Cursor (Supabase, Vercel, etc.) bastam para ops. Critério futuro: finalidade, permissões, dados, risco, custo, alternativa simples — **reavaliar só na Phase 7+** se um publisher oficial o exigir.

---

## READY FOR PHASE 1: **YES**

**Sim** para Phase 1 = **arquitectura e documentação**, com estas condições:

- Não substituir Flutter, Supabase, Vision actual, nem o Site V2.
- Não implementar ainda Affiliate/Content/Video/Publishers.
- Não alterar produção nem criar migrations de produtos sem autorização explícita da Phase 2.
- Tratar o P0 Play Console como bloqueio **humano**, paralelo, não como desculpa para adiar contratos de afiliados.
- Primeiro entregável da Phase 1 (quando autorizado): `docs/ARCHITECTURE.md`, `AFFILIATE_ENGINE.md`, `CONTENT_ENGINE.md`, `PUBLISHING.md`, `ANALYTICS.md`, `SECURITY.md`, `ROADMAP.md` + regras Cursor **pequenas** (arquitectura, afiliados, conteúdo, segurança) — sem código de app.

Phase 0 (esta auditoria) está **completa**. Aguardar autorização para a Phase 1.
