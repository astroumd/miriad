/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				Sept 20, 1990
*
* NCSA HDF Version 3.10r2 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
* 
* We ask, but do not require, that the following message be included in all
* derived works:
* 
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
* 
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
* 
*****************************************************************************/

#ifdef RCSID
static char RcsId[] = "@(#)$Revision$"
#endif
/*
$Header$
$Log$
Revision 1.1  1993/10/09 01:42:47  teuben
Initial revision

 * Revision 3.6  90/09/20  11:07:32  clow
 * Added DFIseek and DFIread which are striped dpwn version
 * (without overhead of checking validity of the args)
 * of DFseek and DFread.
 * DFIseek and DFIread should only be called by other DF routines
 * which are certain about its parameters.
 * 
 * Revision 3.5  90/09/17  16:13:39  clow
 * added line in mopen() to truncate the file if it's created
 * 
 * Revision 3.4  90/06/29  10:07:31  mfolk
 * *** empty log message ***
 * 
 * Revision 3.3  90/05/23  15:53:29  clow
 * added MACRO "DF_OPENERR" to give uniform error open checking,
 * especially for unbufferred I/O open
 * 
*/
/*-----------------------------------------------------------------------------
 * File:    df.c
 * Purpose: HDF low level file access
 * Invokes: df.h
 * Contents: 
 *  DFImemcopy: copy bytes, on machines with no memcpy equivalents
 *  DFopen: open HDF file
 *  DFclose: close HDF file
 *  DFIseedDDs: read data descriptors into memory
 *  DFIcheck: check that dfile is a valid HDF file pointer
 *  DFdescriptors: return a list of the data descriptors in the HDF file
 *  DFnumber: count the number of occurrences of a given tag in the HDF file
 *  DFsetfind: set up a search
 *  DFfind: search for tag/ref combination
 *  DFIfind: internal routine to actually perform search
 *  DFIemptyDD: find an empty DD in the HDF file, or create one
 *  DFaccess: set up a read/write on a data element
 *  DFstart: set up a read/write on a data element
 *  DFread: read a portion of a data element
 *  DFseek: seek to new position within data element
 *  DFwrite: write portion of a data element
 *  DFupdate: write out updated DDs to HDF file
 *  DFstat: provide status information about HDF file
 *  DFgetelement: read an entire data element
 *  DFputelement: write an entire data element
 *  DFdup: create an additional descriptor for a data element
 *  DFdel: delete a data element
 *  DFnewref: Get an unused reference number
 *  DFishdf: is this an HDF file?
 *  DFerrno: return value of DFerror
 *  DFIerr: close a file saving DFerror, return -1, for error handling.
 * Remarks: These are the only routines which access HDF files directly
 *---------------------------------------------------------------------------*/

#define DFMASTER
#include "df.h"

#define CKMALLOC( x, ret) { if (!x) { DFerror = DFE_NOSPACE; return(ret); } }

#define CKSEEK(x,y,z, ret)  {  if (DF_SEEK( x,(long)y,z) <0) \
                {DFerror = DFE_SEEKERROR; return(ret); } }

#define CKSEEKEND(x,y,z, ret)   {  if (DF_SKEND( x,(long)y,z) <0) \
                {DFerror = DFE_SEEKERROR; return(ret); } }

#ifdef VMS
#define CKREAD(x,y,z,f, ret)    { \
                int32 currfileposn; \
                currfileposn = DF_TELL(f); \
                if (DF_READ( (char*)x, (int)(y), (int)(z), (f))<0) \
                { DFerror = DFE_READERROR; return(ret); } \
                DF_SEEK(f, (long) (currfileposn + y*z), 0); \
                }
#else /*VMS*/
#define CKREAD(x,y,z,f, ret)    { \
                if (DF_READ( (char*)x, (int)(y), (int)(z), (f))<0) \
                { DFerror = DFE_READERROR; return(ret); } \
                }
#endif /*VMS*/

#define CKWRITE(x,y,z,f, ret)   { if (DF_WRITE( (char*)x, (int)y, (int)z,f)<0) \
                {DFerror = DFE_WRITEERROR; return(ret); } }

/*
 *  Important Internal Variables
 */
static DF *DFlist=NULL;		/* pointer to list of open DFs */
static int DFinuse=0;		/* How many are currently in use */
static uint16 DFmaxref;		/* which is the largest ref used? */
static unsigned char *DFreflist=NULL; /* list of refs in use */
static unsigned char patterns[] = {0x80, 0x40, 0x20, 0x10, 0x08,
				       0x04, 0x02, 0x01};

#ifdef MAC

/*
*  Macintosh file stubs for HDF
*
*  Implement a subset of the C unbuffered file I/O stubs in the
*  Mac toolbox.
*/


static int hdfc = '????', hdft = '_HDF';

mopen(name, flags)
	char *name;
	int flags;
{
	short volref,rn;

	GetVol(NULL,&volref);
	
	if (flags & O_CREAT)	/* we need to create it */
		create(name, volref, hdfc, hdft);
	
	if (0 != fsopen(name, volref, &rn))
		return(-1);
		
	if (flags & O_CREAT)	/* and truncate it */
		SetEOF(rn, 0);

	return(rn);
}

mclose(rn)
	int rn;
{
	return(FSClose(rn));

}

mread(rn, buf, n)
	int rn,n;
	char *buf;
{
	if (0 != FSRead( rn, &n, buf))
		return(-1);
		
	return(n);

}

mwrite(rn, buf, n)
	int rn,n;
	char *buf;
{
	if (0 != FSWrite( rn, &n, buf))
		return(-1);
		
	return(n);
}

mlseek(rn, n, m)
	int rn,n,m;
{
	switch(m) {
		case 0:
		default:
			m = 1;
			break;
		case 1:
			m = 3;
			break;
		case 2:
			m = 2;
			break;
	}
	
	if (0 != SetFPos(rn, m, n))
		return(-1);
		
	if (0 != GetFPos(rn, &n))
		return(-1);
		
	return(n);
}
#endif /* MAC */

/*-----------------------------------------------------------------------------
 * Name:    DFImemcopy
 * Purpose: Copy bytes from one place to another
 * Inputs:  from, to: source and destination for copy
 *          length: number of bytes to copy
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, on machines without memcpy equivalents
 * Remarks: assumes non-overlapping
 *          Intended for machines on which memcppy etc. do not work
 *---------------------------------------------------------------------------*/

