/*
 *	File:		gr_ext.h
 *	Contents:	Header file containing all the externs
 *				of the graphics module.
 */

/*
 * Local externs
 */
/*  'NEW' stuff. */
extern Widget gr_MakeBulletin2();
extern Widget gr_MakeButton3();
extern Widget gr_MakeRepeater();
extern Widget gr_MakeDialog();
extern Widget gr_MakeDialog1();	/* One line dialog. */
extern Widget gr_MakeForm();
extern Widget gr_MakeBoxForm();
extern Widget gr_MakeBox2();
extern Widget gr_MakeList2();
extern Widget gr_MakeToggle2();
extern Widget gr_MakeText2();
extern Widget gr_MakeWindow2();
extern Widget gr_MakeWorkSpace2();
extern Widget gr_MakeImageStatic2();
extern Widget gr_MakeSlider2();
extern Widget gr_MakeVPort2();
extern Widget gr_MakeLabel2();
extern Widget gr_MakeMenu(), gr_AddMenuEntry(), gr_MakeMenuButton();
extern Boolean gr_is_toggle_set();
extern	void	gr_free();		/* Widget destroy support.	*/
extern	String	gr_GetStringResource();
extern	String	gr_GetFileResource();
extern	int	gr_GetIntResource();
extern	float	gr_GetFloatResource();
extern	Boolean	gr_GetBooleanResource();

extern Widget gr_make_palette();

/*****/
extern void		gr_ButtonSet();
extern void		gr_DialogAddTrans();
extern void		gr_DialogSetValue();
extern void		gr_LabelSetValue();
extern void		gr_SliderSetValue();
extern void		gr_ListChange();
extern void		gr_ListHighlight();
extern void		gr_TextReplace();
extern void		gr_TextSetInsertionPoint();
extern void		gr_WidgetCursor();
extern void		gr_TextMsgOut();
extern void		gr_ImageSetCMap();
extern void		gr_ImageSetCMapSplit();
extern void		gr_LoadPAL();
extern void		gr_LoadPALSplit();
extern void		Notate();

extern A_BossWind_t	*gr_InitBossLevel();
extern Widget		gr_DialogGetTextWind();
extern XImage		*gr_ImageCreate();
extern Pixmap		gr_PixmapCreate();
extern char		*gr_FileGetFileStrng();
extern char		*gr_DialogGetValue();
extern char		*gr_ListgetStruct();
extern char		*gr_TextGetStr();
extern char		*gr_ViewgetData();

extern int		gr_SliderGetValue();
extern Visual	*gr_GetVisual();

/*
 * Inter-module externs
 */

extern void		td_Free();
extern void		td_Free2d();
extern void		td_Free3d();
extern void		td_Free2dChar();
extern void		td_Free2dInt();
extern void		td_Free2dVRect();
extern int		td_FileIsDir();
extern int		td_FileIsHdf();
extern int		td_FileExist();
extern char		**td_FileDirStrings();
extern char		*td_CurrentDate();
extern char		*td_getDirName();
extern char		*td_getLogFileName();
extern char		*td_getToolName();
extern Boolean		td_setDirName();
extern	char		*td_parseFilename();
extern char		*td_getDirName();
extern void		td_setFileName();
extern char		*td_getFileName();
extern String		td_getPathName();
extern A_Directory_t	td_SetDirIndex();
extern char		*td_HdfgetRasData();
extern char		*td_HdfgetRaster();
extern char		*td_HdfgetStats();
extern char		*td_HdfgetPixData();
extern char		**td_HdfgetHScale();
extern char		**td_HdfgetVScale();
extern char		**td_HdfgetPlaneData();
extern char		td_HdfConvertToPix();
extern char		td_HdfConvertToSplit();
extern int		td_HdfR8restart();
extern int		td_HdfPalrestart();
extern int		td_HdfSDrestart();
extern int		td_HdfgetDim();
extern int		td_HdfCheck();
extern int		td_HdfLoad();
extern int		td_HdfgetRasDims();
extern int		td_HdfAddImage();
extern int		td_HdfPutImage();
extern int		td_MiriadLoad();
extern char		*td_MiriadgetStats();
extern char		*td_Malloc();
extern char		*td_Malloc1D();
extern char		**td_Malloc2D();
extern char		**td_Malloc2DChar();
extern int		**td_Malloc2DInt();
extern A_VRect_t	**td_Malloc2DVRect();
extern float32	***td_Malloc3Dfloat32();
