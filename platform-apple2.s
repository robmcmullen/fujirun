
; os memory map
KEYBOARD = $c000
KBDSTROBE = $c010
CLRTEXT = $c050
SETTEXT = $c051
CLRMIXED = $c052
SETMIXED = $c053
TXTPAGE1 = $c054
TXTPAGE2 = $c055
CLRHIRES = $c056
SETHIRES = $c057


set_hires bit CLRTEXT     ; start with HGR page 1, full screen
    bit CLRMIXED
    bit TXTPAGE1
    bit SETHIRES
    rts

; clear all screens, hires and text
clrscr lda #$20
    sta clrscr_smc+2
    lda #$81
    ldy #0
clrscr_smc sta $ff00,y
    iny
    bne clrscr_smc
    inc clrscr_smc+2
    ldx clrscr_smc+2
    cpx #$40
    bcc clrscr_smc

    lda #0
    ldx #39
?1  jsr text_put_col ; text page 1
    jsr text_put_col2 ; text page 2
    dex
    bpl ?1
    rts


clear_input lda KBDSTROBE
    rts

; wait for any key
any_key lda KBDSTROBE
?1  lda KEYBOARD
    bpl ?1
    lda KBDSTROBE
    rts

; process gameplay user input. Sets actor_input_dir and various debugging
; input
userinput lda KEYBOARD
    pha
    ldx #38
    ldy #23
    jsr debughex
    ldx #0
    pla
    bpl input_not_movement ; stop movement of player if no direction input

    ; setting the keyboard strobe causes the key to enter repeat mode if held
    ; down, which causes a pause after the initial movement. Not setting the
    ; strobe allows smooth movement from the start, but there's no way to stop
    ;sta KBDSTROBE

check_up cmp #$8d  ; up arrow
    beq input_up
    cmp #$c1  ; 'A' key
    beq input_up
    cmp #$c9  ; I
    bne check_down
input_up lda #TILE_UP
    sta actor_input_dir,x
    rts

check_down cmp #$af  ; down arrow
    beq input_down
    cmp #$bb  ; ';' key (dvorak keyboards)
    beq input_down
    cmp #$da  ; 'Z' key
    beq input_down
    cmp #$d4  ; K
    bne check_left
input_down lda #TILE_DOWN
    sta actor_input_dir,x
    rts

check_left cmp #$88  ; left arrow
    beq input_left
    cmp #$c8  ; J
    bne check_right
input_left lda #TILE_LEFT
    sta actor_input_dir,x
    rts

check_right cmp #$95  ; right arrow
    beq input_right
    cmp #$ce  ; L
    bne input_not_movement
input_right lda #TILE_RIGHT
    sta actor_input_dir,x
    rts

input_not_movement lda #0
    sta actor_input_dir,x

check_special cmp #$80 + 32
    beq input_space
    cmp #$80 + '.'
    beq input_period
    cmp #$80 + 'P'
    beq input_period
    rts

input_space
    jmp debugflipscreens

input_period
    jsr wait
    lda KEYBOARD
    bpl input_period
    cmp #$80 + 'P'
    beq input_period
    rts

debugflipscreens
    lda #20
    sta scratch_count
debugloop
    jsr pageflip
    jsr wait
    jsr pageflip
    jsr wait
    dec scratch_count
    bne debugloop
    rts



; delay for a while. 7 reps = 7 * (2 + 256*19 + 2 + 3) = 34097 cycles
wait
    ldy #$06
wait_outer ; outer loop: 2 + 256 * (inner) + 2 + 3
    ldx #$ff
wait_inner  ; inner loop: 14 + 2 + 3
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne wait_inner
    dey
    bne wait_outer
    rts


; [i*7-3 for i in range(40)]
player_col_to_x .byte 0, 3, 10, 17, 24, 31, 38, 45, 52, 59, 66, 73, 80, 87, 94, 101, 108, 115, 122, 129, 136, 143, 150, 157, 164, 171, 178, 185, 192, 199, 206, 213, 220, 227, 234, 241, 248, 248, 248, 248, 248,
;.byte 0, 4, 11, 18, 25, 32, 39, 46, 53, 60, 67, 74, 81, 88, 95, 102, 109, 116, 123, 130, 137, 144, 151, 158, 165, 172, 179, 186, 193, 200, 207, 214, 221, 228, 235, 242, 249, 249, 249, 249, 249

; [i*8-5 for i in range(24)]
player_row_to_y .byte 0, 3, 11, 19, 27, 35, 43, 51, 59, 67, 75, 83, 91, 99, 107, 115, 123, 131, 139, 147, 155, 163, 171, 179


; defines the zone around the midpoint where the player can change to any direction, not just backtracking.
x_allowed_turn .byte 0, 0, 1, 1, 1, 0, 0
y_allowed_turn .byte 0, 0, 1, 1, 1, 0, 0, 0


;# Returns address of tile in col 0 of row y
;def mazerow(y):
;    return maze[y]

; row in Y
mazerow lda textrows_l,y
    sta mazeaddr
    lda textrows_h,y
    sta mazeaddr+1
    rts


; text & hgr screen utils

init_screen_once nop
    lda #0
    sta KBDSTROBE
    sta drawpage
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
    ldx #WIPE_DELAY
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
    ldx #WIPE_DELAY
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
    cpx #40
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
    sta fastfont_smc+1
    sta fasttiles_smc+1
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H1
    sta fastfont_smc+2
    sta fasttiles_smc+2
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
    sta fastfont_smc+1
    sta fasttiles_smc+1
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H2
    sta fastfont_smc+2
    sta fasttiles_smc+2
    sta copytexthgr_dest_smc+2
    rts

; tile for middle left/right (number 12) is a color tile and gets
; the wrong bit pattern when it's in an odd column -- replace the
; image with tile 15 when necessary
fastfont nop
    cmp #12
    bne fastfont_smc
    txa
    and #1
    bne ?1
    lda #15
    bne fastfont_smc
?1  lda #12
fastfont_smc jmp $ffff

; restore a horizontal segment from the text page to the current screen
; param_col = text column
; param_row = text screen row
; param_count = number of characters to copy to hgr screen
fasttiles ldx param_col
    ldy param_row
    lda textrows_h,y
    sta fasttiles_row_smc+2
    lda textrows_l,y
    sta fasttiles_row_smc+1
fasttiles_row_smc lda $ffff,x
    cmp #12
    bne fasttiles_smc
    txa
    and #1
    bne ?1
    lda #15
    bne fasttiles_smc
?1  lda #12
fasttiles_smc jsr $ffff
    inx
    dec param_count
    bne fasttiles_row_smc
    rts



; From Michael Pohoreski's font tutorial
FASTSCROLL_4000_2000_RTS
        rts
FASTSCROLL_4000_2000    ; A,X clobbered
        ldy #0
FASTSCROLL_4000_2000_OUTER
        cpy #192
        bcs FASTSCROLL_4000_2000_RTS
        lda HGRROWS_L,y
        sta FASTSCROLL_4000_2000_SMC0+1
        lda HGRROWS_H2,y
        sta FASTSCROLL_4000_2000_SMC0+2
        iny
        lda HGRROWS_L,y
        sta FASTSCROLL_4000_2000_SMC1+1
        lda HGRROWS_H2,y
        sta FASTSCROLL_4000_2000_SMC1+2
        iny
        lda HGRROWS_L,y
        sta FASTSCROLL_4000_2000_SMC2+1
        lda HGRROWS_H2,y
        sta FASTSCROLL_4000_2000_SMC2+2
        iny
        lda HGRROWS_L,y
        sta FASTSCROLL_4000_2000_SMC3+1
        lda HGRROWS_H2,y
        sta FASTSCROLL_4000_2000_SMC3+2
        iny
        ldx #39
