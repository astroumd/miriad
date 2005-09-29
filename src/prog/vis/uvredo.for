c************************************************************************
	program uvredo
	implicit none
c= uvredo -- Recompute various derived quantitues in a uv data-set
c& rjs
c: uv analysis
c+
c	UVREDO recomputes various derived quantities in a uv data-set.
c	This may be needed if the derived quantities are wrong for some
c	reason, or if there is a need to change a coordinate system.
c	For example uvredo can recompute velocity information, thus
c	allowing conversion between different velocity rest frames.
c
c       A patch for handling SMA data has been added into UVREDO in 
c       consideration of the fact that the sky frequency given in the 
c       archived SMA data has been corrected for a part of the tracked 
c       Doppler velocity (the diurnal term and a part of the annual term).
c       The SMA patch calculates the proper residual Doppler velocity for 
c       each of the data records corresponding to the "corrected sky 
c       frequency".
c
c	NOTE: The recomputation relies on a number of parameters in the
c	data-set, such as "time". It is assumed that this information is
c	correct. Uv variables that are important are:
c	For velocity: time and latitu,longitu (or telescop is these are
c	missing).
c@ vis
c	The name of the input uv data set. No default.
c@ select
c	The normal uv selection commands. The default is to select everything.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels. Note that if there are multiple
c	spectral windows, the fitting process is performed on each window
c	separately.
c@ stokes
c	The polarization/Stokes parameters to be copied to the output
c	data-set. The default is to copy the polarisation/Stokes parameters
c	unchanged.
c@ out
c	The name of the output uv data-set. There is no default name.
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreviated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'velocity'    Recompute velocity information.
c	   'chi'         Recompute parallactic angle information.
c	The following options can be used to turn off calibration corrections.
c	The default is to apply any calibration present.
c	   'nocal'       Do not apply the gains table.
c	   'nopass'      Do not apply bandpass corrections.
c	   'nopol'       Do not apply polarizatiopn corrections.
c          'smaveldop'   Recompute the veldop for SMA data.
c                        Keyword: dopsour must be given. 
c
c@ dopsour
c      If options=smaveldop, this gives the source name, on which the Doppler
c      motions were tracked by the SMA online system.
c      dopsour is case-sensitive.
c    
c@ doptime
c      If options=smaveldop, this gives the UT time to calculate the annual 
c      term as a reference value. The offset from this reference value in the 
c      annual term has been used in the SMA online correction to the Doppler 
c      tracked sky frequency in addition to the diurnal term. The keyword 
c      doptime is in the format of [dd,hh,mm,ss.s; 4 values]. The default is 
c      null. If doptime is null, UVREDO reads the residual Doppler velocity 
c      (veldop) of the Doppler tracked source and recomputes the residual 
c      Doppler velocity for each of the selected data records. The residual 
c      Doppler velocity is then stored into the header variable "veldop" 
c      corresponding to the "corrected sky frequency" ("sfreq").
c
c@ velocity
c	If options=velocity or options=smaveldop, this gives the rest frame 
c       of the output data-set. Possible values are 'observatory', 'lsr' and 
c       'barycentric'. The default is the rest frame of the input data-set.
c--
c	It can also recompute equatorial and (u,v) coordinates, to allow
c	a data-set to be converted between different coordinate epochs
c	(e.g. between J2000 and B1950).
c@ epoch
c	If options=radec is set, this gives the epoch of the mean equinox
c	and equator of the output.
c	   'uv'          Recompute uv coordinates (not implemented yet).
c	   'radec'       Transform RA and DEC to a different epoch (not
c	                 implemented yet). This also invokes uv coordinate
c	                 recomputation.
c	   'lst'         Recompute local apparent sidereal time (not
c	                 implemented yet).
c	   'all'         Do ALL the above.
c  History:
c    rjs  31aug93 Original version.
c    mjs  23sep93 bsrcha -> binsrcha, per miriad-wide change.
c    rjs  28nov93 Parallactic recomputation.
c    rjs  15jul95 Why doesn't options=jupaxis get mentioned in this
c		  history. I have improved it a bit.
c    rjs  19jun97 Eliminate jupaxis business (now in uvjup).
c    dpr  22may01 Marginal XY-EW support
c    mchw 26aug03 Added Nasmyth for SMA
c    jhz  31aug05 A patch for handling SMA data has been added to calculate
c    the residual Doppler velocity considering the sky frequency
c    in the archived SMA data has been corrected for a part of the
c    tracked Doppler velocity (the diurnal term and part of the annual
c    term).
c    jhz  16sep05 initialize the array doptime; otherwise
c                 it may cause problem in some syetems.
c    jhz  29sep05 add vsource to smavelop when calculates
c                 the residual veldop for SMA data.
c
c  Bugs:
c    * Much more needs to be added.
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	character version*(*)
	parameter(version='UvRedo: version 1.3 29-Sept-05')
	integer OBS,HEL,LSR
	parameter(OBS=1,HEL=2,LSR=3)
