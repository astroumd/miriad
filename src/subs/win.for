c************************************************************************
c  History:
c    bs    aug89  Original version.
c    rjs 14sep89  Fixed some long lines, included documentation within the
c		  source code.
c    lgm 11nov89  fixed bug in WinNorm - pgplot blew up when y constant
c    pjt  6dec89  return 'q' in wincurs when no cursor available
c    rjs 26mar90  Fixed bad call to pgqinf, in wincurs.
c    lgm xxapr90  Various little mods for improvements to passfit and calflag
c    pjt 18jun90  Added winpoint
c    pjt 14jul90  NSF beautification
c    pjt  1oct90  Added winscalx, winscaly; fixed 'index' to 'idx'
c    pjt 18dec90  Have wincurs return char(0) for pgcurs compatibility
c    pjt  7feb91  comments in fatpoint
c    pjt  3mar91  uncommented fatpoint, by lack of better - fixed winshow
c    pjt 16mar91  redone pgerase (PGASK!!) and some extra bug() calls
c    pjt 16may91  fixed bug introduces on 16mar91 in pgerase
c    rjs 22may91  Fixed a flaw in WinSize which caused many unnecessary
c		  calls.
c    pjt  7aug91  PGTBOX test
c    pjt 30nov91  more PGTBOX testing
c    mjs 13mar93  pgplot subr names have less than 7 chars.
c     jm 13jul95  Removed obsolete code and corrected PGPLOT sections.
c                 Also added PGPLOT buffering calls.  Removed fatpoint.
c                 Made winshow just a call to wintshow with 0 scaling.
c    pjt 20jun98  removed sloppy EXTERNAL/INTEGER declarations for g77
c************************************************************************
c* Win -- Subroutine package for interactive plots, using PGPLOT.
c& pjt
c: plotting,PGPLOT,user-interaction
c+
c The Win package consists of a set of subroutines for interactive
c display of simultaneous plots.  At any one time some subset of the plots are
c displayed in an X-Y grid, and cursor input can be directed toward and
c particular window.  Zooming and panning are also possible.  See CalFlag and
c VarPlot as examples.
c--
c************************************************************************
c* WinPick -- Set the active windows
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinPick( Xlo, Xhi, Ylo, Yhi )
	implicit none
	integer Xlo, Xhi, Ylo, Yhi
c
c    WinPick selects which of the available plots are to be acted upon or
c    displayed.  If the user might use { 1, 4, 1, 3 } to effect a grid of
c    4x3 plots.  Any further WinXxxx routine will operate on all the the
c    selected plots is some fashion, either independently or with some sort
c    of average.
c
c--
c------------------------------------------------------------------------
	include 'win.h'
c
	if( Xlo .lt.     1 )
     *	  call WinError( 'WinPick: Xlo < 1' )
	if( Xhi .gt. WinMaxX )
     *	  call WinError( 'WinPick: Xhi > WinMaxX' )
	if( Ylo .lt.     1 )
     *	  call WinError( 'WinPick: Ylo < 1' )
	if( Yhi .gt. WinMaxY )
     *	  call WinError( 'WinPick: Yhi > WinMaxY' )
	if( Xlo .gt.   Xhi )
     *	  call WinError( 'WinPick: Xlo > Xhi' )
	if( Ylo .gt.   Yhi )
     *	  call WinError( 'WinPick: Ylo > Yhi' )
c
	WinNXlo = Xlo
	WinNXhi = Xhi
	WinNYlo = Ylo
	WinNYhi = Yhi
	return
	end
c************************************************************************
c* WinPick1 -- set an active window
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinPick1( X, Y )
	implicit none
	integer X, Y
c
c    WinPick1 selects a particular plot, as in WinPick above.
c--
c------------------------------------------------------------------------
	call WinPick( X, X, Y, Y )
	return
	end
c************************************************************************
c* WinLoc -- set window screen locations
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinLoc( Xlo, Xhi, Ylo, Yhi )
	implicit none
	real Xlo, Xhi, Ylo, Yhi
c
c    WinLoc sets the location of a plot on the viewing surface.  Generally
c    the user does not call WinLoc except for an application such as a
c    button.
c--
c------------------------------------------------------------------------
	include 'win.h'
	integer NX, NY
c
	do NX = WinNXlo, WinNXhi
	do NY = WinNYlo, WinNYhi
	    win0( NX, NY, 1 ) = Xlo
	    win0( NX, NY, 2 ) = Xhi
	    win0( NX, NY, 3 ) = Ylo
	    win0( NX, NY, 4 ) = Yhi
	enddo
	enddo
	return
	end
c************************************************************************
c* WinScale -- set window user scales
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinScale( Xlo, Xhi, Ylo, Yhi )
	implicit none
	real Xlo, Xhi, Ylo, Yhi
c
c    WinScale sets the user coordinates of a set of plots.  Also see
c    WinSize and WinNorm.
c--
c------------------------------------------------------------------------
	include 'win.h'
	integer NX, NY
c
	do NX = WinNXlo, WinNXhi
	do NY = WinNYlo, WinNYhi
	    win1( NX, NY, 1 ) = Xlo
	    win1( NX, NY, 2 ) = Xhi
	    win1( NX, NY, 3 ) = Ylo
	    win1( NX, NY, 4 ) = Yhi
	enddo
	enddo
	return
	end
c************************************************************************
c* WinScaly -- set window user Y-scales
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinScaly( Ylo, Yhi )
	implicit none
	real Ylo, Yhi
c
c    WinScaly sets the Y user coordinates of a set of plots.  
c    Also see WinScale.
c--
c------------------------------------------------------------------------
	include 'win.h'
	integer NX, NY
c
	do NX = WinNXlo, WinNXhi
	do NY = WinNYlo, WinNYhi
	    win1( NX, NY, 3 ) = Ylo
	    win1( NX, NY, 4 ) = Yhi
	enddo
	enddo
	return
	end
c************************************************************************
c* WinScalx -- set window user X-scales
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinScalx( Xlo, Xhi )
	implicit none
	real Xlo, Xhi
c
c    WinScaly sets the X user coordinates of a set of plots.  
c    Also see WinScale.
c--
c------------------------------------------------------------------------
	include 'win.h'
	integer NX, NY
c
	do NX = WinNXlo, WinNXhi
	do NY = WinNYlo, WinNYhi
	    win1( NX, NY, 1 ) = Xlo
	    win1( NX, NY, 2 ) = Xhi
	enddo
	enddo
	return
	end
c************************************************************************
c  WinError -- print an error message and die
c
c------------------------------------------------------------------------
	subroutine WinError( message )
	implicit none
	character*(*) message
	call bug('f',message)
	end
c************************************************************************
c* WinSize -- Size windows to the data
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinSize( N, X, Y )
	implicit none
	integer N
	real X(*), Y(*)
c
c    WinSize sets the user coordinates of a set of windows to the
c    minimum and maximum of a set of data points.  See also WinNorm.
c--
c------------------------------------------------------------------------
	integer i
	real minX, maxX, minY, maxY
c
	if (N .lt. 1) then
	   minX = 0
	   maxX = 1
	   minY = 0
	   maxY = 1
	else
	   minX = X(1)
	   maxX = X(1)
	   minY = Y(1)
	   maxY = Y(1)
	   do i = 1, N
	       minX = min( minX, X(i) )
	       maxX = max( maxX, X(i) )
	       minY = min( minY, Y(i) )
	       maxY = max( maxY, Y(i) )
	   enddo
	endif
	call WinScale( minX, maxX, minY, maxY )
	return
	end
c************************************************************************
c* WinNorm -- normalize plots and add a margin
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinNorm( margin )
	implicit none
	real margin
c
c    WinNorm normalizes the set of active windows to have the same user
c    coordinates and adds a margin around the data.  A margin of 0.1 is
c    recommended.
c--
c------------------------------------------------------------------------
	include 'win.h'
