%% This file is to be included by latex in ug.tex
%
% General Task Concepts
%
\mylabel{c:concepts}
\myfile{concepts.inc}

This chapter describes the general concepts of MIRIAD tasks.

\section{Datasets}
\mylabel{s:dataset}

Often documentation refers to MIRIAD ``files'' or ``datasets''; however,
these are in actuality directories ({\it i.e.}, 
the host operating system sees a ``directory'' whenever MIRIAD sees a 
``dataset'').  A MIRIAD dataset
actually contains several kinds of data (called ``items'')
\index{item, definition} used by the MIRIAD tasks 
({\it e.g.}, a history item, an image item, a visdata item etc.).  
The user is insulated from this internal organization and can always 
refer to this set of data as a MIRIAD ``dataset''. There are a few
system utilities to manipulate such {\it item}s. These MIRIAD
programs do not contain any astronomical knowledge. Appendix
\ref{as:tindex} lists them thematically.
Note that a MIRIAD dataset must not exist when created,
although this condition has been relaxed on VMS (see also
Appendix \ref{s:caveats}).


As an example, consider the following session where a test image {\tt gauss},
created with {\tt imgen} \index{imgen} in the previous 
chapter\footnote{Command {\tt imgen out=gauss} for the ones who
forgot what happened in the previous chapter}
\begin{verbatim}
    > itemize in=gauss
    Itemize: version 1.1 4-mar-91
    naxis    = 2
    naxis1   = 256
    naxis2   = 256
    crpix1   = 129
    crpix2   = 129
    cdelt1   = -4.848137e-06
    cdelt2   = 4.848137e-06
    crval1   = 0
    crval2   = 0
    history    (text data, 38 elements)
    image      (real data, 65536 elements)
\end{verbatim}
Notice that MIRIAD tasks always announce their version. The history
of a dataset (implemented by the {\tt history} item) usually
contains the version date's or numbers of programs which acted
upon them. 

Now we will have to show two examples where an operating system
dependent command is used to browse in a dataset.  A VMS case:
\begin{verbatim}
    $ dir/size/date [.gauss]
    Directory BKYAST$DUA0:[MIRTH.PETER.GAUSS]

    HEADER.;2                 1   8-MAR-1991 13:48:03.49
    HEADER.;1                 0   8-MAR-1991 13:48:00.56
    HISTORY.;1                1   8-MAR-1991 13:48:00.86
    IMAGE.;1                513   8-MAR-1991 13:48:01.24

    Total of 4 files, 515 blocks.
\end{verbatim}
and a UNIX case:
\begin{verbatim}
    % ls -l gauss
    total 274
    -rw-r--r--  1 teuben        280 Mar  8 16:49 header
    -rw-r--r--  1 teuben         34 Mar  8 16:49 history
    -rw-r--r--  1 teuben     262148 Mar  8 16:49 image
\end{verbatim}
As an exercise for yourself, look up the documentation
of {\tt itemize} and find out what is in the {\tt history} item. Then,
use the VMS {\tt type} or UNIX {\tt more} utility to look at the
corresponding file. Do the same for the {\tt naxis} 
item\footnote{This is actually a trick question, since {\tt naxis}
is an example of an item that is in the ``{\tt header}'' file, and
hence cannot be simply looked at with system utilities}.

The implementation of datasets as directories does hence complicate
making your own private backups, since your favorite image is not
just a file anymore. 
Either a FITS file has to be written (MIRIAD \index{FITS}
task: {\tt fits}), or host archiving utilities such as \index{archiving}
{\tt BACKUP} 
(VMS\footnote{On VMS one has to be extra careful when different file
versions  exist. The dataset may be corrupted, see Appendix~\ref{s:caveats}})
and {\tt tar} (UNIX) can \index{tar} \index{BACKUP, VMS}
be used. The last two
methods are to be preferred if you stay within MIRIAD, but for
transferring or archiving data the FITS method is normally preferred.

\section{Indirect Parameter Input}
\mylabel{s:atfile}
It is possible that the length of a parameter value can become
large (indeed quite huge). In these cases, it is convenient to store the 
parameter \index{@file} value
in a file and then to use the file name in place of the parameter 
value\footnote{Don't confuse this with a default file, which
contains pairs of ``parameter=value'', one on each line in the file.
See section \ref{s:cmdline}}.

