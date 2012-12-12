#!/bin/csh -vf

goto start

start:
hex19.csh   config3 -30 0.05 mosmem
hex19.csh   config3 -30 0.05 default
hex19.csh   config3 -30 0.05 joint
goto end

hex19.csh   config3 -30 0.1 mosmem
hex19.csh   config3 -30 0.1 default
hex19.csh   config3 -30 0.1 joint

hex19.csh   config2 -30 0.1 mosmem
hex19.csh   config2 -30 0.1 default
hex19.csh   config2 -30 0.1 joint

hex19.csh   config2 -30 0.07 mosmem
hex19.csh   config2 -30 0.07 default
hex19.csh   config2 -30 0.07 joint
goto end

end:
