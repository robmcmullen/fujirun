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
logging.basicConfig(level=logging.WARNING)
init_log = logging.getLogger("init")
logic_log = logging.getLogger("logic")
logic_log.setLevel(logging.DEBUG)
draw_log = logging.getLogger("draw")
maze_log = logging.getLogger("maze")
box_log = logging.getLogger("maze")
game_log = logging.getLogger("game")
collision_log = logging.getLogger("collision")
collision_log.setLevel(logging.DEBUG)

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
    pad = curses.newpad(40, 80)
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
    while True:
        wipe_down()
        wipe_title()
        if config_quit:
            return


def read_menu_input():
    global config_quit, config_start

    read_user_input()
    if config_quit:
        sys.exit()
    if config_start:
        play_game()
    config_quit = 0
    config_start = 0


def clear_line(y, c):
    addr = screenrow(y)
    x = 0
    while x < SCREEN_COLS:
        addr[x] = c
        x += 1


def wipe_down():
    y = 0
    while y < SCREEN_ROWS:
        read_menu_input()
        clear_line(y, 0)
        show_screen()
        time.sleep(.02)
        y += 1


def wipe_title():
    y = 0
    while y < 10:
        read_menu_input()
        clear_line(y, 32)
        show_screen()
        time.sleep(.02)
        y += 1
    i = 0
    while i < len(title_text):
        read_menu_input()
        x = 0
        addr = screenrow(y)
        while x < SCREEN_COLS:
            addr[x] = ord(title_text[i][x])
            x += 1
        show_screen()
        time.sleep(.02)
        y += 1
        i += 1
    while y < SCREEN_ROWS:
        read_menu_input()
        clear_line(y, 32)
        show_screen()
        time.sleep(.02)
        y += 1
    i = TITLE_SCREEN_TIME
    while i >= 0:
        read_menu_input()
        show_screen()
        time.sleep(.02)
        i -= 1


title_text = [
    "              LINE 1                    ",
    "              LINE 2                    ",
    "              LINE 3                    ",
    "              LINE 4                    ",
]


def play_game():
    init_maze()
    screen[:,0:33] = maze

    show_screen()

    zp.level = 1
    zp.num_enemies = level_enemies[zp.level]
    zp.num_players = 2
    init_enemies()
    init_players()
    init_static_background()

    game_loop()

##### Memory usage

# Zero page

class ZeroPage(object):
    r = 0
    c = 0
    round_robin_index = [0, 0]  # down, up
    level = 0

    # enemy info
    num_enemies = 0
    current_enemy = 0  # index of enemy being processed

    # player info
    num_players = 1
    current_player = 0  # index of player currently being processed

    # sprite
    num_sprites_drawn = 0


    # box drawing workspace
    next_level_box = 0 
    box_col_save = 0
    box_row_save = 0


zp = ZeroPage()

# 2 byte addresses

maze = np.empty((24, 33), dtype=np.uint8)

screen = np.empty((24, 40), dtype=np.uint8)

TILE_DOWN = 0x1
TILE_UP = 0x2
TILE_RIGHT = 0x4
TILE_LEFT= 0x8
TILE_HORZ = TILE_LEFT | TILE_RIGHT
TILE_VERT = TILE_UP | TILE_DOWN
DIR_MASK = 0x0f
TILE_DOT = 0x10

LEFT_TILE = TILE_DOT | TILE_RIGHT
MIDDLE_TILE = TILE_DOT | TILE_LEFT | TILE_RIGHT
RIGHT_TILE = TILE_DOT | TILE_LEFT

VPATH_NUM = 6
if VPATH_NUM == 7:
    BOX_WIDTH = 4
else:
    VPATH_NUM = 6
    BOX_WIDTH = 5
VPATH_COL_SPACING = BOX_WIDTH + 1

vpath_cols = [1 + i * VPATH_COL_SPACING for i in range(VPATH_NUM)]

vpath_top_tile = [MIDDLE_TILE | TILE_DOWN] * VPATH_NUM
vpath_top_tile[0] = LEFT_TILE | TILE_DOWN
vpath_top_tile[-1] = RIGHT_TILE | TILE_DOWN

vpath_bot_tile = [MIDDLE_TILE | TILE_UP] * VPATH_NUM
vpath_bot_tile[0] = LEFT_TILE | TILE_UP
vpath_bot_tile[-1] = RIGHT_TILE | TILE_UP

if VPATH_NUM == 7:
    player_start_col = [
        [255, 255, 255, 255],
        [vpath_cols[3], 0, 0, 0],
        [vpath_cols[2], vpath_cols[4], 0, 0],
        [vpath_cols[1], vpath_cols[3], vpath_cols[5], 0],
        [vpath_cols[0], vpath_cols[2], vpath_cols[4], vpath_cols[6]],
    ]
