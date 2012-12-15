c***********************************************************************
      program sinbad
      implicit none
c
c= sinbad - Calculate Tsys*(on-off)/off for autocorrelation data.
c& mchw
c: uv analysis
c+
c       SINBAD is a MIRIAD task to calculate (ON-OFF)/OFF*TSYS for
c       autocorrelation data. The preceeding OFF and TSYS record
c	for each antenna is used. When flags on the OFF scans are bad,
c       the scan is now ignored as an OFF scan.
c	Flags on the ON scans are copied to the output file.
c       Only valid ON scans are copied to the output file.
c       Missing TSYS can be replaced via the tsys= keyword as a last
c       resort, or the spectral window based systemp() UV variable
c       that should be present in normal MIRIAD datasets.
c       Normally the "on" UV-variable is used to find out which record
c       is the ON (on=1) or OFF (on=0) record. You can override this
c       by supplying two source names using the onoff= keyword
c       For baseline subtraction, see:  SINPOLY
c       For single dish mapping, see:  VARMAPS
c@ vis
c       The name of the input autocorrelation data set.
c       Only one name must be given.
c@ select
c       The normal uv selection commands. See the Users manual for details.
c       Warning(BUG):   do not use win() selection,the tsys values are still
c       not correctly obtained this way. Use UVCAT to preprocess your selection.
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
c@ onoff
c       Two source names, for the on=1 and on=0 (off) positions. This will
c       override the use of the "on" uv variable, which is how normal
c       autocorrelation data are tagged for single dish work.
c       This mode also disallows usage of Tsys hidden in on=-1 tagged
c       data.
c       Default: not used, since on/off tagging is done via the 'on' uv var
c@ options 
c       Different computational output options (mainly for debugging).
c       Exclusively one of the following (minimum match):
c         'spectrum'     Compute Tsys*(on-off)/off.  This is the default
c         'difference'   Compute (on-off)
c         'ratio'        Compute on/off
c         'on'           Output (on)
c         'off'          Output (off)
c         'tsys'         Tsys
c@ slop
c       Allow some fraction of channels bad for accepting
c       Default: 0
c@ debug
c       Set to TRUE if you truely want to see lots of debugging output.
c       Default: false
c@ repair
c       A list of bad channels (birdies) that need to be repaired by
c       interpolating accross them. CLASSy data need 80 for each window
c       of 159 channels.  eg. repair=80,239,398
c       Default: not used.
c@ mode
c       Interpolation mode between OFF before and after ON.  Default is 0,
c       meaning no interpolation done, the last OFF scan is used, or an
c       average (see OAVER= below) is used.
c       1 signifies linear interpolation.
c       ** not used **
c@ oaver
c       Avering mode for the OFF. Two integers, denoting the number of
c       OFF's before the current ON, and the number after.  Use a negative
c       number to force averaging all scans.  The default is to look at the
c       most recent one, i.e. oaver=1,0.
c
c@ normalize
c       Should all scan be normalized before using the OFF?  
c       Using larger oaver= should be combined with normalize=true
c       Default: false
c
c@ log
c       Optional filename in which the ON pointing centers (in offset arcsec)
c       are listed. A third column designates if this pointing center
c       was the one immediately preceded by an OFF pointing.
c--
c
c  History:
c    mchw    29jan97  New task for Marc.
c    mchw    05feb97  write same type of correlation data as input file.
c    pjt/mwp 19feb08  safeguard off before on, tsys=1 if not present
c    pjt     25feb08  use window based systemp array if tsys not available.
c    mwp     16may08  added options for spectrum, difference, ratio
c    mwp     16may08-2  off() must be complex!!! very funny behavior if not. 
c    pjt     28jan11  made it listen to flags in the OFF scans
c    pjt     28feb11  quick hack to pre-cache first scan of all OFF's
c    pjt      3mar11  flagging
c    pjt     30sep11  options=on,off 
c    pjt      8may12  bad channel (interpolate accross) method  [not impl]
c    pjt     24sep12  implemented onoff=
c    pjt     28sep12  fixing up some ....and then more
c    pjt     28oct12  added log=
c    pjt      1nov12  oops, bug in spectrum mode ever since 16may08
c    pjt      2nov12  start work on mode=, but added options=tsys
c    pjt      5nov12  added oaver=
c    pjt     26nov12  implemented normalize=
c    pjt      4dec12  fix variable copy when ending on an OFF in onoff=
c---------------------------------------------------------------------------
c  TODO:
c    - integration time from listobs appears wrong
c    - the on/off flag is still copied, looks a bit confusing perhaps
c      even though the off scans are not written
c
c  - proper handling of flags (oflags is now read)
c    useful if ON and OFF are different
c  - optionally allow interpolaton between two nearby OFF's
c  - specify OFF's from a different source name (useful if data were
c    not marked correctly).
c  - does't handle missing ants too well?

      include 'maxdim.h'
      character version*80,versan*80
      integer MAXSELS, MAXTIME, MAXOFF, MAXCHAN2, MAXBAD
      parameter(MAXSELS=1024)
      parameter(MAXTIME=1000)
      parameter(MAXOFF=256)
      parameter(MAXCHAN2=1024)
      parameter(MAXBAD=16)
c     
      real sels(MAXSELS)
      real start,step,width,tsys1,slop,dra,ddec
      double precision timein0
      character linetype*20,vis*128,out*128,log*128,logline*128
      character srcon*16, srcoff*16, src*16
      complex data(MAXCHAN2)
      logical flags(MAXCHAN2)
      logical first,new,dopol,PolVary,doon,dosrc,qnorm
      integer lIn,lOut,nchan,npol,pol,SnPol,SPol,on,i,j,k,ant,koff
      character type*1, line*128
      integer length, nt, intmode, nvis, ivis, n
      integer nrepair, repair(MAXBAD)
      logical updated,qlog,more
      double precision preamble(5)
c            trick to read the preamble(4) [or preamble(5)]
      double precision uin,vin,timein,basein
      common/preamb/uin,vin,timein,basein
c     
      complex off(MAXCHAN2,MAXANT,MAXOFF), toff(MAXCHAN2)
      real    tsys(MAXCHAN2,MAXANT)
      complex offsum(MAXANT,MAXOFF)
      integer ivisoff(MAXOFF+1,MAXANT)  
      logical oflags(MAXCHAN2,MAXANT,MAXOFF), tflags(MAXCHAN2)
      double precision stime(MAXTIME)
      integer otime(MAXTIME), oaver(2)
      integer num,   non,    noff,    ntsys
      integer        nonb,   noffb,   ntsysb
      data    num/0/,non/0/, noff/0/, ntsys/0/
      data           nonb/0/,noffb/0/,ntsysb/0/
      logical spectrum, diffrnce, ratio, have_ant(MAXANT), rant(MAXANT)
      logical allflags,debug,qon,qoff,qfirst,qtsys
      integer iwhengtm
c     
c  Read the inputs.
c
      version = versan('sinbad',
     *     '$Revision$',
     *     '$Date$')
      
      call keyini
      call getopt(spectrum,diffrnce,ratio,qon,qoff,qtsys)
      call keyf('vis',vis,' ')
      call SelInput('select',sels,MAXSELS)
      call keya('line',linetype,' ')
      call keyi('line',nchan,0)
      call keyr('line',start,1.)
      call keyr('line',width,1.)
      call keyr('line',step,width)
      call keya('out',out,' ')
      call keyr('tsys',tsys1,-1.0)
      call keyr('slop',slop,0.0)
      call keyl('debug',debug,.FALSE.)
      call keya('onoff',srcon,' ')
      call keya('onoff',srcoff,' ')
      call keya('log',log,' ')
      call keyi('mode',intmode,0)
      call keyi('oaver',oaver(1),1)
      call keyi('oaver',oaver(2),0)
      call mkeyi('repair',repair,MAXBAD,nrepair)
      call keyl('normalize',qnorm,.FALSE.)
      call keyfin
