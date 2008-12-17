#!/usr/bin/env python

# pieflag.py written by Enno Middelberg 2005-2006
# enno.middelberg@csiro.au

# this version January 2006
version="1.1beta"

################################################################################
#
#
# Changes from version 1.0 to 1.1
# 
# -uses scipy, which requires Numeric, hence ppgplot needs to be
#  compiled with Numeric (will soon be replaced with numpy)
# 
# -can handle stokes types and flag single polarizations
# 
# -"-xrange"/"-yrange" command line switches replaced with "-xy"
# 
# -uses more intuitive switching between fixed scale and autoscaling
#
# -search for larger clusters of bad points now uses proper gridding and
#  convolution function from scipy (a lot faster now)
# 
# -"-long" command line options now specifies seconds, not integrations
# 
# -finding point nearest to cursor in plotting (by clicking / pressing
#  "p") now uses the distance in the plot, not in world coordinates
# 
# -works around a flaw in uvlist when more than 9 antennae are in data set
# 
# -recognizes flags from Miriad UV data sets (can be skipped with "-ignore"
# 
# 
################################################################################

# todo:
# -implement easier navigation in data sets with lots of channels (skip 10/100 channels)
# -speed up reading in spectral line data sets
#  try to read ASCII only one and then keep a binary copy?
# -read/write to AIPS data sets directly (have to wait for ParselTongue to add FG table support)

print

import sys, fileinput, string, math, os, ppgplot, Numeric, scipy

##################################################################################
# A greeting message
##################################################################################

if len(sys.argv)==1:
    print """\n
 pieflag.py written by Enno Middelberg 2005-2006 (enno.middelberg@csiro.au)
\n Task to scan UV data from Miriad data sets on a baseline- and channel-dependent
 basis for bad points.
 For outliers and data around it a flagging command is written to a text file
 (*pythonflags.csh) which can be executed to apply the flags to the data.
 The data can be inspected in a plot and flags can be interactively set and removed.
\n Usage: pieflag.py filename [options]
\n filename          is required, unless otherwise specified, it must be a Miriad data directory. Options are:\n

 General options:

 -filename name           name of Miriad data file for which the flags shall be prepared
                          defaults to uvlist file
 -uvlist                  first command-line argument already is a uvlist file
                          default is that it's a Miriad data directory and a uvlist file needs
                          to be created
 -stokes x,y[,z,..]       specify which stokes parameter/polarization to read and analyse (x) and which polarizations
                          to flag (y,z,...). For example, one can read and analyse rr and use the
                          results to flag both rr and ll by specifying -stokes rr,rr,ll.
                          The possible values are the same as for Miriad's "stokes" keyword
                          defaults to read Stokes I and to flag all polarizations
 -ignore                  ignore existing flags in Miriad data, default is to read them
 -test n m o              process only data on baseline n m, and channel o (assuming channel o is bad)
                          allows to adjust flag finding parameters more quickly as fewer data
                          need to be processed. Specify a good channel using the -goodch option
 -v                       print flagging thresholds, report on progress, print summary
 -vv                      print each flag which has been found and a lot more (you don't want this, believe me)

 Flag finding options:

 -goodch n                number of a good (relatively RFI-free) channel to which the other channels are to be compared
                          defaults to centre of band
 -cutoff n                multiples of median of difference to median in data, above which data are suspicious.
                          Will be multiplied by two to obtain a threshold above which data are certainly bad
                          defaults to 7
 -noamp                   switch off amplitude-based flagging
 -gap                     time in seconds which defines a scan gap (source changes also define scans)
                          defaults to 150
 -rmscut                  factor by which the RFI-free channel's scan-by-scan rms is to be multiplied
                          and above which data is considered bad
                          defaults to 3
 -norms                   switch off rms-based flagging

 Flag extension options:

 -long n                  width of running sum window in seconds in which to calculate fraction of flagged visibilities
                          1200 is reasonable for weak sources, 600 for calibrator observations
                          defaults to 1200
 -thres n                 fraction of maximum of running sum, defines threshold above which data are deemed bad
                          in search for large clusters of bad points
                          defaults to 0.15
 -noshort                 don't flag short (+-60s) sections around bad points
                          this effectively turns off amplitude-based flagging because amplitude-
                          based flagging does not generate flags directly
 -nolong                  don't search for larger clusters of points

 Plotting options:
 (press h in plotting window for a list of shortcuts)
 
 -noplot                  skip plotting and interactive flagging
 -xy xmin,xmax,ymin,ymax  define initial plotting range (x in h, y in amplitude)\n"""

    sys.exit()


##################################################################################
# Read command line options
##################################################################################

goodch=9
if "-goodch" in sys.argv:
    i=sys.argv.index("-goodch")
    goodch=int(sys.argv[i+1])
    print " Found goodch = %i" % goodch

cutoff=7
if "-cutoff" in sys.argv:
    i=sys.argv.index("-cutoff")
    cutoff=float(sys.argv[i+1])
    print " Found cutoff = %2.1f" % cutoff

filename=sys.argv[1]
if "-filename" in sys.argv:
    i=sys.argv.index("-filename")
    filename=sys.argv[i+1]
    print " Will prepare flags for file "+filename

# number of integrations over which to look for noisy RFI
long=1200.0
if "-long" in sys.argv:
    i=sys.argv.index("-long")
    long=float(sys.argv[i+1])
    print " Found window long = %i " % long

# threshold to use
threshold=0.15
if "-thres" in sys.argv:
    i=sys.argv.index("-thres")
    threshold=float(sys.argv[i+1])
    print " Found threshold = %3.2f" % threshold

# gap which separates scans [seconds]
gap=150.0
if "-gap" in sys.argv:
    i=sys.argv.index("-gap")
    gap=float(sys.argv[i+1])
    print " Found gap = %3.2f" % gap

# cutoff to use in rms-based flagging
rmscut=3.0
if "-rmscut" in sys.argv:
    i=sys.argv.index("-rmscut")
    rmscut=float(sys.argv[i+1])
    print " Found rmscut = %3.2f" % rmscut

# test mode? if so, get the baseline
if "-test" in sys.argv:
    i=sys.argv.index("-test")
    ant1=int(sys.argv[i+1])
    ant2=int(sys.argv[i+2])
    badch=int(sys.argv[i+3])

# check for stokes parameters
stokesread="i"
stokesflag="i"
if "-stokes" in sys.argv:
    i=sys.argv.index("-stokes")
    l=string.split(sys.argv[i+1], ",")
    stokesread=l[0]
    stokesflag=string.join(l[1:], ",")
    print " Will read and analyse stokes %s and flag stokes %s" % (stokesread, stokesflag)


