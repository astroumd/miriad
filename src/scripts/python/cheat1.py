#! /usr/bin/env python
#
#    example to read a mirid image if you have no other interfaces
#    needs astropy

import os
import sys
import numpy as np

try:
    from astropy.io import fits
except:
    import pyfits as fits


def mirread(mfile):
    cmd = "fits in=%s out=%s/fits op=xyout" % (mfile,mfile)
    os.system(cmd)
    hdu = fits.open("%s/fits" % mfile)
    h = hdu[0].header
    d = hdu[0].data
    hdu.close()
    #   @todo    should os.remove("%s/fits" % mfile)
    return(h,d)


mfile = sys.argv[1]


if not os.path.exists(mfile):
    print("miriad data %s does not exist" % mfile)

(header,data) = mirread(mfile)
print(mfile,header["NAXIS1"],header["NAXIS2"],data.mean(), data.std())
