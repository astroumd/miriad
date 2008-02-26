#!/bin/csh -vf

echo $0  mchw 26 Feb 2008
echo $0  Run date `date`
echo Average uvdata for antennas with dual polarization and fit polarization leakage


goto start

   106	18:11	ls /sun1
   107	18:11	ls /sun1/wrigt
   108	18:12	ls /sun1/wright
   109	18:12	ls /sun1/wright/miriad
   110	18:12	mir-sun
   111	18:12	echo $MIR
   113	18:15	uvaver vis=fx32a-3c380-1430_1,fx32a-3c147-1430_1,fx32a-2206--1430_1,fx32a-3c48-1430_1,fx32a-bllac-1430_1,fx32a-0834+-1430_1,fx32a-2038+-1430_1,fx32a-3c84-1430_1,fx32a-3c119-1430_1,fx32a-3c123-1430_1,fx32a-3c138-1430_1,fx32a-3c345-1430_1 interval=1 line=chan,1,100,400 select=-auto options=nocal,nopass out=cals.fx32ap
   114	18:16	uvedit vis=cals.fx32ap apfile=antpos.fx32a
   117	18:36	uvaver vis=fx32b-3c147-1430_1,fx32b-3c380-1430_1,fx32b-2206--1430_1,fx32b-bllac-1430_1,fx32b-0834+-1430_1,fx32b-2038+-1430_1,fx32b-3c84-1430_1,fx32b-3c138-1430_1,fx32b-3c345-1430_1,fx32b-3c123-1430_1,fx32b-3c119-1430_1,fx32b-3c48-1430_1 interval=1 line=chan,1,100,400 select=-auto options=nocal,nopass out=cals.fx32bp
   118	18:37	uvedit vis=cals.fx32bp apfile=antpos.fx32b
   119	18:37	ls -lrt
   121	18:39	uvindex vis=cals.fx32ap_c
   122	18:40	uvindex vis=cals.fx32bp_c
   123	18:41	gpcal vis=cals.fx32ap_c
   127	18:42	uvplt device=/xs vis=cals.fx32ap_c
   128	18:43	uvplt device=/xs vis=cals.fx32bp_c
   129	18:43	uvplt device=/xs vis=cals.fx32bp_c nxy=2,2

foreach FILE ( fx32b-3c147-1430_1 fx32b-3c380-1430_1 fx32b-2206--1430_1 fx32b-bllac-1430_1 fx32b-0834+-1430_1 fx32b-2038+-1430_1 fx32b-3c84-1430_1 fx32b-3c138-1430_1 fx32b-3c345-1430_1 fx32b-3c123-1430_1 fx32b-3c119-1430_1 fx32b-3c48-1430_1 )
  rm -r $FILE.fx32bp
  uvaver vis=$FILE interval=1 line=chan,1,100,400 'select=ant(4,7,13,20,32)(4,7,13,20,32)',-auto options=nocal,nopass out=$FILE.fx32bp
  uvedit vis=$FILE.fx32bp apfile=antpos.fx32b
c  uvplt device=/xs vis=$FILE.fx32bp_c
  gpcal vis=$FILE.fx32bp_c refant=4
end


echo $0  Run date `date` > leakage.results
echo Average uvdata for antennas with dual polarization and fit polarization leakage >> leakage.results

echo $0  mchw 26 Feb 2008 >> leakage.results

foreach FILE ( fx32b-3c147-1430_1 fx32b-3c380-1430_1 fx32b-2206--1430_1 fx32b-bllac-1430_1 fx32b-0834+-1430_1 fx32b-2038+-1430_1 fx32b-3c84-1430_1 fx32b-3c138-1430_1 fx32b-3c345-1430_1 fx32b-3c123-1430_1 fx32b-3c119-1430_1 fx32b-3c48-1430_1 )

  echo $FILE.fx32bp_c >> leakage.results
  tail -56 $FILE.fx32bp_c/history >> leakage.results

end

start:

echo " " >> leakage.results
echo $0  Compare XY phase and polarization leakage on each source >> leakage.results
echo " " >> leakage.results

# edit out 2206 -- probably too leak source.
foreach FILE ( fx32b-3c147-1430_1 fx32b-3c380-1430_1 fx32b-bllac-1430_1 fx32b-0834+-1430_1 fx32b-2038+-1430_1 fx32b-3c84-1430_1 fx32b-3c138-1430_1 fx32b-3c345-1430_1 fx32b-3c123-1430_1 fx32b-3c119-1430_1 fx32b-3c48-1430_1 )

  echo $FILE.fx32bp_c >> leakage.results
end

echo " " >> leakage.results
echo "Xyphase" >> leakage.results
echo " " >> leakage.results

grep "GPCAL:  Xyphase( 1- 7)" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Xyphase( 8-14)" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Xyphase(15-21)" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Xyphase(22-28)" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Xyphase(29-35)" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Xyphase(36-42)" leakage.results >> leakage.results
echo " " >> leakage.results

echo " " >> leakage.results
echo "Polarization leakage" >> leakage.results
echo " " >> leakage.results

grep "GPCAL:  Ant 4:Dx,Dy" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Ant 7:Dx,Dy" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Ant13:Dx,Dy" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Ant20:Dx,Dy" leakage.results >> leakage.results
echo " " >> leakage.results
grep "GPCAL:  Ant32:Dx,Dy" leakage.results >> leakage.results
echo " " >> leakage.results
