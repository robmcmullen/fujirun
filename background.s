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
    jsr damage_char
    rts




;        if box_painting[x] == 0:
;            box_painting[x] = c
;            box_painting[x + 1] = r1
;            box_painting[x + 2] = r2
;            box_painting[x + 3] = zp.current_actor
;            break
    lda c1
    sta box_painting,y
    rts


;        x += NUM_BOX_PAINTING_PARAMS
;    pad.addstr(27, 0, "starting box, player @ %d %d,%d -> %d,%d" % (zp.current_actor, r1, c, r2, c + BOX_WIDTH))


save_index .byte 0

; def paint_boxes():
paint_boxes nop
;     x = 0
;     pad.addstr(28, 0, "Checking box:")
;     while x < NUM_BOX_PAINTING_PARAMS * 16:
    ldy #0
    sty param_index
?loop ldy param_index
    cpy #MAX_BOX_PAINTING
    bcc ?1
    rts

;         if box_painting[x] > 0:
?1  lda box_painting,y
    beq ?skip
;             c1 = box_painting[x]
;             r1 = box_painting[x + 1]
;             r2 = box_painting[x + 2]
;             i = box_painting[x + 3]

    inc debug_paint_box

    sta c1
    sty save_index
    iny
    lda box_painting,y
    sta r1
    iny
    lda box_painting,y
    sta r2
    iny
    lda box_painting,y ; player number
    iny
    sty param_index
;             box_log.debug("Painting box line, player %d at %d,%d" % (i, r1, c1))
;             pad.addstr(30, 0, "painting box line at %d,%d" % (r1, c1))
;             addr = screenrow(r1)
    ldy r1
    jsr mazerow
    ldy c1
    lda #$24 ; $ sign
    sta (mazeaddr),y
    iny
    lda #$23 ; # sign
    sta (mazeaddr),y
    iny
    lda #$24 ; $ sign
    sta (mazeaddr),y
    iny
    lda #$23 ; # sign
    sta (mazeaddr),y
    iny
    lda #$24 ; $ sign
    sta (mazeaddr),y

    lda c1
    sta c
    lda r1
    sta r
    lda #5
    sta size
    jsr damage_string
;             for c in range(BOX_WIDTH):
;                 if i == 0:
;                     addr[c1 + c] = ord("X")
;                 else:
;                     addr[c1 + c] = ord(".")
;             r1 += 1
    inc r1
;             print "ROW", r1
;             if r1 >= r2:
;                 box_painting[x] = 0
    lda r1
    cmp r2
    bcs ?finish

;             box_painting[x + 1] = r1
    ldy save_index
    iny
    sta box_painting,y
    bne ?loop

?finish ldy save_index
    lda #0
    sta box_painting,y
    beq ?loop



;         x += NUM_BOX_PAINTING_PARAMS
?skip iny
    iny
    iny
    iny
    sty param_index
    bne ?loop ; always

; 
; def init_static_background():
;     zp.current_actor = 0
;     while zp.current_actor < zp.num_players:
;         row = player_score_row[zp.current_actor]
;         pad.addstr(row - 1, MAZE_SCORE_COL, "       ")
;         pad.addstr(row, MAZE_SCORE_COL,     "Player%d" % (zp.current_actor + 1))
;         zp.current_actor += 1

clear_panel nop
    ldx #MAZE_RIGHT_COL+1
    lda #0
?1  jsr text_put_col
    inx
    cpx #40
    bcc ?1
    rts

init_panel nop
    jsr clear_panel

    ldy #1
    jsr mazerow
    ldy #MAZE_PANEL_COL
    ldx #0
?1  lda player1_text,x
    beq ?2
    sta (mazeaddr),y
    iny
    inx
    bne ?1
?2  
    ldy #6
    jsr mazerow
    ldy #MAZE_PANEL_COL
    ldx #0
?3  lda player2_text,x
    beq ?4
    sta (mazeaddr),y
    iny
    inx
    bne ?3
?4
    ldx #0
    jsr update_score
    inx
    jsr update_score
    rts

player1_text .byte "PLAYER1", 0
player2_text .byte "PLAYER2", 0



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

print_hex pha
    stx param_x
    lsr
    lsr
    lsr
    lsr
    tax
    lda hexdigit,x
    sta (mazeaddr),y
    iny
    pla
    and #$0f
    tax
    lda hexdigit,x
    sta (mazeaddr),y
    iny
    ldx param_x
    rts


; def update_score():
update_score nop
    lda #MAZE_SCORE_COL
    sta c
    lda player_score_row,x
    sta r
    lda #6
    sta size
    jsr damage_string

print_score nop
    ldy player_score_row,x
    jsr mazerow
    ldy #MAZE_SCORE_COL
    lda player_score_h,x
    jsr print_hex
    lda player_score_m,x
    jsr print_hex
    lda player_score_l,x
    jsr print_hex
    rts
;     row = player_score_row[zp.current_actor]
;     if actor_status[zp.current_actor] == GAME_OVER:
;         pad.addstr(row - 1, MAZE_SCORE_COL, "GAME   ")
;         pad.addstr(row, MAZE_SCORE_COL,     "   OVER")
;     else:
;         pad.addstr(row + 1, MAZE_SCORE_COL, " %06d" % player_score[zp.current_actor])
;         show_lives(row + 2, player_lives[zp.current_actor])
; 