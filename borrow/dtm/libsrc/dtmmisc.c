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


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#ifdef _ARCH_MSDOS
#include <nmpcip.h>
#else
#include <netdb.h>
#include <netinet/in.h>
#endif

#include "dtmint.h"
#include "debug.h"

#ifndef min
#define		min(a, b)	(((a) <= (b)) ? (a) : (b))
#endif


/*************************************************************************
**
**  Header Utilitiy Functions
**
**************************************************************************/

#ifdef DTM_PROTOTYPES
void dtm_set_char(char *h,char *tag,char *s)
#else
void dtm_set_char(h, tag, s)
  char	*h, *tag, *s;
#endif
{

  strcat(h, tag);  strcat(h, " '");
  strcat(h, s);    strcat(h, "' ");
}


#ifdef DTM_PROTOTYPES
void dtm_set_int(char *h,char *tag,int x)
#else
void dtm_set_int(h, tag, x)
  char	*h, *tag;
  int	x;
#endif
{
  char	num[16];

  strcat(h, tag);  strcat(h, " ");

  sprintf(num, "%d ", x);
  strcat(h, num);
}


#ifdef DTM_PROTOTYPES
void dtm_set_float( char * h, char * tag, double x)
#else
void dtm_set_float(h, tag, x)
  char	*h, *tag;
  float	x;
#endif
{
  sprintf(h+strlen(h), "%s %e ", tag, x);
}


#ifdef DTM_PROTOTYPES
char *dtm_find_tag(char *h,char *tag)
#else
char *dtm_find_tag(h, tag)
  char	*h, *tag;
#endif
{
  int	len;

  len = strlen(tag);

  while ((h = strchr(h, ' ')) != NULL)  {
    h++;
    if (!strncmp(h, tag, len) && *(h+len) == ' ')
      return h;
    }

  return NULL;
}


#ifdef DTM_PROTOTYPES
int dtm_get_char(char *h,char *tag,char *s,int l)
#else
int dtm_get_char(h, tag, s, l)
  char	*h, *tag, *s;
  int	l;
#endif
{

  /* set NULL string incase tag does not exist */
  *s = '\0';

  /* decrement length to save space for final NUL */
  l -= 1;

  /* no tag return error */
  if ((h = dtm_find_tag(h, tag)) == NULL)
    return DTMERROR;

  /* no field available, return error */
  if ((h = strchr(h, '\'')) == NULL)
    return DTMERROR;
  else
    h += 1;

  if ((tag = strchr(h, '\'')) == NULL)  {
    strncpy(s, h, min((int)strlen(h)+1, l));
    *(s+min((int)strlen(h)+1, l)) = '\0';
    }
  else  {
    strncpy(s, h, min(tag-h, l));
    *(s+min(tag-h, l)) = '\0';
    }

  return 0;
}


#ifdef DTM_PROTOTYPES
int dtm_get_int(char *h,char *tag,int *x)
#else
int dtm_get_int(h, tag, x)
  char	*h, *tag;
  int	*x;
#endif
{

  /* no tag return error */
  if ((h = dtm_find_tag(h, tag)) == NULL)
    return DTMERROR;

  /* no field available, return error */
  if ((h = strchr(h, ' ')) == NULL)
    return DTMERROR;
  else
    h += 1;

  *x = atoi(h);

  return 0;
}


#ifdef DTM_PROTOTYPES
int dtm_get_float(char *h,char *tag,float *x)
#else
int dtm_get_float(h, tag, x)
  char	*h, *tag;
  float	*x;
#endif
{

  /* no tag return error */
  if ((h = dtm_find_tag(h, tag)) == NULL)
    return DTMERROR;

  /* no field available, return error */
  if ((h = strchr(h, ' ')) == NULL)
    return DTMERROR;
  else
    h += 1;

  *x = atof(h);

  return 0;
}


#ifdef  NONO
#ifdef DTM_PROTOTYPES
void DTMsetType(char *h,DTMTYPE type)
#else
void DTMsetType(h, type)
  char		*h;
  DTMTYPE	type;
#endif
{
  char	num[8];

  strcat(h, DTMtype); strcat(h, " ");

  sprintf(num, "%d ", type);
  strcat(h, num);
}


#ifdef DTM_PROTOTYPES
DTMTYPE DTMgetType(char *h)
#else
DTMTYPE DTMgetType(h)
  char	*h;
#endif
{
  char	*f;

  if ((f = dtm_find_tag(h, DTMtype)) != NULL)
    return (DTMTYPE)atoi(f);
  else
    return DTM_FLOAT;
}


#ifdef DTM_PROTOTYPES
void DTMsetGroup(char *h,DTMCMD cmd,char *parent,char *self)
#else
void DTMsetGroup(h, cmd, parent, self)
  char		*h, *parent, *self;
  DTMCMD	cmd;
#endif
{
  char		num[12];

  strcat(h, "GRP ");
  sprintf(num, "%d ", (int)cmd);
  strcat(h, num);
  if (parent != NULL)
    strcat(h, parent);
  strcat(h, " ");
  if (self != NULL)
    strcat(h, self);
  strcat(h, " ");
}


#ifdef DTM_PROTOTYPES
int DTMgetGroup(char *h,DTMCMD cmd,char *parent,char *self)
#else
int DTMgetGroup(h, cmd, parent, self)
  char		*h, *parent, *self;
  DTMCMD	*cmd;
#endif
{
  int		len;

  *self = *parent = '\0';

  if ((h = dtm_find_tag(h, "GRP")) == NULL)
    return DTMERROR;

  h = strchr(h, ' ')+1;

  /* get DTM command */
  *cmd = (DTMCMD)atoi(h);
  h = strchr(h, ' ')+1;

  /* get parent name */
  if (*h != ' ')  {
    len = strchr(h, ' ')-h;
    strncpy(parent, h, len);
    *(parent+len) = '\0';
    }
  else
    *parent = '\0';
  
  h = strchr(h, ' ')+1;

  /* get self name */
  if (*h != ' ')  {
    len = strchr(h, ' ')-h;
    strncpy(self, h, len);
    *(self+len) = '\0';
    }
  else
    *self = '\0';

  return 1;
}
#endif
