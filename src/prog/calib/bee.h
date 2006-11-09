c********1*********2*********3*********4*********5*********6*********7*c
c		include 'bee.h'
c	include file for BEE - MCHW Jan 1986
c	small 'flint' appeasing   PJT  Jan 1992
c	added focus values - mchw 05may93
c	included constants and telescope parameters
c	declarations before common to appease FLINT and PJT mchw 02dec93
c	23dec94 mchw increase MAXSOLS to 2048
c	02aug95 mchw added elev to common/base/
c	01nov2006 mchw increase MAXANTS to 64
c	08nov2006 mchw increase MAXSOLS to 4096
c----------------------------------------------------------------------c
c
        integer MAXANTS,MAXSOLS
        parameter(MAXANTS=64,MAXSOLS=4096)
c
c  Source list.
c
	integer NSMAX
	parameter(NSMAX=100)
	logical stf(NSMAX)
	character*8 sname(NSMAX)
	real sra(NSMAX),sdec(NSMAX)
	integer ns
	common /slist1/ ns, stf, sra, sdec
	common /slist2/ sname
c
c  Inputs and antenna.
c  vis		input filename for plot header.
c  antenna	current antenna stored in data base.
c  refant	reference antenna for gains.
c  refpwr	reference antenna for tpower.
c  amdone	Amplitude fitting done
c  phdone	Phase fitting done
c  eddone	Editing done
c
	integer antenna,refant,refpwr
	character*64 vis,out
	character*1 amdone(MAXANTS), phdone(MAXANTS), eddone(MAXANTS)
	common /input1/ antenna,refant,refpwr
	common /input2/ vis,out, amdone, phdone, eddone
c
c  bee common variables
c  amp and pase and the observed amplitude and phase. 
c  ampint and phint and the fitted amplitude and phase. 
c  edph is the edited phase for the current antenna.
c  antenna positions: b - original, c - fitted, bnew - last change.
c  phed is true if instrumental phase is subtracted)
c
	integer np,is(MAXSOLS)
	real ha(MAXSOLS),dec(MAXSOLS),tim(MAXSOLS),tair(MAXSOLS),
     *    frq(MAXSOLS),pase(MAXSOLS),amp(MAXSOLS),edph(MAXSOLS),
     *    phint(MAXSOLS),ampint(MAXSOLS),tpower(MAXSOLS),focus(MAXSOLS),
     *    elev(MAXSOLS)
	real b(6),c(6),bnew(6)
	logical phed
	common/base/np,is,ha,dec,tim,tair,frq,pase,amp,edph,phint,
     *              tpower,focus,b,c,bnew,phed,ampint,elev
c  
c  amp/phase correction array 
c  
	integer nph
	real xph(MAXSOLS),yph(MAXSOLS)
	common /pharay/ nph,xph,yph
c
c  gains,antfit  - are the fitted gains and antenna positions.
c  nants,nsols,interval,antpos,dtime - are the original inputs.
c  
	integer nants,nsols
	double precision interval,antpos(3*MAXANTS),dtime(MAXSOLS)
	complex gains(MAXANTS,MAXSOLS)
	double precision antfit(MAXANTS,6)
	common/gain/interval,antpos,dtime,antfit,gains,nants,nsols
c  
c  constants and telescope parameters
c  
	real pi,tupi,rlat,slat,clat,sinel,cosel
	parameter(pi=3.141592654,tupi=6.283185307)
	common/telescope/ rlat,slat,clat,sinel,cosel
c********1*********2*********3*********4*********5*********6*********7*c
