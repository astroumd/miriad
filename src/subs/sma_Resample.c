/* jhz - may2004 */
/* 2004-5    propose the development of SMA code unde miriad */
/* 2004-5    start to write the SMAmir2Miriad code (SMALOD) */
/* 2004-7-15 read/write out all vis data */
/* 2004-7-16 write lst */
/* 2004-7-17 correct for spectral order based on s sequence */
/* 2004-7-19 source information */
/* 2004-7-20 sideband separation */
/* 2004-7-22 fix coordinates for j2000 and apparent (observing) */
/* 2004-7-23 fix skip beginning and ending scans */
/* 2004-7-24 check and correct the flagging */
/* 2004-7-25 add a variable sourceid */
/* 2004-7-26 Tsys EL AZ information */
/* 2004-8-2  Instrument, telescope, observer version */
/* 2004-8-4  flip the phase for lsb */
/* 2004-12-10 rename header file data_write.h to sma_data.h */
#include <math.h>
#include <rpc/rpc.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include "sma_data.h"
#define H_BYTE          1
#define H_INT           2
#define H_INT2          3
#define H_REAL          4
#define H_DBLE          5
#define H_TXT           6
#define H_CMPLX         7
#define OK 0
/* Speed of light (meters/second). */
#define DCMKS           299792458.0
#define uvputvra_c(tno,name,value)   \
        uvputvr_c(tno,H_BYTE,name,value,strlen(value))
#define uvputvrj_c(tno,name,value,n) \
        uvputvr_c(tno,H_INT2,name,(char *)(value),n)
#define uvputvri_c(tno,name,value,n) \
        uvputvr_c(tno,H_INT,name,(char *)(value),n)
#define uvputvrr_c(tno,name,value,n) \
        uvputvr_c(tno,H_REAL,name,(char *)(value),n)
#define uvputvrd_c(tno,name,value,n) \
        uvputvr_c(tno,H_DBLE,name,(char *)(value),n)
#define uvputvrc_c(tno,name,value,n) \
        uvputvr_c(tno,H_CMPLX,name,(char *)(value),n)

/* extern variable while read mir data */
char pathname[36];
static FILE* fpin[6];
int nsets[6];
double jday; /* julian day */
struct inh_def   **inh;
struct blh_def   **blh;
/*struct sph_def   **sph;*/
struct codeh_def **cdh;
struct ant_def   **enh;
struct sch_def   **sch;


/* declare the externals struct which is the same to
   the common blocks, atlodd and atlodc */

char sname[64];
smlodd smabuffer;
/*smEng smaEng;
*/

struct vis { float real;
         float imag;
};
int rsmir_Read();

unsigned long mfsize(FILE *);
struct inh_int_def {
	int  a[512];
};
void rspokeinisma_c();
void rspokeflshsma_c();
char *rar2c();
char *decr2c();
int spdecode();
float juliandate();
double slaCldj();
void precess();
void nutate();
void aberrate();
void elaz();
void tsysStore();
/* interface between fortran and c */
void rsmirread_c(char *datapath, char *jst[])
{ extern char pathname[];
  int jstat;
  int tno;
  struct vis *vis_in;
  float *weight;
  int  baseline, inteID;
  double ut;
  float u, v, w;
  int flag, bin, if_no, sourceno;
       strcpy(pathname,datapath);
        jstat=(int)*jst;
        jstat = rsmir_Read(pathname,jstat);
        *jst = (char *)jstat; 
   return;
}

void rsmiriadwrite_c(char *datapath, char *jst[])
{ extern char pathname[];
  int jstat,kstat;
  int tno;
  extern smlodd smabuffer;
      tno = smabuffer.tno;
     jstat=-1;
/* open mir files */
     jstat = rsmir_Read(pathname,jstat);
        *jst = (char *)jstat;
/* then start to read and write data if the files are ok. */
     if (jstat==0) {jstat=0;
         jstat = rsmir_Read(pathname,jstat);}
         else {
         printf("file problem\n");
            }
      
     return;
}

void rssmaflush_c(mflag,scinit,tcorr,scbuf,xflag,yflag,maxif,maxant,scanskip,scanproc, sb, rxif)
int *mflag, *scinit, tcorr, *scbuf, *xflag, *yflag, maxif, maxant,scanskip,scanproc, sb, rxif;
{ /* flush mirdata*/
int i, j;
int jstat;
int kstat;
int tno;
char telescope[4];
char instrument[4];
char observer[16];
char version[16];
extern char pathname[];
extern smlodd smabuffer;
      tno = smabuffer.tno;
          smabuffer.scanskip=scanskip;
          smabuffer.scanproc=scanproc;
          smabuffer.sb = sb;
           smabuffer.rxif= rxif;
     *mflag = FALSE;
     for (j=1; j<maxant+1; j++) {
     for (i=1; i<maxant+1; i++) {
            scinit[i,j] = FALSE;
            scbuf[i,j]  = FALSE;
            xflag[i,j]  = FALSE;
            yflag[i,j]  = FALSE;
     }
     } 
      kstat = jstat = -1;  
/*read header  */
      rspokeflshsma_c((char *)&(kstat)); 
/*  write ante numbers */
      if(smabuffer.nants!=0) {
         uvputvri_c(tno,"nants",&(smabuffer.nants),1);
/*  write telescope name and other description parameters */
       sprintf(telescope,"SMA\0");
       sprintf(instrument,"SMA\0");
       sprintf(observer,"SmaUser\0");
       sprintf(version, "test\0");
       uvputvra_c(tno, "telescop", telescope);
       uvputvra_c(tno, "instrume", instrument);
       uvputvra_c(tno, "observer", observer);
       uvputvra_c(tno, "version", version);
         }
};
    
void rspokeinisma_c(char *kst[], int tno1, int *dosam1, int *doxyp1,
  int *doop1, int *dohann1, int *birdie1, int *dowt1, int *dopmps1,
  int *dobary1, int *doif1, int *hires1, int *nopol1, int *oldpol1, 
  double lat1, double long1, int rsnchan1)
{ /* rspokeflshsma_c == pokeflsh */
    int buffer;
    extern char sname[];
    extern smlodd smabuffer;
    
  /* initialize the external buffers */   
   strcpy(sname, " ");
        smabuffer.tno    = tno1;
        smabuffer.rsnchan= rsnchan1;
        smabuffer.dosam  = *dosam1;
        smabuffer.doxyp  = *doxyp1;
        smabuffer.opcorr = *doop1;
        smabuffer.dohann = *dohann1;
        smabuffer.doif   = *doif1;
        smabuffer.dobary = *dobary1;
        smabuffer.birdie = *birdie1;
        smabuffer.dowt   = *dowt1;
        smabuffer.dopmps = *dopmps1;
        smabuffer.hires  = *hires1;
        smabuffer.nopol  = *nopol1;
        smabuffer.oldpol = *oldpol1;
        smabuffer.lat    = lat1;
        smabuffer.longi  = long1;
    if(smabuffer.dowt>0) {
           /* call lagwt(wts,2*smcont-2,0.04) */
           /* process weights here. */ 
                   }
        smabuffer.newsc = FALSE;
        smabuffer.newfreq = FALSE;
        smabuffer.nants = 0;
        smabuffer.nifs = 0;
        smabuffer.nused = 0;
        smabuffer.tcorr = 0;
        buffer=(int)*kst;
        *kst= OK;

}

