#! /bin/env python
#


#     use this if you need just to produce offline figures
# import matplotlib
# matplotlib.use('Agg')

import numpy             as np
#import matplotlib.pyplot as plt
import matplotlib.pylab  as plt


__version__ = "PACS data reduction script helper functions: $Id$"


def sexa2dec(dms):
    """
    convert an D:M:S string to D, also works for H:M:S
    """
    w = dms.split(':')
    if len(w) == 3:
        return float(w[0]) + (float(w[1]) + float(w[2])/60.0)/60.0;
    elif len(w) == 2:
        return float(w[0]) + float(w[1])/60.0;
    elif len(w) == 1:
        return float(w[0])
    else:
        return 0.0

def avector(a):
    v = []
    for x in a:
        v.append(float(x))
    return v

def unwrap(a,doit=True):
    """
    align phases - see e.g. MIRIAD::gpplt.GetPhase()
    """
    if not doit: return a
    a0 = a[0]
    for i in range(0,len(a)):
        a[i] = a[i] - 360*nint((a[i]-a0)/360.0)
        a0 = 0.5*(a[i]+a0)
    return a

def nint(x):
    """
    get nearest integer.  In python2.6 you can use to_integral_value
    """
    if x>0: return int(x+0.5)
    return int(x-0.5)

def rglist(file):
    """
    This reads the ascii output of a listing from gplist options=phase
    which looks roughly as follows:
        GpList: version 18-mar-09
        Found gain entries for  15 antennas.
        The phase gain values listed in the table are:
        Time  Anten 1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
        05:08:17.0    0  111    0 -151   48    4  102 -118   45    0  -16 -135  112  -68   26
        05:32:21.0    0   96    0 -152   53  -13  101 -132   33    0  -30 -138   97  -90    9
        05:56:29.5    0  121    0 -147   66  -15   83 -135   18    0  -55 -146   88  -98   18
        ...
    """
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    inHeader = True

    t=[]
    r=[]
    nants = 0
    for l in lines:
        w = l.split()
        if inHeader:
            if w[0] == 'Time': 
                inHeader = False
        else:
            if nants == 0:
                nants = len(w)-1;
            else:
                if nants != len(w)-1:
                    print "Bad line with different antenna count"
                    return 0
            t.append( sexa2dec(w[0]) )
            r.append( avector(w[1:]) )
    return (nants,np.array(t), np.array(r).transpose())
            
            
def example1(file):
    (nants,t,r) = rglist(file)
    plt.plot(t,r[4],'ro-')
    plt.plot(t,r[5],'bs-')
    plt.axis([0,24,-180,180])
    plt.savefig('example1.ps')
    plt.show()


def example2(file):
    (nants,t,r) = rglist(file)
    plt.figure(1)
    plt.subplot(221)
    plt.plot(t,r[0],'ro-')
    plt.title('Ant-1')

    plt.subplot(222)
    plt.plot(t,unwrap(r[1]),'ro-')
    plt.title('Ant-2')

    plt.subplot(223)
    plt.plot(t,r[2],'ro-')
    plt.title('Ant-3')

    plt.subplot(224)
    plt.plot(t,unwrap(r[3]),'ro-')
    plt.title('Ant-4')
    #
    plt.figure(2)
    plt.plot(t,r[4],'ro-')
    plt.title('Ant-5')
    #
    plt.show()

