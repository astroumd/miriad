#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

/* header for libwww */
#include <HTAccess.h>
#include <HTFormat.h>
#include "HTMIME.h"

#include "gendefs.h"

int handle_http(url)
	char *url;
{

	HTRequest *request;

	/* allocate/create the HTRequest structure */
	if ((request = HTRequest_new()) == (HTRequest *)NULL){
		fprintf(stderr, "Error allocating request\n");
		return ERR;
	}

	/* initialize the values in the HTRequest structure */

	request->method = METHOD_GET;
	request->output_format = WWW_SOURCE;

   	/* go get the URL */ 
	if (!HTLoadToStream(url, NO, request)){
		fprintf(stderr, "Error on HTLoadToStream\n");
		HTRequest_delete(request);
		return ERR;
	}

	HTRequest_delete(request);

	return OK;

}
