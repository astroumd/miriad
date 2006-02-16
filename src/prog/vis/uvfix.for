c***********************************************************************
	program uvfix
	implicit none
c
c= uvfix - Re-calculate obsra, obsdec and (u,v,w) from radec keyword.
c& mchw
c: uv analysis
c+
c	UVFIX Re-calculates obsra, obsdec and (u,v,w) from radec keyword.
c	UVFIX does NOT change the phase.
c	use UVCAL to correct the phase to the new phase center.
c	By default, UVFIX applies the calibration files 
c	before it processes the uv-data into the output file.
c@ vis
c	The names of the input uv data sets. Multiple names can be given,
c	separated by commas. At least one name must be given.
c@ select
c	The normal uv selection commands. See the Users manual for details.
c	The default is to process all data. Note that window selection can
c	not be used with options=hanning, passband, contsub, or wide.
c@ radec
c   Source right ascension and declination. These can be given in
c   hh:mm:ss,dd:mm:ss format, or as decimal hours and decimal
c   degrees. Setting RA and DEC will change the phase center to
c   the RA and DEC specified. The default leaves the data unchanged.
c@ options
c	This gives extra processing options. Several options can be given,
c	each separated by commas. They may be abbreivated to the minimum
c	needed to avoid ambiguity. Possible options are:
c	   'nocal'      Do not apply the gains file.
c	   'nopass'     Do not apply bandpass corrections.
c	   'nopol'      Do not apply the polarization leakage file.
c	   'nowide'     Do not copy across wide-band channels.
c	   'nochannel'  Do not copy across spectral channels.
c	   'unflagged'  Copy only those records where there are some
c	                unflagged visibilites.
c	   'contsub'    Continuum subtraction using a linear fit to the real
c                   and imaginary parts of each spectral window.
c 	                Exclude badchan and endchan specified below.
c	   'conjugate'  Conjugate visibilities
c      'fxcal'      Calibrate FX correlator data
c                   by dividing the cross correlations by the 
c                   geometric mean of the autocorrelations.
c	   'hanning'    Hanning smooth each spectral window.
c	   'holo'       Replace u,v with dra,ddec for holography.
c	   'linecal'	Remove phase slope across passband due to line length
c                   changes. This option also corrects the phase difference
c                   between the wide channels due to line length.
c                   options=linecal,wide will re-make the wideband from
c                   the channel data after the phase slope is removed.	
c                   option can gain in SNR for the wide channels might be
c      'parang'	    Multiply LR by expi(2*chi) and RL by expi(-2*chi)
c                   where chi is the parallactic angle for Alt-Az antennas.
c	   'passband'   Fit passband to lsb and correct the uv-data.
c                   Can be used when the source is strong. e.g. for
c	                planets. The passband is estimated from the lsb,
c	                smoothed within each spectral window, and applied
c	                to the lsb data. The complex conjugate is applied
c                   to the usb. This corrects for time variable IF
c                   passband errors. The uv-data must contain the same
c                   spectral windows in both sidebands of LO1.
c	   'uvrotate'	Rotate uv-coordinates from current to standard epoch.
c                   The standard epoch, ra, dec can be changed using PUTHD.
c	   'avechan'	Average unflagged spectral channels into wide,2,1 for
c                   lsb and usb of LO1 respectively. The data are weighted by
c                   bandwidth and exclude badchan and endchan specified below.
c                   Also remake wideband average for each spectral window.
c	   'avewide'	Average unflagged wideband channels into wide,2,1 for
c                   lsb and usb of LO1 respectively. The data are weighted by
c                   bandwidth and exclude badchan specified below and wide,2,1
c
c	NOTE: 	Options=nochannel cannot be used with "hanning", "passband"
c	and "contsub". For these 3 options no processing is performed on the
c	wideband data.
c@ badchan
c	Number of ranges of bad channels followed by list of up to 20 pairs
c	of numbers giving range of channels to exclude in options=contsub
c	and options=avechan. E.g. badchan=3,1,3,15,16,256,257 
c	excludes the 3 ranges	(1,3) (15,16) and (265,257)
c@ endchan
c	Number of channels to drop from the ends of each spectral
c	window in options=passband, contsub, and avechan. Default=0.
c@ nave
c	Number of channels to average in options=passband. Default=1.
c@ sigma
c	Rms noise level used to flag data in options=contsub. All channels
c	are flagged if the rms noise level per channel is greater than sigma
c	after subtracting the continuum. Endchan and badchan are not included
c	in computing the rms. The default is sigma=0. which does not flag
c	any data.
c@ scale
c	Multiply the data and wideband by cmplx(scale1,scale2). Two values.
c	Default is no scaling. If only one value is given it is assumed to
c	be a real value. E.g. scale=0,1 multiplies the data by sqrt(-1)
c@ offset
c	Subtract a complex valued offset from the uv-data. Two values give
c   amplitude (after calibrations have been applied by uvcal) 
c   and phase in degrees.  Default is none.
c@ model
c	Subtract a source model from the uv-data. Three values
c	give the flux density [Jy], scale [nanosecs], and index 
c	for a radial power law:
c		model = flux * (uvdist/scale) ** index
c	The model visibility is subtracted from the uv-data.
c	Default model=0,0,0. i.e. no model is subtracted.
c@ polcal
c	Subtract the source polarization from the uv-data. Two values
c	give polarized intensity, Ip, and position angle, 2*psi, in degrees.
c	Use same amplitude units as uv-data after calibration is applied..
c	subtract Ip*expi(2*psi)*expi(-2*chi) from LR, and
c	subtract Ip*expi(-2*psi)*expi(2*chi) from RL
c	where chi is the parallactic angle for Alt-Az antennas.
c	Default=0,0. is no correction.
c	After subtracting the source polarization, the averaged uv-data
c	gives the instrumental polarization for each baseline.
c@ polcode
c	Change the polarization code. Default polcode=0 makes no change.
c	Polarizations are  YX,XY,YY,XX,LR,RL,LL,RR,-,I,Q,U,V
c	Polarization codes -8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4
c	E.g.  polcode=4  changes YX,XY,YY,XX to LR,RL,LL,RR
c	E.g.  polcode=-4 changes LR,RL,LL,RR to YX,XY,YY,XX
c@ parot
c	Rotate uv coordinates and hence image by parot degrees.
c	Rotation is +ve to the E from N. i.e. increasing PA.
c	Default is no rotation.
c@ out
c	The name of the output uv data set. No default.
c--
c
c  History:
c    rjs  Dark-ages Original version of uvcat.
c    mchw 07mar91   Added passband option for planet observations.
c    mchw 19mar91   Added hanning option.
c    mchw 28mar91   Changes to handle processing options after window selection.
c    rjs  19apr91   Repaired options=nochan, which I apparently broke on
c		    20feb91.
c    rjs  20may91   Added xyphase to the list of variables to copy.
c    rjs  28jun91   Handle the flags for polarisation leakage correction.
c    mjs  04aug91   Replaced local maxants with maxdim.h value MAXANT
c    mchw 08oct91   Continuum subtraction option using linear fit to spectra.
c    mchw 22oct91   Split off special processing options from uvcat.
c    mchw 23oct91   Added flagging of noisy data in options=contsub.
c    nebk 16jan92   Add option to conjugate visibilities, corrected
c                   help to include NOPOL option.   Added code stolen
c                   from parent UVCAT to write out polarization info.
c    mchw 21jul92   Fixed a precision problem in linfit.
c    rjs  17aug92   Added var routines. Some changes to .doc.
c    mchw 16jun93   Add imaginary option to multiply by sqrt(-1)
c		    Handle wideband for conjugate and imaginary options.
c    mchw 12aug93   Elliminate time average in options=passband.
c			Added avechan keyword.
c    mchw 20sep93   Option 'phasem' Replace last channel and wideband
c			  with predicted line length phase.
c    mchw 07oct93   Option 'holo' Replace u,v with dra,ddec for holography.
c    mchw 30nov93   Option 'tpower' Replace last channel and wideband
c			  with predicted phase from tpower differences.
c    mchw 01jan94   Option 'wide'  Make wideband from channel average
c		    	for each sideband of LO1.
c    mchw 10apr94  Changed maxwins to MAXWIN; put MAXWIN into maxdim.h.
c    mchw 26aug94  More documentation and checks. Contsub each window.
c		   New options=linecal. Add window selection and remove
c			badchan from options=wide.
c    mchw 18may95  Added keyword scale; removed options=minus, imaginary.
c    mchw 15mar96  Use badchan mask in options=wide.
c    mchw 04jun96  Rotate uv-coordinates from current to standard epoch.
c    mchw 04jul96  Multiply LR by expi(2*chi) and RL by expi(-2*chi)
c    mchw 09jul96  Subtract source polarization from the uv-data.
c    mchw 01aug96  Changes to support variable nwide. Change polcode.
c		   Removed options=phasem and tpower.
c    mchw 18jun97  Subtract power law model from the uv-data.
c    mchw 25jun97  remake wideband average for each spectral window.
c    pjt  25jun98  better fortran standards for linux/g77 
c    mchw 25jul03  Added uvrotation.
c    mchw 25aug03  Correct doc, call uvrdvrr (lIn, 'chi', chi, 0.)
c    mchw 27nov04  Add fxcal.  uvset(tOut,'preamble','uvw/time/baseline')
c    mchw 22dec04  Subtract offset from uvdata.
c    mchw 22apr05  add code to change phase center.
c    mchw 05may05  change sign of phase correction in pcenter.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer maxbad
	character version*(*)
	parameter(version='UVFIX: version 3.0 05-May-2005')
	parameter(maxbad=20)
	real PI
	parameter(PI=3.1415926)