c
	integer nx, ny
	real lower
	real minX, maxX, minY, maxY
c
	if( margin .le. -0.5 ) call WinError( 'WinNorm:  bad margin' )
c
	minX = win1( WinNXlo, WinNYlo, 1 )
	maxX = win1( WinNXlo, WinNYlo, 2 )
	minY = win1( WinNXlo, WinNYlo, 3 )
	maxY = win1( WinNXlo, WinNYlo, 4 )
	do nx = WinNXlo, WinNXhi
	do ny = WinNYlo, WinNYhi
	    minX = min( minX, win1( nx, ny, 1 ) )
	    maxX = max( maxX, win1( nx, ny, 2 ) )
	    minY = min( minY, win1( nx, ny, 3 ) )
	    maxY = max( maxY, win1( nx, ny, 4 ) )
	enddo
	enddo
c
c  Adjust the min and max a little if they are very close to being equal
c
        if(maxX .le. minX) then
	   maxX = minX
           lower = minX
           if (lower .eq. 0.0) lower = 1.0
	   minX = minX - (0.01 * abs(lower))
	   maxX = maxX + (0.01 * abs(lower))
        endif
        if (abs(maxX - minX) .lt. 1.0E-5) then
	    maxX = minX + (margin / 2.0)
	    minX = minX - (margin / 2.0)
        endif
c
	if(maxY .le. minY) then
           maxY = minY
           lower = minY
           if (lower .eq. 0.0) lower = 1.0
	   minY = minY - (0.01 * abs(lower))
	   maxY = maxY + (0.01 * abs(lower))
        endif
        if (abs(maxY - minY) .lt. 1.0E-5) then
	    maxY = minY + (margin / 2.0)
	    minY = minY - (margin / 2.0)
	endif
c
	do nx = WinNXlo, WinNXhi
	do ny = WinNYlo, WinNYhi
	    win1(nx,ny,1) = minX - (margin * (maxX - minX))
	    win1(nx,ny,2) = maxX + (margin * (maxX - minX))
	    win1(nx,ny,3) = minY - (margin * (maxY - minY))
	    win1(nx,ny,4) = maxY + (margin * (maxY - minY))
	enddo
	enddo
	return
	end
c************************************************************************
c* WinCoord -- change PGPLOT coordinates to a window
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	SUBROUTINE wincoord( x, y )
	IMPLICIT NONE
	INTEGER x, y
c
c    WinCoord sets the PGPLOT coordinates to a particular window for
c    plotting.  Generally the user calls WinShow rather than calling this
c    subroutine directly.
c--
c------------------------------------------------------------------------
	INCLUDE 'win.h'
        CHARACTER itoaf*2
c
	IF( (x .lt. WinNXlo) .or. (x .gt. WinNXhi)
     *  .or.(y .lt. WinNYlo) .or. (y .gt. WinNYhi) ) then
	    win0(x,y,1) = 0.0
	    win0(x,y,2) = 0.0
	    win0(x,y,3) = 0.0
	    win0(x,y,4) = 0.0
            CALL bug('w',
     *        'WinCoord: Cannot reset sub-window for (x,y)=' //
     *        itoaf(x) // ' ' // itoaf(y))
            RETURN
	ENDIF
	CALL pgsvp(win0(x,y,1),win0(x,y,2),win0(x,y,3),win0(x,y,4))
	CALL pgswin(win1(x,y,1),win1(x,y,2),win1(x,y,3),win1(x,y,4))
	RETURN
	END
c************************************************************************
c* WinToScr -- convert a point to screen coordinates
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinToScr( x, y, px, py )
	implicit none
	real px, py
	integer x, y
c
c    WinToScr converts {xpos, ypos} from user coordinates to screen
c    coordinates, such as those returned by WinCurs.
c--
c------------------------------------------------------------------------
	include 'win.h'
c
	px = ( px - win1(x,y,1) ) / ( win1(x,y,2) - win1(x,y,1) )
	py = ( py - win1(x,y,3) ) / ( win1(x,y,4) - win1(x,y,3) )
	px = px * ( win0(x,y,2) - win0(x,y,1) ) + win0(x,y,1)
	py = py * ( win0(x,y,4) - win0(x,y,3) ) + win0(x,y,3)
	return
	end
c************************************************************************
c* WinToUsr -- convert a point to screen coordinates
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinToUsr( x, y, px, py )
	implicit none
	real px, py
	integer x, y
c
c    WinToUsr converts {xpos, ypos} from screen coordinates to user
c    coordinates.
c--
c------------------------------------------------------------------------
	include 'win.h'
c
	px = ( px - win0(x,y,1) ) / ( win0(x,y,2) - win0(x,y,1) )
	py = ( py - win0(x,y,3) ) / ( win0(x,y,4) - win0(x,y,3) )
	px = px * ( win1(x,y,2) - win1(x,y,1) ) + win1(x,y,1)
	py = py * ( win1(x,y,4) - win1(x,y,3) ) + win1(x,y,3)
	return
	end
c************************************************************************
c* WinCurs -- get a character from a window
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	SUBROUTINE WinCurs( nx, ny, px, py, c )
	REAL      px, py
	INTEGER   nx, ny
	CHARACTER c*1
c
c    WinCurs gets a character from the screen and returns an absolute
c    position in {xpos, ypos}.  If the character was typed from within
c    an active plot, then the window number is returned in {nx, ny},
c    otherwise {nx, ny} is {0, 0}.  See WinToScr and WinToUsr.
c    If the device did not have a cursor (like printers) char(0) is
c    returned in c.
c--
c------------------------------------------------------------------------
	include 'win.h'
	character ans*1
	integer length
	real xsave, ysave
	save xsave, ysave
	data xsave, ysave / 0.5, 0.5 /
c
	call pgqinf('CURSOR',ans,length)
	if (ans.eq.'n' .or. ans.eq.'N') then
	    c = CHAR(0)
            return
        endif
	call pgsvp( 0.0, 1.0, 0.0, 1.0 )
	call pgswin( 0.0, 1.0, 0.0, 1.0 )
	call pgcurs( xsave, ysave, c )
	px = xsave
	py = ysave
	do nx = WinNXlo, WinNXhi
	do ny = WinNYlo, WinNYhi
	    if(   ( px .ge. win0(nx,ny,1) )
     *	    .and. ( px .le. win0(nx,ny,2) )
     *	    .and. ( py .ge. win0(nx,ny,3) )
     *	    .and. ( py .le. win0(nx,ny,4) ) ) return
	enddo
	enddo
	nx = 0
	ny = 0
	return
	end
c************************************************************************
c* WinNear -- return the nearest point
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine WinNear( nx, ny, xpos, ypos, count, x, y, 
     *                      idx, dist )
	implicit none
	integer count, nx, ny, idx
	real xpos, ypos, x(*), y(*), dist
c
c    WinNear finds the nearest data point to an absolute position.
c    The ordinal number of the data point is returned if the point
c    is unambiguous, otherwise the negative is returned.
c--
c
c  MARGIN -- margin of ambiguity
c------------------------------------------------------------------------
	integer MARGIN
	parameter( MARGIN = 2.0 )
c
	integer n, n1
	real d, d1, d2
	real x0, y0
c
	n = 1
	n1 = n
	x0 = x(n)
	y0 = y(n)
	call WinToScr( nx, ny, x0, y0 )
	d1 = ((x0 - xpos) * (x0 - xpos)) + ((y0 - ypos) * (y0 - ypos))
	d2 = 10.0 * d1 + 1.0
	do n = 2, count
	    x0 = x(n)
	    y0 = y(n)
	    call WinToScr( nx, ny, x0, y0 )
	    d = ((x0 - xpos)*(x0 - xpos)) + ((y0 - ypos)*(y0 - ypos))
	    if( d .lt. d1 ) then
		d2 = d1
		d1 = d
		n1 = n
	    else if( d .lt. d2 ) then
		d2 = d
	    endif
	enddo
	d1 = sqrt(d1)
	d2 = sqrt(d2)
	if( d2 .lt. MARGIN * d1 ) then
	    idx = -n1
	else
	    idx = n1
	endif
        dist = d1
        return
	end
c************************************************************************
c* pgerase -- erase the screen - and nothing more
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	SUBROUTINE pgerase
c
c  Erase the screen: it calls PGPAGE to erase the screen, but also
c  sets PGASK to be false as not to get to interactively advance
c  to the next window....
c--
c------------------------------------------------------------------------
	CALL pgask(.FALSE.)
	CALL pgpage
	RETURN
	END
c************************************************************************
c* WinShow -- put the plots onto the screen
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	SUBROUTINE winshow( xlabel, ylabel, title, func )
	IMPLICIT NONE
	CHARACTER*(*) xlabel(*), ylabel(*), title
	EXTERNAL      func
c
c    WinShow shows the plot on the screen by setting up the appropriate
c    PGPLOT coordinates and calling func() on each window.  Func() is a
c    user supplied routine which should draw the contents of the plot.
c    WinShow currently draws the box and labels, which are supplied in
c    the arrays xlabel and ylabel.  The title is drawn in a smaller font
c    so more information can be printed.
c
c    The calling sequence of func is:
c
c		subroutine func(x, y)
c		integer x, y
c
c    where the inputs (x,y) represent the panel to be plotted.
c--
c------------------------------------------------------------------------
	call wintshow(xlabel, ylabel, title, func, 0.0)
	return
	end
c************************************************************************
c* WinTShow -- put the plots onto the screen
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	SUBROUTINE wintshow( xlabel, ylabel, title, func, tfac )
	IMPLICIT NONE
	CHARACTER*(*) xlabel(*), ylabel(*), title
        REAL          tfac
	EXTERNAL      func
c
c    WinTShow shows the plot on the screen by setting up the appropriate
c    PGPLOT coordinates and calling func() on each window.  Func() is a
c    user supplied routine which should draw the contents of the plot.
c    WinTShow currently draws the box and labels, which are supplied in
c    the arrays xlabel and ylabel.  The title is drawn in a smaller font
c    so more information can be printed.  If the input scaling factor,
c    tfac, is non-zero, then the labels on the top axes will be drawn in
c    HMS and the bottom axes in regular units.  The units are multiplied
c    by tfac to convert to HMS units.  If the current box units are in
c    decimal hours, then tfac should be set to 86400.  Compare the PGPLOT
c    routines PGBOX and PGTBOX for more details.  If tfac=0, then the
c    same units will be used to display the top and bottom of the boxes.
c
c    The calling sequence of func() is:
c
c		subroutine func(x, y)
c		integer x, y
c
c    where the inputs (x,y) represent the panel to be plotted.
c--
c------------------------------------------------------------------------
	include 'win.h'
c
c  MARGIN1 -- inner plotting margin
c
	real MARGIN1
	parameter( MARGIN1 = 0.005 )
c
c  MARGIN2 -- outer plotting margin
c
	REAL MARGIN2
	PARAMETER( MARGIN2 = 0.06 )
c
        REAL ytop
        PARAMETER( ytop = 0.93 )
c
	INTEGER x, y, nlab
	REAL    xwidth, ywidth, wider, size
	LOGICAL numbers
c
	numbers = .TRUE.
	wider = 1.0
	if( numbers ) wider = 1.2
c
	xwidth = ( 1.0 - 2 * MARGIN2 ) / real(WinNXhi - WinNXlo + 1)
	ywidth = (ytop - 2 * MARGIN2 ) / real(WinNYhi - WinNYlo + 1)
c
	call pgbbuf
	CALL pgqch(size)
	CALL pgerase
	CALL pgsvp( 0.0, 1.0, 0.0, 1.0 )
        CALL pgsch(0.9 * size)
	call pgmtxt('T', -2.1, 0.5, 0.5, title)
	do x = WinNXlo, WinNXhi
	do y = WinNYlo, WinNYhi
	    win0(x,y,1) = wider * MARGIN2 + 
     *			(x-WinNXlo  ) * Xwidth + MARGIN1
	    win0(x,y,2) = wider * MARGIN2 +
     *			(x-WinNXlo+1) * Xwidth - MARGIN1
	    win0(x,y,3) = wider * MARGIN2 +
     *			(y-WinNYlo  ) * Ywidth + MARGIN1
	    win0(x,y,4) = wider * MARGIN2 +
     *			(y-WinNYlo+1) * Ywidth - MARGIN1
	    call WinCoord( x, y )
	    call pgsch(size)
	    call func(x, y)
	    if( x .eq. WinNXlo ) then
c 						===> left edge
		if( NUMBERS ) then
		    call pgsch(0.6 * size)
		    call pgtbox( ' ', 0.0, 0, 'N', 0.0, 0 )
		endif
		call pgsch(0.7 * size)
                nlab = x + (y-1) * WinMaxX
		call pgmtxt('L', 2.2, 0.5, 0.5, ylabel(nlab))
	    endif
	    if( y .eq. WinNYlo ) then
c						===> bottom edge
		if( NUMBERS ) then
		    call pgsch(0.6 * size)
		    call pgtbox( 'N', 0.0, 0, ' ', 0.0, 0 )
		endif
		call pgsch(0.7 * size)
                nlab = x + (y-1) * WinMaxX
		call pgmtxt('B', 2.2, 0.5, 0.5, xlabel(nlab))
	    endif
            if( y .eq. WinNYhi .and. WinNYlo .ne. WinNYhi) then
c						===> top edge
                if( NUMBERS ) then
		    call pgsch(0.6 * size)
                    if (tfac .ne. 0.0) then
			call pgswin(win1(x,y,1)*tfac,win1(x,y,2)*tfac,
     *                            0.,1.)
			call pgtbox( 'CMSTHZ', 0.0, 0, ' ', 0.0, 0 )
                    else
			call pgtbox( 'M', 0.0, 0, ' ', 0.0, 0 )
                    endif
                endif
		call pgsch(0.7 * size)
                nlab = x + (y-1) * WinMaxX
		call pgmtxt('T', 2.5, 0.5, 0.5, xlabel(nlab))
            else
c                                               ===> other tops
                if( NUMBERS ) then
                    if (tfac .ne. 0.0) then
			call pgsch(0.6 * size)
			call pgswin(win1(x,y,1)*tfac,win1(x,y,2)*tfac,
     *                            0.,1.)
			call pgtbox( 'CSTHZ', 0.0, 0, ' ', 0.0, 0 )
                    endif
                endif
            endif
	enddo
	enddo
	call pgsch(size)
	call pgebuf
	return
	end
c************************************************************************
c* winpoint -- draw points
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	subroutine winpoint( n, x, y, ipt )
	implicit none
	integer n, ipt(*)
	real x(*), y(*)
c
c    WinPoint draw a set of points - the symbol indicator is not
c    exactly in the order of the standard pgplot graph markers,
c    but a lookup table is used which reorder them a bit. Just
c    a silly preference based history...
c
c   Input:
c       n     integer       Number of points in arrays
c       x     real          Array of X-coordinates of points
c       y     real          Array of Y-coordinates of points
c       ipt   integer       Array of graph markers
c--
c------------------------------------------------------------------------
        INTEGER i
        REAL size
c
	call pgbbuf
	call pgqch(size)
	call pgsch(0.5 * size)
        DO i=1,n
	   CALL pgpt( 1, x(i), y(i), 64+ipt(i))
        ENDDO
	call pgsch(size)
	call pgebuf
	return
	end
c************************************************************************
c* winsymb -- return win2pgplot symbol marker
c& pjt
c: plotting,PGPLOT,user-interaction
c+
	integer function winsymb( i )
	implicit none
	integer i
c
c   Input:
c       i        integer        win symbol marker
c   Output:
c	winsymb  integer	pgplot symbol marker (0..31)
c--
c------------------------------------------------------------------------
	INTEGER winidx(32)
        DATA winidx/17,18,16,13,4,15,3,2,24*1/
c
	IF (i.LE.0 .OR. i.GE.32) THEN
	    winsymb = 0
        ELSE
c            winsymb = winidx(i)
            winsymb = i+64
        ENDIF
	RETURN
        END
c************************************************************************
c* WinNormY -- normalize plots and add a margin
c& pjt
c: plotting,PGPLOT,user-interaction
c+
        subroutine WinNormY( margin )
	implicit none
        real margin
c
c    WinNormY normalizes the set of active windows to have the same user
c    Y coordinates ONLY and adds a margin around the data.  A margin of
c    0.1 is recommended.
c--
c------------------------------------------------------------------------
        include 'win.h'
c
        integer nx, ny
        real lower, minY, maxY
c
        if( margin .le. -0.5 ) call WinError( 'WinNorm:  bad margin' )
c
        minY = win1( WinNXlo, WinNYlo, 3 )
        maxY = win1( WinNXlo, WinNYlo, 4 )
        do nx = WinNXlo, WinNXhi
        do ny = WinNYlo, WinNYhi
            minY = min( minY, win1( nx, ny, 3 ) )
            maxY = max( maxY, win1( nx, ny, 4 ) )
        enddo
        enddo
c
	if(maxY .le. minY) then
           maxY = minY
           lower = minY
           if (lower .eq. 0.0) lower = 1.0
	   minY = minY - (0.01 * abs(lower))
	   maxY = maxY + (0.01 * abs(lower))
        endif
        if (abs(maxY - minY) .lt. 1.0E-5) then
	    maxY = minY + (margin / 2.0)
	    minY = minY - (margin / 2.0)
	endif
c
        do nx = WinNXlo, WinNXhi
        do ny = WinNYlo, WinNYhi
            win1(nx,ny,3) = minY - (margin * (maxY - minY))
            win1(nx,ny,4) = maxY + (margin * (maxY - minY))
        enddo
        enddo
	return
        end
c************************************************************************
c* WinSet -- set max unzoomed window matrix
c& pjt
c: plotting,PGPLOT,user-interaction
c+
        subroutine WinSet( Xhi, Yhi )
	implicit none
        integer Xhi, Yhi
c
c    WinSet sets-up the maximum number of x-windows and y-windows
c    allowed in all future calls. This routine must be called before
c    calling WinPick or WinPick1
c--
c------------------------------------------------------------------------
        include 'win.h'
c
        if(Xhi .le. NXMAX) then
           WinMaxX = Xhi
        else
           call WinError( 'WinSet: Xhi out of range')
        endif
        if(Yhi .le. NYMAX) then
           WinMaxY = Yhi
        else
           call WinError( 'WinSet: Yhi out of range')
        endif
        call WinPick( 1, WinMaxX , 1, WinMaxY)
        return
        end
c************************************************************************
c* WinqScal -- queries set window user scales for selected window
c& pjt
c: plotting,PGPLOT,user-interaction
c+
        subroutine WinQScal( Xlo, Xhi, Ylo, Yhi )
	implicit none
        real Xlo, Xhi, Ylo, Yhi
c
c    WinQScal returns the user coordinates of a plot window.  Select
C    desired window using WinPick1. See WinScale.
c--
c------------------------------------------------------------------------
        include 'win.h'
        integer NX, NY
c
        NX = WinNXlo
        NY = WinNYlo
        Xlo = win1( NX, NY, 1 ) 
        Xhi = win1( NX, NY, 2 )
        Ylo = win1( NX, NY, 3 )
        Yhi = win1( NX, NY, 4 )
	return
        end
