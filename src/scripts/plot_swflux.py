#! /usr/bin/env python
#
#  a liberal translation of Stephen White's IDL based 'plot_swflux' script
#


import os,sys,re,string,time

try:
    import Miriad
except:
    print "I'm sorry, the Miriad module is really needed"
    os._exit(1)

try:
    import Numeric, gracePlot
    _do_grace = 1
except:
    _do_grace = 0


try:
    import ppgplot
    _do_pgplot = 1
except:
    _do_pgplot = 0

if _do_pgplot:
    print "PGPLOT available"
if _do_grace:
    print "Grace available"

# --------------------------------------------------------------------------------

help = """
       Plots recent BIMA flux measurements, (relative to planets)
       Liberally based on Stephen White's IDL based 'plot_swflux'
       Selects by source name (string abbreviations allowed)
       """

keyval = {
    'cal'    : 'cals.pfluxes',                  # calibrator file
    'src'    : '3c273',                         # source name (partial matches)
    'cut'    : '4',                             # S/3N cutoff
    'tab'    : 'false',                         # output ASCII table?
    'pgplot' : ''                               # set to a device if you want it
    }

# --------------------------------------------------------------------------------    

def ymd2day(ymd):
    """convert a date string like 'yymmmdd' to a day number
    (days since 1970.0 presumably)"""
    y = ymd[0:2]
    m = ymd[2:5]
    d = ymd[5:7]
    t1 = time.mktime(time.strptime("%s %s %s" % (y,m,d) , '%y %b %d'))/86400.0
    return t1

def get_info(calfile,src):
    """for given calibrator flux table file that is formatted like
    Flux of: 3C84     on 98MAY05 at  86.24 GHz:   5.053 Jy +/-  0.086 Jy (MARS    )
    return a tuple of arrays/lists that match a sourcename (case independant)
    in (days_since_first,flux,flux_err,freq,ymd_ascii)
    """
    r1 = re.compile( src , re.IGNORECASE)
    flux = []
    ferr = []
    freq = []
    date = []
    ymda = []
    f = open(calfile,'r')                   # open file
    line = f.readline()                            
    while line:                             # read lines
        a = line.split()
        if r1.search(a[2]):
            flux.append(string.atof(a[8]))  # columns 9,12,7,5
            ferr.append(string.atof(a[11]))
            freq.append(string.atof(a[6]))
            ymda.append(a[4])
            date.append(ymd2day(a[4]))
        line=f.readline()
    f.close()
    return date,flux,ferr,freq,ymda

def min_index(x):
    """return the index (0 based) where the minimum of
    the array is located"""
    xmin = x[0]
    idx = 0
    for i in range(1,len(x)):
        if x[i] < xmin:
            idx = i
    return idx

def get_range(t,f,e,freq,fmin,fmax,cut):
    n = 0
    for i in range(0,len(t)):
        if freq[i]<fmax and freq[i]>fmin and f[i]>0 and f[i]/e[i]>cut:
            n=n+1
    x=Numeric.arrayrange(n)
    y=Numeric.arrayrange(n)
    d=Numeric.arrayrange(n)
    n = 0
    m = 0
    for i in range(0,len(t)):
        if freq[i]<fmax and freq[i]>fmin:
            if f[i]>0 and f[i]/e[i]>cut:
                x[n] = t[i]
                y[n] = f[i]
                d[n] = e[i]
                n    = n + 1
            else:
                m = m + 1
    print "%d measurements in %g - %g GHz range (discarded %d by noise)" % (n,fmin,fmax,m)
    return n,x,y,d
        

# ----------------------------------------------------------------------------

Miriad.keyini(keyval,help,0)
cal = Miriad.keya('cal')
src = Miriad.keya('src')
cut = Miriad.keyr('cut')
tab = Miriad.keyl('tab')


if Miriad.keyprsnt('pgplot') and _do_grace and _do_pgplot:
    pgp = Miriad.keya('pgplot')
    _do_pgplot = 1
    _do_grace = 0

if __name__ == "__main__":
    date,flux,ferr,freq,ymda = get_info(cal,src)
    if len(date) > 0:
        idx = min_index(date)
        t0  = date[idx]
        d0  = ymda[idx]
        if tab:
            print '# Day (since ',ymda[idx],') Flux(Jy) FluxError(Jy) Freq(Ghz)'
            for i in range(0,len(flux)):
                print date[i]-t0,flux[i],ferr[i],freq[i]
            print '# Found ',len(date),' entries matching ',src
        else:
            print 'Found ',len(date),' entries matching ',src
    else:
        print '# Warning: no sources found to match ',src
        os._exit(1)

        
    if _do_grace:
        #  -- switch lists to arrays (should have done that to begin with) for pgplot
        t = Numeric.array(date)          # time (in days)
        t = t - t0                       # but relative to first date found
        f = Numeric.array(flux)          # flux
        e = 3*Numeric.array(ferr)        # flux errors as 3 sigma
        g = Numeric.array(freq)          # freq
        
        p = gracePlot.gracePlot()
        p.plot(t,f,e,symbols=1)
        p.title('Fluxes for ' + src)
        p.xlabel('Days since ' + d0)
        p.ylabel('Flux (Jy)')
        for r in [ [70,100],[100,120],[120,250] ]:
            n,x,y,dy = get_range(t,f,e,g,r[0],r[1],cut)
            if n:   p.plot(x,y,dy,symbols=1)
            p.hold(1)
    elif _do_pgplot:
        t = Numeric.array(date)          # time (in days)
        t = t - t0                       # but relative to first date found
        f = Numeric.array(flux)          # flux
        ppgplot.pgopen(pgp)
        ppgplot.pgenv(0,1500,0,80,0,1)
        ppgplot.pglab('Days since %s' % d0,'Flux(Jy)','Flux for %s' % src)
        ppgplot.pgpt(t,f,9)
        ppgplot.pgline(t,f)
        

