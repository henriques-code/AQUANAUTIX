import cairosvg
from pathlib import Path


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    assets = repo_root / "assets"

    inputs = [
        assets / "mockup_licencas.svg",
        assets / "mockup_login.svg",
    ]

    for p in inputs:
        if not p.exists():
            raise FileNotFoundError(p)

        out = p.with_suffix(".png")
        # output_width mantém proporção 9:16 e dá qualidade suficiente para preview.
        cairosvg.svg2png(
            url=str(p),
            write_to=str(out),
            output_width=720,
            dpi=200,
        )
        print(f"OK: {out}")


if __name__ == "__main__":
    main()

