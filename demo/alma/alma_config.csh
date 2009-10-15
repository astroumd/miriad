#!/bin/csh -vf

echo "Extract antenna configurations from Richard's alma configurations file"

test:
awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' alma_config.1 | head
#goto end

awk '{if($4==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $1)}' alma_config.1 > config1.ant
awk '{if($5==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config2.ant
awk '{if($6==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config3.ant
awk '{if($7==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config4.ant
awk '{if($8==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config5.ant
awk '{if($9==1)  printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config6.ant
awk '{if($10==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config7.ant
awk '{if($11==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config8.ant
awk '{if($12==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config9.ant
awk '{if($13==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config10.ant
awk '{if($14==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config11.ant
awk '{if($15==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config12.ant
awk '{if($16==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config13.ant
awk '{if($17==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config14.ant
awk '{if($18==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config15.ant
awk '{if($19==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config16.ant
awk '{if($20==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config17.ant
awk '{if($21==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config18.ant
awk '{if($22==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config19.ant
awk '{if($23==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config20.ant
awk '{if($24==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config21.ant
awk '{if($25==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config22.ant
awk '{if($26==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config23.ant
awk '{if($27==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config24.ant
awk '{if($28==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config25.ant
awk '{if($29==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config26.ant
awk '{if($30==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config27.ant
awk '{if($31==1) printf("%.2f  %.2f  0.0  %s\n", $3, $2, $4)}' alma_config.1 > config28.ant

echo "ALMA beams with natural weighting (sup=0)"
echo "Make single field images and plot beams for DEC 30"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 )
  mfs.csh config$i 30 -1,1,.1 1 sup=0
end

echo "Make single field images and plot beams for DEC 0"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 )
  mfs.csh config$i 0 -1,1,.1 1 sup=0
end

echo "Make single field images and plot beams for DEC -30"
foreach i (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 )
  mfs.csh config$i -30 -1,1,.1 1 sup=0
end

end:
