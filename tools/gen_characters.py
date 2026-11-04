#!/usr/bin/env python3
"""Procedural pixel-art generator for the player and NPC sprite sheets.

Run from the repo root:  python3 tools/gen_characters.py

Output (same layout the game code already expects):
  assets/sprites/player_spritesheet.png  96x96   (4 frames x 4 rows, 24px cells)
  assets/sprites/npc_spritesheet.png    264x96   (11 characters x 4 rows)
Rows are facing directions: 0 down, 1 up, 2 left, 3 right.
Player columns are the 4 walk frames (0 doubles as the idle pose).
NPC columns follow NpcComponent._columnForNpcId.

Each character is drawn from simple shapes (head, hair, torso, arms, legs),
shaded with a 3-tone ramp per material, then given a 1px dark outline and a
soft ground shadow - the classic GBA-RPG chibi look.
"""
from PIL import Image

CELL = 24
OUTLINE = (38, 28, 46, 255)


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, f):
    """f<1 darkens (with a cool shift), f>1 lightens (with a warm shift)."""
    r, g, b = c
    if f < 1:
        return (int(r * f * 0.96), int(g * f * 0.98), int(min(255, b * f * 1.06)))
    k = f - 1
    return (int(r + (255 - r) * k), int(g + (255 - g) * k * 0.95), int(b + (255 - b) * k * 0.85))


class Ramp:
    def __init__(self, base):
        base = rgb(base) if isinstance(base, str) else base
        self.base = base
        self.dark = shade(base, 0.72)
        self.darker = shade(base, 0.52)
        self.light = shade(base, 1.28)


class Canvas:
    def __init__(self):
        self.px = {}

    def set(self, x, y, c):
        if 0 <= x < CELL and 0 <= y < CELL:
            self.px[(x, y)] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, c)

    def row(self, y, x0, x1, c):
        for x in range(x0, x1 + 1):
            self.set(x, y, c)

    def get(self, x, y):
        return self.px.get((x, y))

    def finish(self):
        """Outline pass + ground shadow, returns an RGBA image."""
        img = Image.new('RGBA', (CELL, CELL), (0, 0, 0, 0))
        out = {}
        for (x, y), c in self.px.items():
            out[(x, y)] = c + (255,)
        for (x, y) in list(self.px):
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                p = (x + dx, y + dy)
                if p not in self.px and 0 <= p[0] < CELL and 0 <= p[1] < CELL:
                    out[p] = OUTLINE
        # soft ellipse shadow under the feet (never over the sprite)
        for x in range(6, 18):
            for y in (22, 23):
                if (x, y) not in out:
                    edge = x in (6, 17) or y == 23 and x in (7, 16)
                    out[(x, y)] = (20, 14, 30, 38 if edge else 78)
        for p, c in out.items():
            img.putpixel(p, c)
        return img


# Head silhouettes: half-widths per row, y=3..13 for a 12px-wide head.
HEAD_HALF = [4, 5, 6, 6, 6, 6, 6, 6, 5, 4, 3]
HEAD_TOP = 3


def draw_head_front(cv, st, by):
    skin, sd = st['skin'].base, st['skin'].dark
    for i, h in enumerate(HEAD_HALF):
        y = HEAD_TOP + i + by
        cv.row(y, 12 - h, 11 + h, skin)
    # soft shading on the right cheek / jaw
    for i, h in enumerate(HEAD_HALF):
        if i >= 6:
            cv.set(11 + h, HEAD_TOP + i + by, sd)
    cv.row(HEAD_TOP + 10 + by, 10, 13, sd)
    # neck
    cv.rect(10, 14 + by, 13, 14 + by, sd)


