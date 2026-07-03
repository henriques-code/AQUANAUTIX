# AQUANAUTIX — Plano de Fecho Beta → Play Store

**Versão:** 1.0 · **Data:** Julho 2026  
**Objectivo:** Fechar o ciclo técnico e comercial até **beta fechado testável**, sem custos de loja até fase P1.  
**Responsável:** Engenharia AQUANAUTIX · **App ID:** `com.aquanautix.app`

---

## Resumo executivo

| Fase | Nome | Estado alvo | Pagamento |
|------|------|-------------|-----------|
| **P0** | Consolidação código | `main` = P5 + webhook tier | Grátis |
| **P1** | Segurança & compliance app | Legal, permissões, verify script | Grátis |
| **P2** | Config remota (secrets) | Supabase + RC webhook | Grátis* |
| **P3** | Play Console & billing | Internal testing + compra teste | **€25 + subscrições** |
| **P4** | Beta fechado | 10–20 testers, métricas D7 | Grátis |
| **P5** | Produção Play Store | AAB, Data Safety, screenshots | Incluído em P3 |

\*Requer chaves RC/Supabase já existentes — sem taxa adicional.

---

## Definition of Done — Beta fechado

- [ ] `main` contém P5, webhook tier, legal links, permissões limpas
- [ ] `flutter analyze` → 0 issues · `flutter test` → 16/16
- [ ] `./tools/launch_beta_verify.sh` → verde
- [ ] Webhook RC configurado + teste manual de tier em `user_profiles`
- [ ] Internal testing Play com compra license tester (quando P3)
- [ ] 10 testers com retenção D1 medida (Oráculo ou Mapa abertos)

---

## P0 — Consolidação código (SEM CUSTO)

**Objectivo:** Uma única fonte de verdade no Git.

| # | Tarefa | Critério | Estado |
|---|--------|----------|--------|
| 0.1 | Merge `feat/p5-golden-window-push` | Home v2, P5 push, RLS spots, 53 spots | ✅ PR #11 |
| 0.2 | Webhook RevenueCat → `user_profiles.tier` | Edge Functions + migration | ✅ PR #12 |
| 0.3 | Branch `cursor/launch-beta-close-a1c8` → `main` | Um PR consolidado | 🔄 |
| 0.4 | `flutter analyze` + `flutter test` | Verde | 🔄 |

**Entregável:** PR único para `main` com todo o trabalho P5 + monetização backend.

---

## P1 — Segurança & compliance app (SEM CUSTO)

**Objectivo:** App aceitável para revisão Google (pré-requisitos sem pagar).

| # | Tarefa | Critério | Estado |
|---|--------|----------|--------|
| 1.1 | Remover `RECORD_AUDIO` do manifest | Permissão não usada eliminada | 🔄 |
| 1.2 | Links Privacidade + Termos no login | Footer com `url_launcher` | 🔄 |
| 1.3 | Secção legal no Perfil | Abrir documentos in-app | 🔄 |
| 1.4 | Script `tools/launch_beta_verify.sh` | Auditoria automática pré-build | 🔄 |
| 1.5 | Documentar assets em falta | Lista em `assets/README.md` | 🔄 |

**Adiado (pós-beta, sem custo imediato):**
- Storage privado + signed URLs (fotos)
- Edge Function Vision (OpenAI server-side)
- Remover opção «Amigos» em privacidade até RLS implementada

---

## P2 — Configuração remota (SEM CUSTO — manual)

**Objectivo:** Backend alinhado com monetização.

| # | Tarefa | Onde | Estado |
|---|--------|------|--------|
| 2.1 | Secret `REVENUECAT_SECRET_API_KEY` | Supabase → Edge Functions → Secrets | ⏳ manual |
| 2.2 | Secret `REVENUECAT_WEBHOOK_AUTHORIZATION` | Idem | ⏳ manual |
| 2.3 | Webhook URL no RevenueCat | `…/functions/v1/revenuecat-webhook` | ⏳ manual |
| 2.4 | Teste: compra sandbox → `user_profiles.tier = PRO` | SQL Editor ou app Mapa | ⏳ após P3 |
| 2.5 | Verificar migrations remotas = repo (16) | `supabase migration list` | ✅ |

