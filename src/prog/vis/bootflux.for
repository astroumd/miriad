c************************************************************************
	program bootflux
c
	implicit none
c
c= BootFlux -- Determine secondary source fluxes from visibilities.
c& lgm
c: uv-analysis
c+
c   BootFlux is a MIRIAD task which can be used to determine the fluxes
c   of secondary standards from primary standards. Both vector and scalar 
c   averages are formed. It also prints out the rms scatter around the 
c   vector mean, and the RMS variation in the amplitude.
c
c@ vis
c   The name of the input visibility datasets. You MUST include the datasets
c   for the sources that you want to derive fluxes for as well as the
c   dataset for the primary calibrator. Several files can be given, 
c   wildcarding is supported. No default.
c@ select
c   Standard uv selection. The default is all data.
c@ line
c   Standard line-type specification. When there are multiple channels
c   selected, uvflux averages them all together. At this time, the program
c   can ONLY handle ONE CHANNEL at a time so you should specify 
c   line=wide,1,1,1,1 or line=wide,1,2,1,1
c@ stokes
c   Normal Stokes processing. You can select several Stokes or
c   polarisation parameters, which will be be averaged independently.
c@ taver
c   Averaging time in minutes. Data will be vector averaged until 
c   this amount of integration time has been accumulated or this amount
c   of wall-clock time has elapsed, which ever comes first.
c   Default: 5 minute averaging.
c@primary
c   Source name of primary flux standard, flux (or Tb for planets) of source
c   (optional). The source name MUST be the source name in the dataset,
c   NOT the name of the dataset.
c   Default: Source name MUST be specified, flux or Tb is optional.
c@badres
c   Used to drop baselines on which planet flux is resolved out. Input value
c   represents the minimum percentage planet visibility in baselines to be 
c   included in the calibration calculation.
c   Default = 30.  
c@record
c   Logical to indicate if results should be saved to archive flux files 
c   and name of archive directory (if different from default)
c   default: false -- do not archive measured fluxes
c   default directory: ./measured_fluxes
c@ options
c   Extra processing options. Several can be given, separated by
c   commas. Minimum match is used. Possible values are:
c         nocal    Do not apply any antenna gain calibration corrections.
c                  By default these are applied if they exist.
c         nopol    Do not apply polarisation leakage corrections. By default
c                  these are applied if they exist.
c         nopass   Do not apply bandpass corrections. By default these
c                  are applied if they exist.
c@ log
c   Log file name for output. 
c   Default: No Log file.
c
c--
c  History:
c    lgm 20mar94 Started with 05-nov-93 version of uvflux. Thanks BobS
c    lgm 08apr94 Still creating and expanding capability of prog
c    lgm 17apr94 beta test version release upon MD folks
c    lgm 28may94 code now checks for baselines with low visibility, fixed
c                   bugs relevant if only one data point in sample and if
c                   no valid data points on any baseline within an interval.
c    lgm 20oct95 Only looks for flux of primary source if it is not specified
c                   on input line. Changed name from NuFlux to BootFlux and 
c                   reset to version 1.0.
c    pjt 11feb97 Fixed formatting bug 
c    dar 17oct97 Changed calls to imax0 and imin0 to generic max0 and min0
c                   for compatability with SGI 64-bit compiler.
c    pjt 20jun98 fixed 0 -> .FALSE. for flags(i) assignment
c  Bugs:
c   Polarization mode not tested.
c------------------------------------------------------------------------
      include 'maxdim.h'
      include 'mirconst.h'
      integer MAXPOL,MAXSRC,PolMin,PolMax
      character version*(*),defdir*(*)
      parameter(MAXPOL=4,MAXSRC=256,PolMin=-9,PolMax=4)
      parameter(version='BootFlux: version 1.0 20-jun-98')
      parameter(defdir=
c     *         '/home/bima2/data/flux/measured_fluxes/')
c     *          '/lma/mirth/programmers/lgm/measured_fluxes/')
     *          './' )
c
      character uvflags*16,polcode*2,line*132
      logical docal,dopol,dopass,found,valid(MAXSRC)
      character sources(MAXSRC)*16,source*16
      complex flux(MAXPOL,MAXBASE,MAXSRC)
      real amp(MAXPOL,MAXBASE,MAXSRC),amp2(MAXPOL,MAXBASE,MAXSRC)
      complex vecaver,newvec(MAXBASE)
      real vecscat(MAXPOL,MAXBASE,MAXSRC),scalscat(MAXBASE),temp
      real vecamp(MAXBASE)
      real vecpha(MAXBASE),scalamp,scalsig,vamp,vsig
      integer i,j,ii,jj,t
      integer ncnt(MAXPOL,MAXBASE,MAXSRC)
      integer PolIndx(PolMin:PolMax),p(MAXPOL),pp(MAXPOL)
      integer nsrc,npol,isrc,ipol,vsource,tno
