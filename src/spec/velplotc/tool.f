ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Called by c-program to get the value of certain keyword
c	
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc	
	subroutine checkkeyword(keyword,keylen,valuestring)
	character keyword*20,valuestring*35
	integer i,keylen,arglen,argnum,narg
	character arg*35
c  Externals.
	integer iargc,len1
c

c	keylen=len1(keyword)
	valuestring="\0"
c	write(*,*) "get:",keyword(1:keylen)
	narg = iargc()
	argnum = 0

	do i=1,narg
	  call getarg(i, arg)
	  arglen = len1(arg)
c	  write(*,*) i,arglen,arg
	  if (arglen.ge.keylen+2) then
	    if (keyword(1:keylen).eq.arg(1:keylen).and.
     &		arg(keylen+1:keylen+1).eq."=") then
		arg(arglen+1:arglen+1)="\0"
		valuestring=arg(keylen+2:arglen+1)
		return
	    endif
	  end if
c	  write(*,*) argnum,arg(1:arglen)
	  argnum = argnum + 1
	enddo
	return
	end

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c	Sin and cos with argument in degree
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        real function cosd(angle)
        real angle
        cosd=cos(acos(-1.0)*angle/180.0)
        return
        end

        real function sind(angle)
        real angle 
        sind=sin(acos(-1.0)*angle/180.0)
        return
        end

	subroutine maxmap(ary,nx,ny,is,ie,js,je,
     *		amax,imax,jmax,amin,imin,jmin,ave,rms,num)
	implicit none
	integer nx,ny,is,ie,js,je,imax,jmax,imin,jmin,num
	real ary(nx,ny),amax,amin,ave,rms
c
c  Find max, min and rms in specified region of real array.
c			MCHW Jan 1986
c    pixel blanking: ignore values .lt. -99999.  wh feb 87
c
c  Inputs:
c    ary	array of values.
c    nx,ny	dimensions of ary
c    is,ie,js,je  L,R,B,T of region to search.
c
c  Outputs:
c    max,min	maximum and minimum in specified region.
c    imax,jmax	position of maximum.
c    imin,jmin	position of minimum.
c    ave,rms	average and rms in specified region.
c    num	number of pixels greater than -99999
c----------------------------------------------------------------------c
	integer i,j
	real a,sum,sumsq
c
c	write(*,*) "nx",nx,ny
	amax = -1.e9
	amin = 1.e9
	sum = 0.
	sumsq = 0.
	num = 0
	do j = js,je
	  do i = is,ie
	    a = ary(i,j)
	    if(abs(a+99999.).gt.0.5) then
	      sum = sum + a
	      sumsq = sumsq + a*a
	      num = num + 1
	      if(a.gt.amax) then
		amax = a
		imax = i
		jmax = j
	      else if (a.lt.amin) then
		amin = a
		imin = i
		jmin = j
	      endif
	    endif
	  enddo
	enddo
c
	if(num.gt.0)then
	  ave = sum/num
	  rms = sqrt(sumsq/num) - ave*ave
	endif
	end

	integer function ifirstfound(string,s1)
	character string*(*),s1*1
	integer lens,i
	lens=len1(string)
	ifirstfound=0
	do i=lens,1,-1
	  if (string(i:i).eq.s1) then
	     ifirstfound=i
	     return
	  end if
	end do
	return
	end

	integer function itlength(str)
	character str*(*)
	integer i
	do i=1,1000
	  if (str(i:i).lt."") then
	   itlength=i-1
	   return
	  end if
	end do
	return
	end

	subroutine stripspace(str)
	character str*(*)
	integer itlength,len,i,j
	len= len1(str)
	j=0
	do i=1,len
	  if (str(i:i).ne." ") then
	    j=j+1
	    if (j.ne.i) then
	      str(j:j)=str(i:i)
	      str(i:i)=" "
	    end if
	  end if
	end do
	return
	end

	real function realchar(s)
	real factor
        integer l,idot,iexp,inexp,len,k,in,index
        character s*32,ch(32)*1,s1*1
	character tab,returnn,space,empty
	integer ierror
	common/realerror/ierror
	ierror=0
c	define common character
c	space=char(32) or " "
	tab="\t"
	returnn="\n"
	space=" "
	empty="\0"
	len=0
c	s=" -1.2e-12"
c	write(*,*) "s=",s
	realchar=0.0
c	remove spaces at the beginning of the character
	do i=1,32
	  if (s(i:i).eq.empty.or.s(i:i).eq.returnn) goto 40
	  if (s(i:i).ne.space.and.s(i:i).ne.tab) goto 10
	end do
10	continue
	factor=1.0
	l=i
	if (s(i:i).eq."-".or.s(i:i).eq."+") then
	   l=i+1
	   if (s(i:i).eq."-") factor=-1.0
	endif
	idot=0
	iexp=0
	inexp=0
	do i=l,32
	  s1=s(i:i)
	  ch(i-l+1)=s1
	  if (s1.eq.space.or.s1.eq.returnn.or.
     +	      s1.eq.empty.or.s1.eq.tab) then
	     len=i-l
	     goto 20
	  endif
	  if (s1.eq."-".or.s1.eq."+") then
 	     if (inexp.ne.0) goto 40
	     inexp=i-l+1
	  endif
	  if (s1.eq.".") then
 	     if (idot.ne.0) goto 40
	     idot=i-l+1
	  endif
	  if (s1.eq."e".or.s1.eq."E".or.s1.eq."d".or.s1.eq."D") then
	      if (iexp.ne.0) goto 40
	      iexp=i-l+1
	  endif
	  k=ichar(s1)
	  if (k.lt.ichar("0").or.k.gt.ichar("9")) then
            if (s1.ne.".".and.s1.ne."e".and.s1.ne."E".and.s1.ne."d".and
     +       .s1.ne."D".and.s1.ne."-".and.s1.ne."+") goto 40
	  endif
	end do
20	continue
	index=0
	if (iexp.ne.0) then
	  if (iexp.eq.len.or.idot.gt.iexp) goto 40
	  if (inexp.ne.0) then
	    if (inexp.ne.iexp+1.or.inexp.eq.len) goto 40
	    in=1
	    if (ch(inexp).eq."-") in=-1
	    do k=len,inexp+1,-1
	       index=index+(ichar(ch(k))-ichar('0'))*10**(len-k)
	    end do
	    index=in*index
	  else
	    do k=len,iexp+1,-1
	       index=index+(ichar(ch(k))-ichar('0'))*10**(len-k)
	    end do
	  endif
	  len=iexp-1
	end if
	if (iexp.eq.0) then
	   if (inexp.ne.0) goto 40 
	endif
	if (idot.eq.0) idot=len+1
        do i=1,idot-1
           realchar=realchar+
     +         real(ichar(ch(i))-ichar('0'))*10.0**(idot-i-1)
        end do
        do i=idot+1,len
           realchar=realchar+
     +         real(ichar(ch(i))-ichar('0'))*10.0**(idot-i)
        end do
        realchar=realchar*factor*10.0**real(index)
        return
40	call error(1)
	ierror=1
	return
        end

	subroutine error(n)
	integer n
	character trans*20
	if (n.eq.1) write(*,*) "Error converting string to real number"
	if (n.eq.2) write(*,*) "Error: call keyini first"
c	call exit(1)
c	stop
	end

c	convert the white space into end of line
c	adding a "\0" to the tstring that doesnot have
	character*20 function trans(a)
	character a*(*)
	trans=a
c	stripe trailing white spaces
	do i=len(trans),1,-1
	  if (trans(i:i).gt." ") goto 15
	  trans(i:i)="\0"
	enddo
15	return
	end

	subroutine separation(separator,string,strlen,nvalue,value)
	character separator*1,string*50
	integer nvalue,strlen,i,ni,nf
	integer ierror
	common/realerror/ierror
	real value(20)
	string(strlen+1:strlen+1)=separator
	ni=1
	nvalue=0
	do i=1,strlen+1
	  if (string(i:i).eq.separator) then
	    nf=i-1
	    if (nf.lt.ni) then
	      nvalue=0      ! Error Input
	      return
	    endif
	    nvalue=nvalue+1
	    string(i:i)="\0"
c	    write(*,*) "error[",string(ni:nf),"]",ierror
	    value(nvalue)=realchar(string(ni:nf))
	    ni=i+1
	    if (ierror.eq.1) then
	      nvalue=0
	      ierror=0
	      return
	    end if
	  endif
	end do
	return
	end

        subroutine setconts(isneg,fmax,fmin,conflag,
     +      nconarg,conargs,conlevel,numcon)
        logical isneg
        real fmax,fmin
        integer numcon
        real conlevel(50)
c
c  Setconts uses the contour -conflag and
c		conargs(nconarg) and its arguments to create a list of
c		contours.
c		conflag is made up of one letter codes which mean:
c		p means the contour values are percentages of the maximum.
c		i means the contour values are a list of contour values.
c		a means the contour values are absolute numbers.
c		if i is not present, the first contour value is used as a
c		step to compute the other values between the min and max of
c		the map.
c  Inputs:
c    isneg	true means  get negative contours
c    fmax,fmin	Maximum and minimum values in image.
c  Outputs:
c    conlevel	Array of contour values.
c    numcon	The number of conlevel.
c-------------------------------------------------------c
        character*10 conflag
        real plusmin, themax, conval
        real conargs(50)
        integer nconarg,i
c
        if (isneg) then
          plusmin = -1.
          themax = abs(fmin)
        else
          plusmin = 1.
          themax = abs(fmax)
        end if
        numcon = 0
c
c
c  Itemized percentage contours.
c

        if (index(conflag,'i').gt.0 .and. index(conflag,'p').gt.0)
     *                                                           then
          do 90000 i=1,nconarg
            conval = conargs(i)/100.*abs(fmax)
            if(abs(conval).le.themax.and.(conval*plusmin.ge.0)) then
              numcon = numcon + 1
              conlevel(numcon) = conval*plusmin
            end if
90000     continue
c
c  Itemized absolute contours.
c
        else if (index(conflag,'i').gt.0) then
          do 90001 i=1,nconarg
            numcon = numcon + 1
            conlevel(numcon) = conargs(numcon)*plusmin
90001     continue
c
c  Absolute contours.
c
        else if (index(conflag,'a').gt.0) then
90002     if(numcon.lt.50 .and.
     *                  (numcon+1)*abs(conargs(1)).le.themax)then
            numcon = numcon+1
            conlevel(numcon) = numcon*plusmin*abs(conargs(1))
          goto 90002
          endif
c
c  Percentage contours.
c
        else if (index(conflag,'p').gt.0) then
90003     if(numcon.lt.50  .and.
     *      (numcon+1)*abs(conargs(1))*fmax/100..le.themax)then
            numcon = numcon+1
            conlevel(numcon) =
     *                  numcon*plusmin*abs(conargs(1))*fmax/100.
	    goto 90003
          endif
        end if
        end
