c************************************************************************
        program smamfcal
c
c= smaMfCal -- Multifrequency antenna and passband calibration.
c& jhz for SMA based on rjs' mfcal
c: calibration
c+
c	SmaMfCal is a Miriad task which determines calibration corrections
c	(antenna gains, delay terms and passband shapes) from a
c	multi-frequency observation.  The delays and passband are
c	determined from an average of all the selected data.  The gains
c	are worked out periodically depending upon the user
c	selected interval. SmaMfcal implements algothrims for weighting,
c       continuum vector normalization, and moving smooth prior to solving
c       for bandpass and gains, which are necessary for handling data
c       at submillimeter wavelength when the S/N is poor and phase dispersion
c       is large. The basic solving algorithms are the same as in Mfcal.
c@ vis
c	Input visibility data file. No default. This can (indeed should)
c	contain multiple channels and spectral windows. The frequency
c	set-up can vary with time.
c@ line
c	Standard line parameter, with standard defaults.
c@ edge
c	The number of channels, at the edges of each spectral window, that
c	are to be dropped. Either one or two numbers can be given, being the
c	number of channels at the start and end of each spectral window to be
c	dropped. If only one number is given, then this number of channels
c	is dropped from both the start and end. The default value is 0.
c@ select
c	Standard uv selection. Default is all data.
c@ flux
c	Three numbers, giving the source flux, the reference frequency
c	(in GHz) and the source spectral index. The flux and spectral index
c	are at the reference frequency. If not values are given, then SmaMFCAL
c	checks whether the source is one of its known sources, and uses the
c	appropriate flux variation with frequency. Otherwise the default flux
c	is determined so that the rms gain amplitude is 1, and the default
c	spectral index is 0. The default reference frequency is the mean of
c	the frequencies in the input data. Also see the `oldflux' option.
c@ refant
c	The reference antenna. Default is 3. The reference antenna needs
c	to be present throughout the observation. Any solution intervals
c	where the reference antenna is missing are discarded.
c@ minants
c	The minimum number of antennae that must be present before a
c	solution is attempted. Default is 2.
c@ interval
c	This gives one or two numbers, both given in minutes, both being
c	used to determine the extents of the gains calibration solution
c	interval. The first gives the max length of a solution interval. The
c	second gives the max gap size in a solution interval. A new solution
c	interval is started when either the max times length is exceeded, or a
c	gap larger than the max gap is encountered. The default max length is
c	5 minutes, and the max gap size is the same as the max length.
c@ weight
c       This gives different ways to determine weights (wt) prior to 
c       solving for bandpass: 
c        -1 -> wt = 1; the same weighting method as used in MFCAL.
c         1 -> wt ~ amp0**2/var(i); for a normalized channel 
c                   visibility, the reduced variance is proportional 
c                   to amp0**2/var(i), where amp0 is the amplitude 
c                   of the pseudo continuum and var(i) is the variance
c                   of visibility for the ith channel.
c         2 -> wt ~ amp0**4/var(i)**2; 
c       Default is 2 for SMA and -1 for other telescopes.   
c            if you have stable phase, use -1;
c            if the phase stability is poor, use 1 or 2;
c            for a larger planet, 2 is recommended.
c
c       For antenna gains' solver:
c        -1 -> wt = 1; the same weight method that is used in MFCAL.
c        >0 -> wt = 1/var, where var is the visibility variance.
c       Defualt is 1/var.
c@ options
c	Extra processing options. Several values can be given, separated by
c	commas. Minimum match is used. Possible values are:
c	  delay     Attempt to solve for the delay parameters. This can
c	            be a large sink of CPU time.
c	  nopassol  Do not solve for bandpass shape. In this case if a bandpass
c	            table is present in the visibility data-set, then it will
c	            be applied to the data.
c	  interpolate Interpolate (and extrapolate) via a spline fit (to
c	            the real and imaginary parts) bandpass values for
c	            channels with no solution (because of flagging).  If
c	            less than 50% of the channels are unflagged, the
c	            interpolation (extrapolation) is not done and those
c	            channels will not have a bandpass solution
c	  oldflux   This causes SmaMFCAL to use a pre-August 1994 ATCA flux
c	            density scale. See the help on "oldflux" for more
c	            information.
c         msmooth      Do moving average of the uv data (the real and 
c                      imaginary parts) using the keyword smooth parameters 
c                      specified prior to solving for bandpass.
c         opolyfit     Do least-square fit to the bandpass solutions
c                      (the real and imaginary parts) with an orthogonal 
c                      polynomial of degree n which can be given in keyword
c                      polyfit.
c         wrap         Don't unwrap phase while do fit or smooth
c                      the uv data.
c         averrll      In the case of solving for bandpass of dual
c                      polarizations, averrll gives vector average 
c                      of rr and ll bandpass solutions; the mean value 
c                      is written into the bandpass table for each of rr 
c                      and ll.
c
c@ smooth
c       This gives three parameters of moving smooth calculation of the
c       bandpass/gain curves
c       smooth(1) = K  parameter k giving the length 2k+1 of the averaging
c                      interval; default is 3.
c       smooth(2) = L  order of the averaging polynomial l; default is 1.
c       smooth(3) = P  probability P for computing the confidence limits;
c                      default is 0.9.
c
c@ polyfit
c       polyfit gives a degree of orthogonal polynomial in least-sqaure
c       fit to the bandpass/gain curves. Default is 3.
c       polyfit: 1 (linear), 2 (parabolic), 3 (cubic), ....
c@ tol
c	Solution convergence tolerance. Default is 0.001.
c--
c  History:
c    jhz  09aug04 extends for SMA data
c    jhz  16Oct04 added moving smooth uv data prior to solving for
c                 gains/bandpass.
c    jhz  17Dec04 added an option othogonal polynorm fit to the passs 
c                 solutions.
c    jhz  20Dec04 added weight=1/sigma**2
c    jhz  31Dec04 added weight=1/sigma**2, divided by channel zero
c    jhz  05May05 enable to handle dual polarization data
c    jhz  27May05 fixed edge problem
c    jhz  20Jul05 fixed things caused the warning messages.
c    jhz  16sep05 fixed normaliztion by channel zero in the case of
c                 solving for bandpass 
c                 added the options of averrll for
c                 taking vector average of rr and ll bandpass.
c    jhz  22may06 increased  maxschan from 1024 to 4096 for
c                 handling high spectral resolution data.
c    jhz  29Sep06 fixed a bug in smoothing when edge flagging is present.
c    jhz  11Oct06 took out inttime from rms weight; inttime has been
c                 included in variance.
c    jhz  07Dec06 put mirconst.h back
c    jhz  11Dec06 corrected a bug in the case of weight=-1
c    jhz  13Dec06 implemented a feature in smooth for
c                 handling multiple bands with hybrid channel
c                 resolutions.
c    jhz  15Dec06 Updated MfCal algorithm (MfCal: version 11-feb-05)
c    jhz  18Dec06 implemented band-dependent weighting (systemp(j)
c                 sdf(j).
c                 Treat SMA differently from other telescopes
c                 in calculating bandpass:
c                 For SMA, considering the fact that signals are 
c                 weak but small phase jumps are between different 
c                 bands due to on-line correction, all the band 
c                 are used in calculating the pseudo continuum 
c                 vis. Note SMA treats sideband separately.
c                 For other lower frequency telescopes, signals
c                 are stronger but there might be large phase jumps 
c                 between bands. Only the first band data are used 
c                 in calculating the pseudo continuum.
c   jhz  15Jun07  added instructive msg for handling SMA
c                 hybrid spectral resolution data.
c  pkgw  11Apr08  When fitting polynomials, give flagged channels
c                 virtually no weight.
c   jhz  24Jun08  added description on the working buffers in
c                 passtab.
c  Problems:
c    * Should do simple spectral index fit.
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxspect,maxvis,maxsoln,maxiter,maxpol
        parameter(maxspect=49,maxvis=7000000,maxiter=30,maxsoln=1024)
        parameter(maxpol=2)
c
        character version*80, versan*80
c
        integer tno
        integer pwgains,pfreq,psource,ppass,pgains,ptau
        integer popass,pogains,potau
        integer nvis,vid(maxvis)
        integer nspect,nschan(maxspect),ischan(maxspect)
        integer npol,nants,nsoln,count(maxsoln),nchan,refant,minant
        integer niter,edge(2),polmap(maxpol),pee(maxpol)
        real flux(3),tol,epsi
        double precision freq0,sfreq(maxspect),sdf(maxspect)
        double precision freqc(maxspect)
        double precision interval(2),time(maxsoln)
        complex vis(maxvis)
        real wt(maxvis)
        character line*64,uvflags*16,source*64
        logical dodelay,dopass,defflux,interp,oldflux
        logical dosmooth,donply,dowrap,doaverrll,defaultwt
c
c  Dynamic memory stuff.
c
        integer weight
        real ref(maxbuf)
        complex cref(maxbuf/2)
        double precision dref(maxbuf/2)
        equivalence(ref,cref,dref)
        real smooth(3)
        integer nply(3),bnply(3)
        common ref
        common/bsmooth/smooth,bnply
c
c  Externals.
c
        logical uvdatopn,keyprsnt
c
c  Some intialization
c
        defaultwt = .false.
c
c  Get inputs and check them.
c
        version = versan('smamfcal',
     * '$Id$')
        call keyini
        call getopt(dodelay,dopass,interp,oldflux,
     *              dosmooth,donply,dowrap,doaverrll)
        uvflags = 'dlbx'
        if(.not.dopass)uvflags(5:5) = 'f'
        call uvdatinp('vis',uvflags)
        call keyi('refant',refant,3)
        call keyi('minants',minant,2)
        defflux = .not.keyprsnt('flux')
        call keyr('flux',flux(1),1.0)
        call keyr('flux',flux(2),0.0)
        call keyr('flux',flux(3),0.0)
        call keyi('edge',edge(1),0)
        call keyi('edge',edge(2),edge(1))
        call keyd('interval',interval(1),5.0d0)
        call keyd('interval',interval(2),interval(1))
        call keyi('weight', weight, 1000)
            if (weight.eq.1000) then
            defaultwt = .true.
            weight = 2
            endif
            if (weight.lt.0) weight=-1
            if (weight.eq.0) weight=1
            if (weight.ge.3) then
        call output('weight = 3 or greater ... ')
        call bug('f', 'Sorry, we no longer support this weighting.')
            end if      
        call keyr('smooth',smooth(1), 3.)
        call keyr('smooth',smooth(2), 1.)
        call keyr('smooth',smooth(3), 0.9)
        call keyi('polyfit', nply(1), 3)
        call keyi('polyfit', nply(2), 0)
        call keyi('polyfit', nply(3), 0)
c nply(3)=100 to plot smooth curve; nply(3)=200 to plot opolfit curve
                      if(dopass) then
                      bnply(1)=nply(1)
                      bnply(2)=nply(2)
                      bnply(3)=nply(3)
                      end if
        call keyr('tol',tol,0.001)
        if(donply.and.(nply(1).le.0))
     &  call bug('f', 'assign polyfit(1) a possitive integer.')
        if(dosmooth.and.(smooth(1).eq.0))
     &  call bug('f', 'assign smooth(1) a possitive integer.')
        call keyfin
c
        if(minant.lt.2)
     *    call bug('f','Bad value minant parameter')
        if(refant.le.0)
     *    call bug('f','Bad value for the reference antenna parameter')
        if(flux(1).le.0.or.flux(2).lt.0)
     *    call bug('f','Bad values for the flux parameter')
        if(edge(1).lt.0.or.edge(2).lt.0)
     *    call bug('f','Bad value for the edge parameter')
c
        if(interval(1).le.0.or.interval(2).le.0)
     *    call bug('f','Bad value for the interval parameter')
        interval(2) = min(interval(1),interval(2))
        interval(1) = interval(1) / (24*60)
        interval(2) = interval(2) / (24*60)
c
        if(tol.le.0.or.tol.ge.1)
     *    call bug('f','Bad value for the tol parameter')
c
c  Open the input file.
c
        if(.not.uvdatopn(tno))call bug('f','Error opening input file')
        call hisopen(tno,'append')
        call hiswrite(tno,'SmaMFCAL: '//version)
        call hisinput(tno,'SmaMFCAL')
c
c  Get the input data.
c
        call output('Reading the data ...')
        call datread(tno,maxvis,nvis,npol,vis,wt,vid,
     *       maxspect,nspect,sfreq,sdf,nschan,nants,
     *       maxsoln,nsoln,time,count,minant,refant,interval,
     *       edge,source,polmap,dopass,dosmooth,donply,dowrap,
     *       weight,defaultwt)
c
c  Check that the polarisations present are commensurate.
c
        call polcheck(npol,polmap,pee)
c          
c  Determine the nschan thingo.
c
        call output('Initialising ...')
        call chancvt(nspect,nschan,nchan,ischan)
c
c  Determine the reference frequency.
c
        freq0 = flux(2)
        if(freq0.le.0)call averfreq(nspect,nschan,sfreq,sdf,freq0)
c
c  Generate the frequencies for each channel in the total passband.
c
        call memalloc(pfreq,nchan,'d')
        call freqgen(nspect,nschan,sfreq,sdf,
     *                          freqc,dref(pfreq),nchan)
c
c  Generate the source model.
c
        call memalloc(psource,nchan,'r')
        call srcgen(source,oldflux,defflux,
     *    ref(psource),nchan,dref(pfreq),freq0,flux(1),flux(3))
c
c  Now make the frequency relative to the reference frequency.
c
        call freqrel(dref(pfreq),freq0,nchan)
        call freqrel(freqc,freq0,nspect)
c
c  Allocate some extra memory.
c
        call memalloc(ppass,nants*nchan*npol,'c')
        call memalloc(pgains,nants*nsoln*npol,'c')
        call memalloc(ptau,nants*nsoln,'r')
        call memalloc(popass,nants*nchan*npol,'c')
        call memalloc(pogains,nants*nsoln*npol,'c')
        call memalloc(potau,nants*nsoln,'r')
c
c  Get an initial estimate of the wide gains and passband.
c
        call output('Generating initial solution estimate ...')
        call memalloc(pwgains,nants*nspect*nsoln*npol,'c')
c
c
c  Estimate the "wide" gains. The gains in each spectral window are
c  solved for independently.
c
        call wgini(vis,wt,vid,ischan,nvis,npol,count,nsoln,nchan,
     *    nants,nspect,ref(psource),cref(pwgains),refant,minant)
c
c  Given the gains for each antenna for each band (WGains), estimate the
c  passband gain (Pass), atmospheric delay (Tau) and antenna gain (Gains).
c  These are estimates that are used in a full-blown solver later on.
c
        call bpini(npol,nants,nchan,nsoln,nspect,nschan,cref(pwgains),
     *    freqc,cref(ppass),cref(pgains),ref(ptau),dodelay,dopass)
        call memfree(pwgains,nants*nspect*nsoln*npol,'c')
c
c  Normalise the gains, and make a copy for later comparison.
c
        if(dopass)call norm(npol,nants,nchan,nsoln,cref(ppass),
     *    cref(pgains),ref(ptau),dref(pfreq))
c
        call gaincpy(npol,nants,nchan,nsoln,cref(ppass),cref(pgains),
     *    ref(ptau),cref(popass),cref(pogains),ref(potau))
c
c  We have estimates of the antenna gains (Gains), the delay term
c  (Tau) and the passbands (Pass). Perform the main solver iterations.
c
        call output('Doing solution refinement ...')
        niter = 0
        epsi = 1
        dowhile(epsi.gt.tol.and.niter.lt.maxiter)
          niter = niter + 1
c
c  Get the antenna gains and delay.
c
          call solvegt(refant,minant,nants,nspect,nchan,nsoln,
     *      cref(ppass),ref(psource),dref(pfreq),vis,wt,vid,ischan,
     *      count,nvis,npol,cref(pgains),ref(ptau),
     *      dodelay.and.niter.ne.1,tol)
c
c  Get the passband.
c
          if(dopass)call solvebp(refant,minant,nants,nspect,nchan,nsoln,
     *      cref(ppass),ref(psource),dref(pfreq),vis,wt,vid,ischan,
     *      count,nvis,npol,cref(pgains),ref(ptau),tol)
c
c  Normalise the total gains so that the average delay is zero and
c  the rms passband gain is 1.
c
          if(dopass)call norm(npol,nants,nchan,nsoln,cref(ppass),
     *      cref(pgains),ref(ptau),dref(pfreq))
c
c  Compare the solution with previous solutions.
c
          call gaincmp(npol,nants,nchan,nsoln,cref(ppass),cref(pgains),
     *          ref(ptau),cref(popass),cref(pogains),ref(potau),epsi)
c
c  Keep the user awake.
c
          write(line,'(a,i2,a,f7.3)')'Iter=',niter,
     *                               ', Solution Error:',epsi
          call output(line)
        enddo
c
c  Scale the gains if we have no idea what the source flux really was.
c
        if(defflux)then
          call gainscal(flux,cref(pgains),npol*nants*nsoln)
          write(line,'(a,f8.3)')'I flux density: ',flux(1)
          call output(line)
        endif
c
        if(epsi.gt.tol)call bug('w','Failed to converge')
        call output('Saving solution ...')
        call gaintab(tno,time,cref(pgains),ref(ptau),npol,nants,nsoln,
     *    freq0,dodelay,pee)
        if (dopass.and.interp) call intext(npol,nants,nchan,nspect,
     *    nschan,cref(ppass))
        if(dopass)call passtab(tno,npol,nants,nchan,
     *    nspect,sfreq,sdf,nschan,cref(ppass),pee,
     *    donply,dowrap,doaverrll)
c
c  Free up all the memory, and close down shop.
c
        call memfree(potau,nants*nsoln,'r')
        call memfree(pogains,nants*nsoln*npol,'c')
        call memfree(popass,nants*nchan*npol,'c')
        call memfree(ptau,nants*nsoln,'r')
        call memfree(pgains,nants*nsoln*npol,'c')
        call memfree(ppass,nants*nchan*npol,'c')
        call memfree(psource,nchan,'r')
        call memfree(pfreq,nchan,'d')
        call hisclose(tno)
        call uvdatcls
c
        end
c************************************************************************
        subroutine gainscal(flux,gains,ngains)
c
        integer ngains
        complex gains(ngains)
        real flux
c
c  Scale the gains and the flux so that the rms gain is 1.
c
c  Input:
c    ngains	Number of gains.
c  Input/Output:
c    Gains	The gains.
c    flux	Nominal source flux.
c------------------------------------------------------------------------
        real sum2,t
        integer n,i
c
        n = 0
        sum2 = 0
        do i=1,ngains
          t = real(gains(i))**2 + aimag(gains(i))**2
          if(t.gt.0)then
            sum2 = sum2 + t
            n = n + 1
          endif
        enddo
c
c  Return if all the gains are flagged bad.
c
        if(sum2.eq.0)return
c
c  Scale the gains.
c
        t = sqrt(n/sum2)
        do i=1,ngains
          gains(i) = t*gains(i)
        enddo
c
c  Scale the flux.
c
        t = sum2/n
        flux = t*flux
c
        end
c************************************************************************
        subroutine polcheck(npol,polmap,pee)
c
        integer npol,polmap(npol),pee(npol)
c
c  This checks that the polarisations present are commensurate (either
c  both circulars or both linears).
c  It also initialises the array which determines the order that the
c  solutions are written out in.
c
c------------------------------------------------------------------------
        pee(1) = 1
        if(npol.eq.1)return
        if(npol.gt.2)call bug('f','Something is screwy')
        if(abs(polmap(1)-polmap(2)).ne.1)call bug('f',
     *      'Incommensurate polarisations selected')
        if(polmap(2).gt.polmap(1))then
          pee(1) = 2
          pee(2) = 1
        else
          pee(1) = 1
          pee(2) = 2
        endif
        end
c************************************************************************
        subroutine getopt(dodelay,dopass,interp,oldflux,
     *   dosmooth,donply,dowrap,doaverrll)
c
        logical dodelay,dopass,interp,oldflux
        logical dosmooth,donply,dowrap,doaverrll
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=8)
        logical present(nopt)
        character opts(nopt)*11
        data opts/ 'delay      ','nopassol   ','interpolate',
     *             'oldflux    ','msmooth    ',
     *             'opolyfit   ','wrap       ','averrll  ' /
c
        call options('options',opts,present,nopt)
c
        
        dodelay =      present(1)
        dopass  = .not.present(2)
        interp  =      present(3)
        oldflux =      present(4)
        dosmooth=      present(5)
        donply  =      present(6)
        dowrap  =      present(7)
        doaverrll =    present(8)
        end
c************************************************************************
        subroutine gaintab(tno,time,gains,tau,npol,nants,nsoln,
     *  freq0,dodelay,pee)
c
        integer tno,nants,nsoln,npol,pee(npol)
        double precision time(nsoln),freq0
        real tau(nants,nsoln)
        complex gains(nants,npol,nsoln)
        logical dodelay
c
c  Write out the antenna gains and the delays.
c
c  Input:
c    tno
c    time
c    Gains
c    Tau
c    npol	Number of polarisations. Either 1 or 2.
c    nants
c    nsoln
c    dodelay	True if the delays are to be written out.
c    pee	Mapping from internal polarisation number to the order
c		that we write the gains out in.
c------------------------------------------------------------------------
c  
       include 'maxdim.h'
       include 'mirconst.h'
        integer iostat,off,item,i,j,p,pd,j1,ngains
        complex g(3*maxant)
c
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
c
c  Write out all the gains.
c
        ngains = npol*nants
        if(dodelay) ngains = (npol+1)*nants
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
              if(abs(real( gains(j,pd,i)))+
     *           abs(aimag(gains(j,pd,i))).ne.0)then
                g(j1) = 1/gains(j,pd,i)
              else
                g(j1) = (0.,0.)
              endif
              j1 = j1 + 1
            enddo
            if(dodelay)then
              g(j1) = cmplx(0.,-2*pi*tau(j,i))
              j1 = j1 + 1
            endif
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
        subroutine passtab(tno,npol,nants,nchan,
     *  nspect,sfreq,sdf,nschan,pass,pee,
     *  donply,dowrap,doaverrll)
c
        integer tno,npol,nants,nchan,nspect,nschan(nspect),pee(npol)
        complex pass(nants,nchan,npol)
        double precision sdf(nspect),sfreq(nspect)
c
c  Write out the bandpass table and frequency description table (with a
c  few other assorted parameters). This assumes that the parameters
c    ngains, nfeeds
c  have already been written out.
c
c  Input:
c    tno	Handle of the output dataset.
c    nants	Number of antennas.
c    npol	Number of polarisations (either 1 or 2).
c    nspect	The total number of frequency bands observed. This is the
c		product of the number of simultaneous spectral windows and
c		the number of different frequency settings.
c    nschan	The number of channels in each observing band.
c    nchan	Total number of channels.
c		NOTE: Here (as elsewhere in this task) "nchan" is the total
c		number of channels (the sum of all the channels from all the
c		bands observed).
c		i.e. nchan = Sum nschan(i)
c    Pass	The bandpass function. This is of size nants * nchan * npol.
c		The bandpass table that we have to write out is in the order
c		nchan * npol * nants, so we have to do some reorganising
c		before we write out.
c    pee	Mapping from internal polarisation number to the order
c		that we write the gains out in. We always write X then Y
c		(or R then L).
c    sdf	Frequency increment for each observing band.
c    sfreq	Start frequency for each observing band.
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer iostat,off,item,i,j,k,n,p,pd,nsp,nterm
        complex g(maxchan),temp,avbuf
        double precision freqs(2)
        PARAMETER(MAXNR=20, pi=3.14159265358979323846)
        double precision Rsp(nchan),Isp(nchan),xchan(nchan),DELY(nchan)
        double precision XA(MAXNR),BP(MAXNR,MAXNR)
        double precision AP(nchan,MAXNR),CHI2(MAXNR)
        real rxchan(nchan),rRsp(nchan),rIsp(nchan)
        real amp,phase,pphase,revis,imvis,plamp(nchan),plpha(nchan)
        logical dev, donply, dowrap,doaverrll
        real smooth(3)
        integer bnply(3)
        common/bsmooth/smooth,bnply
        real wt(2)
c
c working buffer
c Rsp           real part of the spectrum
c Isp           imaginary part of the spectrum
c xchan         channel number
c DELY          uncertainty of the solutions
c               DELY=1 for solutions derived from BP solver
c               DELY=1D20 for failure in getting solution from BP solver
c
        n=0
c
c average rr and ll
c
          if(doaverrll.and.(npol.eq.2)) then
         do i = 1,nants
         do j = 1,nchan
         wt(1)=0.5
         wt(2)=0.5
      if(((real(pass(i,j,1)))**2+(aimag(pass(i,j,1)))**2).lt.1.e-10)
     * then
         wt(1)=0.0
         wt(2)=1.0
       end if
      if(((real(pass(i,j,2)))**2+(aimag(pass(i,j,2)))**2).lt.1.e-10)
     * then
         if(wt(1).ge.0.5) wt(1)=1.0
         wt(2)=0.0
       end if
         avbuf= wt(1)*pass(i,j,1)+wt(2)*pass(i,j,2)
         pass(i,j,1)=avbuf
         pass(i,j,2)=avbuf
         enddo
         enddo
               end if

c
c  Fudge to create a "complex" table, then open it again.
c
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
         
           if(donply) then 
          nterm=bnply(1)+1
          do i=1,nants
          do p=1,npol
          pd = pee(p)
          do j=1,nchan,maxchan
              n = min(maxchan,nchan-j+1)
          nsp=0
             pphase=0
          do l=1, nspect
          do k=1, nschan(l)
             xchan(k) = k
             rxchan(k) = k
             DELY(k)=1.0D0
c fit amp and phase
            revis= real(pass(i,j+nsp+k-1,pd))
            imvis= aimag(pass(i,j+nsp+k-1,pd))
            amp = revis**2+imvis**2
            amp = sqrt(amp)
c check up if the solutions failed
            if(abs(revis)+
     *      abs(imvis).eq.0) then
            phase=0
            DELY(K)=1.0D20
            else
            phase = 180.0/pi *
     *      atan2(imvis,revis)
c unwrap phase
            if(.not.dowrap) then
             phase = phase - 360*nint((phase-pphase)/360.)
             pphase = 0.5*(phase + pphase)
             end if
            endif
              Rsp(k) = amp
              Isp(k) = phase
          enddo
          CALL REGPOL(xchan,Rsp,DELY,nschan(l),MAXNR,XA,BP,AP,CHI2)
          call regpolfitg(nterm,xa,bp,nschan(l),rxchan,plamp)
          CALL REGPOL(xchan,Isp,DELY,nschan(l),MAXNR,XA,BP,AP,CHI2)
          call regpolfitg(nterm,xa,bp,nschan(l),rxchan,plpha)        
            dev=.true.
          if(bnply(3).eq.200) call pgplt(nschan(l),rxchan,Rsp,plamp,dev)
            dev=.false.
          if(bnply(3).eq.200) call pgplt(nschan(l),rxchan,Isp,plpha,dev)
          do k=1, nschan(l)
            rRsp(k)=plamp(k)*cos(plpha(k)*pi/180.)
            rIsp(k)=plamp(k)*sin(plpha(k)*pi/180.)
            pass(i,j+nsp+k-1,pd)=cmplx(rRsp(k),rIsp(k))
          enddo
          nsp=nsp+nschan(l)
          enddo
          enddo
          enddo
          enddo
                end if
          do i=1,6
          do p=1,npol
            pd = pee(p)
            do j=1,8
           end do
           end do
           end do
        off = 8
        do i=1,nants
          do p=1,npol
            pd = pee(p)
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
c
c  Access the frequencies description table.
c
        call haccess(tno,item,'freqs','write',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output frequency table.')
          call bugno('f',iostat)
        endif
        call hwritei(item,0,0,4,iostat)
        if(iostat.ne.0)then
          call bug('w','Error writing header of frequency table')
          call bugno('f',iostat)
        endif
c
c  Write out all the frequencies.
c
        off = 8
        do i=1,nspect
          call hwritei(item,nschan(i),off,4,iostat)
          off = off + 8
          if(iostat.ne.0)then
          call bug('w','Error writing nschan to freq table')
          call bugno('f',iostat)
          endif
          freqs(1) = sfreq(i)
          freqs(2) = sdf(i)
          call hwrited(item,freqs,off,2*8,iostat)
          off = off + 2*8
          if(iostat.ne.0)then
          call bug('w','Error writing freqs to freq table')
          call bugno('f',iostat)
          endif
        enddo
c
c  Finished writing the frequency table.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Now write out the other parameters that need to go along with this.
c
        call wrhdi(tno,'nspect0',nspect)
        call wrhdi(tno,'nchan0',nchan)
c
        end
c************************************************************************
        subroutine norm(npol,nants,nchan,nsoln,pass,gains,tau,freq)
c
        integer npol,nants,nchan,nsoln
        complex pass(nants,nchan,npol),gains(nants,npol,nsoln)
        real tau(nants,nsoln)
        double precision freq(nchan)
c
c  Normalise the total gains so that the average delay is zero and the
c  rms passband gain is 1.
c
c  Input:
c    npol	Number of intensity polarisations -- either 1 or 2.
c    nants
c    nchan
c    nsoln
c    freq
c  Input/Output:
c    Pass	Passband function.
c    Gains	Antenna gains.
c    Tau	Delay.
c------------------------------------------------------------------------
        integer maxpol
        parameter(maxpol=2)
        include 'maxdim.h'
        include 'mirconst.h'
        real sumtau(maxant),rmspass(maxant,maxpol),temp,theta
        integer i,j,p,npass(maxant,maxpol)
c
c  Zero the accumulators.
c
        do p=1,npol
          do i=1,nants
            sumtau(i) = 0
            rmspass(i,p) = 0
            npass(i,p) = 0
          enddo
        enddo
c
c  Accumulate the average delay.
c
        do j=1,nsoln
          do i=1,nants
            sumtau(i) = sumtau(i) + tau(i,j)
          enddo
        enddo
c
c  Accumulate the rms passband gain.
c
        do p=1,npol
          do j=1,nchan
            do i=1,nants
              temp = real(pass(i,j,p))**2 + aimag(pass(i,j,p))**2
              if(temp.gt.0)then
                npass(i,p) = npass(i,p) + 1
                rmspass(i,p) = rmspass(i,p) + temp
              endif
            enddo
          enddo
        enddo
c
c  Calculate the average delay and rms passband gain.
c
        do i=1,nants
          sumtau(i) = sumtau(i) / nsoln
          do p=1,npol
            if(npass(i,p).gt.0)then
              rmspass(i,p) = sqrt(rmspass(i,p)/npass(i,p))
            else
              rmspass(i,p) = 1
            endif
          enddo
        enddo
c
c  Correct the delay and antenna gains.
c
        do j=1,nsoln
          do i=1,nants
            tau(i,j) = tau(i,j) - sumtau(i)
          enddo
        enddo
c
        do p=1,npol
          do j=1,nsoln
            do i=1,nants
              gains(i,p,j) = gains(i,p,j) * rmspass(i,p)
            enddo
          enddo
        enddo
c
c  Correct the passband gains.
c
        do p=1,npol
          do j=1,nchan
            do i=1,nants
              theta = 2*pi * sumtau(i) * freq(j)
              pass(i,j,p) = pass(i,j,p) * cmplx(cos(theta),sin(theta))
     *                                                  / rmspass(i,p)
            enddo
          enddo
        enddo
c
        end
c************************************************************************
        subroutine gaincpy(npol,nants,nchan,nsoln,pass,gains,
     *          tau,opass,ogains,otau)
c
        integer npol,nants,nchan,nsoln
        complex pass(nants,nchan,npol),gains(nants,npol,nsoln)
        complex opass(nants,nchan,npol),ogains(nants,npol,nsoln)
        real tau(nants,nsoln),otau(nants,nsoln)
c
c  Copy the current gains to the old gains.
c------------------------------------------------------------------------
        integer i,j,p
c
        do p=1,npol
          do j=1,nchan
            do i=1,nants
              opass(i,j,p) = pass(i,j,p)
            enddo
          enddo
        enddo
c
        do p=1,npol
          do j=1,nsoln
            do i=1,nants
              ogains(i,p,j) = gains(i,p,j)
            enddo
          enddo
        enddo
c
        do j=1,nsoln
          do i=1,nants
            otau(i,j) = tau(i,j)
          enddo
        enddo
c
        end
c************************************************************************
        subroutine gaincmp(npol,nants,nchan,nsoln,pass,gains,
     *          tau,opass,ogains,otau,epsi)
c
        integer npol,nants,nchan,nsoln
        complex pass(nants,nchan,npol),gains(nants,npol,nsoln)
        complex opass(nants,nchan,npol),ogains(nants,npol,nsoln)
        real tau(nants,nsoln),otau(nants,nsoln),epsi
c
c  Copy and compare the current and old gains.
c------------------------------------------------------------------------
        integer i,j,p
        real change,sum2,rtemp
        complex temp
c
        epsi = 0
c
        change = 0
        sum2 = 0
        do p=1,npol
          do j=1,nchan
            do i=1,nants
              temp = pass(i,j,p) - opass(i,j,p)
              opass(i,j,p) = pass(i,j,p)
              change = change + real(temp)**2 + aimag(temp)**2
              sum2 = sum2 + real( pass(i,j,p))**2
     *                    + aimag(pass(i,j,p))**2
            enddo
          enddo
        enddo
        if(sum2.gt.0)epsi = max(epsi, change / sum2)
c
        change = 0
        sum2 = 0
        do p=1,npol
          do j=1,nsoln
            do i=1,nants
              temp = gains(i,p,j) - ogains(i,p,j)
              ogains(i,p,j) = gains(i,p,j)
              change = change + real(temp)**2 + aimag(temp)**2
              sum2 = sum2 + real( gains(i,p,j))**2
     *                    + aimag(gains(i,p,j))**2
            enddo
          enddo
        enddo
        if(sum2.gt.0)epsi = max(epsi, change / sum2)
c
        change = 0
        sum2 = 0
        do j=1,nsoln
          do i=1,nants
            rtemp = tau(i,j) - otau(i,j)
            otau(i,j) = tau(i,j)
            change = change + rtemp*rtemp
            sum2 = sum2 + tau(i,j)*tau(i,j)
          enddo
        enddo
        if(sum2.gt.0)epsi = max(epsi, change / sum2)
c
        epsi = sqrt(epsi)
c
        end
c************************************************************************
        subroutine srcgen(source,oldflux,defflux,sflux,nchan,freq,
     *                                          freq0,flux,alpha)
c
        integer nchan
        real flux,alpha,sflux(nchan)
        double precision freq(nchan),freq0
        logical defflux,oldflux
        character source*(*)
c
c  Generate the source flux as a function of frequency.
c
c  Input:
c    Source	Source name.
c    nchan	Number of spectral channels.
c    freq	Offset frequency of each channel.
c    freq0	Reference frequency.
c    flux	Source flux at the reference frequency.
c    alpha	Spectral index.
c    oldflux	True if we are to use the old ATCA 1934 flux scales.
c  Input/Output:
c    defflux	Check for a known source, and use this if possible.
c  Output:
c    source	Flux of the source at each frequency.
c------------------------------------------------------------------------
        integer i,ierr
        character umsg*64,src*16
c
        ierr = 2
        src = source
        if(src.eq.'1934-638'.or.src.eq.'1934'.or.
     *                  src.eq.'1939-637')then
          if(oldflux)then
            src = 'old1934'
            call output('Using pre-Aug94 ATCA flux scale for 1934-638')
          else
            call bug('w',
     *                  'Using post-Aug94 ATCA flux scale for 1934-638')
          endif
        endif
        if(defflux)call calstoke(src,'i',freq,sflux,nchan,ierr)
        if(ierr.eq.2)then
          if(alpha.eq.0)then
            do i=1,nchan
              sflux(i) = flux
            enddo
          else
            do i=1,nchan
              sflux(i) = flux * (freq(i)/freq0) ** alpha
            enddo
          endif
        else if(ierr.eq.1)then
          defflux = .false.
          umsg = 'Extrapolating to get frequency variation of '//source
          call bug('w',umsg)
        else
          defflux = .false.
          umsg = 'Using known frequency variation of '//source
          call output(umsg)
        endif
c
        end
c************************************************************************
        subroutine averfreq(nspect,nschan,sfreq,sdf,freq0)
c
        integer nspect,nschan(nspect)
        double precision sfreq(nspect),sdf(nspect),freq0
c
c  Determine the average frequency of the data.
c------------------------------------------------------------------------
        integer i,nchan
c
        nchan = 0
        freq0 = 0
        do i=1,nspect
          nchan = nchan + nschan(i)
          freq0 = freq0 + nschan(i)*(sfreq(i)+0.5*(nschan(i)-1)*sdf(i))
        enddo
c
        freq0 = freq0 / nchan
        end
c************************************************************************
        subroutine freqrel(freq,freq0,nchan)
c
        integer nchan
        double precision freq(nchan),freq0
c
c  Subtract off the reference frequency.
c------------------------------------------------------------------------
        integer i
c
        do i=1,nchan
          freq(i) = freq(i) - freq0
        enddo
        end
c************************************************************************
        subroutine freqgen(nspect,nschan,sfreq,sdf,freqc,freq,nchan)
c
        integer nchan,nspect,nschan(nspect)
        double precision sfreq(nspect),sdf(nspect),freq(nchan)
        double precision freqc(nspect)
c
c  Generate the frequency corresponding to each channel.
c
c  Input:
c    sfreq
c    sdf
c    nschan
c  Output:
c    freqc	The average offset frequency of each window.
c    freq	The offset frequency corresponding to each channel.
c------------------------------------------------------------------------
        integer i,j,off
c
        off = 0
        do j=1,nspect
          freqc(j) = sfreq(j) + 0.5*sdf(j)*(nschan(j)-1)
          do i=1,nschan(j)
            off = off + 1
            freq(off) = sfreq(j) + sdf(j) * (i-1)
          enddo
        enddo
c
        end
c************************************************************************
        subroutine chancvt(nspect,nschan,nchan,ischan)
c
        integer nspect,nschan(nspect),nchan,ischan(nspect)
c
c  Determine the ischan array.
c
c  Input:
c    nspect
c    nschan
c    nvis
c  Output:
c    nchan
c    ischan
c------------------------------------------------------------------------
        integer i
c
        nchan = 0
        do i=1,nspect
          ischan(i) = nchan
          nchan = nchan + nschan(i)
        enddo
c
        end
c************************************************************************
        subroutine wgini(vis,wt,vid,ischan,nvis,npol,count,nsoln,nchan,
     *    nants,nspect,source,wgains,refant,minant)
c
        integer nvis,nsoln,nants,nspect,nchan,minant,refant,npol
        complex vis(nvis),wgains(nants,nspect,npol,nsoln)
        integer vid(nvis),count(nsoln),ischan(nspect)
        real source(nchan),wt(nvis)
c
c  Estimate the "wide" gains. The gains in each spectral window are
c  solved for independently.
c
c  Input:
c    Vis
c    Wt
c    VID
c    nvis
c    Count
c    nsoln
c    nants
c    nspect
c    nchan
c    Source
c    ischan
c  Output:
c    WGains
c------------------------------------------------------------------------
        integer maxpol
        parameter(maxpol=2)
        include 'maxdim.h'
c
        integer i,j,k,i1,i2,bl,spect,chan,off,nbl,p
        complex sumvm(maxbase,maxwin,maxpol)
        real summm(maxbase,maxwin,maxpol),epsi
        external unpack
c
        nbl = nants*(nants-1)/2
c
        off = 0
        do k=1,nsoln
          do p=1,npol
            do j=1,nspect
              do i=1,nbl
                sumvm(i,j,p) = 0
                summm(i,j,p) = 0
              enddo
            enddo
          enddo
c
c  Accumulate the data for this solution interval.
c
          do i=1,count(k)
            off = off + 1
            call unpack(i1,i2,p,spect,chan,vid(off))
            chan = chan + ischan(spect)
            bl = (i2-1)*(i2-2)/2 + i1
            sumvm(bl,spect,p) = sumvm(bl,spect,p) +
     *                  vis(off)*source(chan)
            summm(bl,spect,p) = summm(bl,spect,p) +
     *                  wt(off)*source(chan)**2
          enddo
c
c  Solve for the gains for this interval.
c
          do p=1,npol
            do i=1,nspect
              call solve(nants,nbl,sumvm(1,i,p),summm(1,i,p),
     *          wgains(1,i,p,k),refant,minant,1e-4,epsi,.true.)
            enddo
          enddo
        enddo
c
        end

        subroutine rmsweight(tno,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge,tsys1,tsys2,sdf)
         integer tno,maxspect,nspect,nchan,maxchan,weight
         integer nschan(maxspect),i,j,edge(2)
         double precision sdf(maxspect)
         real tsys1(maxspect),tsys2(maxspect)
         real chnwt(maxchan), wwt
c
c initialize
          do i=1,nchan
          chnwt(i) = 1.0
          enddo

c
c   determine channel dependent weight =1/sigma**2
c   multiple the channel width
c

         if(weight.ge.0.and.weight.lt.3) then
c   read the first variance of first channel
                 if(weight.le.2) call uvdatgtr('variance',wwt)
                    if(wwt.le.0) then
                    wwt = 0.0
                    else
                    wwt = 1./wwt
                    endif
         endif

               if(weight.ge.3) then
               wwt=1.
               endif
c
c   correct for band dependent factor using Tsys and BW of each band 
c
            ichan=0
            do j=1, nspect
            do i=1, edge(1)+nschan(j)+edge(2)
            ichan=ichan+1
            if(nschan(j).gt.0) then
            if(abs(sdf(1)).ne.0.d0) then
            chnwt(ichan) = wwt*abs(sdf(j)/sdf(1))
            else
            chnwt(ichan) = wwt
            end if
            if(tsys1(j).ne.0.0) then
            chnwt(ichan) = chnwt(ichan)*tsys1(1)/tsys1(j)
            else
            chnwt(ichan) = chnwt(ichan)
            end if
            if(tsys2(j).ne.0.0) then
            chnwt(ichan) = chnwt(ichan)*tsys1(1)/tsys2(j)
            else
            chnwt(ichan) = chnwt(ichan)
            end if
            else
            chnwt(ichan) =0
            endif
c
c  for uniform weight
c
            if(weight.ge.3.or.weight.lt.0) then
            wwt=1.
            endif
            enddo
            enddo
            end

c************************************************************************
        subroutine datread(tno,maxvis,nvis,npol,vis,wt,vid,
     *          maxspect,nspect,sfreq,sdf,nschan,nants,
     *          maxsoln,nsoln,time,count,minant,refant,interval,
     *          edge,source,polmap,dopass,dosmooth,
     *          donply,dowrap,weight,defaultwt)
c
        integer tno,maxvis,nvis,maxspect,nspect,nants,maxsoln,nsoln
        integer minant,refant,npol
        double precision time(maxsoln),interval(2)
        double precision sfreq(maxspect),sdf(maxspect)
        integer nschan(maxspect),count(maxsoln),edge(2)
        complex vis(maxvis)
        real wt(maxvis)
        integer vid(maxvis),polmap(*)
        character source*(*)
        logical defaultwt
c
c  Read the data, and return information on what we have read.
c
c  Input:
c    tno
c    maxvis
c    maxspect
c    maxsoln
c    minant
c    refant
c    interval
c    edge
c    weight     weighting method
c    defaultwt  if ture, using the default method
c  Output:
c    nvis
c    nspect
c    nants
c    nsoln
c    Source	The source name.
c    npol	Number of polarisations.
c    PolMap	Map between internal polarisation number and external
c		polarisation. Must be of dimension at least MAXPOL.
c    time
c    sfreq
c    sdf
c    nschan
c    VID
c    Wt
c    Vis
c    Count
c------------------------------------------------------------------------
        integer polxx,polyy,polrr,polll,poli
        parameter(polxx=-5,polyy=-6,polrr=-1,polll=-2,poli=1)
        integer polmin,polmax
        parameter(polmin=-6,polmax=1)
        include 'maxdim.h'
        integer maxhash,maxpol
        parameter(maxhash=2*maxant*maxchan,maxpol=2)
c
        integer nchan,nbad,nauto,nreg,ngood,ninter,i1,i2,p,i,visid
        double precision preamble(4),tfirst,tlast
        complex data(maxchan), ndata(maxchan)
        logical flags(maxchan),present(maxant,maxpol),updated,ok
        logical dopass,dosmooth,donply,dowrap
        integer chan(maxchan),spect(maxchan),state(maxchan)
        integer hash(2,maxhash),vupd
        integer pols(polmin:polmax)
        integer weight 
        real tsys(maxspect*maxant),tsys1(maxspect),tsys2(maxspect)
        character telescop*10, type*1, msg*80
        integer length, sb(maxspect)
        logical hsrmode
c
c  Externals.
c
        logical uvvarupd, accept
        character itoaf*8
        external pack
c
c  wwt: 1/sigma**2
c  chzwt: weight of channel zero
c  chz:   vis data of channel zero
        real wwt,chzwt(maxwin,maxpol), chnwt(maxchan)
        complex chz(maxwin,maxpol)
        integer bchan, echan, numpol
c
c  initialization
c
           hsrmode=.false.
           do i=1, maxchan
           chnwt(i) =1.
           end do
           do i=1, maxspect
           nschan(i) = 0
           sfreq(i) = 0.0d0
           sdf(i) = 0.0d0
           end do
        if(weight.eq.-1) 
     *  call output('Using the same weighting as used in MFCAL...')
        if(dosmooth) call output('Smoothing the spectral data ...') 
c
c  Is the size of the "state" array OK?
c
        if(3*(maxspect+2).gt.maxchan)
     *    call bug('f','State array too small in DatRead')
c
c  Initialise thing.
c
        call uvvarini(tno,vupd)
        call uvvarset(vupd,'nspect')
        call uvvarset(vupd,'sfreq')
        call uvvarset(vupd,'sdf')
        call uvvarset(vupd,'nschan')
        call uvvarset(vupd,'systemp')
        call uvvarset(vupd,'wfreq')
        call uvvarset(vupd,'wwidth')
        call uvselect(tno,'and',0.d0,0.d0,.true.)
        call uvselect(tno,'polarization',dble(polxx),0.d0,.true.)
        call uvselect(tno,'polarization',dble(polyy),0.d0,.true.)
        call uvselect(tno,'polarization',dble(polrr),0.d0,.true.)
        call uvselect(tno,'polarization',dble(polll),0.d0,.true.)
        call uvselect(tno,'polarization',dble(poli),0.d0,.true.)
c
        wwt=1.
        do p=polmin,polmax
          pols(p) = 0
        enddo
        npol = 0
c
        nsoln = 0
        nspect = 0
        nvis = 0
        ninter=0
c
        updated = .false.
        tfirst = 0
        tlast = 0
        nbad = 0
        nauto = 0
        nreg = 0
        ngood = 0
c initialized pol-feed and antenna matrix 
        do p=1,maxpol
          do i=1,maxant
            present(i,p) = .false.
          enddo
        enddo
c
c  Loop over everything.
c
        call uvdatrd(preamble,data,flags,maxchan,nchan)
c
c get telescope name
c
       call uvprobvr (tno, 'telescop',type, length, ok)
       call uvrdvra(tno,'telescop',telescop,' ')
c
c reset default weight for non-SMA telescope
c for SMA
c default weight = 2 for bandpass
c         weight = 1 for gain
c for Other telescope
c default weight = -1 back to MFCAL
c
        if(defaultwt.and.(telescop.ne.'SMA')) then
        weight=-1
        end if
        
        if(defaultwt.and.(.not.dopass)) weight=1
        
       updated =.true.
       call despect(updated,tno,nchan,edge,chan,spect,
     * maxspect,nspect,sfreq,sdf,nschan,state)
c if SMA data check up if this is a hybrid spectral resolution data set
             if(telescop.eq.'SMA') then
             do i=1, nspect-1
             if(nschan(i).ne.nschan(i+1)) hsrmode=.true.
             end do
             
             if(hsrmode) then
             call bug('w', 'hybrid spectral resolution detected:')
             do i=1, nspect
             write(msg,9876) i, nschan(i)
             call output('s'//msg)
             end do
          call output(' ')
          call bug('w',
     *    'Read Users Guide for handling hybrid spectral resolution')
          msg(1:49)='http://sma-www.cfa.harvard.edu/miriadWWW/manuals/'
          call output(msg(1:49)//'SMAuguide/smauserhtml/index.html')
          call output(' ')
             end if
             end if
9876    format(i2,' =',i5)


       call uvrdvra(tno,'source',source,' ')
       call uvrdvri(tno,'nants',nants,0)
        if(nants.le.0.or.nants.gt.maxant)
     *    call bug('f','Bad value for nants, in DatRead')

c
c get system
c
            call uvprobvr(tno,'systemp',type,length,ok)
            call uvgetvrr(tno,'systemp',tsys,length)
            call basant(preamble(4),i1,i2)
            do i=1, nspect
             if (telescop.eq.'SMA') then
             tsys1(i) =tsys(i1)
             tsys2(i) =tsys(i2)
              else
             tsys1(i) =tsys(i1+(i-1)*nants)
             tsys2(i) =tsys(i2+(i-1)*nants)
             end if
c determine sb: positive -> usb; negative -> lsb
            sb(i) = int(sdf(i)/abs(sdf(i)))
            end do

c
c jhz: derive wt from vis variance
c
        call rmsweight(tno,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge,tsys1,tsys2,sdf)
         if(dopass) then
c
c  calculate pseudo continuum channels
c         
          if(weight.ge.1) then
          numpol = 1
          bchan  = 0
          echan  = 0
          call avgchn(numpol,bchan,echan,data,flags,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,sb,
     *    telescop)
c
c  divide the spectral channel by the pseudo continuum
c
          call divchz(numpol,data,ndata,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,edge)
c
c  smooth the data
c
          if(dosmooth) call smoothply(preamble,ndata,
     *    flags,nchan,nspect,maxspect,
     *    nschan,maxchan,dosmooth,donply,dowrap,wwt,edge)
          endif
          endif
          if(weight.eq.-1) then
          if(dosmooth) call smoothply(preamble,data,
     *    flags,nchan,nspect,maxspect,
     *    nschan,maxchan,dosmooth,donply,dowrap,wwt,edge)
          end if

        dowhile(nchan.gt.0)
          updated = updated.or.uvvarupd(vupd)
          call uvdatgti('pol',p)
          ok = i1.gt.0.and.i1.le.maxant.and.
     *         i2.gt.0.and.i2.le.maxant.and.
     *         p.ge.polmin.and.p.le.polmax
c
c  p-> pol-state, in the range of polmin=-6 and polmax=1
c
c
c  Finish up an old solution interval, and initialise a new slot.
c
          if(ok)then
            if( nsoln.eq.0.or.
     *          preamble(3).gt.tfirst+interval(1).or.
     *          preamble(3).gt.tlast+interval(2))then
              if(nsoln.ne.0)then
                time(nsoln) = (tfirst+tlast)/2
                if(.not.accept(present,nants,npol,refant,minant,maxant)
     *          )then
                  nvis = nvis - count(nsoln)
                  nreg = nreg + ninter
                  nsoln = nsoln - 1
                else
                  ngood = ngood + ninter
                endif
              endif
              nsoln = nsoln + 1
              if(nsoln.gt.maxsoln)
     *          call bug('f','Too many solution intervals')
              tfirst = preamble(3)
              tlast  = tfirst
              ninter = 0
              count(nsoln) = 0
              call accumini(hash,maxhash)
            else if(preamble(3).lt.tfirst)then
              call bug('f','Data does not appear to be in time order')
            endif
c
c  Determine the polarisation number.
c
            if(pols(p).eq.0)then
              npol = npol + 1
              if(npol.gt.maxpol)
     *          call bug('f','Too many different polarisations')
                pols(p) = npol
           polmap(npol) = p
            endif
                p = pols(p)
c
            if(nchan+nvis.gt.maxvis)
     *      call bug('f','Buffer overflow: set interval larger')
c
            tlast = max(tlast,preamble(3))
            call despect(updated,tno,nchan,edge,chan,spect,
     *      maxspect,nspect,sfreq,sdf,nschan,state)

c edge: number of channels in each edge to be flagged
c nchan: total number spectral channels
c nschan: number of channel in each of the spectral chunk
c nspect: number of spectral windows
c chan(i): new channel id corresponds to the original channel
c          id after edge flagged 
c spect(i): chunk id 
                 
                
           do i=1,nchan
              if(flags(i).and.chan(i).gt.0)then
                present(i1,p) = .true.
                present(i2,p) = .true.
                call pack(i1,i2,p,spect(i),chan(i),visid)

c
c assign visid based on i1,i2,p, spect chan
c
             ninter = ninter + 1
          if(dopass.and.(weight.ge.1)) 
     *       call accumwt(hash,ndata(i),visid,
     *       nsoln,nvis,vis,wt,vid,count,chnwt(i))

          if(dopass.and.(weight.eq.-1))  
     *       call accum(hash,data(i),visid,
     *       nsoln,nvis,vis,wt,vid,count)

          if(.not.dopass) then
          if(weight.ne.-1)
     *       call accumwt(hash,data(i),visid,
     *       nsoln,nvis,vis,wt,vid,count,chnwt(i))
          if(weight.eq.-1) 
     *       call accum(hash,data(i),visid,
     *       nsoln,nvis,vis,wt,vid,count)            
           end if

          else
             nbad = nbad + 1
          endif
          enddo
c
          else
            nauto = nauto + 1
          endif
          call uvdatrd(preamble,data,flags,maxchan,nchan)

c
c get system
c
            call uvprobvr(tno,'systemp',type,length,ok)
            call uvgetvrr(tno,'systemp',tsys,length)
            call basant(preamble(4),i1,i2)
            do i=1, nspect
            if (telescop.eq.'SMA') then
            tsys1(i) =tsys(i1)
            tsys2(i) =tsys(i2)
            else
            tsys1(i) =tsys(i1+(i-1)*nants)
            tsys2(i) =tsys(i2+(i-1)*nants)
            end if
            sb(i) = int(sdf(i)/abs(sdf(i)))
            end do
c
c jhz: derive wt the current Tsys measurement and BW and integration time
c
       call rmsweight(tno,chnwt,nchan,nspect,nschan,maxspect,
     *    maxchan,weight,edge,tsys1,tsys2,sdf)

          if(dopass) then
c
c  calculate pseudo continuum 
c
          if(weight.ge.1) then 
          numpol = 1
          bchan  = 0
          echan  = 0
          call avgchn(numpol,bchan,echan,data,flags,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,sb,
     *    telescop)

c
c  divide the spectral channel by the pseudo continuum
c
          call divchz(numpol,data,ndata,nchan,
     *    nspect,nschan,maxchan,chnwt,chz,chzwt,weight,
     *    edge)
c
c  smooth the data
c
          if(dosmooth) call smoothply(preamble,ndata,
     *    flags,nchan,nspect,maxspect,
     *    nschan,maxchan,dosmooth,donply,dowrap,wwt,edge)
          end if
          end if   
          if(weight.eq.-1) then
          if(dosmooth) then 
          call smoothply(preamble,data,
     *    flags,nchan,nspect,maxspect,
     *    nschan,maxchan,dosmooth,donply,dowrap,wwt,edge)
          end if
          end if
        enddo

c
c  Check if the last time interval is to be accepted.
c
       if(nsoln.ne.0)then
         time(nsoln) = (tfirst+tlast)/2
       if(.not.accept(present,nants,npol,refant,minant,maxant))then
         nvis = nvis - count(nsoln)
         nreg = nreg + ninter
         nsoln = nsoln - 1
       else
            ngood = ngood + ninter
       endif
       endif

c
c  Tell the user whats what
c
        call output('Number of solution intervals: '
     *    //itoaf(nsoln))
        if(nauto.ne.0)
     *    call bug('w','Number of autocorrelations discarded: '
     *    //itoaf(nauto))
        if(nbad.ne.0)
     *    call bug('w','Correlations flagged or edge-rejected: '
     *    //itoaf(nbad))
        if(nreg.ne.0)
     *    call bug('w','Number correlations lacking minant/refant: '
     *    //itoaf(nreg))
        call output('Number correlations accepted: '
     *    //itoaf(ngood))
        call output('Number of frequency bands/settings: '
     *    //itoaf(nspect))
        call output('Number of polarisations selected: '
     *    //itoaf(npol))
        if(nsoln.eq.0.or.nvis.eq.0)
     *    call bug('f','No data to process!')

        end
c************************************************************************
                subroutine avevar(data,n,ave,var)
      INTEGER n
      REAL ave,var,data(n)
      INTEGER j
      REAL s,ep
      ave=0.0
      do 11 j=1,n
        ave=ave+data(j)
11    continue
      ave=ave/n
      var=0.0
      ep=0.0
      do 12 j=1,n
        s=data(j)-ave
        ep=ep+s
        var=var+s*s
12    continue
      var=(var-ep**2/n)/(n-1)
      return
      END


        subroutine pack(i1,i2,p,spect,chan,vid)
c
        integer i1,i2,p,spect,chan,vid
c
c  Pack antenna and polarisation numbers into one number.
c
c  Input:
c    i1
c    i2
c    p
c    spect
c    chan
c  Output:
c    VID
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxpol
        parameter(maxpol=2)
        vid = chan - 1
        vid = maxant * vid + i1 - 1
        vid = maxant  *vid + i2 - 1
        vid = maxpol  *vid + p  - 1
        vid = maxwin  *vid + spect - 1
        end
c************************************************************************
        subroutine unpack(i1,i2,p,spect,chan,vid)
c
        integer i1,i2,p,spect,chan,vid
c
c  Unpack antenna and polarisation number.
c
c  Input:
c    VID
c  Output:
c    i1
c    i2
c    p
c    spect
c    chan
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxpol
        parameter(maxpol=2)
        integer visid
c
        visid = vid
        spect = mod(visid,maxwin)
        visid = visid/maxwin
        p     = mod(visid,maxpol)
        visid = visid/maxpol
        i2    = mod(visid,maxant)
        visid = visid/maxant
        i1    = mod(visid,maxant)
        chan  = visid/maxant
c
        i1 = i1 + 1
        i2 = i2 + 1
        p = p + 1
        spect = spect + 1
        chan = chan + 1
c
        end
c************************************************************************
        subroutine accumini(hash,maxhash)

        integer maxhash,hash(2,maxhash)
c
c  Initialise the hash table.
c
c------------------------------------------------------------------------
        integer i
c
c  Externals.
c
        integer prime
c
        do i=1,maxhash
          hash(1,i) = 0
        enddo
c
        hash(1,1) = prime(maxhash-2)
        end
c************************************************************************
        subroutine accumwt(hash,data,visid,nsoln,nvis,vis,wt,
     *                  vid,count, wwt)
c
        integer visid,nsoln,nvis,vid(*),count(*)
        real wt(*), wwt
        integer hash(2,*)
        complex data,vis(*)
c
c  add a weight while accumulate vis 
c
c  Inputs:
c    VisId	Identifier, giving channel, IF band, antennae and polarisation.
c------------------------------------------------------------------------
        integer nhash,ihash,indx,i
c
c  Find this channel in the hash table.
c
        nhash = hash(1,1)
        ihash = visid + 1
        indx = mod(ihash,nhash) + 2
        dowhile(hash(1,indx).ne.0.and.hash(1,indx).ne.ihash)
          indx = indx + 1
        enddo
        if(indx.ge.nhash+2)then
          indx = 2
          dowhile(hash(1,indx).ne.0.and.hash(1,indx).ne.ihash)
            indx = indx + 1
          enddo
          if(indx.ge.nhash+2)
     *          call bug('f','Hash table overflow, in Accum')
        endif
c
c  Is it a new slot?
c
        if(hash(1,indx).eq.0)then
          nvis = nvis + 1
          hash(1,indx) = ihash
          hash(2,indx) = nvis
          i = nvis
c
c wwt=1/sigma**2
c
          wt(i) = wwt
          vis(i) = wwt*data
          vid(i) = visid
          count(nsoln) = count(nsoln) + 1
          else
          i = hash(2,indx)
                wt(i) = wt(i) + wwt
               vis(i) = vis(i)+wwt*data
        endif
c
        end
c************************************************************************
        subroutine avgchn(numpol,bchan,echan,data,flags,nchan,
     *  bpnspect,bpnschan,maxchan,chnwt,chz,chzwt,weight,sb,telescop)
        PARAMETER(maxwin=49, maxpol=2)
        integer nchan,bpnspect,maxchan,bpnschan(maxwin),sb(maxwin)
        integer i,j,numpol,bchan,echan, ipol
        integer bschan, eschan 
        complex data(maxchan)
        logical flags(maxchan), nsflag(maxchan)
        real ysr(maxchan), ysi(maxchan)
        character telescop*10
c
c  calculate pseudo continuum vector
c
c  wwt: 1/sigma**2
c  chzwt: weight of channel zero
c  chz:   vis data of channel zero
        real chnwt(maxchan),chzwt(maxwin,maxpol)
        complex chz(maxwin,maxpol)
        real SUMWT, SUMRE, SUMIM, XNORM
        integer  weight
            SUMWT = 0.0
            SUMRE = 0.0
            SUMIM = 0.0
            ipol=1
         ntcount=0
c assuming numpol =1
           if(telescop.eq.'SMA') then
c
c
c for SMA, take all chunk data (in one side band) to derive pseudo-continuum
c
         do j=1, bpnspect
             bschan=bchan
           if (bchan.eq.0) bschan = bpnschan(j)*0.125
             eschan=echan
           if (echan.eq.0) eschan = bpnschan(j)*0.875
            SUMWT = 0.0
            SUMRE = 0.0
            SUMIM = 0.0
          do i=1, bpnschan(j)
              ntcount=ntcount+1
              ysr(i) = real(data(ntcount))
              ysi(i) = aimag(data(ntcount))
              nsflag(i) = flags(ntcount)
              if(i.ge.bschan.and.i.le.eschan) then
              if(nsflag(i).and.chnwt(ntcount).gt.0.0) then
                  SUMRE = SUMRE + ysr(i)*chnwt(ntcount)
                  SUMIM = SUMIM + ysi(i)*chnwt(ntcount)
                  SUMWT = SUMWT + chnwt(ntcount)
                 endif
              endif
           enddo
            XNORM = 1.0
         if(SUMWT.gt.1.0e-20) XNORM = 1.0 / SUMWT
         if(XNORM.eq.1.) then 
            SUMWT =0.0
            SUMRE =1.0
            SUMIM =0.0
           endif         
         chzwt(j,ipol) = SUMWT
         chz(j,ipol) = cmplx(SUMRE*XNORM, SUMIM*XNORM) 
         enddo
         else
c
c for a non-SMA telescope, only take the 1st band to derive pseudo-continuum
c

         bschan=bchan
           j=1
           if (bchan.eq.0) bschan = bpnschan(j)*0.125
             eschan=echan
           if (echan.eq.0) eschan = bpnschan(j)*0.875
            SUMWT = 0.0
            SUMRE = 0.0
            SUMIM = 0.0
          do i=1, bpnschan(j)
              ntcount=ntcount+1
              ysr(i) = real(data(ntcount))
              ysi(i) = aimag(data(ntcount))
              nsflag(i) = flags(ntcount)
              if(i.ge.bschan.and.i.le.eschan) then
              if(nsflag(i).and.chnwt(ntcount).gt.0.0) then
                  SUMRE = SUMRE + ysr(i)*chnwt(ntcount)
                  SUMIM = SUMIM + ysi(i)*chnwt(ntcount)
                  SUMWT = SUMWT + chnwt(ntcount)
                 endif 
              endif
           enddo
            XNORM = 1.0
         if(SUMWT.gt.1.0e-20) XNORM = 1.0 / SUMWT
         if(XNORM.eq.1.) then
            SUMWT =0.0
            SUMRE =1.0
            SUMIM =0.0
           endif
          do j=1, bpnspect
          chzwt(j,ipol) = SUMWT
          chz(j,ipol) = cmplx(SUMRE*XNORM, SUMIM*XNORM)
          enddo
          endif

         if(weight.ge.1) then
c initialize
          cntnumreal = 0.0
          cntnumimag = 0.0
          cntnumwt   = 0.0
       do j =1, bpnspect
       cntnumreal=cntnumreal+real(chz(j,ipol))*chzwt(j,ipol)
       cntnumimag=cntnumimag+aimag(chz(j,ipol))*chzwt(j,ipol)
       cntnumwt  =cntnumwt + chzwt(j,ipol)
       enddo
       cntnumnorm = 1.0
      if(cntnumwt.ge.1.0e-20) cntnumnorm = 1.0/cntnumwt
      if(cntnumnorm.eq.1.0) then 
        contnumwt = 0.
        cntnumreal = 1.0
        cntnumimag = 0.
        endif
       do j =1, bpnspect
         chzwt(j,ipol) = cntnumwt
         chz(j,ipol) =  
     * cmplx(cntnumreal*cntnumnorm,cntnumimag*cntnumnorm)
       enddo
             endif
         end

c************************************************************************
        subroutine divchz(numpol,data,ndata,nchan,
     *  bpnspect,bpnschan,maxchan,chnwt,chz,chzwt,weight,
     *  edge)
        PARAMETER(maxwin=49, maxpol=2)
        PARAMETER(pi=3.14159265358979323846)
        integer nchan,bpnspect,maxchan,bpnschan(maxwin)
        integer i,j,numpol,ipol
        integer edge(2)
        complex data(maxchan),ndata(maxchan)
        real chnwt(maxchan), chwt
        real vr,vi,chzr,chzi
c
c  normalize the channel data by dividing the pseudo continuum vector
c  calculate the correspoding weight for the channel data.
c
c  wwt: 1/sigma**2
c  chzwt: weight of channel zero
c  chz:   vis data of channel zero
        real chzwt(maxwin,maxpol)
        complex chz(maxwin,maxpol)
        real DENOM,AMPD,ar,ai
        integer weight
c initialization
         ntcount=0
c assuming numpol =1
         ipol=1
         DENOM=0.0
         do j=1, bpnspect
          chzr=real(chz(j,ipol))
          chzi=aimag(chz(j,ipol))
         if(chzwt(j,ipol).gt.0.0) DENOM=chzr**2+chzi**2
c
c reject data around nulls in planets
c
       if(DENOM.le.1.0e-20.or.chzwt(j,ipol).le.1.0e-20) then
              do i=1, edge(1)+bpnschan(j)+edge(2)
              ntcount=ntcount+1
              data(ntcount) = cmplx(0.0,0.0)
              chnwt(ntcount) = 0.0
              end do
            else
              do i=1, edge(1)+bpnschan(j)+edge(2)
               ntcount=ntcount+1
               vr = real(data(ntcount))
               vi = aimag(data(ntcount))
           AMPD = vr**2 + vi**2
           chwt=chnwt(ntcount)
           chnwt(ntcount)=DENOM*DENOM*chwt*chzwt(j,ipol)
     *   / (DENOM*chzwt(j,ipol)+AMPD*chwt)
              ar = (chzr*vr+chzi*vi)  / DENOM 
              ai = (chzr*vi-chzi*vr) / DENOM
           ndata(ntcount) = cmplx(ar,ai)
          if(weight.ge.2) chnwt(ntcount)=chnwt(ntcount)**2             
          enddo
            endif
         enddo
         end
c************************************************************************
        subroutine smoothply(preamble,data,flags,nchan,bpnspect,
     *  maxspect,bpnschan,maxchan,dosmooth,donply,dowrap,wwt,edge)
c
c        PARAMETER(maxwin=48)
c        integer nchan,bpnspect,maxchan,bpnschan(maxwin),nschan(maxwin)
        integer nchan,bpnspect,maxchan
        integer bpnschan(maxspect),nschan(maxspect)
        integer i,j,ntcount,nvisout
        PARAMETER(MAXNR=20, pi=3.14159265358979323846)
        complex data(maxchan),smoothdat(maxchan)
        logical flags(maxchan)
        logical dosmooth,donply,dowrap,dev
        double precision ETA(12200),CONETA(12200),A(21,MAXNR)
        double precision ATA1(MAXNR,MAXNR),ATA1AT(MAXNR,21)
        double precision SCRAT(MAXNR,MAXNR)
        double precision YR(maxchan), YI(maxchan)
        real rYR(maxchan), rYI(maxchan) 
        real ysr(maxchan), ysi(maxchan)
        double precision xchan(maxchan)
        double precision preamble(4)
        integer K, L, nply
        real xply(maxchan)
        double precision P
        real smooth(3), pphase
        real wwt
        integer bnply(3)
        integer edge(2)
        common/bsmooth/smooth,bnply
        logical dohann
        integer maxco,hann
        parameter (maxco=15)
        real hc(maxco),hw(maxco)
c
c  moving smooth the spectral data
c
c initialize the moving smooth parameters
        L = 1 
        P = 0.9
        nply = 3 
        K=smooth(1)
        L=smooth(2)
        P=smooth(3)
c
        pphase=0
        nvisout=0
        ntcount=0
c shut off hanning smooth        
        dohann=.false.
        hann = K
        call hcoeffs(hann,hc)
c        
c        
          do j=1, bpnspect
          nschan(j) = bpnschan(j) +edge(1)+edge(2)
          end do
c            
          do j=1, bpnspect
          do i=1, nschan(j)
          ysr(i) = 1.
          ysi(i) = 0.
          end do
          end do
c
           do j=1, bpnspect
           do i=1, nschan(j)
            ntcount=ntcount+1
           if((i.gt.edge(1)).and.(i.le.(nschan(j)-edge(2)))) then
            xchan(i-edge(1))=i-edge(1)
            xply(i-edge(1))=i-edge(1)
c   smooth the vis vector
            if(dosmooth) then
            YR(i-edge(1)) = real(data(ntcount))
            YI(i-edge(1)) = aimag(data(ntcount))
            end if 
            end if
            end do
         if(dohann) then
c
c hanning smooth
c
         do i=1, bpnschan(j)
         rYR(i) = YR(i)
         rYI(i) = YI(i)
         end do        
         call hannsm(hann,hc,bpnschan,rYR,hw)
         call hannsm(hann,hc,bpnschan,rYI,hw)
         do i=1, bpnschan(j)
          ysr(i+edge(1)) = rYR(i)
          ysi(i+edge(1)) = rYI(i)
         end do
        else
c
c moving smooth   
c      
        CALL TIMSER(YR,bpnschan(j),K,L,P,ETA,
     *              CONETA,A,ATA1,ATA1AT,SCRAT)
         do i=1, bpnschan(j)
          ysr(i+edge(1)) = ETA(i+K)
         end do
           dev=.true.
           if(bnply(3).eq.100) call pgplt(bpnschan,xply,YR,ysr,dev)
         CALL TIMSER(YI,bpnschan(j),K,L,P,ETA,
     *              CONETA,A,ATA1,ATA1AT,SCRAT)
         do i=1, bpnschan(j)
           ysi(i+edge(1)) = ETA(i+K)
         end do
           dev=.false.
           if(bnply(3).eq.100) call pgplt(bpnschan,xply,YI,ysi,dev)
        end if
         do i=1, nschan(j)
         nvisout = nvisout+1
         if(dosmooth) smoothdat(nvisout) = 
     *          cmplx(ysr(i),ysi(i))
         end do
         end do

c
        ntcount=0
        do j=1, bpnspect
           do i=1, nschan(j)
             ntcount = ntcount+1
             data(ntcount) = smoothdat(ntcount)
           end do
        end do
        end                   
c
c************************************************************************
        subroutine pgplt (N,XPTS,YPTSD,YFIT,dev)
        integer N,i,nx,ny
        LOGICAL PGNOTO, dev
        real XPTS(N),YPTS(N),YFIT(N)
        real xmin, xmax, range(2)
        double precision YPTSD(N)
         range(2) = -1
         range(1) =  1
        nx=1
        ny=2        
        if(dev) ierr = pgbeg(0,'?',nx,ny)
          xmin = XPTS(1)
          xmax = XPTS(N)
          do i=1, N
          YPTS(i) = YPTSD(i)
          end do 
          call setpg(xmin,xmax,YPTS,N,range,.true.)
          call pgsci(7)
        IF (N.LT.1) RETURN
        IF (PGNOTO('PGPT')) RETURN
         CALL PGBBUF
         CALL GRMKER(SYMBOL,.FALSE.,N,XPTS,YPTS)
         CALL PGEBUF
         call pgsci(1)
         call pgline (N,XPTS,YFIT)
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
c    xmin,xmax  Range of the X data to be plotted.
c    y          The Y data to be plotted.
c    n          Number of points in Y.
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

c       
c************************************************************************

      subroutine regpolfitg(nterms,xa,bp,N, x1, pl2)
         PARAMETER(MAXNR=20)
         integer nterms, N, i, j, k, l
         double precision xa(MAXNR),bp(MAXNR,MAXNR)
         double precision XPL(N,MAXNR), YPL(N,MAXNR)
         real x1(N), pl2(N)
         double precision D
         PARAMETER (ZERO=0.0)
c
c  interpolate bandpass solution based on the polynomial fit
c
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

c************************************************************************
        logical function accept(present,nants,npol,refant,minant,maxant)
c
        integer nants,refant,minant,maxant,npol
        logical present(maxant,npol)
c
c  Determine whether we should accept this solution interval. In particular
c  check whether the reference antenna is present, and whether the minimum
c  number of antennae are present.
c------------------------------------------------------------------------
        integer n,i,p
        logical gotone
c
c  If some data from a particular polarisation is present, then the
c  reference antenna should also be present.
c
        accept = .false.
        do p=1,npol
          do i=1,nants
            if(present(i,p).and..not.present(refant,p))return
          enddo
        enddo
c
c  Determine how many antenna are present.
c
        n = 0
        do i=1,nants
          gotone = .false.
          do p=1,npol
            gotone = gotone.or.present(i,p)
            present(i,p) = .false.
          enddo
          if(gotone)n = n + 1
        enddo
c
c  Is the minants requirement satisfied?
c
        accept = n.ge.minant
        end
c************************************************************************
        subroutine despect(updated,tno,nchan,edge,chan,spect,
     *                  maxspect,nspect,sfreq,sdf,nschan,
     *                 state)
c
        integer tno,nchan,chan(nchan),spect(nchan),edge(2)
        integer nspect,maxspect,nschan(maxspect),state(3,maxspect+2)
        double precision sfreq(maxspect),sdf(maxspect)
        logical updated
c
c  Determine the chan/spect parameters for a particular
c  set of correlations that have just been read.
c
c  Input:
c    tno
c    nchan
c    maxspect
c    updated
c    edge	Number of channels to reject at band edges.
c  Input/Output:
c    nspect
c    sfreq
c    sdf
c    nschan
c    state
c  Output:
c    chan
c    spect
c------------------------------------------------------------------------
         include 'maxdim.h'
        integer channel,wide,mspect
        parameter(channel=1,wide=2,mspect=48)
        integer i,j,n,ispect,ltype,start,nschan0(mspect),nspect0,nwide
        integer chans,ibeg,iend,bdrop,edrop,nwidth,nstep
        double precision line(6),sfreq0(mspect),sdf0(mspect),f
        real wfreq(mspect),wwidth(mspect)
c
c  Determine what the current frequency setup is.
c
        if(updated)then
          call uvinfo(tno,'line',line)
          if(nint(line(2)).ne.nchan)
     *      call bug('f','Number of channels disagree')
          nstep  = nint(line(5))
          nwidth = nint(line(4))
          ltype = nint(line(1))
          start = nint(line(3))
          state(1,1) = 0
c
          if(ltype.eq.channel)then
            call uvrdvri(tno,'nspect',nspect0,0)
            if(nspect0.le.0.or.nspect0.gt.mspect)
     *      call bug('f','Bad value for nspect, in DESPECT')
            call uvgetvrd(tno,'sfreq',sfreq0,nspect0)
            call uvgetvrd(tno,'sdf',sdf0,nspect0)
            call uvgetvri(tno,'nschan',nschan0,nspect0)
c
c  Go through the windows that we have. Match this with any
c  previous windows of the same sort.
c
            ispect = 1
            n = nchan
            dowhile(n.gt.0)
              dowhile(start.gt.nschan0(ispect))
                start = start - nschan0(ispect)
                ispect = ispect + 1
              enddo
              chans = min(n,
     *          (nschan0(ispect) - start + 1 + nstep - 1)/nstep)
              bdrop = max(0,edge(1)-start+1 + nstep - 1)/nstep
              edrop = max(0,
     *          nstep*chans+start-1+edge(2)-nschan0(ispect)+nstep-1 )
     *          / nstep
              if(bdrop+edrop.ge.chans)
     *          call bug('f','Illegal edge parameter')
              f = sfreq0(ispect) +
     *            sdf0(ispect) * (start - 1 + 0.5*(nwidth-1))
              call setstate(state,f,nstep*sdf0(ispect),chans,
     *          maxspect,nspect,sfreq,sdf,nschan,bdrop,edrop)
              n = n - chans
              start = start + nstep * chans
            enddo
c
c  Handle "wide" linetype.
c
          else if(ltype.eq.wide)then
            if(nstep.ne.1.or.nwidth.ne.1)call bug('f',
     *        'Line width and step parameters must be 1 for line=wide')
            call uvrdvri(tno,'nwide',nwide,0)
            if(nwide.le.0.or.nwide.gt.mspect)
     *          call bug('f','Bad value for nwide in DESPECT')
            call uvgetvrr(tno,'wfreq',wfreq,nwide)
            call uvgetvrr(tno,'wwidth',wwidth,nwide)
            do j=start,start+nchan-1
              call setstate(state,dble(wfreq(j)),dble(wwidth(j)),1,
     *              maxspect,nspect,sfreq,sdf,nschan,0,0)
            enddo
          else
            call bug('f','Unsupported linetype')
          endif
          updated = .false.
        endif
c
c We know the frequency setup. Now fill the chan and spect arrays with this
c setup.
c
        n = 0
        do j=2,state(1,1)+1
          ispect = state(1,j)
          ibeg  = state(2,j)
          iend  = state(3,j)
          if(ispect.eq.0)then
            do i=ibeg,iend
              n = n + 1
              chan(n) = 0
            enddo
          else
            do i=ibeg,iend
              n = n + 1
              chan(n) = i
              spect(n) = ispect
            enddo
          endif
        enddo
c                 
        end
c************************************************************************
        subroutine setstate(state,f,df,nchan,
     *          maxspect,nspect,sfreq,sdf,nschan,bdrop,edrop)
c
        integer maxspect,nspect,nchan,bdrop,edrop
        integer state(3,maxspect+2),nschan(maxspect)
        double precision f,df,sfreq(maxspect),sdf(maxspect)
c
c  Find the current frequency setup in the list of previous setups.
c
c  Input:
c    f		Frequency of the first channel (ignoring channels to drop).
c    df		Frequency increment between channels.
c    nchan	Total number of channels (ignoring channels to drop).
c    bdrop,edrop Number of channels to drop at beginning and end of window.
c    maxspect
c  Input/Output:
c    nspect	Number of spectral windows stored in sfreq,sdf,nschan
c    sfreq
c    sdf
c    nschan
c    state
c------------------------------------------------------------------------
        logical more
        integer ispect,i
        double precision f0
c
c  See if we have a match.
c
        f0 = f + bdrop * df
        more = nspect.gt.0
        ispect = 1
        dowhile(more)
          if(abs(f0-sfreq(ispect)).lt.0.5*abs(sdf(ispect)).and.
     *       abs(df-sdf(ispect)).lt.0.01*abs(sdf(ispect)))then
            more = .false.
          else
            ispect = ispect + 1
            more = ispect.le.nspect
          endif
        enddo
c
c  If there was not a match, fill in a new slot for it. Otherwise
c  make sure the total number of channels is OK.
c
        if(ispect.gt.nspect)then
          nspect = nspect + 1
          if(nspect.gt.maxspect)
     *      call bug('f','Too many spectral windows for me to handle')
          sdf(nspect) = df
          sfreq(nspect) = f0
          nschan(nspect) = nchan - bdrop - edrop
        else
          nschan(ispect) = max(nschan(ispect),nchan - bdrop - edrop)
        endif
c
c  Return the new frequency setup description.
c
        i = state(1,1) + 1
        if(bdrop.gt.0)then
          if(i.gt.1.and.state(1,i).eq.0)then
            state(3,i) = state(3,i) + bdrop
          else
            i = i + 1
            if(i.gt.maxspect+2)
     *        call bug('f','Buffer overflow, in despect-1')
            state(1,i) = 0
            state(2,i) = 1
            state(3,i) = bdrop
          endif
        endif
        i = i + 1
        if(i.gt.maxspect+2)
     *    call bug('f','Buffer overflow, in despect-2')
        state(1,i) = ispect
        state(2,i) = 1
        state(3,i) = nchan - bdrop - edrop
        if(edrop.gt.0)then
          i = i + 1
          if(i.gt.maxspect+2)
     *      call bug('f','Buffer overflow, in despect-3')
          state(1,i) = 0
          state(2,i) = 1
          state(3,i) = edrop
        endif
        state(1,1) = i - 1
        end
c************************************************************************
        subroutine bpini(npol,nants,nchan,nsoln,nspect,nschan,wgains,
     *    freq,pass,gains,tau,dodelay,dopass)
c
        integer npol,nants,nspect,nsoln,nchan,nschan(nspect)
        real tau(nants,nsoln)
        double precision freq(nspect)
        complex wgains(nants,nspect,npol,nsoln),gains(nants,npol,nsoln)
        complex pass(nants,nchan,npol)
        logical dodelay,dopass
c
c  Given the gains for each antenna for each band (WGains), estimate the
c  passband gain (Pass), atmospheric delay (Tau) and antenna gain (Gains).
c  These are estimates that are used in a full-blown solver later on.
c
c  Input:
c    WGains	The antenna gains for each antenna for each band.
c    freq	Centre frequency of each band.
c    nants	Number of antennae.
c    nspect	Number of frequency bands.
c    nsoln	Number of solution intervals.
c    npol	Number of polarisations.
c    dodelay	Estimate the delay parameters?
c  Output:
c    Pass	Estimate of the passband gains.
c    Gains	Estimate of the antenna gains.
c    Tau	Estimate of the atmospheric delay.
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxpol
        parameter(maxpol=2)
        integer i,j,k,p
        complex g,wpass(maxant*maxwin*maxpol)
        logical more
        real epsi
c
c  Set the antenna gains as the gain of the lowest band.
c
        do k=1,nsoln
          do p=1,npol
            do j=1,nants
              gains(j,p,k) = 0
              tau(j,k) = 0
              i = 0
              more = .true.
              dowhile(more)
                i = i + 1
                g = wgains(j,i,p,k)
                if(abs(real(g))+abs(aimag(g)).gt.0)then
                  gains(j,p,k) = g
                  more = .false.
                else
                  more = i.lt.nspect
                endif
              enddo
            enddo
          enddo
        enddo
c
c  If we want the passband, iteratively solve for the band gain, the antenna
c  gain and atmospheric delay.
c
        if(dopass)then
          epsi = 1
          dowhile(epsi.gt.1e-2)
            call bandest(nants,npol,nspect,nsoln,wgains,freq,
     *        wpass,gains,tau)
            call gainest(nants,npol,nspect,nsoln,wgains,freq,
     *        wpass,gains,tau,dodelay,epsi)
          enddo
c
c  Otherwise, initialise the band gain to 1, and solve for the
c  antenna gain and delay.
c
        else
          do i=1,nspect*nants*npol
            wpass(i) = 1
          enddo
          call gainest(nants,npol,nspect,nsoln,wgains,freq,
     *      wpass,gains,tau,dodelay,epsi)
        endif
c
c  OK, we now have estimates of everything that we want. Fill in the
c  "Pass" array.
c
        call passfill(nants,npol,nchan,nspect,nschan,wpass,pass)
c
        end
c************************************************************************
        subroutine passfill(nants,npol,nchan,nspect,nschan,wpass,pass)
c
        integer nants,npol,nchan,nspect,nschan(nspect)
        complex wpass(nants,nspect,npol),pass(nants,nchan,npol)
c
c  Fill in the passband estimate.
c
c  Input:
c    nants,nchan,nspect,nschan,npol
c    WPass
c  Output:
c    Pass
c------------------------------------------------------------------------
        integer i,j,k,p,chan
        complex temp
        do p=1,npol
          chan = 0
          do k=1,nspect
            do i=1,nants
              temp = wpass(i,k,p)
              do j=chan+1,chan+nschan(k)
                pass(i,j,p) = temp
              enddo
            enddo
            chan = chan + nschan(k)
          enddo
        enddo
        end
c************************************************************************
        subroutine gainest(nants,npol,nspect,nsoln,wgains,freq,
     *    wpass,gains,tau,dodelay,epsi)
        integer nants,nspect,nsoln,npol
        real tau(nants,nsoln),epsi
        double precision freq(nspect)
        complex wgains(nants,nspect,npol,nsoln),gains(nants,npol,nsoln)
        complex wpass(nants,nspect,npol)
        logical dodelay
c
c  Given the band gain (wpass) and the overall gain (wgain), estimate the
c  antenna gain and the delay term.
c
c  Input:
c    WGains	The antenna gains for each antenna for each band.
c    freq	Centre frequency of each band.
c    nants	Number of antennae.
c    nspect	Number of frequency bands.
c    nsoln	Number of solution intervals.
c    WPass	Estimate of the band gains.
c    dodelay	Solve for the delay terms.
c  Input/Output:
c    Gains	Estimate of the antenna gains.
c    Tau	Estimate of the atmospheric delay.
c  Output:
c    epsi	Fractional change in the gains.
c------------------------------------------------------------------------
        include 'mirconst.h'
        integer i,j,k,n,p
        real theta,summm,delta,sumf,sumt,sumtf,sumff
        real sumdt2,sumt2,sumdg2,sumg2,f
        complex v,m,sumvm,cdelta,temp
c
c  Initialise.
c
        sumdt2 = 0
        sumt2  = 0
        sumdg2 = 0
        sumg2  = 0
c
c  Loop over all solutions for all antennae.
c
        do k=1,nsoln
          do i=1,nants
c
c  Solve for the delay term. Use a simple linear approach.
c
            if(dodelay)then
              sumf = 0
              sumt = 0
              sumtf = 0
              sumff = 0
              n = 0
              do p=1,npol
                do j=1,nspect
                  v = wgains(i,j,p,k)
                  if(abs(real(v))+abs(aimag(v)).gt.0)then
                    f = freq(j)
                    temp = v / (wpass(i,j,p) * gains(i,p,k))
                    theta = atan2(aimag(temp),real(temp))
     *                            - 2*pi*tau(i,k)*f
                    theta = mod(theta,2*pi)
                    if(theta.gt.pi)  theta = theta - 2*pi
                    if(theta.lt.-pi) theta = theta + 2*pi
                    sumf = sumf + f
                    sumt = sumt + theta
                    sumtf = sumtf + theta*f
                    sumff = sumff + f*f
                    n = n + 1
                  endif
                enddo
              enddo
              if(n.gt.1.and.sumff.gt.0)then
                delta = (n*sumtf - sumt*sumf) /
     *                  (2*pi*(n*sumff - sumf*sumf))
                tau(i,k) = tau(i,k) + delta
                sumdt2 = sumdt2 + delta*delta
                sumt2 = sumt2 + tau(i,k)*tau(i,k)
              else
                tau(i,k) = 0
              endif
            endif
c
c  Now solve for the antenna gain.
c
            do p=1,npol
              sumvm = 0
              summm = 0
              do j=1,nspect
                v = wgains(i,j,p,k)
                if(abs(real(v))+abs(aimag(v)).gt.0)then
                  theta = 2*pi * tau(i,k) * freq(j)
                  m = wpass(i,j,p) * cmplx(cos(theta),sin(theta))
                  sumvm = sumvm + v*conjg(m)
                  summm = summm + real(m)**2 + aimag(m)**2
                endif
              enddo
              if(summm.gt.0)then
                cdelta = sumvm / summm - gains(i,p,k)
                gains(i,p,k) = gains(i,p,k) + cdelta
                sumdg2 = sumdg2 + real(cdelta)**2 + aimag(cdelta)**2
                sumg2 = sumg2 +
     *            real(gains(i,p,k))**2 + aimag(gains(i,p,k))**2
              else
                gains(i,p,k) = 0
              endif
            enddo
c
          enddo
        enddo
c
        epsi = 0
        if(sumg2.gt.0) epsi = max(epsi, sumdg2 / sumg2)
        if(sumt2.gt.0) epsi = max(epsi, sumdt2 / sumt2)
        epsi = sqrt(epsi)
        end
c************************************************************************
        subroutine bandest(nants,npol,nspect,nsoln,wgains,freq,
     *    wpass,gains,tau)
c
        integer nants,nspect,nsoln,npol
        real tau(nants,nsoln)
        double precision freq(nspect)
        complex wgains(nants,nspect,npol,nsoln),gains(nants,npol,nsoln)
        complex wpass(nants,nspect,npol)
c
c  Estimate the band gain, given the gains for each antenna for each band,
c  the antenna gains, and the atmospheric gains.
c
c  Input:
c    WGains	The antenna gains for each antenna for each band.
c    freq	Centre frequency of each band.
c    nants	Number of antennae.
c    nspect	Number of frequency bands.
c    nsoln	Number of solution intervals.
c    Gains	Estimate of the antenna gains.
c    Tau	Estimate of the atmospheric delay.
c  Output:
c    WPass	Estimate of the band gains.
c------------------------------------------------------------------------
        include 'mirconst.h'
        include 'maxdim.h'
        integer maxpol
        parameter(maxpol=2)
        integer i,j,k,p
        real summm(maxant,maxwin,maxpol),theta
        complex sumvm(maxant,maxwin,maxpol),g,v
c
c  Initialise the accumulators.
c
        do p=1,npol
          do j=1,nspect
            do i=1,nants
              summm(i,j,p) = 0
              sumvm(i,j,p) = 0
            enddo
          enddo
        enddo
c
c  Accumulate the rubbish.
c
        do k=1,nsoln
          do p=1,npol
            do j=1,nspect
              do i=1,nants
                g = wgains(i,j,p,k)
                if(abs(real(g))+abs(aimag(g)).gt.0)then
                  theta = 2*pi * freq(j) * tau(i,k)
                  v = gains(i,p,k) * cmplx(cos(theta),sin(theta))
                  sumvm(i,j,p) = sumvm(i,j,p) + g*conjg(v)
                  summm(i,j,p) = summm(i,j,p) + real(v)**2 + aimag(v)**2
                endif
              enddo
            enddo
          enddo
        enddo
c
c  Now we need to fill in the resulting solution.
c
        do p=1,npol
          do j=1,nspect
            do i=1,nants
              if(summm(i,j,p).gt.0)then
                wpass(i,j,p) = sumvm(i,j,p) / summm(i,j,p)
              else
                wpass(i,j,p) = 0
              endif
            enddo
          enddo
        enddo
c
        end
c************************************************************************
        subroutine solvebp(refant,minant,nants,nspect,nchan,nsoln,pass,
     *    source,freq,dat,wt,vid,ischan,count,n,npol,gains,tau,tol)
c
        integer nants,nchan,n,nsoln,refant,minant,nspect,npol
        real tau(nants,nsoln),source(nchan),tol,wt(n)
        double precision freq(nchan)
        complex pass(nants,nchan,npol),gains(nants,npol,nsoln)
        complex dat(n)
        integer vid(n),count(nsoln),ischan(nspect)
c
c  Given the source, antenna gains and atmospheric delays, solve for
c  the pass band.
c
c  Input:
c    nants	Number of antennae.
c    nspect
c    nchan	Total number of channels.
c    n		Number of data points.
c    refant	The reference antenna.
c    source	Source flux as a function of frequency.
c    freq	Frequency of each channel.
c    Pass	Passband gain.
c    Dat	Visibility data.
c    Wt		Weight of each visibility.
c    VID
c    SolNo	Antenna solution number.
c    Gains	Antenna gains.
c    Tau	Delay term.
c    tol	Convergence tolerance.
c  Input/Output:
c    Pass	Pass band.
c------------------------------------------------------------------------
         include 'maxdim.h'
        integer psumvm,psummm
        real epsi
        integer nbl,off,i,p
c
        real ref(maxbuf)
        complex cref(maxbuf/2)
        equivalence(ref,cref)
        common ref
c
        nbl = nants*(nants-1)/2
c
c  Allocate memory.
c
        call memalloc(psumvm,nbl*nchan*npol,'c')
        call memalloc(psummm,nbl*nchan*npol,'r')
c
c  Accumulate statistics.
c
        call accpb(nants,nspect,nbl,nchan,npol,nsoln,source,freq,dat,wt,
     *          vid,ischan,count,n,gains,tau,cref(psumvm),ref(psummm))
c
c  Having accumulated the crap, go and get a solution.
c
        off = 0
        do p=1,npol
          do i=1,nchan
            call solve(nants,nbl,cref(psumvm+off),ref(psummm+off),
     *        pass(1,i,p),refant,minant,tol*tol,epsi,.false.)
            off = off + nbl
          enddo
        enddo
c
c  Free up the allocated memory.
c
        call memfree(psumvm,nbl*nchan*npol,'c')
        call memfree(psummm,nbl*nchan*npol,'r')
        end
c************************************************************************
        subroutine solve(nants,nbl,sumvm,summm,gains,
     *  refant,minant,tol,epsi,init)
c
        integer nants,nbl,refant,minant
        complex sumvm(nbl),gains(nants)
        real summm(nbl),tol,epsi
        logical init
c
c  Given the accumulated crap, solve for the passband value for this
c  particular frequency channel.
c
c  Input:
c    nants	Number of antennae.
c    nbl	Total number of baselines = nants*(nants-1)/2
c    SumVM,SumMM Accumulated rubbish.
c    init	No initial guess of the gains has been given. This routine
c		works it out from scratch.
c    minant	Minimum number of antenna before a solution will be attempted.
c    refant	The reference antenna.
c    tol	Solution convergence tolerance.
c  Input/Output:
c    Gains	On entry, an estimate of the antenna gains. On exit,
c		an updated estimate! If "init" is true, then the gains
c		are not input, and an initial estimate should be made.
c  Output:
c    epsi	Fractional change
c------------------------------------------------------------------------
         include 'maxdim.h'
        integer i,i1,i2,k,nantsd,nbld,idx(maxant)
        integer b1(maxbase),b2(maxbase)
        complex ref,g(maxant),svm(maxbase)
        real smm(maxbase)
        external scale
        do i=1,nants
          idx(i) = 0
        enddo
        if(init)then
          do i=1,nants
            gains(i) = 1
          enddo
        endif
        nantsd = 0
        nbld = 0
        k = 0
        do i2=2,nants
          do i1=1,i2-1
            k = k + 1
            if(summm(k).gt.0)then
              nbld = nbld + 1
              if(idx(i1).eq.0)then
                nantsd = nantsd + 1
                idx(i1) = nantsd
                g(nantsd) = gains(i1)
              endif
              if(idx(i2).eq.0)then
                nantsd = nantsd + 1
                idx(i2) = nantsd
                g(nantsd) = gains(i2)
              endif
              b1(nbld) = idx(i1)
              b2(nbld) = idx(i2)
              svm(nbld) = sumvm(k)
              smm(nbld) = summm(k)
            endif
          enddo
        enddo
c
c  Get the solution and unpack it.
c
        if(nantsd.ge.minant)then
          if(init)then
            call phasol(nantsd,nbld,svm,b1,b2,g,tol)
            call scale(nantsd,nbld,svm,smm,b1,b2,g)
          endif
          call amphasol(nantsd,nbld,svm,smm,b1,b2,g,tol,epsi)
          if(idx(refant).gt.0)then
            ref = conjg(g(idx(refant))) / abs(g(idx(refant)))
          else
            ref = 1
          endif
          do i=1,nants
            if(idx(i).gt.0)then
              gains(i) = ref * g(idx(i))
            else
              gains(i) = 0
            endif
          enddo
c
c  Otherwise things have gone wrong. Set everything to zero.
c
        else
          do i=1,nants
            gains(i) = 0
          enddo
        endif
        end
c************************************************************************
        subroutine phasol(nants,nbl,sumvm,b1,b2,gain,tol)
c
        integer nbl,nants
        integer b1(nbl),b2(nbl)
        complex sumvm(nbl),gain(nants)
        real tol
c
c  Solve for the phase corrections which minimise the error. This uses
c  a nonlinear Jacobi iteration, as suggested by Fred Schwab in "Adaptive
c  calibration of radio interferomter data", SPIE Vol. 231, 1980
c  International Optical Computing Conference (pp 18-24). The damping
c  heuristics are copied from AIPS ASCAL.
c
c  Input:
c    nbl	Number of baselines.
c    nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Model*conjg(Vis)
c  Input/Output:
c    Gain	The antenna gain solution.
c------------------------------------------------------------------------
         include 'maxdim.h'
        integer maxiter
        parameter(maxiter=100)
c
        real factor,change
        complex temp
        integer niter,i
        complex sum(maxant)
        logical convrg
c
c  Initialise.
c 
        do i=1,nants
          sum(i) = (0.,0.)
        enddo
c
        factor = 0.8
        if(nants.le.6)factor = 0.5
c
c  Iterate.
c
        convrg = .false.
        niter = 0
        do while(.not.convrg.and.niter.lt.maxiter)
          niter = niter + 1
c
c  Sum the contributions over the baselines. Note that the following
c  loop has a dependency.
c
          do i=1,nbl
            sum(b1(i)) = sum(b1(i)) + gain(b2(i)) *       sumvm(i)
            sum(b2(i)) = sum(b2(i)) + gain(b1(i)) * conjg(sumvm(i))
          enddo
c
c  Update the gains.
c
          change = 0
          do i=1,nants
            temp = ( sum(i)/abs(sum(i)) )
            temp = gain(i) + factor * ( temp - gain(i) )
            temp = temp/abs(temp)
            change = change + real(gain(i)-temp)**2
     *                      + aimag(gain(i)-temp)**2
            gain(i) = temp
            sum(i) = (0.,0.)
          enddo
          convrg = change/nants .lt. tol
        enddo
        end
c************************************************************************
        subroutine scale(nants,nbl,sumvm,summm,b1,b2,gain)
c
        integer nants,nbl
        integer b1(nbl),b2(nbl)
        complex sumvm(nbl),gain(nants)
        real summm(nbl)
c
c  Get an initial approximation of the gain solution. This finds a single
c  real gain which minimises the error. This helps stablise the algorithm
c  when the gain solution is very different from 1 (e.g. when we are
c  calculating a priori calibration factors).
c
c  Input:
c    nbl	Number of baselines.
c    nants	Number of antennae.
c    b1,b2	This gives the antennae pair for each baseline.
c    SumVM	Sum of Vis*conjg(Model), for each baseline.
c    SumMM	Sum of Model*conjg(Model), for each baseline.
c  Input/Output:
c    Gain	The antenna gain solution.
c
c------------------------------------------------------------------------
        integer i
        real factor,sumrmm,sumrvm
        complex t
c
        sumrvm = 0
        sumrmm = 0
        do i=1,nbl
          t = conjg(gain(b1(i))) * gain(b2(i))
          sumrvm = sumrvm + t*sumvm(i)
          sumrmm = sumrmm + (real(t)**2 + aimag(t)**2) * summm(i)
        enddo
        factor = sqrt(abs(sumrvm / sumrmm))
c
        do i=1,nants
          gain(i) = factor * gain(i)
        enddo
        end
c************************************************************************
        subroutine amphasol(nants,nbl,sumvm,summm,b1,b2,g,tol,epsi)
c
        integer nbl,nants,b1(nbl),b2(nbl)
        complex sumvm(nbl),g(nants)
        real summm(nbl),epsi,tol
c
c  Inputs:
c    nbl,nants	Number of baselines and number of antennae.
c    SumMM,SumVM Accumulated rubbish used in the solution process.
c    b1,b2	Antenna numbers of the given baseline.
c    tol	Tolerance in determining the solutions.
c  Input/Output:
c    G		Current estimate of the X gains.
c  Output:
c    epsi	Fractional change in gains.
c------------------------------------------------------------------------
        integer maxiter
        parameter(maxiter=100)
        include 'maxdim.h'
c
        integer i,niter
        logical convrg
        real sum2(maxant),factor,sumwt,change,t
        complex sum(maxant),temp
c
        real factors(11)
        data factors/0.5,0.75,8*0.9,0.5/
c
c  Initialise.
c
        epsi = 0
        do i=1,nants
          sum(i) = (0.,0.)
          sum2(i) = 0.
        enddo
c
        convrg = .false.
        niter = 0
        dowhile(.not.convrg.and.niter.lt.maxiter)
          niter = niter + 1
c
c  Get the same damping factor as AIPS.
c
          if(nants.le.6)then
            factor = 0.5
          else
            factor = factors(min(11,niter))
          endif
c
c  Sum the contributions over the baselines. Note that the following
c  loop contains a dependency (it should not vectorise).
c
          do i=1,nbl
            sum(b1(i))  = sum(b1(i)) + g(b2(i)) * sumvm(i)
            sum(b2(i))  = sum(b2(i)) + g(b1(i)) * conjg(sumvm(i))
c
            sum2(b1(i)) = sum2(b1(i)) +
     *        (real(g(b2(i)))**2 + aimag(g(b2(i)))**2)*summm(i)
            sum2(b2(i)) = sum2(b2(i)) +
     *        (real(g(b1(i)))**2 + aimag(g(b1(i)))**2)*summm(i)
          enddo
c
c  Update the gains.
c
          change = 0
          sumwt = 0
c
c  Evaluate gain, and zero counters.
c
          do i=1,nants
            t = 1./sum2(i)
            temp = t * sum(i) - g(i)
            g(i) = g(i) + factor * temp
            change = change + real(temp)**2 + aimag(temp)**2
            sumwt = sumwt + real(g(i))**2  + aimag(g(i))**2
            sum(i) = 0
            sum2(i) = 0
          enddo
          t = change/sumwt
          epsi = max(epsi,t)
          convrg = t.lt.tol
        enddo
c
        end
c************************************************************************
        subroutine accpb(nants,nspect,nbl,nchan,npol,nsoln,source,freq,
     *    vis,wt,vid,ischan,count,nvis,gains,tau,sumvm,summm)
c
        integer nants,nbl,nchan,nsoln,nvis,nspect,npol
        real source(nchan),tau(nants,nsoln),wt(nvis)
        double precision freq(nchan)
        complex vis(nvis),gains(nants,npol,nsoln)
        integer vid(nvis),count(nsoln),ischan(nspect)
        complex sumvm(nbl,nchan,npol)
        real summm(nbl,nchan,npol)
c
c  Accumulate rubbish.
c------------------------------------------------------------------------
        include 'mirconst.h'
        integer i,j,bl,off,spect,chan,i1,i2,p
        real theta,w
        complex v,model
        external unpack
c
        do p=1,npol
          do j=1,nchan
            do i=1,nbl
              sumvm(i,j,p) = 0
              summm(i,j,p) = 0
            enddo
          enddo
        enddo
c
c  Go through things, accumulating all the rubbish we could possibly
c  want.
c
        off = 0
        do j=1,nsoln
          do i=1,count(j)
            off = off + 1
            call unpack(i1,i2,p,spect,chan,vid(off))
            chan =  chan + ischan(spect)
            v = vis(off)
            w = wt(off)
c         write(*,*) 'off amp=',off,sqrt(real(v)**2+aimag(v)**2),' p=',p
c
            theta = 2*pi* freq(chan) * ( tau(i1,j) - tau(i2,j) )
            model = source(chan)*gains(i1,p,j)*conjg(gains(i2,p,j))
     *            * cmplx(cos(theta),sin(theta))
            bl = (i2-1)*(i2-2)/2 + i1
            sumvm(bl,chan,p) = sumvm(bl,chan,p) + v*conjg(model)
            summm(bl,chan,p) = summm(bl,chan,p) + w*model*conjg(model)
          enddo
        enddo
        end
c************************************************************************
        subroutine solvegt(refant,minant,nants,nspect,nchan,nsoln,pass,
     *    source,freq,vis,wt,vid,ischan,count,nvis,npol,gains,tau,
     *    dodelay,tol)
c
        integer refant,minant,nants,nchan,nsoln,nvis,nspect,npol
        integer vid(nvis),count(nsoln),ischan(nspect)
        complex pass(nants,nchan,npol),vis(nvis),gains(nants,npol,nsoln)
        real source(nchan),tau(nants,nsoln),tol,wt(nvis)
        double precision freq(nchan)
        logical dodelay
c
c  Driver for the routine to solve for the antenna gains and delays.
c------------------------------------------------------------------------
        integer i,off
c
        off = 1
        do i=1,nsoln
          if(dodelay)then
            call solvegt1(refant,nants,nspect,nchan,npol,pass,source,
     *          freq,vis(off),wt(off),vid(off),ischan,count(i),
     *          gains(1,1,i),tau(1,i),tol)
          else
            call solvegt2(refant,minant,nants,nspect,nchan,npol,pass,
     *          source,vis(off),wt(off),vid(off),ischan,count(i),
     *          gains(1,1,i),tol)
          endif
          off = off + count(i)
        enddo
        end
c************************************************************************
                subroutine SolveGT1(refant,nants,nspect,nchan,npol,
     *    Pass,Source,freq,Dat,Wt,VID,ischan,n,Gains,Tau,tol)
c
        implicit none
        integer nants,nchan,n,refant,nspect,npol
        real Tau(nants),Source(nchan),tol
        double precision freq(nchan)
        complex Pass(nants,nchan,npol),Gains(nants,npol)
        complex Dat(n)
        real Wt(n)
        integer VID(n),ischan(nspect)
c
c  Solve for the antenna gains and the atmospheric delay.
c
c  Input:
c    nants      Number of antennae.
c    nspect
c    nchan      Total number of channels.
c    n          Number of data points.
c    refant     The reference antenna.
c    source     Source flux as a function of frequency.
c    freq       Frequency of each channel.
c    Pass       Passband gain.
c    Dat        Visibility data.
c    Wt         Weight for each data point.
c    VID        Visibility antennae, polarisation, channel, band.
c    tol        Convergence tolerance.
c  Input/Output:
c    Gains
c    Tau
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxdata,maxpol
        parameter(maxdata=5000,maxpol=2)
c
        complex vis(maxdata),model(maxdata)
        integer b1(maxdata),b2(maxdata),t1(maxdata),t2(maxdata)
        integer zerovar(maxpol+1),nzero
        real angfreq(maxdata)
        common/mfcalcom/vis,model,angfreq,b1,b2,t1,t2,zerovar,nzero
        integer MAXITER,MAXVAR
        parameter(MAXITER=200,MAXVAR=(1+2*MAXPOL)*MAXANT)
        include 'mirconst.h'
c
        integer i,Idx(MAXANT,MAXPOL),TIdx(MAXANT),p
        integer ifail,spect,chan,i1,i2,nvar,neqn
c
c  Scratch arrays for the least squares solver.
c
        real x(MAXVAR),dx(MAXVAR),W
        integer dfdx,aa,f,fp
c
c  Dynamic memory commons.
c
        real ref(MAXBUF)
        common ref
c
c  Externals.
c
        character itoaf*4
        external FUNC,DERIVE,UNPACK
c
c  Check we have enough space.
c
        if(n.gt.MAXDATA)call bug('f','Too many data points')
c
c  Initialise the indices to keep track of things.
c
        do p=1,npol
          do i=1,nants
            Idx(i,p) = 0
            TIdx(i) = 0
          enddo
        enddo
c
c  Copy the data across into common, determining the variable index as we go.
c
        nvar = 0
        do i=1,n
          call unpack(i1,i2,p,spect,chan,VID(i))
          chan = chan + ischan(spect)
          if(Idx(i1,p).eq.0)then
            Idx(i1,p) = nvar + 1
            nvar = nvar + 2
          endif
          if(TIdx(i1).eq.0)then
            nvar = nvar + 1
            TIdx(i1) = nvar
          endif
          if(Idx(i2,p).eq.0)then
            Idx(i2,p) = nvar + 1
            nvar = nvar + 2
          endif
          if(TIdx(i2).eq.0)then
            nvar = nvar + 1
            TIdx(i2) = nvar
          endif
          b1(i) = Idx(i1,p)
          b2(i) = Idx(i2,p)
          t1(i) = TIdx(i1)
          t2(i) = TIdx(i2)
          angfreq(i) = 2*pi*freq(chan)
          W = sqrt(Wt(i))
          Model(i) = W * Source(chan) *
     *                  Pass(i1,chan,p) * conjg(Pass(i2,chan,p))
          Vis(i) = Dat(i) / W
        enddo
c
c  Make a list of the variables that are to be constrained to be zero. This
c  is to make life simpler in the solver. The are the delay of the
c  reference antenna, and the imaginary parts of the gains of the reference
c  antenna.
c
        nzero = 1
        zerovar(nzero) = TIdx(refant)
        do p=1,npol
          if(Idx(refant,p).gt.0)then
            nzero = nzero + 1
            zerovar(nzero) = Idx(refant,p) + 1
          endif
        enddo
        neqn = 2*n+nzero
c
c  Copy across the current estimate of the variables.
c
        do i=1,nants
          do p=1,npol
            if(Idx(i,p).gt.0)then
              x(Idx(i,p))   = real(Gains(i,p))
              x(Idx(i,p)+1) = aimag(Gains(i,p))
            endif
          enddo
          if(TIdx(i).gt.0) x(Tidx(i)) = Tau(i)
        enddo
c
c  Allocate memory for scratch arrays.
c
        call memalloc(dfdx,neqn*nvar,'r')
        call memalloc(aa,nvar*nvar,'r')
        call memalloc(f,neqn,'r')
        call memalloc(fp,neqn,'r')
c
c  Call the solver at last.
c
        call nllsqu(nvar,neqn,x,x,MAXITER,0.,tol,.true.,
     *    ifail,FUNC,DERIVE,ref(f),ref(fp),dx,ref(dfdx),ref(aa))
        if(ifail.ne.0)call bug('w',
     *    'Solver failed to converge: ifail='//itoaf(ifail))
c
c  Free up the memory now.
c
        call memfree(fp,neqn,'r')
        call memfree(f,neqn,'r')
        call memfree(aa,nvar*nvar,'r')
        call memfree(dfdx,neqn*nvar,'r')
c
c  Now unpack the solution.
c
        do i=1,nants
          do p=1,npol
            if(Idx(i,p).gt.0)then
              Gains(i,p) = cmplx(x(Idx(i,p)),x(Idx(i,p)+1))
            else
              Gains(i,p) = 0
            endif
          enddo
          if(TIdx(i).gt.0)then
            Tau(i) = x(Tidx(i))
          else
            Tau(i) = 0
          endif
        enddo
c
        end

        subroutine FUNC(x,f,n,m)
c
        implicit none
        integer m,n
        real x(n),f(m)
c------------------------------------------------------------------------
        integer maxdata,maxpol
        parameter(maxdata=5000,maxpol=2)
c
        complex vis(maxdata),model(maxdata)
        integer b1(maxdata),b2(maxdata),t1(maxdata),t2(maxdata)
        integer zerovar(maxpol+1),nzero
        real angfreq(maxdata)
        common/mfcalcom/vis,model,angfreq,b1,b2,t1,t2,zerovar,nzero
c
        integer i,i1,i2,j1,j2,off
        complex temp
        real theta
c
c  Fudge equations to ensure that the phase and delay of the reference antenna
c  is 0.
c
        do i=1,nzero
          f(i) = m*x(zerovar(i))
        enddo
c
        off = 0
        do i=nzero+1,m,2
          off = off + 1
          i1 = b1(off)
          i2 = b2(off)
          j1 = t1(off)
          j2 = t2(off)
          theta = angfreq(off) * (x(j1)-x(j2))
          temp = Vis(off) - cmplx(x(i1),x(i1+1))*cmplx(x(i2),-x(i2+1))
     *                     * cmplx(cos(theta),sin(theta)) * Model(off)
          f(i)   = real(temp)
          f(i+1) = aimag(temp)
        enddo
        end

        subroutine DERIVE(x,dfdx,n,m)
c
        implicit none
        integer m,n
        real x(n),dfdx(n,m)
c------------------------------------------------------------------------
        integer maxdata,maxpol
        parameter(maxdata=5000,maxpol=2)
        complex vis(maxdata),model(maxdata)
        integer b1(maxdata),b2(maxdata),t1(maxdata),t2(maxdata)
        integer zerovar(maxpol+1),nzero
        real angfreq(maxdata)
        common/mfcalcom/vis,model,angfreq,b1,b2,t1,t2,zerovar,nzero
c
        integer i,j,i1,i2,j1,j2,off
        complex g1,g2,temp,w
        real theta
c
        do j=1,m
          do i=1,n
            dfdx(i,j) = 0
          enddo
        enddo
c
c  Fudge equations to make sure that the phase and delay of the referenece
c  antenna is zero.
c
        do i=1,nzero
          dfdx(zerovar(i),i) = m
        enddo
c
c  The real equations.
c
        off = 0
        do i=nzero+1,m,2
          off = off + 1
          i1 = b1(off)
          i2 = b2(off)
          j1 = t1(off)
          j2 = t2(off)
          theta = angfreq(off) * (x(j1)-x(j2))
          w = cmplx(cos(theta),sin(theta))
          g1 = cmplx(x(i1),x(i1+1))
          g2 = cmplx(x(i2),-x(i2+1))
c
          temp = g2*w*Model(off)
          dfdx(i1,i)     = -real(temp)
          dfdx(i1+1,i)   =  aimag(temp)
          dfdx(i1,i+1)   = -aimag(temp)
          dfdx(i1+1,i+1) = -real(temp)
c
          temp = g1*w*Model(off)
          dfdx(i2,i)     = -real(temp)
          dfdx(i2+1,i)   = -aimag(temp)
          dfdx(i2,i+1)   = -aimag(temp)
          dfdx(i2+1,i+1) =  real(temp)
c
          temp = angfreq(off) * g1*g2*w * Model(off)
          dfdx(j1,i)   =  aimag(temp)
          dfdx(j1,i+1) = -real(temp)
          dfdx(j2,i)   = -aimag(temp)
          dfdx(j2,i+1) =  real(temp)
        enddo
        end

c************************************************************************
        subroutine solvegt2(refant,minant,nants,nspect,nchan,npol,
     *    pass,source,dat,wt,vid,ischan,n,gains,tol)
c
        integer nants,nchan,n,refant,minant,nspect,npol
        real source(nchan),tol
        complex pass(nants,nchan,npol),gains(nants,npol)
        complex dat(n)
        real wt(n)
        integer vid(n),ischan(nspect)
c
c  Solve for the antenna gains, but not atmospheric delay.
c
c  Input:
c    nants	Number of antennae.
c    nspect
c    nchan	Total number of channels.
c    n		Number of data points.
c    refant	The reference antenna.
c    source	Source flux as a function of frequency.
c    Pass	Passband gain.
c    Dat	Visibility data.
c    Wt		Weight for each data point.
c    VID	Visibility antennae, polarisation, channel, band.
c    tol	Convergence tolerance.
c  Input/Output:
c    Gains
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxpol
        parameter(maxpol=2)
c
        integer nbl,bl,p,i,i1,i2,spect,chan
        real summm(maxbase,maxpol),epsi
        complex sumvm(maxbase,maxpol),model
        external unpack
c
c  Initialise the accumulators.
c
        nbl = nants*(nants-1)/2
        do p=1,npol
          do i=1,nbl
            summm(i,p) = 0
            sumvm(i,p) = 0
          enddo
        enddo
c
c  Now accumulate all the rubbish.
c
        do i=1,n
          call unpack(i1,i2,p,spect,chan,vid(i))
          chan = chan + ischan(spect)
          bl = (i2-1)*(i2-2)/2 + i1
          model = source(chan) *
     *            pass(i1,chan,p) * conjg(pass(i2,chan,p))
          sumvm(bl,p) = sumvm(bl,p) + dat(i)*conjg(model)
          summm(bl,p) = summm(bl,p) + wt(i)*(real(model)**2+
     *                                      aimag(model)**2)
        enddo
c
c  Get the solution from the accumulated crap.
c
        do p=1,npol
          call solve(nants,nbl,sumvm(1,p),summm(1,p),
     *        gains(1,p),refant,minant,tol*tol,epsi,.false.)
        enddo
c
        end
c************************************************************************
        subroutine intext(npol,nants,nchan,nspect,nschan, pass)
c
        integer npol, nants, nchan, nspect, nschan(nspect)
        complex pass(nants,nchan,npol)
c
c  Spline fit the band pass table and evaluate the fit for channels
c  that have no solutions.  Do this for real and imaginary separately.
c
c  Input:
c    nants	Number of antennas.
c    npol	Number of polarisations (either 1 or 2).
c    nspect	The total number of frequency bands observed. This is the
c		product of the number of simultaneous spectral windows and
c		the number of different frequency settings.
c    nschan	The number of channels in each observing band.
c    nchan	Total number of channels.
c		NOTE: Here (as elsewhere in this task) "nchan" is the total
c		number of channels (the sum of all the channels from all the
c		bands observed).
c		i.e. nchan = Sum nschan(i)
c    Pass	The bandpass function. This is of size nants * nchan * npol.
c		The bandpass table that we have to write out is in the order
c		nchan * npol * nants, so we have to do some reorganising
c		before we write out.
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer i,j,k,l,ngaps,ischan,ig,chanlo,chanhi,nwidth,npnt,order
        integer ifail
        real rcoeff(3),icoeff(3),x
        real wp(maxchan),xp(maxchan),rp(maxchan),ip(maxchan)
        logical ok(maxchan)
        integer chan1(maxchan/2),chan2(maxchan/2)
        real wrk1(6),wrk2(3*maxchan),a,b,rnorm
        logical within
        complex temp
c
        do l=1,npol
          do k=1,nants
            ischan = 0
            do j=1,nspect
              if(nschan(j).gt.maxchan)
     *          call bug('f','Too many channels')
c
c  Find the gaps in this spectrum.
c
              ngaps = 0
              within = .false.
c
              do i=1,nschan(j)
                temp = pass(k,i+ischan,l)
                ok(i) = abs(real(temp))+abs(aimag(temp)).gt.0
                if(ok(i))then
                  if(within.and.ngaps.gt.0)then
                    chan2(ngaps) = i-1
                  endif
                  within = .false.
                else
                  if(.not.within.and.i.gt.1)then
                    ngaps = ngaps + 1
                    chan1(ngaps) = i
                  endif
                  within = .true.
                endif
              enddo
c
              if(within)ngaps = max(ngaps - 1,0)
c
c  We have a list of the gaps in the spectrum. For a gap width of "nwidth",
c  fit a quadratic to the good channels on within "nwidth" channels of
c  the band edge.
c
              a = 2.0/real(nschan(j)-1)
              b = 0.5*(nschan(j)+1)
              do ig=1,ngaps
                nwidth = chan2(ig) - chan1(ig) + 1
                chanlo = max(chan1(ig) - nwidth,1)
                chanhi = min(chan2(ig) + nwidth,nschan(j))
                npnt = 0
                do i=chanlo,chanhi
                  temp = pass(k,i+ischan,l)
                  if(ok(i))then
                    npnt = npnt + 1
                    xp(npnt) = a*(i-b)
                    rp(npnt) = real(temp)
                    ip(npnt) = aimag(temp)
                    wp(npnt) = 1
                  endif
                enddo
                order = 2
                if(npnt.lt.5)then
                  order = 1
                  rcoeff(3) = 0
                  icoeff(3) = 0
                endif
                call wpfit(order,npnt,xp,rp,wp,rcoeff,
     *                                  rnorm,wrk1,wrk2,ifail)
                if(ifail.eq.0)
     *              call wpfit(order,npnt,xp,ip,wp,icoeff,
     *                                  rnorm,wrk1,wrk2,ifail)
                if(ifail.ne.0)call bug('f','Poly fit failed')
c
c  Interpolate the missing channels.
c
                do i=chan1(ig),chan2(ig)
                  x = a*(i-b)
                  pass(k,i+ischan,l) = cmplx(
     *              rcoeff(1) + (rcoeff(2) + rcoeff(3)*x)*x ,
     *              icoeff(1) + (icoeff(2) + icoeff(3)*x)*x )
                enddo
              enddo
c
              ischan = ischan + nschan(j)
            enddo
          enddo
        enddo
c
        end
      SUBROUTINE REGPOL(T,Y,DELTAY,N,NR,X,B,A,CHI2)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
      DIMENSION T(N),Y(N),DELTAY(N),X(NR),CHI2(NR)
      DIMENSION B(NR,NR),A(N,NR)
      PARAMETER(MAXN=1000)
      DIMENSION G(MAXN)
      COMMON /DASV04/ G
      PARAMETER (ZERO=0.D0,ONE=1.D0)
c
c   orthogonal polynomial fit
c
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
      PARAMETER (MAX=1000,ZERO=0.D0,ONE=1.D0,HALF=0.5D0)
      DIMENSION X(MAX),YTMP(MAX),ETATMP(MAX),T(MAX)
      COMMON /DADV03/ X,YTMP,ETATMP,T
c
c  moving smooth
c
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
         SQSTUD=0.0d0
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

c************************************************************************
c Original from Bob Saults' MFCAL
        subroutine Accum(Hash,Data,VisId,nsoln,nvis,Vis,Wt,
     *                                          VID,Count)
c
        implicit none
        integer VisId,nsoln,nvis,VID(*),Count(*)
        real Wt(*)
        integer Hash(2,*)
        complex Data,Vis(*)
c
c  Inputs:
c    VisId      Identifier, giving channel, IF band, antennae and polarisation.
c------------------------------------------------------------------------
        integer nHash,iHash,indx,i
c
c  Find this channel in the hash table.
c
        nHash = Hash(1,1)
        iHash = VisId + 1
        indx = mod(iHash,nHash) + 2
        dowhile(Hash(1,indx).ne.0.and.Hash(1,indx).ne.iHash)
          indx = indx + 1
        enddo
        if(indx.ge.nHash+2)then
          indx = 2
          dowhile(Hash(1,indx).ne.0.and.Hash(1,indx).ne.iHash)
            indx = indx + 1
          enddo
          if(indx.ge.nHash+2)
     *          call bug('f','Hash table overflow, in Accum')
        endif
c
c  Is it a new slot?
c
        if(Hash(1,indx).eq.0)then
          nvis = nvis + 1
          Hash(1,indx) = iHash
          Hash(2,indx) = nvis
          i = nvis
          Vis(i) = Data
          Wt(i) = 1
          VID(i) = VisId
          Count(nsoln) = Count(nsoln) + 1
        else
          i = Hash(2,indx)
          Vis(i) = Vis(i) + Data
          Wt(i) = Wt(i) + 1
        endif
c
        end