To do this, the file name should be preceeded by an ``at'' sign (\verb+@+).
For example, assuming the file {\tt name}, contains the text
{\tt chicyg} , then
\begin{verbatim}
     > histo in=@name
\end{verbatim}
is equivalent to
\begin{verbatim}
     > histo in=chicyg
\end{verbatim}
These \verb+@+ can be nested, and multiple \verb+@+ files can appear on a
line (separated by commas). Indeed an \verb+@+ file and other parameter
values can be intermixed, separated by commas.

The \verb+@+ file can contain many lines. An end-of-line is treated like
a comma.  

As mentioned before in Section~\ref{s:cmdline}, parameter input can
also be made easier by using the {\tt -f} flag when MIRIAD commands are
given directly from the shell.

\section{UV Linetypes (line=)}
\mylabel{s:line}

MIRIAD uv datasets can consist of spectral and continuum data.
Spectral data is generally narrow band, and the
\index{uv, linetypes} \index{line=}
frequencies \index{linetype, uv}
are defined to high precision. Doppler tracking is generally
employed. Continuum data has a much larger bandwidth, and frequency
tolerances are not as great.``Channel 0'' data is also treated as
``continuum'' data.
 
The uv dataset allows multiple spectral and continuum correlators. The
spectral data is described by a set of ``spectral windows'', each window
consists of a number of channels separated by a single increment in
sky frequency (though this increment can vary with time). The data
provided by the different continuum correlators are often called
``wideband channels'' in MIRIAD documentation.

It is quite common, when analyzing, plotting or mapping visibility data,
that you will want to perform some averaging of the data, and might
wish to examine either the spectral or the continuum data. For the
spectral data, if the channel number does not correspond reasonably directly
with velocity ({\it e.g.}
if doppler tracking was not used), then it might be
desirable to resample the spectral data at equal increments in velocity.
% Additionally phase-only or amplitude-only
% processing may be desired. 
These abilities are provided by the ``linetype'' parameter, usually
implemented as the {\tt line=} keyword in a task.

The linetype parameter consists of a string followed by up to four numbers.
The string can be one of:
\begin{description}
\item[channel] This gives raw or averaged spectral channels. This is
generally the default if spectral data is present.
\index{channel, linetype}
\item[wide] This gives raw or averaged continuum (wide-band) data.
This is the default if only continuum data is present.
\index{wide, linetype}
\item[velocity] This gives spectral data, that has been resampled at equal
increments in velocity. The ``resampling'' operation is a weighted average
of spectral channels. Also the requested velocities are centered in the
sampling bins.
\index{velocity,linetype}
\end{description}

The four numbers that accompany the string give {\it number of channels},
{\it start}, {\it width} and {\it step} parameters. 
For {\bf channel} and {\bf wide} linetypes, the {\it start} parameter is
the first channel to be used. The {\it width} parameter gives the number of
channels to average together, and the {\it step} parameter gives the increment
between channels. For {\bf velocity} linetype, the {\it start}, 
{\it width} and {\it step}
parameters are given in km/s.

For example, giving a linetype of:
\begin{verbatim}
     velocity,10,1.5,1.0,3.0
\end{verbatim}
would return 10 ``velocity'' channels with velocities 
{\bf centered} at 1.5,4.5,7.5,
etc. km/s. Each channel would have a width of 1 km/s. If you use
``velocity'' and have more than one spectral window, you may also
want to use the {\bf window} uv data selection, as described in the
next section.

Some tasks require two linetypes, the first being the linetype of the
data, and the second being the linetype of a single reference channel
(see {\it e.g.} {\tt invert}). \index{invert}

\section{UV Data Selection (select=)}
\mylabel{s:select}
It is common to wish to process only a subset of the possible 
visibility data.
In MIRIAD, the uv data to be selected is usually specified by one
parameter, generally the {\tt select=} keyword is used for this.
This parameter is constructed from
\index{select, uv data selection} \index{select=}
a number of subcommands, each subcommand selecting or rejecting
uv data which satisfies some condition. The subcommands, which can
be abbreviated to uniqueness, are as follows:
\begin{description}
\item[time(t1,t2)] This selects visibilities observed between times
{\tt t1} and {\tt t2}. Times are given in UT. 
The second time ({\tt t2}) is optional.
If missing, it is assumed to be 24 hours after {\tt t1}.