c
      integer nchan
      double precision preamble(4),skyfreq(MAXCHAN)
      real antel(MAXSRC)
      complex data(MAXCHAN)
      logical flags(MAXCHAN)
c
      integer base,bases(MAXBASE),ibl,nbase,ant1,ant2,bigant
      integer blmatrx(MAXANT,MAXANT),ncal,calscan(MAXSRC),iclose
      integer nsamp,fno,iostat,nants,nspec,nsys
      real dtime,temp1,temp2,temp3,scalamp2,pltb,factor,sumw,weight
      real tave,sigr,sigi,newflux(MAXBASE),sigflux(MAXBASE)
      real rflux2(MAXPOL,MAXBASE,MAXSRC)
      real iflux2(MAXPOL,MAXBASE,MAXSRC)
      real systemps(MAXANT*16),antsys(MAXSRC,MAXANT),sum
      real obsfreq(MAXSRC),tsys(MAXSRC),reslim
      real tint,inttime(MAXBASE,MAXSRC),wallclk,visib,plflux,freq
      real sumdy2,sformal,finscal(MAXSRC),finssig(MAXSRC)
      real finvec(MAXSRC),finvsig(MAXSRC),decobs,haobs
      double precision starttm(MAXSRC),startut(MAXSRC),thisbas
      double precision startjd(MAXSRC),dlst,draobs,ddecobs
      character calsou*16,ctime*18,caltime*18,filename*80
      character savedir*80,logfile*80
      logical newtime,save,more
c
c  Externals.
c
      integer findbase,min0,max0
      logical uvDatOpn,uvVarUpd
      character PolsC2P*2
c
c  Get the user parameters.
c
      call output(version)
      call keyini
      call GetOpt(docal,dopol,dopass)
c
c Determine uvDat parameters fags.
c s: stokes processing, d: data selection, l: linetype
c
      uvflags = 'sdl'
3     if(docal)  uvflags(5:5) = 'c'
      if(dopol)  uvflags(6:6) = 'e'
      if(dopass) uvflags(7:7) = 'f'
      call uvDatInp('vis',uvflags)
c
      call keyr('taver',tave,5.)
      tave = 60.0*tave
      call keya('primary',calsou,' ')
      call keyr('primary',pltb,-1.0)
      call ucase(calsou)
      call keyr('badres',reslim,30.)
      reslim = reslim/100.
c
      call keyl('record',save,.false.)
      call keya('record',savedir,defdir)
      call keya('log',logfile,' ')
      call LogOpen(logfile,' ')
c
      call keyfin
c
c  Initialise various things.
c
      isrc       = 0
      nsrc       = 0
      npol       = 0
      nbase      = 0
      bigant     = 0
      sources(1) = '      '
      starttm(1) = -100.0
      do i=1,MAXANT
      do j=1,MAXANT
        blmatrx(i,j) = 0
      enddo
      enddo
      do ibl=1,MAXBASE
        inttime(ibl,1)= 0.
      enddo
      do i=PolMin,PolMax
        PolIndx(i) = 0
      enddo
      call logwrite(' ',more)
      if(logfile .ne. ' ') call logwrite(version,more)
      if(logfile .ne. ' ') call logwrite(' ',more)
      call logwrite('------------------------------------------'//
     *         '-------------------------------------',more)

c
c  Loop the loop until we have no more files.
c
      dowhile(uvDatOpn(tno))
        call uvVarIni(tno,vsource)
        call uvVarSet(vsource,'source')
        call uvDatRd(preamble,data,flags,MAXCHAN,nchan)

        dowhile(nchan.gt.0)
c
c  Determine the polarisation.
c
         call uvDatGti('pol',ipol)
         if(PolIndx(ipol).eq.0)then
           npol = npol + 1
           if(npol.gt.MAXPOL)
     *	          call bug('f','Too many polarisations')
           PolIndx(ipol) = npol
         endif
         ipol = PolIndx(ipol)
c
c  Determine the source number. Has the source variable changed.
c  If so, check whether this was a real change. If it was, search
c  the list of known sources for it. If the requested integration time
c  is exceeded, set "found" back to false so another sample will be started.
c
         if(uvVarUpd(vsource))then
           call uvrdvra(tno,'source',source,' ')
           found = .false.
           if(isrc.gt.0)found = source.eq.sources(isrc)
           if(.not.found)then
             isrc = 0
             dowhile(.not.found.and.isrc.lt.nsrc)
               isrc = isrc + 1
               found = sources(isrc).eq.source
               if(inttime(ibl,isrc) .ge. tave) found = .false.
               wallclk = preamble(3) - starttm(isrc)
               if(wallclk .gt. tave) found = .false.
             enddo
           endif
         endif
