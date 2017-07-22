EXPLODING_TIME = 10
DEAD_TIME = 10
REGENERATING_TIME = 60
END_GAME_TIME = 100
TITLE_SCREEN_TIME = 100


; def draw_actors():
;     zp.current_actor = 0
;     while zp.current_actor <= zp.last_enemy:
;         r = actor_row[zp.current_actor]
;         c = actor_col[zp.current_actor]
;         get_sprite()
;         draw_sprite(r, c)
;         zp.current_actor += 1
; 
; def get_sprite():
;     a = actor_status[zp.current_actor]
;     if a == PLAYER_ALIVE:
;         c = ord("$") + zp.current_actor
;     elif a == PLAYER_EXPLODING:
;         collision_log.debug("p%d: exploding, frame=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
;         c = ord(exploding_char[actor_frame_counter[zp.current_actor]])
;         actor_frame_counter[zp.current_actor] -= 1
;         if actor_frame_counter[zp.current_actor] <= 0:
;             actor_status[zp.current_actor] = PLAYER_DEAD
;             actor_frame_counter[zp.current_actor] = DEAD_TIME
;     elif a == PLAYER_DEAD:
;         collision_log.debug("p%d: dead, waiting=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
;         c = None
;         actor_frame_counter[zp.current_actor] -= 1
;         if actor_frame_counter[zp.current_actor] <= 0:
;             player_lives[zp.current_actor] -= 1
;             if player_lives[zp.current_actor] > 0:
;                 init_player()
;                 actor_status[zp.current_actor] = PLAYER_REGENERATING
;                 actor_frame_counter[zp.current_actor] = REGENERATING_TIME
;             else:
;                 actor_status[zp.current_actor] = GAME_OVER
;     elif a == PLAYER_REGENERATING:
;         collision_log.debug("p%d: regenerating, frame=%d" % (zp.current_actor, actor_frame_counter[zp.current_actor]))
;         if actor_frame_counter[zp.current_actor] & 1:
;             c = ord("$") + zp.current_actor
;         else:
;             c = ord(" ")
;         actor_frame_counter[zp.current_actor] -= 1
;         if actor_frame_counter[zp.current_actor] <= 0:
;             actor_status[zp.current_actor] = PLAYER_ALIVE
;     elif a == AMIDAR_NORMAL or a == ORBITER_NORMAL:
;         c = ord("0") + zp.current_actor - FIRST_AMIDAR
;     else:
;         c = None
;     zp.sprite_addr = c

evaluate_status nop
; update pixel position
    lda actor_status,x
    cmp #PLAYER_EXPLODING
    bne ?dead

    lda #0
    sta actor_active,x
    dec actor_frame_counter,x
    bne ?end
    lda #PLAYER_DEAD
    sta actor_status,x
    lda #DEAD_TIME
    sta actor_frame_counter,x
    dec player_lives,x
    jmp update_lives

?dead cmp #PLAYER_DEAD
    bne ?regenerating
    dec actor_frame_counter,x
    bne ?end

    lda player_lives,x
    beq ?game_over

    jsr next_life
    lda #PLAYER_REGENERATING
    sta actor_status,x
    lda #REGENERATING_TIME
    sta actor_frame_counter,x
    rts

?regenerating cmp #PLAYER_REGENERATING
    bne ?end
    dec actor_frame_counter,x
    beq ?alive

    lda actor_frame_counter,x
    and #1
    sta actor_active,x
    rts

?game_over nop
    rts

?alive lda #1
    sta actor_active,x
?end rts


get_sprite nop
    lda actor_row,x
    tay
    lda player_row_to_y,y
    clc
    adc actor_ypixel,x
    sta actor_y,x
    lda actor_col,x
    tay
    lda player_col_to_x,y
    clc
    adc actor_xpixel,x
    sta actor_x,x

?end
    rts

?game_over
    rts

; 
; 
; ##### Game logic
; 
; # Determine which of the 4 directions is allowed at the given row, col
; def get_allowed_dirs(r, c):
;     addr = mazerow(r)
;     allowed = addr[c] & DIR_MASK
;     return allowed
get_allowed_dirs nop
    ldy r
    jsr mazerow
    ldy c
    lda (mazeaddr),y
    and #DIR_MASK
    sta allowed
    rts



; # See if current tile has a dot
; def has_dot(r, c):
;     addr = mazerow(r)
;     return addr[c] & TILE_DOT
has_dot nop
    ldy r
    jsr mazerow
    ldy c
    lda (mazeaddr),y
    and #TILE_DOT
    rts


; # clear a dot
; def clear_dot(r, c):
;     addr = mazerow(r)
;     addr[c] &= ~TILE_DOT
; 
; # Determine the tile location given the direction of the actor's movement
; def get_next_tile(r, c, dir):
;     if dir & TILE_UP:
;         r -= 1
;     elif dir & TILE_DOWN:
;         r += 1
;     elif dir & TILE_LEFT:
;         c -= 1
;     elif dir & TILE_RIGHT:
;         c += 1
;     else:
;         logic_log.error("bad direction % dir")
;     return r, c
get_next_tile nop
    lda actor_dir,x
    sta scratch_0
    and #TILE_UP
    beq ?down
    dec r
    rts
?down lda scratch_0
    and #TILE_DOWN
    beq ?left
    inc r
    rts
?left lda scratch_0
    and #TILE_LEFT
    beq ?right
    dec c
    rts
?right lda scratch_0
    and #TILE_RIGHT
    beq ?end
    inc c
?end rts


; 
; # Choose a target column for the next up/down direction at a bottom or top T
; def get_next_round_robin(rr_table, x):
get_next_round_robin nop
    lda round_robin_index,y
    pha
    tay
    iny
    cpy #VPATH_NUM
    bcc ?ok
    ldy #0
?ok  tya
    sta round_robin_index,y
;     target_col = rr_table[zp.round_robin_index[x]]
    pla
    tay
    lda (scratch_ptr),y
;     logic_log.debug("target: %d, indexes=%s, table=%s" % (target_col, str(zp.round_robin_index), rr_table))
;     zp.round_robin_index[x] += 1
;     if zp.round_robin_index[x] >= VPATH_NUM:
;         zp.round_robin_index[x] = 0
;     return target_col
    rts

; # Find target column when enemy reaches top or bottom
; def get_target_col(c, allowed_vert):
get_target_col nop
;     if allowed_vert & TILE_UP:
;         x = 1
;         rr_table = round_robin_up
    lda allowed_vert
    and #TILE_HORZ
    bne ?down
    ldy #0
    lda #<round_robin_up
    sta scratch_ptr
    lda #>round_robin_up
    sta scratch_ptr+1
    jmp ?load

;     else:
;         x = 0
;         rr_table = round_robin_down
?down
    ldy #0
    lda #<round_robin_down
    sta scratch_ptr
    lda #>round_robin_down
    sta scratch_ptr+1
    
;     target_col = get_next_round_robin(rr_table, x)
?load jsr get_next_round_robin
;     if target_col == c:
;         # don't go back up the same column, skip to next one
;         target_col = get_next_round_robin(rr_table, x)
    cmp c
    bne ?left
    jsr get_next_round_robin

;     if target_col < c:
;         current = TILE_LEFT
?left sta actor_target_col,x
    bcs ?right
    lda #TILE_LEFT
    sta current
    rts

;     else:
;         current = TILE_RIGHT
?right lda #TILE_LEFT
    sta current
    rts
;     actor_target_col[zp.current_actor] = target_col
;     return current
; 
; def check_midpoint(current):
;     # set up decision point flag to see if we have crossed the midpoint
;     # after the movement
;     if current & TILE_VERT:
;         sub = actor_ypixel[zp.current_actor]
;         return sub == Y_MIDPOINT
;     else:
;         sub = actor_xpixel[zp.current_actor]
;         return sub == X_MIDPOINT
check_midpoint nop
    lda current
    and #TILE_VERT
    beq ?lr
    lda actor_ypixel,x
    cmp #Y_MIDPOINT
    beq ?mid
?no lda #0
    rts
?lr lda actor_xpixel,x
    cmp #X_MIDPOINT
    bne ?no
?mid lda #1
    rts

before_midpoint nop
    lda current
    and #TILE_UP
    beq ?down
    lda actor_ypixel,x
    cmp #Y_MIDPOINT
    bcc ?n
    beq ?n
    bcs ?y
?down lda current
    and #TILE_DOWN
    beq ?left
    lda actor_ypixel,x
    cmp #Y_MIDPOINT
    bcc ?y
    bcs ?n
?left lda current
    and #TILE_LEFT
    beq ?right
    lda actor_xpixel,x
    cmp #X_MIDPOINT
    bcc ?n
    beq ?n
    bcs ?y
?right lda current
    and #TILE_RIGHT
    beq ?n
    lda actor_xpixel,x
    cmp #X_MIDPOINT
    bcc ?y
    ;bcs ?n
?n  lda #0
    sta crossed
    rts
?y  lda #1
    sta crossed
    rts

; check if midpoint OR after
crossed_midpoint nop
    lda crossed
    bne ?1
    rts ; immediately abort if already after midpoint
?1  lda current
    and #TILE_UP
    beq ?down
    lda actor_ypixel,x
    cmp #Y_MIDPOINT
    bcc ?y
    beq ?y
    bcs ?n
?down lda current
    and #TILE_DOWN
    beq ?left
    lda actor_ypixel,x
    cmp #Y_MIDPOINT
    bcc ?n
    bcs ?y
?left lda current
    and #TILE_LEFT
    beq ?right
    lda actor_xpixel,x
    cmp #X_MIDPOINT
    bcc ?y
    beq ?y
    bcs ?n
?right lda current
    and #TILE_RIGHT
    beq ?n
    lda actor_xpixel,x
    cmp #X_MIDPOINT
    ; bcc ?n
    bcs ?y
?n  lda #0 ; no
    sta crossed
    rts
?y  lda #1 ; yes
    sta crossed
    rts

; # Move enemy given the enemy index
; def move_enemy():
move_enemy nop
;     current = actor_dir[zp.current_actor]
    lda actor_dir,x
    sta current

;    lda actor_row,x
;    clc
;    adc #1
;    and #$0f
;    sta actor_row,x
;    lda actor_col,x
;    clc
;    adc #1
;    and #$0f
;    sta actor_col,x


; 
;     # check sub-pixel location to see if we've reached a decision point
;     temp = check_midpoint(current)
    jsr before_midpoint

;     pixel_move(current)
    jsr pixel_move

    jsr crossed_midpoint ; save this for later
    lda crossed
    beq move_tile

;         if check_midpoint(current):
;             # crossed the midpoint! Make a decision on the next allowed direction
;             if actor_status[zp.current_actor] == ORBITER_NORMAL:
;                 decide_orbiter()
;             else:
;                 decide_direction()
    lda actor_type,x
    cmp #ORBITER_TYPE
    bne ?dir
    jsr decide_orbiter
    jmp move_tile
?dir jsr decide_direction

move_tile nop
;     # check if moved to next tile. pixel fraction stays the same to keep
;     # the speed consistent, only the pixel gets adjusted
;     if actor_xpixel[zp.current_actor] < 0:
;         actor_col[zp.current_actor] -= 1
;         actor_xpixel[zp.current_actor] += X_TILEMAX
?left lda actor_xpixel,x
    bpl ?right
    dec actor_col,x
    lda actor_xpixel,x
    clc
    adc #X_TILEMAX
    sta actor_xpixel,x
    jmp ?ret

;     elif actor_xpixel[zp.current_actor] >= X_TILEMAX:
;         actor_col[zp.current_actor] += 1
;         actor_xpixel[zp.current_actor] -= X_TILEMAX
?right lda actor_xpixel,x
    cmp #X_TILEMAX
    bcc ?up
    inc actor_col,x
    lda actor_xpixel,x
    sec
    sbc #X_TILEMAX
    sta actor_xpixel,x
    jmp ?ret



;     elif actor_ypixel[zp.current_actor] < 0:
;         actor_row[zp.current_actor] -= 1
;         actor_ypixel[zp.current_actor] += Y_TILEMAX
?up lda actor_ypixel,x
    bpl ?down
    dec actor_row,x
    lda actor_ypixel,x
    clc
    adc #Y_TILEMAX
    sta actor_ypixel,x
    jmp ?ret

;     elif actor_ypixel[zp.current_actor] >= Y_TILEMAX:
;         actor_row[zp.current_actor] += 1
;         actor_ypixel[zp.current_actor] -= Y_TILEMAX
?down lda actor_ypixel,x
    cmp #Y_TILEMAX
    bcc ?ret
    inc actor_row,x
    lda actor_ypixel,x
    sec
    sbc #Y_TILEMAX
    sta actor_ypixel,x

?ret rts

; 
; def pixel_move(current):
pixel_move nop
    lda current

;     if current & TILE_UP:
;         actor_yfrac[zp.current_actor] -= actor_yspeed[zp.current_actor]
;         if actor_yfrac[zp.current_actor] < 0:
;             actor_ypixel[zp.current_actor] -= 1
;             actor_yfrac[zp.current_actor] += 256
?up cmp #TILE_UP
    bne ?down
    lda actor_yfrac,x
    sec
    sbc actor_yspeed_l,x
    sta actor_yfrac,x
    lda actor_ypixel,x
    sbc actor_yspeed_h,x
    sta actor_ypixel,x
    rts

;     elif current & TILE_DOWN:
;         actor_yfrac[zp.current_actor] += actor_yspeed[zp.current_actor]
;         if actor_yfrac[zp.current_actor] > 255:
;             actor_ypixel[zp.current_actor] += 1
;             actor_yfrac[zp.current_actor] -= 256
?down cmp #TILE_DOWN
    bne ?left
    lda actor_yfrac,x
    clc
    adc actor_yspeed_l,x
    sta actor_yfrac,x
    lda actor_ypixel,x
    adc actor_yspeed_h,x
    sta actor_ypixel,x
    rts

;     elif current & TILE_LEFT:
;         actor_xfrac[zp.current_actor] -= actor_xspeed[zp.current_actor]
;         if actor_xfrac[zp.current_actor] < 0:
;             actor_xpixel[zp.current_actor] -= 1
;             actor_xfrac[zp.current_actor] += 256
?left cmp #TILE_LEFT
    bne ?right
    lda actor_xfrac,x
    sec
    sbc actor_xspeed_l,x
    sta actor_xfrac,x
    lda actor_xpixel,x
    sbc actor_xspeed_h,x
    sta actor_xpixel,x
    rts

;     elif current & TILE_RIGHT:
;         actor_xfrac[zp.current_actor] += actor_xspeed[zp.current_actor]
;         if actor_xfrac[zp.current_actor] > 255:
;             actor_xpixel[zp.current_actor] += 1
;             actor_xfrac[zp.current_actor] -= 256
?right cmp #TILE_RIGHT
    bne ?ret
    lda actor_xfrac,x
    clc
    adc actor_xspeed_l,x
    sta actor_xfrac,x
    lda actor_xpixel,x
    adc actor_xspeed_h,x
    sta actor_xpixel,x
?ret rts


; def set_speed(current):
;     if current & TILE_VERT:
;         actor_xspeed[zp.current_actor] = 0
;         actor_yspeed[zp.current_actor] = level_speeds[zp.level]
;     else:
;         actor_xspeed[zp.current_actor] = level_speeds[zp.level]
;         actor_yspeed[zp.current_actor] = 0

; actor in X; clobbers all
set_speed lda actor_dir,x
    and #TILE_VERT
    beq ?1
    lda #0
    sta actor_xspeed_l,x
    sta actor_xspeed_h,x
    ldy level
    lda level_speed_l,y
    sta actor_yspeed_l,x
    lda level_speed_h,y
    sta actor_yspeed_h,x
    rts
?1  lda #0
    sta actor_yspeed_l,x
    sta actor_yspeed_h,x
    ldy level
    lda level_speed_l,y
    sta actor_xspeed_l,x
    lda level_speed_h,y
    sta actor_xspeed_h,x
    rts




; 
; def decide_orbiter():
decide_orbiter nop
;     current = actor_dir[zp.current_actor]
    lda actor_dir,x
    sta current
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
    lda actor_row,x
    sta r
    lda actor_col,x
    sta c
;     allowed = get_allowed_dirs(r, c)
    jsr get_allowed_dirs

;     if allowed & current:
    and current
    beq ?newdir
;         # Can continue the current direction, so keep on doing it
    rts
; 
;         logic_log.debug("orbiter %d: continuing %s" % (zp.current_actor, str_dirs(current)))
;     else:
;         # Can't continue, and because we must be at a corner, turn 90 degrees.
;         # So, if we are moving vertically, go horizontally, and vice versa.
; 
;         if current & TILE_VERT:
;             current = allowed & TILE_HORZ
;         else:
;             current = allowed & TILE_VERT
;         actor_dir[zp.current_actor] = current
;         set_speed(current)

?newdir lda current
    and #TILE_VERT
    beq ?lr

    lda allowed
    and #TILE_HORZ

    sta actor_dir,x
    ; horizontal direction allowed; reset vertical subpixel to be right in the middle
    lda #Y_MIDPOINT
    sta actor_ypixel,x
    lda #0
    sta actor_yfrac,x
    jmp set_speed

?lr lda allowed
    and #TILE_VERT
    sta actor_dir,x
    ; vertial direction allowed; reset horizontal subpixel to be right in the middle
    lda #X_MIDPOINT
    sta actor_xpixel,x
    lda #0
    sta actor_xfrac,x
    jmp set_speed



; def decide_direction():
decide_direction nop
;     current = actor_dir[zp.current_actor]
    lda actor_dir,x
    sta current
    sta last_dir
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
    lda actor_row,x
    sta r
    lda actor_col,x
    sta c
;     allowed = get_allowed_dirs(r, c)
    jsr get_allowed_dirs

;     updown = actor_updown[zp.current_actor]
    lda actor_updown,x
    sta updown
; 
;     allowed_horz = allowed & TILE_HORZ
;     allowed_vert = allowed & TILE_VERT
    lda allowed
    and #TILE_HORZ
    sta allowed_horz
    lda allowed
    and #TILE_VERT
    sta allowed_vert

;     if allowed_horz:
;         # left or right is available, we must go that way, because that's the
;         # Amidar(tm) way
    lda allowed_horz
    beq ?finalize

;         if allowed_horz == TILE_HORZ:
;             # *Both* left and right are available, which means we're either in
;             # the middle of an box horz segment *or* at the top or bottom (but
;             # not at a corner)
    cmp #TILE_HORZ
    bne ?one_horz
; 
;             if allowed_vert:
;                 # At a T junction at the top or bottom. What we do depends on
;                 # which direction we approached from
    lda allowed_vert
    beq ?no_updown
; 
;                 if current & TILE_VERT:
    lda current
    and #TILE_VERT
    beq ?approach_horz
;                     # approaching vertically means go L or R; choose direction
;                     # based on a round robin so the enemy doesn't go back up
;                     # the same path. Sets the target column for this enemy to
;                     # be used when approaching the T horizontally
;                     current = get_target_col(c, allowed_vert)
    jsr get_target_col
    jmp ?finalize
; 
;                     if allowed_vert & TILE_UP:
;                         logic_log.debug("enemy %d: at bot T, new dir %x, col=%d target=%d" % (zp.current_actor, current, c, actor_target_col[zp.current_actor]))
;                     else:
;                         logic_log.debug("enemy %d: at top T, new dir %x, col=%d target=%d" % (zp.current_actor, current, c, actor_target_col[zp.current_actor]))
;                 else:
;                     # approaching horizontally, so check to see if this is the
;                     # vpath to use
; 
;                     if actor_target_col[zp.current_actor] == c:
?approach_horz lda actor_target_col,x
    cmp c
    bne ?skip_vert
;                         # Going vertical! Reverse desired up/down direction
;                         updown = allowed_vert
;                         current = allowed_vert
    lda allowed_vert
    sta updown
    sta current
    jmp ?finalize
; 
;                         if allowed_vert & TILE_UP:
;                             logic_log.debug("enemy %d: at bot T, reached target=%d, going up" % (zp.current_actor, c))
;                         else:
;                             logic_log.debug("enemy %d: at top T, reached target=%d, going down" % (zp.current_actor, c))
;                     else:
;                         # skip this vertical, keep on moving
?skip_vert jmp ?finalize
; 
;                         if allowed_vert & TILE_UP:
;                             logic_log.debug("enemy %d: at bot T, col=%d target=%d; skipping" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
;                         else:
;                             logic_log.debug("enemy %d: at top T, col=%d target=%d; skipping" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
; 
;             else:
;                 # no up or down available, so keep marching on in the same
;                 # direction.
;                 logic_log.debug("enemy %d: no up/down, keep moving %s" % (zp.current_actor, str_dirs(current)))
?no_updown jmp ?finalize

; 
;         else:
?one_horz lda allowed_vert
;             # only one horizontal dir is available
; 
;             if allowed_vert == TILE_VERT:
;                 # At a left or right T junction...
    cmp #TILE_VERT
    bne ?at_corner
; 
;                 if current & TILE_VERT:
;                     # moving vertically. Have to take the horizontal path
;                     current = allowed_horz
;                     logic_log.debug("enemy %d: taking hpath, start moving %s" % (zp.current_actor, str_dirs(current)))
    lda current
    and #TILE_VERT
    beq ?horz_t
    lda allowed_horz
    sta current
    jmp ?finalize

;                 else:
;                     # moving horizontally into the T, forcing a vertical turn.
;                     # Go back to preferred up/down direction
;                     current = updown
;                     logic_log.debug("enemy %d: hpath end, start moving %s" % (zp.current_actor, str_dirs(current)))
?horz_t lda updown
    sta current
    jmp ?finalize

;             else:
;                 # At a corner, because this tile has exactly one vertical and
;                 # one horizontal path.
; 
;                 if current & TILE_VERT:
?at_corner lda current
    and #TILE_VERT
    beq ?horz_top_bot

;                     # moving vertically, and because this is a corner, the
;                     # target column must be set up
;                     current = get_target_col(c, allowed_vert)
    jsr get_target_col
    jmp ?finalize
; 
;                     if allowed_horz & TILE_LEFT:
;                         logic_log.debug("enemy %d: at right corner col=%d, heading left to target=%d" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
;                     else:
;                         logic_log.debug("enemy %d: at left corner col=%d, heading right to target=%d" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
;                 else:
;                     # moving horizontally along the top or bottom. If we get
;                     # here, the target column must also be this column
;                     current = allowed_vert
;                     updown = allowed_vert
?horz_top_bot lda allowed_vert
    sta current
    sta updown
;                     if allowed_vert & TILE_UP:
;                         logic_log.debug("enemy %d: at bot corner col=%d with target %d, heading up" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
;                     else:
;                         logic_log.debug("enemy %d: at top corner col=%d with target=%d, heading down" % (zp.current_actor, c, actor_target_col[zp.current_actor]))
; 
;     elif allowed_vert:
;         # left or right is not available, so we must be in the middle of a
;         # vpath segment. Only thing to do is keep moving
;         logic_log.debug("enemy %d: keep moving %x" % (zp.current_actor, current))
; 
;     else:
;         # only get here when moving into an illegal space
;         logic_log.debug("enemy %d: illegal move to %d,%d" % (zp.current_actor, r, c))
;         current = 0
; 
;     actor_updown[zp.current_actor] = updown
;     actor_dir[zp.current_actor] = current
;     set_speed(current)
?finalize lda updown
    sta actor_updown,x
    lda current
    sta actor_dir,x

    cmp last_dir
    beq ?speed

    ; different directions; reset subpixel
    lda current
    and #TILE_VERT
    bne ?lr
    lda #Y_MIDPOINT
    sta actor_ypixel,x
    lda #0
    sta actor_yfrac,x
    jmp set_speed

?lr lda #X_MIDPOINT
    sta actor_xpixel,x
    lda #0
    sta actor_xfrac,x

?speed jmp set_speed



; def move_player():
move_player nop
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
    lda actor_row,x
    sta r
    lda actor_col,x
    sta c

;     allowed = get_allowed_dirs(r, c)
    jsr get_allowed_dirs
;     current = actor_dir[zp.current_actor]
    lda actor_dir,x
    sta current
;     d = actor_input_dir[zp.current_actor]
    lda actor_input_dir,x
    sta d

;     pad.addstr(26, 0, "r=%d c=%d allowed=%s d=%s current=%s      " % (r, c, str_dirs(allowed), str_dirs(d), str_dirs(current)))
;     if d:
    bne ?1
    rts ; no direction => no movement

;            # player wants to go in an illegal direction. instead, continue in
;            # direction that was last requested
?illegal lda allowed
    and current
    bne ?not_turn_zone
    rts

?1  lda #0
    sta actor_turn_zone,x
    lda actor_xpixel,x
    tay
    lda x_allowed_turn,y
    beq ?not_zone
    lda actor_ypixel,x
    beq ?not_zone
    lda #1
    sta actor_turn_zone,x

;        if allowed & d:
?not_zone lda allowed
    and d
    beq ?illegal
;            # player wants to go in an allowed direction
;            # is desired direction a change in axes?
;            if current & TILE_VERT: # current is vertical
    lda current
    and #TILE_VERT
    beq ?allowed_horz

;                if d & TILE_HORZ: # dir change; wants horizontal
    lda d
    and #TILE_HORZ
    beq ?cur_dir_wants_same_axis

;                    if turn_zone:
;                        actor_ypixel[zp.current_actor] = 3
;                        actor_yfrac[zp.current_actor] = 0
;                        actor_dir[zp.current_actor] = d
;                        set_speed(d)
;                        pixel_move(d)
    lda actor_turn_zone,x
    beq ?not_turn_zone

    lda d
    sta current
    sta actor_dir,x
    lda #Y_MIDPOINT
    sta actor_ypixel,x
    lda #0
    sta actor_yfrac,x
    jsr set_speed
    jmp pixel_move

;                    else: # wants horz but not in turn zone
?not_turn_zone
    lda current
?not_turn_zone2
    sta actor_dir,x
    jsr set_speed
    jsr pixel_move
    jmp move_tile
;                        if current & allowed:
;                            player_log.debug("same")
;                            actor_dir[zp.current_actor] = current
;                            set_speed(current)
;                            pixel_move(current)
;                            move_tile()
;                        else: # opposite of allowed; valid before turn zone
;                            player_log.debug("opposite!")
;                            actor_dir[zp.current_actor] = current
;                            set_speed(current)
;                            pixel_move(current)
;                            move_tile()


;                else: # current vertical, wants vertical, allowed
?cur_dir_wants_same_axis
;                    actor_dir[zp.current_actor] = d
;                    set_speed(d)
;                    pixel_move(d)
;                    move_tile()
    lda d
    jmp ?not_turn_zone2


;            else: # current is horizontal
?allowed_horz
;                if d & TILE_VERT: # dir change; wants vertical
;                    y = actor_ypixel[zp.current_actor]
;                    if y in [2, 3, 4]:
;                        actor_xpixel[zp.current_actor] = 3
;                        actor_xfrac[zp.current_actor] = 0
;                        actor_dir[zp.current_actor] = d
;                        set_speed(d)
;                        pixel_move(d)
;                    else: # wants vert but not in turn zone
;                        if current & allowed:
;                            actor_dir[zp.current_actor] = current
;                            set_speed(current)
;                            pixel_move(current)
;                            move_tile()
;                        else: # opposite of allowed; valid before turn zone
;                            player_log.debug("opposite!")
;                            actor_dir[zp.current_actor] = current
;                            set_speed(current)
;                            pixel_move(current)
;                            move_tile()
;                else: # current horz, wants horz, allowed
;                    actor_dir[zp.current_actor] = d
;                    pixel_move(d)
;                    move_tile()
    lda d
    and #TILE_VERT
    beq ?cur_dir_wants_same_axis

    lda actor_turn_zone,x
    beq ?not_turn_zone

    lda d
    sta current
    sta actor_dir,x
    lda #X_MIDPOINT
    sta actor_xpixel,x
    lda #0
    sta actor_xfrac,x
    jsr set_speed
    jmp pixel_move


; 
; 
; ##### Collision detection
; 
; # Check possible collisions between the current player and any enemies
; def check_collisions():
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
;     enemy_index = FIRST_AMIDAR
;     while enemy_index <= zp.last_enemy:
;         # Will provide pac-man style bug where they could pass through each
;         # other because it's only checking tiles
;         if actor_row[enemy_index] == r and actor_col[enemy_index] == c:
;             start_exploding()
;             break
;         enemy_index += 1
check_collisions nop
    lda actor_row,x
    sta r
    lda actor_col,x
    sta c

    ldy #FIRST_AMIDAR-1
?enemy iny
    lda actor_active,y
    bmi end_collisions ; negative = end
    beq ?enemy ; zero = skip
    lda actor_row,y
    cmp r
    bne ?enemy
    lda actor_col,y
    cmp c
    bne ?enemy

; def start_exploding():
;     actor_status[zp.current_actor] = PLAYER_EXPLODING
;     actor_frame_counter[zp.current_actor] = EXPLODING_TIME
start_exploding lda #PLAYER_EXPLODING
    sta actor_status,x
    lda #EXPLODING_TIME
    sta actor_frame_counter,x

end_collisions rts


