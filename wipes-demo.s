titlepage jsr FASTSCROLL_4000_2000
    lda #$50
    sta param_count
?1  jsr wait
    dec param_count
    bne ?1
    rts

fastwipe jsr wipeclear1
    jsr wipe2to1 ; copy hidden title page
    rts
