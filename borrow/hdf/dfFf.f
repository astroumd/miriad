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
C Revision 1.1  1990/09/28 21:49:47  teuben
C Initial revision
C
c Revision 3.1  90/07/02  10:12:18  clow
c some cosmetic modifications
c 
C

C------------------------------------------------------------------------------
C File:     dfFf.f
C Purpose:  Fortran stubs for Fortran low level i/o routines
C Invokes:  dfF.c dfkit.c
C Contents: 
C   dfopen: call dfiopen to open HDF file
C -----------------------------------------------------------------------------

C------------------------------------------------------------------------------
C Name:     dfopen
C Purpose:  call dfiopen to open HDF file
C Inputs:   name: name of HDF file to open
C           access: integer for access mode: DFACC_READ etc.
C           defdds: default number of DDs per header block
C Returns:  0 on success, -1 on failure with DFerror set
C Users:    HDF Fortran programmers
C Invokes:  dfiopen
C------------------------------------------------------------------------------


      integer function dfopen(name, access, defdds)
      character*(*) name
      integer access, defdds, dfiopen

      dfopen = dfiopen(name, access, defdds, len(name))
      return
      end
