c************************************************************************
	program gildas
	implicit none
c= gildas - Conversion from MIRIAD to uv FITS for GILDAS convention 
c& jhz
c: data transfer
c+
c	GILDAS is a MIRIAD task, which converts Miriad uv files to 
c       FITS following the GILDAS convention for the headers
c       of spectral line features. In this testing version,
c       the cross polarization visibilities are skipped and
c       the parallel polarizations are degenerated to Stokes I. 
c       References:
c	  For a description of the FITS standard, see
c	  http://fits.gsfc.nasa.gov/fits_home.html
c         For a description of Gildas, see
c         http://www.iram.fr/IRAMFR/GILDAS/
c
c@ in
c	Name of the input file (either a MIRIAD file name). 
c       No default.
c@ out
c	Name of the output file (UVFITS file name for GILDAS or AIPS).
c	There is no default.
c@ line
c	Line type of the output, when op=uvout. This is of the form:
c
c	  linetype,nchan,start,width,step
c
c	"Linetype" is either "channel", "wide" or "velocity". "Nchan" is
c	the number of channels in the output.
c@ select
c	Normal uv selection.
c@ linename
c       The name of the spectral line transition; maximum length
c       is 12; default is empty. Usage: linename = 'H2O'
c@ options
c	These options applies for op=uvin only.
c	  compress Store the data in compressed uv format.
c	  lefty    Assume that the UVFITS antenna table uses a
c	           left-handed coordinate system (rather than the
c	           more normal right-handed system).
c	  varwt    The visibility weight in the UVFITS file should
c	           be interpretted as the reciprocal of the noise
c	           variance on that visibility.
c
c	  nocal    Do not apply the gains table to the data.
c	  nopass   Do not apply the bandpass table correctsions
c	           to the data.
c
c	  nod2     Use the conventions of NOD2 UVFITS files.
c         aips     Output for AIPS UVFIT; default is for GILDAS. 
c
c--
c
c  Bugs:
c
c  History:
c    jhz  06-jun-06  started a version for converting miriad to UVFITS
c                    using gildas convention for spectral line features 
c                    based on rjs' fits: version 6-jan-05'
c    jhz  15-jun-06 changed options nogildas to aips
c  Note:
c        only for miriad-> gildas
c        consider for gildas->miriad
c------------------------------------------------------------------------
	character version*(*)
	parameter(version='Gildas: version 0.2 15-jun-06')
	integer MAXBOXES
	parameter(MAXBOXES=2048)
	character in*128,out*128,uvdatop*12,linename*12
	logical docal,dopol,dopass,dss,dochi,nod2,compress
	logical lefty,varwt,dogildas
c
c  Get the input parameters.
c
       
	call output( version )
	call keyini
        call keya('out',out,' ')
        call keya('linename',linename, '  ')
        call getopt(docal,dopol,dopass,dss,nod2,dochi,compress,
     *	lefty,varwt,dogildas)
          uvdatop = 'sdlb3'
	  if(docal)uvdatop(6:6) = 'c'
	  if(dopol)uvdatop(7:7) = 'e'
	  if(dopass)uvdatop(8:8) = 'f'
          call uvdatinp('in',uvdatop)
c
	call keyfin
	if(in.eq.' ')
     *	  call bug('f','Input file name is missing')
	if(out.eq.' ')
     *	  call bug('f','Output file name is missing')
c
c  Handle the five cases.
c
	  call uvout(out,version,linename,dogildas)
	end

c************************************************************************
      subroutine getopt(docal,dopol,dopass,dss,nod2,dochi,
     *  compress,lefty,varwt,dogildas)
c
      implicit none
      logical docal,dopol,dopass,dss,dochi,nod2,compress,lefty,varwt
      logical dogildas
c
c     Get a couple of the users options from the command line
c
c  Output:
c    docal   Apply gain calibration
c    dopol   Apply polarization calibration
c    dopass  Apply bandpass calibration
c    dss     Handle DSS image.
c    nod2    Handle NOD2 image.
c    dochi   Attempt to calculate the parallactic angle.
c    compress Store data in compressed format.
c    lefty   Assume antenna table uses a left-handed system.
c    varwt   Interpret the visibility weight as the reciprocal of the
c            noise variance.
c    dogildas  true for gildas; false for AIPS
c------------------------------------------------------------------------
      integer nopt
      parameter (nopt = 11)
      character opts(nopt)*8
      logical present(nopt),olddss
      data opts /'nocal   ','nopol   ','nopass  ','rawdss  ',
     *           'nod2    ','nochi   ','compress','lefty   ',
     *           'varwt   ','dss     ','aips    '/

c
      call options ('options', opts, present, nopt)
      docal    = .not.present(1)
      dopol    = .not.present(2)
      dopass   = .not.present(3)
      dss      =      present(4)
      nod2     =      present(5)
      dochi    = .not.present(6)
      compress =      present(7)
      lefty    =      present(8)
      varwt    =      present(9)
      olddss   =      present(10)
c
      dopol    = .false.
      dochi    = .false.
      if (olddss) then
        call bug('w','Option DSS is deprecated. Please use RAWDSS')
        dss=.true.
      endif
      dogildas  = present(11)
      if(dogildas) then
           dogildas=.false.
       else
           dogildas=.true.
      end if
c
      end
c************************************************************************
        subroutine uvout(out,version,linename,dogildas)
c
        implicit none
        character out*(*),version*(*), linename*12
        logical dogildas
c
c  Write out a UV FITS file.
c
c  Inputs:
c    out        Name of the output uv FITS file.
c    version    Version of this program.
c------------------------------------------------------------------------
        include 'maxdim.h'
        include 'mirconst.h'
        integer uvCrval,uvCdelt,uvCrpix
        integer uvStokes,uvFreq,uvRa,uvDec
        parameter(uvCrval=1,uvCdelt=2,uvCrpix=3)
        parameter(uvStokes=1,uvFreq=2,uvRa=3,uvDec=4)
