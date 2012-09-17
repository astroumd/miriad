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

 *  After this , hexdump -C test1.mir/header , will show the layout of the bytes

          +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F    0123456789ABCDEF
00000000  61 5f 69 74 65 6d 00 00  00 00 00 00 00 00 00 00  |a_item..........|
00000010  61 5f 63 68 61 72 5f 31  00 00 00 00 00 00 00 0f  |a_char_1........|
00000020  00 00 00 01 48 65 6c 6c  6f 20 57 6f 72 6c 64 00  |....Hello World.|
00000030  61 5f 63 68 61 72 00 31  00 00 00 00 00 00 00 09  |a_char.1........|
00000040  00 00 00 01 48 65 6c 6c  6f 00 00 00 00 00 00 00  |....Hello.......|
00000050  61 5f 69 6e 74 38 5f 35  00 00 00 00 00 00 00 10  |a_int8_5........|
00000060  00 00 00 08 00 00 00 00  00 00 00 01 00 00 00 02  |................|
00000070  61 5f 69 6e 74 38 5f 34  00 00 00 00 00 00 00 10  |a_int8_4........|
00000080  00 00 00 08 00 00 00 00  00 00 00 01 00 00 00 00  |................|
00000090  61 5f 69 6e 74 38 5f 33  00 00 00 00 00 00 00 10  |a_int8_3........|
000000a0  00 00 00 08 00 00 00 00  00 00 00 00 ff ff ff ff  |................|
000000b0  61 5f 69 6e 74 38 5f 32  00 00 00 00 00 00 00 10  |a_int8_2........|
000000c0  00 00 00 08 00 00 00 00  00 00 00 00 80 00 00 00  |................|
000000d0  61 5f 69 6e 74 38 5f 31  00 00 00 00 00 00 00 10  |a_int8_1........|
000000e0  00 00 00 08 00 00 00 00  00 00 00 00 7f ff ff ff  |................|
000000f0  61 5f 69 6e 74 38 5f 30  00 00 00 00 00 00 00 10  |a_int8_0........|
00000100  00 00 00 08 00 00 00 00  00 00 00 00 00 00 01 02  |................|
00000110  61 5f 69 6e 74 00 5f 30  00 00 00 00 00 00 00 08  |a_int._0........|
00000120  00 00 00 02 00 00 01 02  00 00 00 00 00 00 00 00  |................|
00000130  61 5f 72 65 61 6c 5f 64  00 00 00 00 00 00 00 08  |a_real_d........|
00000140  00 00 00 04 40 49 0f db  00 00 00 00 00 00 00 00  |....@I..........|
00000150  61 5f 72 65 61 6c 5f 66  00 00 00 00 00 00 00 08  |a_real_f........|
00000160  00 00 00 04 40 49 0f db  00 00 00 00 00 00 00 00  |....@I..........|
00000170  61 5f 64 6f 75 62 6c 65  00 00 00 00 00 00 00 10  |a_double........|
00000180  00 00 00 05 f0 03 38 00  40 09 21 fb 54 44 2d 18  |......8.@.!.TD-.|
00000190

 *
 * History:
 *
 *      
 *      aug-2006:     some changes for MIR5
 *      oct-2008      append option, added more to 's' to show things
 *      jun-2011      made it compile for ATNF version as well, add header readx
 */


#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "maxdimc.h"
#include "miriad.h"
/* work around an ATNF header difference */
#ifndef BUFSIZE
#include "sysdep.h"
#endif


#define check(iostat) if(iostat)bugno_c('f',iostat)


