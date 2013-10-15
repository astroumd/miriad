#! /usr/bin/env python
#
#
#   Script to convert CASA flux table to CARMA/MIRIAD
#   Normally used for Uranus, Neptune, Jupiter, Venus
#
#   ./flux_c2m.py Uranus_Tb.dat  > uranustb.tab
#   ./flux_c2m.py Neptune_Tb.dat > neptunetb.tab
#   ./flux_c2m.py Jupiter_Tb.dat > jupitertb.tab
#   ./flux_c2m.py Venus_Tb.dat   > venustb.tab
#
#   The _Tb.dat files are essentially transposed to
#   tb.tab files, such that CARMA doesn't have to
#   change.  Currently longest lines are in Jupiter,
#   8540 characters !!!
#
#       11-jul-2013     written     Peter Teuben
#    
#
import math,sys

# freq range
f0 = 20.0
f1 = 300.0

# date range (it will write for times d0,d1,d2 [where d2=2*d1-d0] 
#             to make interpolation work)
d0 = 55197.0
d1 = 59215.0

def read_table(file):
    """read a flux table
    """
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    freq=[]
    flux=[]
    for line in lines:
        words = line.split()
        _freq = float(words[0])
        _flux = float(words[1])
        if _freq < f0 or _freq > f1: continue
        if len(freq)>0 and freq[-1] == _freq: 
            print "# Skipping (%g,%g) because freq is duplicated" % (_freq,_flux)
            continue
        freq.append(_freq)
        flux.append(_flux)
    return (freq,flux)

def write_table(freq,flux):
    n = len(freq)
    #
    sys.stdout.write("#| MJD ")
    for i in range(n):
        sys.stdout.write("| TB%.1f" % freq[i])
    sys.stdout.write("\n");
    #
    sys.stdout.write("#| r   ")
    for i in range(n):
        sys.stdout.write("| r   ")
    sys.stdout.write("\n");
    #
    sys.stdout.write("#| days")
    for i in range(n):
        sys.stdout.write("| K   ")
    sys.stdout.write("\n");
    # 
    sys.stdout.write("%g " % d0)
    for i in range(n):
        sys.stdout.write(" %g" % flux[i])
    sys.stdout.write("\n");
    # 
    sys.stdout.write("%g " % d1)
    for i in range(n):
        sys.stdout.write(" %g" % flux[i])
    sys.stdout.write("\n");
    # 
    sys.stdout.write("%g " % (2*d1-d0))
    for i in range(n):
        sys.stdout.write(" %g" % flux[i])
    sys.stdout.write("\n");
    # 


        
if __name__ == '__main__':
    if len(sys.argv) > 1:
        name = sys.argv[1]
        print "#  automatically written for CARMA from CASA table %s" % name
        print "#  frequencies selected between %g and %g GHz" % (f0,f1)
        (freq,flux) = read_table(name)
        write_table(freq,flux)
    else:
        print 'Need CASA flux filename, e.g.Uranus_Tb.dat'
