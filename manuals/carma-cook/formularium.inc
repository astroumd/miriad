% -*- tex -*-
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
coordinate system with the X axis pointing outwards from the
local meridian.
The conversion of these to a local topocentric
system is:
$$
	E,N,U = \cos{lat}, \sin{lat} X,Y,Z
$$

and the relationship betwen UVW and XYZ is, in a right-handed coordinate
system (XY in the equatorial plane, X meridian, Y to the east, Z towards
the north pole)

%   see SMT pp.86 (section 4.2)

$$
u  =   sin H             cos H      0               X
v  =   -sin d cos H    sin d sin H     cos d        Y
w  =   cos d cos H     -cos d sin H     sin d       Z
$$
where $H$ is the hour angle, $\delta$ the declination.
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

