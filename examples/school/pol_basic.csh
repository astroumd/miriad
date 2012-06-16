#!/bin/csh
# pol_basic.csh   version 1.0

# basic csh script to reduce CARMA continuum polarization data with Miriad
# assumes FULLPOL correlator mode with 8 wideband windows, win(1,3,5,7,9,11,13,15)
# Dick Plambeck, 31-may-2012

# ---------------------------------------------------------------------------------------#
# user-settable parameters
#
set RAW = ...              # name of miriad dataset
set REFANT = 1             # MUST be a 10-m telescope!
set SRC = ...              # source name
set PASSCAL = ...          # passband calibrator name
set GAINCAL = ...          # gain calibrator name
set GAINFLUX = ...         # flux density of gain calibrator, if you know it
set LEAKFILE = "None"      # visibility data file with leak corrections, if available
set MAP = ...              # continuum map name
set I_RMS = ...            # noise in total intensity map
set QU_RMS = ...           # measured noise in Stokes Q,U,V maps
set REGION = 'arcsec,box(12,-12,-12,12)'	# region to plot
# ---------------------------------------------------------------------------------------#

goto start

start:

  # ------------------------------------------------------------------------------------- #
  # step 1: 'xyphase' calibration
  #
  # The 'xyphase' is the LCP-RCP phase difference.  A direct calibration of the xyphase 
  # is possible only on the 10-m telescopes by observing a polarized noise source.  This
  # calibration is performed automatically every ~45 minutes by the standard observing
  # script.  Xyphase calibration data are labeled 'purpose(P)' in the Miriad dataset.
  # ------------------------------------------------------------------------------------- #

    xyauto vis=$RAW select='purpose(P)' 
        # ... fits purpose(P) data, stores phase correction as a bandpass
 
    smagpplt vis=$RAW options=bandpass,nofit,wrap device=/xs yrange=-180,180 \
      xaxis=chan yaxis=phase
        # ... examine result; all phases will be zero except for C1-C6 LCP

    rm -r wide.xy
    uvcat vis=$RAW out=wide.xy options=nopol select='-source(noise),-auto,-purpose(P)' 
        # ... rewrite data to apply the correction


  # ------------------------------------------------------------------------------------- #
  # step 2: passband correction
  #
  # At this point phase(LCP) = phase(RCP) on the 10-m, but not the 6-m, telescopes.
  # It is essential to choose a 10-m telescope as the REFANT when fitting the passband 
  # in order to transfer the xyphase calibration to the 6-m telescopes.
  # ------------------------------------------------------------------------------------- #

    mfcal vis=wide.xy select='source('$PASSCAL')' interval=0.1 refant=$REFANT 
    smagpplt vis=wide.xy options=bandpass,nofit,wrap device=/xs yrange=-180,180 \
      xaxis=chan yaxis=phase
        # ... examine the result

    rm -r wide.pb
    uvcat vis=wide.xy out=wide.pb options=nocal,nopol 
        # ... rewrite data to apply the correction

    rm -r wide.av
    uvaver vis=wide.pb out=wide.av line=chan,8,1,47,47 options=nocal
        # ... condense to just 8 channels to speed further analysis


  # ------------------------------------------------------------------------------------- #
  # step 3: leakage calibration
  # 
  # Leakage corrections compensate for cross-coupling between the LCP and RCP channels.
  # Leakages depend on the observing frequency and (unfortunately) the observing date
  # (because of receiver swaps).  If feasible, use standard leakage tables.  For now, 
  # obtain these by emailing chat@astro.berkeley.edu.  Or, if the gain calibrator was 
  # observed  over a sufficiently wide range of parallactic angle (> 90 degrees, say), 
  # fit the leakages to these data, as shown below.  Delete flux=$GAINFLUX if flux of
  # gain calibrator is unknown.
  # ------------------------------------------------------------------------------------- #
  
    uvplt vis=wide.av select='source('$GAINCAL'),pol(LL)' axis=time,parang device=/xs \
	  options=nobase,nopol
        # ... plot parallactic angle coverage of gain calibrator

    if $LEAKFILE == "None" then
      gpcal vis=wide.av options=circular,qusolve,noxy,nopass flux=$GAINFLUX interval=0.5 \
        refant=$REFANT select='source('$GAINCAL')' 
          # ... fit leakages (and gains) to gain calibrator in this data set
    else    
      gpcopy vis=$LEAKFILE out=wide.av options=nocal,nopass
      mfcal vis=wide.av select='source('$GAINCAL')' interval=0.5 refant=$REFANT \
    .   flux=$GAINFLUX
          # ... copy leakages from $LEAKFILE, fit gains separately 
    endif
 
    gpaver vis=wide.av options=scalar interval=15
        # smooth gains to 15-minute time resolution
    puthd in=wide.av/senmodel value='GSV' type=ascii
	    # tells Miriad to include gain in variance calculation inside invert


  # ------------------------------------------------------------------------------------- #
  # step 4: generate maps, measure noise levels
  #
  # At this point the data are fully calibrated.  The xyphase and passband corrections were
  # applied in writing wide.av; the leakage and gains items are present in the dataset;
  # ------------------------------------------------------------------------------------- #
  
    rm -r  $MAP.I.mp $MAP.Q.mp $MAP.U.mp $MAP.V.mp $MAP.bm
    invert vis=wide.av line=chan,8,1,1 \
      map=$MAP.I.mp,$MAP.Q.mp,$MAP.U.mp,$MAP.V.mp beam=$MAP.bm stokes=I,Q,U,V sup=0 \
      'select=source('$SRC')' options=mfs,systemp cell=0.25 imsize=512

    rm noiseList
    foreach MP ($MAP.I $MAP.Q $MAP.U $MAP.V)
      rm -r $MP.sl
      clean map=$MP.mp beam=$MAP.bm out=$MP.sl niters=3000
      rm -r $MP.cm
      restor map=$MP.mp beam=$MAP.bm model=$MP.sl out=$MP.cm 
      cgdisp in=$MP.cm device=/xs region='arcsec,box(20,-20,-20,20)' labtyp=arcsec 
      echo " " >> noiseList
      echo $MP".cm" >> noiseList
      imlist options=stat in=$MP.cm region='arcsec,box(20,-20,-20,-5)' | tail -2 >> noiseList
        # ... measure actual noise in a box offset from the center; change region if
        # ... source extends into it
    end

    tail -20 noiseList
        # ... rms for I probably will be greater than for Q,U,V

