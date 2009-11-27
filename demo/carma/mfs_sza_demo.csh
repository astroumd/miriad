#!/bin/csh -vf

goto m87
goto mfs64

mfs_sza.csh sza_A 60 -1,1,.1 1 sup=0
mfs_sza.csh sza_A 60 -1,1,.1 1 robust=.5
mfs_sza.csh sza_A 60 -1,1,.1 1 uniform
mfs_sza.csh sza_B 60 -1,1,.1 1 sup=0
mfs_sza.csh sza_B 60 -1,1,.1 1 robust=.5
mfs_sza.csh sza_B 60 -1,1,.1 1 uniform
tail beams.results

# mfs8 sidelobe level is MUCH lower than mfs1 with robust and uniform weighting
mfs8:
mfs_sza.csh sza_A 60 -1,1,.1 8 sup=0
mfs_sza.csh sza_A 60 -1,1,.1 8 robust=.5
mfs_sza.csh sza_A 60 -1,1,.1 8 uniform
mfs_sza.csh sza_B 60 -1,1,.1 8 sup=0
mfs_sza.csh sza_B 60 -1,1,.1 8 robust=.5
mfs_sza.csh sza_B 60 -1,1,.1 8 uniform
tail beams.results

# mfs64 has ~10% higher sidelobes than mfs8 with robust and uniform weighting.
mfs64:
mfs_sza.csh sza_A 60 -1,1,.1 64 sup=0
mfs_sza.csh sza_A 60 -1,1,.1 64 robust=.5
mfs_sza.csh sza_A 60 -1,1,.1 64 uniform
mfs_sza.csh sza_B 60 -1,1,.1 64 sup=0
mfs_sza.csh sza_B 60 -1,1,.1 64 robust=.5
mfs_sza.csh sza_B 60 -1,1,.1 64 uniform
tail beams.results


# DEC 12 for M87  mfs8 with robust and uniform weighting.
m87:
mfs_sza.csh sza_A 12 -1,1,.1 64 sup=0
mfs_sza.csh sza_A 12 -1,1,.1 64 robust=.5
mfs_sza.csh sza_A 12 -1,1,.1 64 uniform
mfs_sza.csh sza_B 12 -1,1,.1 64 sup=0
mfs_sza.csh sza_B 12 -1,1,.1 64 robust=.5
mfs_sza.csh sza_B 60 -1,1,.1 64 uniform
tail beams.results