void rspokeflshsma_c(char *kst[])
{ /* rspokeflshsma_c== pokeflsh */
     int buffer, tno, ibuff, i;
     int i1, i2, ifs, p, bl, sb, nchan, nspect;
     int npol,ipnt,ischan[SMIF];
     int tbinhi,tbin,binhi,binlo,bin, nbin[SMIF];
     int nstoke[SMIF], nfreq[SMIF], sfreq[SMIF], sdf[SMIF], restfreq[SMIF];
     double preamble[5], tdash;
     float freq0[SMIF],fac[SMIF], tfac;
     float jyperk, vel;
     visdata vis[MAXCHAN];
     int flags[MAXCHAN]; 
     extern char sname[];
     extern smlodd smabuffer;
     struct pols *polcnt;
     struct pols *rscntstokes();
      char telescope[4];
      char instrument[4];
      char observer[16];
      char version[16];
     tno = smabuffer.tno;
     sb = smabuffer.sb; /* sb=0 for lsb; sb=1 for usb; sb=2 for both */
     if(smabuffer.nused==0) 
               return;
/* put ants to uvdata */
      if(smabuffer.nants!=0) {
       uvputvri_c(tno,"nants",&(smabuffer.nants),1);
/*  write telescope name and other description parameters */
       sprintf(telescope,"SMA\0");
       sprintf(instrument,"SMA\0");
       sprintf(observer,"SmaUser\0");
       sprintf(version, "test\0");
       uvputvra_c(tno, "telescop", telescope);
       uvputvra_c(tno, "instrume", instrument);
       uvputvra_c(tno, "observer", observer);
       uvputvra_c(tno, "version", version);
         }

     if(smabuffer.newfreq>0) {
           if(smabuffer.doif>0) {
           for (ifs=1; ifs < smabuffer.nifs; ifs++) {
            if(smabuffer.nstoke[ifs-1]!=smabuffer.nstoke[0]) 
 bug_c( "f", "Number of polarisations differ between IFs. Use options=noif.\n"); 
     for (p=1; p< smabuffer.nstoke[ifs-1]; p++) {
         if(smabuffer.polcode[ifs-1][p-1][0]!=smabuffer.polcode[0][p-1][0]) 
 bug_c( "f", "Polarisation types differ between IFs. Use options=noif.\n");
                                                }
                                                      }
                             }
                                 }
        else 
             {
             if(smabuffer.hires > 0) 
             for (ifs=1; ifs<smabuffer.nifs; ifs++){
              if (smabuffer.nbin[ifs]!=smabuffer.nbin[0]) 
    bug_c( "f", 
      "Number of bins in different IFs must agree for options=hires\n");
                                                  }
            } 
                  
/* setup time */
       if(smabuffer.hires > 0) {
          tdash  = smabuffer.time - 
          0.5*smabuffer.inttim*(smabuffer.nbin[0]-1)/86400.0;
          tbinhi = smabuffer.nbin[0]; 
                               }
          else  {
            tdash  = smabuffer.time;
            tbinhi = 1;
                }
/* Write out the met data */
/* no information for met data in mir archived data */
            smabuffer.mflag=-1;
          if(smabuffer.mflag > 0) {
           uvputvrr_c(tno, "airtemp",&smabuffer.mdata[0],1);
           uvputvrr_c(tno,"pressmb", &smabuffer.mdata[1],1); 
           uvputvrr_c(tno,"relhumid",&smabuffer.mdata[2],1);
           uvputvrr_c(tno,"wind", &smabuffer.mdata[3],1);
           uvputvrr_c(tno,"winddir",&smabuffer.mdata[4],1);
                                  }
/* Computer apparent LST */
           uvputvrd_c(tno,"lst",&(smabuffer.lst),1);
    /* store elaz data */
           elaz(tno);
           for (tbin=1; tbin<tbinhi+1; tbin++) {

           if(smabuffer.opcorr>0) {
              if(smabuffer.mflag==0)
            bug_c("f","No met data to compute opacity correction\n");
              for (ifs=0; ifs < smabuffer.nifs; ifs++) {
           freq0[ifs]= (smabuffer.sfreq[ifs] +
              0.5*(smabuffer.nfreq[ifs]-1)*smabuffer.sdf[ifs]
                       )*1e9;
                     }

           tfac = 1;
              for (ifs=0; ifs < smabuffer.nifs; ifs++) {
                fac[ifs] = 1/fac[ifs];
              tfac = tfac * fac[ifs];
                                                       }
                                                }
          else {
            for (ifs=0; ifs < smabuffer.nifs; ifs++) {
           fac[ifs] = 1;
                                                     }
                }

/* Compute radial velocity of the observatory */
/*call velrad(.not.dobary,tdash,obsra,obsdec,ra,dec,lst,lat,vel)*/
        uvputvrr_c(tno,"veldop",&vel,1);
                jyperk=139.;    /* assuming eta=0.7 d=6m */
        uvputvrr_c(tno,"jyperk",&jyperk,1);
/* Handle the case that we are writing the multiple IFs out as multiple
   records. */
         if(smabuffer.doif!=1&&smabuffer.nifs>1) {
              nspect =ischan[0]= 1;
            for(ifs=0; ifs < smabuffer.nifs; ifs++) {
                printf(" writing headers\n");
                
               uvputvri_c(tno,"nspect",&nspect,1);
                printf(" search\n");
               uvputvri_c(tno,"npol",  &(smabuffer.nstoke[ifs]),1);
               uvputvri_c(tno,"nschan",&(smabuffer.nfreq[ifs]),1);
               uvputvri_c(tno,"ischan",&ischan[0],1);
               uvputvrd_c(tno,"sfreq", &(smabuffer.sfreq[ifs]),1);
               uvputvrd_c(tno,"sdf",  &(smabuffer.sdf[ifs]),  1);
               uvputvrd_c(tno,"restfreq",&(smabuffer.restfreq[ifs]),1);
               bl=0;
                   for(i2=1; i2<smabuffer.nants+1; i2++){
                   for(i1=1; i1<i2+1; i2++){
                  preamble[0] = smabuffer.u[bl];
                  preamble[1] = smabuffer.v[bl];
                  preamble[2] = smabuffer.w[bl];
                  preamble[3] = tdash;
                  preamble[4] = 256*i1 + i2;
                  for(p=0; p<smabuffer.nstoke[ifs]; p++){
                    ipnt = smabuffer.pnt[ifs][p][bl][0];
                   printf("ipnt=%d\n", ipnt);
                     if(ipnt>0) 
               uvputvrr_c(tno,"inttime",&smabuffer.inttime[bl],1);
          if(smabuffer.opcorr==0) 
                  {  /* call opapply(data(ipnt),nfreq(if),fac(if)) */
    uvwrite_c(tno,preamble,smabuffer.data[ipnt],flags,smabuffer.nfreq[ifs]);
           
                  }
                                                          }
                    bl++;
                                                            }
               }
                                                            }
                                                     }
        else {
/* Handle the case were we are writing the multiple IFs out as a single record.
   */
      if(smabuffer.newfreq>0) {
            ischan[0] = 1;
              for (ifs = 1; ifs < smabuffer.nifs; ifs++) {
                ischan[ifs] = ischan[ifs-1] + smabuffer.nfreq[ifs];
               }
          uvputvri_c(tno,"nspect",&(smabuffer.nifs),1);
          uvputvri_c(tno,"ischan",&(ischan),smabuffer.nifs);
          uvputvri_c(tno,"nschan",&(smabuffer.nfreq),smabuffer.nifs);
          uvputvrd_c(tno,"sfreq",&(smabuffer.sfreq),smabuffer.nifs);
          uvputvrd_c(tno,"sdf",&(smabuffer.sdf),smabuffer.nifs);
          uvputvrd_c(tno,"restfreq",&(smabuffer.restfreq),smabuffer.nifs);
                                         }
/* call tsysStore */
            uvputvri_c(tno,"tcorr",&(smabuffer.tcorr),1);
          tsysStore(tno); 
              bl=0;
              for(i2=1; i2<smabuffer.nants+1; i2++){
                for(i1=1; i1<i2+1; i1++){
                  preamble[0] = smabuffer.u[bl];
                  preamble[1] = smabuffer.v[bl];
                  preamble[2] = smabuffer.w[bl];
                  preamble[3] = smabuffer.time; 
                  preamble[4] = smabuffer.blcode[bl]; 
       polcnt = rscntstokes(npol, bl, sb);
       npol = polcnt->npol;
          if(npol>0) {
            uvputvri_c(tno,"npol",&npol,1);
            for(p=polcnt->polstart; p<polcnt->polend+1; p++){
    nchan = rsgetdata(&vis,&flags,&nchan, p, bl, sb);
    if(nchan>0) {
           ibuff = smabuffer.polcode[0][p][bl];
         uvputvri_c(tno,"pol",&ibuff,1);
         uvputvrr_c(tno,"inttime",&smabuffer.inttime[bl],1);
         uvwrite_c(tno,&preamble,&vis,&flags,nchan);
                }
                                                        }
                                     }
                                               
                 bl++;
                    }
                                                  }
             }
           }
     smabuffer.newfreq=-1;
/* re-initialize the pntr */
    for (ifs=0; ifs<SMIF; ifs++) {
    for (p=0; p<SMPOL; p++) {
    for (bl=0; bl<SMBAS; bl++) {
    for (sb=0; sb<SMSB; sb++) {
    smabuffer.pnt[ifs][p][bl][sb]=0;
      }}}}

}

