"""Paints the Fermenting Shelf from box parts projected into the tile's iso view."""
import math
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter

TILE_W, TILE_H = 128, 256
SS = 6

# a, b: ends of the wall edge at plank height. d: wall to plank front.
FACE_GEOMETRY = {
    "S": dict(a=(65, 81), b=(124, 114), d=(-17, 9)),
    "E": dict(a=(64, 80), b=(2, 111), d=(17, 8)),
    "W": dict(a=(123, 109), b=(61, 147), d=(-16, -6)),
    "N": dict(a=(5, 110), b=(63, 144), d=(16, -9)),
}

# Tones follow the vanilla bookcase. Vanilla furniture has no outlines: faces are
# separated by light, with soft grain and brighter strips along the corners.
WOOD = (146, 78, 46)
WOOD_HIGHLIGHT = (196, 118, 74, 150)
METAL = (74, 75, 78)
LIT_TOP, LIT_FRONT, LIT_SIDE, LIT_RAIL, LIT_BACK = 1.0, 0.76, 0.6, 0.72, 0.34
GRAIN_TONES = (0.93, 0.96, 1.04, 1.07)
GRAIN_BLUR = 0.35  # tile pixels
FACE_FADE = 0.68  # brightness at the bottom of a vertical face

POST_W = 6.5
POST_TOP, POST_BOTTOM, POST_CAP = 37.0, -15.0, 30.0
ARM_W, ARM_DEPTH, ARM_H = 5.5, 1.16, 7.0
PLANK_H = 4.0
RAIL_LOW, RAIL_SLOT, RAIL_HIGH = 5.0, 15.0, 26.0
DIAMONDS = [(0.33, 7.0, 6.0), (0.67, 7.0, 6.0)]  # position along the rail, half width, half height
STRAP_W = 3.0
STRAP_TOP_Z, STRAP_FOOT_D = 25.0, 0.92


