#!/bin/csh -vf

echo "Extract antenna configurations from Richard's alma configurations file"

test:
awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs | head
#goto end

awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs > ACA_config1.ant
awk '{if($5==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs > ACA_config2.ant

echo "ALMA_ACA beams with shadow=7m" >> beams.results.ACA

echo "Make single field images and plot beams for DEC 30"
foreach WEIGHT (sup=0 robust=0.5 uniform )
  foreach CONFIG (1 2 )
    foreach DEC ( 30 0 -30 )
     ./ACA.mfs.csh ACA_config$CONFIG $DEC -4,4,.1 1 $WEIGHT
    end
  end
end

end:
