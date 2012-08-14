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
c  at CARMA since March 2012, but can be employed by any observatory.
c 
c  It might be wise to make a copy of the flags and wflags items
c  before complex operations are attempted,e.g. using
c       mkdir $VIS/backup 
c       touch $VIS/backup/header
c       copyhd in=$VIS out=$VIS/backup items=wflags,flags
c  NOTE: this will be done by UVBFLAG in one of the next revisions.
c
c  A bit about logic, flags and masking:
c  The flags in a vis dataset are true/false, a true value for a correlation 
c  means that bit is set, and the correllation is deemed good. They appear
c  in the (w)flags item as 1.
c  The blanking mask is set if some (bad) condition was met during observing
c  that ought to cause flags to be set to false, e.g. lost phaselock,
c  bad tracking, antenna shadowing etc.
c  
c  The current version applies flags to all channels in both narrow and wide
c  band (if present). Use UVWIDE to recompute the wide band values based on
c  flags.
c
c  See UVCHECK or UVFLAG for related flagging operations.
c  UVLIST options=bfmask will help you displaying the flags for first window
c
c@ vis
c	The input visibility file. No default.
c@ select
c       Selection of visibilities, as long as they do not change
c       the number of channels or windows, only selections that
c       pick out full records are allowed.
c@ flagval
c       set to either 'flag' or 'unflag' to flag the data.
c       Default: don't change the flags, but operations
c       are reported had there been flagging or unflagging.
c       Warning: flagging and unflagging does not know about previous
c       settings of the flags. In order to return to a previous
c       setting , you will need to make a backup of the flags and wflags
c       items, viz.
c
c@ mask
c       A list of mnemonic names, or digits (1=first, 31=last), which
c       are to be used to transfer masking bits to the normal uv flags. 
c       If any of these bits BFmask has been set, this particular 
c       (baseline,window) pair is then selected
c       See also: http://www.mmarray.org/twiki/index.php/Blanking_and_flagging
c       Note that bit 32 is not used, due to possible confusion with the 
c       sign bit.
c       If BFmask is not dimensioned, it will be applied to all windows
c       for flagval (which can be flagged or unflagged)
c       Full names of the masking bits are in the miriad item 'blfmask',
c       carried in the original uv dataset.
c       Currently for CARMA (2012) we use the following bits (1..31)
c       (options=blfmask should always produce the current list)
c
C        1 A1_PHASELOCK               0x00000001
C        2 A2_PHASELOCK               0x00000002
C        3 A1_MAJOR_TRACKING          0x00000004
C        4 A2_MAJOR_TRACKING          0x00000008
C        5 A1_TSYS_BAD                0x00000010
C        6 A2_TSYS_BAD                0x00000020
C        7 A1_SHADOWED                0x00000040
C        8 A2_SHADOWED                0x00000080
C        9 A1_OFFLINE                 0x00000100
C       10 A2_OFFLINE                 0x00000200
C       11 A1_MINOR_TRACKING          0x00000400
C       12 A2_MINOR_TRACKING          0x00000800
C       13 A1_CALSTATE                0x00001000
C       14 A2_CALSTATE
C       15 UNKNOWN12
C       16 UNKNOWN13
C       17 UNKNOWN14                  0x00010000
C       18 UNKNOWN15
C       19 UNKNOWN16
C       20 UNKNOWN17
C       21 UNKNOWN18                  0x00100000
C       22 UNKNOWN19
C       23 UNKNOWN20
C       24 UNKNOWN21
C       25 BAND_OFFLINE               0x01000000
C       26 UNMAPPED_SIGNAL            0x02000000
C       27 MONITOR_DATA_BAD           0x04000000
C       28 BAD_CHANNEL_COUNT          0x08000000
C       29 NO_RX_IN_SIDEBAND          0x10000000
C       30 CORR_DATA_MISSING          0x20000000
C       31 CORR_DATA_INVALID          0x40000000
C       32 DO_NOT_USE                 0x80000000
c
c@ logic
c       What operation to apply to masking? AND, OR or XOR are 
c       allowed. Default: AND
c       It is not adviced to change this.
c       For flagging:   mask.AND.bfmask  has to be true to flag
c       For unflagging: .NOT.mask.AND.bfmask has to be false to unflag
c@ log
c	The output log file. Default is the terminal.
c@ options
c       Extra processing options. Possible values are:
c         stats    Print out how often each bit mask was set
c         astats   Print out how often each bit mask was set, per antenna
c         debug    Print more output (but only when bfmask changes)
c         blfmask  Show the names in the blfmask item
c         swap     Special option to swap true/false flags in the file
c         all      Show all bfmask(nspect) values for selected records
c         one      Force bfmask(2..nspect) to be bfmask(1)
c--
c
c
c  History:
c    pjt  20oct2011  Original cloned off uvflag
c    pjt  23feb2012  new cloned off uvcheck
c    pjt  22mar2012  fixed up multi-band implementation
c    pjt  22apr2012  fix logic for unflagging
c    pjt  22apr2012  add options=swap 
c    pjt  25apr2012  add options=all and one
c    pjt  15may2012  added CALSTATE, only in documentation
c    pjt  25jun2012  options=stats
c    pjt   5jul2012  options=astats
c    pjt  13aug2012  fixed indexing bug (mostly applied to sci2)
c----------------------------------------------------------------------c
	include 'maxdim.h'
	character version*128, fmt1*32
	integer MAXSELS, MAXBIT, nflag, nwflag
	parameter(MAXSELS=512,MAXBIT=32)
	real sels(MAXSELS)
	complex data(MAXCHAN)
	double precision preamble(5),freq,obsdec
	integer lIn,nchan,nread,nvis,nwin,nspect,varlen,nwide
	real start,width,step,inttime
	character vis*128,log*128,line*128,date*18,var*9,vartype*1
        character oper*10,bfmaska*8
	character source*9,linetype*20,flagval*10
	logical flags(MAXCHAN),updated,doflag,varflag,newflag
	logical dowide,mflag(MAXWIN)
	integer nvar,ant1,ant2,nvisflag,nwinflag,na
        integer bfmask(MAXWIN), nschan(MAXWIN), ischan(MAXWIN)
        integer mask1(MAXBIT),mask2(MAXBIT),mask3(MAXBIT),i,j
        integer list1(MAXBIT),list2(MAXBIT),list3(MAXBIT),n1,n2,n3
        integer counts(MAXBIT+1,MAXANT), amask(MAXANT), alist(MAXANT)
	double precision datline(6)
        integer CHANNEL,WIDE,VELOCITY,type
        parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
        logical debug,mrepeat,doblfmask,doswap,doall,doone,dostats
        logical doastats
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
        version = versan ('UVBFLAG', 
     :                  '$Revision$',
     :                  '$Date$')

	call keyini
	call keyf ('vis',vis,' ')
	call keyline(linetype,nchan,start,width,step)
	call SelInput ('select',sels,maxsels)
	call keya ('flagval',flagval,' ')
	call keya ('log',log,' ')
