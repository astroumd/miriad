      include 'mirconst.h'
      include 'maxdim.h'
c
      integer MAXFILES
      parameter(MAXFILES=5)
c
      integer MAXINT
      parameter(MAXINT=100000)
c
      double precision dtor
      parameter(dtor=0.01745329252)  !degrees to radians
c
      double precision nstom     !ns to meters
      parameter(nstom=1./3.33564)
c the common blocks
c  integration header
      integer conid,traid,inhid,inte,proid,souid
      integer icocd,iut,iref_time,ivctype,isource,ipos,iofftype,ira,
     * idec,itq
      real az,el,ha,vc,rinteg,offx,offy,epoch,sflux,size
      double precision dhrs,sx,sy,sz,rar,decr,utime

      common/in/dhrs,sx,sy,sz,rar,decr,utime,az,el,ha,vc,rinteg,
     * offx,offy,
     * epoch,sflux,size,conid,traid,inhid,inte,proid,souid,icocd,iut,
     * iref_time,ivctype,isource,ipos,iofftype,ira,idec,itq
c  baseline header
      integer blhid,blsid,soid
      integer isb,ipols,iaq,ibq,
     * icq,ioq,irec,iifc,
     * itel1,itel2,iblcd
      real pa,u,v,w,prbl,
     * angres,vis,coh,sigcoh,
     * csnr,vflux,cnoise,ampave,
     * phaave,tpvar,ble,bln,
     * blu,binhid
      double precision avedhrs
      
      common/bl/avedhrs,pa,u,v,w,prbl,angres,vis,coh,sigcoh,csnr,vflux,
     * cnoise,ampave,phaave,tpvar,ble,bln,blu,blhid,blsid,soid,isb,
     * ipols,iaq,ibq,icq,ioq,irec,iifc,itel1,itel2,iblcd,binhid
c  spectral window header
      integer sphid,dataoff,linid
c     * linid,sblhid,
c     * sinhid
      integer igq,ipq,
     * iband,ipstate,
     * ivtype,
     * itaper,nch,nrec,
     * itrans,pasid,
     * gaiidamp,
     * gaiidpha,flcid,
     * atmid
      real tau0,vres,
     * fres,
     * tssb,integ,wt,
     * snoise
      double precision vel,fsky,
     * rfreq

      common/sp/vel,fsky,rfreq,tau0,vres,fres,tssb,integ,wt,snoise,
     * sphid,dataoff,linid,igq,ipq,iband,ipstate,ivtype,itaper,nch,nrec,
     * itrans,pasid,gaiidamp,gaiidpha,flcid,atmid
c  record header
      real integs,toffs,
     * noises
     * ,scales,wts
      complex data

      common/re/data,integs,toffs,noises,scales,wts
c  codes header
c  code values
      character*26 cocd,ut(MAXINT),ref_time,tq(10),vc_type(4),sb(2),
     *  pol(5),aq(3),bq(3),cq(3),oq(5),rec(3),ifc(2),tel1(23),tel2(23),
     *  blcd(253),gq(2),pq(2),band(16),pstate(10),vtype(4),taper(2),
     *  trans(10),source(10),pos(20),offtype(3),ra(MAXINT),dec(MAXINT),
     *  icode_s,icode_tag
c  number of code values
      integer num_cocd,num_ut,num_ref_time,num_tq,num_vc_type,num_sb,
     *  num_pol,num_aq,num_bq,num_cq,num_oq,num_rec,num_ifc,num_tel1,
     *  num_tel2,num_blcd,num_gq,num_pq,num_band,num_pstate,num_vtype,
     *  num_taper,num_trans,num_source,num_pos,num_offtype,num_ra,
     *  num_dec,num_icode_s,num_icode_tag

      double precision tqlo(10)

      common/cdc/cocd,ut,ref_time,tq,vc_type,sb,pol,aq,bq,cq,oq,rec,
     *  ifc,tel1,tel2,blcd,gq,pq,band,pstate,vtype,taper,trans,
     *  source,pos,offtype,ra,dec,icode_s,icode_tag

      common/numcd/tqlo,num_cocd,num_ut,num_ref_time,num_tq,num_vc_type,
     *  num_sb,num_pol,num_aq,num_bq,num_cq,num_oq,num_rec,num_ifc,
     *  num_tel1,num_tel2,num_blcd,num_gq,num_pq,num_band,num_pstate,
     *  num_vtype,num_taper,num_trans,num_source,num_pos,num_offtype,
     *  num_ra,num_dec,num_icode_s,num_icode_tag
c
c is this a planet?
      logical planet

      common/plnt/planet

      real pltb,plntmaj,plntmin,plntang

      common/pla/pltb,plntmaj,plntmin,plntang

c
c baseline x,y,z
      double precision x(MAXANT),y(MAXANT),z(MAXANT)

      common/posn/x,y,z
c
c tsys
      real tsys(MAXANT,MAXWIN)

      common/ctsys/tsys
c
c calibrators
      character*26 cname(10)

      common/cch/cname

      integer num_cname,cval(10,3)

      common/cv/num_cname,cval
c
c project file exists
      logical proex

      common/pro/proex
c
c last integration
      double precision preamble(5)
      complex visibility(MAXCHAN)
      logical flags(MAXCHAN)
      integer nread
	  logical newint,tsysPresent

	  common/lastvis/visibility,preamble,nread,flags,newint,
     *          tsysPresent
c
c miriad variables
      integer nschan(MAXWIN),ischan(MAXWIN),polst,nchan1,nspect,na
      real tau230,variance,vsrc,vdop 
      double precision rf(MAXWIN),sf(MAXWIN),sdf(MAXWIN),
     *                 miriadaz(MAXANT),miriadel(MAXANT),tda(MAXANT),
     *                 tde(MAXANT)
      logical antused(MAXANT)

      common/mirv/rf,sf,sdf,tau230,variance,vsrc,vdop,nschan,miriadaz,
     *      miriadel,tda,tde,ischan,polst,nchan1,nspect,na,antused
c
c coordinates
c      double precision lat,longe
      integer refant
      double precision latitude

      common/cds/latitude,refant
c offset from last integration
c end common

