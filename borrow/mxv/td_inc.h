/*
 *	File:		td_inc.h
 *	Contents:	Header file containing all the includes and externs
 *				by the td module.
 */
#include <stdio.h>
#include <X11/Intrinsic.h>
#include "df.h"
#include "mxv.h"

/*
 * Local calls
 */
extern	void	td_Free();
extern	void	td_Free2d();
extern	void	td_Free3d();
extern	void	td_Free2dChar();
extern	void	td_Free2dInt();
extern	void	td_Free2dVRect();
extern	char	*td_Malloc1D();
extern	char	**td_Malloc2D();
extern	float32	***td_Malloc3Dfloat32();
extern	char	*td_CurrentDate();
extern	int32	td_HdfCheckPlane();
extern  void 	td_Init();
extern	int	td_FileIsHdf();
extern char	*td_getVersion();
extern float	td_GetAxisValue();
extern char	*td_GetAxisValueString();

/*
 * Inter-module calls
 */

extern	void	gr_TextMsgOut();
