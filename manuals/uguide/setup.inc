%% This file is to be included by latex in ug.tex
%
% Setting Up Your Account
%
\mylabel{a:setup}
\myfile{setup.inc}

In this appendix a few examples will be given how to set yourself up
to run the MIRIAD software, assuming it has been installed on your
system. The methods used to setup Miriad for an existing account
may all look different, but in effect are quite similar. Some hide
more details than others, but are somewhat restrictive in other
applications.

\section{Berkeley and Maryland Suns}
\mylabel{a:setup:sun}

To get the definitions needed to run MIRIAD, include the following three lines
in \index{path, search}
your \verb+ ~/.cshrc+ file at the appropriate places:
\begin{verbatim}
    setenv MIR ~mirth
    source $MIR/MIRRC
\end{verbatim}
anywhere in the beginning, and somewhere later where the {\bf PATH} is defined,
modify that path to include the {\tt MIRBIN}  environment variable:
\begin{verbatim}
    set path = (. $MIRBIN ... /usr/local/bin /usr/bin ... )
\end{verbatim}
Once you have done this, enter \verb+source ~/.cshrc+ to invoke your
\index{environment, MIRBIN}
login procedure, this sets up MIRIAD for immediate use (it will be
\index{MIRBIN, environment}
automatically set up for you thereafter every time you log in). 

A few notes on your {\tt path} shell variable:
(1) the exact order of directories in {\tt path}:
{\tt \$MIRBIN} should be in the beginning,
preferably after the dot ({\tt .}), if you have one. Name conflicts could
occur, {\tt restore} being one of them. See also {\it restore(8)} in the
UNIX manual pages.
(2) If you use X-windows, make sure its area is included in your search 
path too.
Its location can be more towards the end of the search {\tt path}. Sometimes
\index{X-windows}
you may find the executables in {\tt /usr/local/bin} (Maryland), or
{\tt /usr/local/bin/X11} (Illinois) or even {\tt /usr/bin/X11}
Consult your local system manager.

\section{Illinois Suns}
\mylabel{a:setup:il}
To get the definitions needed to run MIRIAD, include the following at the
end (or anywhere AFTER the path has been set)
of your \verb+~/.cshrc+ file (note the single backquotes around
{\tt arch}):
\begin{verbatim}
 
     if (`arch` == "sun4" && -e ~miriad/cshrc.nMIRIAD) then
        source ~miriad/cshrc.nMIRIAD
     endif
 
\end{verbatim}
Once you have done this, enter \verb+source ~/.cshrc+ to invoke your
login procedure and to set up MIRIAD for immediate use (it will be
automatically set up for you thereafter every time you log in). 

Location of the X-windows in Illinois is {\tt /usr/local/bin/X11},
make sure it is included in your search path (see previous section).

\section{NCSA Cray2 (UNICOS)}
\mylabel{a:setup:cray}

The setup on the Illinois Cray is similar to the Illinois Suns
(see previous section),
instead add the following three liner
to the end (meaning anywhere after the {\tt path} has been set)
of your {\tt .cshrc} file:
\begin{verbatim}
     if (-e ~u11329/cshrc.nMIRIAD)   then
        source ~u11329/cshrc.nMIRIAD
     endif
\end{verbatim}
Once you have done this, enter \verb+source ~/.cshrc+ to invoke your
login procedure and to set up MIRIAD for immediate use (it will be
automatically set up for you thereafter every time you log in). 

The X11 directory, also to be included in the user's {\tt path} is
{\tt /usr/bin/X11}.

% Because disk quota for permanent files is very small, all MIRIAD executables
% are stored in the \index{CFS, Cray file archive}
% CFS file archive, rather than on local Cray disks. The ``miriad'' front-end
% will automatically retrieve the executables from CFS, if necessary.
% Miriad assumes that the environment
% variable {\tt BINDIR} has been set to the scratch directory used to store
% executables. After setting this, you should invoke the Miriad login
% script, \verb+~u11329/MIRRC+. Thus your \verb+.login+ script would
% typically contain the commands:
% \begin{verbatim}
% 
%     source /usr/local/bin/scratch.csh
%     setenv BINDIR $SCR
%     source ~u11329/MIRRC
% 
% \end{verbatim}
% Once you have done this, enter \verb+source ~/.login+ to invoke your
% login procedure and set up MIRIAD for immediate use (it will be
% automatically set up for you thereafter every time you log in). 
%  
\section{Illinois Convex}

{\it To be filled in}

\section{Australia Convex/Suns}

{\it To be filled in}


\section{RALINT Users on Berkeley VAX (VMS)}
\mylabel{a:setup:vms}

There are name conflicts between some RALINT and MIRIAD tasks. By default,
\index{RALINT, miriad}
RALINT users initially have the RALINT set-up (this is handled by the
normal RALINT login command procedure). To get MIRIAD definitions, give the
command
\begin{verbatim}
     $ miriad
\end{verbatim}
To switch back to RALINT definitions, use
\begin{verbatim}
     $ ralint
\end{verbatim}

