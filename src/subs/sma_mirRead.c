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
/* 2004-12-10 rename header file for miriad 4.0.4 - pjt */
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
int mir_Read();

unsigned long mfsize(FILE *);
struct inh_int_def {
	int  a[512];
};
void pokeinisma_c();
void pokeflshsma_c();
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
void mirread_c(char *datapath, char *jst[])
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
        jstat = mir_Read(pathname,jstat);
        *jst = (char *)jstat; 
   return;
}

void miriadwrite_c(char *datapath, char *jst[])
{ extern char pathname[];
  int jstat,kstat;
  int tno;
  extern smlodd smabuffer;
      tno = smabuffer.tno;
     jstat=-1;
/* open mir files */
     jstat = mir_Read(pathname,jstat);
        *jst = (char *)jstat;
/* then start to read and write data if the files are ok. */
     if (jstat==0) {jstat=0;
         jstat = mir_Read(pathname,jstat);}
         else {
         printf("file problem\n");
            }
      
     return;
}

void smaflush_c(mflag,scinit,tcorr,scbuf,xflag,yflag,maxif,maxant,scanskip,scanproc, sb, rxif)
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
      pokeflshsma_c((char *)&(kstat)); 
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
    
void pokeinisma_c(char *kst[], int tno1, int *dosam1, int *doxyp1,
  int *doop1, int *dohann1, int *birdie1, int *dowt1, int *dopmps1,
  int *dobary1, int *doif1, int *hires1, int *nopol1, int *oldpol1, 
  double lat1, double long1)
{ /* pokeflshsma_c == pokeflsh */
    int buffer;
    extern char sname[];
    extern smlodd smabuffer;
    
  /* initialize the external buffers */   
   strcpy(sname, " ");
        smabuffer.tno    = tno1;
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

void pokeflshsma_c(char *kst[])
{ /* pokeflshsma_c== pokeflsh */
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
     struct pols *cntstokes();
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
       polcnt = cntstokes(npol, bl, sb);
       npol = polcnt->npol;
          if(npol>0) {
            uvputvri_c(tno,"npol",&npol,1);
            for(p=polcnt->polstart; p<polcnt->polend+1; p++){
    nchan = getdata(&vis,&flags,&nchan, p, bl, sb);
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

int getdata(smavis, smaflags, smanchan, p, bl, sb)
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

struct pols *cntstokes(int npol, int bl, int sb)
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
              
int mir_Read(char *datapath,
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
char unknown[7];
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

/*   printf("blhset=%d\n", blhset);
   printf("blhid =%d\n", blhid);
   printf("RXIF=%d\n", smabuffer.rxif);
*/
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
} else {
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
   smabuffer.sdf[spcode[i]-1] = smaFreq[0].chanWidth[i];
   smabuffer.restfreq[spcode[i]-1] = multisour[sourceID].restfreq[i];
   smabuffer.nfreq[spcode[i]-1] = smaFreq[0].n_chunk_ch[i];
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
      numberBaselines/2, numberSpectra-1, numberSidebands, numberRxif);
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
   (strncmp(multisour[sourceID].name,unknown,7)!=0) ){
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
/*printf("smabuffer.rxif=%d uvwbsln[inhset]->uvwID[j].irec= %d inhset=%d j=%d\n",
       smabuffer.rxif, uvwbsln[inhset]->uvwID[j].irec, inhset, j);
*/
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
for(i=0;i<sph[kk]->nch;i++){
smabuffer.data[ipnt].real=(float)pow(2.,(double)scale)*shortdata[5+2*i];
smabuffer.data[ipnt].imag=(float)pow(2.,(double)scale)*shortdata[6+2*i];
ipnt++;    }
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
/* call pokeflshsma_c to store databuffer to uvfile */
       kstat = -1;
       *kst = (char *)&kstat;
        if((strncmp(multisour[sourceID].name,target,6)!=0)&&
           (strncmp(multisour[sourceID].name,unknown,7)!=0)) {
       pokeflshsma_c(kst);
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
printf("done with data conversion from mir to miriad!\n");
}
/* ---------------------------------------------------------------------- */
endTime = time(NULL);
trueTime = difftime(endTime, startTime);
/*if(jstat==0) fprintf(stderr,
  "Real time used =%f sec.\n",
        trueTime);
*/
jstat=0;
return(jstat);
} /* end of main */

/* This function reads the integration header */
struct inh_def *inh_read(FILE * fpinh)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */

  struct inh_def inh;
  struct inh_def *inhptr;
 
        nbytes = 0;
        nobj = 0;

/* read first data in set and check for end of file */
 
        nobj += fread(&inh.conid,sizeof(inh.conid),1,fpinh);
        if (nobj == 0) {
          printf("Unexpected end of file in_read\n");
          exit(-1);
        }
        nbytes += sizeof(inh.conid);
        nobj += fread(&inh.icocd,sizeof(inh.icocd),1,fpinh);
        nbytes += sizeof(inh.icocd);
        nobj += fread(&inh.traid,sizeof(inh.traid),1,fpinh);
        nbytes += sizeof(inh.traid);
        nobj += fread(&inh.inhid,sizeof(inh.inhid),1,fpinh);
        nbytes += sizeof(inh.inhid);
        nobj += fread(&inh.ints,sizeof(inh.ints),1,fpinh);
        nbytes += sizeof(inh.ints);
        nobj += fread(&inh.itq,sizeof(inh.itq),1,fpinh);
        nbytes += sizeof(inh.itq);
        nobj += fread(&inh.az,sizeof(inh.az),1,fpinh);
        nbytes += sizeof(inh.az);
        nobj += fread(&inh.el,sizeof(inh.el),1,fpinh);
        nbytes += sizeof(inh.el);
        nobj += fread(&inh.ha,sizeof(inh.ha),1,fpinh);
        nbytes += sizeof(inh.ha);
        nobj += fread(&inh.iut,sizeof(inh.iut),1,fpinh);
        nbytes += sizeof(inh.iut);
        nobj += fread(&inh.iref_time,sizeof(inh.iref_time),1,fpinh);
        nbytes += sizeof(inh.iref_time);
        nobj += fread(&inh.dhrs,sizeof(inh.dhrs),1,fpinh);
        nbytes += sizeof(inh.dhrs);
        nobj += fread(&inh.vc,sizeof(inh.vc),1,fpinh);
        nbytes += sizeof(inh.vc);
        nobj += fread(&inh.ivctype,sizeof(inh.ivctype),1,fpinh);
        nbytes += sizeof(inh.ivctype);
        nobj += fread(&inh.sx,sizeof(inh.sx),1,fpinh);
        nbytes += sizeof(inh.sx);
        nobj += fread(&inh.sy,sizeof(inh.sy),1,fpinh);
        nbytes += sizeof(inh.sy);
        nobj += fread(&inh.sz,sizeof(inh.sz),1,fpinh);
        nbytes += sizeof(inh.sz);
        nobj += fread(&inh.rinteg,sizeof(inh.rinteg),1,fpinh);
        nbytes += sizeof(inh.rinteg);
        nobj += fread(&inh.proid,sizeof(inh.proid),1,fpinh);
        nbytes += sizeof(inh.proid);
        nobj += fread(&inh.souid,sizeof(inh.souid),1,fpinh);
        nbytes += sizeof(inh.souid);
        nobj += fread(&inh.isource,sizeof(inh.isource),1,fpinh);
        nbytes += sizeof(inh.isource);
        nobj += fread(&inh.ipos,sizeof(inh.ipos),1,fpinh);
        nbytes += sizeof(inh.ipos);
        nobj += fread(&inh.offx,sizeof(inh.offx),1,fpinh);
        nbytes += sizeof(inh.offx);
        nobj += fread(&inh.offy,sizeof(inh.offy),1,fpinh);
        nbytes += sizeof(inh.offy);
        nobj += fread(&inh.iofftype,sizeof(inh.iofftype),1,fpinh);
        nbytes += sizeof(inh.iofftype);
        nobj += fread(&inh.ira,sizeof(inh.ira),1,fpinh);
        nbytes += sizeof(inh.ira);
        nobj += fread(&inh.idec,sizeof(inh.idec),1,fpinh);
        nbytes += sizeof(inh.idec);
        nobj += fread(&inh.rar,sizeof(inh.rar),1,fpinh);
        nbytes += sizeof(inh.rar);
        nobj += fread(&inh.decr,sizeof(inh.decr),1,fpinh);
        nbytes += sizeof(inh.decr);
        nobj += fread(&inh.epoch,sizeof(inh.epoch),1,fpinh);
        nbytes += sizeof(inh.epoch);
        nobj += fread(&inh.sflux,sizeof(inh.sflux),1,fpinh);
        nbytes += sizeof(inh.sflux);
        nobj += fread(&inh.size,sizeof(inh.size),1,fpinh);
        nbytes += sizeof(inh.size);
        inhptr = &inh;
        return inhptr;
 
} /* end of function inh_read */


/* This function reads one baseline header */
struct blh_def *blh_read(FILE * fpblh)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */
  struct blh_def blh;
  struct blh_def *blhptr;
 
        nbytes = 0;
        nobj = 0;
 
 
        nobj += fread(&blh.blhid,sizeof(blh.blhid),1,fpblh);
        if (nobj == 0) {
          printf("Unexpected end of file bl_read\n");
          exit(-1);
        }
        nbytes += sizeof(blh.blhid);
        nobj += fread(&blh.inhid,sizeof(blh.inhid),1,fpblh);
        nbytes += sizeof(blh.inhid);
        nobj += fread(&blh.isb,sizeof(blh.isb),1,fpblh);
        nbytes += sizeof(blh.isb);
        nobj += fread(&blh.ipol,sizeof(blh.ipol),1,fpblh);
        nbytes += sizeof(blh.ipol);
        nobj += fread(&blh.pa,sizeof(blh.pa),1,fpblh);
        nbytes += sizeof(blh.pa);
        nobj += fread(&blh.iaq,sizeof(blh.iaq),1,fpblh);
        nbytes += sizeof(blh.iaq);
        nobj += fread(&blh.ibq,sizeof(blh.ibq),1,fpblh);
        nbytes += sizeof(blh.ibq);
        nobj += fread(&blh.icq,sizeof(blh.icq),1,fpblh);
        nbytes += sizeof(blh.icq);
        nobj += fread(&blh.ioq,sizeof(blh.ioq),1,fpblh);
        nbytes += sizeof(blh.ioq);
        nobj += fread(&blh.irec,sizeof(blh.irec),1,fpblh);
        nbytes += sizeof(blh.irec);
        nobj += fread(&blh.iifc,sizeof(blh.iifc),1,fpblh);
        nbytes += sizeof(blh.iifc);
        nobj += fread(&blh.u,sizeof(blh.u),1,fpblh);
        nbytes += sizeof(blh.u);
        nobj += fread(&blh.v,sizeof(blh.v),1,fpblh);
        nbytes += sizeof(blh.v);
        nobj += fread(&blh.w,sizeof(blh.w),1,fpblh);
        nbytes += sizeof(blh.w);
        nobj += fread(&blh.prbl,sizeof(blh.prbl),1,fpblh);
        nbytes += sizeof(blh.prbl);
        nobj += fread(&blh.angres,sizeof(blh.angres),1,fpblh);
        nbytes += sizeof(blh.angres);
        nobj += fread(&blh.vis,sizeof(blh.vis),1,fpblh);
        nbytes += sizeof(blh.vis);
        nobj += fread(&blh.coh,sizeof(blh.coh),1,fpblh);
        nbytes += sizeof(blh.coh);
        nobj += fread(&blh.sigcoh,sizeof(blh.sigcoh),1,fpblh);
        nbytes += sizeof(blh.sigcoh);
        nobj += fread(&blh.csnr,sizeof(blh.csnr),1,fpblh);
        nbytes += sizeof(blh.csnr);
        nobj += fread(&blh.vflux,sizeof(blh.vflux),1,fpblh);
        nbytes += sizeof(blh.vflux);
        nobj += fread(&blh.cnoise,sizeof(blh.cnoise),1,fpblh);
        nbytes += sizeof(blh.cnoise);
        nobj += fread(&blh.avedhrs,sizeof(blh.avedhrs),1,fpblh);
        nbytes += sizeof(blh.avedhrs);
        nobj += fread(&blh.ampave,sizeof(blh.ampave),1,fpblh);
        nbytes += sizeof(blh.ampave);
        nobj += fread(&blh.phaave,sizeof(blh.phaave),1,fpblh);
        nbytes += sizeof(blh.phaave);
        nobj += fread(&blh.tpvar,sizeof(blh.tpvar),1,fpblh);
        nbytes += sizeof(blh.tpvar);
        nobj += fread(&blh.blsid,sizeof(blh.blsid),1,fpblh);
        nbytes += sizeof(blh.blsid);
        nobj += fread(&blh.itel1,sizeof(blh.itel1),1,fpblh);
        nbytes += sizeof(blh.itel1);
        nobj += fread(&blh.itel2,sizeof(blh.itel2),1,fpblh);
        nbytes += sizeof(blh.itel2);
        nobj += fread(&blh.iblcd,sizeof(blh.iblcd),1,fpblh);
        nbytes += sizeof(blh.iblcd);
        nobj += fread(&blh.ble,sizeof(blh.ble),1,fpblh);
        nbytes += sizeof(blh.ble);
        nobj += fread(&blh.bln,sizeof(blh.bln),1,fpblh);
        nbytes += sizeof(blh.bln);
        nobj += fread(&blh.blu,sizeof(blh.blu),1,fpblh);
        nbytes += sizeof(blh.blu);
        nobj += fread(&blh.soid,sizeof(blh.soid),1,fpblh);
        nbytes += sizeof(blh.soid);
        blhptr = &blh;
        return blhptr;
 
} /* end of blh_read  */


unsigned long mfsize(FILE *fp)
{
    /* Optimization stuff */
    char temp[BUFSIZ];
    static const long DATALENGTH_MAX=LONG_MAX%2!=0?LONG_MAX-1:LONG_MAX;
    long datalength=DATALENGTH_MAX;

    unsigned long i, counter, fsize;
    fsize = 0;

    if (fp==NULL)
    {
     printf("null pointer\n");
     return (unsigned)NULL;
    }

/* fseek() doesn't signal EOF so i use fread() to detect the end of file */
for (fseek(fp, datalength-1, SEEK_SET); 
    datalength>0 && fread(temp, 1, 1, fp)==0; 
       fseek(fp, datalength-1, SEEK_SET)) datalength/=128;

    fseek(fp, 0, SEEK_SET);
	
    if (datalength==0 && fread(temp, 1, 1, fp)==0)
    {
        return fsize;
    }

    else if (datalength==0)
           datalength=BUFSIZ;

    fseek(fp, datalength-1, SEEK_SET);
    /* fseek() doesn't signal EOF so i use fread() to detect the end of file */
    for(counter=0; fread(temp, 1, 1, fp)!=0; ++counter)
    	fseek(fp, datalength-1, SEEK_CUR);

    fseek(fp, 0, SEEK_SET);

    for( ; counter>0; --counter)
    {
        fseek(fp, datalength, SEEK_CUR);
        fsize += datalength;

    }

    do
    {
        fsize += datalength=fread(temp, 1, BUFSIZ, fp);

    }while(datalength!=0);

    fseek(fp, 0, SEEK_SET);

    return fsize;
}


struct sph_def *sph_read(FILE * fpsph)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */
 
  struct sph_def sph;
  struct sph_def *sphptr; 
        nbytes = 0;
        nobj = 0;
 
        nobj += fread(&sph.sphid,sizeof(sph.sphid),1,fpsph);
        if (nobj == 0) {
          printf("Unexpected end of file sp_read\n");
          exit(-1);
        }
        nbytes += sizeof(sph.sphid);
        nobj += fread(&sph.blhid,sizeof(sph.blhid),1,fpsph);
        nbytes += sizeof(sph.blhid);
        nobj += fread(&sph.inhid,sizeof(sph.inhid),1,fpsph);
        nbytes += sizeof(sph.inhid);
        nobj += fread(&sph.igq,sizeof(sph.igq),1,fpsph);
        nbytes += sizeof(sph.igq);
        nobj += fread(&sph.ipq,sizeof(sph.ipq),1,fpsph);
        nbytes += sizeof(sph.ipq);
        nobj += fread(&sph.iband,sizeof(sph.iband),1,fpsph);
        nbytes += sizeof(sph.iband);
        nobj += fread(&sph.ipstate,sizeof(sph.ipstate),1,fpsph);
        nbytes += sizeof(sph.ipstate);
        nobj += fread(&sph.tau0,sizeof(sph.tau0),1,fpsph);
        nbytes += sizeof(sph.tau0);
        nobj += fread(&sph.vel,sizeof(sph.vel),1,fpsph);
        nbytes += sizeof(sph.vel);
        nobj += fread(&sph.vres,sizeof(sph.vres),1,fpsph);
        nbytes += sizeof(sph.vres);
        nobj += fread(&sph.ivtype,sizeof(sph.ivtype),1,fpsph);
        nbytes += sizeof(sph.ivtype);
        nobj += fread(&sph.fsky,sizeof(sph.fsky),1,fpsph);
        nbytes += sizeof(sph.fsky);
        nobj += fread(&sph.fres,sizeof(sph.fres),1,fpsph);
        nbytes += sizeof(sph.fres);
        nobj += fread(&sph.tssb,sizeof(sph.tssb),1,fpsph);
        nbytes += sizeof(sph.tssb);
        nobj += fread(&sph.integ,sizeof(sph.integ),1,fpsph);
        nbytes += sizeof(sph.integ);
        nobj += fread(&sph.wt,sizeof(sph.wt),1,fpsph);
        nbytes += sizeof(sph.wt); 
        nobj += fread(&sph.itaper,sizeof(sph.itaper),1,fpsph);
        nbytes += sizeof(sph.itaper);
        nobj += fread(&sph.snoise,sizeof(sph.snoise),1,fpsph);
        nbytes += sizeof(sph.snoise);
        nobj += fread(&sph.nch,sizeof(sph.nch),1,fpsph);
        nbytes += sizeof(sph.nch);
        nobj += fread(&sph.nrec,sizeof(sph.nrec),1,fpsph);
        nbytes += sizeof(sph.nrec);
        nobj += fread(&sph.dataoff,sizeof(sph.dataoff),1,fpsph);
        nbytes += sizeof(sph.dataoff);
        nobj += fread(&sph.linid,sizeof(sph.linid),1,fpsph);
        nbytes += sizeof(sph.linid);
        nobj += fread(&sph.itrans,sizeof(sph.itrans),1,fpsph);
        nbytes += sizeof(sph.itrans);
        nobj += fread(&sph.rfreq,sizeof(sph.rfreq),1,fpsph);
        nbytes += sizeof(sph.rfreq);
        nobj += fread(&sph.pasid,sizeof(sph.pasid),1,fpsph);
        nbytes += sizeof(sph.pasid);
        nobj += fread(&sph.gaiidamp,sizeof(sph.gaiidamp),1,fpsph);
        nbytes += sizeof(sph.gaiidamp);
        nobj += fread(&sph.gaiidpha,sizeof(sph.gaiidpha),1,fpsph);
        nbytes += sizeof(sph.gaiidpha);
        nobj += fread(&sph.flcid,sizeof(sph.flcid),1,fpsph);
        nbytes += sizeof(sph.flcid);
        nobj += fread(&sph.atmid,sizeof(sph.atmid),1,fpsph);
        nbytes += sizeof(sph.atmid);
         sphptr = &sph;
        return sphptr;
 
} /* end of sph_write */

/* This function reads  the code or strings header */
struct codeh_def * cdh_read (FILE * fpcodeh)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */
 
  struct codeh_def codeh;
  struct codeh_def *codehptr;
        nbytes = 0;
        nobj = 0;
        nobj += fread(codeh.v_name,sizeof(codeh.v_name),1,fpcodeh);
        if (nobj == 0) {
          printf("Unexpected end of file cdh_read\n");
          exit(-1);
        }
        nbytes += sizeof(codeh.v_name);
        nobj += fread(&codeh.icode,sizeof(codeh.icode),1,fpcodeh);
        nbytes += sizeof(codeh.icode);
        nobj += fread(codeh.code,sizeof(codeh.code),1,fpcodeh);
        nbytes += sizeof(codeh.code);
        nobj += fread(&codeh.ncode,sizeof(codeh.ncode),1,fpcodeh);
        nbytes += sizeof(codeh.ncode);
         codehptr = &codeh;
        return codehptr;
 
} /* end of codeh_write */ 

/* This function reads the engineering data header */
struct ant_def * enh_read(FILE * fpeng)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */

  struct ant_def ant;
  struct ant_def *antptr; 
        nbytes = 0;
        nobj = 0;
 
        nobj += fread(&ant.antennaNumber,sizeof(ant.antennaNumber),1,fpeng);
        if (nobj == 0) {
          printf("Unexpected end of file enh_read\n");
          exit(-1);
        }
        nbytes += sizeof(ant.antennaNumber);
        nobj += fread(&ant.padNumber,sizeof(ant.padNumber),1,fpeng);
        nbytes += sizeof(ant.padNumber);
        nobj += fread(&ant.antennaStatus,sizeof(ant.antennaStatus),1,fpeng);
        nbytes += sizeof(ant.antennaStatus);
        nobj += fread(&ant.trackStatus,sizeof(ant.trackStatus),1,fpeng);
        nbytes += sizeof(ant.trackStatus);
        nobj += fread(&ant.commStatus,sizeof(ant.commStatus),1,fpeng);
        nbytes += sizeof(ant.commStatus);
        nobj += fread(&ant.inhid,sizeof(ant.inhid),1,fpeng);
        nbytes += sizeof(ant.inhid);
        nobj += fread(&ant.ints,sizeof(ant.ints),1,fpeng);
        nbytes += sizeof(ant.ints);
        nobj += fread(&ant.dhrs,sizeof(ant.dhrs),1,fpeng);
        nbytes += sizeof(ant.dhrs);
        nobj += fread(&ant.ha,sizeof(ant.ha),1,fpeng);
        nbytes += sizeof(ant.ha);
        nobj += fread(&ant.lst,sizeof(ant.lst),1,fpeng);
        nbytes += sizeof(ant.lst);
        nobj += fread(&ant.pmdaz,sizeof(ant.pmdaz),1,fpeng);
        nbytes += sizeof(ant.pmdaz);
        nobj += fread(&ant.pmdel,sizeof(ant.pmdel),1,fpeng);
        nbytes += sizeof(ant.pmdel);
        nobj += fread(&ant.tiltx,sizeof(ant.tiltx),1,fpeng);
        nbytes += sizeof(ant.tiltx);
        nobj += fread(&ant.tilty,sizeof(ant.tilty),1,fpeng);
        nbytes += sizeof(ant.tilty);
        nobj += fread(&ant.actual_az,sizeof(ant.actual_az),1,fpeng);
        nbytes += sizeof(ant.actual_az);
        nobj += fread(&ant.actual_el,sizeof(ant.actual_el),1,fpeng);
        nbytes += sizeof(ant.actual_el);
        nobj += fread(&ant.azoff,sizeof(ant.azoff),1,fpeng);
        nbytes += sizeof(ant.azoff);
        nobj += fread(&ant.eloff,sizeof(ant.eloff),1,fpeng);
        nbytes += sizeof(ant.eloff);
        nobj += fread(&ant.az_tracking_error,sizeof(ant.az_tracking_error),1,fpeng);
        nbytes += sizeof(ant.az_tracking_error);
        nobj += fread(&ant.el_tracking_error,sizeof(ant.el_tracking_error),1,fpeng);
        nbytes += sizeof(ant.el_tracking_error);
        nobj += fread(&ant.refraction,sizeof(ant.refraction),1,fpeng);
        nbytes += sizeof(ant.refraction);
        nobj += fread(&ant.chopper_x,sizeof(ant.chopper_x),1,fpeng);
        nbytes += sizeof(ant.chopper_x);
        nobj += fread(&ant.chopper_y,sizeof(ant.chopper_y),1,fpeng);
        nbytes += sizeof(ant.chopper_y);
        nobj += fread(&ant.chopper_z,sizeof(ant.chopper_z),1,fpeng);
        nbytes += sizeof(ant.chopper_z);
        nobj += fread(&ant.chopper_angle,sizeof(ant.chopper_angle),1,fpeng);
        nbytes += sizeof(ant.chopper_angle);
        nobj += fread(&ant.tsys,sizeof(ant.tsys),1,fpeng);
        nbytes += sizeof(ant.tsys);
        nobj += fread(&ant.ambient_load_temperature,sizeof(ant.ambient_load_temperature),1,fpeng);        
        nbytes += sizeof(ant.ambient_load_temperature);
        antptr = &ant;
        return antptr;
} 

struct sch_def * sch_head_read(FILE * fpsch)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */

  struct sch_def sch;
  struct sch_def *schptr; 
        nbytes = 0;
        nobj = 0;
 
        nobj += fread(&sch.inhid,sizeof(sch.inhid),1,fpsch);
        if (nobj == 0) {
          printf("Unexpected end of file sch_head_read\n");
          exit(-1);
        }
        nbytes += sizeof(sch.inhid);
        nobj += fread(sch.form,sizeof(sch.form),1,fpsch);
        nbytes += sizeof(sch.form);
        nobj += fread(&sch.nbyt,sizeof(sch.nbyt),1,fpsch);
        nbytes += sizeof(sch.nbyt);
        nobj += fread(&sch.nbyt_pack,sizeof(sch.nbyt_pack),1,fpsch);
        nbytes += sizeof(sch.nbyt_pack);
        schptr = &sch;
        return schptr;
 
} /* end of sch_write */ 

int sch_data_read(FILE * fpsch, long int datalength, short int * data)
{
  int nbytes;   /* counts number of bytes written */
  int nobj;     /* the number of objects written by each write */
  int i;
  extern smlodd smabuffer;
/*  short buff;*/
        nbytes = 0;
        nobj = 0;
        nobj += fread(data,datalength*sizeof(short int),1,fpsch);
        if (nobj == 0) {
        printf("The current scan (set=% 4d) is being read.\n",
                smabuffer.currentscan); 
        bug_c('f',"Unexpected end of file shc_data_read. Using nscans\n to select a scan range and run smalod again.\n"); 
        exit(-1);
        }
        return nbytes;
 
} /* end of sch_data_read */

char *rar2c(double ra)
{   static char rac[13];
    int hh, mm;
    float ss;
        hh = (int) (12.0/DPI*ra);
        mm = (int) ((12.0/DPI*ra-hh)*60.0);
        ss = (float) (((12.0/DPI*ra-hh)*60.0-mm)*60.0);
    sprintf(rac,"%02d:%02d:%07.4f", hh,mm,ss);
        rac[13]='\0';
/*    printf("ra=%s\n", rac);
  */
  return &rac[0];      
}

char *decr2c(double dec)
{   static char decc[15];
    int dd, am;
    float as;
        dd = (int)(180./DPI*dec);
        am = (int)((180./DPI*dec-dd)*60.0);
        as = (float)(((180./DPI*dec-dd)*60.0-am))*60.0;
        am = (int)fabs(am);
        as = (float)fabs(as);
    sprintf(decc,"% 3d:%02d:%07.4f", dd,am,as);
        decc[15]='\0';
    return &decc[0];
}
 
int spdecode (struct codeh_def *specCode[])
{   int spid;
    char  cspid[13];
    char  prefix[1];
    cspid[13]='\0';
    memcpy(cspid, specCode[0]->code, 12);
    sscanf(cspid, "%1s%d", prefix, &spid);
    return spid;
}

float juliandate (struct codeh_def *refdate[])
{   int i, stat;
    double jdate;
    char  ccaldate[13];
    static char *months[] = {"ill", "Jan","Feb","Mar","Apr","May","Jun","Jul", 
          "Aug","Sep","Oct","Nov","Dec"};
    char yc[4];
    char mc[3];
    char dc[2];
    int yi,mi, di;
    ccaldate[13]='\0';
    memcpy(ccaldate,refdate[0]->code, 12);
    sscanf(ccaldate, "%s%d%s%d", mc, &di,yc,&yi);
    printf("Observing Date: %d %s %d\n", yi, mc, di);
     for (i=1; i<13; i++){
       if (memcmp(mc,months[i], 3)==0) mi=i;
                         }
    jdate = slaCldj (yi, mi, di, stat)+2400000.5;
    return jdate;
    }
 

double slaCldj ( int iy, int im, int id,  int sj)
/*
**  - - - - - - - -
**   s l a C l d j
**  - - - - - - - -
**
**  Gregorian calendar to Modified Julian Date.
**
**  Given:
**     iy,im,id     int    year, month, day in Gregorian calendar
**
**  Returned:
**     *djm         double Modified Julian Date (JD-2400000.5) for 0 hrs
**     *j           int    status:
**                           0 = OK
**                           1 = bad year   (MJD not computed)
**                           2 = bad month  (MJD not computed)
**                           3 = bad day    (MJD computed)
**
**  The year must be -4699 (i.e. 4700BC) or later.
**
**  The algorithm is derived from that of Hatcher 1984 (QJRAS 25, 53-55).
**
**  Last revision:   29 August 1994
**
**  Copyright P.T.Wallace.  All rights reserved.
*/
{
   long iyL, imL, mjd;
   int jj, *j;
   double mjd_rtn;
/* Month lengths in days */
   static int mtab[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };




/* Validate year */
   if ( iy < -4699 ) { *j = 1; return; }

/* Validate month */
   if ( ( im < 1 ) || ( im > 12 ) ) { *j = 2; return; }

/* Allow for leap year */
   mtab[1] = ( ( ( iy % 4 ) == 0 ) &&
             ( ( ( iy % 100 ) != 0 ) || ( ( iy % 400 ) == 0 ) ) ) ?
             29 : 28;

/* Validate day */
  jj =  (( id < 1 || id > mtab[im-1] ) ? 3 : 0);

/* Lengthen year and month numbers to avoid overflow */
   iyL = (long) iy;
   imL = (long) im;
/* Perform the conversion */
 /*djm = (double)*/

  mjd =  ( ( 1461L * ( iyL - ( 12L - imL ) / 10L + 4712L ) ) / 4L
        + ( 306L * ( ( imL + 9L ) % 12L ) + 5L ) / 10L
        - ( 3L * ( ( iyL - ( 12L - imL ) / 10L + 4900L ) / 100L ) ) / 4L
        + (long) id - 2399904L );
    mjd_rtn = (double) mjd;
 return mjd_rtn;
}

