    *= $06

hgr_ptr .ds 2
FIRST_CHAR_OF_SCREEN .ds 1
FRAME_COUNT .ds 1

    *= $5000

start_set
    jsr set_hires
    jsr driver
    jsr set_text
    jmp forever
    rts
    brk

driver
    lda #$00
    sta FIRST_CHAR_OF_SCREEN
    lda #64
    sta FRAME_COUNT
page_loop
    jsr page
    dec FRAME_COUNT
    bne page_loop
    rts

forever
    jmp forever

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

set_text bit SETTEXT
    bit CLRMIXED
    bit TXTPAGE1
    bit CLRHIRES
    rts


    *= $5074
page
; set hires page 1 only
    lda #$20
    sta setscr_smc+2
    lda frame_count
    ldy #0
    lda #$ff
setscr_smc sta $ff00,y      ; 4
    iny                     ; 2
    bne setscr_smc          ; 4 = 10 * 256
    inc setscr_smc+2        ; 6
    ldx setscr_smc+2        ; 6
    cpx #$40                ; 2
    bcc setscr_smc          ; 4
    rts                     ; (18 + 10*256) * 32 = 82496

    brk
