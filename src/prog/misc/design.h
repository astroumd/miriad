c=======================================================================
      INCLUDE 'maxdim.h'
      INTEGER MAXPAD
      PARAMETER (MAXPAD=100)

      INTEGER nant, npad, idx(MAXPAD)
      REAL xant(MAXPAD), yant(MAXPAD)
      REAL xpad(MAXPAD), ypad(MAXPAD)
      CHARACTER id(MAXPAD)*4
      LOGICAL used(MAXPAD)

      COMMON /dloc/nant, npad, xant, yant, xpad, ypad, used
      COMMON /cloc/id

c=======================================================================