void precess(jday1,ra1,dec1,jday2,ra2pt,dec2pt)
double jday1,ra1,dec1,jday2,*ra2pt,*dec2pt; 
{
/* jhz 2004-7-23: based on a miriad fortran code, translate into c.
c  A simple precession routine, to precess from one set of mean
c  equatorial coordinates (RA,DEC), to another at a different epoch.
c  This is accurate to order 0.3 arcsec over 50 years.
c
c  Reference:
c    Explanatory Supplement to the Astronomical Almanac, 1993. p 105-106.
c
c  NOTE: This does not take account of atmospheric refraction,
c  nutation, aberration nor gravitational deflection.
c
c  Input:
c    jday1      Julian day of the known epoch.
c    ra1,dec1   RA,DEC at the jday1 epoch (radians).
c    jday2      Julian day of the new epoch.
c  Output:
c    ra2,dec2   Precessed coordinates (radians) */
       double r0,d0,rm,dm,T,M,N,ra2,dec2;
       T  = (jday1 - 2451545.0)/36525;
       M  = DPI/180 * (1.2812323 + (0.0003879 + 0.0000101*T)*T)*T;
       N  = DPI/180 * (0.5567530 - (0.0001185 + 0.0000116*T)*T)*T;
       rm = ra1 - 0.5*(M + N*sin(ra1)*tan(dec1));
       dm = dec1 - 0.5*N*cos(rm);

/*   J2000 coordinates */
       r0 = ra1 - M - N*sin(rm)*tan(dm);
       d0 = dec1 - N*cos(rm);
/* Coordinates of the other epoch. */
        T = (jday2 - 2451545.0)/36525.0;
        M = DPI/180.0 * (1.2812323 + (0.0003879 + 0.0000101*T)*T)*T;
        N = DPI/180.0 * (0.5567530 - (0.0001185 + 0.0000116*T)*T)*T;
        rm = r0 + 0.5*(M + N*sin(r0)*tan(d0));
        dm = d0 - 0.5*N*cos(rm);
        ra2 = r0 + M + N*sin(rm)*tan(dm);
        dec2 = d0 + N*cos(rm);
        *ra2pt=ra2;
        *dec2pt=dec2;
     }

void nutate(jday,rmean,dmean,rtrueptr,dtrueptr)
double jday,rmean,dmean,*rtrueptr,*dtrueptr;
{
/* jhz 2004-7-23: based on miriad code in f, translate into c
c  Convert between mean and true equatorial coordinates, by
c  accounting for nutation.
c
c  Input:
c    jday       Julian day.
c    rmean,dmean Mean (RA,DEC) at jday.
c  Output:
c    rtrue,dtrue True (RA,DEC) at jday.
*/
 double deps,dpsi,eps, rtrue, dtrue;
 double coseps,sineps,sinra,cosra,tandec;
 double mobliq();
 void nuts();
/*  Nutation parameters. */
        nuts(jday,&dpsi,&deps);
/*  True obliquity. */
        eps = mobliq(jday) + deps;
/*  Various parameters. */
        sineps = sin(eps);
        coseps = cos(eps);
        sinra  = sin(rmean);
        cosra  = cos(rmean);
        tandec = tan(dmean);   

        rtrue = rmean + (coseps + sineps*sinra*tandec)*dpsi
                      - cosra*tandec*deps;
        dtrue = dmean + sineps*cosra*dpsi + sinra*deps;
        *rtrueptr = rtrue;
        *dtrueptr = dtrue;
     /*   printf("nutate: r1 d1 %f %f\n", rtrue, dtrue);
*/
}
void nuts(jday,dpsiptr,depsptr)
double jday,*dpsiptr,*depsptr;
{
/* jhz 2004-7-23: based on miriad code in f and translate into c.
c
c  Return nutation parameters. The claimed accuracy is 1 arcsec.
c
c  Input:
c    jday       Julian date.
c  Output:
c    dpsi,deps  Difference between mean and true ecliptic latitude and
c               longitude due to nutation, in radians.
c
c  Reference:
c    Explanatory Supplmenet, page 120.
c--
*/
       double d,t1,t2, dpsi,  deps;
        d = jday - 2451545.0;
        t1 = DPI/180*(125.0 - 0.05295 * d);
        t2 = DPI/180*(200.9 + 1.97129 * d);
        dpsi = DPI/180 * (-0.0048*sin(t1) - 0.0004*sin(t2));
        deps = DPI/180 * ( 0.0026*cos(t1) + 0.0002*cos(t2));
        *dpsiptr=dpsi;
        *depsptr=deps;
}

double mobliq(double jday)
{
/* jhz 2004-7-23: based on miriad code in f and translate into c.
c
c  Return the mean obliquity of the ecliptic.
c
c  Input:
c    jday       Julian day.
c  Output:
c    mobliq     Mean obliquity of the ecliptic, in radians.
c
c  Reference:
c    Explanatory Supplement ... page 114.
c-- */
     double T;
     double vmobliq;
/* Centuries from J2000*/
    T = (jday - 2451545.0) / 36525.0;
/* Mean obliquity.*/    
        vmobliq = 84381.448 - (46.8150+(0.00059-0.001813*T)*T)*T;
        vmobliq = DPI/(180.*3600.) * vmobliq;    
        return vmobliq;
}

void aberrate(jday,ra,dec,rappptr,dappptr)
double jday,ra,dec,*rappptr,*dappptr;
{/* jhz 2004-7-23: based on miriad code in f and translate into c.
cc  Account for the effect of annual aberration, to convert
c  from a true (RA,DEC) to a geocentric apparent (RA,DEC).
c
c  Input:
c    jday       Julian date.
c    ra,dec     True (RA,DEC).
c  Output:
c    rapp,dapp  Geocentric apparent (RA,DEC).
c--
*/
double  pos[3],vel[3],sinra,sindec,cosra,cosdec, rapp, dapp;
void vearth();

         vearth(jday,&pos, &vel);
        sinra = sin(ra);
        cosra = cos(ra);
        sindec = sin(dec);
        cosdec = cos(dec);
        rapp = ra +  (-vel[0]*sinra + vel[1]*cosra)/
                                    (0.001*CMKS*cosdec);
        dapp = dec + (-vel[0]*cosra*sindec - vel[1]*sinra*sindec
                   + vel[2]*cosdec)/(0.001*CMKS);
        *rappptr= rapp;
        *dappptr= dapp;

}