c
	character out*64,ltype*16,uvflags*16,dsource*8
	integer frame,lIn,lOut
	logical dovel,dochi,dosma
c
c  Externals.
c
	logical uvDatOpn
         real doptime(4)
         integer  nt,i
c
c intialize
c
           do i=1,4
           doptime(i) = 0.0
           end do
c
c  Get the input parameters.
c
        dosma=.false.
	call output(version)
c  
	call keyini
	call GetOpt(dovel,dochi,uvflags,dosma)
            if(dosma) then 
            call keya('dopsour',dsource, ' ')
            dovel = .true.
            call mkeyr ('doptime',doptime,4,nt)
            end if
	    frame = 0
	if(dovel) call GetRest(frame)
	call uvDatInp('vis',uvflags)
	call keya('out',out,' ')
c
	call keyfin
c
c  Check the inputs.
c
	if(out.eq.' ')call bug('f','An output must be given')
	if(.not.dovel.and..not.dochi)
     *	  call bug('f','Nothing to recompute!')

c
c for the SMA patch
c
       if(dosma.and.(dsource(1:1).eq.' '))
     *     call bug('f', 'no dopsour is given.')
       if(dosma) then
        if(.not.uvdatopn(lIn))call bug('f','Error opening input file')
      call sourfind(lIn,dsource,doptime)
        call uvdatcls     
        end if
c
c  Regets the input parameters and
c  Open the inputs and the outputs.
c 
        call keyini
           call GetOpt(dovel,dochi,uvflags,dosma)
            if(dosma) then
            call keya('dopsour',dsource, ' ')
            dovel = .true.
            call mkeyr ('doptime',doptime,4,nt)
            end if
        frame = 0
        if(dovel) call GetRest(frame)
        call uvDatInp('vis',uvflags)
        call keya('out',out,' ')
        call keyfin
	if(.not.uvDatOpn(lIn))
     *	  call bug('f','Failed to open the input data-set')
	call uvDatGta('ltype',ltype)
	call VarInit(lIn,ltype)
c
	call uvopen(lOut,out,'new')
	call hdcopy(lIn,lOut,'history')
	call hisopen(lOut,'append')
	call hiswrite(lOut,'UVREDO: Miriad '//version)
	call hisinput(lOut,'UVREDO')
	call hisclose(lOut)
	call VarOnit(lIn,lOut,ltype)
c
c  Do the work.
c
	call Process(lIn,lOut,dovel,frame,dochi,dosma)
c
c  All said and done. Close up shop.
c
	call uvDatCls
	call uvclose(lOut)
	end
c************************************************************************
	subroutine GetRest(frame)
c
	implicit none
	integer frame
c
c  Determine the rest frame.
c------------------------------------------------------------------------
	integer nout
	integer nframes
	parameter(nframes=3)
	character rframes(nframes)*11,rframe*11
c
c  Externals.
c
	integer binsrcha
c
	data rframes/'barycentric','lsr        ','observatory'/
c
	call keymatch('velocity',nframes,rframes,1,rframe,nout)
	frame = 0
	if(nout.ne.0)frame = binsrcha(rframe,rframes,nframes)
	end
c************************************************************************
	subroutine GetOpt(dovel,dochi,uvflags,dosma)
c
	implicit none
	logical dovel,dochi,dosma
	character uvflags*(*)
c
c  Determine extra processing options.
c
c  Output:
c    dovel
c    dochi
c    uvflags
c    dosma
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=6)
	logical present(NOPTS)
	character opts(NOPTS)*9
