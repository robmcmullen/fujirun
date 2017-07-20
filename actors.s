level_enemies .byte 55, 4, 5, 6, 7, 8 ;# level starts counting from 1, so dummy zeroth level info
level_speeds .byte 255, 200, 210, 220, 230, 240 ;# increment of fractional pixel per game frame
player_score_row .byte 2, 7, 12, 17


;# sprites all use the same table. In the sample configuration, sprites 0 - 3
;# are players, 4 and above are enemies. One is an orbiter enemy, the rest use
;# amidar movement.
MAX_PLAYERS = 4
MAX_AMIDARS = VPATH_NUM + 1  ; # one enemy per vpath + one orbiter
MAX_ACTORS = MAX_PLAYERS + MAX_AMIDARS
FIRST_PLAYER = 0
FIRST_AMIDAR = MAX_PLAYERS
LAST_PLAYER = FIRST_AMIDAR - 1
LAST_AMIDAR = MAX_ACTORS - 1

PLAYER_TYPE = 0
ORBITER_TYPE = 1
AMIDAR_TYPE = 2
actor_type .byte PLAYER_TYPE, PLAYER_TYPE, PLAYER_TYPE, PLAYER_TYPE
    .byte ORBITER_TYPE
    .byte AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE, AMIDAR_TYPE
actor_active .byte 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, $ff
actor_init_func_l .byte <init_player, <init_orbiter, <init_amidar
actor_init_func_h .byte >init_player, >init_orbiter, >init_amidar

STARTING_LIVES = 3
BONUS_LIFE = 10000
MAX_LIVES = 8

X_MIDPOINT = 3
X_TILEMAX = 7
Y_MIDPOINT = 3
Y_TILEMAX = 8

NOT_VISIBLE = 0
PLAYER_DEAD = 1
PLAYER_ALIVE = 2
PLAYER_EXPLODING = 3
PLAYER_REGENERATING = 4
AMIDAR_NORMAL = 5
ORBITER_NORMAL = 6
GAME_OVER = 255
;
;# Scores
;
DOT_SCORE = 10
PAINT_SCORE_PER_LINE = 100

; level number in X, clobbers
init_level nop
    stx level
    lda level_enemies,x
    clc
    adc #FIRST_AMIDAR
    sta last_enemy


;
;##### Gameplay initialization
;
;def init_actor():
;    # Common initialization params for all actors
;    actor_col[zp.current_actor] = MAZE_LEFT_COL
;    actor_xpixel[zp.current_actor] = 3
;    actor_xfrac[zp.current_actor] = 0
;    actor_xspeed[zp.current_actor] = 0
;    actor_row[zp.current_actor] = MAZE_BOT_ROW
;    actor_ypixel[zp.current_actor] = 3
;    actor_yfrac[zp.current_actor] = 0
;    actor_yspeed[zp.current_actor] = 0
;    actor_input_dir[zp.current_actor] = 0
;    actor_updown[zp.current_actor] = TILE_UP
;    actor_dir[zp.current_actor] = TILE_UP
;    actor_status[zp.current_actor] = NOT_VISIBLE
;    actor_frame_counter[zp.current_actor] = 0
;    actor_target_col[zp.current_actor] = 0
;    actor_input_dir[zp.current_actor] = 0

; actor in X
init_actor nop
    lda #MAZE_LEFT_COL
    sta actor_col,x
    lda #3
    sta actor_xpixel,x
    sta actor_ypixel,x
    lda #0
    sta actor_xfrac,x
    sta actor_xspeed,x
    sta actor_yfrac,x
    sta actor_yspeed,x
    sta actor_input_dir,x
    sta actor_frame_counter,x
    sta actor_target_col,x
    sta actor_input_dir,x
    lda #MAZE_BOT_ROW
    sta actor_row,x
    lda #TILE_UP
    sta actor_updown,x
    sta actor_dir,x
    lda #NOT_VISIBLE
    sta actor_status,x
    rts


;def init_orbiter():
;    init_actor()
;    actor_col[zp.current_actor] = ORBITER_START_COL
;    actor_row[zp.current_actor] = ORBITER_START_ROW
;    actor_dir[zp.current_actor] = TILE_UP
;    actor_status[zp.current_actor] = ORBITER_NORMAL
;    set_speed(TILE_UP)

; actor in X
init_orbiter nop
    jsr init_actor
    lda #ORBITER_START_COL
    sta actor_col,x
    lda #ORBITER_START_ROW
    sta actor_row,x
    lda #TILE_UP
    sta actor_dir,x
    lda #ORBITER_NORMAL
    sta actor_status,x
    rts



;def init_amidar():
;    init_actor()
;    amidar_index = zp.current_actor - FIRST_AMIDAR - 1  # orbiter always 1st enemy
;    actor_col[zp.current_actor] = amidar_start_col[amidar_index]
;    actor_row[zp.current_actor] = MAZE_TOP_ROW
;    actor_ypixel[zp.current_actor] = 4
;    actor_updown[zp.current_actor] = TILE_DOWN
;    actor_dir[zp.current_actor] = TILE_DOWN
;    actor_status[zp.current_actor] = AMIDAR_NORMAL
;    set_speed(TILE_DOWN)

; actor in X
init_amidar nop
    jsr init_actor
    txa
    sec
    sbc #FIRST_AMIDAR
    sbc #1
    tay
    lda amidar_start_col,y
    sta actor_col,x
    lda #MAZE_TOP_ROW
    sta actor_row,x
    lda #4
    sta actor_ypixel,x
    lda #TILE_DOWN
    sta actor_updown,x
    sta actor_dir,x
    lda #AMIDAR_NORMAL
    sta actor_status,x
    lda #TILE_DOWN
    jsr set_speed


;def init_player():
;    init_actor()
;    addr = player_start_col[zp.num_players]
;    actor_col[zp.current_actor] = addr[zp.current_actor]
;    actor_row[zp.current_actor] = MAZE_BOT_ROW
;    actor_status[zp.current_actor] = PLAYER_ALIVE
init_player nop
    jsr init_actor
    lda config_num_players  ; 4 players max, 
    asl a
    asl a
    clc
    adc current_actor
    tay
    lda player_start_col,y
    sta actor_col,x
    lda #MAZE_BOT_ROW
    sta actor_row,x
    lda #PLAYER_ALIVE
    sta actor_status,x
;                player_lives[zp.current_actor] = STARTING_LIVES
;                player_next_target_score[zp.current_actor] = BONUS_LIFE
    lda #STARTING_LIVES
    sta player_lives,x
    lda #BONUS_LIFE
    sta player_next_target_score,x
    rts


;def init_actors():
init_actors nop
;    get_col_randomizer(amidar_start_col)
    lda #<amidar_start_col
    sta scratch_addr
    lda #>amidar_start_col
    sta scratch_addr+1
    jsr get_col_randomizer
;    get_col_randomizer(round_robin_up)
    lda #<round_robin_up
    sta scratch_addr
    lda #>round_robin_up
    sta scratch_addr+1
    jsr get_col_randomizer
;    get_col_randomizer(round_robin_down)
    lda #<round_robin_down
    sta scratch_addr
    lda #>round_robin_down
    sta scratch_addr+1
    jsr get_col_randomizer

    lda #0
    sta round_robin_index
    sta round_robin_index+1

;    zp.current_actor = 0
;    while zp.current_actor <= zp.last_enemy:
;        if zp.current_actor <= LAST_PLAYER:
;            if zp.current_actor < zp.num_players:
;                init_player()
;                player_lives[zp.current_actor] = STARTING_LIVES
;                player_next_target_score[zp.current_actor] = BONUS_LIFE
;        else:
;            if zp.current_actor == FIRST_AMIDAR:
;                init_orbiter()
;            else:
;                init_amidar()
;        zp.current_actor += 1
;    zp.round_robin_index[:] = [0, 0]
    lda #$ff
    sta current_actor
init_actors_loop  inc current_actor
    ldx current_actor
    lda actor_status,x
    bpl ?2 ; negative = end
    rts
?2  beq init_actors_loop ; zero = skip
    lda actor_type,x
    tay
    lda actor_init_func_l,y
    sta init_actors_smc+1
    lda actor_init_func_h,y
    sta init_actors_smc+2
init_actors_smc jsr $ffff
    jmp init_actors_loop