The time is composed of a date and `time-of-day' portions, either of which
can be omitted (but not both at the same time!). When the date is omitted,
then the selection matches data, for the given time-of-day, regardless of
the day. This is most useful for files containing only a single days data.
When the time-of-day is omitted, then 00:00 is assumed.

The times
\index{time, uv select}
{\tt t1} and {\tt t2} are given in the form:
\begin{verbatim}
   yymmmdd.fff
\end{verbatim}
or
\begin{verbatim}
   yymmmdd:hh:mm:ss.s
\end{verbatim}
Here \verb+yy+ is the year, \verb+mmm+ is the first three letters of the
months name, \verb+dd+ is the day of the month, \verb+fff+ is a fraction of
a day, \verb+hh+ is the hour (24 hour clock), \verb+mm+ is the minute, and
\verb+ss.s+ is seconds and fractions of a second.
The `time-of-day' portion can be abbreviated. For
example, the seconds part can be omitted. Indeed (provided a date is given)
the `time-of-day' portion can be totally ommitted if desired.


For example:
\begin{verbatim}
   90jan12:12:30
\end{verbatim}
is 12:30 on 12 January, 1990, whereas
\begin{verbatim}
   78jun03.5
\end{verbatim}
is midday on 3 June, 1978. 

To give some examples:
\begin{verbatim}
   select=time(91jan05:10:50,91jan05:17:20)
\end{verbatim}
will select data observed on 5th January, 1991, between 10:50 UT to 17:20 UT.

The form where no date is given:
\begin{verbatim}
   select=time(10:50,17:20)
\end{verbatim}
will select data observed on any day between 10:50 and 17:20.

To give an example where only one time is given, the following
\begin{verbatim}
   select=time(91jan03)
\end{verbatim}
will select all data observed on 3rd January, 1991. This form is only
useful for a file containing several days of data.

\item[antennae(a1,a2,...)(b1,b2...)] This selects according to the
antennae and baseline. Here {\tt a1,a2,...} is a list of antennae to select.
The second list, {\tt b1,b2,...} is optional. If present, only baselines
corresponding to the antennae pair (a1,b1), (a1,b2), ..., (a2,b1), ..., etc
are selected. For example, to select all visibilities using antennae 1 or 3,
\index{antennae, uv select}
use
\begin{verbatim}
    select=antennae(1,3)
\end{verbatim}
To select all visibilities using baselines with antennae 1 and 2, or 3 and 2,
use
\begin{verbatim}
    select=antennae(1,3)(2)
\end{verbatim}
\item[uvrange(uvmin,uvmax)] This selects visibilities whose uv radius
is in the range {\tt uvmin} to {\tt uvmax}.
If only one value is given, then {\tt uvmin} is
\index{uvrange, uv select}
taken as zero. The units of {\tt uvmin} and {\tt uvmax} are kilowavelengths.
\item[uvnrange(uvmin,uvmax)] This is the same as the {\tt uvrange} subcommand, 
except that the units are nanoseconds.
\item[visibility(n1,n2)] This selects visibilities numbered {\tt n1}
\index{uvnrange, uv select}
to {\tt n2} inclusive.
\item[increment(inc)] This selects only every {\tt inc}'th visibility.
\index{increment, uv select}
\item[dra(p1,p2)] For data files containing several pointing centers, this
selects visibilities whose pointing center is offset, in RA, from the main
\index{dra, uv select}
pointing center, by between {\tt p1} and {\tt p2} arcseconds.
\item[ddec(p1,p2)] For data files containing several pointing centers, this
selects visibilities whose pointing center is offset, in DEC, from the main
\index{ddec, uv select}
pointing center, by between {\tt p1} and {\tt p2} arcseconds.
\item[pointing(p1,p2)] For data files containing rms pointing error data,
this selects visibilities with the rms pointing error in the range {\tt p1}
\index{pointing, uv select}
to {\tt p2} arcseconds. If only one number is given, {\tt p1} is taken as 0.
The rms
pointing error of a visibility is taken as the maximum of the rms azimuth and
rms elevation pointing errors of the two antennae.
\item[amplitude(x,y)] Any correlation, where the amplitude
is between {\tt x} and {\tt y}, is processed. 
If only one value is given, it is assumed to be {\tt x}; and
{\tt y} is assumed to be infinity.
\index{amplitude, uv select}
\item[window(w1,w2,...)] When calculating ``velocity'' linetype, with
data observed by a spectrometer with multiple
\index{window, uv select}
IF bands (``windows''), this selects the IF bands used if calculating the
``velocity'' channels. This subcommand has no effect unless a velocity
linetype is being calculated. For example, to use only the first, second
and fourth ``window'', use:
\begin{verbatim}
    select=window(1,2,4)
\end{verbatim}
\item[on] This is intended for use with single dish observations, and
selects based on the ``on'' variable in the uv dataset. The ``on'' variable
indicates whether the telescope is pointing on or off source.
\index{on, uv select}
\item[polarization(a,b,c,...)] This selects based on the polarization/Stokes
type of the visibility. The possible values for {\tt a,b,c,} etc. are mnemonics
for the polarization type, as discussed in the next section.
\index{polarization, uv select}
\item[or] This parameter is discussed below.
\index{or, uv select}
\end{description}
As noted before, all
subcommand names can be abbreviated to the minimum number of characters
needed to keep them unambiguous (minimum match).

Each subcommand can optionally
be prefixed with a plus or minus sign (\verb|+| or
\verb|-|). A plus sign means to select the data given by the following
subcommand, whereas a minus sign means to discard the data. If neither
a plus nor a minus sign is present, a plus sign is assumed. For example
\begin{verbatim}
    select=uvrange(0,10)
\end{verbatim}
means to select all visibilities between 0 and 10 kilowavelengths, whereas
\begin{verbatim}
    select=-uvrange(0,10)
\end{verbatim}
discards visibilities between 0 and 10 kilowavelengths, but selects all others.

Several subcommands can be combined on the same line, separated by commas.
When combining several subcommands of {\it different} types,
the visibility must be selected by all the
subcommands to be accepted (a logical AND).
When combining several subcommands of
the same type, then the visibility is accepted if it is selected
after sequentially examining each of the subcommands (a logical OR).
For example:
\begin{verbatim}
    select=uvrange(0,10),uvrange(20,30)
\end{verbatim}
selects data with a uv radius in the intervals 0 to 10 kilowavelengths AND
20 to 30 kilowavelengths. The following uses a ``select then discard''
approach to selecting the same uv ranges as above:
\begin{verbatim}
    select=uvrange(0,30),-uvrange(10,20)
\end{verbatim}
The following selects the same uv ranges, but only for the baseline between
antennae 1 and 3.
\begin{verbatim}
    select=uvrange(0,10),uvrange(20,30),antennae(1)(3)
\end{verbatim}
The following selects all baselines, with the exception of 1-2,5-7 and 6-7:
\begin{verbatim}
    select=-antennae(1)(2),-antennae(5,6)(7)
\end{verbatim}

Another way of combining subcommands, is with the ``{\tt or}'' subcommand.
This allows you to OR together two ``clauses'' of selection commands.
For example, to select
IF windows 1 and 2 for the day 0 to 1, and windows 4 and 5 for times
2:00 to 3:00, use:
\begin{verbatim}
    select=time(0:00,1:00),window(1,2),or,time(2:00,3:00),window(4,5)
\end{verbatim}

By combining the various subcommands and the ``or'' subcommand, quite complex
selection criteria can be developed. For complex selections, an
\verb+@+ file (as described in Section~\ref{s:atfile}) may be preferred.

For example, consider a file, {\tt select.data}, containing the text:
\begin{verbatim}
  time(1:00,2:00),window(1,2),or
  time(2:00,3:00),window(1,2),-uvrange(50,100),-antennae(1)(3),or
  time(3:00,4:00),window(1,2,3,4)
\end{verbatim}
Then
\begin{verbatim}
    select=@select.data
\end{verbatim}
will use windows 1 and 2 for time 1:00 to 2:00, and windows 1, 2, 3 and 4 for
times 3:00 to 4:00. For time 2:00 to 3:00, it uses windows 1 and 2, but omits
data for baseline 1-3 which has a uvrange of 50 to 100 kilowavelengths.
\index{or, uv select}


There are some limitations:
\begin{itemize}
\item Some tasks place limitations on using the ``polarization'' form.
See the description on polarization handling below. If ``polarization''
is not allowed, then the ``increment'' (by some arcane quirk) also is not
usable.
\item If a visibility is selected by several clauses (separated by ``or''),
and if these
different clauses contain {\tt window} or {\tt amplitude} subcommands, then
the window or amplitude subcommand that actually gets used with the correlation
data is not defined. For example:
\begin{verbatim}
    select=time(0:00,1:00),window(1,2,3),or,
           time(0:00,2:00),window(4,5,6)
\end{verbatim}
Here the times 0:00 to 1:00 is selected twice, but with different {\tt window}
subcommands. There is no guarantee as to which of the two window subcommands
will be used during this time interval.
\end{itemize}

\section{Polarization/Stokes Handling (stokes= and select=)}
The uv datasets possibly contain correlations for different polarizations
and Stokes parameters. There are two basic ways that polarization
\index{polarization} 
characteristics can be measured: firstly, two orthogonal feeds can be 
present on the \index{stokes}
antennae, and the four different polarization correlations from a baseline can
be taken and recorded. Alternately only one feed may be present, which can
be rotated, or there are not enough correlators to calculate all 4
polarization correlations simultaneously. The first approach allows all
polarization parameters to be measured simultaneously. The second forces
a `time sharing' approach, where the feed or correlated must be switched
between measuring one polarization to another. With the 4 simultaneous
measurements, it is possible to convert a visibility from raw polarization
parameter to Stokes parameter. With the time-shared mode, this is not
directly possible. These two different scenarios mean that two very different
suites of software are needed to obtain Stokes parameters.

In MIRIAD, each different polarization/Stokes measurement is treated as a
separate visibility (this differs from the AIPS approach -- which does
not really support the time-shared approach to polarization measurement).
So if a baseline measures 4 simultaneous polarization correlations, then
4 ``visibilities'' will be produced for this baseline, per integration
interval. In this case, each visibility will be tagged with a uv variable
({\tt pol}) \index{pol, uv variable}
indicating the polarization type.

There are two ways the user can determine which polarizations that he or she
wants to process, either with the `select' parameter, or with the `stokes' 
parameter.

The `select' approach selects visibilities purely on the basis of their
polarization or Stokes parameter.
It is a normal part of the uv selection process, as described in the
previous section. The `select' mechanism cannot
convert from raw polarization parameters to Stokes parameters. It just
selects visibilities, in the file, based on their polarization.
The general form is:
\begin{verbatim}
   select=polarization(a,b,c,...)
\end{verbatim}
where ``\verb+a,b,c+'' etc can be one of the mnemonics 
{\tt i, q, u, v} (for the Stokes parameters), 
{\tt rr, ll, rl, lr } (for the raw circular polarization parameters) and 
{\tt xx, yy, xy and yx} (for the raw linear polarization parameters).

Using the `stokes' approach is superficially similar, in that it causes
only certain polarization/Stokes parameters to be processed. However,
with the `stokes' approach, the software can perform
conversion between raw polarizations and Stokes parameters if required.
It also insists that all the requested polarization/Stokes parameters are
calculable, at a given time, before it will allow any of them to be
processed.
For example, if the user requests Stokes  I and V, and the
data-set contains linear polarization data, then all four of 
{\tt xx, yy, xy} and {\tt yx}
polarizations must be present for I and V to be returned.

