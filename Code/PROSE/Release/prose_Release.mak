SHELL = cmd.exe

#
# ZDS II Make File - prose project, Release configuration
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
WORKDIR = E:\My_Own_Files\Coding\ez80p\Code\PROSE\Release

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSE;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -NOdebug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\prose_Release.linkcmd
OUTDIR = E:\My_Own_Files\Coding\ez80p\Code\PROSE\Release

build: prose

buildall: clean prose

relink: deltarget prose

deltarget: 
	@if exist $(WORKDIR)\prose.lod  \
            $(RM) $(WORKDIR)\prose.lod
	@if exist $(WORKDIR)\prose.hex  \
            $(RM) $(WORKDIR)\prose.hex
	@if exist $(WORKDIR)\prose.map  \
            $(RM) $(WORKDIR)\prose.map

clean: 
	@if exist $(WORKDIR)\prose.lod  \
            $(RM) $(WORKDIR)\prose.lod
	@if exist $(WORKDIR)\prose.hex  \
            $(RM) $(WORKDIR)\prose.hex
	@if exist $(WORKDIR)\prose.map  \
            $(RM) $(WORKDIR)\prose.map
	@if exist $(WORKDIR)\prose_main.obj  \
            $(RM) $(WORKDIR)\prose_main.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\prose_main.obj

prose: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\prose_main.obj :  \
            E:\My_Own_Files\Coding\ez80p\Code\PROSE\src\prose_main.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSE\src\prose_main.asm
