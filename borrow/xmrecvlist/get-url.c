#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* includes for libwww */
#include <HTParse.h>

#include "gendefs.h"

#ifndef GETURL
#include "get-url.h"
#endif

#ifndef ACCESS_DTM
#define ACCESS_DTM "DTM"
#endif

#ifndef RETR_SCRIPT
#define RETR_SCRIPT "bima/data/archive"
#endif
 
char *dtm2http(DTMurl)
	char *DTMurl;
{
	char *access = "http";
	char *host, *path;
	char *httpurl;

	if ((host = HTParse(DTMurl, "", PARSE_HOST))  == NULL){
		fprintf(stderr, "dtm2http: Error getting host\n");
		return NULL;
	}

	if ((path = HTParse(DTMurl, "", PARSE_PATH))  == NULL){
		fprintf(stderr, "dtm2http: Error getting path\n");
		return NULL;
	}

	if ((httpurl = (char *)malloc((sizeof(char) * strlen(access)) +
								  (sizeof(char) * strlen(host)) +
								  (sizeof(char) * strlen(RETR_SCRIPT)) +
								  (sizeof(char) * strlen(path)) +
								  (sizeof(char) * 6))) == NULL){
		fprintf(stderr, "dtm2http: Error allocating memory for httpurl\n");
		return NULL;
	}

	sprintf(httpurl, "%s://%s/%s/%s", access, host, RETR_SCRIPT, path);

	return strdup(httpurl);
}

int get_http(URL)
	char *URL;
{

	char *access;

	if ((access = HTParse(URL, "", PARSE_ACCESS))  == NULL){
		fprintf(stderr, "Error getting access\n");
		return 0;
	}

	if (!strcasecmp(ACCESS_HTTP, access)){
		if (! handle_http(URL)){
			free(access);
			return 0;
		}
	}
	else if (!strcasecmp(ACCESS_DTM, access)){
		if (! handle_http(dtm2http(URL))){
			free(access);
			return 0;
		}
	}
	else{
		fprintf(stderr, "ERROR: Unsupported access method %s\n", access);
		free(access);
		return 0;
	}
	/* free up stuff */
	free(access);
	return 1;
}