##################################################################################
# Functions
##################################################################################

# Function to work out avg, sx and sigmax from a list of numbers
def stat(numbers):
    sum=0

    # Calculate median
    numbers.sort()
    if (len(numbers) % 2)==1:
        median=numbers[(len(numbers)-1)/2]
    else:
        median=(numbers[(len(numbers)/2)-1]+numbers[(len(numbers)/2)])/2

    # Calculate avg, sx and sigmax
    if len(numbers)>1:
        for i in numbers:
            sum=sum+i
            # Store total sum for later
            total=sum
        avg=sum/len(numbers)
        sum=0
        for i in numbers:
            sum=sum+(i-avg)**2
        sx=math.sqrt(sum/(len(numbers)-1))

        # calculate median of difference to median
        diff=[]
        for i in numbers:
            diff.append(abs(median-i))
        diff.sort()
        if (len(diff) % 2)==1:
            diffmed=diff[(len(diff)-1)/2]
        else:
            diffmed=(diff[(len(diff)/2)-1]+diff[(len(diff)/2)])/2
        
    else:
        avg=numbers[0]
        sx=0
        median=numbers[0]
        diffmed=0
    # Return results
    return avg, sx, median, diffmed

def rectangle_stats(xarray, yarray, x1, x2, y1, y2):
        xcopy=[]
        ycopy=[]
        for i in range(len(xarray)):
                if x1<=xarray[i]<=x2 and y1<=yarray[i]<=y2:
                        xcopy.append(xarray[i])
                        ycopy.append(yarray[i])
        n=len(xcopy)
        xstat=stat(xcopy)
        ystat=stat(ycopy)
        return(xstat, ystat, n)

# Function to convert seconds to hh:mm:ss.ss format, returns a string
def time2hms(seconds):
    h=int(seconds/3600)
    m=int(seconds % 3600)/60
    s=seconds-(h*3600)-(m*60)
    h=`h`
    m=`m`
    s="%4.2f" % s
    hms=h.zfill(2)+":"+m.zfill(2)+":"+s.zfill(4)
    return hms


