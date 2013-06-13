c***********************************************************************
        program listobs
c
c  Makes a listing of time ordered information about the observations in
c  modest detail. If multiple files or wildcards are used as input the 
c  resulting listing is time ordered.
c
c= Listobs - Makes a summary of a set of observations.
c& pjt
c: utility
c+
c	LISTOBS makes a summary of a set of CARMA observations.  Parameters of
c	interest to the observer are pulled from one or many files, and
c	printed to a log file.  A time ordered summary of the sources
c	observed is compiled.  The primary use of this program is to
c	create a summary of the instrument setup and all observations
c	made during a track.  Use wild cards or an include file to specify
c	all files relevent for your observations.
c       Scans are reported where source name, tsys, were changed.
c       For more details on the correlator setup, use
c       uvlist options=spectra vis=...
c       or
c       uvindex vis=...
c       Although LISTOBS is specific to CARMA data, old BIMA can be fixed
c       up for LISTOBS using the fix4bima script.
c< vis
c@ log 
c	Output device. (default is standard user output)
c@ gap
c       Maximum gap time allowed between integrations, anything over this
c       time will cause a new record to be displayed. Source changes always
c       cause a new record to be displayed. Use 0 if you want to see each
c       record.  Negative numbers resort to the old percentage of the
c       integration time gap, i.e. -0.12 defines the gap 12% of the
c       current integration time.
c       Default: 1 minute.
c@ options
c       This gives extra processing options. Several options can be given,
c       each separated by commas. They may be abbreivated to the minimum
c       needed to avoid ambiguity.
c         'nobase'      Do not list baselines. Useful for big arrays such
c                       as ATA. By default baselines and uvdistance are
c                       listed.
c         'allants'     List all antennas, not just those in the dataset
c--
c
c< time
c	Takes value "ut" or "lst" to print time as UT or LST (default: ut)
c
c  History:
c          04-dec-89 initial writing begun by lgm
c             dec-89 first working version - lgm
c          10-may-90 minor mods by lgm
c          17-jun-90 added baselines in wavelengths and focus
c          25-jan-91 fixed format for printing iffreq
c          26-feb-91 added printing of the UT date - pjt
c    mchw 11sep91  Fix bugs for some missing variables.
c			Use wsystemp for wideband data.
c    mchw 12sep91  Changed some code to standard.
c          21-feb-92    buffer check if ipt is not too large.... pjt
c          15-feb-93    ra uv variable now in double precision   pjt
c                       deghms is still in REAL though !!!
c    <<<   12-mar-93    Remove REAL "casting" from deghms call ... mjs	 >>>
c	   22-mar-93 pjt dghms back to double - fixed formatting problems
c			 for 6 antenna array. 
c          31-mar-93 pjt fixed site problem with variable corbw() length
c	    9-jul-93 pjt fixed audit trail confusions - all fences end @72
c	   12-jul-93 mjs elim 1 char from string so str len is <= 80
c          15-nov-93 lgm introduced maxspect to correct reading of systemps,
c                           made ant mask to id ants in use and changed
c                           output so only ants used are output.
c	    5-sep-95 pjt only use&report focus changes for used antennae
c	   19-dec-95 mwp fixed up output for 9 antennas. space is made by
c                        giving user choice of UT or LST output. (time=)
c          22-may-96 pjt Another historic day: Ant # 10 is online!!!!
c	   09-oct-97 mchw  more format changes to fit onto page.
c          19-jun-98 pjt fixed some ansi problems for linux g77
c          14-mar-01 pjt realigned Mel's versino with test for missing systemp
c			 (originally done 20jan99)
c          09-jan-06 dnf changed formats of outputs for nants<=15 (CARMA)
c                        made changes in reading of cormore, corfin,
c                        and corbw as these variables are not included in
c                        CARMA data. the output will read 0 for these 
c                        variables for CARMA data and will behave as normal
c                        for other (old BIMA) data
c                        changed in to vis to make listobs consistent with
c                        other uv data tasks
c          18-apr-06 pjt sourcename now allowed 16
c          12-jul-06 pjt handle blank vis= correctly
c          29-aug-06 dnf changed output format so that all active antennas
c                        are listed with the system temperature listing
c           2-jan-07 pjt list local (ENU) antenna positions as well as XYZ
c          31-jan-07 pjt one more HatCreek dependancy removed (lat) - Elev now correct
c           4-dec-07 mwp/pjt  time with extra digit, no more focus reporting for CARMA
c          11-dec-07 pjt removed BW/cormode, printing both ut and lst
c          16-jan-08 pjt Added uv distance to the baseline-UVW output section
c          30-jan-08 pjt options=nobase to stop the N^2 baselines output
c          04-feb-08 dnf Added object purpose to source listing output
c          19-feb-08 pjt Added versan() version login
c           8-dec-08 pjt make it work for SZA data as well
c          12-dec-08 pjt deal with version 1.1 SZA data (wsystemp instead of systemp)
c          10-aug-09 pjt list end time of observations, only UT needed for now
c                        and revert back, Quality would be upset with this change
c          25-aug-09 pjt UVW one more digit for A array when UVW < 0
c           3-mar-10 pjt rad2hms in double precision, better rounding
c          31-jan-11 pjt carma-23 formatting improved
c          11-feb-11 pjt systemp computation improved (nschan and flags)
c          17-feb-11 pjt increased MAXSPECT for sci2 (needs 32)
c           2-aug-11 pjt add options=allants
c           7-dec-11 pjt add gap to tinker with less output records
c          18-mar-13 pjt fix purpose reporting when same source changes in the middle
c
c
c TODO:
c      - remove old corr column - check with Doug Friedel
c      - there is a strange bug (causing segfault) if the cal*h are replaced with maxdim.h
c        suggesting somebody is writing over it's boundaries.
c      - inttime can vary per baseline, and one needs to use MAX(inttime)
c        not the first one found... (bugzilla 1058)
c-----------------------------------------------------------------------
	include 'mirconst.h'
        include 'caldefs.h'
        include 'calapply.h'
        include 'listobs.h'
