c************************************************************************
	program uvlist
	implicit none
c
c= UVLIST - Print data, variables and statistics from uv dataset
c& mchw
c: uv analysis
c+
c	UVLIST lists a MIRIAD UV data file. It can list either the
c	variables or the correlation data.
c	    Generally the data are presented in their raw units, but some
c	variables and data can undergo some massaging. In particular, the
c	time is given as a standard calendar date. UVLIST does not apply
c	the gains or bandpass corrections when listing the data.
c@ vis
c	The input UV dataset name. No default.
c@ options
c	This controls what is listed, and the verbosity. Several can be
c	given, separated by commas. Minimum match is used. Possible values
c	are:
c	  "brief"     Short listing (default).
c	  "data"      correlation data.
c	  "average"   average and rms.
c	  "allan"     Allan standard deviation.
c	  "history"   the history file.
c	  "flux"      flux visibility, uvdistance and Jy/AveAmp.
c	  "full"      The opposite of "brief".
c	  "list"      ut,lst,ant,u,v, AZ, EL, paralactic angle, dra, ddec.
c	  "variables" uv variables.
c	  "stat"      max, ave, rms and high channels for each record.
c	  "birds      frequencies for high channels in each record.
c	  "spectra"   information about the spectral windows.
c	If no options are given, uvlist uses options=brief,data.
c@ select
c	This selects the data to be processed, using the standard uvselect
c	format. Default is all data.
c@ line
c	For options=data, this gives the linetype that is printed, in the
c	form:
c	  type,nchan,start,width,step
c	where type can be `channel' (default), `wide' or `velocity'.
c	The default is to print all the raw channel data (no averaging,
c	etc). If options=brief, a maximum of only 6 channels will be printed.
c@ scale
c	Scale factor applied to the amplitudes before printing them.
c	Default: 1
c@ recnum   
c	The number of output records. This is used to cut off long outputs.
c	The default is 1.
c@ log
c	The list output file name. The default is the terminal.
c--
c
c  History:
c    wh    oct89 - Original version.
c    RJS 20Mar89 - Broke one line longer than 72 characters into two lines.
c    wh  4apr89  - print ut/lst in hr:min:sec  and fix bugs
C    wh  7apr89  - change format to print julian date
c    RJS 24apr89 - Changed the baseline parameter to double precision.
c		   Added a "save" statement to writeit.
c		   Declared otherwise undeclared variables everywhere.
c		   Several cosmetic changes.
c    wh  25apr89 - ut/lst need not be present anymore
c    wh  28apr89 - nwide can be 0
c    wh  12may89 - bigger field for time/log
c    rjs 12may89 - Improved code to deal with a missing nwide value.
c    rjs 26may89 - Checks for long variables in PRINTHD.
c    rjs 29may89 - Deleted some unused variables.
c    mchw31oct89 - fixed bugs, converted units and used amphase routine.
c    rjs  1nov89 - Improved error checking, fixed more bugs, converted
c		   it to use the "log" routines.
c    mchw 6nov89 - Added "spec" option to list spectral windows.
c    rjs  7nov89 - Significant rework. Changed it to use the selection
c		   and linetype routines. Included the functionality of the
c		   UVPRT task. Added 'brief' mode.
c    8nov89 mchw - add ra to header list; corrected sign of velocity incr.
c    8nov89 rjs  - More minor mods.
c   12feb90 rjs  - Again minor mods.
c    9mar90 rjs  - Change in calling sequence to JulDay.
c   27mar90 rjs  - Changed date format for brief data listings.
c   28mar90 rjs  - Changed 'option' to 'options'. Minor other correction.
c   31mar90 rjs  - Fixed default linetype for wide only file.
c    2may90 pjt  - line*128 ; maxdim.h now gets maxchan
c    4may90 mchw - replaced line*80 so it works again.
c    7may90 mchw - fixed listspec so it works for nspect.gt.6
c   15may90 mchw - changed writeit to have same fix as in ImList.
c   16jul90 mchw - Message for nspect=0 in case user requests spectra.
c    9jan91 rjs  - Fixed format in long listing to deal with more than
c		   999 channels.
c   18mar91 mchw - Fixed format in printhd so cray can handle long lines.
c   22may91 mchw - Changed keya to keyf.
c   17jun91 jm   - Fixed default value of UT.
c   19jun91 mchw - Added options=list.
c   25jun92 rjs  - Doc changes, and list the polarisation type. Misc
c		   changes.
c   12feb93 rjs  - Improved some indentation. Cosmetic change.
c   29mar93 mchw - List statistics and highest channels.
c   01apr93 rjs  - Correct continuation, and initialise some variables.
c   07may93 mchw - fixed bug with needhd in options=list?
c   01jul93 mchw - time average option. Does not yet handle polariation.
c   06jul93 rjs  - print lat and long in dd:mm:ss.s format. Eliminate
c		   use of angles (replace with rangle and hangle).
c   12jul93 mchw - Don't list if all channels flagged in options=stat.
c   15jul93 pjt  - Got rid of dangerous string counters and use LEN1
c   16sep93 rjs  - Rename bsrch to binsrch.
c   12dec93 mchw - list Allan standard deviation.
c   28mar94 pjt  - added scale=
c   15apr94 pjt/mchw  - fixed options=stat features to use line=
c			fixed header output, and use MAXWIN from maxdim.h
c   09may94 mchw - test if scale.eq.1. for efficiency.
c   18dec95 mchw - added options=flux      List planet flux visibility.
c   15apr96 mchw - added dra, ddec to options=list.
c   26may96 pjt  - made max filename length a bit more reasonable (80)
c   14jun96 mchw - replace rangle and hangle, with rangleh and hangleh.
c   26jun96 mchw - Get paralactic angle using varmint routine.
c   06aug96 mchw - List flux visibility, uvdistance and Jy/AveAmp
c   24oct96 mchw - List frequencies for high channels in each record.
c   10jun97 rjs/mchw - Use keyline to uniformly handle linetype.
c   26dec97 pjt  - more ansi (x -> 1x in format 100; Stat -> ShowStat [g77]
c   28oct99 mchw - Extend phase in averaging routine.
c   27oct00 mchw - Changes to accomodate more antennas.
c   19jan02 pjt  - basant needs double precision argument
c   27jun02 mchw - use latitude uv-variable if present.
c   11dec02 pjt  - subroutine q/r/d/ZERO to bypass big DATA statement that makes big binaries
c   13mar03 pjt  - need to use MAXBASE2 mor multidim arrays...
c   14aug03 mchw - replace varmint with parang in options=list.
c   14dec03 pjt  - fix initialization bug for options=average
c   06feb04 mchw - added AZ to options=list.
c   21may04 pjt  = CVS merged the two previous modifications
c   19jun05 pjt  - fixes for g95: num() is now integer array
c   01jul05 jhz  - add a space (1x) before Amp and Phase in the formats
c                  for the vis list in AveDat,BriefDat,Allan
c-----------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='UVLIST: version  19-jun-05')
	real rtoh,rtod,pi
	integer maxsels
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	parameter(maxsels=1024)
c
	real sels(maxsels)
	real start,step,width,scale
	character linetype*20,vis*80,out*80,line*80,last*1,date*18
	complex data(maxchan)
	logical flags(maxchan)
	logical dohead,dodata,dospect,dohist,dobrief,dolist,dostat
	logical eof,more,ltemp,doallan,doave,doflux,dobird
	double precision ut,lst,visno
	integer unit,numrec,numchan,num,time0,p,i
	double precision uin,vin,timein,basein
	common/preamb/uin,vin,timein,basein
c
c  Externals.
c
	logical uvupdate
c
c  Read the inputs.
c
	call output(version)
 	call keyini
	call keyf('vis',vis,' ')
	if(vis.eq.' ')call bug('f','Input file must be given (vis=)')
	call GetOpt(dohead,dodata,dospect,dohist,
     *		    dobrief,dolist,dostat,doallan,doave,doflux,dobird)
	call SelInput('select',sels,maxsels)
	call keyline(linetype,numchan,start,width,step)
	call keyi('recnum',numrec,1)
 	call keya('log',out,' ')
        call keyr('scale',scale,1.0)
	call keyfin
c
c  Open the output text file.
c
 	call LogOpen(out,' ')
c
c  Open the data file, apply selection, do linetype initialisation and
c  determine the variables of interest.
c
	call uvopen(unit,vis,'old')
	call SelApply(unit,sels,.true.)
	if(dodata.or.dolist.or.dostat.or.doflux.or.dobird)then
	  if(linetype.ne.' ')
     *	    call uvset(unit,'data',linetype,numchan,start,width,step)
	  call uvset(unit,'coord','wavelength',0,0.,0.,0.)
	endif
	if(dohead)call VarLoad(unit,dobrief)
c
c  Read through the file, listing what we have to.
c
	num=0
	call uvread(unit,uin,data,flags,maxchan,numchan)
	if(scale.ne.1.)then
          do i=1,numchan
            data(i) = data(i) * scale
          enddo
	endif

	time0 = timein + 100
	call writein(unit,vis,dohead,dodata,dospect,
     *	  dohist,dolist,dobrief,dostat,doallan,doave,doflux,dobird,
     *                  scale)
	last = ' '
	dowhile ( numchan.gt.0 .and. num.lt.numrec)
	  num = num + 1
c
c  List the header, if required.
c
	  if(dohead.and.uvupdate(unit))then
	    call printhd(unit,timein)
	    last = 'v'
	  endif
