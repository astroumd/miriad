/*----------------------------------------------------------------------------
-- mosaic_main.c --
/*----------------------------------------------------------------------------*/

/*= mosaic - deconvolution using mosaicing method
/*& bpw
/*: deconvolution
/*+
    Mosaic does a simultaneous deconvolution of a set of adjacent
    pointings, combining them into a single map. This should yield a
    better result than individually deconvolving the pointings. It
    replaces the dirty point spread function (i.e. one with many and/or
    deep sidelobes) with one that is well-behaved (i.e. a gaussian). [In
    the near future, it will be possible to include single-dish data.]

    A short outline of the algorithm: start with an initial model. For
    each pointing, multiply the model with the primary beam pattern;
    convolve with the synthesized beam of that pointing. Subtract the
    observation and calculate the chi^2 of the residual. Then apply the
    formulae of the Maximum Entropy Method, in which unobserved data are
    constrained by a "reference map". To find a step, use Lagrange
    Multipliers and a Newton-Raphson iterative method. Drive the sum of
    the chi^2 values of all maps to a value such that on average the
    residual deviates by one sigma from the prediction and such that the
    total flux converges toward a wanted value.

    The many keywords below come in five groups:
      - in, beam, pbpar, maxcorr, rms -- specify interferometer inputs
      - region#, planes, initial, reference, flux -- set up constraints
      - out, mode, beamsize, save, saveiter -- specify outputs
      - maxiters, tol, measure, lm0, meslev -- control parameters
    Obligatory keywords are: in, beam, rms and out; the rest is for fine
    tuning.

    Inputs for interferometer data are: a list of miriad datasets with
    input observations, a list of the corresponding synthesized beams, an
    optional list of primary beam descriptions and a list of values for
    the rms noise in each input map.

    For each of the input maps it is possible to select a region outside
    of which the model is set to zero (see the region and reference
    keywords). A list of common planes can be given to simplify the
    selection of channels. If datasets are not on the same frequency
    grid, use miriad task regrid to make them fit.

    The output is a miriad dataset with the model. It is also possible
    (and advisable) to write output datasets containing the residuals of
    the input map, a combined residual (without primary beam corrections),
    the model convolved with a "clean beam", and a final map (the sum of
    the primary beam corrected residual and the convolved model). The
    reference coordinate (crval) of the output maps is that of the first
    in the list of input maps. Note: the mask of the model (outside which
    it is zero) is only written to the mask item of the 'convolved' output
    map.

    Calculating the secondary outputs (residuals, convolved and final map)
    is equivalent to using 'restor' after a 'clean' operation. They can
    also be calculated from a read-in model map (see the mode keyword).

    Most intermediate results (like the evolving model and residuals) can
    be written by using the save= keyword.

    The program has three other independent uses: 1) to write a linear
    mosaic of the primary beam corrected, variance-weighted input maps;
    2) to write a noise map, i.e. the harmonic mean of the variances;
    3) to write primary-beam-corrected input maps. A choice is made using
    the mode= keyword.

    An example of standard simple usage is:
     mosaic in=map\* beam=beam\* rms=1,... flux=-10 out=out mode=m,f,r,c

    TAKE NOTE OF THE FOLLOWING:

    Beware: the value given for the rms is of paramount importance in
    determining convergence. In fact, it is the parameter that has the
    most influence on the reliability of the result. If it is too low or
    too high convergence may not occur.

    A current limitation is that the crvals of the input maps must be an
    integer number of pixels offset from each other. The program checks
    this and tells you what input to use for the invert keyword offset=
    to get it right. The reason for this limitation is that mosaic does
    not regrid the maps.

    For large fields (larger than about one degree) geometrical projection
    effects may become important. Maps made with invert will not be on the
    same tangential plane. Usually this can be ignored. Strictly speaking,
    however, they should be reprojected (using the miriad task regrid).
    Unfortunately, miriad does not differentiate between pointing center
    and projection center, and this causes trouble. So, after using regrid,
    you need to fix the crval and crpix of the reprojected datasets so
    that they indicate the pointing center of the observation.

    As the model is forced to be non-zero everywhere inside the selected
    region, it can also be non-zero where there is no actual emission.
    Thus, it may be even more important than in CLEAN to define a region
    where the signal is expected. Use the region#= or the reference=
    keyword (see there for details). One way to create a region is to
    first run mosaic with mode=m,c, without region selection; then take
    the resulting convolved model, and fiddle a bit with it; next use it
    as input to the reference keyword, making use of the clipping option.
    A choice for the region that is too small will result in missed
    structure in the model. Or, the bias flux that is spread around in the
    map may become too high. A choice for the region that is too large can
    result in "structure" being found in the noise.

    It is furthermore important to put in a good value for the total flux
    (if only as initial estimate). If you don't have this, don't be
    surprised if the answer looks bad or convergence does not occur. You
    might try to iterate by changing the initial input value until it does
    not vary much from the value at the last iteration.

    A good reference map improves convergence. Without it, in principle
    the final result should be the same, but you may have to wait longer
    if the source structure is complex. The reference map gives the
    algorithm reasonable data on spatial frequencies that were not
    observed. There are several possible ways to create a reference map
    (or an initial estimate):
      a) a flat map (default, usually good enough and preferable)
      b) the sum of the primary beam patterns (for sources whose diameter
         is comparable to the primary beam) (often unreliable)
      c) a single-dish map gridded to the interferometer gridspacing
      d) a map of the same source at a different frequency
      e) the result of a previous or lower-resolution observation
    The latter three cases require you to specify the reference map as
    input. If any a-priori information is present, use this to create an
    initial estimate and reference map.

    Officially, miriad has no header variable that represents the pointing
    center. The uv-variables "obsra" and "obsdec" come closest. They are
    defined as the phase center at the epoch of the observation. To get
    the phase center at the epoch of the map requires a precessional
    correction, which is not done (yet?). Thus, "crval1, crval2" are used
    instead as the coordinates of the pointing center. For miriad datasets
    this should almost alway be OK, but it is a non-guaranteed use of the
    variables. For maps imported from aips, check whether crval/crpix
    indeed give the pointing center. If "crval1, crval2" does not give the
    pointing center, the primary beam is offset and the algorithm will
    fail.

    Be very cautious using this method. If you don't understand it, it is
    easy to obtain wrong output maps. Don't blame the program if you fail
    at the first try, fiddle with the parameters or ask for help (remember
    the need for an accurate rms).

/*@ in
    List of input maps with observations.
/*@ beam
    List of input beam datasets (one for each map).
    The lengths of the x and y axes must be a power of 2.
/*@ pbpar
    List of values giving the formula used to describe the primary beam.
    There should be a value for each input map, unless "..." is used. [The
    default is "pbpar=tel,...", i.e. use the header for all input maps, as
    described below.]
    Values can be:
      - ""         => tel
      - none       => no primary beam correction
      - tel        => use formula for telescope as described below
                      if telescope not known, make a gaussian with fwhm
                      from header item "pbfwhm"
      - gauss,fwhm => create a gaussian primary beam (cut off at 0.05)
      - airy,fwhm  => create an airy disk
      - airyc,fwhm => create an airy disk, but only out to first zero
      - ...        => repeat the last given value for remaining inputs
      If fwhm > 0  => make primary beam of given type with this fwhm
                     (if restfreq>10 GHz units are arcsec, else arcmin)
      If fwhm = 0  => read fwhm from header item "pbfwhm"; if not
                      present, get fwhm from "restfreq" and "telescop"
    If "pbpar=tel", header items "telescop" and "restfreq" are used to make
    the primary beam: a polynomial for the WSRT, VLA and ATCA, a gaussian
    for FST and BIMA; these functions are cut off at a level of about 0.05
    (see keyword maxcorr). If "restfreq" is not present, but the type of
    the "freq" axis is "FREQ", then crval, crpix and cdelt are used to get
    the frequency of plane 1.
    Example 1: with two input maps, pbpar=gauss,120,gauss,120 makes
    gaussian primary beams with fwhm 120 arcsec.
    Example 2: pbpar=airy,120,tel,gauss,0,gauss,118 with four input maps
    makes an airy disk with fwhm 120 arcsec for the first, uses the
    telescope formula for the second, makes a gaussian with fwhm found
    from "restfreq" and "telescop" for the third and makes a gaussian with
    fwhm 118 arcsec for the fourth.
/*@ maxcorr
    Influences to how far out the primary beam correction is done:
    everywhere where the correction factor is less than maxcorr. Not valid
    for airy shapes. Mainly useful with mode=pbc. [Default is telescope
    dependent (20 for gauss, 16 for WSRT, 43 for VLA, 33 for ATCA).]
/*@ rms
    List of values of the pixel-to-pixel rms (in Jy/beam, as given by
    imstat), one for each map. Determine this from signal-free areas or
    channels. You can repeat the value of the rms by using "...". E.g.:
    "rms=0.1,..." will make the rms 0.1 for each input map. Entering
    "rms=0.1" with more than one input map will result in an error
    message, i.e., the value is not automatically repeated; this is a
    safety feature. Beware: getting the rms right is the most important
    thing to get proper convergence.
/*@ region1
    See region#.
/*@ region2
    See region#.
/*@ region3
    See region#.
/*@ region#
    region# stands for region1, region2, region3, etc. You never actually
    type the '#'.
    There can be one region keyword for each input map. For the first map
    use 'region1', for the second 'region2', etc. For the format of the
    specification, see 'doc region' or the users manual.
    If you are using the miriad 'shell', region can only be given for the
    first three input maps. To use more, use a c-shell command, making
    sure that all '(' and ')' are put within single quotations marks.
    If none of the region# keywords is given, the region is determined
    either by the reference keyword (if a cutoff is given), or by merging
    the inner quarters of all maps.
    For each individual region keyword, the list of boxes and polygons is
    'ored' together to form a single region in the combined map. Pixels
    farther out than the primary beam cutoff are masked out. If the input
    file has a mask item or if the keyword specification contains 'mask',
    these masks are 'anded' in.
    The set of input regions, one for each map, is 'anded' together to
    create a region in the mosaiced map. Everything outside this region
    will be set to zero in the final model.
    Example1: region1=quart(1) makes the mosaic model non-zero only in
    the inner quarter of the first map.
    Example2: region1=relpix,box(-30,-30,30,30),box(-50,-50,0,0) combines
    the two boxes into a single, larger region, and makes the mosaic model
    non-zero in this region.
    Example3: region1=quart(1) region2=quart(1) makes the model non-zero
    in the overlap region between the inner quarters of the first and
    second input map.
    It is easy to check the region that is produced, by using the save=ref
    keyword. This write out the reference map, which is non-zero only
    inside the selected region.
/*@ planes
    To make it a little easier to specify a list of input planes, use
    this keyword to work on same planes for all input datasets. It has the
    same syntax as the standard region keyword. It supersedes any image
    specifications in individual region keywords. Subcommands other than
    'abspixel', 'relpixel', 'kms' and 'image' are ignored.
    This is mainly useful for homogeneous data. Otherwise, you will need
    to select the planes using a region#=image() specification for each
    dataset separately. The program will check whether the given planes
    correspond to the same sky frequencies, and stop if they do not. Use
    miriad task regrid to make datasets fit. The same planes are used for
    for both the interferometer and the single-dish data.
/*@ mode
    Specifies which output(s) are written. Options 'model', 'residual',
    'convolved', 'final' and 'obsres' can be combined. Options 'linmos',
    'noise', and 'pbc' must be the only given option. [Default is
    'mode=model,final'.]
    If mode 'model' is present, the mem algorithm is applied and the model
    is written to the dataset given by the out= keyword.
    If mode 'model' is missing, the out= keyword must specify an existing
    model dataset, from which the other outputs can be generated.
    In/output units are Jy/pixel for the model, Jy/beam for the others.
    The other output datasets have names made from the one given by out=
    by appending the mode to that name. E.g. out=name mode=final produces
    'name_final'.
      - model    Write mem model map. If not present, use out= as input
                 to construct the other outputs. planes= then refers to
                 planes in the model, not planes in the inputs.
      - final    Write the sum of maps convolved with a restoring beam
                 and a summed residual. The latter is the sum of the
                 residuals weighted by the inverse variance at each pixel,
                 including the primary beam correction. Analagous to
                 primary-beam-corrected clean map in CLEAN.
      - convolve Write the model convolved with a restoring beam. The
                 FWHM and PA of the restoring beam are the average of the
                 FWHMs and PAs of the input beams unless beamsize= is used.
      - residual Write a residual as the straight sum of the individual
                 residuals. Not a realistic map, but useful for checks.
      - obsres   Write the final residual for each of the input maps.
      - linmos   Write the linear mosaic: sum of primary beam corrected
                 input maps weighted with inverse variance; ignore the
                 beam= keyword; only the relative values in the rms=
                 keyword are important. Use with pbpar=none to turn off
                 the primary beam correction.
      - noise    Write a noise map. This is the harmonic mean of the
                 variances. Use pbpar=none to turn off primary beam
                 correction.
      - pbc      Only apply the primary beam correction to each of the
                 input datasets; ignore beam= and rms=.
      - invpbc   Apply inverse primary beam correction (suppression).
/*@ out
    If 'model' is one of the options of the mode= keyword this gives the
    name of the dataset to which the final model map is written.
    If mode 'model' does not occur, it gives the name of an input dataset
    containing a previously-made model map (use this if you want to
    restore a previously-created model map with a nice beam). The units
    must then be Jy/pixel.
/*@ reference
    If the name of a dataset is given, this contains the reference image
    (the units of this map must be Jy/pixel, not Jy/beam). This dataset
    must have either one plane or the same number of planes as the input
    dataset.
    If blank, a flat reference map with flux is equal to that of the
    initial estimate is constructed. If the special value "PBPATTERNS" (in
    caps, no minimal match) is used, the pattern is the sum of the primary
    beam patterns. The reference map can also be used as an alternative,
    usually simpler, way of defining a mask for the model area. To this
    end the keyword takes two more arguments. The second argument gives a
    cutoff value that is applied to the reference map in order to define a
    mask. The third argument can be "mask" or "use". In the former case
    (default) the actual reference map is made flat, in the latter the
    clipped version is used.
/*@ initial
    If the name of a dataset is given, this contains the initial estimate
    (the units of this map must be Jy/pixel, not Jy/beam). This dataset
    must have either one plane or the same number of planes as the input
    dataset. Can be the mem model of a previous run.
    If blank: an initial estimate is constructed; the pattern is a flat
    map with a flux determined by the flux keyword (see below).
/*@ flux
    Wanted total flux of final map. [Default is 0.] This is the flux that
    the source is supposed to have (use flux from single-dish observation
    if available).
    One value is needed for each input channel. The following formats are
    recognized (minimal match on 'gauss' and 'dataset'):
      flux=#            single value, replicated for all channels
      flux=#,#,#        one value per channel, the last one is replicated
      flux=gauss,a,c,w  flux has gaussian profile, with given amplitude 'a',
                        central channel 'c', and width in channels 'w'
      flux=dataset,set  'set' is a miriad dataset of 1 pixel in x/y and
                        z-length equal to the number of channels; flux is
                        read from this dataset.
    The flux value has a different meaning depending on its value and
    sign, as described in detail below (if flux is not 0, and the initial
    estimate is not read in, the keyword value gives the flux of the
    initial estimate).
      flux<0 => final flux unconstrained
      flux=0 => final flux unconstrained;
                - reference read in  => use flux of reference map
                - reference not read => flux at each pixel is <rms>
      flux>0 => final flux constrained to be the given value
/*@ beamsize
    Major and minor axis (in arcsec) and position angle (in degrees
    counterclockwise from the north) of a restoring beam. [Default is to
    calculate it as the straight average of the parameters of the dirty
    beams fitted by a gaussian.]
/*@ maxiters
    Maximum number of iterations. [Default 20].
/*@ tol
    Tolerance for convergence. The first value gives how close chi^2 and
    the flux must be from the wanted values (default 0.05, i.e. 5%); the
    second value gives the maximum value of the 'norm'. [Default 0.01.]
/*@ measure
    Entropy measure; "gull" or "cornwell" [gull] (no minimal match).
      gull:     H = -b*(log(b/r)-1)
      cornwell: H = -log(cosh(b/r))
/*@ lm0
    Initial value for Lagrange multipliers. [Default all 0).]
    The first value gives alpha, the second beta
    If you continue (i.e. set initial= to the previous result), also set
    alpha and beta to the values they had after the last iteration.
/*@ meslev
    Message level [default 2]. Levels are cumulative and produce ever
    more output Most useful are levels 2 through 4.
      0 : no output (silent run)
      1 : print basic timing info and planes program is working on
      2 : 1-line convergence info
      3 : fancier and more extensive convergence info
      4 : give information while waiting for initializations
      5 : list of dataset and control parameters after initializations
      6 : print more detailed gradient-sum information
      7 : print an approximate count of the number of operations
/*@ save
    Save intermediate results, for checking. The options in the list below
    can be combined. There is no minimal match. The most useful options are
    'res_iter' and 'est', to trace the development of the residual and the
    model. The rest is mainly useful to trace problems.
    The names of the output datasets are constructed by appending the
    option to the name of the input datasets. Except for options 'cov',
    'ref' and 'ggradx', the plane number is also added to the output file
    name; there is a separate output map for each plane of each input map.
    In the output maps each plane representing an iteration.
      - cov       save the uv-coverages (one for each input beam)
      - prb       save a map with the primary beam attenuation
      - conv      save extracted map convolved with synthesized beam
      - res_iter  save residuals for each iteration
      - res_int   save interpolated residuals
      - ref       save the (generated) reference dataset
      - ggradx    save the map of the second derivative of Grad chi^2
      - gradx     save the map containing the gradient of chi^2
      - gradx_int save the interpolated the gradient of chi^2
      - est       save the map with the current estimate
      - step      save the map holding the step taken
/*@ saveiter
    Specifies the first iteration at which saving is done. Saving is
    done for this and all later iterations.
    [Default 1.]
/*--

    This program can do its calculations on a different (faster) machine
    than where it is started and where the data are. See 'remote='. [not
    guaranteed until dtm library is updated.]

      - remote, hippi -- control over where the calculation is done

/*@ remote
    Enter the internet address (name) of the machine on which you want the
    actual calculations to be done. You need permission to use this machine
    i.e. you need to be listed in its .rhosts file. If allowed, the data
    will be sent over, the calculations will be done remotely, and the
    results will be sent back.
/*@ hippi
    'TRUE' or 'FALSE'; If 'TRUE', use the hippi connection. Default FALSE.


SD doc:

many keywords:
     - sdin, sdpbpar, sdrms -- specify single-dish inputs

after inputs for interferometer
    Inputs for single-dish data are: a
    list of miriad datasets with single-dish observations, an optional
    list of primary beam descriptions and a list of values for the rms
    noise in each single-dish input map.

    linmos: single-dish data: regridded map is added to lin mos.

/*@ sdin
    List of input maps with single-dish data. Each map may a 1x1 pixel
    datasets, for a single pointing, or a dataset combining a set of
    observations done on a regular grid.
/*@ sdpbpar
    Primary beam parameters for single-dish data. Same syntax as pbpar=.
/*@ sdrms
    List of rms values for single-dish data. Same syntax as rms=. If the
    sdin= keyword gave a combination map, there must be one rms value for
    each pixel in that map. The first value is for the spectrum in the
    the lower left corner, the second for the next x-position, etc.
*/
/******************************************************************************/
/*
   History:

   21-jul-93 bpw Original version
   26-aug-93 bpw Changed abs macro to fabs routine after problems on bima2
   27-aug-93 bpw Fixed fitting 2-d gaussian
   29-sep-93 bpw Major rearrangement, after finding bugs and implementing
                 suggestions after extensive usage; insert DTM blanks
    6-oct-93 bpw Fixed AT primary beam and SYSV timer functions
    8-oct-93 bpw Fixed linear mosaic weights
    9-feb-94 bpw Finished major redress of C* simulation and dtm code
                 - mode=noise added, ModeInput made more reliable
                 - AtoF now uses strtod
                 - operations counters added
                 - fix reading keywords from @ file
                 - improve output of memory use
                 - single scratch array for I/O and FT
                 - made all save options work again
                 - add maxcorr keyword
                 - different ways of clipping possible
                 - check presence of output before calculations
                 - quick fix of projection effects
                 - new improved criterion for damping delta alpha
                 - reshuffle of step routines
                 - avoid extra copy of data on IO
   29-mar-94 bpw Find best magic alpha change formula combination
   19-may-94 bpw Make all DTM code actually work
   20-jul-94 bpw Works on sgi power; lots of small fixes/changes, e.g.
                 - FFT choice via #defines
                 - Use "Real" instead of "Double" for datatype
                 - MapArrays function for sgi
                 - Document fixes suggested by pjt
                 - Keyword decoding now handles 'key  =  value'
                 - Single array memory allocation on sgi
                 - CreateDataPointers logic rewritten
                 - Timer routines improved
                 - Introduced res_final option
   19-oct-94 bpw FFT runs in parallel on SGIs
                 Things smoothed out
                 - improvements in operations counting
                 - inserted many timers, improved timer functions
                 - program now always split into multiple files
                 - more independence between different files
                 - compile and test scripts made
                 - allow use of xyio instead of xyzio
   27-oct-94 bpw - mosaic map now excludes all the zeroes outside merged
                   inner quarters
                 - convolution with gaussian reuses memory space
                 - adaptations in output for meslev=2/3
                 - flux keyword more versatile
    2-dec-94 bpw - some reorganization (introduce arrays.h, check.c, exch.c,
                   maps.c; introduce MOSDEBUG environment variable; introduce
                   'private'; simplify scratch allocation)
                 - checked with lint on different platforms
                 - wrote testscript, tested on mira/sirius/convex/monet
                 - fixed all small bugs that lint and script showed

*/

