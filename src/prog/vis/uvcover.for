c************************************************************************
	PROGRAM uvcover
	IMPLICIT NONE

c= uvcover - Display uv coverage
c& lgm
c: uv analysis
c+
c    UVCOVER displays UV coverage. Although the W coordinate is read
c    (if present) it is not plotted. The program UVPLOT with keyword
c    'axis=uv,vc' does exactly the same as UVCOVER, but allows more
c    selection *and* does not plot flagged data. Hence this
c    program is deprecated.
c    
c< vis
c< device
c--
c
c  History:
c    bs   19may89
c    bs   13jun89
c    rjs  24oct89  Fixed some portability problems.
c    rjs   7nov89  Standardised keywords.
c    lgm  11nov89  changed default plot device to /sun
c    pjt  27mar90  mkeyf, added filename in label on top of plot, no GOTO's
c    rjs  23apr90  Added a goto, because pjt's no GOTO's made the code
c		   non-standard.
c    pjt  17may90  increased MAXSETS
c    pjt  22jun90  increased MAXPNTS a bit for Arie mr. VLA
c    bpw  11feb91  add standard keyword documentation
c    mjs  13mar93  pgplot subr names have less than 7 chars.
c    pjt  28mar95  added needed support for UVW coordinates 
c    pjt   7apr95  fixed broken UV when doing UVW (previous 'fix')
c                  add deprecation message in favor of UVPLT
c    pjt  17nov08  fix deprecation message 
c------------------------------------------------------------------------
c
c  MAXPNTS -- maximum UV points
c
	INTEGER MAXPNTS
	PARAMETER( MAXPNTS = 50000000 )
c
c  MAXSETS -- maximum number of data sets
c
	INTEGER MAXSETS
	PARAMETER( MAXSETS = 64)
c
c   local variables
c
      REAL             u(MAXPNTS), v(MAXPNTS), uvmax, uvpmax
      INTEGER          tno, iset, nsets, ipnt, npnts, uvscan, len1
      INTEGER          clen
      CHARACTER*132    dataset(MAXSETS), device, vis
      CHARACTER        ctyp*1
      DOUBLE PRECISION coord(3)
      LOGICAL          more, cupd


      CALL output('Uvcover: version 1.0 17-nov-08' )
      CALL bug('i','UVCOVER is deprecated, please use UVPLT instead:')
      CALL bug('i','uvplt axis=uc,vc options=equal,nobase,nanosec ...')
c
c  Get the dataset names
c
	CALL keyini
	CALL keya( 'device', device, '/sun' )
        CALL keyr( 'uvmax', uvpmax, 0.0)
        CALL mkeyf('vis',dataset,MAXSETS,nsets)
	CALL keyfin
        IF (nsets.eq.0) THEN
            CALL bug('f','Must specify at least one vis dataset')
        ELSE
            vis = dataset(1)
            DO iset=2,nsets
               vis = vis(1:len1(vis)) // ',' //
     -               dataset(iset)(1:len1(dataset(iset)))
            ENDDO
        ENDIF
c
c  Read in UV coordinates
c
	ipnt = 0
	DO iset = 1, nsets
	    CALL uvopen( tno, dataset(iset), 'old' )
 
            more = .TRUE.
	    DOWHILE(ipnt.LT.MAXPNTS .AND. more)
	        IF( uvscan( tno, 'coord' ) .EQ. 0 ) THEN
                    ipnt = ipnt + 1
                    CALL uvprobvr( tno, 'coord', ctyp, clen, cupd)
		    CALL uvgetvrd( tno, 'coord', coord, clen)
		    u(ipnt) = coord(1)
		    v(ipnt) = coord(2)
                ELSE
                    more = .FALSE.
                ENDIF
	    ENDDO
            CALL uvclose(tno)
            IF (ipnt.GE.MAXPNTS) then
	        CALL bug( 'w', 'maximum number of points exceeded' )
	        ipnt = MAXPNTS
		goto 10
            ENDIF
        ENDDO
 10	npnts = ipnt

	IF (uvpmax.LE.0.0) THEN
c
c  Find the maximum U,V ns
c
	  uvmax = u(1)
	  DO ipnt = 1, npnts
	    IF( ABS( u(ipnt) ) .GT. uvmax ) uvmax = ABS( u(ipnt) )
	    IF( ABS( v(ipnt) ) .GT. uvmax ) uvmax = ABS( v(ipnt) )
          ENDDO
	  uvmax = uvmax * 1.1
	ELSE
	  uvmax = uvpmax
	ENDIF

c
c  Plot it
c
	CALL pgbeg( 0, device, 1, 1)
	CALL pgenv( -uvmax, uvmax, -uvmax, uvmax, 1, 1)
	CALL pglab('U -- nanoseconds','V -- nanoseconds',
     -      'UvCover: '//vis)
	CALL pgpt(npnts, u, v, 1)
	CALL pgswin(uvmax, -uvmax, uvmax, -uvmax)
	CALL pgpt(npnts, u, v, 1)
	CALL pgend
c
c   all done
c
	END

