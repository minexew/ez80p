SHELL = cmd.exe

#
# ZDS II Make File - chfight project, Debug configuration
#
# Generated by: ZDS II - eZ80Acclaim! 5.1.1 (Build 10061702)
#   IDE component: d:5.1:10042301
#   Install Path: C:\Program Files (x86)\ZiLOG\ZDSII_eZ80Acclaim!_5.1.1\
#

RM = del

ZDS = C:\PROGRA~3\ZiLOG\ZDSII_~1.1
BIN = $(ZDS)\bin
# ZDS include base directory
INCLUDE = C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include
# intermediate files directory
WORKDIR = C:\Users\fog76\Desktop\CHFIGH~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

CFLAGS =  \
-define:_DEBUG -define:_EZ80L92 -define:_EZ80 -define:_SIMULATE  \
-NOgenprintf -keepasm -keeplst -NOlist -NOlistinc -NOmodsect  \
-optspeed -promote -NOreduceopt  \
-stdinc:"..;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\std;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\zilog"  \
-usrinc:"..;" -NOmultithread -NOdebug -cpu:eZ80L92  \
-asmsw:" -cpu:eZ80L92 -define:_EZ80=1 -define:_SIMULATE=1 -include:..;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\std;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\zilog"

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\std;C:\PROGRA~3\ZiLOG\ZDSII_~1.1\include\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -NOdebug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\chfight_Debug.linkcmd
OUTDIR = C:\Users\fog76\Desktop\CHFIGH~1\Debug

build: chfight relist

buildall: clean chfight relist

relink: deltarget chfight

deltarget: 
	@if exist $(WORKDIR)\chfight.hex  \
            $(RM) $(WORKDIR)\chfight.hex
	@if exist $(WORKDIR)\chfight.map  \
            $(RM) $(WORKDIR)\chfight.map

clean: 
	@if exist $(WORKDIR)\chfight.hex  \
            $(RM) $(WORKDIR)\chfight.hex
	@if exist $(WORKDIR)\chfight.map  \
            $(RM) $(WORKDIR)\chfight.map
	@if exist $(WORKDIR)\main.obj  \
            $(RM) $(WORKDIR)\main.obj

relist: 
	$(AS) $(ASFLAGS) -relist:C:\Users\fog76\Desktop\CHFIGH~1\Debug\chfight.map \
            C:\Users\fog76\Desktop\CHFIGH~1\Debug\main.src

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\main.obj

chfight: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\main.obj :  \
            C:\Users\fog76\Desktop\CHFIGH~1\main.c  \
            $(INCLUDE)\std\Stdlib.h  \
            $(INCLUDE)\std\String.h  \
            C:\Users\fog76\Desktop\CHFIGH~1\PROSE_Header.h  \
            C:\Users\fog76\Desktop\CHFIGH~1\game.c  \
            C:\Users\fog76\Desktop\CHFIGH~1\game.h  \
            C:\Users\fog76\Desktop\CHFIGH~1\screen.c  \
            C:\Users\fog76\Desktop\CHFIGH~1\screen.h
	 $(CC) $(CFLAGS) C:\Users\fog76\Desktop\CHFIGH~1\main.c

