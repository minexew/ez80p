SHELL = cmd.exe

#
# ZDS II Make File - linedouble project, Debug configuration
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
-include:"..;..\..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\linedouble_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\Debug

build: linedouble

buildall: clean linedouble

relink: deltarget linedouble

deltarget: 
	@if exist $(WORKDIR)\linedouble.lod  \
            $(RM) $(WORKDIR)\linedouble.lod
	@if exist $(WORKDIR)\linedouble.hex  \
            $(RM) $(WORKDIR)\linedouble.hex
	@if exist $(WORKDIR)\linedouble.map  \
            $(RM) $(WORKDIR)\linedouble.map

clean: 
	@if exist $(WORKDIR)\linedouble.lod  \
            $(RM) $(WORKDIR)\linedouble.lod
	@if exist $(WORKDIR)\linedouble.hex  \
            $(RM) $(WORKDIR)\linedouble.hex
	@if exist $(WORKDIR)\linedouble.map  \
            $(RM) $(WORKDIR)\linedouble.map
	@if exist $(WORKDIR)\double_line.obj  \
            $(RM) $(WORKDIR)\double_line.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\double_line.obj

linedouble: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\double_line.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\src\double_line.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\AMOEBA~3\src\double_line.asm

