SHELL = cmd.exe

#
# ZDS II Make File - dis_proj project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\debug

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

LDFLAGS = @.\dis_proj_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\debug

build: dis_proj

buildall: clean dis_proj

relink: deltarget dis_proj

deltarget: 
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.lod  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.lod
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.hex  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.hex
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.map  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.map

clean: 
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.lod  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.lod
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.hex  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.hex
	@if exist E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.map  \
            $(RM) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\Debug\dis_proj.map
	@if exist $(WORKDIR)\dis.obj  \
            $(RM) $(WORKDIR)\dis.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\dis.obj

dis_proj: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\dis.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\source\dis.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\dis\source\dis.asm

