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


#define	SDSclass		"SDS"
#define SDSsize			256

/* SDS specific tags */
#define SDSdims			"DIM"
#define SDSminmax		"MM"


/* SDS specific macros */
#define SDSsetClass(h)			dtm_set_class(h, SDSclass)
#define SDScompareClass(h)		dtm_compare_class(h, SDSclass)

/* SDS rename macros */
#define SDSheaderLength			dtm_header_length
#define	SDSHL				dtm_header_length

#define SDSsetType			dtm_set_type
#define	SDSgetType			dtm_get_type

#define SDSsetTitle			dtm_set_title
#define SDSgetTitle			dtm_get_title

/* SDS routines */

#ifdef __cplusplus
extern "C" {
#endif

extern void SDSsetDimensions    PROTO(( char* h, int rank, int *dims ));
extern int SDSgetDimensions     PROTO(( char* h, int * rank, int* dims, 
									int len ));
extern int SDSgetRank           PROTO(( char* h, int * rank ));
extern int SDSnumElements       PROTO(( int rank, int *dims ));
extern void SDSsetMinMax        PROTO(( char* h, double min, double max));
extern int SDSgetMinMax         PROTO(( char* h, float* min, float* max));

#ifdef __cplusplus
};
#endif