goto end

  # ------------------------------------------------------------------------------------- #
  # step 5: plot the polarization; enter noise levels I_RMS and QU_RMS before proceeding
  # ------------------------------------------------------------------------------------- #
  
    cgdisp in=$MAP.I.cm,$MAP.Q.cm,$MAP.U.cm type=pixel,contour,contour options=full \
      region=$REGION labtyp=hms,dms cols1=2 cols2=4 slev=a,$QU_RMS,a,$QU_RMS \
      levs1=-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,3,4,5,6,7,8,9,10,11,12,13,14,15 \
      levs2=-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,3,4,5,6,7,8,9,10,11,12,13,14,15 \
      line=1,3,3 device=/xs
        # ... >3 sigma detection of Stokes Q and/or U needed for a polarization detection
        # ... remember that Q and U can be positive or negative

    rm -r $MAP.poli.cm $MAP.polm.cm $MAP.pa.cm
    impol poli=$MAP.poli.cm polm=$MAP.polm.cm pa=$MAP.pa.cm sigma=$QU_RMS,$I_RMS \
      in=$MAP.Q.cm,$MAP.U.cm,$MAP.I.cm sncut=3,2
        # ... derive pol intensity and PA maps from Stokes parameters     

    cgdisp in=$MAP.I.cm,$MAP.poli.cm,$MAP.pa.cm type=contour,amp,angle \
      region=$REGION options=full labtyp=hms,dms vecfac=1.2,4,4 beamtyp=b,l,4 \
      lines=1,1,10 cols1=1 slev=a,$I_RMS \
      levs1=-6,-5,-4,-3,3,4,5,6,8,10,15,20,25,30,35,40,45,50,55 \
      device=/xs
        # ... plot polarization vectors on total intensity map

  # ------------------------------------------------------------------------------------- #
  # cleanup
  # ------------------------------------------------------------------------------------- #

    rm -r wide.xy
    rm -r wide.pb
    rm -r $MAP.*.sl $MAP.*.mp

end:
