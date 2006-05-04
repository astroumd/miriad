c************************************************************************
        program smagpplt
c
c= SmaGpPlt -- Plot,smooth and fit to gain and bandpass.
c& jhz for SMA
c: calibration
c+
c	SmaGpPlt is a MIRIAD task which plots and lists antenna gain and
c	bandbass. The plot for gains is against time. The
c	plot for bandpass is against the frequency. SmaGpPlt provides
c       options to moving smooth or orthogal polynomial fit to the
c       gain/bandpass solutions and to over write the old gain/bandpass
c       tables with the smoothed or polynomial fit results. In addition,
c       SmaGpPlt allows to compare bandpass solutions in two vis files.
c       SmaGpPlt can also merge two gain tables computed (using either
c       SmaMfCal or MfCal from two calibrators that were observed 
c       interleavely.
c            
c@ vis
c	The name of the input data-set. This will normally be a visibility
c	data-set. No default. If two files are given, options must be
c       either 'bandpass' or 'gains,merge'.
c@ device
c	The PGPLOT plotting device to use. The default is no plot.
c@ log
c	The log to give a listing of the gains and polarization terms. The
c	default is no log.
c@ yaxis
c	This specifies what is to be plotted/listed. Several values can be
c	given, separated by commas. Minimum match is used:
c	  amp	   Plot/list amplitudes. This is the default if the gains
c	           are being plotted/listed, and nothing else is requested.
c	  phase    Plot/list phases.
c	  real	   Plot/list the real parts. This is the default if the
c	           polarization terms are being plotted/listed, and nothing
c	           else is requested.
c	  imag     Plot/list the imaginary parts.
c	If nothing is given, "amp" is assumed.
c@ options
c	Some extra processing options can be given. Several values can be
c	given, separated by commas. Minimum match us used.
c	  gains	       Plot/list the gains vs time. This is the default if
c		       nothing else is requested.
c	  bandpass     Plot/list the bandpass shape vs frequency.
c	  dots         Plot things as dots (rather than chunky circles).
c	  dtime	       Give time in days and fractions of a day. This is more
c	               useful for listing files which are to be passed into
c	               some other analysis or plotting tool.
c	  wrap         Don't unwrap phase plots.
c         msmooth      Do moving average of the bandpass/gain curve using 
c		       the smooth parameters and replace old one.
c         weight       This gives weight in the orthogonal polynomial
c                      least-square fit to the antenna gain 
c                      curves.
c
c                      <1  => weight = 1, uniform weight.
c                       1 or greater  => weight = the sqaure of amplitude
c                         of 1/g, where g is a complex antenna gain
c                         derived within a solutional interval.
c                      The default is 1.
c
c         opolyfit     Do least-square fit to the bandpass/gain curves 
c                      with an orthogonal polynomial of degree n and replace 
c                      old one. Only one of the options is allowed in 
c                      the replacement of the gain/bandpass. Please choose
c                      either msmooth or opolyfit.
c         ratio        do ratio (bp1/bp2) in comparison of two bandpasse
c                      solutions if Keyword vis is given two input vis files. 
c                      The default is to compare the difference (bp2-bp1).
c         merge        merge two gain tables associated with the two
c                      visibility files respectively. Two input vis
c                      file must be given. The merged gain table
c                      will be placed in the second input vis file
c                      by overwritting on the old gain table.
c
c@ filelabel
c       This gives an option to label the file name in the plot:
c        filelabel = -1, not to label the file name, the default;
c        filelabel =  0, label the file name to each of panel plots;
c        filelabel =  1, label the file name to the 1st panel in
c                     the case of multiple panels.
c
c@ smooth
c       This gives three parameters of moving smooth calculation of the 
c       bandpass/gain curves
c       smooth(1) = K  parameter k giving the length 2k+1 of the averaging
c                      interval; default is 3.
c                      If smooth(1) =0, then polynomial fit will be
c                      taken.
c       smooth(2) = L  order of the averaging polynomial l; default is 3.
c       smooth(3) = P  probability P for computing the confidence limits;
c                      default is 0.9. 
c
c@ polyfit             
c       polyfit(1) gives a degree of orthogonal polynomial in least-sqaure 
c       fit to the bandpass/gain curves. Default is 0 (moving smooth).  
c       If polyfit(1)=0, then the moving average is taken.
c       If polyfit(2)>0, then the Chi-square parameters as function
c       of a polynomial order  1 (linear) , 2 (parabolic), 
c       3 (cubic), 4, 5 are reported for each antenna
c       and each spectral window. The minimum Chi-square corresponds to
c       the best fit in orthogonal polynomial regression.  
c@ nxy
c	Number of plots in the x and y directions. The default is 2,2.
c@ select
c	A subset of the normal uv-selection parameters. They are not
c	entirely consisently used. Antenna and time selection is supported
c	for gains. Time selection is supported for delay and spectral
c	correction. Antenna and frequency selection is supported for
c	bandpasses. The default is to select everything.
c@ yrange
c	The min and max range along the y axis of the plots. By default
c	gpplt autoscales. If the ``yrange'' parameter is given, then this
c	range is used on ALL plots. So it may not make much sense to
c	plot different sorts of quantities (e.g. amplitude and phases)
c	when explicitly giving the plot range.
c--
c  History:
c    JHZ  ----> cloned from calib/gpplt.for
c    jhz  30jul04 extends for SMA
c    jhz  30jul04 color coded the spectral windows
c    jhz  30jul04 add moving smooth
c    jhz  23sep04 add polynomial fit
c    jhz  20nov04 replace polynomial fit by orthogonal polynomial.
c    jhz  04jan05 add weight to polynomial fit.
c    jhz  27may05 fix the edge flagging problem.
c    jhz  31may05 fix the program name smapplt
c    jhz  01jun05 eliminate gpplt.h
c    pjt  01jun05 but re-introduced a clone as smagpplt.h
c    jhz  11jul05 but change the vis to allow accept two separate vis files;
c                 add options ratio to compare two bandpass solutions
c    jhz  12jul05 fix a bug in logwrite
c    jhz  14jul05 force the absolute values of the max and min in y
c                 range greater than 1e-18. In the case of auto range,
c                 smaller values may collapse the plot frame.
c    jhz  01aug05 add a gain pointer to distinguish the dual polarizations 
c                 in a gain table, count the gain solution for each polarization, 
c                 and skip the failed gain solutions in the polynomial fitting.
c                 label the circular polarizations in the case of
c                 dual polarizations involved.
c    jhz 18oct05 add an options for merging two gain tables.
c    jhz 19oct05 add a description in inline doc for options=merge
c                fixed a bug in ending x-window plot for
c                the case of more than one input files involved.
c    jhz 14feb06 fixed a bug in merging two gains
c    jhz 03may06 implemented polynomial fitting to amp&pha of 
c                the gain solutions.
c    jhz 03may06 fixed a bug in time selection.
c    jhz 04may06 added an input parameter (filelabel) for option
c                to label the file name.
c  Bugs:
c------------------------------------------------------------------------
        integer maxsels
        character version*(*)
        parameter(maxsels=256, maxspect=49)
        parameter (PI = 3.14159265358979323846)
        parameter (DPI = 3.14159265358979323846)
        parameter (TWOPI = 2 * PI)
        parameter (DTWOPI = 2 * DPI)        
        parameter(version='SmaGpPlt: version 1.8 04-May-06')
        include 'smagpplt.h'
        integer iostat,tin,nx,ny,nfeeds,nants,nsols,ierr,symbol,nchan
        integer ntau,length, i, j, k,nschann(maxspect)
        character vis*64,device*64,logfile*64,basetime*20
        double precision t0
        logical doamp,dophase,doreal,doimag,dogains,dopol,dodtime,doxy
        logical doxbyy,doplot,dolog,more,ltemp,dodots,dodelay,dopass
        logical dospec,dowrap, dosmooth, donply, doratio, domerge
        complex g1(maxgains),g2(maxgains)
        real alpha(maxgains)
        real times(maxtimes),range(2)
        real freqs(maxtimes)
        double precision jtime(6154)
        character feeds(3)*1
        real sels(maxsels)
c
c  Externals.
c
        logical hdprsnt
        integer pgbeg,len1
c linear feeds
c        data feeds/'I','X','Y'/
c circular feeds
        data feeds/'I','R','L'/
        integer pee(2),nfiles,lin,offset,nnsols(10,2),gns
        character ops*9
        logical uvdatopn
        complex pass(10,6145,2), gains(10,2,6145)
        real smooth(3), rpass(10,6145,2), ipass(10,6145,2)
        real apass(10,6145,2), ppass(10,6145,2)
        real smoothg(3), rgain(10,2,6145), igain(10,2,6145)
        integer nply(2), gnply, bnply, greport,breport, weight
        common/bsmooth/smooth,rpass,ipass,apass,ppass,bnply,breport
        common/gsmooth/smoothg,rgain,igain,gnply,greport,nnsols
        integer nants1, nfeeds1, nsols1
        integer nsols2,filelabel
        complex g2buf(maxgains),gbuf(maxgains)
        complex gf12(maxgains)
        real times1(maxtimes),times2(maxtimes)
        double precision t01,t02
        double precision jtime1(6154),jtime2(6154)
c
c  Get the user parameters.
c
            nfile=0
        call output(version)
        call keyini
c       ops = 'sdlp'
        ops = ' '
        call uvdatinp ('vis', ops)
        if(vis.eq.' ')call bug('f','Input data-set must be given')
        call keya('device',device,' ')
        doplot = device.ne.' '
        call keya('log',logfile,' ')
        dolog = logfile.ne.' '
        if(.not.(dolog.or.doplot))
     *    call bug('f','One of the device and log must be given')
        call getaxis(doamp,dophase,doreal,doimag)
        call getopt(dogains,doxy,doxbyy,dopol,dodtime,dodots,
     *    dodelay,dospec,dopass,dowrap,dosmooth,donply,doratio,
     *    domerge)
         if(dosmooth.and.dopass) then
              if(doamp) dophase=.true.
              if(dophase) doamp=.true.
              if(doreal) doimag=.true.
              if(doimag) doreal=.true.
         end if  

        call keyr('smooth',smooth(1), 3.)
        call keyr('smooth',smooth(2), 3.)
        call keyr('smooth',smooth(3), 0.9)
               do i=1,3
               smoothg(i) = smooth(i)
               end do 
        call keyi('weight', weight, 1)
        call keyi('filelabel', filelabel, -1)
        if(donply) smooth(1)=0
        call keyi('polyfit', nply(1), 0)
        call keyi('polyfit', nply(2), 0)
        if(dosmooth) nply(1)=0
        if(donply.and.(nply(1).eq.0)) 
     &  call bug('f', 'assign polyfit(1) a possitive integer.')
        if(dosmooth.and.(smooth(1).eq.0))
     &  call bug('f', 'assign smooth(1) a possitive integer.')
 
c
c number of polynomial term = degree of polynomial +1
c
c
c check make sure no conflict in smooth and polynormial fit
c
        if((smooth(1).eq.0).and.(nply(1).eq.0)) then
	 call bug('f','assign smooth(1) a number instead of 0 if 
     &moving smooth averag is chosen; otherwise assign polyfit a number
     &rather than 0.')
          end if 
        if(dopass) then 
           bnply=nply(1)
           breport=nply(2)
           end if
        if(dogains) then 
           gnply=nply(1)
           greport=nply(2) 
            end if         
        call keyi('nxy', nx, 0)
        call keyi('nxy', ny, 0)
        if(nx.ne.0.and.ny.eq.0)then
          ny = nx
          else if(nx.eq.0.and.ny.eq.0)then
          nx = 3
          ny = 2
        endif
        if(nx.le.0.or.ny.le.0)
     *    call bug('f','Bad value for nxy')
        call selinput('select',sels,maxsels)
        call keyr('yrange',range(1),0.)
        call keyr('yrange',range(2),range(1)-1.)
        call keyfin
            call uvdatgti ('nfiles', nfiles)
            if(nfiles.gt.2)
     *   call bug('f','Too many uv files.')
            if((.not.dopass.and.nfiles.gt.1)
     *          .and.(.not.domerge.and.nfiles.gt.1))
     *   call bug('f','Too many uv files.')
              if(domerge.and.nfiles.lt.2)
     *   call bug('f','Need two uv files.')

c
c  Determine the plotting symbol.
c
        symbol = 17
        if(dodots) symbol = 1
c
c  Fill in the defaults.
c
        if(.not.(dogains.or.doxy.or.doxbyy.or.dopol.or.
     *          dodelay.or.dopass.or.dospec))dogains = .true.
        if(.not.(doamp.or.dophase.or.doreal.or.doimag))doamp = .true.
c
c  Open up all the inputs.
c
        if(nfiles.ge.2) then
            do lin= 1, nfiles
            if(.not.uvdatopn(tin))call bug('f','Error opening inputs')
            call uvdatgta ('name', vis)
            write(*,*) lin,':file', vis
            call uvdatcls         
            call hopen(tin,vis,'old',iostat)
            if(iostat.ne.0)then
            call bug('w','Error opening input '//vis)
            call bugno('f',iostat)
             endif
          if(dopass)then
           dopass = hdprsnt(tin,'bandpass')
           if(.not.dopass)call bug('w','Bandpass function not present')
          endif
          if(doplot)then
           length = len1(device)
           ierr = pgbeg(0,device(1:length),nx,ny)
          if (ierr.ne.1)then
           call pgldev
           call bug ('f', 'Error in PGPLOT device')
          endif
          call pgsch(real(max(nx,ny))**0.4)
          endif
       if(dolog.and.(lin.eq.1)) call logopen(logfile,' ')
       if(dolog) call logwrite('# file:'//vis,more)
       if(dolog.and.(lin.eq.2).and.doratio) 
     * call logwrite('# bandpass ratio for above two files',more)
       if(dolog.and.(lin.eq.2).and.(.not.doratio.and..not.domerge))
     * call logwrite('# bandpass difference for above two files',more) 
       if(dopass)then
          call bload(tin,times,g1,nfeeds,nants,nchan,sels,
     *          maxgains,maxtimes,nschann)
            do i=1, nants
            do j=1, nfeeds
            peeds =j
            offset = (j-1) + (i-1)*nfeeds
            do k=1, nchan
            if(lin.eq.1) then 
                  pass(i,k,j) = g1(k+offset*nchan)
                  freqs(k)=times(k)
                  endif
            if(lin.eq.2) then
            if(.not.doratio) g1(k+offset*nchan)= 
     *      g1(k+offset*nchan)-pass(i,k,j)
            if(doratio)
     *   g1(k+offset*nchan)= pass(i,k,j)/g1(k+offset*nchan)             
c           call bug('f','inconsistent frequency between the two files')
                 endif
            end do
            end do
            end do
          if(lin.eq.2) 
     *     call bpplt(vis,times,g1,nfeeds,nants,nchan,range,
     *          feeds(nfeeds),doamp,dophase,dowrap,doreal,doimag,
     *          doplot,dolog,symbol,nx*ny,nschann,donply,dosmooth,
     *          filelabel)
         endif
             
        if(dolog.and.(lin.eq.2).and.domerge)
     * call logwrite('# merge two gain tables from two files',more)

c
c  merge two gain tables
c
        if(dogains) then
            if(lin.eq.1) then 
        call gload(tin,t01,times1,jtime1,g1,nfeeds1,ntau,nants1,
     *      nsols1,sels, maxgains,maxtimes) 
            
            call gncvt(g1,g2buf,nfeeds1,ntau,nants1*nsols1)

                         end if
            if(lin.eq.2) then
        call gload(tin,t02,times2,jtime2,g1,nfeeds,ntau,nants,
     *      nsols2,sels, maxgains,maxtimes)
            call gncvt(g1,g2,nfeeds,ntau,nants*nsols2)
            if(t01.ne.t02) 
     *      call bug('f',
     *  'The two gain tables  do not match in the basetime.');
            if(nfeeds1.ne.nfeeds) 
     *      call bug('f',
     *  'The two gain tables do not match in the number of feeds.');
            if(nants1.ne.nants) 
     *      call bug('f',
     *  'The two gain tables do not match in the number of antennas.'); 
             
            nsols= nsols1+nsols2 
            do ifeed=1,nfeeds
            do j=1,nants
            offset = ifeed + (j-1)*nfeeds
c handle lin=1
            do i=1,nsols1
            gf12(i)  = g2buf(offset+(i-1)*nfeeds*nants)
            times(i) = times1(i)
            jtime(i) = jtime1(i)
            end do
c handle lin=2 and merge g2 to g1
            do i=1,nsols2
            gf12(i+nsols1) = g2(offset+(i-1)*nfeeds*nants)
            times(i+nsols1) = times2(i)
            jtime(i+nsols1) = jtime2(i)
            end do
c sorting gbuf based on the order of ascending time 
            call xysortcd(nsols1+nsols2,times,gf12,jtime)
c put back to gbuf
            do i=1,nsols
            gbuf(offset+(i-1)*nfeeds*nants) = gf12(i)
            rgain(j,ifeed,i)=real(gf12(i)) 
            igain(j,ifeed,i)=aimag(gf12(i))
            end do
            end do
            end do 
            end if
            endif
          end do
c
c plot the gains
c
          if(dogains) 
     *       call gainplt(vis,times,gbuf,nfeeds,nants,nsols,range,
     *       feeds(nfeeds),doamp,dophase,dowrap,doreal,doimag,
     *       doplot,dolog,dodtime,donply,dosmooth,
     *       symbol,nx*ny,weight,filelabel)
          if(dolog) call logclose

c assign the nsols (maximun nsols for each set of ant/feed)
c to gns
          gns = nsols
c
c Apply the polyfit or smooth to the gain table
c
c          if((donply.or.dosmooth).and.dogains) then
           if(dogains) then
           do i=1, nants
           do j=1, nfeeds
           do k=1,gns
           gains(i,j,k)=0.0
           enddo
           enddo
           enddo
           do i=1, nants
           do j=1, nfeeds
           pee(j) =j
           do k=1,gns
           gains(i,j,k) = cmplx(rgain(i,j,k),igain(i,j,k))
            end do
            end do
            end do
          call hdelete(tin,'gains',iostat)
          write(*,*) 'delete the old gains table'
          call gaintab(tin,jtime,gains,nfeeds,nants,gns,
     *    pee)
          end if
          if(doplot)call pgend
          call hclose(tin)
          stop
        endif

        if(.not.uvdatopn(tin))call bug('f','Error opening inputs')
            call uvdatgta ('name', vis)
            call uvdatcls
        call hopen(tin,vis,'old',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening input '//vis)
          call bugno('f',iostat)
        end if


c
c  Check for the needed tables.
c
        if(dopass)then
          dopass = hdprsnt(tin,'bandpass')
          if(.not.dopass)call bug('w','Bandpass function not present')
        endif
c
        if(dopol)then
          dopol = hdprsnt(tin,'leakage')
          if(.not.dopol)call bug('w',
     *          'Polarization leakage table not present')
        endif
c
        if(dogains.or.doxy.or.doxbyy.or.dodelay.or.dospec)then
          ltemp = hdprsnt(tin,'gains')
          if(ltemp) ltemp = hdprsnt(tin,'ngains')
          if(.not.ltemp)then
            call bug('w',
     *          'Antenna gains information not present')
            dogains = .false.
            doxy = .false.
            doxbyy = .false.
            dodelay = .false.
            dospec = .false.
          else if(doxy.or.doxbyy)then
            call rdhdi(tin,'nfeeds',nfeeds,1)
            doxy = nfeeds.eq.2.and.doxy
            doxbyy = nfeeds.eq.2.and.doxbyy
            if(nfeeds.ne.2)call bug('w',
     *          'Cannot compute XY gains from a single set of gains')
          else if(dodelay.or.dospec)then
            call rdhdi(tin,'ntau',ntau,0)
            if(ntau.eq.0)then
              call bug('w',
     *          'Delays/spectral correction not present in gains')
              dodelay = .false.
              dospec = .false.
            endif
          endif
        endif
        if(.not.(dodelay.or.dospec.or.dopol.or.doxy.or.doxbyy.or.
     *    dogains.or.dopass))
     *    call bug('f','Requested options cannot be performed')
c
c  Open up the other devices now that we think everything looks OK.
c
        if(doplot)then
          length = len1(device)
          ierr = pgbeg(0,device(1:length),nx,ny)
          if (ierr.ne.1)then
            call pgldev
            call bug ('f', 'Error in PGPLOT device')
          endif
          call pgsch(real(max(nx,ny))**0.4)
        endif
       if(dolog)then
          call logopen(logfile,' ')
          call logwrite('# Gain/Polarization listing for '//vis,more)
        endif
c
c  Do the gain plots.
c
        if(dogains.or.doxy.or.doxbyy.or.dodelay.or.dospec)then
          call gload(tin,t0,times,jtime, g1,nfeeds,ntau,nants,
     *      nsols,sels, maxgains,maxtimes)
c         write(*,*) 'gload',nsols,nants,nfeeds
          if(.not.dodtime)call tscale(times,nsols)
          call julday(t0,'H',basetime)
          call output('The base time is '//basetime)
          if(dolog)
     *      call logwrite('# The base time is '//basetime,more)
          if(dogains)then
         call gncvt(g1,g2,nfeeds,ntau,nants*nsols)
         call gainplt(vis,times,g2,nfeeds,nants,nsols,range,
     *       feeds(nfeeds),doamp,dophase,dowrap,doreal,doimag,
     *       doplot,dolog,dodtime,donply,dosmooth,
     *       symbol,nx*ny,weight,filelabel)           
          endif
c
c the memory of nsols appears to be changed
c when the actually array size of the gains
c is changed
c assign the nsols (maximun nsols for each set of ant/feed)
c to gns
           gns = nsols
c
c Apply the smooth to the gain table
c
         if((donply.or.dosmooth).and.dogains) then

c 
c the memory of nsols appears to be changed
c when the actually array size of the gains 
c is changed
          
           do i=1, nants
           do j=1, nfeeds
           do k=1,gns
           gains(i,j,k)=0.0
           enddo
           enddo
           enddo    

           do i=1, nants
           do j=1, nfeeds
           pee(j) =j
           do k=1,gns 
c           if (nnsols(i,j).gt.0) 
            gains(i,j,k) = cmplx(rgain(i,j,k),igain(i,j,k))
            end do
            end do
            end do
          call hdelete(tin,'gains',iostat)
          write(*,*) 'delete the old gains table'
c
          call gaintab(tin,jtime,gains,nfeeds,nants,gns,
     *    pee)          

          end if

          if(doxy)then
            call xycvt(g1,g2,nfeeds,ntau,nants*nsols,.true.)
            call gainplt(vis,times,g2,1,nants,nsols,range,
     *          'XY',doamp,dophase,dowrap,doreal,doimag,
     *          doplot,dolog,dodtime,donply,dosmooth,
     *          symbol,nx*ny,weight,filelabel)
          endif
          if(doxbyy)then
            call xycvt(g1,g2,nfeeds,ntau,nants*nsols,.false.)
            call gainplt(vis,times,g2,1,nants,nsols,range,
     *          'X*Y',doamp,dophase,dowrap,doreal,doimag,
     *          doplot,dolog,dodtime,donply,dosmooth,
     *          symbol,nx*ny,weight,filelabel)
          endif
          if(dodelay)then
            call alphacvt(g1,alpha,nfeeds,ntau,nants*nsols,.true.)
            call alphaplt(vis,times,alpha,nants,nsols,range,
     *          'Delay (nsec)',
     *          doplot,dolog,dodtime,symbol,nx*ny)
          endif
          if(dospec)then
            call alphacvt(g1,alpha,nfeeds,ntau,nants*nsols,.false.)
            call alphaplt(vis,times,alpha,nants,nsols,range,
     *          'Spectral Correction',
     *          doplot,dolog,dodtime,symbol,nx*ny)
          endif
        endif
c
c  Do the bandpass plots.
c
        if(dopass)then
          call bload(tin,times,g1,nfeeds,nants,nchan,sels,
     *          maxgains,maxtimes,nschann)
          call bpplt(vis,times,g1,nfeeds,nants,nchan,range,
     *          feeds(nfeeds),doamp,dophase,dowrap,doreal,doimag,
     *          doplot,dolog,symbol,nx*ny,nschann,
     *          donply,dosmooth,filelabel)
        endif
            
c
c Apply the polynomial fit or smooth
c
        if((donply.or.dosmooth).and.dopass) then
        do i=1, nants
c              write(*,*)
           do j=1, nfeeds
            pee(i) =j
            do k=1, nchan
            if(doamp.or.dophase) then
            rpass(i,k,j)=apass(i,k,j)*cos(ppass(i,k,j)*pi/180.)
            ipass(i,k,j)=apass(i,k,j)*sin(ppass(i,k,j)*pi/180.)
            end if
            pass(i,k,j) = cmplx(rpass(i,k,j),ipass(i,k,j))
c               write(*,*) 'pass g', pass(i,k,j), g1(k+(i-1)*nchan)
              end do
           end do
        end do
          call hdelete(tin,'bandpass',iostat)
          write(*,*) 'delete the old bandpass table'
         
          call passtab(tin,nfeeds,nants,nchan,
     *    pass,pee)
         end if
c        
c  Do the polarization leakage term plots.
c
        if(dopol)then
          if(dolog)call logwrite('# Polarization Information',more)
          call pload(tin,g1,nfeeds,nants,maxgains)
          call polplt(g1,nfeeds,nants,range,feeds(nfeeds),
     *          doamp,dophase,doreal,doimag,doplot,dolog,symbol)
        endif
c
c  Close up now.
c
        if(doplot)call pgend
        if(dolog) call logclose
        call hclose(tin)
        end
c************************************************************************
        subroutine gload(tin,t0,time,jtime,g,nfeeds,ntau,nants,
     *    nsols,sels,maxgains,maxtimes)
c
        integer tin,nfeeds,nants,ntau,nsols,maxgains,maxtimes
        complex g(maxgains)
        real time(maxtimes),sels(*)
        double precision t0, jtime(6145)
c
c  Load the antenna gains.
c
c  Input:
c    tIn
c    maxGains
c    maxTimes
c  Output:
c    T0		Base time, as a Julian date.
c    time	Offset Julian date.
c    G		The antenna gains.
c    nfeeds	Number of feeds (1 or 2).
c    ntau	Number of delay/spec corr terms (0 or 1).
c    nants	Number of antennas.
c    nsols	Number of solution intervals.
c-----------------------------------------------------------------------_
        integer item,iostat,offset,i,k,ngains
        double precision t
        logical doselect,select
c
c  Externals.
c
        integer hsize
        logical selprobe
c
c  Determine the various parameters, and check their validity. We have pretty
c  well checked that all is OK before, so nothing should go wrong.
c
        doselect = selprobe(sels,'time?',0.d0)
        call rdhdi(tin,'nfeeds',nfeeds,1)
        call rdhdi(tin,'ntau',ntau,0)
        call rdhdi(tin,'ngains',ngains,1)
        call rdhdi(tin,'nsols',nsols,1)
        if(nfeeds.le.0.or.ntau.lt.0.or.ngains.le.0.or.nsols.le.0)
     *    call bug('f','Bad gain table size information')
        nants = ngains / (nfeeds + ntau)
        if(nants*(nfeeds+ntau).ne.ngains)
     *    call bug('f','Number of gains does equal nants*(nfeeds+ntau)')
        if((nfeeds+ntau)*nants*nsols.gt.maxgains)call bug('f',
     *    'Too many gains for me')
        if(nsols.gt.maxtimes)call bug('f',
     *    'Too many solution intervals for me')
c
        call haccess(tin,item,'gains','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the gains table')
          call bugno('f',iostat)
        endif
c
c  Determine what we thing the number of solutions should be from the
c  size of the file.
c
        if(hsize(item).ne.8+(ngains+1)*8*nsols)
     *    call bug('f','Gain table does not look the right size')
c
c  All is OK. Lets go for it.
c
        k = 0
        offset = 8
        do i=1,nsols
          call hreadd(item,t,offset,8,iostat)
          if(iostat.ne.0)call bugno('f',iostat)
          offset = offset + 8
          if(doselect)then
            select = selprobe(sels,'time',t)
          else
            select = .true.
          endif
          if(select)then
            k = k + 1
            if(k.eq.1) t0 = nint(t - 1.d0) + 0.5d0
            jtime(k)=t
            time(k) = t - t0
            call hreadr(item,g((k-1)*ngains+1),offset,8*ngains,iostat)
            if(iostat.ne.0)call bugno('f',iostat)
          endif
          offset = offset + 8*ngains
        enddo
        if(k.eq.0)call bug('f','No gains selected')
        nsols = k
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Blank out the antenna gains that were not selected.
c
        if(selprobe(sels,'antennae?',0.d0))
     *    call antgsel(sels,g,nfeeds,ntau,nants,nsols)
        end
c************************************************************************
        subroutine antgsel(sels,g,nfeeds,ntau,nants,nsols)
c
        integer nfeeds,ntau,nants,nsols
        real sels(*)
        complex g(nfeeds+ntau,nants,nsols)
c
c  Blank out any antennas that were not selected.
c
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer i,j,k
        logical ant(maxant)
c
c  Externals.
c
        logical selprobe
c
c  Determine which antennas were selected.
c
        do i=1,nants
          ant(i) = selprobe(sels,'antennae',257.d0*i)
        enddo
c
c  Now blank out the unwanted antennas.
c
        do k=1,nsols
          do j=1,nants
            if(.not.ant(j))then
              do i=1,nfeeds
                g(i,j,k) = 0
              enddo
            endif
          enddo
        enddo
c
        end
c************************************************************************
        subroutine bload(tin,freq,gains,nfeeds,nants,nchan,sels,
     *    maxpass,maxfreq,nschann)
c
        integer tin,nants,nchan,maxpass,maxfreq,nfeeds
        real freq(maxfreq),sels(*)
        complex gains(maxpass)
c
c  Load the bandpass shapes.
c
c  Input:
c    tIn
c    maxPass	Max number of gains that can be handled.
c    maxfreq	Max number of frequencies that can be handled.
c  Output:
c    nants
c    nfeeds
c    nchan
c    freq
c    Gains
c------------------------------------------------------------------------
        include 'smagpplt.h'
        integer ngains,nspect,item,iostat,n,off,nschan,i,j,k,offi,offo
        parameter(maxspect=49)
        integer ntau,nschann(maxspect)
        double precision freqs(2)
        logical doselect,select(maxtimes)
c
c  Externals.
c
        logical selprobe
c
        call rdhdi(tin,'nfeeds',nfeeds,1)
        call rdhdi(tin,'ngains',ngains,1)
        call rdhdi(tin,'ntau',ntau,0)
        call rdhdi(tin,'nchan0',nchan,0)
        call rdhdi(tin,'nspect0',nspect,0)
        if(nfeeds.le.0.or.ngains.le.0)
     *    call bug('f','Bad gain table size information')
        nants = ngains / (nfeeds+ntau)
        if(nants*(nfeeds+ntau).ne.ngains)
     *    call bug('f','Number of gains does equal nants*nfeeds')
        if(nchan.gt.min(maxfreq,maxtimes).or.nchan.le.0)call bug('f',
     *    'Bad number of frequencies')
        if(nspect.le.0.or.nspect.gt.nchan)call bug('f',
     *    'Bad number of frequency spectral windows')
        if(nfeeds*nants*nchan.gt.maxpass)call bug('f',
     *    'Too many gains for me')
c
        doselect = selprobe(sels,'frequency?',0.d0)
c
c  Read the frequency table.
c
        call haccess(tin,item,'freqs','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the bandpass frequency table')
          call bugno('f',iostat)
        endif
c
        n = 0
        off = 8
        do i=1,nspect
          call hreadi(item,nschan,off,4,iostat)
              nschann(i)=nschan
          off = off + 8
          if(iostat.eq.0)call hreadd(item,freqs,off,2*8,iostat)
          off = off + 2*8
          if(iostat.ne.0)then
            call bug('w','Error reading bandpass frequency table')
            call bugno('f',iostat)
          endif
          do j=1,nschan
            n = n + 1
            freq(n) = freqs(1) + (j-1)*freqs(2)
            select(n) = .not.doselect.or.
     *                  selprobe(sels,'frequency',dble(freq(n)))
          enddo
        enddo
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Read the bandpass table now.
c
        call haccess(tin,item,'bandpass','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the bandpass table')
          call bugno('f',iostat)
        endif
c
        off = 8
        call hreadr(item,gains,off,8*nants*nfeeds*nchan,iostat)
        if(iostat.ne.0)then
          call bug('w','Error reading the bandpass table')
          call bugno('f',iostat)
        endif
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Take the reciprocal of the gains.
c
        offi = 0
        do k=1,nants
          do j=1,nfeeds
            do i=1,nchan
              offi = offi + 1
              if(abs(real(gains(offi)))+abs(aimag(gains(offi))).gt.0)
     *          gains(offi) = 1/gains(offi)
            enddo
          enddo
        enddo
c
c  Perform frequency selection, if needed.
c
        if(doselect)then
          offo = 0
          offi = 0
          do k=1,nants
            do j=1,nfeeds
              do i=1,nchan
                offi = offi + 1
                if(select(i))then
                  offo = offo + 1
                  gains(offo) = gains(offi)
                endif
              enddo
            enddo
          enddo
c
          offo = 0
          do j=1,nchan
            if(select(j))then
              offo = offo + 1
              freq(offo) = freq(j)
            endif
          enddo
          nchan = offo
          if(nchan.eq.0)call bug('f','No channels selected')
        endif
c
c  Blank out the unwanted antennas.
c
        if(selprobe(sels,'antennae?',0.d0))
     *    call antbsel(sels,gains,nchan*nfeeds,nants)
c
        end
c************************************************************************
        subroutine antbsel(sels,g,n,nants)
c
        integer n,nants
        real sels(*)
        complex g(n,nants)
c
c  Blank out any antennas that were not selected.
c
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer i,j
        logical ant(maxant)
c
c  Externals.
c
        logical selprobe
c
c  Determine which antennas were selected.
c
        do i=1,nants
          ant(i) = selprobe(sels,'antennae',257.d0*i)
        enddo
c
c  Now blank out the unwanted antennas.
c
        do j=1,nants
          if(.not.ant(j))then
            do i=1,n
              g(i,j) = 0
            enddo
          endif
        enddo
c
        end
c************************************************************************
        subroutine pload(tin,leaks,nfeeds,nants,maxleaks)
c
        integer tin,nfeeds,nants,maxleaks
        complex leaks(2,maxleaks)
c
c  Load the polarisation leakage table.
c
c------------------------------------------------------------------------
        integer item,iostat
c
c  Externals.
c
        integer hsize
c
        call haccess(tin,item,'leakage','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the leakage table')
          call bugno('f',iostat)
        endif
c
c  Determine the number of antennas.
c
        nfeeds = 2
        nants = (hsize(item)-8)/16
        if(nants.le.0.or.nants.gt.maxleaks)
     *    call bug('f','Illegal number of leakage parameters')
c
c  Now read them in.
c
        call hreadr(item,leaks,8,8*nants*nfeeds,iostat)
        if(iostat.ne.0)then
          call bug('w','I/O error while reading the leakage tabele')
          call bugno('f',iostat)
        endif
c
c  And close up.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
        end
c************************************************************************
        subroutine alphaplt(vis,time,alpha,nants,nsols,range,
     *                  ylabel,
     *                  doplot,dolog,dodtime,symbol,ppp)
c
        integer nants,nsols,symbol,ppp
        real time(nsols),range(2)
        real alpha(nants*nsols)
        character ylabel*(*),vis*(*)
        logical doplot,dolog,dodtime
c
c  Do the plot or the listing.
c
c  Inputs:
c------------------------------------------------------------------------
        include 'smagpplt.h'
        character line*80,title*48
        logical more
        real y(maxtimes)
        integer iday,ihr,imin,isec,i,j,j1,offset,k,length
c
c  Externals.
c
        character itoaf*3
        integer len1
c
c  Do the plots.
c
        if(doplot)then
          do j=1,nants
            call alpick(alpha(j),nants,nsols,y)
            call setpg(time(1),time(nsols),y,nsols,range,dodtime)
            call pgpts(nsols,time,y,symbol)
            title = 'Antenna '//itoaf(j)//'File='//vis
            length = len1(title)
            call pglab('Time',ylabel,title(1:length))
          enddo
          call subfill(nants,ppp)
        endif
c
c  Write the needed data to the listing file.
c
        if(dolog)then
          offset = 0
          do k=1,nsols
            if(k.eq.1)then
              line = '# Listing of '//ylabel
              call logwrite(line,more)
              line = '# Number of antennas: '//itoaf(nants)
              call logwrite(line,more)
            endif
            do j=1,nants,6
              j1 = min(j+5,nants)
              if(j.eq.1)then
                if(dodtime)then
                  write(line(1:12),'(f11.6)')time(k)
                else
                  isec = nint(time(k))
                  iday = isec/(24*3600)
                  isec = isec - 24*3600*iday
                  ihr  = isec/3600
                  isec = isec - 3600*ihr
                  imin = isec / 60
                  isec = isec - 60*imin
                  write(line(1:12),'(i2,a,i2.2,a,i2.2,a,i2.2)')
     *                  iday,' ',ihr,':',imin,':',isec
                endif
              else
                line(1:12) = ' '
              endif
              write(line(13:80),'(6g11.3)')
     *                  (alpha(i),i=offset+j,offset+j1)
              call logwrite(line,more)
            enddo
            offset = offset + nants
          enddo
        endif
        end
c************************************************************************
        subroutine alpick(alpha,nants,nsols,y)
c
        integer nants,nsols
        real alpha(nants,nsols),y(nsols)
c------------------------------------------------------------------------
        integer i
        do i=1,nsols
          y(i) = alpha(1,i)
        enddo
        end
c************************************************************************
        subroutine polplt(leaks,nfeeds,nants,range,feeds,
     *          doamp,dophase,doreal,doimag,doplot,dolog,symbol)
c
        integer nants,nfeeds,symbol
        logical doamp,dophase,doreal,doimag,doplot,dolog
        complex leaks(nfeeds*nants)
        character feeds(nfeeds)*(*)
        real range(2)
c
c------------------------------------------------------------------------
c
c
c  Externals.
c
        real getamp,getphasw,getreal,getimag
        external getamp,getphasw,getreal,getimag
c
        if(doamp)  call polplt2(leaks,nfeeds,nants,range,'Amp',feeds,
     *    doplot,dolog,symbol,getamp)
        if(dophase)call polplt2(leaks,nfeeds,nants,range,'Phase',feeds,
     *    doplot,dolog,symbol,getphasw)
        if(doreal) call polplt2(leaks,nfeeds,nants,range,'Real',feeds,
     *    doplot,dolog,symbol,getreal)
        if(doimag) call polplt2(leaks,nfeeds,nants,range,'Imag',feeds,
     *    doplot,dolog,symbol,getimag)
        end
c************************************************************************
        subroutine gainplt(vis,time,g,nfeeds,nants,nsols,range,
     *    feeds,doamp,dophase,dowrap,doreal,doimag,doplot,dolog,
     *    dodtime,donply,dosmooth,symbol,ppp,weight,filelabel)
c
        integer nfeeds,nants,nsols,ppp,symbol,filelabel
        complex g(nfeeds*nants*nsols)
        real time(nsols),range(2)
        logical doamp,dophase,dowrap,doreal,doimag,doplot,dolog,dodtime
        logical donply,dosmooth
        character feeds(nfeeds)*(*),vis*(*)
c
c  Plot/list the antenna gains.
c
c  Input:
c    nfeeds	Number of polarization feeds.
c    nants	Number of antennas.
c    nsols	Number of solutions.
c    time	The offset time of each solution.
c    G		The gains
c    range	Range along Y axis for plots.
c    Feeds	Used to form labels and descriptions.
c    doamp,dophase,doreal,doimag If true, the do the corresponding
c		plot/listing.
c    dowrap	Do not attempt to unwrap the phases.
c    doplot,dolog If true, do a plot or write the table.
c    symbol	Plotting symbol.
c    dodtime	Give time in fractions of a day.
c    ppp	Plots per page.
c    vis	File name.
c------------------------------------------------------------------------
c
c  Externals.
c
        real getamp,getphase,getphasw,getreal,getimag
        external getamp,getphasw,getphase,getreal,getimag
        integer weight
c
       if(doamp) call gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *   'Amp',feeds,doplot,dolog,dodtime,donply,dosmooth, 
     *   symbol,getamp,ppp,weight,filelabel)
        if(dophase)then
        if(dowrap)then
            call gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *  'Phase',feeds,doplot,dolog,dodtime,donply,dosmooth,
     *   symbol,getphasw,ppp,weight,filelabel)
          else
            call gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *  'Phase',feeds,doplot,dolog,dodtime,donply,dosmooth,
     *   symbol,getphase,ppp,weight,filelabel)
          endif
        endif
       if(doreal) call gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *  'Real',feeds,doplot,dolog,dodtime,donply,dosmooth,
     *   symbol,getreal,ppp,weight,filelabel)
        if(doimag) call gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *  'Imag',feeds,doplot,dolog,dodtime,donply,dosmooth,
     *  symbol,getimag,ppp,weight,filelabel)
        end
c************************************************************************
        subroutine bpplt(vis,freq,g,nfeeds,nants,nchan,range,
     *    feeds,doamp,dophase,dowrap,doreal,doimag,doplot,dolog,
     *    symbol,ppp,nschann,donply,dosmooth,filelabel)
c
        parameter(maspect=49)
        integer nfeeds,nants,nchan,ppp,symbol,nschann(49)
        integer filelabel
        complex g(nchan*nfeeds*nants)
        real freq(nchan),range(2)
        logical doamp,dophase,dowrap,doreal,doimag,doplot,dolog
        character feeds(nfeeds)*(*),vis*(*)
        logical donply,dosmooth
c
c  Plot/list the bandpass shape.
c
c  Input:
c    nfeeds	Number of polarization feeds.
c    nants	Number of antennas.
c    nchan	Number of channels.
c    freq	The offset time of each solution.
c    G		The gains
c    range	Range along Y axis for plots.
c    Feeds	Used to form labels and descriptions.
c    doamp,dophase,doreal,doimag If true, the do the corresponding
c		plot/listing.
c    dowrap	True if we are not to attempt to unwrap.
c    doplot,dolog If true, do a plot or write the table.
c    symbol	Plotting symbol.
c    ppp	Plots per page.
c------------------------------------------------------------------------
c
c  Externals.
c
        real     getamp,getphasw,getphase,getreal,getimag
        external getamp,getphasw,getphase,getreal,getimag
c
        if(doamp)  call bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    'Amp',feeds,doplot,dolog,symbol,getamp,ppp,nschann,
     *     donply,dosmooth,filelabel)
        if(dophase)then
          if(dowrap)then
            call bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    'Phase',feeds,doplot,dolog,symbol,getphasw,ppp,nschann,
     *     donply,dosmooth,filelabel)
          else
            call bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    'Phase',feeds,doplot,dolog,symbol,getphase,ppp,nschann,
     *     donply,dosmooth,filelabel)
          endif
        endif
        if(doreal) call bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    'Real',feeds,doplot,dolog,symbol,getreal,ppp,nschann,
     *     donply,dosmooth,filelabel)
        if(doimag) call bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    'Imag',feeds,doplot,dolog,symbol,getimag,ppp,nschann,
     *     donply,dosmooth,filelabel)
        end
