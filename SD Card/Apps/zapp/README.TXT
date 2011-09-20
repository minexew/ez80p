                    ZAPP - An eZ80P Apple1 Emulator
                    
ZAPP is an Apple 1 emulator for eZ80P born from the study of three emulators
for Windows/Linux: napple1 (linux), pom1 and apple1emu (windows, linux).

Using emulator
======================================================

Start ZAPP by typing "zapp" on PROSE. 

Internal Commands
======================================================

F12 : Quit to PROSE
F10 : Soft Reset
F9  : Hard Reset
F8  : Load Apple integer basic in memory,
      to start basic you must type E000R in emulator
F5  : Dump all memory in a file on sd (named: dump1.bin, dump2.bin...)
F3  : Switch between 8Kb or 64Kb mode (and soft reset emulator)


Load a memory dump file
======================================================

To load a memory dump file just type (on PROSE) ZAPP <DUMPNAME.BIN>
If you load a dump that contains a basic listing, you must perform a
"soft entry" in basic, just type on Apple1 monitor: E2B3R and after RUN
(E000R command start basic and clean memory)


Example: loading game STARTREK.BIN (basic listing):

# on PROSE type: ZAPP STARTERK.BIN (return)
# when emulator is ready type E2B3R (return)
# now type RUN on basic (return)

 
Attached code from http://www.brielcomputers.com/files/games.zip
 
In folder games find sources for apple1 games.


Calogiuri Enzo Antonio.