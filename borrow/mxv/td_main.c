/*
 *	File:		td_main.c
 *	Contents:	Main initialization/termination routines for td module
 *
 */

#include "td_com.h"
#include "mxv.h"

#include <stdio.h>

extern	void	gr_Init();
extern	void	gr_ProcessLoop();
extern char	*td_getToolName();

#if 0
extern char *getcwd();
/* Current directory pathname. We should use a system number that gives the
maximum path length. For now, use this.

Note, some systems allow getcwd to be called with path== NULL. Others, like
the convex don't and actually return the address of pathname.
*/
/* This should be MAXPATHLEN defined in ' <sys/param.h>' (on suns). */
#ifndef MAXPATHLEN
#define MAXPATHLEN 1024
#endif
static char pathname[MAXPATHLEN];
#endif

static char mxvlogfilename[MAXPATHLEN]; /* td_logFile will point to this */


/*
 *	Initialize Miriad X Visualizer
 */
void td_Init(argc,argv)
int	argc;
char	*argv[];
{
FILE *fp;
char	msg[256];

/******************* Initialize global variables.****************/
axesLabels[0] = (char*) malloc(2);
axesLabels[1] = (char*) malloc(2);
axesLabels[2] = (char*) malloc(2);

	strcpy(axesLabels[0],"X");
	strcpy(axesLabels[1],"Y");
	strcpy(axesLabels[2],"Z");
	RA___SIN = StringToQuark("RA---SIN");
	DEC__SIN = StringToQuark("DEC--SIN");
	VELO_LSR = StringToQuark("VELO_LSR");
/****************************************************************/
/* ---- print brief credits message --- */
/*  printf ("Miriad X11 Visualizer v 1.0 July 1991\n");*/
/* mxvLog is now created in the home directory. jng nov 15 */

	if(MAXPATHLEN < 128)
		printf("Caution: Short MAXPATHLEN(%d)\n", MAXPATHLEN);

/*!!!!?? Whether/where to write/put logfile should be resources. */
	sprintf(mxvlogfilename, "%s/mxvLog",(char*) getenv("HOME"));
	td_logFile = mxvlogfilename;

	if ((fp = fopen(td_logFile,"w")) != NULL)
	{
		sprintf(msg, "Welcome to %s. Started at %s",
			td_getToolName(), td_CurrentDate());
		gr_TextInitBuff((long)strlen(msg));
		fprintf(fp,"%s",msg);
		fclose(fp);
		chmod(td_logFile,0000700|0000070|0000007);
	}
	else
	{
		fprintf(stderr,
			"Error\t: Cannot open log file %s\n",td_logFile);
		exit(1);
	}
#if 0
/* This should use 'getwd' instead. */
	if ((td_dirName = getcwd(pathname, MAXPATHLEN)) == NULL)
	{
		gr_TextMsgOut(
		  "WARNING: Cannot get current directory pathname\n");
		td_dirName = td_dirDefName;
	}
#endif
	gr_Init(argc,argv);
} /* main */


/*
 *	Entry point into Miriad X11 Visualizer.
 */
main(argc,argv)
int 	argc;
char	*argv[];
{
	td_Init(argc,argv);

	gr_ProcessLoop();

}

/*
 *	Terminate Miriad X Visualizer
 */
void
td_Terminate()
{
	exit(0);
}