c************************************************************************
        subroutine polplt2(leaks,nfeeds,nants,range,type,feeds,
     *    doplot,dolog,symbol,getval)
c
        integer nfeeds,nants,symbol
        complex leaks(nfeeds*nants)
        logical doplot,dolog
        character feeds(nfeeds)*(*),type*(*)
        real range(2)
        real getval
        external getval
c
c------------------------------------------------------------------------
        include 'smagpplt.h'
        real x(2*maxant),y(2*maxant),value
        integer ifeed,iant,j,j1,j2
        logical more
        character line*80,label*16
c
c  Externals.
c
        character itoaf*3
c
        if(doplot)then
          do ifeed=1,nfeeds
            value = 0
            do iant=1,nants
              x(iant) = iant
              y(iant) = getval(leaks(ifeed+nfeeds*(iant-1)),value)
            enddo
            call setpg(1.,real(nants),y,nants,range,.true.)
            call pgpt(nants,x,y,symbol)
            label = feeds(ifeed)//'-Leakage-'//type
            call pglab('Antenna Number',label,' ')
          enddo
        endif
c
        if(dolog)then
          value = 0
          do j=1,nfeeds*nants
            y(j) = getval(leaks(j),value)
          enddo
          write(line,10)type,(feeds(ifeed),ifeed=1,nfeeds)
   10     format('# Listing of the ',a,
     *          ' of the leakages for feeds ',4(a,:,','))
          call logwrite(line,more)
          line = '# Number of antennas: '//itoaf(nants)
          call logwrite(line,more)
          do j1=1,nfeeds*nants,6
            j2 = min(j1+5,nfeeds*nants)
            write(line,'(7f11.3)')(y(j),j=j1,j2)
            call logwrite(line,more)
          enddo
        endif
        end
c************************************************************************
        subroutine gainplt2(vis,time,g,nfeeds,nants,nsols,range,
     *  type,feeds,doplot,dolog,dodtime,donply,dosmooth,
     *  symbol,getval,ppp,weight,filelabel)
c
        integer nfeeds,nants,nsols,ppp,symbol
        real time(nsols),range(2)
        complex g(nfeeds*nants*nsols)
        logical doplot,dolog,dodtime,donply,dosmooth
        character feeds(nfeeds)*(*),vis*(*),type*(*)
        real getval
        external getval
c
c  Do the plot or the listing.
c
c  Inputs:
c	Similar to GainPlt, except ...
c	GetVal	Routine used to convert to the desired quantity.
c------------------------------------------------------------------------
        include 'smagpplt.h'
        character line*80,title*48,label*20
        character uvfile*48
        logical more, xpntr(maxtimes)
        real x(maxtimes),y(maxtimes),value(2*maxant)
        real wt(maxtimes)
        complex gain
        integer iday,ihr,imin,isec,j,j1,j2,isol,ifeed,iant
        integer offset,nres,ng,length,weight,lfile
c
c  Externals.
c
        character itoaf*3
        integer len1,filelabel
c
c  Do the plots.
c
            uvfile = 'File='//vis
            lfile = len1(uvfile)
        if(doplot)then
          do ifeed=1,nfeeds
            nres = 0
            do iant=1,nants
              offset = ifeed + (iant-1)*nfeeds
              ng = 0
              value(offset) = 0
              do isol=1,nsols
              gain = g(offset+(isol-1)*nfeeds*nants)
              if(abs(real(gain))+abs(aimag(gain)).gt.0)then
                xpntr(isol) = .true.
                ng = ng + 1
                x(ng) = time(isol)
                y(ng) = getval(gain,value(offset))
                wt(ng) = real(gain)**2+imag(gain)**2
                else
                 xpntr(isol) = .false.
              endif
              enddo
              if(ng.gt.0) then
           call setpg(time(1),time(nsols),y,ng,range,dodtime)
           call pgptsgain(ng,x,y,symbol,iant,ifeed,type,wt,
     *  weight,xpntr,time,nsols,donply,dosmooth)
            if(filelabel.gt.-1) then
            if((filelabel.eq.1).and.(iant.eq.1)) 
     *      call pgmtxt('LV',-1.,0.9,.0,uvfile(1:lfile))
            if(filelabel.eq.0) 
     *      call pgmtxt('LV',-1.,0.9,.0,uvfile(1:lfile))
            end if
                label = feeds(ifeed)//'-Gain-'//type
                title = 'Antenna '//itoaf(iant)
                length = len1(title)
                call pglab('Time',label,title(1:lfile))
                nres = nres + 1
              endif
            enddo
            call subfill(nres,ppp)
            enddo
            endif
