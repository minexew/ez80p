SHELL = cmd.exe

#
# ZDS II Make File - test320x240 project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\SPRITE~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;E:\My_Own_Files\Coding\Ez80 Project\Code\PROSE Apps\includes;..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\test320x240_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\SPRITE~1\Debug

build: test320x240

buildall: clean test320x240

relink: deltarget test320x240

deltarget: 
	@if exist $(WORKDIR)\test320x240.lod  \
            $(RM) $(WORKDIR)\test320x240.lod
	@if exist $(WORKDIR)\test320x240.hex  \
            $(RM) $(WORKDIR)\test320x240.hex
	@if exist $(WORKDIR)\test320x240.map  \
            $(RM) $(WORKDIR)\test320x240.map

clean: 
	@if exist $(WORKDIR)\test320x240.lod  \
            $(RM) $(WORKDIR)\test320x240.lod
	@if exist $(WORKDIR)\test320x240.hex  \
            $(RM) $(WORKDIR)\test320x240.hex
	@if exist $(WORKDIR)\test320x240.map  \
            $(RM) $(WORKDIR)\test320x240.map
	@if exist $(WORKDIR)\test320x240.obj  \
            $(RM) $(WORKDIR)\test320x240.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\test320x240.obj

test320x240: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\test320x240.obj :  \
            E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\SPRITE~1\src\test320x240.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\SPRITE~1\src\test320x240.asm
