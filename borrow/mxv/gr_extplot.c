/* gr_extplot.c

Routines that deal with plotting external to mxv. (Via WIP or GNUPLOT).

TODO:
	Vector plots should have x and y axis values. Currently x axis
goes from 0..up.
*/

#ifdef sun
#define bcopy(a,b,c) memcpy((b),(a),(c))
#endif
#if defined (sun) && defined (SYSV)
#define rindex(a,b)  strrchr((a),(b))
#define  index(a,b)  strchr ((a),(b))
#endif

#include "gr_com.h"
#include "gr_plot.h"
#include "fits.h"

/*
This holds things that stay the same from one plot to the next.
*/
static PlotCtl plotctl=NULL;


/* Convert a string to plot method.
Returns INTERNALPLOT if type is unknown.
*/
static struct {
        char    *name;
        A_PlotMethod method;
        } methods[] = 
	{	{ "INTERNALPLOT", INTERNALPLOT},
		{ "WIPPLOT", WIPPLOT},
		{ "GNUPLOT", GNUPLOT}
	};
#define NMETHODS (sizeof(methods)/sizeof(*methods))

/* Convert a string to a plot method. Used to convert resource strings.*/
static A_PlotMethod gr_str_to_method(str)
char    *str;
{
int     i;

	if(str == NULL)
		return INTERNALPLOT;
	for(i=0; i< NMETHODS; i++)
		if(strcmp(str, methods[i].name) == 0)
			return methods[i].method;

	return INTERNALPLOT;
}

#ifdef __convex__
/*
 To get this to work will require splitting up the resource to use
	the setenv call.
Putenv does not exist on the convex.
Break an evironment string <Name>=<value> into <Name> and <value> parts
then call setenv().
*/
int putenv(str)
char	*str;
{
char	name[256], *value; 	/* Should be enough for MXV. */

	if( (str == NULL) || strlen(str) == 0)
		return 0;
	strcpy( name, (const char *) str);
	value = index(name, '=');
	if( value == NULL)
		return 0;	/* Something's missing. */
	*value++ = '\0';
	return setenv(name, value, 1);
}
#endif

/* Initial setup of plotctl structure. Called once at the beginning of
Mxv.
*/
void gr_InitializePlot(w)
Widget	w;
{
char	*str;

	if(plotctl != NULL)
		return;
	if( (plotctl = (PlotCtl) calloc(1, sizeof( *plotctl))) == NULL)
		return;

	plotctl->savecmdfile = plotctl->savedatafile = FALSE;
	str = gr_GetStringResource(w,
			"plot.plotMethod", "Plot.PlotMethod", "INTERNALPLOT");
	plotctl->method = gr_str_to_method(str);
	plotctl->tmpdir = gr_GetStringResource(w,
				"plot.tmpDir", "Plot.Directory", "/tmp");
	plotctl->contourimage = gr_GetBooleanResource(w,
			"plot.contourImage", "Plot.ContourImage", FALSE);

	plotctl->hardcopy = NULL;
	/* Generate standard argv array. */
	plotctl->progname = "xterm";
	plotctl->argv[0] = "xterm";	/* Run an xterm.	*/
	plotctl->argv[1] = "-geom";
	plotctl->argv[2] = "80x4";
	plotctl->argv[3] = "-e";
	plotctl->argv[4] = NULL; plotctl->progindx = 4;
	plotctl->argv[5] = NULL; plotctl->cmdfileindx = 5;
	plotctl->argv[6] = NULL;	/* Need a terminating NULL.	*/
	/* Get commands to use to execute WIP &/or gnuplot. */
	plotctl->wipcmd = gr_GetStringResource(w,
		"plot.wipCommand", "Plot.Command", "wip");
	plotctl->gnucmd = gr_GetStringResource(w,
		"plot.gnuCommand", "Plot.Command", "gnuplot");

	/* Wip needs the PG_PLOT environment variable set. */
	/* This should be a string of the form:
		PGPLOT_FONT=/data/miriad/nov.miriad/lib/sun4/grfont.dat
	*/

	str = gr_GetStringResource(w,
		"plot.wipEnvironment", "Plot.Environment", NULL);
	if(str != NULL)
		putenv(str);
	/* Gnuplot doesn't need one, but just in case... */
	str = gr_GetStringResource(w,
		"plot.gnuEnvironment", "Plot.Environment", NULL);
	if(str != NULL)
		putenv(str);
}


/* Create a new PlotData struct and fill in the pointer to plotctl.
If plotdata is non NULL, fill it in and don't reallocate.
Returns a pointer to the (new) struct or NULL if could not allocate memory.
*/
PlotData NewPlotData(plotdata)
PlotData	plotdata;
{
	if(plotdata == NULL)
	{	plotdata = (PlotData) calloc(1, sizeof(*plotdata));
		if(plotdata == NULL)
			return NULL;
	}
	plotdata->plotctl = plotctl;
	return plotdata;
}

