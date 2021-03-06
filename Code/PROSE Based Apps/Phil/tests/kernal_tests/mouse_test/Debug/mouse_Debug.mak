SHELL = cmd.exe

#
# ZDS II Make File - mouse project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;E:\My_Own_Files\Coding\Ez80 Project\Code\PROSE Apps\includes;E:\My_Own_Files\Coding\Ez80 Project\Code\includes;..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\mouse_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~1\Debug

build: mouse

buildall: clean mouse

relink: deltarget mouse

deltarget: 
	@if exist $(WORKDIR)\mousetest.lod  \
            $(RM) $(WORKDIR)\mousetest.lod
	@if exist $(WORKDIR)\mousetest.hex  \
            $(RM) $(WORKDIR)\mousetest.hex
	@if exist $(WORKDIR)\mousetest.map  \
            $(RM) $(WORKDIR)\mousetest.map

clean: 
	@if exist $(WORKDIR)\mousetest.lod  \
            $(RM) $(WORKDIR)\mousetest.lod
	@if exist $(WORKDIR)\mousetest.hex  \
            $(RM) $(WORKDIR)\mousetest.hex
	@if exist $(WORKDIR)\mousetest.map  \
            $(RM) $(WORKDIR)\mousetest.map
	@if exist $(WORKDIR)\mouse_test.obj  \
            $(RM) $(WORKDIR)\mouse_test.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\mouse_test.obj

mouse: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\mouse_test.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~1\src\mouse_test.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\tests\MOUSE_~1\src\mouse_test.asm

