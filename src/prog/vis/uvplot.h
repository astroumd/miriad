c--------------------------------------------
c	uvplot.h - include file for uvplot
c--------------------------------------------
	integer itlen, MAXPTS
	parameter (itlen=216,MAXPTS=1000)
c  size of table and maximum number of rows in table
	integer vnum	
	character*8 varname(itlen)
c					!variable name or CHAN
	character*9 vflag(itlen)
c					!amp/phase
	real vsubs(itlen)
c					!subscript or channel
	character*10 vants(itlen)
c					!antenna flag
	double precision vvalue(itlen)
c					!accumulator for aver
	double precision vvalue2(itlen)
c					!value**2  accumulator
	double precision vsamp(itlen)
c					!samples accumulator
	common /vtablec/ varname,vflag,vants
	common /vtablen/ vvalue,vvalue2,vsamp,vnum,vsubs
