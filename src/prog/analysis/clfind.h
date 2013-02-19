c---------------------------------------------------------------
c     clfind.h
c     include file for the clump finding program
c---------------------------------------------------------------
      include 'clpars.h'

c MAXLVL  = number of contour levels
c MAXREG  = number of regions/level
c MAXPIX  = number of pixels/level (level>2)
c MAXCLP  = total number of clumps
c MAXPIX1 = number of pixels in level 1 (dT < T < 2dT)
      integer MAXLVL,MAXREG,MAXCLP,MAXPIX,MAXPIX1
      parameter(MAXLVL=100,MAXREG=250,MAXCLP=250)
      parameter(MAXPIX=250000,MAXPIX1=2000000)

c #pixels/level
      integer npix(MAXLVL)                    

c #regions/level
      integer nregions(MAXLVL)                

c merge flag
      logical merge(MAXREG)                   

c tree structure
      logical tree(MAXLVL,MAXREG,MAXCLP)

      common /ianalyz/ npix,nregions
      common /lanalyz/ tree,merge

      integer clump(MAXCLP,4)
      common /clumps/ clump

      integer nlevels,badcl
      common /parms/ nlevels,badcl
c ---------------------------------------------------------
c----------------------------------------------------------------
c     header.h
c     header variables for file in clumpfind
c----------------------------------------------------------------
      integer lin,lout
      common /files/ lin,lout

      integer p1,p3
      real p2
      common /parms/ p1,p2,p3

      integer nx,ny,nz
      real dx,dy,dv
      character*8 ctype(4)
      common /headvarn/ nx,ny,nz,dx,dy,dv
      common /headvarc/ ctype

      double precision crpix(4),crval(4),cdelt(4),bmaj,bmin,bpa
      common /dheadvar/ crpix,crval,cdelt,bmaj,bmin,bpa

c----------------------------------------------------------------
