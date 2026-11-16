#!/usr/bin/env python3
"""
Generador determinista de activos gráficos para PWA, Android (Capacitor) y Google Play Console.
Genera íconos PNG reales, mipmaps Android, foreground adaptativo y Feature Graphic 1024x500.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent

BG_DARK = (9, 13, 22, 255)
WALNUT_DARK = (45, 24, 11, 255)
WALNUT_BORDER = (120, 53, 15, 255)
GOLD = (245, 158, 11, 255)
GOLD_LIGHT = (252, 211, 77, 255)
GOLD_DARK = (180, 83, 9, 255)
WHITE_TEXT = (248, 250, 252, 255)
SLATE_TEXT = (203, 213, 225, 255)


def draw_crown_icon(size: int, padding_ratio: float = 0.0, circle_mask: bool = False) -> Image.Image:
    """Dibuja el emblema de corona real sobre fondo de nogal oscuro."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0) if circle_mask else WALNUT_DARK)
    draw = ImageDraw.Draw(img)

    if circle_mask:
        margin = max(1, int(size * 0.02))
        draw.ellipse(
            [margin, margin, size - margin, size - margin],
            fill=WALNUT_DARK,
            outline=GOLD,
            width=max(2, size // 32),
        )
    else:
        draw.rectangle([0, 0, size, size], fill=WALNUT_DARK)
        # Anillo dorado decorativo
        ring_pad = int(size * (0.10 + padding_ratio * 0.5))
        draw.ellipse(
            [ring_pad, ring_pad, size - ring_pad, size - ring_pad],
            outline=GOLD_DARK,
            width=max(2, size // 48),
        )
        inner_pad = ring_pad + max(3, size // 42)
        draw.ellipse(
            [inner_pad, inner_pad, size - inner_pad, size - inner_pad],
            outline=GOLD,
            width=max(2, size // 36),
        )

    # Coordenadas proporcionales de la corona real
    scale = 1.0 - padding_ratio * 2.0
    cx = size / 2.0
    cy = size / 2.0

    def pt(nx: float, ny: float) -> tuple[float, float]:
        return (cx + (nx - 0.5) * size * scale, cy + (ny - 0.5) * size * scale)

    crown_poly = [
        pt(0.24, 0.66),
        pt(0.19, 0.33),
        pt(0.36, 0.45),
        pt(0.50, 0.27),
        pt(0.64, 0.45),
        pt(0.81, 0.33),
        pt(0.76, 0.66),
    ]
    draw.polygon(crown_poly, fill=GOLD, outline=GOLD_LIGHT)

    # Base de la corona
    b_left, b_top = pt(0.24, 0.70)
    b_right, b_bottom = pt(0.76, 0.77)
    draw.rounded_rectangle(
        [b_left, b_top, b_right, b_bottom],
        radius=max(2, int(size * 0.03)),
        fill=GOLD_LIGHT,
    )

    # Joyas en las puntas
    jewel_r = max(2, int(size * 0.032 * scale))
    for jx, jy in [(0.19, 0.31), (0.50, 0.25), (0.81, 0.31)]:
        px, py = pt(jx, jy)
        draw.ellipse([px - jewel_r, py - jewel_r, px + jewel_r, py + jewel_r], fill=GOLD_LIGHT)

    return img


def draw_foreground_crown(size: int) -> Image.Image:
    """Dibuja solo la corona centrada en la zona segura adaptativa (66%)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = 0.68
    cx = size / 2.0
    cy = size / 2.0

    def pt(nx: float, ny: float) -> tuple[float, float]:
        return (cx + (nx - 0.5) * size * scale, cy + (ny - 0.5) * size * scale)

    crown_poly = [
        pt(0.22, 0.66),
        pt(0.16, 0.32),
        pt(0.35, 0.45),
        pt(0.50, 0.26),
        pt(0.65, 0.45),
        pt(0.84, 0.32),
        pt(0.78, 0.66),
    ]
    draw.polygon(crown_poly, fill=GOLD, outline=GOLD_LIGHT)
    b_left, b_top = pt(0.22, 0.70)
    b_right, b_bottom = pt(0.78, 0.77)
    draw.rounded_rectangle(
        [b_left, b_top, b_right, b_bottom],
        radius=max(2, int(size * 0.025)),
        fill=GOLD_LIGHT,
    )
    return img


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_feature_graphic(width: int = 1024, height: int = 500) -> Image.Image:
    """Genera el gráfico de funciones 1024x500 obligatorio para Google Play Console."""
    img = Image.new("RGBA", (width, height), BG_DARK)
    draw = ImageDraw.Draw(img)

    # Fondo tablero diagonal sutil a la derecha
    board_x0 = 560
    sq = 58
    for r in range(9):
        for c in range(9):
            x0 = board_x0 + c * sq
            y0 = -10 + r * sq
            color = (92, 58, 33, 255) if (r + c) % 2 == 1 else (216, 182, 138, 255)
            draw.rectangle([x0, y0, x0 + sq, y0 + sq], fill=color)
            if (r + c) % 2 == 1 and r in (1, 2, 6, 7):
                piece_col = (241, 245, 249, 255) if r >= 6 else (30, 41, 59, 255)
                outline_col = (148, 163, 184, 255) if r >= 6 else GOLD
                pad = 10
                draw.ellipse(
                    [x0 + pad, y0 + pad, x0 + sq - pad, y0 + sq - pad],
                    fill=piece_col,
                    outline=outline_col,
                    width=3,
                )

    # Degradado izquierdo para legibilidad del texto
    for x in range(0, 640):
        alpha = 255 if x < 480 else int(255 * (1.0 - (x - 480) / 160.0))
        draw.line([(x, 0), (x, height)], fill=(9, 13, 22, alpha))

    # Emblema corona a la izquierda
    crown = draw_crown_icon(148, padding_ratio=0.08)
    img.paste(crown, (64, 72), crown)

    title_font = load_font(54)
    sub_font = load_font(24)
    chip_font = load_font(19)

    draw.text((64, 248), "DAMAS DEL MUNDO", font=title_font, fill=WHITE_TEXT)
    draw.text((64, 316), "7 Variantes Mundiales • IA Némesis • Academia Infinita", font=sub_font, fill=GOLD_LIGHT)

    # Insignia offline
    draw.rounded_rectangle([64, 372, 420, 422], radius=14, fill=(45, 24, 11, 255), outline=GOLD, width=2)
    draw.text((84, 385), "100% OFFLINE • SIN ANUNCIOS", font=chip_font, fill=GOLD_LIGHT)

    return img.convert("RGB")


def draw_splash_screen(width: int, height: int) -> Image.Image:
    """Genera pantalla de arranque oscura (#090D16) con emblema de corona centrado."""
    img = Image.new("RGB", (width, height), BG_DARK[:3])
    emblem_size = max(96, min(width, height) // 3)
    crown = draw_crown_icon(emblem_size, padding_ratio=0.06, circle_mask=True)
    x = (width - emblem_size) // 2
    y = (height - emblem_size) // 2
    img.paste(crown, (x, y), crown)
    return img


def main() -> None:
    icons_dir = ROOT / "assets" / "icons"
    store_dir = ROOT / "play_store_assets"
    icons_dir.mkdir(parents=True, exist_ok=True)
    store_dir.mkdir(parents=True, exist_ok=True)

    # PWA & Play Store icons
    draw_crown_icon(192, padding_ratio=0.05).save(icons_dir / "icon-192.png")
    icon_512 = draw_crown_icon(512, padding_ratio=0.05)
    icon_512.save(icons_dir / "icon-512.png")
    icon_512.convert("RGB").save(store_dir / "icon_512x512.png")
    draw_crown_icon(512, padding_ratio=0.14).save(icons_dir / "icon-512-maskable.png")

    # Feature graphic
    draw_feature_graphic(1024, 500).save(store_dir / "feature_graphic_1024x500.png")

    # Android mipmaps y splash oscuros si android/app/src/main/res existe
    res_dir = ROOT / "android" / "app" / "src" / "main" / "res"
    if res_dir.exists():
        densities = {
            "mipmap-mdpi": (48, 108),
            "mipmap-hdpi": (72, 162),
            "mipmap-xhdpi": (96, 216),
            "mipmap-xxhdpi": (144, 324),
            "mipmap-xxxhdpi": (192, 432),
        }
        for folder, (icon_px, fg_px) in densities.items():
            d = res_dir / folder
            d.mkdir(parents=True, exist_ok=True)
            draw_crown_icon(icon_px, padding_ratio=0.04).save(d / "ic_launcher.png")
            draw_crown_icon(icon_px, padding_ratio=0.08, circle_mask=True).save(d / "ic_launcher_round.png")
            draw_foreground_crown(fg_px).save(d / "ic_launcher_foreground.png")

        splash_sizes = {
            "drawable": (480, 320),
            "drawable-land-mdpi": (480, 320),
            "drawable-land-hdpi": (800, 480),
            "drawable-land-xhdpi": (1280, 720),
            "drawable-land-xxhdpi": (1600, 960),
            "drawable-land-xxxhdpi": (1920, 1280),
            "drawable-port-mdpi": (320, 480),
            "drawable-port-hdpi": (480, 800),
            "drawable-port-xhdpi": (720, 1280),
            "drawable-port-xxhdpi": (960, 1600),
            "drawable-port-xxxhdpi": (1280, 1920),
        }
        for folder, (w, h) in splash_sizes.items():
            d = res_dir / folder
            if d.exists():
                draw_splash_screen(w, h).save(d / "splash.png")

    print("[generate_assets] Activos PWA, Play Store y Android generados correctamente.")


if __name__ == "__main__":
    main()
