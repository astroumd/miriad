/*
 *	File:		gr_mos.c
 *	Contents:	routines for mosaic window
 */

#include "gr_com.h"

void
gr_MosExpose(w, client_data, call_data)
Widget	w;
caddr_t	client_data;
caddr_t	call_data;
{
	A_MosWind_t	*mosWin=(A_MosWind_t *)client_data;
	int			atX=0,atY=0,i,k=0;
    Display     *dpy = XtDisplay(mosWin->imageWin);
    Window      win = XtWindow(mosWin->imageWin);
    int         scr = DefaultScreen(dpy);
    GC          gc;
    XGCValues   gcvals;

    gcvals.foreground = BlackPixel(dpy,scr);
    gcvals.background = WhitePixel(dpy,scr);
    gc = XtGetGC(mosWin->imageWin, GCForeground|GCBackground, &gcvals);
    gr_ImageSetCMap(mosWin->shell);

    for (i=0;i<mosWin->numTiles;i++)
    {
        if (k >= mosWin->nx)
        {
            atX = 0;
            atY = atY+mosWin->tysize+1;
            k = 0;
        }
        XPutImage(dpy,win,gc,mosWin->image[i],0,0,
            atX,atY,mosWin->txsize,mosWin->tysize);
        atX = atX + mosWin->txsize+1;
        k++;
    }
}
