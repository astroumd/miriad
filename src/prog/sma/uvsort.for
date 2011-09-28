c************************************************************************
	program uvsort
	implicit none
c
c= uvsort - Copy and sort a uv dataset into ascending order in time.
c& jhz
c: uv analysis
c+
c	UVSORT copies a uv dataset, sorting uvdata into ascending
c	order in time.
c@ vis
c	The name of the input uv data set. It must be a single file. 
c	No default.
c@ select
c	The normal uv selection commands. The default is copy everything.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels). The output will consist of only spectral or
c	wideband data (but not both).
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c  jhz 22sept05 made an initiative versioni, requested by dan marrone.
c  jhz 26sept05 purged irrelevant lines and notes.
c  pjt 18apr06  moved sortd to sort.for and cleaned up some indentation
c  jhz 03jun07  incorporated peter williams modification
c  pjt 21sep11  also handle auto-correlations
c  Bugs:
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='UvSort: version 28-sep-2011')
	character uvflags*12,ltype*16,out*120,line*120
	integer npol,pol,tIn,tOut,vupd,nread,nrec
	integer i,nuniq,written,nthistime,nrewind
	real jyperk
	logical futureskipped
	double precision preamble(5),Tprev,nextprog
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
c
        integer MAXREC
        parameter(MAXREC=1008000)
        integer irec,isrec
        double precision sortedtime(MAXREC)
	integer npertime(MAXREC)
c
c  Externals.
c
	logical uvDatOpn
c   initialize the time array
        do i=1, MAXREC
	   sortedtime(i) = 0.0d0
	   npertime(i) = 0 
        end do
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags)
	call uvDatInp('vis',uvflags)
              
	call keya('out',out,' ')
	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
c
c  Various initialisation.
c
	npol = 0
	nrec = 0
c
c making time sorted array: loop through the input data
c and just read the times
c
	call output( 'First pass: reading timestamps and sorting')

        if(.not.uvDatOpn(tIn)) call bug('f', 
     *            'Cannot open the input file.') 
	call uvDatRd(preamble,data,flags,maxchan,nread)
	do while(nread.gt.0)
	   nrec = nrec + 1
	   if (nrec.GE.MAXREC) call bug('f','MAXREC too small')
	   sortedtime(nrec) = preamble(4) 
	   call uvDatRd(preamble,data,flags,maxchan,nread)
	end do
	call uvDatCls
	call sortd (sortedtime,nrec)

c XXX Begin modifications by PKGW
c
c Cut down the list to only unique times

	nuniq = 0
	Tprev = 0.0d0

        do i=1, nrec
	   if (sortedtime(i).ne.Tprev) then
	      nuniq = nuniq + 1
	      sortedtime(nuniq) = sortedtime(i)
	      Tprev = sortedtime(i)
	   end if

	   npertime(nuniq) = npertime(nuniq) + 1
        end do

	write(line,112) nuniq,nrec 
        call output(line)
112     format(5x,i6,' unique UV timestamps, ',i6,' UV records.')

c  Open the input again, and the output file.

        call output ('Second pass: copying data')

        call keyini
        call uvDatInp('vis',uvflags)
        call keya('out',out,' ')
        call keyfin
	if(.not.uvDatOpn(tIn)) 
      *   call bug('f', 'cannot open input uv file')
	call uvDatGta('ltype',ltype)
	call VarInit(tIn,ltype)
	call uvVarIni(tIn,vupd)
	call uvVarSet(vupd,'dra')
	call uvVarSet(vupd,'ddec')
	call uvVarSet(vupd,'source')
	call uvVarSet(vupd,'on')
                  
	call uvopen(tOut,out,'new')
	call uvset(tOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
	call hdcopy(tIn,tOut,'history')
	call hisopen(tOut,'append')
	call hiswrite(tOut,'UVSORT: Miriad '//version)
	call hisinput(tOut,'UVSORT')
	call hisclose(tOut)
	  
	call VarOnit(tIn,tOut,ltype)

	isrec = 1
	written = 0
	nrewind = 0
	nextprog = 0.1d0

	do while(isrec.le.nuniq)
	   futureskipped = .false.
	   nthistime = 0
	   irec = 0

	   call uvDatRd(preamble,data,flags,maxchan,nread)

c       Check again for isrec < nuniq since our short-circuit
c       inside the loop will have advanced us past the end for
c       the chronologically final record.

	   do while(nread.gt.0.and.isrec.le.nuniq)
	      irec = irec + 1

	      if (preamble(4).gt.sortedtime(isrec)) then
		 futureskipped = .true.
	      else if(preamble(4).eq.sortedtime(isrec)) then
		 call uvDatGti('npol',npol)
		 call uvputvri(tOut,'npol',npol,1)
		 call uvDatGti('pol',pol)
		 call uvputvri(tOut,'pol',pol,1)
		 call VarCopy(tIn,tOut)
		 call uvDatGtr('jyperk',jyperk)
		 call uvputvrr(tOut,'jyperk',jyperk,1)
		 call uvwrite(tOut,preamble,data,flags,nread)

		 written = written + 1
		 nthistime = nthistime + 1

c       If we haven't skipped any records from the future, and we know that
c       we've written all the records for the current isrec, we can move on
c       to the next isrec without rewinding, safe in the knowledge that
c       all the necessary records lie ahead of us in the file.

		 if ((.not.futureskipped).and.
		 * (nthistime.eq.npertime(isrec))) then
		    isrec = isrec + 1
		    nthistime = 0
		 end if

c       Report progress

		 if ((1.0d0 * written / nrec).ge.nextprog) then
		    write(line,116)  written, nrec 
		    call output(line) 
                    nextprog = nextprog + 0.1
		 end if
	      end if

	      call uvDatRd(preamble,data,flags,maxchan,nread)
	   enddo

c       Completed one pass through the file. We should have found every
c       record for the current sorted time. Rewind and start looking for
c       records matching the next time in our sorted list.

	   if (nthistime.ne.npertime(isrec)) then
	      write(*,*) 'Bug: nthis ', nthistime
	      write(*,*) 'Bug: nper ', npertime(isrec)
	      call bug ('f', 'Algorithm bug! (1)')
	   end if

	   nrewind = nrewind + 1
	   call uvrewind(tIn)
	   isrec = isrec + 1
	enddo

c       Done with all times. Check sanity and clean up.

	if (isrec.le.nuniq) call bug ('f', 'Algorithm bug! (2)')
	if (written.ne.nrec) call bug ('f', 'Algorithm bug! (3)')

        write(line,115) nrewind 
115     format('Done sorting. Had to rewind ',i6, ' times.')
116     format(5x,i6,' of ', i6, ' UV records written.')
        call output(line)

	call uvDatCls
	call uvclose(tOut)

	end


c************************************************************************
	subroutine GetOpt(uvflags)
c
	implicit none
	character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c  Output:
c    uvflags	Flags to pass to the uvdat routines.
c------------------------------------------------------------------------
c
c Set up calibration flags
c
c
           uvflags = 'bdlr3'
	end
