/*============================================================================

  WCSLIB 4.6 - an implementation of the FITS WCS standard.
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
#include "wcsutil.h"
#include "sph.h"
#include "wcs.h"
#include "wcsunits.h"
#include "wcsfix.h"

extern const int WCSSET;

/* Maximum number of coordinate axes that can be handled. */
#define NMAX 16

/* Map status return value to message. */
const char *wcsfix_errmsg[] = {
  "Success",
  "Null wcsprm pointer passed",
  "Memory allocation failed",
  "Linear transformation matrix is singular",
  "Inconsistent or unrecognized coordinate axis types",
  "Invalid parameter value",
  "Invalid coordinate transformation parameters",
  "Ill-conditioned coordinate transformation parameters",
  "All of the corner pixel coordinates are invalid",
  "Could not determine reference pixel coordinate",
  "Could not determine reference pixel value"};

/*--------------------------------------------------------------------------*/

int wcsfix(int ctrl, const int naxis[], struct wcsprm *wcs, int stat[])

{
  int status = 0;

  if ((stat[CDFIX] = cdfix(wcs)) > 0) {
    status = 1;
  }

  if ((stat[DATFIX] = datfix(wcs)) > 0) {
    status = 1;
  }

  if ((stat[UNITFIX] = unitfix(ctrl, wcs)) > 0) {
    status = 1;
  }

  if ((stat[CELFIX] = celfix(wcs)) > 0) {
    status = 1;
  }

  if ((stat[SPCFIX] = spcfix(wcs)) > 0) {
    status = 1;
  }

  if (naxis) {
    if ((stat[CYLFIX] = cylfix(naxis, wcs)) > 0) {
      status = 1;
    }
  } else {
    stat[CYLFIX] = -2;
  }

  return status;
}

/*--------------------------------------------------------------------------*/

int cdfix(struct wcsprm *wcs)

{
  int  i, k, naxis, status = -1;
  double *cd;

  if (wcs == 0x0) return 1;

  if ((wcs->altlin & 1) || !(wcs->altlin & 2)) {
    /* Either we have PCi_ja or there are no CDi_ja. */
    return -1;
  }

  naxis = wcs->naxis;
  status = -1;
  for (i = 0; i < naxis; i++) {
    /* Row of zeros? */
    cd = wcs->cd + i * naxis;
    for (k = 0; k < naxis; k++, cd++) {
      if (*cd != 0.0) goto next;
    }

    /* Column of zeros? */
    cd = wcs->cd + i;
    for (k = 0; k < naxis; k++, cd += naxis) {
      if (*cd != 0.0) goto next;
    }

    cd = wcs->cd + i * (naxis + 1);
    *cd = 1.0;
    status = 0;

next: ;
  }

  return status;
}

/*--------------------------------------------------------------------------*/

int datfix(struct wcsprm *wcs)

