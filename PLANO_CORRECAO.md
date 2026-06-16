# PLANO DE CORRECÇÃO — AQUANAUTIX App Flutter
_Criado: 2026-05-11 · Revisão módulo a módulo · Prioridade decrescente_

---

## Diagnóstico inicial

| Item | Estado |
|---|---|
| `flutter analyze` | 1 warning (cast desnecessário) |
| Dependências desactualizadas | 24 packages com versão superior incompatível |
| Ecrãs com dados demo | Logbook, Perfil, Paywall |
| RevenueCat | Fallback local funcional; produtos reais não configurados |
| Onboarding | Implementado mas integração no arranque por verificar |
| Comunidade | Core preparado; UI não ligada |

---

## MÓDULO 0 — Análise & Dependências
**Prioridade: ANTES DE TUDO**

### Problemas
- [ ] `lib/core/catch_photos/catch_photo_repository.dart:113` — cast desnecessário (`unnecessary_cast`)
- [ ] 24 packages com versão superior — verificar quais actualizar sem breaking changes

### Tarefas
1. Remover cast desnecessário em `catch_photo_repository.dart:113`
2. Correr `flutter pub outdated` e listar os seguros para actualizar
3. Validar `flutter analyze` → 0 issues

---

## MÓDULO 1 — Bootstrap / Main
**Ficheiros:** `main.dart`, `app.dart`, `core/supabase_bootstrap.dart`
**Estado:** ✅ Limpo

### Problemas
- [ ] `initMapboxIfConfigured()` usa Mapbox SDK só para token; confirmar que não falha silenciosamente se token ausente

### Tarefas
1. Adicionar log de debug quando Mapbox token está ausente (apenas `kDebugMode`)
2. Verificar que `FishingContextStore.instance.init()` + `AppLocaleStore.instance.init()` são idempotentes em hot-restart

---

## MÓDULO 2 — Splash & Onboarding
**Ficheiros:** `screens/splash_screen.dart`, `screens/onboarding.dart`, `screens/onboarding/slides/`
**Estado:** 🔄 Implementado; integração com arranque por verificar

### Problemas
- [ ] Verificar se `OnboardingScreen.shouldShow()` é chamado no fluxo de arranque (app.dart / splash)
- [ ] `OnboardingScreen.markDone()` — confirmar que é chamado quando o utilizador completa ou salta o onboarding
- [ ] Slide "Vision Scanner" importa `aquanautix_pins.dart` — verificar que não há erro de inicialização do Canvas antes do `WidgetsFlutterBinding`
- [ ] Verificar que o onboarding não aparece em cada hot-restart em debug (SharedPreferences persiste)

### Tarefas
1. Ler `app.dart` e `splash_screen.dart` e mapear o fluxo splash → onboarding → home
2. Garantir que `onDone` do onboarding chama `markDone()` + navega para `AquanautixHome`
3. Testar caminho: primeiro arranque → onboarding → home → segundo arranque → home directo

---

## MÓDULO 3 — Oráculo
**Ficheiro:** `screens/oraculo.dart`, `screens/widgets/oracle_decisao_fold.dart`, `oracle_conversion_pack.dart`, `oracle_hero_decision.dart`, `oracle_weather_details_grid.dart`, `core/tides/oracle_data_service.dart`, …
**Estado:** ✅ Mockup Decisão + pack conversão PRO (Jun 2026); core funcional + grelha meteorologia 16 cartões

### Concluído (Jun 2026)
- [x] **OracleDecisaoFold** — hero pescador, score pulse, janela âmbar, mini-mapa, espécie alvo, CTAs, GHOST cards, spot PRO
- [x] **Pack conversão PRO** — linha decisão, faixa sticky, drawer trial, blur mapa FREE, CTAs PRO secundários
- [x] Grelha «Detalhes de meteorologia» — 16 cartões brancos, dados Open‑Meteo + marine + AQI
- [x] Cartões Marés (onda isométrica 3D) e Correntes (velocidade/direcção oceânica)
- [x] Pull-to-refresh no Oráculo (`invalidateCache`, `_loadWeatherDetails`)
- [x] `OracleDataService.lastCoords` para meteorologia com GPS ou planeamento Nominatim

### Problemas
- [ ] Detecção de modo rio por string (`ctx.region == 'ABRANTES'`) — frágil se região mudar
- [ ] `_activeSpeciesCodes` é completamente estático e hardcoded por nome de local PT — não cobre ES
- [ ] Banner "Activar alerta" — UI mockup tem «Alertar janela (PRO) · EM BREVE» desactivado; backend push pendente (P5)
- [ ] `_speciesUiLabel` sem tradução ES (Corvina, Sargo, etc. são iguais; Achigã → "Black Bass" em ES)
- [ ] Constantes `_costa` e `_rio` ficam visíveis brevemente antes dos dados reais carregarem — esperado, mas confirmar animação de loading não fica presa

