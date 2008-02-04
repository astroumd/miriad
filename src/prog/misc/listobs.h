C
C Include file for program LISTOBS - now CARMA specific
c BIMA version is in the MIR3 release of MIRIAD
C
C   Amount of space needed: ~ (22+MAXANT)*MAXP words ('REAL's)
C   MAXP = 
C   MAXF = 
C   MAXSPECT = spectral windows (6 for CARMA old correlator)
C
        integer MAXP,MAXF,MAXSPECT
        parameter (MAXP = 5000 )
        parameter (MAXF = 50 )
        parameter (MAXSPECT = 6)
 
        integer nspec,nchan,nants,ncorbw,ncorfin
        real utst(MAXP),dur(MAXP),el(MAXP)
        real vel(MAXP),syst(MAXP,MAXANT)
        integer corbw(MAXP,MAXSPECT/2)
        real corfs(MAXP,MAXSPECT/2)
        real lst(MAXP),linefreq(MAXP),veldop(MAXP),flo(MAXP),
     1       iffreq(MAXP)
        character objs(MAXP)*17,linname(MAXP)*8,veltype(MAXP)*10
        character purpose(MAXP)*5
        double precision jday(MAXP), ra(MAXP),dec(MAXP)
        common /prarra_i/ nspec,nchan,cmode,nants,ncorbw,ncorfin,corbw
        common /prarra_r/ utst,dur,el,vel,flo,iffreq,
     1                      syst,corfs,lst,linefreq,veldop
        common /prarra_c/ objs,linname,veltype,purpose
        common /prarra_d/ jday, ra, dec
