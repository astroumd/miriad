#!/bin/csh -vf

goto start

start:
hex19.csh   config3 -30 0.05 mosmem
hex19.csh   config3 -30 0.05 default
hex19.csh   config3 -30 0.05 joint

goto end

end:
