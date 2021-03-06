SHELL = cmd.exe

#
# ZDS II Make File - showbmp project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\showbmp\Debug

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

LDFLAGS = @.\showbmp_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\showbmp\Debug

build: showbmp

buildall: clean showbmp

relink: deltarget showbmp

deltarget: 
	@if exist $(WORKDIR)\showbmp.lod  \
            $(RM) $(WORKDIR)\showbmp.lod
	@if exist $(WORKDIR)\showbmp.hex  \
            $(RM) $(WORKDIR)\showbmp.hex
	@if exist $(WORKDIR)\showbmp.map  \
            $(RM) $(WORKDIR)\showbmp.map

clean: 
	@if exist $(WORKDIR)\showbmp.lod  \
            $(RM) $(WORKDIR)\showbmp.lod
	@if exist $(WORKDIR)\showbmp.hex  \
            $(RM) $(WORKDIR)\showbmp.hex
	@if exist $(WORKDIR)\showbmp.map  \
            $(RM) $(WORKDIR)\showbmp.map
	@if exist $(WORKDIR)\show_bmp.obj  \
            $(RM) $(WORKDIR)\show_bmp.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\show_bmp.obj

showbmp: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\show_bmp.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\showbmp\source\show_bmp.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\showbmp\source\show_bmp.asm

