#!/bin/csh -vf

echo Radial Profile of Fourier Transforms for Models and Images

goto start

disk:
imgen in=casc.vla factor=0 object=disk spar=1.314758E-02,0,0,320,320,0 out=disk.model
fft rin=disk.model mag=disk.fft
ellint in=disk.fft log=disk.fft.ellint options=natural scale=1

casc.vla:
rm -r casc.vla.fft
fft rin=casc.vla mag=casc.vla.fft
implot device=/xs in=casc.vla.fft conflag=l conargs=2.5
ellint in=casc.vla.fft log=casc.vla.fft.ellint options=natural scale=10
wip casc.vla.fft.wip

eyechart:
rm -r eyechart.fft
fft rin=/dp/wright/cca/eyechart.model mag=eyechart.fft
ellint in=eyechart.fft log=eyechart.fft.ellint options=natural scale=1e-3
wip eyechart.fft.wip

cas.0.03:
scale = 10/Effective beam area:  0.2839E+02 to get same units in FFT = 0.3522367


rm -r cas.0.04.vla.fft
fft rin=cas.0.04.vla mag=cas.0.04.vla.fft
ellint in=cas.0.04.vla.fft log=cas.0.04.vla.fft.ellint options=natural scale=10
rm -r config?.30.cas.0.04.mem.fft
fft rin=config1.30.cas.0.04.mem mag=config1.30.cas.0.04.mem.fft
fft rin=config2.30.cas.0.04.mem mag=config2.30.cas.0.04.mem.fft
fft rin=config5.30.cas.0.04.mem mag=config5.30.cas.0.04.mem.fft
ellint in=config1.30.cas.0.04.mem.fft log=config1.30.cas.0.04.mem.fft.ellint options=natural scale=10
ellint in=config2.30.cas.0.04.mem.fft log=config2.30.cas.0.04.mem.fft.ellint options=natural scale=10
ellint in=config5.30.cas.0.04.mem.fft log=config5.30.cas.0.04.mem.fft.ellint options=natural scale=10

rm -r config?.30.cas.0.04.resid.fft
fft rin=config1.30.cas.0.04.resid mag=config1.30.cas.0.04.resid.fft
fft rin=config2.30.cas.0.04.resid mag=config2.30.cas.0.04.resid.fft
fft rin=config5.30.cas.0.04.resid mag=config5.30.cas.0.04.resid.fft
set scale = `imlist options=stat in=config1.30.cas.0.04.resid | grep Effective | awk '{print 10/$4}'`
ellint in=config1.30.cas.0.04.resid.fft log=config1.30.cas.0.04.resid.fft.ellint options=natural scale=$scale
set scale = `imlist options=stat in=config2.30.cas.0.04.resid | grep Effective | awk '{print 10/$4}'`
ellint in=config2.30.cas.0.04.resid.fft log=config2.30.cas.0.04.resid.fft.ellint options=natural scale=$scale
set scale = `imlist options=stat in=config5.30.cas.0.04.resid | grep Effective | awk '{print 10/$4}'`
ellint in=config5.30.cas.0.04.resid.fft log=config5.30.cas.0.04.resid.fft.ellint options=natural scale=$scale

# cut off plot at max uv-spacing in wavelengths
uvcheck vis=config1.30.cas.0.04.uv1
calc '230*481' = 110630 = line 78
uvcheck vis=config2.30.cas.0.04.uv1
calc '230*884' = 203320.0 = line 145
uvcheck vis=config5.30.cas.0.04.uv1
calc '230*632' = 145360.0 = line 78

wip cas.0.04.dec30.fft.wip
wip cas.0.04.dec30.fft.wip -x -d cas.0.04.dec30.fft.ps/cps
goto end


rm -r cas.0.03.vla.fft
fft rin=cas.0.03.vla mag=cas.0.03.vla.fft
ellint in=cas.0.03.vla.fft log=cas.0.03.vla.fft.ellint options=natural scale=10
rm -r config?.30.cas.0.03.mem.fft
fft rin=config1.30.cas.0.03.mem mag=config1.30.cas.0.03.mem.fft
fft rin=config2.30.cas.0.03.mem mag=config2.30.cas.0.03.mem.fft
fft rin=config5.30.cas.0.03.mem mag=config5.30.cas.0.03.mem.fft
ellint in=config1.30.cas.0.03.mem.fft log=config1.30.cas.0.03.mem.fft.ellint options=natural scale=10
ellint in=config2.30.cas.0.03.mem.fft log=config2.30.cas.0.03.mem.fft.ellint options=natural scale=10
ellint in=config5.30.cas.0.03.mem.fft log=config5.30.cas.0.03.mem.fft.ellint options=natural scale=10

rm -r config?.30.cas.0.03.resid.fft
fft rin=config1.30.cas.0.03.resid mag=config1.30.cas.0.03.resid.fft
fft rin=config2.30.cas.0.03.resid mag=config2.30.cas.0.03.resid.fft
fft rin=config5.30.cas.0.03.resid mag=config5.30.cas.0.03.resid.fft
ellint in=config1.30.cas.0.03.resid.fft log=config1.30.cas.0.03.resid.fft.ellint options=natural scale=0.431
ellint in=config2.30.cas.0.03.resid.fft log=config2.30.cas.0.03.resid.fft.ellint options=natural scale=0.232
ellint in=config5.30.cas.0.03.resid.fft log=config5.30.cas.0.03.resid.fft.ellint options=natural scale=0.503
wip cas.0.03.dec30.fft.wip
goto end

start:

foreach dec ( -30 0 30 )
rm -r config?.$dec.cas.0.05.mem.fft
fft rin=config1.$dec.cas.0.05.mem mag=config1.$dec.cas.0.05.mem.fft
ellint in=config1.$dec.cas.0.05.mem.fft log=config1.$dec.cas.0.05.mem.fft.ellint options=natural scale=10

rm -r config?.$dec.cas.0.05.resid.fft
fft rin=config1.$dec.cas.0.05.resid mag=config1.$dec.cas.0.05.resid.fft

set scale = `imlist options=stat in=config1.$dec.cas.0.05.resid | grep Effective | awk '{print 10/$4}'`
ellint in=config1.$dec.cas.0.05.resid.fft log=config1.$dec.cas.0.05.resid.fft.ellint options=natural scale=$scale
end

# cut off plot at max uv-spacing in wavelengths
uvcheck vis=config1.-30.cas.0.04.uv1
calc '230*484' = 111320 = line 75
uvcheck vis=config2.-30.cas.0.04.uv1
calc '230*885' = 203320 = line 139
uvcheck vis=config5.-30.cas.0.04.uv1
calc '230*976' = 224480 = line 138

wip cas.0.04.dec-30.fft.wip
wip cas.0.04.dec-30.fft.wip -x -d cas.0.04.dec-30.fft.ps/cps

end:

