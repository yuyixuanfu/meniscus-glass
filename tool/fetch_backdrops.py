import io
import urllib.request
from pathlib import Path

from PIL import Image

W, H = 1080, 2340
OUT = Path(__file__).resolve().parent.parent / "example" / "assets"

PHOTOS = {
    "sea": "sts054-152-102",
    "clouds": "iss040e006214",
    "reef": "iss009e23808",
    "desert": "iss007e08259",
}


def fetch(nasa_id):
    for size in ("orig", "large"):
        url = f"https://images-assets.nasa.gov/image/{nasa_id}/{nasa_id}~{size}.jpg"
        try:
            with urllib.request.urlopen(url, timeout=60) as r:
                return Image.open(io.BytesIO(r.read())).convert("RGB")
        except Exception as e:
            print(f"{url}: {e}")
    raise SystemExit(f"could not fetch {nasa_id}")


def trim_caption(img):
    grey = img.convert("L")
    y = img.height
    while y > img.height * 0.8:
        row = grey.crop((0, y - 1, img.width, y)).resize((1, 1), Image.BOX).getpixel((0, 0))
        if row < 225:
            break
        y -= 1
    return img.crop((0, 0, img.width, y))


def portrait(img):
    img = trim_caption(img)
    s = max(W / img.width, H / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x, y = (img.width - W) // 2, (img.height - H) // 2
    return img.crop((x, y, x + W, y + H))


for name, nasa_id in PHOTOS.items():
    path = OUT / f"{name}.jpg"
    portrait(fetch(nasa_id)).save(path, quality=86, optimize=True, progressive=True)
    print(path, path.stat().st_size)
