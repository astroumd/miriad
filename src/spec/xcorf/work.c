#include "xcorf.h"

#include <math.h>

#define DCORF(x) ((((x) + LO2) * Global->doppler) - LO2)

#include <Xm/Scale.h>
#include <Xm/TextF.h>
#include <Xm/ToggleB.h>

/*
 *  This routine truncates a number such that it only has NSIG
 *  decimals of precision.
 */
/***********************************************************************/
#ifdef __STDC__
static double fpfmt(double arg, int nsig)
#else
static double fpfmt(arg, nsig)
double arg;
int nsig;
#endif /*__STDC__*/
{
      char fspec;
      char fmt[20];
      char field[80];
      int ndec, iexpo, nchar;
      double val, expo;

      val = (arg >= 0) ? arg : -arg;
      if (val == 0.0) {
        ndec = nsig;
        nchar = nsig + 3;
        fspec = 'f';
      } else if ((val < 1.0E6) && (val > 1.0E-4)) {
        if (val < 0.9) val += 1.0E-5;
        expo = log10(val);
        iexpo = expo;
        if (expo >= 0.0) iexpo++;
        ndec = nsig - iexpo;
        if (ndec < 0) ndec = 0;
        if (iexpo < 0) iexpo = 0;
        nchar = ndec + 2 + iexpo;
        fspec = 'f';
      } else {
        ndec = nsig - 1;
        nchar = nsig + 6;
        fspec = 'E';
      }
      (void)sprintf(fmt, "%%%d.%d%c", nchar, ndec, fspec);
      (void)sprintf(field, fmt, arg);
      if (sscanf(field, " %lg", &val) != 1)
        val = arg;
      return(val);
}

/***********************************************************************/
#ifdef __STDC__
static void setState(Widget w, int which, int indx, Boolean state)
#else
static void setState(w, which, indx, state)
Widget w;
int which, indx;
Boolean state;
#endif /*__STDC__*/
{
    char name[50];
    char errmsg[1000];
    Widget bwW;

    (void)sprintf(name, "*bwRadio_%d*button_%d", which, indx);
    if ((bwW = XtNameToWidget(w, name)) == (Widget)NULL) {
      (void)sprintf(errmsg, "Trouble finding BW widget [%s].\n", name+1);
      Warning(errmsg);
      return;
    }
    XtSetSensitive(bwW, state);
}

/*
 *  This routine turns corf/bw windows on/off by making them either
 *  sensitive (state[i] == True) or insensitive (state[i] == False).
 */
