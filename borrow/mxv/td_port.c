/*
 *	File:		td_port.c
 *	Contents:	Ports of variables outside td module
 *
 */
#if defined (SYSV) && defined (sun)
#define rindex(a,b)  strrchr((a),(b))
#define  index(a,b)  strchr ((a),(b))
#endif

#include "td_com.h"
#include "version.h"
#include <string.h>
#ifndef __convex__
#if ! defined (sun) && ! defined (SYSV)
#include <strings.h>
#endif
#include <netdb.h>
#endif
#include <sys/param.h>

char *ctime();

#define	CLASS_NAME	"Mxv"

/* Short/Long names we go by. */
static	char	*td_ResourceName=NULL;		/* Set to name of pgm. */
static	char	*td_ClassName= CLASS_NAME;

/* Format string. */
static	char	*td_toolName="Miriad X11 Visualizer (%s)";

static char name[128];	/* Space for name + version. */
static char version[80];
static Boolean have_version=FALSE;

/* Return pointer to version string with 'V'. */
char *td_getVersion()
{
	if(!have_version)
	{	/* If not 'experimental, ignore the edit/status part. */
		if(strcmp(STATUS, " ") != 0)
			sprintf(version, "V%d.%d.%d%s",
					MAJOR, MINOR, EDIT, STATUS);
		else
			sprintf(version, "V%d.%d", MAJOR, MINOR);

		have_version = TRUE;
	}
	return(version);
}

/* Return 'short name'.
If class is true, return class name, otherwise, return program name.
*/
char *td_getShortToolName(class)
Boolean	class;
{
	return (class) ? CLASS_NAME: td_ResourceName;
}

/* Set the resource name w/o any leading path components.
*/
void td_setShortToolName(name)
char	*name;
{
char	*n;

	n = strrchr(name, '/');
	td_ResourceName = (n != NULL) ? n+1 : name;
}

/* Full mxv name. */
char *td_getToolName()
{
char	buf[128];

	sprintf(buf, td_toolName, td_getShortToolName(TRUE));
	sprintf(name, "%s %s", buf, td_getVersion());
	return(name);
}

char *td_getLogFileName()
{
	return(td_logFile);
}

char *td_CurrentDate()
{
	long lntime;
	char *chtime;

	lntime = time((long *)0);
	chtime = ctime(&lntime);

	return(chtime);
}

long td_CurrentTime()
{
	return(time((long *)0));
}

/* Return hostname. Return is a pointer to a statically allocated array.
*/

char * td_Hostname()
{
int	error;
static char hostname[MAXHOSTNAMELEN+1], *p;
static Boolean havehostname = FALSE;

	if(! havehostname)
	{	error = gethostname(hostname, MAXHOSTNAMELEN +1 );
		if(error != 0)
		{	perror("td_HostName:Error reading host name");
			strcat(hostname, "UnknownHost");
		}
		else	/* Remove any domain name. */
		if( (p = index(hostname, '.')) != NULL)
			*p = '\0';
		havehostname = TRUE;
	}
	return hostname;
}
