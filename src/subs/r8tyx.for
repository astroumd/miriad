C************************************************************************
c* r8tyx -- Radix, 8 iterations
c& mchw
c: mathematics
c+
      subroutine r8tyx(nxtlt, nthpo, lengt, cs,
     *			c0, c1, c2, c3, c4, c5, c6, c7)
c--
C
      implicit none
      integer nxtlt, nthpo, lengt
      complex c0(*),c1(*),c2(*),c3(*),c4(*),c5(*),c6(*),c7(*)
      complex cs(*)
c
c  radix - 8 iterations.
c
c------------------------------------------------------------------------
      real p7
      parameter(p7=0.7071067811865475)
      complex a0,a1,a2,a3,a4,a5,a6,a7,b0,b1,b2,b3,b4,b5,b6,b7
      integer j,k
      integer i1,i2,i3,i4,i5,i6,i7
      integer inc1,inc2,inc3,inc4,inc5,inc6,inc7
c
      i1 = 1
      i2 = 1
      i3 = 1
      i4 = 1
      i5 = 1
      i6 = 1
      i7 = 1
      inc1 = nthpo/lengt
      inc2 = inc1 + inc1
      inc3 = inc1 + inc2
      inc4 = inc1 + inc3
      inc5 = inc1 + inc4
      inc6 = inc1 + inc5
      inc7 = inc1 + inc6
c
c#nooptimize
      do j=1,nxtlt 
        do k=j,nthpo,lengt
          a0 = c0(k) + c4(k)
          a4 = c0(k) - c4(k) 
          a2 = c2(k) + c6(k)
          a6 = c2(k) - c6(k)
	  a6 = cmplx(-aimag(a6),real(a6))
c
          b0 = a0 + a2
          b2 = a0 - a2
	  b4 = a4 + a6
	  b6 = a4 - a6
c
          a1 = c1(k) + c5(k)
          a5 = c1(k) - c5(k)
          a3 = c3(k) + c7(k)
          a7 = c3(k) - c7(k)
	  a7 = cmplx(-aimag(a7),real(a7))
c
          b1 = a1 + a3
          b3 = a1 - a3
	  b3 = cmplx(-aimag(b3),real(b3))
	  b5 = a5 + a7
	  b5 = cmplx(p7*(real(b5)-aimag(b5)),p7*(real(b5)+aimag(b5)))
	  b7 = a5 - a7
	  b7 = cmplx(-p7*(real(b7)+aimag(b7)),p7*(real(b7)-aimag(b7)))
c
c#ifndef vector
	  if(j.gt.1)then
c#endif
	    c0(k) = b0 + b1
            c1(k) = cs(i4) * (b0 - b1)
	    c2(k) = cs(i2) * (b2 + b3)
	    c3(k) = cs(i6) * (b2 - b3)
	    c4(k) = cs(i1) * (b4 + b5)
	    c5(k) = cs(i5) * (b4 - b5)
	    c6(k) = cs(i3) * (b6 + b7)
	    c7(k) = cs(i7) * (b6 - b7)
c#ifndef vector
	  else
	    c0(k) = b0 + b1
	    c1(k) = b0 - b1
            c2(k) = b2 + b3
            c3(k) = b2 - b3
            c4(k) = b4 + b5
            c5(k) = b4 - b5
	    c6(k) = b6 + b7
	    c7(k) = b6 - b7
	  endif
c#endif
	enddo
	i1 = i1 + inc1
	i2 = i2 + inc2
	i3 = i3 + inc3
	i4 = i4 + inc4
	i5 = i5 + inc5
	i6 = i6 + inc6
	i7 = i7 + inc7
      enddo
      end