c
	character pversion*80, versan*80
c
        integer ipt,nfiles,uvflag,order(MAXP),nameidx(100),nnames
        integer isys(MAXANT),i,uvscan,j,ii,jj,ipicked,ifix
        integer tin,k,nfocs,length,nhere,hereidx(MAXANT)
	character dataset(MAXF)*128,outlog*128,text*256,dash*80
	character radec*24,uthms*8,lsthms*8,oldsou*17,newsou*17
	character type*1, sftime*30,oldpur*5,newpur*5
	real diff,totint,tint,baseline(MAXBASE),focus(MAXANT,50)
	real focnew(MAXANT),focold(MAXANT),focdiff,rlst,uvd
        real bl
	double precision jdold,jdnow,antpos(3 * MAXANT),apos(6)
	double precision foclst(50),focjday(50),ftime,jdend,utend
        double precision lat,lon,sinlat,coslat,sinlon,coslon,gap
	logical more,fthere,anthere(MAXANT),updated,nobase,allants
        logical pthere
        integer len1,tlen1
        data more /.true./
c----------------------------------------------------------------------c

        pversion=versan('listobs',
     *  '$Revision$',
     *  '$Date$')
c-----------------------------------------------------------------------

	dash = '----------------------------------------' //
     1	       '----------------------------------------' 
c
c-----------------------------------------------------------------------
c    get data set name and output file name
c
        call keyini
        call mkeyf('vis',dataset,MAXF,nfiles)
        if (nfiles.eq.0)
     *      call bug('f','No data set name(s) given; use vis=')
	call keya('log',outlog,' ')
        call keyd('gap',gap,1.0d0)
        call getopt(nobase,allants)
        call keyfin
c
c-----------------------------------------------------------------------
c    initialize array counter and focus counter
	ipt   = 0
	nfocs = 0
        do i=1,MAXANT
           anthere(i) = .false.
        enddo
        sinlat = 1.0d0
        coslat = 0.0d0
        sinlon = 1.0d0
        coslon = 0.0d0
        jdend  = -1.0d0
c-----------------------------------------------------------------------
c    gather up all of the data from all files requested
c
	do 100 i=1,nfiles
           write(text,'(a,a)') 'Opening File: ',dataset(i)
           call output(text)
           call uvopen(tin,dataset(i),'old')
           call uvread(tin,preamble,data,flags,maxchan,nread)
           call uvgetvra(tin,'source',oldsou)
c --- check if focus is missing as it is in old data ----
	   call uvprobvr(tin,'focus',type,length,fthere)
c --- check source purpose
           call uvprobvr(tin,'purpose',type,length,pthere)
           if (pthere) call uvgetvra(tin,'purpose',oldpur)
           ipt = ipt + 1
	   if(ipt.gt.MAXP)CALL bug('f','Too many points')
	   call getall(tin,ipt,pthere,nread,flags)
	   jdold = jday(ipt)
	   call uvgetvrr(tin,'inttime',tint,1)
	   totint = tint
	   if(i .eq. 1) then
	      call uvgetvrd(tin,'antpos',antpos,nants*3)
              call uvgetvrd(tin,'latitud',lat,1)
              call uvgetvrd(tin,'longitu',lon,1)
              sinlat = sin(lat)
              coslat = cos(lat)
              sinlon = sin(lon)
              coslon = cos(lon)
	   endif
	   if(fthere) then
	      nfocs = nfocs + 1
	      call uvgetvrr(tin,'focus',focold,nants)
              do j=1,nants
 	         focus(j,nfocs) = focold(j)
	      enddo 
	      call uvgetvrd(tin,'time',focjday(nfocs),1)
	      call uvgetvrd(tin,'lst',foclst(nfocs),1)
	   endif
           uvflag = uvscan(tin,'coord')
	   dowhile (uvflag .ge. 0)
              call uvgetvrr(tin,'baseline',bl,1)
              call basant(dble(bl),ii,jj)
              anthere(ii) = .true.
              anthere(jj) = .true.
              call uvprobvr(tin,'ut',type,length,updated)
	      if(updated) then
		 call uvgetvrd(tin,'time',jdnow,1)
		 call uvgetvrr(tin,'inttime',tint,1)
                 call uvgetvra(tin,'source',newsou)
                 call uvgetvra(tin,'purpose',newpur)
                 if (jdnow.gt.jdend) then
                    jdend = jdnow + tint/(3600.0*24.0)
                    call uvgetvrd(tin,'ut',utend,1)
                 endif
		 tint = tint/86400.0
                 if (gap.gt.0d0) then
                    diff = jdnow - (jdold + tint + gap/1440.0d0)
                 else
                    diff = jdnow - (jdold + (1.0d0-gap)*tint)
                 endif
		 if(diff.gt.0d0 .or. 
     *                newsou.ne.oldsou .or. newpur.ne.oldpur) then
		    dur(ipt) = totint/60.0
		    ipt      = ipt + 1
	            if(ipt.gt.MAXP)CALL bug('f','Too many points[MAXP]')
		    call getall(tin,ipt,pthere,nread,flags)
		    totint   = 86400.0 * tint
                    oldsou = newsou
                    oldpur = newpur
                 else
                    totint = totint + 86400.0 * tint
		 endif
		 jdold  = jdnow

		 if(fthere) then
                    call uvgetvrr(tin,'focus',focnew,nants)  
                    focdiff = 0.0 
                    do j=1,nants 
                       focdiff = focdiff + abs(focold(j)-focnew(j)) 
                    enddo
                    if(focdiff .gt. 0.2) then 
                       nfocs = nfocs + 1
                       do j=1,nants   
                          focus(j,nfocs) = focnew(j)
		          focold(j) = focnew(j)
                       enddo     
	  	       call uvgetvrd(tin,'time',focjday(nfocs),1)
                       call uvgetvrd(tin,'lst',foclst(nfocs),1)
                    endif
	 	 endif
	      endif
              uvflag = uvscan(tin,'coord')
           enddo
           dur(ipt) = totint/60.
	   call uvclose(tin)
  100	continue
c
c-----------------------------------------------------------------------
c   time sort the Julian day array gathered expressly for this
c   purpose. Result is the index array order which contains the array
c   indices in time order.
c
	call sortidxd(ipt,jday,order)
        ftime = jday(order(1))
        call julday(ftime,'H',sftime)
c
c-----------------------------------------------------------------------
c   Make a list of the source names observed
c
	call findnam(ipt,objs,nameidx,nnames)
