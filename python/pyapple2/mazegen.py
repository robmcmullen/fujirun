#!/usr/bin/env python

# Basic maze: 40x24, rightmost 7 cols are the score area
#
# 00 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______
# 01 X/----T----T----T----T----T----\X_______
# 02 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 03 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 04 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______
# 05 X|XXXX|XXXX+----+XXXX|XXXX+----+X_______
# 06 X|XXXX|XXXX|XXXX+----+XXXX|XXXX|X_______
# 07 X|XXXX+----+XXXX|XXXX|XXXX|XXXX|X_______
# 08 X+----+XXXX+----+XXXX|XXXX|XXXX|X_______
# 09 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______
# 10 X|XXXX+----+XXXX|XXXX|XXXX+----+X_______
# 11 X|XXXX|XXXX|XXXX+----+XXXX|XXXX|X_______
# 12 X+----+XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 13 X|XXXX+----+XXXX|XXXX|XXXX|XXXX|X_______
# 14 X|XXXX|XXXX+----+XXXX+----+XXXX|X_______
# 15 X|XXXX|XXXX|XXXX|XXXX|XXXX+----+X_______
# 16 X|XXXX|XXXX|XXXX+----+XXXX|XXXX|X_______
# 17 X|XXXX+----+XXXX|XXXX|XXXX|XXXX|X_______
# 18 X+----+XXXX+----+XXXX|XXXX+----+X_______
# 19 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______
# 20 X|XXXX+----+XXXX+----+XXXX|XXXX|X_______
# 21 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 22 X\----^----^----^----^----^----/X_______
# 23 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______
#
# Terminology:
#
# vpath - vertical path
# hpath - horizontal path
# boxes - area inside path boundaries that gets filled when dots around it are collected
# enemy - uses Amidar movement
# player - joystick control
# actor - either a player or an enemy

import time
import random
import curses

import numpy as np

import logging
init_log = logging.getLogger("init")
logic_log = logging.getLogger("logic")
draw_log = logging.getLogger("draw")
maze_log = logging.getLogger("maze")
box_log = logging.getLogger("maze")
game_log = logging.getLogger("game")

CURSES = 1

##### Game loader

pad = None

def init():
    if CURSES:
        curses.wrapper(init_screen)
    else:
        main()

def init_screen(*args, **kwargs):
    global pad, curseschars

    curses.use_default_colors()
    curses.start_color()
    curses.init_pair(1, curses.COLOR_BLUE, curses.COLOR_WHITE)
    curses.curs_set(0)
    pad = curses.newpad(30, 80)
    pad.timeout(0)
    pad.keypad(1)

    # have to define these here because initscr hasn't been called when parsing
    # the python source.
    curseschars = [
        curses.ACS_CKBOARD,  # illegal
        curses.ACS_CKBOARD,
        curses.ACS_CKBOARD,
        curses.ACS_VLINE,  # 3: up/down
        curses.ACS_CKBOARD,
        curses.ACS_ULCORNER,  # 5: down/right
        curses.ACS_LLCORNER,  # 6: up/right
        curses.ACS_LTEE,  # 7: up/down/right
        curses.ACS_CKBOARD,
        curses.ACS_URCORNER,  # 9: left/down
        curses.ACS_LRCORNER,  # 10: left/up
        curses.ACS_RTEE,  # 11: left/up/down
        curses.ACS_HLINE,  # 12: left/right
        curses.ACS_TTEE,  # 13: left/right/down
        curses.ACS_BTEE,  # 14: left/right/up
        curses.ACS_CKBOARD,

        # And same again, with dots
        curses.ACS_CKBOARD,  # illegal
        curses.ACS_CKBOARD,
        curses.ACS_CKBOARD,
        curses.ACS_VLINE,  # 3: up/down
        curses.ACS_CKBOARD,
        curses.ACS_ULCORNER,  # 5: down/right
        curses.ACS_LLCORNER,  # 6: up/right
        curses.ACS_LTEE,  # 7: up/down/right
        curses.ACS_CKBOARD,
        curses.ACS_URCORNER,  # 9: left/down
        curses.ACS_LRCORNER,  # 10: left/up
        curses.ACS_RTEE,  # 11: left/up/down
        curses.ACS_HLINE,  # 12: left/right
        curses.ACS_TTEE,  # 13: left/right/down
        curses.ACS_BTEE,  # 14: left/right/up
        curses.ACS_CKBOARD,
    ]

    main()


def main():
    global level, cur_enemies, cur_players

    init_maze()
    print_maze()
    screen[:,0:33] = maze

    show_screen()

    level = 1
    cur_enemies = level_enemies[level]
    cur_players = 1
    init_enemies()
    init_players()
    init_static_background()

    game_loop()
    print_maze()

##### Memory usage

# Zero page

r = 0
c = 0
round_robin_index = [0, 0]  # down, up

# 2 byte addresses

maze = np.empty((24, 33), dtype=np.uint8)

screen = np.empty((24, 40), dtype=np.uint8)

tiledown = 0x1
tileup = 0x2
tileright = 0x4
tileleft= 0x8
tilehorz = tileleft | tileright
tilevert = tileup | tiledown
dir_mask = 0x0f
tiledot = 0x10

vpath_num = 7
box_width = 4
vpath_col_spacing = box_width + 1
vpath_cols = [
    1 + 0 * vpath_col_spacing,
    1 + 1 * vpath_col_spacing,
    1 + 2 * vpath_col_spacing,
    1 + 3 * vpath_col_spacing,
    1 + 4 * vpath_col_spacing,
    1 + 5 * vpath_col_spacing,
    1 + 6 * vpath_col_spacing,
    ]
vpath_top_tile = [
    tiledot|tiledown|tileright,
    tiledot|tiledown|tileleft|tileright,
    tiledot|tiledown|tileleft|tileright,
    tiledot|tiledown|tileleft|tileright,
    tiledot|tiledown|tileleft|tileright,
    tiledot|tiledown|tileleft|tileright,
    tiledot|tiledown|tileleft,
    ]
vpath_bot_tile = [
    tiledot|tileup|tileright,
    tiledot|tileup|tileleft|tileright,
    tiledot|tileup|tileleft|tileright,
    tiledot|tileup|tileleft|tileright,
    tiledot|tileup|tileleft|tileright,
    tiledot|tileup|tileleft|tileright,
    tiledot|tileup|tileleft,
    ]

# up/down/left/right would be 0xf, but this is not legal for ghost legs
tilechars = [
    "x",  # illegal
    "x",
    "x",
    "|",  # 3: up/down
    "x",
    "/",  # 5: down/right
    "\\",  # 6: up/right
    "+",  # 7: up/down/right
    "x",
    "\\",  # 9: left/down
    "/",  # 10: left/up
    "+",  # 11: left/up/down
    "-",  # 12: left/right
    "T",  # 13: left/right/down
    "^",  # 14: left/right/up
    "x",

    # And same again, with dots
    "x",  # illegal
    "x",
    "x",
    "|",  # 3: up/down
    "x",
    "/",  # 5: down/right
    "\\",  # 6: up/right
    "+",  # 7: up/down/right
    "x",
    "\\",  # 9: left/down
    "/",  # 10: left/up
    "+",  # 11: left/up/down
    "-",  # 12: left/right
    "T",  # 13: left/right/down
    "^",  # 14: left/right/up
    "x",

    "@",  # 32: enemy (temporary)
    "$",  # 33: player
]


# up/down/left/right would be 0xf, but this is not legal for ghost legs
curseschars = None


##### Constants

# Screen has rows 0 - 23
# Maze is rows 1 - 22
mazetoprow = 1
mazebotrow = 22
screenrows = 24

# Screen has cols 0 - 39
# cols 0 - 32 are the maze, of which 1 - 31 are actually used
#  0 and 32 are border tiles having the value zero
# cols 33 - 39 is the score area
mazeleftcol = 1
mazerightcol = 31
mazescorecol = 33
p1scorerow = 2
p2scorerow = 5
screencols = 40

# Orbiter goes around the outside border, but not through the maze
orbiterstartcol = mazerightcol
orbiterstartrow = (mazetoprow + mazebotrow) / 2


##### Utility functions

# Returns address of tile in col 0 of row y
def mazerow(y):
    return maze[y]

# Returns address of tile in col 0 of row y of the "screen" memory
def screenrow(y):
    return screen[y]

# Return a random number between 3 and 5 (inclusive) to represent next row that
# contains an hpath. 3 is the minimum number so that if necessary, the last
# spacing on the bottom can be adjusted upward by 1 to guarantee no cross-
# throughs
def get_rand_spacing():
    return random.randint(3, 5)

# Random number between 0 and 6 (inclusive) used for column starting positions
def get_rand7():
    return random.randint(0, 6)

def get_rand_byte():
    return random.randint(0, 255)

# Get random starting columns for enemies by swapping elements in a list
# several times
def get_col_randomizer():
    r = list(vpath_cols)
    x = 10
    while x >= 0:
        i1 = get_rand7()
        i2 = get_rand7()
        old1 = r[i1]
        r[i1] = r[i2]
        r[i2] = old1
        x -= 1
    return r


###### Level creation functions

def clear_maze():
    y = 0
    while y < screenrows:
        addr = mazerow(y)
        x = 0
        while x < mazescorecol:
            addr[x] = 0
            x += 1
        y += 1
    init_boxes()

# Set all elements in a row to dot + left + right; only top and bottom
def setrow(row):
    addr = mazerow(row)
    x = mazeleftcol
    while x <= mazerightcol:
        addr[x] = tiledot|tileleft|tileright
        x += 1

# Create all 7 vpaths, using top/bot character from a list to handle both
# corners and T connections.
def setvpath(col):
    x = vpath_cols[col]
    y = mazetoprow
    addr = mazerow(y)
    addr[x] = vpath_top_tile[col]
    y += 1
    while y < mazebotrow:
        addr = mazerow(y)
        addr[x] = tiledot|tileup|tiledown
        y += 1
    addr = mazerow(y)
    addr[x] = vpath_bot_tile[col]


# Create hpaths such that there are no hpaths that meet at the same row in
# adjacent columns (cross-throughs are not allowed in ghost legs). Starts at
# the rightmost vpath and moves left using the rightmost vpath as the input to
# this function and building hpaths between it and the vpath to the left. The
# first time this routine is called there won't be any existing columns to
# compare to, otherwise if a tile on the left vpath has a rightward pointing
# hpath, move up one and draw the hpath there. This works because the minimum
# hpath vertical positioning leaves 2 empty rows, so moving up by one still
# leaves 1 empty row.
def sethpath(col):
    x1_save = vpath_cols[col - 1]
    x2 = vpath_cols[col]
    y = mazetoprow
    start_box(y, x1_save)
    y += get_rand_spacing()
    while y < mazebotrow - 1:
        addr = mazerow(y)

        # If not working on the rightmost column, check to see there are
        # no cross-throughs.
        if col < vpath_num - 1:
            tile = addr[x2]
            if tile & tileright:
                maze_log.debug("at y=%d on col %d, found same hpath level at col %d" % (y, col, col + 1))
                y -= 1
                addr = mazerow(y)
        add_box(y)

        x = x1_save
        addr[x] = tiledot|tileup|tiledown|tileright
        x += 1
        while x < x2:
            addr[x] = tiledot|tileleft|tileright
            x += 1
        addr[x2] = tiledot|tileup|tiledown|tileleft
        y += get_rand_spacing()
    add_box(mazebotrow)


def init_maze():
    clear_maze()

    # Draw top and bottom; no intersections anywhere. Corners and T
    # intesections will be placed in setvpath
    setrow(mazetoprow)
    setrow(mazebotrow)

    # Draw all vpaths, including corners and top/bot T intersections
    counter = vpath_num
    counter -= 1
    while counter >= 0:
        setvpath(counter)
        counter -= 1

    # Draw connectors between vpaths, starting with the rightmost column and
    # the one immediately left of it. This is performed 6 times because it
    # always needs a pair of columns to work with.
    counter = vpath_num
    counter -= 1
    while counter > 0:  # note >, not >=
        sethpath(counter)
        counter -= 1

    finish_boxes()


##### Box handling/painting

# Level box storage uses the left column (we don't need to store the right side
# because they are always a fixed distance away) and a list of rows.
#
# To examine the boundary of each box to check for dots, the top row and the
# bottom row must look at box_width + 2 tiles, all the middle rows only have to
# check the left and right tiles
#
# The entire list of rows doesn't need to be stored, either; only the top and
# bottom because everything else is a middle row. Therefore, all we need is the
# x of the left vpath, the top row and the bottom row:
#
# x1, ytop, ybot
#
# is 3 bytes. Max number of boxes is 10 per column, 6 columns that's 10 * 6 * 3
# = 180 bytes. Less than 256, yay!
#
# n can also be used as a flag: if n == 0, the box has already been checked and
# painted. n == 0xff is the flag to end processing.