c @todo: this will need to become an options list, via getopt() style
        call mkeyi('mask',list1,MAXBIT-1,n1)
        call keya('logic',oper,'AND')
	call GetOpt(debug,doblfmask,doswap,doall,doone,dostats,doastats)
	call keyfin
c
c  Check that the inputs are reasonable.
c
      if (vis.eq.' ') call bug ('f', 'Input name must be given')
      if (nchan.gt.0) nchan = min (nchan,maxchan)
      if (nchan.lt.0) call bug ('f', 'Bad number of channels')
      if (width.le.0.0) call bug ('f','Negative width is useless')
      if (step.ne.1.) call bug ('f','step must be 1 in line=') 
      doflag = flagval.eq.'flag' .or. flagval.eq.'unflag' .or. doswap
      newflag = flagval.eq.'unflag'
      call l2m(n1,list1,MAXBIT-1,mask1)
      if (newflag) then
         call maskop(MAXBIT-1,mask1,mask1,'NOT',mask1)
      endif
c
c  Open log file and write title.
c
      call LogOpen(log,' ')
      call LogWrit(version)
      line = 'File: '//vis
      call LogWrit(line(1:len1(line)))
      call LogWrit(' ')

c
c  Open an old visibility file, and apply selection criteria.
c
      call uvopen (lIn,vis,'old')
      if (doblfmask) then
         call blfmask(lIn,0,0,counts,alist)
         call uvclose(lIn)
         stop
      endif
c
      if(linetype.ne.' ')
     *	  call uvset(lIn,'data',linetype,nchan,start,width,step)
      call uvset(lIn,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call uvset(lIn,'coord','nanosec',0, 0.0, 0.0, 0.0)
      call uvset(lIn,'planet', ' ', 0, 0.0, 0.0, 0.0)
      call SelApply(lIn,sels,.true.)
c
c  Append history if flagging was going to occur
c  Make a backup of flags and wflags if they didn't exist yet
c
      if (doflag) then
         call hisopen(lin,'append')
         call hiswrite(lin, version)
         call hisinput(lin, 'UVBFLAG')
         call fbackup(lin)
      endif
c
c  Miscelaneous initialization.
c
      nvis = 0
      nwin = 0
      nflag = 0
      nwflag = 0
      nvisflag = 0
      nwinflag = 0
      do j=1,MAXANT
         amask(j)=0
         do i=1,MAXBIT+1
            counts(i,j) = 0
         enddo
      enddo
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
        call uvrdvrr(lIn,'inttime',inttime,0.0)
        call uvgetvri(lIn,'nschan',nschan,nspect)
        call uvgetvri(lIn,'ischan',ischan,nspect)
        call uvprobvr(lIn,'bfmask',vartype,varlen,updated)
        if (updated) then
           mrepeat = varlen.ne.nspect
           if (mrepeat.or.doone) then
              call uvrdvri(lIn,'bfmask',bfmask,0)
              do j=2,nspect
                 bfmask(j) = bfmask(1)
              enddo
           else
              call uvgetvri(lIn,'bfmask',bfmask,nspect)
           endif
           if (doall) then
              write(fmt1,'(a,i2,a)') '(i6,',nspect,'(1x,z8))'
              write(*,fmt1) nvis, (bfmask(j),j=1,nspect)
           endif
           write(bfmaska,'(z8)') bfmask(1)
c              convert each bfmask(j) into a mask array, and a list for debug
           do j=1,nspect
              call getmaski(bfmask(j),mask2)
              call m2l(MAXBIT-1,mask2,n2,list2)
              call maskop(MAXBIT-1,mask1,mask2,oper,mask3)
              call m2l(MAXBIT-1,mask3,n3,list3)
              mflag(j) = ismasked(MAXBIT-1,mask3)
              if (newflag) mflag(j) = .NOT.mflag(j)
              if (debug .and. j.eq.1) then
                 write(*,*) date,inttime,source,ant1,ant2,bfmaska,
     *                varlen,
     *                (list2(i),i=1,n2),
     *                mflag(j),
     *                (list3(i),i=1,n3)
              endif
           enddo
           varflag = mflag(1)
        endif
        if (dostats) then
           do j=1,nspect
              call getmaski(bfmask(j),mask2)
              do i=1,MAXBIT
                 if (mask2(i).gt.0) counts(i,1) = counts(i,1) + 1
              enddo
           enddo
        else if (doastats) then
           amask(ant1) = 1
           amask(ant2) = 1
           do j=1,nspect
              call getmaski(bfmask(j),mask2)
              do i=1,MAXBIT
                 if (mask2(i).gt.0) then
                    counts(i,ant1) = counts(i,ant1) + 1
                    counts(i,ant2) = counts(i,ant2) + 1
                 endif
              enddo
              do i=1,MAXANT
                 counts(MAXBIT+1,i) = counts(MAXBIT+1,i) + 1
              enddo
           enddo
        endif
        if (varflag) nvisflag = nvisflag + 1
        do j=1,nspect
           if (mflag(j)) nwinflag = nwinflag + 1
        enddo

c
c  Flag or Unflag the data, if requested
c
        if (doflag) then
           call uvxflag(lIn, flags, nread, dowide, newflag,
     *          nspect, nschan, ischan, mflag,
     *          nflag, nwflag, doswap)
	endif

c
c  Loop the loop (get next record, if it exists)
c
        call uvread(lIn, preamble, data, flags, maxchan, nread)
	nvis = nvis + 1
        nwin = nwin + nspect
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

      if (dostats .or. doastats) then
         if (doastats) then
            call m2l(MAXANT,amask,na,alist)
         else
            alist(1) = 0
         endif
         call blfmask(lIn,MAXBIT+1,na,counts,alist)
      else
         write(line,'(a,i9,1x,a,i9)') '# flagged records= ', 
     *      nvisflag,'/',nvis
         call LogWrit(line)
         write(line,'(a,i9,1x,a,i9)') '# flagged windows= ', 
     *      nwinflag,'/',nwin
         call LogWrit(line)

         if (doflag) then
            write(line,'(i10,a)') nflag,  ' channels currently flagged'
            call LogWrit(line)
            write(line,'(i10,a)') nwflag, ' wideband currently flagged'
            call LogWrit(line)
         endif
         if(nvar.gt.0)then
            call LogWrit(' nvar > 0 ')
            call LogWrit(line)
         endif
      endif
      call LogClose
c
      if (doflag) then
         call hisclose (lIn)
      endif
      call uvclose (lIn)
      end
c********1*********2*********3*********4*********5*********6*********7*c
      subroutine uvxflag(lIn, flags, nread, dowide, newflag,
     *              nspect, nschan, ischan, mflag,
     *              nflag, nwflag, doswap)
      implicit none
      integer lIn, nread, nflag, nwflag
      integer nspect, nschan(nspect), ischan(nspect)
      logical mflag(nspect)
      logical flags(nread), newflag, dowide, doswap
c--
      include 'maxdim.h'
      complex wdata(MAXWIDE)
      logical wflags(MAXWIDE)
      integer nwread, i,j

      if (doswap) then
         do j=1,nspect
            do i=ischan(j),ischan(j)+nschan(j)
               flags(i) = .NOT.flags(i)
            enddo
         enddo
c         write(*,*)
      else
         do j=1,nspect
            if (mflag(j)) then
               do i=ischan(j),ischan(j)+nschan(j)
                  flags(i) = newflag
               enddo
               nflag = nflag + nschan(j)
            endif
         enddo
      endif
      call uvflgwr(lIn,flags)

      if (dowide) then
         call uvwread(lIn,wdata,wflags,MAXWIDE,nwread)
         if (doswap) then
            do i=1,nwread
               wflags(i) = .NOT.wflags(i) 
            enddo
         else
            do i=1,nwread
               if (mflag(i)) then
                  wflags(i) = newflag
                  nwflag = nwflag + nwread
               endif
            enddo
         endif
         call uvwflgwr(lIn,wflags)
      endif

      end
c********1*********2*********3*********4*********5*********6*********7**
        subroutine GetOpt(debug,doblfmask,doswap,doall,doone,dostats,
     *                    doastats)
c
        implicit none
        logical debug,doblfmask,doswap,doall,doone,dostats,doastats
c
c  Get extra processing options.
c------------------------------------------------------------------------
        integer nopts
        parameter(nopts=7)
        logical present(nopts)
        character opts(nopts)*8
        data opts/'debug   ','blfmask ','swap    ','all     ',
     *            'one     ','stats   ','astats  '/
c
        call options('options',opts,present,nopts)
        debug     = present(1)
        doblfmask = present(2)
        doswap    = present(3)
        doall     = present(4)
        doone     = present(5)
        dostats   = present(6)
        doastats  = present(7)
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

      if (nl.eq.1 .and. l(1).eq.0) then
         call bug('i','Turning full list on')
         do i=1,n
            masks(i) = i
         enddo
         return
      else
         do i=1,n
            masks(i) = 0
         enddo
      endif
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
      else if (oper.eq.'not' .or. oper.eq.'NOT') then
         do i=1,n
            if (mask1(i).eq.0) then
               mask3(i) = 1
            else
               mask3(i) = 0
            endif
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
c-----------------------------------------------------------------------
      subroutine fbackup(lin)
      integer lin
c
      call bug('i','no backup of flags and wflags yet')
      end
c-----------------------------------------------------------------------
      subroutine blfmask(lin, nc, na, counts, alist)
      integer lin, nc, na, counts(nc,na), alist(na)
c
      integer item,iostat,n
      logical eof,doastats
      character line*256,name*80,fmt*64
      integer i,k
c extern
      integer len1

      doastats  = alist(1).ne.0
      
      call haccess(lin,item,'blfmask','read',iostat)
      if (iostat.ne.0) then
         call bug('w','Error opening blfmask')
         return
      endif
      if (nc.ne.0 .and. doastats) then
         write(fmt,'(''(a,'',i3,''(i3,5x))'')') na
c         write(*,*) 'FMT: ',fmt
         write(line,fmt) 'BIT\ANT',(alist(k),k=1,na)
         call LogWrit(line(1:len1(line)))
      endif
      eof = .FALSE.
      n = 0
      do while(.not.eof)
         call hreada(item,name,eof)
         if (.not.eof) then
            n = n + 1
            if (nc.eq.0) then
               write(line,'(i2,1x,a)')n,name(1:len1(name))
            else if (doastats) then
               write(fmt,'(''(i2,1x,'',i3,''i8,2x,a)'')') na
c               write(*,*) 'FMT=',fmt(1:len1(fmt)),' NA=',na
c               write(line,'(i2,1x,13i12,2x,a)') n, (counts(n,k),k=1,na),
               write(line,fmt) n, (counts(n,alist(k)),k=1,na),
     *                                       name(1:len1(name))
            else
               write(line,'(i2,1x,i12,2x,a)')n,counts(n,1),
     *                                       name(1:len1(name))
            endif
            call LogWrit(line(1:len1(line)))
         endif
      end do
      if (nc.gt.0) then
         n = nc
         write(line,fmt) -1, (counts(n,alist(k)),k=1,na),'-- TOTAL --'
         call LogWrit(line(1:len1(line)))
      endif
      call hdaccess(item,iostat)
      if (iostat.ne.0) call bug('f','Error closing blfmask')
      end