else:
    player_start_col = [
        [255, 255, 255, 255],
        [(vpath_cols[2] + vpath_cols[3])//2, 0, 0, 0],
        [vpath_cols[1], vpath_cols[4], 0, 0],
        [vpath_cols[1], vpath_cols[3], vpath_cols[5], 0],
        [vpath_cols[0], vpath_cols[2], vpath_cols[4], vpath_cols[5]],
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
MAZE_TOP_ROW = 1
MAZE_BOT_ROW = 22
SCREEN_ROWS = 24

# Screen has cols 0 - 39
# cols 0 - 32 are the maze, of which 1 - 31 are actually used
#  0 and 32 are border tiles having the value zero
# cols 33 - 39 is the score area
MAZE_LEFT_COL = 1
MAZE_RIGHT_COL = 31
MAZE_SCORE_COL = 33
SCREEN_COLS = 40

# Orbiter goes around the outside border, but not through the maze
ORBITER_START_COL = MAZE_RIGHT_COL
ORBITER_START_ROW = (MAZE_TOP_ROW + MAZE_BOT_ROW) / 2


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

# Random number between 0 and VPATH_NUM (exclusive) used for column starting
# positions
def get_rand_col():
    return random.randint(0, VPATH_NUM - 1)

def get_rand_byte():
    return random.randint(0, 255)

# Get random starting columns for enemies by swapping elements in a list
# several times
def get_col_randomizer():
    r = list(vpath_cols)
    x = 10
    while x >= 0:
        i1 = get_rand_col()
        i2 = get_rand_col()
        old1 = r[i1]
        r[i1] = r[i2]
        r[i2] = old1
        x -= 1
    return r


###### Level creation functions

def clear_maze():
    y = 0
    while y < SCREEN_ROWS:
        addr = mazerow(y)
        x = 0
        while x < MAZE_SCORE_COL:
            addr[x] = 0
            x += 1
        y += 1
    init_boxes()

# Set all elements in a row to dot + left + right; only top and bottom
def setrow(row):
    addr = mazerow(row)
    x = MAZE_LEFT_COL
    while x <= MAZE_RIGHT_COL:
        addr[x] = TILE_DOT|TILE_LEFT|TILE_RIGHT
        x += 1

# Create all vpaths, using top/bot character from a list to handle both
# corners and T connections.
def setvpath(col):
    x = vpath_cols[col]
    y = MAZE_TOP_ROW
    addr = mazerow(y)
    addr[x] = vpath_top_tile[col]
    y += 1
    while y < MAZE_BOT_ROW:
        addr = mazerow(y)
        addr[x] = TILE_DOT|TILE_UP|TILE_DOWN
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
    y = MAZE_TOP_ROW
    start_box(y, x1_save)
    y += get_rand_spacing()
    while y < MAZE_BOT_ROW - 1:
        addr = mazerow(y)

        # If not working on the rightmost column, check to see there are
        # no cross-throughs.
        if col < VPATH_NUM - 1:
            tile = addr[x2]
            if tile & TILE_RIGHT:
                maze_log.debug("at y=%d on col %d, found same hpath level at col %d" % (y, col, col + 1))
                y -= 1
                addr = mazerow(y)
        add_box(y)

        x = x1_save
        addr[x] = TILE_DOT | TILE_UP | TILE_DOWN | TILE_RIGHT
        x += 1
        while x < x2:
            addr[x] = TILE_DOT | TILE_LEFT | TILE_RIGHT
            x += 1
        addr[x2] = TILE_DOT | TILE_UP | TILE_DOWN | TILE_LEFT
        y += get_rand_spacing()
    add_box(MAZE_BOT_ROW)


def init_maze():
    clear_maze()

    # Draw top and bottom; no intersections anywhere. Corners and T
    # intesections will be placed in setvpath
    setrow(MAZE_TOP_ROW)
    setrow(MAZE_BOT_ROW)

    # Draw all vpaths, including corners and top/bot T intersections
    counter = VPATH_NUM
    counter -= 1
    while counter >= 0:
        setvpath(counter)
        counter -= 1

    # Draw connectors between vpaths, starting with the rightmost column and
    # the one immediately left of it. This is performed 6 times because it
    # always needs a pair of columns to work with.
    counter = VPATH_NUM
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
# bottom row must look at BOX_WIDTH + 2 tiles, all the middle rows only have to
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

# for VPATH_NUM == 7:
# 01 X/----T----T----T----T----T----\X_______
# 02 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 03 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
# 04 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______

# for VPATH_NUM == 6:
# 01 X/-----T-----T-----T-----T-----\X_______
# 02 X|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|X_______
# 03 X|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|X_______
# 04 X|XXXXX|XXXXX|XXXXX+-----+XXXXX|X_______

NUM_LEVEL_BOX_PARAMS = 3
level_boxes = [0] * 10 * 6 * NUM_LEVEL_BOX_PARAMS

# Box painting will be in hires so this array will become a tracker for the
# hires display. It will need y address, y end address, x byte number. It's
# possible for up to 3 boxes to get triggered to start painting when collecting
# a dot, and because it will take multiple frames to paint a box there may be
# even more active at one time, so for safety use 16 as possible max.
#
# player #, xbyte, ytop, ybot
NUM_BOX_PAINTING_PARAMS = 4
box_painting = [0] * NUM_BOX_PAINTING_PARAMS * 16

def init_boxes():
    zp.next_level_box = 0

def start_box(r, c):
    zp.box_col_save = c
    zp.box_row_save = r

def add_box(r):
    i = zp.next_level_box
    level_boxes[i] = zp.box_col_save
    level_boxes[i + 1] = zp.box_row_save
    level_boxes[i + 2] = r
    zp.box_row_save = r
    zp.next_level_box += NUM_LEVEL_BOX_PARAMS

def finish_boxes():
    i = zp.next_level_box
    level_boxes[i] = 0xff

def check_boxes():
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
            dot = addr[c] | addr[c + 1] | addr[c + 2] | addr[c + 3] | addr[c + 4] | addr[c + 5] | addr[c + BOX_WIDTH + 1]

            r2 = level_boxes[x + 2]
            addr = mazerow(r2)
            dot |= addr[c] | addr[c + 1] | addr[c + 2] | addr[c + 3] | addr[c + 4] | addr[c + 5] | addr[c + BOX_WIDTH + 1]

            while r1 < r2:
                addr = mazerow(r1)
                dot |= addr[c] | addr[c + BOX_WIDTH + 1]
                r1 += 1

            if (dot & TILE_DOT) == 0:
                # No dots anywhere! Start painting
                mark_box_for_painting(r1_save, r2, c + 1)
                num_rows = r2 - r1_save
                player_score[zp.current_player] += num_rows * 100
                level_boxes[x] = 0  # Set flag so we don't check this box again

        x += 3

def mark_box_for_painting(r1, r2, c):
    box_log.debug("Marking box, player $%d @ %d,%d -> %d,%d" % (zp.current_player, r1, c, r2, c + BOX_WIDTH))
    x = 0
    while x < NUM_BOX_PAINTING_PARAMS * 16:
        if box_painting[x] == 0:
            box_painting[x] = c
            box_painting[x + 1] = r1
            box_painting[x + 2] = r2
            box_painting[x + 3] = zp.current_player
            break
        x += NUM_BOX_PAINTING_PARAMS
    pad.addstr(27, 0, "starting box, player @ %d %d,%d -> %d,%d" % (zp.current_player, r1, c, r2, c + BOX_WIDTH))


##### Gameplay storage

config_num_players = 1
config_quit = 0
config_start = 0

level = -1
level_enemies = [255, 4, 5, 6, 7, 8]  # level starts counting from 1, so dummy zeroth level info
level_speeds = [255, 200, 210, 220, 230, 240]  # increment of fractional pixel per game frame
player_score_row = [2, 7, 12, 17]

# Hardcoded, up to 8 enemies because there are max of 7 vpaths + 1 orbiter
# Enemy #0 is the orbiter
MAX_ENEMIES = 8
X_MIDPOINT = 3
X_TILEMAX = 7
Y_MIDPOINT = 3
Y_TILEMAX = 8
enemy_col = [0, 0, 0, 0, 0, 0, 0, 0]  # current tile column
enemy_xpixel = [0, 0, 0, 0, 0, 0, 0, 0]  # current pixel offset in col
enemy_xfrac = [0, 0, 0, 0, 0, 0, 0, 0]  # current fractional pixel
enemy_xspeed = [0, 0, 0, 0, 0, 0, 0, 0]  # current speed (affects fractional)
enemy_row = [0, 0, 0, 0, 0, 0, 0, 0]  # current tile row
enemy_ypixel = [0, 0, 0, 0, 0, 0, 0, 0]  # current pixel offset in row
enemy_yfrac = [0, 0, 0, 0, 0, 0, 0, 0]  # current fractional pixel
enemy_yspeed = [0, 0, 0, 0, 0, 0, 0, 0]  # current speed (affects fractional)
enemy_updown = [0, 0, 0, 0, 0, 0, 0, 0]  # preferred direction
enemy_dir = [0, 0, 0, 0, 0, 0, 0, 0]  # actual direction
enemy_target_col = [0, 0, 0, 0, 0, 0, 0, 0]  # target column at bot or top T

round_robin_up = [0, 0, 0, 0, 0, 0, 0]
round_robin_down = [0, 0, 0, 0, 0, 0, 0]

# Hardcoded, up to 4 players
MAX_PLAYERS = 4
STARTING_LIVES = 3
BONUS_LIFE = 10000
MAX_LIVES = 8
player_col = [0, 0, 0, 0]  # current tile col
player_xpixel = [0, 0, 0, 0]  # current pixel offset in col
player_xfrac = [0, 0, 0, 0]  # current fractional pixel
player_row = [0, 0, 0, 0]  # current tile row
player_ypixel = [0, 0, 0, 0]  # current pixel offset in row
player_yfrac = [0, 0, 0, 0]  # current fractional pixel
player_input_dir = [0, 0, 0, 0]  # current joystick input direction
player_dir = [0, 0, 0, 0]  # current movement direction
dot_eaten_row = [255, 255, 255, 255]  # dot eaten by player
dot_eaten_col = [255, 255, 255, 255]
player_score = [0, 0, 0, 0]
player_next_target_score = [0, 0, 0, 0]
player_lives = [0, 0, 0, 0]  # lives remaining
player_status = [0, 0, 0, 0]  # alive, exploding, dead, regenerating, ???
player_frame_counter = [0, 0, 0, 0]  # frame counter for sprite changes

PLAYER_DEAD = 0
PLAYER_ALIVE = 1
PLAYER_EXPLODING = 2
PLAYER_REGENERATING = 3
GAME_OVER = 4

# Scores

DOT_SCORE = 10
PAINT_SCORE_PER_LINE = 100

##### Gameplay initialization

def init_enemies():
    enemy_col[0] = ORBITER_START_COL
    enemy_row[0] = ORBITER_START_ROW
    enemy_dir[0] = TILE_UP
    zp.current_enemy = 1
    randcol = get_col_randomizer()
    while zp.current_enemy < zp.num_enemies:
        enemy_col[zp.current_enemy] = randcol[zp.current_enemy]
        enemy_xpixel[zp.current_enemy] = 3
        enemy_xfrac[zp.current_enemy] = 0
        enemy_row[zp.current_enemy] = MAZE_TOP_ROW
        enemy_ypixel[zp.current_enemy] = 4
        enemy_yfrac[zp.current_enemy] = 0
        enemy_updown[zp.current_enemy] = TILE_DOWN
        enemy_dir[zp.current_enemy] = TILE_DOWN
        enemy_target_col[zp.current_enemy] = 0  # Arbitrary, just need valid default
        set_speed(TILE_DOWN)
        zp.current_enemy += 1
    round_robin_up[:] = get_col_randomizer()
    round_robin_down[:] = get_col_randomizer()
    zp.round_robin_index[:] = [0, 0]

def init_player():
    addr = player_start_col[zp.num_players]
    player_col[zp.current_player] = addr[zp.current_player]
    player_xpixel[zp.current_player] = 3
    player_xfrac[zp.current_player] = 0
    player_row[zp.current_player] = MAZE_BOT_ROW
    player_ypixel[zp.current_player] = 3
    player_yfrac[zp.current_player] = 0
    player_input_dir[zp.current_player] = 0
    player_dir[zp.current_player] = 0
    player_status[zp.current_player] = PLAYER_ALIVE
    player_frame_counter[zp.current_player] = 0

def init_players():
    zp.current_player = 0
    while zp.current_player < zp.num_players:
        init_player()
        player_lives[zp.current_player] = STARTING_LIVES
        player_next_target_score[zp.current_player] = BONUS_LIFE
        zp.current_player += 1


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

exploding_char = ['*', '*', '@', '#', '\\', '-', '/', '|', '\\', '-', '/', '|', '\\', '-', '/', '|', '\\', '-', '/', '|']
EXPLODING_TIME = len(exploding_char) - 1
DEAD_TIME = 40
REGENERATING_TIME = 60
END_GAME_TIME = 100
TITLE_SCREEN_TIME = 100

# Erase sprites in reverse order that they're drawn to restore the background
# properly
def erase_sprites():
    while zp.num_sprites_drawn > 0:
        zp.num_sprites_drawn -= 1
        i = zp.num_sprites_drawn
        val = sprite_backing_store[i]
        r = last_sprite_y[i]
        addr = screenrow(r)
        c = last_sprite_byte[i]
        draw_log.debug("restoring background %d @ (%d,%d)" % (i, r, c))
        addr[c] = val

def save_backing_store(r, c, sprite):
    addr = mazerow(r)
    i = zp.num_sprites_drawn
    draw_log.debug("saving background %d @ (%d,%d)" % (i, r, c))
    last_sprite_byte[i] = c
    last_sprite_y[i] = r
    last_sprite_addr[i] = sprite
    sprite_backing_store[i] = addr[c]
    sprite_bytes_per_row[i] = 1
    sprite_num_rows[i] = 1
    zp.num_sprites_drawn += 1

def draw_sprite(r, c, sprite):
    if sprite is not None:
        save_backing_store(r, c, sprite)
        addr = screenrow(r)
        addr[c] = sprite

def draw_enemies():
    zp.current_enemy = 0
    while zp.current_enemy < zp.num_enemies:
        r = enemy_row[zp.current_enemy]
        c = enemy_col[zp.current_enemy]
        sprite = get_enemy_sprite()
        draw_sprite(r, c, sprite)

        #enemy_history[i].append((r, c))
        zp.current_enemy += 1

def draw_players():
    zp.current_player = 0
    while zp.current_player < zp.num_players:
        r = player_row[zp.current_player]
        c = player_col[zp.current_player]
        sprite = get_player_sprite()
        draw_sprite(r, c, sprite)

        #player_history[zp.current_player].append((r, c))
        zp.current_player += 1

def get_enemy_sprite():
    return ord("0") + zp.current_enemy

def get_player_sprite():
    a = player_status[zp.current_player]
    if a == PLAYER_ALIVE:
        c = ord("$") + zp.current_player
    elif a == PLAYER_EXPLODING:
        collision_log.debug("p%d: exploding, frame=%d" % (zp.current_player, player_frame_counter[zp.current_player]))
        c = ord(exploding_char[player_frame_counter[zp.current_player]])
        player_frame_counter[zp.current_player] -= 1
        if player_frame_counter[zp.current_player] <= 0:
            player_status[zp.current_player] = PLAYER_DEAD
            player_frame_counter[zp.current_player] = DEAD_TIME
    elif a == PLAYER_DEAD:
        collision_log.debug("p%d: dead, waiting=%d" % (zp.current_player, player_frame_counter[zp.current_player]))
        c = None
        player_frame_counter[zp.current_player] -= 1
        if player_frame_counter[zp.current_player] <= 0:
            player_lives[zp.current_player] -= 1
            if player_lives[zp.current_player] > 0:
                init_player()
                player_status[zp.current_player] = PLAYER_REGENERATING
                player_frame_counter[zp.current_player] = REGENERATING_TIME
            else:
                player_status[zp.current_player] = GAME_OVER
    elif a == PLAYER_REGENERATING:
        collision_log.debug("p%d: regenerating, frame=%d" % (zp.current_player, player_frame_counter[zp.current_player]))
        if player_frame_counter[zp.current_player] & 1:
            c = ord("$") + zp.current_player
        else:
            c = ord(" ")
        player_frame_counter[zp.current_player] -= 1
        if player_frame_counter[zp.current_player] <= 0:
            player_status[zp.current_player] = PLAYER_ALIVE
    else:
        c = None
    return c


##### Game logic

# Determine which of the 4 directions is allowed at the given row, col
def get_allowed_dirs(r, c):
    addr = mazerow(r)
    allowed = addr[c] & DIR_MASK
    return allowed

# See if current tile has a dot
def has_dot(r, c):
    addr = mazerow(r)
    return addr[c] & TILE_DOT

# clear a dot
def clear_dot(r, c):
    addr = mazerow(r)
    addr[c] &= ~TILE_DOT

# Determine the tile location given the direction of the actor's movement
def get_next_tile(r, c, dir):
    if dir & TILE_UP:
        r -= 1
    elif dir & TILE_DOWN:
        r += 1
    elif dir & TILE_LEFT:
        c -= 1
    elif dir & TILE_RIGHT:
        c += 1
    else:
        logic_log.error("bad direction % dir")
    return r, c

# Choose a target column for the next up/down direction at a bottom or top T
def get_next_round_robin(rr_table, x):
    target_col = rr_table[zp.round_robin_index[x]]
    logic_log.debug("target: %d, indexes=%s, table=%s" % (target_col, str(zp.round_robin_index), rr_table))
    zp.round_robin_index[x] += 1
    if zp.round_robin_index[x] >= VPATH_NUM:
        zp.round_robin_index[x] = 0
    return target_col

# Find target column when enemy reaches top or bottom
def get_target_col(c, allowed_vert):
    if allowed_vert & TILE_UP:
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
        current = TILE_LEFT
    else:
        current = TILE_RIGHT
    enemy_target_col[zp.current_enemy] = target_col
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

        if current & TILE_VERT:
            current = allowed & TILE_HORZ
        else:
            current = allowed & TILE_VERT
        enemy_dir[0] = current

def check_midpoint(current):
    # set up decision point flag to see if we have crossed the midpoint
    # after the movement
    if current & TILE_VERT:
        sub = enemy_ypixel[zp.current_enemy]
        return sub == Y_MIDPOINT
    else:
        sub = enemy_xpixel[zp.current_enemy]
        return sub == X_MIDPOINT

# Move enemy given the enemy index
def move_enemy():
    current = enemy_dir[zp.current_enemy]

    # check sub-pixel location to see if we've reached a decision point
    temp = check_midpoint(current)
    pixel_move(current)
    # check if moved to next tile. pixel fraction stays the same to keep
    # the speed consistent, only the pixel gets adjusted
    if enemy_xpixel[zp.current_enemy] < 0:
        enemy_col[zp.current_enemy] -= 1
        enemy_xpixel[zp.current_enemy] += X_TILEMAX
    elif enemy_xpixel[zp.current_enemy] >= X_TILEMAX:
        enemy_col[zp.current_enemy] += 1
        enemy_xpixel[zp.current_enemy] -= X_TILEMAX
    elif enemy_ypixel[zp.current_enemy] < 0:
        enemy_row[zp.current_enemy] -= 1
        enemy_ypixel[zp.current_enemy] += Y_TILEMAX
    elif enemy_ypixel[zp.current_enemy] >= Y_TILEMAX:
        enemy_row[zp.current_enemy] += 1
        enemy_ypixel[zp.current_enemy] -= Y_TILEMAX
    s = "#%d: tile=%d,%d pix=%d,%d frac=%d,%d  " % (zp.current_enemy, enemy_col[zp.current_enemy], enemy_row[zp.current_enemy], enemy_xpixel[zp.current_enemy], enemy_ypixel[zp.current_enemy], enemy_xfrac[zp.current_enemy], enemy_yfrac[zp.current_enemy])
    logic_log.debug(s)
    pad.addstr(0 + zp.current_enemy, 40, s)
    if not temp:
        if check_midpoint(current):
            # crossed the midpoint! Make a decision on the next allowed direction
            decide_direction()

def pixel_move(current):
    if current & TILE_UP:
        enemy_yfrac[zp.current_enemy] -= enemy_yspeed[zp.current_enemy]
        if enemy_yfrac[zp.current_enemy] < 0:
            enemy_ypixel[zp.current_enemy] -= 1
            enemy_yfrac[zp.current_enemy] += 256
    elif current & TILE_DOWN:
        enemy_yfrac[zp.current_enemy] += enemy_yspeed[zp.current_enemy]
        if enemy_yfrac[zp.current_enemy] > 255:
            enemy_ypixel[zp.current_enemy] += 1
            enemy_yfrac[zp.current_enemy] -= 256
    elif current & TILE_LEFT:
        enemy_xfrac[zp.current_enemy] -= enemy_xspeed[zp.current_enemy]
        if enemy_xfrac[zp.current_enemy] < 0:
            enemy_xpixel[zp.current_enemy] -= 1
            enemy_xfrac[zp.current_enemy] += 256
    elif current & TILE_RIGHT:
        enemy_xfrac[zp.current_enemy] += enemy_xspeed[zp.current_enemy]
        if enemy_xfrac[zp.current_enemy] > 255:
            enemy_xpixel[zp.current_enemy] += 1
            enemy_xfrac[zp.current_enemy] -= 256

def set_speed(current):
    if current & TILE_VERT:
        enemy_xspeed[zp.current_enemy] = 0
        enemy_yspeed[zp.current_enemy] = level_speeds[zp.level]
    else:
        enemy_xspeed[zp.current_enemy] = level_speeds[zp.level]
        enemy_yspeed[zp.current_enemy] = 0

def decide_direction():
    current = enemy_dir[zp.current_enemy]
    r = enemy_row[zp.current_enemy]
    c = enemy_col[zp.current_enemy]
#    r, c = get_next_tile(r, c, current)
    allowed = get_allowed_dirs(r, c)
    updown = enemy_updown[zp.current_enemy]

    allowed_horz = allowed & TILE_HORZ
    allowed_vert = allowed & TILE_VERT
    if allowed_horz:
        # left or right is available, we must go that way, because that's the
        # Amidar(tm) way

        if allowed_horz == TILE_HORZ:
            # *Both* left and right are available, which means we're either in
            # the middle of an box horz segment *or* at the top or bottom (but
            # not at a corner)

            if allowed_vert:
                # At a T junction at the top or bottom. What we do depends on
                # which direction we approached from

                if current & TILE_VERT:
                    # approaching vertically means go L or R; choose direction
                    # based on a round robin so the enemy doesn't go back up
                    # the same path. Sets the target column for this enemy to
                    # be used when approaching the T horizontally
                    current = get_target_col(c, allowed_vert)

                    if allowed_vert & TILE_UP:
                        logic_log.debug("enemy %d: at bot T, new dir %x, col=%d target=%d" % (zp.current_enemy, current, c, enemy_target_col[zp.current_enemy]))
                    else:
                        logic_log.debug("enemy %d: at top T, new dir %x, col=%d target=%d" % (zp.current_enemy, current, c, enemy_target_col[zp.current_enemy]))
                else:
                    # approaching horizontally, so check to see if this is the
                    # vpath to use

                    if enemy_target_col[zp.current_enemy] == c:
                        # Going vertical! Reverse desired up/down direction
                        updown = allowed_vert
                        current = allowed_vert

                        if allowed_vert & TILE_UP:
                            logic_log.debug("enemy %d: at bot T, reached target=%d, going up" % (zp.current_enemy, c))
                        else:
                            logic_log.debug("enemy %d: at top T, reached target=%d, going down" % (zp.current_enemy, c))
                    else:
                        # skip this vertical, keep on moving

                        if allowed_vert & TILE_UP:
                            logic_log.debug("enemy %d: at bot T, col=%d target=%d; skipping" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))
                        else:
                            logic_log.debug("enemy %d: at top T, col=%d target=%d; skipping" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))

            else:
                # no up or down available, so keep marching on in the same
                # direction.
                logic_log.debug("enemy %d: no up/down, keep moving %s" % (zp.current_enemy, str_dirs(current)))

        else:
            # only one horizontal dir is available

            if allowed_vert == TILE_VERT:
                # At a left or right T junction...

                if current & TILE_VERT:
                    # moving vertically. Have to take the horizontal path
                    current = allowed_horz
                    logic_log.debug("enemy %d: taking hpath, start moving %s" % (zp.current_enemy, str_dirs(current)))
                else:
                    # moving horizontally into the T, forcing a vertical turn.
                    # Go back to preferred up/down direction
                    current = updown
                    logic_log.debug("enemy %d: hpath end, start moving %s" % (zp.current_enemy, str_dirs(current)))
            else:
                # At a corner, because this tile has exactly one vertical and
                # one horizontal path.

                if current & TILE_VERT:
                    # moving vertically, and because this is a corner, the
                    # target column must be set up
                    current = get_target_col(c, allowed_vert)

                    if allowed_horz & TILE_LEFT:
                        logic_log.debug("enemy %d: at right corner col=%d, heading left to target=%d" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))
                    else:
                        logic_log.debug("enemy %d: at left corner col=%d, heading right to target=%d" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))
                else:
                    # moving horizontally along the top or bottom. If we get
                    # here, the target column must also be this column
                    current = allowed_vert
                    updown = allowed_vert
                    if allowed_vert & TILE_UP:
                        logic_log.debug("enemy %d: at bot corner col=%d with target %d, heading up" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))
                    else:
                        logic_log.debug("enemy %d: at top corner col=%d with target=%d, heading down" % (zp.current_enemy, c, enemy_target_col[zp.current_enemy]))

    elif allowed_vert:
        # left or right is not available, so we must be in the middle of a
        # vpath segment. Only thing to do is keep moving
        logic_log.debug("enemy %d: keep moving %x" % (zp.current_enemy, current))

    else:
        # only get here when moving into an illegal space
        logic_log.debug("enemy %d: illegal move to %d,%d" % (zp.current_enemy, r, c))
        current = 0

    enemy_updown[zp.current_enemy] = updown
    enemy_dir[zp.current_enemy] = current
    set_speed(current)

