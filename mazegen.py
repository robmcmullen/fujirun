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
#logic_log.setLevel(logging.DEBUG)
draw_log = logging.getLogger("draw")
maze_log = logging.getLogger("maze")
box_log = logging.getLogger("maze")
game_log = logging.getLogger("game")
collision_log = logging.getLogger("collision")
player_log = logging.getLogger("player")
player_log.setLevel(logging.DEBUG)

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

    #main()
    play_game()


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
    zp.last_enemy = level_enemies[zp.level] + FIRST_AMIDAR
    zp.num_players = 2
    init_actors()
    init_static_background()

    game_loop()

##### Memory usage

# Zero page

class ZeroPage(object):
    current_actor = 0  # index of sprite currently being processed
    current_dir = 0  # direction of actor
    r = 0
    c = 0

    round_robin_index = [0, 0]  # down, up
    level = 0

    sprite_addr = None

    # enemy info
    last_enemy = 0

    # player info
    num_players = 1

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

amidar_start_col = [0] * VPATH_NUM
round_robin_up = [0] * VPATH_NUM
round_robin_down = [0] * VPATH_NUM

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
def get_col_randomizer(r):
    r[:] = vpath_cols[:]
    x = 10
    while x >= 0:
        i1 = get_rand_col()
        i2 = get_rand_col()
        old1 = r[i1]
        r[i1] = r[i2]
        r[i2] = old1
        x -= 1


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
                player_score[zp.current_actor] += num_rows * 100
                level_boxes[x] = 0  # Set flag so we don't check this box again

        x += 3

def mark_box_for_painting(r1, r2, c):
    box_log.debug("Marking box, player $%d @ %d,%d -> %d,%d" % (zp.current_actor, r1, c, r2, c + BOX_WIDTH))
    x = 0
    while x < NUM_BOX_PAINTING_PARAMS * 16:
        if box_painting[x] == 0:
            box_painting[x] = c
            box_painting[x + 1] = r1
            box_painting[x + 2] = r2
            box_painting[x + 3] = zp.current_actor
            break
        x += NUM_BOX_PAINTING_PARAMS
    pad.addstr(27, 0, "starting box, player @ %d %d,%d -> %d,%d" % (zp.current_actor, r1, c, r2, c + BOX_WIDTH))


##### Gameplay storage

config_num_players = 1
config_quit = 0
config_start = 0

level = -1
level_enemies = [255, 4, 5, 6, 7, 8]  # level starts counting from 1, so dummy zeroth level info
level_speeds = [255, 200, 210, 220, 230, 240]  # increment of fractional pixel per game frame
player_score_row = [2, 7, 12, 17]

# sprites all use the same table. In the sample configuration, sprites 0 - 3
# are players, 4 and above are enemies. One is an orbiter enemy, the rest use
# amidar movement.
MAX_PLAYERS = 4
MAX_AMIDARS = VPATH_NUM + 1  # one enemy per vpath + one orbiter
MAX_ACTORS = MAX_PLAYERS + MAX_AMIDARS
FIRST_PLAYER = 0
FIRST_AMIDAR = MAX_PLAYERS
LAST_PLAYER = FIRST_AMIDAR - 1
LAST_AMIDAR = MAX_ACTORS - 1

STARTING_LIVES = 3
BONUS_LIFE = 10000
MAX_LIVES = 8

X_MIDPOINT = 3
X_TILEMAX = 7
Y_MIDPOINT = 3
Y_TILEMAX = 8

