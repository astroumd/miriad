/* gr_plot.h
Include file for MXV routines that want to do plotting.

Currently, plots can be done either internally or externally. Internal
plots are done via a call to an MXV plot routine. External plots are done
by writing command and data files then forking the desired plotting program.
Currently, WIP and GNUPLOT are supported. Usually, the fork starts up
an Xterm that executes the plot program. This allows multiple plots to
be displayed. (It is necessary to ^C or type a return to exit the plots.

There are two structures used. The first is global and is used to determine
which plotting technique to use. If an external plot program is used, it
must be in the user's search path.

The second structure contains the data pertinent to the specific plot.

This not meant to be a general purpose plot interface. Its only supposed
to be able to generate preview plots and make data files so users can import
them into other programs.
*/

/* What is used to generate plot. */
typedef enum { INTERNALPLOT, WIPPLOT, GNUPLOT} A_PlotMethod;
/* 
All Functions generate data/command files. (Unless Internal is used).
PREVIEW	bring up a display window.
PRINT	Will generate some sort of output file (Postscript, LaTeX, etc).
	The file may be sent to the printer. (If WIP).
SAVE	Only the Command/Data files are generated. The plot program is not
	called.

PRINT mode is not currently supported.
*/
#ifndef __convex__
/* Needed for rindex when generating names. */
#if defined (sun) && defined (SYSV)
#include <string.h>
#else
#include <strings.h>
#endif
#endif

typedef enum { PREVIEWPLOT, PRINTPLOT, SAVEPLOT} A_PlotFunction;

/* Initial values for these come from resources. */
typedef struct {
	A_PlotMethod	method;		/* What should be used to do plots. */
	char		*hardcopy;	/* What device should be used to
					   generate hardcopy plots. Since each
					   method supports different plots,
					   this gets reset to NULL when method
					   changes. NULL means use default.
					*/
	char		*wipcmd,	/* filename w/path of wip and  */
			*gnucmd;	/* gnuplot commands. -> resources.*/
	Boolean		savedatafile;	/* If false, hardcopy & preview
					   data files will be placed in
					   /tmp. Otherwise, the directory
					   of the data file will be used.
					*/
	Boolean		savecmdfile;	/* Same, but for command file.	*/
	char		*tmpdir;	/* tmp directory.		*/
	Boolean		contourimage;	/* If true, image is displayed with
					   contours, else just contour.
					*/
	/* Most plots are assumed to be 'preview' plots which use an xterm.
	   to run the plot program. For this case, the args to runPlotProg
	   are mostly constant, so here they are. Only the names of the
	   plot program and its command file need be entered. Hardcopy plots
	   will usually not run an xterm and will have an argv built.
	*/
	char		*progname;	/* "xterm"	*/
	char		*argv[7];	/* Place for standard args to execvp.
					   Non standard need to make their own.
					*/
	int		progindx,	/* Where program name and cmd strings*/
			cmdfileindx;	/* Should be stuffed.		*/
	} *PlotCtl;

/* If a char * variable is NULL, the plot won't contain it. */
typedef struct {
		PlotCtl	plotctl;	/* Pointer to control struct. */
	Boolean		preview;	/* True means do preview plot. FALSE,
					   hardcopy.
					*/
		float	xmin,ymin,	/* WIP seems to need these. */
			xmax,ymax;
		Boolean	drawtitle,
			drawxtitle,
			drawytitle;
		/* Various type of plots. */
		Boolean	vectorplot;	/* If true, do it. */
		Boolean	contourplot;	/* Not all methods can do everything.*/
		Boolean	imageplot;	/* Especially at once. */
		Boolean	surfaceplot;
		/* The above are probably mutually exclusive. */
		Boolean	flipx, flipy;	/* Whether to reverse direction of
					   writing x/y axis. (Only supported
					   in wip2d).
					*/
		Boolean xhms, yhms;	/* If true, axis lables should be
					   hours mins, secs. (only supported
					   int wip2d).
					*/
		int	nrows, ncols;	/* For vector plots, set nrows = nvals
					   and ncols = 1.
					*/

		float	*pdata;		/* Data to be plotted. */
		float	*contourlevels;	/* Pointer to list of contour values.*/
		int	ncontours;	/* length of contourlevels. */
					/* If ncontours > 0, but contourlevels
					   == NULL, should just choose levels.
					*/
		A_Data_t *data;		/* Pointer to data struct wanting
					   the plot. Currently only pathname
					   and format are needed. (To generate
					   filenames).
					*/
		A_Axes_t *axesOrient;	/* Pointer to orientation struct
					   that tells which data axis is
					   being display where.
					*/
		char	filename[MAXPATHLEN+1];
					/* 'Bare' filename to be used to
					   generate cmd & data file names.
					   Actual file names will have an
					   absolute path prepended and
					   indications of method and data/cmd
					   appended.
					*/
			/* Full cmd & data file names.
			*/
		char	datafilename[MAXPATHLEN+1],
			cmdfilename[MAXPATHLEN+1];
		char	title[80];		/* Plot title. */
		char	xtitle[80],	/* X/Y titles.	*/
			ytitle[80];
	} *PlotData;

extern PlotData NewPlotData();		/* Allocate new PlotData struct. */
extern Boolean	SetPlotMethod();	/* Sets plotmethod global var.	*/
