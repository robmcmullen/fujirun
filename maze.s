; defines

TILE_DOWN = $1
TILE_UP = $2
TILE_RIGHT = $4
TILE_LEFT= $8
TILE_HORZ = TILE_LEFT|TILE_RIGHT
TILE_VERT = TILE_UP|TILE_DOWN
DIR_MASK = $0f
TILE_DOT = $10
CLEAR_TILE_DOT = %11101111

LEFT_TILE = TILE_DOT|TILE_RIGHT
MIDDLE_TILE = TILE_DOT|TILE_LEFT|TILE_RIGHT
RIGHT_TILE = TILE_DOT|TILE_LEFT

VPATH_NUM = 6
BOX_WIDTH = 5
VPATH_COL_SPACING = BOX_WIDTH + 1

NUM_BOX_PAINTING_PARAMS = 4
MAX_BOX_PAINTING = NUM_BOX_PAINTING_PARAMS * 16


; storage

vpath_cols .byte 1, 7, 13, 19, 25, 31
vpath_top_tile .byte LEFT_TILE|TILE_DOWN
    .byte MIDDLE_TILE|TILE_DOWN
    .byte MIDDLE_TILE|TILE_DOWN
    .byte MIDDLE_TILE|TILE_DOWN
    .byte MIDDLE_TILE|TILE_DOWN
    .byte RIGHT_TILE|TILE_DOWN
vpath_bot_tile .byte LEFT_TILE|TILE_UP
    .byte MIDDLE_TILE|TILE_UP
    .byte MIDDLE_TILE|TILE_UP
    .byte MIDDLE_TILE|TILE_UP
    .byte MIDDLE_TILE|TILE_UP
    .byte RIGHT_TILE|TILE_UP
player_start_col .byte 255,255,255,255, ; zero players!
    .byte 16, 0, 0, 0,
    .byte 7, 25, 0, 0,
    .byte 7, 19, 31, 0,
    .byte 1, 13, 25, 31,

MAZE_TOP_ROW = 1
MAZE_BOT_ROW = 22
SCREEN_ROWS = 24

;# Screen has cols 0 - 39
;# cols 0 - 32 are the maze, of which 1 - 31 are actually used
;#  0 and 32 are border tiles having the value zero
;# cols 33 - 39 is the score area
MAZE_LEFT_COL = 1
MAZE_RIGHT_COL = 31
MAZE_SCORE_COL = 33
SCREEN_COLS = 40

;# Orbiter goes around the outside border, but not through the maze
ORBITER_START_COL = MAZE_RIGHT_COL
ORBITER_START_ROW = (MAZE_TOP_ROW + MAZE_BOT_ROW) / 2

;# Returns address of tile in col 0 of row y
;def mazerow(y):
;    return maze[y]

; row in Y
mazerow lda textrows_l,y
    sta mazeaddr
    lda textrows_h,y
    sta mazeaddr+1
    rts

;###### Level creation functions

;def clear_maze():
;    y = 0
;    while y < SCREEN_ROWS:
;        addr = mazerow(y)
;        x = 0
;        while x < MAZE_SCORE_COL:
;            addr[x] = 0
;            x += 1
;        y += 1
;    init_boxes()
clear_maze nop
    ldx #MAZE_LEFT_COL
    lda #0
?1  jsr text_put_col
    inx
    cpx #MAZE_RIGHT_COL
    bcc ?1
    beq ?1
    jmp init_boxes

;# Set all elements in a row to dot + left + right; only top and bottom
;def setrow(row):
;    addr = mazerow(row)
;    x = MAZE_LEFT_COL
;    while x <= MAZE_RIGHT_COL:
;        addr[x] = TILE_DOT|TILE_LEFT|TILE_RIGHT
;        x += 1

; row in Y, clobbered
setrow jsr mazerow
    lda #MIDDLE_TILE
    ldy #MAZE_RIGHT_COL
?1  sta (mazeaddr),y
    dey
    cpy #MAZE_LEFT_COL
    bcs ?1
    rts

;
;# Create all vpaths, using top/bot character from a list to handle both
;# corners and T connections.
;def setvpath(col):
;    x = vpath_cols[col]
;    y = MAZE_TOP_ROW
;    addr = mazerow(y)
;    addr[x] = vpath_top_tile[col]
;    y += 1
;    while y < MAZE_BOT_ROW:
;        addr = mazerow(y)
;        addr[x] = TILE_DOT|TILE_UP|TILE_DOWN
;        y += 1
;    addr = mazerow(y)
;    addr[x] = vpath_bot_tile[col]

