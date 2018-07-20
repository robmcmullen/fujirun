
all: INSANECLEAR.BIN FASTEST.BIN SETSCRN.BIN NORMAL.BIN NORMALSMC.BIN FASTCLEAR.BIN NORMALINCFONT.BIN NORMALAL31.BIN

FASTEST.BIN: driver.s fastfont.s
	rm -f fastest.xex
	cat driver.s fastfont.s > temp.s
	atrcopy . assemble -f -s temp.s -r 0x5000 -o FASTEST.BIN
	atrcopy kfest.dsk add FASTEST.BIN -f
	rm -f apple2auto.state

SETSCRN.BIN: setscrn.s
	rm -f setscrn.bin
	cat setscrn.s > temp.s
	atrcopy . assemble -f -s temp.s -r 0x5000 -o SETSCRN.BIN
	atrcopy kfest.dsk add SETSCRN.BIN -f
	rm -f apple2auto.state

NORMAL.BIN: driver.s normal.s
	cat driver.s normal.s > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o NORMAL.BIN
	atrcopy kfest.dsk add NORMAL.BIN -f
	rm -f apple2auto.state

NORMALINCFONT.BIN: driver.s normalincfont.s
	cat driver.s normalincfont.s > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o NORMALINCFONT.BIN
	atrcopy kfest.dsk add NORMALINCFONT.BIN -f
	rm -f apple2auto.state

NORMALAL31.BIN: driver.s normalal31.s
	cat driver.s normalal31.s > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o NORMALAL31.BIN
	atrcopy kfest.dsk add NORMALAL31.BIN -f
	rm -f apple2auto.state

NORMALSMC.BIN: driver.s normalsmc.s
	cat driver.s normalsmc.s > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o NORMALSMC.BIN
	atrcopy kfest.dsk add NORMALSMC.BIN -f
	rm -f apple2auto.state

FASTCLEAR.BIN: fastclear.s
	cat fastclear.s > temp.s
	atrcopy . assemble -f -s fastclear.s -r 0x5000 -o FASTCLEAR.BIN
	atrcopy kfest.dsk add FASTCLEAR.BIN -f
	rm -f apple2auto.state

INSANECLEAR.BIN: insaneclear.s
	cat insaneclear.s > temp.s
	atrcopy . assemble -f -s insaneclear.s -r 0x4000 -o INSANECLEAR.BIN
	atrcopy insaneclear.dsk boot -b INSANECLEAR.BIN --brun 4000 -f
	rm -f apple2auto.state

clean:
	rm -f working.dsk

reallyclean: clean
	rm -f player-missile.hgr player-missile-2.hgr kansasfest-hackfest.hgr title.hgr