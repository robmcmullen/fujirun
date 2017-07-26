    *= $6000

.include "macros.s"
.include "constants.s"

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
last_dir .ds 1
allowed .ds 1 ; allowed directions
allowed_horz .ds 1
allowed_vert .ds 1
updown .ds 1 ; up or down for amidar
d .ds 1 ; actor input dir
r .ds 1
r1 .ds 1
r2 .ds 1
c .ds 1
c1 .ds 1
c2 .ds 1
size .ds 1
dot .ds 1

    * = $0070
before .ds 1
crossed .ds 1
round_robin_index .ds 2
level .ds 1
last_enemy .ds 1

    *= $f0
debug_a .ds 1
debug_x .ds 1
debug_y .ds 1
debug_last_key .ds 1
frame_count .ds 2

; other declare storage vars
.include "vars.s"

    *= $6000

start jsr set_hires     ; start with HGR page 1, full screen

    ;jsr clrscr
    jsr init_once

restart jsr title_screen
    jsr init_game
    jsr game_loop

check_restart ldx #34
    ldy player_score_row
    lda #<game_text
    sta scratch_ptr
    lda #>game_text
    sta scratch_ptr+1
    jsr printstr
    ldx #35
    ldy player_lives_row
    lda #<over_text
    sta scratch_ptr
    lda #>over_text
    sta scratch_ptr+1
    jsr printstr ; prints to back page, so have to flip pages to show
    jsr pageflip

    jsr any_key
    jmp restart

game_text .byte "GAME  ",0
over_text .byte "OVER",0

forever
    jmp forever

init_once jsr init_damage
    jsr init_screen_once
    jsr init_actors_once
    rts

title_screen nop
    lda #1
    sta config_num_players
    lda #0
    sta config_quit
    lda #1
    sta level
    rts

init_game jsr init_level
    jsr init_actors
    jsr initbackground
    lda #0
    sta frame_count
    sta frame_count+1
    sta countdown_time
    sta config_quit
    rts

initbackground jsr init_damage
    jsr show_page1
    jsr init_maze
    jsr init_panel
    jsr titlepage
    jsr copytexthgr  ; page2 becomes the source
    jsr fastwipe
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

    ; loop through enemies first so we can check collisions with the
    ; players as the players are moved
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

; if any player is still alive, the game continues. Once the last player
; dies, the countdown timer allows the enemies to continue to move a
; little while before the game ends
?alive lda still_alive
    bne ?draw
    dec countdown_time
    bne ?draw
    rts

; main draw loop. Restoring background will overwrite the softsprites
; so there's no need to erase the sprites some other way. Text damage
; is also restored before any changes for the upcoming frame are drawn.
?draw jsr restorebg_driver
    jsr restoretext
    jsr paint_boxes
    jsr renderstart
    jsr pageflip
    jsr debug_player
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




.include "rand.s"
.include "maze.s"
.include "actors.s"
.include "logic.s"
.include "background.s"
.include "debug.s"
