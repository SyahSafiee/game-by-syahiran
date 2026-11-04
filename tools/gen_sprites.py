"""Procedural pixel-art character generator for game-by-syahiran.

Produces 24x24 frames matching the engine's existing sheet layout:
  player_spritesheet.png -> 4 cols (walk frames) x 4 rows (down,up,left,right)
  npc_spritesheet.png    -> N cols (one per NPC, static) x 4 rows

Style: chibi/RPG-Maker-ish proportions (big head, 2.5-head-tall body),
flat-shaded with a 1px darker outline/shadow per color area, matching the
nearest-neighbor pixel-perfect rendering the game already uses.
"""
from PIL import Image, ImageDraw

F = 24  # frame size


def darker(hex_color, amount=40):
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    r = max(0, r - amount)
    g = max(0, g - amount)
    b = max(0, b - amount)
    return (r, g, b, 255)


def c(hex_color, a=255):
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return (r, g, b, a)


class Char:
    """A character's palette + build, used to draw all 4 directions."""

    def __init__(
        self,
        skin,
        hair,
        hair_style,  # 'short_m','spiky','side_part','bald_grey','grey_short','bun','long','ponytail','twintail','wavy_long'
        top,
        bottom,
        bottom_type,  # 'pants' | 'skirt'
        shoes,
        build="youth",  # 'youth' | 'adult'
        accessory=None,  # 'glasses' | 'hat' | 'ribbon' | None
        undershirt=None,
    ):
        self.skin = c(skin)
        self.skin_sh = darker(skin, 30)
        self.hair = c(hair)
        self.hair_sh = darker(hair, 35)
        self.hair_style = hair_style
        self.top = c(top)
        self.top_sh = darker(top, 35)
        self.bottom = c(bottom)
        self.bottom_sh = darker(bottom, 35)
        self.bottom_type = bottom_type
        self.shoes = c(shoes)
        self.build = build
        self.accessory = accessory
        self.undershirt = c(undershirt) if undershirt else None


def new_canvas():
    return Image.new("RGBA", (F, F), (0, 0, 0, 0))


