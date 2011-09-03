SHELL = cmd.exe

#
# ZDS II Make File - raster_test project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\Debug

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

LDFLAGS = @.\raster_test_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\Debug

build: raster_test

buildall: clean raster_test

relink: deltarget raster_test

deltarget: 
	@if exist $(WORKDIR)\nmi_test.lod  \
            $(RM) $(WORKDIR)\nmi_test.lod
	@if exist $(WORKDIR)\nmi_test.hex  \
            $(RM) $(WORKDIR)\nmi_test.hex
	@if exist $(WORKDIR)\nmi_test.map  \
            $(RM) $(WORKDIR)\nmi_test.map

clean: 
	@if exist $(WORKDIR)\nmi_test.lod  \
            $(RM) $(WORKDIR)\nmi_test.lod
	@if exist $(WORKDIR)\nmi_test.hex  \
            $(RM) $(WORKDIR)\nmi_test.hex
	@if exist $(WORKDIR)\nmi_test.map  \
            $(RM) $(WORKDIR)\nmi_test.map
	@if exist $(WORKDIR)\raster_nmi.obj  \
            $(RM) $(WORKDIR)\raster_nmi.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\raster_nmi.obj

raster_test: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\raster_nmi.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\src\raster_nmi.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\AMOEBA~1\src\raster_nmi.asm

