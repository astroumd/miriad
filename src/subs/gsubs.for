C	helper routines for gfiddle; these need to be in a separate
C	file because of a type change in the arguments due to a
C	switch of variable types which some strict ANSI fortran
C	compilers cannot (should really) handle. Most notably the g77
C	gnu compiler (default on linux now) cannot handle this.
C
      SUBROUTINE ClearVis(nslot,nwide,nbl,vis,flg,value)
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl
      INTEGER flg(nslot,nwide,nbl)
      COMPLEX vis(nslot,nwide,nbl), value
c
c  Resets all VIS and FLG values to unused.
c
c  legal flg values:
c        -1    unused slot
c         0    flagged as bad 
c         1    flagged as good
c-----------------------------------------------------------------------
      INTEGER i,j,k
c
      DO k=1,nbl
         DO j=1,nwide
            DO i=1,nslot
               vis(i,j,k) = value
               flg(i,j,k) = -1
            ENDDO
         ENDDO
      ENDDO
      RETURN
      END
c***********************************************************************
      SUBROUTINE SetVis(nslot,nwide,nbl,vis,flg,
     *                  i,j,k,data,flag)
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl, i,j,k
      INTEGER flg(nslot,nwide,nbl)
      COMPLEX vis(nslot,nwide,nbl), data
      LOGICAL flag
c
c  Set the flg and vis values of a particular item
c-----------------------------------------------------------------------
      vis(i,j,k) = data
      IF(flag) THEN
         flg(i,j,k) = 1
      ELSE
         flg(i,j,k) = 0
      ENDIF
      RETURN
      END
c***********************************************************************
      subroutine getvis(nslot,nwide,nbl,vis,flg,i,j,k,data,flag,mode)
      implicit none
      integer nslot,nwide,nbl, i,j,k,mode
      integer flg(nslot,nwide,nbl)
      complex vis(nslot,nwide,nbl), data
      logical flag
c
c  Get the flg and vis values of one particular item pointed to by
c  (i,j,k) from (nslot,nwide,nbl).  Also check to see if this vis data
c  was ever initialized.  The returned logical flag will be .TRUE. if
c  the data was initialized AND is valid (flagged good); otherwise, it
c  will be .FALSE. if the data was flagged bad OR was not initialized.
c  Mode is the controlling item here.  It determines which data value
c  is returned.  If mode is 0, 1, or 4, then the raw value is returned.
c  If mode is 2, then the ssb value is computed from the dsb data.  If
c  mode is 3, the dsb value is computed from the ssb data.
c-----------------------------------------------------------------------
      real rval, ival
      real phazlo, phazhi
      complex zlow, zhigh
c
      data = (0.0, 0.0)
      flag = .FALSE.
      if ((mode .eq. 0) .or. (mode .eq. 1) .or. (mode .eq. 4)) then
        data = vis(i,j,k)
        flag = (flg(i,j,k) .gt. 0)
      else if ((mode .eq. 2) .and. (nwide .ge. 2)) then
        zlow = vis(i,1,k)
        zhigh = vis(i,2,k)
c-??        flag = ((flg(i,1,k) .gt. 0) .and. (flg(i,2,k) .gt. 0))
        flag = ((flg(i,1,k) .ne. 0) .and. (flg(i,2,k) .ne. 0))
        if (j .eq. 1) then
          if (REAL(zlow) .gt. 0) then
            rval = REAL(zhigh) / sqrt(REAL(zlow))
          else
            rval = 0.0
          endif
          ival = AIMAG(zhigh) - (AIMAG(zlow) / 2.0)
        else if (j .eq. 2) then
          rval = REAL(zhigh) * sqrt(REAL(zlow))
          ival = AIMAG(zhigh) + (AIMAG(zlow) / 2.0)
        else
          call bug('w', 'GETVIS:  Index greater than nwide.')
          rval = 0.0
          ival = 0.0
          flag = .FALSE.
        endif
        data = CMPLX(rval, ival)
      else if ((mode .eq. 3) .and. (nwide .ge. 2)) then
        zlow = vis(i,1,k)
        zhigh = vis(i,2,k)
        phazlo = AIMAG(zlow)
        phazhi = AIMAG(zhigh)
c-??        flag = ((flg(i,1,k) .gt. 0) .and. (flg(i,2,k) .gt. 0))
        flag = ((flg(i,1,k) .ne. 0) .and. (flg(i,2,k) .ne. 0))
        if (j .eq. 1) then
          if (REAL(zlow) .ne. 0) then
            rval = REAL(zhigh) / REAL(zlow)
          else
            rval = 0.0
          endif
          ival = phazhi - phazlo
        else if (j .eq. 2) then
          rval = sqrt(REAL(zhigh) * REAL(zlow))
          do while ((phazhi - phazlo) .gt. 180.0)
            phazlo = phazlo + 360.0
          enddo
          do while ((phazhi - phazlo) .lt. -180.0)
            phazlo = phazlo - 360.0
          enddo
          ival = 0.5 * (phazhi + phazlo)
        else
          call bug('w', 'GETVIS:  Index greater than nwide.')
          rval = 0.0
          ival = 0.0
          flag = .FALSE.
        endif
        data = CMPLX(rval, ival)
      else
        call bug('w', 'GETVIS:  Invalid sideband mode.')
      endif
      return
      end
c***********************************************************************
      SUBROUTINE C2PVis(nslot,nwide,nbl,vis,flg)
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl
      INTEGER flg(nslot,nwide,nbl) 
      REAL    vis(2,nslot,nwide,nbl)
c
c  Cartesian (really Complex) to Polar conversion of all data.
c  Angles will be in degrees (see routine amphase).
c-----------------------------------------------------------------------
      INTEGER i,j,k
      REAL amp, phase
c
      DO k=1,nbl
         DO j=1,nwide
            DO i=1,nslot
               IF(flg(i,j,k).GE.0)THEN
                  CALL amphase(vis(1,i,j,k), amp, phase)
                  vis(1,i,j,k) = amp
                  vis(2,i,j,k) = phase
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      RETURN
      END     
c***********************************************************************
      SUBROUTINE ClipVis(nslot,nwide,nbl,vis,flg,clip,cnt,sbmode)
      IMPLICIT NONE
      INTEGER nslot,nwide,nbl,cnt,sbmode
      INTEGER flg(nslot,nwide,nbl) 
      REAL    vis(2,nslot,nwide,nbl), clip
c
c  Clip the amplitudes (the vis(1,...) values) whenever valid and
c  larger than a clip value.
c-----------------------------------------------------------------------
      CHARACTER msg*100
      INTEGER i,j,k
      integer mode
      complex data
      logical flag
c
      IF (clip.LE.0.0) RETURN
c
c  Convert any dsb data to ssb to test amplitude values.
c
      mode = sbmode
      if (mode .gt. 2) mode = mode - 2
      cnt = 0
      DO k=1,nbl
         DO j=1,nwide
            DO i=1,nslot
c-old               IF(flg(i,j,k).GE.0 .AND. vis(1,i,j,k).GT.clip)THEN
               call getvis(nslot,nwide,nbl,vis,flg,i,j,k,data,flag,mode)
               if (flag .and. (real(data) .gt. clip)) then
                  flg(i,j,k) = 0
                  cnt = cnt + 1
               ENDIF
            ENDDO
         ENDDO
      ENDDO
c
      IF(cnt.GT.0) THEN
         WRITE(msg,'(I5,A,F7.3)') cnt,' values clipped with clip=',clip
         CALL output(msg)
      ENDIF
      RETURN
      END     
