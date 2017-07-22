EXPLODING_TIME = 50
DEAD_TIME = 40
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


get_sprite nop
; update pixel position
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
;     target_col = rr_table[zp.round_robin_index[x]]
;     logic_log.debug("target: %d, indexes=%s, table=%s" % (target_col, str(zp.round_robin_index), rr_table))
;     zp.round_robin_index[x] += 1
;     if zp.round_robin_index[x] >= VPATH_NUM:
;         zp.round_robin_index[x] = 0
;     return target_col
; 
; # Find target column when enemy reaches top or bottom
; def get_target_col(c, allowed_vert):
;     if allowed_vert & TILE_UP:
;         x = 1
;         rr_table = round_robin_up
;     else:
;         x = 0
;         rr_table = round_robin_down
; 
;     target_col = get_next_round_robin(rr_table, x)
;     if target_col == c:
;         # don't go back up the same column, skip to next one
;         target_col = get_next_round_robin(rr_table, x)
; 
;     if target_col < c:
;         current = TILE_LEFT
;     else:
;         current = TILE_RIGHT
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
    jsr check_midpoint
    sta tempcheck

;     pixel_move(current)
    jsr pixel_move
;     # check if moved to next tile. pixel fraction stays the same to keep
;     # the speed consistent, only the pixel gets adjusted
;     if actor_xpixel[zp.current_actor] < 0:
;         actor_col[zp.current_actor] -= 1
;         actor_xpixel[zp.current_actor] += X_TILEMAX
    lda actor_xpixel,x
    bpl ?right
    dec actor_col,x
    lda actor_xpixel,x
    clc
    adc #X_TILEMAX
    sta actor_xpixel,x
    jmp ?mid

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
    jmp ?mid



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
    jmp ?mid

;     elif actor_ypixel[zp.current_actor] >= Y_TILEMAX:
;         actor_row[zp.current_actor] += 1
;         actor_ypixel[zp.current_actor] -= Y_TILEMAX
?down lda actor_ypixel,x
    cmp #X_TILEMAX
    bcc ?ret
    inc actor_row,x
    lda actor_ypixel,x
    sec
    sbc #Y_TILEMAX
    sta actor_ypixel,x

;     s = "#%d: tile=%d,%d pix=%d,%d frac=%d,%d  " % (zp.current_actor, actor_col[zp.current_actor], actor_row[zp.current_actor], actor_xpixel[zp.current_actor], actor_ypixel[zp.current_actor], actor_xfrac[zp.current_actor], actor_yfrac[zp.current_actor])
;     logic_log.debug(s)
;     pad.addstr(0 + zp.current_actor, 40, s)
;     if not temp:
?mid lda tempcheck ; check if crossing onto midpoint
    bne ?ret ; nope, already on midpoint so must have checked last time

    jsr check_midpoint
    beq ?ret ; nope, still not on midpoint
;         if check_midpoint(current):
;             # crossed the midpoint! Make a decision on the next allowed direction
;             if actor_status[zp.current_actor] == ORBITER_NORMAL:
;                 decide_orbiter()
;             else:
;                 decide_direction()
    lda actor_status,x
    cmp #ORBITER_NORMAL
    bne ?dir
    jmp decide_orbiter
?dir jmp decide_direction
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
    sbc actor_yspeed,x
    sta actor_yfrac,x
    bcs ?ret
    dec actor_ypixel,x ; haha! Don't have to adjust yfrac because it's only 8 bits!
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
    adc actor_yspeed,x
    sta actor_yfrac,x
    bcc ?ret
    inc actor_ypixel,x
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
    sbc actor_xspeed,x
    sta actor_xfrac,x
    bcs ?ret
    dec actor_xpixel,x
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
    adc actor_xspeed,x
    sta actor_xfrac,x
    bcc ?ret
    inc actor_xpixel,x
?ret rts


; def set_speed(current):
;     if current & TILE_VERT:
;         actor_xspeed[zp.current_actor] = 0
;         actor_yspeed[zp.current_actor] = level_speeds[zp.level]
;     else:
;         actor_xspeed[zp.current_actor] = level_speeds[zp.level]
;         actor_yspeed[zp.current_actor] = 0

; direction in A, actor in X; clobbers all
set_speed nop
    and #TILE_VERT
    beq ?1
    lda #0
    sta actor_xspeed,x
    ldy level
    lda level_speeds,y
    sta actor_yspeed,x
    rts
?1  lda #0
    sta actor_yspeed,x
    ldy level
    lda level_speeds,y
    sta actor_xspeed,x
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
    bne ?set
?lr lda allowed
    and #TILE_VERT
?set sta actor_dir,x
    jmp set_speed



; def decide_direction():
decide_direction nop
    rts
;     current = actor_dir[zp.current_actor]
;     r = actor_row[zp.current_actor]
;     c = actor_col[zp.current_actor]
;     allowed = get_allowed_dirs(r, c)
;     updown = actor_updown[zp.current_actor]
; 
;     allowed_horz = allowed & TILE_HORZ
;     allowed_vert = allowed & TILE_VERT
;     if allowed_horz:
;         # left or right is available, we must go that way, because that's the
;         # Amidar(tm) way
; 
;         if allowed_horz == TILE_HORZ:
;             # *Both* left and right are available, which means we're either in
;             # the middle of an box horz segment *or* at the top or bottom (but
;             # not at a corner)
; 
;             if allowed_vert:
;                 # At a T junction at the top or bottom. What we do depends on
;                 # which direction we approached from
; 
;                 if current & TILE_VERT:
;                     # approaching vertically means go L or R; choose direction
;                     # based on a round robin so the enemy doesn't go back up
;                     # the same path. Sets the target column for this enemy to
;                     # be used when approaching the T horizontally
;                     current = get_target_col(c, allowed_vert)
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
;                         # Going vertical! Reverse desired up/down direction
;                         updown = allowed_vert
;                         current = allowed_vert
; 
;                         if allowed_vert & TILE_UP:
;                             logic_log.debug("enemy %d: at bot T, reached target=%d, going up" % (zp.current_actor, c))
;                         else:
;                             logic_log.debug("enemy %d: at top T, reached target=%d, going down" % (zp.current_actor, c))
;                     else:
;                         # skip this vertical, keep on moving
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
; 
;         else:
;             # only one horizontal dir is available
; 
;             if allowed_vert == TILE_VERT:
;                 # At a left or right T junction...
; 
;                 if current & TILE_VERT:
;                     # moving vertically. Have to take the horizontal path
;                     current = allowed_horz
;                     logic_log.debug("enemy %d: taking hpath, start moving %s" % (zp.current_actor, str_dirs(current)))
;                 else:
;                     # moving horizontally into the T, forcing a vertical turn.
;                     # Go back to preferred up/down direction
;                     current = updown
;                     logic_log.debug("enemy %d: hpath end, start moving %s" % (zp.current_actor, str_dirs(current)))
;             else:
;                 # At a corner, because this tile has exactly one vertical and
;                 # one horizontal path.
; 
;                 if current & TILE_VERT:
;                     # moving vertically, and because this is a corner, the
;                     # target column must be set up
;                     current = get_target_col(c, allowed_vert)
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
    beq ?end
;         if allowed & d:
    and allowed
    beq ?illegal
;             # player wants to go in an allowed direction, so go!
;             actor_dir[zp.current_actor] = d
;             r, c = get_next_tile(r, c, d)
;             actor_row[zp.current_actor] = r
;             actor_col[zp.current_actor] = c
    lda d
    sta actor_dir,x
    jmp ?continue

;         else:
;             # player wants to go in an illegal direction. instead, continue in
;             # direction that was last requested
; 
;             if allowed & current:
;                 r, c = get_next_tile(r, c, current)
;                 actor_row[zp.current_actor] = r
;                 actor_col[zp.current_actor] = c
?illegal lda allowed
    and current
    bne ?continue
    rts

?continue jsr get_next_tile
    lda r
    sta actor_row,x
    lda c
    sta actor_col,x

?end rts


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
    cpy r
    beq start_exploding
    lda actor_col,y
    cpy c
    bne ?enemy

; def start_exploding():
;     actor_status[zp.current_actor] = PLAYER_EXPLODING
;     actor_frame_counter[zp.current_actor] = EXPLODING_TIME
start_exploding lda #PLAYER_EXPLODING
    sta actor_status,x
    lda #EXPLODING_TIME
    sta actor_frame_counter,x

end_collisions rts


