#!/usr/bin/env python
#
# history:
#   03feb99 mchw - Miriad:  misc 
#   11mar02 mchw - added declination  
#   12mar02 mchw - removed declination  
#   15mar03 pjt  - pythonized
#   17apr03 pjt  - using newer Miriad.py version


import os,sys,string
import Miriad

# -----------------------------------------------------------------------------

help = """
       calculates hexagonal grid patterns for mosaic observations
       example usage:
          hex.py nring=3 grid=5.0 > hex3_5
          uvgen ... center=hex3_5
       however, also note the existence of a more sophistacted
       embedded approach inside mosaic.py
       """

keyval = {
    "nring"  : "3",           # number of rings (including the center point)
    "grid"   : "5"            # grid separation
    }


# -----------------------------------------------------------------------------

Miriad.keyini(keyval,help,0)

# -----------------------------------------------------------------------------
        
def hex(nring,grid):
    # enable the next line if MIRIAD finally learns what comment lines are
    # print "# Created with:  hex.py nring=%d grid=%g" % (nring,grid)
    for row in range(-nring+1,nring,1):
        y = 0.866025403 * grid * row
        lo = 2-2*nring+abs(row)
        hi = 2*nring-abs(row)-1
        for k in range(lo,hi,2):
            x = 0.5*grid*k
            print "%.2f,%.2f" % (x,y)
# -----------------------------------------------------------------------------
#nring = string.atoi(keyval['nring'])
#grid  = string.atof(keyval['grid'])
nring = Miriad.keyi('nring')
grid  = Miriad.keyr('grid')
hex(nring,grid)

