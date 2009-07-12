#! /bin/env python
#
import os,sys
#
# For miriad scaling reasons I have to pick a frequency...I choose
# 100GHz mostly because this is ~3mm and makes life easy with a
# 12m dish
#
imSize   = 2048
cellSize = 0.032
antDiam  = 6.0
pixDelt  = antDiam*1000.0/3.0*cellSize
#
def makeApertures(aperBase='aper',x=range(0,15,2),y=0,outfile='run.stat',fitOnly=False,cleanUp='all') :
    cleanUp = cleanUp.upper()
    baseFile = ('%s.x%f.y%f' % (aperBase,x[0],y) )
    if not fitOnly :
        for i in x : createAperture('%s.x%f.y%f' % (aperBase,i,y))
        for i in x : moveAperture('%s.x%f.y%f'   % (aperBase,i,y),i,y)
        for i in x : 
            newAper=('%s.x%f.y%f' % (aperBase,i,y) )
            if newAper <> baseFile : obstructAperture(baseFile,'%s.x%f.y%f' % (aperBase,i,y),'%s.x%f.y%f.shad' % (aperBase,i,y))
        for i in x[1:] : 
            print i
            makeBeam('%s.x%f.y%f.shad' % (aperBase,i,y) )
    fd = open(outfile,'w')
    fd.write("File Name   ,   Peak ,   Max_Pha,   Min_Pha,  Major, Minor, Ellip, Pa\n")
    for i in x[1:] :
        peak_mag = float(os.popen("histo in=%s.x%f.y%f.shad.sky.mag | grep 'Maximum value' | awk '{printf($3)}'" % (aperBase,i,y)).read())
        max_pha = float(os.popen("histo in=%s.x%f.y%f.shad.sky.mask.pha region='arcsec,boxes(-50,-50,50,50)' | grep 'Maximum value' | awk '{printf($3)}'" % (aperBase,i,y)).read())
        min_pha = float(os.popen("histo in=%s.x%f.y%f.shad.sky.mask.pha region='arcsec,boxes(-50,-50,50,50)' | grep 'Minimum value' | awk '{printf($3)}'" % (aperBase,i,y)).read())
        os.system("histo in=%s.x%f.y%f.shad.sky.pha" % (aperBase,i,y))
        os.system("imfit in=%s.x%f.y%f.shad.sky.mag object=gauss clip=%f spar=%f,0,0,75,75,0 region='arcsec,boxes(-120,-120,120,120)'" % (aperBase,i,y,(peak_mag/10.0),peak_mag) )
        major   = float(os.popen("imfit in=%s.x%f.y%f.shad.sky.mag object=gauss clip=%f spar=%f,0,0,75,75,0 region='arcsec,boxes(-120,-120,120,120)' | grep 'Major axis' | awk '{printf($4)}'" % (aperBase,i,y,(peak_mag/10.0),peak_mag) ).read())
        minor   = float(os.popen("imfit in=%s.x%f.y%f.shad.sky.mag object=gauss clip=%f spar=%f,0,0,75,75,0 region='arcsec,boxes(-120,-120,120,120)' | grep 'Minor axis' | awk '{printf($4)}'" % (aperBase,i,y,(peak_mag/10.0),peak_mag) ).read())
        pa      = float(os.popen("imfit in=%s.x%f.y%f.shad.sky.mag object=gauss clip=%f spar=%f,0,0,75,75,0 region='arcsec,boxes(-120,-120,120,120)' | grep 'Position angle (degrees)' | awk '{printf($4)}'" % (aperBase,i,y,(peak_mag/4.545455),peak_mag) ).read())
        ellip   = major/minor
        fd.write("%s.x%f.y%f.shad.sky.mag, %f, %f, %f, %f, %f, %f, %f\n" % (aperBase,i,y,peak_mag,max_pha,min_pha,major,minor,ellip,pa) )
    if cleanUp == 'ALL' : 
        os.system("rm -rf %s.*" % aperBase)
    elif cleanUp == 'APER' :
        os.system("rm -rf %s.*.*0 %s.*.*.shad" % (aperBase,aperBase))
    elif cleanUp == 'SKY' :
        os.system("rm -rf %s.*.*.shad.sky.*" % aperBase)

