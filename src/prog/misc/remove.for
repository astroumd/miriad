      PROGRAM remove
c-----------------------------------------------------------------------
c History:
c     16-mar-91   Recreated from scratch     		       Peter Teuben
c     18-mar-91   Added ishell kludge for Cray - and lib$spawn for VMS  PJT
c     21-mar-91   Separated command/rmdata as subs              	PJT
c      6-may-91   Renamed program name rmdata to remove because some
c		  cannot handle rmdata in prog and subs........		PJT
c-----------------------------------------------------------------------
c= remove - remove a MIRIAD dataset
c& pjt
c: Utility
c+
c  REMOVE is a MIRIAD task to delete datasets. It refuses to
c  delete datasets which do not look like MIRIAD datasets.
c  The subroutine ``rmdata'' does the actual work.
c@in
c  Comma separated list of datasets to be deleted. One can also
c  use a wildcard notation, such as ``in=*_old,junk1'' or
c  ``in=junk[1-5],*_bad'', whatever you local operating systems
c  supports.
c  Default: none
c-----------------------------------------------------------------------
c parameters:
      INTEGER    MAXFILES
      PARAMETER (MAXFILES=64)
      CHARACTER  VERSION*(*)
      PARAMETER (VERSION='Version 1.0 22-may-91')
c local variables:
      CHARACTER fname(MAXFILES)*132
      INTEGER   i, nfiles
c--
c Announce presence
      CALL output('REMOVE: '//VERSION)
c Get parameters from command lines
      CALL keyini
      CALL mkeyf('in',fname,MAXFILES,nfiles)
      CALL keyfin
c Check if no files given
      IF (nfiles.LE.0) THEN
         CALL bug('i','No MIRIAD datasets to delete; use in=')
c Else loop over all datasets
      ELSE
         DO i=1,nfiles
               CALL rmdata(fname(i))
	 ENDDO
      ENDIF
      END
