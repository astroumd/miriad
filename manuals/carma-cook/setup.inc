% -*- TeX -*-
%
% Setting Up Your Account
%
\chapter{Setting Up Your Account with Miriad}
\label{app:setup}

Setting up your account to use \miriad\ 
of course varies from system to system.
If in doubt, ask a local miriad user. We will assume you are using the \verb+csh+
shell. For {\tt bash}, just replace {\tt .csh} with {\tt .sh}.

Typically you will need to know where MIRIAD is stored, and then

\begin{verbatim}
   source /somewhere/miriad/miriad_start.csh
\end{verbatim}

If you have installed a binary release, and have not edited the two {\tt miriad\_start.*}
files, please do so.

\section{Site dependent setup}
\subsection{OVRO valley}

\begin{verbatim}
   source /sw/miriad/cvs/miriad_start.csh
\end{verbatim}

\subsection{OVRO cedar flat}

\begin{verbatim}
   source /array/miriad/cvs/miriad_start.csh
\end{verbatim}

\subsection{Berkeley}

\begin{verbatim}
   source ...
\end{verbatim}

\subsection{Caltech}

\begin{verbatim}
   source ...
\end{verbatim}

\subsection{Illinois}

\begin{verbatim}
   source ...
\end{verbatim}

\subsection{Maryland}

Maryland uses mostly Mandrake Linux (10.1  as of this writing) on IA-32
as well as IA-64 type machines. A few
Solaris machines are still present, but Miriad is not actively maintained
on them (though available upon request).

\smallskip

Maryland also uses {\tt astromake}, which allows you to (interactively)
load various packages in your shell. Although this comes with an
obvious flexibility, the danger is that loading packages in
a certain order could render your interactive shell useless,
and loading multiple versions of miriad can make commands from
the older version to peek through  the new one and cause unexpected
result. Use with caution.
Example:
\begin{verbatim}
   % source /n/astromake2/astromake_start
   % astroload -v daily miriad
   % astroload ds9
\end{verbatim}


\section{Installation}

Both binary and source based installs are available for Miriad. For a binary release you will
need to adjust the path to {\tt MIR} in the two {\tt miriad\_start.*} files. There
is a risk of shared library conflicts, in which case you will have to relink
and/or recompile the code. The Miriad website provided more details and instructions
how to do this.

\subsection{Source Installation}


Example of a two liner installation:
\begin{verbatim}
  1% curl ftp://ftp.astro.umd.edu/progs/bima/miriad.tar.gz | tar zxf -
or:
  1% wget -O - ftp://ftp.astro.umd.edu/progs/bima/miriad.tar.gz | tar zxf -

  2% miriad_cvs/install/install.miriad
\end{verbatim}

and a few lines of usage to certify the installation seems ok:

\begin{verbatim}
  3% source miriad_cvs/miriad_start.csh

  4% imgen out=map0
  5% itemize in=map0
  6% cgdisp in=map0 device=/xs
\end{verbatim}

Note that this version of MIRIAD is the development version, and contain CVS administrative
files to allow you to easily update and get the latest fixes.


\subsection{Binary Installation}

We expect to make available binary releases for Linux (32bit and 64bit), MacOSX (ppc and intel)
and Solaris (sol10 w/ gcc, sol10 w/ sunstudio12?). Details will be on the miriad website.
