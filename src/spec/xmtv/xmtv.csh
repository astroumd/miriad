#!/bin/csh -f
# This script will enable you to run the XMtv application without
# having to move the XMtv resource file to your home or defaults directory.

set noglob

setenv XAPPLRESDIR /lma/mirth/doc/misc

exec xmtv.exe ${*:q}

