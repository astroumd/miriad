%% This file is to be included by tex in ug.tex
%
%  Using MIRIAD under UNICOS
%

\mylabel{a:unicos}
Prior to using the Cray for the first time, it is recommended that you
obtain the {\tt NCSA UNICOS Startup Package}.  Information on NCSA
publications can be obtained from the following address:
\begin{verbatim}
 
     Attention:  Documentation Orders
     NCSA
     University of Illinois at Urbana-Champaign
     605 East Springfield Avenue
     Champaign, IL  61820
     (217)244-4130

\end{verbatim}
This note describes use of Miriad on the NCSA UNICOS Cray2. UNICOS is a variant
of System-V UNIX. As such, most of the normal UNIX commands 
({\it e.g.} {\tt ls, cd, pwd, } etc) are available. 
The following assumes that you are using the c-shell.
All files input to tasks must reside on the Cray local disks. Because
disk quotas are small, this means that you will keep data files on a scratch
local disk when they are in use, and in the CFS file archive for permanent
storage.

There are a number of useful utilities kept in the directory
\verb+~u11329/bin+. They are normal
UNIX commands, and work independent of the Miriad environment. Conversely,
though they
provide some conveniences, none are essential for running Mirad If you
wish to use these utilities, you must place \verb+~u11329/bin+ in your
path.

\section{CFS Operations}
Because your permanent disk quota is small (1 Mbyte, or less), you must
always work with your data on a scratch disk. The scratch disks are generally
purged of any files that have not been used for 72 hours, so consequently
a permanent storage area for data is needed. The CFS file archive
provides this.

This describes a simple front-end for use with the CFS archive, making
the necessary commands more flexible and UNIX-like. These differ
from the ``cfs'' command in two basic ways. Firstly the current default
directory is not lost after each command (it is stored in the file
\verb+~/.cfsdir+, which is read by all the commands, and written by the
cd command). Secondly these commands allow the use of wildcards. Many of
the commands have the same name as the equivalent UNIX command, except
that they have ``m'' (for Mass) appended to it.
These commands are:
\begin{description}
\item[check] Checks if files exist locally. If not, get the file from CFS.
\item[get] Get file from CFS.
\item[put] Store file in CFS.
\item[lsm] Directory listing of files.
\item[cdm] Change the default CFS directory.
\item[pwdm] Print working directory.
\item[rmm] Remove files.
\item[mkdirm] Make directories.
\item[rmdirm] Delete directories.
\end{description}

All commands can take the -d switch, which must be used if the file is
in a directory other than the default CFS directory. For example:
\begin{verbatim}

  % get -d /011329/data alpha beta

\end{verbatim}
will retrieve the files {\tt alpha} and {\tt beta} from the CFS 
directory {\tt /011329/data}.

The filenames given to the {\tt ls, check, get, rmdir} and {\tt rm} commands
can include the normal wildcard characters and UNIX regular expressions,
which are used to match with files in CFS.

Remember that the shell
normally replaces wildcards with local filenames. This is good for
the put command, but it needs to be defeated when using wildcards
with other commands. That is, you need to quote or ``escape'' the
wildcard character. For example, to put all local files, matching
\verb+ab*+ into CFS, use:
\begin{verbatim}
     % put ab*
\end{verbatim}
However, to retrieve all these files, one would use:
\begin{verbatim}
     % get ab\*
\end{verbatim}

The cd command and the -d switch understand the normal UNIX use
of .. and \verb+~+.

The above describes the way these CFS commands could be used from the
command like of a standard UNIX shell ({\it e.g.} {\tt csh}) 
or from within the Miriad
front-end. It is also possible to invoke the ``mass'' front-end:
\begin{verbatim}
     % mass
\end{verbatim}
Inside this front-end, characters special to the csh, etc, do not need
to be quoted or escaped. Also inside this front-end, the trailing ``m''
(for Mass) on many of the commands may be omitted.

\section{LPX and PGOUT}
\mylabel{s:lpx}
These print files on the Illinois Astronomy printers. The default printer
is rigel, but use
\begin{verbatim}
     % lpx -castor filenames
\end{verbatim}
to print on castor's \index{castor, illinois vms}
printer. Rigel's \index{rigel, illinois sun}
printer is a postscript printer, and
so postscript files (produced by PGPLOT) can be spooled to it.

\section{MEM}
This is the MicroEmacs editor. \index{mem, emacs}

\section{Typical Mode of Operation}
Typically you will want to save and retrieve you data from CFS with
moderate regularity. Because Miriad files are actually directory
trees, it is rather inconvenient to have to save and store each of the
many files, by hand. The easiest way is to package the directory
tree into a tar file before
placing it in CFS, and unpackage it afterwards. Typically to save
your files, you would use
\begin{verbatim}
    % tar -cf outname innames...
    % cdm dirname
    % put outname
\end{verbatim}
The first command makes a tar file (the UNIX equivalent of a backup save set)
of ``innames'', which can be directories. If ``inname'' is the name of a 
directory, tar saves the directory tree that ``inname'' points to. This is
exactly what is desired when packaging a Miriad data set.
The ``cdm'' (Change Directory Mass) gets you into the correct CFS directory.
The ``put'' command saves the tar file.

To retrieve a file, use:
\begin{verbatim}
  % cdm dirname
  % get outname
  % tar -xf outname
\end{verbatim}
This undoes the process.