int rsgetdata(smavis, smaflags, smanchan, p, bl, sb)
visdata smavis[MAXCHAN];
int smaflags[MAXCHAN];
int *smanchan;
int p;
int bl;
int sb;
{ /* Construct a visibility record constructed from multiple IFs. */
int nifs=smabuffer.nifs;
int nvis;
int pnt[nifs],nfreq[nifs],bchan[nifs];
float fac[nifs];
int n,ipnt,i,nchand, nchan; 
int ifpnt, polpnt, blpnt, binpnt;
    nchan = 0;
        nchand = 0;
    for (n=0; n<nifs; n++) {
       ipnt = smabuffer.pnt[n][p][bl][sb]; 
      if(ipnt>0) {
        if(nchan<nchand) {
               for (i=nchan; i<nchand; i++) {
              smaflags[i] = -1;
                smavis[i].real = 0;
                smavis[i].imag = 0;
              
                                            }    
                     nchan = nchand;
                         }
          for (i=nchan; i< nchan+smabuffer.nfreq[n]; i++){
            fac[n]=1000000.;
/*          printf("sb=%d %f\n", sb, pow((double)(-1),(double)(sb+1))); 
  */
    smavis[i].real =  fac[n]*smabuffer.data[ipnt].real;
      smavis[i].imag =  fac[n]*smabuffer.data[ipnt].imag*
           (float)pow((double)(-1),(double)(sb+1)); 
         smaflags[i] =  smabuffer.flag[n][p][bl][sb];       
              ipnt++;    
                    }
     if(smabuffer.bchan[n]>=1&&smabuffer.bchan[n]<=smabuffer.nfreq[n])
              smaflags[nchan+smabuffer.bchan[n]] = -1;
              nchan = nchan + smabuffer.nfreq[n];
                                                        }
              nchand = nchand + smabuffer.nfreq[n];
                    }

       if(nchan<nchand&&nchan>0) {
         for(i=nchan+1; i< nchand+1; i++) {
              smaflags[i] = -1;
              smavis[i].real = 0;
              smavis[i].imag = 0;
                                        }
          nchan = nchand;
                                 }
                 *smanchan=nchan;
                   return nchan;
 }

struct pols *rscntstokes(int npol, int bl, int sb)
{ /*Determine the number of valid Stokes records in this record.*/
    int nifs = SMIF;
    int nstoke = SMPOL;
    short valid;
    int p, p1, p2, ifs;
    static struct pols polcnts;
    npol =0;
    p1=-1;
    p2=1;
    for (p=0; p< nstoke; p++) {
          valid = -1;
           for ( ifs =0; ifs<nifs; ifs++) {
            valid = valid;
           if(smabuffer.pnt[ifs][p][bl][sb] > 0) valid = 1;
					}
           if(valid>0&&p1==-1) {p1=p; p2=p1;}
           if(valid>0) {npol++; if(p>p1) p2=p1+1;}
                                }
         polcnts.npol=npol;
         polcnts.polstart=p1;
         polcnts.polend=p2;
         return (&polcnts);
}          
              

