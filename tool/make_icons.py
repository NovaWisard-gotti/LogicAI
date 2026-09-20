"""Genera los PNG del icono de LogicAI para lanzadores anteriores a Android 8.

El diseno es el mismo que el del icono adaptativo (`ic_launcher_foreground.xml`):
un nodo de inicio, un rombo de decision y dos caminos posibles, con el camino
activo en verde lima sobre negro azulado.

Uso:
    python3 tool/make_icons.py
"""

from __future__ import annotations

import os

from PIL import Image, ImageDraw

INK = (10, 15, 21, 255)        # negro azulado
STEEL = (91, 110, 128, 255)    # gris acero
LIME = (180, 240, 42, 255)     # verde lima electrico
COOL_WHITE = (239, 244, 248, 255)

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Region del lienzo de 108 unidades que se usa en el icono cuadrado.
VIEW_MIN, VIEW_MAX = 12.0, 96.0

RES_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "android", "app", "src", "main", "res",
)


def build(size: int, supersample: int = 8) -> Image.Image:
    s = size * supersample
    image = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    span = VIEW_MAX - VIEW_MIN

    def p(x: float, y: float) -> tuple[float, float]:
        return ((x - VIEW_MIN) / span * s, (y - VIEW_MIN) / span * s)

    def u(value: float) -> float:
        return value / span * s

    # Fondo: cuadrado de esquinas redondeadas.
    draw.rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.21), fill=INK)

    def line(x1, y1, x2, y2, color, width):
        draw.line([p(x1, y1), p(x2, y2)], fill=color, width=int(u(width)))
        # Extremos redondeados.
        for x, y in ((x1, y1), (x2, y2)):
            cx, cy = p(x, y)
            r = u(width) / 2
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)

    def circle(cx, cy, r, color):
        x, y = p(cx, cy)
        rr = u(r)
        draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)

    # Aristas del grafo.
    line(38, 36, 50, 46, STEEL, 5)
    line(50, 60, 34, 75, STEEL, 5)
    line(66, 60, 78, 75, LIME, 5)

    # Rombo de decision (contorno).
    diamond = [p(58, 40), p(72, 54), p(58, 68), p(44, 54)]
    draw.line(diamond + [diamond[0], diamond[1]], fill=LIME, width=int(u(5)),
              joint="curve")

    # Nodos.
    circle(34, 30, 7, COOL_WHITE)
    circle(30, 81, 7, STEEL)
    circle(82, 81, 8, LIME)

    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    for folder, size in SIZES.items():
        target_dir = os.path.join(RES_DIR, folder)
        os.makedirs(target_dir, exist_ok=True)
        icon = build(size)
        icon.save(os.path.join(target_dir, "ic_launcher.png"))

        round_icon = icon.copy()
        mask = Image.new("L", (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, size * 4 - 1, size * 4 - 1], fill=255)
        round_icon.putalpha(mask.resize((size, size), Image.LANCZOS))
        round_icon.save(os.path.join(target_dir, "ic_launcher_round.png"))

        print(f"{folder}: {size}x{size}")


if __name__ == "__main__":
    main()