c
        integer uvU,uvV,uvW,uvBl,uvT,uvSrc,uvRandom,uvData
        parameter(uvU=1,uvV=2,uvW=3,uvBl=4,uvT=5,uvSrc=6,uvRandom=6)
        parameter(uvData=uvRandom+1)
c
        integer Polmin,Polmax,maxPol,PolRR,PolXX
        parameter(PolMin=-8,PolMax=4,maxPol=4,PolXX=-5,PolRR=-1)
c
        complex Data(maxchan)
        logical Flags(maxchan)
        real OutData(uvRandom+1+3*maxchan)
c
        integer i,i0
        integer tIn,tScr,tOut,vSrc
        integer nread,nvis,nVisRef,offset,length,velref,nchan
        integer nSrc,iSrc
        integer ant1,ant2
        real wt,epoch
        double precision pntra,pntdec,restfreq,preamble(5),Coord(3,4)
        double precision f0,df,v0,dv,repsi,fepsi,vepsi,T0
        character string*64,ltype*32,veltype*32,vtype(6)*8
        character observer*32,telescop*32
        integer pols(PolMin:PolMax),P,badpol,npol,Pol0,PolInc
        integer nants,mount
        character polty*2,type*1
        logical updated
        double precision xyz(3*MAXANT),lat,long,height
c
        integer MAXSRC
        parameter(MAXSRC=512)
        double precision ras(MAXSRC),decs(MAXSRC),antbas
        double precision aras(MAXSRC),adecs(MAXSRC)
        character sources(MAXSRC)*16
c
        integer MAXPARMS
        parameter(MAXPARMS=6)
        integer nparms
        character parms(MAXPARMS)*8
c  for gildas
        real CKMS
        parameter(CKMS=299792.458)
        double precision fwidth
        integer nivis, nrrvis,nllvis,nxxvis,nyyvis
        character line*32
        integer plength, len1
       
c
c  Externals.
c
        character itoaf*8
        logical uvdatopn
        logical hdprsnt
c
        data parms/'UU      ','VV      ','WW      ',
     *             'BASELINE','DATE    ','SOURCE  '/
        data vtype/'FELO-LSR','FELO-HEL','FELO-OBS',
     *             'VELO-LSR','VELO-HEL','VELO-OBS'/
c
c  Initialise the array to count the sorts of polarizations that we have.
c
        nivis=0
        nrrvis=0
        nllvis=0
        nxxvis=0
        nyyvis=0
        do i=PolMin,PolMax
          pols(i) = 0
        enddo
c
c  Open up and initialise the input file. Also get the scratch file.
c
        if (.not.uvdatopn(tin))call bug('f','Error opening input file')
        call uvVarIni(tin,vSrc)
        call uvVarSet(vSrc,'source')
        call uvVarSet(vSrc,'dra')
        call uvVarSet(vSrc,'ddec')
        call scropen(tScr)
c
c  Read through the input, determining the min and max values of all the
c  parameters that we need.
c
        nSrc = 0
        iSrc = 0
        ras(1) = 0
        decs(1) = 0
        sources(1) = ' '
c
        call uvdatrd(preamble,data,flags,maxchan,nread)
        if(nread.eq.0)call bug('f','No data to write out!')
        call SrcUpd(tIn,vSrc,iSrc,ras,decs,aras,adecs,sources,
     *                                                  nSrc,MAXSRC)
        call uvrdvrd(tIn,'pntra',pntra,ras(1))
        call uvrdvrd(tIn,'pntdec',pntdec,decs(1))
        nchan = nread
c
        nvis = 0
        length = uvRandom + 1 + 3*nchan
        offset = 0
c
c  Get things which define the coordinate system.
c
        call uvrdvrr(tIn,'epoch',epoch,1950.)
        call uvfit2(tIn,'sfreq',nread,df,f0,fepsi)
        if(fepsi.gt.0.1*abs(df))call bug('w',
     *      'Channel frequencies deviated by > 10% from linearity')
        if(nread.eq.1)call uvfit1(tIn,'bandwidth',nread,df,fepsi)
        f0 = 1e9 * f0
        df = 1e9 * df
c
        call uvdatgta('ltype',ltype)
        if(ltype.eq.'wide')then
          velref = 0
          restfreq = 0
        else
          call uvfit1(tIn,'restfreq',nread,restfreq,repsi)
          if(repsi.gt.0.001*restfreq) call bug('w',
     *      'Rest frequencies varied between channels by > 0.1%')
          restfreq = 1e9 * restfreq
          if(restfreq.gt.0)then
            call uvrdvra(tIn,'veltype',veltype,'VELO-LSR')
            call uvfit2(tIn,'velocity',nread,dv,v0,vepsi)
            v0 = 1000.d0 * v0
            if(vepsi.gt.0.1*abs(dv))call bug('w',
     *        'Channel velocities deviate by > 10% from linearity')
            velref = 0
            do i=1,6
              if(veltype.eq.vtype(i)) velref = i
            enddo
            if(velref.gt.3) velref = velref - 3 + 256
          endif
        endif
c
c  Get other book keeping.
c
        call uvrdvra(tIn,'telescop',telescop,' ')
        call uvrdvra(tIn,'observer',observer,' ')
c
c  Set the reference date.
c
        T0 = preamble(4)
        T0 = int(T0 - 0.5d0) + 0.5d0
c
c  Load antenna table information.
c
        call uvprobvr(tIn,'antpos',type,nants,updated)
        if(mod(nants,3).ne.0)
     *    call bug('f','Antpos variable looks bad')
        nants = nants/3
        if(nants.gt.MAXANT)nants = 0
        if(nants.gt.0)then
          call uvgetvrd(tIn,'antpos',xyz,3*nants)
          call getarr(tIn,mount,lat,long,height)
        endif
