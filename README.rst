========
Fujirun
========

My (winning!) entry in the `KansasFest <https://www.kansasfest.org/>`_ 2017 `HackFest <https://www.kansasfest.org/hackfest/>`_ competition.


Running
=======

Fujirun is written for an Apple ][+ with 48K of memory.

A pre-built disk image is included, so no need to reassemble the code unless
you are changing something. Use your favorite Apple II emulator to boot the disk image ``demo.dsk``.


Building
========

To build from the assembly source, you will need the following programs:

* `Python 2.7 <https://www.python.org/downloads/>`_
* `ATasm <http://atari.miribilist.com/atasm/>`_, which, while ostensibly an *Atari* macro assembler, produces generic 6502 code and can be used on any 6502 machine
* `lz4 <https://lz4.github.io/lz4/>`_, a compression program suitable for fast decompression on the 6502

For Python, you will need these additional packages

* `atrcopy <https://github.com/robmcmullen/atrcopy>`_, my disk image utility
* `asmgen <https://github.com/robmcmullen/asmgen>`_, my 6502 code generation utility

which are available through pip, so once Python is installed use:

``
pip install atrcopy asmgen
``

Gameplay
========

This is a clone of the arcade game Amidar. You control an apple, trying to fill
in rectangles while avoiding the booataris. Moving on the lines of the maze,
you change the color from white to green the first time you walk on a segment
of a line. When all segments surrounding a rectangle are green, the rectangles
will be filled.

* 1 point is awarded for each segment of a line
* 20 points per segment height are awarded for each box filled, so for example
  40 points for a box that is two segments high, 60 for 3 segments high, etc.

There are two types of booataris: an orbiter than continually makes
counterclockwise circuits around the outside of the maze, and amidars which
follow the rules of "ghost legs". Amidars start on the top of the maze and move
downward. When the reach a horizontal branch, they **must** take it. Once they
reach the end of a branch, they will resume their downward direction. When they
reach the bottom, they will move left or right to a different vertical line and
begin travelling upwards, again following the same rule that when they hit a
horizontal line, they **must** take it.

While moving up and down, the amidars behave deterministically: there is no
randomness at all. The only random bit of their movement is choosing which line
to start down (or up) when reaching the top (or bottom).


Game Status
===========

As coded for the HackFest, the game has a single screen and is a single player
game. At this point, nothing happens when completing the maze. I ran out of time during KansasFest.

I am planning on adding:

* actually moving on to the next level when you complete a level
* some sort of effect when the player gets caught by a booatari.
* multiple levels
* sound
* two player simultaneous play
* an Atari 8-bit port

Bugs
----

By design, the "pac-man" bug is present so the player and an amidar can pass
through each other if they happen to exchange grid squares in a single turn. In
practice this happens more often than I thought it would, so I'll have to
readdress this.

After you lose all your lives and restart (by pressing any key), the amidars will work correctly until they get to the bottom, after which one will continue going down after the bottom row and stomp all over memory and crash. I still haven't been able to debug this.


Code Walkthrough
================

Source files
------------

* ``main.s`` - main driver
* ``platform-apple2.s`` - Apple II specific code
* ``wipes-demo.s`` - title screen animation
* ``wipes-null.s`` - stubs for title screen to make faster booting test image
* ``actors.s`` - player/amidar initialization
* ``background.s`` - printing, text screen utilities, screen damage
* ``constants.s`` - variables. Just kidding. Constants.
* ``debug.s`` - debugging utilities
* ``logic.s`` - player/amidar movement logic
* ``lz4.s`` - Peter Ferrie's `lz4 decompressor <http://pferrie.host22.com/misc/appleii.htm>`_
* ``macros.s`` - guess
* ``maze.s`` - maze generation code
* ``rand.s`` - random number generator and utilities
* ``vars.s`` - uninitialized variable declarations

Notes
-----

* any place you see the "_smc" extension, that's a target for self-modifying code. Got that from Quinn Dunki.


References
==========

* Quinn Dunki's `sprite compiler <https://github.com/blondie7575/HiSprite>`_ and `my modifications <https://github.com/robmcmullen/asmgen>`_
* Michael Pohoreski's `HGR Font Tutorial <https://github.com/Michaelangel007/apple2_hgr_font_tutorial>`_
* Peter Ferrie's original `one sector boot loader <https://github.com/peterferrie/standard-delivery>`_ and `my modifications <https://github.com/robmcmullen/standard-delivery>`_
* Peter Ferrie's `LZ4 unpacker <http://pferrie.host22.com/misc/appleii.htm>`_
* Sheldon Simms' `PNG to HGR converter <http://wsxyz.net/tohgr.html>`_