# Function to plot and edit data
def plotit(xarray, yarray, xlabel, ylabel, title, xsusparray, ysusparray, \
           xflagarray, yflagarray, yavg, yoff, mode, selfscale, xy):
    # print "\n Processing %i points" % len(xarray)

    if selfscale==1:
        action=(0,0, "s")
    else:
        action=(0,0, "")
    ppgplot.pgask(0)
    pttype=1
    susptyp=2
    flagtyp=5
    ppgplot.pgscr(30, 1, 1, 0)
    ppgplot.pgscr(10, 1, 0, 0)
    ppgplot.pgscr(1, 1, 1, 1)
    refresh=0

    # evaluate the last keystroke
    # x   - continue with next baseline
    # q   - quit plotting and write flagging commands
    # " " - next channel
    # <   - previous source
    # >   - next source
    # .   - next channel
    # ,   - previous channel
    # ?   - plot all sources
    # -   - refresh screen (intended for internal use only)

    while not (action[2]=="x" or action[2]=="q" or action[2]==" " or \
           action[2] in ants or action[2]=="<" or action[2]==">" or \
           action[2]=="." or action[2]=="," or action[2]=="?" or action[2]=="-"):

        # switch between flagging data (=1) and unflagging data (=-1)
        if action[2]=="u":
            mode=mode*(-1)

        # switch between fixed scale and selfscale
        if action[2]=="f":
            selfscale=selfscale*(-1)

        xmin=xy[0]
        xmax=xy[1]
        ymin=xy[2]
        ymax=xy[3]

        # find plot boundaries in selfscaling
        if action[2]=="s" and selfscale==1:
            xmin=xarray[0]
            xmax=xarray[0]
            for i in xarray:
                    if i<xmin:
                            xmin=i
                    if i>xmax:
                            xmax=i
            ymin=yarray[0]
            ymax=yarray[0]
            for i in yarray:
                    if i<ymin:
                            ymin=i
                    if i>ymax:
                            ymax=i
            for i in ysusparray:
                    if i<ymin:
                            ymin=i
                    if i>ymax:
                            ymax=i
            for i in yflagarray:
                    if i<ymin:
                            ymin=i
                    if i>ymax:
                            ymax=i
            # Store data for later use
            dataxmin=xmin
            dataxmax=xmax
            dataymin=ymin
            dataymax=ymax
            xy=[xmin, xmax, ymin, ymax]
            # add and subtract 5% as extra margin
            xmin=xmin-0.05*(xmax-xmin)
            xmax=xmax+0.05*(xmax-xmin)
            # add and subtract 5% as extra margin
            ymin=ymin-0.05*(ymax-ymin)
            ymax=ymax+0.05*(ymax-ymin)
            # print "\n New plot dimensions: xmin=%.1f, xmax=%.1f, ymin=%.1f, ymax=%.1f" % (xmin, xmax, ymin, ymax)

        # if a hardcopy is requested, close online window, reset some parms,
        # generate a Postscript file and exit
        if action[2]=="m":
            print """ Copy of current screen saved to screen.ps.
Unflagged data are plotted as dots, suspicious data as pluses,
and flagged data as crosses.\n"""
            ppgplot.pgclos()
            ppgplot.pgopen("screen.ps/PS")
            ppgplot.pgsch(1.2)

        # initialize plot window
        ppgplot.pgeras()
        ppgplot.pgswin(xmin, xmax, ymin, ymax)
        ppgplot.pgtbox("ABCHNSTZ", 0, 0, "ABCNST", 0, 0)
        ppgplot.pglab(xlabel, ylabel, title)

        # plot data and a tick for the average
        ppgplot.pgpt(xarray, yarray, pttype)
        if not ("-noamp" in sys.argv):
            xnum=Numeric.array([(xmin+0.98*(xmax-xmin)), xmax])
            ynum=Numeric.array([yavg, yavg])
            txt="med"
            ppgplot.pgline(xnum, ynum)
            if (ymax-ymin)!=0:
                ppgplot.pgmtxt("RV", 1.0, ((yavg-ymin)/(ymax-ymin)), 0.0, txt)

        # suspect points are drawn as yellow crosses
        ppgplot.pgsci(30)
        ppgplot.pgpt(xsusparray, ysusparray, susptyp)

        # indicate cutoff levels with extra ticks on left
        if not ("-noamp" in sys.argv):
            xnum=Numeric.array([(xmin+0.98*(xmax-xmin)), xmax])
            ynum=Numeric.array([yavg+yoff, yavg+yoff])
            ppgplot.pgline(xnum, ynum)
            txt=`cutoff`+"\\(0644)"
            if (ymax-ymin)!=0:
                ppgplot.pgmtxt("RV", 1.0, ((yavg+yoff-ymin)/(ymax-ymin)), 0.0, txt)
            xnum=Numeric.array([(xmin+0.98*(xmax-xmin)), xmax])
            ynum=Numeric.array([yavg-yoff, yavg-yoff])
            ppgplot.pgline(xnum, ynum)
            txt="-"+`cutoff`+"\\(0644)"
            if (ymax-ymin)!=0:
                ppgplot.pgmtxt("RV", 1.0, ((yavg-yoff-ymin)/(ymax-ymin)), 0.0, txt)

        # flagged points are drawn as red asterisks
        ppgplot.pgsci(10)
        ppgplot.pgpt(xflagarray, yflagarray, flagtyp)

        # indicate 2*cutoff level with extra tick on left
        if not ("-noamp" in sys.argv):
            xnum=Numeric.array([(xmin+0.98*(xmax-xmin)), xmax])
            ynum=Numeric.array([yavg+2*yoff, yavg+2*yoff])
            ppgplot.pgline(xnum, ynum)
            txt=`2*cutoff`+"\\(0644)"
            if (ymax-ymin)!=0:
                ppgplot.pgmtxt("RV", 1.0, ((yavg+2*yoff-ymin)/(ymax-ymin)), 0.0, txt)
            xnum=Numeric.array([(xmin+0.98*(xmax-xmin)), xmax])
            ynum=Numeric.array([yavg-2*yoff, yavg-2*yoff])
            ppgplot.pgline(xnum, ynum)
            txt="-"+`2*cutoff`+"\\(0644)"
            if (ymax-ymin)!=0:
                ppgplot.pgmtxt("RV", 1.0, ((yavg-2*yoff-ymin)/(ymax-ymin)), 0.0, txt)

        # reset colur to white for upcoming plots
        ppgplot.pgsci(1)

        # add whether we're flagging or unflagging
        if mode==1:
            ppgplot.pgmtxt("B", 3, 0, 0, "flagging data")
        elif mode==-1:
            ppgplot.pgmtxt("B", 3, 0, 0, "unflagging data")

        # add whether we're self-scaling or not
        if selfscale==-1:
            ppgplot.pgmtxt("B", 3, 1, 1.0, "scale fixed")
        else:
            ppgplot.pgmtxt("B", 3, 1, 1.0, "scale variable")

        # if hardcopy was requested, close file and exit
        if action[2]=="m":
            ppgplot.pgclos()
            sys.exit()

        # start flagging
        action=ppgplot.pgband(7, 0, 0, 0)

        # report nearest data point
        if action[2]=="p" or action[2]=="P":
            deltax=(xmax-xmin)
            deltay=(ymax-ymin)
            x1=action[0]
            y1=action[1]
            min=1.0
            for i in range(len(xarray)):
                dist=math.sqrt(((xarray[i]-x1)/deltax)**2+((yarray[i]-y1)/deltay)**2)
                if dist<min:
                    min=dist
                    index=i
            for i in range(len(bsldata[bsl])):
                if xarray[index]==bsldata[bsl][i][0]:
                    break
            t=time2hms(bsldata[bsl][i][0])
            s=bsldata[bsl][i][5]
            print " Nearest data point: ",t, "source:", s, "amplitude: %4.3f " % yarray[index]

        # delete above horizontal line
        if action[2]=="a":
            ylim=action[1]
            print " Flagged above y=%f" % ylim
            xcopy=[]
            ycopy=[]
            for i in range(len(yarray)):
                if yarray[i]<=ylim:
                    xcopy.append(xarray[i])
                    ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # delete below horizontal line
        if action[2]=="b":
            ylim=action[1]
            print " Flagged below y=%f" % ylim
            xcopy=[]
            ycopy=[]
            for i in range(len(yarray)):
                if yarray[i]>=ylim:
                    xcopy.append(xarray[i])
                    ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # delete right of vertical line
        if action[2]=="r":
            xlim=action[0]
            print " Flagged right of x=%f" % xlim
            xcopy=[]
            ycopy=[]
            for i in range(len(xarray)):
                if xarray[i]<=xlim:
                    xcopy.append(xarray[i])
                    ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # delete left of vertical line
        if action[2]=="l":
            xlim=action[0]
            print " Flagged left of x=%f" % xlim
            xcopy=[]
            ycopy=[]
            for i in range(len(xarray)):
                if xarray[i]>=xlim:
                    xcopy.append(xarray[i])
                    ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # delete inside or outside of rectangle
        if action[2]=="c" or action[2]=="k":
            key=action[2]
            (x1, x2, y1, y2)=get_rectangle(action[0], action[1])
            xcopy=[]
            ycopy=[]
            if key=="c":
                for i in range(len(xarray)):
                    if not (x1<=xarray[i]<=x2 and y1<=yarray[i]<=y2):
                        xcopy.append(xarray[i])
                        ycopy.append(yarray[i])
            if key=="k":
                for i in range(len(xarray)):
                    if x1<=xarray[i]<=x2 and y1<=yarray[i]<=y2:
                        xcopy.append(xarray[i])
                        ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # zoom in
        if action[2]=="z":
            xy[0], xy[1], xy[2], xy[3]=get_rectangle(action[0], action[1])
            # print "\n New plot dimensions: xmin=%.1f, xmax=%.1f, ymin=%.1f, ymax=%.1f" % (xmin, xmax, ymin, ymax)
            # clear "action" or last click it will be evaluated in next loop
            action=(0,0,"")

        # delete nearest point (click left=="A")
        if action[2]=="o" or action[2]=="A":
            deltax=(xmax-xmin)
            deltay=(ymax-ymin)
            x1=action[0]
            y1=action[1]
            min=1.0
            for i in range(len(xarray)):
                dist=math.sqrt(((xarray[i]-x1)/deltax)**2+((yarray[i]-y1)/deltay)**2)
                if dist<min:
                    min=dist
                    index=i
            xcopy=[]
            ycopy=[]
            for i in range(len(xarray)):
                if i!=index:
                    xcopy.append(xarray[i])
                    ycopy.append(yarray[i])
            xarray=Numeric.array(xcopy)
            yarray=Numeric.array(ycopy)
            # refresh display
            action=(0,0,"-")

        # stats inside rectangle
        if action[2]=="t":
            (x1, x2, y1, y2)=get_rectangle(action[0], action[1])
            (xstat, ystat, n)=rectangle_stats(xarray, yarray, x1, x2, y1, y2)
            print "\n Statistics of %i points in rectangle xmin=%.1f, xmax=%.1f, ymin=%.1f, ymax=%.1f" % (n, x1, x2, y1, y2)
            print "\n x: avg(x)=%f, rms=%f, median=%f" % (xstat[0], xstat[1], xstat[2])
            print " y: avg(x)=%f, rms=%f, median=%f\n" % (ystat[0], ystat[1], ystat[2])

        # stats inside viewport
        if action[2]=="v":
            (xstat, ystat, n)=rectangle_stats(xarray, yarray, xmin, xmax, ymin, ymax)
            print "\n Statistics of %i points in viewport xmin=%.1f, xmax=%.1f, ymin=%.1f, ymax=%.1f" % (n, xmin, xmax, ymin, ymax)
            print "\n x: avg(x)=%f, rms=%f, median=%f" % (xstat[0], xstat[1], xstat[2])
            print " y: avg(x)=%f, rms=%f, median=%f\n" % (ystat[0], ystat[1], ystat[2])

        # histogram of y
        if action[2]=="j":
            inp=raw_input(" Number of bins: ")
            nbins=int(inp)
            ppgplot.pgeras()
            length=len(yarray)
            ppgplot.pghist(length, yarray, dataymin, dataymax, nbins, 0)
            ppgplot.pgband(2,0,0,0)

        # print help
        if action[2]=="h":
            print_help()
    return xarray, yarray, action[2], mode, selfscale, xy