c
c-----------------------------------------------------------------------
c   Make a cross listing for which of antennas were actually present
c      in the array during data taking
c
        nhere = 0
        do i=1,nants
           if(anthere(i)) then
             nhere = nhere + 1
             hereidx(nhere) = i
           endif
        enddo
c        if(nhere .gt. 9) nhere = 9

c
c-----------------------------------------------------------------------
c   Print starting information and list of files used as input
c
	call LogOpen(outlog,' ')
	call LogWrite('                SUMMARY OF OBSERVATIONS ',more)
	call LogWrite(dash,more)
	call LogWrite(dash,more)
	do 150 j=1,nfiles
	   write(text,2001) dataset(j)
	   call LogWrite(text,more)
  150	continue
 2001	format('Input file: ',a)
	call LogWrite(dash,more)
c
c   Write out antenna locations and baselines
c
	call LogWrite('         Antenna and Baseline Information',more)
	call LogWrite('         --------------------------------',more)
	call LogWrite('            Antenna Locations (in nsec)'//
     1                '            Antenna Locations (in m)',more)
        call LogWrite('                 X           Y           Z    '//
     1                       '          E           N           U    '
     2                   ,more)
	do 160 j=1,nants
           if(anthere(j) .or. allants) then
	      do jj=1,3
	         apos(jj) = antpos(j+nants*(jj-1))
              enddo
c                  apos(1..3) is XYZ    apos(4..6) is ENU
              apos(4) =  apos(2)
              apos(5) = -apos(1)*sinlat + apos(3)*coslat
              apos(6) =  apos(1)*coslat + apos(3)*sinlat
	      do jj=4,6
	         apos(jj) = apos(jj) * DCMKS/1.0d9
              enddo

	      write(text,2002) j,(apos(jj),jj=1,6)
	      call LogWrite(text,more)
           endif
  160	continue
 2002	format('Antenna ',i2,': ',3(f10.4,2x),2x,3(f10.3,2x))
        if (.not.nobase) then
          call LogWrite(dash,more)
	  call LogWrite('           Baselines in Wavelengths',more)
          call LogWrite('           ------------------------',more)
	  call LogWrite('      for Decl = 0 deg. Source at Transit',
     1                  more)
	  call LogWrite('                  '//
     1                  'U             V             W'//
     2                  '           UVdistance',more)

	  do j=1,nants-1
	   do k=j+1,nants
              if(anthere(j) .and. anthere(k)) then
	         do jj=1,3
	 	    baseline(jj) = linefreq(1)*(antpos(j+nants*(jj-1)) -
     1			       antpos(k+nants*(jj-1)))
                 enddo
                 uvd = sqrt(baseline(2)**2 + baseline(3)**2)
	         write(text,2003) j,k,baseline(2),baseline(3),
     1                         baseline(1),uvd
	         call LogWrite(text,more)
              endif
           enddo
          enddo
        endif
 2003	format('Bsln  ',i2,'-',i2,': ',4(f11.2,2x))
c
c   Write out section showing source names, coordinates, and corr freqs
c
	call LogWrite(dash,more)
	text = '            Observed Sources Coordinates and Corr Freqs'
	call LogWrite(text,more)
	write(text,2004)
 2004	format('Source         Purpose    RA         Decl         Vlsr',
     1         '            Corfs in MHz')
	call LogWrite(text,more)
	do 200 j=1,nnames
c           write(*,*)nameidx(j)
	   call DegHms(ra(nameidx(j))*180.0d0/DPI,
     1                 dec(nameidx(j))*180.0d0/DPI,radec)
	   write(text,2005) objs(nameidx(j)),purpose(nameidx(j)),radec,
     1                   vel(nameidx(j)),
     1                   (corfs(nameidx(j),i),i=1,ncorfin)
	   call LogWrite(text,more)
  200	continue
 2005   format(a,2x,a,2x,a,3x,1pe9.2,3x,4(0pf5.1,1x))
