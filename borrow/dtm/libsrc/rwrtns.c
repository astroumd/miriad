/*****************************************************************************
*
*                   Data Transfer Mechanism (DTM) v. 2.3
*                           May 1, 1992
*
* UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
* APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
* Software
* 
* The NCSA software Data Transfer Mechanism [both binary and source (if
* released)] is in the public domain, available without fee for education,
* research, non-commercial and commercial purposes.  Users may distribute the
* binary or source code to third parties provided that this statement
* appears on all copies and that no charge is made for such copies.
* 
* UI MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY
* PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  THE
* UI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS
* SOFTWARE.  The software may have been developed under agreements between
* the UI and the Federal Government which entitle the Government to certain
* rights.
* 
* By copying this program, you, the user, agree to abide by the conditions
* and understandings with respect to any software which is marked with a
* public domain notice.
*
*****************************************************************************/


#include	<stdio.h>
#include	<sys/types.h>
#ifdef _ARCH_MSDOS
#include    <nmpcip.h>
#include    "uio.h"
#else
#include	<sys/socket.h>
#include	<sys/uio.h>
#include	<netinet/in.h>
#endif
#include	<fcntl.h>
#include	<errno.h>

#ifdef RS6000
#include <sys/select.h>
#endif

#include	"dtmint.h"
#include	"debug.h"


/*
	CONTENTS


	dtm_read_buffer() 	- attempts to fill the next dtm buffer. 
	dtm_recv_header() 	- Function to read header and return size.  
 	dtm_recv_ack() 		- receive message ackowledgement
	tm_send_ack() 		- send message acknowledgement
	dtm_writev_buffer()	- sends the buffers to receiving process.
*/

/*
	STATIC FUNCTION PROTOTYPES
*/
#ifdef DTM_PROTOTYPES
static  int dtm_recv_reliable PROTO((int ,char *,int ));
static  int dtm_writev_failed PROTO((int ,struct msghdr *,int ));
static  int dtm_send_some PROTO((int d, char *buf, int bufsize ));
#endif

static int	padding[] = {0, 3, 2, 1};

/*		Technique from XlibInt.c
*/
#if defined(EAGAIN) && defined(EWOULDBLOCK)
#define ERRTEST(err) (err == EAGAIN || err == EWOULDBLOCK)
#else
#if defined(EAGAIN)
#define ERRTEST(err) (err == EAGAIN)
#else
#define ERRTEST(err) (err == EWOULDBLOCK)
#endif
#endif

/*
	Reliably read from a port in the face of signals and other
	'errors' produced by the operating system.
*/
#ifdef DTM_PROTOTYPES
static int   dtm_recv_reliable(int d,char *buffer,int length )
#else
int	dtm_recv_reliable( d, buffer, length )
	int		d;
	char *	buffer;
	int		length;
#endif
{
	int		bytes_read;
	while ( (bytes_read = recv( d, buffer, length, 0)) !=  length ) {
		if ( bytes_read > 0) {
			length -= bytes_read;
			buffer += bytes_read;
		} else if (ERRTEST(errno)) {
			fd_set  filedes;
			int		got;

			/* FD_ZERO and FD_SET were moved into the select loop */
			/* just in case the select is clearing filedes */
			do {
				FD_ZERO( &filedes );
				FD_SET( d, &filedes );
				got = select( d, &filedes, (fd_set *)NULL, (fd_set *)NULL,
						NULL );
				if (got < 0 &&  errno != EINTR ) {
					DTMerrno = DTMREAD;
					return DTMERROR;
				}
			} while ( got <= 0 );
			continue;
		} else if (bytes_read == 0) {
			DTMerrno = DTMEOF;
			return DTMERROR;
		} else if (errno != EINTR) {
			DTMerrno = DTMREAD;
			return DTMERROR;
		}
	}
	return DTM_OK;
}

/*
 * dtm_read_buffer() - attempts to fill the next dtm buffer.  The 
 *	blocklen variable must be set to DTM_NEW_DATASET after each dataset
 *	to force recv_buffer to move the next dataset.
 */
