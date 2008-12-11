c************************************************************************
	program panda
	implicit none
c
c= panda - Compute phase correction for each baseline, based on 
c          delay table from SZA.
c& lmp
c: uv analysis
c+
c
c  This routine applies an atmospheric phase correction to a CARMA visibility dataset.
c  The phase correction is computed from the SZA delay table obtained from 'bldelay', and
c  applied in a baseline-based sense, with the possibility of averaging delays over a fixed 
c  interval.
c
c@ vis
c       CARMA visibility file to be calibrated. No default.
c
c@ ref
c       SZA delay table (a .txt file for the moment). No default.
c
c@ out
c	    The name of the output uv data set. No default.
c
c@ interval
c	    Solution time interval, in minutes. The default is 0 minutes, i.e. no averaging.
c
c@ list1
c       List of CARMA antennas to be paired with SZA. No default.
c
c@ list2
c       List of SZA antennas, that are paired with 'list1'. No default.
c      
c--
c  History:
c    lmp  04nov08 Original version (based on blcal routine).
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='PANDA: version 1.0 04-Nov-08')
	character out*64,ref*64,line*32
	integer lVis,lOut,nchan
	integer nfiles
	double precision interval, preamble(6)
	complex visdata(MAXCHAN)
	logical flags(MAXCHAN)
	double precision fchan(MAXCHAN), bnumber
	integer sza_table(15), carma_table(15), nc, ns
c
c  Externals.
c
	logical uvDatOpn
	real oneamp
c
c  Get the inputs.
c
	call output(version)
	call keyini
	call uvDatInp('vis','bcef3')
	call keyd('interval',interval,0.0)
	if(interval.lt.0)call bug('f','Invalid value for interval')
	interval = interval/(60.*24.)
	call keya('out',out,' ')
	call keya('ref',ref,' ')
	call mkeyi('list1',carma_table,15,nc)
	call mkeyi('list2',sza_table,15,ns)
	call keyfin
c
c  Check user inputs.
c
	if(out.eq.' ') call bug('f','Output file name is missing')
	if(ref.eq.' ') call bug('f','Reference file name is missing')
	if(nc.ne.ns)   call bug('f',
	*  'Number of antennas in both lists must be the same')
c
c  Check the number of input files.
c
	call uvDatGti('nfiles',nfiles)
	if(nfiles.ne.1)call bug('f',
        * 'Input dataset must be given (CARMA dataset)')
c
c  Open the reference table and get delays
c
	call output('Opening the delay table ...')
	call delayDat(ref,carma_table,sza_table,nc)
c
c  Average delay data over interval
c
	call output('Averaging delays over input interval ...')
	call datLoad(interval)
	if(interval.gt.0) then
	   call datNorm
	endif
