#!/usr/bin/env python3
"""Procedural pixel-art tileset for the campus map.

Run from the repo root:  python3 tools/gen_tiles.py

Writes assets/tiles/placeholder_tileset.png (a 16x16-tile strip). Tile ids
0-19 keep the exact meaning they had before (grass, path, tree, water, then
roof/wall/window/door for four buildings) so degree_campus.tmx and the
collision properties in placeholder_tileset.tsx keep working. Ids 20+ are
new decoration tiles (see DECOR below / the .tsx).

Textures use a deterministic hash for dithering so every run is identical.
"""
from PIL import Image

T = 16


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def hsh(x, y, salt=0):
    n = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    n = (n ^ (n >> 13)) * 1274126177
    return (n ^ (n >> 16)) & 0xFFFF


class Tile:
    def __init__(self, base=None):
        self.im = Image.new('RGBA', (T, T), base or (0, 0, 0, 0))

    def p(self, x, y, c):
        if 0 <= x < T and 0 <= y < T:
            self.im.putpixel((x, y), c)

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.p(x, y, c)

    def get(self, x, y):
        return self.im.getpixel((x, y))


# ------------------------------------------------------------------ palette
G1, G2, G3, G4 = rgb('#6cb84a'), rgb('#5fa842'), rgb('#4f9438'), rgb('#86cc5c')
D1, D2, D3, D4 = rgb('#d9bd8a'), rgb('#cdae78'), rgb('#bd9a66'), rgb('#e8d2a2')
OUT = rgb('#2b2233')


def grass(variant=0):
    t = Tile(G1)
    for y in range(T):
        for x in range(T):
            h = hsh(x, y, 1 + variant)
            if h % 11 == 0:
                t.p(x, y, G2)
            elif h % 17 == 0:
                t.p(x, y, G4)
    # a few tufts, tile-safe (kept off the very edge columns)
    spots = [(3, 4), (11, 9), (7, 13)] if variant == 0 else [(5, 3), (12, 12), (2, 10), (9, 7)]
    for x, y in spots:
        t.p(x, y, G3)
        t.p(x, y - 1, G4)
        t.p(x + 1, y, G3)
    return t


def path():
    t = Tile(D1)
    for y in range(T):
        for x in range(T):
            h = hsh(x, y, 5)
            if h % 9 == 0:
                t.p(x, y, D2)
            elif h % 23 == 0:
                t.p(x, y, D4)
    for x, y in [(4, 5), (12, 3), (9, 11), (2, 13), (14, 8)]:
        t.p(x, y, D3)
        t.p(x + 1, y, D2)
    return t


def tree():
    t = grass(0)
    # trunk
    t.rect(7, 11, 8, 14, rgb('#6b4a2c'))
    t.p(8, 12, rgb('#54381f'))
    t.p(8, 13, rgb('#54381f'))
    t.rect(6, 14, 9, 14, rgb('#54381f'))
    # canopy: stacked blobs with highlight
    canopy = [(2, 5, 10), (3, 3, 12), (4, 2, 13), (5, 2, 13), (6, 2, 13), (7, 3, 12), (8, 3, 12), (9, 4, 11), (10, 5, 10)]  # (y, x0, x1)
    for y, a, b in canopy:
        for x in range(a, b + 1):
            t.p(x, y, rgb('#2f7a3a'))
    for y, a, b in canopy:
        for x in range(a, b + 1):
            h = hsh(x, y, 9)
            if x <= a + 2 and y <= 6:
                t.p(x, y, rgb('#4faa4a'))
            if h % 5 == 0:
                t.p(x, y, rgb('#3d9444'))
            if x >= b - 1 and y >= 5:
                t.p(x, y, rgb('#25602f'))
    for y, a, b in canopy:
        for x in range(a, b + 1):
            if y in (9, 10) and (x == a or x == b or True):
                if y == 10 or x == a or x == b:
                    pass
    # outline
    px = t.im
    mask = {(x, y) for y, a, b in canopy for x in range(a, b + 1)}
    for (x, y) in list(mask):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in mask and 0 <= q[0] < T and 0 <= q[1] < T and not (6 <= q[0] <= 9 and q[1] >= 11):
                px.putpixel(q, rgb('#1d4a28'))
    # leaf clusters
    for x, y in [(6, 4), (9, 6), (5, 7), (11, 4)]:
        t.p(x, y, rgb('#5cbc54'))
    return t


