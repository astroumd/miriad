c************************************************************************
	program uvsort
	implicit none
c
c= uvsort - Copy and sort a uv dataset into ascending order in time.
c& jhz for SMA 
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
c  Bugs:
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='UvSort: version 1.0 24-sept-05')
	character uvflags*12,ltype*16,out*64
	integer npol,Snpol,pol,tIn,tOut,vupd,nread,nrec,i
	real jyperk
	logical dotaver,doflush,buffered,PolVary,first
	logical ok,donenpol
	double precision preamble(5),Tprev,interval
        double precision time0
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
c
        integer MAXREC, blid,totalrec,idone
        parameter(MAXREC=1008000)
        integer irec,isrec
        double precision sortedtime(MAXREC)
c
c  Externals.
c
	logical uvDatOpn
c   initialize the time array
        do i=1, MAXREC
        sortedtime(i)=0.0d0
        end do
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call GetOpt(uvflags)
	call uvDatInp('vis',uvflags)
              
	call keyd('interval',interval,0.d0)
	call keya('out',out,' ')
	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
c
c  Various initialisation.
c
	interval = interval/(24.*60.)
	    npol = 0
	   Snpol = 0
           first = .true.
	 PolVary = .false.
	 doflush = .false.
	buffered = .false.
	donenpol = .false.
         dotaver = .false.
	    nrec = 0
c
c making time sorted array
c
       if(.not.uvDatOpn(tIn)) 
     *  call bug('f', 'Can not open the input file.')
          call uvDatRd(preamble,data,flags,maxchan,nread)
          time0 = preamble(4)
          dowhile(nread.gt.0)
             nrec = nrec + 1
             sortedtime(nrec) = preamble(4) 
          call uvDatRd(preamble,data,flags,maxchan,nread)
          end do
           call uvDatCls
           call sortd (sortedtime,nrec)

c
c
c  Open the input and the output files.
c
        write(*,*) 'Sorting uvdata into a time order.'
        call keyini
        call uvDatInp('vis',uvflags)
        call keya('out',out,' ')
        call keyfin
	if(.not.uvDatOpn(tIn)) 
     * write(*,*) 'cannot open input uv file'
	  call uvDatGta('ltype',ltype)
	  call VarInit(tIn,ltype)
	  call uvVarIni(tIn,vupd)
	  call uvVarSet(vupd,'dra')
	  call uvVarSet(vupd,'ddec')
	  call uvVarSet(vupd,'source')
	  call uvVarSet(vupd,'on')
                  
c
c Special processing the first time around.
c
	  if(first)then
	    call uvopen(tOut,out,'new')
	    call uvset(tOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
	    call hdcopy(tIn,tOut,'history')
	    call hisopen(tOut,'append')
	    call hiswrite(tOut,'UVSORT: Miriad '//version)
	    call hisinput(tOut,'UVSORT')
	    call hisclose(tOut)
	    first = .false.
	  endif
	  
          call VarOnit(tIn,tOut,ltype)


c
c  Loop over the data.
c
          isrec=1
          blid=0
          totalrec=0
          idone=0
          Tprev=0.0d0
          ok = .false.
12345     call uvDatRd(preamble,data,flags,maxchan,nread)
          irec=0
	  dowhile(nread.gt.0)
c
c  Count the number of records read.
c
	     irec = irec + 1
             if(sortedtime(isrec).eq.preamble(4)) ok = .true.
             if(ok) then
                call uvDatGti('npol',npol)
                call uvputvri(tOut,'npol',npol,1)
		call uvDatGti('pol',pol)
          	call uvputvri(tOut,'pol',pol,1)
                call VarCopy(tIn,tOut)
		call uvDatGtr('jyperk',jyperk)
		call uvputvrr(tOut,'jyperk',jyperk,1)
		call uvwrite(tOut,preamble,data,flags,nread)
                blid=blid+1
                totalrec=totalrec+1
                isrec=isrec+1
             Tprev = preamble(4)
                end if
            call uvDatRd(preamble,data,flags,maxchan,nread)
             if((preamble(4).ne.Tprev).and.ok) then
            call uvrewind(tIn)
             nread=-1
           ok=.false.
           if((isrec*100/nrec).eq.10.and.idone.lt.10) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=10
           else if ((isrec*100/nrec).eq.20.and.idone.lt.20) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=20
           else if ((isrec*100/nrec).eq.30.and.idone.lt.30) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=30
           else if ((isrec*100/nrec).eq.40.and.idone.lt.40) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=40
           else if ((isrec*100/nrec).eq.50.and.idone.lt.50) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=50
           else if ((isrec*100/nrec).eq.60.and.idone.lt.60) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=60
           else if ((isrec*100/nrec).eq.70.and.idone.lt.70) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=70
           else if ((isrec*100/nrec).eq.80.and.idone.lt.80) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=80
           else if ((isrec*100/nrec).eq.90.and.idone.lt.90) then
           write(*,*) isrec*100/nrec, '% completed.'
           idone=90
           end if
c          write(*,*) preamble(4)- sortedtime(isrec-1),irec,
c     *    Tprev-sortedtime(isrec-1),isrec-1,preamble(5),blid,'e',
c     *    totalrec
               blid=0
                end if
          enddo
               if(isrec.lt.nrec) goto 12345
               if(isrec.eq.nrec) goto 54321
               

c	  enddo
54321          write(*,*) isrec*100/nrec, '% completed.'
 	  call uvDatCls
c
c  Update the history and close up files.
c
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
           uvflags = 'bxdlr3'
	end
c************************************************************************
        subroutine sortd(array,n)
c
        implicit none
        integer n
        double precision array(n)
c
c  Sorts an array, ARRAY, of length N into ascending order using a
c  Heapsort algorithm. ARRAY is replaced on output by its sorted
c  rearrangement. The array elements are in double precision.
c
c  Input:
c    n          Number of elements to be sorted.
c
c  Input/Output:
c    array      Input: Elements to be sorted.
c               Output: Sorted elements.
c--
c------------------------------------------------------------------------
      INTEGER L,IR,J,I
      double precision RRA
c
      L=N/2+1
      IR=N
10    CONTINUE
        IF(L.GT.1)THEN
          L=L-1
          RRA=ARRAY(L)
        ELSE
          RRA=ARRAY(IR)
          ARRAY(IR)=ARRAY(1)
          IR=IR-1
          IF(IR.LE.1)THEN
            ARRAY(1)=RRA
            RETURN
          ENDIF
        ENDIF
        I=L
        J=L+L
20      IF(J.LE.IR)THEN
          IF(J.LT.IR)THEN
            IF(ARRAY(J).LT.ARRAY(J+1))J=J+1
          ENDIF
          IF(RRA.LT.ARRAY(J))THEN
            ARRAY(I)=ARRAY(J)
            I=J
            J=J+J
          ELSE
            J=IR+1
          ENDIF
        GO TO 20
        ENDIF
        ARRAY(I)=RRA
      GO TO 10
      END

