#!/bin/csh

foreach config (ata-98 ata-206 ata-350)
foreach range (2900 2400 2000 1700 1400 1100 800 500 400 300 200 150 100 80 60 40 )
  uvplt vis=$config.uv device=/xs axis=uc,vc options=nobase,equal,nano "select=uvnrange(0,$range)"
end
end
