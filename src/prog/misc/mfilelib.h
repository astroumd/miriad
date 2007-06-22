/* $Id$ */
#ifndef SRC_PROG_MISC_MFILELIB_H
#define SRC_PROG_MISC_MFILELIB_H

#include <time.h>

typedef struct _mirInfoDesc
{
  char *fileName;
  char *type;
  time_t start;
  time_t end;
} mirInfoDesc;

char *getMiriadDataType( int mirfd );
void printMirInfoDesc( mirInfoDesc *desc );
void printCSVMirInfoDesc( mirInfoDesc *desc );


#endif // SRC_PROG_MISC_MFILELIB_H
