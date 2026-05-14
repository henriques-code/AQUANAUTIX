# AQUANAUTIX - Checklist de Bloqueios para Release

Checklist operacional para fechar o que depende de contas/plataformas externas.

## 1) Google Cloud / Places

- [ ] Projeto Google Cloud criado
- [ ] Billing ativa no projeto
- [ ] Places API (New) ativa
- [ ] API key criada e restrita a Places API (New)
- [ ] `GOOGLE_PLACES_API_KEY` disponível para `flutter run --dart-define=...`

## 2) RevenueCat

- [ ] Produtos criados (PRO mensal/anual, ELITE anual)
- [ ] Entitlement `pro` ligado aos produtos corretos
- [ ] Offering `default` configurada
- [ ] `REVENUECAT_API_KEY_IOS` preenchida
- [ ] `REVENUECAT_API_KEY_ANDROID` validada

## 3) Supabase

- [ ] Edge Functions deployadas (`oracle`, `vision-identify`, `market-recommendations`, `market-track-click`)
- [ ] Variáveis server-side configuradas (`SUPABASE_SERVICE_ROLE_KEY`, `APP_ORIGIN`, `OPENAI_API_KEY`)
- [ ] Smoke tests mínimos das functions executados

## 4) Mapbox

- [ ] Token público restringido a:
  - `https://aquanautix.app/*`
  - `https://www.aquanautix.app/*`
  - `http://localhost:8080/*` (opcional dev)

## 5) Domínio / Vercel

- [ ] `aquanautix.app` ligado ao projeto Vercel
- [ ] `www.aquanautix.app` ligado e a redirecionar para domínio principal
- [ ] DNS resolvido para `76.76.21.21` em `@` e `www`

## 6) Gate final de release app

- [ ] `FORCE_PRO_ENTITLEMENT=false`
- [ ] `flutter analyze` sem erros
- [ ] `flutter test` a passar

