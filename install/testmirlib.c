/*
 *  test out a bunch of things the C version of mirlib does
 *
 *  gcc -g -Imirlib -o testmirlib testmirlib.c mirlib/libmir.a -lm
 * or:
 *  gcc -g -I$MIRINC -I$MIRSUBS -o testmirlib testmirlib.c -L$MIRLIB -lmir -lm
 *  [except it seems to need pgplot now, and it should not !!! ]
 *  gcc -g -I$MIRINC -I$MIRSUBS -o testmirlib testmirlib.c $MIRLIB/libmir.a -lm
 *  [prevents the  pgplot problem]
 *
 *  Note: for LFS you also need to add extra compile flags:
 *     set lfs=(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE)
 *     gcc -g $lfs -I$MIRINC -I$MIRSUBS -o testmirlib testmirlib.c $MIRLIB/libmir.a -lm

          +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F    0123456789ABCDEF

 +00000000 61 5F 69 74 65 6D 00 00 00 00 00 00 00 00 00 00    a_item..........
  00000010 61 5F 63 68 61 72 00 00 00 00 00 00 00 00 00 09    a_char..........
  00000020 00 00 00 01 48 65 6C 6C 6F 00 00 00 00 00 00 00    ....Hello.......
  00000030 61 5F 69 6E 74 38 00 00 00 00 00 00 00 00 00 08    a_int8..........
  00000040 00 00 00 02 00 00 00 1C 00 00 00 00 00 00 00 00    ................
  00000050 61 5F 69 6E 74 00 00 00 00 00 00 00 00 00 00 08    a_int...........
  00000060 00 00 00 02 00 00 00 1C 00 00 00 00 00 00 00 00    ................
  00000070 61 5F 72 65 61 6C 5F 64 00 00 00 00 00 00 00 08    a_real_d........
  00000080 00 00 00 04 40 49 0F DB 00 00 00 00 00 00 00 00    ....@I..........
  00000090 61 5F 72 65 61 6C 5F 66 00 00 00 00 00 00 00 08    a_real_f........
  000000A0 00 00 00 04 40 49 0F DB 00 00 00 00 00 00 00 00    ....@I..........
  000000B0 61 5F 64 6F 75 62 6C 65 00 00 00 00 00 00 00 10    a_double........
  000000C0 00 00 00 05 58 01 C0 00 40 09 21 FB 54 44 2D 18    ....X...@.!.TD-.

 *
 * History:
 *
 *      
 *      aug-2006:     some changes for MIR5
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "maxdimc.h"
#include "miriad.h"


#define check(iostat) if(iostat)bugno_c('f',iostat)


void test_hio(char *name1)
{
  int t1, i1,iostat;
  double pi_d = 3.14159265358979323846;
  float pi_f = 3.14159265358979323846;
  int  d  = 258;          /* 0x01 0x02 */
  int8 d4 = 258;
  int8 d8 = 4294967298LL; /* 0x01 0x00 0x00 0x00 0x02 */

  fprintf(stderr,"test_hio: %s\n",name1);

  hopen_c(&t1, name1, "old", &iostat);
  if (iostat==0) {
    fprintf(stderr,"Deleting previous dataset %s\n",name1);
    hrm_c(t1);
  } else
    fprintf(stderr,"Creating new dataset %s\n",name1);

  hopen_c(&t1, name1, "new", &iostat);                check(iostat);

  wrhdd_c(t1,"a_double",pi_d);
  wrhdr_c(t1,"a_real_f",pi_f);
  wrhdr_c(t1,"a_real_d",pi_d);
  wrhdi_c(t1,"a_int",d);
  wrhdl_c(t1,"a_int8_4",d4);
  wrhdl_c(t1,"a_int8_8",d8);
  wrhda_c(t1,"a_char","Hello");

  haccess_c(t1,&i1,"a_item","write",&iostat);         check(iostat);
  hdaccess_c(i1,&iostat);                             check(iostat);

#if 0
  hdelete_c(t1,"a",&iostat);                          check(iostat);
#endif
  hclose_c(t1);

}

