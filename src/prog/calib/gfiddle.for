c***********************************************************************
      PROGRAM gfiddle
      IMPLICIT NONE
c-----------------------------------------------------------------------
c
c  History:
c    pjt   8jan92   Initial coding finished
c    pjt    aug92   Various improvements
c    pjt    jan93   Final adjustments for BIMA submission
c    pjt    apr93   fixing numerous bugs and other program enhancements
c << mjs  25jan93   Removed unused vars to eliminate spurious warnings. >>
c << mjs  13mar93   pgplot subr names have less than 7 chars.           >>
c    pjt  12jul93   merged two versions plus guaranteed usage of all variables
c    pjt  13sep93   fixed up some labels, attempt to supply unwrapper
c    pjt  10nov93   check file existance and set 'nosave' color; 
c         13dec93   fixed time offset bug in loadap() and fitpol() [lspoly]
c          3may94   bug('f' when output file exists)
c    pjt  15mar95   fixed char*(*) catenation problem 
c     jm  16oct95   Substantial modification to entire program.
c                   Fixed UT by adding 0.5 day correction.  The program
c                   does not write an output file if quit selected.
c                   Data used in fits are now phased unwrapped.  Added
c                   dsb option and automatic break points for source
c                   and focus changes.  A lot of code cleaning too.
c     jm  26oct95   Fixed a bug so that fits do not happen unless the
c                   cursor is in a valid window.
c     jm  02nov95   Added history file entries to let the user know
c                   when something has changed in the file.  Batch mode
c                   now exits rather than quits at the end.
c     jm  10nov95   Fixed source identification routine so that repeated
c                   sources do not generate a new id.  Also corrected
c                   info section so it returns the x/y value of the
c                   nearest point rather than the cursor position.
c     jm  28nov95   Fixed Info so proper (good) item is returned if
c                   some data are flagged bad.
c     jm  04apr96   Modified so empty windows are not displayed.  This
c                   only happens on the last page and when there are not
c                   an integer number of baselines (relative to nxy).
c                   Also modified loadxy so negative requests still
c                   do the entire slot range but ignore the flag value.
c     jm  10feb97   Modified auto-scaling so only good phase values are
c                   unwrapped; flagged phases pass through unwrapped.
c                   No change to the way amplitudes are handled.
c                   Modified fit drawing subroutine so phases are not
c                   unwrapped.  This should not be necessary(?).
c                   Corrected the way the fit index range is determined
c                   permitting npts=0 as a return.
c   pjt   21may97   option to disable setting breakpoints upon reading
c   pjt    1apr99   (not a joke) split off gsubs for g77, fixed EQ -> EQV
c		    all for a picky g77 compiler
c   pjt   19jun99   logging events for optional batch replay
c   pjt   28jul99   add fit residuals etc. to output history
c   pjt   31jul98   fix bug in non-interactive devices
c		    WORKING ON: more history logging
c
c
c= gfiddle - Fiddle with a (gain) visibility dataset
c& pjt
c: calibration
c+
c     GFIDDLE is a MIRIAD task that allows interactive and batch
c     processing of a gain visibility dataset (created by GMAKE).
c     It can also modify the flags of a regular visibility dataset
c     but adding breakpoints and fits has no meaning for them.
c     Also see UVWIDE on how to feedback wide band flags to narrow
c     band flags.
c
c     You can actually fiddle with *any* visibility dataset, so the
c     units could be K, Jy, Jy/K, or sqrt(Jy/K), depending on the
c     origin of the dataset, although the reported units may not
c     always come out as you think.
c
c     Gains can be either antenna based or baseline based.
c
c     By default, the single sideband data are displayed.  One can
c     optionally run in double sideband mode (i.e. phase differences
c     and amplitude ratios) by using the dsb option (see below).
c     GMAKE, when run to compute the double sideband solution, puts
c     the single sideband solutions (ssb) in the first two wide
c     channels and the double sideband solutions (dsb) in the third
c     and fourth channels.  If the dsb solutions are not present
c     and dsb mode is still requested, then then ssb data will be
c     used to compute the dsb data.
c
c     Commands in cursor mode are:
c
c         d   -- delete the nearest point (i.e. flag bad).
c         a   -- add the nearest deleted point (i.e. flag good).
c         x   -- zoom/unzoom toggle on the current column.
c         y   -- zoom/unzoom toggle on the current row.
c         z   -- zoom/unzoom toggle on the current plot.
c	  b   -- insert a breakpoint.
c	  c   -- delete the nearest breakpoint.
c         m   -- switch between DSB/SSB mode (see note with ssb option below).
c         0-9 -- order of the polynomial fit/number of spline nodes.
c	  t   -- toggle between polynomial and cubic spline fits.
c         f   -- two-point fit (simple linear interpolation).
c         l   -- toggle between single/all baselines (see link option below).
c         i   -- info on the nearest (good) data point.
c         r   -- redraw the screen (also rescales the axes).
c         +   -- advance to the next page (if multiple pages).
c         -   -- backup to the previous page (if multiple pages).
c         <>  -- shift left (right) one panel (only in zoom mode).
c         v^  -- shift down (up) one panel (only in zoom mode).
c         ?,h -- this help.
c         q   -- quit (no saving).
c         e   -- exit (save flags, breakpoints, and fits, if modified).
c	  .      Toggle DEBUG mode.
c
c     NOTE: there is no confirmation on 'q' or 'e'.
c
c@ vis
c     Name of the input uv dataset.  There is no default and a
c     dataset must be supplied.
c@ line
c     The line to be selected. Default: wide,2
c     There can only be one or two channels selected; all others cause
c     the program to terminate with a warning.  Also, any other valid
c     option but the default will be permitted, but warned about.
c  ** Note that this will also affect changed flags, breakpoints, and
c     what is written to the optional output dataset.
c     This keyword is usually omitted by the user.
c@ select
c     UV dataselection. Default: all
c  ** Note that this will also affect changed flags, breakpoints and
c     what is written to the optional output dataset.
c     This keyword is usually omitted by the user.
c@ device
c     PGPLOT graphics device name. If none is supplied or the device
c     selected does not have an interactive cursor, then the program
c     will run in batch mode (i.e. no cursor interaction).  The default
c     device is /null (batch mode).
c@batch
c     Name of a batch file in which interactive (if the PGPLOT device
c     supports it) commands can be stored. By default commands are appended
c     to the file, but with 'options=new' this behavior can be changed.
c     Be careful when you re-apply batch files with commands that have a 
c     cumulative action (flags, breaks etc.)
c@ nxy
c     The maximum number of plots per page in the x direction.  The
c     number of plots in the y direction is controlled by the program.
c     Be careful if you use this keyword with batch= since they must
c     be consistent accross calls.
c     The default is 3 plots in the x direction. 
c@ fit
c     This keyword provides a way for the user to apply an initial fit
c     to the data.  The arguments to this keyword determines what kind
c     of initial fit will be applied (and possible optional parameters).
c     Valid options are:
c       poly,<amp_poly_order>,<phase_poly_order>
c       2pt
c       spline,<#_of_spline_nodes>
c     The amp and phase polynomial orders must be in the range [0, 9].
c     Omitting the phase polynomial order defaults to order 2; omitting
c     the amplitude order defaults to order 0.
c     The number of spline nodes must be in the range [0, 9] (the
c     actual number of spline nodes is one larger).  The default for the
c     spline fit argument is 0 (i.e. 1 node).  The 2pt fit simply
c     connects the dots; there are no additional parameters to this fit.
c     By default, no initial fit is applied.  However, the fit values
c     are initialized to 1 for amplitudes and 0 for phases.
c@ sample
c     Output sample time in minutes.  It is adviced to set the sampling 
c     time finer than the typical intervals in the input file.
c     The default is 1 minute.
c@ clip
c     Automatically clips all amplitudes larger than this value.
c     The default is to perform no clipping.
c@ options
c     Additional processing options. Multiple options, if compatible,
c     can be given, separated by commas.
c     link      While flagging points, this option applies the change
c               to the corresponding points on other baselines.
c               Similarly, with breakpoints.  Note that unflagging and
c               clearing of breakpoints cannot be done in this mode.
c               The interactive counterpart (key l) allows the user to
c               switch this mode interactively.
c     nowrap    Do not attempt to unwrap phases.
c     sources   If no break point information is present in the input
c               uv dataset, the program will automatically set break
c               points.  Focus changes always create a break point.
c               Source name changes will also create a break point
c               but only if this option is used.
c     nobreak   Do not set breakpoint on reading the data. By default
c               it will.
c     dsb       By default, the single sideband data are displayed.
c               If this option is present, then the plots and fits will
c               be done in double sideband mode (i.e. phase differences
c               and amplitude ratios).  Note that this option controls
c               which of the windows permits editing.  The interactive
c               counterpart (key m) permits viewing of the other window,
c               but no editing.
c     new       In batch mode an existing batch file will normally be
c               processed in a special append mode: first the existing
c               commands are read and applied, then new commands will
c               be added to the batch file. options=new will overwrite
c               the batch file and start from scratch.
c     debug     Debugging mode.  A lot of output to aid in providing
c               the programmer with relevant info. The '.' command
c               can be used as a debug toggle in interactive mode.
c@ ampmax
c     If supplied, the amplitude scale is fixed from 0 to ampmax;
c     otherwise auto-scaling is done.
c     The default is to auto-scale the amplitudes.
c@ phminmax
c     Range in phases to be displayed.  If supplied, two values (in
c     units of degrees) are needed.  If only one value is supplied,
c     the second value will be the negative of the first.
c     The default is to auto-scale the phases.
c@ phase
c     List of (antenna,{U|L},phase_slope/hour) 3-tuples that
c     are used as an estimate for unwrapping the phases.  When low
c     signal/noise data have large phase drifts, the automatic phase
c     unwrapper may not be sufficient to unwrap the phase.  This
c     parameter is an attempt to give the user some automated way to
c     experiment with unwrapping phases.  Phases are given in degrees;
c     Antenna is an integer; and U/L is given as 1/2 (for upper or
c     lower sideband).
c     Default: not used.
c@ batch
c     Name of batch file to be used for input or output.
c     Default: not used.
c@ out
c     The name of the output UV dataset. The default is to NOT write
c     out (and, hence, not save) the derived fits.
c
c     COLORS:
c     If the graphic device selected is capable of drawing with various
c     colors, then the following list will identify their meanings:
c       BLUE:
c         Fits drawn in blue indicate that no output uv dataset
c         name was provided.
c       GREEN:
c         If a valid output dataset is provided, then new fits
c         will be drawn in green.
c       YELLOW:
c         Yellow fits identify windows in which the fit is old
c         for some reason.  A new fit should be generated.
c--
c  ******  MORE OPTIONS TO COME  ??? ******
c
c     append    In batch mode this means an existing logfile will
c               be appended to. By default an existing logfile will be
c               overwritten. It also means it will first apply the 
c               commands found in the batch file
c             (DEPRECATED, SINCE OPTIONS=NEW DOES THE REVERSE OF THIS)
c     accum     In batch mode this means all recording information is
c               applied again. Normally this is not a good idea since
c               commands like flagging and breakpoints will use the
c               nearest point and thus depend on the order of events.
c     history   extra history in out= file, stores the fit residuals/sigma
c     
c TODO: 
c  fix when device= is forgotten, it goes into infinite loop
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      INTEGER MAXWINS,MAXBAD,MAXX,MAXY,MAXSELS
      CHARACTER VERSION*(*)
      PARAMETER(VERSION='GFIDDLE: Version 1-aug-99 PJT')
      PARAMETER(MAXWINS=16,MAXBAD=20,MAXX=15,MAXY=4,MAXSELS=256)

      CHARACTER visi*80, viso*80, device*80, chr*1, ltype*20, fmethod*10
      CHARACTER batch*80, mesg*80
      CHARACTER glabel*128
      CHARACTER xlabel(MAXX*MAXY)*20, ylabel(MAXX*MAXY)*20
      INTEGER i, ix, iy, mx, xlo, xhi, ylo, yhi, aorder, porder
      INTEGER npage, order, npts, nchan, tno, tnohis, maxwides
      INTEGER fitmode
      INTEGER idx(MAXTIME)
      REAL phzmin, phzmax
      REAL defsize, chsize
      REAL clip, xpos, ypos, dist, ampmax
      REAL lstart, lwidth, lstep
      REAL x(MAXTIME),y(MAXTIME)
      REAL sels(MAXSELS)
      LOGICAL dobreak, dobreaks, dosrcbrk, canedit, bexist
      LOGICAL dobatch, dodsb, fexist, doinit, doappend, donew
      LOGICAL more1, more2, more3, xzoom, yzoom, first, fmode
      LOGICAL fixamp, fixphaz
c
c  Externals
c
      CHARACTER*13 dangle
      INTEGER len1, pgbeg
      LOGICAL keyprsnt, hexists
      EXTERNAL plotwin
c-----------------------------------------------------------------------
c  Announce the program
c
      CALL output(VERSION)
      CALL bug('i','Note: new version with batch= capabilities')
c
c  Get user inputs
c
      CALL keyini
      CALL keyf('vis',visi,' ')
      CALL selinput('select',sels,MAXSELS)
      CALL keya('line',ltype,'wide')
      CALL keyi('line',nchan,2)
      CALL keyr('line',lstart,1.)
      CALL keyr('line',lwidth,1.)
      CALL keyr('line',lstep,lwidth)
      CALL keya('device',device,'/null')
      CALL keyf('batch',batch,' ')
      CALL keyf('out',viso,' ')
      CALL keyi('nxy',nx,3)
      CALL keyd('sample',sample,1.0d0)
      CALL getopt(debug,dolink,dowrap,dosrcbrk,dodsb,dobreak,
     *            doappend,donew)
      CALL getphase('phase')
      CALL keyr('clip',clip,-1.0)
      fixamp = keyprsnt('ampmax')
      IF(fixamp) THEN 
         CALL keyr('ampmax',ampmax,-1.0)
      ENDIF
      fixphaz = keyprsnt('phminmax')
      if (fixphaz) then 
        call keyr('phminmax', phzmin, -180.0)
        call keyr('phminmax', phzmax, -phzmin)
      endif
      doinit = keyprsnt('fit')
      IF (doinit) THEN
         CALL keya('fit',fmethod,'poly')
         CALL keyi('fit',aorder,0)
         CALL keyi('fit',porder,2)
      ENDIF
      CALL keyfin
