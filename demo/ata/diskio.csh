#!/bin/csh

rm -r ./ata-42.30.uvcal
echo start UVCAL: `date` > uvcal.timing
uvcal vis=./ata-42.30.uv out=./ata-42.30.uvcal
echo finish UVCAL: `date` >> uvcal.timing
cat uvcal.timing