/*

/*----------------------------------------------------------------------------*/
#define DEFVARS
#include "mosaic.h"
/*----------------------------------------------------------------------------

/******************************************************************************/
/* <<< MAIN >>>                                        172 +  105 =  277 MAIN
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*
   MAIN
*/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/* <<< main >>>                                        114 +   67 =  181 MAIN
/******************************************************************************/
/*
   Start here. First interpret the keyword input. Then, deconvolve each
   individual plane.

   __main__ is a macro, defined with the purpose of lessening confusion
   because it avoids having to use the symbol indicating whether the CM SS
   library must be used or not outside of the file it is used in.
   If CMSSL used,     __main__ is MAIN_ and linking is done with cmf
   If CMSSL not used, __main__ is main  and linking is done with cs or cc
*/
/******************************************************************************/

private char *version = "3.0 2-dec-94";

int main( argc, argv )
int   argc;
char *argv[];
{
   void         keyini_c();
   int          MesLev, MesLevInp();
   logical      DTMmaster();
   void         DTMsetup();
   private void Local_main(), Remote_main();

   keyini_c( version, argc, argv );
   MesLev = MesLevInp();
   DTMsetup( "mosaic", version, MesLev );

   if( DTMmaster() ) Local_main();
   else              Remote_main();
   return(0);
}

