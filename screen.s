; text & hgr screen utils

init_screen_once nop
    lda #0
    sta KBDSTROBE
    sta drawpage
    sta damageindex1
    sta damageindex2
    sta damageptr
    sta damageptr1
    sta damageptr2
    lda #damagepage1
    sta damageptr+1
    sta damageptr1+1
    lda #damagepage2
    sta damageptr2+1
    lda #0
    sta tdamageindex1
    lda #128
    sta tdamageindex2
    jsr draw_to_page1
    rts


; character in A, col in X
text_put_col nop
    sta $0400,x ; row 0
    sta $0480,x ; row 1
    sta $0500,x ; row 2
    sta $0580,x ; row 3
    sta $0600,x ; row 4
    sta $0680,x ; row 5
    sta $0700,x ; row 6
    sta $0780,x ; row 7
    sta $0428,x ; row 8
    sta $04a8,x ; row 9
    sta $0528,x ; row 10
    sta $05a8,x ; row 11
    sta $0628,x ; row 12
    sta $06a8,x ; row 13
    sta $0728,x ; row 14
    sta $07a8,x ; row 15
    sta $0450,x ; row 16
    sta $04d0,x ; row 17
    sta $0550,x ; row 18
    sta $05d0,x ; row 19
    sta $0650,x ; row 20
    sta $06d0,x ; row 21
    sta $0750,x ; row 22
    sta $07d0,x ; row 23
    rts

text_put_col2 nop
    sta $0800,x ; row 0
    sta $0880,x ; row 1
    sta $0900,x ; row 2
    sta $0980,x ; row 3
    sta $0a00,x ; row 4
    sta $0a80,x ; row 5
    sta $0b00,x ; row 6
    sta $0b80,x ; row 7
    sta $0828,x ; row 8
    sta $08a8,x ; row 9
    sta $0928,x ; row 10
    sta $09a8,x ; row 11
    sta $0a28,x ; row 12
    sta $0aa8,x ; row 13
    sta $0b28,x ; row 14
    sta $0ba8,x ; row 15
    sta $0850,x ; row 16
    sta $08d0,x ; row 17
    sta $0950,x ; row 18
    sta $09d0,x ; row 19
    sta $0a50,x ; row 20
    sta $0ad0,x ; row 21
    sta $0b50,x ; row 22
    sta $0bd0,x ; row 23
    rts

; maze is text screen 1
textrows_l .byte $00, $80, $00, $80, $00, $80, $00, $80
        .byte $28, $a8, $28, $a8, $28, $a8, $28, $a8
        .byte $50, $d0, $50, $d0, $50, $d0, $50, $d0
textrows_h .byte $04, $04, $05, $05, $06, $06, $07, $07
        .byte $04, $04, $05, $05, $06, $06, $07, $07
        .byte $04, $04, $05, $05, $06, $06, $07, $07


wipeclear1 ldy #0
    sty param_y
wipeclear1_loop lda HGRROWS_L,y
    sta wipeclear1_save_smc+1
    lda HGRROWS_H1,y
    sta wipeclear1_save_smc+2
    ldx #39
    lda #$ff
wipeclear1_save_smc sta $ffff,x
    dex
    bpl wipeclear1_save_smc
    ldx #0
wipeclear1_wait nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne wipeclear1_wait
    inc param_y
    ldy param_y
    cpy #192
    bcc wipeclear1_loop
    rts

wipe2to1 ldy #0
    sty param_y
wipe2to1_loop lda HGRROWS_H2,y
    sta wipe2to1_load_smc+2
    lda HGRROWS_L,y
    sta wipe2to1_load_smc+1
    sta wipe2to1_save_smc+1
    lda HGRROWS_H1,y
    sta wipe2to1_save_smc+2
    ldx #39
wipe2to1_load_smc lda $ffff,x
wipe2to1_save_smc sta $ffff,x
    dex
    bpl wipe2to1_load_smc
    ldx #0
wipe2to1_wait nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne wipe2to1_wait
    inc param_y
    ldy param_y
    cpy #192
    bcc wipe2to1_loop
    rts

copy2to1 lda #$40
    sta ?source+2
    lda #$20
    sta ?dest+2
?outer ldy #0
?source lda $ff00,y
?dest sta $ff00,y
    iny
    bne ?source
    inc ?source+2
    inc ?dest+2
    lda ?dest+2
    cmp #$40
    bcc ?outer
    rts


copytexthgr nop
    ldy #0      ; y is rows
copytexthgr_outer
    lda textrows_h,y
    ora #4
    sta copytexthgr_src_smc+2
    lda textrows_l,y
    sta copytexthgr_src_smc+1
    ldx #0      ; x is columns
copytexthgr_src_smc
    lda $ffff,x
copytexthgr_dest_smc
    jsr $ffff
    inx
    cpx #32
    bcc copytexthgr_src_smc
    iny
    cpy #24
    bcc copytexthgr_outer
    rts


pageflip nop
    lda drawpage
    eor #$80
    bpl show_page1   ; pos = show 1, draw 2; neg = show 1, draw 1

show_page2 lda #$80
    sta drawpage
    bit TXTPAGE2 ; show page 2, work on page 1
draw_to_page1 lda #$00
    sta hgrselect
    lda #$20
    sta hgrhi
    lda damageindex   ; save other page's damage pointer
    sta damageindex2

    lda #DAMAGEPAGE1  ; point to page 1's damage area
    sta damageptr+1
    lda damageindex1
    sta damageindex

    lda tdamageindex   ; save other page's damage pointer
    sta tdamageindex2
    lda tdamageindex1 ; point to page 1's damage area
    sta tdamageindex
    lda #0
    sta damagestart

    ; copy addresses for functions that write to one page or the other
    lda #<FASTFONT_H1
    sta fastfont+1
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H1
    sta fastfont+2
    sta copytexthgr_dest_smc+2
    rts

show_page1 lda #0
    sta drawpage
    bit TXTPAGE1 ; show page 1, work on page 2
draw_to_page2 lda #$60
    sta hgrselect
    lda #$40
    sta hgrhi
    lda damageindex   ; save other page's damage pointer
    sta damageindex1

    lda #DAMAGEPAGE2  ; point to page 2's damage area
    sta damageptr+1
    lda damageindex2
    sta damageindex

    lda tdamageindex   ; save other page's damage pointer
    sta tdamageindex1
    lda tdamageindex2 ; point to page 2's damage area
    sta tdamageindex
    lda #128
    sta damagestart

    lda #<FASTFONT_H2
    sta fastfont+1
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H2
    sta fastfont+2
    sta copytexthgr_dest_smc+2
    rts

; pageflip jump tables. JSR to one of these jumps and it will jump to the 
; correct version for the page. The rts in there will return to the caller

fastfont jmp $ffff



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
    ldy #0
    sty damageindex

    ;inc renderroundrobin_smc+1

renderroundrobin_smc
    lda #0
    sta param_index

renderloop
    lda param_index
    and #actor_l - actor_active - 1
    tax
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
    dec param_count
    bne renderloop

renderend
    rts


; text position in r, c. add to both pages!
damage_char nop
    ldy tdamageindex1
    lda c
    sta TEXTDAMAGE,y
    iny
    lda r
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
    sty param_index

    ldy param_row
    lda textrows_h,y
    sta ?row_smc+2
    lda textrows_l,y
    sta ?row_smc+1
    ldx param_col
?row_smc lda $ffff,x
    jsr fastfont
    jmp ?loop1


