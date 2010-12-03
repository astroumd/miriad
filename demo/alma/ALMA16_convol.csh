#!/bin/csh -vf

echo $0  Convolve ALMA16 beams by Gaussians   MCHW 02 Dec 2010

convol map=ALMA16_config3.-30.bm fwhm=10,10 out=ALMA16_config3.-30.bm.convol10x10
cgdisp device=/xs in=ALMA16_config3.-30.bm
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol10x10
convol map=ALMA16_config3.-30.bm fwhm=1,1 out=ALMA16_config3.-30.bm.convol1x1
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol10x10,ALMA16_config3.-30.bm.convol1x1
convol map=ALMA16_config3.-30.bm fwhm=2,2 out=ALMA16_config3.-30.bm.convol2x2
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol10x10,ALMA16_config3.-30.bm.convol2x2
convol map=ALMA16_config3.-30.bm fwhm=3,3 out=ALMA16_config3.-30.bm.convol3x3
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol10x10,ALMA16_config3.-30.bm.convol3x3
convol map=ALMA16_config3.-30.bm fwhm=5,5 out=ALMA16_config3.-30.bm.convol5x5
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol10x10,ALMA16_config3.-30.bm.convol5x5
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol3x3,ALMA16_config3.-30.bm.convol5x5
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol1x1,ALMA16_config3.-30.bm.convol3x3,ALMA16_config3.-30.bm.convol5x5,ALMA16_config3.-30.bm.convol10x10
cgdisp device=/xs in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol1x1,ALMA16_config3.-30.bm.convol2x2,ALMA16_config3.-30.bm.convol3x3,ALMA16_config3.-30.bm.convol5x5,ALMA16_config3.-30.bm.convol10x10
imcat in=ALMA16_config3.-30.bm,ALMA16_config3.-30.bm.convol1x1,ALMA16_config3.-30.bm.convol2x2,ALMA16_config3.-30.bm.convol3x3,ALMA16_config3.-30.bm.convol5x5,ALMA16_config3.-30.bm.convol10x10 out=ALMA16_config3.-30.bm.convol.imcat options=relax
cgdisp device=/xs in=ALMA16_config3.-30.bm-30.bm.convol.imcat
cgdisp device=/xs in=ALMA16_config3.-30.bm.convol.imcat
cgdisp device=/xs in=ALMA16_config3.-30.bm.convol.imcat type=con
cgdisp device=/xs in=ALMA16_config3.-30.bm.convol.imcat
cgdisp device=/xs in=ALMA16_config3.-30.bm.convol.imcat device=ALMA16_config3.-30.bm.convol.imcat.ps/ps
