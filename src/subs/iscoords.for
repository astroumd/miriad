c* iscoords - test if input string can represent coordinates and convert it
c: coordinates
c& bpw
c+
      logical function iscoords ( mode, coords, c1, c2 )

      character*(*)    mode
      character*(*)    coords
      real             c1, c2

c This checks if the input string can represent coordinates. For mode='ra', the
c input must look like right ascension and declination, for mode='lb', it must
c be longitude and latitude. If this is not so, the return value for iscoords
c is set to false.
c Every possible check is made to ensure that the input could be right ascension
c and declination or longitude/latitude, e.g. whether hours are between 0 and
c 24, minutes and seconds between 0 and 59, etc.
c
c Input:
c   mode:      determines whether input must represent right ascension and
c              declination (mode='ra') or longitude and latitude (mode='lb').
c   coords:    a string that could represent coordinates.
c
c Output:
c   c1, c2:    specified coordinates in radians
c--
c
c History:
c   bpw   11sep90  created
c   rjs   22feb91  Changed GetLun to LunGet to avoid a naming conflict.
c   bpw   24feb91  changed references of atoi,etc to atoif,etc.
c   pjt    5jan95  statement order for f2c (linux)
c   rjs   10jan96  Refix statement order for linux!!
c-----------------------------------------------------------------------


c- test if string text can represent ra/dec or l/b
c- and then convert data to those coordinates

      integer          nnum
      logical          ok
      integer          nelc
      character*1      chm1, ch
      logical          err(13)
      integer          nitem
      integer          i, j
      logical          isdigitf
      real             a(6)
      real             pi
      integer          lun_kld
      save             lun_kld
      data             lun_kld / 0 /

      if( mode(1:2).eq.'ra' ) nnum = 6
      if( mode(1:2).eq.'lb' ) nnum = 2

      if( lun_kld.eq.0 ) then
        call lunget( lun_kld )
        open ( unit=lun_kld, status='scratch' )
      endif

      do i = 1, 13
        err(i) = .false.
      enddo

      nitem = 0
      do i = 1, nelc(coords)
        if( i.eq.1 ) chm1 = ' '
        if( i.ne.1 ) chm1 = coords(i-1:i-1)
        ch = coords(i:i)
        err(1) = err(1).or.(.not.isdigitf(ch).and.index(' .-',ch).eq.0)
        if( chm1.eq.' '  .and.  ch.ne.' ' ) then
          nitem  = nitem + 1
          j      = i
          if( nnum.eq.6 )
     *    err(2) = err(2)  .or.  (  ch.eq.'-' .and. nitem.ne.4  )
          if( nnum.eq.2 )
     *    err(2) = err(2)  .or.  (  ch.eq.'-' .and. nitem.ne.2  )
        endif
        if( chm1.ne.' '  .and.  ch.eq.' '  .and.  nnum.eq.6 ) then
          if( ( nitem.eq.1 .or. nitem.eq.2 .or. nitem.eq.5 ) .and.
     *          i-j.ge.3 ) err(3) = .true.
          if( ( nitem.eq.4 ) .and. i-j.ge.4 ) err(3) = .true.
        endif
      enddo
      err(4) = nitem .ne. nnum
      if( .not. ( err(1).or.err(2).or.err(3).or.err(4) ) ) then
        rewind  lun_kld
        write ( lun_kld, '( '' '', a )' ) coords
        rewind  lun_kld
        read  ( lun_kld, *, err=201 ) ( a(i), i=1,nitem )
        goto 202
  201   err(13) = .true.
  202   continue
        if( mode(1:2).eq.'ra' ) then
          err( 5) = a(1).gt.24.
          err( 6) = a(2).gt.60.
          err( 7) = a(3).gt.60.
          err( 8) = abs(a(4)).gt.90.
          err( 9) = a(5).gt.60.
          err(10) = a(6).gt.60.
          err(11) = .false.
          err(12) = .false.
        elseif( mode(1:2).eq.'lb' ) then
          err( 5) = .false.
          err( 6) = .false.
          err( 7) = .false.
          err( 8) = .false.
          err( 9) = .false.
          err(10) = .false.
          err(11) = a(1).lt.0. .or. a(1).gt.360.
          err(12) = abs(a(2)).gt.90.
        endif
      endif

      if( err( 1) )call bug('e','Illegal character given')
      if( err( 2) )call bug('e','Only declination can be <0')
      if( err( 3) )call bug('e','Too many digits')
      if( err( 4) )call bug('e','Wrong number of values')
      if( err( 5) )call bug('e','Hours must be less than 24')
      if( err( 6) )call bug('e','Minutes must be less than 60')
      if( err( 7) )call bug('e','Seconds must be less than 60')
      if( err( 8) )call bug('e','Degrees must be between +/- 90')
      if( err( 9) )call bug('e','Arcminutes must be less than 60')
      if( err(10) )call bug('e','Arcseconds must be less than 60')
      if( err(11) )call bug('e','Longitude must in range 0 360')
      if( err(12) )call bug('e','Latitude must be in range -90 90')
      if( err(13) )call bug('e','Error decoding numeric input')

      ok = .true.
      do i = 1, 13
        ok = ok .and. .not.err(i)
      enddo

      if( ok ) then
c-      transform input to radians
c-      the complicated way of finding the sign of dec is caused
c-      by ambiguities between +0 and -0 when a(4)=0
        pi = acos( -1. )
        if( nnum.eq.6 ) then
           c1 = (     a(1)  + a(2)/60. + a(3)/3600. ) * pi/12.
           c2 = -isign  ( 1, ( index(coords,'-') - 1 ) ) *
     *          ( abs(a(4)) + a(5)/60. + a(6)/3600. ) * pi/180.
        else
           c1 = a(1) * pi/180.
           c2 = a(2) * pi/180.
        endif
      endif

      iscoords = ok
      return
      end