{
  char *dateobs;
  int  day, dd, hour = 0, jd, minute = 0, month, msec, n4, year;
  double mjdobs, sec = 0.0, t;

  if (wcs == 0x0) return 1;

  dateobs = wcs->dateobs;
  if (dateobs[0] == '\0') {
    if (undefined(wcs->mjdobs)) {
     /* No date information was provided. */
      return -1;

    } else {
      /* Calendar date from MJD. */
      jd = 2400001 + (int)wcs->mjdobs;

      n4 =  4*(jd + ((2*((4*jd - 17918)/146097)*3)/4 + 1)/2 - 37);
      dd = 10*(((n4-237)%1461)/4) + 5;

      year  = n4/1461 - 4712;
      month = (2 + dd/306)%12 + 1;
      day   = (dd%306)/10 + 1;
      sprintf(dateobs, "%.4d-%.2d-%.2d", year, month, day);

      /* Write time part only if non-zero. */
      if ((t = wcs->mjdobs - (int)wcs->mjdobs) > 0.0) {
        t *= 24.0;
        hour = (int)t;
        t = 60.0 * (t - hour);
        minute = (int)t;
        sec    = 60.0 * (t - minute);

        /* Round to 1ms. */
        dd = 60000*(60*hour + minute) + (int)(1000*(sec+0.0005));
        hour = dd / 3600000;
        dd -= 3600000 * hour;
        minute = dd / 60000;
        msec = dd - 60000 * minute;
        sprintf(dateobs+10, "T%.2d:%.2d:%.2d", hour, minute, msec/1000);

        /* Write fractions of a second only if non-zero. */
        if (msec%1000) {
          sprintf(dateobs+19, ".%.3d", msec%1000);
        }
      }

      return 0;
    }

  } else {
    if (strlen(dateobs) < 8) {
      /* Can't be a valid date. */
      return 5;
    }

    /* Identify the date format. */
    if (dateobs[4] == '-' && dateobs[7] == '-') {
      /* Standard year-2000 form: CCYY-MM-DD[Thh:mm:ss[.sss...]] */
      if (sscanf(dateobs, "%4d-%2d-%2d", &year, &month, &day) < 3) {
        return 5;
      }

      if (dateobs[10] == 'T') {
        if (sscanf(dateobs+11, "%2d:%2d:%lf", &hour, &minute, &sec) < 3) {
          return 5;
        }
      } else if (dateobs[10] == ' ') {
        if (sscanf(dateobs+11, "%2d:%2d:%lf", &hour, &minute, &sec) == 3) {
          dateobs[10] = 'T';
        } else {
          hour = 0;
          minute = 0;
          sec = 0.0;
        }
      }

    } else if (dateobs[4] == '/' && dateobs[7] == '/') {
      /* Also allow CCYY/MM/DD[Thh:mm:ss[.sss...]] */
      if (sscanf(dateobs, "%4d/%2d/%2d", &year, &month, &day) < 3) {
        return 5;
      }

      if (dateobs[10] == 'T') {
        if (sscanf(dateobs+11, "%2d:%2d:%lf", &hour, &minute, &sec) < 3) {
          return 5;
        }
      } else if (dateobs[10] == ' ') {
        if (sscanf(dateobs+11, "%2d:%2d:%lf", &hour, &minute, &sec) == 3) {
          dateobs[10] = 'T';
        } else {
          hour = 0;
          minute = 0;
          sec = 0.0;
        }
      }

      /* Looks ok, fix it up. */
      dateobs[4]  = '-';
      dateobs[7]  = '-';

    } else {
      if (dateobs[2] == '/' && dateobs[5] == '/') {
        /* Old format date: DD/MM/YY, also allowing DD/MM/CCYY. */
        if (sscanf(dateobs, "%2d/%2d/%4d", &day, &month, &year) < 3) {
          return 5;
        }

      } else if (dateobs[2] == '-' && dateobs[5] == '-') {
        /* Also recognize DD-MM-YY and DD-MM-CCYY */
        if (sscanf(dateobs, "%2d-%2d-%4d", &day, &month, &year) < 3) {
          return 5;
        }

      } else {
        /* Not a valid date format. */
        return 5;
      }

      if (year < 100) year += 1900;

      /* Doesn't have a time. */
      sprintf(dateobs, "%.4d-%.2d-%.2d", year, month, day);
    }

    /* Compute MJD. */
    mjdobs = (double)((1461*(year - (12-month)/10 + 4712))/4
             + (306*((month+9)%12) + 5)/10
             - (3*((year - (12-month)/10 + 4900)/100))/4
             + day - 2399904)
             + (hour + (minute + sec/60.0)/60.0)/24.0;

    if (undefined(wcs->mjdobs)) {
      wcs->mjdobs = mjdobs;
    } else {
      /* Check for consistency. */
      if (fabs(mjdobs - wcs->mjdobs) > 0.5) {
        return 5;
      }
    }
  }

  return 0;
}

/*--------------------------------------------------------------------------*/

int unitfix(int ctrl, struct wcsprm *wcs)

{
  int  i, status = -1;

  if (wcs == 0x0) return 1;

  for (i = 0; i < wcs->naxis; i++) {
    if (wcsutrn(ctrl, wcs->cunit[i]) == 0) status = 0;
  }

  return status;
}

/*--------------------------------------------------------------------------*/

int celfix(struct wcsprm *wcs)

