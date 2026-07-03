# Assets AQUANAUTIX — estado e requisitos

Ficheiros referenciados em `pubspec.yaml` que **devem existir** antes de build de produção com UI completa.

## Presentes no repositório

| Ficheiro | Uso |
|----------|-----|
| `assets/data/species_ibero.json` | Catálogo espécies PT/ES |
| `assets/data/fishing_regulations_pt_es.geojson` | Camada regulamentos mapa |
| `assets/icons/fish_silhouette.svg` | Ícone (não no pubspec) |

## Em falta — adicionar antes de screenshots Play Store

| Ficheiro / pasta | Uso | Fallback actual |
|------------------|-----|-----------------|
| `assets/video_bg.mp4` | Splash + login | Fundo sólido (gitignored) |
| `assets/robalo_scanner.png` | Onboarding Vision | `errorBuilder` |
| `assets/marketing/spots/*.jpg` | Cards Início (3) | Placeholder cinza |
| `assets/marketing/catches/*.jpg` | Hero Oráculo, comunidade (5) | Placeholder cinza |
| `assets/onboarding/` | Declarado no pubspec | Pasta vazia OK |

## Placeholder local (dev / CI)

```bash
ffmpeg -y -f lavfi -i color=c=black:s=64x64:d=0.5 -c:v libx264 -pix_fmt yuv420p assets/video_bg.mp4
```

## Política de versionamento

- **JSON / GeoJSON:** versionar sempre
- **Imagens marketing / vídeo:** versionar antes de beta público (ou LFS se >5MB)
- **Nunca** commitar `.env`, chaves API, keystore

Ver `docs/LAUNCH_BETA_PLAN.md` fase P1.
