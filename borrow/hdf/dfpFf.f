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

C
C $Header$
C
C $Log$
C Revision 1.1  1990/09/28 21:49:59  teuben
C Initial revision
C
c Revision 3.1  90/07/02  11:52:13  clow
c some cosmetic modifications
c 
c Revision 3.0  90/02/02  20:31:06  clow
c *** empty log message ***
c 

C------------------------------------------------------------------------------
C File:     dfpF.c
C Purpose:  Fortran stubs for Palette Fortran routines
C Invokes:  dfpF.c dfkit.c
C Contents: 
C   dpgpal:         Call dpigpal to get palette
C   dpapal:         Call dpippal to add palette to file
C   dpppal:         Call dpippal to write/overwrite palette in file
C   dpnpal:         Call dpinpal to get number of palettes in file
C   dpwref:         Call dpiwref to set ref of pal to write next
C   dprref:         Call dpirref to set ref of pal to read next
C   DFPgetpal:      Call dpigpal to get palette
C   DFPaddpal:      Call dpippal to add palette to file
C   DFPputpal:      Call dpippal to write/overwrite palette in file
C   DFPnpals:       Call dpinpal to get number of palettes in file
C   DFPwriteref:    Call dpiwref to set ref of pal to write next
C   DFPreadref:     Call dpirref to set ref of pal to read next
C Remarks: none
C----------------------------------------------------------------------------*/


C------------------------------------------------------------------------------
C Name: dpgpal
C Purpose:  call dpigpal, get palette
C Inputs:   filename: filename to get pal from
C           pal: space to put palette
C Returns: 0 on success, -1 on failure with DFerror set
C Users:    Fortran stub routine
C Invokes: dpigpal
C----------------------------------------------------------------------------*/

      integer function dpgpal(filename, pal)

      character*(*) filename
      character*(*) pal
      integer dpigpal

      dpgpal = dpigpal(filename, pal, len(filename))
      return
      end


C------------------------------------------------------------------------------
C Name: dpapal
C Purpose:  call dpippal, add palette
C Inputs:   filename: filename to put pal into
C           pal: palette
C Returns: 0 on success, -1 on failure with DFerror set
C Users:    Fortran stub routine
C Invokes: dpippal
C----------------------------------------------------------------------------*/

      integer function dpapal(filename, pal)

      character*(*) filename
      character*(*) pal
      integer dpippal

      dpapal = dpippal(filename, pal, 0, 'a', len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: dpppal
C     Purpose:  call dpippal, write palette
C     Inputs:   filename: filename to put pal to
C     pal: palette
C     ow, filemode: see DFPputpal
C     Returns: 0 on success, -1 on failure with DFerror set
C     Users:    Fortran stub routine
C     Invokes: dpippal
C----------------------------------------------------------------------------*/
      
      integer function dpppal(filename, pal, ow, filemode)
      
      character*(*) filename
      character*(*) pal
      integer dpippal, ow, filemode
      
      dpppal = dpippal(filename, pal, ow, filemode, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: dpnpals
C     Purpose:  How many palettes are present in this file?
C     Inputs:   filename: name of HDF file
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpinpal
C----------------------------------------------------------------------------*/
      
      integer function dpnpals(filename)
      
      character*(*) filename
      integer dpinpal
      
      dpnpals = dpinpal(filename, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: dpwref
C     Purpose:  Ref to write next
C     Inputs:   filename: name of HDF file
C     ref: ref to write next
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpiwref
C----------------------------------------------------------------------------*/
      
      integer function dpwref(filename, ref)
      
      character*(*) filename
      integer ref, dpiwref
      
      dpwref = dpiwref(filename, ref, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: dprref
C     Purpose:  Ref to read next
C     Inputs:   filename: name of HDF file
C     ref: ref to read next
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpirref
C----------------------------------------------------------------------------*/
      
      integer function dprref(filename, ref)
      
      character*(*) filename
      integer ref, dpirref
      
      dprref = dpirref(filename, ref, len(filename))
      return
      end
      
      
CEND7MAX
      
      
C------------------------------------------------------------------------------
C     Name: DFPgetpal
C     Purpose:  call dpigpal, get palette
C     Inputs:   filename: filename to get pal from
C     pal: space to put palette
C     Returns: 0 on success, -1 on failure with DFerror set
C     Users:    Fortran stub routine
C     Invokes: dpigpal
C----------------------------------------------------------------------------*/
      
      integer function DFPgetpal(filename, pal)
      
      character*(*) filename
      character*(*) pal
      integer dpigpal
      
      DFPgetpal = dpigpal(filename, pal, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: DFPaddpal
C     Purpose:  call dpippal, add palette
C     Inputs:   filename: filename to put pal into
C     pal: palette
C     Returns: 0 on success, -1 on failure with DFerror set
C     Users:    Fortran stub routine
C     Invokes: dpippal
C----------------------------------------------------------------------------*/
      
      integer function DFPaddpal(filename, pal)
      
      character*(*) filename
      character*(*) pal
      integer dpippal
      
      DFPaddpal = dpippal(filename, pal, 0, 'a', len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: DFPputpal
C     Purpose:  call dpippal, write palette
C     Inputs:   filename: filename to put pal to
C     pal: palette
C     ow, filemode: see DFPputpal
C     Returns: 0 on success, -1 on failure with DFerror set
C     Users:    Fortran stub routine
C     Invokes: dpippal
C----------------------------------------------------------------------------*/
      
      integer function DFPputpal(filename, pal, ow, filemode)
      
      character*(*) filename
      character*(*) pal
      integer dpippal, ow, filemode
      
      DFPputpal = dpippal(filename, pal, ow, filemode, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: dpnpals
C     Purpose:  How many palettes are present in this file?
C     Inputs:   filename: name of HDF file
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpinpal
C----------------------------------------------------------------------------*/
      
      integer function DFPnpals(filename)
      
      character*(*) filename
      integer dpinpal
      
      DFPnpals = dpinpal(filename, len(filename))
      return
      end

      
C------------------------------------------------------------------------------
C     Name: DFPwriteref
C     Purpose:  Ref to write next
C     Inputs:   filename: name of HDF file
C     ref: ref to write next
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpiwref
C----------------------------------------------------------------------------*/
      
      integer function DFPwriteref(filename, ref)
      
      character*(*) filename
      integer ref, dpiwref
      
      DFPwriteref = dpiwref(filename, ref, len(filename))
      return
      end
      
      
C------------------------------------------------------------------------------
C     Name: DFPreadref
C     Purpose:  Ref to read next
C     Inputs:   filename: name of HDF file
C     ref: ref to read next
C     Returns: number of palettes on success, -1 on failure with DFerror set
C     Users:    HDF programmers, other routines and utilities
C     Invokes: dpirref
C----------------------------------------------------------------------------*/
      
      integer function DFPreadref(filename, ref)
      
      character*(*) filename
      integer ref, dpirref
      
      DFPreadref = dpirref(filename, ref, len(filename))
      return
      end