def draw_face_front(cv, st, by):
    eye = rgb('#2a1c24')
    y = 9 + by
    for x in (8, 14):
        cv.rect(x, y, x + 1, y + 1, eye)
        cv.set(x, y, (255, 255, 255))
    cv.set(7, 11 + by, st['blush'])
    cv.set(16, 11 + by, st['blush'])
    cv.row(12 + by, 11, 12, rgb('#a8504c'))
    if st.get('glasses'):
        g = rgb('#3a3550')
        cv.rect(7, 8 + by, 10, 8 + by, g)
        cv.rect(13, 8 + by, 16, 8 + by, g)
        cv.rect(7, 11 + by, 10, 11 + by, g)
        cv.rect(13, 11 + by, 16, 11 + by, g)
        cv.set(7, 9 + by, g)
        cv.set(7, 10 + by, g)
        cv.set(10, 9 + by, g)
        cv.set(10, 10 + by, g)
        cv.set(13, 9 + by, g)
        cv.set(13, 10 + by, g)
        cv.set(16, 9 + by, g)
        cv.set(16, 10 + by, g)
        cv.row(9 + by, 11, 12, g)


def hair_front(cv, st, by):
    h = st['hair']
    style = st['style']
    base, hi, dk = h.base, h.light, h.dark
    if style == 'hijab':
        return hijab_front(cv, st, by)
    # top cap of hair
    for i, hw in enumerate([4, 5, 6, 6]):
        y = 3 + i + by
        cv.row(y, 12 - hw, 11 + hw, base)
    cv.row(2 + by, 8, 15, base)
    cv.row(3 + by, 9, 14, hi)
    cv.row(4 + by, 8, 10, hi)
    # side locks
    cv.rect(6, 7 + by, 6, 8 + by, base)
    cv.rect(17, 7 + by, 17, 8 + by, base)
    cv.set(17, 8 + by, dk)
    # fringe
    for x in range(7, 17):
        cv.set(x, 7 + by, base)
    for x in (9, 10, 13):
        cv.set(x, 8 + by, base)
    cv.set(14, 7 + by, dk)
    cv.set(12, 7 + by, dk)
    if style == 'spiky':
        for x, yy in ((7, 2), (10, 1), (13, 1), (16, 2)):
            cv.set(x, yy + by, base)
        cv.set(10, 2 + by, base)
        cv.set(13, 2 + by, base)
    if style == 'bun':
        cv.rect(10, 0 + by, 13, 1 + by, base)
        cv.set(10, 0 + by, dk)
        cv.set(11, 0 + by, hi)
        cv.row(1 + by, 9, 14, base) if False else None
    if style == 'long':
        # strands that frame the face and fall over the shoulders
        cv.rect(5, 7 + by, 6, 15 + by, base)
        cv.rect(17, 7 + by, 18, 15 + by, base)
        cv.rect(5, 12 + by, 5, 15 + by, dk)
        cv.rect(18, 12 + by, 18, 15 + by, dk)
    if style == 'cap':
        c = st['cap']
        cv.row(2 + by, 7, 16, c.base)
        cv.row(3 + by, 6, 17, c.base)
        cv.row(4 + by, 6, 17, c.base)
        cv.row(5 + by, 6, 17, c.light)
        cv.row(6 + by, 5, 18, c.dark)
        cv.row(7 + by, 6, 17, c.darker)
        cv.set(11, 3 + by, c.light)
        cv.set(12, 3 + by, c.light)


def hijab_front(cv, st, by):
    c = st['hair']  # hijab colour is stored in 'hair'
    base, hi, dk = c.base, c.light, c.dark
    # scarf frames the face: wider than the head, drapes over shoulders
    for i, hw in enumerate([5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]):
        y = 2 + i + by
        cv.row(y, 12 - hw, 11 + hw, base)
    # face opening (skin oval)
    face_rows = {6: (8, 15), 7: (7, 16), 8: (7, 16), 9: (7, 16), 10: (7, 16), 11: (8, 15), 12: (9, 14), 13: (10, 13)}
    for yy, (a, b) in face_rows.items():
        cv.row(yy + by, a, b, st['skin'].base)
    cv.row(13 + by, 10, 13, st['skin'].dark)
    # drape over the chest
    cv.rect(6, 14 + by, 17, 16 + by, base)
    cv.rect(7, 17 + by, 16, 17 + by, dk)
    # fabric highlights/folds
    cv.row(3 + by, 9, 12, hi)
    cv.rect(7, 4 + by, 7, 5 + by, hi)
    cv.rect(16, 7 + by, 16, 13 + by, dk) if False else None
    for yy in range(7, 16):
        cv.set(18, yy + by, dk)
    cv.rect(11, 14 + by, 12, 16 + by, dk)


