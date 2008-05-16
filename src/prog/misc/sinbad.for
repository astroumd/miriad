c***********************************************************************
        program sinbad
        implicit none
c
c= sinbad - Calculate Tsys*(on-off)/off*  for autocorrelation data.
c& mchw
c: uv analysis
c+
c       SINBAD is a MIRIAD task to calculate (ON-OFF)/OFF*TSYS for
c       autocorrelation data. The preceeding OFF and TSYS record
c	for each antenna is used. Flags on the OFF scans are ignored.
c	Flags on the ON scans are copied to the output file.
c       Missing TSYS can be replaced via the tsys= keyword as a last
c       resort, or the spectral window based systemp() UV variable.
c@ vis
c       The name of the input autocorrelation data set.
c       Only one name must be given.
c@ select
c       The normal uv selection commands. See the Users manual for details.
c       The default is to process all data.
c@ line
c       The normal uv linetype in the form:
c         line,nchan,start,width,step
c       The default is all channels. 
c	The output consists of spectral channels only.
c@ out
c       The name of the output uv data set. No default.
c@ tsys
c       Value for flat tsys spectrum if neither band average systemp 
c       nor full spectrum is available.
c@ options 
c       Different computational output options (mainly for debugging).
c       Exclusively one of the following (minimum match):
c         'spectrum'     Compute Tsys*(on-off/off).  This is the default
c         'difference'   Compute (on-off)
c         'ratio'        Compute on/off
c--
c
c  History:
c    mchw    29jan97  New task for Marc.
c    mchw    05feb97  write same type of correlation data as input file.
c    pjt/mwp 19feb08  safeguard off before on, tsys=1 if not present
c    pjt     25feb08  use window based systemp array if tsys not available.
c    mwp     16may08  added options for spectrum, difference, ratio
c    mwp     16may08-2  off() must be complex!!! very funny behavior if not.
c---------------------------------------------------------------------------
	include 'maxdim.h'
	character version*80,versan*80
	integer maxsels
	parameter(maxsels=1024)
c
	real sels(maxsels)
	real start,step,width,tsys1
	character linetype*20,vis*80,out*80
	complex data(maxchan)
	logical flags(maxchan)
        logical first,new,dopol,PolVary,doon
	integer lIn,lOut,nchan,npol,pol,SnPol,SPol,on,i,j,ant
        character type*1
        integer length 
        logical updated
	double precision uin,vin,timein,basein
	common/preamb/uin,vin,timein,basein
	complex off(MAXCHAN,MAXANT)
        real    tsys(MAXCHAN,MAXANT)
	integer num,   non,   noff,   ntsys
	data    num/0/,non/0/,noff/0/,ntsys/0/
        logical spectrum, diffrnce, ratio
c
c  Read the inputs.
c
        version = versan('sinbad',
     *  '$Id$')
 	call keyini
        call getopt(spectrum,diffrnce,ratio)
	call keyf('vis',vis,' ')
	call SelInput('select',sels,maxsels)
	call keya('line',linetype,' ')
	call keyi('line',nchan,0)
	call keyr('line',start,1.)
	call keyr('line',width,1.)
	call keyr('line',step,width)
 	call keya('out',out,' ')
        call keyr('tsys',tsys1,-1.0)
	call keyfin
c
c  Check user inputs.
c
	if(vis.eq.' ')call bug('f','Input file name (vis=) missing')
        if(out.eq.' ')call bug('f','Output file name (out=) missing')
c
c default is spectrum, so set it if nothing specified on 
c command line.  Note I could do this in getopt() like
c  spectrum = present(spectrum) || ( !present(diffrnce) && !present(ratio) )
c but this is a little more obvious
c
        if( ( spectrum .eqv. .false. ) .and.
     *      ( diffrnce .eqv. .false. ) .and.
     *      ( ratio    .eqv. .false. ) ) then
            spectrum = .true.
        endif
c
c  Open the output file.
c
        call uvopen(lOut,out,'new')
c
c  Open the data file, apply selection, do linetype initialisation and
c  determine the variables of interest.
c
	call uvopen(lIn,vis,'old')
	call SelApply(lIn,sels,.true.)
	  if(linetype.ne.' ')
     *	    call uvset(lIn,'data',linetype,nchan,start,width,step)
          call VarInit(lIn,'channel')
        do j=1,MAXANT
           do i=1,MAXCHAN
              tsys(i,j) = tsys1
           enddo
        enddo
c
c  Read through the file, listing what we have to.
c
	call uvread(lIn,uin,data,flags,maxchan,nchan)
c
c  Other initialisation.
c
        first = .true.
        new = .true.
        SnPol = 0
        SPol = 0
        PolVary = .false.
        call uvprobvr(lIn,'corr',type,length,updated)
        if(type.ne.'r'.and.type.ne.'j'.and.type.ne.'c')
     *		call bug('f','no spectral data in input file')
        call uvset(lOut,'corr',type,0,0.,0.,0.)
        call uvprobvr(lIn,'npol',type,length,updated)
        dopol = type.eq.'i'
	if(dopol) call bug('w', 'polarization variable is present')
        call uvprobvr(lIn,'on',type,length,updated)
        doon = type.eq.'i'
	if(.not.doon) call bug('w', '"on" variable is missing')
        if (tsys1.lt.0.0) call getwtsys(lIn,tsys,MAXCHAN,MAXANT)

