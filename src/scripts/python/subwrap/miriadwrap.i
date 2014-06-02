%module miriad_io
%{
#if !defined(TRUE)
# define TRUE		1
#else
# if TRUE != 1
#  error "TRUE should be 1"
# endif
#endif

#if !defined(FALSE)
# define FALSE		0
#else
# if FALSE != 0
#  error "FALSE should be 0"
# endif
#endif

typedef struct {
 float r, i;
} Complex;

#define H_BYTE          1
#define H_INT           2
#define H_INT2          3
#define H_REAL          4
#define H_DBLE          5
#define H_TXT           6
#define H_CMPLX         7

#define hreadb_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_BYTE,buf,offset,length,iostat)
#define hwriteb_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_BYTE,buf,offset,length,iostat)
#define hreadi_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_INT,(char *)(buf),offset,length,iostat)
#define hwritei_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_INT,(char *)(buf),offset,length,iostat)
#define hreadj_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_INT2,(char *)(buf),offset,length,iostat)
#define hwritej_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_INT2,(char *)(buf),offset,length,iostat)
#define hreadl_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_INT8,(char *)(buf),offset,length,iostat)
#define hwritel_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_INT8,(char *)(buf),offset,length,iostat)
#define hreadr_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_REAL,(char *)(buf),offset,length,iostat)
#define hwriter_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_REAL,(char *)(buf),offset,length,iostat)
#define hreadd_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_DBLE,(char *)(buf),offset,length,iostat)
#define hwrited_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_DBLE,(char *)(buf),offset,length,iostat)
#define hreadc_c(item,buf,offset,length,iostat) \
        hio_c(item,FALSE,H_CMPLX,(char *)(buf),offset,length,iostat)
#define hwritec_c(item,buf,offset,length,iostat) \
        hio_c(item,TRUE,H_CMPLX,(char *)(buf),offset,length,iostat)
#define hwrite_c(item,type,buf,offset,length,iostat) \
        hio_c(item,TRUE,type,(char *)(buf),offset,length,iostat)
#define hread_c(item,type,buf,offset,length,iostat) \
        hio_c(item,FALSE,type,(char *)(buf),offset,length,iostat)

%}
typedef struct {
	float r, i;
} Complex;

%include cpointer.i
%include cstring.i
%include carrays.i
%pointer_functions(int, intp);
%pointer_functions(char, charp);
%pointer_functions(float, floatp);
%pointer_functions(double, doublep);
%pointer_functions(Complex, Fcomplexp);
%array_class(int, intArray);
%array_class(float, floatArray);
%array_class(double, doubleArray);
%array_class(Complex, FcomplexArray);

# Fortran functions

extern int alignini_(int *lmodel,int *lmap,int *mmap,int *nmap,int *omap,int *xoff,int *yoff,int *zoff);
extern int alignget_(int *lmodel,int *runs,int *nruns,int *k,int *ioff,int *joff,int *koff,int *n1,int *n2,int *n3,float *data,int *maxdata,int *ndata);
extern int amphase_(Complex *data,float *amp,float *phase);
extern int antmask_(int *maxant,int *nant1,int *nant2,int *ant1,int *ant2,int *blmask);
extern int antind_(int *maxant,int *a1,int *a2,int *idx);
extern int assertl_(int *cond,char *mesg,short mesg_len);
extern int assertf_(char *name__,int *cond,char *mesg,short name_len,short mesg_len);
extern int asserti2_(int *i1,int *i2,char *mesg,short mesg_len);
extern int assertigti_(int *i1,int *i2,char *mesg,short mesg_len);
extern int assertigei_(int *i1,int *i2,char *mesg,short mesg_len);
extern int atjones_(float *rad,float *psi,double *freq,Complex *jo,float *pb);
extern int axistype_(int *lin,int *axis,int *plane,char *ctype,char *label,double *value,char *units,short ctype_len,short label_len,short units_len);
extern int basant_(double *baseline,int *ant1,int *ant2);
extern int basanta_(double *baseline,int *ant1,int *ant2);
extern int basants_(double *baseline,int *ant1,int *ant2,int *check);
extern double antbas_(int *i1,int *i2);
extern int boxinput_(char *key,char *file,int *boxes,int *maxboxes,short key_len,short file_len);
extern int boxzrnge_(char *spec,int *k1,int *k2,int *zrange,char *ztype,int *lu,short spec_len,short ztype_len);
extern int boxint_(char *spec,int *k1,int *k2,int *boxes,int *n,int *modulo,int *nmax,char *type__,int *lu,short spec_len,short type_len);
extern int boxpoly_(char *spec,int *k1,int *k2,int *verts,int *n,int *nmax,int *xyrange,char *xytype,int *lu,short spec_len,short xytype_len);
extern int boxsort_(int *boxes,int *n,int *xyrange);
extern int boxmsk_(char *spec,int *k1,int *k2,int *tno,int *xyzrange,short spec_len);
extern int boxmask_(int *tno,int *boxes,int *maxboxes);
extern int boxmskpr_(int *tno,int *xyzrange);
extern int boxdef_(int *boxes,int *naxis,int *blc,int *trc);
extern int boxset_(int *boxes,int *naxis,int *nsize,char *flags,short flags_len);
extern int boxinfo_(int *boxes,int *naxis,int *blc,int *trc);
extern int boxrect_(int *boxes);
extern int boxbound_(int *boxes,int *subcmd,int *naxis,char *type__,char *mode,int *blc,int *trc,short type_len,short mode_len);
extern int boxcount_(int *runs,int *nruns,int *npoint);
extern int boxruns_(int *naxis,int *plane,char *flags,int *boxes,int *runs,int *maxruns,int *nruns,int *xminv,int *xmaxv,int *yminv,int *ymaxv,short flags_len);
extern int boxand_(int *n1,int *in1,int *n2,int *in2,int *nout,int *out,int *maxout);
extern int boxor_(int *n1,int *in1,int *n2,int *in2,int *nout,int *out,int *maxout);
extern int boxboxx_(int *goes,int *maxgoes,int *j0,int *nbox,int *box,int *ngoes);
extern int boxpolyx_(int *goes,int *maxgoes,int *j0,int *nverts,int *verts,int *ngoes);
extern int boxbug_(char *spec,char *message,short spec_len,short message_len);
extern int wrbtype_(int *lun,char *value,short value_len);
extern int rdbtype_(int *lun,char *value,char *def,short value_len,short def_len);
extern int caopen_(int *tno,char *dataname,double *time0,int *nbl,int *base,int *version,char *status,short dataname_len,short status_len);
extern int caclose_(int *tno);
extern int cadread_(int *tno,int *i__,float *rtime,float *rdata,int *rflag,int *sindex,int *err);
extern int cadwrite_(int *tno,int *i__,float *rtime,float *rdata,int *rflag,int *sindex);
extern int casread_(int *tno,int *i__,char *name__,float *plstuff,int *err,short name_len);
extern int caswrite_(int *tno,int *i__,char *name__,float *plstuff,short name_len);
extern int caflag_(int *tno,int *i__,int *rflag);
extern int caerror_(int *iostat,char *string,short string_len);
extern int rdhdia_(int *tno,char *itemname,int *length,int *value,short itemname_len);
extern int wrhdia_(int *tno,char *itemname,int *length,int *value,short itemname_len);
extern int rsplit_(int *tno,int *split);
extern int wsplit_(int *tno,int *split);
extern int dgefa_(double *a,int *lda,int *n,int *ipvt,int *info);
extern int dgesl_(double *a,int *lda,int *n,int *ipvt,double *b,int *job);
extern int vectav_(int *b,int *p,int *count,int *avidx,int *clump,int *nclump,float *x,float *y,float *dtaver,float *tmax);
extern int miniflip_(int *npts,float *phas,int *flips);
extern int flipper_(float *timave,float *timmax,int *basediff);
extern int getclo3_(int *nbl,int *base,float *signcl);
extern int inipoly_();
extern int getpoly_(char *dataset,short dataset_len);
extern int putpoly_(char *dataset,short dataset_len);
extern int chkpoly_(char *code,short code_len);
extern double evalpoly_(float *t,char *code,int *bl,int *valid,short code_len);
extern int fitpoly_(int *n,float *x,float *y,char *code,int *bl,int *porder,short code_len);
extern int addpoly_(char *code,int *bl,int *porder,float *ppoly,float *valid,short code_len);
extern int readset_(char *file,short file_len);
extern int writeset_(char *file,int *checksrc,short file_len);
extern int writflag_(char *file,short file_len);
extern int addhist_(char *file,char *progname,char *message,short file_len,short progname_len,short message_len);
extern int hisappn_(int *tno,char *file,int *insert,short file_len);
extern int readbrk_(char *file,short file_len);
extern int writbrk_(char *file,short file_len);
extern int putsrc_(char *file,short file_len);
extern int calstoke_(char *source,char *stokes,double *freq,float *flux,int *nchan,int *ierr,short source_len,short stokes_len);
extern int findbase_(int *bl,int *base,int *nbl);
extern void blname_(char *value, int vlen, int* bl);
extern int getants_(int *binp,int *nant,int *a1,int *a2);
extern int taver_(int *n,float *x,float *y,float *dx);
extern int code2s_(char *code,short code_len);
extern int ampscal_(float *amp,float *jyflux,int *scalmode);
extern int setxy_(int *bp,int *b,int *p,int *count,float *x,float *y,float *taver);
extern int cnvlinif_(int *handle,int *lu,int *n1,int *n2,int *ic,int *jc,float *param,char *flags,short flags_len);
extern int cnvlinia_(int *handle,float *array,int *n1,int *n2,int *ic,int *jc,float *param,char *flags,short flags_len);
extern int cnvlcopy_(int *out,int *handle);
extern int cnvlco_(int *handle1,int *handle2,char *flags,short flags_len);
extern int cnvlin0_(int *handle,int *n1,int *n2,int *n1d,int *n2d,int *space,int *trans,int *cdat1,int *cdat2,char *flags,int *ic,int *jc,int *xr,int *yr,short flags_len);
extern int cnvla_(int *handle,float *in,int *nx,int *ny,float *out,char *flags,short flags_len);
extern int cnvlf_(int *handle,int *lu,int *nx,int *ny,float *out,char *flags,short flags_len);
extern int cnvlr_(int *handle,float *in,int *nx,int *ny,int *runs,int *nruns,float *out,char *flags,short flags_len);
extern int cnvlext_(int *handle,int *n1,int *n2,int *n1d,int *n2d);
extern int cnvl0_(int *handle,int *nx,int *ny,int *n1,int *n2,int *n1a,int *n2a,int *n1d,int *n2d,int *space,int *trans,int *cdat1,int *cdat2,char *flags,int *sym,int *compr,int *corr,int *xr,int *yr,short flags_len);
extern int cnvlfin_(int *handle);
extern int convl_(float *in,float *out,int *n,int *nx,int *ny,int *runs,int *nruns,float *beam,int *n1,int *n2);
extern int sctico_(char *type__,double *win,char *cti,short type_len,short cti_len);
extern int sctoco_(char *type__,double *wout,short type_len);
extern int setoaco_(int *lun,char *absoff,int *n,int *iax,char *types,short absoff_len,short types_len);
extern int specco_(int *lun,int *iax,char *stype,short stype_len);
extern int sunitco_(int *lun,int *iax,char *type__,char *units,short type_len,short units_len);
extern int w2wcov_(int *lun,int *n,char *typei,double *win,char *typeo,double *wout,int *valid,short typei_len,short typeo_len);
extern int w2wfco_(int *lun,int *n,char *typei,double *win,char *typeo,int *nounit,char *strout,int *strlen,short typei_len,short typeo_len,short strout_len);
extern int w2wsco_(int *lun,int *iax,char *typei,double *win,char *typeo,double *wout,short typei_len,short typeo_len);
extern int w2wsfco_(int *lun,int *iax,char *typei,double *win,char *typeo,int *nounit,char *strout,int *strlen,short typei_len,short typeo_len,short strout_len);
extern int ctrlopen_(char *name__,int *ctrl,short name_len);
extern int ctrlinit_(char *name__,int *status,short name_len);
extern int ctrlport_(char *name__,int *port,int *status,short name_len);
extern int ctrlview_();
extern int ctrlclr_();
extern int ctrlchck_(char *name__,int *changes,int *val1,int *val2,short name_len);
extern int ctrlwait_(char *name__,int *changes,int *val1,int *val2,short name_len);
extern int ctrldef_(char *name__,char *type__,char *values,int *nvalues,short name_len,short type_len,short values_len);
extern int ctrlset_(char *name__,int *values,int *nvalues,short name_len);
extern int ctrlseta_(char *name__,char *string,short name_len,short string_len);
extern int ctrlfin_();
extern int ctrlflsh_(int *n);
extern int ctrlread_(int *n);
extern int defsmodl_(int *tno);
extern int deghms_(double *a,double *d__,char *radec,short radec_len);
extern int radhms_(double *a,double *d__,char *radec,short radec_len);
extern int jul2ut_(double *jday,double *ut);
extern int prerotat_(double *jday,double *ra,double *dec,double *jout,double *theta);
extern int precess_(double *jday1,double *ra1,double *dec1,double *jday2,double *ra2,double *dec2);
extern int azel_(double *obsra,double *obsdec,double *lst,double *latitude,double *az,double *el);
extern int parang_(double *obsra,double *obsdec,double *lst,double *latitude,float *chi);
extern int jullst_(double *jday,double *long__,double *lst);
extern int xyz2llh_(double *x,double *y,double *z__,double *lat,double *long__,double *height);
extern int llh2xyz_(double *lat,double *long__,double *height,double *x,double *y,double *z__);
extern int sph2lmn_(double *ra,double *dec,double *lmn);
extern int lmn2sph_(double *lmn,double *ra,double *dec);
extern int aberrate_(double *jday,double *ra,double *dec,double *rapp,double *dapp);
extern int nutate_(double *jday,double *rmean,double *dmean,double *rtrue,double *dtrue);
extern int nuts_(double *jday,double *dpsi,double *deps);
extern int sunradec_(double *jday,double *ra,double *dec);
extern int fk45z_(double *r1950,double *d1950,double *jday,double *r2000,double *d2000);
extern int fk54z_(double *r2000,double *d2000,double *jday,double *r1950,double *d1950,double *dr1950,double *dd1950);
extern int fk524_(double *r2000,double *d2000,double *dr2000,double *dd2000,double *p2000,double *v2000,double *r1950,double *d1950,double *dr1950,double *dd1950,double *p1950,double *v1950);
extern int pm_(double *r0,double *d0,double *pr,double *pd,double *px,double *rv,double *jep0,double *jep1,double *r1,double *d1);
extern int fftrc_(float *in,float *out,int *isn,int *n);
extern int fftcr_(float *in,float *out,int *isn,int *n);
extern int fftcc_(Complex *in,Complex *out,int *isn,int *n);
extern int fftini_(int *n,int *m,int *ni,int *i1,int *i2,Complex *twiddle);
extern int fxyopen_(int *lu,char *name__,char *status,int *naxis,int *nsize,short name_len,short status_len);
extern int fxysetpl_(int *lu,int *naxis,int *nsize);
extern int fxyread_(int *lu,int *indx,float *data);
extern int fxyflgrd_(int *lu,int *indx,int *flags);
extern int fxywrite_(int *lu,int *indx,float *data);
extern int fxyflgwr_(int *lu,int *indx,int *flags);
extern int fxyclose_(int *lu);
extern int fuvopen_(int *lu,char *name__,char *status,int *nvis,int *npol,int *nfreq,short name_len,short status_len);
extern int fuvsetpa_(int *lu,int *nparam,char *params,short params_len);
extern int fuvwrpa_(int *lu,int *nranfile,char *params,double *timoff,short params_len);
extern int fuvrdpa_(int *lu,int *nranfile,int *nranprog,char *params,int *indices1,int *indices2,float *scales1,float *scales2,float *zeros,double *timoff,short params_len);
extern int fuvsett0_(int *lu,double *t0);
extern int fuvwrhd_(int *lu,double *coord);
extern int fuvrdhd_(int *lu,double *coord);
extern int fuvread_(int *lu,float *visdat,int *number,int *count);
extern int fuvwrite_(int *lu,float *visdat,int *number,int *count);
extern int fuvclose_(int *lu);
extern int fuvrtrn1_(int *lu,int *n,int *in,int *ppvisi,float *out,int *ppviso);
extern int fuvrtrn2_(int *lu,int *n,float *in,int *mask,int *ppvisi,float *out,int *ppviso);
extern int fuvmltr1_(int *n,float *bscale,float *bzero,int *a,int *na,float *b,int *nb);
extern int fuvgrand_(int *lu,int *indx,double *rparam);
extern int fuvfreq_(int *lu,double *freq);
extern int fuvwt_(int *lu,float *factor);
extern int fuvget_(int *lu,int *naxis,int *ncmplx,int *icmplx,int *npol,int *ipol,int *nfreq,int *ifreq,int *nif,int *iif);
extern int fitrdhdi_(int *lu,char *key,int *out,int *default__,short key_len);
extern int fitrdhdr_(int *lu,char *key,float *out,float *default__,short key_len);
extern int fitrdhdd_(int *lu,char *key,double *out,double *default__,short key_len);
extern int fitrdhda_(int *lu,char *key,char *out,char *default__,short key_len,short out_len,short default_len);
extern int fitrdhdl_(int *lu,char *key,int *out,int *default__,short key_len);
extern int fitwrhdh_(int *lu,char *key,char *value,short key_len,short value_len);
extern int fitwrhda_(int *lu,char *key,char *value,short key_len,short value_len);
extern int fitwrhdl_(int *lu,char *key,int *value,short key_len);
extern int fitwrhdi_(int *lu,char *key,int *value,short key_len);
extern int fitwrhdr_(int *lu,char *key,float *value,short key_len);
extern int fitwrhdd_(int *lu,char *key,double *value,short key_len);
extern int fitopen_(int *lu,char *name__,char *status,short name_len,short status_len);
extern int fithdfin_(int *lu);
extern int fitclose_(int *lu);
extern int fitcdio_(int *lu,char *value,short value_len);
extern int fitsrch_(int *lu,char *key,int *found,short key_len);
extern int ftabloc_(int *lu,char *name__,int *found,short name_len);
extern int ftabnxt_(int *lu,char *name__,int *found,short name_len);
extern int ftabskip_(int *lu,char *name__,int *found,short name_len);
extern int ftabload_(int *lu,int *ok);
extern int ftabform_(char *string,int *colform,int *colcnt,short string_len);
extern int ftabinfo_(int *lu,char *name__,char *type__,char *units,int *nrow,int *nval,short name_len,short type_len,short units_len);
extern int ftabgeti_(int *lu,char *name__,int *irow,int *data,short name_len);
extern int ftabgetr_(int *lu,char *name__,int *irow,float *data,short name_len);
extern int ftabgetc_(int *lu,char *name__,int *irow,Complex *data,short name_len);
extern int ftabgetd_(int *lu,char *name__,int *irow,double *data,short name_len);
extern int ftabgeta_(int *lu,char *name__,int *irow,char *data,short name_len,short data_len);
extern int ftabdini_(int *lu,char *ename,short ename_len);
extern int ftabdfin_(int *lu);
extern int ftabdef_(int *lu,char *name__,char *type__,char *units,int *nrow,int *nval,short name_len,short type_len,short units_len);
extern int ftabputr_(int *lu,char *name__,int *irow,float *data,short name_len);
extern int ftabputd_(int *lu,char *name__,int *irow,double *data,short name_len);
extern int ftabputi_(int *lu,char *name__,int *irow,int *data,short name_len);
extern int ftabputa_(int *lu,char *name__,int *irow,char *data,short name_len,short data_len);
extern int fitdate_(int *lu,char *keyw,double *jday,short keyw_len);
extern int fbasant_(float *bl,int *ant1,int *ant2,int *config);
extern int fndaxnum_(int *tinp,char *type__,char *axisname,int *axisnr,short type_len,short axisname_len);
extern int remext_(char *filename,short filename_len);
extern int gser_(float *a,float *x,float *gamser,float *gln);
extern int gcf_(float *a,float *x,float *gammcf,float *gln);
extern int gaupar1_(int *lin,float *bmaj2,float *bmin2,float *bpa2,char *bunit,float *bmaj,float *bmin,float *bpa,float *fac,short bunit_len);
extern int gaupar2_(int *lin1,int *lin2,char *bunit,float *bmaj,float *bmin,float *bpa,float *fac,short bunit_len);
extern int gaupar_(char *bunit1x,double *dx1,double *dy1,float *bmaj1,float *bmin1,float *bpa1,char *bunit2x,double *dx2,double *dy2,float *bmaj2,float *bmin2,float *bpa2,char *bunit,float *bmaj,float *bmin,float *bpa,float *fac,short bunit1x_len,short bunit2x_len,short bunit_len);
extern int gaufac_(float *bmaj1,float *bmin1,float *bpa1,float *bmaj2,float *bmin2,float *bpa2,float *fac,float *bmaj,float *bmin,float *bpa,int *ifail);
extern int gaudfac_(float *bmaj1,float *bmin1,float *bpa1,float *bmaj2,float *bmin2,float *bpa2,float *fac,float *bmaj,float *bmin,float *bpa,int *ifail);
extern int getbeam_(int *lin,int *naxis,char *bunit,float *bmaj,float *bmin,float *omega,float *cbof,short bunit_len);
extern int getfreq_(int *tin,float *pix,int *ifax,double *freq,double *finc,int *ierr);
extern int getpb_(int *tno,char *name__,float *pbfwhm,short name_len);
extern int getxy_(int *tno,float *fac,float *xyphase,int *count,int *mxant,int *nants);
extern int corrfun_(char *func,float *phi,int *n,int *width,float *alpha,short func_len);
extern int gcffun_(char *func,float *phi,int *n,int *width,float *alpha,short func_len);
extern int hcoeffs_(int *nsmth,float *coeffs);
extern int bico_(int *n,int *k,float *c__);
extern int hannsm_(int *nsmth,float *coeffs,int *npts,float *arr,float *work);
extern int bcoeffs_(int *nsmth,float *coeffs);
extern int boxcarsm_(int *nsmth,float *coeffs,int *npts,float *arr,float *work);
extern int headcopy_(int *tnoinp,int *tnoout,int *axnum,int *naxis,int *blc,int *trc);
extern int hisinput_(int *tno,char *name__,short name_len);
extern int hsorta_(int *n,char *array,int *indx,short array_len);
extern int hsorti_(int *n,int *array,int *indx);
extern int hsortr_(int *n,float *array,int *indx);
extern int hsortd_(int *n,double *array,int *indx);
extern int hsortar_(int *n,char *array,float *second,int *indx,short array_len);
extern int hsortad_(int *n,char *array,double *second,int *indx,short array_len);
extern int hsortrr_(int *n,float *array,float *second,int *indx);
extern int imminmax_(int *lun,int *naxis,int *nsize,float *rmin,float *rmax);
extern int incini_(int *n,int *size,int *dims__);
extern int incoff_(int *n,int *size1,int *size2,int *out);
extern int intpini_(int *n1,int *n2,float *blctrc);
extern int intprini_();
extern int intprd_(int *lu,int *jj,float *out,int (*intpget));
extern int intpolat_(float *out,int *n,int *indx,float *z0,float *z1,float *z2,float *z3,float *wx0,float *wx1,float *wx2,float *wx3,float *wy0,float *wy1,float *wy2,float *wy3);
extern int julday_(double *julian,char *form,char *calday,short form_len,short calday_len);
extern int julcal_(double *julian,int *year,int *month,double *day);
extern int dayjul_(char *calday,double *julian,short calday_len);
extern int datepars_(char *calday,int *a,int *z__,int *alpha,char *delim,int *iarray,int *ok,short calday_len,short delim_len);
extern int todayjul_(double *julian);
extern int lagwt_(float *wts,int *nwts,float *fac);
extern int linetype_(int *unit,float *line,char *type__,short type_len);
extern int logopen_(char *name__,char *flags,short name_len,short flags_len);
extern int logwrit_(char *line,short line_len);
extern int logwrite_(char *line,int *more,short line_len);
extern int logclose_();
extern int loginput_(char *name__,short name_len);
extern int lsearchd_(int *n,double *x,double *t,int *i__);
extern int lsf_(int *noerr,int *n,float *x,float *y,float *w,float *m,float *b,float *sigm,float *sigb,float *chisq,float *q);
extern int lspoly_(int *nn,int *l,float *x,float *y,float *w,float *z__,float *coeff);
extern int legdr_(float *x,float *p,int *np);
extern int llsquini_(float *x,float *b,int *n);
extern int llsquacc_(float *f,float *a,float *x,float *b,int *m,int *n);
extern int llsqusol_(float *x,float *b,int *n,int *ifail,float *pivot);
extern int llsqu_(float *f,float *a,int *n,int *m,float *c__,int *ifail,float *b,int *pivot);
extern int linlsq_(float *xarr,float *yarr,int *npnt,float *a1,float *b1,float *a2,float *b2,float *sigx,float *sigy,float *corr);
extern int mapfin_();
extern int mapini_(char *mode1,int *tscr1,int *nvis1,int *npnt1,float *umax1,float *vmax1,int *offcorr1,int *totchan1,short mode1_len);
extern int mapdef_(int *nchan1,int *nx1,int *ny1);
extern int mapscale_(int *ichan);
extern int mapper_(int *ichan,int *pmap);
extern int mapbufs_(int *ichan);
extern int mapvsum_(Complex *dat,int *n,float *sum);
extern int mapgrid_(int *ichan);
extern int mapginit_();
extern int mapbuf_(int *ichan);
extern int mapvis_(int *tvis,float *cgf,int *ncgf,int *width,int *nvis,int *nstart,int *ncount,int *vissize,Complex *grd,int *nu,int *nv,int *npnt,int *u0,int *v0,int *n1,int *n2);
extern int mapit_(float *vis,int *nvis,int *offset,int *ncount,int *npnt,int *size,Complex *grd,int *nu,int *nv,int *u0,int *v0,int *n1,int *n2,float *cgf,int *ncgf,int *width,int *poff,int *qoff,int *goff);
extern int mapindx_(int *ncgf,int *width,int *nu,int *poff,int *qoff,int *goff);
extern int mapfft2_(float *grd,int *inoff,int *outoff,int *nu,int *nv,int *nx,int *ny,int *n1,int *u0,int *v0,float *scale,float *xcorr,float *ycorr);
extern int mapfft1_(Complex *grd,int *nu,int *nv,int *u0,int *v0,int *n2);
extern int mapslows_(int *tscr,int *nvis,int *offcorr,int *vissize,float *sum);
extern int mapslow_(int *tscr,char *mode,int *nvis,int *offcorr,int *vissize,float *dat,float *wrk,float *map,int *nx,int *ny,float *scale,short mode_len);
extern int whenfeq_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenfne_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenflt_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenfle_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenfgt_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenfge_(int *n,float *array,int *inc,float *target,int *index,int *nval);
extern int whenieq_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int whenine_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int whenilt_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int whenile_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int whenigt_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int whenige_(int *n,int *array,int *inc,int *target,int *index,int *nval);
extern int mcinitfg_(int *tno1,float *bmaj1,float *bmin1,float *bpa1);
extern int mcinitf_(int *tno1);
extern int mcplane_(int *coobj,int *k);
extern int mccnvl_(float *in,int *nix,int *niy,float *out,int *nox,int *noy);
extern int mcplaner_(int *coobj,int *k,int *runs,int *nruns,int *npoint);
extern int mcgain_(float *gain,int *npoint);
extern int mcgn_(float *gain,float *wt1,int *npoint);
extern int mcsigma2_(float *sigma2,int *npoint,int *noinvert);
extern int mcsig_(float *sigma2,float *wt1,float *wt2,int *npoint,int *noinvert);
extern int mccnvlr_(float *in,int *runs,int *nruns,float *out);
extern int mccnvl2_(int *k,int *cnvl,int *pbobj,float *in,float *wt1,float *wt3,int *xlo,int *ylo,int *xhi,int *yhi,int *xmin,int *ymin,int *xmax,int *ymax,int *n,float *out,int *runs,int *nruns,float *pb,float *resid,int *nscr);
extern int mcwt_(float *out,float *wts,int *n);
extern int mcextent_(int *k,int *pbobj,int *n1,int *n2,int *n1d,int *n2d,int *xlo,int *ylo,int *xhi,int *yhi,int *xmin,int *ymin,int *xmax,int *ymax);
extern int mcinitc_(int *k,int *cnvl1);
extern int mcgaus_(int *tno,float *beam,int *n1,int *n2,int *ic,int *jc,float *bmaj,float *bmin,float *bpa);
extern int mcfin_();
extern int medfit_(float *x,float *y,int *n,float *a,float *b,int *dooff);
extern int median_(float *x,int *n,float *xmed);
extern int memini_();
extern int modelini_(int *tmod,int *tvis,float *sels,char *flags,short flags_len);
extern int modpolm_(int *tmod,int *polm);
extern int modpolv_(int *tvis,int *polv);
extern int modfreqm_(int *tmod,double *freq0);
extern int modfft_(int *tvis,int *tmod,int *nx,int *ny,int *nchan,int *nxd,int *nyd,float *level,int *polm,int *doclip,int *imhead,Complex *buffer,int *nv,int *nu,int *mfs,double *xref1,double *yref1,double *xref2,double *yref2);
extern int modgrid_(float *uu,float *vv,Complex *grd,int *nu,int *nv,int *nchan,int *u0,int *v0,float *gcf,int *ngcf,Complex *intp);
extern int modshift_(double *uu,double *vv,double *xref1,double *yref1,double *xref2,double *yref2,double *freq,Complex *intp,int *nchan);
extern int modcorr_(float *xcorr,float *ycorr,int *nxd,int *nyd);
extern int modplane_(int *tmod,int *nx,int *ny,int *nxd,int *nyd,float *xcorr,float *ycorr,float *level,int *nclip,int *iref,int *jref,Complex *buffer,int *nu,int *nv);
extern int modstat_(int *calscale,int *tvis,float *out,int *nchan,int (*calget),float *level,float *vispow,float *modpow);
extern int modget_(int (*calget),int *tvis,int *nchan,float *a,float *level);
extern int modinit_();
extern int modprd_(int *tvis,char *line,int *k1,int *k2,double *lmn,short line_len);
extern int moscini_();
extern int moscdone_(int *lin);
extern int moschk_(int *lin,int *i__);
extern int moschar_(double *ra1,double *dec1,int *npnt1,char *proj,short proj_len);
extern int mosginit_(int *coobj,int *nx,int *ny,int *nchan,int *mnx,int *mny);
extern int mosshift_(int *coobj,int *npnt1,int *nchan,float *x,float *y);
extern int mossizer_(int *nx2,int *ny2,float *x,float *y,int *npnt,int *nchan,int *mnx,int *mny,double *crpix1,double *crpix2);
extern int mosgeom_(int *size,int *n,int *nchan,int *npol,Complex *vis,float *wts);
extern int mosload_(int *tno,int *npnt1);
extern int mosprint_();
extern int mosinit_(int *nx,int *ny);
extern int mosget_(int *i__,double *ra1,double *dec1,float *rms1,char *pbtype1,short pbtype1_len);
extern int mosset_(int *i__,double *ra1,double *dec1,float *rms1,char *pbtype1,short pbtype1_len);
extern int mosgetn_(int *nx2d,int *ny2d,int *npnt1);
extern int mossetn_(int *nx2d,int *ny2d);
extern int mossave_(int *tno);
extern int mosgfin_();
extern int mosmini_(int *coobj,float *chan);
extern int mosaicer_(float *in,float *out,int *nx,int *ny,int *npnt1,int *mnx,int *mny,int *runs,int *maxruns,int *nruns);
extern int mosaic1_(float *in,float *out,int *nx,int *ny,int *mnx,int *mny,int *runs,int *maxruns,int *nruns);
extern int mosaic2_(float *in,float *out,float *wts,int *nx,int *ny,int *npnt,int *mnx,int *mny,float *rms2);
extern int moswt_(float *rms2,int *npnt,float *out,float *wts,int *n);
extern int mosmfin_();
extern int mosval_(int *coobj,char *in,double *x,float *gain,float *rms,short in_len);
extern int mospnt_(int *coobj,char *in,double *x,float *beams,float *psf,int *nx,int *ny,int *npnt1,short in_len);
extern int mospnt1_(float *beams,float *psf,float *wts,int *nx,int *ny,int *npnt1,int *xr,int *yr);
extern int moswts_(float *wt1,float *wt2,int *nx,int *ny,int *xoff,int *yoff);
extern int moswtsr_(int *runs,int *nruns,float *wt1,float *wt2,int *npix);
extern int mosradec_(int *k,double *ra,double *dec);
extern int nearest_(float *x,float *y,int *indx,int *n,int *ip,float *mnmax);
extern int randset_(int *seed);
extern int uniform_(float *data,int *n);
extern int setseed_(int *seed);
extern int gaus_(float *data,int *n);
extern int besj_(float *x,float *alpha,int *n,float *y,int *nz);
extern int jairy_(float *x,float *rx,float *c__,float *ai,float *dai);
extern int numbpg_(int *mm,int *pp,int *form,char *string,int *nc,short string_len);
extern int obsprint_();
extern int obspar_(char *observ,char *object,double *value,int *ok,short observ_len,short object_len);
extern int obsinit_();
extern int obsad_(char *name__,double *value,short name_len);
extern int ofmapp_();
extern int ofmcol_(int *jofm,float *imin,float *imax);
extern int ofmcmp_();
extern int ofmevl_();
extern int ofmfit_();
extern int ofmheq_(int *npix,float *image,int *mask,float *imin,float *imax);
extern int ofmini_();
extern int ofml1m_();
extern int ofmlin_(float *x,float *y,int *domsg);
extern int ofmlnf_();
extern int ofmlog_(float *imin,float *imax);
extern int ofmmod_(float *tfvpu,int *nu,float *image,int *mask,float *imin,float *imax);
extern int ofmrep_();
extern int ofmrev_();
extern int ofmrsf_();
extern int ofmsel_(float *imin,float *imax);
extern int ofmsqr_(float *imin,float *imax);
extern int ofmtabw_(float *imin,float *imax);
extern int ofmtba_(float *imin,float *imax,int *dofcc);
extern int ofmtbb_();
extern int ofmtbw_();
extern int ofmtcc_(float *imin,float *imax,int *dofcc);
extern int ofmtfe_();
extern int ofmtff_(int *npix,float *image,int *mask,float *imin,float *imax);
extern int ofmtfp_();
extern int ofmuin_(float *x,float *y,char *cch,short cch_len);
extern int options_(char *key,char *opts,int *present,int *nopt,short key_len,short opts_len);
extern int keymatch_(char *key,int *ntype,char *types,int *maxout,char *out,int *nout,short key_len,short types_len,short out_len);
extern int pblist_();
extern int pbread_(int *tno,char *pbtype,short pbtype_len);
extern int pbwrite_(int *tno,char *pbtype,short pbtype_len);
extern int pbencode_(char *pbtype,char *type__,float *val,short pbtype_len,short type_len);
extern int pbinit_(int *pbobj,char *pbtype,int *coobj,short pbtype_len);
extern int pbinitc_(int *pbobj,char *type__,int *coobj,char *in,double *x1,short type_len,short in_len);
extern int pbfin_(int *pbobj);
extern int pbinfo_(int *pbobj,float *pbfwhmd,float *cutoffd,float *maxradd);
extern int pbextent_(int *pbobj,float *x,float *y,float *xext,float *yext);
extern int pbfirst_();
extern int pbadd_(char *tel,float *f1d,float *f2d,float *pbfwhmd,float *cutoffd,int *pbtyped,int *nval,float *vals,char *descripd,short tel_len,short descripd_len);
extern int pbradp_(int *doinv,float *cutoff,float *coeff,int *ncoeff,float *pbfwhm,float *maxrad);
extern int pcvtinit_(int *coobj1d,int *coobj2d);
extern int pcvt_(double *x1,double *x2,int *n);
extern int pghline_(int *npts,float *x,float *y,float *gapfac);
extern int pkfit_(float *z__,int *width,float *zmax,double *pix,float *c__);
extern int getplane_(int *lu,int *run,int *nrun,int *xoff,int *yoff,int *nx,int *ny,float *out,int *maxout,int *nout);
extern int putplane_(int *lu,int *run,int *nrun,int *xoff,int *yoff,int *nx,int *ny,float *in,int *nin);
extern int putruns_(int *lout,int *runs,int *nruns,int *xoff,int *yoff,int *nx,int *ny);
extern float pltbs_(int *iplanet, float *freq);
extern int plradec_(double *jday,int *np,double *ra,double *dec);
extern int plpar_(double *jday,int *np,double *sub,double *dist,float *bmaj,float *bmin,float *bpa);
extern int plphyeph_(double *jday,int *np,double *alpha,double *delta,double *w,double *r__,double *f);
extern int plobseph_(double *date,int *np,double *pv,int *jstat);
extern int plinit_(float *dist1,int *plant,float *erad1,float *prad1);
extern int plfake_(float *dist1,float *lambda,float *de);
extern int plcomm_();
extern int pluvw_(double *uv,double *time,double *uvw,float *a,float *b,float *fac1,int *smatidx,float *bpa1,double *sub);
extern int rpolyzr_(float *a,int *nn,Complex *roots,int *ifail);
extern int rpolsolr_(float *tol,float *x,float *y,float *r__,float *rx,float *j,float *jx,float *a,int *n,int *sat);
extern int dpolyzr_(double *a,int *nn,Complex *roots,int *ifail);
extern int dpolsolr_(double *tol,double *x,double *y,double *r__,double *rx,double *j,double *jx,double *a,int *n,int *sat);
extern int squares_(int *count,float *x,float *y,int *pmax);
extern int lsqfill_(int *count,float *x,float *y,int *pmax);
extern int solve_(int *nlsq);
extern int lsqsault_(int *count,float *x,float *y,int *pmax);
extern int opacget_(int *nfreq,float *freq,float *el,float *t0,float *p0,float *h0,float *fac,float *tb);
extern int refract_(float *t,float *pdry,float *pvap,float *z__,int *n,float *nu,float *t0,float *el,float *tb,float *tau,float *ldry,float *lvap);
extern int restini_(int *lbeam,int *nx1,int *ny1,float *fwhm1,float *fwhm2,float *pa,char *mode,short mode_len);
extern int restget_(int *lbeam,float *data,int *n1,int *n2,int *nx,int *ny,int *ic,int *jc);
extern int restdiff_(int *lbeam,float *gaus,int *n1,int *n2,int *nx,int *ny,int *ic,int *jc);
extern int restgaus_(float *gaus,int *nx,int *ny,int *x0,int *y0,float *bmaj,float *bmin,float *bpa);
extern int restore_(int *lmodel,int *i__,float *out);
extern int restadd_(float *out,float *dat,int *nx,int *ny);
extern int restfin_();
extern int selinput_(char *key,float *sels,int *maxsels,short key_len);
extern int selfudge_(float *rval,double *dval);
extern int selbug_(char *spec,char *message,short spec_len,short message_len);
extern int seldcde_(char *spec,int *k1,int *k2,double *vals,int *n,int *nmax,char *format,short spec_len,short format_len);
extern int selapply_(int *tno,float *sels,int *select);
extern int sfetra_(float *slon,float *slat,int *inv,int *sys);
extern int dsfetra_(double *lon,double *lat,int *inv,int *sys);
extern int shadowed_(int *tno, double *ants, float *limit);
extern int sortr_(float *array,int *n);
extern int sortd_(double *array,int *n);
extern int sorti_(int *array,int *n);
extern int spaxsw_(int *lh,char *switch__,char *ctype,double *cdelt,double *crval,short switch_len,short ctype_len);
extern int spline_(int *n,double *x,double *y,double *b,double *c__,double *d__);
extern int gettok_(char *string,int *k1,int *k2,char *token,int *length,short string_len,short token_len);
extern int getfield_(char *string,int *k1,int *k2,char *token,int *length,short string_len,short token_len);
extern int calget_(char *filename,char *source,float *freq,float *delfreq,double *day,float *deldate,float *flux,int *iostat,short filename_len,short source_len);
extern int tabflux_(char *filename,char *source,float *freq,float *delfreq,double *day,float *delday,float *flux,float *rms,int *line,int *iostat,short filename_len,short source_len);
extern int tabload_(char *name__,char *source,int *iostat,short name_len,short source_len);
extern int car2bim_(char *string,short string_len);
extern int tabfind_(char *source,float *freq,float *deltnu,double *day,float *deltime,float *flux,float *rms,int *line,int *iostat,short source_len);
extern int tabparse_(char *string,int *length,char *source,int *nentry,short string_len,short source_len);
extern int aliases_(char *source,char *srcalias,short source_len,short srcalias_len);
extern int addalias_(char *anchor,char *srcalias,short anchor_len,short srcalias_len);
extern int namparse_(char *string,int *length,short string_len);
extern int dectime_(char *string,double *value,char *fmt,int *ok,short string_len,short fmt_len);
extern int decangle_(char *angle,double *val,char *fmt,int *ok,short angle_len,short fmt_len);
extern int title_(int *lin,int *naxis,int *blc,int *trc,float *cbof);
extern int imscale_(float *map,int *mx,int *nx,int *ny,float *pmin,float *pmax);
extern int uvdatinp_(char *key,char *flags,short key_len,short flags_len);
extern int uvdatpy_(char *vis1, char* vis2,char *ltype, int *nc, float *ls, float *lw, float *lst, float *lf, char *refer, float *rs, float *rw, char *flags,short vis1_len,short vis2_len,short ltype_len,short refer_len,short flags_len);
extern int uvpolinp_(int *maxpol,int *npol,int *pols);
extern int uvdatopn_(int *tin);
extern int uvdatrd_(double *preamble,Complex *data,int *flags,int *n,int *nread);
extern int uvdatrew_();
extern int uvdatcls_();
extern int uvpolget_(double *preamble,Complex *data,int *flags,int *n,int *nread);
extern int uvpolchi_(int *nochi,float *cos2chi,float *sin2chi);
extern int uvdatwrd_(Complex *data,int *flags,int *n,int *nread);
extern int uvdatgti_(char *object,int *ival,short object_len);
extern int uvdatgtr_(char *object,float *rval,short object_len);
extern int uvdatgta_(char *object,char *aval,short object_len,short aval_len);
extern int uvdatset_(char *object,int *value,short object_len);
extern int uvlkini_();
extern int uvlkcorr_(double *baseline,int *maxpol,int *ncoeff,int *type__,Complex *coeffs,Complex *leaks,int *nleaks);
extern int uvfit1_(int *tno,char *object,int *n,double *a,double *epsi,short object_len);
extern int uvfit2_(int *tno,char *object,int *n,double *a,double *b,double *epsi,short object_len);
extern int uvgetbl_(double *preambl,Complex *data,int *nread,int *bl);
extern int uvgnini_(int *tno1,int *dogains1,int *dopass1);
extern int uvgngnin_();
extern int uvgnpsin_();
extern int uvgnfin_();
extern int uvgnfac_(double *time,double *baseline,int *pol,int *dowide,Complex *data,int *flags,int *nread,float *grms);
extern int uvgncwap_(int *dowide,int *ant1,int *ant2,Complex *data,int *flags,int *nread);
extern int uvgnget_(int *gitem,int *solno,Complex *gains,int *flags,int *nsols,int *ngains);
extern int uvgnpsap_(int *dowide,int *ant1,int *ant2,int *p,Complex *tau,Complex *data,int *flags,int *nread);
extern int uvgnps1t_(int *tno,int *vwide,int *vline);
extern int uvgnpspb_(int *ant1,int *ant2,int *p,int *nfeeds,int *nants,Complex *gains,int *gflags,Complex *data,int *flags,int *nread);
extern int uvgnpsdl_(Complex *tau,Complex *data,double *freq,double *freq0,int *nread);
extern int uvgnpsld_(int *tno,int *maxspect,int *ngains,int *nchan,int *nspect,double *sfreq,double *sdf,int *nschan,int *pgains,int *size);
extern int uvgnpsrd_(int *tno,int *dowide,int *nread,int *nchan,int *nfeeds,int *nants,int *aver,int *nspect,double *sfreq,double *sdf,int *nschan,int *ptab,int *pflags,int *pdat,int *ndat,int *pfreq,int *nfreq,int *dotau,int *dopass);
extern int uvgnpsfq_(int *nchan,int *nspect,double *sfreq,double *sdf,int *nschan,double *freq);
extern int uvgnpsgt_(int *tno,int *dowide,int *nread,int *mspect,int *doaver,int *nspect,double *sfreq,double *sdf,double *swidth,int *nschan);
extern int uvgninic_();
extern int uvgniniw_();
extern int width_(int *nspect,double *sdf,int *nschan,float *wide);
extern int varinit_(int *tin,char *linetype,short linetype_len);
extern int varonit_(int *tin,int *tout,char *linetype,short linetype_len);
extern int varwinit_(int *tin);
extern int varcopy_(int *tin,int *tout);
extern int varwide_(int *tvis,int *tout,int *lstart,int *lwidth,int *lstep,int *nchan,int *avall);
extern int varchan_(int *tvis,int *tout,int *lstart,int *lwidth,int *lstep,int *nchan,int *avall);
extern int varvelo_(int *tvis,int *tout,float *lstart,float *lstep,int *nchan,int *win,int *avall);
extern int varavall_(int *tvis,int *doav);
extern int varmintd_(int *tvis,char *var,double *value,short var_len);
extern int varmintr_(int *tvis,char *var,float *value,short var_len);
extern int vearth_(double *jday,double *pos,double *vel);
extern int vsite_(double *phi,double *st,double *vel);
extern int vsun_(double *vel);
extern int wpfit_(int *nd,int *np,float *x,float *y,float *w,float *a,float *rnorm,float *phi,float *phix,int *ierr);
extern int zedscale_(int *luni,float *freq,float *scale,int *noline);
extern int zed_(char *mode,float *ispect,float *vspect,int *m,int *n,float *a,float *b,float *siga,float *sigb,float *sigi,int *convrg,short mode_len);
extern int zeddelsq_(float *ispect,int *m,int *n,float *a,float *siga,float *sigi,int *delta,int *convrg);
extern int zedihat_(char *mode,float *ispect,float *vspect,int *m,int *n,float *a,float *b,float *ihat,short mode_len);
extern int zedvhat_(char *mode,float *ihat,int *m,int *n,float *a,float *b,float *vhat,short mode_len);
extern int zedfunc_(char *mode,float *ispect,float *vspect,int *m,int *n,float *a,float *b,float *sigi,short mode_len);
extern int zedlsq_(float *ispect,float *vspect,int *m,int *n,float *a,float *b,float *siga,float *sigb,float *sigi,int *leak,int *delta);
extern int zedml_(float *ispect,float *vspect,int *m,int *n,float *a,float *b,float *siga,float *sigb,float *sigi,int *leak,int *delta,int *convrg);
extern int zed1_(float *ispect,float *vspect,int *n,float *a,float *b,float *i0);
extern int zedfudge_(char *mode,float *ispect,float *vspect,int *m,int *n1,int *n2,float *a,float *b,float *fudge,float *rho,float *beam,int *nx,int *ny,short mode_len);
extern int zeddi_(float *ispect,float *vspect,float *a,float *b,float *di,int *m,int *md,int *n1,int *n2,int *n,int *delta);
extern int zedxyapp_(float *di,int *md,int *n,float *a);
extern int zedfapp_(float *di,int *md,int *n,float *gamma,float *rho);
extern int zedfcov_(float *gamma,int *md,float *rho);
extern int zedxycov_(float *a,int *n1,int *n2,float *beam,int *nx,int *ny);
extern int zedrho_(char *mode,float *ispect,float *vspect,int *m,int *n,float *rho,float *a,float *b,float *siga,float *sigb,float *sigi,int *convrg,short mode_len);
extern int zedrdr_(float *x,int *n,float *rho);
extern int zedr_(float *x,int *n,float *rho);
extern int binfid_(int *iwin,char *aveop,int *size,int *axis,int *bin,int *blc,int *trc,int *nbin,short aveop_len);
extern int binrd2_(int *h1,int *h2,int *bin,int *blc,int *trc,int *nbin,float *row,float *data1,float *data2);
extern int binup_(float *data,int *blc,int *trc,int *bin,float *norm,int *ipt,float *binned,int *wrt);