{
  int k, status;
  struct celprm *wcscel = &(wcs->cel);
  struct prjprm *wcsprj = &(wcscel->prj);

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  /* Was an NCP or GLS projection code translated? */
  if (wcs->lat >= 0) {
    /* Check ctype. */
    if (strcmp(wcs->ctype[wcs->lat]+5, "NCP") == 0) {
      strcpy(wcs->ctype[wcs->lng]+5, "SIN");
      strcpy(wcs->ctype[wcs->lat]+5, "SIN");

      if (wcs->npvmax < wcs->npv + 2) {
        /* Allocate space for two more PVi_ja keyvalues. */
        if (wcs->m_flag == WCSSET && wcs->pv == wcs->m_pv) {
          if (!(wcs->pv = calloc(wcs->npv+2, sizeof(struct pvcard)))) {
            wcs->pv = wcs->m_pv;
            return 2;
          }

          wcs->npvmax = wcs->npv + 2;
          wcs->m_flag = WCSSET;

          for (k = 0; k < wcs->npv; k++) {
            wcs->pv[k] = wcs->m_pv[k];
          }

          if (wcs->m_pv) free(wcs->m_pv);
          wcs->m_pv = wcs->pv;

        } else {
          return 2;
        }
      }

      wcs->pv[wcs->npv].i = wcs->lat + 1;
      wcs->pv[wcs->npv].m = 1;
      wcs->pv[wcs->npv].value = wcsprj->pv[1];
      (wcs->npv)++;

      wcs->pv[wcs->npv].i = wcs->lat + 1;
      wcs->pv[wcs->npv].m = 2;
      wcs->pv[wcs->npv].value = wcsprj->pv[2];
      (wcs->npv)++;

      return 0;

    } else if (strcmp(wcs->ctype[wcs->lat]+5, "GLS") == 0) {
      strcpy(wcs->ctype[wcs->lng]+5, "SFL");
      strcpy(wcs->ctype[wcs->lat]+5, "SFL");

      if (wcs->crval[wcs->lng] != 0.0 || wcs->crval[wcs->lat] != 0.0) {
        /* In the AIPS convention, setting the reference longitude and
         * latitude for GLS does not create an oblique graticule.  A non-zero
         * reference longitude introduces an offset in longitude in the normal
         * way, whereas a non-zero reference latitude simply translates the
         * reference point (i.e. the map as a whole) to that latitude.  This
         * might be effected by adjusting CRPIXja but that is complicated by
         * the linear transformation and instead is accomplished here by
         * setting theta_0. */
        if (wcs->npvmax < wcs->npv + 2) {
          /* Allocate space for three more PVi_ja keyvalues. */
          if (wcs->m_flag == WCSSET && wcs->pv == wcs->m_pv) {
            if (!(wcs->pv = calloc(wcs->npv+3, sizeof(struct pvcard)))) {
              wcs->pv = wcs->m_pv;
              return 2;
            }

            wcs->npvmax = wcs->npv + 3;
            wcs->m_flag = WCSSET;

            for (k = 0; k < wcs->npv; k++) {
              wcs->pv[k] = wcs->m_pv[k];
            }

            if (wcs->m_pv) free(wcs->m_pv);
            wcs->m_pv = wcs->pv;

          } else {
            return 2;
          }
        }

        wcs->pv[wcs->npv].i = wcs->lng + 1;
        wcs->pv[wcs->npv].m = 0;
        wcs->pv[wcs->npv].value = 1.0;
        (wcs->npv)++;

        /* Note that the reference longitude is still zero. */
        wcs->pv[wcs->npv].i = wcs->lng + 1;
        wcs->pv[wcs->npv].m = 1;
        wcs->pv[wcs->npv].value = 0.0;
        (wcs->npv)++;

        wcs->pv[wcs->npv].i = wcs->lng + 1;
        wcs->pv[wcs->npv].m = 2;
        wcs->pv[wcs->npv].value = wcs->crval[wcs->lat];
        (wcs->npv)++;
      }

      return 0;
    }
  }

  return -1;
}

/*--------------------------------------------------------------------------*/

int spcfix(struct wcsprm *wcs)

{
  char ctype[9], specsys[9];
  int  i, status;

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  if ((i = wcs->spec) < 0) {
    /* Look for a linear spectral axis. */
    for (i = 0; i < wcs->naxis; i++) {
      if (wcs->types[i]/100 == 30) {
        break;
      }
    }

    if (i >= wcs->naxis) {
      /* No spectral axis. */
      return -1;
    }
  }

  /* Translate an AIPS-convention spectral type if present. */
  if ((status = spcaips(wcs->ctype[i], wcs->velref, ctype, specsys))) {
    return status;
  }

  strcpy(wcs->ctype[i], ctype);
  if (wcs->specsys[1] == '\0') strcpy(wcs->specsys, specsys);

  wcsutil_null_fill(72, wcs->ctype[i]);
  wcsutil_null_fill(72, wcs->specsys);

  return 0;
}

/*--------------------------------------------------------------------------*/

int cylfix(const int naxis[], struct wcsprm *wcs)

{
  unsigned short icnr, indx[NMAX], ncnr;
  int    j, k, stat[4], status;
  double img[4][NMAX], lat, lng, phi[4], phi0, phimax, phimin, pix[4][NMAX],
         *pixj, theta[4], theta0, world[4][NMAX], x, y;

  /* Initialize if required. */
  if (wcs == 0x0) return 1;
  if (wcs->flag != WCSSET) {
    if ((status = wcsset(wcs))) return status;
  }

  /* Check that we have a cylindrical projection. */
  if (wcs->cel.prj.category != CYLINDRICAL) return -1;
  if (wcs->naxis < 2) return -1;


  /* Compute the native longitude in each corner of the image. */
  ncnr = 1 << wcs->naxis;

  for (k = 0; k < NMAX; k++) {
    indx[k] = 1 << k;
  }

  status = 0;
  phimin =  1.0e99;
  phimax = -1.0e99;
  for (icnr = 0; icnr < ncnr;) {
    /* Do four corners at a time. */
    for (j = 0; j < 4; j++, icnr++) {
      pixj = pix[j];

      for (k = 0; k < wcs->naxis; k++) {
        if (icnr & indx[k]) {
          *(pixj++) = naxis[k] + 0.5;
        } else {
          *(pixj++) = 0.5;
        }
      }
    }

    if (!(status = wcsp2s(wcs, 4, NMAX, pix[0], img[0], phi, theta, world[0],
                          stat))) {
      for (j = 0; j < 4; j++) {
        if (phi[j] < phimin) phimin = phi[j];
        if (phi[j] > phimax) phimax = phi[j];
      }
    }
  }

  if (phimin > phimax) return status;

  /* Any changes needed? */
  if (phimin >= -180.0 && phimax <= 180.0) return -1;


  /* Compute the new reference pixel coordinates. */
  phi0 = (phimin + phimax) / 2.0;
  theta0 = 0.0;

  if ((status = prjs2x(&(wcs->cel.prj), 1, 1, 1, 1, &phi0, &theta0, &x, &y,
                       stat))) {
    return (status == 2) ? 5 : 9;
  }

  for (k = 0; k < wcs->naxis; k++) {
    img[0][k] = 0.0;
  }
  img[0][wcs->lng] = x;
  img[0][wcs->lat] = y;

  if ((status = linx2p(&(wcs->lin), 1, 0, img[0], pix[0]))) {
    return status;
  }


  /* Compute celestial coordinates at the new reference pixel. */
  if ((status = wcsp2s(wcs, 1, 0, pix[0], img[0], phi, theta, world[0],
                       stat))) {
    return status == 8 ? 10 : status;
  }

  /* Compute native coordinates of the celestial pole. */
  lng =  0.0;
  lat = 90.0;
  (void)sphs2x(wcs->cel.euler, 1, 1, 1, 1, &lng, &lat, phi, theta);

  wcs->crpix[wcs->lng] = pix[0][wcs->lng];
  wcs->crpix[wcs->lat] = pix[0][wcs->lat];
  wcs->crval[wcs->lng] = world[0][wcs->lng];
  wcs->crval[wcs->lat] = world[0][wcs->lat];
  wcs->lonpole = phi[0] - phi0;

  return wcsset(wcs);
}