def draw_torso_front(cv, st, by, arm_l, arm_r):
    top = st['top']
    # arms (behind torso edge), sleeves + hands
    sleeve = st.get('sleeve', top)
    for side, off in ((6, arm_l), (16, arm_r)):
        y0 = 14 + by + off
        cv.rect(side, y0, side + 1, y0 + 3, sleeve.base)
        cv.set(side + 1 if side == 16 else side, y0 + 1, sleeve.dark)
        cv.rect(side, y0 + 4, side + 1, y0 + 5, st['skin'].base)
        cv.set(side + (1 if side == 16 else 0), y0 + 5, st['skin'].dark)
    # torso
    cv.rect(8, 14 + by, 15, 19 + by, top.base)
    cv.rect(15, 14 + by, 15, 19 + by, top.dark)
    cv.row(19 + by, 8, 15, top.dark)
    cv.row(14 + by, 8, 15, top.light)
    cv.row(15 + by, 8, 9, top.light)
    under = st.get('under')
    if under:
        cv.rect(10, 14 + by, 13, 15 + by, under)
        cv.rect(11, 16 + by, 12, 16 + by, under)
        cv.row(14 + by, 10, 13, shade(under, 0.8))
    if st.get('apron'):
        a = st['apron']
        cv.rect(9, 15 + by, 14, 19 + by, a.base)
        cv.rect(14, 15 + by, 14, 19 + by, a.dark)
        cv.row(15 + by, 9, 14, a.light)
        cv.set(11, 17 + by, a.dark)
        cv.set(12, 17 + by, a.dark)
    if st.get('belt'):
        cv.row(18 + by, 8, 15, st['belt'])
    if st.get('lanyard'):
        cv.rect(11, 14 + by, 11, 17 + by, st['lanyard'])
        cv.rect(12, 14 + by, 12, 17 + by, st['lanyard'])
        cv.rect(11, 18 + by, 12, 18 + by, rgb('#f2efe6'))


def draw_legs_front(cv, st, by, lift):
    """lift: -1 raise left leg, +1 raise right leg, 0 neutral."""
    pants, shoe = st['bottom'], st['shoes']
    for x0, raised in ((8, lift == -1), (13, lift == 1)):
        bottom = 21 if raised else 22
        top = 20 + by
        if raised:
            top = min(top, bottom - 1)
        cv.rect(x0, top, x0 + 2, bottom - 1, pants.base)
        cv.rect(x0 + 2, top, x0 + 2, bottom - 1, pants.dark)
        cv.rect(x0, bottom - 1, x0 + 2, bottom - 1, shoe.base) if False else None
        cv.rect(x0 - (0 if x0 > 8 else 0), bottom, x0 + 2, bottom, shoe.base)
        cv.set(x0 + 2, bottom, shoe.dark)
        cv.set(x0, bottom, shoe.light)
    if st.get('skirt'):
        sk = st['skirt']
        cv.rect(8, 19 + by, 15, 21 + by, sk.base)
        cv.row(21 + by, 8, 15, sk.dark)
        cv.rect(15, 19 + by, 15, 21 + by, sk.dark)
        cv.row(19 + by, 8, 15, sk.light)
        # fabric fold lines
        for x in (10, 13):
            cv.rect(x, 20 + by, x, 21 + by, sk.dark)


# ---------------------------------------------------------------- back view
def draw_back(cv, st, by, arm_l, arm_r, lift):
    skin = st['skin']
    hair = st['hair']
    style = st['style']
    # head
    for i, h in enumerate(HEAD_HALF):
        y = HEAD_TOP + i + by
        cv.row(y, 12 - h, 11 + h, skin.base)
    cv.rect(10, 14 + by, 13, 14 + by, skin.dark)
    # arms/torso reuse front shape
    draw_torso_front(cv, {**st, 'under': None, 'lanyard': None, 'apron': None}, by, arm_l, arm_r)
    if st.get('apron'):
        a = st['apron']
        cv.row(16 + by, 8, 15, a.base)  # apron strap
    draw_legs_front(cv, st, by, lift)
    # hair covers the whole back of the head
    base, hi, dk = hair.base, hair.light, hair.dark
    if style == 'hijab':
        for i, hw in enumerate([5, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7]):
            cv.row(2 + i + by, 12 - hw, 11 + hw, base)
        cv.rect(6, 14 + by, 17, 18 + by, base)
        cv.rect(7, 19 + by, 16, 19 + by, dk)
        cv.row(3 + by, 9, 12, hi)
        cv.rect(11, 8 + by, 12, 18 + by, dk)
        for yy in range(5, 19):
            cv.set(18, yy + by, dk)
        return
    for i, hw in enumerate([4, 5, 6, 6, 6, 6, 6, 6, 5, 4]):
        cv.row(3 + i + by, 12 - hw, 11 + hw, base)
    cv.row(2 + by, 8, 15, base)
    cv.row(3 + by, 9, 14, hi)
    cv.row(4 + by, 8, 10, hi)
    for i in range(4, 10):
        cv.set(11 + HEAD_HALF[i - 0] if i - 0 < len(HEAD_HALF) else 17, 3 + i + by, dk)
    cv.row(12 + by, 9, 14, dk)
    if style == 'spiky':
        for x, yy in ((7, 2), (10, 1), (13, 1), (16, 2)):
            cv.set(x, yy + by, base)
    if style == 'bun':
        cv.rect(10, 0 + by, 13, 1 + by, base)
        cv.set(11, 0 + by, hi)
    if style == 'long':
        cv.rect(5, 7 + by, 18, 17 + by, base)
        cv.rect(5, 15 + by, 18, 17 + by, dk)
        cv.rect(8, 8 + by, 9, 14 + by, hi) if False else None
        cv.row(9 + by, 8, 9, hi)
    if style == 'cap':
        c = st['cap']
        cv.row(2 + by, 7, 16, c.base)
        cv.row(3 + by, 6, 17, c.base)
        cv.row(4 + by, 6, 17, c.base)
        cv.row(5 + by, 6, 17, c.light)
        cv.row(6 + by, 6, 17, c.dark)
        cv.set(11, 4 + by, c.light)
        cv.set(12, 4 + by, c.light)