void test_hio(char *name1, int write)
{
  int t1, i1,iostat;
  double pi_d = 3.14159265358979323846;
  float  pi_f = 3.14159265358979323846;
  int  d    = 258;          /*                0x01 0x02 */
  int8 d8_0 = 258;          /*                0x01 0x02 */
  int8 d8_1 = 2147483647LL; /*      0x7F 0xFF 0xFF 0xFF */
  int8 d8_2 = 2147483648LL; /*      0x80 0x00 0x00 0x00 */
  int8 d8_3 = 4294967295LL; /*      0x0F 0xFF 0xFF 0xFF */
  int8 d8_4 = 4294967296LL; /* 0x01 0x00 0x00 0x00 0x00 */
  int8 d8_5 = 4294967298LL; /* 0x01 0x00 0x00 0x00 0x02 */

  fprintf(stderr,"test_hio: %s\n",name1);

  if (write) {
    hopen_c(&t1, name1, "old", &iostat);
    if (iostat==0) {
      fprintf(stderr,"Deleting previous dataset %s\n",name1);
      hrm_c(t1);
    } else
      fprintf(stderr,"Creating new dataset %s\n",name1);
    hopen_c(&t1, name1, "new", &iostat);                check(iostat);
  } else {
    hopen_c(&t1, name1, "old", &iostat);                check(iostat);
  }


  if (write) {
    wrhdd_c(t1,"a_double",pi_d);
    wrhdr_c(t1,"a_real_f",pi_f);
    wrhdr_c(t1,"a_real_d",pi_d);
    wrhdi_c(t1,"a_int",   d);
    wrhdl_c(t1,"a_int8_0",d8_0);
    wrhdl_c(t1,"a_int8_1",d8_1);
    wrhdl_c(t1,"a_int8_2",d8_2);
    wrhdl_c(t1,"a_int8_3",d8_3);
    wrhdl_c(t1,"a_int8_4",d8_4);
    wrhdl_c(t1,"a_int8_5",d8_5);
    wrhda_c(t1,"a_char","Hello");
    wrhda_c(t1,"a_char_1","Hello World");
    wrhda_c(t1,"a_char_2","Hello World abcdefghijklmnopqrstuvwxyz");
  } else {
    rdhdd_c(t1,"a_double",&pi_d, 0.0);   printf("a_double=%g\n",pi_d);
    rdhdr_c(t1,"a_real_f",&pi_f, 0.0);   printf("a_real_f=%g\n",pi_f);
    rdhdr_c(t1,"a_real_d",&pi_d, 0.0);   printf("a_real_d=%g\n",pi_d);
    rdhdi_c(t1,"a_int",   &d,    0);     printf("a_int=%d\n",d);
    rdhdl_c(t1,"a_int8_0",&d8_0, 0);     printf("a_int8_0=%lld\n",d8_0);
    rdhdl_c(t1,"a_int8_1",&d8_1, 0);     printf("a_int8_1=%lld\n",d8_1);
    rdhdl_c(t1,"a_int8_2",&d8_2, 0);     printf("a_int8_2=%lld\n",d8_2);
    rdhdl_c(t1,"a_int8_3",&d8_3, 0);     printf("a_int8_3=%lld\n",d8_3);
    rdhdl_c(t1,"a_int8_4",&d8_4, 0);     printf("a_int8_4=%lld\n",d8_4);
    rdhdl_c(t1,"a_int8_5",&d8_5, 0);     printf("a_int8_5=%lld\n",d8_5);
  }

  haccess_c(t1,&i1,"a_item","write",&iostat);         check(iostat);
  hdaccess_c(i1,&iostat);                             check(iostat);

#if 0
  hdelete_c(t1,"a_char",&iostat);                          check(iostat);
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
  int nschan  = 1;

  fprintf(stderr,"test_uvio: %s nc,nw,nr=%d %d %d\n",fname,nc,nw,nr);

  /* check if old one , if exists, add data in append mode */
  hopen_c(&t1, fname, "old", &iostat);

  if (iostat==0)  {
    fprintf(stderr,"  appending to %s\n",fname);
    uvopen_c(&t1, fname, "append");
  } else {
    fprintf(stderr,"  new dataset %s\n",fname);
    uvopen_c(&t1, fname, "new");
  }

  uvset_c(t1, "data",     "channel", 0, 1.0, 1.0, 1.0);
  uvset_c(t1, "preamble", "uvw/time/baseline", 0, 0.0, 0.0, 0.0);

  for (i=0; i<nr; i++) {
    /* garbage uv variables */
    uvputvr_c(t1,H_BYTE,"abyte",(char *)data, 1);
    uvputvr_c(t1,H_INT2,"aint2",(char *)data, 1);
    uvputvr_c(t1,H_INT, "aint4",(char *)data, 1);
    uvputvr_c(t1,H_REAL,"areal",(char *)data, 1);
    uvputvr_c(t1,H_DBLE,"adble",(char *)data, 1);
    uvputvr_c(t1,H_CMPLX,"acmplx",(char *)data, 1);
    /* some data */
    if (nw)  uvwwrite_c(t1,data,flags,nw);
    uvwrite_c(t1,preamble,data,flags,nc);
  }
  uvclose_c(t1);
}


