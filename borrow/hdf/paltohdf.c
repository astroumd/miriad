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
static char RcsId[] = "@(#) $Revision$"
#endif
/*
$Header$

$Log$
Revision 1.1  1990/09/28 21:50:13  teuben
Initial revision

 * Revision 3.1  90/07/02  10:58:31  clow
 * some cosmetic modifications
 * 
*/
/*
*  paltohdf.c
*       Version: 1.0   date: August 1, 1989
*       This utility converts a raw palette to hdf format 
*       The incoming palette is assumed to have 768 bytes:
*          256 red values, 256 greens, and 256 blues.
*          The palette in the HDF file will have the RGB values
*          interlaced: RGB RGB ... (This is standard HDF format.)
*
*  by Mike Folk
*  first version of paltohdf:   8/01/89
*
*  This program is in the public domain
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
		printf("   %s rawpalfile hdffile \n\n", argv[0]);
        printf("%s,  version: 1.0   date: August 1, 1989\n\n",argv[0]);
    	printf("   This utility converts a raw palette to hdf format \n\n");
    	printf("   The incoming palette is assumed to have 768 bytes:\n");
    	printf("   256 red values, 256 greens, and 256 blues.\n\n");
    	printf("   The palette in the HDF file will have the RGB values\n");
    	printf("   interlaced: RGB RGB ... (This is standard HDF format.\n\n");
		exit(1);
	}

	palconv( argv[1], argv[2]);
}

/*
 *	palconv(palfile, outfile) sets the palette
 */

palconv( palfile,outfile)
char *palfile, *outfile;
{
	unsigned char *p;
	FILE *fp;
	int j,ret;

	fp = fopen(palfile,"r");
	if (fp==NULL) {
		printf(" Error opening palette file %s\n", palfile);
		exit(1);
	}
	fread(reds,1,256,fp);
	fread(greens,1,256,fp);
	fread(blues,1,256,fp);
	fclose(fp);

	p = palspace;
	for (j=0; j<256; j++) {
		*p++ = reds[j];
		*p++ = greens[j];
		*p++ = blues[j];
	}

	ret = DFPaddpal(outfile, palspace);
	if (ret < 0) {
		printf(" Error: %d, in writing palette %s\n",ret, palfile);
		exit(1);
	}
	return(0);
}

