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


#ifndef UIO_H
#define UIO_H

#include <sys\types.h>

typedef char far *caddr_t;

struct iovec {
	caddr_t	iov_base;
    long int iov_len;
};

struct uio {
    struct iovec *uio_iov;
    long int uio_iovcnt;
	off_t	uio_offset;
    long int uio_segflg;
	short	uio_fmode;
	int	uio_resid;
};

struct msghdr {
    caddr_t   msg_name;         /* optional address */
    long int  msg_namelen;      /* size of address */
    struct    iovec *msg_iov;   /* scatter/gather array */
    long int  msg_iovlen;       /* # elements in msg_iov */
    caddr_t   msg_accrights;    /* access rights sent/received */
    long int  msg_accrightslen;
};

#ifndef EFAULT
#define EFAULT  14          /* for UNIX compability */
#endif

enum	uio_rw { UIO_READ, UIO_WRITE };

/*
 * Segment flag values (should be enum).
 */
#define UIO_USERSPACE	0		/* from user data space */
#define UIO_SYSSPACE	1		/* from system space */
#define UIO_USERISPACE	2		/* from user I space */

#if defined(__STDC__) | defined (_STDC_)
extern long int readv(int ,struct iovec *,int );
extern long int writev(int ,struct iovec *,int );

extern long int recvmsg(int ,struct msghdr *,int );
extern long int sendmsg(int ,struct msghdr *,int );
#endif  /* defined(__STDC__) */

#endif  /* UIO_H */

