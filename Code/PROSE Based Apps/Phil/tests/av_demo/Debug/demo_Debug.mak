SHELL = cmd.exe

#
# ZDS II Make File - demo project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\av_demo\Debug

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

LDFLAGS = @.\demo_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\av_demo\Debug

build: demo

buildall: clean demo

relink: deltarget demo

deltarget: 
	@if exist $(WORKDIR)\demo.lod  \
            $(RM) $(WORKDIR)\demo.lod
	@if exist $(WORKDIR)\demo.hex  \
            $(RM) $(WORKDIR)\demo.hex
	@if exist $(WORKDIR)\demo.map  \
            $(RM) $(WORKDIR)\demo.map

clean: 
	@if exist $(WORKDIR)\demo.lod  \
            $(RM) $(WORKDIR)\demo.lod
	@if exist $(WORKDIR)\demo.hex  \
            $(RM) $(WORKDIR)\demo.hex
	@if exist $(WORKDIR)\demo.map  \
            $(RM) $(WORKDIR)\demo.map
	@if exist $(WORKDIR)\demo.obj  \
            $(RM) $(WORKDIR)\demo.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\demo.obj

demo: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\demo.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\av_demo\src\demo.asm  \
            E:\My_Own_Files\Coding\ez80p\Code\Includes\Routines\ADL_mode_Protracker_Player_v101.asm  \
            E:\My_Own_Files\Coding\ez80p\Code\Includes\Routines\ADL_mode_Protracker_to_AMOEBA_audio_v102.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\av_demo\src\demo.asm
