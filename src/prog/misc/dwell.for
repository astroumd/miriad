c**********************************************************************c
      program DWELL
      implicit none
c= DWELL - Calculate dwell time for given array configuration
c& mwp
c: utility
c+
c	DWELL - Calculate the dwell time for a given array configuration.
c	The dwell time is the maximum amount of time that can be
c       spent on a given field before the longest baseline
c 	rotates to a completely independent visibility point. It is
c 	given by
c
c	tdwell = (43200/pi)*(D/L)*(1/N)
c
c 	where D is the antenna diameter, L is the longest baseline, and
c	N is the number of fields.
c
c	This task can be used to help maximize the on-source time and 
c       increase observing efficiency. It is of most use when planning 
c	mosaic observations.  
c@ ary
c	The name of a text file containing the antenna positions 
c       (in nanosec and either topocentric or geocentric coordinates).  
c       Can be either same format as for uvtrack ("ary format") or uvgen
c       ("ant" format). No default. 
c@ format
c	Format for array file, "ant" or "ary", indicating styles
c	of $MIRCAT/*.ant[pos] or  $MIRCAT/*.ary, respectively.
c	Default is "ant".
c@ nfields
c	Number of fields in the mosaic. No default.
c@ antdiam
c	Antenna diameter (m). Default=6.1 
c@ options 
c	verbose  Print out the antennna pairs and baseline lengths
c--
c  History:
c	17jun97 mwp   original version. adapted from personal C version.
c	08oct98 mwp   read(,*) for flexibility in array position formats
c	12apr99 mwp   added options=verbose to print out the baselines
c
c-----------------------------------------------------------------------
	character version*(*)
	parameter(version='version 1.1  12-Apr-99')
	include 'maxdim.h'
	real antdiam,base,longbase,tau,nfields
	real x(MAXANT),y(MAXANT),z(MAXANT)
	integer i,k,nants,lu,iostat
	logical verbose
	character antfile*80, line*80, form*4 

        call output('Dwell '//version)
c
c  Get user inputs.
c
        call keyini
	call keya('ary',antfile,' ')
        call keyr('nfields',nfields,0.)
	call keya('format',form,'ant')
        call keyr('antdiam',antdiam,6.1)
	call GetOpt(verbose)
	call keyfin

	if(nfields.eq.0) then
	  call bug('f','Number of fields must be specified')
	endif

	longbase=0.0
	nants=0

	call txtopen(lu,antfile,'old',iostat)
	if(iostat.ne.0) call bug('f','Error opening array file')

	if (form.eq.'ary') then
c
c read in a file.ary that has format, e.g:
c c97.ary
c 1 9
c   -75.     0.
c     0.    15.
c     0.    80.
c    15.     0.
c   125.     0.
c     0.    20.
c     0.   140.
c     0.   180.
c     0.   100.

c   get the useless first line 
	 call txtread(lu,line,k,iostat) 
	 if(iostat.ne.0) call bug('f','Error reading from config file')

	 call txtread(lu,line,k,iostat) 
	 if(iostat.ne.0) call bug('f','Error reading from config file')
	 read(line(1:k),*) i,nants
	 write(line,200) i,nants
200	 format('Found ',i3,' configurations of ',i4,' antennas')
	 call output(line)
	 nants=i*nants

	 if(nants.gt.MAXANT) then
		call bug('f','Maximum number of antennas exceeded')
	 endif

	 do i=1,nants
	  call txtread(lu,line,k,iostat) 
	  if(iostat.ne.0) call bug('f','Error reading from config file')
    	  read(line(1:k),*) x(i),y(i)
	  z(i) = 0.0
c	  print *,x(i),y(i)
	 enddo

	else
c read in a file.ant that has format, e.g.
c    560.0000      0.0000      0.0000
c   1740.0000    310.0000      0.0000
c   2710.0000   -230.0000      0.0000
	 call txtread(lu,line,k,iostat)
         dowhile(iostat.eq.0.and.nants.lt.MAXANT)
          if(line(1:1).ne.'#')then
           nants = nants + 1
c           read(line(1:k),'(3f12.4)') x(nants),y(nants),z(nants)
           read(line(1:k),*) x(nants),y(nants),z(nants)
	  endif
	 call txtread(lu,line,k,iostat)
	 enddo
	endif

	call txtclose(lu)

c/* Calculate the baseline to every other antenna
c * Yes, i know this is inefficient because it does many twice, but
c * CPU is free and fast. I'll save a little time by not taking the
c * square root, ok?
c * Before, I just took the furthest north and furthest E||W to
c * find the longest baseline, but now that we can have antennas
c * off the T, that (very fast) algorithm can fail.
c */
		
	do i=1,nants
	    do k=1,nants
	     base=(x(i)-x(k))*(x(i)-x(k))+(y(i)-y(k))*(y(i)-y(k))
	     base=base+((z(i)-z(k))*(z(i)-z(k)))
	     if(verbose.and.(i.lt.k)) write(6,351) i,k,(base**0.5)/3.33
	     if (base.gt.longbase) longbase = base
	    enddo 
	enddo 
	longbase = (longbase**0.5)/3.33

	tau = 86400.0*antdiam/(3.14159265*longbase)
351	format('Ant(',i3,','i3,')  ',f7.1,' meters')
	write(line,400) longbase
400	format('Longest baseline is ',f7.1,' meters')
	call output(line)
	write(line,500) 
500	format('Time for longest baseline to rotate to')
	call output(line)
	write(line,550) tau
550	format('completely independent u-v point is ',f6.1,' seconds')
	call output(line)
	tau = tau / (2.0*nfields)
	write(line,600) nfields
600	format('To mosaic ',f4.0,' fields, ITIME times NREPS')
	call output(line)
	write(line,700) tau, tau/60.
700	format('should not exceed ',f6.1,' seconds (',f6.2,' minutes).')
	call output(line)
	write(line,800)
800	format('Have a nice day.')
	call output(line)
	end

c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(verbose)
c
        implicit none
        logical verbose
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=1)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'verbose '/
c
        call options('options',opts,present,nopts)
        verbose = present(1)
        end

