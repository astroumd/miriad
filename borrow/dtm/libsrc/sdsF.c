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


#include        <stdio.h>
#include        <string.h>
#include	<fortran.h>

#include        "dtm.h"
#include        "sds.h"


extern int      atoi();
extern double   atof();
extern	char *	dtm_find_tag();



/*************************************************************************
**
** Cray version of SDS macros
**
*************************************************************************/

/* SDSsetClass */
void SDSSC(s)
  _fcd	s;
{
  strcat(strcpy(_fcdtocp(s), SDSclass), " ");
}

/* SDScompareClass */
long SDSCC(s)
  _fcd	s;
{
  return _btol(!strncmp(_fcdtocp(s), SDSclass, strlen(SDSclass)));
}


/* SDSheaderLength */
#undef SDSHL
long SDSHL(s)
  _fcd	s;
{
  return _fcdlen(s);
}


/* SDSsetType */
void SDSSDT(s, type)
  _fcd	s;
  int	*type;
{
  dtm_set_type(_fcdtocp(s), *type);
}


/* SDSgetType */
void SDSGDT(s, type)
  _fcd	s;
  int	*type;
{
  dtm_get_type( _fcdtocp(s), type);
}


/* SDSsetTitle */
void SDSST(s, t)
  _fcd  s, t;
{
  dtm_set_title(_fcdtocp(s), _fcdtocp(t));
}


/* SDSgetTitle */
void SDSGT(s, t)
  _fcd  s, t;
{
  dtm_get_title(_fcdtocp(s), _fcdtocp(t), _fcdlen(t));
}


/*************************************************************************
**
** Cray version of SDS functions
**
*************************************************************************/

/* SDSsetDimensions */
void SDSSD(s, rank, dims)
  _fcd	s;
  int   *rank, *dims;
{
  char  *h = _fcdtocp(s);
  char	num[8];
  int   i;


  sprintf(num, "%d ", *rank);
  strcat(h, SDSdims); strcat(h, " ");
  strcat(h, num);

  for (i=0; i< *rank; i+=1)  {
    sprintf(num, "%d ", dims[i]);
    strcat(h, num);
    }
}

/* SDSgetDimensions */
int SDSGD(s, rank, dims, len)
  _fcd	s;
  int   *rank, *dims, *len;
{
  char	*h = _fcdtocp(s);
  int   i;


  if ((h = dtm_find_tag(h, SDSdims)) == NULL)
    return DTMERROR;
  else
    h = strchr(h, ' ')+1;

  *rank = atoi(h);

  for (i=0; i<*rank && i<*len; i+=1)
    if ((h = strchr(h, ' ')) == NULL)
      return DTMERROR;
    else
      dims[i] = atoi(++h);

  return 0;
}


/* SDSsetMinMax */
void SDSSMM(s, min, max)
  _fcd	s;
  float *min, *max;
{
  char  *h = _fcdtocp(s);

  sprintf(h+strlen(h), "%s %e %e ", SDSminmax, *min, *max);
}


/* SDSgetMinMax */
long SDSGMM(s, min, max)
  _fcd	s;
  float *min, *max;
{
  char	*h = _fcdtocp(s);

  if ((h = dtm_find_tag(h, SDSminmax)) == NULL)
    return _btol(0);
  else
    h = strchr(h, ' ')+1;


  *min = atof(h);

  h = strchr(h, ' ') + 1;
  *max = atof(h);

  return _btol(1);
}


/* SDSnumElements */
long SDSNE(rank, dims)
  int	*rank, *dims;
{
  int   size;

  size = *dims++;
  while (--(*rank) > 0)
    size *= *dims++;

  return size;
}
