C
C $Header$
C
C $Log$
C Revision 1.1.1.1  1990/09/28 21:50:00  teuben
C UIUC 15-feb-2001 w/out wip and some manuals
C
c Revision 3.2  90/07/06  09:40:10  clow
c Added fortran stubs for DFR8readref:  d8rref, d8readref, and d8irref_
c 
c Revision 3.1  90/07/02  10:11:57  clow
c some cosmetic modifications
c 
C

C------------------------------------------------------------------------------
C File:     dfr8Ff.f
C Purpose:  Fortran stubs for Fortran RIS routines
C Invokes:  dfr8F.c
C Contents: 
C   d8gdims: call d8igdim to get dimensions of next image
C   d8gimg: call d8igimg to get next image
C   d8pimg: call d8ipimg to put image to new file
C   d8aimg: call d8iaimg to add image to existing file
C   dfr8getdims: call d8igdim to get dimensions of next image
C   dfr8getimage: call d8igimg to get next image
C   dfr8putimage: call d8ipimg to put image to new file
C   dfr8addimage: call d8iaimg to add image to existing file
C -----------------------------------------------------------------------------

C------------------------------------------------------------------------------
C Name:     d8gdims
C Purpose:  call d8igdim to get dimensions of next image
C Inputs:   name: name of HDF file
C           xdim, ydim: integers to return dimensions of image
C           ispal: integer to return whether a palette is associated
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8igdim
C------------------------------------------------------------------------------


      integer function d8gdims(name, xdim, ydim, ispal)
      character*(*) name
      integer xdim, ydim, ispal, d8igdim

      d8gdims = d8igdim(name, xdim, ydim, ispal, len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     d8gimg
C Purpose:  call d8igimg to get next image
C Inputs:   name: name of HDF file
C           image: space to return image in
C           xdim, ydim: dimensions of space to return image in
C           pal: 768-byte space to return palette in
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8igimg
C------------------------------------------------------------------------------


      integer function d8gimg(name, image, xdim, ydim, pal)
      character*(*) name
      character image(*), pal(*)
      integer xdim, ydim, d8igimg

      d8gimg = d8igimg(name,image,xdim,ydim,pal,len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     d8pimg
C Purpose:  call d8ipimg to write image to new file
C Inputs:   name: name of HDF file
C           image: space containing image
C           xdim, ydim: dimensions of image
C           compress: compression scheme to be used
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8ipimg
C------------------------------------------------------------------------------


      integer function d8pimg(name, image, xdim, ydim, compress)
      character*(*) name
      character image(*)
      integer xdim, ydim, compress, d8ipimg

      d8pimg=d8ipimg(name,image,xdim,ydim,compress,len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     d8aimg
C Purpose:  call d8iaimg to add image to existing file
C Inputs:   name: name of HDF file
C           image: space containing image
C           xdim, ydim: dimensions of image
C           compress: compression scheme to be used
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8iaimg
C------------------------------------------------------------------------------


      integer function d8aimg(name, image, xdim, ydim, compress)
      character*(*) name
      character image(*)
      integer xdim, ydim, compress, d8iaimg

      d8aimg=d8iaimg(name,image,xdim,ydim,compress,len(name))
      return
      end

C-----------------------------------------------------------------------------
C  Name:    d8rref
C  Purpose: Set ref of image to get next
C  Inputs:  filename: file to which this applies
C           ref: reference number of next get
C  Returns: 0 on success, -1 on failure
C  Users:   HDF programmers, other routines and utilities
C  Invokes: d8irref
C  Remarks: checks if image with this ref exists
C-----------------------------------------------------------------------------

      integer function d8rref(name, ref)
      character*(*) name
      integer ref, d8irref

      d8rref = d8irref(name, ref, len(name))
      return
      end

CEND7MAX


C------------------------------------------------------------------------------
C Name:     dfr8getdims
C Purpose:  call d8igdim to get dimensions of next image
C Inputs:   name: name of HDF file
C           xdim, ydim: integers to return dimensions of image
C           ispal: integer to return whether a palette is associated
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8igdim
C------------------------------------------------------------------------------


      integer function dfr8getdims(name, xdim, ydim, ispal)
      character*(*) name
      integer xdim, ydim, ispal, d8igdim

      dfr8getdims = d8igdim(name, xdim, ydim, ispal, len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     dfr8getimage
C Purpose:  call d8igimg to get next image
C Inputs:   name: name of HDF file
C           image: space to return image in
C           xdim, ydim: dimensions of space to return image in
C           pal: 768-byte space to return palette in
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8igimg
C------------------------------------------------------------------------------


      integer function dfr8getimage(name, image, xdim, ydim, pal)
      character*(*) name
      character image(*), pal(*)
      integer xdim, ydim, d8igimg

      dfr8getimage = d8igimg(name,image,xdim,ydim,pal,len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     dfr8putimage
C Purpose:  call d8ipimg to write image to new file
C Inputs:   name: name of HDF file
C           image: space containing image
C           xdim, ydim: dimensions of image
C           compress: compression scheme to be used
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8ipimg
C------------------------------------------------------------------------------


      integer function dfr8putimage(name, image, xdim, ydim, compress)
      character*(*) name
      character image(*)
      integer xdim, ydim, compress, d8ipimg

      dfr8putimage=d8ipimg(name,image,xdim,ydim,compress,len(name))
      return
      end


C------------------------------------------------------------------------------
C Name:     dfr8addimage
C Purpose:  call d8iaimg to add image to existing file
C Inputs:   name: name of HDF file
C           image: space containing image
C           xdim, ydim: dimensions of image
C           compress: compression scheme to be used
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  d8iaimg
C------------------------------------------------------------------------------


      integer function dfr8addimage(name, image, xdim, ydim, compress)
      character*(*) name
      character image(*)
      integer xdim, ydim, compress, d8iaimg

      dfr8addimage=d8iaimg(name,image,xdim,ydim,compress,len(name))
      return
      end


C-----------------------------------------------------------------------------
C  Name:    dfr8readref
C  Purpose: Set ref of image to get next
C  Inputs:  filename: file to which this applies
C           ref: reference number of next get
C  Returns: 0 on success, -1 on failure
C  Users:   HDF programmers, other routines and utilities
C  Invokes: d8irref
C  Remarks: checks if image with this ref exists
C-----------------------------------------------------------------------------

      integer function dfr8readref(name, ref)
      character*(*) name
      integer ref, d8irref

      dfr8readref = d8irref(name, ref, len(name))
      return
      end