c
c  Determine if a new sample needs to be started based on time
c
         if(found) then
           newtime = .false.
           if(inttime(ibl,isrc) .ge. tave) newtime = .true.
           wallclk = 86400.*(preamble(3) - starttm(isrc))
           if(wallclk .gt. tave) newtime = .true.
         endif
c
c  Initialize a new slot for integration
c
         if(.not.found .or. newtime)then
     	    nsrc = nsrc + 1
     	    if(nsrc.gt.MAXSRC)
     *                  call bug('f','Too many sources')
     	    sources(nsrc) = source
     	    do i=1,MAXPOL
            do ibl=1,MAXBASE
              flux(i,ibl,nsrc)   = 0
              rflux2(i,ibl,nsrc) = 0
              iflux2(i,ibl,nsrc) = 0
              amp(i,ibl,nsrc)    = 0
              amp2(i,ibl,nsrc)   = 0
              ncnt(i,ibl,nsrc)   = 0
            enddo
            enddo
            do ibl=1,MAXBASE
              inttime(ibl,nsrc) = 0
            enddo
            call uvgetvrd(tno,'ut',startut(nsrc),1)
            call uvgetvrd(tno,'time',startjd(nsrc),1)
            call uvgetvrd(tno,'obsra',draobs,1)
            call uvgetvrd(tno,'lst',dlst,1)
            call uvgetvrd(tno,'obsdec',ddecobs,1)
            decobs = ddecobs
            haobs = dlst - draobs
            call CalElev(haobs,decobs,antel(nsrc))
            antel(nsrc) = 180.0 * antel(nsrc)/3.1415926
            call uvgetvri(tno,'nants',nants,1)
            call uvgetvri(tno,'nspect',nspec,1)
            if(nspec .ne. 0) then
              call uvgetvrr(tno,'systemp',systemps,nants*nspec)
            else
              call uvrdvri(tno,'nwide',nspec,1)
              if(nspec .ne. 0)
     *             call uvgetvrr(tno,'wsystemp',systemps,nants*nspec)
            endif
            do i=1,nants
              sum = 0.0
              do j=1,nspec
                sum = sum + systemps(i + (j-1)*nants)
              enddo
              antsys(nsrc,i) = sum/nspec
            enddo
            starttm(nsrc) = preamble(3)
            isrc = nsrc
            found = .true.
            call uvinfo(tno,'sfreq',skyfreq)
            obsfreq(nsrc) = skyfreq(1)
         endif
c
c  Get frequency info so you can do the resolution corrections for planets.
c
         call uvinfo(tno,'sfreq',skyfreq)
c
c   If this is your calibrator store away the flux
c
         if(calsou .eq. sources(isrc)) then
            freq = skyfreq(1)
            ibl = preamble(4)
            call PlanVis(tno,freq,pltb,visib,plflux,.true.)
         endif
c
c  Accumulate the data. Drop data where the fractional visibility is
c     is less then "reslim" input by user.
c
         base = preamble(4)
         ibl  = findbase(base,bases,nbase)
         if(ibl .eq. 0) then
           nbase      = nbase + 1
           ibl        = nbase
           bases(ibl) = base
         endif
         do i=1,nchan
           freq = skyfreq(i)
           call PlanVis(tno,freq,pltb,visib,temp,.false.)
           if(visib .lt. reslim) flags(i) = .FALSE.
           if(flags(i))then
             flux(ipol,ibl,isrc)   = flux(ipol,ibl,isrc) + data(i)/
     *                               visib
             rflux2(ipol,ibl,isrc) = real(data(i))*real(data(i))/
     *                               (visib*visib) +
     *                               rflux2(ipol,ibl,isrc)
             iflux2(ipol,ibl,isrc) = aimag(data(i))*aimag(data(i))/
     *                               (visib*visib) +
     *                               iflux2(ipol,ibl,isrc)
             temp                  = abs(data(i)/visib)
             amp(ipol,ibl,isrc)    = amp(ipol,ibl,isrc) + temp
             amp2(ipol,ibl,isrc)   = amp2(ipol,ibl,isrc) + temp*temp
             ncnt(ipol,ibl,isrc)   = ncnt(ipol,ibl,isrc) + 1
             call uvgetvrr(tno,'inttime',tint,1)
             inttime(ibl,isrc)    = inttime(ibl,isrc) + tint
           endif
         enddo
