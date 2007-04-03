c************************************************************************
	program pjyperk
	implicit none
c
c= jyperk - Compute new baseline based jyperk from jyperka
c& pjt
c: uv analysis
c+
c	JYPERK computes new baseline based jyperk values from the
c       jyperka array.
c
c       All CARMA data prior to <sometime>-october-2006 suffer from the
c       wrong value for jyperk, so this task should be used early in
c       the data reduction process. 
c
c@ vis
c	The names of the input uv data sets. No default.
c@ select
c	Standard visibility data selection. See the help on "select" for
c	more information. The default is to select all data.
c@ out
c	The name of the output uv data set. No default.
c@ jyperka
c       An array of antenna based JY/K values to override the jyperka
c       array in the dataset. 
c
c--
c  History:
c    25oct06 pjt  Written, for CARMA
c    22feb07 pjt  warning added
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	character version*(*)
	integer MAXSELS
	parameter(version='jyperk: version 22-feb-07')
	parameter(MAXSELS=256)
c
	real sels(MAXSELS),jyperk
	integer lVis,lOut,vnif,ant1,ant2
	character vis*128,out*128
	integer nchan,nants,nanta,nwcorr
c
	complex data(MAXCHAN),wcorr(MAXWIDE)
	logical flags(MAXCHAN),wflags(MAXWIDE)
	double precision preamble(6)
	real jyperka(MAXANT) 
c
	call output(version)
	call bug('i','This program is not needed anymore for CARMA ' //
     *    'data filled after 2007-01-31')
	call keyini
	call keya('vis',vis,' ')
	call keya('out',out,' ')
	call selInput('select',sels,MAXSELS)
	call mkeyr('jyperka',jyperka,MAXANT,nanta)
	call keyfin
c
c  Check the inputs.
c
	if(vis.eq.' ')call bug('f','An input must be given: vis=')
	if(out.eq.' ')call bug('f','An output must be given: out=')
c
c  Get ready to copy the data.
c
	call uvopen(lVis,vis,'old')
	call SelApply(lVis,sels,.true.)
	call uvset(lVis,'preamble','uvw/time/baseline',0,0.,0.,0.)
	call varInit(lVis,'channel')
	call varWinit(lVis)
c
	call uvvarIni(lVis,vnif)
c
c  Open the output, and make its history.
c
	call uvopen(lOut,out,'new')
	call varOnit(lVis,lOut,'channel')
	call uvset(lOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
c
	call hdcopy(lVis,lOut,'history')
	call hisopen(lOut,'append')
	call hiswrite(lOut,'JYPERK: Miriad '//version)
	call hisinput(lOut,'JYPERK')
	call hisclose(lOut)
c
c  Get first record of the final pass.
c  warning: we're only getting jyperka() once here
c
	call uvread(lVis,preamble,data,flags,MAXCHAN,nchan)
	if(nchan.eq.0)call bug('f','No data found')
	call uvwread(lVis,wcorr,wflags,MAXWIDE,nwcorr)
	call uvrdvri(lVis,'nants',nants,0)
	if (nanta.eq.0) then
	   call uvgetvrr(lVis,'jyperka',jyperka,nants)
	   DO ant1=1,nants
	      write(*,*) 'jyperka ',ant1,jyperka(ant1)
	   ENDDO
	else if (nanta.lt.nants) then
	   call bug('f','Not enough values for jyperka array')
	endif
c
	dowhile(nchan.gt.0)
	  call varCopy(lVis,lOut)
	  call basant(preamble(5),ant1,ant2,.TRUE.)
	  jyperk = sqrt(jyperka(ant1)*jyperka(ant2))
	  call uvputvrr(lOut,'jyperk',jyperk,1)
	  call uvwwrite(lOut,wcorr,wflags,nwcorr)
	  call uvwrite(lOut,preamble,data,flags,nchan)
	  call uvread(lVis,preamble,data,flags,MAXCHAN,nchan)
	  call uvwread(lVis,wcorr,wflags,MAXWIDE,nwcorr)
	enddo
c
	call uvclose(lVis)
	call uvclose(lOut)
	end
c************************************************************************
