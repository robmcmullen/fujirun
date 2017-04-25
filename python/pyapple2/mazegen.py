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

import numpy as np


##### Game loader

def main():
    global level, cur_enemies, cur_players

    init_maze()
    print_maze()

    level = 1
    cur_enemies = level_enemies[level]
    cur_players = 1
    init_enemies()
    init_players()

    game_loop()
    draw_enemies()
    draw_players()
    print_maze()

##### Memory usage

# Zero page

r = 0
c = 0
round_robin_index = [0, 0]  # down, up

# 2 byte addresses

maze = np.empty((24, 33), dtype=np.uint8)

tiledown = 0x1
tileup = 0x2
tileright = 0x4
tileleft= 0x8
tilehorz = tileleft | tileright
tilevert = tileup | tiledown
dir_mask = 0x0f
tiledot = 0x10

vpath_num = 7
vpath_cols = [1, 6, 11, 16, 21, 26, 31]
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
screencols = 40


##### Utility functions

# Returns address of tile in col 0 of row y
def getrow(y):
    return maze[y]

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
        addr = getrow(y)
        x = 0
        while x < mazescorecol:
            addr[x] = 0
            x += 1
        y += 1

def setrow(row):
    addr = getrow(row)
    x = mazeleftcol
    while x <= mazerightcol:
        addr[x] = tiledot|tileleft|tileright
        x += 1

def setvpath(col):
    x = vpath_cols[col]
    y = mazetoprow
    addr = getrow(y)
    addr[x] = vpath_top_tile[col]
    y += 1
    while y < mazebotrow:
        addr = getrow(y)
        addr[x] = tiledot|tileup|tiledown
        y += 1
    addr = getrow(y)
    addr[x] = vpath_bot_tile[col]


# Using col and col - 1, find hpaths such that there are no hpaths that meet at
# the same row in the column col + 1, preventing any "+" intersections (which
# is not legal ghost legs)
def sethpath(col):
    x1_save = vpath_cols[col - 1]
    x2 = vpath_cols[col]
    y = mazetoprow + 1  # first blank row below the top row
    y += get_rand_spacing()
    while y < mazebotrow - 1:
        addr = getrow(y)

        # If not working on the rightmost column, check to see there are
        # no cross-throughs.
        if col < vpath_num - 1:
            tile = addr[x2]
            if tile & tileright:
                print "at y=%d on col %d, found same hpath level at col %d" % (y, col, col + 1)
                y -= 1
                addr = getrow(y)

        x = x1_save
        addr[x] = tiledot|tileup|tiledown|tileright
        x += 1
        while x < x2:
            addr[x] = tiledot|tileleft|tileright
            x += 1
        addr[x2] = tiledot|tileup|tiledown|tileleft
        y += get_rand_spacing()

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


##### Gameplay storage

level = -1
level_enemies = [255, 3, 4, 5, 6, 7]  # starts counting from 1, so dummy zeroth level info
level_speeds = [255, 0, 0, 0, 0, 0]  # probably needs to be 16 bit
level_start_col = [
    [255, 255, 255, 255],
    [3, 0, 0, 0],
    [2, 4, 0, 0],
    [1, 3, 5, 0],
    [0, 2, 4, 6],
]

# Hardcoded, up to 8 enemies because there are max of 7 vpaths + 1 orbiter
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


##### Gameplay initialization

def init_enemies():
    x = 0
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

def draw_enemies():
    i = 0
    while i < cur_enemies:
        r = enemy_row[i]
        c = enemy_col[i]
        enemy_history[i].append((r, c))
        i += 1

def draw_players():
    i = 0
    while i < cur_players:
        r = player_row[i]
        c = player_col[i]
        player_history[i].append((r, c))
        i += 1


##### Game logic

# Determine which of the 4 directions is allowed at the given row, col
def get_allowed_dirs(r, c):
    addr = getrow(r)
    allowed = addr[c] & dir_mask
    return allowed

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
        print("bad direction % dir")
    return r, c

