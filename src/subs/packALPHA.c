/************************************************************************/
/*									*/
/*  The pack routines -- these convert between the host format and	*/
/*  the disk format. Disk format is IEEE 32 and 64 bit reals, and 2's	*/
/*  complement integers. Byte order is the FITS byte order (most	*/
/*  significant bytes first).						*/
/*									*/
/*  This version is for a machine which uses IEEE internally, but which	*/
/*  uses least significant bytes first (little endian), e.g. PCs and	*/
/*  Alphas.								*/
/*									*/
/*  History:								*/
/*    rjs  21nov94 Original version.					*/
/************************************************************************/
void pack16_c(in,out,n)
char *out;
int *in,n;
/*
  Pack an integer array into 16 bit integers.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)in;
  for(i=0; i < n; i++){
    *out++ = *(s+1);
    *out++ = *s;
    s += sizeof(int);
  }
}
/************************************************************************/
void unpack16_c(in,out,n)
int *out,n;
char *in;
/*
  Unpack an array of 16 bit integers into integers.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)out;
  for(i=0; i < n; i++){
    *s++ = *(in+1);
    *s++ = *in;
    if(0x80 & *in){
      *s++ = 0xFF;
      *s++ = 0xFF;
    } else {
      *s++ = 0;
      *s++ = 0;
    }
    in += 2;
  }
}
/************************************************************************/
void pack32_c(in,out,n)
int *in,n;
char *out;
/*
  Pack an array of integers into 32 bit integers.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)in;
  for(i = 0; i < n; i++){
    *out++ = *(s+3);
    *out++ = *(s+2);
    *out++ = *(s+1);
    *out++ = *s;
    s += 4;
  }
}
/************************************************************************/
void unpack32_c(in,out,n)
int *out,n;
char *in;
/*
  Unpack an array of 32 bit integers into integers.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)out;
  for(i = 0; i < n; i++){
    *s++ = *(in+3);
    *s++ = *(in+2);
    *s++ = *(in+1);
    *s++ = *in;
    in += 4;
  }
}
/************************************************************************/
void packr_c(in,out,n)
int n;
float *in;
char *out;
/*
  Pack an array of reals into IEEE reals -- just do byte reversal.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)in;
  for(i = 0; i < n; i++){
    *out++ = *(s+3);
    *out++ = *(s+2);
    *out++ = *(s+1);
    *out++ = *s;
    s += 4;
  }
}
/************************************************************************/
void unpackr_c(in,out,n)
char *in;
float *out;
int n;
/*
  Unpack an array of IEEE reals into reals -- just do byte reversal.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)out;
  for(i = 0; i < n; i++){
    *s++ = *(in+3);
    *s++ = *(in+2);
    *s++ = *(in+1);
    *s++ = *in;
    in += 4;
  }
}
/************************************************************************/
void packd_c(in,out,n)
double *in;
char *out;
int n;
/*
  Pack an array of doubles -- this involves simply performing byte
  reversal.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)in;
  for(i = 0; i < n; i++){
    *out++ = *(s+7);
    *out++ = *(s+6);
    *out++ = *(s+5);
    *out++ = *(s+4);
    *out++ = *(s+3);
    *out++ = *(s+2);
    *out++ = *(s+1);
    *out++ = *s;
    s += 8;
  }
}
/************************************************************************/
void unpackd_c(in,out,n)
char *in;
double *out;
int n;
/*
  Unpack an array of doubles -- this involves simply performing byte
  reversal.
------------------------------------------------------------------------*/
{
  int i;
  char *s;

  s = (char *)out;
  for(i = 0; i < n; i++){
    *s++ = *(in+7);
    *s++ = *(in+6);
    *s++ = *(in+5);
    *s++ = *(in+4);
    *s++ = *(in+3);
    *s++ = *(in+2);
    *s++ = *(in+1);
    *s++ = *in;
    in += 8;
  }
}