FASTSCROLL_4000_2000_INNER
        lda $3000,x
        sta $2000,x
        lda $3400,x
        sta $2400,x
        lda $3800,x
        sta $2800,x
        lda $3c00,x
        sta $2c00,x
        lda $2080,x
        sta $3000,x
        lda $2480,x
        sta $3400,x
        lda $2880,x
        sta $3800,x
        lda $2c80,x
        sta $3c00,x
        lda $3080,x
        sta $2080,x
        lda $3480,x
        sta $2480,x
        lda $3880,x
        sta $2880,x
        lda $3c80,x
        sta $2c80,x
        lda $2100,x
        sta $3080,x
        lda $2500,x
        sta $3480,x
        lda $2900,x
        sta $3880,x
        lda $2d00,x
        sta $3c80,x
        lda $3100,x
        sta $2100,x
        lda $3500,x
        sta $2500,x
        lda $3900,x
        sta $2900,x
        lda $3d00,x
        sta $2d00,x
        lda $2180,x
        sta $3100,x
        lda $2580,x
        sta $3500,x
        lda $2980,x
        sta $3900,x
        lda $2d80,x
        sta $3d00,x
        lda $3180,x
        sta $2180,x
        lda $3580,x
        sta $2580,x
        lda $3980,x
        sta $2980,x
        lda $3d80,x
        sta $2d80,x
        lda $2200,x
        sta $3180,x
        lda $2600,x
        sta $3580,x
        lda $2a00,x
        sta $3980,x
        lda $2e00,x
        sta $3d80,x
        lda $3200,x
        sta $2200,x
        lda $3600,x
        sta $2600,x
        lda $3a00,x
        sta $2a00,x
        lda $3e00,x
        sta $2e00,x
        lda $2280,x
        sta $3200,x
        lda $2680,x
        sta $3600,x
        lda $2a80,x
        sta $3a00,x
        lda $2e80,x
        sta $3e00,x
        lda $3280,x
        sta $2280,x
        lda $3680,x
        sta $2680,x
        lda $3a80,x
        sta $2a80,x
        lda $3e80,x
        sta $2e80,x
        lda $2300,x
        sta $3280,x
        lda $2700,x
        sta $3680,x
        lda $2b00,x
        sta $3a80,x
        lda $2f00,x
        sta $3e80,x
        lda $3300,x
        sta $2300,x
        lda $3700,x
        sta $2700,x
        lda $3b00,x
        sta $2b00,x
        lda $3f00,x
        sta $2f00,x
        lda $2380,x
        sta $3300,x
        lda $2780,x
        sta $3700,x
        lda $2b80,x
        sta $3b00,x
        lda $2f80,x
        sta $3f00,x
        lda $3380,x
        sta $2380,x
        lda $3780,x
        sta $2780,x
        lda $3b80,x
        sta $2b80,x
        lda $3f80,x
        sta $2f80,x
        lda $2028,x
        sta $3380,x
        lda $2428,x
        sta $3780,x
        lda $2828,x
        sta $3b80,x
        lda $2c28,x
        sta $3f80,x
        lda $3028,x
        sta $2028,x
        lda $3428,x
        sta $2428,x
        lda $3828,x
        sta $2828,x
        lda $3c28,x
        sta $2c28,x
        lda $20a8,x
        sta $3028,x
        lda $24a8,x
        sta $3428,x
        lda $28a8,x
        sta $3828,x
        lda $2ca8,x
        sta $3c28,x
        lda $30a8,x
        sta $20a8,x
        lda $34a8,x
        sta $24a8,x
        lda $38a8,x
        sta $28a8,x
        lda $3ca8,x
        sta $2ca8,x
        lda $2128,x
        sta $30a8,x
        lda $2528,x
        sta $34a8,x
        lda $2928,x
        sta $38a8,x
        lda $2d28,x
        sta $3ca8,x
        lda $3128,x
        sta $2128,x
        lda $3528,x
        sta $2528,x
        lda $3928,x
        sta $2928,x
        lda $3d28,x
        sta $2d28,x
        lda $21a8,x
        sta $3128,x
        lda $25a8,x
        sta $3528,x
        lda $29a8,x
        sta $3928,x
        lda $2da8,x
        sta $3d28,x
        lda $31a8,x
        sta $21a8,x
        lda $35a8,x
        sta $25a8,x
        lda $39a8,x
        sta $29a8,x
        lda $3da8,x
        sta $2da8,x
        lda $2228,x
        sta $31a8,x
        lda $2628,x
        sta $35a8,x
        lda $2a28,x
        sta $39a8,x
        lda $2e28,x
        sta $3da8,x
        lda $3228,x
        sta $2228,x
        lda $3628,x
        sta $2628,x
        lda $3a28,x
        sta $2a28,x
        lda $3e28,x
        sta $2e28,x
        lda $22a8,x
        sta $3228,x
        lda $26a8,x
        sta $3628,x
        lda $2aa8,x
        sta $3a28,x
        lda $2ea8,x
        sta $3e28,x
        lda $32a8,x
        sta $22a8,x
        lda $36a8,x
        sta $26a8,x
        lda $3aa8,x
        sta $2aa8,x
        lda $3ea8,x
        sta $2ea8,x
        lda $2328,x
        sta $32a8,x
        lda $2728,x
        sta $36a8,x
        lda $2b28,x
        sta $3aa8,x
        lda $2f28,x
        sta $3ea8,x
        lda $3328,x
        sta $2328,x
        lda $3728,x
        sta $2728,x
        lda $3b28,x
        sta $2b28,x
        lda $3f28,x
        sta $2f28,x
        lda $23a8,x
        sta $3328,x
        lda $27a8,x
        sta $3728,x
        lda $2ba8,x
        sta $3b28,x
        lda $2fa8,x
        sta $3f28,x
        lda $33a8,x
        sta $23a8,x
        lda $37a8,x
        sta $27a8,x
        lda $3ba8,x
        sta $2ba8,x
        lda $3fa8,x
        sta $2fa8,x
        lda $2050,x
        sta $33a8,x
        lda $2450,x
        sta $37a8,x
        lda $2850,x
        sta $3ba8,x
        lda $2c50,x
        sta $3fa8,x
        lda $3050,x
        sta $2050,x
        lda $3450,x
        sta $2450,x
        lda $3850,x
        sta $2850,x
        lda $3c50,x
        sta $2c50,x
        lda $20d0,x
        sta $3050,x
        lda $24d0,x
        sta $3450,x
        lda $28d0,x
        sta $3850,x
        lda $2cd0,x
        sta $3c50,x
        lda $30d0,x
        sta $20d0,x
        lda $34d0,x
        sta $24d0,x
        lda $38d0,x
        sta $28d0,x
        lda $3cd0,x
        sta $2cd0,x
        lda $2150,x
        sta $30d0,x
        lda $2550,x
        sta $34d0,x
        lda $2950,x
        sta $38d0,x
        lda $2d50,x
        sta $3cd0,x
        lda $3150,x
        sta $2150,x
        lda $3550,x
        sta $2550,x
        lda $3950,x
        sta $2950,x
        lda $3d50,x
        sta $2d50,x
        lda $21d0,x
        sta $3150,x
        lda $25d0,x
        sta $3550,x
        lda $29d0,x
        sta $3950,x
        lda $2dd0,x
        sta $3d50,x
        lda $31d0,x
        sta $21d0,x
        lda $35d0,x
        sta $25d0,x
        lda $39d0,x
        sta $29d0,x
        lda $3dd0,x
        sta $2dd0,x
        lda $2250,x
        sta $31d0,x
        lda $2650,x
        sta $35d0,x
        lda $2a50,x
        sta $39d0,x
        lda $2e50,x
        sta $3dd0,x
        lda $3250,x
        sta $2250,x
        lda $3650,x
        sta $2650,x
        lda $3a50,x
        sta $2a50,x
        lda $3e50,x
        sta $2e50,x
        lda $22d0,x
        sta $3250,x
        lda $26d0,x
        sta $3650,x
        lda $2ad0,x
        sta $3a50,x
        lda $2ed0,x
        sta $3e50,x
        lda $32d0,x
        sta $22d0,x
        lda $36d0,x
        sta $26d0,x
        lda $3ad0,x
        sta $2ad0,x
        lda $3ed0,x
        sta $2ed0,x
        lda $2350,x
        sta $32d0,x
        lda $2750,x
        sta $36d0,x
        lda $2b50,x
        sta $3ad0,x
        lda $2f50,x
        sta $3ed0,x
        lda $3350,x
        sta $2350,x
        lda $3750,x
        sta $2750,x
        lda $3b50,x
        sta $2b50,x
        lda $3f50,x
        sta $2f50,x
        lda $23d0,x
        sta $3350,x
        lda $27d0,x
        sta $3750,x
        lda $2bd0,x
        sta $3b50,x
        lda $2fd0,x
        sta $3f50,x
        lda $33d0,x
        sta $23d0,x
        lda $37d0,x
        sta $27d0,x
        lda $3bd0,x
        sta $2bd0,x
        lda $3fd0,x
        sta $2fd0,x
FASTSCROLL_4000_2000_SMC0
        lda $ffff,x
        sta $33d0,x
FASTSCROLL_4000_2000_SMC1
        lda $ffff,x
        sta $37d0,x
FASTSCROLL_4000_2000_SMC2
        lda $ffff,x
        sta $3bd0,x
FASTSCROLL_4000_2000_SMC3
        lda $ffff,x
        sta $3fd0,x
        dex
        bmi FASTSCROLL_4000_2000_NEXT_OUTER

        jmp FASTSCROLL_4000_2000_INNER
FASTSCROLL_4000_2000_NEXT_OUTER
        jmp FASTSCROLL_4000_2000_OUTER
