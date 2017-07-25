    *= $800

actor_col .ds MAX_ACTORS  ; #  current tile column
actor_x .ds MAX_ACTORS  ; pixel position (calculated from col & xpixel)
actor_row .ds MAX_ACTORS  ; #  current tile row
actor_y .ds MAX_ACTORS  ; pixel position (calculated from row & ypixel)
actor_xpixel .ds MAX_ACTORS  ; #  current pixel offset in col
actor_xfrac .ds MAX_ACTORS  ; #  current fractional pixel
actor_xspeed_l .ds MAX_ACTORS  ; #  current speed (affects fractional)
actor_xspeed_h .ds MAX_ACTORS  ; #  current speed (affects pixel)
actor_ypixel .ds MAX_ACTORS  ; #  current pixel offset in row
actor_yfrac .ds MAX_ACTORS  ; #  current fractional pixel
actor_yspeed_l .ds MAX_ACTORS  ; #  current speed (affects fractional)
actor_yspeed_h .ds MAX_ACTORS  ; #  current speed (affects pixel)
actor_updown .ds MAX_ACTORS  ; #  preferred direction
actor_dir .ds MAX_ACTORS  ; #  actual direction
actor_target_col .ds MAX_ACTORS  ; #  target column at bot or top T
actor_status .ds MAX_ACTORS  ; #  alive, exploding, dead, regenerating, invulnerable, ???
actor_frame_counter .ds MAX_ACTORS  ; #  frame counter for sprite changes
actor_input_dir .ds MAX_ACTORS  ; #  current joystick input direction
actor_active .ds MAX_ACTORS ; 1 = active, 0 = skip, $ff = end
actor_l .ds MAX_ACTORS  ; address (low byte) of compiled sprite
actor_h .ds MAX_ACTORS  ; address (high byte)
actor_turn_zone .ds MAX_ACTORS ; debugging; is player in turn zone:

player_score  .ds MAX_PLAYERS
player_next_target_score  .ds MAX_PLAYERS
player_lives  .ds MAX_PLAYERS  ; # lives remaining

amidar_start_col .ds VPATH_NUM
round_robin_up  .ds VPATH_NUM
round_robin_down  .ds VPATH_NUM

; after player completes a box, this data is used to fill it in subsequent
; frames. This list tracks the left column (right is always a fixed distance
; away) and starting and ending rows
box_painting_c .ds MAX_BOX_PAINTING
box_painting_r1 .ds MAX_BOX_PAINTING
box_painting_r2 .ds MAX_BOX_PAINTING
box_painting_actor .ds MAX_BOX_PAINTING
