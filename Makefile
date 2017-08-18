SPRITES = atari-sprite9x11.png apple-sprite9x11.png
TOHGR = tohgr
A2 = build-apple2/
VERSION = -v1

all: working.dsk fujirun$(VERSION).dsk

build-apple2:
	mkdir build-apple2

player-missile.hgr: player-missile.png
	cp player-missile.png $(A2)
	asmgen.py $(A2)player-missile.png
	cp $(A2)player-missile.hgr player-missile.hgr

player-missile-2.hgr: player-missile-2.png
	cp player-missile-2.png $(A2)
	asmgen.py $(A2)player-missile-2.png
	cp $(A2)player-missile-2.hgr player-missile-2.hgr

kansasfest-hackfest.hgr: kansasfest-hackfest.png
	cp kansasfest-hackfest.png $(A2)kansasfest-hackfest-top.png
	$(TOHGR) $(A2)kansasfest-hackfest-top.png
	cp kansasfest-hackfest.png $(A2)kansasfest-hackfest-bot.png
	asmgen.py -i bw $(A2)kansasfest-hackfest-bot.png
	asmgen.py --merge 96 -o $(A2)kansasfest-hackfest $(A2)kansasfest-hackfest-top.hgr $(A2)kansasfest-hackfest-bot.hgr
	cp $(A2)kansasfest-hackfest.hgr kansasfest-hackfest.hgr

title.hgr: title.png
	cp title.png $(A2)title-top.png
	$(TOHGR) $(A2)title-top.png
	cp title.png $(A2)title-bot.png
	asmgen.py -i bw $(A2)title-bot.png
	asmgen.py --merge 136 -o $(A2)title $(A2)title-top.hgr $(A2)title-bot.hgr
	cp $(A2)title.hgr title.hgr

$(A2)title.s: title.hgr
	# use legacy block format
	lz4 -9lf title.hgr $(A2)title.lz4
	# strip first 8 bytes (start at byte 9 when counting from 1)
	tail -c +9 $(A2)title.lz4 > $(A2)title.lz4-payload
	asmgen.py -a mac65 --src $(A2)title.lz4-payload -n title > $(A2)title.s

$(A2)working-sprite-driver.s: $(SPRITES) fatfont128.dat
	asmgen.py -a mac65 -p 6502 -s hgrbw --scroll 4 -m -k -d -g -f fatfont128.dat -o $(A2)working $(SPRITES)

$(A2)working.xex: wipes-null.s main.s constants.s rand.s maze.s $(A2)working-sprite-driver.s $(A2)title.s vars.s debug.s actors.s background.s logic.s platform-apple2.s lz4.s
	rm -f $(A2)working.xex
	echo '.include "main.s"' > $(A2)working.s
	echo '.include "wipes-null.s"' >> $(A2)working.s
	echo '.include "platform-apple2.s"' >> $(A2)working.s
	echo '.include "$(A2)working-sprite-driver.s"' >> $(A2)working.s
	echo '.include "$(A2)title.s"' >> $(A2)working.s
	atasm -mae -o$(A2)working.xex $(A2)working.s -L$(A2)working.var -g$(A2)working.lst

working.dsk: build-apple2 $(A2)working.xex
	rm -f working.dsk
	atrcopy working.dsk boot -b $(A2)working.xex --brun 6000 -f
	#cp $(A2)working.var /home/rob/.wine/drive_c/applewin/APPLE2E.SYM

$(A2)fujirun.xex: wipes-demo.s main.s constants.s rand.s maze.s $(A2)working-sprite-driver.s vars.s debug.s actors.s background.s logic.s platform-apple2.s lz4.s
	rm -f $(A2)fujirun.xex
	echo '.include "main.s"' > $(A2)fujirun.s
	echo '.include "wipes-demo.s"' >> $(A2)fujirun.s
	echo '.include "platform-apple2.s"' >> $(A2)fujirun.s
	echo '.include "$(A2)working-sprite-driver.s"' >> $(A2)fujirun.s
	echo '.include "$(A2)title.s"' >> $(A2)fujirun.s
	atasm -mae -o$(A2)fujirun.xex $(A2)fujirun.s -L$(A2)fujirun.var -g$(A2)fujirun.lst

fujirun$(VERSION).dsk: build-apple2 $(A2)fujirun.xex player-missile.hgr player-missile-2.hgr kansasfest-hackfest.hgr title.hgr
	atrcopy fujirun$(VERSION).dsk boot -d player-missile.hgr@2000 player-missile-2.hgr@4000 kansasfest-hackfest.hgr@2000 -b $(A2)fujirun.xex --brun 6000 -f

clean:
	rm -rf $(A2)
	rm -f fujirun$(VERSION).dsk working.dsk

reallyclean: clean
	rm -f player-missile.hgr player-missile-2.hgr kansasfest-hackfest.hgr title.hgr