c
	data opts/'velocity ','chi      ',
     *		  'nocal    ','nopol    ','nopass   ',
     *            'smaveldop'/
c
	call options('options',opts,present,NOPTS)
	dovel = present(1)
	dochi = present(2)
c
c  Determine the flags to pass to the uvDat routines.
c    d - Data selection.
c    l - Linetype processing.
c    s - Stokes processing.
c    b - Input must be a single file.
c    c - Apply gain table.
c    e - Apply leakage correction.
c    f - Apply bandpass correction.
c
	uvflags = 'dlsb'
	if(.not.present(3))uvflags(5:5) = 'c'
	if(.not.present(4))uvflags(6:6) = 'e'
	if(.not.present(5))uvflags(7:7) = 'f'
         dosma = present(6)
c
	end
c************************************************************************
	subroutine Process(lIn,lOut,dovel,frame,dochi,dosma)
c
	implicit none
	integer lIn,lOut
	logical dovel,dochi
	integer frame
        logical dosma

c  Do all the real work.
c
c  Input:
c    lIn
c    lOut
c    dovel
c    frame	The rest frame for the velocity.
c    dochi	Do parallactic angle recomputation.
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer nchan,velupd,chiupd
	double precision preamble(4),time,lst,epoch,ra,dec,rapp,dapp
	logical flags(MAXCHAN)
	complex data(MAXCHAN)
	logical needlst,needepo,needrade,needapp
c
c  Externals.
c
	logical uvVarUpd
c
c  Determine what we need.
c
	needlst  = dovel.or.dochi
	needepo  = dovel
	needrade = dovel
	needapp  = dovel.or.dochi
c
c  Initialise for the various recomputations.
c
	if(dochi)call ChiInit(lIn,chiupd)
	if(dovel)call VelInit(lIn,velupd)
c
c  Read the first record.
c
	call uvDatRd(preamble,data,flags,MAXCHAN,nchan)
c
c  the default rest frame, if we are doing velocity recomputation
c  and a rest frame has not been given.
c
	if(dovel.and.frame.eq.0)call GetFrame(lIn,frame)
	dowhile(nchan.gt.0)
c
c  Copy all the variables from the input to the output.
c
	  call PolCpy(lOut)
	  call VarCopy(lIn,lOut)
c
c  Get things from the visibility file.
c
	  time = preamble(3)
	  if(needlst)call uvrdvrd(lIn,'lst',lst,0.d0)
	  if(needepo)call uvrdvrd(lIn,'epoch',epoch,2000.d0)
	  if(needrade)then
	    call uvrdvrd(lIn,'ra',ra,0.d0)
	    call uvrdvrd(lIn,'dec',dec,0.d0)
	  endif
	  if(needapp)then
	    call uvrdvrd(lIn,'obsra',rapp,ra)
	    call uvrdvrd(lIn,'obsdec',dapp,dec)
	  endif
c
c  Recompute parallactic angle.
c
	  if(dochi)then
	    if(uvvarupd(chiupd))call ChiComp(lIn,lOut,
     *		lst,rapp,dapp)
	  endif
c
c  Recompute velocity.
c
	  if(dovel)then
	    if(uvvarupd(velupd))call VelComp(lIn,lOut,frame,
     *		lst,time,rapp,dapp,epoch,ra,dec,dosma)
	  endif
c
c  All done. Loop the loop.
c
	  call uvwrite(lOut,preamble,data,flags,nchan)
	  call uvDatRd(preamble,data,flags,MAXCHAN,nchan)
	enddo
