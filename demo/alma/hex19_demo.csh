#!/bin/csh -vf

goto start

hex19.csh   config3 -30 0.05 mosmem
hex19.csh   config3 -30 0.05 default
hex19.csh   config3 -30 0.05 joint

start:
hex19.csh   config3 -30 0.1 mosmem
hex19.csh   config3 -30 0.1 default
hex19.csh   config3 -30 0.1 joint
goto end

end:
