/*
 *	File:		gr_var.h
 *	Contents:	Header file containing all global variables used
 *				by the graphics module.
 */

Widget		gr_topLevel;		/* Top Level Widget */
A_TopWind_t	gr_topWin;		/* Top Window */
#if 0
char		gr_DirName[STRNG160];	/* Directory name */
char		gr_FileName[STRNG160];	/* File name */
#endif
A_Color_t	gr_color;		/* Color structure for palette */
A_Color_t	gr_colorSplit;		/* Color structure for split pal */
XtAppContext	app_context;		/* Application context. */
