/*
 *	File:		gr_pal.c
 *	Contents:	routines for color pallet manipulation
 */

#include "gr_com.h"
#include <string.h>
#if defined (sun) && defined (SYSV)
#include <sys/fcntl.h>
#endif

extern	int	td_HdfPalLoad();

/* rccells should probably replace gr_origCells completely at some time. */
/*
extern  XColor  rccells[];
void    copy_colors();
*/
XColor	gr_origCells[256];

/* ------------------------------------------------------------------ */

/*
 *	Initialize palette data
 */
void
gr_PalInit(wid)
Widget	wid;
{
Display	*dpy = XtDisplay(wid);
int 	scr = DefaultScreen(dpy);
Visual  *vis = gr_GetVisual(dpy,scr);
int	bprgb = vis->bits_per_rgb;
int	depth = DisplayPlanes(dpy,scr);
int	x,y,i=0;
char	msg[128];

	if (bprgb == 0)
		bprgb = 8;

	gr_color.white = WhitePixel(dpy,scr);
	gr_color.black = BlackPixel(dpy,scr);
	gr_color.depth = depth;
	gr_color.shiftbits = 8;

	gr_colorSplit.white = WhitePixel(dpy,scr);
	gr_colorSplit.black = BlackPixel(dpy,scr);
	gr_colorSplit.depth = depth;
	gr_colorSplit.shiftbits = 8;

	gr_TextMsgOut("X Server characteristics:\n");
	if ( (DefaultVisual(dpy,scr)->class == PseudoColor) ||
		 (DefaultVisual(dpy,scr)->class == DirectColor) )
	{
		gr_color.defCanSet = gr_colorSplit.defCanSet = TRUE;
		sprintf(msg,"Default Visual is PseudoColor, White %d, Black %d.\n",
			gr_color.white,gr_color.black);
		gr_TextMsgOut(msg);
	}
	else
	{
		gr_color.defCanSet = gr_colorSplit.defCanSet = FALSE;
		sprintf(msg,"Default Visual is non PseudoColor, White %d, Black %d.\n",
			gr_color.white,gr_color.black);
		gr_TextMsgOut(msg);
	}

/*	sprintf(msg,"# color planes: %d, ",depth);
	gr_TextMsgOut(msg);
*/
	if (depth == 1)
	{
		/* 1 plane monochrome */
		gr_TextMsgOut("\nWarning: MXV will not display color on a \n");
		gr_TextMsgOut("single plane monochrome device.\n");
		gr_color.nColors = 2;
		gr_color.maxColors = 2;
		gr_color.canSet = FALSE;
		gr_colorSplit.nColors = 2;
		gr_colorSplit.maxColors = 2;
		gr_colorSplit.canSet = FALSE;
	}
	else
	{
		switch (vis->class)
		{
			case PseudoColor:
			gr_TextMsgOut("Pseudo Color device, ");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = TRUE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = TRUE;
			break;

			case StaticColor:
			gr_TextMsgOut("\nWarning\t: MXV cannot change the color\n");
			gr_TextMsgOut("map on a StaticColor device.\n");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = FALSE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = FALSE;
			break;

			case DirectColor:
			gr_TextMsgOut("Direct Color device, ");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = TRUE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = TRUE;
			break;

			case TrueColor:
			gr_TextMsgOut("\nWarning\t: MXV cannot change the color\n");
			gr_TextMsgOut("map on a TrueColor device.\n");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = FALSE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = FALSE;
			break;

			case GrayScale:
			gr_TextMsgOut("\nWarning\t: MXV cannot change the color\n");
			gr_TextMsgOut("map on a GrayScale device.\n");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = FALSE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = FALSE;
			break;

			case StaticGray:
			gr_TextMsgOut("\nWarning\t: MXV cannot change the color\n");
			gr_TextMsgOut("map on a StaticGray device.\n");
			gr_color.nColors = vis->map_entries-2*RESERVED_COLORS;
			gr_color.maxColors = vis->map_entries;
			gr_color.canSet = FALSE;
			gr_colorSplit.nColors = (vis->map_entries/3)-2*RESERVED_COLORS;
			gr_colorSplit.maxColors = vis->map_entries;
			gr_colorSplit.canSet = FALSE;
			break;
		}

	}

	if (gr_color.maxColors > 256)
	{
		gr_color.maxColors = 256;
		gr_color.nColors = 256-2*RESERVED_COLORS;
	}
	if (gr_colorSplit.maxColors > 256)
	{
		gr_colorSplit.maxColors = 256;
		gr_colorSplit.nColors = (256/3)-2*RESERVED_COLORS;
	}


/*      Initialize XImage palette stuff. */
        initximage(wid);

#if 0
	sprintf(msg,"# colors used = %d\n",gr_color.nColors);

	gr_TextMsgOut(msg);
#endif
}


