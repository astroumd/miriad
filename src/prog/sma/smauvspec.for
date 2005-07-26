c************************************************************************
        program smauvspec
c
c= smauvspec - Plot averaged spectra of a visibility dataset.
c& jhz for SMA 
c: uv analysis
c+
c	SmaUVSPEC plots averaged spectra of a visibility dataset. Averaging can
c	be in both time and frequency
c@ vis
c	The name of the input uv data sets. Several can be given (wild
c	cards are supported). No default.
c@ select
c	The normal uv selection commands. The default is plot everything.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels).
c@ stokes
c	The Stokes/polarization types to be plotted. The default is to
c	plot those polarizations present in the input files.
c@ interval
c	Time averaging interval, in minutes. The default is 0 (i.e. no
c	averaging).
c@ hann
c	Hanning smoothing width (an odd integer).  Smoothing is
c	applied after averaging. Default is 1 (no Hanning smoothing).
c@ offset
c	An offset (in arcsec) to shift the data. Positive values result in
c	the data center being shifted to the North and East. Two values
c	should be given, being the shift in the RA and DEC directions.
c	The default is 0,0 (i.e. no shift).
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreviated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'nocal'       Do not apply the gains file. By default, SmaUVSPEC
c	                 applies the gains file in copying the data.
c	   'nopass'      Do not apply bandpass corrections. By default,
c	                 SmaUVSPEC corrects for the bandpass shape if the
c	                 required information is available.
c	   'nopol'       Do not apply polarizatiopn corrections. By default
c	                 SmaUVSPEC corrects for polarization corss-talk.
c	   'ampscalar'   When plotting amplitude, this causes it to perform
c	                 scalar averaging. By default it does vector averaging.
c	   'rms'         When plotting amplitude, this causes it to plot
c		         the rms amplitude. by default it does vector averaging.
c	   'nobase'      Plot all the baselines on one plot.
c	   'avall'       Average all the baselines together before plotting.
c	   'dots'        Plot phases with dots instead of filled circles.
c	   'flagged'     Plot flagged data instead of unflagged data. The
c	                 default is to plot only unflagged data.
c	   'all'         Plot both flagged and unflagged data.
c          'jplcat'      Plot JPL catalog lines. The xaxis and yaxis are
c                        then forced to be frequency and ampltiude.
c@ catpath
c       This gives the path of JPL catalog. No Default. In general, 
c       the path of JPL catalog are: $MIRCAT/jpl/; otherwise, it can
c       be specified by users.
c
c@ lsrvel  
c       This gives the system velocity n km/s with respect to LSR to shift the 
c       catalog lines. The default is 0.
c
c@ veldef  
c       This is the velocity definition used in the shift of the catalog lines.
c          radio         is the radio definition.
c          optical       is the optical definion.
c       The default is "radio".
c          
c@ axis
c	This gives two strings, which determine the X and Y axes of each plot.
c	The values can be abbreviated to uniqueness.
c	Possible values for the X axis are:
c	   channel       X-axis is channel number.
c	   frequency     X-axis is the sky frequency, in GHz.
c	   dfrequency    X-axis is the Doppler-corrected frequency, in GHz.
c	   velocity      X-axis is velocity in radio convention, in km/sec.
c	   felocity	 X-axis is velocity in optical convention, in km/sec.
c	   lag           X-axis is lag number.
c	Possible values for the Y axis are:
c	   amplitude     Plot amplitude.
c	   phase         Plot phase.
c	   real          Plot real part of the data.
c	   imaginary     Plot imaginary part of the data.
c          both          Plot both amplitude and phase.
c	The default is axis=channel,amplitude.
c@ yrange
c	The min and max range along the y axis of the plots. The default
c	is to autoscale.
c       Note: in the case of yaxis=both, the range is specified by the 
c             yrange to the variable amplitude. The phase is plotted below 
c             the amplitude in the bottom panel with the range from -180 to 
c             180 degree. 
c@ device
c	PGPLOT plot device/type. No default.
c@ nxy
c	Number of plots in the x and y directions. The default is
c	determined from the number of antennae in the data-sets.
c@ log
c	Log file into which the spectra are dumped in the order in which
c	they are plotted.  Really only useful if your plot is quite simple.
c--
c  History:
c    rjs  18sep92 Derived from uvaver.
c    nebk 22sep92 OPTIONS=DOTS
c    rjs  21oct92 Better title. Bug dealing with number of points in a plot.
c    nebk 28oct92 Add HAnning smoothing
c    mjs  13mar93 pgplot subr names have less than 7 chars.
c    rjs  17mar93 Different colours for different plots.
c    rjs  19mar93 I did not understand the "gap" arg to pghline!
c    rjs  18aug93 Improve labelling.
c    rjs  24aug93 Added shift option.
c    nebk 05sep93 Added log option
c    rjs  22sep93 Rms averaging option.
c    rjs  23dec93 Added 'felocity' axis (velocity using optical definition).
c    rjs   8mar94 Handle data which are not in time order.
c    nebk 22mar94 Add options=flagged
c    rjs  17aug94 Better offset handling.
c    rjs  26sep95 Discard bad spectra as soon as possible.
c    rjs  28sep95 Fix bug I introduced two days ago.
c    rjs  17oct95 Correct initialisation bug when first integration is all
c		  bad.
c    rjs  19oct95 options=all
c    rjs  16nov95 Use different colours and PGRNGE.
c    rjs  14dec95 Increase buffer in averaging (MAXAVER).
c    rjs  19aug97 Added axis=lag
c    rjs  31oct97 Use colours in the label.
c    rjs   3dec97 Replace part of label that dropped off in above change.
c    rjs  13sep99 Added Doppler corrected freq to possibilities to plot.
c    jhz  13Jul04 extended for SMA.
c    jhz  14Jul04 add color index coded for spectral windows.
c    jhz  10oct04 corect for the error in source labelling.
c    jhz  13oct04 add bothA&P to axis.
c    jhz  10dec04 fold smauvspec back to MIRIAD4.0.4 
c    jhz  15dec04 added the jpl line catalog 
c    jhz  22jun05 fixed problem of chunk boundary allowing
c                 edge flag.
c    jhz  23jun05 enable phase plot
c    jhz  21jul05 fixed a bug in pghline which cause draw a
c                 random lin at end of the line drawing. 
c    jhz  24jul05 add back the do both amplitude and phase
c    jhz  26jul05 label the phase panel for the case of
c                 plotting both amplitude and phase.
c>  Bugs:
c------------------------------------------------------------------------
c=======================================================================
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c ----------------------------------------------------------------------
c  Speed of light (meters/second).
      real cmks
      double precision dcmks
      parameter (cmks = 299792458.0)
      parameter (dcmks = 299792458.0)
c ----------------------------------------------------------------------
c  Boltzmann constant (Joules/Kelvin).
      real kmks
      double precision dkmks
      parameter (kmks = 1.380658e-23)
      parameter (dkmks = 1.380658d-23)
c ----------------------------------------------------------------------
c  Planck constant (Joules-second).
      real hmks
      double precision dhmks
      parameter (hmks = 6.6260755e-34)
      parameter (dhmks = 6.6260755d-34)
c ----------------------------------------------------------------------
c  Planck constant divided by Boltzmann constant (Kelvin/GHz).
      real hoverk
      double precision dhoverk
      parameter (hoverk = 0.04799216)
      parameter (dhoverk = 0.04799216)
c=======================================================================
        include 'maxdim.h'
        integer maxco
        parameter (maxco=15)
c
c catalog
c 
        parameter (maxmline=500)
        character mname*8000, moln*16
        integer mtag(maxmline), nmline, j, jp, js, je, iline
        character version*(*)
        parameter(version='SmaUvSpec: version 1.6 26-Jul-05')
        character uvflags*8,device*64,xaxis*12,yaxis*12,logf*64
        character xtitle*64,ytitle*64, veldef*8
        logical ampsc,rms,nobase,avall,first,buffered,doflush,dodots
        logical doshift,doflag,doall,dolag,docat
        double precision interval,t0,t1,preamble(4),shift(2),shft(2)
        integer tin,vupd
        integer nxy(2),nchan,nread,nplot
        real yrange(2),inttime, lsrvel, veldop
        double precision x(2*maxchan-2)
        complex data(maxchan)
        logical flags(maxchan)
        integer hann, pathlen
        real hc(maxco),hw(maxco)
        character in(1)*64
	character source*32
c
c  Externals.
c
        integer nextpow2
        logical uvdatopn,uvvarupd
c
c common jpl
c
        
        integer nmol, moltag(maxmline)
        character molname(maxmline)*16, jplpath*80 
        common/jplcat/nmol,moltag,molname,docat,lsrvel,veldef,veldop
        logical docolor
        integer nspect, nschan(maxwin),nchan0
        common/spectrum/nspect,nschan,nchan0,docolor



c
c  Get the input parameters.
c
        call output(version)
        docolor=.true.
        call keyini
        call mkeyf('vis',in,1,nin)
        call vishd(in)
        call keyini
        call getopt(uvflags,ampsc,rms,nobase,avall,dodots,doflag,doall,
     &          docat)
        call keya('catpath', jplpath, ' ')
        call keyr('lsrvel', lsrvel, 0.0)
        call keya('veldef', veldef, 'radio')
         if((veldef(1:1).eq."O").or.(veldef(1:1).eq."o")) then
                veldef = 'optical'
                  else
                veldef = 'radio'
              end if
        call getaxis(xaxis,yaxis)
        if(docat) 
     & call bug('f','has not fully implemented yet for jpl catalog.')
        dolag = xaxis.eq.'lag'
        call uvdatinp('vis',uvflags)
        call keyd('interval',interval,0.d0)
        call keyi('hann',hann,1)
        call keya('device',device,' ')
        call keyi('nxy',nxy(1),0)
        call keyi('nxy',nxy(2),0)
        call keyd('offset',shift(1),0.d0)
        call keyd('offset',shift(2),0.d0)
        call keyr('yrange',yrange(1),0.)
        call keyr('yrange',yrange(2),yrange(1)-1)
        call keya('log',logf,' ')
        call keyfin
c
c select molecular species
c 
         if(docat) then
         if(jplpath(1:1).eq." ") 
     &   call bug('f','Zero length of keyword catpath.')
         pathlen=1
         do while (jplpath(pathlen:pathlen).ne." ")
         pathlen=pathlen+1
         end do
         pathlen=pathlen-1
         if(jplpath(pathlen:pathlen).ne."/") then
            jplpath=jplpath(1:pathlen)//'/'
            pathlen=pathlen+1
            end if
         xaxis='frequency'
         yaxis='amplitude'

         call molselect(jplpath,pathlen,mtag,nmline,mname)
                   jp=1
                   iline=0 
                   do while(iline.lt.nmline)
                   js=jp
                   j=1
                   do while((mname(jp:jp).ne."\n").and.(j.lt.16))
                       jp=jp+1
                       j=j+1
                   end do
                   je=jp
                   moln=mname(js:je)
                   iline=iline+1
                   jp=jp+1
                   moltag(iline)=mtag(iline)
                   molname(iline)=moln
                   end do
               nmol= nmline
