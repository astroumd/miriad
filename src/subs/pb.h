        include 'maxdim.h'
	integer POLY,GAUS,COS6,SINGLE,IPOLY,BLOCKED
	parameter(POLY=1,GAUS=2,COS6=3,IPOLY=4,BLOCKED=5,SINGLE=6)
	integer MAXPB,MAXVAL,NCONV
	parameter(MAXPB=50,MAXVAL=250,NCONV=10)
c
	character pb(MAXPB)*16,descrip(MAXPB)*32
	integer pbtype(MAXPB),npbvals,npb,indx(MAXPB),nvals(MAXPB)
	real f1(MAXPB),f2(MAXPB),cutoff(MAXPB),pbfwhm(MAXPB)
	real pbvals(MAXVAL),maxrad(MAXPB)
c
	integer pbhead
	real xc(MAXPNT),yc(MAXPNT),x0(MAXPNT),y0(MAXPNT),fwhm(MAXPNT)
	real freq(MAXPNT), xn(MAXPNT), yn(MAXPNT), bandw(MAXPNT)
	integer pnt(MAXPNT),pnt2(MAXPNT)
        logical conv(MAXPNT)
c
	common/pb1com/ f1,f2,cutoff,pbfwhm,pbvals,xc,yc,x0,y0,fwhm,freq,
     *	    maxrad,xn,yn,bandw, pbtype,npbvals,npb,indx,nvals,pbHead,
     *      pnt,pnt2,conv
	common/pb1comc/pb,descrip