c
c  Check user inputs and convert to internal units where needed
c
      CALL assertf(visi,.TRUE.,
     *            'Input dataset does not exist; vis='//visi)
      IF(viso.EQ.' ') THEN
         CALL bug('i', 'No output dataset given; (out=)')
         fcolor = CNoSaveF
         tnohis = -1
      ELSE
         INQUIRE(FILE=viso(1:len1(viso)),EXIST=fexist)
         IF (fexist) THEN
            CALL bug('f',
     *         'Output file (out='// viso(1:len1(viso)) // ') exists')
            fcolor = CNoSaveF
         ELSE
            fcolor = CSaveF
         ENDIF
         CALL uvopen(tnohis,viso(1:len1(viso))//'.his','new')
         CALL hisopen(tnohis, 'write')
         CALL hiswrite(tnohis,'Hello world - testing history logging')
      ENDIF 
c
c  Check the line items.  Permit non-standard items but warn the user.
c  That said, only allow nchan to be 1 or 2.  A constraint of window.
c
      CALL lcase(ltype)
      IF (ltype .ne. 'wide')
     *  call bug('w', 'A line type other than wide is non-standard.')
      IF ((nchan .ne. 1) .and. (nchan .ne. 2))
     *  call bug('f', 'Please use 1 or 2 channels for line= keyword.')
c
      CALL assertl(sample.GT.0.0,'Sample time must be > 0; sample=')
      sample = sample / (24.0 * 60.0)
      IF(fixamp) CALL assertl(ampmax.GT.0.0,'ampmax= must be positive')
      if (fixphaz) call assertl(phzmax .ne. phzmin,
     *  'phase range must be larger than 0 degrees; phminmax=')
c
      CALL assertl(nx.GT.0, 'The value for nxy= must be positive.')
      CALL assertl(nx.LE.MAXX,
     *  'Too many plots in the X direction for a useful page.')
c
      if (fixphaz .and. (phzmax .lt. phzmin)) then
        dist = phzmin
        phzmin = phzmax
        phzmax = dist
      endif
c
c  Set the sideband mode (sbmode).  There are currently 5 modes
c  possible.  sbmode=0 is for single channel mode; sbmode=1 is ssb mode
c  from the first 2 wide channels; sbmode=2, is also ssb mode but is
c  generated from the original dsb data; sbmode=3 is dsb mode where the
c  dsb values are computed from the original ssb inputs; and sbmode=4
c  is dsb mode where the dsb values are input as wide channels 3/4.
c  Modes 0/1/2 are mutually exclusive of 3/4.
c
      ny = 4
      if (nchan .eq. 1) then
        sbmode = 0
        ny = 2
        if (dodsb) call bug('f',
     *    'Double sideband mode not permitted with this line type.')
      else if (dodsb) then
        sbmode = 3
      else
        sbmode = 1
      endif
c
      canedit = .TRUE.
      breakmod = .FALSE.
      flagmod = .FALSE.
      ipage = 1
c
c  Open the visibility dataset.  Check to see how many wide channels
c  are present.  If there are four, try to get the dsb wide values
c  read rather then having to compute them.  The ssb wide values
c  will be in channels 1,2 and the dsb will be in 3,4.
c  --> Unfortunately, this is very specific to gmake/gfiddle!! <--
c
      CALL uvopen(tno,visi,'old')
      CALL uvnext(tno)
      CALL uvrdvri(tno, 'nwide', maxwides, 0)
      CALL uvrdvra(tno, 'gmode', glabel, ' ')
      CALL uvrewind(tno)
      i = len1(glabel)
      call lcase(glabel(1:i))
      if ((sbmode .gt. 0) .and. (ltype .eq. 'wide') .and.
     *    (nchan .eq. 2) .and. (lstart .eq. 1) .and.
     *    (maxwides .eq. 4) .and. (glabel(1:i) .eq. 'dsb')) then
        lstart = 3
        sbmode = sbmode + 1
      endif
      if (maxwides .eq. 2) then
        if ((sbmode .eq. 2) .or. (sbmode .eq. 4)) sbmode = sbmode - 1
      endif
      if (sbmode .eq. 2) then
        call bug('i', 'SSB values will be generated from DSB data.')
      else if (sbmode .eq. 3) then
        call bug('i', 'DSB values will be generated from SSB data.')
      endif
c
      CALL uvset(tno,'data',ltype,nchan,lstart,lwidth,lstep)
      CALL SelApply(tno,sels,.TRUE.)
      dobreaks = .not. hexists(tno, 'nbreaks')
      IF (.NOT.dobreak) dobreaks = .FALSE.
c
c  Read the visibility dataset in memory.  If no (previous)
c  breakpoints are available, then source changes and focus changes
c  will set them.
c
      CALL visread(tno, visi, clip, dobreaks, dosrcbrk)

c
c  Read the (previous) breakpoints, if present.
c
      IF (.NOT. dobreaks) CALL brread(tno, visi, nbl, day0)

c
c  Graphics interaction loop (in batch mode this is simply executed once)
c
      IF(pgbeg(0, device, 1, 1).NE.1)THEN
         CALL pgldev
         CALL bug('f', 'Opening graphics device')
      ENDIF
c
      defsize = 1.0
      CALL pgsch(defsize)
      CALL pgqinf('CURSOR', chr, i)
      dobatch = ((chr .eq. 'n') .or. (chr .eq. 'N'))
      IF (dobatch)
     *   CALL bug('i', 'This graphics device only works in batch mode.')

c
c  Open logging;
c     note that the miriad append mode means you really can only write,
c     and not read.... is that a braindead implementation??????
c     so, old='r'
c         new='w'
c         append='a'
c
      INQUIRE(FILE=batch(1:len1(batch)),EXIST=bexist)
      IF(donew) THEN
         write(*,*) 'Overriding : this is going to be a NEW file'
         bexist = .FALSE.
      ENDIF
      IF(bexist)THEN
         write(*,*) 'Opening in old mode'
         CALL logcuro(batch,'old')
      ELSE
         write(*,*) 'Opening in new mode'
         CALL logcuro(batch,'new')
      ENDIF
c
      npage = (nbl-1)/nx + 1
      if ((npage .eq. 1) .and. (nx .gt. nbl)) nx = nbl
      IF(npage.GT.1 .AND. .NOT.dobatch) THEN
         WRITE(mesg, *) '*** NOTE: There are ', npage, ' pages'
         CALL output(mesg)
         CALL output('*** Use + and - to advance/backup a page')
      ENDIF
c
c  Initialize the fits for each window, if necessary.
c
      call lcase(fmethod)
      if (doinit) call initfits(npage, fmethod, aorder, porder)
      fitmode = 1
      if (fmethod(1:1) .eq. 's') fitmode = 2
      ipage = 1
c
c Set the WIN routines for a matrix of NX by NY windows
c
      CALL winset(nx,ny)
c
c Three nested 'infinite loops', controlled by 3 logicals (more1..3):
c This contraption came out of trying to avoid the use of GOTOs
c     1) total recompute, using current value of ipage (1..npage)
c     2) redraw current (zoomed) image (also autoscales the axes)
c     3) get new cursor input, no redraw done.
c
      first = .TRUE.
      more1 = .TRUE.
      DOWHILE(more1)
         IF(debug)CALL output('MORE1>')
         mx = nx
         if (ipage .eq. npage) mx = nbl - ((npage - 1) * nx)
         DO iy=1,ny
            DO ix=1,mx
               CALL winpick1(ix,iy)
c
c  When auto-scaling phases, only unwrap the unflagged data.
c  Otherwise, large phase jumps are possible and data not displayed.
c
               if ((mod(iy, 2) .eq. 0) .and. dowrap) then
                 CALL loadxy(MAXTIME,i,x,y,ix,iy,idx,.TRUE.,0)
                 call unwrap(dowrap, i, y)
                 CALL loadxy(MAXTIME-i,npts,x(i),y(i),ix,iy,idx(i),
     *             .FALSE.,0)
                 npts = npts + i
               else
                 CALL loadxy(MAXTIME,npts,x,y,ix,iy,idx,.TRUE.,-1)
               endif
               call winsize(npts, x, y)
               if (fixphaz .and. (mod(iy, 2) .eq. 0))
     *           call winscaly(phzmin, phzmax)
               if (fixamp .and. (mod(iy, 2) .eq. 1)) then
                 if (sbmode .le. 2) then
                   call winscaly(0.0, ampmax)
                 else
                   if (iy .ne. 1) then
                     call winscaly(0.0, ampmax)
                   endif
                 endif
               endif
            ENDDO
         ENDDO
         DO iy=1,ny
            CALL winpick(1,mx,iy,iy)
            CALL winnorm(0.1)
         ENDDO
         CALL setlabel((MAXX*MAXY), xlabel, ylabel)
         WRITE(glabel,'(A,A,A,I2,A,I2)') 'File: ', visi(1:len1(visi)),
     *                      ' Page ',ipage,'/',npage
         if (debug) CALL output(glabel)
         IF(first)THEN
            xlo = 1
            xhi = mx
            ylo = 1
            yhi = ny
            xzoom = .FALSE.
            yzoom = .FALSE.
            first = .FALSE.
         ENDIF
         more2 = .TRUE.
         DOWHILE(more2)
            IF(debug)CALL output('MORE2>')
            CALL winpick(xlo,xhi,ylo,yhi)
            if ((xlo .eq. xhi) .and. (ylo .eq. yhi)) then
              chsize = 1.3 * defsize
            else if (ylo .eq. yhi) then
              chsize = 1.2 * defsize
            else if (xlo .eq. xhi) then
              chsize = 1.1 * defsize
            else
              chsize = defsize
            endif
            call pgsch(chsize)
            CALL wintshow(xlabel,ylabel,glabel,plotwin,86400.0)
            more3 = .TRUE.
            DOWHILE(more3)
               IF(debug)CALL output('MORE3>')
               IF(bexist) THEN
                  CALL logcurr(ix,iy,xpos,ypos,chr)
c                  WRITE(*,*) 'BATCURS: ',ix,iy,xpos,ypos,' : ',chr
c                        skip over end/quit commands
                  IF(chr.EQ.'e' .OR. chr.EQ.'q') chr = ' '
c                        at end of reading, in append mode, switch to writing
                  IF(chr.EQ.char(0) .AND. .NOT.donew) THEN
                     bexist = .FALSE.
                     chr = '?'
                     chr = 'r'
                     write(*,*) 'Re-Opening in append mode'
                     CALL logcurc
                     IF(dobatch) THEN
                        chr = 'e'
                     ELSE
                        CALL logcuro(batch,'append')
                     ENDIF
                  ENDIF
               ELSE
                  IF(dobatch)THEN
                     IF(ipage.lt.npage)THEN
                        chr = '+'
                     ELSE
                        chr = 'e'
                     ENDIF
                  ELSE
                     CALL wincurs(ix,iy,xpos,ypos,chr)
                     CALL logcurw(ix,iy,xpos,ypos,chr)
c                    WRITE(*,*) 'WINCURS: ',ix,iy,xpos,ypos,' : ',chr
                  ENDIF
               ENDIF
c                                                           Switch to action
               IF (((ix .lt. 1) .or. (iy .lt. 1)) .and.
     *              (index('.?hrqelmt', chr) .eq. 0)) THEN
                  IF (debug) THEN
                    write(mesg, *) 'Cursor @ ', xpos, ypos
                    call output(mesg)
                  ENDIF
                  IF (xpos.LT.0.1 .AND. ypos.LT.0.1) THEN
                    chr = '-'
                  ELSE IF (xpos.GT.0.9 .AND. ypos.GT.0.9) THEN
                    chr = '+'
                  ELSE IF (xpos.LT.0.1) THEN
                    chr = '<'
                    if (xlo .ne. xhi) chr = '-'
                  ELSE IF (xpos.GT.0.9) THEN
                    chr = '>'
                    if (xlo .ne. xhi) chr = '+'
                  ELSE IF (ypos.LT.0.1) THEN
                    chr = 'v'
                    if (ylo .ne. yhi) chr = '-'
                  ELSE IF (ypos.GT.0.9) THEN
                    chr = '^'
                    if (ylo .ne. yhi) chr = '+'
                  ELSE
                    CALL bug('w',
     *                'Illegal position; cursor not in a sub-window')
                    chr = CHAR(0)
                  ENDIF
               ENDIF
c								Null cmd
               IF (chr .EQ. char(0)) THEN
                  CONTINUE
c								Help
               ELSE IF(chr.EQ.'?' .OR. chr.EQ.'h') THEN
                  CALL help(debug,canedit,dolink,(fitmode.eq.1),sbmode)
c 								Toggle debug
               ELSE IF(chr.EQ.'.') THEN
                  debug = .NOT.debug
                  IF(debug)THEN
                     CALL output('DEBUG mode is now ON')
                     write(mesg, *) '* Page: ', ipage, ' Window ix,iy=',
     *                 ix, iy
                     call output(mesg)
                     write(mesg, *) '* Xlo,Xhi = ', xlo, xhi,
     *                 ' Ylo,Yhi = ', ylo, yhi
                     call output(mesg)
                     write(mesg, *) '* X,Y Zoom = ', xzoom, yzoom
                     call output(mesg)
                  ELSE
                     CALL output('DEBUG mode is now OFF')
                  ENDIF
c								Redraw Screen
               ELSE IF(chr.EQ.'r') THEN
                  more2 = .FALSE.
                  more3 = .FALSE.
c								Toggle link
               ELSE IF(chr.EQ.'l') THEN
                  dolink = .NOT. dolink
                  i = len1(abmode)
                  IF(dolink)THEN
                     mesg = 'Keys d and b now affect all ' //
     *                 abmode(1:i) // 's.'
                  ELSE
                     mesg = 'Keys d and b only affect one ' //
     *                 abmode(1:i) // '.'
                  ENDIF
                  call output(mesg)
c								Quit/Exit
               ELSE IF(chr.EQ.'q' .OR. chr.EQ.'e') THEN
                  more1 = .FALSE.
                  more2 = .FALSE.
                  more3 = .FALSE.
                  IF(chr.EQ.'q')THEN
                     CALL output('Quitting; nothing saved.')
                     breakmod = .FALSE.
                     flagmod = .FALSE.
                  ELSE
                     CALL output('Exiting; saving what needs be saved.')
                  ENDIF
c								Edit point
               ELSE IF(chr.EQ.'d' .OR. chr.EQ.'a') THEN
                 if (canedit) then
                   fmode = chr.EQ.'a' 
                   if (debug) then
                     if (fmode) then
                       call output('Undelete (add) a point.')
                     else
                       call output('Delete (flag) a point.')
                     endif
                   endif
                   CALL loadxy(MAXTIME,npts,x,y,ix,iy,idx,.NOT.fmode,0)
                   if ((mod(iy, 2) .eq. 0) .and. (.not. fmode)) then
                     call unwrap(dowrap, npts, y)
                   endif
                   IF(npts.GT.0) THEN
                     CALL winnear(ix,iy,xpos,ypos,npts,x,y,i,dist)
                     IF (i.GT.0) THEN
                       flagmod = .TRUE.
                       i = idx(i)
                       CALL setflag(xpos,i,ix,iy,fmode,xlo,xhi,ylo,yhi)
                     ELSE
                       CALL bug('w', 'Ambiguous position selected.')
                     ENDIF
                   ELSE
                     CALL bug('w', 'No points left in this window.')
                   ENDIF
                 else
                   call bug('w',
     *               'Can not edit points in this sideband mode.')
                 endif
c								Info ?
               ELSE IF(chr.EQ.'i') THEN
                  CALL loadxy(MAXTIME,npts,x,y,ix,iy,idx,.TRUE.,-1)
                  if (mod(iy, 2) .eq. 0) call unwrap(dowrap, npts, y)
                  IF(npts.GT.0) THEN
                     CALL winnear(ix,iy,xpos,ypos,npts,x,y,i,dist)
                     IF (i.GT.0) THEN
                        write(mesg, *) '*** Slot Selected: ', i, idx(i)
                        call output(mesg)
                        if (debug) then
                          write(mesg, *) '*** Raw Cursor ', xpos, ypos
                          call output(mesg)
                        endif
                        xpos = x(i)
                        ypos = y(i)
                        write(mesg, '(A, F6.3)') '*** Time ', xpos
                        i = len1(mesg)
                        mesg(i+1:) = ' [' // dangle(DBLE(xpos * 24.0))
                        i = len1(mesg) + 1
                        if (mod(iy, 2) .eq. 0) then
                          write(mesg(i:), '(A, G12.5)') '] Phase ', ypos
                        else
                          write(mesg(i:), '(A, G12.5)') '] Gain ', ypos
                        endif
                        call output(mesg)
                     ELSE
                        CALL bug('w', 'Ambiguous position selected.')
                     ENDIF
                  ELSE
                     CALL bug('w', 'No unflagged points in this window')
                  ENDIF
c								Breakpoint
               ELSE IF(chr.EQ.'c' .OR. chr.EQ.'b') THEN
                 if (canedit) then
                  breakmod = .TRUE.
                  CALL WinToUsr(ix,iy,xpos,ypos)
                  IF (chr.EQ.'b') THEN
                     if (debug) CALL output('Setting a breakpoint.')
                     call setbreak(xpos, ix, iy, xlo, xhi, ylo, yhi)
                  ELSE
                     if (debug) CALL output('Clearing a breakpoint.')
                     call clrbreak(xpos, ix, iy, xlo, xhi, ylo, yhi)
                  ENDIF
                 else
                   call bug('w',
     *               'Can not edit break points in this sideband mode.')
                 endif
c								X zoom
               ELSE IF(chr.EQ.'x') THEN
                  more3 = .FALSE.
                  if (debug) CALL output('Toggle zoom in X')
                  if (xzoom .and. yzoom) then
                    yzoom = .NOT.yzoom
                  else
                    xzoom = .NOT.xzoom
                  endif
                  IF(xzoom)THEN
                     xlo = ix
                     xhi = ix
                  ELSE
                     xlo = 1
                     xhi = mx
                  ENDIF
                  IF(yzoom)THEN
                     ylo = iy
                     yhi = iy
                  ELSE
                     ylo = 1
                     yhi = ny
                  ENDIF
c								Y zoom
               ELSE IF(chr.EQ.'y') THEN
                  more3 = .FALSE.
                  if (debug) CALL output('Toggle zoom in Y')
                  if (xzoom .and. yzoom) then
                    xzoom = .NOT.xzoom
                  else
                    yzoom = .NOT.yzoom
                  endif
                  IF(xzoom)THEN
                     xlo = ix
                     xhi = ix
                  ELSE
                     xlo = 1
                     xhi = mx
                  ENDIF
                  IF(yzoom)THEN
                     ylo = iy
                     yhi = iy
                  ELSE
                     ylo = 1
                     yhi = ny
                  ENDIF
c								Z zoom
               ELSE IF(chr.EQ.'z') THEN
                  more3 = .FALSE.
                  if (debug) CALL output('Toggle zoom in X and Y')
                  xzoom = .NOT.(xzoom .and. yzoom)
                  yzoom = xzoom
                  IF(xzoom.AND.yzoom)THEN
                     xlo = ix
                     xhi = ix
                     ylo = iy
                     yhi = iy
                  ELSE
                     xlo = 1
                     xhi = mx
                     ylo = 1
                     yhi = ny
                  ENDIF
c                                                               Up & Down
               ELSE IF(chr.EQ.'^' .OR. chr.EQ.'v') THEN
                  IF(ylo.EQ.yhi) THEN
                     IF(chr.EQ.'^' .AND. ylo.LT.ny) THEN
                        more3 = .FALSE.
                        ylo = ylo + 1
                        yhi = yhi + 1
                     ELSE IF (chr.EQ.'v' .AND. ylo.GT.1) THEN
                        more3 = .FALSE.
                        ylo = ylo - 1
                        yhi = yhi - 1
                     ELSE
                        CALL bug('w', 'You hit the edge of the window.')
                     ENDIF
                  ELSE
                     mesg = 'Key ' // chr // ' only works in zoom mode.'
                     CALL bug('w', mesg)
                  ENDIF
c                                                               Left & Right
               ELSE IF(chr.EQ.'<' .OR. chr.EQ.'>') THEN
                  IF(xlo.EQ.xhi) THEN
                     IF(chr.EQ.'>' .AND. xlo.LT.mx) THEN
                        more3 = .FALSE.
                        xlo = xlo + 1
                        xhi = xhi + 1
                     ELSE IF (chr.EQ.'<' .AND. xlo.GT.1) THEN
                        more3 = .FALSE.
                        xlo = xlo - 1
                        xhi = xhi - 1
                     ELSE
                        CALL bug('w', 'You hit the edge of the window.')
                     ENDIF
                  ELSE
                     mesg = 'Key ' // chr // ' only works in zoom mode.'
                     CALL bug('w', mesg)
                  ENDIF
c								New page
               ELSE IF(chr.EQ.'+' .OR. chr.EQ.'-') THEN
                  IF(chr.EQ.'+' .AND. ipage.GE.npage) THEN
                     CALL bug('w','No next page')
                  ELSE IF(chr.EQ.'-' .AND. ipage.LE.1) THEN
                     CALL bug('w','No previous page')
                  ELSE
                     if (debug) then
                       CALL output('Checking out next/previous page')
                     endif
                     IF(chr.EQ.'+') ipage = ipage + 1
                     IF(chr.EQ.'-') ipage = ipage - 1
                     more2 = .FALSE.
                     more3 = .FALSE.
                     first = .TRUE.
                  ENDIF
                  ipage = max(1, min(ipage, npage))
                  IF(debug)WRITE(*,*) '*** New page will be ',ipage
c								switch SB mode
               ELSE IF(chr.EQ.'m') THEN
                 if (sbmode .lt. 1) then
                   call bug('w',
     *               'Switching makes no sense in this single mode.')
                 else
                   if ((sbmode .eq. 1) .or. (sbmode .eq. 2)) then
                     mesg = 'Switching from SSB mode to DSB mode.'
                     sbmode = sbmode + 2
                   else if ((sbmode .eq. 3) .or. (sbmode .eq. 4)) then
                     mesg = 'Switching from DSB mode to SSB mode.'
                     sbmode = sbmode - 2
                   endif
                   canedit = .NOT. canedit
                   i = len1(mesg)
                   if (canedit) then
                     mesg(i+1:) = '  Editing enabled.'
                   else
                     mesg(i+1:) = '  Editing disabled.'
                   endif
                   call output(mesg)
                   more2 = .FALSE.
                   more3 = .FALSE.
                 endif
c                                                               Change fit mode
               ELSE IF(chr.EQ.'t') THEN
                 if (canedit) then
                  if (fitmode .eq. 1) then
                    fitmode = 2
                    call output('Keys 0-9 now fit with Splines.')
                  else
                    if (fitmode .ne. 2) call bug('w',
     *                'Unknown fit mode; forced to Polynomial.')
                    fitmode = 1
                    call output('Keys 0-9 now fit with Polynomials.')
                  endif
                 else
                   call bug('w',
     *               'Fitting not permitted in this sideband mode.')
                 endif
c                                                               two-point fit
               ELSE IF(chr.EQ.'f') THEN
                 if (canedit) then
                  call output('Two point interpolation fit')
                  call wintousr(ix, iy, xpos, ypos)
                  call fitlin(ix, iy, xpos, .TRUE.)
                 else
                   call bug('w',
     *               'Fitting not permitted in this sideband mode.')
                 endif
c                                                               skip
               ELSE IF(chr.EQ.' ') THEN
                  chr = ' '