def get_rectangle(x1, y1):
        action=ppgplot.pgband(2, 0, x1, y1)
        x2=action[0]
        y2=action[1]
        if x2<x1:
                i=x1
                x1=x2
                x2=i
        if y2<y1:
                i=y1
                y1=y2
                y2=i
        return (x1, x2, y1, y2)

# print help
def print_help():
        print """
        \n Your choices:  

        h  - print this message

        ---- Change plot ----
        z  - zoom in
        s  - re-scale
     space - next baseline
     1...6 - advance to next baseline with antenna
        ,. - next/previous channels   
        <> - next/previous source
        ?  - select all sources
        f  - toggle fixed/variable scale
        m  - save a hardcopy to \"screen.ps\" and exit

        ---- Flagging ----
        u  - toggle flagging/unflagging of data
        a  - select above
        b  - select below
        l  - select to left
        r  - select to right
        c  - select rectangle
        k  - select outside rectangle
    o, MB1 - select nearest point

        ---- Analyze data ----
        p  - print nearest point
        t  - statistics of points in rectangle
        j  - plot histogram of y data
             (give number of bins on console)

        ---- Exit ----
        x  - exit and write flags   
        q  - quit program, don't write flags\n"""

# wait for keystroke
def pause():
    x=raw_input("Press enter to continue ")
    return x

def vprint(x):
    if ("-v" in sys.argv) or ("-vv" in sys.argv):
        print x

def vvprint(x):
    if ("-vv" in sys.argv):
        print x
    
##################################################################################
# Preliminaries
##################################################################################

# default mode when plotting is to flag data
mode=1

# this controls modes of self-scaling and using fixed scales
selfscale=1
if "-xy" in sys.argv:
    selfscale=-1
    i=sys.argv.index("-xy")
    xy=string.split(sys.argv[i+1], ",")
    if len(xy)!=4:
        print " Not enough parameters to fix the plotting range with -xy. Reverting to selfscale"
        xy=[0,0,0,0]
        selfscale=1
    else:
        xmin=3600*float(xy[0])
        xmax=3600*float(xy[1])
        ymin=float(xy[2])
        ymax=float(xy[3])
        xy=[xmin, xmax, ymin, ymax]
else:
    xy=[0,0,0,0]


# list of antennas, needed for navigating the plotting subroutine
ants=['1', '2', '3', '4', '5', '6']

##################################################################################
# Program starts
##################################################################################

########################################
# read data from file and sort it out
########################################

# if "-uvlist" flag is set, filename specifies an existing uvlist file
# else, it specifies a Miriad data directory and uvlist_em needs to be executed
if not ("-uvlist" in sys.argv):
    print " Converting Miriad data to uvlist..."
    command="uvlist_em vis="+sys.argv[1]+" options=data,source,full recnum=1e9 log="+sys.argv[1]+".uvlist stokes=%s" % stokesread
#    command="uvlist_em vis="+sys.argv[1]+" options=data,source,full stokes=i recnum=1e9 log="+sys.argv[1]+".uvlist \"select=ant(1)(2)\" line=ch,2,2"
    os.system(command)
    sys.argv[1]=sys.argv[1]+".uvlist"
    
# read data from file and store in "data"
print " Reading in the data from "+sys.argv[1]+"..."
input=[]

# read data
for x in fileinput.input(sys.argv[1]):
    if x!="\n" and not ("RA:" in x) and not ("DEC:" in x) and not ("Vis" in x):
        input.append(x+" ")

print " Sorting out useless overhead... ",

list=[]
x=5
while x<len(input):
    if input[x][0:1]=="|":
        list.append(input[x][0:-2])
        x=x+1
        list.append(input[x][0:-2])
        x=x+1
        while x<len(input) and not ("Source:" in input[x]):
            list[-1]=list[-1]+input[x][0:-2]+" "
            x=x+1
        list.append(input[x][0:-2])
    x=x+1
print "%i data points remaining" % (len(list)/3)

########################################
# convert ASCII to numbers
########################################

# determine number of channels from second element in list
nchan=len(string.split(list[1]))/3
print " Number of channels: %i" % nchan

# if no good channel was specified on command line, choose centre channel
if not "-goodch" in sys.argv:
    print "\n ##### WARNING"
    print " You didn't specify a good channel, hence I'm using the centre channel. Sure this is good?"
    goodch=int(nchan/2)

# make a list with one zero for each channel
zero=[]
for x in range(nchan):
    zero.append(0)

print " Converting ASCII into numbers..."
if "-ignore" in sys.argv:
    print " (Ignoring existing flags)"

