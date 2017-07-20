; 
; def check_dots():
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
;     if has_dot(r, c):
;         dot_eaten_row[zp.current_actor] = r
;         dot_eaten_col[zp.current_actor] = c
; 
;         # Update maze here so we can check which player closed off a box
;         addr = mazerow(r)
;         addr[c] &= ~TILE_DOT
; 
;         player_score[zp.current_actor] += DOT_SCORE
check_dots nop
    lda actor_row,x
    sta r
    lda actor_col,x
    sta c
    jsr has_dot
    beq ?1
    lda r
    sta dot_eaten_row,x
    lda c
    sta dot_eaten_col,x

    ldy r
    jsr mazerow
    ldy c
    lda (mazeaddr),y
    and #CLEAR_TILE_DOT
    sta (mazeaddr),y

    ; update damage! Needs to update both screens
    jsr damage_maze

    lda #DOT_SCORE
    jsr add_score
?1  rts


; update both screens!
damage_maze nop
    rts


; 
; def update_background():
;     zp.current_actor = 0
;     while zp.current_actor < zp.num_players:
;         if dot_eaten_col[zp.current_actor] < 128:
;             # Here we update the screen; note the maze has already been updated
;             # but we don't change the background until now so sprites can
;             # restore their saved backgrounds first.
; 
;             r = dot_eaten_row[zp.current_actor]
;             c = dot_eaten_col[zp.current_actor]
;             addr = screenrow(r)
;             addr[c] &= ~TILE_DOT
; 
;             # mark as completed
;             dot_eaten_col[zp.current_actor] = 255
;         update_score()
;         zp.current_actor += 1
; 
;     paint_boxes()
; 
; def paint_boxes():
;     x = 0
;     pad.addstr(28, 0, "Checking box:")
;     while x < NUM_BOX_PAINTING_PARAMS * 16:
;         pad.addstr(29, x, "%d   " % x)
;         if box_painting[x] > 0:
;             c1 = box_painting[x]
;             r1 = box_painting[x + 1]
;             r2 = box_painting[x + 2]
;             i = box_painting[x + 3]
;             box_log.debug("Painting box line, player %d at %d,%d" % (i, r1, c1))
;             pad.addstr(30, 0, "painting box line at %d,%d" % (r1, c1))
;             addr = screenrow(r1)
;             for c in range(BOX_WIDTH):
;                 if i == 0:
;                     addr[c1 + c] = ord("X")
;                 else:
;                     addr[c1 + c] = ord(".")
;             r1 += 1
;             print "ROW", r1
;             box_painting[x + 1] = r1
;             if r1 >= r2:
;                 box_painting[x] = 0
;         x += NUM_BOX_PAINTING_PARAMS
; 
; def init_static_background():
;     zp.current_actor = 0
;     while zp.current_actor < zp.num_players:
;         row = player_score_row[zp.current_actor]
;         pad.addstr(row - 1, MAZE_SCORE_COL, "       ")
;         pad.addstr(row, MAZE_SCORE_COL,     "Player%d" % (zp.current_actor + 1))
;         zp.current_actor += 1
; 
; def show_lives(row, num):
;     i = 1
;     col = SCREEN_COLS
;     while col > MAZE_SCORE_COL:
;         col -= 1
;         if i < num:
;             c = "*"
;         else:
;             c = " "
;         pad.addch(row, col, ord(c))
;         i += 1
; 
; def update_score():
;     row = player_score_row[zp.current_actor]
;     if actor_status[zp.current_actor] == GAME_OVER:
;         pad.addstr(row - 1, MAZE_SCORE_COL, "GAME   ")
;         pad.addstr(row, MAZE_SCORE_COL,     "   OVER")
;     else:
;         pad.addstr(row + 1, MAZE_SCORE_COL, " %06d" % player_score[zp.current_actor])
;         show_lives(row + 2, player_lives[zp.current_actor])
; 