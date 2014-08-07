#!/bin/csh -fe
#
# Purpose:
#    This MIRIAD reduction script reduces CARMA UV data, shows diagnostic
#    plots, and produces images. The script is designed for tracks that
#    use a single correlator configuration and one or more designated 
#    wide-band windows.
#
# Author: John Carpenter
#
# Instructions:
#    1) Edit the user-supplied parameters below
#    2) Run the script as:
#            carma_calibrate.csh 
#       All user options can be over-ridden on the command line as, e.g.,
#            carma_calibrate.csh plots=0 linecal=0
#       where 0 -> False  and  1 -> True.
#            
#    3) By default, the raw data are in the directory "raw/",
#       the reduced UV data are placed in the directory "reduced/",
#       and the directory "tmp/" is used as a scratch area.
#       These directory names can be modified below.
#
# Tips:
#    1) You will likely need to re-run the script several times. You can turn
#       off plots for selected sections using the command line. For example,
#       to skip the tsys and general track plots, type:  
#           carma_calibrate.csh plot_track=0
#       The available plot sections are
#          plot_track    : Tsys vs time, raw amp vs. time, raw phases vs time,
#                          raw spectra on passband calibrator
#          plot_linecal  : Line cal phases vs time
#          plot_noise    : Noise source passband solution (amplitudes and phases)
#          plot_passband : Astronomical source passband solution for
#                          wide and narrow band data. Also plots passband
#                          calibrated spectra on passband and gain calibrators.
#          plot_fluxcal  : Amplitude vs uvdistance for flux calibrator
#          plot_gains    : Antenna-based mmplitude and phase vs time.
#          plot_cal      : Amplitude and phase vs. uv distance on phase 
#                          calibrator. Close phase vs time on gain calibrator.
#          plot_images   : Dirty images for specified sources.
#
#    2) If you need to restart the script, you can jump to the start of a 
#       specific section. e.g.  carma_calibrate.csh goto=passband
#       will re-start the script at the passband calibration step.
#       The available breakpoints (in order that they are executed) are: 
#            baseline : Apply baseline solution
#            flag     : Apply general flagging (e.g. high elevation, shadow, 
#                       edge channels, bad windows, bad antennas)
#            myflag   : Apply custom flagging (e.g. time ranges)
#            linecal  : Apply line-length calibration
#            passband : Apply passband
#            fluxcal  : Apply fluxcal
#            gaincal  : Apply gain calibration
#            images   : Produce dirty images
#
#    3) Most tracks will need custom flagging. This is best done as follows:
#           a) Create a csh script file called "<vis>.csh", where "<vis>" is 
#              the name of the miriad file. For example, if your miriad is 
#              called names c0940.1E_230HLTau.3.miriad, the flags file should 
#              be called c0940.1E_230HLTau.3.csh . 
#
#           b) The first lines in the csh script should be: 
#                 #!/bin/csh -fe
#
#                 # Example flagging commands
#                 uvflag vis=$vis flagval=flag select="time(12:00:00,12:15:00:00)"
#                 uvflag vis=$vis flagval=flag select="ant(12)"
#                 uvflag vis=$vis flagval=flag select="ant(17),win(1)"
#
# Known bugs:
#    1) If two or more windows have exactly the same mean frequency, then 
#       the passband calibration will be the average of the two windows.
#       These windows will need to be processed separately with separate
#       calls to the script.
#
#    2) If the script is restarted at gain calibration, then the flux 
#       calibration step is skipped and the flux of the gain calibrator
#       will not be remeasured. If restarting the script at the gaincal
#       step, the gain calibrator flux should be specified within the script
#       or on the command line. e.g.   
#             carma_calibrate.csh goto=gaincal flux_gaincal=4.3
#
#    3) When the noise source is split from the astronomical data, miriad
#       somethings think there are multiple correlator configurations in the
#       track. mfcal will then fail since there are too many windows.
#       The solution is to select a time range where only one noise cal 
#       integration is present, and flag the remaining noise integrations.
#       These flagging commands can be placed the <vis>.csh flag file 
#       described above.
#
# ************************************************
# ******* START USER-SUPPLIED PARAMETERS ***********
# ************************************************

# Raw visibility file. This file is NOT modified by the script. The file 
# is assumed located in the directory specified by the variable $dir_raw.
  set vis           = c1189.18E_115NGC520.1.mir
  set sci           = 1  # 1 -> 6/10m track;  2 -> 3.5m track
  set iscarma23     = 0  # 1 -> Is a carma 23 track; 0 -> is not a carma23 track

# Directories containing the raw data and working directories
  set dir_raw       = "raw"     # Directory with raw data
  set dir_reduced   = "reduced" # Directory with reduced data
  set dir_tmp       = "tmp"     # Scratch directory

# Flux calibration parameters.
#    source_fluxcal : name of the flux calibrator
#    flux_fluxcal   : Flux in Jy for source_fluxcal, or brightness temperature
#                     if source_fluxcal is a planet. Set to "" to use the fluxes
#                     in the miriad flux catalog.
#    flux_gaincal   : Flux in Jy for gain calibrator(s), if known.
#                     If set, then a flux must be given for each gain
#                     calibrator.
# The flux calibration procedure is as follows:
#    1) If flux_gaincal is set, that flux is used during gain calibration.
#    2) If flux_gaincal is not set, then source_fluxcal 
#       is used to calibrate the fluxes.
#    3) If neither source_fluxcal and flux_gaincal are set, then the flux 
#       for source_gaincal is determined from the miriad flux table in 
#       $MIR/cat/FluxSource.cat.
  set flux_gaincal    = ""
  set source_fluxcal  = mars
  set flux_fluxcal    = ""
  set flux_uttime     = ""  # List utrange (e.g. time(20:00:00,20:50:00) "
  set flux_elevation  = ""  # List elevation range to select (e.g. 30,40). 
                            # This does not work because of a bug in miriad.
                            # It uses ant 1 to select elevations.

# Source names
  set source_passcal = 1927+739 # Passband calibrator
  set source_gaincal = 1419+543 # Gain calibrators
  set source_image   = NGC5204  # Sources to image (comma separated list)