DFImemcopy( from, to, length)
char *from, *to;
register int length;
{
    length++;
    while (--length) *to++ = *from++;
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFopen
 * Purpose: open DF file if it exists, else create it if write access
 * Inputs:  name: name of file to open
 *          access: DFACC_READ, DFACC_WRITE, DFACC_CREATE, DFACC_ALL
 *          ndds: number of dds in a block
 * Returns: DF ptr to open file on success, NULL on failure with DFerror set
 * Invokes: DFIseedDDs 
 * Users:   HDF programmers, many HDF user-level routines, utilities
 * Remarks: Contains hooks for multiple DF files open simultaneously
 *---------------------------------------------------------------------------*/

DF *DFopen( name, access, ndds )
char *name;
int access;
int ndds;
{
    int created, i;             /* created is true if file is newly created */

                    /* error checking */
    DFerror = DFE_NOERROR;

    if (!(*name)) {                             /* check name */
        DFerror = DFE_BADNAME;
        return(NULL);
    }

    if ((access & (DFACC_ALL))!= access || access==0) {     /* check access */
        DFerror = DFE_BADACC;
        return(NULL); 
    }
    
    if (DFinuse >= DF_MAXDFS) {	/* is DF table filled up? */
        DFerror = DFE_TOOMANY; 
        return(NULL);  
    }
    
                /* open file, set it up */
        /* set up space for list of DFs */
    if (!DFlist) {
        DFlist = (DF *) DFIgetspace(DF_MAXDFS * sizeof(DF));
        for (i=0; i<DF_MAXDFS; i++)
            DFlist[i].type = 0;	/* mark free */
    }

        /* locate unused slot in table */
    for (i=0; i<DF_MAXDFS && DFlist[ i].type != 0; i++);

    if ( i>=DF_MAXDFS) {                            /* no free slot */
        DFerror = DFE_TOOMANY;
        return(NULL); 
    }

    if (access == DFACC_CREATE) {
        created = 1;
        access = DFACC_WRITE;                   /* equivalent to write */
    }
    else created = 0;

        /* does an extra open just to check if file exists */
    if (created || DF_OPENERR(DFlist[i].file = DF_OPEN(name, DF_RDACCESS))) {
        if (access<2) {         /* file does not exist, check if read access */
            DFerror = DFE_FNF;  /* file not found */
            return(NULL);
        }
#ifndef MAC
        close (DF_CREAT( name, 0666));  /* else create the file */
#else /* MAC */
		DF_CLOSE(DF_CREAT(name, 0666));
#endif 
        created=1;
    }
    else
        DF_CLOSE(DFlist[i].file);   /* open successful, close it */

        /* open file with correct access mode */
    if ( DF_OPENERR(DFlist[i].file = DF_OPEN( name, 
        ((access>1) ? DF_WRACCESS : DF_RDACCESS ))) ) {
        DFerror = DFE_BADOPEN;
        return(NULL);
    }

    if (created) {      /* Create a DDH and DD's for a new file */
        DFdd dd;
        DFddh ddh;
	char magick[4];
        int j;

	strncpy(magick, DF_MAGICK, 4); /* magick number */
        CKWRITE( magick,4,1,DFlist[i].file, NULL);

        ddh.next=0;                         /* only one DDH */
        if (ndds<=0) DFlist[i].defdds = DF_DEFAULTDDS;  
        else DFlist[i].defdds = ndds;       /* set up number of DDs in block */
        ddh.dds = DFlist[i].defdds;
        dd.tag=DFTAG_NULL;              /* set up empty DD */
        dd.ref=0;                       /* offset, length don't care */

#ifdef DF_STRUCTOK                      /* okay to write structures? */
        CKWRITE( &ddh, sizeof(DFddh), 1, DFlist[i].file, NULL); /* write it */
#else /*DF_STRUCTOK*/
        {
            register char *p;
            /* copy structure into buffer, write it out */
            p = DFtbuf;
            INT16WRITE( p, ddh.dds);    /* header */
            INT32WRITE( p, ddh.next);
            CKWRITE( DFtbuf, 6, 1, DFlist[i].file, NULL);   /* 6=header size */
        }
#endif /*DF_STRUCTOK*/

        for (j=0; j<ddh.dds; j++) {             /* write out DDs */
#ifdef DF_STRUCTOK
            CKWRITE( &dd, sizeof(DFdd),1, DFlist[i].file, NULL);
#else /*DF_STRUCTOK*/
            {
                register char *p;
                p = DFtbuf;
                UINT16WRITE( p, dd.tag);
                UINT16WRITE( p, dd.ref);
                INT32WRITE( p, dd.offset);
                INT32WRITE( p, dd.length);
                CKWRITE( DFtbuf, 12, 1, DFlist[i].file, NULL); /* 12=DD size */
            }
#endif /*DF_STRUCTOK*/
        }
    }
    else {			/* if file already exists */
         char magick[4];

        CKREAD( magick, 4, 1, DFlist[i].file, NULL); /* check magick number */
        if ( strncmp(magick,DF_MAGICK,4)) {
            DFerror = DFE_NOTDFFILE;
            DF_CLOSE(DFlist[i].file);
            return(NULL);
        }
    }

    /* store status information in struct */
    if (ndds<=0) DFlist[i].defdds = DF_DEFAULTDDS;  
    else DFlist[i].defdds = ndds;
    DFlist[i].access=access;
    DFlist[i].list = NULL;
    DFlist[i].changed=0;
    DFlist[i].last_tag= 0;
    DFlist[i].last_ref= 0;
    DFlist[i].type=1;
    DFlist[i].up_access=0;
    DFlist[i].up_dd = NULL;

            /* read DDs and store the information in internal structure */
    if (DFIseedDDs( &DFlist[i]) <0) return(NULL);

    if (created) {                  /* create MT if new file */
        DFdd *dd;
        dd = &(DFlist[i].list->next->dd[0]);    /* first dd is in 2nd dle */
        dd->tag = DFTAG_MT;
        dd->ref = DF_MT;
        dd->offset = 0;
        dd->length = 0;
    }
    DFinuse++;                      /* no of DF slots in use */
    return( &DFlist[i]);            /* DF file pointer */
}


/*-----------------------------------------------------------------------------
 * Name:    DFclose
 * Purpose: Write out updated DDs, close DF file
 * Inputs:  dfile: pointer to open DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Invokes: DFIcheck
 * Users:   HDF programmers, many HDF user-level routines, utilities
 *---------------------------------------------------------------------------*/

int DFclose( dfile)
DF *dfile;
{
    DFdle *prev, *current;          /* DLEs being written out */
    int i;

    DFerror = DFE_NOERROR;

    if ( DFIcheck(dfile))           /* is dfile a valid pointer? */
        return(-1);

    if (dfile->type!=1) {           /* 0 is a closed file  or unused slot */
        DFerror= DFE_NOTOPEN;
        return(-1);
    }

    prev=dfile->list;               /* start of DLE list */

    while (current=prev->next) {        /* for all DLEs */
        if (dfile->changed) {           /* if file modified, write it out */
                /* current DD should be written at location prev->ddh.next */
            CKSEEK( dfile->file, (long) prev->ddh.next,0, -1);
            if (current->ddh.dds) {     /* if any DDs to write out */
#ifdef DF_STRUCTOK
                CKWRITE( &current->ddh, sizeof(DFddh)+
                    current->ddh.dds*sizeof(DFdd), 1, dfile->file, -1);
#else /*DF_STRUCTOK*/
                {           /* write out dd struct elements */
                    register  char *p;
                    p = DFtbuf;
                    INT16WRITE( p, current->ddh.dds);
                    INT32WRITE( p, current->ddh.next);
                    for (i=0; i<current->ddh.dds; i++) {
                        UINT16WRITE( p, current->dd[i].tag);
                        UINT16WRITE( p, current->dd[i].ref);
                        INT32WRITE( p, current->dd[i].offset);
                        INT32WRITE( p, current->dd[i].length);
                    }
                    CKWRITE( DFtbuf, 6+i*12, 1, dfile->file, -1);
                            /* 6=size of DDH, 12=size of DD */
                }
#endif /*DF_STRUCTOK*/
            }
        }
        DFIfreespace((char*)prev);
        prev=current;
    }
    DFIfreespace((char*)prev); /* get rid of the last one */

    if ( (DF_CLOSE( dfile->file)) !=0) {
        DFerror = DFE_CANTCLOSE;
        return(-1);
    }

                    /* reset structure values */
    dfile->last_ref= 0;
    dfile->last_tag= 0;
    dfile->type=0;
    dfile->access=0;
    dfile->file= 0;
    dfile->list= (DFdle *) 0L;
    DFinuse--;
    return(0);
}   


/*-----------------------------------------------------------------------------
 * Name:    DFIseedDDs
 * Purpose: read DDs in file into memory
 * Inputs:  dfile: pointer to open DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DFopen
 *---------------------------------------------------------------------------*/

int DFIseedDDs(dfile)
DF *dfile;
{
    DFdle *list;
    DFddh ddh;
    int i,n;                        /* n = no. of DDs in block */
    
    DFerror = DFE_NOERROR;

    if (dfile->list) {
        DFerror = DFE_SEEDTWICE;    /* ### NOTE: Internal error! */
        return(-1);
    }
    
    dfile->list= (DFdle *) DFIgetspace(sizeof(DFdle));
    /* includes one DD - unused */
    CKMALLOC( dfile->list, -1);

    list=dfile->list;
    list->next=NULL;                /* No other lists (yet) */
    list->ddh.next= (int32)4L;      /* next is at 4 in file */
    list->ddh.dds= -1;              /* flag so this is not written */

    DFmaxref = 0;                   /* largest ref found till now is 0 */

    while (list->ddh.next) {        /* while more headers to read */
        CKSEEK( dfile->file, list->ddh.next, 0, -1);

                            /* read headers */
#ifdef DF_STRUCTOK
        CKREAD( &ddh, sizeof(DFddh), 1, dfile->file, -1);
#else /*DF_STRUCTOK*/
        {
            register  char *p;
            p = DFtbuf;
            CKREAD( DFtbuf, 6, 1, dfile->file, -1);     /* 6 = size of header */
            INT16READ( p, ddh.dds);
            INT32READ( p, ddh.next);
        }
#endif /*DF_STRUCTOK*/
        n   =ddh.dds;

	/* read in DDs */
        list->next= (DFdle *)
	    DFIgetspace((unsigned)
			(sizeof(DFdle)+ (n-1)* sizeof(DFdd)));
				/* note space for 1 DD included in DLE */
        CKMALLOC( list->next, -1);
        list=list->next;
        list->next=NULL;
    
        DFmovmem((char*)&ddh, (char*)&(list->ddh),
		 sizeof(DFddh) ); /* Copy ddh */

        if (n) {
#ifdef DF_STRUCTOK
            CKREAD( &list->dd[0], sizeof(DFdd), n, dfile->file, -1);
	    /* load DD's */
#else /*DF_STRUCTOK*/
            {
                register  char *p;
                p = DFtbuf;
                CKREAD( DFtbuf, n*12, 1, dfile->file, -1);  /* 12=size of DD */
                for (i=0; i<n; i++) {
                    UINT16READ( p, list->dd[i].tag);
                    UINT16READ( p, list->dd[i].ref);
                    INT32READ( p, list->dd[i].offset);
                    INT32READ( p, list->dd[i].length);
                }
            }
#endif /*DF_STRUCTOK*/
        }
                /* Remember highest ref found - ignore MTs */
        for (i=0; i<n; i++)
            if ((list->dd[i].ref > DFmaxref) && (list->dd[i].tag != DFTAG_MT))
                                     DFmaxref = list->dd[i].ref;
    }
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFIcheck
 * Purpose: check if dfile argument represents a valid DF file
 * Inputs:  dfile: pointer to open DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, several routines in this file
 *---------------------------------------------------------------------------*/

int DFIcheck( dfile)
DF *dfile;
{
    DFerror = DFE_NOERROR;
    
    if (!dfile) {
        DFerror = DFE_DFNULL;
        return(-1);
        }

    if ((dfile->access & DFACC_ALL) != dfile->access)
        DFerror = DFE_BADACC;

    if ((dfile->type >1) || (dfile->type <-1))
        DFerror = DFE_ILLTYPE;

    if (!dfile->list)
        DFerror= DFE_BADDDLIST;

    if (DFerror)
        return(-1);
    else
        return(0);

}


/*-----------------------------------------------------------------------------
 * Name:    DFdescriptors
 * Purpose: return a list of all the DDs in the file
 * Inputs:  dfile: pointer to open DF file
 *          ptr: pointer to space for the list of DDs
 *          begin, num: the list starts at DD numbered begin, and contains
 *              a maximum of num entries
 * Returns: number of DDs returned in the list
 * Invokes: DFIcheck
 * Users:   HDF programmers, other routines and utilities
 *---------------------------------------------------------------------------*/

int DFdescriptors(dfile, ptr, begin, num)
DF *dfile;
DFdesc ptr[];
int begin, num;
{
    DFdle *DLEp;
    int i,ddnum=0;

    if ( DFIcheck(dfile))
        return(-1);
    
    if (begin<0) begin = 0;
    if (num<0) num = 0;
    ddnum = 0;
    for (DLEp=dfile->list; DLEp; DLEp=DLEp->next)
        for (i=0; i<DLEp->ddh.dds; i++, ddnum++)
            if (ddnum>=begin) {
                if (ddnum<begin+num) {
                    ptr[ddnum-begin] = DLEp->dd[i];
                }
                else
                    return(num);
            }
    return(ddnum-begin);
}


/*-----------------------------------------------------------------------------
 * Name:    DFnumber
 * Purpose: return the number of occurrences of the given tag in the HDF file
 * Inputs:  dfile: pointer to open DF file
 *          tag: tag to count occurrences of
 * Returns: number of occurrences of tag in file, -1 on error with DFerror set
 *          if tag is DFTAG_WILDCARD, count occurrences of all tags
 * Invokes: DFIcheck
 * Users:   HDF programmers, other routines and utilities
 *---------------------------------------------------------------------------*/

int DFnumber(dfile, tag)
DF *dfile;
uint16 tag;
{
    DFdle *DLEp;
    int i, ntag=0;

    if ( DFIcheck(dfile))
        return(-1);
    
    for (DLEp=dfile->list; DLEp; DLEp=DLEp->next)
        if (tag==DFTAG_WILDCARD) ntag += DLEp->ddh.dds;
        else {
            for (i=0; i<DLEp->ddh.dds; i++)
                if (DLEp->dd[i].tag == tag) ntag++;
        }

    return(ntag);
}


/*-----------------------------------------------------------------------------
 * Name:    DFsetfind
 * Purpose: set up parameters for a wildcard find
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: tag and ref of element to search for, 0 is wildcard
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck
 * Users:   HDF programmers, several utilities
 *---------------------------------------------------------------------------*/

int DFsetfind( dfile, tag, ref)
DF *dfile;
uint16 tag,ref;
{

    if ( DFIcheck(dfile))
        return(-1);
    
        /* remember tag, ref for subsequent searches */
    dfile->last_tag=tag;
    dfile->last_ref=ref;
    dfile->last_dle=NULL;           /* flag value: nothing found so far */

    return(0);
}
    

/*-----------------------------------------------------------------------------
 * Name:    DFfind
 * Purpose: perform wildcard searches - sets up parameters, calls DFIfind
 * Inputs:  dfile: pointer to open DF file
 *          ptr: ptr to put in DD when found
 * Returns: 0 on success, -1 on failure
 *          if success, DD matching specification is copied to *ptr
 * Invokes: DFIcheck, DFIfind
 * Users:   HDF programmers, several utilities
 *---------------------------------------------------------------------------*/

int DFfind(dfile, ptr)
DF *dfile;
DFdesc *ptr;
{
    DFdle *cDLEp;
    int cdd;
    uint16 tag, ref, ltag,lref;
    int isfirst=1;

    if ( DFIcheck(dfile))
        return(-1);

    DFerror = DFE_NOERROR;

    tag = dfile->last_tag;          /* tag, ref being searched for */
    ref = dfile->last_ref;

    if (dfile->last_dle) {          /* something found previously */
        isfirst = 0;
        ltag= dfile->last_dle->dd[ dfile->last_dd ].tag;    /* prev tag, ref */
        lref= dfile->last_dle->dd[ dfile->last_dd ].ref;
    } else {
	ltag = lref = 0;
    }

    if ((tag!=DFTAG_NULL) &&        /* empty DDs are invisible on finds */
        !DFIfind( dfile, tag, ref, isfirst, ltag, lref, &cDLEp, &cdd)) {
        *ptr = cDLEp->dd[cdd];      /* if found, copy dd to ptr */
        dfile->last_dd = cdd;       /* set last_dle and last_dd to DD found */
        dfile->last_dle= cDLEp;
        return(0);
    } else {
        DFerror = DFE_NOMATCH;
        ptr->tag = 0;
        ptr->ref = 0;
        return(-1);
    }
}
        

/*-----------------------------------------------------------------------------
 * Name:    DFIfind
 * Purpose: perform wildcard searches
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: tag, ref (possibly wildcard) being searched for
 *          isfirst: 1 if first call to DFIfind for this tag/ref, else 0
 *          ltag, lref: last tag and ref returned for this search,
 *              don't care if isfirst set
 *          cDLEp, cddp: pointers to DLE and DD number to return matched DD in
 * Returns: 0 on success, -1 on failure
 *          if success, cDLEp and cddp are set to point to matched DD
 * Users:   HDF system programmers, DFfind, HDF utilities, many routines
 * Remarks: The searching algorithm is a little complex.  It returns entries
 *          in the sorting order of refs, then tags.  Even after a candidate
 *          is found, searching continues till best candidate found.  Best way
 *          to check if conditions: work it out independently for yourself!
 *---------------------------------------------------------------------------*/

int DFIfind( dfile, tag, ref, isfirst, ltag, lref, cDLEp, cddp)
DF *dfile;
DFdle **cDLEp;
int *cddp;
int isfirst;                            /* 1 if no prev search, 0 otherwise */
uint16 tag, ref, ltag, lref;
{
    DFdle *DLEp;
    int i, found=0;
    uint16 ctag=0, cref=0, wtag,wref; /* ctag, cref: tag, ref found so far */
                                      /* wtag, wref: tag, ref being checked */

    DLEp=dfile->list;               /* start of DLE list */

    if (tag && ref) {               /* No wildcards */
        if (isfirst) {              /* if not already found */
            while (DLEp) {          /* go through list */
                for (i=0; i<DLEp->ddh.dds; i++) {       /* for all DDs */
                    if (DLEp->dd[i].tag==tag &&
                            DLEp->dd[i].ref==ref)
                        {*cDLEp=DLEp; *cddp=i; return(0);}
                    }
                DLEp=DLEp->next;
                }
            }
        }
    else if (tag && !ref)           /* wildcard ref */
        while (DLEp) {
            for (i=0; i<DLEp->ddh.dds; i++) {
                wtag=DLEp->dd[i].tag;
                wref=DLEp->dd[i].ref;
        /* condition = tag match, better than found so far (if any),
            follows what was returned last time (if any) */
                if ( (wtag==tag) && (!found || (wref<cref)) &&
                    (isfirst || (wref>lref)))
                    { ctag=wtag; cref=wref; *cDLEp=DLEp; *cddp=i;found=1;}
                }
            DLEp=DLEp->next;
            }
    else if (!tag && ref)           /* wildcard tag */
        while (DLEp) {
            for (i=0; i<DLEp->ddh.dds; i++) {
                wtag=DLEp->dd[i].tag;
                wref=DLEp->dd[i].ref;
                if ((wref==ref) && (isfirst || (wtag>ltag)) &&
                    (!found || (wtag<ctag)) )
                    { ctag=wtag; cref=wref; *cDLEp=DLEp; *cddp=i;found=1;}
                }
            DLEp=DLEp->next;
            }
    else if (!tag && !ref)          /* wildcard tag & ref */
        while (DLEp) {
            for (i=0; i<DLEp->ddh.dds; i++) {
                wtag=DLEp->dd[i].tag;
                wref=DLEp->dd[i].ref;
                if ((isfirst || (wref>lref) || (wref==lref && wtag>ltag)) &&
                    (!found || (wref<cref) || (wref==cref && wtag<ctag)) &&
                    (wtag!=DFTAG_NULL))         /* empty DDs are invisible */
                    { ctag=wtag; cref=wref; *cDLEp=DLEp; *cddp=i;found=1;}
                }
            DLEp=DLEp->next;
            }
    return(found-1);            /* 0 or -1 */
}


/*-----------------------------------------------------------------------------
 * Name:    DFIemptyDD
 * Purpose: find an empty DD to use, or create a block of DDs if necessary
 * Inputs:  dfile: pointer to open DF file
 * Returns: pointer to an empty DD
 * Invokes: DFIfind
 * Users:   HDF system programmers, DFaccess, DFdup
 *---------------------------------------------------------------------------*/

DFdd *DFIemptyDD(dfile)
DF *dfile;
{
    DFdle *cDLEp;
    int cdd;

    if (!DFIfind( dfile, DFTAG_NULL, DFREF_WILDCARD, 1, 0, 0, &cDLEp, &cdd))
        return(&(cDLEp->dd[cdd]));      /* there is an empty DD */

    else {          /* add new DDH block */
        int32 fpos;
        DFdle *p, *dle;
        DFddh ddh;
        DFdd dd;
        int j;

        CKSEEKEND( dfile->file, (long) 0, 2, NULL); /* go to end of df */
        fpos= (int32) DF_TELL(dfile->file);
        ddh.dds= dfile->defdds;             /* Initialize ddh */
        ddh.next= 0;
        dd.tag=DFTAG_NULL;                  /* and all DD's */
        dd.ref=0;
#ifdef DF_STRUCTOK
        CKWRITE( &ddh, sizeof(DFddh), 1, dfile->file, NULL);
#else /*DF_STRUCTOK*/
        {
            register  char *p;
            p = DFtbuf;
            INT16WRITE( p, ddh.dds);
            INT32WRITE( p, ddh.next);
            CKWRITE( DFtbuf, 6, 1, dfile->file, NULL);  /* 6 = size of header */
        }
#endif /*DF_STRUCTOK*/
        for (j=0; j<ddh.dds; j++) {
#ifdef DF_STRUCTOK
            CKWRITE( &dd, sizeof(DFdd),1, dfile->file, NULL);
#else /*DF_STRUCTOK*/
            {
                register  char *p;
                p = DFtbuf;
                UINT16WRITE( p, dd.tag);
                UINT16WRITE( p, dd.tag);
                INT32WRITE( p, dd.offset);
                INT32WRITE( p, dd.length);
                CKWRITE( DFtbuf, 12, 1, dfile->file, NULL); /* 12=size of dd */
            }
#endif /*DF_STRUCTOK*/
        }

        p=dfile->list;                      /* find end of list */
        while (p->next) p= p->next;

        p->ddh.next=fpos;                   /* new dd goes at end of file */
        dle=(DFdle *)
	    DFIgetspace((unsigned)
			(sizeof(DFdle)+(ddh.dds-1)*sizeof(DFdd)));
                            /* one dd included in dle */
        CKMALLOC(dle, NULL);
        p->next=dle;                        /* insert dle at end of list */
        dle->next=NULL;
        DFmovmem((char*)&ddh, (char*)&dle->ddh,sizeof(DFddh));
        for (j=0; j<ddh.dds; j++)
            DFmovmem( (char*)&dd, (char*)&dle->dd[j], sizeof(DFdd));
        return(&(dle->dd[0]));
    }
#ifdef PC
    return(NULL);           /* dummy, for return value checking */
#endif /*PC*/
}


/*-----------------------------------------------------------------------------
 * Name:    DFaccess
 * Purpose: set up read/write access to a data element
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: id of element
 *          access: "r", "w", "a" (append)
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck, DFIfind, DFIemptyDD
 * Users:   HDF programmers, utilities, DFgetelement, DFputelement
 * Remarks: if "a", data element will be copied to end of file, since it
 *          cannot be extended in place if it is in the middle of the file
 *---------------------------------------------------------------------------*/

int DFaccess(dfile, tag, ref, access)
DF *dfile;
uint16 tag, ref;
char *access;
{
    DFdle *cDLEp;
    int cdd;
     char *storage=NULL;        /* for copying data if append access */
    char accmode;
    
    DFerror = DFE_NOERROR;
 
    if (DFIcheck(dfile) )
        return( -1);

    if (!tag) {
        DFerror = DFE_BADTAG;
        return(-1);
    }
    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }
            /* set up and check access modes */
    accmode = *access;
    switch (accmode) {
        case 'r':   dfile->up_access = DFACC_READ;  break;
        case 'a':
        case 'w':   dfile->up_access = DFACC_WRITE; break;
        default:    DFerror = DFE_BADACC;   return(-1); 
    }
    if ((dfile->up_access & dfile->access) != dfile->up_access) {
        DFerror = DFE_BADACC;
        return(-1);
    }
                    
                /* Find DD of element to be updated */
    if (!DFIfind( dfile, tag, ref, 1, 0 , 0, &cDLEp, &cdd))
        dfile->up_dd = &(cDLEp->dd[cdd]);   /* DD of element to be updated */

    else {              /* No such DD */
        if (accmode=='r') {
            DFerror = DFE_NOMATCH; 
            return(-1);
        }
        accmode = 'w';          /* append is really write if no current data */
        dfile->up_dd = DFIemptyDD(dfile);       /* find an empty DD to use */
        if (!dfile->up_dd) return(-1);
        dfile->up_dd->tag = tag;                    /* fill in DD block */
        dfile->up_dd->ref = ref;
        dfile->up_dd->length = 0;
    }

    if (accmode!='w') {		/*for read, DFaccess positions fp at element */
                                /* for append also, we need to read element */
        CKSEEK(dfile->file, (long) dfile->up_dd->offset, 0, -1);
        }
    else dfile->up_dd->length = 0;  /* throws away any existing data */

    if (accmode!='r') {
        dfile->changed = 1;         /* if write/append, file modified */

        if ((accmode=='a') && (dfile->up_dd->length)) {
                    /* allocate storage to read current data */
                storage = (char*)DFIgetspace((unsigned)(dfile->up_dd->length));
                CKMALLOC( storage, -1 );
                CKREAD( storage, dfile->up_dd->length, 1, dfile->file, -1);
        }

        CKSEEKEND( dfile->file, (long) 0, 2, -1);   /* go to end of df */
            /* find the offset of the end of file */
        dfile->up_dd->offset = (int32) DF_TELL(dfile->file);

        if ((accmode=='a') && dfile->up_dd->length) {   /* copy old data */
            CKWRITE( storage, dfile->up_dd->length, 1, dfile->file, -1);
                /* note this leaves fp positioned correctly for write */
        }
        if (storage) DFIfreespace(storage);
    }

    if (DFmaxref < ref) DFmaxref = ref;                 /* note ref is used */
    if (DFreflist) DFreflist[ref/8] |= patterns[ref%8]; /* set ref'th bit */

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFstart
 * Purpose: set up read/write access to a data element - alternate to DFaccess
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: id of element
 *          access: "r", "w", "a" (append)
 * Returns: 0 on success, -1 on failure
 * Invokes: DFaccess
 * Users:   Accidental/old-time users, intending to use DFaccess
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFstart(dfile, tag, ref, access)
DF *dfile;
uint16 tag, ref;
char *access;
{

    return(DFaccess(dfile, tag, ref, access));
}
        

/*-----------------------------------------------------------------------------
 * Name:    DFread
 * Purpose: read bytes from DF file (part of element specified by DFaccess)
 * Inputs:  dfile: pointer to open DF file
 *          ptr: pointer to space to read data into
 *          len: number of bytes to read
 * Returns: number of bytes read on success, -1 on failure
 * Invokes: DFIcheck
 * Users:   HDF programmers, DFgetelement
 *---------------------------------------------------------------------------*/

int32 DFread( dfile, ptr, len)
DF *dfile;
char *ptr;
int32 len;
{
    int32 maxlen;
#ifdef VMS
    int32 totalread;
    int32 readsize;
#endif /*VMS*/

    DFerror = DFE_NOERROR;
 
    if (DFIcheck(dfile) )
        return( (int32) -1);

    if (!dfile->up_dd) {
        DFerror = DFE_BADCALL;
        return((int32) -1);
    }

    if (!(dfile->up_access & DFACC_READ)) {
        DFerror = DFE_BADACC;
        return((int32) -1);
    }

    if (!ptr) {
        DFerror = DFE_BADPTR;
        return((int32) -1);
    }

    maxlen = dfile->up_dd->length -
                ((int32) DF_TELL(dfile->file) - dfile->up_dd->offset);
    if (len>maxlen) len = maxlen;
    if (len<0) {            /* will also catch reads from beyond element */
        DFerror = DFE_BADLEN;
        return(-1);
    }

#ifdef VMS
    totalread = 0;
    while (totalread<len) {
        readsize = len - totalread;
        if (readsize>512) readsize = 512;
        CKREAD( &ptr[totalread], (int)readsize, 1, dfile->file, -1); 
        totalread += readsize;
    }
        
#else /*VMS*/
    if (len) {      /* NOTE: cast to (int) will limit to 64K on 16 bit m/cs */
        CKREAD( ptr, (int) len, 1, dfile->file, -1); 
    }
#endif /*VMS*/

    return(len);
}


/* Simplified version without the overhead.  This is useful if you */
 /* know that the args are okay, and if you need to read many time */
 /* (like in a loop in DFSDIgetslice()) */
int32 DFIread( dfile, ptr, len)
DF *dfile;
char *ptr;
int32 len;
{
    int32 maxlen;
#ifdef VMS
    int32 totalread;
    int32 readsize;
#endif /*VMS*/
    maxlen = dfile->up_dd->length -
                ((int32) DF_TELL(dfile->file) - dfile->up_dd->offset);
    if (len>maxlen) len = maxlen;
    if (len<0) {            /* will also catch reads from beyond element */
        DFerror = DFE_BADLEN;
        return(-1);
    }

#ifdef VMS
    totalread = 0;
    while (totalread<len) {
        readsize = len - totalread;
        if (readsize>512) readsize = 512;
        CKREAD( &ptr[totalread], (int)readsize, 1, dfile->file, -1); 
        totalread += readsize;
    }
        
#else /*VMS*/
    if (len) {      /* NOTE: cast to (int) will limit to 64K on 16 bit m/cs */
        CKREAD( ptr, (int) len, 1, dfile->file, -1); 
    }
#endif /*VMS*/

    return(len);
}


/*-----------------------------------------------------------------------------
 * Name:    DFseek
 * Purpose: seek to a position, within element specified by DFaccess
 * Inputs:  dfile: pointer to open DF file
 *          offset: offset from beginning of element
 * Returns: offset of actual position seek'ed to from beginning of element
 * Invokes: DFIcheck
 * Users:   HDF programmers
 *---------------------------------------------------------------------------*/

int32 DFseek( dfile, offset)
DF *dfile;
int32 offset;
{
    
    DFerror = DFE_NOERROR;
 
    if (DFIcheck(dfile) )
        return( -1);

    if (!dfile->up_dd) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    if (!(dfile->up_access & DFACC_READ)) {
        DFerror = DFE_BADACC;
        return(-1);
    }

    if (offset > dfile->up_dd->length) {
        offset = dfile->up_dd->length;
        DFerror = DFE_BADSEEK;
    }

    CKSEEK( dfile->file, (long) dfile->up_dd->offset + offset, 0, -1);
    return(offset);
}

/* Simplified version without the overhead.  This is useful if you */
 /* know that the args are okay, and if you need to seek many time */
 /* (like in a loop in DFSDIgetslice()) */
int32 DFIseek( dfile, offset)
DF *dfile;
int32 offset;
{
    CKSEEK( dfile->file, (long) dfile->up_dd->offset + offset, 0, -1);
    return(offset);
}

/*-----------------------------------------------------------------------------
 * Name:    DFwrite
 * Purpose: write bytes to DF file (part of element specified by DFaccess)
 * Inputs:  dfile: pointer to open DF file
 *          ptr: pointer to data to be written
 *          len: number of bytes to written
 * Returns: number of bytes written on success, -1 on failure
 * Invokes: DFIcheck
 * Users:   HDF programmers, DFputelement
 *---------------------------------------------------------------------------*/

int32 DFwrite( dfile, ptr, len)
DF *dfile;
char *ptr;
int32 len;
{
#ifdef VMS
    int32 totalwritten;
    int32 writesize;
#endif /*VMS*/

    DFerror = DFE_NOERROR;
 
    if (DFIcheck(dfile) )
        return( -1);

    if (!(dfile->up_dd)) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    if (!(dfile->up_access & DFACC_WRITE)) {
        DFerror = DFE_RDONLY;
        return(-1);
    }

    if (!ptr) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (len<0) {
        DFerror = DFE_BADLEN;
        return(-1);
    }

    if (!(dfile->changed)) {        /* if an update between writes, re-seek */
      CKSEEK( dfile->file, (long) dfile->up_dd->offset + dfile->up_dd->length,
            0, -1);
    }

#ifdef VMS
    totalwritten = 0;
    while (totalwritten<len) {
        writesize = len - totalwritten;
        if (writesize>512) writesize = 512; /* write at most 512 at a time */
        CKWRITE( &ptr[totalwritten], (int)writesize, 1, dfile->file, -1); 
        totalwritten += writesize;
    }
#else /*VMS*/
    if (len) { CKWRITE( ptr, len, 1, dfile->file, -1); }
#endif /*VMS*/
    dfile->up_dd->length += len;
    return(len);
}


/*-----------------------------------------------------------------------------
 * Name:    DFupdate
 * Purpose: write out updated DD blocks to file
 * Inputs:  dfile: pointer to open DF file
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck
 * Users:   HDF programmers
 *---------------------------------------------------------------------------*/

int DFupdate( dfile)
DF *dfile;
{
    DFdle *prev, *current;
    int i;

    DFerror = DFE_NOERROR;

    if ( DFIcheck(dfile))
        return(-1);

    if (dfile->type!=1) {
        DFerror= DFE_NOTOPEN;
        return(-1);
    }

    prev=dfile->list;           /* start of DLE list */

    if (dfile->changed) {           /* modified */
        while (current=prev->next) {
            CKSEEK( dfile->file, (long) prev->ddh.next,0, -1);
            if (current->ddh.dds) {
#ifdef DF_STRUCTOK
                CKWRITE( &current->ddh, sizeof(DFddh) +
                    (current->ddh.dds*sizeof(DFdd)), 1, dfile->file, -1);
#else /*DF_STRUCTOK*/
                {
                    register  char *p;
                    p = DFtbuf;
                    INT16WRITE( p, current->ddh.dds);
                    INT32WRITE( p, current->ddh.next);
                    for (i=0; i<current->ddh.dds; i++) {
                        UINT16WRITE( p, current->dd[i].tag);
                        UINT16WRITE( p, current->dd[i].ref);
                        INT32WRITE( p, current->dd[i].offset);
                        INT32WRITE( p, current->dd[i].length);
                    }
                    CKWRITE( DFtbuf, 6+i*12, 1, dfile->file, -1);
                        /* 6= size of DDH, 12=size of DD */
                }
#endif /*DF_STRUCTOK*/
            }
            prev=current;
        }
        DF_FLUSH(dfile->file);              /* ensure everything is written */
    }
    dfile->changed=0;
    return(0);
}   


/*-----------------------------------------------------------------------------
 * Name:    DFstat
 * Purpose: provide status information about DF file
 * Inputs:  dfile: pointer to open DF file
 *          dfinfo: ptr to space where to place information on HDF file
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck
 * Users:   HDF programmers
 *---------------------------------------------------------------------------*/

int DFstat(dfile, dfinfo)
DF *dfile;
struct DFdata *dfinfo;
{

    DFerror = DFE_NOERROR;
 
    if (DFIcheck(dfile) )
        return( -1);

        /* This is version number of program.  More will be added later */
    dfinfo->version = DFVERSION;
    return(0);
}
    

/*-----------------------------------------------------------------------------
 * Name:    DFgetelement
 * Purpose: read a data element from df file
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: id of data element
 *          ptr: space to put data element in
 * Returns: number of bytes read on success, -1 on failure
 * Invokes: DFaccess, DFread
 * Users:   HDF programmers, utilities, many other routines
 *---------------------------------------------------------------------------*/

int32 DFgetelement( dfile, tag, ref, ptr)
DF *dfile;
uint16 tag, ref;
char *ptr;
{
    if ( DFaccess( dfile, tag, ref, "r")<0) return((int32) -1);
    return( DFread( dfile, ptr, (int32) dfile->up_dd->length));
}


/*-----------------------------------------------------------------------------
 * Name:    DFputelement
 * Purpose: write a data element to df file
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: id of data element
 *          ptr: pointer to data element to be written
 *          len: length of data element
 * Returns: 0 on success, -1 on failure
 * Invokes: DFaccess, DFwrite
 * Users:   HDF programmers, utilities, many other routines
 *---------------------------------------------------------------------------*/

int DFputelement( dfile, tag, ref, ptr, len)
DF *dfile;
uint16 tag, ref;
 char *ptr;
int32 len;
{
    if ( DFaccess( dfile, tag, ref, "w")<0) return(-1);
    if( DFwrite( dfile, ptr, len)<0) return(-1);
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFdup
 * Purpose: Add a new tag/ref for existing data
 * Inputs:  dfile: pointer to open DF file
 *          itag, iref: new id of data element
 *          otag, oref: current id of data element
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck, DFIfind, DFIemptyDD
 * Users:   HDF programmers, utilities, many other routines
 *---------------------------------------------------------------------------*/

int DFdup(dfile, itag, iref, otag, oref)
DF *dfile;
uint16 itag, iref, otag, oref;  /* new, existing tag/refs */
{
    DFdle *odlep, *idlep;
    int ocdd, icdd;
    DFdd *newdd;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile) )
        return( -1);

    if (DFIfind( dfile, otag, oref, 1, 0, 0, &odlep, &ocdd)<0) {
        DFerror = DFE_NOMATCH;      /* existing tag/ref does not exist! */
        return(-1);
    }

    if (!DFIfind( dfile, itag, iref, 1, 0, 0, &idlep, &icdd))
        newdd = &idlep->dd[icdd];   /* replaces existing DD */
    else {
        newdd = DFIemptyDD(dfile);  /* find empty DD */
        if (!newdd) return(-1);
        newdd->tag = itag;
        newdd->ref = iref;

        if (DFmaxref < iref) DFmaxref = iref;       /* mark iref as used */
        if (DFreflist) DFreflist[iref/8] |= patterns[iref%8];
    }
    newdd->offset = odlep->dd[ocdd].offset;
    newdd->length = odlep->dd[ocdd].length;
    dfile->changed = 1;
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFdel
 * Purpose: Delete a data element from file
 * Inputs:  dfile: pointer to open DF file
 *          tag, ref: id of data element
 * Returns: 0 on success, -1 on failure
 * Invokes: DFIcheck, DFIfind
 * Users:   HDF programmers, utilities, many other routines
 * Remarks: Data element is not deleted, only the reference to it is changed
 *---------------------------------------------------------------------------*/

int DFdel(dfile, tag, ref)
DF *dfile;
uint16 tag, ref;
{
    DFdle *dlep;
    int cdd;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile) )
        return( -1);

    if (DFIfind( dfile, tag, ref, 1, 0, 0, &dlep, &cdd)<0) {
        DFerror = DFE_NOMATCH;      /* nothing to delete */
        return(-1);
    }
    dlep->dd[cdd].tag = DFTAG_NULL;
    dlep->dd[cdd].ref = 0;
    dfile->changed = 1;
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFnewref
 * Purpose: Get an ununsed reference number
 * Inputs:  dfile: pointer to HDF file
 *          tag: tag for which ref is needed
 * Returns: unused ref number if found.  0 with DFerror set if not.
 * Users:   HDF programmers, for adding data elements
 * Invokes: DFIcheck
 * Remarks: Currently, returns a ref which is not used with any tag, except
 *          possibly DFTAG_MT
 *---------------------------------------------------------------------------*/

uint16 DFnewref(dfile)
DF *dfile;
{
    DFdle *DLEp;
    int i,j;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile) )
        return ((uint16) 0);

    if (DFmaxref < 65535)       /* 65535 = largest 16-bit uint = largest ref */
        return(++DFmaxref);

    /* allocate a bit array of 65536 bits - one for each ref */
    if (DFreflist==NULL) {
        if ((DFreflist = (unsigned char *) DFIgetspace(8192)) == NULL)
                return((uint16) 0);             /* 8192 = 65536/8 */
        
        for (i=1; i<8192; i++) DFreflist[i] = 0;    /* initialize */
        DFreflist[0] = 0x80;            /* ref 0 is not to be allocated */

        for (DLEp=dfile->list; DLEp; DLEp=DLEp->next) /* go through all DDs */
            for (i=0; i<DLEp->ddh.dds; i++)
                if (DLEp->dd[i].tag != DFTAG_MT)    /* set ref'th bit to 1 */
                    DFreflist[DLEp->dd[i].ref/8] |=
			patterns[DLEp->dd[i].ref%8];
    }

    for (i=0; i<8192; i++)
        if (DFreflist[i] != 0xff) break; /* if ff, all refs taken */

    if (i==8192) {
        DFerror = DFE_NOREF;
        return((uint16) 0);
    }

    for (j=0; j<8; j++) {
        if (!(DFreflist[i] & patterns[j])) { /* ref j is not allocated */
            DFreflist[i] |= patterns[j]; /* ref j is now in use */
            return((uint16) (i*8 + j));	/* ref to use */
        }
    }

    return((uint16) 0);		/* this statement should not be reached */
}