c
c  Write the needed data to the listing file.
c
        if(dolog)then
          do j=1,nfeeds*nants
            value(j) = 0
          enddo
          write(line,10)type,(feeds(j),j=1,nfeeds)
   10     format('# Listing of the ',a,' of the gains for ',4(a,:,','))
          call logwrite(line,more)
          line = '# Number of antennas: '//itoaf(nants)
          call logwrite(line,more)
c
          do isol=1,nsols
            offset = (isol-1)*nants*nfeeds
            do j=1,nfeeds*nants
              y(j) = getval(g(offset+j),value(j))
            enddo
            do j1=1,nfeeds*nants,6
              j2 = min(j1+5,nfeeds*nants)
              if(j1.eq.1)then
                if(dodtime)then
                  write(line(1:12),'(f11.6)')time(isol)
                else
                  isec = nint(time(isol))
                  iday = isec/(24*3600)
                  isec = isec - 24*3600*iday
                  ihr  = isec/3600
                  isec = isec - 3600*ihr
                  imin = isec / 60
                  isec = isec - 60*imin
                  write(line(1:12),'(i2,a,i2.2,a,i2.2,a,i2.2)')
     *                  iday,' ',ihr,':',imin,':',isec
                endif
              else
                line(1:12) = ' '
              endif
              write(line(13:80),'(6f11.3)')(y(j),j=j1,j2)
              call logwrite(line,more)
            enddo
          enddo
        endif
        end
c************************************************************************
        subroutine bpplt2(vis,freq,g,nfeeds,nants,nchan,range,
     *    type,feeds,doplot,dolog,symbol,getval,ppp,nschann,
     *    donply,dosmooth,filelabel)
c
        parameter(maxspect=49)
        integer nfeeds,nants,nchan,ppp,symbol,nschann(maxspect)
        real freq(nchan),range(2)
        complex g(nchan*nfeeds*nants)
        logical doplot,dolog
        character feeds(nfeeds)*(*),type*(*),vis*(*)
        real getval
        external getval
c
c  Do the plot or the listing.
c
c  Inputs:
c	Similar to BpPlt, except ...
c	GetVal	Routine used to convert to the desired quantity.
c------------------------------------------------------------------------
        include 'smagpplt.h'
        character line*80,label*20,title*12
        character uvfile*48
        logical more,donply,dosmooth
        real x(maxtimes),y(maxtimes),freqmin,freqmax
        real value(2*maxant)
        complex gain
        integer ichan,ifeed,iant,offset,j,j1,j2,nres,ng
        integer filelabel,lfile
c
c  Externals.
c
        character itoaf*3
c
c  Do the plots.
c
            uvfile = 'File='//vis
            lfile = len1(uvfile)

        if(doplot)then
c
c  Determine the min and max frequencies.
c
          freqmin = freq(1)
          freqmax = freqmin
          do ichan=1,nchan
            freqmin = min(freqmin,freq(ichan))
            freqmax = max(freqmax,freq(ichan))
          enddo
c
          do ifeed=1,nfeeds
            nres = 0
            do iant=1,nants
              offset = (ifeed-1) + (iant-1)*nfeeds
              ng = 0
              value(offset+1) = 0
              do ichan=1,nchan
                gain = g(ichan + nchan*offset)
                if(abs(real(gain))+abs(aimag(gain)).gt.0)then
                  ng = ng + 1
                  x(ng) = freq(ichan)
                  y(ng) = getval(gain,value(offset+1))
                endif
              enddo
              if(ng.gt.0)then
                call setpg(freqmin,freqmax,y,ng,range,.true.)
c        write(*,*) 'ifeed iant type nfeed',ifeed,iant,type,nfeeds
          call pgptbpass(ng,x,y,symbol,ifeed,iant,type,
     *    nschann,donply,dosmooth)

            if(filelabel.gt.-1) then
            if((filelabel.eq.1).and.(iant.eq.1))
     *      call pgmtxt('LV',-1.,0.9,.0,uvfile(1:lfile))
            if(filelabel.eq.0)
     *      call pgmtxt('LV',-1.,0.9,.0,uvfile(1:lfile))
            end if

           label = feeds(ifeed)//'-BandPass-'//type
           title = 'Antenna '//itoaf(iant)
           call pglab('Frequency (GHz)',label,title)
                nres = nres + 1
              endif
            
            enddo
            call subfill(nres,ppp)
          enddo
        endif