c
	end
c************************************************************************
	subroutine ChiInit(lIn,chiupd)
c
	implicit none
	integer lIn,chiupd
c
c  Determine which variables cause us to recompute.
c
c------------------------------------------------------------------------
	logical needtel
c
	logical varprsnt
c
	call uvVarIni(lIn,chiupd)
	call uvVarSet(chiupd,'time')
	call uvVarSet(chiupd,'obsra')
	call uvVarSet(chiupd,'obsdec')
	needtel = .false.
	if(varprsnt(lIn,'latitud'))then
	  call uvVarSet(chiupd,'latitud')
	else
	  needtel = .true.
	endif
	if(varprsnt(lIn,'evector'))then
	  call uvVarSet(chiupd,'evector')
	else
	  needtel = .true.
	endif
	if(varprsnt(lIn,'mount'))then
	  call uvVarSet(chiupd,'mount')
	else
	  needtel = .true.
	endif
	if(needtel)then
	  if(varprsnt(lIn,'telescop'))then
	    call uvVarSet(chiupd,'telescop')
	  else
	    call bug('f','Could not determine the telescope')
	  endif
	endif
c
	end
c************************************************************************
	subroutine ChiComp(lIn,lOut,lst,rapp,dapp)
c
	implicit none
	integer lIn,lOut
	double precision lst,rapp,dapp
c
c  Determine the parallactic angle.
c
c------------------------------------------------------------------------
	real evec,chi
	integer mount
	double precision lat,dtemp
        double precision elev,ha,sinha,cosha,sind,cosd,sinl,cosl
	logical ok
	character telescop*32
c
	integer EQUATOR,ALTAZ,XYEW,NASMYTH
	parameter(EQUATOR=1,ALTAZ=0,XYEW=3,NASMYTH=4)
c
c  Externals.
c
	logical varprsnt
c
c  Determine the telescope mount.
c
	if(varprsnt(lIn,'mount'))then
	  call uvgetvri(lIn,'mount',mount,1)
	else
	  call uvrdvra(lIn,'telescop',telescop,' ')
	  call obspar(telescop,'mount',dtemp,ok)
	  if(.not.ok)call bug('f',
     *	   'Could not determine the telescope mount')
	  mount = nint(dtemp)
	endif
c
c  Determine evector.
c
	if(varprsnt(lIn,'evector'))then
	  call uvgetvrr(lIn,'evector',evec,1)
	else
	  call uvrdvra(lIn,'telescop',telescop,' ')
	  call obspar(telescop,'evector',dtemp,ok)
	  if(.not.ok)call bug('f',
     *	    'Could not evector for the telescope')
	  evec = dtemp
	endif
c
	if(mount.eq.EQUATOR)then
	  chi = 0
	else if(mount.eq.ALTAZ) then
	  if(varprsnt(lIn,'latitud'))then
	    call uvgetvrd(lIn,'latitud',lat,1)
	  else
	    call uvrdvra(lIn,'telescop',telescop,' ')
	    call obspar(telescop,'latitude',lat,ok)
	    if(.not.ok)call bug('f',
     *		'Unable to determine telescope latitude')
	  endif
	  call parang(rapp,dapp,lst,lat,chi)
	else if(mount.eq.NASMYTH) then
	  if(varprsnt(lIn,'latitud'))then
	    call uvgetvrd(lIn,'latitud',lat,1)
	  else
	    call uvrdvra(lIn,'telescop',telescop,' ')
	    call obspar(telescop,'latitude',lat,ok)
	    if(.not.ok)call bug('f',
     *		'Unable to determine telescope latitude')
	  endif
	  call parang(rapp,dapp,lst,lat,chi)
c
c       For Nasmyth SMA -- Needs to be modified by elev
c
               ha = lst-rapp
               sinha = sin(ha)
               cosha = cos(ha)
               sind = sin(dapp)
               cosd = cos(dapp)
               sinl = sin(lat)
               cosl = cos(lat)
               elev = asin(sinl*sind+cosl*cosd*cosha)
               chi = - elev + chi
          else
	endif
