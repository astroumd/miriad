#!/bin/csh -vf
#
# remove working files
#
rm -rf stuff1 stuff2 sky_real sky_pha sky_mag sky_imag sky_pow
rm -rf sky_real_norm sky_pha_norm sky_mag_norm sky_imag_norm sky_pow_norm
##
## normalize = (aper*1.9)**-1 = 0.0000438596 for alma
##
#imgen out=stuff1 object=gaussian spar=1,0,0,0.52,0.52,0 cell=0.016 imsize=8192
imgen out=stuff1 object=j0 spar=1,0,0,0.5263158 cell=0.016 imsize=8192
##
## 
##
maths exp='(<stuff1>)' mask='sqrt(x*x+y*y).le.62.5' xrange=-4096,4096 yrange=-4096,4096 out=stuff2
##
## header fix
##
puthd in=stuff2/ctype1   value=UU---SIN
puthd in=stuff2/ctype2   value=VV---SIN
puthd in=stuff2/cdelt1   value=-32.0
puthd in=stuff2/cdelt2   value=32.0
puthd in=stuff2/restfreq value=100.00
puthd in=stuff2/naxis    value=3
puthd in=stuff2/naxis3   value=1
puthd in=stuff2/crpix3   value=1
puthd in=stuff2/crval3   value=10000.00
puthd in=stuff2/cdelt3   value=10.00
puthd in=stuff2/bunit    value=JY
fft rin=stuff2 rout=sky_real phase=sky_pha iout=sky_imag mag=sky_mag sign=-1
maths exp='(<sky_real>/1.2810e5)' out=sky_real_norm
maths exp='(<sky_imag>/1.2810e5)' out=sky_imag_norm
maths exp='(<sky_pha>/1.2810e5)'  out=sky_pha_norm
maths exp='(<sky_mag>/1.2810e5)'  out=sky_mag_norm
maths exp='(<sky_mag_norm>*<sky_mag_norm>)' out=sky_pow

