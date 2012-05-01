c     gjdw 09jun11 Replaced MAXDIM by MAXSIM in mafia.for and maxfld.h
c     pjt  may2012 Put smaller values for more generic machines,the default need big memory
      include 'maxdim.h'
      include 'maxnax.h'
      integer MAXFLD
c      parameter (MAXFLD=128*MAXDIM)
      parameter (MAXFLD=16384)
      INTEGER   MAXSIM
c      PARAMETER(MAXSIM=8192)
      PARAMETER(MAXSIM=256)
 
