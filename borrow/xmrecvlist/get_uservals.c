#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <pwd.h>

#define RC_FILE ".xmbimarc"

typedef struct passwd passwd;

extern int verbose;

/*
**  This checks for user defined values for various values used by
**	this program. The current values that can be set by this are
**	all the optional flags from the command line. Currently there
**	is no way to specify an alternative rc file.
**
**	Functionality:
**  It first looks for an environmental variable env_var and returns
**  its value if it exists. If not then it looks for a file called
**  .xmrecvlistrc in the users home dir and searches it for a field
**	value pair of the form file_field=val and returns that. If none
**	of these are found or if an error occurs it returns default_val. 
*/
char *get_uservals(file_field, env_var, default_val)
	char *file_field, *env_var, *default_val;
{

	char *val = NULL;
	char *homedir, *rcfile, buf[1024];
	uid_t uid;
	passwd *pw;
	FILE *fp;

	if ((val = (char *)getenv(env_var)) != NULL){
		return (char *)strdup(val);
	}

	uid = getuid();

	if ((pw = (passwd *)getpwuid(uid)) == NULL){
		if (verbose)
			fprintf(stderr, "Could not get passwd structure for %d\n", uid);
		val = default_val;
		if (val == NULL) return NULL;
		else return (char *)strdup(val);
	}

	if ((homedir = (char *)strdup(pw->pw_dir)) == NULL){
		if (verbose)
			fprintf(stderr, "Could not get homedir for %d\n", uid);
		val = default_val;
		if (val == NULL) return NULL;
		else return (char *)strdup(val);
	}

	if ((rcfile = (char *)malloc((sizeof(char) * strlen(homedir)) +
								 (sizeof(char) * strlen(RC_FILE)) +
								 (sizeof(char) * 2))) == NULL){
		if (verbose) fprintf(stderr, "Allocation error on rcfile\n");
		val = default_val;
		free(homedir);
		if (val == NULL) return NULL;
		else return (char *)strdup(val);
	}

	strcat(strcat(strcpy(rcfile, homedir), "/"), RC_FILE);

	if ((fp = fopen(rcfile, "r")) == NULL){
		if (verbose) fprintf(stderr, "Could not open %s\n", rcfile);
		val = default_val;
		free(homedir); free(rcfile);
		if (val == NULL) return NULL;
		else return (char *)strdup(val);
	}

	while(fgets(buf, 1024, fp) != NULL){

		if (*buf == '#') continue;
		if (*buf == '\n') continue;

		if ((buf[strlen(buf) - 1]) == '\n') buf[strlen(buf) - 1] = '\0';
 
		if (((char *)strstr(buf, file_field)) != NULL){
			char *cptr;

			if ((cptr = (char *)strchr(buf, '=')) == NULL){
				fprintf(stderr, "Syntax Error in %s\n", rcfile);
				val = default_val;
				free(homedir); free(rcfile);
				if (val == NULL) return NULL;
				else return (char *)strdup(val);
			}
			cptr++;
			if ((val = (char *)strdup(cptr)) == NULL){
				if (verbose) fprintf(stderr, "Error duping cptr\n");
				val = default_val;
				free(homedir); free(rcfile);
				if (val == NULL) return NULL;
				else return (char *)strdup(val);
			}
			break;
		}
	}

	if (val == NULL) val = default_val;
	if (val == NULL) return NULL;
	else return (char *)strdup(val);
}
