c***********************************************************************
      PROGRAM design
      IMPLICIT NONE
c-----------------------------------------------------------------------
c
c
c  History:
c    pjt   17jan92   Initial coding
c    pjt   19jan92   added 'p' - debugged some other
c    pjt   24jan92   allow # comments in pad file
c    arie  28jan92   fiddled with cellsize
c    pjt   29jan92   formalized cellsize/mapsize through 
c    pjt    1feb92   first export to Miriad users
c    mjs   02feb92   Eliminate unused vars to eliminate compiler warns
c    pjt   12mar92   Changed 'ds' to 'mirsao' and subsequent flags
c    pjt   13apr92   Some joker renamed restore to restor (cf. restore(8))
c          15apr92   formalized pgbegin+pgldev
c    mjs   13mar93   pgplot subr names have less than 7 chars; minor doc
c                    mod.
c    pjt   19apr93   changed to new calling sequence of mgetenv()
c    pjt   21may93   pgask
c    mjs   16jun93   Elim spurious compiler warning in "loadpad".
c    pjt   16jun93   Fixed up VERSION because of previous 'patch'
c     jm   03sep93   Made returned cursor lowercase, added server
c                    keyword (to override mirsao), and .
c     jm   14oct93   Modified call to uvtrack to reflect keyword change.
c     pjt  20jun98   EQ -> EQV for logical comparison (g77) 
c
c= design - Interactive array design, uv coverage and beam
c& pjt
c: general
c+
c     DESIGN is an interactive program that allows you to add
c     pads and populate them with antennae to a site of your 
c     selection.
c     For a selected design a synthesised beam is computed, and
c     the noise in the primary beam, exluding the central gaussian
c     part of the synthesised beam, is shown.
c
c     Commands in cursor mode are:
c
c         a   -- add an antenna (to this pad)
c         d   -- delete an antenna (from this pad)
c         p   -- add a new pad at this cursor position !!
c                (NOTE: Can't delete a pad position (*yet*)
c         c   -- check redundancy
c                (NOTE: not implemented yet)
c         x   -- execute a script to display uvcover and beam
c		 UVTRACK, UVCOVER, INVERT, IMPLOT, DS etc.
c         r   -- redraw screen
c         l   -- list all antennae
c         ?,h -- this help
c         q   -- quit
c         e   -- exit
c@ pad
c     Name of the input file with pad locations. 
c     The format of the text file is unformatted; the first two
c     columns are taken as the X and Y positions (a cartesion
c     system with origin at pad location 0N with units in Feet).
c     Default: $MIRCAT/hc.pad
c@ ary
c     The name of a file containing the antenna positions for a
c     particular array.  This file can be used to initially select
c     a grouping of antennas.
c     Note:  If this file contains multiple configurations of a
c     group of antennas, that some of the cross-correlations present
c     in this simulation will not really be present in real data.
c     Default: no antennas initially selected.
c@ antlist
c     List of antennae identifiers, numbered 1 through MAXPAD
c     to start the design with. Default: none supplied.
c@ device
c     PGPLOT graphics devices (two can be given):
c     The first one is the one to edit the pads, it better be
c     an interactive device. The second device is optional, and
c     will be the same as the first one if not supplied; it it
c     used for the spawned script, and does not have to be
c     an interactive device.
c  ** Note: The first device needs to be interactive device.
c@ minmax
c     Site Coverage, in feet, for displaying the data.
c     Four numbers need to be supplied: umin, umax, vmin, vmax. 
c     Default: -520,520,-20,600 (useful for the basic T at
c     Hat Creek).
c  ** Eventually we'll allow arbitrary units etc.
c@ vis
c     Output visibility dataset to be used. No default.
c     Maps and beams are stored as ``items'' within this dataset.
c  ** NOTE: If the dataset already existed, it will be deleted
c     without any user intervention using RMDATA.
c@ imsize
c     The size of the output image in pixels, for INVERT. Only one 
c     value can be given (i.e. a square image will be produced).
c     INVERT increases the sizes to the next power of two (if
c     they were not initially a power of 2). Default: 256.
c@ cell
c     Image cell size, in arcsec, for INVERT. Only one value can be
c     given. Default: 1.0
c@ box
c     Half the box size, in arcsec, that is used by HISTO to compute 
c     statistics of the gaussian subtracted dirty beam. Must be less
c     than half the product of CELL and IMSIZE of course.
c     Default: 64.
c< server
c     If this keyword is present, the server will be used to display the
c     beam; the Maryland specific task 'mirsao' will be used otherwise.
c-----------------------------------------------------------------------
      INCLUDE 'design.h'
      CHARACTER VERSION*(*)
      PARAMETER(VERSION='DESIGN: Version 20-jun-98')

      CHARACTER name*80, idevice*80, bdevice*80, chr*1, vis*80
      CHARACTER xlabel*16, ylabel*16, glabel*128
      CHARACTER aryfile*128, server*128
      LOGICAL more1, more2, more3, mode
      REAL    xpos, ypos, dist, umin, umax, vmin, vmax, cell, box
      INTEGER i, ix, iy, imsize
C      INTEGER i, ix, iy, xlo, xhi, ylo, yhi, imsize
      INTEGER nantlist, antlist(MAXPAD)
c
c  Externals
c
      EXTERNAL plotpad
      INTEGER len1, pgbeg
c-----------------------------------------------------------------------
c  Announce
      CALL output(VERSION)
c
c
c  Get user inputs
c
      CALL keyini
      CALL keyf('pad',name,' ')
      IF(name.EQ.' ')THEN
         CALL mgetenv(name,'MIRCAT')
         name = name(1:len1(name)) // '/hc.pad'
      ENDIF
      CALL keya('device',idevice,' ')
      CALL keya('device',bdevice,idevice)
      CALL keyf('vis',vis,' ')
      CALL keyr('minmax',umin,-520.0)
      CALL keyr('minmax',umax, 520.0)
      CALL keyr('minmax',vmin, -20.0)
      CALL keyr('minmax',vmax, 600.0)
      CALL mkeyi('antlist',antlist,MAXPAD,nantlist)
      CALL keyi('imsize',imsize,256)
      CALL keyr('cell',cell,1.0)
      CALL keyr('box',box,64.0)
      CALL keya('server',server,' ')
      CALL keyf('ary',aryfile,' ')
      CALL keyfin

c
c  Check user inputs and convert to internal units where needed
c
      CALL assertf(name,.TRUE.,
     *            'Input file does not exist; pad='//name)
      CALL assertl(idevice.NE.' ','No device name given; device=')
      CALL assertl(vis.NE.' ','Vis must be given; vis=')
      CALL assertl(box.LT.0.5*cell*imsize,
     *            'box must be small then 0.5*cell*imsize')
      IF (aryfile .NE. ' ') CALL assertf(aryfile,.TRUE.,
     *            'Input array file does not exist; ary='//aryfile)
c
c  Read pad positions
c
      CALL loadpad(name, MAXPAD, npad, xpad, ypad, used, id)
c
c  Initialize any initial antenna array.
c
      IF (aryfile .NE. ' ') THEN
        CALL loadary(aryfile, npad, xpad, ypad, used)
      ENDIF
c
c  Merge in any possible antennae from the user specified list
c
      DO i=1,nantlist
         IF(antlist(i).GE.0 .AND. antlist(i).LE.npad)THEN
            used(antlist(i)) = .TRUE.
         ELSE
            write(*,*) 'Warning: skipping invalid antenna ',antlist(i)
         ENDIF
      ENDDO
c
c  Graphics interaction loop
c
      IF(pgbeg(0, idevice, 1, 1).NE.1)THEN
         CALL pgldev
         CALL bug('f','Opening graphics device')
      ENDIF
      CALL pgask(.FALSE.)
      CALL winset(1,1)

      more1 = .TRUE.
      DOWHILE(more1)
         CALL winpick1(1,1)
         CALL winscalx(umin, umax)
         CALL winscaly(vmin, vmax)
         xlabel = 'East-West'
         ylabel = 'North'
         glabel = 'Hat Creek'
         more2 = .TRUE.
         DOWHILE(more2)
            CALL winshow(xlabel,ylabel,glabel,plotpad)
            more3 = .TRUE.
            DOWHILE(more3)
               CALL wincurs(ix,iy,xpos,ypos,chr)
               CALL lcase(chr)
               IF(ix.NE.1.OR.iy.NE.1) THEN
                  CALL output('Illegal ix/iy')
               ELSE IF(chr.EQ.'?' .OR. chr.EQ.'h') THEN
                  CALL help
               ELSE IF(chr.EQ.'r') THEN
                  more2 = .FALSE.
                  more3 = .FALSE.
               ELSE IF(chr.EQ.'q' .OR. chr.EQ.'e') THEN
                  more1 = .FALSE.
                  more2 = .FALSE.
                  more3 = .FALSE.
                  IF(chr.EQ.'q')THEN
                     CALL output('Abandoning ship, saving nothing')
                  ELSE
                     CALL output('Saving what need be saved')
                  ENDIF
               ELSE IF(chr.EQ.'d' .OR. chr.EQ.'a') THEN
                  mode = chr.EQ.'d'
                  CALL loadant(maxpad,npad,xpad,ypad,used,
     *                                nant,xant,yant,mode,idx)
                  IF(nant.GT.0)THEN
                     CALL winnear(ix,iy,xpos,ypos,nant,xant,yant,i,dist)
                     IF (i.GT.0) THEN
                        write(*,*) 'winnear: i=',i,' idx=',idx(i)
                        i = idx(i)
                        used(i) = .NOT. used(i)
                        CALL showpad(xpad(i),ypad(i),used(i))
                     ELSE
                        CALL output('ambiguous')
                     ENDIF
                  ELSE
                     CALL output('No more points left to select (a/d)')
                  ENDIF
               ELSE IF(chr.EQ.'.')THEN
                  DO i=1,npad
                     write (*,*) 'Antenna ',i,used(i)
                  ENDDO
                  CALL wintousr(ix,iy,xpos,ypos)
                  write(*,*) 'xpos,ypos=',xpos,ypos
               ELSE IF(chr.EQ.'l')THEN
                  DO i=1,npad
                     write (*,*) 'Antenna ',i,xpad(i),ypad(i),used(i)
                  ENDDO
               ELSE IF(chr.EQ.'c')THEN
                  CALL loadant(MAXPAD,npad,xpad,ypad,used,
     *                                nant,xant,yant,.TRUE.,idx)
                  CALL redun(MAXPAD,nant,xant,yant,idx)
               ELSE IF(chr.EQ.'x')THEN
                  CALL loadant(MAXPAD,npad,xpad,ypad,used,
     *                                nant,xant,yant,.TRUE.,idx)
                  CALL run(MAXPAD,nant,xant,yant,vis,bdevice,server,
     *                     imsize, cell, box)
                  CALL help
	       ELSE IF(chr.EQ.'p')THEN
                  CALL wintousr(ix,iy,xpos,ypos)
                  write(*,*) 'New pad position: ',xpos,ypos
                  npad = npad + 1
                  xpad(npad) = xpos
                  ypad(npad) = ypos
                  CALL showpad(xpad(npad),ypad(npad),.FALSE.)
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      
      CALL pgend
      END
c***********************************************************************
      SUBROUTINE help
c
      IMPLICIT NONE
c

      CALL output('a   -- add an antenna (to this pad)')
      CALL output('d   -- delete an antenna (from this pad)')
      CALL output('p   -- add a new pad at this cursor position !!')
      CALL output('       (NOTE: Can''t delete a pad position (*yet*)')
      CALL output('c   -- check redundancy')
      CALL output('       (NOTE: not implemented yet)')
      CALL output('x   -- execute script to display uvcov and beam')
      CALL output('       UVTRACK, UVCOVER, INVERT, IMPLOT, DS etc.')
      CALL output('r   -- redraw screen')
      CALL output('l   -- list all antennae')
      CALL output('?,h -- this help')
      CALL output('q   -- quit')
      CALL output('e   -- exit')

      END
c***********************************************************************
      SUBROUTINE plotpad (ix,iy)
c
      IMPLICIT NONE
      INTEGER ix,iy
c
c  Service routine called by WINTSHOW win(3MIR) package (win.for)
c  that does the actual drawing. Har Creek specific for now.
c-----------------------------------------------------------------------
      INCLUDE 'design.h'
c
c-
      INTEGER NROAD
      PARAMETER (NROAD=7)
      INTEGER i
      REAL xlo, xhi, ylo, yhi
      CHARACTER name*4
      REAL xroad(NROAD), yroad(NROAD)
      DATA xroad/160,312,452, 557, 567, 391, 251/
      DATA yroad/315,457,677,1050,1385,1652,1963/

c  get current extent of window anyhow
      CALL pgqwin( xlo, xhi, ylo, yhi)

c  always draw a box and the cross itself
      CALL pgbox( 'BCTS', 0.0, 0, 'BCTS', 0.0, 0 )
      CALL pgmove( -500.0,   0.0 )
      CALL pgdraw(  500.0,   0.0 )
      CALL pgmove(    0.0,   0.0 )
      CALL pgdraw(    0.0, 580.0 )

c  draw the old lab in color=4  (blue)   size=4.0
      CALL pgsch(4.0)
      CALL pgsci(4)

      CALL pgpt(1, 100.0, 260.0, 0)
c  draw the new lab in color=4  (blue)
      CALL pgsch(1.0)
      CALL pgsci(4)
      CALL pgmove(  80.0,  80.0 )
      CALL pgdraw(  80.0, 200.0 )
      CALL pgdraw( 140.0, 200.0 )
      CALL pgdraw( 140.0, 130.0 )
      CALL pgdraw( 200.0, 130.0 )
      CALL pgdraw( 200.0,  80.0 )
      CALL pgdraw(  80.0,  80.0 )

c  draw the road in color 11 , dashed though
      CALL pgsci(11)
      CALL pgsls(2)
      CALL pgline(NROAD,xroad,yroad)
      CALL pgsls(1)
      CALL pgsch(1.0)
CC      CALL pgtext(330.0,450.0,'(Fake Road)')
      CALL pgtext(330.0,450.0,'(Road)')

c  draw pad positions as squares (0) size=2.0 color=3 (green)
      CALL pgsch(1.5)
      CALL pgsci(3)
      IF(npad.GT.0) CALL pgpt(npad, xpad, ypad, 0)

c  draw antennae as open plusses   color=7 (yellow)
      CALL pgsci(7)
      CALL loadant(MAXPAD,npad,xpad,ypad,used,
     *                          nant,xant,yant,.TRUE.,idx)
      IF(nant.GT.0) CALL pgpt(nant, xant, yant, 14)

c Reset color for other drawing operations
      CALL pgsci(1)
      CALL pgsch(1.0)


      IF (.FALSE.) THEN
       DO i=1,npad
         name = id(i)
         IF(ypad(i).EQ.0.0) THEN
            CALL pgptxt(xpad(i), -10.0, 270.0, 0.0, name)
         ELSE
            CALL pgptxt(-10.0, ypad(i),   0.0, 1.0, name)
         ENDIF
       ENDDO
      ENDIF

      END
c***********************************************************************
      SUBROUTINE showpad(xpad,ypad,used)
      REAL xpad, ypad
      LOGICAL used

c      write(*,*) 'Showpad ',xpad,ypad,used
      CALL wincoord(1,1)
      CALL pgsch(1.5)
c
c first delete possible previous info
       CALL pgsci(0)
       CALL pgpt(1,xpad,ypad,14)
       CALL pgpt(1,xpad,ypad,0)
c
c then redraw point in the right color and size

      CALL pgsci(3)
      CALL pgpt(1,xpad,ypad,0)
      IF(used) THEN
         CALL pgsci(7)
         CALL pgpt(1,xpad,ypad,14)
      ENDIF

      CALL pgsci(1)
      CALL pgsch(1.0)
   
      END
c***********************************************************************
      SUBROUTINE loadpad(name, maxpad, npad, xpad, ypad, used, id)
      CHARACTER name*(*)
      INTEGER maxpad, npad
      REAL xpad(maxpad), ypad(maxpad)
      LOGICAL used(maxpad)
      CHARACTER id(maxpad)*(*)
c
c-----------------------------------------------------------------------
      INTEGER iostat, tno, linelen
      CHARACTER line*100, iname*4

      npad = 0

      CALL txtopen(tno,name,'old',iostat)
      DOWHILE(iostat.EQ.0)
         CALL txtread(tno,line,linelen,iostat)
         IF(iostat.EQ.0 .AND. line(1:1).NE.'#')THEN
            npad = npad + 1
            used(npad) = .FALSE.
            READ(line,*) xpad(npad),ypad(npad)
#ifdef 0
            IF(ypad(npad).EQ.0.0 .AND. xpad(npad).NE.0.0) THEN
               i = xpad(npad)
               IF(i.LT.0) THEN
                  write(iname,'(I3,A)') -i,'W'
               ELSE
                  write(iname,'(I3,A)') i,'E'
               ENDIF
            ELSE
               i = ypad(npad)
               write(iname,'(I3,A)') i,'N'
            ENDIF
#else
            iname = '*'
#endif
            id(npad) = iname
            WRITE(*,*) iname,' :',npad,' X,Y=',xpad(npad),ypad(npad)
         ENDIF
      ENDDO
      CALL txtclose(tno)

      END
c***********************************************************************
      SUBROUTINE loadant(maxpad,npad,xpad,ypad,used,
     *                          nant,xant,yant,mode,idx)
      INTEGER maxpad, npad, nant, idx(maxpad)
      REAL xpad(maxpad), ypad(maxpad), xant(maxpad), yant(maxpad)
      LOGICAL mode, used(maxpad)
c
c-----------------------------------------------------------------------
      INTEGER i

      nant = 0
      DO i=1, npad
         IF(used(i).EQV.mode) THEN
            nant = nant + 1
            xant(nant) = xpad(i)
            yant(nant) = ypad(i)
            idx(nant) = i
         ENDIF
      ENDDO

      write(*,*) 'loadant: selected ',nant
      write(*,*) 'idx=',(idx(i),i=1,nant)

      END
c***********************************************************************
      SUBROUTINE BatCurs( nx, ny, px, py, c )
c
      IMPLICIT NONE
      REAL      px, py
      INTEGER   nx, ny
      CHARACTER c*1
c
c  Fake cursor in batch mode
c-----------------------------------------------------------------------


c for now just exit; no batching possible

      c = 'e'

      END
c***********************************************************************
      SUBROUTINE redun(maxant,nant,xant,yant,idx)
      INTEGER maxant,nant,idx(maxant)
      REAL xant(maxant), yant(maxant)
c-----------------------------------------------------------------------
      IF(nant.LT.3) THEN
         CALL output('Not enough antennae for redundant baselines')
         RETURN
      ENDIF

      write(*,*) 'EW REDUNDANCY CHECK: *** not implemented yet ***'
      write(*,*) 'NS REDUNDANCY CHECK: *** not implemented yet ***'

      END
c***********************************************************************
      SUBROUTINE run(maxant,nant,xant,yant,vis,device,server,
     *                     imsize, cell, box)
      INTEGER maxant, nant, imsize
      REAL xant(maxant), yant(maxant), cell, box
      CHARACTER vis*(*), device*(*), server*(*)
c
      CHARACTER cmd*256, line*256, rtoaf*10, bmin*10, bmax*10
      CHARACTER sizestr*10, cellstr*10, itoaf*10
      INTEGER tno, i, len1, iostat

      IF(nant.LT.2) THEN
         CALL output('Not enough antennae for an interferometer')
         RETURN
      ENDIF

      write(*,*) 'PREPARING FOR MIRIAD RUN: Selected #ants = ',nant
   
      bmin=rtoaf(-0.5*box,1,1)
      bmax=rtoaf(0.5*box,1,1)
      cellstr = rtoaf(cell,1,1)
      sizestr = itoaf(imsize)

c  Write the 'ary' file for UVTRACK
      CALL txtopen(tno,'tmp.ary','new',iostat)
      WRITE(line,'(A)') '  TMP.ARY'
      CALL txtwrite(tno,line,len1(line),iostat)
      WRITE(line,'(A,I2)')  '1,',nant
      CALL txtwrite(tno,line,len1(line),iostat)
      DO i=1,nant
         WRITE(line,'(F8.1,A,F8.1)') xant(i),',',yant(i)
         CALL txtwrite(tno,line,len1(line),iostat)
      ENDDO
      CALL txtclose(tno)

c  Write all commands to a script to be executed

      CALL txtopen(tno,'tmp.csh','new',iostat)

c
c There is no 'clean' way in MIRIAD to spawn processed (as if the
c following method was really dirty). What we do here is writing
c a shell script (It should even work in VMS, not tested though)
c
      
c RMDATA

      WRITE(cmd,'(A,A)')
     *      ' rmdata in=',
     *      vis(1:len1(vis))
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)


c UVTRACK

      WRITE(cmd,'(A,A,A)')
     *      ' uvtrack mode=batch ary=tmp.ary', 
     *      ' out=',
     *      vis(1:len1(vis))
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c UVCOVER

      WRITE(cmd,'(A,A,A,A,A)')
     *      ' uvcover vis=',
     *      vis(1:len1(vis)),
     *      ' device=',
     *      device(1:len1(device)),
     *      ' &'
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c INVERT

      WRITE(cmd,'(A,A,A,A,A,A,A,A,A,A)')
     *      ' invert vis=',
     *      vis(1:len1(vis)),
     *      ' map=',
     *      vis(1:len1(vis)),
     *      '/map beam=',
     *      vis(1:len1(vis)),
     *      '/beam imsize=',
     *      sizestr(1:len1(sizestr)),
     *      ' cell=',
     *      cellstr(1:len1(cellstr))
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c IMPLOT

      WRITE(cmd,'(A,A,A,A,A)')
     *      ' implot in=',
     *      vis(1:len1(vis)),
     *      '/beam device=',
     *      device(1:len1(device)),
     *      ' units=s conflag=p &'
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c TVDISP or MIRSAO (display program - only in Maryland)

      IF (server .ne. ' ') THEN
        WRITE(cmd,'(A,A,A,A,A)')
     *      ' tvdisp in=',
     *      vis(1:len1(vis)),
     *      '/beam server=',
     *      server(1:len1(server)),
     *      ' range=-0.1,1 &'
      ELSE
        WRITE(cmd,'(A,A,A)')
     *      ' mirsao ',
     *      vis(1:len1(vis)),
     *      '/beam -rmin -0.1 -rmax 1 &'
      ENDIF
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c CLEAN

      WRITE(cmd,'(A,A,A,A,A,A,A)')
     *      ' clean map=',
     *      vis(1:len1(vis)),
     *      '/beam beam=',
     *      vis(1:len1(vis)),
     *      '/beam out=',
     *      vis(1:len1(vis)),
     *      '/beam.cc niters=1 gain=1'
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c RESTOR(E)

      WRITE(cmd,'(A,A,A,A,A,A,A,A,A)')
     *      ' restor map=',
     *      vis(1:len1(vis)),
     *      '/beam beam=',
     *      vis(1:len1(vis)),
     *      '/beam model=',
     *      vis(1:len1(vis)),
     *      '/beam.cc out=',
     *      vis(1:len1(vis)),
     *      '/beam.conv mode=convolve'
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c MATHS

      WRITE(cmd,'(A,A,A,A,A,A,A)')
     *      ' maths ''exp=<',
     *      vis(1:len1(vis)),
     *      '/beam>-<',
     *      vis(1:len1(vis)),
     *      '/beam.conv>'' out=',
     *      vis(1:len1(vis)),
     *      '/beam.diff'
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)

c HISTO

      WRITE(cmd,'(A,A,A,A,A,A,A,A,A,A,A)')
     *      ' histo in=',
     *      vis(1:len1(vis)),
     *      '/beam.diff ''region=arcsec,box(',
     *      bmin(1:len1(bmin)),
     *      ',',
     *      bmin(1:len1(bmin)),
     *      ',',
     *      bmax(1:len1(bmax)),
     *      ',',
     *      bmax(1:len1(bmax)),
     *      ')'''
      CALL mkcmd(cmd)
      CALL output('MIRIAD: '//cmd)
      CALL txtwrite(tno,cmd,len1(cmd),iostat)
c
      CALL txtclose(tno)
c
#ifdef vms
      CALL command('@tmp.csh')
#else
      CALL command('csh -f tmp.csh')
#endif
c
      END
c***********************************************************************
      SUBROUTINE mkcmd(cmd)
      CHARACTER cmd*(*)

#ifdef vms
      IF(cmd(1:1).EQ.' ') THEN
        cmd(1:1) = '$'
      ELSE
        CALL bug('f','Cannot construct VMS command; need extra space')
      ENDIF
#endif
      END
c***********************************************************************
      SUBROUTINE loadary(aryfile, npad, xpad, ypad, used)
      CHARACTER aryfile*(*)
      INTEGER npad
      REAL xpad(*), ypad(*)
      LOGICAL used(*)
c
c  EPS is set to 5 feet.  Any antenna position within 5 feet in both
c  the X and Y directions is considered a match.
c
      REAL EPS
      PARAMETER (EPS = 5.0)
c
      CHARACTER line*100
      INTEGER i
      INTEGER iostat, tno, linelen
      INTEGER nconfig, nant
      REAL xp, yp, delx, dely
      LOGICAL name, config
c
c  ARY files are assumed to have a format where the first valid line
c  contains the name of the array and the second line the number of
c  configurations and the number of antennas.  Subsequent valid lines
c  have the (X,Y) positions of the antenna.
c
      nconfig = 0
      nant = 0
      name = .FALSE.
      config = .FALSE.
      CALL txtopen(tno, aryfile, 'old', iostat)
c
      DOWHILE (iostat .EQ. 0)
        CALL txtread(tno, line, linelen, iostat)
        IF ((iostat .EQ. 0) .AND. (line(1:1) .NE. '#')) THEN
          IF (.NOT. name) THEN
            name = .TRUE.
          ELSEIF (.NOT. config) THEN
            config = .TRUE.
            READ(line, *) nconfig, nant
            IF (nconfig .LE. 0) THEN
              CALL bug('w',
     *          'Incorrectly formatted array file; file ignored.')
              iostat = 1
            ENDIF
          ELSE
            READ(line, *) xp, yp
            DO i = 1, npad
              delx = ABS(xp - xpad(i))
              dely = ABS(yp - ypad(i))
              IF ((delx .LE. EPS) .AND. (dely .LE. EPS)) THEN
                used(i) = .TRUE.
              ENDIF
            ENDDO
          ENDIF
        ENDIF
      ENDDO
c
      CALL txtclose(tno)
c
c  Warn the user if there are more than one configuration in this
c  antenna array file.
c
      IF (nconfig .GT. 1) THEN
        WRITE(line, '(A,I3,A)') 'Additional configurations [', nconfig,
     *    '] will generate artificial correlations.'
        CALL bug('w', line)
      ENDIF
      END
c***********************************************************************
