/*
 *  VMSget -- read VMS variable length record files on UNIX
 *
 *	short	VMSgetS()	-- get a integer*2
 *	int	VMSgetI()	-- get an integer*4
 *	float	VMSgetR()	-- get a real*4
 *	double	VMSgetD()	-- get a real*8
 *	void	VMSget(n, buff)	-- get a char*n
 *	void	VMSend()	-- signal end-of-record
 *	void	VMSunget(c)	-- unget one character
 *
 *  Reading is done on the stdio FILE VMSin, which is initially stdin.
 *  VMSin is set to 0 at EOF.
 *
 *  VMSend must be called exactly when and end-of-record comes along.
 *
 *  19-jul-90   pjt   - extra security in fread() for early EOF detection
 *   4-jan-91   pjt   - keep filepointer
 *
 */

#include <stdio.h>
#include "vmsget.h"
static void VMSerror(), VMSerror_d() ;
extern int totcount;
int location=0;

/******* Read a Short **************************************************/

short VMSgetS()
{
    char c[2] ;

    union {
	char c[2] ;
	short s ;
    } x ;

    VMSget( 2, c ) ;

    x.c[0] = c[1] ;
    x.c[1] = c[0] ;

    return x.s ;
}

/******* Read an Integer ***********************************************/

int VMSgetI()
{
    char c[4] ;

    union {
	char c[4] ;
	int i ;
    } x ;

    VMSget( 4, c ) ;

    x.c[0] = c[3] ;
    x.c[1] = c[2] ;
    x.c[2] = c[1] ;
    x.c[3] = c[0] ;

    return x.i ;
}

/******* Read a Float **************************************************/

float VMSgetR()
{
    char c[4] ;

    union {
	char c[4] ;
	float r ;
    } x ;

    VMSget( 4, c ) ;

    x.c[0] = c[1] ;
    x.c[1] = c[0] ;
    x.c[2] = c[3] ;
    x.c[3] = c[2] ;

    return x.r / 4.0 ;
}

/******* Read a Double *************************************************/

double VMSgetD()
{
    char c[8] ;

    union {
	char c[8] ;
	struct {
	    unsigned sign	: 1 ;
	    unsigned exp	: 8 ;
	    unsigned u3		:20 ;
	    unsigned u2		: 3 ;
	    unsigned u1		:29 ;
	    unsigned extra	: 3 ;
        } f ;
    } x ;

    union {
	struct {
	    unsigned sign	: 1 ;
	    unsigned exp	:11 ;
	    unsigned u3		:20 ;
	    unsigned u2		: 3 ;
	    unsigned u1		:29 ;
        } f ;
	double d ;
    } y ;

    VMSget( 8, c ) ;

    x.c[0] = c[1] ;
    x.c[1] = c[0] ;
    x.c[2] = c[3] ;
    x.c[3] = c[2] ;
    x.c[4] = c[5] ;
    x.c[5] = c[4] ;
    x.c[6] = c[7] ;
    x.c[7] = c[6] ;

    y.f.sign = x.f.sign ;
    y.f.exp = ( x.f.exp ? x.f.exp + 894 : 0 ) ;
    y.f.u1 = x.f.u1 ;
    y.f.u2 = x.f.u2 ;
    y.f.u3 = x.f.u3 ;

    return y.d ;
}

/*************************************************************************
 *
 *  get bytes from a VMS file
 *
 */

#define START	0
#define FIXED	1
#define VARIED	2

#define LENGTH	2042

static int count = 0 ;
static int mode = START ;
static int unget = 0 ;
static char ungetC ;

FILE *VMSin = stdin ;

/******* Read a Character*(*) ******************************************/

void VMSget( n, buff )
int n ;
char *buff ;
{
    int type, d , check;
    char msg[128];

    if( unget ) {
	unget = 0 ;
	buff[0] = ungetC ;
	if( n > 1 )
	    VMSget( n-1, buff+1 ) ;
	return ;
    }


    if( mode == START ) {
	count = LENGTH ;
        location = ftell(VMSin);
	type = getc(VMSin) ;
	if( type == EOF ) {
	    VMSin = (FILE *) 0 ;
	    return ;
        }

        location = ftell(VMSin);
	d = getc(VMSin) ;
	if(d)
	    VMSerror_d( "Illegal logical record label value", d ) ;

	switch(type) {
	case 0:
	case 1:
	    mode = FIXED ;
	    break ;
	case 2:
	case 3:
	    mode = VARIED ;
	    break ;
	default:
	    VMSerror_d( "Illegal logical record label type", type ) ;
	}
    }

    if( n <= count ) {
        location = ftell(VMSin);
	check= fread( buff, 1, n, VMSin ) ;
	if (check != n) {
            sprintf(msg,"fread_1(n): expected %d, read %d: ",n,check);
	    perror(msg);
	} 
	totcount += n;
	count -= n ;
    } else {
	if( mode == FIXED ) {
            location = ftell(VMSin);
	    check = fread( buff, 1, count, VMSin ) ;
	    if (check != count) {
                sprintf(msg,"fread_2(count): expected %d, read %d: ",count,check);
                perror(msg);
            }
            totcount += count;
            location = ftell(VMSin);
	    d = getc(VMSin) ;
	    if( d != '\n' )			/* bad backup expansion */
		ungetc( d, VMSin ) ;
	    mode = START ;
	    VMSget( n - count, buff + count ) ;
	} else
	    VMSerror( "logical record overrun" ) ;
    }
}

/******* Signal End-of-Record ******************************************/

void VMSend()
{
    int d ;

    location = ftell(VMSin);
    d = getc(VMSin) ;
    if( d != '\n' )				/* bad backup expansion */
	ungetc( d, VMSin ) ;
    if( (mode == FIXED) && (count != 0) )
	VMSerror( "unexpected VMSend call" ) ;
    mode = START ;
}

/******* Unget a Character *********************************************/

void VMSunget(c)
char c ;
{
    unget = 1 ;
    ungetC = c ;
}

/******* Report an Error ***********************************************/

static void VMSerror(c)
char *c ;
{
    (void) fprintf( stderr, "Bad VMS record: %s\n", c ) ;
    (void) fprintf( stderr, "At location = 0x%x\n", location ) ;
    (void) stop(1) ;
}

static void VMSerror_d(c, d)
char *c ;
int d ;
{
    (void) fprintf( stderr, "Bad VMS record: %s -- %d\n", c, d ) ;
    (void) fprintf( stderr, "At location = 0x%x\n", location ) ;
    (void) stop(1) ;
}
