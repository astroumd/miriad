#! /usr/bin/env python
#
#  this processes the output of the command
#    uvbflag vis=... options=astat
#  into a fractional count, as opposed to absolute count
#  and produces some interesting looking fits files
#  for viewing.  It is needed by quality
#
#  12-nov-2013   Peter Teuben   - Created based on earlier version
#  14-nov-2013   PJT - fix if numpy 1.6 present, fix for WB data

import os, sys
try:
    import numpy as np
except:
    print "No numpy installed"
    sys.exit(1)

try:
    import pyfits as fits
except:
    print "Warning: no pyfits installed"
    fits = None


def printf(format, *args):
    sys.stdout.write(format % args)

def np2array(sdata):
    """ work around np 1.6 deficiency
        where one cannot  np.array(['1','2','3'],dtype=float)
    """
    if True:
        n = len(sdata)
        data = np.arange(n,dtype=float)
        for i in range(n):
            data[i] = float(sdata[i])
    else:
        # this works in numpy 1.7
        data = np.array(sdata,dtype=float)
    return data	

def process(file,out='bfmask.txt'):
    fp = open(file,'r')
    lines = fp.readlines()
    fp.close()
    nants = 0
    c = np.zeros(32*23,dtype=float).reshape(32,23)
    counter = range(32)
    visname = None
    for line in lines:
        words = line.strip().split()
        if len(words) == 0: continue
        if words[0][0:5] == 'File:':
            visname = words[1]
        if words[0][0:3] == 'BIT':
            nants = len(words)-1
            # print 'found ',nants,' ants'
            continue
        if nants > 0:
            bit = int(words[0])
            if bit>0:
                counter[bit-1] = words
            elif bit==-1:
                sum = words
    print "test: ",nants,sum[1:nants+1]
    #nsum = np.array(sum[1:nants+1],dtype=float)
    nsum = np2array(sum[1:nants+1])
    fp = open(out,'w')
    fp.write("BIT/      Percentage of mask BITs set per ANT:\n ANT ")
    for ant in range(nants):
        fp.write(" %2d  " % (ant+1))
    fp.write(" BITMASK-NAME\n\n");
    for bit in range(32):
        #val = np.array(counter[bit][1:nants+1],dtype=float)
        val = np2array(counter[bit][1:nants+1])
        r= (val/nsum)*100
        rm = r*10
        # print r
        fp.write("%2d   " % bit)
        for ant in range(nants):
            #printf("%4.1f ",r[ant])
            #printf("%4d ",rm[ant])
            s = "%4.1f " % r[ant]
            if s == " 0.0 ":  s = "  .  "
            fp.write("%s" % s)
            c[bit][ant] = r[ant]
        fp.write(" %s\n" % counter[bit][nants+1])
    fp.close()
    # print "vis=",visname
    return (visname,c)

def blfmask(file,x=4,out='bfmask.olay'):
    fp = open(file,'r')
    lines = fp.readlines()
    fp.close()
    y = 0
    fp = open(out,'w')
    for line in lines:
        y = y + 1
        word = line.strip()
        fp.write('clear abspix abspix %s yes %d %d 0\n' % (word,x,y))
    fp.close()

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print "Usage: %s astats_file" % sys.argv[0]
        print "Parses the output from uvbflag options=astats for quality"
        sys.exit(1)
    file0 = 'bfmask.txt'
    file1 = 'bfmask.fits'
    file2 = 'bfmask.mir'
    file3 = 'bfmask.olay'
    file4 = 'bfmask.ps'
    #
    (visname,m) = process(sys.argv[1],file0)
    #
    blfmask(visname+'/blfmask')
    #
    cmd = 'rm -rf %s %s' % (file1,file2)
    os.system(cmd)
    #
    hdu = fits.PrimaryHDU(m)
    hdulist = fits.HDUList([hdu])
    hdulist.writeto('bfmask.fits')
    #
    cmd = 'fits in=%s out=%s op=xyin' % (file1,file2)
    os.system(cmd)
    #
    os.system('puthd in=%s/ctype1 value=ANT'     % file2)
    os.system('puthd in=%s/ctype2 value=BIT'     % file2)
    os.system('puthd in=%s/bunit  value=PERCENT' % file2)
    cmdopts = 'labtyp=abspix options=full,wedge csize=0,0,0.4,0'
    cmd = 'cgdisp in=%s olay=%s device=%s/vps %s' % (file2,file3,file4,cmdopts)
    os.system(cmd)
    #

    
