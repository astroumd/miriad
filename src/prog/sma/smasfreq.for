      program smasfreq
c------------------------------------------------------------------------
c= smasfreq - fix the frequency labelling problem in SMA data
c& jhz 
c: calibration
c+
c     SMASFREQ re-labels frequencies for each of spectral windows 
c     using the follwoing recipe:
c     sfreq(i) = sfreq(i) + 0.5*sdf(i) for i =1,2,5,6,9,10,13,14,17,18,21,22
c     sfreq(i) = sfreq(i) - 0.5*sdf(i) for i =3,4,7,8,11,12,15,16,19,20,23,24
c     sfreq(i) must be the original sky frequency from the raw SMA data;
c     sdf(i)   must be the original frequency channel increment from the raw SMA
c              data.   
c
c     The output contains the corrected sky frequency label and all other
c     data from the input file.
c
c@ vis
c	Root name of input visibility file. No default  
c@ out
c	Output file name. No default
c
c--
c     jhz  28Nov2007 made the first version for SMA 
c---------------------------------------------------------------------------
      implicit none
c
      include 'maxdim.h'
      character in*80, out*80, line*100
      double precision preamble(5)
      integer nchano, lin, lout, nread, irec, i
      logical gflags(maxchan), doupdsfreq
      complex data(maxchan)
      integer maxspect
      parameter(maxspect=48)
      double precision sfreqi(maxspect),sfoff(maxspect),
     *  sdfi(maxspect),restfreqi(maxspect)
      double precision sfreq(maxspect),
     *  sdf(maxspect)
      integer nschan(maxspect), ischan(maxspect)
      character version*(*)
      parameter (version='SMAsfreq: Version 28-Nov-07')
      integer len1, nspecti, nspect, vupd, pol, npol
      logical uvVarUpd
c-----------------------------------------------------------------------
      call output(version)
c
c Get inputs
c
      call keyini
c
      call keya ('vis', in, ' ')
      if (in.eq.' ') call bug ('f', 'Input root file name not given')
      call keya ('out', out, ' ')
      if (out.eq.' ') call bug ('f', 'Output file name not given')
      call keyfin
c
c Open output file now, rather than later, incase it already exists. We
c don't want to waste hours writing a scratch file and then have it fail
c
      call uvopen(lout,out(1:len1(out)),'new')
c
c Loop over number of input files to 
c get the header information
c
      irec = 0
      nspect=0
      nchano=0
        call uvopen (lin, in(1:len1(in)), 'old')
        call uvvarini(lin,vupd)
        call uvvarset(vupd,'nspect')
        call uvvarset(vupd,'sfreq')
        call uvvarset(vupd,'sdf')
        call uvvarset(vupd,'nschan')
101   format('s',i2, 4x,i4, 4x, f8.4, '  =>  ', f8.4, 4x, f8.3)     
c
      call output ('Processing input file '//in(1:len1(in)))
      call uvset(lin,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call VarInit (lin, 'channel')
c
c Set up output file (its already open)
c
      call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call hdcopy(lin,lout,'history')
      call hisopen(lout,'append')
      call hiswrite(lout,'SMASFREQ: Miriad '//version)
      call hisinput(lout,'SMASFREQ:')
      call hisclose(lout)
      call VarOnit(lin,lout,'channel')
c
c Copy variables from channel 1 file, and copy data from
c the input file
c 
      irec = 0
      call uvread (lin, preamble, data, gflags, maxchan, nread)
c
      do while (nread.gt.0) 
c
c Fish out spectrum from input file
c
        irec = irec + 1
          doupdsfreq = uvVarUpd(vupd)
c
c  processing the sky frequency correction
c
        if(doupdsfreq) then
        call uvrdvri(lin,'nspect',nspecti,0)
        call uvgetvri(lin,'ischan',ischan,nspecti)
        call uvgetvri(lin,'nschan',nschan,nspecti)
        call uvgetvrd(lin,'sfreq',sfreqi,nspecti)
        call uvgetvrd(lin,'sdf',sdfi,nspecti)
        call uvgetvrd(lin,'restfreq',restfreqi,nspecti)
        nchano=nread
            nspect=nspecti
        if(nspect.lt.24)
     * call bug('w', 'the frequency configuration must be original!')
            sfoff(1) = 0.5*sdfi(1)
            sfoff(2) = 0.5*sdfi(2)
            sfoff(5) = 0.5*sdfi(5)
            sfoff(6) = 0.5*sdfi(6)
            sfoff(9) = 0.5*sdfi(9)
            sfoff(10) = 0.5*sdfi(10)
            sfoff(13) = 0.5*sdfi(13)
            sfoff(14) = 0.5*sdfi(14)
            sfoff(17) = 0.5*sdfi(17)
            sfoff(18) = 0.5*sdfi(18)
            sfoff(21) = 0.5*sdfi(21)
            sfoff(22) = 0.5*sdfi(22)
            sfoff(3) = -0.5*sdfi(3)
            sfoff(4) = -0.5*sdfi(4)
            sfoff(7) = -0.5*sdfi(7)
            sfoff(8) = -0.5*sdfi(8)
            sfoff(11) =-0.5*sdfi(11)
            sfoff(12) =-0.5*sdfi(12)
            sfoff(15) =-0.5*sdfi(15)
            sfoff(16) =-0.5*sdfi(16)
            sfoff(19) =-0.5*sdfi(19)
            sfoff(20) =-0.5*sdfi(20)
            sfoff(23) =-0.5*sdfi(23)
            sfoff(24) =-0.5*sdfi(24)
      call output('Updating the sky frequencies:')
      call output('chunkID nchan in-sfreq(GHz) out-sfreq(GHz) sdf(MHz)')
            do i=1, nspecti
             sfreq(i) = sfreqi(i)+sfoff(i)
               sdf(i) = sdfi(i)
      write(line,101) i,nschan(i),sfreqi(i), sfreq(i),sdf(i)*1000.
      call output(line)
            end do
          end if 
c
c Copy variables
c
        call VarCopy(lin, lout)
c
c write the spectral headers       
c
        if(doupdsfreq) call uvputvrd(lout,'sfreq',sfreq,nspect)
        call uvgetvri (lin,'npol', npol, 1)
        call uvgetvri (lin,'pol', pol, 1)
        call uvputvri (lout,'npol', npol, 1)
        call uvputvri (lout,'pol', pol, 1)
c
c Write data
c
        call uvwrite(lout,preamble,data,gflags,nread)
c
c Read next record
c
        call uvread(lin,preamble,data,gflags,maxchan,nread)
      end do
        write (line, 100) irec
100     format ('Copy over ', i8, ' records from ')
        call output (line(1:(len1(line)+1))//in(1:len1(in)))

c
c Bye bye
c
      call uvclose (lin)
      call uvclose (lout)
c
      end