c                                                               polynomial fit
               ELSE
                  order = INDEX('0123456789',chr) - 1
                  if ((order .ge. 0) .and. (order .le. 9)) then
                    if (canedit) then
                      call wintousr(ix, iy, xpos, ypos)
                      if (fitmode .eq. 1) then
                        call output('Polynomial fit of order '//chr)
                        call fitpol(ix, iy, order, xpos, .TRUE.)
                      else if (fitmode .eq. 2) then
                        call output('Spline fit with '//chr//' nodes.')
                        call fitsplin(ix, iy, order, xpos, .TRUE.)
                      endif
                    else
                      call bug('w',
     *                 'Fitting not permitted in this sideband mode.')
                    endif
                  else
                    call bug('w', chr//' : No such command, try ? or H')
                  endif
               ENDIF
            ENDDO
         ENDDO
      ENDDO
c
c  Write out breakpoints and flags into existing input dataset if
c  there was some reason to... also update history, in such cases.
c
      if (breakmod .or. flagmod) then
        call hisopen(tno, 'append')
        call hiswrite(tno, VERSION)
        call hisinput(tno, 'GFIDDLE')
        if (breakmod) call brwrite(tno, visi(1:len1(visi)))
        if (flagmod) call FlgWrite(tno, visi(1:len1(visi)))
        call hisclose(tno)
      endif
c
c  Write out new sampled fitted vis data
c
      IF ((chr .ne. 'q') .and. (viso .ne. ' ')) THEN
         CALL hisclose(tnohis)
         CALL uvclose(tnohis)
         CALL uvopen(tnohis,viso(1:len1(viso))//'.his','old')
         CALL VisWrite(tno, tnohis, viso, VERSION)
         CALL uvclose(tnohis)              
c         CALL deldat(viso(1:len1(viso))//'.his')
         CALL system('/bin/rm -rf '// viso(1:len1(viso)) // '.his')
      ENDIF
      CALL uvclose(tno)
      CALL logcurc
c
      CALL pgend
      END
c***********************************************************************
      subroutine brread(tvis, visi, nbl, day0)
      implicit none
      character visi*(*)
      integer tvis, nbl
      double precision day0
c
c  Read breakpoints in JDs, but convert them to local time offsets
c  from day0 (as determined from the read visibility data routine).
c  This routine will overwrite all previous entries of the breaks.
c-----------------------------------------------------------------------
      character name*20
      integer tbreak, iostat
      integer i, ix, iy, nb, nbreaks, offset, nbases
      double precision breaks(100)
      logical okay
c
      name = visi
c
      call rdhdi(tvis, 'nbreaks', nbases, 0)
      nbases = min(nbases, nbl)
      if (nbases .eq. 0) return
c
      call haccess(tvis, tbreak, 'breaks', 'read', iostat)
      if (iostat .ne. 0) call mybug(iostat,
     *  'Error opening breaks item in dataset: ' // name)
c
      offset = 8
      do i = 1, nbases
        call hreadi(tbreak, ix, offset, 4, iostat)
        offset = offset + 4
        do iy = 1, 2
          call hreadi(tbreak, nbreaks, offset, 4, iostat)
          offset = offset + 4
          if (iostat .ne. 0) call mybug(iostat,
     *      'Error reading breaks count item in dataset: ' // name)
          if (nbreaks .gt. 0) then
            nb = 8 * nbreaks
            call hreadd(tbreak, breaks, offset, nb, iostat)
            offset = offset + nb
            if (iostat .ne. 0) call mybug(iostat,
     *        'Error reading breaks time item in dataset: ' // name)
            do nb = 1, nbreaks
              breaks(nb) = breaks(nb) - day0
              call brmerge(ix, iy, breaks(nb), .TRUE., okay)
            enddo
          endif
        enddo
      enddo
c
      call hdaccess(tbreak, iostat)
      if (iostat .ne. 0) call mybug(iostat,
     *  'Error closing breaks item in dataset: '// name)
      return
      end
c***********************************************************************
      subroutine brwrite(tvis, visi)
      implicit none
      character visi*(*)
      integer tvis
c
c  Store breakpoints in JD's.
c-----------------------------------------------------------------------
      include 'gfiddle.h'
c
      character mesg*132
      integer tbreak, iostat
      integer ix, iy, nb, offset, nbases
      integer header(2)
c
      logical hexists
c
c  Count the number of breaks to be saved.
c
      nb = 0
      do ix = 1, nbl
        do iy = 1, 2
          nb = nb + nbreak(ix, iy)
        enddo
      enddo
c
c  If all breaks have been cleared, then removed the item.
c
      if (nb .eq. 0) then
        write (mesg, '(A)') 'GFIDDLE: No break points saved.'
        call hiswrite(tvis, mesg)
        if (hexists(tvis, 'breaks')) then
          call hdelete(tvis, 'breaks', iostat)
          mesg = 'Error deleting breaks item in dataset: '// visi
          if (iostat .ne. 0) call mybug(iostat, mesg)
        endif
        if (hexists(tvis, 'nbreaks')) then
          call hdelete(tvis, 'nbreaks', iostat)
          mesg = 'Error deleting nbreaks item in dataset: '// visi
          if (iostat .ne. 0) call mybug(iostat, mesg)
        endif
        return
      endif
c
c  At this point, there are break points that need to be written.
c
      write(mesg,'(A,I3,A,A)') 'GFIDDLE: Writing ', nb, ' break points.'
      call hiswrite(tvis, mesg)
      call haccess(tvis, tbreak, 'breaks', 'write', iostat)
      mesg = 'Error opening breaks item in dataset: ' // visi
      if (iostat .ne. 0) call mybug(iostat, mesg)
      header(1) = 0
      header(2) = 0
      offset = 0
      call hwritei(tbreak, header, offset, 8, iostat)
      mesg = 'Error writing breaks header in dataset: ' // visi
      if (iostat .ne. 0) call mybug(iostat, mesg)
      offset = 8
c
      nbases = 0
      do ix = 1, nbl
        if ((nbreak(ix, 1) .gt. 0) .or. (nbreak(ix, 2) .gt. 0)) then
          nbases = nbases + 1
          call hwritei(tbreak, ix, offset, 4, iostat)
          offset = offset + 4
          do iy = 1, 2
            call hwritei(tbreak, nbreak(ix, iy), offset, 4, iostat)
            offset = offset + 4
            mesg = 'Error writing break count item in dataset: ' // visi
            if (iostat .ne. 0) call mybug(iostat, mesg)
            if (nbreak(ix, iy) .gt. 0) then
              do nb = 1, nbreak(ix, iy)
                break(nb, ix, iy) = break(nb, ix, iy) + day0
              enddo
              nb = 8 * nbreak(ix, iy)
              call hwrited(tbreak, break(1, ix, iy), offset, nb, iostat)
              offset = offset + nb
              mesg = 'Error writing break time item in dataset: '// visi
              if (iostat .ne. 0) call mybug(iostat, mesg)
            endif
          enddo
        endif
      enddo
c
      if (nbases .eq. 0) then
        call bug('w', 'Something really wrong when writing the breaks.')
      endif
c
      call hdaccess(tbreak, iostat)
      mesg = 'Error closing breaks item in dataset: ' // visi
      if (iostat .ne. 0) call mybug(iostat, mesg)
      call wrhdi(tvis, 'nbreaks', nbases)
      return
      end
c***********************************************************************
      SUBROUTINE mybug(iostat,message)
      IMPLICIT NONE
      INTEGER iostat
      CHARACTER message*(*)
c
c  Give an error message, and bugger off.
c------------------------------------------------------------------------
      CALL bug('w', message)
      CALL bugno('f', iostat)
      RETURN
      END
c***********************************************************************
      subroutine brmerge(bin, pin, btime, add, okay)
      implicit none
      integer bin, pin
      double precision btime
      logical add, okay
c
c  Input:
c    bin   : Baseline of break point.  If 0, do all baselines.
c    pin   : Sideband of break point.  If 0, do all sidebands.
c    add   : If .TRUE., add the break point; .FALSE., remove it.
c
c  Input/Output:
c    btime : Time of break point (decimal days offset from day0).
c          : If deleting, btime contains the break point time removed.
c
c  Output:
c    okay  : .TRUE. if break point added/removed; .FALSE., otherwise.
c
c  Merge each or delete each near supplied 'btime' in/out of
c  the 'break' array from the common block.
c  Do this in such a way that the 'break' array remains time sorted.
c  The input array break has a declared length MAXBREAK for each
c  baseline and sideband but only nbreak(b,p) elements have been
c  filled so far.  The input btime is either added (add=.TRUE.) or
c  deleted (add=.FALSE.) from the array.  If deleted, it looks for
c  the nearest neighbor and returns that in btime.  All times are in
c  units of decimal days offset from day0.  This routine returns the
c  logical flag okay as .TRUE. if the break was added/deleted
c  successfully; okay is set to .FALSE., otherwise.
c-----------------------------------------------------------------------
      include 'gfiddle.h'
c
      character msg*80
      integer i, j
      integer b, p
      integer bmin, bmax, pmin, pmax
      logical append
c
      okay = .FALSE.
      if (bin .gt. nbl) return
c
      if (bin .eq. 0) then
        bmin = 1
        bmax = nbl
      else
        bmin = bin
        bmax = bin
      endif
      if (pin .eq. 0) then
        pmin = 1
        pmax = 2
      else
        pmin = pin
        pmax = pin
      endif
c
c  Handle the simple cases first.
c
   10 format(A, A, I3, A, I3)
      okay = .TRUE.
      append = .FALSE.
      do p = pmin, pmax
        do b = bmin, bmax
          if (nbreak(b, p) .eq. 0) then
            if (add) then
              i = 0
              nbreak(b, p) = 1
              break(1, b, p) = btime         
            else
              okay = .FALSE.
              write(msg, 10) 'Cannot remove any more break points for ',
     *          abmode, b, ' and sideband ', p
              call bug('w', msg)
            endif
c
          else if (add .and. (nbreak(b, p) .eq. MAXBREAK)) then
            okay = .FALSE.
            write(msg, 10) 'Cannot add any more break points for ',
     *        abmode, b, ' and sideband ', p
            call bug('w', msg)
          else
c
c Locate where the to-be-inserted/deleted point should be
c for deletion, the nearest neighbor is taken
c i=interval to the right of breakpoint (0=before first one)
c
            call lsearchd(nbreak(b, p), break(1, b, p), btime, i)
c
            if (add) then
              if (btime .eq. break(i, b, p)) then
                write(msg, 10) 'Identical break entry ignored for ',
     *            abmode, b, ' and sideband ', p
                call bug('w', msg)
                okay = .FALSE.
              endif
              if (i .eq. nbreak(b, p)) then
                append = .TRUE.
              else        
                do j = nbreak(b, p), i + 1, -1
                  break(j + 1, b, p) = break(j, b, p)
                enddo
              endif
              break(i + 1, b, p) = btime
              nbreak(b, p) = nbreak(b, p) + 1
            else
              if (i .eq. 0) then
                i = 1
              else if (i .lt. nbreak(b, p)) then
                if ((btime-break(i,b,p)) .gt. (break(i+1,b,p)-btime))
     *            i = i + 1
              endif
              btime = REAL(break(i, b, p))
              if (i .lt. nbreak(b, p)) then
                do j = i, nbreak(b, p) - 1
                  break(j, b, p) = break(j + 1, b, p)
                enddo
              endif
              nbreak(b, p) = nbreak(b, p) - 1
            endif
          endif
        enddo
      enddo
c
   20 format(I3, 1X, A, 1X, F6.3)
      if (okay) then
        if (add .and. append) then
          write(msg, 20) i + 1, 'appending break time at ', btime
        else if (add) then
          write(msg, 20) i + 1, 'inserting break time at ', btime
        else
          write(msg, 20) i, 'deleting break time at ', btime
        endif
        call output(msg)
      endif
c
      return
      end
c***********************************************************************
      subroutine setbreak(time, ix, iy, xlo, xhi, ylo, yhi)
      implicit none
      integer ix, iy, xlo, xhi, ylo, yhi
      real time
c-----------------------------------------------------------------------
      include 'gfiddle.h'
c
      integer b, p, p2, pf
      integer bmin, bmax
      integer i, idx, sci
      real tlo, thi, zlo, zhi
      double precision dtime
      logical okay
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      p2 = (p + 1) / 2
      if (b .gt. nbl) return
c
c  The transformation of pf -> iy works only because of the special
c  relation p = iy.  If this mapping changes, then this do-loop may
c  need to be adjusted.
c
      pf = iy
      if (iy .eq. (2 * (iy / 2))) pf = pf - 1
c
      if (dolink) then
        bmin = 1
        bmax = nbl
      else
        bmin = b
        bmax = b
      endif
      do b = bmin, bmax
        dtime = DBLE(time)
c
c  Find the fit index of the region containing this new breakpoint.
c  Do this before adding the new break to keep the index count correct.
c
        if (nbreak(b, p2) .eq. 0) then
          idx = 0
        else
          call lsearchd(nbreak(b, p2), break(1, b, p2), dtime, idx)
        endif
        idx = idx + 1
      WRITE(*,*) 'setbreak: ', idx, nbreak(b, p2), b, p2
c
c  Try to add this break point to the database.
c            
        call brmerge(b, p2, dtime, .TRUE., okay)
        if (.not. okay) return
c
c  If it could be added, then shift the higher index fits making room
c  for this newly split one.  Also, identify which of the (now) two fits
c  need to be updated.
c
        do i = MAXBREAK, (idx + 1), -1
          fitdone(i+1, b, pf)   = fitdone(i, b, pf)
          fitdone(i+1, b, pf+1) = fitdone(i, b, pf+1)
        enddo
        do i = idx, idx + 1
          fitdone(i, b, pf) = .FALSE.
          fitdone(i, b, pf+1) = .FALSE.
        enddo
      enddo
c
c  Reset only those windows that are in direct view of the user.
c  b is now the ix counter; not the 1..nbl counter.
c
      if (dolink) then
        bmin = xlo
        bmax = xhi
      else
        bmin = ix
        bmax = ix
      endif
c
      do b = bmin, bmax
        if ((b .ge. xlo) .and. (b .le. xhi)) then
          call pgqci(sci)
          call pgsci(CNewB)
          do idx = pf, pf + 1
            if ((idx .ge. ylo) .and. (idx .le. yhi)) then
              call WinCoord(b, idx)
              call pgqwin(tlo, thi, zlo, zhi)
              call pgmove(time, zlo)
              call pgdraw(time, zhi)
              call plotfit(.FALSE., b, idx, zlo, zhi)
            endif
          enddo
          call pgsci(sci)
        endif
      enddo
      return
      end
c***********************************************************************
      subroutine clrbreak(time, ix, iy, xlo, xhi, ylo, yhi)
      implicit none
      integer ix, iy, xlo, xhi, ylo, yhi
      real time
c-----------------------------------------------------------------------
      include 'gfiddle.h'
c
      integer b, p, p2
      integer i, idx, sci
      real tlo, thi, zlo, zhi
      double precision btime
      logical okay
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      p2 = (p + 1) / 2
      if (b .gt. nbl) return
c
c  Find the fits on either side of this old breakpoint.
c
      btime = DBLE(time)
      call brmerge(b, p2, btime, .FALSE., okay)
      if (.not. okay) return
c
      if (nbreak(b, p2) .eq. 0) then
        idx = 0
      else
        call lsearchd(nbreak(b, p2), break(1, b, p2), btime, idx)
      endif
      idx = idx + 1
c
c  If it could be removed, then shift the higher index fits down freeing
c  up room of the newly removed one.  Also, identify that this (now) one
c  fit needs to be updated.
c
c  The transformation of p2 -> iy works only because of the special
c  relation p = iy.  If this mapping changes, then this do-loop may
c  need to be adjusted.
c
      p2 = iy
      if (iy .eq. (2 * (iy / 2))) p2 = p2 - 1
c
      fitdone(idx, b, p2) = .FALSE.
      fitdone(idx, b, p2+1) = .FALSE.
      do i = (idx + 1), MAXBREAK
        fitdone(i, b, p2)   = fitdone(i+1, b, p2)
        fitdone(i, b, p2+1) = fitdone(i+1, b, p2+1)
      enddo
c
      if ((ix .ge. xlo) .and. (ix .le. xhi)) then
        call pgqci(sci)
        call pgsci(COldB)
        do idx = p2, p2 + 1
          if ((idx .ge. ylo) .and. (idx .le. yhi)) then
            call WinCoord(ix, idx)
            call pgqwin(tlo, thi, zlo, zhi)
            call pgmove(REAL(btime), zlo)
            call pgdraw(REAL(btime), zhi)
            call plotfit(.FALSE., ix, idx, zlo, zhi)
          endif
        enddo
        call pgsci(sci)
      endif
      return
      end
c***********************************************************************
      subroutine visread(tno, visi, clip, dobreaks, dosrcbrk)
      implicit none
      integer tno
      character visi*(*)
      real clip
      logical dobreaks, dosrcbrk
c
c  tno      vis file handler.
c  visi     input vis file.
c  clip     amplitude value above which data is flagged bad.
c  dobreaks .TRUE. if source and focus changes should trip a break.
c  dosrcbrk .TRUE. if source changes trip a new breakpoint.
c-----------------------------------------------------------------------
      REAL MINVOLTS
      PARAMETER (MINVOLTS = 0.1)
c
      INCLUDE 'gfiddle.h'
c
      CHARACTER msg*120, src*10, name*40, type*1
      INTEGER baseline, b, nread, i, islot, nclips, a1, a2, k
      INTEGER ix, nants, thissrc
      REAL    dt, oldvolts, volts
      REAL    focus(MAXANT)
      DOUBLE PRECISION t1, t2, dtime
      DOUBLE PRECISION preamble(4)
      COMPLEX cval
      COMPLEX data(2)
      LOGICAL more, updated
      LOGICAL okay, firstsrc, firstvol
      LOGICAL flag(2)
c externals
      INTEGER findbase
      INTEGER findsrc
c
      name = visi
      firstsrc = .TRUE.
      firstvol = .TRUE.
c
c   Get all visibility in memory; first it must figure out how many
c   timeslots are being used..this is a bit tricky, for that
c   we perform one scan through the data, assuming they are
c   nicely time ordered...
c
      nslot = 0
      nbl = 0
      t1 = -1.0
      tmin = -1.0
      tmax = -1.0
      abmode(1:1) = ' '
c
      nread = 1
      CALL uvrewind(tno)
      DO WHILE(nread.GT.0)
         CALL uvread(tno,preamble,data,flag,2,nread)
         IF(nread.GT.0)THEN
            IF(abmode(1:1).EQ.' ') THEN
               CALL basant(preamble(4),a1,a2)
               IF(a1.EQ.a2) THEN
                  abmode = 'antenna'
               ELSE
                  abmode = 'baseline'
               ENDIF            
            ENDIF
            baseline = NINT(preamble(4))
            b = findbase(baseline,base,nbl)
            IF (b.EQ.0) THEN
               nbl = nbl + 1
               CALL assertl(nbl.LE.MAXBASE,'Too many baselines')
               base(nbl) = baseline
            ENDIF
            IF(tmin.LT.0.0) THEN
               tmin = preamble(3)
               tmax = preamble(3)
            ELSE
               tmin = MIN(tmin,preamble(3))
               tmax = MAX(tmax,preamble(3))
            ENDIF
            t2 = preamble(3)
            IF(t2.GT.t1)THEN
               nslot = nslot + 1
               if (nslot .gt. MAXTIME) then
                 call bug('f',
     *             'Data file too large; overflows internal storage.')
               endif
               times(nslot) = preamble(3)
            ELSE IF(t2.LT.t1)THEN
               CALL bug('w', 'Visibility file not in time order')
               IF(debug) write(*,*) '*       islot,t1,t2=',nslot,t1,t2
               nslot = nslot + 1
               if (nslot .gt. MAXTIME) then
                 call bug('f',
     *             'Data file too large; overflows internal storage.')
               endif
               times(nslot) = preamble(3)
            ENDIF
            t1 = t2
         ENDIF
      ENDDO
      nsloto = (tmax-tmin)/sample + 1
c
      IF(debug)THEN
         WRITE(*,*) 'first time slot=',times(1),' in dataset ',name
         WRITE(*,*) 'Found ',nbl,' ',abmode,'s'
         WRITE(*,*) 'Found ',nslot,' Time Slots. Output needs ',nsloto
         WRITE(*,*) '  Tmin=',tmin,' Tmax=',tmax
         WRITE(*,*) abmode,' based gains found in ',name
      ENDIF
c
      CALL assertl(nslot.GT.0,'(nslot=) Found no data in vis='//name)
      CALL assertl(nbl.GT.0,'(nbl=0) Found no data in vis='//name)
c
c  set the pointers in for common block data
c  It assumes an INTEGER takes up the same amount of space as a REAL
c  which is half the space of a COMPLEX....
c
c  Vis1 and Flg1 hold the data.  Vis1 is really meant to be two REAL
c  arrays which hold (amp,phase).  Flg1 is an INTEGER array but is
c  really a logical array.  Hence, 1 means good data (.TRUE.); 0
c  means bad or flagged data (.FALSE.).
c
      pVis1 = 1
      pFlg1 = pVis1 + 2*nslot*2*nbl
      pFree = pFlg1 +   nslot*2*nbl
      CALL assertl(pFree.LE.MAXBUF,'VisRead: Not enough memory....')
c
c  Try and allocate space for the fits. If they don't fit, increase
c  the sample time and try again.  Loop until it succeeds.
c
      more = .TRUE.
      DOWHILE(more)
         pVis4 = pFree
         pFlg4 = pVis4 + 2*nsloto*2*nbl
         pFree = pFlg4 +   nsloto*2*nbl
         if ((pFree .gt. MAXBUF) .or. (nsloto .gt. MAXTIME)) then
            pFree = pFlg1 +   nslot*2*nbl
            pVis4 = 0
            pFlg4 = 0
            WRITE(msg,'(A,F7.3,A)') 'Cannot store fits with sample=',
     *            sample*24*60,'. Trying twice that value'
            CALL bug('w', msg)
            sample = sample * 2
            nsloto = (tmax-tmin)/sample + 1
            if (nsloto .le. 2) then
              write(msg, '(A,A)') 'The number of fit slots is too ',
     *          'small to continue; too many data points.'
              call bug('f', msg)
            endif
         ELSE
            WRITE(msg,'(A,F7.3,A,I5,A)') 'Accepting sampling time=',
     *            sample*24*60,'. A total of ',nsloto,' slots needed'
            CALL output(msg)
            more = .FALSE.
         ENDIF
      ENDDO
c
c  inititialize the buffer data to unused unit gains etc.
c  slot 1/2 are (0,0), the output gains (1,0) ??
c
      cval = (0.0,0.0)
      CALL clearvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),cval)
      cval = (1.0,0.0)
      IF(pVis4.GT.0)
     *   CALL clearvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),cval)
c
c  set times() relative to the first day (units in fractional days).
c  Since Julian days are offset from UT by 12 hours, add half a day.
c  This is done by subtracting half a day from day0.  This is so
c  the reverse operation yields the proper Julian day.
c
      day0 = DBLE(INT(tmin + 0.5D0)) - 0.5D0
      time0 = tmin - day0
      do islot = 1, nslot
        times(islot) = times(islot) - day0
      enddo
c
c  rewind the vis file, and read the data again, now plugging it into
c  the 'allocated' arrays in memory
c
      CALL uvrewind(tno)
      nread = 1
      islot = 0
      t1 = -1.0
      nsrcs = 0
      thissrc = 1
c
      DO WHILE(nread.GT.0)
         CALL uvread(tno,preamble,data,flag,2,nread)
         IF(nread.GT.0)THEN
            baseline = NINT(preamble(4))
            b = findbase(baseline,base,nbl)
            IF(b.EQ.0) CALL bug('f', 'Illegal baseline')
            t2 = preamble(3)
            IF(t2.NE.t1) THEN
               islot = islot + 1
            ENDIF
            t1 = t2
c
            call uvprobvr(tno, 'source', type, k, updated)
            if (updated) then
              call uvrdvra(tno, 'source', src, ' ')
              thissrc = findsrc(nsrcs, sources, src)
              if (thissrc .eq. 0) then
                nsrcs = nsrcs + 1
                if (nsrcs .gt. MAXSRC) then
                  call bug('w', 'Too many sources in this file.')
                  nsrcs = MAXSRC
                endif
                sources(nsrcs) = src
                thissrc = nsrcs
                if (dobreaks) then
                  if (firstsrc) then
                    firstsrc = .not. dosrcbrk
                  else
                    if (islot .gt. 1) then
                      dtime = (times(islot-1) + times(islot)) / 2.0
                    else
                      dtime = times(islot)
                    endif
                    call brmerge(0, 0, dtime, .TRUE., okay)
                  endif
                endif
              endif
            endif
            srcidx(islot) = thissrc
c
c  Focus changes always generate a break point.  There will be
c  only one of the following focus items below.  The item focus
c  is written by Hat Creek observing software; sfocus is created
c  by GMAKE.  The item sfocus is just the sum of all focus elements.
c  If neither item exists, then updated will always return .FALSE.
c
            if (dobreaks) then
              call uvprobvr(tno, 'focus', type, k, updated)
              if (updated) then
                call uvrdvri(tno, 'nants', nants, 0)
                call uvgetvrr(tno, 'focus', focus, nants)
                volts = 0.0
                do ix = 1, nants
                  volts = volts + focus(ix)
                enddo
                if (firstvol) then
                  oldvolts = volts
                  firstvol = .FALSE.
                else if (abs(volts - oldvolts) .gt. MINVOLTS) then
                  if (islot .gt. 1) then
                    dtime = (times(islot-1) + times(islot)) / 2.0
                  else
                    dtime = times(islot)
                  endif
                  call brmerge(0, 0, dtime, .TRUE., okay)
                endif
              endif
              call uvprobvr(tno, 'sfocus', type, k, updated)
              if (updated) then
                call uvrdvrr(tno, 'sfocus', volts, 0.0)
                if (firstvol) then
                  oldvolts = volts
                  firstvol = .FALSE.
                else if (abs(volts - oldvolts) .gt. MINVOLTS) then
                  if (islot .gt. 1) then
                    dtime = (times(islot-1) + times(islot)) / 2.0
                  else
                    dtime = times(islot)
                  endif
                  call brmerge(0, 0, dtime, .TRUE., okay)
                endif
              endif
            endif
c
            IF (nphase.GT.0) THEN
               dt = times(islot)*24
               IF (debug) WRITE(*,*) 'P.C.b:',data(1),data(2)
               CALL driftcor(data(1),dt*phlinfit(1,b))
               CALL driftcor(data(2),dt*phlinfit(2,b))
               IF (debug) WRITE(*,*) 'P.C.a:',data(1),data(2)
            ENDIF
            CALL setvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,1,b,data(1),flag(1))
            CALL setvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,2,b,data(2),flag(2))
         ENDIF
      ENDDO
c
      if (nsrcs .lt. 1) then
C-jm  Next bug call needs to wait until GMAKE writes out source names.
C-jm        call bug('w',
C-jm     *    'VisRead: No source items were found in this data set.')
        nsrcs = 1
        sources(nsrcs) = 'Unknown'
      endif
c
c  Treating each complex as 2 reals, convert them to phase/amp for
c  plotting.  Then clip values by flagging their associated Flg to 0.
c
      CALL  c2pvis(nslot,2,nbl,buf(pVis1),buf(pFlg1))
      CALL clipvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),clip,nclips,sbmode)
      IF(nclips.GT.0) flagmod = .TRUE.
c
c  Set all windows as having no associated fits      
c
      DO k=1,MAXBREAK+1
      DO i=1,MAXBASE
         fitdone(k,i,1) = .FALSE.
         fitdone(k,i,2) = .FALSE.
         fitdone(k,i,3) = .FALSE.
         fitdone(k,i,4) = .FALSE.
      ENDDO
      ENDDO
      return
      END
c***********************************************************************
      SUBROUTINE VisWrite(tin, tinhis, viso, version)
      IMPLICIT NONE
      INTEGER tin,tinhis
      CHARACTER viso*(*), version*(*)
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      CHARACTER mesg*80
      INTEGER tno, b, i, islot, nbad
      INTEGER mode
      INTEGER ncount(4)
      REAL dt
      DOUBLE PRECISION ltime
      DOUBLE PRECISION preamble(4)
      COMPLEX zdata, data(2)
      LOGICAL done,flag(2)
c
      CHARACTER itoaf*5
      INTEGER nants
      REAL wfreq(2)
c
      LOGICAL hdprsnt
      COMPLEX mkcmplx
c
c Open new dataset to be written, set line to wide (DSB)
c
      CALL uvopen(tno,viso,'new')
      CALL uvset(tno,'data','wide',2,1.0,1.0,1.0)
c
c ToDo: these must be properly inherited from the input vis
      CALL uvputvri(tno,'nants',nants,1)
      CALL uvputvrr(tno,'wfreq',wfreq,2)
c
      IF (hdprsnt(tin,'history')) CALL hdcopy(tin, tno, 'history')
      CALL hisopen(tno,'append')
      CALL hiswrite(tno,version)
      CALL hisinput(tno,'GFIDDLE')

c
      IF(debug)THEN
         write(mesg, *) 'Writing ', nbl, ' Baselines'
         call output(mesg)
         write(mesg, *) 'Writing ', nsloto, ' Resampled Time Slots'
         call output(mesg)
      ENDIF
c
      nbad = 0
      ncount(1) = 0
      ncount(2) = 0
      ncount(3) = 0
      ncount(4) = 0
      do i = 1, MAXBREAK+1
        do b = 1, nbl
          if ((i - 1) .le. nbreak(b, 1)) then
            if (.not. fitdone(i, b, 1)) nbad = nbad + 1
            if (.not. fitdone(i, b, 2)) nbad = nbad + 1
            if (fitdone(i, b, 1)) ncount(1) = ncount(1) + 1
            if (fitdone(i, b, 2)) ncount(2) = ncount(2) + 1
          endif
          if ((i - 1) .le. nbreak(b, 2)) then
            if (.not. fitdone(i, b, 3)) nbad = nbad + 1
            if (.not. fitdone(i, b, 4)) nbad = nbad + 1
            if (fitdone(i, b, 3)) ncount(3) = ncount(3) + 1
            if (fitdone(i, b, 4)) ncount(4) = ncount(4) + 1
          endif
        enddo
      enddo
      IF(nbad.GT.0) THEN
         mesg = 'Number of missing or bad fits: ' // itoaf(nbad)
         call bug('w', mesg)
         call hiswrite(tno, 'GFIDDLE: ' // mesg)
      ENDIF
      if (sbmode .le. 2) then
        islot = ncount(1) + ncount(3)
        mesg = 'Number of fit amplitudes: ' // itoaf(islot)
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
        islot = ncount(2) + ncount(4)
        mesg = 'Number of fit phases: ' // itoaf(islot)
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
      else
        mesg = 'Number of fit amplitude ratios: ' // itoaf(ncount(1))
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
        mesg = 'Number of fit phase differences: ' // itoaf(ncount(2))
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
        mesg = 'Number of fit amplitude products: ' // itoaf(ncount(3))
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
        mesg = 'Number of fit phase averages: ' // itoaf(ncount(4))
        call bug('i', mesg)
        call hiswrite(tno, 'GFIDDLE: ' // mesg)
      endif
c
c  write corr's out. Note that preamble(1) and (2) [the U and V coordinates]
c  are not filled in yet, so further (external) processing is complicated.
c  Note that ssb data is written out.  If in dsb mode, then the data
c  needs to be converted before being written.
c
      mode = sbmode
      if (mode .gt. 2) mode = 2
      preamble(1) = 0
      preamble(2) = 0
      ltime = day0 + time0
      DO islot=1,nsloto
         DO b=1,nbl
            CALL getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *         islot,1,b,zdata,flag(1),mode)
            data(1) = mkcmplx(REAL(zdata), AIMAG(zdata))
            CALL getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *         islot,2,b,zdata,flag(2),mode)
            data(2) = mkcmplx(REAL(zdata), AIMAG(zdata))
            preamble(3) = ltime + ((islot - 1) * sample)
            preamble(4) = DBLE(base(b))
            IF(nphase.GT.0) THEN
               dt = (islot-1)*sample*24.0
               CALL driftcor(data(1),-dt*phlinfit(1,b))
               CALL driftcor(data(2),-dt*phlinfit(2,b))
            ENDIF
            CALL uvwrite(tno,preamble,data,flag,2)
         ENDDO
      ENDDO
      IF (hdprsnt(tinhis,'history')) THEN
        CALL hisopen(tinhis,'read')
        done = .FALSE.
        DOWHILE(.NOT.done)
            CALL hisread(tinhis,mesg,done)
            IF(.NOT.done) CALL hiswrite(tno,'GFIDDLE: ' // mesg)
        ENDDO
        CALL hisclose(tinhis)
      ENDIF
      CALL hisclose(tno)
      CALL uvclose(tno)
      END
c***********************************************************************
      SUBROUTINE FlgWrite(tno,visi)
      IMPLICIT NONE
      CHARACTER visi*(*)
      INTEGER tno
c
c  Rewrites the wide band flags
c  Make sure this routine walks the same way through the data as
c  VisRead, where the visibilities were read at startup. Otherwise
c  the flags will be written out in some wrong order. This routine
c  maintains a counter, to make sure nothing strange has happened
c  to the input dataset.
c  Slots are assigned according to incrementing time; if the dataset
c  stores visibilties with (pol & baseline) not being fastest running
c  storage can be terribly inefficient
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      CHARACTER mesg*132
      COMPLEX data(2)
      LOGICAL newflag, flag(2)
      INTEGER b, islot, nread, baseline
      INTEGER nflags
      INTEGER mode
      DOUBLE PRECISION preamble(4), t1, t2
c
      CHARACTER itoaf*4
      INTEGER findbase
c
      mesg = 'Writing back modified flags to ' // visi
      call output(mesg)
c
      mode = sbmode
      if (mode .gt. 2) mode = mode - 2
      nread = 1
      t1 = -1.0
      t2 = -1.0
      islot = 0
      nflags = 0
      CALL uvrewind(tno)
      DO WHILE(nread.GT.0)
         CALL uvread(tno,preamble,data,flag,2,nread)
         IF(nread.GT.0)THEN
            baseline = NINT(preamble(4))
            b = findbase(baseline,base,nbl)
            IF(b.EQ.0) CALL bug('f','Illegal baseline')
            t2 = preamble(3)
            IF(t2.NE.t1) THEN
               islot = islot + 1
            ENDIF
            t1 = t2
            CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,1,b,data(1),newflag,mode)
            if (flag(1) .neqv. newflag) nflags = nflags + 1
            flag(1) = newflag
            CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,2,b,data(2),newflag,mode)
            if (flag(2) .neqv. newflag) nflags = nflags + 1
            flag(2) = newflag
            CALL uvflgwr(tno,flag)
         ENDIF
      ENDDO
      mesg = 'GFIDDLE: Number of flags changed = ' // itoaf(nflags)
      call hiswrite(tno, mesg)
      return
      END
c***********************************************************************
      SUBROUTINE setflag(time, islot, ix, iy, fmode, xlo,xhi,ylo,yhi)
      IMPLICIT NONE
      INTEGER islot, ix, iy, xlo,xhi,ylo,yhi
      REAL time
      LOGICAL fmode
c
c     flag both bands in (pFlg2) to 'fmode'
c
c  Input:
c     islot       the slot to flag (must be 1..nbl)
c     ix          originator window (1..nx)
c     iy          originator window (1..ny)
c     fmode       TRUE=set as unflagged data  FALSE=set as flagged data
c     xlo,xhi     Current limits in 'ix' for display
c     ylo,yhi     Current limits in 'iy' for display
c
c     depending on 'dolink' the flags are set to 'fmode' for either
c     one baseline/antenna (b) or all (1..nbl)
c-----------------------------------------------------------------------
c     
      INCLUDE 'gfiddle.h'
      INTEGER b,p,bmin,bmax, n, idx
      REAL x, y, mean, rms
      DOUBLE PRECISION btime
      COMPLEX data
      LOGICAL flag
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      if (b .gt. nbl) return
c
      if (dolink) then
        bmin = 1
        bmax = nbl
      else
        bmin = b
        bmax = b
      endif
c
      if (debug) write(*,*) 'Flagging point ',islot,' as ',fmode
c
c  Set the relevant data in memory
c
      btime = DBLE(time)
      DO b=bmin,bmax
         DO p=1,2
            CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *                  islot,p,b,data,flag,0)
            CALL setvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *                  islot,p,b,data,fmode)
            if (nbreak(b, p) .eq. 0) then
              idx = 0
            else
              call lsearchd(nbreak(b, p), break(1, b, p), btime, idx)
            endif
            idx = idx + 1
            fitdone(idx,b,2*p) = .FALSE.
            fitdone(idx,b,2*p-1) = .FALSE.
         ENDDO
      ENDDO
c
c  Reset only those windows that are in direct view of the user.
c  b is now the ix counter; not the 1..nbl counter.
c
      if (dolink) then
        bmin = xlo
        bmax = xhi
      else
        bmin = ix
        bmax = ix
      endif
c
c  The logic in this next section may seem backwards compared with
c  the other plotting sections of this program but that is because
c  in this part we are only interested in changing the color of the
c  point.  When the window is redrawn, it will be drawn correctly
c  in either upper or lower (the right) case.
c
      if (.not. fmode) call pgsci(CBadP)
      do b = bmin, bmax
        do p = ylo, yhi
          call loadxy(1, n, x, y, b, p, idx, fmode, islot)
c             unwrap phases?
          if (n .eq. 0) call bug('f', 'BUMMER, No data.....')
          idx = srcidx(idx)
          if (fmode) idx = idx + 32
          call wincoord(b, p)
          call winpoint(1, x, y, idx)
          call plotfit(.FALSE., b, p, mean, rms)
        enddo
      enddo
      if (.not. fmode) call pgsci(1)
      return
      end
c***********************************************************************
      SUBROUTINE fitlin(ix,iy, xpos, doplot)
      IMPLICIT NONE
      INTEGER ix,iy
      REAL xpos
      LOGICAL doplot
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
c
      INTEGER b,p,nz,idx,isloto
      INTEGER s1, s2, off, last, npts
      REAL frac, mean, rms
      REAL ap(MAXTIME)
      DOUBLE PRECISION ltime
      DOUBLE PRECISION t(MAXTIME)
      COMPLEX data
      LOGICAL flag, doamp
c
c ToDo:  proper linear interpolation      
c
      b=(ipage-1)*nx+ix
      p=iy
      if (b .gt. nbl) return
      doamp = mod(p, 2) .eq. 1
c
      call loadap(MAXTIME, nz, ap, t, ix, iy)
      call getfits(1, xpos, ix, iy, nz, t, s1, s2, off, last)
      npts = last - off + 1
c
      if (npts .lt. 1) then
         call bug('w', 'Not enough points to 2-point fit.')
         return
      endif
c
c  Erase the previous fit.
c
      if (doplot) call plotfit(.TRUE., ix, iy, mean, rms)
c
      DO isloto = s1, s2
         CALL getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag,0)
         ltime = time0 + ((isloto - 1) * sample)
         call lsearchd(nz, t, ltime, idx)
         if ((idx .lt. 1) .or. (idx .ge. nz)) then
            mean = 0
            flag = .FALSE.
         else
            frac = (ltime - t(idx)) / (t(idx+1) - t(idx))
            mean = ((1.0 - frac) * ap(idx)) + (frac * ap(idx+1))
            flag = .TRUE.
            if ((idx .lt. off) .or. (idx .gt. last)) flag = .FALSE.
         endif
         if (doamp) then
           data = cmplx(mean, AIMAG(data))
         else
           data = cmplx(REAL(data), mean)
         endif
c
         CALL setvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag)
      ENDDO
c
      if (doplot) then
        call plotfit(.FALSE., ix, iy, mean, rms)
        WRITE(*,*) '<yplot> = ', mean, ', sigma_y = ', rms
      endif
      return
      END
c***********************************************************************
      SUBROUTINE fitpol(ix, iy, order, xpos, doplot)
      IMPLICIT NONE
      INTEGER ix,iy,order
      REAL xpos
      LOGICAL doplot
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
c
      INTEGER i,b,p,nz,isloto
      INTEGER s1, s2, off, last, npts
      REAL amp,ysum,ysum2,mean,stime,sigma,ftime
      REAL ap(MAXTIME),ttt(MAXTIME),wt(MAXTIME),z(MAXTIME),polcoef(10)
      DOUBLE PRECISION t(MAXTIME)
      COMPLEX data
      LOGICAL flag, doamp
c
      REAL valpol
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      if (b .gt. nbl) return
      doamp = mod(p, 2) .eq. 1
c
      call loadap(MAXTIME, nz, ap, t, ix, iy)
      call getfits(order+1, xpos, ix, iy, nz, t, s1, s2, off, last)
      npts = last - off + 1
c
      if (npts .le. order) then
         call bug('w', 'Not enough points to fit a polynomial.')
         return
      endif