/*
 *	Set palette data using HDF palette data format
 */
void
gr_ImageInitCMapHDF(palette)
unsigned char *palette;
{
	int	x,tmp,tmp1,tmp2;

	for (x = 0; x<gr_color.maxColors; x++)
	{
		tmp=x*3; tmp1 = tmp+1; tmp2 = tmp+2;
		gr_color.cmapCells[x].pixel = x;
		gr_color.cmapCells[x].red=
			(unsigned short)palette[tmp] << gr_color.shiftbits ;
		gr_color.cmapCells[x].green=
			(unsigned short) palette[tmp1] << gr_color.shiftbits ;
		gr_color.cmapCells[x].blue=
			(unsigned short) palette[tmp2] << gr_color.shiftbits;
		gr_color.cmapCells[x].flags=DoRed|DoGreen|DoBlue;

		gr_color.palette[tmp] = palette[tmp];
		gr_color.palette[tmp1] = palette[tmp1];
		gr_color.palette[tmp2] = palette[tmp2];
	}

	gr_color.cmapCells[gr_color.black].red		= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].green	= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].blue		= (unsigned short) 0;

	gr_color.cmapCells[gr_color.white].red		= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].green	= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].blue		= (unsigned short) 65535;
}


/*
 *	Set palette data using PLANAR palette data format
 */
void
gr_ImageInitCMapPLA(palette)
unsigned char *palette;
{
	int	x,tmp;

	for (x = 0; x<gr_color.maxColors; x++)
	{
		tmp=x*3;
		gr_color.cmapCells[x].pixel = x;
		gr_color.cmapCells[x].red=
			(unsigned short)palette[x] << gr_color.shiftbits ;
		gr_color.cmapCells[x].green=
		(unsigned short)palette[x+gr_color.maxColors] << gr_color.shiftbits ;
		gr_color.cmapCells[x].blue=
		(unsigned short)palette[x+2*gr_color.maxColors] << gr_color.shiftbits;
		gr_color.cmapCells[x].flags=DoRed|DoGreen|DoBlue;

		gr_color.palette[tmp] = palette[x];
		gr_color.palette[tmp+1] = palette[x+gr_color.maxColors];
		gr_color.palette[tmp+2] = palette[x+2*gr_color.maxColors];
	}

	gr_color.cmapCells[gr_color.black].red		= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].green	= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].blue		= (unsigned short) 0;

	gr_color.cmapCells[gr_color.white].red		= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].green	= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].blue		= (unsigned short) 65535;
}


/*
 *	Set palette data using SEQ palette data format
	Called mostly internally.
 */
static void gr_ImageInitCMapRGB(r,g,b)
unsigned char r[],g[],b[];
{
	int	x;
	unsigned char	*p;

	p = gr_color.palette;
	for (x = 0; x<gr_color.maxColors; x++)
	{
		gr_color.cmapCells[x].pixel = x;
		gr_color.cmapCells[x].red = r[x] << gr_color.shiftbits ;
		gr_color.cmapCells[x].green = g[x] << gr_color.shiftbits ;
		gr_color.cmapCells[x].blue = b[x] << gr_color.shiftbits ;
		gr_color.cmapCells[x].flags = DoRed|DoGreen|DoBlue;
		*p++ = r[x];
		*p++ = g[x];
		*p++ = b[x];
	}

	gr_color.cmapCells[gr_color.black].red		= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].green	= (unsigned short) 0;
	gr_color.cmapCells[gr_color.black].blue		= (unsigned short) 0;

	gr_color.cmapCells[gr_color.white].red		= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].green	= (unsigned short) 65535;
	gr_color.cmapCells[gr_color.white].blue		= (unsigned short) 65535;
}


/*
 *	Split a palette into 3 parts
 */
