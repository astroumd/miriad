c************************************************************************
        program smatbpass
c
c= SmaTbpass -- removes time-dependent bandpass ripples (antenna-based).
c& jhz for SMA
c: calibration
c+
c	SmaTbpass is a MIRIAD task which removes time-dependent bandpass 
c       ripples. SmaTbpass reads multiple files (bpfile) containing 
c       antenna-based bandpass solved using either smamfcal or mfcal
c       in different time intervals. The bandpasses are interpolated
c       or extrapolated to a time with either linear fit from
c       the two nearby data points or orthogonal polynomial
c       fit from all the data points in the input files.
c       
c       The antenna-based bandpass in each of the multiple input
c       files must be IDENTICAL in spectral format, i.e. they must have
c       the same number of channele, the same number of spectral
c       chunks, and the same polarizations. The data used for solving 
c       for bandpass in the multiple files must be observed in the same 
c       track as the observations of the target sources in the vis files.
c
c       The output contains the data that have been applied with
c       the bandpass corrections.
c       
c@ bpfile
c       Root name of input files. Files must be named as
c       bpfile_i for the ith file, e.g. mybpass_1, mybpass_2 ... mybpass_n.
c       Each of the n bpfiles contains a bandpass solved from an independent
c       time interval using either smamfcal or mfcal.  No default. 
c       NOTE: The calibration tables (bandpass, gains, freqs) must present 
c       in the input datasets. 
c
c@ nfiles
c       The number of bandpass files (bpfile) to read.
c
c@ vis
c       The name of the input uv data sets in which the visibility
c       will be applied for bandpass corrections. Several can be given (wild
c       cards are supported) but the spectral configuration(correlator setup)
c       is identical through out the files. No default.
c
c@ bptime
c       The time interval, in minutes, to interpolate/extrapolate the 
c       bandpass solutions. The default is 60 minutes.
c
c@ options
c       This gives extra processing options. Several options can be given,
c       each separated by commas. They may be abbreivated to the minimum
c       needed to avoid ambiguity. Possible options are:
c          nocal       Do not apply the gains file. By default, UVAVER
c                      applies the gains file in copying the data.
c          opolyfit    Do least-square fit to the time variations in
c                      bandpasses given in all the bpfile_i files with an 
c                      orthogonal polynomial of degree n input from 
c                      Keyword: polyfit; n upto 10 is supported.
c                      Default: linear fit from two nearby time points.
c          cross       Apply the bandpass to the cross-hand polarization
c                      visibilities in addition to the parallel ones.
c                      Default: to the parallel ones only.
c
c@ polyfit
c       polyfit gives a degree of orthogonal polynomial in least-sqaure
c       fit to the time variaton of the bandpass. Default: 3 or cubic.
c       polyfit upto 10 is supported.
c
c@ out
c       The name of the output uv data set. No default.
c--
c  History:
c   JHZ ---> miriad software to remove time-dependent bandpass ripples 
c   jhz 19jul05 creates the first version
c   jhz 18oct05 change processing message.
c   jhz 12dec05 add options of cross for applying the bandpass
c               to the cross-hand visibilities.
c   jhz 13dec05 add initialization for the ppass array
c               in sub tpolbpass and
c                  sub t2ptbpass
c   jhz 30may06 add restriction that the bpass files
c               must have the same number of antennas
c               in the bandpass solutions.
c
c  Bugs:
c     not for dual pol case, must select one of pol in the case
c     of multiple polarizations. For dual polarization present,
c     the mean bandpass solutions of the dual polarization data is used to
c     correct for the bandpass shape. 
c     For cross-hand polarization, the mean bandpass solutions of 
c     the dual polarization data is used to correct for the bandpass 
c     shape.
c------------------------------------------------------------------------
        integer maxsels
        character version*(*)
        parameter(maxsels=256, maxspect=49)
        parameter (PI = 3.14159265358979323846)
        parameter (DPI = 3.14159265358979323846)
        parameter (TWOPI = 2 * PI)
        parameter (DTWOPI = 2 * DPI)        
        parameter(version='SmaTbpass: version 1.1 12-Dec-05')
        include 'maxdim.h'
        integer maxTimes,maxGains
        parameter(maxTimes=2*MAXCHAN*MAXANT)
        parameter(maxGains=2*MAXCHAN*MAXANT)
        integer iostat,tin,tOut, nfeeds,nants,nchan,maxnants
        integer  i, j, k,nschann(maxspect),nsols,ntau
        character vis*64,bpfile*64,out*64,itoaf*3,ltype*16
        logical dopass,first
        logical doratio,docross
        complex g1(maxgains),g2(maxgains)
        real times(maxtimes),bptime(maxtimes),UT, UTstep
        real freqs(maxtimes)
        real sels(maxsels)
        character uvflags*12
        double precision t0,jtime(6154)
        logical relax, ok,donenpol
        integer npol,Snpol,pol,vupd,nread,nrec
        integer nschan(maxspect), maxspect, nspectt
        real inttime,jyperk
        double precision preamble(5),Tmin,Tmax,Tprev,interval
        double precision TTprev,sfreq(maxspect),sdf(maxspect)
        double precision sfreqq(maxspect)
        complex data(MAXCHAN)
        logical flags(MAXCHAN), tupdate, bpupdate
        logical bpflags(MAXCHAN), dopolfit
        logical dotaver,doflush,buffered,PolVary,ampsc,vecamp