c
c   Write out section showing frequency set-up
c
	call LogWrite(dash,more)
	call LogWrite('                         Frequency Set-up',more)
	call pickone(objs,dur,ipt,ipicked)
	call rad2hms(utst(ipicked),uthms)
	call rad2hms(lst(ipicked),lsthms)
	write(text,2051) objs(ipicked),uthms,lsthms
	call LogWrite(text,more)
	write(text,2061) linname(ipicked),linefreq(ipicked),
     1                   iffreq(ipicked)
	call LogWrite(text,more)
	write(text,2071) veltype(ipicked),veldop(ipicked),flo(ipicked)
	call LogWrite(text,more)
 2051	format('   Source: ',a,'          UT: ',a,12x,'  LST: ',a)
 2061	format('Line Code: ',a,'   Rest Freq: ',f9.4,' GHz',
     1      '     IF Freq: ',f9.3,' MHz')
 2071	format('Velo Code: ',a,' Anten Vel: ',f9.2,' km/s ',
     1            '  First LO: ',f9.4,' GHz')
	call LogWrite(dash,more)
        write(text,2110) sftime(1:7)
	call LogWrite(text,more)
        text = 'Source              UT      LST     Dur Elev  ' //
     1         '     Sys Temps (K)'
	call LogWrite(text,more)
        write(text,'(''                  hhmmss   hhmmss'')')
        tlen1 = len1(text)
        write(text(tlen1+1:),'(''    min deg    '',23(i2,3x))')
     1        (hereidx(i),i=1,nhere)
	call LogWrite(text,more)
 2110   format('               Chronology of Observations on ',A)
	do 300 i=1,ipt
	ii = order(i)
	call rad2hms(utst(ii),uthms)
	call rad2hms(lst(ii),lsthms)
	do 250 j=1,nants
	   isys(j) = ifix(syst(ii,j)+0.0001)
  250	continue
        write(text,2201) objs(ii),uthms,lsthms,dur(ii),el(ii),
     1        (isys(hereidx(j)),j=1,nhere)
 2201	format(a,1x,a,1x,a,1x,f5.1,1x,f4.0,1x,  
     1       23(i4,1x))
c 2202	format(a,1x,a)
	call LogWrite(text,more)
  300	continue
c	call rad2hms(real(utend),uthms)
c        write(text,2202) '<END>            ',uthms
c	call LogWrite(text,more)
	call LogWrite(dash,more)
c
c    organize focus numbers in time order and see if there are any
c    changes with time
c
	call sortidxd(nfocs,focjday,order)
 2301	format('              Record of Focus Values')
	if(nfocs .gt. 0) then
           write(text,2301)
           call LogWrite(text,more)
	   rlst = foclst(order(1))
	   call rad2hms(rlst,lsthms)
	   write(text,2305) lsthms,
     1                      (focus(hereidx(j),order(1)),j=1,nhere)
 2305      format('At LST: ',a,' Focus=',15(f5.1,1x))
	   call LogWrite(text,more)
	   do i=2,nfocs
	      ii = order(i)
              jj = order(i-1)
	      focdiff = 0.0
 	      do j=1,nants
 	         focdiff = focdiff + abs(focus(j,ii)-focus(j,jj))
	      enddo
	      if(focdiff .ge. 0.2) then
                 rlst = foclst(ii)
                 call rad2hms(rlst,lsthms)
                 write(text,2305) lsthms,
     1                            (focus(hereidx(j),ii),j=1,nhere)
                 call LogWrite(text,more) 
              endif
	   enddo
	   call LogWrite('Focus constant to end of file',more)
	endif

	call LogClose

	end
c-----------------------------------------------------------------------
	subroutine findnam(nobs,objts,indx,nidx)
c
c  sort through objects names to collect index locations of unique
c  sources.
c
        implicit none
        include 'maxdim.h'
        include 'listobs.h'
        integer tindx
	character*(*) objts(*)
	integer nobs,nidx,indx(*),i,j,k
	character*10 oldnames(100)
        character*5 oldpurp(10000)
	nidx = 1
	oldnames(1) = objts(1)
        oldpurp(1) = purpose(1)
        
	indx(1) = 1
	do 100 i=1,nobs
	   do 50 j=1,nidx
	      if(objts(i) .eq. oldnames(j))then
                 do k=1,i-1
                    if(objts(i) .eq. objts(k))then
                       if(index(purpose(k),purpose(i)(1:1)) .eq. 0) then
                          tindx=index(purpose(k)," ")
                          purpose(k) = purpose(k)(1:tindx-1)
     *                                //purpose(i)(1:1)
                       endif
                       exit
                    endif
                 enddo
                 go to 55
              endif
   50      continue
	   nidx = nidx + 1
	   oldnames(nidx) = objts(i)
           oldpurp(nidx) = purpose(i)
	   indx(nidx) = i
   55	   continue
  100	continue

	return
	end