c
c  At last, write out the "chi" variable.
c
	call uvputvrr(lOut,'chi',chi+evec,1)
c
	end
c************************************************************************
	subroutine VelInit(lIn,velupd)
c
	implicit none
	integer lIn,velupd
c
c  Determine which variables cause us to recompute.
c
c------------------------------------------------------------------------
	logical varprsnt
c
	call uvVarIni(lIn,velupd)
	call uvVarSet(velupd,'time')
	call uvVarSet(velupd,'ra')
	call uvVarSet(velupd,'dec')
	if(varprsnt(lIn,'latitud'))then
	  call uvVarSet(velupd,'latitud')
	else if(varprsnt(lIn,'telescop'))then
	  call uvVarSet(velupd,'telescop')
	else
	  call bug('f','Unable to determine observatory latitude')
	endif
	end
c************************************************************************
	subroutine VelComp(lIn,lOut,frame,lst,time,rapp,dapp,
     *					epoch,ra,dec,dosma)
c
	implicit none
	integer lIn,lOut,frame
	double precision lst,time,rapp,dapp,epoch,ra,dec
        logical dosma
c
c  Compute the radial velocity, and update the output file.
c
c------------------------------------------------------------------------
	integer OBS,LSR,HEL
	parameter(OBS=3,LSR=2,HEL=1)
c
	integer length,i
	real veldop
	double precision vel(3),pos(3),lat,lmn(3),ra2000,dec2000
	character telescop*16,type*1
	logical ok
	character rframes(3)*8
c
c  Externals.
c
	double precision epo2jul
        real smaveldop
c
	data rframes/'VELO-HEL','VELO-LSR','VELO-OBS'/
       
c
c  If its a topocentric velocity, determining it is pretty easy!
c
	if(frame.eq.OBS)then
	  veldop = 0
	else
c
c  Otherwise its a bit more involved.
c  Get the telescope latitude.
c
	  call uvprobvr(lIn,'latitud',type,length,ok)
	  if(type.eq.'d'.and.length.eq.1)then
	    call uvgetvrd(lIn,'latitud',lat,1)
	  else
	    call uvrdvra(lIn,'telescop',telescop,' ')
	    call obspar(telescop,'latitude',lat,ok)
	    if(.not.ok)call bug('f',
     *		'Unable to determine telescope latitude')
	  endif
c
c  Compute the velocity.
c
	  call sph2lmn(rapp,dapp,lmn)
c  Diurnal.
	  call vsite(lat,lst,vel)
	  veldop = 0
	  do i=1,3
	    veldop = veldop - vel(i)*lmn(i)
	  enddo

c  Annual.
	  call vearth(time,pos,vel)
	  do i=1,3
	    veldop = veldop - vel(i)*lmn(i)
	  enddo

          if(dosma) then
          veldop = veldop -
     *    smaveldop(lIn,time,lst,lat,frame)
          end if


c  LSR
	  if(frame.eq.LSR)then
	    if(abs(epoch-2000).gt.0.001)then
	      call precess(epo2jul(epoch,' '),ra,dec,
     *	        epo2jul(2000.d0,'J'),ra2000,dec2000)
	      call sph2lmn(ra2000,dec2000,lmn)
	    else
	      call sph2lmn(ra,dec,lmn)
	    endif
	    call vsun(vel)
	    do i=1,3
	      veldop = veldop + vel(i)*lmn(i)
	    enddo
	  endif
	endif
c
c  Save the info in the data-set.
c
	call uvputvra(lOut,'veltype',rframes(frame))
	call uvputvrr(lOut,'vsource',0.,1)
	call uvputvrr(lOut,'veldop',veldop,1)
	end
c************************************************************************
	logical function varprsnt(tno,var)
c
	implicit none
	integer tno
	character var*(*)