c
	integer nchan,lIn,lOut,i,nPol,Pol,SnPol,SPol,endchan
	integer nwide,length,nave,lflags,nbad,badchan(maxbad)
	double precision preamble(5)
	complex data(MAXCHAN),wdata(MAXCHAN)
	logical flags(MAXCHAN),wflags(MAXCHAN)
	logical first,init,new,more,dopol,PolVary
	logical dochan,dowide,docopy,updated,doscale,dopolcal,domodel
	logical nocal,nopol,nopass,nowide,nochan,doall,dopass,
     *       dohann,docont,doconj,dophase,holo,dopower,avechan,avewide,
     *       linecal,uvrot,doparang,dooffset,dofxcal
	character out*64, type*1, uvflags*8, source*16
	real mask(MAXCHAN),sigma
	integer polcode
	real dra,ddec,parot,sinpa,cospa
	real scale(2),polcal(2),model(3),offset(2)
	complex coffset
	double precision obsra,obsdec
       double precision obsra_calc,obsdec_calc,arcsec/4.8481370E-06/
	double precision ra,dec,uu,vv,epoch,jepoch,theta,costh,sinth,jd
c
c  Externals.
c
	logical uvDatOpn, uvDatPrb
	double precision epo2jul
	complex expi
c
	call output(version)
	call bug('i','        New FXCAL option  27nov04')
	call bug('i','Change sign of phase center 05may05')
	call keyini
	call GetOpt(nocal,nopol,nopass,nowide,nochan,doall,dopass,
     *       dohann,docont,doconj,dophase,holo,dopower,avechan,avewide,
     *       linecal,uvrot,doparang,dofxcal)
	lflags = 3
	uvflags(1:3) = 'ds3'
	if(.not.nocal)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'c'
	endif
	if(.not.nopol)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'e'
	endif
	if(.not.nopass)then
	  lflags = lflags + 1
	  uvflags(lflags:lflags) = 'f'
	endif
c
	call uvDatInp('vis',uvflags(1:lflags))
	call keya('out',out,' ')
      call keyt('radec',ra,'hms',0.d0)
      call keyt('radec',dec,'dms',0.d0)
	call keyi('nave',nave,1)
	call keyi('endchan',endchan,0)
	call keyi('badchan',nbad,0)
	if(nbad.gt.0)then
	  do i=1,2*nbad
	    call keyi('badchan',badchan(i),0)
	  enddo
	endif
	call keyr('offset',offset(1),0.)
	call keyr('offset',offset(2),0.)
	call keyr('scale',scale(1),0.)
	call keyr('scale',scale(2),0.)
	call keyr('model',model(1),0.)
	call keyr('model',model(2),0.)
	call keyr('model',model(3),0.)
	call keyr('polcal',polcal(1),0.)
	call keyr('polcal',polcal(2),0.)
	call keyi('polcode',polcode,0)
	call keyr('parot',parot,0.)
	call keyfin
