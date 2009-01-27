#! /bin/csh -f
#
# 3/7/07
#
# Script to reduce CARMA OPHB11 data
#   -- using 2 calibrators:
#            offsetcal to calibrate offset in phase b/w wide and narrow band
#                  cal to calibrate phases
#
# pre-work:
# set vis=c0014.OphB11_C.1.miriad
# carmadata  $vis.tar.gz
# puthd in=$vis/restfreq value=115.271204 type=double
# uvcat vis=$vis out=1751+096W.raw 'select=source(1751+096),-auto,time(11:29:00,11:38:20)'
# uvcat vis=$vis out=1751+096N.raw 'select=source(1751+096),-auto,time(11:08:00,11:30:00)'
# uvcat vis=$vis out=1625-254.raw  'select=source(1625-254),-auto'
# uvcat vis=$vis out=ophb11.raw    'select=source(ophb11),-auto'

umask 002

set task=flag                     # task to perform
set vis==c0014.OphB11_C.1.miriad  # base project vis file
set offsetcal=1751+096            # calibrator for phase offset b/w Wide and Narr. bands
set cal=1625-254                  # primary phase cal name
set source=ophb11                 # source name
set refant=8                      # refant for selfcal
set interval=25                   # interval for selfcal
set scselect=                     # select for selfcal on phase cal
set nxy=3,3                       # number of windows for plotting
set flux=1.6

set ointerval=9999         # interval for offset cal selfcal
set olinecal=chan,1,46,45,45
set linenarrow=chan,1,109,63,63
set axis=time,phase

set line=

set dev=1/xs              # plotting device
set select=                # select for uvplt
set options=              # options for uvplt

set cutoff= 

foreach _arg ($*)
    set $_arg
end

goto $task

logs:
listobs vis=


renewoffset:

# Secondary Calibrator split into files with with differen correlator configs:
rm -rf "$offsetcal"N.red
cp -r "$offsetcal"N.raw "$offsetcal"N.red
rm -rf "$offsetcal"W.red
cp -r "$offsetcal"W.raw "$offsetcal"W.red

flagoff:
uvplt vis="$offsetcal"W.red device=$dev  \
    nxy=$nxy select=$select options=$options axis=$axis

uvplt vis="$offsetcal"N.red device=$dev \
    nxy=$nxy select=$select options=$options axis=$axis

exit 0

selfoff:

# if applying BP cal to 1751, also apply to sec phase, and to source, depending on
#    window ...
#
# or just include USB (calibrating Wide band) :

selfcal vis="$offsetcal"W.red refant=$refant  \
    line=$olinecal options=noscale interval=$ointerval

gpplt vis="$offsetcal"W.red yaxis=phase yrange=-180,180 \
    device=$dev nxy=$nxy options=w

# Apply Wide Band calibration to Narrow Band:
gpcopy vis="$offsetcal"W.red out="$offsetcal"N.red mode=copy options=nopass

rm -rf "$offsetcal"Nref.red
uvcat vis="$offsetcal"N.red out="$offsetcal"Nref.red

# Another selfcal to get offset between Wide and Narrow bands:
selfcal vis="$offsetcal"Nref.red refant=$refant select=$select    \
    line=$linenarrow options=phase interval=$ointerval

gpplt vis="$offsetcal"Nref.red yaxis=phase yrange=-180,180 \
    device=$dev nxy=$nxy options=w

exit 0
renew:
# CAREFUL: This will erase $cal.red to start from scratch
# uvcat  vis=c0014.OphB11_C.1.miriad select=source(1625-254),-auto out=1625-254.raw

rm -rf $cal.red
cp -r $cal.raw $cal.red

flag:
uvplt vis=$cal.red device=$dev line= \
    nxy=$nxy select=$select options=$options

#---Flag data here---
exit 0

selfcal:

#selfcal phase calibrator

selfcal vis="$cal".red flux=$flux refant=$refant select=$scselect options=amp,apriori,noscale interval=$interval line=$olinecal

gpplt:
gpplt vis="$cal".red yaxis=phase yrange=-180,180 \
    device=$dev nxy=$nxy options=w

sleep 2

rm -rf $cal.dm $cal.bm
invert vis="$cal".red map=$cal.dm beam=$cal.bm \
    imsize=237,237 cell=1,1 line=$olinecal options=systemp select=$scselect

rm -rf $cal.cln

clean map=$cal.dm beam=$cal.bm niters=10000 out=$cal.cln cutoff=$cutoff

rm -rf $cal.restor
restor model=$cal.cln map=$cal.dm beam=$cal.bm out=$cal.restor

cgdisp in=$cal.restor device=$dev

chmod -R 775 $cal.*

exit 0

renewsource:
# CAREFUL: This will erase $source.red to start from scratch
# uvcat  vis=c0014.OphB11_C.1.miriad select=source(OPHB11),-auto out=ophb11.raw
rm -rf $source.red
cp -r $source.raw $source.red

flagsource:
uvplt vis=$source.red device=$dev line=$line \
    nxy=$nxy select=$select options=$options

#---Flag source data here---
exit 0


invert:

# Copy and apply gains table from phase calibrator
gpcopy vis="$cal".red/ out=$source.red mode=copy

rm -rf "$source"GT.red
uvcat vis=$source.red out="$source"GT.red

# Copy and apply gains table from offset calibrator (narrow band only)
gpcopy vis="$offsetcal"Nref.red out="$source"GT.red mode=copy

rm -rf "$source"cal.red
uvcat vis="$source"GT.red out="$source"cal.red select='window(5)'

rm -rf $source.dm $source.bm
invert vis="$source"cal.red map=$source.dm beam=$source.bm imsize=237,237 \
    cell=1,1 options=systemp,double,mosaic line=$line sup=0 select=$select

#rm -rf $source.cln $source.restor
#clean map=$source.dm beam=$source.bm out=$source.cln \
#    niters=10000 cutoff=$cutoff
#minmax in=$source.cln
#restor map=$source.dm beam=$source.bm \
#    model=$source.cln out=$source.restor

chmod -R 775 $source.* 

