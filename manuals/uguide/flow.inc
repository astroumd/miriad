%% This file is to be included by latex in ug.tex
%
% Chapter:  Data flow
%
\myfile{flow.inc}
\mylabel{c:flow}

For non-BIMA users this  part of the manual
may be of no more use than to skip it. We describe in this
chapter where your Hat Creek data are or may be, or where
you can retrieve them from. In the next chapter data conversion
will be discussed for when your data is not in Miriad format.
This may still be of some use to non-BIMA users.

If you are only concerned with finding out where your Hat Creek data
are, jump to section \ref{s:bkydat} (Berkeley),
\ref{s:illdat} (Illinois) or \ref{s:marydat} (Maryland) now. 


\section{Monitoring Hat Creek (STOCK)}

Although users are not encouraged to do so (increasing the load
of the system too much would jeopardize telescope operations)
it is possible to remotely monitor the operation of the telescopes
and watch the data being gathered.

While the data are being taken, one can run a program, referred to
as  ``stock'', on your workstation, which, 
in real-time and at regular intervals displays
the status of the telescopes with information about ambient
temperature, humidity, wind speed, frequency tuning, phase stability,
etc. 

For this to work a small command file must be started up
on the Hat Creek computer {\tt HAT}, if it has not been done yet.
Normally this has been taken care of.
It is a version of the infamous {\tt DISPLAY} program on the 
{\tt HAT} VAX computer.
\index{DISPLAY}
except it sends the screen output to a file on the Berkeley computer
{\tt BKYAST}, where it can be picked up by a script you run on 
your local workstation.
The Hat Creek version of the program is called {\tt STOCK}, and 
lives in {\tt [DATA.TEUBEN]}.
If you need to run it manually (check with {\tt SHO SYS} or
{\tt SHO QUE}) the following
examples may be helpful:\index{stock} \index{SUBMIT, VMS}
\begin{verbatim}
    $ @[DATA.TEUBEN]STOCK                    (at HAT::)
    $ SUBMIT/NOLOG [DATA.TEUBEN]STOCK        (at HAT::)
\end{verbatim}
To kill a batch job, check with {\tt SHO SYS} what the exact 
process ID number is, and issue {\it e.g.}:
\begin{verbatim}
    $ STOP/ID=116F
\end{verbatim}
or, if you know its batch queue entry (from {\tt SHO QUE}):
\begin{verbatim}
    $ DELETE/ENTRY=134 SYS$BATCH
\end{verbatim}
At your local site the script {\tt stock.csh} can be run,
usually by making an alias:
\begin{verbatim}
    % alias stock $HCRO/stock/stock.csh
\end{verbatim}
This alias is automatically provided, if you opted to add the
Maryland {\bf HCRO} environment, as described somewhere else.
The script {\tt stock.csh} has an optional argument, telling it
the delay in seconds to check at {\tt BKYAST} for the log file.
The default of 20 seconds is more than enough.

\underline{Note:} If you run {\tt stock}, you are adviced to 
resize your window to be about 85 characters wide, and 
40 characters high. Under {\tt suntools} or {\tt sunview}
add the following 
one-line\footnote{the example shows 4 lines, but in the .rootmenu
file it needs to be on 1 line, no backslashes in the file please}
entry to your {\tt .rootmenu} file: \index{rootmenu}
\begin{verbatim}
    "STOCK"    shelltool -Ww 85 -Wh 40 
                -Wt /usr/lib/fonts/fixedwidthfonts/screen.r.10 
                -WL "stock"  -Wl "stock"
                /lma/hcro/stock/stock.csh
\end{verbatim}


Copying files has to be done using DECNET, {\it e.g.} between
\index{copy, DECNET}
Hat Creek and Berkeley one would use:
\begin{verbatim}
    BKYAST$ COPY HAT"DATA RAL"::DU:[DATA]TEST.BCK *
\end{verbatim}
Note the extra security {\tt "DATA RAL"} between the hostname and
the remainder of the command line.

\section{Data in Berkeley}
\mylabel{s:bkydat}
The data is transferred accross a special 
``high speed'' 9600 baud line from the Hat
Creek observatory ({\tt HAT}) to Berkeley ({\tt BKYAST}) 
every morning at 2 a.m. PST.
It will then reside on {\tt BKYAST} within the 
{\tt DATA} account for a limited
amount of time (few hours to few days??) until someone backs it up to
tape over there.  

In the meantime, for remote users, it is possible for us to look at what
is in Berkeley and save a listing in a local file here:

\begin{verbatim}
%               --> ftp bkyast.berkeley.edu
login(...):     --> data
password(...):  --> XXXXXXXX
ftp>            --> dir [...] local-filename
ftp>            --> quit
%               --> grep -i string local-filename
\end{verbatim}

You will now have a file {\tt local-filename} 
which contains a directory listing of all files currently
inside the {\tt DATA} 
account at Berkeley.  If you are currently observing the object NGC 1989,
then use "1989" for {\tt string} and all the appropriate
filenames will appear.  The actual data directory name is 
likely to be something like {\tt N1989COM.DIR}\footnote{The base name
of the directory must end in {\tt M} (for Maryland) or {\tt I} (for
Illinois) for it to be send out. The basename starts with the object
{\tt N1989} in this case, followed by a line-code {\tt CO}, and 
optionally a remote site indication}.

For Maryland, a {\tt Nightly} \index{Nightly} script does all this work
automatically, and puts the information in
files with a name {\tt come-ddmmmyy} and {\tt gone-ddmmmyy};
here {\tt dd} is the day of month,
{\tt mmm} is month name, and {\tt yy} the last two
digits of the decade, {\it e.g.} {\tt come-09nov89}.
The home directory of the Nightly script is {\tt \$HCRO/Nightly}.
\index{Nightly, directory}

\section{Shipping data from Berkeley (SENDOFF)}

A VMS command file {\tt SENDOFF} \index{sendoff} runs every morning
at 7 a.m. PST (10 a.m. EST)
on one of the Berkeley VAXes, and
takes care of automatic transport of data from Berkeley to Maryland
and Illinois.
Each remote site is responsible for maintaining {\tt SENDOFF}. It lives
in {\tt [DATA.COMMAND]}. Shadow copies of relevant files live
in {\tt \$HCRO/bkyast}. \index{BKYAST, shadow files}

Information provided to the command files about the remote site (username,
password, directory to put data into, etc.) reside in files 
in {\tt [DATA.COMMAND]}, see the file {\tt maryland.ftp} or 
{\tt illinois.ftp}.

\section{Getting data from Berkeley}

It is also possible to copy the data yourself, if you're eager to get it, as
long as it resides on {\tt BKYAST}.
The data will eventually be transferred to your local site
automatically, a day or so
later.  You can be notified by mail about this, see Section
\ref{sec-nhc} below for instructions to set yourself up for this.

Here's an example how to get the data from Berkeley yourself. It's 
a two-step process and is
done by creating a VMS BACKUP saveset \index{BACKUP, VMS}
on {\tt BKYAST}, and copying (using {\tt ftp}) this file in binary mode back
to Maryland. An example will clarify this:
\begin{verbatim}
%               --> telnet bkyast.berkeley.edu
Username:       --> DATA
Password:       --> XXXXXXXX
$               --> SET DEF [.YOUR_OBJECT_DIRECTORY]
$               --> BACKUP/BLOCK=2048/LIST *.* TEMP.BCK/SAVE
$               --> LOGOUT
%               --> ftp bkyast.berkeley.edu
login(...):     --> data
password(...):  --> XXXXXXXX
ftp>            --> binary
ftp>            --> hash
ftp>            --> cd [.YOUR_OBJECT_DIRECTORY]
ftp>            --> get TEMP.BCK local-filename
ftp>            --> delete TEMP.BCK;1
ftp>            --> quit
%               --> vmsdisk -tf local-filename
\end{verbatim}

The last command {\tt vmsdisk} will print a listing of the files in 
the backup save-set
{\tt local-filename} \index{vmsdisk}. If the alias
{\tt bdir} has been added to the environment, this can be used to
list the contents of the backup saveset: \index{bdir, vmsdisk}
\begin{verbatim}
    % bdir local-filename
\end{verbatim}

The program {\tt vmsdisk} can also be used to explode 
the BACKUP saveset on a UNIX machine \index{BACKUP, VMS}
into their individual files.

To explode a saveset into their individual files one would normally use:
\begin{verbatim}
    %   vmsdisk -xdvf local-filename
\end{verbatim}
or, if the alias {\tt explode} has been installed: \index{explode, vmsdisk}
\begin{verbatim}
    %   explode local-filename
\end{verbatim}

\index{vmsdisk}
This will also create a directory tree, as it was in the original
VMS saveset. Leave out the {\tt -d} option from {\tt vmsdisk} if
the directory structure is not important and all files can be
dumped in the current directory.

\section{Getting your data from Sun to VAX (VMS)}

\mylabel{s:fixatr}
Reduction of Hat Creek data with {\tt RALINT} \index{RALINT}
has to be done on a VAX (Machine name: {\tt BIMA} in Maryland,
{\tt CASTOR} in Illinois), but is not encouraged: use MIRIAD!!
Support for RALINT may dwindle, and machines on which RALINT
is present may disappear.


If the data was stored as a BACKUP save set on a Sun,
it must be copied (using ftp) in binary mode to a VAX. Once
there, the recordsize of 512 bytes (imposed by ftp) 
has to be reset to the
original 2048 byte blocksize (the smallest blocksize
VMS {\tt BACKUP} can handle). This
can be done using the VMS utility {\tt FIXATR}:
\index{FIXATR} \index{BLOCK}
\begin{verbatim}
    $ FIXATR/RFM=FIX:2048 TEMP.BCK
\end{verbatim}
or by using a homegrown fortran program {\tt BLOCK}.

The following example shows how to copy the data from a Sun
({\tt astro} in this case) to a VAX ({\tt BIMA} in this case)
in a safe and sane way:

\begin{verbatim}
%               --> ftp bima.umd.edu
login(...):     --> bima
password(...):  --> XXXXXXXX
ftp>            --> binary
ftp>            --> hash
ftp>            --> cd [.YOUR_DIRECTORY]
ftp>            --> put local-filename TEMP.BCK
ftp>            --> quit
%               --> telnet bima.umd.edu
Username:       --> BIMA
Password:       --> XXXXXXXX
$               --> SET DEF [.YOUR_DIRECTORY]
$               --> FIXATR/RFM=FIX:2048 TEMP.BCK
$               --> BACKUP TEMP.BCK/SAVE [...]
$               --> DELETE TEMP.BCK;*
\end{verbatim}

You now have your data on {\tt BIMA}.  
% Do not leave files sitting in the
% root directory of the BIMA account, {\tt \$DISK1:[BIMA]}, since someone
% is likely to delete them; preferably create a subdirectory with the
% same name as your username on the Sun's.

\section{Data in Maryland}
\mylabel{s:marydat}
The Maryland data on {\tt BKYAST}
\footnote{Dataset with directory basename ending in M, 
{\it i.e.} {\tt [data.*m]*.*}}
are automatically copied every morning
at 10 a.m. EST to {\tt astro} in the form of BACKUP savesets. 
They reside in the directory {\tt /lma/hcro/data}, and have names like
{\tt maryland.date} and {\tt logs.date}.  The {\tt maryland} files contain
the data (currently in VMS RALINT format), and the {\tt logs} files
various log files, which may be of interest to an observer.
The {\tt date} part of the filename is of
the form {\it ddmmmyy}, where {\it dd} is the day number (always 2
digits), {\it mmm} the month name (3 characters, lower case) and {\it
yy} the year (last 2 digits of the year), {\it e.g.}
{\tt maryland.03oct89}. 

You can get listings of the savesets manually as follows:
\index{vmsdisk} \index{bdir, vmsdisk}
\begin{verbatim}
    % cd /lma/hcro/data           or:         % data:
    % vmsdisk -tf maryland.date   or:         % bdir maryland.date
\end{verbatim}

of course this would be very cumbersome to look for data yourself this
way, so after each month has passed a listing file \index{listing,
data files} is created for the data that came in during that previous
month.  Listing files can be found in {\tt /lma/hcro/listings} and
its subdirectories.  
The files {\tt Listing.mmmyy}, where {\tt mmm} is the name of
the month and {\tt yy} the last two digits of the year, contain a backup
saveset listing of all data that \underline{arrived} in Maryland.  At
the end of a month the data for that month are moved into a subdirectory
{\tt /lma/hcro/data/mmm} (where {\tt mmm} is the name of the month), the
listing file {\tt /lma/hcro/listings/Listing.mmmyy} is created, and the
data are backed up to tape whenever the {\tt /lma} disk is threatened to
overflow.  

The data on tape hence have filenames with a construction like
{\tt maryland.23mar90} and {\tt logs.23mar90}. 



If for some reason you suspect that the data didn't make it to 
Maryland (this does happen!) - you need to check the listing files
in the directory\newline
{\tt /lma/hcro/listings/yyyy/mmm} directories 
({\tt yyyy} is the year and {\tt mmm} the month). These listing
files are not created in Maryland, but in Berkeley, and will aid
in retrieving the right tape in Berkeley when data is missing
in Maryland. 

% The script {\tt Findgal} aides in finding information in this Berkeley
% listings subtree. An example of usage:
% \begin{verbatim}
%    % Findgal oph >& oph.lis
%  or
%    % Findgal year 1990 oph >& oph.lis-1990
% \end{verbatim}