private MOSMAP G_MosMap;
private ONEMAP G_Maps;
void MapStructs( MosMap, Maps )
MOSMAP **MosMap;
ONEMAP **Maps;
{
   *MosMap = &G_MosMap;
   *Maps   = &G_Maps;
}

/*

/******************************************************************************/
/*
   Local_main is called on local machine or when there is no remote machine.
   It sets up, calculates and closes off. In the called routines, routines may
   be started up that make Remote_main do something.

   Remote_main is only called on the remote machine. It waits for a signal from
   the master. This then delivers the structs and executes the appropriate
   function.
*/
/******************************************************************************/

private void Local_main()
{
   void     Timer_Start(), Timer_End();
   void     MapStructs();
   int      Initialize();
   void     DeConvolve();
   private void FinishOff();
   MOSMAP  *MosMap;
   ONEMAP  *Maps;
   logical  Flags[N_MOSFLAGS];
   CONTROL  CTRL;
   STATS    Stats;
   int      nPlanes;
   TRACE("Local_main");

   MapStructs( &MosMap, &Maps );

   Timer_Start("TOTAL");

   nPlanes = Initialize( MosMap, Maps, Flags, &CTRL, &Stats          );
   DeConvolve(           MosMap, Maps, Flags, &CTRL, &Stats, nPlanes );
   FinishOff(            MosMap, Maps, Flags                         );

   Timer_End("TOTAL");
}

/*

/******************************************************************************/
/*
   Interface the calls to calculation routines to execute on a remote machine.

   - If there is no remote machine, it returns FALSE and execution takes place.
   - If called on the master, send a signal to Remote_main, then wait while the
     remote machine executes, until it sends "READY".
     Meanwhile, a signals may arrive to save a dataset (the ready, abort and
     print signals are taken care of by DTMreceive).
     When ready, return TRUE, to skip the remainder of the calling function.
   - If called on the slave, returns FALSE, resulting in execution.
   - The calling function MUST use the construct:
     function() {
     if( !DTMremoteExec( Signal ) {
       statements
       DTMremoteExec("READY");
     }}
*/
/******************************************************************************/

logical DTMremoteExec( Signal )
char *Signal;
{
   logical LocallyRun(), DTMmaster(), DTMreceive(), DTMrclass();
   void    DTMsendSignal();
   void    Timer_Start(), Timer_End();
   void    SaveSet();

   if( StrEq(Signal,"READY") ) { DTMsendSignal("READY"); return TRUE; }

   if( DTMmaster() && !LocallyRun() ) {
      TRACE("DTMremoteExec");
      DTMsendSignal(Signal);

      Timer_Start("DTM_REMOTE_EXEC");
      while( DTMreceive() ) { if( DTMrclass("SAVE") ) SaveSet(0,DNULL,0); }
      Timer_End(  "DTM_REMOTE_EXEC");

      return FALSE;
   } else {
      return TRUE;
   }
}