data=[]
baselines=[]
sources=[]
firstline=1
for x in range(0,len(list),3):
    # the first out of three lines has some metadata...
    # need to introduce a space around dashes separating antenna numbers
    j=string.replace(list[x], "-", " - ")
    a=string.split(j)

    # the second the channel amplitudes & phases...
    b=string.split(list[x+1])

    #  and the third the source name
    src=string.split(list[x+2])[1]

    # I used to insist that the header line has 9 items, but with many antennae
    # (VLA data), antenna numbers are no longer separated by space, and there are
    # only 8 items. Hence this test was skipped
    # if len(a)<>9 or len(b)<>3*nchan:
    if len(b)<>3*nchan:
        print "##### FATAL ERROR:"
        print "couldn't read some data - it's unlikely this will work as desired, exiting."
        print a
        print b
        sys.exit()
    # snip the time
    time=a[5]
    # if this is the first line of the uvlist file, keep the date for later
    if firstline==1:
        yr1=time[0:2]
        mon1=time[2:5]
        day1=time[5:7]
        firstline=-1
    # yr, mon and day are used later when the flagging commands are written to disk
    yr=time[0:2]
    mon=time[2:5]
    day=time[5:7]
    ndays=0
    if firstline==-1 and day!=day1:
        ndays=1
    # convert the time into seconds of UT
    hh=int(time[8:10])
    mm=int(time[11:13])
    ss=int(time[14:16])
    UT=3600*hh+60*mm+ss+ndays*86400
    # store baseline and source name
    bsl=[int(a[2]), int(a[4])]
    if bsl not in baselines:
        baselines.append(bsl)
    if src not in sources:
        sources.append(src)
    # append the channel data and test for existing flags
    ch=[]
    flags=[]
    f=3.0
    if "-ignore" in sys.argv:
        f=0
    for y in range(1,3*nchan,3):
        # test for flags
        if b[y+1][-1:]!="*":
            flags.append(0)
        else:
            flags.append(f)
        # add data
        try:
            ch.append(float(b[y]))
        except ValueError:
            ch.append(-1.0)
            print " \"*******\" in uvlist file replaced by -1"
    # store everything in a list
    # if we're in testing mode,  keep only one baseline
    if "-test" in sys.argv:
        if (ant1 in bsl) and (ant2 in bsl):
            d=[ch[goodch-1], ch[badch-1]]
            data.append([UT, bsl, d, zero[:], flags[:], src])
    else:
        data.append([UT, bsl, ch, zero[:], flags[:], src])

########################################
# Bring data into time order
########################################

print(" Sorting data ...")
data.sort()

if data[-1][0]-data[0][0]>86400:
    print "\n ##### FATAL ERROR:"
    print " Your data set spans more than two UT days, which I cannot handle."
    print " Please break it up into smaller pieces. Exiting.\n"
    sys.exit()

if "-test" in sys.argv:
    baselines=[[ant1, ant2]]
    nchan=2
    goodch=1
    
# Some output for the user's delight
baselines.sort()
print " Found %i baselines:" % len(baselines)
print " ",baselines

print " Found %i sources:" % len(sources)
print " ",sources

# The last date marks the date on which observations ended. Keep it for later
yr2=yr
mon2=mon
day2=day

print " Observations started on ", yr1, mon1, day1
print " Observations ended on   ", yr2, mon2, day2


########################################
# sort data by baseline
########################################

# make a list with as many empty sublists as there are baselines
bsldata=[]
for x in range(len(baselines)):
    bsldata.append([])

# then sort the data into these empty slots
for x in data:
    i=baselines.index(x[1])
    bsldata[i].append(x)


# guess integration time from baseline 0, channel 0
y=[]
for x in range(1, len(bsldata[0])):
    y.append(bsldata[0][x][0]-bsldata[0][x-1][0])
inttime=stat(y)[2]

print " I am guessing that the integration time is %3.2f seconds" % inttime


##################################################################################
# Look for bad points
##################################################################################

####################################################
# determine avg, rms, median for amplitude flagging
####################################################

if not ("-noamp" in sys.argv):

    # Now calculate the rms of one good channel on each baseline
    print " Calculating statistics of channel %i on each baseline... " % goodch


    bslavg=[]
    for x in baselines:
        bslavg.append([])

    # loop over baselines
    for x in range(len(bsldata)):
        # on each baseline, initialize a list with as many sublists as there are sources
        l=[]
        for z in sources:
            l.append([])
        # sort out which source we're dealing with and store the data from goodch
        for y in range(len(bsldata[x])):
            src=bsldata[x][y][5]
            i=sources.index(bsldata[x][y][5])
            l[i].append(bsldata[x][y][2][goodch-1])
        # calculate the statistics to determine the levels at which data are good, bad, or ugly
        # this approach looks at the median of the data and at the multiple of the median of the difference to it
        for z in l:
            rms=stat(z)
            high   =rms[2]+cutoff*rms[3]
            low    =rms[2]-cutoff*rms[3]
            toohigh=rms[2]+2*cutoff*rms[3]
            toolow =rms[2]-2*cutoff*rms[3]
            bslavg[x].append([rms[2], rms[3], rms[2], high, low, toohigh, toolow])

    if "-v" in sys.argv:
        for bsl in range(len(baselines)):
            print "\n Baseline %s" % baselines[bsl]
            print " Src.   avg.     rms      median   high      low      toohigh   toolow"
            for src in range(len(sources)):
                print sources[src],
                for y in range(len(bslavg[bsl][src])):
                    print "%5.4f  " % bslavg[bsl][src][y],
                print


    ########################################
    # search for outliers
    ########################################

    print "\n"
    # loop over baselines
    for bsl in range(len(bsldata)):
        vprint(" Scanning for outliers on baseline %i-%i" % \
               (baselines[bsl][0], baselines[bsl][1]))
        # check out each data point; look up source-specific constraints
        for y in range(len(bsldata[bsl])):
            s=bsldata[bsl][y][5]
            src=sources.index(s)
            # once source and baseline are determined, check each channel against reference
            for ch in range(nchan):
                high   =bslavg[bsl][src][3]
                low    =bslavg[bsl][src][4]
                toohigh=bslavg[bsl][src][5]
                toolow =bslavg[bsl][src][6] 
                if toohigh>bsldata[bsl][y][2][ch]>high or toolow<bsldata[bsl][y][2][ch]<low:
                    bsldata[bsl][y][3][ch]=1
                    # if "-vv" in sys.argv:
                    #     print "Bad:  %5.4f in channel %i on baseline" % (bsldata[bsl][y][2][ch], ch),
                    #     print baselines[bsl],"looking at ",sources[src]
                if bsldata[bsl][y][2][ch]>toohigh or bsldata[bsl][y][2][ch]<toolow:
                    bsldata[bsl][y][3][ch]=2
                    # if "-vv" in sys.argv:
                    #     print "Ugly: %5.4f in channel %i on baseline" % (bsldata[bsl][y][2][ch], ch),
                    #     print baselines[bsl],"looking at ",sources[src]

    print


####################################################
# determine avg, rms, median for rms flagging
####################################################

if not ("-norms" in sys.argv):

    """The result of this part is the list bslrms, which contains the
    median amplitude rms for each source on each baseline. The rms is
    calculated for each 'scan', divided by either a source change or a gap
    of a certain length. bslrms is a list with the following format:

    bslrms[baseline][source][median rms, [list of rms from which median was computed]]""" 


    # Now calculate the rms of one good channel on each baseline
    print " Calculating scanwise statistics of channel %i on each baseline... " % goodch

    bslrms=[]
    for x in baselines:
        bslrms.append([])

    # loop over baselines
    for bsl in range(len(bsldata)):

        # on each baseline, find gaps in the data caused by source changes
        # or just gaps in time
        # generate list with as many sublists as sources
        l=[]
        for z in sources:
            l.append([])

        # find index of first source observed and add time to l
        y=0
        i=sources.index(bsldata[0][1][5])
        l[i].append(0)

        # then compare the remaining data pairwise
        y=1
        while y<len(bsldata[bsl]):
            if bsldata[bsl][y][5]!=bsldata[bsl][y-1][5] or abs(bsldata[bsl][y][0]-bsldata[bsl][y-1][0])>gap:
                i=sources.index(bsldata[bsl][y-1][5])
                l[i].append(y-1)
                i=sources.index(bsldata[bsl][y][5])
                l[i].append(y)
            y=y+1

        # find index of last source observed and add time to l
        i=sources.index(bsldata[bsl][-1][5])
        l[i].append(y-1)
        # print l
        # for x in range(0, len(l[0]), 2):
        #     print time2hms(bsldata[bsl][l[0][x]][0]),  time2hms(bsldata[bsl][l[0][x+1]][0])

        # Chop up too large pieces
        for x in range(len(l)):
            # print l[x]
            # looping backwards over index list so newly inserted indices won't affect
            # rest of the loop
            for y in range(len(l[x])-2, -2, -2):
                dur=bsldata[bsl][l[x][y+1]][0]-bsldata[bsl][l[x][y]][0]
                # print time2hms(bsldata[bsl][l[x][y]][0]), time2hms(bsldata[bsl][l[x][y+1]][0]),
                # print "Duration: %f seconds" % dur,
                n_piec=dur/gap
                # only do anything if there is at least one cut to be made
                if n_piec>1:
                    # print "Chopping it %f times" % n_piec
                    n=(float(l[x][y+1])-float(l[x][y]))/int(n_piec)
                    for z in range(int(n_piec)-1, 0, -1):
                        l[x].insert(y+1, int(l[x][y]+z*n)+1)
                        l[x].insert(y+1, int(l[x][y]+z*n))
                        # print l[x]
        # print l
        # for x in range(0, len(l[0]), 2):
        #     print time2hms(bsldata[bsl][l[0][x]][0]),  time2hms(bsldata[bsl][l[0][x+1]][0])
        # sys.exit()

        # now do the real work
        # first, calculate rms in each of these blocks
        for src in range(len(sources)):
            rmslist=[]
            for z in range(0, len(l[src]), 2):
                k=[]
                for j in range(l[src][z], l[src][z+1]+1):
                    k.append(bsldata[bsl][j][2][goodch-1])
                rms=stat(k)
                rmslist.append(rms[1])

            # calculate the median rms and store it in bslrms
            t=rmslist[:]
            medrms=stat(rmslist)
            bslrms[bsl].append([medrms[2], t])

        if '-v' in sys.argv:
            print "\n Reference rms on baseline ",baselines[bsl]
            print " Source     med rms    rms values in channel %i" % (goodch)
            for src in range(len(sources)):
                print "%s  %5.4f    " % (sources[src], bslrms[bsl][src][0]),
                for x in bslrms[bsl][src][1]:
                    print"%5.4f  " % x,
                print
        
        # second, inspect all other channels for outliers
        # we're already looping over baselines
        vvprint("\n Baseline %i-%i" % (baselines[bsl][0], baselines[bsl][1]))
        # loop over channels
        for ch in range(nchan):
            vvprint(" channel %i" % (ch+1))
            # loop over sources
            for src in range(len(sources)):
                vvprint(" source %s" % sources[src])
                rmslist=[]
                # calculate rms of each scan
                for x in range(0, len(l[src]), 2):
                    k=[]
                    for y in range(l[src][x], l[src][x+1]+1):
                        k.append(bsldata[bsl][y][2][ch])
                    rms=stat(k)
                    vvprint(" rms=%5.4f, rmscut=%5.4f, bslrms[bsl][src][0]=%5.4f" % (rms[1], rmscut, bslrms[bsl][src][0]))
                    if rms[1]>rmscut*bslrms[bsl][src][0]:
                        vvprint(" flagged scan due rms=%5.4f: baseline %s-%s, channel %i, %s-%s, source %s" % \
                               (rms[1], baselines[bsl][0], baselines[bsl][1], (ch+1), \
                                time2hms(bsldata[bsl][l[src][x]][0]), time2hms(bsldata[bsl][l[src][x+1]][0]), \
                                bsldata[bsl][l[src][x]][5]))
                        for y in range(l[src][x], l[src][x+1]+1):
                            bsldata[bsl][y][3][ch]=1
                            bsldata[bsl][y][4][ch]=3

##################################################################################
# Extrapolation of flags
##################################################################################

########################################
# look for small clusters of points
########################################

if not ("-noshort" in sys.argv):

    print "\n Searching small clusters of bad points"

    # now slide a 1-min window over each baseline and channel and decide what to flag
    # loop over bsldata
    for bsl in range(len(bsldata)):
        vprint(" Processing baseline %i-%i" % \
               (baselines[bsl][0], baselines[bsl][1]))
        # loop over channels
        for channel in range(len(bsldata[bsl][0][2])):
            # starting at each data point...
            for y in range(len(bsldata[bsl])-5):
                flagsum=0
                # ...sum the flags of the next six integrations
                for z in range(6):
                    #vvprint(" channel %i, time=%s, source=%s, bad/ugly=%5.4f" \
                    #        % (channel, time2hms(bsldata[bsl][y+z][0]), bsldata[bsl][y+z][5], bsldata[bsl][y+z][3][channel]))
                    flagsum=flagsum+bsldata[bsl][y+z][3][channel]
                #vvprint("----------")
                # if the sum of the flags exceeds a limit, make a note
                # starting with the current data point
                if flagsum>=2:
                    vvprint("too many bad points within a minute, flag it")
                    bsldata[bsl][y][4][channel]=3
                    # and continuing with the next six, if there isn't a gap in time exceeding 1 min = 60 seconds
                    for z in range(6):
                        if abs(bsldata[bsl][y+z][0]-bsldata[bsl][y][0])<=60:
                            bsldata[bsl][y+z][4][channel]=3


########################################
# look for larger clusters
########################################

if not ("-nolong" in sys.argv):

    print "\n Searching for larger clusters of bad points"
    x=int(long/30.0)
    y=int(30.0/inttime)
    convmax=x*y*3
    vprint(" The maximum of the convolution is %i" % convmax)
    vprint(" Will flag if convolution exceeds %i" % (convmax*threshold))

    # loop over baselines
    for bsl in range(len(bsldata)):
        vprint(" Processing baseline %i-%i" % \
               (baselines[bsl][0], baselines[bsl][1]))

        # loop over channels
        for ch in range(nchan):

            # grid flags into 30s-bins
            # make a list of bins
            elapsed=bsldata[bsl][-1][0]-bsldata[bsl][0][0]
            nbins=int(elapsed/30.0)+1
            flags=[]
            for x in range(nbins):
                flags.append(0)

            # sort data into bins
            for x in range(len(bsldata[bsl])):
                bin=int((bsldata[bsl][x][0]-bsldata[bsl][0][0])/30.0)
                flags[bin]=flags[bin]+bsldata[bsl][x][4][ch]

            # define smoothing kernel
            kernel=[]
            for x in range(int(long/30)):
                kernel.append(1)

            # convolve with smoothing kernel
            smoo=scipy.convolve(flags, kernel, 1)

            # now un-grid the smoothed flags back to the data
            y=threshold*convmax
            for x in range(len(bsldata[bsl])):
                bin=int((bsldata[bsl][x][0]-bsldata[bsl][0][0])/30.0)
                if smoo[bin]>y:
                    bsldata[bsl][x][4][ch]=3

    # print some data
    if "-vv" in sys.argv:
        for bsl in range(len(baselines)):
            print baselines[bsl]
            for y in range(len(bsldata[bsl])):
                print bsldata[bsl][y][0],
                for ch in range(len(bsldata[bsl][y][2])):
                      print "%4.3f  " % bsldata[bsl][y][2][ch],
                for ch in range(len(bsldata[bsl][y][2])):
                      print "%i " % bsldata[bsl][y][3][ch],
                print "  ",
                for ch in range(len(bsldata[bsl][y][2])):
                      print "%i " % bsldata[bsl][y][4][ch],
                print bsldata[bsl][y][5]

################################################
# print a summary of how much has been flagged
################################################

print " Computing fraction of flagged visibilities...\n"

flagchan=[]
for bsl in range(len(baselines)):
    flagchan.append([])
    for ch in range(nchan):
        n_ch=0.0
        for x in range(len(bsldata[bsl])):
           if bsldata[bsl][x][4][ch]!=0:
               n_ch=n_ch+1
        flagchan[bsl].append([n_ch, len(bsldata[bsl])])

totvis=0
totflg=0
print " Bsl.  channel 1...%i" % nchan
for bsl in range(len(baselines)):
    print baselines[bsl],
    vis=0
    flg=0
    for ch in range(nchan):
        print "%3.2f  "% (flagchan[bsl][ch][0]/flagchan[bsl][ch][1]),
        vis=vis+flagchan[bsl][ch][1]
        flg=flg+flagchan[bsl][ch][0]
        totvis=totvis+flagchan[bsl][ch][1]
        totflg=totflg+flagchan[bsl][ch][0]
    print "| %3.2f " % (flg/vis)

print "\n %3.2f %% (%i out of %i) were flagged." % (100*(totflg/totvis), totflg, totvis)


##################################################################################
# plot and flag interactively
##################################################################################

if not ("-noplot" in sys.argv):

    ppgplot.pgopen("/xw")
    bsl=0
    src=sources[:]
    print_help()

    # using a while construct here to enable fast forward
    while bsl<len(baselines):
        ch=0
        # using while here as well for channel skipping
        while ch<nchan:

            # put together lists of data, suspects, and flags
            xlist=[]
            ylist=[]
            xsuspects=[]
            ysuspects=[]
            xflags=[]
            yflags=[]
            for x in range(len(bsldata[bsl])):
                if bsldata[bsl][x][5] in src:
                    xlist.append(bsldata[bsl][x][0])
                    ylist.append(bsldata[bsl][x][2][ch])
                    if bsldata[bsl][x][3][ch]>0:
                        xsuspects.append(bsldata[bsl][x][0])
                        ysuspects.append(bsldata[bsl][x][2][ch])
                    if bsldata[bsl][x][4][ch]>0:
                        xflags.append(bsldata[bsl][x][0])
                        yflags.append(bsldata[bsl][x][2][ch])

            # add labels and titles
            xlabel="UT"
            ylabel="Amplitude"
            title=sys.argv[1]+": Channel %i on baseline %i-%i, sources: " % (ch+1, baselines[bsl][0], baselines[bsl][1])
            if len(src)>1:
                title=title+"all"
            elif len(src)==1:
                title=title+src[0]

            # turn lists into arrays for ppgplot
            xarray=Numeric.array(xlist)
            yarray=Numeric.array(ylist)
            xsusparray=Numeric.array(xsuspects)
            ysusparray=Numeric.array(ysuspects)
            xflagarray=Numeric.array(xflags)
            yflagarray=Numeric.array(yflags)

            # if only a single source is displayed, plot +-cutoff sigma points
            # this works only when averages have been computed, hence test for it
            if len(src)==1 and not ('-noamp' in sys.argv):
                srcindex=sources.index(src[0])
                yavg=bslavg[bsl][srcindex][0]
                yoff=cutoff*bslavg[bsl][srcindex][1]
            else:
                yavg=0
                yoff=0

            # this is to print data for external plotting with, eg, Gnuplot
