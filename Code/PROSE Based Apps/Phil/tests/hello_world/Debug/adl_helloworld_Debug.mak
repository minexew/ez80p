SHELL = cmd.exe

#
# ZDS II Make File - adl_helloworld project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\HELLO_~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\HELLO_~1;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\adl_helloworld_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\HELLO_~1\Debug

build: adl_helloworld

buildall: clean adl_helloworld

relink: deltarget adl_helloworld

deltarget: 
	@if exist $(WORKDIR)\adl_helloworld.lod  \
            $(RM) $(WORKDIR)\adl_helloworld.lod
	@if exist $(WORKDIR)\adl_helloworld.hex  \
            $(RM) $(WORKDIR)\adl_helloworld.hex
	@if exist $(WORKDIR)\adl_helloworld.map  \
            $(RM) $(WORKDIR)\adl_helloworld.map

clean: 
	@if exist $(WORKDIR)\adl_helloworld.lod  \
            $(RM) $(WORKDIR)\adl_helloworld.lod
	@if exist $(WORKDIR)\adl_helloworld.hex  \
            $(RM) $(WORKDIR)\adl_helloworld.hex
	@if exist $(WORKDIR)\adl_helloworld.map  \
            $(RM) $(WORKDIR)\adl_helloworld.map
	@if exist $(WORKDIR)\hello_world_adl.obj  \
            $(RM) $(WORKDIR)\hello_world_adl.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\hello_world_adl.obj

adl_helloworld: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\hello_world_adl.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\HELLO_~1\src\hello_world_adl.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\HELLO_~1\src\hello_world_adl.asm
