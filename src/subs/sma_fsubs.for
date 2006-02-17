c************************************************************************
c     A collection of subroutines shared by the tasks 
c     for SMA data reductions. 
c History:
c jhz 06feb13: make an initiative version 
c
c  gload   : load the antennas.
c  gncvt   : pick up the true gains.
c  antgsel : Blank out the antenna gains that were not selected.
c************************************************************************
        subroutine gload(tin,t0,time,jtime,g,nfeeds,ntau,nants,
     *    nsols,sels,maxgains,maxtimes)
c
        integer tin,nfeeds,nants,ntau,nsols,maxgains,maxtimes
        complex g(maxgains)
        real time(maxtimes),sels(*)
        double precision t0, jtime(6145)
c
c  Load the antenna gains.
c
c  Input:
c    tIn
c    maxGains
c    maxTimes
c  Output:
c    T0         Base time, as a Julian date.
c    time       Offset Julian date.
c    G          The antenna gains.
c    nfeeds     Number of feeds (1 or 2).
c    ntau       Number of delay/spec corr terms (0 or 1).
c    nants      Number of antennas.
c    nsols      Number of solution intervals.
c-----------------------------------------------------------------------_
        integer item,iostat,offset,i,k,ngains
        double precision t
        logical doselect,select
c
c  Externals.
c
        integer hsize
        logical selprobe
c
c  Determine the various parameters, and check their validity. We have pretty
c  well checked that all is OK before, so nothing should go wrong.
c
        doselect = selprobe(sels,'time?',0.d0)
        call rdhdi(tin,'nfeeds',nfeeds,1)
        call rdhdi(tin,'ntau',ntau,0)
        call rdhdi(tin,'ngains',ngains,1)
        call rdhdi(tin,'nsols',nsols,1)
        if(nfeeds.le.0.or.ntau.lt.0.or.ngains.le.0.or.nsols.le.0)
     *    call bug('f','Bad gain table size information')
        nants = ngains / (nfeeds + ntau)
        if(nants*(nfeeds+ntau).ne.ngains)
     *    call bug('f','Number of gains does equal nants*(nfeeds+ntau)')
        if((nfeeds+ntau)*nants*nsols.gt.maxgains)call bug('f',
     *    'Too many gains for me')
        if(nsols.gt.maxtimes)call bug('f',
     *    'Too many solution intervals for me')
c
        call haccess(tin,item,'gains','read',iostat)
        if(iostat.ne.0)then
          call bug('w','Error accessing the gains table')
          call bugno('f',iostat)
        endif
c
c  Determine what we thing the number of solutions should be from the
c  size of the file.
c
        if(hsize(item).ne.8+(ngains+1)*8*nsols)
     *    call bug('f','Gain table does not look the right size')
c
c  All is OK. Lets go for it.
c
        k = 0
        offset = 8
        do i=1,nsols
          call hreadd(item,t,offset,8,iostat)
          if(iostat.ne.0)call bugno('f',iostat)
          offset = offset + 8
          if(doselect)then
            select = selprobe(sels,'time',t)
          else
            select = .true.
          endif
          if(select)then
            k = k + 1
            if(k.eq.1) t0 = nint(t - 1.d0) + 0.5d0
            jtime(k)=t
            time(k) = t - t0
            call hreadr(item,g((k-1)*ngains+1),offset,8*ngains,iostat)
            if(iostat.ne.0)call bugno('f',iostat)
          endif
          offset = offset + 8*ngains
        enddo
        if(k.eq.0)call bug('f','No gains selected')
        nsols = k
        call hdaccess(item,iostat)
        if(iostat.ne.0)call bugno('f',iostat)
c
c  Blank out the antenna gains that were not selected.
c
        if(selprobe(sels,'antennae?',0.d0))
     *    call antgsel(sels,g,nfeeds,ntau,nants,nsols)
        end
c************************************************************************
        subroutine gncvt(in,out,nfeeds,ntau,ngains)
c
        integer nfeeds,ntau,ngains
        complex in(nfeeds+ntau,ngains),out(nfeeds,ngains)
c
c  Pick out the true gains.
c
c------------------------------------------------------------------------
        integer i,j
c
        do j=1,ngains
          do i=1,nfeeds
            out(i,j) = in(i,j)
          enddo
        enddo
        end
c************************************************************************
        subroutine antgsel(sels,g,nfeeds,ntau,nants,nsols)
c
        integer nfeeds,ntau,nants,nsols
        real sels(*)
        complex g(nfeeds+ntau,nants,nsols)
c
c  Blank out any antennas that were not selected.
c
c------------------------------------------------------------------------
        include 'maxdim.h'
        integer i,j,k
        logical ant(maxant)
c
c  Externals.
c
        logical selprobe
c
c  Determine which antennas were selected.
c
        do i=1,nants
          ant(i) = selprobe(sels,'antennae',257.d0*i)
        enddo
c
c  Now blank out the unwanted antennas.
c
        do k=1,nsols
          do j=1,nants
            if(.not.ant(j))then
              do i=1,nfeeds
                g(i,j,k) = 0
              enddo
            endif
          enddo
        enddo
        end

