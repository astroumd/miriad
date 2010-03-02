      SUBROUTINE PALETT(TYPE)
C-----------------------------------------------------------------------
C Set a "palette" of colors in the range of color indices used by
C PGIMAG.
C-----------------------------------------------------------------------
      INTEGER TYPE
C
      REAL GL(2), GR(2), GG(2), GB(2), GIR(2), GIG(2), GIB(2)
      REAL RL(9), RR(9), RG(9), RB(9)
      REAL HL(5), HR(5), HG(5), HB(5)
      REAL WL(10), WR(10), WG(10), WB(10)
      REAL AL(20), AR(20), AG(20), AB(20)
      REAL TL(4), TR(4), TG(4), TB(4)
      REAL saoAL(7),saoAR(7),saoAG(7),saoAB(7)
      REAL saoBBL(5),saoBBR(5),saoBBG(5),saoBBB(5)
      REAL saoHEL(8),saoHER(8),saoHEG(8),saoHEB(8)
      REAL saoI8L(9),saoI8R(9),saoI8G(9),saoI8B(9)
      REAL dsL(17),dsR(17),dsG(17),dsB(17)
      REAL cyclicL(7),cyclicR(7),cyclicG(7),cyclicB(7)

C
      DATA GL /0.0, 1.0/
      DATA GR /1.0, 0.0/
      DATA GG /1.0, 0.0/
      DATA GB /1.0, 0.0/
      DATA GIR /0.0, 1.0/
      DATA GIG /0.0, 1.0/
      DATA GIB /0.0, 1.0/
C
      DATA RL /-0.5, 0.0, 0.17, 0.33, 0.50, 0.67, 0.83, 1.0, 1.7/
      DATA RR / 0.0, 0.0,  0.0,  0.0,  0.6,  1.0,  1.0, 1.0, 1.0/
      DATA RG / 0.0, 0.0,  0.0,  1.0,  1.0,  1.0,  0.6, 0.0, 1.0/
      DATA RB / 0.0, 0.3,  0.8,  1.0,  0.3,  0.0,  0.0, 0.0, 1.0/
C
      DATA HL /0.0, 0.2, 0.4, 0.6, 1.0/
      DATA HR /0.0, 0.5, 1.0, 1.0, 1.0/
      DATA HG /0.0, 0.0, 0.5, 1.0, 1.0/
      DATA HB /0.0, 0.0, 0.0, 0.3, 1.0/
C
      DATA WL /0.0, 0.5, 0.5, 0.7, 0.7, 0.85, 0.85, 0.95, 0.95, 1.0/
      DATA WR /0.0, 1.0, 0.0, 0.0, 0.3,  0.8,  0.3,  1.0,  1.0, 1.0/
      DATA WG /0.0, 0.5, 0.4, 1.0, 0.0,  0.0,  0.2,  0.7,  1.0, 1.0/
      DATA WB /0.0, 0.0, 0.0, 0.0, 0.4,  1.0,  0.0,  0.0, 0.95, 1.0/
C
      DATA AL /0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, 0.5,
     :         0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1.0/
      DATA AR /0.0, 0.0, 0.3, 0.3, 0.5, 0.5, 0.0, 0.0, 0.0, 0.0,
     :         0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0/
      DATA AG /0.0, 0.0, 0.3, 0.3, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8,
     :         0.6, 0.6, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.0, 0.0/
      DATA AB /0.0, 0.0, 0.3, 0.3, 0.7, 0.7, 0.7, 0.7, 0.9, 0.9,
     :         0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0/
C
      DATA TL /0.0, 0.5, 0.5, 1.0/
      DATA TR /0.2, 0.6, 0.6, 1.0/
      DATA TG /0.0, 0.0, 0.5, 1.0/
      DATA TB /1.0, 0.0, 0.0, 0.0/
C
      DATA saoAL/0.0, 0.125, 0.25, 0.5, 0.64, 0.77, 1.0/
      DATA saoAR/0.0, 0.0,   0.0,  1.0, 1.0,  1.0,  1.0/
      DATA saoAG/0.0, 0.0,   1.0,  0.0, 0.0,  0.0,  1.0/
      DATA saoAB/0.0, 0.0,   0.0,  1.0, 0.5,  0.0,  0.0/