c
c  Loop the loop.
c
          call uvDatRd(preamble,data,flags,MAXCHAN,nchan)
        enddo
c
c  Finished reading a dataset. Close it and see if there are more to read
c
        call uvDatCls
      enddo
c
c  Finished reading all datasets
c
c  Determine the order that we will print the polarisations out in.
c
      npol = 0
      do j=PolMin,PolMax
        if(PolIndx(j).gt.0)then
          npol = npol + 1
          p(npol) = j
          pp(npol) = PolIndx(j)
          do i=npol,2,-1
            if(abs(p(i)).lt.abs(p(i-1)))then
              t = p(i)
              p(i) = p(i-1)
              p(i-1) = t
              t = pp(i)
              pp(i) = pp(i-1)
              pp(i-1) = t
            endif
          enddo
        endif
      enddo
c  Now check for time intervals with no good data
c
      do isrc=1,nsrc
         valid(isrc) = .false.
         do ipol=1,npol
         do ibl=1,nbase
            if(ncnt(ipol,ibl,isrc).gt.0) valid(isrc)=.true.
         enddo
         enddo
      enddo
c
c  Print out the results.
c
      do isrc=1,nsrc
       if(valid(isrc)) then
        source = sources(isrc)
        call julday(startjd(isrc),'H',ctime)
        do ii=1,npol
          ipol = pp(ii)
          PolCode = PolsC2P(p(ii))
          write(line,'(''Results for Source: '',a)')
     *              source
c          call logwrite(line,more)
          write(line,'(5x,''UT Start Time: '',a16,4x,''Polarization: '',
     *              a)') ctime,polcode
c          call logwrite(line,more)
          write(line,'(5x,''No. samples:    '',i4,15x,''Integ. Time : ''
     *              ,f5.1)') ncnt(1,1,isrc),inttime(1,isrc)
c          call logwrite(line,more)
          write(line,'(5x,''Frequency:    '',f8.4,'' GHz'',
     *              ''         Elev:        '',f5.1)')
     *              skyfreq(1),antel(isrc)
c          call logwrite(line,more)
c          call logwrite(' ',more)
          write(line,'(7x,''Matrix of Amplitudes in 10000*Kelvins'')')
c          call logwrite(line,more)
c
c   calculate sigma of observations if more than 1 data point. If only 1,
c      set sigma to 10 percent of amplitude
c
          do ibl=1,nbase
            thisbas = bases(ibl)
            call basant(thisbas,ant1,ant2)
            bigant = max0(bigant,ant2)
            if(ncnt(ipol,ibl,isrc).gt.0) then
              vecaver = flux(ipol,ibl,isrc) / ncnt(ipol,ibl,isrc)
              call amphase(vecaver,vecamp(ibl),vecpha(ibl))
              if(ncnt(ipol,ibl,isrc).gt.1) then
                 sigr    = (rflux2(ipol,ibl,isrc)-ncnt(ipol,ibl,isrc)*
     *                    real(vecaver)*real(vecaver))/
     *                    (ncnt(ipol,ibl,isrc)-1)
                 sigi    = (iflux2(ipol,ibl,isrc)-ncnt(ipol,ibl,isrc)*
     *                    aimag(vecaver)*aimag(vecaver))/
     *                    (ncnt(ipol,ibl,isrc)-1)
                 temp    = (real(vecaver)*real(vecaver)/(vecamp(ibl)*
     *                    vecamp(ibl)))*sigr
     *               +(aimag(vecaver)*aimag(vecaver)/(vecamp(ibl)*
     *                    vecamp(ibl)))*sigi
                 vecscat(ipol,ibl,isrc) = 
     *                sqrt(abs(temp)/ncnt(ipol,ibl,isrc))
              else
                 vecscat(ipol,ibl,isrc) = 0.1 * vecamp(ibl)
              endif
              temp         = amp2(ipol,ibl,isrc) / ncnt(ipol,ibl,isrc)
     *			 - (amp(ipol,ibl,isrc) / ncnt(ipol,ibl,isrc))**2
              scalscat(ibl)= sqrt(abs(temp))
              blmatrx(ant1,ant2) = ibl
            endif
          enddo
c          write(line,'('' ANTS '',12(1x,i3,3x))') (i,i=1,bigant)
c          call logwrite(line,more)
          do i=1,bigant
            write(line(1:5),'(i3,''  '')') i
            do j=1,bigant
              jj = (j-1)*7 + 6
              if(blmatrx(i,j) .gt. 0) then
                write(line(jj:jj+7),'(i6,'' '')') 
     *                       nint(vecamp(blmatrx(i,j))*10000.)
              else
                write(line(jj:jj+7),'(''       '')')
              endif
            enddo
