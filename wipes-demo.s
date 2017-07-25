titlepage jsr titlewipe
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

titlewipe jsr wipeclear1
    jsr wipe2to1 ; copy hidden title page
    rts