C
      DATA saoBBL/0.0, 0.25, 0.5, 0.75, 1.0/
      DATA saoBBR/0.0, 0.0,  1.0, 1.0,  1.0/
      DATA saoBBG/0.0, 0.0,  0.0, 1.0,  1.0/
      DATA saoBBB/0.0, 0.0,  0.0, 0.0,  1.0/
c     
      DATA saoHEL/0.0, 0.015, 0.03,  0.065, 0.125, 0.25, 0.5,  1.0/
      DATA saoHER/0.0, 0.5,   0.5,   0.5,   0.5,   0.5,  0.75, 1.0/
      DATA saoHEG/0.0, 0.0,   0.0,   0.0,   0.5,   0.75, 0.81, 1.0/
      DATA saoHEB/0.0, 0.125, 0.375, 0.625, 0.625, 0.25, 0.25, 1.0/
c
      DATA saoI8L/0.0,   0.125, 0.25, 0.5, 0.5, 0.75, 0.75, 1.0, 1.0/
      DATA saoI8R/0.087, 0.087, 0.0,  0.0, 0.0, 1.0,  1.0,  1.0, 1.0/
      DATA saoI8G/0.087, 0.087, 1.0,  0.0, 1.0, 0.0,  1.0,  0.0, 1.0/
      DATA saoI8B/0.087, 0.087, 0.0,  1.0, 1.0, 0.0,  0.0,  1.0, 1.0/

      DATA dsL/0.0,   0.008, 0.055, 0.11,  0.173, 0.323, 0.331,
     +                 0.449, 0.457, 0.496, 0.567, 0.701, 0.843, 0.850,
     +                 0.858, 0.913, 1.0/
      DATA dsR/0.0,   0.282, 0.651, 0.0,   0.0,   0.0,   0.0,
     +                 0.0,   0.0,   0.639, 0.973, 0.98,  0.996, 1.0,
     +                 1.0,   0.98,  1.0/
      DATA dsG/0.0,   0.278, 0.0,   0.0,   0.486, 0.961, 0.973,
     +                 1.0,   1.0,   0.953, 0.973, 0.533, 0.267, 0.0,
     +                 0.294, 0.584,  1.0/
      DATA dsB/0.0,   0.239, 0.647, 1.0,   1.0,   0.961, 0.898,
     +                 0.486, 0.0,   0.0,   0.0,   0.0,   0.0,   0.0,
     +                 0.294, 0.588, 1.0/

c     This cycles from Red to Green to Blue to Red.... 
      DATA cyclicL/0.0, 0.166, 0.333, 0.5,   0.666, 0.833, 1.0/
      DATA cyclicR/1.0, 1.0,   0.0,   0.0,   0.0,   1.0,   1.0/
      DATA cyclicG/0.0, 1.0,   1.0,   1.0,   0.0,   0.0,   0.0/
      DATA cyclicB/0.0, 0.0,   0.0,   1.0,   1.0,   1.0,   0.0/
      integer la
      character ans*10

      IF (TYPE.EQ.1) THEN
C        -- gray scale
        call pgqinf('HARDCOPY',ans,la)
        if (ans.eq.'YES') then
         CALL PGCTAB(GL, GIR, GIG, GIB, 2, 1.0, 0.5)
        else
         CALL PGCTAB(GL, GR, GG, GB, 2, 1.0, 0.5)
        end if
      ELSE IF (TYPE.EQ.2) THEN
C        -- rainbow
         CALL PGCTAB(RL, RR, RG, RB, 9, 1.0, 0.5)
      ELSE IF (TYPE.EQ.3) THEN
C        -- heat
         CALL PGCTAB(HL, HR, HG, HB, 5, 1.0, 0.5)
      ELSE IF (TYPE.EQ.4) THEN
C        -- weird IRAF
         CALL PGCTAB(WL, WR, WG, WB, 10, 1.0, 0.5)
      ELSE IF (TYPE.EQ.5) THEN
C        -- AIPS
         CALL PGCTAB(AL, AR, AG, AB, 20, 1.0, 0.5)
      ELSE IF (TYPE.EQ.6) THEN
C        -- TJP
         CALL PGCTAB(TL, TR, TG, TB, 4, 1.0, 0.5)
      ELSE IF (TYPE.EQ.7) THEN
