c************************************************************************
        program smauvspec
c
c= smauvspec - Plot averaged spectra of a visibility dataset.
c& jhz for SMA based on uvspec of rjs
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
c          bothA&P       Plot both amplitude and phase.
c	The default is axis=channel,amplitude.
c@ yrange
c	The min and max range along the y axis of the plots. The default
c	is to autoscale.
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
c  Bugs:
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
        include 'maxdim.h'
        integer maxco
        parameter (maxco=15)
c
        character version*(*)
        parameter(version='SmaUvSpec: version 1.1 1-DEC-04')
        character uvflags*8,device*64,xaxis*12,yaxis*12,logf*64
        character xtitle*64,ytitle*64
        logical ampsc,rms,nobase,avall,first,buffered,doflush,dodots
        logical doshift,doflag,doall,dolag
        double precision interval,t0,t1,preamble(4),shift(2),shft(2)
        integer tin,vupd, bsp(24)
        integer nxy(2),nchan,nread,nplot
        real yrange(2),inttime
        double precision x(2*maxchan-2)
        complex data(maxchan)
        logical flags(maxchan)
        integer hann
        real hc(maxco),hw(maxco)
        character in(1)*64
	character source*32
c
c  Externals.
c
        integer nextpow2
        logical uvdatopn,uvvarupd
c
c  Get the input parameters.
c
        call output(version)
        call keyini
        call mkeyf('vis',in,1,nin)
        call vishd(in)
        call keyini
        call getopt(uvflags,ampsc,rms,nobase,avall,dodots,doflag,doall)
        call getaxis(xaxis,yaxis)
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
           
c
c  Loop over the data.
c
          call uvdatrd(preamble,data,flags,maxchan,nread)
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
     *             'bothA&P'/
c
        call keymatch('axis',nx,xaxes,1,xaxis,n)
        if(n.eq.0)xaxis = xaxes(1)
        call keymatch('axis',ny,yaxes,1,yaxis,n)
        if(n.eq.0)yaxis = yaxes(1)
        end
c************************************************************************
        subroutine getopt(uvflags,ampsc,rms,nobase,avall,dodots,
     *          doflag,doall)
c
        logical ampsc,rms,nobase,avall,dodots,doflag,doall
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
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=10)
        character opts(nopts)*9
        logical present(nopts),docal,dopol,dopass
        data opts/'nocal    ','nopol    ','ampscalar','nopass   ',
     *            'nobase   ','avall    ','dots     ','rms      ',
     *            'flagged  ','all      '/
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
        integer count(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase
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
c
         include 'maxdim.h'
        integer maxaver,maxpol
        parameter(maxaver=276525,maxpol=4)
        complex buf(maxaver)
        real    bufr(maxaver),buf2(maxaver)
        integer count(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase
        integer polmin,polmax
        parameter(polmin=-8,polmax=4)
        integer maxplt,maxpnt
        parameter(maxpnt=32168,maxplt=1024)
        real xp(maxpnt),yp(maxpnt),xrange(2),inttime
        real ypp(maxpnt)
        integer plot(maxplt+1)
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
     *              nchan(i,j),
     *              doamp,doampsc,dorms,dophase,doreal,doimag,
     *              doboth,xp,yp,ypp,maxpnt,npnts)
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
     *          dopoint,hann,hc,hw,logf,doboth)
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
     *    pol,npol,dopoint,hann,hc,hw,logf,doboth)
c
c  Reset the counters.
c
        free = 1
        mbase = 0
c
        end
c************************************************************************
        subroutine visext(x,buf,buf2,bufr,count,nchan,
     *              doamp,doampsc,dorms,dophase,doreal,doimag,
     *              doboth,xp,yp,ypp,maxpnt,npnts)
c
        integer nchan,npnts,maxpnt,count(nchan)
        logical doamp,doampsc,dorms,dophase,doreal,doimag
        logical doboth
        real buf2(nchan),bufr(nchan),xp(maxpnt),yp(maxpnt)
        real ypp(maxpnt)
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
        integer count(maxaver)
        integer pnt(maxpol,maxbase),nchan(maxpol,maxbase),free,mbase
        integer npols(maxbase),pols(maxpol,maxbase),cnt(maxbase)
        integer cntp(maxpol,maxbase)
        double precision preamble(5,maxbase)
        common/uvavcom/preamble,buf,bufr,buf2,count,pnt,nchan,npols,
     *    pols,cnt,cntp,free,mbase
        integer i,i1,i2,p,bl,pol
        real t
        logical ok
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
     *            pol,npol,dopoint,hann,hc,hw,logf,doboth)
c
        integer npnts,bl,nplts,plot(nplts+1),npol,pol(npol),hann
        double precision time
        real xp(npnts),yp(npnts),xrange(2),yrange(2),inttime,hc(*),hw(*)
        real ypp(npnts)
        logical dopoint,dodots, doboth
        character xtitle*(*),ytitle*(*),logf*(*)
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
        real xlen,ylen,xloc
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
          call pgswin(xrange(1),xrange(2),yranged(1),yranged(2))
c          yrange(2)=yranged(2)
c          yrange(1)=yranged(1)
        else
          call pgswin(xrange(1),xrange(2),yrange(1),yrange(2))
        endif
         call setaxisr(ypp,npnts,ypranged)
c
        call pgbox('BCNST',0.,0.,'BCNST',0.,0.)
        do i=1,nplts

