/*
 *	File:		gr_def.h
 *	Contents:	Header file containing all the typedefs and defs used
 *				by the graphics module.
 */

#ifndef	_GR_DEF_H
#define	_GR_DEF_H

#include "mxv.h"

#define MAX_ANILEV_WINDS	100
#define MAX_ARBLEV_WINDS	1
#define MAX_BOSLEV_WINDS	100
#define MAX_CUBLEV_WINDS	1
#define MAX_DICELEV_WINDS	100
#define MAX_DSPLEV_WINDS	100
#define MAX_HISTLEV_WINDS	100
#define MAX_ISOLEV_WINDS	100
#define MAX_FILLEV_WINDS	1
#define MAX_MOSLEV_WINDS	100
#define MAX_SUBSLEV_WINDS	100
#define MAX_TILLEV_WINDS	100
#define MAX_VIEWLEV_WINDS	100

#define MAX_TILLEV_TILES	15
#define MAX_TRACE_SELPTS	30
/* 2 datadirs.	*/
#define	MAXFILEWINDIRS		 2


typedef enum { AXES, ARBITRARY, DICER, ISO } A_DisplayMode_t;

typedef enum {
	LOADRAS, LOADSDS, LOADPAL, LOADPALSPLIT, 
	SAVEANI, SAVEDICER, SAVEDISKA, SAVEDISKP, SAVEDISKI, SAVEDSPL,
	SAVEISO, SAVEPROC, SAVETILE, SAVEVIEW, SAVEVBUFF,SAVEPS, /* jng */
	SAVEPAL, SAVEPALSPLIT /* hr */
} A_FileAction_t;

typedef enum { 	AUTOOFF, AUTOREVERSE, AUTOREPEAT } A_PlayMode_t;
typedef enum { LEFT_JUSTIFY, RIGHT_JUSTIFY, CENTER_JUSTIFY } A_Justify_t;
typedef enum {NOSCROLL, VERTONLY, HORIZONLY, VERTHORIZ, PORTHOLE } A_Scroll_t;
typedef enum { SELECTABLE, NONSELECTABLE } A_TextSelect_t;
typedef enum { FILESOURCE, STRINGSOURCE } A_TextSource_t;
typedef enum { AUTO, UNFOLDED } A_Tile_t;
typedef enum { NONE, DIAMOND, SQUARE, UP, DOWN, LEFT, RIGHT } A_ToggleShape_t;
typedef enum { SMALL, MEDIUM, MEDIUM_BOLD, LARGE, LARGE_BOLD } A_Font_t;
typedef	enum { DIR_NONE, DIR_TOP, DIR_BOTTOM, DIR_LEFT, DIR_RIGHT, DIR_CENTER
		} A_Direction_t;
typedef enum { DISPLAY_NEVER=0, DISPLAY_SOMETIMES,
			DISPLAY_ALWAYS } A_DisplayTimes_t;
/* Describe which file directory is being referenced.
CURRENTDIR	use value of fileWin->currentdir;
DIRFENCE	highest valid (normal) directory index.
*BACKUP		These locations are used to store the initial values.
DIROFFSET	Offset, when added to a directory index, gives its backup.
		(implies dirs are contiguous. Same with backups).
(Backups not used for now).
*/
typedef enum { CURRENTDIR=-1, DATADIR=0, PALETTEDIR=1, DIRFENCE=1,
		DATABACKUP=2, PALETTEBACKUP, DIROFFSET=DATABACKUP-DATADIR
		} A_Directory_t;

typedef enum { NORMALCMAP=0, SPLITCMAP=1} A_Colormap_t;

typedef struct A_SubsType_t {
	double	lower, upper, opacity;
	int	red, green, blue;
} A_SubsType_t;

typedef struct A_BoxVert_t {
	int			id;
	double			x,y,z;
	struct A_BoxEdge_t 	*enode;
	struct A_BoxVert_t 	*next;
} A_BoxVert_t;

typedef struct A_BoxEdge_t {
	int			id;
	int			adj[7];
	struct A_BoxVert_t	*v1,*v2;
	struct A_BoxEdge_t	*next;
} A_BoxEdge_t;

