      program mafia
      implicit none
      include 'maxfld.h'      
c-----------------------------------------------------------------------
c= mafia - determine the number of mask fields in a map and remove them
c& fkbn
c: map analysis, map manipulation
c+
c     MaFiA (MAsk FIeld Algorithm)  determines the number of mask fields
c     (unconnected unmasked areas) in an image or cube.
c     You may also specify various cutoff criteria  concerning different
c     properties  of the mask fields.  Fields  that do not  fulfil these
c     criteria will not be displayed. Moreover, there is the possibility
c     to 'mask away'  these  negligible  fields  using  the options=mask
c     directive.
c
c     Using MaFiA does only make sense for maps containing  a mask item.
c     This mask item can be customized  with the task IMMASK or computed
c     using MATHS' mask-option.
c
c@ in
c	The input image. No deufault.
c@ template
c	If a template image is given, only mask fields that overlap with
c       a mask field  in the template  will be taken into account.  Both
c       cubes must have identical dimensions.
c       The template image will NOT be ALTERED.
c@ plane
c	For data cubes, you can specify the plane to be examined. If not
c       given, all planes will be examined (necessary for options=3dim).
c@ cutmode
c	Determines  whether fields with values greater than (GT) or less
c	than (LT) the given cutoffs are neglected. Default is LT.
c
c@ fields
c	Only show fields with given index numbers. ONLY ONE NUMBER...
c
c Following are cutoff criteria for different properties of mask fields.
c If a mask field fails to fulfil these conditions, it is not taken into
c account. If not given, the respective cutoff is not applied.
c@ pixels
c	Number of pixels
c@ flux
c	Sum of pixel values
c@ intens
c	Average pixel value
c@ peak
c	Value of the brightest pixel
c
c
c Following are even more cutoff conditions, but these are applied after
c the others in the STATS phase. Thus they work only with options=stats.
c@ m1
c	Moment M1: M1 = m_20 + m_02
c	Moments of inertia: m_ij = sum((x - <x>)**i * (y - <y>)**j)
c@ m2
c	Moment M2: M2 = (m_20 - m_02)**2 + 4 * m_11**2
c@ ell
c	Ellipticity: ell = (M1+sqrt(M2)) / (M1-sqrt(M2))
c@ faint
c	'Faintension', a measure for faint extended emission:
c	F = (ell*M2) / (peak*1E10)
c
c@ options
c	There are several modes concerning  the mask field detection and
c	output behaviour. You may combine them (separated by commas):
c	  mask   Mask fields that do not fulfil the cutoff criteria will
c	         be 'masked away'. Use this mode to APPLY CHANGES to the
c                mask information stored in the input file.
c	  blink  Fields without an overlapping relative in the preceding
c	         or following  plane of the data cube will be classified
c	         as negligible regardless of their pixel number.
c	         Works only with options=3dim.
c	  3dim   Do not evaluate  the planes  of a data cube seperately,
c	         but treat fields as 3D objects. Requires plane=0.
c	  stats  Compute some statistics.  This includes  values derived
c	         from the moments of inertia  and an 8-bin histogram  of
c	         the brightness distribution.
c	  brief  Only display overall results.
c
c--
c
c  History:
c     fkbn 08sep04 Original version
c     fkbn 03dec04 Revised version with proper 3D support
c     fkbn 08jun05 Write 3D fields to scratch file for extreme speed-up,
c                  Template comparison, Statistics and new cutoffs
c     gjdw 09jun11 Replaced MAXDIM by MAXSIM in mafia.for and maxfld.h
c
c-----------------------------------------------------------------------
c
c variable declarations
c
c     file handles for in=, template= and scratch file      
      integer limg, ltpl/1/, lscr
c
c     axis sizes, planes to process
      integer axize(MAXNAX), planes(2)
c
c     field index of field to show
      integer idx
c
c     cutoff conditions
      integer pixels
      real    intens, flux, peak, mom1, mom2, ellipti, faint
c      
c     array containing information about the given options      
      logical modus(7)
c     1: options=mask
c     2: options=blink
c     3: options=3dim
c     4: options=brief
c     5: template given
c     6: options=stats
c     7: cutoff mode: .true.  mask values less than the given cutoffs
c                     .false. mask values greater than the given cutoffs
c      
c     buffers for reading (mask-, image-) data from files
      logical maskval(MAXSIM),tplval(MAXSIM)
      real    pixval(MAXSIM)
c
c     identifiers of adjacent fields
      integer fieldnos(2)
c
c     running variables: plane, field identifier, coordinates
      integer plane, i, x, y
c
c     data storage for mask field analysis
      integer Ary(MAXSIM*MAXSIM), Fields(MAXFLD), maxFields,
     +        SumXYZ(MAXFLD,9)
      real    Flxs(MAXFLD), Pks(MAXFLD)
      logical FieldRep(MAXFLD)
c
c     variables needed for 3D subroutines
      integer Ary3D(MAXSIM*MAXSIM), Fields3D(MAXFLD), maxFields3D,
     +        SumXYZ3D(MAXFLD,9)
      real    Flxs3D(MAXFLD), Pks3D(MAXFLD)
      logical FieldRep3D(MAXFLD)/MAXFLD*.false./
c
c version
c
      character version*50 /'MaFiA: version 08-jun-05'/
      call output(version)
c
c-----------------------------------------------------------------------
c
c get inputs, open necessary files
c
      call handleInputs(limg, ltpl, axize, planes, modus, pixels, flux,
     +           intens, peak, mom1, mom2, ellipti, faint, idx)
      if ((modus(1).or.modus(6)).and.modus(3)) then
        lscr = 42
        open(lscr, status='SCRATCH', access='DIRECT',
     +       recl=4*axize(1)*axize(2), form='UNFORMATTED')
      end if
c
c-----------------------------------------------------------------------
c
c----- begin plane loop -----
c
      do plane=planes(1),planes(2)
        call xysetpl(limg, 1, plane)
        if (modus(5)) call xysetpl(ltpl, 1, plane)
c 
c reset list variables
c
	do i=1,MAXFLD
          Fields(i)=0
          FieldRep(i)=.false.
        end do
        maxFields=0
c
c-----------------------------------------------------------------------
c
c pixel loop: process Ary
c
        do y=1,axize(2)
          call xyflgrd(limg, y, maskval)
          if (modus(5)) call xyflgrd(ltpl, y, tplval)
          call xyread(limg, y, pixval)
          do x=1,axize(1)
            if (.not.maskval(x)) then
              Ary(x+(y-1)*axize(1))=0
            else
              call adjacentFields(Ary, x, y, fieldnos, axize)
              call handleFields(axize,plane,Ary,x,y,pixval,fieldnos,
     +             Fields,Flxs,Pks,SumXYZ,maxFields,tplval,FieldRep)
            end if
          end do
        end do
c
c-----------------------------------------------------------------------
c
c do 3D evaluation of actual plane
c
        if (modus(3)) then
          call evaluate3D(axize, plane, planes, modus, lscr,
     +    Ary,  Fields,  Flxs,  Pks,  SumXYZ,  maxFields,  FieldRep,
     +    Ary3D,Fields3D,Flxs3D,Pks3D,SumXYZ3D,maxFields3D,FieldRep3D)
c
        else
c
c perform 2D field handling, output, masking
c
          call handleOutput(plane, modus, Fields, Flxs, Pks, SumXYZ,
     +         maxFields, FieldRep, pixels, flux, intens, peak, idx)
  
          if (modus(6)) call stats(limg, lscr, axize, planes, modus,Ary,
     +    Fields, Flxs, Pks, SumXYZ, maxFields, mom1,mom2,ellipti,faint)
          if (modus(1)) call mask(limg, lscr, axize, planes, modus,
     +                            Ary, Fields)
c  
        end if
c
      end do
c
c----- end plane loop -----
c
c-----------------------------------------------------------------------
c
c perform 3D field handling, output, masking
c
      if (modus(3)) then
c
        call handleOutput(plane,modus,Fields3D,Flxs3D,Pks3D,SumXYZ3D,
     +       maxFields3D, FieldRep3D, pixels, flux, intens, peak, idx)
c
        if (modus(6)) call stats(limg, lscr, axize, planes, modus,
     +     Ary3D, Fields3D, Flxs3D, Pks3D, SumXYZ3D, maxFields3D,
     +     mom1, mom2, ellipti, faint)
c
        if (modus(1)) call mask(limg, lscr, axize, planes, modus,
     +                          Ary3D, Fields3D)
      end if