c   rescale the phase for plotting both
           do k=plot(i),plot(i+1)
          if(ypranged(2).gt.ypranged(1)) then
         ypp(k) = 0.85*(ypp(k)-ypranged(1))*(yranged(2)-yranged(1))/
     *         (ypranged(2)-ypranged(1))
            else
          call bug('f','the plotting range in phase is 0 degree!!')
          end if
          end do

          call  pgsci(i)
c          call pgsci(mod(i-1,ncol)+1)
          if(dopoint)then
          call pgpts(plot(i+1)-plot(i),xp(plot(i)),yp(plot(i)),symbol)
          else
            if (hann.gt.1) call hannsm(hann,hc,plot(i+1)-plot(i),
     *         yp(plot(i)),hw)
        call pghline(plot(i+1)-plot(i),xp(plot(i)),yp(plot(i)),
     *        ypp(plot(i)),2.0,doboth)
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
     *      pollab(1:lp)//' \\gt='//tau(lt:)//' min, T=',
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
     *      pollab(1:lp)//' \\gt='//tau(lt:)//' min, Bl='//
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
        subroutine pghline(npts,x,y,yp,gapfac,doboth)
        integer npts
        real x(npts), y(npts), yp(npts), gapfac
        REAL XPTS(npts), YPTS(npts)
        INTEGER N
c
c  Histogram style line plot of y-array versus x-array. Points are not
c  connected over gaps or reversals in the x-array.
c
c  Inputs:
c    npts	number of points
c    x		x-array to be plotted
c    y		y-array to be plotted
c    gapfac	factor to define a gap in x-array. E.g. 2= 2*(x(i+1)-x(i))
c
c--
c History
c    02nov89	mchw	original version
c    02apr94    nebk    add pgbbuf/pgebuf calls
c    24may94    mjs     reinserted Mel's docs
c-------------------------------------------------------------------------
        integer start,end,i,j, k, ci, l
        character title*64
        real xlen,ylen,xloc
        integer maxwin,symbol
        parameter(maxwin=48)
        logical gap,reverse, doboth
        integer nchan, nspect, nschan(maxwin)
        common/spectrum/nchan,nspect,nschan

c
c  Look for gaps or reversals in x-array
c
c        symbol=17
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
          do k=1, nschan(j)
               i=i+1
               N=N+1
               XPTS(k) = x(k+(j-1)*nschan(j))
               YPTS(k) = yp(k+(j-1)*nschan(j))
              
            if(i<npts.and.k<nschan(j)) then
              call pgdraw (0.5*(x(i+1)+x(i)), y(i))
              call pgdraw (0.5*(x(i+1)+x(i)), y(i+1))
            end if
             if(i<npts.and.i.eq.(j*nschan(j))) then
              call pgdraw (0.5*(x(i)+x(i)), y(i))
              call pgdraw (0.5*(x(i)+x(i)), y(i))
             endif
            call pgebuf
             if(i>npts) goto 555
          enddo
             end=i
             call pgdraw(x(end),y(end))
             start=end+1
             write(title,'(a,i2)') 's',j
               l = len1(title)
               call pglen(5,title(1:l),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/30.
              call pgmtxt('RV',1.0,yloc,0.,title(1:l))
          call pgebuf        
c          plot phase
           if(doboth) then
           call  pgsci(1)
           IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
           CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
           ELSE
           CALL GRDOT1(N,XPTS,YPTS)
           END IF
           CALL PGEBUF
           endif
           enddo        
555        continue 
c        call pgebuf
        end


CPGPT -- draw several graph markers
Cvoid cpgpt(int n, const float *xpts, const float *ypts, int symbol);
C
      SUBROUTINE PGPTS (N, XPTS, YPTS, SYMBOL)
      INTEGER N
      REAL XPTS(*), YPTS(*)
      INTEGER SYMBOL
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
C-----------------------------------------------------------------------
      LOGICAL PGNOTO
      integer j, k, ci, l
      character title*64
      real xlen,ylen,xloc
      integer   i,maxwin
      parameter(maxwin=48)
      integer nchan, nspect, nschan(maxwin)
      common/spectrum/nchan,nspect,nschan
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
          do k=1, nschan(j)
            i=i+1
          N=N+1
          XPTS(k) = XPTS(k+(j-1)*nschan(j))
          YPTS(k) = YPTS(k+(j-1)*nschan(j))
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
      character line*80,aval1*64,aval2*64,type*1,obstype*32
      integer il1,il2,length,nschan(maxwin),nchan,nspect,npol,pol,i
      integer nants,ival,ncorr,tno,n
      real epoch
      double precision sdf(maxwin),sfreq(maxwin),restfreq(maxwin)
      double precision time
      double precision obsra,obsdec,ra,dec,delra,deldec,pntra,pntdec
      real wwidth(maxwide),wfreq(maxwide)
      logical updated,present,more
      common/spectrum/nchan, nspect, nschan
c
c  Externals.
c
      integer len1
      character itoaf*8,polsc2p*2,hangleh*12,rangleh*12
      logical hdprsnt
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
        call uvrdvri(tno,'nchan',nchan,1)
        call uvrdvri(tno,'nspect',nspect,1)
        if(nspect.le.maxwin)then
        call uvgetvri(tno,'nschan',nschan,nspect)
        call uvgetvrd(tno,'sfreq',sfreq,nspect)
        call uvgetvrd(tno,'sdf',sdf,nspect)
        call uvgetvrd(tno,'restfreq',restfreq,nspect)
        endif
      call uvclose(tno)
c
      end