c
c  Write the needed data to the listing file.
c
        if(dolog)then
          call bptitle(type,feeds,nfeeds,nants)
          do offset=1,nants*nfeeds
            value(offset) = 0
          enddo
c
          do ichan=1,nchan
            offset = 0
            do iant=1,nants
              do ifeed=1,nfeeds
                gain = g(ichan+nchan*offset)
                y(offset+1) = getval(gain,value(offset+1))
                offset = offset + 1
              enddo
            enddo
            do j1=1,nfeeds*nants,6
              j2 = min(j1+5,nfeeds*nants)
              if(j1.eq.1)then
                write(line,'(f10.5,6f10.5)')freq(ichan),(y(j),j=j1,j2)
              else
                write(line,'(10x,  6f10.5)')            (y(j),j=j1,j2)
              endif
              call logwrite(line,more)
            enddo
          enddo
        endif
        end

      SUBROUTINE PGPTS (N, XPTS, YPTS, SYMBOL)
      INTEGER N
      REAL XPTS(*), YPTS(*)
      INTEGER SYMBOL
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
c     for moving smooth
      double precision Y(6145),ETA(6200),CONETA(6200),A(21,6)
      double precision ATA1(6,6),ATA1AT(6,21),SCRAT(6,6),P
      real x(6145), ys(6145)
      integer K, L, i, bnply, breport
      real smooth(3), rpass(10,6145,2),ipass(10,6145,2)
      real apass(10,6145,2),ppass(10,6145,2)
      common/bsmooth/smooth,rpass,ipass,apass,ppass,bnply,breport
C
      call pgsci(2)
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
      CALL PGBBUF
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
          CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
      ELSE
          CALL GRDOT1(N,XPTS,YPTS)
      END IF
      CALL PGEBUF
       do i=1, N
        x(i) = XPTS(i)
        y(i) = YPTS(i)
        end do
c
c        K=3 
c        L=3
c        P=0.9
c
         K= smooth(1)
         L= smooth(2)
         P= smooth(3)
c
c timer is to do moving smooth, the code/algorithm is from
c "Data Analysis" by Siegmund Brandt
c
        if((K.gt.0).and.(bnply.eq.0)) then 
        CALL TIMSER(Y,N,K,L,P,ETA,CONETA,A,ATA1,ATA1AT,SCRAT)
         do i=1, N
           ys(i) = ETA(i+K)
         end do
         end if

       call pgsci(5)
       call pgline (N, x, ys)

      call pgsci(1)
      END

      SUBROUTINE PGPTSGAIN(N,XPTS,YPTS,SYMBOL,IANT,IFEED,
     *  type,WT,weight,xpntr,time,nsols,donply,dosmooth)
      INTEGER N,IANT,IFEED
      REAL XPTS(*), YPTS(*),WT(*)
      INTEGER SYMBOL,weight
      character type*(*)
      real time(nsols)
      LOGICAL xpntr(nsols),donply,dosmooth
C
C-----------------------------------------------------------------------
      LOGICAL PGNOTO
c     for moving smooth
      PARAMETER(MAXNR=20,MAXN=7681)
      double precision dpi
      parameter(dpi=3.14159265358979323846)
      double precision T(N),Y(N),DELTAY(N)
      double precision ETA(6200),CONETA(6200),A(21,6)
      double precision ATA1(6,6),ATA1AT(6,21),SCRAT(6,6)
      double precision XA(MAXNR),BP(MAXNR,MAXNR),AP(N,MAXNR)
      double precision CHI2(MAXNR),P
      real x(MAXN), ys(MAXN)
      integer K, L, i, gnply, greport, nterm, nnsols(10,2)
      real smoothg(3), rgain(10,2,6145),igain(10,2,6145)
      real  again(10,2,6145),pgain(10,2,6145)
      common/gsmooth/smoothg,rgain,igain,gnply,greport,nnsols
C
c   load the nnsols
c   initialize x(i),ys(i)
c
          nnsols(IANT,IFEED)=nsols
          do i=1, nsols
           x(i)= time(i)/3600.
           ys(i) = 0. 
          end do
      call pgsci(2)
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
      CALL PGBBUF
      IF (SYMBOL.GE.0 .OR. SYMBOL.LE.-3) THEN
          CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
      ELSE
          CALL GRDOT1(N,XPTS,YPTS)
      END IF
      CALL PGEBUF
        do i=1, N
        T(i) = XPTS(i)/3600.
        Y(i) = YPTS(i)
        DELTAY(i)=1.0D0
        if(weight.ge.1) DELTAY(i)=1.0D0*WT(i)
        end do
c
         K = smoothg(1)
         L = smoothg(2)
         P = smoothg(3)
c
c timer is to do moving smooth, the code/algorithm is from
c "Data Analysis" by Siegmund Brandt
c
         if((K.gt.0).and.(gnply.eq.0)) then
        CALL TIMSER(Y,N,K,L,P,ETA,CONETA,A,ATA1,ATA1AT,SCRAT)
         do i=1, N
           ys(i) = ETA(i+K)
            x(i) = T(i)
            
         end do
            nsols=N
         end if
c
c Orthogonal polynomial fit to the gains 
c        
         if(gnply.gt.0) then 
        CALL REGPOL(T,Y,DELTAY,N,MAXNR,XA,BP,AP,CHI2)
         if(greport>0) then
            write(*,*) 'Order  Chi2  for Ant',IANT
         do ii=1, MAXNR
         write(*,'(i2xxf8.1)') ii-1, CHI2(ii)
         end do
            end if
            nterm=gnply+1
            call regpolfitg(nterm,xa,bp,nsols,x,ys)
            end if
         do i=1,nsols 
        if(donply.or.dosmooth) then
        if(type.eq.'Amp') again(IANT, IFEED,i) = ys(i)
        if(type.eq.'Phase') then
              pgain(IANT, IFEED,i) = ys(i)*dpi/180.
           rgain(IANT, IFEED,i) = 
     *        again(IANT, IFEED,i)*cos(pgain(IANT, IFEED,i))
           igain(IANT, IFEED,i) =
     *        again(IANT, IFEED,i)*sin(pgain(IANT, IFEED,i))
         end if
         end if
        if(type.eq.'Real') rgain(IANT, IFEED,i) = ys(i)
        if(type.eq.'Imag') igain(IANT, IFEED,i) = ys(i)
            x(i)=3600.*x(i)
         end do
        call pgsci(5)
        call pgline (nsols, x, ys)
        call pgsci(1)
        END
c-----------------------------------------------------------
c         subroutine gaintab(tno,time,gains,tau,npol,nants,nsoln,
c     *                                          freq0,dodelay,pee)
          subroutine gaintab(tno,time,gains,npol,nants,nsoln,pee)
c
        integer tno,nants,nsoln,npol,pee(npol)
        double precision time(nsoln),freq0
        complex gains(10,2,6145)
        logical dodelay
c
c  Write out the antenna gains and the delays.
c
c  Input:
c    tno
c    time
c    Gains
c    Tau
c    npol       Number of polarisations. Either 1 or 2.
c    nants
c    nsoln
c    dodelay    True if the delays are to be written out.
c    pee        Mapping from internal polarisation number to the order
c               that we write the gains out in.
c------------------------------------------------------------------------
c=======================================================================
            include 'maxdim.h'
c=======================================================================
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
        integer iostat,off,item,i,j,p,pd,j1,ngains
        complex g(3*maxant)
c
c  no delay correction
c
            dodelay=.false.
            freq0=100.
        call haccess(tno,item,'gains','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output amp/phase table.')
          call bugno('f',iostat)
        endif
        call hwritei(item,0,0,4,iostat)
        if(iostat.ne.0)then
         call bug('w','Error writing header of amp/phase table')
          call bugno('f',iostat)
        endif
        write(*,*) 
     * 'create new gain table with smoothed or interpolated values.'
c
c  Write out all the gains.
c
         ngains = npol*nants
        if(dodelay) ngains = (npol+1)*nants
c
        off = 8
        do i=1,nsoln
          call hwrited(item,time(i),off,8,iostat)
          off = off + 8
          if(iostat.ne.0)then
            call bug('w','Error writing time to amp/phase table')
            call bugno('f',iostat)
          endif
          j1 = 1
          do j=1,nants
            do p=1,npol
              pd = pee(p)
              g(j1) =gains(j,pd,i)
             j1 = j1 + 1
            enddo
          enddo
          call hwriter(item,g,off,8*ngains,iostat)
          off = off + 8*ngains
          if(iostat.ne.0)then
            call bug('w','Error writing gains to amp/phase table')
            call bugno('f',iostat)
          endif
        enddo
c
c  Finished writing the gain table.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)

c
c  Now write out the other parameters that need to go along with this.
c
        call wrhdi(tno,'nfeeds',npol)
        call wrhdi(tno,'ngains',ngains)
        call wrhdi(tno,'nsols',nsoln)
        call wrhdd(tno,'interval',0.5d0)
        if(dodelay)then
          call wrhdi(tno,'ntau',1)
          call wrhdd(tno,'freq0',freq0)
        else
          call wrhdi(tno,'ntau',0)
        endif
c
        end

c************************************************************************
      SUBROUTINE PGPTBPASS (N,XPTS,YPTS,SYMBOL,IFEED,
     *   IANT,type,nschann,donply,dosmooth)
      INTEGER N, IFEED, IANT
      REAL XPTS(*), YPTS(*)
      INTEGER SYMBOL
      LOGICAL PGNOTO
      character type*(*)
c     for movinf smooth
      PARAMETER(MAXNR=20,MAXN=7681,maxspect=49)
      double precision dpi
      parameter(dpi=3.14159265358979323846)
      integer nschann(maxspect)
      double precision T(N),Y(N),DELTAY(N)
      double precision ETA(6200),CONETA(6200),A(21,6)
      double precision XA(MAXNR),BP(MAXNR,MAXNR),AP(N,MAXNR)
      double precision CHI2(MAXNR), P
      double precision ATA1(6,6),ATA1AT(6,21),SCRAT(6,6)
      real x(N), xchan(N), ys(N)
      real xlen,ylen,xloc
      character title*64
      integer K,L,i,nspects,schan,fsign,ll,bnply,nterm,breport 
      real smooth(3), ymean
      real rpass(10,6145,2), ipass(10,6145,2)
      real apass(10,6145,2), ppass(10,6145,2)
      logical donply, dosmooth
      common/bsmooth/smooth,rpass,ipass,apass,ppass,bnply,breport
C
      call pgsci(1)
      IF (N.LT.1) RETURN
      IF (PGNOTO('PGPT')) RETURN
C
       yloc=0.95
       schan=0
       nspects=0
       ymean=0.0
       do i=1, N
       ymean=ymean+YPTS(i)
       enddo
       ymean=ymean/N
        fsign=-1
        if((XPTS(1)/XPTS(2)).ge.1) fsign=1
        do i=1, N
         

        if((schan+1).lt.nschann(nspects+1)) then
        schan  = schan+1
        x(schan)  = XPTS(i)
        T(schan)  = schan
        xchan(schan)  = schan
        ys(schan) = YPTS(i)
        y(schan) = YPTS(i)
         DELTAY(schan) = 1.D0
          else
           schan  = schan+1
           x(schan)  = XPTS(i)
           T(schan)  = schan
           xchan(schan)  = schan
           ys(schan) = YPTS(i)
           y(schan) = YPTS(i)
           DELTAY(schan) = 1.D0
           nspects  = nspects+1
         if(nspects.le.12) call pgsci(nspects)
c         if(nspects.gt.12) call pgsci(nspects-12)
         if(nspects.eq.13) call pgscr(nspects, 1.0, 1.0, 0.5)
         if(nspects.eq.14) call pgscr(nspects, 1.0, 1.0, 0.0)
         if(nspects.eq.15) call pgscr(nspects, 1.0, 0.5, 0.5)
         if(nspects.eq.16) call pgscr(nspects, 1.0, 0.5, 0.2)
         if(nspects.eq.17) call pgscr(nspects, 1.0, 0.0, 0.5)
         if(nspects.eq.18) call pgscr(nspects, 1.0, 0.2, 0.2)
         if(nspects.eq.19) call pgscr(nspects, 0.5, 1.0, 0.5)
         if(nspects.eq.20) call pgscr(nspects, 0.7, 0.70, 0.70)
         if(nspects.eq.21) call pgscr(nspects, 0.7, 0.5, 0.5)
         if(nspects.eq.22) call pgscr(nspects, 0.7, 0.5, 0.9)
         if(nspects.eq.23) call pgscr(nspects, 0.5, 0.0, 0.5)
         if(nspects.eq.24) call pgscr(nspects, 0.75, 0.2, 0.3)
         call pgsci(nspects)
            
         CALL PGBBUF
          
         CALL GRMKER(SYMBOL,.FALSE.,schan,x,ys)
         CALL PGEBUF

       write(title,'(a,i2)') 's', nspects
       ll = len1(title)
               call pglen(5,title(1:ll),xlen,ylen)
               xloc = 0.8
               yloc = yloc-1/30.
               call pgmtxt('RV',1.0,yloc,0.,title(1:ll))
c
c  convert double to real
c
c
         K= smooth(1)
         L= smooth(2)
         P= smooth(3)
        if(bnply.eq.0) then
c
c timer is to do moving smooth, the code/algorithm is from
c "Data Analysis" by Siegmund Brandt
c
        CALL TIMSER(Y,schan,K,L,P,ETA,CONETA,A,ATA1,ATA1AT,SCRAT)
        do ii=1, schan
        ys(ii) = ETA(ii+K)
        end do
              else
c
c Orthogonal polynomial fit to the bpass
c
         CALL REGPOL(T,Y,DELTAY,schan,MAXNR,XA,BP,AP,CHI2)
         if(breport>0) then
         write(*,*) 'Order  Chi2  for Ant',IANT, '-- Sp',nspects
         do ii=1, MAXNR
         write(*,'(i2xxf8.1)') ii-1, CHI2(ii)
         end do
         end if
        nterm=bnply+1
        call regpolfitg(nterm,xa,bp,schan,xchan,ys)
        end if
        do ii=1, schan
        if(type.eq.'Real') rpass(IANT, i-schan+ii, IFEED) = ys(ii)
        if(type.eq.'Imag') ipass(IANT, i-schan+ii, IFEED) = ys(ii)
        if(type.eq.'Amp')  apass(IANT,i-schan+ii, IFEED) = ys(ii)
         if(type.eq.'Phase') ppass(IANT, i-schan+ii, IFEED) = ys(ii)
c
c        if(donply.or.dosmooth) then
c        if(type.eq.'Amp') apass(IANT,i-schan+ii, IFEED) = ys(ii)
c        if(type.eq.'Phase') then
c              ppass(IANT, i-schan+ii, IFEED) = ys(ii)*dpi/180.
c           rpass(IANT,i-schan+ii, IFEED) =
c     * apass(IANT,i-schan+ii, IFEED)*cos(ppass(IANT,i-schan+ii,IFEED))
c           ipass(IANT,i-schan+ii, IFEED) =
c     * apass(IANT,i-schan+ii, IFEED)*sin(ppass(IANT,i-schan+ii,IFEED))
c         end if
c         end if
        end do
       call pgsci(1)
       call pgline (schan, x, ys)
       call pgsci(1)
        schan=0
        end if
        end do
       END


c************************************************************************
       subroutine passtab(tno,npol,nants,nchan,
     *           pass,pee)
c
        integer tno,npol,nants,nchan,pee(npol)
        complex pass(10,6145,2)
c
c  Write out the bandpass table and frequency description table (with a
c  few other assorted parameters). This assumes that the parameters
c    ngains, nfeeds
c  have already been written out.
c
c  Input:
c    tno        Handle of the output dataset.
c    nants      Number of antennas.
c    npol       Number of polarisations (either 1 or 2).
c    nspect     The total number of frequency bands observed. This is the
c               product of the number of simultaneous spectral windows and
c               the number of different frequency settings.
c    nschan     The number of channels in each observing band.
c    nchan      Total number of channels.
c               NOTE: Here (as elsewhere in this task) "nchan" is the total
c               number of channels (the sum of all the channels from all the
c               bands observed).
c               i.e. nchan = Sum nschan(i)
c    Pass       The bandpass function. This is of size nants * nchan * npol.
c               The bandpass table that we have to write out is in the order
c               nchan * npol * nants, so we have to do some reorganising
c               before we write out.
c    pee        Mapping from internal polarisation number to the order
c               that we write the gains out in. We always write X then Y
c               (or R then L).
c    sdf        Frequency increment for each observing band.
c    sfreq      Start frequency for each observing band.
c------------------------------------------------------------------------
        include 'maxdim.h'
	integer iostat,off,item,i,j,k,n,p,pd
        complex g(maxchan),temp
c
c  Fudge to create a "complex" table, then open it again.
c
c        call hdelete(tno,'bandpass',iostat)
        write(*,*) 'create the new bandpass table'
        n=0
        call wrhdc(tno,'bandpass',(0.,0.))
        call haccess(tno,item,'bandpass','append',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output bandpass table')
          call bugno('f',iostat)
        endif
c
c  Write out all the gains. Write one antenna and one polarisation at
c  a time. Because the input ("Pass") is in antenna/channel/pol order,
c  and the output table is in channel/pol/antenna order, we have to
c  rearraneg before writing out. Also convert from a "error" to a "correction"
c  by taking the inverse.
c  Because "nchan" is the sum of all the channels from the frequency
c  bands observed, nchan may be larger than MAXCHAN. To cope with this,
c  copy the output channels in a strip-mining approach.
c
c  Loop over antenna, polarisation, strip, and channel within a strip.
c
        off = 8
      
        do i=1,nants
          do p=1,npol
            pd = pee(p)
             pd=1
            do j=1,nchan,maxchan
              n = min(maxchan,nchan-j+1)
              do k=1,n
                temp = pass(i,j+k-1,pd)
                if(abs(real(temp))+abs(aimag(temp)).ne.0)then
                  g(k) = 1/temp
                else
                  g(k) = 0
                endif
              enddo
            enddo


c
c  Write a strip, and check for errors.
c
            call hwriter(item,g,off,8*n,iostat)
            off = off + 8*n
            if(iostat.ne.0)then
              call bug('w','Error writing gains to bandpass table')
              call bugno('f',iostat)
            endif
          enddo
        enddo
c
c  Finished writing the bandpass table.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
                    write(*,*) 'finish bp table'
c
c  Access the frequencies description table.
c
cc        call haccess(tno,item,'freqs','write',iostat)
cc        if(iostat.ne.0)then
cc          call bug('w','Error opening output frequency table.')
cc          call bugno('f',iostat)
cc        endif
cc        call hwritei(item,0,0,4,iostat)
cc        if(iostat.ne.0)then
cc          call bug('w','Error writing header of frequency table')
cc          call bugno('f',iostat)
cc        endif
c
c  Write out all the frequencies.
c
cc        off = 8
cc        do i=1,nspect
cc          call hwritei(item,nschan(i),off,4,iostat)
cc          off = off + 8
cc          if(iostat.ne.0)then
cc            call bug('w','Error writing nschan to freq table')
cc            call bugno('f',iostat)
cc          endif
cc          freqs(1) = sfreq(i)
cc          freqs(2) = sdf(i)
cc          call hwrited(item,freqs,off,2*8,iostat)
cc          off = off + 2*8
cc          if(iostat.ne.0)then
cc            call bug('w','Error writing freqs to freq table')
cc            call bugno('f',iostat)
cc c         endif
cc        enddo
c
c  Finished writing the frequency table.
c
cc        call hdaccess(item,iostat)
cc       if(iostat.ne.0)call bugno('f',iostat)
c
c  Now write out the other parameters that need to go along with this.
c
c        call wrhdi(tno,'nspect0',nspect)
c        call wrhdi(tno,'nchan0',nchan)
c
        end

c************************************************************************
        subroutine bptitle(type,feeds,nfeeds,nants)
c
        integer nfeeds,nants
        character type*(*),feeds(nfeeds)*(*)
c
c  Generate the title for the Bandpass listing file.
c------------------------------------------------------------------------
        integer length,j,j1,j2,ant,feed
        logical more
        character line*80
c
c  Externals.
c
        character itoaf*2
        integer len1
c
        length = len1(type)
        write(line,10)type(1:length),(feeds(j),j=1,nfeeds)
   10   format('# Listing of the ',a,
     *          ' of the bandpass for ',4(a,:,','))
        call logwrite(line,more)
        line = '# Number of antennas: '//itoaf(nants)
        call logwrite(line,more)
        do j1=1,nants*nfeeds,6
          if(j1.eq.1)then
            line = '# Freq(GHz)'
          else
            line = '#'
          endif
          length = 16
          j2 = min(j1+5,nants*nfeeds)
          do j=j1,j2
            ant = (j-1)/nfeeds + 1
            feed = j - (ant-1)*nfeeds
            line(length+1:) = feeds(feed)//itoaf(ant)
            length = length + 10
          enddo
          call logwrite(line(1:length),more)
        enddo
        end
c************************************************************************
        subroutine tscale(time,nsols)
c
        integer nsols
        real time(nsols)
c
c  Scale the times to seconds.
c
c  Input:
c    nsols	Number of times.
c  Input/Output:
c    time	The times. On input, these are in fractions of a day.
c		On output these are the seconds in a day.
c------------------------------------------------------------------------
        integer i
        real scale
        parameter(scale=24.0*3600.0)
c
        do i=1,nsols
          time(i) = scale * time(i)
        enddo
        end
c************************************************************************
        subroutine setpg(xmin,xmax,y,n,range,dodtime)
c
        integer n
        real xmin,xmax,y(*),range(2)
        logical dodtime
c
c  Determine the range of the plots, and call the appropriate PGPLOT
c  routines to set this up.
c
c  Inputs:
c    xmin,xmax	Range of the X data to be plotted.
c    y		The Y data to be plotted.
c    n		Number of points in Y.
c------------------------------------------------------------------------
        real xlo,xhi,ylo,yhi,delta,maxv
        integer i
c
        delta = 0.05*(xmax-xmin)
        if(delta.le.0)delta = 1
        xlo = xmin - delta
        xhi = xmax + delta
c
        if(range(2).gt.range(1))then
          yhi = range(2)
          ylo = range(1)
        else if(n.eq.0)then
          ylo = -1
          yhi =  1
        else
          yhi = y(1)
          ylo = yhi
          do i=2,n
            yhi = max(yhi,y(i))
            ylo = min(ylo,y(i))
          enddo
c
c get rid of a bug when lo and li is small at e-42,
c which collapes the plot frame
c
      if(abs(yhi).le.1.e-18) yhi=1.e-18
      if((abs(ylo).le.1.e-18)) ylo=-1.e-18
c
          delta = 0.05*(yhi-ylo)
          maxv = max(abs(ylo),abs(yhi))
          if(delta.le.1e-4*maxv) delta = 0.01*maxv
          if(delta.eq.0) delta = 1
          ylo = ylo - delta
          yhi = yhi + delta
        endif
c
        call pgpage
        call pgvstd
        call pgswin(xlo,xhi,ylo,yhi)
        if(dodtime)then
          call pgtbox('BCNST',0.,0,'BCNST',0.,0)
        else
          call pgtbox('BCNSTHZO',0.,0,'BCNST',0.,0)
        endif
        end
c************************************************************************
        real function getamp(g,pamp)
c
        complex g
        real pamp
c
c  Get the amplitude of a complex value.
c------------------------------------------------------------------------
        getamp = abs(g)
        end
c************************************************************************
        real function getphase(g,pphase)
c
        complex g
        real pphase
c
c  Get the unwrapped phase of a complex value.
c------------------------------------------------------------------------
        include 'mirconst.h'
c
        if(abs(real(g))+abs(aimag(g)).eq.0)then
          getphase = 0
        else
          getphase = 180/pi * atan2(aimag(g),real(g))
          getphase = getphase - 360*nint((getphase-pphase)/360.)
          pphase = 0.5*(getphase + pphase)
        endif
        end
c************************************************************************
        real function getphasw(g,pphase)
c
        complex g
        real pphase
c
c  Get the wrapped phase of a complex value.
c------------------------------------------------------------------------
        include 'mirconst.h'
c
        if(abs(real(g))+abs(aimag(g)).eq.0)then
          getphasw = 0
        else
          getphasw = 180/pi * atan2(aimag(g),real(g))
        endif
        end
c************************************************************************
        real function getreal(g,preal)
c
        complex g
        real preal
c
c  Get the real part of a complex value.
c------------------------------------------------------------------------
        getreal = real(g)
        end
c************************************************************************
        real function getimag(g,pimag)
c
        complex g
        real pimag
c
c  Get the imaginary of a complex value.
c------------------------------------------------------------------------
        getimag = aimag(g)
        end
c************************************************************************
        subroutine gncvt(in,out,nfeeds,ntau,ngains)
c
        integer nfeeds,ntau,ngains
        complex in(nfeeds+ntau,ngains),out(nfeeds,ngains)
c
c  Pick out the true gains.
c
c------------------------------------------------------------------------
        integer i,j
c
        do j=1,ngains
          do i=1,nfeeds
            out(i,j) = in(i,j)
          enddo
        enddo
        end
c************************************************************************
        subroutine alphacvt(in,out,nfeeds,ntau,ngains,doimag)
c
        integer nfeeds,ntau,ngains
        logical doimag
        complex in((nfeeds+ntau)*ngains)
        real out(ngains)
c
c------------------------------------------------------------------------
        include 'mirconst.h'
        integer i,j
c
        i = 1 + nfeeds
        do j=1,ngains
          if(doimag)then
            out(j) = aimag(in(i)) / (2*pi)
          else
            out(j) = real(in(i))
          endif
          i = i + nfeeds + ntau
        enddo
        end
c************************************************************************
        subroutine xycvt(in,out,nfeeds,ntau,ngains,doxy)
c
        integer nfeeds,ntau,ngains
        logical doxy
        complex in((nfeeds+ntau)*ngains),out(ngains)
c
c  This divides or multiplies the X gains by the Y gains, to get the XY gains.
c
c------------------------------------------------------------------------
        integer i,j
        real temp
c
        i = 1
        do j=1,ngains
          temp = abs(real(in(i+1)))+abs(aimag(in(i+1)))
          if(temp.le.0)then
            out(j) = 0
          else if(doxy)then
            out(j) = in(i)/in(i+1)
          else
            out(j) = in(i)*conjg(in(i+1))
          endif
          i = i + nfeeds + ntau
        enddo
        end
c************************************************************************
        subroutine getopt(dogains,doxy,doxbyy,dopol,dodtime,dodots,
     *     dodelay,dospec,dopass,dowrap,dosmooth,donply,doratio,
     *     domerge)
c
        logical dogains,dopol,dodtime,doxy,doxbyy,dodots,dodelay
        logical dospec,dopass,dowrap,dosmooth,donply,doratio
        logical domerge
c
c  Get extra processing options.
c
c  Output:
c    dogains	If true, process the gains.
c    doxy	If true, process the ratio of X/Y gains.
c    doxbyy	If true, process the product of X*Y gains
c    dopol	If true, process the polarizations.
c    dodtime	If true, give time as day fractions.
c    dodots	If true, plot small dots (rather than big circles).
c    dodelay	If true, process the delays table.
c    dopass	If true, process the bandpass table.
c    dowrap     If true, don't unwrap phases.
c    dosmooth   If true, replace old gain curve with the smooth.
c    donply     If true, replace old gain curve with the polynomial fit.
c    doratio    If true, calculate bandpass ratio.
c    domerge    If true, merge two gains tables.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=14)
        logical present(nopt)
        character opts(nopt)*12
