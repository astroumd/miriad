c************************************************************************
      program mir
      implicit none
c
c= MIR -- Convert MIRIAD uv data to MIR uv data
c& dnf
c: data transfer
c+
c     MIR converts uv channel data (wideband data are not converted) 
c     from MIRIAD format to the Caltech MIR format.
c     Note that since MIR does not have an analog to the MIRIAD flags
c     all data are converted, however windows with all channels flagged
c     bad will have negative weights and channels that are flagged bad
c     will have real and imaginary parts set to -1001. It is recommended
c     that only entire datasets are converted at this point.
c
c@ vis
c     The input miriad file
c@ refant
c     The reference antenna for translating baseline positions
c     (default is antenna 7)
c@ out
c     The output mir file
c--
c  History:
c     dnf 17-may-06 Initial version
c--
c  Still to do:
c   implement and check the project/obsblock file reading
c      this requires the project/obsblock file to be present
c      which will not be the case for some time
c************************************************************************
      include 'mir.h'
      character version*(*)
      parameter(version='Mir: version 1.0')

      character out*64,cb*1,fb*64,infl*128
      character fln*128
      integer tIo,tfile,ios
c  Externals
      logical uvdatopn
      integer len1
c

      call output(version)
      call initVars
      call keyini
      call keya('vis',infl,' ')
      write(fln,'(a4,a124)')'vis=',infl
      call keyput('mir',fln)
      call uvdatinp('vis','xsb3')  !only channel data will be read
      call keyi('refant',refant,7)
      call keyf('out',fb,'mir.out')
      cb=fb(len1(fb):len1(fb))
      if(cb.ne."/")out=fb(1:len1(fb))//'/'
      call keyfin
      if(uvdatopn(tIo))then
         cb=infl(len1(infl):len1(infl))
         if(cb.ne."/")then
            infl=infl(1:len1(infl))//'/project'  !read in the project file
         else
            infl=infl(1:len1(infl))//'project'
         endif
         call txtopen(tfile,infl,'old',ios)
         if(ios .eq. 0)then
            proex=.true.
            call proExist(tfile)   !if the project file exists
         else
            proex=.false.
            call proNotExist
         endif
c initialize the output MIR files
         call mirInit(out)
c do the work
         call uvdatrd(preamble,visibility,flags,maxchan,nread)
         inte=0
         do while(nread .ne. 0)
            inte=inte+1
            call inhdGet(tIo)
         enddo
c close and clean up
         call uvdatcls
         call codeWr
         call mirClose
         print*,inte,' integrations converted'
      endif
      end
c************************************************************************
      subroutine inhdGet(tIo)
      implicit none
      include 'mir.h'
      integer tIo
c  subroutine to get the integration header values
c------------------------------------------------------------------------
      character*26 temp
      character*13 hac,dr,dd
      character type
      logical match,ok,ok1,ok2,neg,sys0
      integer i,tmp,j,length,nants,itr
      double precision lo1,xyz(MAXANT*3),daverage,sind,cosd,cosha,
     *  sinha,lst
      real temptemp(MAXANT*MAXWIN),dra,ddec
c External
      integer len1
      character*13 rangle
c
      neg=.false.
      sys0=.false.
      call uvprobvr(tIo,'nants',type,length,ok)
      if(ok)call uvgetvri(tIo,'nants',nants,1)
c AZ and EL, the average is calculated later and only includes the 
c    antennas actually used
      call uvprobvr(tIo,'antaz',type,length,ok)
      if(ok)call uvgetvrd(tIo,'antaz',miriadaz,nants)
      call uvprobvr(tIo,'antel',type,length,ok)
      if(ok)call uvgetvrd(tIo,'antel',miriadel,nants)
c tuning codes
      call uvprobvr(tIo,'lo1',type,length,ok)
      if(ok)then
         call uvgetvrd(tIo,'lo1',lo1,1)
         itq=0
         do i=1,num_tq
            if(lo1 .eq. tqlo(i))itq=i-1
         enddo
         if(itq .eq. 0)then
            itq=num_tq
            num_tq=num_tq+1
            tqlo(num_tq)=lo1
            write(tq(num_tq),'(a4,i1)')'tune',num_tq-1
         endif
      endif
c project id
      call uvprobvr(tIo,'project',type,length,ok)
      if(ok)then
         call uvgetvra(tIo,'project',temp)
         proid=0
         length=len1(temp)
         if(length .gt. 9)then
            call bug('w','Cannot convert project id' //
     *        ' to integer, too many digits')
            length=9
         endif
         do i=length,1,-1
            tmp=ichar(temp(i:i))
            if(tmp .ge. 48 .and. tmp .le. 57)tmp=tmp-48
            proid=proid+int(tmp*10**i)
         enddo
      endif
c integration time
      call uvprobvr(tIo,'inttime',type,length,ok)
      if(ok)call uvgetvrr(tIo,'inttime',rinteg,1)
c epoch
      call uvprobvr(tIo,'epoch',type,length,ok)
      if(ok)call uvgetvrr(tIo,'epoch',epoch,1)
c coordinates
      call uvprobvr(tIo,'dec',type,length,ok1)
      if(ok1)call uvgetvrd(tIo,'dec',decr,1)
      call uvprobvr(tIo,'ra',type,length,ok2)
      if(ok2)call uvgetvrd(tIo,'ra',rar,1)
      if(ok1 .or. ok2)call codeAddCoord
