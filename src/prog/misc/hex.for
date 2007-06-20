c**********************************************************************c
      program HEX
      implicit none
c
c= HEX -  Calculate hexagonal pointing grids for mosaicing.
c& mchw
c: image analysis
c+
c	HEX - Calculate hexagonal pointing grids for mosaicing.
c
c	   *   *
c	 *   *   *
c	   *   *
c	    hex7
c
c@ rings
c	number of rings. Default rings=2 makes a hexagonal grid of
c	7 pointings.
c@ cell
c	Horizontal grid spacing in arcsecs.
c	The vertical spacing is sqrt(3)/2 times the
c	horizontal spacing.  
c--
c History
c  mchw 28may96  Original version.
c  mchw 12jul02  Added documentation and key routine input.
c  mchw 01nov02  Changed format for ATA.
c----------------------------------------------------------------------c
        character version*(*)
        parameter(version='version 01nov02')
        character fmtstr*16
	real x, y, cell
	integer n,k,row
c
        call output('HEX: '//version)
        call keyini
        call keyi('rings',n,2)
        call keyr('cell',cell,60.)
        call keyfin
c
        fmtstr = '(f9.2,a,f9.2)'
c
	do row=-(n-1),(n-1),1
	  y =row*cell*0.8660254
	  do k = -(2*n-abs(row)-2),(2*n-abs(row)-2),2
	    x =k*cell*0.5
	    print(fmtstr), x, ',', y
	  enddo
	enddo
	end