#ifdef DTM_PROTOTYPES
int dtm_read_buffer(int d,int32 *blocklen,VOIDPTR buffer,int length)
#else
int dtm_read_buffer(d, blocklen, buffer, length)
  int		d, *blocklen;
  VOIDPTR	buffer;
  int		length;
#endif
{
  reg int	tmp, readcnt, count = 0;

  DBGFLOW("# dtm_read_buffer called.\n");
  DBGMSG1("dtm_recv_buffer: attempting to read %d bytes.\n", length);
  DBGMSG1("dtm_recv_buffer: initial blocklen = %d\n", *blocklen);

  /* if block length is DTM_NEW_DATASET this is a new dataset 
   * get initial block count 
   */
  if (*blocklen == DTM_NEW_DATASET)  {
    CHECK_ERR(dtm_recv_reliable(d, (char *)blocklen, 4));
    LOCALINT(*blocklen);
    DBGINT("initial blocklen = %d\n", *blocklen);
  }

  /* attempt to get a full buffer */
  while (TRUE)  {

    /* if block length is 0, because last call to fill_buffer hit
     * the EOS or because this dataset is zero length, return 0  
     * to indicate the end of dataset.				 
	 */
    if (*blocklen == 0)
      return 0;

    /* if block length is greater than buffer size then... */
    if (*blocklen >= length - count)  {

      readcnt = length - count;
      CHECK_ERR( dtm_recv_reliable( d, ((char *)buffer) + length - readcnt,
         readcnt));

		/* decrement block length, if 0 get next block length */
		*blocklen -= (length - count);
		if (*blocklen == 0)  
			*blocklen = DTM_NEW_DATASET;

      /* if block length is 0 now, the EOS will be returned on */
      /* the next call to fill_buffer */

      /* return full buffer count */
      DBGINT("recv_buffer: buffer full, returning %d\n", length);
      return length;
      }

    /* else block length is less than buffer size */
    else  {

      readcnt = *blocklen;
      CHECK_ERR( dtm_recv_reliable( d, (char *)buffer + count +
         *blocklen - readcnt, readcnt));

      /* increment count */
      count += *blocklen;

      /* get next block length */
      CHECK_ERR( dtm_recv_reliable(d, (char *)blocklen, 4));
      LOCALINT(*blocklen);
      DBGINT("blocklen = %d\n", *blocklen);

      /* if block length is 0 now, the correct count will be */
      /* returned now, and EOS on the next call to fill_buffer */ 
      if (*blocklen == 0)
        return count;

      }
    } /* end while */
}

/*
       Replaces dtm_recv_header for nornal communication.
*/
#ifdef DTM_PROTOTYPES
int   dtm_read_header(int fd,void *buf,int buflen )
#else
int   dtm_read_header( fd, buf, buflen )
	int		fd;
	void * 	buf;
	int		buflen;
#endif
{
	int32		hdrsize;


	/* get the header length */
	CHECK_ERR( dtm_recv_reliable( fd, (char *)&hdrsize, 4 ));
	LOCALINT(hdrsize);

	/* if the header length is 0, return 0 */
	if (hdrsize == 0)  {
		return hdrsize;
	}

	/* if header length is smaller the actual buffer length,	*/
	/* read header into buffer and return header size.			*/
	else if ( hdrsize <= buflen ) {
		CHECK_ERR( dtm_recv_reliable( fd, buf, hdrsize ));
		return hdrsize;
	}

	/* otherwise, read as much header as possible and discard the rest */
	else {
		int		left  = hdrsize - buflen;
		int     readcnt = left % DISCARDSIZE;

		CHECK_ERR( dtm_recv_reliable( fd, buf, buflen ));

		if (!readcnt) readcnt = DISCARDSIZE;
		while (left) {
			CHECK_ERR(dtm_recv_reliable( fd, dtm_discard, readcnt ));
			left -= readcnt;
			readcnt = DISCARDSIZE;
		}

		DTMerrno = DTMHEADER;
		return DTMERROR;
    }
}

