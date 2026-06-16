# AQUANAUTIX — Fluxo de sincronização e segurança

> **Objectivo:** nada se perde — código, backend, docs e Git alinhados.  
> **Última revisão:** 16 Jun 2026 · commit de referência `cc359ab`

---

## 1. Princípios (opinião de engenharia)

| Princípio | Regra |
|-----------|--------|
| **Uma fonte de verdade** | Código em `lib/` + migrations em `supabase/migrations/` + docs versionados |
| **Segredos nunca no Git** | `.env`, `tools/local_secrets.ps1`, tokens, `sk_`, `sbp_` |
| **Sync explícito por camada** | App ≠ Site V2 ≠ Supabase — cada um tem comando próprio |
| **Agente executa verificações** | O assistente corre `sync_check` e reporta; commit/push só com critérios abaixo |
| **Site V2 protegido** | Deploy/edição só com **AUTORIZO** explícito |

---

## 2. Matriz do ecossistema

| Camada | Onde | Verificar | Sincronizar | Frequência |
|--------|------|-----------|-------------|------------|
| **App Flutter** | `lib/` | `flutter analyze lib/` | `git push` | Cada feature/fix |
| **Supabase** | `supabase/migrations/` | `.\tools\supabase_with_env.ps1 migration list` | `db push --yes` | Após nova migration |
| **Documentação** | `*.md`, `.cursorrules` | refs 7 tabs, commits, migrations | commit com código | Mesmo PR/sessão |
| **GitHub** | `origin/main` | `git status` · `git log origin/main..HEAD` | `git push origin main` | Fim de sessão útil |
| **Site V2** | `Site V2/` | diff local | `vercel --prod` | Só com AUTORIZO |
| **Secrets** | `.env` (local) | nunca staged | — | Só na máquina |

---

## 3. Segurança (obrigatório)

### Nunca commitar

- `.env` · `.env.*` · `tools/local_secrets.ps1`
- `sk_*` (OpenAI, RevenueCat secret, Mapbox secret)
- `sbp_*` (Supabase personal access token)
- Chaves JWT completas coladas em ficheiros versionados
- `Imagens/` (screenshots locais) salvo pedido explícito

### O que pode ir no `.env` (local, gitignored)

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...          # chave pública anon — app Flutter
SUPABASE_ACCESS_TOKEN=sbp_...  # só CLI — NUNCA dart-define na app
MAPBOX_ACCESS_TOKEN=pk....     # público restrito por domínio
REVENUECAT_API_KEY_ANDROID=goog_...
OPENAI_API_KEY=sk-...          # preferir Edge Function a médio prazo
```

### Checklist pré-commit (agente)

1. `git diff --staged` — sem ficheiros sensíveis
2. `git status` — confirmar que `.env` não aparece
3. Hook local: `.\tools\install_git_hooks.ps1` (uma vez por clone) — bloqueia `.env`, tokens no conteúdo
4. Se migration SQL nova → `migration list` local = remoto após `db push`

---

## 4. Comandos oficiais

### Setup (uma vez por clone)

```powershell
.\tools\install_git_hooks.ps1   # pre-commit bloqueia segredos
```

### Verificação rápida (correr sempre ao fechar trabalho)

```powershell
cd "C:\Users\Joaop\OneDrive\Documentos\AQUANAUTIX"
.\tools\sync_check.ps1
```

### App

```powershell
flutter analyze lib/
.\tools\run_dev.ps1 -d WWZLYDXWYXT8PV5D
```

### Supabase (lê token do `.env`)

```powershell
.\tools\supabase_with_env.ps1 migration list
.\tools\supabase_with_env.ps1 db push --yes
```

### Git (agente — fim de sessão com alterações)

```powershell
git status
git diff --stat
git add lib/ supabase/ *.md .cursorrules tools/
git commit -m "tipo(escopo): descrição"
git push origin main
```

---

## 5. Regra para o agente Cursor (sempre aplicar)

**Quando o utilizador pedir** «atualizar tudo», «sync», «fechar sessão», ou após implementação significativa:

1. Correr `.\tools\sync_check.ps1` e resumir resultado (✅/⚠️/❌).
2. Se `lib/` mudou → `flutter analyze lib/` (já incluído no script).
3. Se `supabase/migrations/` mudou → `migration list`; se local ≠ remoto → `db push --yes`.
4. Se estrutura/navegação mudou → actualizar `AQUANAUTIX_CONTEXT.md` + `HANDOFF.md` (mínimo).
5. **Commit** — mensagem conventional; agrupar por tipo (`feat` / `fix` / `docs` / `chore(supabase)`).
6. **Push** — após commit, se branch ahead of origin (aprovação Cursor em `main` é normal).
7. **Nunca** ler nem colar conteúdo do `.env` no chat.
8. **Site V2** — não editar/deploy sem **AUTORIZO**.

**Commits automáticos:** permitidos quando o utilizador disser explicitamente «commit», «push», «atualizar tudo», ou «sync completo».

---

## 6. Branch Protection — Fluxo de trabalho (GitHub Ruleset)

O branch `main` tem um **Branch Ruleset** activo no GitHub com as seguintes regras:

| Regra | Estado |
|-------|--------|
| Restringir exclusões | ✅ Activo |
| Bloquear force push | ✅ Activo |
| Exigir histórico linear | ✅ Activo |
| Exigir PR antes de merge | ✅ Activo |

### Fluxo obrigatório (push directo para `main` bloqueado)

```powershell
# 1. Criar branch para a feature
git checkout -b feature/nome-da-feature

# 2. Trabalhar e commitar
git add lib/ supabase/ *.md
git commit -m "feat(escopo): descrição"

# 3. Push do branch
git push origin feature/nome-da-feature

# 4. Criar PR no GitHub → merge → main
# (O agente pode criar PR via gh CLI se pedido)
```

### Excepção: bypass autorizado

O proprietário do repositório tem permissão de bypass — em emergências pode usar:
```powershell
git push origin main  # só funciona para contas com bypass no Ruleset
```

---

## 7. Definition of Done (sessão)

Uma sessão está **fechada** quando:

- [ ] `flutter analyze lib/` — 0 issues
- [ ] `migration list` — colunas Local = Remote (ou explicado)
- [ ] Docs principais coerentes com código (tabs, ficheiros-chave)
- [ ] `git status` limpo (ou só untracked esperado: `Imagens/`)
- [ ] Push feito ou utilizador informado do motivo de não push

---

## 8. O que fica de fora (manual / externo)

| Item | Onde | Notas |
|------|------|-------|
| RevenueCat produtos | dashboard.revenuecat.com | P0 monetização |
| Google Play SHA-1 | Google Cloud Console | Login Android |
| Mapbox URL restrictions | mapbox.com | Restringir a aquanautix.vercel.app |
| Domínio aquanautix.app | Vercel DNS | Marketing |
| Edge Functions | Supabase (futuro `supabase/functions/`) | Vision/oracle server-side |

---

## 9. Referências

- `ECOSYSTEM.md` — serviços e matriz sync
- `HANDOFF.md` — prompt novos chats
- `supabase/README_setup.md` — migrations
- `.cursor/rules/secrets-local-overrides.mdc` — segredos Flutter
- `.cursor/rules/aquanautix-sync-workflow.mdc` — regra agente (cópia local Cursor)
