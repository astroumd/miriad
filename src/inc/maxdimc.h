/*
	-------------------------------------------------------------
	maxdimc.h - include file for C code containing MIRIAD-wide
		    parameters

	MAXDIM .... maximum number of elements in any one plane
		    (ie, maximum dimensionality of a map)
	MAXANT .... maximum number of antennae
	MAXBASE ... maximum number of baselines
	MAXCHAN ... maximum number of channels in spectral data

	History:

	04aug91 mjs   Original version.
	05aug91 mjs   Put parentheses around MAXBASE defined value.
        bpw  20jul91  Created as xyzio.h
        mjs  08apr92  Minor mod to compile on VAX
        rjs  23feb93  Merged maxdimc.h and xyzio.h. Include MAXNAX.
        mchw 01feb02  decouple MAXBASE from MAXANT.
	mchw 04feb02  change define MAXBUF 1048576 to 4194304.
        mchw 14feb02  recouple MAXBASE to MAXANT for selfcal on MAXANT antennas.
	pjt   3dec02  added MAXBASE2,MAXDIM2
        pjt   5mar04  MAXANT not too big for mfcal
	-------------------------------------------------------------
*/
#define		MAXDIM		8192
#define		MAXDIM2		65536
#define		MAXANT		64
#define		MAXANT2		28
#define		MAXBASE		((MAXANT * (MAXANT + 1)) / 2)
#define		MAXBASE2	500
#define		MAXCHAN		4096
#define		MAXNAX		7
#define		MAXWIN		16

#ifdef unicos
#  define	MAXBUF		2097152
#endif
#ifdef convex
#  define	MAXBUF		4194304
#endif
#ifdef alliant
#  define	MAXBUF		4194304
#endif
#ifndef MAXBUF
#  define	MAXBUF		4194304
#endif

