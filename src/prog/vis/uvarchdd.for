c************************************************************************
	program uvarchdd
	implicit none
c
c= UVARCHDD - Print card catalog data values from uv dataset
c& mjs
c: uv analysis
c+
c	UVARCHDD lists selected uv variables in a MIRIAD dataset, to be
c	used in generating a card catalog of information on archived
c	Hat Creek data.  This task is specific to the needs of the BIMA
c	database, and is not intended for any other use (though no harm
c       will come from using it).
c
c	Though the program uses subroutine SelInput to look for `select'
c	keywords, the `select' keyword MUST NOT be present ... this 
c       reference should be removed for cleanliness someday.
c
c@ vis
c	The input uv dataset name. No default.
c@ proj
c	User-defined project name, up to 39 characters.  The default
c	is `-'.  Entries longer than 39 characters will be truncated.
c@ machine
c	The machine IP number (not a locally-known alias) where the
c	archived data is stored.  If NCSA's Common File System (cfs),
c	enter `ncsa-cfs'.  39 characters maximum.  No default.
c@ file
c	The fully-qualified filename (not a MIRIAD dataset name) of the
c	archived data.  1024 characters maximum (a presumed unix
c       MAXPATHLEN).  No member of the pathname may be longer than 16
c       characters.  No default.
c@ size
c	The size in KB of the MIRIAD dataset.  Caution:  not all
c	machines give the same result from `du -s'.  For example, the
c	Cray2 (UNICOS 6.0/SYSV) returns a number that must be multiplied
c	by 4 to yield the size in KB.  The default is 0, implying that
c	no size was given.
c@ cksum
c	Checksum, input as an integer.  The default is -1, implying that
c	no value was given.
c@ flist
c	File containing the list of uv variables to be included in the
c	catalog.  The standard list of uv variables cataloged for Hat
c	Creek data is contained in file `$MIR/cat/uvctlg', and this
c	is the default.  Environment variables may be used in the
c	filename.  Maximum pathlength is 96 characters.
c@ log
c	The list output file name. The default is the terminal.
c--
c
c  History:
c   05jun91 mjs  - Initial version, from UVLIST.
c   17jun91 mjs  - Further hacking in the iterative process.
c   30sep91 mjs  - Include RA and DEC in radians, too; by request.
c   23sep93 mjs  - Righteously remove 30sep91 mod, since requestor left;
c                  bsrch->binsrch name change.
c   27sep93 mjs  - Make flint complain less.
c   27jan94 mjs  - Elim pathname element length.
c   07feb94 mjs  - Add cksum as a keyword input parameter.
c   20jun98 pjt  - no (EQ,EQV), but simple if(ret)then ; g77 induced
c   15dec00 pjt  - some longer names, increased maxdata for biggish things
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='(version 1.0 15-dec-00)')
	real rtoh,rtod,pi
	integer maxsels
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	parameter(maxsels=1024)
	character*256 defname
	parameter (defname='$MIR/cat/uvctlg')
c
	real sels(maxsels)
	character vis*128,out*128,line*256
	character proj*40,flist*256,machine*40,file*1024
	character tmpname*256,fullname*256,date*18
	integer isize,icksum
	complex data(maxchan)
	logical flags(maxchan)
	logical more,eof
	integer unit1,unit,numchan,num
	integer ilist(200),iostat,i,j
	character*8 alist(200)
c
	integer llen
c
	double precision uin,vin,timein,basein
	common/preamb/uin,vin,timein,basein
c
c  Externals.
c
	logical uvupdate
