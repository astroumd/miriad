C
C Include file for program LISTOBS
C
C   Amount of space needed: ~ (22+MAXANT)*MAXP words ('REAL's)
C
        integer MAXP,MAXF, MAXSPECT
        parameter (MAXP = 5000 )
        parameter (MAXF = 50 )
        parameter (MAXSPECT = 8)
 
        integer nspec,nchan,cmode(MAXP),nants,ncorbw,ncorfin
        real utst(MAXP),dur(MAXP),el(MAXP)
        real vel(MAXP),corbw(MAXP,MAXSPECT/2),syst(MAXP,MAXANT)
        real corfs(MAXP,MAXSPECT/2)
        real lst(MAXP),linefreq(MAXP),veldop(MAXP),flo(MAXP),
     1       iffreq(MAXP)
        character objs(MAXP)*9,linname(MAXP)*8,veltype(MAXP)*10
        double precision jday(MAXP), ra(MAXP),dec(MAXP)
        common /prarra_i/ nspec,nchan,cmode,nants,ncorbw,ncorfin
        common /prarra_r/ utst,dur,el,vel,corbw,flo,iffreq,
     1                      syst,corfs,lst,linefreq,veldop
        common /prarra_c/ objs,linname,veltype
        common /prarra_d/ jday, ra, dec