c
        data opts/'gains       ','polarization','dtime       ',
     *            'xygains     ','xbyygains   ','dots        ',
     *            'delays      ','bandpass    ','speccor     ',
     *            'wrap        ','msmooth     ','opolyfit    ',
     *            'ratio       ','merge       '/
c
        call options('options',opts,present,nopt)
        dogains = present(1)
        dopol   = present(2)
        dodtime = present(3)
        doxy    = present(4)
        doxbyy  = present(5)
        dodots  = present(6)
        dodelay = present(7)
        dopass  = present(8)
        dospec  = present(9)
        dowrap  = present(10)
        dosmooth= present(11)
        donply  = present(12)
        doratio = present(13)
        domerge = present(14)
        if(dosmooth.and.donply) then
           call  bug('f','choose either msmooth or opolyfit')
        end if
        end
c************************************************************************
        subroutine getaxis(doamp,dophase,doreal,doimag)
c
        logical doamp,dophase,doreal,doimag
c
c  Determine the things to plot.
c
c  Output:
c    doamp	Plot the amplitude.
c    dophase	Plot the phase.
c    doreal	Plot the real part.
c    doimag	Plot the imaginary part.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=4)
        logical present(nopt)
        character opts(nopt)*9
c
        data opts/'amplitude','phase    ','real     ','imaginary'/
c
        call options('yaxis',opts,present,nopt)
        doamp   = present(1)
        dophase = present(2)
        doreal  = present(3)
        doimag  = present(4)
        end
c************************************************************************
      subroutine subfill(nres,ppp)
c
      integer nres,ppp
c
c     Skip through some blank sub-plots
c------------------------------------------------------------------------
      integer i,n
c
      n = mod( ppp-mod(nres,ppp), ppp)
      do i = 1, n
        call pgpage
      end do
c
      end

c  subroutine repolfit
c    purpose
c    make a least-sqaure fit to data with a polynomial curve
c        y = x1 + x2*f1(t) + a3*f2(t) + a4*f3(t) + ...
c        t - array of data points for independent variable
c        y - array of data points for dependent variable
c
c    fj(t) = sum(from k=1 to j) bjk t^(k-1)
c
        subroutine regpolfit(nterms,xa,bp,N, x1, pl2)
         PARAMETER(MAXNR=20)
         integer nterms, N, i, j, k, l
         double precision xa(MAXNR),bp(MAXNR,MAXNR)
         double precision XPL(N,MAXNR), YPL(N,MAXNR)
         real x1(N), pl2(N)
         double precision D
         PARAMETER (ZERO=0.0)
       do 40 i=1,N
        do 30 j=1,nterms
          XPL(i,j)=x1(i)
          YPL(i,j)=ZERO
          do 27 l=1,j
            D=bp(l,1)
            IF(l.gt.1) THEN
                do 25 k=2,l
                D=D+bp(l,k)*XPL(i,j)**(k-1)
25             continue
            END IF
            YPL(i,j)=YPL(i,j)+xa(l)*D
27           continue
30           continue
40           continue

              do i =1, N
                 x1(i) =XPL(i,nterms)
                 pl2(i) =YPL(i,nterms)
                end do
                return
                end

       subroutine regpolfitg(nterms,xa,bp,N, x1, pl2)
         PARAMETER(MAXNR=20)
         integer nterms, N, i, j, k, l
         double precision xa(MAXNR),bp(MAXNR,MAXNR)
         double precision XPL(N,MAXNR), YPL(N,MAXNR)
         real x1(N), pl2(N)
         double precision D
         PARAMETER (ZERO=0.0)
       do 40 i=1,N
        do 30 j=1,nterms
          XPL(i,j)=x1(i)
          YPL(i,j)=ZERO
          do 27 l=1,j
            D=bp(l,1)
            IF(l.gt.1) THEN
                do 25 k=2,l
                D=D+bp(l,k)*XPL(i,j)**(k-1)
25             continue
            END IF
            YPL(i,j)=YPL(i,j)+xa(l)*D
