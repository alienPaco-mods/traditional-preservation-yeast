#!/usr/bin/env python3
"""Builds the Fermenting Shelf tileset (42/media/*.tiles and texturepacks/*.pack) and the culture jars' item icons.

The shelf itself is painted by shelf_art.py. This draws one jar per shelf slot in each look and each kind of jar,
which TraditionalPreservationYeastShelf.lua layers on top, then packs them all. A glass jar shows the culture
through it; a clay jar is opaque, so its look is the cloth tied over its mouth: pale linen when started, stained by
halfway, dark with froth at the rim when done. A fed (hopped) jar carries a hop cone under its twine.

Usage: python3 tools/build_shelf_tileset.py
Needs Pillow. Rerun after editing the tables or colours here or in shelf_art.py.
"""
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw

from shelf_art import FACE_GEOMETRY, paint_shelf

sys.path.insert(0, str(Path(os.environ.get("TPCORE", Path(__file__).resolve().parents[2] / "TraditionalPreservationCore")) / "tools"))
import pzart  # noqa: E402
import cloth_art  # noqa: E402

NAME = "traditionalpreservationyeast"
TILESET = NAME + "_01"
COLUMNS = 8
SUPERSAMPLE = 8
PAGE_SIZE = 1024
ICON_SIZE = 32
ICON_SCALE = 1.7  # a jar in an item icon, against its size on the shelf

FACES = ["S", "E", "W", "N"]

JAR_POSITIONS = [0.16, 0.33, 0.5, 0.67, 0.84]  # one per culture slot
JAR_WIDTH, JAR_HEIGHT = 10.0, 16.0
CULTURE_LEVEL = 0.68

GLASS_EDGE = (120, 120, 112, 130)
GLASS = (205, 222, 226, 80)
# Ferment Culture fresh, halfway, done, then Raise Fed Culture rising and done (hop tea turns it greener gold).
# Named in JAR_LOOK_NAMES for the generated Tiles.lua.
JAR_LOOK_NAMES = ["fresh", "halfway", "done", "fedRising", "fedDone"]
HOPPED_LOOKS = {3, 4}
DONE_LOOKS = {2, 4}
JAR_COLOURS = [
    dict(culture=(206, 202, 182, 245), shade=(170, 166, 148, 245), top=(226, 222, 204, 255), bubble=(236, 232, 216, 200)),
    dict(culture=(196, 158, 88, 245), shade=(160, 124, 66, 245), top=(222, 190, 124, 255), bubble=(238, 214, 158, 220)),
    dict(culture=(140, 88, 42, 245), shade=(108, 66, 32, 245), top=(214, 182, 122, 255), bubble=(226, 196, 138, 230)),
    dict(culture=(192, 178, 112, 245), shade=(156, 144, 88, 245), top=(214, 204, 146, 255), bubble=(230, 224, 180, 210)),
    dict(culture=(150, 118, 54, 245), shade=(118, 92, 40, 245), top=(222, 206, 150, 255), bubble=(236, 222, 170, 235)),
]
HIGHLIGHT = (255, 255, 255, 80)
LID = (120, 114, 104, 255)
LID_TOP = (156, 150, 138, 255)
SHADOW = (24, 16, 10, 90)

BUBBLE_SPOTS = [(-0.2, 0.30), (0.18, 0.46), (-0.05, 0.62), (0.24, 0.72)]

# The jars a culture can be in, named in JAR_KIND_NAMES for Tiles.lua. Clay colours are vanilla's own jar textures'
# (ClayJar_Fired_Unglazed, ClayJar_Glazed).
JAR_KIND_NAMES = ["glass", "clay", "glazed"]
CLAYS = {
    "clay": dict(body=(206, 157, 120, 255), shade=(160, 112, 82, 255), light=(226, 184, 150, 255)),
    "glazed": dict(body=(130, 145, 158, 255), shade=(92, 104, 118, 255), light=(170, 186, 198, 255)),
}
# The cloth over a clay jar's mouth, by look: linen, stained, dark and wet, then the same for a fed jar.
CLOTHS = [(236, 232, 218, 255), (196, 172, 124, 255), (122, 92, 56, 255), (196, 172, 124, 255), (122, 92, 56, 255)]
FROTH = (248, 242, 222, 255)
TWINE = (150, 120, 76, 255)
HOP = (122, 150, 70, 255)
HOP_DARK = (86, 110, 48, 255)

# Item icons: each culture item in each jar, in the look it has in the hand. TraditionalPreservationYeast.lua sets a
# clay one's icon from these names (Item_<item>_<kind>.png).
ICON_ITEMS = {"FermentingCulture": 0, "FedCulture": 3, "ActiveCulture": 2, "ActiveCultureHopped": 4}


def shelf_props(facing):
    return [
        ("CanBreak", ""),
        ("CanScrap", ""),
        ("CustomName", "Fermenting Shelf"),
        ("Facing", facing),
        ("IsHigh", ""),
        ("IsMoveAble", ""),
        ("Material", "Wood"),
        ("Material2", "Nails"),
        ("MaterialType", "Wood"),
        ("MoveType", "WallObject"),
        ("PickUpTool", "Hammer"),
        ("PickUpWeight", "50"),
        ("PlaceTool", "Hammer"),
    ]


def jar_props(facing):
    return [("Facing", facing)]


def jar_index(face_index, slot, look, kind=0):
    """jarSprite in TraditionalPreservationYeastShelf.lua reads these numbers from the generated Tiles.lua."""
    return len(FACES) + ((kind * len(JAR_LOOK_NAMES) + look) * len(JAR_POSITIONS) + slot) * len(FACES) + face_index


# Yeast cakes on TP Core's Drying Cloth: three cakes a lot, at each of its five lots, wet, dry or dead (killed by
# heat). The same on either face of the cloth: its lots are a die's five.
CAKE_STATES = ["wet", "dry", "dead"]
CAKES = {
    "wet": dict(top=(232, 214, 150), side=(196, 176, 112), mark=(250, 240, 200)),
    "dry": dict(top=(206, 170, 96), side=(160, 126, 66), mark=(150, 112, 58)),
    "dead": dict(top=(120, 92, 60), side=(86, 64, 42), mark=(70, 52, 34)),
}
CAKE_SPOTS = [(-0.06, 0.0), (0.0, -0.06), (0.04, 0.04)]
FIRST_CAKE = jar_index(0, 0, 0, len(JAR_KIND_NAMES))


def cake_index(lot, state):
    return FIRST_CAKE + CAKE_STATES.index(state) * len(cloth_art.LOTS) + lot


TILE_COUNT = FIRST_CAKE + len(CAKE_STATES) * len(cloth_art.LOTS)
ROWS = -(-TILE_COUNT // COLUMNS)

TILE_PROPS = {}
for face_index, face in enumerate(FACES):
    TILE_PROPS[face_index] = shelf_props(face)
    for kind in range(len(JAR_KIND_NAMES)):
        for slot in range(len(JAR_POSITIONS)):
            for look in range(len(JAR_LOOK_NAMES)):
                TILE_PROPS[jar_index(face_index, slot, look, kind)] = jar_props(face)


def shapes(d, scale):
    """Ellipse and rectangle in tile pixels, onto a supersampled draw."""
    s = SUPERSAMPLE

    def ellipse(x, y, rx, ry, fill):
        d.ellipse([(x - rx) * s, (y - ry) * s, (x + rx) * s, (y + ry) * s], fill=fill)

    def rect(x0, y0, x1, y1, fill):
        d.rectangle([x0 * s, y0 * s, x1 * s, y1 * s], fill=fill)

    return ellipse, rect


def draw_hop(d, x, y, scale):
    """A small hop cone tucked under the twine."""
    ellipse, _ = shapes(d, scale)
    ellipse(x, y, 1.3 * scale, 1.7 * scale, HOP_DARK)
    ellipse(x - 0.2 * scale, y - 0.2 * scale, 1.0 * scale, 1.3 * scale, HOP)


def draw_glass(layer, cx, base_y, look, scale=1.0):
    """Composites one glass jar onto layer, its base centred on (cx, base_y) in tile pixels."""
    colours = JAR_COLOURS[look]
    jar = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(jar)
    ellipse, rect = shapes(d, scale)

    width, height = JAR_WIDTH * scale, JAR_HEIGHT * scale
    half_w = width / 2
    rim = width * 0.2  # vertical radius of the jar's ellipses
    top_y = base_y - height
    lid_h = height * 0.17
    shoulder_y = top_y + lid_h

    ellipse(cx + 1.5 * scale, base_y + 0.5 * scale, half_w + scale, rim + 0.5 * scale, SHADOW)

    # Glass edge first, then everything inset by a pixel on top of it.
    ellipse(cx, base_y, half_w, rim, GLASS_EDGE)
    rect(cx - half_w, shoulder_y, cx + half_w, base_y, GLASS_EDGE)
    inner = half_w - 0.8 * scale

    ellipse(cx, base_y - 0.3 * scale, inner, rim - 0.4 * scale, GLASS)
    rect(cx - inner, shoulder_y, cx + inner, base_y - 0.3 * scale, GLASS)

    culture_y = base_y - (height - lid_h) * CULTURE_LEVEL
    ellipse(cx, base_y - 0.4 * scale, inner, rim - 0.4 * scale, colours["culture"])
    rect(cx - inner, culture_y, cx + inner, base_y - 0.4 * scale, colours["culture"])
    rect(cx + inner * 0.35, culture_y, cx + inner, base_y - 0.4 * scale, colours["shade"])
    ellipse(cx, culture_y, inner, rim - 0.6 * scale, colours["top"])

    for dx, rise in BUBBLE_SPOTS:
        ellipse(cx + dx * width, base_y - height * rise * 0.8, 0.6 * scale, 0.6 * scale, colours["bubble"])

    rect(cx - inner + 0.7 * scale, shoulder_y + scale, cx - inner + 1.7 * scale, base_y - 2.0 * scale, HIGHLIGHT)

    lid_rx = half_w - 0.6 * scale
    rect(cx - lid_rx, top_y, cx + lid_rx, shoulder_y, LID)
    ellipse(cx, shoulder_y, lid_rx, rim - 0.5 * scale, LID)
    ellipse(cx, top_y, lid_rx, rim - 0.5 * scale, LID_TOP)
    if look in HOPPED_LOOKS:
        draw_hop(d, cx + half_w - 1.2 * scale, top_y + 2.0 * scale, scale)

    layer.alpha_composite(jar)


def draw_clay(layer, cx, base_y, look, clay, scale=1.0):
    """A ceramic jar: round belly, short neck, a cloth tied over the mouth."""
    jar = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(jar)
    ellipse, rect = shapes(d, scale)
    s = SUPERSAMPLE

    half_w = (JAR_WIDTH / 2 + 0.5) * scale
    rim = half_w * 0.4
    height = (JAR_HEIGHT - 1.0) * scale
    neck_w = half_w * 0.62
    neck_top = base_y - height
    neck_bottom = neck_top + 3.0 * scale
    belly_y = base_y - height * 0.45

    ellipse(cx + 1.5 * scale, base_y + 0.5 * scale, half_w + scale, rim + 0.5 * scale, SHADOW)
    # Belly: a tall ellipse over a foot, darker on the right as the glass jars are.
    ellipse(cx, belly_y, half_w, height * 0.47, clay["body"])
    rect(cx - half_w * 0.7, belly_y, cx + half_w * 0.7, base_y - 0.4 * scale, clay["body"])
    ellipse(cx, base_y - 0.4 * scale, half_w * 0.7, rim * 0.8, clay["body"])
    shade = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.ellipse([(cx - half_w) * s, (belly_y - height * 0.47) * s, (cx + half_w) * s, (belly_y + height * 0.47) * s], fill=clay["shade"])
    sd.rectangle([(cx - half_w) * s, 0, (cx + half_w * 0.3) * s, layer.size[1]], fill=(0, 0, 0, 0))
    jar.alpha_composite(shade)
    rect(cx - half_w * 0.62, belly_y - height * 0.3, cx - half_w * 0.42, belly_y + height * 0.15, clay["light"])
    # Neck, then the cloth: a disc over the mouth, its skirt down the neck, a twine band.
    rect(cx - neck_w, neck_top + scale, cx + neck_w, neck_bottom + scale, clay["shade"])
    cloth = CLOTHS[look]
    if look in DONE_LOOKS:  # done: froth pushing out under the cloth's edge
        for dx in (-0.8, -0.3, 0.25, 0.75):
            ellipse(cx + dx * neck_w * 1.4, neck_bottom - 0.2 * scale, 1.1 * scale, 0.9 * scale, FROTH)
    rect(cx - neck_w - 0.5 * scale, neck_top + 0.6 * scale, cx + neck_w + 0.5 * scale, neck_bottom - 0.6 * scale, cloth)
    ellipse(cx, neck_top + 0.6 * scale, neck_w + 0.7 * scale, rim * 0.55, cloth)
    rect(cx - neck_w - 0.5 * scale, neck_bottom - 1.6 * scale, cx + neck_w + 0.5 * scale, neck_bottom - 0.9 * scale, TWINE)
    if look in HOPPED_LOOKS:
        draw_hop(d, cx + neck_w + 0.6 * scale, neck_bottom - 1.0 * scale, scale)

    layer.alpha_composite(jar)


def draw_jar(layer, cx, base_y, look, kind, scale=1.0):
    name = JAR_KIND_NAMES[kind]
    if name in CLAYS:
        draw_clay(layer, cx, base_y, look, CLAYS[name], scale)
    else:
        draw_glass(layer, cx, base_y, look, scale)


def jar_spots(face):
    """Slot positions on the plank, rearmost first so layers stack correctly."""
    geometry = FACE_GEOMETRY[face]
    x0, y0 = (geometry["a"][i] + geometry["d"][i] / 2 for i in (0, 1))
    x1, y1 = (geometry["b"][i] + geometry["d"][i] / 2 for i in (0, 1))
    spots = [(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t) for t in JAR_POSITIONS]
    return sorted(spots, key=lambda spot: spot[1])


def draw_jar_tile(face, slot, look, kind):
    layer = pzart.new_layer(SUPERSAMPLE)
    cx, base_y = jar_spots(face)[slot]
    draw_jar(layer, cx, base_y, look, kind)
    return pzart.shrink(layer)


def draw_icon(look, kind):
    layer = pzart.new_layer(SUPERSAMPLE)
    draw_jar(layer, 64, 200, look, kind, ICON_SCALE)
    tile = pzart.shrink(layer)
    art = tile.crop(tile.getbbox())
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    icon.alpha_composite(art, ((ICON_SIZE - art.width) // 2, (ICON_SIZE - art.height) // 2))
    return icon


def draw_cakes(lot, state):
    """Three round flat cakes on a lot of the cloth, rearmost first: a wet sheen, a crack once dry."""
    layer = pzart.new_layer(SUPERSAMPLE)
    d = ImageDraw.Draw(layer)
    colours = CAKES[state]
    lx, ly = cloth_art.lot_spot(lot)
    s = SUPERSAMPLE
    for x, y in sorted([(lx + dx, ly + dy) for dx, dy in CAKE_SPOTS], key=lambda p: p[0] + p[1]):
        cx, cy = (v * s for v in pzart.project(x, y, 1.5))
        rx, ry = 3.4 * s, 1.8 * s
        d.ellipse([cx - rx, cy - ry + 1.2 * s, cx + rx, cy + ry + 1.2 * s], fill=colours["side"] + (255,))
        d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=colours["top"] + (255,))
        if state == "wet":
            d.ellipse([cx - rx * 0.5, cy - ry * 0.6, cx - rx * 0.1, cy - ry * 0.2], fill=colours["mark"] + (200,))
        else:
            d.line([cx - rx * 0.5, cy - ry * 0.2, cx + rx * 0.3, cy + ry * 0.3], fill=colours["mark"] + (255,), width=s // 2)
    return pzart.shrink(layer)


def lua_tiles():
    prefix = TILESET + "_"
    return {
        "PREFIX": prefix,
        "SHEETS": [{"prefix": prefix, "tiles": COLUMNS * ROWS}],
        "FACE_COUNT": len(FACES),
        "STATIONS": [prefix + str(index) for index in range(len(FACES))],
        "FIRST_JAR": jar_index(0, 0, 0),
        "JAR_SLOTS": len(JAR_POSITIONS),
        "JAR_LOOKS": {name: look for look, name in enumerate(JAR_LOOK_NAMES)},
        "JAR_KINDS": {name: kind for kind, name in enumerate(JAR_KIND_NAMES)},
        "FIRST_CAKE": FIRST_CAKE,
        "CAKE_STATES": {name: index for index, name in enumerate(CAKE_STATES)},
    }


def main():
    media = Path(__file__).resolve().parent.parent / "42" / "media"
    pzart.write_lua_tiles(media, "TraditionalPreservationYeast", lua_tiles(), "tools/build_shelf_tileset.py")
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)

    tiles = {}
    for index, face in enumerate(FACES):
        tiles[index] = paint_shelf(face)
        for kind in range(len(JAR_KIND_NAMES)):
            for slot in range(len(JAR_POSITIONS)):
                for look in range(len(JAR_LOOK_NAMES)):
                    tiles[jar_index(index, slot, look, kind)] = draw_jar_tile(face, slot, look, kind)
    for state in CAKE_STATES:
        for lot in range(len(cloth_art.LOTS)):
            tiles[cake_index(lot, state)] = draw_cakes(lot, state)
    pzart.write_pack(media / "texturepacks" / f"{NAME}.pack", tiles, NAME, TILESET, PAGE_SIZE)
    pzart.write_tiles(media / f"{NAME}.tiles", [(TILESET, COLUMNS, ROWS)], TILE_PROPS)
    pzart.write_build_icon(tiles[0], media / "textures" / "Item_FermentingShelf.png")
    cakes = draw_cakes(2, "wet")
    pzart.write_build_icon(cakes, media / "textures" / "Item_YeastCakes.png", ICON_SIZE)
    pzart.write_build_icon(draw_cakes(2, "dry"), media / "textures" / "Item_DriedYeastCakes.png", ICON_SIZE)
    for item, look in ICON_ITEMS.items():
        for kind, kind_name in enumerate(JAR_KIND_NAMES):
            draw_icon(look, kind).save(media / "textures" / f"Item_{item}_{kind_name}.png")
    # The mod list shows a full shelf: glass and clay jars, from fresh to done.
    shelf = tiles[0].copy()
    mix = [(0, 0), (1, 1), (2, 0), (3, 2), (4, 1)]
    for slot, (look, kind) in enumerate(mix):
        shelf.alpha_composite(tiles[jar_index(0, slot, look, kind)])
    pzart.write_mod_icon(shelf, media.parent / "icon.png")
    print(f"wrote {NAME}.pack and {NAME}.tiles ({TILE_COUNT} tiles) to {media}")


if __name__ == "__main__":
    main()
