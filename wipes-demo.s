titlepage jsr FASTSCROLL_4000_2000
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    jsr wait
    rts

fastwipe jsr wipeclear1
    jsr wipe2to1 ; copy hidden title page
    rts
