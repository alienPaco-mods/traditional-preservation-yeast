#!/usr/bin/env python3
"""Builds the Fermenting Shelf tileset (42/media/*.tiles and texturepacks/*.pack).

The shelf itself is painted by shelf_art.py. This draws one jar per shelf slot in each
fermentation state, which TraditionalPreservationYeastShelf.lua layers on top, then packs them all.

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

NAME = "traditionalpreservationyeast"
TILESET = NAME + "_01"
COLUMNS, ROWS = 8, 8
PAGE_SIZE = 512
SUPERSAMPLE = 8

FACES = ["S", "E", "W", "N"]

JAR_POSITIONS = [0.16, 0.33, 0.5, 0.67, 0.84]  # one per culture slot
JAR_WIDTH, JAR_HEIGHT = 10.0, 16.0
CULTURE_LEVEL = 0.68

GLASS_EDGE = (120, 120, 112, 130)
GLASS = (205, 222, 226, 80)
# Fresh, halfway, done, named in JAR_STATE_NAMES for the generated Tiles.lua.
JAR_STATE_NAMES = ["fresh", "halfway", "done"]
JAR_STATES = [
    dict(culture=(206, 202, 182, 245), shade=(170, 166, 148, 245), top=(226, 222, 204, 255), bubble=(236, 232, 216, 200)),
    dict(culture=(196, 158, 88, 245), shade=(160, 124, 66, 245), top=(222, 190, 124, 255), bubble=(238, 214, 158, 220)),
    dict(culture=(140, 88, 42, 245), shade=(108, 66, 32, 245), top=(214, 182, 122, 255), bubble=(226, 196, 138, 230)),
]
HIGHLIGHT = (255, 255, 255, 80)
LID = (120, 114, 104, 255)
LID_TOP = (156, 150, 138, 255)
SHADOW = (24, 16, 10, 90)

BUBBLE_SPOTS = [(-0.2, 0.30), (0.18, 0.46), (-0.05, 0.62), (0.24, 0.72)]


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


def jar_index(face_index, slot, state):
    """jarSprite in TraditionalPreservationYeastShelf.lua reads these numbers from the generated Tiles.lua."""
    return len(FACES) + (state * len(JAR_POSITIONS) + slot) * len(FACES) + face_index


TILE_PROPS = {}
for face_index, face in enumerate(FACES):
    TILE_PROPS[face_index] = shelf_props(face)
    for slot in range(len(JAR_POSITIONS)):
        for state in range(len(JAR_STATES)):
            TILE_PROPS[jar_index(face_index, slot, state)] = jar_props(face)


def draw_jar(layer, cx, base_y, colours):
    """Composites one jar onto layer, its base centred on (cx, base_y) in tile pixels."""
    s = SUPERSAMPLE
    jar = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(jar)

    half_w = JAR_WIDTH / 2
    rim = JAR_WIDTH * 0.2  # vertical radius of the jar's ellipses
    top_y = base_y - JAR_HEIGHT
    lid_h = JAR_HEIGHT * 0.17
    shoulder_y = top_y + lid_h

    def ellipse(x, y, rx, ry, fill):
        d.ellipse([(x - rx) * s, (y - ry) * s, (x + rx) * s, (y + ry) * s], fill=fill)

    def rect(x0, y0, x1, y1, fill):
        d.rectangle([x0 * s, y0 * s, x1 * s, y1 * s], fill=fill)

    ellipse(cx + 1.5, base_y + 0.5, half_w + 1, rim + 0.5, SHADOW)

    # Glass edge first, then everything inset by a pixel on top of it.
    ellipse(cx, base_y, half_w, rim, GLASS_EDGE)
    rect(cx - half_w, shoulder_y, cx + half_w, base_y, GLASS_EDGE)
    inner = half_w - 0.8

    ellipse(cx, base_y - 0.3, inner, rim - 0.4, GLASS)
    rect(cx - inner, shoulder_y, cx + inner, base_y - 0.3, GLASS)

    culture_y = base_y - (JAR_HEIGHT - lid_h) * CULTURE_LEVEL
    ellipse(cx, base_y - 0.4, inner, rim - 0.4, colours["culture"])
    rect(cx - inner, culture_y, cx + inner, base_y - 0.4, colours["culture"])
    rect(cx + inner * 0.35, culture_y, cx + inner, base_y - 0.4, colours["shade"])
    ellipse(cx, culture_y, inner, rim - 0.6, colours["top"])

    for dx, height in BUBBLE_SPOTS:
        ellipse(cx + dx * JAR_WIDTH, base_y - JAR_HEIGHT * height * 0.8, 0.6, 0.6, colours["bubble"])

    rect(cx - inner + 0.7, shoulder_y + 1.0, cx - inner + 1.7, base_y - 2.0, HIGHLIGHT)

    lid_rx = half_w - 0.6
    rect(cx - lid_rx, top_y, cx + lid_rx, shoulder_y, LID)
    ellipse(cx, shoulder_y, lid_rx, rim - 0.5, LID)
    ellipse(cx, top_y, lid_rx, rim - 0.5, LID_TOP)

    layer.alpha_composite(jar)


def jar_spots(face):
    """Slot positions on the plank, rearmost first so layers stack correctly."""
    geometry = FACE_GEOMETRY[face]
    x0, y0 = (geometry["a"][i] + geometry["d"][i] / 2 for i in (0, 1))
    x1, y1 = (geometry["b"][i] + geometry["d"][i] / 2 for i in (0, 1))
    spots = [(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t) for t in JAR_POSITIONS]
    return sorted(spots, key=lambda spot: spot[1])


def draw_jar_tile(face, slot, state):
    layer = pzart.new_layer(SUPERSAMPLE)
    cx, base_y = jar_spots(face)[slot]
    draw_jar(layer, cx, base_y, JAR_STATES[state])
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
        "JAR_STATES": {name: state for state, name in enumerate(JAR_STATE_NAMES)},
    }


def main():
    media = Path(__file__).resolve().parent.parent / "42" / "media"
    pzart.write_lua_tiles(media, "TraditionalPreservationYeast", lua_tiles(), "tools/build_shelf_tileset.py")
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)

    tiles = {}
    for index, face in enumerate(FACES):
        tiles[index] = paint_shelf(face)
        for slot in range(len(JAR_POSITIONS)):
            for state in range(len(JAR_STATES)):
                tiles[jar_index(index, slot, state)] = draw_jar_tile(face, slot, state)
    pzart.write_pack(media / "texturepacks" / f"{NAME}.pack", tiles, NAME, TILESET, PAGE_SIZE)
    pzart.write_tiles(media / f"{NAME}.tiles", [(TILESET, COLUMNS, ROWS)], TILE_PROPS)
    pzart.write_build_icon(tiles[0], media / "textures" / "Item_FermentingShelf.png")
    # The mod list shows a full shelf at every stage, from fresh to done.
    shelf = tiles[0].copy()
    for slot in range(len(JAR_POSITIONS)):
        shelf.alpha_composite(tiles[jar_index(0, slot, slot * (len(JAR_STATES) - 1) // (len(JAR_POSITIONS) - 1))])
    pzart.write_mod_icon(shelf, media.parent / "icon.png")
    print(f"wrote {NAME}.pack and {NAME}.tiles to {media}")


if __name__ == "__main__":
    main()