void test_xyio(char *fname, int nx, int ny, int nz)
{
  int t1, i,j,k,iostat;
  float data[MAXDIM];
  int axes[3];

  fprintf(stderr,"test_xyio: %s nx,ny,nz=%d %d %d\n",fname,nx,ny,nz);

  /* delete old one , if exists */
  hopen_c(&t1, fname, "old", &iostat);
  if (iostat==0) hrm_c(t1);

  axes[0] = nx;
  axes[1] = ny;
  axes[2] = nz;

  xyopen_c(&t1,fname,"new",3,axes);
  for (k=1; k<=nz; k++) {
    xysetpl_c(t1,1,&k);
    for (j=1; j<=ny; j++)
      xywrite_c(t1,j,data);
  }
  xyclose_c(t1);


}

void test_uvio(char *fname, int nc, int nw, int nr)
{
  int t1, i,iostat;
  double preamble[5];
  float data[2*MAXCHAN];
  int  flags[MAXCHAN];

  fprintf(stderr,"test_uvio: %s nc,nw,nr=%d %d %d\n",fname,nc,nw,nr);

  /* delete old one , if exists */
  hopen_c(&t1, fname, "old", &iostat);
  if (iostat==0) hrm_c(t1);

  uvopen_c(&t1, fname, "new");

  for (i=0; i<nr; i++) {

    uvputvr_c(t1,H_BYTE,"abyte",(char *)data, 1);
    uvputvr_c(t1,H_INT2,"aint2",(char *)data, 1);
    uvputvr_c(t1,H_INT, "aint4",(char *)data, 1);
    uvputvr_c(t1,H_REAL,"areal",(char *)data, 1);
    uvputvr_c(t1,H_DBLE,"adble",(char *)data, 1);
    uvputvr_c(t1,H_CMPLX,"acmplx",(char *)data, 1);
    
    uvwrite_c(t1,preamble,data,flags,nc);
    uvwwrite_c(t1,data,flags,nw);
  }
  uvclose_c(t1);
}


void test_sizes(void)
{
  printf("sizeof(short)     = %d\n",sizeof(short));
  printf("sizeof(int)       = %d\n",sizeof(int));
  printf("sizeof(long)      = %d\n",sizeof(long));
  printf("sizeof(long long) = %d\n",sizeof(long long));
  printf("sizeof(size_t)    = %d\n",sizeof(size_t));
  printf("sizeof(off_t)     = %d\n",sizeof(off_t));
  printf("sizeof(void *)    = %d\n",sizeof(void *));
}

int main(int argc, char *argv[])
{
  int n1, n2, n3;
  char *buf;
  fprintf(stderr,"Testing MIRLIB:\n");
  if (argc==1) {
    fprintf(stderr,"Command line options\n");
    fprintf(stderr," h                              hio test on test1.mir \n");
    fprintf(stderr," x [nx ny nz]                   xyio write test on test1.xy\n");
    fprintf(stderr," u [nc nw nr]                   uvio write test on test1.uv\n");
    fprintf(stderr," m                              malloc loop until full memory [sic]\n");
    return 1;
  }

  switch (*argv[1]) {
  case 'h': 
    test_hio("test1.mir");
    break;
  case 'x':
    if (argc>2) {
      n1 = atoi(argv[2]);
      n2 = atoi(argv[3]);
      n3 = atoi(argv[4]);
    } else {
      n1 = n2 = n3 = 64;
    }
    test_xyio("test1.xy", n1,n2,n3);
    break;
  case 'u':
    if (argc>2) {
      n1 = atoi(argv[2]);
      n2 = atoi(argv[3]);
      n3 = atoi(argv[4]);
    } else {
      n1 = 1024;
      n2 = 16;
      n3 = 40000;
    }
    test_uvio("test1.uv", n1,n2,n3);
    break;
  case 'm':
    fprintf(stderr,"Malloc loop until memory full, incrementing by %d ... ",BUFSIZE);  
    sleep(1);
    fprintf(stderr,"... go!\n");
    do {
      buf = malloc(BUFSIZE);
    } while (buf);
    break;
  case 's':
    test_sizes();
    break;
  default:
    break;
  }
  return 0;
}


