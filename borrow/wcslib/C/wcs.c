/*============================================================================

  WCSLIB 4.5 - an implementation of the FITS WCS standard.
  Copyright (C) 1995-2010, Mark Calabretta

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
  along with WCSLIB.  If not, see <http://www.gnu.org/licenses/>.

  Correspondence concerning WCSLIB may be directed to:
    Internet email: mcalabre@atnf.csiro.au
    Postal address: Dr. Mark Calabretta
                    Australia Telescope National Facility, CSIRO
                    PO Box 76
                    Epping NSW 1710
                    AUSTRALIA

  Author: Mark Calabretta, Australia Telescope National Facility
  http://www.atnf.csiro.au/~mcalabre/index.html
  $Id$
*===========================================================================*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wcsmath.h"
#include "wcstrig.h"
#include "wcsunits.h"
#include "wcsutil.h"
#include "lin.h"
#include "log.h"
#include "spc.h"
#include "spx.h"
#include "prj.h"
#include "sph.h"
#include "cel.h"
#include "tab.h"
#include "wcs.h"

const int WCSSET = 137;

/* Maximum number of PVi_ma and PSi_ma keywords. */
int NPVMAX = 64;
int NPSMAX =  8;

/* Map status return value to message. */
const char *wcs_errmsg[] = {
  "Success",
  "Null wcsprm pointer passed",
  "Memory allocation failed",
  "Linear transformation matrix is singular",
  "Inconsistent or unrecognized coordinate axis types",
  "Invalid parameter value",
  "Invalid coordinate transformation parameters",
  "Ill-conditioned coordinate transformation parameters",
  "One or more of the pixel coordinates were invalid",
  "One or more of the world coordinates were invalid",
  "Invalid world coordinate",
  "No solution found in the specified interval",
  "Invalid subimage specification",
  "Non-separable subimage coordinate system"};

#ifndef signbit
#define signbit(X) ((X) < 0.0 ? 1 : 0)
#endif

/* Internal helper functions, not intended for general use. */
int  wcs_types(struct wcsprm *);
int  wcs_units(struct wcsprm *);

/*--------------------------------------------------------------------------*/

int wcsnpv(int npvmax) { if (npvmax >= 0) NPVMAX = npvmax; return NPVMAX; }
int wcsnps(int npsmax) { if (npsmax >= 0) NPSMAX = npsmax; return NPSMAX; }

/*--------------------------------------------------------------------------*/

int wcsini(int alloc, int naxis, struct wcsprm *wcs)