def draw_down_up(ch: Char, facing: str, frame: int) -> Image.Image:
    """facing: 'down' or 'up'. frame: 0..3 walk cycle (0/2 neutral, 1/3 step)."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    adult = ch.build == "adult"

    head_top = 2
    head_bot = head_top + (9 if adult else 10)
    head_l, head_r = 7, 16
    cx = (head_l + head_r) / 2

    torso_top = head_bot + 1
    torso_bot = torso_top + 6
    torso_l, torso_r = 6, 17

    leg_top = torso_bot
    leg_bot = leg_top + 4

    # leg animation offset: alternate legs step up/down by 1px
    step = 0
    if frame == 1:
        step = 1
    elif frame == 3:
        step = -1

    # --- legs (drawn first, behind torso hem) ---
    if ch.bottom_type == "skirt" and facing == "down":
        # trapezoid skirt, legs peek out below
        d.polygon(
            [(torso_l, leg_top - 2), (torso_r, leg_top - 2), (torso_r + 1, leg_top + 2), (torso_l - 1, leg_top + 2)],
            fill=ch.bottom,
        )
        d.line([(torso_l - 1, leg_top + 2), (torso_r + 1, leg_top + 2)], fill=ch.bottom_sh)
        leg_y0 = leg_top + 2
        d.rectangle([9, leg_y0 + step, 10, leg_bot], fill=ch.skin)
        d.rectangle([13, leg_y0 - step, 14, leg_bot], fill=ch.skin)
        d.rectangle([9, leg_bot, 10, leg_bot], fill=ch.shoes)
        d.rectangle([13, leg_bot, 14, leg_bot], fill=ch.shoes)
    else:
        lx0, lx1 = 9, 10
        rx0, rx1 = 13, 14
        d.rectangle([lx0, leg_top + step, lx1, leg_bot], fill=ch.bottom)
        d.rectangle([rx0, rx1, rx1, leg_bot] if False else [rx0, leg_top - step, rx1, leg_bot], fill=ch.bottom)
        d.rectangle([lx0, leg_bot - 1, lx1, leg_bot], fill=ch.shoes)
        d.rectangle([rx0, leg_bot - 1, rx1, leg_bot], fill=ch.shoes)

    # --- arms (sides of torso, skin or sleeve colored) ---
    sleeve = ch.top
    d.rectangle([torso_l - 2, torso_top + 1, torso_l - 1, torso_bot - 1], fill=sleeve)
    d.rectangle([torso_r + 1, torso_top + 1, torso_r + 2, torso_bot - 1], fill=sleeve)
    d.rectangle([torso_l - 2, torso_bot - 2, torso_l - 1, torso_bot - 1], fill=ch.skin)
    d.rectangle([torso_r + 1, torso_bot - 2, torso_r + 2, torso_bot - 1], fill=ch.skin)

    # --- torso ---
    d.rectangle([torso_l, torso_top, torso_r, torso_bot], fill=ch.top)
    d.rectangle([torso_l, torso_bot - 1, torso_r, torso_bot], fill=ch.top_sh)
    if ch.undershirt and facing == "down":
        d.rectangle([cx - 1, torso_top, cx + 1, torso_top + 1], fill=ch.undershirt)

    # --- head ---
    d.ellipse([head_l, head_top, head_r, head_bot], fill=ch.skin)
    d.line([(head_l + 1, head_bot), (head_r - 1, head_bot)], fill=ch.skin_sh)

    if facing == "down":
        # eyes
        d.point([(cx - 2, head_bot - 4), (cx + 2, head_bot - 4)], fill=(40, 30, 25, 255))
        if adult and ch.accessory != "glasses":
            d.point([(cx - 2, head_bot - 2)], fill=darker("D1A074", 60))  # subtle mouth/mustache hint

    _draw_hair(d, ch, head_l, head_top, head_r, head_bot, facing, cx)

    if ch.accessory == "glasses" and facing == "down":
        d.rectangle([cx - 3, head_bot - 5, cx - 1, head_bot - 4], outline=(30, 30, 30, 255))
        d.rectangle([cx + 1, head_bot - 5, cx + 3, head_bot - 4], outline=(30, 30, 30, 255))
    if ch.accessory == "ribbon" and facing == "down":
        d.rectangle([head_r - 3, head_top, head_r - 1, head_top + 2], fill=c("E85D9E"))

    return img


def _draw_hair(d, ch: Char, hl, ht, hr, hb, facing, cx):
    style = ch.hair_style
    back = facing == "up"

    if style == "bald_grey":
        d.arc([hl - 1, ht - 1, hr + 1, hb - 3], 180, 360, fill=ch.hair)
        d.line([(hl, ht + 3), (hl, ht + 5)], fill=ch.hair)
        d.line([(hr, ht + 3), (hr, ht + 5)], fill=ch.hair)
        return

    # cap covering top of head
    d.pieslice([hl - 1, ht - 2, hr + 1, hb - 2], 180, 360, fill=ch.hair)
    d.rectangle([hl - 1, ht + 2, hr + 1, ht + 4], fill=ch.hair)

    if style == "spiky":
        for x in range(hl, hr + 1, 2):
            d.line([(x, ht - 1), (x + 1, ht - 2)], fill=ch.hair)
        d.rectangle([hl - 1, ht + 1, hl + 1, ht + 6], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 6], fill=ch.hair)
    elif style == "short_m":
        d.rectangle([hl - 1, ht + 1, hl + 1, ht + 5], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 5], fill=ch.hair)
    elif style == "side_part":
        d.rectangle([hl - 1, ht + 1, hl + 2, ht + 6], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr, ht + 4], fill=ch.hair)
    elif style == "grey_short":
        d.rectangle([hl - 1, ht + 1, hl + 1, ht + 5], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 5], fill=ch.hair)
    elif style == "long":
        d.rectangle([hl - 2, ht + 2, hl, hb + 4], fill=ch.hair)
        d.rectangle([hr, ht + 2, hr + 2, hb + 4], fill=ch.hair)
        if back:
            d.rectangle([hl - 1, ht + 2, hr + 1, hb + 5], fill=ch.hair)
    elif style == "wavy_long":
        d.rectangle([hl - 3, ht + 2, hl - 1, hb + 5], fill=ch.hair)
        d.rectangle([hr + 1, ht + 2, hr + 3, hb + 5], fill=ch.hair)
        d.point([(hl - 3, hb + 2), (hr + 3, hb + 2)], fill=ch.hair_sh)
        if back:
            d.rectangle([hl - 2, ht + 2, hr + 2, hb + 6], fill=ch.hair)
    elif style == "ponytail":
        d.rectangle([hl - 1, ht + 1, hl + 1, ht + 5], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 5], fill=ch.hair)
        tail_x = hr if not back else cx
        d.rectangle([tail_x, ht + 3, tail_x + 2, hb + 6], fill=ch.hair)
    elif style == "twintail":
        d.rectangle([hl - 3, ht + 2, hl - 1, hb + 2], fill=ch.hair)
        d.rectangle([hr + 1, ht + 2, hr + 3, hb + 2], fill=ch.hair)
    elif style == "bun":
        d.rectangle([hl, ht + 1, hr, ht + 4], fill=ch.hair)
        d.ellipse([cx - 2, ht - 3, cx + 2, ht + 1], fill=ch.hair)

    if ch.accessory == "hat":
        d.rectangle([hl - 2, ht - 3, hr + 2, ht], fill=c("C2A05A"))
        d.rectangle([hl - 2, ht - 1, hr + 2, ht], fill=darker("C2A05A", 30))


def draw_side(ch: Char, frame: int) -> Image.Image:
    """Left-facing profile; right is produced by mirroring this."""
    img = new_canvas()
    d = ImageDraw.Draw(img)
    adult = ch.build == "adult"

    head_top = 2
    head_bot = head_top + (9 if adult else 10)
    head_l, head_r = 8, 16
    torso_top = head_bot + 1
    torso_bot = torso_top + 6
    torso_l, torso_r = 8, 15
    leg_top = torso_bot
    leg_bot = leg_top + 4

    step = 0
    if frame == 1:
        step = 1
    elif frame == 3:
        step = -1

    # back leg, front leg (front leg steps)
    if ch.bottom_type == "skirt":
        d.polygon(
            [(torso_l - 1, leg_top - 2), (torso_r + 1, leg_top - 2), (torso_r + 2, leg_top + 2), (torso_l - 2, leg_top + 2)],
            fill=ch.bottom,
        )
        y0 = leg_top + 2
        d.rectangle([9, y0, 10, leg_bot], fill=ch.skin)
        d.rectangle([12 + step, y0 - max(step, 0), 13 + step, leg_bot], fill=ch.skin)
        d.rectangle([9, leg_bot, 10, leg_bot], fill=ch.shoes)
        d.rectangle([12 + step, leg_bot, 13 + step, leg_bot], fill=ch.shoes)
    else:
        d.rectangle([10, leg_top, 11, leg_bot], fill=ch.bottom_sh)
        d.rectangle([10, leg_bot - 1, 11, leg_bot], fill=ch.shoes)
        fx = 11 + step
        d.rectangle([fx, leg_top, fx + 1, leg_bot], fill=ch.bottom)
        d.rectangle([fx, leg_bot - 1, fx + 1, leg_bot], fill=ch.shoes)

    # back arm hinted, front arm visible
    d.rectangle([torso_l - 1, torso_top + 1, torso_l, torso_bot - 1], fill=ch.top)
    d.rectangle([torso_l - 1, torso_bot - 2, torso_l, torso_bot - 1], fill=ch.skin)

    # torso
    d.rectangle([torso_l, torso_top, torso_r, torso_bot], fill=ch.top)
    d.rectangle([torso_l, torso_bot - 1, torso_r, torso_bot], fill=ch.top_sh)

    # head (profile oval, nose bump toward facing side = left)
    d.ellipse([head_l, head_top, head_r, head_bot], fill=ch.skin)
    d.rectangle([head_l - 1, head_top + 5, head_l, head_top + 7], fill=ch.skin)
    d.line([(head_l, head_bot), (head_r - 1, head_bot)], fill=ch.skin_sh)
    # eye
    d.point([(head_l + 2, head_top + 5)], fill=(40, 30, 25, 255))

    _draw_hair_side(d, ch, head_l, head_top, head_r, head_bot)

    return img


def _draw_hair_side(d, ch: Char, hl, ht, hr, hb):
    style = ch.hair_style
    d.pieslice([hl - 1, ht - 2, hr + 2, hb - 2], 200, 350, fill=ch.hair)
    d.rectangle([hl, ht + 1, hr + 1, ht + 3], fill=ch.hair)

    if style == "bald_grey":
        d.rectangle([hr - 1, ht + 2, hr + 1, ht + 5], fill=ch.hair)
        return
    if style in ("spiky",):
        d.polygon([(hr - 2, ht - 1), (hr + 2, ht - 2), (hr + 1, ht + 1)], fill=ch.hair)
        d.rectangle([hr - 1, ht + 1, hr + 2, ht + 6], fill=ch.hair)
    elif style in ("short_m", "grey_short", "side_part"):
        d.rectangle([hr - 1, ht + 1, hr + 2, ht + 6], fill=ch.hair)
    elif style in ("long", "wavy_long"):
        d.rectangle([hr - 1, ht + 1, hr + 2, hb + 5], fill=ch.hair)
        d.rectangle([hl, ht + 2, hl + 1, hb + 1], fill=ch.hair)
    elif style == "ponytail":
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 5], fill=ch.hair)
        d.rectangle([hl - 2, ht + 3, hl, hb + 6], fill=ch.hair)
    elif style == "twintail":
        d.rectangle([hr - 1, ht + 1, hr + 1, ht + 4], fill=ch.hair)
        d.rectangle([hl - 2, ht + 2, hl, hb + 1], fill=ch.hair)
    elif style == "bun":
        d.rectangle([hl, ht + 1, hr + 1, ht + 3], fill=ch.hair)
        d.ellipse([hl - 1, ht - 3, hl + 3, ht + 1], fill=ch.hair)

    if ch.accessory == "hat":
        d.rectangle([hl - 1, ht - 3, hr + 2, ht], fill=c("C2A05A"))
        d.rectangle([hl - 1, ht - 1, hr + 2, ht], fill=darker("C2A05A", 30))


def build_frames(ch: Char):
    """Returns dict[direction] -> list of 4 PIL frames."""
    down = [draw_down_up(ch, "down", f) for f in range(4)]
    up = [draw_down_up(ch, "up", f) for f in range(4)]
    left = [draw_side(ch, f) for f in range(4)]
    right = [f.transpose(Image.FLIP_LEFT_RIGHT) for f in left]
    return {"down": down, "up": up, "left": left, "right": right}


def paste_player_sheet(ch: Char, path):
    sheet = Image.new("RGBA", (F * 4, F * 4), (0, 0, 0, 0))
    frames = build_frames(ch)
    rows = ["down", "up", "left", "right"]
    for r, dirname in enumerate(rows):
        for col, frame_img in enumerate(frames[dirname]):
            sheet.paste(frame_img, (col * F, r * F), frame_img)
    sheet.save(path)


def paste_npc_sheet(chars_in_order, path):
    n = len(chars_in_order)
    sheet = Image.new("RGBA", (F * n, F * 4), (0, 0, 0, 0))
    rows = ["down", "up", "left", "right"]
    for col, ch in enumerate(chars_in_order):
        frames = build_frames(ch)
        for r, dirname in enumerate(rows):
            frame_img = frames[dirname][0]  # static neutral pose
            sheet.paste(frame_img, (col * F, r * F), frame_img)
    sheet.save(path)


# ---------------------------------------------------------------------------
# Character definitions
# ---------------------------------------------------------------------------

player = Char(
    skin="E8B894", hair="4A3121", hair_style="spiky",
    top="E8743B", bottom="C9A66B", bottom_type="pants", shoes="C0392B",
    build="youth", undershirt="2C3E6B",
)

npc_defs = {
    "npc_librarian": Char(
        skin="D9A878", hair="5B5B5B", hair_style="bun",
        top="7A3B46", bottom="3A3A4A", bottom_type="skirt", shoes="3A2E2E",
        build="adult", accessory="glasses",
    ),
    "npc_dorm_keeper": Char(
        skin="D1A074", hair="8A8A8A", hair_style="grey_short",
        top="5B6B3D", bottom="33363B", bottom_type="pants", shoes="2B2320",
        build="adult",
    ),
    "npc_groundskeeper": Char(
        skin="C98A5B", hair="9A9A9A", hair_style="bald_grey",
        top="8B5E34", bottom="4C6B3C", bottom_type="pants", shoes="3A2E2E",
        build="adult", accessory="hat",
    ),
    "npc_ajim": Char(
        skin="E0AC78", hair="241C15", hair_style="short_m",
        top="3B6EA8", bottom="36454F", bottom_type="pants", shoes="2B2320",
        build="youth",
    ),
    "npc_amer": Char(
        skin="D9A066", hair="1C1C1C", hair_style="side_part",
        top="4C9A52", bottom="2C3E50", bottom_type="pants", shoes="2B2320",
        build="youth",
    ),
    "npc_john": Char(
        skin="F0C8A0", hair="6B4423", hair_style="short_m",
        top="D8D8D8", bottom="6B2C3E", bottom_type="pants", shoes="3A2E2E",
        build="youth",
    ),
    "npc_hariz": Char(
        skin="E0AC78", hair="201A14", hair_style="spiky",
        top="7D5BA6", bottom="26272B", bottom_type="pants", shoes="201A14",
        build="youth",
    ),
    "npc_azib": Char(
        skin="DDA873", hair="2A2117", hair_style="side_part",
        top="2E8B8B", bottom="4A4A52", bottom_type="pants", shoes="2B2320",
        build="youth", accessory="glasses",
    ),
    "npc_intan": Char(
        skin="E0AC78", hair="1C1410", hair_style="long",
        top="E07A9E", bottom="4F6D8C", bottom_type="skirt", shoes="3A2E2E",
        build="youth",
    ),
    "npc_aleeya": Char(
        skin="E3B38A", hair="3B2A1E", hair_style="twintail",
        top="9A6FB0", bottom="2F2F3A", bottom_type="skirt", shoes="3A2E2E",
        build="youth",
    ),
    "npc_ain_najwa": Char(
        skin="E8B894", hair="5A3A26", hair_style="wavy_long",
        top="E8C547", bottom="2C3E6B", bottom_type="skirt", shoes="4A2E1E",
        build="youth", accessory="ribbon",
    ),
}

if __name__ == "__main__":
    import sys
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    paste_player_sheet(player, f"{out_dir}/player_spritesheet.png")
    order = [
        "npc_librarian", "npc_dorm_keeper", "npc_groundskeeper",
        "npc_ajim", "npc_amer", "npc_john", "npc_hariz",
        "npc_intan", "npc_aleeya", "npc_azib", "npc_ain_najwa",
    ]
    paste_npc_sheet([npc_defs[k] for k in order], f"{out_dir}/npc_spritesheet.png")
    print("done")