c     
c     Check user inputs.
c     
      if(vis.eq.' ')call bug('f','Input file name (vis=) missing')
      if(out.eq.' ')call bug('f','Output file name (out=) missing')
      qlog = log.ne.' '
c
c     Check the on/off mode
c
      dosrc =  srcon.ne.' '
      if (dosrc) then
         if (srcoff.eq.' ') call bug('f','Need two sources for onoff=')
      endif
c     
c default is spectrum, so set it if nothing specified on 
c command line.  Note I could do this in getopt() like
c  spectrum = present(spectrum) || ( !present(diffrnce) && !present(ratio) )
c but this is perhaps a little more obvious
c
      if( ( spectrum .eqv. .false. ) .and.
     *     ( diffrnce .eqv. .false. ) .and.
     *     ( qon .eqv. .false. ) .and.
     *     ( qoff .eqv. .false. ) .and.
     *     ( qtsys .eqv. .false. ) .and.
     *     ( ratio    .eqv. .false. ) ) then
         spectrum = .true.
      endif
c
c  Open the output file.
c

      call uvopen(lOut,out,'new')
      if (qlog) call logopen(log,' ')
c     
c  Open the data file, apply selection, do linetype initialisation and
c  determine the variables of interest.
c
      call uvopen(lIn,vis,'old')
c      call SelApply(lIn,sels,.true.)
      if(linetype.ne.' ')
     *     call uvset(lIn,'data',linetype,nchan,start,width,step)
      call SelApply(lIn,sels,.true.)
      call VarInit(lIn,'channel')
      do j=1,MAXANT
         do i=1,MAXCHAN2
            tsys(i,j) = tsys1
         enddo
         have_ant(j) = .FALSE.
         rant(j) = .TRUE.
      enddo
      do j=1,MAXANT
         do k=1,MAXOFF
            ivisoff(k,j) = 0
         end do
      end do
      nvis = 0

c     
c  Scan the file once and pre-cache the first OFF positions
c  for each antenna (danger: this could mean they're not
c  all at taken at the same time)
c     
      call uvread(lIn,uin,data,flags,MAXCHAN2,nchan)
      do while (nchan.gt.0)
         nvis = nvis + 1
         call uvrepair(nchan,data,flags,nrepair,repair)
         if (dosrc) then
            call uvgetvra(lIn,'source',src)
            if (debug) write(*,*) "source: ",src
            if (src.eq.srcon) then
               on = 1
            else if (src.eq.srcoff) then
               on = 0
            else
               call bug('f','onoff not supported mode')
            endif
         else
            call uvgetvri(lIn,'on',on,1)
         endif
         ant = basein/256
         if(on.eq.0)then
            n = ivisoff(1,ant) + 1
            if (debug) write(*,*) 'Reading off ant ',
     *           ant,have_ant(ant),nvis,n
            if (n.eq.MAXOFF) call bug('f','MAXOFF: too many offs')
            ivisoff(n+1,ant) = nvis
            ivisoff(1,ant) = n
            offsum(ant,n) = 0.0
            do i=1,nchan
               offsum(ant,n) = offsum(ant,n) + data(i)
               off(i,ant,n) = data(i)
               oflags(i,ant,n) = flags(i)
            end do
c                not sure if we should hang on to this?
            if (allflags(nchan,flags,slop)) then
               if (.not.have_ant(ant)) then
                  if(debug)write(*,*) 'Saving off ant ',ant
                  have_ant(ant) = .TRUE.
               endif
            endif

         endif
         call uvread(lIn,uin,data,flags,MAXCHAN2,nchan)
      end do

      call uvrewind(lIn)
      write(*,*) 'Rewinding file, reading ON'
c
c  Read through the file, listing what we have to.
c
      call uvread(lIn,uin,data,flags,MAXCHAN2,nchan)
c
c  Other initialisation.
c     
      first = .true.
      new = .true.
      SnPol = 0
      SPol = 0
      PolVary = .false.
      timein0 = timein
      nt = 1
      koff = 0
      call uvprobvr(lIn,'corr',type,length,updated)
      if(type.ne.'r'.and.type.ne.'j'.and.type.ne.'c')
     *     call bug('f','no spectral data in input file')
      call uvset(lOut,'corr',type,0,0.,0.,0.)
      call uvprobvr(lIn,'npol',type,length,updated)
      dopol = type.eq.'i'
      if(dopol) call bug('w', 'polarization variable is present')

      if (.NOT.dosrc) then
         call uvprobvr(lIn,'on',type,length,updated)
         doon = type.eq.'i'
         if(.not.doon) call bug('w', '"on" variable is missing')
      else
         doon = .TRUE.
      endif
      if (tsys1.lt.0.0) call getwtsys(lIn,tsys,MAXCHAN2,MAXANT)
      
c
c  Loop through the data, writing (ON-OFF)/OFF*TSYS
c
      do while (nchan.gt.0)
         num = num + 1
         call uvrepair(nchan,data,flags,nrepair,repair)

c
c  Determine the polarisation info, if needed.
c     
         if(dopol)then
            call uvgetvri(lIn,'npol',nPol,1)
            if(nPol.le.0) call bug('f',
     *           'Could not determine number of polarizations present')
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
c  Since only the "on" scans are output, there's an 
c  un-intended side effect here: some variables are written
c  twice (e.g. the "on" will be off, then on again).
c
c         call VarCopy(lIn,lOut)
c  VarCopy now moved down, not clear how some options= now work 
c  if you need other than 'on'



c
c  Now process the data.
c
         if(doon)then
            if (timein0.ne.timein) then
               timein0 = timein
               nt = nt + 1
            endif
            if (dosrc) then
               call uvgetvra(lIn,'source',src)
               if (src.eq.srcon) then
                  on=1
                  call VarCopy(lIn,lOut)
               else if (src.eq.srcoff) then
                  on=0
               else
                  on=-1
               endif
               write(*,*) 'source: ',src,on
            else
               call VarCopy(lIn,lOut)
               call uvgetvri(lIn,'on',on,1)
            endif
            ant = basein/256
            if(on.eq.0)then
               if (allflags(nchan,flags,slop)) then
                  noff = noff + 1
c                  do i=1,nchan
c                     off(i,ant) = data(i)
c                     oflags(i,ant) = flags(i)
c                  enddo
               else
                  noffb = noffb + 1
               end if
               koff = 1
            else if(on.eq.-1)then
               if (allflags(nchan,flags,slop)) then
                  ntsys = ntsys + 1
                  do i=1,nchan
                     tsys(i,ant) = data(i)
c                    oflags(i,ant) = flags(i)
                  enddo
               else
                  ntsysb = ntsysb + 1
               end if
            else if(on.eq.1)then
               if (have_ant(ant)) then
                  if (noff.eq.0) call bug('f','No OFF before ON found')
                  if (ntsys.eq.0 .and. tsys1.lt.0.0)
     *                 call getwtsys(lIn,tsys,MAXCHAN2,MAXANT) 
                  non = non + 1
                  call getoff(nchan,num,ant,oaver,qnorm,debug,
     *                        MAXCHAN2,MAXANT,MAXOFF,
     *                        off, offsum, ivisoff, toff, tflags)
                  if (qnorm) call normdata(nchan,data,flags)
                  if(spectrum) then
                     do i=1,nchan
                        data(i) = tsys(i,ant)*(data(i)/toff(i) - 1.0)
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  else if(diffrnce) then
                     do i=1,nchan
                        data(i) = data(i)-toff(i)
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  else if(ratio) then
                     do i=1,nchan
                        data(i) = data(i)/toff(i)
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  else if(qon) then
                     do i=1,nchan
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  else if(qoff) then
                     do i=1,nchan
                        data(i) = toff(i)
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  else if(qtsys) then
                     do i=1,nchan
                        data(i) = tsys(i,ant)
                        flags(i) = flags(i).AND.tflags(i)
                     enddo
                  end if
                  call uvwrite(lOut,uin,data,flags,nchan)
