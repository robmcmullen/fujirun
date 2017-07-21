debugtext nop
    sta SETTEXT
    sta KBDSTROBE
?1  lda KEYBOARD
    sta debug_last_key
    cmp #$A0  ; space?
    bne ?1
    rts


printhex ; A = hex byte, X = column, Y = row; A is clobbered, X&Y are not
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
?next lda (scratch_ptr),y
    beq ?exit
    ldy param_y
    jsr fastfont
    inx
    bne ?next
?exit rts


debug_damage .byte 0
debug_paint_box .byte 0
debug_mark_box .byte 0


debug_player nop
    lda #22
    sta scratch_row

    ldx #0
    lda actor_input_dir,x
    ldx #35
    ldy scratch_row
    jsr printhex
    ldx #0
    lda actor_dir,x
    ldx #38
    ldy scratch_row
    jsr printhex

    dec scratch_row
    ldx #0
    lda actor_x,x
    ldx #35
    ldy scratch_row
    jsr printhex
    ldx #0
    lda actor_y,x
    ldx #38
    ldy scratch_row
    jsr printhex

    dec scratch_row
    ldx #0
    lda actor_col,x
    ldx #35
    ldy scratch_row
    jsr printhex
    ldx #0
    lda actor_row,x
    ldx #38
    ldy scratch_row
    jsr printhex

    dec scratch_row
    ldx #0
    lda tdamageindex1
    ldx #35
    ldy scratch_row
    jsr printhex
    ldx #0
    lda tdamageindex2
    ldx #38
    ldy scratch_row
    jsr printhex

    dec scratch_row
    ldx #0
    lda debug_mark_box
    ldx #35
    ldy scratch_row
    jsr printhex
    ldx #0
    lda debug_paint_box
    ldx #38
    ldy scratch_row
    jsr printhex

    rts
