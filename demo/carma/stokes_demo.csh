#!/bin/csh -vf

echo $0 mchw  `date`
echo polarization calibration
echo  uvflux without polcal
echo  uvflux with polcal
echo  plot real,imag with and without polcal
echo  default xyphase=0. default refant=3. xyphase is put into y-gain-phase
echo  fitting xyphase copies refant xyphase to all antennas since uvdata has zero xyphase

goto start

start:
# generate uvdata rr,ll,lr,rl with 0% leakage
stokes.csh E 30 -6,6,.5 1 sup=0 '-shadow(6.1)' point.source 0

# generate unpolarized source uvdata rr,ll,lr,rl with 10% leakage
stokes.csh E 31 -6,6,.5 1 sup=0 '-shadow(6.1)' point.source 10

# generate linearly polarized source uvdata rr,ll,lr,rl.  Q=10%  with 10% leakage
stokes.csh E 32 -6,6,.5 1 sup=0 '-shadow(6.1)' Q.source 10

# generate linearly polarized source uvdata rr,ll,lr,rl.  U=10%  with 10% leakage
stokes.csh E 33 -6,6,.5 1 sup=0 '-shadow(6.1)' U.source 10

# generate circularly polarized source uvdata rr,ll,lr,rl.  V=10%  with 10% leakage
stokes.csh E 34 -6,6,.5 1 sup=0 '-shadow(6.1)' V.source 10

# generate circularly polarized source uvdata rr,ll,lr,rl.  V=10%  with 0% leakage
stokes.csh E 35 -6,6,.5 1 sup=0 '-shadow(6.1)' V.source 0

end:
