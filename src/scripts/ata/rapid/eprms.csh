#! /usr/bin/tcsh -f
#  calculates mean and rms phase per baseline    jrf - 05jan08
# modified for automated mapping - no input requests are present!
#
# $Id$
#


#    exit script cleanly  on interrupt
onintr finish

#    set fixed parameters
set plim = 30                 # rms phase limit for select (deg)
set clim = 10                 # closure phase limit for report (deg))
set int=.5                     # selfcal interval (min)
set dev=/null               # plot device (use /xs for plots)
set rep=report.prms

alias rep "tee -ia $rep"

#    get input source name for scan
 set vis = $1
 set plim = $2
 set clim = $3
 set rpt = $4
goto start
start:

#    log phase vs time for given scan and pol for all baselines
set log = log.$vis
uvplt vis=$vis device=$dev nxy=7,5 axis=time,pha yrange=-180,180 \
        options=log,nofqav,2pass log=$log select='window(1),-auto'\
	line=chan,4,101,103,103

#    get phase vs time data from uvplt log file
grep E+ $log > data

#    get baseline list and sort into uvplt sequence 
grep Base $log | awk '{printf "%s %.3d %4.0f\n", $2,$3,$5}' | sort -n | \
     sed -e s/'- 0'/-/ | sed -e s/-0/-/ > base

#    get number of points in the plots (assumes all are the same)
set nct = `head -1 base | awk '{print $2}'`

#    derive mean and rms of (selfcaled) phases for each baseline
awk '{n++; if (n==1) {sx=$2; sxx=$2*$2} else {sx=sx+$2; sxx=sxx+($2*$2)} if (n==nct) {m=sx/n; r=sqrt((sxx-n*m*m)/n); n=0; printf "%5.0f %6.0f\n", m,r}}' nct=$nct data > stats

#    put together the baseline and statistics lists sorted by rms
echo "#   n baseline points      ave   rms (deg)" > basestats
paste base stats | sort -rnk 4 | pr -tn >> basestats

#     make selection list of baselines with rms > $plim deg
grep -v '#' basestats | tr '-' ' ' | awk '{if($6>=plim) printf "%s", "ant("$2")("$3"),"}' plim=$plim | tr '\012' ' ' > sel.$vis
grep -v '#' basestats | tr '-' ' ' | awk '{if($5>=clim) printf "%s", "ant("$2")("$3"),"}' clim=$clim | tr '\012' ' ' >> sel.$vis

if ($rpt == "report") then
grep -v '#' basestats | tr '-' ' ' | awk '{if($6>=plim) printf "%s", "ant("$2")("$3"),"}' plim=$plim | tr '\012' ' ' >> scatter
grep -v '#' basestats | tr '-' ' ' | awk '{if($5>=clim) printf "%s", "ant("$2")("$3"),"}' clim=$clim | tr '\012' ' ' >> closure
endif
set na = `cat base | tr '-' ' ' | awk '{printf "%s\n %s\n", $1,$2}' | \
	sort -nu | wc | awk '{print $1}'`
set nt = `wc base | awk '{print $1}'`
set nb = `cat sel.$vis | tr ',' ' ' | wc | awk '{print $2}'`

#     find set of antennas involved in the bad baselines
grep -v '#' basestats | tr '-' ' ' | awk '{if($6>=plim) printf "%s\n %s\n",$2,$3}' plim=$plim | sed s/" "// | sort -nu > ants.lis
set nba = `cat ants.lis |  tr '\012' ' ' | wc | awk '{print $2}'`
set bar = `echo $nba $nb | awk '{printf "%3.1f",$2*2/$1}'`

#     find number of baselines and ants with closure > $clim deg
set nbc=`grep -v '#' basestats | tr '-' ' ' | awk '{if($5>=clim) print $5}' clim=$clim | wc | awk '{print $1}'` 
grep -v '#' basestats | tr '-' ' ' | awk '{if($5>=clim) printf "%s\n %s\n",$2,$3}' clim=$clim | sed s/" "// | sort -nu > cants.lis

finish:
rm -rf *.lis basestats base data stats list log.* dump

exit 0
