*=======================================================================
*
* WCSLIB 4.18 - an implementation of the FITS WCS standard.
* Copyright (C) 1995-2013, Mark Calabretta
*
* This file is part of WCSLIB.
*
* WCSLIB is free software: you can redistribute it and/or modify it
* under the terms of the GNU Lesser General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* WCSLIB is distributed in the hope that it will be useful, but WITHOUT
* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
* FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
* License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with WCSLIB.  If not, see http://www.gnu.org/licenses.
*
* Direct correspondence concerning WCSLIB to mark@calabretta.id.au
*
* Author: Mark Calabretta, Australia Telescope National Facility, CSIRO.
* http://www.atnf.csiro.au/people/Mark.Calabretta
* $Id$
*=======================================================================

      BLOCK DATA SPC_BLOCK_DATA

      CHARACTER SPC_ERRMSG(0:4)*80

      COMMON /SPC_DATA/ SPC_ERRMSG

      DATA SPC_ERRMSG /
     :  'Success',
     :  'Null spcprm pointer passed',
     :  'Invalid spectral parameters',
     :  'One or more of x coordinates were invalid',
     :  'One or more of the spec coordinates were invalid'/

      END