c
c  check
c
c               do i=1, nmol
c               write(*,*) "moltag", moltag(i)," molname   ", molname(i) 
c               end do
                    end if
c
c  Check the input parameters.
c
        if(interval.lt.0)call bug('f','Illegal value for interval')
        if((ampsc.or.rms).and.yaxis.ne.'amplitude')
     *    call bug('w','Amplitude averaging option ignored')
        if(avall.and..not.nobase)
     *    call bug('w','Option NOBASE being used because of AVALL')
        nobase = nobase.or.avall
        if (hann.lt.1 .or. hann.gt.maxco) call bug('f',
     *    'Illegal Hanning smoothing width')
c
c  Convert the shifts, and determine whether a shift is to be performed.
c
        shift(1) = pi/180/3600 * shift(1)
        shift(2) = pi/180/3600 * shift(2)
        doshift = abs(shift(1))+abs(shift(2)).gt.0
c
c  Various initialisation.
c
        ytitle = yaxis
        if(ytitle.eq.'both') ytitle='BothA&P'
        call ucase(ytitle(1:1))
        interval = interval/(24.*60.)
        doflush = .false.
        buffered = .false.
        first = .true.
        call bufini
        if(hann.gt.1) call hcoeffs(hann,hc)
        if(logf.ne.' ') call logopen(logf,' ')
c
c  Open the input file(s).
c
        dowhile(uvdatopn(tin))
c
c No comment.
c
          call uvvarini(tin,vupd)
          call uvvarset(vupd,'dra')
          call uvvarset(vupd,'ddec')
          call uvvarset(vupd,'source')
          call uvvarset(vupd,'nchan')
           
c
c  Loop over the data.
c
          
          call uvdatrd(preamble,data,flags,maxchan,nread)
           
          if((nread.lt.nchan0).and.docolor) docolor = .false.
          nplot = nread
          if(dolag)nplot = nextpow2(2*(nread-1))
          if(doshift)then
            call coinit(tin)
            call cocvt(tin,'ow/ow',shift,'op/op',shft)
            call cofin(tin)
          endif
          nchan = nread
          t1 = preamble(3)
          t0 = t1
          dowhile(nread.gt.0)
c
c  Shift the data if needed.
c
            if(doshift)call shiftit(tin,preamble,data,nchan,shft)
c
c  Determine if we need to flush out the averaged data.
c
            doflush = uvvarupd(vupd)
            doflush = nread.ne.nchan
            t0 = min(preamble(3),t0)
            t1 = max(preamble(3),t1)
            doflush = (doflush.or.t1-t0.gt.interval).and.buffered
c
c  Pull the chain and flush out and plot the accumulated data
c  in the case of time averaging.
c
         if(doflush)then
       call bufflush(source,ampsc,rms,nobase,dodots,hann,hc,hw,first,
     *          device,x,nplot,xtitle,ytitle,nxy,yrange,logf)
              t0 = preamble(3)
              t1 = t0
              buffered = .false.
            endif
c
c  Accumulate more data, if we are time averaging.
c
            if(.not.buffered)call getxaxis(tin,xaxis,xtitle,x,nplot)
            if(avall)preamble(4) = 257
            call uvrdvrr(tin,'inttime',inttime,0.)
            call bufacc(doflag,doall,preamble,inttime,data,flags,nread)
            buffered = .true.
            nchan = nread
c
c  Keep on going. Read in another record.
c
            call uvgetvra(tin,'source',source)
            call uvgetvrr(tin,'veldop',veldop,1)
            call uvdatrd(preamble,data,flags,maxchan,nread)
          enddo
c
c  Flush out and plot anything remaining.
c
          if(buffered)then
         call bufflush(source,ampsc,rms,nobase,dodots,hann,hc,hw,first,
     *        device,x,nplot,xtitle,ytitle,nxy,yrange,logf)
            buffered = .false.
          endif
          call uvdatcls
        enddo
c
        if(first)call bug('f','Nothing to plot')
        if(logf.ne.' ') call logclose
        call pgend
        end
c************************************************************************
        subroutine shiftit(tin,uv,data,nchan,shift)
c
        integer tin,nchan
        double precision uv(2)
        double precision shift(2)
        complex data(nchan)
c
c  Shift the data.
c
c------------------------------------------------------------------------
       include 'maxdim.h'
c=======================================================================
c - mirconst.h  Include file for various fundamental physical constants.
c
c  History:
c    jm  18dec90  Original code.  Constants taken from the paper
c                 "The Fundamental Physical Constants" by E. Richard
c                 Cohen and Barry N. Taylor (PHYICS TODAY, August 1989).
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c ----------------------------------------------------------------------
c  Speed of light (meters/second).
      real cmks
      double precision dcmks
      parameter (cmks = 299792458.0)
      parameter (dcmks = 299792458.0)
c ----------------------------------------------------------------------
c  Boltzmann constant (Joules/Kelvin).
      real kmks
      double precision dkmks
      parameter (kmks = 1.380658e-23)
      parameter (dkmks = 1.380658d-23)
c ----------------------------------------------------------------------
c  Planck constant (Joules-second).
      real hmks
      double precision dhmks
      parameter (hmks = 6.6260755e-34)
      parameter (dhmks = 6.6260755d-34)
c ----------------------------------------------------------------------
c  Planck constant divided by Boltzmann constant (Kelvin/GHz).
      real hoverk
      double precision dhoverk
      parameter (hoverk = 0.04799216)
      parameter (dhoverk = 0.04799216)
c=======================================================================
        double precision sfreq(maxchan)
        real theta,theta0
        complex w
        integer i
c
c  Get the sky frequency.
c
        call uvinfo(tin,'sfreq',sfreq)
c
c  Shift the data.
c
        theta0 = -2*pi * (uv(1)*shift(1) + uv(2)*shift(2))
        do i=1,nchan
          theta = theta0 * sfreq(i)
          w = cmplx(cos(theta),sin(theta))
          data(i) = w * data(i)
        enddo
c
        end
c************************************************************************
        subroutine getxaxis(tin,xaxis,xtitle,x,nchan)
c
        integer tin,nchan
        character xaxis*(*),xtitle*(*)
        double precision x(nchan)
c
c  Determine the X axis coordinates for each channel.
c
c  Input:
c    tIn
c    xaxis
c    nchan
c  Output:
c    x
c------------------------------------------------------------------------
        integer velo
        parameter(velo=3)
c
        integer i,i0
        double precision data(6),start,step
        character vel*32
c
c  Externals.
c
        integer len1
c
        if(xaxis.eq.'channel')then
          call uvinfo(tin,'line',data)
          
          start = data(3)
          if(nint(data(1)).ne.velo)start = start + 0.5*(data(4)-1)
          step = data(5)
          do i=1,nchan
            x(i) = start + (i-1)*step
          enddo
          if(nint(data(1)).eq.velo)then
            call velsys(tin,vel,'radio')
            xtitle = 'Velocity Channels('//vel(1:len1(vel))//') (km/s)'
          else
            xtitle = 'Channels'
          endif
        else if(xaxis.eq.'velocity')then
          call velsys(tin,vel,'radio')
          xtitle = 'Velocity('//vel(1:len1(vel))//') (km/s)'
          call uvinfo(tin,'velocity',x)
        else if(xaxis.eq.'felocity')then
          call velsys(tin,vel,'optical')
          xtitle = 'Velocity('//vel(1:len1(vel))//') (km/s)'
          call uvinfo(tin,'felocity',x)
        else if(xaxis.eq.'frequency')then
          xtitle = 'Frequency (GHz)'
          call uvinfo(tin,'sfreq',x)
        else if(xaxis.eq.'dfrequency')then
          xtitle = 'Doppler-Corrected Frequency (GHz)'
          call uvinfo(tin,'frequency',x)
        else if(xaxis.eq.'lag')then
          i0 = -nchan/2
          do i=1,nchan
            x(i) = i0
            i0 = i0 + 1
          enddo
          xtitle = 'Lag Number'
        else
          call bug('f','Unrecognised xaxis')
        endif
        end
c************************************************************************
        subroutine velsys(tin,vel,type)
c
        integer tin
        character vel*(*),type*(*)
c
c------------------------------------------------------------------------
        character veltype*32
c
        call uvrdvra(tin,'veltype',veltype,'VELO-LSR')
        if(veltype(6:8).eq.'LSR')then
          vel = type//',LSR'
        else if(veltype(6:8).eq.'HEL')then
          vel = type//',Barycentric'
        else if(veltype(6:8).eq.'OBS')then
          vel = type//',Topocentric'
        else
          vel = type//',unknown'
        endif
        end
c************************************************************************
        subroutine getaxis(xaxis,yaxis)
c
        character xaxis*(*),yaxis*(*)
c
c  Determine the X and Y axis to plot.
c
c  Output:
c    xaxis
c    yaxis
c------------------------------------------------------------------------
        integer nx,ny
        parameter(nx=6,ny=5)
c
        integer n
        character xaxes(nx)*10,yaxes(ny)*9
        data xaxes/'channel   ','frequency ','velocity  ','felocity  ',
     *             'lag       ','dfrequency'/
        data yaxes/'amplitude','phase    ','real     ','imaginary',
     *             'both'/
c
        call keymatch('axis',nx,xaxes,1,xaxis,n)
        if(n.eq.0)xaxis = xaxes(1)
        call keymatch('axis',ny,yaxes,1,yaxis,n)
        if(n.eq.0)yaxis = yaxes(1)
        end
c************************************************************************
        subroutine getopt(uvflags,ampsc,rms,nobase,avall,dodots,
     *          doflag,doall,docat)
c
        logical ampsc,rms,nobase,avall,dodots,doflag,doall,docat
        character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c    ampsc      True for amp-scalar averaging.
c    rms	True for amp-rms averaging.
c    nobase
c    avall
c    dodots
c    doflag
c    doall
c    dojplcat
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=11)
        character opts(nopts)*9
        logical present(nopts),docal,dopol,dopass
        data opts/'nocal    ','nopol    ','ampscalar','nopass   ',
     *            'nobase   ','avall    ','dots     ','rms      ',
     *            'flagged  ','all      ','jplcat   '/
c
        call options('options',opts,present,nopts)
        docal = .not.present(1)
        dopol = .not.present(2)
        dopass= .not.present(4)
        ampsc =    present(3)
        rms   =    present(8)
        if(ampsc.and.rms)call bug('f',
     *    'Only one amplitude averaging option can be given')
        nobase =   present(5)
        avall  =   present(6)
        dodots =   present(7)
        doflag =   present(9)
        doall  =   present(10)
        docat  =   present(11)
        if(doflag.and.doall)call bug('f',
     *    'The "flagged" and "all" options are mutually exclusive')
c
        uvflags = 'dsl'
        if(docal) uvflags(4:4) = 'c'
        if(dopass)uvflags(5:5) = 'f'
        if(dopol) uvflags(6:6) = 'e'
        end
c************************************************************************
        subroutine bufini
c
c  Initialise the routines which do the buffering and averaging of
c  the visibility data.
c  All the buffering/averaging is performed in arrays stored in a
c  common block.
c
c------------------------------------------------------------------------
c************************************************************************
c
c  Include file for uvaver.for
c
c  Buf		Buffer used to accumulate the data.
c  Bufr         Buffer used to accumulate amplitudes
c               for amp-scalar averaging
c  Buf2		Buffer used to accumulate amplitudes**2
c		for rms averaging.
c  Count(i)	Number of good correlations added into Data(i).
c  free		Points to the first unused location in Data and Count.
c  pnt		For a baseline, points to location of data in Data and Count.
c  nchan	Number of channels for a given baseline.
c  npols		Number of polarisations.
c  pols		The polarisation codes.
c  preamble	The accumulated preambles.
c  cnt		The number of things accumulated into the preambles.
c
        include 'maxdim.h'
        integer maxaver,maxpol
        parameter(maxaver=276525,maxpol=4)
c       parameter(maxaver=276525,maxpol=4)
        complex buf(maxaver)
        real    bufr(maxaver),buf2(maxaver)
        integer count(maxaver),chnkpntr(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase,chnkpntr
        free = 1
        mbase = 0
        end
c************************************************************************
        subroutine bufflush(source,ampsc,rms,nobase,dodots,hann,hc,hw,
     *          first,device,x,n,xtitle,ytitle,nxy,yrange,logf)
c
        character source*32
        logical ampsc,rms,nobase,first,dodots
        character device*(*),xtitle*(*),ytitle*(*),logf*(*)
        integer n,nxy(2),hann
        real yrange(2),hc(*),hw(*)
        double precision x(n)
c
c  Plot the averaged data. On the first time through, also initialise the
c  plot device.
c
c------------------------------------------------------------------------
c************************************************************************
c
c  Include file for uvaver.for
c
c  Buf		Buffer used to accumulate the data.
c  Bufr         Buffer used to accumulate amplitudes
c               for amp-scalar averaging
c  Buf2		Buffer used to accumulate amplitudes**2
c		for rms averaging.
c  Count(i)	Number of good correlations added into Data(i).
c  free		Points to the first unused location in Data and Count.
c  pnt		For a baseline, points to location of data in Data and Count.
c  nchan	Number of channels for a given baseline.
c  npols		Number of polarisations.
c  pols		The polarisation codes.
c  preamble	The accumulated preambles.
c  cnt		The number of things accumulated into the preambles.
c  chnkpntr     The spectral chunk pntr.
         include 'maxdim.h'
        integer maxaver,maxpol
        parameter(maxaver=276525,maxpol=4)
        complex buf(maxaver)
        real    bufr(maxaver),buf2(maxaver)
        integer count(maxaver),chnkpntr(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase,chnkpntr
        integer polmin,polmax
        parameter(polmin=-8,polmax=4)
        integer maxplt,maxpnt
        parameter(maxpnt=32168,maxplt=1024)
        real xp(maxpnt),yp(maxpnt),xrange(2),inttime
        real ypp(maxpnt)
        integer plot(maxplt+1), sppntr(maxpnt)
        double precision time
        integer i,j,ngood,ng,ntime,npnts,nplts,nprev,p
        logical doamp,doampsc,dorms,dophase,doreal,doimag,dopoint,dolag
        logical doboth,hit(polmin:polmax)
        integer npol,pol(maxpol)
c
c  Determine the conversion of the data.
c
        doamp = ytitle.eq.'Amplitude'
        dolag = xtitle.eq.'Lag Number'
        doampsc = doamp.and.ampsc
        dorms   = doamp.and.rms
        if(doampsc)doamp = .false.
        if(dorms)  doamp = .false.
        dophase = ytitle.eq.'Phase'
        dopoint = dophase
        doreal  = ytitle.eq.'Real'
        doimag  = ytitle.eq.'Imaginary'
        doboth  = ytitle.eq.'BothA&P'
        if(doboth) ytitle=''
c
c  Determine the number of good baselines.
c
        ngood = 0
        do j=1,mbase
          if(cnt(j).gt.0)ngood = ngood + 1
        enddo
        if(ngood.le.0)return
c
c  Initialise the plot device, if this is the first time through.
c
        ng = ngood
        if(nobase) ng = 1
        if(first)call pltini(device,ng,nxy)
        first = .false.
c
c  Autoscale the X axis.
c
        call setaxisd(x,n,xrange)
c
c  Now loop through the good baselines, plotting them.
c
        inttime = 0
        time = 0
        ntime = 0
        npnts = 0
        nplts = 0
        npol = 0
        do i=polmin,polmax
          hit(i) = .false.
        enddo
c
        do j=1,mbase
          if(cnt(j).gt.0)then
            inttime = inttime + preamble(5,j)
            time = time + preamble(3,j)
            ntime = ntime + cnt(j)
c
c  Average the data in each polarisation. If there is only one scan in the
c  average, not bother to average it.
c
            do i=1,npols(j)
              if(.not.hit(pols(i,j)))then
                npol = npol + 1
                if(npol.gt.maxpol)call bug('f','Too many polarisations')
                pol(npol) = pols(i,j)
                hit(pols(i,j)) = .true.
              endif
              nprev = npnts
              p = pnt(i,j)
              if(cntp(i,j).ge.1)then
                if(dolag)then
                  call lagext(x,buf(p),count(p),nchan(i,j),n,
     *              xp,yp,maxpnt,npnts)
                else
                  call visext(x,buf(p),buf2(p),bufr(p),count(p),
     *              nchan(i,j),chnkpntr(p),
     *              doamp,doampsc,dorms,dophase,doreal,doimag,
     *              doboth,xp,yp,ypp,maxpnt,npnts,sppntr)
                endif
              endif
c
c  Did we find another plot.
c
              if(npnts.gt.nprev)then
                nplts = nplts + 1
                if(nplts.gt.maxplt)call bug('f',
     *            'Buffer overflow(plots), when accumulating plots')
                plot(nplts) = nprev + 1
                plot(nplts+1) = npnts + 1
              endif
            enddo
            if(.not.nobase.and.npnts.gt.0)then
        call plotit(source,npnts,xp,yp,ypp,xrange,yrange,dodots,plot,
     *          nplts,
     *          xtitle,ytitle,j,time/ntime,inttime/nplts,pol,npol,
     *          dopoint,hann,hc,hw,logf,doboth,sppntr)
c
              npol = 0
              do i=polmin,polmax
                hit(i) = .false.
              enddo
              npnts = 0
              nplts = 0
              ntime = 0
              time = 0
              inttime = 0
            endif
          endif
        enddo
c
c  Do the final plot.
c
        if(npnts.gt.0)call plotit(source,npnts,xp,yp,ypp,
     *    xrange,yrange,dodots,
     *    plot,nplts,xtitle,ytitle,0,time/ntime,inttime/nplts,
     *    pol,npol,dopoint,hann,hc,hw,logf,doboth,sppntr)
c
c  Reset the counters.
c
        free = 1
        mbase = 0
c
        end
c************************************************************************
        subroutine visext(x,buf,buf2,bufr,count,nchan,chnkpntr,
     *              doamp,doampsc,dorms,dophase,doreal,doimag,
     *              doboth,xp,yp,ypp,maxpnt,npnts,sppntr)
c
        integer nchan,npnts,maxpnt,count(nchan)
        logical doamp,doampsc,dorms,dophase,doreal,doimag
        logical doboth
        real buf2(nchan),bufr(nchan),xp(maxpnt),yp(maxpnt)
        real ypp(maxpnt)
        integer sppntr(maxpnt),chnkpntr(nchan)
        double precision x(nchan)
        complex buf(nchan)
c------------------------------------------------------------------------
c=======================================================================
c - mirconst.h  Include file for various fundamental physical constants.
c
c  History:
c    jm  18dec90  Original code.  Constants taken from the paper
c                 "The Fundamental Physical Constants" by E. Richard
c                 Cohen and Barry N. Taylor (PHYICS TODAY, August 1989).
c ----------------------------------------------------------------------
c  Pi.
      real pi, twopi
      double precision dpi, dtwopi
      parameter (pi = 3.14159265358979323846)
      parameter (dpi = 3.14159265358979323846)
      parameter (twopi = 2 * pi)
      parameter (dtwopi = 2 * dpi)
c ----------------------------------------------------------------------
c  Speed of light (meters/second).
      real cmks
      double precision dcmks
      parameter (cmks = 299792458.0)
      parameter (dcmks = 299792458.0)
c ----------------------------------------------------------------------
c  Boltzmann constant (Joules/Kelvin).
      real kmks
      double precision dkmks
      parameter (kmks = 1.380658e-23)
      parameter (dkmks = 1.380658d-23)
c ----------------------------------------------------------------------
c  Planck constant (Joules-second).
      real hmks
      double precision dhmks
      parameter (hmks = 6.6260755e-34)
      parameter (dhmks = 6.6260755d-34)
c ----------------------------------------------------------------------
c  Planck constant divided by Boltzmann constant (Kelvin/GHz).
      real hoverk
      double precision dhoverk
      parameter (hoverk = 0.04799216)
      parameter (dhoverk = 0.04799216)
c=======================================================================
        integer k
        real temp, temp2
        complex ctemp
        integer maxwin
        parameter(maxwin=48)
        logical docolor
        integer nspect,nschan(maxwin), nchan0        
        common/spectrum/nspect,nschan,nchan0,docolor
        temp=0.
        temp2=0.
c
        do k=1,nchan
          if(count(k).gt.0)then
            if(doamp)then
              temp = abs(buf(k)) / count(k)
            else if(doampsc)then
              temp = bufr(k) / count(k)
            else if(dorms)then
              temp = sqrt(buf2(k) / count(k))
            else if(dophase)then
              ctemp = buf(k)
              if(abs(real(ctemp))+abs(aimag(ctemp)).eq.0)then
                temp = 0
              else
                temp=180/pi*atan2(aimag(ctemp),real(ctemp))
              endif
            else if(doreal)then
              temp = real(buf(k)) / count(k)
            else if(doimag)then
              temp = aimag(buf(k)) / count(k)
            else if(doboth)then
c    ampl
              temp = abs(buf(k)) / count(k)
c    phas
              ctemp = buf(k)
              if(abs(real(ctemp))+abs(aimag(ctemp)).eq.0)then
                temp2 = 0
              else
                temp2=180/pi*atan2(aimag(ctemp),real(ctemp))
              endif
            endif
            npnts = npnts + 1
          if(npnts.gt.maxpnt)call bug('f',
     *    'Buffer overflow(points), when accumulating plots')
             xp(npnts) = x(k)
             yp(npnts) = temp
            ypp(npnts) = temp2
         sppntr(npnts) = chnkpntr(k)
          endif
        enddo
c
        end
c************************************************************************
        subroutine lagext(x,buf,count,nchan,n,
     *              xp,yp,maxpnt,npnts)
c
        integer nchan,n,npnts,maxpnt,count(nchan)
        double precision x(n)
        real xp(maxpnt),yp(maxpnt)
        complex buf(nchan)
c------------------------------------------------------------------------
        include 'maxdim.h' 
        real rbuf(2*(maxchan-1))
        complex cbuf(maxchan)
        integer k,k0
c
c  Normalise.
c
        do k=1,nchan
          if(count(k).gt.0)then
            cbuf(k) = buf(k) / count(k)
          else
            cbuf(k) = 0
          endif
        enddo
        do k=nchan+1,n/2+1
          cbuf(k) = 0
        enddo
c
        call fftcr(cbuf,rbuf,-1,n)
c
        k0 = n/2
        do k=1,n
          k0 = k0 + 1
          if(k0.gt.n)k0 = k0 - n
          npnts = npnts + 1
          if(npnts.gt.maxpnt)call bug('f',
     *          'Buffer overflow: Too many points to plot')
          xp(npnts) = x(k)
          yp(npnts) = rbuf(k0)
        enddo
c
        end
c************************************************************************
        subroutine bufacc(doflag,doall,preambl,inttime,data,flags,nread)
c
        integer nread
        double precision preambl(4)
        real inttime
        complex data(nread)
        logical flags(nread),doflag,doall
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input
c    doflag     Plot flagged data instead of unflagged
c  Input/Output:
c    preambl	Preamble. Destroyed on output.
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
c************************************************************************
c
c  Include file for uvaver.for
c
c  Buf		Buffer used to accumulate the data.
c  Bufr         Buffer used to accumulate amplitudes
c               for amp-scalar averaging
c  Buf2		Buffer used to accumulate amplitudes**2
c		for rms averaging.
c  Count(i)	Number of good correlations added into Data(i).
c  free		Points to the first unused location in Data and Count.
c  pnt		For a baseline, points to location of data in Data and Count.
c  nchan	Number of channels for a given baseline.
c  npols		Number of polarisations.
c  pols		The polarisation codes.
c  preamble	The accumulated preambles.
c  cnt		The number of things accumulated into the preambles.
c
         include 'maxdim.h'
        integer maxaver,maxpol
        parameter(maxaver=276525,maxpol=4)
        complex buf(maxaver)
        real    bufr(maxaver),buf2(maxaver)
        integer count(maxaver), chnkpntr(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase,chnkpntr
        integer i,i1,i2,p,bl,pol
        real t
        logical ok,docolor
c        integer maxwin
c        parameter(maxwin=48)
        integer nspect, nschan(maxwin),nchan0
        common/spectrum/nspect,nschan,nchan0,docolor
c
c  Does this spectrum contain some good data.
c
       ok = doall
        if(.not.ok)then
          do i=1,nread
            ok = ok.or.(flags(i).neqv.doflag)
          enddo
        endif
        if(.not.ok)return
c
c  Determine the baseline number.
c
        call basant(preambl(4),i1,i2)
        bl = (i2*(i2-1))/2 + i1
c
c  Zero up to, and including, this baseline.
c
        do i=mbase+1,bl
          cnt(i) = 0
        enddo
        mbase = max(mbase,bl)
c
c  Add in this visibility.
c
        if(cnt(bl).eq.0)then
          cnt(bl) = 1
          npols(bl) = 0
          preamble(1,bl) = preambl(1)
          preamble(2,bl) = preambl(2)
          preamble(3,bl) = preambl(3)
          preamble(4,bl) = preambl(4)
          preamble(5,bl) = inttime
        else
          cnt(bl) = cnt(bl) + 1
          preamble(1,bl) = preamble(1,bl) + preambl(1)
          preamble(2,bl) = preamble(2,bl) + preambl(2)
          preamble(3,bl) = preamble(3,bl) + preambl(3)
          preamble(4,bl) = preamble(4,bl) + preambl(4)
          preamble(5,bl) = preamble(5,bl) + inttime
        endif
c
c  Determine the polarisation.
c
        call uvdatgti('pol',pol)
        p = 0
        do i=1,npols(bl)
          if(pols(i,bl).eq.pol) p = i
        enddo
c
c  A new baseline. Set up the description of it.
c
        if(p.eq.0)then
          npols(bl) = npols(bl) + 1
          p = npols(bl)
          if(p.gt.maxpol) call bug('f',
     *      'Too many polarizations, in BufAcc')
          pols(p,bl) = pol
          cntp(p,bl) = 1
          nchan(p,bl) = nread
          pnt(p,bl) = free
          free = free + nread
          if(free.gt.maxaver)call bug('f',
     *      'Too much data to accumulate, in BufAcc')
c
c  Copy across the new data.
c
          p = pnt(p,bl) - 1
c
c make spectral window pntr
c
          i=0
          do j=1,nspect
          do k=1,nschan(j)
          i=i+1
          chnkpntr(i+p) =j
          end do
          end do
 
          do i=1,nread
            if(doall.or.(doflag.neqv.flags(i)))then
              buf(i+p) = data(i) 
              t = abs(data(i))
              bufr(i+p) = t
              buf2(i+p) = t*t
              count(i+p) = 1
            else
              buf(i+p) = (0.0,0.0)
              bufr(i+p) = 0.0
              buf2(i+p) = 0.0
              count(i+p) = 0
            endif
          enddo
c
c  Else accumulate new data for old baseline.
c
        else
          cntp(p,bl) = cntp(p,bl) + 1
          nread = min(nread,nchan(p,bl))
          nchan(p,bl) = nread
          p = pnt(p,bl) - 1
          do i=1,nread
            if(doall.or.(doflag.neqv.flags(i)))then
              t = abs(data(i))
              buf(i+p) = buf(i+p) + data(i)
              bufr(i+p) = bufr(i+p) + t
              buf2(i+p) = buf2(i+p) + t*t
              count(i+p) = count(i+p) + 1
            endif
          enddo
        endif
c
        end
c************************************************************************
        subroutine pltini(device,ngood,nxy)
c
        character device*(*)
        integer ngood,nxy(2)
c
c  Initialise the plot device.
c
c------------------------------------------------------------------------
        integer nx,ny
        character hard*4
        integer hlen
c
c  Externals.
c
        integer pgbeg
c
c  Determine the default plots per page in X and Y
c
        nx = nxy(1)
        ny = nxy(2)
        if(nx.le.0.or.ny.le.0)then
          nx = 2
          if(mod(ngood,3).eq.0)nx = 3
          ny = 2
          if(mod(ngood,9).eq.0)ny = 2
        endif
        if(pgbeg(0,device,nx,ny).ne.1)then
          call pgldev
          call bug('f','Error opening graphics device')
        endif
        call pgsch(real(max(nx,ny))**0.4)
        call pgqinf('hardcopy',hard,hlen)
        if(hard.eq.'YES')call pgscf(2)
        end
c************************************************************************
        subroutine setaxisd(data,npnts,range)
c
        integer npnts
        real range(2)
        double precision data(npnts)
c
c  Determine the range, for autoscaling, or the data.
c
c  Input:
c    data
c    npnts
c  Output:
c    range
c------------------------------------------------------------------------
        double precision dmax,dmin
        integer i
c
        dmax = data(1)
        dmin = dmax
        do i=2,npnts
          dmax = max(data(i),dmax)
          dmin = min(data(i),dmin)
        enddo
c
        call pgrnge(real(dmin),real(dmax),range(1),range(2))
c
        end
c************************************************************************
        subroutine setaxisr(data,npnts,range)
c
        integer npnts
        real range(2)
        real data(npnts)
c
c  Determine the range, for autoscaling, or the data.
c
c  Input:
c    data
c    npnts
c  Output:
c    range
c------------------------------------------------------------------------
        real dmax,dmin,delta,maxv
        integer i
c
        dmax = data(1)
        dmin = dmax
        do i=2,npnts
          dmax = max(data(i),dmax)
          dmin = min(data(i),dmin)
        enddo
c
        delta = 0.05*(dmax - dmin)
        maxv = max(abs(dmax),abs(dmin))
        if(delta.le.1e-4*maxv) delta = 0.01*maxv
        if(delta.eq.0) delta = 1
        range(1) = dmin - delta
        range(2) = dmax + delta
        end
c************************************************************************
        subroutine plotit(source,npnts,xp,yp,ypp,xrange,yrange,dodots,
     *            plot,nplts,xtitle,ytitle,bl,time,inttime,
     *            pol,npol,dopoint,hann,hc,hw,logf,doboth,sppntr)
c
        integer npnts,bl,nplts,plot(nplts+1),npol,pol(npol),hann
        double precision time
        real xp(npnts),yp(npnts),xrange(2),yrange(2),inttime,hc(*),hw(*)
        real ypp(npnts)
        logical dopoint,dodots, doboth
        character xtitle*(*),ytitle*(*),logf*(*)
        integer sppntr(npnts)
c
c  Draw a plot
c------------------------------------------------------------------------
        integer ncol
        parameter(ncol=12)
        integer hr,mins,sec,b1,b2,l,i,j,xl,yl,symbol,lp,lt
        character title*64,baseline*12,tau*16,line*80
        character pollab*32, source*32
        double precision t0
        real yranged(2), ypranged(2)
        real xlen,ylen,xloc, pscale, pline
        integer k1,k2, k
c
c  Externals.
c
        integer len1
        character itoaf*4,polsc2p*2
c
c
        symbol = 17
        if (dodots) symbol = 1
c
        call pgpage
        call pgvstd
        if(yrange(2).le.yrange(1))then
          call setaxisr(yp,npnts,yranged)
           pscale= (yranged(2)-yranged(1))
           pline = yranged(1)
          if(doboth) yranged(1) = yranged(1)-0.5*pscale
          call pgswin(xrange(1),xrange(2),yranged(1),yranged(2))
           if(doboth) yranged(1) = yranged(1)+0.5*pscale
cc          yrange(2)=yranged(2)
cc          yrange(1)=yranged(1)
          
        else
           pscale= (yrange(2)-yrange(1))
           pline = yrange(1)
            if(doboth) yrange(1) = yrange(1)-0.5*pscale
          call pgswin(xrange(1),xrange(2),yrange(1),yrange(2))
           if(doboth) yrange(1) = yrange(1)+0.5*pscale
        endif
         call setaxisr(ypp,npnts,ypranged)
            ypranged(1) =-200.
            ypranged(2) = 200.
c
        if(.not.doboth) call pgbox('BCNST',0.,0.,'BCNST',0.,0.)
        if(doboth) call pg2box('BCNST',0.,0,'BCNST',0.,0,pline)
           do i=1,nplts
c   rescale the phase for plotting both
           do k=plot(i),plot(i+1)
         if(ypranged(2).gt.ypranged(1)) then
             if(yrange(2).le.yrange(1))then
         ypp(k) = 0.5*(ypp(k)-ypranged(2))*(yranged(2)-yranged(1))/
     *    (ypranged(2)-ypranged(1)) + yranged(1)
          
                  else
        ypp(k) = 0.5*(ypp(k)-ypranged(2))*(yrange(2)-yrange(1))/
     *    (ypranged(2)-ypranged(1))+yrange(1)
         
                  endif
          else
          call bug('f','the plotting range in phase is 0 degree!!')
          end if
          end do
          
          call  pgsci(i)
c          call pgsci(mod(i-1,ncol)+1)
          if(dopoint)then
          call pgpts(plot(i+1)-plot(i),xp(plot(i)),yp(plot(i)),symbol,
     *               sppntr)
          else
            if (hann.gt.1) call hannsm(hann,hc,plot(i+1)-plot(i),
     *         yp(plot(i)),hw)
             if (hann.gt.1) call hannsm(hann,hc,plot(i+1)-plot(i),
     *         ypp(plot(i)),hw)
        call pghline(plot(i+1)-plot(i),xp(plot(i)),yp(plot(i)),
     *      ypp(plot(i)),2.0,doboth, yranged(2), sppntr, 
     *      pline,xrange)
          endif
          if (logf.ne.' ') then
            do j = 1, plot(i+1)-plot(i)
              write(line,'(1pe13.6,2x,1pe13.6)')
     *          xp(plot(i)+j-1),yp(plot(i)+j-1)
              call logwrit(line)
            end do
          end if
        enddo
        call pgsci(1)
c
c  The polarisation label.
c
        pollab = ' '
        lp = 0
        do i=1,npol
          pollab(lp+1:lp+2) = polsc2p(pol(i))
          lp = len1(pollab)
          pollab(lp+1:lp+1) = ','
          lp = lp + 1
        enddo
c
c  The integration time label.
c
        write(tau,'(f16.1)')inttime/60.
        lt = 1
        dowhile(tau(lt:lt).eq.' ')
          lt = lt + 1
        enddo
c
c  Time of day.
c
        t0 = nint(time - 1.d0) + 0.5
        sec = nint(24*3600*(time - t0))
        hr = sec / 3600
        sec = sec - 3600*hr
        mins = sec / 60
        sec = sec - 60*mins
c
        if(bl.eq.0)then
          write(title,'(a,i2.2,a,i2.2,a,i2.2)')
     *      pollab(1:lp)//' \gt='//tau(lt:)//' min, T=',
     *      hr,':',mins,':',sec
        else
c
c  Decode baseline number into antenna numbers.
c
          b2 = 1
          l = 1
          dowhile(bl.ge.l+b2)
            l = l + b2
            b2 = b2 + 1
          enddo
          b1 = bl - l + 1
c
          baseline = itoaf(b1)
          l = len1(baseline)
          baseline(l+1:) = '-'//itoaf(b2)
          l = len1(baseline)
c
          write(title,'(a,i2.2,a,i2.2,a,i2.2)')
     *      pollab(1:lp)//' \gt='//tau(lt:)//' min, Bl='//
     *      baseline(1:l)//', T=',hr,':',mins,':',sec
        endif
        l = len1(title)
        xl = len1(xtitle)
        yl = len1(ytitle)
c
        if(npol.eq.1)then
          call pglab(xtitle(1:xl),ytitle(1:yl),title(1:l))
        else
          call pglab(xtitle(1:xl),ytitle(1:yl),' ')
          call pglen(5,title(1:l),xlen,ylen)
          xloc = 0.5 - 0.5*xlen
c
          k1 = 1
          do i=1,npol
            k2 = k1 + len1(polsc2p(pol(i))) - 1
            if(i.ne.npol)k2 = k2 + 1
            call pgsci(i)
            call pgmtxt('T',2.0,xloc,0.,title(k1:k2))
            call pglen(5,title(k1:k2),xlen,ylen)
            xloc = xloc + xlen
            k1 = k2 + 1
          enddo
          call pgsci(1)
          k2 = l
          call pgmtxt('T',2.0,xloc,0.,title(k1:k2))
        endif
c          call uvgetvra(lvis,'source',source)
          call pgsci(2)
          call pgmtxt('LV',0.0, 1.025, 0., source(1:32))
          call pgsci(1)
c
        end

c************************************************************************
c PgHline -- Histogram line plot for pgplot.
c mchw:
c plotting,uv-data
c
        subroutine pghline(npts,x,y,yp,gapfac,doboth,maxstr,sppntr,
     *   pline,xrange)
              parameter(maxsline=10000)
              parameter(cmks = 299792458.0)
        real fmx,fmn,strl
        real freq(maxsline),intensity(maxsline)
        integer uqst(6*maxsline),lqst(6*maxsline),mtag(6*maxsline)
        integer mxnline,iubuff, ilbuff
        real maxf, minf, maxstr, minstr, maxcatstr
        real xlfrq(2), ylstr(2)
        integer npts,sppntr(npts)
        real x(npts), y(npts), yp(npts), gapfac
        REAL XPTS(npts),YPTS(npts), pline,apline(2),xrange(2)
        INTEGER N
c
c  Histogram style line plot of y-array versus x-array. Points are not
c  connected over gaps or reversals in the x-array.
c
c  Inputs:
c    npts	number of points
c    x		x-array to be plotted
c    y		y-array to be plotted
c    yp         phas-array
c    gapfac	factor to define a gap in x-array. E.g. 2= 2*(x(i+1)-x(i))
c    sppntr     spectral window pntr
c
c--
c History
c    02nov89	mchw	original version
c    02apr94    nebk    add pgbbuf/pgebuf calls
c    24may94    mjs     reinserted Mel's docs
c    22jun05    jhz     add features for color coded multiple chunk plot
c-------------------------------------------------------------------------
        integer start,end,i,j, k, ci, l, lm
        character title*64
        real xlen,ylen,xloc
        integer maxwin,symbol
        parameter(maxwin=48)
        logical doboth,docolor
        integer nspect, nschan(maxwin),fnschan(maxwin),nchan0
        common/spectrum/nspect,nschan,nchan0,docolor
c
c common jpl
c
        parameter(maxmline=500)
        integer nmol, moltag(maxmline)
        character molname(maxmline)*16, veldef*8
        real lsrvel,veldop
        logical docat
        common/jplcat/nmol,moltag,molname,docat,lsrvel,veldef,veldop
           apline(1)=pline
           apline(2)=pline
c
c  sort the spectral window pointr after flagging
c
                 
        do j=1, nspect
        fnschan(j)=0
        enddo
        j=sppntr(1)
        do i=1, npts
        if(sppntr(i).eq.j) then
         fnschan(j)=fnschan(j)+1
         else
          j=sppntr(i)
          fnschan(j)=1
         endif
        enddo
c
        maxf=0.
        minf=1000.
        minstr=0.
        ylstr(1)=0.
c
c  Look for gaps or reversals in x-array
c
        symbol=2
        yloc=0.95
        call pgbbuf
        start = 1
        end = 2
           i=0
           ci=25
           call pgscr(ci, .3, 0.5, 0.7)
           do j=1, nspect 
            ci=j
        if(j.gt.12) then
            if(ci.eq.13) call pgscr(ci, 1.0, 1.0, 0.5)
            if(ci.eq.14) call pgscr(ci, 1.0, 1.0, 0.0)
            if(ci.eq.15) call pgscr(ci, 1.0, 0.5, 0.5)
            if(ci.eq.16) call pgscr(ci, 1.0, 0.5, 0.2)
            if(ci.eq.17) call pgscr(ci, 1.0, 0.0, 0.5)
            if(ci.eq.18) call pgscr(ci, 1.0, 0.2, 0.2)
            if(ci.eq.19) call pgscr(ci, 0.5, 1.0, 0.5)
            if(ci.eq.20) call pgscr(ci, 0.7, 0.70, 0.70)
            if(ci.eq.21) call pgscr(ci, 0.7, 0.5, 0.5)
            if(ci.eq.22) call pgscr(ci, 0.7, 0.5, 0.9)
            if(ci.eq.23) call pgscr(ci, 0.5, 0.0, 0.5)
            if(ci.eq.24) call pgscr(ci, 0.75, 0.2, 0.3)
            end if
             call  pgsci(ci)
             if(j.eq.1) call  pgsci(7)
             if(j.eq.7) call  pgsci(25)
             call pgmove(x(start),y(start))
             N=0
          do k=1, fnschan(j)
               i=i+1
               N=N+1
            if(j.gt.12) then
            if(ci.eq.13) call pgscr(ci, 1.0, 1.0, 0.5)
            if(ci.eq.14) call pgscr(ci, 1.0, 1.0, 0.0)
            if(ci.eq.15) call pgscr(ci, 1.0, 0.5, 0.5)
            if(ci.eq.16) call pgscr(ci, 1.0, 0.5, 0.2)
            if(ci.eq.17) call pgscr(ci, 1.0, 0.0, 0.5)
            if(ci.eq.18) call pgscr(ci, 1.0, 0.2, 0.2)
            if(ci.eq.19) call pgscr(ci, 0.5, 1.0, 0.5)
            if(ci.eq.20) call pgscr(ci, 0.7, 0.70, 0.70)
            if(ci.eq.21) call pgscr(ci, 0.7, 0.5, 0.5)
            if(ci.eq.22) call pgscr(ci, 0.7, 0.5, 0.9)
            if(ci.eq.23) call pgscr(ci, 0.5, 0.0, 0.5)
            if(ci.eq.24) call pgscr(ci, 0.75, 0.2, 0.3)
            end if
c
c make the single spectral window to be green
c
             if(.not.docolor)  call  pgsci(3)
               XPTS(k) = x(k+(j-1)*fnschan(j))
               YPTS(k) = yp(k+(j-1)*fnschan(j))
          if(maxf.lt.(x(k+(j-1)*fnschan(j)))) maxf=x(k+(j-1)*fnschan(j))
          if(minf.gt.(x(k+(j-1)*fnschan(j)))) minf=x(k+(j-1)*fnschan(j))
          if(maxstr.lt.(y(k+(j-1)*fnschan(j)))) 
     *      then
                maxstr=y(k+(j-1)*fnschan(j))
            end if
            if(i<npts.and.k<fnschan(j)) then
              call pgdraw (0.5*(x(i+1)+x(i)), y(i))
              call pgdraw (0.5*(x(i+1)+x(i)), y(i+1))
            end if
             if(i<npts.and.k.eq.fnschan(j)) then
              call pgdraw (0.5*(x(i)+x(i)), y(i))
              call pgdraw (0.5*(x(i)+x(i)), y(i))
             endif
            call pgebuf
          enddo
             end=i
             call pgdraw(x(end),y(end))
              start=end+1
             if(docolor) then
             write(title,'(a,i2)') 's',j
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/30.
              call pgmtxt('RV',1.0,yloc,0.,title(1:l))
          call pgebuf
             endif        
c          plot phase
           if(doboth) then
           call  pgsci(1)
           call pgline(2,xrange,apline)
           call  pgsci(2)
           IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
           CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
           ELSE
           CALL GRDOT1(N,XPTS,YPTS)
           END IF
           CALL PGEBUF
           endif
           if(end.eq.npts) goto 556
           enddo        
556        continue 


          if(docat) then
      fmn  = minf
      fmx  = maxf
      strl = -500
          call  pgsci(2)
       if(abs(lsrvel).lt.1000) then
       write(title,'(a,f7.1,a)') 'Vlsr =',lsrvel,' km/s'
         else
       write(title,'(a,f7.3)') 'z =',lsrvel*1.0e3/cmks
       end if
       call pgmtxt('RV',-12.0, 0.925, 0., title)
       if(veldef.eq."radio") then 
                 fmn = fmn /(1.-lsrvel*1.e3/cmks)
                 fmx = fmx /(1.-lsrvel*1.e3/cmks)
               end if
       if(veldef.eq."optical") then
                 fmn = fmn*(1.+lsrvel*1.e3/cmks)
                 fmx = fmx*(1.+lsrvel*1.e3/cmks)
               end if
c
c fmx,fmn,strl,nmol,moltag are input parameters
c       
       call JPLlineRD(fmx,fmn,strl,nmol,moltag,mxnline,
     &               freq,intensity,uqst,lqst,mtag)
c      write(*,*) 'mxnline=', mxnline
      iubuff=0
      ilbuff=0
      maxcatstr=strl
      do i=1, mxnline
      if(maxcatstr.lt.intensity(i)) maxcatstr=intensity(i)
      end do

c      write(*, *) 'maxcatstr maxstr', maxcatstr, maxstr
      call  pgsci(1)
      do i=1, mxnline
       if(veldef.eq."radio") 
     &  freq(i) = freq(i)*(1.-(lsrvel+veldop)*1.e3/cmks) 
       if(veldef.eq."optical") 
     &  freq(i) = freq(i)/(1.+(lsrvel+veldop)*1.e3/cmks)
c      write(*,*) freq(i)/1000.,intensity(i)/maxcatstr*maxstr
              intensity(i)=maxstr
              ylstr(2) = intensity(i)*.75
              ylstr(1) = intensity(i)*.65 
              xlfrq(1) = freq(i)/1000.
              xlfrq(2) = freq(i)/1000.
              do j=1, nmol
               mtag(i)=abs(mtag(i))
              if(moltag(j).eq.mtag(i)) then
c                 write(*,*) molname(j)
                write(title,'(a)') molname(j)
                endif
              end do
              lm=1
              do while (title(lm:lm).ne."\n") 
                  lm=lm+1
              end do
         call pgline (2, xlfrq, ylstr)
         call pgebuf
                xloc=xlfrq(1)+(maxf-minf)/npts
                yloc=ylstr(2)*1.02
                lm=lm-1
         call pgptext(xloc,yloc, 90.0, 0.0, title(1:lm))
          end do
          end if
        end


CPGPT -- draw several graph markers
Cvoid cpgpt(int n, const float *xpts, const float *ypts, int symbol);
C
      SUBROUTINE PGPTS (N, XPTS, YPTS, SYMBOL,sppntr)
      INTEGER N
      REAL XPTS(*), YPTS(*)
      INTEGER SYMBOL, sppntr(N)
c jhz modified to PGPT with color codes for spectra.
C
C Primitive routine to draw Graph Markers (polymarker). The markers
C are drawn using the current values of attributes color-index,
C line-width, and character-height (character-font applies if the symbol
C number is >31).  If the point to be marked lies outside the window,
C no marker is drawn.  The "pen position" is changed to
C (XPTS(N),YPTS(N)) in world coordinates (if N > 0).
C

C Arguments:
C  N      (input)  : number of points to mark.
C  XPTS   (input)  : world x-coordinates of the points.
C  YPTS   (input)  : world y-coordinates of the points.
C  SYMBOL (input)  : code number of the symbol to be drawn at each
C                    point:
C                    -1, -2  : a single dot (diameter = current
C                              line width).
C                    -3..-31 : a regular polygon with ABS(SYMBOL)
C                              edges (style set by current fill style).
C                    0..31   : standard marker symbols.
C                    32..127 : ASCII characters (in current font).
C                              e.g. to use letter F as a marker, let
C                              SYMBOL = ICHAR('F').
C                    > 127  :  a Hershey symbol number.
C
C Note: the dimension of arrays X and Y must be greater than or equal
C to N. If N is 1, X and Y may be scalars (constants or variables). If
C N is less than 1, nothing is drawn.
C--

C 27-Nov-1986
C 17-Dec-1990 - add polygons [PAH].
C 14-Mar-1997 - optimization: use GRDOT1 [TJP].
C 23-Jub-2005 - jhz - implemented spectral window pntr and color index
C-----------------------------------------------------------------------
ccccccccccccccccccccccccccc
      LOGICAL PGNOTO, docolor
      integer j, k, ci, l
      character title*64
      real xlen,ylen,xloc
      integer   i,maxwin
      parameter(maxwin=48)
      integer  nspect, nschan(maxwin),fnschan(maxwin),nchan0
      common/spectrum/nspect,nschan,nchan0,docolor
c
c  sort the spectral window pointr after flagging
c
        do j=1, nspect
        fnschan(j)=0
        enddo
        j=sppntr(1)
        do i=1, N 
        if(sppntr(i).eq.j) then
         fnschan(j)=fnschan(j)+1
         else
          j=sppntr(i)
          fnschan(j)=1
         endif
        enddo


        yloc=0.95
C
         i=0
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPTS')) RETURN
C
          do j=1, nspect
            ci=j
        if(j.gt.12) then
            if(ci.eq.12) call pgscr(ci, 0.8, 0.6, 0.4)
            if(ci.eq.13) call pgscr(ci, 1.0, 1.0, 0.5)
            if(ci.eq.14) call pgscr(ci, 1.0, 1.0, 0.0)
            if(ci.eq.15) call pgscr(ci, 1.0, 0.5, 0.5)
            if(ci.eq.16) call pgscr(ci, 1.0, 0.5, 0.2)
            if(ci.eq.17) call pgscr(ci, 1.0, 0.0, 0.5)
            if(ci.eq.18) call pgscr(ci, 1.0, 0.2, 0.2)
            if(ci.eq.19) call pgscr(ci, 0.5, 1.0, 0.5)
            if(ci.eq.20) call pgscr(ci, 0.7, 0.70, 0.70)
            if(ci.eq.21) call pgscr(ci, 0.7, 0.5, 0.5)
            if(ci.eq.22) call pgscr(ci, 0.7, 0.5, 0.9)
            if(ci.eq.23) call pgscr(ci, 0.5, 0.0, 0.5)
            if(ci.eq.24) call pgscr(ci, 0.75, 0.2, 0.3)
            end if
            call  pgsci(ci)
            
          N=0
          do k=1, fnschan(j)
          i=i+1
          N=N+1
          XPTS(k) = XPTS(k+(j-1)*fnschan(j))
          YPTS(k) = YPTS(k+(j-1)*fnschan(j))
          enddo
       write(title,'(a,i2)') 's' ,j
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/30.
               call pgmtxt('RV',1.0,yloc,0.,title(1:l))

      CALL PGBBUF
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
          CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
      ELSE
          CALL GRDOT1(N,XPTS,YPTS)
      END IF
      CALL PGEBUF
          enddo
555       continue
      
        END



        subroutine vishd(in)
c
        character in*(*)
c
c  Give a summary about a uv data-set.
c------------------------------------------------------------------------
      include 'maxdim.h' 
      character aval1*64,aval2*64,type*1,obstype*32
      integer length,nschan(maxwin),nchan0,nspect,npol,pol,i
      integer nants,tno
      double precision sdf(maxwin),sfreq(maxwin),restfreq(maxwin)
      double precision time
      real veldop
      logical updated, docolor
      common/spectrum/nspect,nschan,nchan0,docolor
c
c  Close and reopen the file as a visibility file.
c
      call uvopen(tno,in,'old')
      call uvnext(tno)
c
c  Telescope/observer/object parameters.
c
      call uvrdvra(tno,'instrume',aval1,' ')
      call uvrdvra(tno,'telescop',aval2,' ')
      call uvrdvra(tno,'source',aval1,' ')
      call uvrdvra(tno,'observer',aval2,' ')
      call uvrdvrd(tno,'time',time,0.d0)
      call julday(time,'H',aval1)
      call uvrdvri(tno,'nants',nants,0)
      call uvrdvri(tno,'npol',npol,1)
      call uvrdvri(tno,'pol',pol,1)
      do i=2,npol
        call uvnext(tno)
        call uvrdvri(tno,'pol',pol,1)
      enddo
      call rdhda(tno,'obstype',obstype,' ')
      call uvprobvr(tno,'corr',type,length,updated)
        call uvrdvri(tno,'nchan',nchan0,1)
        call uvrdvri(tno,'nspect',nspect,1)
        if(nspect.le.maxwin)then
        call uvgetvri(tno,'nschan',nschan,nspect)
        call uvgetvrd(tno,'sfreq',sfreq,nspect)
        call uvgetvrd(tno,'sdf',sdf,nspect)
        call uvgetvrd(tno,'restfreq',restfreq,nspect)
        call uvgetvrr(tno,'veldop', veldop, 1)
c        write(*,*) 'veldop=', veldop
        endif
	if(nspect.eq.1) docolor=.false.
      call uvclose(tno)
c
      end

      SUBROUTINE PG2BOX(XOPT,XTICK,NXSUB,YOPT,YTICK,NYSUB,YSTART)
      CHARACTER*(*) XOPT, YOPT
       REAL XTICK,YTICK,YSTART
      INTEGER NXSUB, NYSUB
C
C Annotate the viewport with frame, axes, numeric labels, etc.
C PGBOX is called by on the user's behalf by PGENV, but may also be
C called explicitly.
C
C Arguments:
C  XOPT   (input)  : string of options for X (horizontal) axis of
C                    plot. Options are single letters, and may be in
C                    any order (see below).
C  XTICK  (input)  : world coordinate interval between major tick marks
C                    on X axis. If XTICK=0.0, the interval is chosen by
C                    PGBOX, so that there will be at least 3 major tick
C                    marks along the axis.
C  NXSUB  (input)  : the number of subintervals to divide the major
C                    coordinate interval into. If XTICK=0.0 or NXSUB=0,
C                    the number is chosen by PGBOX.
C  YOPT   (input)  : string of options for Y (vertical) axis of plot.
C                    Coding is the same as for XOPT.
C  YTICK  (input)  : like XTICK for the Y axis.
C  NYSUB  (input)  : like NXSUB for the Y axis.
C
C Options (for parameters XOPT and YOPT):
C  A : draw Axis (X axis is horizontal line Y=0, Y axis is vertical
C      line X=0).
C  B : draw bottom (X) or left (Y) edge of frame.
C  C : draw top (X) or right (Y) edge of frame.
C  G : draw Grid of vertical (X) or horizontal (Y) lines.
C  I : Invert the tick marks; ie draw them outside the viewport
C      instead of inside.
C  L : label axis Logarithmically (see below).
C  N : write Numeric labels in the conventional location below the
C      viewport (X) or to the left of the viewport (Y).
C  P : extend ("Project") major tick marks outside the box (ignored if
C      option I is specified).
C  M : write numeric labels in the unconventional location above the
C      viewport (X) or to the right of the viewport (Y).
C  T : draw major Tick marks at the major coordinate interval.
C  S : draw minor tick marks (Subticks).
C  V : orient numeric labels Vertically. This is only applicable to Y.
C      The default is to write Y-labels parallel to the axis.
C  1 : force decimal labelling, instead of automatic choice (see PGNUMB).
C  2 : force exponential labelling, instead of automatic.
C
C To get a complete frame, specify BC in both XOPT and YOPT.
C Tick marks, if requested, are drawn on the axes or frame
C or both, depending which are requested. If none of ABC is specified,
C tick marks will not be drawn. When PGENV calls PGBOX, it sets both
C XOPT and YOPT according to the value of its parameter AXIS:
C -1: 'BC', 0: 'BCNST', 1: 'ABCNST', 2: 'ABCGNST'.
C
C For a logarithmic axis, the major tick interval is always 1.0. The
C numeric label is 10**(x) where x is the world coordinate at the
C tick mark. If subticks are requested, 8 subticks are drawn between
C each major tick at equal logarithmic intervals.
C
C To label an axis with time (days, hours, minutes, seconds) or
C angle (degrees, arcmin, arcsec), use routine PGTBOX.
C--
C 19-Oct-1983
C 23-Sep-1984 - fix bug in labelling reversed logarithmic axes.
C  6-May-1985 - improve behavior for pen plotters [TJP].
C 23-Nov-1985 - add 'P' option [TJP].
C 14-Jan-1986 - use new routine PGBOX1 to fix problem of missing
C               labels at end of axis [TJP].
C  8-Apr-1987 - improve automatic choice of tick interval; improve
C               erroneous rounding of tick interval to 1 digit [TJP].
C 23-Apr-1987 - fix bug: limit max number of ticks to ~10 [TJP].
C  7-Nov-1987 - yet another change to algorithm for choosing tick
C               interval; maximum tick interval is now 0.2*range of
C               axis, which may round up to 0.5 [TJP].
C 15-Dec-1988 - correct declaration of MAJOR [TJP].
C  6-Sep-1989 - use Fortran generic intrinsic functions [TJP].
C 18-Oct-1990 - correctly initialize UTAB(1) [AFT].
C 19-Oct-1990 - do all plotting in world coordinates [TJP].
C  6-Nov-1991 - label logarithmic subticks when necessary [TJP].
C  4-Jul-1994 - add '1' and '2' options [TJP].
C 20-Apr-1995 - adjust position of labels slightly, and move out
C               when ticks are inverted [TJP].
C 26-Feb-1997 - use new routine pgclp [TJP].
C-----------------------------------------------------------------------
      INCLUDE  'smauvspec.h'
      CHARACTER*20  CLBL
      CHARACTER*64  OPT
      LOGICAL  XOPTA, XOPTB, XOPTC, XOPTG, XOPTN, XOPTM, XOPTT, XOPTS
      LOGICAL  YOPTA, YOPTB, YOPTC, YOPTG, YOPTN, YOPTM, YOPTT, YOPTS
      LOGICAL  XOPTI, YOPTI, YOPTV, XOPTL, YOPTL, XOPTP, YOPTP, RANGE
      LOGICAL  IRANGE, MAJOR, XOPTLS, YOPTLS, PGNOTO
      REAL     TAB(9), UTAB(9)
      INTEGER  I, I1, I2, J, NC, NP, NV, KI, CLIP
      INTEGER  NSUBX, NSUBY, JMAX, XNFORM, YNFORM
      REAL     TIKL, TIKL1, TIKL2, XC, YC
      REAL     XINT, XINT2, XVAL, YINT, YINT2, YVAL
      REAL     PGRND
      REAL     A, B, C
      REAL     XNDSP, XMDSP, YNDSP, YMDSP, YNVDSP, YMVDSP
      REAL     XBLC, XTRC, YBLC, YTRC
      INTRINSIC ABS, INDEX, INT, LOG10, MAX, MIN, MOD, NINT, SIGN, REAL
      real     ylpmax,ylpmin
C
C Table of logarithms 1..9
C
      DATA TAB / 0.00000, 0.30103, 0.47712, 0.60206, 0.69897,
     1           0.77815, 0.84510, 0.90309, 0.95424 /
C
      RANGE(A,B,C) = (A.LT.B.AND.B.LT.C) .OR. (C.LT.B.AND.B.LT.A)
      IRANGE(A,B,C) = (A.LE.B.AND.B.LE.C) .OR. (C.LE.B.AND.B.LE.A)
C
      IF (PGNOTO('PGBOX')) RETURN
      CALL PGBBUF
      CALL PGQWIN(XBLC, XTRC, YBLC, YTRC)
C
C Decode options.
C
      CALL GRTOUP(OPT,XOPT)
      XOPTA = INDEX(OPT,'A').NE.0 .AND. RANGE(YBLC,0.0,YTRC)
      XOPTB = INDEX(OPT,'B').NE.0
      XOPTC = INDEX(OPT,'C').NE.0
      XOPTG = INDEX(OPT,'G').NE.0
      XOPTI = INDEX(OPT,'I').NE.0
      XOPTL = INDEX(OPT,'L').NE.0
      XOPTM = INDEX(OPT,'M').NE.0
      XOPTN = INDEX(OPT,'N').NE.0
      XOPTS = INDEX(OPT,'S').NE.0
      XOPTT = INDEX(OPT,'T').NE.0
      XOPTP = INDEX(OPT,'P').NE.0 .AND. (.NOT.XOPTI)
      XNFORM = 0
      IF (INDEX(OPT,'1').NE.0) XNFORM = 1
      IF (INDEX(OPT,'2').NE.0) XNFORM = 2
      CALL GRTOUP(OPT,YOPT)
      YOPTA = INDEX(OPT,'A').NE.0 .AND. RANGE(XBLC,0.0,XTRC)
      YOPTB = INDEX(OPT,'B').NE.0
      YOPTC = INDEX(OPT,'C').NE.0
      YOPTG = INDEX(OPT,'G').NE.0
      YOPTI = INDEX(OPT,'I').NE.0
      YOPTL = INDEX(OPT,'L').NE.0
      YOPTN = INDEX(OPT,'N').NE.0
      YOPTM = INDEX(OPT,'M').NE.0
      YOPTS = INDEX(OPT,'S').NE.0
      YOPTT = INDEX(OPT,'T').NE.0
      YOPTV = INDEX(OPT,'V').NE.0
      YOPTP = INDEX(OPT,'P').NE.0 .AND. (.NOT.YOPTI)
      YNFORM = 0
      IF (INDEX(OPT,'1').NE.0) YNFORM = 1
      IF (INDEX(OPT,'2').NE.0) YNFORM = 2
C
C Displacement of labels from edge of box
C (for X bottom/top, Y left/right, and Y left/right with V option).
C
      XNDSP = 1.2
      XMDSP = 0.7
      YNDSP = 0.7
      YMDSP = 1.2
      YNVDSP = 0.7
      YMVDSP = 0.7
      IF (XOPTI) THEN
         XNDSP = XNDSP + 0.3
         XMDSP = XMDSP + 0.3
      END IF
      IF (YOPTI) THEN
         YNDSP = YNDSP + 0.3
         YMDSP = YMDSP + 0.3
         YNVDSP = YNVDSP + 0.3
         YMVDSP = YMVDSP + 0.3
      END IF
C
C Disable clipping.
C
      CALL PGQCLP(CLIP)
      CALL PGSCLP(0)
C
C Draw box.
C
      IF (XOPTB) THEN
          CALL GRMOVA(XBLC, YBLC)
          CALL GRLINA(XTRC, YBLC)
      END IF
      IF (YOPTC) THEN
          CALL GRMOVA(XTRC, YBLC)
          CALL GRLINA(XTRC, YTRC)
      END IF
      IF (XOPTC) THEN
          CALL GRMOVA(XTRC, YTRC)
          CALL GRLINA(XBLC, YTRC)
      END IF
      IF (YOPTB) THEN
          CALL GRMOVA(XBLC, YTRC)
          CALL GRLINA(XBLC, YBLC)
      END IF
C
C Draw axes if required.
C
      IF (XOPTA.AND..NOT.XOPTG) THEN
          CALL GRMOVA(XBLC, 0.0)
          CALL GRLINA(XTRC, 0.0)
      END IF
      IF (YOPTA.AND..NOT.YOPTG) THEN
          CALL GRMOVA(0.0, YBLC)
          CALL GRLINA(0.0, YTRC)
      END IF
C
C Length of X tick marks.
C
      TIKL1 = PGXSP(PGID)*0.6*(YTRC-YBLC)/PGYLEN(PGID)
      IF (XOPTI) TIKL1 = -TIKL1
      TIKL2 = TIKL1*0.5
C
C Choose X tick intervals. Major interval = XINT,
C minor interval = XINT2 = XINT/NSUBX.
C
      UTAB(1) = 0.0
      IF (XOPTL) THEN
          XINT = SIGN(1.0,XTRC-XBLC)
          NSUBX = 1
          DO 10 J=2,9
              UTAB(J) = TAB(J)
              IF (XINT.LT.0.0) UTAB(J) = 1.0-TAB(J)
   10     CONTINUE
      ELSE IF (XTICK.EQ.0.0) THEN
          XINT = MAX(0.05, MIN(7.0*PGXSP(PGID)/PGXLEN(PGID), 0.20))
     1           *(XTRC-XBLC)
          XINT = PGRND(XINT,NSUBX)
      ELSE
          XINT = SIGN(XTICK,XTRC-XBLC)
          NSUBX = MAX(NXSUB,1)
      END IF
      IF (.NOT.XOPTS) NSUBX = 1
      NP = INT(LOG10(ABS(XINT)))-4
      NV = NINT(XINT/10.**NP)
      XINT2 = XINT/NSUBX
      XOPTLS = XOPTL .AND. XOPTS .AND. (ABS(XTRC-XBLC).LT.2.0)
C
C Draw X grid.
C
      IF (XOPTG) THEN
          CALL PGBOX1(XBLC, XTRC, XINT, I1, I2)
          DO 20 I=I1,I2
              CALL GRMOVA(REAL(I)*XINT, YBLC)
              CALL GRLINA(REAL(I)*XINT, YTRC)
   20     CONTINUE
      END IF
C
C Draw X ticks.
C
      IF (XOPTT.OR.XOPTS) THEN
          CALL PGBOX1(XBLC, XTRC, XINT2, I1, I2)
          JMAX = 1
          IF (XOPTL.AND.XOPTS) JMAX=9
C
C         Bottom ticks.
C
          IF (XOPTB) THEN
            DO 40 I=I1-1,I2
            DO 30 J=1,JMAX
                MAJOR = (MOD(I,NSUBX).EQ.0).AND.XOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                XVAL = (I+UTAB(J))*XINT2
                IF (IRANGE(XBLC,XVAL,XTRC)) THEN
                    IF (XOPTP.AND.MAJOR) THEN
                        CALL GRMOVA(XVAL, YBLC-TIKL2)
                    ELSE
                        CALL GRMOVA(XVAL, YBLC)
                    END IF
                    CALL GRLINA(XVAL, YBLC+TIKL)
                END IF
   30        CONTINUE
   40       CONTINUE
          END IF
C
C         Axis ticks.
C
          IF (XOPTA) THEN
            DO 60 I=I1-1,I2
            DO 50 J=1,JMAX
                MAJOR = (MOD(I,NSUBX).EQ.0).AND.XOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                XVAL = (I+UTAB(J))*XINT2
                IF (IRANGE(XBLC,XVAL,XTRC)) THEN
                    CALL GRMOVA(XVAL, -TIKL)
                    CALL GRLINA(XVAL, TIKL)
                END IF
   50       CONTINUE
   60       CONTINUE
          END IF
C
C         Top ticks.
C
          IF (XOPTC) THEN
            DO 80 I=I1-1,I2
            DO 70 J=1,JMAX
                MAJOR = (MOD(I,NSUBX).EQ.0).AND.XOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                XVAL = (I+UTAB(J))*XINT2
                IF (IRANGE(XBLC,XVAL,XTRC)) THEN
                    CALL GRMOVA(XVAL, YTRC-TIKL)
                    CALL GRLINA(XVAL, YTRC)
                END IF
   70       CONTINUE
   80       CONTINUE
          END IF
      END IF
C
C Write X labels.
C
      IF (XOPTN .OR. XOPTM) THEN
          CALL PGBOX1(XBLC, XTRC, XINT, I1, I2)
          DO 90 I=I1,I2
              XC = (I*XINT-XBLC)/(XTRC-XBLC)
              IF (XOPTL) THEN
                  CALL PGNUMB(1,NINT(I*XINT),XNFORM,CLBL,NC)
              ELSE
                  CALL PGNUMB(I*NV,NP,XNFORM,CLBL,NC)
              END IF
              IF (XOPTN) CALL PGMTXT('B', XNDSP, XC, 0.5, CLBL(1:NC))
              IF (XOPTM) CALL PGMTXT('T', XMDSP, XC, 0.5, CLBL(1:NC))
   90     CONTINUE
      END IF
C
C Extra X labels for log axes.
C
      IF (XOPTLS) THEN
          CALL PGBOX1(XBLC, XTRC, XINT2, I1, I2)
          DO 401 I=I1-1,I2
             DO 301 J=2,5,3
                XVAL = (I+UTAB(J))*XINT2
                XC = (XVAL-XBLC)/(XTRC-XBLC)
                KI = I
                IF (XTRC.LT.XBLC) KI = KI+1
                IF (IRANGE(XBLC,XVAL,XTRC)) THEN
                    CALL PGNUMB(J,NINT(KI*XINT2),XNFORM,CLBL,NC)
                    IF (XOPTN) 
     1                CALL PGMTXT('B', XNDSP, XC, 0.5, CLBL(1:NC))
                    IF (XOPTM) 
     1                CALL PGMTXT('T', XMDSP, XC, 0.5, CLBL(1:NC))
                END IF
  301       CONTINUE
  401     CONTINUE
      END IF
C
C Length of Y tick marks.
C
      TIKL1 = PGXSP(PGID)*0.6*(XTRC-XBLC)/PGXLEN(PGID)
      IF (YOPTI) TIKL1 = -TIKL1
      TIKL2 = TIKL1*0.5
C
C Choose Y tick intervals. Major interval = YINT,
C minor interval = YINT2 = YINT/NSUBY.
C
      UTAB(1) = 0.0
      IF (YOPTL) THEN
          YINT = SIGN(1.0,YTRC-YBLC)
          NSUBY = 1
          DO 100 J=2,9
              UTAB(J) = TAB(J)
              IF (YINT.LT.0.0) UTAB(J) = 1.0-TAB(J)
  100     CONTINUE
      ELSE IF (YTICK.EQ.0.0) THEN
          YINT = MAX(0.05, MIN(7.0*PGXSP(PGID)/PGYLEN(PGID), 0.20))
     1           *(YTRC-YBLC)
          YINT = PGRND(YINT,NSUBY)
      ELSE
          YINT  = SIGN(YTICK,YTRC-YBLC)
          NSUBY = MAX(NYSUB,1)
      END IF
      IF (.NOT.YOPTS) NSUBY = 1
      NP = INT(LOG10(ABS(YINT)))-4
      NV = NINT(YINT/10.**NP)
      YINT2 = YINT/NSUBY
      YOPTLS = YOPTL .AND. YOPTS .AND. (ABS(YTRC-YBLC).LT.2.0)
C
C Draw Y grid.
C
      IF (YOPTG) THEN
          CALL PGBOX1(YBLC, YTRC, YINT, I1, I2)
          DO 110 I=I1,I2
           
              CALL GRMOVA(XBLC, REAL(I)*YINT)
              CALL GRLINA(XTRC, REAL(I)*YINT)
  110     CONTINUE
      END IF
C
C Draw Y ticks.
C
      IF (YOPTT.OR.YOPTS) THEN
          CALL PGBOX1(YBLC, YTRC, YINT2, I1, I2)
          JMAX = 1
          IF (YOPTL.AND.YOPTS) JMAX = 9
C
C               Left ticks.
C
            IF (YOPTB) THEN
            DO 130 I=I1-1,I2
c              write(*,*) I,I1, I2, I*YINT2
             if ((I*YINT2).lt.YSTART) goto 555 
            DO 120 J=1,JMAX
                MAJOR = (MOD(I,NSUBY).EQ.0).AND.YOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                YVAL = (I+UTAB(J))*YINT2
                IF (IRANGE(YBLC,YVAL,YTRC)) THEN
                    IF (YOPTP.AND.MAJOR) THEN
                        CALL GRMOVA(XBLC-TIKL2, YVAL)
                    ELSE
                        CALL GRMOVA(XBLC, YVAL)
                    END IF
                    CALL GRLINA(XBLC+TIKL, YVAL)
                END IF
  120       CONTINUE
  555       continue
  130       CONTINUE
            END IF
c
c lable the phase
c
                DO 131 I=-2,2
                MAJOR = I.EQ.0
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                 
                YVAL = (I+2)/12.*(ytrc-yblc)+yblc 
                  IF (MAJOR) THEN
                        CALL GRMOVA(XBLC, YVAL)
                    ELSE
                       CALL GRMOVA(XBLC, YVAL)
                    END IF
                    CALL GRLINA(XBLC+TIKL, YVAL)
c  lable phase
                
              if(I.eq.-1) then
              ylpmin=1./12.
              call pgmtext('L',YNDSP,ylpmin,0.5, '-100')
              end if
              if(I.eq.-1) then
              ylpmin=1./6.
              call pgmtext('L',YNDSP,ylpmin,0.5, '0')
              end if
            if(I.eq.-1) then
              ylpmin=1./4.
              call pgmtext('L',YNDSP,ylpmin,0.5, '100')
              end if
 
  131       CONTINUE

               
                 


               DO 132 I=-2,2
                MAJOR = I.EQ.0
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1

                YVAL = 1./3.*(I+2)/4.*(ytrc-yblc)+yblc
                  IF (MAJOR) THEN
                        CALL GRMOVA(XTRC-TIKL, YVAL)
                    ELSE
                       CALL GRMOVA(XTRC-TIKL, YVAL)
                    END IF
                    CALL GRLINA(XTRC, YVAL)
  132       CONTINUE



C
C               Axis ticks.
C
            IF (YOPTA) THEN
            DO 150 I=I1-1,I2
            DO 140 J=1,JMAX
                MAJOR = (MOD(I,NSUBY).EQ.0).AND.YOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                YVAL = (I+UTAB(J))*YINT2
                IF (IRANGE(YBLC,YVAL,YTRC)) THEN
                    CALL GRMOVA(-TIKL, YVAL)
                    CALL GRLINA(TIKL, YVAL)
                END IF
  140       CONTINUE
  150       CONTINUE
            END IF
C
C               Right ticks.
C
            IF (YOPTC) THEN
            DO 170 I=I1-1,I2
              if ((I*YINT2).lt.YSTART) goto 557
            DO 160 J=1,JMAX
                MAJOR = (MOD(I,NSUBY).EQ.0).AND.YOPTT.AND.J.EQ.1
                TIKL = TIKL2
                IF (MAJOR) TIKL = TIKL1
                YVAL = (I+UTAB(J))*YINT2
                IF (IRANGE(YBLC,YVAL,YTRC)) THEN
                    CALL GRMOVA(XTRC-TIKL, YVAL)
                    CALL GRLINA(XTRC, YVAL)
                END IF
  160       CONTINUE
  557       continue
  170       CONTINUE
            END IF
        END IF
C
C Write Y labels.
C
      IF (YOPTN.OR.YOPTM) THEN
          CALL PGBOX1(YBLC, YTRC, YINT, I1, I2)
          DO 180 I=I1,I2
              
              YC = (I*YINT-YBLC)/(YTRC-YBLC)
              if((I*YINT).lt.YSTART) goto 556
              IF (YOPTL) THEN
                  CALL PGNUMB(1,NINT(I*YINT),YNFORM,CLBL,NC)
              ELSE
                  CALL PGNUMB(I*NV,NP,YNFORM,CLBL,NC)
              END IF
              IF (YOPTV) THEN
                  IF (YOPTN) CALL PGMTXT('LV',YNVDSP,YC,1.0,CLBL(1:NC))
                  IF (YOPTM) CALL PGMTXT('RV',YMVDSP,YC,0.0,CLBL(1:NC))
              ELSE
                  IF (YOPTN) CALL PGMTXT('L',YNDSP,YC,0.5,CLBL(1:NC))
                  IF (YOPTM) CALL PGMTXT('R',YMDSP,YC,0.5,CLBL(1:NC))
              END IF
  556     continue
  180     CONTINUE
      END IF
                 ylpmax=2./3.
                 call pgmtext('L',3.*YNDSP,ylpmax,0.5, 'Amplitude (Jy)')
                 ylpmin=1./6.
                 call pgmtext('L',3.*YNDSP,ylpmin,0.5, 'Phase (Degree)')

C
C Extra Y labels for log axes.
C
      IF (YOPTLS) THEN
          CALL PGBOX1(YBLC, YTRC, YINT2, I1, I2)
          DO 402 I=I1-1,I2
            DO 302 J=2,5,3
                YVAL = (I+UTAB(J))*YINT2
                YC = (YVAL-YBLC)/(YTRC-YBLC)
                KI = I
                IF (YBLC.GT.YTRC) KI = KI+1
                IF (IRANGE(YBLC,YVAL,YTRC)) THEN
                    CALL PGNUMB(J,NINT(KI*YINT2),YNFORM,CLBL,NC)
                    IF (YOPTV) THEN
                    IF (YOPTN) 
     1                CALL PGMTXT('LV', YNVDSP, YC, 1.0, CLBL(1:NC))
                    IF (YOPTM) 
     1                CALL PGMTXT('RV', YMVDSP, YC, 0.0, CLBL(1:NC))
                    ELSE
                    IF (YOPTN) 
     1                CALL PGMTXT('L', YNDSP, YC, 0.5, CLBL(1:NC))
                    IF (YOPTM) 
     1                CALL PGMTXT('R', YMDSP, YC, 0.5, CLBL(1:NC))
                    END IF
                END IF
  302       CONTINUE
  402     CONTINUE
      END IF
C
C Enable clipping.
C
      CALL PGSCLP(CLIP)
C
      CALL PGEBUF
      END