; vpath number in X, AY clobbered
setvpath lda vpath_cols,x
    tay
    lda #TILE_DOT|TILE_VERT
    sta $0500,y ; row 2
    sta $0580,y ; row 3
    sta $0600,y ; row 4
    sta $0680,y ; row 5
    sta $0700,y ; row 6
    sta $0780,y ; row 7
    sta $0428,y ; row 8
    sta $04a8,y ; row 9
    sta $0528,y ; row 10
    sta $05a8,y ; row 11
    sta $0628,y ; row 12
    sta $06a8,y ; row 13
    sta $0728,y ; row 14
    sta $07a8,y ; row 15
    sta $0450,y ; row 16
    sta $04d0,y ; row 17
    sta $0550,y ; row 18
    sta $05d0,y ; row 19
    sta $0650,y ; row 20
    sta $06d0,y ; row 21
    lda vpath_top_tile,x
    sta $0480,y ; row 1
    lda vpath_bot_tile,x
    sta $0750,y ; row 22
    rts

;
;
;# Create hpaths such that there are no hpaths that meet at the same row in
;# adjacent columns (cross-throughs are not allowed in ghost legs). Starts at
;# the rightmost vpath and moves left using the rightmost vpath as the input to
;# this function and building hpaths between it and the vpath to the left. The
;# first time this routine is called there won't be any existing columns to
;# compare to, otherwise if a tile on the left vpath has a rightward pointing
;# hpath, move up one and draw the hpath there. This works because the minimum
;# hpath vertical positioning leaves 2 empty rows, so moving up by one still
;# leaves 1 empty row.
;def sethpath(col):
x1_save .byte 0
x2 .byte 0
col_save .byte 0
row_save .byte 0

; X is col, clobbers everything
sethpath PUSHAXY
    stx col_save

;    x1_save = vpath_cols[col - 1]
    dex
    lda vpath_cols,x
    sta x1_save

;    x2 = vpath_cols[col]
    inx
    lda vpath_cols,x
    sta x2

;    y = MAZE_TOP_ROW
    ldy #MAZE_TOP_ROW
    sty row_save

;    start_box(y, x1_save)
    ldx x1_save
    jsr start_box

;    y += get_rand_spacing()
    jsr get_rand_spacing
    sta scratch_row
    tya
    clc
    adc scratch_row
    tay
    sty row_save

;    while y < MAZE_BOT_ROW - 1:
;        addr = mazerow(y)
?1  ldy row_save
    jsr mazerow

;        # If not working on the rightmost column, check to see there are
;        # no cross-throughs.
;        if col < VPATH_NUM - 1:
    lda col_save
    cmp #VPATH_NUM-1
    bcs ?hpath_ok

;            tile = addr[x2]
    ldy x2
    lda (mazeaddr),y

;            if tile & TILE_RIGHT:
    and #TILE_RIGHT
    beq ?hpath_ok

;                maze_log.debug("at y=%d on col %d, found same hpath level at col %d" % (y, col, col + 1))
;                y -= 1
    dec row_save
;                addr = mazerow(y)
    ldy row_save
    jsr mazerow

?hpath_ok
;        add_box(y)
    ldy row_save
    jsr add_box

;
;        x = x1_save
    ldy x1_save

;        addr[x] = TILE_DOT|TILE_UP|TILE_DOWN|TILE_RIGHT
    lda #TILE_DOT|TILE_UP|TILE_DOWN|TILE_RIGHT
    sta (mazeaddr),y

    lda #TILE_DOT|TILE_LEFT|TILE_RIGHT
;        x += 1
    iny

;        while x < x2:
?2
;            addr[x] = TILE_DOT|TILE_LEFT|TILE_RIGHT
    sta (mazeaddr),y

;            x += 1
    iny
    cpy x2
    bcc ?2
;        addr[x2] = TILE_DOT|TILE_UP|TILE_DOWN|TILE_LEFT
    lda #TILE_DOT|TILE_UP|TILE_DOWN|TILE_LEFT
    sta (mazeaddr),y

;        y += get_rand_spacing()
    jsr get_rand_spacing
    clc
    adc row_save
    sta row_save
    cmp #MAZE_BOT_ROW-1
    bcc ?1

;    add_box(MAZE_BOT_ROW)
    ldy #MAZE_BOT_ROW
    jsr add_box

    PULLAXY
    rts