c
c  Check user inputs.
c
	if(out.eq.' ') call bug('f','Output file name is missing')
	if(uvDatPrb('window?',0.d0) .and.
     *	  (dohann.or.dopass.or.docont)) call bug('f',
     *		'Window selection cannot be used with these options')
	dooffset = offset(1).ne.0.
	if(dooffset) coffset=offset(1)*expi(offset(2)*PI/180.)
	domodel = model(1).ne.0.
	doscale = scale(1).ne.0..or.scale(2).ne.0.
	dopolcal = polcal(1).ne.0.
	if(dopolcal) polcal(2) = polcal(2)*PI/180.
c
c  Open the output.
c
	call uvopen(lOut,out,'new')
	call uvset(lOut,'preamble','uvw/time/baseline',0,0.,0.,0.)
c
c  Other initialisation.
c
	first = .true.
	init = .false.
	new = .true.
	SnPol = 0
	SPol = 0
	PolVary = .false.
	call badinit(nbad,badchan,maxbad,mask,maxchan)
c
c  Loop the loop. Open a file, process it, copy it, etc.
c
	more = uvDatOpn(lIn)
	dowhile(more)
	  if(new)then
	    call SetUp(lIn,dopol,nochan,nowide,dochan,dowide)
	    if(dowide.and..not.dochan)
     *	      call uvset(lOut,'data','wide',0,1.,1.,1.)
	    new = .false.
	  endif
	  if(.not.dochan.and.(dohann.or.dopass.or.docont))
     *	    call bug('f','Invalid option when there is no channel data')
c
c  Copy the history the first time, and set the form of the output
c  correlations the first time we are to copy some.
c
	  if(first)then
	    call hdcopy(lIn,lOut,'history')
	    first = .false.
	  endif
	  if(.not.init.and.dochan)then
	    call uvprobvr(lIn,'corr',type,length,updated)
	    call uvset(lOut,'corr',type,0,0.,0.,0.)
	    init = .true.
	  endif
c
c  Read in the data and apply the gains.
c
	  call uvDatRd(preamble,data,flags,maxchan,nchan)
c
c  Case of end-of-file. Close the old file, and open the new.
c
	  if(nchan.eq.0)then
	    call uvDatCls
	    more = uvDatOpn(lIn)
	    new = .true.
c
c  Case of still more data. Copy across any variables that we want,
c  write out the data.
c
	  else
c
c  Determine the polarisation info, if needed.
c
            if(dopol)then
              call uvDatGti('npol',nPol)
              if(nPol.le.0) call bug('f',
     *          'Could not determine number of polarizations present')
              if(nPol.ne.SnPol)then
                call uvputvri(lOut,'npol',nPol,1)
                PolVary = SnPol.ne.0
                SnPol = nPol
              endif
              call uvDatGti('pol',Pol)
              if(Pol.ne.SPol)then
                Pol = Pol + polcode
                call uvputvri(lOut,'pol',Pol,1)
                SPol = Pol
              endif
            endif
c
c  Check if these data are wanted.
c
	    docopy = doall
	    if(.not.docopy)then
	      do i=1,nchan
	        docopy = docopy .or. flags(i)
	      enddo
	    endif
c
c
c  Copy the variables we are interested in.
c
	    if(docopy)then
	      call VarCopy(lIn,lOut)
c
c  Special processing options.
c

c   Calibrate FX correlator data
c   by dividing the cross correlations by the geometric mean
c   of the autocorrelations.

       if(dofxcal) call fxcal(lIn,preamble(5),data,flags,nchan)

c   Setting RA and DEC will change the phase center to
c   the RA and DEC specified. The default leaves the data unchanged.

       if(ra.ne.0.d0 .or. dec.ne.0.d0)then

c  Get apparent RA and DEC of phase center at time of observation.
         call uvrdvrd(lIn,'epoch',epoch,2000.0d0)
         jd = epo2jul(epoch, ' ')
         call uvrdvra(lIn,'source',source,'unknown')
c         call uvgetvrd(lIn,'ra',ra,1)
c         call uvgetvrd(lIn,'dec',dec,1)
         call precess(jd,ra,dec,preamble(4),obsra,obsdec)
         call pcenter(lIn,preamble,data,nchan,obsra,obsdec,'none')
         call uvputvrd(lout,'ra',ra,1)
         call uvputvrd(lout,'obsra',obsra,1)
         call uvputvrd(lout,'dec',dec,1)
         call uvputvrd(lout,'obsdec',obsdec,1)
       endif

c      'uvrotate'   Rotate uv-coordinates from current to standard epoch.
c           The standard epoch, ra, dec can be changed using PUTHD.

              if(uvrot)then
                call uvrdvrd(Lin, 'epoch', epoch, 2000.0d0)
                call uvrdvrd(Lin, 'ra', ra, 0.0d0)
                call uvrdvrd(Lin, 'dec', dec, 0.0d0)
                jepoch = epo2jul(epoch, ' ')
                call prerotat(jepoch, RA, dec, preamble(4), theta)
                costh = cos(theta)
                sinth = sin(theta)
                uu = preamble(1)
                vv = preamble(2)
                preamble(1) = (uu * costh) + (vv * sinth)
                preamble(2) = (vv * costh) - (uu * sinth)
              endif

c   Rotate uv coordinates and hence image by parot degrees.
c   Rotation is +ve to the E from N. i.e. increasing PA.
c   Default is no rotation.

             if(parot.ne.0. )then
               sinpa = sin(parot*PI/180.)
               cospa = cos(parot*PI/180.)
               uu = preamble(1)
               vv = preamble(2)
               preamble(1) = (uu * cospa) + (vv * sinpa)
               preamble(2) = (vv * cospa) - (uu * sinpa)
              endif
c
	      if(holo)then
	        call uvgetvrr(lIn,'dra',dra,1)
	        call uvgetvrr(lIn,'ddec',ddec,1)
	        preamble(1) = 2.062648062d05*dra
	        preamble(2) = 2.062648062d05*ddec
	      endif
