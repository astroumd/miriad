/* gr_misc.c
Misc routines.
*/

#include "X11/Xlib.h"
#include <errno.h>
extern	int	sys_nerr;
extern	char	*sys_errlist[];

/* Draw a text string in different directions.
Path
 0	L R
 1	B T
 2	R L
 3	T B

X,Y give the lower left corner of the FIRST char in the string. X,Y are
fudged to take into account the way X draws characters. For the case of
R-L, X,Y will have most of the first character to the right and the rest
to the left.
*/

int iix_text(dpy, pixmap, gc, font, x0, y0, path, str)
Display *dpy;
Pixmap	pixmap;
GC	gc;
XFontStruct *font;
int	x0,y0;
int	path;
char	*str;
{
XCharStruct cs;
int	dir, ascent, descent;
char	*chr;
int	x,y;
int	offset;

	switch(path) {
	case 0:		/* Left to Right	*/
		XTextExtents(font, str, strlen(str), &dir, &ascent,
							&descent, &cs);
		/* From lower left of char to 'origin'	*/
		x = x0 - cs.lbearing;
		y = y0 - descent;
		XDrawString(dpy, pixmap,gc, x, y, str, strlen(str));
		break;
	case 1:		/* Bottom to Top.	*/
		/* Fudged. Space between chars is assumed constant. */

		chr = str;
		x = x0; y = y0;
		XTextExtents(font, chr, strlen(chr), &dir, &ascent,
							&descent, &cs);
		offset = ascent + descent;
		while( *chr != '\0')
		{
			XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
			y -= offset;
		}
		break;
	case 2:		/*Right to left. */
		chr = str;
		x = x0;
		XTextExtents(font, chr, strlen(chr), &dir, &ascent, &descent,
								&cs);
		y0 = y0 - descent;
		y = y0 - descent;
		while( *chr != '\0')
		{	
			XTextExtents(font, chr, 1, &dir, &ascent, &descent,
									&cs);
			y = y0 - descent;
			x -= cs.rbearing;
			XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
			x += cs.lbearing;
		}
		break;

	case 3:		/* Top to Bottom.	*/
		chr = str;
		y = y0;
		x = x0;
		XTextExtents(font, chr, strlen(chr), &dir, &ascent,
							&descent, &cs);
		offset = ascent + descent;
		XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
		y += cs.descent + offset;
		while( *chr != '\0')
		{
			XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
			y += offset;
		}
#ifdef FUPI
		y -= cs.descent;
		x = x0 - cs.lbearing;
		XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
		y += cs.descent;
		while( *chr != '\0')
		{ int	offset = 0;

			XTextExtents(font, chr, 1, &dir, &ascent, &descent,
									&cs);
			/* Y is at bottom of previous char's rectangle. Move
			   to this char's origin.
			*/
			y += cs.ascent;
			x = x0 - cs.lbearing;
			XDrawString(dpy, pixmap,gc, x, y, chr++, 1);
			/* Bottom of char's rectangle. */
			y += cs.descent;
		}
#endif
		break;
	default:
		return(1);
	}
	return(0);

}


/* Return a pointer to a system error mesg. */
char *gr_serror()
{
	if((errno >= 0) && ( errno < sys_nerr))
		return sys_errlist[errno];
	else
		return "Unknown Error";
}

/* Display system error message in log window.

str is a format string to be used in building the error message.
arg is an argument for str.

The message is built then the system error message is appended to the end
and displayed in the logging window.

Return is the current value of errno.
*/
int gr_perror(str, arg)
char	*str, *arg;
{
char	buf[256];

	if(str == NULL)
		sprintf(buf, "%s\n", gr_serror());
	else
	{	sprintf(buf, str, arg);
		strcat(buf, gr_serror());
		strcat(buf, "\n");
	}
	gr_TextMsgOut(buf);
	return errno;
}
