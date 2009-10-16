#!/bin/csh -vf

echo "Extract antenna configurations from Richard's alma configurations file"

test:
awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs | head
#goto end

awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs > ALMA16_config1.ant
awk '{if($5==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' ALMA16_configs > ALMA16_config2.ant
awk '{if($6==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' ALMA16_configs > ALMA16_config3.ant

echo "ALMA16_configs beams with natural weighting (sup=0)"

echo "Make single field images and plot beams for DEC 30"
foreach i (1 2 3 )
  mfs.csh ALMA16_config$i 30 -1,1,.1 1 sup=0
end

echo "Make single field images and plot beams for DEC 0"
foreach i (1 2 3 )
  mfs.csh ALMA16_config$i 0 -1,1,.1 1 sup=0
end

echo "Make single field images and plot beams for DEC -30"
foreach i (1 2 3 )
  mfs.csh ALMA16_config$i -30 -1,1,.1 1 sup=0
end

end:
