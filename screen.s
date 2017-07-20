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

    lda #sprite_l - sprite_active
    sta param_count
    inc renderroundrobin_smc+1

renderroundrobin_smc
    ldy #0
    sty param_index

renderloop
    lda param_index
    and #sprite_l - sprite_active - 1
    tay
    lda sprite_active,y
    beq renderskip      ; skip if zero
    lda sprite_l,y
    sta jsrsprite_smc+1
    lda sprite_h,y
    sta jsrsprite_smc+2
    lda sprite_x,y
    sta param_x
    lda sprite_y,y
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




; Sprite data is interleaved so a simple indexed mode can be used. This is not
; convenient to set up but makes faster accessing because you don't have to 
; increment the index register. For example, all the info about sprite #2 can
; be indexed using Y = 2 on the indexed operators, e.g. "lda sprite_active,y",
; "lda sprite_x,y", etc.
;
; Number of sprites must be a power of 2

sprite_active
    .byte 1, 1, 1, 1, 1, 1, 1, 1  ; 1 = active, 0 = skip

sprite_l
    .byte <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11, <APPLE_SPRITE9X11

sprite_h
    .byte >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11, >APPLE_SPRITE9X11

sprite_x
    .byte 80, 164, 33, 45, 4, 9, 180, 18

sprite_y
    .byte 116, 126, 40, 60, 80, 100, 9, 140