void test_sizes(void)
{
  printf("sizeof(char)        = %d\n",sizeof(char));
  printf("sizeof(short)       = %d\n",sizeof(short));
  printf("sizeof(int)         = %d\n",sizeof(int));
  printf("sizeof(long)        = %d\n",sizeof(long));
  printf("sizeof(long long)   = %d\n",sizeof(long long));
  printf("sizeof(void *)      = %d\n",sizeof(void *));
  printf("sizeof(off_t)       = %d\n",sizeof(off_t));
  printf("sizeof(size_t)      = %d\n",sizeof(size_t));
  printf("sizeof(ptrdiff_t)   = %d\n",sizeof(ptrdiff_t) );
  printf("sizeof(int2)        = %d\n",sizeof(int2));
  printf("sizeof(int8)        = %d\n",sizeof(int8));
  printf("sizeof(float)       = %d\n",sizeof(float) );
  printf("sizeof(double)      = %d\n",sizeof(double) );
  printf("sizeof(long double) = %d\n",sizeof(long double) );

#ifdef MIRTEL
  printf("MIRTEL              = %s\n",MIRTEL);
#else
  printf("MIRTEL              = %s\n","ATNF");
#endif
#ifdef MAXIANT
  printf("MAXIANT             = %d\n",MAXIANT);
#else
  printf("MAXIANT             = %d\n",-1);
#endif
  printf("MAXANT              = %d\n",MAXANT);
  printf("MAXBASE             = %d\n",MAXBASE);
  printf("MAXDIM              = %d\n",MAXDIM);
  printf("MAXCHAN             = %d\n",MAXCHAN);
  printf("MAXWIN              = %d\n",MAXWIN);
  
}

void my_handler(char c, char *msg)
{
  char *m = bugmessage_c();
  printf("HANDLED1: %s\n",m);
  printf("HANDLED2: %s\n",msg);
}

void my_recover(void)
{
  char *m = bugmessage_c();
  printf("RECOVERED: %s\n",m);
}

void test_errors(void)
{
  printf("Testing error catching\n");
  bughandler_c(my_handler);
  //bugrecover_c(my_recover);
  bug_c('f',"here's some random fatal error from miriad");
  printf("And we just continue on....\n");
}


int main(int argc, char *argv[])
{
  int n1, n2, n3;
  char *buf;
  fprintf(stderr,"Testing MIRLIB:\n");
  if (argc==1) {
    fprintf(stderr,"Command line options\n");
    fprintf(stderr," w                              hio write test on test1.mir \n");
    fprintf(stderr," r                              hio read test on test1.mir \n");
    fprintf(stderr," x [nx ny nz]                   xyio write test on test1.xy\n");
    fprintf(stderr," u [nc nw nr]                   uvio write test on test1.uv\n");
    fprintf(stderr," m                              malloc loop until full memory [sic]\n");
    fprintf(stderr," s                              show sizeof() and MAX... of things\n");
    fprintf(stderr," e                              test fatal error catching\n");
    return 1;
  }

  switch (*argv[1]) {
  case 'w': 
    test_hio("test1.mir",1);
    break;
  case 'r': 
    test_hio("test1.mir",0);
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
  case 'e':
    test_errors();
    break;
  default:
    break;
  }
  return 0;
}
