/*
 *  test out a bunch of things the C version of mirlib does
 *
 *  gcc -g -Imirlib -o testmirlib testmirlib.c mirlib/libmir.a -lm
 * or:
 *  gcc -g -I$MIRINC -I$MIRSUBS -o testmirlib testmirlib.c -L$MIRLIB -lmir -lm
 *  [except it seems to need pgplot now, and it should not !!! ]
 *  gcc -g -I$MIRINC -I$MIRSUBS -o testmirlib testmirlib.c $MIRLIB/libmir.a -lm
 *  [prevents the  pgplot problem]
 */


#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "maxdimc.h"
#include "miriad.h"

#define check(iostat) if(iostat)bugno_c('f',iostat)


void test_hio(char *name1)
{
  int t1, i1,iostat;
  double pi = 3.141592;
  float g = 9.8;
  int d = 28;
  

  hopen_c(&t1, name1, "old", &iostat);
  if (iostat==0) {
    fprintf(stderr,"Deleting previous dataset %s\n",name1);
    hrm_c(t1);
  } else
    fprintf(stderr,"Creating new dataset %s\n",name1);

  hopen_c(&t1, name1, "new", &iostat);                check(iostat);

  wrhdd_c(t1,"pi",pi);
  wrhdr_c(t1,"g",g);
  wrhdi_c(t1,"d",d);

  haccess_c(t1,&i1,"a","write",&iostat);              check(iostat);
  hdaccess_c(i1,&iostat);                             check(iostat);

#if 0
  hdelete_c(t1,"a",&iostat);                          check(iostat);
#endif
  hclose_c(t1);

}

void test_uvio(char *fname, int nc, int nw, int nr)
{
  int t1, i,iostat;
  double preamble[5];
  float data[2*MAXCHAN];
  int  flags[MAXCHAN];

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

int main(int argc, char *argv[])
{
  fprintf(stderr,"Testing MIRLIB\n");

  test_hio("test1.mir");

  test_uvio("test1.uv", 1024, 16, 4);
 
  return 0;
}