The general form of it is:
\begin{verbatim}
  stokes=a,b,c,...
\end{verbatim}
where ``\verb+a,b,c+'' etc, can be one of the mnemonics given above
({\tt i,q,u,v,rr,ll,} etc), as well as the mnemonic {\tt ii}. Here 
{\tt ii} gives
Stokes I parameter, making the assumption that the source is unpolarized.
More particularly {\tt ii} will return a weighted sum of the `parallel hand'
correlations.

The `select' mechanism is usually used for `time-shared' polarization
measurements, whereas the `stokes' mechanism is usually used where there are
simultaneous measurements. However this is not a hard and fast rule.
The two approaches generally cannot be used at the
same time. Some tasks will prohibit the use of the `select'
approach altogether (they will give error messages if you attempt to),
whereas others are more lenient. The rules which determine whether you
can or cannot use the `select' approach are somewhat arcane and can be
file dependent. Check the documentation for each task,
especially if both `select' and `stokes' parameters are present.

\section{Image Region of Interest (region=)}
A number of tasks can process a subset of the pixels in an input
image. Depending on the task, the selected pixels may either be a fairly
arbitrary region, or only a regular subimage of the input image.
\index{region, of interest} This is called a ``region of interest'',
or short: ``region''. 

The task parameters specifying these regions
consist of a combination of subcommands, each giving a subregion,
or specifying the units of the coordinates used in subsequent
commands.
The subregions selected by multiple subcommands are effectively ``OR-ed'
together to form the overall region.
For comparatively simple regions, combining subcommands is quite
adequate. However for complex regions, TV/cursor based programs may be
more convenient in generating the subcommands.

