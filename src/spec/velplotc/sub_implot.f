        subroutine annot_implot(tno,in,tmax,tmin,conlevs,numlevs,
     *          range,sclo,schi,sdlo,sdhi)
        character*(*) in
        integer tno,numlevs
        real tmax,tmin,conlevs(50),range(2),sclo,schi,sdlo,sdhi
c
c  Annotate the map information to the right side of
c  the page for ImPlot.
c
c  Inputs:
c    tno	The input image.
c    in 	The input filename.
c    tmax,tmin	Maximum and minimum of region of interest.
c    conlevs	The array of contour levels.
c    numlevs	Number of conlevs.
c    range	Grey level range.
c    sclo,schi,sdlo,sdhi  PGPLOT view port limits.
c--
c  History:
c    may89  wh    Original version.
c    23jun90  mchw  Rewritten to accomodate transposed images.
c    04apr91  mchw  Update annotation for larger file and max/min.
c    17apr91  mchw  Fixed annotate for cray. Set maxnax=4.
c    01nov91 mchw  Added grey scale range.
c---------------------------------------------------------------c
        integer maxnax
        parameter(maxnax=4)
        double precision PI,RTS
        parameter(PI=3.141592654,RTS=180.d0*3600.d0/PI)
        character*10 bunit,ctype(maxnax),ans
        character object*20,text*40,axis*1,crlabel(maxnax)*13,msg*80
        double precision crval(maxnax),cdelt(maxnax)
        real restfreq,bmaj,bmin,bpa,pbfwhm
        integer naxis,nsize(maxnax),la
        integer i,mid,last
        logical once
c
c  Externals.
c
        character itoaf*1
        character hangleh*13, rangleh*13
        integer len1
	real ax,bx,ay,by
c
c  Data
c
        data once /.true./