c hour angle and other time stuff
      call uvprobvr(tIo,'lst',type,length,ok)
      if(ok)then
         call uvgetvrd(tIo,'lst',lst,1)
         ha=lst-rar
c convert ha
         if(ha .lt. 0)then
            ha=-ha
            neg=.true.
         endif
         call radhms(dble(ha),0.d0,temp)
         hac=temp(1:12)
c add ' ' to ha
         do i=2,3
            if(hac(i:i) .eq. ' ')then
               if(i .eq. 2)then
                  temp='0'//hac(1:12)
                  hac=temp
               endif
            endif
         enddo
         call atoif(hac(1:2),tmp,ok)
         if(ok)then
            ha=tmp
            call atoif(hac(4:5),tmp,ok)
            if(ok)then
               ha=ha+(tmp/60.)
               call atoif(hac(7:8),tmp,ok)
               if(ok)then
                  ha=ha+(tmp/3600.)
                  call atoif(hac(10:11),tmp,ok)
                  if(ok)ha=ha+(tmp/360000.)
               endif
            endif
         endif
         if(neg)ha=-ha
         if(.not.ok)call bug('f','Cannot calculate HA')
      endif
c sx,sy,sz
      if(ok .or. ok1 .or. ok2)then
         sind=dsin(decr)
         cosd=dcos(decr)
         cosha=dcos(ha*15.d0)
         sinha=dsin(ha*15.d0)
         sz=sind
         sx=cosd*cosha
         sy=-cosd*sinha
      endif
c velocity info
      call uvprobvr(tIo,'vsource',type,length,ok)
      if(ok)then
         call uvgetvrr(tIo,'vsource',vsrc,1)
         call uvgetvra(tIo,'veltype',temp)
         if(temp .eq. 'VELO-LSR')temp='vlsr'
         if(temp .eq. 'VELO-HEL')temp='vhel'
         match=.false.
         do i=1,num_vc_type
            if(vc_type(i) .eq. temp)then
               ivctype=i-1
               ivtype=i-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            ivctype=num_vc_type
            ivtype=num_vtype
            num_vc_type=num_vc_type+1
            num_vtype=num_vtype+1
            vc_type(num_vc_type)=temp
            vtype(num_vtype)=temp
         endif
      endif
      call uvprobvr(tIo,'veldop',type,length,ok)
      if(ok)call uvgetvrr(tIo,'veldop',vdop,1)
      vc=vsrc-vdop
c source info
      call uvprobvr(tIo,'source',type,length,ok)
      if(ok)then
         call uvgetvra(tIo,'source',temp)
         match=.false.
         do i=1,num_source
            if(source(i) .eq. temp)then
               isource=i-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            isource=num_source
            num_source=num_source+1
            source(num_source)=temp
         endif
         souid=isource
      endif
c position info
      call uvprobvr(tIo,'dra',type,length,ok1)
      if(ok1)call uvgetvrr(tIo,'dra',dra,1)
      call uvprobvr(tIo,'ddec',type,length,ok2)
      if(ok2)call uvgetvrr(tIo,'ddec',ddec,1)
      if(ok1 .or. ok2)then
         dr=rangle(dra)
         dd=rangle(ddec)
         temp=dr(6:len1(dr))//','//dd(6:len1(dd))
         match=.false.
         do i=1,num_pos
            if(pos(i) .eq. temp)then
               ipos=i-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            ipos=num_pos
            num_pos=num_pos+1
            pos(num_pos)=temp
         endif
         offy=60.*dra/real(dtor)
         offx=60.*ddec/real(dtor)
      endif
c inhid stuff !!will need to be modified
      inhid=inte
c is this a planet
      call uvprobvr(tIo,'plmaj',type,length,ok)
      if(ok)then
         call uvgetvrr(tIo,'plmaj',plntmaj,1)
         planet=.false.
         if(plntmaj .gt. 0)then
            planet=.true.
            call uvgetvrr(tIo,'plmin',plntmin,1)
            call uvgetvrr(tIo,'pltb',pltb,1)
            call uvgetvrr(tIo,'plangle',plntang,1)
            size=2.*plntmaj*plntmin/(plntmaj+plntmin)
            call pflux(lo1)
         else
            size=0.
            sflux=0.
         endif
      endif
c antenna x,y,z
      call uvprobvr(tIo,'antpos',type,length,ok)
      if(ok)then
         call uvgetvrd(tIo,'antpos',xyz,nants*3)
         do i=1,nants
            x(i)=xyz(i)*nstom
            y(i)=xyz(i + nants)*nstom
            z(i)=xyz(i + 2*nants)*nstom
         enddo
         call posCalc(tIo,nants) !shift to ref. antenna and calculate e,n,u
      endif