c            call logwrite(line,more)
            do j=1,bigant
              jj = (j-1)*7 + 6
              if(blmatrx(i,j) .gt. 0) then
                write(line(jj:jj+7),'('' ('',i4,'')'')') 
     *                   nint(vecscat(ipol,blmatrx(i,j),isrc)*10000.)
              else
                write(line(jj:jj+7),'(''       '')')
              endif
            enddo
c            call logwrite(line,more)
          enddo
c         call logwrite('------------------------------------------'//
c     *		'-------------------------------------',more)
c
        enddo
       endif
      enddo
c
c  End of raw data analysis and print-out. Now proceed to estimate flux
c  for sources based on calibrator flux
c
c  Find calibration source location in source array
c
      ncal = 0
      do isrc=1,nsrc
        if(sources(isrc) .eq. calsou .and. valid(isrc)) then
           ncal = ncal + 1
           calscan(ncal) = isrc
        endif
      enddo
      if(ncal .eq. 0) then
        call logwrite(' Calibration source not found',more)
        call bug('f','Absolute flux calibration not possible')
      endif
c
c  Loop over each source to calculate flux and statistics
c
      do isrc = 1,nsrc
       if(valid(isrc)) then
c
c  Identify which cal scan is closest to each source scan
c
        temp = 10.
        do i=1,ncal
          dtime = abs(startut(isrc) - startut(calscan(i)))
          if(dtime .lt. temp) then
             temp = dtime
             iclose = i
          endif
        enddo
        source = sources(isrc)
        call julday(startjd(isrc),'H',ctime)
        call julday(startjd(calscan(iclose)),'H',caltime)
c
c   loop on polarizations and baselines calculating fluxes and sigmas
c
        do ii=1,npol
          ipol = pp(ii)
          PolCode = PolsC2P(p(ii))
          write(line,'(''Results for Source: '',a)')
     *              source
          call logwrite(line,more)
          write(line,'(5x,''UT Start Time: '',a16,4x,''Polarization: '',
     *              a)') ctime,polcode
          call logwrite(line,more)
          write(line,'(5x,''No. samples:    '',i4,15x,''Integ Time : ''
     *              ,f5.1)') ncnt(1,1,isrc),inttime(1,isrc)
          call logwrite(line,more)
          write(line,'(5x,''Frequency:    '',f8.4,'' GHz'',
     *              ''         Elev:        '',f5.1)')
     *              skyfreq(1),antel(isrc)
          call logwrite(line,more)
          write(line,'(5x,''Calib Source:  '',a,4x,''UT Time:'',5x,a)')
     *              sources(calscan(iclose)),caltime
          call logwrite(line,more)
          write(line,'(5x,''Calib Flux: '',f7.2,'' Jy'')') plflux
          call logwrite(line,more)
          call logwrite('  ',more)
          do ibl = 1,nbase
            thisbas = bases(ibl)
            call basant(thisbas,ant1,ant2)
            if(ncnt(ipol,ibl,isrc) .gt. 0 .and. ncnt(ipol,ibl,
     *             calscan(iclose)) .gt. 0) then
              vecaver = flux(ipol,ibl,isrc)/ncnt(ipol,ibl,isrc)
              call amphase(vecaver,temp1,temp3)
              vecaver = flux(ipol,ibl,calscan(iclose))/
     *                    ncnt(ipol,ibl,calscan(iclose))
              call amphase(vecaver,temp2,temp3)
              newvec(ibl)  = plflux * (flux(ipol,ibl,isrc)/ncnt(ipol,
     *                    ibl,isrc))/(flux(ipol,ibl,calscan(iclose))/
     *                    ncnt(ipol,ibl,calscan(iclose)))
              newflux(ibl) = plflux * (temp1 / temp2)
              sigflux(ibl) = newflux(ibl)*newflux(ibl)*
     *                  ((vecscat(ipol,ibl,isrc)/temp1)**2 + 
     *                   (vecscat(ipol,ibl,calscan(iclose))/temp2)**2)
              sigflux(ibl) = sqrt(abs(sigflux(ibl)))
              blmatrx(ant1,ant2) = ibl
              if(calsou .eq. sources(isrc)) then
                 newflux(ibl) = plflux/temp1
                 sigflux(ibl) = newflux(ibl)*(vecscat(ipol,ibl,isrc)/
     *                          temp1)
              endif
            else
              blmatrx(ant1,ant2) = 0
              ncnt(ipol,ibl,isrc) = 0
            endif
          enddo
c
c  Write out flux and sigma results in a matrix format
c
          if(calsou .eq. sources(isrc)) then
            factor = 1.0
            write(line,'(15x,''Matrix of Gains and Errors (S.D.M.)'')')
            call logwrite(line,more)
            write(line,'(20x,''in units of Janskys / K'')')
            call logwrite(line,more)
          else
            factor = 1000.
            write(line,'(15x,''Matrix of Fluxes and Errors (S.D.M.)'')')
            call logwrite(line,more)
            write(line,'(20x,''in units of 1000*Janskys'')')
            call logwrite(line,more)
          endif
          write(line,'('' ANTS '',12(3x,i2,3x))') (i,i=1,bigant)
          call logwrite(line,more)
          do i=1,bigant
            write(line(1:5),'(i3,''  '')') i
            do j=1,bigant
              jj = (j-1)*8 + 6
              if(blmatrx(i,j) .gt. 0) then
                write(line(jj:jj+8),'(i7,'' '')')
     *                       nint(newflux(blmatrx(i,j))*factor)
              else
                write(line(jj:jj+8),'(''        '')')
              endif
            enddo
            call logwrite(line,more)
            do j=1,bigant
              jj = (j-1)*8 + 6
              if(blmatrx(i,j) .gt. 0) then
                write(line(jj:jj+8),'('' ('',i5,'')'')')
     *                   nint(sigflux(blmatrx(i,j))*factor)
              else
                write(line(jj:jj+8),'(''       '')')
              endif
            enddo
            call logwrite(line,more)
          enddo
          call logwrite(' ',more)
c
c  write out system temps -- and save average system for summary printout
c
          do j=1,bigant,4
            jj = min0(j+3,bigant)
            write(line,'('' System Temps: '',4(''Ant'',i2.2,'':'','//
     *                'i5,2x))') (i,nint(antsys(isrc,i)),i=j,jj)
            call logwrite(line,more)
          enddo
          call logwrite(' ',more)
          tsys(isrc) = 0.
          nsys = 0
          do j=1,bigant
            if(antsys(isrc,j) .le. 9000.) then
              tsys(isrc) = tsys(isrc) + antsys(isrc,j)
              nsys = nsys + 1
            endif
          enddo
          tsys(isrc) = tsys(isrc)/nsys
          write(line,'('' Average System Temperature: '',i6,'' K'')')
     *            nint(tsys(isrc))
          call logwrite(line,more)
c  
c  calculate scaler and vector averages over baselines
c
          sumw     = 0.
          nsamp    = 0
          scalamp  = 0.
          scalamp2 = 0.
          vecaver  = cmplx(0.,0.)
          do ibl=1,nbase
            if(ncnt(ipol,ibl,isrc) .gt. 0) then
              weight   = 1.0/(sigflux(ibl)*sigflux(ibl))
              scalamp  = scalamp + newflux(ibl)*weight
              scalamp2 = scalamp2 + newflux(ibl)*newflux(ibl)
     *                        *weight*weight
              vecaver  = vecaver + newvec(ibl)*weight
              nsamp    = nsamp + 1
              sumw     = sumw + weight
            endif
          enddo
          scalamp = scalamp/sumw
          vecaver = vecaver/sumw
          if(nsamp .gt. 1) then 
c            scalsig = (scalamp2 - (scalamp*scalamp/nsamp))/
c     *                 (nsamp-1)
c            scalsig = sqrt(abs(scalsig)/float(nsamp))
            sumdy2 = 0.0
            do ibl=1,nbase
              if(ncnt(ipol,ibl,isrc) .gt. 0) then
                weight = 1.0/(sigflux(ibl)*sigflux(ibl))
                sumdy2 = sumdy2 + weight*((newflux(ibl)-scalamp)**2)
              endif
            enddo
            scalsig = sqrt(nsamp*sumdy2/((nsamp-1)*sumw))/
     *                sqrt(1.0*nsamp)
            sformal = 1.0/sqrt(sumw)
          else
            scalsig = 0.0
          endif
          call amphase(vecaver,vamp,temp)
          vsig = 0.
          finscal(isrc) = scalamp
          finssig(isrc) = scalsig
          finvec(isrc)  = vamp
          finvsig(isrc) = vsig
          if(calsou .eq. sources(isrc)) then
            write(line,'('' Mean Gains = '',f7.1,'' +- '',f6.1,
     *                  '' Jy/K'')') scalamp,scalsig
            call logwrite(line,more)
          else
            write(line,'('' Baseline Scaler Weighted Average = '',
     *                  f8.3,'' (+- '',f6.3,'' S.D.M.)  Jy'')') 
     *                  scalamp,scalsig
            call logwrite(line,more)
            write(line,'(''            Formal weighted sigma = '',13x,
     *                  f6.3,''  Jy'')') sformal
            call logwrite(line,more)
            write(line,'('' Baseline Vector Weighted Average = '',
     *                  f8.3,'' (+- '',f6.3,'')  Jy'')') 
     *                  vamp,vsig
            call logwrite(line,more)
            write(line,'(''  WARNING: DO NOT use the vector average'',
     *                   '' with un-calibrated data'')')
            call logwrite(line,more)
          endif
          call logwrite('----------------------------------------'//
     *          '-------------------------------------',more)
        enddo
       endif
      enddo