# Set windows.
# win_wide : indicates the wideband windows used for gain calibration.
#            If all windows are wide, then use: set win_wide= ""
# win_flag : indicates any windows that should be ignored (i.e. flagged).
#            If you want to use all windows, then use: set win_flag = ""
# win_edge : Windows which should have edge channels flagged. "" -> all windows
#            WIN_EDGE DOES NOT WORK PROPERLY DUE TO A BUG IN MIRIAD.
# edgechan : Number of edge channels to flag. If edgechan is a single number,
#            then it applies to all windows specified with win_edge.
#            Otherwise, you can specify a difference number of channels per 
#            window. For example, edgechan = "1,2,3" and win_edge = "4,5,6"
#            will flag the edge 1, 2, and 3 channels in window 4, 5, and 6
#            respectively.
# split_pb : If "1", then the passband calibrator is too weak to passband
#            calibrate the narrow bands channel-by-channel. In this case,
#            channel-by-channel calibration is done by the noise source only.
#            If "0", then channel-by-channel calibration is done by the 
#            passband calibrator.
# noise_bl : Apply baseline-based noise passband calibration
  set win_wide = "6,7,8,14,15,16"
  set win_flag = ""
  set win_edge = ""
  set edgechan = "1"
  set split_pb = "1"
  set noise_bl = "0"

# Calibration steps  (0-> skip,  1-> execute)
  set linecal   = 0   # Apply linecal. Not recommended.
  set noise     = 1   # Apply noise source passband (amplitude and phase)
  set autocc    = 1   # Apply auto correlation passband (amplitude only)
  set fluxcal   = 1   # Flux calibration
  set images    = 1   # Make dirty images

# Time intervals (in minutes)
  set interval_flux = 1.0       # [minutes]  Interval for flux calibration
  set interval_gain = 12.0      # [minutes]  Interval for gain calibration
  set interval_pb   = 20.0      # [minutes]  Interval for passband calibration

# Image (invert) parameters
  set cell         = 2
  set imsize       = 129
  set robust       = 2
  set offset       = ""   # Choose the image reference pixel.

# Miscellaneous options
  set antpos        = ""  # Antenna position file. If blank, no solution is applied
  set badant        = ""   # "bad" antenna; e.g. "4,7" to flag antennas 4 and 7
  set badres        = 30  # Minimum visibility percentage to use for bootflux
  set dotsize       = 15  # Dot size for plots
  set nb_polyfit    = 0   # Order of polynomial for narrow-band passband fit. 
                          # 0-> cnst, 1->linear, etc... This does not work well.
  set refant        = 12 # Reference antenna for selfcal solutions
  set taver         = 3.1 # Averaging time for bootflux
  set goto          = ""  # Indicates starting point for script

# Plotting options. The specific plot options override the "plot" variable.
# For example, to show all plots except the linecal plots, type:
# carma_calibrate.csh plot_linecal=0    
  set plot          = 1   # Show all plots
  set plot_track    = ""  # Plot track information at beginning of track
  set plot_linecal  = ""  # Plot line cal
  set plot_noise    = ""  # Plot noise source data
  set plot_passband = ""  # Plot wideband data
  set plot_fluxcal  = ""  # Plot flux calibrator
  set plot_gains    = ""  # Plot gains
  set plot_cal      = ""  # Plot calibrated data
  set plot_images   = ""  # Plot dirty images

# ************************************************
# ******* END USER-SUPPLIED PARAMETERS  **********
# *******                               **********
# ******* User-specific data flagging   **********
# ******* can be added below.           **********
# ************************************************


# Override user supplied parameters with command line arguments
  foreach a ( $* )
    set nargs = `echo $a | awk -F= '{print NF}'`
    set var   = `echo $a | awk -F= '{print $1}'`
    if ("$nargs" == 1) then
       echo "Error reading command line option '$a'"
       echo "Format is $a=<value>"
       exit
    endif
    set $a
  end

set orig_vis=$vis

# Reset plot variables
  if ($plot_cal      == "") set plot_cal      = $plot
  if ($plot_gains    == "") set plot_gains    = $plot
  if ($plot_fluxcal  == "") set plot_fluxcal  = $plot
  if ($plot_images   == "") set plot_images   = $plot
  if ($plot_linecal  == "") set plot_linecal  = $plot
  if ($plot_noise    == "") set plot_noise    = $plot
  if ($plot_passband == "") set plot_passband = $plot
  if ($plot_track    == "") set plot_track    = $plot


# Make directories
  if (!(-e "$dir_tmp"))     mkdir $dir_tmp
  if (!(-e "$dir_reduced")) mkdir $dir_reduced


# Move into temporary directory
  set starting_dir = `pwd`
  cd $dir_tmp


# Get root name of raw visibility data
  if ($vis:e == 'mir' || $vis:e == 'miriad') then
     set root = $vis:r
  else
     set root = $vis
  endif


# Output miriad file names at end of various calibration steps
# These are needed so that the reduction script can be restarted.
  set vis_astro          = ""
  set vis_noise          = ""
  set vis_narrow         = ""
  set vis_wide           = ""
  set cal_wide           = ""
  set cal_narrow         = ""
  set mir_raw            = "raw.mir"
  set mir_baseline       = "base.mir"
  set mir_baseline_astro = "astro_base.mir"
  set mir_baseline_noise = "noise_base.mir"
  set mir_linecal_astro  = "astro_lc.mir"
  set mir_pb_astro       = "astro_pb.mir"
  set mir_pb_wide        = "astro_pb_wide.mir"
  set mir_pb_narrow      = "astro_pb_narrow.mir"
  set mir_cal_wide       = $starting_dir/$dir_reduced/${root}_wide.mir
  set mir_cal_narrow     = $starting_dir/$dir_reduced/${root}_narrow.mir


# Skip to certain steps
  if ($goto != "") then
     # Check that raw data exists
       if (-e "$dir_tmp/$mir_raw") then
          echo "Error starting script at $goto. $dir_tmp/$mir_raw not found."
          exit
       endif

     # Print warning if skipping flux calibration
       if ($goto == "gaincal" && $flux_gaincal == "" && $source_fluxcal == "") then
          echo "WARNING: You are skipping the flux calibration step."
          sleep 2
       endif

     # Jump
       goto $goto
  endif


# ***********************
# **** COPY RAW DATA ****
# ***********************
  set out = $mir_raw
  rm -rf $out
  echo ""
  echo "*** Making copy of raw data  (vis=$dir_raw/$vis out=$dir_tmp/$out)"
  set select=""
  if ($iscarma23 == 1) then
     set select='select=win(1,3,5,7,9,11,13,15)'
  else if ($sci == 2) then
     # Get LO frequency
     set listobsFile = listobs
     listobs vis=$starting_dir/$dir_raw/$vis log=$listobsFile
     set lofreq=`awk '/First LO/ {print $10}' $listobsFile`
     set intfreq=`calc -i "$lofreq"`
     if ($intfreq < 40) then
        set select='select=win(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)'
     else
        set select='select=-win(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)'
     endif
  endif
  uvcat vis=$starting_dir/$dir_raw/$vis out=$out options=nowide $select
  set vis = $out


