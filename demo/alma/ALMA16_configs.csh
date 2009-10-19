#!/bin/csh -vf

echo "Extract antenna configurations from Richard's alma configurations file"

test:
awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs | head
#goto end

awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs > ALMA16_config1.ant
awk '{if($5==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs > ALMA16_config2.ant
awk '{if($6==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' ALMA16_configs > ALMA16_config3.ant


echo "ALMA16_configs beams with shadow = 12m"

echo "Make single field images and plot beams "
foreach WEIGHT (sup=0 robust=0.5 uniform )
  foreach CONFIG (1 2 3 )
    foreach DEC ( 30 0 -30 )
     ./mfs.csh ALMA16_config$CONFIG $DEC -4,4,.1 1 $WEIGHT
    end
  end
end

end:
