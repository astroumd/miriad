C
C $Header$
C
C $Log$
C Revision 1.1  1990/09/28 21:49:42  teuben
C Initial revision
C
c Revision 1.1  90/03/29  10:05:45  pwebb
c Initial revision
c 
C
C+
C N O T I C E
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
C   Cray_to_Sun_32-bit_floating-point (with packing) conversion routine.
C   USAGE:   call cspk32 (carray, sarray, size, icheck)
C   WHERE    carray is the array of Cray floating point numbers
C            (64 bit) to be converted to 32-bit IEEE format
C            reals and packed 2 to 1 (high to low order) in sarray.
C            Size is the dimension of the input carray.
C            (sarray is assumed to be (size+1)/2 )
C            Icheck, if 1, provides checking for over/underflow
C            and writes the appropriate "infinity" pattern.
C
       subroutine cspk32 (carray,sarray,size,icheck)
       integer size,carray(0:size-1),sarray(0:(size+1)/2-1)
       integer stemp1,stemp2,exp1,exp2,mant1,mant2
       if (icheck.eq.1) goto 30
       do 20 i=0,(size+1)/2-1
          sign1=and(carray(2*i),x'8000000000000000')
          sign2=and(carray(2*i+1),x'8000000000000000')
          exp1=shiftr(and(carray(2*i),x'7fff000000000000'),48)-16258
          exp2=shiftr(and(carray(2*i+1),x'7fff000000000000'),48)-16258
          mant1=and(carray(2*i),x'00007fffff000000') +
     &    shiftl(and(carray(2*i),x'0000000000800000'),1)
          mant2=and(carray(2*i+1),x'00007fffff000000') +
     &    shiftl(and(carray(2*i+1),x'0000000000800000'),1)
          stemp1=or(or(sign1, shiftl(exp1,55)) , shiftl(mant1,8))
          stemp2=or(or(sign2, shiftl(exp2,55)) , shiftl(mant2,8))
          stemp1=cvmgn(stemp1,0,carray(2*i))
          stemp2=cvmgn(stemp2,0,carray(2*i+1))
          sarray(i)=or(stemp1,shiftr(stemp2,32))
20     continue
       return
30     continue
       do 10 i=0,(size+1)/2-1
          sign1=and(carray(2*i),x'8000000000000000')
          sign2=and(carray(2*i+1),x'8000000000000000')
          exp1=shiftr(and(carray(2*i),x'7fff000000000000'),48)-16258
          exp2=shiftr(and(carray(2*i+1),x'7fff000000000000'),48)-16258
          mant1=and(carray(2*i),x'00007fffff000000') +
     &    shiftl(and(carray(2*i),x'0000000000800000'),1)
          mant2=and(carray(2*i+1),x'00007fffff000000') +
     &    shiftl(and(carray(2*i+1),x'0000000000800000'),1)
          stemp1=or(or(sign1, shiftl(exp1,55)) , shiftl(mant1,8))
          stemp2=or(or(sign2, shiftl(exp2,55)) , shiftl(mant2,8))
          stemp1=cvmgm(or(sign1,x'7f80000000000000'),stemp1,254-exp1)
          stemp2=cvmgm(or(sign2,x'7f80000000000000'),stemp2,254-exp2)
          stemp1=cvmgn(stemp1,0,carray(2*i))
          stemp2=cvmgn(stemp2,0,carray(2*i+1))
          stemp1=cvmgm(0,stemp1,exp1-1)
          stemp2=cvmgm(0,stemp2,exp2-1)
          sarray(i)=or(stemp1,shiftr(stemp2,32))
10     continue
       end



