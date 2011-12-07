c************************************************************************
        program smalod 
        implicit none
c
c= smalod - Convert an Sma archive data (Caltech MIR) into Miriad uv format
c& jhz 
c: data transfer
c+
c       SMALOD is a MIRIAD task, which converts the standard SMA data 
c       format to Miriad format.
c
c@ in   Name of the input MIR file.
c       There is no default.
c
c@ out
c       Name of the output Miriad uv data-set. No default.
c
c@ rxif
c       select data from one of the dual receivers/IFs: 
c       rxif=-1 for the 1st rxif band;
c       rxif=-2 for the 2nd rxif band.
c
c       select the data based on receiver id:
c       for data taken after  2006-12-28 --
c       rxif=0 for receiver id = 0 -> 230 GHz band;
c       rxif=1 for receiver id = 1 -> 340 GHz band;
c       rxif=2 for receiver id = 2 -> 400 GHz band;
c       rxif=3 for receiver id = 3 -> 690 GHz band;
c       for data taken before 2006-12-28 --
c       rxif=0 for receiver id = 0 -> 230 GHz band;
c       rxif=1 for receiver id = 1 -> 340 GHz band;
c       rxif=2 for receiver id = 2 -> 690 GHz band.
c
c       The default is rxif=-1 or the 1st rxif band.
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
c       the barycenter, which was included in the online Doppler
c       track. The velocity reference frame can be selected 
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
c                  receivers and waveplates for each antenna. For the 
c                  circular polarization data observed before 2005-06-10, 
c                  the polarization states are swapped by the default 
c                  (RR<->LL, RL<->LR or -1 <-> -2, -3 <-> -4).
c
c       'linear'   when linear polarization data taken with dual linear feeds.
c   
c       'oldpol'   Obsoleted. 
c                  Defaults assume that non-polarization state is assigned.
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
c                  Default: 
c                  conjugate the phase of the lsb data observed before 
c                  2005-04-28;
c                  no phase flip for the data observed after 2005-04-28.
c       'noskip'   not to skip any data; the default is to skip
c                  data with source name "target" and/or "unknown".
c       'mcconfig' to handle multiple correlator configurations.
c                  The default is to handle multiple correlator configuration. 
c       'nohspr'   to turn off the high spectral resolution mode.
c                  For data taken after 2006-5-12, the default 
c                  will properly handle the hybrid high spectral 
c                  resolution mode, allowing presence of empty 
c                  spectral windows (chunks).
c       'debug'    To print out the warning messages indicating
c                  what have been fixed or skipped for the header
c                  problems. ERRreport.log is created in reporting
c                  the detailed errors. Default mutes these messages.
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
c@ spskip
c       For data taken after 2006-5-12, the default will properly
c       handle the skipped windows (chunks).
c       For data taken earlier than 2006-5-12, this keyword 
c       specifies the skipping in spectral windows, e.g.:
c       spskip=21,2 means that starting at spcode (MIR) = 21, two
c       spectral chunks are skipped, i.e. no data are produced for the
c       spectral chunks with spcode=21 and 22. Then smalod will
c       move up by two spectral windows while storing the rest of
c       the chunks' data with the following mapping between MIR
c       spcode and Miriad spectral window id:
c                 MIR       Miriad
c                  1    ->    1
c                  2    ->    2
c                 ...
c                 20    ->   20
c                 21 skipped
c                 22 skipped
c                 23    ->   21
c                 24    ->   22
c       Thus, the data in Miriad format will have a total
c       of 22 spectral windows instead of 24.
c
c       In addition, spskip=-1 takes the frequency 
c       configuration from that of the first integration
c       assigned by nscans assuming that the frequency 
c       configuration for the rest of integrations does not 
c       change. 
c       
c       For old data sets (such as 2003), spskip=-2003 might be 
c       useful to handle data from an incompleted correlator.
c
c       The default is no skipping in spectral windows.
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
c    jhz 28-sep-05 update the inline doc for vsource.
c    jhz 11-oct-05 add on-line flagging
c    jhz 11-oct-05 add an option to read antenna positions 
c                  from the ASCII file 'antennas'.
c    jhz 13-oct-05 the sma_mirRead.c is implemented
c                  for swapping r with l for the polarization data
c                  observed before 2005-6-10.
c                  also skipping the decoding Doppler velocity
c                  because of the velocity entry in the header
c                  of MIR data appeared to be screwed up.
c    jhz 09-nov-05 add options of noskip.
c    jhz 30-nov-05 update version number according to the
c                  change made in sma_mirRead.c for
c                  storing pointing position in all the cases
c                  rather than only when pointing position
c                  differs from source catalog position
c                  (FITS convention)
c    jhz 05-dec-05 add the inline doc to options oldpol
c                  to explain the two stages in pol state
c                  conversion from MIR data to Miriad convention:
c                  1) before 2004-9-1 and 2) before 2005-6-10.
c    jhz 05-dec-05 Obsoleted options=oldpol.
c    jhz 06-dec-05 add keyword spskip.
c    jhz 30-dec-05 fix  the inconsistence
c                  of the total number of integrations
c                  in the mir header files (in_read and bl_read).
c    jhz 24-jan-06 add options for skipsp=-1
c    jhz 03-feb-06 optimize the memory requirement
c    jhz 08-feb-05 add a feature to handle multiple correlator configu.
c    jhz 06-mar-06 add a feature to handle 2003 data with incompleted
c                  correlator.
c    jhz 18-may-06 implemented hybrid high spectral resolution mode,
c                  allowing presence of empty data chunks.
c    jhz 09-jun-06 fixed a bug in sma_mirRead.c in parsing source if
c                  in the case no source information is given in
c                  mir data (an on-line bug)
c    jhz 12-jun-06 updated version date
c    jhz 09-aug-06 changed a typo in line 346
c    jhz 29-dec-06 implemented handling 400 rx
c    jhz 04-jan-07 implemented reading projectInfo fil
c    jhz 08-jan-07 store chi and chi2
c    jhz 08-jan-07 remove mount=0; back to mount=4 or
c                  sma/mount =  NASMYTH
c    jhz 10-jan-07 add evector
c    jhz 31-jan-07 changed source name length limit from 
c                  8 characters to 16.
c    jhz 07-mar-07 removed redundnt call of juliandate
c                  added percent of file reading in the prompt
c                  message.
c    jhz 07-mar-07 robustly handling antennas file.
c                  obsolete readant in the keyword input. 
c    jhz 06-jun-07 added a bug report message accoding to
c                  the new limits set by SMA hardware.
c    jhz 11-jun-07 fixed a bug in passing the values of nscans array.
c    jhz 12-jun-07 obsoleted single corr config loading mode. 
c    jhz 07-sep-07 added the 'debug' in options.
c    jhz 27-sep-07 fixed initialization problem in sma_mirRead.c
c    jhz 08-nov-07 change the extension of the output file name
c                  in the rx selection of a negative value.
c    jhz 14-nov-07 added a feature to fix the source coordinate
c                  problem in the MIR data
c    jhz 27-nov-07 added a patch to fix the frequency labelling problem
c                  in the old SMA data (before 2007-11-26) with the recipe
c                  described in the SMA operation log # 14505
c    jhz 23-jan-08 fixed a bug in rar2c and decr2c in c program
c   pkgw 05-dec-11 Remove reference to MAXIANT.
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxfiles
        parameter(maxfiles=128)
        character version*(*)
        parameter(version='SmaLod: version 2.11 23-Jan-08')