# Choose a target column for the next up/down direction at a bottom or top T
def get_next_round_robin(rr_table, x):
    target_col = rr_table[round_robin_index[x]]
    print "target: %d, indexes=%s, table=%s" % (target_col, str(round_robin_index), rr_table)
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
                        print("enemy %d: at bot T, new dir %x, col=%d target=%d" % (i, current, c, enemy_target_col[i]))
                    else:
                        print("enemy %d: at top T, new dir %x, col=%d target=%d" % (i, current, c, enemy_target_col[i]))
                else:
                    # approaching horizontally, so check to see if this is the
                    # vpath to use

                    if enemy_target_col[i] == c:
                        # Going vertical! Reverse desired up/down direction
                        updown = allowed_vert
                        current = allowed_vert

                        if allowed_vert & tileup:
                            print("enemy %d: at bot T, reached target=%d, going up" % (i, c))
                        else:
                            print("enemy %d: at top T, reached target=%d, going down" % (i, c))
                    else:
                        # skip this vertical, keep on moving

                        if allowed_vert & tileup:
                            print("enemy %d: at bot T, col=%d target=%d; skipping" % (i, c, enemy_target_col[i]))
                        else:
                            print("enemy %d: at top T, col=%d target=%d; skipping" % (i, c, enemy_target_col[i]))

            else:
                # no up or down available, so keep marching on in the same
                # direction.
                print("enemy %d: no up/down, keep moving %x" % (i, current))

        else:
            # only one horizontal dir is available

            if allowed_vert == tilevert:
                # At a left or right T junction...

                if current & tilevert:
                    # moving vertically. Have to take the horizontal path
                    current = allowed_horz
                    print("enemy %d: taking hpath, start moving %x" % (i, current))
                else:
                    # moving horizontally into the T, forcing a vertical turn.
                    # Go back to preferred up/down direction
                    current = updown
                    print("enemy %d: hpath end, start moving %x" % (i, current))
            else:
                # At a corner, because this tile has exactly one vertical and
                # one horizontal path.

                if current & tilevert:
                    # moving vertically, and because this is a corner, the
                    # target column must be set up
                    current = get_target_col(i, c, allowed_vert)

                    if allowed_horz & tileleft:
                        print("enemy %d: at right corner col=%d, heading left to target=%d" % (i, c, enemy_target_col[i]))
                    else:
                        print("enemy %d: at left corner col=%d, heading right to target=%d" % (i, c, enemy_target_col[i]))
                else:
                    # moving horizontally along the top or bottom. If we get
                    # here, the target column must also be this column
                    current = allowed_vert
                    updown = allowed_vert
                    if allowed_vert & tileup:
                        print("enemy %d: at bot corner col=%d with target %d, heading up" % (i, c, enemy_target_col[i]))
                    else:
                        print("enemy %d: at top corner col=%d with target=%d, heading down" % (i, c, enemy_target_col[i]))

    elif allowed_vert:
        # left or right is not available, so we must be in the middle of a
        # vpath segment. Only thing to do is keep moving
        print("enemy %d: keep moving %x" % (i, current))

    else:
        # only get here when moving into an illegal space
        print("enemy %d: illegal move to %d,%d" % (i, r, c))
        current = 0

    enemy_updown[i] = updown
    enemy_dir[i] = current

def move_player(i):
    pass


##### Game loop

def game_loop():
    count = 0
    while count < 100:
        print("Turn %d" % count)
        draw_enemies()
        draw_players()
        print_maze()
        time.sleep(.05)
        print(chr(12))

        for i in range(cur_enemies):
            move_enemy(i)

        for i in range(cur_players):
            move_player(i)

        count += 1


# Debugging stuff below here, things that won't get converted to 6502

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





if __name__ == "__main__":
    #random.seed(31415)
    main()
