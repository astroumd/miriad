#!/bin/csh

echo $0  CARMA-15 mosaicing

hex7-15.csh carma_E 22 .1 5
default7-15.csh carma_E 22 .1 5
joint7-15.csh carma_E 22 .1 5
tail casc.vla.results
