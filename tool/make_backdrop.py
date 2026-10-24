import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

W, H = 1080, 2340
random.seed(7)

img = Image.new("RGB", (W, H))
top, bottom = (212, 226, 238), (246, 232, 222)
px = img.load()
for y in range(H):
    t = y / (H - 1)
    c = tuple(round(a + (b - a) * t) for a, b in zip(top, bottom))
    for x in range(W):
        px[x, y] = c

palette = [(104, 150, 196), (232, 150, 120), (150, 196, 170), (248, 206, 120), (170, 140, 210)]
for _ in range(14):
    r = random.randint(140, 320)
    x, y = random.randint(-100, W + 100), random.randint(-100, H + 100)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse((x - r, y - r, x + r, y + r), fill=150)
    img.paste(Image.new("RGB", (W, H), random.choice(palette)), (0, 0), mask.filter(ImageFilter.GaussianBlur(80)))

lines = ImageDraw.Draw(img)
for i in range(0, W, 54):
    lines.line((i, 0, i, H), fill=(255, 255, 255), width=2)
for row, cy in enumerate(range(150, H, 230)):
    for col in range(6):
        x = 120 + col * 168 + (84 if row % 2 else 0)
        lines.ellipse((x - 26, cy - 26, x + 26, cy + 26), fill=(40, 52, 70))

out = Path(__file__).resolve().parent.parent / "example" / "assets" / "backdrop.png"
img.save(out, optimize=True)
print(out, img.size)
