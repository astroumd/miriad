/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				Sept 20, 1990
*
* NCSA HDF Version 3.10r2 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
* 
* We ask, but do not require, that the following message be included in all
* derived works:
* 
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
* 
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
* 
*****************************************************************************/

#ifdef RCSID
static char RcsId[] = "@(#)$Revision$";
#endif
/*
$Header$

$Log$
Revision 1.1.1.1  1990/09/28 21:50:12  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.0  90/02/02  20:31:12  clow
 * *** empty log message ***
 * 
*/
/*
*  hdftopal.c
*       Version: 1.0   date: August 1, 1989
*       This utility converts a palette from an HDF file
*       to a raw palette in a raw palette file.
*       The outgoing palette will have 768 bytes: First
*       256 red values, then 256 greens, then 256 blues.
*
*  by Mike Folk
*  first version of hdftopal:   8/01/89
*
*  This program is in the public domain
*
*/

#include <stdio.h>
#include "df.h"

unsigned char palspace[1024],
			reds[256],
			greens[256],
			blues[256];


main(argc,argv) 
int argc;
char *argv[];
{
	if (argc < 3) { 
		puts("Usage:");
		printf("   %s hdffile rawpalfile \n\n", argv[0]);
        printf("%s,  version: 1.0   date: August 1, 1989\n\n",argv[0]);
    	printf("   This utility converts a palette from an HDF file \n");
    	printf("   to a raw palette in a raw palette file.\n\n");
    	printf("   The outgoing palette will have 768 bytes: First \n");
    	printf("   256 red values, then 256 greens, then 256 blues.\n\n");
		exit(1);
	}

	rawpalconv( argv[1], argv[2]);
}

/*
 *	rawpalconv(palfile, outfile) sets the palette
 */

rawpalconv( hdffile,rawpalfile)
char *hdffile, *rawpalfile;
{
	unsigned char *p;
	FILE *fp;
	int j,ret;

	ret = DFPgetpal(hdffile, palspace);
	if (ret < 0) {
		printf("\n Error in reading file %s\n\n", hdffile);
		exit(1);
	}

	p = palspace;
	for (j=0; j<256; j++) {
		reds[j]   = *p++;
		greens[j] = *p++;
		blues[j]  = *p++;
	}

	fp = fopen(rawpalfile,"w");
	if (fp==NULL) {
		printf(" Error opening raw palette file %s\n", rawpalfile);
		exit(1);
	}
	fwrite(reds,1,256,fp);
	fwrite(greens,1,256,fp);
	fwrite(blues,1,256,fp);
	fclose(fp);
	return(0);
}

