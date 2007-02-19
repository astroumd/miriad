
\newcommand{\newchapter}{
  \cleardoublepage
  \renewcommand{\thepage}{\thechapter-\arabic{page}}
  \setcounter{page}{1}}

\newcommand{\miriad}{{\bf $\cal MIRIAD$}}
\newcommand{\aips}{{\bf $\cal AIPS$}}
\newcommand{\task}[1]{{\tt #1}\index{#1}}
\newcommand{\unix}[1]{{\tt #1}\index{#1}}
\newcommand{\MM}[1]{$#1$}
\newcommand{\TT}[2]{{$#1\times#2$}}
\newcommand{\degrees}{$^\circ$}
\newcommand{\kms}{km~s$^{-1}$}
\newcommand{\radm}{rad~m$^{-2}$}
\newcommand{\lookat}{$\Rightarrow$}
\newcommand{\elll}{\ell}
\newcommand{\ssigma}{$\sigma$}


%============================================================================
% Save file as: VERBATIMFILES.STY      Source: FILESERV@SHSU.BITNET
% Here is a version of Adrian's VERBATIM.STY, for inputting whole files
% verbatim, which is "more LaTeX-like" in that it uses the actual LaTeX
% macros which set up the `verbatim' environment.
%
% As a matter  of interest, it is much nicer for TeX if you input large
% quantities of "verbatim material" from an "external file" rather than by use
% of the `verbatim' environment (i.e. putting the material in the main input
% file. This is because this environment, in common with most (but not all)
% other "verbatim macros", makes the whole of the "vebatim material" a macro
% argument and therefore eats up TeTeX's internal memory.
%
% Chris Rowley
%

% ---              V E R B A T I M F I L E S . S T Y
%
% --- This LaTeX style-file defines two user-callable macros:
% ---     \verbatimfile{<filename>}    for verbatim inclusion of a file
% ---     \verbatimlisting{<filename>} for verbatim inclusion with line numbers
%
% --- The macros are based on those distributed with Sunil Podar's
% --- `EPIC.STY' macro package, attributed to Tim Morgan,
% --- modified to keep internal macros internal by Adrian F. Clark,
% --- alien@uk.ac.essex.ese
% --- ---and further latexification by Chris Rowley,
% --- ca_rowley@uk.ac.open.acs.vax.
%
% --- Note that the precise layout of line breaks in this file is important!
%

\def\verbatimfile#1{\begingroup
                    \@verbatim \frenchspacing \@vobeyspaces
                    \input#1 \endgroup
}

\newcounter{lineno}

\def\verbatimlisting#1{\setcounter{lineno}{0}%
    \begingroup \@verbatim \frenchspacing \@vobeyspaces \parindent=20pt
    \everypar{\stepcounter{lineno}\llap{\thelineno:\ \ }}\input#1
    \endgroup
}

%============================================================================
\def\@beginverb{\begin{verbatim}}

\begingroup
\catcode `|=0 \catcode `[= 1 \catcode`]=2 
\catcode `\{=12 \catcode `\}=12 \catcode`\\=12
|gdef|@endverb[\end{verbatim}]
|endgroup

\def\verbatimpjt#1{\def\next{\input{#1}}\expandafter\@verbinput\@endverb}

\def\@verbinput{\expandafter\@beginverb\next}