def water(phase=0):
    base, hi, lo = rgb('#4a8ad8'), rgb('#8cc4f0'), rgb('#3a6ab8')
    t = Tile(base)
    for y in range(T):
        for x in range(T):
            if hsh(x, y, 3) % 13 == 0:
                t.p(x, y, lo)
    for (x, y, w) in [(2, 3, 4), (9, 7, 4), (4, 11, 5), (11, 1, 3), (1, 8, 3)]:
        for i in range(w):
            t.p(x + i, y, hi)
        t.p(x - 1, y, base)
    return t


# ------------------------------------------------------------- buildings
class BPal:
    def __init__(self, roof, wall, trim, glass):
        self.roof = rgb(roof)
        self.roof_d = tuple(int(c * 0.78) for c in rgb(roof)[:3]) + (255,)
        self.roof_l = tuple(min(255, int(c + (255 - c) * 0.3)) for c in rgb(roof)[:3]) + (255,)
        self.wall = rgb(wall)
        self.wall_d = tuple(int(c * 0.84) for c in rgb(wall)[:3]) + (255,)
        self.wall_l = tuple(min(255, int(c + (255 - c) * 0.35)) for c in rgb(wall)[:3]) + (255,)
        self.trim = rgb(trim)
        self.glass = rgb(glass)
        self.glass_l = tuple(min(255, int(c + (255 - c) * 0.55)) for c in rgb(glass)[:3]) + (255,)
        self.glass_d = tuple(int(c * 0.7) for c in rgb(glass)[:3]) + (255,)


def roof_tile(b):
    t = Tile(b.roof)
    # shingle rows: offset brick pattern, tileable horizontally (period 8)
    for y in range(T):
        row = y // 4
        for x in range(T):
            off = 4 if row % 2 else 0
            if y % 4 == 3:
                t.p(x, y, b.roof_d)
            elif (x + off) % 8 == 7:
                t.p(x, y, b.roof_d)
            elif y % 4 == 0:
                t.p(x, y, b.roof_l)
    # drop shadow at the bottom edge and a bright ridge on top
    for x in range(T):
        t.p(x, 15, OUT)
        t.p(x, 14, b.roof_d)
        t.p(x, 0, b.roof_l)
    return t


def wall_tile(b):
    t = Tile(b.wall)
    for y in range(T):
        for x in range(T):
            h = hsh(x, y, 11)
            if h % 19 == 0:
                t.p(x, y, b.wall_d)
    # plaster band + baseboard
    for x in range(T):
        t.p(x, 0, b.wall_l)
        t.p(x, 15, b.wall_d)
        t.p(x, 14, b.wall_d)
    return t


def window_tile(b):
    t = wall_tile(b)
    # frame
    t.rect(3, 2, 12, 12, b.trim)
    t.rect(4, 3, 11, 11, b.glass)
    # glass gradient + reflection
    for y in range(3, 12):
        for x in range(4, 12):
            if y >= 8:
                t.p(x, y, b.glass_d)
    for i in range(4):
        t.p(5 + i, 7 - i, b.glass_l)
    t.p(6, 4, b.glass_l)
    t.p(5, 5, b.glass_l)
    # cross bars
    t.rect(7, 3, 8, 11, b.trim)
    t.rect(4, 7, 11, 7, b.trim)
    # sill
    t.rect(2, 13, 13, 13, b.wall_l)
    t.rect(2, 14, 13, 14, b.wall_d)
    return t


def door_tile(b):
    t = wall_tile(b)
    door = rgb('#6b4a2c')
    dd = rgb('#4a3220')
    dl = rgb('#8a6440')
    t.rect(3, 1, 12, 15, b.trim)
    t.rect(4, 2, 11, 15, door)
    for y in range(2, 16):
        t.p(7, y, dd)
        t.p(8, y, dd)
        t.p(4, y, dl)
    t.rect(5, 3, 6, 7, dl)
    t.rect(9, 3, 10, 7, dl)
    t.rect(5, 9, 6, 13, dl)
    t.rect(9, 9, 10, 13, dl)
    t.p(6, 10, dd)
    t.p(9, 10, dd)
    # knob + doorstep
    t.p(10, 9, rgb('#f0c84a'))
    t.p(10, 10, rgb('#b8902a'))
    t.rect(2, 15, 13, 15, rgb('#bdb8b0'))
    return t


BUILDINGS = [
    BPal('#3f5fa8', '#d8d2c4', '#f4f1e8', '#8cc4e8'),  # lecture hall / library
    BPal('#c8682f', '#e8d6b0', '#fff4dc', '#9ad0e0'),  # hostel
    BPal('#c43c3c', '#f0dcc0', '#fff2d8', '#a8d8e8'),  # cafeteria
    BPal('#7a4aa8', '#d6cce0', '#f4eefa', '#a8c8f0'),  # club room
]


# --------------------------------------------------------------- decoration
def flowers(c1, c2):
    t = grass(1)
    for (x, y) in [(3, 3), (10, 5), (6, 10), (13, 12), (2, 13)]:
        t.p(x, y, c1)
        t.p(x - 1, y, c1)
        t.p(x + 1, y, c1)
        t.p(x, y - 1, c1)
        t.p(x, y + 1, c1)
        t.p(x, y, c2)
    for (x, y) in [(3, 4), (10, 6), (6, 11)]:
        t.p(x, y + 1, G3)
    return t


def bush():
    t = grass(0)
    body, lt, dk = rgb('#3d9444'), rgb('#5cbc54'), rgb('#25602f')
    mask = []
    for y, a, b in [(5, 5, 10), (6, 3, 12), (7, 2, 13), (8, 2, 13), (9, 2, 13), (10, 3, 12), (11, 4, 11), (12, 5, 10)]:
        for x in range(a, b + 1):
            mask.append((x, y))
            t.p(x, y, body)
            if y <= 7 and x < a + 4:
                t.p(x, y, lt)
            if y >= 10 or x >= b - 1:
                t.p(x, y, dk)
    for (x, y) in [(5, 8), (9, 7), (11, 9), (7, 10)]:
        t.p(x, y, lt)
    s = set(mask)
    for (x, y) in mask:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in s:
                t.p(x + dx, y + dy, rgb('#1d4a28'))
    # berries
    for (x, y) in [(6, 7), (10, 9), (8, 11)]:
        t.p(x, y, rgb('#e8506a'))
    return t


def bench():
    t = grass(1)
    wood, wl, wd = rgb('#a8703c'), rgb('#c8905a'), rgb('#6b4426')
    # shadow
    for x in range(2, 14):
        t.p(x, 13, G3)
    # backrest
    t.rect(2, 4, 13, 4, wd)
    t.rect(2, 5, 13, 6, wood)
    t.rect(2, 5, 13, 5, wl)
    t.rect(2, 7, 13, 7, wd)
    # seat
    t.rect(1, 8, 14, 10, wood)
    t.rect(1, 8, 14, 8, wl)
    t.rect(1, 10, 14, 10, wd)
    # legs
    t.rect(2, 11, 3, 13, rgb('#3a3a46'))
    t.rect(12, 11, 13, 13, rgb('#3a3a46'))
    t.rect(2, 4, 2, 10, wd)
    t.rect(13, 4, 13, 10, wd)
    return t


def lamp():
    t = grass(0)
    # base
    t.rect(5, 14, 10, 14, rgb('#8e8a84'))
    t.rect(6, 13, 9, 13, rgb('#4a4a58'))
    t.rect(7, 5, 8, 12, rgb('#3a3a48'))
    t.p(7, 5, rgb('#5a5a6a'))
    # lantern
    t.rect(5, 1, 10, 4, rgb('#3a3a48'))
    t.rect(6, 2, 9, 3, rgb('#ffe8a0'))
    t.rect(7, 2, 8, 2, rgb('#fffbe0'))
    t.rect(4, 0, 11, 0, rgb('#3a3a48'))
    # glow
    for (x, y) in [(3, 2), (12, 2), (4, 4), (11, 4)]:
        t.p(x, y, rgb('#f5e6a8'))
    return t