c
c  Read header items from image.
c
c        if (once) then
          once=.false.
          call rdhda(tno,'object',object,'________')
          call rdhda(tno,'bunit',bunit,'________')
          call rdhdr(tno,'restfreq',restfreq,0.)
          call rdhdi(tno,'naxis',naxis,1)
          call rdhdr(tno,'bmaj',bmaj,0.)
          call rdhdr(tno,'bmin',bmin,0.)
          call rdhdr(tno,'bpa',bpa,0.)
          call rdhdr(tno,'pbfwhm',pbfwhm,-1.)
          do 90000 i=1,naxis
            axis = itoaf(i)
            call rdhda(tno,'ctype'//axis,ctype(i),'________')
            call rdhdd(tno,'crval'//axis,crval(i),0.)
            call rdhdd(tno,'cdelt'//axis,cdelt(i),0.)
            call rdhdi(tno,'naxis'//axis,nsize(i),1)
            if(ctype(i).eq.'RA---SIN')then
c	      crlabel(i) = hangleh(dble(crval(i)))
              crlabel(i) = hangleh(crval(i))
              cdelt(i) = cdelt(i)*rts
            else if(ctype(i).eq.'DEC--SIN')then
c	      crlabel(i) = rangleh(dble(crval(i)))
              crlabel(i) = rangleh(crval(i))
              cdelt(i) = cdelt(i)*rts
            else if(ctype(i)(1:4).eq.'VELO') then
              write(crlabel(i),'(f8.3,a)') crval(i),' km/s'
            else if(ctype(i)(1:4).eq.'FREQ')then
              write(crlabel(i),'(f9.4,a)') crval(i),' GHz'
            else
              write(crlabel(i),'(g13.6)') crval(i)
            endif
90000     continue
c        end if
c
c  Draw the labels using pgplot.
c
        call pgqinf('HARDCOPY',ans,la)
        if (ans.eq.'YES') then
          call pgslw(3)
          call pgscf(2)
        else
          call pgslw(1)
          call pgscf(1)
        end if
	call pgqwin(ax,bx,ay,by)
        call pgvsiz(0.78*schi,0.98*schi,sdlo,sdhi)
        call pgswin(1.,10.,1.,30.)
        call pgsch(1.0)
        call pgptxt(5.5,30.,0.5,0.5,object)
        call pgsch(0.7)
        call pgptxt(1.,28.,0.,0.,crlabel(1)//' '//crlabel(2))
        last = len1(in)
        if (last.eq.0) last = 20
        mid = max(1,last-20)
        msg = 'File: '//in(mid:last)
        call pgptxt(1.,25.,0.,0.,msg)
        write(text,'(a,f10.6,a)') 'Freq:',restfreq,' (GHz)'
        call pgptxt(1.,24.,0.,0.,text)
        if(naxis.ge.3)call pgptxt(1.,23.,0.,0.,'Crval3: '//crlabel(3))
        write(text,'(a,g13.6)') 'Max: ',tmax
        call pgptxt(1.,22.,0.,0.,text)
        write(text,'(a,g13.6)') 'Min: ',tmin
        call pgptxt(1.,21.,0.,0.,text)
        call pgptxt(1.,20.,0.,0.,'Units: '//bunit)
        if(bmaj.gt.0.) then
          write(text,'(a,f6.1,a,f6.1)') 'Beam:',bmaj*rts,' x ',bmin*rts
          call pgptxt(1.,19.,0.,0.,text)
        end if
        if(pbfwhm.ge.0.) then
          write(text,'(a,f6.0)') 'Pbfwhm:',pbfwhm
          call pgptxt(1.,18.,0.,0.,text)
        end if
        write(text,'(a,i4,a,i4,a,i3)') 'Axes:',
     *                  nsize(1),' x ',nsize(2),' x ',nsize(3)
        call pgptxt(1.,17.,0.,0.,text)
        write(text,'(f6.2,a,f6.2,a,f6.2)')
     *           cdelt(1),' x ',cdelt(2),' x ',cdelt(3)
        call pgptxt(2.,16.,0.,0.,text)
        if(range(1).ne.range(2))then
          write(text,'(a,2g10.3)') 'Image:',range
          call pgptxt(1.,14.,0.,0.,text)
        endif
	if (numlevs.gt.0) then
          write(text,'(a,i6)') 'Contours:',numlevs
          call pgptxt(1.,10.,0.,0.,text)
          do 90001 i=1,numlevs,2
            if(i+1.le.numlevs) then
              write(text,'(2f8.3)') conlevs(i),conlevs(i+1)
            else
              write(text,'(2f8.3)') conlevs(i)
            end if
            call pgptxt(1.,9.-i/2.,0.,0.,text)
90001     continue
	endif
c
c reset line width and character size for hardcopy device
c
        call pgqinf('HARDCOPY',ans,la)
        if (ans.eq.'YES') then
          call pgslw(1)
        end if
        end

        subroutine beampat(tno,corner,blc,trc,funits)
        integer tno,corner
        real blc(3), trc(3)
        character*(*) funits
c
c  Add a picture of the beam to the specified corner of the plot.
c
c  Inputs:
c    tno	The handle of the input image.
c    corner	is 0 for none or 1-4 to specify corner
c    blc,trc	The corners of the region of interest.
c    funits	Units of plot.
c------------------------------------------------------c
        real PI
        parameter(PI=3.14159654)
        integer i
        real xfract(4), yfract(4)
        real xs(0:360), ys(0:360)
        real bx, by, cdelt1, cdelt2, t
        real bmaj, bmin, bpa, xcen, ycen, xfac, yfac
        real xx,yy,bbpa
c
        data xfract /-.01,.99,.99,-.01/
        data yfract /-.01,-.01,.99,.99/
c
        if(corner.eq.0) return
c
c  Get the beam size (arcsec).
c
        call rdhdr(tno,'bmaj',bmaj,0.)
        call rdhdr(tno,'bmin',bmin,0.)
        call rdhdr(tno,'bpa',bpa,0.)
        bmaj = bmaj/2.
        bmin = bmin/2.
        if(bmin.eq.0.  .or. bmaj.eq.0.) return
c
c  Calculate factors to convert to units on x and y axes.
c
        if(index(funits,'a').gt.0) then
          xfac = 12. / PI
          yfac = 180. / PI
        else if (index(funits,'s').gt.0) then
          xfac = 180. * 3600. / PI
          yfac = 180. * 3600. / PI
        else
          call rdhdr(tno,'cdelt1',cdelt1,0.)
          call rdhdr(tno,'cdelt2',cdelt2,0.)
          xfac = 1. / cdelt1
          yfac = 1. / cdelt2
        end if
c
c  Calculate center of pattern.
c
        xcen = trc(1) + (blc(1)-trc(1))*abs(xfract(corner))
     *                  - sign(1.,xfract(corner))*1.4*bmaj*xfac
        ycen = trc(2) + (blc(2)-trc(2))*abs(yfract(corner))
     *                  + sign(1.,yfract(corner))*1.4*bmaj*yfac
c
c  Make up box around beam.
c
        bx = 1.2 * bmaj * xfac
        by = 1.2 * bmaj * yfac
        call pgsfs(1)
        call pgsci(0)
        call pgrect(xcen-bx,xcen+bx,ycen-by,ycen+by)
        call pgsfs(2)
        call pgsci(1)
        call pgrect(xcen-bx,xcen+bx,ycen-by,ycen+by)
c
c  Fill in the polygon.
c
        bbpa = (90.+bpa)*3.1415926/180.
        do 90000 i=0,360
          t = i*3.1415926/180.
          xx = bmaj*cos(t)
          yy = bmin*sin(t)
          xs(i) = xcen + (xx*cos(bbpa) + yy*sin(bbpa))*xfac
          ys(i) = ycen + (-xx*sin(bbpa) +yy*cos(bbpa))*yfac
90000   continue
c
c  Draw the beam.
c
        call pgsfs(2)
        call pgsci(1)
        call pgpoly(361,xs(0),ys(0))
	return
        end

        subroutine labels(tno,blc,trc,flag,ablc,atrc,trout,label)
        integer tno,blc(3),trc(3)
        character*(*) flag,label(2)
        real ablc(3),atrc(3),trout(6)
c
c  Make the coordinate labels for plotting a Miriad image.
c
c  The types of units are permitted are:
c	p  pixels with respect to center
c	s  arcseconds with respect to center, km/s, or Ghz
c	a  absolute coordinates RA(hrs), DEC(degs), km/s, or Ghz
c
c  Inputs:
c    tno	The handle of the input Image.
c    blc	The input bottom left corner.
c    trc	The input top right corner.
c    flag	The flag for coordinate labels.
c  Outputs:
c    ablc	User units bottom left corner
c    atrc	User units top right corner
c    trout	The translation array for pgplot
c    label	The axis labels for the plot
c--
c  History:
c      mar89  wh	Original 'units' routine.
c    23mar90 mchw	Removed input unit conversion; simplyfied.
c    23jun90 mchw	Rewritten to accomodate transposed images.
c    25mar92 mjs        Altered trout calc for use of memalloc routine
c----------------------------------------------------------------------c
        integer maxnax
        double precision PI
        parameter(maxnax=3,PI=3.141592654)
        real crval,cdelt,crpix,scale,offset,cosdec
        integer i,naxis
        character axis*1,ctype*10,type*16
c
c  Externals.
c
        character itoaf*1
c
c  Get cosdec if needed for absolute coordinates.
c
        if(index(flag,'a').gt.0) then
          call rdhdi(tno,'naxis',naxis,1)
          cosdec = 1.
          do 90000 i=1,naxis
            axis=itoaf(i)
            call rdhda(tno,'ctype'//axis,ctype, ' ')
            if(ctype(1:3).eq.'DEC') then
              call rdhdr(tno,'crval'//axis,crval,0.)
              cosdec = cos(crval)
            endif
90000     continue
        endif
c
c  Make the coordinates axes for the plot.
c
        do 90001 i=1,2
          axis=itoaf(i)
          call rdhda(tno,'ctype'//axis,ctype, ' ')
          call rdhdr(tno,'crpix'//axis,crpix,1.)
          call rdhdr(tno,'crval'//axis,crval,0.)
          call rdhdr(tno,'cdelt'//axis,cdelt,1.e-6)
c
c  Make nice labels from ctype.
c
          type = ctype
          if(ctype(1:2).eq.'RA') type='RA'
          if(ctype(1:3).eq.'DEC') type='DEC'
          if(ctype(1:4).eq.'VELO') type='Velocity (km/s)'
          if(ctype(1:4).eq.'FREQ') type='Frequency (GHz)'
c
c  Absolute RA(hours) and DEC(degs)
c
          if(index(flag,'a').gt.0 .and. ctype(1:2).eq.'RA') then
            scale = cdelt * 12./PI/cosdec
            offset = crval * 12./PI - crpix*scale
            label(i) = 'RA (Hours)'
          else if(index(flag,'a').gt.0 .and. ctype(1:3).eq.'DEC') then
            scale = cdelt * 180./PI
            offset = crval * 180./PI - crpix*scale
            label(i) = 'DEC (Degrees)'
c
c  Relative RA and DEC (arcseconds from center).
c
          else if(index(flag,'s').gt.0 .and. ctype(1:2).eq.'RA') then
            scale = cdelt * 3600.*180./PI
            offset = -crpix*scale
            label(i) = 'Relative RA (")'
          else if(index(flag,'s').gt.0 .and. ctype(1:3).eq.'DEC') then
            scale = cdelt * 3600.*180./PI
            offset = -crpix*scale
            label(i) = 'Relative DEC (")'
c
c  Frequency or velocity axes.
c
          else if(index(flag,'a').gt.0 .or. index(flag,'s').gt.0) then
            scale = cdelt
            offset = crval - crpix*scale
            label(i) = type
c
c  Pixels.
c
          else
            scale = 1.
            offset = -crpix
            label(i) = type(1:9)//' Pixels'
          endif
c
c  Set the corners and the translation array for PGPLOT.
c
          ablc(i) = blc(i)*scale + offset
          atrc(i) = trc(i)*scale + offset
c
c  Following line replace by the 2 below it on 25mar92.
c
c	  trout(i*i) = offset
c
          if (i .eq. 1) trout(i*i) = offset + scale * (blc(1) - 1)
          if (i .eq. 2) trout(i*i) = offset + scale * (blc(2) - 1)
          trout(i*(i+1)) = scale
90001   continue
        trout(3) = 0.
        trout(5) = 0.
        end

