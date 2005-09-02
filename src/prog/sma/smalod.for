c************************************************************************
        program smalod 
        implicit none
c
c= smalod - Convert an Sma archive data (Caltech MIR) into Miriad uv format
c& Jun-Hui Zhao 
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
c@ vsource
c       The radial velocity of source in km/s w.r.t. the LSR or 
c       the barycenter. The velocity reference frame can be selected 
c       in options. Positive velocity is away from observer.
c       Default is zero.
c
c@ refant
c      The reference antenna. Default is 6. The reference antenna needs
c      to be present while the antenna positions are being decoded 
c      from baseline vectors stored in SMA MIR data. The geocentrical 
c      coordinates for the antennas can be retrieved from SMA sybase. 
c      For double checking the antenna positions, one can login to
c      d2o.sma.hawaii.edu (IP:128.171.116.111) and use the following
c      command:
c      dBValue -d hal9000-newdds -v dsm_dds_hal_x_v11_d -t "2004-11-16 00:00:00"
c      dBValue -d hal9000-newdds -v dsm_dds_hal_y_v11_d -t "2004-11-16 00:00:00"
c      dBValue -d hal9000-newdds -v dsm_dds_hal_z_v11_d -t "2004-11-16 00:00:00"
c      If the reference antenna is not the default value 6, one may need
c      to give the reference antenna here.
c
c@ options
c       'bary'     Compute the radial velocities of the observatory, in the 
c                  direction of a source, w.r.t. the barycenter. 
c		   Default uses the on-line values.
c       'lsr'      Compute the radial velocities of the observatory, in the 
c                  direction of a source, w.r.t. the LSR. 
c                  Default uses the on-line values.
c                  The above two options might be applied only when
c                  the chunk frequency stored in the SMA raw data
c                  corresponds to the true Doppler tracked sky frequency
c                  or no online correction to the frequency has been
c                  made. 
c       'nopol'    Disable polarization. All the correlations will be
c                  labelled as XX. Default in options for polarization 
c                  is nopol.
c       'circular' when circular polarization data taken with single
c                  with waveplates.
c       'linear'   when linear polarization data taken with dual linear feeds.
c   
c       'oldpol'   Converts MIR polarization data observed before
c                  2004-9-1.
c                  Defaults assumes non-polarization state is assigned.
c       'dospc'    reverses the order of the spectral chunks in frequency
c                  only for the first three blocks (1 2 3).
c                  frequency code vs. spectral window orders:
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
c       'conjugat' to phase conjugate for lsb data.
c                   Default: 
c                   conjugate the phase of the lsb data observed before 2005-04-28;
c                   no phase flip for the data observed after 2005-04-28.
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
c       followed by the number of scans to process. 
c       The default is to skip the 1st and the last 2 scans
c       and process the rest of scans in the file.
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
c    jhz  02-mar-05 added options doengrd to read engineer data file
c    jhz  08-mar-05 added options circular to read polarization data
c                   taken from single feed with waveplates.
c    jhz  10-mar-05 decoded the antenna positions from mir baseline
c                   coordinates; converted the geocentrical coordinates
c                   to miriad coordinates.
c    jhz  10-mar-05 removed uvputvra for file name which somehow
c                   is rejected by miriad program uvlist.
c    jhz  18-mar-05 added linear in options for polarization;
c                   made default for nopol
c    jhz  18-mar-05 corrected size for mount in uvputvr
c    jhz  23-mar-05 fixed a bug in decoding antenna position
c                   for antennas with id > reference antenna's id. 
c    jhz  01-apr-05 cleaned some mess left from atlod. 
c    jhz  02-may-05 add a function to add '/' in the end of the input
c                   file name in case the slash is missing.
c    jhz  02-may-05 add an option to do phase conjugate for the lower side
c                   band data in respose to Taco's log 9288.
c    jhz  05-may-05 enable the function to calculate radial velocity
c                   on either barycentric of lsr frame.
c    jhz  02-jun-05 add input parameter vsource; and enable input
c                   parameter restfreq.
c    jhz  20-jun-05 fix a bug (pointing to a wrong v component) in calculation\
c                   of the site velocity due to the earth rotation.
c                   The error was in the sma_mirRead.c
c    jhz  21-jun-05 eliminate unused variables and subroutines
c    jhz  22-jun-05 make restfreq working
c    jhz  24-jun-05 add variable ut
c    jhz  27-jun-05 add initializing blarray in sma_mirRead.c
c    jhz  05-jul-05 update the version corresponding to
c                   remove a hidden phase flip in sma_mirRead.c
c    jhz  07-jul-05 update jyperk in sma_mirRead.c
c                   change the default of the first argument in 
c                   nscans to 1
c    jhz 07-jul-05 pasring the source name in sma_mirRead.c
c                   changing the source name if the first 8
c                   characters are identical for any of the two source
c                   name entries from mir data.
c    jhz 08-aug-05 updating the inline document for vsource;
c                   the velocity reference frame for vsource
c                   is defined using options; either bary or lsr
c                   is supported. 
c    jhz 31-aug-05 update the inline doc for option lsr and bary.
c------------------------------------------------------------------------
        integer maxfiles
        parameter(maxfiles=128)
        character version*(*)
        parameter(version='SmaLod: version 1.12 31-Aug-05')
