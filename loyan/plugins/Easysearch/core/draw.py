import os
from PIL import Image, ImageDraw, ImageFont

from loyan.plugins.core.zhfont import get_zh_font

PLUGIN_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE_DIR = os.path.join(PLUGIN_DIR, "data")

PHONE_W = 390
PHONE_H = 844


def _load_font(size: int) -> ImageFont.FreeTypeFont:
    return get_zh_font(size)


def draw_error(msg: str) -> str:
    img = Image.new("RGB", (PHONE_W, PHONE_H), (28, 28, 30))
    draw = ImageDraw.Draw(img)
    f = _load_font(16)
    lines = []
    for line in msg.split("\n"):
        lines.append(line)
    y = PHONE_H // 2 - len(lines) * 14
    for line in lines:
        w = draw.textlength(line, font=f)
        draw.text(((PHONE_W - w) // 2, y), line, fill=(255, 59, 48), font=f)
        y += 28
    out_path = os.path.join(CACHE_DIR, "search_error.png")
    os.makedirs(CACHE_DIR, exist_ok=True)
    img.save(out_path, "PNG")
    return out_path