def move_player():
    r = player_row[zp.current_player]
    c = player_col[zp.current_player]
    allowed = get_allowed_dirs(r, c)
    current = player_dir[zp.current_player]
    d = player_input_dir[zp.current_player]
    pad.addstr(26, 0, "r=%d c=%d allowed=%s d=%s current=%s      " % (r, c, str_dirs(allowed), str_dirs(d), str_dirs(current)))
    if d:
        if allowed & d:
            # player wants to go in an allowed direction, so go!
            player_dir[zp.current_player] = d
            r, c = get_next_tile(r, c, d)
            player_row[zp.current_player] = r
            player_col[zp.current_player] = c
        else:
            # player wants to go in an illegal direction. instead, continue in
            # direction that was last requested

            if allowed & current:
                r, c = get_next_tile(r, c, current)
                player_row[zp.current_player] = r
                player_col[zp.current_player] = c


##### Collision detection

# Check possible collisions between the current player and any enemies
def check_collisions():
    zp.current_enemy = 0
    r = player_row[zp.current_player]
    c = player_col[zp.current_player]
    while zp.current_enemy < zp.num_enemies:
        # Will provide pac-man style bug where they could pass through each
        # other because it's only checking tiles
        if enemy_row[zp.current_enemy] == r and enemy_col[zp.current_enemy] == c:
            start_exploding()
            break
        zp.current_enemy += 1

