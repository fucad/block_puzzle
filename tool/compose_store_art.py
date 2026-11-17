#!/usr/bin/env python3
"""Composes store graphics from raw simulator captures.

Input:  docs/store/raw/{menu,classic,map,gems,stats}.png  (tool/capture_screenshots.sh)
        assets/icon/icon.png
Output: docs/store/ios/{en,ko}/NN_<scene>.png   1320x2868 (App Store 6.9")
        docs/store/play/{en,ko}/NN_<scene>.png  1080x1920 (Play phone, 9:16)
        docs/store/play/feature_graphic.png     1024x500
        docs/store/play/icon_512.png            512x512

Requires Pillow (pip install pillow). Fonts: macOS Apple SD Gothic Neo
(covers Latin + Hangul); pass another .ttc/.ttf path via FONT=... elsewhere.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RAW = os.path.join(ROOT, 'docs/store/raw')
OUT = os.path.join(ROOT, 'docs/store')
FONT = os.environ.get('FONT', '/System/Library/Fonts/AppleSDGothicNeo.ttc')
FONT_HEAVY_INDEX = 6   # "Bold" face in AppleSDGothicNeo.ttc
FONT_MED_INDEX = 4     # "SemiBold"

BG_TOP = (58, 76, 140)
BG_BOTTOM = (28, 36, 72)
ACCENT = (255, 212, 71)
WHITE = (255, 255, 255)
SOFT = (200, 214, 255)

# (scene, EN headline, EN sub, KO headline, KO sub)
SHOTS = [
    ('classic', 'Zero ads.\nJust blocks.', 'Not even "optional" ones.',
     '광고 0개.\n블록만 있어요.', '"선택형 광고"조차 없습니다.'),
    ('gems', 'Collect the gems', 'Hand-crafted quest levels',
     '보석을 모으세요', '직접 디자인한 퀘스트 레벨'),
    ('map', '40 quest levels', 'New packs arrive without updates',
     '퀘스트 40단계', '업데이트 없이 새 레벨 팩 추가'),
    ('menu', 'Free forever', 'No purchases. No account. Offline.',
     '영원히 무료', '결제·계정 없음. 오프라인 플레이.'),
    ('stats', 'Your stats stay\non your phone', 'We collect nothing. Open source.',
     '기록은 내 폰에만', '어떤 정보도 수집하지 않습니다. 오픈소스.'),
]


def font(size, heavy=True):
    try:
        return ImageFont.truetype(FONT, size, index=FONT_HEAVY_INDEX if heavy else FONT_MED_INDEX)
    except OSError:
        return ImageFont.truetype(FONT, size)


def gradient(w, h):
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM))
        for x in range(w):
            px[x, y] = c
    return img


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def centered_text(draw, cx, y, text, fnt, fill, spacing):
    box = draw.multiline_textbbox((0, 0), text, font=fnt, spacing=spacing, align='center')
    w, h = box[2] - box[0], box[3] - box[1]
    draw.multiline_text((cx - w / 2, y), text, font=fnt, fill=fill, spacing=spacing, align='center')
    return y + h


def compose(raw_path, w, h, head, sub, out_path):
    canvas = gradient(w, h).convert('RGBA')
    d = ImageDraw.Draw(canvas)
    s = w / 1320  # scale factor relative to the iOS layout
    y = centered_text(d, w / 2, 120 * s if h / w > 2 else 80 * s, head, font(round(118 * s)), WHITE, round(18 * s))
    y = centered_text(d, w / 2, y + 56 * s, sub, font(round(52 * s), heavy=False), ACCENT, 8)

    shot = Image.open(raw_path).convert('RGB')
    top = y + 70 * s
    avail_h = h - top - 60 * s
    scale = min(avail_h / shot.height, (w * 0.80) / shot.width)
    sw, sh = round(shot.width * scale), round(shot.height * scale)
    shot = rounded(shot.resize((sw, sh), Image.LANCZOS), round(70 * s * scale * 1.6))
    x = (w - sw) // 2
    shadow = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 20 * s, x + sw, top + sh + 20 * s), round(80 * s), fill=(0, 0, 0, 120))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(30 * s)))
    canvas.alpha_composite(shot, (x, round(top)))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.convert('RGB').save(out_path, optimize=True)


def feature_graphic(icon_path, out_path):
    w, h = 1024, 500
    canvas = gradient(w, h).convert('RGBA')
    icon = rounded(Image.open(icon_path).convert('RGB').resize((300, 300), Image.LANCZOS), 66)
    canvas.alpha_composite(icon, (90, 100))
    d = ImageDraw.Draw(canvas)
    d.text((440, 120), 'Block Puzzle', font=font(84), fill=WHITE)
    d.text((444, 232), 'No ads. No tracking.', font=font(44, heavy=False), fill=ACCENT)
    d.text((444, 290), 'Free forever.', font=font(44, heavy=False), fill=ACCENT)
    d.text((444, 370), 'Open source · FUCAD', font=font(32, heavy=False), fill=SOFT)
    canvas.convert('RGB').save(out_path, optimize=True)


def main():
    missing = [s for s, *_ in SHOTS if not os.path.exists(os.path.join(RAW, s + '.png'))]
    if missing:
        sys.exit(f'missing raw captures: {missing} — run tool/capture_screenshots.sh')
    for i, (scene, en_h, en_s, ko_h, ko_s) in enumerate(SHOTS, 1):
        raw = os.path.join(RAW, scene + '.png')
        for lang, head, sub in (('en', en_h, en_s), ('ko', ko_h, ko_s)):
            name = f'{i:02d}_{scene}.png'
            compose(raw, 1320, 2868, head, sub, os.path.join(OUT, 'ios', lang, name))
            compose(raw, 1080, 1920, head, sub, os.path.join(OUT, 'play', lang, name))
    icon = os.path.join(ROOT, 'assets/icon/icon.png')
    os.makedirs(os.path.join(OUT, 'play'), exist_ok=True)
    feature_graphic(icon, os.path.join(OUT, 'play', 'feature_graphic.png'))
    Image.open(icon).convert('RGB').resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT, 'play', 'icon_512.png'), optimize=True)
    print('store art written to docs/store/')


if __name__ == '__main__':
    main()