/***********************************************************************/
#ifdef __STDC__
static void setSensitive(Widget parent, Boolean state[], Cardinal count)
#else
static void setSensitive(parent, state, count)
Widget parent;
Boolean state[];
Cardinal count;
#endif /*__STDC__*/
{
    char name[50];
    char errmsg[1000];
    Cardinal which;
    Widget w;

    for (which = 1; which <= count; which++) {
      (void)sprintf(name, "*corfBWFrame_%d", which);
      if ((w = XtNameToWidget(parent, name)) == (Widget)NULL) {
        (void)sprintf(errmsg, "Trouble finding BW widget [%s].", name+1);
        Warning(errmsg);
        continue;
      }
      XtSetSensitive(w, state[which-1]);
      Global->active[which-1] = state[which-1];
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void checkSampling(void)
#else
static void checkSampling()
#endif /*__STDC__*/
{
    char errmsg[1000];
    register int i, j;
    int corshift, bwtest;
    int cormpx[4];

    /*  Warn about under and oversampling. */

    for (i = 0; i < 4; i++) {
      if (Global->bw[i] == 100.0)
        cormpx[i] = 4;
      else if (Global->bw[i] == 50.0)
        cormpx[i] = 2;
      else
        cormpx[i] = 1;
    }

    for (i = 0; i < 2; i++) {
      if ((Global->active[i] && (Global->bw[i] >= 25.0)) ||
          (Global->active[i+2] && (Global->bw[i+2] >= 25.0)))
        corshift = 4;
      else if ((Global->active[i] && (Global->bw[i] == 12.5)) ||
               (Global->active[i+2] && (Global->bw[i+2] == 12.5)))
        corshift = 2;
      else
        corshift = 1;

      for (j = 0; j < 3; j += 2) {
        if (Global->active[i+j]) {
          bwtest = (Global->bw[i+j] / BWMIN) + 0.5;
          if (bwtest > (cormpx[i+j] * corshift)) {
            (void)sprintf(errmsg, "\
BW %d will be undersampled.\n\
Be aware that this is not fatal; but it does imply that you will\n\
lose resolution due to an insufficient number of useful channels.\n\n\
To obtain the full range of the available number of channels,\n\
set BW %d and BW %d to the same value.\n", i+j+1, i-j+3, i+j+1);
            Warning(errmsg);
          } else if (bwtest < (cormpx[i+j] * corshift)) {
            (void)sprintf(errmsg, "\
BW %d will be oversampled.\n\
Be aware that this is not fatal; there is a slight gain in the\n\
signal to noise ratio (SNR); but it does imply that you are\n\
not using the full range of the available number of channels.\n\n\
To obtain the full range of the available number of channels,\n\
set BW %d and BW %d to the same value.\n", i+j+1, i-j+3, i+j+1);
            Warning(errmsg);
          }
        }
      }
    }

    return;
}

/***********************************************************************/
#ifdef __STDC__
static void getLUChans(int which, int *lchan, int *uchan)
#else
static void getLUChans(which, lchan, uchan)
int which;
int *lchan;
int *uchan;
#endif /*__STDC__*/
{
    register int cormpx;

    *lchan = *uchan = 0;

    if ((which < 1) || (which > 4))
      return;

    /*  Get the multiplexing term. */

    if (Global->bw[which-1] == 100.0)
      cormpx = 4;
    else if (Global->bw[which-1] == 50.0)
      cormpx = 2;
    else
      cormpx = 1;

    switch (which) {
      case 1:
        switch (Global->mode) {
          case 1:
            *lchan = Global->numchans / cormpx;
            break;
          case 2:
          case 3:
          case 5:
            *lchan = Global->numchans / 2 / cormpx;
            break;
          case 4:
          case 6:
          case 7:
            *lchan = Global->numchans / 4 / cormpx;
            break;
          case 8:
            *lchan = Global->numchans / 8 / cormpx;
            *uchan = Global->numchans / 8 / 4;
            break;
        }
        break;
      case 2:
        switch (Global->mode) {
          case 1:
            break;
          case 2:
            *uchan = Global->numchans / 2 / cormpx;
            break;
          case 3:
          case 4:
            *uchan = Global->numchans / 4 / cormpx;
            break;
          case 5:
          case 6:
          case 7:
          case 8:
            *lchan = Global->numchans / 8 / 4;
            *uchan = Global->numchans / 8 / 4;
            break;
        }
        break;
      case 3:
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 5:
            break;
          case 4:
          case 6:
            *lchan = Global->numchans / 4 / cormpx;
            break;
          case 7:
          case 8:
            *lchan = Global->numchans / 8 / 4;
            *uchan = Global->numchans / 8 / 4;
            break;
        }
        break;
      case 4:
        switch (Global->mode) {
          case 1:
          case 2:
            break;
          case 3:
          case 4:
            *uchan = Global->numchans / 4 / cormpx;
            break;
          case 5:
          case 6:
          case 7:
          case 8:
            *lchan = Global->numchans / 8 / 4;
            *uchan = Global->numchans / 8 / 4;
            break;
        }
        break;
    }

    return;
}

/*
 *  This routine determines the size of an individual corf based on
 *  the current mode and the bandwidth.  It returns the extent of the
 *  desired corf in MHz as well as an offset (also in MHz).  The offset
 *  is the displacement from the "inner" edge of the actual corf
 *  frequency.  If offset is 0, the corf is at the "inner"-most edge
 *  of the band.
 */
/***********************************************************************/
#ifdef __STDC__
void getCorfSizes(int which, double *extent, double *offset)
#else
void getCorfSizes(which, extent, offset)
int which;
double *extent;
double *offset;
#endif /*__STDC__*/
{
    double off, size;

    switch (which) {
      case 1:
        size = Global->bw[which-1];
        off = size;
        if (Global->mode == 8)
          size += 100;
        break;
      case 2:
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
            size = Global->bw[which-1];
            off = 0;
            break;
          case 5:
          case 6:
          case 7:
          case 8:
            size = 2 * Global->bw[which-1];
            off = Global->bw[which-1];
            break;
        }
        break;
      case 3:
        size = Global->bw[which-1];
        off = size;
        if (Global->mode > 6)
          size += 100;
        break;
      case 4:
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
            size = Global->bw[which-1];
            off = 0;
            break;
          case 5:
          case 6:
          case 7:
          case 8:
            size = 2 * Global->bw[which-1];
            off = Global->bw[which-1];
            break;
        }
        break;
    }

    *offset = off;
    *extent = size;

    return;
}

/***********************************************************************/
#ifdef __STDC__
Boolean isValidCorf(int mode, int whichCorf)
#else
Boolean isValidCorf(mode, whichCorf)
int mode;
int whichCorf;
#endif /*__STDC__*/
{
    Boolean state = True;

    switch (whichCorf) {
      case 1:                              /* Corf 1 is always active. */
        break;
      case 2:
        if (mode < 2)
          state = False;
        break;
      case 3:
        if ((mode < 4) || (mode == 5))
          state = False;
        break;
      case 4:
        if (mode < 3)
          state = False;
        break;
      default:
        state = False;
        break;
    }

    return(state);
}

/***********************************************************************/
#ifdef __STDC__
int isValidIF(Boolean isusb, int chan[], int nchan, double freq, int ifchan[])
#else
int isValidIF(isusb, chan, nchan, freq, ifchan)
Boolean isusb;
int chan[];
int nchan;
double freq;
int ifchan[];
#endif /*__STDC__*/
{
    int nifs;
    double lo1;
    double lineif, hundred;
    double bw[4], delif[4];

    if (nchan != Global->mode) {
      Warning("Number of windows does not agree with current mode.");
      return(0);
    }

    lo1 = getLO1();
    lineif = (freq - lo1) * 1000.0;  /* freq in GHz -> IF freq in MHz. */
    lineif *= Global->doppler;      /* Add doppler motion corrections. */

    if (isusb == True)
      lineif = lineif - LO2;
    else
      lineif = -(lineif + LO2);

    delif[0] = DCORF(Global->corfs[0]) - lineif;
    delif[1] = lineif - DCORF(Global->corfs[1]);
    delif[2] = DCORF(Global->corfs[2]) - lineif;
    delif[3] = lineif - DCORF(Global->corfs[3]);

    bw[0] = Global->bw[0];
    bw[1] = Global->bw[1];
    bw[2] = Global->bw[2];
    bw[3] = Global->bw[3];
    hundred = 100;

    nifs = 0;

    /*  This first case is present in every mode. */
    if ((delif[0] > 0) && (delif[0] <= bw[0]))
      ifchan[nifs++] = chan[0] - (delif[0] * chan[0] / bw[0]);

    switch (Global->mode) {
      case 1:
        break;
      case 2:
        if ((delif[1] > 0) && (delif[1] <= bw[1]))
          ifchan[nifs++] = chan[0] + (delif[1] * chan[1] / bw[1]);
        break;
      case 3:
        if ((delif[1] > 0) && (delif[1] <= bw[1]))
          ifchan[nifs++] = chan[0] + (delif[1] * chan[1] / bw[1]);
        if ((delif[3] > 0) && (delif[3] <= bw[3]))
          ifchan[nifs++] = chan[0] + chan[1] + (delif[3] * chan[2] / bw[3]);
        break;
      case 4:
        if ((delif[1] > 0) && (delif[1] <= bw[1]))
          ifchan[nifs++] = chan[0] + (delif[1] * chan[1] / bw[1]);
        if ((delif[2] > 0) && (delif[2] <= bw[2]))
          ifchan[nifs++] = chan[0] + chan[1] + chan[2] -
                           (delif[2] * chan[2] / bw[2]);
        if ((delif[3] > 0) && (delif[3] <= bw[3]))
          ifchan[nifs++] = chan[0] + chan[1] + chan[2] +
                           (delif[3] * chan[3] / bw[3]);
        break;
      case 5:
        if ((delif[1] >= -hundred) && (delif[1] <= hundred))
          ifchan[nifs++] = chan[0] + chan[1] + (delif[1] * chan[1] / hundred);
        if ((delif[3] >= -hundred) && (delif[3] <= hundred))
          ifchan[nifs++] = chan[0] + (2 * chan[1]) + chan[3] +
                           (delif[3] * chan[3] / hundred);
        break;
      case 6:
        if ((delif[1] >= -hundred) && (delif[1] <= hundred))
          ifchan[nifs++] = chan[0] + chan[1] + (delif[1] * chan[1] / hundred);
        if ((delif[2] > 0) && (delif[2] <= bw[2]))
          ifchan[nifs++] = chan[0] + (2 * chan[1]) + chan[3] -
                           (delif[2] * chan[3] / bw[2]);
        if ((delif[3] >= -hundred) && (delif[3] <= hundred))
          ifchan[nifs++] = chan[0] + (2 * chan[1]) + chan[3] + chan[4] +
                           (delif[3] * chan[5] / hundred);
        break;
      case 7:
        if ((delif[1] >= -hundred) && (delif[1] <= hundred))
          ifchan[nifs++] = chan[0] + chan[1] + (delif[1] * chan[1] / hundred);
        if ((delif[2] >= -hundred) && (delif[2] <= hundred))
          ifchan[nifs++] = chan[0] + (3 * chan[1]) -
                           (delif[2] * chan[3] / hundred);
        if ((delif[3] >= -hundred) && (delif[3] <= hundred))
          ifchan[nifs++] = chan[0] + (5 * chan[1]) +
                           (delif[3] * chan[5] / hundred);
        break;
      case 8:
        if ((delif[0] >= -hundred) && (delif[0] <= 0))
          ifchan[nifs++] = chan[0] - (delif[0] * chan[1] / hundred);
        if ((delif[1] >= -hundred) && (delif[1] <= hundred))
          ifchan[nifs++] = chan[0] + (2 * chan[1]) +
                           (delif[1] * chan[1] / hundred);
        if ((delif[2] >= -hundred) && (delif[2] <= hundred))
          ifchan[nifs++] = chan[0] + (4 * chan[1]) -
                           (delif[2] * chan[1] / hundred);
        if ((delif[3] >= -hundred) && (delif[3] <= hundred))
          ifchan[nifs++] = chan[0] + (6 * chan[1]) +
                           (delif[3] * chan[3] / hundred);
        break;
    }

    return(nifs);
}

/*
 *  For an input channel number and input array of channel ranges,
 *  this routine will try to find the corresponding (doppler un-shifted)
 *  frequency.  The input isusb is used to determine if the sought
 *  line is in the lower or upper sideband relative to LO1.  This
 *  routine returns the frequency (GHz) and in which channel window
 *  (1-8) it appears; both values are set to zero on failure.
 */
