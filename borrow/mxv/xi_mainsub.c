/* mainsub.c
Needed vars, routines from old main file.

I suspect a lot of this could be removed fairly easily. Something to do
when there is time.
*/

#include <X11/Intrinsic.h>
#include "gr_xwi.h"
#include "ximage.h"
#include "gr_com.h"

Widget toplevel;	/* The top dude of everything ...really everything..*/
Widget toplevelform;	/* The top composite widget, parent of all the shells*/

Boolean defStaticVisual;
extern	Widget toplevel;
extern	void ClosePaletteBox();

Widget	b[BUTTON_TABLE_SIZE];		/* Buttons */

initximage(wid)
Widget wid;
{
Arg		arglist[10];
Cardinal	i=0;
char		buff[128];
char		buff2[256];
Display		*dpy;
int		screen;
Visual		*myVis;


	dpy    = XtDisplay(wid);
	screen = DefaultScreen(dpy);
	/* I'm guessing here. */
	toplevel = gr_topLevel;
	toplevelform = gr_topWin.shell;
	/*****************************/
	{
	Visual *vis;
	vis = DefaultVisual(dpy,screen);
	if (vis->class == StaticColor)
		defStaticVisual=TRUE;
	else
		defStaticVisual=FALSE;
	}

	if (! InitPalette(wid))
		exit(0);

	/* Print the Display Info*/

  if (8 == DisplayPlanes(dpy,screen)) /* perfectionism at it's wosrt*/
    sprintf(buff,"Display is an %d plane %%s with %d entries in Colormap\n",
			DisplayPlanes(dpy,screen),XDisplayCells(dpy,screen));
  else
    sprintf(buff,"Display is a %d plane %%s with %d entries in Colormap\n",
			DisplayPlanes(dpy,screen),XDisplayCells(dpy,screen));

	myVis = gr_GetVisual(dpy, DefaultScreen(dpy));
	switch (myVis->class) {
		case StaticGray:
			sprintf(buff2,buff,"StaticGray");
			break;
		case GrayScale:
			sprintf(buff2,buff,"GrayScale");
			break;
		case StaticColor:
			sprintf(buff2,buff,"StaticColor");
			break;
		case PseudoColor:
			sprintf(buff2,buff,"PseudoColor");
			break;
		case TrueColor:
			sprintf(buff2,buff,"TrueColor");
			break;
		case DirectColor:
			sprintf(buff2,buff,"DirectColor");
			break;
		}
	gr_TextMsgOut(buff2);
} /* Initialize() */
