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


#include	<stdio.h>
#include	<string.h>

#include	"dtmint.h"
#include	"ris.h"


char		PAL[] = "PAL ";


#ifdef DTM_PROTOTYPES
void RISsetDimensions(char *h,int x,int y)
#else
void RISsetDimensions(h, x, y)
  char	*h;
  int	x, y;
#endif
{
  char	append[32];

  sprintf(append, "%s 2 %d %d ", RISdims, x, y);
  strcat(h, append);
}

#ifdef DTM_PROTOTYPES
int RISgetDimensions(char *h,int *x,int *y)
#else
int RISgetDimensions(h, x, y)
  char	*h;
  int	*x, *y;
#endif
{

  if ((h = dtm_find_tag(h, RISdims)) == NULL)
    return DTMERROR;
  else
    h = strchr(h, ' ')+1;

  /* skip rank */
  h = strchr(h, ' ')+1;

  *x = atoi(h);
  h = strchr(h, ' ') + 1;
  *y = atoi(h);

  return 0;
}