# ***************************
# **** BASELINE SOLUTION ****
# ***************************
baseline:
  set vis = $mir_raw
  set out = $mir_baseline
  rm -rf $out
  if ($antpos != "") then
     echo ""
     echo "*** Applying baseline solution   (vis=$vis out=$out antpos=$antpos)"
     uvedit vis=$vis out=$out apfile=$starting_dir/$antpos
     set vis = $out
  endif


# ******************
# **** FLAGGING ****
# ******************
flag:
  # Set file
    if ($vis == "") then
       set vis = $mir_baseline
       if ($antpos != "") set vis = $mir_raw
    endif

  # Flag shadowed baselines
    echo ""
    echo "*** Flagging shadowed baselines  (vis=$vis)"
    csflag vis=$vis

  # Flag high elevation data
    uvflag vis=$vis flagval=flag select="el(85,90)"

  # Flag low elevation data for sci2, as the 3.5m antennas can't
  # go below 17 degrees and can sit on the elevation limit integrating
  # when the source is below el=17.
    if ( "$sci" == "2" ) then
        echo "*** Flagging data at low elevation  (vis=$vis)"
        uvflag vis=$vis flagval=f select="el(0,17)"
    endif

  # Flag used-specified bad antennas
    if ($badant != "") then
       echo ""
       echo "*** Flagging antennas: $badant"
       uvflag vis=$vis flagval=f select="ant($badant)"
    endif

  # Flag user-specified bad windows
  # This has to be done one window at a time since uvflag cannot handle
  # non-contiguous windows in the selected command.
    if ($win_flag != "") then
       echo ""
       echo "*** Flagging windows $win_flag  (vis=$vis)"
       set windows = `echo $win_flag | sed 's/,/ /g'`
       foreach w ($windows)
          uvflag vis=$vis flagval=f select="win($w)"
       end
    endif

  # Flag edge channels.
  # The same edgechan is used for all windows. 
      if ("$edgechan" != "0" && "$edgechan" != "") then
       if ("$win_edge" == "") then
          echo ""
          echo "*** Flagging $edgechan edge channels in all windows (vis=$vis)"
          uvflag vis=$vis flagval=flag edge=$edgechan
       else 
          echo "ERROR: DUE TO BUG IN MIRIAD, WIN_EDGE IS DISABLED.\nSet WIN_EDGE to \"\""
          # Set arrays
            set ec = `echo $edgechan | sed 's/,/ /g'`
            set we = `echo $win_edge | sed 's/,/ /g'`
            set nec = $#ec
            set nwe = $#we

          # Check inputs
            if ($nec > 1 && $nwe != $nec) then
               echo "Error entering edgechan and win_edge variables."
               echo "They must match in size if there is more than one edgechan."
               exit
            endif

          # Loop over windows
            set n = 0
            while ($n < $nwe)
               @ n = $n + 1

               set w = $we[$n]
               set e = $ec[1]
               if ($n < $nec) then
                  set e = $ec[$n]
                endif
               if ($e > 0) then
                  echo ""
                  echo "*** Flagging $e edge channels for window $w (vis=$vis)"
                  uvflag vis=$vis flagval=flag edge=$e select="win($w)"
               endif
            end
       endif
    endif

# *** PUT USER-SUPPLIED FLAGGING HERE ***
# If a file called $orig_vis.csh exists
# in $starting_dir then it will be run to do the 
# flagging. 
myflag:
  if ($vis == "") then
     set vis = $mir_baseline
     if ($antpos != "") set vis = $mir_raw
  endif
  set flagfile = $starting_dir/$orig_vis:r.csh
  echo ""
  if ( -e $flagfile ) then
     echo "####  USING CUSTOM FLAGGING FOR $vis ($flagfile) ####"
     set visflag = $vis
     source $flagfile
  else 
     echo "####  NO CUSTOM FLAGGING FOR $vis ####"
  endif 


# ********************
# **** PLOT TRACK ****
# ********************
# Plot track info
  if ($plot_track != "0") then
     # tau230
       echo ""
       echo "*** Plotting tau230"
       echo "*** To skip plotting raw data, type plot_track=0 when starting script."
       varplt device=/xs vis=$vis yaxis=tau230
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # rmspath
       echo ""
       echo "*** Plotting phase monitor rms"
       echo "*** To skip plotting raw data, type plot_track=0 when starting script."
       varplt device=/xs vis=$vis yaxis=rmspath
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Tsys
       echo -n "*** Do you want to plot the system temperatures (Y/N)? "
       set ans = "$<"
       if ($ans == "Y" || $ans == "y" || $ans == "1") then 
          echo ""
          echo "*** Plotting tsys"
          echo "*** Look for antennas with high or variable tsys."
          echo "*** Note that all CARMA antennas are shown, even if they "
          echo "*** were not online during the track."
          echo "*** To skip plotting raw data, type plot_track=0 when starting script."
          varplt device=/xs vis=$vis nxy=5,3 yaxis=systemp
          echo -n "*** HIT RETURN TO CONTINUE ***"
          set ans = "$<"
       endif

     # Amplitudes
       set win_track = 3   # Default window to plot
       if ($win_wide != "") then
          set w = `echo $win_wide | sed 's/,/ /g'`
          set nw = $#w
          set win_track = $w[$nw]
       endif
       echo ""
       echo "*** Raw amplitudes in window $win_track ***"
       echo "*** Look for integrations with abnormally high or low amplitudes."
       echo "*** To skip plotting raw data, type plot_track=0 when starting script."
       smauvplt device=/xs vis=$vis select="-source(noise),win($win_track),-auto"
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Phases
       echo ""
       echo "*** Raw phases in window $win_track ***"
       echo "*** Look for incoherent phases on calibrators."
       echo "*** To skip plotting raw data, type plot_track=0 when starting script."
       smauvplt device=/xs vis=$vis select="-source(noise),purpose(bgf),win($win_track),-auto" axis=time,phase
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Spectra
       if ($source_passcal != "") then
          echo ""
          echo "*** Plotting raw spectra for $source_passcal ***"
          echo "*** Look for windows with poor signal to noise."
          echo "*** To skip plotting raw data, type plot_track=0 when starting script."
          smauvspec device=/xs vis=$vis select="source($source_passcal),-auto" interval=10000 axis=chan,both
          echo -n "*** HIT RETURN TO CONTINUE ***"
          set ans = "$<"
       endif
  endif


