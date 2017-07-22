debugtext nop
    sta SETTEXT
    sta KBDSTROBE
?1  lda KEYBOARD
    sta debug_last_key
    cmp #$A0  ; space?
    bne ?1
    rts


debughex ; A = hex byte, X = column, Y = row; A is clobbered, X&Y are not
    pha
    stx param_x
    lsr
    lsr
    lsr
    lsr
    tax
    lda hexdigit,x
    ldx param_x
    jsr fastfont
    pla
    and #$0f
    tax
    lda hexdigit,x
    ldx param_x
    inx
    jsr fastfont
    rts

hexdigit .byte "0123456789ABCDEF"

printstr ; X = column, Y = row, scratch_ptr is text (null terminated)
    sty param_y
    ldy #0
    sty param_index
?next ldy param_index
    lda (scratch_ptr),y
    beq ?exit
    ldy param_y
    jsr fastfont
    inc param_index
    inx
    bne ?next
?exit rts


debug_damage .byte 0
debug_paint_box .byte 0
debug_mark_box .byte 0


debug_player nop
    lda #22
    sta scratch_row

    ldx #34
    ldy scratch_row
    lda #'d'
    jsr fastfont
    ldx #0
    lda actor_input_dir,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #0
    lda actor_dir,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'x'
    jsr fastfont
    ldx #0
    lda actor_x,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #0
    lda actor_y,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'c'
    jsr fastfont
    ldx #0
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #0
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'s'
    jsr fastfont
    ldx #0
    lda actor_status,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #0
    lda actor_row,x
    ldx #38
    ldy scratch_row
    ;jsr debughex

;    dec scratch_row
;    ldx #34
;    ldy scratch_row
;    lda #'t'
;    jsr fastfont
;    ldx #0
;    lda tdamageindex1
;    ldx #35
;    ldy scratch_row
;    jsr debughex
;    ldx #0
;    lda tdamageindex2
;    ldx #38
;    ldy scratch_row
;    jsr debughex
;
;    dec scratch_row
;    ldx #34
;    ldy scratch_row
;    lda #'p'
;    jsr fastfont
;    ldx #0
;    lda debug_mark_box
;    ldx #35
;    ldy scratch_row
;    jsr debughex
;    ldx #0
;    lda debug_paint_box
;    ldx #38
;    ldy scratch_row
;    jsr debughex

    ; amidar 4
    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'4'
    jsr fastfont
    ldx #FIRST_AMIDAR+3
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR+3
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr debughex

    ; amidar 3
    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'3'
    jsr fastfont
    ldx #FIRST_AMIDAR+2
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR+2
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr debughex

    ; amidar 2
    dec scratch_row
    ldx #FIRST_AMIDAR+1
    lda actor_xpixel,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR+1
    lda actor_ypixel,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'2'
    jsr fastfont
    ldx #FIRST_AMIDAR+1
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR+1
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr debughex

    ; amidar 1 (orbiter)
    dec scratch_row
    ldx #FIRST_AMIDAR
    lda actor_xpixel,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR
    lda actor_ypixel,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #FIRST_AMIDAR
    lda actor_xfrac,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR
    lda actor_yfrac,x
    ldx #38
    ldy scratch_row
    jsr debughex

    dec scratch_row
    ldx #34
    ldy scratch_row
    lda #'1'
    jsr fastfont
    ldx #FIRST_AMIDAR
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr debughex
    ldx #FIRST_AMIDAR
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr debughex

    rts
