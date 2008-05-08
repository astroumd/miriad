c************************************************************************
	program bplist
	implicit none
c
c= BpList -- List bandpass gains table 
c& pjt
c: calibration
c+
c     BpList is a Miriad task to list the bandpass gains in a bandpass gain
c     table.
c
c     This routine is specific to CARMA, currently hardcoded for 15 antennas.
c       
c@ vis
c     The input visibility file, containing the gain file to list/massage
c@ options
c     amp      List the amplitude gains: default option
c              The mean, median and rms (about the mean) are reported.
c     phase    List the phase corrections.
c     complex  List complex gains for 10 antennas only (2 lines per soln)
c     all      List all complex gains (one line per antenna per solution
c              for all antennas; lots of output, better than
c              options=complex if you want to grep one one antenna.)
c  
c--
c  History:
c    pjt      7may08 Cloned off gplist.
c                    
c  Bugs and Shortcomings:
c    bplist is hardwired in some places to list 15 antennas! (check options=dyn...)
c    although we're using MAXGANT, there are format statements with
c    usage with 15 or 30 elements. 
c
c    use some of gplist' edit features?
c
c-----------------------------------------------------------------------
	include 'bplist.h'
        character version*(*)
	parameter(version='BpList: version 8-may-08')
	logical docomp,dophas,doall,hexists,doamp
	logical docarma
	character vis*256
	integer ngains,nfeeds,ntau,nants,iostat,nchan,nspect
	integer tVis
c
c  Get the input parameters.
c
      call output(version)
      call keyini
      call keya('vis',vis,' ')
      call GetOpt(doamp,docomp,dophas,doall,docarma)
      call keyfin
      if(vis.eq.' ')call bug('f','An input file must be given')
