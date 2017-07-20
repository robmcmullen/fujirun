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

debug_player nop
    ldx #0
    lda actor_input_dir,x
    ldx #35
    ldy #23
    jsr printhex

    ldx #0
    lda actor_x,x
    ldx #35
    ldy #22
    jsr printhex
    ldx #0
    lda actor_y,x
    ldx #38
    ldy #22
    jsr printhex

    ldx #0
    lda actor_col,x
    ldx #35
    ldy #21
    jsr printhex
    ldx #0
    lda actor_row,x
    ldx #38
    ldy #21
    jsr printhex

    rts
