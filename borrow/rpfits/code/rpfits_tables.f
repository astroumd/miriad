      subroutine RPFITS_READ_TABLE(lun, m, ii, endhdr)
 
C     routine to read any  FITS tables right up to
C     the end of the header
C     On entry:
C                lun is the lun of the RPFITS file
C                m is the array of card images
C                ii is the current line in the array m, or is set to -1
C                    if only the flag table (at the end of the data) is
C                    to be read
C                endhdr will be set to true if the end of header is 
C                    encountered
C     RPN 29/9/88
C     HM  11/5/90  Made mods necessary for compilation on SUNs
C     HM  29/1/91  Reduced lines to 72 chars
C     HM  15/5/92  Allow for up to source number up to 999 in IF, FG, SU
C                  and CU tables. Also increased are if_simul in IF 
C                  table and entry number in flag table.
C     HM  26/8/92  Fix bug. Set i=1 not 0 after write.
C     HM  23/6/93  Eliminate unused variables.
C     HM  11/3/94  Changed format of MT table (i4 to i5)
C-----------------------------------------------------------------------
      logical   endhdr, fg_only
      integer   lun, i, ii, status, AT_READ, ichr(640), j
      character m(32)*80
 
      include 'rpfits.inc'
 
      i = ABS(ii)
      fg_only = (ii.eq.-1)
      do while (.not. endhdr)
 
         if (ncard.lt.0) then
            card(-ncard) = m(i)
            ncard = ncard - 1
         end if
 
         if (m(i)(1:8).eq.'TABLE IF') then
            call READIF (lun, m, i)
         else if (m(i)(1:8).eq.'TABLE SU') then
            call READSU (lun, m, i)
         else if (m(i)(1:8).eq.'TABLE FG') then
            call READFG (lun, m, i)
         else if (m(i)(1:8).eq.'TABLE AN') then
            call READAN (lun, m, i)
         else if (m(i)(1:8).eq.'TABLE MT') then
            call READMT (lun, m, i)
         else if (m(i)(1:8).eq.'TABLE CU') then
            call READCU (lun, m, i)
         else if (m(i)(1:8).eq.'END     ') then
            endhdr = .true.
            return
         end if
 
         if (fg_only) then
            endhdr = .false.
            return
         end if
 
         i = i + 1
         if (i.gt.32) then
            status = AT_READ (lun, ichr)
            write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
            i = 1
         end if
      end do
 
      return
      end
 
 
 
 
 
 
      subroutine READIF (lun, m, i)
 
