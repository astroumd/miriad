      program imwcs
      implicit none
c
c= IMWCS- Changes image header for new WCS parameters
c& pjt
c: image analysis
c+
c	IMWCS changes the image header variables related to the WCS
c       (crvalN,crpixN,cdeltN,ctypeN).
c
c       This program is a cheat, and currently assumes a purely linear
c       coordinate system, i.e. at pixel 'i'
c                    wcs_value = crval + (i-crpix)*cdelt
c
c       Only 1 axis at a time can be changed.
c
c       If multiple keywords are changed, the order in which they are
c       changed is: CRVAL, CRPIX, CDELT, CTYPE.
c       If only a single one is changed, the related one (CRVAL<->CRPIX)
c       will also be changed, unless auto is set to false.
c   
c       See also:  IMPOS, REGRID, IMFRAME
c@ in
c	The input image dataset. No default.
c@ axis
c       For which axis to change a WCS keyword. Any number between 1 and
c       the NAXIS value of an image. No default.
c@ crval
c       Axis reference value to change.
c@ crpix
c       Axis reference pixel to change.
c@ cdelt
c       Axis pixel increment to change.
c@ ctype
c       Axis name to change.
c@ auto
c       Boolean to signify if a single keyword is changed, the related
c       one should also be changed. E.g. changing crpix should also
c       crval in a consistent way.
c       Default: true
c@ center
c       Boolean, if set and crpix is not set, it will set the reference
c       pixel to the center of the axis, (N+1)/2.
c       Note that if auto=true and crval not given, a new crval will be
c       computed.
c       Default: false
c--
c
c  History:
c    pjt  13aug02  Original version
c-----------------------------------------------------------------------
      include 'maxdim.h'
      include 'maxnax.h'
c
      double precision crval,crpix,cdelt
      double precision orval,orpix,odelt
      integer axis, lun, naxis, nsize(maxnax)
      character file*80, krval*10,kdelt*10,krpix*10,ktype*10,ctype*30
      logical docrval,docdelt,docrpix,doctype,doauto,docenter
c
c  Externals.
c
      logical keyprsnt
c
c-----------------------------------------------------------------------
      call output ('IMWCS: version 13-Aug-02')
c
c  Get inputs
c
      call keyini
      call keyf ('in', file, ' ')
      if (file.eq.' ') call bug ('f', 'Input file must be given')

      call keyi('axis',axis,0)
      if (axis.eq.0) call bug('f','No default for axis=')
      docrval = keyprsnt('crval')
      docdelt = keyprsnt('cdelt')
      docrpix = keyprsnt('crpix')
      doctype = keyprsnt('ctype')
      if (docrval) call keyd('crval',crval,0.0)
      if (docrpix) call keyd('crpix',crpix,0.0)
      if (docdelt) call keyd('cdelt',cdelt,0.0)
      if (doctype) call keya('ctype',ctype,' ')
      call keyl('auto',doauto,.TRUE.)
      call keyl('center',docenter,.FALSE.)
      call keyfin

      write(krval,100) 'crval',axis
      write(krpix,100) 'crpix',axis
      write(kdelt,100) 'cdelt',axis
      write(ktype,100) 'ctype',axis

c
c  Open file
c
      call xyopen (lun, file, 'old', maxnax, nsize)
      call rdhdi(lun,'naxis',naxis,0)
      if (axis.gt.naxis) call bug('f','axis too large for this image')

      if (docenter .and. .not.docrpix) then
         docrpix = .TRUE.
         crpix = (nsize(axis)+1.0)/2.0
      endif

      if (docrval .and. docrpix) doauto=.FALSE.

      if (docrval) then
         call output('Changing crval')
         if (doauto) then
            call rdhdd(lun,krval,orval,0.0d0)
            call rdhdd(lun,krpix,orpix,0.0d0)
            call rdhdd(lun,kdelt,odelt,1.0d0)
            crpix = orpix + (crval-orval)/odelt
            call wrhdd(lun,krpix,crpix)
         endif
         call wrhdd(lun,krval,crval)
      endif


      if (docrpix) then
         call output('Changing crpix')
         if (doauto) then
            call rdhdd(lun,krval,orval,0.0d0)
            call rdhdd(lun,krpix,orpix,0.0d0)
            call rdhdd(lun,kdelt,odelt,1.0d0)
            crval = orval + (crpix-orpix)*odelt
            call wrhdd(lun,krval,crval)
         endif
         call wrhdd(lun,krpix,crpix)
      endif

      if (docdelt) then
         call output('Changing cdelt')
         call wrhdd(lun,kdelt,cdelt)
      endif

      if (doctype) then
         call output('Changing ctype')
         call wrhda(lun,ktype,ctype)
      endif

      call xyclose (lun)

 100  format(A,I1)

      end

