c
        character in(maxfiles)*64,out*64,line*64, rxc*4
        character msg*64
        parameter(msg='Loading standard SMA data ...')
        integer tno, length, len1
        integer ifile,rxif,nfreq,iostat,nfiles,i
        double precision rfreq
        logical doauto,docross,docomp,dosam,relax,unflag,dohann
        logical dobary,doif,birdie,dowt,dopmps,doxyp,doop
        logical polflag,hires,nopol,sing,circular,linear,oldpol,dsb,
     *          dospc,doengrd,doconjug,dolsr,noskip,mcconfig,nohighspr,
     *          dodebug
        integer fileskip,fileproc,scanskip,scanproc,sb, dosporder
        integer doeng, spskip(2)
	integer rsNCHAN, refant, readant, antid, lIn
        double precision antpos(10*3),xyz(3)
        real vsour
        character fname*64
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
         call keyi('rxif',rxif,-1)
            if(rxif==-2) rxc='_rxh'
            if(rxif==-1) rxc='_rxl'
            if(rxif==0) rxc='_rx0'
            if(rxif==1) rxc='_rx1'
            if(rxif==2) rxc='_rx2'
            if(rxif==3) rxc='_rx3'
c
         if(rxif.lt.-2.or.rxif.gt.3) then
             call output('For data taken after 2006-12-28:')
             call output('rxif = -2 -> 2nd rxif band')
             call output('rxif = -1 -> 1st rxif band')
             call output('rxif =  0 -> 230 band')
             call output('rxif =  1 -> 340 band')
             call output('rxif =  2 -> 400 band')
             call output('rxif =  3 -> 690 band')
             call output('For data taken before 2006-12-28:')
             call output('rxif = -2 -> 1st rxif band')
             call output('rxif = -1 -> 2nd rxif band')
             call output('rxif = 0 -> 230 band')
             call output('rxif = 1 -> 340 band')
             call output('rxif = 2 -> 690 band')
             call output(' ')
             call bug('f','Invalid Receiver ID.')
             end if