/*-----------------------------------------------------------------------------
 * Name:    DFishdf
 * Purpose: Is this an HDF file?
 * Inputs:  filename: name of HDF file
 * Returns: 0 if it is an HDF file, -1 if not.  DFerror is set to open error
 *              if any, else to DFE_NOERROR
 * Users:   HDF systems programmers, for checking files
 * Invokes: DFopen, DFclose
 * Remarks: none
 *---------------------------------------------------------------------------*/

DFishdf(filename)
char *filename;
{
    DF *dfile;

    DFerror = DFE_NOERROR;

    dfile = DFopen(filename, DFACC_READ, -1);
    if (dfile==NULL) return(-1);
    return(DFclose(dfile));
}


/*-----------------------------------------------------------------------------
 * Name:    DFerrno
 * Purpose: return value of DFerror
 * Inputs:  none
 * Returns: value of DFerror
 * Users:   HDF users, programmers
 * Invokes: none
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFerrno()
{

    return(DFerror);
}


/*-----------------------------------------------------------------------------
 * Name:    DFIerr
 * Purpose: Close a file and return on error. save DFerror
 * Inputs:  dfile: pointer to HDF file to close
 * Returns: -1
 * Users:   HDF systems programmers, for error handling
 * Invokes: DFclose
 * Remarks: Used to centralize some error handling
 *---------------------------------------------------------------------------*/

int DFIerr(dfile)
DF *dfile;
{
    int saveerror;

    saveerror = DFerror;
    if (dfile!=NULL) (void) DFclose(dfile);
    DFerror = saveerror;
    return(-1);
}
