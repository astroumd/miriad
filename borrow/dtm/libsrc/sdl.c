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

#include	"dtm.h"
#include	"sdl.h"


#ifdef DTM_PROTOTYPES
void SDLsetBoundingBox(char *header, float *min, float *max)
#else
void SDLsetBoundingBox(header, min, max)
char		*header;
float		*min, *max;
#endif
{
   sprintf(header+strlen(header), "%s %e %e %e %e %e %e ",
	SDLbounds, min[0], min[1], min[2], max[0], max[1], max[2]);

}


#ifdef DTM_PROTOTYPES
int SDLgetBoundingBox(char *header, float *min, float *max)
#else
int SDLgetBoundingBox(header, min, max)
char            *header;
float           *min, *max;
#endif
{
   int   i;

   if ((header = dtm_find_tag(header, SDLbounds)) == NULL)
      return DTMERROR;

   for (i=0; i<3; i+=1)
      if ((header = strchr(header, ' ')) == NULL)
         return DTMERROR;
      else
         min[i] = atof(++header);

   for (i=0; i<3; i+=1)
      if ((header = strchr(header, ' ')) == NULL)
         return DTMERROR;
      else
         max[i] = atof(++header);

   return 0;
}
