c************************************************************************
        program bpsel
        implicit none
c
c= BPSEL -- Select a subset of bandpass solutions.
c& tw
c: calibration
c+
c@ vis
c       The name of the input data-set. This will normally be a visibility
c       data-set. No default.
c@ fmhz
c       Required frequency resolution of bandpass soln in MHz.  Only 
c       windows that match this criterion are kept.
c@ tol
c       Fractional tolerance for a frequency resolution match.
c       Default is 0.25, so frequency resolution ranging from 75% to
c       125% of fmhz is allowed.
c--
c  History:
c  Bugs:
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer maxGains
        parameter(maxGains=2*MAXCHAN*MAXANT)
        character version*(*)
        parameter(version='BPSEL: version 2008-May-06')
        character vis*80,line*80
        integer tIn,nschan,nspect,iostat,item,off,i,j,ifeed,iant
        integer ispect,nchan2,nchan,ntau,nfeeds,ngains,nants
        integer nschan_save(MAXWIN),newch(maxGains)
        double precision freqs(2),fmhz
        double precision freq1_save(MAXWIN),freq2_save(MAXWIN)
        real tol
        complex Gains(maxGains),Gains2(maxGains)
c
c  Get the user parameters.
c
        call output(version)
        call keyini
        call keya('vis',vis,' ')
        if(vis.eq.' ')call bug('f','Input data-set must be given')
        call keyd('fmhz',fmhz,0.d0)
        call keyr('tol',tol,0.25)
        call keyfin
c
c  Open up the input.
c
        call hopen(tIn,vis,'old',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening input '//vis)
          call bugno('f',iostat)
        endif
c
c  Get header info.
c
        call rdhdi(tIn,'nfeeds',nfeeds,1)
        call rdhdi(tIn,'ngains',ngains,1)
        call rdhdi(tIn,'ntau',ntau,0)
        call rdhdi(tIn,'nchan0',nchan,0)
        call rdhdi(tIn,'nspect0',nspect,0)
        if(nfeeds.le.0.or.ngains.le.0)
     *    call bug('f','Bad gain table size information')
        nants = ngains / (nfeeds+ntau)
        if(nants*(nfeeds+ntau).ne.ngains)
     *    call bug('f','Number of gains does equal nants*nfeeds')
        if(nchan.gt.MAXCHAN.or.nchan.le.0)call bug('f',
     *    'Bad number of frequencies')
        if(nspect.le.0.or.nspect.gt.nchan)call bug('f',
     *    'Bad number of frequency spectral windows')
        if(nfeeds*nants*nchan.gt.maxGains)call bug('f',
     *    'Too many gains for me')
c
c
c  Read the frequency table.
c
        call haccess(tIn,item,'freqs','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the bandpass frequency table')
          call bugno('f',iostat)
        endif
c
        nchan = 0
        nchan2 = 0
        ispect = 0
        off = 8
        do i=1,nspect
          call hreadi(item,nschan,off,4,iostat)
          off = off + 8
          if(iostat.eq.0)call hreadd(item,freqs,off,2*8,iostat)
          write(line,602) 'Window ',i,': nschan, freqs = ',nschan,
     *      freqs(1),freqs(2)
          call output(line)
602       format(a,i2,a,i4,f12.4,f10.5)
          off = off + 2*8
          if(iostat.ne.0)then
            call bug('w','Error reading bandpass frequency table')
            call bugno('f',iostat)
          endif
          if (abs(1-abs(freqs(2)*1e3/fmhz)) .lt. tol) then
            ispect = ispect + 1
            nschan_save(ispect) = nschan
            freq1_save(ispect) = freqs(1)
            freq2_save(ispect) = freqs(2)
            do j = 1, nschan
               newch(j+nchan2) = j+nchan
            enddo
            nchan2 = nchan2 + nschan
          endif
          nchan = nchan + nschan
        enddo
        write(line,*) 'Selected ', ispect, ' spectral windows'
        call output(line)
        write(line,*) 'Selected ', nchan2, ' spectral channels'
        call output(line)
c
c  Close the frequency table.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Read the bandpass table.
c
        call haccess(tIn,item,'bandpass','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the bandpass table')
          call bugno('f',iostat)
        endif
c
        off = 8
        call hreadr(item,Gains,off,8*nants*nfeeds*nchan,iostat)
C        do i = 1, nchan
C            do j = 1, nants
C                write(46,*) i,j,Gains(i+(j-1)*nchan)
C            enddo
C        enddo
        if(iostat.ne.0)then
          call bug('w','Error reading the bandpass table')
          call bugno('f',iostat)
        endif
c
c  Close the bandpass table.
c
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Delete the old tables.
c
        if(nchan2.le.0)then
            call bug('f','No bandpass gains selected!')
        endif
        call output( 'Deleting the old frequency table')
        call hdelete(tIn,'freqs',iostat)
        call output( 'Deleting the old bandpass table')
        call hdelete(tIn,'bandpass',iostat)
c
c  Write the new frequency table.
c
        call wrhdi(tIn,'nspect0',ispect)
        call wrhdi(tIn,'nchan0',nchan2)
        call haccess(tIn,item,'freqs','write',iostat)
	    call hwritei(item,0,0,4,iostat)
	    if(iostat.ne.0)then
	      call bug('w','Error writing header of frequency table')
	      call bugno('f',iostat)
	    endif
c
        off = 8
        do i=1,ispect
          call hwritei(item,nschan_save(i),off,4,iostat)
          off = off + 8
          call hwrited(item,freq1_save(i),off,8,iostat)
          off = off + 8
          call hwrited(item,freq2_save(i),off,8,iostat)
          off = off + 8
          write(line,602) 'Window ',i,': nschan, freqs = ',
     *      nschan_save(i),freq1_save(i),freq2_save(i)
          call output(line)
          if(iostat.ne.0)then
            call bug('w','Error writing frequency table')
            call bugno('f',iostat)
          endif
        enddo
        call hdaccess(item,iostat)
        if(iostat.ne.0)then
          call bug('w','Error closing frequency table')
          call bugno('f',iostat)
        endif
c
c  Write the new bandpass table.
c
        call output('Writing the bandpass table now')
        call wrhdc(tIn,'bandpass',(0.,0.))
        call haccess(tIn,item,'bandpass','append',iostat)
        if(iostat.ne.0)then
          call bug('w','Error opening output bandpass table')
          call bugno('f',iostat)
        endif
        do i=1,nchan2
           off = 0
           do iant = 1, nants
              do ifeed = 1, nfeeds
                 Gains2(i+off*nchan2) = Gains(newch(i)+off*nchan)
                 off = off + 1
              enddo
           enddo
        enddo
        off = 8
        call hwriter(item,Gains2,off,8*nants*nfeeds*nchan2,iostat)
        if(iostat.ne.0)then
          call bug('w','Error writing bandpass table')
          call bugno('f',iostat)
        endif
C
C        off = 8
C        j = 0
C        do iant = 1, nants
C           do ifeed = 1, nfeeds
C              do i = 1, nchan2
C                 Gains2(i) = Gains(newch(i)+j*nchan)
C              enddo
C              call hwriter(item,Gains2,off,8*nchan2,iostat)
C              if(iostat.ne.0)then
C                 call bug('w','Error writing the bandpass table')
C                 call bugno('f',iostat)
C              endif
C              j = j + 1
C              off = off + 8*nchan2
C           enddo
C        enddo
C       
        call hdaccess(item,iostat)
        if(iostat.ne.0)then
          call bug('w','Error closing bandpass table')
          call bugno('f',iostat)
        endif
c
c  Close the header and update the history file.
c
        call hisopen(  tIn, 'append' )
        call hiswrite( tIn, 'BPSEL: ' // version)
        call hisinput( tIn, 'BPSEL' )
        call hisclose( tIn )
        call hclose(tIn)
c
        stop
        end

