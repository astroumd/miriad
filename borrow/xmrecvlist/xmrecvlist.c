/* ------------------------------------------------------------ */
/*= xmrecvlist - transfer miriad datasets from the bima archive */
/*& mjs								*/
/*: tools							*/
/*+								*/
/*  XMRECVLIST is a utility program to actually perform the     */
/*  transfer of miriad datasets from the bima archive.  This    */
/*  is a support program used only by the ncsa mosaic program   */
/*  via miriad script archbima.					*/
/*  								*/
/*  The program should not be used directly by users.		*/
/* 								*/
/*  Correspondence regarding this program can be sent to the    */
/*  author, Jeff Terstriep, at jefft@ncsa.uiuc.edu		*/
/*--								*/
/* ------------------------------------------------------------ */
/* History:							*/
/*  								*/
/* jt   25mar94  Original version (Jeff Terstriep, NCSA).	*/
/* mjs  25mar94  Add in-code docs; elim compiler warning.       */
/* jt   05apr94  Fixed the only bug in the pgm			*/
/* rks  10aug94  Added untarring on the fly						*/
/* rks  11jul95  Overhauled to use libwww and not dtm	*/
/*				 Also added support for environmental variables */
/*				 and rc file
/* ------------------------------------------------------------ */
#include	<stdlib.h>
#include	<stdio.h>
#include	<string.h>
#include	<sys/types.h>
#include    <dirent.h>
#include    <unistd.h>
#include    <fcntl.h>
#include	<sys/wait.h>

#define PAR_IO

#define		ERR		0
#define		OK		1

#define     BUFSIZE     256 * 1024

#define		RC_PATH			"PATH"
#define		RC_VERBOSE 		"VERBOSE"
#define		RC_BACKGROUND 	"BACKGROUND"
#define		RC_NUMPROCS		"NUMPROCS"

#define		ENV_PATH 		"XMBIMAPATH"
#define		ENV_VERBOSE 	"XMBIMAVERBOSE"
#define		ENV_BACKGROUND 	"XMBIMABACKGROUND"
#define		ENV_NUMPROCS	"XMBIMAPROCS"

#define		DEFAULT_BASEPATH 	"./"
#define		DEFAULT_VERBOSE 	"OFF"
#define		DEFAULT_BACKGROUND	"OFF"
#define	    DEFAULT_NUMPROCS	"1"

int   		verbose;
static int 	background;
static int 	numprocs;

extern int get_http();
extern char *get_uservals();
extern char *get_url_path();
extern char *get_url_dirpath();

void usage(prog) char *prog;
{
  fprintf(stderr, "Usage: %s [options] -f <filename>\n", prog);
  fprintf(stderr, "\t-f <file>      : list of items to be retrieved.\n");
  fprintf(stderr, "\n");
  fprintf(stderr, "Options:\n");
  fprintf(stderr, "\t-path <path>   : sets the transfer directory,\n");
  fprintf(stderr, "\t                 defaults to current directory.\n");
  fprintf(stderr, "\t-procs <procs> : retrieval occurs in procs\n");
  fprintf(stderr, "\t                 number files(processes) at a time\n");
  fprintf(stderr, "\t                 (default 1)\n");
  fprintf(stderr, "\t-bg            : untars files in the background.\n");
  fprintf(stderr, "\t-v             : turn on verbose debugging mode.\n");
  exit(-1);
}


/*
** create_dirs - utility routine which ensures all the directories
**	in a path exist.  If a non-existant directory is encountered, it
**	is created.
*/
static int create_dirs(path) char * path;
{
  int	len;
  char	*lpath, *cptr;
  DIR 	*dptr;
  
  
  len = strlen(path);
  if ((lpath = (char *)malloc(len + 1)) == NULL) return ERR;
  memset(lpath, '\0', len + 1);
  
  cptr = (*path == '/') ? path+1 : path;
  while ((cptr = strchr(cptr, '/')) != NULL)  {
    memcpy(lpath, path, cptr - path);
    if ((dptr = opendir(lpath)) == NULL){
      if (mkdir(lpath, 0777) == -1) return ERR;
    }
    else {
      closedir(dptr);
    }
    cptr += 1;
  }
  
  return OK;
}