c-----------------------------------------------------------------------
	subroutine pickone(objs,dur,nobj,ipicked)
	character objs(1)*(*)
	real dur(*),sums(100),maxval
	integer nobj,ipicked,i,j,indx(100),nidx
c
	do 100 i=1,100
	   sums(i) = 0.0
  100	continue
	call findnam(nobj,objs,indx,nidx)
	do 200 i=1,nidx
	   do 150 j=1,nobj
	      if(objs(indx(i)) .eq. objs(j)) 
     1                sums(i) = sums(i) + dur(j)
  150      continue
  200	continue
	maxval = -1.0
	do 300 i=1,nidx
	   if(sums(i) .gt. maxval) then
	      maxval  = sums(i)
	      ipicked = i
	   endif
  300	continue
	ipicked = indx(ipicked)
	return
	end
c-----------------------------------------------------------------------
	subroutine getall(tin,ipt,pthere,nread,flags)
c
c   gets all the header information that will be later printed
c

        include 'caldefs.h'
c        include 'maxdim.h'
        include 'listobs.h'

	integer tin,ipt,iants,j,i,length,nschan(MAXSPECT)
	double precision utdouble,dlst,dlinef,dlo1,dif,lat,draobs,
     1                   ddecobs,sfreq(MAXSPECT)
	real systemps(MAXSPECT*MAXANT),tsys
        real cfreq(MAXSPECT/2),haobs,decobs,sum
        character vtype*4
        logical vupd,systhere,pthere,first
        data first/.TRUE./
c
c   get all of the desired uv variables from header
c
	call uvgetvrd(tin,'time',jday(ipt),1)
	call uvgetvrd(tin,'ut',utdouble,1)
	call uvgetvra(tin,'source',objs(ipt))
        if(pthere)then
           call uvgetvra(tin,'purpose',purpose(ipt))
        else
           purpose(ipt) = " "
        endif
c       write(*,*) ipt,objs(ipt),purpose(ipt)
c	call uvgetvrd(tin,'ra',ra(ipt),1)
c	call uvgetvrd(tin,'dec',dec(ipt),1)
	call uvrdvrd(tin,'ra',ra(ipt),0.0d0)
	call uvrdvrd(tin,'dec',dec(ipt),0.0d0)

	call uvgetvrr(tin,'vsource',vel(ipt),1)
	call uvgetvri(tin,'nants',iants,1)
	call uvrdvri(tin,'nspect',nspec,0)
	if(nspec.ne.0)then
	  call uvgetvri(tin,'nchan',nchan,1)
          call uvgetvri(tin,'nschan',nschan,nspec)