/* When a menu selection is made, the called routine sets the plot method
in the global plotctl struct. This routine lets it do that.
Returns FALSE if plotctl has not been setup yet, else TRUE.
*/
Boolean	SetPlotMethod(method)
A_PlotMethod	method;
{
	if(plotctl == NULL)
		return FALSE;
	plotctl->method = method;
	return TRUE;
}

/* Generate an absolute filename given a base filename and some hints
as to which directory to use.

If save is true, file is put in the data directory. Otherwise, it is put
in /tmp.

If MIRIAD format, suffix is the name of the file in
the directory. Otherwise, suffix is appended to the current pathname.

name	Pointer to an array to hold the filename. It is assumed to be big
	enough.
data	Data struct used to access pathname and format.
filename Base filename.
suffix	Suffix to append to filename;
save	If true, use datadir from 'data' otherwise, use /tmp.

Return is a pointer to name or NULL if something failed.
*/
static char *makefilename(name, data, filename, suffix, save)
char		*name;		/* Where the name goes. */
A_Data_t	*data;
char		*filename, *suffix;
Boolean		save;
{
char	*sep, *pn;

	if(name == NULL)
		return NULL;
	if( !save)
	{	pn = plotctl->tmpdir;
		sep = "/";
	}
	else
	{	pn = data->pathName;
		sep = (data->format == MIRIAD) ? "/" : ".";
	}
	sprintf(name, "%s%s%s%s", pn, sep, filename, suffix);
	return name;
}

/* Display the names of the command and data files in the log window. */
static void logfiles(plot)
PlotData	plot;
{
char msg[MAXPATHLEN+32];

	/* Display names of cmd/data files. */
	sprintf(msg,"Command file is:\n\t%s\n", plot->cmdfilename);
	gr_TextMsgOut(msg);
	sprintf(msg,"Data file is:\n\t%s\n", plot->datafilename);
	gr_TextMsgOut(msg);
}

/* Run plot program.
*/
static int runPlotProg(plot, prog, argv)
PlotData	plot;
char		*prog, **argv;
{
	if( fork() == 0)
	{	execvp(prog, argv);
		/* Error in child!! */
		exit(-1);
	}

	return 0;
}

/* Most plots are previews. This little convenience routine packs up
the relevant information and calls runPlotProg.
*/
static void preview_plot(plot, plotprog)
PlotData	plot;
char		*plotprog;
{
PlotCtl	pc = plot->plotctl;

	plot->preview = TRUE;
	pc->argv[pc->progindx] = plotprog;
	pc->argv[pc->cmdfileindx] = plot->cmdfilename;
	runPlotProg(plot, pc->progname, pc->argv);
}

/*
Generate GNU format command and data files and put their names in the plot
struct. Then executes GNUPLOT.

Returns 0 if OK, else non zero.
*/

static int plot_gnu(plot, plotfunction)
PlotData	plot;
A_PlotFunction	plotfunction;
{
FILE	*file;
char	*datafilename, *cmdfilename;
int	rows, cols, nvals, i;
float	*f, val, ymin, ymax, xmin, xmax;
PlotCtl	pc;
Boolean		preview, needImage;

	if(plot == NULL)
		return 0;

	pc = plot->plotctl;
	/* Generate the filenames. */
	datafilename = makefilename((plot->datafilename), plot->data,
				plot->filename, ".dat",
				plotfunction == SAVEPLOT);
	cmdfilename = makefilename((plot->cmdfilename), plot->data,
				plot->filename, ".gnu.cmd",
				plotfunction == SAVEPLOT);


	if( (file = fopen( datafilename, "w")) == NULL)
		return gr_perror("Plot_gnu-%s: ", datafilename);

	/****************	DATA FILE	****************/
	/* Make the title of the plot a datafile comment. */
	if(plot->title != NULL)
		fprintf(file, "# %s\n", plot->title);
	f=plot->pdata;
	ymax = ymin = *f;
	nvals =  plot->nrows*plot->ncols;
	needImage = plot->contourplot || plot->imageplot;

	/***!!! Add comments to data file giving object name and stats. */
	if( plot->vectorplot)
	{	fprintf(file, "# %d values\n", nvals);
		for(i =0; i< nvals; i++)
		{	val = *f++;
			if(val < ymin) ymin = val;
			if(val > ymax) ymax = val;
				fprintf(file, "%f\n", val);
		}
		xmax = (float) (nvals - 1);
	}
	else
	if( needImage )
	{	fprintf(file, "# %d rows, %d columns\n",
					plot->nrows, plot->ncols);
		for( rows = 0; rows < plot->nrows; rows++)
		{	for( cols = 0; cols < plot->ncols; cols++)
			{	val = *f++;
				if(val < ymin) ymin = val;
				if(val > ymax) ymax = val;
				fprintf(file, "%f\n",  val);
			}
			fprintf(file, "\n");
		}
		xmax = (float) (plot->ncols - 1);
	}
	/**********	COMMAND FILE		************/
	xmin = 0.0;
	fprintf(file, "# Min = %f, Max = %f\n", ymin, ymax);
	fclose(file);

	if( (file = fopen(cmdfilename, "w")) == NULL)
		return gr_perror("Plot_gnu-%s:", cmdfilename);

	if(plot->drawtitle)
		fprintf(file, "set title \"%s\"\n", plot->title);
	fprintf(file, "set nokey\n");
	if(plot->drawxtitle)
		fprintf(file, "set xlabel '%s'\n", plot->xtitle);
	if(plot->drawytitle)
		fprintf(file, "set ylabel '%s'\n", plot->ytitle);
	if(plot->vectorplot)
	{	fprintf(file, "set data style linespoints\n");
		fprintf(file, "plot '%s'\n", datafilename);
	}
	else
	if(needImage)
	{	fprintf(file, "set data style lines\n");
		if(plot->contourplot)
		{	fprintf(file, "set contour base\n");
			if(plot->ncontours > 0)
				fprintf(file, "set cntrparam levels %d\n",
							plot->ncontours);
		}
		if(plot->imageplot)
		{	fprintf(file,
		   "#Uncomment next two lines for contour/surface plot.\n");
			fprintf(file, "#set nosurface\n");
			fprintf(file, "#set view 0,0,1\n");
		}
		else
		{	fprintf(file,
			"#Comment next two lines for contour only plot.\n");
			fprintf(file, "set nosurface\n");
			fprintf(file, "set view 0,0,1\n");
		}

		fprintf(file, "splot '%s'\n", datafilename);
	}

	fprintf(file, "pause -1 \"Press <return> to exit.\"\n");

	fclose(file);

	logfiles(plot);		/* Display file names. */

	switch(plotfunction) {
	case PREVIEWPLOT:
			preview_plot(plot, pc->gnucmd);
			break;
	case PRINTPLOT:
			break;
	case SAVEPLOT:
			break;
	default:
			break;
	}
	return 0;
}

