/* This is a global header file for all of ximage, meaning that it is
 * included in all the .c files. 

	This file, contains the old ximage copies of ximage.h, buttons.h
	and paletteP.h
 */



typedef struct {
	Boolean installCMap;
	} XIResources, *XIResourcesPtr;

extern XIResources appResources;
extern Boolean	defStaticVisual;	/* do windows default to stat visual?*/

	/* from (xi_)buttons.h */
extern	Widget	b[];		/* Butttons (b[]) are defined in main.c */

#define	CTRL_IMAGE	0
#define	CTRL_PALETTE	1
#define	CTRL_ANIMATE	2
#define IMAGE_DONE	3
#define CTRL_CALC	4
#define	CTRL_QUIT	5
#define IMAGE_CART	6
#define IMAGE_POLAR	7
#define IMAGE_DATA	8
#define IMAGE_GRAPH	9
#define	IMAGE_CDONE	10
#define IMAGE_PDONE	11
#define PAL_LOAD	12
#define PAL_FIDDLE	13
#define	PAL_INVERT	14
#define	PAL_ROTATE	15
#define PAL_T_ROTATE	16
#define PAL_SAVE	17
#define	PAL_DONE	18
#define	FILE_HDF	19
#define FILE_RASTER	20
#define FILE_SUNRASTER	21
#define	FILE_DONE	22
#define	CTRL_NOTEBOOK	23
#define IMAGE_W_DONE	24
#define PAL_CYAN	25
#define PAL_MAGENTA	26
#define PAL_YELLOW	27
#define PAL_HUE		28
#define	PAL_VALUE	29
#define	PAL_SATURATION	30
#define PAL_RED		31
#define	PAL_BLUE	32
#define PAL_GREEN	33
#define PAL_PCYAN	34
#define PAL_PMAGENTA	35
#define PAL_PYELLOW	36
#define PAL_PHUE	37
#define	PAL_PVALUE	38
#define	PAL_PSATURATION	39
#define PAL_PRED	40
#define	PAL_PBLUE	41
#define PAL_PGREEN	42
#define	PAL_EVAL	43
#define	PAL_RESET	44
#define	PAL_SMOOTH	45
#define	PAL_SETWINDOW	46
#define BUTTON_TABLE_SIZE	(PAL_SETWINDOW+1)

		/* from (xi_)paletteP.h */
#define	CRED		(1 << 9)
#define	CGREEN		(1 << 8)
#define	CBLUE		(1 << 7)
#define	CCYAN		(1 << 6)
#define	CMAGENTA	(1 << 5)
#define	CYELLOW		(1 << 4)
#define	CHUE		(1 << 3)
#define	CSATURATION	(1 << 2)
#define	CVALUE		(1 << 1)
#define	CLIGHTNESS	1