c
	      if(dohann) call Hanning(lIn,data,flags,nchan)
	      if(dopass) call Passband(lIn,data,flags,nchan,
     *							endchan,nave)
	      if(docont) call Contsub(lIn,data,flags,nchan,
     *						endchan,mask,sigma)
	      if(linecal)
     *		  call linecal1(lIn,data,flags,nchan,wdata,wflags,nwide,
     *					dowide,dochan,preamble)
	      if(avechan)
     *	          call makewide(lIn,data,flags,nchan,wdata,wflags,nwide,
     *					endchan,mask,'chan')
	      if(avewide)
     *	          call makewide(lIn,data,flags,nchan,wdata,wflags,nwide,
     *					endchan,mask,'wide')
c
c  Process the wideband data separately if doing both wide and channel data.
c
	      if(dowide.and.dochan)then
                if(.not.(avewide.or.avechan.or.linecal))
     *                    call uvDatWRd(wdata,wflags,maxchan,nwide)
		if(dooffset)then
		  do i=1,nwide
		    wdata(i) = wdata(i) - coffset
		  enddo
		endif
		if(doscale)then
		  do i=1,nwide
		    wdata(i) = cmplx(scale(1),scale(2)) * wdata(i)
		  enddo
		endif
		if(doconj)then
		  do i=1,nwide
		    wdata(i) = conjg(wdata(i))
		  enddo
		endif
		if(doparang)then
		  call parang1(lIn,Pol,wdata,nwide)
		endif
		if(domodel)then
		  call model1(lIn,preamble,wdata,nwide,model)
		endif
		if(dopolcal)then
		  call polcal1(lIn,Pol,wdata,nwide,polcal)
		endif
	        call uvwwrite(lOut,wdata,wflags,nwide)
	      endif
c
c  Now process the line data, or the wideband data in the case of no channel data.
c
		if(dooffset)then
		  do i=1,nchan
		    data(i) = data(i) - coffset
		  enddo
		endif
		if(doscale)then
		  do i=1,nchan
		    data(i) = cmplx(scale(1),scale(2)) * data(i)
		  enddo
		endif
		if(doconj)then
		  do i=1,nchan
		    data(i) = conjg(data(i))
		  enddo
		endif
		if(doparang)then
		  call parang1(lIn,Pol,data,nchan)
		endif
		if(domodel)then
		  call model1(lIn,preamble,data,nchan,model)
		endif
		if(dopolcal)then
		  call polcal1(lIn,Pol,data,nchan,polcal)
		endif
	      call uvwrite(lOut,preamble,data,flags,nchan)
	    endif
	  endif
	enddo
c
c  Write out the "npol" parameter, if it did not vary.
c
        if(.not.PolVary) call wrhdi(lOut,'npol',npol)
