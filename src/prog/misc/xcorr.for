c********1*********2*********3*********4*********5*********6*********7*c
	program xcorr
	implicit none
c= xcorr - cross correlate columns in ascii files.
c& mchw
c: analysis
c+
c	XCORR is a Miriad task to cross correlate columns in ascii files.
c	Print average and rms for each column and the correlation matrix.
c	Write the cross correlation functions to output file.
c@in
c	Input filename of ascii data.
c	Lines begining with "#" are not used.
c	Default is a pill box 3 rows wide and shifted by 10 rows.
c@out
c	Output filename for cross correlation functions.
c	Default none.
c@nrow
c	Number of rows, same as number of points in FFT	.
c	Must be power of 2 only if correlation functions are written.
c	Maximum 2048. Default 32.
c@ ncol
c	Number of columns to cross correlate.
c	Maximum 16. Default 2.
c@ refcol
c	Refererence column for cross correlation.
c	Default 1.
c@ device
c       Standard PGPLOT device, to plot correlation functions. 
c       Default is no plot.
c@ nxy
c       Number of plots in the x and y directions.
c	The default selects something reasonable.
c@ xrange
c       The min and max range along the x axis of the plots. The default
c       is to autoscale.
c@ yrange
c       The min and max range along the y axis of the plots. The default
c       is to autoscale.
c-- 
c
c  History:
c    14may72 mchw  Original version.
c    27dec95 mchw  Added keywords for nrow and ncol 
c    15oct97 mchw  Added beauty. 
c    15oct97 rjs   Added truth. 
c    11sep02 mchw  Added logic. 
c----------------------------------------------------------------------c
	character version*(*),infile*132,outfile*132,line*132,dat*24
	character device*80
	integer nx,ny
	parameter(version='(version 11-Sep-02)')
	integer MAXROW,MAXCOL
	parameter(MAXROW=2048,MAXCOL=16)
	real data(MAXROW,MAXCOL),maxamp/0./
	complex out(MAXROW,MAXCOL)
	complex temp(MAXROW)
	integer i,j,nrow,ncol,refcol,k
	real ave(MAXCOL),rms(MAXCOL),corr(MAXCOL,MAXCOL)
        real xx(MAXROW),yy(MAXROW)
        real xrange(2),yrange(2)
c
c  Get user input parameters.
c
	call output('XCORR '//version)
	call keyini
	call keya('in',infile,' ')
	call keya('out',outfile,' ')
	call keyi('nrow',nrow,32)
	call keyi('ncol',ncol,2)
	call keyi('refcol',refcol,1)
        call keya('device',device,' ')
        call keyi('nxy',nx,0)
        call keyi('nxy',ny,nx)
        call keyr('xrange',xrange(1),0.)
        call keyr('xrange',xrange(2),xrange(1))
        call keyr('yrange',yrange(1),0.)
        call keyr('yrange',yrange(2),yrange(1))
	call keyfin
c
	call fdate(dat)
	write(line,'(a,a)') 'cross correlations - ',dat
	call output(line)
c
c  Read input data.
c
	if(infile.ne.' ')then
	  open (unit=1, file=infile, form='formatted', status='old')
	  call output('File: '//infile)
	  do i=1,nrow
	    read(1,'(a)') line
	    if(line(1:1).eq.'#')then
	      call output(line)
	    else
	      read(line,*)  (data(i,j),j=1,ncol)
	    endif
	  enddo
c
c  Else test with autocorrelation and with known offset
c
	else
	  ncol = 2
	  call output(
     *		'Test - a pill box 3 rows wide and shifted by 10 rows.')
	  do i=1,nrow
	    data(i,1) = 0.
	    data(i,2) = 0.
	  enddo
	  do i=20,22
	    data(i,1) = 1.
	    data(i+10,2) = 1.
	  enddo
	endif
c
c  Compute statistics
c
	do j=1,ncol
	  ave(j) = 0.
	  rms(j) = 0.
          do i=1,nrow
            ave(j)  =  ave(j) + data(i,j)
            rms(j)  =  rms(j) + data(i,j)*data(i,j)
	    do k=1,ncol
              corr(j,k) = corr(j,k) + data(i,j)*data(i,k)
            enddo
          enddo
	  ave(j) = ave(j)/nrow
	  rms(j) = rms(j)/nrow - ave(j)*ave(j)
	  if(rms(j).ge.0.) then
	    rms(j) = sqrt(rms(j))
	  else
	    rms(j) = 0.
	  endif
        enddo
c
c  Subtract average
c
	do j=1,ncol
	  do i=1,nrow
	    data(i,j) = data(i,j) - ave(j)
          enddo
        enddo
c
c  Print correlation matrix
c
	write(line,'(a)')
     *		 'column  average      rms      correlation matrix'
	call output(line)
	do j=1,ncol
          do k=1,ncol
	   if(rms(j)*rms(k).ne.0.)then
	    corr(j,k) = (corr(j,k)/nrow-ave(j)*ave(k))/(rms(j)*rms(k))
	   else
            corr(j,k) = 0.
	   endif
	  enddo
	  write(line,'(i4,x,16f10.3)') 
     *				j,ave(j),rms(j),(corr(j,k),k=1,ncol)
	  call output(line)
        enddo
c
c  Compute correlation functions.
c
	if(outfile.eq.' ' .and. device.eq.' ')then
	  stop 1
	endif
c
c  Subtract mean and compute correlation functions.
c
          do i=1,nrow
            data(i,j) = data(i,j) - ave(j)/nrow
          enddo
c
c  FFT columns
c
	do j=1,ncol
	  call fftrc(data(1,j),out(1,j),1,nrow)
	enddo
c
c  normalize each FFT
c
	do j=1,ncol
	  maxamp = 0.
	  do i=1,nrow/2+1
	    maxamp = max(maxamp,cabs(out(i,j)))
	  enddo
	  do i=1,nrow/2+1
	    out(i,j) = out(i,j)/maxamp
	  enddo
	enddo
c
c  product of FFT's and inverse FFT to get cross correlation
c
	do j=1,ncol
	  do i=1,nrow/2+1
	    temp(i) = out(i,j) * conjg(out(i,refcol))
	  enddo
	  call fftcr(temp(1),data(1,j),-1,nrow)
	enddo
c
c  Output correlation functions.
c
	if(outfile.ne.' ')then
	  open (unit=2, file=outfile, form='formatted', status='new')
	  do i=1,nrow
	    write(2,'(i,x,12f10.2)') i,(data(i,j),j=1,ncol)
	  enddo
	endif
c
c  plot correlation functions.
c
	call corrplot(device,infile,nx,ny,xx,yy,data,
     *    xrange,yrange,nrow,ncol,MAXROW,MAXCOL)
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine corrplot(device,infile,nx,ny,xx,yy,data,
     *	  xrange,yrange,nrow,ncol,MAXROW,MAXCOL)
c
        implicit none
        character*(*) device, infile
	integer nrow,ncol,MAXROW,MAXCOL,nx,ny
        real data(MAXROW,MAXCOL)
        real xx(MAXROW),yy(MAXROW)
        real xrange(2),yrange(2)
c-----------------------------------------------------------------------
        real xlo,xhi,ylo,yhi
        integer pgbeg, ierr, ismin, ismax, i, j, length
        character*48 title, xaxis, yaxis
	real delta
c
c  Externals.
c
        character itoaf*3
        integer len1
c
c  Open the plot device.
c
	if(nx*ny.eq.0)then
	  nx = min(4.,sqrt(float(ncol)))
	  ny = min(4.,float(ncol)/nx+0.9)
	endif
	ierr = pgbeg(0,device,nx,ny)
          if(ierr.ne.1)then
            call pgldev
            call bug ('f', 'Error in PGPLOT device')
          endif
	call pgsch(real(max(nx,ny))**0.4)
c
c  Find plot limits.
c
        do j=1,ncol
	  do i=1,nrow
	    xx(i) = i
	    yy(i) = data(i,j)
	  enddo
	  if(xrange(1).eq.xrange(2))then
	    xlo = xx(ismin(nrow,xx,1))
	    xhi = xx(ismax(nrow,xx,1))
	  else
	    xlo = xrange(1)
	    xhi = xrange(2)
	  endif
	    ylo = yy(ismin(nrow,yy,1))
	    yhi = yy(ismax(nrow,yy,1))
	 if(ylo.ne.yhi)then
	  if(yrange(1).ne.yrange(2))then
	    ylo = yrange(1)
	    yhi = yrange(2)
	  endif
	  delta = 0.05*(xhi-xlo)
	  if(delta.le.0)delta = 1
	  xlo = xlo - delta
	  xhi = xhi + delta
	  delta = 0.05*(yhi-ylo)
	  if(delta.le.0)delta = 1
	  ylo = ylo - delta
	  yhi = yhi + delta
c
c  Do the plots.
c
	  call pgpage
          call pgvstd
          call pgswin(xlo,xhi,ylo,yhi)
	  call pgpt(nrow,xx,yy,1)
          call pgtbox('BCNST',0.,0,'BCNST',0.,0)
          xaxis = 'lag'
          yaxis = 'cross correlation'
          title = 'column '//itoaf(j)//'File='//infile
          length = len1(title)
          call pglab(xaxis,yaxis,title(1:length))
	 endif
	enddo
c
c  Close up plot.
c
	call pgend
	end
c********1*********2*********3*********4*********5*********6*********7*c
