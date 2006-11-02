#!/bin/csh

foreach dec ( 30 )
 foreach harange ( -6,6,.2 )
#  foreach config ( ata-350 ata-206 ata-98 ata-32 ata-42b ata-32 )
  foreach config ( ata-42b ata-32 hex7.625m )

echo Generate uv-data and images for $config at declination = $dec, HArange = $harange
echo " " >> uvcheck.results
echo Generate uv-data and images for $config at declination = $dec, HArange = $harange >> uvcheck.results

  mfs.csh $config $dec $harange 1

echo Get number of uv samples at short spacings in each uvrange
echo Get number of uv samples at short spacings in each uvrange >> uvcheck.results

   foreach range ( 0,10000 10,15 15,20 20,25 25,30 30,35 35,40 40,45 45,50 )
    uvcheck vis=$config.$dec.uv "select=uvnrange($range)"   | grep uvrange >> uvcheck.results
   end
  end
 end
end