C     routine to read an IF table from an RPFITS file 
C
C     RPN 29/9/88
C     Modified 14/Dec/91 HM  Added if_simul and if_chain. Old data 
C     without them is given if_simul=if_chain=1 in the IF table.
C     Modified 14/May/92 HM  Allow for i3 if_num or if_simul.
C-----------------------------------------------------------------------
      integer   lun, i, j, k, l, status, AT_READ, ichr(640)
      character m(32)*80, temp*5
 
      include 'rpfits.inc'

      n_if = 0
      do while (.true.)
         do j = i + 1,32
            if (ncard.lt.0) then
               card(-ncard) = m(j)
               ncard = ncard - 1
            end if
 
            if (m(j)(1:8).eq.'ENDTABLE') then
               i = j
               goto 999
            else if (m(j)(1:8).eq.'HEADER') then
            else if (m(j)(1:8).eq.'COMMENT') then
            else
               k = n_if + 1
               read(m(j),'(BN,i3,f16.3,1x,i2, 1x, f16.3, 1x, i4,
     +            1x, i2, 1x, 4a2, 1x,i1, 1x,f6.1, 1x, a5)')
     +            if_num(k), if_freq(k), if_invert(k),
     +            if_bw(k), if_nfreq(k), if_nstok(k), 
     +            (if_cstok(l,k),l = 1,4), if_sampl(k), 
     +            if_ref(k), temp
               if (temp .eq. ' ') then
                  if_simul(k) = 1
                  if_chain(k) = 1
               else
                  read (temp,*) if_simul(k), if_chain(k)
                  if (if_simul(k) .eq. 0) if_simul(k) = 1
                  if (if_chain(k) .eq. 0) if_chain(k) = 1
               end if
               n_if = n_if + 1
            end if
         end do
 
         status = AT_READ (lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  999 if_found = .true.
      return
      end
 
 
 
 
 
      subroutine WRITE_IF_TABLE (i, m)
 
C     routine to write an IF table to an RPFITS file 
C
C     RPN 29/9/88
C     Modified 14/Dec/91 HM  Added if_simul and if_chain. Note that it 
C                            are read with BZ to interpret the blanks in
C                            old data as zero.
C     Modified 14/May/92 HM  Write if_num as i3.
C-----------------------------------------------------------------------
      integer   i, k, l
      character m(*)*80, header*80
      include 'rpfits.inc'
 
      header =
     +   'HEADER     FREQ    INVERT   BW         '//
     +   'NCHAN NSTOK TYPE SAM REF SIM CHAIN'
      i = i+1
      write (m(i),'(a)')  'TABLE IF'
      i = i+1
      write (m(i),'(a)')  header
 
      do k = 1, n_if
         i = i+1
         write (m(i),'(i3,f16.3,1x,i2, 1x, f16.3, 1x, i4, 1x, 
     +      i2 , 1x, 4a2,1x,i1, 1x, f6.1, 1x, i2, 1x, i2)')
     +      if_num(k), if_freq(k), if_invert(k),
     +      if_bw(k), if_nfreq(k), if_nstok(k),
     +      (if_cstok(l,k),l=1,4), if_sampl(k), 
     +      if_ref(k), if_simul(k), if_chain(k)
      end do
 
      i = i+1
      write (m(i),'(a)')  'ENDTABLE'
 
      return
      end
 
 
 
 
 
      subroutine READSU(lun, m, i)
 
C     routine to read a SOURCE table from an RPFITS file 
C
C     RPN 8/11/88
C     HM  15/5/92 Read old (i2) or new (i3) source number.
C-----------------------------------------------------------------------
      integer   lun, i, j, k, status, AT_READ, ichr(640)
      character m(32)*80
      include 'rpfits.inc'

      n_su = 0
      do while (.true.)
         do j = i + 1,32
            if (ncard.lt.0) then
               card(-ncard) = m(j)
               ncard = ncard-1
            end if
 
            if (m(j)(1:8).eq.'ENDTABLE') then
               i = j
               goto 999
            else if (m(j)(1:8).eq.'HEADER') then
            else if (m(j)(1:8).eq.'COMMENT') then
            else
               k = n_su+1
               read(m(j),'(BN,i3,a16,1x,f12.9, 1x, f12.9, 1x, a4, 
     +            1x, f11.9, 1x, f11.9)')
     +            su_num(k), su_name(k), su_ra(k), su_dec(k), 
     +            su_cal(k), su_rad(k), su_decd(k)
               n_su = n_su+1
            end if
         end do
 
         status = AT_READ (lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  999 su_found = .true.
      return
      end
 
 
 
 
 
      subroutine WRITE_SU_TABLE (i, m)
 
C     routine to write a SOURCE table to an RPFITS file 
C
C     RPN 8/11/88
C     HM 15/05/92 Modified to write su_num as i3.
C-----------------------------------------------------------------------
      integer i, k
      character m(*)*80, header*80
      include 'rpfits.inc'
      data header(1:40)/
     +   'HEADER  NAME            RA2000   DEC2000'/
      data header(41:80)/
     +   '  CALCODE  RA_DATE    DEC_DATE          '/
 
      i = i+1
      write (m(i),'(a)')  'TABLE SU'
      i = i+1
      write (m(i),'(a)')  header
 
      do k = 1, n_su
         i = i+1
         write (m(i),'(i3,a16,1x,f12.9, 1x, f12.9, 1x, a4,
     +      1x, f11.9, 1x, f11.9)')
     +      su_num(k), su_name(k), su_ra(k), su_dec(k), su_cal(k),
     +      su_rad(k), su_decd(k)
      end do
 
      i = i+1
      write (m(i),'(a)')  'ENDTABLE'
 
      return
      end
 
 
 
 
 
      subroutine READFG (lun, m, i)
 
C     routine to read a FLAG table from an RPFITS file 
C
C     RPN 8/11/88
C     Modified 15/5/92 HM Read old (i2) and new (i3) j and fg_if 
C-----------------------------------------------------------------------
      integer lun, i, j, k, status, AT_READ, ichr(640)
      character m(32)*80
      include 'rpfits.inc'
 
      n_fg = 0
      do while (.true.)
         do k = i + 1,32
            if (ncard.lt.0) then
               card(-ncard) = m(k)
               ncard = ncard - 1
            end if
            if (m(k)(1:8).eq.'ENDTABLE') then
               i = k
               goto 999
            else if ( m(k)(1:8).eq.'HEADER' ) then
            else if ( m(k)(1:8).eq.'COMMENT') then
            else
               read(m(k),'(BN, i3, i2, 1x, i2, 2(1x,f8.1), 1x, 2(i3),
     +            i4, 1x, i4, 2(1x,i1), a24)') j,
     +            fg_ant(1,j), fg_ant(2,j), fg_ut(1,j), fg_ut(2,j),
     +            fg_if(1,j), fg_if(2,j), fg_chan(1,j), fg_chan(2,j),
     +            fg_stok(1,j), fg_stok(2,j), fg_reason
               n_fg = n_fg+1
            end if
         end do
 
         status = AT_READ (lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  999 fg_found = .true.
      return
      end
 
 
 
 
 
      subroutine WRITE_FG_TABLE (i, m)
 
C     routine to write a FLAG table to an RPFITS file 
C
C     RPN 8/11/88
C     Modified 15/5/92 HM Write j and fg_if as i3.
C-----------------------------------------------------------------------
      integer i, j
      character m(*)*80, header*80
      include 'rpfits.inc'
      header =
     +   'HEADER  ANT   UT    IF     CHAN     STOK       REASON'
      i = i + 1
      write (m(i),'(a)')  'TABLE FG'
      i = i + 1
      write (m(i),'(a)')  header
 
      do j = 1, n_fg
         i = i + 1
         write (m(i),'(i3, i2, 1x, i2, 2(1x,f8.1), 1x, i3, i3, 
     +      i4, 1x, i4, 2(1x,i1), a24)') j,
     +      fg_ant(1,j), fg_ant(2,j), fg_ut(1,j), fg_ut(2,j),
     +      fg_if(1,j), fg_if(2,j), fg_chan(1,j), fg_chan(2,j),
     +      fg_stok(1,j), fg_stok(2,j), fg_reason(j)
      end do
 
      i = i + 1
      write (m(i),'(a)')  'ENDTABLE'
 
      return
      end
 
 
 
 
 
      subroutine READAN (lun, m, i)
 
C     routine to read an AN table from an RPFITS file 
C
C     RPN 27/7/89
C     mod rpn 11/10/89 remove met info
C     H.May 26/8/92  Change read to match write in write_an_table
C-----------------------------------------------------------------------
      integer lun, i, j, status, AT_READ, iaxis_offset,
     +   ichr(640)
      character m(32)*80
      include 'rpfits.inc'
      nant = 0
 
      do while (.true.)
         do j = i + 1, 32
            if (ncard.lt.0) then
               card(-ncard) = m(j)
               ncard = ncard - 1
            end if
            if (m(j)(1:8).eq.'ENDTABLE') then
               i = j
               goto 999
            else if (m(j)(1:8).eq.'HEADER' ) then
            else if (m(j)(1:8).eq.'COMMENT') then
            else
               nant = nant + 1
               read(m(j),100) ant_num(nant), sta(nant), 
     +            ant_mount(nant), x(nant), y(nant), z(nant), 
     +            Iaxis_offset
               axis_offset(nant) = iaxis_offset/1000.0
            end if
         end do
 
         status = AT_READ (lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  100 format (i2,1x,a8,1x,i1,3(1x,f13.3),1x,i4)
  999 an_found = .true.
 
      return
      end
 
 
 
 
 
      subroutine WRITE_AN_TABLE (i, m)
 
C     routine to write an AN table to an RPFITS file 
C
C     RPN 29/9/88
C     mod rpn 11/10/89 remove met info
C-----------------------------------------------------------------------
      integer   i, k, iaxis_offset
      character m(*)*80, header*80
      include 'rpfits.inc'
      header = 'HEADER      M       X             Y             '//
     +   'Z       AXIS'
      i = i + 1
      write (m(i),'(a)')  'TABLE AN'
      i = i + 1
      write (m(i),'(a)')  header
 
      do k = 1, nant
         i = i + 1
         iaxis_offset  =  nint(axis_offset(k)*1000.0)
         write (m(i),100) ant_num(k), sta(k), ant_mount(k), 
     +      x(k), y(k), z(k), iaxis_offset
      end do
 
      i = i + 1
      write (m(i),'(a)')  'ENDTABLE'
  100 format (i2,1x,a8,1x,i1,3(1x,f13.3),1x,i4)
 
      return
      end
 
 
 
 
 
      subroutine READMT (lun, m, i)
 
C     routine to read a MT table from an RPFITS file 
C
C     RPN 11/10/89
C-----------------------------------------------------------------------
      integer   lun, i, j, status, AT_READ, ichr(640)
      character m(32)*80
      include 'rpfits.inc'
 
      n_mt = 0
      do while (.true.)
         do j = i+1, 32
            if (ncard.lt.0) then
               card(-ncard) = m(j)
               ncard = ncard - 1
            end if
 
            if (m(j)(1:8).eq.'ENDTABLE') then
               i = j
               goto 999
            else if (m(j)(1:8).eq.'HEADER' ) then
            else if (m(j)(1:8).eq.'COMMENT') then
            else
               n_mt = n_mt + 1
               read(m(j),100) mt_ant(n_mt), mt_ut(n_mt),
     +            mt_press(n_mt), mt_temp(n_mt), mt_humid(n_mt)
            end if
         end do
 
         status = AT_READ (lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  100 format (i2,1x, f8.1, 1x,f6.1, 2(1x,f5.1))
  999 mt_found = .true.
 
      return
      end
 
 
 
 
 
      subroutine WRITE_MT_TABLE (i, m)
 
C     routine to write an MT table to an RPFITS file 
C
C     RPN 11/10/89
C-----------------------------------------------------------------------
      integer i, k
      character m(*)*80, header*80
      include 'rpfits.inc'
 
      header = 'HEADER UT PRESS  TEMP  HUMID'
      i = i + 1
      write (m(i),'(a)')  'TABLE MT'
      i = i + 1
      write (m(i),'(a)')  header
 
      do k = 1, n_mt
         i = i + 1
         write (m(i),100) mt_ant(k), mt_ut(k), 
     +      mt_press(k), mt_temp(k), mt_humid(k)
      end do
 
      i = i + 1
      write (m(i),'(a)')  'ENDTABLE'
  100 format (i2,1x, f8.1, 1x,f6.1, 2(1x,f5.1))
 
      return
      end
 
 
 
 
 
      subroutine READCU (lun, m, i)
 
C     routine to read a CU table from an RPFITS file 
C
C     RPN 22/03/90
C     Modified: HM  15/05/92  Read old (i2) or new (i3) cu_if.
C-----------------------------------------------------------------------
      integer lun, i, j, status, AT_READ, ichr(640)
      character m(32)*80
      include 'rpfits.inc'
 
      n_cu = 0
      do while (.true.)
         do j = i + 1,32
            if (ncard.lt.0) then
               card(-ncard) = m(j)
               ncard = ncard - 1
            end if
 
            if (m(j)(1:8).eq.'ENDTABLE') then
               i = j
               goto 999
            else if (m(j)(1:8).eq.'HEADER' ) then
            else if (m(j)(1:8).eq.'COMMENT') then
            else
               n_cu = n_cu + 1
               read(m(j),100) cu_ut(n_cu), cu_ant(n_cu), cu_if(n_cu),
     +            cu_cal1(n_cu), cu_cal2(n_cu), cu_ch1(n_cu), 
     +            cu_ch2(n_cu)
            end if
         end do
 
         status = AT_READ(lun, ichr)
         write (m, '(32(20a4,:,/))') (ichr(j),j=1,640)
         i = 0
      end do
 
  100 format (BN, f8.1,1x,i2,1x,i3,f6.1,1x,f6.1,2(1x,i4))
  999 cu_found = .true.
 
      return
      end
 
 
 
 
 
      subroutine WRITE_CU_TABLE (i, m)
 
C     routine to write a CU table to an RPFITS file 
C
C     RPN 11/10/89
C     Modified HM 15/05/92 Write cu_if as i3.
C-----------------------------------------------------------------------
      integer i, k
      character m(*)*80, header*80
      include 'rpfits.inc'
 
      header = 'HEADER  ANT IF CALSTART  CALSTOP   CH1  CH2'
      i = i + 1
      write (m(i),'(a)')  'TABLE CU'
      i = i + 1
      write (m(i),'(a)')  header
 
      do k = 1, n_cu
         i = i + 1
         write  (m(i),100) cu_ut(n_cu), cu_ant(n_cu), cu_if(n_cu),
     +      cu_cal1(n_cu), cu_cal2(n_cu), cu_ch1(n_cu), cu_ch2(n_cu)
      end do
 
      i = i + 1
      write (m(i),'(a)')  'ENDTABLE'
  100 format (f8.1,1x,i2,1x,i3,f6.1,1x,f6.1,2(1x,i4))
 
      return
      end
