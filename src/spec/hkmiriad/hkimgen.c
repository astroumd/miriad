/*
 * gcc -g -I$MIRINC -I$MIRSUBS -o hkimgen hkimgen.c $MIRLIB/libmir.a -lm libZeno.a
 */

/*= hkimgen - generate images
/*& jk
/*: image analysis
/*+
    Much like IMGEN, 

/*@ out
    Output file
/*@ sdgsize
    Grid size of single-dish map
/*@ imsize
    Number of pixels
/*@ cell
    Grid size [arcsec]
/*@ object=
    Object function [BG: Bessel-Gauss, SP: Spheroidal]
/*--
 */

#include "stdinc.h"
#include "getparam.h"
#include "mathfns.h"
#include "maxdimc.h"
#include "miriad.h"

/*
 * Default values for input parameters.
 */

string defv[] = {           ";HKIMGEN: hack miriad imgen and make pb image",
     "out=sp.bm",           ";Output image file",
     "sdgsize=8.0",         ";Grid size of single-dish map",
     "imsize=256,256",      ";Number of pixels",
     "cell=0.5,0.5",        ";Grid size [arcsec]",
     "object=SP",           ";Object function [BG: Bessel-Gauss, SP: Spheroidal]",
     NULL,
};


/*
 * Prototypes and variables for local procedures
 */

local void loaddefv(void);
local void setimhead(int);
local void mkimage();
local double spheroidal2d(double,double);
local double besselgauss(double);
local float bessj1(float);
local double spheroidal(double,int,float);

string headline;
string outfile;
double sdgsize;
string object;
int naxis;
int *naxisi;
int ncell;
double *cell;
float *image;

double crpix1,crpix2,cdelt1,cdelt2,crval1,crval2;
double bmaj,bmin,bpa;

/*
 * MAIN: toplevel routine
 */

int main(int argc, string argv[])
{
    int unit;
    int j;

    initparam(argv,defv);                       /* initialize param access   */
    headline = defv[0] + 1;                     /* skip ";" in headline      */
    loaddefv();                                 /* get params and input data */
    xyopen_c(&unit,outfile,"new",naxis,naxisi); /* open miriad image file    */
    setimhead(unit);                            /* set header variables      */
    mkimage();                                  /* create image of object    */
    for (j=0; j<naxisi[1]; j++)
        xywrite_c(unit,j,image+j*naxisi[0]);    /* write image into file     */
    xyclose_c(unit);                            /* close miriad image file   */

}

/*
 * LOADDEFV: load variables defined in defv or command line
 */

local void loaddefv(void)
{
    int i;

    outfile = getparam("out");                  /* set output file name      */
    sdgsize = getdparam("sdgsize");             /* grid size of single-D map */
    naxis = countelem("imsize");                /* number of axes            */
    naxisi = (int *)allocate(naxis*sizeof(int));/* allocate memory           */
    for (i=0; i<naxis; i++)                     /* num. of pixel             */
        naxisi[i] = scaniparam("imsize",i);
    ncell = countelem("cell");                  /* num. of cell elements     */
    if (ncell != naxis)                         /* if not equal to naxis     */
        error("loaddefv: # of cell does not much with # of axis.");
    cell = (double *) allocate(ncell*sizeof(double));
    for (i=0; i<ncell; i++)                     /* pixel increment           */
        cell[i] = scandparam("cell",i);
    object = getparam("object");                /* object type,e.g.spheroidal*/

}

/*
 * SETIMHEAD: set image header
 */

local void setimhead(int unit)
{

    crpix1 = naxisi[0]/2.0+1.0;
    crpix2 = naxisi[1]/2.0+1.0;
    crval1 =    0.0;
    crval2 = PI/6.0;
    cdelt1 = -cell[0]/3600.0 * PI/180.0;
    cdelt2 = +cell[1]/3600.0 * PI/180.0;
    bmaj   = 2.0 *sdgsize/3600.0 * PI/180.0;
    bmin   = 2.0 *sdgsize/3600.0 * PI/180.0;
    bpa    =  0.0;

    wrhdd_c(unit,"crpix1",crpix1);      
    wrhdd_c(unit,"crpix2",crpix2);
    wrhdd_c(unit,"crval1",crval1);
    wrhdd_c(unit,"crval2",crval2);
    wrhdd_c(unit,"cdelt1",cdelt1);
    wrhdd_c(unit,"cdelt2",cdelt2);
    wrhda_c(unit,"ctype1","RA---SIN");
    wrhda_c(unit,"ctype2","DEC--SIN");
    if (bmaj*bmin > 0) {
        wrhda_c(unit,"bunit","JY/BEAM");
        wrhdd_c(unit,"bmaj",bmaj);
        wrhdd_c(unit,"bmin",bmin);
        wrhdd_c(unit,"bpa",bpa);
    } else {
        wrhda_c(unit,"bunit","JY/PIXEL");
    }
}

