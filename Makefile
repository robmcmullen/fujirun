SPRITES = atari-sprite9x11.png apple-sprite9x11.png
CPSPRITES = apple-sprite9x11.png moldy_burger.png
TOHGR = tohgr

all: working.dsk demo.dsk

player-missile.hgr: player-missile.png
	quicksprite.py player-missile.png

kansasfest-hackfest.hgr: kansasfest-hackfest.png
	cp kansasfest-hackfest.png tmphgr-kansasfest-hackfest-top.png
	$(TOHGR) tmphgr-kansasfest-hackfest-top.png
	cp kansasfest-hackfest.png tmphgr-kansasfest-hackfest-bot.png
	quicksprite.py -i bw tmphgr-kansasfest-hackfest-bot.png
	quicksprite.py --merge 96 -o kansasfest-hackfest tmphgr-kansasfest-hackfest-top.hgr tmphgr-kansasfest-hackfest-bot.hgr

partycrasher-software.hgr: partycrasher-software.png
	cp partycrasher-software.png tmphgr-partycrasher-software-top.png
	$(TOHGR) tmphgr-partycrasher-software-top.png
	cp partycrasher-software.png tmphgr-partycrasher-software-bot.png
	quicksprite.py -i bw tmphgr-partycrasher-software-bot.png
	quicksprite.py --merge 116 -o partycrasher-software tmphgr-partycrasher-software-top.hgr tmphgr-partycrasher-software-bot.hgr

title.hgr: title.png
	cp title.png tmphgr-title-top.png
	$(TOHGR) tmphgr-title-top.png
	cp title.png tmphgr-title-bot.png
	quicksprite.py -i bw tmphgr-title-bot.png
	quicksprite.py --merge 136 167 -o title tmphgr-title-top.hgr tmphgr-title-bot.hgr

working-sprite-driver.s: $(SPRITES) fatfont128.dat
	quicksprite.py -a mac65 -p 6502 -s hgrbw -m -k -d -g -f fatfont128.dat -o working $(SPRITES)

working.xex: working.s wipes-null.s main.s constants.s rand.s maze.s working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s
	rm -f working.xex
	atasm -mae -oworking.xex working.s -Lworking.var -gworking.lst

working.dsk: working.xex
	rm -f working.dsk
	atrcopy working.dsk boot -b working.xex --brun 6000 -f
	#cp working.var /home/rob/.wine/drive_c/applewin/APPLE2E.SYM

demo.xex: demo.s wipes-demo.s main.s constants.s rand.s maze.s working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s
	rm -f demo.xex
	atasm -mae -odemo.xex demo.s -Ldemo.var -gdemo.lst

demo.dsk: demo.xex logic.s player-missile.hgr partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	atrcopy demo.dsk boot -d partycrasher-software.hgr@2000 player-missile.hgr@4000 kansasfest-hackfest.hgr@2000 title.hgr@4001 -b demo.xex --brun 6000 -f

clean:
	rm -f player-missile.hgr player-missile.hgr.png partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	rm -f tmphgr-*
	rm -f working.dsk working.xex working-*.s
	rm -f demo.dsk demo.xex
	rm -f *.lst *.var
