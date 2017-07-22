titlepage jsr wipeclear1
    jsr wipe2to1 ; copy hidden title page
    ldy     #$80    ; Loop a bit
?outer
    ldx     #$ff
?inner
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne     ?inner
    dey
    bne     ?outer
    rts

titlewipe jsr wipeclear1
    jsr wipe2to1
    rts