{
  int i, j, k, status;
  double *cd;

  if (wcs == 0x0) return 1;

  if (naxis <= 0) {
    return 2;
  }

  /* Initialize memory management. */
  if (wcs->flag == -1 || wcs->m_flag != WCSSET) {
    wcs->m_flag  = 0;
    wcs->m_naxis = 0;
    wcs->m_crpix = 0x0;
    wcs->m_pc    = 0x0;
    wcs->m_cdelt = 0x0;
    wcs->m_crval = 0x0;
    wcs->m_cunit = 0x0;
    wcs->m_ctype = 0x0;
    wcs->m_pv    = 0x0;
    wcs->m_ps    = 0x0;
    wcs->m_cd    = 0x0;
    wcs->m_crota = 0x0;
    wcs->m_colax = 0x0;
    wcs->m_cname = 0x0;
    wcs->m_crder = 0x0;
    wcs->m_csyer = 0x0;
    wcs->m_tab   = 0x0;
    wcs->m_wtb   = 0x0;

    if (wcs->flag == -1) {
      wcs->lin.flag = -1;
    }
  }

  if (wcs->flag == -1) wcs->types = 0x0;


  /* Allocate memory for arrays if required. */
  if (alloc ||
     wcs->crpix == 0x0 ||
     wcs->pc    == 0x0 ||
     wcs->cdelt == 0x0 ||
     wcs->crval == 0x0 ||
     wcs->cunit == 0x0 ||
     wcs->ctype == 0x0 ||
     (NPVMAX && wcs->pv == 0x0) ||
     (NPSMAX && wcs->ps == 0x0) ||
     wcs->cd    == 0x0 ||
     wcs->crota == 0x0 ||
     wcs->colax == 0x0 ||
     wcs->cname == 0x0 ||
     wcs->crder == 0x0 ||
     wcs->csyer == 0x0) {

    /* Was sufficient allocated previously? */
    if (wcs->m_flag == WCSSET &&
       (wcs->m_naxis < naxis  ||
        wcs->npvmax  < NPVMAX ||
        wcs->npsmax  < NPSMAX)) {
      /* No, free it. */
      wcsfree(wcs);
    }


    if (alloc || wcs->crpix == 0x0) {
      if (wcs->m_crpix) {
        /* In case the caller fiddled with it. */
        wcs->crpix = wcs->m_crpix;

      } else {
        if (!(wcs->crpix = calloc(naxis, sizeof(double)))) {
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_crpix = wcs->crpix;
      }
    }

    if (alloc || wcs->pc == 0x0) {
      if (wcs->m_pc) {
        /* In case the caller fiddled with it. */
        wcs->pc = wcs->m_pc;

      } else {
        if (!(wcs->pc = calloc(naxis*naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_pc    = wcs->pc;
      }
    }

    if (alloc || wcs->cdelt == 0x0) {
      if (wcs->m_cdelt) {
        /* In case the caller fiddled with it. */
        wcs->cdelt = wcs->m_cdelt;

      } else {
        if (!(wcs->cdelt = calloc(naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_cdelt = wcs->cdelt;
      }
    }

    if (alloc || wcs->crval == 0x0) {
      if (wcs->m_crval) {
        /* In case the caller fiddled with it. */
        wcs->crval = wcs->m_crval;

      } else {
        if (!(wcs->crval = calloc(naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_crval = wcs->crval;
      }
    }

    if (alloc || wcs->cunit == 0x0) {
      if (wcs->m_cunit) {
        /* In case the caller fiddled with it. */
        wcs->cunit = wcs->m_cunit;

      } else {
        if (!(wcs->cunit = calloc(naxis, sizeof(char [72])))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_cunit = wcs->cunit;
      }
    }

    if (alloc || wcs->ctype == 0x0) {
      if (wcs->m_ctype) {
        /* In case the caller fiddled with it. */
        wcs->ctype = wcs->m_ctype;

      } else {
        if (!(wcs->ctype = calloc(naxis, sizeof(char [72])))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_ctype = wcs->ctype;
      }
    }

    if (alloc || wcs->pv == 0x0) {
      if (wcs->m_pv) {
        /* In case the caller fiddled with it. */
        wcs->pv = wcs->m_pv;

      } else {
        if (NPVMAX) {
          if (!(wcs->pv = calloc(NPVMAX, sizeof(struct pvcard)))) {
            wcsfree(wcs);
            return 2;
          }
        } else {
          wcs->pv = (struct pvcard *)0;
        }

        wcs->npvmax  = NPVMAX;

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_pv    = wcs->pv;
      }
    }

    if (alloc || wcs->ps == 0x0) {
      if (wcs->m_ps) {
        /* In case the caller fiddled with it. */
        wcs->ps = wcs->m_ps;

      } else {
        if (NPSMAX) {
          if (!(wcs->ps = calloc(NPSMAX, sizeof(struct pscard)))) {
            wcsfree(wcs);
            return 2;
          }
        } else {
          wcs->ps = (struct pscard *)0;
        }

        wcs->npsmax  = NPSMAX;

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_ps    = wcs->ps;
      }
    }

    if (alloc || wcs->cd == 0x0) {
      if (wcs->m_cd) {
        /* In case the caller fiddled with it. */
        wcs->cd = wcs->m_cd;

      } else {
        if (!(wcs->cd = calloc(naxis*naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_cd    = wcs->cd;
      }
    }

    if (alloc || wcs->crota == 0x0) {
      if (wcs->m_crota) {
        /* In case the caller fiddled with it. */
        wcs->crota = wcs->m_crota;

      } else {
        if (!(wcs->crota = calloc(naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_crota = wcs->crota;
      }
    }

    if (alloc || wcs->colax == 0x0) {
      if (wcs->m_colax) {
        /* In case the caller fiddled with it. */
        wcs->colax = wcs->m_colax;

      } else {
        if (!(wcs->colax = calloc(naxis, sizeof(int)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_colax = wcs->colax;
      }
    }

    if (alloc || wcs->cname == 0x0) {
      if (wcs->m_cname) {
        /* In case the caller fiddled with it. */
        wcs->cname = wcs->m_cname;

      } else {
        if (!(wcs->cname = calloc(naxis, sizeof(char [72])))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_cname = wcs->cname;
      }
    }

    if (alloc || wcs->crder == 0x0) {
      if (wcs->m_crder) {
        /* In case the caller fiddled with it. */
        wcs->crder = wcs->m_crder;

      } else {
        if (!(wcs->crder = calloc(naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_crder = wcs->crder;
      }
    }

    if (alloc || wcs->csyer == 0x0) {
      if (wcs->m_csyer) {
        /* In case the caller fiddled with it. */
        wcs->csyer = wcs->m_csyer;

      } else {
        if (!(wcs->csyer = calloc(naxis, sizeof(double)))) {
          wcsfree(wcs);
          return 2;
        }

        wcs->m_flag  = WCSSET;
        wcs->m_naxis = naxis;
        wcs->m_csyer = wcs->csyer;
      }
    }
  }


  wcs->flag  = 0;
  wcs->naxis = naxis;


  /* Set defaults for the linear transformation. */
  wcs->lin.crpix  = wcs->crpix;
  wcs->lin.pc     = wcs->pc;
  wcs->lin.cdelt  = wcs->cdelt;
  wcs->lin.m_flag = 0;
  if ((status = linini(0, naxis, &(wcs->lin)))) {
    return status;
  }


  /* CRVALia defaults to 0.0. */
  for (i = 0; i < naxis; i++) {
    wcs->crval[i] = 0.0;
  }


  /* CUNITia and CTYPEia are blank by default. */
  for (i = 0; i < naxis; i++) {
    memset(wcs->cunit[i], 0, 72);
    memset(wcs->ctype[i], 0, 72);
  }


  /* Set defaults for the celestial transformation parameters. */
  wcs->lonpole = UNDEFINED;
  wcs->latpole = +90.0;

  /* Set defaults for the spectral transformation parameters. */
  wcs->restfrq =  0.0;
  wcs->restwav =  0.0;

  /* Default parameter values. */
  wcs->npv = 0;
  for (k = 0; k < wcs->npvmax; k++) {
    wcs->pv[k].i = 0;
    wcs->pv[k].m = 0;
    wcs->pv[k].value = 0.0;
  }

  wcs->nps = 0;
  for (k = 0; k < wcs->npsmax; k++) {
    wcs->ps[k].i = 0;
    wcs->ps[k].m = 0;
    memset(wcs->ps[k].value, 0, 72);
  }

  /* Defaults for alternate linear transformations. */
  cd = wcs->cd;
  for (i = 0; i < naxis; i++) {
    for (j = 0; j < naxis; j++) {
      *(cd++) = 0.0;
    }
  }
  for (i = 0; i < naxis; i++) {
    wcs->crota[i] = 0.0;
  }
  wcs->altlin = 0;
  wcs->velref = 0;

  /* Defaults for auxiliary coordinate system information. */
  memset(wcs->alt, 0, 4);
  wcs->alt[0] = ' ';
  wcs->colnum = 0;

  memset(wcs->wcsname, 0, 72);
  for (i = 0; i < naxis; i++) {
    wcs->colax[i] = 0;
    memset(wcs->cname[i], 0, 72);
    wcs->crder[i] = UNDEFINED;
    wcs->csyer[i] = UNDEFINED;
  }
  memset(wcs->radesys, 0, 72);
  wcs->equinox    = UNDEFINED;
  memset(wcs->specsys, 0, 72);
  memset(wcs->ssysobs, 0, 72);
  wcs->velosys    = UNDEFINED;
  memset(wcs->ssyssrc, 0, 72);
  wcs->zsource    = UNDEFINED;
  wcs->obsgeo[0]  = UNDEFINED;
  wcs->obsgeo[1]  = UNDEFINED;
  wcs->obsgeo[2]  = UNDEFINED;
  memset(wcs->dateobs, 0, 72);
  memset(wcs->dateavg, 0, 72);
  wcs->mjdobs     = UNDEFINED;
  wcs->mjdavg     = UNDEFINED;

  wcs->ntab = 0;
  wcs->tab  = 0x0;
  wcs->nwtb = 0;
  wcs->wtb  = 0x0;

  /* Reset derived values. */
  strcpy(wcs->lngtyp, "    ");
  strcpy(wcs->lattyp, "    ");
  wcs->lng  = -1;
  wcs->lat  = -1;
  wcs->spec = -1;
  wcs->cubeface = -1;

  celini(&(wcs->cel));
  spcini(&(wcs->spc));

  return 0;
}

/*--------------------------------------------------------------------------*/

int wcssub(
  int alloc,
  const struct wcsprm *wcssrc,
  int *nsub,
  int axes[],
  struct wcsprm *wcsdst)

{
  char *c, ctypei[16];
  int  axis, cubeface, dealloc, dummy, i, itab, j, k, latitude, longitude, m,
       *map = 0x0, msub, naxis, npv, nps, other, spectral, status, stokes;
  const double *srcp;
  double *dstp;
  struct tabprm *tabp;

  if (wcssrc == 0x0) return 1;

  if ((naxis = wcssrc->naxis) <= 0) {
    return 2;
  }

  if (!(map = calloc(naxis, sizeof(int)))) {
    return 2;
  }

  if (nsub == 0x0) {
    nsub = &dummy;
    *nsub = naxis;
  } else if (*nsub == 0) {
    *nsub = naxis;
  }

  if ((dealloc = (axes == 0x0))) {
    /* Construct an index array. */
    if (!(axes = calloc(naxis, sizeof(int)))) {
      free(map);
      return 2;
    }

    for (i = 0; i < naxis; i++) {
      axes[i] = i+1;
    }
  }


  msub = 0;
  for (j = 0; j < *nsub; j++) {
    axis = axes[j];

    if (abs(axis) > 0x1000) {
      /* Subimage extraction by type. */
      k = abs(axis) & 0xFF;

      longitude = k & WCSSUB_LONGITUDE;
      latitude  = k & WCSSUB_LATITUDE;
      cubeface  = k & WCSSUB_CUBEFACE;
      spectral  = k & WCSSUB_SPECTRAL;
      stokes    = k & WCSSUB_STOKES;

      if ((other = (axis < 0))) {
        longitude = !longitude;
        latitude  = !latitude;
        cubeface  = !cubeface;
        spectral  = !spectral;
        stokes    = !stokes;
      }

      for (i = 0; i < naxis; i++) {
        strncpy (ctypei, (char *)(wcssrc->ctype + i), 8);
        ctypei[8] = '\0';

        /* Find the last non-blank character. */
        c = ctypei + 8;
        while (c-- > ctypei) {
          if (*c == ' ') *c = '\0';
          if (*c != '\0') break;
        }

        if (
          strcmp(ctypei,   "RA")  == 0 ||
          strcmp(ctypei+1, "LON") == 0 ||
          strcmp(ctypei+2, "LN")  == 0 ||
          strncmp(ctypei,   "RA---", 5) == 0 ||
          strncmp(ctypei+1, "LON-", 4) == 0 ||
          strncmp(ctypei+2, "LN-", 3) == 0) {
          if (!longitude) {
            continue;
          }

        } else if (
          strcmp(ctypei,   "DEC") == 0 ||
          strcmp(ctypei+1, "LAT") == 0 ||
          strcmp(ctypei+2, "LT")  == 0 ||
          strncmp(ctypei,   "DEC--", 5) == 0 ||
          strncmp(ctypei+1, "LAT-", 4) == 0 ||
          strncmp(ctypei+2, "LT-", 3) == 0) {
          if (!latitude) {
            continue;
          }

        } else if (strcmp(ctypei, "CUBEFACE") == 0) {
          if (!cubeface) {
            continue;
          }

        } else if ((
          strncmp(ctypei, "FREQ", 4) == 0 ||
          strncmp(ctypei, "ENER", 4) == 0 ||
          strncmp(ctypei, "WAVN", 4) == 0 ||
          strncmp(ctypei, "VRAD", 4) == 0 ||
          strncmp(ctypei, "WAVE", 4) == 0 ||
          strncmp(ctypei, "VOPT", 4) == 0 ||
          strncmp(ctypei, "ZOPT", 4) == 0 ||
          strncmp(ctypei, "AWAV", 4) == 0 ||
          strncmp(ctypei, "VELO", 4) == 0 ||
          strncmp(ctypei, "BETA", 4) == 0) &&
          (ctypei[4] == '\0' || ctypei[4] == '-')) {
          if (!spectral) {
            continue;
          }

        } else if (strcmp(ctypei, "STOKES") == 0) {
          if (!stokes) {
            continue;
          }

        } else if (!other) {
          continue;
        }

        /* This axis is wanted, but has it already been added? */
        for (k = 0; k < msub; k++) {
          if (map[k] == i+1) {
            break;
          }
        }
        if (k == msub) map[msub++] = i+1;
      }

    } else if (0 < axis && axis <= naxis) {
      /* Check that the requested axis has not already been added. */
      for (k = 0; k < msub; k++) {
        if (map[k] == axis) {
          break;
        }
      }
      if (k == msub) map[msub++] = axis;

    } else {
      status = 12;
      goto cleanup;
    }
  }

  if ((*nsub = msub) == 0) {
    status = 0;
    goto cleanup;
  }

  for (i = 0; i < *nsub; i++) {
    axes[i] = map[i];
  }


  /* Construct the inverse axis map. */
  for (i = 0; i < naxis; i++) {
    map[i] = 0;
  }

  for (i = 0; i < *nsub; i++) {
    map[axes[i]-1] = i+1;
  }

  /* Check that the subimage coordinate system is separable. */
  if (*nsub < naxis) {
    srcp = wcssrc->pc;
    for (i = 0; i < naxis; i++) {
      for (j = 0; j < naxis; j++) {
        if (*(srcp++) == 0.0 || j == i) continue;

        if ((map[i] == 0) != (map[j] == 0)) {
          status = 13;
          goto cleanup;
        }
      }
    }
  }


  /* Initialize the destination. */
  npv = NPVMAX;
  nps = NPSMAX;

  NPVMAX = 0;
  for (k = 0; k < wcssrc->npv; k++) {
    i = wcssrc->pv[k].i;
    if (i == 0 || (i > 0 && map[i-1])) {
      NPVMAX++;
    }
  }

  NPSMAX = 0;
  for (k = 0; k < wcssrc->nps; k++) {
    i = wcssrc->ps[k].i;
    if (i > 0 && map[i-1]) {
      NPSMAX++;
    }
  }

  status = wcsini(alloc, *nsub, wcsdst);

  NPVMAX = npv;
  NPSMAX = nps;

  if (status) {
    goto cleanup;
  }


  /* Linear transformation. */
  srcp = wcssrc->crpix;
  dstp = wcsdst->crpix;
  for (j = 0; j < *nsub; j++) {
    k = axes[j] - 1;
    *(dstp++) = *(srcp+k);
  }

  srcp = wcssrc->pc;
  dstp = wcsdst->pc;
  for (i = 0; i < *nsub; i++) {
    for (j = 0; j < *nsub; j++) {
      k = (axes[i]-1)*naxis + (axes[j]-1);
      *(dstp++) = *(srcp+k);
    }
  }

  srcp = wcssrc->cdelt;
  dstp = wcsdst->cdelt;
  for (i = 0; i < *nsub; i++) {
    k = axes[i] - 1;
    *(dstp++) = *(srcp+k);
  }

  /* Coordinate reference value. */
  srcp = wcssrc->crval;
  dstp = wcsdst->crval;
  for (i = 0; i < *nsub; i++) {
    k = axes[i] - 1;
    *(dstp++) = *(srcp+k);
  }

  /* Coordinate units and type. */
  for (i = 0; i < *nsub; i++) {
    k = axes[i] - 1;
    strncpy(wcsdst->cunit[i], wcssrc->cunit[k], 72);
    strncpy(wcsdst->ctype[i], wcssrc->ctype[k], 72);
  }

  /* Celestial and spectral transformation parameters. */
  wcsdst->lonpole = wcssrc->lonpole;
  wcsdst->latpole = wcssrc->latpole;
  wcsdst->restfrq = wcssrc->restfrq;
  wcsdst->restwav = wcssrc->restwav;

  /* Parameter values. */
  npv = 0;
  for (k = 0; k < wcssrc->npv; k++) {
    i = wcssrc->pv[k].i;
    if (i == 0 || (i > 0 && map[i-1])) {
      /* i == 0 is a special code for the latitude axis. */
      wcsdst->pv[npv] = wcssrc->pv[k];
      wcsdst->pv[npv].i = map[i-1];
      npv++;
    }
  }
  wcsdst->npv = npv;

  nps = 0;
  for (k = 0; k < wcssrc->nps; k++) {
    i = wcssrc->ps[k].i;
    if (i > 0 && map[i-1]) {
      wcsdst->ps[nps] = wcssrc->ps[k];
      wcsdst->ps[nps].i = map[i-1];
      nps++;
    }
  }
  wcsdst->nps = nps;

  /* Alternate linear transformations. */
  srcp = wcssrc->cd;
  dstp = wcsdst->cd;
  for (i = 0; i < *nsub; i++) {
    for (j = 0; j < *nsub; j++) {
      k = (axes[i]-1)*naxis + (axes[j]-1);
      *(dstp++) = *(srcp+k);
    }
  }

  srcp = wcssrc->crota;
  dstp = wcsdst->crota;
  for (i = 0; i < *nsub; i++) {
    k = axes[i] - 1;
    *(dstp++) = *(srcp+k);
  }

  wcsdst->altlin = wcssrc->altlin;
  wcsdst->velref = wcssrc->velref;

  /* Auxiliary coordinate system information. */
  strncpy(wcsdst->alt, wcssrc->alt, 4);
  wcsdst->colnum = wcssrc->colnum;

  strncpy(wcsdst->wcsname, wcssrc->wcsname, 72);
  for (i = 0; i < *nsub; i++) {
    k = axes[i] - 1;
    wcsdst->colax[i] = wcssrc->colax[k];
    strncpy(wcsdst->cname[i], wcssrc->cname[k], 72);
    wcsdst->crder[i] = wcssrc->crder[k];
    wcsdst->csyer[i] = wcssrc->csyer[k];
  }

  strncpy(wcsdst->radesys, wcssrc->radesys, 72);
  wcsdst->equinox = wcssrc->equinox;

  strncpy(wcsdst->specsys, wcssrc->specsys, 72);
  strncpy(wcsdst->ssysobs, wcssrc->ssysobs, 72);
  wcsdst->velosys = wcssrc->velosys;
  strncpy(wcsdst->ssyssrc, wcssrc->ssyssrc, 72);
  wcsdst->zsource = wcssrc->zsource;

  wcsdst->obsgeo[0] = wcssrc->obsgeo[0];
  wcsdst->obsgeo[1] = wcssrc->obsgeo[1];
  wcsdst->obsgeo[2] = wcssrc->obsgeo[2];

  strncpy(wcsdst->dateobs, wcssrc->dateobs, 72);
  strncpy(wcsdst->dateavg, wcssrc->dateavg, 72);
  wcsdst->mjdobs = wcssrc->mjdobs;
  wcsdst->mjdavg = wcssrc->mjdavg;


  /* Coordinate lookup tables; only copy what's needed. */
  wcsdst->ntab = 0;
  for (itab = 0; itab < wcssrc->ntab; itab++) {
    /* Is this table wanted? */
    for (m = 0; m < wcssrc->tab[itab].M; m++) {
      i = wcssrc->tab[itab].map[m];

      if (map[i-1]) {
        wcsdst->ntab++;
        break;
      }
    }
  }

  if (wcsdst->ntab) {
    /* Allocate memory for tabprm structs. */
    if (!(wcsdst->tab = calloc(wcsdst->ntab, sizeof(struct tabprm)))) {
      wcsdst->ntab = 0;

      status = 2;
      goto cleanup;
    }

    wcsdst->m_tab = wcsdst->tab;
  }

  tabp = wcsdst->tab;
  for (itab = 0; itab < wcssrc->ntab; itab++) {
    for (m = 0; m < wcssrc->tab[itab].M; m++) {
      i = wcssrc->tab[itab].map[m];

      if (map[i-1]) {
        if ((status = tabcpy(1, wcssrc->tab + itab, tabp))) {
          goto cleanup;
        }

        tabp++;
        break;
      }
    }
  }


cleanup:
  if (map) free(map);
  if (dealloc) {
    free(axes);
  }

  if (status && wcsdst->m_tab) free(wcsdst->m_tab);

  return status;
}

/*--------------------------------------------------------------------------*/

int wcsfree(struct wcsprm *wcs)

{
  int j;

  if (wcs == 0x0) return 1;

  if (wcs->flag == -1) {
    wcs->lin.flag = -1;

  } else {
    /* Free memory allocated by wcsini(). */
    if (wcs->m_flag == WCSSET) {
      if (wcs->crpix == wcs->m_crpix) wcs->crpix = 0x0;
      if (wcs->pc    == wcs->m_pc)    wcs->pc    = 0x0;
      if (wcs->cdelt == wcs->m_cdelt) wcs->cdelt = 0x0;
      if (wcs->crval == wcs->m_crval) wcs->crval = 0x0;
      if (wcs->cunit == wcs->m_cunit) wcs->cunit = 0x0;
      if (wcs->ctype == wcs->m_ctype) wcs->ctype = 0x0;
      if (wcs->pv    == wcs->m_pv)    wcs->pv    = 0x0;
      if (wcs->ps    == wcs->m_ps)    wcs->ps    = 0x0;
      if (wcs->cd    == wcs->m_cd)    wcs->cd    = 0x0;
      if (wcs->crota == wcs->m_crota) wcs->crota = 0x0;
      if (wcs->colax == wcs->m_colax) wcs->colax = 0x0;
      if (wcs->cname == wcs->m_cname) wcs->cname = 0x0;
      if (wcs->crder == wcs->m_crder) wcs->crder = 0x0;
      if (wcs->csyer == wcs->m_csyer) wcs->csyer = 0x0;
      if (wcs->tab   == wcs->m_tab)   wcs->tab   = 0x0;
      if (wcs->wtb   == wcs->m_wtb)   wcs->wtb   = 0x0;

      if (wcs->m_crpix)  free(wcs->m_crpix);
      if (wcs->m_pc)     free(wcs->m_pc);
      if (wcs->m_cdelt)  free(wcs->m_cdelt);
      if (wcs->m_crval)  free(wcs->m_crval);
      if (wcs->m_cunit)  free(wcs->m_cunit);
      if (wcs->m_ctype)  free(wcs->m_ctype);
      if (wcs->m_pv)     free(wcs->m_pv);
      if (wcs->m_ps)     free(wcs->m_ps);
      if (wcs->m_cd)     free(wcs->m_cd);
      if (wcs->m_crota)  free(wcs->m_crota);
      if (wcs->m_colax)  free(wcs->m_colax);
      if (wcs->m_cname)  free(wcs->m_cname);
      if (wcs->m_crder)  free(wcs->m_crder);
      if (wcs->m_csyer)  free(wcs->m_csyer);

      /* Free memory allocated by wcstab(). */
      if (wcs->m_tab) {
        for (j = 0; j < wcs->ntab; j++) {
          tabfree(wcs->m_tab + j);
        }

        free(wcs->m_tab);
      }
      if (wcs->m_wtb) free(wcs->m_wtb);
    }

    /* Free memory allocated by wcsset(). */
    if (wcs->types) free(wcs->types);

    if (wcs->lin.crpix == wcs->m_crpix) wcs->lin.crpix = 0x0;
    if (wcs->lin.pc    == wcs->m_pc)    wcs->lin.pc    = 0x0;
    if (wcs->lin.cdelt == wcs->m_cdelt) wcs->lin.cdelt = 0x0;
  }

  wcs->m_flag   = 0;
  wcs->m_naxis  = 0x0;
  wcs->m_crpix  = 0x0;
  wcs->m_pc     = 0x0;
  wcs->m_cdelt  = 0x0;
  wcs->m_crval  = 0x0;
  wcs->m_cunit  = 0x0;
  wcs->m_ctype  = 0x0;
  wcs->m_pv     = 0x0;
  wcs->m_ps     = 0x0;
  wcs->m_cd     = 0x0;
  wcs->m_crota  = 0x0;
  wcs->m_colax  = 0x0;
  wcs->m_cname  = 0x0;
  wcs->m_crder  = 0x0;
  wcs->m_csyer  = 0x0;

  wcs->ntab  = 0;
  wcs->m_tab = 0x0;
  wcs->nwtb  = 0;
  wcs->m_wtb = 0x0;

  wcs->types = 0x0;

  wcs->flag = 0;

  return linfree(&(wcs->lin));
}

/*--------------------------------------------------------------------------*/

int wcsprt(const struct wcsprm *wcs)

{
  int i, j, k;
  struct wtbarr *wtbp;

  if (wcs == 0x0) return 1;

  if (wcs->flag != WCSSET) {
    printf("The wcsprm struct is UNINITIALIZED.\n");
    return 0;
  }

  printf("       flag: %d\n", wcs->flag);
  printf("      naxis: %d\n", wcs->naxis);
  printf("      crpix: %p\n", (void *)wcs->crpix);
  printf("            ");
  for (i = 0; i < wcs->naxis; i++) {
    printf("  %- 11.5g", wcs->crpix[i]);
  }
  printf("\n");

  /* Linear transformation. */
  k = 0;
  printf("         pc: %p\n", (void *)wcs->pc);
  for (i = 0; i < wcs->naxis; i++) {
    printf("    pc[%d][]:", i);
    for (j = 0; j < wcs->naxis; j++) {
      printf("  %- 11.5g", wcs->pc[k++]);
    }
    printf("\n");
  }

  /* Coordinate increment at reference point. */
  printf("      cdelt: %p\n", (void *)wcs->cdelt);
  printf("            ");
  for (i = 0; i < wcs->naxis; i++) {
    printf("  %- 11.5g", wcs->cdelt[i]);
  }
  printf("\n");

  /* Coordinate value at reference point. */
  printf("      crval: %p\n", (void *)wcs->crval);
  printf("            ");
  for (i = 0; i < wcs->naxis; i++) {
    printf("  %- 11.5g", wcs->crval[i]);
  }
  printf("\n");

  /* Coordinate units and type. */
  printf("      cunit: %p\n", (void *)wcs->cunit);
  for (i = 0; i < wcs->naxis; i++) {
    printf("             \"%s\"\n", wcs->cunit[i]);
  }

  printf("      ctype: %p\n", (void *)wcs->ctype);
  for (i = 0; i < wcs->naxis; i++) {
    printf("             \"%s\"\n", wcs->ctype[i]);
  }

  /* Celestial and spectral transformation parameters. */
  if (undefined(wcs->lonpole)) {
    printf("    lonpole: UNDEFINED\n");
  } else {
    printf("    lonpole: %9f\n", wcs->lonpole);
  }
  printf("    latpole: %9f\n", wcs->latpole);
  printf("    restfrq: %f\n", wcs->restfrq);
  printf("    restwav: %f\n", wcs->restwav);

  /* Parameter values. */
  printf("        npv: %d\n", wcs->npv);
  printf("     npvmax: %d\n", wcs->npvmax);
  printf("         pv: %p\n", (void *)wcs->pv);
  for (i = 0; i < wcs->npv; i++) {
    printf("             %3d%4d  %- 11.5g\n", (wcs->pv[i]).i,
      (wcs->pv[i]).m, (wcs->pv[i]).value);
  }
  printf("        nps: %d\n", wcs->nps);
  printf("     npsmax: %d\n", wcs->npsmax);
  printf("         ps: %p\n", (void *)wcs->ps);
  for (i = 0; i < wcs->nps; i++) {
    printf("             %3d%4d  %s\n", (wcs->ps[i]).i,
      (wcs->ps[i]).m, (wcs->ps[i]).value);
  }

  /* Alternate linear transformations. */
  k = 0;
  printf("         cd: %p\n", (void *)wcs->cd);
  if (wcs->cd) {
    for (i = 0; i < wcs->naxis; i++) {
      printf("    cd[%d][]:", i);
      for (j = 0; j < wcs->naxis; j++) {
        printf("  %- 11.5g", wcs->cd[k++]);
      }
      printf("\n");
    }
  }

  printf("      crota: %p\n", (void *)wcs->crota);
  if (wcs->crota) {
    printf("            ");
    for (i = 0; i < wcs->naxis; i++) {
      printf("  %- 11.5g", wcs->crota[i]);
    }
    printf("\n");
  }

  printf("     altlin: %d\n", wcs->altlin);
  printf("     velref: %d\n", wcs->velref);



  /* Auxiliary coordinate system information. */
  printf("        alt: '%c'\n", wcs->alt[0]);
  printf("     colnum: %d\n", wcs->colnum);

  printf("      colax: %p\n", (void *)wcs->colax);
  if (wcs->colax) {
    printf("           ");
    for (i = 0; i < wcs->naxis; i++) {
      printf("  %5d", wcs->colax[i]);
    }
    printf("\n");
  }

  if (wcs->wcsname[0] == '\0') {
    printf("    wcsname: UNDEFINED\n");
  } else {
    printf("    wcsname: \"%s\"\n", wcs->wcsname);
  }

  printf("      cname: %p\n", (void *)wcs->cname);
  if (wcs->cname) {
    for (i = 0; i < wcs->naxis; i++) {
      if (wcs->cname[i][0] == '\0') {
        printf("             UNDEFINED\n");
      } else {
        printf("             \"%s\"\n", wcs->cname[i]);
      }
    }
  }

  printf("      crder: %p\n", (void *)wcs->crder);
  if (wcs->crder) {
    printf("           ");
    for (i = 0; i < wcs->naxis; i++) {
      if (undefined(wcs->crder[i])) {
        printf("  UNDEFINED   ");
      } else {
        printf("  %- 11.5g", wcs->crder[i]);
      }
    }
    printf("\n");
  }

  printf("      csyer: %p\n", (void *)wcs->csyer);
  if (wcs->csyer) {
    printf("           ");
    for (i = 0; i < wcs->naxis; i++) {
      if (undefined(wcs->csyer[i])) {
        printf("  UNDEFINED   ");
      } else {
        printf("  %- 11.5g", wcs->csyer[i]);
      }
    }
    printf("\n");
  }

  if (wcs->radesys[0] == '\0') {
    printf("    radesys: UNDEFINED\n");
  } else {
    printf("    radesys: \"%s\"\n", wcs->radesys);
  }

  if (undefined(wcs->equinox)) {
    printf("    equinox: UNDEFINED\n");
  } else {
    printf("    equinox: %9f\n", wcs->equinox);
  }

  if (wcs->specsys[0] == '\0') {
    printf("    specsys: UNDEFINED\n");
  } else {
    printf("    specsys: \"%s\"\n", wcs->specsys);
  }

  if (wcs->ssysobs[0] == '\0') {
    printf("    ssysobs: UNDEFINED\n");
  } else {
    printf("    ssysobs: \"%s\"\n", wcs->ssysobs);
  }

  if (undefined(wcs->velosys)) {
    printf("    velosys: UNDEFINED\n");
  } else {
    printf("    velosys: %9f\n", wcs->velosys);
  }

  if (wcs->ssyssrc[0] == '\0') {
    printf("    ssyssrc: UNDEFINED\n");
  } else {
    printf("    ssyssrc: \"%s\"\n", wcs->ssyssrc);
  }

  if (undefined(wcs->zsource)) {
    printf("    zsource: UNDEFINED\n");
  } else {
    printf("    zsource: %9f\n", wcs->zsource);
  }

  printf("     obsgeo: ");
  for (i = 0; i < 3; i++) {
    if (undefined(wcs->obsgeo[i])) {
      printf("UNDEFINED     ");
    } else {
      printf("%- 11.5g  ", wcs->obsgeo[i]);
    }
  }
  printf("\n");

  if (wcs->dateobs[0] == '\0') {
    printf("    dateobs: UNDEFINED\n");
  } else {
    printf("    dateobs: \"%s\"\n", wcs->dateobs);
  }

  if (wcs->dateavg[0] == '\0') {
    printf("    dateavg: UNDEFINED\n");
  } else {
    printf("    dateavg: \"%s\"\n", wcs->dateavg);
  }

  if (undefined(wcs->mjdobs)) {
    printf("     mjdobs: UNDEFINED\n");
  } else {
    printf("     mjdobs: %9f\n", wcs->mjdobs);
  }

  if (undefined(wcs->mjdavg)) {
    printf("     mjdavg: UNDEFINED\n");
  } else {
    printf("     mjdavg: %9f\n", wcs->mjdavg);
  }

  printf("       ntab: %d\n", wcs->ntab);
  printf("        tab: %p", (void *)wcs->tab);
  if (wcs->tab != 0x0) printf("  (see below)");
  printf("\n");
  printf("       nwtb: %d\n", wcs->nwtb);
  printf("        wtb: %p", (void *)wcs->wtb);
  if (wcs->wtb != 0x0) printf("  (see below)");
  printf("\n");

  /* Derived values. */
  printf("      types: %p\n           ", (void *)wcs->types);
  for (i = 0; i < wcs->naxis; i++) {
    printf("%5d", wcs->types[i]);
  }
  printf("\n");

  printf("     lngtyp: \"%s\"\n", wcs->lngtyp);
  printf("     lattyp: \"%s\"\n", wcs->lattyp);
  printf("        lng: %d\n", wcs->lng);
  printf("        lat: %d\n", wcs->lat);
  printf("       spec: %d\n", wcs->spec);
  printf("   cubeface: %d\n", wcs->cubeface);

  printf("        lin: (see below)\n");
  printf("        cel: (see below)\n");
  printf("        spc: (see below)\n");

  /* Memory management. */
  printf("     m_flag: %d\n", wcs->m_flag);
  printf("    m_naxis: %d\n", wcs->m_naxis);
  printf("    m_crpix: %p", (void *)wcs->m_crpix);
  if (wcs->m_crpix == wcs->crpix) printf("  (= crpix)");
  printf("\n");
  printf("       m_pc: %p", (void *)wcs->m_pc);
  if (wcs->m_pc == wcs->pc) printf("  (= pc)");
  printf("\n");
  printf("    m_cdelt: %p", (void *)wcs->m_cdelt);
  if (wcs->m_cdelt == wcs->cdelt) printf("  (= cdelt)");
  printf("\n");
  printf("    m_crval: %p", (void *)wcs->m_crval);
  if (wcs->m_crval == wcs->crval) printf("  (= crval)");
  printf("\n");
  printf("    m_cunit: %p", (void *)wcs->m_cunit);
  if (wcs->m_cunit == wcs->cunit) printf("  (= cunit)");
  printf("\n");
  printf("    m_ctype: %p", (void *)wcs->m_ctype);
  if (wcs->m_ctype == wcs->ctype) printf("  (= ctype)");
  printf("\n");
  printf("       m_pv: %p", (void *)wcs->m_pv);
  if (wcs->m_pv == wcs->pv) printf("  (= pv)");
  printf("\n");
  printf("       m_ps: %p", (void *)wcs->m_ps);
  if (wcs->m_ps == wcs->ps) printf("  (= ps)");
  printf("\n");
  printf("       m_cd: %p", (void *)wcs->m_cd);
  if (wcs->m_cd == wcs->cd) printf("  (= cd)");
  printf("\n");
  printf("    m_crota: %p", (void *)wcs->m_crota);
  if (wcs->m_crota == wcs->crota) printf("  (= crota)");
  printf("\n");
  printf("\n");
  printf("    m_colax: %p", (void *)wcs->m_colax);
  if (wcs->m_colax == wcs->colax) printf("  (= colax)");
  printf("\n");
  printf("    m_cname: %p", (void *)wcs->m_cname);
  if (wcs->m_cname == wcs->cname) printf("  (= cname)");
  printf("\n");
  printf("    m_crder: %p", (void *)wcs->m_crder);
  if (wcs->m_crder == wcs->crder) printf("  (= crder)");
  printf("\n");
  printf("    m_csyer: %p", (void *)wcs->m_csyer);
  if (wcs->m_csyer == wcs->csyer) printf("  (= csyer)");
  printf("\n");
  printf("      m_tab: %p", (void *)wcs->m_tab);
  if (wcs->m_tab == wcs->tab) printf("  (= tab)");
  printf("\n");
  printf("      m_wtb: %p", (void *)wcs->m_wtb);
  if (wcs->m_wtb == wcs->wtb) printf("  (= wtb)");
  printf("\n");

  /* Tabular transformation parameters. */
  if ((wtbp = wcs->wtb)) {
    for (j = 0; j < wcs->nwtb; j++, wtbp++) {
      printf("\n");
      printf("wtb[%d].*\n", j);
      printf("          i: %d\n", wtbp->i);
      printf("          m: %d\n", wtbp->m);
      printf("       kind: %c\n", wtbp->kind);
      printf("     extnam: %s\n", wtbp->extnam);
      printf("     extver: %d\n", wtbp->extver);
      printf("     extlev: %d\n", wtbp->extlev);
      printf("      ttype: %s\n", wtbp->ttype);
      printf("        row: %ld\n", wtbp->row);
      printf("       ndim: %d\n", wtbp->ndim);
      printf("     dimlen: %p\n", (void *)wtbp->dimlen);
      printf("     arrayp: %p -> %p\n", (void *)wtbp->arrayp,
                                        (void *)(*(wtbp->arrayp)));
    }
  }

  if (wcs->tab) {
    for (j = 0; j < wcs->ntab; j++) {
      printf("\n");
      printf("tab[%d].*\n", j);
      tabprt(wcs->tab + j);
    }
  }

  /* Linear transformation parameters. */
  printf("\n");
  printf("   lin.*\n");
  linprt(&(wcs->lin));

  /* Celestial transformation parameters. */
  printf("\n");
  printf("   cel.*\n");
  celprt(&(wcs->cel));

  /* Spectral transformation parameters. */
  printf("\n");
  printf("   spc.*\n");
  spcprt(&(wcs->spc));

  return 0;
}

/*--------------------------------------------------------------------------*/

int wcsset(struct wcsprm *wcs)

{
  char scode[4], stype[5];
  int i, j, k, m, naxis, status;
  double lambda, rho;
  double *cd, *pc;
  struct celprm *wcscel = &(wcs->cel);
  struct prjprm *wcsprj = &(wcscel->prj);
  struct spcprm *wcsspc = &(wcs->spc);


  /* Determine axis types from CTYPEia. */
  if (wcs == 0x0) return 1;
  if ((status = wcs_types(wcs))) {
    return status;
  }

  /* Convert to canonical units. */
  if ((status = wcs_units(wcs))) {
    return status;
  }


  /* Non-linear celestial axes present? */
  if (wcs->lng >= 0 && wcs->types[wcs->lng] == 2200) {
    celini(wcscel);

    /* CRVALia, LONPOLEa, and LATPOLEa keyvalues. */
    wcscel->ref[0] = wcs->crval[wcs->lng];
    wcscel->ref[1] = wcs->crval[wcs->lat];
    wcscel->ref[2] = wcs->lonpole;
    wcscel->ref[3] = wcs->latpole;

    /* PVi_ma keyvalues. */
    for (k = 0; k < wcs->npv; k++) {
      i = wcs->pv[k].i - 1;
      m = wcs->pv[k].m;

      if (i == -1) {
        /* From a PROJPn keyword. */
        i = wcs->lat;
      }

      if (i == wcs->lat) {
        /* PVi_ma associated with latitude axis. */
        if (m < 30) {
          wcsprj->pv[m] = wcs->pv[k].value;
        }

      } else if (i == wcs->lng) {
        /* PVi_ma associated with longitude axis. */
        switch (m) {
        case 0:
          wcscel->offset = (wcs->pv[k].value != 0.0);
          break;
        case 1:
          wcscel->phi0   = wcs->pv[k].value;
          break;
        case 2:
          wcscel->theta0 = wcs->pv[k].value;
          break;
        case 3:
          /* If present, overrides LONPOLEa. */
          wcscel->ref[2] = wcs->pv[k].value;
          break;
        case 4:
          /* If present, overrides LATPOLEa. */
          wcscel->ref[3] = wcs->pv[k].value;
          break;
        default:
          return 6;
          break;
        }
      }
    }

    /* Do simple alias translations. */
    if (strncmp(wcs->ctype[wcs->lng]+5, "GLS", 3) == 0) {
      wcscel->offset = 1;
      wcscel->phi0   = wcs->crval[wcs->lng];
      wcscel->theta0 = wcs->crval[wcs->lat];
      strcpy(wcsprj->code, "SFL");

    } else if (strncmp(wcs->ctype[wcs->lng]+5, "NCP", 3) == 0) {
      /* Convert NCP to SIN. */
      if (wcscel->ref[1] == 0.0) {
        return 5;
      }

      strcpy(wcsprj->code, "SIN");
      wcsprj->pv[1] = 0.0;
      wcsprj->pv[2] = cosd(wcscel->ref[1])/sind(wcscel->ref[1]);

    } else {
      strncpy(wcsprj->code, wcs->ctype[wcs->lng]+5, 3);
      wcsprj->code[3] = '\0';
    }

    /* Initialize the celestial transformation routines. */
    wcsprj->r0 = 0.0;
    if ((status = celset(wcscel))) {
      return status + 3;
    }

    /* Update LONPOLE, LATPOLE, and PVi_ma keyvalues. */
    wcs->lonpole = wcscel->ref[2];
    wcs->latpole = wcscel->ref[3];

    for (k = 0; k < wcs->npv; k++) {
      i = wcs->pv[k].i - 1;
      m = wcs->pv[k].m;

      if (i == wcs->lng) {
        switch (m) {
        case 1:
          wcs->pv[k].value = wcscel->phi0;
          break;
        case 2:
          wcs->pv[k].value = wcscel->theta0;
          break;
        case 3:
          wcs->pv[k].value = wcscel->ref[2];
          break;
        case 4:
          wcs->pv[k].value = wcscel->ref[3];
          break;
        }
      }
    }
  }


  /* Non-linear spectral axis present? */
  if (wcs->spec >= 0 && wcs->types[wcs->spec] == 3300) {
    spcini(wcsspc);
    spctyp(wcs->ctype[wcs->spec], stype, scode, 0x0, 0x0, 0x0, 0x0, 0x0);
    strcpy(wcsspc->type, stype);
    strcpy(wcsspc->code, scode);

    /* CRVALia, RESTFRQa, and RESTWAVa keyvalues. */
    wcsspc->crval = wcs->crval[wcs->spec];
    wcsspc->restfrq = wcs->restfrq;
    wcsspc->restwav = wcs->restwav;

    /* PVi_ma keyvalues. */
    for (k = 0; k < wcs->npv; k++) {
      i = wcs->pv[k].i - 1;
      m = wcs->pv[k].m;

      if (i == wcs->spec) {
        /* PVi_ma associated with grism axis. */
        if (m < 7) {
          wcsspc->pv[m] = wcs->pv[k].value;
        }
      }
    }

    /* Initialize the spectral transformation routines. */
    if ((status = spcset(wcsspc))) {
      return status + 3;
    }
  }


  /* Tabular axes present? */
  for (j = 0; j < wcs->ntab; j++) {
    if ((status = tabset(wcs->tab + j))) {
      return status + 3;
    }
  }


  /* Initialize the linear transformation. */
  naxis = wcs->naxis;
  wcs->altlin &= 7;
  if (wcs->altlin > 1 && !(wcs->altlin & 1)) {
    pc = wcs->pc;

    if (wcs->altlin & 2) {
      /* Copy CDi_ja to PCi_ja and reset CDELTia. */
      cd = wcs->cd;
      for (i = 0; i < naxis; i++) {
        for (j = 0; j < naxis; j++) {
          *(pc++) = *(cd++);
        }
        wcs->cdelt[i] = 1.0;
      }

    } else if (wcs->altlin & 4) {
      /* Construct PCi_ja from CROTAia. */
      if ((i = wcs->lng) >= 0 && (j = wcs->lat) >= 0) {
        rho = wcs->crota[j];

        if (wcs->cdelt[i] == 0.0) return 3;
        lambda = wcs->cdelt[j]/wcs->cdelt[i];

        *(pc + i*naxis + i) = *(pc + j*naxis + j) = cosd(rho);
        *(pc + i*naxis + j) = *(pc + j*naxis + i) = sind(rho);
        *(pc + i*naxis + j) *= -lambda;
        *(pc + j*naxis + i) /=  lambda;
      }
    }
  }

  wcs->lin.crpix  = wcs->crpix;
  wcs->lin.pc     = wcs->pc;
  wcs->lin.cdelt  = wcs->cdelt;
  if ((status = linset(&(wcs->lin)))) {
    return status;
  }


  /* Strip off trailing blanks and null-fill auxiliary string members. */
  wcsutil_null_fill(4, wcs->alt);
  wcsutil_null_fill(72, wcs->wcsname);
  for (i = 0; i < naxis; i++) {
    wcsutil_null_fill(72, wcs->cname[i]);
  }
  wcsutil_null_fill(72, wcs->radesys);
  wcsutil_null_fill(72, wcs->specsys);
  wcsutil_null_fill(72, wcs->ssysobs);
  wcsutil_null_fill(72, wcs->ssyssrc);
  wcsutil_null_fill(72, wcs->dateobs);
  wcsutil_null_fill(72, wcs->dateavg);

  wcs->flag = WCSSET;

  return 0;
}


int wcs_types(struct wcsprm *wcs)

{
  const int  nalias = 2;
  const char aliases [2][4] = {"NCP", "GLS"};

  char ctypei[16], pcode[4], requir[9], scode[4], specsys[9];
  int i, j, m, naxis, *ndx = 0x0, type;


  if (wcs == 0x0) return 1;

  /* Parse the CTYPEia keyvalues. */
  pcode[0]  = '\0';
  requir[0] = '\0';
  wcs->lng  = -1;
  wcs->lat  = -1;
  wcs->spec = -1;
  wcs->cubeface = -1;


  naxis = wcs->naxis;
  if (wcs->types) free(wcs->types);
  wcs->types = calloc(naxis, sizeof(int));

  for (i = 0; i < naxis; i++) {
    /* Null fill. */
    wcsutil_null_fill(72, wcs->ctype[i]);

    strncpy(ctypei, wcs->ctype[i], 15);
    ctypei[15] = '\0';

    /* Check for early Paper IV syntax (e.g. '-SIP' used by Spitzer). */
    if (strlen(ctypei) == 12 && ctypei[8] == '-') {
      /* Excise the "4-3-3" or "8-3"-form distortion code. */
      ctypei[8] = '\0';

      /* Remove trailing dashes from "8-3"-form codes. */
      for (j = 7; j > 0; j--) {
        if (ctypei[j] != '-') break;
        ctypei[j] = '\0';
      }
    }

    /* Logarithmic or tabular axis? */
    wcs->types[i] = 0;
    if (strcmp(ctypei+4, "-LOG") == 0) {
      /* Logarithmic axis. */
      wcs->types[i] = 400;

    } else if (strcmp(ctypei+4, "-TAB") == 0) {
      /* Tabular axis. */
      wcs->types[i] = 500;
    }

    if (wcs->types[i]) {
      /* Could have -LOG or -TAB with celestial or spectral types. */
      ctypei[4] = '\0';

      /* Take care of things like 'FREQ-LOG' or 'RA---TAB'. */
      for (j = 3; j >= 0; j--) {
        if (ctypei[j] != '-') break;
        ctypei[j] = '\0';
      }
    }

    /* Translate AIPS spectral types. */
    if (spcaips(ctypei, wcs->velref, ctypei, specsys) == 0) {
      strcpy(wcs->ctype[i], ctypei);
      if (wcs->specsys[0] == '\0') strcpy(wcs->specsys, specsys);
    }

    /* Process linear axes. */
    if (!(strlen(ctypei) == 8 && ctypei[4] == '-')) {
      /* Identify Stokes, celestial and spectral types. */
      if (strcmp(ctypei, "STOKES") == 0) {
        /* STOKES axis. */
        wcs->types[i] = 1100;

      } else if (strcmp(ctypei, "RA")  == 0 ||
        strcmp(ctypei+1, "LON") == 0 ||
        strcmp(ctypei+2, "LN")  == 0) {
        /* Longitude axis. */
        if (wcs->lng < 0) wcs->lng = i;
        wcs->types[i] += 2000;

      } else if (strcmp(ctypei,   "DEC") == 0 ||
                 strcmp(ctypei+1, "LAT") == 0 ||
                 strcmp(ctypei+2, "LT")  == 0) {
        /* Latitude axis. */
        if (wcs->lat < 0) wcs->lat = i;
        wcs->types[i] += 2001;

      } else if (strcmp(ctypei, "CUBEFACE") == 0) {
        /* CUBEFACE axis. */
        if (wcs->cubeface == -1) {
          wcs->types[i] = 2102;
          wcs->cubeface = i;
        } else {
          /* Multiple CUBEFACE axes! */
          return 4;
        }

      } else if (spctyp(ctypei, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0) == 0) {
        /* Spectral axis. */
        if (wcs->spec < 0) wcs->spec = i;
        wcs->types[i] += 3000;
      }

      continue;
    }


    /* CTYPEia is in "4-3" form; is it a recognized spectral type? */
    if (spctyp(ctypei, 0x0, scode, 0x0, 0x0, 0x0, 0x0, 0x0) == 0) {
      /* Non-linear spectral axis found. */
      wcs->types[i] = 3300;

      /* Check uniqueness. */
      if (wcs->spec >= 0) {
        return 4;
      }

      wcs->spec = i;

      continue;
    }


    /* Is it a recognized celestial projection? */
    for (j = 0; j < prj_ncode; j++) {
      if (strncmp(ctypei+5, prj_codes[j], 3) == 0) break;
    }

    if (j == prj_ncode) {
      /* Not a standard projection code, maybe it's an alias. */
      for (j = 0; j < nalias; j++) {
        if (strncmp(ctypei+5, aliases[j], 3) == 0) break;
      }

      if (j == nalias) {
        /* Not a recognized algorithm code of any type. */
        wcs->types[i] = -1;
        return 4;
      }
    }

    /* Parse the celestial axis type. */
    wcs->types[i] = 2200;
    if (*pcode == '\0') {
      /* The first of the two celestial axes. */
      sprintf(pcode, "%.3s", ctypei+5);

      if (strncmp(ctypei, "RA--", 4) == 0) {
        wcs->lng = i;
        strcpy(wcs->lngtyp, "RA");
        strcpy(wcs->lattyp, "DEC");
        ndx = &wcs->lat;
        sprintf(requir, "DEC--%s", pcode);
      } else if (strncmp(ctypei, "DEC-", 4) == 0) {
        wcs->lat = i;
        strcpy(wcs->lngtyp, "RA");
        strcpy(wcs->lattyp, "DEC");
        ndx = &wcs->lng;
        sprintf(requir, "RA---%s", pcode);
      } else if (strncmp(ctypei+1, "LON", 3) == 0) {
        wcs->lng = i;
        sprintf(wcs->lngtyp, "%cLON", ctypei[0]);
        sprintf(wcs->lattyp, "%cLAT", ctypei[0]);
        ndx = &wcs->lat;
        sprintf(requir, "%s-%s", wcs->lattyp, pcode);
      } else if (strncmp(ctypei+1, "LAT", 3) == 0) {
        wcs->lat = i;
        sprintf(wcs->lngtyp, "%cLON", ctypei[0]);
        sprintf(wcs->lattyp, "%cLAT", ctypei[0]);
        ndx = &wcs->lng;
        sprintf(requir, "%s-%s", wcs->lngtyp, pcode);
      } else if (strncmp(ctypei+2, "LN", 2) == 0) {
        wcs->lng = i;
        sprintf(wcs->lngtyp, "%c%cLN", ctypei[0], ctypei[1]);
        sprintf(wcs->lattyp, "%c%cLT", ctypei[0], ctypei[1]);
        ndx = &wcs->lat;
        sprintf(requir, "%s-%s", wcs->lattyp, pcode);
      } else if (strncmp(ctypei+2, "LT", 2) == 0) {
        wcs->lat = i;
        sprintf(wcs->lngtyp, "%c%cLN", ctypei[0], ctypei[1]);
        sprintf(wcs->lattyp, "%c%cLT", ctypei[0], ctypei[1]);
        ndx = &wcs->lng;
        sprintf(requir, "%s-%s", wcs->lngtyp, pcode);
      } else {
        /* Unrecognized celestial type. */
        wcs->types[i] = -1;

        wcs->lng = -1;
        wcs->lat = -1;
        return 4;
      }

      if (wcs->lat >= 0) wcs->types[i]++;

    } else {
      /* Looking for the complementary celestial axis. */
      if (wcs->lat < 0) wcs->types[i]++;

      if (strncmp(ctypei, requir, 8) != 0) {
        /* Inconsistent projection types. */
        wcs->lng = -1;
        wcs->lat = -1;
        return 4;
      }

      *ndx = i;
      requir[0] = '\0';
    }
  }

  /* Do we have a complementary pair of celestial axes? */
  if (strcmp(requir, "")) {
    /* Unmatched celestial axis. */
    wcs->lng = -1;
    wcs->lat = -1;
    return 4;
  }

  /* Table group numbers. */
  for (j = 0; j < wcs->ntab; j++) {
    for (m = 0; m < wcs->tab[j].M; m++) {
      i = wcs->tab[j].map[m];

      type = (wcs->types[i] / 100) % 10;
      if (type != 5) {
        return 4;
      }
      wcs->types[i] += 10 * j;
    }
  }

  return 0;
}


int wcs_units(struct wcsprm *wcs)

{
  char ctype[9], units[16];
  int  i, j, naxis;
  double scale, offset, power;

  /* Initialize if required. */
  if (wcs == 0x0) return 1;

  naxis = wcs->naxis;
  for (i = 0; i < naxis; i++) {
    /* Use types set by wcs_types(). */
    switch (wcs->types[i]/1000) {
    case 2:
      /* Celestial axis. */
      strcpy(units, "deg");
      break;

    case 3:
      /* Spectral axis. */
      strncpy(ctype, wcs->ctype[i], 8);
      ctype[8] = '\0';
      spctyp(ctype, 0x0, 0x0, 0x0, units, 0x0, 0x0, 0x0);
      break;

    default:
      continue;
    }

    /* Tabular axis, CDELTia and CRVALia relate to indices. */
    if ((wcs->types[i]/100)%10 == 5) {
      continue;
    }

    wcsutil_null_fill(72, wcs->cunit[i]);
    if (wcs->cunit[i][0]) {
      if (wcsunits(wcs->cunit[i], units, &scale, &offset, &power)) {
        return 6;
      }

      if (scale != 1.0) {
        wcs->cdelt[i] *= scale;
        wcs->crval[i] *= scale;

        for (j = 0; j < naxis; j++) {
          *(wcs->cd + i*naxis + j) *= scale;
        }

        strcpy(wcs->cunit[i], units);
      }

    } else {
      strcpy(wcs->cunit[i], units);
    }
  }

  return 0;
}

/*--------------------------------------------------------------------------*/

int wcsp2s(
  struct wcsprm *wcs,
  int ncoord,
  int nelem,
  const double pixcrd[],
  double imgcrd[],
  double phi[],
  double theta[],
  double world[],
  int stat[])

{
  int    bits, face, i, iso_x, iso_y, istat, *istatp, itab, k, m, nx, ny,
        *statp, status, type;
  double crvali, offset;
  register double *img, *wrl;
  struct celprm *wcscel = &(wcs->cel);
  struct prjprm *wcsprj = &(wcscel->prj);

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  /* Sanity check. */
  if (ncoord < 1 || (ncoord > 1 && nelem < wcs->naxis)) return 4;


  /* Apply pixel-to-world linear transformation. */
  if ((status = linp2x(&(wcs->lin), ncoord, nelem, pixcrd, imgcrd))) {
    return status;
  }

  /* Initialize status vectors. */
  if (!(istatp = calloc(ncoord, sizeof(int)))) {
    return 2;
  }

  stat[0] = 0;
  wcsutil_setAli(ncoord, 1, stat);


  /* Convert intermediate world coordinates to world coordinates. */
  for (i = 0; i < wcs->naxis; i++) {
    /* Extract the second digit of the axis type code. */
    type = (wcs->types[i] / 100) % 10;

    if (type <= 1) {
      /* Linear or quantized coordinate axis. */
      img = imgcrd + i;
      wrl = world  + i;
      crvali = wcs->crval[i];
      for (k = 0; k < ncoord; k++) {
        *wrl = *img + crvali;
        img += nelem;
        wrl += nelem;
      }

    } else if (wcs->types[i] == 2200) {
      /* Convert celestial coordinates; do we have a CUBEFACE axis? */
      if (wcs->cubeface != -1) {
        /* Separation between faces. */
        if (wcsprj->r0 == 0.0) {
          offset = 90.0;
        } else {
          offset = wcsprj->r0*PI/2.0;
        }

        /* Lay out faces in a plane. */
        img = imgcrd;
        statp = stat;
        bits = (1 << i) | (1 << wcs->lat);
        for (k = 0; k < ncoord; k++, statp++) {
          face = (int)(*(img+wcs->cubeface) + 0.5);
          if (fabs(*(img+wcs->cubeface) - face) > 1e-10) {
            *statp |= bits;
            status = 8;

          } else {
            *statp = 0;

            switch (face) {
            case 0:
              *(img+wcs->lat) += offset;
              break;
            case 1:
              break;
            case 2:
              *(img+i) += offset;
              break;
            case 3:
              *(img+i) += offset*2;
              break;
            case 4:
              *(img+i) += offset*3;
              break;
            case 5:
              *(img+wcs->lat) -= offset;
              break;
            default:
              *statp |= bits;
              status = 8;
            }
          }

          img += nelem;
        }
      }

      /* Check for constant x and/or y. */
      nx = ncoord;
      ny = 0;

      if ((iso_x = wcsutil_allEq(ncoord, nelem, imgcrd+i))) {
        nx = 1;
        ny = ncoord;
      }
      if ((iso_y = wcsutil_allEq(ncoord, nelem, imgcrd+wcs->lat))) {
        ny = 1;
      }

      /* Transform projection plane coordinates to celestial coordinates. */
      if ((istat = celx2s(wcscel, nx, ny, nelem, nelem, imgcrd+i,
                          imgcrd+wcs->lat, phi, theta, world+i,
                          world+wcs->lat, istatp))) {
        if (istat == 5) {
          status = 8;
        } else {
          status = istat + 3;
          goto cleanup;
        }
      }

      /* If x and y were both constant, replicate values. */
      if (iso_x && iso_y) {
        wcsutil_setAll(ncoord, nelem, world+i);
        wcsutil_setAll(ncoord, nelem, world+wcs->lat);
        wcsutil_setAll(ncoord, 1, phi);
        wcsutil_setAll(ncoord, 1, theta);
        wcsutil_setAli(ncoord, 1, istatp);
      }

      if (istat == 5) {
        bits = (1 << i) | (1 << wcs->lat);
        wcsutil_setBit(ncoord, istatp, bits, stat);
      }

    } else if (type == 3 || type == 4) {
      /* Check for constant x. */
      nx = ncoord;
      if ((iso_x = wcsutil_allEq(ncoord, nelem, imgcrd+i))) {
        nx = 1;
      }

      istat = 0;
      if (wcs->types[i] == 3300) {
        /* Spectral coordinates. */
        istat = spcx2s(&(wcs->spc), nx, nelem, nelem, imgcrd+i, world+i,
                       istatp);

      } else if (type == 4) {
        /* Logarithmic coordinates. */
        istat = logx2s(wcs->crval[i], nx, nelem, nelem, imgcrd+i, world+i,
                       istatp);
      }

      if (istat) {
        if (istat == 3) {
          status = 8;
        } else {
          status = istat + 3;
          goto cleanup;
        }
      }

      /* If x was constant, replicate values. */
      if (iso_x) {
        wcsutil_setAll(ncoord, nelem, world+i);
        wcsutil_setAli(ncoord, 1, istatp);
      }

      if (istat == 3) {
        wcsutil_setBit(ncoord, istatp, 1 << i, stat);
      }
    }
  }


  /* Do tabular coordinates. */
  for (itab = 0; itab < wcs->ntab; itab++) {
    istat = tabx2s(wcs->tab + itab, ncoord, nelem, imgcrd, world, istatp);

    if (istat == 4) {
      status = 8;

      bits = 0;
      for (m = 0; m < wcs->tab[itab].M; m++) {
        bits |= 1 << wcs->tab[itab].map[m];
      }
      wcsutil_setBit(ncoord, istatp, bits, stat);

    } else if (istat) {
      status = (istat == 3) ? 5 : istat;
      goto cleanup;
    }
  }


  /* Zero the unused world coordinate elements. */
  for (i = wcs->naxis; i < nelem; i++) {
    world[i] = 0.0;
    wcsutil_setAll(ncoord, nelem, world+i);
  }

cleanup:
  free(istatp);
  return status;
}

/*--------------------------------------------------------------------------*/

int wcss2p(
  struct wcsprm* wcs,
  int ncoord,
  int nelem,
  const double world[],
  double phi[],
  double theta[],
  double imgcrd[],
  double pixcrd[],
  int stat[])

{
  int    bits, i, isolat, isolng, isospec, istat, *istatp, itab, k, m, nlat,
         nlng, nwrld, status, type;
  double crvali, offset;
  register const double *wrl;
  register double *img;
  struct celprm *wcscel = &(wcs->cel);
  struct prjprm *wcsprj = &(wcscel->prj);


  /* Initialize if required. */
  status = 0;
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  /* Sanity check. */
  if (ncoord < 1 || (ncoord > 1 && nelem < wcs->naxis)) return 4;

  /* Initialize status vectors. */
  if (!(istatp = calloc(ncoord, sizeof(int)))) {
    return 2;
  }

  stat[0] = 0;
  wcsutil_setAli(ncoord, 1, stat);


  /* Convert world coordinates to intermediate world coordinates. */
  for (i = 0; i < wcs->naxis; i++) {
    /* Extract the second digit of the axis type code. */
    type = (wcs->types[i] / 100) % 10;

    if (type <= 1) {
      /* Linear or quantized coordinate axis. */
      wrl = world  + i;
      img = imgcrd + i;
      crvali = wcs->crval[i];
      for (k = 0; k < ncoord; k++) {
        *img = *wrl - crvali;
        wrl += nelem;
        img += nelem;
      }

    } else if (wcs->types[i] == 2200) {
      /* Celestial coordinates; check for constant lng and/or lat. */
      nlng = ncoord;
      nlat = 0;

      if ((isolng = wcsutil_allEq(ncoord, nelem, world+i))) {
        nlng = 1;
        nlat = ncoord;
      }
      if ((isolat = wcsutil_allEq(ncoord, nelem, world+wcs->lat))) {
        nlat = 1;
      }

      /* Transform celestial coordinates to projection plane coordinates. */
      if ((istat = cels2x(wcscel, nlng, nlat, nelem, nelem, world+i,
                          world+wcs->lat, phi, theta, imgcrd+i,
                          imgcrd+wcs->lat, istatp))) {
        if (istat == 6) {
          status = 9;
        } else {
          status = istat + 3;
          goto cleanup;
        }
      }

      /* If lng and lat were both constant, replicate values. */
      if (isolng && isolat) {
        wcsutil_setAll(ncoord, nelem, imgcrd+i);
        wcsutil_setAll(ncoord, nelem, imgcrd+wcs->lat);
        wcsutil_setAll(ncoord, 1, phi);
        wcsutil_setAll(ncoord, 1, theta);
        wcsutil_setAli(ncoord, 1, istatp);
      }

      if (istat == 6) {
        bits = (1 << i) | (1 << wcs->lat);
        wcsutil_setBit(ncoord, istatp, bits, stat);
      }

      /* Do we have a CUBEFACE axis? */
      if (wcs->cubeface != -1) {
        /* Separation between faces. */
        if (wcsprj->r0 == 0.0) {
          offset = 90.0;
        } else {
          offset = wcsprj->r0*PI/2.0;
        }

        /* Stack faces in a cube. */
        img = imgcrd;
        for (k = 0; k < ncoord; k++) {
          if (*(img+wcs->lat) < -0.5*offset) {
            *(img+wcs->lat) += offset;
            *(img+wcs->cubeface) = 5.0;
          } else if (*(img+wcs->lat) > 0.5*offset) {
            *(img+wcs->lat) -= offset;
            *(img+wcs->cubeface) = 0.0;
          } else if (*(img+i) > 2.5*offset) {
            *(img+i) -= 3.0*offset;
            *(img+wcs->cubeface) = 4.0;
          } else if (*(img+i) > 1.5*offset) {
            *(img+i) -= 2.0*offset;
            *(img+wcs->cubeface) = 3.0;
          } else if (*(img+i) > 0.5*offset) {
            *(img+i) -= offset;
            *(img+wcs->cubeface) = 2.0;
          } else {
            *(img+wcs->cubeface) = 1.0;
          }

          img += nelem;
        }
      }

    } else if (type == 3 || type == 4) {
      /* Check for constancy. */
      nwrld = ncoord;
      if ((isospec = wcsutil_allEq(ncoord, nelem, world+i))) {
        nwrld = 1;
      }

      istat = 0;
      if (wcs->types[i] == 3300) {
        /* Spectral coordinates. */
        istat = spcs2x(&(wcs->spc), nwrld, nelem, nelem, world+i,
                       imgcrd+i, istatp);

      } else if (type == 4) {
        /* Logarithmic coordinates. */
        istat = logs2x(wcs->crval[i], nwrld, nelem, nelem, world+i,
                       imgcrd+i, istatp);
      }

      if (istat) {
        if (istat == 4) {
          status = 9;
        } else {
          status = istat + 3;
          goto cleanup;
        }
      }

      /* If constant, replicate values. */
      if (isospec) {
        wcsutil_setAll(ncoord, nelem, imgcrd+i);
        wcsutil_setAli(ncoord, 1, istatp);
      }

      if (istat == 4) {
        wcsutil_setBit(ncoord, istatp, 1 << i, stat);
      }
    }
  }


  /* Do tabular coordinates. */
  for (itab = 0; itab < wcs->ntab; itab++) {
    istat = tabs2x(wcs->tab + itab, ncoord, nelem, world, imgcrd, istatp);

    if (istat == 5) {
      status = 9;

      bits = 0;
      for (m = 0; m < wcs->tab[itab].M; m++) {
        bits |= 1 << wcs->tab[itab].map[m];
      }
      wcsutil_setBit(ncoord, istatp, bits, stat);

    } else if (istat) {
      status = (istat == 3) ? 5 : istat;
      goto cleanup;
    }
  }


  /* Zero the unused intermediate world coordinate elements. */
  for (i = wcs->naxis; i < nelem; i++) {
    imgcrd[i] = 0.0;
    wcsutil_setAll(ncoord, nelem, imgcrd+i);
  }


  /* Apply world-to-pixel linear transformation. */
  if ((istat = linx2p(&(wcs->lin), ncoord, nelem, imgcrd, pixcrd))) {
    status = istat;
    goto cleanup;
  }

cleanup:
  free(istatp);
  return status;
}

/*--------------------------------------------------------------------------*/

int wcsmix(
  struct wcsprm *wcs,
  int mixpix,
  int mixcel,
  const double vspan[2],
  double vstep,
  int viter,
  double world[],
  double phi[],
  double theta[],
  double imgcrd[],
  double pixcrd[])

{
  const int niter = 60;
  int    crossed, istep, iter, j, k, nstep, retry, stat[1], status;
  const double tol  = 1.0e-10;
  const double tol2 = 100.0*tol;
  double *worldlat, *worldlng;
  double lambda, span[2], step;
  double pixmix;
  double dlng, lng, lng0, lng0m, lng1, lng1m;
  double dlat, lat, lat0, lat0m, lat1, lat1m;
  double d, d0, d0m, d1, d1m, dx = 0.0;
  double dabs, dmin, lmin;
  double dphi, phi0, phi1;
  struct celprm *wcscel = &(wcs->cel);
  struct wcsprm wcs0;

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  worldlng = world + wcs->lng;
  worldlat = world + wcs->lat;


  /* Check vspan. */
  if (vspan[0] <= vspan[1]) {
    span[0] = vspan[0];
    span[1] = vspan[1];
  } else {
    /* Swap them. */
    span[0] = vspan[1];
    span[1] = vspan[0];
  }

  /* Check vstep. */
  step = fabs(vstep);
  if (step == 0.0) {
    step = (span[1] - span[0])/10.0;
    if (step > 1.0 || step == 0.0) step = 1.0;
  }

  /* Check viter. */
  nstep = viter;
  if (nstep < 5) {
    nstep = 5;
  } else if (nstep > 10) {
    nstep = 10;
  }

  /* Given pixel element. */
  pixmix = pixcrd[mixpix];

  /* Iterate on the step size. */
  for (istep = 0; istep <= nstep; istep++) {
    if (istep) step /= 2.0;

    /* Iterate on the sky coordinate between the specified range. */
    if (mixcel == 1) {
      /* Celestial longitude is given. */

      /* Check whether the solution interval is a crossing interval. */
      lat0 = span[0];
      *worldlat = lat0;
      if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }
      d0 = pixcrd[mixpix] - pixmix;

      dabs = fabs(d0);
      if (dabs < tol) return 0;

      lat1 = span[1];
      *worldlat = lat1;
      if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }
      d1 = pixcrd[mixpix] - pixmix;

      dabs = fabs(d1);
      if (dabs < tol) return 0;

      lmin = lat1;
      dmin = dabs;

      /* Check for a crossing point. */
      if (signbit(d0) != signbit(d1)) {
        crossed = 1;
        dx = d1;
      } else {
        crossed = 0;
        lat0 = span[1];
      }

      for (retry = 0; retry < 4; retry++) {
        /* Refine the solution interval. */
        while (lat0 > span[0]) {
          lat0 -= step;
          if (lat0 < span[0]) lat0 = span[0];
          *worldlat = lat0;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d0 = pixcrd[mixpix] - pixmix;

          /* Check for a solution. */
          dabs = fabs(d0);
          if (dabs < tol) return 0;

          /* Record the point of closest approach. */
          if (dabs < dmin) {
            lmin = lat0;
            dmin = dabs;
          }

          /* Check for a crossing point. */
          if (signbit(d0) != signbit(d1)) {
            crossed = 2;
            dx = d0;
            break;
          }

          /* Advance to the next subinterval. */
          lat1 = lat0;
          d1 = d0;
        }

        if (crossed) {
          /* A crossing point was found. */
          for (iter = 0; iter < niter; iter++) {
            /* Use regula falsi division of the interval. */
            lambda = d0/(d0-d1);
            if (lambda < 0.1) {
              lambda = 0.1;
            } else if (lambda > 0.9) {
              lambda = 0.9;
            }

            dlat = lat1 - lat0;
            lat = lat0 + lambda*dlat;
            *worldlat = lat;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }

            /* Check for a solution. */
            d = pixcrd[mixpix] - pixmix;
            dabs = fabs(d);
            if (dabs < tol) return 0;

            if (dlat < tol) {
              /* An artifact of numerical imprecision. */
              if (dabs < tol2) return 0;

              /* Must be a discontinuity. */
              break;
            }

            /* Record the point of closest approach. */
            if (dabs < dmin) {
              lmin = lat;
              dmin = dabs;
            }

            if (signbit(d0) == signbit(d)) {
              lat0 = lat;
              d0 = d;
            } else {
              lat1 = lat;
              d1 = d;
            }
          }

          /* No convergence, must have been a discontinuity. */
          if (crossed == 1) lat0 = span[1];
          lat1 = lat0;
          d1 = dx;
          crossed = 0;

        } else {
          /* No crossing point; look for a tangent point. */
          if (lmin == span[0]) break;
          if (lmin == span[1]) break;

          lat = lmin;
          lat0 = lat - step;
          if (lat0 < span[0]) lat0 = span[0];
          lat1 = lat + step;
          if (lat1 > span[1]) lat1 = span[1];

          *worldlat = lat0;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d0 = fabs(pixcrd[mixpix] - pixmix);

          d  = dmin;

          *worldlat = lat1;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d1 = fabs(pixcrd[mixpix] - pixmix);

          for (iter = 0; iter < niter; iter++) {
            lat0m = (lat0 + lat)/2.0;
            *worldlat = lat0m;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }
            d0m = fabs(pixcrd[mixpix] - pixmix);

            if (d0m < tol) return 0;

            lat1m = (lat1 + lat)/2.0;
            *worldlat = lat1m;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }
            d1m = fabs(pixcrd[mixpix] - pixmix);

            if (d1m < tol) return 0;

            if (d0m < d && d0m <= d1m) {
              lat1 = lat;
              d1   = d;
              lat  = lat0m;
              d    = d0m;
            } else if (d1m < d) {
              lat0 = lat;
              d0   = d;
              lat  = lat1m;
              d    = d1m;
            } else {
              lat0 = lat0m;
              d0   = d0m;
              lat1 = lat1m;
              d1   = d1m;
            }
          }
        }
      }

    } else {
      /* Celestial latitude is given. */

      /* Check whether the solution interval is a crossing interval. */
      lng0 = span[0];
      *worldlng = lng0;
      if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }
      d0 = pixcrd[mixpix] - pixmix;

      dabs = fabs(d0);
      if (dabs < tol) return 0;

      lng1 = span[1];
      *worldlng = lng1;
      if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }
      d1 = pixcrd[mixpix] - pixmix;

      dabs = fabs(d1);
      if (dabs < tol) return 0;
      lmin = lng1;
      dmin = dabs;

      /* Check for a crossing point. */
      if (signbit(d0) != signbit(d1)) {
        crossed = 1;
        dx = d1;
      } else {
        crossed = 0;
        lng0 = span[1];
      }

      for (retry = 0; retry < 4; retry++) {
        /* Refine the solution interval. */
        while (lng0 > span[0]) {
          lng0 -= step;
          if (lng0 < span[0]) lng0 = span[0];
          *worldlng = lng0;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d0 = pixcrd[mixpix] - pixmix;

          /* Check for a solution. */
          dabs = fabs(d0);
          if (dabs < tol) return 0;

          /* Record the point of closest approach. */
          if (dabs < dmin) {
            lmin = lng0;
            dmin = dabs;
          }

          /* Check for a crossing point. */
          if (signbit(d0) != signbit(d1)) {
            crossed = 2;
            dx = d0;
            break;
          }

          /* Advance to the next subinterval. */
          lng1 = lng0;
          d1 = d0;
        }

        if (crossed) {
          /* A crossing point was found. */
          for (iter = 0; iter < niter; iter++) {
            /* Use regula falsi division of the interval. */
            lambda = d0/(d0-d1);
            if (lambda < 0.1) {
              lambda = 0.1;
            } else if (lambda > 0.9) {
              lambda = 0.9;
            }

            dlng = lng1 - lng0;
            lng = lng0 + lambda*dlng;
            *worldlng = lng;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }

            /* Check for a solution. */
            d = pixcrd[mixpix] - pixmix;
            dabs = fabs(d);
            if (dabs < tol) return 0;

            if (dlng < tol) {
              /* An artifact of numerical imprecision. */
              if (dabs < tol2) return 0;

              /* Must be a discontinuity. */
              break;
            }

            /* Record the point of closest approach. */
            if (dabs < dmin) {
              lmin = lng;
              dmin = dabs;
            }

            if (signbit(d0) == signbit(d)) {
              lng0 = lng;
              d0 = d;
            } else {
              lng1 = lng;
              d1 = d;
            }
          }

          /* No convergence, must have been a discontinuity. */
          if (crossed == 1) lng0 = span[1];
          lng1 = lng0;
          d1 = dx;
          crossed = 0;

        } else {
          /* No crossing point; look for a tangent point. */
          if (lmin == span[0]) break;
          if (lmin == span[1]) break;

          lng = lmin;
          lng0 = lng - step;
          if (lng0 < span[0]) lng0 = span[0];
          lng1 = lng + step;
          if (lng1 > span[1]) lng1 = span[1];

          *worldlng = lng0;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d0 = fabs(pixcrd[mixpix] - pixmix);

          d  = dmin;

          *worldlng = lng1;
          if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                               stat))) {
            return (status == 9) ? 10 : status;
          }
          d1 = fabs(pixcrd[mixpix] - pixmix);

          for (iter = 0; iter < niter; iter++) {
            lng0m = (lng0 + lng)/2.0;
            *worldlng = lng0m;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }
            d0m = fabs(pixcrd[mixpix] - pixmix);

            if (d0m < tol) return 0;

            lng1m = (lng1 + lng)/2.0;
            *worldlng = lng1m;
            if ((status = wcss2p(wcs, 1, 0, world, phi, theta, imgcrd, pixcrd,
                                 stat))) {
              return (status == 9) ? 10 : status;
            }
            d1m = fabs(pixcrd[mixpix] - pixmix);

            if (d1m < tol) return 0;

            if (d0m < d && d0m <= d1m) {
              lng1 = lng;
              d1   = d;
              lng  = lng0m;
              d    = d0m;
            } else if (d1m < d) {
              lng0 = lng;
              d0   = d;
              lng  = lng1m;
              d    = d1m;
            } else {
              lng0 = lng0m;
              d0   = d0m;
              lng1 = lng1m;
              d1   = d1m;
            }
          }
        }
      }
    }
  }


  /* Set cel0 to the unity transformation. */
  wcs0 = *wcs;
  wcs0.cel.euler[0] = -90.0;
  wcs0.cel.euler[1] =   0.0;
  wcs0.cel.euler[2] =  90.0;
  wcs0.cel.euler[3] =   1.0;
  wcs0.cel.euler[4] =   0.0;

  /* No convergence, check for aberrant behaviour at a native pole. */
  *theta = -90.0;
  for (j = 1; j <= 2; j++) {
    /* Could the celestial coordinate element map to a native pole? */
    *phi = 0.0;
    *theta = -*theta;
    status = sphx2s(wcscel->euler, 1, 1, 1, 1, phi, theta, &lng, &lat);

    if (mixcel == 1) {
      if (fabs(fmod(*worldlng-lng, 360.0)) > tol) continue;
      if (lat < span[0]) continue;
      if (lat > span[1]) continue;
      *worldlat = lat;
    } else {
      if (fabs(*worldlat-lat) > tol) continue;
      if (lng < span[0]) lng += 360.0;
      if (lng > span[1]) lng -= 360.0;
      if (lng < span[0]) continue;
      if (lng > span[1]) continue;
      *worldlng = lng;
    }

    /* Is there a solution for the given pixel coordinate element? */
    lng = *worldlng;
    lat = *worldlat;

    /* Feed native coordinates to wcss2p() with cel0 set to unity. */
    *worldlng = -180.0;
    *worldlat = *theta;
    if ((status = wcss2p(&wcs0, 1, 0, world, phi, theta, imgcrd, pixcrd,
                         stat))) {
      return (status == 9) ? 10 : status;
    }
    d0 = pixcrd[mixpix] - pixmix;

    /* Check for a solution. */
    if (fabs(d0) < tol) {
      /* Recall saved world coordinates. */
      *worldlng = lng;
      *worldlat = lat;
      return 0;
    }

    /* Search for a crossing interval. */
    phi0 = -180.0;
    for (k = -179; k <= 180; k++) {
      phi1 = (double) k;
      *worldlng = phi1;
      if ((status = wcss2p(&wcs0, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }
      d1 = pixcrd[mixpix] - pixmix;

      /* Check for a solution. */
      dabs = fabs(d1);
      if (dabs < tol) {
        /* Recall saved world coordinates. */
        *worldlng = lng;
        *worldlat = lat;
        return 0;
      }

      /* Is it a crossing interval? */
      if (signbit(d0) != signbit(d1)) break;

      phi0 = phi1;
      d0 = d1;
    }

    for (iter = 1; iter <= niter; iter++) {
      /* Use regula falsi division of the interval. */
      lambda = d0/(d0-d1);
      if (lambda < 0.1) {
        lambda = 0.1;
      } else if (lambda > 0.9) {
        lambda = 0.9;
      }

      dphi = phi1 - phi0;
      *worldlng = phi0 + lambda*dphi;
      if ((status = wcss2p(&wcs0, 1, 0, world, phi, theta, imgcrd, pixcrd,
                           stat))) {
        return (status == 9) ? 10 : status;
      }

      /* Check for a solution. */
      d = pixcrd[mixpix] - pixmix;
      dabs = fabs(d);
      if (dabs < tol || (dphi < tol && dabs < tol2)) {
        /* Recall saved world coordinates. */
        *worldlng = lng;
        *worldlat = lat;
        return 0;
      }

      if (signbit(d0) == signbit(d)) {
        phi0 = *worldlng;
        d0 = d;
      } else {
        phi1 = *worldlng;
        d1 = d;
      }
    }
  }


  /* No solution. */
  return 11;
}

/*--------------------------------------------------------------------------*/

int wcssptr(
  struct wcsprm *wcs,
  int  *i,
  char ctype[9])

{
  int    j, status;
  double cdelt, crval;

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  if ((j = *i) < 0) {
    if ((j = wcs->spec) < 0) {
      /* Look for a linear spectral axis. */
      for (j = 0; j < wcs->naxis; j++) {
        if (wcs->types[j]/100 == 30) {
          break;
        }
      }

      if (j >= wcs->naxis) {
        /* No spectral axis. */
        return 12;
      }
    }

    *i = j;
  }

  /* Translate the spectral axis. */
  if ((status = spctrn(wcs->ctype[j], wcs->crval[j], wcs->cdelt[j],
                       wcs->restfrq, wcs->restwav, ctype, &crval, &cdelt))) {
    return 6;
  }


  /* Translate keyvalues. */
  wcs->flag = 0;
  wcs->cdelt[j] = cdelt;
  wcs->crval[j] = crval;
  spctyp(ctype, 0x0, 0x0, 0x0, wcs->cunit[j], 0x0, 0x0, 0x0);
  strcpy(wcs->ctype[j], ctype);

  /* This keeps things tidy if the spectral axis is linear. */
  spcini(&(wcs->spc));

  return 0;
}