# 01 X/----T----T----T----T----T----\X_______
# 02 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 03 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 04 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______

next_level_box = 0  # in the assembly, this will be it the x or y register or zero page
level_boxes = [0] * 10 * 6 * 8
box_col_save = 0
box_row_save = 0

# Box painting will be in hires so this array will become a tracker for the
# hires display. It will need y address, y end address, x byte number. It's
# possible for up to 3 boxes to get triggered to start painting when collecting
# a dot, and because it will take multiple frames to paint a box there may be
# even more active at one time, so for safety use 16 as possible max.
#
# xbyte, ytop, ybot
box_painting = [0] * 3 * 16

def init_boxes():
    next_level_box = 0

def start_box(r, c):
    global box_col_save, box_row_save

    box_col_save = c
    box_row_save = r

def add_box(r):
    global next_level_box, box_row_save

    i = next_level_box
    level_boxes[i] = box_col_save
    level_boxes[i + 1] = box_row_save
    level_boxes[i + 2] = r
    box_row_save = r
    next_level_box += 3

def finish_boxes():
    i = next_level_box
    level_boxes[i] = 0xff

def check_boxes(i):
    x = 0
    pad.addstr(28, 0, str(level_boxes[0:21]))
    while level_boxes[x] < 0xff:
        c = level_boxes[x]
        if c > 0:
            r1 = level_boxes[x + 1]
            addr = mazerow(r1)
            r1 += 1
            r1_save = r1

            # If there's a dot anywhere, then the box isn't painted. We don't
            # care where it is so we don't need to keep track of individual
            # locations.
            dot = addr[c] | addr[c + 1] | addr[c + 2] | addr[c + 3] | addr[c + 4] | addr[c + 5]

            r2 = level_boxes[x + 2]
            addr = mazerow(r2)
            dot |= addr[c] | addr[c + 1] | addr[c + 2] | addr[c + 3] | addr[c + 4] | addr[c + 5]

            while r1 < r2:
                addr = mazerow(r1)
                dot |= addr[c] | addr[c + 5]
                r1 += 1

            if (dot & tiledot) == 0:
                # No dots anywhere! Start painting
                mark_box_for_painting(r1_save, r2, c + 1)
                num_rows = r2 - r1_save
                player_score[i] += num_rows * 100
                level_boxes[x] = 0  # Set flag so we don't check this box again

        x += 3

def mark_box_for_painting(r1, r2, c):
    box_log.debug("Marking box at %d,%d -> %d,%d" % (r1, c, r2, c + box_width))
    x = 0
    while x < 3 * 16:
        if box_painting[x] == 0:
            box_painting[x] = c
            box_painting[x + 1] = r1
            box_painting[x + 2] = r2
            break
        x += 3
    pad.addstr(27, 0, "starting box %d,%d -> %d,%d" % (r1, c, r2, c + box_width))


##### Gameplay storage

config_num_players = 1
config_quit = 0

level = -1
level_enemies = [255, 4, 5, 6, 7, 8]  # level starts counting from 1, so dummy zeroth level info
level_speeds = [255, 0, 0, 0, 0, 0]  # probably needs to be 16 bit
level_start_col = [
    [255, 255, 255, 255],
    [3, 0, 0, 0],
    [2, 4, 0, 0],
    [1, 3, 5, 0],
    [0, 2, 4, 6],
]

# Hardcoded, up to 8 enemies because there are max of 7 vpaths + 1 orbiter
# Enemy #0 is the orbiter
max_enemies = 8
cur_enemies = -1
enemy_col = [0, 0, 0, 0, 0, 0, 0, 0]  # current tile column
enemy_row = [0, 0, 0, 0, 0, 0, 0, 0]  # current tile row
enemy_updown = [0, 0, 0, 0, 0, 0, 0, 0]  # preferred direction
enemy_dir = [0, 0, 0, 0, 0, 0, 0, 0]  # actual direction
enemy_target_col = [0, 0, 0, 0, 0, 0, 0, 0]  # target column at bot or top T