c
        character in(maxfiles)*64,out*64,line*64, rxc*4
        integer tno, length, len1
        integer ifile,rxif,nfreq,iostat,nfiles,i
        double precision rfreq
        logical doauto,docross,docomp,dosam,relax,unflag,dohann
        logical dobary,doif,birdie,dowt,dopmps,doxyp,doop
        logical polflag,hires,nopol,sing,circular,linear,oldpol,dsb,
     *          dospc,doengrd, doconjug, dolsr
        integer fileskip,fileproc,scanskip,scanproc,sb, dosporder
        integer doeng
	integer rsNCHAN, refant
        real vsour
c
c  Externals.
c
        character smaerr*32,itoaf*8, filebuf*64, charbuf*1
        dsb = .false.
c
c  Get the input parameters.
c
        call output(version)
        call keyini
        call mkeyf('in',in,maxfiles,nfiles)
        filebuf=in(1)(1:len1(in(1)))
        charbuf=in(1)(len1(in(1)):len1(in(1)))
           if(charbuf.ne."/")  
     *      in(1)=filebuf(1:len1(filebuf))//'/'
        if(nfiles.gt.1)
     *    call bug('f','Only handle one input file at once')
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
c        call mkeyd('restfreq',rfreq,2,nfreq)
        call keyd('restfreq',rfreq,0.0)
        call keyr('vsource', vsour,0.0)
        call keyi('refant',refant,6)
        call getopt(doauto,docross,docomp,dosam,doxyp,doop,relax,
     *    sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,polflag,
     *    hires,nopol,circular,linear,oldpol,dospc,doengrd,doconjug,
     *    dolsr)
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
        call keyi('nscans',scanskip,1)
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
     *      dopmps,dobary,doif,hires,nopol,circular,linear,oldpol,
     *      rsnchan,refant,dolsr,rfreq,vsour)
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
     *          iostat, dosporder,doeng,doconjug)
          endif
        enddo
        if(iostat.ne.0)then
          line = 'SMAMIR i/o error: '//smaerr(iostat)
          call bug('w',line)
          call bug('w','Prematurely finishing because of errors')
          call hiswrite(tno,'SMALOD: '//line)
          
          call hiswrite(tno,
     *      'SMALOD: Prematurely finishing because of errors')
          else
          call hiswrite(tno,
     *      'SMALOD: Ended Gracefully')
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
     *    polflag,hires,nopol,circular,linear,oldpol,dospc,doengrd,
     *    doconjug,dolsr)
c
        logical doauto,docross,dosam,relax,unflag,dohann,dobary,doop
        logical docomp,doif,birdie,dowt,dopmps,doxyp,polflag,hires,sing
        logical nopol,circular,linear,oldpol,dospc,doengrd,doconjug
        logical dolsr
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
c    dowt	Reweight the lag spectrum.
c    dopmps	Undo "poor man's phase switching"
c    polflag	Flag all polarisations if any are bad.
c    hires      Convert bin-mode to high time resolution data.
c    sing	Single dish mode.
c    nopol      Disable polarization.
c    circular   circular polarization.
c    linear     linear polarization.
c    dospc      reverse the order of spectral windows for
c               the last three blocks.
c    doengrd    read engineer file.
c    doconjug   phase conjugate for lsb data (data before 2004 April 28)
c    dolsr      Compute LSR radial velocities.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=26)
        character opts(nopt)*8
        logical present(nopt)
        data opts/'noauto  ','nocross ','compress','relax   ',
     *            'unflag  ','samcorr ','hanning ','bary    ',
     *            'noif    ','birdie  ','reweight','xycorr  ',
     *            'opcorr  ','nopflag ','hires   ','pmps    ',
     *            'mmrelax ','single  ','nopol   ','circular  ',
     *            'linear', 'oldpol','dospc', 'doengrd',
     *            'conjugat', 'lsr'/
        call options('options',opts,present,nopt)
        doauto  = .not.present(1)
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
        circular= present(20)
        linear  = present(21)
        oldpol  = present(22)
        dospc   = present(23)
        doengrd = present(24)
        doconjug= present(25)
        dolsr   = present(26)
        if(dobary.and.dolsr) 
     *  call bug('f','choose options of either bary or lsr')
        if((.not.circular.and..not.linear).and..not.oldpol) nopol=.true.
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
c        call uvputvrr(tno,'vsource',0.,1)
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
c
c Alt-Az mount=0 SMA project book
c
          mount =0
          call uvputvri(tno,'mount',mount,1)
        endif
        end