;
;def init_maze():
;    clear_maze()
;
;    # Draw top and bottom; no intersections anywhere. Corners and T
;    # intesections will be placed in setvpath
;    setrow(MAZE_TOP_ROW)
;    setrow(MAZE_BOT_ROW)
;
;    # Draw all vpaths, including corners and top/bot T intersections
;    counter = VPATH_NUM
;    counter -= 1
;    while counter >= 0:
;        setvpath(counter)
;        counter -= 1
;
;    # Draw connectors between vpaths, starting with the rightmost column and
;    # the one immediately left of it. This is performed 6 times because it
;    # always needs a pair of columns to work with.
;    counter = VPATH_NUM
;    counter -= 1
;    while counter > 0:  # note >, not >=
;        sethpath(counter)
;        counter -= 1
;
;    finish_boxes()

init_maze nop
    jsr clear_maze
    ldy #MAZE_TOP_ROW
    jsr setrow
    ldy #MAZE_BOT_ROW
    jsr setrow
    ldx #VPATH_NUM
    stx maze_gen_col
?1  dex
    jsr setvpath
    cpx #0
    bne ?1

    ldx #VPATH_NUM
?2  dex
    jsr sethpath
    cpx #1
    bne ?2

    jsr finish_boxes

    rts

;##### Box handling/painting
;
;# Level box storage uses the left column (we don't need to store the right side
;# because they are always a fixed distance away) and a list of rows.
;#
;# To examine the boundary of each box to check for dots, the top row and the
;# bottom row must look at BOX_WIDTH + 2 tiles, all the middle rows only have to
;# check the left and right tiles
;#
;# The entire list of rows doesn't need to be stored, either; only the top and
;# bottom because everything else is a middle row. Therefore, all we need is the
;# x of the left vpath, the top row and the bottom row:
;#
;# x1, ytop, ybot
;#
;# is 3 bytes. Max number of boxes is 10 per column, 6 columns that's 10 * 6 * 3
;# = 180 bytes. Less than 256, yay!
;#
;# n can also be used as a flag: if n == 0, the box has already been checked and
;# painted. n == 0xff is the flag to end processing.
;
;# for VPATH_NUM == 7:
;# 01 X/----T----T----T----T----T----\X_______
;# 02 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
;# 03 X|XXXX|XXXX|XXXX|XXXX|XXXX|XXXX|X_______
;# 04 X|XXXX|XXXX|XXXX|XXXX+----+XXXX|X_______
;
;# for VPATH_NUM == 6:
;# 01 X/-----T-----T-----T-----T-----\X_______
;# 02 X|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|X_______
;# 03 X|XXXXX|XXXXX|XXXXX|XXXXX|XXXXX|X_______
;# 04 X|XXXXX|XXXXX|XXXXX+-----+XXXXX|X_______
;
NUM_LEVEL_BOX_PARAMS = 3
;level_boxes .ds 10*6*NUM_LEVEL_BOX_PARAMS
level_boxes = $bd00

;# Box painting will be in hires so this array will become a tracker for the
;# hires display. It will need y address, y end address, x byte number. It's
;# possible for up to 3 boxes to get triggered to start painting when collecting
;# a dot, and because it will take multiple frames to paint a box there may be
;# even more active at one time, so for safety use 16 as possible max.
;#
;# player #, xbyte, ytop, ybot
;NUM_BOX_PAINTING_PARAMS = 4
;box_painting = [0] * NUM_BOX_PAINTING_PARAMS * 16
;
;def init_boxes():
;    zp.next_level_box = 0
init_boxes nop
    lda #0
    sta next_level_box
    rts
;
;def start_box(r, c):
;    zp.box_col_save = c
;    zp.box_row_save = r

; col in X, row in Y
start_box nop
    stx box_col_save
    sty box_row_save
    rts

;
;def add_box(r):
;    i = zp.next_level_box
;    level_boxes[i] = zp.box_col_save
;    level_boxes[i + 1] = zp.box_row_save
;    level_boxes[i + 2] = r
;    zp.box_row_save = r
;    zp.next_level_box += NUM_LEVEL_BOX_PARAMS
add_box nop
    ldx next_level_box
    lda box_col_save
    sta level_boxes,x
    inx
    lda box_row_save
    sta level_boxes,x
    inx
    tya
    sta level_boxes,x
    sta box_row_save
    inx
    stx next_level_box
    rts