actor_col = [0] * MAX_ACTORS  # current tile column
actor_xpixel = [0] * MAX_ACTORS  # current pixel offset in col
actor_xfrac = [0] * MAX_ACTORS  # current fractional pixel
actor_xspeed = [0] * MAX_ACTORS  # current speed (affects fractional)
actor_row = [0] * MAX_ACTORS  # current tile row
actor_ypixel = [0] * MAX_ACTORS  # current pixel offset in row
actor_yfrac = [0] * MAX_ACTORS  # current fractional pixel
actor_yspeed = [0] * MAX_ACTORS  # current speed (affects fractional)
actor_updown = [0] * MAX_ACTORS  # preferred direction
actor_dir = [0] * MAX_ACTORS  # actual direction
actor_target_col = [0] * MAX_ACTORS  # target column at bot or top T
actor_status = [0] * MAX_ACTORS  # alive, exploding, dead, regenerating, invulnerable, ???
actor_frame_counter = [0] * MAX_ACTORS  # frame counter for sprite changes
actor_input_dir = [0] * MAX_ACTORS  # current joystick input direction

dot_eaten_row = [255, 255, 255, 255]  # dot eaten by player
dot_eaten_col = [255, 255, 255, 255]
player_score = [0, 0, 0, 0]
player_next_target_score = [0, 0, 0, 0]
player_lives = [0, 0, 0, 0]  # lives remaining

NOT_VISIBLE = 0
PLAYER_DEAD = 1
PLAYER_ALIVE = 2
PLAYER_EXPLODING = 3
PLAYER_REGENERATING = 4
AMIDAR_NORMAL = 5
ORBITER_NORMAL = 6
GAME_OVER = 255

# Scores

DOT_SCORE = 10
PAINT_SCORE_PER_LINE = 100

##### Gameplay initialization

def init_actor():
    # Common initialization params for all actors
    actor_col[zp.current_actor] = MAZE_LEFT_COL
    actor_xpixel[zp.current_actor] = 3
    actor_xfrac[zp.current_actor] = 0
    actor_xspeed[zp.current_actor] = 0
    actor_row[zp.current_actor] = MAZE_BOT_ROW
    actor_ypixel[zp.current_actor] = 3
    actor_yfrac[zp.current_actor] = 0
    actor_yspeed[zp.current_actor] = 0
    actor_input_dir[zp.current_actor] = 0
    actor_updown[zp.current_actor] = TILE_UP
    actor_dir[zp.current_actor] = TILE_UP
    actor_status[zp.current_actor] = NOT_VISIBLE
    actor_frame_counter[zp.current_actor] = 0
    actor_target_col[zp.current_actor] = 0
    actor_input_dir[zp.current_actor] = 0

def init_orbiter():
    init_actor()
    actor_col[zp.current_actor] = ORBITER_START_COL
    actor_row[zp.current_actor] = ORBITER_START_ROW
    actor_dir[zp.current_actor] = TILE_UP
    actor_status[zp.current_actor] = ORBITER_NORMAL
    #set_speed(TILE_UP)

def init_amidar():
    init_actor()
    amidar_index = zp.current_actor - FIRST_AMIDAR - 1  # orbiter always 1st enemy
    actor_col[zp.current_actor] = amidar_start_col[amidar_index]
    actor_row[zp.current_actor] = MAZE_TOP_ROW
    actor_ypixel[zp.current_actor] = 4
    actor_updown[zp.current_actor] = TILE_DOWN
    actor_dir[zp.current_actor] = TILE_DOWN
    actor_status[zp.current_actor] = AMIDAR_NORMAL
    #set_speed(TILE_DOWN)

def init_player():
    init_actor()
    addr = player_start_col[zp.num_players]
    actor_col[zp.current_actor] = addr[zp.current_actor]
    actor_row[zp.current_actor] = MAZE_BOT_ROW
    actor_status[zp.current_actor] = PLAYER_ALIVE
    set_speed(TILE_DOWN)

def init_actors():
    get_col_randomizer(amidar_start_col)
    get_col_randomizer(round_robin_up)
    get_col_randomizer(round_robin_down)
    zp.current_actor = 0
    while zp.current_actor <= zp.last_enemy:
        if zp.current_actor <= LAST_PLAYER:
            if zp.current_actor < zp.num_players:
                init_player()
                player_lives[zp.current_actor] = STARTING_LIVES
                player_next_target_score[zp.current_actor] = BONUS_LIFE
        else:
            if zp.current_actor == FIRST_AMIDAR:
                init_orbiter()
            else:
                init_amidar()
        zp.current_actor += 1
    zp.round_robin_index[:] = [0, 0]


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

def save_backing_store(r, c):
    addr = mazerow(r)
    i = zp.num_sprites_drawn
    draw_log.debug("saving background %d @ (%d,%d)" % (i, r, c))
    last_sprite_byte[i] = c
    last_sprite_y[i] = r
    last_sprite_addr[i] = zp.sprite_addr
    sprite_backing_store[i] = addr[c]
    sprite_bytes_per_row[i] = 1
    sprite_num_rows[i] = 1
    zp.num_sprites_drawn += 1

def draw_sprite(r, c):
    if zp.sprite_addr is not None:
        save_backing_store(r, c)
        addr = screenrow(r)
        addr[c] = zp.sprite_addr

def draw_actors():
    zp.current_actor = 0
    while zp.current_actor <= zp.last_enemy:
        r = actor_row[zp.current_actor]
        c = actor_col[zp.current_actor]
        get_sprite()
        draw_sprite(r, c)
        zp.current_actor += 1

def get_sprite():
    a = actor_status[zp.current_actor]
    if a == PLAYER_ALIVE:
        c = ord("$") + zp.current_actor
    elif a == PLAYER_EXPLODING:
        collision_log.debug("p%d: exploding, frame=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
        c = ord(exploding_char[actor_frame_counter[zp.current_actor]])
        actor_frame_counter[zp.current_actor] -= 1
        if actor_frame_counter[zp.current_actor] <= 0:
            actor_status[zp.current_actor] = PLAYER_DEAD
            actor_frame_counter[zp.current_actor] = DEAD_TIME
    elif a == PLAYER_DEAD:
        collision_log.debug("p%d: dead, waiting=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
        c = None
        actor_frame_counter[zp.current_actor] -= 1
        if actor_frame_counter[zp.current_actor] <= 0:
            player_lives[zp.current_actor] -= 1
            if player_lives[zp.current_actor] > 0:
                init_player()
                actor_status[zp.current_actor] = PLAYER_REGENERATING
                actor_frame_counter[zp.current_actor] = REGENERATING_TIME
            else:
                actor_status[zp.current_actor] = GAME_OVER
    elif a == PLAYER_REGENERATING:
        collision_log.debug("p%d: regenerating, frame=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
        if actor_frame_counter[zp.current_actor] & 1:
            c = ord("$") + zp.current_actor
        else:
            c = ord(" ")
        actor_frame_counter[zp.current_actor] -= 1
        if actor_frame_counter[zp.current_actor] <= 0:
            actor_status[zp.current_actor] = PLAYER_ALIVE
    elif a == AMIDAR_NORMAL or a == ORBITER_NORMAL:
        c = ord("0") + zp.current_actor - FIRST_AMIDAR
    else:
        c = None
    zp.sprite_addr = c


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
    actor_target_col[zp.current_actor] = target_col
    return current

def check_midpoint(current):
    # set up decision point flag to see if we have crossed the midpoint
    # after the movement
    if current & TILE_VERT:
        sub = actor_ypixel[zp.current_actor]
        return sub == Y_MIDPOINT
    else:
        sub = actor_xpixel[zp.current_actor]
        return sub == X_MIDPOINT

def move_tile():
    # check if moved to next tile. pixel fraction stays the same to keep
    # the speed consistent, only the pixel gets adjusted
    if actor_xpixel[zp.current_actor] < 0:
        actor_col[zp.current_actor] -= 1
        actor_xpixel[zp.current_actor] += X_TILEMAX
    elif actor_xpixel[zp.current_actor] >= X_TILEMAX:
        actor_col[zp.current_actor] += 1
        actor_xpixel[zp.current_actor] -= X_TILEMAX
    elif actor_ypixel[zp.current_actor] < 0:
        actor_row[zp.current_actor] -= 1
        actor_ypixel[zp.current_actor] += Y_TILEMAX
    elif actor_ypixel[zp.current_actor] >= Y_TILEMAX:
        actor_row[zp.current_actor] += 1
        actor_ypixel[zp.current_actor] -= Y_TILEMAX

# Move enemy given the enemy index
def move_enemy():
    current = actor_dir[zp.current_actor]

    # check sub-pixel location to see if we've reached a decision point
    temp = check_midpoint(current)
    pixel_move(current)
    move_tile()
    s = "#%d: tile=%d,%d pix=%d,%d frac=%d,%d  " % (zp.current_actor, actor_col[zp.current_actor], actor_row[zp.current_actor], actor_xpixel[zp.current_actor], actor_ypixel[zp.current_actor], actor_xfrac[zp.current_actor], actor_yfrac[zp.current_actor])
    logic_log.debug(s)
    pad.addstr(0 + zp.current_actor, 40, s)
    if not temp:
        if check_midpoint(current):
            # crossed the midpoint! Make a decision on the next allowed direction
            if actor_status[zp.current_actor] == ORBITER_NORMAL:
                decide_orbiter()
            else:
                decide_direction()

def pixel_move(current):
    if current & TILE_UP:
        actor_yfrac[zp.current_actor] -= actor_yspeed[zp.current_actor]
        if actor_yfrac[zp.current_actor] < 0:
            actor_ypixel[zp.current_actor] -= 1
            actor_yfrac[zp.current_actor] += 256
    elif current & TILE_DOWN:
        actor_yfrac[zp.current_actor] += actor_yspeed[zp.current_actor]
        if actor_yfrac[zp.current_actor] > 255:
            actor_ypixel[zp.current_actor] += 1
            actor_yfrac[zp.current_actor] -= 256
    elif current & TILE_LEFT:
        actor_xfrac[zp.current_actor] -= actor_xspeed[zp.current_actor]
        if actor_xfrac[zp.current_actor] < 0:
            actor_xpixel[zp.current_actor] -= 1
            actor_xfrac[zp.current_actor] += 256
    elif current & TILE_RIGHT:
        actor_xfrac[zp.current_actor] += actor_xspeed[zp.current_actor]
        if actor_xfrac[zp.current_actor] > 255:
            actor_xpixel[zp.current_actor] += 1
            actor_xfrac[zp.current_actor] -= 256

def set_speed(current):
    if current & TILE_VERT:
        actor_xspeed[zp.current_actor] = 0
        actor_yspeed[zp.current_actor] = level_speeds[zp.level]
    else:
        actor_xspeed[zp.current_actor] = level_speeds[zp.level]
        actor_yspeed[zp.current_actor] = 0

def decide_orbiter():
    current = actor_dir[zp.current_actor]
    r = actor_row[zp.current_actor]
    c = actor_col[zp.current_actor]
    allowed = get_allowed_dirs(r, c)

    if allowed & current:
        # Can continue the current direction, so keep on doing it

        logic_log.debug("orbiter %d: continuing %s" % (zp.current_actor, str_dirs(current)))
    else:
        # Can't continue, and because we must be at a corner, turn 90 degrees.
        # So, if we are moving vertically, go horizontally, and vice versa.

        if current & TILE_VERT:
            current = allowed & TILE_HORZ
        else:
            current = allowed & TILE_VERT
        actor_dir[zp.current_actor] = current
        set_speed(current)

def decide_direction():
    current = actor_dir[zp.current_actor]
    r = actor_row[zp.current_actor]
    c = actor_col[zp.current_actor]
    allowed = get_allowed_dirs(r, c)
    updown = actor_updown[zp.current_actor]

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
                        logic_log.debug("enemy %d: at bot T, new dir %x, col=%d target=%d" % (zp.current_actor, current, c, actor_target_col[zp.current_actor]))
                    else:
                        logic_log.debug("enemy %d: at top T, new dir %x, col=%d target=%d" % (zp.current_actor, current, c, actor_target_col[zp.current_actor]))
                else:
                    # approaching horizontally, so check to see if this is the
                    # vpath to use

                    if actor_target_col[zp.current_actor] == c:
                        # Going vertical! Reverse desired up/down direction
                        updown = allowed_vert
                        current = allowed_vert

                        if allowed_vert & TILE_UP:
                            logic_log.debug("enemy %d: at bot T, reached target=%d, going up" % (zp.current_actor, c))
                        else:
                            logic_log.debug("enemy %d: at top T, reached target=%d, going down" % (zp.current_actor, c))
                    else:
                        # skip this vertical, keep on moving

                        if allowed_vert & TILE_UP:
                            logic_log.debug("enemy %d: at bot T, col=%d target=%d; skipping" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
                        else:
                            logic_log.debug("enemy %d: at top T, col=%d target=%d; skipping" % (zp.current_actor, c, actor_target_col[zp.current_actor]))

            else:
                # no up or down available, so keep marching on in the same
                # direction.
                logic_log.debug("enemy %d: no up/down, keep moving %s" % (zp.current_actor, str_dirs(current)))

        else:
            # only one horizontal dir is available

            if allowed_vert == TILE_VERT:
                # At a left or right T junction...

                if current & TILE_VERT:
                    # moving vertically. Have to take the horizontal path
                    current = allowed_horz
                    logic_log.debug("enemy %d: taking hpath, start moving %s" % (zp.current_actor, str_dirs(current)))
                else:
                    # moving horizontally into the T, forcing a vertical turn.
                    # Go back to preferred up/down direction
                    current = updown
                    logic_log.debug("enemy %d: hpath end, start moving %s" % (zp.current_actor, str_dirs(current)))
            else:
                # At a corner, because this tile has exactly one vertical and
                # one horizontal path.

                if current & TILE_VERT:
                    # moving vertically, and because this is a corner, the
                    # target column must be set up
                    current = get_target_col(c, allowed_vert)

                    if allowed_horz & TILE_LEFT:
                        logic_log.debug("enemy %d: at right corner col=%d, heading left to target=%d" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
                    else:
                        logic_log.debug("enemy %d: at left corner col=%d, heading right to target=%d" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
                else:
                    # moving horizontally along the top or bottom. If we get
                    # here, the target column must also be this column
                    current = allowed_vert
                    updown = allowed_vert
                    if allowed_vert & TILE_UP:
                        logic_log.debug("enemy %d: at bot corner col=%d with target %d, heading up" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
                    else:
                        logic_log.debug("enemy %d: at top corner col=%d with target=%d, heading down" % (zp.current_actor, c, actor_target_col[zp.current_actor]))

    elif allowed_vert:
        # left or right is not available, so we must be in the middle of a
        # vpath segment. Only thing to do is keep moving
        logic_log.debug("enemy %d: keep moving %x" % (zp.current_actor, current))

    else:
        # only get here when moving into an illegal space
        logic_log.debug("enemy %d: illegal move to %d,%d" % (zp.current_actor, r, c))
        current = 0

    actor_updown[zp.current_actor] = updown
    actor_dir[zp.current_actor] = current
    set_speed(current)

def move_player():
    r = actor_row[zp.current_actor]
    c = actor_col[zp.current_actor]
    allowed = get_allowed_dirs(r, c)
    current = actor_dir[zp.current_actor]
    d = actor_input_dir[zp.current_actor]
    pad.addstr(26, 0, "r=%d c=%d allowed=%s d=%s current=%s      " % (r, c, str_dirs(allowed), str_dirs(d), str_dirs(current)))

    turn_zone = False
    x = actor_xpixel[zp.current_actor]
    if x in [2, 3, 4]:
        y = actor_ypixel[zp.current_actor]
        if y in [2, 3, 4]:
            turn_zone = True

    if d:
        if allowed & d:
            # player wants to go in an allowed direction
            player_log.debug("allowed, cur=%s, d=%s, turnzone=%s x=%d.%d y=%d.%d, r=%d c=%d" % (current, d, turn_zone, actor_xpixel[zp.current_actor], actor_xfrac[zp.current_actor], actor_ypixel[zp.current_actor], actor_yfrac[zp.current_actor], actor_col[zp.current_actor], actor_row[zp.current_actor]))
            # is desired direction a change in axes?
            if current & TILE_VERT: # current is vertical
                if d & TILE_HORZ: # dir change; wants horizontal
                    if turn_zone:
                        actor_ypixel[zp.current_actor] = 3
                        actor_yfrac[zp.current_actor] = 0
                        actor_dir[zp.current_actor] = d
                        set_speed(d)
                        pixel_move(d)
                    else: # wants horz but not in turn zone
                        if current & allowed:
                            player_log.debug("same")
                            actor_dir[zp.current_actor] = current
                            set_speed(current)
                            pixel_move(current)
                            move_tile()
                        else: # opposite of allowed; valid before turn zone
                            player_log.debug("opposite!")
                            actor_dir[zp.current_actor] = current
                            set_speed(current)
                            pixel_move(current)
                            move_tile()
                else: # current vertical, wants vertical, allowed
                    actor_dir[zp.current_actor] = d
                    set_speed(d)
                    pixel_move(d)
                    move_tile()
            else: # current is horizontal
                if d & TILE_VERT: # dir change; wants vertical
                    y = actor_ypixel[zp.current_actor]
                    if y in [2, 3, 4]:
                        actor_xpixel[zp.current_actor] = 3
                        actor_xfrac[zp.current_actor] = 0
                        actor_dir[zp.current_actor] = d
                        set_speed(d)
                        pixel_move(d)
                    else: # wants vert but not in turn zone
                        if current & allowed:
                            actor_dir[zp.current_actor] = current
                            set_speed(current)
                            pixel_move(current)
                            move_tile()
                        else: # opposite of allowed; valid before turn zone
                            player_log.debug("opposite!")
                            actor_dir[zp.current_actor] = current
                            set_speed(current)
                            pixel_move(current)
                            move_tile()
                else: # current horz, wants horz, allowed
                    actor_dir[zp.current_actor] = d
                    pixel_move(d)
                    move_tile()
        else:
            # player wants to go in an illegal direction. instead, continue in
            # direction that was last requested
            player_log.debug("illegal: allowed=%s cur=%s, d=%s, turnzone=%s x=%d.%d y=%d.%d, r=%d c=%d" % (allowed, current, d, turn_zone, actor_xpixel[zp.current_actor], actor_xfrac[zp.current_actor], actor_ypixel[zp.current_actor], actor_yfrac[zp.current_actor], actor_col[zp.current_actor], actor_row[zp.current_actor]))
            if allowed & current:
                player_log.debug("continuing current dir")
                actor_dir[zp.current_actor] = current
                set_speed(current)
                pixel_move(current)
                move_tile()
#                r, c = get_next_tile(r, c, current)
#                actor_row[zp.current_actor] = r
#                actor_col[zp.current_actor] = c


##### Collision detection

# Check possible collisions between the current player and any enemies
def check_collisions():
    r = actor_row[zp.current_actor]
    c = actor_col[zp.current_actor]
    enemy_index = FIRST_AMIDAR
    while enemy_index <= zp.last_enemy:
        # Will provide pac-man style bug where they could pass through each
        # other because it's only checking tiles
        if actor_row[enemy_index] == r and actor_col[enemy_index] == c:
            start_exploding()
            break
        enemy_index += 1

def start_exploding():
    actor_status[zp.current_actor] = PLAYER_EXPLODING
    actor_frame_counter[zp.current_actor] = EXPLODING_TIME


##### Scoring routines

def check_dots():
    r = actor_row[zp.current_actor]
    c = actor_col[zp.current_actor]
    if has_dot(r, c):
        dot_eaten_row[zp.current_actor] = r
        dot_eaten_col[zp.current_actor] = c

        # Update maze here so we can check which player closed off a box
        addr = mazerow(r)
        addr[c] &= ~TILE_DOT

        player_score[zp.current_actor] += DOT_SCORE

def update_background():
    zp.current_actor = 0
    while zp.current_actor < zp.num_players:
        if dot_eaten_col[zp.current_actor] < 128:
            # Here we update the screen; note the maze has already been updated
            # but we don't change the background until now so sprites can
            # restore their saved backgrounds first.

            r = dot_eaten_row[zp.current_actor]
            c = dot_eaten_col[zp.current_actor]
            addr = screenrow(r)
            addr[c] &= ~TILE_DOT

            # mark as completed
            dot_eaten_col[zp.current_actor] = 255
        update_score()
        zp.current_actor += 1

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
    zp.current_actor = 0
    while zp.current_actor < zp.num_players:
        row = player_score_row[zp.current_actor]
        pad.addstr(row - 1, MAZE_SCORE_COL, "       ")
        pad.addstr(row, MAZE_SCORE_COL,     "Player%d" % (zp.current_actor + 1))
        zp.current_actor += 1

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
    row = player_score_row[zp.current_actor]
    if actor_status[zp.current_actor] == GAME_OVER:
        pad.addstr(row - 1, MAZE_SCORE_COL, "GAME   ")
        pad.addstr(row, MAZE_SCORE_COL,     "   OVER")
    else:
        pad.addstr(row + 1, MAZE_SCORE_COL, " %06d" % player_score[zp.current_actor])
        show_lives(row + 2, player_lives[zp.current_actor])


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
        actor_input_dir[0] = TILE_UP
    elif key == curses.KEY_DOWN:
        actor_input_dir[0] = TILE_DOWN
    elif key == curses.KEY_LEFT:
        actor_input_dir[0] = TILE_LEFT
    elif key == curses.KEY_RIGHT:
        actor_input_dir[0] = TILE_RIGHT
    else:
        actor_input_dir[0] = 0

    if key == ord(',') or key == ord('.'):
        actor_input_dir[1] = TILE_UP
    elif key == ord('o'):
        actor_input_dir[1] = TILE_DOWN
    elif key == ord('a'):
        actor_input_dir[1] = TILE_LEFT
    elif key == ord('e'):
        actor_input_dir[1] = TILE_RIGHT
    else:
        actor_input_dir[1] = 0

    if key == ord('1'):
        config_start = 1


##### Game loop

def game_loop():
    global config_quit

    count = 0
    zp.num_sprites_drawn = 0
    countdown_time = END_GAME_TIME
    time_0 = time.time()
    while True:
        game_log.debug("Turn %d" % count)
        read_user_input()
        if config_quit:
            return
        game_log.debug(chr(12))

        zp.current_actor = FIRST_AMIDAR
        while zp.current_actor <= zp.last_enemy:
            move_enemy()
            zp.current_actor += 1

        zp.current_actor = 0
        still_alive = 0
        while zp.current_actor < zp.num_players:
            if actor_status[zp.current_actor] == PLAYER_REGENERATING:
                # If regenerating, change to alive if the player starts to move
                if actor_input_dir[zp.current_actor] > 0:
                    actor_status[zp.current_actor] = PLAYER_ALIVE
            if actor_status[zp.current_actor] == PLAYER_ALIVE:
                # only move and check collisions if alive
                move_player()
                check_collisions()
            if actor_status[zp.current_actor] == PLAYER_ALIVE:
                # only check for points if still alive
                check_dots()
                check_boxes()
            if actor_status[zp.current_actor] != GAME_OVER:
                still_alive += 1
            zp.current_actor += 1

        if still_alive == 0:
            countdown_time -= 1
            if countdown_time <= 0:
                break

        erase_sprites()
        update_background()
        draw_actors()
        show_screen()
        #time.sleep(.01)
        if count % 50 == 0:
            pad.addstr(20, MAZE_SCORE_COL, "%f" % (time.time() - time_0))

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

actor_history = [[], [], [], [], [], [], []]
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
            if index < len(actor_history[i]):
                remain = True
                r, c = actor_history[i][index]
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