c the following was changed to accomodate CARMA data (doesn't use corfin)
c and SZA data (in version 1.1 system has wrong dimension)
          call uvprobvr(tin,'corfin',vtype,ncorfin,vupd)
          if(ncorfin.ne.0)then
             call uvgetvrr(tin,'corfin',cfreq,ncorfin)
          else
             ncorfin=1
             cfreq(1)=0
          endif
	  call uvprobvr(tin,'systemp',vtype,length,systhere)
	  if(systhere) then
             if (length.eq.iants*nspec) then
     	  	call uvgetvrr(tin,'systemp',systemps,iants*nspec)
             else
     	  	call uvgetvrr(tin,'wsystemp',systemps,iants*nspec)
             endif
          endif
	else
	  call uvrdvri(tin,'nwide',nspec,0)
	  if(nspec.ne.0)
     *		call uvgetvrr(tin,'wsystemp',systemps,iants*nspec)

	endif

	call uvgetvrd(tin,'lst',dlst,1)
	call uvrdvrd(tin,'freq',dlinef,0.d0)
c handle SZA that doesn't store freq, grab the middle sfreq
        if (dlinef.eq.0d0) then
           call uvgetvrd(tin,'sfreq',sfreq,nspec)
           dlinef = sfreq(nspec/2)
        endif
	call uvgetvra(tin,'veltype',veltype(ipt))
	call uvrdvrr(tin,'veldop',veldop(ipt),0.)
	call uvrdvrd(tin,'lo1',dlo1,0.d0)
	call uvrdvrd(tin,'freqif',dif,0.d0)
	call uvrdvrd(tin,'obsra',draobs,0.d0)
	call uvrdvrd(tin,'obsdec',ddecobs,0.d0)
        call uvrdvrd(tin,'latitud',lat,0.0d0)

c
c   Process the variables that need it
c
        utst(ipt) = utdouble
	lst(ipt)  = dlst

c   LSB for C16-23 not flagged yet, so use this kludge
        if (first) then
           call bug('w','Only Tsys < 10,000 used in band averaging')
           first = .FALSE.
        endif

	do 200 i=1,iants
	   sum = 0.0
           isum = 0
	   do 100 j=1,nspec
              tsys = systemps(i + (j-1)*iants)
              if (nschan(j).GT.0 .AND.  tsys.LT.9999.9) then
	         sum = sum + tsys
                 isum = isum + 1
              endif
  100	   continue
           if (isum.gt.0) then
              syst(ipt,i) = sum/isum
           else
              syst(ipt,i) = 0.0
           endif
  200	continue
	if(iants .gt. nants) nants = iants
	do 300 i=1,ncorfin
	   corfs(ipt,i) = 1000.0*cfreq(i)
  300   continue
	linname(ipt)  = 'unknown'
	linefreq(ipt) = dlinef
	iffreq(ipt)   = 1000.0 * dif
	flo(ipt)      = dlo1
	haobs = dlst - draobs
	decobs = ddecobs
	call CalElev(haobs,decobs,el(ipt),REAL(lat))
	el(ipt) = 57.29578 * el(ipt)
	return
	end
c-----------------------------------------------------------------------
	subroutine Rad2Hms(SRadTime,CharHms)
	character*8 CharHms
        real        SRadTime
c
c   Converts time in radians to time in hh:mm:ss.s in a character
c   string
c
        include 'mirconst.h'

	double precision RadTime,secs,time,dble
	integer ihour,imin,idint

        RadTime = SRadTime
	time  = 12.0*RadTime/PI
	ihour = idint(time)
	imin  = idint(60.0d0*(time-dble(ihour)))
	secs  = 60.0d0 * (60.0d0 * (time-dble(ihour)) - dble(imin))
	if(secs .ge. 9.95d0) then
	    write(CharHms,2001) ihour,imin,secs
	else
	    write(CharHms,2002) ihour,imin,secs
        endif
        if (CharHms(8:8) .eq. '*') then
           write(*,*) radtime,time,ihour,imin,secs,' =>',charhms
           call bug('f','bad rad2hms conversion')
        endif
c        if (CharHms(5:6).eq.'60') then
c           call bug('w','Bad RAD2HMS conversion')
c           write(*,*) 'PJT: ',radtime,' ',charhms
c           write(*,*) '     ',time,ihour,imin,secs
c        endif
c        print 2002, secs
 2001	format(i2.2,i2.2,f4.1)
 2002	format(i2.2,i2.2,'0',f3.1)
	return
	end
c-----------------------------------------------------------------------
	subroutine CalElev(ha,decl,elev,lat)
c
c    Calculates the source Elevation from the source hour angle (HA),
c    declination (DECL) and latitude of observatory (LAT)
c    HA, DECL, and ELEV are all in radians.
c
	real ha,decl,elev,lat,dummy

	dummy = sin(decl)*sin(lat) + 
     1          cos(decl)*cos(ha)*cos(lat)
	elev  = asin(dummy)
	return
	end
c-----------------------------------------------------------------------
        subroutine getopt(nobase,allants)
        implicit none
        logical nobase,allants
c
        integer nopt
        parameter(nopt=2)
        character opts(nopt)*9
        logical present(nopt)
        data opts/'nobase   ','allants  '/
        call options('options',opts,present,nopt)
        nobase = present(1)
        allants = present(2)
        end