round_robin_up = [0, 0, 0, 0, 0, 0, 0]
round_robin_down = [0, 0, 0, 0, 0, 0, 0]

# Hardcoded, up to 4 players
max_players = 4
cur_players = 1
player_col = [0, 0, 0, 0]  # current tile col
player_row = [0, 0, 0, 0]  # current tile row
player_input_dir = [0, 0, 0, 0]  # current joystick input direction
player_dir = [0, 0, 0, 0]  # current movement direction
dot_eaten_row = [255, 255, 255, 255]  # dot eaten by player
dot_eaten_col = [255, 255, 255, 255]
player_score = [0, 0, 0, 0]

# Scores

dot_score = 10
paint_score_per_line = 100

##### Gameplay initialization

def init_enemies():
    enemy_col[0] = orbiterstartcol
    enemy_row[0] = orbiterstartrow
    enemy_dir[0] = tileup
    x = 1
    randcol = get_col_randomizer()
    while x < cur_enemies:
        enemy_col[x] = randcol[x]
        enemy_row[x] = mazetoprow
        enemy_updown[x] = tiledown
        enemy_dir[x] = tiledown
        enemy_target_col[x] = 0  # Arbitrary, just need valid default
        x += 1
    round_robin_up[:] = get_col_randomizer()
    round_robin_down[:] = get_col_randomizer()
    round_robin_index[:] = [0, 0]

def get_col_start():
    addr = level_start_col[cur_players]
    return addr

def init_players():
    x = 0
    start = get_col_start()
    while x < cur_players:
        player_col[x] = vpath_cols[start[x]]
        player_row[x] = mazebotrow
        player_input_dir[x] = 0
        player_dir[x] = 0
        x += 1


##### Drawing routines

# Sprites use a backing store array that captures the background before each
# sprite is drawn. Each sprite's backing store is a a rectange of bytes (always
# starting on a byte boundary) stored consecutively starting with the first row
# of bytes, then the second, etc. on down the streen for the height of the
# sprite. The backing store doesn't actually care what the x value of the
# actual sprite is, only the byte number in the row of the first pixel
# affected.

# Max 16 sprites?
last_sprite_byte = [0] * 16  # byte number in row (0 - 39)
last_sprite_y = [0] * 16  # y coord of upper left corner of sprite
last_sprite_addr = [0] * 16  # Addr of sprite? Index of sprite?
sprite_backing_store = [0] * 16  # Addr of backing store? Index into array?
sprite_bytes_per_row = [0] * 16  # backing store is a rectangle of bytes
sprite_num_rows = [0] * 16  # Addr of sprite? Index of sprite?
num_sprites_drawn = 0

# Erase sprites in reverse order that they're drawn to restore the background
# properly
def erase_sprites():
    global num_sprites_drawn

    while num_sprites_drawn > 0:
        num_sprites_drawn -= 1
        i = num_sprites_drawn
        val = sprite_backing_store[i]
        r = last_sprite_y[i]
        addr = screenrow(r)
        c = last_sprite_byte[i]
        draw_log.debug("restoring background %d @ (%d,%d)" % (i, r, c))
        addr[c] = val

def save_backing_store(r, c, sprite):
    global num_sprites_drawn

    addr = mazerow(r)
    i = num_sprites_drawn
    draw_log.debug("saving background %d @ (%d,%d)" % (i, r, c))
    last_sprite_byte[i] = c
    last_sprite_y[i] = r
    last_sprite_addr[i] = sprite
    sprite_backing_store[i] = addr[c]
    sprite_bytes_per_row[i] = 1
    sprite_num_rows[i] = 1
    num_sprites_drawn += 1

def draw_sprite(r, c, sprite):
    save_backing_store(r, c, sprite)
    addr = screenrow(r)
    addr[c] = sprite

def draw_enemies():
    i = 0
    while i < cur_enemies:
        r = enemy_row[i]
        c = enemy_col[i]
        sprite = get_enemy_sprite(i)
        draw_sprite(r, c, sprite)

        enemy_history[i].append((r, c))
        i += 1

def draw_players():
    i = 0
    while i < cur_players:
        r = player_row[i]
        c = player_col[i]
        sprite = get_player_sprite(i)
        draw_sprite(r, c, sprite)

        player_history[i].append((r, c))
        i += 1

def get_enemy_sprite(i):
    return ord("0") + i

