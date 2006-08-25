c************************************************************************
      PROGRAM vel2fel 
c
c= vel2fel - Change the value of or add a single header item
c& jhz 
c: utility
c+
c   VEL2FEL is a MIRIAD task to convert the velocity
c   convention from radio to optical in an image header.
c@ in
c   The name of a data set. 
c--
c  History:
c    jhz   24aug06  Original version.
c
c-----------------------------------------------------------------------
	character PVERSION*(*)
	parameter(PVERSION='Version 1.0 24-aug-06')
        include 'mirconst.h'
	integer lin,iostat, iaxis
	character in*80,item*32
        character vtype*72,iitem
	double precision fel1,dfel
c
c  Externals.
c
	integer len1
c-----------------------------------------------------------------------
        call output( 'VEL2FEL: '//PVERSION )
c
	call keyini
	call keya('in',in,' ')
	call keyfin
	if(in.eq.' ')call bug('f','Input data-set name is missing')
	call hopen(lin,in,'old',iostat)
	if(iostat.ne.0)then
	   call bug('i','Error opening dataset '//in(1:len1(in)))
	   call bugno('f',iostat)
        endif
        
        call getFelInfo(lin,in,fel1,dfel,vtype,iaxis)
              
              if(iaxis.eq.1) iitem='1'
              if(iaxis.eq.2) iitem='2'
              if(iaxis.eq.3) iitem='3'
              if(iaxis.eq.4) iitem='4'
              if(iaxis.eq.5) iitem='5'
c
            item = 'ctype'//iitem(1:1)
            call wrhda(lIn,item,vtype)
            item = 'crval'//iitem(1:1)
	    call wrhdd(lIn,item,fel1)
            item = 'cdelt'//iitem(1:1)
            call wrhdd(lIn,item,dfel)
c
c  History
c
	call hisopen(lin,'append')
	call hiswrite(lin,'VEL2FEL: Miriad PutHd: '//PVERSION)
	call hisinput(lin,'VEL2FEL')
	call hisclose(lin)
c
c  Close up and go home.
c
	call hclose(lin)
	end

c************************************************************************
        subroutine getFelInfo(tno,in,fel1,dfel,vtype,iaxis)
c
        implicit none
        integer tno
        character in*(*)
c
c  Give a summary about an image.
c------------------------------------------------------------------------
      include 'mirconst.h'
      double precision dval,restf,fel1,dfel
      real vobs
      integer ival,iaxis
      character line*80,vtype*72
       logical hdprsnt
c
c  Externals.
c
c
c  Dimension info.
c
      call rdhdi (tno, 'naxis', ival, 0)
      write (line,'(a,i2,a)')'This image has',ival,' axes.'
      if(hdprsnt(tno,'vobs')) call rdhdr(tno,'vobs',vobs,0.0)
       
      call rdhdd(tno,'restfreq',dval,0.d0)
      if(dval.gt.0)then
        write(line,'(a,f13.6,a)')
     *    'Rest frequency:         ',dval,' GHz'
           restf=dval

      call dovel2fel (tno,ival,restf,vobs,fel1,dfel,vtype,iaxis)
      end if
c
    
      end

c************************************************************************
      subroutine dovel2fel (tno,naxis,restf,vobs,fel1,dfel,vtype,iaxis)
c
      implicit none
      integer tno,naxis,iaxis
c
c     List axes
c-----------------------------------------------------------------------
      include 'mirconst.h'
      double precision crval,cdelt,restf
      real crpix,vobs
      integer n,i
      character aval*72,str*2,vtype*72
      character itoaf*2
      double precision fel1,dfel,fac
c
c restf:  rest frequency
c  obsf:  reference observing frequency (sky frequency) 
c  fel1:  reference velocity in optical convention
c  dfel:  velocity width in optical convention 
c  vtype: velocity type
c  iaxis: the ith axis corresponding to velocity
c  Externals.
c
      do i=1,naxis
        str = itoaf(i)
        call rdhda(tno, 'ctype'//str, aval, 'none')
        call rdhdi(tno,'naxis'//str,n,0)
        call rdhdd (tno, 'crval'//str, crval,0.0d0)
        call rdhdr (tno, 'crpix'//str, crpix,0.0)
        call rdhdd (tno, 'cdelt'//str, cdelt,0.0d0)
        if(aval(1:5).eq.'FELO-') then
        call bug('w','already in optical-convention.')
        stop
        end if

        if(aval(1:5).eq.'VELO-')then
        iaxis=i
c
c determine the conversion factor  
c
        fac = DCMKS/(DCMKS-crval*1.0d3)
c determine the reference velocity in optical convention
        fel1 = crval*fac
c determine the reference frequency
        dfel = cdelt*fac*fac
        vtype=aval
        vtype(1:1) = 'F'
        end if
      enddo
      end