c system temperature
      call uvprobvr(tIo,'nspect',type,length,ok)
      if(ok)then
         call uvgetvri(tIo,'nspect',nspect,1)
         call bandLabel
      endif
      call uvprobvr(tIo,'systemp',type,length,ok)
      if(ok)then
         call uvgetvrr(tIo,'systemp',temptemp,nants*nspect)
         do i=1,nants
            do j=1,nspect
               tsys(i,j)=temptemp((i-1)*15 +j)*sqrt(2.)
            enddo
         enddo
      endif
      do i=1,nants
         do j=1,nspect
            if(tsys(i,j) .eq. 0.)then
               tsys(i,j)=1.     !!temporary fix until tsys is written
               sys0=.true.
            endif
         enddo
      enddo
      if(sys0)call bug('w','Tsys does not appear to be in the '//
     *              'MIRIAD data, using 1.0 to avoid divison by 0')
c itrans
      call uvprobvr(tIo,'obsline',type,length,ok)
      if(ok)then
         call uvgetvra(tIo,'obsline',temp) !there is only one stored in MIRIAD and it is not window dependent
         match=.false.
         do i=1,num_trans
            if(trans(i) .eq. temp)then
               itr=i-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            itr=num_trans
            num_trans=num_trans+1
            trans(num_trans)=temp
         endif
      endif
      call codeAddTime
      call antSet(nants)
      call blhdGet(tIo,nants,itr)
      az=real(daverage(tda,na))
      el=real(daverage(tde,na))
      call inWrite(conid,icocd,traid,inhid,inte,itq,az,el,ha,iut,
     *       iref_time,dhrs,vc,ivctype,sx,sy,sz,rinteg,proid,souid,
     *       isource,ipos,offx,offy,iofftype,ira,idec,rar,decr,epoch,
     *       sflux,size)
      end
c************************************************************************
      subroutine blhdGet(tIo,nants,itr)
      implicit none
c subroutine to get the baseline header values
      include 'mir.h'
      integer tIo,nants,itr
c------------------------------------------------------------------------
c preamble is u,v,w,time,baselineid
      integer i,j,t1,t2,length
      logical chk,match,ok
      real itime
      character*26 ct1,ct2,temp
      character type

      nbl=(nants*(nants-1))/2
      do i=1,nbl
c get basic info about number of bands and channels
         call uvprobvr(tIo,'nschan',type,length,ok)
         if(ok)call uvgetvri(tIo,'nschan',nschan,nspect)
         call uvprobvr(tIo,'ischan',type,length,ok)
         if(ok)call uvgetvri(tIo,'ischan',ischan,nspect)
         call uvprobvr(tIo,'restfreq',type,length,ok)
         if(ok)call uvgetvrd(tIo,'restfreq',rf,nspect)
         call uvprobvr(tIo,'tau230',type,length,ok)
         if(ok)call uvgetvrr(tIo,'tau230',tau230,1)
         call uvprobvr(tIo,'sdf',type,length,ok)
         if(ok)call uvgetvrd(tIo,'sdf',sdf,nspect)
         itime=rinteg
         call uvprobvr(tIo,'sfreq',type,length,ok)
         if(ok)then
            call uvgetvrd(tIo,'sfreq',sf,nspect)
            call recAssign(sf(1))
         endif
c polarization state
         call uvprobvr(tIo,'pol',type,length,ok)
         if(ok)then
            call uvgetvri(tIo,'pol',polst,1)
            if(polst .eq. 1)then
               temp='I'
            elseif(polst .eq. 2)then
               temp='Q'
            elseif(polst .eq. 3)then
               temp='U'
            elseif(polst .eq. 4)then
               temp='V'
            elseif(polst .eq. -1)then
               temp='RR'
            elseif(polst .eq. -2)then
               temp='LL'
            elseif(polst .eq. -3)then
               temp='RL'
            elseif(polst .eq. -4)then
               temp='LR'
            elseif(polst .eq. -5)then
               temp='XX'
            elseif(polst .eq. -6)then
               temp='YY'
            elseif(polst .eq. -7)then
               temp='XY'
            elseif(polst .eq. -8)then
               temp='YX'
            else
               call bug('f','Unknown polarization state')
            endif
            match=.false.
            do j=1,num_pol
               if(pol(j) .eq. temp)then
                  ipols=j-1
                  match=.true.
               endif
            enddo
            if(.not.match)then
               ipols=num_pol
               num_pol=num_pol+1
               pol(num_pol)=temp
            endif
         endif
         if(proex)then
            do j=1,num_cname
               if(source(isource+1) .eq. cname(j))iaq=cval(j,1)
            enddo
         else
            iaq=0
         endif
c variance and u,v,w
         call uvprobvr(tIo,'variance',type,length,ok)
         if(ok)call uvdatgtr('variance',variance)         
         u=-real(preamble(1)*nstom)  !uvw in meters
         v=-real(preamble(2)*nstom)
         w=-real(preamble(3)*nstom)
         prbl=sqrt(u**2 + v**2 + w**2)
c basline and antenna numbers
         call basant(preamble(5),t1,t2,chk)
         write(ct1,'(i2)')t1
         write(ct2,'(i2)')t2
         if(.not.antused(t1))then
            na=na+1
            tda(na)=miriadaz(t1)
            tde(na)=miriadel(t1)
            antused(t1)=.true.
         endif
         if(.not.antused(t2))then
            na=na+1
            tda(na)=miriadaz(t2)
            tde(na)=miriadel(t2)
            antused(t2)=.true.
         endif

         match=.false.
         do j=1,num_tel1
            if(tel1(j) .eq. ct1)then
               itel1=j-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            itel1=num_tel1
            num_tel1=num_tel1+1
            tel1(num_tel1)=ct1
         endif
         match=.false.
         do j=1,num_tel2
            if(tel2(j) .eq. ct2)then
               itel2=j-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            itel2=num_tel2
            num_tel2=num_tel2+1
            tel2(num_tel2)=ct2
         endif
         if(t1 .lt. 10 .and. t2 .lt. 10)then
            write(temp,'(i1,a1,i1)')t1,'-',t2
         elseif(t1 .lt. 10 .and. t2 .ge. 10)then
            write(temp,'(i1,a1,i2)')t1,'-',t2
         else
            write(temp,'(i2,a1,i2)')t1,'-',t2
         endif
         match=.false.
         do j=1,num_blcd
            if(blcd(j) .eq. temp)then
               iblcd=j-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            iblcd=num_blcd
            num_blcd=num_blcd+1
            blcd(num_blcd)=temp
         endif
         call getBlCode(cocd,int(preamble(5)),blsid)
         ble=y(t1)-y(t2)
         bln=x(t1)-x(t2)
         blu=z(t1)-z(t2)
         souid=1             !CARMA does not store baseline soluiton #s
c blsid stuff !! will need to be modified
         binhid=inhid
         do j=1,2
            isb=j-1
            blhid=blhid+1
c planetary visibility stuff
            call uvprobvr(tIo,'nchan',type,length,ok)
            if(ok)call uvgetvri(tIo,'nchan',nchan1,1)
            if(planet)then
               if(j .eq. 1)then
                  call pVis(preamble(1),preamble(2),vis,
     *                 sf(int(nspect/4)))
               else
                  call pVis(preamble(1),preamble(2),vis,
     *                 sf(int(3*nspect/4)))
               endif
               vflux=vis*sflux
               cnoise=sqrt(variance/(nchan1/2))
               csnr=vflux/cnoise
            else
               vis=1.0
               vflux=0.
               csnr=0.
            endif
            call sphdGet(itime,i,t1,t2,itr,j)
            call ampPhaAve(j)
c wideband average stuff
            call blWrite(blhid,inhid,isb,ipols,pa,iaq,
     *          ibq,icq,ioq,irec,iifc,u,v,w,
     *          prbl,angres,vis,coh,sigcoh,csnr,
     *          vflux,cnoise,avedhrs,ampave,phaave,
     *          tpvar,blsid,itel1,itel2,iblcd,ble,
     *          bln,blu,soid)
         enddo
         call uvdatrd(preamble,visibility,flags,maxchan,nread)
      enddo
      end
c************************************************************************
      double precision function daverage(td,num)
      implicit none
c function to calculate the average of an array
      double precision td(*)
      integer num
c------------------------------------------------------------------------
      integer i
      double precision sum
      sum=0.d0
      do i=1,num
         sum=sum+td(i)
      enddo
      daverage=sum/num
      return
      end
c************************************************************************
      subroutine sphdGet(itime,bl,t1,t2,itr,sbnd)
      implicit none
c subroutine to get the speactral header values
      include 'mir.h'
      integer bl,t1,t2,itr,sbnd
      real itime
c------------------------------------------------------------------------
      real re(MAXCHAN),im(MAXCHAN),offch
      integer i,j,doff,start,stp,middle
      logical good,first

      common/sphdcom/re,im  !,scale,iscale,ire,iim

      if(sbnd .eq. 1)then   !doing lsb
         first=.true.
         start=1
         stp=nspect/2
      else                  !doing usb
         first=.false.
         start=nspect/2+1
         stp=nspect
      endif
      middle=int((start+stp)/2)
      if(first)then
         do j=1,nchan1
            if(flags(j))then    !apply channel flagging
               re(j)=real(visibility(j))
               im(j)=aimag(visibility(j))
            else
               re(j)=-1001.
               im(j)=-1001.
            endif
         enddo
      endif
      do i=start,stp
         rfreq=rf(i)
         nch=nschan(i)
         tau0=tau230
         nrec=1
         fres=real(sdf(i)*1000.)
         vres=real(-sdf(i)*DCMKS/(rf(i)*1000.))
         fsky=sf(i)+(((nschan(i)/2)-0.5) * sdf(i))  !shifted to center of band
         if(i .eq. middle)angres=real(3600.*DCMKS/(fsky*1.d9*prbl*dtor))
         integ=itime
         integs=itime
c sphid stuff
         sphid=sphid+1
c tsys stuff
         tssb=(tsys(t1,i)+tsys(t2,i))/2.
         wt=integ/(tssb**2)
         good=.true.
         do j=1,nschan(i)
            good=(good .and. flags(ischan(i)+j-1))         !apply full window flagging
         enddo
         if(.not.good)wt=-abs(wt)
         wts=wt
         iband=i-1
c igq ipq
         if(proex)then
            do j=1,num_cname
               if(source(isource+1) .eq. cname(j))then
                  igq=cval(j,2)
                  ipq=cval(j,3)
               endif
            enddo
         else
            igq=0
            ipq=0
         endif
c snoise
         snoise=sqrt(variance)
c itrans
         itrans=itr
c toffs
         toffs=0 !there is no offset between hdrs and the integration time
c velocity of center channel
         offch=(rfreq-fsky)/fres
         vel=vc-(offch*vres)
