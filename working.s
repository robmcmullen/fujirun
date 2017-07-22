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
param_save .ds 1

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

    *= $0030
tdamageindex .ds 1
tdamageindex1 .ds 1
tdamageindex2 .ds 1
damagestart .ds 1
 
    *= $0040
; global variables for this program
rendercount   .ds 1
drawpage      .ds 1      ; pos = page1, neg = page2
hgrhi         .ds 1    ; either $20 or $40, the base of each hgr screen
hgrselect     .ds 1    ; either $00 or $60, used as xor mask for HGRROWS_H1
tempaddr      .ds 2
counter1      .ds 1
textptr       .ds 2
hgrptr        .ds 2
temprow       .ds 1
tempcol       .ds 1
tempcheck .ds 1

    *= $0050
mazeaddr    .ds 2
next_level_box .ds 1
box_row_save .ds 1
box_col_save .ds 1
maze_gen_col .ds 1
config_num_players .ds 1
config_quit .ds 1
frame_count .ds 2
countdown_time .ds 1
still_alive .ds 1

    *= $0060
current_actor .ds 1
current .ds 1 ; current direction
allowed .ds 1 ; allowed directions
d .ds 1 ; actor input dir
r .ds 1
r1 .ds 1
r2 .ds 1
c .ds 1
c1 .ds 1
c2 .ds 1
size .ds 1
dot .ds 1
round_robin_index .ds 2
level .ds 1
last_enemy .ds 1

    * = $0070
before .ds 1
crossed .ds 1


; memory map
; BF00 - BFFF: damage for page 1
; BE00 - BEFF: damage for page 2
; BD00 - BDFF: level box storage
; BC00 - BCFF: text damage
; constants

DAMAGEPAGE1 = $bf   ; page number of damage list for screen 1
DAMAGEPAGE2 = $be   ;   "" for screen 2
TEXTDAMAGE = $bc00
MAXPOSX     = 220
MAXPOSY     = 192 - 16

    *= $80

    *= $f0
debug_a .ds 1
debug_x .ds 1
debug_y .ds 1
debug_last_key .ds 1
frame_count .ds 2


    *= $6000

start nop
    bit CLRTEXT     ; start with HGR page 1, full screen
    bit CLRMIXED
    bit TXTPAGE1
    bit SETHIRES

    ;jsr clrscr
    jsr init_once
    jsr title_screen
    jsr init_game
    jsr game_loop

init_once
    jsr init_screen_once
    jsr init_actors_once
    ldx #MAX_BOX_PAINTING
    lda #0
?1  sta box_painting - 1,x
    dex
    bne ?1
    rts

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

    lda #0
    ldx #39
?1  jsr text_put_col ; text page 1
    jsr text_put_col2 ; text page 2
    dex
    bpl ?1
    rts

title_screen nop
    lda #1
    sta config_num_players
    lda #0
    sta config_quit
    lda #1
    sta level
    rts

init_game nop
    jsr init_level
    jsr init_actors
    jsr initbackground
    lda #0
    sta frame_count
    sta frame_count+1
    sta countdown_time
    sta config_quit
    rts

initbackground nop
    jsr show_page1
    jsr init_maze
    jsr init_panel
    jsr copytexthgr  ; page2 becomes the source
    jsr wipeclear1
    jsr wipe2to1
    jsr copy2to1
    rts

game_loop nop
    inc frame_count
    bne ?1
    inc frame_count+1
?1  jsr userinput

    lda config_quit
    beq ?2
    rts
?2  lda #FIRST_AMIDAR-1
    sta current_actor
?enemy inc current_actor
    ldx current_actor
    lda actor_active,x
    bmi ?player ; negative = end
    beq ?enemy ; zero = skip
    jsr move_enemy
    jmp ?enemy

?player lda #0
    sta still_alive
    lda #$ff
    sta current_actor
?p1 inc current_actor
    ldx current_actor
    lda actor_type,x
    cmp #PLAYER_TYPE
    bne ?alive
    lda actor_active,x
    beq ?p1 ; zero = skip
    jsr handle_player
    jmp ?p1

?alive lda still_alive
    bne ?draw
    dec countdown_time
    bne ?draw
    rts

;        erase_sprites()
;        update_background()
;        draw_actors()
;        show_screen()
?draw jsr restorebg_driver
    jsr restoretext
    jsr paint_boxes
    jsr renderstart
    jsr pageflip
    ;jsr debug_player
    ;jsr wait
    jmp game_loop




handle_player nop
;            if actor_status[zp.current_actor] == PLAYER_REGENERATING:
;                # If regenerating, change to alive if the player starts to move
;                if actor_input_dir[zp.current_actor] > 0:
;                    actor_status[zp.current_actor] = PLAYER_ALIVE
    lda actor_status,x
    cmp #PLAYER_REGENERATING
    bne ?alive
    lda actor_input_dir,x
    beq ?final
    lda #PLAYER_ALIVE
    sta actor_status,x

;            if actor_status[zp.current_actor] == PLAYER_ALIVE:
;                # only move and check collisions if alive
;                move_player()
;                check_collisions()
?alive lda actor_status,x
    cmp #PLAYER_ALIVE
    bne ?dots
    jsr move_player
    jsr check_collisions

;            if actor_status[zp.current_actor] == PLAYER_ALIVE:
;                # only check for points if still alive
;                check_dots()
;                check_boxes()

?dots lda actor_status,x
    cmp #PLAYER_ALIVE
    bne ?final
    jsr check_dots
    jsr check_boxes

;            if actor_status[zp.current_actor] != GAME_OVER:
;                still_alive += 1
;            zp.current_actor += 1

?final lda actor_status,x
    cmp #GAME_OVER
    beq ?end
    inc still_alive
?end rts




userinput
    lda KEYBOARD
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
    cmp #$c9  ; I
    bne check_down
input_up lda #TILE_UP
    sta actor_input_dir,x
    rts

check_down cmp #$af  ; down arrow
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


wait
    ldy     #$06    ; Loop a bit
wait_outer
    ldx     #$ff
wait_inner
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dex
    bne     wait_inner
    dey
    bne     wait_outer
    rts



.include "working-sprite-driver.s"
.include "rand.s"
.include "screen.s"
.include "maze.s"
.include "actors.s"
.include "logic.s"
.include "background.s"
.include "debug.s"

; vars must be last
.include "vars.s"
