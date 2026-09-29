# Prompt para o Cursor — CI, Pull Request #22 e sincronização do main (24 Set 2026)

> Colar no chat do Cursor (caixa central), numa conversa nova. Local ("This PC"), não Cloud.

---

```
Contexto: o PR #22 (branch fix/seguranca-2026-09-24 → main) contém 7 commits que só existiam neste PC, incluindo as migrações de segurança de 24 Set e a mudança do OpenAI Vision para Edge Function. O main no GitHub é protegido e exige o check "analyze + test". O CI está vermelho e o main local está divergente (7 à frente, 2 atrás — os 2 são bumps do Dependabot em Site V2/package-lock.json).

Causa do CI vermelho (confirmada no log do job "build apk --debug"): o passo "Placeholder assets/video_bg.mp4 (gitignored)" chama ffmpeg, que já não vem instalado no runner ubuntu-latest → "ffmpeg: command not found", exit 127. O job "analyze + test" tem o mesmo passo.

ÂMBITO DESTA SESSÃO (só isto, nada mais):
A) Corrigir o CI.
B) Pôr o PR #22 verde e integrá-lo (com a minha autorização).
C) Sincronizar o main local.
D) .gitignore para as pastas de cópias.
Fora de âmbito: código em lib/, supabase/, Site V2/, design, P1–P4, bug image/jpg (sessão própria a seguir).

REGRAS
- Nunca push directo para main. Nunca --force. Nunca reset --hard. Nunca apagar branches ou ficheiros.
- Não fazer commit das pastas "Imagens - Cópia*" nem "Logo Aquanautix - Cópia*".
- Se o hook pre-commit falhar, pára e mostra-me o erro; não usar --no-verify.
- Antes de cada comando git que escreve (commit, push, merge, pull), diz-me em 1 linha o que vai fazer.
- Resposta final em PT-PT, curta.

PASSOS

A) CI
1. git status -sb e git branch --show-current. Se houver alterações staged inesperadas, pára e reporta.
2. git switch fix/seguranca-2026-09-24
3. Em .github/workflows/flutter-ci.yml, nos DOIS passos "Placeholder assets/video_bg.mp4 (gitignored)" (jobs analyze_test e build_apk_debug), acrescentar no início do bloco run, antes de "mkdir -p assets":
     sudo apt-get update -qq
     sudo apt-get install -y -qq ffmpeg
   Não alterar mais nada no ficheiro.
4. git add .github/workflows/flutter-ci.yml
   git commit -m "ci: instala ffmpeg antes de gerar placeholder video_bg.mp4"
   git push

B) PR #22
5. Aguardar o CI. Se tiveres `gh` instalado e autenticado: gh pr checks 22 --watch. Se não, pede-me para ver no GitHub e esperar pela minha resposta.
6. Se "analyze + test" falhar por OUTRA razão (ex.: warnings do flutter analyze, testes): NÃO corrigir código. Mostra-me o erro exacto (ficheiro:linha) e pára.
7. Com "analyze + test" verde: pergunta-me "Posso fazer merge do PR #22?" e espera por AUTORIZO.
8. Com AUTORIZO: gh pr merge 22 --merge (merge commit; NUNCA --squash nem --rebase, senão o main local deixa de conseguir fast-forward). Sem gh: diz-me para clicar "Create a merge commit" no GitHub e espera.

C) Sincronizar main
9. git switch main
   git pull --ff-only
   Se falhar, pára e mostra-me o erro (não resolver com merge/rebase por iniciativa própria).
10. Confirmar: git status -sb mostra "main...origin/main" sem "ahead"/"behind", e git log --oneline -3.

D) Higiene (commit próprio, via branch + PR porque o main é protegido)
11. git switch -c chore/gitignore-copias
12. Acrescentar ao fim do .gitignore:
      # Cópias locais de assets (não versionar)
      Imagens - Cópia*/
      Logo Aquanautix - Cópia*/
13. Confirmar com git status que as pastas de cópias deixaram de aparecer.
14. git add .gitignore
    git commit -m "chore: ignora pastas de cópias locais de imagens e logos"
    git push -u origin chore/gitignore-copias
    Abrir PR (gh pr create --fill) ou dar-me o link. NÃO fazer merge sem o meu AUTORIZO.
    NÃO aplicar .gitattributes nesta sessão.

RELATÓRIO FINAL
- Estado do CI do PR #22 (verde/vermelho + causa se vermelho).
- PR #22 integrado? main local sincronizado? (output de git status -sb)
- Link do PR do .gitignore.
- Qualquer coisa que tenha ficado por fazer e porquê.
```
