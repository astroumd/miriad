
/* $Id$ */

#include <stdio.h>

int main ( int argc, char **argv )
{
  /* now a stub to not break 1 file 1 binary old build system */
}

#include "config.h"

#include <stdio.h>

#include "miriad.h"
#include "mfilelib.h"

// TODO
// Error for now on these conditions until
// we have more robust ways of working through these...
#if( defined(HAVE_STDLIB_H) && ( HAVE_STDLIB_H == 1 ))
#include <stdlib.h>
#else
#error "Needs stdlib.h"
#endif

#if( defined(HAVE_STRDUP) && ( HAVE_STRDUP == 1 ))
#include <string.h>
#else
#error "Needs string.h"
#endif

#if( defined(HAVE_SYS_STAT_H) && ( HAVE_SYS_STAT_H == 1 ))
#include <sys/stat.h>
#else
#error "Needs sys/stat.h"
#endif

#if( defined(HAVE_SYS_TYPES_H) && ( HAVE_SYS_TYPES_H == 1 ))
#include <sys/types.h>
#else
#error "Needs sys/types.h"
#endif

#if( defined(HAVE_UNISTD_H) && ( HAVE_UNISTD_H == 1 ))
#include <unistd.h>
#else
#error "Needs unistd.h"
#endif


extern bool mfile_verbose;

char *getMiriadDataType( int mirfd )
{

  char *mirt;

  if ( mfile_verbose )
    fprintf( stderr, " hdprsnt_c(%d,'image')\n", mirfd );
  if ( hdprsnt_c( mirfd, "image" ) != 0 )
    mirt = "image";

  if ( mfile_verbose )
    fprintf( stderr, " hdprsnt_c(%d,'visdata')\n", mirfd );
  if ( hdprsnt_c( mirfd, "visdata" ) != 0 )
    mirt = "visdata";

  if ( mfile_verbose )
    fprintf( stderr, " hdprsnt_c(%d,'rdata')\n", mirfd );
  if ( hdprsnt_c( mirfd, "rdata" ) != 0 )
    mirt = "rdata";

  // Can lead to mem leaks
  return strdup(mirt);
}

void printMirInfoDesc( mirInfoDesc *desc )
{
  printf( "name: '%s'\n", desc->fileName );
  printf( "dataType: '%s'\n", desc->type );

}

void printCSVMirInfoDesc( mirInfoDesc *desc )
{
  printf( "\"%s\",\"%s\"\n", desc->fileName, desc->type );
}
