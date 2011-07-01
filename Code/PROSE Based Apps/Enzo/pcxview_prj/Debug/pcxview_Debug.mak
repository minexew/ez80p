SHELL = cmd.exe

#
# ZDS II Make File - pcxview project, Debug configuration
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
WORKDIR = C:\DOCUME~1\_Enzo_\Desktop\pcxview\Debug

CC = @$(BIN)\eZ80cc
AS = @$(BIN)\eZ80asm
LD = @$(BIN)\eZ80link
AR = @$(BIN)\eZ80lib
WEBTOC = @$(BIN)\mkwebpage

CFLAGS =  \
-define:_DEBUG -define:_EZ80L92 -define:_EZ80 -define:_SIMULATE  \
-define:_MULTI_THREAD -NOgenprintf -keepasm -keeplst -NOlist  \
-NOlistinc -NOmodsect -optspeed -promote -NOreduceopt  \
-stdinc:"..;$(INCLUDE)\std;$(INCLUDE)\zilog" -usrinc:"..;"  \
-multithread -NOdebug -cpu:eZ80L92  \
-asmsw:" -cpu:eZ80L92 -define:_EZ80=1 -define:_SIMULATE=1 -include:..;$(INCLUDE)\std;$(INCLUDE)\zilog"

ASFLAGS =  \
-define:_EZ80=1 -define:_SIMULATE=1  \
-include:"..;$(INCLUDE)\std;$(INCLUDE)\zilog" -list -NOlistmac  \
-name -pagelen:56 -pagewidth:80 -quiet -sdiopt -warn -NOdebug  \
-NOigcase -cpu:eZ80L92

LDFLAGS = @.\pcxview_Debug.linkcmd
OUTDIR = C:\DOCUME~1\_Enzo_\Desktop\pcxview\Debug

build: pcxview relist

buildall: clean pcxview relist

relink: deltarget pcxview

deltarget: 
	@if exist $(WORKDIR)\pcxview.hex  \
            $(RM) $(WORKDIR)\pcxview.hex
	@if exist $(WORKDIR)\pcxview.map  \
            $(RM) $(WORKDIR)\pcxview.map

clean: 
	@if exist $(WORKDIR)\pcxview.hex  \
            $(RM) $(WORKDIR)\pcxview.hex
	@if exist $(WORKDIR)\pcxview.map  \
            $(RM) $(WORKDIR)\pcxview.map
	@if exist $(WORKDIR)\main.obj  \
            $(RM) $(WORKDIR)\main.obj

relist: 
	$(AS) $(ASFLAGS) -relist:C:\DOCUME~1\_Enzo_\Desktop\pcxview\Debug\pcxview.map \
            C:\DOCUME~1\_Enzo_\Desktop\pcxview\Debug\main.src

# pre-4.11.0 compatibility
rebuildall: buildall 

LIBS = 

OBJS =  \
            $(WORKDIR)\main.obj

pcxview: $(OBJS)
	 $(LD) $(LDFLAGS)

$(WORKDIR)\main.obj :  \
            C:\DOCUME~1\_Enzo_\Desktop\pcxview\main.c  \
            C:\DOCUME~1\_Enzo_\Desktop\pcxview\PROSE_Header.h  \
            $(INCLUDE)\std\String.h
	 $(CC) $(CFLAGS) C:\DOCUME~1\_Enzo_\Desktop\pcxview\main.c

