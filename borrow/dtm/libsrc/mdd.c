/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software Data Transfer Mechanism [both binary and source (if
* released)] is in the public domain, available without fee for education,
* research, non-commercial and commercial purposes.  Users may distribute the
* binary or source code to third parties provided that this statement
* appears on all copies and that no charge is made for such copies.
* 
* UI MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY
* PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  THE
* UI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS
* SOFTWARE.  The software may have been developed under agreements between
* the UI and the Federal Government which entitle the Government to certain
* rights.
* 
* By copying this program, you, the user, agree to abide by the conditions
* and understandings with respect to any software which is marked with a
* public domain notice.
*
*****************************************************************************/


#include	<stdlib.h>
#include	<stdio.h>
#include	<string.h>

#include	"dtmint.h"
#include	"mdd.h"



#ifdef DTM_PROTOTYPES
void MDDsetDimensions(char *h,int rank,int *dims)
#else
void MDDsetDimensions(h, rank, dims)
  char	*h;
  int	rank, *dims;
#endif
{
  char	num[8];
  int	i;

  sprintf(num, "%d ", rank);
  strcat(h, MDDdims); strcat(h, " ");
  strcat(h, num);

  for (i=0; i<rank; i+=1)  {
    sprintf(num, "%d ", dims[i]);
    strcat(h, num);
    }
}


#ifdef DTM_PROTOTYPES
int MDDgetDimensions(char *h,int *rank,int *dims,int len)
#else
int MDDgetDimensions(h, rank, dims, len)
  char	*h;
  int	*rank, *dims, len;
#endif
{
  int	i;

  if ((h = dtm_find_tag(h, MDDdims)) == NULL)
    return DTMERROR;
  else
    h = strchr(h, ' ')+1;

  *rank = atoi(h);

  for (i=0; i<*rank && i<len; i+=1)
    if ((h = strchr(h, ' ')) == NULL)
      return DTMERROR;
    else
      dims[i] = atoi(++h);

  return 0;
}


#ifdef DTM_PROTOTYPES
int MDDnumElements(int rank,int *dims)
#else
int MDDnumElements(rank, dims)
  int	rank, *dims;
#endif
{
  int	size;

  size = *dims++;
  while (--rank > 0)
    size *= *dims++;

  return size;
}


#ifdef DTM_PROTOTYPES
void MDDsetMinMax(char *h,double min,double max)
#else
void MDDsetMinMax(h, min, max)
  char	*h;
  float	min, max;
#endif
{
  sprintf(h+strlen(h), "%s %e %e ", MDDminmax, min, max);
}


#ifdef DTM_PROTOTYPES
int MDDgetMinMax(char *h,float *min,float *max)
#else
int MDDgetMinMax(h, min, max)
  char	*h;
  float	*min, *max;
#endif
{

  if ((h = dtm_find_tag(h, MDDminmax)) == NULL)
    return DTMERROR;
  else
    h = strchr(h, ' ')+1;


  *min = (float)atof(h);

  h = strchr(h, ' ') + 1;
  *max = (float)atof(h);
  
  return 0;
}


#ifdef DTM_PROTOTYPES
void MDDfindMinMax(char *h,float *mdd,float *min,float *max)
#else
void MDDfindMinMax(h, mdd, min, max)
  char	*h;
  float	*mdd, *min, *max;
#endif
{
  int	i, rank, dims[10];

  MDDgetDimensions(h, &rank, dims, sizeof dims);
  rank = MDDnumElements(rank, dims);

  *min = *max = *mdd++;
  for (i=1; i<rank; mdd+=1, i+=1)
    if (*mdd < *min)
      *min = *mdd;
    if (*mdd > *max)
      *max = *mdd;
}
