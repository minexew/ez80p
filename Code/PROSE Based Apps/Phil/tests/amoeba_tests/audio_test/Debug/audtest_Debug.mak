SHELL = cmd.exe

#
# ZDS II Make File - audtest project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\AUDIO_~1\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\AUDIO_~1;E:\My_Own_Files\Coding\Ez80 Project\Code\PROSE Apps\includes;..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\audtest_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\AUDIO_~1\Debug

build: audtest

buildall: clean audtest

relink: deltarget audtest

deltarget: 
	@if exist $(WORKDIR)\audtest.lod  \
            $(RM) $(WORKDIR)\audtest.lod
	@if exist $(WORKDIR)\audtest.hex  \
            $(RM) $(WORKDIR)\audtest.hex
	@if exist $(WORKDIR)\audtest.map  \
            $(RM) $(WORKDIR)\audtest.map

clean: 
	@if exist $(WORKDIR)\audtest.lod  \
            $(RM) $(WORKDIR)\audtest.lod
	@if exist $(WORKDIR)\audtest.hex  \
            $(RM) $(WORKDIR)\audtest.hex
	@if exist $(WORKDIR)\audtest.map  \
            $(RM) $(WORKDIR)\audtest.map
	@if exist $(WORKDIR)\audio_test.obj  \
            $(RM) $(WORKDIR)\audio_test.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\audio_test.obj

audtest: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\audio_test.obj :  \
            E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\AUDIO_~1\src\audio_test.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\EZ80PR~1\Code\PROSEA~1\AUDIO_~1\src\audio_test.asm