static void gr_PaletteSplit()
{
	int	x,i,s1,s2;
	unsigned char *p=gr_colorSplit.palette;

	/* Pull every third color off full palette */
	i=0;
	for (x = 0; x<gr_colorSplit.maxColors; x+=3)
	{
		gr_origCells[i]=gr_color.cmapCells[x];
		gr_origCells[i].pixel = i;
		i++;
	}

	gr_origCells[gr_colorSplit.black].red   = (unsigned short)0;
	gr_origCells[gr_colorSplit.black].green = (unsigned short)0;
	gr_origCells[gr_colorSplit.black].blue  = (unsigned short)0;

	gr_origCells[gr_colorSplit.white].red   = (unsigned short)65535;
	gr_origCells[gr_colorSplit.white].green = (unsigned short)65535;
	gr_origCells[gr_colorSplit.white].blue  = (unsigned short)65535;

	s1 = gr_colorSplit.nColors+(2*RESERVED_COLORS);
	s2 = 2*(gr_colorSplit.nColors+(2*RESERVED_COLORS));
	for (x = 0; x < s1; x++)
	{
		gr_colorSplit.cmapCells[x]=gr_origCells[x];
		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
	}

	i = 0;
	for (x = s1; x < s2; x++)
	{
		gr_colorSplit.cmapCells[x] = gr_origCells[i];
		gr_colorSplit.cmapCells[x].pixel = x;
		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
		i++;
	}

	i = 0;
	for (x = s2; x < gr_colorSplit.maxColors; x++)
	{
		gr_colorSplit.cmapCells[x] = gr_origCells[i];
		gr_colorSplit.cmapCells[x].pixel = x;
		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
		i++;
	}

	gr_colorSplit.cmapCells[gr_colorSplit.black].red   =(unsigned short)0;
	gr_colorSplit.cmapCells[gr_colorSplit.black].green =(unsigned short)0;
	gr_colorSplit.cmapCells[gr_colorSplit.black].blue  =(unsigned short)0;

	gr_colorSplit.cmapCells[gr_colorSplit.white].red   =(unsigned short)65535;
	gr_colorSplit.cmapCells[gr_colorSplit.white].green =(unsigned short)65535;
	gr_colorSplit.cmapCells[gr_colorSplit.white].blue  =(unsigned short)65535;
}


/*
 *	Shade a palette to change contrast
 */
void
gr_PaletteShade(val)
int val;
{
	int	x,i,s1,s2;
	unsigned char *p;
/*	register int valshift;*/
	register unsigned short valshift;

	s1 = gr_colorSplit.nColors+(2*RESERVED_COLORS);
	s2 = 2*(gr_colorSplit.nColors+(2*RESERVED_COLORS));
	i=RESERVED_COLORS;
	p = gr_colorSplit.palette;
	for (x = RESERVED_COLORS; x< s1; x++)
	{
		valshift = val;
		if (gr_origCells[i].red < (unsigned short) (65535-valshift))
			gr_colorSplit.cmapCells[x].red = 
				gr_origCells[i].red + valshift;
		else
			gr_colorSplit.cmapCells[x].red = 65535;

		if (gr_origCells[i].green < (unsigned short) (65535-valshift))
			gr_colorSplit.cmapCells[x].green = 
				gr_origCells[i].green + valshift;
		else
			gr_colorSplit.cmapCells[x].red = 65535;

		if (gr_origCells[i].blue < (unsigned short) (65535-valshift))
			gr_colorSplit.cmapCells[x].blue = 
				gr_origCells[i].blue + valshift;
		else
			gr_colorSplit.cmapCells[x].blue = 65535;

		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
		i++;
	}
	i=RESERVED_COLORS;
	for (x = RESERVED_COLORS+s1; x < s2; x++)
	{
		valshift = val;
		if (gr_origCells[i].red > valshift)
			gr_colorSplit.cmapCells[x].red =
				gr_origCells[i].red - valshift;
		else
			gr_colorSplit.cmapCells[x].green = 0;

		if (gr_origCells[i].green > valshift)
			gr_colorSplit.cmapCells[x].green = 
				gr_origCells[i].green - valshift;
		else
			gr_colorSplit.cmapCells[x].red = 0;

		if (gr_origCells[i].blue > valshift)
			gr_colorSplit.cmapCells[x].blue = 
				gr_origCells[i].blue - valshift;
		else
			gr_colorSplit.cmapCells[x].blue = 0;

		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
		i++;
	}
	i=RESERVED_COLORS;
	for (x = RESERVED_COLORS+s2; x < gr_colorSplit.maxColors; x++)
	{
		valshift = val+val+val;
		if (gr_origCells[i].red > valshift)
			gr_colorSplit.cmapCells[x].red =
				gr_origCells[i].red - valshift;
		else
			gr_colorSplit.cmapCells[x].red = 0;

		if (gr_origCells[i].green > valshift)
			gr_colorSplit.cmapCells[x].green = 
				gr_origCells[i].green - valshift;
		else
			gr_colorSplit.cmapCells[x].red = 0;

		if (gr_origCells[i].blue > valshift)
			gr_colorSplit.cmapCells[x].blue = 
				gr_origCells[i].blue - valshift;
		else
			gr_colorSplit.cmapCells[x].blue = 0;

		*p++ = gr_colorSplit.cmapCells[x].red >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].green >> gr_colorSplit.shiftbits;
		*p++ = gr_colorSplit.cmapCells[x].blue >> gr_colorSplit.shiftbits;
		i++;
	}
	gr_colorSplit.cmapCells[gr_colorSplit.black].red   =(unsigned short)0;
	gr_colorSplit.cmapCells[gr_colorSplit.black].green =(unsigned short)0;
	gr_colorSplit.cmapCells[gr_colorSplit.black].blue  =(unsigned short)0;

	gr_colorSplit.cmapCells[gr_colorSplit.white].red   =(unsigned short)65535;
	gr_colorSplit.cmapCells[gr_colorSplit.white].green =(unsigned short)65535;
	gr_colorSplit.cmapCells[gr_colorSplit.white].blue  =(unsigned short)65535;
}


/*
 *	Set color map of widget to a split palette
 */
void
gr_ImageSetCMapSplit(wid)
Widget wid;
{
	XIMAGE_setcmap(wid, gr_colorSplit.cmapCells, TRUE);
	return;
}


/*
 *	Set color map of widget to a normal palette
 */
void
gr_ImageSetCMap(wid)
Widget wid;
{
	XIMAGE_setcmap(wid, gr_color.cmapCells, FALSE);
	return;
}

static int read_palette(palettename)
char	*palettename;
{
char	errbuff[260];
unsigned char	rbuff[256];
unsigned char	gbuff[256];
unsigned char	bbuff[256];
int	fd;


	if (td_FileIsHdf(palettename))
	{
		if (td_HdfPalLoad(palettename,gr_color.palette) == -1)
		{
			sprintf(errbuff,
				"Cannot open Hdf palette %s. : %s\n",
				palettename, gr_serror());
			gr_TextMsgOut(errbuff); return -1;
		}
		else
		{
			gr_ImageInitCMapHDF(gr_color.palette);
			sprintf(errbuff,
				"Loaded HDF palette %s.\n",palettename);
			gr_TextMsgOut(errbuff);
		}
	}
	else
	{
		if ((fd = open(palettename,O_RDONLY,NULL)) < 0)
		{
			sprintf(errbuff,
				"Cannot open palette %s. : %s\n",
				palettename, gr_serror());
			gr_TextMsgOut(errbuff); return -1;
		}
		if (read(fd,rbuff,256) != 256)
		{
			sprintf(errbuff,"%s is not a seq colormap\n",
				palettename);
    		(void) close(fd); gr_TextMsgOut(errbuff); return -1;
    	}
    	if (read(fd,gbuff,256) != 256)
		{
			sprintf(errbuff,"%s is not a seq colormap\n",
				palettename);
    		(void) close(fd); gr_TextMsgOut(errbuff); return -1;
		}
		if (read(fd,bbuff,256) != 256)
		{
			sprintf(errbuff,"%s is not a seq colormap\n",
				palettename);
    		(void) close(fd); gr_TextMsgOut(errbuff); return -1;
		}
    	(void) close(fd);
		gr_ImageInitCMapRGB(rbuff,gbuff,bbuff);
		sprintf(errbuff,"Loaded SEQ palette %s.\n",palettename);
		gr_TextMsgOut(errbuff);
	}
	return 0;
}


/*
 *	Set color map of widget to default gray-scaled palette
	Only called from gr_main to set initial colormap.
 */
void gr_ImageDefCMap(w)
Widget	w;
{
unsigned char r[256],g[256],b[256];
int	x, err;
char	*name, *pathname, *dir;
A_Directory_t	current;

	/* Temporarily set to palette. */
	current = td_SetDirIndex(NULL, PALETTEDIR);
	dir = td_getDirName();
	name = td_getFileName(PALETTEDIR);
	if(name != NULL)
		pathname = td_getPathName(NULL, dir, name);
	td_SetDirIndex(NULL, current);	/* Reset. */

	if(name != NULL)
		err = read_palette(pathname);
	else
		err = -1;

	/* Use this as default in case there is nothing else. */
	if(err != 0)
	{	for (x=0; x<gr_color.maxColors; x++)
			r[x] = g[x] = b[x] = (unsigned char)x;
		gr_ImageInitCMapRGB(r,g,b);
	}
	gr_PaletteSplit();

/* Copy to ximage's current copy and redraw components.
*/
	xi_storeColors(gr_color.cmapCells, TRUE, 0);
}

