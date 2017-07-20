    *= $6000

.include "macros.s"

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
scratch_2 .ds 1
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
box_row_save .ds 1
box_col_save .ds 1
maze_gen_col .ds 1
config_num_players .ds 1

    *= $50
current_actor .ds 1
current_dir .ds 1
r .ds 1
c .ds 1
round_robin_index .ds 2
level .ds 1
last_enemy .ds 1


; memory map
; BF00 - BFFF: damage for page 1
; BE00 - BEFF: damage for page 2
; BD00 - BDFF: level box storage

; constants

DAMAGEPAGE1 = $bf   ; page number of damage list for screen 1
DAMAGEPAGE2 = $be   ;   "" for screen 2
MAXPOSX     = 220
MAXPOSY     = 192 - 16

    *= $80

    *= $f0
debug_a .ds 1
debug_x .ds 1
debug_y .ds 1
debug_last_key .ds 1


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
    lda #1
    jsr init_level
    lda #1
    sta config_num_players
    jsr init_actors
    rts

game_loop nop
    jmp game_loop

.include "working-sprite-driver.s"
.include "rand.s"
.include "screen.s"
.include "maze.s"
.include "actors.s"
.include "logic.s"
.include "debug.s"

; vars must be last
.include "vars.s"
