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
**
**  Database Message Headers
**
**
*/

#define	DBclass			"DB"
#define	DBsize			1024

#define	DBfile			"DBF"
#define	DBauthor		"AUTH"
#define	DBscience		"SCI"
#define DBtitle			"TITLE"
#define	DBdatatype		"DT"
#define	DBkeywords		"KEYS"

#define	DBrecsize		"RS"
#define	DBmatch			"MATCH"


#define	DBsetClass(h)		DTMsetClass(h, DBclass)
#define	DBcompareClass(h)	DTMcompareClass(h, DBclass)

#define DBsetDB(h, s)		dtm_set_char(h, DBfile, s)
#define	DBgetDB(h, s, l)	dtm_get_char(h, DBfile, s, l)

#define DBsetAuthor(h, s)	dtm_set_char(h, DBauthor, s)
#define	DBgetAuthor(h, s, l)	dtm_get_char(h, DBauthor, s, l)

#define DBsetTitle(h, s)	dtm_set_char(h, DBtitle, s)
#define	DBgetTitle(h, s, l)	dtm_get_char(h, DBtitle, s, l)

#define DBsetScience(h, s)	dtm_set_char(h, DBscience, s)
#define	DBgetScience(h, s, l)	dtm_get_char(h, DBscience, s, l)

#define	DBsetKeywords(h, s)	dtm_set_char(h, DBkeywords, s)
#define	DBgetKeywords(h, s, l)	dtm_get_char(h, DBkeywords, s, l)

#define	DBsetDatatype(h, s)	dtm_set_char(h, DBdatatype, s)
#define	DBgetDatatype(h, s, l)	dtm_get_char(h, DBdatatype, s, l)

#define	DBsetRecordSize(h, i)	dtm_set_int(h, DBrecsize, i)
#define	DBgetRecordSize(h, ip)	dtm_get_int(h, DBrecsize, ip)

#define	DBsetMatches(h, i)	dtm_set_int(h, DBmatch, i)
#define	DBgetMatches(h, ip)	dtm_get_int(h, DBmatch, ip)