int rsmir_Read(char *datapath,
             int jstat)
{
char location[6][64];
char pathname[36];
char filename[6][36];
int set, readSet;
int file,nfiles = 6;
int headerbytes[6];
extern int nsets[];
extern FILE* fpin[];
extern smlodd smabuffer;
extern double jday;
smEng **smaEngdata;
double epo2jul();
int i,j,k,l,m,n;
int kk,ll;
int difference;
long imax,bytepos,nbytes,datalength;
long *data_start_pos;
long *sph_start_pos;
int firstbsl,lastbsl,inhid;
int numberBaselines,numberSpectra,numberSidebands,numberRxif;
int blhid,firstsp,lastsp;
int inhset,blhset,sphset;
int spcode[25];
short int realvisS,imagvisS,scale;
float realvisF[128],imagvisF[128];
short int *shortdata;
double r,cost,sint,z0,tmp, rar, decr;
double antpos[3*MAXANT+1];
int tno, ipnt, usbstart, usbend;
int kstat;
char *kst[4];
char target[6];
char unknown[6];
int ntarget;
int p, bl, bin;
time_t timer, startTime, endTime;
float trueTime;
blvector blarray[MAXANT][MAXANT];
station  antenna[MAXANT];
source   multisour[MAXSOURCE];
int sourceID, phaseSign;
correlator smaCorr;
frequency  smaFreq[2];
uvwPack **uvwbsln;
visdataBlock  visSMAscan;
int sphSizeBuffer=SMIF*MAXBAS*6;
int ibuff, nnants;
int ifpnt, polpnt, blpnt, sbpnt, sblpnt, binpnt, rx_irec;
int avenchan;
float avereal, aveimag;
extern struct inh_def   **inh;
extern struct blh_def   **blh;
static struct sph_def   **sph;
extern struct codeh_def **cdh;
extern struct ant_def   **enh;
extern struct sch_def   **sch;

struct inh_def *inh_read(FILE *);
struct blh_def *blh_read(FILE * );
struct sph_def *sph_read(FILE * );
struct codeh_def *cdh_read(FILE * );
struct ant_def *enh_read(FILE * );
struct sch_def *sch_head_read(FILE * );
int sch_data_read(FILE *, long int, short int * );
strcpy(pathname,datapath);
strcpy(filename[0],"in_read");
strcpy(filename[1],"bl_read");
strcpy(filename[2],"sp_read");
strcpy(filename[3],"codes_read");
strcpy(filename[4],"eng_read");
strcpy(filename[5],"sch_read");
strcpy(target,"target");
strcpy(unknown,"unknown");
ntarget=0;

/* number of bytes in each type of header. */
/* sch is variable number of bytes */
headerbytes[0] = 132;
headerbytes[1] = 118;
headerbytes[2] = 100;
headerbytes[3] = 42;
headerbytes[4] = 188;
headerbytes[5] = 0;
     switch(jstat) {
case -3:
/* Open all the files */
for (file=0;file<nfiles;file++){

  strcpy(location[file],pathname); 
  strcat(location[file],filename[file]);
  fpin[file] = fopen(location[file],"r");
        if (fpin[file] == NULL) {
                printf("Problem opening the file %s\n",location[file]);
                perror("file open problem");
                exit(-1);
        } else {
                printf("Found file %s\n",location[file]);
        }
}
 
/* Get the size of each file and compute the number of headers */

for (file=0;file<nfiles;file++){
  if(file < 5 ){
    imax = mfsize(fpin[file]);
    nsets[file] = imax / headerbytes[file];
  }
}

break;
case 0:   /*read header & vis */
startTime = time(NULL);
/* Allocate memory to store all the headers */
 inh = (struct inh_def **) malloc(nsets[0]*sizeof( struct inh_def *));
    for (set=0;set<nsets[0];set++) {
    inh[set] = (struct inh_def *)malloc(sizeof(struct inh_def ));
    if (inh[set] == NULL ){
 printf("ERROR: Memory allocation for inh failed trying to allocate %d bytes\n",
                        nsets[0]*sizeof(struct inh_def));
      exit(-1);
    }
  }

 blh = (struct blh_def **) malloc(nsets[1]*sizeof( struct blh_def *));
  for (set=0;set<nsets[1];set++) {
  blh[set] = (struct blh_def *)malloc(sizeof(struct blh_def ));
  if (blh[set] == NULL ){
 printf("ERROR: Memory allocation for blh failed trying to allocate %d bytes\n",
                        nsets[1]*sizeof(struct blh_def));
      exit(-1);
    }
  }

uvwbsln = (struct uvwPack **) malloc(nsets[0]*sizeof( struct uvwPack));
for (set=0;set<nsets[0];set++) {
   uvwbsln[set] = (struct uvwPack *)malloc(sizeof(struct uvwPack));
    if (uvwbsln[set] == NULL ){
printf("ERROR: Memory allocation for uvwbsln failed for %d bytes\n",
nsets[0]*sizeof(struct uvwPack));
      exit(-1);
                              }
                                }

/* Read the headers */
     for (set=0;set<nsets[0];set++) {
 	*inh[set] = *(inh_read(fpin[0])); 
      if (SWAP_ENDIAN) {
       inh[set] =  swap_inh(inh[set]);
                           }
 }
if (SWAP_ENDIAN) {
printf("FINISHED READING  IN HEADERS (endian-swapped)\n");
} else {
printf("FINISHED READING  IN HEADERS\n");
}
  for (set=0;set<nsets[1];set++) {
	*blh[set] = *(blh_read(fpin[1]));
          if (SWAP_ENDIAN) {
       blh[set] =  swap_blh(blh[set]);
                           }
  }

/* loading baselines */
blhset =0;
for (inhset=0; inhset<nsets[0]; inhset++) {
    inhid=uvwbsln[inhset]->inhid = inh[inhset]->inhid;
    firstbsl=-1;
    lastbsl =-1;
for (set=blhset; set<nsets[1]; set++) {
    if (firstbsl == -1 && blh[set]->inhid == inhid) 
       firstbsl = set;
    if (firstbsl != -1 && blh[set]->inhid != inhid)
       lastbsl = set - 1;
    if (lastbsl != -1) break;
    if (set==nsets[1]-1) lastbsl = set;

       uvwbsln[inhset]->uvwID[set-blhset].u = blh[set]->u;
       uvwbsln[inhset]->uvwID[set-blhset].v = blh[set]->v;
       uvwbsln[inhset]->uvwID[set-blhset].w = blh[set]->w;
       uvwbsln[inhset]->uvwID[set-blhset].blhid = blh[set]->blhid;
       uvwbsln[inhset]->uvwID[set-blhset].blsid = blh[set]->blsid;
       uvwbsln[inhset]->uvwID[set-blhset].blcode =
       blh[set]->itel1*256+blh[set]->itel2;
       uvwbsln[inhset]->uvwID[set-blhset].isb = blh[set]->isb;
       uvwbsln[inhset]->uvwID[set-blhset].irec = blh[set]->irec;
/* convert MIR polarization label used befor sep1,2004 to Miriad */
/* 
used   MIR  actual          Miriad
non      0   I                 1
RR       1   HH               -5
RL       2   HV               -7
LR       3   VH               -8
LL       4   VV               -6
*/
      if(smabuffer.oldpol==1) {
            switch(blh[set]->ipol) {
case 0: uvwbsln[inhset]->uvwID[set-blhset].ipol= 1; break;
case 1: uvwbsln[inhset]->uvwID[set-blhset].ipol=-5; break;
case 2: uvwbsln[inhset]->uvwID[set-blhset].ipol=-7; break;
case 3: uvwbsln[inhset]->uvwID[set-blhset].ipol=-8; break;
case 4: uvwbsln[inhset]->uvwID[set-blhset].ipol=-6; break;
               }
           } else {
  if(blh[set]->ipol!=0&&smabuffer.nopol!=1) {
  fprintf(stderr,"###program exiting because the file may contain polarization data.\n");
  fprintf(stderr,"###Please try options=oldpol to load polarization data.\n");
       exit(0);
         }
/*       uvwbsln[inhset]->uvwID[set-blhset].ipol= 1;
*/
       uvwbsln[inhset]->uvwID[set-blhset].ipol= -5 -blh[set]->ipol;
          }
          }
     uvwbsln[inhset]->n_bls = numberBaselines = lastbsl-firstbsl+1;
     blhset += numberBaselines;
}
/* set antennas */
      blarray[1][1].ee = blh[0]->ble ;
      blarray[1][1].nn = blh[0]->bln ;
      blarray[1][1].uu = blh[0]->blu ;
      smabuffer.nants=1;
for (set=1;set<nsets[1];set++) {
      if(blarray[1][1].ee != blh[set]->ble) {
      blarray[blh[set]->itel1][blh[set]->itel2].ee = blh[set]->ble;
      blarray[blh[set]->itel1][blh[set]->itel2].nn = blh[set]->bln;
      blarray[blh[set]->itel1][blh[set]->itel2].uu = blh[set]->blu;
      blarray[blh[set]->itel1][blh[set]->itel2].itel1 = blh[set]->itel1;
      blarray[blh[set]->itel1][blh[set]->itel2].itel2 = blh[set]->itel2;
      blarray[blh[set]->itel1][blh[set]->itel2].blid  = blh[set]->blsid;
         smabuffer.nants++; }
          else
        {smabuffer.nants = (int)((1+sqrt(1.+8.*smabuffer.nants))/2);
/* printf("mirRead: number of antenna =%d\n", smabuffer.nants);*/
                goto blload_done;}
                                }
blload_done:
      free(blh);
if (SWAP_ENDIAN) {
printf("FINISHED READING  BL HEADERS (endian-swapped)\n");
} else {
printf("FINISHED READING  BL HEADERS\n");
}

enh = (struct ant_def **) malloc(nsets[4]*sizeof( struct ant_def *));
  for (set=0;set<nsets[4];set++) {
    enh[set] = (struct ant_def *)malloc(sizeof(struct ant_def ));
    if (enh[set] == NULL ){
     printf("ERROR: Memory allocation for enh failed for %d bytes\n",
      nsets[4]*sizeof(struct ant_def));
      exit(-1);
    }
  }

smaEngdata = (struct smEng **) malloc(nsets[0]*sizeof( struct smEng *));
   for (set=0;set<nsets[0];set++) {
    smaEngdata[set] = (struct smEng *)malloc(sizeof(struct smEng ));
    if (smaEngdata[set] == NULL ){
     printf("ERROR: Memory allocation for smaEngdata failed for %d bytes\n",
      nsets[0]*sizeof(struct smEng));
      exit(-1);
    }
  }
for (set=0;set<nsets[4];set++) {
	*enh[set] = *(enh_read(fpin[4]));
        if (SWAP_ENDIAN) {
          	enh[set]=swap_enh(enh[set]);
                              }} 

/* store sma engineer data to smaEngdata */
inhset=0;
for (set=0;set<nsets[4];set++) {
        if(enh[set]->inhid!=inh[inhset]->inhid) inhset++;
        if(inhset<nsets[0]) {
        smaEngdata[inhset]->inhid=enh[set]->inhid;
        smaEngdata[inhset]->ints =enh[set]->ints;
        smaEngdata[inhset]->antpad_no[enh[set]->antennaNumber]
            =enh[set]->padNumber;
        smaEngdata[inhset]->antenna_no[enh[set]->antennaNumber]
            = enh[set]->antennaNumber;
        smaEngdata[inhset]->lst = enh[set]->lst;
        smaEngdata[inhset]->dhrs = enh[set]->dhrs;
        smaEngdata[inhset]->ha = enh[set]->ha;
        smaEngdata[inhset]->el[enh[set]->antennaNumber]
            = enh[set]->actual_el;
        smaEngdata[inhset]->az[enh[set]->antennaNumber]
            = enh[set]->actual_az;
        smaEngdata[inhset]->tsys[enh[set]->antennaNumber]
            = enh[set]->tsys;
        smaEngdata[inhset]->tamb[enh[set]->antennaNumber]
            = enh[set]->ambient_load_temperature;} 
}
if (SWAP_ENDIAN) {
printf("FINISHED READING  EN HEADERS (endian-swapped)\n");
} else {
printf("FINISHED READING  EN HEADERS\n");
  }
     free(enh);
       for (i=1; i < smabuffer.nants+1; i++) {
          antenna[i].x = 0.;
          antenna[i].y = 0.;
          antenna[i].z = 0.;
          antenna[i].x_phs = 0.;
          antenna[i].y_phs = 0.;
          antenna[i].z_phs = 0.;
          antenna[i].axisoff_x = 0.;
          antenna[i].axisoff_y = 0.;
          antenna[i].axisoff_z = 0.;
                        }
          sprintf(antenna[1].name, "AN%d", 1);
       for (i=1; i < smabuffer.nants+1; i++) {
        for (j=i+1; j < smabuffer.nants+1; j++) {
          antenna[j].x = blarray[i][j].ee - antenna[i].x;
          antenna[j].y = blarray[i][j].nn - antenna[i].y;
          antenna[j].z = blarray[i][j].uu - antenna[i].z;
          sprintf(antenna[j].name, "AN%d", j);
           }
          }

     printf("NUMBER OF ANTENNAS =%d\n", smabuffer.nants); 
     smabuffer.nants = 8;        
/* the positions of antennas need to check  */ 
/*   for (i=1; i < smabuffer.nants+1; i++) {
         printf("ANT x y z %s  %11.5f %11.5f %11.5f\n",antenna[i].name,
                      antenna[i].x,
                      antenna[i].y,
                      antenna[i].z); } 
*/
/* finished loading antennas */
/* write antenna dat to uv file */
      for (i=1; i < smabuffer.nants+1; i++) {
      r = sqrt(pow(antenna[i].x,2) + pow(antenna[i].y,2));
      cost = antenna[i].x / r;
      sint = antenna[i].y / r;
      z0 = antenna[i].z;
      tmp = (antenna[i].x)*cost + (antenna[i].y)*sint - r;
      antpos[i] = (1e9/DCMKS) * tmp;
      tmp = (-antenna[i].x)*sint + (antenna[i].y)*cost;
      antpos[i+smabuffer.nants] = (1e9/DCMKS) * tmp;
      antpos[i+2*smabuffer.nants] = (1e9/DCMKS)*(antenna[i].z-z0);
          }
        tno = smabuffer.tno;
          nnants = 3*smabuffer.nants;
            uvputvrd_c(tno,"antpos", antpos, nnants);


/* setup correlator */     
sph = (struct sph_def **) malloc(sphSizeBuffer*sizeof( struct sph_def *));
  for (set=0;set<sphSizeBuffer;set++) {
    sph[set] = (struct sph_def *)malloc(sizeof(struct sph_def ));
    if (sph[set] == NULL ){
 printf("ERROR: Memory allocation for sph failed for %d bytes\n",
                       sphSizeBuffer*sizeof(struct sph_def));
      exit(-1);
    }
  }

       for (set=0;set<sphSizeBuffer; set++) {
        *sph[set] = *(sph_read(fpin[2]));
         if (SWAP_ENDIAN) {
        sph[set] =  swap_sph(sph[set]);
                           }
  }
if (SWAP_ENDIAN) {
printf("FINISHED READING SP HEADERS (endian-swapped)\n");
} else {
printf("FINISHED READING SP HEADERS\n");
}
  rewind(fpin[5]);
  firstbsl = -1;
  lastbsl  = -1;
/* start from the 1st integration  inhset = 0; */
  inhset = 0;
  numberBaselines=  uvwbsln[inhset]->n_bls,

/* count sideband */
  smaCorr.no_sideband =1;

  for(i=1; i< numberBaselines;i++) 
  if(uvwbsln[inhset]->uvwID[i].isb !=uvwbsln[inhset]->uvwID[i+1].isb) 
      smaCorr.no_sideband =2;
      numberSidebands=smaCorr.no_sideband;

 smaCorr.no_rxif =1;
   for(i=1; i< numberBaselines;i++)
/*   printf("irec i= %d %d \n", uvwbsln[inhset]->uvwID[i].irec, i);
 */
   if(uvwbsln[inhset]->uvwID[i].irec !=uvwbsln[inhset]->uvwID[i+1].irec)
   smaCorr.no_rxif =2;
   numberRxif=smaCorr.no_rxif;

/* pick the 2th baseline to count number of spectra */
/*  blhset = 1; */
  blhset=1;
/* purse the receiver id */
 /* no receiver seperation */
  if(smabuffer.rxif==0) goto nextrx;
 /* find the specific receiver to load */
  for (i=blhset; i<numberBaselines; i++){
   rx_irec=uvwbsln[inhset]->uvwID[i].irec;
 /*  printf("smabuffer.rxif==rx_irec %d %d\n",smabuffer.rxif, rx_irec);
  */
  if(smabuffer.rxif==rx_irec)  {blhset=i; goto nextrx;}
   }
   printf("ERROR: there is no receiver %d in this data set.\n", smabuffer.rxif);
   exit(-1);
   nextrx:
  blhid = uvwbsln[inhset]->uvwID[blhset].blhid;
  firstsp = -1;
  lastsp  = -1;
  for (set=0;set<nsets[2];set++) { 
    if (firstsp == -1 && sph[set]->blhid == blhid) {
       firstsp = set;
    }
    if (firstsp  != -1 && sph[set]->blhid != blhid) {
       lastsp  = set - 1;
    }
    if (lastsp  != -1) break;
  }
  
  numberSpectra   = lastsp -firstsp +1;
/*  numberSpectra =3;*/
/* take out 1 for eliminating the continuum channel */
  smaCorr.n_chunk = numberSpectra -1;
/* count the number of channels in each spectrum */
/* the first one is the continuum channel */
switch(smabuffer.sb) {
case 0:
printf("LSB only\n");
  for(i=1;i<smaCorr.n_chunk+1;i++) {
     smaFreq[0].chunkBW[i]    = sph[i]->fres*sph[i+firstsp]->nch;
     smaFreq[0].chunkfreq[i]  = sph[i+firstsp]->fsky;
     smaFreq[0].chanWidth[i]  = sph[i+firstsp]->fres/1000.0;
     smaFreq[0].ref_chan[i]   = sph[i+firstsp]->nch/2;
     smaFreq[0].n_chunk_ch[i] = sph[i+firstsp]->nch;
     smaFreq[0].freqid        = -1;
     smaFreq[0].sideband_id   = 0;
     inhset=1; blhset         = 0;
     smaFreq[0].polarization[i] =
     uvwbsln[inhset]->uvwID[blhset].ipol;
  }
    break;
case 1:  
  printf("USB only\n");
  usbstart = numberBaselines*(1+smaCorr.n_chunk)/2;
  usbend = usbstart + 1+smaCorr.n_chunk;
 for(i=1; i<1+smaCorr.n_chunk; i++) {
     smaFreq[0].chunkBW[i]    = sph[i]->fres*sph[i+firstsp+usbstart]->nch;
     smaFreq[0].chunkfreq[i]  = sph[i+firstsp+usbstart]->fsky;
     smaFreq[0].chanWidth[i]  = sph[i+firstsp+usbstart]->fres/1000.0;
     smaFreq[0].ref_chan[i]   = sph[i+firstsp+usbstart]->nch/2;
     smaFreq[0].n_chunk_ch[i] = sph[i+firstsp+usbstart]->nch;
     smaFreq[0].freqid        = -1;
     smaFreq[0].sideband_id   = 1;
     inhset=1; blhset         = 0;
     smaFreq[0].polarization[i] =
     uvwbsln[inhset]->uvwID[blhset].ipol;
    }
}
/* setup source */
cdh = (struct codeh_def **) malloc(nsets[3]*sizeof( struct codeh_def *));
  for (set=0;set<nsets[3];set++) {
cdh[set] = (struct codeh_def *)malloc(sizeof(struct codeh_def ));
    if (cdh[set] == NULL ){
  printf("ERROR: Memory allocation for cdh failed for %d bytes.\n",
                        nsets[3]*sizeof(struct codeh_def));
      exit(-1);
    }
  }

  for (set=0;set<nsets[3];set++){
        *cdh[set] = *(cdh_read(fpin[3]));
         if (SWAP_ENDIAN) {
              cdh[set]=swap_cdh(cdh[set]);
                }
  }
if (SWAP_ENDIAN) {
printf("FINISHED READING  CD HEADERS (endian-swapped)\n");
}else {
printf("FINISHED READING  CD HEADERS\n");
}
sourceID = 0;
for (set=0;set<nsets[3];set++){
/* decode the sp id */
if((cdh[set]->v_name[0]=='b'&&cdh[set]->v_name[1]=='a')&&
                  cdh[set]->v_name[2]=='n'){
           spcode[cdh[set]->icode]=spdecode(&cdh[set]);
        }

/* decode the julian date for from the observing date */
     if((cdh[set]->v_name[0]=='r'&&cdh[set]->v_name[1]=='e')&&
                  cdh[set]->v_name[2]=='f'){
            jday = juliandate(&cdh[set]);      }
                              }
/* decode the source information */
for (set=0;set<nsets[3];set++){
         if(cdh[set]->v_name[0]=='s'&&cdh[set]->v_name[1]=='o') {
         sourceID++;
         sprintf(multisour[sourceID].name, "%s", cdh[set]->code);
         multisour[sourceID].sour_id = cdh[set]->icode;
/*         printf("cdh[set]->code=%s\n", cdh[set]->code);
*/
         inhset=0;
         while (inh[inhset]->souid!=multisour[sourceID].sour_id)
         inhset++;
/*         printf("inh[inhset]->rar to c %s\n", 
                (char *)rar2c(inh[inhset]->rar));
*/
         multisour[sourceID].ra = inh[inhset]->rar;
         multisour[sourceID].dec = inh[inhset]->decr;
         sprintf(multisour[sourceID].equinox, "%s", inh[inhset]->epoch);
         multisour[sourceID].freqid =-1;
/* calculate the apparent position coordinates from j2000 coordinates */
 { double obsra,obsdec,r1,d1;
  char jcode = 'J';
  double julian2000=2451544.5;
/*  precess(epo2jul(2000.0, &jcode), */
         precess(julian2000,
         multisour[sourceID].ra,
         multisour[sourceID].dec, jday, &obsra, &obsdec);
         nutate(jday,obsra,obsdec,&r1,&d1);
         aberrate(jday,r1,d1,&obsra,&obsdec);
         multisour[sourceID].ra_app = obsra;
         multisour[sourceID].dec_app = obsdec;
} 
         multisour[sourceID].qual=0;
         multisour[sourceID].pmra = 0.;
         multisour[sourceID].pmdec = 0.;
         multisour[sourceID].parallax=0.;
         strcpy(multisour[sourceID].veltyp, "lsr");
         strcpy(multisour[sourceID].veldef, "radio");
       for (i=1; i<smaCorr.n_chunk+1; i++) {
         multisour[sourceID].restfreq[i]= sph[i+firstsp]->rfreq;
         multisour[sourceID].sysvel[i] = sph[i+firstsp]->vel;
  }
}}
       
    for (i=1; i< sourceID+1; i++) {
    printf("source: %-21s id=%2d RA=%13s ", 
    multisour[i].name,
    multisour[i].sour_id, 
    (char *)rar2c(multisour[i].ra));
    printf("DEC=% 13s\n", (char *)decr2c(multisour[i].dec));
           }

/* now loading the smabuffer */
for (i=1; i<smabuffer.nants+1; i++){
       smabuffer.tsys[i-1]=0;
        }   
   smabuffer.newfreq =1;
   for(i=1;i<smaCorr.n_chunk+1; i++) {
   smabuffer.sfreq[spcode[i]-1] = smaFreq[0].chunkfreq[i];
   smabuffer.sdf[spcode[i]-1] = smaFreq[0].chanWidth[i]
         *smaFreq[0].n_chunk_ch[i]/smabuffer.rsnchan;
   smabuffer.restfreq[spcode[i]-1] = multisour[sourceID].restfreq[i];
/*   smabuffer.nfreq[spcode[i]-1] = smaFreq[0].n_chunk_ch[i];*/
     smabuffer.nfreq[spcode[i]-1] = smabuffer.rsnchan;
   smabuffer.bchan[spcode[i]-1]=1;
   smabuffer.nstoke[spcode[i]-1]=4;
   smabuffer.edge[spcode[i]-1]=0;
   smabuffer.nbin[spcode[i]-1]=1;
     }
   
  for(j=1;j<smaCorr.n_chunk+1;j++) {
  for(i=1; i<smabuffer.nstoke[j-1]; i++) {
  for (k=1; k<SMBAS+1; k++) {
     smabuffer.polcode[j-1][i-1][k-1] = 0;
     }
                                      }
                                    }

  for(j=1;j<smabuffer.nants+1;j++) {
  for(i=1;i<smaCorr.n_chunk+1;i++) {
  smabuffer.xtsys[i-1][j-1]=0.;
  smabuffer.ytsys[i-1][j-1]=0.;
  smabuffer.xyphase[i-1][j-1]=0.;
  smabuffer.xyamp[i-1][j-1]=1.;
      }}

  for(k=0; k<3; k++) {
  for(j=1;j<smabuffer.nants+1;j++) {
  for(i=1;i<smaCorr.n_chunk+1;i++) {
  smabuffer.xsampler[i-1][j-1][k]=0.;
  smabuffer.ysampler[i-1][j-1][k]=0.;
      }}}
  
smabuffer.nifs = smaCorr.n_chunk;
 
/* initialize pnt flags */
   for (i=1; i<SMIF+1; i++)  {
   for (j=1; j<SMPOL+1; j++) {
   for (k=1; k<SMBAS+1; k++) {
   for (l=1; l<3; l++) { /* 2 sb */
        smabuffer.flag[i-1][j-1][k-1][l-1]=-1;
        smabuffer.pnt[i-1][j-1][k-1][l-1]=0;
                             }}}}

  smabuffer.nused=0;
    free(cdh);
    free(sph);
    rewind(fpin[3]);
    rewind(fpin[2]);
/*break;
case 0:
visread:*/
rewind(fpin[5]);
sch = (struct sch_def **) malloc(nsets[0]*sizeof( struct sch_def *));
  for (set=0; set<nsets[0];set++) {
    sch[set] = (struct sch_def *)malloc(sizeof(struct sch_def ));
    if (sch[set] == NULL ){
 printf("ERROR: Memory allocation for sch failed for %d bytes\n",
                        nsets[0]*sizeof(struct sch_def));
      exit(-1);
    }
  }


/* Need an array to hold the starting byte for each integration of data */
  data_start_pos = (long int*)malloc(nsets[0]*sizeof(long int));
inhset=0;
for (set=inhset;set<nsets[0]-1;set++) {
        data_start_pos[set] = ftell(fpin[5]);
           *sch[set] = *(sch_head_read(fpin[5]));
        if (SWAP_ENDIAN) {
                sch[set]=swap_sch(sch[set]);
                              }
i = fseek(fpin[5],(long int)sch[set]->nbyt,SEEK_CUR);
}
/* rewind vis data file */
rewind(fpin[5]);  
/* initilize the handles for baseline, spectral, integration */
blhset  = -1;
sphset  = 0;
readSet=1;
numberBaselines = uvwbsln[0]->n_bls;
/* numberBaselines = 2;*/
printf("#Baselines=%d #Spectra=%d  #Sidebands=%d #Receivers=%d\n",
          numberBaselines/2, numberSpectra-1, numberSidebands, 
          numberRxif);
sphSizeBuffer= numberSpectra; /* numberBaselines for usb and lsb */
firstsp=sphset;
firstbsl=blhset;
printf("start to read vis data!!!\n");
/* initialize vis point handle */
ipnt=1;
if(smabuffer.scanskip!=0) inhset=smabuffer.scanskip-1;
if(smabuffer.scanproc!=0&&(nsets[0]>(smabuffer.scanskip+smabuffer.scanproc)))
nsets[0]=smabuffer.scanskip+smabuffer.scanproc;
while(inhset<(nsets[0]-1)) {
/* inhset=inh[inhset+1]->ints;*/
inhset++;

visSMAscan.blockID.ints = inh[inhset]->ints;
visSMAscan.blockID.inhid = inh[inhset]->inhid;
visSMAscan.blockID.sourID = inh[inhset]->souid;
visSMAscan.blockID.freqID = smaFreq[0].freqid;
visSMAscan.time.UTCtime = jday+inh[inhset]->dhrs/24.000; /*hrs*/
/* loading smabuffer */
smabuffer.currentscan=inhset-smabuffer.scanskip;
smabuffer.time = visSMAscan.time.UTCtime;
if(inh[inhset]->inhid!=smaEngdata[inhset]->inhid) 
bug_c("e", "LST in the engineer data may corrupted!\n");
if(inh[inhset]->inhid==smaEngdata[inhset]->inhid) 
{ smabuffer.lst = smaEngdata[inhset]->lst*DPI/12.0;
   /* in unit of hr in mir format; in unit of radian in miriad format */
  for (i=0; i<smabuffer.nants; i++) {
       smabuffer.el[i] = smaEngdata[inhset]->el[i+1];
       smabuffer.az[i] = smaEngdata[inhset]->az[i+1];
       smabuffer.tsys[i] = smaEngdata[inhset]->tsys[i+1];
                                    }
}
/* handle source information */
sourceID = visSMAscan.blockID.sourID;
smabuffer.obsra = multisour[sourceID].ra_app;
smabuffer.obsdec = multisour[sourceID].dec_app;
smabuffer.ra = multisour[sourceID].ra;
smabuffer.dec = multisour[sourceID].dec;


/* write source to uvfile */
if((strncmp(multisour[sourceID].name,target,6)!=0)&&
   (strncmp(multisour[sourceID].name,unknown,7)!=0)) {
uvputvra_c(tno,"source",multisour[sourceID].name);
uvputvrd_c(tno,"ra",&(smabuffer.ra),1);
uvputvrd_c(tno,"dec",&(smabuffer.dec),1);
/* store the true pointing position */
rar = inh[inhset]->rar;
if (rar!=smabuffer.ra) 
     uvputvrd_c(tno,"pntra", &rar, 1);
decr = inh[inhset]->decr;
if (decr!=smabuffer.dec)
     uvputvrd_c(tno,"pntdec",&decr,1);
uvputvrd_c(tno,"obsra",&(smabuffer.obsra),1);
uvputvrd_c(tno,"obsdec",&(smabuffer.obsdec),1);
uvputvri_c(tno,"calcode",&(multisour[sourceID].calcode),1);
uvputvri_c(tno,"sourid", &sourceID, 1);
}

sblpnt=0;
for(j=0; j < numberBaselines; j++){
if(smabuffer.rxif==uvwbsln[inhset]->uvwID[j].irec||smabuffer.rxif==0) {

sblpnt=j;
blhset++;
visSMAscan.uvblnID = uvwbsln[inhset]->uvwID[j].blcode; 
visSMAscan.blockID.sbid = uvwbsln[inhset]->uvwID[j].isb;
visSMAscan.blockID.polid = uvwbsln[inhset]->uvwID[j].ipol;
sbpnt = visSMAscan.blockID.sbid;
switch(sbpnt) {
case 0: blpnt=sblpnt;
        phaseSign=-1;
        break;
case 1: blpnt=sblpnt - numberBaselines/2;
        phaseSign=1;
        break;
              }
if(smabuffer.nopol==1) visSMAscan.blockID.polid=-5;
switch(visSMAscan.blockID.polid)  {
case  0: polpnt=0; break;
case -1: polpnt=1; break;
case -2: polpnt=2; break;
case -3: polpnt=3; break;
case -4: polpnt=4; break;
case -5: polpnt=1; break;
case -6: polpnt=2; break;
case -7: polpnt=3; break;
case -8: polpnt=4; break; }
/* loading smabuffer uvw*/
/* Miriad using nsec */
smabuffer.u[blpnt] = uvwbsln[inhset]->uvwID[j].u/smabuffer.sfreq[1]*1000.;
smabuffer.v[blpnt] = uvwbsln[inhset]->uvwID[j].v/smabuffer.sfreq[1]*1000.;
smabuffer.w[blpnt] = uvwbsln[inhset]->uvwID[j].w/smabuffer.sfreq[1]*1000.;
smabuffer.blcode[blpnt] = visSMAscan.uvblnID;

/* read sph for a complete spectral records assuming that the correlator
configuration is not changed during the observation */
if(readSet<= 1&&j==0) { 
free(sph);
sph = (struct sph_def **) malloc(sphSizeBuffer*sizeof( struct sph_def *));
  for (set=0; set < sphSizeBuffer; set++) {
    sph[set] = (struct sph_def *)malloc(sizeof(struct sph_def ));
    if (sph[set] == NULL ){
 printf("ERROR: Memory allocation for sph failed for %d bytes\n",
                       sphSizeBuffer*sizeof(struct sph_def));
      exit(-1);
    }
  }
for (set=0; set< sphSizeBuffer; set++) {
        *sph[set] = *(sph_read(fpin[2]));
         if (SWAP_ENDIAN) {
        sph[set] =  swap_sph(sph[set]);
  }
}

}
/* The data for this spectrum consists of a 5 short int record header 
   and the data  which is a short for each real and a short for 
   each imag vis */
   datalength = 5 + 2*sph[0]->nch;
/* Get some memory to hold the data */
   shortdata = (short int* )malloc(datalength*sizeof(short int));
/* Here is the starting byte for the data for this spectrum */
/* The 16 is to skip over the data integration header which precedes 
   all the records. We already read this data integration header 
   with sch_head_read  */
   bytepos = 16 + data_start_pos[inhset] + sph[0]->dataoff ; 
   bytepos = bytepos * (sblpnt+1);
/* Move to this position in the file and read the data */
  if(j<1) fseek(fpin[5],bytepos,SEEK_SET);
  nbytes = sch_data_read(fpin[5],datalength,shortdata);
      if (SWAP_ENDIAN) {
                shortdata=swap_sch_data(shortdata, datalength);
                              }
/* take a look at the record header */
/* intTime in sec */
    visSMAscan.time.intTime = (double) (shortdata[0]/10.);
/* loading smabuffer intTime */
    smabuffer.inttime[j]= visSMAscan.time.intTime;
    smabuffer.inttim = visSMAscan.time.intTime;
/* There is a different scale factor for each record (spectrum) */
    scale = shortdata[4];
/* Now the data There is only one channel for the continuum*/
   visSMAscan.bsline.continuum.real = pow(2.,(double)scale)*shortdata[5];
   visSMAscan.bsline.continuum.imag = pow(2.,(double)scale)*shortdata[6];
    free(shortdata);
    sphset++;  
/* The file is positioned at the record header for the next spectrum. */
/* There is no 16 byte integration header between records */
/* numberSpectra */
ifpnt=0;
   for (kk=1;kk<numberSpectra; kk++) {
/*ifpnt=kk-1;*/
  ifpnt = spcode[kk]-1;
   datalength = 5 + 2*sph[kk]->nch;
/* 5 short in header of each spectral visibility data */
/* 2 shorts for real amd imaginary */
/* sph[sphset]->nch number of channel in each spectral set*/
/* Get some memory to hold the data */
/* memory size = datalength*sizeof(short)) */
   shortdata = (short int* )malloc(datalength*sizeof(short int));
   nbytes = sch_data_read(fpin[5],datalength,shortdata);
 if (SWAP_ENDIAN) {
                shortdata=swap_sch_data(shortdata, datalength);
                              }
/* There is a different scale factor for each record (spectrum) */
   scale = shortdata[4];
/* update polcode and pnt to smabuffer  */
smabuffer.polcode[ifpnt][polpnt][blpnt]=visSMAscan.blockID.polid;
/* smabuffer.pnt[ifpnt][polpnt][blpnt][0] = ipnt;*/
smabuffer.pnt[ifpnt][polpnt][blpnt][sbpnt] = ipnt;
/* Now the channel data.  */
/* Make pseudo continuum */
avenchan = 0;
avereal  = 0.;
aveimag  = 0.;

for(i=0;i<sph[kk]->nch;i++){
if(avenchan< (sph[kk]->nch/smabuffer.rsnchan) ) {
avereal = avereal + (float)pow(2.,(double)scale)*shortdata[5+2*i];
aveimag = aveimag + (float)pow(2.,(double)scale)*shortdata[6+2*i];
avenchan++;
/*printf("avenchan=%d\n", avenchan);*/
} else {
avereal = avereal/avenchan;
aveimag = aveimag/avenchan;
smabuffer.data[ipnt].real=avereal;
smabuffer.data[ipnt].imag=aveimag;
ipnt++;
avenchan = 1;
avereal  = (float)pow(2.,(double)scale)*shortdata[5+2*i];
aveimag  = (float)pow(2.,(double)scale)*shortdata[6+2*i];
}}

/*smabuffer.data[ipnt].real=(float)pow(2.,(double)scale)*shortdata[5+2*i];
smabuffer.data[ipnt].imag=(float)pow(2.,(double)scale)*shortdata[6+2*i];
ipnt++;    }*/
    free(shortdata);
    sphset++;  /* count for each spectral chunk */
           }
firstsp = sphset;
        }
  }
if (fmod((readSet-1), 100.)<0.5)
printf("set=%4d ints=%4d inhid=%4d time(JulianDay)=%9.5f int=% 4.1f \n",
readSet,
visSMAscan.blockID.ints,
visSMAscan.blockID.inhid,
visSMAscan.time.UTCtime,
visSMAscan.time.intTime);
       readSet++;
       smabuffer.nused=ipnt;
/* re-initialize vis point for next integration */
       ipnt=1;
/* call rspokeflshsma_c to store databuffer to uvfile */
       kstat = -1;
       *kst = (char *)&kstat;
        if((strncmp(multisour[sourceID].name,target,6)!=0)&&
           (strncmp(multisour[sourceID].name,unknown,7)!=0)) {
       rspokeflshsma_c(kst);
         }else {
          ntarget++;}
}
printf("set=%4d ints=%4d inhid=%4d time(JulianDay)=%9.5f int=% 4.1f \n",
readSet-1, 
visSMAscan.blockID.ints,
visSMAscan.blockID.inhid,
visSMAscan.time.UTCtime,
visSMAscan.time.intTime);
printf("skipped %d integration scans on `target&unknown'\n",ntarget);
printf("converted the original correlator configuration\n");
printf("to low resolution configuration:\n");
avenchan=smabuffer.rsnchan;
for (kk=1; kk<numberSpectra; kk++) {
printf("  s%02d     %3d  =>  %2d\n",kk, sph[kk]->nch, avenchan);
         }                            
printf("done with data conversion from mir to miriad!\n");
}
/* ---------------------------------------------------------------------- */
endTime = time(NULL);
trueTime = difftime(endTime, startTime);
if(jstat==0) fprintf(stderr,
  "Real time used =%f sec.\n",
        trueTime);
jstat=0;
return(jstat);
} /* end of main */

