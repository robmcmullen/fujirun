SPRITES = atari-sprite9x11.png apple-sprite9x11.png
CPSPRITES = apple-sprite9x11.png moldy_burger.png
TOHGR = tohgr

all: working.dsk demo.dsk

player-missile.hgr: player-missile.png
	quicksprite.py player-missile.png

kansasfest-hackfest.hgr: kansasfest-hackfest.png
	cp kansasfest-hackfest.png _apple2-kansasfest-hackfest-top.png
	$(TOHGR) _apple2-kansasfest-hackfest-top.png
	cp kansasfest-hackfest.png _apple2-kansasfest-hackfest-bot.png
	quicksprite.py -i bw _apple2-kansasfest-hackfest-bot.png
	quicksprite.py --merge 96 -o kansasfest-hackfest _apple2-kansasfest-hackfest-top.hgr _apple2-kansasfest-hackfest-bot.hgr

partycrasher-software.hgr: partycrasher-software.png
	cp partycrasher-software.png _apple2-partycrasher-software-top.png
	$(TOHGR) _apple2-partycrasher-software-top.png
	cp partycrasher-software.png _apple2-partycrasher-software-bot.png
	quicksprite.py -i bw _apple2-partycrasher-software-bot.png
	quicksprite.py --merge 116 -o partycrasher-software _apple2-partycrasher-software-top.hgr _apple2-partycrasher-software-bot.hgr

title.hgr: title.png
	cp title.png _apple2-title-top.png
	$(TOHGR) _apple2-title-top.png
	cp title.png _apple2-title-bot.png
	quicksprite.py -i bw _apple2-title-bot.png
	quicksprite.py --merge 136 167 -o title _apple2-title-top.hgr _apple2-title-bot.hgr

_apple2-working-sprite-driver.s: $(SPRITES) fatfont128.dat
	quicksprite.py -a mac65 -p 6502 -s hgrbw -m -k -d -g -f fatfont128.dat -o _apple2-working $(SPRITES)

_apple2-working.xex: wipes-null.s main.s constants.s rand.s maze.s _apple2-working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s platform-apple2.s
	rm -f _apple2-working.xex
	echo '.include "main.s"' > _apple2-working.s
	echo '.include "wipes-null.s"' >> _apple2-working.s
	echo '.include "platform-apple2.s"' >> _apple2-working.s
	atasm -mae -o_apple2-working.xex _apple2-working.s -L_apple2-working.var -g_apple2-working.lst

working.dsk: _apple2-working.xex
	rm -f working.dsk
	atrcopy working.dsk boot -b _apple2-working.xex --brun 6000 -f
	#cp working.var /home/rob/.wine/drive_c/applewin/APPLE2E.SYM

_apple2-demo.xex: wipes-demo.s main.s constants.s rand.s maze.s _apple2-working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s platform-apple2.s
	rm -f _apple2-demo.xex
	echo '.include "main.s"' > _apple2-demo.s
	echo '.include "wipes-demo.s"' >> _apple2-demo.s
	echo '.include "platform-apple2.s"' >> _apple2-demo.s
	atasm -mae -o_apple2-demo.xex _apple2-demo.s -L_apple2-demo.var -g_apple2-demo.lst

demo.dsk: _apple2-demo.xex logic.s player-missile.hgr partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	atrcopy demo.dsk boot -d partycrasher-software.hgr@2000 player-missile.hgr@4000 kansasfest-hackfest.hgr@2000 title.hgr@4001 -b _apple2-demo.xex --brun 6000 -f

clean:
	rm -f player-missile.hgr player-missile.hgr.png partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	rm -f _apple2-* working.dsk demo.dsk
	rm -f *.lst *.var