def get_player_sprite(i):
    return ord("$") + i


##### Game logic

# Determine which of the 4 directions is allowed at the given row, col
def get_allowed_dirs(r, c):
    addr = mazerow(r)
    allowed = addr[c] & dir_mask
    return allowed

# See if current tile has a dot
def has_dot(r, c):
    addr = mazerow(r)
    return addr[c] & tiledot

# clear a dot
def clear_dot(r, c):
    addr = mazerow(r)
    addr[c] &= ~tiledot

# Determine the tile location given the direction of the actor's movement
def get_next_tile(r, c, dir):
    if dir & tileup:
        r -= 1
    elif dir & tiledown:
        r += 1
    elif dir & tileleft:
        c -= 1
    elif dir & tileright:
        c += 1
    else:
        logic_log.error("bad direction % dir")
    return r, c

# Choose a target column for the next up/down direction at a bottom or top T
def get_next_round_robin(rr_table, x):
    target_col = rr_table[round_robin_index[x]]
    logic_log.debug("target: %d, indexes=%s, table=%s" % (target_col, str(round_robin_index), rr_table))
    round_robin_index[x] += 1
    if round_robin_index[x] >= vpath_num:
        round_robin_index[x] = 0
    return target_col

# Find target column when enemy reaches top or bottom
def get_target_col(i, c, allowed_vert):
    if allowed_vert & tileup:
        x = 1
        rr_table = round_robin_up
    else:
        x = 0
        rr_table = round_robin_down

    target_col = get_next_round_robin(rr_table, x)
    if target_col == c:
        # don't go back up the same column, skip to next one
        target_col = get_next_round_robin(rr_table, x)

    if target_col < c:
        current = tileleft
    else:
        current = tileright
    enemy_target_col[i] = target_col
    return current

# Move orbiter
def move_orbiter():
    r = enemy_row[0]
    c = enemy_col[0]
    current = enemy_dir[0]
    r, c = get_next_tile(r, c, current)
    enemy_row[0] = r
    enemy_col[0] = c
    allowed = get_allowed_dirs(r, c)

    if allowed & current:
        # Can continue the current direction, so keep on doing it

        logic_log.debug("orbiter: continuing %s" % str_dirs(current))
    else:
        # Can't continue, and because we must be at a corner, turn 90 degrees.
        # So, if we are moving vertically, go horizontally, and vice versa.

        if current & tilevert:
            current = allowed & tilehorz
        else:
            current = allowed & tilevert
        enemy_dir[0] = current


