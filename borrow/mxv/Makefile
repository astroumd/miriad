# DON'T edit this file! It will be overwritten.
#
#		Miriad X Visualizer source level Makefile
# MXV 2.0 requires the following libraries:
#	X11R5	(It will not link with R4).
#	The hdf library df, version HDF3.1r5.
#	It will not compile/link with 3.2.
#
# MXV is supported on Sun 4s and the UI's Convex C3. If it is desired to
# run MXV on other systems, some work may need to be done. In particular,
# MAFLAGS needs to be defined correctly so the hdf include files don't barf.
# Also, macros will have to be defined similar to those below.
#
#	You will need to specify the paths to the location of the required
#	Hdf and X libraries.
#
#	Targets defined:
#
#	1.	make
#		Create a working version of Miriad X Visualizer in the current 
#		directory.
#	1a.	make map
#		Links mxv and creates a loader map file mxv.map.
#	2.	make clean
#		Clean all .o and unnecessary files.
#		(Well, most unnecesary files).
#	3.	make makefile
#		Creates a makefile from Makefile.proto
#	4.	make install
#		Installs mxv in the installed directory.
#	5.	make install.doc
#		Currently, installs a readable version of the resource
#		description.
# Notes:
#	On Sun's, the makefile will expand ${${macro}_macro, but other
#	systems won't. So we use a sed script to do it for us. (Hence, the
#	Makefile.proto file).
#	DTM support has been removed. It never worked anyway.

PROGRAM	= mxv

# Choose one of these. With luck that's all you need to change.
# 'make.makefile' edits the following line and substitutes the current value.
ARCH=sun4
#ARCH=c38

# Hopefully, most of these don't need to be changed.
# Which C compiler to use? On the Suns we are using the 'ANSI' C compiler
# even though MXV was not written for it. On the Convex, cc is ANSI C.
c38_CC		= cc
sun4_CC		= acc

CC		= ${sun4_CC}

# TOP specifies where to look for external library and include directories.
# Create a single TOP in case both hdf and X11 are there.
sun4_TOP	= /usr/local
c38_TOP		= /usr/local

TOP		= ${sun4_TOP}

# Where are the include/library files for hdf?
sun4_HDFTOP	= ${TOP}
# On the C3, some libraries are my versions.
c38_HDFTOP	= /lai/hr

HDFTOP		= ${sun4_HDFTOP}

sun4_HDFINCS	= ${HDFTOP}/include/hdf
c38_HDFINCS	= ${HDFTOP}/include/hdf

HDFINCS		= -I${sun4_HDFINCS}

sun4_HDFLIB	= ${HDFTOP}/lib
c38_HDFLIB	= ${HDFTOP}/lib

HDFLIB		= -L${sun4_HDFLIB}
HDFLIBS		= -ldf

# Where are the include/library files for X11?
sun4_X11TOP	= ${TOP}
# On the c38, some libraries are my versions.
c38_X11TOP	= ${TOP}

X11TOP		= ${sun4_X11TOP}

sun4_X11INCS	= ${X11TOP}/include
#c38_X11INCS	= ${X11TOP}/include
c38_X11INCS	= ${X11TOP}/include

X11INCS		= -I${sun4_X11INCS}

sun4_X11LIB	= ${X11TOP}/lib
c38_X11LIB	= ${X11TOP}/lib

X11LIB		= -L${sun4_X11LIB}

INCDIRS		= ${X11INCS} ${HDFINCS}

# These are the same everywhere.
X11LIBS		= -lXaw  -lXt -lXmu -lXext -lX11

# When compiling on the Suns and doing debugging, we want to link statically.
sun4_PRE	= -Bstatic
sun4_POST	= -Bdynamic
c38_PRE		=
c38_POST	=

PRE		= ${sun4_PRE}
POST		= ${sun4_POST}

# Where should mxv be put when installed?
sun4_BINDIR	= ..
c38_BINDIR	= /lai/hr/bin

BINDIR		= ${sun4_BINDIR}

# Where does the nroff listing of the resources go?
sun4_DOCDIR	= ..
c38_DOCDIR	= /lai/hr/doc

DOCDIR		= ${sun4_DOCDIR}

# Normally these are left undefined.
# define if don't want processed SDS support.
#NOPROCSDS = -DNO_PROCSDS
# Define for no ISO support
#NOISO = -DNO_ISO
# Define for no dicer support
#NODICE = -DNO_DICER
# Define if don't want load raster support.
#NOLOADRASTER = -DNO_LOADRASTER

# Define if system does not have qsort. (Used in td_file to sort dir.).
#NOQSORT = -DNOQSORT

DISABLEFLAGS = ${NOPROCSDS} ${NOISO} ${NODICE} ${NOLOADRASTER} ${NOQSORT}


# What external libraries are needed?
LINKLIBS	= ${X11LIBS}  ${HDFLIBS} -lm 
# and where to look for them
LIBDIRS =  ${HDFLIB} ${X11LIB}

