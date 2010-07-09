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
UV variable, which records them in nanoseconds in a local equatorial
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

In {\tt \$MIRINC/mirconst.h} various constants are listed that the
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

\section{Calibration}

\subsection{Line Length Calibration}

Line length calibration works by utilizing the LO1 frequency, $\nu_0$,
and sending a signal along the fiber to each antannea,
and accurately measuring the round trip time.
Half this time
is stored in the {\tt delay} UV variable (in ns) in a MIRIAD
dataset. At the LO1 reference frequency this would amount to a slowly
drifting phase correction, 
computed to be between $-\pi$ and $\pi$,
and stored in the {\tt phasem1} UV  variable (in radians):
% see AstroHeaderWriter.cc around line 2220)
$$
  \phi_{i} = 2 \pi (\nu_{0}L_i \bmod 1) - \pi
$$
The {\tt linecal} program then stores these antenna base phases
from {\tt phasem1} as time dependant
complex gains in a standard MIRIAD gaintable
$$
   g_i = e^{i\phi_i}
$$
and can be applied via commands such as {\tt uvcat}. Note that this
procedure does not apply any bandpass slope.

Recall that the LO1 frequency, $\nu_0$, is generally 
doppler tracked, so some of the variations you will see
with programs such as {\tt varplt} will be due to a
doppler shift component due to earth rotation. The maximum
peak-to-peak variation in the earth
rotation is 0.46 km/s, or 0.15 MHz at 100 GHz.
For a typical 100m (fiberlength difference) baseline this
would be about $15^0$.

An alternative is {\tt uvcal options=linecal,avechan}, 
which takes into account that the measurements in {\tt phasem1}
were taken at LO1 and takes out an additional frequency 
dependant phase slope based on $\nu/\nu_0(\phi_i-\phi_j)$.
Accross a typical 500 MHz band at 3mm this would amount to
about $2^0$.


\subsection{Passband Calibration}

{\tt mfcal} solves for antennae based complex gains $b_i(\nu)$,
and corrects the visibities as follows:

$$
    V_{ij}^{'} = b_i b_j^* V_{ij}
$$

% double check if they are stored as inverse?

\subsection{Gain Calibration}

{\tt selfcal} solves for antennae based complex gains, $g_i(t)$,
and corrects the visibities as follows:
$$
    V_{ij}^{'} = g_i g_j^* V_{ij}
$$

Note that a gain larger than 1 means a loss of signal (e.g. due to
bad pointing) where the observed visibilities needed to be multiplied
by larger numbers to get back to the expected flux.

\subsection{Buddy Phase Calibration}

There are two implementatons of phase calibrating using a nearby
buddy (SZA) antenna operating at around 30 GHz (1cm).


\subsection{Interpolation}

The time interpolation formulae\footnote{See also {\tt \$MIRSUBS/uvgn.for::uvGnFac()}}
that computes a baseline based gain
at time $t$, from antenna based gains $g_A$ and $g_B$ that had
been computed at two surrounding times, $t_1 < t < t_2$, 
is given by the following expression:
$$
G = g_{A,2} 
(1 + (\left| {g_{A,1}\over g_{A,2}}\right|-1)\epsilon)
\left({ g_{A,1} \over g_{A,2}}\right)^\epsilon 
g_{B,2}^* 
(1 + (\left| {g_{B,1}\over g_{B,2}}\right|-1)\epsilon)
\left({ g_{B,1} \over g_{B,2}}\right)^{-\epsilon}
$$
and for a phase-only selfcal solution, where $|g|=1$, this simplifies to:
$$
G = g_{A,2} g_{B,2}^* \left({ g_{A,1} \over g_{A,2}}\right)^\epsilon 
                    \left({ g_{B,1} \over g_{B,2}}\right)^{-\epsilon}
$$
where $\epsilon$ in [0,1]
$$
\epsilon = {  {t_2 - t} \over {t_2 - t_1} }
$$


\section{Doppler Shift}

CARMA spectral line data are normally doppler tracked. In addition
channels are linear in frequency space, so you will find that we employ
the (non-relativistic) 
radio definition of the doppler shift:
% see MIRIAD::uvio.c::uvinfo_chan()
$$
   V_r = { {(\nu_o - \nu)} \over \nu_o } c
       = { {(\lambda-\lambda_0)} \over \lambda } c
$$
instead of the optical definition:
$$
   V_o = { {(\lambda-\lambda_0)} \over \lambda_0 } c 
      =  { {(\nu_o - \nu)} \over \nu } c
$$
then, VELO is used to label an axis in the radio convention,
and FELO when the axis is regular in frequency, but expressed
in the optical convention.

In MIRIAD a few UV variables are used to describe this:
\begin{itemize}
\item restfreq
\item sfreq
\item sdf
\item vsource Nominal radial ; a constant normally (but not for planets)
\item veldop Sum of radial vel of observatory and that of source
\end{itemize}

Thus for a doppler tracked frequency, $\nu$, the corrected frequency would
be
$$
   \nu' = \nu 
$$


The relativistic convention for radial velocities is not implemented
at CARMA yet.