# Move enemy given the enemy index
def move_enemy(i):
    r = enemy_row[i]
    c = enemy_col[i]
    current = enemy_dir[i]
    r, c = get_next_tile(r, c, current)
    enemy_row[i] = r
    enemy_col[i] = c
    allowed = get_allowed_dirs(r, c)
    updown = enemy_updown[i]

    allowed_horz = allowed & tilehorz
    allowed_vert = allowed & tilevert
    if allowed_horz:
        # left or right is available, we must go that way, because that's the
        # Amidar(tm) way

        if allowed_horz == tilehorz:
            # *Both* left and right are available, which means we're either in
            # the middle of an box horz segment *or* at the top or bottom (but
            # not at a corner)

            if allowed_vert:
                # At a T junction at the top or bottom. What we do depends on
                # which direction we approached from

                if current & tilevert:
                    # approaching vertically means go L or R; choose direction
                    # based on a round robin so the enemy doesn't go back up
                    # the same path. Sets the target column for this enemy to
                    # be used when approaching the T horizontally
                    current = get_target_col(i, c, allowed_vert)

                    if allowed_vert & tileup:
                        logic_log.debug("enemy %d: at bot T, new dir %x, col=%d target=%d" % (i, current, c, enemy_target_col[i]))
                    else:
                        logic_log.debug("enemy %d: at top T, new dir %x, col=%d target=%d" % (i, current, c, enemy_target_col[i]))
                else:
                    # approaching horizontally, so check to see if this is the
                    # vpath to use

                    if enemy_target_col[i] == c:
                        # Going vertical! Reverse desired up/down direction
                        updown = allowed_vert
                        current = allowed_vert

                        if allowed_vert & tileup:
                            logic_log.debug("enemy %d: at bot T, reached target=%d, going up" % (i, c))
                        else:
                            logic_log.debug("enemy %d: at top T, reached target=%d, going down" % (i, c))
                    else:
                        # skip this vertical, keep on moving

                        if allowed_vert & tileup:
                            logic_log.debug("enemy %d: at bot T, col=%d target=%d; skipping" % (i, c, enemy_target_col[i]))
                        else:
                            logic_log.debug("enemy %d: at top T, col=%d target=%d; skipping" % (i, c, enemy_target_col[i]))

            else:
                # no up or down available, so keep marching on in the same
                # direction.
                logic_log.debug("enemy %d: no up/down, keep moving %s" % (i, str_dirs(current)))

        else:
            # only one horizontal dir is available

            if allowed_vert == tilevert:
                # At a left or right T junction...

                if current & tilevert:
                    # moving vertically. Have to take the horizontal path
                    current = allowed_horz
                    logic_log.debug("enemy %d: taking hpath, start moving %s" % (i, str_dirs(current)))
                else:
                    # moving horizontally into the T, forcing a vertical turn.
                    # Go back to preferred up/down direction
                    current = updown
                    logic_log.debug("enemy %d: hpath end, start moving %s" % (i, str_dirs(current)))
            else:
                # At a corner, because this tile has exactly one vertical and
                # one horizontal path.

                if current & tilevert:
                    # moving vertically, and because this is a corner, the
                    # target column must be set up
                    current = get_target_col(i, c, allowed_vert)

                    if allowed_horz & tileleft:
                        logic_log.debug("enemy %d: at right corner col=%d, heading left to target=%d" % (i, c, enemy_target_col[i]))
                    else:
                        logic_log.debug("enemy %d: at left corner col=%d, heading right to target=%d" % (i, c, enemy_target_col[i]))
                else:
                    # moving horizontally along the top or bottom. If we get
                    # here, the target column must also be this column
                    current = allowed_vert
                    updown = allowed_vert
                    if allowed_vert & tileup:
                        logic_log.debug("enemy %d: at bot corner col=%d with target %d, heading up" % (i, c, enemy_target_col[i]))
                    else:
                        logic_log.debug("enemy %d: at top corner col=%d with target=%d, heading down" % (i, c, enemy_target_col[i]))

    elif allowed_vert:
        # left or right is not available, so we must be in the middle of a
        # vpath segment. Only thing to do is keep moving
        logic_log.debug("enemy %d: keep moving %x" % (i, current))

    else:
        # only get here when moving into an illegal space
        logic_log.debug("enemy %d: illegal move to %d,%d" % (i, r, c))
        current = 0

    enemy_updown[i] = updown
    enemy_dir[i] = current

def move_player(i):
    r = player_row[i]
    c = player_col[i]
    allowed = get_allowed_dirs(r, c)
    current = player_dir[i]
    d = player_input_dir[i]
    pad.addstr(26, 0, "r=%d c=%d allowed=%s d=%s current=%s      " % (r, c, str_dirs(allowed), str_dirs(d), str_dirs(current)))
    if d:
        if allowed & d:
            # player wants to go in an allowed direction, so go!
            player_dir[i] = d
            r, c = get_next_tile(r, c, d)
            player_row[i] = r
            player_col[i] = c
        else:
            # player wants to go in an illegal direction. instead, continue in
            # direction that was last requested

            if allowed & current:
                r, c = get_next_tile(r, c, current)
                player_row[i] = r
                player_col[i] = c


##### Scoring routines

def check_dots(i):
    r = player_row[i]
    c = player_col[i]
    if has_dot(r, c):
        dot_eaten_row[i] = r
        dot_eaten_col[i] = c
        player_score[i] += dot_score

def update_background():
    for i in range(cur_players):
        if dot_eaten_col[i] < 128:
            # dot has been marked as being eaten, so deal with it. Somehow.

            r = dot_eaten_row[i]
            c = dot_eaten_col[i]
            addr = mazerow(r)
            addr[c] &= ~tiledot
            addr = screenrow(r)
            addr[c] &= ~tiledot

            # mark as completed
            dot_eaten_col[i] = 255

    update_score()
    paint_boxes()

