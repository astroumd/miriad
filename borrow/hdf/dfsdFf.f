C*****************************************************************************
C 
C			  NCSA HDF version 3.10r2
C				Sept 20, 1990
C
C NCSA HDF Version 3.10r2 source code and documentation are in the public
C domain.  Specifically, we give to the public domain all rights for future
C licensing of the source code, all resale rights, and all publishing rights.
C 
C We ask, but do not require, that the following message be included in all
C derived works:
C 
C Portions developed at the National Center for Supercomputing Applications at
C the University of Illinois at Urbana-Champaign.
C 
C THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
C SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
C WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
C 
C*****************************************************************************

C $Revision$
C $Header$
C $Log$
C Revision 1.1.1.1  1990/09/28 21:50:06  teuben
C UIUC 15-feb-2001 w/out wip and some manuals
C
c Revision 3.2  90/08/31  12:36:11  clow
c fixed inconsistency in arg list of dsgslc\
c 
c Revision 3.1  90/06/13  16:31:17  clow
c added DFSDreadref that will set the ref of the next SD read in.
c 
C------------------------------------------------------------------------------
C File:     dfsdFf.f
C Purpose:  Fortran stubs for Fortran SDS routines
C Invokes:  dfsdF.c dfsd.c
C Contents: 
C   dsgdims:        get dimensions of next SDG
C   dsgdata:        get data for next SDG
C   dssdast:        set strings for data for subsequent SDGs
C   dssdist:        set strings for a dimension for subsequent SDGs
C   dspdata:        write SDG to new file
C   dsadata:        append SDG to existing file
C   dsgslc:         get slice from file
C   dssslc:         set up to write slices to file
C   dsrref:	    set up next ref to read
C   dfsdgetdims:    get dimensions of next SDG
C   dfsdgetdata:    get data for next SDG
C   dfsdsetdatastrs:set strings for data for subsequent SDGs
C   dfsdsetdimstrs: set strings for a dimension for subsequent SDGs
C   dfsdputdata:    write SDG to new file
C   dfsdadddata:    append SDG to existing file
C   dfsdgetslice:   get slice from file
C   dfsdstartslice:set up to write slices to file
C   dfsdreadref:    set up next ref to read
C Remarks: none
C------------------------------------------------------------------------------