/*
** checkfile - utility routine, take two pathnames and concatenates
**	them together.  Then calls create_dirs to make sure all the
**	subdirectories exist.
*/
static char *checkfile(basepath, filepath) 
	char *basepath, *filepath;
{
  int		len;
  char  path[1024];
  
  /* copy basepath to filepath, append '/' if necessary */
  if (basepath != NULL)  {
    strcpy(path, basepath);
    if ( *(basepath + strlen(basepath) - 1) != '/') strcat(path, "/");
  }
  
  /* if basepath == NULL, start with current directory */
  else  {
    strcpy(path, DEFAULT_BASEPATH);
  }
  
  /* append filepath to basepath, remove beginning '/' if necessary */
  /* if filepath is NULL assume the file came in on the basepath */
  if (filepath != NULL)  {
    if (*filepath == '/') filepath += 1;
    strcat(path, filepath);
  }
  
  /* make sure all the directories exist in the path */
  if (create_dirs(path) == ERR) return NULL;
  
  /* finally ready return the path*/
  return strdup(path);
}

/*
** HTTPrecvFile - handle the receiving and untarring of the files.
**
** Args
**	basepath - base path for saving file
**	url - url for file to retrieve
*/
static int HTTPrecvFile(basepath, url) 
	 char *basepath, *url;
{
  char	cur_dir[1024], *urldir, *dirpath;

  /* get the directory path in the url*/
  if ((urldir = get_url_dirpath(url)) == NULL) return ERR;
  
  /* make the directory <basepath>/<urlpath> */
  if ((dirpath = (char *)checkfile(basepath, urldir)) == NULL) return ERR;

  /* chdir to basepath/urldir, then gethttp */
  getcwd(cur_dir, 1024);
  if (cur_dir == NULL) return ERR;
  if (chdir(dirpath) == -1) return ERR;

  /* lets do this in the background to avoid broken pipes*/
  switch (fork()){
  case -1: /* error */
	  return ERR;
	  break;
  case 0: /* child */

	  if (get_http(url) == ERR){
		  if (verbose) fprintf(stderr, "Error: problem getting %s\n", 
							   get_url_path(url));
		  if(chdir(cur_dir) == -1) return ERR;
		  return ERR;
	  }

	  exit(0);
	  break;
  default:	/* parent */
	  if (!background) wait(0);
	  break;
  }
  chdir(cur_dir);

  free(urldir);
  free(dirpath);
  return OK;
}

/*
** handleURL - reads URL and saves it to disk
**
** On Entry:
**	url	- url to retrieve
** 
** On Exit:
**	returns status (OK or ERR)
*/
static int handleURL(url, basepath)
     char *url, *basepath;
{
  
  /* attempt to retrieve the file */
  if (HTTPrecvFile((char *)basepath, url) == ERR)  {
    fprintf(stderr, "Error: could not retrieve dataset\n");
    return ERR;
  }
 return OK;
}