c
c  Read the data. Check that we are dealing with a single pointing.
c  If the polarization code is OK, do some conversions, and write to
c  a scratch file.
c
        badpol = 0
        dowhile(nread.eq.nchan)
          call uvdatgti('pol',P)
          
           
c       if(P.ge.PolMin.and.P.le.PolMax.and.P.ne.0)then
        if((P.eq.1).or.(P.eq.-1).or.(P.eq.-2).or.
     *   (P.eq.-5).or.(P.eq.-6)) then
            if(P.eq.1) nivis=nivis+1
             if(P.eq.-1) nrrvis=nrrvis+1
             if(P.eq.-2) nllvis=nllvis+1
              if(P.eq.-5) nxxvis=nxxvis+1
               if(P.eq.-6) nyyvis=nyyvis+1

            P=1
            nvis = nvis + 1
            call uvdatgtr('variance',wt)
            if(wt.eq.0)then
              call uvrdvrr(tIn,'inttime',wt,1.)
            else
              wt = 1/wt
            endif
c
c  Convert baseline number to normal AIPS form. Note the different conventions!
c
c  Miriad convention is that bl = 256*ant1 + ant2, where the baseline is ant2 - ant1
c  AIPS                      bl = 256*ant1 + ant2                        ant1 - ant2c  !!
c
c  In both cases ant1 is normally less than ant2.
c  ant1=0 should never happen, since bad ant's were filtered before. '
c  Are we sure that ant1 < ant2 always here ??
            call Basanta(preamble(5),ant1,ant2)
            if (ant1.eq.0) call bug('f','bad antenna ant1=1')
            pols(P) = pols(P) + 1
c
            OutData(uvU+1) = -1e-9 * preamble(1)
            OutData(uvV+1) = -1e-9 * preamble(2)
            OutData(uvW+1) = -1e-9 * preamble(3)
c      write(*,*) P, OutData(uvU+1),OutData(uvV+1),OutData(uvW+1), nread
            OutData(uvT+1) = preamble(4) - T0
c           OutData(uvBl+1) = 256*ant1 + ant2
            OutData(uvBl+1) = REAL(antbas(ant1,ant2))
            OutData(uvSrc+1) = iSrc
c            OutData(1) = P
            OutData(1) = 1
            i0 = uvData
            do i=1,nchan
              OutData(i0+1) = real(Data(i))
              OutData(i0+2) = -aimag(Data(i))
              if(flags(i))then
                OutData(i0+3) = wt
              else
                OutData(i0+3) = -wt
              endif
              i0 = i0 + 3
            enddo
            call scrwrite(tScr,OutData,offset,length)
            offset = offset + length
          else
            badpol = badpol + 1
          endif
          call uvdatrd(preamble,data,flags,maxchan,nread)
          call SrcUpd(tIn,vSrc,iSrc,ras,decs,aras,adecs,sources,
     *         nSrc,MAXSRC)
        enddo
