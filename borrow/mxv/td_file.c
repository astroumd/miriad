/*
 *	File:		td_file.c
 *	Contents:	Unix file routines
 *
 */

#include <stdio.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/stat.h>
#include <pwd.h>
#include <string.h>
#include <dirent.h>
#include "td_com.h"
#include "gr_com.h"

#define MAXDIRENTRIES	300	/* Default max # of directory entries. */
/* maxdirentries and ignorefiletype are set in td_setMaxDirEntries before
being used.
*/
static int maxdirentries;	/* Max # of directory entries. */
/* During directory sorts, do we ignore the file type char or include it?
   If its ignored, the directory is listed alphabetically. If its not ignored,
   subdirectories are listed before plain files.
*/
static Boolean ignorefiletype;

extern	void	gr_TextInitBuff();


/* Set the maxdirentries variable. Called from gr_InitFileLevel only.
W is the widget used for getting resources.
*/
void td_setMaxDirEntries(w)
Widget	w;
{
	maxdirentries = gr_GetIntResource(w, "maxDirEntries",
		"MaxDirEntries", MAXDIRENTRIES);
	/* We have to have something. */
	if(maxdirentries <= 0)
		maxdirentries = MAXDIRENTRIES;
	ignorefiletype = gr_GetBooleanResource(w, "ignoreFileType",
		"IgnoreFileType", FALSE);
}


/*****************************************************************/
/****			parse file name.			*/

/* Copy a string and return a pointer to next available char.
*/
static char *copy(buf, str)
char	*buf, *str;
{
int	c;

	if(buf == NULL)
		return NULL;
	if(str == NULL)
		return buf;

	do
		c = *buf++ = *str++;
	while (c !=  '\0');

	return buf -1;
}

static char *getuserdir(user)
char	*user;
{
struct passwd *pw;

	if(user == NULL)
		return NULL;
	pw = getpwnam(user);

	if(pw == NULL)
		return NULL;
	return pw->pw_dir;
}

/* parsefilename
decode a pathname:
   Replace			with
   $<environment variable>	its value
	~/			Value of $HOME
	~<user name>		Home directory of user
	./			CURRENTDIR
	<dir>/.			<dir>
	../			parent of CURRENTDIR.
	<dir>/..		parent of <dir>.
	:<file>			X resource "*MXV_File_Window.file" with class
				"Filename".
	|<directory>		X resource "*MXV_File_Window.directory"
				with class "Directory".

				In most cases, ':' and '|' are interchangeable.

	\<c>			Treat the character after the '\' as a normal
				character.
CURRENTDIR is either the current data directory or the current palette
directory depending on what is to be read/written.

path	String to decode.
dir	Buffer to use if not NULL. If NULL, an internal buffer is (re)used.

Returns a pointer to the decoded pathname. 

NOTE:
	Someday, may wish to make recursive to handle cases of meta chars
resulting in meta chars. It is sort of done now since calling getpathname
followed by diraccept results in this being called twice.
*/
#ifndef MAXPATHLEN
#define	MAXPATHLEN	1024
#endif