typedef	struct A_Box_t	{
	int			numCuts;
	int			xdim,ydim,zdim;
	int			indepth;
	int			xpicsize,ypicsize;
	double			xorig,yorig,zorig;
	double			xlen,ylen,zlen;
	double			boundxmin,boundxmax;
	double			boundymin,boundymax;
	double			xmin,xmax;
	double			ymin,ymax;
	double			zmin,zmax;
	double			dimFactor;
	double			matrix[5][5];
	double			invmatrix[5][5];
	double			xangle,yangle;
	double			depth;
	struct A_BoxVert_t	*origVList;
	struct A_BoxVert_t	*vertList;
	struct A_BoxEdge_t	*edgeList;
	struct A_BoxVert_t	*cutVList;
	struct A_BoxEdge_t	*cutEList;
	struct A_Box_t		*next;
} A_Box_t;

typedef struct {
	/*	1:X 2:Y 3:Z */
	int row;
	int col;
	int	axis;
	int	plane;
} A_Axes_t;

typedef struct {
	unsigned long	white, black;
	int		nColors, maxColors;
	unsigned int	depth,shiftbits;
	Boolean		canSet,defCanSet;
	XColor		cmapCells[256];
	unsigned char	palette[768];
} A_Color_t;

/* contains mapping information needed to translate between data and pixel
values.
*/
typedef struct pixelMapping {
		int	npixels;	/* Number of available pixels. */
		unsigned char map[256];	/* Converts pixel in the
					range 0..npixels-1 to a valid pixel.
					Entries npixels..255 are undefined.
					*/
		short	unmap[256];	/* Converts a pixel to 0..npixels-1.
					   An entry of -1 means an invalid
					   pixel.
					*/
	} pixelMapping;

typedef	struct A_AniWind_t {
	Widget	shell,win;
	Widget	imageVPort,imageWin;
	Widget	skipDialog;
	Widget	frameDialog;
	Widget	frameSlider;
	Widget	speedSlider;
	GC		imageWinGC;
	XImage	**ximage;
	Pixmap	*image;
	char	*pathname;
	char	**data;
	long	speed;
	int		skip;
	int		playStop;
	int		aniType;
	int		scale,offset;
	int		curplane,numplanes;
	int		xorg,yorg,tickMark;
	int		*imagexsize,*imageysize;
	Boolean	usePixmap,useDisk,gridOn;
	A_Axes_t 		axesOrient;
	A_PlayMode_t	autoMode;
	struct A_HistWind_t	*contourWin;
	struct A_AniWind_t	*next,*prev;
	struct A_CubeWind_t	*parent;
	struct A_ArbWind_t	*arbparent;
}	A_AniWind_t;

typedef struct FileData_t {
	time_t	lastmod;	/* Last modified time of directory. */
	char	dir[MAXPATHLEN+1];	/* Dir name. */
	char	file[MAXNAMELEN+1];	/* Selected file name.	*/
	} FileData_t;

typedef	struct A_FileWind_t {
	Widget	shell,win;
	Widget	fileVPort, fileWin;
	Widget	dirDialog,fileDialog,scaleDialog;
	Widget	sdsDialog,rasStartDialog,rasEndDialog;
	Widget	saveButton;
	Widget	sdsBox,savBox,palBox,palSBox,rasBox;
	Widget	palSaveBox, palSplitSaveBox;
	Widget	saveSepToggle;
	Widget	callShell;
	A_FileAction_t	mode;
	A_FileFormat_t	format;
	short	clicks;
	char	**fileData;
	Boolean	paletteIO;	/* Set if doing palette IO instead of data.*/
	Boolean	separateFiles;
	Boolean globalPalette;
	Boolean loadAllSDS;
	Boolean usePixmap;
	Boolean useDisk;
	struct A_AniWind_t	*aniWin;
	struct A_ArbWind_t	*arbWin;
	struct A_CubeWind_t	*cubeWin;
	struct A_DiceWind_t	*diceWin;
	struct A_DsplWind_t	*dsplWin;
	struct A_IsoWind_t	*isoWin;
	struct A_SubsWind_t	*subsWin;
	struct A_TileWind_t	*tileWin;
	struct A_ViewWind_t	*viewWin;
	struct A_TopWind_t	*parent;
	A_Directory_t	currentdir;	/* Index of current directory. */
	FileData_t	dirs[MAXFILEWINDIRS];
}	A_FileWind_t;