# ***************************************************************
# **** SPLIT FILES INTO NOISE SOURCE AND ASTRONOMICAL SOURCE ****
# ***************************************************************
# This is needed since linecal should not be applied to noise source data.
  set vis_astro = $mir_baseline_astro
  set vis_noise = $mir_baseline_noise
  rm -rf $vis_noise $vis_astro
  echo ""
  echo "*** Creating file with noise source data  (vis=$vis out=$vis_noise)"
  uvcat vis=$vis out=$vis_noise select="source(noise)"
  echo ""
  echo "*** Creating file with astronomical data only  (vis=$vis out=$vis_astro)"
  uvcat vis=$vis out=$vis_astro select="-source(noise)"


# *****************
# **** LINECAL ****
# *****************
# Apply line calibrations
linecal:
  if ($vis_astro == "") set vis_astro = $mir_baseline_astro
  if ($vis_noise == "") set vis_noise = $mir_baseline_noise
  set out = $mir_linecal_astro
  rm -rf $out
  if ($linecal != "0") then
     # Derive linecal
       echo ""
       echo "*** Deriving linecal  (vis=$vis)"
       linecal vis=$vis_astro

     # Plot solution
       if ($plot_linecal != "0") then
          echo ""
          echo "*** Plotting linecal phases ***"
          smagpplt device=/xs vis=$vis_astro yaxis=phase options=wrap,nofit \
                   yrange=-200,200 nxy=5,3 
          echo -n "*** HIT RETURN TO CONTINUE ***"
          set ans = "$<"
       endif

     # Apply linecal
       echo ""
       echo "*** Applying linecal  (vis=$vis_astro out=$out)"
       uvcat vis=$vis_astro out=$out options=nopass
       set vis_astro = $out
  endif


# ***********************************
# **** NON-ASTRONOMICAL PASSBAND ****
# ***********************************
passband:
  # Set files
    if ($vis_astro == "") then
       set vis_astro = $mir_baseline_astro
       if ($linecal != "0") set vis_astro = $mir_linecal_astro
    endif
    if ($vis_noise == "") set vis_noise = $mir_baseline_noise

  # Noise source
    if ($noise != "0") then 
       echo ""
       echo "*** Applying noise-source passband  (vis=$vis_noise)"

       # Copy/conjugate noise source from lower to upper sideband
         set out = $vis_noise:r_cj.mir
         rm -rf $out
         echo ""
         echo "*** Conjugating noise source data  (vis=$vis_noise out=$out)"
         uvcal vis=$vis_noise out=$out options=noisecal
         set vis_noise = $out

       # Derive noise source passband.
       # It may be necessary to select a specific time range for the 
       # noise, since miriad sometimes assigns multiple frequency configurations
       # to the noise integrations. The "mfcal" statement below would be modified
       # as, for example,  select="time(20:00:00,20:05:00)" to select one 
       # integration.
         if ($noise_bl == "0") then
            # Derive
              echo ""
              echo "*** Deriving noise source passband"
              mfcal vis=$vis_noise interval=$interval_pb refant=$refant

            # Plot noise-source passband
              if ($plot_noise != "0" && $plot_passband != "0") then
                 echo ""
                 echo "*** Plotting mfcal noise-source passband amplitudes  (vis=$vis_noise)"
                 smagpplt device=/xs vis=$vis_noise nxy=2,2 options=bandpass,nofit
                 echo -n "*** HIT RETURN TO CONTINUE ***"
                 set ans = "$<"

                 echo ""
                 echo "*** Plotting mfcal noise-source passband phases  (vis=$vis_noise)"
                 smagpplt device=/xs vis=$vis_noise nxy=2,2 yrange=-200,200 \
                          options=wrap yaxis=phase options=bandpass,nofit
                 echo -n "*** HIT RETURN TO CONTINUE ***"
                 set ans = "$<"
              endif

            # Apply noise source
              set out = $vis_astro:r_ns.mir
              rm -rf $out
              echo ""
              echo "*** Apply noise passband to astronomy data  (noise=$vis_noise  astro=$vis_astro out=$out)"
              gpcopy vis=$vis_noise out=$vis_astro options=nocal,nopol
              uvcat vis=$vis_astro out=$out options=nocal
              set vis_astro = $out
         else
            echo ""
            echo "*** Applying baseline-based noise source passband"
            set out = $vis_astro:r_ns.mir
            rm -rf $out
            blcal vis=$vis_noise,$vis_astro interval=1 out=$out
            set vis_astro = $out
         endif
    endif

  # Auto-correlations
    if ($autocc != "0") then 
       # Autocorrelations
         set out = $vis_astro:r_ac.mir
         rm -rf $out
         echo ""
         echo "*** Applying auto-correlations passband   (vis=$vis_astro out=$out)"
         uvcal vis=$vis_astro out=$out options=fxcal
         set vis_astro = $out
    endif

  # Rename files
    rm -rf $mir_pb_astro 
    mv $vis_astro $mir_pb_astro
    set vis_astro = $mir_pb_astro


# ***********************************************************
# **** SPLIT ASTRONOMICAL DATA INTO WIDE AND NARROW BAND ****
# ***********************************************************
  if ($split_pb == "0") then
     set vis_wide = $vis_astro
  else
     # Create file with wideband windows
       set out = split_wide.mir
       rm -rf $out
       echo ""
       echo "*** Creating wideband data file  (vis=$vis_astro out=$out)"
       set select = "select=win($win_wide),-auto"
       if ($win_wide == "") set select = "select=-auto"
       uvcat vis=$vis_astro out=$out $select
       set vis_wide = $out

     # Create miriad file with narrow band windows
       set vis_narrow = ""
       if ($win_wide != "") then
          set out = split_narrow.mir
          rm -rf $out
          echo ""
          echo "*** Creating narrow band file  (vis=$vis_astro out=$out)"
          uvcat vis=$vis_astro out=$out select="-win($win_wide),-auto"
          set vis_narrow = $out
       endif
  endif


