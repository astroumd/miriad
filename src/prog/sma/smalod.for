c************************************************************************
        program smalod 
        implicit none
c
c= smalod - Convert an Sma archive data (Caltech MIR) into Miriad uv format
c& jhz 15-jul-04
c: data transfer
c+
c       SMALOD is a MIRIAD task, which converts a uv data-set from the MIR
c       format to Miriad format.
c
c@ in   Name of the input MIR files. Several names (not yet) can be given
c       -- wildcar expansion is supported. In this case, see the NFILES
c       keyword below. There is no default.
c
c@ out
c       Name of the output Miriad uv data-set. No default.
c
c@ rxif
c       selete from dual receivers/IFs; 
c       rxif=0 for receiver id = 0 -> 230 GHz band;
c       rxif=1 for receiver id = 1 -> 340 GHz band;
c       rxif=2 for receiver id = 2 -> 690 GHz band;
c       No default.
c
c@ restfreq
c       The rest frequency, in GHz, for line observations.  By default,
c       the value in the MIR file is used.
c       we are cosidering to support the following functions: Giving a
c       value for the "restfreq" parameter overrides the MIR file value.
c       If you do set this parameter, you MUST give the same number of
c       values as the number of IFs written out. A value of 0 is used
c       for a continuum observation. For example, if you have two IFs,
c       the first of which is CO(3-2), and the second is continuum, use
c       restfreq=345.795991,0
c
c@ options
c       'nopol'    Disable polarization. All the correlations will be
c                  labelled as XX.
c       'cirpol'   when circular polarization data taken with waveplates.
c                  Default is for linear polarization data taken with
c                  dual linear feeds.   
c       'oldpol'   Converts MIR polarization data observed before
c                  2004-9-1.
c                  Defaults assumes non-polarization state is assigned.
c       'dospc'    reverses the order of the spectral chunks in frequency
c                  only for the first three blocks (1 2 3).
c                  freuency code vs. spectral window orders:
c                   frcode iband 
c		       	 4 1
c			 3 2
c			 2 3
c			 1 4
c			 8 5
c			 7 6
c			 6 7
c		 	 5 8
c			12 9
c			11 10
c			10 11
c			 9 12
c			13 13
c			14 14
c			15 15
c			16 16
c			17 17
c			18 18
c			19 19
c 			20 20
c	  		21 21
c			22 22
c			23 23
c			24 24 
c       'doengrd'  to read the engineer file for Tsys and LST.
c
c       No extra processing options have been given yet. The default
c       works.
c
c@ rsnchan
c	This is an option for resampling SMA uvdata from higher
c	spectral resolution to lower spectral resolution or from
c	hybrid spectral resolutions across the 24 spectral windows
c       (chunks or IFs) to a uniform spectral resolution. 
c       The default or a negative is no resampling to be applied. 
c       Note that this number must be power of 2 and equal to/less 
c       than the smallest channel number in the 24 spectral windows.
c       If rsnchan is not equal to the nth power of 2, the program 
c       will take the a number of 2**n which is close to the input
c       value. If rsnchan is greater than the smallest channel  number,
c       the program will take the smallest channel number. 
c
c@ sideband
c       This is an option for separating sidebands. A value of 0 is for
c       lower sideband only, 1 for upper sideband and 2 for both.
c       The default is 0.
c
c@ nfiles
c       This gives one or two numbers, being the number of files to skip,
c       followed by the number of files to process (not yet). This is only
c       useful when the input is a tape device containing multiple files.
c       The default is 0,1 (i.e. skip none, process 1 file).
c
c@ nscans
c       This gives one or two numbers, being the number of scans to skip,
c       followed by the number of scans to process. NOTE: This applies to
c       all files read. The default is to skip none and process all scans.
c--
c  History:
c    jhz 15-jul-04 made the original version.
c    jhz 30-aug-04 add options "nopol" to disable the polarization
c    jhz 03-sep-04 add options "oldpol" to convert non-convetion
c                  SMA polariztion state labelling to the convetion
c                  that both NRAO and BIMA follow.
c    jhz 30-nov-04 implemented handling both sideband together
c    jhz  1-dec-04 implemented dual receivers
c    jhz  16-dec-04 added  checking the length of infile
c    jhz  11-jan-05 merged smauvrsample into smalod;
c    jhz  11-jan-05 added Key word rsnchan controls the resmapling vis 
c                   spectra output.  
c    jhz  28-feb-05 added option dospc
c    jhz  01-mar-05 added rx id label to the output file
c    jhz  02-mar-05 added option doengrd to read engineer data file
c------------------------------------------------------------------------
        integer maxfiles
        parameter(maxfiles=128)
        character version*(*)
        parameter(version='SmaLod: version 1.2 1-Mar-05')
c
        character in(maxfiles)*64,out*64,line*64, rxc*4
        integer tno, length, len1
        integer ifile,rxif,nfreq,iostat,nfiles,i
        double precision rfreq(2)
        logical doauto,docross,docomp,dosam,relax,unflag,dohann
        logical dobary,doif,birdie,dowt,dopmps,doxyp,doop
        logical polflag,hires,nopol,sing,cirpol,oldpol,dsb,dospc,doengrd
        integer fileskip,fileproc,scanskip,scanproc,sb, dosporder
        integer doeng
	integer rsNCHAN
