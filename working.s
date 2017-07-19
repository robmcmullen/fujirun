    *= $6000

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

; Zero page locations. Using the whole thing because we aren't using any
; ROM routines

    *= $0006
; parameters: these should not be changed by child subroutines
param_x   .ds 1
param_y   .ds 1
param_col   .ds 1
param_row   .ds 1
param_index .ds 1
param_count .ds 1

    *= $0010
; scratch areas: these may be modified by child subroutines
scratch_addr  .ds 2
scratch_ptr   .ds 2
scratch_0     .ds 1
scratch_1     .ds 1
scratch_index .ds 1
scratch_count .ds 1
scratch_col   .ds 1
scratch_row .ds 1

    *= $0020
; required variables for HiSprite
damageindex   .ds 1
damageindex1  .ds 1
damageindex2  .ds 1
bgstore       .ds 2
damage_w      .ds 1
damage_h      .ds 1
damageptr     .ds 2
damageptr1    .ds 2
damageptr2    .ds 2
hgrhi         .ds 1    ; either $20 or $40, the base of each hgr screen
hgrselect     .ds 1    ; either $00 or $60, used as xor mask for HGRROWS_H1

    *= $0030
; global variables for this program
rendercount   .ds 1
drawpage      .ds 1      ; pos = page1, neg = page2
tempaddr      .ds 2
counter1      .ds 1
textptr       .ds 2
hgrptr        .ds 2
temprow       .ds 1
tempcol       .ds 1

    *= $0040
mazeaddr    .ds 2
next_level_box .ds 1


; constants

DAMAGEPAGE1 = $bf   ; page number of damage list for screen 1
DAMAGEPAGE2 = $be   ;   "" for screen 2
MAXPOSX     = 220
MAXPOSY     = 192 - 16

    *= $80


    *= $6000

start nop
    bit CLRTEXT     ; start with HGR page 1, full screen
    bit CLRMIXED
    bit TXTPAGE1
    bit SETHIRES

    jsr clrscr
    jsr init_screen_once
    jsr init_game
    jsr game_loop

forever
    jmp forever

clrscr
    lda #0
    sta clr1+1
    lda #$20
    sta clr1+2
clr0
    lda #$81
    ldy #0
clr1
    sta $ffff,y
    iny
    bne clr1
    inc clr1+2
    ldx clr1+2
    cpx #$40
    bcc clr1
    rts

init_game nop
    jsr init_maze
    jsr copytexthgr
    rts

game_loop nop
    jmp game_loop

.include "working-sprite-driver.s"
.include "rand.s"
.include "screen.s"
.include "maze.s"


