/***********************************************************************
**
** simple_reader.c : this file contains a simple example using DTM
**		to receive messages another process.  In this case,
**		simple_writer can be setup to send the message.
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
    int   port = -1;                   /* DTM port Id */
    char  header[DTM_MAX_HEADER];      /* DTM message header buffer */


    /* check the command line arguements looking for '-DTMIN' */
    for (i=1; i<argc; i++)  {

        if (!strcmp(argv[i], "-DTMIN"))

            /* make the DTM input port - DTMmakeInPort requires the    */
            /* source address (argv[++i]) and type of service flag     */
            /* (DTM_DEFAULT).  The source address is actually the      */
            /* the address where the receiving process is listening    */
            /* for incoming messages on the local machine.   The       */ 
            /* port address should be of the form "host:port number".  */
            /* Since the host is always the local machine, the host    */
            /* component may be omitted.  The port number should be an */
            /* integer in the range 5000-65536.                        */

            port = DTMmakeInPort(argv[++i], DTM_DEFAULT);

            if (port == DTMERROR) {
                fprintf(stderr, "%s: error creating DTM port.\n", argv[0]);
                exit(-1);
            }
    }

    /* make sure the input port was specified on the command line */
    if (port == -1)  {
        fprintf(stderr, "Usage: %s -DTMIN <host:port number>\n", argv[0]);
        exit(-1);
    }


    /* Receive the message to the sending process.  DTMreadMsg reads    */
    /* a simple DTM message.  It requires the DTM port Id (port), a     */
    /* buffer (header), and the size of the buffer,  a data buffer      */
    /* (NULL), number of data elements (0) and the type of elements     */
    /* (DTM_CHAR).  In this case, there is no data to be received, only */
    /* the header.  If the incoming message had contained data elements */
    /* they would have been discarded.                                  */

    DTMreadMsg(port, header, sizeof header, NULL, 0, DTM_CHAR);


    /* the above call is equivalent to the following two calls...       */
   
    /* DTMbeginRead(port, header, sizeof header); */
    /* DTMendRead(port); */

    /* For simple messages, where all the data elements will be         */
    /* stored in a single buffer or where no data elements are to be    */
    /* saved, DTMreadMsg provides a simpler interface for receiving     */
    /* messages.  Unlike DTMwriteMsg, there is no performance           */
    /* improvement for using DTMreadMsg over DTMbeginRead and           */
    /* DTMendRead.  Note - if the incoming message contains data        */
    /* elements but the receiver does not request them, they will be    */
    /* silently discarded.                                              */

    printf("Message Received: '%s'\n", header);
}