c
c  Finish up the history, and close up shop.
c
        call hisopen(lOut,'append')
        call hiswrite(lOut,'UVCAL: Miriad '//version)
        call hisinput(lOut,'UVCAL')
        call hisclose (lOut)
        call uvclose(lOut)
        end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine SetUp(lIn,dopol,nochan,nowide,dochan,dowide)
c
	implicit none
	logical dopol,nochan,nowide,dochan,dowide
	integer lIn
c
c  Input:
c    lIn	Handle of the uv dataset.
c    nochan	True if the user does not want "corr" data.
c    nowide	True if the user does not want "wcorr" data.
c  Output:
c    dochan	Copy "corr" data across.
c    dowide	Copy "wcorr" data across.
c    dopol	True if the file contains polarisation information.
c------------------------------------------------------------------------
	character type*1
	integer length
	logical updated
c
c  Check if "wcorr" and "corr" are present, and determine which ones we
c  want to write out.
c
	call uvprobvr(lIn,'wcorr',type,length,updated)
	dowide = type.eq.'c'.and..not.nowide
	call uvprobvr(lIn,'corr',type,length,updated)
	dochan = (type.eq.'r'.or.type.eq.'j'.or.type.eq.'c')
     *		 .and..not.nochan
c
	if(dochan)then
	  call VarInit(lIn,'channel')
	  if(dowide)call VarWInit(lIn)
	else if(dowide)then
	  call uvset(lIn,'data','wide',0,1.,1.,1.)
	  call VarInit(lIn,'wide')
	else
	  call bug('f','No corr or wcorr data to copy')
	endif
c
	call uvprobvr(lIn,'npol',type,length,updated)
	dopol = type.eq.'i'
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine GetOpt(nocal,nopol,nopass,nowide,nochan,doall,dopass,
     *       dohann,docont,doconj,dophase,holo,dopower,avechan,avewide,
     *       linecal,uvrot,doparang,dofxcal)
c
	implicit none
	logical nocal,nopol,nopass,nowide,nochan,doall,dopass,
     *       dohann,docont,doconj,dophase,holo,dopower,avechan,avewide,
     *       linecal,uvrot,doparang,dofxcal
c
c  Determine extra processing options.
c
c  Output:
c    nocal	If true, do not apply selfcal corrections.
c    nopol	If true, do not apply polarisation corrections.
c    nopass	If true, do not apply bandpass corrections.
c    nowide	True if wide channels are not to be copied across.
c    nochan	True if spectral channels are not to be copied across.
c    doall	True if all data (not just unflagged) is to be copied.
c    dopass	True if passband option is selected.
c    dohann	True if hanning option is selected.
c    docont	True if contsub option is selected.
c    doconj    Conjugate visibilities
c    dophase   Predict line length phase.
c    dopower   Predict phase from tpower differences.
c    dofxcal   Calibrate cross correlations using sqrt(autcorrelations)
c    holo      Replace u,v with dra,ddec for holography.
c    avechan   Average unflagged spectral channels into wide,2,1
c    avewide   Average unflagged wideband channels into wide,2,1
c    linecal   Correct phase slope due to line length change.
c    uvrot     Rotate uv-coordinates from current to standard epoch.
c    doparang  Multiply LR by expi(2*chi) and RL by expi(-2*chi)
c------------------------------------------------------------------------
	integer nopt
	parameter(nopt=17)
	character opts(nopt)*9
	logical present(nopt)
	data opts/'nocal    ','nowide   ','nochannel','unflagged',
     *		  'passband ','hanning  ','nopol    ','contsub  ',
     *            'conjugate','nopass   ','holo     ',
     *            'avechan  ','avewide  ','linecal  ',
     *            'uvrotate ','parang   ','fxcal    '/

	call options('options',opts,present,nopt)
	nocal   = present(1)
	nowide  = present(2)
	nochan  = present(3)
	doall   = .not.present(4)
	dopass  = present(5)
	dohann  = present(6)
	nopol   = present(7)
	docont  = present(8)
	doconj  = present(9)
	nopass  = present(10)
	holo    = present(11)
	avechan = present(12)
	avewide = present(13)
	linecal = present(14)
	uvrot   = present(15)
	doparang= present(16)
	dofxcal = present(17)
c
c  Check for imcompatible options
c
	if(avechan.and.avewide)call bug('f',
     *	  'Options "avechan" and "avewide" cannot be used together.')
	if(nochan.and.(dohann.or.dopass.or.docont))call bug('f',
     *	  'options=nochannel cannot be used with "hanning", "passband"
     * or "contsub"')
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	      subroutine Passband(lIn,data,flags,nchan,
     *							endchan,nave)
c
	implicit none
	integer lIn,nchan,nave,endchan
	complex data(nchan)
	logical flags(nchan)
c
c  Fit passband to spectra and apply to the data.
c
c  Input:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    nave	Number of channels to average.
c    endchan	Number of end channels to drop.
c  Input/Output:
c    data
c    flags
c------------------------------------------------------------------------
	include 'maxdim.h'
	complex pass(MAXCHAN),opass(MAXCHAN/2),anorm
	integer nspect,ischan(MAXWIN),nschan(MAXWIN)
	integer i,j,k,j1,j2,npass(MAXCHAN/2)
	real chan
c
c  Get the dimensioning info.
c
	  call uvgetvri(lIn,'nspect',nspect,1)
	  if(nspect.le.0)
     *	    call bug('f','Bad value for uv variable nspect')
	  call uvgetvri(lIn,'ischan',ischan,nspect)
	  call uvgetvri(lIn,'nschan',nschan,nspect)
c
c  Store passband estimate.
c
	do i=1,nspect/2
	  do j=ischan(i), ischan(i)+nschan(i)-1
	    pass(j) = data(j)
	  enddo
	enddo
c
c  Smooth channels within each spectral window.
c
	do i=1,nspect/2
	  j1=ischan(i)
	  j2=ischan(i)+nschan(i)-1
          do j=j1,j2
	    npass(j) = 0
	    opass(j) = pass(j)
            do k=max(j1+endchan,j-nave/2),
     *				min(j2-endchan,j+nave/2)
              npass(j) = npass(j) + 1
	      opass(j) = opass(j) + pass(k)
            enddo
	  enddo
          do j=j1+endchan,j2-endchan
            pass(j) = opass(j)/npass(j)
	  enddo
	enddo
c
c  Normalize the passband relative to amplitude and phase of lsb.
c  This assumes that the data contain both lsb and usb.
c  Omit endchan channels in normalization.
c
	anorm = (0.,0.)
	chan = 0.
	do i=1,nspect/2
	  do j=ischan(i)+endchan, ischan(i)+nschan(i)-endchan-1
	    anorm = anorm + pass(j)
	    chan = chan + 1.
	  enddo
	enddo
	anorm = anorm/chan
c
c  Apply the passband to the data.
c  Use the conjugate of the lsb to correct the usb.
c
	do i=1,nspect/2
	  do j=ischan(i), ischan(i)+nschan(i)-1
	    data(j) = anorm * data(j) / pass(j)
	    data(j+nchan/2) = anorm * data(j+nchan/2) / conjg(pass(j))
	  enddo
	enddo
c
c  Return with the corrected data.
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine Hanning(lIn,data,flags,nchan)
c
	implicit none
	integer nchan
	complex data(nchan)
	logical flags(nchan)
	integer lIn
c
c  Hanning smooth each spectral window.
c
c  Input:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c  Input/Output:
c    data
c    flags
c------------------------------------------------------------------------
	include 'maxdim.h'
	complex hann(MAXCHAN)
	integer nspect,ischan(MAXWIN),nschan(MAXWIN)
	integer i,j,j1,j2
c
c  Get the dimensioning info.
c
	  call uvgetvri(lIn,'nspect',nspect,1)
	  if(nspect.le.0)
     *	    call bug('f','Bad value for uv variable nspect')
	  call uvgetvri(lIn,'ischan',ischan,nspect)
	  call uvgetvri(lIn,'nschan',nschan,nspect)
c
c  Hanning smooth each spectral window. Copy end channels.
c
	do i=1,nspect
	  j1=ischan(i)+1
	  j2=ischan(i)+nschan(i)-2
	  do j=j1,j2
	    hann(j) = 0.25*data(j-1) + 0.5*data(j) + 0.25*data(j+1)
	  enddo
	  do j=j1,j2
	    data(j) = hann(j)
	  enddo
	enddo
c
c  Return with the corrected data.
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine linecal1(lIn,data,flags,nchan,wdata,wflags,nwide,
     *					dowide,dochan,preamble)
	implicit none
	integer lIn,nchan,nwide
	complex data(nchan),wdata(nchan)
	logical flags(nchan),wflags(nchan),dowide,dochan
	double precision preamble(5)
c
c  Remove phase slope across passband due to line length changes.
c  This option also corrects the phase difference
c  between the wide channels due to line length.
c
c  In:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    dowide	do wide data.
c    dochan	do channel data.
c    preamble
c  In/out:
c    data	Channel data
c    flags	Channel flags
c  Out:
c    wdata	wide data
c    wflags	wide flags
c    nwide	number of wide data.
c------------------------------------------------------------------------
	include 'maxdim.h'
	integer i,ant1,ant2,nants
	real phasem(MAXANT),phaselo1,wfreq(MAXWIN),phase
	double precision sfreq(MAXCHAN),lo1
c
c  Externals.
c
	complex expi
c
c  Get the line length phase for lo1.
c
	call uvrdvrd(lIn,'lo1',lo1,0.d0)
	if(lo1.eq.0.d0)
     *	  call bug('f','LO1 zero or missing in uv-data')
	call uvgetvri(lIn,'nants',nants,1)
	call uvgetvrr(lIn,'phasem1',phasem,nants)
	call basant(preamble(5),ant1,ant2)
	phaselo1 = phasem(ant1)-phasem(ant2)
c
c  Handle the wideband if channel data also present.
c
	if(dowide.and.dochan) then
     	  call uvDatWRd(wdata,wflags,MAXCHAN,nwide)
	  call uvgetvrr(lIn,'wfreq',wfreq,nwide)
	  do i=1,nwide
	    phase = wfreq(i) / lo1 * phaselo1
	    wdata(i) = wdata(i) * expi(phase)
	  enddo
	endif
c
c  Handle the selected data.
c
	call uvinfo(lIn,'sfreq',sfreq)
	do i=1,nchan
	  phase = sfreq(i) / lo1 * phaselo1
	  data(i) = data(i) * expi(phase)
	enddo
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine makewide(lIn,data,flags,nchan,wdata,wflags,nwide,
     *					endchan,mask,line)
	implicit none
	integer lIn,nchan,nwide,endchan
	complex data(nchan),wdata(nchan)
	logical flags(nchan),wflags(nchan)
	real mask(nchan)
	character*4 line
c
c  Make wideband average for each sideband of LO1.
c
c  In:
c    lIn	Handle of input uv-data.
c    data	data
c    flags	flags
c    nchan	Number of input channel or wideband data.
c    endchan	Number of end channels to drop.
c    mask       Mask for bad channels.
c    line	'wide' or 'chan' data
c  Out:
c    wdata	wide data
c    wflags	wide flags
c    nwide	number of output wideband data.
c------------------------------------------------------------------------
	include 'maxdim.h'
	double precision sfreq(MAXWIN),sdf(MAXWIN),lo1,freq
	integer nspect,ischan(MAXWIN),nschan(MAXWIN)
	real wfreq(MAXCHAN),wwidth(MAXCHAN)
	real wt(MAXWIDE)
	integer i,j,j1,j2,k,newide
c
c  Get the dimensioning info.
c
	call uvrdvrd(lIn,'lo1',lo1,0.d0)
	if(lo1.eq.0.d0) call bug('f','LO1 zero or missing in uv-data')
	if(line.eq.'chan')then
	  call uvgetvri(lIn,'nspect',nspect,1)
	  if(nspect.le.0)
     *	    call bug('f','Bad value for uv-variable nspect')
	  call uvgetvri(lIn,'ischan',ischan,nspect)
	  call uvgetvri(lIn,'nschan',nschan,nspect)
	  call uvgetvrd(lIn,'sdf',sdf,nspect)
	  call uvgetvrd(lIn,'sfreq',sfreq,nspect)
	else if(line.eq.'wide')then
          call uvgetvri(lIn,'nwide',nwide,1)
          if(nwide.le.0)
     *      call bug('f','Bad value for uv-variable nwide')
          call uvgetvrr(lIn,'wfreq',wfreq,nwide)
          call uvgetvrr(lIn,'wwidth',wwidth,nwide)
	else
	  call bug('f','Invalid line in subroutine makewide')
	endif
c
c  Make wideband channels with lsb in wide,1,1 and usb in wide,1,2
c
     	call uvDatWRd(wdata,wflags,MAXCHAN,nwide)
	if(line.eq.'chan')then
	  newide = nwide
	else if(line.eq.'wide')then
	  newide = 2
	endif
	do i=1,newide
	  wdata(i) = (0.,0.)
	  wt(i) = 0.
	enddo
c
c  Sum the good channels.
c
	if(line.eq.'chan')then
	  k = 0
	  do i=1,nspect
	    j1=ischan(i)+endchan
	    j2=ischan(i)+nschan(i)-1-endchan
	    do j=j1,j2
	      freq = sfreq(i) + sdf(i) * (j-ischan(i))
	      k = k + 1
	      if(flags(k).and.mask(k).ne.0)then
		wdata(i+2) = wdata(i+2) + sdf(i) * data(k)
	        wt(i+2) = wt(i+2) + sdf(i)
	        if(freq.lt.lo1)then
	          wdata(1) = wdata(1) + sdf(i) * data(k)
	          wt(1) = wt(1) + sdf(i)
	        else
	          wdata(2) = wdata(2) + sdf(i) * data(k)
	  	  wt(2) = wt(2) + sdf(i)
	        endif
	      endif
	    enddo
	  enddo
	else if(line.eq.'wide')then
	  do i=3,nwide
	    if(wflags(i).and.mask(i).ne.0)then
	      if(wfreq(i).lt.lo1)then
	        wdata(1) = wdata(1) + wwidth(i) * wdata(i)
	 	wt(1) = wt(1) + wwidth(i)
	      else
	        wdata(2) = wdata(2) + wwidth(i) * wdata(i)
		wt(2) = wt(2) + wwidth(i)
	      endif
	    endif
	  enddo
	endif
c
c  Average the new wdata and set wflags.
c
	do i=1,newide
	  if(wt(i).ne.0.)then
	    wdata(i) = wdata(i)/wt(i)
	    wflags(i) = .true.
	  else
	    wflags(i) = .false.
	  endif
	enddo
c
	call uvrdvri(lIn,'nwide',nwide,0)
	nwide = max(2,nwide)
	end
c********1*********2*********3*********4*********5*********6*********7*c
       subroutine pcenter(lIn,preamble,data,nchan,obsra,obsdec,line)
c********1*********2*********3*********4*********5*********6*********7*c
       implicit none
       integer lIn,nchan
       complex data(nchan)
       double precision preamble(5),obsra,obsdec
       character*4 line
c
c  Move to new phase center.
c
c  In:
c    lIn	Handle of input uv-data.
c    data	data
c    nchan	Number of input channel or wideband data.
c    line	'wide' or 'chan' data
c    preamble(5),obsra,obsdec
c  Out:
c    data,wdata
c    preamble(5),obsra,obsdec
c------------------------------------------------------------------------
       include 'maxdim.h'
       include 'mirconst.h'
       integer i,j,k,ant1,ant2,nants,nwide
       double precision sfreq(MAXWIN),sdf(MAXWIN),freq,u,v,w,lst
       double precision bxx,byy,bzz,antpos(3*MAXANT)
       integer nspect,ischan(MAXWIN),nschan(MAXWIN)
       real wfreq(MAXCHAN),phase,HA,sinha,cosha,sind,cosd
c
c  Externals.
c
       complex expi
c
c  Get the dimensioning info.
c
       if(line.eq.'chan')then
         call uvgetvri(lIn,'nspect',nspect,1)
	     if(nspect.le.0)
     *	    call bug('f','Bad value for uv-variable nspect')
         call uvgetvri(lIn,'ischan',ischan,nspect)
         call uvgetvri(lIn,'nschan',nschan,nspect)
         call uvgetvrd(lIn,'sdf',sdf,nspect)
         call uvgetvrd(lIn,'sfreq',sfreq,nspect)
       else if(line.eq.'wide')then
          call uvgetvri(lIn,'nwide',nwide,1)
          if(nwide.le.0)
     *      call bug('f','Bad value for uv-variable nwide')
          call uvgetvrr(lIn,'wfreq',wfreq,nwide)
c       else
c         call bug('f','Invalid line in subroutine radec1')
       endif
c
c calculate new u,v,w
c
      call uvgetvri(lIn,'nants',nants,1)
      call uvgetvrd(lIn,'antpos',antpos,3*nants)
      call uvgetvrd(lIn,'lst',lst,1)
      HA = lst - obsra
      sinha = sin(HA)
      cosha = cos(HA)
      sind = sin(obsdec)
      cosd = cos(obsdec)
      call basant( preamble(5), ant1, ant2)
      bxx = antpos(ant2)         - antpos(ant1)
      byy = antpos(ant2+nants)   - antpos(ant1+nants)
      bzz = antpos(ant2+2*nants) - antpos(ant1+2*nants)
        u =   bxx * sinha + byy * cosha
        v = -(bxx * cosha - byy * sinha)*sind + bzz*cosd
        w =  (bxx * cosha - byy * sinha)*cosd + bzz*sind
c
c  correct the phase to the new phase center.
c
	if(line.eq.'chan')then
	  k = 0
	  do i=1,nspect
	    do j=ischan(i),ischan(i)+nschan(i)-1
	      freq = sfreq(i) + sdf(i) * (j-ischan(i))
		  phase = - twopi * freq * (w-preamble(3))
		  phase = mod(phase,twopi)
	      k = k + 1
		  data(k) = data(k) * expi(phase)
	    enddo
	  enddo

	else if(line.eq.'wide')then
	  do i=1,nwide
	      freq = wfreq(i)
		  phase = - twopi * freq * (w-preamble(3))
		  phase = mod(phase,twopi)
		  data(i) = data(i) * expi(phase)
	  enddo
	endif
c
c update preamble
c
      preamble(1) = u
      preamble(2) = v
      preamble(3) = w
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine Contsub(lIn,data,flags,nchan,
     *						endchan,mask,sigma)
c
	implicit none
	integer lIn,nchan,endchan
	complex data(nchan)
	logical flags(nchan)
	real mask(nchan),sigma
c
c  Continuum subtraction using linear fit to spectra.
c
c  Input:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    endchan	Number of end channels to drop.
c    mask	Mask for bad channels.
c    sigma	Rms noise level used to flag data.
c  Input/Output:
c    data
c    flags
c------------------------------------------------------------------------
	include 'maxdim.h'
	double precision sdf(MAXWIN),sfreq(MAXWIN)
	real x(MAXCHAN),y(MAXCHAN),z(MAXCHAN),w(MAXCHAN),ay,az,by,bz
	integer nspect,ischan(MAXWIN),nschan(MAXWIN)
	real sumsq,wt,x1,y1,z1
	integer i,j,j1,j2,k
c
c  Get the dimensioning info.
c
	  call uvgetvri(lIn,'nspect',nspect,1)
	  if(nspect.le.0)
     *	    call bug('f','Bad value for uv-variable nspect')
	  call uvgetvri(lIn,'ischan',ischan,nspect)
	  call uvgetvri(lIn,'nschan',nschan,nspect)
	  call uvgetvrd(lIn,'sdf',sdf,nspect)
	  call uvgetvrd(lIn,'sfreq',sfreq,nspect)
c
c  Linear fit to real and imaginary part of each spectral window.
c
	k = 0
	do i=1,nspect
	  j1=ischan(i)+endchan
	  j2=ischan(i)+nschan(i)-1-endchan
	  do j=j1,j2
	    k = k + 1
	    x(k) = mask(j) * (sfreq(i) + sdf(i) * (j-ischan(i)))
	    y(k) = mask(j) * real(data(j))
	    z(k) = mask(j) * aimag(data(j))
	    w(k) = mask(j)
	  enddo
c
	  call linfit(x,y,w,k,ay,by)
	  call linfit(x,z,w,k,az,bz)
c
c  Subtract the linear fit from the data.
c
	  j1=ischan(i)
	  j2=ischan(i)+nschan(i)-1
	  do j=j1,j2
	    x1 = sfreq(i) + sdf(i) * (j-ischan(i))
	    y1 = real(data(j)) -  ay*x1 - by
	    z1 = aimag(data(j)) - az*x1 - bz
	    data(j) = cmplx(y1,z1)
	  enddo
	enddo
c
c  Flag data if channel rms after linear fit is .gt. sigma.
c
      if(sigma.gt.0.) then
	sumsq = 0.
	wt = 0.
	do i=1,nspect
	  j1=ischan(i)+endchan
	  j2=ischan(i)+nschan(i)-1-endchan
	  do j=j1,j2
	    sumsq = sumsq + mask(j) * real(data(j)) * real(data(j))
     *	 		  + mask(j) * aimag(data(j)) *aimag(data(j))
	    wt = wt + mask(j)
	  enddo
	enddo
c
	if(sumsq.gt.wt*sigma*sigma) then
	  do i=1,nchan
	    flags(i) = .false.
	  enddo
	endif
      endif
c
c  Return with the corrected data.
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine badinit(nbad,badchan,maxbad,mask,maxchan)
	implicit none
	integer nbad,maxbad,maxchan,badchan(maxbad)
	real mask(maxchan)
c
c  Make mask from list of bad channels.
c
c  Input:
c    nbad	Number of ranges of bad channels.
c    badchan	Ranges of bad channels.
c    maxbad	Dimension of badchan.
c    mask	Mask for bad channels.
c  Output:
c    maxchan	Dimension of mask.
c------------------------------------------------------------------------
	integer i,j
c
	do i=1,maxchan
	  mask(i) = 1.
	enddo
c
	if(nbad.gt.0)then
	  do i=1,2*nbad,2
	    do j=badchan(i),badchan(i+1)
	      mask(j) = 0.
	    enddo
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine linfit(x,y,w,n,a1,b1)
	implicit none
	integer n
	real x(n),y(n),w(n),a1,b1
c
c  Least squares fit to y = a1*x + b1
c
c  Input:
c    x		The x values
c    y		The y values
c    w		The weight array.
c    n		The number of points in the arrays.
c  Output:
c    a1, b1     coefficients of the relation y=a1*x+b1
c------------------------------------------------------------------------
      double precision sumx, sumy, sumw, sumsqx, sumsqy, sumxy
      integer i
c
      sumx   = 0.
      sumy   = 0.
      sumw   = 0.
      sumsqx = 0.
      sumsqy = 0.
      sumxy  = 0.
      do i = 1,n
	sumx   = sumx   + w(i) * x(i)
        sumy   = sumy   + w(i) * y(i)
        sumw   = sumw   + w(i)
        sumsqx = sumsqx + w(i) * x(i) * x(i)
        sumsqy = sumsqy + w(i) * y(i) * y(i)
        sumxy  = sumxy  + w(i) * x(i) * y(i)
      enddo
c
      if(sumw.eq.0..or.(sumx.eq.0. .and. sumsqx.eq.0.)) then
        a1   = 0.
        b1   = 0.
      else
        a1   = ( sumw*sumxy - sumx*sumy ) / ( sumw*sumsqx - sumx**2 )
        b1   = ( sumy - a1*sumx ) / sumw
      endif
c
      end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine parang1(lIn,Pol,data,nchan)
	implicit none
	integer lIn,Pol,nchan
	complex data(nchan)
c
c Multiply LR by expi(2*chi) and RL by expi(-2*chi)
c
c  In:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c  In/out:
c    data	Channel or wideband data
c------------------------------------------------------------------------
	real chi
	integer PolRL,PolLR,i
	parameter (PolRL=-3,PolLR=-4)
c
c  Externals.
c
	complex expi
c
	if(Pol.eq.PolRL)then
          call uvrdvrr (lIn, 'chi', chi, 0.)
	  do i=1,nchan
	    data(i) = data(i)*expi(-2*chi)
	  enddo
	else if(Pol.eq.PolLR)then
          call uvrdvrr (lIn, 'chi', chi, 0.)
	  do i=1,nchan
	    data(i) = data(i)*expi(2*chi)
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine model1(lIn,preamble,data,nchan,model)
	implicit none
	integer lIn,nchan
	complex data(nchan)
	real model(3)
        double precision preamble(5)
c
c Subtract the source model from the uv-data.
c
c  In:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    model	source model
c    preamble
c  In/out:
c    data	Channel or wideband data
c------------------------------------------------------------------------
	complex modvis
	integer i
c
c  Get model visibility.
c
	modvis = model(1) * (sqrt(preamble(1)**2 + preamble(2)**2) /
     *		model(2)) ** model(3)
	do i=1,nchan
	  data(i) = data(i) - modvis 
	enddo
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine fxcal(lIn,baseline,data,flags,nchan)
	implicit none
	integer lIn,nchan
	complex data(nchan)
	double precision baseline
	logical flags(nchan)
c
c   Calibrate the FX correlator data
c   by dividing the cross correlations by the geometric mean
c   of the autocorrelations.
c
c  In:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    baseline
c  In/out:
c    data	Channel or wideband data
c------------------------------------------------------------------------
	include 'maxdim.h'
	real auto(4,1024),sq
c	real auto(MAXANT2,MAXCHAN),sq
	save auto

	integer ant1,ant2,k

	call basant(baseline,ant1,ant2)

	if(ant1.eq.ant2) then
	  do k=1,nchan
	    auto(ant1,k) = data(k)
	  enddo
	else
	  sq =  auto(ant1,3)*auto(ant2,3)
	  do k=1,nchan
	    sq =  auto(ant1,k)*auto(ant2,k)
	    if(sq.gt.0. and.flags(k)) then
			 data(k) = data(k)/sqrt(sq)
	    else
			 data(k) = cmplx(0.,0.)
		endif
	  enddo
	endif

	end
c********1*********2*********3*********4*********5*********6*********7*c
	subroutine polcal1(lIn,Pol,data,nchan,polcal)
	implicit none
	integer lIn,Pol,nchan
	complex data(nchan)
	real polcal(2)
c
c Subtract the source polarization from the uv-data.
c
c  In:
c    lIn	Handle of input uv-data.
c    nchan	Number of channels.
c    polcal	source polarization
c  In/out:
c    data	Channel or wideband data
c------------------------------------------------------------------------
	real chi
	integer PolRL,PolLR,i
	parameter (PolRL=-3,PolLR=-4)
	complex polcor
c
c  Externals.
c
	complex expi
c
c  Get polarization correction.
c
	if(Pol.eq.PolLR)then
          call uvrdvrr (lIn, 'chi', chi, 0.)
	  polcor = polcal(1) * expi(polcal(2)) * expi(-2*chi)
	  do i=1,nchan
	    data(i) = data(i) - polcor
	  enddo
	else if(Pol.eq.PolRL)then
          call uvrdvrr (lIn, 'chi', chi, 0.)
	  polcor = polcal(1) * expi(-polcal(2)) * expi(2*chi)
	  do i=1,nchan
	    data(i) = data(i) - polcor
	  enddo
	endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