c
c  Determine whether a variable is present.
c------------------------------------------------------------------------
	character type*1
	logical upd
	integer n
c
	call uvprobvr(tno,var,type,n,upd)
	varprsnt = type.ne.' '
	end
c************************************************************************
	subroutine PolCpy(lOut)
c
	implicit none
	integer lOut
c------------------------------------------------------------------------
	integer npol,pol
c
	call uvDatGti('npol',npol)
	if(npol.eq.0)
     *	    call bug('f','Could not determine number of polarisations')
	call uvDatGti('pol',pol)
	call uvputvri(lOut,'npol',npol,1)
	call uvputvri(lOut,'pol',pol,1)
	end
c************************************************************************
	subroutine GetFrame(lIn,frame)
c
	implicit none
	integer lIn,frame
c
c  Determine the default velocity rest frame.
c
c------------------------------------------------------------------------
	integer nframes
	parameter(nframes=6)
	character rframes(nframes)*8,rframe*12
c
c  Externals.
c
	integer binsrcha
c
	data rframes/'FELO-HEL','FELO-LSR','FELO-OBS',
     *		     'VELO-HEL','VELO-LSR','VELO-OBS'/
c
	call uvrdvra(lIn,'veltype',rframe,'VELO-LSR')
	frame = binsrcha(rframe,rframes,nframes)
	if(frame.gt.3) frame = frame - 3
	if(frame.eq.0) frame = 2
c
	end
c************************************************************************
        real function smaveldop(lIn,time,lst,smalat,frame)
        integer lIn
        double precision doptrkra, doptrkdec, time, lst,Jultransit
        logical dosma,getsmavel
        real velsma0
        common/smavel/doptrkra,doptrkdec,
      &                 Jultransit,velsma0,dosma,getsmavel

c
c Calculate the part of Doppler tracked velocity that has been 
c corrected to the chunk frequency recorded in the MIR data header
c (the raw SMA data).
c input from common/smavel/
c     doptrkra      Right ascension (radian) of the phase center (source)
c                   in J2000 that is used for Doppler tracking.
c     doptrkdec     Declination (radian) of the phase center (source)
c                   in J2000 that is used for Doppler tracking.
c     Jultransit    The reference time at which the offset in the annual
c                   term has been used in the correction to the
c                   chunk frequency.
c     velsma0       The residual doppler velocity corresponds
c                   to the Doppler tracked source and the SMA
c                   "sky frequnecy"
c input from the calling:
c     time          Time in Julian date.
c     lst           Local apparent sideral time in radian.
c     smalat        Geodetic latitude of the SMA (radian).
        double precision raapp,decapp,r1,d1,lmn(3)
        double precision lmnapp(3),vel(3),pos(3),smalat
        real veldop,vsource
        integer i,frame
        integer OBS,LSR,HEL
        parameter(OBS=3,LSR=2,HEL=1)

c
c   external
c 
         double precision epo2jul
c
c Calculate the apparent right ascension (radian) and the apparent 
c declination (radian) of the phase center (source)    
c
         call precess(epo2jul(2000.d0,'J'),
     &        doptrkra,doptrkdec,time,raapp,decapp)
         call Nutate(time,raapp,decapp,r1,d1)
         call Aberrate(time,r1,d1,raapp,decapp)
c
c  Convert spherical coordinates (e.g. ra,dec) into
c  direction cosines.
c
         call sph2lmn(raapp,decapp,lmnapp)
c
c Calculate the Diurnal term 
c
          call vsite(smalat,lst,vel)
          veldop = 0
          do i=1,3
          veldop = veldop - vel(i)*lmnapp(i)
          enddo

c
c Calculate the Annual term 
c

          call vearth(time,pos,vel)
          do i=1,3
          veldop = veldop - vel(i)*lmnapp(i)
          enddo

            if(getsmavel) then
c
c  The sun motion w.r.t LSR
c 
c  LSR
          if(frame.eq.LSR)then
            call sph2lmn(doptrkra,doptrkdec,lmn)
            call vsun(vel)
            do i=1,3
              veldop = veldop + vel(i)*lmn(i)
            enddo
          endif
c
c  calculate the part of veldop corrected to the chunk frequency.
c
                   veldop = veldop - velsma0
                         else

c
c upto now, we have calculated the time variation part of
c the veldop (diurnal and annual).
c Now we need to calculate the annual term at the reference time,
c a constant offset which has been taken out from the total contribution 
c from the diurnal and annual.
c
         call precess(epo2jul(2000.d0,'J'),
     &       doptrkra,doptrkdec,Jultransit,raapp,decapp)
         call Nutate(time,raapp,decapp,r1,d1)
         call Aberrate(time,r1,d1,raapp,decapp)
c
c  Convert spherical coordinates (e.g. ra,dec) into
c  direction cosines.
c
          call sph2lmn(raapp,decapp,lmn)
c
c    calculate the earth velocity at transit
c
c         write(*,*) (Jultransit-int(Jultransit-0.5)-0.5)*24.
          call vearth((Jultransit),pos,vel)
          do i=1,3
          veldop = veldop + vel(i)*lmn(i)
          enddo
                        end if
c
c  this part has been corrected
c  in the SMA chunk frequency recorded
c
          call uvrdvrr (lin, 'vsource', vsource, 0.0)
          smaveldop = veldop+vsource
          end
c  ******************************
         subroutine sourfind(tno,dsource,doptime)
          real doptime(4), sumtime
          integer tno,vupd,nread
          include 'maxdim.h'
c
c retrieve the Doppler-tracked source and get its ra-dec coordinates
c in the epoch J2000.0, the epoch of catalog coordinates that the SMA supports.
c
          double precision preamble(4),long,lat
          complex data(maxchan)
          logical flags(maxchan)
          character dsource*8, source*32
          double precision time
          double precision doptrkra,doptrkdec,Jultransit
          real velsma0
          logical dosma, getsmavel
          common/smavel/doptrkra,doptrkdec,
      &                 Jultransit,velsma0,dosma,getsmavel

                
c
c   external
c
c          double precision epo2jul,LstJul
          logical ok, uvvarupd
                     call uvvarini(tno,vupd)
                     call uvvarset(vupd,'source')
          ok=.false.
          nread=maxchan
          time=0.0
          sumtime=0.0
          getsmavel=.false.
          dosma=.true.
c              write(*,*) dsource(1:8)
          call uvnext(tno, ' ')
          call uvrdvra(tno,'source', source,' ')
            call uvgetvrd(tno,'longitu',long,1)
         call uvgetvrd(tno,'latitud',lat,1)
         call uvdatrd(preamble,data,flags,maxchan,nread)
          dowhile((.not.ok).and.(nread.gt.0))
c              dowhile(nread.gt.0) 
           if(source(1:len1(source)).eq.dsource(1:len1(dsource))) then 
                call uvrdvrd(tno,'ra',doptrkra,0.d0)
                call uvrdvrd(tno,'dec',doptrkdec,0.d0)
                call uvrdvrr(tno,'veldop',velsma0,0.)
                ok=.true.
           end if
            call uvnext(tno, ' ')
              if(uvvarupd(vupd)) then
              call uvrdvra(tno,'source', source,' ')
              end if
             call uvdatrd(preamble,data,flags,maxchan,nread)
             time = preamble(3)
            end do
          Jultransit=time
          if(.not.ok) call bug('f', 
      *   'The source = '//dsource(1:len1(dsource))//' is not found.')
          do i=1, 4
          sumtime=sumtime+doptime(i)
          end do
          if(abs(sumtime).le.1.e-15) then
          getsmavel=.true.
          else
c
c         assign the time in Julian date at which the annual term (of veldop)
c         was used in the correction to sfreq
c
          Jultransit = int(Jultransit-0.5)+0.5
      &  + doptime(1)+doptime(2)/24.+doptime(3)/24./60.
      &  + doptime(4)/24./3600.
          end if
          end