/***********************************************************************/
#ifdef __STDC__
double getValidIF(Boolean isusb, int chan[], int nwins, int ichan, int *window)
#else
double getValidIF(isusb, chan, nwins, ichan, window)
Boolean isusb;
int chan[];
int nwins;
int ichan;
int *window;
#endif /*__STDC__*/
{
    int ioff;
    double freq;
    double lineif, hundred;
    double bw[4], delif[4];

    if (nwins != Global->mode) {
      Warning("Number of windows does not agree with current mode.");
      return(0);
    }

    delif[0] = DCORF(Global->corfs[0]);
    delif[1] = DCORF(Global->corfs[1]);
    delif[2] = DCORF(Global->corfs[2]);
    delif[3] = DCORF(Global->corfs[3]);

    bw[0] = Global->bw[0];
    bw[1] = Global->bw[1];
    bw[2] = Global->bw[2];
    bw[3] = Global->bw[3];
    hundred = 100;
    ioff = ichan - chan[0];

    *window = 0;

    /*  This first case is present in every mode. */
    if ((nwins > 0) && (ichan >= 0) && (ichan <= chan[0])) {
      *window = 1;
      lineif = delif[0] + (bw[0] * (double)ioff / (double)chan[0]);
    }

    if ((nwins > 1) && (ioff > 0) && (ioff <= chan[1])) {
      *window = 2;
      switch (Global->mode) {
        case 1:
          break;
        case 2:
        case 3:
        case 4:
          lineif = delif[1] + (bw[1] * ioff / (double)chan[1]);
          break;
        case 5:
        case 6:
        case 7:
          lineif = delif[1] + (hundred * (ioff - chan[1]) / (double)chan[1]);
          break;
        case 8:
          lineif = delif[0] + (hundred * ioff / (double)chan[1]);
          break;
      }
    }

    if (nwins > 2) {
      ioff -= chan[1];
      if ((ioff > 0) && (ioff <= chan[2])) {
        *window = 3;
        switch (Global->mode) {
          case 1:
          case 2:
            break;
          case 3:
            lineif = delif[3] - (bw[3] * (ioff - chan[2]) / (double)chan[2]);
            break;
          case 4:
            lineif = delif[2] + (bw[2] * (ioff - chan[2]) / (double)chan[2]);
            break;
          case 5:
          case 6:
          case 7:
            lineif = delif[1] + (hundred * ioff / (double)chan[1]);
            break;
          case 8:
            lineif = delif[1] + (hundred * (ioff - chan[2]) / (double)chan[1]);
            break;
        }
      }
    }

    if (nwins > 3) {
      ioff -= chan[2];
      if ((ioff > 0) && (ioff <= chan[3])) {
        *window = 4;
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
            break;
          case 4:
            lineif = delif[3] + (bw[3] * ioff / (double)chan[3]);
            break;
          case 5:
            lineif = delif[3] + (hundred * (ioff - chan[3]) / (double)chan[3]);
            break;
          case 6:
            lineif = delif[2] + (bw[2] * (ioff - chan[3]) / (double)chan[3]);
            break;
          case 7:
            lineif = delif[2] + (hundred * (ioff - chan[3]) / (double)chan[1]);
            break;
          case 8:
            lineif = delif[1] + (hundred * ioff / (double)chan[1]);
            break;
        }
      }
    }

    if (nwins > 4) {
      ioff -= chan[3];
      if ((ioff > 0) && (ioff <= chan[4])) {
        *window = 5;
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
            break;
          case 5:
            lineif = delif[3] + (hundred * ioff / (double)chan[3]);
            break;
          case 6:
            lineif = delif[3] + (hundred * (ioff - chan[4]) / (double)chan[5]);
            break;
          case 7:
            lineif = delif[2] + (hundred * ioff / (double)chan[1]);
            break;
          case 8:
            lineif = delif[2] + (hundred * (ioff - chan[4]) / (double)chan[5]);
            break;
        }
      }
    }

    if (nwins > 5) {
      ioff -= chan[4];
      if ((ioff > 0) && (ioff <= chan[5])) {
        *window = 6;
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
          case 5:
            break;
          case 6:
            lineif = delif[3] + (hundred * ioff / (double)chan[5]);
            break;
          case 7:
            lineif = delif[3] + (hundred * (ioff - chan[5]) / (double)chan[5]);
            break;
          case 8:
            lineif = delif[2] + (hundred * ioff / (double)chan[5]);
            break;
        }
      }
    }

    if (nwins > 6) {
      ioff -= chan[5];
      if ((ioff > 0) && (ioff <= chan[6])) {
        *window = 7;
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
          case 5:
          case 6:
            break;
          case 7:
            lineif = delif[3] + (hundred * ioff / (double)chan[5]);
            break;
          case 8:
            lineif = delif[3] + (hundred * (ioff - chan[6]) / (double)chan[6]);
            break;
        }
      }
    }

    if (nwins > 7) {
      ioff -= chan[6];
      if ((ioff > 0) && (ioff <= chan[7])) {
        *window = 8;
        switch (Global->mode) {
          case 1:
          case 2:
          case 3:
          case 4:
          case 5:
          case 6:
          case 7:
            break;
          case 8:
            lineif = delif[3] + (hundred * ioff / (double)chan[6]);
            break;
        }
      }
    }

    lineif = (isusb == True) ? (lineif + LO2) : -(lineif + LO2);
    /* freq in GHz <- IF freq in MHz. */
    freq = (lineif / (Global->doppler * 1000.0)) + getLO1();

    return(freq);
}

/***********************************************************************/
#ifdef __STDC__
void updateVelocity(int which)
#else
void updateVelocity(which)
int which;
#endif /*__STDC__*/
{
    register int i, j;
    int size, lchan, uchan;
    double extent, offset, lo1, scale;
    double range[2], resol[2];

    j = i = which;
    if (which == 0) {
      i = 1;
      j = 4;
    }

    lo1 = getLO1() * 1000.0;
    lo1 *= Global->doppler;
    scale = CKMS / lo1;

    for (/* NULL */ ; (i <= j); i++) {
      size = 0;
      getLUChans(i, &lchan, &uchan);
      getCorfSizes(i, &extent, &offset);
      extent -= offset;
      resol[0] = resol[1] = 0;
      if ((offset >= BWMIN) && (offset <= BWMAX)) {
        range[size] = offset * scale;
        if (lchan > 0) resol[size] = range[size] / (double)lchan;
        size++;
      }
      if ((extent >= BWMIN) && (extent <= BWMAX)) {
        range[size] = extent * scale;
        if (uchan > 0) resol[size] = range[size] / (double)uchan;
        size++;
      }
      if (size < 1)
        continue;

      /* Fix the number of significant digits for easy in display. */
      range[0] = fpfmt(range[0], 3); range[1] = fpfmt(range[1], 3);
      resol[0] = fpfmt(resol[0], 3); resol[1] = fpfmt(resol[1], 3);

      setVelocityRange(Global->mainWindow, i, size, range);
      setVelocityResol(Global->mainWindow, i, size, resol);

      if (Global->debug > 0) {
        switch (size) {
          case 1:
            (void)printf("#%d Velocity (km/s): Range: [%G] Resolution: [%G]\n",
              i, range[0], resol[0]);
            break;
          case 2:
            (void)printf("#%d Velocity (km/s): Ranges: [%G,%G] Res: [%G,%G]\n",
              i, range[0], range[1], resol[0], resol[1]);
            break;
        }
      }
    }
}

/*
 *  This routine compute and return the (non-doppler shifted) LO1 (GHz)
 *  value based on the rest frequency, the sideband state (USB/LSB),
 *  and the if-frequency.
 */
/***********************************************************************/
#ifdef __STDC__
double getLO1(void)
#else
double getLO1()
#endif /*__STDC__*/
{
    double offset, lo1;

    offset = (LO2 + Global->iffreq) / 1000.0;

    if (Global->usb == True) {
      lo1 = Global->restfreq - offset;
    } else {
      lo1 = Global->restfreq + offset;
    }

    return(lo1);
}

/*
 *  This routine will compute the (non-doppler shifted) LO1 value
 *  based on the frequency, the sideband state (USB/LSB), and the
 *  if-frequency.  It also adjusts the position of the slider.
 */
/***********************************************************************/
#ifdef __STDC__
void updateLO1(void)
#else
void updateLO1()
#endif /*__STDC__*/
{
    setSliderValue(getLO1());
    updateVelocity(0);

    return;
}

/*
 *  This routine takes as input, the (non-doppler shifted) LO1
 *  frequency in GHz.  It then calculates the (also non-doppler
 *  shifted) rest frequency based on the current sideband and the
 *  IF frequency selected and then sets the rest frequency accordingly.
 *  (This will also reset the slider position via the called routines.)
 */
/***********************************************************************/
#ifdef __STDC__
void setLO1(double value)
#else
void setLO1(value)
double value;
#endif /*__STDC__*/
{
    double offset, restfreq;

    offset = (LO2 + Global->iffreq) / 1000.0;

    if (Global->usb == True)
      restfreq = value + offset;
    else
      restfreq = value - offset;

    setRestFreq(Global->mainWindow, restfreq);

    return;
}

/*
 *  This routine returns the number of channel numbers for a given
 *  sideband.  This depends on the current mode and corresponding
 *  correlator bandwidths.  It also returns the channel number for
 *  each window and the number of windows in the array.
 */
/***********************************************************************/
#ifdef __STDC__
int getChannels(int chans[], int *nschan)
#else
int getChannels(chans, nschan)
int chans[];
int *nschan;
#endif /*__STDC__*/
{
    register int i;
    int nchan;
    int cormpx[4], chan[8];

    /*  Get the multiplexing terms. */

    for (i = 0; i < 4; i++) {
      if (Global->bw[i] == 100.0)
        cormpx[i] = 4;
      else if (Global->bw[i] == 50.0)
        cormpx[i] = 2;
      else
        cormpx[i] = 1;
    }

    switch (Global->mode) {
      case 1:
        chan[0] = Global->numchans / cormpx[0];
        break;
      case 2:
        chan[0] = Global->numchans / 2 / cormpx[0];
        chan[1] = Global->numchans / 2 / cormpx[1];
        break;
      case 3:
        chan[0] = Global->numchans / 2 / cormpx[0];
        chan[1] = Global->numchans / 4 / cormpx[1];
        chan[2] = Global->numchans / 4 / cormpx[3];
        break;
      case 4:
        for (i = 0; i < 4; i++)
          chan[i] = Global->numchans / 4 / cormpx[i];
        break;
      case 5:
        chan[0] = Global->numchans / 2 / cormpx[0];
        for (i = 1; i < 5; i++)
          chan[i] = Global->numchans / 8 / 4;
        break;
      case 6:
        chan[0] = Global->numchans / 4 / cormpx[0];
        chan[1] = Global->numchans / 8 / 4;
        chan[2] = Global->numchans / 8 / 4;
        chan[3] = Global->numchans / 4 / cormpx[2];
        chan[4] = Global->numchans / 8 / 4;
        chan[5] = Global->numchans / 8 / 4;
        break;
      case 7:
        chan[0] = Global->numchans / 4;
        for (i = 1; i < 7; i++)
          chan[i] = Global->numchans / 8 / 4;
        break;
      case 8:
        chan[0] = Global->numchans / 8 / cormpx[0];
        for (i = 1; i < 8; i++)
          chan[i] = Global->numchans / 8 / 4;
        break;
    }

    for (nchan = i = 0; i < Global->mode; i++)
      nchan += (chans[i] = chan[i]);

    *nschan = Global->mode;

    return(nchan);
}

/*
 *  This routine tests that the chosen corf frequency is within the
 *  limits even when it is doppler shifted.  This should be called
 *  whenever the velocity (vlsr), the bandwidth, corf frequency, or
 *  the mode (effects extent and offset)  is changed.
 */
