#!/bin/csh

goto start
start:

#foreach config (ata-32 ata-42)

foreach config (kat7)
 foreach harange ( -2,2,.1  -4,4,.1 )
  foreach dec (-30 0 30)
   mfs.csh $config $dec $harange 1 sup=0      '-shadow(12)'
   mfs.csh $config $dec $harange 1 robust=-.5 '-shadow(12)'
   mfs.csh $config $dec $harange 1 uniform    '-shadow(12)'
  end
 end
end


