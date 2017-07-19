fatfont_maze
;    curseschars = [
;        curses.ACS_CKBOARD,  # illegal
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_VLINE,  # 3: up/down
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_ULCORNER,  # 5: down/right
;        curses.ACS_LLCORNER,  # 6: up/right
;        curses.ACS_LTEE,  # 7: up/down/right
;        curses.ACS_CKBOARD,
;        curses.ACS_URCORNER,  # 9: left/down
;        curses.ACS_LRCORNER,  # 10: left/up
;        curses.ACS_RTEE,  # 11: left/up/down
;        curses.ACS_HLINE,  # 12: left/right
;        curses.ACS_TTEE,  # 13: left/right/down
;        curses.ACS_BTEE,  # 14: left/right/up
;        curses.ACS_CKBOARD,
;
;        # And same again, with dots
;        curses.ACS_CKBOARD,  # illegal
;        curses.ACS_CKBOARD,
;        curses.ACS_CKBOARD,
;        curses.ACS_VLINE,  # 3: up/down
;        curses.ACS_CKBOARD,
;        curses.ACS_ULCORNER,  # 5: down/right
;        curses.ACS_LLCORNER,  # 6: up/right
;        curses.ACS_LTEE,  # 7: up/down/right
;        curses.ACS_CKBOARD,
;        curses.ACS_URCORNER,  # 9: left/down
;        curses.ACS_LRCORNER,  # 10: left/up
;        curses.ACS_RTEE,  # 11: left/up/down
;        curses.ACS_HLINE,  # 12: left/right
;        curses.ACS_TTEE,  # 13: left/right/down
;        curses.ACS_BTEE,  # 14: left/right/up
;        curses.ACS_CKBOARD,
;    ]

    .byte %