c        call mkeyd('restfreq',rfreq,2,nfreq)
        call keyd('restfreq',rfreq,0.0)
        call keyr('vsource', vsour,0.0)
        call keyi('refant',refant,6)
        call getopt(doauto,docross,docomp,dosam,doxyp,doop,relax,
     *    sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,polflag,
     *    hires,nopol,circular,linear,oldpol,dospc,doengrd,doconjug,
     *    dolsr,noskip,mcconfig,nohighspr,dodebug)
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
        call keyi('spskip',spskip(1),0)
        call keyi('spskip',spskip(2),0)
        if(spskip(1).gt.0.and.spskip(2).le.0)
     *  call bug('f','spskip(2) must > 0 if spskip(1) > 0 !')
c        if(spskip(1).lt.0.or.spskip(2).lt.0)
c     *  call bug('f','spskip(1) & spskip(2) must be zero or positive!')
        if(spskip(1).ge.24.or.spskip(2).ge.24)
     *  call bug('f','spskip(1) or spskip(2) must be less than 24!')
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
c alternatively reading the antenna positions from
c the ASCII file antennas
c
       call bug('w',
     *   'Reading antenna positions from ASCII file antennas:')
            fname = in(1)(1:len1(in(1)))//'antennas'
            call txtopen(lIn,fname,'old',iostat)
            if(iostat==0) then
            do i=1,10 ! see limitation below
            call txtread(lIn,line,length,iostat)
            if(iostat==-1) goto 211
            end do
