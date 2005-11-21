c************************************************************************
	program smaflux
	implicit none
c
c= SmaFlux -- Set the flux scale of a vis dataset given a planet obs.
c& jhz 
c: calibration
c+
c	SmaFlux is a MIRIAD program which corrects the flux density scale 
c       in visibility datasets. In doing this, it assumes that the flux
c	density scale is out by a constant factor. SmaFlux looks for 
c       observations of planets, and given its model of the planetary 
c       visibility function, it computes the factor needed to correct 
c       the flux density scale of the data set. The values of the Planck 
c       whole disk brightness temperature from the SMA planetary model 
c       (http://sma1.sma.hawaii.edu/planetvis.html) are adopted for
c       brightness temperature of a planet or a moon which is included
c       in the following list:
c       Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto,
c       Ganymede, Callisto, Titan, Ceres, Pallas, Vesta.
c  
c	To fix the flux density scale, SmaFlux creates or modifies calibration 
c       tables attached to each dataset.
c       To run this program, the data directory for the SMA planetary
c       model needs to be installed by excuting the following script:
c       cd $MIR/install
c       get_smaplmodel
c@ vis
c	Input visibility datasets. Several datasets can be given (wildcards
c	are supported). The datasets should include observations of a planet.
c@ select
c	Normal uv-selection parameter. This selects the data in the input
c	datasets to analyse. See the help on ``select'' for more information.
c	smaflux will use any data that has a source name which it recognises
c	as a planet. You may wish to select just the shortest spacing, where
c	the planet is strongest.
c@ mirhome
c       location of MIRIAD's home directory; 
c       mirlocal=$MIR; no defaults.
c@ options
c	Extra processing options. Several can be given, separated by commas.
c	  vector  Use the real part (rather than amplitude) of the data and
c	          model. This option should be used if the visibility data 
c                 are phase calibrated.
c	  noapply Do not apply the scale factor (just evaluate it).
c         nofqav  When dealing with amplitude data, SMAFLUX normally
c                 averaging in frequency first, to avoid noise
c	          biases. The nofqav disables this averaging.
c--
c  History:
c    jhz  2005-10-20   The original version  based on rjs' plboot.for's
c                      version 1.0 19-May-03 
c    jhz  2005-10-27   Following the suggetion from Peter Teuben, the data
c                      directory is replaced to $MIRCAT/smaplmdl
c    jhz  2005-11-21   Replace comment "Found planet" with
c                                      "Found solar system object"
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='SmaFlux: version 1.0 27-Oct-05')
	integer MAXVIS
	parameter(MAXVIS=32)
c
	character vis(MAXVIS)*64,source*32,line*64
        character mirhome*80
	logical vector,planet,noapply,nofqav
	integer nvis,lVis,vsource,nchan,iplanet,nants,i,iplanetp
	real fac
	double precision SumXX,SumXY,preamble(4),time
	double precision sfreq(MAXCHAN)
	complex data(MAXCHAN)
	logical flags(MAXCHAN),domsg
c
c  Externals.
c
	logical uvDatOpn,uvVarUpd,hdPrsnt
c	integer plLook
        integer smaplLook, len1
	character streal*16
        character smadir*82
        common/smadata/smadir
        domsg = .true.
c
c  Get the user input.
c
	call output(version)
	call keyini
	call uvDatInp('vis','xcefd')
	call uvDatSet('stokes',0)
        call keya('mirhome',mirhome,' ')
        if(mirhome(1:1).eq.' ') 
     *  call bug('f', 'The home directory of Miriad must be given.')
        smadir=mirhome(1:len1(mirhome))//'/cat/smaplmdl/'
	call getopt(vector,noapply,nofqav)
	call keyfin
c
c  Process the data.
c
	iplanetp = 0
	SumXX = 0
	SumXY = 0
	nvis = 0
	dowhile(uvDatOpn(lVis))
	  nvis = nvis + 1
	  if(nvis.gt.MAXVIS)call bug('f','Too many inputs for me!')
	  call uvDatGta('name',vis(nvis))
	  call uvVarIni(lVis,vsource)
	  call uvVarSet(vsource,'source')
	  call uvDatRd(preamble,data,flags,MAXCHAN,nchan)
	  planet = .false.
	  dowhile(nchan.gt.0)
	    if(uvVarUpd(vsource))then
	      call uvrdvra(lVis,'source',source,' ')
c             iplanet = plLook(source)
c            
c test sma codes for Tb and physical properties:
c                source='Mercury'
c                source='Venus'
c                source='Mars'
c                source='Jupiter'
c                source='Saturn'
c                source='Uranus'
c                source='Neptune'
c                source='Pluto'
c                source='Ganymede'
c                source='Callisto'
c                source='Titan' 
c                source='Ceres'
c                source='Pallas'
c                source='Vesta'
c using sma planet id lookup
              iplanet = SmaplLook(source)
c	      planet = iplanet.ge.1.and.iplanet.le.9.and.iplanet.ne.3
              planet = iplanet.ge.1.and.iplanet.le.16.and.iplanet.ne.3
	      if(planet.and.iplanet.ne.iplanetp)
     *		call output('Found solar system objects: '//source)
	      iplanetp = iplanet
	    endif
	    if(planet)then
	      call uvinfo(lVis,'sfreq',sfreq)
	      call Acc(nofqav,vector,preamble,preamble(3),iplanet,
     *	     data,flags,sfreq,nchan,SumXX,SumXY,domsg)
             domsg=.false.
	    endif
	    call uvDatRd(preamble,data,flags,MAXCHAN,nchan)
	  enddo
	  call uvDatCls
	enddo
c
	if(SumXX.le.0)call bug('f','No good data found')
	if(SumXY.le.0)call bug('f','Problem seems ill-conditioned')
	fac = SumXX/SumXY
	line = 'Scaling the data by '//streal(fac,'(f13.3)')
	call output(line)
	fac = sqrt(fac)
c
c  Now apply the scale factor to all the input datasets.
c
	if(.not.noapply)then
	  do i=1,nvis
	    call uvopen(lVis,vis(i),'old')
	    if(hdPrsnt(lVis,'gains'))then
	      call gainSca(lVis,fac)
	    else
	      call uvscan(lVis,'baseline')
	      call uvrdvrd(lVis,'time',time,0.d0)
	      call uvrdvri(lVis,'nants',nants,0)
	      call gainWri(lVis,fac,time,nants)
	    endif
	    call hisopen(lVis,'append')
	    call hiswrite(lVis,'SMAFLUX: Miriad '//version)
	    call hisinput(lVis,'SMAFLUX')
	    call hiswrite(lVis,'SMAFLUX: '//line)
	    call hisclose(lVis)
	    call uvclose(lVis)
	  enddo
	endif
c
	end
c************************************************************************
	subroutine Acc(nofqav,vector,uv,time,iplanet,
     *		data,flags,sfreq,nchan,SumXX,SumXY,domsg)
c
	implicit none
	logical vector,nofqav
	integer nchan,iplanet
	complex data(nchan)
	logical flags(nchan),domsg
	double precision uv(2),time,sfreq(nchan),SumXX,SumXY
c
c  Accumulate info given the planetary data.
c------------------------------------------------------------------------
        include 'mirconst.h'
        integer i,n
        real a,b,cospa,sinpa,pltb,bmaj,bmin,bpa,model
	real avmodel
	complex avdata
        double precision sub(3),dist
c
c  Externals.
c
        real j1xbyx
c       real pltbs
        real smapltbs
        double precision deltime
c
        if(iplanet.lt.9) 
     *   call plpar(time+deltime(time,'tdb'),iplanet,sub,
     *          dist,bmaj,bmin,bpa)
c
c for small planets and moons, the physical prameters and ephemeris
c used in SMA planets model is used.
c
        if(iplanet.ge.9) 
     *   call smaplpar(time+deltime(time,'tdb'),
     *         iplanet,bmaj,bmin,bpa,domsg)
c
c        pltb = pltbs(iplanet,real(sfreq(1)))
c
c        Calculate Tb using Plank whole disk brightness temperature
c        based on SMA planets model.
c
         pltb = smapltbs(iplanet,real(sfreq(1)),
     *   real(time+deltime(time,'tdb')-2400000.5),domsg)
        cospa = cos(bpa)
        sinpa = sin(bpa)
        b = PI * sqrt((bmaj*(uv(1)*cospa-uv(2)*sinpa))**2
     *              + (bmin*(uv(1)*sinpa+uv(2)*cospa))**2)
        a = 2 * pltb * (KMKS*1e18)/(CMKS*CMKS*1e-26)
     *    * 2 * PI/4 * bmaj*bmin
c
	if(nofqav)then
          do i=1,nchan
	    if(flags(i))then
	      model = a*sfreq(i)*sfreq(i)*j1xbyx(real(b*sfreq(i)))
	      SumXX = SumXX + model*model
	      if(vector)then
	        SumXY = SumXY + model*data(i)
	      else
	        SumXY = SumXY + abs(model*data(i))
	      endif
	    endif
          enddo
	else
	  avdata = (0.,0.)
	  avmodel = 0
	  n = 0
	  do i=1,nchan
	    if(flags(i))then
	      avdata = avdata + data(i)
	      avmodel = avmodel + 
     *		a*sfreq(i)*sfreq(i)*j1xbyx(real(b*sfreq(i)))
	      n = n + 1
	    endif
	  enddo
	  if(n.gt.0)then
	    SumXX = SumXX + avmodel*avmodel/n
	    SumXY = SumXY + abs(avmodel*avdata/n)
	  endif
	endif
c
        end
c************************************************************************
	subroutine getopt(vector,noapply,nofqav)
c
	implicit none
	logical vector,noapply,nofqav
c
c  Get extra processing parameters.
c------------------------------------------------------------------------
	integer NOPTS
	parameter(NOPTS=3)
	logical present(NOPTS)
	character opts(NOPTS)*8
	data opts/'vector  ','noapply ','nofqav  '/
c
	call options('options',opts,present,NOPTS)
	vector =  present(1)
	noapply = present(2)
	nofqav =  present(3).or.vector
	end
c************************************************************************
	subroutine gainSca(lVis,fac)
c
	implicit none
	integer lVis
	real fac
c
c  Scale the gains table present in the data.
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	complex Gains(3*MAXANT)
	real scale(3*MAXANT)
	integer item,iostat,nfeeds,ntau,nsols,ngains,offset,i,j
c
c  Externals.
c
	integer hsize
c
	call haccess(lVis,item,'gains','append',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening to modify gains item')
	  call bugno('f',iostat)
	endif
	call rdhdi(lVis,'nfeeds',nfeeds,1)
	call rdhdi(lVis,'ntau',ntau,0)
	call rdhdi(lVis,'ngains',ngains,0)
	if(mod(ngains,nfeeds+ntau).ne.0)
     *	  call bug('f','Bad number of gains or feeds in table')
	nsols = hsize(item)
	if(mod(nsols-8,8*ngains+8).ne.0)
     *	  call bug('f','Size of gain table looks wrong')
	nsols = (nsols-8)/(8*ngains+8)
c
	if(ngains.gt.3*MAXANT)call bug('f','Too many gains for me!')
	do i=1,ngains,nfeeds+ntau
	  scale(i) = fac
	  if(nfeeds.eq.2)scale(i+1) = fac
	  if(ntau.eq.1)scale(i+nfeeds) = 1
	enddo
c
c  Now correct the data.
c
	offset = 16
	do i=1,nsols
	  call hreadr(item,gains,offset,8*ngains,iostat)
	  if(iostat.ne.0)call bugno('f',iostat)
	  do j=1,ngains
	    gains(j) = scale(j)*gains(j)
	  enddo
	  call hwriter(item,gains,offset,8*ngains,iostat)
	  if(iostat.ne.0)call bugno('f',iostat)
	  offset = offset + 8 + 8*ngains
	enddo
c
	call hdaccess(item,iostat)
	end
c************************************************************************
	subroutine gainWri(lVis,fac,time,nants)
c
	implicit none
	real fac
	double precision time
	integer nants,lVis
c
c------------------------------------------------------------------------
	include 'maxdim.h'
	complex gains(MAXANT)
	integer header(2),i,item,iostat
c
	do i=1,nants
	  gains(i) = fac
	enddo
c
c  Create the gains table.
c
	call wrhdd(lVis,'interval',2.d0)
	call wrhdi(lVis,'ngains',nants)
	call wrhdi(lVis,'nsols',1)
	call wrhdi(lVis,'ntau',0)
	call wrhdi(lVis,'nfeeds',1)
	call haccess(lVis,item,'gains','write',iostat)
	if(iostat.ne.0)then
	  call bug('w','Error opening output gains item')
	  call bugno('f',iostat)
	endif
c
	header(1) = 0
	header(2) = 0
	call hwritei(item,header,0,8,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
	call hwrited(item,time,8,8,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
	call hwriter(item,gains,16,8*nants,iostat)
	if(iostat.ne.0)call bugno('f',iostat)
	call hdaccess(item,iostat)
	end

c************************************************************************
        integer function smaplLook(source)
c
        implicit none
        character source*(*)
c
c  Identify a planet.
c
c------------------------------------------------------------------------
        character source1*8
        integer ip
c
        integer NPLANETS
        parameter(NPLANETS=16)
        character planets(NPLANETS)*8
        integer np(NPLANETS),len1
c
c  Externals.
        integer binsrcha
c add sma iplanet mapping
        data planets 
     * /   'callisto','ceres   ','earth   ','ganymede',
     *     'io      ','jupiter ','mars    ','mercury ',
     *     'neptune ','pallas  ','pluto   ','saturn  ',
     *     'titan   ','uranus  ','venus   ','vesta   ' /
        data np     
     * /    11,       12,        3,        10,       
     *      13,        5,        4,         1,        
     *       8,       14,        9,         6,        
     *      16,        7,        2,        15 /

        source1 = source(1:len1(source))
        call lcase(source1)
        ip = binsrcha(source1,planets,NPLANETS)
        if(ip.gt.0)ip = np(ip)
        SmaplLook = ip
        end

        real function smapltbs(iplanet,freq,mjd,domsg)
        integer iplanet
        real freq, mjd
        logical domsg
c
c  Return Planck whole disk brightness temperature
c  at a given time and given a frequency based on the
c  SMA planets model.
c
c  Input:
c    iplanet         Planet number. (SMA name-id mapping)
c    frequency       Observing Frequency (GHz)
c    mjd             Modified Julian date
c  Output:
c    smapltbs        Planck whole disk brightness temperature
c                    of a given planet (Kelvin)
c------------------------------------------------------------------------
        character planet*32
        real wdbt
        integer ip
        integer NPLANETS
        parameter(NPLANETS=16)
        character planets(NPLANETS)*8
        integer np(NPLANETS)
c add sma iplanet mapping
        data planets /'callisto','ceres   ','earth   ',
     *     'ganymede','io      ','jupiter ','mars    ',
     *     'mercury ','neptune ','pallas  ','pluto   ',
     *     'saturn  ','titan   ','uranus  ','venus   ',
     *     'vesta   '/
        data np     / 11,       12,        3,
     *      10,       13,        5,        4,
     *       1,        8,       14,        9,
     *       6,       16,        7,        2,       
     *      15/
c
c  Externals.
c       integer binsrcha
        real marstb, plmodel

        wdbt=0.0
        ip=1
        do while(iplanet.ne.np(ip))
        ip=ip+1
        end do 
        planet=planets(ip)
c----------------------------------------------------------------------
c     if the planet choice is Mars, read in the time-dependent whole-
c     disk Planck brightness temperature calculated from the Caltech
c     Mars Thermal Model (the 'Rudy' model) and interpolate to the
c     input time and frequency.
c----------------------------------------------------------------------
              if(planet.eq.'mars')then
          wdbt = marstb(freq,mjd)
        else if ((iplanet.gt.8.and.iplanet.ne.16).or.iplanet.eq.1) then
c----------------------------------------------------------------------
c     If the planet is on the first list (ip ge 7) then
c     Just use a simple model temperature and falloff for each:
c     NOTE: These are all very approximate, and better values will
c     be obtained soon!
c     UPDATE: 27 May 2003...new Titan model in use.
c----------------------------------------------------------------------
         if(iplanet.eq.1)then        !Mercury
            wdbt=500.
            cosexp=0.3
         else if(iplanet.eq.10)then   !Ganymede
            wdbt=100.           !Changed from 85 K on 27 May 2003
            cosexp=0.1
         else if(iplanet.eq.11)then   !Callisto
            wdbt=120.           !Changed from 100 K on 27 May 2003
            cosexp=0.1
         else if(iplanet.eq.12)then  !Ceres
            wdbt=175.
            cosexp=0.1
         else if(iplanet.eq.9)then  !Pluto
            wdbt=40.
            cosexp=0.1
         else if(iplanet.eq.15)then  !Vesta
            wdbt=175.
            cosexp=0.1
         else if(iplanet.eq.14)then  !Pallas
            wdbt=175.
            cosexp=0.1
         else if(iplanet.eq.13)then  !Io
            wdbt=100.
            cosexp=0.1
         endif
      else
c----------------------------------------------------------------------
c     If planet choice is otherwise, read in the frequency dependent
c     whole-disk Planck brightness temperature 
c     calculated from the JOVIAN model for the appropriate
c     planet, and interpolate to the input frequency.
c----------------------------------------------------------------------
       
        wdbt=plmodel(planet,freq)
        end if
         smapltbs=wdbt
        if(domsg) then
        write(*,*) 'Frequency(GHz)   Tb(Kelvin)'
        write(*,123) freq,smapltbs
123     format(2x, f8.3,9x,f7.2) 
        end if
        return
        end

        real function plmodel(planet,freq)
        implicit none
        character planet*8
        real freq
c
c  Return the brightness temperature of a planet.
c
c  Inputs:
c    planet   Planet name.
c    freq     Observing frequency, in GHz.
c  Output:
c    plmodel    Brightness temperature, in Kelvin.
        integer NVEN
        parameter(NVEN=990)
        real Ven(2,NVEN)
c
        integer NJUP
        parameter(NJUP=990)
        real Jup(2,NJUP)
c
        integer NSAT
        parameter(NSAT=990)
        real Sat(2,NSAT)
c
        integer NURA
        parameter(NURA=990)
        real Ura(2,NURA)
c
        integer NNEP
        parameter(NNEP=990)
        real Nep(2,NNEP)
c
        integer NTIT
        parameter(NTIT=990)
        real Tit(2,NTIT)
c external
         real pltbintp
        save Jup,Ven,Sat,Ura,Nep,Tit
c
c SMA model http://sma1.sma.hawaii.edu/planetvis.html
c version 2005 Sept 22
c Venus Spectrum - Mark Gurwell's planet model'
c CO2 absorption factor of 2 used
c              whole disk brightness temp
c                           Freq(GHz)              WDTB(K)     
          data  Ven(1,   1)/  11.000/, Ven(2,   1)/ 585.527/
          data  Ven(1,   2)/  12.000/, Ven(2,   2)/ 572.680/
          data  Ven(1,   3)/  13.000/, Ven(2,   3)/ 560.833/
          data  Ven(1,   4)/  14.000/, Ven(2,   4)/ 549.932/
          data  Ven(1,   5)/  15.000/, Ven(2,   5)/ 539.900/
          data  Ven(1,   6)/  16.000/, Ven(2,   6)/ 530.650/
          data  Ven(1,   7)/  17.000/, Ven(2,   7)/ 522.099/
          data  Ven(1,   8)/  18.000/, Ven(2,   8)/ 514.175/
          data  Ven(1,   9)/  19.000/, Ven(2,   9)/ 506.807/
          data  Ven(1,  10)/  20.000/, Ven(2,  10)/ 499.940/
          data  Ven(1,  11)/  21.000/, Ven(2,  11)/ 493.520/
          data  Ven(1,  12)/  22.000/, Ven(2,  12)/ 487.504/
          data  Ven(1,  13)/  23.000/, Ven(2,  13)/ 481.853/
          data  Ven(1,  14)/  24.000/, Ven(2,  14)/ 476.533/
          data  Ven(1,  15)/  25.000/, Ven(2,  15)/ 471.517/
          data  Ven(1,  16)/  26.000/, Ven(2,  16)/ 466.777/
          data  Ven(1,  17)/  27.000/, Ven(2,  17)/ 462.290/
          data  Ven(1,  18)/  28.000/, Ven(2,  18)/ 458.037/
          data  Ven(1,  19)/  29.000/, Ven(2,  19)/ 454.001/
          data  Ven(1,  20)/  30.000/, Ven(2,  20)/ 450.160/
          data  Ven(1,  21)/  31.000/, Ven(2,  21)/ 446.503/
          data  Ven(1,  22)/  32.000/, Ven(2,  22)/ 443.017/
          data  Ven(1,  23)/  33.000/, Ven(2,  23)/ 439.689/
          data  Ven(1,  24)/  34.000/, Ven(2,  24)/ 436.506/
          data  Ven(1,  25)/  35.000/, Ven(2,  25)/ 433.461/
          data  Ven(1,  26)/  36.000/, Ven(2,  26)/ 430.542/
          data  Ven(1,  27)/  37.000/, Ven(2,  27)/ 427.742/
          data  Ven(1,  28)/  38.000/, Ven(2,  28)/ 425.053/
          data  Ven(1,  29)/  39.000/, Ven(2,  29)/ 422.468/
          data  Ven(1,  30)/  40.000/, Ven(2,  30)/ 419.980/
          data  Ven(1,  31)/  41.000/, Ven(2,  31)/ 417.583/
          data  Ven(1,  32)/  42.000/, Ven(2,  32)/ 415.273/
          data  Ven(1,  33)/  43.000/, Ven(2,  33)/ 413.041/
          data  Ven(1,  34)/  44.000/, Ven(2,  34)/ 410.886/
          data  Ven(1,  35)/  45.000/, Ven(2,  35)/ 408.802/
          data  Ven(1,  36)/  46.000/, Ven(2,  36)/ 406.785/
          data  Ven(1,  37)/  47.000/, Ven(2,  37)/ 404.832/
          data  Ven(1,  38)/  48.000/, Ven(2,  38)/ 402.938/
          data  Ven(1,  39)/  49.000/, Ven(2,  39)/ 401.101/
          data  Ven(1,  40)/  50.000/, Ven(2,  40)/ 399.318/
          data  Ven(1,  41)/  51.000/, Ven(2,  41)/ 397.585/
          data  Ven(1,  42)/  52.000/, Ven(2,  42)/ 395.900/
          data  Ven(1,  43)/  53.000/, Ven(2,  43)/ 394.261/
          data  Ven(1,  44)/  54.000/, Ven(2,  44)/ 392.665/
          data  Ven(1,  45)/  55.000/, Ven(2,  45)/ 391.111/
          data  Ven(1,  46)/  56.000/, Ven(2,  46)/ 389.595/
          data  Ven(1,  47)/  57.000/, Ven(2,  47)/ 388.117/
          data  Ven(1,  48)/  58.000/, Ven(2,  48)/ 386.674/
          data  Ven(1,  49)/  59.000/, Ven(2,  49)/ 385.265/
          data  Ven(1,  50)/  60.000/, Ven(2,  50)/ 383.888/
          data  Ven(1,  51)/  61.000/, Ven(2,  51)/ 382.542/
          data  Ven(1,  52)/  62.000/, Ven(2,  52)/ 381.226/
          data  Ven(1,  53)/  63.000/, Ven(2,  53)/ 379.938/
          data  Ven(1,  54)/  64.000/, Ven(2,  54)/ 378.679/
          data  Ven(1,  55)/  65.000/, Ven(2,  55)/ 377.443/
          data  Ven(1,  56)/  66.000/, Ven(2,  56)/ 376.234/
          data  Ven(1,  57)/  67.000/, Ven(2,  57)/ 375.047/
          data  Ven(1,  58)/  68.000/, Ven(2,  58)/ 373.883/
          data  Ven(1,  59)/  69.000/, Ven(2,  59)/ 372.741/
          data  Ven(1,  60)/  70.000/, Ven(2,  60)/ 371.621/
          data  Ven(1,  61)/  71.000/, Ven(2,  61)/ 370.522/
          data  Ven(1,  62)/  72.000/, Ven(2,  62)/ 369.441/
          data  Ven(1,  63)/  73.000/, Ven(2,  63)/ 368.377/
          data  Ven(1,  64)/  74.000/, Ven(2,  64)/ 367.334/
          data  Ven(1,  65)/  75.000/, Ven(2,  65)/ 366.308/
          data  Ven(1,  66)/  76.000/, Ven(2,  66)/ 365.302/
          data  Ven(1,  67)/  77.000/, Ven(2,  67)/ 364.307/
          data  Ven(1,  68)/  78.000/, Ven(2,  68)/ 363.332/
          data  Ven(1,  69)/  79.000/, Ven(2,  69)/ 362.370/
          data  Ven(1,  70)/  80.000/, Ven(2,  70)/ 361.425/
          data  Ven(1,  71)/  81.000/, Ven(2,  71)/ 360.493/
          data  Ven(1,  72)/  82.000/, Ven(2,  72)/ 359.574/
          data  Ven(1,  73)/  83.000/, Ven(2,  73)/ 358.672/
          data  Ven(1,  74)/  84.000/, Ven(2,  74)/ 357.780/
          data  Ven(1,  75)/  85.000/, Ven(2,  75)/ 356.901/
          data  Ven(1,  76)/  86.000/, Ven(2,  76)/ 356.036/
          data  Ven(1,  77)/  87.000/, Ven(2,  77)/ 355.181/
          data  Ven(1,  78)/  88.000/, Ven(2,  78)/ 354.339/
          data  Ven(1,  79)/  89.000/, Ven(2,  79)/ 353.509/
          data  Ven(1,  80)/  90.000/, Ven(2,  80)/ 352.688/
          data  Ven(1,  81)/  91.000/, Ven(2,  81)/ 351.880/
          data  Ven(1,  82)/  92.000/, Ven(2,  82)/ 351.082/
          data  Ven(1,  83)/  93.000/, Ven(2,  83)/ 350.293/
          data  Ven(1,  84)/  94.000/, Ven(2,  84)/ 349.515/
          data  Ven(1,  85)/  95.000/, Ven(2,  85)/ 348.748/
          data  Ven(1,  86)/  96.000/, Ven(2,  86)/ 347.989/
          data  Ven(1,  87)/  97.000/, Ven(2,  87)/ 347.239/
          data  Ven(1,  88)/  98.000/, Ven(2,  88)/ 346.500/
          data  Ven(1,  89)/  99.000/, Ven(2,  89)/ 345.768/
          data  Ven(1,  90)/ 100.000/, Ven(2,  90)/ 345.045/
          data  Ven(1,  91)/ 101.000/, Ven(2,  91)/ 344.331/
          data  Ven(1,  92)/ 102.000/, Ven(2,  92)/ 343.625/
          data  Ven(1,  93)/ 103.000/, Ven(2,  93)/ 342.928/
          data  Ven(1,  94)/ 104.000/, Ven(2,  94)/ 342.239/
          data  Ven(1,  95)/ 105.000/, Ven(2,  95)/ 341.557/
          data  Ven(1,  96)/ 106.000/, Ven(2,  96)/ 340.884/
          data  Ven(1,  97)/ 107.000/, Ven(2,  97)/ 340.216/
          data  Ven(1,  98)/ 108.000/, Ven(2,  98)/ 339.558/
          data  Ven(1,  99)/ 109.000/, Ven(2,  99)/ 338.907/
          data  Ven(1, 100)/ 110.000/, Ven(2, 100)/ 338.262/
          data  Ven(1, 101)/ 111.000/, Ven(2, 101)/ 337.624/
          data  Ven(1, 102)/ 112.000/, Ven(2, 102)/ 336.993/
          data  Ven(1, 103)/ 113.000/, Ven(2, 103)/ 336.369/
          data  Ven(1, 104)/ 114.000/, Ven(2, 104)/ 335.752/
          data  Ven(1, 105)/ 115.000/, Ven(2, 105)/ 335.141/
          data  Ven(1, 106)/ 116.000/, Ven(2, 106)/ 334.537/
          data  Ven(1, 107)/ 117.000/, Ven(2, 107)/ 333.939/
          data  Ven(1, 108)/ 118.000/, Ven(2, 108)/ 333.347/
          data  Ven(1, 109)/ 119.000/, Ven(2, 109)/ 332.761/
          data  Ven(1, 110)/ 120.000/, Ven(2, 110)/ 332.181/
          data  Ven(1, 111)/ 121.000/, Ven(2, 111)/ 331.607/
          data  Ven(1, 112)/ 122.000/, Ven(2, 112)/ 331.039/
          data  Ven(1, 113)/ 123.000/, Ven(2, 113)/ 330.477/
          data  Ven(1, 114)/ 124.000/, Ven(2, 114)/ 329.920/
          data  Ven(1, 115)/ 125.000/, Ven(2, 115)/ 329.369/
          data  Ven(1, 116)/ 126.000/, Ven(2, 116)/ 328.823/
          data  Ven(1, 117)/ 127.000/, Ven(2, 117)/ 328.283/
          data  Ven(1, 118)/ 128.000/, Ven(2, 118)/ 327.748/
          data  Ven(1, 119)/ 129.000/, Ven(2, 119)/ 327.218/
          data  Ven(1, 120)/ 130.000/, Ven(2, 120)/ 326.694/
          data  Ven(1, 121)/ 131.000/, Ven(2, 121)/ 326.174/
          data  Ven(1, 122)/ 132.000/, Ven(2, 122)/ 325.659/
          data  Ven(1, 123)/ 133.000/, Ven(2, 123)/ 325.149/
          data  Ven(1, 124)/ 134.000/, Ven(2, 124)/ 324.645/
          data  Ven(1, 125)/ 135.000/, Ven(2, 125)/ 324.145/
          data  Ven(1, 126)/ 136.000/, Ven(2, 126)/ 323.650/
          data  Ven(1, 127)/ 137.000/, Ven(2, 127)/ 323.160/
          data  Ven(1, 128)/ 138.000/, Ven(2, 128)/ 322.674/
          data  Ven(1, 129)/ 139.000/, Ven(2, 129)/ 322.193/
          data  Ven(1, 130)/ 140.000/, Ven(2, 130)/ 321.716/
          data  Ven(1, 131)/ 141.000/, Ven(2, 131)/ 321.244/
          data  Ven(1, 132)/ 142.000/, Ven(2, 132)/ 320.776/
          data  Ven(1, 133)/ 143.000/, Ven(2, 133)/ 320.313/
          data  Ven(1, 134)/ 144.000/, Ven(2, 134)/ 319.854/
          data  Ven(1, 135)/ 145.000/, Ven(2, 135)/ 319.399/
          data  Ven(1, 136)/ 146.000/, Ven(2, 136)/ 318.948/
          data  Ven(1, 137)/ 147.000/, Ven(2, 137)/ 318.502/
          data  Ven(1, 138)/ 148.000/, Ven(2, 138)/ 318.060/
          data  Ven(1, 139)/ 149.000/, Ven(2, 139)/ 317.621/
          data  Ven(1, 140)/ 150.000/, Ven(2, 140)/ 317.187/
          data  Ven(1, 141)/ 151.000/, Ven(2, 141)/ 316.756/
          data  Ven(1, 142)/ 152.000/, Ven(2, 142)/ 316.330/
          data  Ven(1, 143)/ 153.000/, Ven(2, 143)/ 315.908/
          data  Ven(1, 144)/ 154.000/, Ven(2, 144)/ 315.489/
          data  Ven(1, 145)/ 155.000/, Ven(2, 145)/ 315.074/
          data  Ven(1, 146)/ 156.000/, Ven(2, 146)/ 314.663/
          data  Ven(1, 147)/ 157.000/, Ven(2, 147)/ 314.255/
          data  Ven(1, 148)/ 158.000/, Ven(2, 148)/ 313.851/
          data  Ven(1, 149)/ 159.000/, Ven(2, 149)/ 313.452/
          data  Ven(1, 150)/ 160.000/, Ven(2, 150)/ 313.055/
          data  Ven(1, 151)/ 161.000/, Ven(2, 151)/ 312.662/
          data  Ven(1, 152)/ 162.000/, Ven(2, 152)/ 312.272/
          data  Ven(1, 153)/ 163.000/, Ven(2, 153)/ 311.886/
          data  Ven(1, 154)/ 164.000/, Ven(2, 154)/ 311.504/
          data  Ven(1, 155)/ 165.000/, Ven(2, 155)/ 311.125/
          data  Ven(1, 156)/ 166.000/, Ven(2, 156)/ 310.749/
          data  Ven(1, 157)/ 167.000/, Ven(2, 157)/ 310.377/
          data  Ven(1, 158)/ 168.000/, Ven(2, 158)/ 310.008/
          data  Ven(1, 159)/ 169.000/, Ven(2, 159)/ 309.642/
          data  Ven(1, 160)/ 170.000/, Ven(2, 160)/ 309.279/
          data  Ven(1, 161)/ 171.000/, Ven(2, 161)/ 308.920/
          data  Ven(1, 162)/ 172.000/, Ven(2, 162)/ 308.563/
          data  Ven(1, 163)/ 173.000/, Ven(2, 163)/ 308.210/
          data  Ven(1, 164)/ 174.000/, Ven(2, 164)/ 307.860/
          data  Ven(1, 165)/ 175.000/, Ven(2, 165)/ 307.513/
          data  Ven(1, 166)/ 176.000/, Ven(2, 166)/ 307.169/
          data  Ven(1, 167)/ 177.000/, Ven(2, 167)/ 306.828/
          data  Ven(1, 168)/ 178.000/, Ven(2, 168)/ 306.490/
          data  Ven(1, 169)/ 179.000/, Ven(2, 169)/ 306.155/
          data  Ven(1, 170)/ 180.000/, Ven(2, 170)/ 305.823/
          data  Ven(1, 171)/ 181.000/, Ven(2, 171)/ 305.494/
          data  Ven(1, 172)/ 182.000/, Ven(2, 172)/ 305.168/
          data  Ven(1, 173)/ 183.000/, Ven(2, 173)/ 304.844/
          data  Ven(1, 174)/ 184.000/, Ven(2, 174)/ 304.524/
          data  Ven(1, 175)/ 185.000/, Ven(2, 175)/ 304.206/
          data  Ven(1, 176)/ 186.000/, Ven(2, 176)/ 303.891/
          data  Ven(1, 177)/ 187.000/, Ven(2, 177)/ 303.578/
          data  Ven(1, 178)/ 188.000/, Ven(2, 178)/ 303.268/
          data  Ven(1, 179)/ 189.000/, Ven(2, 179)/ 302.961/
          data  Ven(1, 180)/ 190.000/, Ven(2, 180)/ 302.657/
          data  Ven(1, 181)/ 191.000/, Ven(2, 181)/ 302.355/
          data  Ven(1, 182)/ 192.000/, Ven(2, 182)/ 302.056/
          data  Ven(1, 183)/ 193.000/, Ven(2, 183)/ 301.760/
          data  Ven(1, 184)/ 194.000/, Ven(2, 184)/ 301.466/
          data  Ven(1, 185)/ 195.000/, Ven(2, 185)/ 301.174/
          data  Ven(1, 186)/ 196.000/, Ven(2, 186)/ 300.885/
          data  Ven(1, 187)/ 197.000/, Ven(2, 187)/ 300.598/
          data  Ven(1, 188)/ 198.000/, Ven(2, 188)/ 300.314/
          data  Ven(1, 189)/ 199.000/, Ven(2, 189)/ 300.033/
          data  Ven(1, 190)/ 200.000/, Ven(2, 190)/ 299.753/
          data  Ven(1, 191)/ 201.000/, Ven(2, 191)/ 299.477/
          data  Ven(1, 192)/ 202.000/, Ven(2, 192)/ 299.202/
          data  Ven(1, 193)/ 203.000/, Ven(2, 193)/ 298.930/
          data  Ven(1, 194)/ 204.000/, Ven(2, 194)/ 298.660/
          data  Ven(1, 195)/ 205.000/, Ven(2, 195)/ 298.392/
          data  Ven(1, 196)/ 206.000/, Ven(2, 196)/ 298.127/
          data  Ven(1, 197)/ 207.000/, Ven(2, 197)/ 297.864/
          data  Ven(1, 198)/ 208.000/, Ven(2, 198)/ 297.603/
          data  Ven(1, 199)/ 209.000/, Ven(2, 199)/ 297.344/
          data  Ven(1, 200)/ 210.000/, Ven(2, 200)/ 297.087/
          data  Ven(1, 201)/ 211.000/, Ven(2, 201)/ 296.833/
          data  Ven(1, 202)/ 212.000/, Ven(2, 202)/ 296.581/
          data  Ven(1, 203)/ 213.000/, Ven(2, 203)/ 296.331/
          data  Ven(1, 204)/ 214.000/, Ven(2, 204)/ 296.083/
          data  Ven(1, 205)/ 215.000/, Ven(2, 205)/ 295.837/
          data  Ven(1, 206)/ 216.000/, Ven(2, 206)/ 295.593/
          data  Ven(1, 207)/ 217.000/, Ven(2, 207)/ 295.351/
          data  Ven(1, 208)/ 218.000/, Ven(2, 208)/ 295.111/
          data  Ven(1, 209)/ 219.000/, Ven(2, 209)/ 294.873/
          data  Ven(1, 210)/ 220.000/, Ven(2, 210)/ 294.637/
          data  Ven(1, 211)/ 221.000/, Ven(2, 211)/ 294.404/
          data  Ven(1, 212)/ 222.000/, Ven(2, 212)/ 294.171/
          data  Ven(1, 213)/ 223.000/, Ven(2, 213)/ 293.941/
          data  Ven(1, 214)/ 224.000/, Ven(2, 214)/ 293.713/
          data  Ven(1, 215)/ 225.000/, Ven(2, 215)/ 293.487/
          data  Ven(1, 216)/ 226.000/, Ven(2, 216)/ 293.263/
          data  Ven(1, 217)/ 227.000/, Ven(2, 217)/ 293.040/
          data  Ven(1, 218)/ 228.000/, Ven(2, 218)/ 292.819/
          data  Ven(1, 219)/ 229.000/, Ven(2, 219)/ 292.601/
          data  Ven(1, 220)/ 230.000/, Ven(2, 220)/ 292.384/
          data  Ven(1, 221)/ 231.000/, Ven(2, 221)/ 292.169/
          data  Ven(1, 222)/ 232.000/, Ven(2, 222)/ 291.955/
          data  Ven(1, 223)/ 233.000/, Ven(2, 223)/ 291.742/
          data  Ven(1, 224)/ 234.000/, Ven(2, 224)/ 291.532/
          data  Ven(1, 225)/ 235.000/, Ven(2, 225)/ 291.324/
          data  Ven(1, 226)/ 236.000/, Ven(2, 226)/ 291.117/
          data  Ven(1, 227)/ 237.000/, Ven(2, 227)/ 290.913/
          data  Ven(1, 228)/ 238.000/, Ven(2, 228)/ 290.708/
          data  Ven(1, 229)/ 239.000/, Ven(2, 229)/ 290.507/
          data  Ven(1, 230)/ 240.000/, Ven(2, 230)/ 290.307/
          data  Ven(1, 231)/ 241.000/, Ven(2, 231)/ 290.110/
          data  Ven(1, 232)/ 242.000/, Ven(2, 232)/ 289.911/
          data  Ven(1, 233)/ 243.000/, Ven(2, 233)/ 289.717/
          data  Ven(1, 234)/ 244.000/, Ven(2, 234)/ 289.523/
          data  Ven(1, 235)/ 245.000/, Ven(2, 235)/ 289.330/
          data  Ven(1, 236)/ 246.000/, Ven(2, 236)/ 289.140/
          data  Ven(1, 237)/ 247.000/, Ven(2, 237)/ 288.952/
          data  Ven(1, 238)/ 248.000/, Ven(2, 238)/ 288.764/
          data  Ven(1, 239)/ 249.000/, Ven(2, 239)/ 288.577/
          data  Ven(1, 240)/ 250.000/, Ven(2, 240)/ 288.394/
          data  Ven(1, 241)/ 251.000/, Ven(2, 241)/ 288.209/
          data  Ven(1, 242)/ 252.000/, Ven(2, 242)/ 288.027/
          data  Ven(1, 243)/ 253.000/, Ven(2, 243)/ 287.849/
          data  Ven(1, 244)/ 254.000/, Ven(2, 244)/ 287.669/
          data  Ven(1, 245)/ 255.000/, Ven(2, 245)/ 287.492/
          data  Ven(1, 246)/ 256.000/, Ven(2, 246)/ 287.316/
          data  Ven(1, 247)/ 257.000/, Ven(2, 247)/ 287.141/
          data  Ven(1, 248)/ 258.000/, Ven(2, 248)/ 286.967/
          data  Ven(1, 249)/ 259.000/, Ven(2, 249)/ 286.795/
          data  Ven(1, 250)/ 260.000/, Ven(2, 250)/ 286.625/
          data  Ven(1, 251)/ 261.000/, Ven(2, 251)/ 286.455/
          data  Ven(1, 252)/ 262.000/, Ven(2, 252)/ 286.288/
          data  Ven(1, 253)/ 263.000/, Ven(2, 253)/ 286.122/
          data  Ven(1, 254)/ 264.000/, Ven(2, 254)/ 285.955/
          data  Ven(1, 255)/ 265.000/, Ven(2, 255)/ 285.792/
          data  Ven(1, 256)/ 266.000/, Ven(2, 256)/ 285.629/
          data  Ven(1, 257)/ 267.000/, Ven(2, 257)/ 285.468/
          data  Ven(1, 258)/ 268.000/, Ven(2, 258)/ 285.308/
          data  Ven(1, 259)/ 269.000/, Ven(2, 259)/ 285.148/
          data  Ven(1, 260)/ 270.000/, Ven(2, 260)/ 284.990/
          data  Ven(1, 261)/ 271.000/, Ven(2, 261)/ 284.833/
          data  Ven(1, 262)/ 272.000/, Ven(2, 262)/ 284.678/
          data  Ven(1, 263)/ 273.000/, Ven(2, 263)/ 284.524/
          data  Ven(1, 264)/ 274.000/, Ven(2, 264)/ 284.371/
          data  Ven(1, 265)/ 275.000/, Ven(2, 265)/ 284.218/
          data  Ven(1, 266)/ 276.000/, Ven(2, 266)/ 284.068/
          data  Ven(1, 267)/ 277.000/, Ven(2, 267)/ 283.918/
          data  Ven(1, 268)/ 278.000/, Ven(2, 268)/ 283.770/
          data  Ven(1, 269)/ 279.000/, Ven(2, 269)/ 283.623/
          data  Ven(1, 270)/ 280.000/, Ven(2, 270)/ 283.475/
          data  Ven(1, 271)/ 281.000/, Ven(2, 271)/ 283.332/
          data  Ven(1, 272)/ 282.000/, Ven(2, 272)/ 283.187/
          data  Ven(1, 273)/ 283.000/, Ven(2, 273)/ 283.044/
          data  Ven(1, 274)/ 284.000/, Ven(2, 274)/ 282.902/
          data  Ven(1, 275)/ 285.000/, Ven(2, 275)/ 282.761/
          data  Ven(1, 276)/ 286.000/, Ven(2, 276)/ 282.621/
          data  Ven(1, 277)/ 287.000/, Ven(2, 277)/ 282.482/
          data  Ven(1, 278)/ 288.000/, Ven(2, 278)/ 282.345/
          data  Ven(1, 279)/ 289.000/, Ven(2, 279)/ 282.208/
          data  Ven(1, 280)/ 290.000/, Ven(2, 280)/ 282.073/
          data  Ven(1, 281)/ 291.000/, Ven(2, 281)/ 281.937/
          data  Ven(1, 282)/ 292.000/, Ven(2, 282)/ 281.803/
          data  Ven(1, 283)/ 293.000/, Ven(2, 283)/ 281.670/
          data  Ven(1, 284)/ 294.000/, Ven(2, 284)/ 281.539/
          data  Ven(1, 285)/ 295.000/, Ven(2, 285)/ 281.407/
          data  Ven(1, 286)/ 296.000/, Ven(2, 286)/ 281.277/
          data  Ven(1, 287)/ 297.000/, Ven(2, 287)/ 281.150/
          data  Ven(1, 288)/ 298.000/, Ven(2, 288)/ 281.021/
          data  Ven(1, 289)/ 299.000/, Ven(2, 289)/ 280.894/
          data  Ven(1, 290)/ 300.000/, Ven(2, 290)/ 280.768/
          data  Ven(1, 291)/ 301.000/, Ven(2, 291)/ 280.643/
          data  Ven(1, 292)/ 302.000/, Ven(2, 292)/ 280.517/
          data  Ven(1, 293)/ 303.000/, Ven(2, 293)/ 280.394/
          data  Ven(1, 294)/ 304.000/, Ven(2, 294)/ 280.272/
          data  Ven(1, 295)/ 305.000/, Ven(2, 295)/ 280.150/
          data  Ven(1, 296)/ 306.000/, Ven(2, 296)/ 280.028/
          data  Ven(1, 297)/ 307.000/, Ven(2, 297)/ 279.909/
          data  Ven(1, 298)/ 308.000/, Ven(2, 298)/ 279.790/
          data  Ven(1, 299)/ 309.000/, Ven(2, 299)/ 279.671/
          data  Ven(1, 300)/ 310.000/, Ven(2, 300)/ 279.553/
          data  Ven(1, 301)/ 311.000/, Ven(2, 301)/ 279.437/
          data  Ven(1, 302)/ 312.000/, Ven(2, 302)/ 279.321/
          data  Ven(1, 303)/ 313.000/, Ven(2, 303)/ 279.206/
          data  Ven(1, 304)/ 314.000/, Ven(2, 304)/ 279.091/
          data  Ven(1, 305)/ 315.000/, Ven(2, 305)/ 278.978/
          data  Ven(1, 306)/ 316.000/, Ven(2, 306)/ 278.864/
          data  Ven(1, 307)/ 317.000/, Ven(2, 307)/ 278.752/
          data  Ven(1, 308)/ 318.000/, Ven(2, 308)/ 278.642/
          data  Ven(1, 309)/ 319.000/, Ven(2, 309)/ 278.531/
          data  Ven(1, 310)/ 320.000/, Ven(2, 310)/ 278.421/
          data  Ven(1, 311)/ 321.000/, Ven(2, 311)/ 278.312/
          data  Ven(1, 312)/ 322.000/, Ven(2, 312)/ 278.204/
          data  Ven(1, 313)/ 323.000/, Ven(2, 313)/ 278.097/
          data  Ven(1, 314)/ 324.000/, Ven(2, 314)/ 277.991/
          data  Ven(1, 315)/ 325.000/, Ven(2, 315)/ 277.885/
          data  Ven(1, 316)/ 326.000/, Ven(2, 316)/ 277.779/
          data  Ven(1, 317)/ 327.000/, Ven(2, 317)/ 277.674/
          data  Ven(1, 318)/ 328.000/, Ven(2, 318)/ 277.571/
          data  Ven(1, 319)/ 329.000/, Ven(2, 319)/ 277.468/
          data  Ven(1, 320)/ 330.000/, Ven(2, 320)/ 277.365/
          data  Ven(1, 321)/ 331.000/, Ven(2, 321)/ 277.263/
          data  Ven(1, 322)/ 332.000/, Ven(2, 322)/ 277.162/
          data  Ven(1, 323)/ 333.000/, Ven(2, 323)/ 277.060/
          data  Ven(1, 324)/ 334.000/, Ven(2, 324)/ 276.962/
          data  Ven(1, 325)/ 335.000/, Ven(2, 325)/ 276.862/
          data  Ven(1, 326)/ 336.000/, Ven(2, 326)/ 276.763/
          data  Ven(1, 327)/ 337.000/, Ven(2, 327)/ 276.666/
          data  Ven(1, 328)/ 338.000/, Ven(2, 328)/ 276.568/
          data  Ven(1, 329)/ 339.000/, Ven(2, 329)/ 276.472/
          data  Ven(1, 330)/ 340.000/, Ven(2, 330)/ 276.375/
          data  Ven(1, 331)/ 341.000/, Ven(2, 331)/ 276.280/
          data  Ven(1, 332)/ 342.000/, Ven(2, 332)/ 276.186/
          data  Ven(1, 333)/ 343.000/, Ven(2, 333)/ 276.091/
          data  Ven(1, 334)/ 344.000/, Ven(2, 334)/ 275.997/
          data  Ven(1, 335)/ 345.000/, Ven(2, 335)/ 275.905/
          data  Ven(1, 336)/ 346.000/, Ven(2, 336)/ 275.812/
          data  Ven(1, 337)/ 347.000/, Ven(2, 337)/ 275.720/
          data  Ven(1, 338)/ 348.000/, Ven(2, 338)/ 275.629/
          data  Ven(1, 339)/ 349.000/, Ven(2, 339)/ 275.539/
          data  Ven(1, 340)/ 350.000/, Ven(2, 340)/ 275.448/
          data  Ven(1, 341)/ 351.000/, Ven(2, 341)/ 275.359/
          data  Ven(1, 342)/ 352.000/, Ven(2, 342)/ 275.270/
          data  Ven(1, 343)/ 353.000/, Ven(2, 343)/ 275.181/
          data  Ven(1, 344)/ 354.000/, Ven(2, 344)/ 275.094/
          data  Ven(1, 345)/ 355.000/, Ven(2, 345)/ 275.006/
          data  Ven(1, 346)/ 356.000/, Ven(2, 346)/ 274.920/
          data  Ven(1, 347)/ 357.000/, Ven(2, 347)/ 274.833/
          data  Ven(1, 348)/ 358.000/, Ven(2, 348)/ 274.747/
          data  Ven(1, 349)/ 359.000/, Ven(2, 349)/ 274.663/
          data  Ven(1, 350)/ 360.000/, Ven(2, 350)/ 274.579/
          data  Ven(1, 351)/ 361.000/, Ven(2, 351)/ 274.493/
          data  Ven(1, 352)/ 362.000/, Ven(2, 352)/ 274.410/
          data  Ven(1, 353)/ 363.000/, Ven(2, 353)/ 274.327/
          data  Ven(1, 354)/ 364.000/, Ven(2, 354)/ 274.244/
          data  Ven(1, 355)/ 365.000/, Ven(2, 355)/ 274.163/
          data  Ven(1, 356)/ 366.000/, Ven(2, 356)/ 274.081/
          data  Ven(1, 357)/ 367.000/, Ven(2, 357)/ 274.000/
          data  Ven(1, 358)/ 368.000/, Ven(2, 358)/ 273.919/
          data  Ven(1, 359)/ 369.000/, Ven(2, 359)/ 273.838/
          data  Ven(1, 360)/ 370.000/, Ven(2, 360)/ 273.759/
          data  Ven(1, 361)/ 371.000/, Ven(2, 361)/ 273.680/
          data  Ven(1, 362)/ 372.000/, Ven(2, 362)/ 273.601/
          data  Ven(1, 363)/ 373.000/, Ven(2, 363)/ 273.522/
          data  Ven(1, 364)/ 374.000/, Ven(2, 364)/ 273.444/
          data  Ven(1, 365)/ 375.000/, Ven(2, 365)/ 273.367/
          data  Ven(1, 366)/ 376.000/, Ven(2, 366)/ 273.290/
          data  Ven(1, 367)/ 377.000/, Ven(2, 367)/ 273.214/
          data  Ven(1, 368)/ 378.000/, Ven(2, 368)/ 273.138/
          data  Ven(1, 369)/ 379.000/, Ven(2, 369)/ 273.062/
          data  Ven(1, 370)/ 380.000/, Ven(2, 370)/ 272.987/
          data  Ven(1, 371)/ 381.000/, Ven(2, 371)/ 272.912/
          data  Ven(1, 372)/ 382.000/, Ven(2, 372)/ 272.837/
          data  Ven(1, 373)/ 383.000/, Ven(2, 373)/ 272.763/
          data  Ven(1, 374)/ 384.000/, Ven(2, 374)/ 272.690/
          data  Ven(1, 375)/ 385.000/, Ven(2, 375)/ 272.617/
          data  Ven(1, 376)/ 386.000/, Ven(2, 376)/ 272.544/
          data  Ven(1, 377)/ 387.000/, Ven(2, 377)/ 272.472/
          data  Ven(1, 378)/ 388.000/, Ven(2, 378)/ 272.400/
          data  Ven(1, 379)/ 389.000/, Ven(2, 379)/ 272.328/
          data  Ven(1, 380)/ 390.000/, Ven(2, 380)/ 272.257/
          data  Ven(1, 381)/ 391.000/, Ven(2, 381)/ 272.187/
          data  Ven(1, 382)/ 392.000/, Ven(2, 382)/ 272.116/
          data  Ven(1, 383)/ 393.000/, Ven(2, 383)/ 272.046/
          data  Ven(1, 384)/ 394.000/, Ven(2, 384)/ 271.977/
          data  Ven(1, 385)/ 395.000/, Ven(2, 385)/ 271.908/
          data  Ven(1, 386)/ 396.000/, Ven(2, 386)/ 271.839/
          data  Ven(1, 387)/ 397.000/, Ven(2, 387)/ 271.770/
          data  Ven(1, 388)/ 398.000/, Ven(2, 388)/ 271.702/
          data  Ven(1, 389)/ 399.000/, Ven(2, 389)/ 271.635/
          data  Ven(1, 390)/ 400.000/, Ven(2, 390)/ 271.567/
          data  Ven(1, 391)/ 401.000/, Ven(2, 391)/ 271.500/
          data  Ven(1, 392)/ 402.000/, Ven(2, 392)/ 271.434/
          data  Ven(1, 393)/ 403.000/, Ven(2, 393)/ 271.367/
          data  Ven(1, 394)/ 404.000/, Ven(2, 394)/ 271.302/
          data  Ven(1, 395)/ 405.000/, Ven(2, 395)/ 271.235/
          data  Ven(1, 396)/ 406.000/, Ven(2, 396)/ 271.170/
          data  Ven(1, 397)/ 407.000/, Ven(2, 397)/ 271.106/
          data  Ven(1, 398)/ 408.000/, Ven(2, 398)/ 271.041/
          data  Ven(1, 399)/ 409.000/, Ven(2, 399)/ 270.977/
          data  Ven(1, 400)/ 410.000/, Ven(2, 400)/ 270.912/
          data  Ven(1, 401)/ 411.000/, Ven(2, 401)/ 270.849/
          data  Ven(1, 402)/ 412.000/, Ven(2, 402)/ 270.785/
          data  Ven(1, 403)/ 413.000/, Ven(2, 403)/ 270.723/
          data  Ven(1, 404)/ 414.000/, Ven(2, 404)/ 270.660/
          data  Ven(1, 405)/ 415.000/, Ven(2, 405)/ 270.598/
          data  Ven(1, 406)/ 416.000/, Ven(2, 406)/ 270.536/
          data  Ven(1, 407)/ 417.000/, Ven(2, 407)/ 270.474/
          data  Ven(1, 408)/ 418.000/, Ven(2, 408)/ 270.413/
          data  Ven(1, 409)/ 419.000/, Ven(2, 409)/ 270.351/
          data  Ven(1, 410)/ 420.000/, Ven(2, 410)/ 270.291/
          data  Ven(1, 411)/ 421.000/, Ven(2, 411)/ 270.230/
          data  Ven(1, 412)/ 422.000/, Ven(2, 412)/ 270.170/
          data  Ven(1, 413)/ 423.000/, Ven(2, 413)/ 270.110/
          data  Ven(1, 414)/ 424.000/, Ven(2, 414)/ 270.050/
          data  Ven(1, 415)/ 425.000/, Ven(2, 415)/ 269.991/
          data  Ven(1, 416)/ 426.000/, Ven(2, 416)/ 269.932/
          data  Ven(1, 417)/ 427.000/, Ven(2, 417)/ 269.874/
          data  Ven(1, 418)/ 428.000/, Ven(2, 418)/ 269.815/
          data  Ven(1, 419)/ 429.000/, Ven(2, 419)/ 269.757/
          data  Ven(1, 420)/ 430.000/, Ven(2, 420)/ 269.699/
          data  Ven(1, 421)/ 431.000/, Ven(2, 421)/ 269.642/
          data  Ven(1, 422)/ 432.000/, Ven(2, 422)/ 269.584/
          data  Ven(1, 423)/ 433.000/, Ven(2, 423)/ 269.527/
          data  Ven(1, 424)/ 434.000/, Ven(2, 424)/ 269.470/
          data  Ven(1, 425)/ 435.000/, Ven(2, 425)/ 269.413/
          data  Ven(1, 426)/ 436.000/, Ven(2, 426)/ 269.357/
          data  Ven(1, 427)/ 437.000/, Ven(2, 427)/ 269.301/
          data  Ven(1, 428)/ 438.000/, Ven(2, 428)/ 269.245/
          data  Ven(1, 429)/ 439.000/, Ven(2, 429)/ 269.190/
          data  Ven(1, 430)/ 440.000/, Ven(2, 430)/ 269.135/
          data  Ven(1, 431)/ 441.000/, Ven(2, 431)/ 269.079/
          data  Ven(1, 432)/ 442.000/, Ven(2, 432)/ 269.024/
          data  Ven(1, 433)/ 443.000/, Ven(2, 433)/ 268.971/
          data  Ven(1, 434)/ 444.000/, Ven(2, 434)/ 268.916/
          data  Ven(1, 435)/ 445.000/, Ven(2, 435)/ 268.862/
          data  Ven(1, 436)/ 446.000/, Ven(2, 436)/ 268.808/
          data  Ven(1, 437)/ 447.000/, Ven(2, 437)/ 268.755/
          data  Ven(1, 438)/ 448.000/, Ven(2, 438)/ 268.701/
          data  Ven(1, 439)/ 449.000/, Ven(2, 439)/ 268.648/
          data  Ven(1, 440)/ 450.000/, Ven(2, 440)/ 268.596/
          data  Ven(1, 441)/ 451.000/, Ven(2, 441)/ 268.543/
          data  Ven(1, 442)/ 452.000/, Ven(2, 442)/ 268.490/
          data  Ven(1, 443)/ 453.000/, Ven(2, 443)/ 268.438/
          data  Ven(1, 444)/ 454.000/, Ven(2, 444)/ 268.386/
          data  Ven(1, 445)/ 455.000/, Ven(2, 445)/ 268.334/
          data  Ven(1, 446)/ 456.000/, Ven(2, 446)/ 268.283/
          data  Ven(1, 447)/ 457.000/, Ven(2, 447)/ 268.232/
          data  Ven(1, 448)/ 458.000/, Ven(2, 448)/ 268.181/
          data  Ven(1, 449)/ 459.000/, Ven(2, 449)/ 268.130/
          data  Ven(1, 450)/ 460.000/, Ven(2, 450)/ 268.080/
          data  Ven(1, 451)/ 461.000/, Ven(2, 451)/ 268.029/
          data  Ven(1, 452)/ 462.000/, Ven(2, 452)/ 267.979/
          data  Ven(1, 453)/ 463.000/, Ven(2, 453)/ 267.929/
          data  Ven(1, 454)/ 464.000/, Ven(2, 454)/ 267.879/
          data  Ven(1, 455)/ 465.000/, Ven(2, 455)/ 267.830/
          data  Ven(1, 456)/ 466.000/, Ven(2, 456)/ 267.780/
          data  Ven(1, 457)/ 467.000/, Ven(2, 457)/ 267.731/
          data  Ven(1, 458)/ 468.000/, Ven(2, 458)/ 267.682/
          data  Ven(1, 459)/ 469.000/, Ven(2, 459)/ 267.633/
          data  Ven(1, 460)/ 470.000/, Ven(2, 460)/ 267.585/
          data  Ven(1, 461)/ 471.000/, Ven(2, 461)/ 267.537/
          data  Ven(1, 462)/ 472.000/, Ven(2, 462)/ 267.488/
          data  Ven(1, 463)/ 473.000/, Ven(2, 463)/ 267.440/
          data  Ven(1, 464)/ 474.000/, Ven(2, 464)/ 267.393/
          data  Ven(1, 465)/ 475.000/, Ven(2, 465)/ 267.345/
          data  Ven(1, 466)/ 476.000/, Ven(2, 466)/ 267.297/
          data  Ven(1, 467)/ 477.000/, Ven(2, 467)/ 267.250/
          data  Ven(1, 468)/ 478.000/, Ven(2, 468)/ 267.203/
          data  Ven(1, 469)/ 479.000/, Ven(2, 469)/ 267.156/
          data  Ven(1, 470)/ 480.000/, Ven(2, 470)/ 267.109/
          data  Ven(1, 471)/ 481.000/, Ven(2, 471)/ 267.063/
          data  Ven(1, 472)/ 482.000/, Ven(2, 472)/ 267.017/
          data  Ven(1, 473)/ 483.000/, Ven(2, 473)/ 266.970/
          data  Ven(1, 474)/ 484.000/, Ven(2, 474)/ 266.925/
          data  Ven(1, 475)/ 485.000/, Ven(2, 475)/ 266.879/
          data  Ven(1, 476)/ 486.000/, Ven(2, 476)/ 266.834/
          data  Ven(1, 477)/ 487.000/, Ven(2, 477)/ 266.788/
          data  Ven(1, 478)/ 488.000/, Ven(2, 478)/ 266.743/
          data  Ven(1, 479)/ 489.000/, Ven(2, 479)/ 266.697/
          data  Ven(1, 480)/ 490.000/, Ven(2, 480)/ 266.653/
          data  Ven(1, 481)/ 491.000/, Ven(2, 481)/ 266.608/
          data  Ven(1, 482)/ 492.000/, Ven(2, 482)/ 266.563/
          data  Ven(1, 483)/ 493.000/, Ven(2, 483)/ 266.519/
          data  Ven(1, 484)/ 494.000/, Ven(2, 484)/ 266.475/
          data  Ven(1, 485)/ 495.000/, Ven(2, 485)/ 266.430/
          data  Ven(1, 486)/ 496.000/, Ven(2, 486)/ 266.387/
          data  Ven(1, 487)/ 497.000/, Ven(2, 487)/ 266.343/
          data  Ven(1, 488)/ 498.000/, Ven(2, 488)/ 266.299/
          data  Ven(1, 489)/ 499.000/, Ven(2, 489)/ 266.255/
          data  Ven(1, 490)/ 500.000/, Ven(2, 490)/ 266.212/
          data  Ven(1, 491)/ 501.000/, Ven(2, 491)/ 266.169/
          data  Ven(1, 492)/ 502.000/, Ven(2, 492)/ 266.126/
          data  Ven(1, 493)/ 503.000/, Ven(2, 493)/ 266.083/
          data  Ven(1, 494)/ 504.000/, Ven(2, 494)/ 266.040/
          data  Ven(1, 495)/ 505.000/, Ven(2, 495)/ 265.998/
          data  Ven(1, 496)/ 506.000/, Ven(2, 496)/ 265.955/
          data  Ven(1, 497)/ 507.000/, Ven(2, 497)/ 265.913/
          data  Ven(1, 498)/ 508.000/, Ven(2, 498)/ 265.871/
          data  Ven(1, 499)/ 509.000/, Ven(2, 499)/ 265.829/
          data  Ven(1, 500)/ 510.000/, Ven(2, 500)/ 265.787/
          data  Ven(1, 501)/ 511.000/, Ven(2, 501)/ 265.745/
          data  Ven(1, 502)/ 512.000/, Ven(2, 502)/ 265.704/
          data  Ven(1, 503)/ 513.000/, Ven(2, 503)/ 265.662/
          data  Ven(1, 504)/ 514.000/, Ven(2, 504)/ 265.621/
          data  Ven(1, 505)/ 515.000/, Ven(2, 505)/ 265.580/
          data  Ven(1, 506)/ 516.000/, Ven(2, 506)/ 265.539/
          data  Ven(1, 507)/ 517.000/, Ven(2, 507)/ 265.498/
          data  Ven(1, 508)/ 518.000/, Ven(2, 508)/ 265.457/
          data  Ven(1, 509)/ 519.000/, Ven(2, 509)/ 265.417/
          data  Ven(1, 510)/ 520.000/, Ven(2, 510)/ 265.376/
          data  Ven(1, 511)/ 521.000/, Ven(2, 511)/ 265.336/
          data  Ven(1, 512)/ 522.000/, Ven(2, 512)/ 265.296/
          data  Ven(1, 513)/ 523.000/, Ven(2, 513)/ 265.255/
          data  Ven(1, 514)/ 524.000/, Ven(2, 514)/ 265.216/
          data  Ven(1, 515)/ 525.000/, Ven(2, 515)/ 265.176/
          data  Ven(1, 516)/ 526.000/, Ven(2, 516)/ 265.136/
          data  Ven(1, 517)/ 527.000/, Ven(2, 517)/ 265.097/
          data  Ven(1, 518)/ 528.000/, Ven(2, 518)/ 265.057/
          data  Ven(1, 519)/ 529.000/, Ven(2, 519)/ 265.018/
          data  Ven(1, 520)/ 530.000/, Ven(2, 520)/ 264.979/
          data  Ven(1, 521)/ 531.000/, Ven(2, 521)/ 264.939/
          data  Ven(1, 522)/ 532.000/, Ven(2, 522)/ 264.901/
          data  Ven(1, 523)/ 533.000/, Ven(2, 523)/ 264.862/
          data  Ven(1, 524)/ 534.000/, Ven(2, 524)/ 264.823/
          data  Ven(1, 525)/ 535.000/, Ven(2, 525)/ 264.784/
          data  Ven(1, 526)/ 536.000/, Ven(2, 526)/ 264.746/
          data  Ven(1, 527)/ 537.000/, Ven(2, 527)/ 264.707/
          data  Ven(1, 528)/ 538.000/, Ven(2, 528)/ 264.669/
          data  Ven(1, 529)/ 539.000/, Ven(2, 529)/ 264.631/
          data  Ven(1, 530)/ 540.000/, Ven(2, 530)/ 264.593/
          data  Ven(1, 531)/ 541.000/, Ven(2, 531)/ 264.555/
          data  Ven(1, 532)/ 542.000/, Ven(2, 532)/ 264.517/
          data  Ven(1, 533)/ 543.000/, Ven(2, 533)/ 264.480/
          data  Ven(1, 534)/ 544.000/, Ven(2, 534)/ 264.442/
          data  Ven(1, 535)/ 545.000/, Ven(2, 535)/ 264.405/
          data  Ven(1, 536)/ 546.000/, Ven(2, 536)/ 264.367/
          data  Ven(1, 537)/ 547.000/, Ven(2, 537)/ 264.330/
          data  Ven(1, 538)/ 548.000/, Ven(2, 538)/ 264.293/
          data  Ven(1, 539)/ 549.000/, Ven(2, 539)/ 264.256/
          data  Ven(1, 540)/ 550.000/, Ven(2, 540)/ 264.219/
          data  Ven(1, 541)/ 551.000/, Ven(2, 541)/ 264.182/
          data  Ven(1, 542)/ 552.000/, Ven(2, 542)/ 264.146/
          data  Ven(1, 543)/ 553.000/, Ven(2, 543)/ 264.109/
          data  Ven(1, 544)/ 554.000/, Ven(2, 544)/ 264.072/
          data  Ven(1, 545)/ 555.000/, Ven(2, 545)/ 264.036/
          data  Ven(1, 546)/ 556.000/, Ven(2, 546)/ 264.000/
          data  Ven(1, 547)/ 557.000/, Ven(2, 547)/ 263.963/
          data  Ven(1, 548)/ 558.000/, Ven(2, 548)/ 263.927/
          data  Ven(1, 549)/ 559.000/, Ven(2, 549)/ 263.891/
          data  Ven(1, 550)/ 560.000/, Ven(2, 550)/ 263.855/
          data  Ven(1, 551)/ 561.000/, Ven(2, 551)/ 263.820/
          data  Ven(1, 552)/ 562.000/, Ven(2, 552)/ 263.784/
          data  Ven(1, 553)/ 563.000/, Ven(2, 553)/ 263.748/
          data  Ven(1, 554)/ 564.000/, Ven(2, 554)/ 263.713/
          data  Ven(1, 555)/ 565.000/, Ven(2, 555)/ 263.677/
          data  Ven(1, 556)/ 566.000/, Ven(2, 556)/ 263.642/
          data  Ven(1, 557)/ 567.000/, Ven(2, 557)/ 263.607/
          data  Ven(1, 558)/ 568.000/, Ven(2, 558)/ 263.572/
          data  Ven(1, 559)/ 569.000/, Ven(2, 559)/ 263.536/
          data  Ven(1, 560)/ 570.000/, Ven(2, 560)/ 263.502/
          data  Ven(1, 561)/ 571.000/, Ven(2, 561)/ 263.467/
          data  Ven(1, 562)/ 572.000/, Ven(2, 562)/ 263.432/
          data  Ven(1, 563)/ 573.000/, Ven(2, 563)/ 263.397/
          data  Ven(1, 564)/ 574.000/, Ven(2, 564)/ 263.362/
          data  Ven(1, 565)/ 575.000/, Ven(2, 565)/ 263.328/
          data  Ven(1, 566)/ 576.000/, Ven(2, 566)/ 263.294/
          data  Ven(1, 567)/ 577.000/, Ven(2, 567)/ 263.259/
          data  Ven(1, 568)/ 578.000/, Ven(2, 568)/ 263.225/
          data  Ven(1, 569)/ 579.000/, Ven(2, 569)/ 263.191/
          data  Ven(1, 570)/ 580.000/, Ven(2, 570)/ 263.157/
          data  Ven(1, 571)/ 581.000/, Ven(2, 571)/ 263.123/
          data  Ven(1, 572)/ 582.000/, Ven(2, 572)/ 263.089/
          data  Ven(1, 573)/ 583.000/, Ven(2, 573)/ 263.055/
          data  Ven(1, 574)/ 584.000/, Ven(2, 574)/ 263.021/
          data  Ven(1, 575)/ 585.000/, Ven(2, 575)/ 262.988/
          data  Ven(1, 576)/ 586.000/, Ven(2, 576)/ 262.954/
          data  Ven(1, 577)/ 587.000/, Ven(2, 577)/ 262.920/
          data  Ven(1, 578)/ 588.000/, Ven(2, 578)/ 262.887/
          data  Ven(1, 579)/ 589.000/, Ven(2, 579)/ 262.854/
          data  Ven(1, 580)/ 590.000/, Ven(2, 580)/ 262.820/
          data  Ven(1, 581)/ 591.000/, Ven(2, 581)/ 262.787/
          data  Ven(1, 582)/ 592.000/, Ven(2, 582)/ 262.754/
          data  Ven(1, 583)/ 593.000/, Ven(2, 583)/ 262.721/
          data  Ven(1, 584)/ 594.000/, Ven(2, 584)/ 262.688/
          data  Ven(1, 585)/ 595.000/, Ven(2, 585)/ 262.655/
          data  Ven(1, 586)/ 596.000/, Ven(2, 586)/ 262.622/
          data  Ven(1, 587)/ 597.000/, Ven(2, 587)/ 262.590/
          data  Ven(1, 588)/ 598.000/, Ven(2, 588)/ 262.557/
          data  Ven(1, 589)/ 599.000/, Ven(2, 589)/ 262.525/
          data  Ven(1, 590)/ 600.000/, Ven(2, 590)/ 262.492/
          data  Ven(1, 591)/ 601.000/, Ven(2, 591)/ 262.460/
          data  Ven(1, 592)/ 602.000/, Ven(2, 592)/ 262.427/
          data  Ven(1, 593)/ 603.000/, Ven(2, 593)/ 262.395/
          data  Ven(1, 594)/ 604.000/, Ven(2, 594)/ 262.363/
          data  Ven(1, 595)/ 605.000/, Ven(2, 595)/ 262.331/
          data  Ven(1, 596)/ 606.000/, Ven(2, 596)/ 262.299/
          data  Ven(1, 597)/ 607.000/, Ven(2, 597)/ 262.267/
          data  Ven(1, 598)/ 608.000/, Ven(2, 598)/ 262.235/
          data  Ven(1, 599)/ 609.000/, Ven(2, 599)/ 262.203/
          data  Ven(1, 600)/ 610.000/, Ven(2, 600)/ 262.171/
          data  Ven(1, 601)/ 611.000/, Ven(2, 601)/ 262.139/
          data  Ven(1, 602)/ 612.000/, Ven(2, 602)/ 262.108/
          data  Ven(1, 603)/ 613.000/, Ven(2, 603)/ 262.077/
          data  Ven(1, 604)/ 614.000/, Ven(2, 604)/ 262.045/
          data  Ven(1, 605)/ 615.000/, Ven(2, 605)/ 262.014/
          data  Ven(1, 606)/ 616.000/, Ven(2, 606)/ 261.982/
          data  Ven(1, 607)/ 617.000/, Ven(2, 607)/ 261.951/
          data  Ven(1, 608)/ 618.000/, Ven(2, 608)/ 261.920/
          data  Ven(1, 609)/ 619.000/, Ven(2, 609)/ 261.888/
          data  Ven(1, 610)/ 620.000/, Ven(2, 610)/ 261.858/
          data  Ven(1, 611)/ 621.000/, Ven(2, 611)/ 261.826/
          data  Ven(1, 612)/ 622.000/, Ven(2, 612)/ 261.795/
          data  Ven(1, 613)/ 623.000/, Ven(2, 613)/ 261.765/
          data  Ven(1, 614)/ 624.000/, Ven(2, 614)/ 261.734/
          data  Ven(1, 615)/ 625.000/, Ven(2, 615)/ 261.703/
          data  Ven(1, 616)/ 626.000/, Ven(2, 616)/ 261.672/
          data  Ven(1, 617)/ 627.000/, Ven(2, 617)/ 261.642/
          data  Ven(1, 618)/ 628.000/, Ven(2, 618)/ 261.611/
          data  Ven(1, 619)/ 629.000/, Ven(2, 619)/ 261.581/
          data  Ven(1, 620)/ 630.000/, Ven(2, 620)/ 261.550/
          data  Ven(1, 621)/ 631.000/, Ven(2, 621)/ 261.520/
          data  Ven(1, 622)/ 632.000/, Ven(2, 622)/ 261.489/
          data  Ven(1, 623)/ 633.000/, Ven(2, 623)/ 261.459/
          data  Ven(1, 624)/ 634.000/, Ven(2, 624)/ 261.429/
          data  Ven(1, 625)/ 635.000/, Ven(2, 625)/ 261.399/
          data  Ven(1, 626)/ 636.000/, Ven(2, 626)/ 261.369/
          data  Ven(1, 627)/ 637.000/, Ven(2, 627)/ 261.339/
          data  Ven(1, 628)/ 638.000/, Ven(2, 628)/ 261.309/
          data  Ven(1, 629)/ 639.000/, Ven(2, 629)/ 261.279/
          data  Ven(1, 630)/ 640.000/, Ven(2, 630)/ 261.249/
          data  Ven(1, 631)/ 641.000/, Ven(2, 631)/ 261.219/
          data  Ven(1, 632)/ 642.000/, Ven(2, 632)/ 261.189/
          data  Ven(1, 633)/ 643.000/, Ven(2, 633)/ 261.160/
          data  Ven(1, 634)/ 644.000/, Ven(2, 634)/ 261.130/
          data  Ven(1, 635)/ 645.000/, Ven(2, 635)/ 261.101/
          data  Ven(1, 636)/ 646.000/, Ven(2, 636)/ 261.071/
          data  Ven(1, 637)/ 647.000/, Ven(2, 637)/ 261.042/
          data  Ven(1, 638)/ 648.000/, Ven(2, 638)/ 261.012/
          data  Ven(1, 639)/ 649.000/, Ven(2, 639)/ 260.983/
          data  Ven(1, 640)/ 650.000/, Ven(2, 640)/ 260.954/
          data  Ven(1, 641)/ 651.000/, Ven(2, 641)/ 260.925/
          data  Ven(1, 642)/ 652.000/, Ven(2, 642)/ 260.895/
          data  Ven(1, 643)/ 653.000/, Ven(2, 643)/ 260.866/
          data  Ven(1, 644)/ 654.000/, Ven(2, 644)/ 260.837/
          data  Ven(1, 645)/ 655.000/, Ven(2, 645)/ 260.808/
          data  Ven(1, 646)/ 656.000/, Ven(2, 646)/ 260.779/
          data  Ven(1, 647)/ 657.000/, Ven(2, 647)/ 260.750/
          data  Ven(1, 648)/ 658.000/, Ven(2, 648)/ 260.721/
          data  Ven(1, 649)/ 659.000/, Ven(2, 649)/ 260.693/
          data  Ven(1, 650)/ 660.000/, Ven(2, 650)/ 260.664/
          data  Ven(1, 651)/ 661.000/, Ven(2, 651)/ 260.635/
          data  Ven(1, 652)/ 662.000/, Ven(2, 652)/ 260.606/
          data  Ven(1, 653)/ 663.000/, Ven(2, 653)/ 260.578/
          data  Ven(1, 654)/ 664.000/, Ven(2, 654)/ 260.549/
          data  Ven(1, 655)/ 665.000/, Ven(2, 655)/ 260.521/
          data  Ven(1, 656)/ 666.000/, Ven(2, 656)/ 260.492/
          data  Ven(1, 657)/ 667.000/, Ven(2, 657)/ 260.464/
          data  Ven(1, 658)/ 668.000/, Ven(2, 658)/ 260.436/
          data  Ven(1, 659)/ 669.000/, Ven(2, 659)/ 260.407/
          data  Ven(1, 660)/ 670.000/, Ven(2, 660)/ 260.379/
          data  Ven(1, 661)/ 671.000/, Ven(2, 661)/ 260.351/
          data  Ven(1, 662)/ 672.000/, Ven(2, 662)/ 260.323/
          data  Ven(1, 663)/ 673.000/, Ven(2, 663)/ 260.295/
          data  Ven(1, 664)/ 674.000/, Ven(2, 664)/ 260.267/
          data  Ven(1, 665)/ 675.000/, Ven(2, 665)/ 260.239/
          data  Ven(1, 666)/ 676.000/, Ven(2, 666)/ 260.211/
          data  Ven(1, 667)/ 677.000/, Ven(2, 667)/ 260.183/
          data  Ven(1, 668)/ 678.000/, Ven(2, 668)/ 260.155/
          data  Ven(1, 669)/ 679.000/, Ven(2, 669)/ 260.127/
          data  Ven(1, 670)/ 680.000/, Ven(2, 670)/ 260.099/
          data  Ven(1, 671)/ 681.000/, Ven(2, 671)/ 260.072/
          data  Ven(1, 672)/ 682.000/, Ven(2, 672)/ 260.044/
          data  Ven(1, 673)/ 683.000/, Ven(2, 673)/ 260.016/
          data  Ven(1, 674)/ 684.000/, Ven(2, 674)/ 259.989/
          data  Ven(1, 675)/ 685.000/, Ven(2, 675)/ 259.961/
          data  Ven(1, 676)/ 686.000/, Ven(2, 676)/ 259.934/
          data  Ven(1, 677)/ 687.000/, Ven(2, 677)/ 259.906/
          data  Ven(1, 678)/ 688.000/, Ven(2, 678)/ 259.879/
          data  Ven(1, 679)/ 689.000/, Ven(2, 679)/ 259.852/
          data  Ven(1, 680)/ 690.000/, Ven(2, 680)/ 259.824/
          data  Ven(1, 681)/ 691.000/, Ven(2, 681)/ 259.797/
          data  Ven(1, 682)/ 692.000/, Ven(2, 682)/ 259.770/
          data  Ven(1, 683)/ 693.000/, Ven(2, 683)/ 259.742/
          data  Ven(1, 684)/ 694.000/, Ven(2, 684)/ 259.716/
          data  Ven(1, 685)/ 695.000/, Ven(2, 685)/ 259.688/
          data  Ven(1, 686)/ 696.000/, Ven(2, 686)/ 259.661/
          data  Ven(1, 687)/ 697.000/, Ven(2, 687)/ 259.634/
          data  Ven(1, 688)/ 698.000/, Ven(2, 688)/ 259.607/
          data  Ven(1, 689)/ 699.000/, Ven(2, 689)/ 259.580/
          data  Ven(1, 690)/ 700.000/, Ven(2, 690)/ 259.554/
          data  Ven(1, 691)/ 701.000/, Ven(2, 691)/ 259.527/
          data  Ven(1, 692)/ 702.000/, Ven(2, 692)/ 259.500/
          data  Ven(1, 693)/ 703.000/, Ven(2, 693)/ 259.473/
          data  Ven(1, 694)/ 704.000/, Ven(2, 694)/ 259.446/
          data  Ven(1, 695)/ 705.000/, Ven(2, 695)/ 259.420/
          data  Ven(1, 696)/ 706.000/, Ven(2, 696)/ 259.393/
          data  Ven(1, 697)/ 707.000/, Ven(2, 697)/ 259.367/
          data  Ven(1, 698)/ 708.000/, Ven(2, 698)/ 259.340/
          data  Ven(1, 699)/ 709.000/, Ven(2, 699)/ 259.313/
          data  Ven(1, 700)/ 710.000/, Ven(2, 700)/ 259.287/
          data  Ven(1, 701)/ 711.000/, Ven(2, 701)/ 259.261/
          data  Ven(1, 702)/ 712.000/, Ven(2, 702)/ 259.234/
          data  Ven(1, 703)/ 713.000/, Ven(2, 703)/ 259.208/
          data  Ven(1, 704)/ 714.000/, Ven(2, 704)/ 259.181/
          data  Ven(1, 705)/ 715.000/, Ven(2, 705)/ 259.155/
          data  Ven(1, 706)/ 716.000/, Ven(2, 706)/ 259.129/
          data  Ven(1, 707)/ 717.000/, Ven(2, 707)/ 259.103/
          data  Ven(1, 708)/ 718.000/, Ven(2, 708)/ 259.077/
          data  Ven(1, 709)/ 719.000/, Ven(2, 709)/ 259.050/
          data  Ven(1, 710)/ 720.000/, Ven(2, 710)/ 259.025/
          data  Ven(1, 711)/ 721.000/, Ven(2, 711)/ 258.999/
          data  Ven(1, 712)/ 722.000/, Ven(2, 712)/ 258.972/
          data  Ven(1, 713)/ 723.000/, Ven(2, 713)/ 258.947/
          data  Ven(1, 714)/ 724.000/, Ven(2, 714)/ 258.920/
          data  Ven(1, 715)/ 725.000/, Ven(2, 715)/ 258.895/
          data  Ven(1, 716)/ 726.000/, Ven(2, 716)/ 258.869/
          data  Ven(1, 717)/ 727.000/, Ven(2, 717)/ 258.843/
          data  Ven(1, 718)/ 728.000/, Ven(2, 718)/ 258.817/
          data  Ven(1, 719)/ 729.000/, Ven(2, 719)/ 258.792/
          data  Ven(1, 720)/ 730.000/, Ven(2, 720)/ 258.766/
          data  Ven(1, 721)/ 731.000/, Ven(2, 721)/ 258.740/
          data  Ven(1, 722)/ 732.000/, Ven(2, 722)/ 258.714/
          data  Ven(1, 723)/ 733.000/, Ven(2, 723)/ 258.689/
          data  Ven(1, 724)/ 734.000/, Ven(2, 724)/ 258.663/
          data  Ven(1, 725)/ 735.000/, Ven(2, 725)/ 258.638/
          data  Ven(1, 726)/ 736.000/, Ven(2, 726)/ 258.612/
          data  Ven(1, 727)/ 737.000/, Ven(2, 727)/ 258.587/
          data  Ven(1, 728)/ 738.000/, Ven(2, 728)/ 258.562/
          data  Ven(1, 729)/ 739.000/, Ven(2, 729)/ 258.536/
          data  Ven(1, 730)/ 740.000/, Ven(2, 730)/ 258.511/
          data  Ven(1, 731)/ 741.000/, Ven(2, 731)/ 258.486/
          data  Ven(1, 732)/ 742.000/, Ven(2, 732)/ 258.460/
          data  Ven(1, 733)/ 743.000/, Ven(2, 733)/ 258.435/
          data  Ven(1, 734)/ 744.000/, Ven(2, 734)/ 258.410/
          data  Ven(1, 735)/ 745.000/, Ven(2, 735)/ 258.385/
          data  Ven(1, 736)/ 746.000/, Ven(2, 736)/ 258.359/
          data  Ven(1, 737)/ 747.000/, Ven(2, 737)/ 258.334/
          data  Ven(1, 738)/ 748.000/, Ven(2, 738)/ 258.309/
          data  Ven(1, 739)/ 749.000/, Ven(2, 739)/ 258.284/
          data  Ven(1, 740)/ 750.000/, Ven(2, 740)/ 258.259/
          data  Ven(1, 741)/ 751.000/, Ven(2, 741)/ 258.234/
          data  Ven(1, 742)/ 752.000/, Ven(2, 742)/ 258.209/
          data  Ven(1, 743)/ 753.000/, Ven(2, 743)/ 258.184/
          data  Ven(1, 744)/ 754.000/, Ven(2, 744)/ 258.160/
          data  Ven(1, 745)/ 755.000/, Ven(2, 745)/ 258.135/
          data  Ven(1, 746)/ 756.000/, Ven(2, 746)/ 258.110/
          data  Ven(1, 747)/ 757.000/, Ven(2, 747)/ 258.085/
          data  Ven(1, 748)/ 758.000/, Ven(2, 748)/ 258.060/
          data  Ven(1, 749)/ 759.000/, Ven(2, 749)/ 258.036/
          data  Ven(1, 750)/ 760.000/, Ven(2, 750)/ 258.011/
          data  Ven(1, 751)/ 761.000/, Ven(2, 751)/ 257.986/
          data  Ven(1, 752)/ 762.000/, Ven(2, 752)/ 257.962/
          data  Ven(1, 753)/ 763.000/, Ven(2, 753)/ 257.937/
          data  Ven(1, 754)/ 764.000/, Ven(2, 754)/ 257.913/
          data  Ven(1, 755)/ 765.000/, Ven(2, 755)/ 257.888/
          data  Ven(1, 756)/ 766.000/, Ven(2, 756)/ 257.864/
          data  Ven(1, 757)/ 767.000/, Ven(2, 757)/ 257.839/
          data  Ven(1, 758)/ 768.000/, Ven(2, 758)/ 257.815/
          data  Ven(1, 759)/ 769.000/, Ven(2, 759)/ 257.790/
          data  Ven(1, 760)/ 770.000/, Ven(2, 760)/ 257.766/
          data  Ven(1, 761)/ 771.000/, Ven(2, 761)/ 257.742/
          data  Ven(1, 762)/ 772.000/, Ven(2, 762)/ 257.717/
          data  Ven(1, 763)/ 773.000/, Ven(2, 763)/ 257.693/
          data  Ven(1, 764)/ 774.000/, Ven(2, 764)/ 257.669/
          data  Ven(1, 765)/ 775.000/, Ven(2, 765)/ 257.645/
          data  Ven(1, 766)/ 776.000/, Ven(2, 766)/ 257.621/
          data  Ven(1, 767)/ 777.000/, Ven(2, 767)/ 257.596/
          data  Ven(1, 768)/ 778.000/, Ven(2, 768)/ 257.572/
          data  Ven(1, 769)/ 779.000/, Ven(2, 769)/ 257.548/
          data  Ven(1, 770)/ 780.000/, Ven(2, 770)/ 257.524/
          data  Ven(1, 771)/ 781.000/, Ven(2, 771)/ 257.500/
          data  Ven(1, 772)/ 782.000/, Ven(2, 772)/ 257.476/
          data  Ven(1, 773)/ 783.000/, Ven(2, 773)/ 257.452/
          data  Ven(1, 774)/ 784.000/, Ven(2, 774)/ 257.429/
          data  Ven(1, 775)/ 785.000/, Ven(2, 775)/ 257.405/
          data  Ven(1, 776)/ 786.000/, Ven(2, 776)/ 257.380/
          data  Ven(1, 777)/ 787.000/, Ven(2, 777)/ 257.357/
          data  Ven(1, 778)/ 788.000/, Ven(2, 778)/ 257.334/
          data  Ven(1, 779)/ 789.000/, Ven(2, 779)/ 257.310/
          data  Ven(1, 780)/ 790.000/, Ven(2, 780)/ 257.285/
          data  Ven(1, 781)/ 791.000/, Ven(2, 781)/ 257.262/
          data  Ven(1, 782)/ 792.000/, Ven(2, 782)/ 257.239/
          data  Ven(1, 783)/ 793.000/, Ven(2, 783)/ 257.215/
          data  Ven(1, 784)/ 794.000/, Ven(2, 784)/ 257.190/
          data  Ven(1, 785)/ 795.000/, Ven(2, 785)/ 257.167/
          data  Ven(1, 786)/ 796.000/, Ven(2, 786)/ 257.144/
          data  Ven(1, 787)/ 797.000/, Ven(2, 787)/ 257.120/
          data  Ven(1, 788)/ 798.000/, Ven(2, 788)/ 257.096/
          data  Ven(1, 789)/ 799.000/, Ven(2, 789)/ 257.073/
          data  Ven(1, 790)/ 800.000/, Ven(2, 790)/ 257.050/
          data  Ven(1, 791)/ 801.000/, Ven(2, 791)/ 257.026/
          data  Ven(1, 792)/ 802.000/, Ven(2, 792)/ 257.002/
          data  Ven(1, 793)/ 803.000/, Ven(2, 793)/ 256.979/
          data  Ven(1, 794)/ 804.000/, Ven(2, 794)/ 256.956/
          data  Ven(1, 795)/ 805.000/, Ven(2, 795)/ 256.933/
          data  Ven(1, 796)/ 806.000/, Ven(2, 796)/ 256.908/
          data  Ven(1, 797)/ 807.000/, Ven(2, 797)/ 256.886/
          data  Ven(1, 798)/ 808.000/, Ven(2, 798)/ 256.863/
          data  Ven(1, 799)/ 809.000/, Ven(2, 799)/ 256.839/
          data  Ven(1, 800)/ 810.000/, Ven(2, 800)/ 256.815/
          data  Ven(1, 801)/ 811.000/, Ven(2, 801)/ 256.793/
          data  Ven(1, 802)/ 812.000/, Ven(2, 802)/ 256.770/
          data  Ven(1, 803)/ 813.000/, Ven(2, 803)/ 256.747/
          data  Ven(1, 804)/ 814.000/, Ven(2, 804)/ 256.723/
          data  Ven(1, 805)/ 815.000/, Ven(2, 805)/ 256.700/
          data  Ven(1, 806)/ 816.000/, Ven(2, 806)/ 256.678/
          data  Ven(1, 807)/ 817.000/, Ven(2, 807)/ 256.654/
          data  Ven(1, 808)/ 818.000/, Ven(2, 808)/ 256.630/
          data  Ven(1, 809)/ 819.000/, Ven(2, 809)/ 256.608/
          data  Ven(1, 810)/ 820.000/, Ven(2, 810)/ 256.586/
          data  Ven(1, 811)/ 821.000/, Ven(2, 811)/ 256.562/
          data  Ven(1, 812)/ 822.000/, Ven(2, 812)/ 256.539/
          data  Ven(1, 813)/ 823.000/, Ven(2, 813)/ 256.517/
          data  Ven(1, 814)/ 824.000/, Ven(2, 814)/ 256.494/
          data  Ven(1, 815)/ 825.000/, Ven(2, 815)/ 256.471/
          data  Ven(1, 816)/ 826.000/, Ven(2, 816)/ 256.447/
          data  Ven(1, 817)/ 827.000/, Ven(2, 817)/ 256.425/
          data  Ven(1, 818)/ 828.000/, Ven(2, 818)/ 256.403/
          data  Ven(1, 819)/ 829.000/, Ven(2, 819)/ 256.380/
          data  Ven(1, 820)/ 830.000/, Ven(2, 820)/ 256.357/
          data  Ven(1, 821)/ 831.000/, Ven(2, 821)/ 256.335/
          data  Ven(1, 822)/ 832.000/, Ven(2, 822)/ 256.313/
          data  Ven(1, 823)/ 833.000/, Ven(2, 823)/ 256.290/
          data  Ven(1, 824)/ 834.000/, Ven(2, 824)/ 256.266/
          data  Ven(1, 825)/ 835.000/, Ven(2, 825)/ 256.245/
          data  Ven(1, 826)/ 836.000/, Ven(2, 826)/ 256.221/
          data  Ven(1, 827)/ 837.000/, Ven(2, 827)/ 256.200/
          data  Ven(1, 828)/ 838.000/, Ven(2, 828)/ 256.177/
          data  Ven(1, 829)/ 839.000/, Ven(2, 829)/ 256.153/
          data  Ven(1, 830)/ 840.000/, Ven(2, 830)/ 256.131/
          data  Ven(1, 831)/ 841.000/, Ven(2, 831)/ 256.109/
          data  Ven(1, 832)/ 842.000/, Ven(2, 832)/ 256.087/
          data  Ven(1, 833)/ 843.000/, Ven(2, 833)/ 256.064/
          data  Ven(1, 834)/ 844.000/, Ven(2, 834)/ 256.042/
          data  Ven(1, 835)/ 845.000/, Ven(2, 835)/ 256.020/
          data  Ven(1, 836)/ 846.000/, Ven(2, 836)/ 255.997/
          data  Ven(1, 837)/ 847.000/, Ven(2, 837)/ 255.976/
          data  Ven(1, 838)/ 848.000/, Ven(2, 838)/ 255.954/
          data  Ven(1, 839)/ 849.000/, Ven(2, 839)/ 255.931/
          data  Ven(1, 840)/ 850.000/, Ven(2, 840)/ 255.909/
          data  Ven(1, 841)/ 851.000/, Ven(2, 841)/ 255.886/
          data  Ven(1, 842)/ 852.000/, Ven(2, 842)/ 255.864/
          data  Ven(1, 843)/ 853.000/, Ven(2, 843)/ 255.842/
          data  Ven(1, 844)/ 854.000/, Ven(2, 844)/ 255.819/
          data  Ven(1, 845)/ 855.000/, Ven(2, 845)/ 255.798/
          data  Ven(1, 846)/ 856.000/, Ven(2, 846)/ 255.777/
          data  Ven(1, 847)/ 857.000/, Ven(2, 847)/ 255.753/
          data  Ven(1, 848)/ 858.000/, Ven(2, 848)/ 255.732/
          data  Ven(1, 849)/ 859.000/, Ven(2, 849)/ 255.709/
          data  Ven(1, 850)/ 860.000/, Ven(2, 850)/ 255.688/
          data  Ven(1, 851)/ 861.000/, Ven(2, 851)/ 255.666/
          data  Ven(1, 852)/ 862.000/, Ven(2, 852)/ 255.644/
          data  Ven(1, 853)/ 863.000/, Ven(2, 853)/ 255.621/
          data  Ven(1, 854)/ 864.000/, Ven(2, 854)/ 255.600/
          data  Ven(1, 855)/ 865.000/, Ven(2, 855)/ 255.578/
          data  Ven(1, 856)/ 866.000/, Ven(2, 856)/ 255.556/
          data  Ven(1, 857)/ 867.000/, Ven(2, 857)/ 255.534/
          data  Ven(1, 858)/ 868.000/, Ven(2, 858)/ 255.513/
          data  Ven(1, 859)/ 869.000/, Ven(2, 859)/ 255.491/
          data  Ven(1, 860)/ 870.000/, Ven(2, 860)/ 255.469/
          data  Ven(1, 861)/ 871.000/, Ven(2, 861)/ 255.447/
          data  Ven(1, 862)/ 872.000/, Ven(2, 862)/ 255.426/
          data  Ven(1, 863)/ 873.000/, Ven(2, 863)/ 255.404/
          data  Ven(1, 864)/ 874.000/, Ven(2, 864)/ 255.383/
          data  Ven(1, 865)/ 875.000/, Ven(2, 865)/ 255.360/
          data  Ven(1, 866)/ 876.000/, Ven(2, 866)/ 255.340/
          data  Ven(1, 867)/ 877.000/, Ven(2, 867)/ 255.318/
          data  Ven(1, 868)/ 878.000/, Ven(2, 868)/ 255.297/
          data  Ven(1, 869)/ 879.000/, Ven(2, 869)/ 255.275/
          data  Ven(1, 870)/ 880.000/, Ven(2, 870)/ 255.252/
          data  Ven(1, 871)/ 881.000/, Ven(2, 871)/ 255.231/
          data  Ven(1, 872)/ 882.000/, Ven(2, 872)/ 255.210/
          data  Ven(1, 873)/ 883.000/, Ven(2, 873)/ 255.188/
          data  Ven(1, 874)/ 884.000/, Ven(2, 874)/ 255.167/
          data  Ven(1, 875)/ 885.000/, Ven(2, 875)/ 255.146/
          data  Ven(1, 876)/ 886.000/, Ven(2, 876)/ 255.125/
          data  Ven(1, 877)/ 887.000/, Ven(2, 877)/ 255.103/
          data  Ven(1, 878)/ 888.000/, Ven(2, 878)/ 255.081/
          data  Ven(1, 879)/ 889.000/, Ven(2, 879)/ 255.060/
          data  Ven(1, 880)/ 890.000/, Ven(2, 880)/ 255.039/
          data  Ven(1, 881)/ 891.000/, Ven(2, 881)/ 255.018/
          data  Ven(1, 882)/ 892.000/, Ven(2, 882)/ 254.996/
          data  Ven(1, 883)/ 893.000/, Ven(2, 883)/ 254.975/
          data  Ven(1, 884)/ 894.000/, Ven(2, 884)/ 254.954/
          data  Ven(1, 885)/ 895.000/, Ven(2, 885)/ 254.933/
          data  Ven(1, 886)/ 896.000/, Ven(2, 886)/ 254.911/
          data  Ven(1, 887)/ 897.000/, Ven(2, 887)/ 254.891/
          data  Ven(1, 888)/ 898.000/, Ven(2, 888)/ 254.870/
          data  Ven(1, 889)/ 899.000/, Ven(2, 889)/ 254.849/
          data  Ven(1, 890)/ 900.000/, Ven(2, 890)/ 254.827/
          data  Ven(1, 891)/ 901.000/, Ven(2, 891)/ 254.807/
          data  Ven(1, 892)/ 902.000/, Ven(2, 892)/ 254.784/
          data  Ven(1, 893)/ 903.000/, Ven(2, 893)/ 254.763/
          data  Ven(1, 894)/ 904.000/, Ven(2, 894)/ 254.744/
          data  Ven(1, 895)/ 905.000/, Ven(2, 895)/ 254.722/
          data  Ven(1, 896)/ 906.000/, Ven(2, 896)/ 254.701/
          data  Ven(1, 897)/ 907.000/, Ven(2, 897)/ 254.680/
          data  Ven(1, 898)/ 908.000/, Ven(2, 898)/ 254.659/
          data  Ven(1, 899)/ 909.000/, Ven(2, 899)/ 254.638/
          data  Ven(1, 900)/ 910.000/, Ven(2, 900)/ 254.617/
          data  Ven(1, 901)/ 911.000/, Ven(2, 901)/ 254.597/
          data  Ven(1, 902)/ 912.000/, Ven(2, 902)/ 254.576/
          data  Ven(1, 903)/ 913.000/, Ven(2, 903)/ 254.554/
          data  Ven(1, 904)/ 914.000/, Ven(2, 904)/ 254.534/
          data  Ven(1, 905)/ 915.000/, Ven(2, 905)/ 254.513/
          data  Ven(1, 906)/ 916.000/, Ven(2, 906)/ 254.492/
          data  Ven(1, 907)/ 917.000/, Ven(2, 907)/ 254.471/
          data  Ven(1, 908)/ 918.000/, Ven(2, 908)/ 254.451/
          data  Ven(1, 909)/ 919.000/, Ven(2, 909)/ 254.431/
          data  Ven(1, 910)/ 920.000/, Ven(2, 910)/ 254.410/
          data  Ven(1, 911)/ 921.000/, Ven(2, 911)/ 254.389/
          data  Ven(1, 912)/ 922.000/, Ven(2, 912)/ 254.368/
          data  Ven(1, 913)/ 923.000/, Ven(2, 913)/ 254.347/
          data  Ven(1, 914)/ 924.000/, Ven(2, 914)/ 254.327/
          data  Ven(1, 915)/ 925.000/, Ven(2, 915)/ 254.306/
          data  Ven(1, 916)/ 926.000/, Ven(2, 916)/ 254.286/
          data  Ven(1, 917)/ 927.000/, Ven(2, 917)/ 254.265/
          data  Ven(1, 918)/ 928.000/, Ven(2, 918)/ 254.244/
          data  Ven(1, 919)/ 929.000/, Ven(2, 919)/ 254.224/
          data  Ven(1, 920)/ 930.000/, Ven(2, 920)/ 254.204/
          data  Ven(1, 921)/ 931.000/, Ven(2, 921)/ 254.183/
          data  Ven(1, 922)/ 932.000/, Ven(2, 922)/ 254.163/
          data  Ven(1, 923)/ 933.000/, Ven(2, 923)/ 254.142/
          data  Ven(1, 924)/ 934.000/, Ven(2, 924)/ 254.121/
          data  Ven(1, 925)/ 935.000/, Ven(2, 925)/ 254.102/
          data  Ven(1, 926)/ 936.000/, Ven(2, 926)/ 254.082/
          data  Ven(1, 927)/ 937.000/, Ven(2, 927)/ 254.061/
          data  Ven(1, 928)/ 938.000/, Ven(2, 928)/ 254.041/
          data  Ven(1, 929)/ 939.000/, Ven(2, 929)/ 254.020/
          data  Ven(1, 930)/ 940.000/, Ven(2, 930)/ 254.000/
          data  Ven(1, 931)/ 941.000/, Ven(2, 931)/ 253.980/
          data  Ven(1, 932)/ 942.000/, Ven(2, 932)/ 253.959/
          data  Ven(1, 933)/ 943.000/, Ven(2, 933)/ 253.940/
          data  Ven(1, 934)/ 944.000/, Ven(2, 934)/ 253.919/
          data  Ven(1, 935)/ 945.000/, Ven(2, 935)/ 253.899/
          data  Ven(1, 936)/ 946.000/, Ven(2, 936)/ 253.878/
          data  Ven(1, 937)/ 947.000/, Ven(2, 937)/ 253.858/
          data  Ven(1, 938)/ 948.000/, Ven(2, 938)/ 253.838/
          data  Ven(1, 939)/ 949.000/, Ven(2, 939)/ 253.819/
          data  Ven(1, 940)/ 950.000/, Ven(2, 940)/ 253.798/
          data  Ven(1, 941)/ 951.000/, Ven(2, 941)/ 253.778/
          data  Ven(1, 942)/ 952.000/, Ven(2, 942)/ 253.757/
          data  Ven(1, 943)/ 953.000/, Ven(2, 943)/ 253.738/
          data  Ven(1, 944)/ 954.000/, Ven(2, 944)/ 253.718/
          data  Ven(1, 945)/ 955.000/, Ven(2, 945)/ 253.697/
          data  Ven(1, 946)/ 956.000/, Ven(2, 946)/ 253.678/
          data  Ven(1, 947)/ 957.000/, Ven(2, 947)/ 253.657/
          data  Ven(1, 948)/ 958.000/, Ven(2, 948)/ 253.638/
          data  Ven(1, 949)/ 959.000/, Ven(2, 949)/ 253.618/
          data  Ven(1, 950)/ 960.000/, Ven(2, 950)/ 253.597/
          data  Ven(1, 951)/ 961.000/, Ven(2, 951)/ 253.578/
          data  Ven(1, 952)/ 962.000/, Ven(2, 952)/ 253.559/
          data  Ven(1, 953)/ 963.000/, Ven(2, 953)/ 253.539/
          data  Ven(1, 954)/ 964.000/, Ven(2, 954)/ 253.518/
          data  Ven(1, 955)/ 965.000/, Ven(2, 955)/ 253.498/
          data  Ven(1, 956)/ 966.000/, Ven(2, 956)/ 253.479/
          data  Ven(1, 957)/ 967.000/, Ven(2, 957)/ 253.459/
          data  Ven(1, 958)/ 968.000/, Ven(2, 958)/ 253.439/
          data  Ven(1, 959)/ 969.000/, Ven(2, 959)/ 253.419/
          data  Ven(1, 960)/ 970.000/, Ven(2, 960)/ 253.400/
          data  Ven(1, 961)/ 971.000/, Ven(2, 961)/ 253.380/
          data  Ven(1, 962)/ 972.000/, Ven(2, 962)/ 253.360/
          data  Ven(1, 963)/ 973.000/, Ven(2, 963)/ 253.340/
          data  Ven(1, 964)/ 974.000/, Ven(2, 964)/ 253.321/
          data  Ven(1, 965)/ 975.000/, Ven(2, 965)/ 253.300/
          data  Ven(1, 966)/ 976.000/, Ven(2, 966)/ 253.281/
          data  Ven(1, 967)/ 977.000/, Ven(2, 967)/ 253.262/
          data  Ven(1, 968)/ 978.000/, Ven(2, 968)/ 253.242/
          data  Ven(1, 969)/ 979.000/, Ven(2, 969)/ 253.223/
          data  Ven(1, 970)/ 980.000/, Ven(2, 970)/ 253.204/
          data  Ven(1, 971)/ 981.000/, Ven(2, 971)/ 253.184/
          data  Ven(1, 972)/ 982.000/, Ven(2, 972)/ 253.164/
          data  Ven(1, 973)/ 983.000/, Ven(2, 973)/ 253.145/
          data  Ven(1, 974)/ 984.000/, Ven(2, 974)/ 253.124/
          data  Ven(1, 975)/ 985.000/, Ven(2, 975)/ 253.105/
          data  Ven(1, 976)/ 986.000/, Ven(2, 976)/ 253.087/
          data  Ven(1, 977)/ 987.000/, Ven(2, 977)/ 253.067/
          data  Ven(1, 978)/ 988.000/, Ven(2, 978)/ 253.048/
          data  Ven(1, 979)/ 989.000/, Ven(2, 979)/ 253.028/
          data  Ven(1, 980)/ 990.000/, Ven(2, 980)/ 253.009/
          data  Ven(1, 981)/ 991.000/, Ven(2, 981)/ 252.989/
          data  Ven(1, 982)/ 992.000/, Ven(2, 982)/ 252.970/
          data  Ven(1, 983)/ 993.000/, Ven(2, 983)/ 252.949/
          data  Ven(1, 984)/ 994.000/, Ven(2, 984)/ 252.931/
          data  Ven(1, 985)/ 995.000/, Ven(2, 985)/ 252.912/
          data  Ven(1, 986)/ 996.000/, Ven(2, 986)/ 252.892/
          data  Ven(1, 987)/ 997.000/, Ven(2, 987)/ 252.873/
          data  Ven(1, 988)/ 998.000/, Ven(2, 988)/ 252.854/
          data  Ven(1, 989)/ 999.000/, Ven(2, 989)/ 252.834/
          data  Ven(1, 990)/1000.000/, Ven(2, 990)/ 252.816/
c++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c!Jupiter model - from Eric Weisstein's JOVIAN
c!H2 type: intermediate-frozen
c!H2 form: D&B
c!He form: D&B
c!H2 mxr: 0.897
c!PH3 mxr: 5.E-07 for  p > 2.5E-01 bar
c!NH3 mxr: 8.E-5 (half of normal!)
c                            Freq(GHz)          WDTB(Kelvin)
          data  Jup(1,   1)/  11.000/, Jup(2,   1)/ 191.207/
          data  Jup(1,   2)/  12.000/, Jup(2,   2)/ 182.402/
          data  Jup(1,   3)/  13.000/, Jup(2,   3)/ 174.351/
          data  Jup(1,   4)/  14.000/, Jup(2,   4)/ 167.052/
          data  Jup(1,   5)/  15.000/, Jup(2,   5)/ 160.495/
          data  Jup(1,   6)/  16.000/, Jup(2,   6)/ 154.659/
          data  Jup(1,   7)/  17.000/, Jup(2,   7)/ 149.534/
          data  Jup(1,   8)/  18.000/, Jup(2,   8)/ 145.097/
          data  Jup(1,   9)/  19.000/, Jup(2,   9)/ 141.279/
          data  Jup(1,  10)/  20.000/, Jup(2,  10)/ 137.920/
          data  Jup(1,  11)/  21.000/, Jup(2,  11)/ 134.784/
          data  Jup(1,  12)/  22.000/, Jup(2,  12)/ 131.728/
          data  Jup(1,  13)/  23.000/, Jup(2,  13)/ 128.923/
          data  Jup(1,  14)/  24.000/, Jup(2,  14)/ 127.653/
          data  Jup(1,  15)/  25.000/, Jup(2,  15)/ 129.440/
          data  Jup(1,  16)/  26.000/, Jup(2,  16)/ 131.916/
          data  Jup(1,  17)/  27.000/, Jup(2,  17)/ 134.190/
          data  Jup(1,  18)/  28.000/, Jup(2,  18)/ 136.143/
          data  Jup(1,  19)/  29.000/, Jup(2,  19)/ 137.856/
          data  Jup(1,  20)/  30.000/, Jup(2,  20)/ 139.392/
          data  Jup(1,  21)/  31.000/, Jup(2,  21)/ 140.793/
          data  Jup(1,  22)/  32.000/, Jup(2,  22)/ 142.092/
          data  Jup(1,  23)/  33.000/, Jup(2,  23)/ 143.305/
          data  Jup(1,  24)/  34.000/, Jup(2,  24)/ 144.443/
          data  Jup(1,  25)/  35.000/, Jup(2,  25)/ 145.515/
          data  Jup(1,  26)/  36.000/, Jup(2,  26)/ 146.523/
          data  Jup(1,  27)/  37.000/, Jup(2,  27)/ 147.474/
          data  Jup(1,  28)/  38.000/, Jup(2,  28)/ 148.371/
          data  Jup(1,  29)/  39.000/, Jup(2,  29)/ 149.217/
          data  Jup(1,  30)/  40.000/, Jup(2,  30)/ 150.015/
          data  Jup(1,  31)/  41.000/, Jup(2,  31)/ 150.769/
          data  Jup(1,  32)/  42.000/, Jup(2,  32)/ 151.480/
          data  Jup(1,  33)/  43.000/, Jup(2,  33)/ 152.153/
          data  Jup(1,  34)/  44.000/, Jup(2,  34)/ 152.788/
          data  Jup(1,  35)/  45.000/, Jup(2,  35)/ 153.389/
          data  Jup(1,  36)/  46.000/, Jup(2,  36)/ 153.958/
          data  Jup(1,  37)/  47.000/, Jup(2,  37)/ 154.497/
          data  Jup(1,  38)/  48.000/, Jup(2,  38)/ 155.007/
          data  Jup(1,  39)/  49.000/, Jup(2,  39)/ 155.491/
          data  Jup(1,  40)/  50.000/, Jup(2,  40)/ 155.950/
          data  Jup(1,  41)/  51.000/, Jup(2,  41)/ 156.386/
          data  Jup(1,  42)/  52.000/, Jup(2,  42)/ 156.800/
          data  Jup(1,  43)/  53.000/, Jup(2,  43)/ 157.194/
          data  Jup(1,  44)/  54.000/, Jup(2,  44)/ 157.569/
          data  Jup(1,  45)/  55.000/, Jup(2,  45)/ 157.926/
          data  Jup(1,  46)/  56.000/, Jup(2,  46)/ 158.265/
          data  Jup(1,  47)/  57.000/, Jup(2,  47)/ 158.589/
          data  Jup(1,  48)/  58.000/, Jup(2,  48)/ 158.898/
          data  Jup(1,  49)/  59.000/, Jup(2,  49)/ 159.192/
          data  Jup(1,  50)/  60.000/, Jup(2,  50)/ 159.474/
          data  Jup(1,  51)/  61.000/, Jup(2,  51)/ 159.742/
          data  Jup(1,  52)/  62.000/, Jup(2,  52)/ 159.999/
          data  Jup(1,  53)/  63.000/, Jup(2,  53)/ 160.245/
          data  Jup(1,  54)/  64.000/, Jup(2,  54)/ 160.479/
          data  Jup(1,  55)/  65.000/, Jup(2,  55)/ 160.704/
          data  Jup(1,  56)/  66.000/, Jup(2,  56)/ 160.920/
          data  Jup(1,  57)/  67.000/, Jup(2,  57)/ 161.126/
          data  Jup(1,  58)/  68.000/, Jup(2,  58)/ 161.324/
          data  Jup(1,  59)/  69.000/, Jup(2,  59)/ 161.514/
          data  Jup(1,  60)/  70.000/, Jup(2,  60)/ 161.697/
          data  Jup(1,  61)/  71.000/, Jup(2,  61)/ 161.872/
          data  Jup(1,  62)/  72.000/, Jup(2,  62)/ 162.040/
          data  Jup(1,  63)/  73.000/, Jup(2,  63)/ 162.201/
          data  Jup(1,  64)/  74.000/, Jup(2,  64)/ 162.356/
          data  Jup(1,  65)/  75.000/, Jup(2,  65)/ 162.506/
          data  Jup(1,  66)/  76.000/, Jup(2,  66)/ 162.650/
          data  Jup(1,  67)/  77.000/, Jup(2,  67)/ 162.788/
          data  Jup(1,  68)/  78.000/, Jup(2,  68)/ 162.922/
          data  Jup(1,  69)/  79.000/, Jup(2,  69)/ 163.050/
          data  Jup(1,  70)/  80.000/, Jup(2,  70)/ 163.173/
          data  Jup(1,  71)/  81.000/, Jup(2,  71)/ 163.293/
          data  Jup(1,  72)/  82.000/, Jup(2,  72)/ 163.408/
          data  Jup(1,  73)/  83.000/, Jup(2,  73)/ 163.519/
          data  Jup(1,  74)/  84.000/, Jup(2,  74)/ 163.625/
          data  Jup(1,  75)/  85.000/, Jup(2,  75)/ 163.729/
          data  Jup(1,  76)/  86.000/, Jup(2,  76)/ 163.828/
          data  Jup(1,  77)/  87.000/, Jup(2,  77)/ 163.925/
          data  Jup(1,  78)/  88.000/, Jup(2,  78)/ 164.018/
          data  Jup(1,  79)/  89.000/, Jup(2,  79)/ 164.108/
          data  Jup(1,  80)/  90.000/, Jup(2,  80)/ 164.195/
          data  Jup(1,  81)/  91.000/, Jup(2,  81)/ 164.279/
          data  Jup(1,  82)/  92.000/, Jup(2,  82)/ 164.360/
          data  Jup(1,  83)/  93.000/, Jup(2,  83)/ 164.439/
          data  Jup(1,  84)/  94.000/, Jup(2,  84)/ 164.514/
          data  Jup(1,  85)/  95.000/, Jup(2,  85)/ 164.588/
          data  Jup(1,  86)/  96.000/, Jup(2,  86)/ 164.659/
          data  Jup(1,  87)/  97.000/, Jup(2,  87)/ 164.728/
          data  Jup(1,  88)/  98.000/, Jup(2,  88)/ 164.795/
          data  Jup(1,  89)/  99.000/, Jup(2,  89)/ 164.860/
          data  Jup(1,  90)/ 100.000/, Jup(2,  90)/ 164.922/
          data  Jup(1,  91)/ 101.000/, Jup(2,  91)/ 164.983/
          data  Jup(1,  92)/ 102.000/, Jup(2,  92)/ 165.042/
          data  Jup(1,  93)/ 103.000/, Jup(2,  93)/ 165.099/
          data  Jup(1,  94)/ 104.000/, Jup(2,  94)/ 165.155/
          data  Jup(1,  95)/ 105.000/, Jup(2,  95)/ 165.208/
          data  Jup(1,  96)/ 106.000/, Jup(2,  96)/ 165.260/
          data  Jup(1,  97)/ 107.000/, Jup(2,  97)/ 165.311/
          data  Jup(1,  98)/ 108.000/, Jup(2,  98)/ 165.360/
          data  Jup(1,  99)/ 109.000/, Jup(2,  99)/ 165.407/
          data  Jup(1, 100)/ 110.000/, Jup(2, 100)/ 165.453/
          data  Jup(1, 101)/ 111.000/, Jup(2, 101)/ 165.498/
          data  Jup(1, 102)/ 112.000/, Jup(2, 102)/ 165.542/
          data  Jup(1, 103)/ 113.000/, Jup(2, 103)/ 165.584/
          data  Jup(1, 104)/ 114.000/, Jup(2, 104)/ 165.624/
          data  Jup(1, 105)/ 115.000/, Jup(2, 105)/ 165.663/
          data  Jup(1, 106)/ 116.000/, Jup(2, 106)/ 165.702/
          data  Jup(1, 107)/ 117.000/, Jup(2, 107)/ 165.740/
          data  Jup(1, 108)/ 118.000/, Jup(2, 108)/ 165.776/
          data  Jup(1, 109)/ 119.000/, Jup(2, 109)/ 165.811/
          data  Jup(1, 110)/ 120.000/, Jup(2, 110)/ 165.846/
          data  Jup(1, 111)/ 121.000/, Jup(2, 111)/ 165.879/
          data  Jup(1, 112)/ 122.000/, Jup(2, 112)/ 165.911/
          data  Jup(1, 113)/ 123.000/, Jup(2, 113)/ 165.943/
          data  Jup(1, 114)/ 124.000/, Jup(2, 114)/ 165.973/
          data  Jup(1, 115)/ 125.000/, Jup(2, 115)/ 166.003/
          data  Jup(1, 116)/ 126.000/, Jup(2, 116)/ 166.032/
          data  Jup(1, 117)/ 127.000/, Jup(2, 117)/ 166.060/
          data  Jup(1, 118)/ 128.000/, Jup(2, 118)/ 166.087/
          data  Jup(1, 119)/ 129.000/, Jup(2, 119)/ 166.113/
          data  Jup(1, 120)/ 130.000/, Jup(2, 120)/ 166.139/
          data  Jup(1, 121)/ 131.000/, Jup(2, 121)/ 166.164/
          data  Jup(1, 122)/ 132.000/, Jup(2, 122)/ 166.187/
          data  Jup(1, 123)/ 133.000/, Jup(2, 123)/ 166.211/
          data  Jup(1, 124)/ 134.000/, Jup(2, 124)/ 166.234/
          data  Jup(1, 125)/ 135.000/, Jup(2, 125)/ 166.256/
          data  Jup(1, 126)/ 136.000/, Jup(2, 126)/ 166.277/
          data  Jup(1, 127)/ 137.000/, Jup(2, 127)/ 166.298/
          data  Jup(1, 128)/ 138.000/, Jup(2, 128)/ 166.318/
          data  Jup(1, 129)/ 139.000/, Jup(2, 129)/ 166.338/
          data  Jup(1, 130)/ 140.000/, Jup(2, 130)/ 166.357/
          data  Jup(1, 131)/ 141.000/, Jup(2, 131)/ 166.376/
          data  Jup(1, 132)/ 142.000/, Jup(2, 132)/ 166.394/
          data  Jup(1, 133)/ 143.000/, Jup(2, 133)/ 166.411/
          data  Jup(1, 134)/ 144.000/, Jup(2, 134)/ 166.428/
          data  Jup(1, 135)/ 145.000/, Jup(2, 135)/ 166.444/
          data  Jup(1, 136)/ 146.000/, Jup(2, 136)/ 166.460/
          data  Jup(1, 137)/ 147.000/, Jup(2, 137)/ 166.475/
          data  Jup(1, 138)/ 148.000/, Jup(2, 138)/ 166.490/
          data  Jup(1, 139)/ 149.000/, Jup(2, 139)/ 166.504/
          data  Jup(1, 140)/ 150.000/, Jup(2, 140)/ 166.518/
          data  Jup(1, 141)/ 151.000/, Jup(2, 141)/ 166.532/
          data  Jup(1, 142)/ 152.000/, Jup(2, 142)/ 166.545/
          data  Jup(1, 143)/ 153.000/, Jup(2, 143)/ 166.558/
          data  Jup(1, 144)/ 154.000/, Jup(2, 144)/ 166.570/
          data  Jup(1, 145)/ 155.000/, Jup(2, 145)/ 166.581/
          data  Jup(1, 146)/ 156.000/, Jup(2, 146)/ 166.592/
          data  Jup(1, 147)/ 157.000/, Jup(2, 147)/ 166.604/
          data  Jup(1, 148)/ 158.000/, Jup(2, 148)/ 166.614/
          data  Jup(1, 149)/ 159.000/, Jup(2, 149)/ 166.624/
          data  Jup(1, 150)/ 160.000/, Jup(2, 150)/ 166.634/
          data  Jup(1, 151)/ 161.000/, Jup(2, 151)/ 166.644/
          data  Jup(1, 152)/ 162.000/, Jup(2, 152)/ 166.653/
          data  Jup(1, 153)/ 163.000/, Jup(2, 153)/ 166.662/
          data  Jup(1, 154)/ 164.000/, Jup(2, 154)/ 166.670/
          data  Jup(1, 155)/ 165.000/, Jup(2, 155)/ 166.678/
          data  Jup(1, 156)/ 166.000/, Jup(2, 156)/ 166.686/
          data  Jup(1, 157)/ 167.000/, Jup(2, 157)/ 166.694/
          data  Jup(1, 158)/ 168.000/, Jup(2, 158)/ 166.701/
          data  Jup(1, 159)/ 169.000/, Jup(2, 159)/ 166.707/
          data  Jup(1, 160)/ 170.000/, Jup(2, 160)/ 166.714/
          data  Jup(1, 161)/ 171.000/, Jup(2, 161)/ 166.720/
          data  Jup(1, 162)/ 172.000/, Jup(2, 162)/ 166.726/
          data  Jup(1, 163)/ 173.000/, Jup(2, 163)/ 166.732/
          data  Jup(1, 164)/ 174.000/, Jup(2, 164)/ 166.737/
          data  Jup(1, 165)/ 175.000/, Jup(2, 165)/ 166.741/
          data  Jup(1, 166)/ 176.000/, Jup(2, 166)/ 166.746/
          data  Jup(1, 167)/ 177.000/, Jup(2, 167)/ 166.751/
          data  Jup(1, 168)/ 178.000/, Jup(2, 168)/ 166.755/
          data  Jup(1, 169)/ 179.000/, Jup(2, 169)/ 166.759/
          data  Jup(1, 170)/ 180.000/, Jup(2, 170)/ 166.763/
          data  Jup(1, 171)/ 181.000/, Jup(2, 171)/ 166.766/
          data  Jup(1, 172)/ 182.000/, Jup(2, 172)/ 166.770/
          data  Jup(1, 173)/ 183.000/, Jup(2, 173)/ 166.772/
          data  Jup(1, 174)/ 184.000/, Jup(2, 174)/ 166.775/
          data  Jup(1, 175)/ 185.000/, Jup(2, 175)/ 166.777/
          data  Jup(1, 176)/ 186.000/, Jup(2, 176)/ 166.779/
          data  Jup(1, 177)/ 187.000/, Jup(2, 177)/ 166.781/
          data  Jup(1, 178)/ 188.000/, Jup(2, 178)/ 166.783/
          data  Jup(1, 179)/ 189.000/, Jup(2, 179)/ 166.784/
          data  Jup(1, 180)/ 190.000/, Jup(2, 180)/ 166.786/
          data  Jup(1, 181)/ 191.000/, Jup(2, 181)/ 166.786/
          data  Jup(1, 182)/ 192.000/, Jup(2, 182)/ 166.787/
          data  Jup(1, 183)/ 193.000/, Jup(2, 183)/ 166.788/
          data  Jup(1, 184)/ 194.000/, Jup(2, 184)/ 166.788/
          data  Jup(1, 185)/ 195.000/, Jup(2, 185)/ 166.788/
          data  Jup(1, 186)/ 196.000/, Jup(2, 186)/ 166.788/
          data  Jup(1, 187)/ 197.000/, Jup(2, 187)/ 166.788/
          data  Jup(1, 188)/ 198.000/, Jup(2, 188)/ 166.787/
          data  Jup(1, 189)/ 199.000/, Jup(2, 189)/ 166.786/
          data  Jup(1, 190)/ 200.000/, Jup(2, 190)/ 166.785/
          data  Jup(1, 191)/ 201.000/, Jup(2, 191)/ 166.784/
          data  Jup(1, 192)/ 202.000/, Jup(2, 192)/ 166.782/
          data  Jup(1, 193)/ 203.000/, Jup(2, 193)/ 166.781/
          data  Jup(1, 194)/ 204.000/, Jup(2, 194)/ 166.779/
          data  Jup(1, 195)/ 205.000/, Jup(2, 195)/ 166.777/
          data  Jup(1, 196)/ 206.000/, Jup(2, 196)/ 166.775/
          data  Jup(1, 197)/ 207.000/, Jup(2, 197)/ 166.772/
          data  Jup(1, 198)/ 208.000/, Jup(2, 198)/ 166.770/
          data  Jup(1, 199)/ 209.000/, Jup(2, 199)/ 166.767/
          data  Jup(1, 200)/ 210.000/, Jup(2, 200)/ 166.763/
          data  Jup(1, 201)/ 211.000/, Jup(2, 201)/ 166.760/
          data  Jup(1, 202)/ 212.000/, Jup(2, 202)/ 166.756/
          data  Jup(1, 203)/ 213.000/, Jup(2, 203)/ 166.753/
          data  Jup(1, 204)/ 214.000/, Jup(2, 204)/ 166.749/
          data  Jup(1, 205)/ 215.000/, Jup(2, 205)/ 166.744/
          data  Jup(1, 206)/ 216.000/, Jup(2, 206)/ 166.740/
          data  Jup(1, 207)/ 217.000/, Jup(2, 207)/ 166.735/
          data  Jup(1, 208)/ 218.000/, Jup(2, 208)/ 166.730/
          data  Jup(1, 209)/ 219.000/, Jup(2, 209)/ 166.725/
          data  Jup(1, 210)/ 220.000/, Jup(2, 210)/ 166.720/
          data  Jup(1, 211)/ 221.000/, Jup(2, 211)/ 166.714/
          data  Jup(1, 212)/ 222.000/, Jup(2, 212)/ 166.708/
          data  Jup(1, 213)/ 223.000/, Jup(2, 213)/ 166.702/
          data  Jup(1, 214)/ 224.000/, Jup(2, 214)/ 166.695/
          data  Jup(1, 215)/ 225.000/, Jup(2, 215)/ 166.689/
          data  Jup(1, 216)/ 226.000/, Jup(2, 216)/ 166.681/
          data  Jup(1, 217)/ 227.000/, Jup(2, 217)/ 166.674/
          data  Jup(1, 218)/ 228.000/, Jup(2, 218)/ 166.666/
          data  Jup(1, 219)/ 229.000/, Jup(2, 219)/ 166.657/
          data  Jup(1, 220)/ 230.000/, Jup(2, 220)/ 166.644/
          data  Jup(1, 221)/ 231.000/, Jup(2, 221)/ 166.636/
          data  Jup(1, 222)/ 232.000/, Jup(2, 222)/ 166.631/
          data  Jup(1, 223)/ 233.000/, Jup(2, 223)/ 166.624/
          data  Jup(1, 224)/ 234.000/, Jup(2, 224)/ 166.615/
          data  Jup(1, 225)/ 235.000/, Jup(2, 225)/ 166.605/
          data  Jup(1, 226)/ 236.000/, Jup(2, 226)/ 166.595/
          data  Jup(1, 227)/ 237.000/, Jup(2, 227)/ 166.584/
          data  Jup(1, 228)/ 238.000/, Jup(2, 228)/ 166.572/
          data  Jup(1, 229)/ 239.000/, Jup(2, 229)/ 166.560/
          data  Jup(1, 230)/ 240.000/, Jup(2, 230)/ 166.548/
          data  Jup(1, 231)/ 241.000/, Jup(2, 231)/ 166.534/
          data  Jup(1, 232)/ 242.000/, Jup(2, 232)/ 166.519/
          data  Jup(1, 233)/ 243.000/, Jup(2, 233)/ 166.504/
          data  Jup(1, 234)/ 244.000/, Jup(2, 234)/ 166.488/
          data  Jup(1, 235)/ 245.000/, Jup(2, 235)/ 166.470/
          data  Jup(1, 236)/ 246.000/, Jup(2, 236)/ 166.451/
          data  Jup(1, 237)/ 247.000/, Jup(2, 237)/ 166.429/
          data  Jup(1, 238)/ 248.000/, Jup(2, 238)/ 166.406/
          data  Jup(1, 239)/ 249.000/, Jup(2, 239)/ 166.380/
          data  Jup(1, 240)/ 250.000/, Jup(2, 240)/ 166.352/
          data  Jup(1, 241)/ 251.000/, Jup(2, 241)/ 166.320/
          data  Jup(1, 242)/ 252.000/, Jup(2, 242)/ 166.282/
          data  Jup(1, 243)/ 253.000/, Jup(2, 243)/ 166.239/
          data  Jup(1, 244)/ 254.000/, Jup(2, 244)/ 166.190/
          data  Jup(1, 245)/ 255.000/, Jup(2, 245)/ 166.130/
          data  Jup(1, 246)/ 256.000/, Jup(2, 246)/ 166.058/
          data  Jup(1, 247)/ 257.000/, Jup(2, 247)/ 165.968/
          data  Jup(1, 248)/ 258.000/, Jup(2, 248)/ 165.855/
          data  Jup(1, 249)/ 259.000/, Jup(2, 249)/ 165.709/
          data  Jup(1, 250)/ 260.000/, Jup(2, 250)/ 165.513/
          data  Jup(1, 251)/ 261.000/, Jup(2, 251)/ 165.244/
          data  Jup(1, 252)/ 262.000/, Jup(2, 252)/ 164.860/
          data  Jup(1, 253)/ 263.000/, Jup(2, 253)/ 164.291/
          data  Jup(1, 254)/ 264.000/, Jup(2, 254)/ 163.421/
          data  Jup(1, 255)/ 265.000/, Jup(2, 255)/ 162.080/
          data  Jup(1, 256)/ 266.000/, Jup(2, 256)/ 160.263/
          data  Jup(1, 257)/ 267.000/, Jup(2, 257)/ 159.209/
          data  Jup(1, 258)/ 268.000/, Jup(2, 258)/ 160.446/
          data  Jup(1, 259)/ 269.000/, Jup(2, 259)/ 162.212/
          data  Jup(1, 260)/ 270.000/, Jup(2, 260)/ 163.470/
          data  Jup(1, 261)/ 271.000/, Jup(2, 261)/ 164.276/
          data  Jup(1, 262)/ 272.000/, Jup(2, 262)/ 164.795/
          data  Jup(1, 263)/ 273.000/, Jup(2, 263)/ 165.139/
          data  Jup(1, 264)/ 274.000/, Jup(2, 264)/ 165.373/
          data  Jup(1, 265)/ 275.000/, Jup(2, 265)/ 165.538/
          data  Jup(1, 266)/ 276.000/, Jup(2, 266)/ 165.656/
          data  Jup(1, 267)/ 277.000/, Jup(2, 267)/ 165.741/
          data  Jup(1, 268)/ 278.000/, Jup(2, 268)/ 165.804/
          data  Jup(1, 269)/ 279.000/, Jup(2, 269)/ 165.849/
          data  Jup(1, 270)/ 280.000/, Jup(2, 270)/ 165.883/
          data  Jup(1, 271)/ 281.000/, Jup(2, 271)/ 165.908/
          data  Jup(1, 272)/ 282.000/, Jup(2, 272)/ 165.926/
          data  Jup(1, 273)/ 283.000/, Jup(2, 273)/ 165.937/
          data  Jup(1, 274)/ 284.000/, Jup(2, 274)/ 165.945/
          data  Jup(1, 275)/ 285.000/, Jup(2, 275)/ 165.948/
          data  Jup(1, 276)/ 286.000/, Jup(2, 276)/ 165.949/
          data  Jup(1, 277)/ 287.000/, Jup(2, 277)/ 165.947/
          data  Jup(1, 278)/ 288.000/, Jup(2, 278)/ 165.944/
          data  Jup(1, 279)/ 289.000/, Jup(2, 279)/ 165.938/
          data  Jup(1, 280)/ 290.000/, Jup(2, 280)/ 165.931/
          data  Jup(1, 281)/ 291.000/, Jup(2, 281)/ 165.922/
          data  Jup(1, 282)/ 292.000/, Jup(2, 282)/ 165.913/
          data  Jup(1, 283)/ 293.000/, Jup(2, 283)/ 165.903/
          data  Jup(1, 284)/ 294.000/, Jup(2, 284)/ 165.891/
          data  Jup(1, 285)/ 295.000/, Jup(2, 285)/ 165.879/
          data  Jup(1, 286)/ 296.000/, Jup(2, 286)/ 165.867/
          data  Jup(1, 287)/ 297.000/, Jup(2, 287)/ 165.853/
          data  Jup(1, 288)/ 298.000/, Jup(2, 288)/ 165.839/
          data  Jup(1, 289)/ 299.000/, Jup(2, 289)/ 165.824/
          data  Jup(1, 290)/ 300.000/, Jup(2, 290)/ 165.809/
          data  Jup(1, 291)/ 301.000/, Jup(2, 291)/ 165.794/
          data  Jup(1, 292)/ 302.000/, Jup(2, 292)/ 165.778/
          data  Jup(1, 293)/ 303.000/, Jup(2, 293)/ 165.761/
          data  Jup(1, 294)/ 304.000/, Jup(2, 294)/ 165.744/
          data  Jup(1, 295)/ 305.000/, Jup(2, 295)/ 165.727/
          data  Jup(1, 296)/ 306.000/, Jup(2, 296)/ 165.709/
          data  Jup(1, 297)/ 307.000/, Jup(2, 297)/ 165.691/
          data  Jup(1, 298)/ 308.000/, Jup(2, 298)/ 165.673/
          data  Jup(1, 299)/ 309.000/, Jup(2, 299)/ 165.654/
          data  Jup(1, 300)/ 310.000/, Jup(2, 300)/ 165.634/
          data  Jup(1, 301)/ 311.000/, Jup(2, 301)/ 165.615/
          data  Jup(1, 302)/ 312.000/, Jup(2, 302)/ 165.595/
          data  Jup(1, 303)/ 313.000/, Jup(2, 303)/ 165.575/
          data  Jup(1, 304)/ 314.000/, Jup(2, 304)/ 165.555/
          data  Jup(1, 305)/ 315.000/, Jup(2, 305)/ 165.534/
          data  Jup(1, 306)/ 316.000/, Jup(2, 306)/ 165.513/
          data  Jup(1, 307)/ 317.000/, Jup(2, 307)/ 165.492/
          data  Jup(1, 308)/ 318.000/, Jup(2, 308)/ 165.470/
          data  Jup(1, 309)/ 319.000/, Jup(2, 309)/ 165.448/
          data  Jup(1, 310)/ 320.000/, Jup(2, 310)/ 165.426/
          data  Jup(1, 311)/ 321.000/, Jup(2, 311)/ 165.403/
          data  Jup(1, 312)/ 322.000/, Jup(2, 312)/ 165.380/
          data  Jup(1, 313)/ 323.000/, Jup(2, 313)/ 165.357/
          data  Jup(1, 314)/ 324.000/, Jup(2, 314)/ 165.333/
          data  Jup(1, 315)/ 325.000/, Jup(2, 315)/ 165.309/
          data  Jup(1, 316)/ 326.000/, Jup(2, 316)/ 165.285/
          data  Jup(1, 317)/ 327.000/, Jup(2, 317)/ 165.261/
          data  Jup(1, 318)/ 328.000/, Jup(2, 318)/ 165.236/
          data  Jup(1, 319)/ 329.000/, Jup(2, 319)/ 165.211/
          data  Jup(1, 320)/ 330.000/, Jup(2, 320)/ 165.185/
          data  Jup(1, 321)/ 331.000/, Jup(2, 321)/ 165.160/
          data  Jup(1, 322)/ 332.000/, Jup(2, 322)/ 165.133/
          data  Jup(1, 323)/ 333.000/, Jup(2, 323)/ 165.107/
          data  Jup(1, 324)/ 334.000/, Jup(2, 324)/ 165.080/
          data  Jup(1, 325)/ 335.000/, Jup(2, 325)/ 165.053/
          data  Jup(1, 326)/ 336.000/, Jup(2, 326)/ 165.025/
          data  Jup(1, 327)/ 337.000/, Jup(2, 327)/ 164.997/
          data  Jup(1, 328)/ 338.000/, Jup(2, 328)/ 164.969/
          data  Jup(1, 329)/ 339.000/, Jup(2, 329)/ 164.940/
          data  Jup(1, 330)/ 340.000/, Jup(2, 330)/ 164.911/
          data  Jup(1, 331)/ 341.000/, Jup(2, 331)/ 164.881/
          data  Jup(1, 332)/ 342.000/, Jup(2, 332)/ 164.851/
          data  Jup(1, 333)/ 343.000/, Jup(2, 333)/ 164.820/
          data  Jup(1, 334)/ 344.000/, Jup(2, 334)/ 164.786/
          data  Jup(1, 335)/ 345.000/, Jup(2, 335)/ 164.746/
          data  Jup(1, 336)/ 346.000/, Jup(2, 336)/ 164.705/
          data  Jup(1, 337)/ 347.000/, Jup(2, 337)/ 164.689/
          data  Jup(1, 338)/ 348.000/, Jup(2, 338)/ 164.663/
          data  Jup(1, 339)/ 349.000/, Jup(2, 339)/ 164.633/
          data  Jup(1, 340)/ 350.000/, Jup(2, 340)/ 164.601/
          data  Jup(1, 341)/ 351.000/, Jup(2, 341)/ 164.569/
          data  Jup(1, 342)/ 352.000/, Jup(2, 342)/ 164.537/
          data  Jup(1, 343)/ 353.000/, Jup(2, 343)/ 164.503/
          data  Jup(1, 344)/ 354.000/, Jup(2, 344)/ 164.469/
          data  Jup(1, 345)/ 355.000/, Jup(2, 345)/ 164.435/
          data  Jup(1, 346)/ 356.000/, Jup(2, 346)/ 164.400/
          data  Jup(1, 347)/ 357.000/, Jup(2, 347)/ 164.365/
          data  Jup(1, 348)/ 358.000/, Jup(2, 348)/ 164.329/
          data  Jup(1, 349)/ 359.000/, Jup(2, 349)/ 164.292/
          data  Jup(1, 350)/ 360.000/, Jup(2, 350)/ 164.256/
          data  Jup(1, 351)/ 361.000/, Jup(2, 351)/ 164.218/
          data  Jup(1, 352)/ 362.000/, Jup(2, 352)/ 164.180/
          data  Jup(1, 353)/ 363.000/, Jup(2, 353)/ 164.142/
          data  Jup(1, 354)/ 364.000/, Jup(2, 354)/ 164.104/
          data  Jup(1, 355)/ 365.000/, Jup(2, 355)/ 164.064/
          data  Jup(1, 356)/ 366.000/, Jup(2, 356)/ 164.024/
          data  Jup(1, 357)/ 367.000/, Jup(2, 357)/ 163.984/
          data  Jup(1, 358)/ 368.000/, Jup(2, 358)/ 163.944/
          data  Jup(1, 359)/ 369.000/, Jup(2, 359)/ 163.903/
          data  Jup(1, 360)/ 370.000/, Jup(2, 360)/ 163.861/
          data  Jup(1, 361)/ 371.000/, Jup(2, 361)/ 163.819/
          data  Jup(1, 362)/ 372.000/, Jup(2, 362)/ 163.776/
          data  Jup(1, 363)/ 373.000/, Jup(2, 363)/ 163.733/
          data  Jup(1, 364)/ 374.000/, Jup(2, 364)/ 163.689/
          data  Jup(1, 365)/ 375.000/, Jup(2, 365)/ 163.644/
          data  Jup(1, 366)/ 376.000/, Jup(2, 366)/ 163.599/
          data  Jup(1, 367)/ 377.000/, Jup(2, 367)/ 163.554/
          data  Jup(1, 368)/ 378.000/, Jup(2, 368)/ 163.508/
          data  Jup(1, 369)/ 379.000/, Jup(2, 369)/ 163.461/
          data  Jup(1, 370)/ 380.000/, Jup(2, 370)/ 163.413/
          data  Jup(1, 371)/ 381.000/, Jup(2, 371)/ 163.365/
          data  Jup(1, 372)/ 382.000/, Jup(2, 372)/ 163.317/
          data  Jup(1, 373)/ 383.000/, Jup(2, 373)/ 163.267/
          data  Jup(1, 374)/ 384.000/, Jup(2, 374)/ 163.217/
          data  Jup(1, 375)/ 385.000/, Jup(2, 375)/ 163.166/
          data  Jup(1, 376)/ 386.000/, Jup(2, 376)/ 163.115/
          data  Jup(1, 377)/ 387.000/, Jup(2, 377)/ 163.063/
          data  Jup(1, 378)/ 388.000/, Jup(2, 378)/ 163.011/
          data  Jup(1, 379)/ 389.000/, Jup(2, 379)/ 162.957/
          data  Jup(1, 380)/ 390.000/, Jup(2, 380)/ 162.903/
          data  Jup(1, 381)/ 391.000/, Jup(2, 381)/ 162.848/
          data  Jup(1, 382)/ 392.000/, Jup(2, 382)/ 162.793/
          data  Jup(1, 383)/ 393.000/, Jup(2, 383)/ 162.737/
          data  Jup(1, 384)/ 394.000/, Jup(2, 384)/ 162.680/
          data  Jup(1, 385)/ 395.000/, Jup(2, 385)/ 162.622/
          data  Jup(1, 386)/ 396.000/, Jup(2, 386)/ 162.563/
          data  Jup(1, 387)/ 397.000/, Jup(2, 387)/ 162.503/
          data  Jup(1, 388)/ 398.000/, Jup(2, 388)/ 162.443/
          data  Jup(1, 389)/ 399.000/, Jup(2, 389)/ 162.382/
          data  Jup(1, 390)/ 400.000/, Jup(2, 390)/ 162.320/
          data  Jup(1, 391)/ 401.000/, Jup(2, 391)/ 162.258/
          data  Jup(1, 392)/ 402.000/, Jup(2, 392)/ 162.194/
          data  Jup(1, 393)/ 403.000/, Jup(2, 393)/ 162.130/
          data  Jup(1, 394)/ 404.000/, Jup(2, 394)/ 162.065/
          data  Jup(1, 395)/ 405.000/, Jup(2, 395)/ 161.998/
          data  Jup(1, 396)/ 406.000/, Jup(2, 396)/ 161.931/
          data  Jup(1, 397)/ 407.000/, Jup(2, 397)/ 161.862/
          data  Jup(1, 398)/ 408.000/, Jup(2, 398)/ 161.793/
          data  Jup(1, 399)/ 409.000/, Jup(2, 399)/ 161.723/
          data  Jup(1, 400)/ 410.000/, Jup(2, 400)/ 161.652/
          data  Jup(1, 401)/ 411.000/, Jup(2, 401)/ 161.580/
          data  Jup(1, 402)/ 412.000/, Jup(2, 402)/ 161.506/
          data  Jup(1, 403)/ 413.000/, Jup(2, 403)/ 161.432/
          data  Jup(1, 404)/ 414.000/, Jup(2, 404)/ 161.357/
          data  Jup(1, 405)/ 415.000/, Jup(2, 405)/ 161.281/
          data  Jup(1, 406)/ 416.000/, Jup(2, 406)/ 161.203/
          data  Jup(1, 407)/ 417.000/, Jup(2, 407)/ 161.125/
          data  Jup(1, 408)/ 418.000/, Jup(2, 408)/ 161.045/
          data  Jup(1, 409)/ 419.000/, Jup(2, 409)/ 160.964/
          data  Jup(1, 410)/ 420.000/, Jup(2, 410)/ 160.882/
          data  Jup(1, 411)/ 421.000/, Jup(2, 411)/ 160.799/
          data  Jup(1, 412)/ 422.000/, Jup(2, 412)/ 160.715/
          data  Jup(1, 413)/ 423.000/, Jup(2, 413)/ 160.629/
          data  Jup(1, 414)/ 424.000/, Jup(2, 414)/ 160.541/
          data  Jup(1, 415)/ 425.000/, Jup(2, 415)/ 160.453/
          data  Jup(1, 416)/ 426.000/, Jup(2, 416)/ 160.364/
          data  Jup(1, 417)/ 427.000/, Jup(2, 417)/ 160.273/
          data  Jup(1, 418)/ 428.000/, Jup(2, 418)/ 160.180/
          data  Jup(1, 419)/ 429.000/, Jup(2, 419)/ 160.087/
          data  Jup(1, 420)/ 430.000/, Jup(2, 420)/ 159.992/
          data  Jup(1, 421)/ 431.000/, Jup(2, 421)/ 159.896/
          data  Jup(1, 422)/ 432.000/, Jup(2, 422)/ 159.798/
          data  Jup(1, 423)/ 433.000/, Jup(2, 423)/ 159.699/
          data  Jup(1, 424)/ 434.000/, Jup(2, 424)/ 159.598/
          data  Jup(1, 425)/ 435.000/, Jup(2, 425)/ 159.496/
          data  Jup(1, 426)/ 436.000/, Jup(2, 426)/ 159.391/
          data  Jup(1, 427)/ 437.000/, Jup(2, 427)/ 159.286/
          data  Jup(1, 428)/ 438.000/, Jup(2, 428)/ 159.179/
          data  Jup(1, 429)/ 439.000/, Jup(2, 429)/ 159.071/
          data  Jup(1, 430)/ 440.000/, Jup(2, 430)/ 158.960/
          data  Jup(1, 431)/ 441.000/, Jup(2, 431)/ 158.848/
          data  Jup(1, 432)/ 442.000/, Jup(2, 432)/ 158.735/
          data  Jup(1, 433)/ 443.000/, Jup(2, 433)/ 158.620/
          data  Jup(1, 434)/ 444.000/, Jup(2, 434)/ 158.502/
          data  Jup(1, 435)/ 445.000/, Jup(2, 435)/ 158.384/
          data  Jup(1, 436)/ 446.000/, Jup(2, 436)/ 158.263/
          data  Jup(1, 437)/ 447.000/, Jup(2, 437)/ 158.140/
          data  Jup(1, 438)/ 448.000/, Jup(2, 438)/ 158.016/
          data  Jup(1, 439)/ 449.000/, Jup(2, 439)/ 157.890/
          data  Jup(1, 440)/ 450.000/, Jup(2, 440)/ 157.761/
          data  Jup(1, 441)/ 451.000/, Jup(2, 441)/ 157.631/
          data  Jup(1, 442)/ 452.000/, Jup(2, 442)/ 157.499/
          data  Jup(1, 443)/ 453.000/, Jup(2, 443)/ 157.364/
          data  Jup(1, 444)/ 454.000/, Jup(2, 444)/ 157.228/
          data  Jup(1, 445)/ 455.000/, Jup(2, 445)/ 157.090/
          data  Jup(1, 446)/ 456.000/, Jup(2, 446)/ 156.948/
          data  Jup(1, 447)/ 457.000/, Jup(2, 447)/ 156.805/
          data  Jup(1, 448)/ 458.000/, Jup(2, 448)/ 156.658/
          data  Jup(1, 449)/ 459.000/, Jup(2, 449)/ 156.507/
          data  Jup(1, 450)/ 460.000/, Jup(2, 450)/ 156.346/
          data  Jup(1, 451)/ 461.000/, Jup(2, 451)/ 156.169/
          data  Jup(1, 452)/ 462.000/, Jup(2, 452)/ 156.039/
          data  Jup(1, 453)/ 463.000/, Jup(2, 453)/ 155.895/
          data  Jup(1, 454)/ 464.000/, Jup(2, 454)/ 155.739/
          data  Jup(1, 455)/ 465.000/, Jup(2, 455)/ 155.565/
          data  Jup(1, 456)/ 466.000/, Jup(2, 456)/ 155.415/
          data  Jup(1, 457)/ 467.000/, Jup(2, 457)/ 155.256/
          data  Jup(1, 458)/ 468.000/, Jup(2, 458)/ 155.090/
          data  Jup(1, 459)/ 469.000/, Jup(2, 459)/ 154.921/
          data  Jup(1, 460)/ 470.000/, Jup(2, 460)/ 154.749/
          data  Jup(1, 461)/ 471.000/, Jup(2, 461)/ 154.574/
          data  Jup(1, 462)/ 472.000/, Jup(2, 462)/ 154.396/
          data  Jup(1, 463)/ 473.000/, Jup(2, 463)/ 154.216/
          data  Jup(1, 464)/ 474.000/, Jup(2, 464)/ 154.033/
          data  Jup(1, 465)/ 475.000/, Jup(2, 465)/ 153.847/
          data  Jup(1, 466)/ 476.000/, Jup(2, 466)/ 153.659/
          data  Jup(1, 467)/ 477.000/, Jup(2, 467)/ 153.468/
          data  Jup(1, 468)/ 478.000/, Jup(2, 468)/ 153.273/
          data  Jup(1, 469)/ 479.000/, Jup(2, 469)/ 153.077/
          data  Jup(1, 470)/ 480.000/, Jup(2, 470)/ 152.878/
          data  Jup(1, 471)/ 481.000/, Jup(2, 471)/ 152.675/
          data  Jup(1, 472)/ 482.000/, Jup(2, 472)/ 152.470/
          data  Jup(1, 473)/ 483.000/, Jup(2, 473)/ 152.262/
          data  Jup(1, 474)/ 484.000/, Jup(2, 474)/ 152.052/
          data  Jup(1, 475)/ 485.000/, Jup(2, 475)/ 151.838/
          data  Jup(1, 476)/ 486.000/, Jup(2, 476)/ 151.622/
          data  Jup(1, 477)/ 487.000/, Jup(2, 477)/ 151.402/
          data  Jup(1, 478)/ 488.000/, Jup(2, 478)/ 151.180/
          data  Jup(1, 479)/ 489.000/, Jup(2, 479)/ 150.955/
          data  Jup(1, 480)/ 490.000/, Jup(2, 480)/ 150.726/
          data  Jup(1, 481)/ 491.000/, Jup(2, 481)/ 150.495/
          data  Jup(1, 482)/ 492.000/, Jup(2, 482)/ 150.261/
          data  Jup(1, 483)/ 493.000/, Jup(2, 483)/ 150.023/
          data  Jup(1, 484)/ 494.000/, Jup(2, 484)/ 149.783/
          data  Jup(1, 485)/ 495.000/, Jup(2, 485)/ 149.540/
          data  Jup(1, 486)/ 496.000/, Jup(2, 486)/ 149.293/
          data  Jup(1, 487)/ 497.000/, Jup(2, 487)/ 149.044/
          data  Jup(1, 488)/ 498.000/, Jup(2, 488)/ 148.791/
          data  Jup(1, 489)/ 499.000/, Jup(2, 489)/ 148.535/
          data  Jup(1, 490)/ 500.000/, Jup(2, 490)/ 148.276/
          data  Jup(1, 491)/ 501.000/, Jup(2, 491)/ 148.014/
          data  Jup(1, 492)/ 502.000/, Jup(2, 492)/ 147.748/
          data  Jup(1, 493)/ 503.000/, Jup(2, 493)/ 147.480/
          data  Jup(1, 494)/ 504.000/, Jup(2, 494)/ 147.207/
          data  Jup(1, 495)/ 505.000/, Jup(2, 495)/ 146.932/
          data  Jup(1, 496)/ 506.000/, Jup(2, 496)/ 146.653/
          data  Jup(1, 497)/ 507.000/, Jup(2, 497)/ 146.370/
          data  Jup(1, 498)/ 508.000/, Jup(2, 498)/ 146.083/
          data  Jup(1, 499)/ 509.000/, Jup(2, 499)/ 145.792/
          data  Jup(1, 500)/ 510.000/, Jup(2, 500)/ 145.497/
          data  Jup(1, 501)/ 511.000/, Jup(2, 501)/ 145.198/
          data  Jup(1, 502)/ 512.000/, Jup(2, 502)/ 144.893/
          data  Jup(1, 503)/ 513.000/, Jup(2, 503)/ 144.583/
          data  Jup(1, 504)/ 514.000/, Jup(2, 504)/ 144.267/
          data  Jup(1, 505)/ 515.000/, Jup(2, 505)/ 143.945/
          data  Jup(1, 506)/ 516.000/, Jup(2, 506)/ 143.614/
          data  Jup(1, 507)/ 517.000/, Jup(2, 507)/ 143.275/
          data  Jup(1, 508)/ 518.000/, Jup(2, 508)/ 142.925/
          data  Jup(1, 509)/ 519.000/, Jup(2, 509)/ 142.563/
          data  Jup(1, 510)/ 520.000/, Jup(2, 510)/ 142.185/
          data  Jup(1, 511)/ 521.000/, Jup(2, 511)/ 141.787/
          data  Jup(1, 512)/ 522.000/, Jup(2, 512)/ 141.364/
          data  Jup(1, 513)/ 523.000/, Jup(2, 513)/ 140.908/
          data  Jup(1, 514)/ 524.000/, Jup(2, 514)/ 140.408/
          data  Jup(1, 515)/ 525.000/, Jup(2, 515)/ 139.848/
          data  Jup(1, 516)/ 526.000/, Jup(2, 516)/ 139.203/
          data  Jup(1, 517)/ 527.000/, Jup(2, 517)/ 138.433/
          data  Jup(1, 518)/ 528.000/, Jup(2, 518)/ 137.478/
          data  Jup(1, 519)/ 529.000/, Jup(2, 519)/ 136.237/
          data  Jup(1, 520)/ 530.000/, Jup(2, 520)/ 134.556/
          data  Jup(1, 521)/ 531.000/, Jup(2, 521)/ 132.213/
          data  Jup(1, 522)/ 532.000/, Jup(2, 522)/ 129.053/
          data  Jup(1, 523)/ 533.000/, Jup(2, 523)/ 125.643/
          data  Jup(1, 524)/ 534.000/, Jup(2, 524)/ 124.422/
          data  Jup(1, 525)/ 535.000/, Jup(2, 525)/ 126.716/
          data  Jup(1, 526)/ 536.000/, Jup(2, 526)/ 129.837/
          data  Jup(1, 527)/ 537.000/, Jup(2, 527)/ 132.135/
          data  Jup(1, 528)/ 538.000/, Jup(2, 528)/ 133.543/
          data  Jup(1, 529)/ 539.000/, Jup(2, 529)/ 134.337/
          data  Jup(1, 530)/ 540.000/, Jup(2, 530)/ 134.741/
          data  Jup(1, 531)/ 541.000/, Jup(2, 531)/ 134.901/
          data  Jup(1, 532)/ 542.000/, Jup(2, 532)/ 134.903/
          data  Jup(1, 533)/ 543.000/, Jup(2, 533)/ 134.799/
          data  Jup(1, 534)/ 544.000/, Jup(2, 534)/ 134.620/
          data  Jup(1, 535)/ 545.000/, Jup(2, 535)/ 134.387/
          data  Jup(1, 536)/ 546.000/, Jup(2, 536)/ 134.112/
          data  Jup(1, 537)/ 547.000/, Jup(2, 537)/ 133.802/
          data  Jup(1, 538)/ 548.000/, Jup(2, 538)/ 133.463/
          data  Jup(1, 539)/ 549.000/, Jup(2, 539)/ 133.099/
          data  Jup(1, 540)/ 550.000/, Jup(2, 540)/ 132.710/
          data  Jup(1, 541)/ 551.000/, Jup(2, 541)/ 132.299/
          data  Jup(1, 542)/ 552.000/, Jup(2, 542)/ 131.864/
          data  Jup(1, 543)/ 553.000/, Jup(2, 543)/ 131.407/
          data  Jup(1, 544)/ 554.000/, Jup(2, 544)/ 130.926/
          data  Jup(1, 545)/ 555.000/, Jup(2, 545)/ 130.421/
          data  Jup(1, 546)/ 556.000/, Jup(2, 546)/ 129.890/
          data  Jup(1, 547)/ 557.000/, Jup(2, 547)/ 129.333/
          data  Jup(1, 548)/ 558.000/, Jup(2, 548)/ 128.747/
          data  Jup(1, 549)/ 559.000/, Jup(2, 549)/ 128.131/
          data  Jup(1, 550)/ 560.000/, Jup(2, 550)/ 127.479/
          data  Jup(1, 551)/ 561.000/, Jup(2, 551)/ 126.788/
          data  Jup(1, 552)/ 562.000/, Jup(2, 552)/ 126.051/
          data  Jup(1, 553)/ 563.000/, Jup(2, 553)/ 125.258/
          data  Jup(1, 554)/ 564.000/, Jup(2, 554)/ 124.395/
          data  Jup(1, 555)/ 565.000/, Jup(2, 555)/ 123.442/
          data  Jup(1, 556)/ 566.000/, Jup(2, 556)/ 122.372/
          data  Jup(1, 557)/ 567.000/, Jup(2, 557)/ 121.147/
          data  Jup(1, 558)/ 568.000/, Jup(2, 558)/ 119.726/
          data  Jup(1, 559)/ 569.000/, Jup(2, 559)/ 118.058/
          data  Jup(1, 560)/ 570.000/, Jup(2, 560)/ 116.084/
          data  Jup(1, 561)/ 571.000/, Jup(2, 561)/ 113.703/
          data  Jup(1, 562)/ 572.000/, Jup(2, 562)/ 111.093/
          data  Jup(1, 563)/ 573.000/, Jup(2, 563)/ 111.096/
          data  Jup(1, 564)/ 574.000/, Jup(2, 564)/ 113.687/
          data  Jup(1, 565)/ 575.000/, Jup(2, 565)/ 116.040/
          data  Jup(1, 566)/ 576.000/, Jup(2, 566)/ 117.979/
          data  Jup(1, 567)/ 577.000/, Jup(2, 567)/ 119.617/
          data  Jup(1, 568)/ 578.000/, Jup(2, 568)/ 121.011/
          data  Jup(1, 569)/ 579.000/, Jup(2, 569)/ 122.208/
          data  Jup(1, 570)/ 580.000/, Jup(2, 570)/ 123.251/
          data  Jup(1, 571)/ 581.000/, Jup(2, 571)/ 124.177/
          data  Jup(1, 572)/ 582.000/, Jup(2, 572)/ 125.011/
          data  Jup(1, 573)/ 583.000/, Jup(2, 573)/ 125.774/
          data  Jup(1, 574)/ 584.000/, Jup(2, 574)/ 126.481/
          data  Jup(1, 575)/ 585.000/, Jup(2, 575)/ 127.141/
          data  Jup(1, 576)/ 586.000/, Jup(2, 576)/ 127.761/
          data  Jup(1, 577)/ 587.000/, Jup(2, 577)/ 128.348/
          data  Jup(1, 578)/ 588.000/, Jup(2, 578)/ 128.904/
          data  Jup(1, 579)/ 589.000/, Jup(2, 579)/ 129.433/
          data  Jup(1, 580)/ 590.000/, Jup(2, 580)/ 129.937/
          data  Jup(1, 581)/ 591.000/, Jup(2, 581)/ 130.419/
          data  Jup(1, 582)/ 592.000/, Jup(2, 582)/ 130.880/
          data  Jup(1, 583)/ 593.000/, Jup(2, 583)/ 131.320/
          data  Jup(1, 584)/ 594.000/, Jup(2, 584)/ 131.743/
          data  Jup(1, 585)/ 595.000/, Jup(2, 585)/ 132.149/
          data  Jup(1, 586)/ 596.000/, Jup(2, 586)/ 132.539/
          data  Jup(1, 587)/ 597.000/, Jup(2, 587)/ 132.915/
          data  Jup(1, 588)/ 598.000/, Jup(2, 588)/ 133.277/
          data  Jup(1, 589)/ 599.000/, Jup(2, 589)/ 133.626/
          data  Jup(1, 590)/ 600.000/, Jup(2, 590)/ 133.965/
          data  Jup(1, 591)/ 601.000/, Jup(2, 591)/ 134.293/
          data  Jup(1, 592)/ 602.000/, Jup(2, 592)/ 134.610/
          data  Jup(1, 593)/ 603.000/, Jup(2, 593)/ 134.918/
          data  Jup(1, 594)/ 604.000/, Jup(2, 594)/ 135.219/
          data  Jup(1, 595)/ 605.000/, Jup(2, 595)/ 135.511/
          data  Jup(1, 596)/ 606.000/, Jup(2, 596)/ 135.796/
          data  Jup(1, 597)/ 607.000/, Jup(2, 597)/ 136.074/
          data  Jup(1, 598)/ 608.000/, Jup(2, 598)/ 136.346/
          data  Jup(1, 599)/ 609.000/, Jup(2, 599)/ 136.612/
          data  Jup(1, 600)/ 610.000/, Jup(2, 600)/ 136.874/
          data  Jup(1, 601)/ 611.000/, Jup(2, 601)/ 137.130/
          data  Jup(1, 602)/ 612.000/, Jup(2, 602)/ 137.381/
          data  Jup(1, 603)/ 613.000/, Jup(2, 603)/ 137.629/
          data  Jup(1, 604)/ 614.000/, Jup(2, 604)/ 137.872/
          data  Jup(1, 605)/ 615.000/, Jup(2, 605)/ 138.111/
          data  Jup(1, 606)/ 616.000/, Jup(2, 606)/ 138.347/
          data  Jup(1, 607)/ 617.000/, Jup(2, 607)/ 138.579/
          data  Jup(1, 608)/ 618.000/, Jup(2, 608)/ 138.808/
          data  Jup(1, 609)/ 619.000/, Jup(2, 609)/ 139.034/
          data  Jup(1, 610)/ 620.000/, Jup(2, 610)/ 139.257/
          data  Jup(1, 611)/ 621.000/, Jup(2, 611)/ 139.477/
          data  Jup(1, 612)/ 622.000/, Jup(2, 612)/ 139.694/
          data  Jup(1, 613)/ 623.000/, Jup(2, 613)/ 139.909/
          data  Jup(1, 614)/ 624.000/, Jup(2, 614)/ 140.121/
          data  Jup(1, 615)/ 625.000/, Jup(2, 615)/ 140.331/
          data  Jup(1, 616)/ 626.000/, Jup(2, 616)/ 140.538/
          data  Jup(1, 617)/ 627.000/, Jup(2, 617)/ 140.743/
          data  Jup(1, 618)/ 628.000/, Jup(2, 618)/ 140.945/
          data  Jup(1, 619)/ 629.000/, Jup(2, 619)/ 141.145/
          data  Jup(1, 620)/ 630.000/, Jup(2, 620)/ 141.343/
          data  Jup(1, 621)/ 631.000/, Jup(2, 621)/ 141.538/
          data  Jup(1, 622)/ 632.000/, Jup(2, 622)/ 141.731/
          data  Jup(1, 623)/ 633.000/, Jup(2, 623)/ 141.922/
          data  Jup(1, 624)/ 634.000/, Jup(2, 624)/ 142.111/
          data  Jup(1, 625)/ 635.000/, Jup(2, 625)/ 142.297/
          data  Jup(1, 626)/ 636.000/, Jup(2, 626)/ 142.481/
          data  Jup(1, 627)/ 637.000/, Jup(2, 627)/ 142.664/
          data  Jup(1, 628)/ 638.000/, Jup(2, 628)/ 142.844/
          data  Jup(1, 629)/ 639.000/, Jup(2, 629)/ 143.021/
          data  Jup(1, 630)/ 640.000/, Jup(2, 630)/ 143.197/
          data  Jup(1, 631)/ 641.000/, Jup(2, 631)/ 143.370/
          data  Jup(1, 632)/ 642.000/, Jup(2, 632)/ 143.542/
          data  Jup(1, 633)/ 643.000/, Jup(2, 633)/ 143.711/
          data  Jup(1, 634)/ 644.000/, Jup(2, 634)/ 143.878/
          data  Jup(1, 635)/ 645.000/, Jup(2, 635)/ 144.043/
          data  Jup(1, 636)/ 646.000/, Jup(2, 636)/ 144.206/
          data  Jup(1, 637)/ 647.000/, Jup(2, 637)/ 144.367/
          data  Jup(1, 638)/ 648.000/, Jup(2, 638)/ 144.525/
          data  Jup(1, 639)/ 649.000/, Jup(2, 639)/ 144.682/
          data  Jup(1, 640)/ 650.000/, Jup(2, 640)/ 144.837/
          data  Jup(1, 641)/ 651.000/, Jup(2, 641)/ 144.990/
          data  Jup(1, 642)/ 652.000/, Jup(2, 642)/ 145.140/
          data  Jup(1, 643)/ 653.000/, Jup(2, 643)/ 145.289/
          data  Jup(1, 644)/ 654.000/, Jup(2, 644)/ 145.435/
          data  Jup(1, 645)/ 655.000/, Jup(2, 645)/ 145.580/
          data  Jup(1, 646)/ 656.000/, Jup(2, 646)/ 145.722/
          data  Jup(1, 647)/ 657.000/, Jup(2, 647)/ 145.863/
          data  Jup(1, 648)/ 658.000/, Jup(2, 648)/ 146.001/
          data  Jup(1, 649)/ 659.000/, Jup(2, 649)/ 146.138/
          data  Jup(1, 650)/ 660.000/, Jup(2, 650)/ 146.272/
          data  Jup(1, 651)/ 661.000/, Jup(2, 651)/ 146.405/
          data  Jup(1, 652)/ 662.000/, Jup(2, 652)/ 146.535/
          data  Jup(1, 653)/ 663.000/, Jup(2, 653)/ 146.664/
          data  Jup(1, 654)/ 664.000/, Jup(2, 654)/ 146.791/
          data  Jup(1, 655)/ 665.000/, Jup(2, 655)/ 146.916/
          data  Jup(1, 656)/ 666.000/, Jup(2, 656)/ 147.039/
          data  Jup(1, 657)/ 667.000/, Jup(2, 657)/ 147.160/
          data  Jup(1, 658)/ 668.000/, Jup(2, 658)/ 147.280/
          data  Jup(1, 659)/ 669.000/, Jup(2, 659)/ 147.397/
          data  Jup(1, 660)/ 670.000/, Jup(2, 660)/ 147.513/
          data  Jup(1, 661)/ 671.000/, Jup(2, 661)/ 147.627/
          data  Jup(1, 662)/ 672.000/, Jup(2, 662)/ 147.739/
          data  Jup(1, 663)/ 673.000/, Jup(2, 663)/ 147.849/
          data  Jup(1, 664)/ 674.000/, Jup(2, 664)/ 147.958/
          data  Jup(1, 665)/ 675.000/, Jup(2, 665)/ 148.065/
          data  Jup(1, 666)/ 676.000/, Jup(2, 666)/ 148.170/
          data  Jup(1, 667)/ 677.000/, Jup(2, 667)/ 148.273/
          data  Jup(1, 668)/ 678.000/, Jup(2, 668)/ 148.375/
          data  Jup(1, 669)/ 679.000/, Jup(2, 669)/ 148.475/
          data  Jup(1, 670)/ 680.000/, Jup(2, 670)/ 148.573/
          data  Jup(1, 671)/ 681.000/, Jup(2, 671)/ 148.669/
          data  Jup(1, 672)/ 682.000/, Jup(2, 672)/ 148.764/
          data  Jup(1, 673)/ 683.000/, Jup(2, 673)/ 148.857/
          data  Jup(1, 674)/ 684.000/, Jup(2, 674)/ 148.949/
          data  Jup(1, 675)/ 685.000/, Jup(2, 675)/ 149.038/
          data  Jup(1, 676)/ 686.000/, Jup(2, 676)/ 149.126/
          data  Jup(1, 677)/ 687.000/, Jup(2, 677)/ 149.211/
          data  Jup(1, 678)/ 688.000/, Jup(2, 678)/ 149.294/
          data  Jup(1, 679)/ 689.000/, Jup(2, 679)/ 149.373/
          data  Jup(1, 680)/ 690.000/, Jup(2, 680)/ 149.442/
          data  Jup(1, 681)/ 691.000/, Jup(2, 681)/ 149.485/
          data  Jup(1, 682)/ 692.000/, Jup(2, 682)/ 149.566/
          data  Jup(1, 683)/ 693.000/, Jup(2, 683)/ 149.679/
          data  Jup(1, 684)/ 694.000/, Jup(2, 684)/ 149.768/
          data  Jup(1, 685)/ 695.000/, Jup(2, 685)/ 149.846/
          data  Jup(1, 686)/ 696.000/, Jup(2, 686)/ 149.916/
          data  Jup(1, 687)/ 697.000/, Jup(2, 687)/ 149.971/
          data  Jup(1, 688)/ 698.000/, Jup(2, 688)/ 150.006/
          data  Jup(1, 689)/ 699.000/, Jup(2, 689)/ 150.125/
          data  Jup(1, 690)/ 700.000/, Jup(2, 690)/ 150.203/
          data  Jup(1, 691)/ 701.000/, Jup(2, 691)/ 150.274/
          data  Jup(1, 692)/ 702.000/, Jup(2, 692)/ 150.341/
          data  Jup(1, 693)/ 703.000/, Jup(2, 693)/ 150.406/
          data  Jup(1, 694)/ 704.000/, Jup(2, 694)/ 150.469/
          data  Jup(1, 695)/ 705.000/, Jup(2, 695)/ 150.530/
          data  Jup(1, 696)/ 706.000/, Jup(2, 696)/ 150.590/
          data  Jup(1, 697)/ 707.000/, Jup(2, 697)/ 150.649/
          data  Jup(1, 698)/ 708.000/, Jup(2, 698)/ 150.707/
          data  Jup(1, 699)/ 709.000/, Jup(2, 699)/ 150.763/
          data  Jup(1, 700)/ 710.000/, Jup(2, 700)/ 150.819/
          data  Jup(1, 701)/ 711.000/, Jup(2, 701)/ 150.872/
          data  Jup(1, 702)/ 712.000/, Jup(2, 702)/ 150.924/
          data  Jup(1, 703)/ 713.000/, Jup(2, 703)/ 150.975/
          data  Jup(1, 704)/ 714.000/, Jup(2, 704)/ 151.025/
          data  Jup(1, 705)/ 715.000/, Jup(2, 705)/ 151.074/
          data  Jup(1, 706)/ 716.000/, Jup(2, 706)/ 151.121/
          data  Jup(1, 707)/ 717.000/, Jup(2, 707)/ 151.167/
          data  Jup(1, 708)/ 718.000/, Jup(2, 708)/ 151.212/
          data  Jup(1, 709)/ 719.000/, Jup(2, 709)/ 151.256/
          data  Jup(1, 710)/ 720.000/, Jup(2, 710)/ 151.298/
          data  Jup(1, 711)/ 721.000/, Jup(2, 711)/ 151.340/
          data  Jup(1, 712)/ 722.000/, Jup(2, 712)/ 151.380/
          data  Jup(1, 713)/ 723.000/, Jup(2, 713)/ 151.419/
          data  Jup(1, 714)/ 724.000/, Jup(2, 714)/ 151.456/
          data  Jup(1, 715)/ 725.000/, Jup(2, 715)/ 151.493/
          data  Jup(1, 716)/ 726.000/, Jup(2, 716)/ 151.528/
          data  Jup(1, 717)/ 727.000/, Jup(2, 717)/ 151.562/
          data  Jup(1, 718)/ 728.000/, Jup(2, 718)/ 151.595/
          data  Jup(1, 719)/ 729.000/, Jup(2, 719)/ 151.626/
          data  Jup(1, 720)/ 730.000/, Jup(2, 720)/ 151.657/
          data  Jup(1, 721)/ 731.000/, Jup(2, 721)/ 151.686/
          data  Jup(1, 722)/ 732.000/, Jup(2, 722)/ 151.714/
          data  Jup(1, 723)/ 733.000/, Jup(2, 723)/ 151.741/
          data  Jup(1, 724)/ 734.000/, Jup(2, 724)/ 151.766/
          data  Jup(1, 725)/ 735.000/, Jup(2, 725)/ 151.791/
          data  Jup(1, 726)/ 736.000/, Jup(2, 726)/ 151.814/
          data  Jup(1, 727)/ 737.000/, Jup(2, 727)/ 151.836/
          data  Jup(1, 728)/ 738.000/, Jup(2, 728)/ 151.856/
          data  Jup(1, 729)/ 739.000/, Jup(2, 729)/ 151.875/
          data  Jup(1, 730)/ 740.000/, Jup(2, 730)/ 151.893/
          data  Jup(1, 731)/ 741.000/, Jup(2, 731)/ 151.910/
          data  Jup(1, 732)/ 742.000/, Jup(2, 732)/ 151.925/
          data  Jup(1, 733)/ 743.000/, Jup(2, 733)/ 151.938/
          data  Jup(1, 734)/ 744.000/, Jup(2, 734)/ 151.950/
          data  Jup(1, 735)/ 745.000/, Jup(2, 735)/ 151.961/
          data  Jup(1, 736)/ 746.000/, Jup(2, 736)/ 151.970/
          data  Jup(1, 737)/ 747.000/, Jup(2, 737)/ 151.977/
          data  Jup(1, 738)/ 748.000/, Jup(2, 738)/ 151.983/
          data  Jup(1, 739)/ 749.000/, Jup(2, 739)/ 151.987/
          data  Jup(1, 740)/ 750.000/, Jup(2, 740)/ 151.990/
          data  Jup(1, 741)/ 751.000/, Jup(2, 741)/ 151.990/
          data  Jup(1, 742)/ 752.000/, Jup(2, 742)/ 151.989/
          data  Jup(1, 743)/ 753.000/, Jup(2, 743)/ 151.985/
          data  Jup(1, 744)/ 754.000/, Jup(2, 744)/ 151.979/
          data  Jup(1, 745)/ 755.000/, Jup(2, 745)/ 151.972/
          data  Jup(1, 746)/ 756.000/, Jup(2, 746)/ 151.961/
          data  Jup(1, 747)/ 757.000/, Jup(2, 747)/ 151.949/
          data  Jup(1, 748)/ 758.000/, Jup(2, 748)/ 151.933/
          data  Jup(1, 749)/ 759.000/, Jup(2, 749)/ 151.915/
          data  Jup(1, 750)/ 760.000/, Jup(2, 750)/ 151.894/
          data  Jup(1, 751)/ 761.000/, Jup(2, 751)/ 151.869/
          data  Jup(1, 752)/ 762.000/, Jup(2, 752)/ 151.841/
          data  Jup(1, 753)/ 763.000/, Jup(2, 753)/ 151.809/
          data  Jup(1, 754)/ 764.000/, Jup(2, 754)/ 151.773/
          data  Jup(1, 755)/ 765.000/, Jup(2, 755)/ 151.732/
          data  Jup(1, 756)/ 766.000/, Jup(2, 756)/ 151.686/
          data  Jup(1, 757)/ 767.000/, Jup(2, 757)/ 151.636/
          data  Jup(1, 758)/ 768.000/, Jup(2, 758)/ 151.579/
          data  Jup(1, 759)/ 769.000/, Jup(2, 759)/ 151.515/
          data  Jup(1, 760)/ 770.000/, Jup(2, 760)/ 151.443/
          data  Jup(1, 761)/ 771.000/, Jup(2, 761)/ 151.364/
          data  Jup(1, 762)/ 772.000/, Jup(2, 762)/ 151.276/
          data  Jup(1, 763)/ 773.000/, Jup(2, 763)/ 151.177/
          data  Jup(1, 764)/ 774.000/, Jup(2, 764)/ 151.066/
          data  Jup(1, 765)/ 775.000/, Jup(2, 765)/ 150.942/
          data  Jup(1, 766)/ 776.000/, Jup(2, 766)/ 150.802/
          data  Jup(1, 767)/ 777.000/, Jup(2, 767)/ 150.645/
          data  Jup(1, 768)/ 778.000/, Jup(2, 768)/ 150.467/
          data  Jup(1, 769)/ 779.000/, Jup(2, 769)/ 150.265/
          data  Jup(1, 770)/ 780.000/, Jup(2, 770)/ 150.036/
          data  Jup(1, 771)/ 781.000/, Jup(2, 771)/ 149.775/
          data  Jup(1, 772)/ 782.000/, Jup(2, 772)/ 149.474/
          data  Jup(1, 773)/ 783.000/, Jup(2, 773)/ 149.128/
          data  Jup(1, 774)/ 784.000/, Jup(2, 774)/ 148.727/
          data  Jup(1, 775)/ 785.000/, Jup(2, 775)/ 148.260/
          data  Jup(1, 776)/ 786.000/, Jup(2, 776)/ 147.711/
          data  Jup(1, 777)/ 787.000/, Jup(2, 777)/ 147.065/
          data  Jup(1, 778)/ 788.000/, Jup(2, 778)/ 146.297/
          data  Jup(1, 779)/ 789.000/, Jup(2, 779)/ 145.379/
          data  Jup(1, 780)/ 790.000/, Jup(2, 780)/ 144.274/
          data  Jup(1, 781)/ 791.000/, Jup(2, 781)/ 142.938/
          data  Jup(1, 782)/ 792.000/, Jup(2, 782)/ 141.316/
          data  Jup(1, 783)/ 793.000/, Jup(2, 783)/ 139.342/
          data  Jup(1, 784)/ 794.000/, Jup(2, 784)/ 136.951/
          data  Jup(1, 785)/ 795.000/, Jup(2, 785)/ 134.089/
          data  Jup(1, 786)/ 796.000/, Jup(2, 786)/ 130.755/
          data  Jup(1, 787)/ 797.000/, Jup(2, 787)/ 127.069/
          data  Jup(1, 788)/ 798.000/, Jup(2, 788)/ 123.373/
          data  Jup(1, 789)/ 799.000/, Jup(2, 789)/ 120.280/
          data  Jup(1, 790)/ 800.000/, Jup(2, 790)/ 118.516/
          data  Jup(1, 791)/ 801.000/, Jup(2, 791)/ 118.523/
          data  Jup(1, 792)/ 802.000/, Jup(2, 792)/ 120.300/
          data  Jup(1, 793)/ 803.000/, Jup(2, 793)/ 123.399/
          data  Jup(1, 794)/ 804.000/, Jup(2, 794)/ 127.091/
          data  Jup(1, 795)/ 805.000/, Jup(2, 795)/ 130.762/
          data  Jup(1, 796)/ 806.000/, Jup(2, 796)/ 134.060/
          data  Jup(1, 797)/ 807.000/, Jup(2, 797)/ 136.886/
          data  Jup(1, 798)/ 808.000/, Jup(2, 798)/ 139.283/
          data  Jup(1, 799)/ 809.000/, Jup(2, 799)/ 141.243/
          data  Jup(1, 800)/ 810.000/, Jup(2, 800)/ 142.848/
          data  Jup(1, 801)/ 811.000/, Jup(2, 801)/ 144.163/
          data  Jup(1, 802)/ 812.000/, Jup(2, 802)/ 145.246/
          data  Jup(1, 803)/ 813.000/, Jup(2, 803)/ 146.142/
          data  Jup(1, 804)/ 814.000/, Jup(2, 804)/ 146.888/
          data  Jup(1, 805)/ 815.000/, Jup(2, 805)/ 147.513/
          data  Jup(1, 806)/ 816.000/, Jup(2, 806)/ 148.039/
          data  Jup(1, 807)/ 817.000/, Jup(2, 807)/ 148.485/
          data  Jup(1, 808)/ 818.000/, Jup(2, 808)/ 148.865/
          data  Jup(1, 809)/ 819.000/, Jup(2, 809)/ 149.190/
          data  Jup(1, 810)/ 820.000/, Jup(2, 810)/ 149.470/
          data  Jup(1, 811)/ 821.000/, Jup(2, 811)/ 149.711/
          data  Jup(1, 812)/ 822.000/, Jup(2, 812)/ 149.919/
          data  Jup(1, 813)/ 823.000/, Jup(2, 813)/ 150.101/
          data  Jup(1, 814)/ 824.000/, Jup(2, 814)/ 150.259/
          data  Jup(1, 815)/ 825.000/, Jup(2, 815)/ 150.397/
          data  Jup(1, 816)/ 826.000/, Jup(2, 816)/ 150.517/
          data  Jup(1, 817)/ 827.000/, Jup(2, 817)/ 150.622/
          data  Jup(1, 818)/ 828.000/, Jup(2, 818)/ 150.715/
          data  Jup(1, 819)/ 829.000/, Jup(2, 819)/ 150.795/
          data  Jup(1, 820)/ 830.000/, Jup(2, 820)/ 150.866/
          data  Jup(1, 821)/ 831.000/, Jup(2, 821)/ 150.927/
          data  Jup(1, 822)/ 832.000/, Jup(2, 822)/ 150.981/
          data  Jup(1, 823)/ 833.000/, Jup(2, 823)/ 151.027/
          data  Jup(1, 824)/ 834.000/, Jup(2, 824)/ 151.067/
          data  Jup(1, 825)/ 835.000/, Jup(2, 825)/ 151.101/
          data  Jup(1, 826)/ 836.000/, Jup(2, 826)/ 151.130/
          data  Jup(1, 827)/ 837.000/, Jup(2, 827)/ 151.154/
          data  Jup(1, 828)/ 838.000/, Jup(2, 828)/ 151.174/
          data  Jup(1, 829)/ 839.000/, Jup(2, 829)/ 151.190/
          data  Jup(1, 830)/ 840.000/, Jup(2, 830)/ 151.203/
          data  Jup(1, 831)/ 841.000/, Jup(2, 831)/ 151.212/
          data  Jup(1, 832)/ 842.000/, Jup(2, 832)/ 151.218/
          data  Jup(1, 833)/ 843.000/, Jup(2, 833)/ 151.222/
          data  Jup(1, 834)/ 844.000/, Jup(2, 834)/ 151.223/
          data  Jup(1, 835)/ 845.000/, Jup(2, 835)/ 151.222/
          data  Jup(1, 836)/ 846.000/, Jup(2, 836)/ 151.218/
          data  Jup(1, 837)/ 847.000/, Jup(2, 837)/ 151.212/
          data  Jup(1, 838)/ 848.000/, Jup(2, 838)/ 151.205/
          data  Jup(1, 839)/ 849.000/, Jup(2, 839)/ 151.195/
          data  Jup(1, 840)/ 850.000/, Jup(2, 840)/ 151.184/
          data  Jup(1, 841)/ 851.000/, Jup(2, 841)/ 151.172/
          data  Jup(1, 842)/ 852.000/, Jup(2, 842)/ 151.158/
          data  Jup(1, 843)/ 853.000/, Jup(2, 843)/ 151.142/
          data  Jup(1, 844)/ 854.000/, Jup(2, 844)/ 151.125/
          data  Jup(1, 845)/ 855.000/, Jup(2, 845)/ 151.107/
          data  Jup(1, 846)/ 856.000/, Jup(2, 846)/ 151.087/
          data  Jup(1, 847)/ 857.000/, Jup(2, 847)/ 151.067/
          data  Jup(1, 848)/ 858.000/, Jup(2, 848)/ 151.045/
          data  Jup(1, 849)/ 859.000/, Jup(2, 849)/ 151.023/
          data  Jup(1, 850)/ 860.000/, Jup(2, 850)/ 150.999/
          data  Jup(1, 851)/ 861.000/, Jup(2, 851)/ 150.974/
          data  Jup(1, 852)/ 862.000/, Jup(2, 852)/ 150.949/
          data  Jup(1, 853)/ 863.000/, Jup(2, 853)/ 150.922/
          data  Jup(1, 854)/ 864.000/, Jup(2, 854)/ 150.895/
          data  Jup(1, 855)/ 865.000/, Jup(2, 855)/ 150.867/
          data  Jup(1, 856)/ 866.000/, Jup(2, 856)/ 150.837/
          data  Jup(1, 857)/ 867.000/, Jup(2, 857)/ 150.807/
          data  Jup(1, 858)/ 868.000/, Jup(2, 858)/ 150.776/
          data  Jup(1, 859)/ 869.000/, Jup(2, 859)/ 150.745/
          data  Jup(1, 860)/ 870.000/, Jup(2, 860)/ 150.713/
          data  Jup(1, 861)/ 871.000/, Jup(2, 861)/ 150.680/
          data  Jup(1, 862)/ 872.000/, Jup(2, 862)/ 150.647/
          data  Jup(1, 863)/ 873.000/, Jup(2, 863)/ 150.613/
          data  Jup(1, 864)/ 874.000/, Jup(2, 864)/ 150.578/
          data  Jup(1, 865)/ 875.000/, Jup(2, 865)/ 150.543/
          data  Jup(1, 866)/ 876.000/, Jup(2, 866)/ 150.506/
          data  Jup(1, 867)/ 877.000/, Jup(2, 867)/ 150.469/
          data  Jup(1, 868)/ 878.000/, Jup(2, 868)/ 150.432/
          data  Jup(1, 869)/ 879.000/, Jup(2, 869)/ 150.394/
          data  Jup(1, 870)/ 880.000/, Jup(2, 870)/ 150.356/
          data  Jup(1, 871)/ 881.000/, Jup(2, 871)/ 150.317/
          data  Jup(1, 872)/ 882.000/, Jup(2, 872)/ 150.277/
          data  Jup(1, 873)/ 883.000/, Jup(2, 873)/ 150.237/
          data  Jup(1, 874)/ 884.000/, Jup(2, 874)/ 150.196/
          data  Jup(1, 875)/ 885.000/, Jup(2, 875)/ 150.154/
          data  Jup(1, 876)/ 886.000/, Jup(2, 876)/ 150.113/
          data  Jup(1, 877)/ 887.000/, Jup(2, 877)/ 150.070/
          data  Jup(1, 878)/ 888.000/, Jup(2, 878)/ 150.028/
          data  Jup(1, 879)/ 889.000/, Jup(2, 879)/ 149.984/
          data  Jup(1, 880)/ 890.000/, Jup(2, 880)/ 149.940/
          data  Jup(1, 881)/ 891.000/, Jup(2, 881)/ 149.896/
          data  Jup(1, 882)/ 892.000/, Jup(2, 882)/ 149.851/
          data  Jup(1, 883)/ 893.000/, Jup(2, 883)/ 149.806/
          data  Jup(1, 884)/ 894.000/, Jup(2, 884)/ 149.760/
          data  Jup(1, 885)/ 895.000/, Jup(2, 885)/ 149.713/
          data  Jup(1, 886)/ 896.000/, Jup(2, 886)/ 149.667/
          data  Jup(1, 887)/ 897.000/, Jup(2, 887)/ 149.619/
          data  Jup(1, 888)/ 898.000/, Jup(2, 888)/ 149.571/
          data  Jup(1, 889)/ 899.000/, Jup(2, 889)/ 149.523/
          data  Jup(1, 890)/ 900.000/, Jup(2, 890)/ 149.474/
          data  Jup(1, 891)/ 901.000/, Jup(2, 891)/ 149.425/
          data  Jup(1, 892)/ 902.000/, Jup(2, 892)/ 149.376/
          data  Jup(1, 893)/ 903.000/, Jup(2, 893)/ 149.325/
          data  Jup(1, 894)/ 904.000/, Jup(2, 894)/ 149.275/
          data  Jup(1, 895)/ 905.000/, Jup(2, 895)/ 149.224/
          data  Jup(1, 896)/ 906.000/, Jup(2, 896)/ 149.172/
          data  Jup(1, 897)/ 907.000/, Jup(2, 897)/ 149.121/
          data  Jup(1, 898)/ 908.000/, Jup(2, 898)/ 149.068/
          data  Jup(1, 899)/ 909.000/, Jup(2, 899)/ 149.015/
          data  Jup(1, 900)/ 910.000/, Jup(2, 900)/ 148.962/
          data  Jup(1, 901)/ 911.000/, Jup(2, 901)/ 148.908/
          data  Jup(1, 902)/ 912.000/, Jup(2, 902)/ 148.854/
          data  Jup(1, 903)/ 913.000/, Jup(2, 903)/ 148.799/
          data  Jup(1, 904)/ 914.000/, Jup(2, 904)/ 148.744/
          data  Jup(1, 905)/ 915.000/, Jup(2, 905)/ 148.688/
          data  Jup(1, 906)/ 916.000/, Jup(2, 906)/ 148.631/
          data  Jup(1, 907)/ 917.000/, Jup(2, 907)/ 148.573/
          data  Jup(1, 908)/ 918.000/, Jup(2, 908)/ 148.514/
          data  Jup(1, 909)/ 919.000/, Jup(2, 909)/ 148.451/
          data  Jup(1, 910)/ 920.000/, Jup(2, 910)/ 148.382/
          data  Jup(1, 911)/ 921.000/, Jup(2, 911)/ 148.291/
          data  Jup(1, 912)/ 922.000/, Jup(2, 912)/ 148.196/
          data  Jup(1, 913)/ 923.000/, Jup(2, 913)/ 148.192/
          data  Jup(1, 914)/ 924.000/, Jup(2, 914)/ 148.153/
          data  Jup(1, 915)/ 925.000/, Jup(2, 915)/ 148.100/
          data  Jup(1, 916)/ 926.000/, Jup(2, 916)/ 148.043/
          data  Jup(1, 917)/ 927.000/, Jup(2, 917)/ 147.980/
          data  Jup(1, 918)/ 928.000/, Jup(2, 918)/ 147.912/
          data  Jup(1, 919)/ 929.000/, Jup(2, 919)/ 147.826/
          data  Jup(1, 920)/ 930.000/, Jup(2, 920)/ 147.616/
          data  Jup(1, 921)/ 931.000/, Jup(2, 921)/ 147.691/
          data  Jup(1, 922)/ 932.000/, Jup(2, 922)/ 147.665/
          data  Jup(1, 923)/ 933.000/, Jup(2, 923)/ 147.614/
          data  Jup(1, 924)/ 934.000/, Jup(2, 924)/ 147.555/
          data  Jup(1, 925)/ 935.000/, Jup(2, 925)/ 147.494/
          data  Jup(1, 926)/ 936.000/, Jup(2, 926)/ 147.432/
          data  Jup(1, 927)/ 937.000/, Jup(2, 927)/ 147.369/
          data  Jup(1, 928)/ 938.000/, Jup(2, 928)/ 147.305/
          data  Jup(1, 929)/ 939.000/, Jup(2, 929)/ 147.240/
          data  Jup(1, 930)/ 940.000/, Jup(2, 930)/ 147.175/
          data  Jup(1, 931)/ 941.000/, Jup(2, 931)/ 147.110/
          data  Jup(1, 932)/ 942.000/, Jup(2, 932)/ 147.044/
          data  Jup(1, 933)/ 943.000/, Jup(2, 933)/ 146.977/
          data  Jup(1, 934)/ 944.000/, Jup(2, 934)/ 146.911/
          data  Jup(1, 935)/ 945.000/, Jup(2, 935)/ 146.844/
          data  Jup(1, 936)/ 946.000/, Jup(2, 936)/ 146.776/
          data  Jup(1, 937)/ 947.000/, Jup(2, 937)/ 146.708/
          data  Jup(1, 938)/ 948.000/, Jup(2, 938)/ 146.640/
          data  Jup(1, 939)/ 949.000/, Jup(2, 939)/ 146.571/
          data  Jup(1, 940)/ 950.000/, Jup(2, 940)/ 146.502/
          data  Jup(1, 941)/ 951.000/, Jup(2, 941)/ 146.432/
          data  Jup(1, 942)/ 952.000/, Jup(2, 942)/ 146.362/
          data  Jup(1, 943)/ 953.000/, Jup(2, 943)/ 146.292/
          data  Jup(1, 944)/ 954.000/, Jup(2, 944)/ 146.221/
          data  Jup(1, 945)/ 955.000/, Jup(2, 945)/ 146.150/
          data  Jup(1, 946)/ 956.000/, Jup(2, 946)/ 146.079/
          data  Jup(1, 947)/ 957.000/, Jup(2, 947)/ 146.007/
          data  Jup(1, 948)/ 958.000/, Jup(2, 948)/ 145.935/
          data  Jup(1, 949)/ 959.000/, Jup(2, 949)/ 145.862/
          data  Jup(1, 950)/ 960.000/, Jup(2, 950)/ 145.789/
          data  Jup(1, 951)/ 961.000/, Jup(2, 951)/ 145.716/
          data  Jup(1, 952)/ 962.000/, Jup(2, 952)/ 145.642/
          data  Jup(1, 953)/ 963.000/, Jup(2, 953)/ 145.568/
          data  Jup(1, 954)/ 964.000/, Jup(2, 954)/ 145.494/
          data  Jup(1, 955)/ 965.000/, Jup(2, 955)/ 145.419/
          data  Jup(1, 956)/ 966.000/, Jup(2, 956)/ 145.344/
          data  Jup(1, 957)/ 967.000/, Jup(2, 957)/ 145.268/
          data  Jup(1, 958)/ 968.000/, Jup(2, 958)/ 145.192/
          data  Jup(1, 959)/ 969.000/, Jup(2, 959)/ 145.116/
          data  Jup(1, 960)/ 970.000/, Jup(2, 960)/ 145.039/
          data  Jup(1, 961)/ 971.000/, Jup(2, 961)/ 144.962/
          data  Jup(1, 962)/ 972.000/, Jup(2, 962)/ 144.885/
          data  Jup(1, 963)/ 973.000/, Jup(2, 963)/ 144.807/
          data  Jup(1, 964)/ 974.000/, Jup(2, 964)/ 144.728/
          data  Jup(1, 965)/ 975.000/, Jup(2, 965)/ 144.650/
          data  Jup(1, 966)/ 976.000/, Jup(2, 966)/ 144.571/
          data  Jup(1, 967)/ 977.000/, Jup(2, 967)/ 144.491/
          data  Jup(1, 968)/ 978.000/, Jup(2, 968)/ 144.412/
          data  Jup(1, 969)/ 979.000/, Jup(2, 969)/ 144.332/
          data  Jup(1, 970)/ 980.000/, Jup(2, 970)/ 144.251/
          data  Jup(1, 971)/ 981.000/, Jup(2, 971)/ 144.170/
          data  Jup(1, 972)/ 982.000/, Jup(2, 972)/ 144.089/
          data  Jup(1, 973)/ 983.000/, Jup(2, 973)/ 144.007/
          data  Jup(1, 974)/ 984.000/, Jup(2, 974)/ 143.924/
          data  Jup(1, 975)/ 985.000/, Jup(2, 975)/ 143.842/
          data  Jup(1, 976)/ 986.000/, Jup(2, 976)/ 143.759/
          data  Jup(1, 977)/ 987.000/, Jup(2, 977)/ 143.676/
          data  Jup(1, 978)/ 988.000/, Jup(2, 978)/ 143.592/
          data  Jup(1, 979)/ 989.000/, Jup(2, 979)/ 143.507/
          data  Jup(1, 980)/ 990.000/, Jup(2, 980)/ 143.422/
          data  Jup(1, 981)/ 991.000/, Jup(2, 981)/ 143.337/
          data  Jup(1, 982)/ 992.000/, Jup(2, 982)/ 143.252/
          data  Jup(1, 983)/ 993.000/, Jup(2, 983)/ 143.166/
          data  Jup(1, 984)/ 994.000/, Jup(2, 984)/ 143.079/
          data  Jup(1, 985)/ 995.000/, Jup(2, 985)/ 142.992/
          data  Jup(1, 986)/ 996.000/, Jup(2, 986)/ 142.904/
          data  Jup(1, 987)/ 997.000/, Jup(2, 987)/ 142.816/
          data  Jup(1, 988)/ 998.000/, Jup(2, 988)/ 142.728/
          data  Jup(1, 989)/ 999.000/, Jup(2, 989)/ 142.639/
          data  Jup(1, 990)/1000.000/, Jup(2, 990)/ 142.549/
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c!Saturn model - from Eric Weisstein's JOVIAN
c!H2 type: intermediate-frozen
c!H2 form: D&B
c!He form: D&B
c!H2 mxr: 0.963
c!PH3 mxr: 3.E-06 for  p > 1.E-01 bar
c!HCN mxr: 1.E-10 for 999.0 > p >   0. bar.
c!            Planck    Planck    Rad. Intensity
c!                          Freq(GHz)             WDTB(Kelvin) 
          data  Sat(1,   1)/  11.000/,Sat(2,   1)/ 148.535/
          data  Sat(1,   2)/  12.000/,Sat(2,   2)/ 146.572/
          data  Sat(1,   3)/  13.000/,Sat(2,   3)/ 144.790/
          data  Sat(1,   4)/  14.000/,Sat(2,   4)/ 143.113/
          data  Sat(1,   5)/  15.000/,Sat(2,   5)/ 141.485/
          data  Sat(1,   6)/  16.000/,Sat(2,   6)/ 139.865/
          data  Sat(1,   7)/  17.000/,Sat(2,   7)/ 138.232/
          data  Sat(1,   8)/  18.000/,Sat(2,   8)/ 136.576/
          data  Sat(1,   9)/  19.000/,Sat(2,   9)/ 134.904/
          data  Sat(1,  10)/  20.000/,Sat(2,  10)/ 133.237/
          data  Sat(1,  11)/  21.000/,Sat(2,  11)/ 131.629/
          data  Sat(1,  12)/  22.000/,Sat(2,  12)/ 130.181/
          data  Sat(1,  13)/  23.000/,Sat(2,  13)/ 129.084/
          data  Sat(1,  14)/  24.000/,Sat(2,  14)/ 128.581/
          data  Sat(1,  15)/  25.000/,Sat(2,  15)/ 128.761/
          data  Sat(1,  16)/  26.000/,Sat(2,  16)/ 129.421/
          data  Sat(1,  17)/  27.000/,Sat(2,  17)/ 130.288/
          data  Sat(1,  18)/  28.000/,Sat(2,  18)/ 131.190/
          data  Sat(1,  19)/  29.000/,Sat(2,  19)/ 132.051/
          data  Sat(1,  20)/  30.000/,Sat(2,  20)/ 132.842/
          data  Sat(1,  21)/  31.000/,Sat(2,  21)/ 133.557/
          data  Sat(1,  22)/  32.000/,Sat(2,  22)/ 134.199/
          data  Sat(1,  23)/  33.000/,Sat(2,  23)/ 134.776/
          data  Sat(1,  24)/  34.000/,Sat(2,  24)/ 135.295/
          data  Sat(1,  25)/  35.000/,Sat(2,  25)/ 135.764/
          data  Sat(1,  26)/  36.000/,Sat(2,  26)/ 136.188/
          data  Sat(1,  27)/  37.000/,Sat(2,  27)/ 136.574/
          data  Sat(1,  28)/  38.000/,Sat(2,  28)/ 136.925/
          data  Sat(1,  29)/  39.000/,Sat(2,  29)/ 137.246/
          data  Sat(1,  30)/  40.000/,Sat(2,  30)/ 137.540/
          data  Sat(1,  31)/  41.000/,Sat(2,  31)/ 137.810/
          data  Sat(1,  32)/  42.000/,Sat(2,  32)/ 138.060/
          data  Sat(1,  33)/  43.000/,Sat(2,  33)/ 138.290/
          data  Sat(1,  34)/  44.000/,Sat(2,  34)/ 138.503/
          data  Sat(1,  35)/  45.000/,Sat(2,  35)/ 138.701/
          data  Sat(1,  36)/  46.000/,Sat(2,  36)/ 138.884/
          data  Sat(1,  37)/  47.000/,Sat(2,  37)/ 139.056/
          data  Sat(1,  38)/  48.000/,Sat(2,  38)/ 139.215/
          data  Sat(1,  39)/  49.000/,Sat(2,  39)/ 139.364/
          data  Sat(1,  40)/  50.000/,Sat(2,  40)/ 139.503/
          data  Sat(1,  41)/  51.000/,Sat(2,  41)/ 139.634/
          data  Sat(1,  42)/  52.000/,Sat(2,  42)/ 139.757/
          data  Sat(1,  43)/  53.000/,Sat(2,  43)/ 139.871/
          data  Sat(1,  44)/  54.000/,Sat(2,  44)/ 139.979/
          data  Sat(1,  45)/  55.000/,Sat(2,  45)/ 140.081/
          data  Sat(1,  46)/  56.000/,Sat(2,  46)/ 140.177/
          data  Sat(1,  47)/  57.000/,Sat(2,  47)/ 140.267/
          data  Sat(1,  48)/  58.000/,Sat(2,  48)/ 140.352/
          data  Sat(1,  49)/  59.000/,Sat(2,  49)/ 140.432/
          data  Sat(1,  50)/  60.000/,Sat(2,  50)/ 140.509/
          data  Sat(1,  51)/  61.000/,Sat(2,  51)/ 140.581/
          data  Sat(1,  52)/  62.000/,Sat(2,  52)/ 140.649/
          data  Sat(1,  53)/  63.000/,Sat(2,  53)/ 140.713/
          data  Sat(1,  54)/  64.000/,Sat(2,  54)/ 140.774/
          data  Sat(1,  55)/  65.000/,Sat(2,  55)/ 140.832/
          data  Sat(1,  56)/  66.000/,Sat(2,  56)/ 140.887/
          data  Sat(1,  57)/  67.000/,Sat(2,  57)/ 140.939/
          data  Sat(1,  58)/  68.000/,Sat(2,  58)/ 140.988/
          data  Sat(1,  59)/  69.000/,Sat(2,  59)/ 141.035/
          data  Sat(1,  60)/  70.000/,Sat(2,  60)/ 141.079/
          data  Sat(1,  61)/  71.000/,Sat(2,  61)/ 141.122/
          data  Sat(1,  62)/  72.000/,Sat(2,  62)/ 141.162/
          data  Sat(1,  63)/  73.000/,Sat(2,  63)/ 141.200/
          data  Sat(1,  64)/  74.000/,Sat(2,  64)/ 141.236/
          data  Sat(1,  65)/  75.000/,Sat(2,  65)/ 141.270/
          data  Sat(1,  66)/  76.000/,Sat(2,  66)/ 141.303/
          data  Sat(1,  67)/  77.000/,Sat(2,  67)/ 141.334/
          data  Sat(1,  68)/  78.000/,Sat(2,  68)/ 141.363/
          data  Sat(1,  69)/  79.000/,Sat(2,  69)/ 141.391/
          data  Sat(1,  70)/  80.000/,Sat(2,  70)/ 141.417/
          data  Sat(1,  71)/  81.000/,Sat(2,  71)/ 141.441/
          data  Sat(1,  72)/  82.000/,Sat(2,  72)/ 141.463/
          data  Sat(1,  73)/  83.000/,Sat(2,  73)/ 141.484/
          data  Sat(1,  74)/  84.000/,Sat(2,  74)/ 141.502/
          data  Sat(1,  75)/  85.000/,Sat(2,  75)/ 141.518/
          data  Sat(1,  76)/  86.000/,Sat(2,  76)/ 141.529/
          data  Sat(1,  77)/  87.000/,Sat(2,  77)/ 141.533/
          data  Sat(1,  78)/  88.000/,Sat(2,  78)/ 141.515/
          data  Sat(1,  79)/  89.000/,Sat(2,  79)/ 141.513/
          data  Sat(1,  80)/  90.000/,Sat(2,  80)/ 141.577/
          data  Sat(1,  81)/  91.000/,Sat(2,  81)/ 141.611/
          data  Sat(1,  82)/  92.000/,Sat(2,  82)/ 141.635/
          data  Sat(1,  83)/  93.000/,Sat(2,  83)/ 141.654/
          data  Sat(1,  84)/  94.000/,Sat(2,  84)/ 141.671/
          data  Sat(1,  85)/  95.000/,Sat(2,  85)/ 141.685/
          data  Sat(1,  86)/  96.000/,Sat(2,  86)/ 141.699/
          data  Sat(1,  87)/  97.000/,Sat(2,  87)/ 141.711/
          data  Sat(1,  88)/  98.000/,Sat(2,  88)/ 141.722/
          data  Sat(1,  89)/  99.000/,Sat(2,  89)/ 141.732/
          data  Sat(1,  90)/ 100.000/,Sat(2,  90)/ 141.741/
          data  Sat(1,  91)/ 101.000/,Sat(2,  91)/ 141.750/
          data  Sat(1,  92)/ 102.000/,Sat(2,  92)/ 141.758/
          data  Sat(1,  93)/ 103.000/,Sat(2,  93)/ 141.765/
          data  Sat(1,  94)/ 104.000/,Sat(2,  94)/ 141.772/
          data  Sat(1,  95)/ 105.000/,Sat(2,  95)/ 141.778/
          data  Sat(1,  96)/ 106.000/,Sat(2,  96)/ 141.783/
          data  Sat(1,  97)/ 107.000/,Sat(2,  97)/ 141.788/
          data  Sat(1,  98)/ 108.000/,Sat(2,  98)/ 141.792/
          data  Sat(1,  99)/ 109.000/,Sat(2,  99)/ 141.796/
          data  Sat(1, 100)/ 110.000/,Sat(2, 100)/ 141.800/
          data  Sat(1, 101)/ 111.000/,Sat(2, 101)/ 141.803/
          data  Sat(1, 102)/ 112.000/,Sat(2, 102)/ 141.806/
          data  Sat(1, 103)/ 113.000/,Sat(2, 103)/ 141.807/
          data  Sat(1, 104)/ 114.000/,Sat(2, 104)/ 141.808/
          data  Sat(1, 105)/ 115.000/,Sat(2, 105)/ 141.807/
          data  Sat(1, 106)/ 116.000/,Sat(2, 106)/ 141.810/
          data  Sat(1, 107)/ 117.000/,Sat(2, 107)/ 141.812/
          data  Sat(1, 108)/ 118.000/,Sat(2, 108)/ 141.813/
          data  Sat(1, 109)/ 119.000/,Sat(2, 109)/ 141.813/
          data  Sat(1, 110)/ 120.000/,Sat(2, 110)/ 141.812/
          data  Sat(1, 111)/ 121.000/,Sat(2, 111)/ 141.812/
          data  Sat(1, 112)/ 122.000/,Sat(2, 112)/ 141.810/
          data  Sat(1, 113)/ 123.000/,Sat(2, 113)/ 141.809/
          data  Sat(1, 114)/ 124.000/,Sat(2, 114)/ 141.807/
          data  Sat(1, 115)/ 125.000/,Sat(2, 115)/ 141.805/
          data  Sat(1, 116)/ 126.000/,Sat(2, 116)/ 141.803/
          data  Sat(1, 117)/ 127.000/,Sat(2, 117)/ 141.800/
          data  Sat(1, 118)/ 128.000/,Sat(2, 118)/ 141.797/
          data  Sat(1, 119)/ 129.000/,Sat(2, 119)/ 141.793/
          data  Sat(1, 120)/ 130.000/,Sat(2, 120)/ 141.790/
          data  Sat(1, 121)/ 131.000/,Sat(2, 121)/ 141.786/
          data  Sat(1, 122)/ 132.000/,Sat(2, 122)/ 141.781/
          data  Sat(1, 123)/ 133.000/,Sat(2, 123)/ 141.777/
          data  Sat(1, 124)/ 134.000/,Sat(2, 124)/ 141.772/
          data  Sat(1, 125)/ 135.000/,Sat(2, 125)/ 141.767/
          data  Sat(1, 126)/ 136.000/,Sat(2, 126)/ 141.762/
          data  Sat(1, 127)/ 137.000/,Sat(2, 127)/ 141.756/
          data  Sat(1, 128)/ 138.000/,Sat(2, 128)/ 141.750/
          data  Sat(1, 129)/ 139.000/,Sat(2, 129)/ 141.744/
          data  Sat(1, 130)/ 140.000/,Sat(2, 130)/ 141.737/
          data  Sat(1, 131)/ 141.000/,Sat(2, 131)/ 141.730/
          data  Sat(1, 132)/ 142.000/,Sat(2, 132)/ 141.723/
          data  Sat(1, 133)/ 143.000/,Sat(2, 133)/ 141.716/
          data  Sat(1, 134)/ 144.000/,Sat(2, 134)/ 141.708/
          data  Sat(1, 135)/ 145.000/,Sat(2, 135)/ 141.700/
          data  Sat(1, 136)/ 146.000/,Sat(2, 136)/ 141.692/
          data  Sat(1, 137)/ 147.000/,Sat(2, 137)/ 141.684/
          data  Sat(1, 138)/ 148.000/,Sat(2, 138)/ 141.675/
          data  Sat(1, 139)/ 149.000/,Sat(2, 139)/ 141.666/
          data  Sat(1, 140)/ 150.000/,Sat(2, 140)/ 141.657/
          data  Sat(1, 141)/ 151.000/,Sat(2, 141)/ 141.647/
          data  Sat(1, 142)/ 152.000/,Sat(2, 142)/ 141.638/
          data  Sat(1, 143)/ 153.000/,Sat(2, 143)/ 141.628/
          data  Sat(1, 144)/ 154.000/,Sat(2, 144)/ 141.617/
          data  Sat(1, 145)/ 155.000/,Sat(2, 145)/ 141.607/
          data  Sat(1, 146)/ 156.000/,Sat(2, 146)/ 141.595/
          data  Sat(1, 147)/ 157.000/,Sat(2, 147)/ 141.584/
          data  Sat(1, 148)/ 158.000/,Sat(2, 148)/ 141.572/
          data  Sat(1, 149)/ 159.000/,Sat(2, 149)/ 141.560/
          data  Sat(1, 150)/ 160.000/,Sat(2, 150)/ 141.547/
          data  Sat(1, 151)/ 161.000/,Sat(2, 151)/ 141.534/
          data  Sat(1, 152)/ 162.000/,Sat(2, 152)/ 141.520/
          data  Sat(1, 153)/ 163.000/,Sat(2, 153)/ 141.506/
          data  Sat(1, 154)/ 164.000/,Sat(2, 154)/ 141.491/
          data  Sat(1, 155)/ 165.000/,Sat(2, 155)/ 141.475/
          data  Sat(1, 156)/ 166.000/,Sat(2, 156)/ 141.458/
          data  Sat(1, 157)/ 167.000/,Sat(2, 157)/ 141.439/
          data  Sat(1, 158)/ 168.000/,Sat(2, 158)/ 141.419/
          data  Sat(1, 159)/ 169.000/,Sat(2, 159)/ 141.397/
          data  Sat(1, 160)/ 170.000/,Sat(2, 160)/ 141.372/
          data  Sat(1, 161)/ 171.000/,Sat(2, 161)/ 141.343/
          data  Sat(1, 162)/ 172.000/,Sat(2, 162)/ 141.307/
          data  Sat(1, 163)/ 173.000/,Sat(2, 163)/ 141.261/
          data  Sat(1, 164)/ 174.000/,Sat(2, 164)/ 141.198/
          data  Sat(1, 165)/ 175.000/,Sat(2, 165)/ 141.105/
          data  Sat(1, 166)/ 176.000/,Sat(2, 166)/ 140.940/
          data  Sat(1, 167)/ 177.000/,Sat(2, 167)/ 140.505/
          data  Sat(1, 168)/ 178.000/,Sat(2, 168)/ 140.760/
          data  Sat(1, 169)/ 179.000/,Sat(2, 169)/ 140.976/
          data  Sat(1, 170)/ 180.000/,Sat(2, 170)/ 141.066/
          data  Sat(1, 171)/ 181.000/,Sat(2, 171)/ 141.109/
          data  Sat(1, 172)/ 182.000/,Sat(2, 172)/ 141.130/
          data  Sat(1, 173)/ 183.000/,Sat(2, 173)/ 141.137/
          data  Sat(1, 174)/ 184.000/,Sat(2, 174)/ 141.137/
          data  Sat(1, 175)/ 185.000/,Sat(2, 175)/ 141.131/
          data  Sat(1, 176)/ 186.000/,Sat(2, 176)/ 141.121/
          data  Sat(1, 177)/ 187.000/,Sat(2, 177)/ 141.109/
          data  Sat(1, 178)/ 188.000/,Sat(2, 178)/ 141.095/
          data  Sat(1, 179)/ 189.000/,Sat(2, 179)/ 141.079/
          data  Sat(1, 180)/ 190.000/,Sat(2, 180)/ 141.061/
          data  Sat(1, 181)/ 191.000/,Sat(2, 181)/ 141.043/
          data  Sat(1, 182)/ 192.000/,Sat(2, 182)/ 141.023/
          data  Sat(1, 183)/ 193.000/,Sat(2, 183)/ 141.002/
          data  Sat(1, 184)/ 194.000/,Sat(2, 184)/ 140.981/
          data  Sat(1, 185)/ 195.000/,Sat(2, 185)/ 140.959/
          data  Sat(1, 186)/ 196.000/,Sat(2, 186)/ 140.936/
          data  Sat(1, 187)/ 197.000/,Sat(2, 187)/ 140.912/
          data  Sat(1, 188)/ 198.000/,Sat(2, 188)/ 140.887/
          data  Sat(1, 189)/ 199.000/,Sat(2, 189)/ 140.861/
          data  Sat(1, 190)/ 200.000/,Sat(2, 190)/ 140.835/
          data  Sat(1, 191)/ 201.000/,Sat(2, 191)/ 140.808/
          data  Sat(1, 192)/ 202.000/,Sat(2, 192)/ 140.780/
          data  Sat(1, 193)/ 203.000/,Sat(2, 193)/ 140.751/
          data  Sat(1, 194)/ 204.000/,Sat(2, 194)/ 140.721/
          data  Sat(1, 195)/ 205.000/,Sat(2, 195)/ 140.691/
          data  Sat(1, 196)/ 206.000/,Sat(2, 196)/ 140.659/
          data  Sat(1, 197)/ 207.000/,Sat(2, 197)/ 140.626/
          data  Sat(1, 198)/ 208.000/,Sat(2, 198)/ 140.592/
          data  Sat(1, 199)/ 209.000/,Sat(2, 199)/ 140.557/
          data  Sat(1, 200)/ 210.000/,Sat(2, 200)/ 140.521/
          data  Sat(1, 201)/ 211.000/,Sat(2, 201)/ 140.483/
          data  Sat(1, 202)/ 212.000/,Sat(2, 202)/ 140.444/
          data  Sat(1, 203)/ 213.000/,Sat(2, 203)/ 140.403/
          data  Sat(1, 204)/ 214.000/,Sat(2, 204)/ 140.361/
          data  Sat(1, 205)/ 215.000/,Sat(2, 205)/ 140.317/
          data  Sat(1, 206)/ 216.000/,Sat(2, 206)/ 140.272/
          data  Sat(1, 207)/ 217.000/,Sat(2, 207)/ 140.224/
          data  Sat(1, 208)/ 218.000/,Sat(2, 208)/ 140.174/
          data  Sat(1, 209)/ 219.000/,Sat(2, 209)/ 140.122/
          data  Sat(1, 210)/ 220.000/,Sat(2, 210)/ 140.067/
          data  Sat(1, 211)/ 221.000/,Sat(2, 211)/ 140.010/
          data  Sat(1, 212)/ 222.000/,Sat(2, 212)/ 139.950/
          data  Sat(1, 213)/ 223.000/,Sat(2, 213)/ 139.887/
          data  Sat(1, 214)/ 224.000/,Sat(2, 214)/ 139.820/
          data  Sat(1, 215)/ 225.000/,Sat(2, 215)/ 139.749/
          data  Sat(1, 216)/ 226.000/,Sat(2, 216)/ 139.674/
          data  Sat(1, 217)/ 227.000/,Sat(2, 217)/ 139.595/
          data  Sat(1, 218)/ 228.000/,Sat(2, 218)/ 139.509/
          data  Sat(1, 219)/ 229.000/,Sat(2, 219)/ 139.416/
          data  Sat(1, 220)/ 230.000/,Sat(2, 220)/ 139.307/
          data  Sat(1, 221)/ 231.000/,Sat(2, 221)/ 139.204/
          data  Sat(1, 222)/ 232.000/,Sat(2, 222)/ 139.112/
          data  Sat(1, 223)/ 233.000/,Sat(2, 223)/ 139.001/
          data  Sat(1, 224)/ 234.000/,Sat(2, 224)/ 138.879/
          data  Sat(1, 225)/ 235.000/,Sat(2, 225)/ 138.745/
          data  Sat(1, 226)/ 236.000/,Sat(2, 226)/ 138.600/
          data  Sat(1, 227)/ 237.000/,Sat(2, 227)/ 138.443/
          data  Sat(1, 228)/ 238.000/,Sat(2, 228)/ 138.271/
          data  Sat(1, 229)/ 239.000/,Sat(2, 229)/ 138.083/
          data  Sat(1, 230)/ 240.000/,Sat(2, 230)/ 137.878/
          data  Sat(1, 231)/ 241.000/,Sat(2, 231)/ 137.652/
          data  Sat(1, 232)/ 242.000/,Sat(2, 232)/ 137.402/
          data  Sat(1, 233)/ 243.000/,Sat(2, 233)/ 137.125/
          data  Sat(1, 234)/ 244.000/,Sat(2, 234)/ 136.817/
          data  Sat(1, 235)/ 245.000/,Sat(2, 235)/ 136.474/
          data  Sat(1, 236)/ 246.000/,Sat(2, 236)/ 136.088/
          data  Sat(1, 237)/ 247.000/,Sat(2, 237)/ 135.652/
          data  Sat(1, 238)/ 248.000/,Sat(2, 238)/ 135.158/
          data  Sat(1, 239)/ 249.000/,Sat(2, 239)/ 134.596/
          data  Sat(1, 240)/ 250.000/,Sat(2, 240)/ 133.951/
          data  Sat(1, 241)/ 251.000/,Sat(2, 241)/ 133.207/
          data  Sat(1, 242)/ 252.000/,Sat(2, 242)/ 132.343/
          data  Sat(1, 243)/ 253.000/,Sat(2, 243)/ 131.336/
          data  Sat(1, 244)/ 254.000/,Sat(2, 244)/ 130.152/
          data  Sat(1, 245)/ 255.000/,Sat(2, 245)/ 128.753/
          data  Sat(1, 246)/ 256.000/,Sat(2, 246)/ 127.088/
          data  Sat(1, 247)/ 257.000/,Sat(2, 247)/ 125.097/
          data  Sat(1, 248)/ 258.000/,Sat(2, 248)/ 122.706/
          data  Sat(1, 249)/ 259.000/,Sat(2, 249)/ 119.826/
          data  Sat(1, 250)/ 260.000/,Sat(2, 250)/ 116.363/
          data  Sat(1, 251)/ 261.000/,Sat(2, 251)/ 112.224/
          data  Sat(1, 252)/ 262.000/,Sat(2, 252)/ 107.358/
          data  Sat(1, 253)/ 263.000/,Sat(2, 253)/ 101.818/
          data  Sat(1, 254)/ 264.000/,Sat(2, 254)/  95.871/
          data  Sat(1, 255)/ 265.000/,Sat(2, 255)/  90.123/
          data  Sat(1, 256)/ 266.000/,Sat(2, 256)/  85.735/
          data  Sat(1, 257)/ 267.000/,Sat(2, 257)/  83.891/
          data  Sat(1, 258)/ 268.000/,Sat(2, 258)/  86.062/
          data  Sat(1, 259)/ 269.000/,Sat(2, 259)/  90.792/
          data  Sat(1, 260)/ 270.000/,Sat(2, 260)/  96.590/
          data  Sat(1, 261)/ 271.000/,Sat(2, 261)/ 102.495/
          data  Sat(1, 262)/ 272.000/,Sat(2, 262)/ 107.940/
          data  Sat(1, 263)/ 273.000/,Sat(2, 263)/ 112.689/
          data  Sat(1, 264)/ 274.000/,Sat(2, 264)/ 116.709/
          data  Sat(1, 265)/ 275.000/,Sat(2, 265)/ 120.058/
          data  Sat(1, 266)/ 276.000/,Sat(2, 266)/ 122.833/
          data  Sat(1, 267)/ 277.000/,Sat(2, 267)/ 125.128/
          data  Sat(1, 268)/ 278.000/,Sat(2, 268)/ 127.031/
          data  Sat(1, 269)/ 279.000/,Sat(2, 269)/ 128.615/
          data  Sat(1, 270)/ 280.000/,Sat(2, 270)/ 129.940/
          data  Sat(1, 271)/ 281.000/,Sat(2, 271)/ 131.055/
          data  Sat(1, 272)/ 282.000/,Sat(2, 272)/ 131.997/
          data  Sat(1, 273)/ 283.000/,Sat(2, 273)/ 132.799/
          data  Sat(1, 274)/ 284.000/,Sat(2, 274)/ 133.484/
          data  Sat(1, 275)/ 285.000/,Sat(2, 275)/ 134.073/
          data  Sat(1, 276)/ 286.000/,Sat(2, 276)/ 134.581/
          data  Sat(1, 277)/ 287.000/,Sat(2, 277)/ 135.023/
          data  Sat(1, 278)/ 288.000/,Sat(2, 278)/ 135.407/
          data  Sat(1, 279)/ 289.000/,Sat(2, 279)/ 135.742/
          data  Sat(1, 280)/ 290.000/,Sat(2, 280)/ 136.037/
          data  Sat(1, 281)/ 291.000/,Sat(2, 281)/ 136.296/
          data  Sat(1, 282)/ 292.000/,Sat(2, 282)/ 136.525/
          data  Sat(1, 283)/ 293.000/,Sat(2, 283)/ 136.728/
          data  Sat(1, 284)/ 294.000/,Sat(2, 284)/ 136.907/
          data  Sat(1, 285)/ 295.000/,Sat(2, 285)/ 137.067/
          data  Sat(1, 286)/ 296.000/,Sat(2, 286)/ 137.209/
          data  Sat(1, 287)/ 297.000/,Sat(2, 287)/ 137.335/
          data  Sat(1, 288)/ 298.000/,Sat(2, 288)/ 137.448/
          data  Sat(1, 289)/ 299.000/,Sat(2, 289)/ 137.549/
          data  Sat(1, 290)/ 300.000/,Sat(2, 290)/ 137.639/
          data  Sat(1, 291)/ 301.000/,Sat(2, 291)/ 137.719/
          data  Sat(1, 292)/ 302.000/,Sat(2, 292)/ 137.791/
          data  Sat(1, 293)/ 303.000/,Sat(2, 293)/ 137.855/
          data  Sat(1, 294)/ 304.000/,Sat(2, 294)/ 137.912/
          data  Sat(1, 295)/ 305.000/,Sat(2, 295)/ 137.963/
          data  Sat(1, 296)/ 306.000/,Sat(2, 296)/ 138.007/
          data  Sat(1, 297)/ 307.000/,Sat(2, 297)/ 138.047/
          data  Sat(1, 298)/ 308.000/,Sat(2, 298)/ 138.082/
          data  Sat(1, 299)/ 309.000/,Sat(2, 299)/ 138.113/
          data  Sat(1, 300)/ 310.000/,Sat(2, 300)/ 138.139/
          data  Sat(1, 301)/ 311.000/,Sat(2, 301)/ 138.162/
          data  Sat(1, 302)/ 312.000/,Sat(2, 302)/ 138.182/
          data  Sat(1, 303)/ 313.000/,Sat(2, 303)/ 138.198/
          data  Sat(1, 304)/ 314.000/,Sat(2, 304)/ 138.212/
          data  Sat(1, 305)/ 315.000/,Sat(2, 305)/ 138.223/
          data  Sat(1, 306)/ 316.000/,Sat(2, 306)/ 138.231/
          data  Sat(1, 307)/ 317.000/,Sat(2, 307)/ 138.237/
          data  Sat(1, 308)/ 318.000/,Sat(2, 308)/ 138.241/
          data  Sat(1, 309)/ 319.000/,Sat(2, 309)/ 138.243/
          data  Sat(1, 310)/ 320.000/,Sat(2, 310)/ 138.243/
          data  Sat(1, 311)/ 321.000/,Sat(2, 311)/ 138.242/
          data  Sat(1, 312)/ 322.000/,Sat(2, 312)/ 138.238/
          data  Sat(1, 313)/ 323.000/,Sat(2, 313)/ 138.233/
          data  Sat(1, 314)/ 324.000/,Sat(2, 314)/ 138.226/
          data  Sat(1, 315)/ 325.000/,Sat(2, 315)/ 138.218/
          data  Sat(1, 316)/ 326.000/,Sat(2, 316)/ 138.208/
          data  Sat(1, 317)/ 327.000/,Sat(2, 317)/ 138.197/
          data  Sat(1, 318)/ 328.000/,Sat(2, 318)/ 138.185/
          data  Sat(1, 319)/ 329.000/,Sat(2, 319)/ 138.171/
          data  Sat(1, 320)/ 330.000/,Sat(2, 320)/ 138.156/
          data  Sat(1, 321)/ 331.000/,Sat(2, 321)/ 138.140/
          data  Sat(1, 322)/ 332.000/,Sat(2, 322)/ 138.122/
          data  Sat(1, 323)/ 333.000/,Sat(2, 323)/ 138.102/
          data  Sat(1, 324)/ 334.000/,Sat(2, 324)/ 138.082/
          data  Sat(1, 325)/ 335.000/,Sat(2, 325)/ 138.059/
          data  Sat(1, 326)/ 336.000/,Sat(2, 326)/ 138.035/
          data  Sat(1, 327)/ 337.000/,Sat(2, 327)/ 138.010/
          data  Sat(1, 328)/ 338.000/,Sat(2, 328)/ 137.982/
          data  Sat(1, 329)/ 339.000/,Sat(2, 329)/ 137.951/
          data  Sat(1, 330)/ 340.000/,Sat(2, 330)/ 137.918/
          data  Sat(1, 331)/ 341.000/,Sat(2, 331)/ 137.881/
          data  Sat(1, 332)/ 342.000/,Sat(2, 332)/ 137.839/
          data  Sat(1, 333)/ 343.000/,Sat(2, 333)/ 137.790/
          data  Sat(1, 334)/ 344.000/,Sat(2, 334)/ 137.729/
          data  Sat(1, 335)/ 345.000/,Sat(2, 335)/ 137.641/
          data  Sat(1, 336)/ 346.000/,Sat(2, 336)/ 137.525/
          data  Sat(1, 337)/ 347.000/,Sat(2, 337)/ 137.505/
          data  Sat(1, 338)/ 348.000/,Sat(2, 338)/ 137.419/
          data  Sat(1, 339)/ 349.000/,Sat(2, 339)/ 137.291/
          data  Sat(1, 340)/ 350.000/,Sat(2, 340)/ 137.110/
          data  Sat(1, 341)/ 351.000/,Sat(2, 341)/ 136.849/
          data  Sat(1, 342)/ 352.000/,Sat(2, 342)/ 136.442/
          data  Sat(1, 343)/ 353.000/,Sat(2, 343)/ 135.733/
          data  Sat(1, 344)/ 354.000/,Sat(2, 344)/ 134.098/
          data  Sat(1, 345)/ 355.000/,Sat(2, 345)/ 134.042/
          data  Sat(1, 346)/ 356.000/,Sat(2, 346)/ 135.643/
          data  Sat(1, 347)/ 357.000/,Sat(2, 347)/ 136.302/
          data  Sat(1, 348)/ 358.000/,Sat(2, 348)/ 136.656/
          data  Sat(1, 349)/ 359.000/,Sat(2, 349)/ 136.864/
          data  Sat(1, 350)/ 360.000/,Sat(2, 350)/ 136.992/
          data  Sat(1, 351)/ 361.000/,Sat(2, 351)/ 137.072/
          data  Sat(1, 352)/ 362.000/,Sat(2, 352)/ 137.120/
          data  Sat(1, 353)/ 363.000/,Sat(2, 353)/ 137.147/
          data  Sat(1, 354)/ 364.000/,Sat(2, 354)/ 137.160/
          data  Sat(1, 355)/ 365.000/,Sat(2, 355)/ 137.162/
          data  Sat(1, 356)/ 366.000/,Sat(2, 356)/ 137.156/
          data  Sat(1, 357)/ 367.000/,Sat(2, 357)/ 137.144/
          data  Sat(1, 358)/ 368.000/,Sat(2, 358)/ 137.127/
          data  Sat(1, 359)/ 369.000/,Sat(2, 359)/ 137.107/
          data  Sat(1, 360)/ 370.000/,Sat(2, 360)/ 137.084/
          data  Sat(1, 361)/ 371.000/,Sat(2, 361)/ 137.059/
          data  Sat(1, 362)/ 372.000/,Sat(2, 362)/ 137.031/
          data  Sat(1, 363)/ 373.000/,Sat(2, 363)/ 137.002/
          data  Sat(1, 364)/ 374.000/,Sat(2, 364)/ 136.972/
          data  Sat(1, 365)/ 375.000/,Sat(2, 365)/ 136.940/
          data  Sat(1, 366)/ 376.000/,Sat(2, 366)/ 136.907/
          data  Sat(1, 367)/ 377.000/,Sat(2, 367)/ 136.873/
          data  Sat(1, 368)/ 378.000/,Sat(2, 368)/ 136.838/
          data  Sat(1, 369)/ 379.000/,Sat(2, 369)/ 136.802/
          data  Sat(1, 370)/ 380.000/,Sat(2, 370)/ 136.765/
          data  Sat(1, 371)/ 381.000/,Sat(2, 371)/ 136.727/
          data  Sat(1, 372)/ 382.000/,Sat(2, 372)/ 136.688/
          data  Sat(1, 373)/ 383.000/,Sat(2, 373)/ 136.649/
          data  Sat(1, 374)/ 384.000/,Sat(2, 374)/ 136.609/
          data  Sat(1, 375)/ 385.000/,Sat(2, 375)/ 136.569/
          data  Sat(1, 376)/ 386.000/,Sat(2, 376)/ 136.528/
          data  Sat(1, 377)/ 387.000/,Sat(2, 377)/ 136.486/
          data  Sat(1, 378)/ 388.000/,Sat(2, 378)/ 136.443/
          data  Sat(1, 379)/ 389.000/,Sat(2, 379)/ 136.401/
          data  Sat(1, 380)/ 390.000/,Sat(2, 380)/ 136.357/
          data  Sat(1, 381)/ 391.000/,Sat(2, 381)/ 136.312/
          data  Sat(1, 382)/ 392.000/,Sat(2, 382)/ 136.267/
          data  Sat(1, 383)/ 393.000/,Sat(2, 383)/ 136.221/
          data  Sat(1, 384)/ 394.000/,Sat(2, 384)/ 136.175/
          data  Sat(1, 385)/ 395.000/,Sat(2, 385)/ 136.128/
          data  Sat(1, 386)/ 396.000/,Sat(2, 386)/ 136.080/
          data  Sat(1, 387)/ 397.000/,Sat(2, 387)/ 136.032/
          data  Sat(1, 388)/ 398.000/,Sat(2, 388)/ 135.983/
          data  Sat(1, 389)/ 399.000/,Sat(2, 389)/ 135.933/
          data  Sat(1, 390)/ 400.000/,Sat(2, 390)/ 135.883/
          data  Sat(1, 391)/ 401.000/,Sat(2, 391)/ 135.832/
          data  Sat(1, 392)/ 402.000/,Sat(2, 392)/ 135.780/
          data  Sat(1, 393)/ 403.000/,Sat(2, 393)/ 135.727/
          data  Sat(1, 394)/ 404.000/,Sat(2, 394)/ 135.673/
          data  Sat(1, 395)/ 405.000/,Sat(2, 395)/ 135.619/
          data  Sat(1, 396)/ 406.000/,Sat(2, 396)/ 135.564/
          data  Sat(1, 397)/ 407.000/,Sat(2, 397)/ 135.508/
          data  Sat(1, 398)/ 408.000/,Sat(2, 398)/ 135.452/
          data  Sat(1, 399)/ 409.000/,Sat(2, 399)/ 135.394/
          data  Sat(1, 400)/ 410.000/,Sat(2, 400)/ 135.336/
          data  Sat(1, 401)/ 411.000/,Sat(2, 401)/ 135.276/
          data  Sat(1, 402)/ 412.000/,Sat(2, 402)/ 135.216/
          data  Sat(1, 403)/ 413.000/,Sat(2, 403)/ 135.155/
          data  Sat(1, 404)/ 414.000/,Sat(2, 404)/ 135.092/
          data  Sat(1, 405)/ 415.000/,Sat(2, 405)/ 135.029/
          data  Sat(1, 406)/ 416.000/,Sat(2, 406)/ 134.964/
          data  Sat(1, 407)/ 417.000/,Sat(2, 407)/ 134.898/
          data  Sat(1, 408)/ 418.000/,Sat(2, 408)/ 134.830/
          data  Sat(1, 409)/ 419.000/,Sat(2, 409)/ 134.762/
          data  Sat(1, 410)/ 420.000/,Sat(2, 410)/ 134.692/
          data  Sat(1, 411)/ 421.000/,Sat(2, 411)/ 134.620/
          data  Sat(1, 412)/ 422.000/,Sat(2, 412)/ 134.546/
          data  Sat(1, 413)/ 423.000/,Sat(2, 413)/ 134.471/
          data  Sat(1, 414)/ 424.000/,Sat(2, 414)/ 134.393/
          data  Sat(1, 415)/ 425.000/,Sat(2, 415)/ 134.313/
          data  Sat(1, 416)/ 426.000/,Sat(2, 416)/ 134.230/
          data  Sat(1, 417)/ 427.000/,Sat(2, 417)/ 134.145/
          data  Sat(1, 418)/ 428.000/,Sat(2, 418)/ 134.055/
          data  Sat(1, 419)/ 429.000/,Sat(2, 419)/ 133.962/
          data  Sat(1, 420)/ 430.000/,Sat(2, 420)/ 133.864/
          data  Sat(1, 421)/ 431.000/,Sat(2, 421)/ 133.759/
          data  Sat(1, 422)/ 432.000/,Sat(2, 422)/ 133.646/
          data  Sat(1, 423)/ 433.000/,Sat(2, 423)/ 133.524/
          data  Sat(1, 424)/ 434.000/,Sat(2, 424)/ 133.389/
          data  Sat(1, 425)/ 435.000/,Sat(2, 425)/ 133.236/
          data  Sat(1, 426)/ 436.000/,Sat(2, 426)/ 133.059/
          data  Sat(1, 427)/ 437.000/,Sat(2, 427)/ 132.847/
          data  Sat(1, 428)/ 438.000/,Sat(2, 428)/ 132.583/
          data  Sat(1, 429)/ 439.000/,Sat(2, 429)/ 132.236/
          data  Sat(1, 430)/ 440.000/,Sat(2, 430)/ 131.751/
          data  Sat(1, 431)/ 441.000/,Sat(2, 431)/ 131.004/
          data  Sat(1, 432)/ 442.000/,Sat(2, 432)/ 129.657/
          data  Sat(1, 433)/ 443.000/,Sat(2, 433)/ 125.834/
          data  Sat(1, 434)/ 444.000/,Sat(2, 434)/ 129.003/
          data  Sat(1, 435)/ 445.000/,Sat(2, 435)/ 130.427/
          data  Sat(1, 436)/ 446.000/,Sat(2, 436)/ 131.075/
          data  Sat(1, 437)/ 447.000/,Sat(2, 437)/ 131.411/
          data  Sat(1, 438)/ 448.000/,Sat(2, 438)/ 131.588/
          data  Sat(1, 439)/ 449.000/,Sat(2, 439)/ 131.671/
          data  Sat(1, 440)/ 450.000/,Sat(2, 440)/ 131.695/
          data  Sat(1, 441)/ 451.000/,Sat(2, 441)/ 131.679/
          data  Sat(1, 442)/ 452.000/,Sat(2, 442)/ 131.637/
          data  Sat(1, 443)/ 453.000/,Sat(2, 443)/ 131.574/
          data  Sat(1, 444)/ 454.000/,Sat(2, 444)/ 131.496/
          data  Sat(1, 445)/ 455.000/,Sat(2, 445)/ 131.406/
          data  Sat(1, 446)/ 456.000/,Sat(2, 446)/ 131.305/
          data  Sat(1, 447)/ 457.000/,Sat(2, 447)/ 131.195/
          data  Sat(1, 448)/ 458.000/,Sat(2, 448)/ 131.075/
          data  Sat(1, 449)/ 459.000/,Sat(2, 449)/ 130.940/
          data  Sat(1, 450)/ 460.000/,Sat(2, 450)/ 130.778/
          data  Sat(1, 451)/ 461.000/,Sat(2, 451)/ 130.530/
          data  Sat(1, 452)/ 462.000/,Sat(2, 452)/ 130.502/
          data  Sat(1, 453)/ 463.000/,Sat(2, 453)/ 130.394/
          data  Sat(1, 454)/ 464.000/,Sat(2, 454)/ 130.247/
          data  Sat(1, 455)/ 465.000/,Sat(2, 455)/ 130.028/
          data  Sat(1, 456)/ 466.000/,Sat(2, 456)/ 129.930/
          data  Sat(1, 457)/ 467.000/,Sat(2, 457)/ 129.800/
          data  Sat(1, 458)/ 468.000/,Sat(2, 458)/ 129.643/
          data  Sat(1, 459)/ 469.000/,Sat(2, 459)/ 129.476/
          data  Sat(1, 460)/ 470.000/,Sat(2, 460)/ 129.301/
          data  Sat(1, 461)/ 471.000/,Sat(2, 461)/ 129.119/
          data  Sat(1, 462)/ 472.000/,Sat(2, 462)/ 128.930/
          data  Sat(1, 463)/ 473.000/,Sat(2, 463)/ 128.735/
          data  Sat(1, 464)/ 474.000/,Sat(2, 464)/ 128.534/
          data  Sat(1, 465)/ 475.000/,Sat(2, 465)/ 128.325/
          data  Sat(1, 466)/ 476.000/,Sat(2, 466)/ 128.109/
          data  Sat(1, 467)/ 477.000/,Sat(2, 467)/ 127.886/
          data  Sat(1, 468)/ 478.000/,Sat(2, 468)/ 127.655/
          data  Sat(1, 469)/ 479.000/,Sat(2, 469)/ 127.416/
          data  Sat(1, 470)/ 480.000/,Sat(2, 470)/ 127.168/
          data  Sat(1, 471)/ 481.000/,Sat(2, 471)/ 126.911/
          data  Sat(1, 472)/ 482.000/,Sat(2, 472)/ 126.644/
          data  Sat(1, 473)/ 483.000/,Sat(2, 473)/ 126.368/
          data  Sat(1, 474)/ 484.000/,Sat(2, 474)/ 126.080/
          data  Sat(1, 475)/ 485.000/,Sat(2, 475)/ 125.782/
          data  Sat(1, 476)/ 486.000/,Sat(2, 476)/ 125.471/
          data  Sat(1, 477)/ 487.000/,Sat(2, 477)/ 125.147/
          data  Sat(1, 478)/ 488.000/,Sat(2, 478)/ 124.810/
          data  Sat(1, 479)/ 489.000/,Sat(2, 479)/ 124.459/
          data  Sat(1, 480)/ 490.000/,Sat(2, 480)/ 124.093/
          data  Sat(1, 481)/ 491.000/,Sat(2, 481)/ 123.711/
          data  Sat(1, 482)/ 492.000/,Sat(2, 482)/ 123.311/
          data  Sat(1, 483)/ 493.000/,Sat(2, 483)/ 122.893/
          data  Sat(1, 484)/ 494.000/,Sat(2, 484)/ 122.455/
          data  Sat(1, 485)/ 495.000/,Sat(2, 485)/ 121.997/
          data  Sat(1, 486)/ 496.000/,Sat(2, 486)/ 121.517/
          data  Sat(1, 487)/ 497.000/,Sat(2, 487)/ 121.012/
          data  Sat(1, 488)/ 498.000/,Sat(2, 488)/ 120.482/
          data  Sat(1, 489)/ 499.000/,Sat(2, 489)/ 119.926/
          data  Sat(1, 490)/ 500.000/,Sat(2, 490)/ 119.340/
          data  Sat(1, 491)/ 501.000/,Sat(2, 491)/ 118.723/
          data  Sat(1, 492)/ 502.000/,Sat(2, 492)/ 118.073/
          data  Sat(1, 493)/ 503.000/,Sat(2, 493)/ 117.388/
          data  Sat(1, 494)/ 504.000/,Sat(2, 494)/ 116.664/
          data  Sat(1, 495)/ 505.000/,Sat(2, 495)/ 115.901/
          data  Sat(1, 496)/ 506.000/,Sat(2, 496)/ 115.094/
          data  Sat(1, 497)/ 507.000/,Sat(2, 497)/ 114.241/
          data  Sat(1, 498)/ 508.000/,Sat(2, 498)/ 113.340/
          data  Sat(1, 499)/ 509.000/,Sat(2, 499)/ 112.387/
          data  Sat(1, 500)/ 510.000/,Sat(2, 500)/ 111.380/
          data  Sat(1, 501)/ 511.000/,Sat(2, 501)/ 110.317/
          data  Sat(1, 502)/ 512.000/,Sat(2, 502)/ 109.194/
          data  Sat(1, 503)/ 513.000/,Sat(2, 503)/ 108.010/
          data  Sat(1, 504)/ 514.000/,Sat(2, 504)/ 106.764/
          data  Sat(1, 505)/ 515.000/,Sat(2, 505)/ 105.456/
          data  Sat(1, 506)/ 516.000/,Sat(2, 506)/ 104.087/
          data  Sat(1, 507)/ 517.000/,Sat(2, 507)/ 102.661/
          data  Sat(1, 508)/ 518.000/,Sat(2, 508)/ 101.181/
          data  Sat(1, 509)/ 519.000/,Sat(2, 509)/  99.657/
          data  Sat(1, 510)/ 520.000/,Sat(2, 510)/  98.099/
          data  Sat(1, 511)/ 521.000/,Sat(2, 511)/  96.523/
          data  Sat(1, 512)/ 522.000/,Sat(2, 512)/  94.945/
          data  Sat(1, 513)/ 523.000/,Sat(2, 513)/  93.388/
          data  Sat(1, 514)/ 524.000/,Sat(2, 514)/  91.873/
          data  Sat(1, 515)/ 525.000/,Sat(2, 515)/  90.422/
          data  Sat(1, 516)/ 526.000/,Sat(2, 516)/  89.053/
          data  Sat(1, 517)/ 527.000/,Sat(2, 517)/  87.776/
          data  Sat(1, 518)/ 528.000/,Sat(2, 518)/  86.595/
          data  Sat(1, 519)/ 529.000/,Sat(2, 519)/  85.509/
          data  Sat(1, 520)/ 530.000/,Sat(2, 520)/  84.527/
          data  Sat(1, 521)/ 531.000/,Sat(2, 521)/  83.701/
          data  Sat(1, 522)/ 532.000/,Sat(2, 522)/  83.264/
          data  Sat(1, 523)/ 533.000/,Sat(2, 523)/  82.766/
          data  Sat(1, 524)/ 534.000/,Sat(2, 524)/  82.704/
          data  Sat(1, 525)/ 535.000/,Sat(2, 525)/  82.868/
          data  Sat(1, 526)/ 536.000/,Sat(2, 526)/  83.326/
          data  Sat(1, 527)/ 537.000/,Sat(2, 527)/  84.031/
          data  Sat(1, 528)/ 538.000/,Sat(2, 528)/  84.925/
          data  Sat(1, 529)/ 539.000/,Sat(2, 529)/  85.945/
          data  Sat(1, 530)/ 540.000/,Sat(2, 530)/  87.065/
          data  Sat(1, 531)/ 541.000/,Sat(2, 531)/  88.281/
          data  Sat(1, 532)/ 542.000/,Sat(2, 532)/  89.589/
          data  Sat(1, 533)/ 543.000/,Sat(2, 533)/  90.980/
          data  Sat(1, 534)/ 544.000/,Sat(2, 534)/  92.435/
          data  Sat(1, 535)/ 545.000/,Sat(2, 535)/  93.928/
          data  Sat(1, 536)/ 546.000/,Sat(2, 536)/  95.432/
          data  Sat(1, 537)/ 547.000/,Sat(2, 537)/  96.917/
          data  Sat(1, 538)/ 548.000/,Sat(2, 538)/  98.363/
          data  Sat(1, 539)/ 549.000/,Sat(2, 539)/  99.747/
          data  Sat(1, 540)/ 550.000/,Sat(2, 540)/ 101.056/
          data  Sat(1, 541)/ 551.000/,Sat(2, 541)/ 102.280/
          data  Sat(1, 542)/ 552.000/,Sat(2, 542)/ 103.413/
          data  Sat(1, 543)/ 553.000/,Sat(2, 543)/ 104.451/
          data  Sat(1, 544)/ 554.000/,Sat(2, 544)/ 105.392/
          data  Sat(1, 545)/ 555.000/,Sat(2, 545)/ 106.239/
          data  Sat(1, 546)/ 556.000/,Sat(2, 546)/ 106.991/
          data  Sat(1, 547)/ 557.000/,Sat(2, 547)/ 107.649/
          data  Sat(1, 548)/ 558.000/,Sat(2, 548)/ 108.218/
          data  Sat(1, 549)/ 559.000/,Sat(2, 549)/ 108.698/
          data  Sat(1, 550)/ 560.000/,Sat(2, 550)/ 109.091/
          data  Sat(1, 551)/ 561.000/,Sat(2, 551)/ 109.398/
          data  Sat(1, 552)/ 562.000/,Sat(2, 552)/ 109.619/
          data  Sat(1, 553)/ 563.000/,Sat(2, 553)/ 109.752/
          data  Sat(1, 554)/ 564.000/,Sat(2, 554)/ 109.796/
          data  Sat(1, 555)/ 565.000/,Sat(2, 555)/ 109.746/
          data  Sat(1, 556)/ 566.000/,Sat(2, 556)/ 109.594/
          data  Sat(1, 557)/ 567.000/,Sat(2, 557)/ 109.330/
          data  Sat(1, 558)/ 568.000/,Sat(2, 558)/ 108.940/
          data  Sat(1, 559)/ 569.000/,Sat(2, 559)/ 108.406/
          data  Sat(1, 560)/ 570.000/,Sat(2, 560)/ 107.720/
          data  Sat(1, 561)/ 571.000/,Sat(2, 561)/ 106.924/
          data  Sat(1, 562)/ 572.000/,Sat(2, 562)/ 106.268/
          data  Sat(1, 563)/ 573.000/,Sat(2, 563)/ 106.382/
          data  Sat(1, 564)/ 574.000/,Sat(2, 564)/ 107.293/
          data  Sat(1, 565)/ 575.000/,Sat(2, 565)/ 108.387/
          data  Sat(1, 566)/ 576.000/,Sat(2, 566)/ 109.365/
          data  Sat(1, 567)/ 577.000/,Sat(2, 567)/ 110.357/
          data  Sat(1, 568)/ 578.000/,Sat(2, 568)/ 111.240/
          data  Sat(1, 569)/ 579.000/,Sat(2, 569)/ 112.013/
          data  Sat(1, 570)/ 580.000/,Sat(2, 570)/ 112.711/
          data  Sat(1, 571)/ 581.000/,Sat(2, 571)/ 113.347/
          data  Sat(1, 572)/ 582.000/,Sat(2, 572)/ 113.933/
          data  Sat(1, 573)/ 583.000/,Sat(2, 573)/ 114.475/
          data  Sat(1, 574)/ 584.000/,Sat(2, 574)/ 114.980/
          data  Sat(1, 575)/ 585.000/,Sat(2, 575)/ 115.453/
          data  Sat(1, 576)/ 586.000/,Sat(2, 576)/ 115.897/
          data  Sat(1, 577)/ 587.000/,Sat(2, 577)/ 116.315/
          data  Sat(1, 578)/ 588.000/,Sat(2, 578)/ 116.709/
          data  Sat(1, 579)/ 589.000/,Sat(2, 579)/ 117.082/
          data  Sat(1, 580)/ 590.000/,Sat(2, 580)/ 117.435/
          data  Sat(1, 581)/ 591.000/,Sat(2, 581)/ 117.770/
          data  Sat(1, 582)/ 592.000/,Sat(2, 582)/ 118.089/
          data  Sat(1, 583)/ 593.000/,Sat(2, 583)/ 118.392/
          data  Sat(1, 584)/ 594.000/,Sat(2, 584)/ 118.681/
          data  Sat(1, 585)/ 595.000/,Sat(2, 585)/ 118.957/
          data  Sat(1, 586)/ 596.000/,Sat(2, 586)/ 119.219/
          data  Sat(1, 587)/ 597.000/,Sat(2, 587)/ 119.469/
          data  Sat(1, 588)/ 598.000/,Sat(2, 588)/ 119.708/
          data  Sat(1, 589)/ 599.000/,Sat(2, 589)/ 119.936/
          data  Sat(1, 590)/ 600.000/,Sat(2, 590)/ 120.154/
          data  Sat(1, 591)/ 601.000/,Sat(2, 591)/ 120.362/
          data  Sat(1, 592)/ 602.000/,Sat(2, 592)/ 120.559/
          data  Sat(1, 593)/ 603.000/,Sat(2, 593)/ 120.747/
          data  Sat(1, 594)/ 604.000/,Sat(2, 594)/ 120.926/
          data  Sat(1, 595)/ 605.000/,Sat(2, 595)/ 121.094/
          data  Sat(1, 596)/ 606.000/,Sat(2, 596)/ 121.252/
          data  Sat(1, 597)/ 607.000/,Sat(2, 597)/ 121.400/
          data  Sat(1, 598)/ 608.000/,Sat(2, 598)/ 121.536/
          data  Sat(1, 599)/ 609.000/,Sat(2, 599)/ 121.659/
          data  Sat(1, 600)/ 610.000/,Sat(2, 600)/ 121.768/
          data  Sat(1, 601)/ 611.000/,Sat(2, 601)/ 121.858/
          data  Sat(1, 602)/ 612.000/,Sat(2, 602)/ 121.926/
          data  Sat(1, 603)/ 613.000/,Sat(2, 603)/ 121.964/
          data  Sat(1, 604)/ 614.000/,Sat(2, 604)/ 121.960/
          data  Sat(1, 605)/ 615.000/,Sat(2, 605)/ 121.896/
          data  Sat(1, 606)/ 616.000/,Sat(2, 606)/ 121.739/
          data  Sat(1, 607)/ 617.000/,Sat(2, 607)/ 121.428/
          data  Sat(1, 608)/ 618.000/,Sat(2, 608)/ 120.838/
          data  Sat(1, 609)/ 619.000/,Sat(2, 609)/ 119.648/
          data  Sat(1, 610)/ 620.000/,Sat(2, 610)/ 116.481/
          data  Sat(1, 611)/ 621.000/,Sat(2, 611)/ 118.314/
          data  Sat(1, 612)/ 622.000/,Sat(2, 612)/ 120.529/
          data  Sat(1, 613)/ 623.000/,Sat(2, 613)/ 121.615/
          data  Sat(1, 614)/ 624.000/,Sat(2, 614)/ 122.274/
          data  Sat(1, 615)/ 625.000/,Sat(2, 615)/ 122.717/
          data  Sat(1, 616)/ 626.000/,Sat(2, 616)/ 123.038/
          data  Sat(1, 617)/ 627.000/,Sat(2, 617)/ 123.283/
          data  Sat(1, 618)/ 628.000/,Sat(2, 618)/ 123.479/
          data  Sat(1, 619)/ 629.000/,Sat(2, 619)/ 123.640/
          data  Sat(1, 620)/ 630.000/,Sat(2, 620)/ 123.776/
          data  Sat(1, 621)/ 631.000/,Sat(2, 621)/ 123.894/
          data  Sat(1, 622)/ 632.000/,Sat(2, 622)/ 123.998/
          data  Sat(1, 623)/ 633.000/,Sat(2, 623)/ 124.091/
          data  Sat(1, 624)/ 634.000/,Sat(2, 624)/ 124.175/
          data  Sat(1, 625)/ 635.000/,Sat(2, 625)/ 124.252/
          data  Sat(1, 626)/ 636.000/,Sat(2, 626)/ 124.322/
          data  Sat(1, 627)/ 637.000/,Sat(2, 627)/ 124.387/
          data  Sat(1, 628)/ 638.000/,Sat(2, 628)/ 124.446/
          data  Sat(1, 629)/ 639.000/,Sat(2, 629)/ 124.501/
          data  Sat(1, 630)/ 640.000/,Sat(2, 630)/ 124.552/
          data  Sat(1, 631)/ 641.000/,Sat(2, 631)/ 124.600/
          data  Sat(1, 632)/ 642.000/,Sat(2, 632)/ 124.644/
          data  Sat(1, 633)/ 643.000/,Sat(2, 633)/ 124.684/
          data  Sat(1, 634)/ 644.000/,Sat(2, 634)/ 124.722/
          data  Sat(1, 635)/ 645.000/,Sat(2, 635)/ 124.757/
          data  Sat(1, 636)/ 646.000/,Sat(2, 636)/ 124.788/
          data  Sat(1, 637)/ 647.000/,Sat(2, 637)/ 124.817/
          data  Sat(1, 638)/ 648.000/,Sat(2, 638)/ 124.844/
          data  Sat(1, 639)/ 649.000/,Sat(2, 639)/ 124.868/
          data  Sat(1, 640)/ 650.000/,Sat(2, 640)/ 124.890/
          data  Sat(1, 641)/ 651.000/,Sat(2, 641)/ 124.909/
          data  Sat(1, 642)/ 652.000/,Sat(2, 642)/ 124.926/
          data  Sat(1, 643)/ 653.000/,Sat(2, 643)/ 124.941/
          data  Sat(1, 644)/ 654.000/,Sat(2, 644)/ 124.953/
          data  Sat(1, 645)/ 655.000/,Sat(2, 645)/ 124.963/
          data  Sat(1, 646)/ 656.000/,Sat(2, 646)/ 124.971/
          data  Sat(1, 647)/ 657.000/,Sat(2, 647)/ 124.977/
          data  Sat(1, 648)/ 658.000/,Sat(2, 648)/ 124.980/
          data  Sat(1, 649)/ 659.000/,Sat(2, 649)/ 124.982/
          data  Sat(1, 650)/ 660.000/,Sat(2, 650)/ 124.982/
          data  Sat(1, 651)/ 661.000/,Sat(2, 651)/ 124.980/
          data  Sat(1, 652)/ 662.000/,Sat(2, 652)/ 124.975/
          data  Sat(1, 653)/ 663.000/,Sat(2, 653)/ 124.969/
          data  Sat(1, 654)/ 664.000/,Sat(2, 654)/ 124.959/
          data  Sat(1, 655)/ 665.000/,Sat(2, 655)/ 124.949/
          data  Sat(1, 656)/ 666.000/,Sat(2, 656)/ 124.937/
          data  Sat(1, 657)/ 667.000/,Sat(2, 657)/ 124.922/
          data  Sat(1, 658)/ 668.000/,Sat(2, 658)/ 124.906/
          data  Sat(1, 659)/ 669.000/,Sat(2, 659)/ 124.887/
          data  Sat(1, 660)/ 670.000/,Sat(2, 660)/ 124.867/
          data  Sat(1, 661)/ 671.000/,Sat(2, 661)/ 124.844/
          data  Sat(1, 662)/ 672.000/,Sat(2, 662)/ 124.819/
          data  Sat(1, 663)/ 673.000/,Sat(2, 663)/ 124.793/
          data  Sat(1, 664)/ 674.000/,Sat(2, 664)/ 124.764/
          data  Sat(1, 665)/ 675.000/,Sat(2, 665)/ 124.733/
          data  Sat(1, 666)/ 676.000/,Sat(2, 666)/ 124.700/
          data  Sat(1, 667)/ 677.000/,Sat(2, 667)/ 124.665/
          data  Sat(1, 668)/ 678.000/,Sat(2, 668)/ 124.627/
          data  Sat(1, 669)/ 679.000/,Sat(2, 669)/ 124.587/
          data  Sat(1, 670)/ 680.000/,Sat(2, 670)/ 124.545/
          data  Sat(1, 671)/ 681.000/,Sat(2, 671)/ 124.501/
          data  Sat(1, 672)/ 682.000/,Sat(2, 672)/ 124.454/
          data  Sat(1, 673)/ 683.000/,Sat(2, 673)/ 124.404/
          data  Sat(1, 674)/ 684.000/,Sat(2, 674)/ 124.351/
          data  Sat(1, 675)/ 685.000/,Sat(2, 675)/ 124.295/
          data  Sat(1, 676)/ 686.000/,Sat(2, 676)/ 124.236/
          data  Sat(1, 677)/ 687.000/,Sat(2, 677)/ 124.171/
          data  Sat(1, 678)/ 688.000/,Sat(2, 678)/ 124.101/
          data  Sat(1, 679)/ 689.000/,Sat(2, 679)/ 124.020/
          data  Sat(1, 680)/ 690.000/,Sat(2, 680)/ 123.914/
          data  Sat(1, 681)/ 691.000/,Sat(2, 681)/ 123.728/
          data  Sat(1, 682)/ 692.000/,Sat(2, 682)/ 123.661/
          data  Sat(1, 683)/ 693.000/,Sat(2, 683)/ 123.680/
          data  Sat(1, 684)/ 694.000/,Sat(2, 684)/ 123.621/
          data  Sat(1, 685)/ 695.000/,Sat(2, 685)/ 123.532/
          data  Sat(1, 686)/ 696.000/,Sat(2, 686)/ 123.414/
          data  Sat(1, 687)/ 697.000/,Sat(2, 687)/ 123.228/
          data  Sat(1, 688)/ 698.000/,Sat(2, 688)/ 122.956/
          data  Sat(1, 689)/ 699.000/,Sat(2, 689)/ 123.041/
          data  Sat(1, 690)/ 700.000/,Sat(2, 690)/ 122.940/
          data  Sat(1, 691)/ 701.000/,Sat(2, 691)/ 122.790/
          data  Sat(1, 692)/ 702.000/,Sat(2, 692)/ 122.602/
          data  Sat(1, 693)/ 703.000/,Sat(2, 693)/ 122.368/
          data  Sat(1, 694)/ 704.000/,Sat(2, 694)/ 122.070/
          data  Sat(1, 695)/ 705.000/,Sat(2, 695)/ 121.671/
          data  Sat(1, 696)/ 706.000/,Sat(2, 696)/ 121.104/
          data  Sat(1, 697)/ 707.000/,Sat(2, 697)/ 120.212/
          data  Sat(1, 698)/ 708.000/,Sat(2, 698)/ 118.530/
          data  Sat(1, 699)/ 709.000/,Sat(2, 699)/ 115.361/
          data  Sat(1, 700)/ 710.000/,Sat(2, 700)/ 118.853/
          data  Sat(1, 701)/ 711.000/,Sat(2, 701)/ 120.035/
          data  Sat(1, 702)/ 712.000/,Sat(2, 702)/ 120.598/
          data  Sat(1, 703)/ 713.000/,Sat(2, 703)/ 120.886/
          data  Sat(1, 704)/ 714.000/,Sat(2, 704)/ 121.025/
          data  Sat(1, 705)/ 715.000/,Sat(2, 705)/ 121.075/
          data  Sat(1, 706)/ 716.000/,Sat(2, 706)/ 121.066/
          data  Sat(1, 707)/ 717.000/,Sat(2, 707)/ 121.018/
          data  Sat(1, 708)/ 718.000/,Sat(2, 708)/ 120.942/
          data  Sat(1, 709)/ 719.000/,Sat(2, 709)/ 120.844/
          data  Sat(1, 710)/ 720.000/,Sat(2, 710)/ 120.729/
          data  Sat(1, 711)/ 721.000/,Sat(2, 711)/ 120.601/
          data  Sat(1, 712)/ 722.000/,Sat(2, 712)/ 120.461/
          data  Sat(1, 713)/ 723.000/,Sat(2, 713)/ 120.311/
          data  Sat(1, 714)/ 724.000/,Sat(2, 714)/ 120.151/
          data  Sat(1, 715)/ 725.000/,Sat(2, 715)/ 119.982/
          data  Sat(1, 716)/ 726.000/,Sat(2, 716)/ 119.805/
          data  Sat(1, 717)/ 727.000/,Sat(2, 717)/ 119.621/
          data  Sat(1, 718)/ 728.000/,Sat(2, 718)/ 119.428/
          data  Sat(1, 719)/ 729.000/,Sat(2, 719)/ 119.228/
          data  Sat(1, 720)/ 730.000/,Sat(2, 720)/ 119.021/
          data  Sat(1, 721)/ 731.000/,Sat(2, 721)/ 118.805/
          data  Sat(1, 722)/ 732.000/,Sat(2, 722)/ 118.581/
          data  Sat(1, 723)/ 733.000/,Sat(2, 723)/ 118.350/
          data  Sat(1, 724)/ 734.000/,Sat(2, 724)/ 118.110/
          data  Sat(1, 725)/ 735.000/,Sat(2, 725)/ 117.862/
          data  Sat(1, 726)/ 736.000/,Sat(2, 726)/ 117.605/
          data  Sat(1, 727)/ 737.000/,Sat(2, 727)/ 117.339/
          data  Sat(1, 728)/ 738.000/,Sat(2, 728)/ 117.064/
          data  Sat(1, 729)/ 739.000/,Sat(2, 729)/ 116.780/
          data  Sat(1, 730)/ 740.000/,Sat(2, 730)/ 116.486/
          data  Sat(1, 731)/ 741.000/,Sat(2, 731)/ 116.182/
          data  Sat(1, 732)/ 742.000/,Sat(2, 732)/ 115.867/
          data  Sat(1, 733)/ 743.000/,Sat(2, 733)/ 115.542/
          data  Sat(1, 734)/ 744.000/,Sat(2, 734)/ 115.205/
          data  Sat(1, 735)/ 745.000/,Sat(2, 735)/ 114.857/
          data  Sat(1, 736)/ 746.000/,Sat(2, 736)/ 114.497/
          data  Sat(1, 737)/ 747.000/,Sat(2, 737)/ 114.125/
          data  Sat(1, 738)/ 748.000/,Sat(2, 738)/ 113.740/
          data  Sat(1, 739)/ 749.000/,Sat(2, 739)/ 113.342/
          data  Sat(1, 740)/ 750.000/,Sat(2, 740)/ 112.930/
          data  Sat(1, 741)/ 751.000/,Sat(2, 741)/ 112.504/
          data  Sat(1, 742)/ 752.000/,Sat(2, 742)/ 112.064/
          data  Sat(1, 743)/ 753.000/,Sat(2, 743)/ 111.609/
          data  Sat(1, 744)/ 754.000/,Sat(2, 744)/ 111.138/
          data  Sat(1, 745)/ 755.000/,Sat(2, 745)/ 110.652/
          data  Sat(1, 746)/ 756.000/,Sat(2, 746)/ 110.150/
          data  Sat(1, 747)/ 757.000/,Sat(2, 747)/ 109.631/
          data  Sat(1, 748)/ 758.000/,Sat(2, 748)/ 109.095/
          data  Sat(1, 749)/ 759.000/,Sat(2, 749)/ 108.543/
          data  Sat(1, 750)/ 760.000/,Sat(2, 750)/ 107.973/
          data  Sat(1, 751)/ 761.000/,Sat(2, 751)/ 107.385/
          data  Sat(1, 752)/ 762.000/,Sat(2, 752)/ 106.779/
          data  Sat(1, 753)/ 763.000/,Sat(2, 753)/ 106.155/
          data  Sat(1, 754)/ 764.000/,Sat(2, 754)/ 105.514/
          data  Sat(1, 755)/ 765.000/,Sat(2, 755)/ 104.855/
          data  Sat(1, 756)/ 766.000/,Sat(2, 756)/ 104.178/
          data  Sat(1, 757)/ 767.000/,Sat(2, 757)/ 103.484/
          data  Sat(1, 758)/ 768.000/,Sat(2, 758)/ 102.774/
          data  Sat(1, 759)/ 769.000/,Sat(2, 759)/ 102.048/
          data  Sat(1, 760)/ 770.000/,Sat(2, 760)/ 101.307/
          data  Sat(1, 761)/ 771.000/,Sat(2, 761)/ 100.553/
          data  Sat(1, 762)/ 772.000/,Sat(2, 762)/  99.785/
          data  Sat(1, 763)/ 773.000/,Sat(2, 763)/  99.008/
          data  Sat(1, 764)/ 774.000/,Sat(2, 764)/  98.220/
          data  Sat(1, 765)/ 775.000/,Sat(2, 765)/  97.427/
          data  Sat(1, 766)/ 776.000/,Sat(2, 766)/  96.628/
          data  Sat(1, 767)/ 777.000/,Sat(2, 767)/  95.828/
          data  Sat(1, 768)/ 778.000/,Sat(2, 768)/  95.029/
          data  Sat(1, 769)/ 779.000/,Sat(2, 769)/  94.233/
          data  Sat(1, 770)/ 780.000/,Sat(2, 770)/  93.444/
          data  Sat(1, 771)/ 781.000/,Sat(2, 771)/  92.664/
          data  Sat(1, 772)/ 782.000/,Sat(2, 772)/  91.898/
          data  Sat(1, 773)/ 783.000/,Sat(2, 773)/  91.145/
          data  Sat(1, 774)/ 784.000/,Sat(2, 774)/  90.411/
          data  Sat(1, 775)/ 785.000/,Sat(2, 775)/  89.697/
          data  Sat(1, 776)/ 786.000/,Sat(2, 776)/  89.004/
          data  Sat(1, 777)/ 787.000/,Sat(2, 777)/  88.333/
          data  Sat(1, 778)/ 788.000/,Sat(2, 778)/  87.685/
          data  Sat(1, 779)/ 789.000/,Sat(2, 779)/  87.061/
          data  Sat(1, 780)/ 790.000/,Sat(2, 780)/  86.458/
          data  Sat(1, 781)/ 791.000/,Sat(2, 781)/  85.879/
          data  Sat(1, 782)/ 792.000/,Sat(2, 782)/  85.325/
          data  Sat(1, 783)/ 793.000/,Sat(2, 783)/  84.797/
          data  Sat(1, 784)/ 794.000/,Sat(2, 784)/  84.306/
          data  Sat(1, 785)/ 795.000/,Sat(2, 785)/  83.860/
          data  Sat(1, 786)/ 796.000/,Sat(2, 786)/  83.474/
          data  Sat(1, 787)/ 797.000/,Sat(2, 787)/  83.250/
          data  Sat(1, 788)/ 798.000/,Sat(2, 788)/  82.978/
          data  Sat(1, 789)/ 799.000/,Sat(2, 789)/  82.789/
          data  Sat(1, 790)/ 800.000/,Sat(2, 790)/  82.753/
          data  Sat(1, 791)/ 801.000/,Sat(2, 791)/  82.753/
          data  Sat(1, 792)/ 802.000/,Sat(2, 792)/  82.790/
          data  Sat(1, 793)/ 803.000/,Sat(2, 793)/  82.936/
          data  Sat(1, 794)/ 804.000/,Sat(2, 794)/  83.175/
          data  Sat(1, 795)/ 805.000/,Sat(2, 795)/  83.490/
          data  Sat(1, 796)/ 806.000/,Sat(2, 796)/  83.873/
          data  Sat(1, 797)/ 807.000/,Sat(2, 797)/  84.315/
          data  Sat(1, 798)/ 808.000/,Sat(2, 798)/  84.809/
          data  Sat(1, 799)/ 809.000/,Sat(2, 799)/  85.336/
          data  Sat(1, 800)/ 810.000/,Sat(2, 800)/  85.890/
          data  Sat(1, 801)/ 811.000/,Sat(2, 801)/  86.468/
          data  Sat(1, 802)/ 812.000/,Sat(2, 802)/  87.069/
          data  Sat(1, 803)/ 813.000/,Sat(2, 803)/  87.691/
          data  Sat(1, 804)/ 814.000/,Sat(2, 804)/  88.337/
          data  Sat(1, 805)/ 815.000/,Sat(2, 805)/  89.004/
          data  Sat(1, 806)/ 816.000/,Sat(2, 806)/  89.693/
          data  Sat(1, 807)/ 817.000/,Sat(2, 807)/  90.401/
          data  Sat(1, 808)/ 818.000/,Sat(2, 808)/  91.128/
          data  Sat(1, 809)/ 819.000/,Sat(2, 809)/  91.870/
          data  Sat(1, 810)/ 820.000/,Sat(2, 810)/  92.626/
          data  Sat(1, 811)/ 821.000/,Sat(2, 811)/  93.393/
          data  Sat(1, 812)/ 822.000/,Sat(2, 812)/  94.166/
          data  Sat(1, 813)/ 823.000/,Sat(2, 813)/  94.944/
          data  Sat(1, 814)/ 824.000/,Sat(2, 814)/  95.724/
          data  Sat(1, 815)/ 825.000/,Sat(2, 815)/  96.502/
          data  Sat(1, 816)/ 826.000/,Sat(2, 816)/  97.275/
          data  Sat(1, 817)/ 827.000/,Sat(2, 817)/  98.041/
          data  Sat(1, 818)/ 828.000/,Sat(2, 818)/  98.798/
          data  Sat(1, 819)/ 829.000/,Sat(2, 819)/  99.544/
          data  Sat(1, 820)/ 830.000/,Sat(2, 820)/ 100.276/
          data  Sat(1, 821)/ 831.000/,Sat(2, 821)/ 100.994/
          data  Sat(1, 822)/ 832.000/,Sat(2, 822)/ 101.696/
          data  Sat(1, 823)/ 833.000/,Sat(2, 823)/ 102.381/
          data  Sat(1, 824)/ 834.000/,Sat(2, 824)/ 103.047/
          data  Sat(1, 825)/ 835.000/,Sat(2, 825)/ 103.696/
          data  Sat(1, 826)/ 836.000/,Sat(2, 826)/ 104.326/
          data  Sat(1, 827)/ 837.000/,Sat(2, 827)/ 104.936/
          data  Sat(1, 828)/ 838.000/,Sat(2, 828)/ 105.527/
          data  Sat(1, 829)/ 839.000/,Sat(2, 829)/ 106.098/
          data  Sat(1, 830)/ 840.000/,Sat(2, 830)/ 106.650/
          data  Sat(1, 831)/ 841.000/,Sat(2, 831)/ 107.183/
          data  Sat(1, 832)/ 842.000/,Sat(2, 832)/ 107.697/
          data  Sat(1, 833)/ 843.000/,Sat(2, 833)/ 108.192/
          data  Sat(1, 834)/ 844.000/,Sat(2, 834)/ 108.670/
          data  Sat(1, 835)/ 845.000/,Sat(2, 835)/ 109.129/
          data  Sat(1, 836)/ 846.000/,Sat(2, 836)/ 109.570/
          data  Sat(1, 837)/ 847.000/,Sat(2, 837)/ 109.995/
          data  Sat(1, 838)/ 848.000/,Sat(2, 838)/ 110.404/
          data  Sat(1, 839)/ 849.000/,Sat(2, 839)/ 110.796/
          data  Sat(1, 840)/ 850.000/,Sat(2, 840)/ 111.172/
          data  Sat(1, 841)/ 851.000/,Sat(2, 841)/ 111.534/
          data  Sat(1, 842)/ 852.000/,Sat(2, 842)/ 111.880/
          data  Sat(1, 843)/ 853.000/,Sat(2, 843)/ 112.213/
          data  Sat(1, 844)/ 854.000/,Sat(2, 844)/ 112.532/
          data  Sat(1, 845)/ 855.000/,Sat(2, 845)/ 112.837/
          data  Sat(1, 846)/ 856.000/,Sat(2, 846)/ 113.130/
          data  Sat(1, 847)/ 857.000/,Sat(2, 847)/ 113.411/
          data  Sat(1, 848)/ 858.000/,Sat(2, 848)/ 113.679/
          data  Sat(1, 849)/ 859.000/,Sat(2, 849)/ 113.936/
          data  Sat(1, 850)/ 860.000/,Sat(2, 850)/ 114.182/
          data  Sat(1, 851)/ 861.000/,Sat(2, 851)/ 114.417/
          data  Sat(1, 852)/ 862.000/,Sat(2, 852)/ 114.641/
          data  Sat(1, 853)/ 863.000/,Sat(2, 853)/ 114.855/
          data  Sat(1, 854)/ 864.000/,Sat(2, 854)/ 115.059/
          data  Sat(1, 855)/ 865.000/,Sat(2, 855)/ 115.254/
          data  Sat(1, 856)/ 866.000/,Sat(2, 856)/ 115.439/
          data  Sat(1, 857)/ 867.000/,Sat(2, 857)/ 115.614/
          data  Sat(1, 858)/ 868.000/,Sat(2, 858)/ 115.780/
          data  Sat(1, 859)/ 869.000/,Sat(2, 859)/ 115.937/
          data  Sat(1, 860)/ 870.000/,Sat(2, 860)/ 116.085/
          data  Sat(1, 861)/ 871.000/,Sat(2, 861)/ 116.224/
          data  Sat(1, 862)/ 872.000/,Sat(2, 862)/ 116.352/
          data  Sat(1, 863)/ 873.000/,Sat(2, 863)/ 116.471/
          data  Sat(1, 864)/ 874.000/,Sat(2, 864)/ 116.578/
          data  Sat(1, 865)/ 875.000/,Sat(2, 865)/ 116.673/
          data  Sat(1, 866)/ 876.000/,Sat(2, 866)/ 116.753/
          data  Sat(1, 867)/ 877.000/,Sat(2, 867)/ 116.817/
          data  Sat(1, 868)/ 878.000/,Sat(2, 868)/ 116.860/
          data  Sat(1, 869)/ 879.000/,Sat(2, 869)/ 116.876/
          data  Sat(1, 870)/ 880.000/,Sat(2, 870)/ 116.853/
          data  Sat(1, 871)/ 881.000/,Sat(2, 871)/ 116.777/
          data  Sat(1, 872)/ 882.000/,Sat(2, 872)/ 116.617/
          data  Sat(1, 873)/ 883.000/,Sat(2, 873)/ 116.319/
          data  Sat(1, 874)/ 884.000/,Sat(2, 874)/ 115.765/
          data  Sat(1, 875)/ 885.000/,Sat(2, 875)/ 114.615/
          data  Sat(1, 876)/ 886.000/,Sat(2, 876)/ 112.722/
          data  Sat(1, 877)/ 887.000/,Sat(2, 877)/ 114.834/
          data  Sat(1, 878)/ 888.000/,Sat(2, 878)/ 116.059/
          data  Sat(1, 879)/ 889.000/,Sat(2, 879)/ 116.728/
          data  Sat(1, 880)/ 890.000/,Sat(2, 880)/ 117.153/
          data  Sat(1, 881)/ 891.000/,Sat(2, 881)/ 117.445/
          data  Sat(1, 882)/ 892.000/,Sat(2, 882)/ 117.658/
          data  Sat(1, 883)/ 893.000/,Sat(2, 883)/ 117.820/
          data  Sat(1, 884)/ 894.000/,Sat(2, 884)/ 117.947/
          data  Sat(1, 885)/ 895.000/,Sat(2, 885)/ 118.049/
          data  Sat(1, 886)/ 896.000/,Sat(2, 886)/ 118.133/
          data  Sat(1, 887)/ 897.000/,Sat(2, 887)/ 118.202/
          data  Sat(1, 888)/ 898.000/,Sat(2, 888)/ 118.260/
          data  Sat(1, 889)/ 899.000/,Sat(2, 889)/ 118.309/
          data  Sat(1, 890)/ 900.000/,Sat(2, 890)/ 118.350/
          data  Sat(1, 891)/ 901.000/,Sat(2, 891)/ 118.385/
          data  Sat(1, 892)/ 902.000/,Sat(2, 892)/ 118.414/
          data  Sat(1, 893)/ 903.000/,Sat(2, 893)/ 118.439/
          data  Sat(1, 894)/ 904.000/,Sat(2, 894)/ 118.458/
          data  Sat(1, 895)/ 905.000/,Sat(2, 895)/ 118.474/
          data  Sat(1, 896)/ 906.000/,Sat(2, 896)/ 118.485/
          data  Sat(1, 897)/ 907.000/,Sat(2, 897)/ 118.493/
          data  Sat(1, 898)/ 908.000/,Sat(2, 898)/ 118.498/
          data  Sat(1, 899)/ 909.000/,Sat(2, 899)/ 118.500/
          data  Sat(1, 900)/ 910.000/,Sat(2, 900)/ 118.498/
          data  Sat(1, 901)/ 911.000/,Sat(2, 901)/ 118.493/
          data  Sat(1, 902)/ 912.000/,Sat(2, 902)/ 118.486/
          data  Sat(1, 903)/ 913.000/,Sat(2, 903)/ 118.475/
          data  Sat(1, 904)/ 914.000/,Sat(2, 904)/ 118.462/
          data  Sat(1, 905)/ 915.000/,Sat(2, 905)/ 118.445/
          data  Sat(1, 906)/ 916.000/,Sat(2, 906)/ 118.426/
          data  Sat(1, 907)/ 917.000/,Sat(2, 907)/ 118.402/
          data  Sat(1, 908)/ 918.000/,Sat(2, 908)/ 118.375/
          data  Sat(1, 909)/ 919.000/,Sat(2, 909)/ 118.339/
          data  Sat(1, 910)/ 920.000/,Sat(2, 910)/ 118.289/
          data  Sat(1, 911)/ 921.000/,Sat(2, 911)/ 118.196/
          data  Sat(1, 912)/ 922.000/,Sat(2, 912)/ 118.062/
          data  Sat(1, 913)/ 923.000/,Sat(2, 913)/ 118.162/
          data  Sat(1, 914)/ 924.000/,Sat(2, 914)/ 118.164/
          data  Sat(1, 915)/ 925.000/,Sat(2, 915)/ 118.137/
          data  Sat(1, 916)/ 926.000/,Sat(2, 916)/ 118.096/
          data  Sat(1, 917)/ 927.000/,Sat(2, 917)/ 118.043/
          data  Sat(1, 918)/ 928.000/,Sat(2, 918)/ 117.968/
          data  Sat(1, 919)/ 929.000/,Sat(2, 919)/ 117.827/
          data  Sat(1, 920)/ 930.000/,Sat(2, 920)/ 117.260/
          data  Sat(1, 921)/ 931.000/,Sat(2, 921)/ 117.688/
          data  Sat(1, 922)/ 932.000/,Sat(2, 922)/ 117.762/
          data  Sat(1, 923)/ 933.000/,Sat(2, 923)/ 117.749/
          data  Sat(1, 924)/ 934.000/,Sat(2, 924)/ 117.710/
          data  Sat(1, 925)/ 935.000/,Sat(2, 925)/ 117.660/
          data  Sat(1, 926)/ 936.000/,Sat(2, 926)/ 117.605/
          data  Sat(1, 927)/ 937.000/,Sat(2, 927)/ 117.545/
          data  Sat(1, 928)/ 938.000/,Sat(2, 928)/ 117.482/
          data  Sat(1, 929)/ 939.000/,Sat(2, 929)/ 117.416/
          data  Sat(1, 930)/ 940.000/,Sat(2, 930)/ 117.347/
          data  Sat(1, 931)/ 941.000/,Sat(2, 931)/ 117.275/
          data  Sat(1, 932)/ 942.000/,Sat(2, 932)/ 117.202/
          data  Sat(1, 933)/ 943.000/,Sat(2, 933)/ 117.126/
          data  Sat(1, 934)/ 944.000/,Sat(2, 934)/ 117.047/
          data  Sat(1, 935)/ 945.000/,Sat(2, 935)/ 116.966/
          data  Sat(1, 936)/ 946.000/,Sat(2, 936)/ 116.883/
          data  Sat(1, 937)/ 947.000/,Sat(2, 937)/ 116.797/
          data  Sat(1, 938)/ 948.000/,Sat(2, 938)/ 116.708/
          data  Sat(1, 939)/ 949.000/,Sat(2, 939)/ 116.617/
          data  Sat(1, 940)/ 950.000/,Sat(2, 940)/ 116.523/
          data  Sat(1, 941)/ 951.000/,Sat(2, 941)/ 116.427/
          data  Sat(1, 942)/ 952.000/,Sat(2, 942)/ 116.328/
          data  Sat(1, 943)/ 953.000/,Sat(2, 943)/ 116.226/
          data  Sat(1, 944)/ 954.000/,Sat(2, 944)/ 116.121/
          data  Sat(1, 945)/ 955.000/,Sat(2, 945)/ 116.013/
          data  Sat(1, 946)/ 956.000/,Sat(2, 946)/ 115.901/
          data  Sat(1, 947)/ 957.000/,Sat(2, 947)/ 115.786/
          data  Sat(1, 948)/ 958.000/,Sat(2, 948)/ 115.668/
          data  Sat(1, 949)/ 959.000/,Sat(2, 949)/ 115.546/
          data  Sat(1, 950)/ 960.000/,Sat(2, 950)/ 115.418/
          data  Sat(1, 951)/ 961.000/,Sat(2, 951)/ 115.286/
          data  Sat(1, 952)/ 962.000/,Sat(2, 952)/ 115.149/
          data  Sat(1, 953)/ 963.000/,Sat(2, 953)/ 115.004/
          data  Sat(1, 954)/ 964.000/,Sat(2, 954)/ 114.852/
          data  Sat(1, 955)/ 965.000/,Sat(2, 955)/ 114.691/
          data  Sat(1, 956)/ 966.000/,Sat(2, 956)/ 114.518/
          data  Sat(1, 957)/ 967.000/,Sat(2, 957)/ 114.329/
          data  Sat(1, 958)/ 968.000/,Sat(2, 958)/ 114.120/
          data  Sat(1, 959)/ 969.000/,Sat(2, 959)/ 113.880/
          data  Sat(1, 960)/ 970.000/,Sat(2, 960)/ 113.595/
          data  Sat(1, 961)/ 971.000/,Sat(2, 961)/ 113.237/
          data  Sat(1, 962)/ 972.000/,Sat(2, 962)/ 112.754/
          data  Sat(1, 963)/ 973.000/,Sat(2, 963)/ 112.014/
          data  Sat(1, 964)/ 974.000/,Sat(2, 964)/ 110.524/
          data  Sat(1, 965)/ 975.000/,Sat(2, 965)/ 110.434/
          data  Sat(1, 966)/ 976.000/,Sat(2, 966)/ 111.583/
          data  Sat(1, 967)/ 977.000/,Sat(2, 967)/ 111.995/
          data  Sat(1, 968)/ 978.000/,Sat(2, 968)/ 112.150/
          data  Sat(1, 969)/ 979.000/,Sat(2, 969)/ 112.176/
          data  Sat(1, 970)/ 980.000/,Sat(2, 970)/ 112.130/
          data  Sat(1, 971)/ 981.000/,Sat(2, 971)/ 112.037/
          data  Sat(1, 972)/ 982.000/,Sat(2, 972)/ 111.914/
          data  Sat(1, 973)/ 983.000/,Sat(2, 973)/ 111.768/
          data  Sat(1, 974)/ 984.000/,Sat(2, 974)/ 111.605/
          data  Sat(1, 975)/ 985.000/,Sat(2, 975)/ 111.430/
          data  Sat(1, 976)/ 986.000/,Sat(2, 976)/ 111.243/
          data  Sat(1, 977)/ 987.000/,Sat(2, 977)/ 111.047/
          data  Sat(1, 978)/ 988.000/,Sat(2, 978)/ 110.843/
          data  Sat(1, 979)/ 989.000/,Sat(2, 979)/ 110.632/
          data  Sat(1, 980)/ 990.000/,Sat(2, 980)/ 110.413/
          data  Sat(1, 981)/ 991.000/,Sat(2, 981)/ 110.187/
          data  Sat(1, 982)/ 992.000/,Sat(2, 982)/ 109.956/
          data  Sat(1, 983)/ 993.000/,Sat(2, 983)/ 109.717/
          data  Sat(1, 984)/ 994.000/,Sat(2, 984)/ 109.473/
          data  Sat(1, 985)/ 995.000/,Sat(2, 985)/ 109.222/
          data  Sat(1, 986)/ 996.000/,Sat(2, 986)/ 108.964/
          data  Sat(1, 987)/ 997.000/,Sat(2, 987)/ 108.701/
          data  Sat(1, 988)/ 998.000/,Sat(2, 988)/ 108.431/
          data  Sat(1, 989)/ 999.000/,Sat(2, 989)/ 108.154/
          data  Sat(1, 990)/1000.000/,Sat(2, 990)/ 107.871/
c++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c!Uranus model - from Eric Weisstein's JOVIAN
c!H2 type: equillibrium
c!H2 form: D&B
c!He form: B&G
c!H2 mxr: 0.85
c!CO mxr: 0.
c!HCN mxr: 0.
c!                             Freq(GHz)    WDTB(Kelvin)      
          data  Ura(1,   1)/  11.000/,Ura(2,   1)/ 152.826/
          data  Ura(1,   2)/  12.000/,Ura(2,   2)/ 151.648/
          data  Ura(1,   3)/  13.000/,Ura(2,   3)/ 150.559/
          data  Ura(1,   4)/  14.000/,Ura(2,   4)/ 149.545/
          data  Ura(1,   5)/  15.000/,Ura(2,   5)/ 148.596/
          data  Ura(1,   6)/  16.000/,Ura(2,   6)/ 147.707/
          data  Ura(1,   7)/  17.000/,Ura(2,   7)/ 146.870/
          data  Ura(1,   8)/  18.000/,Ura(2,   8)/ 146.083/
          data  Ura(1,   9)/  19.000/,Ura(2,   9)/ 145.344/
          data  Ura(1,  10)/  20.000/,Ura(2,  10)/ 144.649/
          data  Ura(1,  11)/  21.000/,Ura(2,  11)/ 143.999/
          data  Ura(1,  12)/  22.000/,Ura(2,  12)/ 143.392/
          data  Ura(1,  13)/  23.000/,Ura(2,  13)/ 142.828/
          data  Ura(1,  14)/  24.000/,Ura(2,  14)/ 142.306/
          data  Ura(1,  15)/  25.000/,Ura(2,  15)/ 141.825/
          data  Ura(1,  16)/  26.000/,Ura(2,  16)/ 141.383/
          data  Ura(1,  17)/  27.000/,Ura(2,  17)/ 140.978/
          data  Ura(1,  18)/  28.000/,Ura(2,  18)/ 140.609/
          data  Ura(1,  19)/  29.000/,Ura(2,  19)/ 140.271/
          data  Ura(1,  20)/  30.000/,Ura(2,  20)/ 139.964/
          data  Ura(1,  21)/  31.000/,Ura(2,  21)/ 139.683/
          data  Ura(1,  22)/  32.000/,Ura(2,  22)/ 139.427/
          data  Ura(1,  23)/  33.000/,Ura(2,  23)/ 139.190/
          data  Ura(1,  24)/  34.000/,Ura(2,  24)/ 138.973/
          data  Ura(1,  25)/  35.000/,Ura(2,  25)/ 138.770/
          data  Ura(1,  26)/  36.000/,Ura(2,  26)/ 138.581/
          data  Ura(1,  27)/  37.000/,Ura(2,  27)/ 138.402/
          data  Ura(1,  28)/  38.000/,Ura(2,  28)/ 138.232/
          data  Ura(1,  29)/  39.000/,Ura(2,  29)/ 138.068/
          data  Ura(1,  30)/  40.000/,Ura(2,  30)/ 137.912/
          data  Ura(1,  31)/  41.000/,Ura(2,  31)/ 137.758/
          data  Ura(1,  32)/  42.000/,Ura(2,  32)/ 137.608/
          data  Ura(1,  33)/  43.000/,Ura(2,  33)/ 137.460/
          data  Ura(1,  34)/  44.000/,Ura(2,  34)/ 137.313/
          data  Ura(1,  35)/  45.000/,Ura(2,  35)/ 137.167/
          data  Ura(1,  36)/  46.000/,Ura(2,  36)/ 137.021/
          data  Ura(1,  37)/  47.000/,Ura(2,  37)/ 136.874/
          data  Ura(1,  38)/  48.000/,Ura(2,  38)/ 136.726/
          data  Ura(1,  39)/  49.000/,Ura(2,  39)/ 136.577/
          data  Ura(1,  40)/  50.000/,Ura(2,  40)/ 136.426/
          data  Ura(1,  41)/  51.000/,Ura(2,  41)/ 136.273/
          data  Ura(1,  42)/  52.000/,Ura(2,  42)/ 136.118/
          data  Ura(1,  43)/  53.000/,Ura(2,  43)/ 135.961/
          data  Ura(1,  44)/  54.000/,Ura(2,  44)/ 135.802/
          data  Ura(1,  45)/  55.000/,Ura(2,  45)/ 135.640/
          data  Ura(1,  46)/  56.000/,Ura(2,  46)/ 135.475/
          data  Ura(1,  47)/  57.000/,Ura(2,  47)/ 135.308/
          data  Ura(1,  48)/  58.000/,Ura(2,  48)/ 135.139/
          data  Ura(1,  49)/  59.000/,Ura(2,  49)/ 134.967/
          data  Ura(1,  50)/  60.000/,Ura(2,  50)/ 134.792/
          data  Ura(1,  51)/  61.000/,Ura(2,  51)/ 134.615/
          data  Ura(1,  52)/  62.000/,Ura(2,  52)/ 134.434/
          data  Ura(1,  53)/  63.000/,Ura(2,  53)/ 134.252/
          data  Ura(1,  54)/  64.000/,Ura(2,  54)/ 134.067/
          data  Ura(1,  55)/  65.000/,Ura(2,  55)/ 133.880/
          data  Ura(1,  56)/  66.000/,Ura(2,  56)/ 133.690/
          data  Ura(1,  57)/  67.000/,Ura(2,  57)/ 133.498/
          data  Ura(1,  58)/  68.000/,Ura(2,  58)/ 133.303/
          data  Ura(1,  59)/  69.000/,Ura(2,  59)/ 133.106/
          data  Ura(1,  60)/  70.000/,Ura(2,  60)/ 132.907/
          data  Ura(1,  61)/  71.000/,Ura(2,  61)/ 132.706/
          data  Ura(1,  62)/  72.000/,Ura(2,  62)/ 132.503/
          data  Ura(1,  63)/  73.000/,Ura(2,  63)/ 132.297/
          data  Ura(1,  64)/  74.000/,Ura(2,  64)/ 132.090/
          data  Ura(1,  65)/  75.000/,Ura(2,  65)/ 131.881/
          data  Ura(1,  66)/  76.000/,Ura(2,  66)/ 131.670/
          data  Ura(1,  67)/  77.000/,Ura(2,  67)/ 131.457/
          data  Ura(1,  68)/  78.000/,Ura(2,  68)/ 131.242/
          data  Ura(1,  69)/  79.000/,Ura(2,  69)/ 131.026/
          data  Ura(1,  70)/  80.000/,Ura(2,  70)/ 130.808/
          data  Ura(1,  71)/  81.000/,Ura(2,  71)/ 130.589/
          data  Ura(1,  72)/  82.000/,Ura(2,  72)/ 130.368/
          data  Ura(1,  73)/  83.000/,Ura(2,  73)/ 130.146/
          data  Ura(1,  74)/  84.000/,Ura(2,  74)/ 129.922/
          data  Ura(1,  75)/  85.000/,Ura(2,  75)/ 129.697/
          data  Ura(1,  76)/  86.000/,Ura(2,  76)/ 129.471/
          data  Ura(1,  77)/  87.000/,Ura(2,  77)/ 129.244/
          data  Ura(1,  78)/  88.000/,Ura(2,  78)/ 129.015/
          data  Ura(1,  79)/  89.000/,Ura(2,  79)/ 128.785/
          data  Ura(1,  80)/  90.000/,Ura(2,  80)/ 128.555/
          data  Ura(1,  81)/  91.000/,Ura(2,  81)/ 128.323/
          data  Ura(1,  82)/  92.000/,Ura(2,  82)/ 128.090/
          data  Ura(1,  83)/  93.000/,Ura(2,  83)/ 127.857/
          data  Ura(1,  84)/  94.000/,Ura(2,  84)/ 127.622/
          data  Ura(1,  85)/  95.000/,Ura(2,  85)/ 127.387/
          data  Ura(1,  86)/  96.000/,Ura(2,  86)/ 127.151/
          data  Ura(1,  87)/  97.000/,Ura(2,  87)/ 126.914/
          data  Ura(1,  88)/  98.000/,Ura(2,  88)/ 126.677/
          data  Ura(1,  89)/  99.000/,Ura(2,  89)/ 126.439/
          data  Ura(1,  90)/ 100.000/,Ura(2,  90)/ 126.201/
          data  Ura(1,  91)/ 101.000/,Ura(2,  91)/ 125.962/
          data  Ura(1,  92)/ 102.000/,Ura(2,  92)/ 125.723/
          data  Ura(1,  93)/ 103.000/,Ura(2,  93)/ 125.483/
          data  Ura(1,  94)/ 104.000/,Ura(2,  94)/ 125.243/
          data  Ura(1,  95)/ 105.000/,Ura(2,  95)/ 125.002/
          data  Ura(1,  96)/ 106.000/,Ura(2,  96)/ 124.761/
          data  Ura(1,  97)/ 107.000/,Ura(2,  97)/ 124.520/
          data  Ura(1,  98)/ 108.000/,Ura(2,  98)/ 124.279/
          data  Ura(1,  99)/ 109.000/,Ura(2,  99)/ 124.037/
          data  Ura(1, 100)/ 110.000/,Ura(2, 100)/ 123.796/
          data  Ura(1, 101)/ 111.000/,Ura(2, 101)/ 123.554/
          data  Ura(1, 102)/ 112.000/,Ura(2, 102)/ 123.312/
          data  Ura(1, 103)/ 113.000/,Ura(2, 103)/ 123.070/
          data  Ura(1, 104)/ 114.000/,Ura(2, 104)/ 122.828/
          data  Ura(1, 105)/ 115.000/,Ura(2, 105)/ 122.586/
          data  Ura(1, 106)/ 116.000/,Ura(2, 106)/ 122.344/
          data  Ura(1, 107)/ 117.000/,Ura(2, 107)/ 122.102/
          data  Ura(1, 108)/ 118.000/,Ura(2, 108)/ 121.860/
          data  Ura(1, 109)/ 119.000/,Ura(2, 109)/ 121.619/
          data  Ura(1, 110)/ 120.000/,Ura(2, 110)/ 121.377/
          data  Ura(1, 111)/ 121.000/,Ura(2, 111)/ 121.136/
          data  Ura(1, 112)/ 122.000/,Ura(2, 112)/ 120.895/
          data  Ura(1, 113)/ 123.000/,Ura(2, 113)/ 120.654/
          data  Ura(1, 114)/ 124.000/,Ura(2, 114)/ 120.414/
          data  Ura(1, 115)/ 125.000/,Ura(2, 115)/ 120.173/
          data  Ura(1, 116)/ 126.000/,Ura(2, 116)/ 119.933/
          data  Ura(1, 117)/ 127.000/,Ura(2, 117)/ 119.694/
          data  Ura(1, 118)/ 128.000/,Ura(2, 118)/ 119.454/
          data  Ura(1, 119)/ 129.000/,Ura(2, 119)/ 119.216/
          data  Ura(1, 120)/ 130.000/,Ura(2, 120)/ 118.977/
          data  Ura(1, 121)/ 131.000/,Ura(2, 121)/ 118.739/
          data  Ura(1, 122)/ 132.000/,Ura(2, 122)/ 118.502/
          data  Ura(1, 123)/ 133.000/,Ura(2, 123)/ 118.265/
          data  Ura(1, 124)/ 134.000/,Ura(2, 124)/ 118.027/
          data  Ura(1, 125)/ 135.000/,Ura(2, 125)/ 117.791/
          data  Ura(1, 126)/ 136.000/,Ura(2, 126)/ 117.556/
          data  Ura(1, 127)/ 137.000/,Ura(2, 127)/ 117.321/
          data  Ura(1, 128)/ 138.000/,Ura(2, 128)/ 117.086/
          data  Ura(1, 129)/ 139.000/,Ura(2, 129)/ 116.852/
          data  Ura(1, 130)/ 140.000/,Ura(2, 130)/ 116.619/
          data  Ura(1, 131)/ 141.000/,Ura(2, 131)/ 116.386/
          data  Ura(1, 132)/ 142.000/,Ura(2, 132)/ 116.154/
          data  Ura(1, 133)/ 143.000/,Ura(2, 133)/ 115.923/
          data  Ura(1, 134)/ 144.000/,Ura(2, 134)/ 115.692/
          data  Ura(1, 135)/ 145.000/,Ura(2, 135)/ 115.462/
          data  Ura(1, 136)/ 146.000/,Ura(2, 136)/ 115.233/
          data  Ura(1, 137)/ 147.000/,Ura(2, 137)/ 115.004/
          data  Ura(1, 138)/ 148.000/,Ura(2, 138)/ 114.775/
          data  Ura(1, 139)/ 149.000/,Ura(2, 139)/ 114.548/
          data  Ura(1, 140)/ 150.000/,Ura(2, 140)/ 114.322/
          data  Ura(1, 141)/ 151.000/,Ura(2, 141)/ 114.096/
          data  Ura(1, 142)/ 152.000/,Ura(2, 142)/ 113.871/
          data  Ura(1, 143)/ 153.000/,Ura(2, 143)/ 113.646/
          data  Ura(1, 144)/ 154.000/,Ura(2, 144)/ 113.423/
          data  Ura(1, 145)/ 155.000/,Ura(2, 145)/ 113.200/
          data  Ura(1, 146)/ 156.000/,Ura(2, 146)/ 112.978/
          data  Ura(1, 147)/ 157.000/,Ura(2, 147)/ 112.756/
          data  Ura(1, 148)/ 158.000/,Ura(2, 148)/ 112.536/
          data  Ura(1, 149)/ 159.000/,Ura(2, 149)/ 112.316/
          data  Ura(1, 150)/ 160.000/,Ura(2, 150)/ 112.098/
          data  Ura(1, 151)/ 161.000/,Ura(2, 151)/ 111.880/
          data  Ura(1, 152)/ 162.000/,Ura(2, 152)/ 111.662/
          data  Ura(1, 153)/ 163.000/,Ura(2, 153)/ 111.446/
          data  Ura(1, 154)/ 164.000/,Ura(2, 154)/ 111.231/
          data  Ura(1, 155)/ 165.000/,Ura(2, 155)/ 111.016/
          data  Ura(1, 156)/ 166.000/,Ura(2, 156)/ 110.803/
          data  Ura(1, 157)/ 167.000/,Ura(2, 157)/ 110.590/
          data  Ura(1, 158)/ 168.000/,Ura(2, 158)/ 110.378/
          data  Ura(1, 159)/ 169.000/,Ura(2, 159)/ 110.167/
          data  Ura(1, 160)/ 170.000/,Ura(2, 160)/ 109.956/
          data  Ura(1, 161)/ 171.000/,Ura(2, 161)/ 109.747/
          data  Ura(1, 162)/ 172.000/,Ura(2, 162)/ 109.538/
          data  Ura(1, 163)/ 173.000/,Ura(2, 163)/ 109.331/
          data  Ura(1, 164)/ 174.000/,Ura(2, 164)/ 109.124/
          data  Ura(1, 165)/ 175.000/,Ura(2, 165)/ 108.918/
          data  Ura(1, 166)/ 176.000/,Ura(2, 166)/ 108.714/
          data  Ura(1, 167)/ 177.000/,Ura(2, 167)/ 108.509/
          data  Ura(1, 168)/ 178.000/,Ura(2, 168)/ 108.306/
          data  Ura(1, 169)/ 179.000/,Ura(2, 169)/ 108.104/
          data  Ura(1, 170)/ 180.000/,Ura(2, 170)/ 107.903/
          data  Ura(1, 171)/ 181.000/,Ura(2, 171)/ 107.702/
          data  Ura(1, 172)/ 182.000/,Ura(2, 172)/ 107.503/
          data  Ura(1, 173)/ 183.000/,Ura(2, 173)/ 107.304/
          data  Ura(1, 174)/ 184.000/,Ura(2, 174)/ 107.107/
          data  Ura(1, 175)/ 185.000/,Ura(2, 175)/ 106.910/
          data  Ura(1, 176)/ 186.000/,Ura(2, 176)/ 106.714/
          data  Ura(1, 177)/ 187.000/,Ura(2, 177)/ 106.519/
          data  Ura(1, 178)/ 188.000/,Ura(2, 178)/ 106.325/
          data  Ura(1, 179)/ 189.000/,Ura(2, 179)/ 106.132/
          data  Ura(1, 180)/ 190.000/,Ura(2, 180)/ 105.940/
          data  Ura(1, 181)/ 191.000/,Ura(2, 181)/ 105.749/
          data  Ura(1, 182)/ 192.000/,Ura(2, 182)/ 105.558/
          data  Ura(1, 183)/ 193.000/,Ura(2, 183)/ 105.368/
          data  Ura(1, 184)/ 194.000/,Ura(2, 184)/ 105.180/
          data  Ura(1, 185)/ 195.000/,Ura(2, 185)/ 104.992/
          data  Ura(1, 186)/ 196.000/,Ura(2, 186)/ 104.806/
          data  Ura(1, 187)/ 197.000/,Ura(2, 187)/ 104.620/
          data  Ura(1, 188)/ 198.000/,Ura(2, 188)/ 104.435/
          data  Ura(1, 189)/ 199.000/,Ura(2, 189)/ 104.251/
          data  Ura(1, 190)/ 200.000/,Ura(2, 190)/ 104.068/
          data  Ura(1, 191)/ 201.000/,Ura(2, 191)/ 103.886/
          data  Ura(1, 192)/ 202.000/,Ura(2, 192)/ 103.705/
          data  Ura(1, 193)/ 203.000/,Ura(2, 193)/ 103.524/
          data  Ura(1, 194)/ 204.000/,Ura(2, 194)/ 103.345/
          data  Ura(1, 195)/ 205.000/,Ura(2, 195)/ 103.166/
          data  Ura(1, 196)/ 206.000/,Ura(2, 196)/ 102.988/
          data  Ura(1, 197)/ 207.000/,Ura(2, 197)/ 102.812/
          data  Ura(1, 198)/ 208.000/,Ura(2, 198)/ 102.636/
          data  Ura(1, 199)/ 209.000/,Ura(2, 199)/ 102.461/
          data  Ura(1, 200)/ 210.000/,Ura(2, 200)/ 102.287/
          data  Ura(1, 201)/ 211.000/,Ura(2, 201)/ 102.113/
          data  Ura(1, 202)/ 212.000/,Ura(2, 202)/ 101.941/
          data  Ura(1, 203)/ 213.000/,Ura(2, 203)/ 101.769/
          data  Ura(1, 204)/ 214.000/,Ura(2, 204)/ 101.599/
          data  Ura(1, 205)/ 215.000/,Ura(2, 205)/ 101.429/
          data  Ura(1, 206)/ 216.000/,Ura(2, 206)/ 101.260/
          data  Ura(1, 207)/ 217.000/,Ura(2, 207)/ 101.092/
          data  Ura(1, 208)/ 218.000/,Ura(2, 208)/ 100.925/
          data  Ura(1, 209)/ 219.000/,Ura(2, 209)/ 100.758/
          data  Ura(1, 210)/ 220.000/,Ura(2, 210)/ 100.593/
          data  Ura(1, 211)/ 221.000/,Ura(2, 211)/ 100.428/
          data  Ura(1, 212)/ 222.000/,Ura(2, 212)/ 100.265/
          data  Ura(1, 213)/ 223.000/,Ura(2, 213)/ 100.102/
          data  Ura(1, 214)/ 224.000/,Ura(2, 214)/  99.940/
          data  Ura(1, 215)/ 225.000/,Ura(2, 215)/  99.778/
          data  Ura(1, 216)/ 226.000/,Ura(2, 216)/  99.618/
          data  Ura(1, 217)/ 227.000/,Ura(2, 217)/  99.458/
          data  Ura(1, 218)/ 228.000/,Ura(2, 218)/  99.299/
          data  Ura(1, 219)/ 229.000/,Ura(2, 219)/  99.142/
          data  Ura(1, 220)/ 230.000/,Ura(2, 220)/  98.984/
          data  Ura(1, 221)/ 231.000/,Ura(2, 221)/  98.828/
          data  Ura(1, 222)/ 232.000/,Ura(2, 222)/  98.673/
          data  Ura(1, 223)/ 233.000/,Ura(2, 223)/  98.518/
          data  Ura(1, 224)/ 234.000/,Ura(2, 224)/  98.364/
          data  Ura(1, 225)/ 235.000/,Ura(2, 225)/  98.211/
          data  Ura(1, 226)/ 236.000/,Ura(2, 226)/  98.059/
          data  Ura(1, 227)/ 237.000/,Ura(2, 227)/  97.907/
          data  Ura(1, 228)/ 238.000/,Ura(2, 228)/  97.756/
          data  Ura(1, 229)/ 239.000/,Ura(2, 229)/  97.606/
          data  Ura(1, 230)/ 240.000/,Ura(2, 230)/  97.457/
          data  Ura(1, 231)/ 241.000/,Ura(2, 231)/  97.308/
          data  Ura(1, 232)/ 242.000/,Ura(2, 232)/  97.161/
          data  Ura(1, 233)/ 243.000/,Ura(2, 233)/  97.014/
          data  Ura(1, 234)/ 244.000/,Ura(2, 234)/  96.868/
          data  Ura(1, 235)/ 245.000/,Ura(2, 235)/  96.723/
          data  Ura(1, 236)/ 246.000/,Ura(2, 236)/  96.578/
          data  Ura(1, 237)/ 247.000/,Ura(2, 237)/  96.434/
          data  Ura(1, 238)/ 248.000/,Ura(2, 238)/  96.291/
          data  Ura(1, 239)/ 249.000/,Ura(2, 239)/  96.148/
          data  Ura(1, 240)/ 250.000/,Ura(2, 240)/  96.007/
          data  Ura(1, 241)/ 251.000/,Ura(2, 241)/  95.866/
          data  Ura(1, 242)/ 252.000/,Ura(2, 242)/  95.726/
          data  Ura(1, 243)/ 253.000/,Ura(2, 243)/  95.586/
          data  Ura(1, 244)/ 254.000/,Ura(2, 244)/  95.448/
          data  Ura(1, 245)/ 255.000/,Ura(2, 245)/  95.310/
          data  Ura(1, 246)/ 256.000/,Ura(2, 246)/  95.172/
          data  Ura(1, 247)/ 257.000/,Ura(2, 247)/  95.036/
          data  Ura(1, 248)/ 258.000/,Ura(2, 248)/  94.900/
          data  Ura(1, 249)/ 259.000/,Ura(2, 249)/  94.765/
          data  Ura(1, 250)/ 260.000/,Ura(2, 250)/  94.630/
          data  Ura(1, 251)/ 261.000/,Ura(2, 251)/  94.496/
          data  Ura(1, 252)/ 262.000/,Ura(2, 252)/  94.363/
          data  Ura(1, 253)/ 263.000/,Ura(2, 253)/  94.231/
          data  Ura(1, 254)/ 264.000/,Ura(2, 254)/  94.099/
          data  Ura(1, 255)/ 265.000/,Ura(2, 255)/  93.968/
          data  Ura(1, 256)/ 266.000/,Ura(2, 256)/  93.837/
          data  Ura(1, 257)/ 267.000/,Ura(2, 257)/  93.708/
          data  Ura(1, 258)/ 268.000/,Ura(2, 258)/  93.579/
          data  Ura(1, 259)/ 269.000/,Ura(2, 259)/  93.450/
          data  Ura(1, 260)/ 270.000/,Ura(2, 260)/  93.322/
          data  Ura(1, 261)/ 271.000/,Ura(2, 261)/  93.195/
          data  Ura(1, 262)/ 272.000/,Ura(2, 262)/  93.069/
          data  Ura(1, 263)/ 273.000/,Ura(2, 263)/  92.943/
          data  Ura(1, 264)/ 274.000/,Ura(2, 264)/  92.818/
          data  Ura(1, 265)/ 275.000/,Ura(2, 265)/  92.693/
          data  Ura(1, 266)/ 276.000/,Ura(2, 266)/  92.569/
          data  Ura(1, 267)/ 277.000/,Ura(2, 267)/  92.446/
          data  Ura(1, 268)/ 278.000/,Ura(2, 268)/  92.323/
          data  Ura(1, 269)/ 279.000/,Ura(2, 269)/  92.201/
          data  Ura(1, 270)/ 280.000/,Ura(2, 270)/  92.080/
          data  Ura(1, 271)/ 281.000/,Ura(2, 271)/  91.959/
          data  Ura(1, 272)/ 282.000/,Ura(2, 272)/  91.839/
          data  Ura(1, 273)/ 283.000/,Ura(2, 273)/  91.719/
          data  Ura(1, 274)/ 284.000/,Ura(2, 274)/  91.600/
          data  Ura(1, 275)/ 285.000/,Ura(2, 275)/  91.481/
          data  Ura(1, 276)/ 286.000/,Ura(2, 276)/  91.363/
          data  Ura(1, 277)/ 287.000/,Ura(2, 277)/  91.246/
          data  Ura(1, 278)/ 288.000/,Ura(2, 278)/  91.130/
          data  Ura(1, 279)/ 289.000/,Ura(2, 279)/  91.013/
          data  Ura(1, 280)/ 290.000/,Ura(2, 280)/  90.898/
          data  Ura(1, 281)/ 291.000/,Ura(2, 281)/  90.783/
          data  Ura(1, 282)/ 292.000/,Ura(2, 282)/  90.668/
          data  Ura(1, 283)/ 293.000/,Ura(2, 283)/  90.555/
          data  Ura(1, 284)/ 294.000/,Ura(2, 284)/  90.442/
          data  Ura(1, 285)/ 295.000/,Ura(2, 285)/  90.329/
          data  Ura(1, 286)/ 296.000/,Ura(2, 286)/  90.216/
          data  Ura(1, 287)/ 297.000/,Ura(2, 287)/  90.105/
          data  Ura(1, 288)/ 298.000/,Ura(2, 288)/  89.994/
          data  Ura(1, 289)/ 299.000/,Ura(2, 289)/  89.883/
          data  Ura(1, 290)/ 300.000/,Ura(2, 290)/  89.774/
          data  Ura(1, 291)/ 301.000/,Ura(2, 291)/  89.664/
          data  Ura(1, 292)/ 302.000/,Ura(2, 292)/  89.555/
          data  Ura(1, 293)/ 303.000/,Ura(2, 293)/  89.447/
          data  Ura(1, 294)/ 304.000/,Ura(2, 294)/  89.339/
          data  Ura(1, 295)/ 305.000/,Ura(2, 295)/  89.232/
          data  Ura(1, 296)/ 306.000/,Ura(2, 296)/  89.125/
          data  Ura(1, 297)/ 307.000/,Ura(2, 297)/  89.018/
          data  Ura(1, 298)/ 308.000/,Ura(2, 298)/  88.913/
          data  Ura(1, 299)/ 309.000/,Ura(2, 299)/  88.808/
          data  Ura(1, 300)/ 310.000/,Ura(2, 300)/  88.703/
          data  Ura(1, 301)/ 311.000/,Ura(2, 301)/  88.599/
          data  Ura(1, 302)/ 312.000/,Ura(2, 302)/  88.495/
          data  Ura(1, 303)/ 313.000/,Ura(2, 303)/  88.392/
          data  Ura(1, 304)/ 314.000/,Ura(2, 304)/  88.289/
          data  Ura(1, 305)/ 315.000/,Ura(2, 305)/  88.187/
          data  Ura(1, 306)/ 316.000/,Ura(2, 306)/  88.085/
          data  Ura(1, 307)/ 317.000/,Ura(2, 307)/  87.984/
          data  Ura(1, 308)/ 318.000/,Ura(2, 308)/  87.883/
          data  Ura(1, 309)/ 319.000/,Ura(2, 309)/  87.783/
          data  Ura(1, 310)/ 320.000/,Ura(2, 310)/  87.683/
          data  Ura(1, 311)/ 321.000/,Ura(2, 311)/  87.584/
          data  Ura(1, 312)/ 322.000/,Ura(2, 312)/  87.485/
          data  Ura(1, 313)/ 323.000/,Ura(2, 313)/  87.386/
          data  Ura(1, 314)/ 324.000/,Ura(2, 314)/  87.289/
          data  Ura(1, 315)/ 325.000/,Ura(2, 315)/  87.191/
          data  Ura(1, 316)/ 326.000/,Ura(2, 316)/  87.094/
          data  Ura(1, 317)/ 327.000/,Ura(2, 317)/  86.998/
          data  Ura(1, 318)/ 328.000/,Ura(2, 318)/  86.901/
          data  Ura(1, 319)/ 329.000/,Ura(2, 319)/  86.806/
          data  Ura(1, 320)/ 330.000/,Ura(2, 320)/  86.710/
          data  Ura(1, 321)/ 331.000/,Ura(2, 321)/  86.616/
          data  Ura(1, 322)/ 332.000/,Ura(2, 322)/  86.521/
          data  Ura(1, 323)/ 333.000/,Ura(2, 323)/  86.427/
          data  Ura(1, 324)/ 334.000/,Ura(2, 324)/  86.334/
          data  Ura(1, 325)/ 335.000/,Ura(2, 325)/  86.241/
          data  Ura(1, 326)/ 336.000/,Ura(2, 326)/  86.148/
          data  Ura(1, 327)/ 337.000/,Ura(2, 327)/  86.056/
          data  Ura(1, 328)/ 338.000/,Ura(2, 328)/  85.964/
          data  Ura(1, 329)/ 339.000/,Ura(2, 329)/  85.873/
          data  Ura(1, 330)/ 340.000/,Ura(2, 330)/  85.782/
          data  Ura(1, 331)/ 341.000/,Ura(2, 331)/  85.692/
          data  Ura(1, 332)/ 342.000/,Ura(2, 332)/  85.602/
          data  Ura(1, 333)/ 343.000/,Ura(2, 333)/  85.512/
          data  Ura(1, 334)/ 344.000/,Ura(2, 334)/  85.423/
          data  Ura(1, 335)/ 345.000/,Ura(2, 335)/  85.334/
          data  Ura(1, 336)/ 346.000/,Ura(2, 336)/  85.246/
          data  Ura(1, 337)/ 347.000/,Ura(2, 337)/  85.158/
          data  Ura(1, 338)/ 348.000/,Ura(2, 338)/  85.070/
          data  Ura(1, 339)/ 349.000/,Ura(2, 339)/  84.983/
          data  Ura(1, 340)/ 350.000/,Ura(2, 340)/  84.896/
          data  Ura(1, 341)/ 351.000/,Ura(2, 341)/  84.809/
          data  Ura(1, 342)/ 352.000/,Ura(2, 342)/  84.723/
          data  Ura(1, 343)/ 353.000/,Ura(2, 343)/  84.638/
          data  Ura(1, 344)/ 354.000/,Ura(2, 344)/  84.552/
          data  Ura(1, 345)/ 355.000/,Ura(2, 345)/  84.467/
          data  Ura(1, 346)/ 356.000/,Ura(2, 346)/  84.383/
          data  Ura(1, 347)/ 357.000/,Ura(2, 347)/  84.299/
          data  Ura(1, 348)/ 358.000/,Ura(2, 348)/  84.215/
          data  Ura(1, 349)/ 359.000/,Ura(2, 349)/  84.132/
          data  Ura(1, 350)/ 360.000/,Ura(2, 350)/  84.049/
          data  Ura(1, 351)/ 361.000/,Ura(2, 351)/  83.966/
          data  Ura(1, 352)/ 362.000/,Ura(2, 352)/  83.884/
          data  Ura(1, 353)/ 363.000/,Ura(2, 353)/  83.802/
          data  Ura(1, 354)/ 364.000/,Ura(2, 354)/  83.720/
          data  Ura(1, 355)/ 365.000/,Ura(2, 355)/  83.639/
          data  Ura(1, 356)/ 366.000/,Ura(2, 356)/  83.558/
          data  Ura(1, 357)/ 367.000/,Ura(2, 357)/  83.478/
          data  Ura(1, 358)/ 368.000/,Ura(2, 358)/  83.398/
          data  Ura(1, 359)/ 369.000/,Ura(2, 359)/  83.318/
          data  Ura(1, 360)/ 370.000/,Ura(2, 360)/  83.238/
          data  Ura(1, 361)/ 371.000/,Ura(2, 361)/  83.159/
          data  Ura(1, 362)/ 372.000/,Ura(2, 362)/  83.081/
          data  Ura(1, 363)/ 373.000/,Ura(2, 363)/  83.002/
          data  Ura(1, 364)/ 374.000/,Ura(2, 364)/  82.924/
          data  Ura(1, 365)/ 375.000/,Ura(2, 365)/  82.846/
          data  Ura(1, 366)/ 376.000/,Ura(2, 366)/  82.769/
          data  Ura(1, 367)/ 377.000/,Ura(2, 367)/  82.692/
          data  Ura(1, 368)/ 378.000/,Ura(2, 368)/  82.616/
          data  Ura(1, 369)/ 379.000/,Ura(2, 369)/  82.539/
          data  Ura(1, 370)/ 380.000/,Ura(2, 370)/  82.463/
          data  Ura(1, 371)/ 381.000/,Ura(2, 371)/  82.387/
          data  Ura(1, 372)/ 382.000/,Ura(2, 372)/  82.312/
          data  Ura(1, 373)/ 383.000/,Ura(2, 373)/  82.237/
          data  Ura(1, 374)/ 384.000/,Ura(2, 374)/  82.162/
          data  Ura(1, 375)/ 385.000/,Ura(2, 375)/  82.088/
          data  Ura(1, 376)/ 386.000/,Ura(2, 376)/  82.013/
          data  Ura(1, 377)/ 387.000/,Ura(2, 377)/  81.940/
          data  Ura(1, 378)/ 388.000/,Ura(2, 378)/  81.866/
          data  Ura(1, 379)/ 389.000/,Ura(2, 379)/  81.793/
          data  Ura(1, 380)/ 390.000/,Ura(2, 380)/  81.720/
          data  Ura(1, 381)/ 391.000/,Ura(2, 381)/  81.648/
          data  Ura(1, 382)/ 392.000/,Ura(2, 382)/  81.575/
          data  Ura(1, 383)/ 393.000/,Ura(2, 383)/  81.504/
          data  Ura(1, 384)/ 394.000/,Ura(2, 384)/  81.432/
          data  Ura(1, 385)/ 395.000/,Ura(2, 385)/  81.361/
          data  Ura(1, 386)/ 396.000/,Ura(2, 386)/  81.290/
          data  Ura(1, 387)/ 397.000/,Ura(2, 387)/  81.219/
          data  Ura(1, 388)/ 398.000/,Ura(2, 388)/  81.148/
          data  Ura(1, 389)/ 399.000/,Ura(2, 389)/  81.078/
          data  Ura(1, 390)/ 400.000/,Ura(2, 390)/  81.008/
          data  Ura(1, 391)/ 401.000/,Ura(2, 391)/  80.939/
          data  Ura(1, 392)/ 402.000/,Ura(2, 392)/  80.870/
          data  Ura(1, 393)/ 403.000/,Ura(2, 393)/  80.801/
          data  Ura(1, 394)/ 404.000/,Ura(2, 394)/  80.732/
          data  Ura(1, 395)/ 405.000/,Ura(2, 395)/  80.663/
          data  Ura(1, 396)/ 406.000/,Ura(2, 396)/  80.595/
          data  Ura(1, 397)/ 407.000/,Ura(2, 397)/  80.527/
          data  Ura(1, 398)/ 408.000/,Ura(2, 398)/  80.460/
          data  Ura(1, 399)/ 409.000/,Ura(2, 399)/  80.393/
          data  Ura(1, 400)/ 410.000/,Ura(2, 400)/  80.326/
          data  Ura(1, 401)/ 411.000/,Ura(2, 401)/  80.259/
          data  Ura(1, 402)/ 412.000/,Ura(2, 402)/  80.192/
          data  Ura(1, 403)/ 413.000/,Ura(2, 403)/  80.126/
          data  Ura(1, 404)/ 414.000/,Ura(2, 404)/  80.060/
          data  Ura(1, 405)/ 415.000/,Ura(2, 405)/  79.994/
          data  Ura(1, 406)/ 416.000/,Ura(2, 406)/  79.929/
          data  Ura(1, 407)/ 417.000/,Ura(2, 407)/  79.864/
          data  Ura(1, 408)/ 418.000/,Ura(2, 408)/  79.799/
          data  Ura(1, 409)/ 419.000/,Ura(2, 409)/  79.734/
          data  Ura(1, 410)/ 420.000/,Ura(2, 410)/  79.670/
          data  Ura(1, 411)/ 421.000/,Ura(2, 411)/  79.605/
          data  Ura(1, 412)/ 422.000/,Ura(2, 412)/  79.542/
          data  Ura(1, 413)/ 423.000/,Ura(2, 413)/  79.478/
          data  Ura(1, 414)/ 424.000/,Ura(2, 414)/  79.415/
          data  Ura(1, 415)/ 425.000/,Ura(2, 415)/  79.352/
          data  Ura(1, 416)/ 426.000/,Ura(2, 416)/  79.288/
          data  Ura(1, 417)/ 427.000/,Ura(2, 417)/  79.226/
          data  Ura(1, 418)/ 428.000/,Ura(2, 418)/  79.163/
          data  Ura(1, 419)/ 429.000/,Ura(2, 419)/  79.101/
          data  Ura(1, 420)/ 430.000/,Ura(2, 420)/  79.039/
          data  Ura(1, 421)/ 431.000/,Ura(2, 421)/  78.977/
          data  Ura(1, 422)/ 432.000/,Ura(2, 422)/  78.916/
          data  Ura(1, 423)/ 433.000/,Ura(2, 423)/  78.854/
          data  Ura(1, 424)/ 434.000/,Ura(2, 424)/  78.793/
          data  Ura(1, 425)/ 435.000/,Ura(2, 425)/  78.732/
          data  Ura(1, 426)/ 436.000/,Ura(2, 426)/  78.671/
          data  Ura(1, 427)/ 437.000/,Ura(2, 427)/  78.611/
          data  Ura(1, 428)/ 438.000/,Ura(2, 428)/  78.550/
          data  Ura(1, 429)/ 439.000/,Ura(2, 429)/  78.490/
          data  Ura(1, 430)/ 440.000/,Ura(2, 430)/  78.430/
          data  Ura(1, 431)/ 441.000/,Ura(2, 431)/  78.370/
          data  Ura(1, 432)/ 442.000/,Ura(2, 432)/  78.310/
          data  Ura(1, 433)/ 443.000/,Ura(2, 433)/  78.250/
          data  Ura(1, 434)/ 444.000/,Ura(2, 434)/  78.190/
          data  Ura(1, 435)/ 445.000/,Ura(2, 435)/  78.131/
          data  Ura(1, 436)/ 446.000/,Ura(2, 436)/  78.071/
          data  Ura(1, 437)/ 447.000/,Ura(2, 437)/  78.011/
          data  Ura(1, 438)/ 448.000/,Ura(2, 438)/  77.951/
          data  Ura(1, 439)/ 449.000/,Ura(2, 439)/  77.891/
          data  Ura(1, 440)/ 450.000/,Ura(2, 440)/  77.831/
          data  Ura(1, 441)/ 451.000/,Ura(2, 441)/  77.770/
          data  Ura(1, 442)/ 452.000/,Ura(2, 442)/  77.708/
          data  Ura(1, 443)/ 453.000/,Ura(2, 443)/  77.646/
          data  Ura(1, 444)/ 454.000/,Ura(2, 444)/  77.582/
          data  Ura(1, 445)/ 455.000/,Ura(2, 445)/  77.516/
          data  Ura(1, 446)/ 456.000/,Ura(2, 446)/  77.448/
          data  Ura(1, 447)/ 457.000/,Ura(2, 447)/  77.375/
          data  Ura(1, 448)/ 458.000/,Ura(2, 448)/  77.297/
          data  Ura(1, 449)/ 459.000/,Ura(2, 449)/  77.209/
          data  Ura(1, 450)/ 460.000/,Ura(2, 450)/  77.106/
          data  Ura(1, 451)/ 461.000/,Ura(2, 451)/  76.977/
          data  Ura(1, 452)/ 462.000/,Ura(2, 452)/  76.800/
          data  Ura(1, 453)/ 463.000/,Ura(2, 453)/  76.525/
          data  Ura(1, 454)/ 464.000/,Ura(2, 454)/  76.003/
          data  Ura(1, 455)/ 465.000/,Ura(2, 455)/  74.456/
          data  Ura(1, 456)/ 466.000/,Ura(2, 456)/  75.439/
          data  Ura(1, 457)/ 467.000/,Ura(2, 457)/  76.139/
          data  Ura(1, 458)/ 468.000/,Ura(2, 458)/  76.397/
          data  Ura(1, 459)/ 469.000/,Ura(2, 459)/  76.505/
          data  Ura(1, 460)/ 470.000/,Ura(2, 460)/  76.546/
          data  Ura(1, 461)/ 471.000/,Ura(2, 461)/  76.552/
          data  Ura(1, 462)/ 472.000/,Ura(2, 462)/  76.538/
          data  Ura(1, 463)/ 473.000/,Ura(2, 463)/  76.512/
          data  Ura(1, 464)/ 474.000/,Ura(2, 464)/  76.480/
          data  Ura(1, 465)/ 475.000/,Ura(2, 465)/  76.442/
          data  Ura(1, 466)/ 476.000/,Ura(2, 466)/  76.402/
          data  Ura(1, 467)/ 477.000/,Ura(2, 467)/  76.359/
          data  Ura(1, 468)/ 478.000/,Ura(2, 468)/  76.314/
          data  Ura(1, 469)/ 479.000/,Ura(2, 469)/  76.269/
          data  Ura(1, 470)/ 480.000/,Ura(2, 470)/  76.222/
          data  Ura(1, 471)/ 481.000/,Ura(2, 471)/  76.175/
          data  Ura(1, 472)/ 482.000/,Ura(2, 472)/  76.128/
          data  Ura(1, 473)/ 483.000/,Ura(2, 473)/  76.080/
          data  Ura(1, 474)/ 484.000/,Ura(2, 474)/  76.032/
          data  Ura(1, 475)/ 485.000/,Ura(2, 475)/  75.984/
          data  Ura(1, 476)/ 486.000/,Ura(2, 476)/  75.936/
          data  Ura(1, 477)/ 487.000/,Ura(2, 477)/  75.888/
          data  Ura(1, 478)/ 488.000/,Ura(2, 478)/  75.840/
          data  Ura(1, 479)/ 489.000/,Ura(2, 479)/  75.792/
          data  Ura(1, 480)/ 490.000/,Ura(2, 480)/  75.744/
          data  Ura(1, 481)/ 491.000/,Ura(2, 481)/  75.696/
          data  Ura(1, 482)/ 492.000/,Ura(2, 482)/  75.648/
          data  Ura(1, 483)/ 493.000/,Ura(2, 483)/  75.601/
          data  Ura(1, 484)/ 494.000/,Ura(2, 484)/  75.553/
          data  Ura(1, 485)/ 495.000/,Ura(2, 485)/  75.506/
          data  Ura(1, 486)/ 496.000/,Ura(2, 486)/  75.458/
          data  Ura(1, 487)/ 497.000/,Ura(2, 487)/  75.411/
          data  Ura(1, 488)/ 498.000/,Ura(2, 488)/  75.364/
          data  Ura(1, 489)/ 499.000/,Ura(2, 489)/  75.317/
          data  Ura(1, 490)/ 500.000/,Ura(2, 490)/  75.270/
          data  Ura(1, 491)/ 501.000/,Ura(2, 491)/  75.224/
          data  Ura(1, 492)/ 502.000/,Ura(2, 492)/  75.177/
          data  Ura(1, 493)/ 503.000/,Ura(2, 493)/  75.131/
          data  Ura(1, 494)/ 504.000/,Ura(2, 494)/  75.085/
          data  Ura(1, 495)/ 505.000/,Ura(2, 495)/  75.039/
          data  Ura(1, 496)/ 506.000/,Ura(2, 496)/  74.993/
          data  Ura(1, 497)/ 507.000/,Ura(2, 497)/  74.947/
          data  Ura(1, 498)/ 508.000/,Ura(2, 498)/  74.902/
          data  Ura(1, 499)/ 509.000/,Ura(2, 499)/  74.856/
          data  Ura(1, 500)/ 510.000/,Ura(2, 500)/  74.811/
          data  Ura(1, 501)/ 511.000/,Ura(2, 501)/  74.766/
          data  Ura(1, 502)/ 512.000/,Ura(2, 502)/  74.721/
          data  Ura(1, 503)/ 513.000/,Ura(2, 503)/  74.676/
          data  Ura(1, 504)/ 514.000/,Ura(2, 504)/  74.631/
          data  Ura(1, 505)/ 515.000/,Ura(2, 505)/  74.587/
          data  Ura(1, 506)/ 516.000/,Ura(2, 506)/  74.543/
          data  Ura(1, 507)/ 517.000/,Ura(2, 507)/  74.498/
          data  Ura(1, 508)/ 518.000/,Ura(2, 508)/  74.455/
          data  Ura(1, 509)/ 519.000/,Ura(2, 509)/  74.411/
          data  Ura(1, 510)/ 520.000/,Ura(2, 510)/  74.367/
          data  Ura(1, 511)/ 521.000/,Ura(2, 511)/  74.323/
          data  Ura(1, 512)/ 522.000/,Ura(2, 512)/  74.280/
          data  Ura(1, 513)/ 523.000/,Ura(2, 513)/  74.237/
          data  Ura(1, 514)/ 524.000/,Ura(2, 514)/  74.194/
          data  Ura(1, 515)/ 525.000/,Ura(2, 515)/  74.150/
          data  Ura(1, 516)/ 526.000/,Ura(2, 516)/  74.108/
          data  Ura(1, 517)/ 527.000/,Ura(2, 517)/  74.065/
          data  Ura(1, 518)/ 528.000/,Ura(2, 518)/  74.023/
          data  Ura(1, 519)/ 529.000/,Ura(2, 519)/  73.980/
          data  Ura(1, 520)/ 530.000/,Ura(2, 520)/  73.938/
          data  Ura(1, 521)/ 531.000/,Ura(2, 521)/  73.896/
          data  Ura(1, 522)/ 532.000/,Ura(2, 522)/  73.854/
          data  Ura(1, 523)/ 533.000/,Ura(2, 523)/  73.813/
          data  Ura(1, 524)/ 534.000/,Ura(2, 524)/  73.771/
          data  Ura(1, 525)/ 535.000/,Ura(2, 525)/  73.729/
          data  Ura(1, 526)/ 536.000/,Ura(2, 526)/  73.688/
          data  Ura(1, 527)/ 537.000/,Ura(2, 527)/  73.647/
          data  Ura(1, 528)/ 538.000/,Ura(2, 528)/  73.606/
          data  Ura(1, 529)/ 539.000/,Ura(2, 529)/  73.565/
          data  Ura(1, 530)/ 540.000/,Ura(2, 530)/  73.524/
          data  Ura(1, 531)/ 541.000/,Ura(2, 531)/  73.484/
          data  Ura(1, 532)/ 542.000/,Ura(2, 532)/  73.443/
          data  Ura(1, 533)/ 543.000/,Ura(2, 533)/  73.403/
          data  Ura(1, 534)/ 544.000/,Ura(2, 534)/  73.363/
          data  Ura(1, 535)/ 545.000/,Ura(2, 535)/  73.323/
          data  Ura(1, 536)/ 546.000/,Ura(2, 536)/  73.283/
          data  Ura(1, 537)/ 547.000/,Ura(2, 537)/  73.243/
          data  Ura(1, 538)/ 548.000/,Ura(2, 538)/  73.203/
          data  Ura(1, 539)/ 549.000/,Ura(2, 539)/  73.164/
          data  Ura(1, 540)/ 550.000/,Ura(2, 540)/  73.124/
          data  Ura(1, 541)/ 551.000/,Ura(2, 541)/  73.085/
          data  Ura(1, 542)/ 552.000/,Ura(2, 542)/  73.046/
          data  Ura(1, 543)/ 553.000/,Ura(2, 543)/  73.007/
          data  Ura(1, 544)/ 554.000/,Ura(2, 544)/  72.968/
          data  Ura(1, 545)/ 555.000/,Ura(2, 545)/  72.930/
          data  Ura(1, 546)/ 556.000/,Ura(2, 546)/  72.891/
          data  Ura(1, 547)/ 557.000/,Ura(2, 547)/  72.853/
          data  Ura(1, 548)/ 558.000/,Ura(2, 548)/  72.814/
          data  Ura(1, 549)/ 559.000/,Ura(2, 549)/  72.776/
          data  Ura(1, 550)/ 560.000/,Ura(2, 550)/  72.738/
          data  Ura(1, 551)/ 561.000/,Ura(2, 551)/  72.700/
          data  Ura(1, 552)/ 562.000/,Ura(2, 552)/  72.662/
          data  Ura(1, 553)/ 563.000/,Ura(2, 553)/  72.625/
          data  Ura(1, 554)/ 564.000/,Ura(2, 554)/  72.587/
          data  Ura(1, 555)/ 565.000/,Ura(2, 555)/  72.550/
          data  Ura(1, 556)/ 566.000/,Ura(2, 556)/  72.512/
          data  Ura(1, 557)/ 567.000/,Ura(2, 557)/  72.475/
          data  Ura(1, 558)/ 568.000/,Ura(2, 558)/  72.438/
          data  Ura(1, 559)/ 569.000/,Ura(2, 559)/  72.401/
          data  Ura(1, 560)/ 570.000/,Ura(2, 560)/  72.365/
          data  Ura(1, 561)/ 571.000/,Ura(2, 561)/  72.328/
          data  Ura(1, 562)/ 572.000/,Ura(2, 562)/  72.291/
          data  Ura(1, 563)/ 573.000/,Ura(2, 563)/  72.255/
          data  Ura(1, 564)/ 574.000/,Ura(2, 564)/  72.219/
          data  Ura(1, 565)/ 575.000/,Ura(2, 565)/  72.183/
          data  Ura(1, 566)/ 576.000/,Ura(2, 566)/  72.147/
          data  Ura(1, 567)/ 577.000/,Ura(2, 567)/  72.111/
          data  Ura(1, 568)/ 578.000/,Ura(2, 568)/  72.076/
          data  Ura(1, 569)/ 579.000/,Ura(2, 569)/  72.040/
          data  Ura(1, 570)/ 580.000/,Ura(2, 570)/  72.005/
          data  Ura(1, 571)/ 581.000/,Ura(2, 571)/  71.970/
          data  Ura(1, 572)/ 582.000/,Ura(2, 572)/  71.934/
          data  Ura(1, 573)/ 583.000/,Ura(2, 573)/  71.899/
          data  Ura(1, 574)/ 584.000/,Ura(2, 574)/  71.864/
          data  Ura(1, 575)/ 585.000/,Ura(2, 575)/  71.830/
          data  Ura(1, 576)/ 586.000/,Ura(2, 576)/  71.795/
          data  Ura(1, 577)/ 587.000/,Ura(2, 577)/  71.760/
          data  Ura(1, 578)/ 588.000/,Ura(2, 578)/  71.726/
          data  Ura(1, 579)/ 589.000/,Ura(2, 579)/  71.691/
          data  Ura(1, 580)/ 590.000/,Ura(2, 580)/  71.657/
          data  Ura(1, 581)/ 591.000/,Ura(2, 581)/  71.623/
          data  Ura(1, 582)/ 592.000/,Ura(2, 582)/  71.589/
          data  Ura(1, 583)/ 593.000/,Ura(2, 583)/  71.555/
          data  Ura(1, 584)/ 594.000/,Ura(2, 584)/  71.521/
          data  Ura(1, 585)/ 595.000/,Ura(2, 585)/  71.487/
          data  Ura(1, 586)/ 596.000/,Ura(2, 586)/  71.454/
          data  Ura(1, 587)/ 597.000/,Ura(2, 587)/  71.420/
          data  Ura(1, 588)/ 598.000/,Ura(2, 588)/  71.387/
          data  Ura(1, 589)/ 599.000/,Ura(2, 589)/  71.353/
          data  Ura(1, 590)/ 600.000/,Ura(2, 590)/  71.320/
          data  Ura(1, 591)/ 601.000/,Ura(2, 591)/  71.287/
          data  Ura(1, 592)/ 602.000/,Ura(2, 592)/  71.254/
          data  Ura(1, 593)/ 603.000/,Ura(2, 593)/  71.221/
          data  Ura(1, 594)/ 604.000/,Ura(2, 594)/  71.189/
          data  Ura(1, 595)/ 605.000/,Ura(2, 595)/  71.156/
          data  Ura(1, 596)/ 606.000/,Ura(2, 596)/  71.123/
          data  Ura(1, 597)/ 607.000/,Ura(2, 597)/  71.091/
          data  Ura(1, 598)/ 608.000/,Ura(2, 598)/  71.059/
          data  Ura(1, 599)/ 609.000/,Ura(2, 599)/  71.027/
          data  Ura(1, 600)/ 610.000/,Ura(2, 600)/  70.995/
          data  Ura(1, 601)/ 611.000/,Ura(2, 601)/  70.962/
          data  Ura(1, 602)/ 612.000/,Ura(2, 602)/  70.930/
          data  Ura(1, 603)/ 613.000/,Ura(2, 603)/  70.899/
          data  Ura(1, 604)/ 614.000/,Ura(2, 604)/  70.867/
          data  Ura(1, 605)/ 615.000/,Ura(2, 605)/  70.835/
          data  Ura(1, 606)/ 616.000/,Ura(2, 606)/  70.804/
          data  Ura(1, 607)/ 617.000/,Ura(2, 607)/  70.772/
          data  Ura(1, 608)/ 618.000/,Ura(2, 608)/  70.741/
          data  Ura(1, 609)/ 619.000/,Ura(2, 609)/  70.710/
          data  Ura(1, 610)/ 620.000/,Ura(2, 610)/  70.679/
          data  Ura(1, 611)/ 621.000/,Ura(2, 611)/  70.648/
          data  Ura(1, 612)/ 622.000/,Ura(2, 612)/  70.617/
          data  Ura(1, 613)/ 623.000/,Ura(2, 613)/  70.586/
          data  Ura(1, 614)/ 624.000/,Ura(2, 614)/  70.555/
          data  Ura(1, 615)/ 625.000/,Ura(2, 615)/  70.525/
          data  Ura(1, 616)/ 626.000/,Ura(2, 616)/  70.494/
          data  Ura(1, 617)/ 627.000/,Ura(2, 617)/  70.464/
          data  Ura(1, 618)/ 628.000/,Ura(2, 618)/  70.433/
          data  Ura(1, 619)/ 629.000/,Ura(2, 619)/  70.403/
          data  Ura(1, 620)/ 630.000/,Ura(2, 620)/  70.373/
          data  Ura(1, 621)/ 631.000/,Ura(2, 621)/  70.343/
          data  Ura(1, 622)/ 632.000/,Ura(2, 622)/  70.313/
          data  Ura(1, 623)/ 633.000/,Ura(2, 623)/  70.283/
          data  Ura(1, 624)/ 634.000/,Ura(2, 624)/  70.254/
          data  Ura(1, 625)/ 635.000/,Ura(2, 625)/  70.224/
          data  Ura(1, 626)/ 636.000/,Ura(2, 626)/  70.194/
          data  Ura(1, 627)/ 637.000/,Ura(2, 627)/  70.165/
          data  Ura(1, 628)/ 638.000/,Ura(2, 628)/  70.135/
          data  Ura(1, 629)/ 639.000/,Ura(2, 629)/  70.106/
          data  Ura(1, 630)/ 640.000/,Ura(2, 630)/  70.077/
          data  Ura(1, 631)/ 641.000/,Ura(2, 631)/  70.048/
          data  Ura(1, 632)/ 642.000/,Ura(2, 632)/  70.019/
          data  Ura(1, 633)/ 643.000/,Ura(2, 633)/  69.990/
          data  Ura(1, 634)/ 644.000/,Ura(2, 634)/  69.961/
          data  Ura(1, 635)/ 645.000/,Ura(2, 635)/  69.932/
          data  Ura(1, 636)/ 646.000/,Ura(2, 636)/  69.904/
          data  Ura(1, 637)/ 647.000/,Ura(2, 637)/  69.875/
          data  Ura(1, 638)/ 648.000/,Ura(2, 638)/  69.846/
          data  Ura(1, 639)/ 649.000/,Ura(2, 639)/  69.818/
          data  Ura(1, 640)/ 650.000/,Ura(2, 640)/  69.789/
          data  Ura(1, 641)/ 651.000/,Ura(2, 641)/  69.761/
          data  Ura(1, 642)/ 652.000/,Ura(2, 642)/  69.733/
          data  Ura(1, 643)/ 653.000/,Ura(2, 643)/  69.705/
          data  Ura(1, 644)/ 654.000/,Ura(2, 644)/  69.677/
          data  Ura(1, 645)/ 655.000/,Ura(2, 645)/  69.649/
          data  Ura(1, 646)/ 656.000/,Ura(2, 646)/  69.621/
          data  Ura(1, 647)/ 657.000/,Ura(2, 647)/  69.593/
          data  Ura(1, 648)/ 658.000/,Ura(2, 648)/  69.565/
          data  Ura(1, 649)/ 659.000/,Ura(2, 649)/  69.537/
          data  Ura(1, 650)/ 660.000/,Ura(2, 650)/  69.509/
          data  Ura(1, 651)/ 661.000/,Ura(2, 651)/  69.482/
          data  Ura(1, 652)/ 662.000/,Ura(2, 652)/  69.454/
          data  Ura(1, 653)/ 663.000/,Ura(2, 653)/  69.427/
          data  Ura(1, 654)/ 664.000/,Ura(2, 654)/  69.399/
          data  Ura(1, 655)/ 665.000/,Ura(2, 655)/  69.372/
          data  Ura(1, 656)/ 666.000/,Ura(2, 656)/  69.344/
          data  Ura(1, 657)/ 667.000/,Ura(2, 657)/  69.317/
          data  Ura(1, 658)/ 668.000/,Ura(2, 658)/  69.290/
          data  Ura(1, 659)/ 669.000/,Ura(2, 659)/  69.262/
          data  Ura(1, 660)/ 670.000/,Ura(2, 660)/  69.235/
          data  Ura(1, 661)/ 671.000/,Ura(2, 661)/  69.208/
          data  Ura(1, 662)/ 672.000/,Ura(2, 662)/  69.180/
          data  Ura(1, 663)/ 673.000/,Ura(2, 663)/  69.153/
          data  Ura(1, 664)/ 674.000/,Ura(2, 664)/  69.125/
          data  Ura(1, 665)/ 675.000/,Ura(2, 665)/  69.098/
          data  Ura(1, 666)/ 676.000/,Ura(2, 666)/  69.070/
          data  Ura(1, 667)/ 677.000/,Ura(2, 667)/  69.042/
          data  Ura(1, 668)/ 678.000/,Ura(2, 668)/  69.014/
          data  Ura(1, 669)/ 679.000/,Ura(2, 669)/  68.985/
          data  Ura(1, 670)/ 680.000/,Ura(2, 670)/  68.957/
          data  Ura(1, 671)/ 681.000/,Ura(2, 671)/  68.927/
          data  Ura(1, 672)/ 682.000/,Ura(2, 672)/  68.897/
          data  Ura(1, 673)/ 683.000/,Ura(2, 673)/  68.867/
          data  Ura(1, 674)/ 684.000/,Ura(2, 674)/  68.835/
          data  Ura(1, 675)/ 685.000/,Ura(2, 675)/  68.802/
          data  Ura(1, 676)/ 686.000/,Ura(2, 676)/  68.767/
          data  Ura(1, 677)/ 687.000/,Ura(2, 677)/  68.730/
          data  Ura(1, 678)/ 688.000/,Ura(2, 678)/  68.689/
          data  Ura(1, 679)/ 689.000/,Ura(2, 679)/  68.643/
          data  Ura(1, 680)/ 690.000/,Ura(2, 680)/  68.590/
          data  Ura(1, 681)/ 691.000/,Ura(2, 681)/  68.525/
          data  Ura(1, 682)/ 692.000/,Ura(2, 682)/  68.443/
          data  Ura(1, 683)/ 693.000/,Ura(2, 683)/  68.330/
          data  Ura(1, 684)/ 694.000/,Ura(2, 684)/  68.163/
          data  Ura(1, 685)/ 695.000/,Ura(2, 685)/  67.889/
          data  Ura(1, 686)/ 696.000/,Ura(2, 686)/  67.375/
          data  Ura(1, 687)/ 697.000/,Ura(2, 687)/  66.171/
          data  Ura(1, 688)/ 698.000/,Ura(2, 688)/  64.698/
          data  Ura(1, 689)/ 699.000/,Ura(2, 689)/  66.858/
          data  Ura(1, 690)/ 700.000/,Ura(2, 690)/  67.574/
          data  Ura(1, 691)/ 701.000/,Ura(2, 691)/  67.895/
          data  Ura(1, 692)/ 702.000/,Ura(2, 692)/  68.057/
          data  Ura(1, 693)/ 703.000/,Ura(2, 693)/  68.144/
          data  Ura(1, 694)/ 704.000/,Ura(2, 694)/  68.190/
          data  Ura(1, 695)/ 705.000/,Ura(2, 695)/  68.214/
          data  Ura(1, 696)/ 706.000/,Ura(2, 696)/  68.223/
          data  Ura(1, 697)/ 707.000/,Ura(2, 697)/  68.223/
          data  Ura(1, 698)/ 708.000/,Ura(2, 698)/  68.217/
          data  Ura(1, 699)/ 709.000/,Ura(2, 699)/  68.207/
          data  Ura(1, 700)/ 710.000/,Ura(2, 700)/  68.194/
          data  Ura(1, 701)/ 711.000/,Ura(2, 701)/  68.179/
          data  Ura(1, 702)/ 712.000/,Ura(2, 702)/  68.163/
          data  Ura(1, 703)/ 713.000/,Ura(2, 703)/  68.145/
          data  Ura(1, 704)/ 714.000/,Ura(2, 704)/  68.126/
          data  Ura(1, 705)/ 715.000/,Ura(2, 705)/  68.107/
          data  Ura(1, 706)/ 716.000/,Ura(2, 706)/  68.087/
          data  Ura(1, 707)/ 717.000/,Ura(2, 707)/  68.067/
          data  Ura(1, 708)/ 718.000/,Ura(2, 708)/  68.046/
          data  Ura(1, 709)/ 719.000/,Ura(2, 709)/  68.026/
          data  Ura(1, 710)/ 720.000/,Ura(2, 710)/  68.005/
          data  Ura(1, 711)/ 721.000/,Ura(2, 711)/  67.984/
          data  Ura(1, 712)/ 722.000/,Ura(2, 712)/  67.962/
          data  Ura(1, 713)/ 723.000/,Ura(2, 713)/  67.941/
          data  Ura(1, 714)/ 724.000/,Ura(2, 714)/  67.919/
          data  Ura(1, 715)/ 725.000/,Ura(2, 715)/  67.898/
          data  Ura(1, 716)/ 726.000/,Ura(2, 716)/  67.877/
          data  Ura(1, 717)/ 727.000/,Ura(2, 717)/  67.855/
          data  Ura(1, 718)/ 728.000/,Ura(2, 718)/  67.833/
          data  Ura(1, 719)/ 729.000/,Ura(2, 719)/  67.812/
          data  Ura(1, 720)/ 730.000/,Ura(2, 720)/  67.790/
          data  Ura(1, 721)/ 731.000/,Ura(2, 721)/  67.769/
          data  Ura(1, 722)/ 732.000/,Ura(2, 722)/  67.747/
          data  Ura(1, 723)/ 733.000/,Ura(2, 723)/  67.726/
          data  Ura(1, 724)/ 734.000/,Ura(2, 724)/  67.705/
          data  Ura(1, 725)/ 735.000/,Ura(2, 725)/  67.683/
          data  Ura(1, 726)/ 736.000/,Ura(2, 726)/  67.662/
          data  Ura(1, 727)/ 737.000/,Ura(2, 727)/  67.641/
          data  Ura(1, 728)/ 738.000/,Ura(2, 728)/  67.619/
          data  Ura(1, 729)/ 739.000/,Ura(2, 729)/  67.598/
          data  Ura(1, 730)/ 740.000/,Ura(2, 730)/  67.577/
          data  Ura(1, 731)/ 741.000/,Ura(2, 731)/  67.556/
          data  Ura(1, 732)/ 742.000/,Ura(2, 732)/  67.534/
          data  Ura(1, 733)/ 743.000/,Ura(2, 733)/  67.514/
          data  Ura(1, 734)/ 744.000/,Ura(2, 734)/  67.493/
          data  Ura(1, 735)/ 745.000/,Ura(2, 735)/  67.472/
          data  Ura(1, 736)/ 746.000/,Ura(2, 736)/  67.451/
          data  Ura(1, 737)/ 747.000/,Ura(2, 737)/  67.430/
          data  Ura(1, 738)/ 748.000/,Ura(2, 738)/  67.409/
          data  Ura(1, 739)/ 749.000/,Ura(2, 739)/  67.388/
          data  Ura(1, 740)/ 750.000/,Ura(2, 740)/  67.367/
          data  Ura(1, 741)/ 751.000/,Ura(2, 741)/  67.347/
          data  Ura(1, 742)/ 752.000/,Ura(2, 742)/  67.326/
          data  Ura(1, 743)/ 753.000/,Ura(2, 743)/  67.305/
          data  Ura(1, 744)/ 754.000/,Ura(2, 744)/  67.285/
          data  Ura(1, 745)/ 755.000/,Ura(2, 745)/  67.265/
          data  Ura(1, 746)/ 756.000/,Ura(2, 746)/  67.244/
          data  Ura(1, 747)/ 757.000/,Ura(2, 747)/  67.224/
          data  Ura(1, 748)/ 758.000/,Ura(2, 748)/  67.204/
          data  Ura(1, 749)/ 759.000/,Ura(2, 749)/  67.184/
          data  Ura(1, 750)/ 760.000/,Ura(2, 750)/  67.163/
          data  Ura(1, 751)/ 761.000/,Ura(2, 751)/  67.143/
          data  Ura(1, 752)/ 762.000/,Ura(2, 752)/  67.123/
          data  Ura(1, 753)/ 763.000/,Ura(2, 753)/  67.103/
          data  Ura(1, 754)/ 764.000/,Ura(2, 754)/  67.083/
          data  Ura(1, 755)/ 765.000/,Ura(2, 755)/  67.063/
          data  Ura(1, 756)/ 766.000/,Ura(2, 756)/  67.043/
          data  Ura(1, 757)/ 767.000/,Ura(2, 757)/  67.023/
          data  Ura(1, 758)/ 768.000/,Ura(2, 758)/  67.004/
          data  Ura(1, 759)/ 769.000/,Ura(2, 759)/  66.984/
          data  Ura(1, 760)/ 770.000/,Ura(2, 760)/  66.965/
          data  Ura(1, 761)/ 771.000/,Ura(2, 761)/  66.945/
          data  Ura(1, 762)/ 772.000/,Ura(2, 762)/  66.926/
          data  Ura(1, 763)/ 773.000/,Ura(2, 763)/  66.906/
          data  Ura(1, 764)/ 774.000/,Ura(2, 764)/  66.887/
          data  Ura(1, 765)/ 775.000/,Ura(2, 765)/  66.867/
          data  Ura(1, 766)/ 776.000/,Ura(2, 766)/  66.848/
          data  Ura(1, 767)/ 777.000/,Ura(2, 767)/  66.829/
          data  Ura(1, 768)/ 778.000/,Ura(2, 768)/  66.810/
          data  Ura(1, 769)/ 779.000/,Ura(2, 769)/  66.790/
          data  Ura(1, 770)/ 780.000/,Ura(2, 770)/  66.771/
          data  Ura(1, 771)/ 781.000/,Ura(2, 771)/  66.752/
          data  Ura(1, 772)/ 782.000/,Ura(2, 772)/  66.733/
          data  Ura(1, 773)/ 783.000/,Ura(2, 773)/  66.714/
          data  Ura(1, 774)/ 784.000/,Ura(2, 774)/  66.695/
          data  Ura(1, 775)/ 785.000/,Ura(2, 775)/  66.677/
          data  Ura(1, 776)/ 786.000/,Ura(2, 776)/  66.658/
          data  Ura(1, 777)/ 787.000/,Ura(2, 777)/  66.639/
          data  Ura(1, 778)/ 788.000/,Ura(2, 778)/  66.620/
          data  Ura(1, 779)/ 789.000/,Ura(2, 779)/  66.602/
          data  Ura(1, 780)/ 790.000/,Ura(2, 780)/  66.583/
          data  Ura(1, 781)/ 791.000/,Ura(2, 781)/  66.565/
          data  Ura(1, 782)/ 792.000/,Ura(2, 782)/  66.546/
          data  Ura(1, 783)/ 793.000/,Ura(2, 783)/  66.528/
          data  Ura(1, 784)/ 794.000/,Ura(2, 784)/  66.509/
          data  Ura(1, 785)/ 795.000/,Ura(2, 785)/  66.491/
          data  Ura(1, 786)/ 796.000/,Ura(2, 786)/  66.473/
          data  Ura(1, 787)/ 797.000/,Ura(2, 787)/  66.454/
          data  Ura(1, 788)/ 798.000/,Ura(2, 788)/  66.436/
          data  Ura(1, 789)/ 799.000/,Ura(2, 789)/  66.418/
          data  Ura(1, 790)/ 800.000/,Ura(2, 790)/  66.400/
          data  Ura(1, 791)/ 801.000/,Ura(2, 791)/  66.382/
          data  Ura(1, 792)/ 802.000/,Ura(2, 792)/  66.364/
          data  Ura(1, 793)/ 803.000/,Ura(2, 793)/  66.346/
          data  Ura(1, 794)/ 804.000/,Ura(2, 794)/  66.328/
          data  Ura(1, 795)/ 805.000/,Ura(2, 795)/  66.311/
          data  Ura(1, 796)/ 806.000/,Ura(2, 796)/  66.293/
          data  Ura(1, 797)/ 807.000/,Ura(2, 797)/  66.275/
          data  Ura(1, 798)/ 808.000/,Ura(2, 798)/  66.257/
          data  Ura(1, 799)/ 809.000/,Ura(2, 799)/  66.240/
          data  Ura(1, 800)/ 810.000/,Ura(2, 800)/  66.222/
          data  Ura(1, 801)/ 811.000/,Ura(2, 801)/  66.204/
          data  Ura(1, 802)/ 812.000/,Ura(2, 802)/  66.187/
          data  Ura(1, 803)/ 813.000/,Ura(2, 803)/  66.170/
          data  Ura(1, 804)/ 814.000/,Ura(2, 804)/  66.152/
          data  Ura(1, 805)/ 815.000/,Ura(2, 805)/  66.135/
          data  Ura(1, 806)/ 816.000/,Ura(2, 806)/  66.118/
          data  Ura(1, 807)/ 817.000/,Ura(2, 807)/  66.100/
          data  Ura(1, 808)/ 818.000/,Ura(2, 808)/  66.083/
          data  Ura(1, 809)/ 819.000/,Ura(2, 809)/  66.066/
          data  Ura(1, 810)/ 820.000/,Ura(2, 810)/  66.049/
          data  Ura(1, 811)/ 821.000/,Ura(2, 811)/  66.032/
          data  Ura(1, 812)/ 822.000/,Ura(2, 812)/  66.015/
          data  Ura(1, 813)/ 823.000/,Ura(2, 813)/  65.998/
          data  Ura(1, 814)/ 824.000/,Ura(2, 814)/  65.981/
          data  Ura(1, 815)/ 825.000/,Ura(2, 815)/  65.964/
          data  Ura(1, 816)/ 826.000/,Ura(2, 816)/  65.947/
          data  Ura(1, 817)/ 827.000/,Ura(2, 817)/  65.930/
          data  Ura(1, 818)/ 828.000/,Ura(2, 818)/  65.913/
          data  Ura(1, 819)/ 829.000/,Ura(2, 819)/  65.897/
          data  Ura(1, 820)/ 830.000/,Ura(2, 820)/  65.880/
          data  Ura(1, 821)/ 831.000/,Ura(2, 821)/  65.863/
          data  Ura(1, 822)/ 832.000/,Ura(2, 822)/  65.847/
          data  Ura(1, 823)/ 833.000/,Ura(2, 823)/  65.830/
          data  Ura(1, 824)/ 834.000/,Ura(2, 824)/  65.814/
          data  Ura(1, 825)/ 835.000/,Ura(2, 825)/  65.797/
          data  Ura(1, 826)/ 836.000/,Ura(2, 826)/  65.781/
          data  Ura(1, 827)/ 837.000/,Ura(2, 827)/  65.764/
          data  Ura(1, 828)/ 838.000/,Ura(2, 828)/  65.748/
          data  Ura(1, 829)/ 839.000/,Ura(2, 829)/  65.732/
          data  Ura(1, 830)/ 840.000/,Ura(2, 830)/  65.716/
          data  Ura(1, 831)/ 841.000/,Ura(2, 831)/  65.699/
          data  Ura(1, 832)/ 842.000/,Ura(2, 832)/  65.683/
          data  Ura(1, 833)/ 843.000/,Ura(2, 833)/  65.667/
          data  Ura(1, 834)/ 844.000/,Ura(2, 834)/  65.651/
          data  Ura(1, 835)/ 845.000/,Ura(2, 835)/  65.635/
          data  Ura(1, 836)/ 846.000/,Ura(2, 836)/  65.619/
          data  Ura(1, 837)/ 847.000/,Ura(2, 837)/  65.603/
          data  Ura(1, 838)/ 848.000/,Ura(2, 838)/  65.587/
          data  Ura(1, 839)/ 849.000/,Ura(2, 839)/  65.571/
          data  Ura(1, 840)/ 850.000/,Ura(2, 840)/  65.555/
          data  Ura(1, 841)/ 851.000/,Ura(2, 841)/  65.540/
          data  Ura(1, 842)/ 852.000/,Ura(2, 842)/  65.524/
          data  Ura(1, 843)/ 853.000/,Ura(2, 843)/  65.508/
          data  Ura(1, 844)/ 854.000/,Ura(2, 844)/  65.493/
          data  Ura(1, 845)/ 855.000/,Ura(2, 845)/  65.477/
          data  Ura(1, 846)/ 856.000/,Ura(2, 846)/  65.461/
          data  Ura(1, 847)/ 857.000/,Ura(2, 847)/  65.446/
          data  Ura(1, 848)/ 858.000/,Ura(2, 848)/  65.430/
          data  Ura(1, 849)/ 859.000/,Ura(2, 849)/  65.415/
          data  Ura(1, 850)/ 860.000/,Ura(2, 850)/  65.399/
          data  Ura(1, 851)/ 861.000/,Ura(2, 851)/  65.384/
          data  Ura(1, 852)/ 862.000/,Ura(2, 852)/  65.369/
          data  Ura(1, 853)/ 863.000/,Ura(2, 853)/  65.353/
          data  Ura(1, 854)/ 864.000/,Ura(2, 854)/  65.338/
          data  Ura(1, 855)/ 865.000/,Ura(2, 855)/  65.323/
          data  Ura(1, 856)/ 866.000/,Ura(2, 856)/  65.307/
          data  Ura(1, 857)/ 867.000/,Ura(2, 857)/  65.292/
          data  Ura(1, 858)/ 868.000/,Ura(2, 858)/  65.277/
          data  Ura(1, 859)/ 869.000/,Ura(2, 859)/  65.262/
          data  Ura(1, 860)/ 870.000/,Ura(2, 860)/  65.247/
          data  Ura(1, 861)/ 871.000/,Ura(2, 861)/  65.232/
          data  Ura(1, 862)/ 872.000/,Ura(2, 862)/  65.217/
          data  Ura(1, 863)/ 873.000/,Ura(2, 863)/  65.202/
          data  Ura(1, 864)/ 874.000/,Ura(2, 864)/  65.187/
          data  Ura(1, 865)/ 875.000/,Ura(2, 865)/  65.172/
          data  Ura(1, 866)/ 876.000/,Ura(2, 866)/  65.157/
          data  Ura(1, 867)/ 877.000/,Ura(2, 867)/  65.142/
          data  Ura(1, 868)/ 878.000/,Ura(2, 868)/  65.128/
          data  Ura(1, 869)/ 879.000/,Ura(2, 869)/  65.113/
          data  Ura(1, 870)/ 880.000/,Ura(2, 870)/  65.098/
          data  Ura(1, 871)/ 881.000/,Ura(2, 871)/  65.083/
          data  Ura(1, 872)/ 882.000/,Ura(2, 872)/  65.069/
          data  Ura(1, 873)/ 883.000/,Ura(2, 873)/  65.054/
          data  Ura(1, 874)/ 884.000/,Ura(2, 874)/  65.039/
          data  Ura(1, 875)/ 885.000/,Ura(2, 875)/  65.024/
          data  Ura(1, 876)/ 886.000/,Ura(2, 876)/  65.010/
          data  Ura(1, 877)/ 887.000/,Ura(2, 877)/  64.995/
          data  Ura(1, 878)/ 888.000/,Ura(2, 878)/  64.981/
          data  Ura(1, 879)/ 889.000/,Ura(2, 879)/  64.966/
          data  Ura(1, 880)/ 890.000/,Ura(2, 880)/  64.952/
          data  Ura(1, 881)/ 891.000/,Ura(2, 881)/  64.937/
          data  Ura(1, 882)/ 892.000/,Ura(2, 882)/  64.923/
          data  Ura(1, 883)/ 893.000/,Ura(2, 883)/  64.908/
          data  Ura(1, 884)/ 894.000/,Ura(2, 884)/  64.894/
          data  Ura(1, 885)/ 895.000/,Ura(2, 885)/  64.879/
          data  Ura(1, 886)/ 896.000/,Ura(2, 886)/  64.865/
          data  Ura(1, 887)/ 897.000/,Ura(2, 887)/  64.850/
          data  Ura(1, 888)/ 898.000/,Ura(2, 888)/  64.836/
          data  Ura(1, 889)/ 899.000/,Ura(2, 889)/  64.821/
          data  Ura(1, 890)/ 900.000/,Ura(2, 890)/  64.807/
          data  Ura(1, 891)/ 901.000/,Ura(2, 891)/  64.792/
          data  Ura(1, 892)/ 902.000/,Ura(2, 892)/  64.777/
          data  Ura(1, 893)/ 903.000/,Ura(2, 893)/  64.763/
          data  Ura(1, 894)/ 904.000/,Ura(2, 894)/  64.748/
          data  Ura(1, 895)/ 905.000/,Ura(2, 895)/  64.733/
          data  Ura(1, 896)/ 906.000/,Ura(2, 896)/  64.718/
          data  Ura(1, 897)/ 907.000/,Ura(2, 897)/  64.703/
          data  Ura(1, 898)/ 908.000/,Ura(2, 898)/  64.688/
          data  Ura(1, 899)/ 909.000/,Ura(2, 899)/  64.672/
          data  Ura(1, 900)/ 910.000/,Ura(2, 900)/  64.657/
          data  Ura(1, 901)/ 911.000/,Ura(2, 901)/  64.641/
          data  Ura(1, 902)/ 912.000/,Ura(2, 902)/  64.624/
          data  Ura(1, 903)/ 913.000/,Ura(2, 903)/  64.607/
          data  Ura(1, 904)/ 914.000/,Ura(2, 904)/  64.590/
          data  Ura(1, 905)/ 915.000/,Ura(2, 905)/  64.571/
          data  Ura(1, 906)/ 916.000/,Ura(2, 906)/  64.552/
          data  Ura(1, 907)/ 917.000/,Ura(2, 907)/  64.532/
          data  Ura(1, 908)/ 918.000/,Ura(2, 908)/  64.510/
          data  Ura(1, 909)/ 919.000/,Ura(2, 909)/  64.485/
          data  Ura(1, 910)/ 920.000/,Ura(2, 910)/  64.457/
          data  Ura(1, 911)/ 921.000/,Ura(2, 911)/  64.425/
          data  Ura(1, 912)/ 922.000/,Ura(2, 912)/  64.386/
          data  Ura(1, 913)/ 923.000/,Ura(2, 913)/  64.337/
          data  Ura(1, 914)/ 924.000/,Ura(2, 914)/  64.272/
          data  Ura(1, 915)/ 925.000/,Ura(2, 915)/  64.182/
          data  Ura(1, 916)/ 926.000/,Ura(2, 916)/  64.044/
          data  Ura(1, 917)/ 927.000/,Ura(2, 917)/  63.818/
          data  Ura(1, 918)/ 928.000/,Ura(2, 918)/  63.401/
          data  Ura(1, 919)/ 929.000/,Ura(2, 919)/  62.499/
          data  Ura(1, 920)/ 930.000/,Ura(2, 920)/  60.512/
          data  Ura(1, 921)/ 931.000/,Ura(2, 921)/  62.138/
          data  Ura(1, 922)/ 932.000/,Ura(2, 922)/  63.220/
          data  Ura(1, 923)/ 933.000/,Ura(2, 923)/  63.681/
          data  Ura(1, 924)/ 934.000/,Ura(2, 924)/  63.911/
          data  Ura(1, 925)/ 935.000/,Ura(2, 925)/  64.037/
          data  Ura(1, 926)/ 936.000/,Ura(2, 926)/  64.109/
          data  Ura(1, 927)/ 937.000/,Ura(2, 927)/  64.153/
          data  Ura(1, 928)/ 938.000/,Ura(2, 928)/  64.178/
          data  Ura(1, 929)/ 939.000/,Ura(2, 929)/  64.193/
          data  Ura(1, 930)/ 940.000/,Ura(2, 930)/  64.200/
          data  Ura(1, 931)/ 941.000/,Ura(2, 931)/  64.203/
          data  Ura(1, 932)/ 942.000/,Ura(2, 932)/  64.202/
          data  Ura(1, 933)/ 943.000/,Ura(2, 933)/  64.199/
          data  Ura(1, 934)/ 944.000/,Ura(2, 934)/  64.194/
          data  Ura(1, 935)/ 945.000/,Ura(2, 935)/  64.187/
          data  Ura(1, 936)/ 946.000/,Ura(2, 936)/  64.180/
          data  Ura(1, 937)/ 947.000/,Ura(2, 937)/  64.171/
          data  Ura(1, 938)/ 948.000/,Ura(2, 938)/  64.162/
          data  Ura(1, 939)/ 949.000/,Ura(2, 939)/  64.153/
          data  Ura(1, 940)/ 950.000/,Ura(2, 940)/  64.143/
          data  Ura(1, 941)/ 951.000/,Ura(2, 941)/  64.133/
          data  Ura(1, 942)/ 952.000/,Ura(2, 942)/  64.123/
          data  Ura(1, 943)/ 953.000/,Ura(2, 943)/  64.112/
          data  Ura(1, 944)/ 954.000/,Ura(2, 944)/  64.102/
          data  Ura(1, 945)/ 955.000/,Ura(2, 945)/  64.091/
          data  Ura(1, 946)/ 956.000/,Ura(2, 946)/  64.080/
          data  Ura(1, 947)/ 957.000/,Ura(2, 947)/  64.069/
          data  Ura(1, 948)/ 958.000/,Ura(2, 948)/  64.058/
          data  Ura(1, 949)/ 959.000/,Ura(2, 949)/  64.046/
          data  Ura(1, 950)/ 960.000/,Ura(2, 950)/  64.035/
          data  Ura(1, 951)/ 961.000/,Ura(2, 951)/  64.024/
          data  Ura(1, 952)/ 962.000/,Ura(2, 952)/  64.013/
          data  Ura(1, 953)/ 963.000/,Ura(2, 953)/  64.001/
          data  Ura(1, 954)/ 964.000/,Ura(2, 954)/  63.990/
          data  Ura(1, 955)/ 965.000/,Ura(2, 955)/  63.978/
          data  Ura(1, 956)/ 966.000/,Ura(2, 956)/  63.967/
          data  Ura(1, 957)/ 967.000/,Ura(2, 957)/  63.956/
          data  Ura(1, 958)/ 968.000/,Ura(2, 958)/  63.944/
          data  Ura(1, 959)/ 969.000/,Ura(2, 959)/  63.933/
          data  Ura(1, 960)/ 970.000/,Ura(2, 960)/  63.921/
          data  Ura(1, 961)/ 971.000/,Ura(2, 961)/  63.910/
          data  Ura(1, 962)/ 972.000/,Ura(2, 962)/  63.899/
          data  Ura(1, 963)/ 973.000/,Ura(2, 963)/  63.887/
          data  Ura(1, 964)/ 974.000/,Ura(2, 964)/  63.876/
          data  Ura(1, 965)/ 975.000/,Ura(2, 965)/  63.865/
          data  Ura(1, 966)/ 976.000/,Ura(2, 966)/  63.853/
          data  Ura(1, 967)/ 977.000/,Ura(2, 967)/  63.842/
          data  Ura(1, 968)/ 978.000/,Ura(2, 968)/  63.831/
          data  Ura(1, 969)/ 979.000/,Ura(2, 969)/  63.819/
          data  Ura(1, 970)/ 980.000/,Ura(2, 970)/  63.808/
          data  Ura(1, 971)/ 981.000/,Ura(2, 971)/  63.797/
          data  Ura(1, 972)/ 982.000/,Ura(2, 972)/  63.785/
          data  Ura(1, 973)/ 983.000/,Ura(2, 973)/  63.774/
          data  Ura(1, 974)/ 984.000/,Ura(2, 974)/  63.763/
          data  Ura(1, 975)/ 985.000/,Ura(2, 975)/  63.752/
          data  Ura(1, 976)/ 986.000/,Ura(2, 976)/  63.741/
          data  Ura(1, 977)/ 987.000/,Ura(2, 977)/  63.729/
          data  Ura(1, 978)/ 988.000/,Ura(2, 978)/  63.718/
          data  Ura(1, 979)/ 989.000/,Ura(2, 979)/  63.707/
          data  Ura(1, 980)/ 990.000/,Ura(2, 980)/  63.696/
          data  Ura(1, 981)/ 991.000/,Ura(2, 981)/  63.685/
          data  Ura(1, 982)/ 992.000/,Ura(2, 982)/  63.674/
          data  Ura(1, 983)/ 993.000/,Ura(2, 983)/  63.663/
          data  Ura(1, 984)/ 994.000/,Ura(2, 984)/  63.652/
          data  Ura(1, 985)/ 995.000/,Ura(2, 985)/  63.641/
          data  Ura(1, 986)/ 996.000/,Ura(2, 986)/  63.630/
          data  Ura(1, 987)/ 997.000/,Ura(2, 987)/  63.620/
          data  Ura(1, 988)/ 998.000/,Ura(2, 988)/  63.609/
          data  Ura(1, 989)/ 999.000/,Ura(2, 989)/  63.598/
          data  Ura(1, 990)/1000.000/,Ura(2, 990)/  63.587/
c++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c!Neptune model - from Eric Weisstein's JOVIAN
c!H2 type: equillibrium
c!H2 form: D&B
c!He form: B&G
c!H2 mxr: 0.81
c!CO mxr: 6.e-7
c!HCN mxr: 0.
c!                               Freq(GHz)    WDTB(Kelvin) 
          data  Nep(1,   1)/  11.000/,Nep(2,   1)/ 147.947/
          data  Nep(1,   2)/  12.000/,Nep(2,   2)/ 146.803/
          data  Nep(1,   3)/  13.000/,Nep(2,   3)/ 145.745/
          data  Nep(1,   4)/  14.000/,Nep(2,   4)/ 144.759/
          data  Nep(1,   5)/  15.000/,Nep(2,   5)/ 143.836/
          data  Nep(1,   6)/  16.000/,Nep(2,   6)/ 142.969/
          data  Nep(1,   7)/  17.000/,Nep(2,   7)/ 142.153/
          data  Nep(1,   8)/  18.000/,Nep(2,   8)/ 141.385/
          data  Nep(1,   9)/  19.000/,Nep(2,   9)/ 140.662/
          data  Nep(1,  10)/  20.000/,Nep(2,  10)/ 139.982/
          data  Nep(1,  11)/  21.000/,Nep(2,  11)/ 139.346/
          data  Nep(1,  12)/  22.000/,Nep(2,  12)/ 138.752/
          data  Nep(1,  13)/  23.000/,Nep(2,  13)/ 138.200/
          data  Nep(1,  14)/  24.000/,Nep(2,  14)/ 137.689/
          data  Nep(1,  15)/  25.000/,Nep(2,  15)/ 137.219/
          data  Nep(1,  16)/  26.000/,Nep(2,  16)/ 136.788/
          data  Nep(1,  17)/  27.000/,Nep(2,  17)/ 136.395/
          data  Nep(1,  18)/  28.000/,Nep(2,  18)/ 136.038/
          data  Nep(1,  19)/  29.000/,Nep(2,  19)/ 135.713/
          data  Nep(1,  20)/  30.000/,Nep(2,  20)/ 135.420/
          data  Nep(1,  21)/  31.000/,Nep(2,  21)/ 135.153/
          data  Nep(1,  22)/  32.000/,Nep(2,  22)/ 134.912/
          data  Nep(1,  23)/  33.000/,Nep(2,  23)/ 134.692/
          data  Nep(1,  24)/  34.000/,Nep(2,  24)/ 134.491/
          data  Nep(1,  25)/  35.000/,Nep(2,  25)/ 134.306/
          data  Nep(1,  26)/  36.000/,Nep(2,  26)/ 134.136/
          data  Nep(1,  27)/  37.000/,Nep(2,  27)/ 133.976/
          data  Nep(1,  28)/  38.000/,Nep(2,  28)/ 133.826/
          data  Nep(1,  29)/  39.000/,Nep(2,  29)/ 133.685/
          data  Nep(1,  30)/  40.000/,Nep(2,  30)/ 133.549/
          data  Nep(1,  31)/  41.000/,Nep(2,  31)/ 133.419/
          data  Nep(1,  32)/  42.000/,Nep(2,  32)/ 133.292/
          data  Nep(1,  33)/  43.000/,Nep(2,  33)/ 133.168/
          data  Nep(1,  34)/  44.000/,Nep(2,  34)/ 133.046/
          data  Nep(1,  35)/  45.000/,Nep(2,  35)/ 132.924/
          data  Nep(1,  36)/  46.000/,Nep(2,  36)/ 132.804/
          data  Nep(1,  37)/  47.000/,Nep(2,  37)/ 132.683/
          data  Nep(1,  38)/  48.000/,Nep(2,  38)/ 132.562/
          data  Nep(1,  39)/  49.000/,Nep(2,  39)/ 132.440/
          data  Nep(1,  40)/  50.000/,Nep(2,  40)/ 132.317/
          data  Nep(1,  41)/  51.000/,Nep(2,  41)/ 132.193/
          data  Nep(1,  42)/  52.000/,Nep(2,  42)/ 132.066/
          data  Nep(1,  43)/  53.000/,Nep(2,  43)/ 131.938/
          data  Nep(1,  44)/  54.000/,Nep(2,  44)/ 131.807/
          data  Nep(1,  45)/  55.000/,Nep(2,  45)/ 131.675/
          data  Nep(1,  46)/  56.000/,Nep(2,  46)/ 131.540/
          data  Nep(1,  47)/  57.000/,Nep(2,  47)/ 131.403/
          data  Nep(1,  48)/  58.000/,Nep(2,  48)/ 131.264/
          data  Nep(1,  49)/  59.000/,Nep(2,  49)/ 131.122/
          data  Nep(1,  50)/  60.000/,Nep(2,  50)/ 130.978/
          data  Nep(1,  51)/  61.000/,Nep(2,  51)/ 130.831/
          data  Nep(1,  52)/  62.000/,Nep(2,  52)/ 130.682/
          data  Nep(1,  53)/  63.000/,Nep(2,  53)/ 130.531/
          data  Nep(1,  54)/  64.000/,Nep(2,  54)/ 130.377/
          data  Nep(1,  55)/  65.000/,Nep(2,  55)/ 130.220/
          data  Nep(1,  56)/  66.000/,Nep(2,  56)/ 130.062/
          data  Nep(1,  57)/  67.000/,Nep(2,  57)/ 129.901/
          data  Nep(1,  58)/  68.000/,Nep(2,  58)/ 129.737/
          data  Nep(1,  59)/  69.000/,Nep(2,  59)/ 129.572/
          data  Nep(1,  60)/  70.000/,Nep(2,  60)/ 129.404/
          data  Nep(1,  61)/  71.000/,Nep(2,  61)/ 129.233/
          data  Nep(1,  62)/  72.000/,Nep(2,  62)/ 129.061/
          data  Nep(1,  63)/  73.000/,Nep(2,  63)/ 128.887/
          data  Nep(1,  64)/  74.000/,Nep(2,  64)/ 128.710/
          data  Nep(1,  65)/  75.000/,Nep(2,  65)/ 128.531/
          data  Nep(1,  66)/  76.000/,Nep(2,  66)/ 128.350/
          data  Nep(1,  67)/  77.000/,Nep(2,  67)/ 128.168/
          data  Nep(1,  68)/  78.000/,Nep(2,  68)/ 127.983/
          data  Nep(1,  69)/  79.000/,Nep(2,  69)/ 127.796/
          data  Nep(1,  70)/  80.000/,Nep(2,  70)/ 127.607/
          data  Nep(1,  71)/  81.000/,Nep(2,  71)/ 127.416/
          data  Nep(1,  72)/  82.000/,Nep(2,  72)/ 127.224/
          data  Nep(1,  73)/  83.000/,Nep(2,  73)/ 127.029/
          data  Nep(1,  74)/  84.000/,Nep(2,  74)/ 126.833/
          data  Nep(1,  75)/  85.000/,Nep(2,  75)/ 126.634/
          data  Nep(1,  76)/  86.000/,Nep(2,  76)/ 126.434/
          data  Nep(1,  77)/  87.000/,Nep(2,  77)/ 126.232/
          data  Nep(1,  78)/  88.000/,Nep(2,  78)/ 126.028/
          data  Nep(1,  79)/  89.000/,Nep(2,  79)/ 125.822/
          data  Nep(1,  80)/  90.000/,Nep(2,  80)/ 125.614/
          data  Nep(1,  81)/  91.000/,Nep(2,  81)/ 125.404/
          data  Nep(1,  82)/  92.000/,Nep(2,  82)/ 125.191/
          data  Nep(1,  83)/  93.000/,Nep(2,  83)/ 124.976/
          data  Nep(1,  84)/  94.000/,Nep(2,  84)/ 124.759/
          data  Nep(1,  85)/  95.000/,Nep(2,  85)/ 124.539/
          data  Nep(1,  86)/  96.000/,Nep(2,  86)/ 124.317/
          data  Nep(1,  87)/  97.000/,Nep(2,  87)/ 124.091/
          data  Nep(1,  88)/  98.000/,Nep(2,  88)/ 123.861/
          data  Nep(1,  89)/  99.000/,Nep(2,  89)/ 123.628/
          data  Nep(1,  90)/ 100.000/,Nep(2,  90)/ 123.389/
          data  Nep(1,  91)/ 101.000/,Nep(2,  91)/ 123.145/
          data  Nep(1,  92)/ 102.000/,Nep(2,  92)/ 122.895/
          data  Nep(1,  93)/ 103.000/,Nep(2,  93)/ 122.636/
          data  Nep(1,  94)/ 104.000/,Nep(2,  94)/ 122.367/
          data  Nep(1,  95)/ 105.000/,Nep(2,  95)/ 122.085/
          data  Nep(1,  96)/ 106.000/,Nep(2,  96)/ 121.786/
          data  Nep(1,  97)/ 107.000/,Nep(2,  97)/ 121.466/
          data  Nep(1,  98)/ 108.000/,Nep(2,  98)/ 121.115/
          data  Nep(1,  99)/ 109.000/,Nep(2,  99)/ 120.722/
          data  Nep(1, 100)/ 110.000/,Nep(2, 100)/ 120.267/
          data  Nep(1, 101)/ 111.000/,Nep(2, 101)/ 119.716/
          data  Nep(1, 102)/ 112.000/,Nep(2, 102)/ 119.010/
          data  Nep(1, 103)/ 113.000/,Nep(2, 103)/ 118.019/
          data  Nep(1, 104)/ 114.000/,Nep(2, 104)/ 116.414/
          data  Nep(1, 105)/ 115.000/,Nep(2, 105)/ 112.539/
          data  Nep(1, 106)/ 116.000/,Nep(2, 106)/ 114.625/
          data  Nep(1, 107)/ 117.000/,Nep(2, 107)/ 116.564/
          data  Nep(1, 108)/ 118.000/,Nep(2, 108)/ 117.390/
          data  Nep(1, 109)/ 119.000/,Nep(2, 109)/ 117.794/
          data  Nep(1, 110)/ 120.000/,Nep(2, 110)/ 117.983/
          data  Nep(1, 111)/ 121.000/,Nep(2, 111)/ 118.048/
          data  Nep(1, 112)/ 122.000/,Nep(2, 112)/ 118.034/
          data  Nep(1, 113)/ 123.000/,Nep(2, 113)/ 117.968/
          data  Nep(1, 114)/ 124.000/,Nep(2, 114)/ 117.867/
          data  Nep(1, 115)/ 125.000/,Nep(2, 115)/ 117.739/
          data  Nep(1, 116)/ 126.000/,Nep(2, 116)/ 117.593/
          data  Nep(1, 117)/ 127.000/,Nep(2, 117)/ 117.432/
          data  Nep(1, 118)/ 128.000/,Nep(2, 118)/ 117.261/
          data  Nep(1, 119)/ 129.000/,Nep(2, 119)/ 117.081/
          data  Nep(1, 120)/ 130.000/,Nep(2, 120)/ 116.895/
          data  Nep(1, 121)/ 131.000/,Nep(2, 121)/ 116.703/
          data  Nep(1, 122)/ 132.000/,Nep(2, 122)/ 116.508/
          data  Nep(1, 123)/ 133.000/,Nep(2, 123)/ 116.308/
          data  Nep(1, 124)/ 134.000/,Nep(2, 124)/ 116.107/
          data  Nep(1, 125)/ 135.000/,Nep(2, 125)/ 115.902/
          data  Nep(1, 126)/ 136.000/,Nep(2, 126)/ 115.696/
          data  Nep(1, 127)/ 137.000/,Nep(2, 127)/ 115.489/
          data  Nep(1, 128)/ 138.000/,Nep(2, 128)/ 115.280/
          data  Nep(1, 129)/ 139.000/,Nep(2, 129)/ 115.070/
          data  Nep(1, 130)/ 140.000/,Nep(2, 130)/ 114.860/
          data  Nep(1, 131)/ 141.000/,Nep(2, 131)/ 114.648/
          data  Nep(1, 132)/ 142.000/,Nep(2, 132)/ 114.436/
          data  Nep(1, 133)/ 143.000/,Nep(2, 133)/ 114.224/
          data  Nep(1, 134)/ 144.000/,Nep(2, 134)/ 114.011/
          data  Nep(1, 135)/ 145.000/,Nep(2, 135)/ 113.798/
          data  Nep(1, 136)/ 146.000/,Nep(2, 136)/ 113.585/
          data  Nep(1, 137)/ 147.000/,Nep(2, 137)/ 113.372/
          data  Nep(1, 138)/ 148.000/,Nep(2, 138)/ 113.159/
          data  Nep(1, 139)/ 149.000/,Nep(2, 139)/ 112.946/
          data  Nep(1, 140)/ 150.000/,Nep(2, 140)/ 112.733/
          data  Nep(1, 141)/ 151.000/,Nep(2, 141)/ 112.520/
          data  Nep(1, 142)/ 152.000/,Nep(2, 142)/ 112.307/
          data  Nep(1, 143)/ 153.000/,Nep(2, 143)/ 112.095/
          data  Nep(1, 144)/ 154.000/,Nep(2, 144)/ 111.882/
          data  Nep(1, 145)/ 155.000/,Nep(2, 145)/ 111.670/
          data  Nep(1, 146)/ 156.000/,Nep(2, 146)/ 111.458/
          data  Nep(1, 147)/ 157.000/,Nep(2, 147)/ 111.246/
          data  Nep(1, 148)/ 158.000/,Nep(2, 148)/ 111.035/
          data  Nep(1, 149)/ 159.000/,Nep(2, 149)/ 110.824/
          data  Nep(1, 150)/ 160.000/,Nep(2, 150)/ 110.613/
          data  Nep(1, 151)/ 161.000/,Nep(2, 151)/ 110.403/
          data  Nep(1, 152)/ 162.000/,Nep(2, 152)/ 110.193/
          data  Nep(1, 153)/ 163.000/,Nep(2, 153)/ 109.983/
          data  Nep(1, 154)/ 164.000/,Nep(2, 154)/ 109.775/
          data  Nep(1, 155)/ 165.000/,Nep(2, 155)/ 109.566/
          data  Nep(1, 156)/ 166.000/,Nep(2, 156)/ 109.357/
          data  Nep(1, 157)/ 167.000/,Nep(2, 157)/ 109.149/
          data  Nep(1, 158)/ 168.000/,Nep(2, 158)/ 108.942/
          data  Nep(1, 159)/ 169.000/,Nep(2, 159)/ 108.735/
          data  Nep(1, 160)/ 170.000/,Nep(2, 160)/ 108.528/
          data  Nep(1, 161)/ 171.000/,Nep(2, 161)/ 108.322/
          data  Nep(1, 162)/ 172.000/,Nep(2, 162)/ 108.116/
          data  Nep(1, 163)/ 173.000/,Nep(2, 163)/ 107.910/
          data  Nep(1, 164)/ 174.000/,Nep(2, 164)/ 107.706/
          data  Nep(1, 165)/ 175.000/,Nep(2, 165)/ 107.501/
          data  Nep(1, 166)/ 176.000/,Nep(2, 166)/ 107.298/
          data  Nep(1, 167)/ 177.000/,Nep(2, 167)/ 107.094/
          data  Nep(1, 168)/ 178.000/,Nep(2, 168)/ 106.891/
          data  Nep(1, 169)/ 179.000/,Nep(2, 169)/ 106.688/
          data  Nep(1, 170)/ 180.000/,Nep(2, 170)/ 106.486/
          data  Nep(1, 171)/ 181.000/,Nep(2, 171)/ 106.284/
          data  Nep(1, 172)/ 182.000/,Nep(2, 172)/ 106.083/
          data  Nep(1, 173)/ 183.000/,Nep(2, 173)/ 105.882/
          data  Nep(1, 174)/ 184.000/,Nep(2, 174)/ 105.680/
          data  Nep(1, 175)/ 185.000/,Nep(2, 175)/ 105.480/
          data  Nep(1, 176)/ 186.000/,Nep(2, 176)/ 105.280/
          data  Nep(1, 177)/ 187.000/,Nep(2, 177)/ 105.080/
          data  Nep(1, 178)/ 188.000/,Nep(2, 178)/ 104.881/
          data  Nep(1, 179)/ 189.000/,Nep(2, 179)/ 104.681/
          data  Nep(1, 180)/ 190.000/,Nep(2, 180)/ 104.482/
          data  Nep(1, 181)/ 191.000/,Nep(2, 181)/ 104.283/
          data  Nep(1, 182)/ 192.000/,Nep(2, 182)/ 104.084/
          data  Nep(1, 183)/ 193.000/,Nep(2, 183)/ 103.886/
          data  Nep(1, 184)/ 194.000/,Nep(2, 184)/ 103.686/
          data  Nep(1, 185)/ 195.000/,Nep(2, 185)/ 103.487/
          data  Nep(1, 186)/ 196.000/,Nep(2, 186)/ 103.288/
          data  Nep(1, 187)/ 197.000/,Nep(2, 187)/ 103.089/
          data  Nep(1, 188)/ 198.000/,Nep(2, 188)/ 102.889/
          data  Nep(1, 189)/ 199.000/,Nep(2, 189)/ 102.689/
          data  Nep(1, 190)/ 200.000/,Nep(2, 190)/ 102.488/
          data  Nep(1, 191)/ 201.000/,Nep(2, 191)/ 102.286/
          data  Nep(1, 192)/ 202.000/,Nep(2, 192)/ 102.083/
          data  Nep(1, 193)/ 203.000/,Nep(2, 193)/ 101.878/
          data  Nep(1, 194)/ 204.000/,Nep(2, 194)/ 101.672/
          data  Nep(1, 195)/ 205.000/,Nep(2, 195)/ 101.465/
          data  Nep(1, 196)/ 206.000/,Nep(2, 196)/ 101.255/
          data  Nep(1, 197)/ 207.000/,Nep(2, 197)/ 101.042/
          data  Nep(1, 198)/ 208.000/,Nep(2, 198)/ 100.826/
          data  Nep(1, 199)/ 209.000/,Nep(2, 199)/ 100.607/
          data  Nep(1, 200)/ 210.000/,Nep(2, 200)/ 100.382/
          data  Nep(1, 201)/ 211.000/,Nep(2, 201)/ 100.152/
          data  Nep(1, 202)/ 212.000/,Nep(2, 202)/  99.915/
          data  Nep(1, 203)/ 213.000/,Nep(2, 203)/  99.669/
          data  Nep(1, 204)/ 214.000/,Nep(2, 204)/  99.414/
          data  Nep(1, 205)/ 215.000/,Nep(2, 205)/  99.146/
          data  Nep(1, 206)/ 216.000/,Nep(2, 206)/  98.862/
          data  Nep(1, 207)/ 217.000/,Nep(2, 207)/  98.558/
          data  Nep(1, 208)/ 218.000/,Nep(2, 208)/  98.230/
          data  Nep(1, 209)/ 219.000/,Nep(2, 209)/  97.870/
          data  Nep(1, 210)/ 220.000/,Nep(2, 210)/  97.469/
          data  Nep(1, 211)/ 221.000/,Nep(2, 211)/  97.013/
          data  Nep(1, 212)/ 222.000/,Nep(2, 212)/  96.485/
          data  Nep(1, 213)/ 223.000/,Nep(2, 213)/  95.857/
          data  Nep(1, 214)/ 224.000/,Nep(2, 214)/  95.090/
          data  Nep(1, 215)/ 225.000/,Nep(2, 215)/  94.120/
          data  Nep(1, 216)/ 226.000/,Nep(2, 216)/  92.850/
          data  Nep(1, 217)/ 227.000/,Nep(2, 217)/  91.106/
          data  Nep(1, 218)/ 228.000/,Nep(2, 218)/  88.574/
          data  Nep(1, 219)/ 229.000/,Nep(2, 219)/  84.573/
          data  Nep(1, 220)/ 230.000/,Nep(2, 220)/  77.114/
          data  Nep(1, 221)/ 231.000/,Nep(2, 221)/  76.176/
          data  Nep(1, 222)/ 232.000/,Nep(2, 222)/  83.876/
          data  Nep(1, 223)/ 233.000/,Nep(2, 223)/  87.763/
          data  Nep(1, 224)/ 234.000/,Nep(2, 224)/  90.076/
          data  Nep(1, 225)/ 235.000/,Nep(2, 225)/  91.551/
          data  Nep(1, 226)/ 236.000/,Nep(2, 226)/  92.527/
          data  Nep(1, 227)/ 237.000/,Nep(2, 227)/  93.187/
          data  Nep(1, 228)/ 238.000/,Nep(2, 228)/  93.638/
          data  Nep(1, 229)/ 239.000/,Nep(2, 229)/  93.943/
          data  Nep(1, 230)/ 240.000/,Nep(2, 230)/  94.145/
          data  Nep(1, 231)/ 241.000/,Nep(2, 231)/  94.273/
          data  Nep(1, 232)/ 242.000/,Nep(2, 232)/  94.345/
          data  Nep(1, 233)/ 243.000/,Nep(2, 233)/  94.376/
          data  Nep(1, 234)/ 244.000/,Nep(2, 234)/  94.374/
          data  Nep(1, 235)/ 245.000/,Nep(2, 235)/  94.347/
          data  Nep(1, 236)/ 246.000/,Nep(2, 236)/  94.301/
          data  Nep(1, 237)/ 247.000/,Nep(2, 237)/  94.239/
          data  Nep(1, 238)/ 248.000/,Nep(2, 238)/  94.165/
          data  Nep(1, 239)/ 249.000/,Nep(2, 239)/  94.080/
          data  Nep(1, 240)/ 250.000/,Nep(2, 240)/  93.987/
          data  Nep(1, 241)/ 251.000/,Nep(2, 241)/  93.888/
          data  Nep(1, 242)/ 252.000/,Nep(2, 242)/  93.783/
          data  Nep(1, 243)/ 253.000/,Nep(2, 243)/  93.673/
          data  Nep(1, 244)/ 254.000/,Nep(2, 244)/  93.560/
          data  Nep(1, 245)/ 255.000/,Nep(2, 245)/  93.444/
          data  Nep(1, 246)/ 256.000/,Nep(2, 246)/  93.326/
          data  Nep(1, 247)/ 257.000/,Nep(2, 247)/  93.204/
          data  Nep(1, 248)/ 258.000/,Nep(2, 248)/  93.081/
          data  Nep(1, 249)/ 259.000/,Nep(2, 249)/  92.957/
          data  Nep(1, 250)/ 260.000/,Nep(2, 250)/  92.831/
          data  Nep(1, 251)/ 261.000/,Nep(2, 251)/  92.705/
          data  Nep(1, 252)/ 262.000/,Nep(2, 252)/  92.578/
          data  Nep(1, 253)/ 263.000/,Nep(2, 253)/  92.450/
          data  Nep(1, 254)/ 264.000/,Nep(2, 254)/  92.321/
          data  Nep(1, 255)/ 265.000/,Nep(2, 255)/  92.192/
          data  Nep(1, 256)/ 266.000/,Nep(2, 256)/  92.063/
          data  Nep(1, 257)/ 267.000/,Nep(2, 257)/  91.934/
          data  Nep(1, 258)/ 268.000/,Nep(2, 258)/  91.804/
          data  Nep(1, 259)/ 269.000/,Nep(2, 259)/  91.675/
          data  Nep(1, 260)/ 270.000/,Nep(2, 260)/  91.545/
          data  Nep(1, 261)/ 271.000/,Nep(2, 261)/  91.415/
          data  Nep(1, 262)/ 272.000/,Nep(2, 262)/  91.286/
          data  Nep(1, 263)/ 273.000/,Nep(2, 263)/  91.156/
          data  Nep(1, 264)/ 274.000/,Nep(2, 264)/  91.027/
          data  Nep(1, 265)/ 275.000/,Nep(2, 265)/  90.898/
          data  Nep(1, 266)/ 276.000/,Nep(2, 266)/  90.769/
          data  Nep(1, 267)/ 277.000/,Nep(2, 267)/  90.641/
          data  Nep(1, 268)/ 278.000/,Nep(2, 268)/  90.512/
          data  Nep(1, 269)/ 279.000/,Nep(2, 269)/  90.384/
          data  Nep(1, 270)/ 280.000/,Nep(2, 270)/  90.256/
          data  Nep(1, 271)/ 281.000/,Nep(2, 271)/  90.129/
          data  Nep(1, 272)/ 282.000/,Nep(2, 272)/  90.001/
          data  Nep(1, 273)/ 283.000/,Nep(2, 273)/  89.874/
          data  Nep(1, 274)/ 284.000/,Nep(2, 274)/  89.747/
          data  Nep(1, 275)/ 285.000/,Nep(2, 275)/  89.621/
          data  Nep(1, 276)/ 286.000/,Nep(2, 276)/  89.495/
          data  Nep(1, 277)/ 287.000/,Nep(2, 277)/  89.369/
          data  Nep(1, 278)/ 288.000/,Nep(2, 278)/  89.243/
          data  Nep(1, 279)/ 289.000/,Nep(2, 279)/  89.118/
          data  Nep(1, 280)/ 290.000/,Nep(2, 280)/  88.992/
          data  Nep(1, 281)/ 291.000/,Nep(2, 281)/  88.868/
          data  Nep(1, 282)/ 292.000/,Nep(2, 282)/  88.743/
          data  Nep(1, 283)/ 293.000/,Nep(2, 283)/  88.619/
          data  Nep(1, 284)/ 294.000/,Nep(2, 284)/  88.494/
          data  Nep(1, 285)/ 295.000/,Nep(2, 285)/  88.370/
          data  Nep(1, 286)/ 296.000/,Nep(2, 286)/  88.247/
          data  Nep(1, 287)/ 297.000/,Nep(2, 287)/  88.123/
          data  Nep(1, 288)/ 298.000/,Nep(2, 288)/  87.999/
          data  Nep(1, 289)/ 299.000/,Nep(2, 289)/  87.876/
          data  Nep(1, 290)/ 300.000/,Nep(2, 290)/  87.752/
          data  Nep(1, 291)/ 301.000/,Nep(2, 291)/  87.629/
          data  Nep(1, 292)/ 302.000/,Nep(2, 292)/  87.505/
          data  Nep(1, 293)/ 303.000/,Nep(2, 293)/  87.382/
          data  Nep(1, 294)/ 304.000/,Nep(2, 294)/  87.258/
          data  Nep(1, 295)/ 305.000/,Nep(2, 295)/  87.134/
          data  Nep(1, 296)/ 306.000/,Nep(2, 296)/  87.010/
          data  Nep(1, 297)/ 307.000/,Nep(2, 297)/  86.885/
          data  Nep(1, 298)/ 308.000/,Nep(2, 298)/  86.761/
          data  Nep(1, 299)/ 309.000/,Nep(2, 299)/  86.636/
          data  Nep(1, 300)/ 310.000/,Nep(2, 300)/  86.510/
          data  Nep(1, 301)/ 311.000/,Nep(2, 301)/  86.383/
          data  Nep(1, 302)/ 312.000/,Nep(2, 302)/  86.256/
          data  Nep(1, 303)/ 313.000/,Nep(2, 303)/  86.127/
          data  Nep(1, 304)/ 314.000/,Nep(2, 304)/  85.998/
          data  Nep(1, 305)/ 315.000/,Nep(2, 305)/  85.867/
          data  Nep(1, 306)/ 316.000/,Nep(2, 306)/  85.734/
          data  Nep(1, 307)/ 317.000/,Nep(2, 307)/  85.600/
          data  Nep(1, 308)/ 318.000/,Nep(2, 308)/  85.463/
          data  Nep(1, 309)/ 319.000/,Nep(2, 309)/  85.324/
          data  Nep(1, 310)/ 320.000/,Nep(2, 310)/  85.182/
          data  Nep(1, 311)/ 321.000/,Nep(2, 311)/  85.036/
          data  Nep(1, 312)/ 322.000/,Nep(2, 312)/  84.886/
          data  Nep(1, 313)/ 323.000/,Nep(2, 313)/  84.731/
          data  Nep(1, 314)/ 324.000/,Nep(2, 314)/  84.570/
          data  Nep(1, 315)/ 325.000/,Nep(2, 315)/  84.403/
          data  Nep(1, 316)/ 326.000/,Nep(2, 316)/  84.227/
          data  Nep(1, 317)/ 327.000/,Nep(2, 317)/  84.042/
          data  Nep(1, 318)/ 328.000/,Nep(2, 318)/  83.845/
          data  Nep(1, 319)/ 329.000/,Nep(2, 319)/  83.633/
          data  Nep(1, 320)/ 330.000/,Nep(2, 320)/  83.404/
          data  Nep(1, 321)/ 331.000/,Nep(2, 321)/  83.153/
          data  Nep(1, 322)/ 332.000/,Nep(2, 322)/  82.875/
          data  Nep(1, 323)/ 333.000/,Nep(2, 323)/  82.564/
          data  Nep(1, 324)/ 334.000/,Nep(2, 324)/  82.208/
          data  Nep(1, 325)/ 335.000/,Nep(2, 325)/  81.798/
          data  Nep(1, 326)/ 336.000/,Nep(2, 326)/  81.315/
          data  Nep(1, 327)/ 337.000/,Nep(2, 327)/  80.735/
          data  Nep(1, 328)/ 338.000/,Nep(2, 328)/  80.026/
          data  Nep(1, 329)/ 339.000/,Nep(2, 329)/  79.138/
          data  Nep(1, 330)/ 340.000/,Nep(2, 330)/  78.000/
          data  Nep(1, 331)/ 341.000/,Nep(2, 331)/  76.503/
          data  Nep(1, 332)/ 342.000/,Nep(2, 332)/  74.479/
          data  Nep(1, 333)/ 343.000/,Nep(2, 333)/  71.657/
          data  Nep(1, 334)/ 344.000/,Nep(2, 334)/  67.598/
          data  Nep(1, 335)/ 345.000/,Nep(2, 335)/  61.655/
          data  Nep(1, 336)/ 346.000/,Nep(2, 336)/  58.195/
          data  Nep(1, 337)/ 347.000/,Nep(2, 337)/  64.280/
          data  Nep(1, 338)/ 348.000/,Nep(2, 338)/  69.261/
          data  Nep(1, 339)/ 349.000/,Nep(2, 339)/  72.599/
          data  Nep(1, 340)/ 350.000/,Nep(2, 340)/  74.884/
          data  Nep(1, 341)/ 351.000/,Nep(2, 341)/  76.484/
          data  Nep(1, 342)/ 352.000/,Nep(2, 342)/  77.626/
          data  Nep(1, 343)/ 353.000/,Nep(2, 343)/  78.455/
          data  Nep(1, 344)/ 354.000/,Nep(2, 344)/  79.064/
          data  Nep(1, 345)/ 355.000/,Nep(2, 345)/  79.515/
          data  Nep(1, 346)/ 356.000/,Nep(2, 346)/  79.851/
          data  Nep(1, 347)/ 357.000/,Nep(2, 347)/  80.101/
          data  Nep(1, 348)/ 358.000/,Nep(2, 348)/  80.286/
          data  Nep(1, 349)/ 359.000/,Nep(2, 349)/  80.422/
          data  Nep(1, 350)/ 360.000/,Nep(2, 350)/  80.518/
          data  Nep(1, 351)/ 361.000/,Nep(2, 351)/  80.585/
          data  Nep(1, 352)/ 362.000/,Nep(2, 352)/  80.627/
          data  Nep(1, 353)/ 363.000/,Nep(2, 353)/  80.650/
          data  Nep(1, 354)/ 364.000/,Nep(2, 354)/  80.657/
          data  Nep(1, 355)/ 365.000/,Nep(2, 355)/  80.651/
          data  Nep(1, 356)/ 366.000/,Nep(2, 356)/  80.635/
          data  Nep(1, 357)/ 367.000/,Nep(2, 357)/  80.609/
          data  Nep(1, 358)/ 368.000/,Nep(2, 358)/  80.577/
          data  Nep(1, 359)/ 369.000/,Nep(2, 359)/  80.538/
          data  Nep(1, 360)/ 370.000/,Nep(2, 360)/  80.494/
          data  Nep(1, 361)/ 371.000/,Nep(2, 361)/  80.446/
          data  Nep(1, 362)/ 372.000/,Nep(2, 362)/  80.394/
          data  Nep(1, 363)/ 373.000/,Nep(2, 363)/  80.339/
          data  Nep(1, 364)/ 374.000/,Nep(2, 364)/  80.281/
          data  Nep(1, 365)/ 375.000/,Nep(2, 365)/  80.221/
          data  Nep(1, 366)/ 376.000/,Nep(2, 366)/  80.159/
          data  Nep(1, 367)/ 377.000/,Nep(2, 367)/  80.095/
          data  Nep(1, 368)/ 378.000/,Nep(2, 368)/  80.030/
          data  Nep(1, 369)/ 379.000/,Nep(2, 369)/  79.963/
          data  Nep(1, 370)/ 380.000/,Nep(2, 370)/  79.895/
          data  Nep(1, 371)/ 381.000/,Nep(2, 371)/  79.827/
          data  Nep(1, 372)/ 382.000/,Nep(2, 372)/  79.757/
          data  Nep(1, 373)/ 383.000/,Nep(2, 373)/  79.687/
          data  Nep(1, 374)/ 384.000/,Nep(2, 374)/  79.616/
          data  Nep(1, 375)/ 385.000/,Nep(2, 375)/  79.545/
          data  Nep(1, 376)/ 386.000/,Nep(2, 376)/  79.473/
          data  Nep(1, 377)/ 387.000/,Nep(2, 377)/  79.400/
          data  Nep(1, 378)/ 388.000/,Nep(2, 378)/  79.328/
          data  Nep(1, 379)/ 389.000/,Nep(2, 379)/  79.255/
          data  Nep(1, 380)/ 390.000/,Nep(2, 380)/  79.182/
          data  Nep(1, 381)/ 391.000/,Nep(2, 381)/  79.108/
          data  Nep(1, 382)/ 392.000/,Nep(2, 382)/  79.034/
          data  Nep(1, 383)/ 393.000/,Nep(2, 383)/  78.961/
          data  Nep(1, 384)/ 394.000/,Nep(2, 384)/  78.887/
          data  Nep(1, 385)/ 395.000/,Nep(2, 385)/  78.813/
          data  Nep(1, 386)/ 396.000/,Nep(2, 386)/  78.739/
          data  Nep(1, 387)/ 397.000/,Nep(2, 387)/  78.665/
          data  Nep(1, 388)/ 398.000/,Nep(2, 388)/  78.590/
          data  Nep(1, 389)/ 399.000/,Nep(2, 389)/  78.516/
          data  Nep(1, 390)/ 400.000/,Nep(2, 390)/  78.442/
          data  Nep(1, 391)/ 401.000/,Nep(2, 391)/  78.368/
          data  Nep(1, 392)/ 402.000/,Nep(2, 392)/  78.293/
          data  Nep(1, 393)/ 403.000/,Nep(2, 393)/  78.219/
          data  Nep(1, 394)/ 404.000/,Nep(2, 394)/  78.144/
          data  Nep(1, 395)/ 405.000/,Nep(2, 395)/  78.069/
          data  Nep(1, 396)/ 406.000/,Nep(2, 396)/  77.995/
          data  Nep(1, 397)/ 407.000/,Nep(2, 397)/  77.920/
          data  Nep(1, 398)/ 408.000/,Nep(2, 398)/  77.845/
          data  Nep(1, 399)/ 409.000/,Nep(2, 399)/  77.771/
          data  Nep(1, 400)/ 410.000/,Nep(2, 400)/  77.696/
          data  Nep(1, 401)/ 411.000/,Nep(2, 401)/  77.621/
          data  Nep(1, 402)/ 412.000/,Nep(2, 402)/  77.546/
          data  Nep(1, 403)/ 413.000/,Nep(2, 403)/  77.470/
          data  Nep(1, 404)/ 414.000/,Nep(2, 404)/  77.395/
          data  Nep(1, 405)/ 415.000/,Nep(2, 405)/  77.319/
          data  Nep(1, 406)/ 416.000/,Nep(2, 406)/  77.243/
          data  Nep(1, 407)/ 417.000/,Nep(2, 407)/  77.167/
          data  Nep(1, 408)/ 418.000/,Nep(2, 408)/  77.090/
          data  Nep(1, 409)/ 419.000/,Nep(2, 409)/  77.014/
          data  Nep(1, 410)/ 420.000/,Nep(2, 410)/  76.936/
          data  Nep(1, 411)/ 421.000/,Nep(2, 411)/  76.858/
          data  Nep(1, 412)/ 422.000/,Nep(2, 412)/  76.780/
          data  Nep(1, 413)/ 423.000/,Nep(2, 413)/  76.701/
          data  Nep(1, 414)/ 424.000/,Nep(2, 414)/  76.621/
          data  Nep(1, 415)/ 425.000/,Nep(2, 415)/  76.541/
          data  Nep(1, 416)/ 426.000/,Nep(2, 416)/  76.459/
          data  Nep(1, 417)/ 427.000/,Nep(2, 417)/  76.377/
          data  Nep(1, 418)/ 428.000/,Nep(2, 418)/  76.293/
          data  Nep(1, 419)/ 429.000/,Nep(2, 419)/  76.208/
          data  Nep(1, 420)/ 430.000/,Nep(2, 420)/  76.121/
          data  Nep(1, 421)/ 431.000/,Nep(2, 421)/  76.033/
          data  Nep(1, 422)/ 432.000/,Nep(2, 422)/  75.942/
          data  Nep(1, 423)/ 433.000/,Nep(2, 423)/  75.849/
          data  Nep(1, 424)/ 434.000/,Nep(2, 424)/  75.753/
          data  Nep(1, 425)/ 435.000/,Nep(2, 425)/  75.655/
          data  Nep(1, 426)/ 436.000/,Nep(2, 426)/  75.552/
          data  Nep(1, 427)/ 437.000/,Nep(2, 427)/  75.445/
          data  Nep(1, 428)/ 438.000/,Nep(2, 428)/  75.333/
          data  Nep(1, 429)/ 439.000/,Nep(2, 429)/  75.216/
          data  Nep(1, 430)/ 440.000/,Nep(2, 430)/  75.091/
          data  Nep(1, 431)/ 441.000/,Nep(2, 431)/  74.959/
          data  Nep(1, 432)/ 442.000/,Nep(2, 432)/  74.816/
          data  Nep(1, 433)/ 443.000/,Nep(2, 433)/  74.662/
          data  Nep(1, 434)/ 444.000/,Nep(2, 434)/  74.494/
          data  Nep(1, 435)/ 445.000/,Nep(2, 435)/  74.309/
          data  Nep(1, 436)/ 446.000/,Nep(2, 436)/  74.103/
          data  Nep(1, 437)/ 447.000/,Nep(2, 437)/  73.870/
          data  Nep(1, 438)/ 448.000/,Nep(2, 438)/  73.605/
          data  Nep(1, 439)/ 449.000/,Nep(2, 439)/  73.298/
          data  Nep(1, 440)/ 450.000/,Nep(2, 440)/  72.939/
          data  Nep(1, 441)/ 451.000/,Nep(2, 441)/  72.510/
          data  Nep(1, 442)/ 452.000/,Nep(2, 442)/  71.993/
          data  Nep(1, 443)/ 453.000/,Nep(2, 443)/  71.354/
          data  Nep(1, 444)/ 454.000/,Nep(2, 444)/  70.555/
          data  Nep(1, 445)/ 455.000/,Nep(2, 445)/  69.533/
          data  Nep(1, 446)/ 456.000/,Nep(2, 446)/  68.204/
          data  Nep(1, 447)/ 457.000/,Nep(2, 447)/  66.444/
          data  Nep(1, 448)/ 458.000/,Nep(2, 448)/  64.080/
          data  Nep(1, 449)/ 459.000/,Nep(2, 449)/  60.904/
          data  Nep(1, 450)/ 460.000/,Nep(2, 450)/  56.877/
          data  Nep(1, 451)/ 461.000/,Nep(2, 451)/  66.334/
          data  Nep(1, 452)/ 462.000/,Nep(2, 452)/  56.497/
          data  Nep(1, 453)/ 463.000/,Nep(2, 453)/  60.396/
          data  Nep(1, 454)/ 464.000/,Nep(2, 454)/  63.272/
          data  Nep(1, 455)/ 465.000/,Nep(2, 455)/  64.708/
          data  Nep(1, 456)/ 466.000/,Nep(2, 456)/  66.783/
          data  Nep(1, 457)/ 467.000/,Nep(2, 457)/  68.455/
          data  Nep(1, 458)/ 468.000/,Nep(2, 458)/  69.575/
          data  Nep(1, 459)/ 469.000/,Nep(2, 459)/  70.379/
          data  Nep(1, 460)/ 470.000/,Nep(2, 460)/  70.971/
          data  Nep(1, 461)/ 471.000/,Nep(2, 461)/  71.418/
          data  Nep(1, 462)/ 472.000/,Nep(2, 462)/  71.757/
          data  Nep(1, 463)/ 473.000/,Nep(2, 463)/  72.018/
          data  Nep(1, 464)/ 474.000/,Nep(2, 464)/  72.219/
          data  Nep(1, 465)/ 475.000/,Nep(2, 465)/  72.375/
          data  Nep(1, 466)/ 476.000/,Nep(2, 466)/  72.494/
          data  Nep(1, 467)/ 477.000/,Nep(2, 467)/  72.586/
          data  Nep(1, 468)/ 478.000/,Nep(2, 468)/  72.655/
          data  Nep(1, 469)/ 479.000/,Nep(2, 469)/  72.706/
          data  Nep(1, 470)/ 480.000/,Nep(2, 470)/  72.742/
          data  Nep(1, 471)/ 481.000/,Nep(2, 471)/  72.766/
          data  Nep(1, 472)/ 482.000/,Nep(2, 472)/  72.779/
          data  Nep(1, 473)/ 483.000/,Nep(2, 473)/  72.785/
          data  Nep(1, 474)/ 484.000/,Nep(2, 474)/  72.783/
          data  Nep(1, 475)/ 485.000/,Nep(2, 475)/  72.776/
          data  Nep(1, 476)/ 486.000/,Nep(2, 476)/  72.763/
          data  Nep(1, 477)/ 487.000/,Nep(2, 477)/  72.747/
          data  Nep(1, 478)/ 488.000/,Nep(2, 478)/  72.726/
          data  Nep(1, 479)/ 489.000/,Nep(2, 479)/  72.703/
          data  Nep(1, 480)/ 490.000/,Nep(2, 480)/  72.676/
          data  Nep(1, 481)/ 491.000/,Nep(2, 481)/  72.648/
          data  Nep(1, 482)/ 492.000/,Nep(2, 482)/  72.617/
          data  Nep(1, 483)/ 493.000/,Nep(2, 483)/  72.584/
          data  Nep(1, 484)/ 494.000/,Nep(2, 484)/  72.550/
          data  Nep(1, 485)/ 495.000/,Nep(2, 485)/  72.515/
          data  Nep(1, 486)/ 496.000/,Nep(2, 486)/  72.478/
          data  Nep(1, 487)/ 497.000/,Nep(2, 487)/  72.440/
          data  Nep(1, 488)/ 498.000/,Nep(2, 488)/  72.402/
          data  Nep(1, 489)/ 499.000/,Nep(2, 489)/  72.362/
          data  Nep(1, 490)/ 500.000/,Nep(2, 490)/  72.322/
          data  Nep(1, 491)/ 501.000/,Nep(2, 491)/  72.280/
          data  Nep(1, 492)/ 502.000/,Nep(2, 492)/  72.239/
          data  Nep(1, 493)/ 503.000/,Nep(2, 493)/  72.197/
          data  Nep(1, 494)/ 504.000/,Nep(2, 494)/  72.154/
          data  Nep(1, 495)/ 505.000/,Nep(2, 495)/  72.112/
          data  Nep(1, 496)/ 506.000/,Nep(2, 496)/  72.068/
          data  Nep(1, 497)/ 507.000/,Nep(2, 497)/  72.025/
          data  Nep(1, 498)/ 508.000/,Nep(2, 498)/  71.981/
          data  Nep(1, 499)/ 509.000/,Nep(2, 499)/  71.936/
          data  Nep(1, 500)/ 510.000/,Nep(2, 500)/  71.892/
          data  Nep(1, 501)/ 511.000/,Nep(2, 501)/  71.847/
          data  Nep(1, 502)/ 512.000/,Nep(2, 502)/  71.802/
          data  Nep(1, 503)/ 513.000/,Nep(2, 503)/  71.757/
          data  Nep(1, 504)/ 514.000/,Nep(2, 504)/  71.712/
          data  Nep(1, 505)/ 515.000/,Nep(2, 505)/  71.666/
          data  Nep(1, 506)/ 516.000/,Nep(2, 506)/  71.621/
          data  Nep(1, 507)/ 517.000/,Nep(2, 507)/  71.575/
          data  Nep(1, 508)/ 518.000/,Nep(2, 508)/  71.529/
          data  Nep(1, 509)/ 519.000/,Nep(2, 509)/  71.483/
          data  Nep(1, 510)/ 520.000/,Nep(2, 510)/  71.437/
          data  Nep(1, 511)/ 521.000/,Nep(2, 511)/  71.390/
          data  Nep(1, 512)/ 522.000/,Nep(2, 512)/  71.344/
          data  Nep(1, 513)/ 523.000/,Nep(2, 513)/  71.297/
          data  Nep(1, 514)/ 524.000/,Nep(2, 514)/  71.250/
          data  Nep(1, 515)/ 525.000/,Nep(2, 515)/  71.203/
          data  Nep(1, 516)/ 526.000/,Nep(2, 516)/  71.156/
          data  Nep(1, 517)/ 527.000/,Nep(2, 517)/  71.108/
          data  Nep(1, 518)/ 528.000/,Nep(2, 518)/  71.061/
          data  Nep(1, 519)/ 529.000/,Nep(2, 519)/  71.013/
          data  Nep(1, 520)/ 530.000/,Nep(2, 520)/  70.965/
          data  Nep(1, 521)/ 531.000/,Nep(2, 521)/  70.916/
          data  Nep(1, 522)/ 532.000/,Nep(2, 522)/  70.868/
          data  Nep(1, 523)/ 533.000/,Nep(2, 523)/  70.819/
          data  Nep(1, 524)/ 534.000/,Nep(2, 524)/  70.769/
          data  Nep(1, 525)/ 535.000/,Nep(2, 525)/  70.720/
          data  Nep(1, 526)/ 536.000/,Nep(2, 526)/  70.669/
          data  Nep(1, 527)/ 537.000/,Nep(2, 527)/  70.618/
          data  Nep(1, 528)/ 538.000/,Nep(2, 528)/  70.567/
          data  Nep(1, 529)/ 539.000/,Nep(2, 529)/  70.515/
          data  Nep(1, 530)/ 540.000/,Nep(2, 530)/  70.462/
          data  Nep(1, 531)/ 541.000/,Nep(2, 531)/  70.409/
          data  Nep(1, 532)/ 542.000/,Nep(2, 532)/  70.354/
          data  Nep(1, 533)/ 543.000/,Nep(2, 533)/  70.299/
          data  Nep(1, 534)/ 544.000/,Nep(2, 534)/  70.242/
          data  Nep(1, 535)/ 545.000/,Nep(2, 535)/  70.184/
          data  Nep(1, 536)/ 546.000/,Nep(2, 536)/  70.125/
          data  Nep(1, 537)/ 547.000/,Nep(2, 537)/  70.064/
          data  Nep(1, 538)/ 548.000/,Nep(2, 538)/  70.001/
          data  Nep(1, 539)/ 549.000/,Nep(2, 539)/  69.936/
          data  Nep(1, 540)/ 550.000/,Nep(2, 540)/  69.868/
          data  Nep(1, 541)/ 551.000/,Nep(2, 541)/  69.798/
          data  Nep(1, 542)/ 552.000/,Nep(2, 542)/  69.723/
          data  Nep(1, 543)/ 553.000/,Nep(2, 543)/  69.645/
          data  Nep(1, 544)/ 554.000/,Nep(2, 544)/  69.563/
          data  Nep(1, 545)/ 555.000/,Nep(2, 545)/  69.474/
          data  Nep(1, 546)/ 556.000/,Nep(2, 546)/  69.380/
          data  Nep(1, 547)/ 557.000/,Nep(2, 547)/  69.278/
          data  Nep(1, 548)/ 558.000/,Nep(2, 548)/  69.166/
          data  Nep(1, 549)/ 559.000/,Nep(2, 549)/  69.043/
          data  Nep(1, 550)/ 560.000/,Nep(2, 550)/  68.907/
          data  Nep(1, 551)/ 561.000/,Nep(2, 551)/  68.754/
          data  Nep(1, 552)/ 562.000/,Nep(2, 552)/  68.580/
          data  Nep(1, 553)/ 563.000/,Nep(2, 553)/  68.381/
          data  Nep(1, 554)/ 564.000/,Nep(2, 554)/  68.149/
          data  Nep(1, 555)/ 565.000/,Nep(2, 555)/  67.875/
          data  Nep(1, 556)/ 566.000/,Nep(2, 556)/  67.548/
          data  Nep(1, 557)/ 567.000/,Nep(2, 557)/  67.149/
          data  Nep(1, 558)/ 568.000/,Nep(2, 558)/  66.657/
          data  Nep(1, 559)/ 569.000/,Nep(2, 559)/  66.037/
          data  Nep(1, 560)/ 570.000/,Nep(2, 560)/  65.245/
          data  Nep(1, 561)/ 571.000/,Nep(2, 561)/  64.213/
          data  Nep(1, 562)/ 572.000/,Nep(2, 562)/  62.851/
          data  Nep(1, 563)/ 573.000/,Nep(2, 563)/  61.032/
          data  Nep(1, 564)/ 574.000/,Nep(2, 564)/  58.621/
          data  Nep(1, 565)/ 575.000/,Nep(2, 565)/  55.655/
          data  Nep(1, 566)/ 576.000/,Nep(2, 566)/  55.465/
          data  Nep(1, 567)/ 577.000/,Nep(2, 567)/  54.292/
          data  Nep(1, 568)/ 578.000/,Nep(2, 568)/  57.052/
          data  Nep(1, 569)/ 579.000/,Nep(2, 569)/  59.762/
          data  Nep(1, 570)/ 580.000/,Nep(2, 570)/  61.831/
          data  Nep(1, 571)/ 581.000/,Nep(2, 571)/  63.357/
          data  Nep(1, 572)/ 582.000/,Nep(2, 572)/  64.481/
          data  Nep(1, 573)/ 583.000/,Nep(2, 573)/  65.316/
          data  Nep(1, 574)/ 584.000/,Nep(2, 574)/  65.943/
          data  Nep(1, 575)/ 585.000/,Nep(2, 575)/  66.418/
          data  Nep(1, 576)/ 586.000/,Nep(2, 576)/  66.783/
          data  Nep(1, 577)/ 587.000/,Nep(2, 577)/  67.065/
          data  Nep(1, 578)/ 588.000/,Nep(2, 578)/  67.285/
          data  Nep(1, 579)/ 589.000/,Nep(2, 579)/  67.456/
          data  Nep(1, 580)/ 590.000/,Nep(2, 580)/  67.592/
          data  Nep(1, 581)/ 591.000/,Nep(2, 581)/  67.698/
          data  Nep(1, 582)/ 592.000/,Nep(2, 582)/  67.782/
          data  Nep(1, 583)/ 593.000/,Nep(2, 583)/  67.847/
          data  Nep(1, 584)/ 594.000/,Nep(2, 584)/  67.897/
          data  Nep(1, 585)/ 595.000/,Nep(2, 585)/  67.935/
          data  Nep(1, 586)/ 596.000/,Nep(2, 586)/  67.964/
          data  Nep(1, 587)/ 597.000/,Nep(2, 587)/  67.984/
          data  Nep(1, 588)/ 598.000/,Nep(2, 588)/  67.998/
          data  Nep(1, 589)/ 599.000/,Nep(2, 589)/  68.005/
          data  Nep(1, 590)/ 600.000/,Nep(2, 590)/  68.008/
          data  Nep(1, 591)/ 601.000/,Nep(2, 591)/  68.006/
          data  Nep(1, 592)/ 602.000/,Nep(2, 592)/  68.001/
          data  Nep(1, 593)/ 603.000/,Nep(2, 593)/  67.993/
          data  Nep(1, 594)/ 604.000/,Nep(2, 594)/  67.983/
          data  Nep(1, 595)/ 605.000/,Nep(2, 595)/  67.970/
          data  Nep(1, 596)/ 606.000/,Nep(2, 596)/  67.955/
          data  Nep(1, 597)/ 607.000/,Nep(2, 597)/  67.938/
          data  Nep(1, 598)/ 608.000/,Nep(2, 598)/  67.920/
          data  Nep(1, 599)/ 609.000/,Nep(2, 599)/  67.900/
          data  Nep(1, 600)/ 610.000/,Nep(2, 600)/  67.880/
          data  Nep(1, 601)/ 611.000/,Nep(2, 601)/  67.858/
          data  Nep(1, 602)/ 612.000/,Nep(2, 602)/  67.836/
          data  Nep(1, 603)/ 613.000/,Nep(2, 603)/  67.813/
          data  Nep(1, 604)/ 614.000/,Nep(2, 604)/  67.789/
          data  Nep(1, 605)/ 615.000/,Nep(2, 605)/  67.764/
          data  Nep(1, 606)/ 616.000/,Nep(2, 606)/  67.739/
          data  Nep(1, 607)/ 617.000/,Nep(2, 607)/  67.713/
          data  Nep(1, 608)/ 618.000/,Nep(2, 608)/  67.687/
          data  Nep(1, 609)/ 619.000/,Nep(2, 609)/  67.660/
          data  Nep(1, 610)/ 620.000/,Nep(2, 610)/  67.633/
          data  Nep(1, 611)/ 621.000/,Nep(2, 611)/  67.606/
          data  Nep(1, 612)/ 622.000/,Nep(2, 612)/  67.578/
          data  Nep(1, 613)/ 623.000/,Nep(2, 613)/  67.550/
          data  Nep(1, 614)/ 624.000/,Nep(2, 614)/  67.522/
          data  Nep(1, 615)/ 625.000/,Nep(2, 615)/  67.493/
          data  Nep(1, 616)/ 626.000/,Nep(2, 616)/  67.465/
          data  Nep(1, 617)/ 627.000/,Nep(2, 617)/  67.436/
          data  Nep(1, 618)/ 628.000/,Nep(2, 618)/  67.407/
          data  Nep(1, 619)/ 629.000/,Nep(2, 619)/  67.378/
          data  Nep(1, 620)/ 630.000/,Nep(2, 620)/  67.348/
          data  Nep(1, 621)/ 631.000/,Nep(2, 621)/  67.319/
          data  Nep(1, 622)/ 632.000/,Nep(2, 622)/  67.289/
          data  Nep(1, 623)/ 633.000/,Nep(2, 623)/  67.259/
          data  Nep(1, 624)/ 634.000/,Nep(2, 624)/  67.229/
          data  Nep(1, 625)/ 635.000/,Nep(2, 625)/  67.199/
          data  Nep(1, 626)/ 636.000/,Nep(2, 626)/  67.169/
          data  Nep(1, 627)/ 637.000/,Nep(2, 627)/  67.138/
          data  Nep(1, 628)/ 638.000/,Nep(2, 628)/  67.107/
          data  Nep(1, 629)/ 639.000/,Nep(2, 629)/  67.077/
          data  Nep(1, 630)/ 640.000/,Nep(2, 630)/  67.046/
          data  Nep(1, 631)/ 641.000/,Nep(2, 631)/  67.015/
          data  Nep(1, 632)/ 642.000/,Nep(2, 632)/  66.984/
          data  Nep(1, 633)/ 643.000/,Nep(2, 633)/  66.952/
          data  Nep(1, 634)/ 644.000/,Nep(2, 634)/  66.920/
          data  Nep(1, 635)/ 645.000/,Nep(2, 635)/  66.889/
          data  Nep(1, 636)/ 646.000/,Nep(2, 636)/  66.857/
          data  Nep(1, 637)/ 647.000/,Nep(2, 637)/  66.824/
          data  Nep(1, 638)/ 648.000/,Nep(2, 638)/  66.792/
          data  Nep(1, 639)/ 649.000/,Nep(2, 639)/  66.759/
          data  Nep(1, 640)/ 650.000/,Nep(2, 640)/  66.726/
          data  Nep(1, 641)/ 651.000/,Nep(2, 641)/  66.692/
          data  Nep(1, 642)/ 652.000/,Nep(2, 642)/  66.658/
          data  Nep(1, 643)/ 653.000/,Nep(2, 643)/  66.624/
          data  Nep(1, 644)/ 654.000/,Nep(2, 644)/  66.589/
          data  Nep(1, 645)/ 655.000/,Nep(2, 645)/  66.554/
          data  Nep(1, 646)/ 656.000/,Nep(2, 646)/  66.518/
          data  Nep(1, 647)/ 657.000/,Nep(2, 647)/  66.481/
          data  Nep(1, 648)/ 658.000/,Nep(2, 648)/  66.444/
          data  Nep(1, 649)/ 659.000/,Nep(2, 649)/  66.405/
          data  Nep(1, 650)/ 660.000/,Nep(2, 650)/  66.366/
          data  Nep(1, 651)/ 661.000/,Nep(2, 651)/  66.326/
          data  Nep(1, 652)/ 662.000/,Nep(2, 652)/  66.284/
          data  Nep(1, 653)/ 663.000/,Nep(2, 653)/  66.242/
          data  Nep(1, 654)/ 664.000/,Nep(2, 654)/  66.197/
          data  Nep(1, 655)/ 665.000/,Nep(2, 655)/  66.151/
          data  Nep(1, 656)/ 666.000/,Nep(2, 656)/  66.102/
          data  Nep(1, 657)/ 667.000/,Nep(2, 657)/  66.051/
          data  Nep(1, 658)/ 668.000/,Nep(2, 658)/  65.998/
          data  Nep(1, 659)/ 669.000/,Nep(2, 659)/  65.941/
          data  Nep(1, 660)/ 670.000/,Nep(2, 660)/  65.880/
          data  Nep(1, 661)/ 671.000/,Nep(2, 661)/  65.814/
          data  Nep(1, 662)/ 672.000/,Nep(2, 662)/  65.743/
          data  Nep(1, 663)/ 673.000/,Nep(2, 663)/  65.665/
          data  Nep(1, 664)/ 674.000/,Nep(2, 664)/  65.580/
          data  Nep(1, 665)/ 675.000/,Nep(2, 665)/  65.485/
          data  Nep(1, 666)/ 676.000/,Nep(2, 666)/  65.378/
          data  Nep(1, 667)/ 677.000/,Nep(2, 667)/  65.255/
          data  Nep(1, 668)/ 678.000/,Nep(2, 668)/  65.115/
          data  Nep(1, 669)/ 679.000/,Nep(2, 669)/  64.952/
          data  Nep(1, 670)/ 680.000/,Nep(2, 670)/  64.758/
          data  Nep(1, 671)/ 681.000/,Nep(2, 671)/  64.526/
          data  Nep(1, 672)/ 682.000/,Nep(2, 672)/  64.243/
          data  Nep(1, 673)/ 683.000/,Nep(2, 673)/  63.893/
          data  Nep(1, 674)/ 684.000/,Nep(2, 674)/  63.449/
          data  Nep(1, 675)/ 685.000/,Nep(2, 675)/  62.880/
          data  Nep(1, 676)/ 686.000/,Nep(2, 676)/  62.134/
          data  Nep(1, 677)/ 687.000/,Nep(2, 677)/  61.137/
          data  Nep(1, 678)/ 688.000/,Nep(2, 678)/  59.789/
          data  Nep(1, 679)/ 689.000/,Nep(2, 679)/  57.962/
          data  Nep(1, 680)/ 690.000/,Nep(2, 680)/  55.611/
          data  Nep(1, 681)/ 691.000/,Nep(2, 681)/  54.198/
          data  Nep(1, 682)/ 692.000/,Nep(2, 682)/  54.080/
          data  Nep(1, 683)/ 693.000/,Nep(2, 683)/  55.698/
          data  Nep(1, 684)/ 694.000/,Nep(2, 684)/  57.908/
          data  Nep(1, 685)/ 695.000/,Nep(2, 685)/  59.482/
          data  Nep(1, 686)/ 696.000/,Nep(2, 686)/  60.384/
          data  Nep(1, 687)/ 697.000/,Nep(2, 687)/  60.433/
          data  Nep(1, 688)/ 698.000/,Nep(2, 688)/  60.120/
          data  Nep(1, 689)/ 699.000/,Nep(2, 689)/  61.921/
          data  Nep(1, 690)/ 700.000/,Nep(2, 690)/  62.842/
          data  Nep(1, 691)/ 701.000/,Nep(2, 691)/  63.402/
          data  Nep(1, 692)/ 702.000/,Nep(2, 692)/  63.779/
          data  Nep(1, 693)/ 703.000/,Nep(2, 693)/  64.047/
          data  Nep(1, 694)/ 704.000/,Nep(2, 694)/  64.246/
          data  Nep(1, 695)/ 705.000/,Nep(2, 695)/  64.396/
          data  Nep(1, 696)/ 706.000/,Nep(2, 696)/  64.511/
          data  Nep(1, 697)/ 707.000/,Nep(2, 697)/  64.601/
          data  Nep(1, 698)/ 708.000/,Nep(2, 698)/  64.670/
          data  Nep(1, 699)/ 709.000/,Nep(2, 699)/  64.725/
          data  Nep(1, 700)/ 710.000/,Nep(2, 700)/  64.767/
          data  Nep(1, 701)/ 711.000/,Nep(2, 701)/  64.799/
          data  Nep(1, 702)/ 712.000/,Nep(2, 702)/  64.824/
          data  Nep(1, 703)/ 713.000/,Nep(2, 703)/  64.842/
          data  Nep(1, 704)/ 714.000/,Nep(2, 704)/  64.854/
          data  Nep(1, 705)/ 715.000/,Nep(2, 705)/  64.863/
          data  Nep(1, 706)/ 716.000/,Nep(2, 706)/  64.867/
          data  Nep(1, 707)/ 717.000/,Nep(2, 707)/  64.869/
          data  Nep(1, 708)/ 718.000/,Nep(2, 708)/  64.867/
          data  Nep(1, 709)/ 719.000/,Nep(2, 709)/  64.864/
          data  Nep(1, 710)/ 720.000/,Nep(2, 710)/  64.858/
          data  Nep(1, 711)/ 721.000/,Nep(2, 711)/  64.851/
          data  Nep(1, 712)/ 722.000/,Nep(2, 712)/  64.842/
          data  Nep(1, 713)/ 723.000/,Nep(2, 713)/  64.832/
          data  Nep(1, 714)/ 724.000/,Nep(2, 714)/  64.821/
          data  Nep(1, 715)/ 725.000/,Nep(2, 715)/  64.809/
          data  Nep(1, 716)/ 726.000/,Nep(2, 716)/  64.796/
          data  Nep(1, 717)/ 727.000/,Nep(2, 717)/  64.782/
          data  Nep(1, 718)/ 728.000/,Nep(2, 718)/  64.768/
          data  Nep(1, 719)/ 729.000/,Nep(2, 719)/  64.753/
          data  Nep(1, 720)/ 730.000/,Nep(2, 720)/  64.737/
          data  Nep(1, 721)/ 731.000/,Nep(2, 721)/  64.721/
          data  Nep(1, 722)/ 732.000/,Nep(2, 722)/  64.704/
          data  Nep(1, 723)/ 733.000/,Nep(2, 723)/  64.687/
          data  Nep(1, 724)/ 734.000/,Nep(2, 724)/  64.670/
          data  Nep(1, 725)/ 735.000/,Nep(2, 725)/  64.652/
          data  Nep(1, 726)/ 736.000/,Nep(2, 726)/  64.634/
          data  Nep(1, 727)/ 737.000/,Nep(2, 727)/  64.616/
          data  Nep(1, 728)/ 738.000/,Nep(2, 728)/  64.598/
          data  Nep(1, 729)/ 739.000/,Nep(2, 729)/  64.579/
          data  Nep(1, 730)/ 740.000/,Nep(2, 730)/  64.560/
          data  Nep(1, 731)/ 741.000/,Nep(2, 731)/  64.541/
          data  Nep(1, 732)/ 742.000/,Nep(2, 732)/  64.522/
          data  Nep(1, 733)/ 743.000/,Nep(2, 733)/  64.503/
          data  Nep(1, 734)/ 744.000/,Nep(2, 734)/  64.483/
          data  Nep(1, 735)/ 745.000/,Nep(2, 735)/  64.464/
          data  Nep(1, 736)/ 746.000/,Nep(2, 736)/  64.444/
          data  Nep(1, 737)/ 747.000/,Nep(2, 737)/  64.424/
          data  Nep(1, 738)/ 748.000/,Nep(2, 738)/  64.404/
          data  Nep(1, 739)/ 749.000/,Nep(2, 739)/  64.384/
          data  Nep(1, 740)/ 750.000/,Nep(2, 740)/  64.364/
          data  Nep(1, 741)/ 751.000/,Nep(2, 741)/  64.343/
          data  Nep(1, 742)/ 752.000/,Nep(2, 742)/  64.323/
          data  Nep(1, 743)/ 753.000/,Nep(2, 743)/  64.302/
          data  Nep(1, 744)/ 754.000/,Nep(2, 744)/  64.282/
          data  Nep(1, 745)/ 755.000/,Nep(2, 745)/  64.261/
          data  Nep(1, 746)/ 756.000/,Nep(2, 746)/  64.240/
          data  Nep(1, 747)/ 757.000/,Nep(2, 747)/  64.219/
          data  Nep(1, 748)/ 758.000/,Nep(2, 748)/  64.198/
          data  Nep(1, 749)/ 759.000/,Nep(2, 749)/  64.177/
          data  Nep(1, 750)/ 760.000/,Nep(2, 750)/  64.155/
          data  Nep(1, 751)/ 761.000/,Nep(2, 751)/  64.133/
          data  Nep(1, 752)/ 762.000/,Nep(2, 752)/  64.112/
          data  Nep(1, 753)/ 763.000/,Nep(2, 753)/  64.090/
          data  Nep(1, 754)/ 764.000/,Nep(2, 754)/  64.068/
          data  Nep(1, 755)/ 765.000/,Nep(2, 755)/  64.046/
          data  Nep(1, 756)/ 766.000/,Nep(2, 756)/  64.023/
          data  Nep(1, 757)/ 767.000/,Nep(2, 757)/  64.001/
          data  Nep(1, 758)/ 768.000/,Nep(2, 758)/  63.978/
          data  Nep(1, 759)/ 769.000/,Nep(2, 759)/  63.954/
          data  Nep(1, 760)/ 770.000/,Nep(2, 760)/  63.931/
          data  Nep(1, 761)/ 771.000/,Nep(2, 761)/  63.907/
          data  Nep(1, 762)/ 772.000/,Nep(2, 762)/  63.883/
          data  Nep(1, 763)/ 773.000/,Nep(2, 763)/  63.858/
          data  Nep(1, 764)/ 774.000/,Nep(2, 764)/  63.832/
          data  Nep(1, 765)/ 775.000/,Nep(2, 765)/  63.806/
          data  Nep(1, 766)/ 776.000/,Nep(2, 766)/  63.780/
          data  Nep(1, 767)/ 777.000/,Nep(2, 767)/  63.752/
          data  Nep(1, 768)/ 778.000/,Nep(2, 768)/  63.724/
          data  Nep(1, 769)/ 779.000/,Nep(2, 769)/  63.695/
          data  Nep(1, 770)/ 780.000/,Nep(2, 770)/  63.665/
          data  Nep(1, 771)/ 781.000/,Nep(2, 771)/  63.633/
          data  Nep(1, 772)/ 782.000/,Nep(2, 772)/  63.601/
          data  Nep(1, 773)/ 783.000/,Nep(2, 773)/  63.566/
          data  Nep(1, 774)/ 784.000/,Nep(2, 774)/  63.529/
          data  Nep(1, 775)/ 785.000/,Nep(2, 775)/  63.490/
          data  Nep(1, 776)/ 786.000/,Nep(2, 776)/  63.448/
          data  Nep(1, 777)/ 787.000/,Nep(2, 777)/  63.402/
          data  Nep(1, 778)/ 788.000/,Nep(2, 778)/  63.353/
          data  Nep(1, 779)/ 789.000/,Nep(2, 779)/  63.299/
          data  Nep(1, 780)/ 790.000/,Nep(2, 780)/  63.238/
          data  Nep(1, 781)/ 791.000/,Nep(2, 781)/  63.171/
          data  Nep(1, 782)/ 792.000/,Nep(2, 782)/  63.094/
          data  Nep(1, 783)/ 793.000/,Nep(2, 783)/  63.006/
          data  Nep(1, 784)/ 794.000/,Nep(2, 784)/  62.902/
          data  Nep(1, 785)/ 795.000/,Nep(2, 785)/  62.780/
          data  Nep(1, 786)/ 796.000/,Nep(2, 786)/  62.633/
          data  Nep(1, 787)/ 797.000/,Nep(2, 787)/  62.453/
          data  Nep(1, 788)/ 798.000/,Nep(2, 788)/  62.229/
          data  Nep(1, 789)/ 799.000/,Nep(2, 789)/  61.943/
          data  Nep(1, 790)/ 800.000/,Nep(2, 790)/  61.570/
          data  Nep(1, 791)/ 801.000/,Nep(2, 791)/  61.074/
          data  Nep(1, 792)/ 802.000/,Nep(2, 792)/  60.396/
          data  Nep(1, 793)/ 803.000/,Nep(2, 793)/  59.448/
          data  Nep(1, 794)/ 804.000/,Nep(2, 794)/  58.100/
          data  Nep(1, 795)/ 805.000/,Nep(2, 795)/  56.212/
          data  Nep(1, 796)/ 806.000/,Nep(2, 796)/  54.270/
          data  Nep(1, 797)/ 807.000/,Nep(2, 797)/  54.897/
          data  Nep(1, 798)/ 808.000/,Nep(2, 798)/  55.532/
          data  Nep(1, 799)/ 809.000/,Nep(2, 799)/  57.563/
          data  Nep(1, 800)/ 810.000/,Nep(2, 800)/  59.036/
          data  Nep(1, 801)/ 811.000/,Nep(2, 801)/  60.058/
          data  Nep(1, 802)/ 812.000/,Nep(2, 802)/  60.772/
          data  Nep(1, 803)/ 813.000/,Nep(2, 803)/  61.280/
          data  Nep(1, 804)/ 814.000/,Nep(2, 804)/  61.648/
          data  Nep(1, 805)/ 815.000/,Nep(2, 805)/  61.920/
          data  Nep(1, 806)/ 816.000/,Nep(2, 806)/  62.123/
          data  Nep(1, 807)/ 817.000/,Nep(2, 807)/  62.277/
          data  Nep(1, 808)/ 818.000/,Nep(2, 808)/  62.396/
          data  Nep(1, 809)/ 819.000/,Nep(2, 809)/  62.487/
          data  Nep(1, 810)/ 820.000/,Nep(2, 810)/  62.558/
          data  Nep(1, 811)/ 821.000/,Nep(2, 811)/  62.613/
          data  Nep(1, 812)/ 822.000/,Nep(2, 812)/  62.657/
          data  Nep(1, 813)/ 823.000/,Nep(2, 813)/  62.690/
          data  Nep(1, 814)/ 824.000/,Nep(2, 814)/  62.716/
          data  Nep(1, 815)/ 825.000/,Nep(2, 815)/  62.735/
          data  Nep(1, 816)/ 826.000/,Nep(2, 816)/  62.750/
          data  Nep(1, 817)/ 827.000/,Nep(2, 817)/  62.760/
          data  Nep(1, 818)/ 828.000/,Nep(2, 818)/  62.767/
          data  Nep(1, 819)/ 829.000/,Nep(2, 819)/  62.771/
          data  Nep(1, 820)/ 830.000/,Nep(2, 820)/  62.772/
          data  Nep(1, 821)/ 831.000/,Nep(2, 821)/  62.772/
          data  Nep(1, 822)/ 832.000/,Nep(2, 822)/  62.769/
          data  Nep(1, 823)/ 833.000/,Nep(2, 823)/  62.765/
          data  Nep(1, 824)/ 834.000/,Nep(2, 824)/  62.760/
          data  Nep(1, 825)/ 835.000/,Nep(2, 825)/  62.754/
          data  Nep(1, 826)/ 836.000/,Nep(2, 826)/  62.747/
          data  Nep(1, 827)/ 837.000/,Nep(2, 827)/  62.739/
          data  Nep(1, 828)/ 838.000/,Nep(2, 828)/  62.730/
          data  Nep(1, 829)/ 839.000/,Nep(2, 829)/  62.721/
          data  Nep(1, 830)/ 840.000/,Nep(2, 830)/  62.711/
          data  Nep(1, 831)/ 841.000/,Nep(2, 831)/  62.700/
          data  Nep(1, 832)/ 842.000/,Nep(2, 832)/  62.689/
          data  Nep(1, 833)/ 843.000/,Nep(2, 833)/  62.678/
          data  Nep(1, 834)/ 844.000/,Nep(2, 834)/  62.666/
          data  Nep(1, 835)/ 845.000/,Nep(2, 835)/  62.654/
          data  Nep(1, 836)/ 846.000/,Nep(2, 836)/  62.642/
          data  Nep(1, 837)/ 847.000/,Nep(2, 837)/  62.630/
          data  Nep(1, 838)/ 848.000/,Nep(2, 838)/  62.617/
          data  Nep(1, 839)/ 849.000/,Nep(2, 839)/  62.604/
          data  Nep(1, 840)/ 850.000/,Nep(2, 840)/  62.591/
          data  Nep(1, 841)/ 851.000/,Nep(2, 841)/  62.578/
          data  Nep(1, 842)/ 852.000/,Nep(2, 842)/  62.565/
          data  Nep(1, 843)/ 853.000/,Nep(2, 843)/  62.551/
          data  Nep(1, 844)/ 854.000/,Nep(2, 844)/  62.538/
          data  Nep(1, 845)/ 855.000/,Nep(2, 845)/  62.524/
          data  Nep(1, 846)/ 856.000/,Nep(2, 846)/  62.510/
          data  Nep(1, 847)/ 857.000/,Nep(2, 847)/  62.496/
          data  Nep(1, 848)/ 858.000/,Nep(2, 848)/  62.482/
          data  Nep(1, 849)/ 859.000/,Nep(2, 849)/  62.468/
          data  Nep(1, 850)/ 860.000/,Nep(2, 850)/  62.453/
          data  Nep(1, 851)/ 861.000/,Nep(2, 851)/  62.439/
          data  Nep(1, 852)/ 862.000/,Nep(2, 852)/  62.425/
          data  Nep(1, 853)/ 863.000/,Nep(2, 853)/  62.410/
          data  Nep(1, 854)/ 864.000/,Nep(2, 854)/  62.396/
          data  Nep(1, 855)/ 865.000/,Nep(2, 855)/  62.381/
          data  Nep(1, 856)/ 866.000/,Nep(2, 856)/  62.367/
          data  Nep(1, 857)/ 867.000/,Nep(2, 857)/  62.352/
          data  Nep(1, 858)/ 868.000/,Nep(2, 858)/  62.337/
          data  Nep(1, 859)/ 869.000/,Nep(2, 859)/  62.323/
          data  Nep(1, 860)/ 870.000/,Nep(2, 860)/  62.308/
          data  Nep(1, 861)/ 871.000/,Nep(2, 861)/  62.293/
          data  Nep(1, 862)/ 872.000/,Nep(2, 862)/  62.278/
          data  Nep(1, 863)/ 873.000/,Nep(2, 863)/  62.263/
          data  Nep(1, 864)/ 874.000/,Nep(2, 864)/  62.247/
          data  Nep(1, 865)/ 875.000/,Nep(2, 865)/  62.232/
          data  Nep(1, 866)/ 876.000/,Nep(2, 866)/  62.217/
          data  Nep(1, 867)/ 877.000/,Nep(2, 867)/  62.201/
          data  Nep(1, 868)/ 878.000/,Nep(2, 868)/  62.186/
          data  Nep(1, 869)/ 879.000/,Nep(2, 869)/  62.170/
          data  Nep(1, 870)/ 880.000/,Nep(2, 870)/  62.155/
          data  Nep(1, 871)/ 881.000/,Nep(2, 871)/  62.139/
          data  Nep(1, 872)/ 882.000/,Nep(2, 872)/  62.123/
          data  Nep(1, 873)/ 883.000/,Nep(2, 873)/  62.107/
          data  Nep(1, 874)/ 884.000/,Nep(2, 874)/  62.090/
          data  Nep(1, 875)/ 885.000/,Nep(2, 875)/  62.074/
          data  Nep(1, 876)/ 886.000/,Nep(2, 876)/  62.057/
          data  Nep(1, 877)/ 887.000/,Nep(2, 877)/  62.040/
          data  Nep(1, 878)/ 888.000/,Nep(2, 878)/  62.023/
          data  Nep(1, 879)/ 889.000/,Nep(2, 879)/  62.005/
          data  Nep(1, 880)/ 890.000/,Nep(2, 880)/  61.987/
          data  Nep(1, 881)/ 891.000/,Nep(2, 881)/  61.969/
          data  Nep(1, 882)/ 892.000/,Nep(2, 882)/  61.951/
          data  Nep(1, 883)/ 893.000/,Nep(2, 883)/  61.931/
          data  Nep(1, 884)/ 894.000/,Nep(2, 884)/  61.911/
          data  Nep(1, 885)/ 895.000/,Nep(2, 885)/  61.891/
          data  Nep(1, 886)/ 896.000/,Nep(2, 886)/  61.870/
          data  Nep(1, 887)/ 897.000/,Nep(2, 887)/  61.848/
          data  Nep(1, 888)/ 898.000/,Nep(2, 888)/  61.825/
          data  Nep(1, 889)/ 899.000/,Nep(2, 889)/  61.801/
          data  Nep(1, 890)/ 900.000/,Nep(2, 890)/  61.775/
          data  Nep(1, 891)/ 901.000/,Nep(2, 891)/  61.747/
          data  Nep(1, 892)/ 902.000/,Nep(2, 892)/  61.718/
          data  Nep(1, 893)/ 903.000/,Nep(2, 893)/  61.686/
          data  Nep(1, 894)/ 904.000/,Nep(2, 894)/  61.652/
          data  Nep(1, 895)/ 905.000/,Nep(2, 895)/  61.614/
          data  Nep(1, 896)/ 906.000/,Nep(2, 896)/  61.572/
          data  Nep(1, 897)/ 907.000/,Nep(2, 897)/  61.524/
          data  Nep(1, 898)/ 908.000/,Nep(2, 898)/  61.470/
          data  Nep(1, 899)/ 909.000/,Nep(2, 899)/  61.406/
          data  Nep(1, 900)/ 910.000/,Nep(2, 900)/  61.332/
          data  Nep(1, 901)/ 911.000/,Nep(2, 901)/  61.243/
          data  Nep(1, 902)/ 912.000/,Nep(2, 902)/  61.134/
          data  Nep(1, 903)/ 913.000/,Nep(2, 903)/  60.999/
          data  Nep(1, 904)/ 914.000/,Nep(2, 904)/  60.826/
          data  Nep(1, 905)/ 915.000/,Nep(2, 905)/  60.600/
          data  Nep(1, 906)/ 916.000/,Nep(2, 906)/  60.296/
          data  Nep(1, 907)/ 917.000/,Nep(2, 907)/  59.873/
          data  Nep(1, 908)/ 918.000/,Nep(2, 908)/  59.266/
          data  Nep(1, 909)/ 919.000/,Nep(2, 909)/  58.363/
          data  Nep(1, 910)/ 920.000/,Nep(2, 910)/  56.987/
          data  Nep(1, 911)/ 921.000/,Nep(2, 911)/  55.087/
          data  Nep(1, 912)/ 922.000/,Nep(2, 912)/  56.748/
          data  Nep(1, 913)/ 923.000/,Nep(2, 913)/  55.839/
          data  Nep(1, 914)/ 924.000/,Nep(2, 914)/  57.514/
          data  Nep(1, 915)/ 925.000/,Nep(2, 915)/  58.575/
          data  Nep(1, 916)/ 926.000/,Nep(2, 916)/  59.193/
          data  Nep(1, 917)/ 927.000/,Nep(2, 917)/  59.485/
          data  Nep(1, 918)/ 928.000/,Nep(2, 918)/  59.455/
          data  Nep(1, 919)/ 929.000/,Nep(2, 919)/  58.922/
          data  Nep(1, 920)/ 930.000/,Nep(2, 920)/  58.074/
          data  Nep(1, 921)/ 931.000/,Nep(2, 921)/  58.866/
          data  Nep(1, 922)/ 932.000/,Nep(2, 922)/  59.868/
          data  Nep(1, 923)/ 933.000/,Nep(2, 923)/  60.363/
          data  Nep(1, 924)/ 934.000/,Nep(2, 924)/  60.643/
          data  Nep(1, 925)/ 935.000/,Nep(2, 925)/  60.817/
          data  Nep(1, 926)/ 936.000/,Nep(2, 926)/  60.932/
          data  Nep(1, 927)/ 937.000/,Nep(2, 927)/  61.012/
          data  Nep(1, 928)/ 938.000/,Nep(2, 928)/  61.069/
          data  Nep(1, 929)/ 939.000/,Nep(2, 929)/  61.111/
          data  Nep(1, 930)/ 940.000/,Nep(2, 930)/  61.141/
          data  Nep(1, 931)/ 941.000/,Nep(2, 931)/  61.163/
          data  Nep(1, 932)/ 942.000/,Nep(2, 932)/  61.179/
          data  Nep(1, 933)/ 943.000/,Nep(2, 933)/  61.191/
          data  Nep(1, 934)/ 944.000/,Nep(2, 934)/  61.198/
          data  Nep(1, 935)/ 945.000/,Nep(2, 935)/  61.203/
          data  Nep(1, 936)/ 946.000/,Nep(2, 936)/  61.206/
          data  Nep(1, 937)/ 947.000/,Nep(2, 937)/  61.207/
          data  Nep(1, 938)/ 948.000/,Nep(2, 938)/  61.206/
          data  Nep(1, 939)/ 949.000/,Nep(2, 939)/  61.203/
          data  Nep(1, 940)/ 950.000/,Nep(2, 940)/  61.200/
          data  Nep(1, 941)/ 951.000/,Nep(2, 941)/  61.196/
          data  Nep(1, 942)/ 952.000/,Nep(2, 942)/  61.191/
          data  Nep(1, 943)/ 953.000/,Nep(2, 943)/  61.185/
          data  Nep(1, 944)/ 954.000/,Nep(2, 944)/  61.179/
          data  Nep(1, 945)/ 955.000/,Nep(2, 945)/  61.172/
          data  Nep(1, 946)/ 956.000/,Nep(2, 946)/  61.165/
          data  Nep(1, 947)/ 957.000/,Nep(2, 947)/  61.157/
          data  Nep(1, 948)/ 958.000/,Nep(2, 948)/  61.149/
          data  Nep(1, 949)/ 959.000/,Nep(2, 949)/  61.141/
          data  Nep(1, 950)/ 960.000/,Nep(2, 950)/  61.132/
          data  Nep(1, 951)/ 961.000/,Nep(2, 951)/  61.123/
          data  Nep(1, 952)/ 962.000/,Nep(2, 952)/  61.114/
          data  Nep(1, 953)/ 963.000/,Nep(2, 953)/  61.105/
          data  Nep(1, 954)/ 964.000/,Nep(2, 954)/  61.096/
          data  Nep(1, 955)/ 965.000/,Nep(2, 955)/  61.086/
          data  Nep(1, 956)/ 966.000/,Nep(2, 956)/  61.077/
          data  Nep(1, 957)/ 967.000/,Nep(2, 957)/  61.067/
          data  Nep(1, 958)/ 968.000/,Nep(2, 958)/  61.057/
          data  Nep(1, 959)/ 969.000/,Nep(2, 959)/  61.047/
          data  Nep(1, 960)/ 970.000/,Nep(2, 960)/  61.037/
          data  Nep(1, 961)/ 971.000/,Nep(2, 961)/  61.027/
          data  Nep(1, 962)/ 972.000/,Nep(2, 962)/  61.017/
          data  Nep(1, 963)/ 973.000/,Nep(2, 963)/  61.007/
          data  Nep(1, 964)/ 974.000/,Nep(2, 964)/  60.996/
          data  Nep(1, 965)/ 975.000/,Nep(2, 965)/  60.986/
          data  Nep(1, 966)/ 976.000/,Nep(2, 966)/  60.975/
          data  Nep(1, 967)/ 977.000/,Nep(2, 967)/  60.965/
          data  Nep(1, 968)/ 978.000/,Nep(2, 968)/  60.954/
          data  Nep(1, 969)/ 979.000/,Nep(2, 969)/  60.944/
          data  Nep(1, 970)/ 980.000/,Nep(2, 970)/  60.933/
          data  Nep(1, 971)/ 981.000/,Nep(2, 971)/  60.923/
          data  Nep(1, 972)/ 982.000/,Nep(2, 972)/  60.912/
          data  Nep(1, 973)/ 983.000/,Nep(2, 973)/  60.901/
          data  Nep(1, 974)/ 984.000/,Nep(2, 974)/  60.890/
          data  Nep(1, 975)/ 985.000/,Nep(2, 975)/  60.880/
          data  Nep(1, 976)/ 986.000/,Nep(2, 976)/  60.869/
          data  Nep(1, 977)/ 987.000/,Nep(2, 977)/  60.858/
          data  Nep(1, 978)/ 988.000/,Nep(2, 978)/  60.847/
          data  Nep(1, 979)/ 989.000/,Nep(2, 979)/  60.836/
          data  Nep(1, 980)/ 990.000/,Nep(2, 980)/  60.825/
          data  Nep(1, 981)/ 991.000/,Nep(2, 981)/  60.814/
          data  Nep(1, 982)/ 992.000/,Nep(2, 982)/  60.803/
          data  Nep(1, 983)/ 993.000/,Nep(2, 983)/  60.792/
          data  Nep(1, 984)/ 994.000/,Nep(2, 984)/  60.781/
          data  Nep(1, 985)/ 995.000/,Nep(2, 985)/  60.770/
          data  Nep(1, 986)/ 996.000/,Nep(2, 986)/  60.759/
          data  Nep(1, 987)/ 997.000/,Nep(2, 987)/  60.748/
          data  Nep(1, 988)/ 998.000/,Nep(2, 988)/  60.736/
          data  Nep(1, 989)/ 999.000/,Nep(2, 989)/  60.725/
          data  Nep(1, 990)/1000.000/,Nep(2, 990)/  60.713/
c++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c!Titan Spectrum - Mark Gurwell's planet model
c!Basic continuum model using Courtin's N2 abs.
c!                       Freq(GHz)    WDTB(Kelvin)     
          data  Tit(1,   1)/  11.000/,Tit(2,   1)/  89.582/
          data  Tit(1,   2)/  12.000/,Tit(2,   2)/  89.713/
          data  Tit(1,   3)/  13.000/,Tit(2,   3)/  89.846/
          data  Tit(1,   4)/  14.000/,Tit(2,   4)/  89.980/
          data  Tit(1,   5)/  15.000/,Tit(2,   5)/  90.113/
          data  Tit(1,   6)/  16.000/,Tit(2,   6)/  90.244/
          data  Tit(1,   7)/  17.000/,Tit(2,   7)/  90.371/
          data  Tit(1,   8)/  18.000/,Tit(2,   8)/  90.495/
          data  Tit(1,   9)/  19.000/,Tit(2,   9)/  90.613/
          data  Tit(1,  10)/  20.000/,Tit(2,  10)/  90.725/
          data  Tit(1,  11)/  21.000/,Tit(2,  11)/  90.831/
          data  Tit(1,  12)/  22.000/,Tit(2,  12)/  90.930/
          data  Tit(1,  13)/  23.000/,Tit(2,  13)/  91.022/
          data  Tit(1,  14)/  24.000/,Tit(2,  14)/  91.106/
          data  Tit(1,  15)/  25.000/,Tit(2,  15)/  91.182/
          data  Tit(1,  16)/  26.000/,Tit(2,  16)/  91.250/
          data  Tit(1,  17)/  27.000/,Tit(2,  17)/  91.310/
          data  Tit(1,  18)/  28.000/,Tit(2,  18)/  91.361/
          data  Tit(1,  19)/  29.000/,Tit(2,  19)/  91.405/
          data  Tit(1,  20)/  30.000/,Tit(2,  20)/  91.440/
          data  Tit(1,  21)/  31.000/,Tit(2,  21)/  91.467/
          data  Tit(1,  22)/  32.000/,Tit(2,  22)/  91.486/
          data  Tit(1,  23)/  33.000/,Tit(2,  23)/  91.497/
          data  Tit(1,  24)/  34.000/,Tit(2,  24)/  91.500/
          data  Tit(1,  25)/  35.000/,Tit(2,  25)/  91.496/
          data  Tit(1,  26)/  36.000/,Tit(2,  26)/  91.484/
          data  Tit(1,  27)/  37.000/,Tit(2,  27)/  91.465/
          data  Tit(1,  28)/  38.000/,Tit(2,  28)/  91.439/
          data  Tit(1,  29)/  39.000/,Tit(2,  29)/  91.406/
          data  Tit(1,  30)/  40.000/,Tit(2,  30)/  91.368/
          data  Tit(1,  31)/  41.000/,Tit(2,  31)/  91.322/
          data  Tit(1,  32)/  42.000/,Tit(2,  32)/  91.270/
          data  Tit(1,  33)/  43.000/,Tit(2,  33)/  91.213/
          data  Tit(1,  34)/  44.000/,Tit(2,  34)/  91.149/
          data  Tit(1,  35)/  45.000/,Tit(2,  35)/  91.081/
          data  Tit(1,  36)/  46.000/,Tit(2,  36)/  91.008/
          data  Tit(1,  37)/  47.000/,Tit(2,  37)/  90.930/
          data  Tit(1,  38)/  48.000/,Tit(2,  38)/  90.846/
          data  Tit(1,  39)/  49.000/,Tit(2,  39)/  90.759/
          data  Tit(1,  40)/  50.000/,Tit(2,  40)/  90.667/
          data  Tit(1,  41)/  51.000/,Tit(2,  41)/  90.572/
          data  Tit(1,  42)/  52.000/,Tit(2,  42)/  90.473/
          data  Tit(1,  43)/  53.000/,Tit(2,  43)/  90.370/
          data  Tit(1,  44)/  54.000/,Tit(2,  44)/  90.264/
          data  Tit(1,  45)/  55.000/,Tit(2,  45)/  90.155/
          data  Tit(1,  46)/  56.000/,Tit(2,  46)/  90.043/
          data  Tit(1,  47)/  57.000/,Tit(2,  47)/  89.929/
          data  Tit(1,  48)/  58.000/,Tit(2,  48)/  89.812/
          data  Tit(1,  49)/  59.000/,Tit(2,  49)/  89.693/
          data  Tit(1,  50)/  60.000/,Tit(2,  50)/  89.571/
          data  Tit(1,  51)/  61.000/,Tit(2,  51)/  89.448/
          data  Tit(1,  52)/  62.000/,Tit(2,  52)/  89.323/
          data  Tit(1,  53)/  63.000/,Tit(2,  53)/  89.196/
          data  Tit(1,  54)/  64.000/,Tit(2,  54)/  89.068/
          data  Tit(1,  55)/  65.000/,Tit(2,  55)/  88.939/
          data  Tit(1,  56)/  66.000/,Tit(2,  56)/  88.808/
          data  Tit(1,  57)/  67.000/,Tit(2,  57)/  88.677/
          data  Tit(1,  58)/  68.000/,Tit(2,  58)/  88.545/
          data  Tit(1,  59)/  69.000/,Tit(2,  59)/  88.412/
          data  Tit(1,  60)/  70.000/,Tit(2,  60)/  88.279/
          data  Tit(1,  61)/  71.000/,Tit(2,  61)/  88.145/
          data  Tit(1,  62)/  72.000/,Tit(2,  62)/  88.010/
          data  Tit(1,  63)/  73.000/,Tit(2,  63)/  87.876/
          data  Tit(1,  64)/  74.000/,Tit(2,  64)/  87.741/
          data  Tit(1,  65)/  75.000/,Tit(2,  65)/  87.607/
          data  Tit(1,  66)/  76.000/,Tit(2,  66)/  87.472/
          data  Tit(1,  67)/  77.000/,Tit(2,  67)/  87.338/
          data  Tit(1,  68)/  78.000/,Tit(2,  68)/  87.204/
          data  Tit(1,  69)/  79.000/,Tit(2,  69)/  87.070/
          data  Tit(1,  70)/  80.000/,Tit(2,  70)/  86.937/
          data  Tit(1,  71)/  81.000/,Tit(2,  71)/  86.804/
          data  Tit(1,  72)/  82.000/,Tit(2,  72)/  86.671/
          data  Tit(1,  73)/  83.000/,Tit(2,  73)/  86.540/
          data  Tit(1,  74)/  84.000/,Tit(2,  74)/  86.409/
          data  Tit(1,  75)/  85.000/,Tit(2,  75)/  86.278/
          data  Tit(1,  76)/  86.000/,Tit(2,  76)/  86.149/
          data  Tit(1,  77)/  87.000/,Tit(2,  77)/  86.020/
          data  Tit(1,  78)/  88.000/,Tit(2,  78)/  85.893/
          data  Tit(1,  79)/  89.000/,Tit(2,  79)/  85.766/
          data  Tit(1,  80)/  90.000/,Tit(2,  80)/  85.640/
          data  Tit(1,  81)/  91.000/,Tit(2,  81)/  85.515/
          data  Tit(1,  82)/  92.000/,Tit(2,  82)/  85.392/
          data  Tit(1,  83)/  93.000/,Tit(2,  83)/  85.269/
          data  Tit(1,  84)/  94.000/,Tit(2,  84)/  85.148/
          data  Tit(1,  85)/  95.000/,Tit(2,  85)/  85.027/
          data  Tit(1,  86)/  96.000/,Tit(2,  86)/  84.908/
          data  Tit(1,  87)/  97.000/,Tit(2,  87)/  84.790/
          data  Tit(1,  88)/  98.000/,Tit(2,  88)/  84.673/
          data  Tit(1,  89)/  99.000/,Tit(2,  89)/  84.558/
          data  Tit(1,  90)/ 100.000/,Tit(2,  90)/  84.443/
          data  Tit(1,  91)/ 101.000/,Tit(2,  91)/  84.330/
          data  Tit(1,  92)/ 102.000/,Tit(2,  92)/  84.218/
          data  Tit(1,  93)/ 103.000/,Tit(2,  93)/  84.108/
          data  Tit(1,  94)/ 104.000/,Tit(2,  94)/  83.999/
          data  Tit(1,  95)/ 105.000/,Tit(2,  95)/  83.891/
          data  Tit(1,  96)/ 106.000/,Tit(2,  96)/  83.784/
          data  Tit(1,  97)/ 107.000/,Tit(2,  97)/  83.679/
          data  Tit(1,  98)/ 108.000/,Tit(2,  98)/  83.575/
          data  Tit(1,  99)/ 109.000/,Tit(2,  99)/  83.472/
          data  Tit(1, 100)/ 110.000/,Tit(2, 100)/  83.371/
          data  Tit(1, 101)/ 111.000/,Tit(2, 101)/  83.271/
          data  Tit(1, 102)/ 112.000/,Tit(2, 102)/  83.172/
          data  Tit(1, 103)/ 113.000/,Tit(2, 103)/  83.074/
          data  Tit(1, 104)/ 114.000/,Tit(2, 104)/  82.978/
          data  Tit(1, 105)/ 115.000/,Tit(2, 105)/  82.883/
          data  Tit(1, 106)/ 116.000/,Tit(2, 106)/  82.790/
          data  Tit(1, 107)/ 117.000/,Tit(2, 107)/  82.697/
          data  Tit(1, 108)/ 118.000/,Tit(2, 108)/  82.606/
          data  Tit(1, 109)/ 119.000/,Tit(2, 109)/  82.516/
          data  Tit(1, 110)/ 120.000/,Tit(2, 110)/  82.428/
          data  Tit(1, 111)/ 121.000/,Tit(2, 111)/  82.341/
          data  Tit(1, 112)/ 122.000/,Tit(2, 112)/  82.255/
          data  Tit(1, 113)/ 123.000/,Tit(2, 113)/  82.170/
          data  Tit(1, 114)/ 124.000/,Tit(2, 114)/  82.086/
          data  Tit(1, 115)/ 125.000/,Tit(2, 115)/  82.003/
          data  Tit(1, 116)/ 126.000/,Tit(2, 116)/  81.922/
          data  Tit(1, 117)/ 127.000/,Tit(2, 117)/  81.842/
          data  Tit(1, 118)/ 128.000/,Tit(2, 118)/  81.763/
          data  Tit(1, 119)/ 129.000/,Tit(2, 119)/  81.685/
          data  Tit(1, 120)/ 130.000/,Tit(2, 120)/  81.608/
          data  Tit(1, 121)/ 131.000/,Tit(2, 121)/  81.533/
          data  Tit(1, 122)/ 132.000/,Tit(2, 122)/  81.458/
          data  Tit(1, 123)/ 133.000/,Tit(2, 123)/  81.385/
          data  Tit(1, 124)/ 134.000/,Tit(2, 124)/  81.312/
          data  Tit(1, 125)/ 135.000/,Tit(2, 125)/  81.242/
          data  Tit(1, 126)/ 136.000/,Tit(2, 126)/  81.171/
          data  Tit(1, 127)/ 137.000/,Tit(2, 127)/  81.102/
          data  Tit(1, 128)/ 138.000/,Tit(2, 128)/  81.034/
          data  Tit(1, 129)/ 139.000/,Tit(2, 129)/  80.966/
          data  Tit(1, 130)/ 140.000/,Tit(2, 130)/  80.901/
          data  Tit(1, 131)/ 141.000/,Tit(2, 131)/  80.835/
          data  Tit(1, 132)/ 142.000/,Tit(2, 132)/  80.771/
          data  Tit(1, 133)/ 143.000/,Tit(2, 133)/  80.708/
          data  Tit(1, 134)/ 144.000/,Tit(2, 134)/  80.645/
          data  Tit(1, 135)/ 145.000/,Tit(2, 135)/  80.584/
          data  Tit(1, 136)/ 146.000/,Tit(2, 136)/  80.523/
          data  Tit(1, 137)/ 147.000/,Tit(2, 137)/  80.464/
          data  Tit(1, 138)/ 148.000/,Tit(2, 138)/  80.405/
          data  Tit(1, 139)/ 149.000/,Tit(2, 139)/  80.347/
          data  Tit(1, 140)/ 150.000/,Tit(2, 140)/  80.290/
          data  Tit(1, 141)/ 151.000/,Tit(2, 141)/  80.234/
          data  Tit(1, 142)/ 152.000/,Tit(2, 142)/  80.179/
          data  Tit(1, 143)/ 153.000/,Tit(2, 143)/  80.124/
          data  Tit(1, 144)/ 154.000/,Tit(2, 144)/  80.071/
          data  Tit(1, 145)/ 155.000/,Tit(2, 145)/  80.018/
          data  Tit(1, 146)/ 156.000/,Tit(2, 146)/  79.965/
          data  Tit(1, 147)/ 157.000/,Tit(2, 147)/  79.914/
          data  Tit(1, 148)/ 158.000/,Tit(2, 148)/  79.863/
          data  Tit(1, 149)/ 159.000/,Tit(2, 149)/  79.813/
          data  Tit(1, 150)/ 160.000/,Tit(2, 150)/  79.765/
          data  Tit(1, 151)/ 161.000/,Tit(2, 151)/  79.716/
          data  Tit(1, 152)/ 162.000/,Tit(2, 152)/  79.668/
          data  Tit(1, 153)/ 163.000/,Tit(2, 153)/  79.621/
          data  Tit(1, 154)/ 164.000/,Tit(2, 154)/  79.575/
          data  Tit(1, 155)/ 165.000/,Tit(2, 155)/  79.529/
          data  Tit(1, 156)/ 166.000/,Tit(2, 156)/  79.484/
          data  Tit(1, 157)/ 167.000/,Tit(2, 157)/  79.439/
          data  Tit(1, 158)/ 168.000/,Tit(2, 158)/  79.396/
          data  Tit(1, 159)/ 169.000/,Tit(2, 159)/  79.352/
          data  Tit(1, 160)/ 170.000/,Tit(2, 160)/  79.310/
          data  Tit(1, 161)/ 171.000/,Tit(2, 161)/  79.268/
          data  Tit(1, 162)/ 172.000/,Tit(2, 162)/  79.227/
          data  Tit(1, 163)/ 173.000/,Tit(2, 163)/  79.186/
          data  Tit(1, 164)/ 174.000/,Tit(2, 164)/  79.146/
          data  Tit(1, 165)/ 175.000/,Tit(2, 165)/  79.106/
          data  Tit(1, 166)/ 176.000/,Tit(2, 166)/  79.067/
          data  Tit(1, 167)/ 177.000/,Tit(2, 167)/  79.029/
          data  Tit(1, 168)/ 178.000/,Tit(2, 168)/  78.991/
          data  Tit(1, 169)/ 179.000/,Tit(2, 169)/  78.953/
          data  Tit(1, 170)/ 180.000/,Tit(2, 170)/  78.916/
          data  Tit(1, 171)/ 181.000/,Tit(2, 171)/  78.880/
          data  Tit(1, 172)/ 182.000/,Tit(2, 172)/  78.844/
          data  Tit(1, 173)/ 183.000/,Tit(2, 173)/  78.808/
          data  Tit(1, 174)/ 184.000/,Tit(2, 174)/  78.774/
          data  Tit(1, 175)/ 185.000/,Tit(2, 175)/  78.739/
          data  Tit(1, 176)/ 186.000/,Tit(2, 176)/  78.705/
          data  Tit(1, 177)/ 187.000/,Tit(2, 177)/  78.672/
          data  Tit(1, 178)/ 188.000/,Tit(2, 178)/  78.639/
          data  Tit(1, 179)/ 189.000/,Tit(2, 179)/  78.606/
          data  Tit(1, 180)/ 190.000/,Tit(2, 180)/  78.574/
          data  Tit(1, 181)/ 191.000/,Tit(2, 181)/  78.542/
          data  Tit(1, 182)/ 192.000/,Tit(2, 182)/  78.511/
          data  Tit(1, 183)/ 193.000/,Tit(2, 183)/  78.480/
          data  Tit(1, 184)/ 194.000/,Tit(2, 184)/  78.449/
          data  Tit(1, 185)/ 195.000/,Tit(2, 185)/  78.419/
          data  Tit(1, 186)/ 196.000/,Tit(2, 186)/  78.390/
          data  Tit(1, 187)/ 197.000/,Tit(2, 187)/  78.361/
          data  Tit(1, 188)/ 198.000/,Tit(2, 188)/  78.332/
          data  Tit(1, 189)/ 199.000/,Tit(2, 189)/  78.303/
          data  Tit(1, 190)/ 200.000/,Tit(2, 190)/  78.275/
          data  Tit(1, 191)/ 201.000/,Tit(2, 191)/  78.247/
          data  Tit(1, 192)/ 202.000/,Tit(2, 192)/  78.220/
          data  Tit(1, 193)/ 203.000/,Tit(2, 193)/  78.193/
          data  Tit(1, 194)/ 204.000/,Tit(2, 194)/  78.167/
          data  Tit(1, 195)/ 205.000/,Tit(2, 195)/  78.140/
          data  Tit(1, 196)/ 206.000/,Tit(2, 196)/  78.114/
          data  Tit(1, 197)/ 207.000/,Tit(2, 197)/  78.089/
          data  Tit(1, 198)/ 208.000/,Tit(2, 198)/  78.063/
          data  Tit(1, 199)/ 209.000/,Tit(2, 199)/  78.038/
          data  Tit(1, 200)/ 210.000/,Tit(2, 200)/  78.014/
          data  Tit(1, 201)/ 211.000/,Tit(2, 201)/  77.990/
          data  Tit(1, 202)/ 212.000/,Tit(2, 202)/  77.966/
          data  Tit(1, 203)/ 213.000/,Tit(2, 203)/  77.942/
          data  Tit(1, 204)/ 214.000/,Tit(2, 204)/  77.918/
          data  Tit(1, 205)/ 215.000/,Tit(2, 205)/  77.895/
          data  Tit(1, 206)/ 216.000/,Tit(2, 206)/  77.873/
          data  Tit(1, 207)/ 217.000/,Tit(2, 207)/  77.850/
          data  Tit(1, 208)/ 218.000/,Tit(2, 208)/  77.828/
          data  Tit(1, 209)/ 219.000/,Tit(2, 209)/  77.806/
          data  Tit(1, 210)/ 220.000/,Tit(2, 210)/  77.784/
          data  Tit(1, 211)/ 221.000/,Tit(2, 211)/  77.763/
          data  Tit(1, 212)/ 222.000/,Tit(2, 212)/  77.742/
          data  Tit(1, 213)/ 223.000/,Tit(2, 213)/  77.721/
          data  Tit(1, 214)/ 224.000/,Tit(2, 214)/  77.701/
          data  Tit(1, 215)/ 225.000/,Tit(2, 215)/  77.680/
          data  Tit(1, 216)/ 226.000/,Tit(2, 216)/  77.660/
          data  Tit(1, 217)/ 227.000/,Tit(2, 217)/  77.641/
          data  Tit(1, 218)/ 228.000/,Tit(2, 218)/  77.621/
          data  Tit(1, 219)/ 229.000/,Tit(2, 219)/  77.602/
          data  Tit(1, 220)/ 230.000/,Tit(2, 220)/  77.583/
          data  Tit(1, 221)/ 231.000/,Tit(2, 221)/  77.564/
          data  Tit(1, 222)/ 232.000/,Tit(2, 222)/  77.545/
          data  Tit(1, 223)/ 233.000/,Tit(2, 223)/  77.527/
          data  Tit(1, 224)/ 234.000/,Tit(2, 224)/  77.509/
          data  Tit(1, 225)/ 235.000/,Tit(2, 225)/  77.491/
          data  Tit(1, 226)/ 236.000/,Tit(2, 226)/  77.473/
          data  Tit(1, 227)/ 237.000/,Tit(2, 227)/  77.456/
          data  Tit(1, 228)/ 238.000/,Tit(2, 228)/  77.439/
          data  Tit(1, 229)/ 239.000/,Tit(2, 229)/  77.422/
          data  Tit(1, 230)/ 240.000/,Tit(2, 230)/  77.405/
          data  Tit(1, 231)/ 241.000/,Tit(2, 231)/  77.388/
          data  Tit(1, 232)/ 242.000/,Tit(2, 232)/  77.372/
          data  Tit(1, 233)/ 243.000/,Tit(2, 233)/  77.356/
          data  Tit(1, 234)/ 244.000/,Tit(2, 234)/  77.340/
          data  Tit(1, 235)/ 245.000/,Tit(2, 235)/  77.324/
          data  Tit(1, 236)/ 246.000/,Tit(2, 236)/  77.309/
          data  Tit(1, 237)/ 247.000/,Tit(2, 237)/  77.293/
          data  Tit(1, 238)/ 248.000/,Tit(2, 238)/  77.278/
          data  Tit(1, 239)/ 249.000/,Tit(2, 239)/  77.263/
          data  Tit(1, 240)/ 250.000/,Tit(2, 240)/  77.248/
          data  Tit(1, 241)/ 251.000/,Tit(2, 241)/  77.234/
          data  Tit(1, 242)/ 252.000/,Tit(2, 242)/  77.219/
          data  Tit(1, 243)/ 253.000/,Tit(2, 243)/  77.205/
          data  Tit(1, 244)/ 254.000/,Tit(2, 244)/  77.191/
          data  Tit(1, 245)/ 255.000/,Tit(2, 245)/  77.177/
          data  Tit(1, 246)/ 256.000/,Tit(2, 246)/  77.164/
          data  Tit(1, 247)/ 257.000/,Tit(2, 247)/  77.150/
          data  Tit(1, 248)/ 258.000/,Tit(2, 248)/  77.137/
          data  Tit(1, 249)/ 259.000/,Tit(2, 249)/  77.124/
          data  Tit(1, 250)/ 260.000/,Tit(2, 250)/  77.111/
          data  Tit(1, 251)/ 261.000/,Tit(2, 251)/  77.098/
          data  Tit(1, 252)/ 262.000/,Tit(2, 252)/  77.085/
          data  Tit(1, 253)/ 263.000/,Tit(2, 253)/  77.072/
          data  Tit(1, 254)/ 264.000/,Tit(2, 254)/  77.060/
          data  Tit(1, 255)/ 265.000/,Tit(2, 255)/  77.048/
          data  Tit(1, 256)/ 266.000/,Tit(2, 256)/  77.036/
          data  Tit(1, 257)/ 267.000/,Tit(2, 257)/  77.024/
          data  Tit(1, 258)/ 268.000/,Tit(2, 258)/  77.012/
          data  Tit(1, 259)/ 269.000/,Tit(2, 259)/  77.001/
          data  Tit(1, 260)/ 270.000/,Tit(2, 260)/  76.989/
          data  Tit(1, 261)/ 271.000/,Tit(2, 261)/  76.978/
          data  Tit(1, 262)/ 272.000/,Tit(2, 262)/  76.967/
          data  Tit(1, 263)/ 273.000/,Tit(2, 263)/  76.956/
          data  Tit(1, 264)/ 274.000/,Tit(2, 264)/  76.945/
          data  Tit(1, 265)/ 275.000/,Tit(2, 265)/  76.934/
          data  Tit(1, 266)/ 276.000/,Tit(2, 266)/  76.924/
          data  Tit(1, 267)/ 277.000/,Tit(2, 267)/  76.913/
          data  Tit(1, 268)/ 278.000/,Tit(2, 268)/  76.903/
          data  Tit(1, 269)/ 279.000/,Tit(2, 269)/  76.893/
          data  Tit(1, 270)/ 280.000/,Tit(2, 270)/  76.883/
          data  Tit(1, 271)/ 281.000/,Tit(2, 271)/  76.873/
          data  Tit(1, 272)/ 282.000/,Tit(2, 272)/  76.863/
          data  Tit(1, 273)/ 283.000/,Tit(2, 273)/  76.853/
          data  Tit(1, 274)/ 284.000/,Tit(2, 274)/  76.844/
          data  Tit(1, 275)/ 285.000/,Tit(2, 275)/  76.834/
          data  Tit(1, 276)/ 286.000/,Tit(2, 276)/  76.825/
          data  Tit(1, 277)/ 287.000/,Tit(2, 277)/  76.816/
          data  Tit(1, 278)/ 288.000/,Tit(2, 278)/  76.807/
          data  Tit(1, 279)/ 289.000/,Tit(2, 279)/  76.798/
          data  Tit(1, 280)/ 290.000/,Tit(2, 280)/  76.789/
          data  Tit(1, 281)/ 291.000/,Tit(2, 281)/  76.781/
          data  Tit(1, 282)/ 292.000/,Tit(2, 282)/  76.772/
          data  Tit(1, 283)/ 293.000/,Tit(2, 283)/  76.764/
          data  Tit(1, 284)/ 294.000/,Tit(2, 284)/  76.755/
          data  Tit(1, 285)/ 295.000/,Tit(2, 285)/  76.747/
          data  Tit(1, 286)/ 296.000/,Tit(2, 286)/  76.739/
          data  Tit(1, 287)/ 297.000/,Tit(2, 287)/  76.731/
          data  Tit(1, 288)/ 298.000/,Tit(2, 288)/  76.724/
          data  Tit(1, 289)/ 299.000/,Tit(2, 289)/  76.716/
          data  Tit(1, 290)/ 300.000/,Tit(2, 290)/  76.708/
          data  Tit(1, 291)/ 301.000/,Tit(2, 291)/  76.701/
          data  Tit(1, 292)/ 302.000/,Tit(2, 292)/  76.693/
          data  Tit(1, 293)/ 303.000/,Tit(2, 293)/  76.686/
          data  Tit(1, 294)/ 304.000/,Tit(2, 294)/  76.679/
          data  Tit(1, 295)/ 305.000/,Tit(2, 295)/  76.672/
          data  Tit(1, 296)/ 306.000/,Tit(2, 296)/  76.664/
          data  Tit(1, 297)/ 307.000/,Tit(2, 297)/  76.658/
          data  Tit(1, 298)/ 308.000/,Tit(2, 298)/  76.651/
          data  Tit(1, 299)/ 309.000/,Tit(2, 299)/  76.644/
          data  Tit(1, 300)/ 310.000/,Tit(2, 300)/  76.638/
          data  Tit(1, 301)/ 311.000/,Tit(2, 301)/  76.631/
          data  Tit(1, 302)/ 312.000/,Tit(2, 302)/  76.625/
          data  Tit(1, 303)/ 313.000/,Tit(2, 303)/  76.618/
          data  Tit(1, 304)/ 314.000/,Tit(2, 304)/  76.612/
          data  Tit(1, 305)/ 315.000/,Tit(2, 305)/  76.606/
          data  Tit(1, 306)/ 316.000/,Tit(2, 306)/  76.600/
          data  Tit(1, 307)/ 317.000/,Tit(2, 307)/  76.594/
          data  Tit(1, 308)/ 318.000/,Tit(2, 308)/  76.588/
          data  Tit(1, 309)/ 319.000/,Tit(2, 309)/  76.583/
          data  Tit(1, 310)/ 320.000/,Tit(2, 310)/  76.577/
          data  Tit(1, 311)/ 321.000/,Tit(2, 311)/  76.571/
          data  Tit(1, 312)/ 322.000/,Tit(2, 312)/  76.566/
          data  Tit(1, 313)/ 323.000/,Tit(2, 313)/  76.561/
          data  Tit(1, 314)/ 324.000/,Tit(2, 314)/  76.555/
          data  Tit(1, 315)/ 325.000/,Tit(2, 315)/  76.550/
          data  Tit(1, 316)/ 326.000/,Tit(2, 316)/  76.545/
          data  Tit(1, 317)/ 327.000/,Tit(2, 317)/  76.540/
          data  Tit(1, 318)/ 328.000/,Tit(2, 318)/  76.535/
          data  Tit(1, 319)/ 329.000/,Tit(2, 319)/  76.530/
          data  Tit(1, 320)/ 330.000/,Tit(2, 320)/  76.525/
          data  Tit(1, 321)/ 331.000/,Tit(2, 321)/  76.521/
          data  Tit(1, 322)/ 332.000/,Tit(2, 322)/  76.516/
          data  Tit(1, 323)/ 333.000/,Tit(2, 323)/  76.511/
          data  Tit(1, 324)/ 334.000/,Tit(2, 324)/  76.507/
          data  Tit(1, 325)/ 335.000/,Tit(2, 325)/  76.503/
          data  Tit(1, 326)/ 336.000/,Tit(2, 326)/  76.498/
          data  Tit(1, 327)/ 337.000/,Tit(2, 327)/  76.494/
          data  Tit(1, 328)/ 338.000/,Tit(2, 328)/  76.490/
          data  Tit(1, 329)/ 339.000/,Tit(2, 329)/  76.486/
          data  Tit(1, 330)/ 340.000/,Tit(2, 330)/  76.482/
          data  Tit(1, 331)/ 341.000/,Tit(2, 331)/  76.478/
          data  Tit(1, 332)/ 342.000/,Tit(2, 332)/  76.474/
          data  Tit(1, 333)/ 343.000/,Tit(2, 333)/  76.470/
          data  Tit(1, 334)/ 344.000/,Tit(2, 334)/  76.467/
          data  Tit(1, 335)/ 345.000/,Tit(2, 335)/  76.463/
          data  Tit(1, 336)/ 346.000/,Tit(2, 336)/  76.460/
          data  Tit(1, 337)/ 347.000/,Tit(2, 337)/  76.456/
          data  Tit(1, 338)/ 348.000/,Tit(2, 338)/  76.453/
          data  Tit(1, 339)/ 349.000/,Tit(2, 339)/  76.449/
          data  Tit(1, 340)/ 350.000/,Tit(2, 340)/  76.446/
          data  Tit(1, 341)/ 351.000/,Tit(2, 341)/  76.443/
          data  Tit(1, 342)/ 352.000/,Tit(2, 342)/  76.440/
          data  Tit(1, 343)/ 353.000/,Tit(2, 343)/  76.437/
          data  Tit(1, 344)/ 354.000/,Tit(2, 344)/  76.434/
          data  Tit(1, 345)/ 355.000/,Tit(2, 345)/  76.431/
          data  Tit(1, 346)/ 356.000/,Tit(2, 346)/  76.428/
          data  Tit(1, 347)/ 357.000/,Tit(2, 347)/  76.425/
          data  Tit(1, 348)/ 358.000/,Tit(2, 348)/  76.422/
          data  Tit(1, 349)/ 359.000/,Tit(2, 349)/  76.420/
          data  Tit(1, 350)/ 360.000/,Tit(2, 350)/  76.417/
          data  Tit(1, 351)/ 361.000/,Tit(2, 351)/  76.414/
          data  Tit(1, 352)/ 362.000/,Tit(2, 352)/  76.412/
          data  Tit(1, 353)/ 363.000/,Tit(2, 353)/  76.409/
          data  Tit(1, 354)/ 364.000/,Tit(2, 354)/  76.407/
          data  Tit(1, 355)/ 365.000/,Tit(2, 355)/  76.405/
          data  Tit(1, 356)/ 366.000/,Tit(2, 356)/  76.403/
          data  Tit(1, 357)/ 367.000/,Tit(2, 357)/  76.400/
          data  Tit(1, 358)/ 368.000/,Tit(2, 358)/  76.398/
          data  Tit(1, 359)/ 369.000/,Tit(2, 359)/  76.396/
          data  Tit(1, 360)/ 370.000/,Tit(2, 360)/  76.394/
          data  Tit(1, 361)/ 371.000/,Tit(2, 361)/  76.392/
          data  Tit(1, 362)/ 372.000/,Tit(2, 362)/  76.390/
          data  Tit(1, 363)/ 373.000/,Tit(2, 363)/  76.389/
          data  Tit(1, 364)/ 374.000/,Tit(2, 364)/  76.387/
          data  Tit(1, 365)/ 375.000/,Tit(2, 365)/  76.385/
          data  Tit(1, 366)/ 376.000/,Tit(2, 366)/  76.383/
          data  Tit(1, 367)/ 377.000/,Tit(2, 367)/  76.382/
          data  Tit(1, 368)/ 378.000/,Tit(2, 368)/  76.380/
          data  Tit(1, 369)/ 379.000/,Tit(2, 369)/  76.379/
          data  Tit(1, 370)/ 380.000/,Tit(2, 370)/  76.377/
          data  Tit(1, 371)/ 381.000/,Tit(2, 371)/  76.376/
          data  Tit(1, 372)/ 382.000/,Tit(2, 372)/  76.375/
          data  Tit(1, 373)/ 383.000/,Tit(2, 373)/  76.373/
          data  Tit(1, 374)/ 384.000/,Tit(2, 374)/  76.372/
          data  Tit(1, 375)/ 385.000/,Tit(2, 375)/  76.371/
          data  Tit(1, 376)/ 386.000/,Tit(2, 376)/  76.370/
          data  Tit(1, 377)/ 387.000/,Tit(2, 377)/  76.369/
          data  Tit(1, 378)/ 388.000/,Tit(2, 378)/  76.368/
          data  Tit(1, 379)/ 389.000/,Tit(2, 379)/  76.367/
          data  Tit(1, 380)/ 390.000/,Tit(2, 380)/  76.366/
          data  Tit(1, 381)/ 391.000/,Tit(2, 381)/  76.365/
          data  Tit(1, 382)/ 392.000/,Tit(2, 382)/  76.364/
          data  Tit(1, 383)/ 393.000/,Tit(2, 383)/  76.364/
          data  Tit(1, 384)/ 394.000/,Tit(2, 384)/  76.363/
          data  Tit(1, 385)/ 395.000/,Tit(2, 385)/  76.362/
          data  Tit(1, 386)/ 396.000/,Tit(2, 386)/  76.361/
          data  Tit(1, 387)/ 397.000/,Tit(2, 387)/  76.361/
          data  Tit(1, 388)/ 398.000/,Tit(2, 388)/  76.360/
          data  Tit(1, 389)/ 399.000/,Tit(2, 389)/  76.360/
          data  Tit(1, 390)/ 400.000/,Tit(2, 390)/  76.360/
          data  Tit(1, 391)/ 401.000/,Tit(2, 391)/  76.359/
          data  Tit(1, 392)/ 402.000/,Tit(2, 392)/  76.359/
          data  Tit(1, 393)/ 403.000/,Tit(2, 393)/  76.359/
          data  Tit(1, 394)/ 404.000/,Tit(2, 394)/  76.358/
          data  Tit(1, 395)/ 405.000/,Tit(2, 395)/  76.358/
          data  Tit(1, 396)/ 406.000/,Tit(2, 396)/  76.358/
          data  Tit(1, 397)/ 407.000/,Tit(2, 397)/  76.358/
          data  Tit(1, 398)/ 408.000/,Tit(2, 398)/  76.358/
          data  Tit(1, 399)/ 409.000/,Tit(2, 399)/  76.358/
          data  Tit(1, 400)/ 410.000/,Tit(2, 400)/  76.358/
          data  Tit(1, 401)/ 411.000/,Tit(2, 401)/  76.358/
          data  Tit(1, 402)/ 412.000/,Tit(2, 402)/  76.358/
          data  Tit(1, 403)/ 413.000/,Tit(2, 403)/  76.358/
          data  Tit(1, 404)/ 414.000/,Tit(2, 404)/  76.358/
          data  Tit(1, 405)/ 415.000/,Tit(2, 405)/  76.358/
          data  Tit(1, 406)/ 416.000/,Tit(2, 406)/  76.359/
          data  Tit(1, 407)/ 417.000/,Tit(2, 407)/  76.359/
          data  Tit(1, 408)/ 418.000/,Tit(2, 408)/  76.359/
          data  Tit(1, 409)/ 419.000/,Tit(2, 409)/  76.360/
          data  Tit(1, 410)/ 420.000/,Tit(2, 410)/  76.360/
          data  Tit(1, 411)/ 421.000/,Tit(2, 411)/  76.361/
          data  Tit(1, 412)/ 422.000/,Tit(2, 412)/  76.361/
          data  Tit(1, 413)/ 423.000/,Tit(2, 413)/  76.362/
          data  Tit(1, 414)/ 424.000/,Tit(2, 414)/  76.362/
          data  Tit(1, 415)/ 425.000/,Tit(2, 415)/  76.363/
          data  Tit(1, 416)/ 426.000/,Tit(2, 416)/  76.364/
          data  Tit(1, 417)/ 427.000/,Tit(2, 417)/  76.364/
          data  Tit(1, 418)/ 428.000/,Tit(2, 418)/  76.365/
          data  Tit(1, 419)/ 429.000/,Tit(2, 419)/  76.366/
          data  Tit(1, 420)/ 430.000/,Tit(2, 420)/  76.367/
          data  Tit(1, 421)/ 431.000/,Tit(2, 421)/  76.367/
          data  Tit(1, 422)/ 432.000/,Tit(2, 422)/  76.368/
          data  Tit(1, 423)/ 433.000/,Tit(2, 423)/  76.369/
          data  Tit(1, 424)/ 434.000/,Tit(2, 424)/  76.370/
          data  Tit(1, 425)/ 435.000/,Tit(2, 425)/  76.371/
          data  Tit(1, 426)/ 436.000/,Tit(2, 426)/  76.372/
          data  Tit(1, 427)/ 437.000/,Tit(2, 427)/  76.373/
          data  Tit(1, 428)/ 438.000/,Tit(2, 428)/  76.374/
          data  Tit(1, 429)/ 439.000/,Tit(2, 429)/  76.375/
          data  Tit(1, 430)/ 440.000/,Tit(2, 430)/  76.377/
          data  Tit(1, 431)/ 441.000/,Tit(2, 431)/  76.378/
          data  Tit(1, 432)/ 442.000/,Tit(2, 432)/  76.379/
          data  Tit(1, 433)/ 443.000/,Tit(2, 433)/  76.380/
          data  Tit(1, 434)/ 444.000/,Tit(2, 434)/  76.382/
          data  Tit(1, 435)/ 445.000/,Tit(2, 435)/  76.383/
          data  Tit(1, 436)/ 446.000/,Tit(2, 436)/  76.384/
          data  Tit(1, 437)/ 447.000/,Tit(2, 437)/  76.386/
          data  Tit(1, 438)/ 448.000/,Tit(2, 438)/  76.387/
          data  Tit(1, 439)/ 449.000/,Tit(2, 439)/  76.389/
          data  Tit(1, 440)/ 450.000/,Tit(2, 440)/  76.390/
          data  Tit(1, 441)/ 451.000/,Tit(2, 441)/  76.392/
          data  Tit(1, 442)/ 452.000/,Tit(2, 442)/  76.393/
          data  Tit(1, 443)/ 453.000/,Tit(2, 443)/  76.395/
          data  Tit(1, 444)/ 454.000/,Tit(2, 444)/  76.396/
          data  Tit(1, 445)/ 455.000/,Tit(2, 445)/  76.398/
          data  Tit(1, 446)/ 456.000/,Tit(2, 446)/  76.400/
          data  Tit(1, 447)/ 457.000/,Tit(2, 447)/  76.402/
          data  Tit(1, 448)/ 458.000/,Tit(2, 448)/  76.403/
          data  Tit(1, 449)/ 459.000/,Tit(2, 449)/  76.405/
          data  Tit(1, 450)/ 460.000/,Tit(2, 450)/  76.407/
          data  Tit(1, 451)/ 461.000/,Tit(2, 451)/  76.409/
          data  Tit(1, 452)/ 462.000/,Tit(2, 452)/  76.410/
          data  Tit(1, 453)/ 463.000/,Tit(2, 453)/  76.412/
          data  Tit(1, 454)/ 464.000/,Tit(2, 454)/  76.414/
          data  Tit(1, 455)/ 465.000/,Tit(2, 455)/  76.416/
          data  Tit(1, 456)/ 466.000/,Tit(2, 456)/  76.418/
          data  Tit(1, 457)/ 467.000/,Tit(2, 457)/  76.420/
          data  Tit(1, 458)/ 468.000/,Tit(2, 458)/  76.422/
          data  Tit(1, 459)/ 469.000/,Tit(2, 459)/  76.424/
          data  Tit(1, 460)/ 470.000/,Tit(2, 460)/  76.426/
          data  Tit(1, 461)/ 471.000/,Tit(2, 461)/  76.429/
          data  Tit(1, 462)/ 472.000/,Tit(2, 462)/  76.431/
          data  Tit(1, 463)/ 473.000/,Tit(2, 463)/  76.433/
          data  Tit(1, 464)/ 474.000/,Tit(2, 464)/  76.435/
          data  Tit(1, 465)/ 475.000/,Tit(2, 465)/  76.438/
          data  Tit(1, 466)/ 476.000/,Tit(2, 466)/  76.440/
          data  Tit(1, 467)/ 477.000/,Tit(2, 467)/  76.442/
          data  Tit(1, 468)/ 478.000/,Tit(2, 468)/  76.444/
          data  Tit(1, 469)/ 479.000/,Tit(2, 469)/  76.446/
          data  Tit(1, 470)/ 480.000/,Tit(2, 470)/  76.449/
          data  Tit(1, 471)/ 481.000/,Tit(2, 471)/  76.451/
          data  Tit(1, 472)/ 482.000/,Tit(2, 472)/  76.454/
          data  Tit(1, 473)/ 483.000/,Tit(2, 473)/  76.456/
          data  Tit(1, 474)/ 484.000/,Tit(2, 474)/  76.459/
          data  Tit(1, 475)/ 485.000/,Tit(2, 475)/  76.461/
          data  Tit(1, 476)/ 486.000/,Tit(2, 476)/  76.463/
          data  Tit(1, 477)/ 487.000/,Tit(2, 477)/  76.466/
          data  Tit(1, 478)/ 488.000/,Tit(2, 478)/  76.469/
          data  Tit(1, 479)/ 489.000/,Tit(2, 479)/  76.471/
          data  Tit(1, 480)/ 490.000/,Tit(2, 480)/  76.474/
          data  Tit(1, 481)/ 491.000/,Tit(2, 481)/  76.477/
          data  Tit(1, 482)/ 492.000/,Tit(2, 482)/  76.479/
          data  Tit(1, 483)/ 493.000/,Tit(2, 483)/  76.482/
          data  Tit(1, 484)/ 494.000/,Tit(2, 484)/  76.485/
          data  Tit(1, 485)/ 495.000/,Tit(2, 485)/  76.487/
          data  Tit(1, 486)/ 496.000/,Tit(2, 486)/  76.490/
          data  Tit(1, 487)/ 497.000/,Tit(2, 487)/  76.493/
          data  Tit(1, 488)/ 498.000/,Tit(2, 488)/  76.496/
          data  Tit(1, 489)/ 499.000/,Tit(2, 489)/  76.498/
          data  Tit(1, 490)/ 500.000/,Tit(2, 490)/  76.501/
          data  Tit(1, 491)/ 501.000/,Tit(2, 491)/  76.504/
          data  Tit(1, 492)/ 502.000/,Tit(2, 492)/  76.507/
          data  Tit(1, 493)/ 503.000/,Tit(2, 493)/  76.510/
          data  Tit(1, 494)/ 504.000/,Tit(2, 494)/  76.513/
          data  Tit(1, 495)/ 505.000/,Tit(2, 495)/  76.516/
          data  Tit(1, 496)/ 506.000/,Tit(2, 496)/  76.519/
          data  Tit(1, 497)/ 507.000/,Tit(2, 497)/  76.522/
          data  Tit(1, 498)/ 508.000/,Tit(2, 498)/  76.525/
          data  Tit(1, 499)/ 509.000/,Tit(2, 499)/  76.528/
          data  Tit(1, 500)/ 510.000/,Tit(2, 500)/  76.531/
          data  Tit(1, 501)/ 511.000/,Tit(2, 501)/  76.534/
          data  Tit(1, 502)/ 512.000/,Tit(2, 502)/  76.537/
          data  Tit(1, 503)/ 513.000/,Tit(2, 503)/  76.540/
          data  Tit(1, 504)/ 514.000/,Tit(2, 504)/  76.544/
          data  Tit(1, 505)/ 515.000/,Tit(2, 505)/  76.547/
          data  Tit(1, 506)/ 516.000/,Tit(2, 506)/  76.550/
          data  Tit(1, 507)/ 517.000/,Tit(2, 507)/  76.553/
          data  Tit(1, 508)/ 518.000/,Tit(2, 508)/  76.556/
          data  Tit(1, 509)/ 519.000/,Tit(2, 509)/  76.560/
          data  Tit(1, 510)/ 520.000/,Tit(2, 510)/  76.563/
          data  Tit(1, 511)/ 521.000/,Tit(2, 511)/  76.566/
          data  Tit(1, 512)/ 522.000/,Tit(2, 512)/  76.569/
          data  Tit(1, 513)/ 523.000/,Tit(2, 513)/  76.573/
          data  Tit(1, 514)/ 524.000/,Tit(2, 514)/  76.576/
          data  Tit(1, 515)/ 525.000/,Tit(2, 515)/  76.579/
          data  Tit(1, 516)/ 526.000/,Tit(2, 516)/  76.583/
          data  Tit(1, 517)/ 527.000/,Tit(2, 517)/  76.586/
          data  Tit(1, 518)/ 528.000/,Tit(2, 518)/  76.590/
          data  Tit(1, 519)/ 529.000/,Tit(2, 519)/  76.593/
          data  Tit(1, 520)/ 530.000/,Tit(2, 520)/  76.597/
          data  Tit(1, 521)/ 531.000/,Tit(2, 521)/  76.600/
          data  Tit(1, 522)/ 532.000/,Tit(2, 522)/  76.604/
          data  Tit(1, 523)/ 533.000/,Tit(2, 523)/  76.607/
          data  Tit(1, 524)/ 534.000/,Tit(2, 524)/  76.611/
          data  Tit(1, 525)/ 535.000/,Tit(2, 525)/  76.614/
          data  Tit(1, 526)/ 536.000/,Tit(2, 526)/  76.618/
          data  Tit(1, 527)/ 537.000/,Tit(2, 527)/  76.621/
          data  Tit(1, 528)/ 538.000/,Tit(2, 528)/  76.625/
          data  Tit(1, 529)/ 539.000/,Tit(2, 529)/  76.628/
          data  Tit(1, 530)/ 540.000/,Tit(2, 530)/  76.632/
          data  Tit(1, 531)/ 541.000/,Tit(2, 531)/  76.636/
          data  Tit(1, 532)/ 542.000/,Tit(2, 532)/  76.640/
          data  Tit(1, 533)/ 543.000/,Tit(2, 533)/  76.643/
          data  Tit(1, 534)/ 544.000/,Tit(2, 534)/  76.647/
          data  Tit(1, 535)/ 545.000/,Tit(2, 535)/  76.651/
          data  Tit(1, 536)/ 546.000/,Tit(2, 536)/  76.655/
          data  Tit(1, 537)/ 547.000/,Tit(2, 537)/  76.658/
          data  Tit(1, 538)/ 548.000/,Tit(2, 538)/  76.662/
          data  Tit(1, 539)/ 549.000/,Tit(2, 539)/  76.666/
          data  Tit(1, 540)/ 550.000/,Tit(2, 540)/  76.670/
          data  Tit(1, 541)/ 551.000/,Tit(2, 541)/  76.674/
          data  Tit(1, 542)/ 552.000/,Tit(2, 542)/  76.677/
          data  Tit(1, 543)/ 553.000/,Tit(2, 543)/  76.681/
          data  Tit(1, 544)/ 554.000/,Tit(2, 544)/  76.685/
          data  Tit(1, 545)/ 555.000/,Tit(2, 545)/  76.689/
          data  Tit(1, 546)/ 556.000/,Tit(2, 546)/  76.693/
          data  Tit(1, 547)/ 557.000/,Tit(2, 547)/  76.697/
          data  Tit(1, 548)/ 558.000/,Tit(2, 548)/  76.701/
          data  Tit(1, 549)/ 559.000/,Tit(2, 549)/  76.705/
          data  Tit(1, 550)/ 560.000/,Tit(2, 550)/  76.709/
          data  Tit(1, 551)/ 561.000/,Tit(2, 551)/  76.713/
          data  Tit(1, 552)/ 562.000/,Tit(2, 552)/  76.717/
          data  Tit(1, 553)/ 563.000/,Tit(2, 553)/  76.721/
          data  Tit(1, 554)/ 564.000/,Tit(2, 554)/  76.725/
          data  Tit(1, 555)/ 565.000/,Tit(2, 555)/  76.729/
          data  Tit(1, 556)/ 566.000/,Tit(2, 556)/  76.733/
          data  Tit(1, 557)/ 567.000/,Tit(2, 557)/  76.737/
          data  Tit(1, 558)/ 568.000/,Tit(2, 558)/  76.741/
          data  Tit(1, 559)/ 569.000/,Tit(2, 559)/  76.745/
          data  Tit(1, 560)/ 570.000/,Tit(2, 560)/  76.749/
          data  Tit(1, 561)/ 571.000/,Tit(2, 561)/  76.754/
          data  Tit(1, 562)/ 572.000/,Tit(2, 562)/  76.758/
          data  Tit(1, 563)/ 573.000/,Tit(2, 563)/  76.762/
          data  Tit(1, 564)/ 574.000/,Tit(2, 564)/  76.766/
          data  Tit(1, 565)/ 575.000/,Tit(2, 565)/  76.771/
          data  Tit(1, 566)/ 576.000/,Tit(2, 566)/  76.775/
          data  Tit(1, 567)/ 577.000/,Tit(2, 567)/  76.779/
          data  Tit(1, 568)/ 578.000/,Tit(2, 568)/  76.783/
          data  Tit(1, 569)/ 579.000/,Tit(2, 569)/  76.787/
          data  Tit(1, 570)/ 580.000/,Tit(2, 570)/  76.792/
          data  Tit(1, 571)/ 581.000/,Tit(2, 571)/  76.796/
          data  Tit(1, 572)/ 582.000/,Tit(2, 572)/  76.801/
          data  Tit(1, 573)/ 583.000/,Tit(2, 573)/  76.805/
          data  Tit(1, 574)/ 584.000/,Tit(2, 574)/  76.809/
          data  Tit(1, 575)/ 585.000/,Tit(2, 575)/  76.813/
          data  Tit(1, 576)/ 586.000/,Tit(2, 576)/  76.818/
          data  Tit(1, 577)/ 587.000/,Tit(2, 577)/  76.822/
          data  Tit(1, 578)/ 588.000/,Tit(2, 578)/  76.826/
          data  Tit(1, 579)/ 589.000/,Tit(2, 579)/  76.831/
          data  Tit(1, 580)/ 590.000/,Tit(2, 580)/  76.835/
          data  Tit(1, 581)/ 591.000/,Tit(2, 581)/  76.840/
          data  Tit(1, 582)/ 592.000/,Tit(2, 582)/  76.844/
          data  Tit(1, 583)/ 593.000/,Tit(2, 583)/  76.849/
          data  Tit(1, 584)/ 594.000/,Tit(2, 584)/  76.853/
          data  Tit(1, 585)/ 595.000/,Tit(2, 585)/  76.857/
          data  Tit(1, 586)/ 596.000/,Tit(2, 586)/  76.862/
          data  Tit(1, 587)/ 597.000/,Tit(2, 587)/  76.866/
          data  Tit(1, 588)/ 598.000/,Tit(2, 588)/  76.871/
          data  Tit(1, 589)/ 599.000/,Tit(2, 589)/  76.875/
          data  Tit(1, 590)/ 600.000/,Tit(2, 590)/  76.880/
          data  Tit(1, 591)/ 601.000/,Tit(2, 591)/  76.885/
          data  Tit(1, 592)/ 602.000/,Tit(2, 592)/  76.889/
          data  Tit(1, 593)/ 603.000/,Tit(2, 593)/  76.894/
          data  Tit(1, 594)/ 604.000/,Tit(2, 594)/  76.899/
          data  Tit(1, 595)/ 605.000/,Tit(2, 595)/  76.903/
          data  Tit(1, 596)/ 606.000/,Tit(2, 596)/  76.908/
          data  Tit(1, 597)/ 607.000/,Tit(2, 597)/  76.912/
          data  Tit(1, 598)/ 608.000/,Tit(2, 598)/  76.917/
          data  Tit(1, 599)/ 609.000/,Tit(2, 599)/  76.922/
          data  Tit(1, 600)/ 610.000/,Tit(2, 600)/  76.926/
          data  Tit(1, 601)/ 611.000/,Tit(2, 601)/  76.931/
          data  Tit(1, 602)/ 612.000/,Tit(2, 602)/  76.936/
          data  Tit(1, 603)/ 613.000/,Tit(2, 603)/  76.940/
          data  Tit(1, 604)/ 614.000/,Tit(2, 604)/  76.945/
          data  Tit(1, 605)/ 615.000/,Tit(2, 605)/  76.950/
          data  Tit(1, 606)/ 616.000/,Tit(2, 606)/  76.955/
          data  Tit(1, 607)/ 617.000/,Tit(2, 607)/  76.959/
          data  Tit(1, 608)/ 618.000/,Tit(2, 608)/  76.964/
          data  Tit(1, 609)/ 619.000/,Tit(2, 609)/  76.969/
          data  Tit(1, 610)/ 620.000/,Tit(2, 610)/  76.974/
          data  Tit(1, 611)/ 621.000/,Tit(2, 611)/  76.978/
          data  Tit(1, 612)/ 622.000/,Tit(2, 612)/  76.983/
          data  Tit(1, 613)/ 623.000/,Tit(2, 613)/  76.988/
          data  Tit(1, 614)/ 624.000/,Tit(2, 614)/  76.993/
          data  Tit(1, 615)/ 625.000/,Tit(2, 615)/  76.998/
          data  Tit(1, 616)/ 626.000/,Tit(2, 616)/  77.003/
          data  Tit(1, 617)/ 627.000/,Tit(2, 617)/  77.007/
          data  Tit(1, 618)/ 628.000/,Tit(2, 618)/  77.012/
          data  Tit(1, 619)/ 629.000/,Tit(2, 619)/  77.017/
          data  Tit(1, 620)/ 630.000/,Tit(2, 620)/  77.022/
          data  Tit(1, 621)/ 631.000/,Tit(2, 621)/  77.027/
          data  Tit(1, 622)/ 632.000/,Tit(2, 622)/  77.032/
          data  Tit(1, 623)/ 633.000/,Tit(2, 623)/  77.037/
          data  Tit(1, 624)/ 634.000/,Tit(2, 624)/  77.042/
          data  Tit(1, 625)/ 635.000/,Tit(2, 625)/  77.047/
          data  Tit(1, 626)/ 636.000/,Tit(2, 626)/  77.052/
          data  Tit(1, 627)/ 637.000/,Tit(2, 627)/  77.057/
          data  Tit(1, 628)/ 638.000/,Tit(2, 628)/  77.061/
          data  Tit(1, 629)/ 639.000/,Tit(2, 629)/  77.067/
          data  Tit(1, 630)/ 640.000/,Tit(2, 630)/  77.072/
          data  Tit(1, 631)/ 641.000/,Tit(2, 631)/  77.077/
          data  Tit(1, 632)/ 642.000/,Tit(2, 632)/  77.082/
          data  Tit(1, 633)/ 643.000/,Tit(2, 633)/  77.087/
          data  Tit(1, 634)/ 644.000/,Tit(2, 634)/  77.092/
          data  Tit(1, 635)/ 645.000/,Tit(2, 635)/  77.097/
          data  Tit(1, 636)/ 646.000/,Tit(2, 636)/  77.102/
          data  Tit(1, 637)/ 647.000/,Tit(2, 637)/  77.107/
          data  Tit(1, 638)/ 648.000/,Tit(2, 638)/  77.112/
          data  Tit(1, 639)/ 649.000/,Tit(2, 639)/  77.117/
          data  Tit(1, 640)/ 650.000/,Tit(2, 640)/  77.122/
          data  Tit(1, 641)/ 651.000/,Tit(2, 641)/  77.127/
          data  Tit(1, 642)/ 652.000/,Tit(2, 642)/  77.132/
          data  Tit(1, 643)/ 653.000/,Tit(2, 643)/  77.137/
          data  Tit(1, 644)/ 654.000/,Tit(2, 644)/  77.143/
          data  Tit(1, 645)/ 655.000/,Tit(2, 645)/  77.148/
          data  Tit(1, 646)/ 656.000/,Tit(2, 646)/  77.153/
          data  Tit(1, 647)/ 657.000/,Tit(2, 647)/  77.158/
          data  Tit(1, 648)/ 658.000/,Tit(2, 648)/  77.163/
          data  Tit(1, 649)/ 659.000/,Tit(2, 649)/  77.168/
          data  Tit(1, 650)/ 660.000/,Tit(2, 650)/  77.173/
          data  Tit(1, 651)/ 661.000/,Tit(2, 651)/  77.179/
          data  Tit(1, 652)/ 662.000/,Tit(2, 652)/  77.184/
          data  Tit(1, 653)/ 663.000/,Tit(2, 653)/  77.189/
          data  Tit(1, 654)/ 664.000/,Tit(2, 654)/  77.194/
          data  Tit(1, 655)/ 665.000/,Tit(2, 655)/  77.200/
          data  Tit(1, 656)/ 666.000/,Tit(2, 656)/  77.205/
          data  Tit(1, 657)/ 667.000/,Tit(2, 657)/  77.210/
          data  Tit(1, 658)/ 668.000/,Tit(2, 658)/  77.215/
          data  Tit(1, 659)/ 669.000/,Tit(2, 659)/  77.221/
          data  Tit(1, 660)/ 670.000/,Tit(2, 660)/  77.226/
          data  Tit(1, 661)/ 671.000/,Tit(2, 661)/  77.231/
          data  Tit(1, 662)/ 672.000/,Tit(2, 662)/  77.236/
          data  Tit(1, 663)/ 673.000/,Tit(2, 663)/  77.242/
          data  Tit(1, 664)/ 674.000/,Tit(2, 664)/  77.247/
          data  Tit(1, 665)/ 675.000/,Tit(2, 665)/  77.253/
          data  Tit(1, 666)/ 676.000/,Tit(2, 666)/  77.258/
          data  Tit(1, 667)/ 677.000/,Tit(2, 667)/  77.263/
          data  Tit(1, 668)/ 678.000/,Tit(2, 668)/  77.269/
          data  Tit(1, 669)/ 679.000/,Tit(2, 669)/  77.274/
          data  Tit(1, 670)/ 680.000/,Tit(2, 670)/  77.279/
          data  Tit(1, 671)/ 681.000/,Tit(2, 671)/  77.285/
          data  Tit(1, 672)/ 682.000/,Tit(2, 672)/  77.290/
          data  Tit(1, 673)/ 683.000/,Tit(2, 673)/  77.296/
          data  Tit(1, 674)/ 684.000/,Tit(2, 674)/  77.301/
          data  Tit(1, 675)/ 685.000/,Tit(2, 675)/  77.306/
          data  Tit(1, 676)/ 686.000/,Tit(2, 676)/  77.312/
          data  Tit(1, 677)/ 687.000/,Tit(2, 677)/  77.317/
          data  Tit(1, 678)/ 688.000/,Tit(2, 678)/  77.323/
          data  Tit(1, 679)/ 689.000/,Tit(2, 679)/  77.328/
          data  Tit(1, 680)/ 690.000/,Tit(2, 680)/  77.334/
          data  Tit(1, 681)/ 691.000/,Tit(2, 681)/  77.339/
          data  Tit(1, 682)/ 692.000/,Tit(2, 682)/  77.344/
          data  Tit(1, 683)/ 693.000/,Tit(2, 683)/  77.350/
          data  Tit(1, 684)/ 694.000/,Tit(2, 684)/  77.355/
          data  Tit(1, 685)/ 695.000/,Tit(2, 685)/  77.361/
          data  Tit(1, 686)/ 696.000/,Tit(2, 686)/  77.366/
          data  Tit(1, 687)/ 697.000/,Tit(2, 687)/  77.372/
          data  Tit(1, 688)/ 698.000/,Tit(2, 688)/  77.377/
          data  Tit(1, 689)/ 699.000/,Tit(2, 689)/  77.383/
          data  Tit(1, 690)/ 700.000/,Tit(2, 690)/  77.388/
          data  Tit(1, 691)/ 701.000/,Tit(2, 691)/  77.394/
          data  Tit(1, 692)/ 702.000/,Tit(2, 692)/  77.399/
          data  Tit(1, 693)/ 703.000/,Tit(2, 693)/  77.405/
          data  Tit(1, 694)/ 704.000/,Tit(2, 694)/  77.411/
          data  Tit(1, 695)/ 705.000/,Tit(2, 695)/  77.416/
          data  Tit(1, 696)/ 706.000/,Tit(2, 696)/  77.422/
          data  Tit(1, 697)/ 707.000/,Tit(2, 697)/  77.427/
          data  Tit(1, 698)/ 708.000/,Tit(2, 698)/  77.433/
          data  Tit(1, 699)/ 709.000/,Tit(2, 699)/  77.438/
          data  Tit(1, 700)/ 710.000/,Tit(2, 700)/  77.444/
          data  Tit(1, 701)/ 711.000/,Tit(2, 701)/  77.450/
          data  Tit(1, 702)/ 712.000/,Tit(2, 702)/  77.455/
          data  Tit(1, 703)/ 713.000/,Tit(2, 703)/  77.461/
          data  Tit(1, 704)/ 714.000/,Tit(2, 704)/  77.466/
          data  Tit(1, 705)/ 715.000/,Tit(2, 705)/  77.472/
          data  Tit(1, 706)/ 716.000/,Tit(2, 706)/  77.478/
          data  Tit(1, 707)/ 717.000/,Tit(2, 707)/  77.483/
          data  Tit(1, 708)/ 718.000/,Tit(2, 708)/  77.489/
          data  Tit(1, 709)/ 719.000/,Tit(2, 709)/  77.495/
          data  Tit(1, 710)/ 720.000/,Tit(2, 710)/  77.500/
          data  Tit(1, 711)/ 721.000/,Tit(2, 711)/  77.506/
          data  Tit(1, 712)/ 722.000/,Tit(2, 712)/  77.512/
          data  Tit(1, 713)/ 723.000/,Tit(2, 713)/  77.517/
          data  Tit(1, 714)/ 724.000/,Tit(2, 714)/  77.523/
          data  Tit(1, 715)/ 725.000/,Tit(2, 715)/  77.529/
          data  Tit(1, 716)/ 726.000/,Tit(2, 716)/  77.534/
          data  Tit(1, 717)/ 727.000/,Tit(2, 717)/  77.540/
          data  Tit(1, 718)/ 728.000/,Tit(2, 718)/  77.546/
          data  Tit(1, 719)/ 729.000/,Tit(2, 719)/  77.552/
          data  Tit(1, 720)/ 730.000/,Tit(2, 720)/  77.557/
          data  Tit(1, 721)/ 731.000/,Tit(2, 721)/  77.563/
          data  Tit(1, 722)/ 732.000/,Tit(2, 722)/  77.569/
          data  Tit(1, 723)/ 733.000/,Tit(2, 723)/  77.575/
          data  Tit(1, 724)/ 734.000/,Tit(2, 724)/  77.580/
          data  Tit(1, 725)/ 735.000/,Tit(2, 725)/  77.586/
          data  Tit(1, 726)/ 736.000/,Tit(2, 726)/  77.592/
          data  Tit(1, 727)/ 737.000/,Tit(2, 727)/  77.598/
          data  Tit(1, 728)/ 738.000/,Tit(2, 728)/  77.604/
          data  Tit(1, 729)/ 739.000/,Tit(2, 729)/  77.609/
          data  Tit(1, 730)/ 740.000/,Tit(2, 730)/  77.615/
          data  Tit(1, 731)/ 741.000/,Tit(2, 731)/  77.621/
          data  Tit(1, 732)/ 742.000/,Tit(2, 732)/  77.627/
          data  Tit(1, 733)/ 743.000/,Tit(2, 733)/  77.632/
          data  Tit(1, 734)/ 744.000/,Tit(2, 734)/  77.638/
          data  Tit(1, 735)/ 745.000/,Tit(2, 735)/  77.644/
          data  Tit(1, 736)/ 746.000/,Tit(2, 736)/  77.650/
          data  Tit(1, 737)/ 747.000/,Tit(2, 737)/  77.656/
          data  Tit(1, 738)/ 748.000/,Tit(2, 738)/  77.662/
          data  Tit(1, 739)/ 749.000/,Tit(2, 739)/  77.667/
          data  Tit(1, 740)/ 750.000/,Tit(2, 740)/  77.673/
          data  Tit(1, 741)/ 751.000/,Tit(2, 741)/  77.679/
          data  Tit(1, 742)/ 752.000/,Tit(2, 742)/  77.685/
          data  Tit(1, 743)/ 753.000/,Tit(2, 743)/  77.691/
          data  Tit(1, 744)/ 754.000/,Tit(2, 744)/  77.697/
          data  Tit(1, 745)/ 755.000/,Tit(2, 745)/  77.703/
          data  Tit(1, 746)/ 756.000/,Tit(2, 746)/  77.709/
          data  Tit(1, 747)/ 757.000/,Tit(2, 747)/  77.715/
          data  Tit(1, 748)/ 758.000/,Tit(2, 748)/  77.720/
          data  Tit(1, 749)/ 759.000/,Tit(2, 749)/  77.726/
          data  Tit(1, 750)/ 760.000/,Tit(2, 750)/  77.732/
          data  Tit(1, 751)/ 761.000/,Tit(2, 751)/  77.738/
          data  Tit(1, 752)/ 762.000/,Tit(2, 752)/  77.744/
          data  Tit(1, 753)/ 763.000/,Tit(2, 753)/  77.750/
          data  Tit(1, 754)/ 764.000/,Tit(2, 754)/  77.756/
          data  Tit(1, 755)/ 765.000/,Tit(2, 755)/  77.762/
          data  Tit(1, 756)/ 766.000/,Tit(2, 756)/  77.768/
          data  Tit(1, 757)/ 767.000/,Tit(2, 757)/  77.774/
          data  Tit(1, 758)/ 768.000/,Tit(2, 758)/  77.780/
          data  Tit(1, 759)/ 769.000/,Tit(2, 759)/  77.786/
          data  Tit(1, 760)/ 770.000/,Tit(2, 760)/  77.792/
          data  Tit(1, 761)/ 771.000/,Tit(2, 761)/  77.798/
          data  Tit(1, 762)/ 772.000/,Tit(2, 762)/  77.803/
          data  Tit(1, 763)/ 773.000/,Tit(2, 763)/  77.810/
          data  Tit(1, 764)/ 774.000/,Tit(2, 764)/  77.815/
          data  Tit(1, 765)/ 775.000/,Tit(2, 765)/  77.821/
          data  Tit(1, 766)/ 776.000/,Tit(2, 766)/  77.827/
          data  Tit(1, 767)/ 777.000/,Tit(2, 767)/  77.833/
          data  Tit(1, 768)/ 778.000/,Tit(2, 768)/  77.839/
          data  Tit(1, 769)/ 779.000/,Tit(2, 769)/  77.845/
          data  Tit(1, 770)/ 780.000/,Tit(2, 770)/  77.851/
          data  Tit(1, 771)/ 781.000/,Tit(2, 771)/  77.857/
          data  Tit(1, 772)/ 782.000/,Tit(2, 772)/  77.864/
          data  Tit(1, 773)/ 783.000/,Tit(2, 773)/  77.869/
          data  Tit(1, 774)/ 784.000/,Tit(2, 774)/  77.876/
          data  Tit(1, 775)/ 785.000/,Tit(2, 775)/  77.882/
          data  Tit(1, 776)/ 786.000/,Tit(2, 776)/  77.888/
          data  Tit(1, 777)/ 787.000/,Tit(2, 777)/  77.894/
          data  Tit(1, 778)/ 788.000/,Tit(2, 778)/  77.900/
          data  Tit(1, 779)/ 789.000/,Tit(2, 779)/  77.906/
          data  Tit(1, 780)/ 790.000/,Tit(2, 780)/  77.912/
          data  Tit(1, 781)/ 791.000/,Tit(2, 781)/  77.918/
          data  Tit(1, 782)/ 792.000/,Tit(2, 782)/  77.924/
          data  Tit(1, 783)/ 793.000/,Tit(2, 783)/  77.930/
          data  Tit(1, 784)/ 794.000/,Tit(2, 784)/  77.936/
          data  Tit(1, 785)/ 795.000/,Tit(2, 785)/  77.942/
          data  Tit(1, 786)/ 796.000/,Tit(2, 786)/  77.948/
          data  Tit(1, 787)/ 797.000/,Tit(2, 787)/  77.954/
          data  Tit(1, 788)/ 798.000/,Tit(2, 788)/  77.960/
          data  Tit(1, 789)/ 799.000/,Tit(2, 789)/  77.966/
          data  Tit(1, 790)/ 800.000/,Tit(2, 790)/  77.973/
          data  Tit(1, 791)/ 801.000/,Tit(2, 791)/  77.979/
          data  Tit(1, 792)/ 802.000/,Tit(2, 792)/  77.985/
          data  Tit(1, 793)/ 803.000/,Tit(2, 793)/  77.991/
          data  Tit(1, 794)/ 804.000/,Tit(2, 794)/  77.997/
          data  Tit(1, 795)/ 805.000/,Tit(2, 795)/  78.003/
          data  Tit(1, 796)/ 806.000/,Tit(2, 796)/  78.009/
          data  Tit(1, 797)/ 807.000/,Tit(2, 797)/  78.015/
          data  Tit(1, 798)/ 808.000/,Tit(2, 798)/  78.021/
          data  Tit(1, 799)/ 809.000/,Tit(2, 799)/  78.028/
          data  Tit(1, 800)/ 810.000/,Tit(2, 800)/  78.034/
          data  Tit(1, 801)/ 811.000/,Tit(2, 801)/  78.040/
          data  Tit(1, 802)/ 812.000/,Tit(2, 802)/  78.046/
          data  Tit(1, 803)/ 813.000/,Tit(2, 803)/  78.052/
          data  Tit(1, 804)/ 814.000/,Tit(2, 804)/  78.058/
          data  Tit(1, 805)/ 815.000/,Tit(2, 805)/  78.064/
          data  Tit(1, 806)/ 816.000/,Tit(2, 806)/  78.071/
          data  Tit(1, 807)/ 817.000/,Tit(2, 807)/  78.077/
          data  Tit(1, 808)/ 818.000/,Tit(2, 808)/  78.083/
          data  Tit(1, 809)/ 819.000/,Tit(2, 809)/  78.089/
          data  Tit(1, 810)/ 820.000/,Tit(2, 810)/  78.095/
          data  Tit(1, 811)/ 821.000/,Tit(2, 811)/  78.102/
          data  Tit(1, 812)/ 822.000/,Tit(2, 812)/  78.108/
          data  Tit(1, 813)/ 823.000/,Tit(2, 813)/  78.114/
          data  Tit(1, 814)/ 824.000/,Tit(2, 814)/  78.120/
          data  Tit(1, 815)/ 825.000/,Tit(2, 815)/  78.126/
          data  Tit(1, 816)/ 826.000/,Tit(2, 816)/  78.133/
          data  Tit(1, 817)/ 827.000/,Tit(2, 817)/  78.139/
          data  Tit(1, 818)/ 828.000/,Tit(2, 818)/  78.145/
          data  Tit(1, 819)/ 829.000/,Tit(2, 819)/  78.151/
          data  Tit(1, 820)/ 830.000/,Tit(2, 820)/  78.157/
          data  Tit(1, 821)/ 831.000/,Tit(2, 821)/  78.163/
          data  Tit(1, 822)/ 832.000/,Tit(2, 822)/  78.170/
          data  Tit(1, 823)/ 833.000/,Tit(2, 823)/  78.176/
          data  Tit(1, 824)/ 834.000/,Tit(2, 824)/  78.182/
          data  Tit(1, 825)/ 835.000/,Tit(2, 825)/  78.188/
          data  Tit(1, 826)/ 836.000/,Tit(2, 826)/  78.195/
          data  Tit(1, 827)/ 837.000/,Tit(2, 827)/  78.201/
          data  Tit(1, 828)/ 838.000/,Tit(2, 828)/  78.207/
          data  Tit(1, 829)/ 839.000/,Tit(2, 829)/  78.213/
          data  Tit(1, 830)/ 840.000/,Tit(2, 830)/  78.220/
          data  Tit(1, 831)/ 841.000/,Tit(2, 831)/  78.226/
          data  Tit(1, 832)/ 842.000/,Tit(2, 832)/  78.232/
          data  Tit(1, 833)/ 843.000/,Tit(2, 833)/  78.238/
          data  Tit(1, 834)/ 844.000/,Tit(2, 834)/  78.245/
          data  Tit(1, 835)/ 845.000/,Tit(2, 835)/  78.251/
          data  Tit(1, 836)/ 846.000/,Tit(2, 836)/  78.257/
          data  Tit(1, 837)/ 847.000/,Tit(2, 837)/  78.263/
          data  Tit(1, 838)/ 848.000/,Tit(2, 838)/  78.270/
          data  Tit(1, 839)/ 849.000/,Tit(2, 839)/  78.276/
          data  Tit(1, 840)/ 850.000/,Tit(2, 840)/  78.282/
          data  Tit(1, 841)/ 851.000/,Tit(2, 841)/  78.288/
          data  Tit(1, 842)/ 852.000/,Tit(2, 842)/  78.295/
          data  Tit(1, 843)/ 853.000/,Tit(2, 843)/  78.301/
          data  Tit(1, 844)/ 854.000/,Tit(2, 844)/  78.307/
          data  Tit(1, 845)/ 855.000/,Tit(2, 845)/  78.313/
          data  Tit(1, 846)/ 856.000/,Tit(2, 846)/  78.320/
          data  Tit(1, 847)/ 857.000/,Tit(2, 847)/  78.326/
          data  Tit(1, 848)/ 858.000/,Tit(2, 848)/  78.332/
          data  Tit(1, 849)/ 859.000/,Tit(2, 849)/  78.339/
          data  Tit(1, 850)/ 860.000/,Tit(2, 850)/  78.345/
          data  Tit(1, 851)/ 861.000/,Tit(2, 851)/  78.351/
          data  Tit(1, 852)/ 862.000/,Tit(2, 852)/  78.358/
          data  Tit(1, 853)/ 863.000/,Tit(2, 853)/  78.364/
          data  Tit(1, 854)/ 864.000/,Tit(2, 854)/  78.370/
          data  Tit(1, 855)/ 865.000/,Tit(2, 855)/  78.376/
          data  Tit(1, 856)/ 866.000/,Tit(2, 856)/  78.383/
          data  Tit(1, 857)/ 867.000/,Tit(2, 857)/  78.389/
          data  Tit(1, 858)/ 868.000/,Tit(2, 858)/  78.395/
          data  Tit(1, 859)/ 869.000/,Tit(2, 859)/  78.402/
          data  Tit(1, 860)/ 870.000/,Tit(2, 860)/  78.408/
          data  Tit(1, 861)/ 871.000/,Tit(2, 861)/  78.414/
          data  Tit(1, 862)/ 872.000/,Tit(2, 862)/  78.421/
          data  Tit(1, 863)/ 873.000/,Tit(2, 863)/  78.427/
          data  Tit(1, 864)/ 874.000/,Tit(2, 864)/  78.433/
          data  Tit(1, 865)/ 875.000/,Tit(2, 865)/  78.440/
          data  Tit(1, 866)/ 876.000/,Tit(2, 866)/  78.446/
          data  Tit(1, 867)/ 877.000/,Tit(2, 867)/  78.452/
          data  Tit(1, 868)/ 878.000/,Tit(2, 868)/  78.459/
          data  Tit(1, 869)/ 879.000/,Tit(2, 869)/  78.465/
          data  Tit(1, 870)/ 880.000/,Tit(2, 870)/  78.471/
          data  Tit(1, 871)/ 881.000/,Tit(2, 871)/  78.478/
          data  Tit(1, 872)/ 882.000/,Tit(2, 872)/  78.484/
          data  Tit(1, 873)/ 883.000/,Tit(2, 873)/  78.490/
          data  Tit(1, 874)/ 884.000/,Tit(2, 874)/  78.497/
          data  Tit(1, 875)/ 885.000/,Tit(2, 875)/  78.503/
          data  Tit(1, 876)/ 886.000/,Tit(2, 876)/  78.509/
          data  Tit(1, 877)/ 887.000/,Tit(2, 877)/  78.516/
          data  Tit(1, 878)/ 888.000/,Tit(2, 878)/  78.522/
          data  Tit(1, 879)/ 889.000/,Tit(2, 879)/  78.528/
          data  Tit(1, 880)/ 890.000/,Tit(2, 880)/  78.535/
          data  Tit(1, 881)/ 891.000/,Tit(2, 881)/  78.541/
          data  Tit(1, 882)/ 892.000/,Tit(2, 882)/  78.548/
          data  Tit(1, 883)/ 893.000/,Tit(2, 883)/  78.554/
          data  Tit(1, 884)/ 894.000/,Tit(2, 884)/  78.560/
          data  Tit(1, 885)/ 895.000/,Tit(2, 885)/  78.567/
          data  Tit(1, 886)/ 896.000/,Tit(2, 886)/  78.573/
          data  Tit(1, 887)/ 897.000/,Tit(2, 887)/  78.579/
          data  Tit(1, 888)/ 898.000/,Tit(2, 888)/  78.586/
          data  Tit(1, 889)/ 899.000/,Tit(2, 889)/  78.592/
          data  Tit(1, 890)/ 900.000/,Tit(2, 890)/  78.598/
          data  Tit(1, 891)/ 901.000/,Tit(2, 891)/  78.605/
          data  Tit(1, 892)/ 902.000/,Tit(2, 892)/  78.611/
          data  Tit(1, 893)/ 903.000/,Tit(2, 893)/  78.617/
          data  Tit(1, 894)/ 904.000/,Tit(2, 894)/  78.624/
          data  Tit(1, 895)/ 905.000/,Tit(2, 895)/  78.630/
          data  Tit(1, 896)/ 906.000/,Tit(2, 896)/  78.637/
          data  Tit(1, 897)/ 907.000/,Tit(2, 897)/  78.643/
          data  Tit(1, 898)/ 908.000/,Tit(2, 898)/  78.649/
          data  Tit(1, 899)/ 909.000/,Tit(2, 899)/  78.656/
          data  Tit(1, 900)/ 910.000/,Tit(2, 900)/  78.662/
          data  Tit(1, 901)/ 911.000/,Tit(2, 901)/  78.669/
          data  Tit(1, 902)/ 912.000/,Tit(2, 902)/  78.675/
          data  Tit(1, 903)/ 913.000/,Tit(2, 903)/  78.681/
          data  Tit(1, 904)/ 914.000/,Tit(2, 904)/  78.688/
          data  Tit(1, 905)/ 915.000/,Tit(2, 905)/  78.694/
          data  Tit(1, 906)/ 916.000/,Tit(2, 906)/  78.700/
          data  Tit(1, 907)/ 917.000/,Tit(2, 907)/  78.707/
          data  Tit(1, 908)/ 918.000/,Tit(2, 908)/  78.713/
          data  Tit(1, 909)/ 919.000/,Tit(2, 909)/  78.720/
          data  Tit(1, 910)/ 920.000/,Tit(2, 910)/  78.726/
          data  Tit(1, 911)/ 921.000/,Tit(2, 911)/  78.732/
          data  Tit(1, 912)/ 922.000/,Tit(2, 912)/  78.739/
          data  Tit(1, 913)/ 923.000/,Tit(2, 913)/  78.745/
          data  Tit(1, 914)/ 924.000/,Tit(2, 914)/  78.752/
          data  Tit(1, 915)/ 925.000/,Tit(2, 915)/  78.758/
          data  Tit(1, 916)/ 926.000/,Tit(2, 916)/  78.764/
          data  Tit(1, 917)/ 927.000/,Tit(2, 917)/  78.771/
          data  Tit(1, 918)/ 928.000/,Tit(2, 918)/  78.777/
          data  Tit(1, 919)/ 929.000/,Tit(2, 919)/  78.784/
          data  Tit(1, 920)/ 930.000/,Tit(2, 920)/  78.790/
          data  Tit(1, 921)/ 931.000/,Tit(2, 921)/  78.796/
          data  Tit(1, 922)/ 932.000/,Tit(2, 922)/  78.803/
          data  Tit(1, 923)/ 933.000/,Tit(2, 923)/  78.809/
          data  Tit(1, 924)/ 934.000/,Tit(2, 924)/  78.816/
          data  Tit(1, 925)/ 935.000/,Tit(2, 925)/  78.822/
          data  Tit(1, 926)/ 936.000/,Tit(2, 926)/  78.828/
          data  Tit(1, 927)/ 937.000/,Tit(2, 927)/  78.835/
          data  Tit(1, 928)/ 938.000/,Tit(2, 928)/  78.841/
          data  Tit(1, 929)/ 939.000/,Tit(2, 929)/  78.848/
          data  Tit(1, 930)/ 940.000/,Tit(2, 930)/  78.854/
          data  Tit(1, 931)/ 941.000/,Tit(2, 931)/  78.860/
          data  Tit(1, 932)/ 942.000/,Tit(2, 932)/  78.867/
          data  Tit(1, 933)/ 943.000/,Tit(2, 933)/  78.873/
          data  Tit(1, 934)/ 944.000/,Tit(2, 934)/  78.880/
          data  Tit(1, 935)/ 945.000/,Tit(2, 935)/  78.886/
          data  Tit(1, 936)/ 946.000/,Tit(2, 936)/  78.893/
          data  Tit(1, 937)/ 947.000/,Tit(2, 937)/  78.899/
          data  Tit(1, 938)/ 948.000/,Tit(2, 938)/  78.905/
          data  Tit(1, 939)/ 949.000/,Tit(2, 939)/  78.912/
          data  Tit(1, 940)/ 950.000/,Tit(2, 940)/  78.918/
          data  Tit(1, 941)/ 951.000/,Tit(2, 941)/  78.925/
          data  Tit(1, 942)/ 952.000/,Tit(2, 942)/  78.931/
          data  Tit(1, 943)/ 953.000/,Tit(2, 943)/  78.937/
          data  Tit(1, 944)/ 954.000/,Tit(2, 944)/  78.944/
          data  Tit(1, 945)/ 955.000/,Tit(2, 945)/  78.950/
          data  Tit(1, 946)/ 956.000/,Tit(2, 946)/  78.957/
          data  Tit(1, 947)/ 957.000/,Tit(2, 947)/  78.963/
          data  Tit(1, 948)/ 958.000/,Tit(2, 948)/  78.969/
          data  Tit(1, 949)/ 959.000/,Tit(2, 949)/  78.976/
          data  Tit(1, 950)/ 960.000/,Tit(2, 950)/  78.982/
          data  Tit(1, 951)/ 961.000/,Tit(2, 951)/  78.989/
          data  Tit(1, 952)/ 962.000/,Tit(2, 952)/  78.995/
          data  Tit(1, 953)/ 963.000/,Tit(2, 953)/  79.001/
          data  Tit(1, 954)/ 964.000/,Tit(2, 954)/  79.008/
          data  Tit(1, 955)/ 965.000/,Tit(2, 955)/  79.014/
          data  Tit(1, 956)/ 966.000/,Tit(2, 956)/  79.021/
          data  Tit(1, 957)/ 967.000/,Tit(2, 957)/  79.027/
          data  Tit(1, 958)/ 968.000/,Tit(2, 958)/  79.033/
          data  Tit(1, 959)/ 969.000/,Tit(2, 959)/  79.040/
          data  Tit(1, 960)/ 970.000/,Tit(2, 960)/  79.046/
          data  Tit(1, 961)/ 971.000/,Tit(2, 961)/  79.053/
          data  Tit(1, 962)/ 972.000/,Tit(2, 962)/  79.059/
          data  Tit(1, 963)/ 973.000/,Tit(2, 963)/  79.065/
          data  Tit(1, 964)/ 974.000/,Tit(2, 964)/  79.072/
          data  Tit(1, 965)/ 975.000/,Tit(2, 965)/  79.078/
          data  Tit(1, 966)/ 976.000/,Tit(2, 966)/  79.085/
          data  Tit(1, 967)/ 977.000/,Tit(2, 967)/  79.091/
          data  Tit(1, 968)/ 978.000/,Tit(2, 968)/  79.097/
          data  Tit(1, 969)/ 979.000/,Tit(2, 969)/  79.104/
          data  Tit(1, 970)/ 980.000/,Tit(2, 970)/  79.110/
          data  Tit(1, 971)/ 981.000/,Tit(2, 971)/  79.117/
          data  Tit(1, 972)/ 982.000/,Tit(2, 972)/  79.123/
          data  Tit(1, 973)/ 983.000/,Tit(2, 973)/  79.129/
          data  Tit(1, 974)/ 984.000/,Tit(2, 974)/  79.136/
          data  Tit(1, 975)/ 985.000/,Tit(2, 975)/  79.142/
          data  Tit(1, 976)/ 986.000/,Tit(2, 976)/  79.149/
          data  Tit(1, 977)/ 987.000/,Tit(2, 977)/  79.155/
          data  Tit(1, 978)/ 988.000/,Tit(2, 978)/  79.161/
          data  Tit(1, 979)/ 989.000/,Tit(2, 979)/  79.168/
          data  Tit(1, 980)/ 990.000/,Tit(2, 980)/  79.174/
          data  Tit(1, 981)/ 991.000/,Tit(2, 981)/  79.180/
          data  Tit(1, 982)/ 992.000/,Tit(2, 982)/  79.187/
          data  Tit(1, 983)/ 993.000/,Tit(2, 983)/  79.193/
          data  Tit(1, 984)/ 994.000/,Tit(2, 984)/  79.200/
          data  Tit(1, 985)/ 995.000/,Tit(2, 985)/  79.206/
          data  Tit(1, 986)/ 996.000/,Tit(2, 986)/  79.212/
          data  Tit(1, 987)/ 997.000/,Tit(2, 987)/  79.219/
          data  Tit(1, 988)/ 998.000/,Tit(2, 988)/  79.225/
          data  Tit(1, 989)/ 999.000/,Tit(2, 989)/  79.231/
          data  Tit(1, 990)/1000.000/,Tit(2, 990)/  79.238/
c
c  Process the appropriate planet.
c
        plmodel = 0.0
        if(planet(1:3).eq.'ven') plmodel=pltbintp(freq,Ven,NVEN)
        if(planet(1:3).eq.'jup') plmodel=pltbintp(freq,Jup,NJUP)
        if(planet(1:3).eq.'sat') plmodel=pltbintp(freq,Sat,NSAT)
        if(planet(1:3).eq.'ura') plmodel=pltbintp(freq,Ura,NURA)
        if(planet(1:3).eq.'nep') plmodel=pltbintp(freq,Nep,NNEP)
        if(planet(1:3).eq.'tit') plmodel=pltbintp(freq,Tit,NTIT)
        return
        end
        
        real function marstb(freq,mjd)
        real mjd,freq
c  Return the brightness temperature of Mars.
c
c  Inputs:
c    freq     Observing frequency, in GHz.
c    mjd     MJD
c  Output:
c  marstb     Brightness temperature, in Kelvin.
c
        integer NMAR,js,j,i,imjd
        parameter(NMAR=225)
        real Ma(6,NMAR)
        real f(5),tn(5),tl(5),a,b
        data f/43.,115.,230.,333.,1000./
c! Caltech Mars Thermal Model - Whole Disk Planck Brightness Temperature
c! 7mm, 2.6mm, 1.3mm, 0.9mm, 0.3mm
c! Best fit radial cosine law exponent: 0.32
c!                          MJD              T(43)               T(115)     
c!                     T(230)             T(333)               T(1000)
c! correspondind to date 01-AUG-1999 to 25-DEC-2014
c!
       data Ma(1,  1)/51416.0/, Ma(2,  1)/ 192.810/, Ma(3,  1)/ 195.663
     *  /, Ma(4,  1)/ 199.781/, Ma(5,  1)/ 202.410/, Ma(6,  1)/ 207.780/
       data Ma(1,  2)/51441.0/, Ma(2,  2)/ 193.888/, Ma(3,  2)/ 197.069
     *  /, Ma(4,  2)/ 201.426/, Ma(5,  2)/ 204.164/, Ma(6,  2)/ 209.671/
       data Ma(1,  3)/51466.0/, Ma(2,  3)/ 195.664/, Ma(3,  3)/ 199.169
     *  /, Ma(4,  3)/ 203.730/, Ma(5,  3)/ 206.544/, Ma(6,  3)/ 212.108/
       data Ma(1,  4)/51491.0/, Ma(2,  4)/ 198.179/, Ma(3,  4)/ 201.967
     *  /, Ma(4,  4)/ 206.646/, Ma(5,  4)/ 209.484/, Ma(6,  4)/ 214.989/
       data Ma(1,  5)/51516.0/, Ma(2,  5)/ 201.626/, Ma(3,  5)/ 205.915
     *  /, Ma(4,  5)/ 210.836/, Ma(5,  5)/ 213.753/, Ma(6,  5)/ 219.230/
       data Ma(1,  6)/51541.0/, Ma(2,  6)/ 205.716/, Ma(3,  6)/ 210.562
     *  /, Ma(4,  6)/ 215.741/, Ma(5,  6)/ 218.735/, Ma(6,  6)/ 224.169/
       data Ma(1,  7)/51566.0/, Ma(2,  7)/ 208.261/, Ma(3,  7)/ 213.420
     *  /, Ma(4,  7)/ 218.803/, Ma(5,  7)/ 221.868/, Ma(6,  7)/ 227.291/
       data Ma(1,  8)/51591.0/, Ma(2,  8)/ 207.531/, Ma(3,  8)/ 213.126
     *  /, Ma(4,  8)/ 218.857/, Ma(5,  8)/ 222.061/, Ma(6,  8)/ 227.606/
       data Ma(1,  9)/51616.0/, Ma(2,  9)/ 205.289/, Ma(3,  9)/ 211.435
     *  /, Ma(4,  9)/ 217.579/, Ma(5,  9)/ 220.959/, Ma(6,  9)/ 226.693/
       data Ma(1, 10)/51641.0/, Ma(2, 10)/ 202.219/, Ma(3, 10)/ 208.847
     *  /, Ma(4, 10)/ 215.345/, Ma(5, 10)/ 218.868/, Ma(6, 10)/ 224.781/
       data Ma(1, 11)/51666.0/, Ma(2, 11)/ 199.130/, Ma(3, 11)/ 206.138
     *  /, Ma(4, 11)/ 212.872/, Ma(5, 11)/ 216.487/, Ma(6, 11)/ 222.502/
       data Ma(1, 12)/51691.0/, Ma(2, 12)/ 196.668/, Ma(3, 12)/ 203.937
     *  /, Ma(4, 12)/ 210.775/, Ma(5, 12)/ 214.418/, Ma(6, 12)/ 220.435/
       data Ma(1, 13)/51716.0/, Ma(2, 13)/ 194.788/, Ma(3, 13)/ 202.188
     *  /, Ma(4, 13)/ 208.996/, Ma(5, 13)/ 212.595/, Ma(6, 13)/ 218.502/
       data Ma(1, 14)/51741.0/, Ma(2, 14)/ 193.662/, Ma(3, 14)/ 201.223
     *  /, Ma(4, 14)/ 207.962/, Ma(5, 14)/ 211.482/, Ma(6, 14)/ 217.193/
       data Ma(1, 15)/51766.0/, Ma(2, 15)/ 192.970/, Ma(3, 15)/ 200.497
     *  /, Ma(4, 15)/ 207.032/, Ma(5, 15)/ 210.407/, Ma(6, 15)/ 215.830/
       data Ma(1, 16)/51791.0/, Ma(2, 16)/ 193.277/, Ma(3, 16)/ 200.931
     *  /, Ma(4, 16)/ 207.320/, Ma(5, 16)/ 210.571/, Ma(6, 16)/ 215.685/
       data Ma(1, 17)/51816.0/, Ma(2, 17)/ 194.254/, Ma(3, 17)/ 202.082
     *  /, Ma(4, 17)/ 208.341/, Ma(5, 17)/ 211.464/, Ma(6, 17)/ 216.262/
       data Ma(1, 18)/51841.0/, Ma(2, 18)/ 195.518/, Ma(3, 18)/ 203.481
     *  /, Ma(4, 18)/ 209.607/, Ma(5, 18)/ 212.607/, Ma(6, 18)/ 217.100/
       data Ma(1, 19)/51866.0/, Ma(2, 19)/ 197.119/, Ma(3, 19)/ 205.113
     *  /, Ma(4, 19)/ 211.099/, Ma(5, 19)/ 213.989/, Ma(6, 19)/ 218.203/
       data Ma(1, 20)/51891.0/, Ma(2, 20)/ 198.416/, Ma(3, 20)/ 206.473
     *  /, Ma(4, 20)/ 212.384/, Ma(5, 20)/ 215.195/, Ma(6, 20)/ 219.206/
       data Ma(1, 21)/51916.0/, Ma(2, 21)/ 198.708/, Ma(3, 21)/ 206.850
     *  /, Ma(4, 21)/ 212.742/, Ma(5, 21)/ 215.517/, Ma(6, 21)/ 219.411/
       data Ma(1, 22)/51941.0/, Ma(2, 22)/ 197.922/, Ma(3, 22)/ 206.192
     *  /, Ma(4, 22)/ 212.137/, Ma(5, 22)/ 214.912/, Ma(6, 22)/ 218.782/
       data Ma(1, 23)/51966.0/, Ma(2, 23)/ 197.366/, Ma(3, 23)/ 205.900
     *  /, Ma(4, 23)/ 212.002/, Ma(5, 23)/ 214.834/, Ma(6, 23)/ 218.765/
       data Ma(1, 24)/51991.0/, Ma(2, 24)/ 197.219/, Ma(3, 24)/ 206.073
     *  /, Ma(4, 24)/ 212.412/, Ma(5, 24)/ 215.358/, Ma(6, 24)/ 219.460/
       data Ma(1, 25)/52016.0/, Ma(2, 25)/ 197.811/, Ma(3, 25)/ 207.060
     *  /, Ma(4, 25)/ 213.789/, Ma(5, 25)/ 216.941/, Ma(6, 25)/ 221.389/
       data Ma(1, 26)/52041.0/, Ma(2, 26)/ 199.344/, Ma(3, 26)/ 209.063
     *  /, Ma(4, 26)/ 216.407/, Ma(5, 26)/ 219.931/, Ma(6, 26)/ 225.044/
       data Ma(1, 27)/52066.0/, Ma(2, 27)/ 200.927/, Ma(3, 27)/ 210.593
     *  /, Ma(4, 27)/ 218.472/, Ma(5, 27)/ 222.424/, Ma(6, 27)/ 228.492/
       data Ma(1, 28)/52091.0/, Ma(2, 28)/ 198.899/, Ma(3, 28)/ 206.476
     *  /, Ma(4, 28)/ 213.546/, Ma(5, 28)/ 217.353/, Ma(6, 28)/ 223.790/
       data Ma(1, 29)/52116.0/, Ma(2, 29)/ 196.404/, Ma(3, 29)/ 201.617
     *  /, Ma(4, 29)/ 207.315/, Ma(5, 29)/ 210.612/, Ma(6, 29)/ 216.710/
       data Ma(1, 30)/52141.0/, Ma(2, 30)/ 194.826/, Ma(3, 30)/ 198.517
     *  /, Ma(4, 30)/ 203.224/, Ma(5, 30)/ 206.106/, Ma(6, 30)/ 211.773/
       data Ma(1, 31)/52166.0/, Ma(2, 31)/ 195.283/, Ma(3, 31)/ 198.048
     *  /, Ma(4, 31)/ 202.099/, Ma(5, 31)/ 204.689/, Ma(6, 31)/ 209.980/
       data Ma(1, 32)/52191.0/, Ma(2, 32)/ 197.116/, Ma(3, 32)/ 199.503
     *  /, Ma(4, 32)/ 203.233/, Ma(5, 32)/ 205.668/, Ma(6, 32)/ 210.701/
       data Ma(1, 33)/52216.0/, Ma(2, 33)/ 200.087/, Ma(3, 33)/ 202.577
     *  /, Ma(4, 33)/ 206.292/, Ma(5, 33)/ 208.691/, Ma(6, 33)/ 213.575/
       data Ma(1, 34)/52241.0/, Ma(2, 34)/ 203.882/, Ma(3, 34)/ 206.476
     *  /, Ma(4, 34)/ 210.185/, Ma(5, 34)/ 212.563/, Ma(6, 34)/ 217.323/
       data Ma(1, 35)/52266.0/, Ma(2, 35)/ 204.666/, Ma(3, 35)/ 207.404
     *  /, Ma(4, 35)/ 211.279/, Ma(5, 35)/ 213.730/, Ma(6, 35)/ 218.517/
       data Ma(1, 36)/52291.0/, Ma(2, 36)/ 203.684/, Ma(3, 36)/ 206.914
     *  /, Ma(4, 36)/ 211.181/, Ma(5, 36)/ 213.797/, Ma(6, 36)/ 218.762/
       data Ma(1, 37)/52316.0/, Ma(2, 37)/ 201.346/, Ma(3, 37)/ 205.184
     *  /, Ma(4, 37)/ 209.928/, Ma(5, 37)/ 212.755/, Ma(6, 37)/ 217.979/
       data Ma(1, 38)/52341.0/, Ma(2, 38)/ 198.272/, Ma(3, 38)/ 202.706
     *  /, Ma(4, 38)/ 207.901/, Ma(5, 38)/ 210.924/, Ma(6, 38)/ 216.409/
       data Ma(1, 39)/52366.0/, Ma(2, 39)/ 195.532/, Ma(3, 39)/ 200.526
     *  /, Ma(4, 39)/ 206.110/, Ma(5, 39)/ 209.300/, Ma(6, 39)/ 215.005/
       data Ma(1, 40)/52391.0/, Ma(2, 40)/ 193.456/, Ma(3, 40)/ 198.891
     *  /, Ma(4, 40)/ 204.730/, Ma(5, 40)/ 208.016/, Ma(6, 40)/ 213.840/
       data Ma(1, 41)/52416.0/, Ma(2, 41)/ 191.957/, Ma(3, 41)/ 197.764
     *  /, Ma(4, 41)/ 203.753/, Ma(5, 41)/ 207.086/, Ma(6, 41)/ 212.923/
       data Ma(1, 42)/52441.0/, Ma(2, 42)/ 191.166/, Ma(3, 42)/ 197.281
     *  /, Ma(4, 42)/ 203.347/, Ma(5, 42)/ 206.680/, Ma(6, 42)/ 212.452/
       data Ma(1, 43)/52466.0/, Ma(2, 43)/ 191.014/, Ma(3, 43)/ 197.393
     *  /, Ma(4, 43)/ 203.480/, Ma(5, 43)/ 206.779/, Ma(6, 43)/ 212.409/
       data Ma(1, 44)/52491.0/, Ma(2, 44)/ 191.721/, Ma(3, 44)/ 198.501
     *  /, Ma(4, 44)/ 204.647/, Ma(5, 44)/ 207.920/, Ma(6, 44)/ 213.387/
       data Ma(1, 45)/52516.0/, Ma(2, 45)/ 193.071/, Ma(3, 45)/ 200.256
     *  /, Ma(4, 45)/ 206.460/, Ma(5, 45)/ 209.693/, Ma(6, 45)/ 214.960/
       data Ma(1, 46)/52541.0/, Ma(2, 46)/ 194.929/, Ma(3, 46)/ 202.453
     *  /, Ma(4, 46)/ 208.690/, Ma(5, 46)/ 211.877/, Ma(6, 46)/ 216.928/
       data Ma(1, 47)/52566.0/, Ma(2, 47)/ 197.065/, Ma(3, 47)/ 204.848
     *  /, Ma(4, 47)/ 211.099/, Ma(5, 47)/ 214.240/, Ma(6, 47)/ 219.076/
       data Ma(1, 48)/52591.0/, Ma(2, 48)/ 198.983/, Ma(3, 48)/ 207.074
     *  /, Ma(4, 48)/ 213.380/, Ma(5, 48)/ 216.496/, Ma(6, 48)/ 221.156/
       data Ma(1, 49)/52616.0/, Ma(2, 49)/ 199.197/, Ma(3, 49)/ 207.540
     *  /, Ma(4, 49)/ 213.917/, Ma(5, 49)/ 217.015/, Ma(6, 49)/ 221.551/
       data Ma(1, 50)/52641.0/, Ma(2, 50)/ 198.696/, Ma(3, 50)/ 207.313
     *  /, Ma(4, 50)/ 213.768/, Ma(5, 50)/ 216.860/, Ma(6, 50)/ 221.303/
       data Ma(1, 51)/52666.0/, Ma(2, 51)/ 198.013/, Ma(3, 51)/ 206.889
     *  /, Ma(4, 51)/ 213.405/, Ma(5, 51)/ 216.479/, Ma(6, 51)/ 220.831/
       data Ma(1, 52)/52691.0/, Ma(2, 52)/ 197.429/, Ma(3, 52)/ 206.476
     *  /, Ma(4, 52)/ 212.977/, Ma(5, 52)/ 216.006/, Ma(6, 52)/ 220.238/
       data Ma(1, 53)/52716.0/, Ma(2, 53)/ 197.144/, Ma(3, 53)/ 206.255
     *  /, Ma(4, 53)/ 212.658/, Ma(5, 53)/ 215.596/, Ma(6, 53)/ 219.665/
       data Ma(1, 54)/52741.0/, Ma(2, 54)/ 198.301/, Ma(3, 54)/ 207.660
     *  /, Ma(4, 54)/ 214.026/, Ma(5, 54)/ 216.899/, Ma(6, 54)/ 220.788/
       data Ma(1, 55)/52766.0/, Ma(2, 55)/ 199.872/, Ma(3, 55)/ 209.307
     *  /, Ma(4, 55)/ 215.561/, Ma(5, 55)/ 218.340/, Ma(6, 55)/ 222.053/
       data Ma(1, 56)/52791.0/, Ma(2, 56)/ 202.510/, Ma(3, 56)/ 212.127
     *  /, Ma(4, 56)/ 218.380/, Ma(5, 56)/ 221.133/, Ma(6, 56)/ 224.752/
       data Ma(1, 57)/52816.0/, Ma(2, 57)/ 206.032/, Ma(3, 57)/ 216.293
     *  /, Ma(4, 57)/ 222.971/, Ma(5, 57)/ 225.910/, Ma(6, 57)/ 229.745/
       data Ma(1, 58)/52841.0/, Ma(2, 58)/ 208.569/, Ma(3, 58)/ 219.253
     *  /, Ma(4, 58)/ 226.559/, Ma(5, 58)/ 229.868/, Ma(6, 58)/ 234.336/
       data Ma(1, 59)/52866.0/, Ma(2, 59)/ 209.439/, Ma(3, 59)/ 219.914
     *  /, Ma(4, 59)/ 227.836/, Ma(5, 59)/ 231.646/, Ma(6, 59)/ 237.182/
       data Ma(1, 60)/52891.0/, Ma(2, 60)/ 207.827/, Ma(3, 60)/ 216.392
     *  /, Ma(4, 60)/ 223.780/, Ma(5, 60)/ 227.615/, Ma(6, 60)/ 233.763/
       data Ma(1, 61)/52916.0/, Ma(2, 61)/ 206.222/, Ma(3, 61)/ 211.877
     *  /, Ma(4, 61)/ 217.602/, Ma(5, 61)/ 220.827/, Ma(6, 61)/ 226.515/
       data Ma(1, 62)/52941.0/, Ma(2, 62)/ 205.304/, Ma(3, 62)/ 208.793
     *  /, Ma(4, 62)/ 213.158/, Ma(5, 62)/ 215.815/, Ma(6, 62)/ 220.872/
       data Ma(1, 63)/52966.0/, Ma(2, 63)/ 203.551/, Ma(3, 63)/ 206.020
     *  /, Ma(4, 63)/ 209.753/, Ma(5, 63)/ 212.141/, Ma(6, 63)/ 216.862/
       data Ma(1, 64)/52991.0/, Ma(2, 64)/ 201.165/, Ma(3, 64)/ 203.384
     *  /, Ma(4, 64)/ 207.005/, Ma(5, 64)/ 209.350/, Ma(6, 64)/ 214.015/
       data Ma(1, 65)/53016.0/, Ma(2, 65)/ 198.031/, Ma(3, 65)/ 200.407
     *  /, Ma(4, 65)/ 204.204/, Ma(5, 65)/ 206.629/, Ma(6, 65)/ 211.423/
       data Ma(1, 66)/53041.0/, Ma(2, 66)/ 194.661/, Ma(3, 66)/ 197.395
     *  /, Ma(4, 66)/ 201.489/, Ma(5, 66)/ 204.052/, Ma(6, 66)/ 209.048/
       data Ma(1, 67)/53066.0/, Ma(2, 67)/ 191.934/, Ma(3, 67)/ 195.112
     *  /, Ma(4, 67)/ 199.531/, Ma(5, 67)/ 202.239/, Ma(6, 67)/ 207.453/
       data Ma(1, 68)/53091.0/, Ma(2, 68)/ 190.003/, Ma(3, 68)/ 193.619
     *  /, Ma(4, 68)/ 198.317/, Ma(5, 68)/ 201.145/, Ma(6, 68)/ 206.531/
       data Ma(1, 69)/53116.0/, Ma(2, 69)/ 188.796/, Ma(3, 69)/ 192.854
     *  /, Ma(4, 69)/ 197.781/, Ma(5, 69)/ 200.698/, Ma(6, 69)/ 206.185/
       data Ma(1, 70)/53141.0/, Ma(2, 70)/ 188.292/, Ma(3, 70)/ 192.707
     *  /, Ma(4, 70)/ 197.788/, Ma(5, 70)/ 200.752/, Ma(6, 70)/ 206.269/
       data Ma(1, 71)/53166.0/, Ma(2, 71)/ 188.656/, Ma(3, 71)/ 193.543
     *  /, Ma(4, 71)/ 198.811/, Ma(5, 71)/ 201.827/, Ma(6, 71)/ 207.339/
       data Ma(1, 72)/53191.0/, Ma(2, 72)/ 189.699/, Ma(3, 72)/ 195.116
     *  /, Ma(4, 72)/ 200.582/, Ma(5, 72)/ 203.647/, Ma(6, 72)/ 209.121/
       data Ma(1, 73)/53216.0/, Ma(2, 73)/ 191.286/, Ma(3, 73)/ 197.262
     *  /, Ma(4, 73)/ 202.935/, Ma(5, 73)/ 206.045/, Ma(6, 73)/ 211.458/
       data Ma(1, 74)/53241.0/, Ma(2, 74)/ 193.742/, Ma(3, 74)/ 200.213
     *  /, Ma(4, 74)/ 206.075/, Ma(5, 74)/ 209.228/, Ma(6, 74)/ 214.553/
       data Ma(1, 75)/53266.0/, Ma(2, 75)/ 196.531/, Ma(3, 75)/ 203.544
     *  /, Ma(4, 75)/ 209.639/, Ma(5, 75)/ 212.843/, Ma(6, 75)/ 218.090/
       data Ma(1, 76)/53291.0/, Ma(2, 76)/ 198.579/, Ma(3, 76)/ 206.131
     *  /, Ma(4, 76)/ 212.473/, Ma(5, 76)/ 215.745/, Ma(6, 76)/ 220.937/
       data Ma(1, 77)/53316.0/, Ma(2, 77)/ 199.110/, Ma(3, 77)/ 207.165
     *  /, Ma(4, 77)/ 213.761/, Ma(5, 77)/ 217.098/, Ma(6, 77)/ 222.260/
       data Ma(1, 78)/53341.0/, Ma(2, 78)/ 199.161/, Ma(3, 78)/ 207.773
     *  /, Ma(4, 78)/ 214.635/, Ma(5, 78)/ 218.044/, Ma(6, 78)/ 223.189/
       data Ma(1, 79)/53366.0/, Ma(2, 79)/ 198.912/, Ma(3, 79)/ 207.992
     *  /, Ma(4, 79)/ 215.041/, Ma(5, 79)/ 218.486/, Ma(6, 79)/ 223.573/
       data Ma(1, 80)/53391.0/, Ma(2, 80)/ 198.568/, Ma(3, 80)/ 207.969
     *  /, Ma(4, 80)/ 215.084/, Ma(5, 80)/ 218.497/, Ma(6, 80)/ 223.453/
       data Ma(1, 81)/53416.0/, Ma(2, 81)/ 198.656/, Ma(3, 81)/ 208.291
     *  /, Ma(4, 81)/ 215.355/, Ma(5, 81)/ 218.684/, Ma(6, 81)/ 223.418/
       data Ma(1, 82)/53441.0/, Ma(2, 82)/ 199.956/, Ma(3, 82)/ 209.881
     *  /, Ma(4, 82)/ 216.856/, Ma(5, 82)/ 220.063/, Ma(6, 82)/ 224.508/
       data Ma(1, 83)/53466.0/, Ma(2, 83)/ 200.817/, Ma(3, 83)/ 210.487
     *  /, Ma(4, 83)/ 217.042/, Ma(5, 83)/ 219.995/, Ma(6, 83)/ 224.007/
       data Ma(1, 84)/53491.0/, Ma(2, 84)/ 204.108/, Ma(3, 84)/ 213.886
     *  /, Ma(4, 84)/ 220.155/, Ma(5, 84)/ 222.894/, Ma(6, 84)/ 226.476/
       data Ma(1, 85)/53516.0/, Ma(2, 85)/ 207.106/, Ma(3, 85)/ 217.009
     *  /, Ma(4, 85)/ 223.078/, Ma(5, 85)/ 225.653/, Ma(6, 85)/ 228.883/
       data Ma(1, 86)/53541.0/, Ma(2, 86)/ 210.063/, Ma(3, 86)/ 219.421
     *  /, Ma(4, 86)/ 225.014/, Ma(5, 86)/ 227.358/, Ma(6, 86)/ 230.217/
       data Ma(1, 87)/53566.0/, Ma(2, 87)/ 212.727/, Ma(3, 87)/ 222.131
     *  /, Ma(4, 87)/ 227.734/, Ma(5, 87)/ 230.075/, Ma(6, 87)/ 232.879/
       data Ma(1, 88)/53591.0/, Ma(2, 88)/ 214.092/, Ma(3, 88)/ 223.837
     *  /, Ma(4, 88)/ 229.802/, Ma(5, 88)/ 232.329/, Ma(6, 88)/ 235.382/
       data Ma(1, 89)/53616.0/, Ma(2, 89)/ 213.451/, Ma(3, 89)/ 223.322
     *  /, Ma(4, 89)/ 229.750/, Ma(5, 89)/ 232.575/, Ma(6, 89)/ 236.144/
       data Ma(1, 90)/53641.0/, Ma(2, 90)/ 211.338/, Ma(3, 90)/ 221.482
     *  /, Ma(4, 90)/ 228.672/, Ma(5, 90)/ 231.977/, Ma(6, 90)/ 236.434/
       data Ma(1, 91)/53666.0/, Ma(2, 91)/ 209.147/, Ma(3, 91)/ 218.996
     *  /, Ma(4, 91)/ 226.768/, Ma(5, 91)/ 230.558/, Ma(6, 91)/ 236.103/
       data Ma(1, 92)/53691.0/, Ma(2, 92)/ 204.717/, Ma(3, 92)/ 212.383
     *  /, Ma(4, 92)/ 219.415/, Ma(5, 92)/ 223.119/, Ma(6, 92)/ 229.103/
       data Ma(1, 93)/53716.0/, Ma(2, 93)/ 198.737/, Ma(3, 93)/ 203.702
     *  /, Ma(4, 93)/ 209.226/, Ma(5, 93)/ 212.379/, Ma(6, 93)/ 217.983/
       data Ma(1, 94)/53741.0/, Ma(2, 94)/ 193.673/, Ma(3, 94)/ 197.070
     *  /, Ma(4, 94)/ 201.623/, Ma(5, 94)/ 204.384/, Ma(6, 94)/ 209.626/
       data Ma(1, 95)/53766.0/, Ma(2, 95)/ 190.038/, Ma(3, 95)/ 192.787
     *  /, Ma(4, 95)/ 196.919/, Ma(5, 95)/ 199.503/, Ma(6, 95)/ 204.593/
       data Ma(1, 96)/53791.0/, Ma(2, 96)/ 187.493/, Ma(3, 96)/ 190.100
     *  /, Ma(4, 96)/ 194.112/, Ma(5, 96)/ 196.643/, Ma(6, 96)/ 201.702/
       data Ma(1, 97)/53816.0/, Ma(2, 97)/ 186.145/, Ma(3, 97)/ 188.860
     *  /, Ma(4, 97)/ 192.892/, Ma(5, 97)/ 195.430/, Ma(6, 97)/ 200.516/
       data Ma(1, 98)/53841.0/, Ma(2, 98)/ 185.761/, Ma(3, 98)/ 188.715
     *  /, Ma(4, 98)/ 192.846/, Ma(5, 98)/ 195.415/, Ma(6, 98)/ 200.535/
       data Ma(1, 99)/53866.0/, Ma(2, 99)/ 186.241/, Ma(3, 99)/ 189.604
     *  /, Ma(4, 99)/ 193.910/, Ma(5, 99)/ 196.537/, Ma(6, 99)/ 201.705/
       data Ma(1,100)/53891.0/, Ma(2,100)/ 187.517/, Ma(3,100)/ 191.389
     *  /, Ma(4,100)/ 195.926/, Ma(5,100)/ 198.634/, Ma(6,100)/ 203.835/
       data Ma(1,101)/53916.0/, Ma(2,101)/ 189.485/, Ma(3,101)/ 193.910
     *  /, Ma(4,101)/ 198.704/, Ma(5,101)/ 201.496/, Ma(6,101)/ 206.730/
       data Ma(1,102)/53941.0/, Ma(2,102)/ 192.222/, Ma(3,102)/ 197.217
     *  /, Ma(4,102)/ 202.301/, Ma(5,102)/ 205.196/, Ma(6,102)/ 210.457/
       data Ma(1,103)/53966.0/, Ma(2,103)/ 195.452/, Ma(3,103)/ 201.136
     *  /, Ma(4,103)/ 206.586/, Ma(5,103)/ 209.613/, Ma(6,103)/ 214.925/
       data Ma(1,104)/53991.0/, Ma(2,104)/ 197.240/, Ma(3,104)/ 203.611
     *  /, Ma(4,104)/ 209.478/, Ma(5,104)/ 212.662/, Ma(6,104)/ 218.071/
       data Ma(1,105)/54016.0/, Ma(2,105)/ 198.236/, Ma(3,105)/ 205.366
     *  /, Ma(4,105)/ 211.697/, Ma(5,105)/ 215.054/, Ma(6,105)/ 220.584/
       data Ma(1,106)/54041.0/, Ma(2,106)/ 198.793/, Ma(3,106)/ 206.723
     *  /, Ma(4,106)/ 213.528/, Ma(5,106)/ 217.057/, Ma(6,106)/ 222.707/
       data Ma(1,107)/54066.0/, Ma(2,107)/ 199.045/, Ma(3,107)/ 207.712
     *  /, Ma(4,107)/ 214.929/, Ma(5,107)/ 218.597/, Ma(6,107)/ 224.322/
       data Ma(1,108)/54091.0/, Ma(2,108)/ 199.158/, Ma(3,108)/ 208.418
     *  /, Ma(4,108)/ 215.901/, Ma(5,108)/ 219.640/, Ma(6,108)/ 225.343/
       data Ma(1,109)/54116.0/, Ma(2,109)/ 200.055/, Ma(3,109)/ 209.918
     *  /, Ma(4,109)/ 217.608/, Ma(5,109)/ 221.370/, Ma(6,109)/ 226.961/
       data Ma(1,110)/54141.0/, Ma(2,110)/ 200.982/, Ma(3,110)/ 211.119
     *  /, Ma(4,110)/ 218.758/, Ma(5,110)/ 222.415/, Ma(6,110)/ 227.737/
       data Ma(1,111)/54166.0/, Ma(2,111)/ 202.764/, Ma(3,111)/ 213.064
     *  /, Ma(4,111)/ 220.502/, Ma(5,111)/ 223.981/, Ma(6,111)/ 228.904/
       data Ma(1,112)/54191.0/, Ma(2,112)/ 205.509/, Ma(3,112)/ 216.093
     *  /, Ma(4,112)/ 223.365/, Ma(5,112)/ 226.669/, Ma(6,112)/ 231.183/
       data Ma(1,113)/54216.0/, Ma(2,113)/ 208.341/, Ma(3,113)/ 218.698
     *  /, Ma(4,113)/ 225.530/, Ma(5,113)/ 228.564/, Ma(6,113)/ 232.591/
       data Ma(1,114)/54241.0/, Ma(2,114)/ 211.569/, Ma(3,114)/ 221.667
     *  /, Ma(4,114)/ 228.123/, Ma(5,114)/ 230.943/, Ma(6,114)/ 234.571/
       data Ma(1,115)/54266.0/, Ma(2,115)/ 214.273/, Ma(3,115)/ 224.448
     *  /, Ma(4,115)/ 230.844/, Ma(5,115)/ 233.604/, Ma(6,115)/ 237.044/
       data Ma(1,116)/54291.0/, Ma(2,116)/ 214.741/, Ma(3,116)/ 224.704
     *  /, Ma(4,116)/ 231.023/, Ma(5,116)/ 233.760/, Ma(6,116)/ 237.153/
       data Ma(1,117)/54316.0/, Ma(2,117)/ 211.850/, Ma(3,117)/ 221.445
     *  /, Ma(4,117)/ 227.719/, Ma(5,117)/ 230.472/, Ma(6,117)/ 233.949/
       data Ma(1,118)/54341.0/, Ma(2,118)/ 207.761/, Ma(3,118)/ 217.153
     *  /, Ma(4,118)/ 223.473/, Ma(5,118)/ 226.286/, Ma(6,118)/ 229.927/
       data Ma(1,119)/54366.0/, Ma(2,119)/ 204.162/, Ma(3,119)/ 213.403
     *  /, Ma(4,119)/ 219.797/, Ma(5,119)/ 222.686/, Ma(6,119)/ 226.522/
       data Ma(1,120)/54391.0/, Ma(2,120)/ 201.466/, Ma(3,120)/ 210.610
     *  /, Ma(4,120)/ 217.147/, Ma(5,120)/ 220.161/, Ma(6,120)/ 224.282/
       data Ma(1,121)/54416.0/, Ma(2,121)/ 199.928/, Ma(3,121)/ 209.143
     *  /, Ma(4,121)/ 216.053/, Ma(5,121)/ 219.328/, Ma(6,121)/ 223.977/
       data Ma(1,122)/54441.0/, Ma(2,122)/ 198.279/, Ma(3,122)/ 207.146
     *  /, Ma(4,122)/ 214.402/, Ma(5,122)/ 218.007/, Ma(6,122)/ 223.463/
       data Ma(1,123)/54466.0/, Ma(2,123)/ 194.478/, Ma(3,123)/ 201.560
     *  /, Ma(4,123)/ 208.238/, Ma(5,123)/ 211.796/, Ma(6,123)/ 217.706/
       data Ma(1,124)/54491.0/, Ma(2,124)/ 189.563/, Ma(3,124)/ 194.276
     *  /, Ma(4,124)/ 199.608/, Ma(5,124)/ 202.681/, Ma(6,124)/ 208.297/
       data Ma(1,125)/54516.0/, Ma(2,125)/ 186.178/, Ma(3,125)/ 189.338
     *  /, Ma(4,125)/ 193.642/, Ma(5,125)/ 196.286/, Ma(6,125)/ 201.486/
       data Ma(1,126)/54541.0/, Ma(2,126)/ 184.818/, Ma(3,126)/ 187.361
     *  /, Ma(4,126)/ 191.180/, Ma(5,126)/ 193.610/, Ma(6,126)/ 198.573/
       data Ma(1,127)/54566.0/, Ma(2,127)/ 184.823/, Ma(3,127)/ 187.252
     *  /, Ma(4,127)/ 190.912/, Ma(5,127)/ 193.265/, Ma(6,127)/ 198.128/
       data Ma(1,128)/54591.0/, Ma(2,128)/ 185.771/, Ma(3,128)/ 188.389
     *  /, Ma(4,128)/ 192.085/, Ma(5,128)/ 194.438/, Ma(6,128)/ 199.278/
       data Ma(1,129)/54616.0/, Ma(2,129)/ 187.871/, Ma(3,129)/ 190.808
     *  /, Ma(4,129)/ 194.654/, Ma(5,129)/ 197.065/, Ma(6,129)/ 201.933/
       data Ma(1,130)/54641.0/, Ma(2,130)/ 190.821/, Ma(3,130)/ 194.268
     *  /, Ma(4,130)/ 198.393/, Ma(5,130)/ 200.910/, Ma(6,130)/ 205.855/
       data Ma(1,131)/54666.0/, Ma(2,131)/ 193.697/, Ma(3,131)/ 197.766
     *  /, Ma(4,131)/ 202.272/, Ma(5,131)/ 204.948/, Ma(6,131)/ 210.024/
       data Ma(1,132)/54691.0/, Ma(2,132)/ 195.471/, Ma(3,132)/ 200.241
     *  /, Ma(4,132)/ 205.221/, Ma(5,132)/ 208.097/, Ma(6,132)/ 213.366/
       data Ma(1,133)/54716.0/, Ma(2,133)/ 196.727/, Ma(3,133)/ 202.361
     *  /, Ma(4,133)/ 207.923/, Ma(5,133)/ 211.044/, Ma(6,133)/ 216.563/
       data Ma(1,134)/54741.0/, Ma(2,134)/ 197.563/, Ma(3,134)/ 204.125
     *  /, Ma(4,134)/ 210.316/, Ma(5,134)/ 213.695/, Ma(6,134)/ 219.479/
       data Ma(1,135)/54766.0/, Ma(2,135)/ 198.112/, Ma(3,135)/ 205.595
     *  /, Ma(4,135)/ 212.380/, Ma(5,135)/ 216.001/, Ma(6,135)/ 222.020/
       data Ma(1,136)/54791.0/, Ma(2,136)/ 198.794/, Ma(3,136)/ 207.161
     *  /, Ma(4,136)/ 214.474/, Ma(5,136)/ 218.293/, Ma(6,136)/ 224.470/
       data Ma(1,137)/54816.0/, Ma(2,137)/ 200.134/, Ma(3,137)/ 209.365
     *  /, Ma(4,137)/ 217.128/, Ma(5,137)/ 221.090/, Ma(6,137)/ 227.332/
       data Ma(1,138)/54841.0/, Ma(2,138)/ 201.155/, Ma(3,138)/ 210.820
     *  /, Ma(4,138)/ 218.700/, Ma(5,138)/ 222.652/, Ma(6,138)/ 228.741/
       data Ma(1,139)/54866.0/, Ma(2,139)/ 203.687/, Ma(3,139)/ 213.947
     *  /, Ma(4,139)/ 221.938/, Ma(5,139)/ 225.850/, Ma(6,139)/ 231.699/
       data Ma(1,140)/54891.0/, Ma(2,140)/ 206.027/, Ma(3,140)/ 216.765
     *  /, Ma(4,140)/ 224.780/, Ma(5,140)/ 228.603/, Ma(6,140)/ 234.142/
       data Ma(1,141)/54916.0/, Ma(2,141)/ 208.976/, Ma(3,141)/ 219.498
     *  /, Ma(4,141)/ 227.098/, Ma(5,141)/ 230.663/, Ma(6,141)/ 235.713/
       data Ma(1,142)/54941.0/, Ma(2,142)/ 212.468/, Ma(3,142)/ 223.117
     *  /, Ma(4,142)/ 230.568/, Ma(5,142)/ 234.000/, Ma(6,142)/ 238.717/
       data Ma(1,143)/54966.0/, Ma(2,143)/ 215.371/, Ma(3,143)/ 226.248
     *  /, Ma(4,143)/ 233.695/, Ma(5,143)/ 237.080/, Ma(6,143)/ 241.604/
       data Ma(1,144)/54991.0/, Ma(2,144)/ 215.522/, Ma(3,144)/ 226.034
     *  /, Ma(4,144)/ 233.285/, Ma(5,144)/ 236.590/, Ma(6,144)/ 240.977/
       data Ma(1,145)/55016.0/, Ma(2,145)/ 211.838/, Ma(3,145)/ 221.975
     *  /, Ma(4,145)/ 229.113/, Ma(5,145)/ 232.383/, Ma(6,145)/ 236.763/
       data Ma(1,146)/55041.0/, Ma(2,146)/ 207.545/, Ma(3,146)/ 217.380
     *  /, Ma(4,146)/ 224.393/, Ma(5,146)/ 227.624/, Ma(6,146)/ 231.995/
       data Ma(1,147)/55066.0/, Ma(2,147)/ 203.426/, Ma(3,147)/ 212.877
     *  /, Ma(4,147)/ 219.675/, Ma(5,147)/ 222.822/, Ma(6,147)/ 227.129/
       data Ma(1,148)/55091.0/, Ma(2,148)/ 199.990/, Ma(3,148)/ 209.009
     *  /, Ma(4,148)/ 215.519/, Ma(5,148)/ 218.541/, Ma(6,148)/ 222.714/
       data Ma(1,149)/55116.0/, Ma(2,149)/ 197.742/, Ma(3,149)/ 206.447
     *  /, Ma(4,149)/ 212.716/, Ma(5,149)/ 215.628/, Ma(6,149)/ 219.665/
       data Ma(1,150)/55141.0/, Ma(2,150)/ 196.094/, Ma(3,150)/ 204.424
     *  /, Ma(4,150)/ 210.467/, Ma(5,150)/ 213.288/, Ma(6,150)/ 217.244/
       data Ma(1,151)/55166.0/, Ma(2,151)/ 195.507/, Ma(3,151)/ 203.795
     *  /, Ma(4,151)/ 209.893/, Ma(5,151)/ 212.769/, Ma(6,151)/ 216.860/
       data Ma(1,152)/55191.0/, Ma(2,152)/ 194.851/, Ma(3,152)/ 203.071
     *  /, Ma(4,152)/ 209.447/, Ma(5,152)/ 212.544/, Ma(6,152)/ 217.127/
       data Ma(1,153)/55216.0/, Ma(2,153)/ 193.099/, Ma(3,153)/ 200.688
     *  /, Ma(4,153)/ 207.199/, Ma(5,153)/ 210.544/, Ma(6,153)/ 215.861/
       data Ma(1,154)/55241.0/, Ma(2,154)/ 189.792/, Ma(3,154)/ 195.537
     *  /, Ma(4,154)/ 201.243/, Ma(5,154)/ 204.404/, Ma(6,154)/ 209.959/
       data Ma(1,155)/55266.0/, Ma(2,155)/ 187.117/, Ma(3,155)/ 190.922
     *  /, Ma(4,155)/ 195.435/, Ma(5,155)/ 198.136/, Ma(6,155)/ 203.338/
       data Ma(1,156)/55291.0/, Ma(2,156)/ 186.466/, Ma(3,156)/ 189.167
     *  /, Ma(4,156)/ 192.897/, Ma(5,156)/ 195.262/, Ma(6,156)/ 200.105/
       data Ma(1,157)/55316.0/, Ma(2,157)/ 187.617/, Ma(3,157)/ 189.882
     *  /, Ma(4,157)/ 193.268/, Ma(5,157)/ 195.477/, Ma(6,157)/ 200.123/
       data Ma(1,158)/55341.0/, Ma(2,158)/ 190.116/, Ma(3,158)/ 192.438
     *  /, Ma(4,158)/ 195.808/, Ma(5,158)/ 198.010/, Ma(6,158)/ 202.618/
       data Ma(1,159)/55366.0/, Ma(2,159)/ 192.107/, Ma(3,159)/ 194.725
     *  /, Ma(4,159)/ 198.299/, Ma(5,159)/ 200.591/, Ma(6,159)/ 205.293/
       data Ma(1,160)/55391.0/, Ma(2,160)/ 193.725/, Ma(3,160)/ 196.887
     *  /, Ma(4,160)/ 200.850/, Ma(5,160)/ 203.317/, Ma(6,160)/ 208.220/
       data Ma(1,161)/55416.0/, Ma(2,161)/ 194.976/, Ma(3,161)/ 198.886
     *  /, Ma(4,161)/ 203.399/, Ma(5,161)/ 206.110/, Ma(6,161)/ 211.307/
       data Ma(1,162)/55441.0/, Ma(2,162)/ 195.828/, Ma(3,162)/ 200.627
     *  /, Ma(4,162)/ 205.793/, Ma(5,162)/ 208.796/, Ma(6,162)/ 214.344/
       data Ma(1,163)/55466.0/, Ma(2,163)/ 196.455/, Ma(3,163)/ 202.201
     *  /, Ma(4,163)/ 208.047/, Ma(5,163)/ 211.349/, Ma(6,163)/ 217.252/
       data Ma(1,164)/55491.0/, Ma(2,164)/ 197.393/, Ma(3,164)/ 204.148
     *  /, Ma(4,164)/ 210.679/, Ma(5,164)/ 214.272/, Ma(6,164)/ 220.495/
       data Ma(1,165)/55516.0/, Ma(2,165)/ 198.541/, Ma(3,165)/ 206.139
     *  /, Ma(4,165)/ 213.197/, Ma(5,165)/ 216.999/, Ma(6,165)/ 223.415/
       data Ma(1,166)/55541.0/, Ma(2,166)/ 200.325/, Ma(3,166)/ 208.675
     *  /, Ma(4,166)/ 216.123/, Ma(5,166)/ 220.049/, Ma(6,166)/ 226.505/
       data Ma(1,167)/55566.0/, Ma(2,167)/ 202.587/, Ma(3,167)/ 211.714
     *  /, Ma(4,167)/ 219.499/, Ma(5,167)/ 223.506/, Ma(6,167)/ 229.899/
       data Ma(1,168)/55591.0/, Ma(2,168)/ 204.965/, Ma(3,168)/ 214.459
     *  /, Ma(4,168)/ 222.254/, Ma(5,168)/ 226.181/, Ma(6,168)/ 232.310/
       data Ma(1,169)/55616.0/, Ma(2,169)/ 208.350/, Ma(3,169)/ 218.114
     *  /, Ma(4,169)/ 225.866/, Ma(5,169)/ 229.705/, Ma(6,169)/ 235.538/
       data Ma(1,170)/55641.0/, Ma(2,170)/ 212.207/, Ma(3,170)/ 222.510
     *  /, Ma(4,170)/ 230.380/, Ma(5,170)/ 234.199/, Ma(6,170)/ 239.808/
       data Ma(1,171)/55666.0/, Ma(2,171)/ 215.270/, Ma(3,171)/ 225.718
     *  /, Ma(4,171)/ 233.554/, Ma(5,171)/ 237.322/, Ma(6,171)/ 242.726/
       data Ma(1,172)/55691.0/, Ma(2,172)/ 214.529/, Ma(3,172)/ 224.745
     *  /, Ma(4,172)/ 232.489/, Ma(5,172)/ 236.207/, Ma(6,172)/ 241.507/
       data Ma(1,173)/55716.0/, Ma(2,173)/ 211.100/, Ma(3,173)/ 221.198
     *  /, Ma(4,173)/ 228.916/, Ma(5,173)/ 232.617/, Ma(6,173)/ 237.900/
       data Ma(1,174)/55741.0/, Ma(2,174)/ 207.055/, Ma(3,174)/ 216.974
     *  /, Ma(4,174)/ 224.593/, Ma(5,174)/ 228.249/, Ma(6,174)/ 233.490/
       data Ma(1,175)/55766.0/, Ma(2,175)/ 203.037/, Ma(3,175)/ 212.626
     *  /, Ma(4,175)/ 220.006/, Ma(5,175)/ 223.551/, Ma(6,175)/ 228.656/
       data Ma(1,176)/55791.0/, Ma(2,176)/ 199.767/, Ma(3,176)/ 209.008
     *  /, Ma(4,176)/ 216.075/, Ma(5,176)/ 219.462/, Ma(6,176)/ 224.346/
       data Ma(1,177)/55816.0/, Ma(2,177)/ 197.250/, Ma(3,177)/ 206.054
     *  /, Ma(4,177)/ 212.713/, Ma(5,177)/ 215.895/, Ma(6,177)/ 220.479/
       data Ma(1,178)/55841.0/, Ma(2,178)/ 195.592/, Ma(3,178)/ 203.963
     *  /, Ma(4,178)/ 210.198/, Ma(5,178)/ 213.156/, Ma(6,178)/ 217.399/
       data Ma(1,179)/55866.0/, Ma(2,179)/ 194.973/, Ma(3,179)/ 203.067
     *  /, Ma(4,179)/ 208.968/, Ma(5,179)/ 211.741/, Ma(6,179)/ 215.680/
       data Ma(1,180)/55891.0/, Ma(2,180)/ 194.547/, Ma(3,180)/ 202.260
     *  /, Ma(4,180)/ 207.853/, Ma(5,180)/ 210.472/, Ma(6,180)/ 214.186/
       data Ma(1,181)/55916.0/, Ma(2,181)/ 194.964/, Ma(3,181)/ 202.712
     *  /, Ma(4,181)/ 208.301/, Ma(5,181)/ 210.921/, Ma(6,181)/ 214.626/
       data Ma(1,182)/55941.0/, Ma(2,182)/ 195.382/, Ma(3,182)/ 203.317
     *  /, Ma(4,182)/ 209.171/, Ma(5,182)/ 211.958/, Ma(6,182)/ 215.972/
       data Ma(1,183)/55966.0/, Ma(2,183)/ 195.167/, Ma(3,183)/ 203.114
     *  /, Ma(4,183)/ 209.368/, Ma(5,183)/ 212.466/, Ma(6,183)/ 217.166/
       data Ma(1,184)/55991.0/, Ma(2,184)/ 193.995/, Ma(3,184)/ 200.839
     *  /, Ma(4,184)/ 206.909/, Ma(5,184)/ 210.123/, Ma(6,184)/ 215.456/
       data Ma(1,185)/56016.0/, Ma(2,185)/ 192.437/, Ma(3,185)/ 197.183
     *  /, Ma(4,185)/ 202.143/, Ma(5,185)/ 204.998/, Ma(6,185)/ 210.250/
       data Ma(1,186)/56041.0/, Ma(2,186)/ 191.897/, Ma(3,186)/ 195.009
     *  /, Ma(4,186)/ 198.918/, Ma(5,186)/ 201.354/, Ma(6,186)/ 206.214/
       data Ma(1,187)/56066.0/, Ma(2,187)/ 192.109/, Ma(3,187)/ 194.433
     *  /, Ma(4,187)/ 197.822/, Ma(5,187)/ 200.040/, Ma(6,187)/ 204.667/
       data Ma(1,188)/56091.0/, Ma(2,188)/ 192.852/, Ma(3,188)/ 195.066
     *  /, Ma(4,188)/ 198.403/, Ma(5,188)/ 200.606/, Ma(6,188)/ 205.229/
       data Ma(1,189)/56116.0/, Ma(2,189)/ 193.572/, Ma(3,189)/ 196.097
     *  /, Ma(4,189)/ 199.699/, Ma(5,189)/ 202.030/, Ma(6,189)/ 206.835/
       data Ma(1,190)/56141.0/, Ma(2,190)/ 194.028/, Ma(3,190)/ 197.133
     *  /, Ma(4,190)/ 201.203/, Ma(5,190)/ 203.759/, Ma(6,190)/ 208.867/
       data Ma(1,191)/56166.0/, Ma(2,191)/ 194.434/, Ma(3,191)/ 198.305
     *  /, Ma(4,191)/ 202.978/, Ma(5,191)/ 205.813/, Ma(6,191)/ 211.297/
       data Ma(1,192)/56191.0/, Ma(2,192)/ 195.191/, Ma(3,192)/ 199.925
     *  /, Ma(4,192)/ 205.248/, Ma(5,192)/ 208.378/, Ma(6,192)/ 214.245/
       data Ma(1,193)/56216.0/, Ma(2,193)/ 196.213/, Ma(3,193)/ 201.699
     *  /, Ma(4,193)/ 207.552/, Ma(5,193)/ 210.912/, Ma(6,193)/ 217.048/
       data Ma(1,194)/56241.0/, Ma(2,194)/ 198.255/, Ma(3,194)/ 204.557
     *  /, Ma(4,194)/ 210.908/, Ma(5,194)/ 214.465/, Ma(6,194)/ 220.778/
       data Ma(1,195)/56266.0/, Ma(2,195)/ 200.326/, Ma(3,195)/ 207.367
     *  /, Ma(4,195)/ 214.120/, Ma(5,195)/ 217.811/, Ma(6,195)/ 224.179/
       data Ma(1,196)/56291.0/, Ma(2,196)/ 203.093/, Ma(3,196)/ 210.487
     *  /, Ma(4,196)/ 217.328/, Ma(5,196)/ 221.002/, Ma(6,196)/ 227.210/
       data Ma(1,197)/56316.0/, Ma(2,197)/ 206.563/, Ma(3,197)/ 214.518
     *  /, Ma(4,197)/ 221.547/, Ma(5,197)/ 225.247/, Ma(6,197)/ 231.310/
       data Ma(1,198)/56341.0/, Ma(2,198)/ 210.655/, Ma(3,198)/ 219.316
     *  /, Ma(4,198)/ 226.621/, Ma(5,198)/ 230.381/, Ma(6,198)/ 236.327/
       data Ma(1,199)/56366.0/, Ma(2,199)/ 213.483/, Ma(3,199)/ 222.320
     *  /, Ma(4,199)/ 229.674/, Ma(5,199)/ 233.421/, Ma(6,199)/ 239.231/
       data Ma(1,200)/56391.0/, Ma(2,200)/ 211.956/, Ma(3,200)/ 220.861
     *  /, Ma(4,200)/ 228.322/, Ma(5,200)/ 232.103/, Ma(6,200)/ 237.908/
       data Ma(1,201)/56416.0/, Ma(2,201)/ 208.963/, Ma(3,201)/ 218.047
     *  /, Ma(4,201)/ 225.655/, Ma(5,201)/ 229.488/, Ma(6,201)/ 235.336/
       data Ma(1,202)/56441.0/, Ma(2,202)/ 205.328/, Ma(3,202)/ 214.484
     *  /, Ma(4,202)/ 222.141/, Ma(5,202)/ 225.982/, Ma(6,202)/ 231.833/
       data Ma(1,203)/56466.0/, Ma(2,203)/ 201.741/, Ma(3,203)/ 210.820
     *  /, Ma(4,203)/ 218.369/, Ma(5,203)/ 222.149/, Ma(6,203)/ 227.901/
       data Ma(1,204)/56491.0/, Ma(2,204)/ 198.902/, Ma(3,204)/ 207.850
     *  /, Ma(4,204)/ 215.210/, Ma(5,204)/ 218.874/, Ma(6,204)/ 224.439/
       data Ma(1,205)/56516.0/, Ma(2,205)/ 196.568/, Ma(3,205)/ 205.210
     *  /, Ma(4,205)/ 212.220/, Ma(5,205)/ 215.696/, Ma(6,205)/ 220.960/
       data Ma(1,206)/56541.0/, Ma(2,206)/ 195.208/, Ma(3,206)/ 203.641
     *  /, Ma(4,206)/ 210.313/, Ma(5,206)/ 213.586/, Ma(6,206)/ 218.489/
       data Ma(1,207)/56566.0/, Ma(2,207)/ 194.461/, Ma(3,207)/ 202.583
     *  /, Ma(4,207)/ 208.850/, Ma(5,207)/ 211.892/, Ma(6,207)/ 216.398/
       data Ma(1,208)/56591.0/, Ma(2,208)/ 194.450/, Ma(3,208)/ 202.321
     *  /, Ma(4,208)/ 208.231/, Ma(5,208)/ 211.063/, Ma(6,208)/ 215.184/
       data Ma(1,209)/56616.0/, Ma(2,209)/ 195.130/, Ma(3,209)/ 202.942
     *  /, Ma(4,209)/ 208.614/, Ma(5,209)/ 211.291/, Ma(6,209)/ 215.113/
       data Ma(1,210)/56641.0/, Ma(2,210)/ 195.977/, Ma(3,210)/ 203.763
     *  /, Ma(4,210)/ 209.292/, Ma(5,210)/ 211.874/, Ma(6,210)/ 215.493/
       data Ma(1,211)/56666.0/, Ma(2,211)/ 196.867/, Ma(3,211)/ 204.666
     *  /, Ma(4,211)/ 210.189/, Ma(5,211)/ 212.760/, Ma(6,211)/ 216.345/
       data Ma(1,212)/56691.0/, Ma(2,212)/ 197.719/, Ma(3,212)/ 205.654
     *  /, Ma(4,212)/ 211.375/, Ma(5,212)/ 214.064/, Ma(6,212)/ 217.848/
       data Ma(1,213)/56716.0/, Ma(2,213)/ 198.605/, Ma(3,213)/ 206.798
     *  /, Ma(4,213)/ 212.962/, Ma(5,213)/ 215.934/, Ma(6,213)/ 220.245/
       data Ma(1,214)/56741.0/, Ma(2,214)/ 198.487/, Ma(3,214)/ 206.526
     *  /, Ma(4,214)/ 213.087/, Ma(5,214)/ 216.402/, Ma(6,214)/ 221.519/
       data Ma(1,215)/56766.0/, Ma(2,215)/ 197.195/, Ma(3,215)/ 203.747
     *  /, Ma(4,215)/ 209.818/, Ma(5,215)/ 213.108/, Ma(6,215)/ 218.695/
       data Ma(1,216)/56791.0/, Ma(2,216)/ 195.333/, Ma(3,216)/ 199.742
     *  /, Ma(4,216)/ 204.593/, Ma(5,216)/ 207.448/, Ma(6,216)/ 212.797/
       data Ma(1,217)/56816.0/, Ma(2,217)/ 194.108/, Ma(3,217)/ 197.164
     *  /, Ma(4,217)/ 201.169/, Ma(5,217)/ 203.686/, Ma(6,217)/ 208.727/
       data Ma(1,218)/56841.0/, Ma(2,218)/ 193.412/, Ma(3,218)/ 195.992
     *  /, Ma(4,218)/ 199.732/, Ma(5,218)/ 202.152/, Ma(6,218)/ 207.130/
       data Ma(1,219)/56866.0/, Ma(2,219)/ 192.999/, Ma(3,219)/ 195.653
     *  /, Ma(4,219)/ 199.533/, Ma(5,219)/ 202.030/, Ma(6,219)/ 207.160/
       data Ma(1,220)/56891.0/, Ma(2,220)/ 192.988/, Ma(3,220)/ 195.988
     *  /, Ma(4,220)/ 200.180/, Ma(5,220)/ 202.832/, Ma(6,220)/ 208.204/
       data Ma(1,221)/56916.0/, Ma(2,221)/ 193.824/, Ma(3,221)/ 197.312
     *  /, Ma(4,221)/ 201.873/, Ma(5,221)/ 204.696/, Ma(6,221)/ 210.295/
       data Ma(1,222)/56941.0/, Ma(2,222)/ 195.363/, Ma(3,222)/ 199.417
     *  /, Ma(4,222)/ 204.356/, Ma(5,222)/ 207.342/, Ma(6,222)/ 213.116/
       data Ma(1,223)/56966.0/, Ma(2,223)/ 197.480/, Ma(3,223)/ 201.956
     *  /, Ma(4,223)/ 207.127/, Ma(5,223)/ 210.190/, Ma(6,223)/ 215.992/
       data Ma(1,224)/56991.0/, Ma(2,224)/ 200.452/, Ma(3,224)/ 205.321
     *  /, Ma(4,224)/ 210.678/, Ma(5,224)/ 213.793/, Ma(6,224)/ 219.551/
       data Ma(1,225)/57016.0/, Ma(2,225)/ 204.100/, Ma(3,225)/ 209.637
     *  /, Ma(4,225)/ 215.304/, Ma(5,225)/ 218.509/, Ma(6,225)/ 224.227/
c+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
c
c      mark the frequency
c
         js=0
         if(freq.lt.f(1))then
            js=1
         else if(freq.gt.f(5))then
            js=4
         else
         do j=1,4
               if(freq.gt.f(j).and.freq.le.f(j+1))js=j
         enddo
         end if
c
c     mark the mjd
c
         imjd=1
         mjdl =  Ma(1,1)
         
         do while (mjd.ge.Ma(1,imjd))
              do i=1,5
               tl(i) = Ma(i+1,imjd)
              end do
         mjdl=Ma(1,imjd)
         imjd=1+imjd
         end do
         mjdn=Ma(1,imjd)
              do i=1,5
               tn(i) = Ma(i+1,imjd)
              end do
          
         a=(mjd-mjdl)/(mjdn-mjdl)
         b=(freq-f(js))/(f(js+1)-f(js))
         marstb=a*b*tn(js+1) + a*(1.-b)*tn(js) + b*(1.-a)*tl(js+1)
     *              + (1.-a)*(1.-b)*tl(js)
         return
         end

        subroutine smaplpar(jday,iplanet,bmaj,bmin,bpa,domsg)
c
        implicit none
        double precision jday
        real bmaj,bmin,bpa,mjd
        integer iplanet 
        logical domsg
c
c  Return information about the apparent properties of a planet
c  at a given time for the small planets and moons
c
c  Input:
c    jday       Julian day, in the TDB timescale.
c    iplanet         Planet number.
c  Output:
c    bmaj,bmin,bpa The apparent major and minor planet axes, in radians, and
c               its position angle for the small planets and moons:
c               Callisto, Ganymede, Ceres, Io, Titan, Vesta,Pallas 
c------------------------------------------------------------------------
        real oblate(20),a,b,f1,f2,f3
        real mjdf,ra,dec,diam_a,selat,nppa
        logical update
        integer j, ip, len1
        character smadir*82,line*1
        common/smadata/smadir
        character planet*8
        include 'mirconst.h'
        integer NPLANETS
        parameter(NPLANETS=16)
        character planets(NPLANETS)*8
        integer np(NPLANETS)
c add sma iplanet mapping
        data planets /'callisto','ceres   ','earth   ',
     *     'ganymede','io      ','jupiter ','mars    ',
     *     'mercury ','neptune ','pallas  ','pluto   ',
     *     'saturn  ','titan   ','uranus  ','venus   ',
     *     'vesta   '/
        data np     / 11,       12,        3,
     *      10,       13,        5,        4,
     *       1,        8,       14,        9,
     *       6,       16,        7,        2,       
     *      15/
        ip=1
        do while(iplanet.ne.np(ip))
        ip=ip+1
        end do
        planet=planets(ip)
        call ucase(planet(1:1))
c  assign  the value of planet oblate
        oblate(1)=0.00e-0         !mercury        
        oblate(2)=0.00e-0         !venus
        oblate(3)=0.00e-0         !
        oblate(4)=6.48e-3         !mars
        oblate(5)=6.49e-2         !jupiter
        oblate(6)=9.80e-2         !saturn
        oblate(7)=2.29e-2         !uranus
        oblate(8)=1.71e-2         !neptune
        do j=9,20
        oblate(j)=0.0
        enddo
c  convert Julian date to mjd
        mjd=jday-2400000.5
c  read the ephemeris data
         open(unit=10, file=
     *  smadir(1:len1(smadir))//planet(1:len1(planet))//'.ephem.dat',
     *  status='old')
c  read the comments line in the file header
         line(1:1)='!'
         do while(line(1:1).eq.'!')
            read(10,'(a)')line
         enddo
c read the ephemris data on the date macth the input mjd
           mjdf = 0.0
           update=.true.
           do while (int(mjdf).lt.int(mjd))
           read (10,*,err=100) mjdf,ra,dec,diam_a,selat,nppa
           end do
           close(10)
           goto 200
100        update=.false.
200        if(.not.update) 
     *     call bug('f', 'End of the ephemeris data file.')
c     from the sub-earth latitude (which is planetographic from 
c     HORIZONS) determine the planetocentric sub-earth latitude.
          selat=atan( (1.-oblate(iplanet))**2 * tan(selat*pi/180.) )
          selat=selat*180./pi       
c     from to planetocentric sub-earth latitude and the oblateness,
c     determine the ratio of the apparent semi-minor to apparent semi-
c     major axes of the planet on the sky.  then multiply by apparent
c     equatorial diameter of the planet on the sky (in arcseconds) to
c     determine the apparent minor diameter.  derivation available from
c     M. Gurwell upon request.
      a=1.                      !semi-major axis, normalized
      b=(1.-oblate(iplanet))    !semi-minor axis, normalized
      f1=sin(selat*pi/180.)**2/a**2 + cos(selat*pi/180.)**2/b**2
      f2=sin(selat*pi/180.)**2*cos(selat*pi/180.)**2
      f2=f2*(1./b**2-1./a**2)**2
      f3=cos(selat*pi/180.)**2/a**2 + sin(selat*pi/180.)**2/b**2.
c determine diameters of major axis and minor axis (pole axis)
c of the planets on the sky.
      bmaj = diam_a
      bmin = diam_a * 1./(f1-f2/f3)**0.5
      bpa  = nppa               !??????
c 
c need to look into the relationship between bpa in miriad
c and nppa in SMA planet model. For the small planets and moons
c the difference between bmaj and bmin
c
         if(domsg) then
         write(*,*) 'D_maj(")  D_min(")  NPPA (deg)'
         write(*,500) bmaj,bmin,bpa
         end if
c       convert to radian
         bmaj=bmaj*pi/180./3600.
         bmin=bmin*pi/180./3600.
         bpa=bpa*pi/180.
500     format(1x,3(f6.2,4x))
        end