c
c  Open the output vis file
c
	call output('Opening the input visibility file ...')
	if(.not.uvDatOpn(lVis))call bug('f',
     *	  'Error opening science dataset')
	call uvDatGta('ltype',line)
	call varInit(lVis,line)
	call uvopen(lOut,out,'new')
	call uvset(lOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
	call varOnit(lVis,lOut,line)
c
c  From here to the end we apply the delays, 
c  write the output and close the files:
c
	call uvDatRd(preamble,visdata,flags,MAXCHAN,nchan)
	call uvinfo(lVis,'sfreq',fchan)
c
c       Compute the appropiate baseline number according to antenna pairs
	call pairs(preamble(5),carma_table,sza_table,nc,bnumber)
c
c       Loop through the rest of the data
	dowhile(nchan.gt.0)
c
c         Apply delays only if there is a baseline pair that matches
	  if(bnumber.ne.0) then
	    call DatCorr(preamble(4),bnumber,visdata,flags,nchan,fchan)
	  endif
c
c         Write out data
	  call varCopy(lVis,lOut)
	  call uvwrite(lOut,preamble,visdata,flags,nchan)
c
c         Read another record
	  call uvDatRd(preamble,visdata,flags,MAXCHAN,nchan)
	  call uvinfo(lVis,'sfreq',fchan)
	  call pairs(preamble(5),carma_table,sza_table,nc,bnumber)
	enddo
c
	call output('Closing output file ...')
	call hdcopy(lVis,lOut,'history')
	call hisOpen(lOut,'append')
	call hisWrite(lOut,'PANDA: Miriad '//version)
	call hisInput(lOut,'PANDA')
	call hisClose(lOut)
c
	call uvDatCls
	call uvclose(lOut)
c
	call output('Done!')
	end
c
c************************************************************************
	subroutine delayDat(filename,c_table,s_table,n)
c
c  Reads delay table
c  NOTE!!! The current format of the delay table is not very good,
c          and it will need to be changed to a more general table.
c
	implicit none
	character filename*64
	integer s_table(15), c_table(15),n
c------------------------------------------------------------------------
	include 'panda.h'
	integer i, k, EOF, s1, s2, c1, c2
        i = 1
        open (unit = 5, file = filename, status='old')
c 
c       Read first line, save onto variables
        read (5, *, iostat = EOF) t(i),baseline(i),delay(i)
c
c       While there is data in the file keep reading
c
        do while (EOF.eq.0)
           i = i + 1
	   read (5, *, iostat = EOF) t(i),baseline(i),delay(i)
	enddo
	baseline(i) = 0
	print *, i
c
c       Close reference file
        close(5)
c
c       Check which baselines need to be changed in sign:
c
	k = 1
	do while (baseline(k).ne.0)
	   call basant(baseline(k),s1,s2)
c
c          Find what are the antenna pairs:
	   do i=1,n
	      if(s_table(i).eq.s1) then
		 c1 = c_table(i)
	      endif
	      if(s_table(i).eq.s2) then
		 c2 = c_table(i)
	      endif
	   enddo
c	   
c          Change sign accordingly:
	   if(c1.gt.c2) then
	      delay(k) = -1.0 * delay(k)
	   endif
	   k = k+1
	enddo
c
	end
c************************************************************************
	subroutine datLoad(interval)
c
c  Loads the delay data into a convenient set of variables
c  in order to average them over the interval 
c
	implicit none
	double precision interval
c------------------------------------------------------------------------
	include 'panda.h'
	integer bl,bmin,bmax,i,j,k,i1,i2
	integer Tail(MAXBASE)
	logical buffered
	double precision tmin,tmax,tint
c
c  Initialise
c
	nsols = 0
	do j=1,MAXBASE
	  Head(j) = 0
	  Tail(j) = 0
	enddo
c
	buffered = .false.
	k = 1
	tmin = t(k)
	tmax = t(k)
	tint = 0
c
c  Read all the data
c
	dowhile(baseline(k).ne.0)
c        
c  Get the parameters of this record.
c       
	call basant(baseline(k),i1,i2)
	bl = ((i2-1)*i2)/2 + i1
c
c  Is this the end of an integration?
c
	    if(buffered.and.(t(k)-tmin.gt.interval.or.
     *			     tmax-t(k).gt.interval))then
	      call datFlush(Tail,MAXBASE,bmin,bmax)
	      buffered = .false.
c	      print *, 'One interval has elapsed...'
c	      tint = tint + (t(k)-tmin)*24*3600
c	      print *, k, tint, baseline(k)
	    endif
c
c  If tail was not initialized, do it...
c
	    if(tail(bl).eq.0)then
	        nsols = nsols + 1
	        tail(bl) = nsols
	        call memAlloc(gidx(nsols), 1, 'd')
	        call ZeroD(memd(gidx(nsols)), 1)
	        call memAlloc(fidx(nsols), 1,'i')
	        call ZeroI(memi(fidx(nsols)), 1)
	        time(nsols) = 0
	    endif
	    i = tail(bl)
c       
c  Add in this solution.
c
	    call datAdd(memd(gidx(i)),memi(fidx(i)),time(i),
     *      delay(k),t(k))
c
c  Book keeping.
c	
	      if(.not.buffered)then
	        bmin = bl
	        bmax = bmin
	        tmin = t(k)
	        tmax = tmin
	      else
	        bmin = min(bmin,bl)
	        bmax = max(bmax,bl)
	        tmin = min(tmin,t(k))
	        tmax = max(tmax,t(k))
	      endif
	      buffered = .true.
c
c  Go back for more.
c
	k = k + 1
	enddo
c
	if(buffered)call datFlush(Tail,MAXBASE,bmin,bmax)
c
	end
c
c************************************************************************
	subroutine datFlush(Tail,MBASE,bmin,bmax)
c
c  Restore the Tail array to its initial value
c
	implicit none
	integer MBASE,bmin,bmax
	integer Tail(MBASE)
c------------------------------------------------------------------------
	include 'panda.h'
	integer b,p,i
c
	do b=bmin,bmax
	  i = Tail(b)
	  if(i.ne.0)call datLink(Head(b),i)
	  Tail(b) = 0
	enddo
c
	end
c************************************************************************
	subroutine datAdd(vis,cnt,ttt,dly,tm)
c
c  Add data that belongs to a given interval, this data will be
c  averaged later with 'datNorm' routine 
c
	implicit none
	double precision ttt,tm,dly,vis
	integer cnt
c------------------------------------------------------------------------
	integer i
c
	    ttt = ttt + tm
c	    print *, ttt
	    vis = vis + dly
	    cnt = cnt + 1
c
	end
c************************************************************************
	subroutine zerod(data,n)
c
c  Initializes data array (for double precision)
c
	implicit none
	integer n
	double precision data(n)
c------------------------------------------------------------------------
	integer i
c
	do i=1,n
	  data(i) = 0.
	enddo
	end
************************************************************************
	subroutine zeroi(data,n)
c
c  Initializes data array (for integer type)
c
	implicit none
	integer n
	integer data(n)
c------------------------------------------------------------------------
	integer i
c
	do i=1,n
	  data(i) = 0
	enddo
	end
c************************************************************************
	subroutine datLink(Hd,pnt)
c
c  Links the data from Head array into Next array
c
	implicit none
	integer Hd,pnt
c------------------------------------------------------------------------
	include 'panda.h'
	integer i
c
	if(hd.eq.0)then
	  hd = pnt
	else
	  i = hd
	  dowhile(next(i).ne.0)
	    i = next(i)
	  enddo
	  next(i) = pnt
	endif
c
	end
c************************************************************************
	subroutine datNorm()
c
c  Reads over all the delay data and call the average procedure
c
	implicit none
c------------------------------------------------------------------------
	include 'panda.h'
	integer b,pnt
c
c
	do b=1,MAXBASE
	  pnt = Head(b)
	  dowhile(pnt.ne.0)
	    call datAver(memd(gidx(pnt)),memi(fidx(pnt)),time(pnt))
	    pnt = Next(pnt)
	 enddo
	enddo
c
	end
c************************************************************************
	subroutine datAver(del,cnt,tm)
c
c  Averages data from 'del' variable, if 'cnt' is the number of 
c  delays to be averaged
c
	implicit none
	double precision del,tm
	integer cnt
c------------------------------------------------------------------------
	include 'panda.h'
c
	del = del / cnt
	tm = tm / cnt
c
	end
c************************************************************************
	subroutine datCorr(co,bn,visdata,flags,nchan,fchan)
c
c  Correlates the visibility data for a given time and baseline with the
c  corresponding delay, and applies it
c
	implicit none
	integer nchan
	double precision co(3),fchan(nchan), bn
	complex visdata(nchan)
	logical flags(nchan)
c------------------------------------------------------------------------
	include 'panda.h'
	integer bl,i0,i1,i2,i,index
	logical more
	double precision phase,pi
	parameter (pi = 3.141592653589793)
	complex exp
c
	call basant(bn,i1,i2)
	bl = ((i2-1)*i2)/2 + i1
c
c  Search for the appropriate solution.
c
	i1 = head(bl)
	i2 = i1
	i0 = i1
	more = .true.
	dowhile(i2.ne.0.and.more)
	  if(abs(time(i2)-co(1)).lt.abs(time(i0)-co(1))) then
	     i0 = i2
	  endif
	  if(time(i1).gt.co(1).or.co(1).gt.time(i2))then
	    i1 = i2
	    i2 = next(i2)
	  else
	    more = .false.
c	    print *, 'Solution was found', time(i2), time(i1), next(i2)
	  endif
	enddo
c
c  If one delay was found, then apply it.
c
	if(.not.more)then
c
c	   Choose the closest delay in time
c
	   if((time(i2)-co(1)).lt.(co(1)-time(i1))) then
	      index = i2
	   else
	      index = i1
	   endif
c
c          Apply phase correction for each channel
c
	   do i=1,nchan
	      phase = 2.*pi*memd(gidx(index))*fchan(i)
	      exp = cmplx(cos(phase),-sin(phase))
	      visdata(i) = visdata(i) * exp
	   enddo
c	else if(i0.ne.0)then
cc
cc	   Choose the closest delay in time
cc
c	   index = i0
cc
cc          Apply phase correction for each channel
cc
c	   do i=1,nchan
c	      phase = 2.*pi*memd(gidx(index))*fchan(i)
c	      exp = cmplx(cos(phase),-sin(phase))
c	      visdata(i) = visdata(i) * exp
c	   enddo
	else
c
c       Flag visibility where no delay was found
c
	   do i=1,nchan
	    flags(i) = .false.
	  enddo
	endif
c
	end
c************************************************************************
	subroutine pairs(origbl,c_table,s_table,n,bn)
c
c  Read the carma and sza table of paired antennas and computes
c  what is the new baseline number (bn) that will match the delay table
c
	implicit none
	double precision origbl,bn
	integer c_table(15),s_table(15),n
c------------------------------------------------------------------------
c
	integer i,c1,c2,s1,s2
c
	call basant(origbl,c1,c2)
c	
	s1 = 0
	s2 = 0
c
	do i=1,n
c	   print *, c_table(i), s_table(i)
	   if(c_table(i).eq.c1) then
	      s1 = s_table(i)
	   endif
	   if(c_table(i).eq.c2) then
	      s2 = s_table(i)
	   endif
	enddo

	if((s1.eq.s2).or.(s1.eq.0).or.(s2.eq.0)) then 
	   bn = 0
c	   print *,'SZA antennas', s1,s2
c	   print *, 'CARMA antennas',c1,c2
	elseif(s1.lt.s2) then
	   bn = s1*256. + s2
c	   print *, 's1<s2: ', bn, s1, s2
	else
	   bn = s2*256. + s1
c	   print *, 's1>s2: ', bn, s1, s2
	endif
c
c	print *, 'CARMA ant: ', c1, c2
c	print *, origbl, bn
c
	end