# ---------------------------------------------------------------- side view
def draw_side(cv, st, by, phase):
    """Facing left. phase: 'stand', 'passA', 'A' (near leg forward), 'B'."""
    skin = st['skin']
    hair = st['hair']
    style = st['style']
    top, pants, shoe = st['top'], st['bottom'], st['shoes']
    sleeve = st.get('sleeve', top)

    # far leg + near leg
    legs = {
        'stand': (11, 10, 0),
        'passA': (11, 10, 1),
        'passB': (11, 10, 1),
        'A': (8, 13, 0),
        'B': (13, 8, 0),
    }
    near_x, far_x, _ = legs[phase]
    raise_far = phase in ('stand',)
    for x0, dark, bottom in ((far_x, True, 22), (near_x, False, 22)):
        r = pants.dark if dark else pants.base
        s = shoe.dark if dark else shoe.base
        top_y = 20 + by
        cv.rect(x0, top_y, x0 + 2, bottom - 1, r)
        cv.rect(x0 + 2, top_y, x0 + 2, bottom - 1, pants.darker if dark else pants.dark)
        cv.rect(x0 - 1, bottom, x0 + 2, bottom, s)
        cv.set(x0 - 1, bottom, shoe.light if not dark else shoe.base)
    if st.get('skirt'):
        sk = st['skirt']
        cv.rect(8, 19 + by, 15, 21 + by, sk.base)
        cv.row(21 + by, 8, 15, sk.dark)
        cv.row(19 + by, 8, 15, sk.light)
        cv.rect(15, 19 + by, 15, 21 + by, sk.dark)
        cv.rect(11, 20 + by, 11, 21 + by, sk.dark)
    # far arm (behind torso)
    far_arm_x = {'stand': 11, 'passA': 11, 'passB': 11, 'A': 13, 'B': 8}[phase]
    cv.rect(far_arm_x, 14 + by, far_arm_x + 1, 17 + by, sleeve.dark)
    cv.rect(far_arm_x, 18 + by, far_arm_x + 1, 18 + by, skin.dark)
    # torso
    cv.rect(9, 14 + by, 14, 19 + by, top.base)
    cv.rect(14, 14 + by, 14, 19 + by, top.dark)
    cv.row(19 + by, 9, 14, top.dark)
    cv.row(14 + by, 9, 14, top.light)
    if st.get('apron'):
        a = st['apron']
        cv.rect(9, 15 + by, 11, 19 + by, a.base)
        cv.row(15 + by, 9, 11, a.light)
    if st.get('belt'):
        cv.row(18 + by, 9, 14, st['belt'])
    # near arm in front
    near_arm_x = {'stand': 10, 'passA': 10, 'passB': 10, 'A': 12, 'B': 8}[phase]
    cv.rect(near_arm_x, 14 + by, near_arm_x + 1, 17 + by, sleeve.base)
    cv.set(near_arm_x + 1, 15 + by, sleeve.dark)
    cv.rect(near_arm_x, 18 + by, near_arm_x + 1, 19 + by, skin.base)
    cv.set(near_arm_x + 1, 19 + by, skin.dark)
    # head (profile, wider at back)
    prof = [(9, 15), (8, 16), (7, 17), (7, 17), (7, 17), (7, 17), (7, 17), (7, 17), (8, 16), (9, 15), (10, 14)]
    for i, (a, b) in enumerate(prof):
        cv.row(HEAD_TOP + i + by, a, b, skin.base)
    for i in range(5, 11):
        cv.set(prof[i][1], HEAD_TOP + i + by, skin.dark)
    cv.row(HEAD_TOP + 10 + by, 10, 14, skin.dark)
    cv.rect(10, 14 + by, 13, 14 + by, skin.dark)
    # nose, eye
    cv.set(6, 10 + by, skin.base)
    cv.set(6, 11 + by, skin.dark)
    eye = rgb('#2a1c24')
    cv.rect(9, 9 + by, 9, 10 + by, eye)
    cv.set(8, 9 + by, (255, 255, 255)) if False else None
    cv.set(8, 11 + by, st['blush'])
    cv.set(8, 12 + by, rgb('#a8504c'))
    if st.get('glasses'):
        g = rgb('#3a3550')
        cv.rect(7, 8 + by, 10, 8 + by, g)
        cv.rect(7, 11 + by, 10, 11 + by, g)
        cv.rect(7, 9 + by, 7, 10 + by, g)
        cv.rect(10, 9 + by, 10, 10 + by, g)
        cv.row(9 + by, 11, 14, g)

    base, hi, dk = hair.base, hair.light, hair.dark
    if style == 'hijab':
        for i, (a, b) in enumerate([(8, 16), (7, 17), (6, 18), (6, 18), (6, 18), (6, 18), (6, 18), (7, 18), (8, 18), (9, 18), (10, 17), (10, 17), (10, 17)]):
            cv.row(2 + i + by, a, b, base)
        # face opening
        for yy, (a, b) in {6: (7, 9), 7: (7, 10), 8: (7, 10), 9: (7, 10), 10: (7, 10), 11: (8, 10), 12: (9, 10)}.items():
            cv.row(yy + by, a, b, skin.base)
        cv.rect(8, 9 + by, 8, 10 + by, skin.base)
        cv.rect(9, 9 + by, 9, 10 + by, eye)
        cv.set(6, 10 + by, skin.base)
        cv.rect(10, 14 + by, 17, 16 + by, base)
        cv.rect(11, 17 + by, 16, 17 + by, dk)
        cv.row(3 + by, 9, 12, hi)
        for yy in range(6, 17):
            cv.set(18, yy + by, dk)
        return
    # top + back hair
    for i, (a, b) in enumerate([(9, 15), (8, 16), (7, 17), (7, 17)]):
        cv.row(3 + i + by, a, b, base)
    cv.row(2 + by, 9, 15, base)
    cv.row(3 + by, 10, 14, hi)
    cv.row(4 + by, 9, 11, hi)
    # back of head
    for y in range(7, 12):
        cv.row(y + by, 13, 17, base)
    cv.rect(17, 8 + by, 17, 11 + by, dk)
    cv.row(12 + by, 13, 14, dk)
    # sideburn / fringe at the front
    cv.row(7 + by, 7, 12, base)
    cv.set(9, 8 + by, base)
    cv.set(10, 8 + by, base)
    cv.set(11, 7 + by, dk)
    if style == 'spiky':
        for x, yy in ((8, 2), (11, 1), (14, 1), (16, 2)):
            cv.set(x, yy + by, base)
    if style == 'bun':
        cv.rect(14, 1 + by, 17, 4 + by, base)
        cv.set(15, 1 + by, hi)
        cv.rect(17, 3 + by, 17, 4 + by, dk)
    if style == 'long':
        cv.rect(13, 7 + by, 17, 17 + by, base)
        cv.rect(17, 12 + by, 17, 17 + by, dk)
        cv.row(17 + by, 13, 17, dk)
        cv.rect(13, 8 + by, 13, 10 + by, hi)
    if style == 'cap':
        c = st['cap']
        cv.row(2 + by, 8, 16, c.base)
        cv.row(3 + by, 7, 17, c.base)
        cv.row(4 + by, 6, 17, c.base)
        cv.row(5 + by, 6, 17, c.light)
        cv.row(6 + by, 3, 17, c.dark)  # brim sticks out front
        cv.row(7 + by, 4, 8, c.darker)
        cv.set(10, 4 + by, c.light)


# ---------------------------------------------------------------- assembly
FRAME_PARAMS = [
    # by, arm_l, arm_r, lift (front/back), side phase
    (0, 0, 0, 0, 'stand'),
    (1, -1, 1, -1, 'A'),
    (0, 0, 0, 0, 'passA'),
    (1, 1, -1, 1, 'B'),
]


def render(st, direction, frame):
    by, al, ar, lift, phase = FRAME_PARAMS[frame]
    cv = Canvas()
    if direction == 'down':
        # long hair/hijab back strands sit behind the torso: draw body first
        draw_legs_front(cv, st, by, lift)
        draw_torso_front(cv, st, by, al, ar)
        draw_head_front(cv, st, by)
        draw_face_front(cv, st, by)
        hair_front(cv, st, by)
        if st['style'] == 'hijab':
            draw_face_front(cv, st, by)
    elif direction == 'up':
        draw_back(cv, st, by, al, ar, lift)
    else:
        draw_side(cv, st, by, phase)
    img = cv.finish()
    if direction == 'right':
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img


def sheet(st, columns, directions=('down', 'up', 'left', 'right')):
    pass


def make_style(**kw):
    s = dict(kw)
    for k in ('skin', 'hair', 'top', 'bottom', 'shoes', 'sleeve', 'apron', 'skirt', 'cap'):
        if k in s and isinstance(s[k], str):
            s[k] = Ramp(s[k])
    s.setdefault('blush', rgb('#e8908a'))
    s.setdefault('style', 'short')
    return s