C        -- saoA
         CALL PGCTAB(saoAL, saoAR, saoAG, saoAB, 7, 1.0, 0.5)
      ELSE IF (TYPE.EQ.8) THEN
C        -- saoBB
         CALL PGCTAB(saoBBL, saoBBR, saoBBG, saoBBB, 5, 1.0, 0.5)
      ELSE IF (TYPE.EQ.9) THEN
C        -- saoHE
         CALL PGCTAB(saoHEL, saoHER, saoHEG, saoHEB, 8, 1.0, 0.5)
      ELSE IF (TYPE.EQ.10) THEN
C        -- saoI8
         CALL PGCTAB(saoI8L, saoI8R, saoI8G, saoI8B, 9, 1.0, 0.5)
      ELSE IF (TYPE.EQ.11) THEN
C        -- ds
         CALL PGCTAB(dsL, dsR, dsG, dsB, 17, 1.0, 0.5)
      ELSE IF (TYPE.EQ.12) THEN
C        -- cyclic
         CALL PGCTAB(cyclicL, cyclicR, cyclicG, cyclicB, 7, 1.0, 0.5)
      END IF
      END


c	index=4 => touch and square with/out annotation, not for px*py=1
c	index=3 => untouch but with annotation
c	index=2 => touch and square pixel with/out annotation
c	index=1 => touch with/out annotation, not for px*py=1
c	index=0 => restore or untouch with no annotation
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c                -----   -----   -----
c               |     | |     | |     |
c                -----   -----   -----
c                                                        |  
c                -----   -----   -----        |          |
c               |     | |     | |     |       |   ylen   |   ysz
c                -----   -----   -----        |          |
c            <->		         |  yvp
c            xvp
c               <---->
c                xlen
c               <------>
c                xsz
c
c            total xlength = (npx - 1) *xsz +xlen
c
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
	Subroutine PANEL_CONNECT(index,Units_p)
	integer index
	logical first
	data first /.true./
	include 'pgplot.inc'
	real axch,aych,pxch,pych
	real minlen
	real CH,oldCH
	real oldPGXLEN,oldPGYLEN,oldPGXSZ,oldPGYSZ,oldPGXVP,oldPGYVP
	common/oldpg/oldPGXLEN,oldPGYLEN,oldPGXSZ,oldPGYSZ,oldCH,
     +    oldPGXVP,oldPGYVP
	real asclo,aschi,asdlo,asdhi,lenx,leny
	common/boxpg/asclo,aschi,asdlo,asdhi,lenx,leny
	character Units_p*(*)

	real axs,axe,ays,aye,dx,dy,minratio
	if (first) then
	  first=.false.
	  return
	endif
	PGXLEN(PGID)=oldPGXLEN
	PGYLEN(PGID)=oldPGYLEN
	PGXSZ(PGID)=oldPGXSZ
	PGYSZ(PGID)=oldPGYSZ
	PGXVP(PGID)=oldPGXVP
	PGYVP(PGID)=oldPGYVP
	CH=oldCH
	CALL PGSCH(CH)
c	write(*,*) "INDEX", index
c	write(*,*) PGXVP(PGID),PGYVP(PGID),PGXSZ(PGID),PGYSZ(PGID)
	if (index.eq.1.or.index.eq.2.or.index.eq.4) then
c	  if (PGNXC(PGID).gt.1) THEN
            PGXLEN(PGID)=lenx
	    PGXSZ(PGID)=PGXLEN(PGID) ! use as much space as possible
	    PGXVP(PGID)=asclo
c	  ENDIF
c	  if (PGNYC(PGID).gt.1) THEN
	    PGYLEN(PGID)=leny
	    PGYSZ(PGID)=PGYLEN(PGID) ! use as much space as possible 
 	    PGYVP(PGID)=asdlo
c	  ENDIF
c	  try to make it a touched square pixel if asked to
	  if (index.eq.2) then
	    call pgqwin(axs,axe,ays,aye)
	    dx=abs(axe-axs)
	    if (Units_p.eq.'a') dx=dx*15.0
	    dy=abs(aye-ays)
	    minratio=min(PGXLEN(PGID)/dx,PGYLEN(PGID)/dy)
	    xlen=dx*minratio
	    ylen=dy*minratio
c	    write(*,*) "submin",minratio,xlen,ylen
	    PGXLEN(PGID)=xlen
	    PGYLEN(PGID)=ylen
	    if (PGNXC(PGID).gt.1) PGXSZ(PGID)=PGXLEN(PGID)
	    if (PGNYC(PGID).gt.1) PGYSZ(PGID)=PGYLEN(PGID)
	    if (PGXVP(PGID).gt.PGYVP(PGID)) then
	      PGXVP(PGID)=aschi-pgnxc(PGID)*xlen
	    else
	      PGYVP(PGID)=asdhi-pgnyc(PGID)*ylen
	    endif
c	    write(*,*) "ashi",aschi-minlen,asdhi-minlen
c	    write(*,*) PGXSZ(PGID),PGXLEN(PGID),PGXVP(PGID)
	  endif
c	  try to make it a touched square box if asked to
	  if (index.eq.4) then
	    minlen=min(PGXLEN(PGID),PGYLEN(PGID))
	    PGXLEN(PGID)=minlen
	    PGYLEN(PGID)=minlen
	    if (PGNXC(PGID).gt.1) PGXSZ(PGID)=PGXLEN(PGID)
	    if (PGNYC(PGID).gt.1) PGYSZ(PGID)=PGYLEN(PGID)
	    if (PGXVP(PGID).gt.PGYVP(PGID)) then
	      PGXVP(PGID)=aschi-pgnxc(PGID)*minlen
	    else
	      PGYVP(PGID)=asdhi-pgnyc(PGID)*minlen
	    endif
c	    write(*,*) "ashi",aschi-minlen,asdhi-minlen
	  endif
	  call  PGQCS(1, AXCH, AYCH)
	  call  PGQCS(3, PXCH, PYCH)
c	  if (min(PGNXC(PGID),PGNYC(PGID)).eq.2)  CH=1.8
c	  if (min(PGNXC(PGID),PGNYC(PGID)).eq.3)  CH=2.1
c	  if (min(PGNXC(PGID),PGNYC(PGID)).eq.4)  CH=2.7
c	  if (min(PGNXC(PGID),PGNYC(PGID)).gt.4)
c     +  	  CH=2.0*(oldCH+0.1*max(PGNXC(PGID),PGNYC(PGID)))
	  
	  CH=min(0.14/AXch,min(PGXLEN(PGID),PGYLEN(PGID))/6.0/PXCH)
c	  write(*,*) "charsize=",oldCH,CH,AXCH,
c     +         AYCH,PGXLEN(PGID),PGYLEN(PGID)
c	  write(*,*) "charsize1=",oldCH,CH,PXCH,
c     +         PYCH,PGXLEN(PGID),PGYLEN(PGID)
	  if (PGNXC(PGID)*PGNYC(PGID).eq.1) CH=oldCH
	  CALL PGSCH(CH)
	  return
	end if
	if (index.eq.3) then ! reserve space for annotation
	  RATIO=((PGNXC(PGID)-1)*oldPGXSZ+oldPGXLEN)/
     +       (aschi-oldPGXVP)
	  PGXVP(PGID)=max(oldPGXVP,25.0)
	  PGYVP(PGID)=max(oldPGYVP,28.0)
	  Txlen=((PGNXC(PGID)-1)*oldPGXSZ+oldPGXLEN)*ratio
	  xratio=Txlen/(oldPGXVP-PGXVP(PGID)+Txlen)
	  Tylen=((PGNYC(PGID)-1)*oldPGYSZ+oldPGYLEN)
	  yratio=Tylen/(oldPGYVP-2*PGYVP(PGID)+TYlen)

	  PGXLEN(PGID)=oldPGXLEN/ratio/xratio
	  PGYLEN(PGID)=oldPGYLEN/yratio
	  PGXSZ(PGID)=oldPGXSZ/ratio/xratio
	  PGYSZ(PGID)=oldPGYSZ/yratio

c	  write(*,*) PGXVP(PGID),PGYVP(PGID),PGXSZ(PGID),PGYSZ(PGID),
c     +      ratio,xratio
	  call  PGQCS(1, AXCH, AYCH)
	  call  PGQCS(3, PXCH, PYCH)
	  CH=min(0.08/AXch,min(PGXLEN(PGID),PGYLEN(PGID))/10.0/PXCH)
	  if (PGNXC(PGID)*PGNYC(PGID).eq.1) CH=oldCH
	  CALL PGSCH(CH)
	  return
	endif