C------------------------------------------------------------------------------
C Name: dsgdims
C Purpose:  get dimensions of next SDG
C Inputs:   filename: name of HDF file
C           rank: integer to return rank in
C           dimsizes: array to return dimensions in
C           maxrank: size of array dimsizes
C Returns: 0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes: dsigdim
C------------------------------------------------------------------------------

      integer function dsgdims(filename, rank, dimsizes, maxrank)
      character*(*) filename
      integer rank, dimsizes, maxrank, dsigdim

      dsgdims = dsigdim(filename, rank, dimsizes, maxrank,
     +                                              len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dsgdata
C Purpose:  get data from next SDG
C Inputs:   filename: name of HDF file
C           rank: integer containing no of dimensions in array data
C           maxsizes: array containing dimensions of array data
C           data: array to return data values in
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsigdat
C------------------------------------------------------------------------------

      integer function dsgdata(filename, rank, maxsizes, data)
      character*(*) filename
      integer rank, maxsizes, dsigdat
      real data

      dsgdata = dsigdat(filename, rank, maxsizes, data,
     +                                                len(filename))
      return
      end


C------------------------------------------------------------------------------
C Name:     dssdast
C Purpose:  set data strings to be written out with next SDG
C Inputs:   label, unit, format, coordsys: strings to be set
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisdas_
C------------------------------------------------------------------------------

      integer function  dssdast(label, unit, format, coordsys)
      character*(*) label, unit, format,  coordsys
      integer dsisdas, len

      dssdast = dsisdas(label, unit, format, coordsys,
     +1, len(label), len(unit), len(format), len(coordsys))

      return
      end


C------------------------------------------------------------------------------
C Name:     dssdist
C Purpose:  set dim strings to be written out with next SDG
C Inputs:   label, unit, format, coordsys: strings to be set
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisdis_
C------------------------------------------------------------------------------

      integer function  dssdist(dim, label, unit, format)
      character*(*) label, unit, format
      integer dim, len
      integer dsisdis

      dssdist = dsisdis(dim, label, unit, format, 1,
     +len(label), len(unit), len(format))

      return
      end


C------------------------------------------------------------------------------
C Name:     dspdata
C Purpose:  call dsipdat to write SDG to new file
C Inputs:   filename: name of HDF file
C           rank: no of dimensions of array data
C           dimsizes: array containing the dimensions of array data
C           data: array containing the data values
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsipdat
C------------------------------------------------------------------------------

      integer function dspdata(filename, rank, dimsizes, data)
      character*(*) filename
      integer rank, dimsizes, data, len, dsipdat

      dspdata = dsipdat(filename, rank, dimsizes, data, len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dsadata
C Purpose:  call dsiadat to append SDG to existing file
C Inputs:   filename: name of HDF file
C           rank: no of dimensions of array data
C           dimsizes: array containing the dimensions of array data
C           data: array containing the data values
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsiadat
C------------------------------------------------------------------------------

      integer function dsadata(filename, rank, dimsizes, data)
      character*(*) filename
      integer rank, dimsizes, data, len, dsiadat

      dsadata = dsiadat(filename, rank, dimsizes, data, len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dsgslc
C Purpose:  call dsigslc to get slice from file
C Inputs:   filename: name of HDF file
C           winst: array of size = rank of data, containing start of slice
C           winend: array of size rank, containing end of slice
C           data: array for returning slice
C           ndims: no of dims of array data
C           dims: dimensions of array data
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsigslc
C------------------------------------------------------------------------------

      integer function dsgslc(filename,winst,windims,data,dims)
      character*(*) filename
      integer winst, windims, data, dims, dsigslc

      dsgslc = dsigslc(filename, winst, windims, data, dims,
     +     len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dssslc
C Purpose:  call dsisslc to set up to write slices
C Inputs:   filename: name of HDF file
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisslc
C------------------------------------------------------------------------------

      integer function dssslc(filename)
      character*(*) filename
      integer dsisslc

      dssslc = dsisslc(filename, len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dsrref
C Purpose:  call dsirref to set up next ref to read
C Inputs:   filename: name of HDF file
C           ref: next ref to read
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsirref
C------------------------------------------------------------------------------

      integer function dsrref(filename, ref)
      character*(*) filename
      integer ref
      integer dsirref

      dsrref = dsirref(filename, ref, len(filename))

      return
      end

CEND7MAX


C------------------------------------------------------------------------------
C Name: dfsdgetdims
C Purpose:  get dimensions of next SDG
C Inputs:   filename: name of HDF file
C           rank: integer to return rank in
C           dimsizes: array to return dimensions in
C           maxrank: size of array dimsizes
C Returns: 0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes: dsigdim
C------------------------------------------------------------------------------

      integer function dfsdgetdims(filename, rank, dimsizes, maxrank)
      character*(*) filename
      integer rank, dimsizes, maxrank, dsigdim

      dfsdgetdims = dsigdim(filename, rank, dimsizes, maxrank,
     +                                              len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdgetdata
C Purpose:  get data from next SDG
C Inputs:   filename: name of HDF file
C           rank: integer containing no of dimensions in array data
C           maxsizes: array containing dimensions of array data
C           data: array to return data values in
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsigdat
C------------------------------------------------------------------------------

      integer function dfsdgetdata(filename, rank, maxsizes, data)
      character*(*) filename
      integer rank, maxsizes, dsigdat
      real data

      dfsdgetdata = dsigdat(filename, rank, maxsizes, data,
     +                                                len(filename))
      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdsetdatastrs
C Purpose:  set data strings to be written out with next SDG
C Inputs:   label, unit, format, coordsys: strings to be set
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisdas_
C------------------------------------------------------------------------------

      integer function  dfsdsetdatastrs(label, unit, format, coordsys)
      character*(*) label, unit, format,  coordsys
      integer dsisdas, len

      dfsdsetdatastrs = dsisdas(label, unit, format, coordsys,
     +1, len(label), len(unit), len(format), len(coordsys))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdsetdimstrs
C Purpose:  set dim strings to be written out with next SDG
C Inputs:   label, unit, format, coordsys: strings to be set
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisdis_
C------------------------------------------------------------------------------

      integer function  dfsdsetdimstrs(dim, label, unit, format)
      character*(*) label, unit, format
      integer dim, len
      integer dsisdis

      dfsdsetdimstrs = dsisdis(dim, label, unit, format, 1,
     +len(label), len(unit), len(format))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdputdata
C Purpose:  call dsipdat to write SDG to new file
C Inputs:   filename: name of HDF file
C           rank: no of dimensions of array data
C           dimsizes: array containing the dimensions of array data
C           data: array containing the data values
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsipdat
C------------------------------------------------------------------------------

      integer function dfsdputdata(filename, rank, dimsizes, data)
      character*(*) filename
      integer rank, dimsizes, data, len, dsipdat

      dfsdputdata = dsipdat(filename,rank,dimsizes,data,len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdadddata
C Purpose:  call dsiadat to append SDG to existing file
C Inputs:   filename: name of HDF file
C           rank: no of dimensions of array data
C           dimsizes: array containing the dimensions of array data
C           data: array containing the data values
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsiadat
C------------------------------------------------------------------------------

      integer function dfsdadddata(filename, rank, dimsizes, data)
      character*(*) filename
      integer rank, dimsizes, data, len, dsiadat

      dfsdadddata = dsiadat(filename,rank,dimsizes,data,len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdgetslice
C Purpose:  call dsigslc to get slice from file
C Inputs:   filename: name of HDF file
C           winst: array of size = rank of data, containing start of slice
C           winend: array of size rank, containing end of slice
C           data: array for returning slice
C           ndims: no of dims of array data
C           dims: dimensions of array data
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsigslc
C------------------------------------------------------------------------------

      integer function dfsdgetslice(filename, winst, winend, data,
     +                                                    ndims, dims)
      character*(*) filename
      integer winst, winend, data, ndims, dims, dsigslc

      dfsdgetslice = dsigslc(filename, winst, winend, data, ndims,
     +                                             dims, len(filename))

      return
      end


C------------------------------------------------------------------------------
C Name:     dfsdstartslice
C Purpose:  call dsisslc to set up to write slices
C Inputs:   filename: name of HDF file
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsisslc
C------------------------------------------------------------------------------

      integer function dfsdstartslice(filename)
      character*(*) filename
      integer dsisslc

      dfsdstartslice = dsisslc(filename, len(filename))

      return
      end

C------------------------------------------------------------------------------
C Name:     dfsdreadref
C Purpose:  call dsirref to set up next ref to read
C Inputs:   filename: name of HDF file
C           ref: next ref to read
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dsirref
C------------------------------------------------------------------------------

      integer function dfsdreadref(filename, ref)
      character*(*) filename
      integer ref
      integer dsirref

      dfsdreadref = dsirref(filename, ref, len(filename))

      return
      end
