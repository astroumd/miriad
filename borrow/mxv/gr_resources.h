/* gr_resources.h
Define resources available.
These are just the resources available as global variables &/or settable
via switches.
*/

typedef struct {
	Boolean adjustToggles;
	Boolean installCMap;
	Boolean	inputFocus;
	Boolean	useXImage;
	String	dataDir;		/* Initial data directory.	*/
	String	numFrames;		/* Number of animation frames.	*/
	String	scale;			/* Scale.			*/
	Boolean	debug;			/* Turn on debugging info.	*/
	Boolean	verbose;
	Boolean	listresources;		/* If TRUE, print resources.	*/
	String	fileformat;		/* HDF, MIRIAD or FITS		*/
	String	paletteDir;		/* Initial data directory.	*/
	String	palettename;		/* Name of initial palette.	*/
} ApplicationData, *ApplicationDataPtr;

extern ApplicationData gr_Data;