c                 should ask if either dra or ddec was updated, only then print
                  call uvrdvrr(lIn,'dra',dra,0.0)
                  call uvrdvrr(lIn,'ddec',ddec,0.0)
                  if (qlog) then
                     dra  = dra*206265.0
                     ddec = ddec*206265.0
                     write(logline,'(F8.2,1x,F8.2,1x,i1)') dra,ddec,koff
                     call LogWrite(logline,more)
                  end if
                  koff = 0
               else
                  nonb = nonb + 1
c                 only rant about an antenna once in their lifetime
                  if (rant(ant)) then
                     write(line,
     *                 '(''Did not find valid scan for ant '',I2)') ant
                     call bug('w',line)
                     rant(ant) = .FALSE.
                  end if
               end if
            else
               call bug('w','value of on not 1, 0 or -1')
            end if
         end if
         call uvread(lIn,uin,data,flags,MAXCHAN2,nchan)
      enddo
c     
      print *,'Times read:         ',nt
      print *,'records read:       ',num
      print *,'records read: on:   ',non, '  off:',noff ,' tsys:',ntsys
      print *,'records flagged:    ',num-non-noff-ntsys
      print *,'records flagged: on:',nonb,'  off:',noffb,' tsys:',ntsysb
      if (spectrum) then 
         print *,'records written: (on-off)/off*tsys:',non
      endif
      if (diffrnce) then 
         print *,'records written: (on-off)',non
      endif
      if (ratio) then 
         print *,'records written: (on/off)',non
      endif
      if (qon) then 
         print *,'records written: (on)',non
      endif
      if (qoff) then 
         print *,'records written: (off)',non
      endif
      if (qnorm) then
        write(*,*) 'Normalized scans were used'
      else
        write(*,*) 'Raw scans were used (not normalized)'
      end if
      
      if (ntsys.eq.0) then
         if (tsys1.lt.0.0) then
            call bug('i','No Tsys data on=-1 found, used systemp')
         else
            call bug('i','No Tsys data on=-1 found, used default tsys=')
         endif
      endif
      
c     
c  Finish up the history, and close up shop
c
      call hdcopy(lIn,lOut,'history')
      call hisopen(lOut,'append')
      call hiswrite(lOut,'SINBAD: Miriad '//version)
      call hisinput(lOut,'SINBAD')
      call hisclose (lOut)
      call uvclose(lOut)
      call uvclose(lIn)
      if (qlog) call logclose
      end
c-----------------------------------------------------------------------
      subroutine getoff(nchan,num,ant,Oaver,Qnorm,debug,
     *                  mchan,mant,moff,
     *                  off, offsum, ivisoff, toff, tflags)

c
c  get the OFF based on past and/or future values
c
      implicit none
      integer nchan, num, ant, mchan, mant, moff, oaver(2)
      complex off(mchan, mant, moff), toff(mchan)
      complex offsum(mant, moff)
      integer ivisoff(moff+1, mant)
      logical tflags(mchan),qnorm,debug
c
      integer i,k,n, k1,k2,ki, iwhengtm
      real    kw

c
      if (oaver(1).eq.0 .and. oaver(2).eq.0) call bug('f','bad oaver')
      if (oaver(1).lt.0 .or.  oaver(2).lt.0) call bug('f','oaver<0')

c
c  initialize to worst case scenario
c
      do i=1,nchan
         toff(i) = 0.0
         tflags(i) = .FALSE.
      end do

c  find where we are

      n = ivisoff(1,ant)
      k = iwhengtm(n, ivisoff(2,ant), num) - 1
      if (debug) write(*,*) 'getoff: ',ant,num,n,k,
     *                      ivisoff(k,ant),ivisoff(k+1,ant)
      if (k.eq.0) return
c  
      if (oaver(1).eq.1 .and. oaver(2).eq.0) then
         if (qnorm) then
            do i=1,nchan
               toff(i) = off(i,ant,k) / offsum(ant,k)
            end do
         else
            do i=1,nchan
               toff(i) = off(i,ant,k)
               tflags(i) = .TRUE.
            end do
         endif
      else
         k1 = k-oaver(1)
         k2 = k+oaver(2)
         if (k1.lt.1) k1 = 1
         if (k2.gt.n) k2 = n
         kw = k2-k1+1
         do i=1,nchan
            toff(i) = 0.0
            if (qnorm) then
               do ki=k1,k2
                  toff(i) = toff(i) + off(i,ant,ki)/offsum(ant,ki)
               enddo
            else
               do ki=k1,k2
                  toff(i) = toff(i) + off(i,ant,ki)
               enddo
            endif
            toff(i) = toff(i)/kw
            tflags(i) = .TRUE.
         end do
      endif

      end
c-----------------------------------------------------------------------
      integer function iwhengtm(n, iarr, m)
      implicit none
      integer n, m, iarr(n)
c  find the index in a sorted array which the first value is larger than 
c  a given value (m)
      integer i

c  use a simple linear search for now
      do iwhengtm=1,n
         if (iarr(iwhengtm).gt.m) return
      end do

      iwhengtm = 0
      end
c-----------------------------------------------------------------------
      logical function allflags(nchan,flags,slop)
      implicit none
      integer nchan
      logical flags(nchan)
      real slop
c     
      integer i, nf
      allflags = .TRUE.
      
      if (slop.eq.1.0) return
      
      nf = 0
      do i=1,nchan
         if (.NOT.flags(i)) nf = nf + 1
      enddo
c     write(*,*) nf,nchan,slop*nchan
      allflags = nf .LE. (slop*nchan)
      return
      end
c-----------------------------------------------------------------------
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
c              write(*,*) i2,' :t: ',(tsys(i2,j),j=1,nants)
            enddo
         enddo
c        write(*,*) 'new Tsys: ',tsys(1,1)
         
      endif
      
      end
c-----------------------------------------------------------------------
c     Get the various (exclusive) options
c     
      subroutine getopt(spectrum,diffrnce,ratio,qon,qoff,qtsys)
      implicit none
      logical spectrum, diffrnce, ratio, qon,qoff,qtsys
c     
      integer nopt
      parameter(nopt=6)
      character opts(nopt)*10
      logical present(nopt)
      data opts/'spectrum  ','difference','ratio    ',
     *          'on        ','off       ','tsys     '/
      call options('options',opts,present,nopt)
      spectrum = present(1)
      diffrnce = present(2)
      ratio    = present(3)
      qon      = present(4)
      qoff     = present(5)
      qtsys    = present(6)
      end
c-----------------------------------------------------------------------
      subroutine uvrepair(nchan,data,flags,nrepair,repair)
      integer nchan,nrepair,repair(3)
      complex data(nchan)
      logical flags(nchan)
c      
      integer i,ir

      if (nrepair.lt.1) return
      if (nrepair.eq.1 .and. repair(1).lt.1) return

      do i=1,nrepair
         ir = repair(i)
         if (ir.lt.2 .or. ir.gt.nchan-1) call bug('f',
     *         'bad repair channel number (must be 2..nchan-1)')
         data(ir) = 0.5*(data(ir-1) + data(ir+1))
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine normdata(nchan,data,flags)
      implicit none
      integer nchan
      complex data(nchan)
      logical flags(nchan)
c
      real sum
      integer i

      sum = 0.0
      do i=0,nchan
         sum = sum + data(i)
      end do

      do i=0,nchan
         data(i) = data(i) / sum
      end do

      return
      end