c
c  Open the visibility file. Use the hio routines, as all we want to get
c  at is items for which the uvio routines have no access anyway.
c
      call hopen(tVis,vis,'old',iostat)
      if(iostat.ne.0)call AverBug(iostat,'Error opening '//vis)

      IF (.not.hexists(tVis,'bandpass')) then
	 call bug('f','No bandpass table present')
      ENDIF

c
c
c  Determine the number of feeds in the gain table.
c
	call rdhdi(tVis,'ngains', ngains, 0)
	call rdhdi(tVis,'nfeeds', nfeeds, 1)
	call rdhdi(tVis,'ntau',   ntau,   0)
	call rdhdi(tVis,'nchan0', nchan,  0)
	call rdhdi(tVis,'nspect0',nspect, 0)

	if(nfeeds.le.0.or.nfeeds.gt.2.or.mod(ngains,nfeeds+ntau).ne.0
     *	  .or.ntau.gt.1.or.ntau.lt.0)
     *	  call bug('f','Bad number of gains or feeds in '//vis)
	nants = ngains / (nfeeds + ntau)
      write(6,*) "Found bandpass entries for ",nants," antennas."
c
c  List/Replace the gains now.
c
	call ReplGain(tVis,
     *        doamp,docomp,dophas,doall,
     *        nfeeds,ntau,nants,nchan,nspect,
     *        docarma)
c
c  Close up everything.
c
	call hclose(tVis)	
	end
c***********************************************************************
       subroutine GetOpt(doamp,docomp,dophas,doall,docarma)
c
	implicit none
	logical doamp,docomp,dophas,doall,docarma
c
c  Get "Task Enrichment Parameters".
c
c  Output:
c    dovec	Replace amplitude gains
c    docomp List complex gains for 6 current ants
c    dozero Zero phase corrections
c    doall  full list of complex gains
c    dophas List phase gains
c    domult Multiply amplitude gains
c    dolimit Impose upper limit on gains
c    doclip Set amp gain to zero if outside absolute "normal" range
c    dosigclip Set amp gain to zero if outside relative "normal" range
c    doforce Force use of zeroes in jyperk array.
c    docarma if not true, dynamically assigns the array size in the printout.
c    doaddph if true, add/replace phases instead of amps
c-----------------------------------------------------------------------
      integer nopts
      parameter(nopts=6)
      logical present(nopts)
      character opts(nopts)*8
      data opts 
     *  /'amp     ','complex ','all     ','phase   ',
     *   'force   ','dynsize '/
c
      call options('options',opts,present,nopts)
      doamp = present(1)
      docomp = present(2)
      doall = present(5)
      dophas = present(6)
      docarma = .true.
c
      end
c************************************************************************
	subroutine AverBug(iostat,message)
c
	implicit none
	integer iostat
	character message*(*)
c
c  Give an error message, and bugger off.
c------------------------------------------------------------------------
	call bug('w',message)
	call bugno('f',iostat)
	end
c***********************************************************************
      subroutine ReplGain(tVis,doamp,docomp,dophas,doall,
     *              nfeeds,ntau,nants,nchan,nspect,
     *              docarma)
c
      implicit none
      include 'bplist.h'
      integer MAXSOLS,MAXGAINS
      parameter(MAXSOLS=10000,MAXGAINS=3*MAXSOLS*MAXGANT)
      logical doamp,docomp,dophas,doall
      integer nfeeds,ntau,nants,tVis,jant(MAXGANT),jind(3600)
      integer nchan,nspect, idx(MAXGANT),i,j,k
      real MeanGain(MAXGANT),r2d,
     *     GainArr(MAXGANT,3600),
     *     MednGain(MAXGANT), MedArr(3600), GainRms(MAXGANT)
      logical doMed, docarma
c
c  Read and write the gains, and list gains and replace amplitudes
c
c  Bandpass gains are stored Gains(Chan,Ant), which is the other
c  way around from Amp gains, which are Gains(Ant,Time)
c
c------------------------------------------------------------------------
        complex Gains(MAXGAINS)
	double precision freq(MAXSOLS),freq2(2)
	integer off,pnt,tGains,tFreqs,iostat,ngains,nsize
	character ctime*8,msg*128
        integer igains,nschan
c
c  Externals.
c
	integer hsize

c
c  Data 
c
	data doMed /.false./

c
c  Open the bandpass table and read them all in one shot
c
	call haccess(tVis,tGains,'bandpass','read',iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error opening the bandpass')
	nsize = hsize(tGains)-8
	if (nsize .ne. 8*nants*(nfeeds+ntau)*nchan) then
	   call bug('f','Bandpass table odd size')
        endif
	call hreadr(tGains,Gains,8,nsize,iostat)
	if(iostat.ne.0)call Averbug(iostat,'Error reading bandpass')

	ngains = nants*(nfeeds+ntau)
	pnt = nchan
	r2d=180.0/3.14159

	do j=1,nants
	   idx(j) = (j-1)*nchan
	enddo

c
c  Close up.
c
	call hdaccess(tGains,iostat)
	if(iostat.ne.0)call AverBug(iostat,
     *       'Error closing bandpass table')



c
c  Open the frequency table
c
	call haccess(tVis,tFreqs,'freqs','read',iostat)
	if (iostat.ne.0) call AverBug(iostat,'Error opening freqs')

	off = 8
	k = 0
	do i=1,nspect
	   call hreadi(tFreqs,nschan,off,4,iostat)
	   if (iostat.ne.0) call AverBug(iostat,'Error-1 reading freqs')
	   off = off + 8
	   call hreadd(tFreqs,freq2,off,2*8,iostat)
	   if (iostat.ne.0) call AverBug(iostat,'Error-2 reading freqs')
	   off = off + 2*8
	   do j=1,nschan
	     k = k + 1
	     freq(k) = freq2(1) + (j-1)*freq2(2)
	   enddo
	enddo
	if (k.ne.nchan) call bug('f','Channel counting error')

	call hdaccess(tFreqs,iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error closing freqs table')
c
c  
c  Now list the values read
c

      if (docomp) then
         call output('The complex gains listed in the table are:')
         if((ngains.gt. 8).or.docarma) then
     	    msg = '  Freq     Ants 1/9     Ants 2/10     ' //
     *	          'Ants 3/11    Ants 4/12    Ants 5/13  '  //
     *	          'Ants 6/14    Ants 7/15    Ant  8'
	 else
	    msg = '  Freq     Ants 1       Ants 2        ' //
     *	          'Ants 3       Ants 4       Ants 5     ' //
     *	          'Ants 6       Ants 7       Ant  8'
	 end if
         call output(msg)
         do i=1,nchan
	    write(ctime,'(f8.4)') freq(i)
	    if(.not.docarma) then
	       if(ngains.gt.8) then
		  write(msg,95) ctime, 
     *                  (Gains((i-1)*nants+igains), igains=1,8)
	       else
		  write(msg,95) ctime,
     *                  (Gains((i-1)*nants+igains), igains=1,ngains)
	       end if
	       call output(msg)
	       if(ngains.gt.8) then
		  write(msg,95) '   ',
     *               (Gains((i-1)*nants+igains), igains=9,ngains)
	       end if
	    else
	       write(msg,95) ctime,  Gains((i-1)*nants+1),
     *                          Gains((i-1)*nants+2),
     *                          Gains((i-1)*nants+3),
     *                          Gains((i-1)*nants+4),
     *                          Gains((i-1)*nants+5),
     *                          Gains((i-1)*nants+6),
     *                          Gains((i-1)*nants+7),
     *                          Gains((i-1)*nants+8)
	       call output(msg)
	       write(msg,95) '   ',  Gains((i-1)*nants+9),
     *                          Gains((i-1)*nants+10),
     *                          Gains((i-1)*nants+11),
     *                          Gains((i-1)*nants+12),
     *                          Gains((i-1)*nants+13),
     *                          Gains((i-1)*nants+14),
     *                          Gains((i-1)*nants+15)
	       call output(msg)
	    end if
         enddo
      else if (doall) then
         call output('The bandpass gains listed in the table are:')
         do i=1,nchan
	    write(ctime,'(f8.4)') freq(i)
         write(msg,96) ctime,'Ant  ',1,'   gain = ',Gains(idx(1)+i)
            call output(msg)
            do j=2,nants
               write(msg,97) 'Ant  ',j,'   gain = ',Gains(idx(j)+i)
               call output(msg)
            enddo
         enddo
      else if (dophas) then
         call output('The bandpass phases listed in the table are:')
         msg =  'Freq  Anten 1    2    3    4' //
     *          '    5    6    7    8    9   10' //
     *          '   11   12   13   14   15'
         call output(msg)
         do i=1,nchan
	    write(ctime,'(f8.4)') freq(i)
            k=(i-1)*nants
            if(.not.docarma) then
	       write(msg,198) ctime,(nint(r2d*
     *                atan2(AImag(Gains(k+igains)),
     *                      Real(Gains(k+igains)))),igains=1,ngains)
            else
	       write(msg,198) ctime,(nint(r2d*
     *	       atan2(AImag(Gains(i+idx(j) )),
     *	              Real(Gains(i+idx(j) )))),j=1,15)
            end if
            call output(msg)
         enddo
      else if (doamp) then
         do j=1,nants
            MeanGain(j)=0.0
            GainRms(j)=0.0
            jant(j)=0
         enddo
	 call output('The bandpass amplitudes listed '//
     *               'in the table are:')
	 msg = '  Freq    Ant 1  Ant 2  Ant 3  Ant 4 ' //
     *         ' Ant 5  Ant 6  Ant 7  Ant 8  Ant 9  Ant10' //
     *         '  Ant11  Ant12  Ant13  Ant14  Ant15 '
	 call output(msg)
	 do i=1,nchan
	    write(ctime,'(f8.4)') freq(i)
	    if(.not.docarma) then 
	       write(msg,199) ctime,
     *                (abs(Gains((i-1)*nants+igains)), igains=1,ngains)
	    else
	       write(msg,199) ctime, (abs(Gains(i+idx(j))),j=1,15)
	    end if
	    call output(msg)
	    do j=1,nants
	       if (abs(Gains(i+idx(j))).gt.0.0) then
		  MeanGain(j)=MeanGain(j)+abs(Gains(i+idx(j)))
		  GainRms(j)=GainRms(j)+abs(Gains(i+idx(j)))**2
		  jant(j)=jant(j)+1
		  GainArr(j,jant(j))=abs(Gains(i+idx(j)))
	       endif
	    enddo
	 enddo
	 do j=1,nants
	    if (jant(j).gt.0) MeanGain(j)=MeanGain(j)/jant(j)
	    if (jant(j).gt.2) then
	       doMed = .true.
	       do k=1,jant(j)
		  MedArr(k)=GainArr(j,k)
	       enddo
	       call sortidxr( jant(j), MedArr, jind)
	       MednGain(j)=MedArr(jind(int(jant(j)/2)))
	       GainRms(j)=sqrt((GainRms(j)-
     *                    jant(j)*MeanGain(j)*MeanGain(j))/(jant(j)-1))
	    else
	       GainRms(j)=0.0
	    endif
	 enddo
	 write(msg,197) '------------------------------------',
     &               '------------------------------------'
	 call output(msg)
         if(.not.docarma) then
	    write(msg,199) 'Means:  ',(MeanGain(igains),igains=1,ngains)
	 else
	    write(msg,199) 'Means:  ',MeanGain(1),MeanGain(2),
     *              MeanGain(3),MeanGain(4),MeanGain(5),MeanGain(6),
     *              MeanGain(7),MeanGain(8),MeanGain(9),MeanGain(10),
     *           MeanGain(11),MeanGain(12),MeanGain(13),MeanGain(14),
     *                                                  MeanGain(15)
	 end if
	 call output(msg)
	 if (doMed) then
	    if(.not.docarma) then
	       write(msg,199) 'Medians:',(MednGain(igains),
     *                                      igains=1,ngains)
	    else
	       write(msg,199) 'Medians:',MednGain(1),MednGain(2),
     *                MednGain(3),MednGain(4),MednGain(5),MednGain(6),
     *                MednGain(7),MednGain(8),MednGain(9),MednGain(10),
     *           MednGain(11),MednGain(12),MednGain(13),MednGain(14),
     *                                                  MednGain(15)
	    end if
	    call output(msg)
	    if(.not.docarma) then
	       write(msg,199) 'Rms:    ', (GainRms(igains), 
     *                                      igains=1,ngains)
	    else
	       write(msg,199) 'Rms:    ', GainRms(1),GainRms(2),
     *                GainRms(3),GainRms(4),GainRms(5),GainRms(6),
     *                GainRms(7),GainRms(8),GainRms(9),GainRms(10),
     *             GainRms(11),GainRms(12),GainRms(13),GainRms(14),
     *                                                 GainRms(15)
	    end if
	    call output(msg)
	 endif
	 write(msg,197) '------------------------------------',
     *                  '------------------------------------'
	 call output(msg)
      endif


199   format(a8,15(1x,f6.2))
198   format(a8,15i5)
197   format(a36,a36)
97    format(10x,a,i2,a,f9.3,f9.3)
96    format(a8,2x,a,i2,a,f9.3,f9.3)
95    format(a8,1x,8(f5.2,1x,f5.2,2x))
	end
c************************************************************************