def start_exploding():
    player_status[zp.current_player] = PLAYER_EXPLODING
    player_frame_counter[zp.current_player] = EXPLODING_TIME


##### Scoring routines

def check_dots():
    r = player_row[zp.current_player]
    c = player_col[zp.current_player]
    if has_dot(r, c):
        dot_eaten_row[zp.current_player] = r
        dot_eaten_col[zp.current_player] = c

        # Update maze here so we can check which player closed off a box
        addr = mazerow(r)
        addr[c] &= ~TILE_DOT

        player_score[zp.current_player] += DOT_SCORE

def update_background():
    zp.current_player = 0
    while zp.current_player < zp.num_players:
        if dot_eaten_col[zp.current_player] < 128:
            # Here we update the screen; note the maze has already been updated
            # but we don't change the background until now so sprites can
            # restore their saved backgrounds first.

            r = dot_eaten_row[zp.current_player]
            c = dot_eaten_col[zp.current_player]
            addr = screenrow(r)
            addr[c] &= ~TILE_DOT

            # mark as completed
            dot_eaten_col[zp.current_player] = 255
        update_score()
        zp.current_player += 1

    paint_boxes()

def paint_boxes():
    x = 0
    pad.addstr(28, 0, "Checking box:")
    while x < NUM_BOX_PAINTING_PARAMS * 16:
        pad.addstr(29, x, "%d   " % x)
        if box_painting[x] > 0:
            c1 = box_painting[x]
            r1 = box_painting[x + 1]
            r2 = box_painting[x + 2]
            i = box_painting[x + 3]
            box_log.debug("Painting box line, player %d at %d,%d" % (i, r1, c1))
            pad.addstr(30, 0, "painting box line at %d,%d" % (r1, c1))
            addr = screenrow(r1)
            for c in range(BOX_WIDTH):
                if i == 0:
                    addr[c1 + c] = ord("X")
                else:
                    addr[c1 + c] = ord(".")
            r1 += 1
            print "ROW", r1
            box_painting[x + 1] = r1
            if r1 >= r2:
                box_painting[x] = 0
        x += NUM_BOX_PAINTING_PARAMS