c write out visibilities
         call visWrite(re,im,nschan(i),(ischan(i)-1),doff)
         call spWrite(sphid,blhid,inhid,igq,ipq,
     *          iband,ipstate,tau0,vel,
     *          vres,ivtype,fsky,fres,
     *          tssb,integ,wt,itaper,
     *          snoise,nch,nrec,dataoff,
     *          linid,itrans,rfreq,pasid,
     *          gaiidamp,gaiidpha,flcid,atmid)
         dataoff=dataoff+doff           !offset for the data itself
         first=.false.
      enddo
      end
c************************************************************************
      subroutine codeWr()
      implicit none
      include 'mir.h'
c
c     subroutine to write out the code header
c
c------------------------------------------------------------------------
      integer i,len1

      call codeWrite("cocd",0,cocd,len1(cocd))
      do i=1,num_ut
         call codeWrite("ut",i-1,ut(i),len1(ut(i)))
      enddo
      call codeWrite("ref_time",0,ref_time,len1(ref_time))
      do i=1,num_tq
         call codeWrite("tq",i-1,tq(i),len1(tq(i)))
      enddo
      do i=1,num_vc_type
         call codeWrite("vctype",i-1,vc_type(i),len1(vc_type(i)))
      enddo
      do i=1,num_sb
         call codeWrite("sb",i-1,sb(i),len1(sb(i)))
      enddo
      do i=1,num_pol
         call codeWrite("pol",i-1,pol(i),len1(pol(i)))
      enddo
      do i=1,num_aq
         call codeWrite("aq",i-1,aq(i),len1(aq(i)))
      enddo
      do i=1,num_bq
         call codeWrite("bq",i-1,bq(i),len1(bq(i)))
      enddo
      do i=1,num_cq
         call codeWrite("cq",i-1,cq(i),len1(cq(i)))
      enddo
      do i=1,num_oq
         call codeWrite("oq",i-1,oq(i),len1(oq(i)))
      enddo
      do i=1,num_rec
         call codeWrite("rec",i-1,rec(i),len1(rec(i)))
      enddo
      do i=1,num_ifc
         call codeWrite("ifc",i-1,ifc(i),len1(ifc(i)))
      enddo
      do i=1,num_tel1
         call codeWrite("tel1",i-1,tel1(i),len1(tel1(i)))
      enddo
      do i=1,num_tel2
         call codeWrite("tel2",i-1,tel2(i),len1(tel2(i)))
      enddo
      do i=1,num_blcd
         call codeWrite("blcd",i-1,blcd(i),len1(blcd(i)))
      enddo
      do i=1,num_gq
         call codeWrite("gq",i-1,gq(i),len1(gq(i)))
      enddo
      do i=1,num_pq
         call codeWrite("pq",i-1,pq(i),len1(pq(i)))
      enddo
      do i=1,num_band
         call codeWrite("band",i-1,band(i),len1(band(i)))
      enddo
      do i=1,num_pstate
         call codeWrite("pstate",i-1,pstate(i),len1(pstate(i)))
      enddo
      do i=1,num_vtype
         call codeWrite("vtype",i-1,vtype(i),len1(vtype(i)))
      enddo
      do i=1,num_taper
         call codeWrite("taper",i-1,taper(i),len1(taper(i)))
      enddo
      do i=1,num_trans
         call codeWrite("trans",i-1,trans(i),len1(trans(i)))
      enddo
      do i=1,num_source
         call codeWrite("source",i-1,source(i),len1(source(i)))
      enddo
      do i=1,num_pos
         call codeWrite("pos",i-1,pos(i),len1(pos(i)))
      enddo
      call codeWrite("offtype",0,offtype,len1(offtype))
      do i=1,num_ra
         call codeWrite("ra",i-1,ra(i),len1(ra(i)))
      enddo
      do i=1,num_dec
         call codeWrite("dec",i-1,dec(i),len1(dec(i)))
      enddo
      end
c************************************************************************
      subroutine initVars
      implicit none
      include 'mir.h'
c
c subroutine to set initial values
c------------------------------------------------------------------------
      conid=0
      traid=0
      inhid=0
      inte=0
      proid=0
      souid=0
      icocd=0
      iut=0
      iref_time=0
      ivctype=0
      isource=0
      ipos=0
      pos(1)='00.00,00.00'
      iofftype=0
      offtype(1)='eq'
      ira=0
      idec=0
      nbl=0
      dataoff=0
      blhid=0
      blsid=0
      soid=0
      isb=0
      ipols=0
      iaq=0
      ibq=0
      icq=0
      ioq=0
      iifc=0
      itel1=0
      itel2=0
      iblcd=0
      vflux=0.
      coh=1.0
      sigcoh=0.
      tpvar=1.0
      sphid=0
      linid=0
      igq=0
      ipq=0
      iband=0
      ipstate=0
      ivtype=0
      itaper=0
      nch=0
      nrec=0
      itrans=0
      pasid=0
      gaiidamp=0
      gaiidpha=0
      flcid=0
      atmid=0
      scales=1.
      noises=0.
      num_ut=0
      num_ref_time=0
      num_tq=0
      num_vc_type=0
      num_pol=0
      num_bq=1
      bq(1)=' '
      num_cq=1
      cq(1)=' '
      num_oq=1
      oq(1)=' '
      num_ifc=1
      ifc(1)="0"
      num_tel1=0
      num_tel2=0
      num_blcd=0
      num_band=0
      num_pstate=1
      pstate(1)=' '
      num_trans=0
      num_source=0
      num_pos=0
      num_offtype=1
      num_ra=0
      num_dec=0
      num_icode_s=0
      num_icode_tag=0
      num_rec=0
      num_sb=2
      sb(1)="l"
      sb(2)="u"
      num_taper=1
      taper(1)='u'
