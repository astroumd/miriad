      SUBROUTINE DATFIT (OLDDAT, NEWDAT, IERR)
*-----------------------------------------------------------------------
* DATFIT converts a date from the old form, DD/MM/YY, to the new form
* YYYY-MM-DD.  Returns the current UTC date if the input date is blank.
*
*   Given:
*      OLDDAT   C**      Date in DD/MM/YY format.  If blank the current
*                        UTC date is supplied.
*
*   Returned:
*      NEWDAT   C*12     Date in YYYY-MM-DD form.
*
*      IERR     I        Error status:
*                           0: Success.
*                           1: Illegal OLDDAT.
*-----------------------------------------------------------------------
      INTEGER   IMON, IDAY, IYEAR, IERR
      INTEGER*4 TIME, TARRAY(9)
      CHARACTER INDATE*8, NEWDAT*12, OLDDAT*(*)

      EQUIVALENCE (IDAY,  TARRAY(4))
      EQUIVALENCE (IMON,  TARRAY(5))
      EQUIVALENCE (IYEAR, TARRAY(6))
*-----------------------------------------------------------------------
      IF (LEN(OLDDAT).GE.8 .AND. OLDDAT.NE.' ') THEN
*        Rescue bad dates written at Mopra in 2000.
         INDATE = OLDDAT
         IF (INDATE(7:8).EQ.'**') INDATE(7:8) = '00'

         READ (INDATE, '(I2,1X,I2,1X,I2)', IOSTAT=IERR) IDAY, IMON,
     :      IYEAR
         IF (IERR.NE.0) THEN
*           Bad date string.
            IERR = 1
            RETURN
         END IF

         IF (IMON.LT.1 .OR. IMON.GT.12 .OR.
     :       IDAY.LT.1 .OR. IDAY.GT.31) THEN
*           Invalid date fields.
            IERR = 1
            RETURN
         END IF

*        Years written at Mopra past 1999.
         IF (IYEAR.LT.70) IYEAR = IYEAR + 100

      ELSE
*        Get the current UTC date.
         CALL GMTIME(TIME(), TARRAY)
      END IF

      IYEAR = 1900 + IYEAR

      WRITE (NEWDAT, '(I4.4,2(A,I2.2))') IYEAR, '-', IMON, '-', IDAY

      RETURN
      END
