/*
 *	File:		gr_image.c
 *	Contents:	Image plotting functions for graphics module
 */

#include "gr_com.h"


/*
 *	Create an image from raw data
 */
XImage
*gr_ImageCreate(wid,xdim,ydim,data)
Widget	wid;
int		xdim,ydim;
char	*data;
{
	int 		scr;
	Display 	*dpy;
	Visual	  	*vis;
	XImage    	*image;
	unsigned char	*tdata;
	int		i,j,offbytes,offset,rem;

	dpy = XtDisplay(wid);
	scr = DefaultScreen(dpy);
	vis = gr_GetVisual(dpy,scr);

	offbytes = 1;

	if (gr_color.depth > 8)
	{
		rem = gr_color.depth % 8;
		offbytes = (int)(gr_color.depth/8);
		if (rem != 0) offbytes++;
		offset = offbytes-1;
    	if ((tdata = (unsigned char *)td_Malloc1D(xdim*ydim*offbytes, 1,
        (long)sizeof(unsigned char),"Image raster")) == NULL)
        return(NULL);

		for (i=0;i<xdim*ydim;i++)
		{
			for (j=0;j<offset;j++)
				tdata[i*offbytes+j]=(unsigned char)0;
			tdata[i*offbytes+offset]=(unsigned char)data[i];
		}
	}
	else
		tdata = (unsigned char *) data;

	image = 
		XCreateImage(dpy,vis,gr_color.depth,ZPixmap,0, (char *) tdata,
			(unsigned int)xdim, (unsigned int)ydim,
			8*offbytes,(int)(xdim*offbytes));

	return(image);
}


/*
 *	Create an pixmap from raw data
 */
Pixmap
gr_PixmapCreate(wid,gc,xorg,yorg,xdim,ydim,data)
Widget	wid;
GC		gc;
int		xorg,yorg;
int		xdim,ydim;
char	*data;
{
	XImage		*pic;
	Pixmap		pix;
	Display 	*dpy=XtDisplay(wid);
	Drawable	draw=(Drawable)XtWindow(wid);

    pic = gr_ImageCreate(wid,xdim,ydim,data);

	pix = XCreatePixmap(dpy,draw,xdim,ydim,gr_color.depth);
	
	XPutImage(dpy,(Drawable)pix,gc,pic,0,0,xorg,yorg,xdim,ydim);

	return(pix);
}


