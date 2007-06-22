
/* $Id$ */

#include "config.h"

#include <stdio.h>

#include "miriad.h"

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
  printf( "\t-v,--verbose\t\tBe very chatty\n");
  puts("");
}

static bool verbose = false;
static int exitcode;

int main ( int argc, char **argv )
{
  printf( "%s: %s $Revision$\n", PACKAGE_STRING, argv[0] );

  char *fullPathInFileName = NULL;

  while (1)
  {
    int c;
    int option_index = 0;

    c = getopt_long(argc, argv, "hi:v", long_options, &option_index );

    if ( c == -1 )
      break;

    switch ( c )
    {
      case 'h':
        printhelp(argv[0]);
        exitcode = EXIT_SUCCESS;
        break;
      case 'v':
        verbose = true;
        break;
      default:
        printf( " getopt switch got unknown switch: %d\n", c );
        printhelp(argv[0]);
        exitcode = EXIT_FAILURE;
        break;
    }
  }

  if ( optind < argc )
  {
    fullPathInFileName = strdup(argv[optind++]);

  }
  else
  {
    puts("");
    puts( "Expected miriad data set as option!" );
    printhelp(argv[0]);
    exitcode = EXIT_FAILURE;
  }

  if ( optind < argc )
  {
    printf( "Ignoring remaining args passed on command-line:\n" );
    while ( optind < argc )
    {
      printf( "\t%s\n", argv[optind++] );
    }
  }

  if ( verbose )
  {
    if ( fullPathInFileName != NULL )
      fprintf( stderr, " stat('%s',...)\n", fullPathInFileName );
  }




  return( exitcode );
}

// vim: set expandtab sw=2 ts=2 cindent
