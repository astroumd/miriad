%  LaTeX include file
%
%  Check VOBS: is that really V of the OBSERVATORY???
%
%  History:	xx-xxx-89  Bob Sault 	Original written
%		26-jul-90  pjt		Let's see how latex table looks???
%		19-feb-91  pjt		fixed date format and RA---SIN
%
\mylabel{a:image}

In this Appendix we will describe the items that can be present
in an image dataset. MIRIAD utilities such as {\tt itemize},
{\tt puthd}, {\tt mathd},
{\tt copyhd}, {\tt delhd}, and {\tt imhead} or {\tt imlist} may
come in handy to browse or modify these ``header variables''.

Note that the units used in MIRIAD are not always FITS-like, 
{\it e.g.} frequencies are stored in Ghz in MIRIAD, in FITS
one often finds hz. \index{FITS} For example, MIRIAD keeps
velocity in km/s, sky coordinates in radians and frequencies
in Ghz.

\small
\def\see{$\Rightarrow$}
\begin{table}
\caption{Item names in MIRIAD image datasets}
\begin{tabular}{|l|l|c|c|l|} \hline
&&&&\\
Item                & Type      & Units & Origin    & Description/Comments \\ 
&&&&\\\hline
bmaj,bmin           & real      & Radians &         & Beam major and minor axis FWHM.\\
bpa                 & real      & Degrees &         & Beam position angle.\\
bunit               & character &         & FITS    & The units of the pixels (as FITS BUNIT). \\
cdelt1,cdelt2,...   & real      & \see ctype & FITS & The increment between pixels. \\
crpix1,crpix2,...   & real      & \see ctype & FITS & The pixel coordinate of the reference pixel. \\
crval1,crval2,...   & real      &       & FITS      & The coordinate value at the reference pixel. \\
                    &           & Radians &         & \ \ if ctype {\tt RA}.\\
                    &           & Radians &         & \ \ if ctype {\tt DEC}.\\
                    &           & km/s    &         & \ \ if ctype {\tt VELO} or {\tt FELO}\\
                    &           & Ghz     &         & \ \ if ctype {\tt FREQ}\\
ctype1,ctype2,...   & character &       & FITS      & The type of the nth axis (as FITS CTYPE). \\
datamin,datamax     & real      & \see bunit & FITS & The minimum and maximum pixel values.\\
date-obs            & character &       & FITS      & FITS requires a 'dd/mm/yy' format.\\
epoch               & real      & years & (FITS)    & The epoch of the coordinate system.\\
history             & text      &       & FITS      & A text item containing the history of \\
	            &           &       &           & \ \ processing performed to the data set.\\
image               & real      & \see bunit  &     & The pixel data.\\
instrume            & character &       & FITS      & {\tt HATCREEK} for us\\
linetype            & character &       &           & \\
mask                & integer   & \#    &           & Bitmap used to determine which pixels in \\
                    &           &       &           & \ \ the image have been blanked. \\
naxis               & integer   & \#    & FITS      & Number of dimensions. \\
naxis1,naxis2,...   & integer   & \#    & FITS      & Number of pixels along each dimension. \\
niters              & integer   & \#    &           & The total number of deconvolution iterations\\
                    &           &       &           & \ \ performed on the image.\\
object              & character &       & FITS      & source name \\
observer            & character &       & FITS      & observers name\\
obsra,obsdec        & double    & Radians &         & The apparent RA and DEC of the phase \\
                    &           &       &           & \ \ center of the observation. \\
restfreq            & double    & Ghz   &           & The rest frequency of the observed data.\\
telescop            & character &       & FITS      &\\
vobs                & real      & Km/s  &           & Velocity of the observatory (???), \\
                    &           &       &           & \ \ with respect to the rest frame,\\
                    &           &       &           & \ \ during the observation. \\
xshift,yshift       & real      & Radians &         & Shift of the map center from the phase\\
                    &           &       &           & \ \ center when mapping. \\ \hline
\end{tabular}
\end{table}
\normalsize
