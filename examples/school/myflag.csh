#!/bin/csh -fe

# The script must be called as follows:
#   myflag.csh  vis=<vis> 
#   where <vis> is the name of the miriad file

# Override user supplied parameters with command line arguments
  set vis = ""
  foreach a ( $* )
    set $a
  end
  if ($vis == "") then
     echo "Error setting visibility file"
  endif

# Example flagging commands
# uvflag vis=$vis flagval=flag select="time(12:00:00,12:15:00:00)"
# uvflag vis=$vis flagval=flag select="ant(12)"
# uvflag vis=$vis flagval=flag select="ant(17),win(1)"

