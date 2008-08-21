#!/bin/csh -vf

echo "Extract antenna configurations from John's file"

awk '{if($5==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config1.ant
awk '{if($6==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config2.ant
awk '{if($7==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config3.ant
awk '{if($8==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config4.ant
awk '{if($9==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config5.ant
awk '{if($10==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config6.ant
awk '{if($11==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config7.ant
awk '{if($12==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config8.ant
awk '{if($13==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config9.ant
awk '{if($14==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config10.ant
awk '{if($15==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config11.ant
awk '{if($16==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config12.ant
awk '{if($17==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config13.ant
awk '{if($18==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config14.ant
awk '{if($19==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config15.ant
awk '{if($20==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config16.ant
awk '{if($21==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config17.ant
awk '{if($22==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config18.ant
awk '{if($23==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config19.ant
awk '{if($24==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config20.ant
awk '{if($25==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config21.ant
awk '{if($26==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config22.ant
awk '{if($27==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config23.ant
awk '{if($28==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config24.ant
awk '{if($29==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config25.ant
awk '{if($30==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config26.ant
awk '{if($31==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config27.ant
awk '{if($32==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config28.ant
awk '{if($33==1) printf("%.2f  %.2f  0.0  %d\n", $3, $2, $4)}' conway.configs > config29.ant


echo "Make single field images and plot beams for DEC 30"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  mfs.csh config$i 30 -1,1,.1 1
end

echo "Make single field images and plot beams for DEC 0"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  mfs.csh config$i 0 -1,1,.1 1
end

echo "Make single field images and plot beams for DEC -30"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 )
  mfs.csh config$i -30 -1,1,.1 1
end
