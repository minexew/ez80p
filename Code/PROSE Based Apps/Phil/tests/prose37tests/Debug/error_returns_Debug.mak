SHELL = cmd.exe

#
# ZDS II Make File - error_returns project, Debug configuration
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

LDFLAGS = @.\error_returns_Debug.linkcmd
OUTDIR = E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\Debug

build: error_returns

buildall: clean error_returns

relink: deltarget error_returns

deltarget: 
	@if exist $(WORKDIR)\error_returns.lod  \
            $(RM) $(WORKDIR)\error_returns.lod
	@if exist $(WORKDIR)\error_returns.hex  \
            $(RM) $(WORKDIR)\error_returns.hex
	@if exist $(WORKDIR)\error_returns.map  \
            $(RM) $(WORKDIR)\error_returns.map

clean: 
	@if exist $(WORKDIR)\error_returns.lod  \
            $(RM) $(WORKDIR)\error_returns.lod
	@if exist $(WORKDIR)\error_returns.hex  \
            $(RM) $(WORKDIR)\error_returns.hex
	@if exist $(WORKDIR)\error_returns.map  \
            $(RM) $(WORKDIR)\error_returns.map
	@if exist $(WORKDIR)\error_returns.obj  \
            $(RM) $(WORKDIR)\error_returns.obj

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\error_returns.obj

error_returns: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\error_returns.obj :  \
            E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\src\error_returns.asm
	 $(AS) $(ASFLAGS) E:\MY_OWN~1\Coding\ez80p\Code\PROSEB~1\Phil\tests\PROSE3~2\src\error_returns.asm

