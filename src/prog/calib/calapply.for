c************************************************************************
        program calapply
C
C   Read in a uv data set, applies gains and passband calibration
C   and writes out a new set of calibrated data.
c   
c   Known definciency:
C
c   The gainset polynomials are read twice if pass-set also supplied.
c   Reason is that passset may overwrite time0 etc. in /CALSUBS/
c   This silly thing has to be fixed in next major calibration
c   overhaul.
c
C  History:
c    bs   Dark-ages Original version.
c    rjs  24oct89   Fixed a call to sign function where it had mixed
c		    argument types.
c    lgm  <15may90  Lot's of goodlies and badlies
c    pjt  15may90   fixed the badlies
c    lgm  20jun90   Fixed some more badies. Applying gcal and pcal
c                   together should work. 
c    pjt  27jun90   made it set the flags if no validity in evalpoly()
c    pjt  13jul90   report some statistic about good and bad scans
c    lgm  15jul90   added flagbad keyword
c    pjt  30jul90   " -> '
c    pjt  28oct90   inline doc
c    pjt  29nov90   findbase
c    lgm  27jan91   allowed flaged extrapolated data to be calibrated
c                   and improved history
c    pjt  31jan91   catch when evalpoly when it returns valid=-1 - hisappnd
c    bpw  11feb91   Add standard keyword documentation
c    pjt  19mar91   fixed time0 offset bug - Lee ows me Taco Tuesday for this!
c		    also added some more goodies - multiple input files
c    pjt   6may91   fixed bug with not the same base() - getpoly gets them
c    pjt  16may91   new doc
c    pjt  10jul91   write out baseline based, but wideband averaged
c		    jy/k value into the 'jyperk' uv variable
c    pjt  27jul91   fixed bug when no gcal given: getpoly() read too late in 
c                   apply()
c    mchw 06nov91   Fix for nochannel data. Deja vu. Test for nspect=0
c    pjt  09dec91   the breakpoints were never read in!!!
c		    this resulted in some bad extrapolations - (Ted Yu)
c	  30jan92   added parameter to hisappn() 
c << mchw 14apr93   Made fuzzy 0.5 GHz. Shorter doc; removed included docs. >>>
c   lgm/pjt apr93   fixed problems for mode 4 with new array
c		    by splitting up the windows -> 2x polynomials
c		    Note Mel's fix eps from 5 to 500 Mhz is dangerous,
c		    since it will likely cause interpolation into the wrong 
c		    spectral windows - a value of 20Mhz may be ok though
c    pjt   9jul93   documented apr93 and fixed my year typo on 30jan92!
c    pjt  24oct94   new correlator setup required more slots (16)
c    pjt  13dec95   allow missing antennae for passband calibrator (rjr)
c    pjt  22oct96   moved MAXWIDE up to the include files
c
c  WARNING: Known bugs
c    lgm  27jan91   if only wideband data present but channel window
c                   parameters are present, data are written twice;
c                   once as wcorr and once as corr. Only wcorr are correct.
c                   If no window information are present, program bombs.
c
c
c------ Inline doc (retrieved with doc to a .doc file) ----------------c
c
c= calapply - Apply gain and passband corrections producing calibrated data
c& lgm
c: calibration
c+
c   CALAPPLY applies gain and passband corrections producing an output
c   calibrated dataset. The input dataset is untouched. Gains and
c   passband solutions can be applied jointly or independently. Data
c   outside the valid time range of gains fits may by flagged bad.
c@ vis
c   Input UV dataset(s) for calibration. Although multiple input datasets
c   are allowed, use only related data that are meant for INVERT to be
c   mapped. No default.
c@ gcal
c   Name of dataset with gain calibration fits. This must be a dataset
c   produced by calmake. If supplied, a sideband averaged, but baseline
c   dependent gain (in Jy/K) is also written to the output dataset.
c   Default is blank and results in no gain calibration.
c@ pcal
c   Name of dataset with passband calibration fits. This must be a 
c   dataset produced by passmake. 
c   Default is blank and results in no passband calibration.
c@ flagbad
c   Two element true/false parameter for controlling flagging of data
c   beyond range of validity of amplitude and phase gains fits. If 
c   flagbad=true,true, data outside valid time range of gains
c   fits will be flagged bad (although the data are still calibrated
c   using extrapolation). If flagbad=false,false, no data are flagged
c   bad. 
c   Default is flagbad=true,true.
c@ select
c   Standard uvdata selection. Default is all data.
c@ line
c   Standard line selection. Default is all available channels, 
c   wide and narrow.
c   Note: there is a problem when input data has only wide band
c   data.
c@ out
c   Name of output dataset for calibrated data. No default.
c-----------------------------------------------------------------------

        INTEGER   MAXSELS,MAXFILE
        PARAMETER (MAXSELS = 100)
        PARAMETER (MAXFILE = 10)
	CHARACTER PVERSION*(*)
	PARAMETER (PVERSION='Version 22-oct-96')

        include 'caldefs.h'
        include 'calapply.h'
        include 'calsubs.h'

        INTEGER   tin, tout,inpass,iwin,numchan,nwide,nfile,ifile
        REAL      sels(maxsels),start,step,width,jyperk
	CHARACTER inset(MAXFILE)*60, outset*60, gainset*60, passset*60
        CHARACTER line*128,linetype*20,num*1,code(MAXSLOT)*4
	LOGICAL   gainflag, passflag, ampflag, phaflag, split
        INTEGER   len1, i

        INTEGER pchan(MAXWIN),pwins,flagbad(2)
        DOUBLE PRECISION pfstart(MAXWIN),pfend(MAXWIN)
        DOUBLE PRECISION pdelfreq(MAXWIN)
        COMMON /passi/ pwins,pchan,flagbad
        COMMON /passd/ pfstart,pfend,pdelfreq