/*
 * MKIMAGE: create image
 */

void mkimage(void)
{
    int i,j;
    double x,y,r;

    image = (float *) allocate( naxisi[0]*naxisi[1] * sizeof(float));

    if (scanopt(object,"SP") == TRUE) {         /* spheroidal function      */
        for (i=0; i<naxisi[0]; i++) {
            x = (i - crpix1) * cell[0] / sdgsize;/* norm. by SD grid size    */
            for (j=0; j<naxisi[1]; j++) {
                y = (j - crpix2) * cell[1] / sdgsize;
                image[j*naxisi[0]+i] = (float) spheroidal2d(x,y);
            }
        }
    } else if (scanopt(object,"BG") == TRUE) {   /* bessel gauss function    */
        for (i=0; i<naxisi[0]; i++) {
            x = (i - crpix1) * cell[0] / sdgsize;/* norm. by SD grid size    */
            for (j=0; j<naxisi[1]; j++) {
                y = (j - crpix2) * cell[1] / sdgsize;
                r = sqrt(x*x + y*y);
                image[j*naxisi[0]+i] = besselgauss(r);
            }
        }

    }
}

/*
 * SPHEROIDAL2D: 2-D attenuation of spheroidal function
 *    x,y should be normalized by single-dish grid size
 */

local double spheroidal2d(double x,double y)
{
    double a,b,r,val;

    a = 6.0;
    b = 1.0;

    val = spheroidal(x*2./a,(int)a,b) * spheroidal(y*2./a,(int)a,b);
    return(val);
}

/*
 * BESSELGAUSS: bessel gauss function
 *    x,y should be normalized by single-dish grid size
 */

local double besselgauss(double r)
{
    float w;
    double a,b;

    a = 1.55/PI;
    b = 2.52;

    if (r == 0.0) {
        w = 0.5;
    } else {
        w = bessj1(r/a)/(r/a);
    }
    w /= 0.5;                                    /* normalize; peak=1 */
    return(w*exp(-pow(r/b,2)));
}


/*
 * BESSJ1: 1st-order bessel function J1(x)
 *   taken from 'Numerical Recipes in C'
 */

float bessj1(float x) {

	float ax,z;
	double xx,y,ans,ans1,ans2;

	if ((ax=fabs(x)) < 8.0) {
		y = x*x;
		ans1 = x*(72362614232.0+y*(-7895059235.0+y*(242396853.1
		      +y*(-2972611.439+y*(15704.48260+y*(-30.16036606))))));
		ans2 = 144725228442.0+y*(2300535178.0+y*(18583304.74
		      +y*(99447.43394+y*(376.9991397+y*1.0))));
		ans = ans1/ans2;
	} else {
		z = 8.0/ax;
		y = z*z;
		xx = ax-2.356194491;
		ans1 = 1.0+y*(0.183105e-2+y*(-0.3516396496e-4
		      +y*(0.2457520174e-5+y*(-0.240337019e-6))));
		ans2 = 0.04687499995+y*(-0.2002690873e-3
					+y*(0.8449199096e-5+y*(-0.88228987e-6
		      +y*0.105787412e-6)));
		ans = sqrt(0.636619772/ax)*(cos(xx)*ans1-z*sin(xx)*ans2);
		if (x < 0.0) ans = -ans;
	}
	return ans;
}

/*
 * SPHEROIDAL: spheroidal function
 *                                     sawada@nro 2007-05-31
 *   return spheroidal weighting function C (Schwab 1984).
 *   input parameters are:
 *     prm_eta = -1 - +1: normalized distance from the grid
 *     prm_m = 4,5,6,7,8
 *     prm_alpha = 0.0,0.5,1.0,1.5,2.0
 *   if one of them is out of range, the function returns -1.
 * reference)
 *   Schwab, F. R. 1984, in Indirect Imaging, J. A. Roberts Ed.,
 *     Cambridge Univ. Press, pp. 333-346
 * history)
 *   2006-04-02 initial version
 *   2007-05-31 speed up
 */