#            for x in range(len(xlist)):
#                print xlist[x], ylist[x]
#            for x in range(len(xflags)):
#                print xflags[x], yflags[x]
                
            # hand it over to plotit
            tmp=plotit(xarray, yarray, xlabel, ylabel, title, \
                       xsusparray, ysusparray, xflagarray, yflagarray, \
                       yavg, yoff, mode, selfscale, xy)
            selfscale=tmp[4]
            xy=tmp[5]

            # convert the array of good points into a list, so that the index attribute can be used later
            back=tmp[0].tolist()

            # look up which points have been deleted/restores interactively
            min=0
            max=len(tmp[0])
            n=0
            for x in range(len(bsldata[bsl])):
                # first check if the data point is on the right source
                if bsldata[bsl][x][5] in src:
                    # if so, check whether it's present in the list returned from plotting
                    # if so, continue
                    if bsldata[bsl][x][0] in back[min:max]:
                        min=back.index(bsldata[bsl][x][0])
                        continue
                    # if not, it has been marked by user
                    else:
                        # if we're in flagging mode, flag data
                        if tmp[3]==1:
                            bsldata[bsl][x][4][ch]=3
                            n=n+1
                            mode=1
                        # if we're in unflagging mode, restore data
                        if tmp[3]==-1:
                            bsldata[bsl][x][4][ch]=0
                            n=n+1
                            mode=-1
                            
            vprint(" %i points were (un)flagged in previous display" %n)
                    
            # interpret key strokes:
            # switch to next baseline or exit plotting
            if tmp[2]=="x" or tmp[2]==" ":
                break

            # exit plotting
            elif tmp[2]=="q":
                print "\n Exit requested - no flags written.\n"
                ppgplot.pgclos()
                sys.exit()

            # refresh display
            elif tmp[2]=="-":
                pass

            # look for data with a given antenna
            elif tmp[2] in ants:
                i=int(tmp[2])
                j=bsl
                while j<len(baselines):
                    j=j+1
                    if j<len(baselines) and i in baselines[j]:
                        bsl=j
                        break
                    # if no baselines with requested antenna remaining, start over again
                    if j==len(baselines):
                        bsl=0

            # switch back and forth through channels
            elif tmp[2]==",":
                ch=(ch-1) % nchan
            elif tmp[2]==".":
                ch=(ch+1) % nchan

            # switch sources
            elif tmp[2]=="<" or tmp[2]==">":
                if len(sources)==1:
                    src=sources[:]
                elif len(sources)!=1 and len(src)!=1:
                    i=0
                    # the whole source selection things uses lists, so even if only
                    # one source is displayed, it has to be in a list
                    src=[sources[i]]
                elif len(sources)!=1 and len(src)==1 and tmp[2]==">":
                    i=sources.index(src[0])
                    src=[sources[(i+1) % (len(sources))]]
                elif len(sources)!=1 and len(src)==1 and tmp[2]=="<":
                    i=sources.index(src[0])
                    src=[sources[(i-1) % (len(sources))]]
                #print " Source in current display: ",
                #for x in src:
                #    print x,
                #print
            elif tmp[2]=="?":
                print " Sources in current display: ",
                src=sources[:]
                #for x in src:
                #    print x,
                #print
            else:
                ch=ch+1
                
        bsl=bsl+1

        # exit requested?
        if tmp[2]=="x":
            break
        
##################################################################################
# write the flagging commands and exit program
##################################################################################

########################################
# create the flagging commands
########################################

print " Forming the flagging commands..."

# if the stokes parameter was not specified, flag everything, ie, don't specify the "polarization" keyword in uvflag
# otherwise, include it
if stokesflag=="i":
    pol=""
else:
    pol="polarization(%s)," % stokesflag


uvflag=[]
# loop over baselines
for bsl in range(len(bsldata)):
    # and loop over channels
    for channel in range(len(bsldata[bsl][0][2])):
        x=0
        # count x up and check if a "3" indicates the beginning of a period to flag
	firstflag=0
        while x<len(bsldata[bsl]):
            # if a flag is found, store the time
            if bsldata[bsl][x][4][channel]==3:
                # make sure we get the date right
                if bsldata[bsl][x][0]<86400:
                    starttime=time2hms(bsldata[bsl][x][0]-1)
                    startyr=yr1
                    startmon=mon1
                    startday=day1
                else:
                    starttime=time2hms(bsldata[bsl][x][0]-1-86400)
                    startyr=yr2
                    startmon=mon2
                    startday=day2
                # then count x up until the channel turns to "0" again or the end of data is reached
                while x<len(bsldata[bsl]) and bsldata[bsl][x][4][channel]==3:
                    x=x+1
                # if either condition is met, end of region to flag is reached
                if bsldata[bsl][x-1][0]<86400:
                    stoptime=time2hms(bsldata[bsl][x-1][0]+1)
                    stopyr=yr1
                    stopmon=mon1
                    stopday=day1
                else:
                    stoptime=time2hms(bsldata[bsl][x-1][0]+1-86400)
                    stopyr=yr2
                    stopmon=mon2
                    stopday=day2
                # Now glue together all information so that it can be executed
		# if this is the first flag found on this baseline/channel, write flagging command
		if firstflag==0:
		    firstflag=1		
	            flagstring=["uvflag vis="+filename+" flagval=flag line=ch,1,%i,1 \"select=%sant(%i)(%i)" % \
        	               (channel+1, pol, baselines[bsl][0], baselines[bsl][1])]
	        # whether first flagging command or not, append the timestamp
                # miriad commands cannot exceed 1024 characters
                # if line gets too long, close the old and start a new one
                if len(flagstring[-1])>900:
                    flagstring[-1]=flagstring[-1]+"\""
                    flagstring.append("uvflag vis="+filename+" flagval=flag line=ch,1,%i,1 \"select=%sant(%i)(%i)" % \
        	               (channel+1, pol, baselines[bsl][0], baselines[bsl][1]))
                flagstring[-1]=flagstring[-1]+",time("+startyr+startmon+startday+":"+starttime+","+stopyr+stopmon+stopday+":"+stoptime+")"
            x=x+1

	# have any flags been detected at all? if so, close quotes and append line to uvflag
	if firstflag==1:
            flagstring[-1]=flagstring[-1]+"\""
            # append the flags to the list
            for x in flagstring:
                uvflag.append(x)


########################################
# write it to disk
########################################

print " Writing flagging commands to disk..."

# write a command file which executes all the flagging commands
outfile=open(sys.argv[1]+".pythonflags.csh", "w")
outfile.write("#!/bin/tcsh\n#\n")
outfile.write("# Flagging script generated by pieflag "+version+". Execution parameters:\n")
outfile.write("#\n")
outfile.write("# goodch %i\n" % goodch)

if not "-noamp" in sys.argv:
    outfile.write("# cutoff %i\n" % cutoff)
else:
    outfile.write("# amplitude flagging not used\n")

if not "-norms" in sys.argv:
    outfile.write("# rmscut %i\n" % rmscut)
else:
    outfile.write("# rms flagging not used\n")

if not "-nolong" in sys.argv:
    outfile.write("# long %i seconds\n" % long)
    outfile.write("# threshold %3.2f\n" % threshold)
else:
    outfile.write("# longwin not used\n")

if "-noshort" in sys.argv:
    outfile.write("# no short sections flagged (you shouldn't do this!)\n")

if not "-stokes" in sys.argv:
    outfile.write("# data converted to Stokes I before analysis, all polarizations flagged\n")
else:
    outfile.write("# data converted to Stokes %s before analysis, polarizations flagged: %s\n" % (stokesread, stokesflag))

outfile.write("#\n")

for x in uvflag:
    outfile.write(x)
    outfile.write('\n')
outfile.close()

# make the file executable
os.system("chmod 755 "+sys.argv[1]+".pythonflags.csh")


########################################
# Switch off the lights and go to bed
########################################