/*
	dtm_recv_header()
	Function to read header and return size.  

	Notes	: If buffer is too small, dump remainder of header 
		  and return error.
		  Actually, this is function to read length of data and
		  then to receive that much data - the data is called header
		  everywhere since that was the first usage of the function.
*/
#ifdef DTM_PROTOTYPES
int dtm_recv_header(int d,VOIDPTR header,int length )
#else
int dtm_recv_header( d, header, length )
	int		d;
	int		length;
	VOIDPTR	header;
#endif
{
	int	readcnt, headerlen, tmp;
	struct	sockaddr_in from ;
	int	fromlen = sizeof( struct sockaddr_in ) ;

	DBGFLOW("# dtm_recv_header called.\n");
	DBGMSG1("dtm_recv_header: fd = %d.\n", d);
	DBGMSG1("dtm_recv_header: buf length = %d.\n", length);

  	/* get header length */
	
  	if( (readcnt = recvfrom(d, (char *)&headerlen, 4, 0, ( struct sockaddr *)&from,
			( int *)&fromlen)) != 4) {
    		/* somehow hit EOF, return DTMEOF instead */

		if( readcnt == 0 ) {
			DTMerrno = DTMEOF;
			DBGMSG("dtm_recv_header: EOF1.\n");
			return DTMERROR;
		} else {
			if( errno == ECONNRESET ) {
				/* connection closed by writer, return EOF */

				DBGMSG("dtm_recv_header: EOF2.\n");
				DTMerrno = DTMEOF;
				return DTMERROR;
			} else {
				/* don't know what the problem is, punt... */
				DBGMSG("dtm_recv_header: EOF3.\n");
				DTMerrno = DTMREAD;
				return DTMERROR;
			}
		}
  	}    

  	LOCALINT(headerlen);
	DBGMSG("dtm_recv_header: got length.\n");

	/*  read the header */ 

  	readcnt = (length > headerlen) ? headerlen : length ;
  	header = (void *) (((char *) header) + readcnt);

  	while(readcnt) {
		if( (tmp = recvfrom(d, ((char *)header) - readcnt, readcnt, 0, 
		( struct sockaddr *)&from, ( int *)&fromlen)) > 0) 
			readcnt -= tmp;
		else {
      			DTMerrno = DTMREAD;
      			return DTMERROR;
		}
	}

   	/* check for header greater than buffer size provided */ 

  	if( length >= headerlen ) 
		return headerlen;
  	else {
  		/* discard remaining header */

    		readcnt = headerlen - length;
		while (readcnt) {
			if ((tmp = recvfrom(d, dtm_discard, readcnt, 0, 
					(struct sockaddr *)&from, (int *)&fromlen)) > 0) 
				readcnt -= tmp;
			else {
      				DTMerrno = DTMREAD;
      				return DTMERROR;
			}
		}
    
		DTMerrno = DTMHEADER;
		return DTMERROR;
	}
}

/*
 	dtm_recv_ack() - receive message ackowledgement

	Notes	: Berkeley implementation returns 0 from recv
		  if socket connection breaks while waiting in
		  recv system call.  System V returns -1 and 
		  ECONNRESET in errno for same error.

		  For historical reasons, DTMEOF is returned when
		  socket connection breaks in middle instead of
		  say DTMFCONN ( DTM connection failed error )
*/
#ifdef DTM_PROTOTYPES
int dtm_recv_ack(int d,int *ack )
#else
int	dtm_recv_ack( d, ack )
	int	d;
	int	*ack;
#endif
{
	int	tmp ;

	DBGFLOW("# dtm_recv_ack called.\n");

  	if( (tmp = recv( d, (char *)ack, 4, 0 )) != 4 ) {
		DBGINT( "Recv_ack errno = %d\n", errno ) ;
		if( tmp == 0 ) 
			/* Courtesy Berkeley */

			DTMerrno = DTMEOF ;
		else {
			if( errno == ECONNRESET ) 
				/* Courtesy system V */

				DTMerrno = DTMEOF;
			else 
				DTMerrno = DTMREAD;
		}
		return DTMERROR;
	}

	DBGMSG1( "ack received, tmp = %d\n", tmp );
  	LOCALINT(*ack);
  	return DTM_OK;
}

