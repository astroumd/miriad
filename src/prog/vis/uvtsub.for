c************************************************************************
      PROGRAM uvtsub
c
      IMPLICIT NONE
c
c= uvtsub - subtract time-averaged "background" visibilities 
c& pjt
c: uv analysis
c+
c   UVTSUB subtracts a time-averaged background level from each
c   baseline. 
c
c     WARNING: This program does not apply gains. Since gain corrections 
c              are time-dependent, they must be applied to the data
c              before subtraction is carried out, or else subtraction
c              will not work correctly.
c
c@ vis
c	The name of the input uv data-set. No default.
c@ out
c       The name of the output uv data-set. No default.
c@ select
c	The normal uv selection commands. The default is copy everything.
c@ bckgrnd
c       The time interval used to determine the average visibilities 
c       for subtraction. This must be in the standard select= format,
c       e.g. 
c          bckgrnd=time(12:15:30,12:18:20),time(12:25:30,12:26:00)
c       would select two intervals to be used to determine the
c       "background" level for subtraction.
c--
c  History:
c    pjt   9feb95 Original
c    pjt  16feb95 messed around to get line/wide only data
c    pjt/sw 22feb95 Extra warning if gains present
c------------------------------------------------------------------------
      include 'maxdim.h'
      INTEGER MAXSELS
      PARAMETER(MAXSELS=256)
      CHARACTER version*(*)
      PARAMETER(version='UVTSUB: version 1.0 24-feb-95')
c
      CHARACTER vis*128,out*128,msg*72
      INTEGER tvis, tout, numchan, nchan, numbl, i, j, bl
      INTEGER numwide, nwcorr
      REAL sels(MAXSELS), tsels(MAXSELS)
      DOUBLE PRECISION preamble(4)
      INTEGER wcount(MAXBASE,MAXWIDE), count(MAXBASE,MAXCHAN)
      COMPLEX wcorr(MAXWIDE), corr(MAXCHAN), 
     *         waver(MAXBASE,MAXWIDE), aver(MAXBASE,MAXCHAN)
      LOGICAL wflags(MAXWIDE), flags(MAXCHAN), first
      LOGICAL doline, dowide, doboth
c
c  Externals.
c
      INTEGER getbase
      LOGICAL hexists
c
c  Get the input parameters.
c
      CALL output(version)
      CALL keyini
      CALL keyf('vis',vis,' ')
      CALL keya('out',out,' ')
      CALL SelInput('select',sels,MAXSELS)
      CALL SelInput('bckgrnd',tsels,MAXSELS)
      CALL keyfin
c
      IF(vis.EQ.' ')CALL bug('f','No input visibility given; in=')
      IF(out.EQ.' ')CALL bug('f','No output visibility given; out=')

c
c  Open the input, and determine some things about it.
c
      CALL uvopen(tVis,vis,'old')
      CALL SelApply(tVis,tsels,.TRUE.)
      CALL setup(tVis,doline,dowide)
      doboth = doline .AND. dowide

      IF(hexists(tVis,'gains')) then
       CALL output(' ')
       CALL bug('w','There are gains present in this dataset!')
       CALL output(' ')
       msg='This program does not apply gains and you will probably end'
       CALL output(msg)
       msg='up with spurious results since the gains vary with time!'
       CALL output(msg)
       CALL output(' ')
       msg='Use uvcat to create a new dataset with gains applied and'
       CALL output(msg)
       CALL output('run uvtsub on it.')
       CALL output(' ')
       CALL output('Continuing in case you want to do this anyway. ')
       CALL output(' ')
      ENDIF

      DO i=1,MAXCHAN
         DO bl=1,MAXBASE
            aver(bl,i) = CMPLX(0,0)
            count(bl,i) = 0
         ENDDO
      ENDDO
      DO i=1,MAXWIDE
         DO bl=1,MAXBASE
            waver(bl,i) = CMPLX(0,0)
            wcount(bl,i) = 0
         ENDDO
      ENDDO
      first = .TRUE.
      nchan = 1
      nwcorr = 0
      numbl = 0
      DO WHILE(nchan.GT.0) 
         CALL uvread(tVis,preamble,corr,flags,MAXCHAN,nchan)
         IF (nchan.GT.0) THEN
            IF(doboth) CALL uvwread(tVis,wcorr,wflags,MAXWIDE,nwcorr)
            IF (first) THEN
               numchan = nchan
               numwide = nwcorr
               first = .FALSE.
            ELSE
               IF(nchan.NE.numchan .OR. nwcorr.NE.numwide) CALL 
     *            bug('f',
     *           'Cannot handle datasets with changing channel number')
            ENDIF
            bl = getbase(preamble(4))
            numbl = MAX(bl,numbl)
            DO i=1,nchan
               IF (flags(i)) THEN
                  aver(bl,i) = aver(bl,i) + corr(i)
                  count(bl,i)= count(bl,i)+ 1
               ENDIF
            ENDDO
            DO i=1,nwcorr
               IF(wflags(i)) THEN
                  waver(bl,i) = waver(bl,i) + wcorr(i)
                  wcount(bl,i)= wcount(bl,i) + 1
               ENDIF
            ENDDO
         ENDIF
      ENDDO
      CALL uvclose(tVis)

      DO i=1,numchan
         DO j=1,numbl
            IF (count(j,i).GT.0) 
     *             aver(j,i) = aver(j,i)/REAL(count(j,i))
         ENDDO
      ENDDO
      DO i=1,numwide
         DO j=1,numbl
            IF (wcount(j,i).GT.0) 
     *             waver(j,i) = waver(j,i)/REAL(wcount(j,i))
         ENDDO
      ENDDO

      WRITE(*,*) 'Baseline      average LSB             average USB'
      DO j=1,numbl 
         IF (doboth) WRITE(*,*) j,waver(j,1),waver(j,2)
         IF (dowide.AND..NOT.doline)WRITE(*,*) j,aver(j,1),aver(j,2)
      ENDDO
