
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
  printf( "\"%s\",\"%s\",", desc->fileName, desc->type );
  printf( "\"%s\",\"%s\",", desc->instrument, desc->telescope );
  printf( "\"%s\",\"%s\",", desc->source, desc->observer );
  printf( "\"%s\",\"%s\"\n", desc->start_str, desc->end_str );
}

void julianDayToStr ( double julianDay, char *str, int len )
{
  // This algorithm for converting from julianday to
  // string swiped from my_uvlist in uvio.c
  // TODO: move this into a C library as part of
  // libmir_uvio?
  int z,a,b,c,d,e,alpha,month,year,day,hr,minute,sec;
  int dsec,nchar;
  char string[100];
  double f;

  static char *M[] = {
    "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
    "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
  };

  z = (int)(julianDay + 0.5 + (1.0/1728000.0));
  f = julianDay + 0.5 + (1.0/1728000.0) - z;
  if ( z < 2299161 )
  { 
    a=z;
  }
  else
  {
    alpha = (int)(((z - 1867216.25) / 36524.25));
    a = (int)(z + 1 + alpha - (int)(0.25 * alpha));
  }
  b = a + 1524;
  c = (int)((b - 122.1) / 365.25);
  d = (int)(365.25 * c);
  e = (int)((b - d) / 30.6001);
  f += (int)((b - d - (int)(30.6001 * e)));
  day = (int)(f);         
  hr = (int)(24 * (f - day));
  minute = (int)(60 * (24 * (f - day) - hr));
  sec = (int)(600 * (60 * (24 * (f - day) - hr) - minute));
  dsec = sec % 10; sec /= 10;
  month = (e<=13) ? e - 1 : e - 13;
  year = (month>2) ? c - 4716 : c - 4715;
  year %= 100;
  snprintf( str, len, "%2.2d %s %2.2d %2.2d:%2.2d:%2.2d.%1d",
      year,M[month-1],day,hr,minute,sec,dsec);
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

  if ( strcmp( mid.type, "visdata" ) == 0 )
  {

    if ( mfile_verbose )
      fprintf( stderr, " gathering visdata\n" );

    int uvfd;
    if ( mfile_verbose )
      fprintf( stderr, " uvopen_c(...,'%s',...)\n", mid.fileName );
    uvopen_c( &uvfd, mid.fileName, "old" );

    if ( mfile_verbose )
      fprintf( stderr, " uvnext_c(%d)\n", uvfd );
    uvnext_c( uvfd );

    mid.instrument = new char[80];
    mid.telescope = new char[80];
    mid.source = new char[80];
    mid.observer = new char[80];

    uvrdvra_c( uvfd, "instrume", mid.instrument, "N/A", 79);
    uvrdvra_c( uvfd, "telescop", mid.telescope, "N/A", 79);
    uvrdvra_c( uvfd, "source", mid.source, "N/A", 79);
    uvrdvra_c( uvfd, "observer", mid.observer, "N/A", 79);

    mid.start_str = new char[80];
    mid.end_str = new char[80];
    char *julianStartBytes = new char[sizeof(double)];
    uvrdvrd_c( uvfd, "time", julianStartBytes, "0.0");
    double julianDay;
    memcpy(&julianDay, julianStartBytes, sizeof(double));
    julianDayToStr( julianDay, mid.start_str, 79 );


  }

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
