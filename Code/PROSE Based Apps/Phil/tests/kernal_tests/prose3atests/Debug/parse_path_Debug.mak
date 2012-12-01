SHELL = cmd.exe

#
# ZDS II Make File - parse_path project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PRAA63~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PRAA63~1;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\parse_path_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PRAA63~1\Debug

build: parse_path

buildall: clean parse_path

relink: deltarget parse_path

deltarget: 
	@if exist $(WORKDIR)\parse_path.lod  \
            $(RM) $(WORKDIR)\parse_path.lod
	@if exist $(WORKDIR)\parse_path.hex  \
            $(RM) $(WORKDIR)\parse_path.hex
	@if exist $(WORKDIR)\parse_path.map  \
            $(RM) $(WORKDIR)\parse_path.map

clean: 
	@if exist $(WORKDIR)\parse_path.lod  \
            $(RM) $(WORKDIR)\parse_path.lod
	@if exist $(WORKDIR)\parse_path.hex  \
            $(RM) $(WORKDIR)\parse_path.hex
	@if exist $(WORKDIR)\parse_path.map  \
            $(RM) $(WORKDIR)\parse_path.map
	@if exist $(WORKDIR)\parsepath.obj  \
            $(RM) $(WORKDIR)\parsepath.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\parsepath.obj

parse_path: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\parsepath.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PRAA63~1\src\parsepath.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PRAA63~1\src\parsepath.asm