c************************************************************************
c************************************************************************
        subroutine pokeini(tno1,dosam1,doxyp1,doop1,
     *          dohann1,birdie1,dowt1,dopmps1,dobary1,
     *          doif1,hires1,nopol1,circular1,linear1,oldpol1,
     *	        rsnchan1,refant1,dolsr1,rfreq1,vsour1)
c
        integer tno1, rsnchan1, refant1
        logical dosam1,doxyp1,dohann1,doif1,dobary1,birdie1,dowt1
        logical dopmps1,hires1,doop1,nopol1,circular1,linear1,oldpol1
        logical dolsr1
        double precision rfreq1
        real vsour1
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

        double precision lat,long
        double precision lat1, long1
        logical ok
cc jhz
        kstat=1;
        call obspar('SMA','latitude', lat, ok)
          lat1=lat
        if(.not.ok)call bug('f','Could not get SMA latitude')
        call obspar('SMA','longitude',long,ok)
          long1=long
c        if(.not.ok)call bug('f','Could not get SMA longitude')
c
        call rspokeinisma(kstat,tno1,dosam1,doxyp1,doop1,
     *  dohann1,birdie1,dowt1,dopmps1,dobary1,doif1,hires1,
     *  nopol1,circular1,linear1,oldpol1,lat1,long1,rsnchan1,
     *  refant1,dolsr1,rfreq1,vsour1)
        end
c************************************************************************
        subroutine liner(string)
c
        character string*(*)
c
c------------------------------------------------------------------------
        character line*72
c
        call output(string)
        line = 'SMALOD:    '//string
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
c        call uvputvra(tno,'name',in(i1:i2)) 
        end
c************************************************************************
c************************************************************************
        subroutine rpskip(in,iostat)
c
        character in*(*)
        integer iostat
c------------------------------------------------------------------------
        call smaopen(in,iostat)
        if(iostat.eq.0)call smaeof(iostat)
        end
c************************************************************************
        subroutine smadisp(in,scanskip,scanproc,doauto,docross,relax,
     *    sing,unflag,polflag,rxif,userfreq,nuser,sb,iostat, 
     *    dosporder,doeng,doconjug)
c
        character in*(*)
        integer scanskip,scanproc,rxif,nuser,sb,iostat,dosporder,doeng
        double precision userfreq(*)
        logical doauto,docross,relax,unflag,polflag,sing,doconjug
        integer doflppha
c  jhz
c
c  Process a sma_mir file. Dispatch information to the
c  relevant Poke routine. Then eventually flush it out with PokeFlsh.
c
c  Inputs:
c    scanskip	Scans to skip.
c    scanproc	Number of scans to process. If 0, process all scans.
c    doauto     Save autocorrelation data.
c    docross    Save crosscorrelation data.
c    relax      Save data even if the SYSCAL record is bad.
c    sing
c    polflag    Flag all polarisations if any are bad.
c    unflag     Save data even though it may appear flagged.
c    ifsel      IF to select. 0 means select all IFs.
c    userfreq   User-given rest frequency to override the value in
c               the RPFITS file.
c    nuser      Number of user-specificed rest frequencies.
c    
c------------------------------------------------------------------------
c
c
        integer jstat
c
c  Information on flagging.
c
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

        if(doconjug) then
           doflppha = -1
           else
           doflppha = 1
           end if
        call rssmaflush(scanskip, scanproc, sb, rxif, 
     *       dosporder, doeng, doflppha)
             kstat= 666
         
        call rspokeflshsma(kstat);
c
         jstat =-1;
        call rsmiriadwrite(in,jstat)
        end
c************************************************************************
        subroutine smaeof(jstat)
c
        integer jstat
c
c  Skip to the EOF.
c
c------------------------------------------------------------------------
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
        subroutine smaopen(in,jstat)
c
        character in*(*)
        character*80 file
        integer jstat
c
c  External.
c
        character smaerr*32
c
c
        file = in
c   jstat=-3 -> open the input data file 
        jstat = -3
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