211         readant=i-1
            call txtclose(lIn)         
           if(readant.gt.8) then
           call bug('w', 'Number of antennas exceeded the limit 8.')
           end if
      open(16,file=in(1)(1:len1(in(1)))//'antennas',status='unknown')
            do i=1,readant
            read(16,*) antid,xyz(1),xyz(2),xyz(3)
            antpos(1+(antid-1)*3) = xyz(1)
            antpos(2+(antid-1)*3) = xyz(2)
            antpos(3+(antid-1)*3) = xyz(3)
            end do
            close(16)
            readant=i-1
            do i=1,readant
            write(*,100) i,antpos(1+(i-1)*3),
     *             antpos(2+(i-1)*3),antpos(3+(i-1)*3)
             end do
             else
        call bug('w',
     * 'found no antennas file; try solving antpos from bl vectors...')
         readant =0
             end if
100        format(i2,5x,3(f12.6,2x))

c
c    do both side bands
c
           length=len1(out)
           if(sb.eq.2) then
              dsb=.true.
              sb = 0
              end if
             
555           if(sb.eq.0) out=out(1:length)//rxc(1:4)//'.lsb'
              if(sb.eq.1) out=out(1:length)//rxc(1:4)//'.usb'

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
        call output('  ')
        call output(msg)
        call output('  ')
        ifile = 0
        iostat = 0
        dowhile(ifile.lt.fileskip+fileproc.and.iostat.eq.0)
          ifile = ifile + 1
          if(ifile.le.fileskip)then
            if(nfiles.eq.1)then
              call output('Skipping file '//itoaf(ifile))
              call smaskip(in(1),iostat)
            else
              call output('Ignoring file '//in(ifile))
              iostat = 0
            endif
            if(iostat.ne.0)call bug('f','Error skipping SMA-MIR file')
          else
            call pokeini(tno,dosam,doxyp,doop,dohann,birdie,dowt,
     *      dopmps,dobary,doif,hires,nopol,circular,linear,oldpol,
     *      rsnchan,refant,dolsr,rfreq,vsour,antpos,readant,noskip,
     *      spskip,dsb,mcconfig,nohighspr,dodebug)
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
        line = 'output file = '//out
        call output(line)
        goto 666
        end if
        if(sb.eq.0) then
        sb=1
        line = 'output file = '//out
        call output(line)
        call output('Handling other side band data ...')
        call output(' ')
        goto 555
        end if
        if(dsb) then
        line = 'output file = '//out
        call output(line)
        end if
666     stop
        end
c************************************************************************
        subroutine getopt(doauto,docross,docomp,dosam,doxyp,doop,
     *    relax,sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,
     *    polflag,hires,nopol,circular,linear,oldpol,dospc,doengrd,
     *    doconjug,dolsr,noskip,mcconfig,nohighspr,dodebug)
c
        logical doauto,docross,dosam,relax,unflag,dohann,dobary,doop
        logical docomp,doif,birdie,dowt,dopmps,doxyp,polflag,hires,sing
        logical nopol,circular,linear,oldpol,dospc,doengrd,doconjug
        logical dolsr,noskip,mcconfig,nohighspr,dodebug
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
c    noskip     Do not skip any adta.
c    mcconfig   do multiple correlator configurations.
c    nohighspr  no high spectral resolution mode.
c    debug      to print out the messages indicating what have been
c               done to fix the header problems.
c------------------------------------------------------------------------
        integer nopt
        parameter(nopt=30)
        character opts(nopt)*8
        logical present(nopt)
        data opts/'noauto  ','nocross ','compress','relax   ',
     *            'unflag  ','samcorr ','hanning ','bary    ',
     *            'noif    ','birdie  ','reweight','xycorr  ',
     *            'opcorr  ','nopflag ','hires   ','pmps    ',
     *            'mmrelax ','single  ','nopol   ','circular',
     *            'linear  ','oldpol  ','dospc   ','doengrd ',
     *            'conjugat','lsr     ','noskip  ','mcconfig',
     *            'nohspr  ','debug   '/
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
        noskip  = present(27)
        mcconfig= .not.present(28)
        nohighspr = present(29)
        dodebug = present(30)
c  oldpol obsoleted
        if(oldpol) 
     *  call bug('w', 'Hey, options=oldpol has been obsoleted!')
           oldpol  = .false.
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
c ALTAZ=0.d0,EQUATOR=1.d0,NASMYTH=4.d0,XYEW=3.d0
c Alt-Az mount=0 based on SMA project book
c but the polarization goes extra rotation through the 
c elevation axis
c so sma/mount = NASMYTH or mount=4.d0
c
          call uvputvri(tno,'mount',mount,1)
        endif
        end
c************************************************************************
c************************************************************************
        subroutine pokeini(tno1,dosam1,doxyp1,doop1,
     *          dohann1,birdie1,dowt1,dopmps1,dobary1,
     *          doif1,hires1,nopol1,circular1,linear1,oldpol1,
     *	        rsnchan1,refant1,dolsr1,rfreq1,vsour1,antpos1,
     *          readant1,noskip1,spskip1,dsb1,mcconfig1,
     *          nohighspr1,dodebug1)
c
        integer tno1,rsnchan1,refant1,readant1,spskip1(2)
        logical dosam1,doxyp1,dohann1,doif1,dobary1,birdie1,dowt1
        logical dopmps1,hires1,doop1,nopol1,circular1,linear1,oldpol1
        logical dolsr1,noskip1,dsb1,mcconfig1,nohighspr1,dodebug1
        double precision rfreq1,antpos1(10*3)
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

        double precision dtemp
        double precision lat1,long1,evec1
        logicAl ok
cc jhz
        kstat=1;
        call obspar('SMA','latitude', dtemp, ok)
        lat1=dtemp
        if(.not.ok)call bug('f','Could not get SMA latitude')
        call obspar('SMA','longitude',dtemp,ok)
        long1=dtemp
        if(.not.ok)call bug('f','Could not get SMA longitude')
        call obspar('SMA','evector',dtemp,ok)
        evec1 = dtemp
        if(.not.ok)call bug('f','Could not get SMA evector')

c
        call rspokeinisma(kstat,tno1,dosam1,doxyp1,doop1,
     *  dohann1,birdie1,dowt1,dopmps1,dobary1,doif1,hires1,
     *  nopol1,circular1,linear1,oldpol1,lat1,long1,evec1,rsnchan1,
     *  refant1,dolsr1,rfreq1,vsour1,antpos1,readant1,noskip1,
     *  spskip1,dsb1,mcconfig1,nohighspr1,dodebug1)
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
        subroutine smaskip(in,iostat)
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
        integer scanskip1,scanproc1
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
         scanskip1=scanskip
         scanproc1=scanproc

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
        call rssmaflush(scanskip1, scanproc1, sb, rxif, 
     *       dosporder, doeng, doflppha)
             kstat= 666
         
        call rspokeflshsma(kstat);
c
        jstat =-1;
        call rsmiriadwrite(in,jstat)
        end
c************************************************************************
        subroutine smaeof(jstat)
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
        integer jstat
c
c------------------------------------------------------------------------
        character itoaf*8
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
          smaerr = 'SMA mir Data error: jstat='//itoaf(jstat)
        endif
c
        end
c************************************************************************
        subroutine smaopen(in,jstat)
        character in*(*)
        character*80 file
        integer jstat
c
c External.
c
        character smaerr*32
        file = in
c jstat=-3 -> open the input data file 
        jstat = -3
c jhz 
        call rsmirread(in, jstat)
        if(jstat.ne.0) call bug('w',
     *  'Error opening SMA MIR file: '//smaerr(jstat))
        if(jstat.ne.0)return
        end
c************************************************************************
c************************************************************************
        character*(*) function pcent(frac,total)
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
        real freq
c------------------------------------------------------------------------
        if(freq.lt.15)then
          getjpk = 13
        else if(freq.lt.30)then
          getjpk = 15
        else
          getjpk = 25
        endif
        end
