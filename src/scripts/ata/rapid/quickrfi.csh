#! /usr/bin/tcsh -f
#
# $Id$
#


if ($#argv < 1) then
echo "Enter Frequency: (MHz)"
set freq = $<
else
set freq = $1
endif

if (! -e ~/bin/karto/rfi/rfi$freq.list ) then
echo "No rfi lists for $freq MHz! Run QuickObs and QuickReduc at $freq MHz to produce a listing at this frequency."
goto finish
endif

cp ~/bin/karto/rfi/rfi$freq.list rfi.list
if ($2 == copy) goto finish
flag:
foreach chan (`grep -v o rfi.list | awk '{print $1}'`)
echo "Flagging channel $chan"
uvflag 'vis=fx*1430*' flagval=f options=none line=chan,1,$chan
end

echo "Flagging first 100 channels"
uvflag 'vis=fx*1430*' flagval=f options=none line=chan,100
echo "Flagging last 100 channels"
uvflag 'vis=fx*1430*' flagval=f options=none line=chan,100,925
echo "RFI flagging complete!"
uvflag vis='fx*1430*' flagval=f select='ant(1,19,23,37),pol(xx)' line=chan,256,513 options=none

finish:

exit 0
