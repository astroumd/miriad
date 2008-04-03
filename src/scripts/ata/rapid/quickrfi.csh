#! /usr/bin/tcsh -f
#
# $Id$
#


if (-e rfi.list) goto flag

# It's okay if this throws an error on an offsite install of MIRIAD
cp ~/bin/karto/rfi.list .

flag:
foreach chan (`grep -v o rfi.list | awk '{print $1}'`)
echo "Flagging channel $chan"
uvflag 'vis=fx*1430' flagval=f options=none line=chan,1,$chan
end

echo "Flagging first 100 channels"
uvflag 'vis=fx*1430' flagval=f options=none line=chan,100
echo "Flagging last 100 channels"
uvflag 'vis=fx*1430' flagval=f options=none line=chan,100,925
echo "RFI flagging complete!"
uvflag vis='fx*1430' flagval=f select='ant(1,19,23,37),pol(xx)' line=chan,256,513 options=none
exit 0