c
c  Externals.
c
        logical hdprsnt,uvdatopn,uvDatPrb,uvVarUpd
c
c        data feeds/'I','X','Y'/
c        parameter(polxx=-5,polyy=-6,polrr=-1,polll=-2,poli=1)
         integer pee(2),nfiles,lin,offset,i1,i2
         integer nflgbegin, nflgend
         parameter(maxnBpass=20)
         complex tpass(maxant,maxchan,2,maxnBpass)
         integer maxnpoly, nterm
         parameter(maxnpoly=10)
         complex ppass(maxant,maxchan,2)
           integer polxx,polyy,polrr,polll,poli
        parameter(polxx=-5,polyy=-6,polrr=-1,polll=-2,poli=1)
           integer polmin,polmax
            parameter(polmin=-6,polmax=1)
           integer pols(polmin:polmax)

          first   = .true.
          doratio = .true.
          dopass  = .true.
          dopass  = .false.
          tupdate = .false.
          bpupdate = .false.
          maxnants = 0
c
c  Get the user parameters.
c
            nfile=0
        call output(version)
        call keyini
        call keya('bpfile',bpfile, ' ')
        call keyi ('nfiles', nfiles, 0)
        if (nfiles.eq.0)
     *  call bug ('f', 'Number of bandpass files not given')
         call GetOpt(uvflags,ampsc,vecamp,relax,dopolfit,docross)
        call uvDatInp('vis',uvflags)
         write(*,*) 'uvflags=', uvflags
        call selinput('select',sels,maxsels)
        call keyr('bptime', UTstep, 60.)
             UTstep=UTstep/24./60.
        call keyi('polyfit', nterm, 3)
              nterm=nterm+1        
c
c  handle output
c         
        call keya('out',out,' ')
        call keyfin
        write(*,*) 'nfiles for input bpass =',nfiles 
c
c  Open up all the input bpfiles.
c
        if(nfiles.ge.1) then
         do lin= 1, nfiles
             vis=bpfile(1:len1(bpfile))//'_'//itoaf(lin)
          call hopen(tin,vis,'old',iostat)
          if(iostat.ne.0)then
          call bug('w','Error opening input '//vis)
          call bugno('f',iostat)
          endif
          dopass=.true.
          if(dopass)then
            dopass = hdprsnt(tin,'bandpass')
            if(.not.dopass)call bug('w','Bandpass function not present')
            endif

            if(dopass)then
c load bandpass
          call bload(tin,freqs,g1,nfeeds,nants,nchan,sels,
     *          maxgains,maxtimes,nschann,nspectt)
             

c load gains
          call gload(tin,t0,times,jtime, g2,nfeeds,ntau,nants,
     *               nsols,sels, maxgains,maxtimes)

           

         if(nsols.gt.1) call bug('f', 'number of time interval >1.')
c load the bpass time
         bptime(lin) = times(1)
c get the number of antennas from each files
         
         if(lin.eq.1) maxnants=nants
         if((lin.gt.1).and.(maxnants.ne.nants)) 
     * call bug('f', 
     * 'The number of antennas differ in different files.')
         do i=1, nants
         do j=1, nfeeds
            pee(i) =j
            offset = (j-1) + (i-1)*nfeeds
         do k=1, nchan
            tpass(i,k,j,lin) = g1(k+offset*nchan)
        
         end do
         end do
         end do
         write(*,500) 'load bandpass at UT=',
     * bptime(lin)*24.

          endif
          call hclose(tin)
          end do
          endif
c           assign the number of antennas.
            nants=maxnants
            


c 
c handle the input vis data
c
c
c  Various initialisation.
c
c no averaging
        interval = 0.
        interval = interval/(24.*60.)
        npol = 0
        Snpol = 0
        first = .true.
        PolVary = .false.
        doflush = .false.
        buffered = .false.
        donenpol = .false.
        dotaver = interval.gt.0.or.uvDatPrb('polarization?',0.d0)
        call BufIni
        nrec = 0
c
c  Open the input and the output files.
c
          dowhile(uvDatOpn(tIn))
          nbin = 1
          if(dotaver)then
            call uvrdvri(tIn,'nbin',nbin,1)
            if(nbin.gt.1)then
              call bug('w',
     *        'Time averaging or pol''n selection of bin-mode data')
              call bug('w',
     *        'This will average all bins together')
          endif
          endif
          call uvDatGta('ltype',ltype)
          call VarInit(tIn,ltype)
          call uvVarIni(tIn,vupd)
          call uvVarSet(vupd,'dra')
          call uvVarSet(vupd,'ddec')
          call uvVarSet(vupd,'source')
          call uvVarSet(vupd,'on')
        if(docross) 
     *  write(*,*) 
     * 'Apply the bpass to all the polarization components.'
        if(.not.docross) then 
        call uvselect(tIn,'polarization',dble(polxx),0.d0,.true.)
        call uvselect(tIn,'polarization',dble(polyy),0.d0,.true.)
        call uvselect(tIn,'polarization',dble(polrr),0.d0,.true.)
        call uvselect(tIn,'polarization',dble(polll),0.d0,.true.)
        call uvselect(tIn,'polarization',dble(poli),0.d0,.true.)
        end if
c
        do p=polmin,polmax
          pols(p) = 0
        enddo
        npol = 0

c
c Special processing the first time around.
c
          if(first)then


c copy things to output file
            call uvopen(tOut,out,'new')
            call uvset(tOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
            call hdcopy(tIn,tOut,'history')
            call hisopen(tOut,'append')
            call hiswrite(tOut,'SmaTBpass: Miriad '//version)
            call hisinput(tOut,'SmaTBpass')
            call hisclose(tOut)
            first = .false.
          endif
          call VarOnit(tIn,tOut,ltype)
c
c  Loop over the data.
c
          call uvDatRd(preamble,data,flags,maxchan,nread)

            call uvrdvri(tin,'nspect',nspect,0)
            call uvgetvrd(tin,'sfreq',sfreq,nspect)
            call uvgetvrd(tin,'sdf',sdf,nspect)
            call uvgetvri(tin,'nschan',nschan,nspect)
             k=0
             do i=1, nspectt
             if(i.eq.1) k=1
             if(i.gt.1) k=k+nschann(i-1) 
             sfreqq(i) = freqs(k)
             enddo
c
c detemine the bpflag, which were done in edge flagging
c during smafcal or mfcal
c
             do i=1,nread
             bpflags(i)=.true.
             enddo
             k=0
             do i=1, nspect
             if(i.eq.1) k=1
             if(i.gt.1) k=k+nschan(i-1)
              nflgbegin = abs(nint((sfreq(i)-sfreqq(i))/sdf(i)))
             do j=1, nflgbegin
             bpflags(k+j-1)=.false.
             enddo
             nflgend   = nschan(i)-nschann(i)-nflgbegin
             do j=1, nflgend
             bpflags(k+nschan(i)-j)=.false.
             enddo
             enddo

          Tprev = preamble(4)
          Tmin = Tprev
          Tmax = Tmin
          TTprev = Tprev
          t0 = nint(TTprev - 1.d0) + 0.5d0
          UT= preamble(4)-t0
c
c polynomial interpolate bpass and get a new bpass at UT
c for each of the antennas
c
        if(.not.dopolfit) call t2ptbpass(nterm,nants,nchan,nfiles,
     *            nfeeds,ppass,tpass,bptime,UT)
        if(dopolfit) call tpolbpass(nterm,nants,nchan,nfiles,
     *            nfeeds,ppass,tpass,bptime,UT)
            write(*,500) 'applied bpass at UT=',
     * UT*24.
          UT=UT+UTstep
          dowhile(nread.gt.0)
          
          if((preamble(4)-t0).gt.UT) then
c
c update the UT time
c
             UT=preamble(4)-t0           
c
c polynomial interpolate bpass and get a new bpass at UT
c for each of the antennas
             
        if(dopolfit) call tpolbpass(nterm,nants,nchan,nfiles,
     *            nfeeds,ppass,tpass,bptime,UT)
        if(.not.dopolfit) call t2ptbpass(nterm,nants,nchan,nfiles,
     *            nfeeds,ppass,tpass,bptime,UT)
        write(*,500) 'applied bpass at UT=',
     * UT*24.
           UT=UT+UTstep
                       endif
c
c  Count the number of records read.
c
            nrec = nrec + 1
c
c  Do we want to keep this record.
c
           ok = relax.or.donenpol
            if(.not.ok)then
              do i=1,nread
                ok = ok.or.flags(i)
              enddo
            endif
c
c  Determine if we need to flush out the averaged data.
c
            doflush = ok.and.dotaver
            if(doflush)then
              doflush = uvVarUpd(vupd)
              doflush = (doflush.or.preamble(4)-Tmin.gt.interval.or.
     *                              Tmax-preamble(4).gt.interval)
     *                  .and.buffered
            endif
c
c  Flush out the accumulated data -- the case of time averaging.
c
            if(doflush)then
              call BufFlush(tOut,ampsc,vecamp,npol)
              PolVary = PolVary.or.npol.eq.0.or.
     *          (Snpol.ne.npol.and.Snpol.gt.0)
              Snpol = npol
              Tmin = preamble(4)
              Tmax = Tmin
              buffered = .false.
c
c  Flush out the accumulated data -- the case of no time averaging.
c
            else if(.not.dotaver)then
              if(npol.le.0)call uvDatGti('npol',npol)
              if(ok)then
                if(.not.donenpol)then
                  call uvputvri(tOut,'npol',npol,1)
                  PolVary = PolVary.or.
     *              (Snpol.ne.npol.and.Snpol.gt.0)
                  Snpol = npol
                endif
                call uvDatGti('pol',pol)
                call uvputvri(tOut,'pol',pol,1)
                call VarCopy(tIn,tOut)
                call uvDatGtr('jyperk',jyperk)
                call uvputvrr(tOut,'jyperk',jyperk,1)
                call uvgetvri(tIn,'nspect',nspect,1)
                call uvgetvri(tIn,'nschan',nschan,nspect)
                call uvputvri(tOut,'nschan',nschan,nspect)
c
c    apply bandpass
c    only 1 pol 
c
          call basant(preamble(5),i1,i2)
                i=0
                do k=1,nread
                if(bpflags(k)) then 
                i=i+1
                else
                flags(k) = .false.
                end if
                if(flags(k)) then
        if(abs(ppass(i1,i,1)).eq.0..and.abs(ppass(i1,i,2)).eq.0.) 
     *         ppass(i1,i,1) = ppass(i1,i,2)
       if(abs(ppass(i1,i,1)).eq.0) 
     * write(*,*) ppass(i1,i,1),i1,i, UT*24
        data(k)  = 
     *  data(k)/(ppass(i1,i,1)*conjg(ppass(i2,i,1)))
                 endif
                enddo
                     
                call uvwrite(tOut,preamble,data,flags,nread)
                call uvputvri(tOut,'nschan',nschan,nspect)
                donenpol = npol.gt.1
              endif
              npol = npol - 1
            endif
c
c  Accumulate more data, if we are time averaging.
c
            if(dotaver.and.ok)then
              call uvrdvrr(tIn,'inttime',inttime,10.)
              call BufAcc(preamble,inttime,data,flags,nread)
              buffered = .true.
              call VarCopy(tIn,tOut)
              if(nbin.gt.1)call uvputvri(tOut,'nbin',1,1)
            endif
c
c  Keep on going. Read in another record.
c
            if(ok)then
              Tprev = preamble(4)
              Tmin = min(Tmin,Tprev)
              Tmax = max(Tmax,Tprev)
            endif
            call uvDatRd(preamble,data,flags,maxchan,nread)
          enddo
c
c  Flush out anything remaining.
c
          if(buffered)then
            call BufFlush(tOut,ampsc,vecamp,npol)
            PolVary = PolVary.or.npol.le.0.or.
     *        (Snpol.ne.npol.and.Snpol.gt.0)
            Snpol = npol
            buffered = .false.
          endif
          call uvDatCls
        enddo
500     format(1x,a,1x,f5.2)
c
c  Write things to the header which describe the data as a whole.
c
        if(first)call bug('f','Error opening input')
        if(nrec.eq.0)call bug('f','No data found')
        if(.not.PolVary)call wrhdi(tOut,'npol',Snpol)

          call uvclose(tOut)
          end


c************************************************************************
        subroutine tpolbpass(nterm,nants,nchan,ntime,nfeeds,
     *                       ppass,tpass,bptime,ut)
           include 'maxdim.h'
         integer maxnBpass
         parameter(maxnBpass=20)
         complex tpass(maxant,maxchan,2,maxnBpass)
         integer nterm,nants,nchan,nfeeds
         complex ppass(maxant,maxchan,2)
         real bptime(maxnBpass),ut
c
c fit polynomial to the bandpass variaition in time
c
c    input:
c       nterm  - order of polynomial + 1
c       tpass  - input time dependent bpass
c       ntime  - number of time intervals in tpass
c       nchan  - number of channels in tpass
c       nfeed  - number of feeds in tpass
c       bptime - the UT time for the time interval in tpass
c       ut     - at the UT time to get bpass fit   
c    output:
c       ppass  - a fitted bandpass   
         PARAMETER(MAXNR=20)
         double precision XA(MAXNR),BP(MAXNR,MAXNR),AP(ntime,MAXNR),
     *                    CHI2(MAXNR)
         double precision T(ntime),Y(ntime),DELTAY(ntime)
         integer i,j,k, nfit,ant
         real fitUT, rfitBP, ifitBP
c        initialize the ppass array
          do ant=1,maxant
          do   k=1,maxchan
          do   j=1,nfeeds
          ppass(ant,k,j) = complex(1.0,0.0)
          enddo
          enddo
          enddo
c        load the time to T and convert to min from day
              nfit=1
              fitUT = UT*24.*60.
              do i=1, ntime
              T(i) = bptime(i)*24.*60.
              DELTAY(i) = 1
              end do
              do ant=1,nants
              
              do k=1, nchan
              do j=1, nfeeds
              do i=1, ntime
c
c do real
c
              Y(i) = real(tpass(ant,k,j,i))
c             write(*,*) k,j,i, Y(i),T(i)
              end do
              CALL REGPOL(T,Y,DELTAY,ntime,MAXNR,XA,BP,AP,CHI2)
              call regpolfitg(nterm,XA,BP,nfit,fitUT,rfitBP)
              do i=1, ntime
c
c do imaginary
c
              Y(i) = aimag(tpass(ant,k,j,i))
              enddo
              CALL REGPOL(T,Y,DELTAY,ntime,MAXNR,XA,BP,AP,CHI2)
              call regpolfitg(nterm,XA,BP,nfit,fitUT,ifitBP)
             
c
c feed back the fit to the ppass
c
              
              ppass(ant,k,j) = complex(rfitBP,ifitBP)
         if(j.eq.2) ppass(ant,k,1)=(ppass(ant,k,1)+ppass(ant,k,2))/2.
              end do
              end do
              end do
              end


c************************************************************************
        subroutine t2ptbpass(nterm,nants,nchan,ntime,nfeeds,
     *                       ppass,tpass,bptime,ut)
           include 'maxdim.h'
         integer maxnBpass
         parameter(maxnBpass=20)
         complex tpass(maxant,maxchan,2,maxnBpass)
         integer nterm,nants,nchan,nfeeds
         complex ppass(maxant,maxchan,2)
         real bptime(maxnBpass),ut
c
c linear interpolation/extrapolattion from the nearest 2pnts
c
c    input:
c       nterm  - order of polynomial + 1
c       tpass  - input time dependent bpass
c       ntime  - number of time intervals in tpass
c       nchan  - number of channels in tpass
c       nfeed  - number of feeds in tpass
c       bptime - the UT time for the time interval in tpass
c       ut     - at the UT time to get bpass fit
c    output:
c       ppass  - a fitted bandpass
         double precision T(ntime)
         integer i,j,k,ant
         real dy,y0,fitUT, rfitBP, ifitBP
         real dt,t0
         integer ipntr
c        initialize the ppass array
             do ant=1, maxant
             do   k=1, maxchan
             do   j=1,nfeeds
             ppass(ant,k,j) =complex(1.0,0.0)
             enddo
             enddo
             enddo  
c        load the time to T and convert to min from day
              fitUT = UT*24.*60.
c
c determine the interpolate interval
c
            ipntr=0
c
c for UT between two bpass time
c              
              do i=1, ntime
              T(i) = bptime(i)*24.*60.
              enddo
              do i=1, ntime-1
              if(fitUT.ge.(T(i)).and.(fitUT.lt.T(i+1))) then
              ipntr=i     
              end if           
              end do
c
c for UT less than any bpass time
c
              if(fitUT.lt.T(1)) then
               ipntr=1
              endif
              if(fitUT.ge.T(ntime)) then
               ipntr=ntime-1
              endif
              
c
c determine dt
c
              dt = T(ipntr+1)-T(ipntr)
              t0 = T(ipntr)
              do ant=1,nants
              do k=1, nchan
              do j=1, nfeeds
c
c do real dy y0
c
              y0 = real(tpass(ant,k,j,ipntr))
              dy = real(tpass(ant,k,j,ipntr+1))
     *            -real(tpass(ant,k,j,ipntr))
              if(dt.eq.0) call bug('f', 'bpass time degenerates.')
               rfitBP = dy/dt * (fitUT-t0) + y0

              
c
c do imaginary dy y0
c
              y0 = aimag(tpass(ant,k,j,ipntr))
              dy = aimag(tpass(ant,k,j,ipntr+1))
     *            -aimag(tpass(ant,k,j,ipntr))
             
              ifitBP = dy/dt * (fitUT-t0) + y0
c
c feed back the fit to the ppass
c
              ppass(ant,k,j) = complex(rfitBP,ifitBP)
        if(j.eq.2) ppass(ant,k,1)=(ppass(ant,k,1)+ppass(ant,k,2))/2.
              end do
              end do
              end do
           end

c************************************************************************
        subroutine bload(tin,freq,gains,nfeeds,nants,nchan,sels,
     *    maxpass,maxfreq,nschann,nspect)
c
        integer tin,nants,nchan,maxpass,maxfreq,nfeeds,nspectt
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
        include 'maxdim.h'
        integer maxTimes,maxGains
        parameter(maxTimes=2*MAXCHAN*MAXANT)
        parameter(maxGains=2*MAXCHAN*MAXANT)
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
                 nspectt=nspect
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
c    T0         Base time, as a Julian date.
c    time       Offset Julian date.
c    G          The antenna gains.
c    nfeeds     Number of feeds (1 or 2).
c    ntau       Number of delay/spec corr terms (0 or 1).
c    nants      Number of antennas.
c    nsols      Number of solution intervals.
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
        subroutine GetOpt(uvflags,ampsc,vecamp,relax,
     *  dopolfit,docross)
c
        implicit none
        logical ampsc,vecamp,relax,dopolfit,docross
        character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags    Flags to pass to the uvdat routines.
c    ampsc      True for amp-scalar averaging
c    vecamp     True for vector averaging on everything except
c               parallel-hand amplitudes.
c    relax      Do not discard bad records.
c    dopolfit   Do polynomial fit
c    docross    Apply bandpass to cross-hand visibilities.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=9)
        character opts(nopts)*9
        integer l
        logical present(nopts),docal,dopol,dopass,vector
        data opts/'nocal    ','nopol    ','nopass   ',
     *            'vector   ','scalar   ','scavec   ',
     *            'relax    ','opolyfit ','cross    '/
c
        call options('options',opts,present,nopts)
        docal = .not.present(1)
        dopol = .not.present(2)
        dopass= .not.present(3)
        vector = present(4)
        ampsc  = present(5)
        vecamp = present(6)
        relax  = present(7)
        dopolfit = present(8)
        docross = present(9)
c
c Default averaging is vector
c
        if (vector .and. ampsc) call bug ('f',
     *     'You can''t have options=vector and options=scalar')
        if (vector .and. vecamp) call bug ('f',
     *     'You can''t have options=vector and options=scavec')
        if (ampsc .and. vecamp) call bug ('f',
     *     'You can''t have options=scalar and options=scavec')
c
c Set up calibration flags
c
        uvflags = 'dslr3'
        l = 5
        if(docal)then
          l = l + 1
          uvflags(l:l) = 'c'
        endif
        dopass=.false.
        if(dopass)then
          l = l + 1
          uvflags(l:l) = 'f'
        endif
        dopol=.false.
        if(dopol)then
          l = l + 1
          uvflags(l:l) = 'e'
        endif
        write(*,*) 'opt-uvflag=', uvflags
        end

c************************************************************************
	subroutine BufIni
	implicit none
c
c  Initialise the routines which do the buffering and averaging of
c  the visibility data.
c  All the buffering/averaging is performed in arrays stored in a
c  common block.
c
c------------------------------------------------------------------------
	include 'smatbpass.h'
	free = 1
	mbase = 0
	end
c************************************************************************
	subroutine BufFlush(tOut,ampsc,vecamp,npol)
c
	implicit none
	integer tOut,npol
        logical ampsc,vecamp
c
c  This writes out the averaged data. The accumulated data is in common.
c  This starts by dividing the accumulated data by "N", and then writes
c  it out.
c
c  Inputs:
c    tOut	The handle of the output file.
c    ampsc      True for amp scalar averaging
c    vecamp	True for amp scalar averaging of only parallel hand
c		amplitudes.
c  Output:
c    npol	The number of polarisations in the output. If this
c		varies, a zero is returned.
c------------------------------------------------------------------------
	include 'smatbpass.h'
	complex data(MAXCHAN)
        real amp,inttime
	double precision preambl(5),time(MAXBASE)
	logical flags(MAXCHAN)
	integer i,j,jd,k,ngood,nbp,p,idx1(MAXBASE),idx2(MAXBASE)
	logical PolVary,doamp
c
c  Externals.
c
	logical PolsPara
c
c  Determine the number of good baselines, and sort them so we have an
c  index of increasing time.
c
	ngood = 0
	do j=1,mbase
	  if(cnt(j).gt.0)then
	    ngood = ngood + 1
	    time(ngood) = preamble(4,j) / cnt(j)
	    idx2(ngood) = j
	  endif
	enddo
	if(ngood.le.0)return
	call sortidxd(ngood,time,idx1)
c
c  Now loop through the good baselines, writing them out.
c
	nbp = 0
	npol = 0
        PolVary = .true.
	do jd=1,ngood
	  j = idx2(idx1(jd))
	  if(npols(j).ne.npol)then
	    call uvputvri(tOut,'npol',npols(j),1)
	    PolVary = npol.gt.0
	    npol = npols(j)
	  endif
	  preambl(1) = preamble(1,j) / cnt(j)
	  preambl(2) = preamble(2,j) / cnt(j)
	  preambl(3) = preamble(3,j) / cnt(j)
	  preambl(4) = preamble(4,j) / cnt(j)
	  preambl(5) = preamble(5,j) / cnt(j)
	  inttime    = preamble(6,j) / npols(j)
	  call uvputvrr(tOut,'inttime',inttime,1)
c
c  Average the data in each polarisation. If there is only one scan in the
c  average, not bother to average it.
c
	  do i=1,npol
	    p = pnt(i,j) - 1
	    call uvputvri(tOut,'pol',pols(i,j),1)
	    doamp = ampsc.or.(vecamp.and.PolsPara(pols(i,j)))
	    nbp = nbp + 1
c
c  Loop over the channels. If we are doing amp-scalar averaging, and
c  the average visibility is zero, flag the data. Otherwise just
c  depend on whether we have good data or not.
c
	    do k=1,nchan(i,j)
	      if(doamp.and.
     *		abs(real(buf(k+p)))+abs(aimag(buf(k+p))).eq.0)
     *		count(k+p) = 0
	      flags(k) = count(k+p).gt.0
	      if(.not.flags(k))then
		data(k) = 0
	      else if(doamp)then
                amp = abs(buf(k+p))
		data(k) = (bufr(k+p) / count(k+p)) *  
     *                          (buf(k+p) / amp)
	      else
		data(k) = buf(k+p) / count(k+p)
              endif
	    enddo
 	    call uvwrite(tOut,preambl,data,flags,nchan(i,j))
	  enddo
	enddo
c
c  Reset the counters.
c
	free = 1
	mbase = 0

c  If the number of polarisations varied, zero npol.
c
	if(PolVary) npol = 0
	end
c************************************************************************
	subroutine BufAcc(preambl,inttime,data,flags,nread)
c
	implicit none
	integer nread
	double precision preambl(5)
	real inttime
	complex data(nread)
	logical flags(nread)
c
c  This accumulates the visibility data. The accumulated data is left
c  in common.
c
c  Input/Output:
c    preambl	Preamble. Destroyed on output.
c    data	The correlation data to be averaged. Destroyed on output.
c    flags	The data flags.
c    nread	The number of channels.
c------------------------------------------------------------------------
	include 'smatbpass.h'
	integer i,i1,i2,p,bl,pol
c
c  Determine the baseline number, and conjugate the data if necessary.
c
	call BasAnt(preambl(5),i1,i2)
	bl = ((i2-1)*i2)/2 + i1
	if(bl.gt.MAXBASE)
     *	  call bug('f','Too many baselines for me to handle, in BUFACC')
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
	  cnt(bl) = inttime
	  npols(bl) = 0
	  preamble(1,bl) = inttime * preambl(1)
	  preamble(2,bl) = inttime * preambl(2)
	  preamble(3,bl) = inttime * preambl(3)
	  preamble(4,bl) = inttime * preambl(4)
	  preamble(5,bl) = inttime * preambl(5)
	  preamble(6,bl) = inttime
	else
	  cnt(bl) = cnt(bl) + inttime
	  preamble(1,bl) = preamble(1,bl) + inttime * preambl(1)
	  preamble(2,bl) = preamble(2,bl) + inttime * preambl(2)
	  preamble(3,bl) = preamble(3,bl) + inttime * preambl(3)
	  preamble(4,bl) = preamble(4,bl) + inttime * preambl(4)
	  preamble(5,bl) = preamble(5,bl) + inttime * preambl(5)
	  preamble(6,bl) = preamble(6,bl) + inttime
	endif
c
c  Determine the polarisation.
c
	call uvDatGti('pol',pol)
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
	  if(p.gt.MAXPOL) call bug('f',
     *	    'Too many polarizations, in BufAcc')
	  pols(p,bl) = pol
	  nchan(p,bl) = nread
	  pnt(p,bl) = free
	  free = free + nread
	  if(free.gt.MAXAVER)call bug('f',
     *	    'Too much data to accumulate, in BufAcc')
c
c  Copy across the new data.
c
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = inttime * data(i)
              bufr(i+p) = inttime * abs(data(i))
	      count(i+p) = inttime
	    else
	      buf(i+p) = (0.0,0.0)
              bufr(i+p) = 0.0
	      count(i+p) = 0
	    endif
	  enddo
c
c  Else accumulate new data for old baseline.
c
	else
	  nread = min(nread,nchan(p,bl))
	  nchan(p,bl) = nread
	  p = pnt(p,bl) - 1
	  do i=1,nread
	    if(flags(i))then
	      buf(i+p) = buf(i+p) + inttime * data(i)
              bufr(i+p) = bufr(i+p) + inttime * abs(data(i))
	      count(i+p) = count(i+p) + inttime
	    endif
	  enddo
	endif
c
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