c
c  Summarise what we read.
c
        if(badpol.gt.0) call bug('w',
     *    'Visibilities with bad pol codes: '//itoaf(badpol))
        if(nread.gt.0) call bug('f','Bad number of channels')
        if(nvis.le.0)  call bug('f','No visibilities found')
c
c  Determine the polarizations that we are going to output.
c
        call PolCheck(pols,PolMin,PolMax,npol,Pol0,PolInc)
ccc
      plength=0
      if(nivis.gt.0) then
      line='I'
      plength =len1(line)+1
      line(plength:plength)=', '
      end if
      if(nrrvis.gt.0) then
      plength =len1(line)
      line=line(1:plength)//'RR'
      plength =len1(line)+1
      line(plength:plength)=', '
      end if
      if(nllvis.gt.0) then
      plength =len1(line)
      line=line(1:plength)//'LL' 
      plength =len1(line)+1
      line(plength:plength)=', '
      end if
      if(nxxvis.gt.0) then
      plength =len1(line)
      line=line(1:plength)//'XX'
      plength =len1(line)+1
      line(plength:plength)=', '
      end if
      if(nyyvis.gt.0) then
      plength =len1(line)                                                       
      line=line(1:plength)//'YY' 
      plength =len1(line)+1
      line(plength:plength)=', '
      end if
       plength =len1(line)-1   
       call output('Polarisations '
     * //line(1:plength)//' copied to Stokes I')

ccc
        if(npol.gt.maxPol)
     *    call bug('f','Too many polarizations for me to handle')
        if(pol0.le.PolXX)then
          polty = 'XY'
        else if(pol0.le.PolRR)then
          polty = 'RL'
        else
          polty = '  '
        endif
        nVisRef = pols(Pol0)
c
c  Create the output FITS file, and write its header.
c
        Coord(uvCrval,uvStokes) = Pol0
        Coord(uvCdelt,uvStokes) = PolInc
      
        Coord(uvCrpix,uvStokes) = 1
        Coord(uvCrval,uvFreq) = f0
        Coord(uvCdelt,uvFreq) = df
        Coord(uvCrpix,uvFreq) = 1
        Coord(uvCrval,uvRa) = 180.d0/dpi * ras(1)
        Coord(uvCdelt,uvRa) = 1
        Coord(uvCrpix,uvRa) = 1
        Coord(uvCrval,uvDec) = 180.d0/dpi * decs(1)
        Coord(uvCdelt,uvDec) = 1
        Coord(uvCrpix,uvDec) = 1
c
c  Open the FITS file and write out some info. NOTE that a bug in AIPS
c  FITLD requires that the OBJECT keyword be written out as early
c  as possible.
c
        call fuvopen(tOut,out,'new',nVisRef,npol,nchan)
        call fuvSetT0(tOut,T0)
        nparms = 5
        if(nSrc.gt.1)nparms = 6
        call fuvSetPa(tOut,nparms,parms)
        call fuvWrhd(tOut,Coord)
        if(sources(1).ne.' ')call fitwrhda(tOut,'OBJECT',sources(1))
        call fitwrhdd(tOut,'OBSRA', 180.0d0/DPI*pntra)
        call fitwrhdd(tOut,'OBSDEC',180.0d0/DPI*pntdec)
        call fitwrhdr(tOut,'EPOCH',epoch)
c
c  Spectral line and velocity information.
c
        if(.not.dogildas) then
c     works for AIPS
        if(restfreq.gt.0)then
          call fitwrhdd(tOut,'RESTFREQ',restfreq)
          if(velref.gt.0)call fitwrhdi(tOut,'VELREF',velref)
          call fitwrhdr(tOut,'ALTRPIX',1.0)
          call fitwrhdr(tOut,'ALTRVAL',real(v0))
        endif
        else
c    works for gildas
        if(restfreq.gt.0)then
          call fitwrhda(tOut,'LINE', linename) 
          call fitwrhdd(tOut,'RESTFREQ',restfreq)
          call fitwrhdr(tOut,'VLSR', 0.0)
c determine velocity width per channel in optical definition
          fwidth = -CKMS * df / restfreq
          call fitwrhdd(tOut,'DELTAV',fwidth)
        endif
        endif

c
c  Other miscellaneous information.
c
        if(telescop.ne.' ')then
          call fitwrhda(tOut,'TELESCOP',telescop)
          call fitwrhda(tOut,'INSTRUME',telescop)
        endif
        if(observer.ne.' ')call fitwrhda(tOut,'OBSERVER',observer)
        string = 'Miriad '//version
        call fitwrhda(tOut,'ORIGIN',string)
c
c  Copy the history.
c
        if (hdprsnt(tIn,'history ')) then
          call CopyHist(tIn,tOut,version)
        end if
c
c  We now have all the data we want in a scratch file. Copy this
c  data to the output FITS file.
c
        call uvoutWr(tScr,tOut,nvis,nVisRef,npol,nchan,Pol0,PolInc,
     *    nSrc.gt.1)
c
c  Write the source file.
c
        if(nSrc.gt.1)call SrcWrite(tOut,nSrc,sources,
     *    ras,decs,aras,adecs,epoch,restfreq,df,v0)
c
c  Write the antenna file.
c
        if(nants.gt.0)then
          call output('Writing FITS antenna table')
          call AntWrite(tOut,t0,f0,telescop,polty,mount,
     *                  xyz,nants,lat,long,height)
        else
          call bug('w','Insufficent information for antenna table')
        endif
c
c  Everything is done. Close up shop.
c
        call uvdatcls
        call scrclose(tScr)
        call fuvclose(tOut)
c
        end
c************************************************************************
        subroutine SrcUpd(tIn,vSrc,iSrc,ras,decs,aras,adecs,
     *                                          sources,nSrc,MAXSRC)
c
        integer tIn,vSrc,iSrc,nSrc,MAXSRC
        double precision ras(MAXSRC),decs(MAXSRC)
        double precision aras(MAXSRC),adecs(MAXSRC)
        character sources(MAXSRC)*(*)
c
c------------------------------------------------------------------------
        character source*32
        integer i
        double precision ra,dec,dra,ddec
c
c  Externals.
c
        logical uvVarUpd
c
c  Change in source. Get the source name, ra and dec.
c
        if(uvVarUpd(vSrc).or.nSrc.eq.0)then
          call uvrdvra(tIn,'source',source,' ')
          if(len(source).gt.len(sources(1)))
     *      source(len(sources(1))+1:) =  ' '
          call uvrdvrd(tIn,'ra',ra,0.d0)
          call uvrdvrd(tIn,'dec',dec,0.d0)
          call uvrdvrd(tIn,'dra',dra,0.d0)
          call uvrdvrd(tIn,'ddec',ddec,0.d0)
          ra = ra + dra/cos(dec)
          dec = dec + ddec
          iSrc = 0
          i = 1
          dowhile(i.le.nSrc.and.iSrc.eq.0)
            if(ras(i).eq.ra.and.decs(i).eq.dec.and.
     *        sources(i).eq.source)iSrc = i
            i = i + 1
          enddo
c
          if(iSrc.eq.0)then
            nSrc = nSrc + 1
            iSrc= nSrc
            if(nSrc.gt.MAXSRC)call bug('f','Source table overflow')
            sources(iSrc) = source
            ras(iSrc) = ra
            decs(iSrc) = dec
            call uvrdvrd(tIn,'obsra',aras(iSrc),ras(iSrc))
            call uvrdvrd(tIn,'obsdec',adecs(iSrc),decs(iSrc))
          endif
        endif
c
        end
c************************************************************************
        subroutine getarr(tIn,mount,lat,long,height)
c
        implicit none
        integer tIn,mount
        double precision lat,long,height
c------------------------------------------------------------------------
        character telescop*32,type*1
        double precision dval
        integer n
        logical updated,ok
c
c  Determine the telescope.
c
        call uvrdvra(tin,'telescop',telescop,' ')
c
c  Determine the mount.
c
        call uvprobvr(tIn,'mount',type,n,updated)
        ok = n.eq.1
        if(ok)then
          call uvrdvri(tIn,'mount',mount,0)
        else if(telescop.ne.' ')then
          call obspar(telescop,'mount',dval,ok)
          if(ok)mount = nint(dval)
        endif
        if(.not.ok)then
          call bug('w',
     *      'Antenna mount could not be determined -- assuming alt/az')
          mount = 0
        endif
c
c  Determine the latitude.
c
        call uvprobvr(tIn,'latitud',type,n,updated)
        ok = n.eq.1
        if(ok)then
          call uvrdvrd(tIn,'latitud',lat,0.d0)
        else if(telescop.ne.' ')then
          call obspar(telescop,'latitude',lat,ok)
        endif
        if(.not.ok)then
          lat = 0.d0
          call bug('w','Telescope latitude could not be determined')
        endif
c
c  Determine the longitude.
c
        call uvprobvr(tIn,'longitu',type,n,updated)
        ok = n.eq.1
        if(ok)then
          call uvrdvrd(tIn,'longitu',long,0.d0)
        else if(telescop.ne.' ')then
          call obspar(telescop,'longitude',long,ok)
        endif
        if(.not.ok)then
          call bug('w','Telescope longitude could not be determined')
          long = 0.d0
        endif
c
c  Determine the height.
c
        call uvprobvr(tIn,'height',type,n,updated)
        ok = n.eq.1
        if(ok)then
          call uvrdvrd(tIn,'height',height,0.d0)
        else if(telescop.ne.' ')then
          call obspar(telescop,'height',height,ok)
        endif
        if(.not.ok)height = 0.d0
c
        end
c************************************************************************
        subroutine PolCheck(pols,PolMin,PolMax,npol,Pol0,PolInc)
c
        implicit none
        integer PolMin,PolMax,pols(PolMin:PolMax),npol,Pol0,PolInc
c
c  The "pols" array counts the polarizations that were found in the input
c  data. Because FITS can only handle a regular Stokes axis, and because
c  Miriad allows an arbitrary Stokes "dimension", we have to form a regular
c  axis. The rule is to find the commonest polarization, and then to copy
c  "adjacent" polarizations that are at least 70% as common.
c  When a required polarization is missing, we give a dummy (but flagged)
c  value.
c
c  Input:
c    pols       The counts of the polarizations encountered in the
c               input file.
c    PolMin
c    PolMax
c  Output:
c    npol       Number of polarizations to form in the output file.
c    Pol0       The code for the first polarization.
c    PolInc     The code increment between different polarizations. This
c               can be either +1 or -1, having the same sign as Pol0.
c------------------------------------------------------------------------
        integer imax,i,PolMn,PolMx,thresh,p,length
        logical more
        character line*32
c
c  Externals.
c
        character PolsC2P*2
        integer len1
c
c  Determine which polarization type is the most common.
c
        imax = PolMin
        do i=PolMin,PolMax
          if(pols(i).gt.pols(imax).or.
     *      (pols(i).eq.pols(imax).and.abs(i).lt.abs(imax)) ) imax = i
        enddo
c
c  Around the commonest type, find those types that are at least 70% as
c  common. This spans the polarizations that we will choose.
c
        thresh = nint(0.7*pols(imax))
        PolMn = imax
        more = .true.
        dowhile(PolMn-1.ge.PolMin.and.more)
          more = pols(PolMn-1).ge.thresh.and.PolMn-1.ne.0
          if(more) PolMn = PolMn - 1
        enddo
c
        PolMx = imax
        more = .true.
        dowhile(PolMx+1.le.PolMax.and.more)
          more = pols(PolMx+1).ge.thresh.and.PolMx+1.ne.0
          if(more) PolMx = PolMx + 1
        enddo
c
c  Fill in the parameters to describe the choosen polarization.
c
        npol = PolMx - PolMn + 1
        if(PolMx.gt.0)then
          Pol0 = PolMn
          PolInc = 1
        else
          Pol0 = PolMx
          PolInc = -1
        endif
c
c  Give messages about the polarizations that we are copying
c  and those that we are discarding.
c
        length = 0
        p = Pol0
        do i=1,npol
          line(length+1:length+2) = PolsC2P(p)
          length = len1(line(1:length+2)) + 1
c          line(length:length) = ','
           line(length:length) = ' '
          p = p + PolInc
        enddo
c        line(length:length) = '.'
c        call output('Polarisations '
c     * //line(1:length)//' copied to Stokes I')
c
        end
c************************************************************************
        subroutine CopyHist(tIn,tOut,version)
c
        integer tin,tout
        character version*(*)
c
c  Copy out the history comments.
c
c  Input:
c    tIn        The handle of the input MIRIAD file.
c    tOut       The handle of the output FITS file.
c
c------------------------------------------------------------------------
        logical eof
        character card*132,line*80,name*32
        integer narg,i,l1,l2,length,lu,iostat
        logical dofile
        character file*256
        double precision julian
c
c  Externals.
c
        integer iargc,len1
c
        call hisopen(tIn,'read')
        call hisread(tIn,card,eof)
        dowhile(.not.eof)
          line = 'HISTORY '//card(1:72)
          call fitcdio(tOut,line)
          call hisread(tIn,card,eof)
        enddo
        call hisclose(tIn)
c
c  Write some extra FITS history.
c
        narg = iargc()
        name = 'HISTORY FITS:'
        l2 = len(line)
        l1 = len1(name)
        line = name(1:l1)//' Miriad fits: '//version
        call fitcdio(tOut,line)
        call TodayJul(julian)
        call JulDay(julian, 'H', file)
        line = name(1:l1)//' Executed on: '//file(1:len1(file))
        call fitcdio(tOut,line)
        line(l1+1:) = ' Command line inputs follow:'
        call fitcdio(tOut,line)
c
        line(l1+1:l1+4) = ' '
        l1 = l1 + 5
c
        dofile = .false.
        do i=1,narg
          if(dofile)then
            call getarg(i,file)
            call txtopen(lu,file,'old',iostat)
            if(iostat.ne.0)then
              call bug('w','Error opening input parameter file')
              call bugno('w',iostat)
           else
              call txtread(lu,line(l1:l2),length,iostat)
              dowhile(iostat.eq.0)
                length = min(l2,length + l1 - 1)
                call fitcdio(tOut,line(1:length))
                call txtread(lu,line(l1:l2),length,iostat)
              enddo
              call txtclose(lu)
            endif
            dofile = .false.
          else
            call getarg(i,line(l1:l2))
            if(line(l1:l2).eq.'-f')then
              dofile = .true.
            else
              call fitcdio(tOut,line(1:l2))
            endif
          endif
        enddo
c
        line =
     *   'HISTORY FITS: NOTE: Use options=varwt if loading into Miriad'
        call fitcdio(tOut,line)
c
        end
c************************************************************************
        subroutine uvoutWr(tScr,tOut,nvis,nVisRef,npol,nchan,Pol0,
     *  PolInc,doSrc)
c
        integer tScr,tOut,nvis,nVisRef,npol,nchan,Pol0,PolInc
        logical doSrc
c
c  This reads visibilities back from the scratch file, and forms a
c  visibility record the way FITS likes it. That is the visibility
c  consists of 3*npol*nfreq bits of data. This is unlike Miriad in that
c  the polarization axis is in with the frequency axis.
c
c  Inputs:
c    tScr       Handle of the scratch file.
c    tOut       Handle of the output FITS file.
c    nvis       Number of visibilities in the scratch file.
c    nVisRef    Number of visibilities that will be written to the output
c               FITS file.
c    npol       The dimension of the Stokes axis in the output file.
c    nchan      The number of frequency channels in the output file.
c    Pol0       The code of the first polarization.
c    PolInc     The increment between polarizations.
c    doSrc      True if we should write the source number.
c------------------------------------------------------------------------
c  Records are copied or discarded according to whether the reference
c  polarization is present or not. If not, the record is discarded. Currently
c  the reference polarization is always the first polarization, but this may
c  change in the future.
c
        include 'maxdim.h'
        integer maxPol,RefPol,PolMin,PolMax
        parameter(RefPol=1,PolMin=-8,PolMax=4,maxPol=4)
        integer uvU,uvV,uvW,uvBl,uvT,uvSrc,uvRandom,uvData
        parameter(uvU=1,uvV=2,uvW=3,uvBl=4,uvT=5,uvSrc=6,uvRandom=6)
        parameter(uvData=uvRandom+1)
c
        integer pols(PolMin:PolMax),discard(PolMin:PolMax),pnt(maxPol)
        integer ncopy,totcopy,l,l2,InPnt,OutPnt,Bl,P,iP,i,j,jd,k,length
        integer iSrc
        logical copied(maxPol)
        character num*8,num2*8
        real In(uvRandom+1+3*maxchan),Out(uvRandom+3*maxPol*maxchan)
        real Time,wt
c
c  Externals.
c
        character itoaf*8,PolsC2P*2
        integer len1
c
c  Check! These should have been done before, somewhere or other.
c
        if(nchan.gt.maxchan.or.npol.gt.maxpol)
     *    call bug('f','Too many channels, or too many polarizations')
c
c  Form a table to help sort out which polarizations to keep, and where
c  to put them in the output record. Also initialise an array of counters
c  to determine the number of visibilities that are being discarded.
c
        do i=PolMin,PolMax
          pols(i) = 0
          discard(i) = 0
        enddo
c
c  Initialise some tables to help me keep track of things. They allow
c  determination of the polarization code, from the number 1..nPol, and
c  visa versa.
c
        i = Pol0
        do j=1,npol
          copied(j) = .false.
          pnt(j) = i
          pols(i) = j
          i = i + PolInc
        enddo
c
        length = uvRandom + 1 + 3*nchan
        ncopy = 0
        totcopy = 0
        Time = 0
        Bl = 0
        iSrc = 0
        jd = 0
        wt = 0
c
        do j=1,nvis
          call scrread(tScr,In,(j-1)*length,length)
          P = nint(In(1))
          iP = pols(P)
c
c  Handle the case of a polarization that we are not handling, or the
c  case where we have only one polarization to handle.
c
          if(iP.eq.0)then
            discard(P) = discard(P) + 1
          else if(npol.eq.1)then
            jd = jd + 1
            totcopy = totcopy + 1
            if(doSrc)then
              call fuvwrite(tOut,in(2),jd,1)
            else
              in(7) = in(6)
              in(6) = in(5)
              in(5) = in(4)
              in(4) = in(3)
              in(3) = in(2)
              call fuvwrite(tOut,in(3),jd,1)
            endif
          else
c
c  We have a good polarization, and we are handling more than 1 polarizations.
c  If it does not match with the pervious record, then we have to rid
c  ourselves of the previous record.
c
c  If the "reference" polarization is not present, discard the previous record.
c  If the "reference" polarization is present, blnak out any channels which
c  are missing data, and finally write out the previous good record.
c
            if(nint(In(uvBl+1)).ne.Bl.or.In(uvT+1).ne.Time.or.
     *         nint(In(uvSrc+1)).ne.iSrc.or.
     *         (copied(RefPol).and.copied(iP)))then
              if(.not.copied(RefPol))then
                do i=1,npol
                  if(copied(i)) discard(pnt(i)) = discard(pnt(i)) + 1
                enddo
              else
                if(ncopy.lt.npol)call ZeroOut(copied,npol,nchan,out,wt)
                jd = jd + 1
                totcopy = totcopy + ncopy
                call fuvwrite(tOut,Out,jd,1)
              endif
c
c  We have a new record. Ready ourselves for it.
c
              do i=1,npol
                copied(i) = .false.
              enddo
              ncopy = 0
              Out(uvU) = In(uvU+1)
              Out(uvV) = In(uvV+1)
              Out(uvW) = In(uvW+1)
              Out(uvT) = In(uvT+1)
              Out(uvBl) = In(uvBl+1)
              Out(uvSrc) = In(uvSrc+1)
              Bl = nint(In(uvBl+1))
              Time = In(uvT+1)
              iSrc = nint(In(uvSrc+1))
              Wt = abs(In(uvData+3))
            endif
c
c  We have to add visibilities to the currently existing record.
c
            InPnt = uvData
            OutPnt = uvRandom - 1 + 3*(iP-1)
            if(doSrc)OutPnt = OutPnt + 1
            do k=1,nchan
              out(OutPnt+1) = in(InPnt+1)
              out(OutPnt+2) = in(InPnt+2)
              out(OutPnt+3) = in(InPnt+3)
              InPnt = InPnt + 3
              OutPnt = OutPnt + 3*npol
            enddo
            ncopy = ncopy + 1
            copied(iP) = .true.
          endif
        enddo
c
c  We have more or less finished. One record could still be buffered up.
c  Either discard it or write it, depending whether the reference
c  polarization is present.
c
          if(.not.copied(RefPol))then
            do i=1,npol
              if(copied(i)) discard(pnt(i)) = discard(pnt(i)) + 1
            enddo
          else
            if(ncopy.lt.npol)call ZeroOut(copied,npol,nchan,out,wt)
            jd = jd + 1
           totcopy = totcopy + ncopy
            call fuvwrite(tOut,Out,jd,1)
          endif
c
c  Generate messages about the number of visibilities copied and not copied.
c
        if(jd.ne.nVisRef)
     *    call bug('f','Internal inconsistency, in uvout(write)')
        num = itoaf(totcopy)
        l = len1(num)
        num2 = itoaf(nVisRef)
        l2 = len1(num2)
        call output(num(1:l)//' visibilities copied to '//num2(1:l2)//
     *          ' output records.')
c
        do i=PolMin,PolMax
          if(discard(i).ne.0) then
            num = itoaf(discard(i))
            l = len1(num)
            call bug('w','Discarded '//num(1:l)//
     *          ' visibilities of type '//PolsC2P(i))
          endif
        enddo
c
        end
c************************************************************************
        subroutine SrcWrite(tOut,nSrc,sources,ras,decs,aras,adecs,epoch,
     *    restfreq,df,v0)
c
        implicit none
        integer tOut,nSrc
        double precision ras(nSrc),decs(nSrc),aras(nSrc),adecs(nSrc)
        double precision restfreq,df,v0
        character sources(nSrc)*(*)
        real epoch
c
c------------------------------------------------------------------------
        include 'mirconst.h'
        integer i
c
        call ftabdini(tOut,'AIPS SU')
        call ftabdef(tOut,'ID. NO.',  'I',' ',      nSrc,1)
        call ftabdef(tOut,'SOURCE',   'A',' ',      nSrc,
     *                                          len(sources(1)))
        call ftabdef(tOut,'QUAL',     'I',' ',      nSrc,1)
        call ftabdef(tOut,'CALCODE',  'A',' ',      nSrc,4)
        call ftabdef(tOut,'IFLUX',    'R','JY',     nSrc,1)
        call ftabdef(tOut,'QFLUX',    'R','JY',     nSrc,1)
        call ftabdef(tOut,'UFLUX',    'R','JY',     nSrc,1)
        call ftabdef(tOut,'VFLUX',    'R','JY',     nSrc,1)
        call ftabdef(tOut,'FREQOFF',  'D','HZ',     nSrc,1)
        call ftabdef(tOut,'BANDWIDTH','D','HZ',     nSrc,1)
        call ftabdef(tOut,'RAEPO',    'D','DEGREES',nSrc,1)
        call ftabdef(tOut,'DECEPO',   'D','DEGREES',nSrc,1)
        call ftabdef(tOut,'EPOCH',    'D','YEARS',  nSrc,1)
        call ftabdef(tOut,'RAAPP',    'D','DEGREES',nSrc,1)
        call ftabdef(tOut,'DECAPP',   'D','DEGREES',nSrc,1)
        call ftabdef(tOut,'LSRVEL',   'D','M/SEC',  nSrc,1)
        call ftabdef(tOut,'RESTFREQ', 'D','HZ',     nSrc,1)
        call ftabdef(tOut,'PMRA',     'D','DEG/DAY',nSrc,1)
        call ftabdef(tOut,'PMDEC',    'D','DEG/DAY',nSrc,1)
        call ftabdfin(tOut)
c
        call fitwrhdi(tOut,'NO_IF',1)
        call fitwrhda(tOut,'VELTYP','OBS')
        call fitwrhda(tOut,'VELDEF','RADIO')
c
        do i=1,nSrc
          call ftabputi(tOut,'ID. NO.',  i,i)
          call ftabputa(tOut,'SOURCE',   i,sources(i))
          call ftabputi(tOut,'QUAL',     i,0)
          call ftabputa(tOut,'CALCODE',  i,'    ')
          call ftabputr(tOut,'IFLUX',    i,0.0)
          call ftabputr(tOut,'QFLUX',    i,0.0)
          call ftabputr(tOut,'UFLUX',    i,0.0)
          call ftabputr(tOut,'VFLUX',    i,0.0)
          call ftabputd(tOut,'FREQOFF',  i,0.d0)
          call ftabputd(tOut,'BANDWIDTH',i,df)
          call ftabputd(tOut,'RAEPO',    i,180.d0/DPI*ras(i))
          call ftabputd(tOut,'DECEPO',   i,180.d0/DPI*decs(i))
          call ftabputd(tOut,'EPOCH',    i,dble(epoch))
          call ftabputd(tOut,'RAAPP',    i,180.d0/DPI*aras(i))
          call ftabputd(tOut,'DECAPP',   i,180.d0/DPI*adecs(i))
          call ftabputd(tOut,'LSRVEL',   i,v0)
          call ftabputd(tOut,'RESTFREQ', i,restfreq)
          call ftabputd(tOut,'PMRA',     i,0.d0)
          call ftabputd(tOut,'PMDEC',    i,0.d0)
        enddo
c
        end
c************************************************************************
        subroutine AntWrite(tOut,rtime,rfreq,telescop,polty,mount,
     *                  xyz,nants,lat,long,height)
c
        implicit none
        integer tOut,nants,mount
        double precision rtime,rfreq
        double precision xyz(nants,3),lat,long,height
        character telescop*(*),polty*(*)
c
c  Write an antenna table into the output.
c------------------------------------------------------------------------
        include 'mirconst.h'
c
        real zero(3)
        character anname*8,rdate*32
        double precision iatutc,gstia0,gstia1,degpdy,xyzd(3)
        integer i
c
c  Externals.
c
        character itoaf*4
        double precision deltime,eqeq
c
        call ftabdini(tOut,'AIPS AN')
        call ftabdef(tOut,'ANNAME', 'A',' ',      nants,len(anname))
        call ftabdef(tOut,'STABXYZ','D','METERS', nants,3)
        call ftabdef(tOut,'ORBPARM','D',' ',      nants,0)
        call ftabdef(tOut,'NOSTA',  'I',' ',      nants,1)
        call ftabdef(tOut,'MNTSTA', 'I',' ',      nants,1)
        call ftabdef(tOut,'STAXOF', 'R','METERS', nants,1)
        call ftabdef(tOut,'POLTYA', 'A',' ',      nants,1)
        call ftabdef(tOut,'POLAA',  'R','DEGREES',nants,1)
        call ftabdef(tOut,'POLCALA','R',' ',      nants,3)
        call ftabdef(tOut,'POLTYB', 'A',' ',      nants,1)
        call ftabdef(tOut,'POLAB',  'R','DEGREES',nants,1)
        call ftabdef(tOut,'POLCALB','R',' ',      nants,3)
        call ftabdfin(tOut)
c
c  Determine various things to do with time.
c
        iatutc = deltime(rtime,'tai')
        call jullst(rtime-iatutc,0.d0,gstia0)
        gstia0 = 180d0/DPI * (gstia0 + eqeq(rtime-iatutc))
        if(gstia0.lt.0)  gstia0 = gstia0 + 360
        if(gstia0.ge.360)gstia0 = gstia0 - 360
        call jullst(rtime-iatutc+1.d0,0.d0,gstia1)
        gstia1 = 180d0/DPI * (gstia1 + eqeq(rtime-iatutc+1.d0))
        if(gstia1.lt.0)  gstia1 = gstia1 + 360
        if(gstia1.ge.360)gstia1 = gstia1 - 360
        degpdy = gstia1 - gstia0 + 360
        if(degpdy.lt.360)degpdy = degpdy + 360
c
c  Fill out information in the antenna table header.
c
        call llh2xyz(lat,long,height,xyzd(1),xyzd(2),xyzd(3))
        call fitwrhdd(tOut,'ARRAYX',xyzd(1))
        call fitwrhdd(tOut,'ARRAYY',xyzd(2))
        call fitwrhdd(tOut,'ARRAYZ',xyzd(3))
        call fitwrhdd(tOut,'GSTIA0',gstia0)
        call fitwrhdd(tOut,'DEGPDY',degpdy)
        call fitwrhdd(tOut,'FREQ',  rfreq)
        call julday(rtime,'T',rdate)
        call fitwrhda(tOut,'RDATE',rdate)
        call fitwrhdd(tOut,'POLARX',0.d0)
        call fitwrhdd(tOut,'POLARY',0.d0)
        call fitwrhdd(tOut,'UT1UTC',0.d0)
        call fitwrhdd(tOut,'DATUTC',0.d0)
        call fitwrhda(tOut,'TIMSYS','UTC')
        call fitwrhda(tOut,'ARRNAM',telescop)
        call fitwrhdi(tOut,'NUMORB',0)
        call fitwrhdi(tOut,'NOPCAL',3)
        call fitwrhdi(tOut,'FREQID',-1)
        call fitwrhdd(tOut,'IATUTC',86400d0*iatutc)
c
c  Zero out the unused fields.
c
        zero(1) = 0
        zero(2) = 0
        zero(3) = 0
        do i=1,nants
          anname = 'ANT'//itoaf(i)
          call ftabputa(tOut,'ANNAME', i,anname)
          xyzd(1) = DCMKS*1d-9*xyz(i,1)
          xyzd(2) = DCMKS*1d-9*xyz(i,2)
          xyzd(3) = DCMKS*1d-9*xyz(i,3)
          call ftabputd(tOut,'STABXYZ',i,xyzd)
          call ftabputi(tOut,'NOSTA',  i,i)
          call ftabputi(tOut,'MNTSTA', i,mount)
          call ftabputr(tOut,'STAXOF', i,0.0)
          call ftabputa(tOut,'POLTYA', i,polty(1:1))
          if (telescop.eq.'ATCA') then
             call ftabputr(tOut,'POLAA',  i, 45.0)
             call ftabputr(tOut,'POLAB',  i, 135.0)
          else
             call ftabputr(tOut,'POLAA',  i, 0.0)
             call ftabputr(tOut,'POLAB',  i, 0.0)
          end if
          call ftabputr(tOut,'POLCALA',i,zero)
          call ftabputa(tOut,'POLTYB', i,polty(2:2))

          call ftabputr(tOut,'POLCALB',i,zero)
        enddo
c
        end
c************************************************************************
        subroutine ZeroOut(copied,npol,nchan,out,wt)
c
        implicit none
        integer npol,nchan
        logical copied(npol)
        real out(5+3*npol*nchan),wt
c
c  This blanks out any polarizations that have not truely been copied.
c  It does this by setting the correlation value to zero, and the weight
c  to indicate bad data.
c
c  Inputs:
c    copied     Logical array indicating if a particular polarization has
c               been copied.
c    wt         The weight to associate with the blanked out data.
c    npol       Number of polarizations.
c    nchan      Number of channels.
c  Input/Output:
c    out        The visibility record (FITS style). Missing polarizations
c               are blanked out.
c------------------------------------------------------------------------
c------------------------------------------------------------------------
        integer i,OutPnt,k
c
        do i=1,npol
          if(.not.copied(i))then
            OutPnt = 5 + 3*(i-1)
            do k=1,nchan
              out(OutPnt+1) = 0
              out(OutPnt+2) = 0
              out(OutPnt+3) = -wt
              OutPnt = OutPnt + 3*npol
            enddo
          endif
        enddo
        end