### Tarefas
1. Adicionar enum `FishingRegionType` (`costa` / `rio`) para substituir detecção por string
2. Expandir `_activeSpeciesCodes` com localidades ES (Vigo, Huelva, Cádiz, etc.)
3. Substituir snackbar "em breve" por badge visual `[EM BREVE]` no botão de alertas — **feito no mockup** (`Alertar janela (PRO) · EM BREVE`)
4. Adicionar "Achigã" → "Black Bass" a `_speciesUiLabel` quando locale ES

---

## MÓDULO 4 — Mapa
**Ficheiro:** `screens/mapa.dart`, `core/widgets/aquanautix_pins.dart`, `core/state/fishing_mode_store.dart`
**Estado:** ✅ Funcional

### Problemas
- [ ] Pins gerados em Canvas (`_createPinPng`) — verificar que cache `_pinPngCache` é invalidada se a app reiniciar (não é — é in-memory, correcto)
- [ ] `_showSpotDetail` para spots ELITE mostra paywall — confirmar que `PaywallScreen.open` é chamado correctamente e o mapa não fica em estado de loading
- [ ] Lojas de pesca (≤5 km) usam coordenadas hard-coded? Verificar fonte de dados
- [ ] OpenSeaMap toggle — confirmar que `_showSeamarks` persiste entre navegações de tab (state local em `mapa.dart`; perde-se ao sair do tab porque `_tabCache` desmonta o widget)

### Tarefas
1. Verificar fonte de dados das lojas de isco — hard-coded vs JSON vs Supabase
2. Persistir `_showSeamarks` no `FishingModeStore` ou `SharedPreferences`
3. Testar paywall gate nos spots ELITE no dispositivo real (`WWZLYDXWYXT8PV5D`)

---

## MÓDULO 5 — Vision
**Ficheiro:** `screens/vision.dart`, `core/vision/vision_scan_service.dart`
**Estado:** ✅ Scanner + compliance

### Problemas
- [ ] Chave OpenAI carregada via `--dart-define`? Verificar `core/config/openai_config.dart`
- [ ] Fallback quando API key ausente — confirmar que UI mostra erro amigável e não crash
- [ ] Compliance PT/ES — confirmar que usa locale correcto para determinar limites legais

### Tarefas
1. Ler `vision_scan_service.dart` e verificar tratamento de erro quando API key vazia
2. Confirmar que `species_compliance.dart` selecciona limites PT vs ES baseado no locale/GPS

---

## MÓDULO 6 — Logbook
**Ficheiro:** `screens/logbook.dart`, `core/catch_photos/`
**Estado:** 🔄 UI pronta; persistência ainda em demo

### Problemas
- [ ] Lista `_capturas` é demo hard-coded — não lê do `CatchPhotoRepository`
- [ ] `CatchPhotoRepository` existe mas não está ligado ao Logbook
- [ ] `CatchPhotosStore` existe — confirmar se está inicializado no `main.dart`
- [ ] `AppInsightsService` importado — confirmar que não falha se Supabase não configurado
- [ ] Comunidade (`CommunityStore`) importada mas funcionalidade de partilha é demo

### Tarefas
1. Ligar `CatchPhotosStore` ao ecrã — substituir `_capturas` por `ValueListenableBuilder`
2. Confirmar que `CatchPhotosStore` é inicializado no bootstrap (main.dart)
3. Implementar "Adicionar Captura" real — picker de imagem + form + `CatchPhotoRepository.save()`
4. Guardar peso, espécie, local, data, isco na entrada do logbook

---

## MÓDULO 7 — Perfil
**Ficheiro:** `screens/perfil.dart`
**Estado:** 🔄 UI pronta; dados Supabase não ligados

### Problemas
- [ ] Nome `'João Henriques'` hardcoded — deve vir do `Supabase.instance.client.auth.currentUser`
- [ ] Avatar — sem foto real (ícone placeholder) — ok por agora, mas planeado
- [ ] Logout usa `Supabase` directamente — confirmar que limpa `SubscriptionStore` e `FishingContextStore`
- [ ] Plano de subscrição correctamente lido do `SubscriptionStore` — ✅ `ValueListenableBuilder` presente
- [ ] Falta botão "Gerir subscrição" que abre RevenueCat management URL