/*
 *	Load color map
 */
void
gr_PalletLoad(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_BossWind_t		*bossWin=gr_topWin.bossWin;
	A_FileWind_t		*fileWin=(A_FileWind_t *)client_data;
	A_AniWind_t		*curAni;
	A_TileWind_t		*curTile;
	A_DiceWind_t		*curDice;
	A_HistWind_t		*curHist;
	A_IsoWind_t		*curIso;
	A_DsplWind_t		*curDspl;
	A_SubsWind_t		*curSubs;
	A_ViewWind_t		*curView;
	unsigned char		rbuff[256];
	unsigned char		gbuff[256];
	unsigned char		bbuff[256];
	char			errbuff[260];
	int			fd;
	char			*pfile;

	pfile = td_getPathName(NULL, NULL, NULL);


	if( read_palette(pfile) < 0)
		return;

#if 0
/* Only 1 palette and it is global. */
  if (fileWin->globalPalette == TRUE)
  {

	curAni = gr_topWin.aniWin;
	while (curAni != NULL)
	{
		gr_ImageSetCMap(curAni->shell);
		curAni = curAni->next;
	}

	while (bossWin != NULL)
	{
		if (bossWin->cubeWin != NULL)
		{
			curDspl = bossWin->cubeWin->dsplWin;
			while (curDspl != NULL)
			{
				gr_ImageSetCMap(curDspl->shell);
				curHist = curDspl->histWin;
				while (curHist != NULL)
				{
					gr_ImageSetCMap(curHist->shell);
					curHist = curHist->next;
				}
				curDspl = curDspl->next;
			}

			curTile = bossWin->cubeWin->tileWin;
			while (curTile != NULL)
			{
				gr_ImageSetCMap(curTile->shell);
				curTile = curTile->next;
			}

			curAni = bossWin->cubeWin->aniWin;
			while (curAni != NULL)
			{
				gr_ImageSetCMap(curAni->shell);
				curAni = curAni->next;
			}

			curSubs = bossWin->cubeWin->subsWin;
			while (curSubs != NULL)
			{
				gr_ImageSetCMap(curSubs->shell);
				curSubs = curSubs->next;
			}
		}
		if (bossWin->arbWin != NULL)
		{
			curView = bossWin->arbWin->viewWin;
			while (curView != NULL)
			{
				gr_ImageSetCMap(curView->shell);
				curView = curView->next;
			}

			curAni = bossWin->arbWin->aniWin;
			while (curAni != NULL)
			{
				gr_ImageSetCMap(curAni->shell);
				curAni = curAni->next;
			}
		}

		curIso = bossWin->isoWin;
		while (curIso != NULL)
		{
			gr_ImageSetCMap(curIso->shell);
			curIso = curIso->next;
		}

		gr_PaletteSplit();
		curDice = bossWin->diceWin;
		while (curDice != NULL)
		{
			gr_ImageSetCMapSplit(curDice->shell);
			curDice = curDice->next;
		}

		bossWin = bossWin->next;
	}
  }
  else
	gr_ImageSetCMap(fileWin->callShell);
	gr_CloseFileLevel(w,client_data,call_data);

#endif	/* Change a bunch of cmaps. */

	gr_CloseFileLevel(w,client_data,call_data);
	xi_storeColors(gr_color.cmapCells, TRUE, 0);
}


/*
 * Load and split a color map
 */
void
gr_PalletLoadSplit(w, client_data, call_data)
Widget w;
caddr_t client_data;
caddr_t call_data;
{
	A_FileWind_t		*fileWin=(A_FileWind_t *)client_data;
	char			*strng;
	unsigned char		rbuff[256];
	unsigned char		gbuff[256];
	unsigned char		bbuff[256];
	char			errbuff[260];
	int			fd;
	extern			errno;
	char			*pfile;

	pfile = td_getPathName(NULL, NULL, NULL);

	if( read_palette(pfile) < 0)
		return;

	gr_CloseFileLevel(w,client_data,call_data);
	gr_PaletteSplit();
	xi_storeColors(gr_colorSplit.cmapCells, TRUE, 1);
}