def paint_boxes():
    x = 0
    pad.addstr(28, 0, "Checking box:")
    while x < 3 * 16:
        pad.addstr(28, 20 + x, "%d   " % x)
        if box_painting[x] > 0:
            c1 = box_painting[x]
            r1 = box_painting[x + 1]
            r2 = box_painting[x + 2]
            box_log.debug("Painting box line at %d,%d" % (r1, c1))
            pad.addstr(29, 0, "painting box line at %d,%d" % (r1, c1))
            addr = screenrow(r1)
            for i in range(box_width):
                addr[c1 + i] = ord("X")
            r1 += 1
            print "ROW", r1
            box_painting[x + 1] = r1
            if r1 >= r2:
                box_painting[x] = 0
        x += 3

def init_static_background():
    pad.addstr(p1scorerow, mazescorecol, "Player1")
    pad.addstr(p2scorerow, mazescorecol, "Player2")


def update_score():
    pad.addstr(p1scorerow+1, mazescorecol, " %05d" % player_score[0])
    pad.addstr(p2scorerow+1, mazescorecol, " %05d" % player_score[1])


##### User input routines

def read_user_input():
    if CURSES:
        read_curses()

def read_curses():
    global config_quit

    key = pad.getch()
    pad.addstr(25, 0, "key = %d   " % key)
    if key > 0:
        print "%d   " % key
    if key == ord('q'):
        print "QUIT!!!"
        config_quit = 1
    elif key == 27:
        print("QUIT!!!, but need to press ESC one more time for some reason")
        config_quit = 1

    if key == curses.KEY_UP:
        player_input_dir[0] = tileup
    elif key == curses.KEY_DOWN:
        player_input_dir[0] = tiledown
    elif key == curses.KEY_LEFT:
        player_input_dir[0] = tileleft
    elif key == curses.KEY_RIGHT:
        player_input_dir[0] = tileright
    else:
        player_input_dir[0] = 0


##### Game loop

def game_loop():
    global config_quit

    count = 0
    num_sprites_drawn = 0
    while True:
        game_log.debug("Turn %d" % count)
        read_user_input()
        if config_quit:
            return
        game_log.debug(chr(12))

        move_orbiter()  # always enemy #0
        for i in range(1, cur_enemies):
            move_enemy(i)

        for i in range(cur_players):
            move_player(i)
            check_dots(i)
            check_boxes(i)

        erase_sprites()
        update_background()
        draw_enemies()
        draw_players()
        show_screen()
        time.sleep(.02)

        count += 1


# Debugging stuff below here, things that won't get converted to 6502

def str_dirs(d):
    s = ""
    if d & tileleft:
        s += "L"
    if d & tileright:
        s += "R"
    if d & tileup:
        s += "U"
    if d & tiledown:
        s += "D"
    return s

def get_text_maze(m):
    lines = []
    for y in range(24):
        line = ""
        for x in range(33):
            tile = m[y][x]
            if tile < 32:
                line += tilechars[tile]
            else:
                line += chr(tile)
        lines.append(line)
    return lines

enemy_history = [[], [], [], [], [], [], []]
player_history = [[], [], [], []]

def print_maze(append=""):
    m = maze.copy()

    # Loop by time history instead of by enemy number so enemy #1 doesn't
    # always overwrite enemy #0's trail
    remain = True
    index = 0
    while remain:
        remain = False
        for i in range(cur_enemies):
            if index < len(enemy_history[i]):
                remain = True
                r, c = enemy_history[i][index]
                m[r][c] = ord("0") + i
        for i in range(cur_players):
            if index < len(player_history[i]):
                remain = True
                r, c = player_history[i][index]
                m[r][c] = ord("$") + i
        index += 1
    lines = get_text_maze(m)
    for i in range(24):
        print "%02d %s%s" % (i, lines[i], append)

def print_screen():
    print_maze("_______")


def show_screen():
    for r in range(24):
        for c in range(33):
            tile = screen[r, c]
            if tile < 16:
                val = curseschars[tile]
                pad.addch(r, c, val, curses.color_pair(1))
            elif tile < 32:
                val = curseschars[tile]
                pad.addch(r, c, val, curses.A_NORMAL)
            else:
                val = int(tile)
                pad.addch(r, c, val, curses.A_NORMAL)
    pad.refresh(0, 0, 0, 0, 29, 39)
    lines = get_text_maze(screen)
    for i in range(24):
        game_log.debug("%02d %s" % (i, lines[i]))




if __name__ == "__main__":
    #random.seed(31415)
    init()