c extra vars
      sflux=0.
      size=0.
      plntmaj=0.
      plntmin=0.
      plntang=0.
      pltb=0.
      ampave=0.
      phaave=0.
      ivtype=0
      num_vtype=0
      pa=0.
      icode_tag=' '
      icode_s=' '
      end
c************************************************************************
      subroutine getBlCode(cocd,blcd,blsid)
      implicit none
      character*26 cocd
      integer blcd,blsid
c
c subroutine to determine unique baseline number
c   will be baseline code (256*A1 + A2) + a constant determined by array
c   configuration
c------------------------------------------------------------------------
      if(cocd .eq. 'A' .or. cocd .eq. 'a')then
         blsid=blcd+10000
      elseif(cocd .eq. 'B' .or. cocd .eq. 'b')then
         blsid=blcd+20000
      elseif(cocd .eq. 'C' .or. cocd .eq. 'c')then
         blsid=blcd+30000
      elseif(cocd .eq. 'D' .or. cocd .eq. 'd')then
         blsid=blcd+40000
      elseif(cocd .eq. 'E' .or. cocd .eq. 'e')then
         blsid=blcd+50000
      else
         blsid=blcd
      endif
      end
c************************************************************************
      subroutine codeAddCoord
      implicit none
      include 'mir.h'
c
c subroutine to add ra and dec to code header
c
c------------------------------------------------------------------------
      character*24 radec
      character*26 tra,tdec,temp
      integer i
      logical found
      found=.false.

      call radhms(rar,decr,radec)
      tra=radec(1:12)
      tdec=radec(13:24)
      if((tdec(1:1) .ne. '-') .or. (tdec(1:1) .ne. '+'))then
         temp='+'//tdec(1:12)
         tdec=temp
      endif
c add '0' to ra and dec less than 10
      do i=1,4
         if(tra(i:i) .eq. ' ')then
            if(i .eq. 2)then
               temp='0'//tra(1:12)
               tra=temp
            endif
         endif
         if(tdec(i:i) .eq. ' ')then
            if(i .eq. 3)then
               temp=tdec(1:1)//'0'//tdec(2:12)
               tdec=temp
            endif
         endif
      enddo
c insert ':' to the spaces between
      tra(3:3)=':'
      tra(6:6)=':'
      tdec(4:4)=':'
      tdec(7:7)=':'
      
      do i=1,num_ra
         if(ra(i) .eq. tra)then
            ira=i-1
            idec=i-1
            found=.true.
         endif
      enddo
      if(.not.found)then
         ira=num_ra
         num_ra=num_ra+1
         ra(num_ra)=tra
      endif
      found=.false.
      do i=1,num_dec
         if(dec(i) .eq. tdec)then
            idec=i-1
            found=.true.
         endif
      enddo
      if(.not.found)then
         idec=num_dec
         num_dec=num_dec+1
         dec(num_dec)=tdec
      endif
      if(num_ra .gt. MAXINT .or. num_dec .gt. MAXINT)
     *   call bug('f','Too many ra or dec coordinates, increase'//
     *   ' array size in mir.h')
      end
c************************************************************************
      subroutine codeAddTime
      implicit none
      include 'mir.h'
c
c subroutine to add ut and ref_time
c
c------------------------------------------------------------------------
      double precision day,utt,h,m,s
      integer mo,yr,dd,i,tmp
      character*26 temp,date,fulldate
      character*12 utc
      character*3 month
      character*2 dayc,AP
      character*4 year
      logical ok,match

      call jul2ut(preamble(4),utt)
      call radhms(utt,0.d0,temp)
      utc=temp(1:12)
c add ' ' to ut
      do i=2,3
         if(utc(i:i) .eq. ' ')then
            if(i .eq. 2)then
               temp=' '//utc(1:12)
               utc=temp
            endif
         endif
      enddo
