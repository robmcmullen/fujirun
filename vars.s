    *= $800

amidar_start_col .ds VPATH_NUM
round_robin_up  .ds VPATH_NUM
round_robin_down  .ds VPATH_NUM

actor_col .ds MAX_ACTORS  ; #  current tile column
actor_xpixel .ds MAX_ACTORS  ; #  current pixel offset in col
actor_xfrac .ds MAX_ACTORS  ; #  current fractional pixel
actor_xspeed .ds MAX_ACTORS  ; #  current speed (affects fractional)
actor_row .ds MAX_ACTORS  ; #  current tile row
actor_ypixel .ds MAX_ACTORS  ; #  current pixel offset in row
actor_yfrac .ds MAX_ACTORS  ; #  current fractional pixel
actor_yspeed .ds MAX_ACTORS  ; #  current speed (affects fractional)
actor_updown .ds MAX_ACTORS  ; #  preferred direction
actor_dir .ds MAX_ACTORS  ; #  actual direction
actor_target_col .ds MAX_ACTORS  ; #  target column at bot or top T
actor_status .ds MAX_ACTORS  ; #  alive, exploding, dead, regenerating, invulnerable, ???
actor_frame_counter .ds MAX_ACTORS  ; #  frame counter for sprite changes
actor_input_dir .ds MAX_ACTORS  ; #  current joystick input direction

dot_eaten_row  .ds 4 ; # dot eaten by player
dot_eaten_col  .ds 4
player_score  .ds 4
player_next_target_score  .ds 4
player_lives  .ds 4  ; # lives remaining
