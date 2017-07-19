; these characters will be reversed using Omnivore, so the bits are as
; they will appear on screen, not reversed as in screen memory. Bit 9
; is the "high bit" for the palette selection, as defined below.

    *= $b000

fatfont_maze
;    curseschars = [
;        curses.ACS_CKBOARD,  # illegal
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_VLINE,  # 3: up/down
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_ULCORNER,  # 5: down/right
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00101010
    .byte %00101010
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_LLCORNER,  # 6: up/right
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101010
    .byte %00101010
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_LTEE,  # 7: up/down/right
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %00101010
    .byte %00101010
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_URCORNER,  # 9: left/down
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %10101000
    .byte %10101000
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_LRCORNER,  # 10: left/up
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %10101000
    .byte %10101000
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_RTEE,  # 10: left/up/down
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %10101000
    .byte %10101000
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_HLINE,  # 12: left/right
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %10101010
    .byte %10101010
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_TTEE,  # 13: left/right/down
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %10101010
    .byte %10101010
    .byte %00101000
    .byte %00101000
    .byte %00101000

;        curses.ACS_BTEE,  # 14: left/right/up
    .byte %00101000
    .byte %00101000
    .byte %00101000
    .byte %10101010
    .byte %10101010
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_HLINE,  # 15: alternate left/right
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %01010100
    .byte %01010100
    .byte %00000000
    .byte %00000000
    .byte %00000000






;        # And same again, with dots




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
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %00111110
    .byte %00111110
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_LLCORNER,  # 6: up/right
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111110
    .byte %00111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_LTEE,  # 7: up/down/right
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %00111111
    .byte %00111111
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0

;        curses.ACS_URCORNER,  # 9: left/down
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111000
    .byte %11111000
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_LRCORNER,  # 10: left/up
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %11111000
    .byte %11111000
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_RTEE,  # 11: left/up/down
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %11111000
    .byte %11111000
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_HLINE,  # 12: left/right
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111110
    .byte %11111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_TTEE,  # 13: left/right/down
    .byte %00000000
    .byte %00000000
    .byte %00000000
    .byte %11111110
    .byte %11111110
    .byte %00111000
    .byte %00111000
    .byte %00111000

;        curses.ACS_BTEE,  # 14: left/right/up
    .byte %00111000
    .byte %00111000
    .byte %00111000
    .byte %11111110
    .byte %11111110
    .byte %00000000
    .byte %00000000
    .byte %00000000

;        curses.ACS_CKBOARD,
    .byte 0,0,0,0,0,0,0,0


