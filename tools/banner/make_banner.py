#!/usr/bin/env python3
"""
make_banner.py : titres en « briques » pixel (police 5x7), en SVG, sans aucune dépendance.

Exemples :
  python3 make_banner.py "REWRITE_OS" > rewrite_os-dark.svg
  python3 make_banner.py "REWRITE_OS" --theme light > rewrite_os-light.svg
  python3 make_banner.py "REWRITE_OS" --canvas 1280x640 > social.svg      (image d'aperçu du dépôt)
  python3 make_banner.py "REWRITE_OS" --color "#B79BFF" --px 16 > titre.svg  (violet clair, plus grand)
  python3 make_banner.py "BOOTLOADER" --ascii                            (aperçu texte dans le terminal)

Un SVG fait de rectangles s'affiche partout sur GitHub, avec les couleurs, sans police externe.
"""
import argparse
import sys

# --- La police : chaque lettre fait 7 lignes ; « # » = une brique, « . » = vide -------------------
FONT = {
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
    "Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["#####", "...#.", "..#..", "...#.", "....#", "#...#", ".###."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    "6": ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."],
    "_": [".....", ".....", ".....", ".....", ".....", ".....", "#####"],
    "-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
    ".": ["..", "..", "..", "..", "..", "##", "##"],
    ":": ["..", "##", "##", "..", "##", "##", ".."],
    " ": ["...", "...", "...", "...", "...", "...", "..."],
}

# --- Les réglages de forme (en pixels de l'image) --------------------------------------------------
DEFAULT_PX = 12  # taille d'une brique par défaut (modifiable avec --px)


def geometry(px):
    """Toutes les autres tailles se déduisent de celle d'une brique."""
    gap = max(1, round(px / 6))             # joint entre deux briques
    return {
        "px": px,
        "gap": gap,
        "step": px + gap,                   # pas entre deux briques
        "depth": max(2, round(px * 0.42)),  # décalage de l'extrusion 3D (bas et droite)
        "stroke": max(1, round(px / 6)),    # épaisseur du contour
        "rx": max(1, round(px / 4)),        # arrondi des briques
        "pad": px * 2,                      # marge autour du titre
    }

# --- Les palettes : modifie les couleurs ici -------------------------------------------------------
PALETTES = {
    "dark":  {"bg": "#0D1117", "fill": "#E8743B", "shade": "#8F3F1B", "edge": "#000000"},
    "light": {"bg": "#FFFFFF", "fill": "#E8743B", "shade": "#B4552A", "edge": "#2B1409"},
}


def mix(hex_color, other, amount):
    """Mélange une couleur « #RRGGBB » avec une autre : amount=0 -> inchangée, amount=1 -> l'autre."""
    a = [int(hex_color[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(other[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x + (y - x) * amount):02X}" for x, y in zip(a, b))


def palette_from_color(theme, color):
    """À partir d'UNE couleur (la face avant des briques), calcule l'extrusion et le contour."""
    pal = dict(PALETTES[theme])
    pal["fill"] = color.upper()
    pal["shade"] = mix(color, "#000000", 0.45)    # l'extrusion : la même couleur, plus sombre
    pal["edge"] = mix(color, "#000000", 0.88)     # le contour : presque noir, teinté
    return pal


def build_grid(text):
    """Colle les lettres côte à côte (1 colonne vide entre elles) et renvoie une grille de 7 lignes."""
    rows = [""] * 7
    for index, ch in enumerate(text.upper()):
        if ch not in FONT:
            sys.exit(f"Caractère non géré : {ch!r}. Caractères possibles : A-Z 0-9 espace _ - . :")
        glyph = FONT[ch]
        for r in range(7):
            rows[r] += glyph[r] + ("." if index < len(text) - 1 else "")
    return rows


def bricks(rows, g, dx=0, dy=0):
    """Une brique (rectangle arrondi) pour chaque « # » de la grille."""
    out = []
    for r, row in enumerate(rows):
        for c, cell in enumerate(row):
            if cell == "#":
                x = dx + c * g["step"]
                y = dy + r * g["step"]
                out.append(f'<rect x="{x}" y="{y}" width="{g["px"]}" height="{g["px"]}" rx="{g["rx"]}"/>')
    return out


def fit_px(cols, width, height):
    """Plus grande taille de brique pour que le titre occupe au plus 80 % de la largeur et 60 % de la hauteur."""
    for px in range(60, 5, -1):
        g = geometry(px)
        if cols * g["step"] + g["depth"] <= 0.8 * width and 7 * g["step"] + g["depth"] <= 0.6 * height:
            return px
    return 6


def make_svg(text, theme="dark", canvas=None, transparent=False, px=None, color=None):
    pal = palette_from_color(theme, color) if color else PALETTES[theme]
    rows = build_grid(text)
    cols = len(rows[0])

    if canvas and px is None:
        px = fit_px(cols, *canvas)          # sur une grande image, le titre s'adapte tout seul
    g = geometry(px or DEFAULT_PX)

    text_w = cols * g["step"] - g["gap"] + g["depth"]
    text_h = 7 * g["step"] - g["gap"] + g["depth"]

    if canvas:
        width, height = canvas
        ox, oy = (width - text_w) // 2, (height - text_h) // 2   # titre centré
    else:
        width, height = text_w + 2 * g["pad"], text_h + 2 * g["pad"]
        ox, oy = g["pad"], g["pad"]

    out = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
           f'viewBox="0 0 {width} {height}" role="img" aria-label="{text}">',
           f'<title>{text}</title>']
    if not transparent:
        out.append(f'<rect width="{width}" height="{height}" rx="14" fill="{pal["bg"]}"/>')
    # 1) l'extrusion : les mêmes briques, décalées vers le bas et la droite, en couleur sombre
    out.append(f'<g fill="{pal["shade"]}" stroke="{pal["edge"]}" stroke-width="{g["stroke"]}">')
    out += bricks(rows, g, ox + g["depth"], oy + g["depth"])
    out.append('</g>')
    # 2) la face avant, par-dessus
    out.append(f'<g fill="{pal["fill"]}" stroke="{pal["edge"]}" stroke-width="{g["stroke"]}">')
    out += bricks(rows, g, ox, oy)
    out.append('</g>')
    out.append('</svg>')
    return "\n".join(out)


def make_ascii(text):
    return "\n".join("".join("██" if c == "#" else "  " for c in row).rstrip() for row in build_grid(text))


def main():
    ap = argparse.ArgumentParser(description="Titres SVG en briques pixel")
    ap.add_argument("text", help="le titre (A-Z, 0-9, espace, _ - . :)")
    ap.add_argument("--theme", choices=PALETTES, default="dark", help="dark (défaut) ou light")
    ap.add_argument("--canvas", metavar="LxH", help="taille de l'image, ex. 1280x640 (titre centré)")
    ap.add_argument("--px", type=int, help="taille d'une brique en pixels (défaut 12 ; adaptée toute seule avec --canvas)")
    ap.add_argument("--color", metavar="#RRGGBB", help="couleur des briques, ex. #B79BFF (violet clair)")
    ap.add_argument("--transparent", action="store_true", help="sans rectangle de fond")
    ap.add_argument("--ascii", action="store_true", help="aperçu en texte dans le terminal")
    args = ap.parse_args()

    if args.ascii:
        print(make_ascii(args.text))
        return
    canvas = tuple(int(v) for v in args.canvas.lower().split("x")) if args.canvas else None
    print(make_svg(args.text, args.theme, canvas, args.transparent, args.px, args.color))


if __name__ == "__main__":
    main()
