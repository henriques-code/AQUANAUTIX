# AGENTS.md

Projecto **AQUANAUTIX / AQUADEX** — app de pesca (Flutter + Supabase) + site de marketing estático (`Site V2/`).
Regras de produto/idioma/design: ver `CLAUDE.md`, `.cursorrules`, `README.md`, `ECOSYSTEM.md`. Comunicar em Português de Portugal.

## Cursor Cloud specific instructions

Notas para agentes que correm neste ambiente cloud (Linux headless). O *update script* já instala/actualiza dependências antes de cada sessão; não repetir esses passos aqui.

### Toolchain
- **Flutter SDK** está em `/opt/flutter` (canal `stable`, Flutter 3.44 / Dart 3.12), com symlinks em `/usr/local/bin/flutter` e `/usr/local/bin/dart` (já no `PATH`, inclusive em shells não-interactivos). Não é preciso `nvm`/`mise` para o Flutter.
- Java 21 e Node 22 estão disponíveis. **Não há Android SDK nem emulador, e não há `/dev/kvm`** — não é possível correr a app Flutter num emulador Android nem fazer `flutter build apk` aqui.

### App Flutter (foco principal)
- Plataformas configuradas: **só `android/` e `windows/`** (sem `web/`, `linux/`, `ios/`). Logo, **a GUI da app não corre neste VM**. Validar via análise estática e testes:
  - Lint: `flutter analyze`
  - Testes: `flutter test`
- Configuração (Supabase, Mapbox, RevenueCat, OpenAI…) é injectada por `--dart-define=CHAVE=valor`. Tudo é opcional em runtime (`*IfConfigured` em `lib/core/`), por isso analyze/test correm **sem segredos**.
- **Asset obrigatório `assets/video_bg.mp4`**: está declarado em `pubspec.yaml` mas é ignorado pelo Git (`*.mp4` em `.gitignore`), por isso falta num clone novo. Sem ele, `flutter analyze`/`flutter test`/build falham com `No file or variants found for asset: assets/video_bg.mp4`. O *update script* cria um placeholder vazio se faltar; num dispositivo real usa-se o vídeo verdadeiro.

### Site V2 (marketing — protegido, não alterar sem AUTORIZO)
- É HTML/CSS/JS estático. Servir com qualquer servidor estático a partir de `Site V2/`, ex.: `python3 -m http.server 8080` (o `_local_server.ps1` documentado é só Windows/PowerShell).
- O `index.html` contém texto com **mojibake (dupla codificação) já gravado no ficheiro-fonte** (ex.: aparece `OrÃ¡culo`). É conteúdo pré-existente do ficheiro protegido, **não** um problema de codificação do servidor — não "corrigir" sem autorização explícita.
- O motor do Oráculo (`calcularOraculo()`, SunCalc) calcula um score 0–100 em runtime no browser; o mapa Mapbox precisa do token embutido no `index.html`.

### Supabase
- `supabase/` tem migrations versionadas; aplicar a um projecto remoto requer a CLI Supabase + login (não instalada por omissão). Não é necessária para correr o site nem para `analyze`/`test` da app.
