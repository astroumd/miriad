c********1*********2*********3*********4*********5*********6*********7*c
	program pntgen
	implicit none
c= PNTGEN - Generate fake pointing data.
c& mchw
c: pointing analysis
c+
c	PNTGEN generates fake pointing data and calculates the errors
c	which arise from using linear pointing equations.
c	The default is to print out the pointing errors and the
c	difference in arcmin from the linear pointing equations.
c	If an output file is specified then PNTGEN also generates
c	a file containing npts of pointing data at random 
c	azimuth and elevation points within azrange and elrange. 
c@ collim
c	Collimation angle in arcmin between telescope axis and
c	normal to elevation axis. Default=0.
c@ tilt
c	Tilt angle in arcmin of azimuth axis. Default=0.
c@ npts
c	Number of samples of pointing data generated. Default=100.
c@ azrange
c	Azimuth range of pointing data generated. Minimum and
c	maximum values in degrees. Default=-85,85.
c@ elrange
c	Elevation range of pointing data generated. Minimum and
c	maximum values in degrees. Default=5,85.
c@ out
c	Output filename for pointing data.
c-- 
c
c  History:
c    14may92 mchw  Original version.
c    15mar95 pjt   fixed statement orders, call uniform instead of rand()
c    23aug95 mchw  Update pointing format.
c    22mar99 pjt   fixed ,x, -> ,1x, in format stmt (linux)
c----------------------------------------------------------------------c
	character version*(*)
	parameter(version='(version 1.0 22-mar-99)')
	real pi,rtd,rtm,dtr
	parameter(pi=3.141592654)
	parameter(rtd=180./pi,rtm=60.*180./pi,dtr=pi/180.)
	real daz1,del1,z,z1,cosz1,sinaz1,az1,el1
	integer iaz,iel,it
	character source*8,out*40
	double precision ut
	real day,st,ra,dec,an,apc(9),epc(8),az,el,daz,del,tilt,t1,t2
	real coll,collim,theta,azbeg,azfin,elbeg,elfin,randoms(2),t
	integer n,npts
c
c  Get user input parameters.
c
	call output('PNTGEN'//version)
	call keyini
	call keyr('tilt',tilt,0.)
	call keyr('collim',collim,0.)
	call keya('out',out,' ')
	call keyi('npts',npts,100)
	call keyr('azrange',azbeg,-85.)
	call keyr('azrange',azfin,85.)
	call keyr('elrange',elbeg,5.)
	call keyr('elrange',elfin,85.)
	call keyfin
c
c  Convert inputs to radians
c
	t = tilt/rtm
	coll = collim/rtm
c
c  Open output file.
c
	if(out.ne.' ')
     *	  open(unit=1, file=out, form='formatted', status='unknown')
c
c  Initialize variables generated.
c   set apc, epc to zero so that PNT fitted values appear in plot label
c
	source = 'test'
	day= 0.
	ut = 0.d0
	st = 0.
	ra = 0.
	dec = 0.
	an = 1.
	do it=1,8
	  apc(it) = 0.
	  epc(it) = 0.
	enddo
	apc(9) = 0.
c
c  Find errors for range of Az and Elevation.
c
	if(collim.ne.0.) then
	  print *,'  el  asin(sin(collim)/cos(el))  error(arcmin)'
	  do iel=5,85,10
	    el = iel*dtr
	    theta = sin(coll)/cos(el)
	    daz = asin(theta) * rtm
	    daz1 = daz - theta * rtm
	    print *,iel,daz,daz1
	  enddo
	endif
c
	if(out.ne.' ')then
	    print *, 'az el collim(daz,del) collim+tilt(daz,del)'
	  do n=1,npts
	    call uniform(randoms,2)
	    az = (azbeg + (azfin-azbeg)*randoms(1))/rtd
	    el = (elbeg + (elfin-elbeg)*randoms(2))/rtd
	    call point(az,el,t,coll,az1,el1)
	    daz = cos(el)*(az1 - az) * rtm
	    del = (el1 - el) * rtm
	    daz1 = daz - tilt*sin(el)*sin(az)
	    del1 = del - tilt*cos(az)
	    print *, az1/dtr, el1/dtr, daz, del, daz1, del1
	    write(1,990) source, day, ut, st, ra, dec,
     *		 an, apc, epc, az1/dtr, el1/dtr, daz, del, tilt, t1, t2
	  enddo
990      format(a8,1x,f12.2,4f10.5,f4.0,17f8.3,2f9.3,5f8.3)
	endif
c
	if(tilt.ne.0.) then
	 do iaz=5,85,20
	  do iel=5,85,20
	    az = iaz*dtr
	    el = iel*dtr
	    z  = (90-iel)*dtr
	    cosz1 = cos(z)*cos(t) - sin(z)*sin(t)*cos(az)
	    z1 = acos(cosz1)
	    sinaz1 = sin(z1)*sin(az)/sin(z)
	    daz = cos(el)*(asin(sinaz1) - az) * rtm
	    del = (z1 - z) * rtm
	    daz1 = daz - tilt*sin(el)*sin(az)
	    del1 = del - tilt*cos(az)
	    print *,tilt,iaz,iel,daz,del,daz1,del1
	  enddo
	 enddo
	endif
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine point(az,el,tilt,coll,az1,el1)
	implicit none
	real az,el,tilt,coll,az1,el1
c
c  Calculate azimuth and elevation due to tilt and collimation errors.
c
c  Input:
c    az,el	Input azimuth and elevation in radians.
c    tilt,coll	Tilt and collimation errors in radians.
c  Output:
c    az,el	Output azimuth and elevation in radians.
c-----------------------------------------------------------------------
	real cosz1,sinaz1
c
	cosz1 = sin(el)*cos(tilt) - cos(el)*sin(tilt)*cos(az+coll)
	el1 = asin(cosz1)
	sinaz1 = cos(el1)*sin(az)/cos(el)
	az1 = asin(sinaz1)
c
c  Add on collimation error.
c
c	az1 = az1 + asin(sin(coll)/cos(el1))
	end
