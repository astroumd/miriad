/*
 *	File:		gr_proc.c
 *	Contents:	Preprocessor functions for graphics module
 */

#include "gr_com.h"

extern	void	td_ProcInterp();
extern	int		td_HdfPutSDS();
A_Data_t		*inhdf,*outhdf;


/*
 *	Process (interpolate and enlarge) an SDS
 */
void
gr_ProcSDS(num,scale,inname,outname,tparent)
int	 num,scale;
char *inname,*outname;
A_FileWind_t *tparent;
{
	int			i,j,k,xi,yi,zi;
	int			iscale=scale+1,dscale=scale+2;

	gr_WidgetCursor(tparent->shell,XC_watch);

	if ((inhdf = (A_Data_t *)td_Malloc(sizeof(A_Data_t),"A_Data_t")) == NULL)
		return;

	if ((outhdf = (A_Data_t *)td_Malloc(sizeof(A_Data_t),"A_Data_t")) == NULL)
		return;

	td_getPathName(inhdf->pathName, NULL, inname);

	if (td_HdfLoad(inhdf,num) == -1)
	{
		gr_WidgetCursor(tparent->shell,XC_cross);
		sprintf(msg,"HDF Error: Cannot load SDS %d from %s.\n",num,inname);
		gr_TextMsgOut(msg);
		td_Free((char *)inhdf);
		td_Free((char *)outhdf);
		return;
	};

	td_HdfgetStats(inhdf,FALSE,gr_color.nColors,gr_colorSplit.nColors,HDF);

	gr_TextMsgOut("Read in SDS...beginning interpolation.\n");

	*outhdf = *inhdf;
	strcpy(outhdf->pathName, td_getPathName(NULL, NULL, outname));

	outhdf->dims[0] = (inhdf->dims[0]-1)*scale+inhdf->dims[0];
	outhdf->dims[1] = (inhdf->dims[1]-1)*scale+inhdf->dims[1];
	outhdf->dims[2] = (inhdf->dims[2]-1)*scale+inhdf->dims[2];
	outhdf->data = td_Malloc3Dfloat32(outhdf->dims[0],outhdf->dims[1],
					outhdf->dims[2]);
	if (outhdf->data == NULL)
	{
		gr_TextMsgOut("Sorry.  Not enough memory to do interpolation.\n");
		td_Free3d(inhdf->data);
		td_Free((char *)inhdf);
		td_Free((char *)outhdf);
		return;
	}

    for (k=0;k<inhdf->dims[2]-1;k++)
    {
        for (j=0;j<inhdf->dims[1]-1;j++)
            for (i=0;i<inhdf->dims[0]-1;i++)
            {
                xi=i+1; yi=j+1; zi=k+1;

              td_ProcInterp(outhdf->data,iscale,dscale,i,j,k,
              (double)inhdf->data[i][j][k], (double)inhdf->data[xi][j][k],
              (double)inhdf->data[xi][yi][k], (double)inhdf->data[i][yi][k],
              (double)inhdf->data[i][j][zi], (double)inhdf->data[xi][j][zi],
              (double)inhdf->data[xi][yi][zi], (double)inhdf->data[i][yi][zi]);
            }
    }

	gr_TextMsgOut("Finished interpolation.\n");

	if (td_HdfPutSDS(outhdf) == -1)
		gr_TextMsgOut("HDF error: Cannot write SDS to file.\n");
	
	td_Free3d(inhdf->data);
	td_Free3d(outhdf->data);
	td_Free((char *)inhdf);
	td_Free((char *)outhdf);

	gr_WidgetCursor(tparent->shell,XC_cross);
}
