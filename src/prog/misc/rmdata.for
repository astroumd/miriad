      PROGRAM myrmdata
c-----------------------------------------------------------------------
c History:
c     16-mar-91   Recreated from scratch     Peter Teuben
c     18-mar-91   Added ishell kludge for Cray - and lib$spawn for VMS       PJT
c     15-mar-95   program name cannot be same as a subroutine (linux)   pjt
c-----------------------------------------------------------------------
c= rmdata - delete a dataset
c& pjt
c: Utility
c+
c  RMDATA is a MIRIAD task to delete datasets. It refuses to
c  delete datasets which do not look like MIRIAD datasets.
c@in
c  Comma separated list of datasets to be deleted. One can also
c  include the wildcard notation, such as ``in=*_old,junk1'' or
c  ``in=junk[1-5],*_bad'', whatever you local operating systems
c  supports.
c  Default: none
c-----------------------------------------------------------------------
c parameters:
      INTEGER    MAXFILES
      PARAMETER (MAXFILES=64)
      CHARACTER  VERSION*(*)
      PARAMETER (VERSION='Version 1.0 15-mar-95')
c local variables:
      CHARACTER fname(MAXFILES)*132
      INTEGER   tno, iostat, i, nfiles
c externals:
      INTEGER   len1
c--
c Announce presence
      CALL output('RMDATA: '//VERSION)
c Get parameters from command lines
      CALL keyini
      CALL mkeyf('in',fname,MAXFILES,nfiles)
      CALL keyfin
c Check if no files given
      IF (nfiles.LE.0) THEN
         CALL bug('w','No MIRIAD datasets to delete; use in=')
c Else loop over all datasets, check if they can be opened as miriad
c dataset, and if OK, delete them
      ELSE
         DO i=1,nfiles
            CALL hopen(tno,fname(i),'old',iostat)
            IF (iostat.EQ.0) THEN
               CALL hclose(tno)
               CALL deldat(fname(i))
            ELSE
               CALL bugno('i',iostat)
               CALL bug('w','Dataset '// fname(i)(1:len1(fname(i))) //
     *                      ' could not be deleted - not miriad?')
            ENDIF
         ENDDO
      ENDIF
      END
c-----------------------------------------------------------------------
c* deldat
c& pjt
c: utilities
c+
      SUBROUTINE deldat(fname)
      CHARACTER fname*(*)
c
c  Delete a Miriad dataset:
c  For UNIX:      /bin/rm -rf dataset
c  For VMS:       rmdir dataset 
c		  (assuming this BKY command has been installed)
c  Formally 'rmdir' is the wrong approach, since for official
c  VMS one has to first change write permission on the directory,
c  and then delete all files like "DEL [.file...]*.*;*"
c  Someday someone will fix this...
c
c--
      CHARACTER*128 cmd
      INTEGER       len1

#ifdef vms
      cmd = 'rmdir '//fname(1:len1(fname))
#else
      cmd = '/bin/rm -rf '//fname(1:len1(fname))
#endif
      CALL output(cmd)
      CALL shell(cmd)
      END
c-----------------------------------------------------------------------
c* shell - issue a shell command
c& pjt
c: utilities
c+
      SUBROUTINE shell(cmd)
c
      CHARACTER cmd*(*)
c
c SHELL issues a shell command, as supplied by the input
c character string 'cmd'
c
c Input:
c     cmd       character string of the shell command to be performed
c               (probably the shell pointed to by the SHELL environment)
c
c The following implemention dependant operating system routines are called:
c
c UNICOS(cft):     CALL ``ishell(cmd)''
c VMS              CALL ``lib$spawn(cmd)''
c All other:       CALL ``system(cmd)''
c
c--
#ifdef cft
      CALL ishell(cmd)
#else
#ifdef vms
      CALL lib$spawn(cmd)
#else
      CALL system(cmd)
#endif
#endif
      END
