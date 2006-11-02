#!/bin/csh

#foreach config (ata-4h ata-33 ata-42b ata-98 ata-206)
foreach config (ata-4h ata-42b )
  awk '{printf("%.2f   %.2f  %.0f  %5s %5s %5s\n", $1-4519520.87,  $2-629140.02, $3, $4, $5, $6)}' $config.ant | sort -n | sort -n -k 2 > $config.sort.ant
end