# C functions

extern void pad(char *string,int length);
#extern char *zterm(char *string,int length);
extern int dexpand_(char *template,char *output,int template_len,int output_len);
extern void scropen_c(int *handle);
extern void scrclose_c(int handle);
extern void scrread_c(int handle,float *buffer,int offset,int length);
extern void scrwrite_c(int handle,float *buffer,int offset,int length);
extern void uvopen_c(int *tno,char *name,char *status);
extern void uvtrack_c(int tno,char *name,char *switches);
extern void uvcopyvr_c(int tin,int tout);
extern void uvvarini_c(int tno,int *handle);
extern void uvvarset_c(int handle,char *name);
extern void uvvarcpy_c(int handle,int tout);
extern int uvvarupd_c(int handle);
extern void uvflush_c(int tno);
extern void uvclose_c(int tno);
extern int uvupdate_c(int tno);
extern void uvnext_c(int tno);
extern int uvscan_c(int tno,char *var);
extern void uvrewind_c(int tno);
extern void uvread_c(int tno,double *preamble,float *data,int *flags,int n,int *nread);
extern void uvwread_c(int tno,float *data,int *flags,int n,int *nread);
extern void uvflgwr_c(int tno,int *flags);
extern void uvwflgwr_c(int tno,int *flags);
extern void uvset_c(int tno,char *object,char *type,int n,double p1,double p2,double p3);
extern void uvselect_c(int tno,char *object,double p1,double p2,int *datasel);
extern void uvsela_c(int tno,char *object,char *string,int datasel);
extern void uvinfo_c(int tno,char *object,double *data);
extern void uvwrite_c(int tno,double *preamble,float *data,int *flags,int n);
extern void uvwwrite_c(int tno,float *data,int *flags,int n);
extern void uvprobvr_c(int tno,char *var,char *type,int *length,int *updated);
extern void uvrdvra_(int *tno,char *var,char *cdata,char *def,int var_len,int data_len,int def_len);
extern void uvrdvri_(int *tno,char *var,int *data,int *def,int var_len);
extern void uvrdvrr_(int *tno,char *var,float *data,float *def,int var_len);
extern void uvrdvrd_(int *tno,char *var,double *data,double *def,int var_len);
extern void uvrdvrc_(int *tno,char *var,float *data,float *def,int var_len);
extern void uvgetvra_(int *tno,char *var,char *uvadata,int var_len,int data_len);
extern void uvgetvri_(int *tno,char *var,int *data,int *n,int var_len);
extern void uvgetvrj_(int *tno,char *var,int *data,int *n,int var_len);
extern void uvgetvrr_(int *tno,char *var,float *data,int *n,int var_len);
extern void uvgetvrd_(int *tno,char *var,double *data,int *n,int var_len);
extern void uvgetvrc_(int *tno,char *var,float *data,int *n,int var_len);
extern void uvputvri_(int *tno,char *var,int *data,int *n,int var_len);
extern void uvputvrr_(int *tno,char *var,float *data,int *n,int var_len);
extern void uvputvrd_(int *tno,char *var,double *data,int *n,int var_len);
extern void uvputvrc_(int *tno,char *var,float *data,int *n,int var_len);
extern void uvputvra_(int *tno,char *var,char *data,int var_len,int data_len);
extern void hopen_c(int *tno,char *name,char *status,int *iostat);
extern void hclose_c(int tno);
extern void hflush_c(int tno,int *iostat);
extern void habort_c();
extern void hrm_c(int tno);
extern void hdelete_c(int tno,char *name,int *iostat);
extern void haccess_c(int tno,int *item,char *name,char *status,int *iostat);
extern void hmode_c(int tno,char *hmode);
extern int hexists_c(int tno,char *item);
extern void hdaccess_c(int item,int *iostat);
extern int hsize_c(int item);
extern int htell_c(int item);
extern void hseek_c(int item,int offset);
extern void hreada_c(int item,char *hrline, int length,int *iostat);
extern void hwritea_c(int item,char *line, int length,int *iostat);
extern void hreadb_c(int item,char *hrbuffer,int offset,int length,int *iostat);
extern void hwriteb_c(int item,char *buffer,int offset,int length,int *iostat);
extern void hreadj_c(int item,int *buffer,int offset,int length,int *iostat);
extern void hwritej_c(int item,int *buffer,int offset,int length,int *iostat);
extern void hreadi_c(int item,int *buffer,int offset,int length,int *iostat);
extern void hwritei_c(int item,int *buffer,int offset,int length,int *iostat);
extern void hreadr_c(int item,float *buffer,int offset,int length,int *iostat);
extern void hwriter_c(int item,float *buffer,int offset,int length,int *iostat);
extern void hreadd_c(int item,double *buffer,int offset,int length,int *iostat);
extern void hwrited_c(int item,double *buffer,int offset,int length,int *iostat);
extern void hisopen_c(int tno,char *status);
extern void hisread_c(int tno,char *hisline,int *eof);
extern void hiswrite_c(int tno,char *line);
extern void hisclose_c(int tno);
extern void xyopen_c(int *tno,char *name,char *status,int naxis,int *axes);
extern void xyflush_c(int tno);
extern void xyclose_c(int tno);
extern void xyread_c(int tno,int index,float *buffer);
extern void xywrite_c(int tno,int index,float *buffer);
extern void xymkrd_c(int tno,int index,int *buffer,int n,int *nread);
extern void xymkwr_c(int tno,int index,int *buffer,int n);
extern void xyflgrd_c(int tno,int index,int *buffer);
extern void xyflgwr_c(int tno,int index,int *buffer);
extern void xysetpl_c(int tno,int naxis,int *axes);
extern void hdprobe_c(int tno,char *keyword,char *hddescr,int descr_len,char *hdtype,int *n);
extern void rdhdr_c(int tno,char *keyword,float *value,float defval);
extern void rdhdi_c(int tno,char *keyword,int *value,int defval);
extern void rdhdd_c(int tno,char *keyword,double *value,double defval);
extern void rdhda_c(int tno,char *keyword,char *rdvalue,char *defval,int value_len);
extern void rdhdc_c(int tno,char *keyword,float *value,float *defval);
extern void wrhdr_c(int tno,char *keyword,float value);
extern void wrhdd_c(int tno,char *keyword,double value);
extern void wrhdi_c(int tno,char *keyword,int value);
extern void wrhdc_c(int tno,char *keyword,float *value);
extern void wrhda_c(int tno,char *keyword,char *value);
extern void hdcopy_c(int tIn,int tOut,char *keyword);
extern int hdprsnt_c(int tno,char *keyword);
extern void xyzopen_c(int *tno,char *name,char *status,int *naxis,int *axlen);
extern void xyzclose_c(int tno);
extern void xyzflush_c(int tno);
extern void xyzmkbuf_c();
extern void xyzsetup_c(int tno,char *subcube,int *blc,int *trc,int *viraxlen,int *vircubesize);
extern void xyzs2c_c(int tno,int subcubenr,int *coords);
extern void xyzc2s_c(int *tno,int *coords,int *subcubenr);
extern void xyzread_c(int tno,int *coords,float *data,int *mask,int *ndata);
extern void xyzpixrd_c(int tno,int pixelnr,float *data,int *mask);
extern void xyzprfrd_c(int tno,int profilenr,float *data,int *mask,int *ndata);
extern void xyzplnrd_c(int tno,int planenr,float *data,int *mask,int *ndata);
extern void xyzwrite_c(int tno,int *coords,float *data,int *mask,int *ndata);
extern void xyzpixwr_(int tno,int pixelnr,float *data,int *mask);
extern void xyzprfwr_(int tno,int profilenr,float *data,int *mask,int *ndata);
extern void xyzplnwr_(int tno,int planenr,float *data,int *mask,int *ndata);
extern float j1xbyx_(float *arg);
extern float jinc_(float *x);
extern float chat_(float *x);
extern int sortidxd_(int n, double *x, int *idx);
extern int sortidxr_(int n, float *x, int *idx);
extern int sortidxi_(int n, int *x, int *idx);
extern int polspara_(int *code);
extern void polsc2p_(char *ret_val, short ret_val_len, int *code);
extern int polsp2c_(char *mnemo, short mnemo_len);
