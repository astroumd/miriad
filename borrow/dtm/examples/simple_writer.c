/***********************************************************************
**
** simple_writer.c : this file contains a simple example using DTM
**		to send messages another process.  In this case,
**		simple_reader can be setup to receive the message.
**
***********************************************************************/

#include	<stdio.h>
#include	<strings.h>

#include	"dtm.h"


main(argc, argv)
    int   argc;
    char  *argv[];
{
    int   i;
    int   port = -1;                      /* DTM port Id */
    char  header[DTM_MAX_HEADER];         /* DTM message header buffer */


	header[0] = '\0';

    /* check the command line arguements looking for '-DTMOUT' */
    for (i=1; i<argc; i++)  {

        if (!strcmp(argv[i], "-DTMOUT"))  {

            /* make the DTM output port - DTMmakeOutPort requires the  */
            /* destination address (argv[++i]) and type of service     */
            /* flag (DTM_DEFAULT).  The destination address is in the  */
            /* form "host:port number".  The host should be either the */
            /* host name or an IP address in dot decimal form.  The    */
            /* port number should be an integer in the range 5000-     */
            /* 65535.                                                  */
            port = DTMmakeOutPort(argv[++i], DTM_DEFAULT);

            if (port == DTMERROR) {
                fprintf(stderr, "%s: error creating DTM port.\n", argv[0]);
                exit(-1);
            }
        }
        else if (!strcmp(argv[i], "-msg"))
            strcpy(header, argv[++i]);
    }

    /* make sure the output port was specified on the command line */
    if (port == -1)  {
       fprintf(stderr,"Usage: %s -DTMOUT <host:port> [-msg message]\n",argv[0]);
       exit(-1);
    }

    /* Put something in the header - this is normally handle by various */
    /* DTM message class routines.  For now, we will use a simple test  */
    /* string.  As far as DTM is concerned, this is simply a array of   */
    /* of bytes to be transmitted.                                      */

    if (strlen(header) == 0)
        strcpy(header, "THIS IS A TEST STRING.");

    /* Send the message to the receiving process.  DTMwriteMsg writes   */
    /* a simple DTM message.  It requires the DTM port Id (port), a     */
    /* buffer (header), and the length of the buffer,  a data buffer    */
    /* NULL, number of data elements (0) and the type of elements       */
    /* (DTM_CHAR).  In this case, there is no data to be sent, only the */
    /* header.  The header length is determined by the DTM utility      */
    /* macro DTMHL or DTMheaderLength.                                  */

    DTMwriteMsg(port, header, DTMHL(header), NULL, 0, DTM_CHAR);


    /* the above call is equivalent to the following two calls...       */
   
    /* DTMbeginWrite(port, header, DTMHL(header)); */
    /* DTMendWrite(port); */

    /* for simple messages, where all the data elements will be         */
    /* stored in a single buffer or where there are no data elements    */
    /* at all, DTMwriteMsg is more efficient than the multiple calls.   */
    /* DTMwriteMsg will concatenate all the buffers into a single       */
    /* system send call. */
}
