typedef float FLOAT;
#define MAXNAX 3
#define private static
#define TRUE 1
#define FALSE 0
#define MAXARG 32
#define MAXLINE 256
#define max(a,b) ((a) >= (b) ? (a) : (b))
#define min(a,b) ((a) <= (b) ? (a) : (b))
#define abs(a)   ((a) >= 0   ? (a) : -(a))
#define PI 3.141592653589793
#define SKIP_WHITE(a) while( *(a) == ' ' || *(a) == '\t') (a)++
#define ERR_RETURN(a,b) {fprintf(stderr,a); return(b);}

typedef struct variable { int xdim,ydim,type,temporary;
			  struct variable *fwd;
			  FLOAT val[2];
		 	  char *name,*value; } VARIABLE;

#define TYPE_OTHER  0
#define TYPE_REAL   1
#define TYPE_CMPLX  2
#define TYPE_STRING 3
#define TYPE_VAR    4
#define TYPE_COORD  5