/*

/******************************************************************************/
/*
   Loop on remote machine to wait for an instruction.
*/
/******************************************************************************/

private void Remote_main()
{
   void    MapStructs();
   logical DTMreceive(), DTMrclass();
   void    ExchangeVariables();
   void    ReadData(), WriteData();
   void    CreateDataPointers();
   void    InitArrays();
   void    Calculations();
   private void CleanUp();

   MOSMAP *MosMap;
   ONEMAP *Maps;
   logical Flags[N_MOSFLAGS];
   CONTROL CTRL;
   STATS   Stats;
   int     plane=1;

   TRACE("Remote_main");

   MapStructs( &MosMap, &Maps );

   while( DTMreceive() ) {
      if(        DTMrclass("SENDVARS") ) {
                 ExchangeVariables( "SENDVARS",MosMap,Maps,Flags,&CTRL,&Stats );
      } else if( DTMrclass("RESULTS") ) {
                 ExchangeVariables( "RESULTS", MosMap,Maps,Flags,&CTRL,&Stats );
      } else if( DTMrclass("TIMERS") ) {
                 ExchangeVariables( "TIMERS",  MosMap,Maps,Flags,&CTRL,&Stats );

      } else if( DTMrclass("READDATA")  ) {
                            ReadData(0,0,0,DNULL);
      } else if( DTMrclass("WRITEDATA")  ) {
                            WriteData(0,0,0,DNULL);

      } else if( DTMrclass("CREATEDATAPOINTERS") ) {
                            CreateDataPointers(MosMap,Maps,Flags );
      } else if( DTMrclass("INITARRAYS") ) {
                            InitArrays(  MosMap,Maps,Flags );
      } else if( DTMrclass("CALCULATIONS") ) {
                            Calculations(MosMap,Maps,Flags,&CTRL,&Stats,plane);
                            plane++;

      } else if( DTMrclass("CLEANUP") ) {
                            CleanUp(           MosMap,Maps );
                            break;
      }
      if( !DTMrclass("CLEANUP") ) TRACE("Back in remote_main");
   }
}

