SPRITES = atari-sprite9x11.png apple-sprite9x11.png
CPSPRITES = apple-sprite9x11.png moldy_burger.png

all: cpbg.dsk titles.dsk working.dsk demo.dsk

cpbg-sprite-driver.s: $(CPSPRITES)
	quicksprite.py -a mac65 -p 6502 -s hgrbw -m -k -d -g -f fatfont128.dat -o cpbg $(CPSPRITES)

cpbg.xex: cpbg.s cpbg-sprite-driver.s
	atasm -mae -ocpbg.xex cpbg.s -Lcpbg.var -gcpbg.lst

cpbg.dsk: cpbg.xex
	atrcopy cpbg.dsk boot -b cpbg.xex --brun 6000 -f

player-missile.hgr: player-missile.png
	quicksprite.py player-missile.png

kansasfest-hackfest.hgr: kansasfest-hackfest.png
	cp kansasfest-hackfest.png tmphgr-kansasfest-hackfest-top.png
	../tohgr-source/tohgr tmphgr-kansasfest-hackfest-top.png
	cp kansasfest-hackfest.png tmphgr-kansasfest-hackfest-bot.png
	quicksprite.py -i bw tmphgr-kansasfest-hackfest-bot.png
	quicksprite.py --merge 96 -o kansasfest-hackfest tmphgr-kansasfest-hackfest-top.hgr tmphgr-kansasfest-hackfest-bot.hgr

partycrasher-software.hgr: partycrasher-software.png
	cp partycrasher-software.png tmphgr-partycrasher-software-top.png
	../tohgr-source/tohgr tmphgr-partycrasher-software-top.png
	cp partycrasher-software.png tmphgr-partycrasher-software-bot.png
	quicksprite.py -i bw tmphgr-partycrasher-software-bot.png
	quicksprite.py --merge 116 -o partycrasher-software tmphgr-partycrasher-software-top.hgr tmphgr-partycrasher-software-bot.hgr

title.hgr: title.png
	#../tohgr-source/tohgr title.png
	cp title.png tmphgr-title-top.png
	../tohgr-source/tohgr tmphgr-title-top.png
	cp title.png tmphgr-title-bot.png
	quicksprite.py -i bw tmphgr-title-bot.png
	quicksprite.py --merge 136 167 -o title tmphgr-title-top.hgr tmphgr-title-bot.hgr

titles.dsk: cpbg.xex player-missile.hgr partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	#atrcopy titles.dsk boot -d kansasfest-hackfest.hgr@2000 player-missile.hgr@4000 partycrasher-software.hgr@2000 -b cpbg.xex --brun 6000 -f
	atrcopy titles.dsk boot -d title.hgr@2000 -b cpbg.xex --brun 6000 -f

working-sprite-driver.s: $(SPRITES) fatfont128.dat
	quicksprite.py -a mac65 -p 6502 -s hgrbw -m -k -d -g -f fatfont128.dat -o working $(SPRITES)

working.xex: working.s rand.s maze.s working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s
	rm -f working.xex
	atasm -mae -oworking.xex working.s -Lworking.var -gworking.lst

working.dsk: working.xex
	rm -f working.dsk
	atrcopy working.dsk boot -b working.xex --brun 6000 -f
	cp working.var /home/rob/.wine/drive_c/applewin/APPLE2E.SYM

demo.dsk: working.s rand.s maze.s working-sprite-driver.s vars.s debug.s actors.s background.s screen.s logic.s player-missile.hgr partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	atrcopy demo.dsk boot -d kansasfest-hackfest.hgr@2000 player-missile.hgr@4000 partycrasher-software.hgr@2000 -b working.xex --brun 6000 -f

clean:
	rm -f cpbg.dsk cpbg.xex cpbg.var cpbg.lst cpbg-sprite-driver.s cpbg-bwsprite.s cpbg-hgrcols-7x1.s cpbg-hgrrows.s cpbg-apple_sprite9x11.s cpbg-fastfont.s cpbg-moldy_burger.s
	rm -f titles.dsk
	rm -f player-missile.hgr player-missile.hgr.png partycrasher-software.hgr kansasfest-hackfest.hgr title.hgr
	rm -f tmphgr-*
	rm -f working.dsk working.xex working-*.s
