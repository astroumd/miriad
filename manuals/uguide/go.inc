%% This file is to be included by latex in ug.tex
%
% GO (VMS)
%
%	3-apr-91  pjt
\mylabel{s:go}
\myfile{go.inc}
The {\tt GO} front-end \index{go, front-end}
presents MIRIAD and Werong\footnote{Werong is 
a predecessor of Miriad, mainly used to reduce continuum
data, and also uses the GO front-end}
menus on VT100\index{VT100}
terminals\footnote{You can run it remotely from
{\it e.g.} sunwindows by running it within tool utilities, such as
{\tt ansigraf} or {\tt tooltool}}, and is invoked by typing:
\index{ansigraf} \index{tooltool}
\begin{verbatim}
    $ GO
\end{verbatim}

The top menu contains several icons representing the functionality
of the PF[1-4] and Arrow keys at different points in the program and also
the currently selected program name (Prog:) and destination
(Dest:) name.  GO is directed by typing one of the 
keys PF1...PF4 ENTER CR UP-ARROW DOWN-ARROW.  

If 
\begin{verbatim}
    $ GO HISTO
\end{verbatim}
is typed on the command line, {\tt GO} will already fill in the
program name, {\tt HISTO} in this case,\index{SUBMIT,VMS}
and bring up it's menu; {\tt GO} will also exit after the program is run.

\footnotesize\begin{verbatim}
 PF1(EXIT)  stops GO with no further action.
 PF1(Done)  exits from a program menu.
 PF2(HELP)  presents either this message or a local help message
            or lists of MIRIAD programs or Destination names depending on
            where you are in GO.
 PF2(Done)  exits from HELP.
 CR         exits from HELP (queues or progs) and inserts the item under 
            the cursor in the proper blank.
 ENTER(RUN) starts the program named by Prog:
 PF3(Prog)  accepts a program name and presents it's menu.
 PF4(Dest)  accepts the destination (queue) name that programs will be 
            submitted to. (SUBMIT/QUEUE=)
            If no queuename is present, programs will be run interactively.
            If > is the first character, the desination is a file that the 
            commands will be appended to.
\end{verbatim}\normalsize

Context sensitive help\index{help, go}
is present during most steps of the menu process; if PF2 is pressed
when nothing is happening, the above 
message will be displayed; if it is pressed
when entering a {\bf Prog:} or {\bf Dest:}, 
lists of these will be displayed; if it is
pressed while a program name is present, the program help message is 
displayed; with the current menu item in the middle of the screen. All help 
messages are presented in a special window which can be scrolled using the 
UP and DOWN arrow keys. HELP is exited by typing PF2 or by typing CR. CR
has the additional action of inserting the help item under the cursor back
into the {\bf Prog:} or {\bf Dest:} blank.

When a program name is entered (PF3); GO searches for the documentation
and executable files first in LOCALDOC:/LOCALBIN: and then in MIRPDOC:/
MIRBIN: and reports an error if they don't exist in either place.
(To have a local program, you must also set up the VMS symbol

\begin{verbatim}
 $ local_prog_name:=="$localbin:local_prog_name.exe"

\end{verbatim}
and {\tt localbin:} must include  the disk name.)
{\tt PROG.DOC} is used to present an initial menu for the program.
If {\tt PROG.DEF}
is also present, it is used to fill in default answers for the
menu items.  The user now scrolls up and down the menu, and fills/changes
menu items by typing xxxxx CR.  If -\verb+>+ or \verb+<+- is  typed at 
this point the
old answer is presented for editing using the VMS command line editing keys.
(CR must be typed at the end of each item.)
When satisfied, pressing ENTER will start the program.  While the program 
is running interactively, GO gives up control of the screen but when
the program exits, GO asks the user to type a key and then paints the 
screen again and continues unless the program name was entered on the 
command line in which case GO exits.

Example of how your VT100 might look:

\footnotesize\begin{verbatim}
 |---------------------------------MIRIAD MENU-------------------------------|
 |Menu   Help     Run     ^ |  Prog <PF3>:uvhat                              |
 |<PF1>  <PF2>  <ENTER>   | v  Dest <PF4>:                                   |
 |---------------------------------------------------------------------------|
 in              = 3c84wco.15jan
 out             = junk1
 logrange        =
\end{verbatim}\normalsize

