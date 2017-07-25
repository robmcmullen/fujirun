


restorebg_init
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

    ldy param_row
    lda textrows_h,y
    sta ?row_smc+2
    lda textrows_l,y
    sta ?row_smc+1
    ldx param_col
?row_smc lda $ffff,x
    jsr fastfont
    inx
    dec param_count
    bne ?row_smc
    beq ?loop1