c
c convert to REAL for LSPOLY
c also compute the differences and dispersion at the fit points
c and report on the dispersion from the lsq fit
c Note the peculiar behavior of lspoly/valpol to compute
c w.r.t. the first point !!!
c
      ftime = t(off)
      do i = 1, npts
         ttt(i) = t(off+i-1)
         wt(i) = 1.0
      enddo
      CALL lspoly(order,npts,ttt,ap(off),wt,z,polcoef)
      IF (debug) THEN
        write(*,*) 'polcoef: ',polcoef(1),polcoef(2)
        DO i=1,npts
           WRITE(*,*) i,t(off+i-1),ap(off+i-1),z(i)
        ENDDO
      ENDIF
c
      if (doplot) then
        ysum=0
        ysum2=0
        DO i=1,npts
          amp   = z(i) - ap(off + i - 1)
          ysum  = ysum  + amp
          ysum2 = ysum2 + (amp * amp)
        ENDDO
        ysum = ysum/npts
        ysum2 = ysum2/npts-ysum*ysum
        IF(ysum2.LT.0.0) ysum2=0.0
        sigma = sqrt(ysum2)
        WRITE(*,*) ' data-fit: mean = ', ysum, ' sigma_y = ', sigma
      endif
c
c  Erase the previous fit.
c
      if (doplot) call plotfit(.TRUE., ix, iy, mean, ysum2)
c
      t(off) = t(off) - ftime
      t(last) = t(last) - ftime
      DO isloto = s1, s2
         CALL getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag,0)

         stime = (time0 + ((isloto - 1) * sample)) - ftime
         mean = valpol(stime,polcoef,order+1)
c
         flag = .TRUE.
         if ((stime .lt. t(off)) .or. (stime .gt. t(last)))
     *     flag = .FALSE.
         if (doamp) then
           data = cmplx(mean, AIMAG(data))
         else
           data = cmplx(REAL(data), mean)
         endif
c
         CALL setvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag)
      ENDDO
c
c                       TO FIX: cache and unwrap phases this
c
      if (doplot) then
        call plotfit(.FALSE., ix, iy, mean, ysum2)
        IF (order.EQ.0) THEN
           WRITE(*,*) '<yplot> = ', mean, ', sigma_y = ', ysum2
           IF (doamp) WRITE(*,*) '1 / S/N = ', sigma / mean
        ENDIF
        WRITE(*,*) 'Offset: P_0 = ',polcoef(1)
        IF (order.EQ.1) THEN
           IF (doamp) THEN
              WRITE(*,*) 'Gain  drift: P_1 = ',polcoef(2)/24.0,' /hr'
           ELSE
              WRITE(*,*) 'Phase drift: P_1 = ',polcoef(2)/24.0,' deg/hr'
           ENDIF
        ENDIF
      endif
      return
      END
c***********************************************************************
      COMPLEX FUNCTION mkcmplx(amp,phs)
      IMPLICIT NONE
      REAL amp, phs
c
c  return complex number for given amp and phase (degrees)
c-----------------------------------------------------------------------
      REAL       D2R
      PARAMETER (D2R = 180/3.141592653589793)
c
      REAL ang
c
      ang = phs / D2R
      mkcmplx = CMPLX(amp*COS(ang), amp*SIN(ang))
      return
      END
c***********************************************************************
      SUBROUTINE fitsplin(ix, iy, length, xpos, doplot)
      IMPLICIT NONE
      INTEGER ix, iy, length
      REAL xpos
      LOGICAL doplot
c
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      INTEGER j, k, b, p, nz, isloto
      INTEGER s1, s2, off, last, npts, iflag
      REAL delx, mean, sig
      REAL ap(MAXTIME), tt(MAXTIME), wt(MAXTIME), y2(MAXTIME)
      REAL aa(MAXTIME), bb(MAXTIME), cc(MAXTIME), dd(MAXTIME)
      DOUBLE PRECISION stime
      DOUBLE PRECISION t(MAXTIME)
      COMPLEX data
      LOGICAL flag, doamp
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      if (b .gt. nbl) return
      doamp = mod(p, 2) .eq. 1
c
      call loadap(MAXTIME, nz, ap, t, ix, iy)
      call getfits(5, xpos, ix, iy, nz, t, s1, s2, off, last)
      npts = last - off + 1
c
      if (npts .lt. 5) then
        call bug('w', 'Not enough points to spline fit.')
        return
      endif
c
c  Sig is the value that flags a singular matrix has been found.
c  Weighting is the [(number of control points) / (time range)]**3
c  for equal weighting (number of points is increased by 1 since the
c  inputs range from 0 to 9 and 0 is not allowed).
c  If data points have error bars, these just get scaled to the above.
c
      sig = 1.0E-4
      mean = 1.0
      delx = t(last) - t(off)
      if (delx .ne. 0.0) mean = (length + 1.0) / delx
      mean = mean * mean * mean
      do j = 1, npts
        tt(j) = REAL(t(j + off - 1))
        wt(j) = mean
      enddo
c
      call cubsm1(npts, tt, ap(off), wt, sig, y2, aa, bb, cc, dd, iflag)
      if (iflag .ne. 0) then
        call bug('w', 'Failure to fit a spline.')
        return
      endif
c
c  Erase the previous fit.
c
      if (doplot) call plotfit(.TRUE., ix, iy, mean, sig)
c
c  Fit computed.  Now apply it to the fit data.
c
      j = off
      do isloto = s1, s2
         CALL getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag,0)
         stime = time0 + ((isloto - 1) * sample)
    1    continue
         if ((j .lt. (last - 1)) .and. (stime .gt. t(j + 1))) then
           j = j + 1
           goto 1
         endif
         delx = stime - t(j)
CC         mean = aa(j) + (bb(j) * delx) + (cc(j) * delx * delx) +
CC     *          (dd(j) * delx * delx * delx)
         k = j - off + 1
         mean = delx * (bb(k) + (delx * (cc(k) + (delx * dd(k)))))
         mean = aa(k) + mean
c
         flag = .TRUE.
         if ((stime .lt. t(off)) .or. (stime .gt. t(last)))
     *     flag = .FALSE.
         if (doamp) then
           data = cmplx(mean, AIMAG(data))
         else
           data = cmplx(REAL(data), mean)
         endif
         CALL setvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag)
      enddo
c
      if (doplot) then
        call plotfit(.FALSE., ix, iy, mean, sig)
        WRITE(*,*) '<yplot> = ', mean, ', sigma_y = ', sig
      endif
      return
      END
c***********************************************************************
      subroutine plotfit(usebg, ix, iy, mean, rms)
      implicit none
      integer ix, iy
      real mean, rms
      logical usebg
c-----------------------------------------------------------------------
      include 'gfiddle.h'
c
      integer b, p
      integer sci, sls
      integer isloto, nplot, fitidx
      real amp, phase, xplot, yplot
      real ysum, ysum2
      real theta0
      double precision ltime
      complex data
      logical flag, oflag, wrapok
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      mean = 0
      rms = 0
      if (b .gt. nbl) return
      wrapok = dowrap .and. (mod(p, 2) .eq. 0) .and. (nsloto .gt. 1)
c +++++JM
c  No wrapping done here as this should all reside within the range
c  of the data displayed.
c +++++JM
      wrapok = .FALSE.
c -----JM
c
      call wincoord(ix, iy)
c
      nplot = 0
      ysum = 0
      ysum2 = 0
      oflag = .TRUE.
c
c  Set the color index for the first fit since it is always there
c  (i.e. regardless of the number of breaks).  At each break point,
c  adjust the color index for the next fit region.  Also increment
c  the fit index.
c
      call pgqci(sci)
      call pgqls(sls)
      call pgbbuf
      fitidx = 1
      if (usebg) then
        call pgsci(0)
      else if (fitdone(fitidx, b, p)) then
        call pgsci(fcolor)
      else
        call pgsci(COldF)
      endif
c
c  The following needs to be done when phases are to be unwrapped.
c  Because the fits and data are different arrays, the fits need
c  to know where the data has been wrapped to so it overlays properly.
c  The only way to do this is to grab the first data point and treat
c  it as if were going through the phase wrapper.  Assign this
c  (possibly flipped) value to theta0.  Fit data should then flip in
c  a similar fashion.
c
      if (wrapok) then
        theta0 = 0.0
        do isloto = 1, nslot
          CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *          isloto,(p+1)/2,b,data,flag,sbmode)
          if (flag) then
            theta0 = AIMAG(data)
            goto 10
          endif
        enddo
  10    continue
        do while (theta0 .gt. 180.0)
          theta0 = theta0 - 360.0
        enddo
        do while (theta0 .lt. -180.0)
          theta0 = theta0 + 360.0
        enddo
      endif

      do isloto = 1, nsloto
         call getvis(nsloto,2,nbl,buf(pVis4),buf(pFlg4),
     *               isloto,(p+1)/2,b,data,flag,0)
c
         ltime = time0 + ((isloto - 1) * sample)
         if (isloto .gt. 1) then
           if (flag .and. oflag) then
             call pgsls(1)
           else
             call pgsls(4)
           endif
         endif
c
         xplot = ltime
         amp = REAL(data)
         phase = AIMAG(data)
         if (wrapok) then
           phase = phase - (360.0 * NINT((phase - theta0) / 360.0))
           theta0 = 0.5 * (phase + theta0)
           if (abs(theta0) .lt. 1.0E-5) theta0 = 0.0
         endif
c
         if (mod(p, 2) .eq. 0) then
           yplot = phase
         else
           yplot = amp
         endif
         if (isloto .eq. 1) then
           call pgmove(xplot, yplot)
         else
           call pgdraw(xplot, yplot)
         endif
c
         if ((.not. usebg) .and. (fitidx .le. nbreak(b, (p+1)/2)) .and.
     *       (ltime .ge. break(fitidx, b, (p+1)/2))) then
           fitidx = fitidx + 1
           if (fitdone(fitidx, b, p)) then
             call pgsci(fcolor)
           else
             call pgsci(COldF)
           endif
         endif
c
         if (flag) then
           nplot = nplot + 1
           ysum = ysum + yplot
           ysum2 = ysum2 + (yplot * yplot)
         endif
         oflag = flag
      enddo
      call pgsci(sci)
      call pgsls(sls)
      call pgebuf
c
      if (nplot .gt. 0) then
        ysum = ysum / nplot
        ysum2 = (ysum2 / nplot) - (ysum * ysum)
        if (ysum2 .le. 0) ysum2 = 0
        mean = ysum
        rms = sqrt(ysum2)
      endif
      return
      end
c***********************************************************************
      SUBROUTINE loadz(maxz, nz, z, t, phz, ix, iy)
      IMPLICIT NONE
      INTEGER maxz, nz, ix, iy
      REAL phz(maxz)
      COMPLEX z(maxz)
      DOUBLE PRECISION t(maxz)
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      INTEGER b,p,islot
      COMPLEX data
      LOGICAL flag
c
      b = (ipage-1)*nx+ix
      p = iy
      nz = 0
      if (b .gt. nbl) return
c
      DO islot=1,nslot
         CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *               islot,(p+1)/2,b,data,flag,sbmode)
         IF (flag) THEN
            nz = nz + 1
            if (nz .gt. maxz) then
              call bug('f', 'LOADZ: Number of points exceeds storage.')
            endif
            t(nz) = times(islot)
            z(nz) = data
            phz(nz) = AIMAG(data)
         ENDIF
      ENDDO
      call unwrap(dowrap, nz, phz)
      DO islot=1,nz
         z(islot) = CMPLX(REAL(z(islot)), phz(islot))
      ENDDO
      if (debug) write(*,*) 'loadz: ',b,p,nz
      return
      END
c***********************************************************************
      SUBROUTINE loadap(maxap, nap, ap, t, ix, iy)
      IMPLICIT NONE
      INTEGER maxap, nap, ix, iy
      REAL ap(maxap)
      DOUBLE PRECISION t(maxap)
c
c   Load an amplitude or phase from a slot (ix,iy)
c   maxap:  (i) space for array
c   nap:    (o) returned length of array
c   ap:     (o) array
c   t:      (o) times associated with array
c   ix:     (i) X panel
c   iy:     (i) Y panel
c
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      INTEGER b,p,islot
      COMPLEX data
      LOGICAL flag, doamp
c
      b = (ipage-1)*nx+ix
      p = iy
      nap = 0
      if (b .gt. nbl) return
      doamp = MOD(p,2).EQ.1
c
      DO islot=1,nslot
         CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *               islot,(p+1)/2,b,data,flag,sbmode)
         IF (flag) THEN
            nap = nap + 1
            if (nap .gt. maxap) then
              call bug('f', 'LOADAP: Number of points exceeds storage.')
            endif
            t(nap) = times(islot)
            IF (doamp) THEN
               ap(nap) = REAL(data)
            ELSE
               ap(nap) = AIMAG(data)
            ENDIF
         ENDIF
      ENDDO
      if (.not. doamp) call unwrap(dowrap, nap, ap)
c
      if (debug) write(*,*) 'loadap: ',b,p,nap
c
      return
      END
c***********************************************************************
      SUBROUTINE getopt(debug,dolink,dowrap,dosrcbrk,dodsb,dobreak,
     *                  doappend,donew)
      IMPLICIT NONE
      LOGICAL debug,dolink,dowrap,dosrcbrk,dodsb,dobreak,doappend,donew
c-----------------------------------------------------------------------
      INTEGER NOPT
      PARAMETER (NOPT=8)
      CHARACTER opts(NOPT)*10
      LOGICAL present(NOPT)
      DATA opts /'debug','link','nowrap','sources','dsb','nobreak',
     *           'append', 'new'/
c
      CALL options('options',opts, present, NOPT)
      debug = present(1)
      dolink = present(2)
      dowrap = .NOT.present(3)
      dosrcbrk = present(4)
      dodsb = present(5)
      dobreak = .NOT.present(6)
      doappend = present(7)
      donew = present(8)
c
      IF(debug)THEN
         write(*,*) 'Debug is  ',debug
         write(*,*) 'DoLink is ',dolink
         write(*,*) 'DoWrap is ',dowrap
         write(*,*) 'DoSourceBreaks is ',dosrcbrk
         write(*,*) 'DoDSB is ',dodsb
         write(*,*) 'DoBreak is',dobreak
         write(*,*) 'DoAppend is',doappend
         write(*,*) 'DoNew is',donew
      ENDIF
      RETURN
      END
c***********************************************************************
      SUBROUTINE getphase(key)
      IMPLICIT NONE
      CHARACTER key*(*)
c
c   Store the phase drift corrections from the commandline
c   into some internal lookup table
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
c
      INTEGER a, b
      CHARACTER band*1, lkey*10
      REAL pdrift
      LOGICAL keyprsnt
