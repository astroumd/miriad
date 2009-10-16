#!/bin/csh -vf

echo "Extract antenna configurations from Richard's alma configurations file"

test:
awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs | head
#goto end

awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs > ACA_config1.ant
awk '{if($5==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA_ACA_configs > ACA_config2.ant

echo "ALMA_ACA beams with natural weighting (sup=0)"

echo "Make single field images and plot beams for DEC 30"
foreach i (1 2 )
 foreach DEC ( 30 0 -30 )
  mfs.csh ACA_config$i $DEC -4,4,.1 1 sup=0
 end
end

end:
