	integer MAXBUF
	parameter (MAXBUF=1000000)
	real memr(MAXBUF)
	integer memi(MAXBUF)
	equivalence(memr,memi)
	common memr
