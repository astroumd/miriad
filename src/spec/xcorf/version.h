/*
 *	<version.h> - Define current version of XCORF.
 *	01Apr94 jm  Original version.
 *	01Aug94 jm  Modified to include velocity information and added
 *                  ability to select restfqs in channel region.
 *	08Sep94 jm  Modified to properly handle auto-corr mode.
 *      10Nov94 jm  Modified to reflect change to setcorr inputs.  No
 *                  more coropt; instead use coptions.
 *      23Oct95 jm  Modified to write out non-set rest frequencies
 *                  (when at least one exists).  Also changed lower
 *                  limit of IF and CORF frequencies from 70 to 90 MHz.
 *      22Nov96 jm  Corrected the way doppler corrections are done.
 *                  Also added birdie keyword and updated help items.
 *      10dec96 jm  Fixed a fixed string bug which caused a SEGV dump.
 *                  Also corrected a sscanf of a double in work.c.
 *      28feb97 jm  Added a check to see that a filename was actually
 *                  selected from the file browser.
 *      07oct97 jm  Added command line option to pick 1mm/3mm.
 */
#define VERSION "Version 1.8 (07-oct-97)"
