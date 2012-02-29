c**********************************************************************c
      program uvbflag
      implicit none
c= UVBFLAG - flag uv-data based on blanking mask
c& pjt
c: uv analysis, blanking, flagging
c+
c  UVBFLAG is a Miriad program to apply the blanking mask
c  (carried in the UV variable 'bfmask') and carry them into
c  the normal uv-data flags.  This has been a standard operation
c  at CARMA since early 2012.
c 
c  It might be wise to make a copy of the flags and wflags items
c  before complex operations are attempted.
c
c  A bit about logic, flags and masking:
c  The flags in a vis dataset are true/false, a true value for a correlation 
c  means that bit is set, and the correllation is deemed good.
c  The blanking mask is set if some bad condition was met during observing
c  that ought to cause flags to be set to false, e.g. lost phaselock,
c  shadowing etc.
c  
c
c  See UVCHECK or UVFLAG for related flagging operations.
c
c@ vis
c	The input visibility file. No default.
c@ flagval
c       set to either 'flag' or 'unflag' to flag the data.
c       Default: don't change the flags, but operations
c       are reported had there been flagging or unflagging.
c@ mask
c       A list of mnemonic names, or digits (1=first, 31=last), which
c       are to be used to transfer masking bits to the normal uv flags. 
c       If any of these bits BFmask has been set, this particular 
c       (baseline,window) pair is then selected
c       See also: http://www.mmarray.org/twiki/index.php/Blanking_and_flagging
c       Note that bit 32 is not used, due to possible confusion with the 
c       sign bit.
c       If BFmask is not dimensions, it will be applied to all windows.
c       for flagval (which can be flagged or unflagged)
c       Full names of the masking bits are in the miriad item 'blfmask',
c       carried in the uv dataset.
c       Currently for CARMA (2012) we use the following bits (1..31)
c
C        1 A1_PHASELOCK
C        2 A2_PHASELOCK
C        3 A1_MAJOR_TRACKING
C        4 A2_MAJOR_TRACKING
C        5 A1_TSYS_BAD
C        6 A2_TSYS_BAD
C        7 A1_SHADOWED
C        8 A2_SHADOWED
C        9 A1_OFFLINE
C       10 A2_OFFLINE
C       11 A1_MINOR_TRACKING
C       12 A2_MINOR_TRACKING
C       13 UNKNOWN10
C       14 UNKNOWN11
C       15 UNKNOWN12
C       16 UNKNOWN13
C       17 UNKNOWN14
C       18 UNKNOWN15
C       19 UNKNOWN16
C       20 UNKNOWN17
C       21 UNKNOWN18
C       22 UNKNOWN19
C       23 UNKNOWN20
C       24 UNKNOWN21
C       25 BAND_OFFLINE
C       26 UNMAPPED_SIGNAL
C       27 MONITOR_DATA_BAD
C       28 BAD_CHANNEL_COUNT
C       29 NO_RX_IN_SIDEBAND
C       30 CORR_DATA_MISSING
C       31 CORR_DATA_INVALID
C       32 DO_NOT_USE
c
c@ logic
c       What operation to apply to masking? AND, OR or XOR are
c       allowed. Default: AND
c@ log
c	The output log file. Default is the terminal.
c@ options
c       Extra processing options. Possible values are:
c         debug    Print more output
c--
c
c
c  History:
c    pjt  20oct2011  Original cloned off uvflag
c    pjt  23feb2012  new cloned off uvcheck
c----------------------------------------------------------------------c
	include 'maxdim.h'
	character version*128
	integer MAXSELS, MAXBIT, nflag, nwflag
	parameter(MAXSELS=512,MAXBIT=32)
	real sels(MAXSELS)
	complex data(MAXCHAN)
	double precision preamble(5),freq,obsdec
	integer lIn,nchan,nread,nvis,nspect,varlen,nwide
	real start,width,step
	character vis*128,log*128,line*128,date*18,var*9,vartype*1
        character oper*10
	character source*9,linetype*20,flagval*10
	logical flags(MAXCHAN),updated,doflag,varflag,newflag
	logical dowide
	integer nvar,ant1,ant2,bfmask(MAXWIN),nvisflag
        integer mask1(MAXBIT),mask2(MAXBIT),mask3(MAXBIT),i
        integer list1(MAXBIT),list2(MAXBIT),list3(MAXBIT),n1,n2,n3
	double precision datline(6)
        integer CHANNEL,WIDE,VELOCITY,type
        parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
        logical histo,debug,mrepeat
c
c  Externals and data
c
        character*128 versan
        logical ismasked
	integer len1
	data nvar/0/
c
c  Get the parameters given by the user.
c
        version = versan ('uvbflag',
     :                  '$Revision$',
     :                  '$Date$')

	call output(version)
	call keyini
	call keyf ('vis',vis,' ')
	call keyline(linetype,nchan,start,width,step)
	call SelInput ('select',sels,maxsels)
	call keya ('flagval',flagval,' ')
	call keya ('log',log,' ')
