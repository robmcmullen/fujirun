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
    jsr damage_char

    lda #DOT_SCORE
    jsr add_score
?1  rts


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
?1  lda box_painting_c,y
    beq ?skip
;             c1 = box_painting[x]
;             r1 = box_painting[x + 1]
;             r2 = box_painting[x + 2]
;             i = box_painting[x + 3]

    inc debug_paint_box

    sta c1
    lda box_painting_r1,y
    sta r1
    lda box_painting_r2,y
    sta r2
    lda box_painting_actor,y ; player number
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
    ldy param_index
    sta box_painting_r1,y
    inc param_index
    bne ?loop ; always

?finish ldy param_index
    lda #0
    sta box_painting_c,y

;         x += NUM_BOX_PAINTING_PARAMS
?skip inc param_index
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
    jsr print_score
    jsr print_lives
    inx
    jsr print_score
    jsr print_lives
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
update_lives nop
    lda #MAZE_SCORE_COL
    sta c
    lda player_lives_row,x
    sta r
    lda #6
    sta size
    jsr damage_string

print_lives nop
    ldy player_lives_row,x
    jsr mazerow
    lda player_lives,x
    cmp #6
    bcc ?ok
    lda #6
?ok sta scratch_col
    lda #40
    sec
    sbc scratch_col
    sta scratch_col
    ldy #MAZE_SCORE_COL
?loop cpy scratch_col
    bcc ?blank
    lda #'*'
    bne ?show
?blank lda #0
?show sta (mazeaddr),y
    iny
    cpy #40
    bcc ?loop
    rts


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

print_low_nibble stx param_x
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
    jsr print_low_nibble
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




init_damage lda #0
    sta damageindex1
    sta damageindex2
    sta damageptr
    sta damageptr1
    sta damageptr2
    lda #damagepage1
    sta damageptr+1
    sta damageptr1+1
    lda #damagepage2
    sta damageptr2+1
    lda #0
    sta tdamageindex1
    lda #128
    sta tdamageindex2
    rts

restorebg_driver
    ; copy damaged characters back to screen
    ;jsr copytexthgr
    ldy #0
    sty param_count
restorebg_loop1 ldy param_count
    cpy damageindex
    bcc restorebg_cont  ; possible there's no damage, so have to check first
    ldy #0
    sty damageindex  ; clear damage index for this page
    rts
restorebg_cont lda (damageptr),y ; groups of 4 x1 -> x2, y1 -> y2
    sta param_x
    iny
    lda (damageptr),y
    sta param_col
    iny
    lda (damageptr),y
    sta param_y
    iny
    lda (damageptr),y
    sta param_row
    iny
    sty param_count

    ldy param_y
restorebg_row lda textrows_h,y
    sta restorebg_row_smc+2
    lda textrows_l,y
    sta restorebg_row_smc+1
    ldx param_x
restorebg_row_smc lda $ffff,x
    jsr fastfont
    inx
    cpx param_col
    bcc restorebg_row_smc
    iny
    cpy param_row
    beq restorebg_row
    bcc restorebg_row
    bcs restorebg_loop1


; text position in r, c. add single char to both pages!
damage_char nop
    lda #1
    sta size
    ; fallthrough

; text position in r, c; string length in size
damage_string nop
    ldy tdamageindex1
    lda c
    sta TEXTDAMAGE,y
    iny
    lda r
    sta TEXTDAMAGE,y
    iny
    lda size
    sta TEXTDAMAGE,y
    iny
    sty tdamageindex1

    ldy tdamageindex2
    lda c
    sta TEXTDAMAGE,y
    iny
    lda r
    sta TEXTDAMAGE,y
    iny
    lda size
    sta TEXTDAMAGE,y
    iny
    sty tdamageindex2

    lda damagestart
    bmi ?2
    lda tdamageindex1
    sta tdamageindex
    rts
?2  lda tdamageindex2
    sta tdamageindex
    rts


restoretext nop
    ldy damagestart
    sty param_index
?loop1 ldy param_index
    cpy tdamageindex
    bcc ?cont  ; possible there's no damage, so have to check first
    lda damagestart
    sta tdamageindex  ; clear damage index for this page
    rts
?cont lda TEXTDAMAGE,y ; groups of 4 x1 -> x2, y1 -> y2
    sta param_col
    iny
    lda TEXTDAMAGE,y
    sta param_row
    iny
    lda TEXTDAMAGE,y
    sta param_count
    iny
    sty param_index
    jsr fasttiles
    beq ?loop1




; Draw sprites by looping through the list of sprites
renderstart
    lda #0
    sta damageindex
    sta param_index

renderloop
    ldx param_index
    jsr evaluate_status
    lda actor_active,x
    beq renderskip      ; skip if zero
    bmi renderend ; end if negative
    jsr get_sprite
    lda actor_l,x
    sta jsrsprite_smc+1
    lda actor_h,x
    sta jsrsprite_smc+2
    lda actor_x,x
    sta param_x
    lda actor_y,x
    sta param_y
    jmp jsrsprite_smc
jsrsprite_smc
    jsr $ffff           ; wish you could JSR ($nnnn)

    ldy damageindex
    lda scratch_col      ; contains the byte index into the line
    sta (damageptr),y
    iny
    clc
    adc damage_w
    sta (damageptr),y
    iny

    ; need to convert hgr y values to char rows
    lda param_y
    lsr a
    lsr a
    lsr a
    sta (damageptr),y
    iny
    lda param_y
    clc
    adc damage_h
    lsr a
    lsr a
    lsr a
    sta (damageptr),y
    iny
    sty damageindex

renderskip
    inc param_index
    bne renderloop

renderend
    rts
