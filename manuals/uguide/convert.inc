%% This file is to be included by latex in ug.tex
%
% Chapter:  Data conversion to Miriad format
%
\mylabel{c:convert}
\myfile{convert.inc}

As of this writing the visibility data from the Hat Creek telescopes is
still created in \index{newhat} RALINT 
\footnote{To be more precise: the {\tt newhat} RALINT format;
data taken before Sept 1986(?) is in a slightly different format, 
dubbed the {\tt oldhat} \index{oldhat} format.}
format, \index{RALINT}
and has to be converted to Miriad format. This has to be done
with MIRIAD using either a Sun or VAX, since
machines like the Cray\index{cray} cannot convert RALINT data.

Unfortunately there are two different conversion programs: {\tt uvhat}
for VMS and UNIX and {\tt hcconv} for UNIX\footnote{Actually Sun UNIX
is meant here} only, as summarized in \index{SOLARM} 
Table~\ref{t:conversion} below.
\begin{table}[h]
\centering
\caption{Visibility data conversion programs}
\mylabel{t:conversion}
\medskip
\begin{tabular}{|c|c|c|}\hline
        & UNIX          & VMS \\ \hline
oldhat  & UVHAT         & UVHAT \\
newhat  & HCCONV        & UVHAT \\
uv-fits & FITS          & FITS \\ 
% SOLARM  & SOLCONV       &  - \\        
\hline
\end{tabular}
\end{table}


\section{BACKUP saveset on Sun UNIX (vmsdisk)}

If your RALINT data is still in the form of a BACKUP saveset, it has to be
``exploded'' into their individual RALINT datasets. On the VAX the standard
VMS program BACKUP has to be used, but on a Sun a public domain
utility {\tt vmsdisk} that we supply with MIRIAD will serve
the same function.

You're free to ``explode'' the data any way you want, but
here is a suggested way:
\begin{verbatim}
    % cd your_datareducation_directory
    % explode /lma/hcro/data/maryland.09sep90
\end{verbatim}
{\tt explode} is 
a UNIX alias \index{explode, vmsdisk}
for {\tt vmsdisk -xdvf}, and creates the same directory structure as existed
on VMS.
If you don't like to retain this original VMS directory structure, don't
use the {\tt -d} switch, which is automatically invoked with the alias
{\tt explode}. Use the original command
\begin{verbatim}
    % vmsdisk -xvf /lma/hcro/data/maryland.09sep
\end{verbatim}
instead. All files from all VMS subdirectories are now packed in one (your
current) directory, but be aware of {\bf duplicate filenames}. 

\section{RALINT newhat on Sun UNIX (hcconv)}

To convert all {\tt newhat} RALINT datafiles in the current directory use:
\index{newhat}

\begin{verbatim}
    % hcconv
\end{verbatim}

In this mode, {\it i.e.} when no parameters are given, {\tt hcconv} will 
automatically search for
files of the form {\tt name.ddmmm} and convert them to a Miriad
dataset of the form {\tt name\_ddmmm}.  It excludes files whose names start
with {\tt cbee, notes, log, biglog, baseline} and {\tt watch}.  Watch out for
non-data files which still would be included by this, they need to be
renamed to something that {\tt hcconv} will not mistake for a datafile.

Of course, each file can be converted manually:

\begin{verbatim}
    % hcconv in=junk.02apr out=junk1
\end{verbatim}

There is a third parameter to {\tt hcconv}, {\tt mode=}, which allows
you to select the mode in which the output Miriad dataset name is
derived from its RALINT filename. It is only used when no
output name has been given.

\section{RALINT oldhat on Sun UNIX (uvhat)}

In the rare case that you came accross some very old RALINT data, the UNIX
version of {\tt uvhat} can also convert \index{uvhat, UNIX}
this special case of {\tt oldhat} RALINT datafiles to
proper Miriad datasets.

\begin{verbatim}
    % uvhat in=old.02apr86 out=junk2
\end{verbatim}

As of this writing, this is still rather experimental, and may not
quite work for all ``versions'' of the {\tt oldhat} format. Checking
\index{oldhat}
the created Miriad visibility dataset, {\it e.g.}
using {\tt uvlist}, is strongly \index{uvlist}
recommended. See also Chapter~\ref{c:inspect}. 

Alternatively, you can copy the RALINT files to a VMS site and use the
VMS version of UVHAT \index{uvhat, VMS}
(review Section~\ref{s:fixatr} in case your local site does not have
UVHAT available on VMS) and copy the Miriad data back ({\it cumbersome...}).

\section{RALINT on VMS (uvhat)}

On VMS the MIRIAD program {\tt uvhat} automatically 
detects if a file is in {\tt oldhat}
or {\tt newhat} format, and converts it to MIRIAD format. 
An example:
\begin{verbatim}
    $ uvhat in=junk.02apr out=junk1
\end{verbatim}
{\tt uvhat} has a RALINT-style include file option: if the 
{\tt in=} input file has an extension 
{\tt .inc}\footnote{An old RALINT relic, MIRIAD uses the @file notation
to denote include files, see Section \ref{s:atfile}},
then it can contain directives, explained in
the online help file, which input files
to take and which sub-portions of the data to use. This is the only
way to combine multiple input files into one big output
visibility file. 

\section{UVFITS (fits)}

In principle, but not extensively
tested, uv FITS	files can be used to import as well as export
visibility data to and from Miriad.

The MIRIAD program {\tt fits} can be used to convert a UV FITS file into
MIRIAD format:
\begin{verbatim}
    > fits in=uv.fits op=uvin out=vis1 
\end{verbatim}

The keywords {\tt altr=} and {\tt stokes=} may be of some relevance
here. See the MIRIAD help file for {\tt fits} for more details.