c
	  if(dodata.or.dolist.or.dostat.or.doflux.or.dobird)then
	    call uvinfo(unit,'visno',VisNo)
	    call uvrdvrd(unit,'ut',ut,
     *			((timein-0.5)-int((timein-0.5)))*24.d0/rtoh)
            call uvrdvrd(unit,'lst',lst,0.d0/rtoh)
	    call uvrdvri(unit,'pol',p,0)
	    if(dolist)then
	      call ListDat(last.ne.'d',unit,uin,vin,basein,ut,lst,
     *			dobrief,nint(VisNo),data,flags,numchan,p)
	    else if(dobrief)then
	      if(int(timein-0.5).ne.time0)then
	        ltemp = .true.
		time0 = int(timein-0.5)
		call JulDay(dble(time0+0.5),'H',date)
		call LogWrite('Data values for '//date(1:7),more)
	      else
		ltemp = last.ne.'d'
	      endif
	      if(doave)then
		call AveDat(ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      else if(doallan)then
		call Allan(ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      else if(doflux)then
		call Pflux(unit,ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      else if(dobird)then
		call bird(unit,ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      else if(dostat)then
		call ShowStat(ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      else
	        call BriefDat(ltemp,uin,vin,timein,basein,
     *				nint(VisNo),data,flags,numchan,p)
	      endif
	    else
	      call LongDat(last.ne.'d',uin,vin,timein,basein,ut,lst,
     *				nint(VisNo),data,flags,numchan,p)
	    endif
	    last = 'd'
	  endif
c
c  List the spectra info, if required.
c
	  if(dospect)then
	    call listspec(unit)
	    last = 's'
	  endif
c
c  Loop the loop.
c
	  call uvread(unit,uin,data,flags,maxchan,numchan)
          do i=1,numchan
            data(i) = data(i) * scale
          enddo
	enddo
c
c  List the averaged data.
c
	if(doave)then
	  call AveDat(ltemp,uin,vin,timein,basein,
     *				-1,data,flags,numchan,p)
	else if(doallan)then
	  call Allan(ltemp,uin,vin,timein,basein,
     *				-1,data,flags,numchan,p)
	endif
c
c  Copy across the history file, if required.
c
	if(dohist)then
	  call LogWrite(' ',more)
	  call LogWrite(' ***** History of '//vis,more)
	  call LogWrite(' ',more)
	  call hisopen(unit,'read')
	  call hisread(unit,line,eof)
	  dowhile(.not.eof)
	    call LogWrite(line,more)
	    call hisread(unit,line,eof)
	  enddo
	  call hisclose(unit)
	end if
c
c  Close up shop.
c
	call LogClose
	call uvclose(unit)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine Allan(needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  Compute Allan standard deviation.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A value of zero indicates unknown.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer mchan,maxpol,MAXPTS
	parameter(mchan=5,maxpol=12,MAXPTS=10)
	integer nchan,i,j,k, k0,length,ant1,ant2,bl
	logical more
	character line*128,ctime*10,pol*2
	real amp(mchan),arg(mchan),count
	character cflag(mchan)*1
	logical doave(MAXBASE2),first
	double precision preambl(4)
	integer num(MAXBASE2)
	real amps(maxpts,mchan,MAXBASE2),args(maxpts,mchan,MAXBASE2)
	double precision uave(MAXBASE2),vave(MAXBASE2),timeave(MAXBASE2)
	double precision baseave(MAXBASE2)
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	data first/.TRUE./
cpjt	data doave/MAXBASE*.false./
cpjt	data num/MAXBASE*0./
cpjt	data uave,vave,timeave/MAXBASE*0.d0,MAXBASE*0.d0,MAXBASE*0.d0/
cpjt	data baseave/MAXBASE*0.d0/
c
	if(first)then
	   call qzero(MAXBASE2,doave)
	   call izero(MAXBASE2,num)
	   call dzero(MAXBASE2,uave)
	   call dzero(MAXBASE2,vave)
	   call dzero(MAXBASE2,timeave)
	   call dzero(MAXBASE2,baseave)
	   first = .FALSE.
	endif
	if(needhd)then
	  nchan = min(mchan,numchan)
	  call LogWrite(' ',more)
	  call LogWrit(
     *	 'Allan deviation is calculated as: RMS[a(i-k)-2a(i)+a(i+k)]')
	  call LogWrit(
     *	 'averaged over #pts, where k is the sample interval')
	  length = 0
	  call cat(line,length,
     *	   '  #pts  k     Time      Ant    Pol U(kLam)  V(kLam)')
	  do j=1,nchan
	    call cat(line,length,'   Amp  Phase')
	  enddo
	  call LogWrite(line(1:length),more)
	  length = 0
	  call cat(line,length,
     *	   '                                            ')
	  call LogWrite(line(1:length),more)
	endif
c
c  Store the amp and phase and accumulate the average u,v,time.
c
      if(visno.gt.0)then
	preambl(1) = uin
	preambl(2) = vin
	preambl(3) = timein
	preambl(4) = basein
	call uvgetbl(preambl,data,numchan,bl)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	doave(bl) = .true.
	uave(bl) = uave(bl) + uin
	vave(bl) = vave(bl) + vin
	timeave(bl) = timeave(bl) + timein
	baseave(bl) = baseave(bl) + basein
	num(bl) = num(bl) + 1
	i = num(bl)
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	  if(flags(j))then
	    amps(i,j,bl) = amp(j)
	    args(i,j,bl) = arg(j)
	  endif
	enddo
	return
      endif
c
c  Compute Allan standard deviation and average u,v,time, baseline.
c
      do bl=1,MAXBASE2
       if(doave(bl))then
	uave(bl) = uave(bl) / num(bl)
	vave(bl) = vave(bl)  / num(bl)
	timeave(bl) = timeave(bl) / num(bl)
	baseave(bl) = baseave(bl) / num(bl)
        call basant(baseave(bl),ant1,ant2)
c       pjt: does it matter now we changed num() from real to integer ?
	k = (num(bl)-1) / 2
	k0 = k
	do while(k.gt.0)
	 do j=1,nchan
	  if(num(bl).gt.0)then
	   amp(j) = 0.
	   arg(j) = 0.
	   count = 0.
	   do i=1+k,num(bl)-k
	     amp(j) = amp(j) + (amps(i-k,j,bl)
     *		 -2.* amps(i,j,bl) + amps(i+k,j,bl) )**2
	     arg(j) = arg(j) + (args(i-k,j,bl)
     *		 -2.* args(i,j,bl) + args(i+k,j,bl) )**2
	     count = count + 1
	   enddo
	   amp(j) = sqrt(amp(j)/count)
	   arg(j) = sqrt(arg(j)/count)
	   cflag(j) = ' '
	  else
	   cflag(j) = '*'
	  endif
	 enddo
c
c  Write out the results.
c
	 call JulDay(timeave(bl),'H',line(1:18))
	 ctime = line(9:18)
c
	 if(k.eq.k0)then
	 write(line,100) count,k,ctime,
     *   	       ant1,ant2,pol,0.001*uave(bl),0.001*vave(bl),
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchan)
100    format(f6.0,1x,i3,1x,a,i4,'-',i4,1x,a,2f9.2,10(1x,f8.3,1x,i4,a))
	 length = len1(line)
	 call LogWrite(line(1:length),more)
	 else
 	 write(line,'(f6.0,1x,i3,38x,10(f8.3,i4,a))')
     *	   count,k,(amp(j),nint(arg(j)),cflag(j),j=1,nchan)
	 length = len1(line)
	 call LogWrite(line(1:length),more)
	 endif
	 k = k / 2
	enddo
       endif
      enddo
      end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine AveDat(needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  List average and rms of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A value of zero indicates unknown.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer mchan,maxpol,maxave
	parameter(mchan=5,maxpol=12,MAXAVE=mchan*MAXBASE2)
	integer nchan,j,length,ant1,ant2,bl
	logical more
	character line*128,ctime*10,pol*2
	real amp(mchan),arg(mchan)
	character cflag(mchan)*1
	logical doave(MAXBASE2),first
	double precision preambl(4)
	real numave(mchan,MAXBASE2),recave(MAXBASE2)
	real ampave(mchan,MAXBASE2),phiave(mchan,MAXBASE2)
	real amprms(mchan,MAXBASE2),phirms(mchan,MAXBASE2)
	real theta(mchan,MAXBASE2)
	double precision uave(MAXBASE2),vave(MAXBASE2),timeave(MAXBASE2)
	double precision baseave(MAXBASE2)
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	data first/.TRUE./
cpjt	data doave/MAXBASE*.false./
cpjt	data numave/MAXAVE*0./,recave/MAXBASE*0./
cpjt	data ampave,phiave/MAXAVE*0.,MAXAVE*0./
cpjt	data amprms,phirms/MAXAVE*0.,MAXAVE*0./
cpjt	data uave,vave,timeave/MAXBASE*0.d0,MAXBASE*0.d0,MAXBASE*0.d0/
cpjt	data baseave/MAXBASE*0.d0/
c
	if(first)then
	   call qzero(MAXBASE2,doave)
	   call rzero(MAXAVE,numave)
	   call rzero(MAXAVE,recave)
	   call rzero(MAXAVE,ampave)
	   call rzero(MAXAVE,phiave)
	   call rzero(MAXAVE,amprms)
	   call rzero(MAXAVE,phirms)
	   call dzero(MAXBASE,uave)
	   call dzero(MAXBASE,vave)
	   call dzero(MAXBASE,timeave)
	   call dzero(MAXBASE,baseave)
	   first = .FALSE.
	endif
	if(needhd)then
	  nchan = min(mchan,numchan)
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,
     *	   ' # Vis    Time      Ant    Pol U(kLam)  V(kLam)')
	  do j=1,nchan
	    call cat(line,length,'   Amp  Phase')
	  enddo
	  call LogWrite(line(1:length),more)
	  length = 0
	  call cat(line,length,
     *	   '                                            ')
	  do j=1,nchan
	    call cat(line,length,'   rms  rms  ')
	  enddo
	  call LogWrite(line(1:length),more)
	endif
c
c  Accumulate the average and rms.
c
      if(visno.gt.0)then
	preambl(1) = uin
	preambl(2) = vin
	preambl(3) = timein
	preambl(4) = basein
	call uvgetbl(preambl,data,numchan,bl)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	doave(bl) = .true.
	uave(bl) = uave(bl) + uin
	vave(bl) = vave(bl) + vin
	timeave(bl) = timeave(bl) + timein
	baseave(bl) = baseave(bl) + basein
	recave(bl) = recave(bl) + 1.
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	  if(flags(j))then
c extend phase
            if(numave(j,bl).eq.0) theta(j,bl) = arg(j)
            arg(j) = arg(j) -360.*nint((arg(j)-theta(j,bl))/360.)
            theta(j,bl) = 0.5 * (arg(j)+theta(j,bl))
	    ampave(j,bl) = ampave(j,bl) + amp(j)
	    amprms(j,bl) = amprms(j,bl) + amp(j) * amp(j)
	    phiave(j,bl) = phiave(j,bl) + arg(j)
	    phirms(j,bl) = phirms(j,bl) + arg(j) * arg(j)
	    numave(j,bl) = numave(j,bl) + 1.
	  endif
	enddo
	return
      endif
c
c  Average the data and Write out the results.
c
      do bl=1,MAXBASE2
       if(doave(bl))then
	uave(bl) = uave(bl) / recave(bl)
	vave(bl) = vave(bl)  / recave(bl)
	timeave(bl) = timeave(bl) / recave(bl)
	baseave(bl) = baseave(bl) / recave(bl)
        call basant(baseave(bl),ant1,ant2)
	do j=1,nchan
	 if(numave(j,bl).gt.0.)then
	  amp(j) = ampave(j,bl) / numave(j,bl)
	  arg(j) = phiave(j,bl) / numave(j,bl)
	  amprms(j,bl) = sqrt(amprms(j,bl)/numave(j,bl) - amp(j)*amp(j))
	  phirms(j,bl) = sqrt(phirms(j,bl)/numave(j,bl) - arg(j)*arg(j))
	  cflag(j) = ' '
	 else
	  cflag(j) = '*'
	 endif
	enddo
c
	call JulDay(timeave(bl),'H',line(1:18))
	ctime = line(9:18)
c
	write(line,100) recave(bl),ctime,
     *   	       ant1,ant2,pol,0.001*uave(bl),0.001*vave(bl),
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchan)
 100	format(f6.0,1x,a,i4,'-',i4,1x,a,2f9.2,10(1x,f8.3,1x,i4,a))
	length = len1(line)
	call LogWrite(line(1:length),more)
	write(line,'(44x,10(f8.3,i4,a))')
     *		 (amprms(j,bl),nint(phirms(j,bl)),cflag(j),j=1,nchan)
	length = len1(line)
	call LogWrite(line(1:length),more)
       endif
      enddo
      end
c************************************************************************
	subroutine BriefDat(needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  Do a brief listing of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A zero value indicates it is unknown.
c------------------------------------------------------------------------
	integer mchan
	parameter(mchan=5)
	integer nchan,j,length,ant1,ant2
	logical more
	character line*128,ctime*10,pol*2
	real amp(mchan),arg(mchan)
	character cflag(mchan)*1
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	nchan = min(mchan,numchan)
	if(needhd)then
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,
     *	   ' Vis #    Time      Ant    Pol U(kLam)  V(kLam)')
	  do j=1,nchan
	    call cat(line,length,'   Amp  Phase')
	  enddo
	  call LogWrite(line(1:length),more)
	endif
c
        call basant(basein,ant1,ant2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	do j=1,nchan
	  call amphase (data(j), amp(j), arg(j))
	  if(flags(j))then
 	    cflag(j) = ' '
	  else
	    cflag(j) = '*'
	  endif
	enddo
	call JulDay(timein,'H',line(1:18))
	ctime = line(9:18)
c
	write(line,100)mod(VisNo,1000000),ctime,
     *   	       ant1,ant2,pol,0.001*uin,0.001*vin,
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchan)
 100	format(i6,1x,a,i4,'-',i4,1x,a,2f9.2,10(1x,f8.3,1x,i4,a))
	length = len1(line)
	call LogWrite(line(1:length),more)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine ListDat(needhd,unit,uin,vin,basein,ut,lst,
     *				dobrief,VisNo,data,flags,numchan,p)
	implicit none
	integer numchan,VisNo,p,unit
	logical needhd,flags(numchan),dobrief
	complex data(numchan)
	double precision uin,vin,basein,ut,lst
c
c  List ut lst antennas u,v elev and paralactic angle with the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    dobrief	Do brief listing.
c    unit	Handle of the uvdata.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    basein	Baseline number.
c    ut,lst	UT and LST, in radians.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A zero value indicates it is unknown.
c------------------------------------------------------------------------
	real rtoh,rtod,pi,rts
	integer mchan
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	parameter(mchan=5,rts=3600.*180./pi)
	character line*100,cflag(mchan)*1, telescop*20, pol*2
	real amp(mchan),phas(mchan),ha,elev,sinaz,cosaz,azim
	real sinha,cosha,sind,cosd,sinl,cosl,chi
	double precision obsra,obsdec,latitude,dra,ddec
	logical more,ok
	integer i,j,ant1,ant2,nchan
c
c  Externals.
c
	character PolsC2P*2
c
	if(needhd)then
	  call LogWrite(' ',more)
	  line =' Vis #   UT(hrs)  LST(hrs)   Ant    Pol  u(kLam)'
     *	  //'  v(kLam)  Azim  Elev(deg)  Chi  dra(")  ddec(")'
c********1*********2*********3*********4*********5*********6*********7**
	  call LogWrite(line,more)
	endif
c
c  Calculate the elevation and paralactic angle.
c
	call uvrdvrd(unit,'obsra',obsra,0.d0)
	call uvrdvrd(unit,'obsdec',obsdec,0.d0)
	call uvrdvrd(unit,'dra',dra,0.d0)
	call uvrdvrd(unit,'ddec',ddec,0.d0)
	call uvrdvrd(unit,'latitud',latitude,0.d0)
	if(latitude.eq.0.d0)then
          call uvrdvra(unit,'telescop',telescop,'UNKNOWN')
          if(telescop.ne.'UNKNOWN') then
	    call obspar(telescop,'latitude',latitude,ok)
	  else 
	    call bug('w','unable to determine latitude')
	  endif
	endif
	ha = lst-obsra
	sinha = sin(ha)
	cosha = cos(ha)
	sind = sin(obsdec)
	cosd = cos(obsdec)
	sinl = sin(latitude)
	cosl = cos(latitude)
	elev = asin(sinl*sind+cosl*cosd*cosha)
	sinaz = -sinha*cosd/cos(elev)
	cosaz = (sin(elev)*sinl-sind)/cos(elev)/cosl
	azim  = atan2(sinaz,cosaz)
	call parang(obsra,obsdec,lst,latitude,chi)
c
c  Give the preamble.
c
        call basant(basein,ant1,ant2)
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	write(line,
     *    '(i6,2f10.4,1x,i4,''-'',i4,1x,a,2f9.2,3f8.2,2x,2f6.0)')
     *	  mod(Visno,1000000),ut*rtoh,lst*rtoh,ant1,ant2,pol,
     *	  0.001*uin,0.001*vin,azim*rtod,elev*rtod,
     *    chi*rtod,dra*rts,ddec*rts
c********1*********2*********3*********4*********5*********6*********7**
	call LogWrite(line,more)
c
c  List the channel data.
c
	if(.not.dobrief)then
	  do i=1,numchan,mchan
	    nchan = min(numchan-i+1,mchan)
	    do j=1,nchan
	      if(flags(i+j-1))then
	        cflag(j) = ' '
	      else
	        cflag(j) = '*'
	      endif
	      call amphase(data(i+j-1),amp(j),phas(j))
	    enddo
	    write(line,'(5(i4,f7.2,i4,a))')
     *		      (i+j-1,amp(j),nint(phas(j)),cflag(j),j=1,nchan)
	    call LogWrite(line,more)
	  enddo
c
	  call LogWrite(' ',more)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine LongDat(needhd,uin,vin,timein,basein,ut,lst,VisNo,
     *						data,flags,numchan,p)
	implicit none
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein,ut,lst
c
c  Do a full listing of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    ut,lst	UT and LST, in radians.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation type.
c------------------------------------------------------------------------
	real rtoh,rtod,pi
	integer mchan
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	parameter(mchan=5)
	character line*80,date*18,cflag(mchan)*1,pol*2
	real amp(mchan),phas(mchan)
	logical more
	integer i,j,ant1,ant2,nchan
c
c  Externals.
c
	character PolsC2P*2
c
	if(needhd)then
	  call LogWrite(' ',more)
	  line = ' Vis #    Ant       Date         Pol'
     *		 //'  U(klam)  V(klam)   UT(hrs)  LST(hrs)'
	  call LogWrite(line,more)
	endif
c
c  Give the preamble.
c
        call basant(basein,ant1,ant2)
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
	call JulDay(timein,'H',date)
c
	write(line,'("|",i6,i4,"-",i4,x,a,1x,a,2f9.2,2f10.4)')
     *	mod(Visno,1000000),ant1,ant2,date(1:16),pol,0.001*uin,0.001*vin,
     *	ut*rtoh,lst*rtoh
	call LogWrite(line,more)
c
c  List the channel data.
c
	do i=1,numchan,mchan
	  nchan = min(numchan-i+1,mchan)
	  do j=1,nchan
	    if(flags(i+j-1))then
	      cflag(j) = ' '
	    else
	      cflag(j) = '*'
	    endif
	    call amphase(data(i+j-1),amp(j),phas(j))
	  enddo
	  write(line,'(5(i4,f7.2,i4,a))') 
     *		      (i+j-1,amp(j),nint(phas(j)),cflag(j),j=1,nchan)
	  call LogWrite(line,more)
	enddo
c
	call LogWrite(' ',more)
	end
c************************************************************************
	subroutine GetOpt(dohead,dodata,dospect,dohist,
     *		    dobrief,dolist,dostat,doallan,doave,doflux,dobird)
c
	implicit none
	logical dohead,dodata,dospect,dohist,dobrief,dolist,dostat,doave
	logical doallan,doflux,dobird
c
c  Determine which of the options is to be done. Default is
c  "brief" "data".
c
c  Outputs:
c    dohead,dodata,dospect,dohist,dolist,dostat,dobird,doallan,doave
c    dobrief			  Do it in brief or verbose mode.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=12)
	character opts(nopts)*9
	logical present(nopts)
c
	data opts/'brief    ','full     ','data     ','variables',
     *		  'spectra  ','list     ','history  ','statistic',
     *		  'average  ','allan    ','flux     ','birds    '/
c
	call options('options',opts,present,nopts)
c
	if(present(1).and.present(2))
     *	  call bug('f','Cannot combine options BRIEF and FULL')
	dobrief = .not.present(2)
	dodata  = present(3)
	dohead  = present(4)
	dospect = present(5)
	dolist  = present(6)
	dohist  = present(7)
	dostat  = present(8)
	doave   = present(9)
	doallan = present(10)
	doflux  = present(11)
	dobird  = present(12)
	if(.not.(dohead.or.dolist.or.dospect.or.dohist
     *			.or.dostat.or.doflux.or.dobird))
     *							dodata = .true.
c
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine writein(unit,vis,dohead,dodata,dospect,
     *	  dohist,dolist,dobrief,dostat,doallan,doave,doflux,dobird,
     *                  scale)
c
	implicit none
	integer unit
	character vis*(*)
	logical dohead,dodata,dospect,dohist,dolist,dobrief,dostat
	logical doave,doallan,doflux,dobird
        real scale
c
c  Write out the input parameters to the output log file / terminal.
c
c  Input:
c    tno	 Handle of the input.
c    vis	 Name of the input file.
c    dohead,dodata,dospect,dohist,dobrief,dolist,dostat,doave,doallan
c    scale       Scale factor applied to data
c------------------------------------------------------------------------
	integer CHANNEL,WIDE,VELOCITY
	parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
	character line*80,linetype*12
	double precision datline(6)
	real start,width,step
	integer numchan,type,length
	logical more
c
c  Externals.
c
	integer len1
c
c  Determine the linetype.
c
	call uvinfo(unit,'line',datline)
	type = nint(datline(1))
	if(type.eq.CHANNEL)  linetype = 'channel'
	if(type.eq.WIDE)     linetype = 'wide'
	if(type.eq.VELOCITY) linetype = 'velocity'
	numchan = nint(datline(2))
	start = datline(3)
	width = datline(4)
	step  = datline(5)
c
c  Give the file name.
c
	length = len1(vis)
	line = ' ***** UV Listing for '//vis(1:length)//' *****'
	call LogWrite(line,more)
c
	length = 0
	if(dobrief)then
	  call cat(line,length,'  Options: brief')
	else
	  call cat(line,length,'  Options: full')
	endif
	if(dohead)  call cat(line,length,',variables')
	if(dodata)  call cat(line,length,',data')
	if(dospect) call cat(line,length,',spectra')
	if(dohist)  call cat(line,length,',history')
	if(dolist)  call cat(line,length,',list')
	if(dostat)  call cat(line,length,',statistics')
	if(doave)   call cat(line,length,',average')
	if(doallan) call cat(line,length,',Allan standard deviation')
	if(doflux)  call cat(line,length,',planet flux visibility')
	if(dobird)  call cat(line,length,',frequency birdies')
	call LogWrite(line,more)
c
	if(dodata)then
	  length = len1(linetype)
	  write(line,'(a,i4,a,a)')
     *	  '  No. channels:',numchan,', Linetype: ',linetype(1:length)
	  call LogWrite(line,more)
	  write(line,'(a,f9.3,a,f9.3,a,f9.3)')
     *	  '  Line Start:',start,', Width:',width,', Step:',step
	  call LogWrite(line,more)
          write(line,'(a,f9.3)') '  Scale factor:',scale
	  call LogWrite(line,more)
	endif
	call LogWrite(' ',more)
	call LogWrite('------------------------------'//
     *		      '------------------------------',more)
	call LogWrite(' ',more)
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine cat(line,length,string)
c
	implicit none
	character line*(*),string*(*)
	integer length
c
c  Append a string to the end of another string.
c
c  Input:
c    string
c  Input/Output:
c    line
c    length
c  			Note: length is increased by the len(string)
c			      not len1(string) !!!!
c			this to make sure you can enter strings like
c			' hello '.
c------------------------------------------------------------------------
	integer len1

	if (len1(string)+length .gt. len(line)) call bug('w',
     *		'CAT: Not enough space to append string')
	line(length+1:length+len(string)) = string
	length = length + len(string)
	if (length .lt. len(line)) line(length+1:) = ' '
	end
c************************************************************************
	subroutine VarLoad(unit,brief)
c
	implicit none
	integer unit
	logical brief
c
c  Load the names of all the variables in the uv data set.
c
c  Inputs:
c    unit	Handle of the input data set.
c    brief	If true, then only the important variables are considered.
c------------------------------------------------------------------------
	include 'uvlist.h'
	integer item,is,i,j,k
	logical select,overflow
	character varin*12,vsave*8
c
c  Externals.
c
	integer binsrcha
c
c  The following table is a list of "important" and "unimportant" variables.
c  In brief mode, only the important variables are listed. In full mode,
c  all, except the unimportant variables, are listed. NOTE: the tables MUST
c  be in alphabetic order!
c
	integer ngood,nbad
	parameter(ngood=12,nbad=8)
	character vargood(ngood)*8,varbad(nbad)*8
	data (varbad(j),j=1,nbad)/
     *	'baseline','coord   ','corr    ','lst     ','time    ',
     *	'tscale  ','ut      ','wcorr   '/
	data (vargood(j),j=1,ngood)/
     *	'antpos  ','corbw   ','corfin  ','cormode ','dec     ',
     *	'freq    ','freqif  ','nants   ','nchan   ','ra      ',
     *	'source  ','vsource '/
c
 	call haccess(unit,item,'vartable','read',is)
	if(is.ne.0) call bugno('f',is)
	vnum=0
	is = 0
	overflow = .false.
 	dowhile (is.eq.0)
 	  call hreada(item,varin,is)
	  if(is.eq.0.and.varin.ne.' ')then
	    if(brief)then
	      select = binsrcha(varin(3:10),vargood,ngood).gt.0
	    else
	      select = binsrcha(varin(3:10),varbad,nbad).eq.0
	    endif
	    if(select)then
	      if(vnum.eq.itlen)then
		overflow = .true.
		is = -1
	      else
		vnum=vnum+1
		varname(vnum)=varin(3:10)
	      endif
	    endif
	  end if
 	enddo
	if(is.ne.-1) call bugno('f',is)
 	call hdaccess(item,is)
	if(is.ne.0) call bugno('f',is)
	if(overflow)call bug('w','Variable table overflow -- some lost')
c
c  Sort the names
c
	do i=1,vnum-1
 	  k=i
 	  do j=i+1,vnum 	   
	    if(varname(j).lt.varname(k)) k=j
 	  enddo 	 
	  vsave=varname(i)
 	  varname(i)=varname(k)
 	  varname(k)=vsave
	enddo
c
c  Mark all the variables we are interested in.
c
	do i=1,vnum
	  call uvtrack(unit,varname(i),'u')
	enddo
	end
C************************************************************************
	subroutine printhd(unit,timein)
c
	implicit none
	integer unit
	double precision timein
c
c  This print out the header variables in a standard format, using
c  the table in uvlist.h.
c
c  Inputs:
c    unit	Pointer to dataset.
c    timein	Julian date.
c------------------------------------------------------------------------
	integer maxdata
	parameter(maxdata=50)
	include 'uvlist.h'
c
	character vflag*1,date*18
	integer k,i,j,nsubs,vsubs,ant1,ant2,length
	logical more,vupd
c
	character line*670
	character sdata*32
	real data(maxdata)
	integer idata(maxdata)
	double precision ddata(maxdata)
c
c  Externals.
c
	character hangleh*13,rangleh*13
	integer len1
c
	call LogWrite(' ',more)
	call JulDay(timein,'H',date)
	line = 'Header variables at '//date(1:16)
	length = len1(line)
	call LogWrite(line(1:length),more)
c
	do k=1,vnum
	  call uvprobvr(unit,varname(k),vflag,vsubs,vupd)
	  if(vupd)then
c
c  A large variable.
c
	    if(vsubs.gt.maxdata) then
	      write(line,'(a,'': ('',i5,'' elements)'')')varname(k),
     *							   vsubs
	      call writeit(line,26)
c
c  A real variable.
c
	    else if(vflag.eq.'r') then
	      call uvgetvrr(unit,varname(k),data,vsubs)
	      if(varname(k)(1:2).eq.'ra' .or. 
     *			varname(k)(1:2).eq.'ha') then
	        call writeit(
     *			varname(k)//': '//hangleh(dble(data(1))),23)
	      else if (varname(k).eq.'dec'.or.
     *		       varname(k).eq.'obsdec'.or.
     *		       varname(k).eq.'latitud'.or.
     *		       varname(k).eq.'longitu') then
	        call writeit(
     *			varname(k)//': '//rangleh(dble(data(1))),23)
	      else if (varname(k).eq.'baseline') then
		ddata(1) = data(1)
        	call basant(ddata(1),ant1,ant2)
	        write(line,'(a8,'':'',i4,"-",i4)') varname(k),ant1,ant2
	        call writeit(line,15)
	      else
	        do j=1,vsubs,5
		  nsubs=min(vsubs-j+1,5)
	          write(line,'(a8,'':'',5(1pg13.6))') 
     *			varname(k),(data(j+i),i=0,nsubs-1)
		  call writeit(line,9+nsubs*13)
	        enddo
	      end if
c
c  A character variable.
c
	    else if (vflag.eq.'a') then
	      call uvgetvra(unit,varname(k),sdata)
	      vsubs=len(sdata)
	      write(line,'(a8,'':'',a)') varname(k),sdata
	      call writeit(line,9+vsubs)
c
c  An integer variable.
c
	    else if (vflag.eq.'i') then
	      call uvgetvri(unit,varname(k),idata,vsubs)
	      do j=1,vsubs,8
	        nsubs=min(vsubs-j+1,8)
	        write(line,'(a8,'':'',8(i8))') 
     *			varname(k),(idata(j+i),i=0,nsubs-1)
	        call writeit(line,9+nsubs*8)
	      enddo
c
c  A double precision variable.
c
	    else if (vflag.eq.'d') then
	      call uvgetvrd(unit,varname(k),ddata,vsubs)
	      if(varname(k).eq.'ra' .or. 
     *		 varname(k).eq.'obsra' .or.
     *		 varname(k).eq.'ut' .or.
     *		 varname(k).eq.'lst') then
	        call writeit(
     *			varname(k)//': '//hangleh(ddata(1)),23)
	      else if (varname(k).eq.'dec'.or.
     *		       varname(k).eq.'obsdec'.or.
     *		       varname(k).eq.'latitud'.or.
     *		       varname(k).eq.'longitu') then
	        call writeit(
     *			varname(k)//': '//rangleh(ddata(1)),23)
	      else
	        do j=1,vsubs,5
		  nsubs=min(vsubs-j+1,5)
		  write(line,'(a8,'':'',5(1pg13.5))') 
     *			varname(k),(ddata(j+i),i=0,nsubs-1)
		  call writeit(line,9+nsubs*13)
	        enddo
	      endif
c
c  Something else ??
c
	    else
	      write(line,'(a,'': ('',i5,'' elements)'')')varname(k),
     *							   vsubs
	      call writeit(line,26)
	    endif
	  endif
	enddo
c
c  Flush buffer if needed.
c
	line=' '
	call writeit(line,80)
	end
C************************************************************************
	subroutine writeit(partial,plen)
	implicit none
	integer plen
	character partial*(*)
c
c  Stuff pieces of line into buffer and print them.
c
c  Input:
c    partial	A piece of a line.
c    plen	Length of partial.
c------------------------------------------------------------------------
	character line*80
	integer i,j,jend
	logical first,more
	save line,i,j,first
	data first/.true./
c
	if(first) then
	  first=.false.
	  i=1
	  j=1
	  line=' '
	end if
c
	if(plen+i.gt.len(line)) then
	  call LogWrite(line,more)
	  line=' '
	  j=1
	  dowhile (plen-j .gt.len(line))
	    jend=j+79
	    dowhile (partial(jend:jend).ne.' ')
	      jend=jend-1
	    enddo
	    call LogWrite(partial(j:jend),more)
	    j=jend+1
	  enddo
	  i=1
	end if
	line(i:i+plen-j) = partial(j:plen)
	i = i+plen - 1
	i = (i-1)/25*25 + 26
	end
c************************************************************************
	subroutine listspec(unit)
	implicit none
	integer unit
c
c  List spectral windows
c
c  Inputs:
c    unit	Handle of uvdata file
c
c   6nov89  mchw
c   7nov89  rjs  Some tidying and error checking.
c   8nov89  mchw changed sign of velocity increment
c   7may90  mchw changed to handle nspect.gt.6
c------------------------------------------------------------------------
        include 'maxdim.h'
	double precision ckms
	parameter(ckms=299792.458d0)
	character line*80
	logical more
	integer nspect,ischan(MAXWIN),nschan(MAXWIN),i,j,k
	double precision restfreq(MAXWIN),sfreq(MAXWIN)
	double precision sdf(MAXWIN),velocity(maxchan)
c
	call LogWrite(' ',more)
	call uvrdvri(unit,'nspect',nspect,0)
	if(nspect.gt.MAXWIN)call bug('f','Too many windows')
	if(nspect.gt.0) then
	  call uvgetvrd(unit,'restfreq',restfreq,nspect)
	  call uvgetvri(unit,'ischan',ischan,nspect)
	  call uvgetvri(unit,'nschan',nschan,nspect)
	  call uvgetvrd(unit,'sfreq',sfreq,nspect)
	  call uvgetvrd(unit,'sdf',sdf,nspect)
	  call uvinfo(unit,'velocity',velocity)
	  do j=1,nspect,6
	    k=min(j+5,nspect)
	    write(line,'(''rest frequency     :'',8f10.5)')
     .		(restfreq(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''starting channel   :'',8i10)')
     .		(ischan(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''number of channels :'',8i10)')
     .		(nschan(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''starting frequency :'',8f10.5)')
     .		(sfreq(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''frequency interval :'',8f10.5)')
     .		(sdf(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''starting velocity  :'',8f10.3)')
     .		(velocity(ischan(i)),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''ending velocity    :'',8f10.3)')
     .		(velocity(ischan(i)+nschan(i)-1),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''velocity interval  :'',8f10.3)')
     .		(-sdf(i)/restfreq(i)*ckms,i=j,k)
	    call LogWrite(line,more)
	    call LogWrite(' ',more)
	  enddo
	else
	  call LogWrite('These uvdata have no spectra',more)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine ShowStat(needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  List max, min, rms and highest channels in data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A value of zero indicates it is
c		not known.
c------------------------------------------------------------------------
	integer MAXHIGH,ngood,nhigh
	parameter(MAXHIGH=12)
	integer i,j,k,length,ant1,ant2,highchan(MAXHIGH)
	logical more
	character line*128,ctime*10,pol*2
	real amp,phi,maxamp,maxphi,minamp,minphi
	real aveamp,avephi,rmsamp,rmsphi,amphigh(MAXHIGH)
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	if(needhd)then
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,' Vis #    Time      Ant    Pol')
	  call cat(line,length,'  MaxAmp   AveAmp  RmsAmp RmsPhase')
	  call cat(line,length,'   # high channels (>4*rms)')
	  call LogWrite(line,more)
	endif
c
        call basant(basein,ant1,ant2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
c  Accumulate statistics.
c
	maxamp = -1.e9
	minamp =  1.e9
	aveamp = 0.
	rmsamp = 0.
	ngood = 0.
	avephi = 0
	rmsphi = 0
	maxphi = -1e9
	minphi =  1e9
	do j=1,numchan
	  call amphase (data(j), amp, phi)
	  if(flags(j))then
	    aveamp = aveamp + amp
	    rmsamp = rmsamp + amp*amp
 	    if(amp.gt.maxamp) maxamp = amp
	    if(amp.lt.minamp) minamp = amp
	    avephi = avephi + phi
	    rmsphi = rmsphi + phi*phi
 	    if(phi.gt.maxphi) maxphi = phi
	    if(phi.lt.minphi) minphi = phi
	    ngood = ngood + 1
	  endif
	enddo
c
c  calculate rms and find highest channels.
c
	nhigh = 0
	do j=1,MAXHIGH
	  amphigh(j) = 0.
	enddo
	if(ngood.gt.0)then
	  aveamp = aveamp/ngood
	  rmsamp = sqrt(rmsamp/ngood - aveamp*aveamp)
	  avephi = avephi/ngood
	  rmsphi = sqrt(rmsphi/ngood - avephi*avephi)
	  do j=1,numchan
	    call amphase (data(j), amp, phi)
	    if(flags(j).and.amp.gt.4.*rmsamp)then
	      if(nhigh.lt.MAXHIGH) nhigh = nhigh + 1
	      i = 1
	      more = .true.
	      do while(i.le.nhigh.and.more)
		if(amp.gt.amphigh(i))then
		  k = nhigh
		  do while(k.gt.i)
		    highchan(k) = highchan(k-1)
		    amphigh(k) = amphigh(k-1)
		    k = k - 1
		  enddo
		  highchan(i) = j
		  amphigh(i) = amp
		  more = .false.
		endif
		i = i + 1
	      enddo
	    endif
	  enddo
c
c  List max, min, rms and highest channels in data.
c
	  call JulDay(timein,'H',line(1:18))
	  ctime = line(9:18)
c
	  write(line,100)mod(VisNo,1000000),ctime,
     *   	   ant1,ant2,pol,maxamp,aveamp,rmsamp,rmsphi,nhigh
 100	  format(i6,1x,a,i4,'-',i4,1x,a,1x,3(g8.2,1x),f6.0,1x,i5)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	  write(line,'(a,12i7)') 'CHAN', (highchan(j),j=1,nhigh)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine Pflux(tvis,needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer tvis
	integer numchan,VisNo,p
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  List flux visibility for standard sources and planets.
c
c  Input:
c    tvis       Handle of the visibility data file.
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A value of zero indicates unknown.
c------------------------------------------------------------------------
	integer MAXHIGH,ngood,nhigh
	parameter(MAXHIGH=12)
	integer i,j,k,length,ant1,ant2,highchan(MAXHIGH)
	logical more
	character line*128,ctime*10,pol*2
	real amp,phi,maxamp,flux,uvdist,jyamp
	real aveamp,avephi,rmsamp,rmsphi,amphigh(MAXHIGH)
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	if(needhd)then
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,' Vis #    Time      Ant    Pol')
	  call cat(line,length,' MaxAmp AveAmp  RmsAmp  RmsPhase')
	  call cat(line,length,'   uvdist   Flux   Jy/AveAmp')
	  call LogWrite(line,more)
	endif
c
        call basant(basein,ant1,ant2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
c  Accumulate statistics.
c
	aveamp = 0.
	rmsamp = 0.
	ngood = 0.
	avephi = 0
	rmsphi = 0
	maxamp = -1e9
	do j=1,numchan
	  call amphase (data(j), amp, phi)
	  if(flags(j))then
	    aveamp = aveamp + amp
	    rmsamp = rmsamp + amp*amp
            if(amp.gt.maxamp) maxamp = amp
	    avephi = avephi + phi
	    rmsphi = rmsphi + phi*phi
	    ngood = ngood + 1
	  endif
	enddo
c
c  calculate rms and find highest channels.
c
	nhigh = 0
	do j=1,MAXHIGH
	  amphigh(j) = 0.
	enddo
	if(ngood.gt.0)then
	  aveamp = aveamp/ngood
	  rmsamp = sqrt(rmsamp/ngood - aveamp*aveamp)
	  avephi = avephi/ngood
	  rmsphi = sqrt(rmsphi/ngood - avephi*avephi)
	  do j=1,numchan
	    call amphase (data(j), amp, phi)
	    if(flags(j).and.amp.gt.4.*rmsamp)then
	      if(nhigh.lt.MAXHIGH) nhigh = nhigh + 1
	      i = 1
	      more = .true.
	      do while(i.le.nhigh.and.more)
		if(amp.gt.amphigh(i))then
		  k = nhigh
		  do while(k.gt.i)
		    highchan(k) = highchan(k-1)
		    amphigh(k) = amphigh(k-1)
		    k = k - 1
		  enddo
		  highchan(i) = j
		  amphigh(i) = amp
		  more = .false.
		endif
		i = i + 1
	      enddo
	    endif
	  enddo
c
	  call JulDay(timein,'H',line(1:18))
	  ctime = line(9:18)
c
	  call getflux(tvis,numchan,flux)
	  uvdist = sqrt(uin*uin+vin*vin) * 1e-3
	  if(aveamp.ne.0.)then
	    jyamp = flux/aveamp
	  else
	    jyamp = 0.
	  endif
	  write(line,100)mod(VisNo,1000000),ctime,
     *   	       ant1,ant2,pol,maxamp,aveamp,rmsamp,rmsphi,
     *		       uvdist,flux,jyamp
 100	  format(i6,1x,a,i4,'-',i4,1x,a,1x,3(g8.2,1x),f6.0,1x,3f14.6)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	endif
	end
c********1*********2*********3*********4*********5*********6*********7**
	subroutine getflux(tvis,nchan,flux)
c
	implicit none
	integer tvis,nchan
	real flux
c
c  Determine the calibrator flux.
c
c  Input:
c    tvis       Handle of the visibility data file.
c  Output:
c    flux       Flux of the calibrator.
c------------------------------------------------------------------------
	logical update,isplanet
	double precision day,dfreq,delta
	integer iostat,length
        character source*16,source1*16,line*80,type*1
	real freq,level
c
c  Externals.
c
	real ModPlant
c
c  Data
c
	data level/1./
c
	call uvrdvra(tvis,'source',source,'unknown')
          source1 = source
	  call uvfit1(tvis,'frequency',nchan,dfreq,delta)
	  freq = dfreq
c
c  Check whether this source is a planet.
c
	  call uvprobvr(tvis,'pltb',type,length,update)
	  isplanet = type.eq.'r'.and.length.eq.1
	  if(isplanet)then
	    call uvrdvrr(tvis,'pltb',flux,0.)
	    isplanet = flux.gt.0
	  endif
c
c  Return the flux.
c
	if(isplanet)then
	  flux = ModPlant(tvis,freq)
	else
	  flux = 0.
	  call CalGet(' ',source1,freq,100.,day,1000.,flux,iostat)
c	  call CalGet(' ',source1,freq,0.,day,1000.,flux,iostat)
c	  call CalGet(' ',source1,0.d0,100.,day,1000.,flux,iostat)
c	  freq = 0.
c	  call CalGet(' ',source1,freq,100.,day,1000.,flux,iostat)
	  if(iostat.ne.0)then
	    call bug('w','Error determining flux of '//source)
	    write(line,'(a,f8.3,a)') 'Setting flux to ',level,' Jy'
	    call output(line)
	    flux = level
	  endif
	endif
	end
c************************************************************************
	real function ModPlant(tvis,freq)
c
	implicit none
	integer tvis
	real freq
c
c  This determines the flux of a planet for the current visibility. This
c  looks for variables in the visibility file which give the characteristics
c  of the planet.
c
c  Input:
c    tvis	Handle of the visibility file.
c    freq	Observing frequency, in GHz.
c  Output:
c    ModPlant	The flux of the planet for this baseline.
c------------------------------------------------------------------------
	include 'mirconst.h'
	double precision coord(3)
	real plmaj,plmin,plangle,pltb,u,v,flux,cosi,sini,beta,omega
	character type*1
	integer length
	logical update
c
c  Externals.
c
	real j1xbyx
c
c  Get info from the visibility file.
c  Units returned by the uv routines.
c    u,v -- nanosec.
c    plmaj,plmin -- arcsec.
c    plangle -- degrees
c    pltb -- Kelvin
c
	call uvprobvr(tvis,'coord',type,length,update)
	if(type.ne.'d'.or.length.lt.2.or.length.gt.3)
     *	  call bug('f','Screwy uvw coordinate, in ModPlant')
	call uvgetvrd(tvis,'coord',coord,length)
	u = coord(1)
	v = coord(2)
	call uvgetvrr(tvis,'plmaj',plmaj,1)
	call uvrdvrr(tvis,'plmin',plmin,plmaj)
	call uvrdvrr(tvis,'plangle',plangle,0.)
	call uvgetvrr(tvis,'pltb',pltb,1)
c
c  Unit conversion.
c
	plangle = PI/180 * plangle
	plmaj = PI * plmaj / 180 / 3600 
	plmin = PI * plmin / 180 / 3600
c
c  We have the characteristics of the source. Now compute the flux (in Jy).
c    plange -- radians.
c    plmaj,plmin -- radians.
c    pltb -- Kelvin.
c    u,v  -- nanosec.
c    freq -- GHz
c  The factor 1e26 converts between W/m**2/Hz to Janksy.
c
	cosi = cos(plangle)
	sini = sin(plangle)
	beta = PI * sqrt((plmaj*(u*cosi-v*sini))**2
     *	  	       + (plmin*(u*sini+v*cosi))**2)
	omega = pi/4 * plmaj*plmin
	flux = omega * 2*(HMKS*1e26)/(CMKS*CMKS)*(freq**3*1e27)/
     *	 ( exp(((HMKS/KMKS)*1e9)*freq/pltb) - 1. )
	ModPlant = 2.*j1xbyx(beta*freq) * flux
	end		
c********1*********2*********3*********4*********5*********6*********7**
	subroutine bird(tvis,needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,numchan,p)
c
	implicit none
	integer numchan,VisNo,p,tvis
	logical needhd,flags(numchan)
	complex data(numchan)
	double precision uin,vin,timein,basein
c
c  List frequencies for high channels in each record.
c
c  Input:
c    tvis	Handle of input file.
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    numchan	The number of channels.
c    p		Polarisation code. A value of zero indicates it is
c		not known.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer MAXHIGH,ngood,nhigh
	parameter(MAXHIGH=12)
	integer i,j,k,length,ant1,ant2,highchan(MAXHIGH)
	logical more
	character line*128,ctime*10,pol*2
	real amp,phi,maxamp,maxphi,minamp,minphi
	real aveamp,avephi,rmsamp,rmsphi,amphigh(MAXHIGH)
        double precision lo1,lo2,frequency(MAXCHAN)
c
c  Externals.
c
	character PolsC2P*2
	integer len1
c
	if(needhd)then
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,' Vis #    Time      Ant    Pol')
	  call cat(line,length,'  MaxAmp   AveAmp  RmsAmp RmsPhase')
	  call cat(line,length,'   # high channels (>4*rms)')
	  call LogWrite(line,more)
	endif
c
        call basant(basein,ant1,ant2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
c  Accumulate statistics.
c
	maxamp = -1.e9
	minamp =  1.e9
	aveamp = 0.
	rmsamp = 0.
	ngood = 0.
	avephi = 0
	rmsphi = 0
	maxphi = -1e9
	minphi =  1e9
	do j=1,numchan
	  call amphase (data(j), amp, phi)
	  if(flags(j))then
	    aveamp = aveamp + amp
	    rmsamp = rmsamp + amp*amp
 	    if(amp.gt.maxamp) maxamp = amp
	    if(amp.lt.minamp) minamp = amp
	    avephi = avephi + phi
	    rmsphi = rmsphi + phi*phi
 	    if(phi.gt.maxphi) maxphi = phi
	    if(phi.lt.minphi) minphi = phi
	    ngood = ngood + 1
	  endif
	enddo
c
c  calculate rms and find highest channels.
c
	nhigh = 0
	do j=1,MAXHIGH
	  amphigh(j) = 0.
	enddo
	if(ngood.gt.0)then
	  aveamp = aveamp/ngood
	  rmsamp = sqrt(rmsamp/ngood - aveamp*aveamp)
	  avephi = avephi/ngood
	  rmsphi = sqrt(rmsphi/ngood - avephi*avephi)
	  do j=1,numchan
	    call amphase (data(j), amp, phi)
	    if(flags(j).and.amp.gt.4.*rmsamp)then
	      if(nhigh.lt.MAXHIGH) nhigh = nhigh + 1
	      i = 1
	      more = .true.
	      do while(i.le.nhigh.and.more)
		if(amp.gt.amphigh(i))then
		  k = nhigh
		  do while(k.gt.i)
		    highchan(k) = highchan(k-1)
		    amphigh(k) = amphigh(k-1)
		    k = k - 1
		  enddo
		  highchan(i) = j
		  amphigh(i) = amp
		  more = .false.
		endif
		i = i + 1
	      enddo
	    endif
	  enddo
c
c  List max, min, rms and highest channels in data.
c
	  call JulDay(timein,'H',line(1:18))
	  ctime = line(9:18)
c
	  write(line,100)mod(VisNo,1000000),ctime,
     *   	       ant1,ant2,pol,maxamp,aveamp,rmsamp,rmsphi,
     *		       nhigh
 100	  format(i6,1x,a,i4,'-',i4,1x,a,1x,3(g8.2,1x),f6.0,1x,i5)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	  write(line,'(a,12i7)') 'CHAN', (highchan(j),j=1,nhigh)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
c
	  call uvinfo(tvis,'frequency',frequency)
	  write(line,'(a,12f7.3)') 
     *		'FREQ', (frequency(highchan(j)),j=1,nhigh)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	  call uvrdvrd(tvis,'lo1',lo1,0.d0)
	  write(line,'(a,12f7.3)')
     *		'IF1 ',	 ((frequency(highchan(j))-lo1),j=1,nhigh)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	  call uvrdvrd(tvis,'lo2',lo2,0.d0)
	  write(line,'(a,12f7.3)')
     *		'IF2 ',	 (frequency(highchan(j))-lo1
     *		 -sign(lo2,(frequency(highchan(j))-lo1)),j=1,nhigh)
	  length = len1(line)
	  call LogWrite(line(1:length),more)
	endif
	end
c-----------------------------------------------------------------------
      subroutine qzero(n, qarr)
      integer n
      logical qarr(n)
      integer i
      do i=1,n
         qarr(i) = .FALSE.
      enddo
      end
c-----------------------------------------------------------------------
      subroutine rzero(n, rarr)
      integer n
      real rarr(n)
      integer i
      do i=1,n
         rarr(i) = 0.0
      enddo
      end
c-----------------------------------------------------------------------
      subroutine dzero(n, darr)
      integer n
      double precision darr(n)
      integer i
      do i=1,n
         darr(i) = 0.0d0
      enddo
      end
c-----------------------------------------------------------------------
      subroutine izero(n, iarr)
      integer n
      integer iarr(n)
      integer i
      do i=1,n
         iarr(i) = 0.0d0
      enddo
      end
c-----------------------------------------------------------------------
c********1*********2*********3*********4*********5*********6*********7**