27           continue
30           continue
40           continue

              do i =1, N
                 x1(i) =XPL(i,nterms)
                 pl2(i) =YPL(i,nterms)
                end do
                return
                end

      SUBROUTINE REGPOL(T,Y,DELTAY,N,NR,X,B,A,CHI2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION T(N),Y(N),DELTAY(N),X(NR),CHI2(NR)
      DIMENSION B(NR,NR),A(N,NR)
      PARAMETER(MAXN=1000)
      DIMENSION G(MAXN)
      COMMON /DASV04/ G
      PARAMETER (ZERO=0.D0,ONE=1.D0)
C compute weights G and weighted mean TBAR
      SG=ZERO
      TBAR=ZERO
      DO 10 I=1,N
        G(I)=ONE/DELTAY(I)**2
        SG=SG+G(I)
        TBAR=TBAR+G(I)*T(I)
   10 CONTINUE
      TBAR=TBAR/SG
C compute B and A for NR=1
      B(1,1)=ONE/SQRT(SG)
      DO 20 I=1,N
        A(I,1)=B(1,1)
   20 CONTINUE
C compute B and A for NR=2
      IF(NR.GE.2) THEN
        S=ZERO
        DO 30 I=1,N
          S=S+G(I)*(T(I)-TBAR)**2
   30   CONTINUE
        B(2,2)=ONE/SQRT(S)
        B(2,1)=-B(2,2)*TBAR
        DO 40 I=1,N
          A(I,2)=B(2,1)+B(2,2)*T(I)
   40   CONTINUE
      END IF
C compute B and A for NR greater than 2
      IF(NR.GT.2) THEN
        DO 100 J=3,NR
          ALPHA=ZERO
          BETA=ZERO
          GAMMA2=ZERO
          DO 50 I=1,N
            ALPHA=ALPHA+G(I)*T(I)*A(I,J-1)**2
            BETA=BETA+G(I)*T(I)*A(I,J-1)*A(I,J-2)
   50     CONTINUE
          DO 60 I=1,N
            GAMMA2=GAMMA2+G(I)*((T(I)-ALPHA)*A(I,J-1)-
     +             BETA*A(I,J-2))**2
   60     CONTINUE
          GAMMA1=ONE/SQRT(GAMMA2)
          B(J,1)=GAMMA1*(-ALPHA*B(J-1,1)-BETA*B(J-2,1))
          IF(J.GE.4) THEN
            DO 70 K=2,J-2
              B(J,K)=GAMMA1*(B(J-1,K-1)-ALPHA*B(J-1,K)-
     +               BETA*B(J-2,K))
   70       CONTINUE
          END IF
          B(J,J-1)=GAMMA1*(B(J-1,J-2)-ALPHA*B(J-1,J-1))
          B(J,J)=GAMMA1*B(J-1,J-1)
          DO 90 I=1,N
            A(I,J)=B(J,1)
            DO 80 K=2,J
              A(I,J)=A(I,J)+B(J,K)*T(I)**(K-1)
   80       CONTINUE
   90     CONTINUE
  100   CONTINUE
      END IF
C compute X and CHI2
      DO 140 J=1,NR
        X(J)=ZERO
        CHI2(J)=ZERO
        DO 110 I=1,N
          X(J)=X(J)+G(I)*A(I,J)*Y(I)
  110   CONTINUE
        DO 130 I=1,N
          S=ZERO
          DO 120 K=1,J
            S=S+A(I,K)*X(K)
  120     CONTINUE
          CHI2(J)=CHI2(J)+G(I)*(Y(I)-S)**2
  130   CONTINUE
  140 CONTINUE
      END
      SUBROUTINE TIMSER(Y,N,K,L,P,ETA,CONETA,A,ATA1,ATA1AT,SCRAT)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION Y(N),ETA(N+2*K),CONETA(N+2*K),A(2*K+1,L+1)
      DIMENSION ATA1(L+1,L+1),ATA1AT(L+1,2*K+1),SCRAT(L+1,L+1)
      PARAMETER (MAX=1000, ZERO=0.D0, ONE=1.D0, HALF=0.5D0)
      DIMENSION X(MAX),YTMP(MAX),ETATMP(MAX),T(MAX)
      COMMON /DADV03/ X,YTMP,ETATMP,T
C quantile of Student's distribution
      PPRIME=HALF*(P+1)
      NF=2*K-L
      TALPHA=SQSTUD(PPRIME,NF)
C compute matrices depending only on K and L
      K21=2*K+1
      L1=L+1
      DO 20 I=1,K21
        DO 10 J=1,L1
          IF(J.EQ.1) THEN
            A(I,J)=-ONE
          ELSE
            A(I,J)=A(I,J-1)*DBLE(I-K-1)
          END IF
   10   CONTINUE
   20 CONTINUE
      CALL MTXMAT(A,A,ATA1,L1,K21,L1)
      CALL MTXCHI(ATA1,SCRAT,L1)
      CALL MTXMBT(ATA1,A,ATA1AT,L1,L1,K21)
      CALL MTXMSC(ATA1AT,ATA1AT,-ONE,L1,K21)
C loop over inner part of time series
      IA=2*K+1
      IB=N
      DO 60 I=IA,IB
C moving averages and confidence limits for inner part
        CALL MTXGSM(Y,YTMP,N,1,K21,1,I-IA+1,1)
        CALL MTXMLT(ATA1AT,YTMP,X,L1,K21,1)
        ETA(I)=X(1)
        CALL MTXMLT(A,X,ETATMP,K21,L1,1)
        CALL MTXADD(YTMP,ETATMP,ETATMP,K21,1)
        CALL MTXMAT(ETATMP,ETATMP,SY2,1,K21,1)
        SY2=SY2/DBLE(NF)
        A0=SQRT(ABS(ATA1(1,1)))
        CONETA(I)=A0*SQRT(SY2)*TALPHA
C moving averages and confidence limits for end sections
        IF(I.EQ.IA .OR. I.EQ.IB) THEN
          IF(I.EQ.IA) THEN
            IADD=IA
            IS=-1
          ELSE
            IADD=IB
            IS=1
          END IF
          DO 50 I1=1,2*K
            J=IS*I1
            DO 40 I2=1,L1
              DO 30 I3=1,I2
                IF(I3.EQ.1) THEN
                  T(I2)=ONE
                ELSE
                  T(I2)=T(I2)*J
                END IF
   30         CONTINUE
   40       CONTINUE
            CALL MTXMBT(ATA1,T,SCRAT,L1,L1,1)
            CALL MTXMLT(T,SCRAT,SETA2,1,L1,1)
            SETA2=SY2*SETA2
            CALL MTXMLT(T,X,ETAI,1,L1,1)
            CONETA(IADD+J)=SQRT(ABS(SETA2))*TALPHA
            ETA(IADD+J)=ETAI
   50     CONTINUE
        END IF
   60 CONTINUE
      END
      DOUBLE PRECISION FUNCTION SQSTUD(P,N)
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      PARAMETER(BIG=1D10,EPSILN=1D-6,ONE=1.D0,ZERO=0.D0,HALF=.5D0)
      EXTERNAL SZSTUD
         SqSTUD=ZERO
C boundary of range
      IF(P.GE.ONE) SQSTUD=BIG
      IF(P.LE.ZERO) SQSTUD=-BIG
C normal range
      IF(P.LT.ONE .AND. P.GT.ZERO) THEN
        X0=ZERO
        X1=P
        CALL AUXZBR(X0,X1,SZSTUD,P,N,0)
        CALL AUXZFN(X0,X1,XZERO,SZSTUD,P,N,0,EPSILN)
        SQSTUD=XZERO
      END IF
      END
C-----------------------------------------------------------------
      DOUBLE PRECISION FUNCTION SZSTUD(X,P,N,NDUM)
C returns P minus cumulative Student's distribution of (X,N)
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      SZSTUD=P-SCSTUD(X,N)
      END
      SUBROUTINE MTXMAT(A,B,R,M,L,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(L,M),B(L,N),R(M,N)
      DO 30 J=1,N
        DO 20 I=1,M
          R(I,J)=0.
          DO 10 LL=1,L
            R(I,J)=R(I,J)+A(LL,I)*B(LL,J)
   10     CONTINUE
   20   CONTINUE
   30 CONTINUE
      END
      SUBROUTINE MTXCHI(A,U,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(N,N),U(N,N)
C Step 1: Cholesky decomposition
      CALL MTXCHL(A,U,N)
      DO 50 I=1,N
C Step 2: Forward Substitution
        DO 20 L=I,N
          IF(L.EQ.I) THEN
            A(N,L)=DBLE(1.)/U(L,L)
          ELSE
            A(N,L)=DBLE(0.)
            DO 10 K=I,L-1
              A(N,L)=A(N,L)-U(K,L)*A(N,K)
   10       CONTINUE
            A(N,L)=A(N,L)/U(L,L)
          END IF
   20   CONTINUE
C Step 3: Back Substitution
        DO 40 L=N,I,-1
          IF(L.EQ.N) THEN
            A(I,L)=A(N,L)/U(L,L)
          ELSE
            A(I,L)=A(N,L)
            DO 30 K=N,L+1,-1
              A(I,L)=A(I,L)-U(L,K)*A(I,K)
   30       CONTINUE
            A(I,L)=A(I,L)/U(L,L)
          END IF
   40   CONTINUE
   50 CONTINUE
C Fill lower triangle symmetrically
      IF(N.GT.1) THEN
        DO 70 I=1,N
          DO 60 L=1,I-1
            A(I,L)=A(L,I)
   60     CONTINUE
   70   CONTINUE
      END IF
      END
      SUBROUTINE MTXMBT(A,B,R,M,L,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(M,L),B(N,L),R(M,N)
      DO 30 J=1,N
        DO 20 I=1,M
          R(I,J)=0.
          DO 10 LL=1,L
            R(I,J)=R(I,J)+A(I,LL)*B(J,LL)
   10     CONTINUE
   20   CONTINUE
   30 CONTINUE
      END
      SUBROUTINE MTXMSC(A,R,S,M,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(M,N),R(M,N)
      DO 20 J=1,N
        DO 10 I=1,M
          R(I,J)=S*A(I,J)
   10   CONTINUE
   20 CONTINUE
      END
      SUBROUTINE MTXGSM(A,S,M,N,K,L,M1,N1)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(M,N), S(K,L)
      DO 20 I=1,K
        DO 10 J=1,L
          S(I,J)=A(M1-1+I,N1-1+J)
   10   CONTINUE
   20 CONTINUE
      END
      SUBROUTINE MTXMLT(A,B,R,M,L,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(M,L),B(L,N),R(M,N)
      DO 30 J=1,N
        DO 20 I=1,M
          R(I,J)=0.
          DO 10 LL=1,L
            R(I,J)=R(I,J)+A(I,LL)*B(LL,J)
   10     CONTINUE
   20   CONTINUE
   30 CONTINUE
      END
      SUBROUTINE MTXADD(A,B,R,M,N)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION A(M,N),B(M,N),R(M,N)
      DO 20 J=1,N
        DO 10 I=1,M
          R(I,J)=A(I,J)+B(I,J)
   10   CONTINUE
   20 CONTINUE
      END
      SUBROUTINE MTXCHL(A,U,N)
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      DIMENSION A(N,N),U(N,N)
      CALL MTXZER(U,N,N)
      DO 30 K=1,N
        S=0.
        DO 20 J=K,N
          IF(K.GT.1) THEN
            S=0.
            DO 10 L=1,K-1
              S=S+U(L,K)*U(L,J)
   10       CONTINUE
          END IF
          U(K,J)=A(K,J)-S
          IF(K.EQ.J) THEN
            U(K,J)=SQRT(ABS(U(K,J)))
          ELSE
            U(K,J)=U(K,J)/U(K,K)
          END IF
   20   CONTINUE
   30 CONTINUE
      END
      SUBROUTINE AUXZBR(X0,X1,FUNCT,PAR,NPAR1,NPAR2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER (ZERO=0.D0, ONE=1.D0, TWO=2.D0)
      EXTERNAL FUNCT
      IF(X0.EQ.X1) X1=X0+ONE
      F0=FUNCT(X0,PAR,NPAR1,NPAR2)
      F1=FUNCT(X1,PAR,NPAR1,NPAR2)
      DO 10 I=1,1000
        IF(F0*F1 .GT. ZERO) THEN
          IF(ABS(F0).LE.ABS(F1)) THEN
            XS=X0
            X0=X0+TWO*(X0-X1)
            X1=XS
            F1=F0
            F0=FUNCT(X0,PAR,NPAR1,NPAR2)
          ELSE
            XS=X1
            X1=X1+TWO*(X1-X0)
            X0=XS
            F0=F1
            F1=FUNCT(X1,PAR,NPAR1,NPAR2)
          END IF
        ELSE
          GO TO 20
        END IF
   10 CONTINUE
   20 CONTINUE
      END
      SUBROUTINE AUXZFN(X0,X1,XZERO,FUNCT,PAR,NPAR1,NPAR2,EPSILN)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER (ZERO=0.D0, HALF=0.5D0)
      EXTERNAL FUNCT
      XZERO=X0
      DO 10 I=1,2000
        F0=FUNCT(X0,PAR,NPAR1,NPAR2)
        F1=FUNCT(X1,PAR,NPAR1,NPAR2)
        IF(F0.EQ.ZERO) THEN
          XZERO=X0
          GO TO 20
        ELSE IF(F1.EQ.ZERO) THEN
          XZERO=X1
          GO TO 20
        END IF
        XM=HALF*(X0+X1)
        IF(ABS(X0-X1).GE.EPSILN) THEN
          FM=FUNCT(XM,PAR,NPAR1,NPAR2)
          TEST=F0*FM
          IF(TEST .LT. ZERO) THEN
            X1=XM
          ELSE
            X0=XM
          END IF
        ELSE
          XZERO=XM
          GO TO 20
        END IF
   10 CONTINUE
   20 CONTINUE
      END
      DOUBLE PRECISION FUNCTION SCSTUD(X,N)
      IMPLICIT DOUBLE PRECISION(A-H,O-Z)
      PARAMETER (ZERO=0.D0, ONE=1.D0, HALF=0.5D0)
      AN=DBLE(N)
      AN2=HALF*AN
      ARG=AN/(AN+X**2)
      A=GINCBT(AN2,HALF,ARG)
      IF(X.GE.ZERO) THEN
        SCSTUD=ONE-HALF*A
      ELSE
        SCSTUD=HALF*A
      END IF
      END
      SUBROUTINE MTXZER(R,N,M)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION R(N,M)
      DO 20 J=1,M
        DO 10 I=1,N
          R(I,J)=0.
   10   CONTINUE
   20 CONTINUE
      END
      DOUBLE PRECISION FUNCTION GINCBT(AA,BB,XX)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      LOGICAL REFLEC
      PARAMETER(EPSILN=1.D-8, ONE=1.D0, ZERO=0.D0, TWO=2.D0)
      XLIM=(AA+ONE)/(AA+BB+ONE)
      IF (XX.LT.XLIM) THEN
        REFLEC=.FALSE.
        A=AA
        B=BB
        X=XX
      ELSE
        REFLEC=.TRUE.
        A=BB
        B=AA
        X=ONE-XX
      END IF
      IF(X.LT.EPSILN) THEN
C function known at end of range
        CF=0.
      ELSE
C continued fraction
        A1=ONE
        B1=ONE
        A2=ONE
        B2=ONE-(A+B)*X/(A+ONE)
        FNORM=ONE/B2
        CF=A2*FNORM
        DO 10 M=1,100
          RM=DBLE(M)
          APL2M=A+TWO*RM
          D2M=RM*(B-RM)*X/((APL2M-ONE)*APL2M)
          D2M1=-(A+RM)*(A+B+RM)*X/(APL2M*(APL2M+1))
          A1=(A2+D2M*A1)*FNORM
          B1=(B2+D2M*B1)*FNORM
          A2=A1+D2M1*A2*FNORM
          B2=B1+D2M1*B2*FNORM
          IF(B2.NE.0.) THEN
C renormalize and test for convergence
            FNORM=ONE/B2
            CFNEW=A2*FNORM
            IF(ABS(CF-CFNEW)/CF .LT. EPSILN) GO TO 20
            CF=CFNEW
          END IF
   10   CONTINUE
   20   CF=CF*(X**A)*((ONE-X)**B)/(A*GBETAF(A,B))
      END IF
      IF(REFLEC) THEN
        GINCBT=ONE-CF
      ELSE
        GINCBT=CF
      END IF
      END
      DOUBLE PRECISION FUNCTION GBETAF(Z,W)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      PARAMETER(BIG=1.D30, EPSILN=1.D-8)
      IF(W.LT.EPSILN) THEN
        GBETAF=BIG
      ELSE
        GBETAF=EXP(GLNGAM(Z)+GLNGAM(W)-GLNGAM(Z+W))
      END IF
      END
      DOUBLE PRECISION FUNCTION GLNGAM(X)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION C(6)
      LOGICAL REFLEC
      PARAMETER(RTWOPI=2.506628275D0, PI=3.141592654D0, ONE=1.D0)
      PARAMETER(HALF=0.5D0)
      DATA C/76.18009173D0,-86.50532033D0,24.01409822D0,
     +-1.231739516D0,0.120858003D-2,-0.536382D-5/
      IF(X.GE.ONE) THEN
        REFLEC=.FALSE.
        XX=X-ONE
      ELSE
        REFLEC=.TRUE.
        XX=ONE-X
      END IF
      XH=XX+HALF
      XGH=XX+DBLE(5.5)
      S=ONE
      ANUM=XX
      DO 10 I=1,6
        ANUM=ANUM+ONE
        S=S+C(I)/ANUM
   10 CONTINUE
      S=S*RTWOPI
      G=XH*LOG(XGH)+LOG(S)-XGH
      IF (REFLEC) THEN
        GLNGAM=LOG(PI*XX)-G-LOG(SIN(PI*XX))
      ELSE
        GLNGAM=G
      END IF
      END
    
        subroutine xysortcd(n,array,yarray,zarray)
c
c the same function as xysort but with different algorithm
c
        implicit none
        integer n
        real array(n)
        complex yarray(n)
        double precision zarray(n)
c
c  Sorts an array, ARRAY, of length N into ascending order using a
c  Heapsort algorithm. ARRAY is replaced on output by its sorted
c  rearrangement. The second array elements are in complex.
c  The third array elements are in double precision.
c
c  Input:
c  n              Number of elements to be sorted.
c
c  Input/Output:
c  array,yarray,zarray  Input: Elements to be sorted.
c                 Output: Sorted elements.
c--
c------------------------------------------------------------------------
      INTEGER L,IR,J,I
      real RRA
      complex YRRA
      double precision ZRRA
c
      L=N/2+1
      IR=N
10    CONTINUE
        IF(L.GT.1)THEN
          L=L-1
          RRA=ARRAY(L)
                                                                                
          YRRA=YARRAY(L)
          ZRRA=ZARRAY(L)
        ELSE
          RRA=ARRAY(IR)
          ARRAY(IR)=ARRAY(1)
                                                                                
          YRRA=YARRAY(IR)
          YARRAY(IR)=YARRAY(1)

          ZRRA=ZARRAY(IR)
          ZARRAY(IR)=ZARRAY(1)
                                                                      
          IR=IR-1
          IF(IR.LE.1)THEN
            ARRAY(1)=RRA
            YARRAY(1)=YRRA
            ZARRAY(1)=ZRRA
            RETURN
          ENDIF
        ENDIF
        I=L
        J=L+L
20      IF(J.LE.IR)THEN
          IF(J.LT.IR)THEN
            IF(ARRAY(J).LT.ARRAY(J+1))J=J+1
          ENDIF
          IF(RRA.LT.ARRAY(J))THEN
            ARRAY(I)=ARRAY(J)
            YARRAY(I)=YARRAY(J)
            ZARRAY(I)=ZARRAY(J)
            I=J
            J=J+J
          ELSE
            J=IR+1
          ENDIF
        GO TO 20
        ENDIF
        ARRAY(I)=RRA
        YARRAY(I)=YRRA
        ZARRAY(I)=ZRRA
         GO TO 10
      END