def makeBeam(aperName) :
    os.system("rm -rf %s.sky.real %s.sky.imag %s.sky.mag %s.sky.pha %s.sky.mask.pha" % (aperName,aperName,aperName,aperName,aperName) )
    os.system("fft sign=+1 rin=%s rout=%s.sky.real iout=%s.sky.imag mag=%s.sky.mag phase=%s.sky.pha" % (aperName,aperName,aperName,aperName,aperName) )
    peak = float(os.popen("histo in=%s.sky.mag | grep 'Maximum value' | awk '{printf($3)}'" % (aperName)).read())
    os.system("maths exp='(<%s.sky.pha>)' out=%s.sky.mask.pha mask='(<%s.sky.mag>).ge.%f'" % (aperName,aperName,aperName,peak/4.472136) )

def createAperture(aperName='aper.temp',xCen=0,yCen=0,doMask=True,doClean=True) :
    os.system("rm -rf %s %s.full %s.mask" % (aperName,aperName,aperName) )
    os.system("imgen out=%s.full object=j0 spar=1,0,0,0.5263158 cell=%f imsize=%i" % (aperName,cellSize,imSize) )
    if doMask : 
        os.system("maths exp='(<%s.full>)' mask='sqrt(x*x+y*y).le.%f' xrange=-%i,%i yrange=-%i,%i out=%s.mask" % (aperName,(1.0/cellSize),(imSize/2),(imSize/2-1),(imSize/2),(imSize/2-1),aperName) )
    else : 
        os.system("cp -r %s.full %s.mask" % (aperName,aperName) )
    os.system("puthd in=%s.mask/ctype1   value=UU---SIN" % aperName)
    os.system("puthd in=%s.mask/ctype2   value=VV---SIN" % aperName)
    os.system("puthd in=%s.mask/restfreq value=100.00"   % aperName)
    os.system("puthd in=%s.mask/crval3   value=10000.00" % aperName)
    os.system("puthd in=%s.mask/cdelt3   value=10.00"    % aperName)
    os.system("puthd in=%s.mask/naxis    value=3"        % aperName)
    os.system("puthd in=%s.mask/naxis3   value=1"        % aperName)
    os.system("puthd in=%s.mask/crpix3   value=1"        % aperName)
    os.system("puthd in=%s.mask/bunit    value=JY"       % aperName)
    os.system("puthd in=%s.mask/cdelt1   value=-%f" % (aperName,pixDelt) )
    os.system("puthd in=%s.mask/cdelt2   value=%f"  % (aperName,pixDelt) )
    os.system("cp -r %s.mask %s"       % (aperName,aperName) )
    if doClean : os.system("rm -rf %s.mask %s.full" % (aperName,aperName) )
    
def moveAperture(aperName='aper.temp',xOff=0,yOff=0) :
    os.system("rm -rf %s.temp" % (aperName) )
    xOffPix = xOff*1000.0/(3.0*pixDelt)
    yOffPix = yOff*1000.0/(3.0*pixDelt)
    os.system("imdiff in1=%s in2=%s adjust=%s.temp xshift=%f yshift=%f options=noamp,nooff,nox,noy,noex" % (aperName,aperName,aperName,xOffPix,yOffPix) )
#    sys.stdin.readline()
    os.system("rm -rf %s" % (aperName) )
    os.system("cp -r %s.temp %s" % (aperName,aperName))
    os.system("rm -rf %s.temp" % (aperName))

def obstructAperture(aperName,aperMove,aperOut) :
    os.system("rm -rf %s" % (aperOut) )
    os.system("maths exp='(<%s>)' mask='(<%s>.lt.0.01)' out=%s" % (aperName,aperMove,aperOut) )
        
