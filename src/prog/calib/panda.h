	include 'maxdim.h'
	include 'mem.h'
	integer MAXSOL
	parameter(MAXSOL=1000000)
	integer head(MAXBASE),nsols
	integer gidx(MAXSOL), fidx(MAXSOL),next(MAXSOL)
	double precision initial, time(MAXSOL)
	double precision t(MAXSOL),baseline(MAXSOL),delay(MAXSOL)
	common/pandac/time,gidx,fidx,next,head,baseline,t,delay,nsols
