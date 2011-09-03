SHELL = cmd.exe

#
# ZDS II Make File - patch_font project, Debug configuration
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
-include:"..;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\patch_font_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\Debug

build: patch_font

buildall: clean patch_font

relink: deltarget patch_font

deltarget: 
	@if exist $(WORKDIR)\patch_font.lod  \
            $(RM) $(WORKDIR)\patch_font.lod
	@if exist $(WORKDIR)\patch_font.hex  \
            $(RM) $(WORKDIR)\patch_font.hex
	@if exist $(WORKDIR)\patch_font.map  \
            $(RM) $(WORKDIR)\patch_font.map

clean: 
	@if exist $(WORKDIR)\patch_font.lod  \
            $(RM) $(WORKDIR)\patch_font.lod
	@if exist $(WORKDIR)\patch_font.hex  \
            $(RM) $(WORKDIR)\patch_font.hex
	@if exist $(WORKDIR)\patch_font.map  \
            $(RM) $(WORKDIR)\patch_font.map
	@if exist $(WORKDIR)\patch_font.obj  \
            $(RM) $(WORKDIR)\patch_font.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\patch_font.obj

patch_font: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\patch_font.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\src\patch_font.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~1\src\patch_font.asm

