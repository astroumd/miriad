/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				July 1, 1990
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
Revision 1.1.1.1  1990/09/28 21:50:04  teuben
UIUC 15-feb-2001 w/out wip and some manuals

 * Revision 3.12  90/09/20  11:04:32  clow
 * Changed DFSDIgetslice to call DFIseek and DFIread
 * (internal routines without the overhead of checking)
 * in lieu of DFseek and DFread in its loops.
 * This shaves a little off the reading time.
 * 
 * Revision 3.11  90/08/31  12:41:58  clow
 * fixed problems with the getslice routine so that
 * it now reads in only as much as is needed;
 * is smart about contigueous chunks;
 * does the proper seek for all contigueous chunks.
 * 
 * Revision 3.10  90/07/11  09:48:25  clow
 * Modified so that we could do inquiry after doing a getdata.
 * 
 * Revision 3.9  90/07/05  14:06:03  clow
 * Fix bug where transposition is used in getslice
 * 
 * Revision 3.8  90/06/29  17:35:52  clow
 * Fixed bug in DFSDIgetdata and DFSDreadref where the new sdg info is
 * not read.
 * 
 * Revision 3.7  90/06/29  16:49:12  clow
 * Added some spaces before the #pragma line so that the SGI's c compiler
 * will not complain.  Sigh.
 * 
 * Revision 3.6  90/06/28  13:49:12  clow
 * fix bug on DFSDIgetslice and DFSDputslice when the dimensions are collapse
 * 
 * Revision 3.5  90/06/21  10:39:45  clow
 * Fixed bug in Iputslice which calculates the pointer to the data wrongly
 * 
 * Revision 3.4  90/06/13  16:17:38  clow
 * added DFSDreadref that will set the ref of the next SD read in.
 * 
 * Revision 3.3  90/06/07  17:40:02  clow
 * new, faster put/getslice routines done by john walder
 * fixed bug in the getslice routine where the slice is from the
 * wrong coordinates
 * 
*/
/*-----------------------------------------------------------------------------
 File:  dfsd.c

 Purpose:
    Routines for input and output of scientific data

 Invokes:
    df.c dfgroup.c dfkit.c dfi.h df.h dfsd.h

 Public functions:
    DFSDgetdims - get rank and dim sizes
    DFSDgetdatastrs - get label, unit, format and coord system of data
    DFSDgetdimstrs - get label, unit and format for a dimension
    DFSDgetdimscale - get scale for a dimension
    DFSDgetmaxmin - get max and min of data
    DFSDgetdata - get data values
    DFSDsetlengths - set lengths of label, unit, format strings on gets
    DFSDsetdims - set rank and dim sizes
    DFSDsetdatastrs - set data label, unit, format and coord system
    DFSDsetdimstrs - set dim labels, units and formats
    DFSDsetdimscale - set scale for a dimension
    DFSDsetmaxmin - get max and min of data
    DFSDputdata - output data, data info, and display info
    DFSDrestart - forget info about last file accessed - restart from beginning
    DFSDnumber - return number of SDGs in file
    DFSDclear - forget all info set
    DFSDlastref - get reference number of last SDG read or written
    DFSDsettype - set output data type, m/c format, number type and array order
    DFSDgetslice - get part of the data, specified as a slice
    DFSDstartslice - set up to write SD
    DFSDputslice - write specified number of data items to file
    DFSDendslice - end of series of writes, write out SDG

Lower level functions:
    DFSDgetsdg - read SDG into struct
    DFSDputsdg - read SDG into struct

Private functions:
    DFSDIopen - open or reopen file
    DFSDIsdginfo - find next sdg in file
    DFSDIclear - clear sdg data structure of all info
    DFSDIgetdata - read data from file
    DFSDIputdata - write data to file
    DFSDIgetslice - get slice

Fortran stub functions:
    dsisdas_ - set data label, unit, format and coord system
    dsisdis_ - set dim labels, units and formats

 Remarks: 
    An SDG stores actual data from scietific computations, which are
      subsequently to be converted to images.
    This version assumes that all the values are floating point.
 *---------------------------------------------------------------------------*/


#include "dfsd.h"
#include "dfconvert.h"

#ifdef DF_CAPFNAMES
#   define dsisdas_ DSISDAS
#   define dsisdis_ DSISDIS
#endif /* DF_CAPFNAMES */                                            

#define LABEL   0
#define UNIT    1
#define FORMAT  2
#define COORDSYS 3

static DFSsdg Readsdg =		/* struct for reading */
{ {0, 0}, 0, NULL, NULL, { NULL, NULL, NULL },
  { NULL, NULL, NULL }, NULL, 0.0, 0.0 },

    Writesdg =			/* struct for writing */
{ {0, 0}, 0, NULL, NULL, { NULL, NULL, NULL },
  { NULL, NULL, NULL }, NULL, 0.0, 0.0 };

static  uint16  Writeref=0;	/* ref of next SDG to write to file */
static int Newdata=(-1);	/* Values in Readsdg fresh? */
				/* -1 : no descriptor read */
				/* 1 : descriptor read */
static int Nextsdg = 1;		/* Signal if DFSDgetdata should get the */
				/* next sdg */
static DF *Sdfile=NULL;		/* pointer to file for slice writes */
static int32  *Sddims;		/*dims written so far in slice write */

static struct {			/* Indicators of status (s) of info:    */
    int dims;			/* s = -1: there is no info in this category */
    int nt;			/* s = 0: info was set, but not yet written */
    int coordsys;		/* s>0:info was set and written with ref no.s*/
    int luf[3];
    int scales;
    int maxmin;
    int transpose;
} Ref = {  -1, -1, -1, { -1, -1, -1 }, -1, -1 , -1};
    
static int Maxstrlen[4] = { DFS_MAXLEN, DFS_MAXLEN, DFS_MAXLEN, DFS_MAXLEN };
static int Ismaxmin = 0;	/* is there a max/min value on read? */
static int FileTranspose = 0;	/* is the data in column major order? */
static int Fortorder = 0;	/* should data be written col major? */

static int fileNT=DFNTF_IEEE,	/* default: all IEEE */
           fileNTsize=4,	/* size of IEEE in bytes */
           outNT=DFNTF_IEEE,	/* default output: IEEE */
           outNTsize=4,		/* size of IEEE in bytes */
           userNT=DFNTF_IEEE;	/* default */
static int Readref = 0;

static char Lastfile[DF_MAXFNLEN] = "";	/* last file opened */
static uint16 Lastref = 0;

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdims
 * Purpose: Get dimensions of data in next SDG
 * Inputs:  filename: name of HDF file to use
 *          prank: pointer to integer for returning rank (no of dimensions)
 *          sizes: array of integers for returning size of each dimension
 *          maxrank: size of array for returning dimensions
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: rank in prank, size of each dimension in sizes
 *          If rank > maxrank, rank is set, and -1 is returned
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIopen, DFIerr, DFclose, DFSDIsdginfo
 * Method:  Opens file, calls DFSDIsdginfo to get SDG, copies rank etc, closes
 *          file, returns
 * Remarks: Always sequences to next SDG in file
 *          User specifies maxrank, and allocates sizes as an array of integers
 *          with dimension maxrank
 *---------------------------------------------------------------------------*/

int DFSDgetdims(filename, prank, sizes, maxrank)
char *filename;
int *prank;
int32 sizes[];
int maxrank;
{
    int i;
    DF *dfile;

    DFerror = DFE_NOERROR;
    if (!prank) {		/* check if ptr is valid */
        DFerror = DFE_BADPTR;
        return(-1);
    }

    dfile = DFSDIopen(filename, DFACC_READ); /* open/reopen file */
    if (dfile == NULL) return(-1);

    if (DFSDIsdginfo(dfile)<0)	/* reads next SDG from file */
        return(DFIerr(dfile));	/* on error, close file and return -1 */

    *prank = Readsdg.rank;	/* copy rank, dimensions */
    if (maxrank<*prank) {	/* if not all dimensions copied */
        DFerror = DFE_NOTENOUGH;
        return(DFIerr(dfile));
    }
    for (i=0; i<*prank; i++)
        sizes[i] = Readsdg.dimsizes[i];
    Nextsdg = 0;
    return(DFclose(dfile));
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdatastrs
 * Purpose: Get information about data: label, units, format
 * Inputs:  label: string to return label in, length Maxstrlen[LABEL]
 *          unit: string to return unit in, length Maxstrlen[UNIT]
 *          format: string to return format in, length Maxstrlen[FORMAT]
 *          coordsys: string to return coord system, length Maxstrlen[COORDSYS]
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: label, unit, format, coord system in the appropriate arguments
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  get values from struct Readsdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDgetdatastrs(label, unit, format, coordsys)
char *label, *unit, *format, *coordsys;
{
    int32 luf;
    char *lufp;

    DFerror = DFE_NOERROR;
    
    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    /* copy label, unit, format */
    for (luf=LABEL; luf<=FORMAT; luf++) {
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;
        if (lufp)
            if (Readsdg.dataluf[luf])
                DFIstrncpy(lufp, Readsdg.dataluf[luf], Maxstrlen[luf]);
    }
    /* copy coordsys */
    if (coordsys)
        if (Readsdg.coordsys)
            DFIstrncpy(coordsys, Readsdg.coordsys, Maxstrlen[COORDSYS]);
        else coordsys[0] = '\0';
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdimstrs
 * Purpose: Get information about a dimension: label, units, format
 * Inputs:  dim: no of dimension to get information about
 *          label: string to return label in, max length Maxstrlen[LABEL]
 *          unit: string to return unit in, max length Maxstrlen[UNIT]
 *          format: string to return format in, max length Maxstrlen[FORMAT]
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: label, unit, format in the appropriate arguments
 *          NULL string if no value for the arguments
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  get values from struct Readsdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDgetdimstrs(dim, label, unit, format)
int dim;
char *label, *unit, *format;
{
    int luf, rdim;
    char *lufp;

    DFerror = DFE_NOERROR;
    
    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    rdim = dim-1;		/* translate dim to zero origin */
    if ((rdim>=Readsdg.rank) || (rdim<0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    /* copy labels etc */
    for (luf=LABEL; luf<=FORMAT; luf++) {
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;
        if (lufp) {
            if (!Readsdg.dimluf) { /* no labels etc */
                *lufp = '\0';
                continue;
            }
            if (Readsdg.dimluf[luf])
                DFIstrncpy(lufp, Readsdg.dimluf[luf][rdim], Maxstrlen[luf]);
        }
    }
    return(0);
}
                
/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdatalen()
 * Purpose: Get actual length of label, unit, format, coordsys strings
 *          Called from FORTRAN
 * Inputs:  llabel, lunit, lformat, lcoordsys - for returning lengths
 * Globals: Readsdg
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  get lengths from Readsdg
 *---------------------------------------------------------------------------*/

int DFSDgetdatalen(llabel, lunit, lformat, lcoordsys)
int *llabel, *lunit, *lformat, *lcoordsys;
{

    DFerror = DFE_NOERROR;

    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }
    *llabel =  Readsdg.dataluf[LABEL] ? strlen(Readsdg.dataluf[LABEL]) : 0;
    *lunit =  Readsdg.dataluf[UNIT] ? strlen(Readsdg.dataluf[UNIT]) : 0;
    *lformat =  Readsdg.dataluf[FORMAT] ? strlen(Readsdg.dataluf[FORMAT]) : 0;
    *lcoordsys =  Readsdg.coordsys ? strlen(Readsdg.coordsys) : 0;
    return(0);
}
    

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdimlen()
 * Purpose: Get actual length of label, unit, format strings
 *          Called from FORTRAN
 * Inputs:  dim. llabel, lunit, lformat - for returning lengths
 * Globals: Readsdg
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  get lengths from Readsdg
 *---------------------------------------------------------------------------*/

int DFSDgetdimlen(dim, llabel, lunit, lformat)
int dim;
int *llabel, *lunit, *lformat;
{

    DFerror = DFE_NOERROR;

    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }
    if (dim>Readsdg.rank) {
        DFerror = DFE_BADDIM;
        return(-1);
    }
    *llabel =  Readsdg.dimluf[dim-1][LABEL] ?
	strlen(Readsdg.dimluf[dim-1][LABEL]) : 0;
    *lunit =  Readsdg.dimluf[dim-1][UNIT] ?
	strlen(Readsdg.dimluf[dim-1][UNIT]) : 0;
    *lformat =  Readsdg.dimluf[dim-1][FORMAT] ?
	strlen(Readsdg.dimluf[dim-1][FORMAT]) : 0;
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdimscale
 * Purpose: Get dimension scale
 * Inputs:  dim: no of dimension to get scale for
 *          size: size of scale array
 *          scale: array to return scale in
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: scale if present, else -1
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  get values from struct Readsdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDgetdimscale(dim, maxsize, scale)
int dim;
int32 maxsize;
float32 scale[];
{
    int32 i;
    int rdim;

    DFerror = DFE_NOERROR;
    
    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    rdim = dim-1;		/* translate dim to zero origin */
    if ((rdim>=Readsdg.rank) || (rdim<0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    if (maxsize < Readsdg.dimsizes[rdim]) {
        DFerror = DFE_NOSPACE;
        return(-1);
    }

    if (!scale) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (!Readsdg.dimscales || !Readsdg.dimscales[rdim]) { /* no scale */
        DFerror = DFE_NOVALS;
        return(-1);
    }

    for (i=0; i<Readsdg.dimsizes[rdim]; i++) /* copy scale */
        scale[i] = Readsdg.dimscales[rdim][i];

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetmaxmin()
 * Purpose: Get maximum and minimum data values
 * Inputs:  pmax: pointer to float32 to return maximum value in
 *          pmin: pointer to float32 to return minimum value in
 * Globals: Ismaxmin
 * Returns: 0 on success, -1 if no maxmin values or if error, with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Retrieves values from Readsdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDgetmaxmin(pmax, pmin)
float32 *pmax, *pmin;
{

    DFerror = DFE_NOERROR;
    
    if (Newdata<0) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    if (Ismaxmin) {
        *pmax = Readsdg.max_data;
        *pmin = Readsdg.min_data;
        return(0);
    } else {
        DFerror = DFE_NOVALS;
        return(-1);
    }
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetdata
 * Purpose: Get data from SDG.  Will sequence to next SDG if DFSDgetdims not
 *          called.
 * Inputs:  filename: name of HDF file to use
 *          rank: no of dimensions of array "data"
 *          maxsizes: actual dimensions of array "data"
 *          data: data for returning scientific data
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: actual scientific data in array
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIgetdata
 * Method:  call DFSDIgetdata
 * Remarks: maxsizes may be larger than actual size.  In that event, the actual
 *          data may not be contiguous in the array "data"
 *          User sets maxsizes before call.
 *          It is not necessary to call DFSDgetdata first if the dimensions
 *          are correct
 *---------------------------------------------------------------------------*/

int DFSDgetdata(filename, rank, maxsizes, data)
char *filename;
int rank;
int32 maxsizes[];
float32 data[];
{
    return(DFSDIgetdata(filename, rank, maxsizes, data, 0));    /* 0 == C */
}
                

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetlengths()
 * Purpose: Set maximum length for label, unit, format, coordsys strings
 * Inputs:  maxlen_label, maxlen_format, maxlen_unit, maxlen_coordsys:
 *              maximum length of each string.
 * Globals: Maxstrlen
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global Maxstrlen
 * Remarks: The get routines assume the array passed in by user is of this len
 *          If this routine is not called, the lengths default to DFS_MAXLEN
 *          The length includes the string terminator NULL byte
 *---------------------------------------------------------------------------*/

int DFSDsetlengths(maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys)
int maxlen_label, maxlen_unit, maxlen_format, maxlen_coordsys;
{

    if (maxlen_label>0) Maxstrlen[LABEL] = maxlen_label;
    if (maxlen_unit>0) Maxstrlen[UNIT] = maxlen_unit;
    if (maxlen_format>0) Maxstrlen[FORMAT] = maxlen_format;
    if (maxlen_coordsys>0) Maxstrlen[COORDSYS] = maxlen_coordsys;
    return(0);
}
    

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetdims()
 * Purpose: Set rank and sizes for subsequent SDGs
 * Inputs:  rank: rank of array that holds the raw data
 *          dimsizes: sizes of all of the dimensions
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDclear
 * Method:  Stores values in global structure Writesdg
 * Remarks: If dimensions change, all previous "set"s are cleared
 *          This routine must be called before DFSDsetdimstrs and
 *          DFSDsetdimscales.  It need not be called if these routines are
 *          not called, and the correct dimensions are supplied to DFSDputdata
 *          or DFSDadddata
 *---------------------------------------------------------------------------*/

int DFSDsetdims(rank, dimsizes)
int16 rank;
int32  dimsizes[];
{
    int i;

    DFerror = DFE_NOERROR;

    if (Sdfile!=NULL) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    if (Writesdg.rank == rank)	/* check if dimensions same */
        if (Writesdg.dimsizes) {
            for (i=0; i<rank; i++)
                if (Writesdg.dimsizes[i] != dimsizes[i]) break;
            if (i == rank) return(0); /* Dimensions same as before */
        }   
    
    /* forget all attributes set previously */
    if (DFSDIclear(&Writesdg)<0) return(-1);

    /* allocate dimensions */
    Writesdg.dimsizes = (int32 *) DFIgetspace((unsigned)(rank*sizeof(int32)));
    if (Writesdg.dimsizes==NULL) return(-1);

    /* copy dimensions */
    Writesdg.rank = rank;
    for (i=0; i<rank; i++)
        Writesdg.dimsizes[i] = dimsizes[i];

    /* Note dimensions modified */
    Ref.dims = 0;
    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetdatastrs()
 * Purpose: Set label, unit and format for displaying subsequent SDGs
 * Inputs:  label: label to be used to describe data
 *          unit: unit corresponding to data values
 *          format: format to be used in displaying data values
 *          coordsys: type of coordinate system
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global structure Writesdg
 * Remarks: should we validate coordsys? proposed strings: "cartesian",
 *          "polar" (="spherical") and "cylindrical".  Do "spherical" and
 *          "cylindrical" make sense for 2D?
 *---------------------------------------------------------------------------*/

int DFSDsetdatastrs(label, unit, format, coordsys)
char *label, *unit, *format, *coordsys;
{
    int luf;			/* takes values LABEL, UNIT, FORMAT */
				/* in succession */
    char *lufp;			/* points to label, unit, format */
				/* in succession */
    DFerror = DFE_NOERROR;

    for (luf=LABEL; luf<=FORMAT; luf++) {
	/* set lufp to point to label etc. as apppropriate */
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;

	/* free space if allocated */
        Writesdg.dataluf[luf] = DFIfreespace(Writesdg.dataluf[luf]);

	/* copy string */
        if (lufp) {
            Writesdg.dataluf[luf] = DFIgetspace((unsigned) strlen(lufp)+1);
            if (Writesdg.dataluf[luf]==NULL) return(-1);
            strcpy(Writesdg.dataluf[luf], lufp);
        }
    }

    Writesdg.coordsys = DFIfreespace(Writesdg.coordsys);

    if (coordsys) {
        Writesdg.coordsys = DFIgetspace((unsigned) strlen(coordsys)+1);
        if (Writesdg.coordsys==NULL) return(-1);
        strcpy(Writesdg.coordsys, coordsys);
    }

    /* indicate that label, unit, format and coordsys info modified */
    Ref.luf[LABEL] = Ref.luf[UNIT] = Ref.luf[FORMAT] = Ref.coordsys = 0;

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetdimstrs()
 * Purpose: For the given dimension, set label, unit, format
 *          This routine needs to be called once for each dimension whose 
 *          values the user wants to set.
 * Inputs:  dim: the dimension that this info applies to
 *          label: label to be used to describe this dimension
 *          unit: units for dimension
 *          format: format to be used in displaying
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global structure Writesdg
 *---------------------------------------------------------------------------*/

int DFSDsetdimstrs(dim, label, unit, format)
int dim;
char *label, *unit, *format;
{

    int i, rdim;
    int luf;			/* takes values LABEL, UNIT, FORMAT */
				/* in succession */
    char *lufp;			/* points to label, unit, format */
				/* in succession */
    DFerror = DFE_NOERROR;

    rdim = dim-1;		/* translate from 1 to 0 origin */

    if ((rdim>=Writesdg.rank) || (rdim<0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    for (luf=LABEL; luf<=FORMAT; luf++) {
	/* set lufp to point to label etc. as apppropriate */
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;

	/* allocate space if necessary */
        if (!Writesdg.dimluf[luf]) {
            Writesdg.dimluf[luf] =
                (char **) DFIgetspace((unsigned) Writesdg.rank * sizeof(char *));
            if (Writesdg.dimluf[luf]==NULL) return(-1);
            for (i=0; i<Writesdg.rank; i++) /* set allocated pointers to NULL*/
                Writesdg.dimluf[luf][i] = NULL;
        }

	/* free string space if allocated */
        Writesdg.dimluf[luf][rdim] = DFIfreespace(Writesdg.dimluf[luf][rdim]);

	/* copy string */
        if (lufp) {
            Writesdg.dimluf[luf][rdim] = DFIgetspace((unsigned) strlen(lufp)+1);
            if (Writesdg.dimluf[luf][rdim]==NULL) return(-1);
            strcpy(Writesdg.dimluf[luf][rdim], lufp);
        }
    }
    /* Indicate that this info has not been written to file */
    Ref.luf[LABEL] = Ref.luf[UNIT] = Ref.luf[FORMAT] = 0;

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetdimscale()
 * Purpose: For the given dimension, set scale values
 *          This routine needs to be called once for each dimension whose 
 *          values the user wants to set.
 * Inputs:  dim: the dimension that this info applies to
 *          dimsize: number of points in the scale
 *          scale: array of numbers that will make up the scale
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global structure Writesdg
 *---------------------------------------------------------------------------*/

int DFSDsetdimscale(dim, dimsize, scale)
int dim;
int32   dimsize;
float32 scale[];
{

    int i, rdim;
    DFerror = DFE_NOERROR;

    rdim = dim-1;		/* translate from 1 to 0 origin */

    if (!Writesdg.dimsizes) {
        DFerror = DFE_BADCALL;
        return(-1);
    }
    if ((rdim>=Writesdg.rank) || (rdim<0) /* check dimensions */
	|| (dimsize!=Writesdg.dimsizes[rdim])) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    if (!scale) {		/* No scale for this dimension */
        if (Writesdg.dimscales)
            Writesdg.dimscales[rdim] =
		(float32 *) DFIfreespace((char*) Writesdg.dimscales[rdim]);
        Ref.scales = 0;
        return(0);
    }
        
    /* allocate space for dimscales if necessary */
    if (!Writesdg.dimscales) {
        Writesdg.dimscales =
	    (float32 **) DFIgetspace((unsigned)Writesdg.rank * sizeof(float32 *));
        if (Writesdg.dimscales==NULL) return(-1);
        for (i=0; i<Writesdg.rank; i++) /* set allocated pointers to NULL */
            Writesdg.dimscales[i] = NULL;
    }

    if (!Writesdg.dimscales[rdim]) {
	/* allocate dimension scale space if necessary */
        Writesdg.dimscales[rdim] =
	    (float32 *) DFIgetspace((unsigned) dimsize*sizeof(float32));
        if (Writesdg.dimscales[rdim]==NULL) return(-1);
    }

    for (i=0; i<dimsize; i++)	/* copy scale */
        Writesdg.dimscales[rdim][i] = scale[i];

    /* Indicate scales modified */
    Ref.scales = 0;

    return(0);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDsetmaxmin()
 * Purpose: Set maximum and minimum data values
 * Inputs:  maxi: maximum value
 *          mini: minimum value
 * Globals: Ref
 * Returns: 0 on success, -1 if no maxmin values or if error, with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Modify Writesdg, set Ref
 * Remarks: Automatically cleared after call to DFSDputdata or DFSDadddata
 *---------------------------------------------------------------------------*/

int DFSDsetmaxmin(maxi, mini)
float32 maxi, mini;
{

    DFerror = DFE_NOERROR;
    
    Writesdg.max_data = maxi;
    Writesdg.min_data = mini;
    Ref.maxmin = 0;

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDputdata
 * Purpose: Calls DFSDIputdata to write data and SDG to file
 * Inputs:  filename: name of HDF file to use
 *          rank: rank of data array
 *          dimsizes: sizes of the dimensions of data array
 *          data: array that holds data
 * Globals: Writeref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIputdata
 * Method:  Invoke DFSDIputdata
 *---------------------------------------------------------------------------*/

int DFSDputdata(filename, rank, dimsizes, data)
char *filename;
int16 rank;
int32 dimsizes[];
float32 *data;
{

    /* 0, 0 specify create mode, C style array (row major) */
    return(DFSDIputdata(filename, rank, dimsizes, data, 0, 0));
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDadddata
 * Purpose: Calls DFSDIputdata to append data and SDG to file
 * Inputs:  filename: name of HDF file to use
 *          rank: rank of data array
 *          dimsizes: sizes of the dimensions of data array
 *          data: array that holds data
 * Globals: Writeref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIputdata
 * Method:  Invoke DFSDIputdata
 *---------------------------------------------------------------------------*/

int DFSDadddata(filename, rank, dimsizes, data)
char *filename;
int16 rank;
int32 dimsizes[];
float32 *data;
{

    /* 1, 0 specifies append mode, C style array (row major) */
    return(DFSDIputdata(filename, rank, dimsizes, data, 1, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDrestart
 * Purpose: Do not remember info about file - get again from first data set
 * Inputs:  none
 * Returns: 0 on success
 * Users:   HDF programmers
 * Remarks: Just reset Lastfile to NULL
 *          Subsequent gets will starts from first image
 *          Next put will write all "set" info to file
 *---------------------------------------------------------------------------*/

int DFSDrestart()
{
    Lastfile[0] = '\0';
    Readref = 0;
    return(0);
}
    

/*-----------------------------------------------------------------------------
 * Name:    DFSDnumber
 * Purpose: Return number of SDGs in file
 * Inputs:  filename - name of HDF file
 * Globals: none
 * Returns: number of SDGs on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIopen, DFclose, DFnumber
 * Method:  open file, invoke DFnumber, close file
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDnumber(filename)
char *filename;
{
    DF *dfile;
    int nsdgs=0;

    DFerror = DFE_NOERROR;

    /* should use reopen if same file as last time - more efficient */
    dfile = DFSDIopen(filename, DFACC_READ);
    if (dfile==NULL) return(-1);

    nsdgs = DFnumber(dfile, DFTAG_SDG);       /* count number of SDGs */
    if (DFclose(dfile)<0) return(-1);
    return(nsdgs);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDclear
 * Purpose: Clear all "set" values
 * Inputs:  none
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIclear
 * Method:  Invoke DFSDIclear
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDclear()
{
    return(DFSDIclear(&Writesdg));
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDlastref
 * Purpose: Return last ref written or read
 * Inputs:  none
 * Globals: Lastref
 * Returns: ref on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  return Lastref
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDlastref()
{
    return((int) Lastref);
}

/*-----------------------------------------------------------------------------
 * Name:    DFR8readref
 * Purpose: Set ref of image to get next
 * Inputs:  filename: file to which this applies
 *          ref: reference number of next get
 * Returns: 0 on success, -1 on failure
 * Users:   HDF programmers, other routines and utilities
 * Invokes: DFR8Iopen, DFIfind
 * Remarks: checks if image with this ref exists
 *---------------------------------------------------------------------------*/

	int
DFSDreadref(filename, ref)
    char *filename;
    uint16 ref;
{
    DF *dfile;
    int cdd;
    DFdle *dlep;

    DFerror = DFE_NOERROR;
    dfile = DFSDIopen(filename, DFACC_READ);
    if (!dfile) return (-1);
    if (DFIfind(dfile, DFTAG_SDG, ref,1,0,0, &dlep, &cdd) < 0)
	return (DFIerr(dfile));
    Readref = ref;
    Newdata = -1;
    return DFclose(dfile);
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetslice
 * Purpose: Get slice of data from SDG.  Will sequence to next SDG if
 *          DFSDgetdims, DFSDgetdata or DFSDgetslice not called earlier.
 * Inputs:  filename: name of HDF file to use
 *          winst: array of size = rank of data, containing start of slice
 *          windims: array of size rank, containing end of slice
 *          data: array for returning slice
 *          dims: dimensions of array data
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: slice of data in data
 * Users:   DFSDIgetdata
 * Invokes: DFSDIgetslice
 * Method:  call DFSDIgetslice
 * Remarks: dims may be larger than size of slice.  In that event, the actual
 *          data may not be contiguous in the array "data".
 *          User sets dims before call.
 *---------------------------------------------------------------------------*/

int DFSDgetslice(filename, winst, windims, data, dims)
char *filename;
int32 winst[], windims[];
int32 dims[];
float32 data[];
{
    return(DFSDIgetslice(filename, winst, windims, data, dims, 0));
}

/*-----------------------------------------------------------------------------
 * Name:    DFSDstartslice
 * Purpose: Set up to write slice of data to SDG.
 * Inputs:  filename: name of HDF file to write to
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   DFSDIputdata
 * Invokes: DFSDIopen, DFnewref, DFaccess
 * Method:  call DFSDIputslice
 * Remarks: DFSDsetdims must have been called first
 *          No call which needs a file open may be made after this
 *          till DFSDendslice is called
 *---------------------------------------------------------------------------*/

int DFSDstartslice(filename)
char *filename;
{
    int i;

    DFerror = DFE_NOERROR;

    if (!Writesdg.rank) {	/* dimensions not set */
        DFerror = DFE_BADDIM;
        return(-1);
    }

    Sdfile = DFSDIopen(filename, DFACC_WRITE);
    if (Sdfile == NULL) return(-1);

    if (!Writeref) Writeref = DFnewref(Sdfile);
    if (!Writeref) return(-1);

    Writesdg.data.tag = DFTAG_SD;
    Writesdg.data.ref = Writeref;

        /* set up to write image */
    if (DFaccess(Sdfile, DFTAG_SD, Writeref, "w")<0)
            return(DFIerr(Sdfile));

    /* allocate array for keeping track of dims written */
    Sddims = (int32 *) DFIgetspace((unsigned) Writesdg.rank * sizeof(int32));
    if (Sddims==NULL) return(DFIerr(Sdfile));
    
    for (i=0; i<Writesdg.rank; i++)
        Sddims[i] = 0;		/* nothing written so far */

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDputslice
 * Purpose: Put slice of data to SDG.
 * Inputs:  winend: array of size rank, containing end of slice
 *          data: array containing slice
 *          dims: dimensions of array data
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   DFSDIputdata
 * Invokes: DFSDIputslice
 * Method:  call DFSDIputslice
 * Remarks: dims may be larger than size of slice.  In that event, the actual
 *          data may not be contiguous in the array "data".
 *          DFSDstartslice must have been called first
 *---------------------------------------------------------------------------*/

int DFSDputslice(winend, data, dims)
int32 winend[];
int32 dims[];
float32 data[];
{

    return(DFSDIputslice(winend, data, dims, 0));
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDendslice
 * Purpose: Write of data to SDG completed, write SDG and close file
 * Inputs:  none
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   DFSDIputdata
 * Invokes: DFSDputsdg, DFclose, DFIerr
 * Method:  call DFSDputsdg, close Sdfile
 * Remarks: checks that slice writes were completed.
 *---------------------------------------------------------------------------*/

int DFSDendslice()
{
    int i, ret;

    DFerror = DFE_NOERROR;

    if (!Sdfile) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    /* check if slice writes complete */
    for (i=0; i<Writesdg.rank; i++) {
        if (!Fortorder && (i==0) && (Sddims[i]==Writesdg.dimsizes[i]))continue;
        if (Fortorder && (i==Writesdg.rank-1) &&
	    (Sddims[i] == Writesdg.dimsizes[i])) continue;
        if((Fortorder || i>0) && (!Fortorder || i<Writesdg.rank-1)
	   && (Sddims[i] == 0)) continue;
        DFerror = DFE_BADCALL;
        return(-1);
    }


    if (DFSDputsdg(Sdfile, Writeref, &Writesdg)<0) return(DFIerr(Sdfile));

    Lastref = Writeref;		/* remember ref written */
    Writeref=0;			/* don't know ref to write next */

    ret = DFclose(Sdfile);
    Sdfile = NULL;		/* partial write complete */
    Sddims = (int32 *) DFIfreespace((char*) Sddims);

    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDsettype
 * Purpose: Set data type, machine type, number type and array order for output
 * Inputs:  datatype: only DFNT_FLOAT currently supported
 *          machine type: only the local machine type is supported
 *          number type: only local float number type and DFNTF_IEEE supported
 *          array order: may be either C or Fortran order
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: none
 * Users:   HDF users
 * Invokes: none
 * Method:  set globals
 * Remarks: Setting array order may not work if partial writes are attempted
 *          Sometimes call may accept types which later cause errors when
 *          conversion is attempted.
 *---------------------------------------------------------------------------*/

int DFSDsettype(datatype, machinetype, numbertype, arrayorder)
int datatype, machinetype, numbertype, arrayorder;
{
    if (Sdfile !=NULL) {	/* cannot set type during slice writes */
        DFerror = DFE_BADCALL;
        return(-1);
    }

    if (datatype && (datatype != DFNT_FLOAT)) {
        DFerror = DFE_BADDATATYPE;
        return(-1);
    }

    if (machinetype) {
        outNT = (machinetype>>8) & 0x0f;
        if ((machinetype!=DF_MT) && (outNT!=DFNTF_IEEE)) {
            DFerror = DFE_BADMCTYPE;
            return(-1);
        }
    }

    if (numbertype) outNT = numbertype;
    if (outNT == ((DF_MT>>8) & 0x0f)) outNTsize = sizeof(float32);
    else if (outNT == DFNTF_IEEE) outNTsize = 4; /* sizeof IEEE in bytes */
    else {
        DFerror = DFE_BADNUMTYPE;
        return(-1);
    }

    if (arrayorder==DFO_FORTRAN) {
	Fortorder = 1; 
	if (Ref.transpose<0) Ref.transpose = 0;
    }
    else if (arrayorder==DFO_C) {
	Fortorder = 0;
	if (Ref.transpose>=0) Ref.transpose = -1;
    }
    else if (arrayorder) {
        DFerror = DFE_BADORDER;
        return(-1);
    }

    return(0);
}

/******************************************************************************/
/*--------------------- Lower level routines --------------------------------*/
/******************************************************************************/

/*-----------------------------------------------------------------------------
 * Name:    DFSDgetsdg
 * Purpose: Reads in SDG
 * Inputs:  dfile: pointer to HDF file containing SDG
 *          ref: ref of SDG to read
 *          sdg: pointer to DFSsdg struct to read SDG into
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, DFSDgetdims, DFSDgetdata
 * Invokes: DFgetelement, DFdiread, DFdiget, DFaccess, DFread
 * Method:  Reads in SDG using DFdiread.  Gets each tag/ref using DFdiget.
 *          Reads in dimensions, labels, units, formats, scales, coordinate
 *          system using DFgetelement.  Mallocs space for these, freeing
 *          previously allocated space.
 * Remarks: This is specific to floating point data
 *---------------------------------------------------------------------------*/

int DFSDgetsdg(dfile, ref, sdg)
DF *dfile;
uint16 ref;
DFSsdg *sdg;
{
    int i, j, luf, cdd;
    int error;			/* used by DFconvert macro */
    DFdle *dlep;
    struct DFdi elmt, nt;
    char *isscales;
    char *buf, *p;
    char ntstring[4];

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);

    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }

    if (DFdiread(dfile, DFTAG_SDG, ref)<0) /* read RIG into memory */
        return(-1);

    userNT = (DF_MT>>8) & 0x0f;	/* get third nibble from right */

    DFSDIclear(sdg);
    Ismaxmin = 0;

    while (!DFdiget(&elmt)) {	/* get next tag/ref from RIG */
        luf = -1;		/* flag value for label/unit format gets */
        switch (elmt.tag) {	/* process tag/ref */

            case DFTAG_SD:	/* data tag/ref */
                sdg->data.tag = elmt.tag; /* put tag/ref in struct */
                sdg->data.ref = elmt.ref;
                break;

            case DFTAG_SDD:	/* dimension */
                if (DFaccess(dfile, elmt.tag, elmt.ref, "r")<0) return(-1);

				/* read rank */
#ifdef DF_STRUCTOK
                if (DFread(dfile, &sdg->rank, (int32) 2)<0) return(-1);
#else /*DF_STRUCTOK*/
                if (DFread(dfile, DFtbuf, (int32) 2)<0) return(-1);
                {
                    register char *p;
                    p = DFtbuf;
                    INT16READ(p, sdg->rank);
                }
#endif /*DF_STRUCTOK*/

		/* get space for dimensions */
                sdg->dimsizes = (int32 *) DFIgetspace((unsigned) sdg->rank *
						      sizeof(int32));
                if (sdg->dimsizes==NULL) return(-1);

		/* read dimension record */
#ifdef DF_STRUCTOK
                if (DFread(dfile, sdg->dimsizes, (int32) 4*sdg->rank)<0)
                                                                    return(-1);
                            /* read NT */
                if (DFread(dfile, &nt, (int32) 4)<0) return(-1);

#else /*DF_STRUCTOK*/
                if (DFread(dfile, DFtbuf, (int32) 4*sdg->rank)<0) return(-1);
                {
                    register char *p;
                    p = DFtbuf;
                    for (i=0; i<sdg->rank; i++)
                        INT32READ(p, sdg->dimsizes[i]);

                            /* read NT */
                    if (DFread(dfile, DFtbuf, (int32) 4)<0) return(-1);
                    p = DFtbuf;
                    UINT16READ(p, nt.tag);
                    UINT16READ(p, nt.ref);
                }
#endif /*DF_STRUCTOK*/
                            /* read NT */
                if (DFgetelement(dfile, nt.tag, nt.ref, ntstring)<0)
                    return(-1);

                            /* check float data */
                if (ntstring[1] != DFNT_FLOAT) {
                    DFerror = DFE_BADCALL;
                    return(-1);
                }

                            /* set NT info */
                fileNT = ntstring[3];
                fileNTsize = ntstring[2] / 8;

                            /* read and check all scale NTs */
                for (i=0; i<sdg->rank; i++) {
#ifdef DF_STRUCTOK
                            /* read NT tag/ref */
                    if (DFread(dfile, &nt, (int32) 4)<0) return(-1);

#else /*DF_STRUCTOK*/
                    if (DFread(dfile, DFtbuf, (int32) 4)<0) return(-1);
                    {
                        register char *p;
                        p = DFtbuf;
                        UINT16READ(p, nt.tag);
                        UINT16READ(p, nt.ref);
                    }
#endif /*DF_STRUCTOK*/
                            /* read NT itself */
                    if (DFgetelement(dfile, nt.tag,nt.ref, ntstring)<0)
                        return(-1);

                            /* check float data */
                    if (ntstring[1] != DFNT_FLOAT) {
                        DFerror = DFE_BADCALL;
                        return(-1);
                    }
                }

                break;

            case DFTAG_SDL:     /* labels */
                if (luf==(-1)) luf = LABEL;

            case DFTAG_SDU:     /* units */
                if (luf==(-1)) luf = UNIT;

            case DFTAG_SDF:     /* formats */
                if (luf==(-1)) luf = FORMAT;

                if (!sdg->dimsizes) {           /* internal error */
                    DFerror = DFE_CORRUPT;
                    return(-1);
                }

                        /* get needed size of buffer, allocate */
                if (DFIfind(dfile, elmt.tag, elmt.ref, 1, (uint16) 0,
			    (uint16) 0, &dlep, &cdd)<0)
                    return(-1);
                buf = DFIgetspace((unsigned) dlep->dd[cdd].length);
                if (buf==NULL) return(-1);

                        /* read in luf */
                if (DFgetelement(dfile, elmt.tag, elmt.ref, buf)<0) {
                    buf = DFIfreespace(buf);
                    return(-1);
                }
                p = buf;
                        /* allocate data luf space */
                sdg->dataluf[luf] = DFIgetspace((unsigned) strlen(p)+1);
                if (sdg->dataluf[luf]==NULL) {
                    buf = DFIfreespace(buf);
                    return(-1);
                }

		/* extract data luf */
                strcpy(sdg->dataluf[luf], p);
                p += strlen(sdg->dataluf[luf])+1;

		/* get space for dimluf array */
                sdg->dimluf[luf] =
		    (char **) DFIgetspace((unsigned) sdg->rank * sizeof(char *));
                if (sdg->dimluf[luf]==NULL) {
                    buf = DFIfreespace(buf);
                    return(-1);
                }

                                /* extract dimension lufs */
                for (i=0; i<sdg->rank; i++) {
                    sdg->dimluf[luf][i] = DFIgetspace((unsigned) strlen(p)+1);
                    if (sdg->dimluf[luf][i]==NULL) {
                        buf = DFIfreespace(buf);
                        return(-1);
                    }
                    strcpy(sdg->dimluf[luf][i], p);
                    p += strlen(sdg->dimluf[luf][i])+1;
                }
                buf = DFIfreespace(buf);
                break;

            case DFTAG_SDS:     /* scales */
                if (!sdg->dimsizes) {           /* internal error */
                    DFerror = DFE_CORRUPT;
                    return(-1);
                }
		/* set up to read scale */
                if (DFaccess(dfile, elmt.tag, elmt.ref, "r")<0) return(-1);

		/* read isscales */
                isscales = DFIgetspace((unsigned) sdg->rank);
                if (isscales==NULL) return(-1);
                if (DFread(dfile, isscales, (int32) sdg->rank)<0) return(-1);

		/* allocate scale pointers */
                sdg->dimscales =
                    (float32 **) DFIgetspace((unsigned) sdg->rank *
					     sizeof(float32 *));
                if (sdg->dimscales==NULL) {
                    isscales = DFIfreespace(isscales);
                    return(-1);
                }

                            /* read scales */
                for (i=0; i<sdg->rank; i++) {
                    sdg->dimscales[i] = NULL;       /* default */
                    if (!isscales[i]) continue;

                            /* space for scale */
                    sdg->dimscales[i] = (float32 *)
			DFIgetspace((unsigned) sdg->dimsizes[i] *
				    sizeof(float32));
                    if (sdg->dimscales[i]==NULL) {
                        isscales = DFIfreespace(isscales);
                        return(-1);
                    }

                    if (userNT == fileNT) {     /* no conversion needed */
                        if (DFread(dfile, (char*) sdg->dimscales[i], 
                                (int32) (sdg->dimsizes[i]*fileNTsize))<0) {
                            isscales = DFIfreespace(isscales);
                            return(-1);
                        }
                    }

                    else {                      /* conversion necessary */
                        register char *p;

                                /* allocate conversion buffer */
                        buf = DFIgetspace((unsigned) sdg->dimsizes[i] *
					  fileNTsize);
                        if (buf==NULL) {
                            isscales = DFIfreespace(isscales);
                            return(-1);
                        }

                                /* read scale from file */
                        if (DFread(dfile, buf,
                                (int32) (sdg->dimsizes[i]*fileNTsize))<0) {
                            buf = DFIfreespace(buf);
                            isscales = DFIfreespace(isscales);
                            return(-1);
                        }
                            
                        p = buf;
				/* convert, all at once */
                        DFconvert(p, (char*) sdg->dimscales[i], DFNT_FLOAT,
                                 fileNT, userNT, sdg->dimsizes[i], error);

                        buf = DFIfreespace(buf);
                    }
                }
                isscales = DFIfreespace(isscales);
                break;

            case DFTAG_SDC:	/* coordsys */
		/* find and allocate necessary space */
                if (DFIfind(dfile, elmt.tag, elmt.ref, 1, 0, 0, &dlep, &cdd)<0)
                    return(-1);
                sdg->coordsys = DFIgetspace((unsigned) dlep->dd[cdd].length);
                if (sdg->coordsys==NULL) return(-1);

		/* read coordsys */
                if (DFgetelement(dfile, elmt.tag, elmt.ref, sdg->coordsys)<0)
                    return(-1);
                break;

            case DFTAG_SDM:	/* max/min */
                if (fileNT==userNT) {       /* no conversion */
                    if (DFgetelement(dfile, elmt.tag, elmt.ref,
				     (char*) &sdg->max_data)<0)
                        return(-1);
                }
                else {
                        /* allocate buffer */
#ifndef CVT_BUG
		    float32 mm[2];
#endif
                    buf = DFIgetspace((unsigned) 2 * fileNTsize);
                    if (buf==NULL) return(-1);

                        /* read and convert max/min */
                    if (DFgetelement(dfile, elmt.tag, elmt.ref, buf)<0)
                        return(-1);
#ifdef CVT_BUG
                    DFconvert(buf, (char*) &sdg->max_data, DFNT_FLOAT, fileNT,
			      userNT, 1, error);
                    DFconvert(buf+fileNTsize, (char*) &sdg->min_data,
			      DFNT_FLOAT, fileNT, userNT, 1, error);
#else
		    DFconvert(buf, (char*)mm, DFNT_FLOAT,
			      fileNT, userNT, 2, error);
		    sdg->max_data = mm[0];
		    sdg->min_data = mm[1];
#endif
                    buf = DFIfreespace(buf);
                }
                Ismaxmin = 1;
                break;
                    
            case DFTAG_SDT:
                FileTranspose = 1;
                break;
            default:            /* ignore unknown tags */
                break;
        }
    }
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDputsdg
 * Purpose: Write SDG out to HDF file
 * Inputs:  dfile: HDF file pointer
 *          ref: ref to put SDG with
 *          sdg: struct containing SDG info to put
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF programmers, utilities, DFSDputdata, other routines
 * Invokes: DFIcheck, DFdistart, DFdiadd, DFdiend, DFputelement, DFaccess,
 *          DFwrite
 * Remarks: Writes out NTs
 *---------------------------------------------------------------------------*/

int DFSDputsdg(dfile, ref, sdg)
DF *dfile;
uint16 ref;
DFSsdg *sdg;
{
    int i,j, localNT, luf;
    int error;			/* used by DFConvert macro */
    uint16 luftag;
    char ntstring[4];
    char *buf, *Isscales=NULL;
    DFdi nt;

    DFerror = DFE_NOERROR;

    if (DFIcheck(dfile))
        return( -1);

    if (!ref) {
        DFerror = DFE_BADREF;
        return(-1);
    }

    localNT = (DF_MT>>8) & 0x0f;            /* get third nibble from right */

        /* prepare to start writing sdg */
    if (DFdisetup(10)<0) return(-1);        /* max 10 tag/refs in set */

    if (DFdiput(sdg->data.tag, sdg->data.ref) < 0) return(-1);

    if (Ref.nt<=0) {
            /* construct and write out NT */
        ntstring[0] = DFNT_VERSION;         /* version */
        ntstring[1] = DFNT_FLOAT;           /* type */
        ntstring[2] = outNTsize*8;          /* width of float class in bits */
        ntstring[3] = outNT;                /* class: IEEE floating point */
        if (DFputelement(dfile, DFTAG_NT, ref, ntstring, (int32) 4) <0)
            return(-1);
        Ref.nt = ref;
    }

    if (Ref.dims<=0) {
        if (DFaccess(dfile, DFTAG_SDD, ref, "w")<0) return(-1);

                /* write rank, dimensions */
#ifdef DF_STRUCTOK
        if (DFwrite(dfile, &sdg->rank, 2)<0) return(-1);
        if (DFwrite(dfile, sdg->dimsizes, 4 * sdg->rank)<0) return(-1);
#else /*DF_STRUCTOK*/
        {
            register char *p;
            p = DFtbuf;
            UINT16WRITE(p, sdg->rank);
            for (i=0; i<sdg->rank; i++)
                INT32WRITE(p, sdg->dimsizes[i]);
            if (DFwrite(dfile, DFtbuf, (int32) (p-DFtbuf))<0)
                return(-1);
        }
#endif /*DF_STRUCTOK*/

                /* write data NT and scale NTs */
        nt.tag = DFTAG_NT;
        nt.ref = Ref.nt;                /* same NT for scales too */

            /* <= used to write 1 data  NT + rank scale NTs */
        for (i=0; i<=sdg->rank; i++)    /* scale NTs written even if no scale!*/

#ifdef DF_STRUCTOK
            if (DFwrite(dfile, &nt, (int32) 4)<0) return(-1);
#else /*DF_STRUCTOK*/
        {
            register char *p;
            p = DFtbuf;
            UINT16WRITE(p, nt.tag);
            UINT16WRITE(p, nt.ref);
            if (DFwrite(dfile, DFtbuf, (int32) (p-DFtbuf))<0)
                return(-1);
        }
#endif /*DF_STRUCTOK*/
            
        Ref.dims = ref;
    }
    /* write dimension tag/ref */
    if (DFdiput(DFTAG_SDD,(uint16) Ref.dims) < 0) return(-1);

            /* write out label/unit/format */
    for (luf=LABEL; luf<=FORMAT; luf++) {
        luftag = (luf==LABEL) ? DFTAG_SDL : (luf==UNIT) ? DFTAG_SDU : DFTAG_SDF;

            /* this block of code checks if luf is NULL, else writes it */
        if (!Ref.luf[luf]) {            /* if luf was set */
            Ref.luf[luf] = -1;          /* assume it is NULL */
            for (i=0; i<sdg->rank; i++) {
                if ((sdg->dataluf[luf] && sdg->dataluf[luf][0]) ||
                    (sdg->dimluf[luf] && sdg->dimluf[luf][i]
                                      && sdg->dimluf[luf][i][0])) {
                            /* if luf is non-NULL */

                            /* set up to write */
                    if (DFaccess(dfile, luftag, ref, "w")<0) return(-1);

                            /* write data luf */
                    if (sdg->dataluf[luf]) {
                        if (DFwrite(dfile, sdg->dataluf[luf],
                            (int32) strlen(sdg->dataluf[luf])+1)<0) return(-1);
                    }
                    else {  /* write NULL */
                        if (DFwrite(dfile, "", (int32) 1)<0) return(-1);
                    }
                        

                            /* write dim lufs */
                    for (j=0; j<sdg->rank; j++)
                      if (sdg->dimluf[luf] && sdg->dimluf[luf][j]) {
                        if (DFwrite(dfile, sdg->dimluf[luf][j],
                           (int32) strlen(sdg->dimluf[luf][j])+1)<0) return(-1);
                      }
                      else {    /* write NULL */
                        if (DFwrite(dfile, "", (int32) 1)<0) return(-1);
                      }
                    
                    Ref.luf[luf] = ref;	/* remember ref */
                    break;
                }
            }
        }
	/* write luf tag/ref */
        if (Ref.luf[luf]>0) if (DFdiput(luftag, (uint16)Ref.luf[luf]) < 0)
	    return(-1);
    }

    /* check if there is a scale and write it out */
    if (!Ref.scales) {		/* if scale set */
        Isscales = DFIgetspace((unsigned) sdg->rank);
        if (Isscales==NULL) return(-1);
        Ref.scales = (-1);                  /* assume there is no scale */

                    /* set up Isscales array */
        for (i=0; i<sdg->rank; i++) {
            if (sdg->dimscales && sdg->dimscales[i]) {  /* a scale exists */
                Isscales[i] = 1;
                Ref.scales = 0;             /* flag: write out scales */
            }
            else Isscales[i] = 0;
        }
    }

    if (!Ref.scales) {      /* write out scale */
        if (DFaccess(dfile, DFTAG_SDS, ref, "w")<0) {
            Isscales = DFIfreespace(Isscales);
            return(-1);
        }
                            /* write Isscales */
        if (DFwrite(dfile, Isscales, (int32) sdg->rank)<0) {
            Isscales = DFIfreespace(Isscales);
            return(-1);
        }
                            /* Write scales */
        for (j=0; j<sdg->rank; j++) {
            if (!Isscales[j]) continue;
            if (localNT==outNT) {       /* no conversion needed */
                if (DFwrite(dfile, (char*) sdg->dimscales[j],
                            (int32) (sizeof(float32) * sdg->dimsizes[j]))<0) {
                    Isscales = DFIfreespace(Isscales);
                    return(-1);
                }
            }
            else {              /* convert and write */
                        /* allocate buffer */
                buf = DFIgetspace((unsigned) (outNTsize * sdg->dimsizes[j]));
                if (buf==NULL) {
                    Isscales = DFIfreespace(Isscales);
                    return(-1);
                }

                        /* convert, all at once */
                DFconvert((char*) sdg->dimscales[j], buf, DFNT_FLOAT,
			  localNT, outNT, sdg->dimsizes[j], error);
                        /* write it all out */
                if (DFwrite(dfile, buf,
			    (int32) (outNTsize * sdg->dimsizes[j]))<0) {
                    Isscales = DFIfreespace(Isscales);
                    buf = DFIfreespace(buf);
                    return(-1);
                }
                buf = DFIfreespace(buf);
            }
        }
        Ref.scales = ref;
    }
    Isscales = DFIfreespace(Isscales);
    if (Ref.scales>0) if (DFdiput(DFTAG_SDS, (uint16) Ref.scales) < 0)
	return(-1);

    /* write coordsys */
    if (!sdg->coordsys || !sdg->coordsys[0]) Ref.coordsys = (-1);
    if (!Ref.coordsys) {
        if (DFputelement(dfile, DFTAG_SDC, ref, sdg->coordsys,
                            (int32) (strlen(sdg->coordsys)+1))<0) return(-1);
        Ref.coordsys = ref;
    }
    if (Ref.coordsys>0) if (DFdiput(DFTAG_SDC, (uint16) Ref.coordsys) < 0)
	return(-1);
        
    /* write max/min */
    if (!Ref.maxmin) {
        if (localNT == outNT) {     /* no conversion */
            if (DFputelement(dfile, DFTAG_SDM, ref, (char*) &sdg->max_data,
			     (int32) (2 * sizeof(float32)))<0) return(-1);
            Ref.maxmin = ref;
        }
        else {
	    /* allocate buffer */
#ifndef CVT_BUG
	    float32 mm[2];
	    mm[0] = sdg->max_data;
	    mm[1] = sdg->min_data;
#endif
            buf = DFIgetspace((unsigned) 2*outNTsize); /* max/min is 8 bytes */
            if (buf==NULL) return(-1);

	    /* convert */
#ifndef CVT_BUG
	    DFconvert((char*) mm, buf, DFNT_FLOAT, localNT, outNT,2, error);
#else
            DFconvert((char*) &sdg->max_data, buf, DFNT_FLOAT, localNT, outNT,
                      1, error);
            DFconvert((char*) &sdg->min_data, buf+outNTsize, DFNT_FLOAT,
		      localNT, outNT, 1, error);
#endif
	    /* write */
            if (DFputelement(dfile, DFTAG_SDM, ref, buf,
			     (int32) (2*outNTsize))<0) {
                buf = DFIfreespace(buf);
                return(-1);
            }
            Ref.maxmin = ref;
            buf = DFIfreespace(buf);
        }
    }
    if (Ref.maxmin>0) if (DFdiput(DFTAG_SDM, (uint16) Ref.maxmin) < 0)
	return(-1);
    Ref.maxmin = (-1);		/* max/min should be reset for each data set */

    if (!Ref.transpose) {
        if (DFaccess(dfile, DFTAG_SDT, ref, "w")<0) return(-1);
        Ref.transpose = ref;
    }
        
    if (Ref.transpose>0) if (DFdiput(DFTAG_SDT, (uint16) Ref.transpose) < 0)
	return(-1);

    /* write out SDG */
    return(DFdiwrite(dfile, DFTAG_SDG, ref));
}


/******************************************************************************/
/*----------------------- Internal routines ---------------------------------*/
/******************************************************************************/

/*-----------------------------------------------------------------------------
 * Name:    DFSDIopen
 * Purpose: open or reopen a file
 * Inputs:  filename: name of file to open
 *          access : access mode
 * Returns: file pointer on success, NULL on failure with DFerror set
 * Users:   HDF systems programmers, many SD routines
 * Invokes: DFopen
 * Remarks: This is a hook for someday providing more efficient ways to
 *          reopen a file, to avoid re-reading all the headers
 *---------------------------------------------------------------------------*/

DF *DFSDIopen(filename, access)
char *filename;
int access;
{

    DF *dfile;

    if (Sdfile!=NULL) {     /* in the middle of a partial write */
        DFerror = DFE_ALROPEN;
        return(NULL);
    }

        /* use reopen if same file as last time - more efficient */
    if (strncmp(Lastfile,filename,DF_MAXFNLEN) || (access==DFACC_CREATE)) {
                                    /* treat create as different file */
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);
        Newdata = (-1);         /* data in Readsdg is not fresh */
        Readsdg.data.ref = 0;   /* No SDG read yet */

                    /* remember no info written to file */
        Ref.scales  = (Ref.scales  >= 0) ? 0 : Ref.scales;
        Ref.luf[LABEL]  = (Ref.luf[LABEL]  >= 0) ? 0 : Ref.luf[LABEL];
        Ref.luf[UNIT]   = (Ref.luf[UNIT]   >= 0) ? 0 : Ref.luf[UNIT];
        Ref.luf[FORMAT] = (Ref.luf[FORMAT] >= 0) ? 0 : Ref.luf[FORMAT];
        Ref.dims    = (Ref.dims    >= 0) ? 0 : Ref.dims;
        Ref.coordsys = (Ref.coordsys >= 0) ? 0 : Ref.coordsys;
        Ref.maxmin = (Ref.maxmin >= 0) ? 0 : Ref.maxmin;
        Ref.nt = (Ref.nt >= 0) ? 0 : Ref.nt;
    }
    else
        if (!(dfile = DFopen(filename, access, -1))) return(NULL);

    strncpy(Lastfile, filename, DF_MAXFNLEN); 
            /* remember filename, so reopen may be used next time if same file*/

    return(dfile);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDIsdginfo
 * Purpose: Locates next sdg in file
 * Inputs:  dfile: pointer to DF file
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF systems programmers, DFSDgetdims, DFSDgetdata
 * Invokes: DFIfind, DFSDgetsdg
 * Method:  Call DFIfind to find SDG, then DFSDgetsdg to read it in to Readsdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

DFSDIsdginfo(dfile)
DF *dfile;
{
    DFdle *dlep;
    int cdd;

    if (DFIcheck(dfile)) {
        DFerror = DFE_BADCALL;
        return(-1);
    }
        
    /* find next sdg */
    if ((!Readref
	 && DFIfind(dfile, DFTAG_SDG, DFREF_WILDCARD, !Readsdg.data.ref,
		DFTAG_SDG, Readsdg.data.ref, &dlep, &cdd) <0)
	||
	(Readref
	 && DFIfind(dfile, DFTAG_SDG, Readref, 1, 0, 0, &dlep, &cdd) < 0)) {
        Newdata = (-1);
        DFerror = DFE_NOMATCH;
        return(-1);
    }
    if (DFSDgetsdg(dfile, dlep->dd[cdd].ref, &Readsdg)<0) return(-1);

    Lastref = dlep->dd[cdd].ref; /* remember ref read */

    /* now Readsdg is fresh */
    Newdata=1;
    Readref = 0;

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDIclear
 * Purpose: Reset all "set" values, free allocated space
 * Inputs:  sdg: pointer to sdg struct to clear
 * Globals: Ref
 * Returns: 0 on success, -1 on error with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Release space in sdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

int DFSDIclear(sdg)
DFSsdg *sdg;
{
    int luf, i;

    DFerror = DFE_NOERROR;

    if (Sdfile !=NULL) {                /* cannot clear during slice writes */
        DFerror = DFE_BADCALL;
        return(-1);
    }

    sdg->dimsizes = (int32 *) DFIfreespace((char*) sdg->dimsizes);

    sdg->coordsys = DFIfreespace(sdg->coordsys);

        /* free label/unit/format pointers */
    for (luf=LABEL; luf<=FORMAT; luf++) {
        if (sdg->dimluf[luf])       /* free strings */
            for (i=0; i<sdg->rank; i++)
                sdg->dimluf[luf][i] = DFIfreespace(sdg->dimluf[luf][i]);

	/* free string pointers */
        sdg->dimluf[luf] = (char **) DFIfreespace((char*) sdg->dimluf[luf]);

	/* free data string */
        sdg->dataluf[luf] = DFIfreespace(sdg->dataluf[luf]);
    }

    /* free scale pointers */
    if (sdg->dimscales)
        for (i=0; i<sdg->rank; i++)
            sdg->dimscales[i] = (float32 *)
		DFIfreespace((char*) sdg->dimscales[i]);

    /* free array of scale pointers */
    sdg->dimscales = (float32 **) DFIfreespace((char*)sdg->dimscales);

    sdg->rank = 0;

    Ref.dims = -1;
    Ref.scales = Ref.luf[LABEL] = Ref.luf[UNIT] = Ref.luf[FORMAT] = (-1);
    Ref.coordsys = Ref.maxmin = (-1);
    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDIgetdata
 * Purpose: Get data from SDG.  Will sequence to next SDG if DFSDgetdims not
 *          called.
 * Inputs:  filename: name of HDF file to use
 *          rank: no of dimensions of array "data"
 *          maxsizes: actual dimensions of array "data"
 *          data: data for returning scientific data
 *          isfortran : 0 if called from C, 1 when called from FORTRAN
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: actual scientific data in array
 * Users:   DFSDgetdata
 * Invokes: DFSDIgetslice, DFIgetspace, DFIfreespace, DFSDIopen, DFclose,
 *          DFIerr, DFSDIsdginfo
 * Method:  Open file, call DFSDIsdginfo to read sdg if necessary, set up
 *          window start and end arrays, call DFSDIgetslice.
 * Remarks: maxsizes may be larger than actual size.  In that event, the actual
 *          data may not be contiguous in the array "data"
 *          User sets maxsizes before call.
 *---------------------------------------------------------------------------*/


int DFSDIgetdata(filename, rank, maxsizes, data, isfortran)
char *filename;
int rank;
int32 maxsizes[];
float32 data[];
int isfortran;
{
    int32 *winst, *windims;
    int ret, i;
    DF *dfile;

    DFerror = DFE_NOERROR;

    if (Newdata!=1 || Nextsdg) { /* if Readsdg not fresh */
        dfile = DFSDIopen(filename, DFACC_READ);
        if (dfile == NULL) return(-1);
        if (DFSDIsdginfo(dfile)<0) /* reads next SDG from file */
            return(DFIerr(dfile));
        if (DFclose(dfile)<0) return(-1);
    }

    winst = (int32 *) DFIgetspace((unsigned) Readsdg.rank * sizeof(int32));
    if (winst==NULL) return(-1);
    windims = (int32 *) DFIgetspace((unsigned) Readsdg.rank * sizeof(int32));
    if (windims==NULL) {
		DFIfreespace((char*) winst);
		return(-1);
	}

    for (i=0; i<rank; i++) {
        winst[i] = 1;
        windims[i] = Readsdg.dimsizes[i];
	}

    ret = DFSDIgetslice(filename, winst, windims, data, maxsizes,
			isfortran);
    winst = (int32 *) DFIfreespace((char*) winst);
    windims = (int32 *) DFIfreespace((char*) windims);
    Nextsdg = 1;
    return(ret);
}


/*-----------------------------------------------------------------------------
 * Name:    DFSDIputdata
 * Purpose: Writes entire SDG to file
 * Inputs:  filename: name of HDF file to use
 *          rank: rank of data array
 *          dimsizes: sizes of the dimensions of data array
 *          data: array that holds data
 *          accmode: 0 if write to new file, 1 if append to file
 *          isfortran: 0 if C, 1 if FORTRAN
 * Globals: Writeref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: DFSDIopen, DFclose, DFIgetspace, DFIfreespace, DFSDIputslice,
 *          DFSDstartslice, DFSDendslice
 * Method:  Create file if necessary, allocate arrays, call slice routines
 *---------------------------------------------------------------------------*/

int DFSDIputdata(filename, rank, dimsizes, data, accmode, isfortran)
char *filename;
int16  rank;
int32   *dimsizes;
float32 *data;
int accmode;
int isfortran;
{
    int ret;
    DF *dfile;

    DFerror = DFE_NOERROR;

    if (!accmode) {                             /* new file */
        dfile = DFSDIopen(filename, DFACC_CREATE);
        if (dfile == NULL) return(-1);
        if (DFclose(dfile)<0) return(-1);
    }

    if (Ref.dims)       /* don't call setdims if already called */
        if (DFSDsetdims(rank, dimsizes)<0) return(-1);

    if (DFSDstartslice(filename)<0) return(-1);

    if ((ret=DFSDIputslice(Writesdg.dimsizes, data, dimsizes, isfortran)) <0)
	return ret;

    return DFSDendslice();
}

/*----------------------------------------------------------------------------
 * Name:    DFSDIgetslice
 * Purpose: Get slice of data from SDG.  Will sequence to next SDG if
 *          DFSDgetdims, DFSDgetdata or DFSDgetslice not called earlier.
 * Inputs:  filename: name of HDF file to use
 *          winst: array of size = rank of data, containing start of slice
 *          windims: array of size rank, containing size of slice
 *          data: array for returning slice
 *          dims: dimensions of array data
 *          isfortran : 0 if called from C, 1 when called from FORTRAN
 * Returns: 0 on success, -1 on failure with DFerror set
 * Outputs: slice of data in data
 * Users:   DFSDIgetdata
 * Invokes: DFSDIopen, DFclose, DFIerr, DFSDIsdginfo, DFaccess, DFread
 * Method:  Open file, call DFSDIsdginfo to read sdg if necessary, read the
 *          data, convert types if necessary, place in data as appropriate
 *          data is assumed column major for FORTRAN, row major for C
 * Remarks: dims may be larger than size of slice.  In that event, the actual
 *          data may not be contiguous in the array "data".
 *          User sets dims before call.
 *--------------------------------------------------------------------------*/

int DFSDIgetslice(filename, winst, windims, data, dims, isfortran)
    char	*filename;
    int32	winst[];	/* array containing starting dimensions */
				/* of the slice	*/
    int32	windims[];	/* array containing the size of the slice */
    int32	dims[];		/* array containing the dimensions of data[] */
    float32	data[];		/* array to hold the floating point data read*/
    int		isfortran;	/* true if called from Fortran */

{
    int
	rank,			/* number of dimensions in data[] */
	leastsig,		/* fastest varying subscript in the array */
	error;			/* flag if an error occurred */
				/* used by DFconvert macro */
    int
	convert,		/* true if machine NT = NT to be read */
	done,			/* true if we are at end of the slice */
	transposed;		/* true if we must transpose */
				/* the data before writing */
    int32
	i, j,			/* temporaries */
	numfloats,		/* number of floats to read at once */
	readsize,		/* number of bytes to read at once */ 
	stride,			/* number of floats in one row of data[] */
	*dimsleft,		/* array for tracking the current position */
				/* in data[] */
	*offset,		/* array for accessing the next element */
				/* in data[] */
	*foffset,		/* array for accessing the next element */
				/* from the file   */
	fileoffset,		/* offset into the current dataset */
				/* in the file          */
	*wstart,		/* tmp array containing starting slice dims */
	*wdims,			/* tmp array containing the slice size */
	*adims,			/* tmp array containing the dimensions */
				/* of data[] */
	*fdims;			/* tmp array containing the */
				/* dataset dimensions */
			
    float32
	*datap,			/* ptr into data[] at starting offset */
				/* of current block */
	*dp,			/* ptr into data[] at an element */
				/* of the current row */
	*scatterbuf;		/* buffer to hold the */
				/* current row contiguously */
    char
	*buf;			/* buffer containing the */
				/* converted current row */
    DF	*dfile;			/* HDF file pointer */

    DFerror = DFE_NOERROR;

    if (!data) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    dfile = DFSDIopen(filename, DFACC_READ);
    if (dfile == NULL) return(-1);

    if (Newdata!=1) {		/* if Readsdg not fresh */
        if (DFSDIsdginfo(dfile)<0) /* reads next SDG from file */
            return(DFIerr(dfile));
    }

    rank = Readsdg.rank;

    /* get dimensions of slice to extract, set nwindims. also err check */
    for (i=0; i<rank; i++) {
    	/* check validity for the dimension ranges */
        if ((windims[i]<=0) || (winst[i]<=0)
	    || (winst[i]+windims[i]-1 > Readsdg.dimsizes[i])) {
	    DFerror = DFE_BADDIM;
	    return(DFIerr(dfile));
	}
	/* check if space allocated is sufficient */
	if (dims[i]<windims[i]) {
            DFerror = DFE_NOTENOUGH;
            return(DFIerr(dfile));
        }
    }

    /* allocate buffers */
    wstart = (int32 *) DFIgetspace((unsigned) 4 * rank * sizeof(int32));
    if (wstart == NULL) {
	DFerror = DFE_NOSPACE;
        return(DFIerr(dfile));
    }
    wdims = wstart + rank;
    adims = wdims + rank;
    fdims = adims + rank;

    /* copy arrays to private workspace (so that they are in row major order)*/
    for (i=0; i<rank; i++) {
	int ii = isfortran ? rank-i-1 : i;
	adims[i] = dims[ii];
	ii = FileTranspose ? rank-i-1 : i;
	wstart[i] = winst[ii]-1; /* translate to 0 origin */
	wdims[i] = windims[ii];
	fdims[i] = Readsdg.dimsizes[ii];
    }

    userNT     = (DF_MT>>8) & 0x0f; /* get third nibble from right*/
    convert    = (fileNT != userNT); /* is conversion necessary */
    transposed = isfortran ^ FileTranspose; /* is transposition needed */

    /*
     * Note that if the data is transposed we must work on a row by row
     * basis and cannot collapse dimensions.
     */
    if (!transposed) {
	/* collapse dimensions if contiguous both in the file and in memory */
	for (i=rank-1; i>0; i--) { /* stop before most sig dim */
	    if (adims[i] > wdims[i] /* not all of data[] will be filled */
		|| wstart[i] != 0 /* reading only part of the dataset */
		|| wdims[i] < fdims[i])
		break;
	    wstart[i-1] = wstart[i-1] * wdims[i];
	    wdims[i-1] *= wdims[i];
	    adims[i-1] = fdims[i-1] = wdims[i-1];
	    rank--;
	}
    }
    leastsig = rank-1;		/* which is least sig dim */

    /* position at start of image */
    if (DFaccess(dfile, Readsdg.data.tag, Readsdg.data.ref, "r") < 0) {
	DFIfreespace((char *)wstart);
        return(DFIerr(dfile));
    }

    error = 0;
    if (rank==1 && !convert) {
	/* all data is contiguous with no conversions */
	readsize = adims[0] * sizeof(float32);
	if (DFIseek(dfile, wstart[0]*fileNTsize) < 0 ||
	    readsize != DFread(dfile, (char *)data, readsize))
	    error=1;
    } else {
	/*
	 * The data must be further manipulated.
	 * It may be transposed, may need conversion, may not be contiguous, or
	 * any combination of these.
	 */
	numfloats  = wdims[leastsig];
	readsize = numfloats * fileNTsize;

	/* allocate 1 row buffers */
	if (convert) {
	    if ((buf = DFIgetspace((unsigned) readsize)) == NULL) {
		DFIfreespace((char *)wstart);
		DFerror = DFE_NOSPACE;
		return(DFIerr(dfile));
	    }
	} else buf = NULL;

	if (transposed) {
	    scatterbuf = (float32 *)DFIgetspace((unsigned) numfloats
						*sizeof(float32));
	    if (scatterbuf == NULL) {
		DFIfreespace((char *)wstart);
		DFIfreespace(buf);
		DFerror = DFE_NOSPACE;
		return(DFIerr(dfile));
	    }
	} else scatterbuf = NULL;

	offset = (int32 *) DFIgetspace((unsigned)3 * rank * sizeof(int32));
	if (offset==NULL) {
	    DFIfreespace((char *)wstart);
	    DFIfreespace(buf);
	    DFIfreespace((char *)scatterbuf);
	    DFerror = DFE_NOSPACE;
	    return(DFIerr(dfile));
	}
	foffset = offset + rank;
	dimsleft = foffset + rank;

	/* compute initial position in the data */
	for (i=leastsig; i>=0; i--)
	    dimsleft[i] = wdims[i];

	/* compute offsets in the source array */
	if (transposed) {
	    offset[0] = 1;
	    for (i=0; i<leastsig; i++)
		offset[i+1] = offset[i] * adims[leastsig - i];
	} else {
	    offset[leastsig] = 1;
	    for (i = leastsig; i>0; i--)
		offset[i-1] = offset[i] * adims[i];
	}
	stride = offset[leastsig];

	/* compute offsets in the file */
	for (i=leastsig, foffset[i]=1*fileNTsize; i>0; i--)
	    foffset[i-1] = foffset[i] * fdims[i];

	/*
	 * Compute starting position in file
	 * All file reads are done relative to this starting offset.
	 * Cumulative offset is from most sig to next to least sig dim.
	 */
	for (i=0, fileoffset=0; i<leastsig; i++) 
	    fileoffset = (fileoffset+wstart[i]) * fdims[i+1];
	fileoffset += wstart[leastsig]; /* adjust for last dim */
	fileoffset *= fileNTsize; /* convert to bytes */

	datap = data;
	done = 0;

	/* -- now read in the data */
	do {
	    /* move to the next data element in the file */
	    if (DFIseek(dfile, fileoffset) < 0) {
		error=1;
		break;
	    }

	    /* read and convert one contiguous block of data */
	    if (convert) {
		if (readsize != DFIread(dfile, buf, readsize)) {
		    error=1;
		    break;
		}
		DFconvert(buf, transposed ? (char *)scatterbuf : (char *)datap,
			  DFNT_FLOAT, fileNT, userNT, numfloats, error);
	    }
	    else
		if (readsize != DFIread(dfile, transposed ?
				       (char *)scatterbuf :
				       (char *)datap, readsize)) {
		    error=1;
		    break;
		}

	    if (transposed) {
		/* scatter out the elements of one row */
#ifdef UNICOS
#pragma ivdep
#endif
		for (dp=datap, i=0; i<numfloats; i++) {
		    *dp = scatterbuf[i];
		    dp += stride;
		}
	    }

	    /*
	     * Find starting place of the next row/block.
	     * Note that all moves are relative:
	     *   this preserves the starting offsets of each dimension 
	     */
	    for (i=leastsig-1; i>=0; i--) {
		if (--dimsleft[i] > 0) {
		    /* move to next element in the current dimension */
		    datap += offset[i];
		    fileoffset += foffset[i];
		    break;
		} else {
		    dimsleft[i] = wdims[i];
		    /*
		     * Note that we are still positioned at the beginning of
		     * the last element in the current dimension 
		     */
		    /* move back to the beginning of dimension i */
		    datap -= offset[i] * (wdims[i]-1);
		    /* move back to beginning read position of dimension i */
		    fileoffset -= foffset[i] * (wdims[i]-1);
		    if (i==0) done = 1;
		}
	    }
	} while (!done && leastsig > 0);

	DFIfreespace(buf);
	DFIfreespace((char *)scatterbuf);
	DFIfreespace((char *)offset);
    }

    DFIfreespace((char *)wstart);
    return( error ? DFIerr(dfile) : DFclose(dfile) );
}

/*----------------------------------------------------------------------------
 * Name:    DFSDIputslice
 * Purpose: Put slice of data to SDG.
 * Inputs:  windims: array of size rank, containing size of slice
 *          data: array containing slice
 *          dims: dimensions of array data
 *	    	isfortran: 0 for C, 1 for Fortran
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   DFSDputslice
 * Invokes: DFwrite, DFIgetspace, DFIfreespace
 * Method:  check dimensions for contiguity, convert types if necessary
 *          write to file
 * Remarks: dims may be larger than size of slice.  In that event, the actual
 *          data may not be contiguous in the array "data".
 *          DFSDstartslice must have been called first
 *          Note, writes must be contiguous - successive calls to putslice
 *          must write out array consecutively, according to the setting
 *          of the Fortorder variable - row major if 0, column major if 1
 *--------------------------------------------------------------------------*/

int DFSDIputslice(windims, data, dims, isfortran)

    int32	windims[];	/* array containing dimensions of the slice */
    int32	dims[];		/* array containing the dimensions of data[] */
    float32	data[];		/* array of the floating point data to write */
    int		isfortran;	/* true if called from Fortran */
{
    int
	rank,			/* number of dimensions in data[] */
	ret,			/* return code from DFwrite */
	leastsig;		/* fastest varying subscript in the array */
    int
	convert,		/* true if machine NT = NT to be written */
	done,			/* true if we are at end of the slice */
	transposed,		/* true if we must transpose */
				/* the data before writing	*/
	contiguous;		/* true if there are no gaps */
				/* in the data to be written	*/
    int error;			/* used by DFconvert macro */
    int32
	i, j,			/* temporaries */
	numfloats,		/* number of floats to write out per row */
	writesize,		/* number of bytes to write out per row */
	stride,			/* number of bytes in one row of data[] */
	*dimsleft,		/* array for tracking the */
				/* current position in data[]	*/
	*offset;		/* array for accessing the */
				/* next element in data[] */
    float32
	*datap,			/* pointer into data[] at */
				/* the start of the current row	*/
	*dp,			/* pointer into data[] to an element */
				/* of the current row */
	*gatherbuf;		/* buffer to hold the current row */
				/* contiguously */
    char
	*buf,			/* buffer containing the */
				/* converted current row */
	*outbufp;		/* pointer to the buffer containing */
				/* the data to write */

    DFerror = DFE_NOERROR;

    if (!data) {
        DFerror = DFE_BADPTR;
        return(-1);
    }

    if (!Sdfile) {
        DFerror = DFE_BADCALL;
        return(-1);
    }

    rank = Writesdg.rank;

    for (i=0; i<rank; i++) {
    	/* check validity for the dimension ranges */
        if ((windims[i]<=0) || (windims[i]>Writesdg.dimsizes[i])) {
            DFerror = DFE_BADDIM;
            return(-1);
        }
	/* check if space allocated is sufficient */
	if (dims[i] < windims[i]) {
	    DFerror = DFE_NOTENOUGH;
	    return(-1);
	}
    }

    /* check to see if the slices fit together */
    if (Fortorder) {
	/* find the first significant dimension */
	for (i=rank-1; windims[i] == 1 && i>0; i--)
	    ;
	/* check that all 'lesser' dims match */
	for (j=i-1; j>=0; j--)
	    if (dims[j] != windims[j]) {
		DFerror = DFE_BADDIM;
		return (-1);
	    }
	/* update Sddims to reflect new write */
	Sddims[i] += windims[i];
	for (; i<rank-1 && Sddims[i] >= dims[i]; i++) {
	    Sddims[i+1] += Sddims[i] / dims[i]; /* promote the unit */
	    Sddims[i] %= dims[i];
	}
    } else {
	/* find the first significant dimension */
	for (i=0; windims[i] == 1 && i<rank-1; i++)
	    ;
	/* check that all 'lesser' dims match */
	for (j=i+1; j<rank; j++)
	    if (dims[j] != windims[j]) {
		DFerror = DFE_BADDIM;
		return (-1);
	    }
	/* update Sddims to reflect new write */
	Sddims[i] += windims[i];
	for (;i>0 && Sddims[i] >= dims[i]; i--) {
	    Sddims[i-1] += Sddims[i] / dims[i]; /* promote the unit */
	    Sddims[i] %= dims[i];
	}
    }

    leastsig = Fortorder ? 0 : rank-1; /* which is least sig dim */
    userNT = (DF_MT>>8) & 0x0f;	/* get third nibble from right */
    convert = (outNT != userNT); /* is conversion necessary */
    transposed = isfortran ^ Fortorder;	/* is data transposition needed */

    contiguous = !transposed;
    for (i=0; contiguous && i<rank; i++) {
	/* check if data at the start of the users array will be contiguous */
	/* NOTE: do this if a winstart[] array is ever added */

	/* check if data at the end of the users array will be contiguous */
	if (dims[i] > Writesdg.dimsizes[i])
	    contiguous = 0;
    }

    /*
     *	3 Factors that determine how we write (in order of importance)
     *	transposed, conversion, contiguous
     */

    if (!transposed) {
	if (!convert && contiguous) {
	    /* compute total number of floats to write */
	    for (i=0, numfloats=1; i<rank; i++) numfloats *= windims[i];
	    writesize = numfloats * sizeof(float32);
	    if ((ret = DFwrite(Sdfile, (char *)data, writesize)) < 0)
		return(DFIerr(Sdfile));
	}
	else {			/* must step through the data */
	    /* compute number of occurrences of the least sig dim */
	    if (Fortorder)
		for (i=rank-1, j=1; i>0; i--) j *= windims[i];
	    else
		for (i=0, j=1; i<rank-1; i++) j *= windims[i];
	    numfloats = windims[leastsig];
	    writesize = numfloats * outNTsize;
	    stride = dims[leastsig];
	    if (convert) { 
		buf = DFIgetspace((unsigned) writesize);
		if (buf == NULL) return(DFIerr(Sdfile));
		for (i=0; i<j; i++, data+=stride) {
		    DFconvert((char *)data, buf, DFNT_FLOAT,
			      userNT, outNT, numfloats, error);
		    if ((ret = DFwrite(Sdfile, buf, writesize)) < 0) {
			DFIfreespace(buf);
			return(DFIerr(Sdfile));
		    }
		}
		DFIfreespace(buf);
	    }
	    else {
		for (i=0; i<j; i++, data+=stride)
		    if ((ret = DFwrite(Sdfile, (char *)data, writesize)) < 0)
			return(DFIerr(Sdfile));
	    }
	}
    } else {			/* transposed */
	numfloats = windims[leastsig];
	writesize = numfloats * outNTsize;

	/* allocate 1 row buffers */
	if (!convert) buf = NULL;
	else {
	    if ((buf = DFIgetspace((unsigned) writesize)) == NULL) {
		DFerror = DFE_NOSPACE;
		return(-1);
	    }
	}
	gatherbuf = (float32 *)DFIgetspace((unsigned) numfloats
					   *sizeof(float32));
	offset = (int32 *) DFIgetspace((unsigned) 2 * rank * sizeof(int32));
	dimsleft = offset + rank;
	if (gatherbuf==NULL || offset==NULL) {
	    DFIfreespace(buf);
	    DFIfreespace((char *)gatherbuf);
	    DFIfreespace((char *)offset);
	    DFerror = DFE_NOSPACE;
	    return(-1);
	}

	/* initialize the dimension counter */
	for (i=0; i<rank; i++)
	    dimsleft[i] = windims[i];

	datap = data;
	done = 0;
	outbufp = convert ? buf : (char *)gatherbuf;

	/* -- now write out the data */

	/* compute offsets in the source array */
	if (isfortran)
	    for (i=0, offset[0]=1; i<rank-1; i++)
		offset[i+1] = offset[i]*dims[i];
	else
	    for (i=rank-1, offset[i]=1; i > 0; i--)
		offset[i-1] = offset[i]*dims[i];
	stride = offset[leastsig];

	/* step thru the data on a row by row basis */
	do {
	    /* gather the elements of one row together */
#ifdef UNICOS
#pragma ivdep
#endif
	    for (dp=datap, i=0; i<numfloats; i++) {
		gatherbuf[i] = *dp;
		dp += stride;
	    }

	    /* convert and write the row */
	    if (convert)
		DFconvert((char *)gatherbuf, buf, DFNT_FLOAT,
			  userNT, outNT, numfloats, error);
	    ret = DFwrite(Sdfile, outbufp, writesize);

	    /* find the start of the next row */
	    if (Fortorder) {
		for (i=1; i<rank; i++) {
		    if (--dimsleft[i] > 0) {
			/* move to next element in the current dimension */
			datap += offset[i];
			break;
		    }
		    else {	/* move back to the beginning of dimension i */
			datap -= offset[i]*(dimsleft[i] = windims[i]);
			datap += offset[i];
			if (i == rank-1) done = 1;
		    }
		}
	    } else {		/* !Fortorder */
		for (i=rank-2; i>=0; i--) {
		    if (--dimsleft[i] > 0) {
			/* move to next element in the current dimension */
			datap += offset[i];
			break;
		    }
		    else {	/* move back to the beginning of dimension i */
			datap -= offset[i]*(dimsleft[i] = windims[i]);
			datap += offset[i];
			if (i == 0) done = 1;
		    }
		}
	    }
	} while (!done && ret >= 0 && rank > 1);

	DFIfreespace(buf);
	DFIfreespace((char *)gatherbuf);
	DFIfreespace((char *)offset);
    }

    return(ret>=0 ? 0 : -1);
}

/******************************************************************************/
/*----------------------- Internal routines ---------------------------------*/
/******************************************************************************/

/*-----------------------------------------------------------------------------
 * Name:    dsisdas_
 * Purpose: Set label, unit and format for displaying subsequent SDGs
 * Inputs:  label: label to be used to describe data
 *          unit: unit corresponding to data values
 *          format: format to be used in displaying data values
 *          coordsys: type of coordinate system
 *          isfortran: 1 if called from Fortran, 0 if called from C
 *          llabel, lunit, lformat, lcoordsys: lengths of correspoding strings
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global structure Writesdg
 * Remarks: none
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsisdas_(label, unit, format, coordsys, isfortran, llabel, lunit,
	 lformat, lcoordsys)
    char *label, *unit, *format, *coordsys;
    int *isfortran;
    int *llabel, *lunit, *lformat, *lcoordsys;
{

    int luf;                /* takes values LABEL, UNIT, FORMAT in succession */
    char *lufp;             /* points to label, unit, format in succession */
    int luflen;             /* length of luf */

    DFerror = DFE_NOERROR;

    for (luf=LABEL; luf<=FORMAT; luf++) {
	/* set lufp to point to label etc. as apppropriate */
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;
        if (*isfortran)
            luflen = (luf==LABEL) ? *llabel : (luf==UNIT) ? *lunit : *lformat;
        else luflen = strlen(lufp);

	/* free space if allocated */
        Writesdg.dataluf[luf] = DFIfreespace(Writesdg.dataluf[luf]);

	/* copy string */
        if (lufp) {
            Writesdg.dataluf[luf] = DFIgetspace((unsigned) luflen+1);
            if (Writesdg.dataluf[luf]==NULL) return(-1);
            strncpy(Writesdg.dataluf[luf], lufp, luflen);
            Writesdg.dataluf[luf][luflen] = '\0';
        }
    }

    Writesdg.coordsys = DFIfreespace(Writesdg.coordsys);
    luflen = *isfortran ? *lcoordsys : strlen(coordsys);

    if (coordsys) {
        Writesdg.coordsys = DFIgetspace((unsigned) luflen+1);
        if (Writesdg.coordsys==NULL) return(-1);
        strncpy(Writesdg.coordsys, coordsys, luflen);
        Writesdg.coordsys[luflen] = '\0';
    }

    /* indicate that label, unit, format and coordsys info modified */
    Ref.luf[LABEL] = Ref.luf[UNIT] = Ref.luf[FORMAT] = Ref.coordsys = 0;

    return(0);
}


/*-----------------------------------------------------------------------------
 * Name:    dsisdis_
 * Purpose: For the given dimension, set label, unit, format
 *          This routine needs to be called once for each dimension whose 
 *          values the user wants to set.
 * Inputs:  dim: the dimension that this info applies to
 *          label: label to be used to describe this dimension
 *          unit: units for dimension
 *          format: format to be used in displaying
 *          isfortran: 1 if called from Fortran, 0 otherwise
 *          llabel, lunit, lformat: lengths of corresponding strings
 * Globals: Writesdg, Ref
 * Returns: 0 on success, -1 on failure with DFerror set
 * Users:   HDF users, utilities, other routines
 * Invokes: none
 * Method:  Stores values in global structure Writesdg
 *---------------------------------------------------------------------------*/

	FCALLKEYW int
dsisdis_(dim, label, unit, format, isfortran, llabel, lunit, lformat)
    int *dim;
    char    *label, *unit, *format;
    int *isfortran;
    int *llabel, *lunit, *lformat;
{

    int i, rdim;
    int luf;                /* takes values LABEL, UNIT, FORMAT in succession */
    char *lufp;             /* points to label, unit, format in succession */
    int luflen;             /* length of lufp */

    DFerror = DFE_NOERROR;

    rdim = *dim-1;      /* translate from 1 to 0 origin */

    if ((rdim>=Writesdg.rank) || (rdim<0)) {
        DFerror = DFE_BADDIM;
        return(-1);
    }

    for (luf=LABEL; luf<=FORMAT; luf++) {
            /* set lufp to point to label etc. as apppropriate */
        lufp = (luf==LABEL) ? label : (luf==UNIT) ? unit : format;
        if (*isfortran)
            luflen = (luf==LABEL) ? *llabel : (luf==UNIT) ? *lunit : *lformat;
        else luflen = strlen(lufp);

            /* allocate space if necessary */
        if (!Writesdg.dimluf[luf]) {
            Writesdg.dimluf[luf] =
                (char **) DFIgetspace((unsigned)Writesdg.rank * sizeof(char *));
            if (Writesdg.dimluf[luf]==NULL) return(-1);
            for (i=0; i<Writesdg.rank; i++) /* set allocated pointers to NULL */
                Writesdg.dimluf[luf][i] = NULL;
        }

	/* free string space if allocated */
        Writesdg.dimluf[luf][rdim] = DFIfreespace(Writesdg.dimluf[luf][rdim]);

	/* copy string */
        if (lufp) {
            Writesdg.dimluf[luf][rdim] = DFIgetspace((unsigned) luflen+1);
            if (Writesdg.dimluf[luf][rdim]==NULL) return(-1);
            strncpy(Writesdg.dimluf[luf][rdim], lufp, luflen);
            Writesdg.dimluf[luf][rdim][luflen] = '\0';
        }
    }

    /* Indicate that this info has not been written to file */
    Ref.luf[LABEL] = Ref.luf[UNIT] = Ref.luf[FORMAT] = 0;

    return(0);
}