#if 0
/* Allocate memory pointers to make a 3d array. */
float32 ***setup(x,y,z, data)
int32 	x,y,z;
float	*data;
{
float32	***arr,*p,**q;
int32	i,j;


	arr = (float32 ***)calloc(1, (unsigned)(x*sizeof(float32 **)+
						x*y*sizeof(float32 *)));
	if (arr == NULL)
	{
		gr_TextMsgOut(
			"***ERROR: Not enough memory when mallocing.\n");
		return(NULL);
	}

	q = (float32 **)(arr+x);
	p = data;
	for (i=0;i<x;i++)
	{	arr[i] = q;
		q += y;
		for (j=0;j<y;j++)
		{	arr[i][j] = p;
			p += z;
		}
	}

	return(arr);
}
#endif

/* Routine to initialize a cval struct. */
static void crload(cval, label, crval, crpix, cdelt)
char	*label;
float	crval, crpix, cdelt;
Cvalues	cval;
{
	cval->ctype = StringToQuark(label);
	cval->crval = crval;
	cval->crpix = crpix;
	cval->cdelt = cdelt;
}

/* Create a data file in FITS format.
If the input file was HDF, have to make up some values to feed to the FITS
routines.

*/
static void writeFITSfile(plot, datafilename)
PlotData	plot;
char		*datafilename;
{
A_Axes_t *orient;
A_Data_t *data;
cvalues cvals[3];
int	i, j, axis, ncols, nrows;
float	*p, delta, val0;

	data = plot->data;
	orient = plot->axesOrient;
	/* Get axes from orient and generate 'c' values. */
	if(data->format == HDF)
	{	axis = orient->col;
		i = axis - 1;
		val0 = td_GetAxisValue(data, 0, axis, FALSE);
		delta = td_GetAxisValue(data, 1, axis, FALSE) - val0;
		crload(&cvals[0], data->label[i], val0, 0.0, delta, 1.0);

		axis = orient->row;
		i = axis - 1;
		val0 = td_GetAxisValue(data, 0, axis, FALSE);
		delta = td_GetAxisValue(data, 1, axis, FALSE) - val0;
		crload(&cvals[1], data->label[i], val0, 0.0, delta, 1.0);

		axis = orient->axis;
		i = axis - 1;
		val0 = td_GetAxisValue(data, 0, axis, FALSE);
		delta = td_GetAxisValue(data, 1, axis, FALSE) - val0;
		crload(&cvals[2], data->label[i], val0, 0.0, delta, 1.0);
	}
	else
	{	i = orient->col - 1;
		bcopy( &data->cvals[i], &cvals[0], sizeof(cvals[0]));
		i = orient->row - 1;
		bcopy( &data->cvals[i], &cvals[1], sizeof(cvals[1]));

		axis = orient->axis;
		i = axis - 1;
		crload(&cvals[2], data->label[i],
			td_GetAxisValue(data, orient->plane, axis, FALSE),
			0.0, data->cvals[i].cdelt);
	}

	ncols = (plot->flipx) ? -plot->ncols : plot->ncols;
	nrows = (plot->flipy) ? -plot->nrows : plot->nrows;

	/* Write the plane upside down since its stored funny. */
	/* May need to add a boolean at some date. */
	td_FITSWritePlane( datafilename, data->dataName,
		plot->pdata, ncols, nrows,
		cvals, TRUE, orient->plane);
}