**Guia:** `REVENUECAT_SETUP.md` secção 8.

---

## P3 — Play Console & billing (REQUER PAGAMENTO)

> **BLOQUEADO até autorização de pagamento** — taxa única Google Play Developer **$25** + perfil de pagamentos.

| # | Tarefa | Referência |
|---|--------|------------|
| 3.1 | Conta Google Play Developer | play.google.com/console |
| 3.2 | Perfil de pagamentos activo | Play Console → Configuração |
| 3.3 | 3 subscrições (`aquanautix_pro_monthly`, `_pro_annual`, `_elite_annual`) | `tools/PLAY_CONSOLE_SETUP.md` |
| 3.4 | Keystore release + `android/key.properties` | `tools/play_signing_fingerprints.ps1` |
| 3.5 | AAB → faixa **Internal testing** | Obrigatório para billing real |
| 3.6 | Service account Google → RevenueCat | `REVENUECAT_SETUP.md` |
| 3.7 | License testers + compra €0 no Xiaomi | `WWZLYDXWYXT8PV5D` |
| 3.8 | SHA-1 registado (Google Sign-In) | Google Cloud Console |

**Critério E2E:** Compra teste → tier PRO na BD → spots PRO visíveis via API → mapa desbloqueado.

---

## P4 — Beta fechado (SEM CUSTO)

**Objectivo:** Validar produto antes de produção pública.

| # | Tarefa | Métrica |
|---|--------|---------|
| 4.1 | Lista 10–20 pescadores PT/ES | Google Groups ou Firebase App Distribution |
| 4.2 | Onboarding completo | >80% completam 6 slides |
| 4.3 | Primeira sessão Oráculo | >70% abrem tab Oráculo |
| 4.4 | Retenção D7 | >30% voltam à app |
| 4.5 | Crash-free sessions | >99% (Firebase Crashlytics opcional) |
| 4.6 | Feedback NPS informal | 3 perguntas no Perfil (futuro) |

**Duração sugerida:** 2–4 semanas de beta antes de produção.

---

## P5 — Produção Play Store (APÓS P3 + P4)

| # | Tarefa |
|---|--------|
| 5.1 | Ficha loja PT + ES (título, descrição, keywords) |
| 5.2 | Screenshots 6.5" + feature graphic 1024×500 |
| 5.3 | Data Safety form (localização, fotos, compras) |
| 5.4 | Política privacidade URL pública (domínio `aquanautix.app` ou Vercel) |
| 5.5 | Classificação conteúdo + questionário subscrições |
| 5.6 | Promover internal → closed → open (ou produção directa) |

---

## Matriz de riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| Tier FREE com utilizador PRO pagante | Alto | P2 webhook + `sync-subscription-tier` |
| Chave OpenAI no APK | Médio | Edge Function pós-beta |
| Assets marketing em falta | Médio | `assets/README.md` + placeholders versionados |
| Trial local contornável | Baixo | Trial Play intro offer em P3 |
| Drift Git/Supabase | Alto | P0 merge único + `sync_check` |

---

## Comandos de verificação

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd /workspace
./tools/launch_beta_verify.sh
```

```bash
# Dev com secrets
./tools/bootstrap_env_from_secrets.sh
./tools/verify_env.sh
./tools/run_dev.sh -d chrome   # ou device Android
```

---

## Sequência de execução (agente / equipa)

```
P0 merge → P1 compliance → P2 secrets (manual) → [PAGAMENTO] → P3 Play → P4 beta → P5 produção
```

**Próxima acção imediata (sem pagar):** merge PR launch-beta-close → configurar secrets P2 quando tiveres `REVENUECAT_SECRET_API_KEY`.

---

## Histórico

| Data | Alteração |
|------|-----------|
| 2026-07-03 | Plano inicial pós-auditoria + webhook tier |
