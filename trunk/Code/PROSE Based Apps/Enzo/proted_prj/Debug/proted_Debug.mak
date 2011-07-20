SHELL = cmd.exe

#
# ZDS II Make File - proted project, Debug configuration
#
# Generated by: ZDS II - eZ80Acclaim! 5.1.1 (Build 10061702)
#   IDE component: d:5.1:10042301
#   Install Path: C:\Programmi\ZiLOG\ZDSII_eZ80Acclaim!_5.1.1\
#

RM = del

ZDS = C:\Programmi\ZiLOG\ZDSII_eZ80Acclaim!_5.1.1
BIN = $(ZDS)\bin
# ZDS include base directory
INCLUDE = C:\PROGRA~1\ZiLOG\ZDSII_~1.1\include
# intermediate files directory
WORKDIR = C:\proted\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

CFLAGS =  \
-define:_DEBUG -define:_EZ80L92 -define:_EZ80 -define:_SIMULATE  \
-NOgenprintf -keepasm -keeplst -NOlist -NOlistinc -NOmodsect  \
-optspeed -promote -NOreduceopt  \
-stdinc:"..;$(INCLUDE)\std;$(INCLUDE)\zilog" -usrinc:"..;"  \
-NOmultithread -NOdebug -cpu:eZ80L92  \
-asmsw:" -cpu:eZ80L92 -define:_EZ80=1 -define:_SIMULATE=1 -include:..;$(INCLUDE)\std;$(INCLUDE)\zilog"

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;$(INCLUDE)\std;$(INCLUDE)\zilog" -list -NOlistmac  \
-name -pagelen:56 -pagewidth:80 -quiet -sdiopt -warn -NOdebug  \
-NOigcase -cpu:eZ80L92

LDFLAGS = @.\proted_Debug.linkcmd
OUTDIR = C:\proted\Debug

build: proted relist

buildall: clean proted relist

relink: deltarget proted

deltarget: 
	@if exist $(WORKDIR)\proted.hex  \
            $(RM) $(WORKDIR)\proted.hex
	@if exist $(WORKDIR)\proted.map  \
            $(RM) $(WORKDIR)\proted.map

clean: 
	@if exist $(WORKDIR)\proted.hex  \
            $(RM) $(WORKDIR)\proted.hex
	@if exist $(WORKDIR)\proted.map  \
            $(RM) $(WORKDIR)\proted.map
	@if exist $(WORKDIR)\main.obj  \
            $(RM) $(WORKDIR)\main.obj

relist: 
	$(AS) $(ASFLAGS) -relist:C:\proted\Debug\proted.map \
            C:\proted\Debug\main.src

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\main.obj

proted: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\main.obj :  \
            C:\proted\main.c  \
            $(INCLUDE)\std\Format.h  \
            $(INCLUDE)\std\Stdarg.h  \
            $(INCLUDE)\std\Stddef.h  \
            $(INCLUDE)\std\Stdio.h  \
            $(INCLUDE)\std\Stdlib.h  \
            $(INCLUDE)\std\String.h  \
            C:\proted\PROSE_Header.h
	 $(CC) $(CFLAGS) C:\proted\main.c