### Tarefas
1. Substituir nome hardcoded por `supabaseClient?.auth.currentUser?.email ?? 'Pescador'`
2. No logout: chamar `SubscriptionStore.instance.reset()` se existir, limpar contexto
3. Adicionar botão "Gerir subscrição" com deep link RevenueCat

---

## MÓDULO 8 — Paywall
**Ficheiro:** `screens/paywall.dart`
**Estado:** 🔄 Estrutura correcta; preços inconsistentes

### Problemas
- [ ] **Preços inconsistentes:** `CLAUDE.md` documenta PRO €9.99/mês e ELITE €19.99/mês, mas paywall mostra PRO Anual €39.99 (~€3.33/mês), PRO Mensal €4.99, ELITE Anual €59.99
  - Decisão necessária: manter preços actuais ou alinhar com CLAUDE.md?
- [ ] `'Origem: ${widget.source}'` visível em produção — deve ser removido da UI do utilizador
- [ ] Badge `'Sprint 1 · build de teste'` visível em produção — remover ou gate com `kDebugMode`
- [ ] Trial 3 dias — confirmar configurado no RevenueCat dashboard
- [ ] `_resolvePackage` retorna `null` em produção se `--dart-define REVENUECAT_PACKAGE_*` não fornecido

### Tarefas
1. **Decidir preços finais** e actualizar CLAUDE.md + paywall de forma consistente
2. Remover label "Origem: X" da UI de produção (guard `kDebugMode`)
3. Remover badge "build de teste" ou gate com `kDebugMode`
4. Documentar os 3 `--dart-define` necessários em `tools/run_dev.ps1`

---

## MÓDULO 9 — Auth
**Ficheiros:** `screens/login_module.dart`, `screens/reset_password_screen.dart`
**Estado:** ✅ Funcional (Supabase auth)

### Problemas
- [ ] Verificar que deep link de reset de password está configurado no `AndroidManifest.xml` e `Info.plist`
- [ ] `reset_password_screen.dart` — confirmar que funciona com o scheme Supabase configurado

### Tarefas
1. Testar fluxo completo: registo → login → logout → recuperar password → login
2. Verificar `supabase_bootstrap.dart` para URL scheme de redirect

---

## MÓDULO 10 — Core / Estado
**Ficheiros:** `core/state/`, `core/tides/`, `core/community/`
**Estado:** Maioritariamente funcional

### Problemas
- [ ] `FishingModeStore` — `ValueNotifier<bool>` singleton — confirmar que dispose não é chamado enquanto listeners activos
- [ ] `CommunityStore` / `CommunityRepository` — preparados mas não ligados a nenhuma UI
- [ ] `river_discharge_repository.dart` — SNIRH no roadmap — confirmar que fallback funciona
- [ ] `oracle_data_service.dart` — gestão de erros GPS já feita (`OracleGpsRequiredException`); confirmar timeout adequado

### Tarefas
1. Adicionar `CommunityStore` ao `main.dart` bootstrap se necessário (verificar se inicializa lazy)
2. Confirmar que `FishingModeStore` não tem memory leak (listeners adicionados em `initState` removidos em `dispose`)

---

## MÓDULO 11 — Notificações Push
**Ficheiro:** (não existe ainda como módulo separado)
**Estado:** ❌ Banner demo; infraestrutura não implementada

### Problemas
- [ ] `flutter_local_notifications` está no pubspec mas não há um `NotificationService`
- [ ] Banner "Janela de Ouro PRO" no Oráculo é 100% demo
- [ ] Sem agendamento de notificações

### Tarefas (P2 — após RevenueCat)
1. Criar `core/services/notification_service.dart` com init + schedule
2. Ligar ao Oráculo: quando score > 75 no dia seguinte, agendar notificação
3. Só notificar utilizadores PRO/ELITE (gate em `SubscriptionStore`)

---

## Ordem de execução recomendada

| Sprint | Módulos | Impacto |
|---|---|---|
| **1 — Correcção imediata** | M0 (analyze), M7 (paywall labels debug) | Qualidade build |
| **2 — Dados reais** | M6 (logbook persistência), M7 (perfil Supabase) | Funcionalidade core |
| **3 — Monetização** | M8 (paywall preços + RC keys), M9 (auth deep links) | Revenue |
| **4 — Onboarding** | M2 (fluxo arranque) | Retenção D1 |
| **5 — Polimento** | M3 (oráculo ES), M4 (mapa seamarks persist), M5 (vision erros) | UX |
| **6 — Push** | M11 (notificações) | Engagement |

---

_Este plano é o documento de trabalho. Actualizar cada `[ ]` para `[x]` à medida que as correcções são aplicadas._
