SHELL = cmd.exe

#
# ZDS II Make File - deallocate_test project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~3\Debug

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

LDFLAGS = @.\deallocate_test_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~3\Debug

build: deallocate_test

buildall: clean deallocate_test

relink: deltarget deallocate_test

deltarget: 
	@if exist $(WORKDIR)\deallocate_test.lod  \
            $(RM) $(WORKDIR)\deallocate_test.lod
	@if exist $(WORKDIR)\deallocate_test.hex  \
            $(RM) $(WORKDIR)\deallocate_test.hex
	@if exist $(WORKDIR)\deallocate_test.map  \
            $(RM) $(WORKDIR)\deallocate_test.map

clean: 
	@if exist $(WORKDIR)\deallocate_test.lod  \
            $(RM) $(WORKDIR)\deallocate_test.lod
	@if exist $(WORKDIR)\deallocate_test.hex  \
            $(RM) $(WORKDIR)\deallocate_test.hex
	@if exist $(WORKDIR)\deallocate_test.map  \
            $(RM) $(WORKDIR)\deallocate_test.map
	@if exist $(WORKDIR)\deallocate.obj  \
            $(RM) $(WORKDIR)\deallocate.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\deallocate.obj

deallocate_test: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\deallocate.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~3\src\deallocate.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~3\src\deallocate.asm
