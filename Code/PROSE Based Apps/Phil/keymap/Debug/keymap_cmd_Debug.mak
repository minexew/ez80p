SHELL = cmd.exe

#
# ZDS II Make File - keymap_cmd project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\keymap\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\keymap_cmd_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\keymap\Debug

build: keymap_cmd

buildall: clean keymap_cmd

relink: deltarget keymap_cmd

deltarget: 
	@if exist $(WORKDIR)\keymap_cmd.lod  \
            $(RM) $(WORKDIR)\keymap_cmd.lod
	@if exist $(WORKDIR)\keymap_cmd.hex  \
            $(RM) $(WORKDIR)\keymap_cmd.hex
	@if exist $(WORKDIR)\keymap_cmd.map  \
            $(RM) $(WORKDIR)\keymap_cmd.map

clean: 
	@if exist $(WORKDIR)\keymap_cmd.lod  \
            $(RM) $(WORKDIR)\keymap_cmd.lod
	@if exist $(WORKDIR)\keymap_cmd.hex  \
            $(RM) $(WORKDIR)\keymap_cmd.hex
	@if exist $(WORKDIR)\keymap_cmd.map  \
            $(RM) $(WORKDIR)\keymap_cmd.map
	@if exist $(WORKDIR)\keymap.obj  \
            $(RM) $(WORKDIR)\keymap.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\keymap.obj

keymap_cmd: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\keymap.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\keymap\src\keymap.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\keymap\src\keymap.asm