Exploding the saveset was discussed in a previous section. 

\section{Data in Illinois}
\mylabel{s:illdat}

Data in Illinois are stored on {\tt CASTOR} under the {\tt RALINT}
account, in directory \newline
{\tt [RALINT.NEWDATA]}. Currently underway is a conversion of
{\tt RALINT} format to {\tt MIRIAD} format.

Much of the comments how to get data from Berkeley with or without
using {\tt BACKUP} has been mentioned in previous sections.

\section{Data archiving and Data retrieval (Maryland)}

Archiving is done by storing the incoming savesets \index{archiving}
as files on a tar tape \index{tar}; 
the UNIX program {\tt tar} has to be used (see: {\it tar(1)})
to manipulate the files on tape: creating, updating, listing
and extracting. For convenience a few shell scripts are (will be)
available to aid in data retrieval.

Here are four examples of how to store, list, and extract savesets to/from tape:
\begin{verbatim}
    % tar cvf /dev/rmt0   file1  ...    # creating new tape
    % tar uvf /dev/rmt0   file1  ...    # update existing tape
    % tar tvf /dev/rmt0                 # listing of tape
    % tar xvf /dev/rmt0  [file1  ...]   # extract [all/selection]
\end{verbatim}
Note that while extracting files you cannot use wildcards!
The name of the tape device is {\tt /dev/rmt0} in this example;
in UNIX this is often the default tape 
device\footnote{Look at the file {\tt /dev/MAKEDEV}, if present,
it usually contains hidden information what the name of the tape
devices are}.

Note that the tar-update option will not work for the {\tt exabyte}
\index{exabyte} tapedrive, as it is a device which cannot rewind.  The
user has to keep track of individual tar sets on the tape, using the
UNIX {\tt mt} command, \index{mt} and the non-rewinding {\tt /dev/rmt5}
device. 

An example: Suppose the exabyte lists that the data for July 1990 is the
third tarfile on on disk, and you want the data and logfiles from July
4th.  The following set of commands should then work: \begin{verbatim}
    % mt -f /dev/rmt5 rewind
    % mt -f /dev/rmt5 fsf 2
    % tar xvf /dev/rmt5 maryland.04jul90 logs.04jul90
\end{verbatim}

The names of the savesets which are stored on the tape can be found in
the directory {\tt /lma/hcro/listings/Tape}. Each tape has it's
contents listed in a file.

\section{Nightly and HCobjects (Maryland)}
\subsection{Presence of your data}
\mylabel{sec-nhc}

There is an automatic nightly script which does most of the work
described in the previous sections, and mails a message to a selective
set of Hat Creek Observers about the status of their data.  In UNIX
terms this is part of the Nightly\index{Nightly}
script, executed by {\tt cron} every
day at noon in Maryland \index{cron} on {\tt astro}. 

For this to operate, your username must be added to the list of users in
the script {\tt /lma/hcro/Nightly/Nightly} and you must create an {\tt
.hcobjects} file in your home directory, with the names of
\index{.hcobjects} the objects (limited to one word per line) you want
to have checked for being observed.  Item 1 has to be done by the lma
software administrator, Item 2 must be done by yourself. 

\subsection{Map making}
After {\tt Nightly} has checked for the existence of incoming data,
it goes off to reduce each dataset. This is done by the script
{\tt Reduce}; it attempts to calibrate,
grid and transform. A logfile, as well as some plots and maps are sent
to the printer. Users are sent mail about this activity whenever their
object is listed in the {\tt .hcobjects} file.

\begin{table}
\centering
\begin{tabular}{|l|l|l|}\hline
Site   & Directory                                  & Programs, Scripts \\ \hline
&& \\
BKY    & [DATA.object]*.*                           & DIR \\
BKY    & [DATA.LISTINGS]ddmmmyyyy.LIS               & SEARCH \\
MD     & /lma/hcro/data/maryland.ddmmmyy            & vmsdisk \\
MD     & /lma/hcro/listings/yyyy/mmm/ddmmmyyyy.lis  & Findgal, grep \\
MD     & /lma/hcro/listings/Listing.mmmyy           & grep \\
MD     & /lma/hcro/Nightly/*/come-ddmmmyy           & grep \\
MD     & /lma/hcro/Nightly/*/gone-ddmmmyy           & grep \\
IL     & [RALINT.NEWDATA]ILLINOIS.ddmmmyy           & BACKUP \\ \hline
\end{tabular}
\caption{Location of Hat Creek Data and Listing Files}
\end{table}

