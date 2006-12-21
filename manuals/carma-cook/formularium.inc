%  LaTeX include file
%
\chapter{Formularium}
\label{app:formularium}

In this Appendix we summarize various formulae and list constants used 
in MIRIAD and interferometry. 

\section{Interferometry}

\subsection{Antennae positions}
The {\tt uvgen/ant=/baseunit=} keywords control the antennae positions
of an array. These can be specified in either an equatorial system
or a local (topocentric) system. The conversion between the two
is controlled as followed.
A miriad dataset records the antennae positions in the {\tt antpos}
UV variable, which records them in nanoseconds in an equatorial
coordinate system. The conversion of these to a local topocentric
system is:
$$
	x,y,z = \cos{\theta}, \sin{\theta} 
$$

\section{Constants}

In {\tt \$MIRINC/mirconst.inc} various constants are listed that the
code uses. For some a double as well as single precision value is
present.

\footnotesize
\begin{verbatim}
PI     = 3.14159265358979323846   pi
CMKS   = 299792458.0              Speed of light (meters/second)
KMKS   = 1.380658E-23             Boltzmann constant (Joules/Kelvin)        
HMKS   = 6.6260755E-34            Planck constant (Joules-second)
HOVERK = 0.04799216               Planck constant divided by Boltzmann constant (Kelvin/GHz)
\end{verbatim}
\normalsize

