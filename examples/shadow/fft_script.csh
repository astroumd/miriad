#!/bin/csh -vf
#
# Next step: put masking on aperture plane to get rid of that
# nasty halo problem.
#
rm -rf startVoltage.real startVoltage.imag
rm -rf startAper.real startAper.imag startAper.mag startAper.pha
rm -rf maskAper.real maskAper.imag maskAper.mag maskAper.pha
rm -rf maskedAper.real maskedAper.imag maskedAper.mag maskedAper.pha
rm -rf maskedSky.real maskedSky.imag maskedSky.mag maskedSky.pha
#
imgen out=startVoltage.real object=j1x spar=1,0,0,63,63,0 imsize=4096 cell=0.5
imgen out=startVoltage.imag object=level spar=0 imsize=4096 cell=0.5
#
fft rin=startVoltage.real iin=startVoltage.imag mag=startAper.mag phase=startAper.pha rout=startAper.real iout=startAper.imag
#
# Offset the aperture center...gotta figure out the size scales here
# because I am frequency free and using pixels.  As I have it, the 
# aperture size is about 40 pixels across.
#
imdiff in1=startAper.real in2=startAper.real adjust=maskAper.real xshift=15 yshift=10 options=noamp,nooff,nox,noy,noex
imdiff in1=startAper.imag in2=startAper.imag adjust=maskAper.imag xshift=15 yshift=10 options=noamp,nooff,nox,noy,noex
imdiff in1=startAper.mag in2=startAper.mag adjust=maskAper.mag xshift=15 yshift=10 options=noamp,nooff,nox,noy,noex
imdiff in1=startAper.pha in2=startAper.pha adjust=maskAper.pha xshift=15 yshift=10 options=noamp,nooff,nox,noy,noex
#
maths exp='(<startAper.real>)' mask='(<maskAper.mag>.lt.1000)' out=maskedAper.real
maths exp='(<startAper.imag>)' mask='(<maskAper.mag>.lt.1000)' out=maskedAper.imag
maths exp='(<startAper.mag>)' mask='(<maskAper.mag>.lt.1000)' out=maskedAper.mag
maths exp='(<startAper.pha>)' mask='(<maskAper.mag>.lt.1000)' out=maskedAper.pha
#
#
fft sign=+1 rin=maskedAper.real iin=maskedAper.imag rout=maskedSky.real iout=maskedSky.imag mag=maskedSky.mag phase=maskedSky.pha


