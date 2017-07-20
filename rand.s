
; defines

rand_test ldx #0
?1  jsr get_rand_byte
    sta $2000,x
    inx
    bne ?1
?2  jsr get_rand_spacing
    sta $2100,x
    inx
    bne ?2
?3  jsr get_rand_col
    sta $2200,x
    inx
    bne ?3

    brk


randval8 .byte $ff

; return random.randint(3, 5)
;
; returns random value between 3 and 5 in A
get_rand_spacing nop
?1  lda randval8
    asl
    adc #$3b
    eor #$3f
    sta randval8
    and #3
    cmp #3
    bcs ?1 ; loop till less than 3
    clc
    adc #3
    rts


;# Random number between 0 and VPATH_NUM (exclusive) used for column starting
;# positions
;def get_rand_col():
;    return random.randint(0, VPATH_NUM - 1)
get_rand_col nop
?1  lda randval8
    asl
    adc #$3b
    eor #$3f
    sta randval8
    and #7
    cmp #VPATH_NUM
    bcs ?1 ; loop till less than VPATH_NUM
    rts


; def get_rand_byte():
;     return random.randint(0, 255)
get_rand_byte nop
    lda randval8
    asl
    adc #$3b
    eor #$3f
    sta randval8
    rts


; # Get random starting columns for enemies by swapping elements in a list
; # several times
; def get_col_randomizer(r):
;     r[:] = vpath_cols[:]
;     x = 10
;     while x >= 0:
;         i1 = get_rand_col()
;         i2 = get_rand_col()
;         old1 = r[i1]
;         r[i1] = r[i2]
;         r[i2] = old1
;         x -= 1

; addr in scratch_addr, clobbers all
get_col_randomizer nop
    ldy #VPATH_NUM
?1  dey
    lda vpath_cols,y
    sta (scratch_addr),y
    cpy #0
    bne ?1

    lda #10
    sta scratch_count
get_col_lp  jsr get_rand_col
    sta scratch_0
    jsr get_rand_col
    sta scratch_1
    ldy scratch_0
    lda (scratch_addr),y
    sta scratch_2
    ldy scratch_1
    lda (scratch_addr),y
    ldy scratch_0
    sta (scratch_addr),y
    ldy scratch_1
    lda scratch_2
    sta (scratch_addr),y
    dex scratch_count
    bne get_col_lp
    rts
