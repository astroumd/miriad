%% This file is to be included by latex in ug.tex
%
% Chapter:  Map Analysis
%
\mylabel{c:mapana}
\myfile{mapana.inc}

You can do some map analysis inside of MIRIAD, but 
you can also write FITS files and use your other pet 
image processing package. In the latter case be critical
how header variables are copied.

Section \ref{s:anamiriad} details a number of things you can
do with the MIRIAD package. Sections \ref{s:wip} and \ref{s:mxds}
discuss other display and analysis tools which normally come
distributed with MIRIAD.

\section{MIRIAD}
\mylabel{s:anamiriad}

There are already a large number of programs available in MIRIAD to
display and analyze your maps.  \index{image, analysis}
We will just list the most common ones.

{\tt histo} can be used to check on the noise. Programs like
{\tt cgplot} and {\tt implot} make (combined) contour or greyscale
maps of images, whereas {\tt tvdisp} uses the {\tt msss} display 
server to display images in color (see also section~\ref{s:server}).
{\tt imspect} plots a spectrum in a specified region.

\subsection{FITS: import and export}

MIRIAD can also convert its datasets to FITS format, such that you
\index{FITS, image} \index{FITS, uv} can use your own pet image
processing package for the more analysis.  The task {\tt fits} with
{\tt op=xyout} will do this.

\begin{verbatim}
    > fits in=mirmap op=xyout out=fitsmap
    > fits in=fitsmap op=xyin out=mirmap
\end{verbatim}

The second example shows how FITS files can be imported into
MIRIAD, and is ready for further analysis (Please read
the next section in this case first).

\subsection{Initial Header Inspection}


If you imported your image data from outside of MIRIAD, it is highly 
recommended to check the header items if your world 
coordinate system is correct. Otherwise this section can be skipped,
although it is recommended to look at the image header (items)
with programs like {\tt imhead}, {\tt imlist} or even {\tt itemize}.

A list of image items can be found in 
Appendix~\ref{a:image}. The items where most of the problems
occur, and you should check are the following:
\begin{itemize}
\item
The (indexed) items {\tt cdelt}, {\tt crval}, 
{\tt ctype}\footnote{In this context the values of 
the indexed
{\tt crpix} item is probably irrelevant}
and {\tt naxis}, for each relevant axis. You can fix
these with either {\tt puthd} or {\tt mathd}.

\item
Data unit items {\tt bunit}, {\tt datamin} and {\tt datamax}.
These can be easily fixed by running the program {\tt histo},
which automatically find the data minimum and maximum and
fill in the appropriate data items. {\tt bunit} would have
to be added with {\tt puthd}.

\item
Beam smearing items {\tt bmaj}, {\tt bmin} and {\tt bpa}.
When your maps are convolved or smoothed, excersize some
care that these are present, if needed, and that
the units are correct. Relevant programs are
{\tt convol}\index{convol} and {\tt smooth}\index{smooth}.
\end{itemize}

The following examples

\small\begin{verbatim}
    > itemize in=map
    > imhead in=map
    > imlist in=map
\end{verbatim}\normalsize

all display the header items one way or the other.

\subsection{Initial Data Inspection}

Size of the noise can be obtained with {\tt histo}:\index{histo}

\small\begin{verbatim}
    > histo in=map1.c region=arcsec,box(-10,-10,10,10)
\end{verbatim}\normalsize

although an easier way to get statistics on a 
channel-by-channel basis might be {\tt imlist}:

\small\begin{verbatim}
    > imlist in=map1.c options=stat region=@center
\end{verbatim}\normalsize
where an include file {\tt center} has been used to\index{imlist}
replace the long string \newline
{\tt ``arcsec,box(-10,-10,10,10)''}

\subsection{Image Display}

Displaying image data has to be done via the TV server
concept (see Section~\ref{s:server}). The program
{\tt tvdisp} can not only display images, but also
provides an option to run a series of (channel)
maps in sequence as a movie. \index{tvdisp} The program
{\tt views} is useful to prepare a datacube oriented
at arbitrary viewing angle, and processed by
{\tt tvdisp} in movie mode.


\subsection{Plotting}

Contour and greyscale overlay plots can be made with
{\tt cgplot} and {\tt implot}. Spectra at selected
positions with {\tt imspect}.\index{imspect}

\section{WIP}
\mylabel{s:wip}

{\tt wip} is an interactive program\index{wip}
that allows the user, with a
minimum of effort, to produce high quality graphics.
In short, {\tt wip}  is an interactive command interpreter for
the subroutines available in the PGPLOT graphics library.

There are two methods of entering plotting commands to {\tt wip}.
The first (and most common) is to enter interactive mode and
type {\tt wip} commands one at a time.
This method allows the user to type commands and immediately generate
graphics on the chosen device.
As each command is typed, a list of graphics commands is saved in
a command buffer.
This command buffer may be written to an external file for later use.

The second method of entering commands is for the user to input
files into {\tt wip} that contain graphics commands or macro definitions.
These command files are executed by {\tt wip} exactly as if the user
had typed these commands individually.

Currently, {\tt wip} has the ability to read MIRIAD images and
then display grey scales or overlay contours along with
any vector graphics or labeling that may be needed to produce
either quick hardcopies or publication quality output.

As an example of the ease of producing graphics output with {\tt wip},
the following listing are the commands needed to produce a grey
scale of the testimage we created earlier in Section \ref{s:cmdline}.
For reference once more how to create this dataset:\index{imgen}
\begin{verbatim}
    > imgen out=gauss spar=1,10
\end{verbatim}
The following commands can now be given to {\tt wip}:
\begin{verbatim}
    image gauss
    halftone 0 0.5
    levels 0.001 0.01 0.1
    contour
    box bcnstz bcnstzf
    xlabel \ga (1950)
    ylabel \gd (1950)
    move 0 0
    draw -2 60
    putlabel 0 Gauss Center
\end{verbatim}

If the previous commands were saved in the file {\tt plot.pl},
then the command,
\begin{verbatim}
    > wip -Dgauss.ps/vps plot.pl
\end{verbatim}
would generate a file {\tt gauss.ps} 
that could be sent to a postscript\index{postscript}
device. Inside of {\tt wip} the
command {\tt input plot.pl} would have executed the script.

Certain defaults may be set up in a file in your home directory called
{\tt .wipinit}.
Among the defaults that may be specified: a default device specification;
and a default string to use when the BOX command is called without
any arguments.
A typical {\tt .wipinit} file may contain the following lines:

\begin{verbatim}
    device 6x8/sun
    boxdef BCNSTZ
\end{verbatim}

Help on a command may be found by typing ``{\tt help} {\it  cmd}'',
where {\it cmd} is a command name. Minimum match applies, otherwise
the list of possible completions is shown.
Furthermore, a listing and short description of every command may
be found by simply typing {\tt help}.

\section{MXDS}
\mylabel{s:mxds}

Outside of MIRIAD the X-windows-based program {\tt mxds} 
\index{XDS, X-windows} (which supports\index{mxds} both the
Miriad and HDF \index{HDF, format}
data format) can be used for more sophisticated image analysis. 
A separate manual will be available on this shortly.



