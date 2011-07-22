% -*- TeX -*-

\chapter{Future}

As we get to know CARMA and refine calibration strategies,
a number of new techniques will undoubtedly
will have to be addressed. We name a few that are appearing 
on the horizon that you can expect future versions of the cookbook to address:

\begin{itemize}
\item 
Polarization: dual-polarization (LL and RR) are available, as well as full stokes.
\item 
Blanking and Flagging: baseline and band dependant integration times. This will
require some changes to the lower level Miriad code. A special uv-variable 
{\tt bfmask(nspect)} is being prepared, with a task {\tt uvflagb} that will transfer
selected mask-bits to the normal miriad narrow and wide band flags.
\item 
More detailed primary beam models for OVRO and BIMA for improved mosaicing. Currently
only simple gaussians are used. Again something needed in Miriad.
\item 
Iterative Selfcal (cf. BIMA Song scripts)\
\item
% http://setiathome.berkeley.edu/~aparsons/aipy/index.html
support for python (see e.g. AIPY)
\end{itemize}



% 
