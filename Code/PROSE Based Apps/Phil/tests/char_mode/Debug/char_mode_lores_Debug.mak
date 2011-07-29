SHELL = cmd.exe

#
# ZDS II Make File - char_mode_lores project, Debug configuration
#
# Generated by: ZDS II - eZ80Acclaim! 5.1.1 (Build 10061702)
#   IDE component: d:5.1:10042301
#   Install Path: C:\Program Files\ZiLOG\ZDSII_eZ80Acclaim!_5.1.1\
#

RM = del

ZDS = C:\PROGRA~1\ZiLOG\ZDSII_~1.1
BIN = $(ZDS)\bin
# ZDS include base directory
INCLUDE = C:\PROGRA~1\ZiLOG\ZDSII_~1.1\include
# intermediate files directory
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\CHAR_M~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\char_mode_lores_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\CHAR_M~1\Debug

build: char_mode_lores

buildall: clean char_mode_lores

relink: deltarget char_mode_lores

deltarget: 
	@if exist $(WORKDIR)\char_mode_lores.lod  \
            $(RM) $(WORKDIR)\char_mode_lores.lod
	@if exist $(WORKDIR)\char_mode_lores.hex  \
            $(RM) $(WORKDIR)\char_mode_lores.hex
	@if exist $(WORKDIR)\char_mode_lores.map  \
            $(RM) $(WORKDIR)\char_mode_lores.map

clean: 
	@if exist $(WORKDIR)\char_mode_lores.lod  \
            $(RM) $(WORKDIR)\char_mode_lores.lod
	@if exist $(WORKDIR)\char_mode_lores.hex  \
            $(RM) $(WORKDIR)\char_mode_lores.hex
	@if exist $(WORKDIR)\char_mode_lores.map  \
            $(RM) $(WORKDIR)\char_mode_lores.map
	@if exist $(WORKDIR)\test320x240.obj  \
            $(RM) $(WORKDIR)\test320x240.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\test320x240.obj

char_mode_lores: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\test320x240.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\CHAR_M~1\src\test320x240.asm  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\CHAR_M~1\src\font.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\CHAR_M~1\src\test320x240.asm
