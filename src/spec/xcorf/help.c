#include "xcorf.h"

#include <Xm/LabelG.h>
#include <Xm/MessageB.h>
#include <Xm/ScrolledW.h>

typedef struct {
    Widget widget;
    XmString title;
    XmString msg;
} HELP;

/* MAXHELPITEMS is defined in xcorf.h. */
static HELP helpList[MAXHELPITEMS];

/***********************************************************************/
#ifdef __STDC__
static void initHelpStrings(void)
#else
static void initHelpStrings()
#endif /*__STDC__*/
{
    /* Generate the help messages and titles to display. */

    helpList[HELPGENERAL].widget = (Widget)NULL;
    helpList[HELPGENERAL].title = XmStringCreateLtoR("General Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPGENERAL].msg = XmStringCreateLtoR("\
XCORF is an application that allows the perspective BIMA user to\n\
interactively choose correlator (corf) frequencies and bandwidths,\n\
toggle between different correlator setup modes, and explore different\n\
line, IF, and Vlsr arrangements.\n\n\
Use entries under the File pulldown menu to open and read an existing\n\
setup file, save the current correlator/frequency settings to a\n\
specified setup and file, read and then either load or merge a line\n\
frequency file, or exit from this program.\n\n\
Use selections under the Help pulldown menu to get help on other more\n\
specific topics of XCORF.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPAPPDEFS].widget = (Widget)NULL;
    helpList[HELPAPPDEFS].title = XmStringCreateLtoR("Application Resources",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPAPPDEFS].msg = XmStringCreateLtoR("\
XCORF permits you to override the initial defaults in many ways.  \
The application defaults may be included in the user's personal\n\
$HOME/.Xdefaults file or on the command line via the '-xrm arg' flag.  \
In some cases, a command line argument has also been provided\n\
to simplify entering a resource on the command line.  Finally, in addition \
to the following entries, there are the usual resources\n\
associated with the individual widgets, the overall geometry, and the \
application display that may be set as needed.\n\n\
                                       Application Defaults\n\
$HOME/.Xdefaults file or on the command line via the '-xrm arg' flag.  \
In some cases, a command line argument has also been provided\n\
------------------------------------------------------------------\
------------------------------------------------------------------\n\
  Name           Class          Type         Default         Description\n\
------------------------------------------------------------------\
------------------------------------------------------------------\n\
  iconGeometry   IconGeometry   String       <NONE>          \
Specifies the initial position of the application icon.\n\
  infile         Infile         String       lovas3mm.dat    \
The name of initial line file.\n\
  restfreq       Restfreq       float        110.0           \
The initial line frequency in GHz.\n\
  iffreq         Iffreq         float        150.0           \
The initial IF frequency in MHz.\n\
  restfqs        Restfqs        16xfloat     <NONE>          \
The initial rest frequencies for each window in GHz.\n\
  vlsr           Vlsr           float        0.0             \
The initial velocity to be used for doppler corrections in km/s.\n\
  cormode        Cormode        int          8               \
The initial correlator mode [1-8].\n\
  usb            Usb            Boolean      True            \
Set to True if the restfreq is initially in the upper sideband;\n\
                                                             \
False for lower sideband.  This may also be set by including the\n\
                                                             \
sign [+-] when specifying the resource 'iffreq'.\n\
  coropt         Coropt         int          0               \
Set to 0 if the initial option is cross correlation mode; 1 for auto.\n\
  corbw          Corbw          4xfloat      100,100,100,100 \
Specifies an array of 4 bandwidths in MHz.\n\
  corf           Corf           4xfloat      200,400,600,800 \
Specifies an array of 4 corf frequencies in MHz.\n\
  birdie         Birdie         int,Yxfloat  <NONE>          \
Specifies a count followed by count birdie frequencies in MHz.\n\
  setupFile      SetupFile      String       <NONE>          \
The name of initial setup file.  Both 'setupFile' and 'setupName'\n\
                                                             \
must be specified in order for this resource to be loaded.\n\
  setupName      SetupName      String       <NONE>          \
The name of initial setup entry.  Both 'setupFile' and 'setupName'\n\
                                                             \
must be specified in order for this resource to be loaded.\n\
  undefinedColor UndefinedColor String       yellow          \
Specifies the color of undefined molecular lines.  If a line\n\
                                                             \
does not have a name associated with it, the line will be\n\
                                                             \
drawn with this color.\n\
  noFluxColor    NoFluxColor    String       orange          \
Color of molecular lines without known fluxes.  If a line\n\
                                                             \
does not have an intensity associated with it, it is drawn\n\
                                                             \
with this color.\n\
  restfqsColor   RestfqsColor   String       green           \
Color of restfqs lines drawn in the channel plots.\n\
  birdieColor    BirdieColor    String       blue            \
Color of the location of the user specified birdies.\n\
  debug          Debug          int          0               \
Used to set the initial debug state.  Setting this to 0 turns off\n\
                                                             \
messages; 1 provides many messages; and 2 is at a programmer level.\n\
  fmin           Fmin           float        67.7            \
The minimum allowed frequency for main slider ruler in GHz.\n\
  fmax           Fmax           float        120.3           \
The maximum allowed frequency for main slider ruler in GHz.\n\
  rulerwidth     Rulerwidth     float        10.0            \
Sets the initial frequency width for the main slider ruler in GHz.\n\
  rulerFont      Font           String       XtDefaultFont   \
Sets the font for main slider ruler.\n\
  usbRulerFont   Font           String       XtDefaultFont   \
Sets the font for upper sideband rulers.\n\
  usbDrawFont    Font           String       XtDefaultFont   \
Sets the font for upper sideband drawing area.\n\
  lsbRulerFont   Font           String       XtDefaultFont   \
Sets the font for lower sideband rulers.\n\
  lsbDrawFont    Font           String       XtDefaultFont   \
Sets the font for lower sideband drawing area.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPCMDLINE].widget = (Widget)NULL;
    helpList[HELPCMDLINE].title = XmStringCreateLtoR("Command Line Options",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPCMDLINE].msg = XmStringCreateLtoR("\
Many of the application resources may be entered directly on the command\n\
line.  The resources that may be set and their syntax are presented in\n\
the following table.\n\n\
                         Command Line Arguments\n\
------------------------------------------------------------------------\n\
  Argument        Resource(s) Set   Example\n\
------------------------------------------------------------------------\n\
  -1mm            fmin,fmax,freq -1mm; (Sets resources for 1mm lines)\n\
  -icongeometry   iconGeometry   -icongeometry -128+0\n\
  -iconGeometry   iconGeometry   -iconGeometry +128-0\n\
  -ig             iconGeometry   -ig -0-0\n\
  in=             infile         in=$MIRCAT/recom.lis\n\
  infile=         infile         infile=$MIRCAT/lovas3mm.dat\n\
  freq=           restfreq       freq=115.27\n\
  restfreq=       restfreq       restfreq=86.7\n\
  iffreq=         iffreq         iffreq=-200\n\
  restfqs=        restfqs        restfqs=113.25,,,,117.35,,,,\n\
  vlsr=           vlsr           vlsr=50\n\
  cormode=        cormode        cormode=7\n\
  coropt=         coropt         coropt=0\n\
  corf=           corf           corf=225,225,500,500\n\
  corbw=          corbw          corbw=25,100,100,100\n\
  setup=          setupFile      setup=mysetupfile\n\
  name=           setupName      name=corfsetup\n\
  birdie=         birdie         birdie=3,630,710,750\n\
  -usb            usb            -usb   (Sets usb resource to True)\n\
  -lsb            usb            -lsb   (Sets usb resource to False)\n\
  -debug          debug          -debug (Sets debug resource to 1)\n\
  -Debug          debug          -debug (Sets debug resource to 2)\n\
------------------------------------------------------------------------",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPSLIDER].widget = (Widget)NULL;
    helpList[HELPSLIDER].title = XmStringCreateLtoR("Command Window Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPSLIDER].msg = XmStringCreateLtoR("\
The Command Window contains several items which are used to control\n\
the location of the first local oscillator (LO1).\n\n\
Across the top of the window are input items which allow the user to\n\
input the frequency of the line (in GHz) and the IF (in MHz).  If the\n\
IF frequency is input negative, the absolute value will be displayed\n\
and the sideband toggle will be switched to the lower sideband (LSB).\n\
Which sideband the line appears in may be toggled independently by\n\
choosing either the upper (USB) or the lower (LSB) sideband button.\n\
The VLSR window permits the user to specify the velocity (in km/s)\n\
to be used for doppler corrections.\n\n\
The ruler window contains two arrow buttons and a slider.  The arrow\n\
buttons control the dynamic range of the ruler enabling various ranges\n\
of the frequency space to be explored.  The slider provides a way to\n\
dynamically adjust the position of the LO1.  The slider is drawn to\n\
illustrate where the lower and upper sidebands are relative to the\n\
LO1 (center line).  Use the mouse (with the first button pressed) to\n\
drag this slider across the ruler.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPCORF].widget = (Widget)NULL;
    helpList[HELPCORF].title = XmStringCreateLtoR("Corf Window Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPCORF].msg = XmStringCreateLtoR("\
The Correlator (Corf) Windows can be separated into three regions.\n\
The middle area has controls that enable the user to select different\n\
correlator modes; to decide whether the correlator should be set in\n\
cross- or auto-correlation mode; and to select the bandwidth and the\n\
frequency for each available corf.  On either side of this control\n\
window are two graphical areas which display the current lower (left\n\
side) and upper (right side) sideband frequency distribution along\n\
with the current position of each of the available corfs.  Depending\n\
on the mode selected, some corfs may be unavailable for adjustment or\n\
display.  The vertical rulers identify the corf frequency (IF or\n\
third LO) scale.  The length of the individual corfs reflects the\n\
current bandwidth (due to the range of frequencies available for the\n\
corfs in these windows, some smaller bandwidths may 'appear' to be\n\
the same size).\n\n\
The correlator mode may be selected by clicking (with the first mouse\n\
button) on the desired mode number; likewise for the correlator option.\n\n\
If a corf is available (not shaded), then a bandwidth may be selected\n\
by clicking on a choice for that particular corf.  If a choice is\n\
shaded, it is unavailable in the current mode.\n\n\
The corf frequency may be set in several ways.  The easiest way is to\n\
just drag the slider using the mouse (with the first button held down).\n\
Note that the corf frequency value above the corf slider changes as\n\
the slider moves and the drawn corfs in the lower and upper sideband\n\
windows also move.  The other way to adjust the corf frequency is to\n\
use the arrow buttons on the keyboard.  Each button press moves the\n\
corf by about 6 kHz.  If the Control key is also held down when the\n\
arrow key is pressed, the corf moves by 6.25 MHz (this performs the\n\
same action as clicking the mouse in the window of the corf scale but\n\
not on the actual scale button itself).\n\n\
The velocity range and resolution (both in km/s) are presented below\n\
each of the bandwidth selectors.  If a mode is chosen that only has\n\
one window associated with the corf frequency, then only one value is\n\
presented for the range and resolution.  If, however, a mode is chosen\n\
that has two windows associated with a corf, then both ranges and\n\
resolutions will be presented.\n\n\
In some modes, there are two windows associated with one corf.  In\n\
these cases, a line will be drawn in that corf to identify the corf\n\
frequency as well as the bandwidth windows that appear on either side\n\
of that frequency.  This line in the corf drawn will be present in\n\
both the lower and upper sideband windows.\n\n\
The length of the lines drawn for each detected line reflects the\n\
relative strength of the line.  If birdie frequencies have been given\n\
on the command line or through application resources, these will be\n\
drawn in a distinct color and with dashed lines.  Unidentified lines\n\
and lines without strength information are also drawn with colors\n\
different than the known lines (see the help page on the application\n\
resources to see how to specify colors for these lines).",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPCHANS].widget = (Widget)NULL;
    helpList[HELPCHANS].title = XmStringCreateLtoR("Channel Window Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPCHANS].msg = XmStringCreateLtoR("\
The channel windows for each sideband are displayed at the bottom of\n\
the application.  The channel window for the lower sideband is shown on\n\
the left and upper sideband on the right.  Vertical rulers are present\n\
in each window to identify individual channel numbers.  Black dashed\n\
lines represent divisions between individual mode windows (remember\n\
the current mode specifies the number of windows in each sideband).\n\
Currently, in cross correlation mode, up to 8 windows may be present\n\
in each sideband.  In auto correlation mode, there may also be up to\n\
8 windows present but there is no distinction between lower and upper\n\
sidebands.  In other words, the lower and upper sidebands are folded\n\
on top of each other.  The lines are presented as in the Corf Windows\n\
and are presented here to provide a more detailed view of the contents\n\
of the individual corf windows.\n\n\
Rest frequencies for each window (and sideband) may be selected by\n\
clicking with the first mouse button on the desired molecular line for\n\
that window.  To de-select a previously chosen rest frequency, click\n\
again on the line but with the third mouse button.  An algorithm finds\n\
the nearest matching line and assigns that frequency to the 'restfqs'\n\
entry for that window.  The selected 'restfqs' entry is identified by\n\
a (green initially) dashed line.\n\n\
There is also a way to manually set each window's rest frequency; see\n\
the Rest Frequency selection under the Option Pulldown Menu.\n\n\
NOTE: Changing the mode or correlator option may produce incorrect\n\
'restfqs' entries; it is best to set the rest frequencies AFTER the\n\
mode and correlator option are selected.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPMISC].widget = (Widget)NULL;
    helpList[HELPMISC].title = XmStringCreateLtoR("Additional Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPMISC].msg = XmStringCreateLtoR("\
Doppler tracking is always applied to the corfs and the lines displayed\n\
in the corf and channel windows of XCORF.  As with the BIMA software,\n\
the correction is applied to the data so terms like the line frequency\n\
and corf frequencies can be input in the rest frame.\n\n\
When the user specifies a Vlsr, the doppler correction is applied to\n\
the drawing of the lines, the corf positions, and the channel plots.\n\
The correction is applied as at the observatory; namely:\n\
                doppler correction = 1 - v/c\n\
Note that for VERY HIGH VELOCITY sources (> 1000 km/s), the velocity\n\
the user should input is not the Vlsr but rather the velocity derived\n\
from applying the above correction to the correct form.  Also, note\n\
that the radio form ([nu - nu0] / nu0) is used; so that cz values\n\
derived from the optical form (ie. [lambda - lambda0] / lambda0)\n\
should be converted.",
      XmSTRING_DEFAULT_CHARSET);

    /* Generate the help message and title for the input file popup. */

    helpList[HELPINFILES].widget = (Widget)NULL;
    helpList[HELPINFILES].title = XmStringCreateLtoR("File Read Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPINFILES].msg = XmStringCreateLtoR("\
To select a file for reading, use the directory entries (left list) to\n\
move into the desired directory.  With each directory selection (you\n\
may select a directory entry by either double clicking on an entry\n\
in the directory list; by single clicking an entry and then pressing\n\
the Filter button; or by typing a path directly into the Filter entry),\n\
the contents of the Files list (the right list) will be updated.\n\n\
Once in the directory of choice, a file may be selected from the file\n\
list (here, a double click is the same as a single click followed by\n\
pressing the OK button) or by directly typing the name into the\n\
Selection entry.  File selection may be terminated at any time by\n\
pressing the Cancel button.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPOUTFILES].widget = (Widget)NULL;
    helpList[HELPOUTFILES].title = XmStringCreateLtoR("File Write Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPOUTFILES].msg = XmStringCreateLtoR("\
To select a file for writing, use the directory entries (left list) to\n\
move into the desired directory.  With each directory selection (you\n\
may select a directory entry by either double clicking on an entry\n\
in the directory list; by single clicking an entry and then pressing\n\
the Filter button; or by typing a path directly into the Filter entry),\n\
the contents of the Files list (the right list) will be updated.\n\n\
Once in the directory of choice, a file may be selected from the file\n\
list (here, a double click is the same as a single click followed by\n\
pressing the OK button) or by directly typing the name into the\n\
Selection entry.  File selection may be terminated at any time by\n\
pressing the Cancel button.\n\n\
After this file name is assigned, the user will be prompted for the\n\
name of the setup to associated with this configuration.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPSETUP].widget = (Widget)NULL;
    helpList[HELPSETUP].title = XmStringCreateLtoR("Setup Selection Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPSETUP].msg = XmStringCreateLtoR("\
This window allows the user to select the name of a setup entry.\n\n\
If the file is to be read, only the setup associated with the name=\n\
keyword will be loaded (a blank string here loads all setups!).\n\n\
If the file is to be written, a setup name is required and will\n\
be the name assigned to the name= keyword.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPINCORF].widget = (Widget)NULL;
    helpList[HELPINCORF].title = XmStringCreateLtoR("Corf Input Selection Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPINCORF].msg = XmStringCreateLtoR("\
This window permits the user to input a specific correlator frequency\n\
value for this corf.  The corf value must be entered in MHz.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPMODE].widget = (Widget)NULL;
    helpList[HELPMODE].title = XmStringCreateLtoR("Mode Help",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPMODE].msg = XmStringCreateLtoR("\
The mode determines the correlator configuration and number of spectral\n\
windows.  The following table gives the bandwidth and the number of\n\
channels in each correlator window for cross correlation mode (double\n\
the number of channels for the auto correlation modes but note the lower\n\
and upper sidebands are no longer distinct).  A dash indicates a window\n\
that is not available in that mode.  A bandwidth of 50 or 100 MHz will\n\
will reduce the number of channels in a window by a factor 2 or 4,\n\
respectively.  These same windows are repeated in the lower and upper\n\
sideband of the first LO.\n\n\
                            Correlator Modes\n\
------------------------------------------------------------------------\n\
            Corf1           Corf2            Corf3         Corf4\n\
  Mode   lsb1   usb1     lsb2   usb2      lsb3   usb3   lsb4   usb4\n\
------------------------------------------------------------------------\n\
    1   bw1/1024 -        -     -          -      -      -      -\n\
    2   bw1/512  -        -    bw2/512     -      -      -      -\n\
    3   bw1/512  -        -    bw2/256     -      -      -     bw4/256\n\
    4   bw1/256  -        -    bw2/256  bw3/256   -      -     bw4/256\n\
    5   bw1/512  -      100/32 100/32      -      -     100/32 100/32\n\
    6   bw1/256  -      100/32 100/32   bw3/256   -     100/32 100/32\n\
    7    25/256  -      100/32 100/32   100/32  100/32  100/32 100/32\n\
    8  *bw1/128 100/32  100/32 100/32   100/32  100/32  100/32 100/32\n\
------------------------------------------------------------------------\n\
* If mode is 8, the first bandwidth is restricted to 25, 50, or 100 MHz.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPEXAMPLE].widget = (Widget)NULL;
    helpList[HELPEXAMPLE].title = XmStringCreateLtoR("Example Window",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPEXAMPLE].msg = XmStringCreateLtoR("\
The following is a list of the steps a user might generally follow to\n\
set up the correlator using XCORF:\n\n\
  1. Enter the VLSR of the doppler source to be used.  This is done by\n\
     typing a value in the VLSR input window.\n\
  2. Select a initial sideband where the reference line should appear.\n\
     This can be done by toggling the USB/LSB buttons.  This can also\n\
     be modified later as well.\n\
  3. Enter a reference line frequency.  This can be done directly by\n\
     typing a value in the Line Freq. input window or by sliding the\n\
     main ruler bar with the mouse.\n\
  4. Adjust the IF frequency to fine tune the location of the reference\n\
     line within the chosen sideband.  This is done via the IF input\n\
     window.  In general this will not be necessary to do since sliding\n\
     the main ruler can accomplish the same thing.\n\
  5. Select a mode from the choices and then adjust the individual\n\
     correlator bandwidths and frequencies to include the lines of\n\
     interest.  Remember that molecular lines should not be positioned\n\
     so that they reside on the dashed lines in the channel windows.\n\
  6. Select the Write option under the File pulldown menu to save this\n\
     configuration as a setup command.\n\n\
  What follows is a more detailed description of the steps listed above\n\
along with some realistic examples.\n\n\
  Suppose you want to observe a source (with a VLSR of 100 km/s)\n\
at the J = 1 - 0 transition of 13CO.  Since 13CO has a rest frequency\n\
of 110.201 GHz, one could either type in the line frequency in the\n\
upper left input box or slide the ruler slider until either the lower\n\
or upper sideband window included the proper frequency.  For this example,\n\
type in 110.1 GHz in the Line Frequency input window.  Note that\n\
after hitting return, the slider moved and the corresponding upper and\n\
lower sideband displays changed accordingly.\n\n\
  When the application is started, it has default settings such that\n\
the upper sideband is selected (see the toggle buttons at the top of\n\
the display) and the IF frequency is set to 150 MHz.  Also, no velocity\n\
is assigned to the VLSR input window.  In our example, the source we\n\
will be using for doppler tracking has a VLSR of 100 km/s.  Enter 100\n\
in the VLSR window (you might need to click the mouse in the input\n\
window to get the application focus there).  When that number is\n\
entered you might see the lines move as the screen refreshes.  This is\n\
because the doppler correction is being applied so the corfs will see\n\
the same frequency range as will be present from the emission from a\n\
doppler shifted source.\n\n\
  At this point, you should see that the 13CO line is present in the\n\
upper sideband display (right drawing window) around 240 MHz.  Note\n\
that there are lines drawn in different colors (each color is an\n\
application resource that can be defined by the user and, hence, might\n\
be different).  Using the default colors, orange lines signify that\n\
an intensity has not been assigned for this transition; yellow lines\n\
indicate unidentified transitions; and black lines represent known\n\
transitions with known intensities and the length of the line is\n\
indicative of the relative strength of the line.  Finally blue dashed\n\
lines represent the location of user specified birdies.\n\n\
  The main ruler slider can be dragged by the pressing the mouse button\n\
over it and then sliding it left or right.  This will affect which\n\
lines are present in the upper and lower sideband.  Also, toggling the\n\
sideband button at the top will flip, in this example, the 13CO line\n\
back and forth between the lower and upper sideband.  By toggling this\n\
button, note that different lines appear in the opposite sideband.\n\
This method may be important when selecting lines and deciding in which\n\
sideband the main line frequency should appear.\n\n\
  Returning to our example, press the upper sideband toggle and enter\n\
110.1 GHz in the Line Frequency input window.  Note that in the\n\
sideband windows, the corfs are also drawn to indicate where the\n\
molecular lines fall relative to the individual correlator frequencies.\n\
Selecting a new correlator mode, changing a bandwidth, or chosing a\n\
new correlator frequency (corf) will affect which corfs are displayed\n\
and where they will appear in both the upper and lower sidebands.  In\n\
this example, 13CO appears in the upper sideband and the first corf\n\
is positioned to see this line.\n\n\
  Suppose the observer would like to be able to also see the CH3SH line\n\
in the same corf but in the lower sideband?  In this case, the corf\n\
frequency needs to be decreased just a bit.  Clicking and dragging the\n\
mouse button on the first corf slider (in the middle of the screen)\n\
will permit the first corf's value to be dynamically adjusted.  Because\n\
the acceptable corf frequency range is between 90 and 900 MHz, the\n\
minimum corf frequency allowed in this mode will be about 170 MHz.\n\
Trying to slide below that value will result in a warning from the\n\
program.  Setting the corf frequency to about 170 MHz will cause\n\
CH3SH to appear around channel 10 and 13CO to appear near channel 310\n\
(see the bottom windows which represent the lower and upper sideband\n\
distributions in channel space).\n\n\
  Setting the second corf frequency to 430 MHz will illustrate how\n\
multiple lines in both sidebands can be observed.  It is a good idea to\n\
avoid having lines reside on the dashed lines in the channel plot.\n\
These are window boundaries and will generally produce poor data.\n\n\
  As another example, suppose an observer would like to observe 13CO\n\
with 2 km/s resolution and at least 100 km/s bandwidth coverage.  Since\n\
delta_f/f = delta_V/C and f = 110.1 GHz, a delta_V of 100 km/s suggests\n\
that delta_f should be at least 36.8 MHz.  Because the bandwidths step\n\
in powers of 2 from 6.25 MHz, this implies that a bandwidth of either\n\
50 or 100 MHz is necessary.  To get 2 km/s resolution per channel with\n\
a 100 MHz bandwidth, a window with at least 64 channels is needed (for\n\
a bandwidth of 50 MHz, at least 128 channels are needed).  However,\n\
because the data is automatically run through a Hanning smooth\n\
algorithm, the number of channels needed really should be doubled.  By\n\
comparing the number of channels available for each corf in each mode\n\
(a description of modes and the corresponding number of channels can be\n\
found by clicking the mouse over the Help pulldown menu in the upper\n\
right hand corner of the application and then sliding down and\n\
releasing the mouse button over the entry called Mode Settings), the\n\
mode that will provide the desired resolution can be found.  For this\n\
example, a 2 km/s resolution with at least 100 km/s coverage is only\n\
available in modes 1, 2, 3, and 5.  Which choice for mode and bandwidth\n\
will determine if other lines will also be seen in that window.\n\n\
  If a per channel resolution of 1 km/s is desired, then (with the\n\
doubling due to the Hanning smooth) at least 256 channels are needed\n\
(512 channels for 50 MHz).  In this case, it means that only mode 1\n\
will do.\n\n\
  As an exercise, find out how to observe the (J = 1- 0) transition of\n\
both 13CO and C18O simultaneously in the upper sideband (Hint: C18O has\n\
a line frequency about 400 MHz less then 13CO).",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPDRAWING].widget = (Widget)NULL;
    helpList[HELPDRAWING].title = XmStringCreateLtoR("Corf Drawing Window",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPDRAWING].msg = XmStringCreateLtoR("\
The windows marked with bw1, bw2, bw3, and bw4 in the figure below may\n\
have the bandwidth values listed in the following table.  The number of\n\
channels available in a given window depends on the degree of multiplexing;\n\
the multiplexing is parameterized here by the variable m.  See the figure\n\
below of correlator modes for how the number of channels in some windows\n\
depends on the value of m.  NOTE: bw1 and bw3 should have the same value\n\
of multiplexing and bw2 and bw4 should have the same value of multiplexing.\n\n\
                bw(MHz)      m\n\
                --------------\n\
                6.25         1\n\
                12.5         1\n\
                25           1\n\
                50           2\n\
                100          4\n\n\
Those windows with the CORF (third LO) shown centered in a fixed 200 MHz\n\
bandwidth (e.g. cormode=5, CORF2) utilize both the upper and lower sidebands\n\
of that CORF.  The user is restricted to using the 100 MHz immediately\n\
above and below that CORF.  However, the data for the two CORF sidebands\n\
are written to two separate 100 MHz windows.  Note that the number of\n\
windows for a given mode is therefore the same as the mode number.  This\n\
point also applies in mode 8 to CORF1 where the bandwidth of the lower\n\
side band of CORF1 is allowed to vary.\n\n\
Mode 1                                  bw1 \n\
        ---------------------------------------------------------------|\n\
        |                           1024/m ch                          |\n\
        |                                                              |\n\
                                                                   CORF1\n\n\
Mode 2                  bw1                              bw2\n\
        -------------------------------|   |----------------------------\n\
        |             512/m ch         |   |         512/m ch          |\n\
        |                              |   |                           |\n\
                                   CORF1   CORF2\n\n\
Mode 3                  bw1                        bw2             bw4\n\
        -------------------------------|   |------------   |------------\n\
        |             512/m ch         |   |  256/m ch |   |  256/m ch |\n\
        |                              |   |           |   |           |\n\
                                   CORF1   CORF2           CORF4\n\n\
Mode 4      bw1                bw2             bw3             bw4\n\
        ------------|      |------------   ------------|   |------------\n\
        |  256/m ch |      |  256/m ch |   |  256/m ch |   |  256/m ch |\n\
        |           |      |           |   |           |   |           |\n\
                CORF1      CORF2                  CORF3    CORF4\n\n\
Mode 5                bw1                   200 MHz         200 MHz\n\
        -------------------------------|   ----|----       ----|----\n\
        |           512/m ch           |   | 64 ch |       | 64 ch |\n\
        |                              |   |       |       |       |\n\
                                   CORF1     CORF2           CORF4\n\n\
Mode 6      bw1                 200 MHz         bw3         200 MHz\n\
        ------------|          ----|----   ------------|   ----|----\n\
        |  256/m ch |          | 64 ch |   |  256/m ch |   | 64 ch |\n\
        |           |          |       |   |           |   |       |\n\
                CORF1            CORF2             CORF3     CORF4\n\n\
Mode 7      25 MHz              200 MHz     200 MHz         200 MHz\n\
        ------------|          ----|----   ----|----       ----|----\n\
        |   256 ch  |          | 64 ch |   | 64 ch |       | 64 ch |\n\
        |           |          |       |   |       |       |       |\n\
                CORF1            CORF2       CORF3           CORF4\n\n\
Mode 8      bw1**    100 MHz    200 MHz     200 MHz         200 MHz\n\
        ------------|-------   ----|----   ----|----       ----|----\n\
        | 128/m ch   32 ch |   | 64 ch |   | 64 ch |       | 64 ch |\n\
        |                  |   |       |   |       |       |       |\n\
                  CORF1          CORF2       CORF3           CORF4\n\n\
Note: ** In mode 8, bw1 is restricted to values of 25, 50, or 100 MHz.",
      XmSTRING_DEFAULT_CHARSET);

    helpList[HELPRESTFQS].widget = (Widget)NULL;
    helpList[HELPRESTFQS].title = XmStringCreateLtoR("Rest Frequencies Window",
      XmSTRING_DEFAULT_CHARSET);
    helpList[HELPRESTFQS].msg = XmStringCreateLtoR("\
This window permits the user to directly set the rest frequencies\n\
of each window.  Up to 16 rest frequency values may be specified.\n\
In cross correlation mode, the first 8 values represent the first\n\
8 windows in the lower sideband; the second 8, the upper sideband.\n\
Since the mode identifies the number of windows that will be present,\n\
only the first `mode' windows are of use in the lower sideband and\n\
windows 8, 9, ..., 8 + mode - 1, in the upper sideband.  In auto\n\
correlation mode, only the first 8 values are valid (since the lower\n\
and upper sidebands are folded on top of each other).\n\n\
To set the rest frequency for a particular window, select the window\n\
with the first mouse button and then enter a value (or edit the value\n\
if one is already present).  The usual cut and paste features work\n\
to enable a rest frequency to be copied into several other windows\n\
(on some machines, an addition carriage-return (<CR>) may be necessary\n\
to enter the value after being pasted into a window).\n\n\
Rest frequencies may also be set (or unset) by clicking in a window\n\
in the channel display with the first (third) mouse button.  This\n\
method of selection finds the nearest known line (see help on\n\
Channel Windows for more details).\n\n\
To reset all of the rest frequencies to the default value, select\n\
the Reset button.  To close the window, select the Close button.",
      XmSTRING_DEFAULT_CHARSET);

    return;
}

/***********************************************************************/
#ifdef __STDC__
static Widget CreateHelp(Widget parent, HELP *help)
#else
static Widget CreateHelp(parent, help)
Widget parent;
HELP *help;
#endif /*__STDC__*/
{
    Arg args[5];
    Cardinal i;
    Dimension hclose, h20, height, width;
    Widget template, swindow, label;
    XmFontList fontlist;
    XmString close;

    close = XmStringCreateLtoR("Close", XmSTRING_DEFAULT_CHARSET);

    /* Create a Template style MessageBox dialog. */
    i = 0;
    XtSetArg(args[i], XmNdialogTitle,         help->title);  i++;
    XtSetArg(args[i], XmNokLabelString,             close);  i++;
    template = XmCreateTemplateDialog(parent, "helpbox", args, i);

    i = 0;
    XtSetArg (args[i], XmNscrollingPolicy,    XmAUTOMATIC);  i++;
    swindow = XmCreateScrolledWindow(template, "swindow", args, i);
    XtManageChild(swindow);

    i = 0;
    XtSetArg(args[i], XmNalignment, XmALIGNMENT_BEGINNING);  i++;
    XtSetArg(args[i], XmNlabelString,           help->msg);  i++;
    label = XmCreateLabelGadget(swindow, "label", args, i);
    XtManageChild(label);
    /*
     *  Find the width of the longest string in the label and then
     *  assign that to the scrolled window.  Also, find the height
     *  of the assigned text.  If it is greater than 20 lines,
     *  restrict the height to 20 lines and let the user scroll.
     */
    i = 0;
    XtSetArg(args[i], XmNfontList,  &fontlist);  i++;
    XtGetValues(label, args, i);

    width = 40 + XmStringWidth(fontlist, help->msg);
    height = XmStringHeight(fontlist, help->msg);
    hclose = XmStringHeight(fontlist, close);
    height += hclose;                 /* Add one more line to message. */
    h20 = 20 * hclose;
    if (height > h20) height = h20;  /* If more than 20 lines, scroll. */

    i = 0;
    XtSetArg(args[i], XmNwidth,   width);  i++;
    XtSetArg(args[i], XmNheight, height);  i++;
    XtSetValues(swindow, args, i);

    /* Free strings and return MessageBox. */
    if (close != (XmString)NULL) XmStringFree(close);
    if (help->title != (XmString)NULL) XmStringFree(help->title);
    if (help->msg != (XmString)NULL) XmStringFree(help->msg);
    help->msg = help->title = (XmString)NULL;

    return(template);
}

/***********************************************************************/
/* ARGSUSED */
#ifdef __STDC__
void HelpCB(Widget w, XtPointer client_data, XtPointer call_data) 
#else
void HelpCB(w, client_data, call_data) 
Widget w;
XtPointer client_data;
XtPointer call_data;
#endif /*__STDC__*/
{
    int helpItem;
    static Boolean firstTime = True;
    HELP *help;

    if (firstTime == True) {
      firstTime = False;
      initHelpStrings();
    }

    helpItem = (int)client_data;
    if (helpItem < 0) helpItem = 0;
    if (helpItem >= MAXHELPITEMS) helpItem = MAXHELPITEMS - 1;
    help = &helpList[helpItem];

    if (help->widget == (Widget)NULL)
      help->widget = CreateHelp(w, help);

    if (XtIsManaged(help->widget) == False)
      XtManageChild(help->widget);

    return;
}
