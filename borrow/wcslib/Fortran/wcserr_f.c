/*============================================================================

  WCSLIB 4.18 - an implementation of the FITS WCS standard.
  Copyright (C) 1995-2013, Mark Calabretta

  This file is part of WCSLIB.

  WCSLIB is free software: you can redistribute it and/or modify it under the
  terms of the GNU Lesser General Public License as published by the Free
  Software Foundation, either version 3 of the License, or (at your option)
  any later version.

  WCSLIB is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for
  more details.

  You should have received a copy of the GNU Lesser General Public License
  along with WCSLIB.  If not, see http://www.gnu.org/licenses.

  Direct correspondence concerning WCSLIB to mark@calabretta.id.au

  Author: Mark Calabretta, Australia Telescope National Facility, CSIRO.
  http://www.atnf.csiro.au/people/Mark.Calabretta
  $Id$
*===========================================================================*/

#include <stdio.h>
#include <string.h>

#include <wcserr.h>
#include <wcsutil.h>

/* Fortran name mangling. */
#include <wcsconfig_f77.h>
#define wcserr_enable_  F77_FUNC(wcserr_enable, WCSERR_ENABLE)
#define wcserr_get_  F77_FUNC(wcserr_get, WCSERR_GET)
#define wcserr_prt_  F77_FUNC(wcserr_prt, WCSERR_PRT)

#define WCSERR_STATUS   200
#define WCSERR_LINE_NO  201
#define WCSERR_FUNCTION 202
#define WCSERR_FILE     203
#define WCSERR_MSG      204

/*--------------------------------------------------------------------------*/

int wcserr_enable_(const int *enable)

{
  return wcserr_enable(*enable);
}

/*--------------------------------------------------------------------------*/

int wcserr_get_(const int *err, const int *what, void *value)

{
  char   *cvalp;
  int    *ivalp;
  const struct wcserr *errp;

  /* Cast pointers. */
  errp  = (const struct wcserr *)err;
  cvalp = (char *)value;
  ivalp = (int *)value;

  switch (*what) {
  case WCSERR_STATUS:
    *ivalp = errp->status;
    break;
  case WCSERR_LINE_NO:
    *ivalp = errp->line_no;
    break;
  case WCSERR_FUNCTION:
    strncpy(cvalp, errp->function, 72);
    wcsutil_blank_fill(72, cvalp);
    break;
  case WCSERR_FILE:
    strncpy(cvalp, errp->file, 72);
    wcsutil_blank_fill(72, cvalp);
    break;
  case WCSERR_MSG:
    strncpy(cvalp, errp->msg, WCSERR_MSG_LENGTH);
    wcsutil_blank_fill(WCSERR_MSG_LENGTH, cvalp);
    break;
  default:
    return 1;
  }

  return 0;
}

int wcserr_gtc_(const int *wcs, const int *what, char *value)
{
  return wcserr_get_(wcs, what, value);
}

int wcserr_gti_(const int *wcs, const int *what, int *value)
{
  return wcserr_get_(wcs, what, value);
}

/*--------------------------------------------------------------------------*/

int wcserr_prt_(const int *err, const char prefix[72])

{
  char prefix_[72];
  strncpy(prefix_, prefix, 72);
  prefix_[71] = '\0';

  /* This may or may not force the Fortran I/O buffers to be flushed.  If
   * not, try CALL FLUSH(6) before calling WCSERR_PRT in the Fortran code. */
  fflush(NULL);

  return wcserr_prt((const struct wcserr *)err, prefix_);
}
