	program test8
c
	integer   i
	integer   i4
	integer*8 i8

	i4 = 1
	i8 = 1
	do i=1,63
	  write(*,*) i4,i8
	  i4 = i4 * 2
	  i8 = i8 * 2
 	end do

	end

