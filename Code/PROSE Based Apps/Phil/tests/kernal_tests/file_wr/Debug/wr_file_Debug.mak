SHELL = cmd.exe

#
# ZDS II Make File - wr_file project, Debug configuration
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
WORKDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\KERNAL~1\file_wr\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;..\..\..\..\..\..\Includes;$(INCLUDE)\std;$(INCLUDE)\zilog"  \
-list -NOlistmac -name -pagelen:56 -pagewidth:80 -quiet -sdiopt  \
-warn -debug -NOigcase -cpu:eZ80L92

LDFLAGS = @.\wr_file_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\KERNAL~1\file_wr\Debug

build: wr_file

buildall: clean wr_file

relink: deltarget wr_file

deltarget: 
	@if exist $(WORKDIR)\wr_file.lod  \
            $(RM) $(WORKDIR)\wr_file.lod
	@if exist $(WORKDIR)\wr_file.hex  \
            $(RM) $(WORKDIR)\wr_file.hex
	@if exist $(WORKDIR)\wr_file.map  \
            $(RM) $(WORKDIR)\wr_file.map

clean: 
	@if exist $(WORKDIR)\wr_file.lod  \
            $(RM) $(WORKDIR)\wr_file.lod
	@if exist $(WORKDIR)\wr_file.hex  \
            $(RM) $(WORKDIR)\wr_file.hex
	@if exist $(WORKDIR)\wr_file.map  \
            $(RM) $(WORKDIR)\wr_file.map
	@if exist $(WORKDIR)\create_testfile.obj  \
            $(RM) $(WORKDIR)\create_testfile.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\create_testfile.obj

wr_file: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\create_testfile.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\KERNAL~1\file_wr\source\create_testfile.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\KERNAL~1\file_wr\source\create_testfile.asm