char *td_parseFilename(path, dir)
char	*path, *dir;
{
static char Dir[MAXPATHLEN+1];
char	buf[MAXPATHLEN+1];
char	*ip, *op, *tp;
int	c, lastc, len, i;
Boolean	leadin;

	if((path == NULL) || (strlen(path) == 0))
		return NULL;
	if(dir == NULL)
		dir = Dir;

	ip = path; op = dir;
	lastc = '\0';

	while( (c = *ip++) != '\0')
	{	/* Some functions expect to be the first char or first
		   after a '/'.
		*/
		leadin = (lastc == '\0') || (lastc == '/');
		switch (c) {
		case '~':		/* Home dir?  */
			if(!leadin)	/* No.	*/
			{	*op++ = c;
				break;
			}
			/* '~' forces its output to front of buffer. */
			op = dir;
			len = strcspn(ip, "/");
			if(len == 0)
				op = copy(op, getenv("HOME"));
			else	/* Get user name. */
			{	strncpy(buf, ip, len);
				*(buf+len) = '\0';
				tp = buf;
				/*  Get login directory of user. */
				op = copy(op, getuserdir(tp));
				ip += len;
			}
			break;
		case '$':	/* Look for environment variable. */
			/* '$' expands anywhere. */
			len = strcspn(ip, "/");
			if(len > 0)	/* There is a variable string. */
			{	strncpy(buf, ip, len);
				*(buf+len) = '\0';
				tp = buf;
				/* !!! Should check for NULL. */
				op = copy(op, getenv(tp));
				ip += len;
			}
			else	/* Assume its a normal character otherwise. */
				*op++ = '$';
			break;
		case ':':	/* Look for resource variable. */
		case '|':	/* Look for resource variable. */
			/* ':' expands anywhere. */
			len = strcspn(ip, "/");
			if(len > 0)
			{	strncpy(buf, ip, len);
				*(buf+len) = '\0';
				tp = buf;
				op = copy(op, 
				   gr_GetFileResource(gr_topWin.fileWin->shell,
					tp, (c == '|'), NULL, TRUE));
				ip += len;
			}
			else	/* Assume its a normal character. */
				*op++ = c;
			break;
		case '.':	/* Current or parent dir? */
			/* format: 1 or 2 '.'s surrounded by '/' or end of
			   strings. Anything else and the '.'s are part of
			   a filename.
			*/
			len = strspn(ip, ".");	/* More '.'s ?		*/
			/* If there isn't a leadin, there are too many '.'s
			   or there isn't a leadout, its just a dot.
			*/
			if( !leadin || (len > 1) ||
				(( *(ip+len)!= '/') && ( *(ip+len)!= '\0')))
			{	*op++ = c;
				break;
			}
			ip += len;		/* Bump past the dot.	*/

			/* If the '.' was preceded by a /, use what's in the
			   buffer. Otherwise, use current dir. In any case,
			   reset to beginning of output buffer.
			*/
			if(lastc == '/')
			{	*(--op) = '\0';	/* Remove the '/'. */
				if( op != dir)
					strcpy(buf, dir);
				else
					*buf = '\0';
			}
			else	/* Get current dir. */
				strcpy(buf, td_getDirName());

			op = dir;

			/* If '..', remove any trailing component. */
			if( (len == 1) && ((tp = strrchr(buf, '/'))!= NULL))
				*tp = '\0';
			if( tp == buf)	/* But don't backup past root. */
				strcpy(buf, "/");
			op = copy(op, buf);

			break;
		case '/':	/* Remove cases of "//".	*/
			if(lastc != '/')
				*op++ = '/';
			break;
		case '\\':	/* Take next char literally. */
			if( *ip != '\0')
				*op++ = *ip++;
			else	/* If last char, assume its a normal char. */
				*ip++ = c;
			break;
		default:
			if(!isspace(c))
				*op++ = c;
			break;
		}
		lastc = c;
	}

	*op = '\0';

	return dir;
}
/*****************************************************************

/*
 * Return nonzero if pathname is a directory.
 */
int
td_FileIsDir(pathname,lastMod)
char *pathname;
time_t	*lastMod;
{
struct	stat  buf;

	if(pathname == NULL)
		return 0;

	if (stat(pathname,&buf) == 0)
	{	if(lastMod != NULL)
			*lastMod = buf.st_mtime;
		return (S_ISDIR(buf.st_mode)) ? 1 : 0;
	}
	else	/* Some routines are assuming this error message. */
		gr_perror("%s:", pathname);

	return(0);
}

/*
 *	Return 1 if file exists, else return 0
 */
int td_FileExist(pathname)
char *pathname;
{
struct	stat  buf;

	if (stat(pathname,&buf) == 0)
	{	if(S_ISDIR(buf.st_mode) || S_ISREG(buf.st_mode)
#ifndef __convex__
		 || S_ISLNK(buf.st_mode)
#endif
		  )
			return 1;
		else
			return 0;
	}

	return(0);
}

/* Return current directory name.
Returns NULL if there is no name.
*/
char *td_getDirName()
{
A_FileWind_t	*filewin;
A_Directory_t	currentdir;
FileData_t	*fd;


	filewin = gr_topWin.fileWin;
	/* Get current directory data index and make sure its legal. */
	currentdir = filewin->currentdir;
	if(currentdir < 0)
		currentdir = 0;
	else
	if(currentdir >= MAXFILEWINDIRS)
		currentdir = MAXFILEWINDIRS -1;
	/* Current directory data. */
	fd = &(filewin->dirs[currentdir]);
	if(*fd->dir == '\0')	/* Check for empty name. */
		return NULL;

	return( fd->dir );
}

/*
 *	Set Current working directory
 */
Boolean td_setDirName(filewin, dirName, which)
A_FileWind_t	*filewin;
char		*dirName;
A_Directory_t	which;
{
time_t		modtime;
Boolean 	status;
FileData_t	*fd;

	if(filewin == NULL)
		filewin = gr_topWin.fileWin;

	if( (dirName == NULL) || ( td_FileIsDir(dirName, &modtime)))
	{	if(which == CURRENTDIR)
			which = filewin->currentdir;
		fd = &(filewin->dirs[which]);
		if(dirName == NULL)
		{	*fd->dir = '\0';
			if(gr_Data.debug)
			/* This may be wrong if more than 2 dirs. */
				fprintf(stderr, "Setting %s to NULL\n",
					(which == DATADIR) ? "DataDir" :
						"PaletteDir");
		}
		else
			strcpy( fd->dir, dirName);
		fd->lastmod = modtime;
		status = TRUE;
	}
	else
	{ char msg[128];

		sprintf(msg, "%s is not a directory, ignoring.\n", dirName);
		gr_TextMsgOut(msg);
		status = FALSE;
	}
	return status;
}

/* Return a pointer to 'current' file name.
Returns NULL if there is no name.
*/
char *td_getFileName(which)
A_Directory_t	which;
{
A_FileWind_t	*filewin;
A_Directory_t	usedir;
FileData_t	*fd;
char		*file;

	filewin = gr_topWin.fileWin;
	/* Get current directory data index and make sure its legal. */
	if(which == CURRENTDIR)
		which = filewin->currentdir;

	/* Current directory data. */
	fd = &(filewin->dirs[which]);
	file = fd->file;
	if(*file == '\0')	/* Check for empty file. */
		return NULL;
	return( file);
}

/*
 *	Set Current file
 */
void td_setFileName(filewin, FileName, which)
A_FileWind_t	*filewin;
char		*FileName;
A_Directory_t	which;
{
time_t		modtime;
Boolean 	status;
FileData_t	*fd;

	if(which == CURRENTDIR)
		which = filewin->currentdir;
	fd = &(filewin->dirs[which]);
	if(FileName == NULL)
		*fd->file = '\0';
	else
		strcpy( fd->file, FileName);
}

/* Returns a pointer to a parsed pathname formed from a directory and a file
name. If either are NULL, the respective current name is used
(retrieved from the dialog widgets.  If pathname is NULL, a pointer to
an internal static array is returned.
*/

String td_getPathName(pathname, dir, file)
String pathname, dir, file;
{
static char buf[MAXPATHLEN+1];
A_FileWind_t	*fileWin=gr_topWin.fileWin;

	if(pathname == NULL)
		pathname = (String) buf;
	if(dir == NULL)
		dir = gr_DialogGetValue(fileWin->dirDialog);
	if(file == NULL)
		file = gr_DialogGetValue(fileWin->fileDialog);

	sprintf(pathname, "%s/%s", dir, file);
	pathname = td_parseFilename(pathname, NULL);

	return pathname;
}

