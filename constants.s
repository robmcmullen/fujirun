; game configuration
STARTING_LIVES = 3
BONUS_LIFE = 10000
MAX_LIVES = 8

WIPE_DELAY = 40

; tile size definition. On apple, it's a 7x8 tile. Atari is 8x8
X_MIDPOINT = 3
X_TILEMAX = 7
Y_MIDPOINT = 3
Y_TILEMAX = 8

; screen size
MAXPOSX     = 220
MAXPOSY     = 192 - 16

; player/enemy states
NOT_VISIBLE = 0
PLAYER_DEAD = 1
PLAYER_ALIVE = 2
PLAYER_EXPLODING = 3
PLAYER_REGENERATING = 4
AMIDAR_NORMAL = 5
ORBITER_NORMAL = 6
GAME_OVER = 255

EXPLODING_TIME = 10
DEAD_TIME = 10
REGENERATING_TIME = 120
END_GAME_TIME = 100
TITLE_SCREEN_TIME = 100

; memory map
; BF00 - BFFF: damage for page 1
; BE00 - BEFF: damage for page 2
; BD00 - BDFF: level box storage
; BC00 - BCFF: text damage
; constants

DAMAGEPAGE1 = $bf   ; page number of damage list for screen 1
DAMAGEPAGE2 = $be   ;   "" for screen 2
LEVEL_BOXES = $bd00
TEXTDAMAGE = $bc00

; tiles
TILE_DOWN = $1
TILE_UP = $2
TILE_RIGHT = $4
TILE_LEFT= $8
TILE_HORZ = TILE_LEFT|TILE_RIGHT
TILE_VERT = TILE_UP|TILE_DOWN
DIR_MASK = $0f
TILE_DOT = $10
CLEAR_TILE_DOT = $ef ;%11101111

LEFT_TILE = TILE_DOT|TILE_RIGHT
MIDDLE_TILE = TILE_DOT|TILE_LEFT|TILE_RIGHT
RIGHT_TILE = TILE_DOT|TILE_LEFT

; maze
VPATH_NUM = 6
BOX_WIDTH = 5
VPATH_COL_SPACING = BOX_WIDTH + 1
MAX_BOX_PAINTING = 16

; screen is 24 rows, 0 - 23, of which 1-22 are used in the playfield.
MAZE_TOP_ROW = 1
MAZE_BOT_ROW = 22
SCREEN_ROWS = 24

;# Screen has cols 0 - 39
;# cols 0 - 32 are the maze, of which 1 - 31 are actually used
;#  0 and 32 are border tiles having the value zero
;# cols 33 - 39 is the score area
MAZE_LEFT_COL = 1
MAZE_RIGHT_COL = 31
MAZE_PANEL_COL = 33
MAZE_SCORE_COL = 35 ; 5 digits for score
SCREEN_COLS = 40

;# Orbiter goes around the outside border, but not through the maze
ORBITER_START_COL = MAZE_RIGHT_COL
ORBITER_START_ROW = 2

;# sprites all use the same table. In the sample configuration, sprites 0 - 3
;# are players, 4 and above are enemies. One is an orbiter enemy, the rest use
;# amidar movement.
MAX_PLAYERS = 4
MAX_AMIDARS = VPATH_NUM + 1  ; # one enemy per vpath + one orbiter
;MAX_ACTORS = MAX_PLAYERS + MAX_AMIDARS
MAX_ACTORS = 16
FIRST_PLAYER = 0
FIRST_AMIDAR = MAX_PLAYERS
LAST_PLAYER = FIRST_AMIDAR - 1
LAST_AMIDAR = LAST_PLAYER + MAX_AMIDARS
