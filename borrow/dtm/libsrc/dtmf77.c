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
#include	<fortran.h>
#include	"dtm.h"



#ifdef DTM_PROTOTYPES
int DTMMIP(_fcd s)
#else
int DTMMIP(s)
  _fcd	s;
#endif
{
  int	len;
  char	portname[128];

  len = _fcdlen(s);
  strncpy(portname, _fcdtocp(s), len);
  portname[len] = '\0';

  return DTMmakeInPort(portname, DTM_DEFAULT);
}


#ifdef DTM_PROTOTYPES
int DTMMOP(_fcd s)
#else
int DTMMOP(s)
  _fcd	s;
#endif
{
  int	len;
  char	portname[128];

  len = _fcdlen(s);
  strncpy(portname, _fcdtocp(s), len);
  portname[len] = '\0';

  return DTMmakeOutPort(portname, DTM_DEFAULT);
}


#ifdef DTM_PROTOTYPES
int DTMGPA(int *p,_fcd s,int *len)
#else
int DTMGPA(p, s, len)
  int	*p, *len;
  _fcd	s;
#endif
{  
  char	portaddr[128];


  if (DTMgetPortAddr(*p, portaddr, sizeof portaddr) == DTMERROR)
    return DTMERROR;

  if (strlen(portaddr) > *len)  {
    strncpy(_fcdtocp(s), portaddr, *len); 
    return DTMERROR;
    }

  else  {
    strncpy(_fcdtocp(s), portaddr, strlen(portaddr));
    return 0;
    }
}


#ifdef DTM_PROTOTYPES
int DTMAR(int *p)
#else
int DTMAR(p)
  int	*p;
#endif
{
  return DTMavailRead(*p);
}


#ifdef DTM_PROTOTYPES
int DTMBR(int *p,_fcd header,int *size)
#else
int DTMBR(p, header, size)
  int		*p, *size;
  _fcd		header;
#endif
{

  return DTMbeginRead(*p, _fcdtocp(header), *size);
}


#ifdef DTM_PROTOTYPES
int DTMRD(int *p,char *ds,int *size,DTMTYPE *type)
#else
int DTMRD(p, ds, size, type)
  int		*p, *size;
  char		*ds;
  DTMTYPE	*type;
#endif
{
  return DTMreadDataset(*p, ds, *size, *type);
}


#ifdef DTM_PROTOTYPES
int DTMER(int *p)
#else
int DTMER(p)
  int	*p;
#endif
{
  return DTMendRead(*p);
}


#ifdef DTM_PROTOTYPES
int DTMAW(int *p)
#else
int DTMAW(p)
  int		*p;
#endif
{
  return DTMavailWrite(*p);
}


#ifdef DTM_PROTOTYPES
int DTMWM(int *p,_fcd header,int *hsize, char *ds, int *dsize, DTMTYPE *type)
#else
int DTMWM(p, header, hsize, ds, dsize, type)
  int		*p, *hsize, *dsize;
  _fcd		header;
  char		*ds;
  DTMYTPE	*type;
#endif
{
  int   len;
  char  buffer[DTM_MAX_HEADER];

  len = _fcdlen(header);
  strncpy(buffer, _fcdtocp(header), len);
  buffer[len] = '\0';

  return DTMwriteMsg(*p, buffer, len+1, ds, *dsize, *type);
}

#ifdef DTM_PROTOTYPES
int DTMBW(int *p,_fcd header,int *size)
#else
int DTMBW(p, header, size)
  int		*p, *size;
  _fcd		header;
#endif
{
  int	len;
  char	buffer[DTM_MAX_HEADER];

  len = _fcdlen(header);
  strncpy(buffer, _fcdtocp(header), len);
  buffer[len] = '\0';
  
  return DTMbeginWrite(*p, buffer, len+1);
}


#ifdef DTM_PROTOTYPES
int DTMWD(int *p,char *ds,int *size,DTMTYPE *type)
#else
int DTMWD(p, ds, size, type)
  int		*p, *size;
  char		*ds;
  DTMTYPE	*type;
#endif
{
  return DTMwriteDataset(*p, ds, *size, *type);
}


#ifdef DTM_PROTOTYPES
int DTMEW(int *p)
#else
int DTMEW(p)
  int		*p;
#endif
{
  return DTMendWrite(*p);
}
