c
c  box in absolute pixels. (is,ib) (ie,it) can be reset by cursor.
	integer      is,ie,ib,it,midx,midy
	common /box/ is,ie,ib,it,midx,midy
c---------------------------------------------------------------------c
	integer lIn,blc(3),trc(3)
	common/file/lIn,blc,trc
	character filename*50
	common/filename/filename

	real crval1,crval2,epoch,xy,vel,delv,posx,posy,pospa
	real bmaj,bmin,bpa,dperjy,cbof,restfreq,posend,velend
	real amin,amax,arms
	integer		     niters
	common/head/crval1,crval2,epoch,xy,vel,delv,posx,posy,pospa,
     *	     bmaj,bmin,bpa,dperjy,cbof,restfreq,posend,velend,
     *	     amin,amax,arms,niters
c
c  crval1, crval2, (epoch), bmaj, bmin (beam) [radians]
c  xy (map pixel),  [arcsecs]
c  vel,delv - lsr velocity and width of current map [km/s]
c  restfreq, [GHz]
c  posx, posy [arcsec] pospa [deg] (position wrt center and pa of l-v plot) 
c  posend - Length in arcsecs of cut in l-v plot
c  velend - Last velocity in l-v plot.  (First is in vel)
c  amin,amax,arms - min,max,rms for current plot.
c  niters - clean iterations.
c  itype = 1 for PosVel, 2 for Implot
c---------------------------------------------------------------------c

	character      object*20,bunit*9,ctype(3)*9
	common/image_data/object,bunit,ctype
	
	character*1    units,cneg,abscoord,apint,percent,
     *                  pspec,defimage,lgaufit,lgauplot
	common/plotpar/units,cneg,abscoord,apint,percent,
     *     pspec,defimage,lgaufit,lgauplot

c	integer	nlevels
c	real    levels(50)
c	common/con_args/nlevels,levels
c
c  file		filename of image.
c  object	source name from image.
c  bunit	units from image.
c  ctype	types of coordinate axes. (same as FITS keywords).
c  units	units for displayed values.	[J or K]
c  cneg 	Negative contours 		[Y or N]
c  alabel 	Plot header 			[Y or N]
c  write	Write out map to a file		[Y or N]
c  abscoord	Absolute coordinate labels.	[Y or N]
c  apint	Integer Plot			[Y or N]
c  percent	Percentage contour levels	[Y or N]
c  lgaufit      Gaussian fit to spectra         [Y or N]
c  maptype	maptype			[X-Y, POS-VEL or SPECTRA]
c  src		Plot device (0=screen 1=lp 2=vers 3=imagen)
c  levels	Contour levels
c  nlevels	Number of levels
c  conlabel	Label interval for contours
c---------------------------------------------------------------------c