c-----------------------------------------------------------------------
	CALL output('CALAPPLY: '//pversion)
c
c   Call key routines to get user input
c
	CALL keyini
	CALL mkeyf( 'vis', inset, MAXFILE,nfile)
	CALL keyf( 'gcal', gainset, ' ' )
	CALL keyf( 'pcal', passset, ' ')
c * Data flagging control parameter
	CALL keyl('flagbad',ampflag,.TRUE.)
	CALL keyl('flagbad',phaflag,.TRUE.)
	flagbad(1) = 1
	IF(.NOT.ampflag) THEN
	   flagbad(1) = 0
	   CALL output(' Allowing extrapolation of amp gains fit')
	ENDIF
	flagbad(2) = 1
	IF(.NOT.phaflag) THEN
	   flagbad(2) = 0
	   CALL output(' Allowing extrapolation of phase gains fit')
	ENDIF
c * UVselection on input file
        CALL selinput('select',sels,maxsels)
c * Linetype selection on input file
	CALL keya('line',linetype,'unknown')
	CALL keyi('line',numchan,0)
	CALL keyr('line',start,1.0)
	CALL keyr('line',width,1.0)
	CALL keyr('line',step,width)
c * Visibility output file        
        CALL keya( 'out', outset, ' ' )
      CALL keyfin
c * Some more error checking before we're off
      IF (nfile.LT.1) CALL bug('f','No input datasets specified: vis=')
      IF(outset .eq. ' ') CALL bug('f',
     *                        'No output data set specified: out=')
      IF(gainset.EQ.' ' .AND. passset.EQ.' ') CALL bug('f',
     *                'No calibration set(s) specified; gcal=, pcal=')
      calcntg = 0
      calcntb = 0
c-----------------------------------------------------------------------
      DO ifile=1,nfile
C
C   Open input data sets for read - also set select/line massage 
C
	 CALL uvopen(tin, inset(ifile), 'old')
         CALL uvselect(tin,'clear',0.0d0,0.0d0,.TRUE.)
         CALL selapply(tin,sels,.TRUE.)
	 IF(linetype .ne. 'unknown') THEN
	    CALL uvset(tin,'data',linetype,numchan,start,width,step)
	 ENDIF
         IF (ifile.EQ.1) THEN
            line=' Reading data from: '//
     *                  inset(ifile)(1:len1(inset(ifile)))
         ELSE
            line=' Reading more data from: '//
     *                  inset(ifile)(1:len1(inset(ifile)))
         ENDIF
         CALL output(line)
C-----------------------------------------------------------------------
C   If not done, open output data set for write of calibrated data set 
C
         IF (ifile.EQ.1) THEN
            CALL uvopen(tout, outset, 'new')
            CALL hisopen(tout,'append')
         ENDIF

C-----------------------------------------------------------------------
C   Open gains calibration file if it is called for 
C   ALso check that polys are appropriate - if not change gainflag to false
C
         IF (ifile.EQ.1) THEN
	    IF(gainset .ne. ' ') THEN
	       gainflag =.TRUE. 
               line = ' Reading gain fits from: '// gainset
               CALL output(line)
               CALL readbrk( gainset )
	       CALL getpoly( gainset )
 	    ELSE
               gainflag = .FALSE.
	       call output(' No gains calibration file specified')
	    ENDIF
         ENDIF
C-----------------------------------------------------------------------
C   Open passband calibration file if it is called for
C
         IF (ifile.EQ.1) THEN
	    IF(passset .EQ.  ' ') THEN
               passflag = .FALSE.
               call output(' No passband calibration file specified')
            ELSE
               line = ' Reading passband from: ' // passset
               call output(line)
               passflag = .TRUE.
               call uvopen(inpass,passset,'old')
               call uvread(inpass,preamble,data,flags,maxchan,nread)
               call uvgetvri(inpass,'nspect',pwins,1)
               call uvgetvrd(inpass,'sfreq',pfstart,pwins)
               call uvgetvrd(inpass,'sdf',pdelfreq,pwins)
               call uvgetvri(inpass,'nschan',pchan,pwins)
               call rsplit(inpass,split)
               call uvclose(inpass)
               if(split) then
                 do i=1,pwins
                    pchan(2*(pwins+1-i))   = pchan(pwins+1-i)/2
                    pchan(2*(pwins-i)+1)   = pchan(pwins+1-i)/2
c                   starwin(2*(pwins-i)+1) = starwin(pwins+1-i)
c                   starwin(2*(pwins+1-i)) = starwin(pwins+1-i)+
c    1                                       pchan(pwins+1-i)/2
                    pdelfreq(2*(pwins+1-i))= pdelfreq(pwins+1-i)
                    pdelfreq(2*(pwins-i)+1)= pdelfreq(pwins+1-i)
                    pfstart(2*(pwins-i)+1) = pfstart(pwins+1-i)
                    pfstart(2*(pwins+1-i)) = pfstart(pwins+1-i)+
     1                    pdelfreq(pwins+1-i)*pchan(pwins+1-i)/2
                 enddo
                 pwins = 2*pwins
                 do i=1,pwins,2
                    write(num,'(i1)') (i/2 + 1)
                    code(i)   = 'AL'//num//'A'
                    code(i+1) =  'AL'//num//'B'
                 enddo
               else
                 do i=1,pwins
                    if (i.le.pwins/2) then
                       write(num,'(i1)') i
                       code(i) = 'AL'//num//' '
                    else
                       write(num,'(i1)') i-pwins/2
                       code(i) = 'AU'//num//' '
                    endif
                 enddo
               endif
               DO iwin=1,pwins
                 pfend(iwin) = pfstart(iwin) + pdelfreq(iwin)*
     1                           (pchan(iwin)-1)
               ENDDO
            ENDIF
         ENDIF
C-----------------------------------------------------------------------
C check that passband fit is appropriate - set passflag correctly
C-----------------------------------------------------------------------
C set uv tracking on all variables so uvcopy will work

         CALL trackall(tin)
C
         IF (ifile.EQ.1) THEN
	    line =' Writing data to: ' // outset
         ELSE
            line =' Appending more data to: ' // outset
         ENDIF
	 CALL output(line)
c-----------------------------------------------------------------------
C   Main loop which calls subroutines to read data record,  apply
C   calibration,  and write data record to new file
C
	 nread = 1
	 DO WHILE(nread.GT.0)
            CALL uvread(tin,preamble,data,flags,maxchan,nread)
            IF (nread.GT.0) THEN
	       call uvgetvri(tin,'nwide',nwide,1)
               if(nwide .gt. 0) then
                  CALL uvwread(tin,wcorr,wflags,MAXWIDE,nwcorr)
	       else
	          nwcorr = 0
	       endif
	       CALL apply(tin,gainflag,gainset,passflag,passset,code,
     1                         jyperk)
               CALL uvcopyvr(tin, tout)
               IF (jyperk.GT.0) THEN
                    CALL uvputvrr(tout,'jyperk',jyperk,1)
c                    write(*,*) 'adding Jy/K=',jyperk
               ENDIF
               IF(nwcorr .gt. 0) 
     *              CALL uvwwrite(tout,wcorr,wflags,nwcorr)
               CALL uvwrite(tout,preamble,data,flags,nread)
            ENDIF
	 ENDDO
c-----------------------------------------------------------------------
C   Append the history from input to that of output dataset
C
          CALL hisappn(tout,inset(ifile),.FALSE.)

c
c  close open uvfile if this is NOT the last one. The last one will
c  be close later on, after history has been finalized
         IF (ifile.LT.nfile) CALL uvclose(tin)
      ENDDO
c ---  end of big reading loop -----------------------------------------
c
C Finally finish off with appending local history what happened
C here.
c
      IF(gainflag) CALL hisappn(tout,gainset,.TRUE.)
      IF(passflag) CALL hisappn(tout,passset,.TRUE.)
      CALL hiswrite(tout,'CALAPPLY: '//pversion)
      CALL hisinput(tout,'CALAPPLY')
      WRITE(line,
     *	  '(''CALAPPLY: '',I6,'' good visibilities'')') calcntg
      CALL output(line)
      CALL hiswrite(tout,line)
      WRITE(line,
     *	  '(''CALAPPLY: '',I6,'' visibilities flagged bad'')') calcntb
      CALL output(line)
      CALL hiswrite(tout,line)
      CALL hisclose(tout)
C
c-----------------------------------------------------------------------
C   Close open files and then exit
C
      CALL uvclose(tin)
      CALL uvclose(tout)

      END
c***********************************************************************
      SUBROUTINE apply(tin,gainflag,gainset,passflag,passset,code,
     1              jyperk)
c
      INTEGER   tin
      CHARACTER gainset*(*),passset*(*)
      LOGICAL   gainflag,passflag
      REAL      jyperk
C
C   Apply calibration solutions to data 
C
        include 'caldefs.h'
        include 'calsubs.h'
        include 'calapply.h'
 
        character mesg*80,code(MAXSLOT)*4
        integer b, bl, nwins, starwin(MAXWIN),bb
        integer valid,valid1,valid2,valid3,valid4
        integer chanwin(MAXWIN),lochan,hichan,ic,iwin,findbase,i
        real    evalpoly,time
        real    lsbamp, usbamp, lsbphi, usbphi
        double precision starfreq(MAXWIN), delfreq(MAXWIN),
     1          oldfreq(MAXWIN),olddel(MAXWIN),sum,day0
        complex factor(MAXBASHC,MAXCHAN),lsb,usb,pfactor
        save    factor,oldfreq,olddel

        integer pchan(MAXWIN),pwins,flagbad(2) 
        double precision pfstart(MAXWIN),pfend(MAXWIN),pdefreq(MAXWIN) 
        common /passi/ pwins,pchan,flagbad
        common /passd/ pfstart,pfend,pdefreq
 
        bl = preamble(4)
        if( bl / 256 .gt. mod( bl, 256 ) ) then
           bl = 256 * mod( bl, 256 ) + bl / 256
           preamble(4) = bl
           do ic=1,nread
              data(ic) = conjg(data(ic))
           enddo
	   if(nwcorr .gt. 0) then
              do ic=1,nwcorr
                 wcorr(ic) = conjg(wcorr(ic))
              enddo
	   endif
        endif

c---  moved code down 

      call uvrdvri(tin,'nspect',nwins,0)
      if(nwins.gt.0)then
        call uvgetvri(tin,'ischan',starwin,nwins)
        call uvgetvri(tin,'nschan',chanwin,nwins)
        call uvgetvrd(tin,'sfreq',starfreq,nwins)
        call uvgetvrd(tin,'sdf',delfreq,nwins)
        sum = 0.0
	do i=1,nwins
           sum = sum + abs(starfreq(i)-oldfreq(i))
           sum = sum + abs(delfreq(i) - olddel(i))
           oldfreq(i) = starfreq(i)
           olddel(i)  = delfreq(i)
        enddo
        if(abs(sum) .gt. 1.0e-3) then
           if(passflag) then
              call getpoly(passset)
c PJT trick
	      if(gainflag) call getpoly(gainset)
              call passcor(tin,code,factor)
           else
              do ic=1,nread
                do bb=1,nbl
                  factor(bb,ic) = cmplx(1.0,0.0)
                enddo
              enddo
           endif
        endif
      endif

c begin moved
        b  = findbase(bl,base,nbl)
        if( b .eq. 0 .AND. gainflag) then
            write(mesg,'(''Unexpected baseline '',I5)') bl
	    call bug( 'f', mesg)
        endif
c end moved

	day0 = time0
        IF(gainflag) THEN
           time = preamble(3) - day0
           lsbamp = evalpoly( time, 'ALW?', base(b), valid1 )
           IF (valid1.LT.0) valid1=0
           lsbphi = evalpoly( time, 'PLW?', base(b), valid2 )
           IF (valid2.LT.0) valid2=0
           usbamp = evalpoly( time, 'AUW?', base(b), valid3 )
           IF (valid3.LT.0) valid3=0
           usbphi = evalpoly( time, 'PUW?', base(b), valid4 )
           IF (valid4.LT.0) valid4=0
           lsb = lsbamp*cmplx(cos(lsbphi),-sin(lsbphi))
           usb = usbamp*cmplx(cos(usbphi),-sin(usbphi))
           valid = flagbad(1)*valid1 + flagbad(2)*valid2
     1		 + flagbad(1)*valid3 + flagbad(2)*valid4
           IF(flagbad(1)*valid1 + flagbad(1)*valid3.EQ.0) THEN
              jyperk = 0.5*(lsbamp+usbamp)
           ELSE
              jyperk = -1.0
           ENDIF
        ELSE
           lsb = cmplx(1.0,0.0)
           usb = cmplx(1.0,0.0)
           valid = 0
           jyperk = -1.0
        ENDIF

        IF (valid.NE.0) THEN
c           * make current UV stuff invalid, by setting all flags FALSE
	  if(nwins.gt.0)then
            DO i=1,MAXCHAN
                flags(i) = .FALSE.
            ENDDO
	  endif
            DO i=1,nwcorr
                wflags(i) = .FALSE.
            ENDDO
            calcntb = calcntb + 1
        ELSE
            calcntg = calcntg + 1
        ENDIF

	if(nwcorr .gt. 0) then
           do i = 1, nwcorr, 2
              wcorr(i) = wcorr(i) * lsb
           enddo
           do i = 2, nwcorr, 2
              wcorr(i) = wcorr(i) * usb
           enddo
	endif

	if(nwins.gt.0)then
         do iwin = 1,nwins
           lochan = starwin(iwin)
           hichan = starwin(iwin)+chanwin(iwin)-1
           do ic=lochan,hichan
              IF (b.GT.0) THEN
                  pfactor = factor(b,ic)
              ELSE
                  pfactor = CMPLX(1.0,0.0)
              ENDIF
              if(delfreq(iwin) .lt. 0.0) then
                 data(ic) = lsb*data(ic)*pfactor
              else
                 data(ic) = usb*data(ic)*pfactor
              endif
           enddo
         enddo
	endif
 
      END
C***********************************************************************
      SUBROUTINE passcor(inset,code,factor)
      include 'caldefs.h'
      include 'calsubs.h'
      INTEGER inset
      COMPLEX factor(MAXBASHC,MAXCHAN)
c
c
      INTEGER iwin,nwins,ic,starwin(MAXWIN),chanwin(MAXWIN)
      INTEGER passwin,lowin,hiwin,b,valid
      REAL dfreq,evalpoly,amp,pha
      DOUBLE PRECISION starfreq(MAXWIN),delfreq(MAXWIN)
      DOUBLE PRECISION eps, freq
      CHARACTER acode*4,pcode*4,code(MAXSLOT)*4

      INTEGER fuzzy

      INTEGER pchan(MAXWIN),pwins,flagbad(2)
      DOUBLE PRECISION pfstart(MAXWIN),pfend(MAXWIN),pdelfreq(MAXWIN)
      COMMON /passi/ pwins,pchan,flagbad
      COMMON /passd/ pfstart,pfend,pdelfreq
      DATA eps / 0.05d0 /

      CALL uvgetvri(inset,'nspect',nwins,1)
      CALL uvgetvri(inset,'ischan',starwin,nwins)
      CALL uvgetvri(inset,'nschan',chanwin,nwins)
      CALL uvgetvrd(inset,'sfreq',starfreq,nwins)
      CALL uvgetvrd(inset,'sdf',delfreq,nwins)

      DO iwin = 1,nwins
           lowin =  starwin(iwin)
           hiwin = starwin(iwin)+chanwin(iwin)-1
           do ic=lowin,hiwin
              freq = starfreq(iwin) + (ic-lowin)*delfreq(iwin)
c              passwin = fuzzy(freq,pfstart,pfend,eps,pwins)
              passwin = iwin
              if(passwin .eq. 0) call bug('f',
     *         'Source channel freqs not within passband cal')
              acode = code(passwin)
              pcode = code(passwin)
              pcode(1:1) = 'P'
              do b=1,nbl
                 dfreq = freq - pfstart(passwin)
                 amp = evalpoly(dfreq,acode,base(b),valid)
                 pha = evalpoly(dfreq,pcode,base(b),valid)
                 factor(b,ic) = amp * cmplx(cos(pha),sin(pha))
                 factor(b,ic) = 1.0/factor(b,ic)
              enddo
           enddo
c           write(*,*) 'debug: ',iwin,passwin,freq,pfstart,pfend,eps
        enddo
        END
C***********************************************************************
      SUBROUTINE trackall(inset)
      INTEGER inset
c
c   Marks all variable in input data set for copying to output
c   data set. Assumes that the dataset is already open and at
c   begining.
c
        INCLUDE 'caldefs.h'
        INCLUDE 'calapply.h'

        INTEGER ivar,item,iostat
        CHARACTER varname*11
        LOGICAL eof

        CALL uvread(inset,preamble,data,flags,maxchan,nread)
        CALL haccess(inset,item,'vartable','read',iostat)

        do 100 ivar=1,500
           call hreada(item,varname,eof)
           if(eof) go to 125
	   if(varname(3:6).eq.'corr' .or.
     1               varname(3:7).eq.'wcorr') goto 100
           call uvtrack(inset,varname(3:10),'c')
  100   continue
  125   continue
        CALL hdaccess(item,iostat)
        CALL uvrewind(inset)
      END
C***********************************************************************
      INTEGER FUNCTION fuzzy(freq,passbeg,passend,eps,pwins)
      INTEGER pwins
      DOUBLE precision freq,passbeg(*),passend(*),eps
c
	INTEGER jwin, minwin
	DOUBLE precision xmin, xmax, xtest
c
c   return window number if freq is inside the range of a window
c
        fuzzy = 0
	DO jwin = 1,pwins
           IF(passbeg(jwin) .lt. passend(jwin)) THEN
              xmin=passbeg(jwin)
              xmax=passend(jwin)
           ELSE
              xmin=passend(jwin)
              xmax=passbeg(jwin)
           ENDIF
           IF(freq .ge. xmin .and. freq .le. xmax) fuzzy = jwin
	ENDDO
c
c   return the window number of the closest window if freq is not
c       within a window
c
	IF(fuzzy .eq. 0) THEN
	   xmin = 1.0e11
           DO jwin = 1,pwins
              xtest = abs(passbeg(jwin)-freq)
              IF(xtest .lt. xmin) THEN
                 xmin = xtest
                 minwin = jwin
              ENDIF
              xtest = abs(passend(jwin)-freq)
              IF(xtest .lt. xmin) THEN
                 xmin = xtest
                 minwin = jwin
              ENDIF
           ENDDO
        ENDIF
        IF(eps .gt. xmin) fuzzy = minwin
      RETURN
      END
