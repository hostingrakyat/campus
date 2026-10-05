"""Builds the Play Store graphics in store/graphics from game renders.

Inputs (render with the game, SHOT_SIZE=1080x1920 and SHOT_LANG=2/3, see store/README.md):
  <raw>/id/*.png, <raw>/en/*.png  - 1080x1920 screenshots
  <raw>/feature_bg.png            - landscape campus render (2048x1000)
Usage: python tools/make_store_graphics.py <raw_dir>
"""
import pathlib
import shutil
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONT = ROOT / "game/assets/fonts/Fredoka.ttf"
OUT = ROOT / "store/graphics"
INK = (42, 34, 56)
YELLOW = (255, 200, 61)

# (file, background color, Indonesian headline, English headline)
SHOTS = [
    ("create", (47, 107, 255), "Pilih prodi,\nbikin gayamu sendiri", "Pick your major,\ndress your way"),
    ("week", (47, 191, 113), "Atur jadwal kuliah,\nkerja & nongkrong", "Juggle classes,\njobs & hangouts"),
    ("mg_kuliah", (123, 92, 255), "Dosen nunjuk kamu?\nJawab cepat!", "Called on in class?\nAnswer fast!"),
    ("explore", (39, 198, 242), "Jelajahi kampus,\ncari diamond rahasia", "Roam the campus,\nfind secret diamonds"),
    ("event", (255, 159, 28), "Dosen ghosting,\nbirokrasi bikin pusing", "Ghosting lecturers,\nendless red tape"),
    ("war", (255, 90, 78), "War KRS:\nrebut kelas terbaik", "Course war:\ngrab the best classes"),
    ("khs", (255, 107, 154), "IPK naik turun,\nUKT harus dibayar", "GPA ups and downs,\ntuition is due"),
    ("ending_balance", (42, 34, 56), "10 ending berbeda:\ncum laude sampai DO", "10 endings: from\ncum laude to dropout"),
]


def font(size: int) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(str(FONT), size)
    try:
        f.set_variation_by_axes([650])
    except (OSError, AttributeError):
        pass
    return f


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def promo(src: pathlib.Path, bg: tuple, text: str, dst: pathlib.Path) -> None:
    W, H, band = 1080, 1920, 380
    canvas = Image.new("RGB", (W, H), bg)
    d = ImageDraw.Draw(canvas)
    f = font(84)
    d.multiline_text((W // 2, band // 2 + 10), text, font=f, fill="white", anchor="mm", align="center",
                     spacing=14, stroke_width=6, stroke_fill=tuple(int(c * 0.55) for c in bg))
    shot = Image.open(src).convert("RGB")
    h = H - band - 30
    w = int(shot.width * h / shot.height)
    shot = rounded(shot.resize((w, h), Image.LANCZOS), 48)
    shadow = Image.new("RGBA", (w + 60, h + 60), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([30, 40, w + 30, h + 50], 48, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    x = (W - w) // 2
    canvas.paste(shadow, (x - 30, band - 30), shadow)
    canvas.paste(shot, (x, band), shot)
    canvas.save(dst, optimize=True)


def feature(bg_path: pathlib.Path, dst: pathlib.Path) -> None:
    W, H = 1024, 500
    bg = Image.open(bg_path).convert("RGB")
    scale = max(W / bg.width, H / bg.height) * 1.2
    bg = bg.resize((int(bg.width * scale), int(bg.height * scale)), Image.LANCZOS)
    left = min(bg.width - W, (bg.width - W) // 2 + 100)
    bg = bg.crop((left, (bg.height - H) // 2, left + W, (bg.height - H) // 2 + H))
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for x in range(W):
        a = int(min(1.0, max(0.0, 1.0 - (x - 380) / 360.0)) * 238)
        sd.line([(x, 0), (x, H)], fill=(255, 248, 236, a))
    img = Image.alpha_composite(bg.convert("RGBA"), shade)
    d = ImageDraw.Draw(img)
    d.text((56, 150), "MAHASIGMA", font=font(108), fill="white", anchor="lm", stroke_width=9, stroke_fill=INK)
    d.text((62, 258), "SIMULATOR", font=font(70), fill=YELLOW, anchor="lm", stroke_width=7, stroke_fill=INK)
    d.text((64, 340), "Bertahan hidup jadi mahasiswa Indonesia", font=font(34), fill=INK, anchor="lm")
    d.text((64, 384), "Survive Indonesian college life", font=font(28), fill=(93, 86, 112), anchor="lm")
    img.convert("RGB").save(dst, optimize=True)


def main() -> None:
    raw = pathlib.Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    shutil.copy(ROOT / "game/assets/icons/icon_512.png", OUT / "icon-512.png")
    feature(raw / "feature_bg.png", OUT / "feature-graphic-1024x500.png")
    for lang, idx in (("id-ID", 2), ("en-US", 3)):
        sub = "id" if lang == "id-ID" else "en"
        promo_dir = OUT / "phone-screenshots" / lang
        plain_dir = OUT / "phone-screenshots-plain" / lang
        promo_dir.mkdir(parents=True, exist_ok=True)
        plain_dir.mkdir(parents=True, exist_ok=True)
        for i, s in enumerate(SHOTS, 1):
            src = raw / sub / f"{s[0]}.png"
            promo(src, s[1], s[idx], promo_dir / f"{i:02d}-{s[0]}.png")
            shutil.copy(src, plain_dir / f"{i:02d}-{s[0]}.png")
    print("graphics written to", OUT)


if __name__ == "__main__":
    main()
