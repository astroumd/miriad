/*
 *  test out a bunch of things the C version of mirlib does
 */


#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

#include "maxdimc.h"
#include "miriad.h"

#define check(iostat) if(iostat)bugno_c('f',iostat)

static char *name1 = "test1.mir";

void test_hio()
{
  int t1, i1,iostat;
  

  hopen_c(&t1, name1, "old", &iostat);
  if (iostat==0) {
    fprintf(stderr,"Deleting previous dataset %s\n",name1);
    hrm_c(t1);
  } else
    fprintf(stderr,"Creating new dataset %s\n",name1);

  hopen_c(&t1, name1, "new", &iostat);                check(iostat);
  haccess_c(t1,&i1,"a","new",&iostat);                check(iostat);
  hdaccess_c(i1,&iostat);                             check(iostat);
#if 0
  hdelete_c(t1,"a",&iostat);                          check(iostat);
#endif
  hclose_c(t1);

}

int main(int argc, char *argv[])
{
  fprintf(stderr,"Testing MIRLIB\n");

  test_hio();
}


