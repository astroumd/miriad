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


/*
 * PALETTE constants and macros
 */
#define	PALclass	"PAL"
#define PALelements	"PE"
#define	PALsize		128

#define	PALsetClass(h)		dtm_set_class(h, PALclass)
#define	PALcompareClass(h)	dtm_compare_class(h, PALclass)

#define PALsetSize(h, s)	dtm_set_int((h), PALelements, (s))
#define PALgetSize(h, s)	((*(s)=(int)256), \
				 (dtm_get_int((h), PALelements, (s))))

/*
 * PALETTE rename macros
 */
#define PALheaderLength		dtm_header_length
#define PALHL			dtm_header_length

#define PALsetTitle		dtm_set_title
#define PALgetTitle		dtm_get_title



/*
 * RASTER IMAGE constants and macros
 */


/*
 * standard image types: 8 bit colormap entries or 24-bit RGB entries.
 */
typedef	enum {
	RIS8BIT = 0,
	RIS24BIT
} RISTYPE;

#define	RISclass	"RIS"
#define RIStype		"RT"
#define	RISdims		"DIM"
#define RISpalette	"APN"
#define RISsize		256

#define RISsetClass(h)		dtm_set_class(h, RISclass)
#define	RIScompareClass(h)	dtm_compare_class(h, RISclass)

#define RISsetType(h, t)	((dtm_set_int((h), RIStype, (t))), \
				 (dtm_set_type((h), DTM_CHAR)))
#define RISgetType(h, t)	((*(t)=(int)RIS8BIT), \
				 (dtm_get_int((h), RIStype, (int *)(t))))

/*
 * RIS rename macros
 */
#define RISheaderLength		dtm_header_length
#define RISHL			dtm_header_length

#define RISsetTitle		dtm_set_title
#define RISgetTitle		dtm_get_title

#define RISsetPaletteName(h, c)		dtm_set_char((h), RISpalette, (c))
#define RISgetPaletteName(h, c, l)	dtm_get_char((h), RISpalette, (c), (l))
