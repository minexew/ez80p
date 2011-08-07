SHELL = cmd.exe

#
# ZDS II Make File - mouse_init project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~2\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~2;..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\mouse_init_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~2\Debug

build: mouse_init

buildall: clean mouse_init

relink: deltarget mouse_init

deltarget: 
	@if exist $(WORKDIR)\mouse_init.lod  \
            $(RM) $(WORKDIR)\mouse_init.lod
	@if exist $(WORKDIR)\mouse_init.hex  \
            $(RM) $(WORKDIR)\mouse_init.hex
	@if exist $(WORKDIR)\mouse_init.map  \
            $(RM) $(WORKDIR)\mouse_init.map

clean: 
	@if exist $(WORKDIR)\mouse_init.lod  \
            $(RM) $(WORKDIR)\mouse_init.lod
	@if exist $(WORKDIR)\mouse_init.hex  \
            $(RM) $(WORKDIR)\mouse_init.hex
	@if exist $(WORKDIR)\mouse_init.map  \
            $(RM) $(WORKDIR)\mouse_init.map
	@if exist $(WORKDIR)\minit.obj  \
            $(RM) $(WORKDIR)\minit.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\minit.obj

mouse_init: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\minit.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~2\src\minit.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~2\src\minit.asm
