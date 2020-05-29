#  MIRIAD

MIRIAD (the Multichannel ....) was originally developed for BIMA, and
has been adopted for a number of radio telescopes (CARMA, SMA, WSRT,
ATNF and perhaps more).  Sadly each of these has clones and diverged
from the original version of MIRIAD.  So be it.  This is the original
BIMA/CARMA version, as originally developed by Bob Sault in the late
80s. 



# Installation

We have a csh script **install_miriad** and a much simpler bare bones
**install_miriad.sh**. They may contain helpful comments to get you
past some hurdles, but here are briefly the steps on a linux machine,
extracted from those scripts:

      git clone https://github.com/astroumd/miriad
      cd miriad
      install/install.miriad gfortran=1  generic=1 gif=1 telescope=carma

This installation will take about 3 minutes, and usually takes up about 

# Requirements

The following tools should be present:  a Fortran and C compiler, make,
csh, git, development libraries for X11, optionally automake and pgplot library.

## Ubuntu

Essentials:

      sudo apt install git tcsh build-essential gfortran xorg-dev libreadline6-dev -y

Optionals:

      sudo apt install pgplot5 automake libtool flex -y

## Centos

Native pgplot needs a special install. Not tested.

# History

* V1 Original BIMA - Bob Sault (1987-1990)
* V2 BIMA - RCS based (1990-2000)
* V3 BIMA and CARMA - CVS based (2001-2003)
* V4 BIMA and CARMA - 64 bit  (2003-2016)
* V5 - never released -
* V6 CARMA - github based, pgplot decoupled
