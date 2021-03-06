SHELL = cmd.exe

#
# ZDS II Make File - copy project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\copy\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\copy;..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\copy_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\copy\Debug

build: copy

buildall: clean copy

relink: deltarget copy

deltarget: 
	@if exist $(WORKDIR)\copy.lod  \
            $(RM) $(WORKDIR)\copy.lod
	@if exist $(WORKDIR)\copy.hex  \
            $(RM) $(WORKDIR)\copy.hex
	@if exist $(WORKDIR)\copy.map  \
            $(RM) $(WORKDIR)\copy.map

clean: 
	@if exist $(WORKDIR)\copy.lod  \
            $(RM) $(WORKDIR)\copy.lod
	@if exist $(WORKDIR)\copy.hex  \
            $(RM) $(WORKDIR)\copy.hex
	@if exist $(WORKDIR)\copy.map  \
            $(RM) $(WORKDIR)\copy.map
	@if exist $(WORKDIR)\copy.obj  \
            $(RM) $(WORKDIR)\copy.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\copy.obj

copy: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\copy.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\copy\src\copy.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\EXTERN~1\copy\src\copy.asm

