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
* released)] is * in the public domain, available without fee for education,
* research, non-commercial and commercial purposes.  Users may distribute the
* binary or * source code to third parties provided that this statement
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
#include	<sys/types.h>
#include	<netinet/in.h>

#include	"dtmint.h"
#include	"debug.h"


static int dtm_char(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{
  DBGFLOW("# dtm_char called.\n");

  return size;
}


static int dtm_short(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{
  DBGFLOW("# dtm_short called.\n");

  return ((mode == DTMLOCAL) ? (size / 2) : (size * 2));
}


static int dtm_int(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{

  DBGFLOW("# dtm_int called.\n");

  return ((mode == DTMLOCAL) ? (size / 4) : (size * 4));
}


static int dtm_float(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{

  DBGFLOW("# dtm_float called.\n");

  return ((mode == DTMLOCAL) ? (size / 4) : (size * 4));
}


static int dtm_double(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{

  DBGFLOW("# dtm_flt64 called.\n");

  return ((mode == DTMLOCAL) ? (size / 8) : (size * 8));
}


static int dtm_complex(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{

  DBGFLOW("# dtm_complex called.\n");

  return ((mode == DTMLOCAL) ? (size / 8) : (size * 8));
}


static int dtm_triplet(mode, buf, size)
  int	mode, size;
  VOIDPTR	buf;
{

  DBGFLOW("# dtm_triplet called.\n");

  return  ((mode == DTMLOCAL) ? (size / 16) : (size * 16));
}


/* conversion routine function table */
int	(*DTMconvertRtns[])() = {
		dtm_char,
                dtm_short,
                dtm_int,
                dtm_float,
                dtm_double,
                dtm_complex,
		dtm_triplet
		};
