c************************************************************************
	program listpol
	implicit none
c
c= LISTPOL - List polarization for averaged uv-data.
c& mchw
c: uv analysis
c+
c	LISTPOL - Solve for instrumental polarization from averaged uv-data.
c	LISTPOL does not apply the gains or bandpass corrections.
c@ vis
c	The input UV dataset name. No default.
c@ select
c	This selects the data to be processed, using the standard uvselect
c	format. Default uses all the data.
c@ line
c	this gives the linetype that is used, in the
c	form:
c	  type,nchan,start,width,step
c	where type can be `channel' (default), `wide' or `velocity'.
c	Default is channel,1,1,1,1
c@ log
c	The list output file name. The default is the terminal.
c--
c
c  History:
c   26jul96 mchw
c   15apr97 mchw  Change name to listpol.
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='LISTPOL: version  26-JUL-96')
	real rtoh,rtod,pi
	integer maxsels
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	parameter(maxsels=1024)
c
	real sels(maxsels)
	real start,step,width
	character linetype*20,vis*80,out*80
	complex data(MAXCHAN)
	complex RR(MAXCHAN),LL(MAXCHAN),RL(MAXCHAN),LR(MAXCHAN)
	logical flags(MAXCHAN)
	integer tvis,numchan,num,base0,pol,i,ant1,ant2,nchan
	double precision uin,vin,timein,basein
	common/preamb/uin,vin,timein,basein
c
c  Read the inputs.
c
	call output(version)
 	call keyini
	call keyf('vis',vis,' ')
	if(vis.eq.' ')call bug('f','Input file must be given (vis=)')
	call SelInput('select',sels,maxsels)
	call keya('line',linetype,'channel')
	call keyi('line',numchan,1)
	call keyr('line',start,1.)
	call keyr('line',width,1.)
	call keyr('line',step,width)
 	call keya('log',out,' ')
	call keyfin
c
c  Open the output text file.
c
 	call LogOpen(out,' ')
c
c  Open the data file, apply selection, do linetype initialisation and
c  determine the variables of interest.
c
	call uvopen(tvis,vis,'old')
	call SelApply(tvis,sels,.true.)
      	call uvset(tvis,'data',linetype,numchan,start,width,step)
	call uvset(tvis,'coord','wavelength',0,0.,0.,0.)
c
c  Read through the file, listing what we have to.
c
	num=0
	call uvread(tvis,uin,data,flags,maxchan,numchan)
	dowhile(numchan.gt.0)
	 nchan = numchan
	 base0 = basein
	 call BasAnt(basein,ant1,ant2)
	 dowhile(basein.eq.base0.and.numchan.gt.0)
	  call uvrdvri(tvis,'pol',pol,1)
	  num = num + 1
	  print *, ant1, ant2, pol, (data(i),i=1,nchan)
	  if(pol.eq.-1)then
	    do i=1,nchan
	      RR(i) = data(i)
	    enddo
	  else if(pol.eq.-2)then
	    do i=1,nchan
	      LL(i) = data(i)
	    enddo
	  else if(pol.eq.-3)then
	    do i=1,nchan
	      RL(i) = data(i)
	    enddo
	  else if(pol.eq.-4)then
	    do i=1,nchan
	      LR(i) = data(i)
	    enddo
	  endif
	  call uvread(tvis,uin,data,flags,maxchan,numchan)
	 enddo
c
c  List the averaged data.
c
	  print *, ant1, ant2, '   2*LR/(RR+LL)',
     *			 ((2.*LR(i)/(RR(i)+LL(i))),i=1,nchan)
	  print *, ant1, ant2, '   2*RL/(RR+LL)',
     *			 ((2.*RL(i)/(RR(i)+LL(i))),i=1,nchan)
c
	enddo
c
c  Close up shop.
c
	call LogClose
	call uvclose(tvis)
	end
c********1*********2*********3*********4*********5*********6*********7**
