TARGETS = INSANECLEAR.BIN FASTEST.BIN SETSCRN.BIN NORMAL.BIN NORMALSMC.BIN FASTCLEAR.BIN NORMALINCFONT.BIN NORMALAL31.BIN SETSCRNSMC.BIN COMPILED.BIN

all: $(TARGETS)

kfest.dsk:
	atrcopy kfest.dsk create dos33.dsk
	atrcopy kfest.dsk add TEST.BAS
	atrcopy kfest.dsk add FONT.DAT

COMPILED.BIN: driver.s fontcompiled.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

FASTEST.BIN: driver.s fastfont.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

SETSCRN.BIN: setscrn.s
	rm -f $@
	atrcopy . assemble -f -s $< -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

SETSCRNSMC.BIN: setscrnsmc.s
	rm -f $@
	atrcopy . assemble -f -s $< -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

NORMAL.BIN: driver.s normal.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

NORMALINCFONT.BIN: driver.s normalincfont.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

NORMALAL31.BIN: driver.s normalal31.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

NORMALSMC.BIN: driver.s normalsmc.s
	rm -f $@
	cat $^ > temp.s
	atrcopy . assemble -f -d fatfont128.dat@0x6000 -s temp.s -r 0x5000 -o $@
	atrcopy kfest.dsk add $@ -f
	rm -f apple2auto.state

FASTCLEAR.BIN: fastclear.s
	rm -f $@
	cat fastclear.s > temp.s
	atrcopy . assemble -f -s fastclear.s -r 0x5000 -o FASTCLEAR.BIN
	atrcopy kfest.dsk add FASTCLEAR.BIN -f
	rm -f apple2auto.state

INSANECLEAR.BIN: insaneclear.s
	rm -f $@
	cat insaneclear.s > temp.s
	atrcopy . assemble -f -s insaneclear.s -r 0x4000 -o INSANECLEAR.BIN
	atrcopy insaneclear.dsk boot -b INSANECLEAR.BIN --brun 4000 -f
	rm -f apple2auto.state

clean:
	rm -f kfest.dsk insaneclear.dsk $(TARGETS)

reallyclean: clean
	rm -f player-missile.hgr player-missile-2.hgr kansasfest-hackfest.hgr title.hgr