# *******************************
# **** ASTRONOMICAL PASSBAND ****
# *******************************
# This section will remove phase and amplitude offsets between windows.
# For the wide bands, we use channel-by-channel passband.
# For the narrow bands, we use the window average.

  # Create copy of wide-band passband calibrator
    set wb = tmp_wb.mir
    rm -rf $wb
    uvcat vis=$vis_wide out=$wb select="source($source_passcal)" \
          options=nocal,nopass

  # Create copy of narrow-band passband calibrator
    if ($vis_narrow != "") then
       set nb1 = nb1.mir
       rm -rf $nb1
       uvcat vis=$vis_narrow out=$nb1 select="source($source_passcal)" \
             options=nocal,nopass
    endif

  # Derive wideband passband
    echo ""
    echo "*** Passband calibration for wideband channels  (vis=$wb source=$source_passcal)"
    set flux_fake = 1.0   # This can be an arbitrary number
    mfcal vis=$wb select="source($source_passcal)" \
          interval=$interval_pb refant=$refant flux=$flux_fake
    gpcopy vis=$wb out=$vis_wide options=nocal

  # Copy gain solution from wideband to narrow band and apply
    if ($vis_narrow != "") then
       gpcopy vis=$wb out=$nb1 options=nopass,nopol
       set nb2 = nb2.mir
       rm -rf $nb2
       uvcat vis=$nb1 out=$nb2 options=nopass,nopol
    endif

  # Perform passband fit on narrow band data
    if ($vis_narrow != "" && $nb_polyfit == 0) then 
       # Determine number of windows. This is needed for uvwide
         set tmplog = tmp.prthd
         set tmpcorr = tmp.corr
         rm -rf $tmplog $tmpcorr
         prthd in=$vis_narrow options=full log=$tmplog
         set beglin=`awk '/Spectrum  Channels  Freq/ {print NR}' $tmplog`
         @ beglin ++
         set endlin=`awk '/Total number/ {print NR}' $tmplog`
         set endlin=`expr $endlin[1] - 1`
         sed -n "$beglin,${endlin}p" $tmplog > $tmpcorr
         set srcfreq = `cat $tmpcorr | awk '{print $2}'`
         set nwindows = $#srcfreq
         echo ""
         echo "*** Found $nwindows narrow-band windows."

       # Re-compute wide channels
         set nb3 = nb3.mir
         rm -rf $nb3
         echo ""
         echo "*** Re-computing wideband channels for narrow-band data  (vis=$nb2 out=$nb3)"
         uvwide vis=$nb2 nwide=$nwindows out=$nb3

       # Compute band-to-band and gain offsets
         echo ""
         echo "*** Computing gain offsets and band-to-band offsets for narrow band data using band averages (vis=$nb3  source=$source_passcal)"
         mfcal vis=$nb3 select="source($source_passcal)" \
               interval=10000 refant=$refant line=w,$nwindows,1,1,1 \
               flux=$flux_fake

       # Copy solution to narrow band data
         gpcopy vis=$nb3 out=$vis_narrow
    else if ($vis_narrow != "") then
       # Compute passband with polynomial fit.
         echo ""
         echo "*** Computing gain offsets and band-to-band offsets for narrow band data using polynomial fit (vis=$nb3  source=$source_passcal)"
         smamfcal vis=$nb2 select="source($source_passcal)" \
                  interval=10000 refant=$refant options=opolyfit \
                  polyfit=$nb_polyfit flux=$flux_fake
         gpcopy vis=$nb2 out=$vis_narrow
    endif

  # Show sources after passband
    if ($plot_passband != "0") then
       # Plot wide-band solutions - amplitude
         echo ""
         echo "*** Plotting mfcal passband amplitudes for wideband data  (vis=$vis_wide)"
         echo "*** To skip these plots, type plot_passband=0 when starting script."
         smagpplt device=/xs vis=$vis_wide nxy=2,2 \
                  options=bandpass,nofit,dot dotsize=$dotsize
         echo -n "*** HIT RETURN TO CONTINUE ***"
         set ans = "$<"

       # Plot wide-band solutions - phase
         echo ""
         echo "*** Plotting mfcal passband phases for wideband data  (vis=$vis_wide)"
         echo "*** To skip these plots, type plot_passband=0 when starting script."
         smagpplt device=/xs vis=$vis_wide nxy=2,2 yrange=-200,200 \
                  yaxis=phase options=wrap,bandpass,nofit,dot dotsize=$dotsize
         echo -n "*** HIT RETURN TO CONTINUE ***"
         set ans = "$<"

       # Plot narrow-band solutions
         if ($vis_narrow != "") then
            # Amplitude
            echo ""
            echo "*** Plotting band-averaged amplitudes for narrow-band data  (vis=$vis_narrow)"
            echo "*** To skip these plots, type plot_passband=0 when starting script."
            smagpplt device=/xs vis=$vis_narrow nxy=2,2 \
                     options=bandpass,nofit,dot dotsize=$dotsize
            echo -n "*** HIT RETURN TO CONTINUE ***"
            set ans = "$<"
       

            # Phase
            if ($vis_narrow != "") then
               echo ""
               echo "*** Plotting mfcal passband phases for narrow-band data  (vis=$vis_wide)"
               echo "*** To skip these plots, type plot_passband=0 when starting script."
               smagpplt device=/xs vis=$vis_narrow nxy=2,2 yrange=-200,200 \
                        yaxis=phase options=wrap,bandpass,nofit,dot dotsize=$dotsize
               echo -n "*** HIT RETURN TO CONTINUE ***"
               set ans = "$<"
            endif
         endif
    
       # Spectra on passband calibrator - wideband
         echo ""
         echo -n "*** Do you want to plot wide-band spectra for passband calibrator (Y/N)? "
         set ans = "$<"
         if ($ans == "Y" || $ans == "y" || $ans == "1") then 
            echo ""
            echo "*** Plotting wideband data for $source_passcal after passband calibration  (vis=$vis_wide)"
            echo "*** Amplitudes and phases should be flat, and there "
            echo "*** should be no amplitude/phase jumps across windows."
            echo "*** To skip these plots, type plot_passband=0 when starting script."
            smauvspec device=/xs vis=$vis_wide nxy=3,3 select="source($source_passcal),-auto" axis=chan,both interval=10000
            echo -n "*** HIT RETURN TO CONTINUE ***"
            set ans = "$<"
         endif
    
       # Spectra on passband calibrator - narrow band
         if ($vis_narrow != "") then
            echo ""
            echo -n "*** Do you want to plot narrow-band spectra for passband calibrator (Y/N)? "
            set ans = "$<"
            if ($ans == "Y" || $ans == "y" || $ans == "1") then 
               echo ""
               echo "*** Plotting narrow-band data for $source_passcal after passband calibration  (vis=$vis_narrow)"
               echo "*** Amplitudes and phases should be flat, and there "
               echo "*** should be no amplitude/phase jumps across windows."
               echo "*** To skip these plots, type plot_passband=0 when starting script."
               smauvspec device=/xs vis=$vis_narrow nxy=3,3 select="source($source_passcal),-auto" axis=chan,both interval=10000
               echo -n "*** HIT RETURN TO CONTINUE ***"
               set ans = "$<"
            endif
         endif

       # Spectra on gain calibrator
         if ($source_passcal != $source_gaincal) then
            # Wideband
              echo ""
              echo -n "*** Do you want to plot wide-band spectra for gain calibrator (Y/N)? "
              set ans = "$<"
              if ($ans == "Y" || $ans == "y" || $ans == "1") then 
                 echo ""
                 echo "*** Plotting wideband data for $source_gaincal after passband calibration  (vis=$vis_wide)"
                 echo "*** Amplitudes and phases should be flat, and there "
                 echo "*** should be no amplitude/phase jumps across windows."
                 echo "*** To skip these plots, type plot_passband=0 when starting script."
                 smauvspec device=/xs vis=$vis_wide nxy=3,3 select="source($source_gaincal),-auto" axis=chan,both interval=10000
                 echo -n "*** HIT RETURN TO CONTINUE ***"
                 set ans = "$<"
              endif

            # Narrow
              if ($vis_narrow != "") then
                 echo ""
                 echo -n "*** Do you want to plot narrow-band spectra for gain calibrator (Y/N)? "
                 set ans = "$<"
                 if ($ans == "Y" || $ans == "y" || $ans == "1") then 
                    echo ""
                    echo "*** Plotting narrow-band data for $source_gaincal after passband calibration  (vis=$vis_narrow)"
                    echo "*** Amplitudes and phases should be flat, and there "
                    echo "*** should be no amplitude/phase jumps across windows."
                    echo "*** To skip these plots, type plot_passband=0 when starting script."
                    smauvspec device=/xs vis=$vis_narrow nxy=3,3 select="source($source_gaincal),-auto" axis=chan,both interval=10000
                    echo -n "*** HIT RETURN TO CONTINUE ***"
                    set ans = "$<"
                 endif
              endif
         endif
    endif

  # Apply passband for wideband data.
  # Split astronomical data into wide and narrow band, if needed.
    set out_wide = $mir_pb_wide
    rm -rf $out_wide
    if ($split_pb == "0") then
       # Create file with wideband windows
         echo ""
         echo "*** Creating wideband data file  (vis=$vis_wide out=$out_wide)"
         set select = "select=win($win_wide),-auto"
         if ($win_wide == "") set select = "select=-auto"
         uvcat vis=$vis_wide out=$out_wide $select

       # Create miriad file with narrow band windows
         set vis_narrow = ""
         if ($win_wide != "") then
            set out_narrow = $mir_pb_narrow
            rm -rf $out_narrow
            echo ""
            echo "*** Creating narrow band file  (vis=$vis_astro out=$out_narrow)"
            uvcat vis=$vis_wide out=$out_narrow select="-win($win_wide),-auto"
            set vis_narrow = $out_narrow
         endif

       # Set output files
         set vis_wide   = $out_wide
    else
       echo ""
       echo "*** Applying passband to wideband data  (vis=$vis_wide out=$out_wide)"
       uvcat vis=$vis_wide out=$out_wide options=nocal
       set vis_wide = $out_wide
    endif

  # Apply passband - narrowband
    if ($split_pb != "0" && $vis_narrow != "") then
       set out = $mir_pb_narrow
       rm -rf $out
       echo ""
       echo "*** Applying passband to narrowband data  (vis=$vis_narrow out=$out)"
       uvcat vis=$vis_narrow out=$out   # Yes, options=nocal is omitted
       set vis_narrow = $out
    endif



