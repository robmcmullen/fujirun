    *= $6000

; conditional compilation flags

DEBUG_BOUNDS = 1


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

    *= $0080
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

    *= $0090
; required variables for HiSprite/asmgen
damageindex   .ds 1
damageindex1  .ds 1
damageindex2  .ds 1
bgstore       .ds 2
damage_w      .ds 1
damage_h      .ds 1
damageptr     .ds 2
damageptr1    .ds 2
damageptr2    .ds 2

    *= $00a0
tdamageindex .ds 1
tdamageindex1 .ds 1
tdamageindex2 .ds 1
damagestart .ds 1
src   .ds 2 ; decompression usage
dst   .ds 2
end  .ds 2
count   .ds 2
delta   .ds 2
 
    *= $00b0
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

    *= $00c0
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

    *= $00d0
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

    * = $00e0
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

    lda #<TITLE_START
    sta src
    lda #>TITLE_START
    sta src+1
    lda #<TITLE_END
    sta end
    lda #>TITLE_END
    sta end+1
    lda #0
    sta dst
    lda #$40
    sta dst+1
    jsr unpack_lz4

restart jsr init_once
    jsr title_screen
    jsr init_game
    jsr game_loop

check_restart ldx #34 ; x coord on screen for "GAME"
    ldy player_score_row
    lda #<game_text
    sta scratch_ptr
    lda #>game_text
    sta scratch_ptr+1
    jsr printstr
    ldx #35 ; x coordinate for "OVER"
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

init_once jsr init_vars
    jsr init_damage
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

; main game loop. Rather than optimize things and unroll all this stuff into
; a single big function, I'm calling a bunch of subroutines in hopes that
; it is easier to follow.
;
; The "actor" is either a player or an enemy, and the actor number is placed
; in the X register. Subroutines must save the X register and restore it
; upon return if they modify it.
;
; All of the game logic routines expect the player/enemy number in X as they
; use it as an index into whatever specific data they need, like position or
; direction.
game_loop nop
    inc frame_count ; frame count isn't used for anything other than debugging
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
    jsr clear_actor_flag
    jsr move_enemy
    jsr set_actor_flag
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
; little while before the game ends. Returning from the game loop means
; that the game is over.
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


; updates the game state based on player status changes
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
.include "lz4.s"