c insert ':' to the spaces between
      utc(3:3)=':'
      utc(6:6)=':'
      utc(9:9)=':'
      call atoif(utc(1:2),tmp,ok)
      if(.not.ok)call bug('f','Error translating time code')
      if(tmp .gt. 12)then
         AP='PM'
         tmp=tmp-12
         write(temp,'(i2)')tmp
         utc(1:2)=temp(1:2)
      else
         AP='AM'
      endif
      call julcal(preamble(4),yr,mo,day)
      dd=int(day)
      if(mo .eq. 1)then
         month="Jan"
      elseif(mo .eq. 2)then
         month="Feb"
      elseif(mo .eq. 3)then
         month="Mar"
      elseif(mo .eq. 4)then
         month="Apr"
      elseif(mo .eq. 5)then
         month="May"
      elseif(mo .eq. 6)then
         month="Jun"
      elseif(mo .eq. 7)then
         month="Jul"
      elseif(mo .eq. 8)then
         month="Aug"
      elseif(mo .eq. 9)then
         month="Sep"
      elseif(mo .eq. 10)then
         month="Oct"
      elseif(mo .eq. 11)then
         month="Nov"
      elseif(mo .eq. 12)then
         month="Dec"
      endif
      if(dd .lt.10)then
         write(dayc,'(a1,i1)')' ',dd
      else
         write(dayc,'(i2)')dd
      endif
      write(year,'(i4)')yr
      date=month//' '//dayc//' '//year
      fulldate=date(1:11)//' '//utc//AP
      match=.false.
      do i=1,num_ut
         if(fulldate .eq. ut(i))then
            iut=i-1
            match=.true.
         endif
      enddo
      if(.not.match)then
         iut=num_ut
         num_ut=num_ut+1
         if(num_ut .gt. MAXINT)call bug('f','Too many ut time stamps'//
     *     ', increase the array size in mir.h')
         ut(num_ut)=fulldate
      endif
      if(num_ref_time .eq. 0)then
         num_ref_time=1
         ref_time=date
         iref_time=0
      endif
      call atoif(utc(1:2),tmp,ok)
      h=dble(tmp)
      if(ok)call atoif(utc(4:5),tmp,ok)
      m=dble(tmp)
      if(ok)call atoif(utc(7:8),tmp,ok)
      s=dble(tmp)
      if(.not.ok)call bug('f','Error translating time codes')
      if(AP .eq. 'PM')h=h+12.d0
      h=h+(m/60.d0)+(s/3600.d0)
      if(date .ne. ref_time)h=h+24.d0
      dhrs=h
      avedhrs=dhrs  !these are always the same for MIRIAD data
      end
c************************************************************************
      subroutine proExist(tIo)
      implicit none
      include 'mir.h'
      integer tIo
c
c subroutine to read in project file
c
c------------------------------------------------------------------------
      integer len,iostat,n
      character*256 text
      character*50 val
      logical match
c External
      integer len1
c
      match=.false.
      num_cname=3
      aq(1)=' '
      aq(2)='1'
      aq(3)='2'
      num_aq=3
      n=0
      gq(1)=' '
      gq(2)='g'
      num_gq=2
      pq(1)=' '
      pq(2)='p'
      num_pq=2
      call txtread(tIo,text,len,iostat)
      do while(iostat .eq. 0)
         call txtFind(text,'array_config',match,val)
         if(match)then
            icocd=0
            cocd=val
            conid=icocd
            num_cocd=1
            goto 1000
         endif         
         call txtFind(text,'type',match,val)
         if(match)then
            call lcase(val)
            n=n+1
            if(val(1:len1(val)) .eq. 'flux_cal')then
               cval(n,1)=2
               cval(n,2)=0
               cval(n,3)=0
            elseif(val(1:len1(val)) .eq. 'gain_cal')then
               cval(n,1)=1
               cval(n,2)=1
               cval(n,3)=0
            elseif(val(1:len1(val)) .eq. 'pass_cal')then
               cval(n,1)=0
               cval(n,2)=0
               cval(n,3)=1
            else
               cval(n,1)=0
               cval(n,2)=0
               cval(n,3)=0               
            endif
            goto 1000
         endif
         call txtFind(text,'cname',match,val)
         if(match)then
            cname(n)=val(1:len1(val))
            goto 1000
         endif
 1000    call txtread(tIo,text,len,iostat)
      enddo
      if(iostat .ne. -1)call bug('f','Error reading project file')
      call txtclose(tIo)
      end
c************************************************************************
      subroutine proNotExist()
      implicit none
      include 'mir.h'
c
c subroutine to set variables when project file does not exist
c
c------------------------------------------------------------------------
      call bug('i','The project file does not exist. The following '//
     * 'items will have to be added/edited manually:aq, gq, pq, cocd,'//
     *  ' cval, cocd, cname')
      num_cname=1
      aq(1)=' '
      num_aq=1
      gq(1)=' '
      num_gq=1
      pq(1)=' '
      num_pq=1
      icocd=0
      cocd=' '
      num_cocd=1
      cval(1,1)=0
      cval(1,2)=0
      cval(1,3)=0
      cname(1)=' '
      cocd='c'  !!temporary fix
      end
c************************************************************************
      subroutine txtFind(line,item,match,val)
      implicit none
      include 'mir.h'
      character*(*) item,line,val
      logical match
c
c subroutine to find values from project file
c
c------------------------------------------------------------------------
      integer index1,index2,length
      character*50 item1
c External
      integer len1,index
c

      item1='<'//item//'>'
      length=len1(item1)
      index1=index(line,item1)+length
      if(index1 .gt. length)then
         item1='</'//item//'>'
         index2=index(line,item1)
         if(index2 .ne. 0)then
            match=.true.
            val=line(index1:index2)
         else
            match=.false.
         endif
      else
         match=.false.
      endif
      end
c************************************************************************
        Subroutine pVis(uu,vv,visib,freq)
c borrowed and modified from bootflux.for
        implicit none
        real visib
        double precision uu,vv,freq
c
c  Determines fractional visibility of a planet for the current visibility. 
c------------------------------------------------------------------------
        include 'mir.h'
        real beta,cosi,sini