;def finish_boxes():
;    i = zp.next_level_box
;    level_boxes[i] = 0xff
finish_boxes nop
    ldx next_level_box
    lda #$ff
    sta level_boxes,x
    rts



;def check_boxes():
check_boxes nop
;    x = 0
    ldy #0
    sty param_index
?loop ldy param_index
    lda level_boxes,y
;    pad.addstr(28, 0, str(level_boxes[0:21]))
;    while level_boxes[x] < 0xff:
    bpl ?1
    rts
;        c = level_boxes[x]
;        if c > 0:
?1  bne ?check
    iny ; box is filled; don't check again
    iny
    iny
    sty param_index
    bne ?loop

?check sta c1
    sty param_save ; save index so we can mark the box as filled
;            r1 = level_boxes[x + 1]
    iny
    lda level_boxes,y
    sta r1

    iny
    lda level_boxes,y
    sta r2

    iny
    sty param_index

;            addr = mazerow(r1)
    ldy r1
    jsr mazerow
    lda mazeaddr
    sta scratch_addr
    lda mazeaddr+1
    sta scratch_addr+1 ; scratch_addr is top row

;            r1 += 1
    iny
;            r1_save = r1
    sty r1
    sty r

    ldy r2
    jsr mazerow ; mazeaddr is bot row
;
;            # If there's a dot anywhere, then the box isn't painted. We don't
;            # care where it is so we don't need to keep track of individual
;            # locations.
;            dot = addr[c]|addr[c + 1]|addr[c + 2]|addr[c + 3]|addr[c + 4]|addr[c + 5]|addr[c + BOX_WIDTH + 1]
;
;            r2 = level_boxes[x + 2]
;            addr = mazerow(r2)
;            dot |= addr[c]|addr[c + 1]|addr[c + 2]|addr[c + 3]|addr[c + 4]|addr[c + 5]|addr[c + BOX_WIDTH + 1]
    lda #0
    sta dot

    ; start checking top and bottom rows. 7 columns starting at c
    ldy c1
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y
    iny
    ora (mazeaddr),y
    ora (scratch_addr),y

    and #TILE_DOT
    bne ?loop ; a dot somewhere in there; skip this box!

    sty c2

;            while r1 < r2:
;                addr = mazerow(r1)
;                dot |= addr[c]|addr[c + BOX_WIDTH + 1]
;                r1 += 1
?cols ldy r1
    cpy r2
    bcs ?paint

    jsr mazerow
    lda #0
    ldy c1
    ora (mazeaddr),y
    ldy c2
    ora (mazeaddr),y
    and #TILE_DOT
    bne ?loop ; a dot somewhere in there; skip this box!

    inc r1
    bne ?cols

;            if (dot & TILE_DOT) == 0:
;                # No dots anywhere! Start painting
;                mark_box_for_painting(r1_save, r2, c + 1)
?paint ldy r
    sty r1
    inc c1
    jsr mark_box_for_painting

;                level_boxes[x] = 0  # Set flag so we don't check this box again
    ldy param_save
    lda #0
    sta level_boxes,y

;                num_rows = r2 - r1_save
;                player_score[zp.current_actor] += num_rows * 100
    lda r2
    sec
    sbc r
    tay
    lda box_score,y
    jsr add_score



;def mark_box_for_painting(r1, r2, c):
mark_box_for_painting nop
;    box_log.debug("Marking box, player $%d @ %d,%d -> %d,%d" % (zp.current_actor, r1, c, r2, c + BOX_WIDTH))
;    x = 0
;    while x < NUM_BOX_PAINTING_PARAMS * 16:
    ldy #0
?loop cpy #MAX_BOX_PAINTING
    bcc ?1
    rts
;        if box_painting[x] == 0:
;            box_painting[x] = c
;            box_painting[x + 1] = r1
;            box_painting[x + 2] = r2
;            box_painting[x + 3] = zp.current_actor
;            break
?1  lda box_painting,y
    bne ?skip
    lda c1
    sta box_painting,y
    iny
    lda r1
    sta box_painting,y
    iny
    lda r2
    sta box_painting,y
    iny
    txa ; player number
    sta box_painting,y
    rts


;        x += NUM_BOX_PAINTING_PARAMS
;    pad.addstr(27, 0, "starting box, player @ %d %d,%d -> %d,%d" % (zp.current_actor, r1, c, r2, c + BOX_WIDTH))
?skip iny
    iny
    iny
    iny
    bne ?loop ; always
