C
C $Header$
C
C $Log$
C Revision 1.1.1.1  1990/09/28 21:50:14  teuben
C UIUC 15-feb-2001 w/out wip and some manuals
C
c Revision 1.1  90/03/29  10:06:40  pwebb
c Initial revision
c 
C
C Copyright (C) 1988
C The Board of Trustees of the University of Illiniois at Urbana-Champaign
C
C No warranty is expressed or implied.
C Permission is hereby granted to copy and distribute this material without
C charge provided that this NOTICE is retained.
C
C This material was developed at
C The National Center for Supercomputing Applications.
C Author:   Mark Straka
C-
C   Sun_to_Cray_32-bit_Floating-point (with unpacking) conversion routine.
C   USAGE:   call scup32 (sarray, carray, size)
C   WHERE    sarray is the array of 32-bit IEEE floating-point numbers
C            (packed 2 per word) to be converted 64-bit Cray format
C            and stored in carray.  Size is the dimension
C            of the output carray.  (sarray is assumed to be (size+1)/2 ).
C            Icheck is not used.
C
       subroutine scup32 (sarray,carray,size,icheck)
       integer size,sarray(0:(size+1)/2-1),carray(0:size-1),temp
cdir$ ivdep
       do 10 i=0,(size+1)/2-1
          carray(2*i)=and(sarray(i),x'ffffffff00000000')
          carray(2*i+1)=shiftl(sarray(i),32)
10     continue
       do 20 i=0,size-1
          temp=carray(i)
          CARRAY(I)=OR(OR(AND(carray(I),X'8000000000000000'),SHIFTR
     &      (AND(carray(I),X'7F80000000000000'),7)+shiftl(16258,48)),or(
     &shiftr(AND(carray(I),X'007FFFFF00000000'),8),X'0000800000000000'))
          carray(i)=cvmgn(carray(i),0,shiftl(temp,1))
20     continue
       end