# **************************
# **** FLUX CALIBRATION ****
# **************************
fluxcal:
  # Set file names
    if ($vis_wide == "") set vis_wide = $mir_pb_wide
    if ($win_wide != "" && $vis_narrow == "") set vis_narrow = $mir_pb_narrow

  # Measure flux of gain calibrator
    if ($fluxcal != "0" && "$flux_gaincal" == ""  && "$source_fluxcal" != "") then
       # Message
         echo ""
         echo "*** Starting flux calibration"

       # Create file with primary calibrator
         set out_primary = flux_primary.mir
         rm -rf $out_primary
         echo ""
         echo "*** Creating file for $source_fluxcal  (vis=$vis_wide out=$out_primary)"
         uvcat vis=$vis_wide out=$out_primary options=nocal,nopass \
               select="source($source_fluxcal),-auto" 

       # Create file with gain calibrators
         set out_gaincal = flux_gaincal.mir
         rm -rf $out_gaincal
         echo ""
         echo "*** Creating file for $source_gaincal  (vis=$vis_wide out=$out_gaincal)"
         uvcat vis=$vis_wide out=$out_gaincal options=nocal,nopass \
               select="source($source_gaincal),-auto"

       # Phase-only selfcal on primary flux calibrator
         set out = $out_primary:r_ph.mir
         rm -rf $out
         echo ""
         echo "*** Phase-only selfcal on flux calibrator  (vis=$out_primary out=$out)"
         selfcal vis=$out_primary interval=$interval_flux refant=$refant \
                 options=apriori,noscale,phase
         uvcat vis=$out_primary out=$out
         set out_primary = $out

       # Plot amp vs uvdist
         if ($plot_fluxcal != "0") then
            echo ""
            echo "*** Plotting amplitudes vs. uvdistance for $source_fluxcal  (vis=$out_primary)"
            smauvplt device=/xs vis=$out_primary axis=uvdist,amp options=nobase
            echo -n "*** HIT RETURN TO CONTINUE ***"
            set ans = "$<"
         endif

       # Determine number of channels in spectrometer setup.
       # This is needed since bootflux requires only ony data point.
         set tmplog = tmp.uvlist
         rm -rf $tmplog
         uvlist vis=$out_primary options=var,full log=$tmplog
         set nchan=`grep nchan $tmplog | sed 's/.*nchan[ ]*://' | awk '{print $1}'`

       # Loop over gain calibrators
         set gsources = `echo $source_gaincal | sed 's/,/ /g'`
         foreach gcal ($gsources)
            # Phase-only selfcal on gain calibrator
              set out = $out_gaincal:r_ph.mir
              rm -rf $out
              echo ""
              echo "*** Phase-only selfcal on gain calibrator $gcal (vis=$out_gaincal out=$out)"
              selfcal vis=$out_gaincal interval=$interval_flux refant=$refant \
                      options=apriori,noscale,phase select="source($gcal)"
              uvcat vis=$out_gaincal out=$out select="source($gcal)"

            # Construct select statement for bootflux
              set select = "source($source_fluxcal,$gcal)"
              if ($flux_elevation != "") set select = "$select,elevation($flux_elevation)"
              if ($flux_uttime != "") set select = "$select,$flux_uttime"

            # Measure flux
              echo ""
              echo "*** Measuring flux using bootflux"
              set log = bootflux.log
              set out_bootflux = ${root}.$gcal
              rm -rf $log $out_bootflux
              set flux = ""
              if ($flux_fluxcal != "") set flux = ",$flux_fluxcal"
              bootflux vis=$out_primary,$out select="$select,-auto" \
                       taver=$taver primary=$source_fluxcal$flux \
                       badres=$badres log=$log line=chan,1,1,$nchan,1
              grep Average $log | grep Flux | awk '{if ($7 == 0.0) print $3; else print $7;}' > $out_bootflux
              echo ""
              echo -n "*** Measured flux in Janskys on $gcal is: "
              cat $out_bootflux
              if ($plot_fluxcal != "0") then 
                 echo -n "*** HIT RETURN TO CONTINUE ***"
                 set ans = "$<"
              endif
              if ($flux_gaincal != "") set flux_gaincal = "$flux_gaincal,"
              set flux_gaincal = "${flux_gaincal}@$out_bootflux"
         end
    endif


