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

#include <stdio.h>
#include "dtm.h"
#include "vdata.h"

#ifndef MALLOC
#define MALLOC(x)	malloc(x)
#define FREE(x)		free(x)
#endif

#ifdef DTM_PROTOTYPES
int VDATAsetPath(char *header, VdataPathElement **magicPath, int pathLength)
#else
int VDATAsetPath(header,magicPath,pathLength)
char *header;
VdataPathElement **magicPath;
int pathLength;
#endif
{
int x;
char pathString[DTM_MAX_HEADER];
char idString[DTM_MAX_HEADER];
char buff[80];

	pathString[0]='\0';
	for (x=0; x < pathLength; x++) {
		strcat(pathString,magicPath[x]->nodeName);
		strcat(pathString," ");
		}

	idString[0]='\0';
	for (x=0; x < pathLength; x++) {
		sprintf(buff,"%d ",magicPath[x]->nodeID);
		strcat(idString,buff);
		}
	dtm_set_int(header,VDATApathLength,pathLength);
	dtm_set_char(header,VDATApathName,pathString);
	dtm_set_char(header,VDATApathID,idString);
	return(1);
}


#ifdef DTM_PROTOTYPES
int VDATAgetPath(char *header, VdataPathElement **magicPath, int *pathLength)
#else
int VDATAgetPath(header,magicPath,pathLength)
char *header;
VdataPathElement **magicPath;
int *pathLength;
#endif
{
char pathString[DTM_MAX_HEADER];
char pathID[DTM_MAX_HEADER];
int numPath;
int integer[10];
char pathStep[DTM_MAX_HEADER];
char *ptr;
int x;

	dtm_get_int(header,VDATApathLength,&numPath);
	dtm_get_char(header,VDATApathName,pathString,DTM_MAX_HEADER);
	dtm_get_char(header,VDATApathID,pathID,DTM_MAX_HEADER);

	numPath = (numPath > *pathLength)? (*pathLength) : numPath;
	*pathLength = numPath;

	ptr = pathID;
	for (x = 0; x < numPath; x++) {
		sscanf(ptr,"%s ",integer);
		ptr += (strlen(ptr) + 1);
		magicPath[x]->nodeID = atoi(integer);
		}

	ptr = pathString;
	for (x = 0; x < numPath; x++) {
		sscanf(ptr,"%s ",pathStep);
		ptr += (strlen(ptr) + 1);
		if (!(magicPath[x]->nodeName = (char *)
				MALLOC( strlen(pathStep) + 1))) {
			fprintf(stderr,"VDATAgetPath: Out of Memory\n");
			return(-1);
			}
		strcpy(magicPath[x]->nodeName,pathStep);
		}
	return(1);
}


