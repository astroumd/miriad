        integer MAXPNT
        parameter (MAXPNT = 10000 )
        integer MAXPLOT
        parameter( MAXPLOT = 30 )
        integer nvals
        real    xvals(MAXPLOT,MAXPNT), yvals(MAXPLOT,MAXPNT)
        common /HOOBIE/ nvals, xvals, yvals