c
c  Externals.
c
        real j1xbyx
c
        
        if(plntmaj .gt. 0.01) then
           cosi = cos(plntang)
           sini = sin(plntang)
           beta = pi * sqrt((plntmaj*(real(uu)*cosi-real(vv)*sini))**2
     *                 + (plntmin*(real(uu)*sini+real(vv)*cosi))**2)
           visib = 2.*j1xbyx(beta*real(freq))

        else
           visib = 1.0
        endif
        end
c************************************************************************
        subroutine pflux(freq)
c borrowed and modified from bootflux.for
        implicit none
        double precision freq
c
c  Determines total flux of planet
c------------------------------------------------------------------------
        include 'mir.h'
        real omega
        integer iostat
        double precision day
c
c  Unit conversion.
c
        plntang = pi/180 * plntang
        plntmaj = pi * plntmaj / 180 / 3600
        plntmin = pi * plntmin / 180 / 3600
c
c  We have the characteristics of the source. Now compute the flux (in Jy).
c    plange -- radians.
c    plmaj,plmin -- radians.
c    pltb -- Kelvin.
c    u,v  -- nanosec.
c    freq -- GHz
c  The factor 1e26 converts between W/m**2/Hz to Janksy.
c
        if(plntmaj .gt. 1.0e-8) then
           omega = pi/4 * plntmaj*plntmin
           sflux=omega * 2*(HMKS*1e26)/(CMKS*CMKS)*(real(freq)**3*1e27)/
     *          ( exp(((HMKS/KMKS)*1e9)*real(freq)/pltb) - 1. )
        else
           if(pltb .gt. 0.01) then
              sflux = pltb
           else
              day = 0.0d0
              call calget(' ',source(isource),freq,40.,day,200.,sflux,
     *                    iostat)
              if(iostat.lt.0) sflux = 1.0
           endif
        endif
        end
c************************************************************************
         subroutine posCalc(tIo,nants)
         implicit none
c subroutine to calculate the antenna positions relative to each other,
c   using the refernce antenna
         integer nants,tIo
c------------------------------------------------------------------------
         include 'mir.h'
         integer i,length
         double precision xr,yr,zr,latitude,angle
         logical ok
         character type

         call uvprobvr(tIo,'latitud',type,length,ok)
         if(ok)call uvgetvrd(tIo,'latitud',latitude,1)

         if(refant .gt. nants)then
            call bug('w','Reference antenna is not a valid antenna' //
     *             'number for this data. Setting refant to the last '//
     *             'antenna')
            refant=nants
         endif
         xr=x(refant)
         yr=y(refant)
         zr=z(refant)
         do i=1,nants
            x(i)=x(i)-xr
            y(i)=y(i)-yr
            z(i)=z(i)-zr
         enddo
         angle=(DPI/2. - latitude)
         do i=1,nants
            x(i)=x(i)*dcos(angle) + z(i)*dsin(angle)
            z(i)=-x(i)*dsin(angle) + z(i)*dcos(angle)
         enddo
         end
c************************************************************************
      subroutine antSet(nants)
      implicit none
      integer nants
c
c subroutine to reset the array indicating if the antenna has been used
c------------------------------------------------------------------------
         include 'mir.h'
         integer i
         do i=1,nants
            antused(i)=.false.
         enddo
         na=0
         end
c************************************************************************
      subroutine bandlabel
      implicit none
c
c subroutine to set the labels for the bands code
c
c------------------------------------------------------------------------
         include 'mir.h'
         integer i

         if(nspect .gt. num_band)then
            do i=(num_band+1),nspect
               if(i .lt. 10)then
                  write(band(i),'(a1,i1)')'w',i
               else
                  write(band(i),'(a1,i2)')'w',i
               endif
            enddo
            num_band=nspect
         endif
         end
c************************************************************************
      subroutine recAssign(frq)
      implicit none
      double precision frq
c
c subroutine to assign the receiver number
c
c------------------------------------------------------------------------
      include 'mir.h'
      character trec*3
      integer i
      logical match

      if(frq .lt. 60.)then
         trec="3cm"
      elseif(frq .lt. 150.)then
         trec="3mm"
      else
         trec="1mm"
      endif
      if(num_rec .eq. 0)then
         num_rec=1
         irec=0
         rec(num_rec)=trec
      else
         match=.false.
         do i=1,num_rec
            if(trec .eq. rec(i))then
               irec=i-1
               match=.true.
            endif
         enddo
         if(.not.match)then
            irec=num_rec
            num_rec=num_rec+1
            rec(num_rec)=trec
         endif
      endif
      end
c************************************************************************
      subroutine ampPhaAve(sbd)
      implicit none
      integer sbd
c
c subroutine to calculate ampave and phaave
c
c------------------------------------------------------------------------
      include 'mir.h'

      integer start,stp,i

      if(sbd .eq. 1)then
         start=1
         stp=nchan1/2
      else
         start=nchan1/2 + 1
         stp=nchan1
      endif

      ampave=0.
      phaave=0.
      do i=start,stp
         ampave=ampave + abs(visibility(i))
         phaave=phaave + 180./PI * atan2(aimag(visibility(i)),
     *     real(visibility(i)))
      enddo

      ampave=ampave/(nchan1/2)
      phaave=phaave/(nchan1/2)
      end
