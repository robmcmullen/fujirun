
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
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H1
    sta fastfont_smc+2
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
    sta copytexthgr_dest_smc+1
    lda #>FASTFONT_H2
    sta fastfont_smc+2
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
