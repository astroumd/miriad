/*
 * gethcfiles:   check out which files seem like HC files 
 *
 *  18-dec-90   skipping baseline* files too....
 *  12-aug-91   convex uses dirent, not direct (see also dio.c)
 *		also returned baseline file to normal status
 *  29-aug-91   also added pcal and gcal to list of ignorants
 *  14-oct-91   Another minimod for Convex (mjs)  
 *              We presume mjs added__convexc__ 
 *  12-mar-92   include convex #define back again
 */

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include <sys/types.h>

#if defined(__convexc__) || defined(convex)
#include <dirent.h>
#else
#include <sys/dir.h>
#endif


char *malloc() ;

static char *dname = ".";

static char *skipf[] = {     /* list of names to skip files 'name*' anyhow */
    "cbee",
    "notes",
    "log",
    "biglog",
    "watch",
    "pcal",
    "gcal",
/*    "baseline",		/* these are wideband visibility files though */
    NULL,
};

int gethcfiles( flist, nmax)
char *flist[] ;
int   nmax;
{
    DIR *dir ;
#if defined(__convexc__)	
    struct dirent *fentry ;
#else
    struct direct *fentry ;
#endif
    int i, next, cmp(), hcname(), hcfmt();

    dir = opendir( dname ) ;
    if( !dir ) {
	perror( dname ) ;
	return 0 ;
	}

    next = 0 ;
    while( fentry = readdir( dir ) ) {
	if( fentry->d_name[0] != '.') {   /* not starting with dot */
#if 1
            for (i=0 ; skipf[i]!=NULL; i++)  /* check if special skip file */
                if (strncmp(fentry->d_name,skipf[i],strlen(skipf[i]))==0) {
                    printf("%-20s:  skipping \n",fentry->d_name);
                    break;
                }
            if (skipf[i])
                continue;
#endif
    
            if ( (next+2) >= nmax) {
                printf("Warning: could only read %d entries from %s\n",
                        nmax, dname);
                break;
            }
            if (!hcname(fentry->d_name))
                continue;
	    if (!hcfmt(fentry->d_name))
                continue;
	    flist[next] = malloc( fentry->d_namlen + 1 ) ;
	    (void) strcpy( flist[next++], fentry->d_name ) ;
	}
    }
    qsort( (char *) flist, next, sizeof(char *), cmp ) ;
    closedir( dir ) ;

    if (next == 0)
        printf("Warning: no files found in directory %s\n",dname);
        
    return next ;
}

static int cmp(a, b)
char **a, **b ;
{
    return strcmp( *a, *b ) ;
}

static char *mon[] =
  { "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" };

/*
 *  hcname: see if one can ignore file on basis of the name only
 */

static int hcname(fname)
char *fname;
{
    char *cp;
    int i;

    cp = strchr(fname,'.');     /* look for extension */
    if (cp++ == NULL)
        return(0);
    if (strlen(cp) != 5)        /* must be ddmmm - hence 5 char's long */
        return(0);
    if (!isdigit(*cp) || !isdigit(*(cp+1)))
        return(0);
    cp++; cp++;
    for (i=0; i<12; i++)
        if (strncmp(cp,mon[i],3)==0)
            return(1);
    return(0);
}

/*
 * hcfmt: see if one can ignore file on basis of first umpty characters
 *        being pure ascii printable
 */

#define MAXTEST 100

static int hcfmt(fname)
char *fname;
{
    FILE *fp;
    char test[MAXTEST];
    int n, i, retval;
    
    fp = fopen(fname,"r");
    if (fp==NULL) {
        fprintf(stderr,"hcfmt: File %s couldn't be opened for testing\n");
        return(1);      /* assume it's OK */
    }

    n = fread(test,1,MAXTEST,fp);
    if (n<=0) {
        fprintf(stderr,"hcfmt: File %s returns %d on fread()\n",n);
        return(0);      /* assume this is BAD */
    }
    retval = 0;         /* assume worst case: file is not in hc fmt */
    for (i=0; i<n; i++)
        if ( !isspace(test[i]) && !isprint(test[i])) {
            retval=1;       /* looks like a binary thing: must be hc then */
            break;
        }
    fclose(fp);
    if (retval==0)
        fprintf(stderr,"### skipping %s: seems like an ascii file to me\n",
                fname);
    return(retval);
}
