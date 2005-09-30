/*uvio.i*/
/* SWIG interface file for binding to the Miriad I/O libraries
   Author: Garrelt Mellema
   Date: 30-sept-2005
   Currently binds to:
    uvopen_c
    uvread_c
    uvprobvr_c
    uvgetvr_c
    uvclose_c
    hisopen_c
    hiswrite_c
    hisread_c
    hisclose_c
    hopen_c
    hclose_c
   Examples of how to use these bindings can be found in mirlib.py
*/
/* Compilation: 
 swig -python uvio.i
 gcc -c uvio_wrap.c -I/usr/include/python -I$MIRINC
 ld -shared -L$MIRLIB uvio_wrap.o -o _uvio.so -lmirc
*/
%module uvio
%include "cpointer.i"
%include "carrays.i"
%include "cdata.i"
%{
#include "io.h"
#include "miriad.h"
%}
extern void uvopen_c (int *tno, const char *name, const char *status);
extern void uvread_c (int tno, double *preamble, float *data, int *flags, int n, int *nread);
extern void uvprobvr_c (int tno, const char *var, char *type, int *length, int *updated);
extern void uvgetvr_c (int tno, int type, const char *var, char *data, int n);
extern void uvclose_c (int tno);
extern void hisopen_c (int tno, const char *status);
extern void hiswrite_c (int tno, const char *text);
extern void hisread_c (int tno, char *text, size_t length, int *eof);
extern void hisclose_c (int tno);
extern void hopen_c (int *tno, const char *name, const char *status, int *iostat);
extern void hclose_c (int tno);

# Pointer functions
%pointer_functions(int, intp);
%pointer_functions(float, floatp);
%pointer_functions(double, doublep);
%pointer_functions(char, charp);

# Array classes
%array_class(int, intArray);
%array_class(float, floatArray);
%array_class(double, doubleArray);
%array_class(char, charArray);
