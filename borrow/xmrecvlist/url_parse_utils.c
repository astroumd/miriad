#include <stdlib.h>
#include <stdio.h>

/* libwww headers */
#include <HTParse.h>


/*
** get_url_dirpath - parses url into path without filename
**
** On Entry:
**	url	  		: url to be parsed
**
** On Exit  (All pointer must be freed by calling routine):
**  path		: path string excluding file name
*/
/* NOTE: this is very dependant on the format of the url */

#define PATH_DELIMITER "bima/data/archive"
#ifndef ACCESS_DTM
#define ACCESS_DTM "DTM"
#endif

char *get_url_dirpath(url)
	char *url;
{

  char	*fullpath, *cptr, *cptr2, *delimiter;

  if (!strcasecmp(ACCESS_DTM, HTParse(url, "", PARSE_ACCESS)))
	  delimiter = NULL;
  else
	  if ((delimiter = (char *)strdup(PATH_DELIMITER)) == NULL){
		  fprintf(stderr, "url_dir_path: error allocating delimiter\n");
		  return NULL;
	  }

  if ((fullpath = HTParse(url, "", PARSE_PATH)) == NULL) return NULL;

  /* chop off everything but the path and filename */
  if (delimiter != NULL){
	  if((cptr = (char *)strstr(fullpath, delimiter)) == NULL){
		  fprintf(stderr, "url_dir_path: Error, %s incorrect format\n", url);
		  return NULL;
	  }

	  cptr = cptr + strlen(delimiter);
  }
  else
	  cptr = fullpath;

  /* chop off the filename */
  if ((cptr2 = (char *)strrchr(cptr, '/')) == NULL){
    return NULL;
  }
  cptr2++;
  *cptr2 = '\0';

  return (char *)strdup(cptr);
}

/* this is just here to seperate the stuff depending on libwww from
   the xmrecvlist.c file. */
/*
** get_url_path - parses url into path
**
** On Entry:
**	url	  		: url to be parsed
**
** On Exit  (All pointer must be freed by calling routine):
**  path		: path string
*/

char *get_url_path(url)
	char *url;
{
	return HTParse(url, "", PARSE_PATH);
}