# **************************
# **** GAIN CALIBRATION ****
# **************************
gaincal:
  # Set filename
    if ($vis_wide == "") set vis_wide = $mir_pb_wide
    if ($win_wide != "" && $vis_narrow == "") set vis_narrow = $mir_pb_narrow

    rm -rf $vis_wide/gain
    if ($vis_narrow != "") rm -rf $vis_narrow/gain

  # Set gain calibrators
    set gsources = `echo $source_gaincal | sed 's/,/ /g'`

  # Check number of gain calibrator fluxes
    if ("$flux_gaincal" != "") then
       set flux_gaincal = `echo $flux_gaincal | sed 's/,/ /g'`
       if ($#flux_gaincal != $#gsources) then
          echo "ERROR: Number of gain-cal sources does not match number of gain-cal fluxes"
       endif
    endif

  # Loop over gain calibrators
    set n = 0
    foreach gcal ($gsources) 
       # Increment counter
         @ n = $n + 1

       # Copy gain calibrator
         set out = gcal.mir
         rm -rf $out
         echo ""
         echo "*** Copying gain calibrator  (vis=$vis out=$out)"
         uvcat vis=$vis_wide out=$out select="source($gcal)" options=nocal,nopass

       # Set flux
         set fcal = ""
         if ("$flux_gaincal" != "") set fcal = "flux="$flux_gaincal[$n]

       # Derive solution
         echo ""
         echo "*** Gain calibration wideband data  (vis=$out source=$gcal)"
         echo "mfcal vis=$out interval=$interval_gain refant=$refant options=nopass $fcal"
         mfcal vis=$out interval=$interval_gain refant=$refant \
               options=nopass $fcal

       # Copy gain solution
         if ($n == 1) then
            gpcopy vis=$out out=$vis_wide
         else
            gpcopy vis=$out out=$vis_wide mode=merge
         endif
    end

  # Copy to narrow band-data
    if ($vis_narrow != "") then
       echo ""
       echo "*** Copying gain solution to narrow band data  (vis=$vis_wide out=$vis_narrow)"
       gpcopy vis=$vis_wide out=$vis_narrow options=nopass
    endif

  # Plot results
    if ($plot_gains != "0") then
       # Amplitudes
         echo ""
         echo "*** Plotting wideband amplitudes (vis=$vis_wide)"
         echo "*** Amplitudes should vary smoothly in time and should have a value of ~ 1."
         echo "*** To skip these plots, type plot_gains=0 when starting script."
         smagpplt device=/xs vis=$vis_wide nxy=5,3 options=dot,nofit dotsize=$dotsize
         echo -n "*** HIT RETURN TO CONTINUE ***"
         set ans = "$<"

       # Phases
         echo ""
         echo "*** Plotting wideband phases  (vis=$vis_wide)"
         echo "*** Phases should vary smoothly in time."
         echo "*** To skip these plots, type plot_gains=0 when starting script."
         smagpplt device=/xs vis=$vis_wide nxy=5,3 yrange=-200,200 yaxis=phase \
                  options=wrap,dot,nofit dotsize=$dotsize
         echo -n "*** HIT RETURN TO CONTINUE ***"
         set ans = "$<"
    endif


# *******************
# **** COPY DATA ****
# *******************
# Copy calibrated data to reduced directory
# Add GSV keyword so that invert will take into account relative antenna gains.
  echo ""
  echo "*** Copying calibrated wide-band data ($vis_wide) to $dir_reduced"
  puthd in=$vis_wide/senmodel value='GSV' type=ascii
  set cal_wide = $mir_cal_wide
  rm -rf $cal_wide
  echo "*** Calibrated wideband data in $cal_wide"
  cp -r $vis_wide $cal_wide

  if ($vis_narrow != "") then 
     echo ""
     echo "*** Copying calibrated narrow-band data ($vis_wide) to $dir_reduced/"
     puthd in=$vis_narrow/senmodel value='GSV' type=ascii
     set cal_narrow = $mir_cal_narrow
     rm -rf $cal_narrow
     echo "*** Calibrated narrow-band data in $cal_narrow"
     cp -r $vis_narrow $cal_narrow
  endif


# ******************************
# **** PLOT CALIBRATED DATA ****
# ******************************
# Check data
  if ($plot_cal != "0") then
     # Calibrated phases vs time
       echo ""
       echo "*** Plotting phase vs time on gain calibrator (vis=$vis_wide)."
       echo "*** Phases should be centered on zero. The smaller scatter the better!"
       smauvplt device=/xs vis=$vis_wide select="source($source_gaincal)" \
                axis=time,phase
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Calibrated amp vs time
       echo ""
       echo "*** Plotting amplitude vs time on gain calibrator (vis=$vis_wide)."
       echo "*** Amplitudes should be centered on zero. The smaller scatter the better!"
       smauvplt device=/xs vis=$vis_wide select="source($source_gaincal)" \
                axis=time,amp
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Phase vs. uv distance on gain calibrator
       echo ""
       echo "*** Plotting phase vs uvdistance on gain calibrator (vis=$vis_wide)."
       echo "*** Phases should be centered on zero. The smaller scatter the better!"
       smauvplt device=/xs vis=$vis_wide select="source($source_gaincal)" \
                options=nobase axis=uvdist,phase
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Amplitude vs. uv distance on gain calibrator
       echo ""
       echo "*** Plotting amplitude vs uvdistance on gain calibrator (vis=$vis_wide)."
       echo "*** Amplitudes should be centered on flux calibrator flux."
       smauvplt device=/xs vis=$vis_wide select="source($source_gaincal)" \
                options=nobase axis=uvdist,amp
       echo -n "*** HIT RETURN TO CONTINUE ***"
       set ans = "$<"

     # Plot wide-band spectra on gain calibrator
       echo ""
       echo "*** Plotting spectra for wideband data  (vis=$vis_wide)."
       echo "*** Phases should be centered around zero degrees."
    
     # Spectra on gain calibrator - wideband
       echo ""
       echo -n "*** Do you want to plot wide-band spectra for gain calibrator (Y/N)? "
       set ans = "$<"
       if ($ans == "Y" || $ans == "y" || $ans == "1") then 
          echo ""
          echo "*** Plotting wideband data for $source_gaincal after passband calibration  (vis=$vis_wide)."
          echo "*** Amplitudes and phases should be flat, and there "
          echo "*** should be no amplitude/phase jumps across windows."
          echo "*** To skip these plots, type plot_passband=0 when starting script."
          smauvspec device=/xs vis=$vis_wide nxy=3,3 \
                    select="source($source_gaincal),-auto" axis=chan,both \
                    interval=10000
          echo -n "*** HIT RETURN TO CONTINUE ***"
          set ans = "$<"
       endif

     # Narrow
       if ($vis_narrow != "") then
          echo ""
          echo -n "*** Do you want to plot narrow-band spectra for gain calibrator (Y/N)? "
          set ans = "$<"
          if ($ans == "Y" || $ans == "y" || $ans == "1") then 
             echo ""
             echo "*** Plotting narrow-band data for $source_gaincal after passband calibration  (vis=$vis_narrow)"
             echo "*** Amplitudes and phases should be flat, and there "
             echo "*** should be no amplitude/phase jumps across windows."
             echo "*** To skip these plots, type plot_passband=0 when starting script."
             smauvspec device=/xs vis=$vis_narrow nxy=3,3 \
                       select="source($source_gaincal),-auto" \
                       axis=chan,both interval=10000
             echo -n "*** HIT RETURN TO CONTINUE ***"
             set ans = "$<"
          endif
       endif

     # Closure phase on gain calibrator
#      echo ""
#      echo -n "*** Do you want to plot wide-band closure phases on the gain calibrator (Y/N)? "
#      set ans = "$<"
#      if ($ans == "Y" || $ans == "y" || $ans == "1") then 
#         echo ""
#         echo "*** Plotting closure phase on gain calibrator  (vis=$vis_wide)."
#         echo "*** Phases should be centered around zero."
#         closure device=/xs vis=$vis_wide select="source($source_gaincal)" nxy=3,3
#         echo -n "*** HIT RETURN TO CONTINUE ***"
#         set ans = "$<"
#      endif
  endif

# Create images
images:
  if ($vis_wide == "") set vis_wide = $mir_pb_wide
  if ($win_wide != "" && $vis_narrow == "") set vis_narrow = $mir_pb_narrow
  if ($images != "0" && $source_image != "") then
     # Set source names
       set sources = `echo $source_image | sed 's/,/ /g'`

     # Set options
       set option_cell = ""
       if ($cell != "") set option_cell = "cell=$cell"
       set option_imsize = ""
       if ($imsize != "") set option_imsize = "imsize=$imsize"
       set option_offset = ""
       if ($offset != "") set option_offset = "offset=$offset"

     # Loop over sources
       foreach name ($sources)
          # Continuum image
            echo ""
            echo "*** Making continuum image of $name  (vis=$vis_wide)"
            echo "*** Units are in Janskys"
            set map  = "$name.cont.map"
            set beam = "$name.cont.beam"
            rm -rf $map $beam
            invert vis=$vis_wide map=$map beam=$beam robust=$robust \
                   options=mfs,systemp,mosaic select="source($name)" \
                   $option_cell $option_imsize $option_offset
            if ($plot_images != "0") then
               cgdisp device=/xs in=$map labtyp=arcsec options=full,wedge
               echo -n "*** HIT RETURN TO CONTINUE ***"
               set ans = "$<"
            endif

          # Spectral line image
            if ($vis_narrow != "") then
               # Determine number of windows. This is needed for uvwide
                 set tmplog = tmp.prthd
                 set tmpcorr = tmp.corr
                 rm -rf $tmplog $tmpcorr
                 prthd in=$vis_narrow options=full log=$tmplog
                 set beglin=`awk '/Spectrum  Channels  Freq/ {print NR}' $tmplog`
                 @ beglin ++
                 set endlin=`awk '/Total number/ {print NR}' $tmplog`
                 set endlin=`expr $endlin[1] - 1`
                 sed -n "$beglin,${endlin}p" $tmplog > $tmpcorr
                 set srcfreq = `cat $tmpcorr | awk '{print $2}'`
                 set nwindows = $#srcfreq

               # Loop over windows
                 set n = 0
                 set nwin = 0
                 set w_wide = `echo $win_wide | sed 's/,/ /g'`
                 while ($n < $nwindows)
                    # Increment counter
                      @ n = $n + 1
                      @ nwin = $nwin + 1

                    # Increment if this is a wide band window.
                    # This is needed to keep the same window numbers in the
                    # original file.
                      foreach w ($w_wide)
                         if ($nwin == $w) @ nwin = $nwin + 1
                      end

                    # Make image
                      echo ""
                      echo "*** Making spectral line image $name for narrow band spectrometer number $nwin  (vis=$vis_narrow)"
                      echo "*** Units are in Janskys"
                      set map  = $name.spec.$nwin.map
                      rm -rf $map
                      invert vis=$vis_narrow map=$map robust=$robust \
                             options=mfs,systemp,mosaic \
                             select="source($name),win($n)" \
                             $option_cell $option_imsize $option_offset
                      if ($plot_images != "0") then
                         cgdisp device=/xs in=$map labtyp=arcsec options=full,wedge
                         echo -n "*** HIT RETURN TO CONTINUE ***"
                         set ans = "$<"
                      endif
                 end
            endif
       end
  endif

# Go back to starting directory
  cd $starting_dir