double spheroidal(double prm_eta, int prm_m, float prm_alpha) {

  int i,icoeff,twoalpha;
  double ans,abseta,eta0,eta2,detasq,numer,denom;

  /*
   * table of coefficients:
   *   40 sets of 10 parameters p[0-6],q[0-2]
   */
  double coeffs[400] = {
    /*** m = 4 ***/
    /* alpha = 0 */   /* icoeff = 0 */
     1.584774e-2,-1.269612e-1, 2.333851e-1,-1.636744e-1, 5.014648e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 4.845581e-1, 7.457381e-2,
    /* alpha = 1/2 */ /* icoeff = 10 */
     3.101855e-2,-1.641253e-1, 2.385500e-1,-1.417069e-1, 3.773226e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 4.514531e-1, 6.458640e-2,
    /* alpha = 1 */   /* icoeff = 20 */
     5.007900e-2,-1.971357e-1, 2.363775e-1,-1.215569e-1, 2.853104e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 4.228767e-1, 5.655715e-2,
    /* alpha = 3/2 */ /* icoeff = 30 */
     7.201260e-2,-2.251580e-1, 2.293715e-1,-1.038359e-1, 2.174211e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 3.978515e-1, 4.997164e-2,
    /* alpha = 2 */   /* icoeff = 40 */
     9.585932e-2,-2.481381e-1, 2.194469e-1,-8.862132e-2, 1.672243e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 3.756999e-1, 4.448800e-2,
    /*** m = 5 ***/
    /* alpha = 0 */   /* icoeff = 50 */
     3.722238e-3,-4.991683e-2, 1.658905e-1,-2.387240e-1, 1.877469e-1,
    -8.159855e-2, 3.051959e-2, 1.000000e+0, 2.418820e-1, 0.000000e+0,
    /* alpha = 1/2 */ /* icoeff = 60 */
     8.182649e-3,-7.325459e-2, 1.945697e-1,-2.396387e-1, 1.667832e-1,
    -6.620786e-2, 2.224041e-2, 1.000000e+0, 2.291233e-1, 0.000000e+0,
    /* alpha = 1 */   /* icoeff = 70 */
     1.466325e-2,-9.858686e-2, 2.180684e-1,-2.347118e-1, 1.464354e-1,
    -5.350728e-2, 1.624782e-2, 1.000000e+0, 2.177793e-1, 0.000000e+0,
    /* alpha = 3/2 */ /* icoeff = 80 */
     2.314317e-2,-1.246383e-1, 2.362036e-1,-2.257366e-1, 1.275895e-1,
    -4.317874e-2, 1.193168e-2, 1.000000e+0, 2.075784e-1, 0.000000e+0,
    /* alpha = 2 */   /* icoeff = 90 */
     3.346886e-2,-1.503778e-1, 2.492826e-1,-2.142055e-1, 1.106482e-1,
    -3.486024e-2, 8.821107e-3, 1.000000e+0, 1.983358e-1, 0.000000e+0,
    /*** m = 6, eta < eta0 ***/
    /* alpha = 0 */   /* icoeff = 100 */
     5.613913e-2,-3.019847e-1, 6.256387e-1,-6.324887e-1, 3.303194e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 9.077644e-1, 2.535284e-1,
    /* alpha = 1/2 */ /* icoeff = 110 */
     6.843713e-2,-3.342119e-1, 6.302307e-1,-5.829747e-1, 2.765700e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 8.626056e-1, 2.291400e-1,
    /* alpha = 1 */   /* icoeff = 120 */
     8.203343e-2,-3.644705e-1, 6.278660e-1,-5.335581e-1, 2.312756e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 8.212018e-1, 2.078043e-1,
    /* alpha = 3/2 */ /* icoeff = 130 */
     9.675562e-2,-3.922489e-1, 6.197133e-1,-4.857470e-1, 1.934013e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 7.831755e-1, 1.890848e-1,
    /* alpha = 2 */   /* icoeff = 140 */
     1.124069e-1,-4.172349e-1, 6.069622e-1,-4.405326e-1, 1.618978e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 7.481828e-1, 1.726085e-1,
    /*** m = 6, eta > eta0 ***/
    /* alpha = 0 */   /* icoeff = 150 */
     8.531865e-4,-1.616105e-2, 6.888533e-2,-1.109391e-1, 7.747182e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.101270e+0, 3.858544e-1,
    /* alpha = 1/2 */ /* icoeff = 160 */
     2.060760e-3,-2.558954e-2, 8.595213e-2,-1.170228e-1, 7.094106e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.025431e+0, 3.337648e-1,
    /* alpha = 1 */   /* icoeff = 170 */
     4.028559e-3,-3.697768e-2, 1.021332e-1,-1.201436e-1, 6.412774e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 9.599102e-1, 2.918724e-1,
    /* alpha = 3/2 */ /* icoeff = 180 */
     6.887946e-3,-4.994202e-2, 1.168451e-1,-1.207733e-1, 5.744210e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 9.025276e-1, 2.575337e-1,
    /* alpha = 2 */   /* icoeff = 190 */
     1.071895e-2,-6.404749e-2, 1.297386e-1,-1.194208e-1, 5.112822e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 8.517470e-1, 2.289667e-1,
    /*** m = 7, eta < eta0 ***/
    /* alpha = 0 */   /* icoeff = 200 */
     2.460495e-2,-1.640964e-1, 4.340110e-1,-5.705516e-1, 4.418614e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.124957e+0, 3.784976e-1,
    /* alpha = 1/2 */ /* icoeff = 210 */
     3.070261e-2,-1.879546e-1, 4.565902e-1,-5.544891e-1, 3.892790e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.075420e+0, 3.466086e-1,
    /* alpha = 1 */   /* icoeff = 220 */
     3.770526e-2,-2.121608e-1, 4.746423e-1,-5.338058e-1, 3.417026e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.029374e+0, 3.181219e-1,
    /* alpha = 3/2 */ /* icoeff = 230 */
     4.559398e-2,-2.362670e-1, 4.881998e-1,-5.098448e-1, 2.991635e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 9.865496e-1, 2.926441e-1,
    /* alpha = 2 */   /* icoeff = 240 */
     5.432500e-2,-2.598752e-1, 4.974791e-1,-4.837861e-1, 2.614838e-1,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 9.466891e-1, 2.698218e-1,
    /*** m = 7, eta > eta0 ***/
    /* alpha = 0 */   /* icoeff = 250 */
     1.924318e-4,-5.044864e-3, 2.979803e-2,-6.660688e-2, 6.792268e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.450730e+0, 6.578684e-1,
    /* alpha = 1/2 */ /* icoeff = 260 */
     5.030909e-4,-8.639332e-3, 4.018472e-2,-7.595456e-2, 6.696215e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.353872e+0, 5.724332e-1,
    /* alpha = 1 */   /* icoeff = 270 */
     1.059406e-3,-1.343605e-2, 5.135360e-2,-8.386588e-2, 6.484517e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.269924e+0, 5.032139e-1,
    /* alpha = 3/2 */ /* icoeff = 280 */
     1.941904e-3,-1.943727e-2, 6.288221e-2,-9.021607e-2, 6.193000e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.196177e+0, 4.460948e-1,
    /* alpha = 2 */   /* icoeff = 290 */
     3.224785e-3,-2.657664e-2, 7.438627e-2,-9.500554e-2, 5.850884e-2,
     0.000000e+0, 0.000000e+0, 1.000000e+0, 1.130719e+0, 3.982785e-1,
    /*** m = 8, eta < eta0 ***/
    /* alpha = 0 */   /* icoeff = 300 */
     1.378030e-2,-1.097846e-1, 3.625283e-1,-6.522477e-1, 6.684458e-1,
    -4.703556e-1, 0.000000e+0, 1.000000e+0, 1.076975e+0, 3.394154e-1,
    /* alpha = 1/2 */ /* icoeff = 310 */
     1.721632e-2,-1.274981e-1, 3.917226e-1,-6.562264e-1, 6.305859e-1,
    -4.067119e-1, 0.000000e+0, 1.000000e+0, 1.036132e+0, 3.145673e-1,
    /* alpha = 1 */   /* icoeff = 320 */
     2.121871e-2,-1.461891e-1, 4.185427e-1,-6.543539e-1, 5.904660e-1,
    -3.507098e-1, 0.000000e+0, 1.000000e+0, 9.978025e-1, 2.920529e-1,
    /* alpha = 3/2 */ /* icoeff = 330 */
     2.580565e-2,-1.656048e-1, 4.426283e-1,-6.473472e-1, 5.494752e-1,
    -3.018936e-1, 0.000000e+0, 1.000000e+0, 9.617584e-1, 2.715949e-1,
    /* alpha = 2 */   /* icoeff = 340 */
     3.098251e-2,-1.854823e-1, 4.637398e-1,-6.359482e-1, 5.086794e-1,
    -2.595588e-1, 0.000000e+0, 1.000000e+0, 9.278774e-1, 2.530051e-1,
    /*** m = 8, eta > eta0 ***/
    /* alpha = 0 */   /* icoeff = 350 */
     4.290460e-5,-1.508077e-3, 1.233763e-2,-4.091270e-2, 6.547454e-2,
    -5.664203e-2, 0.000000e+0, 1.000000e+0, 1.379457e+0, 5.786953e-1,
    /* alpha = 1/2 */ /* icoeff = 360 */
     1.201008e-4,-2.778372e-3, 1.797999e-2,-5.055048e-2, 7.125083e-2,
    -5.469912e-2, 0.000000e+0, 1.000000e+0, 1.300303e+0, 5.135748e-1,
    /* alpha = 1 */   /* icoeff = 370 */
     2.698511e-4,-4.628815e-3, 2.470890e-2,-6.017759e-2, 7.566434e-2,
    -5.202678e-2, 0.000000e+0, 1.000000e+0, 1.230436e+0, 4.593779e-1,
    /* alpha = 3/2 */ /* icoeff = 380 */
     5.259595e-4,-7.144198e-3, 3.238633e-2,-6.946769e-2, 7.873067e-2,
    -4.889490e-2, 0.000000e+0, 1.000000e+0, 1.168075e+0, 4.135871e-1,
    /* alpha = 2 */   /* icoeff = 390 */
     9.255826e-4,-1.038126e-2, 4.083176e-2,-7.815954e-2, 8.054087e-2,
    -4.552077e-2, 0.000000e+0, 1.000000e+0, 1.111893e+0, 3.744076e-1
  };

  /*
   * check inputs
   * if (at least) one input parameter is out of range, return -1.
   */
  abseta = fabs(prm_eta);
  twoalpha = floor(2.0*prm_alpha + 0.5);
  if (1.0 < abseta ||
      prm_m < 4 || 8 < prm_m ||
      twoalpha < 0 || 4 < twoalpha
     ) return 0.0;

  /*
   * set parameters
   *   icoeff is the starting point in the coefficient table:
   *   in Schwab's notation,
   *     p[k] = coeffs[icoeff+k]; q[k] = coeffs[icoeff+7+k]
   *   eta0 is the relay point of two approx equations
   *   eta2 is Schwab's eta2: 1.0 or eta0
   */
  if (prm_m == 4) {
    icoeff = 0;
    eta0 = 1.0;
  } else if (prm_m == 5) {
    icoeff = 50;
    eta0 = 1.0;
  } else if (prm_m == 6) {
    icoeff = 100;
    eta0 = 0.75;
  } else if (prm_m == 7) {
    icoeff = 200;
    eta0 = 0.775;
  } else {  /* prm_m == 8 */
    icoeff = 300;
    eta0 = 0.775;
  }

  if (prm_m < 6) {
    eta2 = 1.0;
  } else {  /* for m>=6, 2 kinds of approx are used according to eta */
    if (abseta < eta0) {
      eta2 = eta0;
    } else {
      icoeff += 50;
      eta2 = 1.0;
    }
  }

  icoeff += 10*twoalpha;

  /*
   * calculate psi_alpha0
   */
  detasq = pow(abseta,2) - pow(eta2,2);
/*
  numer = 0.0;
  denom = 0.0;
  for(i=0; i<7; i++) {
    numer += coeffs[icoeff+i]*pow(detasq,i);
  }
*/
  numer = coeffs[icoeff] + detasq *
    ( coeffs[icoeff+1] + detasq * ( coeffs[icoeff+2] + detasq *
    ( coeffs[icoeff+3] + detasq * ( coeffs[icoeff+4] + detasq *
    ( coeffs[icoeff+5] + detasq * coeffs[icoeff+6] ) )) ));
/*
  for(i=0; i<3; i++) {
    denom += coeffs[icoeff+7+i]*pow(detasq,i);
  }
*/
  denom = coeffs[icoeff+7] + detasq *
    ( coeffs[icoeff+8] + detasq * coeffs[icoeff+9] );

  if (denom == 0.0) { /* the denominator must not become 0 ....  */
    ans = 0.0;
  } else {
    ans = numer/denom;
  }

  /*
   * calculate the answer C:
   *   C = |1-eta^2|^alpha * psi_alpha0
   */
  ans *= pow(1.0-pow(abseta,2),0.5*twoalpha);

  return ans;
}
