#!/bin/csh

goto start
start:

#foreach harange (-2,2,.2 -4,4,.2 -6,6,.2)
foreach harange (-6,6,.2)
 foreach dec ( 60 30 0 -30)
  foreach config (ata-32 ata-42b ata-42c.sort)
   mfs.csh  $config  $dec  $harange  1 
  end
 end
end