c
c  Loop through the data, writing (ON-OFF)/OFF*TSYS
c
	dowhile (nchan.gt.0)
	  num = num + 1
c	  print *, num,basein,basein/256
c
c  Determine the polarisation info, if needed.
c
            if(dopol)then
              call uvgetvri(lIn,'npol',nPol,1)
              if(nPol.le.0) call bug('f',
     *          'Could not determine number of polarizations present')
              if(nPol.ne.SnPol)then
                call uvputvri(lOut,'npol',nPol,1)
                PolVary = SnPol.ne.0
                SnPol = nPol
              endif
              call uvgetvri(lIn,'pol',Pol,1)
              if(Pol.ne.SPol)then
                call uvputvri(lOut,'pol',Pol,1)
                SPol = Pol
              endif
            endif
c
c  Copy the variables we are interested in.
c
            call VarCopy(lIn,lOut)
c
c  Now process the line data.
c
            if(doon)then
              call uvgetvri(lIn,'on',on,1)
	      ant = basein/256
	      if(on.eq.0)then
		noff = noff + 1
		do i=1,nchan
		  off(i,ant) = data(i)
		enddo
	      else if(on.eq.-1)then
		ntsys = ntsys + 1
		do i=1,nchan
		  tsys(i,ant) = data(i)
		enddo
	      else if(on.eq.1)then
                if (noff.eq.0) call bug('f','No off before on found')
                if (ntsys.eq.0 .and. tsys1.lt.0.0)
     *              call getwtsys(lIn,tsys,MAXCHAN,MAXANT) 
		non = non + 1
                if(spectrum) then
c********1*********2*********3*********4*********5*********6*********7**
		  do i=1,nchan
		   data(i) = tsys(i,ant)*(data(i)/off(i,ant)) - 1.0
		  enddo
                else if(diffrnce) then
		  do i=1,nchan
		    data(i) = data(i)-off(i,ant)
		  enddo
                else if(ratio) then
		  do i=1,nchan
		     data(i) = data(i)/off(i,ant)
		  enddo
                endif
                call uvwrite(lOut,uin,data,flags,nchan)
	      else
		call bug('w','value of on not 1, 0 or -1')
              endif
            endif
c
c  Loop the loop.
c
	  call uvread(lIn,uin,data,flags,maxchan,nchan)
	enddo
c
	print *,'records read: ',num
	print *,'records read: on:',non,'  off:',noff,'  tsys:',ntsys
        if (spectrum) then 
	  print *,'records written: (on-off)/off*tsys:',non
        endif
        if (diffrnce) then 
	  print *,'records written: (on-off)',non
        endif
        if (ratio) then 
	  print *,'records written: (on/off)',non
        endif

        if (ntsys.eq.0) then
          if (tsys1.lt.0.0) then
            call bug('w','No Tsys data on=-1 found, used systemp')
          else
            call bug('w','No Tsys data on=-1 found, used default tsys=')
          endif
        endif

c
c  Close up shop.
c
	call uvclose(lIn)
c
c  Finish up the history, and close up shop.
c
        call hisopen(lOut,'append')
        call hiswrite(lOut,'SINBAD: Miriad '//version)
        call hisinput(lOut,'SINBAD')
        call hisclose (lOut)
        call uvclose(lOut)
        end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine getwtsys(lIn,tsys,mchan,mant)
        implicit none
        integer lIn, mchan, mant
        real tsys(mchan,mant)
c
        logical updated
        integer length,nants,nchan,nspect,i,j,i2
        integer nschan(100),ischan(100)
        real systemp(1024)
        character type*1
        
        call uvprobvr(lIn,'systemp',type,length,updated)
        if (updated .and. length.gt.0) then
           call uvgetvri(lIn,'nants',nants,1)
           call uvgetvri(lIn,'nspect',nspect,1)
           call uvgetvri(lIn,'nchan',nchan,1)
           call uvgetvri(lIn,'nschan',nschan,nspect)
           call uvgetvri(lIn,'ischan',ischan,nspect)
           call uvgetvrr(lIn,'systemp',systemp,nants*nspect)
           do i=1,nspect
              do i2=ischan(i),ischan(i)+nschan(i)-1
                 do j=1,nants
                    tsys(i2,j) = systemp(j+(i-1)*nants)
                 enddo
c                 write(*,*) i2,' :t: ',(tsys(i2,j),j=1,nants)
              enddo
           enddo
           
        endif

        end
c
c********1*********2*********3*********4*********5*********6*********7**
cc Get the various (exclusive) options
        subroutine getopt(spectrum,diffrnce,ratio)
        implicit none
        logical spectrum, diffrnce, ratio
c
        integer nopt
        parameter(nopt=3)
        character opts(nopt)*10
        logical present(nopt)
        data opts/'spectrum  ','difference','ratio    '/
        call options('options',opts,present,nopt)
        spectrum = present(1)
        diffrnce = present(2)
        ratio      = present(3)
        end

