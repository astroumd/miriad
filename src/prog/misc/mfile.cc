
/* $Id$ */

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

// TODO: have configure check for getopt
// Also, this sort of command line processing should be pushed
// into a mir lib, in the same way the key stuff is done
// only, lets actually have command line args work like
// 99% of all other UNIX style command line interfaces, yeah?
// kthxbye
#include <getopt.h>

static struct option long_options[] =
{
  {"help",    no_argument,        0, 'h'},
  {"verbose", no_argument,        0, 'v'},
  {0, 0, 0, 0}
};


void printhelp ( char *progname )
{
  puts("");
  printf( "usage: %s <miriad dataset>\n", progname );
  printf( "\t-h,--help\t\tThis help message\n");
  printf( "\t-r,--readable\t\tPrint an easier to read format\n");
  printf( "\t-v,--verbose\t\tBe very chatty\n");
  puts("");
  printf( " Send bug reports to: %s\n", PACKAGE_BUGREPORT );
  puts("");

}

bool mfile_verbose = false;
bool human_readable = false;

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
int main ( int argc, char **argv )
{
  char *fullPathInFileName = NULL;

  while (1)
  {
    int c;
    int option_index = 0;

    c = getopt_long(argc, argv, "hrv", long_options, &option_index );

    if ( c == -1 )
      break;

    switch ( c )
    {
      case 'h':
        printhelp(argv[0]);
        return( EXIT_SUCCESS );
        break;
      case 'r':
        human_readable = true;
        break;
      case 'v':
        mfile_verbose = true;
        break;
      default:
        printf( " getopt switch got unknown switch: %d\n", c );
        printhelp(argv[0]);
        break;
    }
  }

  if ( mfile_verbose )
    printf( "%s: %s $Revision$ $Date$ \n", PACKAGE_STRING, argv[0] );

  if ( optind < argc )
  {
    fullPathInFileName = strdup(argv[optind++]);
  }
  else
  {
    puts("");
    puts( "Expected miriad data set as option!" );
    printhelp(argv[0]);
  }

  if ( optind < argc )
  {
    printf( "Ignoring remaining args passed on command-line:\n" );
    while ( optind < argc )
    {
      printf( "\t%s\n", argv[optind++] );
    }
  }

  if ( mfile_verbose )
  {
    if ( fullPathInFileName != NULL )
      fprintf( stderr, " hopen_c(...,'%s',...)\n", fullPathInFileName );
    else
    {
      fprintf( stderr, " fullPathInFileName is NULL!\n" );
      return( EXIT_FAILURE );
    }
  }

  mirInfoDesc mid;

  mid.fileName = fullPathInFileName;
  int mirfd, iostat;
  hopen_c( &mirfd, mid.fileName, "old", &iostat );
  if ( iostat )
  {
    bugno_c('f', iostat);
    return( EXIT_FAILURE );
  }

  if ( mfile_verbose )
    fprintf( stderr, " getMirType(%d)\n", mirfd );
  mid.type = getMiriadDataType( mirfd );

  if ( human_readable )
  {
	  printMirInfoDesc( &mid );
  }
  else
  {
    // default to CSV format
    printCSVMirInfoDesc( &mid );
  }

  
  return( EXIT_SUCCESS );

}

// vim: set expandtab sw=2 ts=2 cindent
