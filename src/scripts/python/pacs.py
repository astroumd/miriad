#! /usr/bin/env python
#


#     use this if you need just to produce offline figures
# import matplotlib
# matplotlib.use('Agg')

import numpy             as np
#import matplotlib.pyplot as plt
import matplotlib.pylab  as plt
#
from scipy.interpolate  import spline
import pylab


__version__ = "PACS data reduction script helper functions: $Id$"


#   the buddy pairs in the different campains; note these are 1-based antenna numbers!!!
buddy_b09 = [(2,21),(4,23),(5,20),(6,18),(8,19),(9,22),(13,16),(15,17)]
buddy_a09 = [ ]

def sexa2dec(dms):
    """
    convert an D:M:S string to D, also works for H:M:S

    Inputs:
        dms     D:M:S string, e.g. "04:05:22.3"
    Returns:
        converted floating point value of D:M:S
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
    """convert ascii list into float list"""
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

def rgplist(file):
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

    Inputs:
      file       ...
    Output:
      (n,t,r)    ....
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
            if len(w) > 0 and w[0] == 'Time': 
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
            

def ruvlist(file):
    """
    This reads the ascii output of a listing from uvlist recnum=0
    which looks roughly as follows:

UVLIST: version  10-dec-08
 ***** UV Listing for vis1 *****
  Options: brief,data
  No. channels:   1, Linetype: channel
  Line Start:    1.000, Width:   90.000, Step:   90.000
  Scale factor:    1.000

------------------------------------------------------------

Data values for 09JAN17

 Vis #    Time      Ant    Pol U(kLam)  V(kLam)    Amp   Phase
     1 09:43:52.5   1-   2 RR   -38.69   258.92    4.071 -146
     2 09:43:52.5   1-   3 RR  -308.83   187.31    1.926 -132
     3 09:43:52.5   1-   4 RR    27.14   496.13    4.477  176

        ...

     The data is assumed in regular order , time and baseline regular

    Inputs:
      file       ...
    Output:
      (n,t,r)    ....
    """
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    inHeader = True

    t=[]
    r=[]
    nrec = 0
    time = ""
    ntime = 0
    nbl = 0
    a1 = []
    a2 = []
    vec = []
    nerr = 0
    for l in lines:
        w = l.split()
        if inHeader:
            if len(w) > 0 and w[0] == 'Vis': 
                inHeader = False
        else:
            nrec = nrec + 1
            if w[1] != time:
                ntime = ntime + 1
                if ntime == 2:
                    nbl = nrec - 1
                time = w[1]
                # print 'new Time: %d %s' % (ntime,time)
                if ntime > 1:
                    if len(vec) == nbl:  
                        t.append( sexa2dec(time) )
                        r.append( avector(vec) )
                    else:
                        nerr = nerr + 1
                    vec = []
            ant1 = w[2][:-1]
            ant2 = w[3]
            if ntime == 1:
                a1.append(int(ant1))
                a2.append(int(ant2))
            if w[8][-1] == '*':
                vec.append(0.0)
            else:
                vec.append(float(w[8]))
    # and the final one
    if len(vec) == nbl:
        t.append( sexa2dec(time) )
        r.append( avector(vec) )
    else:
        nerr = nerr + 1
    if nerr > 0:
        print "Not a regular visibility dataset, skipping %d/%d timeslots" % (nerr,ntime)

    if False:
        print "%d records" % nrec
        print "%d timeslots" % ntime
        print "%d baselines" % nbl
        print "ant1: ",a1
        print "ant2: ",a2

    return (nbl,np.array(t),np.array(r).transpose())
            

def pplot(t,p,s='ro-'):
    """add an unwrapped phase plot"""
    plt.plot(t,unwrap(p),s)

def fit1(pair,t1,p1,t2,p2):
    """for given buddy pair (1..8) grab the data for phase corr fit"""
    # get 0 based ant number for carma and sza ant
    c_an = buddy_b09[pair-1][0] - 1
    s_an = buddy_b09[pair-1][1] - 1
    #  get the phases for the CARMA and SZA buddy pair
    c_p = unwrap(p1[c_an])
    s_p = unwrap(p2[s_an])
    # reinterpolate the sza data on times of carma
    #c_p1 = interp(t1, t2,s_p)
    s_p2 = spline(t2,s_p, t1)
    # fit
    p=pylab.polyfit(s_p2,c_p,1)
    # plot
    plt.title('Antenna pair %d %d' % tuple(buddy_b09[pair-1]))
    plt.plot(s_p2,c_p,'ro',label='a=%.2f b=%.2f' % tuple(p))
    plt.plot(s_p2,pylab.polyval(p,s_p2),'-',label='Linear regression')
    plt.legend(loc='best')
    plt.xlabel('phase SZA %d' % (s_an+1))
    plt.ylabel('phase CARMA %d' % (c_an+1))
    print p

def fit4(pair,t1,p1,t2,p2):
    """for given buddy pair (1..8) grab the data for phase corr fit"""
    # get 0 based ant number for carma and sza ant
    c_an = buddy_b09[pair-1][0] - 1
    s_an = buddy_b09[pair-1][1] - 1
    #  get the phases for the CARMA and SZA buddy pair
    c_p = unwrap(p1[c_an])
    s_p = unwrap(p2[s_an])
    # reinterpolate the sza data on times of carma
    #c_p1 = interp(t1, t2,s_p)
    s_p2 = spline(t2,s_p, t1)
    # fit
    p=pylab.polyfit(s_p2,c_p,1)
    # plot
    plt.figure()
    plt.subplot(2,1,1)
    plt.title('Antenna pair %d %d' % tuple(buddy_b09[pair-1]))
    plt.plot(s_p2,c_p,'ro',label='a=%.2f b=%.2f' % tuple(p))
    plt.plot(s_p2,pylab.polyval(p,s_p2),'-',label='Linear regression')
    plt.legend(loc='best')
    plt.xlabel('phase SZA %d' % (s_an+1))
    plt.ylabel('phase CARMA %d' % (c_an+1))
    plt.subplot(2,1,2)
    plt.plot(t1,c_p,'ro',label='CARMA')
    plt.plot(t2,s_p,'bo',label='SZA')
    plt.legend(loc='best')
    plt.xlabel('time')
    plt.ylabel('phase')

def figure():
    plt.figure()
    plt.show()

def example1(file):
    (nants,t,r) = rgplist(file)
    plt.plot(t,r[4],'ro-')
    plt.plot(t,r[5],'bs-')
    plt.axis([0,24,-180,180])
    plt.savefig('example1.ps')
    plt.show()



def example2(file):
    (nants,t,r) = rgplist(file)
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

def example3(file,ant,doit=True):
    (nants,t,r) = rgplist(file)
    plt.plot(t,r[ant-1],'ro-')
    plt.show()

def example4(file1,file2,pair=1):
    """feed it a CARMA and SZA dataset"""
    (n1,t1,p1) = rgplist(file1)
    (n2,t2,p2) = rgplist(file2)
    fit4(pair,t1,p1,t2,p2)



if __name__ == '__main__':
    print "No __main__ yet, if ever...."