typedef struct A_TileWind_t{
	Widget	shell,win;
	Widget	imageVPort[MAX_TILLEV_TILES],imageWin[MAX_TILLEV_TILES];
	XImage	*image[MAX_TILLEV_TILES];
	int	imagexsize[MAX_TILLEV_TILES],imageysize[MAX_TILLEV_TILES];
	char	*data[MAX_TILLEV_TILES];
	int		numTiles,scale;
	int		oldX, oldY;
	int		oldInd;
	Pixel	oldPix[MAX_TILLEV_TILES];
	A_Axes_t axesOrient;
	A_Tile_t tileType;
	struct	A_TileWind_t	*next,*prev;
	struct	A_CubeWind_t	*parent;
}	A_TileWind_t;

typedef struct A_MosWind_t{
	Widget	shell,win;
	Widget	imageVPort,imageWin;
	XImage	**image;
	char	**data;
	int	txsize,tysize,width,height;
	int	numTiles,nx,ny;
	A_Axes_t axesOrient;
	struct	A_MosWind_t	*next,*prev;
	struct	A_CubeWind_t	*parent;
}	A_MosWind_t;

typedef	struct A_DsplWind_t{
	Widget	shell,win;
	Widget	listVPort,listWin;
	Widget	hScaleVPort,hScaleWin;
	Widget	vScaleVPort,vScaleWin;
	Widget	imageVPort,imageWin;
	Widget	xDialog,yDialog,zDialog, dDialog;
	Boolean synchronize,cull;
	int	width,scale;
	int	xdim,ydim,zdim;
	int	selX,selY;	/* Selected position in DATA coordinates. */
	Boolean  traceon;	/* jng oct24 - if 1 => trace slice on image */
	int 	nselected;  /* jng oct24 - # of selected pts so far */
	/* jng may24 - to store selected pts */
	int	selectX[MAX_TRACE_SELPTS], selectY[MAX_TRACE_SELPTS];
	int 	*traceX,*traceY; /* jng may24 - interpolated selected pts */
	int	ntraced;	/* jng oct24 - # of traced pts */
	int	oldX, oldY;	/* Old mouse position. */
	int	oldInd;
	int	imagexsize,imageysize;
	Pixel	oldPix;
	XImage	*image;
	char	*data;		/* Pixel data */
	float32 *fdata;  /* actual float data of the displayed plane. jng  */
	char	**listData,**vScaleData,**hScaleData;
	int	numHistWins;
	A_Axes_t axesOrient;
	struct	A_HistWind_t	*contourWin; /* only one per dsplwin allowed */
	struct	A_HistWind_t	*histWin;
	struct	A_DsplWind_t	*next,*prev;
	struct	A_CubeWind_t	*parent;
}	A_DsplWind_t;

typedef	struct A_SubsWind_t{
	Widget	shell,win;
	Widget	IDLabel, IDSlider;
	Widget	runButton;
	Widget	lowerDialog, upperDialog,opacityDialog;
	Widget	maxDialog,gammaDialog,ambDialog,attDialog;
	Widget	nearDialog,farDialog,incrDialog;
	Widget	redDialog,greenDialog,blueDialog;
	Widget	imageVPort,imageWin;
	XImage	*image;
	char	*data,*data24,*palData;
	Boolean	curCursor;
	int		runMode;	/* 0=reset, 1=running, 2=paused */
	int		xsize,ysize;
	int		numSubs;
	int		curSubsID;
	int		xpts,ypts,zpts;
	int		nearP,farP,incrP,curP;
	int		numdone,totalpoints;
	double	gamma,amb,att;
	double	outMax,incr;
	double	percentdone;
	double	depthcue,depthcueSquared;
	A_Axes_t axesOrient;
	A_Data_t *hdf;
	A_SubsType_t	*subs;
	A_VRect_t	**vbuff;
	struct	A_SubsWind_t	*next,*prev;
	struct	A_CubeWind_t	*parent;
}	A_SubsWind_t;

typedef	struct A_ViewWind_t{
	Widget	shell,win;
	Widget	imageVPort,imageWin;
	XImage	*image;
	char	*data;
	char	*palette;
	struct	A_ViewWind_t	*next,*prev;
	struct	A_ArbWind_t	*parent;
}	A_ViewWind_t;

/* the HistWind is used as the Profile, Trace, Contour and Gaussian window */

typedef	struct A_HistWind_t{
	Widget	shell,win;
	Widget	imageVPort,imageWin;
	XImage	*image;
	char	*data; 
	int	xsize,ysize,xpos,ypos;

	/* used by contour only */
	Widget conDialog;

	/* used by Trace window only */
	int 	*traceX, *traceY; /* jng may24 - interpolated selected pts */
	int	ntraced;	/* jng oct24 - # of traced pts */

	/* used by Gaussian window only */
	Widget   xDialog, yDialog, tDialog, fDialog; /* for gaussian */
	float32* gdata; /* float data plane after gaussian convolution  */
	struct	A_HistWind_t	*next,*prev;
	struct	A_DsplWind_t	*parent;
}	A_HistWind_t;

typedef	struct A_DiceWind_t{
	Widget	shell,win;
	Widget	imageVPort,imageWin;
	Widget	shadeSlider;
	Widget	xSlider,ySlider,zSlider;
	Widget	xToggle, yToggle, zToggle;
	Widget	splaneDialog,fplaneDialog;
	XImage	*image;
	GC	gc1,gc2,gc3;
	int	scale;
	int	org,xdim,ydim,zdim;
	int	xsize,ysize,dimxsize,dimysize;
	int	xdimS,ydimS, zdimS;
	int	maxoff;
	int	planeType;	/* 1:X, 2:Y, 3:Z */
	int	xsplane,xfplane,ysplane,yfplane,zsplane,zfplane;
	char	**data;
	int	**fb;
	Boolean sliced,first,dicer;
	A_Coord_t	vert[8],slice[8];
	struct	A_DiceWind_t	*next,*prev;
	struct	A_BossWind_t	*parent;
}	A_DiceWind_t;

typedef	struct A_IsoWind_t{
	Widget	shell,win;
	Widget	IDLabel, IDSlider;
	Widget	imageVPort,imageWin;
	Widget	numSubsDialog;
	Widget	isoDialog,numFramesDialog,pFactorDialog,attenDialog;
	Widget	rotXDialog,rotYDialog,rotZDialog;
	Widget	incXDialog,incYDialog,incZDialog;
	Widget	startXDialog,startYDialog,startZDialog;
	Widget	endXDialog,endYDialog,endZDialog;
	Widget	redDialog,greenDialog,blueDialog;
	XImage	*image;
	GC	gc;
	char	*data24,*palData;
	char	*data;
	int	**fb;
	int	scale,numFrames,numSubs,curSubsID,curSubs;
	int	xdim,ydim,zdim;
	int	xsize,ysize;
	int	startX[10],startY[10],startZ[10],endX[10],endY[10],endZ[10];
	float32	subsVal[10];
	double 	redCoeff[10],greenCoeff[10],blueCoeff[10];
	double	xangle,yangle,zangle,incX,incY,incZ,pFactor,atten;
	Boolean	stopIso,doAttenuate,doRotate,doPerspective,doUpdate;
	Boolean	doWireFrame,doTrueColor;
	double	xmid,ymid,zmid,xoff,yoff,zoff;
	double	matrix[5][5];
	struct	A_IsoWind_t	*next,*prev;
	struct	A_BossWind_t	*parent;
}	A_IsoWind_t;