/*

/******************************************************************************/
/******************************************************************************/
/******************************************************************************/
/*   <<< Finish >>>                                    13 +   13 =   26 MAIN
/******************************************************************************/
/*
   Clear up and out.
   A clean way of closing would be to send a "READY" signal to the remote
   machine. However, it appears that this causes a hangup because the local
   machine stops before the remote machine has received the signal. So, instead
   let the remote machine send the last signal (in CleanUp) and let it stop
   itself. The last signal is found by DTMremoteExec in CleanUp. The local
   machine will then stop too.
*/
/******************************************************************************/

private void FinishOff( MosMap, Maps, Flags )
MOSMAP  *MosMap;
ONEMAP  *Maps;
logical  Flags[];
{
   private void CleanUp();
   void CloseDataSets();
/*   void DTMsendSignal();*/

   CleanUp(       MosMap, Maps );
   CloseDataSets( MosMap, Maps, Flags );
/*   DTMsendSignal( "READY" );*/
}

/*

/******************************************************************************/
/*
   Neatly get rid of FFTs that were set up.
*/
/******************************************************************************/

private void CleanUp( MosMap, Maps )
MOSMAP  *MosMap;
ONEMAP  *Maps;
{
logical DTMremoteExec();
if( DTMremoteExec("CLEANUP") ) {

   void Timer_End();
#ifdef __CSTAR__
  {void fft_deall();
   ONEMAP *MapI;

   for(ALLMAPSI) { if(MapI->IsIFmap)     fft_deall( &MapI->MemArr.ftid ); }
   if( MosMap->RestoringBeam.CreatedRB ) fft_deall( &MosMap->MemArr.gauftid );}
#else
   MosMap = MosMap; /* keep lint quiet */
   Maps   = Maps;   /* keep lint quiet */
#endif
   Timer_End("REMOTE_DTM");

   (void)DTMremoteExec("READY");
}
}
