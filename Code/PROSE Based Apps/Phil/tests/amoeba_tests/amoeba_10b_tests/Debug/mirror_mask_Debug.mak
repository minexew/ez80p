SHELL = cmd.exe

#
# ZDS II Make File - mirror_mask project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3;..\..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\mirror_mask_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\Debug

build: mirror_mask

buildall: clean mirror_mask

relink: deltarget mirror_mask

deltarget: 
	@if exist $(WORKDIR)\mirror_mask.lod  \
            $(RM) $(WORKDIR)\mirror_mask.lod
	@if exist $(WORKDIR)\mirror_mask.hex  \
            $(RM) $(WORKDIR)\mirror_mask.hex
	@if exist $(WORKDIR)\mirror_mask.map  \
            $(RM) $(WORKDIR)\mirror_mask.map

clean: 
	@if exist $(WORKDIR)\mirror_mask.lod  \
            $(RM) $(WORKDIR)\mirror_mask.lod
	@if exist $(WORKDIR)\mirror_mask.hex  \
            $(RM) $(WORKDIR)\mirror_mask.hex
	@if exist $(WORKDIR)\mirror_mask.map  \
            $(RM) $(WORKDIR)\mirror_mask.map
	@if exist $(WORKDIR)\mirror_mask.obj  \
            $(RM) $(WORKDIR)\mirror_mask.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\mirror_mask.obj

mirror_mask: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\mirror_mask.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\src\mirror_mask.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\src\mirror_mask.asm