c
c Re-open dataset and subtract the average
c
      CALL uvopen(tVis,vis,'old')
      CALL SelApply(tVis,sels,.TRUE.)

      CALL uvopen(tOut,out,'new')
      IF(dowide .AND. .NOT.doline) THEN
         WRITE(*,*) 'wide only data'
         CALL  uvset(tVis,'data','wide',0,1.,1.,1.)
         CALL  uvset(tOut,'data','wide',0,1.,1.,1.)
      ENDIF
      CALL trackall(tVis)
      CALL hdcopy(tVis,tOut, 'history')

      nchan = 1
      DO WHILE(nchan.GT.0) 
         CALL uvread(tVis,preamble,corr,flags,MAXCHAN,nchan)
         IF (nchan.GT.0) THEN
            IF(doboth) CALL uvwread(tVis,wcorr,wflags,MAXWIDE,nwcorr)
            bl = getbase(preamble(4))
            DO i=1,nchan
               corr(i) = corr(i) - aver(bl,i)
c         write(*,*) bl,corr(i),aver(bl,i)
            ENDDO
            DO i=1,nwcorr
               wcorr(i) = wcorr(i) - waver(bl,i)            
c         write(*,*) bl,wcorr(i),waver(bl,i)
            ENDDO
            CALL uvcopyvr(tVis, tout)
            IF(doboth)CALL uvwwrite(tout,wcorr,wflags,nwcorr)
            CALL uvwrite(tout,preamble,corr,flags,nchan)
         ENDIF
      ENDDO
      CALL uvclose(tVis)

      CALL hisopen(tOut,'append')
      CALL hiswrite(tOut,VERSION)
      CALL hisinput(tOut,'UVTSUB')
      CALL hisclose(tOut)

      CALL uvclose(tOut)
      END
c***********************************************************************
      INTEGER FUNCTION getbase(baseline)
      DOUBLE PRECISION baseline
c
      INCLUDE 'maxdim.h'
      INTEGER base(MAXBASE), nbl, i, findbase
      SAVE base, nbl
      DATA nbl/0/
 
      i = baseline
      getbase = findbase(i,base,nbl)
      IF (getbase.EQ.0) THEN
         nbl = nbl + 1
         base(nbl) = i
         getbase = nbl
      ENDIF

      END
C***********************************************************************
      SUBROUTINE trackall(inset)
      INTEGER inset
c
c   Marks all variable in input data set for copying to output
c   data set. Assumes that the dataset is already open and at
c   begining.
c
      INCLUDE 'maxdim.h'
      COMPLEX data(MAXCHAN)
      LOGICAL flags(MAXCHAN), eof
      DOUBLE PRECISION preamble(4)
      INTEGER item,iostat, nread
      CHARACTER varname*11

      CALL uvread(inset,preamble,data,flags,MAXCHAN,nread)
      CALL haccess(inset,item,'vartable','read',iostat)
      IF(iostat.NE.0) CALL bug('f','Error opening vartable')

      eof = .FALSE.
      DOWHILE(.NOT.eof)
         CALL hreada(item,varname,eof)
         IF(.NOT.eof) THEN
            IF(varname(3:6).NE.'corr' .AND. 
     *         varname(3:7).NE.'wcorr') THEN
               CALL uvtrack(inset,varname(3:10),'c')
            ENDIF
         ENDIF
      ENDDO
      CALL hdaccess(item,iostat)
      IF(iostat.NE.0) CALL bug('f','Error closing vartable')
      CALL uvrewind(inset)

      END
c***********************************************************************
      SUBROUTINE setup(tvis,doline,dowide)
      INTEGER tvis
      LOGICAL dowide, doline
c
      CHARACTER type*1
      INTEGER length
      LOGICAL updated 

      CALL uvprobvr(tVis,'wcorr',type,length,updated)
      dowide = type.EQ.'c'
      CALL uvprobvr(tVis,'corr',type,length,updated)
      doline = (type.EQ.'r'.OR.type.EQ.'j'.OR.type.EQ.'c')

      END
c***********************************************************************