#define	PAPER_WIDTH	4.0

static int plot_wip2d( plot, plotfunction)
PlotData	plot;
A_PlotFunction	plotfunction;
{
FILE	*file;
char	*datafilename, *cmdfilename;
PlotCtl	pc;
int	i;
A_Axes_t *orient;
A_Data_t *data;
float	aspect, paperwidth;
char	*xhms, *yhms;	/* x/y hr:min:sec specifiers. */

	if((plot == NULL) || ( !plot->contourplot && ! plot->imageplot))
		return 0;

	pc = plot->plotctl;

	/* Generate the filenames. */
	makefilename((plot->datafilename), plot->data,
				plot->filename, ".fits",
				plotfunction == SAVEPLOT);
	datafilename = plot->datafilename;
	cmdfilename = plot->cmdfilename;


	/****************	DATA FILE	****************/
	writeFITSfile(plot, datafilename);

	/****************	COMMAND FILE	****************/

	if( (file = fopen(cmdfilename, "w")) == NULL)
		return gr_perror("Plot_wip-%s:", cmdfilename);

/*	fprintf(file, "paper 4.0 1.0\n");*/	/* Want small size. */
					
	aspect = ((float)plot->nrows)/((float)plot->ncols);
#if 0
	if(aspect < 1.0)
		paperwidth = PAPER_WIDTH;
	else
		paperwidth = PAPER_WIDTH/aspect;
#else
		paperwidth = PAPER_WIDTH;
#endif
	fprintf(file, "paper %f %f\n", paperwidth, aspect);
	fprintf(file, "image %s\n", datafilename);

	data = plot->data;
	if( ((data->format == MIRIAD) || (data->format == FITS))
		&& (orient = plot->axesOrient) != NULL)
	{
		fprintf(file, "header\n");
		fprintf(file, "expand 0.75\n"); /* Need small chrs */
		/* Tell WIP to HMS labeling if desired. */
		xhms = (plot->xhms) ? "z" : " ";
		yhms = (plot->yhms) ? "z" : " ";
		fprintf(file, "box bcnst%s bcnst%s\n", xhms, yhms);
		fprintf(file, "expand 1.0\n"); /* Back to default. */
	}
	if(plot->ncontours > 0)
	{	if(plot->contourlevels == NULL)
			fprintf(file,
				"autolevs %d\n", plot->ncontours);
		else
		{	fprintf(file, "levels ");
			for(i=0; i< plot->ncontours; i++)
				fprintf(file, " %5.2f",
					plot->contourlevels[i]);
			fprintf(file, "\n");
		}
	}

	if(plot->drawtitle)
		fprintf(file, "mtext T 1.0 0.5 0.5 %s\n", plot->title);
	if(plot->drawxtitle)
		fprintf(file, "mtext B 3.2 0.5 0.5 %s\n", plot->xtitle);
	if(plot->drawytitle)
		fprintf(file, "mtext L 3.2 0.5 0.5 %s\n", plot->ytitle);
	if(plot->imageplot)
		fprintf(file, "halftone\n");
	if(plot->contourplot)
		fprintf(file, "contour t\n");

	fclose(file);

	return 0;
}