c @todo: this will need to become an options list, via getopt() style
        call mkeyi('mask',list1,MAXBIT-1,n1)
        call keya('logic',oper,'AND')
	call GetOpt(histo,debug)
	call keyfin
c
c  Check that the inputs are reasonable.
c
      if (vis.eq.' ') call bug ('f', 'Input name must be given')
      if (nchan.gt.0) nchan = min (nchan,maxchan)
      if (nchan.lt.0) call bug ('f', 'Bad number of channels')
      if (width.le.0.0) call bug ('f','Negative width is useless')
      if (step.ne.1.) call bug ('f','step must be 1 in line=') 
      doflag = flagval.eq.'flag' .or. flagval.eq.'unflag'
      newflag = flagval.eq.'unflag'
      call l2m(n1,list1,MAXBIT-1,mask1)
c
c  Open an old visibility file, and apply selection criteria.
c
      call uvopen (lIn,vis,'old')
c
      if(linetype.ne.' ')
     *	  call uvset(lIn,'data',linetype,nchan,start,width,step)
      call uvset(lIn,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call uvset (lIn,'coord','nanosec',0, 0.0, 0.0, 0.0)
      call uvset (lIn,'planet', ' ', 0, 0.0, 0.0, 0.0)
      call SelApply(lIn,sels,.true.)
c
c  Open log file and write title.
c
      call LogOpen(log,' ')
      call LogWrit(version)
      line = 'File: '//vis
      call LogWrit(line(1:len1(line)))
      call LogWrit(' ')
c
c  Append history if flagging was going to occur
c
      if (doflag) then
         call hisopen(lin,'append')
         call hiswrite(lin, version)
         call hisinput(lin, 'UVBFLAG')
      endif
c
c  Miscelaneous initialization.
c
      nvis = 0
      nflag = 0
      nwflag = 0
      nvisflag = 0
c
c  Read the first record.
c
      call uvread (lIn, preamble, data, flags, maxchan, nread)
      if(nread.le.0) call bug('f','No data found in the input.')

c  Get the first bfmask to prepare if we have old data with
c  the wrongly dimensioned bfmask
      var = 'bfmask'
      call uvprobvr(lIn,var,vartype,varlen,updated)
      call uvrdvri(lIn,'nspect',nspect,0)
      if(nspect.eq.0) call bug('f','No spectral windows?')
      if(varlen.eq.0) call bug('f','No bfmask present')
      if(nspect.ne.varlen) then
         write(*,*) nspect,varlen
         call bug('w','bfmask dimension error - repeat bands')
         mrepeat = .TRUE.
      else
c        @ todo, fix this in uvxflag()
         call bug('f','bfmask band based not implmented yet')
         mrepeat = .FALSE.
      endif

c
c  Determine the linetype.
c
      call uvinfo(lin,'line',datline)
      type = nint(datline(1))
      if(type.eq.CHANNEL)  linetype = 'channel'
      if(type.eq.WIDE)     linetype = 'wide'
      if(type.eq.VELOCITY) linetype = 'velocity'
      if(type.eq.VELOCITY.and.doflag) 
     *		call bug('f','can not flag velocity linetype')
c
c  do the wideband if necessary.
c
      call uvprobvr(lIn,'wcorr',vartype,varlen,updated)
      dowide = linetype.eq.'channel' .and. vartype.eq.'c'
c
c  Read the selected data.
c
      do while(nread.gt.0)
	call basant(preamble(5),ant1,ant2)
        call JulDay(preamble(4),'H',date)
	call uvrdvra(lIn,'source',source,' ')
	call uvrdvri(lIn,'nspect',nspect,0)
	call uvrdvri(lIn,'nwide',nwide,0)
	call uvrdvrd(lIn,'freq',freq,0.d0)
        call uvrdvrd(lIn,'obsdec',obsdec,0.d0)
        call uvprobvr(lIn,'bfmask',vartype,varlen,updated)
        if (updated) then
           mrepeat = varlen.ne.nspect
           if (mrepeat) then
              call uvrdvri(lIn,'bfmask',bfmask,0)
              do i=2,nspect
                 bfmask(i) = bfmask(1)
              enddo
           else
              call uvgetvri(lIn,'bfmask',bfmask,nspect)
           endif
c              convert each bfmask(i) into a mask array, and a list for debug
           call getmaski(bfmask(1),mask2)
           call m2l(MAXBIT-1,mask2,n2,list2)
           call maskop(MAXBIT-1,mask1,mask2,oper,mask3)
           call m2l(MAXBIT-1,mask3,n3,list3)
           varflag = ismasked(MAXBIT-1,mask3)
           if (debug) then
              write(*,*) date,ant1,ant2,bfmask(1),varlen,
     *                (list2(i),i=1,n2),
     *                varflag,
     *                (list3(i),i=1,n3)
           endif
        endif
        if (varflag) nvisflag = nvisflag + 1

c
c  Flag the data, if requested
c
        if (doflag) then
           call uvxflag(lIn, flags, nread, dowide,newflag,
     *          varflag, nflag, nwflag, debug)
	endif

c
c  Loop the loop (get next record)
c
        call uvread(lIn, preamble, data, flags, maxchan, nread)
	nvis = nvis + 1
      enddo
c
c  Rename flagged "channels" if linetype.eq.'wide'
c
      if(linetype.eq.'wide')then
	  nwflag = nflag
	  nflag  = 0
      endif
c
c  Write summary.
c
      write(line,'(a,a,i9)') date, ' # records= ', nvis
      call LogWrit(line)
      write(line,'(a,a,i9)') date, ' # flagged= ', nvisflag
      call LogWrit(line)
      write(line,'(i10,a)') nflag,  ' channels flagged'
      call LogWrit(line)
      write(line,'(i10,a)') nwflag, ' wideband flagged'
      call LogWrit(line)
      if(nvar.gt.0)then
        call LogWrit(' nvar > 0 ')
	call LogWrit(line)
      endif
      call LogClose
c
      if (doflag) then
         call hisclose (lIn)
      endif
      call uvclose (lIn)
      end
c********1*********2*********3*********4*********5*********6*********7*c
      subroutine uvxflag(lIn, flags, nread, dowide,newflag,
     *              varflag, nflag, nwflag, debug)
	implicit none
        integer lIn, nread, nflag, nwflag
        logical flags(nread), varflag, newflag, dowide, debug
c
c  flag data if uv-variable, or reference amplitude 
c	is outside the specified range.
c
c--
      include 'maxdim.h'
      complex wdata(MAXWIDE)
      logical wflags(MAXWIDE)
      integer nwread, i

      if(dowide) call uvwread(lIn,wdata,wflags,MAXWIDE,nwread)

      if (varflag) then
        if(debug) then
           write(*,*) '### Flagging record',newflag,dowide
        endif
        do i=1,nread
          flags(i) = newflag
        enddo
        call uvflgwr(lIn,flags)
        nflag = nflag + nread
	if (dowide) then
          do i=1,nwread
            wflags(i) = newflag
          enddo
          call uvwflgwr(lIn,wflags)
	  nwflag = nwflag + nwread
	endif
      endif
      end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(histo,debug)
c
        implicit none
        logical histo,debug
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=2)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'histo   ','debug    '/
c
        call options('options',opts,present,nopts)
        histo = present(1)
        debug = present(2)
        end