def init_static_background():
    zp.current_player = 0
    while zp.current_player < zp.num_players:
        row = player_score_row[zp.current_player]
        pad.addstr(row - 1, MAZE_SCORE_COL, "       ")
        pad.addstr(row, MAZE_SCORE_COL,     "Player%d" % (zp.current_player + 1))
        zp.current_player += 1

def show_lives(row, num):
    i = 1
    col = SCREEN_COLS
    while col > MAZE_SCORE_COL:
        col -= 1
        if i < num:
            c = "*"
        else:
            c = " "
        pad.addch(row, col, ord(c))
        i += 1

def update_score():
    row = player_score_row[zp.current_player]
    if player_status[zp.current_player] == GAME_OVER:
        pad.addstr(row - 1, MAZE_SCORE_COL, "GAME   ")
        pad.addstr(row, MAZE_SCORE_COL,     "   OVER")
    else:
        pad.addstr(row + 1, MAZE_SCORE_COL, " %06d" % player_score[zp.current_player])
        show_lives(row + 2, player_lives[zp.current_player])


##### User input routines

def read_user_input():
    if CURSES:
        read_curses()

def read_curses():
    global config_quit, config_start

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
        player_input_dir[0] = TILE_UP
    elif key == curses.KEY_DOWN:
        player_input_dir[0] = TILE_DOWN
    elif key == curses.KEY_LEFT:
        player_input_dir[0] = TILE_LEFT
    elif key == curses.KEY_RIGHT:
        player_input_dir[0] = TILE_RIGHT
    else:
        player_input_dir[0] = 0

    if key == ord(',') or key == ord('.'):
        player_input_dir[1] = TILE_UP
    elif key == ord('o'):
        player_input_dir[1] = TILE_DOWN
    elif key == ord('a'):
        player_input_dir[1] = TILE_LEFT
    elif key == ord('e'):
        player_input_dir[1] = TILE_RIGHT
    else:
        player_input_dir[1] = 0

    if key == ord('1'):
        config_start = 1


##### Game loop

def game_loop():
    global config_quit

    count = 0
    zp.num_sprites_drawn = 0
    countdown_time = END_GAME_TIME
    while True:
        game_log.debug("Turn %d" % count)
        read_user_input()
        if config_quit:
            return
        game_log.debug(chr(12))

        zp.current_enemy = 0
        move_orbiter()  # always enemy #0
        zp.current_enemy += 1
        while zp.current_enemy < zp.num_enemies:
            move_enemy()
            zp.current_enemy += 1

        zp.current_player = 0
        still_alive = 0
        while zp.current_player < zp.num_players:
            if player_status[zp.current_player] == PLAYER_REGENERATING:
                # If regenerating, change to alive if the player starts to move
                if player_input_dir[zp.current_player] > 0:
                    player_status[zp.current_player] = PLAYER_ALIVE
            if player_status[zp.current_player] == PLAYER_ALIVE:
                # only move and check collisions if alive
                move_player()
                check_collisions()
            if player_status[zp.current_player] == PLAYER_ALIVE:
                # only check for points if still alive
                check_dots()
                check_boxes()
            if player_status[zp.current_player] != GAME_OVER:
                still_alive += 1
            zp.current_player += 1

        if still_alive == 0:
            countdown_time -= 1
            if countdown_time <= 0:
                break

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
    if d & TILE_LEFT:
        s += "L"
    if d & TILE_RIGHT:
        s += "R"
    if d & TILE_UP:
        s += "U"
    if d & TILE_DOWN:
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
        for i in range(zp.num_enemies):
            if index < len(enemy_history[i]):
                remain = True
                r, c = enemy_history[i][index]
                m[r][c] = ord("0") + i
        for i in range(zp.num_players):
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
    import sys

    global config_start

    #random.seed(31415)
    if "-1" in sys.argv:
        config_start = 1
    init()
