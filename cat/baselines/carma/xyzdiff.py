#! /bin/env python
#
#
#   Script to difference two XYZ antenna positions
#
#   27-oct-2011      written,    Peter Teuben

import math,sys

def read_antpos(file):
    """read an antpot file, usually from $CARMA/baselines/carma"""
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    xyz=[]
    for line in lines:
        if line[0] == '#': continue
        w = line.split()
        x = float(w[0])
        y = float(w[1])
        z = float(w[2])
        xyz.append( (x,y,z) )
    return xyz

def print3(label,xyz):
    ant = 0
    for p in xyz:
	ant = ant + 1
        print "%s   %2d %10.4f %10.4f %10.4f" % (label,ant,p[0],p[1],p[2])

def ant_diff(a1,a2):
    d = []
    for p1,p2 in zip(a1,a2):
        d.append( (p1[0]-p2[0], p1[1]-p2[1], p1[2]-p2[2]) )
    return d

def mean_sigma(d):
    sum0 = 0.0
    sum1 = 0.0
    sum2 = 0.0
    for i in d:
        for j in i:
            sum0 = sum0 + 1
            sum1 = sum1 + j
            sum2 = sum2 + j*j
    mean = sum1/sum0
    sigma = sum2/sum0 - mean*mean
    if sigma > 0:
      return mean,math.sqrt(sigma)
    else:
      return mean,0.0
        
if __name__ == '__main__':
    if len(sys.argv) > 2:
        f1 = sys.argv[1]
        f2 = sys.argv[2]
        a1 = read_antpos(f1)
        a2 = read_antpos(f2)
	d = ant_diff(a1,a2)
	print3("diff (ns): ",d)	        
	m,s = mean_sigma(d)
	print "Mean: %f   Sigma: %f" % (m,s)
    else:
        print 'Need two antpos filenames'