# Where to build the export directory
sun4_EXPORT	= ../mxv.export
c38_EXPORT	= ../mxv.export

EXPORT		= ${sun4_EXPORT}

# set to "E" if experimental or leave undefined. It causes the version edit
# number to be incremented on each compile.
#sun4_EXP	= -DSTATUS=\"E\"
#c38_EXP		= -DSTATUS=\"E\"

EXP		= ${sun4_EXP}

COMPFLAGS =  ${DISABLEFLAGS}

# Switches to create a load map.
sun4_MAP	= -Qoption ld -M
c38_MAP		= -MS

MAP		= ${sun4_MAP}

# (old)
# When compiling with any SYS V systems (except UNICOS),
# uncomment the following line:
# SYFLAGS   = -DSYSV -DUSG -DIRIS4

#	This is only needed to get df.h to work.
sun4_MAFLAGS	= -DSUN4
c38_MAFLAGS	= -DCONVEX

MAFLAGS		= ${sun4_MAFLAGS}

# (old)
# When compiling on the Cray Unicos 5.0, uncomment the following 2 lines
# MAFLAGS   = -DUNICOS
# LMFLAGS   = -lnet

# Debugging switches
sun4_DBG	= -g
#c38_DBG		= -cxdb -no -fi
c38_DBG		= -O -fi

DBG		= ${sun4_DBG}

#############################################################
########## DO NOT MAKE ANY CHANGES BELOW THIS LINE ##########
#############################################################

# Compile flags
CFLAGS  =  ${DBG} ${INCDIRS} ${MAFLAGS}

# load flags -- DO NOT CHANGE
#
LFLAGS = ${LIBDIRS}  ${LINKLIBS}

HDRS	=	SRasterP.h \
		SRaster.h \
		SliderP.h \
		Slider.h \
		WorkSpaceP.h \
		WorkSpace.h \
		bitmaps.h \
		fits.h \
		gr_com.h \
		gr_def.h \
		gr_ext.h \
		gr_inc.h \
		gr_iso.h \
		gr_plot.h \
		gr_resources.h \
		gr_var.h \
		gr_xwi.h \
		mxv.h \
		mxv_icon.h \
		td_com.h \
		td_inc.h \
		td_var.h \
		version.h \
		ximage.h

SRCS	= 	gr_ani.c \
		gr_anilev.c \
		gr_arb.c \
		gr_arblev.c \
		gr_axes.c \
		gr_boss.c \
		gr_boslev.c \
		gr_box1.c \
		gr_box2.c \
		gr_cube.c \
		gr_cublev.c \
		gr_dice1.c \
		gr_dice2.c \
		gr_dicelev.c \
		gr_dsplev.c \
		gr_dspl.c \
		gr_extplot.c \
		gr_file.c \
		grnew.c \
		grkon.c \
		grkonlev.c \
		grps.c \
		grcps.c \
		grcut.c \
		grtask.c \
		gr_fillev.c \
		gr_hist.c \
		gr_hislev.c \
		gr_image.c \
		gr_isolev.c \
		gr_iso1.c \
		gr_iso2.c \
		gr_main.c \
		gr_mos.c \
		gr_moslev.c \
		gr_pal.c \
		gr_palette2.c \
		gr_proc.c \
		gr_text.c \
		gr_subs.c \
		gr_subslev.c \
		gr_tile.c \
		gr_tillev.c \
		gr_toplev.c \
		gr_vbuff.c \
		gr_view.c \
		gr_viewlev.c \
		gr_xwi.c \
		gr_xwi1a.c \
		td_axes.c \
		td_file.c \
		td_hdf.c \
		td_main.c \
		td_mem.c \
		td_miriad.c \
		td_misc.c \
		td_fits.c td_fitsreader.c \
		td_pixel.c \
		td_port.c \
		gr_misc.c\
		xi_mainsub.c \
		xi_palette.c \
		SRaster.c Slider.c WorkSpace.c

OBJS = $(SRCS:.c=.o)

EXPORT_FILES = ${HDRS} ${SRCS} Makefile.proto Makefile README.MXV \
	resources.nro Mxv.ad mxv.for
# Remove from export before copying.
EXPORT_REMOVE = mxv.for
.c.o	:
	rm -f $*.o
	${CC} ${CFLAGS} -c $*.c

.KEEP_STATE:

# Generate MXV
mxv: ${OBJS}
# This isn't really necessary, but its useful during development.
# The new version number takes effect on NEXT compile. 
	@ EXP=${EXP}
	@ if [ ${EXP} ]; then mv version.h version.h.old;\
	  	awk '{ if($$2=="EDIT") $$3+=1;\
			print $$0}' version.h.old > version.h;\
	fi
	rm -f ${PROGRAM} core
	${CC} ${CFLAGS} -o ${PROGRAM} ${PRE} ${OBJS} ${LFLAGS} ${POST}


map:	${OBJS}
	${CC} ${MAP} ${CFLAGS} -o ${PROGRAM} ${PRE} ${OBJS} ${LFLAGS} ${POST}\
		 > ${PROGRAM}.map 2>&1

# Create system dependent Makefile
Makefile:: Makefile.proto
	${MAKE} -f Makefile.proto make.makefile

# This edits the Makefile prototype and changes the 'ARCH=??' line to
# the result of the 'arch' command. Then references to ${ARCH} are changed
# to the value of $ARCH.
make.makefile:
	- mv Makefile Makefile.bak
	echo "# DON'T edit this file! It will be overwritten." > Makefile
	SYS=`arch`;\
	sed -e "s/^ARCH=[A-z0-9]*$$/ARCH=$${SYS}/" \
		-e "s/$$[{]ARCH}_/$${SYS}_/" Makefile.proto >> Makefile

# Copy current test version so others can try it
install:
	- mv -f ${BINDIR}/mxv ${BINDIR}/mxvo
	cp mxv ${BINDIR}/mxv

install.doc: resources.nro
	tbl resources.nro | nroff -me -Tcrt > ${DOCDIR}/mxv.man

# Build a copy of the source for export
export:
# Purge anything old. Sometimes file names change.
	if [ ! -d ${EXPORT} ]; then mkdir ${EXPORT}; \
	else \
		rm -fr ${EXPORT}/* ;\
	fi
#	rm -f ${EXPORT}/${EXPORT_REMOVE}
	cp -p ${EXPORT_FILES} ${EXPORT}
# Copy all the manual stuff.
	cp -rp man ${EXPORT}

clean:
	rm -f *.o mxv mxvLog *~ core ${PROGRAM}.map

#
# Define dependencies
#

gr_ani.o	: gr_ani.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_anilev.o	: gr_anilev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_arb.o	: gr_arb.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_arblev.o	: gr_arblev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_axes.o	: gr_axes.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_boss.o	: gr_boss.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_boslev.o	: gr_boslev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_box1.o	: gr_box1.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_box2.o	: gr_box2.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_cube.o	: gr_cube.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_cublev.o	: gr_cublev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_dice1.o	: gr_dice1.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_dice2.o	: gr_dice2.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_dicelev.o	: gr_dicelev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_dspl.o	: gr_dspl.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_dsplev.o	: gr_dsplev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_extplot.o	: gr_extplot.c gr_def.h fits.h gr_plot.h gr_var.h
gr_file.o	: gr_file.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grkon.o		: grkon.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grkonlev.o	: grkonlev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grps.o		: grps.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grcps.o		: grcps.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grnew.o		: grnew.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grcut.o		: grcut.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
grtask.o	: grtask.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_fillev.o	: gr_fillev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_hist.o	: gr_hist.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_hislev.o	: gr_hislev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_image.o	: gr_image.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_iso1.o	: gr_iso1.c gr_iso.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_iso2.o	: gr_iso2.c gr_iso.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_isolev.o	: gr_isolev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_main.o	: gr_main.c gr_xwi.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h mxv_icon.h
gr_mos.o	: gr_mos.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_moslev.o	: gr_moslev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_pal.o	: gr_pal.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_proc.o	: gr_proc.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_text.o	: gr_text.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_subs.o	: gr_subs.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_subslev.o: gr_subslev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_tile.o	: gr_tile.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_tillev.o	: gr_tillev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_toplev.o	: gr_toplev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_vbuff.o	: gr_vbuff.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_view.o	: gr_view.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_viewlev.o: gr_viewlev.c gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_xwi.o	: gr_xwi.c gr_xwi.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
gr_xwi1a.o	: gr_xwi1a.c bitmaps.h gr_xwi.h gr_def.h mxv.h
td_axes.o	: td_axes.c  td_inc.h td_var.h mxv.h gr_def.h
td_file.o	: td_file.c  td_inc.h td_var.h mxv.h
td_fits.o	: td_fits.c td_inc.h mxv.h
td_hdf.o	: td_hdf.c  td_inc.h td_var.h mxv.h
td_main.o	: td_main.c  td_inc.h td_var.h mxv.h
td_mem.o	: td_mem.c  td_inc.h td_var.h mxv.h
td_miriad.o	: td_miriad.c  td_inc.h td_var.h mxv.h gr_def.h
td_misc.o	: td_misc.c mxv.h gr_def.h
td_pixel.o	: td_pixel.c  td_inc.h td_var.h mxv.h gr_def.h
#td_port.o	:: td_port.c  td_inc.h td_var.h mxv.h version.h
td_port.o	: td_port.c  td_inc.h td_var.h mxv.h version.h
	${CC} ${CFLAGS} ${EXP} -c td_port.c

xi_mainsub.o	: xi_mainsub.c ximage.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
xi_palette.o	: xi_palette.c ximage.h gr_def.h gr_ext.h gr_inc.h gr_var.h mxv.h
