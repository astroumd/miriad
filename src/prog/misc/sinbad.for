c***********************************************************************
        program sinbad
        implicit none
c
c= sinbad - Calculate (on-off)/off* Tsys for autocorrelation data.
c& mchw
c: uv analysis
c+
c       SINBAD is a MIRIAD task to calculate (ON-OFF)/OFF*TSYS for
c       autocorrelation data. The preceeding OFF and TSYS record
c	for each antenna is used. Flags on the OFF scans are ignored.
c	Flags on the ON scans are copied to the output file.
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
c--
c
c  History:
c    mchw 29jan97  New task for Marc.
c    mchw 05feb97  write same type of correlation data as input file.
c    mwp  13may99  removed call to LogClose(); a fatal error with no
c                  preceding LogOpen().
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='SINBAD: version  05-FEB-97')
	integer maxsels
	parameter(maxsels=1024)
c
	real sels(maxsels)
	real start,step,width
	character linetype*20,vis*80,out*80
	complex data(maxchan)
	logical flags(maxchan)
        logical first,new,dopol,PolVary,doon
	integer lIn,lOut,nchan,npol,pol,SnPol,SPol,on,i,ant
        character type*1
        integer length 
        logical updated
	double precision uin,vin,timein,basein
	common/preamb/uin,vin,timein,basein
	real off(MAXCHAN,MAXANT),tsys(MAXCHAN,MAXANT)
c	data off/MAXCHAN*MAXANT*0./, tsys/MAXCHAN*MAXANT*1./
	integer num,non,noff,ntsys
	data num/0/,non/0/,noff/0/,ntsys/0/
c
c  Read the inputs.
c
	call output(version)
 	call keyini
	call keyf('vis',vis,' ')
	call SelInput('select',sels,maxsels)
	call keya('line',linetype,' ')
	call keyi('line',nchan,0)
	call keyr('line',start,1.)
	call keyr('line',width,1.)
	call keyr('line',step,width)
 	call keya('out',out,' ')
	call keyfin
c
c  Check user inputs.
c
	if(vis.eq.' ')call bug('f','Input file must be given (vis=)')
        if(out.eq.' ')call bug('f','Output file name is missing')
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
c
c  Loop thro' the data, writing (ON-OFF)/OFF*TSYS
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
		non = non + 1
		do i=1,nchan
		  data(i) = (data(i)-off(i,ant))/off(i,ant)*tsys(i,ant)
		enddo
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
	print *,'records written: (on-off)/off*tsys:',non
c
c  Close up shop.
c
c	call LogClose
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