Region specification is composed of one or more of the following subcommands.
Again each subcommand can be abbreviated to uniqueness.
\begin{description}
\item[images(z1,z2)] This selects the image planes {\tt z1} to {\tt z2} 
inclusive.
{\tt z2} is optional, defaulting to the same value as {\tt z1}.
\index{images, region of interest}
\item[boxes(xmin,ymin,xmax,ymax,...)(z1,z2)]
This subcommand selects the pixels within a box whose corners are
xmin,ymin,xmax and ymax. Multiple boxes can be
\index{boxes, region of interest}
given within the one command. {\tt z1} and {\tt z2} are the same as in 
the ``image''
subcommand. If the \verb+(z1,z2)+ part is missing, a default is used (generally
all planes are selected).
\item[polygon(x0,y0,x1,y1,x2,y2,...)(z1,z2)]
This gives the vertices of a
polygon. Box(xmin,ymin,xmax,ymax) is equivalent
\index{polygon, region of interest}
to\newline
poly(xmin,ymin,xmax,ymin,xmax,ymax,xmin,ymax). {\tt z1} and {\tt z2}
are the same as with
the ``images'' and ``boxes'' subcommands.
\item[mask(name)]
This selects pixels according to the mask given by the mask item
\index{mask, region of interest} in the
dataset {\tt name}.
\end{description}

The units used for the coordinates are controlled by the following
subcommands:
\begin{description}
\item[abspixel] Subsequent coordinates are given as absolute pixel values
(i.e. values ranging from 1 to $NAXISi$ - see {\tt imlist} or
{\tt itemize})
This affects image coordinates and
the coordinates along the third dimension. This is also the default.
\index{abspixel, image coordinate units}
\item[relpixel] Subsequent image coordinates are relative to the reference
pixel, as defined by the header of the map of interest. Use
\index{imlist}
{\tt imlist} or {\tt itemize} to find out where the reference pixel is
({\it CRPIXi}).
\index{relpixel, image coordinate units}
\item[arcsec] Subsequent image coordinates are given in arcseconds, and
are relative to the reference pixel of the map of interest.
\index{arcsec, image coordinate units}
\item[kms] Subsequent coordinates in the third dimension are given in
km/s.
\index{kms, image coordinate units}
\end{description}

For example, to specify a $21\times21$ region, centered on the reference
pixel, use:
\begin{verbatim}
  region=relpix,box(-10,-10,10,10)
\end{verbatim}
or to give a $10\times10$ region in the lower left corner of the image,
use
\begin{verbatim}
  region=box(1,1,10,10)
\end{verbatim}
If there are multiple maps in the file, use 
\begin{verbatim}
  region=box(1,1,10,10)(1,2)
\end{verbatim}
to select the first 2 maps.

The region-of-interest specifications can become
rather involved, when complex regions are used. As with uv data selection,
\verb+@+ files (see Section~\ref{s:atfile}) 
are a convenient way to store these.


There are some warnings for those who got used to the {\tt select=}
uv data selection method:
\begin{itemize}
\item The subcommands of a region of interest are logically
OR'ed together, whereas in the uv data selection it is a logically
AND. For uv ``select''  the
logical OR must be explictly given by use of the
{\tt or} subcommand.
\item The subcommands do not allow a plus or minus prefix, like
	the uv data selection does.
\end{itemize}

\section{TV Devices (server=)}
\mylabel{s:server}
MIRIAD supports a number of TV devices. When initiating a TV-related task,
you will have to specify the output TV device, usually through
the parameter {\tt server=}.
A TV device name is \index{tv, server=} specified by a string of the form:
\begin{verbatim}
      type@device
