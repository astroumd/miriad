/*
 * Program:	version.c
 *
 * Usage:	version
 *
 * This program calls the DTM function "dtm_version" to print the current
 * version of the DTM library.
 */

#include <stdio.h>
#include <stdlib.h>
#include <dtm.h>


main(int argc, char *argv[])
{
	dtm_version();
	printf("\n");

	return(0);
}