c
c   Print out summary of results
c
      call logwrite(' ',more)
      if(logfile .ne. ' ') call output(' ')
      call logwrite('                 SUMMARY OF FLUX MEASUREMENTS',
     *                 more)
      if(logfile .ne. ' ')
     *  call output('                 SUMMARY OF FLUX MEASUREMENTS')
      write(line,'('' Source             UT       Freq(GHz)  Elev  '',
     *          ''Calib     Tsys    Flux   Error'')')
      call logwrite(line,more)
      if(logfile .ne. ' ') call output(line)
      call logwrite('----------------------------------------'//
     *          '-------------------------------------',more)
      if(logfile .ne. ' ')
     * call output('----------------------------------------'//
     *          '-------------------------------------')
      do isrc=1,nsrc
        if(sources(isrc) .ne. calsou .and. valid(isrc)) then
          call julday(startjd(isrc),'H',ctime)
          write(line,'(a12,1x,a16,1x,f7.3,2x,f5.1,2x,a8,1x,i5,1x,f8.3,
     *       1x,f6.3)') 
     *       sources(isrc),ctime,obsfreq(isrc),antel(isrc),calsou,
     *         nint(tsys(isrc)),finscal(isrc),finssig(isrc)
          call logwrite(line,more)
          if(logfile .ne. ' ') call  output(line)
        endif
      enddo 
c
      call logwrite(' ',more)
      if(logfile .ne. ' ') call output(line)
      call logwrite('    SUMMARY OF JY/K MEASUREMENTS FROM CALIBRATOR',
     *                 more)
      if(logfile .ne. ' ') 
     *  call output('    SUMMARY OF JY/K MEASUREMENTS FROM CALIBRATOR')
      write(line,'('' Source           UT           Elev    JY/K'',
     *          ''   Error'')')
      call logwrite(line,more)
      if(logfile .ne. ' ') call output(line)
      call logwrite('----------------------------------------'//
     *          '----------------------------------',more)
      if(logfile .ne. ' ') 
     * call output('----------------------------------------'//
     *          '----------------------------------')
      do isrc=1,nsrc
        if(sources(isrc) .eq. calsou .and. valid(isrc)) then
          call julday(startjd(isrc),'H',ctime)
          write(line,'(a12,1x,a16,1x,f5.1,1x,f8.3,1x,f6.3)')
     *       sources(isrc),ctime,antel(isrc),
     *         finscal(isrc),finssig(isrc)
          call logwrite(line,more)
          if(logfile .ne. ' ') call output(line)
        endif
      enddo
c
c  Append appropriate info to files for plotting in ascii format
c
c
      if(save) then
        do isrc=1,nsrc
          if(sources(isrc) .ne. calsou .and. valid(isrc)) then
            j = 0
            do i=1,16
              if(sources(isrc)(i:i) .ne. ' ') j = i
            enddo   
            do i=1,80
              if(savedir(i:i) .ne. ' ') jj = i
            enddo
            filename = savedir(1:jj)//sources(isrc)(1:j)//'.flux'
            call txtopen(fno,filename,'append',iostat)
            if(iostat.ne.0) call txtopen(fno,filename,'new',iostat)
            call julday(startjd(isrc),'H',ctime)
            write(line,'(a,1x,f13.4,1x,a16,1x,f7.3,1x,f5.1,1x,a8,1x,i6,
     *          1x,f8.3,1x,f6.3)') sources(isrc),startjd(isrc),ctime,
     *          obsfreq(isrc),antel(isrc),calsou,nint(tsys(isrc)),
     *          finscal(isrc),finssig(isrc) 
            call txtwrite(fno,line,110,iostat)
            call txtclose(fno)
          endif
        enddo
      endif
c
      call LogClose
      end
c************************************************************************
        subroutine GetOpt(docal,dopol,dopass)
c
        implicit none
        logical docal,dopol,dopass
c
c  Outputs:
c    docal      Apply calibration corrections.
c    dopol      Apply polarisation leakage corrections.
c    dopass     Apply bandpass corrections.
c------------------------------------------------------------------------
        integer NOPT
        parameter(NOPT=3)
        character opts(NOPT)*8
        logical present(NOPT)
        data opts/'nocal   ','nopol   ','nopass  '/
