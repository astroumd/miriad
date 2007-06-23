/* $Id$ */
#ifndef SRC_PROG_MISC_MFILELIB_H
#define SRC_PROG_MISC_MFILELIB_H

#include <time.h>

typedef struct _mirInfoDesc
{
  const char *fileName;
  const char *type;
  char *instrument;
  char *telescope;
  char *source;
  char *observer;
  char *start_str;
  char *end_str;
  time_t start;
  time_t end;
} mirInfoDesc;

char *getMiriadDataType( int mirfd );
void printMirInfoDesc( mirInfoDesc *desc );
void printCSVMirInfoDesc( mirInfoDesc *desc );
void julianDayToStr( double julianDay, char *str, int len );


#endif // SRC_PROG_MISC_MFILELIB_H
