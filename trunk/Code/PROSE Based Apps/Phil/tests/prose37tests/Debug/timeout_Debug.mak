SHELL = cmd.exe

#
# ZDS II Make File - timeout project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\timeout_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\Debug

build: timeout

buildall: clean timeout

relink: deltarget timeout

deltarget: 
	@if exist $(WORKDIR)\timeout.lod  \
            $(RM) $(WORKDIR)\timeout.lod
	@if exist $(WORKDIR)\timeout.hex  \
            $(RM) $(WORKDIR)\timeout.hex
	@if exist $(WORKDIR)\timeout.map  \
            $(RM) $(WORKDIR)\timeout.map

clean: 
	@if exist $(WORKDIR)\timeout.lod  \
            $(RM) $(WORKDIR)\timeout.lod
	@if exist $(WORKDIR)\timeout.hex  \
            $(RM) $(WORKDIR)\timeout.hex
	@if exist $(WORKDIR)\timeout.map  \
            $(RM) $(WORKDIR)\timeout.map
	@if exist $(WORKDIR)\timeout.obj  \
            $(RM) $(WORKDIR)\timeout.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\timeout.obj

timeout: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\timeout.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\src\timeout.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\src\timeout.asm

