#!/usr/bin/env python
#
# calculate hexagonal grid patterns for mosaic observations
#
# history:
#   03feb99 mchw - Miriad:  misc 
#   11mar02 mchw - added declination  
#   12mar02 mchw - removed declination  
#   15mar03 pjt  - pythonized
#
# example usage:
#     hex.py nring=3 grid=5.0 > hex3_5
#     uvgen ... center=hex3_5

import os,sys,string

# -----------------------------------------------------------------------------
keyval = {
    "nring"  : "3",           # number of rings (including the center point)
    "grid"   : "5"            # grid separation
    }

# -----------------------------------------------------------------------------
#
def show_keyval(keyval,help=0,quit=0):
    if help != 0:
        print help
    print "Current keywords and their defaults are:"
    print "------------------------------------------------------------"
    for k in keyval.keys():
        print k + '=' + keyval[k]
    print "------------------------------------------------------------"
    if quit:
        os._exit(0)
    
#                                     
quit = 0
for arg in sys.argv[1:]:
    i=string.find(arg,"=")
    if arg == "--help":
        quit=1
    elif i > 0:
        key = arg[0:i]
        val = arg[i+1:]
        if keyval.has_key(key):
            keyval[key] = val
        else:
            print "### Error: keyword in %s not understood, try --help" % arg
            os._exit(0)            
    else:
        print "### Error: argument %s not understood, try --help" % arg
        os._exit(0)

if quit:
    show_keyval(keyval,0,quit)
    
        

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
    
nring = string.atoi(keyval['nring'])
grid  = string.atof(keyval['grid'])
hex(nring,grid)