c
c  Externals.
c
        character smaerr*32,itoaf*8
        dsb = .false.
c
c  Get the input parameters.
c
        call output(version)
        call keyini
        call mkeyf('in',in,maxfiles,nfiles)
        if(nfiles.eq.0)
     *    call bug('f','Input name must be given')
        call keya('out',out,' ')
        if(out.eq.' ')
     *    call bug('f','Output name must be given')
         call keyi('rxif',rxif,-2)
            if(rxif==0) rxc='_rx0'
            if(rxif==1) rxc='_rx1'
            if(rxif==2) rxc='_rx2'
c
        if(rxif==-2) then 
             write(*,*) 'rxif = 0 -> 230 band'
             write(*,*) 'rxif = 1 -> 340 band'
             write(*,*) 'rxif = 2 -> 690 band'
             call bug('f','No defualt for rxif!')
             end if
         if(rxif.lt.-1.or.rxif.gt.2) 
     *   call bug('f','Invalid Receiver ID.')

        call mkeyd('restfreq',rfreq,2,nfreq)
        call getopt(doauto,docross,docomp,dosam,doxyp,doop,relax,
     *    sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,polflag,
     *    hires,nopol,cirpol,oldpol,dospc,doengrd)
            dosporder=-1
            if(dospc) dosporder=1
            doeng =-1
            if(doengrd) doeng=1
        call keyi('rsnchan',rsnchan,-1)
       if(rsnchan.gt.0) then 
         rsnchan=2**(int(log(real(rsnchan))/log(2.)+0.5))
                        else
                        rsnchan=-1
                        end if
        call keyi('sideband',sb,0)
        if(sb.lt.0.or.sb.gt.2)
     *  call bug('f','Invalid SIDEBAND parameter')
        call keyi('nfiles',fileskip,0)
        call keyi('nfiles',fileproc,nfiles-fileskip)
        if(nfiles.gt.1.and.fileproc+fileskip.gt.nfiles)
     *    fileproc = nfiles - fileskip
        if(fileskip.lt.0.or.fileproc.lt.1)
     *  call bug('f','Invalid NFILES parameter')
        call keyi('nscans',scanskip,0)
        call keyi('nscans',scanproc,0)
        if(scanskip.lt.0.or.scanproc.lt.0)
     *  call bug('f','Invalid NSCANS parameter')
        call keyfin
c
c    do both side bands
c
           length=len1(out)
           if(sb.eq.2) then
              dsb=.true.
              sb = 0
              end if
555           if(rxif.eq.-1) then
              if(sb.eq.0) out=out(1:length)//'.lsb'
              if(sb.eq.1) out=out(1:length)//'.usb'
              else
              if(sb.eq.0) out=out(1:length)//rxc(1:4)//'.lsb'
              if(sb.eq.1) out=out(1:length)//rxc(1:4)//'.usb'
              end if

c
c  Open the output and initialise it.
c   
        call uvopen(tno,out,'new')
        if(.not.docomp)call uvset(tno,'corr','r',0,0.,0.,0.)
        call uvset(tno,'preamble','uvw/time/baseline',0,0.,0.,0.)
        call fixed(tno,dobary)
        call hisopen(tno,'write')
        call hiswrite(tno,'SMALOD: Miriad '//version)
        call hisinput(tno,'SMALOD')
        ifile = 0
        iostat = 0
        dowhile(ifile.lt.fileskip+fileproc.and.iostat.eq.0)
          ifile = ifile + 1
          if(ifile.le.fileskip)then
            if(nfiles.eq.1)then
              call output('Skipping file '//itoaf(ifile))
              call rpskip(in(1),iostat)
            else
              call output('Ignoring file '//in(ifile))
              iostat = 0
            endif
            if(iostat.ne.0)call bug('f','Error skipping SMAMIR file')
          else
            call pokeini(tno,dosam,doxyp,doop,dohann,birdie,dowt,
     *      dopmps,dobary,doif,hires,nopol,cirpol,oldpol,rsnchan)
            if(nfiles.eq.1)then
              i = 1
            else
              i = ifile
            endif
            if(i.ne.ifile)then
            call liner('Processing file '//itoaf(ifile))
            else
            call liner('Processing file '//in(ifile))
            endif
            call smadisp(in(i),scanskip,scanproc,doauto,docross,
     *          relax,sing,unflag,polflag,rxif,rfreq,nfreq,sb,
     *          iostat, dosporder,doeng)
          endif
        enddo
        if(iostat.ne.0)then
          line = 'SMAMIR i/o error: '//smaerr(iostat)
          call bug('w',line)
          call bug('w','Prematurely finishing because of errors')
          call hiswrite(tno,'SMALOD: '//line)
          call hiswrite(tno,
     *      'SMALOD: Prematurely finishing because of errors')
        endif
        call hisclose(tno)
        call uvclose(tno)
        if(.not.dsb) then
        if((sb.eq.0).and.(rxif.ne.-1)) write(*,*)
     * 'output file =',out(1:length)//rxc(1:4)//'.lsb'
        if((sb.eq.1).and.(rxif.ne.-1)) write(*,*)
     * 'output file =',out(1:length)//rxc(1:4)//'.usb'
        if((sb.eq.0).and.(rxif.eq.-1)) write(*,*)
     * 'output file =',out(1:length)//'.lsb'
        if((sb.eq.1).and.(rxif.eq.-1)) write(*,*)
     * 'output file =',out(1:length)//'.usb'
         goto 666
         end if
        if(sb.eq.0) then
        sb=1
        goto 555
        end if
         if(dsb) then
         if(rxif.ne.-1) write(*,*)
     * 'output file for lsb =', out(1:length)//rxc(1:4)//'.lsb'
         if(rxif.eq.-1) write(*,*)
     * 'output file for lsb =', out(1:length)//'.lsb'
         if(rxif.ne.-1) write(*,*)
     * 'output file for usb =', out(1:length)//rxc(1:4)//'.usb'
         if(rxif.eq.-1) write(*,*)
     * 'output file for usb =', out(1:length)//'.usb'
         end if

666     stop
        end
c************************************************************************
        subroutine getopt(doauto,docross,docomp,dosam,doxyp,doop,
     *    relax,sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,
     *    polflag,hires,nopol,cirpol,oldpol,dospc,doengrd)
c
        logical doauto,docross,dosam,relax,unflag,dohann,dobary,doop
        logical docomp,doif,birdie,dowt,dopmps,doxyp,polflag,hires,sing
        logical nopol,cirpol,oldpol,dospc,doengrd
c
c  Get the user options.
c
c  Output:
c    doauto	Set if the user want autocorrelation data.
c    docross	Set if the user wants cross-correlationdata.
c    docomp	Write compressed data.
c    dosam	Correct for sampler statistics.
c    doxyp	Correct the data with the measured xy phase.
c    doop	Correct for opacity.
c    dohann     Hanning smooth spectra
c    birdie	Discard bad channels in continuum mode.
c    doif	Map the simultaneous frequencies to the IF axis.
c    relax
c    unflag
c    dobary	Compute barycentric radial velocities.
c    birdie
c    dowt	Reweight the lag spectrum.
c    dopmps	Undo "poor man's phase switching"
c    polflag	Flag all polarisations if any are bad.
c    hires      Convert bin-mode to high time resolution data.
c    sing	Single dish mode.
c    nopol      Disable polarization.
c    dospc      reverse the order of spectral windows for
c               the last three blocks.
c    doengrd read engineer file.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=23)
        character opts(nopt)*8
        logical present(nopt)
        data opts/'noauto  ','nocross ','compress','relax   ',
     *            'unflag  ','samcorr ','hanning ','bary    ',
     *            'noif    ','birdie  ','reweight','xycorr  ',
     *            'opcorr  ','nopflag ','hires   ','pmps    ',
     *            'mmrelax ','single  ','nopol   ','cirpol  ',
     *            'oldpol','dospc', 'doengrd'/
        call options('options',opts,present,nopt)
        doauto = .not.present(1)
        docross = .not.present(2)
        docomp  = present(3)
        relax   = present(4)
        unflag  = present(5)
        dosam   = present(6)
        dohann  = present(7)
        dobary  = present(8)
        doif    = .not.present(9)
        birdie  = present(10)
        dowt    = present(11)
        doxyp   = present(12)
        doop    = present(13)
        polflag = .not.present(14)
        hires   = present(15)
        dopmps  = present(16)
c
c  Option mmrelax is now ignored (set automatically!).
c	
c       mmrelax = present(17)
        sing    = present(18)
        nopol   = present(19)
        cirpol  = present(20)
        oldpol  = present(21)
        dospc   = present(22)
        doengrd = present(23)
c
        if((dosam.or.doxyp.or.doop).and.relax)call bug('f',
     *    'You cannot use options samcorr, xycorr or opcorr with relax')
        end
c************************************************************************
        subroutine fixed(tno,dobary)
c
        integer tno
        logical dobary
c
c  This updates variables that never change.
c
c modified my jhz 2004-5-24 for SMA
c  Input:
c    tno	Handle of the output uv data-set.
c    dobary	Velocity restframe is the barycentre.
c------------------------------------------------------------------------
        double precision latitude,longitud,dtemp
        real chioff
        integer mount
        logical ok
        call uvputvrr(tno,'epoch',2000.,1)
        call uvputvrr(tno,'vsource',0.,1)
        call obspar('SMA','latitude',latitude,ok)
        if(ok)call obspar('SMA','longitude',longitud,ok)
        if(ok)call obspar('SMA','evector',dtemp,ok)
        if(ok)chioff = dtemp
        if(ok)call obspar('SMA','mount',dtemp,ok)
        if(ok)mount = dtemp
        if(.not.ok)then
          call bug('w','Unable to determine telescope lat/long')
        else
          call uvputvrd(tno,'latitud',latitude,1)
          call uvputvrd(tno,'longitu',longitud,1)
          call uvputvrr(tno,'evector',chioff,1)
          call uvputvri(tno,'mount',mount,1)
        endif
c
        if(dobary)then
          call uvputvra(tno,'veltype','VELO-HEL')
        else
          call uvputvra(tno,'veltype','VELO-LSR')
        endif
        end
c************************************************************************
c************************************************************************
        subroutine pokeini(tno1,dosam1,doxyp1,doop1,
     *          dohann1,birdie1,dowt1,dopmps1,dobary1,
     *          doif1,hires1,nopol1,cirpol1,oldpol1,rsnchan1)
c
        integer tno1, rsnchan1
        logical dosam1,doxyp1,dohann1,doif1,dobary1,birdie1,dowt1
        logical dopmps1,hires1,doop1,nopol1,cirpol1,oldpol1
c
c  Initialise the Poke routines.
c------------------------------------------------------------------------
c
c  The common block (yuk) used to buffer up an integration.
c
        include 'maxdim.h'
cc jhz 2004-6-7: change at -> sm for the parameter
cc smif = 48
cc smant = 8

        integer smif,smant,smpol,smdata,smbase,smbin,smcont
        parameter(smif=24,smant=8,smpol=4,smbase=((smant+1)*smant)/2)
        parameter(smbin=1024,smcont=33)
        parameter(smdata=24*maxchan*smbase)
        integer nifs,nfreq(smif),nstoke(smif),polcode(smif,smpol)
        double precision sfreq(smif),sdf(smif),restfreq(smif)
        double precision time
        integer tcorr
        real xtsys(smif,smant),ytsys(smif,smant),chi
        real u(smbase),v(smbase),w(smbase)
        real xyphase(smif,smant),xyamp(smif,smant)
        real xsampler(3,smif,smant),ysampler(3,smif,smant)
        complex data(smdata)
        integer pnt(smif,smpol,smbase,smbin),nbin(smif),edge(smif)
        integer bchan(smif)
        real inttime(smbase),inttim
        logical flag(smif,smpol,smbase,smbin),dosw(smbase)
        integer nused,tno,nants
        logical dosam,dohann,birdie,doif,dobary,newfreq,newsc,newpnt
        logical dowt,dopmps,doxyp,opcorr,hires
        real wts(2*smcont-2)
        real axisrms(smant),axismax(smant),mdata(5)
        logical mflag
        double precision obsra,obsdec,lat,long,ra,dec
        double precision lat1, long1
        character sname*64
c
        common/atlodd/sname
        common/atlodc/sfreq,sdf,restfreq,time,obsra,obsdec,lat,long,
     *      ra,dec,
     *    data,
     *    xtsys,ytsys,chi,xyphase,xyamp,xsampler,ysampler,u,v,w,inttime,
     *      inttim,wts,mdata,axisrms,axismax,
     *    pnt,nbin,nused,tno,nants,nifs,nfreq,nstoke,polcode,edge,
     *      bchan,tcorr,
     *    flag,dosw,dosam,dohann,birdie,dowt,dopmps,doxyp,opcorr,
     *      doif,dobary,newfreq,hires,mflag,
     *    newsc,newpnt
        integer bl,p,if,bin
        logical ok
cc jhz
        kstat=1;
c
        sname  = ' '
        tno    = tno1
        dosam  = dosam1
        doxyp  = doxyp1
        opcorr = doop1
        dohann = dohann1
        doif   = doif1
        dobary = dobary1
        birdie = birdie1
        dowt   = dowt1
        dopmps = dopmps1
        hires  = hires1
c
        if(dowt)call lagwt(wts,2*smcont-2,0.04)
c
        newsc = .false.
        newfreq = .false.
        nants = 0
        nifs = 0
        nused = 0
        do if=1,smif
          nstoke(if) = 0
          nfreq(if) = 0
        enddo
c
c  Reset the counters, etc.
c
        do if=1,smif
          nbin(if) = 0
        enddo
        inttim = 0
        do bin=1,smbin
          do bl=1,smbase
            do p=1,smpol
              do if=1,smif
                pnt(if,p,bl,bin) = 0
              enddo
            enddo
          enddo
        enddo
c
        call obspar('SMA','latitude', lat, ok)
          lat1=lat
        if(.not.ok)call bug('f','Could not get SMA latitude')
        call obspar('SMA','longitude',long,ok)
          long1=long
        if(.not.ok)call bug('f','Could not get SMA longitude')
c
        call rspokeinisma(kstat,tno1,dosam1,doxyp1,doop1,
     *  dohann1,birdie1,dowt1,dopmps1,dobary1,doif1,hires1,
     *  nopol1,cirpol1,oldpol1,lat1,long1,rsnchan1)
        end
c************************************************************************
        subroutine liner(string)
c
        character string*(*)
c
c------------------------------------------------------------------------
        character line*72
c
c  The common block (yuk) used to buffer up an integration.
c
        include 'maxdim.h'
c
        integer smif,smant,smpol,smdata,smbase,smbin,smcont
        parameter(smif=24,smant=8,smpol=4,smbase=((smant+1)*smant)/2)
        parameter(smbin=1024,smcont=33)
        parameter(smdata=24*maxchan*smbase)
        integer nifs,nfreq(smif),nstoke(smif),polcode(smif,smpol)
        double precision sfreq(smif),sdf(smif),restfreq(smif)
        double precision time
        integer tcorr
        real xtsys(smif,smant),ytsys(smif,smant),chi
        real u(smbase),v(smbase),w(smbase)
        real xyphase(smif,smant),xyamp(smif,smant)
        real xsampler(3,smif,smant),ysampler(3,smif,smant)
        complex data(smdata)
        integer pnt(smif,smpol,smbase,smbin),nbin(smif),edge(smif)
        integer bchan(smif)
        real inttime(smbase),inttim
        logical flag(smif,smpol,smbase,smbin),dosw(smbase)
        integer nused,tno,nants
        logical dosam,dohann,birdie,doif,dobary,newfreq,newsc,newpnt
        logical dowt,dopmps,doxyp,opcorr,hires
        real wts(2*smcont-2)
        real axisrms(smant),axismax(smant),mdata(5)
        logical mflag
        double precision obsra,obsdec,lat,long,ra,dec
        character sname*64
c
        common/atlodd/sname
        common/atlodc/sfreq,sdf,restfreq,time,obsra,obsdec,lat,long,
     *      ra,dec,
     *    data,
     *    xtsys,ytsys,chi,xyphase,xyamp,xsampler,ysampler,u,v,w,inttime,
     *      inttim,wts,mdata,axisrms,axismax,
     *    pnt,nbin,nused,tno,nants,nifs,nfreq,nstoke,polcode,edge,
     *      bchan,tcorr,
     *    flag,dosw,dosam,dohann,birdie,dowt,dopmps,doxyp,opcorr,
     *      doif,dobary,newfreq,hires,mflag,
     *    newsc,newpnt
c
        call output(string)
        line = 'SMALOD:    '//string
        call hiswrite(tno,line)
        end
c************************************************************************
        subroutine pokename(in)
c
        character in*(*)
c
c------------------------------------------------------------------------
c
c  The common block (yuk) used to buffer up an integration.
c
        include 'maxdim.h'
c
        integer smif,smant,smpol,smdata,smbase,smbin,smcont
        parameter(smif=24,smant=8,smpol=4,smbase=((smant+1)*smant)/2)
        parameter(smbin=1024,smcont=33)
        parameter(smdata=24*maxchan*smbase)
        integer nifs,nfreq(smif),nstoke(smif),polcode(smif,smpol)
        double precision sfreq(smif),sdf(smif),restfreq(smif)
        double precision time
        integer tcorr
        real xtsys(smif,smant),ytsys(smif,smant),chi
        real u(smbase),v(smbase),w(smbase)
        real xyphase(smif,smant),xyamp(smif,smant)
        real xsampler(3,smif,smant),ysampler(3,smif,smant)
        complex data(smdata)
        integer pnt(smif,smpol,smbase,smbin),nbin(smif),edge(smif)
        integer bchan(smif)
        real inttime(smbase),inttim
        logical flag(smif,smpol,smbase,smbin),dosw(smbase)
        integer nused,tno,nants
        logical dosam,dohann,birdie,doif,dobary,newfreq,newsc,newpnt
        logical dowt,dopmps,doxyp,opcorr,hires
        real wts(2*smcont-2)
        real axisrms(smant),axismax(smant),mdata(5)
        logical mflag
        double precision obsra,obsdec,lat,long,ra,dec
        character sname*64
c
        common/atlodd/sname
        common/atlodc/sfreq,sdf,restfreq,time,obsra,obsdec,lat,long,
     *      ra,dec,
     *    data,
     *    xtsys,ytsys,chi,xyphase,xyamp,xsampler,ysampler,u,v,w,inttime,
     *      inttim,wts,mdata,axisrms,axismax,
     *    pnt,nbin,nused,tno,nants,nifs,nfreq,nstoke,polcode,edge,
     *      bchan,tcorr,
     *    flag,dosw,dosam,dohann,birdie,dowt,dopmps,doxyp,opcorr,
     *      doif,dobary,newfreq,hires,mflag,
     *    newsc,newpnt
        character c*1
        integer i1,i2,i
c
        integer len1
c
        i1 = 1
        i2 = len1(in)
        do i=1,i2
          c = in(i:i)
          if(index('/[]:',c).ne.0)i1 = i + 1
        enddo
        if(i1.gt.i2)i1 = 1
        call uvputvra(tno,'name',in(i1:i2)) 
        end
c************************************************************************
c************************************************************************
        subroutine rpskip(in,iostat)
c
        character in*(*)
        integer iostat
c
c  Skip an RPFITS file.
c------------------------------------------------------------------------
        call smaopen(in,iostat)
        if(iostat.eq.0)call smaeof(iostat)
        if(iostat.eq.0)call smaclose(iostat)
        end
c************************************************************************
        subroutine smadisp(in,scanskip,scanproc,doauto,docross,relax,
     *    sing,unflag,polflag,rxif,userfreq,nuser,sb,iostat, 
     *    dosporder,doeng)
c
        character in*(*)
        integer scanskip,scanproc,rxif,nuser,sb,iostat,dosporder,doeng
        double precision userfreq(*)
        logical doauto,docross,relax,unflag,polflag,sing
c  jhz
c
c  Process a sma_mir file. Dispatch information to the
c  relevant Poke routine. Then eventually flush it out with PokeFlsh.
c
c  Inputs:
c    scanskip	Scans to skip.
c    scanproc	Number of scans to process. If 0, process all scans.
c    doauto	Save autocorrelation data.
c    docross	Save crosscorrelation data.
c    relax	Save data even if the SYSCAL record is bad.
c    sing
c    polflag	Flag all polarisations if any are bad.
c    unflag	Save data even though it may appear flagged.
c    ifsel	IF to select. 0 means select all IFs.
c    userfreq	User-given rest frequency to override the value in
c		the RPFITS file.
c    nuser	Number of user-specificed rest frequencies.
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
        integer maxpol,maxsim,maxxyp
        parameter(maxpol=4,maxsim=4,maxxyp=5)
c
        integer ant_max, max_card, max_if, pol_max, max_su, max_fg,
     *        max_nx, max_mt, max_sc, max_cu
        parameter (ant_max=15, max_card=650, max_if=24, pol_max=8,
     *        max_su=500, max_fg=32, max_nx=256, max_mt=256,
     *        max_sc=16, max_cu=32)

        integer nstok, nfreq, ncount, nscan, ivelref, nant, ncard,
     *        intime, sma_defeat, n_if, if_num(max_if),
     *        if_invert(max_if), if_nfreq(max_if),
     *        if_nstok(max_if), if_sampl(max_if), if_simul(max_if),
     *        if_chain(max_if), ant_num(ant_max), n_su, su_num(max_su),
     *        n_fg, fg_ant(2,max_fg),fg_if(2, max_fg),
     *        fg_chan(2, max_fg), fg_stok(2, max_fg), n_nx,
     *        nx_rec(max_nx), ant_mount(ant_max),
     *        sma_iostat, n_mt, mt_ant(max_mt),
     *        sc_ant, sc_if, sc_q, n_cu, cu_ant(max_cu),
     *        cu_if(max_cu), cu_ch1(max_cu), cu_ch2(max_cu),
     *        sc_srcno, data_format

      double precision ra, dec, freq, dfreq, rfreq, vel1, sma_utcmtai,
     *        sma_c(12), sma_djmrefp, sma_djmreft, x(ant_max),
     *        y(ant_max), z(ant_max), if_freq(max_if), x_array,
     *        y_array, z_array, axis_offset(ant_max),
     *        feed_pa(2,ant_max), feed_cal(ant_max, max_if, pol_max),
     *        if_bw(max_if), fg_ut(2, max_fg), su_ra(max_su),
     *        su_dec(max_su), su_rad(max_su), su_decd(max_su),
     *        if_ref(max_if), nx_ut(max_nx), mt_press(max_mt),
     *        mt_temp(max_mt), mt_humid(max_mt), mt_ut(max_mt),
     *        cu_ut(max_cu), cu_cal1(max_cu), cu_cal2(max_cu),
     *        su_pra(max_su), su_pdec(max_su), su_prad(max_su),
     *        su_pdecd(max_su), pm_ra, pm_dec, pm_epoch

      real sc_ut, sc_cal(max_sc,max_if, ant_max), intbase

      character*2 feed_type(2,ant_max), if_cstok(4,max_if)
      character*16 object,instrument,cal,rp_observer
      character*8 sta(ant_max), coord, datsys
      character*20 version, rpfitsversion
      character*12 datobs, datwrit
      character*80 file
      character*80 card(max_card)
      character su_name(max_su)*16, su_cal(max_su)*4,
     *       fg_reason(max_fg)*24, nx_date(max_nx)*12,
     *       nx_source(max_nx)*16
      logical if_found, su_found, fg_found, nx_found, an_found,
     *       mt_found, cu_found, write_wt

      common /doubles/ axis_offset, dec, dfreq, cu_cal1, cu_cal2,
     *      cu_ut, feed_cal, feed_pa, fg_ut, freq, if_bw, if_ref,
     *      if_freq, mt_humid, mt_press, mt_temp, mt_ut, nx_ut,
     *      ra, rfreq, sma_c, sma_djmrefp, sma_djmreft, sma_utcmtai,
     *      su_dec, su_ra, su_rad, su_decd, su_pra, su_pdec,
     *      su_prad, su_pdecd, vel1, x, x_array, y, y_array, z,
     *      z_array
      common /proper/ pm_ra, pm_dec, pm_epoch
      common /param/ nstok, nfreq, ncount, intime, nscan, write_wt,
     *       ncard, intbase, data_format
      common /spect/ ivelref
      common /anten/ nant, ant_num, ant_mount, an_found
      common /ephem/ rp_defeat
      common /if/ n_if, if_invert, if_nfreq, if_nstok,
     *        if_sampl, if_found, if_num, if_simul, if_chain
      common /su/ n_su, su_found, su_num
      common /fg/ n_fg, fg_ant, fg_if, fg_chan, fg_stok, fg_found
      common /nx/ n_nx, nx_rec, nx_found
      common /mt/ n_mt, mt_ant, mt_found
      common /index/ rp_iostat
      common /sc/ sc_ut, sc_ant, sc_if, sc_q, sc_cal, sc_srcno
      common /cu/ n_cu, cu_ant, cu_if, cu_ch1, cu_ch2, cu_found
      common /names/ object, instrument, cal, sma_observer, datobs,
     *       datwrit, file, datsys, version, coord, sta, feed_type,
     *       card, if_cstok, su_name, su_cal, fg_reason, nx_source,
     *       nx_date, rpfitsversion

c     the following is for compatibility with early versions:
c
      double precision sma_pressure(ant_max), sma_temp(ant_max),
     *    sma_humid(ant_max), ant_pressure(ant_max),
     *    ant_temp(ant_max), ant_humid(ant_max)
      equivalence ( sma_pressure(1), ant_pressure(1))
      equivalence ( sma_temp(1), ant_temp(1))
      equivalence ( sma_humid(1), ant_humid(1))
      equivalence ( mt_press(1), ant_pressure(1))
      equivalence ( mt_temp(1), ant_temp(1))
      equivalence ( mt_humid(1), ant_humid(1))
        integer scanno,i1,i2,baseln,i,id,j
        logical newscan,newsrc,newfreq,newtime,accum,ok,badbit
        logical flags(maxpol),corrfud,kband,wband
        integer jstat,flag,bin,ifno,srcno,simno,ssrcno,ssimno
        integer if2sim(max_if),nifs(max_if),sim2if(maxsim,max_if)
        integer sif(max_if)
        real ut,utprev,utprevsc,u,v,w,weight(maxchan*maxpol)
        complex vis(maxchan*maxpol)
        double precision reftime,ra0,dec0,pntra,pntdec
        character calcode*16

c  Information on flagging.
c
        integer nrec,nspec,fgbad,fgoffsrc,fginvant,fgsysc,fgsam
c
c  Variables to track the sysc records.
c
        logical scinit(max_if,ant_max),scbuf(max_if,ant_max)
        logical xflag(max_if,ant_max),yflag(max_if,ant_max)
        integer ptag(maxxyp,max_if,ant_max)
        integer atag(maxxyp,max_if,ant_max)
        integer nxyp(max_if,ant_max),tcorr
        real xyp(maxxyp,max_if,ant_max),xya(maxxyp,max_if,ant_max)
        real xyphase(max_if,ant_max),xyamp(max_if,ant_max)
        real pntrms(ant_max),pntmax(ant_max)
        real xsamp(3,max_if,ant_max),ysamp(3,max_if,ant_max)
        real xtsys(max_if,ant_max),ytsys(max_if,ant_max)
        real chi,tint,mdata(5)
c
        logical antvalid(ant_max),mflag
        double precision jday0,time,tprev
        integer kstat 
c
c  Open the SMA_MIR file.
c
         call smaopen(in,iostat)
        if(iostat.ne.0)return
c
c  Initialize.
c
        call pokename(in)
        call rssmaflush(mflag,scinit,tcorr,scbuf,xflag,yflag,
     *       max_if,ant_max,  scanskip, scanproc, sb, rxif, 
     *       dosporder, doeng)
                  kstat= 666
        call rspokeflshsma(kstat);
c
         jstat =-1;
         call rsmiriadwrite(in,jstat)
         call smaclose(iostat)
        end
c************************************************************************
        subroutine smaeof(jstat)
c
        integer jstat
c
c  Skip to the EOF.
c
c------------------------------------------------------------------------
        integer flag,baseln,bin,ifno,srcno
        real ut,u,v,w,weight
        complex vis
c
        character smaerr*32
c
c       thsi function is not used.
c
        jstat = 2
        if(jstat.eq.3)jstat = 0
        if(jstat.ne.0)call bug('w',
     *          'Error while skipping: '//smaerr(jstat))
        end
c************************************************************************
        character*(*) function smaerr(jstat)
c
        integer jstat
c
c  Translate an RPFITSIN jstat value into something a bit more
c  meaningful.
c------------------------------------------------------------------------
        character itoaf*8
c
        integer nmess
        parameter(nmess=7)
        character mess(nmess)*32
        data mess/'Operation unsuccessful          ',
     *            'Operation successful            ',
     *            'Encountered header while reading',
     *            'Probably OK ... End of scan     ',
     *            'Encountered end-of-file         ',
     *            'Encountered FG table            ',
     *            'Illegal parameter encountered   '/
c
        if(jstat.ge.-1.and.jstat.le.5)then
          smaerr = mess(jstat+2)
        else
          smaerr = 'RPFITS error: jstat='//itoaf(jstat)
        endif
c
        end
c************************************************************************
        subroutine smaclose(jstat)
c
        integer jstat
c------------------------------------------------------------------------
        integer flag,baseln,bin,ifno,srcno
        real ut,u,v,w,weight
        complex vis
c
        character smaerr*32
c
c       smadata files are closed in the c codes.
c
        end
c************************************************************************
        subroutine smaopen(in,jstat)
c
        character in*(*)
        integer jstat, tno
c
        integer ant_max, max_card, max_if, pol_max, max_su, max_fg,
     *        max_nx, max_mt, max_sc, max_cu
        parameter (ant_max=15, max_card=650, max_if=24, pol_max=8,
     *        max_su=500, max_fg=32, max_nx=256, max_mt=256,
     *        max_sc=16, max_cu=32)
c
        integer nstok, nfreq, ncount, nscan, ivelref, nant, ncard,
     *        intime, rp_defeat, n_if, if_num(max_if),
     *        if_invert(max_if), if_nfreq(max_if),
     *        if_nstok(max_if), if_sampl(max_if), if_simul(max_if),
     *        if_chain(max_if), ant_num(ant_max), n_su, su_num(max_su),
     *        n_fg, fg_ant(2,max_fg),fg_if(2, max_fg),
     *        fg_chan(2, max_fg), fg_stok(2, max_fg), n_nx,
     *        nx_rec(max_nx), ant_mount(ant_max),
     *        rp_iostat, n_mt, mt_ant(max_mt),
     *        sc_ant, sc_if, sc_q, n_cu, cu_ant(max_cu),
     *        cu_if(max_cu), cu_ch1(max_cu), cu_ch2(max_cu),
     *        sc_srcno, data_format
c
      double precision ra, dec, freq, dfreq, rfreq, vel1, rp_utcmtai,
     *        rp_c(12), rp_djmrefp, rp_djmreft,x(ant_max),
     *        y(ant_max), z(ant_max), if_freq(max_if), x_array,
     *        y_array, z_array, axis_offset(ant_max),
     *        feed_pa(2,ant_max), feed_cal(ant_max, max_if, pol_max),
     *        if_bw(max_if), fg_ut(2, max_fg), su_ra(max_su),
     *        su_dec(max_su), su_rad(max_su), su_decd(max_su),
     *        if_ref(max_if), nx_ut(max_nx), mt_press(max_mt),
     *        mt_temp(max_mt), mt_humid(max_mt), mt_ut(max_mt),
     *        cu_ut(max_cu), cu_cal1(max_cu), cu_cal2(max_cu),
     *        su_pra(max_su), su_pdec(max_su), su_prad(max_su),
     *        su_pdecd(max_su), pm_ra, pm_dec, pm_epoch
c
      real sc_ut, sc_cal(max_sc,max_if, ant_max), intbase
c
      character*2 feed_type(2,ant_max), if_cstok(4,max_if)
      character*16 object,instrument,cal,rp_observer
      character*8 sta(ant_max), coord, datsys
      character*20 version, rpfitsversion
      character*12 datobs, datwrit
      character*80 file
      character*80 card(max_card)
      character su_name(max_su)*16, su_cal(max_su)*4,
     *       fg_reason(max_fg)*24, nx_date(max_nx)*12,
     *       nx_source(max_nx)*16
      logical if_found, su_found, fg_found, nx_found, an_found,
     *       mt_found, cu_found, write_wt
c
      common /doubles/ axis_offset, dec, dfreq, cu_cal1, cu_cal2,
     *      cu_ut, feed_cal, feed_pa, fg_ut, freq, if_bw, if_ref,
     *      if_freq, mt_humid, mt_press, mt_temp, mt_ut, nx_ut,
     *      ra, rfreq, rp_c, rp_djmrefp, rp_djmreft, rp_utcmtai,
     *      su_dec, su_ra, su_rad, su_decd, su_pra, su_pdec,
     *      su_prad, su_pdecd, vel1, x, x_array, y, y_array, z,
     *      z_array
      common /proper/ pm_ra, pm_dec, pm_epoch
      common /param/ nstok, nfreq, ncount, intime, nscan, write_wt,
     *       ncard, intbase, data_format
      common /spect/ ivelref
      common /anten/ nant, ant_num, ant_mount, an_found
      common /ephem/ rp_defeat
      common /if/ n_if, if_invert, if_nfreq, if_nstok,
     *        if_sampl, if_found, if_num, if_simul, if_chain
      common /su/ n_su, su_found, su_num
      common /fg/ n_fg, fg_ant, fg_if, fg_chan, fg_stok, fg_found
      common /nx/ n_nx, nx_rec, nx_found
      common /mt/ n_mt, mt_ant, mt_found
      common /index/ rp_iostat
      common /sc/ sc_ut, sc_ant, sc_if, sc_q, sc_cal, sc_srcno
      common /cu/ n_cu, cu_ant, cu_if, cu_ch1, cu_ch2, cu_found
      common /names/ object, instrument, cal, sma_observer, datobs,
     *       datwrit, file, datsys, version, coord, sta, feed_type,
     *       card, if_cstok, su_name, su_cal, fg_reason, nx_source,
     *       nx_date, rpfitsversion
c
c
c     the following is for compatibility with early versions:
      double precision rp_pressure(ant_max), rp_temp(ant_max),
     *    rp_humid(ant_max), ant_pressure(ant_max),
     *    ant_temp(ant_max), ant_humid(ant_max)
      equivalence ( rp_pressure(1), ant_pressure(1))
      equivalence ( rp_temp(1), ant_temp(1))
      equivalence ( rp_humid(1), ant_humid(1))
      equivalence ( mt_press(1), ant_pressure(1))
      equivalence ( mt_temp(1), ant_temp(1))
      equivalence ( mt_humid(1), ant_humid(1))
c
        integer flag,baseln,bin,ifno,srcno
        real ut,u,v,w,weight
        complex vis
c
c  External.
c
        character smaerr*32
c
        file = in
c   jstat=-3 -> open the input data file 
        jstat = -3
        an_found = .false.
c jhz test
        call rsmirread(in, jstat)
        if(jstat.ne.0) call bug('w',
     *      'Error opening SMA MIR file: '//smaerr(jstat))
        if(jstat.ne.0)return
        end
c************************************************************************
c************************************************************************
        character*(*) function pcent(frac,total)
c
        integer frac,total
c------------------------------------------------------------------------
        character val*5
        real x
        x = real(100*frac)/real(total)
        if(x.gt.9.99)then
          write(val,'(f5.1)')x
        else
          write(val,'(f5.2,a)')x
        endif
        pcent = val//'%'
        end
c************************************************************************
        real function getjpk(freq)
c
        real freq
c------------------------------------------------------------------------
        if(freq.lt.15)then
          getjpk = 13
        else if(freq.lt.30)then
          getjpk = 15
        else
          getjpk = 25
        endif
c
        end