/*
** parse command line arguments, open the URL file and attempt to
** retrieve each URL.  If anything go wrong skip to next URL.
*/
int main(argc, argv)
     int  argc;
     char *argv[];
{
  int	i, j;
  char	*prog = argv[0], *fname = NULL;
  char	*basepath = NULL, *debugging = NULL;
  char	*backgrnd = NULL, *nprocs = NULL;
  char  line[256], *url_list[100];
  int	url_listc = 0;
  FILE  *url_file;

  /* get user defined values if any */

  /* BASEPATH */
  if ((basepath = (char *)get_uservals(RC_PATH, ENV_PATH, 
									   DEFAULT_BASEPATH)) == NULL){
	  fprintf(stderr, "$s: Error getting/setting basepath\n", prog);
	  exit(-1);
  }

  /* VERBOSE */
  if ((debugging = (char *)get_uservals(RC_VERBOSE, ENV_VERBOSE, 
										DEFAULT_VERBOSE)) 
	  == NULL){
	  fprintf(stderr, "$s: Error getting/setting verbose flag\n", prog);
	  exit(-1);
  }
  /* convert the char value of VERBOSE setting to int verbose flag */
  if (!strcmp(debugging, "ON")) verbose = 1;
  else verbose = 0;
  free(debugging); /* free this char value -- it is no longer needed */

  /* BACKGROUND */
  if ((backgrnd = (char *)get_uservals(RC_BACKGROUND, ENV_BACKGROUND, 
										DEFAULT_BACKGROUND)) 
	  == NULL){
	  fprintf(stderr, "$s: Error getting/setting background flag\n", prog);
	  exit(-1);
  }
  /* convert the char value of BACKGROUND setting to int background flag */
  if (!strcmp(backgrnd, "ON")) background = 1;
  else background = 0;
  free(backgrnd); /* free this char value -- it is no longer needed */

  /* NUMPROCS */
  if ((nprocs = (char *)get_uservals(RC_NUMPROCS, ENV_NUMPROCS, 
										DEFAULT_NUMPROCS)) 
	  == NULL){
	  fprintf(stderr, "$s: Error getting/setting numprocs\n", prog);
	  exit(-1);
  }
  /* convert the char value of NUMPROCS setting to int numprocs */
  numprocs = atoi(nprocs);
  free(nprocs); /* free this char value -- it is no longer needed */


  /* parse command line arguements */
  for (i=1; i<argc; i+=1)  {
    if (!strcmp(argv[i], "-path")){
		if (basepath == NULL) basepath = argv[++i];
		else{	/* override rc and env values, freeing first */
			free(basepath);
			basepath = argv[++i];
		}
	}
    else if (!strcmp(argv[i], "-v")) verbose = 1;
	else if (!strcmp(argv[i], "-procs")) numprocs = atoi(argv[++i]);
    else if (!strcmp(argv[i], "-bg")) background = 1;
    else if (!strcmp(argv[i], "-f")) fname = argv[++i];
  }
  
  /* check command line arguments */
  if (fname == NULL)  {
	  fprintf(stderr, "%s: Error must specify file with URL list.\n", prog);
	  usage(prog);
  }
  
  /* open the file with URL list */
  if ((url_file = fopen(fname, "r")) == NULL)  {
	  fprintf(stderr, "%s: Error could not open %s.\n", prog, fname);
	  usage(argv[0]);
  }

  /* foreach URL, parse and retrieve it with parallelization */
  while(fscanf(url_file, "%s\n", line) == 1){
	  if ((url_list[url_listc] = (char *)strdup(line)) == NULL){
		  fprintf(stderr, "%s: error creating url_list\n", prog);
		  exit(-1);
	  }
	  url_listc++;
  }
  fclose(url_file);

  /* foreach URL, parse and retrieve it with parallelization */
  i = 0;
  while(i < url_listc){
	  int	*PID;

	  if ((PID = (int *)malloc((sizeof(int) * numprocs))) == NULL){
		  fprintf(stderr, "Could not create PID array\n");
		  exit(-1);
	  }

	  for (j = 0; (j < numprocs) && ((i + j) < url_listc); j++){
#ifdef PAR_IO
		  switch(PID[j] = fork()){
		  case -1:
			  fprintf(stderr, "%s: fork error, exiting\n", prog);
			  exit(-1);
			  break;
		  case 0:
#endif
			  if (verbose) fprintf(stderr, "Attempt to retrieve: %s\n", 
								   get_url_path(url_list[i+j]));

			  if (handleURL(url_list[i+j], basepath) == ERR)  {
				  fprintf(stderr, "%s: Unable to retrieve: %s\n", 
						  prog, get_url_path(url_list[i+j]));
			  }
			  else{
				  if (verbose) fprintf(stderr, "Done retrieving: %s\n",
									   get_url_path(url_list[i+j]));
			  }
#ifdef PAR_IO
			  exit(0);
			  break;
		  default:
			  break;
		  }
#endif
	  }
#ifdef PAR_IO
	  /* wait for all the children to finish */
	  for (j = 0; j < numprocs; j++) waitpid(PID[j],0,0);
#endif
	  /* incriment by the number of procs */
	  i += numprocs;

  }  
  return OK;
}