c	write(*,*) index,"LENGTH",PGXLEN(PGID),
c     +      PGYLEN(PGID),PGNXC(PGID),PGNYC(PGID)
c        write(*,*) PGXVP(PGID),PGYVP(PGID),PGXSZ(PGID),PGYSZ(PGID),CH
	return
	end

	Subroutine getpanelbox
	include 'pgplot.inc'
	real CH,oldCH
	real oldPGXLEN,oldPGYLEN,oldPGXSZ,oldPGYSZ,oldPGXVP,oldPGYVP
	common/oldpg/oldPGXLEN,oldPGYLEN,oldPGXSZ,oldPGYSZ,oldCH,
     +    oldPGXVP,oldPGYVP
	oldPGXLEN=PGXLEN(PGID)
	oldPGYLEN=PGYLEN(PGID)
	oldPGXSZ=PGXSZ(PGID)
	oldPGYSZ=PGYSZ(PGID)
	oldPGXVP=PGXVP(PGID)
	oldPGYVP=PGYVP(PGID)
	CALL PGQCH(CH)
	oldCH=CH
c	write(*,*) "A","LENGTH",PGXLEN(PGID),
c     +      PGYLEN(PGID),PGNXC(PGID),PGNYC(PGID)
c        write(*,*) PGXVP(PGID),PGYVP(PGID),PGXSZ(PGID),PGYSZ(PGID),CH
	return
	end

C*GRGENV -- get value of PGPLOT environment parameter (Sun/Convex-UNIX)
C+
      SUBROUTINE GRGENV(NAME, VALUE, L)
      CHARACTER*(*) NAME, VALUE
      INTEGER L
C
C Return the value of a PGPLOT environment parameter. In Sun/Convex-UNIX,
C environment parameters are UNIX environment variables; e.g. parameter
C ENVOPT is environment variable PGPLOT_ENVOPT. Translation is not
C recursive and is case-sensitive.
C
C Arguments:
C  NAME   : (input) the name of the parameter to evaluate.
C  VALUE  : receives the value of the parameter, truncated or extended
C           with blanks as necessary. If the parameter is undefined,
C           a blank string is returned.
C  L      : receives the number of characters in VALUE, excluding
C           trailing blanks. If the parameter is undefined, zero is
C           returned.
C--
C 19-Jan-1988
C-----------------------------------------------------------------------
      INTEGER I, LIN
      CHARACTER*32 TEST
C
      TEST = 'PGPLOT_'//NAME
      LIN = INDEX(TEST, ' ')-1
      CALL GETENV(TEST(:LIN), VALUE)
      IF (VALUE.EQ.' ') THEN
          L = 0
      ELSE
          DO 10 I=LEN(VALUE),1,-1
              L = I
              IF (VALUE(I:I).NE.' ') GOTO 20
   10     CONTINUE
          L = 0
   20     CONTINUE
      END IF
      IF (TEST(8:14).eq."PS_BBOX") THEN
	 L=3
	 VALUE="MAX"
      ENDIF
      END
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

	SUBROUTINE PGPANL_MY(n)
	integer i,j,n,np
	integer PX,PY
	COMMON/panel/Px,py
	np=mod(n,px*py)
	if (np.eq.0) np=px*py
	i=mod(np,px)
	if (i.eq.0) i=px
	j=int(real(np/px))
	if (np.gt.j*px) then
	  j=j+1
	endif
c	write(*,*) n,np,px,py,i,j
	call pgpanl(i,j)
	return
	end

	SUBROUTINE pgeras_my
	call grpage
	return
	end

	subroutine getpanel(imaps,windx,windy)
	integer imaps,windx,windy
c
c	Return number of plotting windows in x and y directions (windx,windy)
c	imaps is the number of maps to be plotted
c----------------------------------------------------------------------c
c
	if (imaps .gt. 16) then
	    windx=5
	    windy=5
        else if (imaps .gt. 9 .and. imaps .le. 16 ) then
            windx=4
            windy=4
	else if (imaps .gt. 4 .and. imaps .le. 9 ) then
	    windx=3
	    windy=3
	else if (imaps .gt. 1 .and. imaps .le. 4) then
	    windx=2
	    windy=2
	else if (imaps .eq. 1) then
	    windx=1
	    windy=1
	endif
	return
	end
