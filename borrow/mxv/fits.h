/* fits.h
		Structure and constants used by fitsreader routines.
*/

/* Maximum dimension for a fits file.
This could probably be dynamic, but MXV only supports 3 anyway.
*/
#define MAXNAX 7

/* Typedefs and defines dealing with formats and conversions. */

typedef float FLOAT;

typedef struct { int ncards,naxis,axes[MAXNAX],offset,type,status,fd;
                 FLOAT bscale,bzero; } A_FITS_t;

/* Error codes returned by fits routines. */
#define	FITS_ERR_OK	0
#define	FITS_ERR_MEM	1	/* Mem alloc			*/
#define	FITS_ERR_BNDRY	2	/* IO beyond image boundary	*/
#define	FITS_ERR_IO	3	/* IO error			*/
#define	FITS_ERR_IOP	4	/* Illegal operation.		*/
#define	FITS_ERR_INDX	5	/* illegal coordinate index.	*/
#define	FITS_ERR_IOPAD	6	/* IO error during pad.		*/
#define	FITS_ERR_CARD	7	/* IO error reading/writing card*/

#ifdef FITS_READER
/* Error messages to go along with above error codes. Only needed in
fitsreader.
*/
static char *fits_errors[] = {
	"No error",
	"Ran out of memory.",
	"Attempt to read/write beyond image boundaries.",
	"I/O error.",
	"Illegal operation.",
	"Illegal coordinate index.",
	"I/O error while padding FITS file.",
	"I/O error while reading/writing card."
	};
#define NUM_FITS_ERRORS (sizeof(fits_errors)/sizeof(*fits_errors))
#endif

/* Global routines. */
char *fits_error(/*err*/);
void fitrdhdr(),fitrdhdi(),fitwrhdi(),fitwrhdl(),fitwrhda();
int fitwrhd(),fitrdhd(), fitwrhdr();
int fitread(), fitwrite(), fitclose(), fitsetpl();
char *fits_error(), *fitrdhda();
extern A_FITS_t *fitopen(/* name, status, naxis, nsize */);
extern float td_GetAxisValue(/*ds, index, axis, dorasin*/);
