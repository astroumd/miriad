c************************************************************************
	program maxdimp
c
c History:
c
c  pjt      2008  original version
c
c= maxdim - Report all known MAXDIM related parameters that limit memory use
c& pjt
c: utility
c+
c	MAXDIM reports a number of MAXDIM related parameters that Fortran
c       and C programs in Miriad use and could limit memory usage.
c       Sometimes an obscure message (e.g. Hash table overflow) actually
c       means the MAXBUF parameter needs to be increased.
c
c       This program currently has no keywords.
c------------------------------------------------------------------------
c
      include 'maxdim.h'
      include 'mem.h'
c
      CHARACTER version*80, versan*80
      INTEGER membuf,size

      EXTERNAL membuf

      version = versan('maxdim',
     * '$Id$')

c
c  Get the input parameters (well,there are none right now, but
c  MIRIAD still should use this for sanity reasons
c
      CALL keyini
      CALL keyfin

      CALL output('$MIR/VERSION:')
      CALL system('cat $MIR/VERSION')



c  There are some variables that are only present in maxdim.h (fortran)
c  and not in maxdimc.h (C): MAXWIDE
c  and some not in maxdim.h but in maxdimc.h:   MAXNAX

      CALL output('$MIRINC/maxdim.h parameter:')

      WRITE(*,*) 'MIRTEL       = ',MIRTEL
      WRITE(*,*) 'MAXBUF       = ',MAXBUF
      WRITE(*,*) 'MAXDIM       = ',MAXDIM
      WRITE(*,*) 'MAXDIM2      = ',MAXDIM2
      WRITE(*,*) 'MAXIANT      = ',MAXIANT
      WRITE(*,*) 'MAXANT       = ',MAXANT
      WRITE(*,*) 'MAXANT2      = ',MAXANT2
      WRITE(*,*) 'MAXBASE      = ',MAXBASE
      WRITE(*,*) 'MAXBASE2     = ',MAXBASE2
      WRITE(*,*) 'MAXCHAN      = ',MAXCHAN
      WRITE(*,*) 'MAXWIN       = ',MAXWIN
      WRITE(*,*) 'MAXWIDE      = ',MAXWIDE
c     WRITE(*,*) 'MAXNAX       = ',MAXNAX


      CALL output('static membuf (maxbuf) usage:')
      size = membuf()
      WRITE(*,*) 'membuf()     = ',size
      


      END
c******************************************************************c