class Shelf:
    def __init__(self, face):
        g = FACE_GEOMETRY[face]
        self.a, self.d = g["a"], g["d"]
        wall = (g["b"][0] - g["a"][0], g["b"][1] - g["a"][1])
        self.length = math.hypot(*wall)
        self.w = (wall[0] / self.length, wall[1] / self.length)
        self.wall_behind = self.d[1] > 0
        self.image = Image.new("RGBA", (TILE_W * SS, TILE_H * SS), (0, 0, 0, 0))

    def at(self, u, d, z):
        """u: pixels along the wall. d: fraction of plank depth. z: pixels above the plank."""
        return (self.a[0] + self.w[0] * u + self.d[0] * d, self.a[1] + self.w[1] * u + self.d[1] * d - z)

    def fill(self, poly, base, shade, grain_start, grain_end, seed, fade=False):
        """Paints a polygon with wood grain running from grain_start to grain_end."""
        scaled = [(x * SS, y * SS) for x, y in poly]
        mask = Image.new("L", self.image.size, 0)
        ImageDraw.Draw(mask).polygon(scaled, fill=255)
        box = mask.getbbox()
        if box is None:
            return
        tone = lambda k: tuple(min(255, int(c * k)) for c in base) + (255,)
        width, height = box[2] - box[0], box[3] - box[1]
        texture = Image.new("RGBA", (width, height), tone(shade))
        if grain_start is not None:
            draw = ImageDraw.Draw(texture)
            rng = random.Random(seed)
            dx, dy = grain_end[0] - grain_start[0], grain_end[1] - grain_start[1]
            span = math.hypot(dx, dy) or 1
            ux, uy, nx, ny = dx / span, dy / span, -dy / span, dx / span
            reach = max(width, height)
            for _ in range(int(reach / SS * 1.5) + 8):
                off = rng.uniform(-reach / 2, reach / 2)
                along = rng.uniform(-reach / 2, reach / 2)
                run = rng.uniform(reach * 0.2, reach * 0.6)
                x0 = width / 2 + nx * off + ux * along
                y0 = height / 2 + ny * off + uy * along
                k = shade * rng.choice(GRAIN_TONES)
                draw.line([(x0, y0), (x0 + ux * run, y0 + uy * run)], fill=tone(k), width=rng.choice((6, 9, 12)))
            texture = texture.filter(ImageFilter.GaussianBlur(GRAIN_BLUR * SS))
        if fade:
            ramp = Image.linear_gradient("L").resize((width, height)).point(lambda v: 255 - int(v * (1 - FACE_FADE)))
            texture = ImageChops.multiply(texture, Image.merge("RGBA", (ramp, ramp, ramp, Image.new("L", (width, height), 255))))
        self.image.paste(texture, box[:2], mask.crop(box))

    def edge(self, start, end, width=3):
        """Draws the bright strip vanilla puts along a lit corner."""
        ImageDraw.Draw(self.image).line([(start[0] * SS, start[1] * SS), (end[0] * SS, end[1] * SS)], fill=WOOD_HIGHLIGHT, width=width)

    def box(self, u0, u1, d0, d1, z0, z1, seed, grain_along_wall=True, nose=False):
        """Draws the three faces of a box the viewer can see."""
        at = self.at
        side_u = u1 if self.w[1] > 0 else u0
        front_d = d1 if self.wall_behind else d0

        def grain(z):
            if grain_along_wall:
                return at(u0, d0, z), at(u1, d0, z)
            return at(u0, d0, z), at(u0, d1, z)

        def bottom(d):
            return z0 + ARM_H * 0.5 * smooth((d - d1 + 0.34) / 0.34) if nose else z0

        steps = [d0 + (d1 - d0) * i / 16 for i in range(17)]
        side = [at(side_u, d, z1) for d in steps] + [at(side_u, d, bottom(d)) for d in reversed(steps)]
        vertical_grain = (at(u0, d0, z1), at(u0, d0, z0))
        if nose or abs(z1 - z0) < (d1 - d0) * 20:
            self.fill(side, WOOD, LIT_SIDE, at(u0, d0, 0), at(u0, d1, 0), seed + 1)
        else:
            self.fill(side, WOOD, LIT_SIDE, *vertical_grain, seed + 1, fade=True)

        front = [at(u0, front_d, z1), at(u1, front_d, z1), at(u1, front_d, bottom(front_d)), at(u0, front_d, bottom(front_d))]
        tall = abs(z1 - z0) >= 12
        self.fill(front, WOOD, LIT_FRONT, *(vertical_grain if tall else grain(z0)), seed + 2, fade=tall)

        top = [at(u0, d0, z1), at(u1, d0, z1), at(u1, d1, z1), at(u0, d1, z1)]
        self.fill(top, WOOD, LIT_TOP, *grain(z1), seed)
        self.edge(at(u0, front_d, z1), at(u1, front_d, z1))
        self.edge(at(side_u, d0, z1), at(side_u, d1, z1))

    def rail_outline(self, z_low, z_high, notch_from_top):
        """One back board. Diamonds are cut as V notches from its edge next to the slot."""
        left, right = POST_W, self.length - POST_W
        span = right - left
        edge = z_high if notch_from_top else z_low
        direction = -1 if notch_from_top else 1
        notched = []
        for position, half_w, half_h in DIAMONDS:
            u = left + span * position
            notched += [(u - half_w, edge), (u, edge + direction * half_h), (u + half_w, edge)]
        straight = z_low if notch_from_top else z_high
        return [(left, edge)] + notched + [(right, edge), (right, straight), (left, straight)]

    def rails(self):
        slot = RAIL_SLOT
        boards = [
            self.rail_outline(RAIL_LOW, slot - 0.6, True),
            self.rail_outline(slot + 0.6, RAIL_HIGH, False),
        ]
        for index, board in enumerate(boards):
            behind = [self.at(u, 0.02, z) for u, z in board]
            face = [self.at(u, 0.13, z) for u, z in board]
            self.fill(behind, WOOD, LIT_BACK, None, None, 0)
            self.fill(face, WOOD, LIT_RAIL, self.at(0, 0.13, 0), self.at(self.length, 0.13, 0), 40 + index, fade=True)
        top = RAIL_HIGH
        self.edge(self.at(POST_W, 0.13, top), self.at(self.length - POST_W, 0.13, top))

    def post(self, u0, seed):
        u1 = u0 + POST_W
        self.box(u0, u1, 0, 0.2, POST_BOTTOM, POST_CAP, seed, grain_along_wall=False)
        self.box(u0, u1, 0, 0.11, POST_CAP, POST_TOP, seed + 5, grain_along_wall=False)

    def arm(self, u0, seed):
        self.box(u0, u0 + ARM_W, 0, ARM_DEPTH, -ARM_H, 0.6, seed, grain_along_wall=False, nose=True)

    def plank(self):
        self.box(ARM_W, self.length - ARM_W, 0, 1.0, -PLANK_H, 0, 60)

    def strap(self, u):
        draw = ImageDraw.Draw(self.image)
        tone = lambda k: tuple(min(255, int(c * k)) for c in METAL) + (255,)
        top, foot = (0.2, STRAP_TOP_Z), (STRAP_FOOT_D, 0.8)
        half = STRAP_W / 2
        poly = [self.at(u - half, *top), self.at(u + half, *top), self.at(u + half, *foot), self.at(u - half, *foot)]
        scaled = [(x * SS, y * SS) for x, y in poly]
        draw.polygon(scaled, fill=tone(1.0))
        draw.line([scaled[0], scaled[3]], fill=tone(1.55), width=4)
        draw.line([scaled[1], scaled[2]], fill=tone(0.72), width=4)
        for d, z in (top, foot):
            x, y = self.at(u, d, z)
            r = 2.1 * SS
            draw.rectangle([x * SS - r, y * SS - r * 0.8, x * SS + r, y * SS + r * 0.8], fill=tone(1.15))
            b = 1.0 * SS
            draw.ellipse([x * SS - b, y * SS - b, x * SS + b, y * SS + b], fill=tone(0.7))
            draw.ellipse([x * SS - b * 0.5, y * SS - b * 0.6, x * SS, y * SS - b * 0.1], fill=tone(1.7))

    def paint(self):
        left_end, right_end = 0, self.length - ARM_W
        far, near = (left_end, right_end) if self.w[1] > 0 else (right_end, left_end)
        post_far, post_near = (0, self.length - POST_W) if self.w[1] > 0 else (self.length - POST_W, 0)
        strap_far, strap_near = far + ARM_W / 2, near + ARM_W / 2

        if self.wall_behind:
            self.post(post_far, 10)
            self.post(post_near, 20)
            self.rails()
            self.arm(far, 30)
            self.plank()
            self.arm(near, 35)
        else:
            self.arm(far, 30)
            self.plank()
            self.arm(near, 35)
            self.post(post_far, 10)
            self.post(post_near, 20)
        self.strap(strap_far)
        self.strap(strap_near)
        return self.image.resize((TILE_W, TILE_H), Image.LANCZOS)


def smooth(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def paint_shelf(face):
    return Shelf(face).paint()
