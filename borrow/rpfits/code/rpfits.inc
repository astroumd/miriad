C---------------------- COMMONS FOR RPFITS ROUTINES --------------------
C
C                SEE RPFITS.DEFN FOR an EXPLANATION
C
C        Modifications:
C        rpn 7/11/88     added if table and if common
C        rpn 8/11/88     inserted an table and extended antenna common
C                        to include polarisation
C        rpn 9/11/88     major change in treatment of if's. For multi-if
C                        data, rpfits should be called once per if (i.e.
C                        several times per integration), with a formal
C                        parameter if_no varying from 1 to n_if.
C                        A new group will be written for each if.
C                        PTI data will continue to be written with
C                        NSTOK = 2.
C        rpn 9/11/88     added su and fg tables
C        rpn 8/2/89      dates changed from AEST to UT
C        rpn 10/2/89     changed INTEGER*4 declaration to INTEGER for
C                        AIPS.
C        rpn 17/2/89     Put in INDEX common
C        rpn 24/5/89     Put in VERSION string
C        rpn 27/7/89     Put in if_sampl, ant_mount, changed names of
C                        pressure etc to ant_...
C        rpn 10/10/89    put in su_found, if_found, etc.
C        rpn 11/10/89    put in MT commons
C        rpn 8/11/89     put in longer strings for first 4 variables in
C                        /NAMES/
C        rpn 8/11/89     put in su_rad, su_decd
C        rpn 20/3/90     put in su_num, if_num, and changed ant_no to
C                        ant_num.  Added sc common.  Put in write_wt,
C                        if_ref.
C        rpn 22/3/90     put in CU common
C        hm 11/5/90      removed tabs and changed real*4 to real
C                        also cut lines down to 72 characters
C        hm 2/7/90       removed unused variables and changed real*8
C                        to double precision.
C        hm 14/11/91     Added if_sumul and if_chain arrays to if table 
C                        - to handle sumiltaneous frequencies.
C        hm 11/3/92      Increased max_su from 16 to 500 to allow
C                        for mosaicing of up to 500 sources per scan.
C                        Allow for separate phase and pointing centres
C                        by adding new arrays for pointing centres -
C                        su_pra, su_pdec, su_prad, su_pdecd
C        hm 19/3/92      Added sc_srcno
C        hm 29/9/92      Increased max_card from 256 to 650
C        hm 23/6/93      Collected character variables into a single 
C                        common.
C        hm 08/12/93     Added intbase
C        hm 10/03/94     Added proper motion keywords PMRA, PMDEC, 
C                        PMEPOCH
C        hm 28/02/96     Change for multi-beam data. Data real not complex.
C                        Added data_format to be used by rpfitsout to
C                        determine how data is written - instead of 
C                        write_wt.
C        hm 14/02/97     Increase max antennas to 15 for multibeam.
C        hm 02/06/98     VERSION 2 RPFITS. Change char date formats to 
C                        YYYY-MM-DD stored in a 12 character string.
C        hm 04/11/1998   Version 2.1 RPFITS. Change VERSION to char*20
C                        and add rpfitsversion, also char*20

        integer ant_max, max_card, max_if, pol_max, max_su, max_fg,
     +        max_nx, max_mt, max_sc, max_cu
        parameter (ant_max=15, max_card=650, max_if=8, pol_max=8,
     +        max_su=500, max_fg=32, max_nx=256, max_mt=256,
     +        max_sc=16, max_cu=32)

        integer nstok, nfreq, ncount, nscan, ivelref, nant, ncard, 
     +        intime, rp_defeat, n_if, if_num(max_if), 
     +        if_invert(max_if), if_nfreq(max_if), 
     +        if_nstok(max_if), if_sampl(max_if), if_simul(max_if), 
     +        if_chain(max_if), ant_num(ant_max), n_su, su_num(max_su),
     +        n_fg, fg_ant(2,max_fg),fg_if(2, max_fg), 
     +        fg_chan(2, max_fg), fg_stok(2, max_fg), n_nx, 
     +        nx_rec(max_nx), ant_mount(ant_max),
     +        rp_iostat, n_mt, mt_ant(max_mt),
     +        sc_ant, sc_if, sc_q, n_cu, cu_ant(max_cu), 
     +        cu_if(max_cu), cu_ch1(max_cu), cu_ch2(max_cu),
     +        sc_srcno, data_format
 
      double precision ra, dec, freq, dfreq, rfreq, vel1, rp_utcmtai,
     +        rp_c(12), rp_djmrefp, rp_djmreft,x(ant_max), 
     +        y(ant_max), z(ant_max), if_freq(max_if), x_array, 
     +        y_array, z_array, axis_offset(ant_max),
     +        feed_pa(2,ant_max), feed_cal(ant_max, max_if, pol_max), 
     +        if_bw(max_if), fg_ut(2, max_fg), su_ra(max_su), 
     +        su_dec(max_su), su_rad(max_su), su_decd(max_su), 
     +        if_ref(max_if), nx_ut(max_nx), mt_press(max_mt), 
     +        mt_temp(max_mt), mt_humid(max_mt), mt_ut(max_mt), 
     +        cu_ut(max_cu), cu_cal1(max_cu), cu_cal2(max_cu),
     +        su_pra(max_su), su_pdec(max_su), su_prad(max_su),
     +        su_pdecd(max_su), pm_ra, pm_dec, pm_epoch

      real sc_ut, sc_cal(max_sc,max_if, ant_max), intbase

      character*2 feed_type(2,ant_max), if_cstok(4,max_if)
      character*16 object,instrument,cal,rp_observer
      character*8 sta(ant_max), coord, datsys
      character*20 version, rpfitsversion
      character*12 datobs, datwrit
      character*80 file
      character*80 card(max_card)
      character su_name(max_su)*16, su_cal(max_su)*4, 
     +       fg_reason(max_fg)*24, nx_date(max_nx)*12, 
     +       nx_source(max_nx)*16
      logical if_found, su_found, fg_found, nx_found, an_found, 
     +       mt_found, cu_found, write_wt

      common /doubles/ axis_offset, dec, dfreq, cu_cal1, cu_cal2, 
     +      cu_ut, feed_cal, feed_pa, fg_ut, freq, if_bw, if_ref, 
     +      if_freq, mt_humid, mt_press, mt_temp, mt_ut, nx_ut, 
     +      ra, rfreq, rp_c, rp_djmrefp, rp_djmreft, rp_utcmtai,
     +      su_dec, su_ra, su_rad, su_decd, su_pra, su_pdec, 
     +      su_prad, su_pdecd, vel1, x, x_array, y, y_array, z, 
     +      z_array
      common /proper/ pm_ra, pm_dec, pm_epoch
      common /param/ nstok, nfreq, ncount, intime, nscan, write_wt, 
     +       ncard, intbase, data_format
      common /spect/ ivelref
      common /anten/ nant, ant_num, ant_mount, an_found
      common /ephem/ rp_defeat
      common /if/ n_if, if_invert, if_nfreq, if_nstok,
     +        if_sampl, if_found, if_num, if_simul, if_chain
      common /su/ n_su, su_found, su_num
      common /fg/ n_fg, fg_ant, fg_if, fg_chan, fg_stok, fg_found
      common /nx/ n_nx, nx_rec, nx_found
      common /mt/ n_mt, mt_ant, mt_found
      common /index/ rp_iostat
      common /sc/ sc_ut, sc_ant, sc_if, sc_q, sc_cal, sc_srcno
      common /cu/ n_cu, cu_ant, cu_if, cu_ch1, cu_ch2, cu_found
      common /names/ object, instrument, cal, rp_observer, datobs, 
     +       datwrit, file, datsys, version, coord, sta, feed_type, 
     +       card, if_cstok, su_name, su_cal, fg_reason, nx_source, 
     +       nx_date, rpfitsversion


C     the following is for compatibility with early versions:
      double precision rp_pressure(ant_max), rp_temp(ant_max), 
     +    rp_humid(ant_max), ant_pressure(ant_max), 
     +    ant_temp(ant_max), ant_humid(ant_max)
      equivalence ( rp_pressure(1), ant_pressure(1))        
      equivalence ( rp_temp(1), ant_temp(1))        
      equivalence ( rp_humid(1), ant_humid(1))        
      equivalence ( mt_press(1), ant_pressure(1))        
      equivalence ( mt_temp(1), ant_temp(1))        
      equivalence ( mt_humid(1), ant_humid(1))        
