# File: sprite_lib.py
# Description: Tiny pixel-drawing toolkit (canvas, lines, polygons, outline pass, 2-bone IK, sheet packing) used by all art generators.
# Author: Jose-Jorge HERNANDEZ
# Company: Parlee Conseiller, Inc.
# Date: 2026-10-12
# Last edit date: 2026-10-12
# Version: 1.0.0
import math
from PIL import Image, ImageDraw

from palette import CLEAR, OUTLINE


class Canvas:
    """A transparent RGBA pixel canvas with integer-pixel drawing primitives."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), CLEAR)
        self.px = self.img.load()

    # -- primitives ---------------------------------------------------------
    def set(self, x, y, c):
        """Set one pixel if inside the canvas."""
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[x, y] = c

    def rect(self, x, y, w, h, c):
        """Filled rectangle (top-left x,y; width w; height h)."""
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def line(self, p0, p1, c, thick=1):
        """Bresenham-style line; thick>1 stamps a square brush for chunky limbs."""
        x0, y0 = p0
        x1, y1 = p1
        steps = int(max(abs(x1 - x0), abs(y1 - y0), 1) * 2)
        off = (thick - 1) / 2.0
        for i in range(steps + 1):
            t = i / steps
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            for dy in range(thick):
                for dx in range(thick):
                    self.set(x - off + dx, y - off + dy, c)

    def poly(self, pts, c):
        """Filled polygon via PIL's rasteriser (no anti-aliasing, so pixel-art safe)."""
        d = ImageDraw.Draw(self.img)
        d.polygon([(int(round(x)), int(round(y))) for x, y in pts], fill=c)

    def ellipse(self, cx, cy, rx, ry, c):
        """Filled ellipse centred at cx,cy."""
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if rx and ry and ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def paste(self, other, ox=0, oy=0):
        """Alpha-composite another canvas on top at an offset."""
        self.img.alpha_composite(other.img, (ox, oy))
        self.px = self.img.load()

    # -- finishing ----------------------------------------------------------
    def outline(self, color=OUTLINE):
        """Add a 1px outline around every opaque shape (4-neighbour), on transparent pixels only."""
        src = self.img.copy().load()
        for y in range(self.h):
            for x in range(self.w):
                if src[x, y][3] == 0:
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                        if 0 <= nx < self.w and 0 <= ny < self.h and src[nx, ny][3] > 0:
                            self.px[x, y] = color
                            break

    def flipped(self):
        """Return a horizontally mirrored copy."""
        c = Canvas(self.w, self.h)
        c.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        c.px = c.img.load()
        return c


def ik2(a, t, l1, l2, bend=1):
    """Two-bone IK: joint position for a limb from anchor a toward target t (bend=+1/-1 picks the elbow/knee side).

    If the target is out of reach the limb is fully extended toward it.
    """
    ax, ay = a
    tx, ty = t
    dx, dy = tx - ax, ty - ay
    d = max(math.hypot(dx, dy), 1e-6)
    d = min(d, l1 + l2 - 1e-3)
    # Law of cosines gives the angle at the anchor between the target line and the first bone.
    cosang = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
    ang = math.acos(max(-1.0, min(1.0, cosang)))
    base = math.atan2(dy, dx)
    j = base + bend * ang
    return (ax + math.cos(j) * l1, ay + math.sin(j) * l1)


def pack_strip(frames, pad=0):
    """Pack a list of Canvases (same size) into one horizontal sprite strip image."""
    w, h = frames[0].w, frames[0].h
    sheet = Image.new("RGBA", (len(frames) * (w + pad), h), CLEAR)
    for i, f in enumerate(frames):
        sheet.alpha_composite(f.img, (i * (w + pad), 0))
    return sheet


def upscale(img, k):
    """Nearest-neighbour upscale for previews."""
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
