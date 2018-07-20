; A = character, X = column, Y = row; A is clobbered, X&Y are not

FASTFONT_H1 ; A = character, X = column, Y = row; A is clobbered, X&Y are not
    sty scratch_y
    tay
    lda FASTFONT_H1_JMP_HI,y  ; get character
    sta FASTFONT_H1_JMP+2
    lda FASTFONT_H1_JMP_LO,y
    sta FASTFONT_H1_JMP+1
    ldy scratch_y
    lda hgrtextrow_l,y ; load address of first line of hgr text
    sta hgr_ptr
    lda hgrtextrow_h,y
    sta hgr_ptr+1
    txa
    tay
    jmp CHAR_A
FASTFONT_H1_JMP
    jmp $ffff

FASTFONT_H1_JMP_HI
FASTFONT_H1_JMP_LO


hgrtextrow_l
        .byte $00,$80,$00,$80,$00,$80,$00,$80
        .byte $28,$A8,$28,$A8,$28,$A8,$28,$A8
        .byte $50,$D0,$50,$D0,$50,$D0,$50,$D0
hgrtextrow_h
        .byte $20,$20,$21,$21,$22,$22,$23,$23
        .byte $20,$20,$21,$21,$22,$22,$23,$23
        .byte $20,$20,$21,$21,$22,$22,$23,$23

CHAR_A
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ora #0
    sta (hgr_ptr),y
    clc
    lda #4
    adc hgr_ptr+1
    sta hgr_ptr+1
    ldy scratch_y
    rts