c************************************************************************
	program solar
	implicit none
c
c+
c	SOLAR is a MIRIAD task to report some parameters on solar system
c	objects.
c
c@ object
c	This can be "sun" or the name of a major planet (excluding the Earth).
c	No default.
c@ epoch
c	The time (UTC) for which information is required. No default.
c@ observ
c	The name of an observatory used in computing rise and set times.
c	The default is not to compute these.
c--
c------------------------------------------------------------------------
	include 'mirconst.h'
	double precision AUKM
	integer EARTH,SUN
	parameter(AUKM=149.597870D6,EARTH=3,SUN=0)
c
	character planet*8,observ*16
	double precision jday,sub(3),dist,long,lat,ra,dec,w,r,f
	integer np,nout,i
	real bmaj,bmin,bpa
	character line*64
	logical ok
c
c  Externals.
c
	character rangle*32,hangle*32
	double precision deltime
c
	integer NPLANETS
	parameter(NPLANETS=10)
	character planets(NPLANETS)*8
	data planets/'sun     ','mercury ','venus   ','earth   ',
     *		     'mars    ','jupiter ','saturn  ','uranus  ',
     *		     'neptune ','pluto   '/
c
	call keyini
	call keymatch('object',NPLANETS,planets,1,planet,nout)
	if(nout.eq.0)call bug('f','An object must be given')
	call keyt('epoch',jday,'atime',0.d0)
	if(jday.lt.1)call bug('f','An epoch must be given')
	call keya('observ',observ,' ')
	call keyfin
c
c  Match the planet.
c
	do i=1,NPLANETS
	  if(planets(i).eq.planet)np = i-1
	enddo
	if(np.eq.EARTH)
     *	  call bug('f','No information available on the Earth')
c
c  Convert UTC to TDB.
c
	jday = jday + deltime(jday,'tdb')
c
	call output('Information on '//planets(np+1))
	if(np.eq.SUN)then
	  call sunradec(jday,ra,dec)
	  call output('Apparent RA:  '//hangle(ra))
	  call output('Apparent DEC: '//rangle(dec))
	else
	  call plphyeph(jday,np,ra,dec,w,r,f)
	  call plpar(jday,np,sub,dist,bmaj,bmin,bpa)
	  call plradec(jday,np,ra,dec)
	  if(ra.lt.0)ra = ra + 2*pi
	  call output('RA:  '//hangle(ra))
	  call output('DEC: '//rangle(dec))
	  call lmn2sph(sub,long,lat)
	  long = mod(long+2*dpi,2*dpi)
	  write(line,'(a,f7.2)')'Longitude  (deg)   ',real(long*180/dpi)
	  call output(line)
	  write(line,'(a,f7.2)')'Latitude   (deg)   ',
     *					      real(lat*180/dpi)/(1-f)**2
	  call output(line)
	  write(line,'(a,f7.2)')'Distance   (au)    ',real(dist/AUKM)
	  call output(line)
	  write(line,'(a,f7.2)')'Major axis (arcsec)',180/pi*3600*bmaj
	  call output(line)
	  write(line,'(a,f7.2)')'Minor axis (arcsec)',180/pi*3600*bmin
	  call output(line)
	  write(line,'(a,f7.2)')'PA of axis (deg)   ',180/pi*bpa
	  call output(line)
	endif
c
c  Handle the rise and set time if needed.
c
	if(observ.ne.' ')then
          call obspar(observ,'latitude',lat,ok)
          if(ok)call obspar(observ,'longitude',long,ok)
          if(.not.ok)
     *	    call bug('f','Could not determine observatory lat/long')
	  call riseset(jday,lat,long,ra,dec)
	endif
c
	end
c************************************************************************
	subroutine riseset(jday,lat,long,ra,dec)
c
	implicit none
	double precision jday,lat,long,ra,dec
c
c  Echo out the source rise and set times (assume 13 degrees minimum
c  elevation).
c
c  Input:
c    jday	The date of interest.
c    lat,long	Source latitude and longitude.
c    ra,dec	Source apparent RA and DEC.
c------------------------------------------------------------------------
	include 'mirconst.h'
	real sinel,sinl,cosl,sind,cosd,ha
	double precision rise,set,temp
	character string*32
c
	double precision LstJul
c
	sinl = sin(lat)
	cosl = cos(lat)
	sind = sin(dec)
	cosd = cos(dec)
	sinel = sin(12.*pi/180.)
c
	call output(' ')
	temp = (sinel - sinl*sind ) / (cosl*cosd)
	if(abs(temp).gt.1)then
	  if(dec*lat.lt.0)then
	    call bug('w','Source never rises to 12 deg elevation')
	  else
	    call output('Source is always above the horizon')
	  endif
	else
c
c  HA is the hour angle when the source rises/sets, while "rise" and "set"
c  are the LST times of rise and set.
c
	  ha = acos(temp)
	  rise = ra - ha
	  set  = ra + ha
c
c  Convert from LST to UT.
c
	  call output('For a minimum elevation of 12 degrees ...')
	  rise = LstJul(rise,jday,long)
	  call julday(rise,'H',string)
	  call output('Source rises at UT '//string)
	  rise = rise + ha/pi
c
	  set  = LstJul(set,rise,long)
	  call julday(set,'H',string)
	  call output('Source sets  at UT '//string)
	endif
c
	end