c********1*********2*********3*********4*********5*********6*********7*c
c
c m2l:   turn a mask(1..n) into a list(1..nl)
c
      subroutine m2l(n, masks, nw, w)
      implicit none
      integer n, nw, masks(n),w(n)
c
      integer i

      nw = 0
      do i=1,n
         w(i) = 0
         if (masks(i).ne.0) then
            nw = nw + 1
            w(nw) = i
         endif
      end do
      end
c********1*********2*********3*********4*********5*********6*********7*c
c
c
c l2m:   turn a list(1..nl) into a mask(1..n) 
c
      subroutine l2m(nl, l, n, masks)
      implicit none
      integer n, nl, masks(n),l(nl)
c
      integer i

      do i=1,n
         masks(i) = 0
      enddo
      do i=1,nl
         if (l(i).gt.0 .and. l(i).le.n) then
            masks(l(i)) = l(i)
         else
            write(*,*) 'l2m: ', l(i)
            call bug('f','bad value for list in l2m')
         endif
      enddo
      end
c********1*********2*********3*********4*********5*********6*********7*c
c
c maskop:  various masking operations of the form
c          mask3 = mask1 oper mask2  (AND,OR,XOR)
c   or 
c          mask3 = mask1 oper (SET)
c
      subroutine maskop(n, mask1, mask2, oper, mask3)
      implicit none
      integer n, mask1(n), mask2(n), mask3(n)
      character oper*(*)
c
      integer i
c
      if (n.lt.1) call bug('f','maskop: bad array length')

      if (oper.eq.'set' .or. oper.eq.'SET') then
         do i=1,n
            mask3(i) = mask1(i)
         enddo
      else if (oper.eq.'and' .or. oper.eq.'AND') then
         do i=1,n
            mask3(i) = mask1(i) * mask2(i)
         enddo
      else if (oper.eq.'or' .or. oper.eq.'OR') then
         do i=1,n
            mask3(i) = mask1(i) + mask2(i)
         enddo
      else if (oper.eq.'xor' .or. oper.eq.'XOR') then
         do i=1,n
            if (mask1(i).eq.0 .and. mask2(i).eq.0) then
               mask3(i) = 0
            else if (mask1(i).ne.0 .and. mask2(i).ne.0) then
               mask3(i) = 0
            else 
               mask3(i) = 1
            endif
         enddo
      else
         call bug('f','Undefined operand in mask2m')
      endif

      end
c
c  ismasked: return TRUE is any of the bits in the mask were set
c            warning: this logic is opposite from uv flags
c
      logical function ismasked(n,mask)
      integer n, mask(n)
c
      integer i
c
      ismasked = .FALSE.
      do i=1,n
         if (mask(i).ne.0) then
            ismasked = .TRUE.
            return
         endif
      enddo
      end