void vearth (double jday, double pos[3], double vel[3])
{
/* jhz 2004-7-23: based on miriad code in f and translate into c.
*
*  Approximate heliocentric position and velocity of the Earth
*  The date and time should really be in the TDB in the Gregorian
*  calendar, and is interpreted in a manner which is valid between
*  1900 March 1 and 2100 February 28.
*
*  Input:
*    jday       Time of interest (as Julian day).
*  Output:
*    pos        Position, in km.
*    vel        Velocity, in km/sec.
*
*  The Earth heliocentric position/velocity is for mean equator and equinox
*  of date.
*
*  Max/RMS errors 1950-2050:
*     13/5 E-5 AU = 19200/7600 km in position
*     47/26 E-10 AU/s = 0.0070/0.0039 km/s in speed
*/
       float twopi, speed, remb, semb;
       double aukm, j1901;
       float YF,T,ELM,GAMMA,EM,ELT,EPS0,DAY;
       float E,ESQ,V,R,ELMM,COSELT,SINEPS,COSEPS,W1,W2,SELMM,CELMM;
       int IY, QUAD;
       twopi = (float) 2*DPI;
/* Mean orbital speed of Earth, AU/s */
       speed = 1.9913E-7;
/* Mean Earth:EMB distance and speed, AU and AU/s */
       remb = 3.12E-5;
       semb = 8.31E-11;
/* AU to km */
       aukm=149.597870e6;
/* Julian date for 1 January, 1901. */
       j1901=2415385.5;
/* Whole years & fraction of year, and years since 1900.*/
       QUAD = (int)((jday - j1901) / 1461.);
       IY   = (int)((jday - j1901 - 1461*QUAD) / 365.0);
       DAY  = (float)(jday - j1901 - 1461*QUAD - 365*IY + 1);
       IY   = 4*QUAD + IY + 1;
       YF   = (4*DAY - 4*(1/(fmod(IY,4)+1)) - fmod(IY,4) - 2) / 1461.0;
       T    = IY + YF;
/* Geometric mean longitude of Sun
*  (cf 4.881627938+6.283319509911*T MOD 2PI)*/
       ELM  = fmod(4.881628+twopi*YF+0.00013420*T, twopi);
/*  Mean longitude of perihelion */
       GAMMA=4.908230+3.0005e-4*T;
/*  Mean anomaly */
       EM=ELM-GAMMA;
/*  Mean obliquity */
       EPS0=0.40931975-2.27e-6*T;
/*  Eccentricity  */
       E=0.016751-4.2e-7*T;
         ESQ=E*E;
/*  True anomaly */
      V=EM+2.0*E*sin(EM)+1.25*ESQ*sin(2.0*EM);
/*  True ecliptic longitude*/
      ELT=V+GAMMA;
/*  True distance */
      R=(1.0-ESQ)/(1.0+E*cos(V));
/*  Moon's mean longitude */
      ELMM=fmod(4.72+83.9971*T, twopi);
/*  Useful functions */
      COSELT=cos(ELT);
      SINEPS=sin(EPS0);
      COSEPS=cos(EPS0);
      W1=-R*sin(ELT);
      W2=-speed*(COSELT+E*cos(GAMMA));
      SELMM=sin(ELMM);
      CELMM=cos(ELMM);
/*  Earth position and velocity*/
      pos[0] = aukm * (-R*COSELT-remb*CELMM);
      pos[1] = aukm * (W1-remb*SELMM)*COSEPS;
      pos[2] = aukm * W1*SINEPS;
      vel[0] = aukm * (speed*(sin(ELT)+E*sin(GAMMA))+semb*SELMM);
      vel[1] = aukm * (W2-semb*CELMM)*COSEPS;
      vel[2] = aukm * W2*SINEPS;
}

double epo2jul(double epoch, char *code[])
{
/* jhz 2004-7-24: based on miriad code in f, translate into c.
c
c  Convert an epoch (in years) to a Julian day.
c
c  Input:
c    epoch      The epoch.
c    code       Either 'B' (Besselian epoch) or 'J' (Julian) or ' '
c               If its blank, Julian epoch is assumed for values
c               greater than 1984.
c  Output:
c    epo2jul    The Julian day.
*/
        int julian;
        double julianday;
        char jcode[1];
           code[2]='\0';
           printf("code %s\n", &code[0]);
          sprintf(&jcode[0], "%s", &code[0]);
        if( jcode[0]==' '&&epoch>1984.0)julian = 1;
        if (jcode[0]=='J'||jcode[0]=='j')julian = 1;
        if (jcode[0]!='J'&&jcode[0]!='j'&&jcode[0]!='B'&&jcode[0]!='b')
          bug_c('f',"Unrecognized epoch type, in epo2jul");
        if(julian==1)
          julianday = 365.25*(epoch-2000) + 2451545;
              /* why not 245544.5 ? */
        else 
          julianday = 365.242198781*(epoch-1900) + 2415020.31352;
             /* why this value for epoch-1900 ? */
          printf("jcode %s\n", &jcode[0]);
       return julianday;
}

void elaz(int tno) {
/* calculate and store mean az and el into uv data */
int i;
double mel, maz;
extern smlodd smabuffer;
       mel=0;
       maz=0;
        if(smabuffer.nants!=0) {
     for (i=0; i<smabuffer.nants; i++) {
         mel=mel+smabuffer.el[i];
         maz=maz+smabuffer.az[i];
                                       }
         mel=mel/smabuffer.nants;
         maz=maz/smabuffer.nants;
          /* both az and el in degree */
         uvputvrd_c(tno,"antaz",&maz,1);
         uvputvrd_c(tno,"antel",&mel,1);
         }
}
void tsysStore(int tno) {
/* store Tsys to uvdata */
extern smlodd smabuffer;
int cnt, i, j;
float tsysbuf[SMANT*SMIF];
    cnt =0;
/* only one  if */
  for (j=0; j< smabuffer.nants; j++) {
      tsysbuf[cnt]= smabuffer.tsys[j];
/*      if(smabuffer.tsys[j]<0.) tsysbuf[cnt]=0.;
*/
      cnt++;
      }
       uvputvrr_c(tno,"systemp",&tsysbuf,cnt);
}