r24r8 (xres, yres, dat24, dat8, cres, cdat)
int      xres;	/* x dimension - horizontal size */
int      yres;	/* y dimension - vertical size */
unsigned char   *dat24;	/* pointer to 24 bit image in "pixel" format */
unsigned char   *dat8;	/* pointer to 8 bit image */
int      cres;	/* number of colors in the palette - use 256 */
unsigned char *cdat;	/* pointer to palette - should be 3 * 256 bytes long */
{
    int      ct,xct,yct;
    int      rres,rd,rr,rn,rct;
    int      gres,gd,gr,gn,gct;
    int      bres,bd,br,bn,bct;
    int      coff;
    unsigned int    *idat[2];
    unsigned int    *cp,*np;
    unsigned char   *dip,*dop,*rp,*gp,*bp;

    if ((idat[0] = (unsigned int *)malloc(6*xres*sizeof(unsigned int))) == NULL)
    {   fprintf(stderr,"error: Memory allocation fault\n");
	return -1;
    }
    idat[1] = idat[0] + (3 * xres);

    rres = 6;
    gres = 7;
    bres = 6;
    coff = 2;

    rr = gr = br = 255;
    rn = rres - 1;
    gn = gres - 1;
    bn = bres - 1;

    rp = cdat + coff;
    gp = rp + cres;
    bp = gp + cres;

    for (rct=0; rct<rres; rct++)
    {   for (gct=0; gct<gres; gct++)
	{   for (bct=0; bct<bres; bct++)
	    {   *rp++ = (unsigned char)(rr * rct / rn);
		*gp++ = (unsigned char)(gr * gct / gn);
		*bp++ = (unsigned char)(br * bct / bn);
	    }
	}
    }

    rp = cdat;
    gp = rp + cres;
    bp = gp + cres;
    cp = idat[0];
    np = idat[1];
    dip = dat24;
    dop = dat8;

    for (xct=3*xres; --xct>=0; )
	*cp++ = *dip++;

    for (yct=0; yct<(yres-1); yct++)
    {
	np = idat[(yct+1)%2];
	for (xct=3*xres; --xct>=0; )
	    *np++ = *dip++;

	cp = idat[yct%2];
	np = idat[(yct+1)%2];

	if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
	if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
	if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

	*dop++ = ct = (rct * gres + gct) * bres + bct + coff;

	rd = cp[0] - rp[ct];
	gd = cp[1] - gp[ct];
	bd = cp[2] - bp[ct];

	cp += 3;
	np += 3;

	cp[0]  += rd * 7 / 16;
	cp[1]  += gd * 7 / 16;
	cp[2]  += bd * 7 / 16;
	np[-3] += rd * 5 / 16;
	np[-2] += gd * 5 / 16;
	np[-1] += bd * 5 / 16;
	np[0]  += rd / 16;
	np[1]  += gd / 16;
	np[2]  += bd / 16;

	for (xct=2; xct<xres; xct++)
	{
	    if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
	    if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
	    if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

	    *dop++ = ct = (rct * gres + gct) * bres + bct + coff;

	    rd = cp[0] - rp[ct];
	    gd = cp[1] - gp[ct];
	    bd = cp[2] - bp[ct];

	    cp += 3;
	    np += 3;

	    cp[0]  += rd * 7 / 16;
	    cp[1]  += gd * 7 / 16;
	    cp[2]  += bd * 7 / 16;
	    np[-6] += rd * 3 / 16;
	    np[-5] += gd * 3 / 16;
	    np[-4] += bd * 3 / 16;
	    np[-3] += rd * 5 / 16;
	    np[-2] += gd * 5 / 16;
	    np[-1] += bd * 5 / 16;
	    np[0]  += rd / 16;
	    np[1]  += gd / 16;
	    np[2]  += bd / 16;

	}

	if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
	if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
	if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

	*dop++ = ct = (rct * gres + gct) * bres + bct + coff;

	rd = cp[0] - rp[ct];
	gd = cp[1] - gp[ct];
	bd = cp[2] - bp[ct];

	cp += 3;
	np += 3;

	np[-6] += rd * 3 / 16;
	np[-5] += gd * 3 / 16;
	np[-4] += bd * 3 / 16;
	np[-3] += rd * 5 / 16;
	np[-2] += gd * 5 / 16;
	np[-1] += bd * 5 / 16;
    }

    cp = idat[yct%2];

    if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
    if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
    if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

    *dop++ = ct = (rct * gres + gct) * bres + bct + coff;

    rd = cp[0] - rp[ct];
    gd = cp[1] - gp[ct];
    bd = cp[2] - bp[ct];

    cp += 3;

    cp[0]  += rd * 7 / 16;
    cp[1]  += gd * 7 / 16;
    cp[2]  += bd * 7 / 16;

    for (xct=2; xct<xres; xct++)
    {
	if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
	if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
	if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

	*dop++ = ct = (rct * gres + gct) * bres + bct + coff;

	rd = cp[0] - rp[ct];
	gd = cp[1] - gp[ct];
	bd = cp[2] - bp[ct];

	cp += 3;

	cp[0]  += rd * 7 / 16;
	cp[1]  += gd * 7 / 16;
	cp[2]  += bd * 7 / 16;
    }

    if ((rct = (cp[0] * rn / rr)) > rn) rct = rn;
    if ((gct = (cp[1] * gn / gr)) > gn) gct = gn;
    if ((bct = (cp[2] * bn / br)) > bn) bct = bn;

    *dop++ = (rct * gres + gct) * bres + bct + coff;

    free(idat[0]);

    return 0;
}