typedef	struct A_ArbWind_t{
	Widget	shell,win;
	Widget	drawCubeWin;
	Widget	drawDepthWin;
	Widget	xSlider,ySlider,zSlider;
	Widget	scaleDialog;
	Widget	zpercentDialog;
	Widget	numFramesDialog;
	Boolean interp,usePixmap,useDisk;
	pixelMapping	mapping;	/* Pixel mapping info for children.*/
	struct	A_Box_t	*xybox;
	struct	A_AniWind_t		*aniWin;
	struct	A_ViewWind_t	*viewWin;
	struct	A_ArbWind_t		*next,*prev;
	struct	A_BossWind_t	*parent;
	short	numViewWins;
	short	numAniWins;
}	A_ArbWind_t;

typedef	struct A_CubeWind_t{
	Widget	shell,win;
	Widget	drawWin;
	Widget	box2D,box3D;
	Widget	planeDialog;
	Widget	incrDialog;
	Widget	scaleDialog;
	Widget	widthDialog;
	Widget	numPlanesDialog;
	Widget	xptDialog,yptDialog,zptDialog,numSubsDialog;
	Widget	usePixToggle,gridOnToggle;
	Boolean cull,interp,view2D,isStep,usePixmap,useDisk,gridOn;
	pixelMapping mapping;	/* Pixel mapping info for children.	*/
	A_DisplayTimes_t	displaySS;
	A_AniWind_t		*aniWin;
	A_DsplWind_t		*dsplWin;
	A_MosWind_t		*mosWin;
	A_SubsWind_t		*subsWin;
	A_TileWind_t		*tileWin;
	A_Axes_t		axesOrient;
	short	numAniWins;
	short	numDsplWins;
	short	numMosWins;
	short	numTileWins;
	short	numSubsWins;
	struct	A_CubeWind_t	*next,*prev;
	struct	A_BossWind_t	*parent;
}	A_CubeWind_t;

typedef	struct A_BossWind_t{
	char	filename[MAXNAMELEN];
	Widget	shell,win;
	Widget	msgVPort,msgWin;
	Widget	minDialog,maxDialog,diceScaleDialog;
	A_DisplayMode_t	dsplMode;
	A_CubeWind_t	*cubeWin;
	A_ArbWind_t		*arbWin;
	A_DiceWind_t	*diceWin;
	A_IsoWind_t		*isoWin;
	A_Data_t		*data;
	char			*fileAttrib;
	short	numCubeWins;
	short	numArbWins;
	short	numDiceWins;
	short	numIsoWins;
	struct	A_BossWind_t	*next,*prev;
	struct	A_TopWind_t		*parent;
}	A_BossWind_t;

typedef	struct A_TopWind_t {
	Widget	shell,win;
	Widget	msgVPort, msgWin;
	short	numAniWins;
	short	numBossWins;
	short	numFileWins;
	struct	A_BossWind_t	*bossWin;
	struct	A_FileWind_t	*fileWin;
	struct	A_AniWind_t	*aniWin;
}	A_TopWind_t;

	/******* Added for XImage/palette support. *******/

/* The XImage palette window replaces the old MXV palette window and
is called from several places. The routines used to read palettes must
be passed to PaletteBox. (PaletteBox has been inserted between the I/O
routine and the MXV calling routine. This structure allows PaletteBox
to pass the original data on.

A pointer to a color struct is passed to PaletteBox so it can get access to
the current palette... Either the default or split palette.

*/
typedef struct A_Palette_t {
	A_Color_t	*cs;		/* Pointer to color struct to use.  */
/*	A_Colormap_t	index;		/* Which colormap info to use.	    */
	int		index;
	caddr_t	client_data;		/* Data for PaletteBox.		    */
	void	(*Load_Palette)();	/* Callback routine to load palette.*/
	void	(*Save_Palette)();	/* Callback routine to save palette.*/
}	A_Palette_t;


extern pixelMapping *xi_getPixelMapping();
extern unsigned char *xi_mapPixels(), xi_mapPixel();
extern Boolean xi_unmapPixel();

#endif	/*#ifndef	_GR_DEF_H*/
