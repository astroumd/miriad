% -*- TeX -*-

\chapter{Scripting}


\section{Interactive shells}

Miriad vs. Unix. Miriad shell uses {\tt save/load} and {\tt tput/tget} commands,
and if properly installed the {\it readline} library.
Unix shells have different command history recall.

\section{Programmable shells}

Shell (csh/sh/bash) programming vs. python (pyramid)

Useful to import, like MIRIAD programs, to allow a {\it keyword=value} 
commandline syntax. Easy to fake in csh.

\section{Example: mosaic.py}

Here is an example of a mosaic script, using {\tt pyramid} procedures.

\footnotesize
\verbatimlisting{mosaic.py}
\normalsize

\begin{verbatim}\end{verbatim} % prevents 'missing \item' error; no idea why