c
c-----------------------------------------------------------------------
c
c write history information
c
      if (modus(1)) then
        call hisopen(limg,'append')
        call hiswrite(limg,'MaFiA: Miriad '//version)
        call hisinput(limg,'MaFiA:')
        call hisclose(limg)
      end if
c
c close file(s) and quit
c
      call xyclose(limg)
      if ((modus(1).or.modus(6)).and.modus(3)) close(lscr)
      if (modus(5)) call xyclose(ltpl)
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine handleInputs(limg, ltpl, axize, planes, modi, pCut,
     +           fCut, iCut, mCut, m1Cut, m2Cut, elliCut, eCut, idx)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     read user inputs and conduct consistency check
c-----------------------------------------------------------------------
c
      character in*80, mode(4)*5, template*80, cutoffmode*2
      integer limg, ltpl, axize(MAXNAX), planes(2), pCut, defpCut, idx,i
      real fCut, iCut, mCut, eCut, elliCut, m1Cut, m2Cut, defaultCut
      logical modi(7), hdprsnt
c
c gather inputs
c
      call keyini
      call keya ('in', in, ' ')
      call keya ('template', template, ' ')
      call keya ('cutmode', cutoffmode, ' ')
      call keyi ('plane', planes(1), 0)
      do i=1,5
        call keya ('options', mode(i), ' ')
      end do
c
c determine cutoff mode and adjust cutoffs
c maximal values for integer*4 and real*4 are used
c
      if ((cutoffmode.eq.'GT').or.(cutoffmode.eq.'gt')) then
        modi(7)=.false.
        defaultCut = 3.402823E+38
	defpCut = 2147483647
      else
        if ((cutoffmode.ne.'LT').and.(cutoffmode.ne.'lt').and.
     +      (cutoffmode.ne.' '))
     +     call bug ('w','Ignored unknown cutoffmode setting')
        modi(7)=.true.
        defaultCut = -3.402823E+38
	defpCut = -2147483647
      end if
c
c continue gathering inputs
c
      call keyi ('pixels', pCut, defpCut)
      call keyr ('flux', fCut, defaultCut)
      call keyr ('intens', iCut, defaultCut)
      call keyr ('peak', mCut, defaultCut)
      call keyr ('m1', m1Cut, defaultCut)
      call keyr ('m2', m2Cut, defaultCut)
      call keyr ('ell', elliCut, defaultCut)
      call keyr ('faint', eCut, defaultCut)
      call keyi ('fields', idx, 0)      
      call keyfin
c
c check for in= keyword
c
      if (in.eq.' ') call bug ('f', 'Input file name not given')
c
c set modi array according to inputs
c
      do i=1,6
        modi(i)=.false.
      end do
      if (template.ne.' ') modi(5)=.true.
c
      do i=1,5
        if (mode(i).eq.'mask') then
          modi(1)=.true.
        else if (mode(i).eq.'blink') then
          modi(2)=.true.
        else if (mode(i).eq.'3dim') then
          modi(3)=.true.
	else if (mode(i).eq.'brief') then
          modi(4)=.true.
	else if (mode(i).eq.'stats') then
          modi(6)=.true.
        else if (mode(i).ne.' ') then
          call bug ('w','Ignored an unknown mode command')
        end if
      end do
c
c open the input image
c
      call xyopen(limg,in,'old',MAXNAX,axize)
      if (modi(5)) call xyopen(ltpl,template,'old',MAXNAX,axize)
c
c check inputs
c
      if (.not.hdprsnt(limg,'mask'))
     +  call bug ('f', 'Input file does not contain a mask item')
      if (modi(5).and..not.hdprsnt(ltpl,'mask'))
     +  call bug ('f', 'Template file does not contain a mask item')
      if ((planes(1).lt.0).or.(planes(1).gt.axize(3)))
     +  call bug ('f', 'The given plane does not exist')
      if ((planes(1).ne.0).and.(modi(3)))
     +  call bug ('f', '3dim-mode needs plane=0')
      if ((axize(3).eq.1).and.(modi(2))) then
        call bug ('w', 'There is only one plane: blink-mode turned off')
        modi(2) = .false.
      end if
      if ((axize(3).eq.1).and.(modi(3))) then
        call bug ('w', 'There is only one plane: 3dim-mode turned off')
        modi(3) = .false.
      end if
c
c set first and last plane
c
      if (planes(1).eq.0) then
        planes(1)=1
        planes(2)=axize(3)
      else
        planes(2)=planes(1)
      endif
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine handleFields(axize,plane,A,x,y,pixval,fn,F,
     +                        Flux,Peak,SXYZ,maxF,tplval,FieldRep)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     react to existence of adjacent fields: create new, expand or merge
c-----------------------------------------------------------------------
c
      integer axize(MAXNAX),A(MAXSIM*MAXSIM), i,j,x,y, fn(2),plane,
     +        F(MAXFLD),maxF, SXYZ(MAXFLD,9), pos
      real pixval(MAXSIM), Flux(MAXFLD), Peak(MAXFLD)
      logical tplval(MAXSIM),FieldRep(MAXFLD)
c
      if (fn(1).eq.0) then
c--- create a new field ---
        i=1
        do while (F(i).ne.0)
          i=i+1
          if (i.gt.MAXFLD)
     +      call bug('f','Too many fields: increase MAXFLD in maxfld.h')
        end do
        A(x+(y-1)*axize(1))=i
        F(i)=1
        if (tplval(x)) FieldRep(i)=.true.
        Flux(i)=pixval(x)
        Peak(i)=pixval(x)
	SXYZ(i,1)=x
	SXYZ(i,2)=y
	SXYZ(i,3)=plane
	SXYZ(i,4)=x
	SXYZ(i,5)=y
	SXYZ(i,6)=plane
	SXYZ(i,7)=x
	SXYZ(i,8)=y
	SXYZ(i,9)=plane
        if (i.gt.maxF) maxF=i
      else if (fn(2).eq.0) then
c--- expand an existing field ---
        A(x+(y-1)*axize(1))=fn(1)
        F(fn(1))=F(fn(1))+1
        if (tplval(x)) FieldRep(fn(1))=.true.
        Flux(fn(1))=Flux(fn(1))+pixval(x)
	Peak(fn(1))=max(Peak(fn(1)),pixval(x))
	SXYZ(fn(1),1)=SXYZ(fn(1),1)+x
	SXYZ(fn(1),2)=SXYZ(fn(1),2)+y
	SXYZ(fn(1),3)=SXYZ(fn(1),3)+plane
	SXYZ(fn(1),4)=min(SXYZ(fn(1),4),x)
	SXYZ(fn(1),5)=min(SXYZ(fn(1),5),y)
	SXYZ(fn(1),6)=min(SXYZ(fn(1),6),plane)
	SXYZ(fn(1),7)=max(SXYZ(fn(1),7),x)
	SXYZ(fn(1),8)=max(SXYZ(fn(1),8),y)
	SXYZ(fn(1),9)=max(SXYZ(fn(1),9),plane)
      else
c--- merge two existing fields ---
        pos = x+(y-1)*axize(1)
	A(pos)=fn(2)
        F(fn(2))=F(fn(2))+F(fn(1))+1
        if (tplval(x)) FieldRep(fn(2))=.true.
        if (FieldRep(fn(1))) FieldRep(fn(2))=.true.
        Flux(fn(2))=Flux(fn(2))+Flux(fn(1))+pixval(x)
        Peak(fn(2))=max(Peak(fn(2)),Peak(fn(1)),pixval(x))
	SXYZ(fn(2),1)=SXYZ(fn(2),1)+SXYZ(fn(1),1)+x
	SXYZ(fn(2),2)=SXYZ(fn(2),2)+SXYZ(fn(1),2)+y
	SXYZ(fn(2),3)=SXYZ(fn(2),3)+SXYZ(fn(1),3)+plane
	SXYZ(fn(2),4)=min(SXYZ(fn(2),4),SXYZ(fn(1),4),x)
	SXYZ(fn(2),5)=min(SXYZ(fn(2),5),SXYZ(fn(1),5),y)
	SXYZ(fn(2),6)=min(SXYZ(fn(2),6),SXYZ(fn(1),6),plane)
	SXYZ(fn(2),7)=max(SXYZ(fn(2),7),SXYZ(fn(1),7),x)
	SXYZ(fn(2),8)=max(SXYZ(fn(2),8),SXYZ(fn(1),8),y)
	SXYZ(fn(2),9)=max(SXYZ(fn(2),9),SXYZ(fn(1),9),plane)
        F(fn(1))=0
        FieldRep(fn(1))=.false.
        Flux(fn(1))=0
	Peak(fn(1))=0
	do i=1,9
          SXYZ(fn(1),i)=0
	end do
c Find a WORKAROUND here, maybe also -fielnr flagging,
c because this loop SLOWs things down
	do i=1,axize(1)*axize(2)
          if (A(i).eq.fn(1)) A(i)=fn(2)
          if (i.eq.pos) goto 1
        end do
1       continue
      end if
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine adjacentFields(A, x, y, fn, axize)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     detect Fields adjacent to (x, y) and write their ID's to fn
c-----------------------------------------------------------------------
c
      integer x,y,axize(MAXNAX),A(MAXSIM*MAXSIM),fn(2)
c
      if (x.eq.1) then
        if (y.eq.1) then 
          fn(1)=0
          fn(2)=0
        else
          fn(1)=max(A(x+(y-2)*axize(1)),A(x+1+(y-2)*axize(1)))
          fn(2)=0
        end if
      else if (x.eq.axize(1)) then
        if (y.eq.1) then 
          fn(1)=A(x-1+(y-1)*axize(1))
          fn(2)=0
        else
          fn(1)=max(A(x+(y-2)*axize(1)),A(x-1+(y-2)*axize(1)),
     +              A(x-1+(y-1)*axize(1)))
          fn(2)=0
        end if
      else if (y.eq.1) then
        fn(1)=A(x-1+(y-1)*axize(1))
        fn(2)=0
      else
        fn(1)=max(A(x-1+(y-1)*axize(1)), A(x-1+(y-2)*axize(1)),
     +            A(x+(y-2)*axize(1)), A(x+1+(y-2)*axize(1)))
        fn(2)=0
        if ((A(x-1+(y-1)*axize(1)) .ne. fn(1)) .and.
     +      (A(x-1+(y-1)*axize(1)) .ne. 0))  fn(2)=A(x-1+(y-1)*axize(1))
        if ((A(x-1+(y-2)*axize(1)) .ne. fn(1)) .and.
     +      (A(x-1+(y-2)*axize(1)) .ne. 0))  fn(2)=A(x-1+(y-2)*axize(1))
        if ((A(x  +(y-2)*axize(1)) .ne. fn(1)) .and.
     +      (A(x  +(y-2)*axize(1)) .ne. 0))  fn(2)=A(x  +(y-2)*axize(1))
        if ((A(x+1+(y-2)*axize(1)) .ne. fn(1)) .and.
     +      (A(x+1+(y-2)*axize(1)) .ne. 0))  fn(2)=A(x+1+(y-2)*axize(1))
      end if
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine evaluate3D(axize, plane, planes, modi, lscr,
     +                   A,  F,  Flux,  Peak,  SXYZ,  maxF,  FieldRep,
     +                   A3D,F3D,Flux3D,Peak3D,SXYZ3D,maxF3D,FieldRep3D)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     go on to trace the three-dimensional fields in the cube by
c     detecting fields in 'A' that were already present in 'A3D'
c     and update the 3D field statistics variables
c     Write scratch file if masking is scheduled
c-----------------------------------------------------------------------
c
      integer i, j, k, axize(MAXNAX), plane, planes(2), aFN, pFN,
     +    ppN, A(MAXSIM*MAXSIM), A3D(MAXSIM*MAXSIM),
     +     Atmp(axize(1)*axize(2)), F(MAXFLD), maxF, F3D(MAXFLD),
     +    SXYZ(MAXFLD,9), SXYZ3D(MAXFLD,9), maxF3D, lscr
      real Flux(MAXFLD),Flux3D(MAXFLD),Peak(MAXFLD),Peak3D(MAXFLD)
      logical modi(7), FieldRep(MAXFLD), FieldRep3D(MAXFLD)
c
c--- prepare Atmp ---
c
      do i=1,axize(1)*axize(2)
        Atmp(i)=0
      end do
c
c--- loop over Ary and expand or merge fields in 3D ---
c
      if (plane.ne.planes(1)) then
        do i=1,axize(1)*axize(2)
          if ((A(i).ne.0).and.(F(A(i)).ne.0).and.(A3D(i).ne.0)) then
c--- read previous / active field number ---
            pFN=A3D(i)
            aFN=A(i)
            F3D(pFN)=F3D(pFN)+F(aFN)
            if (FieldRep(aFN)) FieldRep3D(pFN)=.true.
            Flux3D(pFN)=Flux3D(pFN)+Flux(aFN)
            Peak3D(pFN)=max(Peak3D(pFN),Peak(aFN))
	    SXYZ3D(pFN,1)=SXYZ3D(pFN,1)+SXYZ(aFN,1)
	    SXYZ3D(pFN,2)=SXYZ3D(pFN,2)+SXYZ(aFN,2)
	    SXYZ3D(pFN,3)=SXYZ3D(pFN,3)+SXYZ(aFN,3)
	    SXYZ3D(pFN,4)=min(SXYZ3D(pFN,4),SXYZ(aFN,4))
	    SXYZ3D(pFN,5)=min(SXYZ3D(pFN,5),SXYZ(aFN,5))
	    SXYZ3D(pFN,6)=min(SXYZ3D(pFN,6),SXYZ(aFN,6))
	    SXYZ3D(pFN,7)=max(SXYZ3D(pFN,7),SXYZ(aFN,7))
	    SXYZ3D(pFN,8)=max(SXYZ3D(pFN,8),SXYZ(aFN,8))
	    SXYZ3D(pFN,9)=max(SXYZ3D(pFN,9),SXYZ(aFN,9))
            do j=1,axize(1)*axize(2)
              if (A(j).eq.aFN) then
                Atmp(j)=pFN
c--- merge ---
                if ((A3D(j).ne.0) .and.(A3D(j).ne.pFN)) then
                  F3D(pFN)=F3D(pFN)+F3D(A3D(j))
                  if (FieldRep3D(A3D(j))) FieldRep3D(pFN)=.true.
                  Flux3D(pFN)=Flux3D(pFN)+Flux3D(A3D(j))
                  Peak3D(pFN)=max(Peak3D(pFN),Peak3D(A3D(j)))
                  SXYZ3D(pFN,1)=SXYZ3D(pFN,1)+SXYZ3D(A3D(j),1)
		  SXYZ3D(pFN,2)=SXYZ3D(pFN,2)+SXYZ3D(A3D(j),2)
		  SXYZ3D(pFN,3)=SXYZ3D(pFN,3)+SXYZ3D(A3D(j),3)
                  SXYZ3D(pFN,4)=min(SXYZ3D(pFN,4),SXYZ3D(A3D(j),4))
		  SXYZ3D(pFN,5)=min(SXYZ3D(pFN,5),SXYZ3D(A3D(j),5))
		  SXYZ3D(pFN,6)=min(SXYZ3D(pFN,6),SXYZ3D(A3D(j),6))
                  SXYZ3D(pFN,7)=max(SXYZ3D(pFN,7),SXYZ3D(A3D(j),7))
		  SXYZ3D(pFN,8)=max(SXYZ3D(pFN,8),SXYZ3D(A3D(j),8))
		  SXYZ3D(pFN,9)=max(SXYZ3D(pFN,9),SXYZ3D(A3D(j),9))
		  ppN=A3D(j)                  
		  F3D(ppN)=-pFN
                  do k=1,axize(1)*axize(2)
                    if (A3D(k).eq.ppN) A3D(k)=pFN
                    if (Atmp(k).eq.ppN) Atmp(k)=pFN
                  end do
                end if
              end if
            end do
            F(aFN)=0
          end if
        end do
      else
        do i=1,MAXFLD
          F3D(i)=0
        end do
        maxF3D=0
      end if
c
c--- look for new beginning fields in Ary and create them in 3D ---
c
      do i=1,maxF
        if (F(i).ne.0) then
          j=1
          do while (F3D(j).ne.0)
            j=j+1
            if (j.gt.MAXFLD) call
     +        bug('f','Too many fields: increase MAXFLD in maxfld.h')
          end do
          F3D(j)=F(i)
	  FieldRep3D(j)=FieldRep(i)
          if (j.gt.maxF3D) maxF3D=j
          Flux3D(j)=Flux(i)
          Peak3D(j)=Peak(i)
	  do k=1,9
	    SXYZ3D(j,k)=SXYZ(i,k)
	  end do
          do k=1,axize(1)*axize(2)
            if (A(k).eq.i) Atmp(k)=j
          end do
        end if
      end do
c
      do i=1,axize(1)*axize(2)
        A3D(i)=Atmp(i)
      end do
c
      if (modi(1).or.modi(6)) write(lscr, rec=plane) Atmp
c      
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine handleOutput(plane, modi, Fields, Flux, Peak, SXYZ,
     +           maxFields, FieldRep, pCut, fCut, iCut, mCut, idx)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     set cutoff fields to 0 size, print status
c-----------------------------------------------------------------------
c
      integer plane, Fields(MAXFLD), SXYZ(MAXFLD,9), maxFields,
     +        pCut, i, x, y,  fieldnr, idx
      real Flux(MAXFLD), Peak(MAXFLD), fCut, iCut, mCut,
     +     minFlux, minInt, minPeak, maxFlux, maxInt, maxPeak
      logical modi(7), FieldRep(MAXFLD), cutme
      character line*256, objname*23
c
      if (.not.modi(4)) then
        if (.not.modi(3)) then
          call output(' ')
          write (line,'(a,i4,a)') '**** PLANE ', plane,' ****'
          call output(line)
        end if
        write (line,'(a,a,a)') "  Nr | Pixels |     Flux     |   Inte",
     +      "nsity  |     Peak     |  Xaver |  Yaver |  Zaver | Xmin|",
     +      " Ymin| Zmin| Xmax| Ymax| Zmax"
        call output(line)
      end if
      fieldnr=0
      minFlux=0
      minInt=0
      minPeak=0
      maxFlux=0
      maxInt=0
      maxPeak=0
        do i=1,maxFields
          if (Fields(i).gt.0) then
          if ((.not.modi(5)).or.(FieldRep(i))) then
	    if (modi(7)) then
              cutme=((Fields(i).lt.pCut).or.(Flux(i).lt.fCut).or.
     +              ((Flux(i)/Fields(i)).lt.iCut).or.(Peak(i).lt.mCut))
            else
              cutme=((Fields(i).gt.pCut).or.(Flux(i).gt.fCut).or.
     +              ((Flux(i)/Fields(i)).gt.iCut).or.(Peak(i).gt.mCut))
            end if
	    if ((modi(2)).and.(SXYZ(i,6).eq.SXYZ(i,9))) cutme=.true.
	    if (idx.ne.0) then
	      if ((fieldnr+1).ne.idx) then
	        cutme=.true.
		fieldnr=fieldnr+1
	      end if
	    end if
	    if (.not.cutme) then
              fieldnr=fieldnr+1
              if (minFlux.eq.0) minFlux=Flux(i)
              if (Flux(i).lt.minFlux) minFlux=Flux(i)
	      if (minInt.eq.0) minInt=Flux(i)/Fields(i)
             if ((Flux(i)/Fields(i)).lt.minInt) minInt=Flux(i)/Fields(i)
	      if (minPeak.eq.0) minPeak=Peak(i)
              if (Peak(i).lt.minPeak) minPeak=Peak(i)
	      if (maxFlux.eq.0) maxFlux=Flux(i)
              if (Flux(i).gt.maxFlux) maxFlux=Flux(i)
              if (maxInt.eq.0) maxInt=Flux(i)/Fields(i)
             if ((Flux(i)/Fields(i)).gt.maxInt) maxInt=Flux(i)/Fields(i)
	      if (maxPeak.eq.0) maxPeak=Peak(i)
              if (Peak(i).gt.maxPeak) maxPeak=Peak(i)
	      if (.not.modi(4)) then
                write (line,'(i5,a,i8,a,f14.6,a,f14.6,a,f14.6,a,f8.2,'//
     +                'a,f8.2,a,f8.2,a,i5,a,i5,a,i5,a,i5,a,i5,a,i5)')
     +                fieldnr, ' ', Fields(i), ' ', Flux(i), ' ',
     +                Flux(i)/Fields(i), ' ', Peak(i), ' ',
     +                real(SXYZ(i,1))/Fields(i), ' ',
     +                real(SXYZ(i,2))/Fields(i), ' ',
     +                real(SXYZ(i,3))/Fields(i), ' ',
     +                SXYZ(i,4), ' ',SXYZ(i,5), ' ',SXYZ(i,6), ' ',
     +                SXYZ(i,7), ' ',SXYZ(i,8), ' ',SXYZ(i,9)
                call output (line)
              end if
            else
	      Fields(i)=0
            end if
	  else
	    Fields(i)=0
	  end if
	  end if
        end do
        if (modi(3)) then
          objname = 'The data cube contains '
	else
	  write(objname,'(a,i4,a)') 'Plane ', plane, ' contains '
	end if
	write (line,'(a,i5,a)') objname, fieldnr, ' mask fields'
        call output(line)
        if (fieldnr.ne.0) then
          write (line,'(a,f14.6,a,f14.6)')
     +	        '"Flux" between      ', minFlux, ' and ', maxFlux
          call output(line)
          write (line,'(a,f14.6,a,f14.6)')
     +	        '"Intensity" between ', minInt, ' and ', maxInt
          call output(line)
          write (line,'(a,f14.6,a,f14.6)')
     +	        '"Peak" between      ', minPeak, ' and ', maxPeak
          call output(line)
        end if
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine mask(limg, lscr, axize, planes, modi, Ary, Fields)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     mask Fields with stated 0 size
c-----------------------------------------------------------------------
c
      integer limg, lscr, axize(MAXNAX), planes(2), maxplane,
     +        Ary(axize(1)*axize(2)), Fields(MAXFLD), plane, i, x, y
      logical modi(7), maskval(MAXSIM)
c
      call output("Masking negligible fields.")
c
      if (modi(3)) then
        maxplane = planes(2)
      else
        maxplane = planes(1)
      end if
c      
      do plane = planes(1), maxplane
        if (modi(3)) then
          call xysetpl(limg, 1, plane)
          read(lscr, rec=plane) Ary
        end if
        do y=1,axize(2)
          call xyflgrd(limg, y, maskval)
          do x=1,axize(1)
            i = Ary(x+(y-1)*axize(1))
            do while (Fields(i).lt.0)
              i = -Fields(i)
            end do
            if (Fields(i).eq.0) maskval(x)=.false.
          end do
          call xyflgwr(limg, y, maskval)
        end do
      end do
c
      end
c
c%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c
      subroutine stats(limg, lscr, axize, planes, modi, Ary, Fields,
     +    Flux, Peak, SumXYZ, maxFields, mom1, mom2, ellipti, faint)
      implicit none
      include 'maxfld.h'
c-----------------------------------------------------------------------
c     compute the special statistics.
c-----------------------------------------------------------------------
c
      integer limg, lscr, plane, planes(2), axize(MAXNAX), bin,
     +        Fields(MAXFLD), maxFields, SumXYZ(MAXFLD,9),
     +        Ary(axize(1)*axize(2)), x, y, Histo(MAXFLD,8),
     +        i, j, maxplane, fieldnr
      real Flux(MAXFLD), Peak(MAXFLD), pixval(MAXSIM),
     +     MI(MAXFLD,3), wmean, sums(4),
     +     mom1, mom2, ellipti, faint, M1, M2, ell, ext
      character line*256
      logical modi(7), cutme
c
      call output("Computing statistics.")
c
      do i=1,maxFields
        do j=1,8
          Histo(i,j)=0
        end do
	do j=1,3
          MI(i,j)=0
	end do
      end do
c
      if (modi(3)) then
        maxplane = planes(2)
      else
        maxplane = planes(1)
      end if
c      
      do plane = planes(1),maxplane
	if (modi(3)) then
          call xysetpl(limg, 1, plane)
          read(lscr, rec=plane) Ary
        end if
        do y=1,axize(2)
          call xyread(limg, y, pixval)
          do x=1,axize(1)
            i = Ary(x+(y-1)*axize(1))
            do while (Fields(i).lt.0)
              i = -Fields(i)
            end do
            if (Fields(i).gt.0) then
              bin=min(int(8*pixval(x)/Peak(i))+1,8)
              Histo(i,bin) = Histo(i,bin)+1
              MI(i,1)=MI(i,1)+(x-real(SumXYZ(i,1))/Fields(i))**2
              MI(i,2)=MI(i,2)+(y-real(SumXYZ(i,2))/Fields(i))**2
              MI(i,3)=MI(i,3)+(x-real(SumXYZ(i,1))/Fields(i))
     +                         *(y-real(SumXYZ(i,2))/Fields(i))
            end if
          end do
        end do
      end do
c
      if (.not.modi(4)) call output("  Nr | Histogram (8 bins) of flu"//
     +     "x per pixel relative to peak flux            | peakpos|  "//
     +     " moment M1  |   moment M2  |  ellipticity |  faintension "//
     +     "|  theta ")
      do i=1,4
        sums(i)=0
      end do
      fieldnr=0
      do i=1,maxFields
        if (Fields(i).gt.0) then
          fieldnr=fieldnr+1
          wmean = 0
          do j=1,8
            wmean = wmean + real(Histo(i,j)*j)/Fields(i)
          end do
          M1=MI(i,1)+MI(i,2)
          M2=(MI(i,1)-MI(i,2))**2+4*MI(i,3)**2
          ell=(M1+sqrt(M2))/(M1-sqrt(M2))
          ext=(ell/Peak(i))*(M2/1e10)
          sums(1)=sums(1)+M1
          sums(2)=sums(2)+M2
          sums(3)=sums(3)+ell
          sums(4)=sums(4)+ext
          
          if (modi(7)) then
            cutme=((ext.lt.faint).or.(ell.lt.ellipti).or.
     +             (M2.lt.mom2).or.(M1.lt.mom1))
          else
            cutme=((ext.gt.faint).or.(ell.gt.ellipti).or.
     +             (M2.gt.mom2).or.(M1.gt.mom1))
          end if
          if (.not.cutme) then
            if (.not.modi(4)) then
	      write (line,'(i5,a,i8,a,i8,a,i8,a,i8,a,i8,a,i8,a,i8,a,i'//
     +               '8,a,f8.6,a,e14.6,a,e14.6,a,f14.6,a,f14.6,a,f8.3)')
     +            fieldnr, ' ', Histo(i,1), ' ', Histo(i,2), ' ',
     +            Histo(i,3), ' ', Histo(i,4), ' ', Histo(i,5), ' ',
     +            Histo(i,6), ' ', Histo(i,7), ' ', Histo(i,8), ' ',
     +            wmean/8, ' ', M1, ' ', M2, ' ', ell, ' ', ext, ' ',
     +            90*atan(2*MI(i,3)/(MI(i,1)-MI(i,2)))/3.1415926536
              call output(line)
	    end if
          else if (Fields(i).gt.0) then
            Fields(i) = 0
          end if
        end if
      end do
c
      write (line,'(a,e14.6)') 'Average moment M1 is ', sums(1)/fieldnr
      call output(line)
      write (line,'(a,e14.6)') 'Average moment M2 is ', sums(2)/fieldnr
      call output(line)
      write (line,'(a,f14.6)') 'Average ellipticity is ',sums(3)/fieldnr
      call output(line)
      write (line,'(a,f14.6)') 'Average faintension is ',sums(4)/fieldnr
      call output(line)
c
      end
