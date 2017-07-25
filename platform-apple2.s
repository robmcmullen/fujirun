
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

; wait for any key
any_key lda KBDSTROBE
?1  lda KEYBOARD
    bpl ?1
    lda KBDSTROBE
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

.include "_apple2-working-sprite-driver.s"