/***********************************************************************/
#ifdef __STDC__
void checkDoppler(int which)
#else
void checkDoppler(which)
int which;
#endif /*__STDC__*/
{
    char errmsg[1000];
    register int i, j;
    double dcorf, extent, offset;

    j = i = which;
    if (which == 0) {
      i = 1;
      j = 4;
    }

    for (/* NULL */ ; (i <= j); i++) {
      dcorf = DCORF(Global->corfs[i-1]);
      getCorfSizes(i, &extent, &offset);
      dcorf -= offset;

      if ((Global->corfs[i-1] > 0) && (Global->bw[i-1] > 0)) {
        if ((dcorf < CORFMIN) || ((dcorf + extent) > CORFMAX)) {
          (void)sprintf(errmsg, "\
 A VLSR of %G km/s will cause the corf frequency of %G MHz\n\
 (and bandwidth of %G MHz) to extend partially (or entirely)\n\
 outside of the acceptable corf range:\n\
 [%G] <= [min=%G dcorf=%G max=%G] <= [%G] MHz.",
            Global->vlsr, Global->corfs[i-1], Global->bw[i-1],
            (double)CORFMIN, dcorf, (dcorf + offset),
            (dcorf + extent), (double)CORFMAX);
          Warning(errmsg);
        }
      }
    }

    if ((Global->doppler < 0) || (Global->doppler > 2)) {
      (void)sprintf(errmsg, "\
 A VLSR of %G km/s will create a Doppler correction of %G\n\
 (which is incorrect).  The VLSR assigned is larger than the\n\
 speed of light (C = %G km/s); please correct your VLSR.",
            Global->vlsr, Global->doppler, CKMS);
      Warning(errmsg);
    }

    return;
}

/*
 *  This routine adjusts the command panel according to the mode
 *  currently selected.  If needed, it will force certain bandwidth
 *  values and turn off (make insensitive) particular corfs.
 */
/***********************************************************************/
#ifdef __STDC__
void checkMode(void)
#else
void checkMode()
#endif /*__STDC__*/
{
    register int i, j;
    Boolean state[4];
    Cardinal count = 4;
    Widget parent;

    parent = Global->mainWindow;

    for (i = 0; i < count; i++)
      state[i] = True;

    for (j = 0; j < 5; j++) {
      setState(parent, 1, j, True);
      setState(parent, 2, j, True);
      setState(parent, 3, j, True);
      setState(parent, 4, j, True);
    }

    /*  Adjust bandwidths based on mode selected. */
    switch (Global->mode) {
      case 1:
        state[1] = state[2] = state[3] = False;
        break;
      case 2:
        state[2] = state[3] = False;
        break;
      case 3:
        state[2] = False;
        break;
      case 4:
        break;
      case 5:
        state[2] = False;
        for (j = 0; j < 4; j++) {
          setState(parent, 2, j, False);
          setState(parent, 4, j, False);
        }
        if ((Global->bw[1] != 100.0) || (Global->bw[3] != 100.0)) {
          if (Global->debug > 0)
            Warning("BW 2 and 4 must be set to 100 MHz.");
          setBW(parent, 2, 100.0);
          setBW(parent, 4, 100.0);
        }
        break;
      case 6:
        for (j = 0; j < 4; j++) {
          setState(parent, 2, j, False);
          setState(parent, 4, j, False);
        }
        if ((Global->bw[1] != 100.0) || (Global->bw[3] != 100.0)) {
          if (Global->debug > 0)
            Warning("BW 2 and 4 must be set to 100 MHz.");
          setBW(parent, 2, 100.0);
          setBW(parent, 4, 100.0);
        }
        break;
      case 7:
        setState(parent, 1, 0, False);
        setState(parent, 1, 1, False);
        setState(parent, 1, 3, False);
        setState(parent, 1, 4, False);
        for (j = 0; j < 4; j++) {
          setState(parent, 2, j, False);
          setState(parent, 3, j, False);
          setState(parent, 4, j, False);
        }
        if (Global->bw[0] != 25.0) {
          if (Global->debug > 0)
            Warning("BW 1 must be set to 25 MHz.");
          setBW(parent, 1, 25.0);
        }
        if (Global->bw[1] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 2 must be set to 100 MHz.");
          setBW(parent, 2, 100.0);
        }
        if (Global->bw[2] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 3 must be set to 100 MHz.");
          setBW(parent, 3, 100.0);
        }
        if (Global->bw[3] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 4 must be set to 100 MHz.");
          setBW(parent, 4, 100.0);
        }
        break;
      case 8:
        setState(parent, 1, 0, False);
        setState(parent, 1, 1, False);
        for (j = 0; j < 4; j++) {
          setState(parent, 2, j, False);
          setState(parent, 3, j, False);
          setState(parent, 4, j, False);
        }
        if ((Global->bw[0] != 25.0) && (Global->bw[0] != 50.0) &&
            (Global->bw[0] != 100.0)) {
          if (Global->debug > 0)
            Warning("BW 1 must be 25, 50, or 100 MHz; set to 25 MHz.");
          setBW(parent, 1, 25.0);
        }
        if (Global->bw[1] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 2 must be set to 100 MHz.");
          setBW(parent, 2, 100.0);
        }
        if (Global->bw[2] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 3 must be set to 100 MHz.");
          setBW(parent, 3, 100.0);
        }
        if (Global->bw[3] != 100.0) {
          if (Global->debug > 0)
            Warning("BW 4 must be set to 100 MHz.");
          setBW(parent, 4, 100.0);
        }
        break;
    }

    /*  Turn off or on correlator sections as required by mode. */
    setSensitive(parent, state, count);

    checkSampling();

    checkDoppler(0);

    updateVelocity(0);

    updateCorfs();

    updateChannels();

    return;
}

/***********************************************************************/
#ifdef __STDC__
static double checkBW(int which, double bw)
#else
static double checkBW(which, bw)
int which;
double bw;
#endif /*__STDC__*/
{
    char errmsg[1000];
    double bwValue;

    bwValue = bw;

    /*  Adjust bandwidths based on mode selected. */
    switch (Global->mode) {
      case 1:
      case 2:
      case 3:
      case 4:
        break;
      case 5:
      case 6:
        if ((which == 2) || (which == 4)) {
          if (bw != 100.0) {
            (void)sprintf(errmsg, "BW %d must be set to 100 MHz.", which);
            Warning(errmsg);
            bwValue = 100.0;
          }
        }
        break;
      case 7:
        if (which == 1) {
          if (bw != 25.0) {
            Warning("BW 1 must be set to 25 MHz.");
            bwValue = 25.0;
          }
        } else if (bw != 100.0) {
          (void)sprintf(errmsg, "BW %d must be set to 100 MHz.", which);
          Warning(errmsg);
          bwValue = 100.0;
        }
        break;
      case 8:
        if (which == 1) {
          if ((bw != 25.0) && (bw != 50.0) && (bw != 100.0)) {
            Warning("BW 1 must be 25, 50, or 100 MHz; set to 25 MHz.");
            bwValue = 25.0;
          }
        } else if (bw != 100.0) {
          (void)sprintf(errmsg, "BW %d must be set to 100 MHz.", which);
          Warning(errmsg);
          bwValue = 100.0;
        }
        break;
    }

    return(bwValue);
}

/***********************************************************************/
#ifdef __STDC__
void setLastPos(Widget w)
#else
void setLastPos(w)
Widget w;
#endif /*__STDC__*/
{
    XmTextPosition lastpos;

    if (w != (Widget)NULL) {
      lastpos = XmTextFieldGetLastPosition(w);
      XmTextFieldSetInsertionPosition(w, lastpos);
    }
}

/***********************************************************************/
#ifdef __STDC__
void setMode(Widget w, int mode)
#else
void setMode(w, mode)
Widget w;
int mode; /* New mode number. */
#endif /*__STDC__*/
{
    char name[50];
    char errmsg[1000];
    Widget modeW;

    if (mode == Global->mode)
      return;

    if ((mode < 1) || (mode > 8)) {
      Warning("Correlator mode must be in the range [1, 8].");
      mode = Global->mode;                  /* Reset to the old value. */
      if ((mode < 1) || (mode > 8))
        mode = 8;               /* Make sure the global ends up valid. */
    }

    Global->mode = mode;

    (void)sprintf(name, "*modeBox.button_%d", (mode - 1));
    if ((modeW = XtNameToWidget(w, name)) == (Widget)NULL) {
      (void)sprintf(errmsg, "Trouble finding BW widget [%s].", name+1);
      Warning(errmsg);
      return;
    }

    XmToggleButtonSetState(modeW, True, True);

    if (Global->debug > 0)
      (void)printf("Mode set to [%d].\n", mode);

    if (XtIsRealized(w))
      checkMode();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setRestFreq(Widget w, double restfreq)
#else
void setRestFreq(w, restfreq)
Widget w;
double restfreq; /* Rest frequency in GHz. */
#endif /*__STDC__*/
{
    char errmsg[1000];
    char string[80];
    Widget text;

    if ((restfreq < Global->freqmin) || (restfreq > Global->freqmax)) {
      (void)sprintf(errmsg,
        "Input rest frequency must be in the range [%.3f, %.3f] GHz.",
        Global->freqmin, Global->freqmax);
      Warning(errmsg);
      restfreq = Global->restfreq;          /* Reset to the old value. */
      if ((restfreq < Global->freqmin) || (restfreq > Global->freqmax))
        restfreq = Global->freqmin;          /* Make sure it is valid. */
    }

    (void)sprintf(string, "%G", restfreq);

    if ((text = XtNameToWidget(w, "*restfreq")) == (Widget)NULL) {
      Warning("Can't find the rest frequency text widget.");
    } else {
      XmTextFieldSetString(text, string);
      setLastPos(text);
    }

    if (restfreq == Global->restfreq)
      return;

    if (Global->debug > 0)
      (void)printf("Rest frequency set to [%s] GHz.\n", string);

    Global->restfreq = restfreq;         /* Reset the Global variable. */

    updateLO1();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setIFFreq(Widget w, double iffreq)
#else
void setIFFreq(w, iffreq)
Widget w;
double iffreq; /* IF frequency in MHz. */
#endif /*__STDC__*/
{
    char errmsg[1000];
    char string[80];
    Widget text;

    if ((iffreq < IFMIN) || (iffreq > IFMAX)) {
      (void)sprintf(errmsg,
        "Input IF frequency must be in the range [%.1f, %.1f] MHz.",
        (double)IFMIN, (double)IFMAX);
      Warning(errmsg);
      iffreq = Global->iffreq;              /* Reset to the old value. */
      if ((iffreq < IFMIN) || (iffreq > IFMAX))
        iffreq = IFMIN;             /* Make sure the default is valid. */
    }

    (void)sprintf(string, "%G", iffreq);

    if ((text = XtNameToWidget(w, "*iffreq")) == (Widget)NULL) {
      Warning("Can't find the IF-frequency text widget.");
    } else {
      XmTextFieldSetString(text, string);
      setLastPos(text);
    }

    if (iffreq == Global->iffreq)
      return;

    if (Global->debug > 0)
      (void)printf("IF frequency set to [%s] MHz.\n", string);

    Global->iffreq = iffreq;               /* Set the global variable. */

    updateLO1();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setVlsr(Widget w, double vlsr)
#else
void setVlsr(w, vlsr)
Widget w;
double vlsr; /* vlsr in km/s. */
#endif /*__STDC__*/
{
    char string[80];
    Widget text;

    (void)sprintf(string, "%G", vlsr);

    if ((text = XtNameToWidget(w, "*vlsr")) == (Widget)NULL) {
      Warning("Can't find the vlsr text widget.");
    } else {
      XmTextFieldSetString(text, string);
      setLastPos(text);
    }

    if (vlsr == Global->vlsr)
      return;

    if (Global->debug > 0)
      (void)printf("VLSR set to [%s] km/s.\n", string);

    Global->vlsr = vlsr;                   /* Set the global variable. */
    Global->doppler = 1.0 - (vlsr / CKMS); /* Set the global variable. */

    checkDoppler(0);

    refreshAllDrawings();

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setCorf(Widget w, int which, double corf)
#else
void setCorf(w, which, corf)
Widget w;
int which;   /* which corf to set. */
double corf; /* corf value in MHz. */
#endif /*__STDC__*/
{
    char name[50];
    char errmsg[1000];
    int khzValue;
    Widget corfW;

    if ((which < 1) || (which > 4)) {
      (void)sprintf(errmsg,
        "Input Corf number is out of range [1 <= %d <= 4].", which);
      Warning(errmsg);
      return;
    }

    if (corf == Global->corfs[which-1])
      return;

    if ((corf < CORFMIN) || (corf > CORFMAX)) {
      (void)sprintf(errmsg,
        "Illegal corf frequency requested: [%G] <= [%G] <= [%G] MHz.",
        (double)CORFMIN, corf, (double)CORFMAX);
      Warning(errmsg);
      corf = Global->corfs[which-1];
      if ((corf < CORFMIN) || (corf > CORFMAX))
        corf = CORFMIN;             /* Make sure the default is valid. */
    }

    /*  Adjust the correlator frequency for discreteness. */

    if (corf != CORFMIN) {
      khzValue = ((corf / SYNTHSTEP) + 0.5);
      corf = (double)khzValue * SYNTHSTEP;
    }

    Global->corfs[which-1] = corf;

    (void)sprintf(name, "*corf%d", which);
    if ((corfW = XtNameToWidget(w, name)) == (Widget)NULL) {
      (void)sprintf(errmsg, "Trouble finding corf widget [%s].", name+1);
      Warning(errmsg);
      return;
    }

    khzValue = ((corf * 1000.0) + 0.5);
    XmScaleSetValue(corfW, khzValue);

    checkDoppler(which);

    moveCorf(which);

    updateChannels();

    if (Global->debug > 0)
      (void)printf("Corf #%d set to [%G] MHz.\n", which, corf);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void setBW(Widget w, int which, double bw)
#else
void setBW(w, which, bw)
Widget w;
int which; /* Which BW changed. */
double bw; /* BW value in MHz. */
#endif /*__STDC__*/
{
    char name[50];
    char errmsg[1000];
    register int i, test;
    int bwAsInt, savedTest, indx;
    double bwNew;
    Widget bwW;

    if ((which < 1) || (which > 4)) {
      (void)sprintf(errmsg,
        "Input BW number is out of range [1 <= %d <= 4].", which);
      Warning(errmsg);
      return;
    }

    if (bw == Global->bw[which-1])
      return;

    bw = checkBW(which, bw);

    bwAsInt = (bw / BWMIN) + 0.5;
    savedTest = 1 << 5;
    for (indx = i = 0; i < 5; i++) {
      test = (1 << i) - bwAsInt;
      if (test < 0) test = -test;
      if (test < savedTest) {
        indx = i;
        savedTest = test;
      }
    }
    bwNew = BWMIN * (1 << indx);

    if (bwNew != bw) {
      (void)sprintf(errmsg,
        "Illegal bandwidth requested: [%G]; setting to [%G] MHz.", bw, bwNew);
      Warning(errmsg);
    }

    if ((bwNew < BWMIN) || (bwNew > BWMAX)) {
      (void)sprintf(errmsg,
        "Illegal bandwidth requested: [%G] <= [%G] <= [%G] MHz.\n",
        (double)BWMIN, bwNew, (double)BWMAX);
      Warning(errmsg);
      if ((bwNew < BWMIN) || (bwNew > BWMAX))
        bwNew = BWMIN;              /* Make sure the default is valid. */
    }

    Global->bw[which-1] = bwNew;

    (void)sprintf(name, "*bwRadio_%d*button_%d", which, indx);
    if ((bwW = XtNameToWidget(w, name)) == (Widget)NULL) {
      (void)sprintf(errmsg, "Trouble finding BW widget [%s].\n", name+1);
      Warning(errmsg);
      return;
    }

    XmToggleButtonSetState(bwW, True, True);

    checkSampling();

    checkDoppler(which);

    updateVelocity(which);

    scaleCorf(which);

    updateChannels();

    if (Global->debug > 0)
      (void)printf("Bandwidth #%d set to [%G] MHz.\n", which, bwNew);

    return;
}

/***********************************************************************/
#ifdef __STDC__
void refreshAllDrawings(void)
#else
void refreshAllDrawings()
#endif /*__STDC__*/
{
    redisplayDrawing(True);
    redisplayDrawing(False);

    updateCorfs();

    updateChannels();

    return;
}
