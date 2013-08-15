#!/bin/csh -vf

echo $0 Results written to file: vla_beams.results
echo mchw 15 Aug 2013


foreach dec (30 0 -30)
  foreach config (vla_d vla_c vla_b vla_a)
    foreach weight (sup=0 robust=0.5 robust=0 uniform)
      ./vla_mfs.csh $config $dec -1,1,.1 1 $weight '-shadow(25)'
    end
  end
end
end:
