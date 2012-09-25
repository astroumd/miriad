c***********************************************************************
      program sinbad
      implicit none
c
c= sinbad - Calculate Tsys*(on-off)/off*  for autocorrelation data.
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
c       Normally the "on" uv variable is used to find out which record
c       is the ON (on=1) or OFF (on=0) record. You can override this
c       by supplying two source names using the onoff= keyword
c       For baseline subtraction, see:  SINPOLY
c       For single dish mapping, see:  VARMAPS
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
c@ tsys
c       Value for flat tsys spectrum if neither band average systemp 
c       nor full spectrum is available.
c@ onoff
c       Sourcenames for the on=1 and on=0 (off) positions. This will
c       override the use of the on uv variable, which is the default.
c       Default: not used.
c@ options 
c       Different computational output options (mainly for debugging).
c       Exclusively one of the following (minimum match):
c         'spectrum'     Compute Tsys*(on-off/off).  This is the default
c         'difference'   Compute (on-off)
c         'ratio'        Compute on/off
c         'on'           Output (on)
c         'off'          Output (off)
c@ slop
c       Allow some fraction of channels bad for accepting
c       Default: 0
c@ repair
c       A list of bad channels (birdies) that need to be repaired by
c       interpolating accross them.
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

      include 'maxdim.h'
      character version*80,versan*80
      integer maxsels
      parameter(maxsels=1024)
c     
      real sels(maxsels)
      real start,step,width,tsys1,slop
      character linetype*20,vis*128,out*128
      character srcon*16, srcoff*16, src*16
      complex data(maxchan)
      logical flags(maxchan)
      logical first,new,dopol,PolVary,doon,dosrc
      integer lIn,lOut,nchan,npol,pol,SnPol,SPol,on,i,j,ant
      character type*1, line*128
      integer length 
      logical updated
c     what the heck is this trick to read the preamble(4) or preamble(5)
      double precision uin,vin,timein,basein
      common/preamb/uin,vin,timein,basein
c     
      complex off(MAXCHAN,MAXANT)
      real    tsys(MAXCHAN,MAXANT)
      logical oflags(MAXCHAN,MAXANT)
      integer num,   non,   noff,   ntsys
      data    num/0/,non/0/,noff/0/,ntsys/0/
      logical spectrum, diffrnce, ratio, have_ant(MAXANT), rant(MAXANT)
      logical allflags,debug,qon,qoff
c     
c  Read the inputs.
c
      version = versan('sinbad',
     *     '$Revision$',
     *     '$Date$')
      
      call bug('i','New caching of OFF positions')
      
      call keyini
      call getopt(spectrum,diffrnce,ratio,qon,qoff)
      call keyf('vis',vis,' ')
      call SelInput('select',sels,maxsels)
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
      call keyfin
c     
c     Check user inputs.
c     
      if(vis.eq.' ')call bug('f','Input file name (vis=) missing')
      if(out.eq.' ')call bug('f','Output file name (out=) missing')
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
c but this is a little more obvious
c
      if( ( spectrum .eqv. .false. ) .and.
     *     ( diffrnce .eqv. .false. ) .and.
     *     ( qon .eqv. .false. ) .and.
     *     ( qoff .eqv. .false. ) .and.
     *     ( ratio    .eqv. .false. ) ) then
         spectrum = .true.
      endif
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
     *     call uvset(lIn,'data',linetype,nchan,start,width,step)
      call VarInit(lIn,'channel')
      do j=1,MAXANT
         do i=1,MAXCHAN
            tsys(i,j) = tsys1
         enddo
         have_ant(j) = .FALSE.
         rant(j) = .TRUE.
      enddo
c     
c  Scan the file once and pre-cache the OFF positions
c     
      call uvread(lIn,uin,data,flags,maxchan,nchan)
      do while (nchan.gt.0)
         if (dosrc) then
            call uvgetvra(lIn,'source',src)
            write(*,*) "source: ",src
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
            if (debug) write(*,*) 'Reading off ant ',
     *           ant,on,have_ant(ant)
            if (allflags(nchan,flags,slop)) then
               if (.not.have_ant(ant)) then
                  if(debug)write(*,*) 'Saving off ant ',ant
                  have_ant(ant) = .TRUE.
                  do i=1,nchan
                     off(i,ant) = data(i)
                     oflags(i,ant) = flags(i)
                  enddo
               endif
            endif
         endif
         call uvread(lIn,uin,data,flags,maxchan,nchan)
      end do

      call uvrewind(lIn)
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
      if (tsys1.lt.0.0) call getwtsys(lIn,tsys,MAXCHAN,MAXANT)
      
