COLORSPRITE = moldy_burger.png
BWSPRITE = apple-sprite9x11.png

all: cpbg.dsk titles.dsk working.dsk

cpbg-sprite-driver.s: $(BWSPRITE)
	quicksprite.py -a mac65 -p 6502 -s hgrbw -m -k -d -g -f fatfont128.dat -o cpbg $(BWSPRITE) $(COLORSPRITE)

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

titles.dsk: cpbg.xex player-missile.hgr partycrasher-software.hgr kansasfest-hackfest.hgr
	atrcopy titles.dsk boot -d kansasfest-hackfest.hgr@2000 player-missile.hgr@4000 partycrasher-software.hgr@2000 -b cpbg.xex --brun 6000 -f

working.xex: working.s rand.s
	rm -f working.xex
	atasm -mae -oworking.xex working.s -Lworking.var -gworking.lst

working.dsk: working.xex
	rm -f working.dsk
	atrcopy working.dsk boot -b working.xex --brun 6000 -f

clean:
	rm -f cpbg.dsk cpbg.xex cpbg.var cpbg.lst cpbg-sprite-driver.s cpbg-bwsprite.s cpbg-hgrcols-7x1.s cpbg-hgrrows.s cpbg-apple_sprite9x11.s cpbg-fastfont.s cpbg-moldy_burger.s
	rm -f titles.dsk
	rm -f player-missile.hgr player-missile.hgr.png partycrasher-software.hgr kansasfest-hackfest.hgr
	rm -f tmphgr-*
	rm -f working.dsk working.xex
