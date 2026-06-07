"""
Scan-like augmentation.

Synthetic renders are too clean — a model trained only on them learns the font,
not the noise of a real scan or phone photo, and falls apart on actual pages.
Each augmentation here imitates one degradation real captures have: skew from a
tilted scan, blur from focus, speckle from cheap paper, ink spread or thinning
from the press, JPEG blocking from a phone camera.

Every transform is applied probabilistically with a per-call RNG, so the same
line rendered N times yields N different plausible captures. Geometry is padded
first so rotation/shear never clips the glyphs.
"""

from __future__ import annotations

import io

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


def augment(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    """Return one randomly-degraded copy of `img` (mode L)."""
    img = img.convert("L")
    img = _pad(img, rng.integers(6, 20))

    if rng.random() < 0.8:
        img = _rotate(img, rng)
    if rng.random() < 0.5:
        img = _shear(img, rng)
    if rng.random() < 0.4:
        img = _ink(img, rng)            # erosion/dilation: bold or thin print
    if rng.random() < 0.6:
        img = _resolution(img, rng)     # downscale/upscale resolution loss
    if rng.random() < 0.6:
        img = img.filter(ImageFilter.GaussianBlur(rng.uniform(0.3, 1.4)))
    if rng.random() < 0.7:
        img = _brightness_contrast(img, rng)
    if rng.random() < 0.7:
        img = _noise(img, rng)          # paper speckle / sensor noise
    if rng.random() < 0.5:
        img = _jpeg(img, rng)           # compression blocking

    return img


def _pad(img: Image.Image, px: int) -> Image.Image:
    out = Image.new("L", (img.width + 2 * px, img.height + 2 * px), 255)
    out.paste(img, (px, px))
    return out


def _rotate(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    return img.rotate(
        rng.uniform(-2.2, 2.2), resample=Image.BICUBIC, expand=True, fillcolor=255
    )


def _shear(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    f = rng.uniform(-0.12, 0.12)
    return img.transform(
        img.size, Image.AFFINE, (1, f, 0, 0, 1, 0),
        resample=Image.BICUBIC, fillcolor=255,
    )


def _ink(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    size = int(rng.choice([3, 3, 5]))
    # MinFilter darkens/thickens strokes (ink bleed); MaxFilter thins them.
    return img.filter(ImageFilter.MinFilter(size) if rng.random() < 0.5
                      else ImageFilter.MaxFilter(size))


def _resolution(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    scale = rng.uniform(0.45, 0.85)
    small = img.resize(
        (max(1, int(img.width * scale)), max(1, int(img.height * scale))),
        Image.BILINEAR,
    )
    return small.resize(img.size, Image.BILINEAR)


def _brightness_contrast(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    img = ImageEnhance.Brightness(img).enhance(rng.uniform(0.8, 1.15))
    img = ImageEnhance.Contrast(img).enhance(rng.uniform(0.8, 1.25))
    return img


def _noise(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    arr = np.asarray(img, dtype=np.float32)
    arr += rng.normal(0, rng.uniform(4, 16), arr.shape)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "L")


def _jpeg(img: Image.Image, rng: np.random.Generator) -> Image.Image:
    buf = io.BytesIO()
    img.convert("L").save(buf, format="JPEG", quality=int(rng.integers(30, 80)))
    buf.seek(0)
    return Image.open(buf).convert("L")