c
      lkey = key
      nphase = 0
      DO a=1,MAXANT
         DO b=1,2
            phlinfit(b,a) = 0.0
         ENDDO
      ENDDO
      DO WHILE(keyprsnt(key))
         CALL keyi(key,a,0)
         CALL keya(key,band,' ')
         b=0
         IF (index('1Ll',band(1:1)).GT.0) b=1
         IF (index('2Uu',band(1:1)).GT.0) b=2
         CALL keyr(key,pdrift,0.0)
         IF (a.LT.1  .OR. a.GT.MAXANT) CALL bug('f',
     *         'Antenna number out of range for keyword '//lkey)
         IF (b.EQ.0) CALL bug('f',
     *         'Error specifying LSB/USB (band 1/2) for keyword '//lkey)
         phlinfit(b,a) = pdrift
         nphase = nphase + 1
         WRITE(*,*) 'Phase correction ',b,a,pdrift
      ENDDO
      RETURN
      END
c***********************************************************************
      SUBROUTINE driftcor(data, phi)
      IMPLICIT NONE
      COMPLEX data
      REAL phi
c
c  Phase correct a complex number by subtraction
c
c     phi is given in degrees !!
c
c-----------------------------------------------------------------------
c local
      REAL amp, phase
c externals
      COMPLEX mkcmplx
c
      CALL amphase(data,amp,phase)
      phase = phase - phi 
      phase =  phase - 360.0*NINT(phase/360.0)
      data = mkcmplx(amp,phase)
      RETURN
      END
c***********************************************************************
      SUBROUTINE help(debug, doedit, dolink, polymode, sbmode)
      IMPLICIT NONE
      logical debug, doedit, dolink, polymode
      integer sbmode
c-----------------------------------------------------------------------
      character mesg*80
      integer i
c
      integer Len1
c
      CALL output('d   -- delete the nearest point (flag bad)')
      CALL output('a   -- add the nearest deleted point (flag good)')
      CALL output('x   -- zoom/unzoom toggle on the current column')
      CALL output('y   -- zoom/unzoom toggle on the current row')
      CALL output('z   -- zoom/unzoom toggle on the current plot')
      CALL output('b   -- insert a breakpoint')
      CALL output('c   -- delete the nearest breakpoint')
      CALL output('m   -- toggle DSB/SSB mode (no editing permitted)')
      CALL output('0-9 -- order of polynomial fit/# of spline nodes')
      CALL output('t   -- toggle between poly and cubic spline fitting')
      CALL output('f   -- two-point fit (simple linear interpolation)')
      CALL output('l   -- toggle between single/all baseline edits')
      CALL output('i   -- info on the nearest (good) data point')
      CALL output('r   -- redraw the screen (also rescales the axes)')
      CALL output('+   -- advance to next page (if multiple pages)')
      CALL output('-   -- backup to previous page (if multiple pages)')
      CALL output('<,> -- shift left/right one panel (in zoom mode)')
      CALL output('v,^ -- shift down/up one panel (in zoom mode)')
      CALL output('?,h -- this help')
      CALL output('q   -- quit (no saving)')
      CALL output('e   -- exit (saving flags, breakpoints, and fits)')
c
      i = 1
      if (debug) then
        write(mesg(i:), '(A)') 'Debug:  ON;'
      else
        write(mesg(i:), '(A)') 'Debug: OFF;'
      endif
      i = Len1(mesg) + 1
c
      if (doedit) then
        write(mesg(i:), '(A)') ' Editing: YES;'
      else
        write(mesg(i:), '(A)') ' Editing:  NO;'
      endif
      i = Len1(mesg) + 1
c
      if (dolink) then
        write(mesg(i:), '(A)') ' b/d   linked;'
      else
        write(mesg(i:), '(A)') ' b/d unlinked;'
      endif
      i = Len1(mesg) + 1
c
      if (sbmode .eq. 0) then
        write(mesg(i:), '(A)') ' One chan mode;'
      else if (sbmode .le. 2) then
        write(mesg(i:), '(A)') ' SSB displayed;'
      else
        write(mesg(i:), '(A)') ' DSB displayed;'
      endif
      i = Len1(mesg) + 1
c
      if (polymode) then
        write(mesg(i:), '(A)') ' [0-9] fits Polys.'
      else
        write(mesg(i:), '(A)') ' [0-9] fits Splines.'
      endif
      i = Len1(mesg) + 1
      call output(mesg(1:i))
      RETURN
      END
c***********************************************************************
      SUBROUTINE plotwin(ix, iy)
      IMPLICIT NONE
      INTEGER ix,iy
c
c  Service routine called by WINTSHOW win(3MIR) package (win.for)
c  that does the actual drawing in the (ix,iy) tile.
c  Together with the (ipage,nbl) a proper (b,p) pair can be
c  computed, needed to look up the data
c
c     Since no paging is done in y:
c           p = iy
c     but
c           b = (ipage-1)*nx + ix
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
c
      INTEGER b, p, npts, i, sls, sci
      INTEGER idx(MAXTIME)
      REAL    tlop, thip, dlo, dhi, btime, size
      REAL    amp, phs
      REAL    x(MAXTIME), y(MAXTIME)
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      if (b .gt. nbl) return
c
c  Get the current extent of window in the (b,p) tile.
c
      call pgbbuf
      call pgqci(sci)
      call pgqls(sls)
      call pgqwin(tlop, thip, dlo, dhi)
c
c  always draw a box and horizontal line at y=0
c  the top X-axis is eventually drawn and labelled by WINTSHOW
c  The character size is set to match that of the WINTSHOW routine.
c
      call pgqch(size)
      call pgsch(0.6 * size)
      call pgsls(1)
      CALL pgtbox( 'BTS', 0.0, 0, 'BCTS', 0.0, 0 )
      call pgsch(size)
      call pgmove(tlop, 0.0)
      call pgdraw(thip, 0.0)
c
c  Load all good points as upper case white; wrapping attempted.
c
      CALL loadxy(MAXTIME,npts,x,y,ix,iy,idx,.TRUE.,0)
	      IF (DEBUG .AND. (MOD(IY,2).EQ.0)) THEN
	        WRITE(*,*) 'Raw: ', IX, IY, B
	        DO I=1,NPTS
	          WRITE(*,*) 'Raw: ', Y(I)
	        ENDDO
	      ENDIF
      if (mod(iy, 2) .eq. 0) call unwrap(dowrap, npts, y)
CCCC	      IF (DEBUG .AND. (SBMODE.EQ.3) .AND. (P.EQ.4)) THEN
	      IF (DEBUG .AND. (MOD(IY,2).EQ.0)) THEN
	        WRITE(*,*) 'Flipped: ', IX, IY, B
	        DO I=1,NPTS
	          WRITE(*,*) 'Flipped: ', Y(I)
	        ENDDO
	      ENDIF
      DO i=1,npts
         idx(i) = srcidx(idx(i))
      ENDDO
      CALL winpoint(npts,x,y,idx)
c
c  Load all bad points as lower case red; no wrapping done.
c
      CALL pgsci(CBadP)
      CALL loadxy(MAXTIME,npts,x,y,ix,iy,idx,.FALSE.,0)
      DO i=1,npts
         idx(i) = srcidx(idx(i)) + 32
      ENDDO
      CALL winpoint(npts,x,y,idx)
      CALL pgsci(1)
c
c  Display the break points.
c
      call pgsci(CNewB)
      do i = 1, nbreak(b, (p+1)/2)
        btime = break(i, b, ((p+1)/2))
        call pgmove(btime, dlo)
        call pgdraw(btime, dhi)
      enddo
      call pgsci(1)
c
c  Display the sampled fits.
c
      call plotfit(.FALSE., ix, iy, amp, phs)
c
      call pgsls(sls)
      call pgsci(sci)
      call pgebuf
      return
      end
c***********************************************************************
      SUBROUTINE BatCurs(nx, ny, px, py, c, morepgs)
      IMPLICIT NONE
      INTEGER   nx, ny
      REAL      px, py
      CHARACTER c*1
      LOGICAL morepgs
c
c  Fake cursor in batch mode
c-----------------------------------------------------------------------
      IF (morepgs) THEN
        c = '+'
      ELSE
        c = 'e'
      ENDIF
      CALL logcurr(nx,ny,px,py,c)
      END
c***********************************************************************
      SUBROUTINE loadxy(maxpts,npts,x,y,ix,iy,idx,fmode,request)
      IMPLICIT NONE
      INTEGER maxpts, npts, ix, iy, idx(maxpts), request
      REAL x(maxpts), y(maxpts)
      LOGICAL fmode
c
c  Load points into data array for immediate access
c
c  Inputs:
c     maxpts      maximum points that can be loaded (array space)
c     ix          (baseline) window in current display
c     iy          (sideband) window in current display
c     fmode       TRUE=pick out unflagged data, FALSE=flagged data
c     request     If greater than zero, only one requested islot is
c                 needed.  If equal to zero, load all slots with the
c                 proper flag.  If less than zero, load all slots
c                 regardless of flagging.
c  Outputs:
c     npts        number of points that were loaded     
c     x           array of X values
c     y           array of Y values 
c-----------------------------------------------------------------------
      INCLUDE 'gfiddle.h'
      INTEGER b,p,islot,imin,imax
      COMPLEX data
      LOGICAL flag
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      npts = 0
      if (b .gt. nbl) return
c
      if (request .le. 0) then
        imin = 1
        imax = nslot
      else
        imin = request
        imax = request
      endif
c
      DO islot=imin,imax
         CALL getvis(nslot,2,nbl,buf(pVis1),buf(pFlg1),
     *         islot,(p+1)/2,b,data,flag,sbmode)
         IF ((fmode.EQV.flag) .OR. (request.LT.0)) THEN
            npts = npts + 1
            if (npts .gt. maxpts) then
              call bug('f', 'LOADXY: Number of points exceeds storage.')
            endif
            idx(npts) = islot
            x(npts) = times(islot)
            IF(MOD(p,2).EQ.0) THEN
               y(npts) = AIMAG(data)
            ELSE
               y(npts) = REAL(data)
            ENDIF
         ENDIF
      ENDDO
c
      IF(debug)THEN
         write(*,*) '*** Loading (b,p) = ',b,p,' with ',
     *               npts,' points.',fmode
      ENDIF
      RETURN
      END
c***********************************************************************
      SUBROUTINE unwrap(dowrap, n, phs)
      IMPLICIT NONE
      LOGICAL dowrap
      INTEGER n
      REAL phs(*)
c
c  Stolen from UVPLT.
c
c  Input:
c       dowrap      .TRUE. means to wrap; .FALSE. means don't wrap.
c       n           Number of points in the phs array.
c
c  Input/Output:
c       phs         Array of 'n' phases [in degrees] to unwrap in-place.
c------------------------------------------------------------------------
      INTEGER i
      REAL theta0
c
      IF (.NOT. dowrap) RETURN
      IF (n.lt.2) RETURN
c
      do while (phs(1) .gt. 180.0)
        phs(1) = phs(1) - 360.0
      enddo
      do while (phs(1) .lt. -180.0)
        phs(1) = phs(1) + 360.0
      enddo
c
      theta0 = phs(1)
      DO i = 2, n
         phs(i) = phs(i) - 360*NINT((phs(i)-theta0)/360.0)
         theta0 = 0.5*(phs(i) + theta0)
      ENDDO
      RETURN
      END
c***********************************************************************
      subroutine initfits(npage, fmethod, aorder, porder)
      implicit none
      character fmethod*(*)
      integer npage, aorder, porder
c
c  The arguments are all input.  npage specifies the total number of
c  of pages that will be generated (needed for page loop).
c  fmethod indicates the type of fit to apply.  It is assumed to come
c  into the routine in lower case.  a/porder are parameters to the fit.
c------------------------------------------------------------------------
      include 'gfiddle.h'
c
      integer ix, iy, nb
      integer b, p, p2
      integer order
      real xpos
c
      call output('Computing initial fits...')
c
c  This outer loop uses ipage which is stored in gfiddle.h.  It
c  is needed to insure that the proper baseline gets set and also
c  needs to be reset at the end of this routine.
c
      do ipage = 1, npage
        do iy = 1, ny
          p = iy
          p2 = (p + 1) / 2
          order = porder
          if (mod(iy, 2) .eq. 1) order = aorder
          do ix = 1, nx
            b = ((ipage - 1) * nx) + ix
            if (b .le. nbl) then
              do nb = 0, nbreak(b, p2)
                if (nb .eq. 0) then
                  xpos = time0
                else
                  xpos = break(nb, b, p2) + 0.5E-5
                endif
                if (fmethod(1:1) .eq. 'p') then
                  call fitpol(ix, iy, order, xpos, .FALSE.)
                else if (fmethod(1:1) .eq. 's') then
                  call fitsplin(ix, iy, aorder, xpos, .FALSE.)
                else if (fmethod(1:1) .eq. '2') then
                  call fitlin(ix, iy, xpos, .FALSE.)
                endif
              enddo
            endif
          enddo
        enddo
      enddo
      ipage = 1
      return
      end
c***********************************************************************
      subroutine setlabel(nxy, xlabel, ylabel)
      implicit none
      integer nxy
      character*(*) xlabel(nxy), ylabel(nxy)
c
c------------------------------------------------------------------------
      include 'gfiddle.h'
c
      character*20 deflabel(10)
      integer ix, iy, k
      integer bl, a1, a2
c
      character itoaf*5
      character blname*10
c
c                     '12345678901234567890'
c                      ====================
      data deflabel / 'Gains sqrt(Jy/K)',
     *                'Phase (degrees)',
     *                'LSB Gain sqt(Jy/K)',
     *                'LSB Phase (degrees)',
     *                'USB Gain sqt(Jy/K)',
     *                'USB Phase (degrees)',
     *                'Gain(USB)/Gain(LSB)',
     *                'Ph(USB)-Ph(LSB)',
     *                'sqt(Gn(USB)*Gn(LSB))',
     *                '(Ph(USB)+Ph(LSB))/2' /
c                      ====================
c
      do ix = 1, nx
        do iy = 1, ny
          k = ix + ((iy - 1) * nx)
          if (k .le. nxy) then
            bl = ix + ((ipage - 1) * nx)
            if (bl .le. nbl) then
              bl = base(bl)
              call basant(DBLE(bl), a1, a2)
              if (a1 .eq. a2) then
                xlabel(k) = abmode(1:1) // ' ' // itoaf(a1)
              else
                xlabel(k) = abmode(1:1) // ' ' // blname(bl)
              endif
              if (sbmode .eq. 0) then
                ylabel(k) = deflabel(iy)
              else if ((sbmode .eq. 1) .or. (sbmode .eq. 2)) then
                ylabel(k) = deflabel(iy + 2)
              else if ((sbmode .eq. 3) .or. (sbmode .eq. 4)) then
                ylabel(k) = deflabel(iy + 6)
              else
                ylabel(k) = 'Y-label-' // itoaf(iy)
              endif
            else
              xlabel(k) = ' '
              ylabel(k) = ' '
            endif
          endif
        enddo
      enddo
      return
      end
c***********************************************************************
      subroutine getfits(smin, xpos, ix, iy, nt, t, s1, s2, off, last)
      implicit none
      real xpos
      integer smin, ix, iy, nt
      double precision t(nt)
      integer s1, s2, off, last
c
c  This routine finds the range of fit slots (s1,s2) based on the input
c  time position (xpos), the range of time values (t(nt)), and the
c  location of the break points (break and nbreak from gfiddle.h) for
c  the current window (ix,iy).  In addition to the fit slot range, the
c  first and last valid index in the t-array are returned.
c  If the number of points found is less than smin, the fitdone flag
c  is not set to .TRUE.
c------------------------------------------------------------------------
      include 'gfiddle.h'
c
      integer b, p, p2, idx
c
      s1 = 1
      s2 = nsloto
      off = 1
      last = nt
c
      b = ((ipage - 1) * nx) + ix
      p = iy
      p2 = (p + 1) / 2
      if (b .gt. nbl) return
c
      if (nbreak(b, p2) .lt. 1) then
        idx = 0
      else
        call lsearchd(nbreak(b, p2), break(1, b, p2), DBLE(xpos), idx)
        if (idx .gt. 0) then
          s1 = ((break(idx, b, p2) - time0) / sample) + 2
          call lsearchd(nt, t, break(idx, b, p2), off)
          off = off + 1
        endif
        if (idx .lt. nbreak(b, p2)) then
          s2 = ((break(idx+1, b, p2) - time0) / sample) + 1
          call lsearchd(nt, t, break(idx+1, b, p2), last)
        endif
      endif
      fitdone(idx+1, b, p) = .TRUE.
c
      if ((last - off + 1) .lt. smin) fitdone(idx+1, b, p) = .FALSE.
      if (debug) 
     *  write (*,*) 'getfits ', xpos, ix, iy, nt, s1, s2, off, last
      return
      end
c***********************************************************************
      subroutine cubsm1(n, x, y, p, eps, y2, a, b, c, d, iflag)
      implicit none
      integer n, iflag
      real eps
      real x(n), y(n), p(n), y2(n), a(n), b(n), c(n), d(n)
c
c  Inputs:
c    n     Number of points in the a, b, c, and f arrays.
c    x,y   Arrays specifying the input data points.
c    p     An array which is used to specify how much smoothing is done.
c    eps   Error value that specifies a singular matrix.
c  Output:
c    y2    The array of second derivatives.
c    a,b,c,d The arrays of spline coefficients.
c    iflag Is 0 if all went okay; 1 if n < 5; 2 if singular matrix.
c
c  Solves for the solution of:
c    sk(x) = Ak + Bk * (x - xk) + Ck * (x - xk)**2 + Dk * (x - xk)**3
c    for all k = 1, n.
c
c  Good values for eps are 10**(-t+2) where t is machine precision.
c
c  From "One Dimensional Spline Interpolation Algorithms" Helmoth Spath,
c       AK Peters 1995.
c-----------------------------------------------------------------------
      integer n1, n2, k, k1, k2
      real p1, p2, p3, r1, r2
      real h1, h2, h3, s
c
      iflag = 0
      if (n .lt. 5) then
        iflag = 1
        return
      endif
c
      n1 = n - 1
      n2 = n - 2
      do k = 1, n1
        d(k) = 1.0 / (x(k + 1) - x(k))
      enddo
      d(n) = 0.0
      p1 = 1.0 / p(1)
      p2 = 1.0 / p(2)
      h1 = d(1)
      h2 = d(2)
      r1 = (y(2) - y(1)) * h1
      do k = 1, n2
        k1 = k + 1
        k2 = k + 2
        h3 = d(k2)
        p3 = 1.0 / p(k2)
        s = h1 + h2
        a(k) = (6.0 * ((h1 * h1 * p1) + (s * s * p2) + (h2 * h2 * p3)))
        a(k) = a(k) + (2.0 / h1) + (2.0 / h2)
        b(k) = (1.0 / h2) - (6.0 * h2 * ((p2 * s) + (p3 * (h2 + h3))))
        c(k) = 6.0 * p3 * h2 * h3
        r2 = (y(k2) - y(k1)) * h2
        y2(k) = 6.0 * (r2 - r1)
        h1 = h2
        h2 = h3
        p1 = p2
        p2 = p3
        r1 = r2
      enddo
      call pentas(n2, a, b, c, y2, eps, iflag)
      if (iflag .ne. 0) return
      do k = n2, 1, -1
        y2(k + 1) = y2(k)
      enddo
      y2(1) = 0.0
      y2(n) = 0.0
      h1 = 0.0
      do k = 1, n1
        k1 = k + 1
        b(k) = d(k)
        h2 = d(k) * (y2(k1) - y2(k))
        d(k) = h2 / 6.0
        a(k) = y(k) - ((h2 - h1) / p(k))
        c(k) = y2(k) / 2.0
        h1 = h2
      enddo
      a(n) = y(n) + (h1 / p(n))
      do k = 1, n1
        k1 = k + 1
        s = b(k)
        b(k) = (a(k1) - a(k)) * s
        b(k) = b(k) - ((y2(k1) + (2.0 * y2(k))) / (6.0 * s))
      enddo
      return
      end
c***********************************************************************
      subroutine pentas(n, a, b, c, f, eps, iflag)
      implicit none
      integer n, iflag
      real eps
      real a(n), b(n), c(n), f(n)
c
c  Solves the five-diagonal matrix.
c  Inputs:
c    n     Number of points in the a, b, c, and f arrays.
c    eps   Error value that specifies a singular matrix.
c  Input/Output:
c    a,b,c Arrays specifying the diagonal elements.
c    f     The linear matrix that is the solution.
c  Output:
c    iflag Is 0 if all went okay; 2 if singular matrix.
c
c  Good values for eps are 10**(-t+2) where t is machine precision.
c
c  From "One Dimensional Spline Interpolation Algorithms" Helmoth Spath,
c       AK Peters 1995.
c-----------------------------------------------------------------------
      integer k
      real h1, h2, h3, h4, h5
      real hh1, hh2, hh3, hh4, hh5
      real z, hb, hc
c
      iflag = 0
      h1 = 0.0
      h2 = 0.0
      h3 = 0.0
      h4 = 0.0
      h5 = 0.0
      hh1 = 0.0
      hh2 = 0.0
      hh3 = 0.0
      hh4 = 0.0
      hh5 = 0.0
      do k = 1, n
        z = a(k) - (h4 * h1) - (hh5 * hh2)
        if (abs(z) .lt. eps) then
          iflag = 2
          return
        endif
        hb = b(k)
        hh1 = h1
        h1 = (hb - (h4 * h2)) / z
        b(k) = h1
        hc = c(k)
        hh2 = h2
        h2 = hc / z
        c(k) = h2
        a(k) = (f(k) - (hh3 * hh5) - (h3 * h4)) / z
        hh3 = h3
        h3 = a(k)
        h4 = hb - (h5 * hh1)
        hh5 = h5
        h5 = hc
      enddo
      h2 = 0.0
      h1 = a(n)
      f(n) = h1
      do k = n - 1, 1, -1
        f(k) = a(k) - (b(k) * h1) - (c(k) * h2)
        h2 = h1
        h1 = f(k)
      enddo
      return
      end
c
c Here are a few support routines to manage the batch file, the file
c that logs the commands that were given interactively, and can be played
c back at will. Only tested on device=/xs
c

c-----------------------------------------------------------------------
c Open the cursor file
c
      SUBROUTINE logcuro(fname,status)
      CHARACTER fname*(*), status*(*)
c                               open cursor log file      
      INCLUDE 'gfiddle.h'
      INTEGER iostat, len1
      CHARACTER*80 line

c      write(*,*) 'logcuro: ',fname,status

      if (fname .eq. ' ') then
         logu = -1
         return
      endif
c
      CALL txtopen(logu,fname,status,iostat)
      IF (iostat.NE.0) CALL bug('f','logcuro: Opening logfile')
      IF(status.EQ.'new')THEN
         line = '# GFIDDLE log file'
         CALL txtwrite(logu,line,len1(line),iostat)
         IF (iostat.NE.0) CALL bug('f','logcuro: Writing new line')
      ENDIF
      END

c-----------------------------------------------------------------------
c Close the cursor file
c
      SUBROUTINE logcurc()
c                               close cursor log file      
      INCLUDE 'gfiddle.h'
c
      if (logu.lt.0) return
      CALL txtclose(logu)
      logu = -1
      END

c-----------------------------------------------------------------------
c Write to the cursor file
c
      SUBROUTINE logcurw(ix,iy,xpos,ypos,chr)
      INTEGER ix,iy
      REAL xpos,ypos
      CHARACTER chr*1
c
      INCLUDE 'gfiddle.h'
c
      CHARACTER line*80, itoaf*20, rtoaf*20
      INTEGER len1,iostat,length

      if (logu.lt.0) return

c      write(*,*) 'More logcurs: ',ix,iy,xpos,ypos," CHR: ",chr
      line = chr // ' ' // itoaf(ix) 
      length = len1(line)
      line(length+1:) = ' ' // itoaf(iy)
      length = len1(line)
      line(length+1:) = ' ' // rtoaf(xpos,1,6)
      length = len1(line)
      line(length+1:) = ' ' // rtoaf(ypos,1,6)
      CALL txtwrite(logu,line,len1(line),iostat)
      IF(iostat.NE.0) CALL bug('f','Writing...')

      END
c
c-----------------------------------------------------------------------
c Read from cursor file
c
      SUBROUTINE logcurr(ix,iy,xpos,ypos,chr)
      INTEGER ix,iy
      REAL xpos,ypos
      CHARACTER chr*1
c
      INCLUDE 'gfiddle.h'
c
      CHARACTER line*80, token*20
      INTEGER len1,iostat,length,k1,k2
      LOGICAL ok

      if (logu.lt.0) return

      ok = .TRUE.
      DO WHILE(ok)
         CALL txtread(logu,line,length,iostat)
         IF(iostat.EQ.-1) THEN
            write(*,*) 'EOF....'
            chr = char(0)
            return
         ENDIF
         ok = line(1:1).EQ.'#'
      ENDDO

c     write (*,*) 'LOGCURR:',length,line


      chr = line(1:1)
      k1 = 3
      k2 = len1(line)
      CALL gettok(line,k1,k2,token,length)
      CALL atoif(token,ix,ok)
c      write(*,*) 'IX',ix,ok,k1,k2
      CALL gettok(line,k1,k2,token,length)
      CALL atoif(token,iy,ok)
c      write(*,*) 'IY',iy,ok,k1,k2
c      CALL gettok(line,k1,k2,token,length)
      CALL getfield(line,k1,k2,token,length)
      CALL atorf(token,xpos,ok)
c      write(*,*) 'XPOS',xpos,ok,k1,k2
c      CALL gettok(line,k1,k2,token,length)
      CALL getfield(line,k1,k2,token,length)
      CALL atorf(token,ypos,ok)
c      write(*,*) 'YPOS',ypos,ok,k1,k2
c      write(*,*) 'READ logcurs: ',ix,iy,xpos,ypos," CHR: ",chr

      END
c-----------------------------------------------------------------------