c
        call options('options',opts,present,NOPT)
        docal = .not.present(1)
        dopol = .not.present(2)
        dopass= .not.present(3)
        end
c************************************************************************
        Subroutine PlanVis(tvis,freq,pltb,visib,flux,calib)
c
        implicit none
        integer tvis
        real freq,pltb,visib,flux
        logical calib
c
c  Determines fractional visibility of a planet for the current visibility. 
c  This looks for variables in the visibility file which give the 
c  characteristics of the planet.
c
c  Input:
c    tvis       Handle of the visibility file.
c    freq       Observing frequency, in GHz.
c    pltb       Planet temperature or source flux input by user, if any
c    calib      logical to indicate if this is a calibrator
c  Output:
c    visib   The visibility of the planet for this baseline. Max = 1.0
c    flux    Total flux of planet or point source in Jy
c------------------------------------------------------------------------
        real pi,h,c,k
        parameter(pi=3.141592653589793,h=6.6252e-34,c=2.99792458e8)
        parameter(k=1.38045e-23)
        double precision coord(2)
        double precision day
c        real delday,rms,
        integer iostat
        real plmaj,plmin,plangle,u,v,cosi,sini,beta,omega
        character source*16
c
c  Externals.
c
        real j1xbyx
c
c  Get info from the visibility file.
c  Units returned by the uv routines.
c    u,v -- nanosec.
c    plmaj,plmin -- arcsec.
c    plangle -- degrees
c    pltb -- Kelvin
        call uvgetvrd(tvis,'coord',coord,2)
        u = coord(1)
        v = coord(2)
        call uvgetvrr(tvis,'plmaj',plmaj,1)
        call uvrdvrr(tvis,'plmin',plmin,plmaj)
        call uvrdvrr(tvis,'plangle',plangle,0.)
        call uvgetvra(tvis,'source',source)
c  
c  Calculate the visibility of plmaj is greater than 0.01
c
        if(plmaj .gt. 0.01) then
           if(pltb .le. 1.) 
     *          call uvgetvrr(tvis,'pltb',pltb,1)
c
c  Unit conversion.
c
           plangle = pi/180 * plangle
           plmaj = pi * plmaj / 180 / 3600
           plmin = pi * plmin / 180 / 3600
c
c  We have the characteristics of the source. Now compute the flux (in Jy).
c    plange -- radians.
c    plmaj,plmin -- radians.
c    pltb -- Kelvin.
c    u,v  -- nanosec.
c    freq -- GHz
c  The factor 1e26 converts between W/m**2/Hz to Janksy.
c
           cosi = cos(plangle)
           sini = sin(plangle)
           beta = pi * sqrt((plmaj*(u*cosi-v*sini))**2
     *                 + (plmin*(u*sini+v*cosi))**2)
           visib = 2.*j1xbyx(beta*freq)

        else
           visib = 1.0
        endif
        if(calib) then
          if(plmaj .gt. 1.0e-8) then
            omega = pi/4 * plmaj*plmin
            flux  = omega * 2*(h*1e26)/(c*c)*(freq**3*1e27)/
     *                ( exp(((h/k)*1e9)*freq/pltb) - 1. )
          else
            if(pltb .gt. 0.01) then
              flux = pltb
            else
              day = 0.0d0
              call calget(' ',source,freq,40.,day,200.,flux,iostat)
              if(iostat.lt.0) flux = 1.0
            endif
          endif
        endif
        end
c************************************************************************
       subroutine rad2hms(time,chartime)
c
c  Converts input time in radians to character hh:mm:ss representation
c
       double precision time,temp
       character chartime*(*)
       integer hours,mins,secs

       temp = 3.81971863d0 * time
       hours = int(temp)
       mins  = int((temp-hours)*60.)
       secs  = int((temp-hours)*3600. - mins*60.)
       write(chartime,'(i2,'':'',i2,'':'',i2)') hours,mins,secs
       return
       end 
c-----------------------------------------------------------------------
        subroutine CalElev(ha,decl,elev)
c
c    Calculates the source Elevation from the source hour angle (HA)
c    and declination (DECL) assuming the latitude of Hat Creek.
c    HA, DECL, and ELEV are all in radians.
c
        real ha,decl,elev,lat,dummy
c
c    Assuming Hat Creek Latitude = 40 deg
        parameter (lat = 0.6981)
c
        dummy = sin(decl)*sin(lat) +
     1          cos(decl)*cos(ha)*cos(lat)
        elev  = asin(dummy)
        return
        end
c