def sign():
    t = grass(0)
    post, pl, pd = rgb('#8a5a30'), rgb('#a87440'), rgb('#5a3a1e')
    t.rect(7, 8, 8, 14, post)
    t.rect(7, 8, 7, 14, pl)
    t.rect(8, 8, 8, 14, pd)
    # board
    t.rect(2, 2, 13, 8, rgb('#d9b87a'))
    t.rect(2, 2, 13, 2, rgb('#f0d49a'))
    t.rect(2, 8, 13, 8, pd)
    t.rect(2, 2, 2, 8, pd)
    t.rect(13, 2, 13, 8, pd)
    # "writing" lines
    for y, a, b in [(4, 4, 11), (6, 4, 9)]:
        for x in range(a, b + 1):
            t.p(x, y, rgb('#5a3a1e'))
    t.p(11, 6, rgb('#d9b87a'))
    return t


def stone_path():
    """Cobblestone variant for plaza accents."""
    t = Tile(rgb('#b8b4ac'))
    for y in range(T):
        for x in range(T):
            if y % 5 == 4 or (x + (y // 5) * 3) % 6 == 5:
                t.p(x, y, rgb('#8e8a84'))
            elif hsh(x, y, 4) % 11 == 0:
                t.p(x, y, rgb('#d0ccc4'))
    return t


# ---------------------------------------------------------------- interiors
WOOD, WOOD_D, WOOD_L = rgb('#c8935a'), rgb('#a87444'), rgb('#dcac76')


def wood_floor():
    t = Tile(WOOD)
    for y in range(T):
        for x in range(T):
            if y % 4 == 3:
                t.p(x, y, WOOD_D)
            elif (x + (y // 4) * 5) % 16 == 0:
                t.p(x, y, WOOD_D)
            elif hsh(x, y, 21) % 13 == 0:
                t.p(x, y, WOOD_L)
    return t


def inner_wall():
    t = Tile(rgb('#e8dcc4'))
    for y in range(T):
        for x in range(T):
            if y >= 11:
                t.p(x, y, rgb('#8a6a4a'))      # wainscot
            elif hsh(x, y, 22) % 17 == 0:
                t.p(x, y, rgb('#d8ccb2'))
    for x in range(T):
        t.p(x, 11, rgb('#b08a60'))
        t.p(x, 15, rgb('#6b4a2c'))
        t.p(x, 0, rgb('#f4ecd8'))
    return t


def door_mat():
    t = wood_floor()
    t.rect(2, 3, 13, 12, rgb('#b8453f'))
    t.rect(3, 4, 12, 11, rgb('#d8645a'))
    for x in range(3, 13, 2):
        t.p(x, 7, rgb('#f0d890'))
        t.p(x, 8, rgb('#f0d890'))
    return t


def bookshelf():
    t = inner_wall()
    t.rect(0, 0, 15, 15, rgb('#6b4426'))
    t.rect(1, 1, 14, 14, rgb('#4a2f1a'))
    cols = [rgb('#c8453f'), rgb('#3f6fb0'), rgb('#e8b84a'), rgb('#4f9a5a'), rgb('#8a4fb0'), rgb('#e8e0cc')]
    for shelf_y in (1, 6, 11):
        for x in range(1, 14):
            h = 3 + hsh(x, shelf_y, 23) % 2
            c = cols[hsh(x, shelf_y, 24) % len(cols)]
            for y in range(shelf_y + 4 - h, shelf_y + 4):
                t.p(x, y, c)
            t.p(x, shelf_y + 4 - h, tuple(min(255, v + 40) for v in c[:3]) + (255,))
        t.rect(1, shelf_y + 4, 14, shelf_y + 4, rgb('#6b4426'))
    return t


def table():
    t = wood_floor()
    top, tl, td = rgb('#a8703c'), rgb('#c8905a'), rgb('#6b4426')
    t.rect(1, 3, 14, 11, top)
    t.rect(1, 3, 14, 3, tl)
    t.rect(1, 11, 14, 12, td)
    t.rect(2, 13, 3, 14, td)
    t.rect(12, 13, 13, 14, td)
    # a book and a mug
    t.rect(3, 5, 7, 8, rgb('#3f6fb0'))
    t.rect(3, 5, 7, 5, rgb('#8cb4e8'))
    t.rect(10, 6, 12, 8, rgb('#f4efe4'))
    t.p(13, 7, rgb('#f4efe4'))
    return t


def bed():
    t = wood_floor()
    t.rect(2, 1, 13, 14, rgb('#6b4426'))
    t.rect(3, 2, 12, 13, rgb('#f4efe4'))
    t.rect(4, 3, 11, 6, rgb('#fff8ec'))
    t.rect(3, 7, 12, 13, rgb('#4f7ab8'))
    t.rect(3, 7, 12, 8, rgb('#7aa4d8'))
    for x in range(3, 13):
        t.p(x, 13, rgb('#34588a'))
    return t


def counter():
    t = wood_floor()
    t.rect(0, 2, 15, 13, rgb('#8a5a30'))
    t.rect(0, 2, 15, 5, rgb('#e8dcc4'))
    t.rect(0, 2, 15, 2, rgb('#fff8ec'))
    t.rect(0, 6, 15, 6, rgb('#5a3a1e'))
    for x in range(2, 15, 4):
        t.rect(x, 8, x + 2, 12, rgb('#a8703c'))
    t.rect(4, 0, 6, 2, rgb('#e8b84a'))   # something on the counter
    t.rect(10, 1, 11, 2, rgb('#c8453f'))
    return t


def plant():
    t = wood_floor()
    t.rect(4, 10, 11, 14, rgb('#b8603a'))
    t.rect(4, 10, 11, 10, rgb('#d8805a'))
    t.rect(5, 14, 10, 14, rgb('#8a4a2a'))
    for (x, y, w) in [(7, 1, 2), (5, 2, 6), (4, 4, 8), (3, 6, 10), (5, 8, 6)]:
        t.rect(x, y, x + w - 1, y, rgb('#3d9444'))
        t.rect(x, y + 1, x + w - 1, y + 1, rgb('#4faa4a'))
    t.rect(7, 9, 8, 9, rgb('#25602f'))
    return t


def chalkboard():
    t = inner_wall()
    t.rect(0, 1, 15, 11, rgb('#6b4426'))
    t.rect(1, 2, 14, 10, rgb('#2f4a3a'))
    for (x, y, w) in [(3, 4, 7), (3, 6, 5), (3, 8, 8)]:
        t.rect(x, y, x + w - 1, y, rgb('#e8e8dc'))
    t.rect(1, 11, 14, 11, rgb('#a87440'))
    t.rect(9, 11, 11, 11, rgb('#f4efe4'))
    return t


def rug():
    t = wood_floor()
    t.rect(0, 2, 15, 13, rgb('#3f6fb0'))
    t.rect(1, 3, 14, 12, rgb('#5a8ad0'))
    t.rect(3, 5, 12, 10, rgb('#e8d8a0'))
    t.rect(4, 6, 11, 9, rgb('#5a8ad0'))
    return t


def void():
    return Tile(rgb('#1c1626'))


def build():
    tiles = [
        grass(0),            # 0
        path(),              # 1
        tree(),              # 2
        water(),             # 3
    ]
    for b in BUILDINGS:       # 4..19
        tiles += [roof_tile(b), wall_tile(b), window_tile(b), door_tile(b)]
    tiles += [
        grass(1),                                 # 20 tufted grass
        flowers(rgb('#f2b8d0'), rgb('#fff2a8')),  # 21 pink flowers
        flowers(rgb('#f6d84a'), rgb('#fff6d0')),  # 22 yellow flowers
        bush(),                                   # 23 bush (blocking)
        bench(),                                  # 24 bench (blocking)
        lamp(),                                   # 25 lamp post (blocking)
        sign(),                                   # 26 signboard (blocking)
        stone_path(),                             # 27 cobblestone (walkable)
        wood_floor(),                             # 28 interior floor (walkable)
        inner_wall(),                             # 29 interior wall (blocking)
        door_mat(),                               # 30 exit mat (walkable, exit)
        bookshelf(),                              # 31 bookshelf (blocking)
        table(),                                  # 32 table (blocking)
        bed(),                                    # 33 bed (blocking)
        counter(),                                # 34 counter (blocking)
        plant(),                                  # 35 plant (blocking)
        chalkboard(),                             # 36 chalkboard (blocking)
        rug(),                                    # 37 rug (walkable)
        void(),                                   # 38 outside the room (blocking)
    ]
    sheet = Image.new('RGBA', (T * len(tiles), T), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.paste(t.im, (i * T, 0))
    return sheet, len(tiles)


if __name__ == '__main__':
    sheet, n = build()
    sheet.save('assets/tiles/placeholder_tileset.png')
    print('wrote tileset with', n, 'tiles')
