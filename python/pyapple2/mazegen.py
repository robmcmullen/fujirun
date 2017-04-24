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

import random

import numpy as np

maze = np.empty((24, 33), dtype=np.uint8)

tiledown = 0x1
tileup = 0x2
tileright = 0x4
tileleft= 0x8
tiledot = 0x10

# up/down/left/right would be 0xf, but this is not legal for ghost legs
tilechars = [
    "X",  # illegal
    "X",
    "X",
    "|",  # 3: up/down
    "X",
    "/",  # 5: down/right
    "\\",  # 6: up/right
    "+",  # 7: up/down/right
    "X",
    "\\",  # 9: left/down
    "/",  # 10: left/up
    "+",  # 11: left/up/down
    "-",  # 12: left/right
    "T",  # 13: left/right/down
    "^",  # 14: left/right/up
    "X",

    # And same again, with dots
    "X",  # illegal
    "X",
    "X",
    "|",  # 3: up/down
    "X",
    "/",  # 5: down/right
    "\\",  # 6: up/right
    "+",  # 7: up/down/right
    "X",
    "\\",  # 9: left/down
    "/",  # 10: left/up
    "+",  # 11: left/up/down
    "-",  # 12: left/right
    "T",  # 13: left/right/down
    "^",  # 14: left/right/up
    "X",
]

# Screen has rows 0 - 23
# Maze is rows 1 - 22
mazetoprow = 1
mazebotrow = 22

# Screen has cols 0 - 39
# cols 0 - 32 are the maze, of which 1 - 31 are actually used
#  0 and 32 are border tiles having the value zero
# cols 33 - 39 is the score area
mazeleftcol = 1
mazerightcol = 31
mazescorecol = 33

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

def getrow(y):
    return maze[y]

def clear_maze():
    y = 0
    while y < 24:
        addr = getrow(y)
        x = 0
        while x < mazescorecol:
            addr[x] = 0
            x += 1
        y += 1

def setrow(addr, x):
    while x < 31:
        addr[x] = tiledot|tileleft|tileright
        x += 1

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


# Return a random number between 3 and 6 (inclusive) to represent next row that
# contains an hpath. 3 is the minimum number so that if necessary, the last
# spacing on the bottom can be adjusted upward by 1 to guarantee no cross-
# throughs
def get_rand_spacing():
    return random.randint(3, 6)

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
    setrow(mazetoprow)
    setrow(mazebotrow)

    counter = vpath_num
    counter -= 1
    while counter >= 0:
        setvpath(counter)
        counter -= 1

    counter = vpath_num
    counter -= 1
    while counter > 0:  # note >, not >=
        sethpath(counter)
        counter -= 1


def get_text_maze():
    lines = []
    for y in range(24):
        line = ""
        for x in range(33):
            tile = maze[y][x]
            line += tilechars[tile]
        lines.append(line)
    return lines

def print_maze():
    lines = get_text_maze()
    for i in range(24):
        print "%02d %s" % (i, lines[i])

def print_screen():
    lines = get_text_maze()
    for i in range(24):
        print "%02d %s_______" % (i, lines[i])

def main():
    init_maze()
    print_maze()



if __name__ == "__main__":
    #random.seed(31415)
    main()