\end{verbatim}
or
\begin{verbatim}
      type@server
\end{verbatim}
Here ``type'' gives the type of the TV device. Current supported values are
{\tt ivas} (IIS IVAS \index{ivas} display), {\tt ivserve} (IVAS server), 
{\tt msss}\footnote{msss is a clone of the AIPS SSS program. MIRIAD
programs may also happen to work with the original SSS program, but this
is not guaranteed}
(MIRIAD Sun Screen Server) and {\tt ultra} (Ultra Frame buffer).
\index{ultra}
The ``device'' or ``server'' part gives the physical device name, or the host
name of the server, depending the device to be local or remote.

For example to display on the Sun ``rigel'', which is running
the MIRIAD Sun Screen Server, use:
\footnote{make sure {\tt msss} and/or {\tt panel} has been started up!}
\begin{verbatim}
      msss@rigel
\end{verbatim}
To display on the IVAS device IXA0, use:  % =CASTOR, DOES NOT EXIST ANYMORE 
\begin{verbatim}
      ivas@ixa0
\end{verbatim}
To display on the IVAS at Berkeley VAX, use:
\begin{verbatim}
      ivserve@bkyast.berkeley.edu
\end{verbatim}
Currently an {\tt ivas} is available on Berkeley's
BKYIM (device name {\tt iia0:}).
% and Illinois' castor (device name {\tt ixa0:}).   NOT ANYMORE???
The Illinois Cray2 currently supports an Ultra frame buffer (device name
{\tt /dev/ultra}). The IVAS server and Sun Screen Server can be accessed by a
task running on any machine with TCP/IP access to one of the servers
(It is possible that, though a TCP/IP connection is possible, the local
machine will not know the internet address of the server.
In this case, the servers internet address, in dot notation, can be given).
Berkeley's BKYIM
% and Illinois' castor both have   NOT ANYMORE ???
has the IVAS server installed.
{\tt msss} is available on a large number of Suns, and
needs to be started up BEFORE attempting to send
display information to it.  Additionally, when using
{\tt msss}, the Sun console must be running SunView
\index{sunview}
(invoked by entering {\tt suntools} or {\tt sunview} from the \index{suntools}
console).


\section{SunView/Suntools Servers}

Background mode is obtained when a command is followed by an ampersand
(\verb+&+), and allows the user to enter additional commands before the
background command is finished.  For example, to run {\tt msss}
in background \index{msss} mode, enter:
\begin{verbatim}
    % msss &
    % panel &
\end{verbatim}
The {\tt panel} program is only needed for 
\index{panel} certain image display tasks,
such as {\tt tvflag} \index{tvflag, miriad task}.


Virtually all MIRIAD-related programs can be run in background mode (though
there is generally no reason to do so for MIRIAD tasks); those MIRIAD programs
that are BEST run in background mode are
\begin{verbatim}
     msss           (Sun only)
     mirtool        (Sun only)
     panel          (Sun only)
\end{verbatim}

\section{Plot Devices (device=)}
Plot devices are described by the standard PGPLOT plotter specification.
The format is ``filename/devicetype''or ``devicename/devicetype''.
If the filename or
device name contains a slash it should be enclosed in double
quotation marks. Usually there exists a default filename or device
name. The part after the slash gives the plotter device type. This
could be {\it e.g.} ``sun'' for plotting on a SunView window, 
or ``ps'' to make
PostScript output. A ``?'' as device name generates a complete list of
the recognized device types.
Files created for hardcopy devices must be spooled to the printer
separately. The command needed for this is site and device specific.

For example:

\footnotesize\begin{verbatim}
     ?         Interactive help to select any of the available devices
     /tek      Tektronix terminal.
     /retro    VT100 with RETRO graphics card.
 size/sun      Sunview window, with optional ``size'' in inches.
               Example:  ``10x8/sun'' gives a 10 by 8 inch window on Sun
               [Default for ``size'' is 8]
 file/ps       File in Postscipt printer format (landscape).
               [Default for file is pgplot.ps]
 file/vps      File in Postscipt printer format (portrait).
               [Default for file is pgplot.ps]
 file/impress  File for a Imagen printer (landscape).
\end{verbatim}\normalsize

{\it The {\tt /retro} and {\tt /tek4010} devices have some problems
when used interactively - this is currently being looked into}.