/* Sets the current directory index to new and returns the old value.
If filewin is NULL use the global value.
*/
A_Directory_t td_SetDirIndex(filewin, new)
A_FileWind_t	*filewin;
A_Directory_t	new;
{
A_Directory_t	old;

	if(filewin == NULL)
		filewin = gr_topWin.fileWin;
	old = filewin->currentdir;
	if(new != CURRENTDIR)
		filewin->currentdir = new;
	return old;
}

#ifndef NOQSORT
/* Used as string compare for qsort call later.
Assumes the first character of the string is a file type specifier which is
ignored.
*/
#if defined(__stdc__)
int Strcmp(const void *s1, const void *s2)
#else
int Strcmp(s1, s2)
char	**s1, **s2;
#endif
{
int	i;
char	*S1, *S2;

	S1 = *((char **)s1);
	S2 = *((char **)s2);

	if(ignorefiletype)
	{	S1 += 1;
		S2 += 1;
	}

#if defined(sun)
	i = strcasecmp( S1, S2);	/* Handles case. */
#else
	i = strcmp(S1, S2);		/* Ignores case. */
#endif
	return i;
}
#endif /* ifndef NOQSORT */

/* 
	Returns a pointer to a list of character strings of the filenames in
	the directory given by the pathname dirName.
*/
char
**td_FileDirStrings(dirName)
char *dirName;
{
	DIR 		  *dirp;
	struct dirent *dp;
	short		  i =0,j,k,changed=1;
	char   		  **strngs,*strng;
	time_t		  lastMod;

	dirp = opendir(dirName);
	
	if (dirp == NULL)
		return(NULL);
	else
	{
		if ((strngs = 
			td_Malloc2D((int)maxdirentries,(int)1,
				(long)sizeof(char *),
				"td_FileDirStrings")) == NULL)
			return(NULL);

		for (dp=readdir(dirp); (dp!=NULL) && (i<maxdirentries);
			 dp=readdir(dirp))
			if (dp->d_name[0] != '.')
			{	if ((strngs[i] =
				  td_Malloc1D((unsigned)(strlen(dp->d_name)+2),
				  1,(unsigned)sizeof(char),
				  "td_FileDirStrings")) != NULL)
				{
				   sprintf(msg,"%s/%s",dirName,dp->d_name);
				/* NOTE: Strcmp (above) expects an extra char
				   at the beginning of the string.
				*/
				  if(! ignorefiletype)
				  {	if (td_FileIsDir(msg,&lastMod))
					   sprintf(strngs[i],"/%s",dp->d_name);
					else
					if (td_FileIsHdf(msg))
					   sprintf(strngs[i],"*%s",dp->d_name);
					else
					   sprintf(strngs[i],"_%s",dp->d_name);
				   }
				   else
					   sprintf(strngs[i]," %s",dp->d_name);
				   i++;
				}
			}
		closedir(dirp);

		if (dp != NULL)
		{
			sprintf(msg,
	"WARNING: Only %d filenames are displayed due to memory limits.\n",
			maxdirentries);
			gr_TextMsgOut(msg);
		}

		strngs[i] = NULL;

		/* When no items in directory */
		if (i == 0)
		{
			if ((strngs[0] = td_Malloc1D((unsigned)10,
				1,(unsigned)sizeof(char),
				"td_FileDirStrings")) != NULL)
			sprintf(strngs[0],"     ");
			strngs[1] = NULL;
			return(strngs);
		}
		/* Sort strings */
#ifdef NOQSORT
		j=i-1;
		while ((j>0) && (changed == 1))
		{
			changed = 0;
			for (k=0;k<j;k++)
			{
				if (strcmp(strngs[k],strngs[k+1]) > 0)
				{
					strng = strngs[k];
					strngs[k] = strngs[k+1];
					strngs[k+1] = strng;
					changed = 1;
				}
			}
			j--;
		}
#else
	(void)qsort( (void *)strngs, (size_t)i, (size_t)sizeof(*strngs),
		Strcmp);
#endif
		return(strngs);
	}
}