SKIN_LIGHT = '#f1c9a1'
SKIN_TAN = '#d9a273'
SKIN_DARK = '#a8704a'

PLAYER = make_style(
    skin=SKIN_TAN, hair='#3a2a28', style='spiky', top='#d8433c', under=rgb('#f4efe4'),
    bottom='#3d5a9e', shoes='#f1eee6', lanyard=None,
)

NPCS = [
    ('npc_librarian', make_style(skin=SKIN_LIGHT, hair='#7a6a8a', style='bun', top='#7b4f8f', under=rgb('#f4efe4'),
                                 bottom='#3c3a52', shoes='#3a2c34', glasses=True, skirt='#4a3f66')),
    ('npc_dorm_keeper', make_style(skin=SKIN_TAN, hair='#4a4a52', style='short', top='#4f8a6a', bottom='#3a4650',
                                   shoes='#2f2b33', belt=rgb('#6b4a2c'), lanyard=rgb('#d9a64a'))),
    ('npc_groundskeeper', make_style(skin=SKIN_DARK, hair='#6f6f78', style='cap', cap='#4d8a47', top='#8a6f3f',
                                     apron='#4f7a3d', bottom='#5a4a38', shoes='#3a2a20', belt=rgb('#3a2a20'))),
    ('npc_ajim', make_style(skin=SKIN_TAN, hair='#2a2230', style='short', top='#3f6fb0', sleeve='#3f6fb0',
                            bottom='#44464f', shoes='#e5e1d8')),
    ('npc_amer', make_style(skin=SKIN_LIGHT, hair='#4a3326', style='short', top='#c9a23a', bottom='#2f3b52',
                            shoes='#3a2c34')),
    ('npc_john', make_style(skin=SKIN_LIGHT, hair='#c98a3c', style='spiky', top='#3c8a7a', bottom='#4a4e5a',
                            shoes='#e5e1d8', under=rgb('#e8efe9'))),
    ('npc_hariz', make_style(skin=SKIN_TAN, hair='#241c26', style='spiky', top='#8a3f4a', bottom='#2f2f3a',
                             shoes='#d6d0c4')),
    ('npc_intan', make_style(skin=SKIN_LIGHT, hair='#e0719a', style='hijab', top='#f0e3ea', bottom='#6a4a78',
                             shoes='#4a3a50', skirt='#7a5a88')),
    ('npc_aleeya', make_style(skin=SKIN_LIGHT, hair='#3a2420', style='long', top='#e8a23c', bottom='#3a4a78',
                              shoes='#7a3a3a', skirt='#3a4a78')),
    ('npc_azib', make_style(skin=SKIN_TAN, hair='#2a2230', style='short', top='#6a4fb0', bottom='#2f3b52',
                            shoes='#2f2b33', glasses=True, under=rgb('#f4efe4'))),
    ('npc_ain_najwa', make_style(skin=SKIN_TAN, hair='#3fb0a8', style='hijab', top='#f0e8d8', bottom='#4a6a8a',
                                 shoes='#e8e0d0', skirt='#4f7a9e')),
]

DIRS = ('down', 'up', 'left', 'right')


def build_player(path):
    sheet_img = Image.new('RGBA', (CELL * 4, CELL * 4), (0, 0, 0, 0))
    for r, d in enumerate(DIRS):
        for f in range(4):
            sheet_img.paste(render(PLAYER, d, f), (f * CELL, r * CELL))
    sheet_img.save(path)


def build_npcs(path):
    sheet_img = Image.new('RGBA', (CELL * len(NPCS), CELL * 4), (0, 0, 0, 0))
    for c, (_, st) in enumerate(NPCS):
        for r, d in enumerate(DIRS):
            sheet_img.paste(render(st, d, 0), (c * CELL, r * CELL))
    sheet_img.save(path)


if __name__ == '__main__':
    build_player('assets/sprites/player_spritesheet.png')
    build_npcs('assets/sprites/npc_spritesheet.png')
    print('wrote player + npc sheets')
