c************************************************************************
	program boxtest
	implicit none
c
c= boxtest - Test the boxes routines.
c& rjs
c: map analysis
c+
c	This is a TEST program, to give a crude display of the user
c	selected "region".
c@ imsize
c	Size of the image. Default is 32,15.
c@ region
c	Normal region keyword.
c--
c
c  History:
c    18mar92 rjs   Original version.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer boxx,boxy,maxruns,maxboxes
	parameter(boxx=32,boxy=15,maxruns=1024,maxboxes=1024)
	integer nsize(2),i,j,k,runs(3,maxruns),boxes(maxboxes)
	integer xmin,xmax,ymin,ymax,nruns
	character asterisk*(maxdim+2)
c
	call output( 'BoxTest: version 1.0 18-Mar-92' )
c
c  Open the input file, and make sure that I can handle it.
c
	call keyini
	call keyi('imsize',nsize(1),boxx)
	call keyi('imsize',nsize(2),boxy)
	if(nsize(1).le.0.or.nsize(2).le.0.or.nsize(1).gt.maxdim)
     *	  call bug('f','Bad imsize values')
	call BoxInput('region',' ',boxes,maxboxes)
	call keyfin
c
c  Set up the region of interest.
c
	call BoxSet(boxes,2,nsize,' ')
	call BoxRuns(1,1,' ',boxes,runs,maxruns,nruns,
     *					xmin,xmax,ymin,ymax)
c
	do i=2,nsize(1)+1
	  asterisk(i:i) = '-'
	enddo
	asterisk(1:1) = '+'
	asterisk(nsize(1)+2:nsize(1)+2) = '+'
	call output(asterisk(1:nsize(1)+2))
c
	k = 1
	do j=1,nsize(2)
	  asterisk(1:nsize(1)+2) = ' '
	  asterisk(1:1) = '|'
	  asterisk(nsize(1)+2:nsize(1)+2) = '|'
	  dowhile(Runs(1,k).eq.j)
	    do i=Runs(2,k)+1,Runs(3,k)+1
	      asterisk(i:i) = '*'
	    enddo
	    k = k + 1
	  enddo
	  call output(asterisk(1:nsize(1)+2))
	enddo
c
	do i=2,nsize(1)+1
	  asterisk(i:i) = '-'
	enddo
	asterisk(1:1) = '+'
	asterisk(nsize(1)+2:nsize(1)+2) = '+'
	call output(asterisk(1:nsize(1)+2))
c
	end
