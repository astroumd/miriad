%
% Setting Up Your Account
%
\chapter{Setting Up Your Account}
\label{app:setup}

Setting up your account to use \miriad\ 
of course varies from system to system.
If in doubt, ask a local! We will assume you are using the \verb+csh+
shell.

Typically you will need to know where MIRIAD is stored, and then

\begin{verbatim}
   source /somewhere/miriad/miriad_start.csh
\end{verbatim}

\section{OVRO valley}

\begin{verbatim}
   source source /sw/miriad/cvs/MIRRC.linux    (should use mriiad_start.csh !!)
\end{verbatim}

\section{OVRO cedar flat}

\begin{verbatim}
   source /array/miriad/cvs/miriad_start.csh
\end{verbatim}

\section{Berkeley}

\begin{verbatim}
   source ...
\end{verbatim}

\section{Caltech}

\begin{verbatim}
   source ...
\end{verbatim}

\section{Illinois}

\begin{verbatim}
   source ...
\end{verbatim}

\section{Maryland}

Maryland uses mostly Mandrake Linux (10.1  as of this writing) on IA-32
as well as IA-64 type machines. A few
Solaris machines are still present, but Miriad is not actively maintained
(though available upon request).

\smallskip

Maryland also uses {\tt astromake}, which allows you to (interactively)
load various packages in your shell. Although this comes with an
obvious flexibility, but the danger is that loading packages in
a certain order could render your interactive shell useless,
and loading multiple versions of miriad can make commands from
the older version to peek through  the new one and cause unexpected
result. Use with caution.
Example:
\begin{verbatim}
   source /n/astromake2/astromake_start
   astroload -v daily miriad
\end{verbatim}