/* Create command and data files to make a vector plot from wip. */
static int plot_wip1d( plot, plotfunction)
PlotData	plot;
A_PlotFunction	plotfunction;
{
FILE	*file;
char	*datafilename, *cmdfilename;
int	nvals, i;
float	*f, val, xmin, xmax, ymin, ymax;
PlotCtl	pc;
A_Axes_t *orient;
A_Data_t *data;

	if((plot == NULL) || ! plot->vectorplot)
		return 0;

	pc = plot->plotctl;

	/* Generate the filenames. */
	makefilename((plot->datafilename), plot->data,
				plot->filename, ".dat",
				plotfunction == SAVEPLOT);
	datafilename = plot->datafilename;
	cmdfilename = plot->cmdfilename;

	/****************	DATA FILE	****************/
	if( (file = fopen( datafilename, "w")) == NULL)
		return gr_perror("Plot_wip-%s: ", datafilename);

	if(plot->title != NULL)
	fprintf(file, "# %s\n", plot->title);
	nvals = plot->nrows * plot->ncols;

	fprintf(file, "# %d values\n", nvals);
	f=plot->pdata;
	ymax = ymin = *f;
	for(i = 0; i < nvals; i++)
	{	val = *f++;
		if(val < ymin) ymin = val;
		if(val > ymax) ymax = val;
			fprintf(file, "%f\n", val);
	}
	xmax = (float) (nvals - 1);
	fprintf(file, "# Min = %f, Max = %f\n", ymin, ymax);
	fclose(file);
	xmin = 0.0;

	/****************	COMMAND FILE	****************/

	if( (file = fopen(cmdfilename, "w")) == NULL)
		return gr_perror("Plot_wip-%s:", cmdfilename);

	fprintf(file, "paper 4.0 1.0\n");	/* Want small size. */
	fprintf(file, "#expand 2.0\n");		/* Now need larger chars.*/
	fprintf(file, "limits %f %f %f %f\n", xmin, xmax, ymin, ymax);
	fprintf(file, "data %s\n", datafilename);
	/* Macro to generate x axis data. */
	/* This should incorporate axes scaling info if available. */
	/* Use cvals.. */
	fprintf(file, "define fillx\n");
	fprintf(file, "\tset \\10 \\10 + 1\n");
	fprintf(file, "\tset x[\\10] \\10\n");
	fprintf(file, "end\n");
	fprintf(file, "box\n");

	if(plot->drawtitle)
		fprintf(file, "mtext T 1.0 0.5 0.5 %s\n", plot->title);
	if(plot->drawxtitle)
		fprintf(file, "mtext B 3.2 0.5 0.5 %s\n", plot->xtitle);
	if(plot->drawytitle)
		fprintf(file, "mtext L 3.2 0.5 0.5 %s\n", plot->ytitle);
	fprintf(file, "ycolumn 1\n");
	fprintf(file, "set \\10 0\n");
	fprintf(file, "loop %d fillx\n", nvals);
	fprintf(file, "points\n");
	fprintf(file, "connect\n");

	fclose(file);

	return 0;
}

/* WIP image and vector plots are sufficiently different that each has
its own routine.
*/
static int plot_wip( plot, plotfunction)
PlotData	plot;
A_PlotFunction	plotfunction;
{
PlotCtl	pc;

	if(plot == NULL)
		return 0;

	pc = plot->plotctl;

	/* Generate the filenames. */
	makefilename((plot->cmdfilename), plot->data,
				plot->filename, ".wip.cmd",
				plotfunction == SAVEPLOT);

	if(plot->vectorplot)
		plot_wip1d(plot, plotfunction);
	else
		plot_wip2d(plot, plotfunction);

	logfiles(plot);		/* Display file names. */

	switch(plotfunction) {
	case PREVIEWPLOT:
			preview_plot(plot, pc->wipcmd);
			break;
	case PRINTPLOT:		/* Not supported yet. */
			break;
	case SAVEPLOT:
			break;
	default:
			break;
	}
	return 0;
}

/* Uses plot->plotctl to decide which plot routine to call. */
void gr_plot(plot, plotfunction)
PlotData	plot;
A_PlotFunction	plotfunction;
{
	switch( plot->plotctl->method) {
	case INTERNALPLOT:
		fprintf(stderr, "INTERNAL isn't here yet\n");
		break;
	case WIPPLOT:
		plot_wip(plot, plotfunction);
		break;
	case GNUPLOT:
		plot_gnu(plot, plotfunction);
		break;
	default:
		break;
	}
}

/* Plot data. */
static void gr_PlotProfile(histWin, plotfunction)
A_HistWind_t	*histWin;
A_PlotFunction	plotfunction;
{
A_DsplWind_t	*dsplWin=histWin->parent;
A_Data_t	*hdf=dsplWin->parent->parent->data;
A_Axes_t	orient;
PlotData	plot;
float32		min=hdf->min,max=hdf->max,frac=hdf->rangeFrac;
float32		***hdfdata=hdf->data;
int		i,xpos,ypos,x,y,axis, row, col;
int		nvals;
float32		*fvals;		/* Something to hold data values. */
float		xmin,xmax, ymin, ymax, val;
unsigned char	nColors = (unsigned char)gr_color.nColors;
char		filename[MAXPATHLEN+1], *ht;


	xpos = histWin->xpos;
	ypos = histWin->ypos;

	nvals = dsplWin->zdim;
	orient=dsplWin->axesOrient;
	axis = orient.axis; if (axis < 0) axis = -axis;
	row = orient.row;  if(row < 0) row = -row;
	col = orient.col;  if(col < 0) col = -col;

	/* Make a title from just the filename by
	   removing leading path compenents.
	*/
	if( (ht = rindex(hdf->pathName, '/')) != NULL)
		ht += 1;
	else
		ht = hdf->pathName;


	fvals = (float32*) malloc(nvals *sizeof(float32));
	if (fvals==NULL)
	{ printf("gr_PlotProfile: fvals malloc err\n"); return; }
	if( (plot = (PlotData) calloc(1, sizeof(*plot))) == NULL)
	{ printf("gr_PlotProfile: plot malloc err\n"); return; }
	plot->plotctl = plotctl;
	plot->data = hdf;
	plot->pdata = fvals;

	sprintf(filename, "%s.%sprofile.%d.%d", ht,
		axesLabels[axis-1], xpos, ypos);
	strcpy(plot->filename, filename);

	plot->vectorplot = TRUE;
	plot->contourplot = FALSE;
	plot->nrows = nvals;
	plot->ncols = 1;


	/* Grab the data from the dataset. */
	computeHistData (hdf, &orient,  xpos, ypos, nvals, fvals);
	sprintf(plot->title,
		"%s-axis profile of %s at [%d,%d]", 
		axesLabels[axis-1], ht, xpos, ypos);
	plot->drawtitle = TRUE;
	sprintf(plot->xtitle, "%s Axis",axesLabels[axis-1]);
	plot->drawxtitle = TRUE;

	gr_plot(plot, plotfunction);

	free (fvals);
	free(plot);
	return;
}

/***				 Plot data. 			****/
void gr_HistPlotGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_PlotProfile(histWin, PREVIEWPLOT);
}

void gr_HistSaveGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotProfile(histWin, SAVEPLOT);
}

void gr_HistPlotWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_PlotProfile(histWin, PREVIEWPLOT);
}

void gr_HistSaveWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotProfile(histWin, SAVEPLOT);
}


void gr_HistSavePS(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = INTERNALPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_HistPrint(NULL, client_data, NULL);
}

/* Save in whatever format was last used. */
void gr_HistSave(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWin=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	/* Hack since INTERNALPLOT isn't really supported here. */
	if(plotctl->method == INTERNALPLOT)
		gr_HistPrint(NULL, client_data, NULL);
	else
		gr_PlotProfile(histWin, SAVEPLOT);
}


/* ------------------------------------------------------------------ */

static void gr_PlotContour(histWind, plotfunction)
A_HistWind_t	*histWind;
A_PlotFunction	plotfunction;
{
A_DsplWind_t   *dsplWin= histWind->parent;
A_Data_t	*hdf=dsplWin->parent->parent->data;
int		r, c, nrows=dsplWin->xdim, ncols=dsplWin->ydim;
char histTitle[100], *ht;
FILE		*file;
float		*f = dsplWin->fdata;
char		*datafile, *cmdfile;
PlotData	plot;
int		xaxis, yaxis, zaxis, ra, dec;

	/* Make a title from just the filename by
	   removing leading path compenents.
	*/
	if( (ht = rindex(hdf->pathName, '/')) != NULL)
		ht += 1;
	else
		ht = hdf->pathName;

	if( (plot = (PlotData) calloc(1, sizeof(*plot))) == NULL)
	{ printf("gr_ShowContour: plot malloc err\n"); return; }
	plot->plotctl = plotctl;
	plot->data = hdf;
	plot->pdata = f;
	plot->vectorplot = FALSE;
	plot->contourplot = TRUE;
	plot->imageplot = plotctl->contourimage;
	plot->nrows = nrows;
	plot->ncols = ncols;
	plot->flipx = FALSE;
	plot->flipy = TRUE;
	plot->axesOrient = &(dsplWin->axesOrient);
	xaxis = plot->axesOrient->col;
	xaxis = (xaxis > 0) ? xaxis -1: -xaxis -1;
	yaxis = plot->axesOrient->row;
	yaxis = (yaxis > 0) ? yaxis -1: -yaxis -1;
	zaxis = plot->axesOrient->axis -1;
	getRaDec( hdf->cvals, &ra, &dec);
	plot->xhms = ((xaxis == ra) && (dec >= 0)) || (dec == xaxis);
	plot->yhms = ((yaxis == ra) && (dec >= 0)) || (dec == yaxis);

	gr_DialogGetFloatValues(histWind->conDialog,
		&plot->contourlevels, &plot->ncontours);

	sprintf(plot->filename, "%s.%s_Pln%d",
		ht, hdf->label[zaxis], plot->axesOrient->plane);

	sprintf(plot->title, "Contour of %s plane %d of %s",
		hdf->label[zaxis], plot->axesOrient->plane, ht);
	plot->drawtitle = TRUE;

	sprintf(plot->xtitle, "%s", hdf->label[xaxis]);
	plot->drawxtitle = TRUE;
	sprintf(plot->ytitle, "%s", hdf->label[yaxis]);
	plot->drawytitle = TRUE;

	gr_plot(plot, plotfunction);
	if(plot->contourlevels != NULL)
		free(plot->contourlevels);
	free(plot);
}

/* ------------------------------------------------------------------ */

/***				 Plot data. 			****/
void gr_ContourPlotGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_PlotContour(histWind, PREVIEWPLOT);
}

void gr_ContourSaveGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotContour(histWind, SAVEPLOT);
}

void gr_ContourPlotWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_PlotContour(histWind, PREVIEWPLOT);
}

void gr_ContourSaveWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotContour(histWind, SAVEPLOT);
}

void gr_ContourSavePS(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = INTERNALPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_Dsplbegincontour(NULL, client_data, NULL);
}

/* Save in whatever format was last used. */
void gr_ContourSave(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	/* Hack since INTERNALPLOT isn't really supported here. */
	if(plotctl->method == INTERNALPLOT)
	{
		gr_Dsplbegincontour(NULL, client_data, NULL);
	}
	else
		gr_PlotContour(histWind, SAVEPLOT);
}


/* ------------------------------------------------------------------ */
/*			Save Trace				*/

/* Return a plane of data given the trace vector.
dsplWin	The stuct that holds the data cube & other info.
data	Address of pointer to float. The address of the data plane will be
	put here. The caller will have to free the array when done.
numx,	Addresses of where to put the size of the array.
numy

Returns 0 if OK, else -1 (Not enough memory).

This was taken almost verbatum from grnew.c:mytempsaveprog.
(The row/col retrieval order is different).

For each level in the 'Z' direction a 'row' is extracted using the x/y
pairs as position. The 'row' isn't necessarily a row from the cube.
The x/y pairs may actually form a curve. The resulting plane will be
zdim wide and numpoints high.
*/
static int getTraceData(histWind, data, numx, numy)
A_HistWind_t	*histWind;
float		**data;
int		*numx, *numy;
{
A_DsplWind_t	*dsplWin = histWind->parent;
A_Data_t	*hdf=dsplWin->parent->parent->data;
A_Axes_t	orient;
float		***hdfdata=hdf->data;
int		i, j, dstart, dend, xpos, ypos, axis, col;
int		numpoints, *traceX, *traceY;
float		*savdata, *sdat;

	orient=dsplWin->axesOrient;
	dstart = 0;		/* always start from plane 0 */
	dend = dsplWin->zdim;
	numpoints =  histWind->ntraced;
	traceX = histWind->traceX;
	traceY = histWind->traceY;
	if((numpoints <= 0) || (dsplWin->zdim <= 0)) return -1;
	if((traceX == NULL) || (traceY == NULL)) return -1;

/*	printf("getTraceData: %d trace points.\n", numpoints);*/

	if ( NULL== (savdata = 
	(float32*) malloc(numpoints * dsplWin->zdim * sizeof(float))))
	{
		gr_TextMsgOut("getTraceData: Can't allocate memory.\n");
		return -1;
	}
	sdat = savdata;	/* Data will be saved in this mem  block */

	axis = orient.axis;
	if (axis < 0) axis = -axis;
	col = orient.col;
	if(col < 0) col = -col;

	switch (axis)
	{
	 case  1:
		if ((col == -2) || (col == 2))
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) { 
					ypos = traceY[j];
					xpos = traceX[j];
					*sdat++ = hdfdata[i][xpos][ypos];
				}
			}

		else
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) { 
					ypos = traceY[j];	
					xpos = traceX[j];	
					*sdat++ = hdfdata[i][ypos][xpos];
				}
			}
		break;
	 case  2:
		if ((col == -1) || (col == 1))
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) { 
					ypos = traceY[j];	
					xpos = traceX[j];	
					*sdat++ = hdfdata[xpos][i][ypos];
				}
			}
		else
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) { 
					ypos = traceY[j];	
					xpos = traceX[j];	
					*sdat++ = hdfdata[ypos][i][xpos];
				}
			}
		break;
	 case  3:
		if ((col == -1) || (col == 1))
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) {
					ypos = traceY[j];	
					xpos = traceX[j];	
					*sdat++ = hdfdata[xpos][ypos][i];
				}
			}
		else
			for(j=0;j<numpoints;j++) {
				for (i=dstart;i<dend;i++) {
					ypos = traceY[j];	
					xpos = traceX[j];	
					*sdat++ = hdfdata[ypos][xpos][i];
				}
			}
		break;
	}

	*data = savdata;
	*numx = dend;
	*numy = numpoints;
	return 0;
}

/* Orient struct for traces.
	Orient.row = 2	(Y axis is 2).
	Orient.col = 1  (X axis is 1).
*/
static A_Axes_t Orient = { 2, 1, 3, 0};

