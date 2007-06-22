/* $Id$ */
#ifndef SRC_PROG_MISC_MFILELIB_H
#define SRC_PROG_MISC_MFILELIB_H

typedef struct _mirInfoDesc
{
  char *fileName;
  char *type;
} mirInfoDesc;

char *getMiriadDataType( int mirfd );
void printMirInfoDesc( mirInfoDesc *desc );
void printCSVMirInfoDesc( mirInfoDesc *desc );


#endif // SRC_PROG_MISC_MFILELIB_H
