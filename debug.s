debugtext nop
    sta SETTEXT
    sta KBDSTROBE
?1  lda KEYBOARD
    sta debug_last_key
    cmp #$A0  ; space?
    bne ?1
    rts