c
c  Loop through the data, writing (ON-OFF)/OFF*TSYS
c
      do while (nchan.gt.0)
         num = num + 1
c     print *, num,basein,basein/256
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
         call VarCopy(lIn,lOut)
c
c  Now process the data.
c
         if(doon)then
            if (dosrc) then
               call uvgetvra(lIn,'source',src)
               if (src.eq.srcon) then
                  on=1
               else if (src.eq.srcoff) then
                  on=0
               else
                  on=-1
               endif
               write(*,*) 'source: ',src,on
            else
               call uvgetvri(lIn,'on',on,1)
            endif
            ant = basein/256
            if(on.eq.0)then
               if (allflags(nchan,flags,slop)) then
                  noff = noff + 1
                  do i=1,nchan
                     off(i,ant) = data(i)
                     oflags(i,ant) = flags(i)
                  enddo
               endif
            else if(on.eq.-1)then
               if (allflags(nchan,flags,slop)) then
                  ntsys = ntsys + 1
                  do i=1,nchan
                     tsys(i,ant) = data(i)
                     oflags(i,ant) = flags(i)
                  enddo
               endif
            else if(on.eq.1)then
               if (have_ant(ant)) then
                  if (noff.eq.0) call bug('f','No OFF before ON found')
                  if (ntsys.eq.0 .and. tsys1.lt.0.0)
     *                 call getwtsys(lIn,tsys,MAXCHAN,MAXANT) 
                  non = non + 1
                  if(spectrum) then
                     do i=1,nchan
                        data(i) = tsys(i,ant)*(data(i)/off(i,ant)) - 1.0
                        flags(i) = flags(i).AND.oflags(i,ant)
                     enddo
                  else if(diffrnce) then
                     do i=1,nchan
                        data(i) = data(i)-off(i,ant)
                        flags(i) = flags(i).AND.oflags(i,ant)
                     enddo
                  else if(ratio) then
                     do i=1,nchan
                        data(i) = data(i)/off(i,ant)
                        flags(i) = flags(i).AND.oflags(i,ant)
                     enddo
                  else if(qon) then
                     do i=1,nchan
                        flags(i) = flags(i).AND.oflags(i,ant)
                     enddo
                  else if(qoff) then
                     do i=1,nchan
                        data(i) = off(i,ant)
                        flags(i) = flags(i).AND.oflags(i,ant)
                     enddo
                  endif
                  call uvwrite(lOut,uin,data,flags,nchan)
               else
c                 only rant about an antenna once in their lifetime
                  if (rant(ant)) then
                     write(line,
     *                 '(''Did not find valid scan for ant '',I2)') ant
                     call bug('w',line)
                     rant(ant) = .FALSE.
                  endif
               endif
            else
               call bug('w','value of on not 1, 0 or -1')
            endif
         endif
c     
c     Loop the loop.
c     
         call uvread(lIn,uin,data,flags,maxchan,nchan)
      enddo
c     
      print *,'records read: ',num
      print *,'records read: on:',non,'  off:',noff,'  tsys:',ntsys
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
      
      if (ntsys.eq.0) then
         if (tsys1.lt.0.0) then
            call bug('w','No Tsys data on=-1 found, used systemp')
         else
            call bug('w','No Tsys data on=-1 found, used default tsys=')
         endif
      endif
      
c     
c  Close up shop.
c
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
         
      endif
      
      end
c-----------------------------------------------------------------------
c     Get the various (exclusive) options
c     
      subroutine getopt(spectrum,diffrnce,ratio,qon,qoff)
      implicit none
      logical spectrum, diffrnce, ratio, qon,qoff
c     
      integer nopt
      parameter(nopt=5)
      character opts(nopt)*10
      logical present(nopt)
      data opts/'spectrum  ','difference','ratio    ',
     *          'on        ','off       '/
      call options('options',opts,present,nopt)
      spectrum = present(1)
      diffrnce = present(2)
      ratio    = present(3)
      qon      = present(4)
      qoff     = present(5)
      end

      subroutine uvrepair(nchan,data,flags)
      integer nchan
      complex data(nchan)
      logical flags(nchan)

      write(*,*) 'REPAIR',data(79),data(80),data(81)

      return
      end

