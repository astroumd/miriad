#!/bin/csh

goto start
start:

foreach config (ata-32 ata-42)
 foreach harange (-6,6,.2)
  foreach dec (30 0 -30)
   mfs.csh  $config  $dec  $harange  1 sup=0
  end
 end
end


