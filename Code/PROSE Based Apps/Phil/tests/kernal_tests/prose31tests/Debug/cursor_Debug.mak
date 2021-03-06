SHELL = cmd.exe

#
# ZDS II Make File - cursor project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\cursor_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\Debug

build: cursor

buildall: clean cursor

relink: deltarget cursor

deltarget: 
	@if exist $(WORKDIR)\cursor.lod  \
            $(RM) $(WORKDIR)\cursor.lod
	@if exist $(WORKDIR)\cursor.hex  \
            $(RM) $(WORKDIR)\cursor.hex
	@if exist $(WORKDIR)\cursor.map  \
            $(RM) $(WORKDIR)\cursor.map

clean: 
	@if exist $(WORKDIR)\cursor.lod  \
            $(RM) $(WORKDIR)\cursor.lod
	@if exist $(WORKDIR)\cursor.hex  \
            $(RM) $(WORKDIR)\cursor.hex
	@if exist $(WORKDIR)\cursor.map  \
            $(RM) $(WORKDIR)\cursor.map
	@if exist $(WORKDIR)\cursor.obj  \
            $(RM) $(WORKDIR)\cursor.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\cursor.obj

cursor: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\cursor.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\src\cursor.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\src\cursor.asm

