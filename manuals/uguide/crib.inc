%% This file is to be included by tex in ug.tex
%
% UNIX and VMS crib sheet
%
\myfile{crib.inc}
\mylabel{a:crib}

This Appendix gives the rough equivalents between various 
UNIX \index{UNIX, command summary} and
VMS \index{VMS, command summary} commands.
Please note, UNIX is a case sensitive system, whereas VMS is not. Commands
cannot be abbreviated in UNIX, whereas they can in VMS. More 
information\index{differences, UNIX and VMS}
is available on UNIX, using the {\tt man} command, and on VMS, using the
{\tt help} command. The following assumes use of the {\tt csh} in UNIX.
Note that certain characters in UNIX are expanded by the shell, and
need to be surrounded by single quotes if not to be expanded.

\small

\begin{tabbing}
\null\hskip 1cm\=\hskip 3cm\=\hskip 3cm\= Comments\kill
\>{\large\bf UNIX}\>{\large\bf VMS}\>{\large\bf Comment}\\
{\bf Help}\\ 
\>man\>help\>Help!!\\
{\bf File Manipulation}\\ 
\>cat\>type\>List on terminal.\\
\>more\>type/page\>List with page prompts.\\
\>ls\>dir\>List directory.\\
\>ls -l\>dir/size\>List directory with size\\
\>\>\>(UNIX in bytes, VMS in blocks).\\
\>ls -F\>\>List directory giving file type.\\
\>diff\>diff\>Compare files.\\
\>rm\>delete\>Delete a file.\\
\>rm -r\>\>Delete a directory\\
\>mv\>rename\>Rename a file.\\
\>chmod\>set prot\>Set/change protection.\\
{\bf Directories}\\ 
\>pwd\>show def\>Show current directory.\\
\>mkdir dir\>create/dir [.dir]\>Create a subdirectory named ``dir''.\\
\>cd dir\>set def [.dir]\>Change current directory.\\
\>cd ..\>set def [-]\>Go up one directory level.\\
\>cd ../dir\>set def [-.dir]\>Move sideways.\\
\>pushd and popd\>\>Change current directory.\\
{\bf Process Control}\\ 
\>kill num\>stop/id=num\>Kill a subprocess.\\
\>ctrl/z\>ctrl/y or c\>Suspend command.\\
\>bg \> spawn\> \\
\>fg\>continue\>Resume a task.\\
{\bf General}\\ 
\>who\>show users\>Show current users.\\
\>lpr\>print\>Send a file to the printer.\\
\>echo\>write sys\$output\>Write message on terminal.\\
\>history\>recall/all\>Review previous commands.\\
\>repeat\>\>Repeat a command.\\
\>setenv or set\>:== or := \>Symbol assignment.\\
\>unsetenv or unset\>delete/symbol\>Delete a symbol.\\
\>printenv or set \>show symbol/all\>Show all symbol values.\\
\>source or csh\> @\>Command procedures, scripts.\\
\>mail\>mail\>Electronic mail.\\
\> ps \>show process\>Shows processes.\\
\>exit or logout\>logout\>Logout.\\
{\bf Control Characters and Command Line Editing}\\ 
\>ctrl/d\>ctrl/z\>End-of-file from keyboard.\\
\>ctrl/z\>ctrl/y or c\>Suspend command.\\
\>ctrl/c\>ctrl/y or c\>Interrupt or abort program.\\
\>ctrl/u\>ctrl/u\>Delete line.\\
\>Backspace or Delete\\
\>\>Delete\>Delete last character.\\
\>--\>/\>Option follows.\\
\>;\>\>Start new command.\\
\> \verb+>+ or \verb+>>+ \>assign sys\$output\>Output or append to line.\\
\> \verb+<+ \>\>Input from file.\\
\> \verb+|+ \>\>Pipe output to next command.\\
\> \& \> spawn/nowait \>Run command in background.\\
\> \verb+~+\>sys\$login:\>Home directory.\\
\> * \> * \>Match all strings.\\
\> ? \> \% \> Match any character.\\
\> .. \> [--] \> Up one directory level.\\
\> \verb+\+ \> -- \> Continuation of command to next line.\\
\> !! \> Up-arrow \>Re-execute last command.\\
\> !string:p \> recall string \>Search for command starting with ``string''.\\
\> \verb+^+old\verb+^+new\>\> Substitute string ``old'' for string``new'' \\
\>                        \>\> \ in last command, and execute.\\
\> !string:s/old/new/ \>  \>Search for command starting with ``string'',\\
\>                    \>  \> \ substitute ``old'' with ``new'', and execute \\
\end{tabbing}

\normalsize