/* Generate a plot of a 'trace' of the cube by using a list of x/y points
in a plane and generating a new plane from the third axis at each of the
x/y points. Since the new plane only has one of the original axis, a new
data struct has to be generated and several values filled in for lower
level routines.
*/
static void gr_PlotTrace(histWind, plotfunction)
A_HistWind_t	*histWind;
A_PlotFunction	plotfunction;
{
A_DsplWind_t   *dsplWin= histWind->parent;
A_Data_t	*dp;
int		i, r, c, nrows=dsplWin->xdim, ncols=dsplWin->ydim;
char histTitle[100], *ht;
FILE		*file;
float		*f;
char		*datafile, *cmdfile, cvtmplabel[MAXNAMELEN];
PlotData	plot;
int		zaxis;
int		numx, numy, ra, dec;
cvalues		*cv, cvtmp;

	/* Get the trace data. */
	if( getTraceData(histWind, &f, &numx, &numy) != 0)
		return;

	/*
	Make a copy of the data struct and fill in special values.
	cvals	x is 'z' axis of cube.
		y is the trace plane.
		z is nothing or DEC--SIN if x is RA---SIN.
	*/
	if( (dp = (A_Data_t *)malloc(sizeof(*dp))) == NULL)
	{	gr_TextMsgOut("gr_PlotTrace: Could not allocate memory.");
		free(f);
		return;
	}

	bcopy(dsplWin->parent->parent->data, dp, sizeof(*dp));
	if( (plot = (PlotData) calloc(1, sizeof(*plot))) == NULL)
	{	printf("gr_PlotTrace: plot malloc err\n");
		free(f);
		free(dp);
		return;
	}
	zaxis = dsplWin->axesOrient.axis;
	if(zaxis < 0) zaxis = -zaxis;
	zaxis = zaxis -1;
	/*		 New cvals.		*/
	/* If Z axis is RA---SIN, then look for a DEC--SIN and use it as
	   as new 'Z' axis so RA---SIN conversions will work if read in again.
	   Otherwise, just make something up.
	*/
	cv = &dp->cvals[0];
	getRaDec( cv, &ra, &dec);
	strcpy(cvtmplabel, " ");		/* Default.	*/
	crload(&cvtmp, cvtmplabel, 0.0, 0.0, 0.0);
	if(( ra == zaxis) && (dec >= 0))
	{	/* Save DEC__SIN cval for third axis. */
#if defined (sun)
		bcopy(&(cv[dec]), &cvtmp, sizeof(cvtmp));
#else
		bcopy(cv[dec], &cvtmp, sizeof(cvtmp));
#endif
		strcpy(cvtmplabel, dp->label[dec]);
		plot->xhms = TRUE;
	}
	else
	if( dec == zaxis)
		plot->xhms = TRUE;
	else	
		plot->xhms = FALSE;
	plot->yhms = FALSE;

	/* Copy Z axis values to X position. */
	if( zaxis != 0)
	{	bcopy( &dp->cvals[zaxis],
			&dp->cvals[0], sizeof(dp->cvals[0]));
		strcpy(dp->label[0], dp->label[zaxis]);
	}
	/* Initialize y/z axis to something. */
	strcpy(dp->label[1], "TRACEPLN");
	crload(&dp->cvals[1], dp->label[1], (float)(numy-1), 0.0, -1.0);
	strcpy(dp->label[2], cvtmplabel);
	bcopy(&cvtmp, &dp->cvals[2], sizeof(cvtmp));

	/* Make a title from just the filename by
	   removing leading path compenents.
	*/
	if( (ht = rindex(dp->pathName, '/')) != NULL)
		ht += 1;
	else
		ht = dp->pathName;

	plot->plotctl = plotctl;
	plot->data = dp;
	plot->pdata = f;
	plot->vectorplot = FALSE;
	plot->contourplot = FALSE;
	plot->imageplot = TRUE;
	plot->nrows = numy;
	plot->ncols = numx;
	plot->flipx = FALSE;
	plot->flipy = FALSE;
	plot->axesOrient = &Orient;

	sprintf(plot->filename, "%s.trace", ht);

	sprintf(plot->title, "Trace along %s axis of %s",
		dp->label[0], ht);
	plot->drawtitle = TRUE;

	sprintf(plot->xtitle, "%s", dp->label[0]);
	plot->drawxtitle = TRUE;
	sprintf(plot->ytitle, "%s", dp->label[1]);
	plot->drawytitle = TRUE;

	gr_plot(plot, plotfunction);

	free(f);
	free(dp);
	free(plot);
}

/* ------------------------------------------------------------------ */

/***				 Trace	 			****/
void gr_TracePlotGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_PlotTrace(histWind, PREVIEWPLOT);
}

void gr_TraceSaveGNU(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = GNUPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotTrace(histWind, SAVEPLOT);
}

void gr_TracePlotWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_PlotTrace(histWind, PREVIEWPLOT);
}

void gr_TraceSaveWIP(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = WIPPLOT;
	gr_SetMenuSelection( NULL, w);
	gr_PlotTrace(histWind, SAVEPLOT);
}

void gr_TraceSavePS(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	plotctl->method = INTERNALPLOT;
	gr_SetMenuSelection( NULL, w);
/*	gr_DsplbeginTrace(NULL, client_data, NULL);*/
}

/* Save in whatever format was last used. */
void gr_TraceSave(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
A_HistWind_t	*histWind=(A_HistWind_t *)client_data;

	if(plotctl == NULL)
		return;
	/* Hack since INTERNALPLOT isn't really supported here. */
	if(plotctl->method == INTERNALPLOT)
	{
/*		gr_DsplbeginTrace(NULL, client_data, NULL);*/
	}
	else
		gr_PlotTrace(histWind, SAVEPLOT);
}