c
c  Read the inputs.
c
	call output('UVARCHDD '//version)
	call output(' ')
 	call keyini
	call keya('vis',vis,' ')
	if (vis.eq.' ')
     +    call bug('f','Input uv dataset must be given')
	call SelInput('select',sels,maxsels)
        call keya('proj',proj,'-')
        call keya('log',out,' ')
        call keya('machine',machine,'-')
        call keyi('size',isize,0)
        call keyi('cksum',icksum,-1)
        call keya('file',file,'-')
        call keya('flist',flist,defname)
	call keyfin
c
c	if (flist(1:1) .eq. ' ') flist = defname
	tmpname = fullname (flist)
	if (len(proj)   .gt. 39) proj = proj(1:39)
	if (len(machine).gt. 39) machine = machine(1:39)
	if (len(file)   .gt. 1024) file = file(1:1024)
c
	numchan  = 0
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
	call VarLoad(unit)
c
c  Get the list of variables to go into the catalog
c
	call txtopen(unit1,tmpname,'old',iostat)
	if (iostat .ne. 0) then
	   line = 'Cannot open '// tmpname
	   llen = len(line)
	   call bug('w',line(1:llen))
	   call bugno('f',iostat)
	endif
	i = 1
	iostat = 0
	dowhile (iostat .eq. 0)
	   call txtread(unit1,line,llen,iostat)
	   if (iostat .eq. 0) then
	      if (llen .lt. 8) then
	         alist(i) = line(1:llen)
	      else
	         alist(i) = line(1:8)
	      endif
	      ilist(i) = 1
	      i = i + 1
	   endif
	enddo
	i = i - 1
	if (i .lt. 1) then
	   line = 'flist has less than 1 entry: '//tmpname
	   llen = len(line)
	   call bug('f',line(1:llen))
	endif
#ifdef cft
	if (iostat .ne. -1001) then
#else
	if (iostat .ne. -1) then
#endif
	   line = 'Problem reading file '//tmpname
	   llen = len(line)
	   call bug('w',line(1:llen))
	   call bugno('f',iostat)
	endif
	call txtclose(unit1)
c
c  Copy across the history file.
c
	line = ':: begin history uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
	call hisopen(unit,'read')
        call hisread(unit,line,eof)
        dowhile(.not.eof)
          call LogWrite(line,more)
          call hisread(unit,line,eof)
        enddo
        call hisclose(unit)
	line = ':: end history uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
c
c  Read through the file, listing what we have to.
c
	num=0
	call uvread(unit,uin,data,flags,maxchan,numchan)
c
	line = ':: begin DB uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
	line = '1dataset: a :        :'//vis
	llen = len(line)
	call LogWrite(line(1:llen),more)
	line = '1proj   : a :        :'//proj
	llen = len(line)
	call LogWrite(line(1:llen),more)
	line = '1machine: a :        :'//machine
	llen = len(line)
	call LogWrite(line(1:llen),more)
	write(line,'(''1size   : i : i25    :'',i25)') isize
	call LogWrite(line(1:47),more)
	write(line,'(''1cksum  : i : i25    :'',i25)') icksum
	call LogWrite(line(1:47),more)
	line = '1file   : a :        :'//file
	llen = len(line)
	call LogWrite(line(1:llen),more)
c
	call JulDay(timein,'H',date)
	llen = 22 + len(date(1:18))
	line(1:llen) = '1date   : a :        :'//date(1:18)
	call LogWrite(line(1:llen),more)
	line = ':: end DB uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
c
	line = ':: begin header uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
c
	dowhile ( numchan.gt.0 .and. num.lt.1)
	  num = num + 1
c
c  List the header, if required.
c
	  if(uvupdate(unit))then
	    call prthd1(unit,ilist,alist,i)
c
c  List out any variables that aren't found
c
	  do j=1,i
	     if (ilist(j) .eq. 1) then
		line(1:8) = alist(j)
		line(9:11) = ': -'
		call LogWrite(line(1:11),more)
	     endif
	  enddo
c
	  endif
	enddo
c
c  Close up shop.
c
	line = ':: end header uv info ::'
	llen = len(line)
	call LogWrite(line(1:llen),more)
	call LogClose
	call uvclose(unit)
	end
c************************************************************************
	subroutine VarLoad(unit)
c
	implicit none
	integer unit
c
c  Load the names of all the variables in the uv data set.
c
c  Inputs:
c    unit	Handle of the input data set.
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
	character varbad(nbad)*8
	data (varbad(j),j=1,nbad)/
     *	'baseline','coord   ','corr    ','lst     ','time    ',
     *	'tscale  ','ut      ','wcorr   '/
c
 	call haccess(unit,item,'vartable','read',is)
	if(is.ne.0) call bugno('f',is)
	vnum=0
	is = 0
	overflow = .false.
 	dowhile (is.eq.0)
 	  call hreada(item,varin,is)
	  if(is.eq.0.and.varin.ne.' ')then
	    select = binsrcha(varin(3:10),varbad,nbad).eq.0
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
	subroutine prthd1(unit,ilist,alist,i)
c
	implicit none
	integer unit,ilist(*),i
	character*8 alist(*)
c
c  This print out the header variables in a standard format, using
c  the table in uvlist.h.
c
c  Inputs:
c    unit	Pointer to dataset.
c    ilist	switch to see if everything has been printed
c    i		number of elements of alist and ilist
c    alist	header variables in the list
c------------------------------------------------------------------------
	integer maxdata
	parameter(maxdata=1024)
	real rtoh,rtod,pi
	parameter(pi=3.141592653589793,rtoh=12/pi,rtod=180/pi)
	include 'uvlist.h'
c
	character vflag*1
	integer k,j,vsubs,ant1,ant2
	logical more,vupd,ret
c
	character line*80
	character sdata*32
	real data(maxdata)
	integer idata(maxdata)
	double precision ddata(maxdata)
c
c  Externals.
c
	character angles*13
c
	do k=1,vnum
	  call uvprobvr(unit,varname(k),vflag,vsubs,vupd)
	  if(vsubs.gt.maxdata) call bug('f','maxdata too small')
	  if(vupd)then
c
	  call cklist(ret,varname(k),alist,ilist,i)
	  if (ret) then
c
c  A real variable.
c
	    if (vflag.eq.'r') then
	      call uvgetvrr(unit,varname(k),data,vsubs)
c
	      if     (varname(k)(1:2).eq.'ra') then
	      write(line,'(''ra      : r : e25.18 :'',e25.18)')
     +		    data(1)
	      call LogWrite(line(1:35),more)
c
	      else if(varname(k)(1:2).eq.'ha') then
	      line = 'ha      : a :        :'//
     +		     angles(dble(data(1))*rtoh)
	      call LogWrite(line(1:35),more)
c
	      else if (varname(k)(1:3).eq.'dec') then
	      write(line,'(''dec     : r : e25.18 :'',e25.18)')
     +		    data(1)
	      call LogWrite(line(1:35),more)
c
	      else if (varname(k).eq.'baseline') then
	      ant1 = data(1)/256
	      write(line,'(''baseline: i : i25    :'',i25)') ant1
	      call LogWrite(line(1:47),more)
	      ant2 = data(1) - ant1*256
	      write(line,'(''baseline: i : i25    :'',i25)') ant2
	      call LogWrite(line(1:47),more)
c
	      else
	      do j=1,vsubs
	         write(line,'(a8,'': r : e25.18 :'',e25.18)')
     +		       varname(k),data(j)
		 call LogWrite(line(1:47),more)
	      enddo
	      end if
c
c  A character variable.
c
	  else if (vflag.eq.'a') then
	    call uvgetvra(unit,varname(k),sdata)
	    write(line,'(a8,'': a :        :'',a)') varname(k),
     +						    sdata
	    vsubs = 22 + len(sdata)
	    call LogWrite(line(1:vsubs),more)
c
c  An integer variable.
c
	  else if (vflag.eq.'i') then
	    call uvgetvri(unit,varname(k),idata,vsubs)
	    do j=1,vsubs
	      write(line,'(a8,'': i : i25    :'',i25)') varname(k),
     +							idata(j)
	      call LogWrite(line(1:47),more)
	    enddo
c
c  A double precision variable.
c
	  else if (vflag.eq.'d') then
	    call uvgetvrd(unit,varname(k),ddata,vsubs)
	    if      (varname(k)(4:5).eq.'ra') then
	    line = varname(k) // ': a :        :' //
     +		   angles(ddata(1)*rtoh)
	    call LogWrite(line(1:35),more)
	    else if (varname(k)(1:2).eq.'ut') then
	    line = varname(k) // ': a :        :' //
     +		   angles(ddata(1)*rtoh)
	    call LogWrite(line(1:35),more)
	    else if (varname(k)(1:3).eq.'lst') then
	    line = varname(k) // ': a :        :' //
     +		   angles(ddata(1)*rtoh)
	    call LogWrite(line(1:35),more)
	    else if (varname(k)(4:6).eq.'dec') then
	    line = varname(k) // ': a :        :' //
     +		   angles(ddata(1)*rtod)
	    call LogWrite(line(1:35),more)
	    else
	      do j=1,vsubs
	      write(line,'(a8,'': d : e25.18 :'',e25.18)')
     +		    varname(k),ddata(j)
	      call LogWrite(line(1:47),more)
	      enddo
	    end if
c
c  Something else ??
c
	    else
	      continue
	    endif
	  endif
	  endif
	enddo
c
	end
c	---------------------------------------------------
	subroutine cklist(ret,name,alist,ilist,i)
c
	implicit	none
	logical		ret
	character*8	name
	character*8	alist(*)
	integer		ilist(*)
	integer		i
c	---------------------------------------------------
c	See if a variable (name) is on the list (alist); if
c	so, set a value to show that it's been found (ilist)
c	and set ret = .true.; else set ret = .false. to show
c	that it isn't on the list.  The list has (i) entries.
c	---------------------------------------------------
	integer		j
c
	ret = .false.
	do j=1,i
	   if (name .eq. alist(j)) then
	      ilist(j) = 0
	      ret = .true.
	      return
	   end if
	enddo
	end
