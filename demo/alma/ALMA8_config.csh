#!/bin/csh -vf

echo "Extract antenna configurations from Al's ALMA8 configuration file"

awk '{if($1!="#")  printf("%.2f  %.2f  %.2f %s  %s\n", $2, $1, $3, $5, $6)}' ALMA8_config > ALMA8_config1.ant

echo "ALMA8_configs beams with shadow = 12m"

echo "Make single field images and plot beams "
foreach WEIGHT (sup=0 robust=0.5 uniform )
  foreach CONFIG ( 1 )
    foreach DEC ( -30 )
     ./mfs.csh ALMA8_config$CONFIG $DEC -4,4,.1 1 $WEIGHT '-shadow(12)'
    end
  end
end

foreach FWHM ( 1 2 4 8 )
  rm -r ALMA8_config1.-30.bm.convol$FWHM
  convol map=ALMA8_config1.-30.bm out=ALMA8_config1.-30.bm.convol$FWHM fwhm=$FWHM,$FWHM
  cgdisp in=ALMA8_config1.-30.bm.convol$FWHM,ALMA8_config1.-30.bm.convol$FWHM type=pix,con labtyp=arcsec device=/xs
end

rm -r ALMA8_config1.-30.bm.convol.imcat ALMA8_config1.-30.bm.convol.imcat.gif
imcat in="ALMA8_config1.-30.bm.convol*" out=ALMA8_config1.-30.bm.convol.imcat options=relax
cgdisp in=ALMA8_config1.-30.bm.convol.imcat,ALMA8_config1.-30.bm.convol.imcat type=p,c labtyp=arcsec device=/xs
cgdisp in=ALMA8_config1.-30.bm.convol.imcat,ALMA8_config1.-30.bm.convol.imcat type=p,c labtyp=arcsec device=/xs
cgdisp in=ALMA8_config1.-30.bm.convol.imcat,ALMA8_config1.-30.bm.convol.imcat type=p,c labtyp=arcsec device=ALMA8_config1.-30.bm.convol.imcat.gif/gif

end:
