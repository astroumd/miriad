#!/bin/csh -fe

# A very simple reduction script for continuum-based observations.
# Assumes:
#    (1) Baseline solution has been applied
#    (2) Flux of the gain calibrator is known
#
# The script applies the following calibrations:
#    (1) Applies baseline solution
#    (2) Flags shadowed baselines
#    (3) Applies passband calibration
#    (4) Applies gain     calibration
#    (5) Makes dirty image


# Specify name of the miriad file
  set vis = cs040.test.1.miriad

# Set other parameters
  set source    = "m51sn"     # Science target
  set passband  = '3c454.3'   # Passband calibrator
  set gain      = '2038+145'  # Gain calibrator
  set flux_gain = 2.5         # Flux of gain calibrator Janskys
  set refant    = 8           # Reference antenna

# Copy the file
  set vis_copy = copy.mir
  rm -rf $vis_copy
  uvcat vis=$vis out=$vis_copy options=nowide select="-source(noise),-auto"

# Flag data
  csflag vis=$vis_copy  # Shadowed baselines

# Passband
  mfcal vis=$vis_copy select="source($passband)" interval=1 refant=$refant

# Gain calibration
  mfcal vis=$vis_copy select="source($gain)" interval=12 refant=$refant flux=$flux_gain options=nopass

# Plot gain solutions
  gpplt device=/xs vis=$vis_copy nxy=5,3 
  echo -n "*** Plotting gain amplitudes ***"
  echo -n "*** HIT RETURN TO CONTINUE   ***"
  set ans = "$<"
  gpplt device=/xs vis=$vis_copy nxy=5,3  yrange=-200,200 options=wrap yaxis=phase
  echo -n "*** Plotting gain phases   ***"
  echo -n "*** HIT RETURN TO CONTINUE ***"
  set ans = "$<"

# Make dirty map
  rm -rf $source.{map,beam}
  invert vis=$vis_copy map=$source.map beam=$source.beam robust=2 \
             options=mfs,systemp,mosaic select="source($source)" \
             cell=2 imsize=257
  cgdisp device=/xs in=$source.map labtyp=arcsec options=full,wedge
  echo "*** Plotting dirty image   ***"

