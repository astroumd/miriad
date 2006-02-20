c************************************************************************
	program smarewt
	implicit none
c
c= smarewt - Copy a uv dataset, re-weighting the visibility.
c& jhz 
c: uv analysis
c+
c	SmaReWt copies a uv dataset, calculating the mean values
c       of antenna gains in amplitude and multiplying the visibility 
c       variances by the mean antenna gains. The re-scaled visibility
c       variances can be used as the weights in the imaging process.
c@ vis
c	The name of the input uv data sets. Several can be given (wild
c	cards are supported). No default.
c@ gain
c       The name of a uvdata with a gain table based on which,
c       the visibility data are re-weighted.
c@ select
c	The normal uv selection commands. The default is copy everything.
c@ line
c	The normal uv linetype in the form:
c	  line,nchan,start,width,step
c	The default is all channels (or all wide channels if there are no
c	spectral channels). The output will consist of only spectral or
c	wideband data (but not both).
c@ options
c       This gives extra processing options.
c          scalar    Means do scalar averaging for the amplitude of gains.
c                    This is the default. 
c          vector    Means do vector averaging for the amplitude of gains.
c          report    Means printing the mean antenna-based gains.
c@ out
c	The name of the output uv data set. No default.
c--
c  History:
c  jhz: 2006-2-17  made the original version as suggested
c                  by Dan Marrone.
c  jhz: 2006-2-20  rewrite the inline doc.
c
c  Bugs:
c------------------------------------------------------------------------
	include 'smagpplt.h'
        character version*(*)
	parameter(version='SmaReWt: version 1.0 20-feb-06')
        character uvflags*12,ltype*16,out*64
        integer npol,Snpol,pol,tIn,tOut,vupd,nread,nrec,i
        integer tvis
        real jyperk
        logical dotaver,doflush,buffered,PolVary
        logical first, doreport
        logical ampsc
        logical ok,donenpol
        double precision preamble(5)
        complex data(MAXCHAN)
        logical flags(MAXCHAN), dogain
        integer maxsels, maxspect
        parameter(maxsels=256, maxspect=49)
        character gain*64
        double precision t0
        real times(maxtimes)
        double precision jtime(6154)
        complex gbuf(maxgains)
        complex g(maxgains)
        integer nfeeds,ntau,nants,nsols,iostat,nrewt
        integer len1, j,ifeed,ngains(10,2,1),offset
        real sels(maxsels)
        real rgain(10,2,6145), igain(10,2,6145), amp(10,2,6145)
        real rewtfactor(10,2,1),avrgain(10,2,1),avigain(10,2,1)
        real avamp(10,2,1), avrewtfactor(2)
        real tsys(maxant*maxwin),rwtsys(maxant*maxwin)
c
c  Externals.
c
        logical uvDatOpn,  hdprsnt 
c
c  intialization
c
          do j=1,maxsels
          sels(j)=0.0
          end do
          do ifeed=1,2
          do j=1,10
          rewtfactor(j,ifeed,1)=0.0
          avamp(j,ifeed,1)=0.0
          avrgain(j,ifeed,1)=0.0
          avigain(j,ifeed,1)=0.0
          ngains(j,ifeed,1)=0
          end do
          end do
c
c  Get the input parameters.
c
	call output(version)
	call keyini
        call GetOpt(uvflags,ampsc,doreport)
	call uvDatInp('vis',uvflags)
        call keya('gain',gain, ' ')
	call keya('out',out,' ')
	call keyfin
c
c  Check the input parameters.
c
	if(out.eq.' ')call bug('f','Output file must be specified')
         
        call output( 'processing gains in '//gain(1:len1(gain)))
            call hopen(tin,gain,'old',iostat)
            if(iostat.ne.0)then
            call bug('w','Error opening input '//gain)
            call bugno('f',iostat)
            endif
            dogain = hdprsnt(tin,'gains')
            if(.not.dogain)call bug('f','gains table not present')
            call gload(tin,t0,times,jtime,g,nfeeds,ntau,nants,
     *    nsols,sels, maxgains,maxtimes)
            call gncvt(g,gbuf,nfeeds,ntau,nants*nsols)
            if(nfeeds.eq.2) 
     *    call bug('f','Not implemented yet for nfeeds=2.')
            do ifeed=1,nfeeds
c  feeds_id = ifeed
            do j=1,nants
c  anti_d = j
                offset = ifeed + (j-1)*nfeeds
            do i=1,nsols
            rgain(j,ifeed,i)=real(gbuf(offset+(i-1)*nfeeds*nants))
            igain(j,ifeed,i)=aimag(gbuf(offset+(i-1)*nfeeds*nants))
            amp(j,ifeed,i)=sqrt(rgain(j,ifeed,i)**2+igain(j,ifeed,i)**2)
            if((rgain(j,ifeed,i)**2+igain(j,ifeed,i)**2).gt.0) then
            avrgain(j,ifeed,1) = avrgain(j,ifeed,1)+rgain(j,ifeed,i)
            avigain(j,ifeed,1) = avigain(j,ifeed,1)+igain(j,ifeed,i)
            ngains(j,ifeed,1) = ngains(j,ifeed,1) + 1
            avamp(j,ifeed,1) = avamp(j,ifeed,1)+amp(j,ifeed,i)
            end if
            end do
            if(ngains(j,ifeed,1).ne.0) then
            if(.not.ampsc)
     *      rewtfactor(j,ifeed,1) = sqrt(avrgain(j,ifeed,1)**2 +
     *      avigain(j,ifeed,1)**2)/ngains(j,ifeed,1)
            if(ampsc)
     *      rewtfactor(j,ifeed,1)=avamp(j,ifeed,1)/ngains(j,ifeed,1)
            else
            rewtfactor(j,ifeed,1) = 0.0
            end if
            end do
            end do
c
c normalization
c
            if (doreport) call output('ant gain-weight')            
            do ifeed=1,nfeeds
            avrewtfactor(ifeed) = 0.0
            nrewt = 0.0
            do j=1,nants
            if(rewtfactor(j,ifeed,1)>0) then
            avrewtfactor(ifeed) = 
     *      avrewtfactor(ifeed) + rewtfactor(j,ifeed,1)
            nrewt = nrewt + 1
            end if
            end do
            if (nrewt.eq.0) call bug('f', 'No gain solutions found.')
            avrewtfactor(ifeed) =
     *      avrewtfactor(ifeed)/nrewt
            do j=1,nants
            if(rewtfactor(j,ifeed,1).gt.0.0) then
            rewtfactor(j,ifeed,1)
     *      =rewtfactor(j,ifeed,1)/avrewtfactor(ifeed)
            else
             rewtfactor(j,ifeed,1)=1.0
            end if

            if(doreport) write(*,*) j,rewtfactor(j,ifeed,1)
            end do
            end do
          
           call hclose(tin)
           call output('processing re-weighting vis variance.')
c
c  Various initialisation.
c
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
c  Open the input and the output files.
c
	dowhile(uvDatOpn(tvis))
	  call uvDatGta('ltype',ltype)
	  call VarInit(tvis,ltype)
	  call uvVarIni(tvis,vupd)
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
	    call hdcopy(tvis,tOut,'history')
	    call hisopen(tOut,'append')
	    call hiswrite(tOut,'SMAREWT: Miriad '//version)
	    call hisinput(tOut,'SMAREWT')
	    call hisclose(tOut)
	    first = .false.
	  endif
	  call VarOnit(tvis,tOut,ltype)
c
c  Loop over the data.
c
	  call uvDatRd(preamble,data,flags,maxchan,nread)

	  dowhile(nread.gt.0)
              
c
c  Count the number of records read.
c
	    nrec = nrec + 1
                ok = .true.
                call uvputvri(tOut,'npol',npol,1)
		call uvDatGti('pol',pol)
		call uvputvri(tOut,'pol',pol,1)
		call VarCopy(tvis,tOut)
		call uvDatGtr('jyperk',jyperk)
		call uvputvrr(tOut,'jyperk',jyperk,1)
                call uvgetvrr(tvis,'systemp',tsys,nants)
                do j=1,nants
c only for feed 1
                rwtsys(j) =  tsys(j)*rewtfactor(j,1,1)
                end do
                call uvputvrr(tOut,'systemp',rwtsys, nants)
		call uvwrite(tOut,preamble,data,flags,nread)
c
c  Keep on going. Read in another record.
	  call uvDatRd(preamble,data,flags,maxchan,nread)
	  enddo
	  call uvDatCls
	enddo
c
c  Write things to the header which describe the data as a whole.
c
	if(first)call bug('f','Error opening input')
	if(nrec.eq.0)call bug('f','No data found')
c
c  Update the history and close up files.
c
	call uvclose(tOut)
	end
c
c************************************************************************
        subroutine GetOpt(uvflags,ampsc,doreport)
c
        implicit none
        logical ampsc,doreport
        character uvflags*(*)
c
c  Determine the flags to pass to the uvdat routines.
c
c  Output:
c    uvflags    Flags to pass to the uvdat routines.
c    ampsc      True for amp-scalar averaging
c    doreport   Printing out the mean antenna-based gain
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=3)
        character opts(nopts)*9
        logical present(nopts),vector
        data opts/'vector   ','scalar   ','report   '/
c
        call options('options',opts,present,nopts)
        vector  = present(1)
        ampsc   = present(2)
        doreport= present(3)
c
c Default averaging is vector
c
        if (vector .and. ampsc) call bug ('f',
     *     'You can''t have options=vector and options=scalar')
        if (.not.vector .and. .not.ampsc) ampsc=.true.
c
c Set up calibration flags
c
        uvflags = 'dslr3'
       end

