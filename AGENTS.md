# AQUANAUTIX — Guia para agentes (Cloud / CI)

Documentação geral do projecto: `CLAUDE.md`, `README.md`.

## Cursor Cloud specific instructions

### Stack no mono-repo

| Produto | Caminho | Servir / correr |
|--------|---------|-----------------|
| **App Flutter** (prioridade) | `/workspace` (`lib/`, `pubspec.yaml`) | `flutter pub get` → `./tools/verify_env.sh` → `./tools/run_dev.sh -d chrome` |
| **Site V2** (landing) | `Site V2/` | `cd "Site V2" && python3 -m http.server 8080` → http://127.0.0.1:8080/ |
| **Protótipos HTML** | `Site V2/*.html` | Mesmo servidor na porta **8080** |

Não há `docker compose`, `supabase start` nem `npm run dev` para o site. `Site V2/package.json` só tem scripts `screenshot:*` (Puppeteer).

### Flutter SDK (Linux)

O SDK **não** vem no repo. Na VM Cloud, usar clone estável em `~/flutter` e PATH:

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

`flutter doctor` deve mostrar **Chrome** disponível; Android SDK e GTK/Linux desktop podem falhar — usar **Chrome (web)** para smoke/E2E na cloud.

### Asset `assets/video_bg.mp4` (gitignored)

`*.mp4` está no `.gitignore`. Sem este ficheiro, `flutter test` e o asset bundle falham. Criar placeholder local (não versionar):

```bash
ffmpeg -y -f lavfi -i color=c=black:s=64x64:d=0.5 -c:v libx264 -pix_fmt yuv420p assets/video_bg.mp4
```

### Variáveis / `.env` / secrets Cloud

Chaves via `--dart-define` (paridade Windows `tools/run_dev.ps1` ↔ Linux `tools/run_dev.sh`). O `.env` na raiz **não** está versionado.

**Fluxo recomendado na Cloud:**

1. Configurar **secrets Cursor** (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MAPBOX_ACCESS_TOKEN`, `OPENAI_API_KEY`, `REVENUECAT_API_KEY_ANDROID`, …).
2. `./tools/bootstrap_env_from_secrets.sh` — cria `.env` só se ainda não existir (nunca sobrescreve).
3. `./tools/verify_env.sh` — audita chaves sem imprimir valores.
4. `./tools/run_dev.sh -d chrome` — injecta `--dart-define` (env vars têm prioridade sobre `.env`).

Sem `SUPABASE_URL` + `SUPABASE_ANON_KEY`, `initSupabaseIfConfigured()` não corre — o ecrã **Início** pode rebentar; **Oráculo** e **Mapa** funcionam com APIs públicas.

### Comandos de verificação

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd /workspace
flutter pub get
flutter analyze          # lint Dart
flutter test             # 1 teste pode falhar: vision_catalog_match (JSON espécies)
```

**Site:** após `python3 -m http.server 8080` em `Site V2/`, validar `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/` → `200` e presença de `</html>` em `index.html`.

### Serviços em tmux (recomendado)

Usar sessões com nomes descritivos, por exemplo:

- `site-v2-server` — `python3 -m http.server 8080` em `Site V2/`
- `flutter-web-dev` — `./tools/run_dev.sh -d chrome` (ou `flutter run -d chrome --web-port=7357 --web-hostname=127.0.0.1` sem secrets)

### Hello world (aceitação mínima)

1. **Site:** abrir `http://127.0.0.1:8080/#oraculo` → score solunar (módulo `calcularOraculo()`).
2. **App:** com secrets + `./tools/run_dev.sh -d chrome` → splash → login ou convidado → **Início** + tab **Oráculo** / **Mapa**.

### Notas

- `flutter build web` / `flutter build linux` podem falhar com *"not configured for web/desktop"* — o repo não inclui pastas `web/` nem target Linux; `flutter run -d chrome` ainda serve para desenvolvimento na cloud.
- Site em produção: https://aquanautix.vercel.app (deploy: `cd "Site V2" && vercel --prod`).
- Módulos **protegidos** do Site V2: ver `.cursorrules` / `CLAUDE.md` — não alterar sem **AUTORIZO**.