#ifdef DTM_PROTOTYPES
static int dtm_send_some(int d, char *buf, int bufsize )
#else
int	dtm_send_some( d, buf, bufsize )
	int		d;
	char *	buf;
	int		bufsize;
#endif
{
	int	tmp ;

	while (bufsize ) {
		tmp = send(d, buf, bufsize, 0);
		if ( tmp >= 0 ) {
			bufsize -= tmp;
			buf += tmp;
			continue;
		}
		if (errno == EPIPE) {
				/* socket connection broke in middle */
			DTMerrno = DTMEOF ;
			return DTMERROR;
		} else if ( ERRTEST( errno ) ) {
			fd_set  filedes;
			int		got;

			FD_ZERO( &filedes );
			FD_SET( d, &filedes );
			do {
				got = select( 32, &filedes, (fd_set *)NULL, (fd_set *)NULL,
						NULL );
				if (got < 0 &&  errno != EINTR ) {
					DTMerrno = DTMWRITE;
					return DTMERROR;
				}
			} while ( got <= 0 );
			continue;
		} else DTMerrno = DTMWRITE ;
		return DTMERROR;
	}
	return DTM_OK;
}

/*
 * dtm_send_ack() - send message acknowledgement
 */
#ifdef DTM_PROTOTYPES
int dtm_send_ack(int d, int32 ack)
#else
int	dtm_send_ack(d, ack)
	int		d;
	int32	ack;
#endif
{
	DBGFLOW("# dtm_send_ack called.\n");

  	STDINT(ack);
	return dtm_send_some( d, (char *)&ack, 4 );
}

#ifdef DTM_PROTOTYPES
static int dtm_writev_failed(int fd,struct msghdr *msgbuf,int tmp )
#else
int dtm_writev_failed( fd, msgbuf, tmp )
	int					fd;
	struct msghdr * 	msgbuf;
	int					tmp;
#endif
{
	int					done = tmp;
	int					i;
	struct	iovec	*	iov = msgbuf->msg_iov;
	if ( tmp < 0 ) done = 0;
	for ( i = 0; i < msgbuf->msg_iovlen; i++ ) {
		done -= iov[i].iov_len;
		if ( done > 0 ) continue;
#ifdef sgi
		if ( dtm_send_some( fd, (int32 *)iov[i].iov_base + done + iov[i].iov_len, 
				(- done )) == DTMERROR )
#else /* !sgi */
		if ( dtm_send_some( fd, iov[i].iov_base + done + iov[i].iov_len, 
				(- done )) == DTMERROR )
#endif /* sgi */
			return DTMERROR;
		done = 0;
	}
}

/*
	dtm_writev_buffer() - sends the buffers to receiving process.
*/
#ifdef DTM_PROTOTYPES
int dtm_writev_buffer(int fd,struct iovec *iov,int32 iovlen,int32 iovsize,
			struct sockaddr *addr,int addrlen )
#else
int	dtm_writev_buffer( fd, iov, iovlen, iovsize, addr, addrlen )
	int				fd ;
	struct	iovec	*iov ;
	int32			iovlen ;
	int32			iovsize ;
	struct sockaddr	*addr ;
	int				addrlen ;
#endif
{
	int	tmp;
	struct	msghdr	msgbuf ;
	int	todo;

  	DBGINT("# dtm_writev_buffer called, fd %d.\n", fd );
	
	msgbuf.msg_name = (caddr_t)addr ; 
	msgbuf.msg_namelen = addrlen ;
	msgbuf.msg_iov = iov ;
	msgbuf.msg_iovlen = iovlen ;
	msgbuf.msg_accrights = 0 ;

	if( (tmp = sendmsg( fd, &msgbuf, 0 )) != iovsize ) 
		return dtm_writev_failed( fd, &msgbuf, tmp );

	DBGINT( "dtm_writev_buffer tmp = %d\n", tmp );
	
	return	DTM_OK ;
}
