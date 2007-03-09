      program noiseglue
c------------------------------------------------------------------------
c= noiseglue - glue channels together
c& dnf
c: calibration
c+
c     NOISEGLUE glues together 2 individual multi-channel files into
c     one mega-multi-channel file. This task is specifically used to
c     glue the LSB and USB (created by conjugating the LSB) for the noise
c     source back together into 1 file.
c
c     The individual multi-channel files must be IDENTICAL except for 
c     the values and flags of the correlations.  I.e. they must have 
c     the same number of channels and the same preambles.
c     
c     Each data set must have the same number of windows (nwin) and the
c     output will have nwin*2 windows. The header info that is window
c     specific is copied from the reference dataset.
c
c@ vis
c       Visibility file names. 2 Must be given. No default.
c       NOTE: any calibration tables present in the input datasets are NOT
c       applied in forming the output.
c@ reference
c       Dataset used for header reference (sfreq, restfreq, sdf), since
c       using uvcal to conjugate the data will not get these values correct
c       If not present it will default to the second vis file.
c       This dataset MUST match vis(2) except for header values, no
c        consistency checking is done.
c@ out
c	Output file name. No default
c
c--
c     08mar07 dnf original version based on uvglue
c---------------------------------------------------------------------------
      implicit none
c
      include 'maxdim.h'
      character in(2)*80, out*80, line*80,type*1,reference*80
      double precision preamble(5),preamble2(5)
      integer nchani, nchano, lin, lins, lout, nread, irec, ichan,
     +  offset, ioff, npol, pol, j, k, ifile,lin2,nread2
      logical gflags(maxchan), first,gflags2(maxchan),update,update2
      complex data(maxchan),data2(maxchan)
      real scratch(maxchan*3)
      real systemp(MAXWIN*MAXANT),systempA(MAXWIN*MAXANT)
      real systempB(MAXWIN*MAXANT)
      integer ischan(MAXWIN), nschan(MAXWIN)
      integer ischanA(MAXWIN),ischanB(MAXWIN),nschanA(MAXWIN)
      integer nschanB(MAXWIN)
      double precision restfreq(MAXWIN),sdf(MAXWIN)
      double precision restfreqA(MAXWIN),restfreqB(MAXWIN)
      double precision sdfA(MAXWIN),sdfB(MAXWIN)
      double precision sfreq(MAXWIN)
      double precision sfreqA(MAXWIN),sfreqB(MAXWIN)
      integer nischanA,nnschanA,nsystempA,nrestfreqA,nsdfA,nsfreqA
      integer nischanB,nnschanB,nsystempB,nrestfreqB,nsdfB,nsfreqB
      integer nchanA,nchanB,nspect
      character version*(*)
      parameter (version='NoiseGlue: Version 08-Mar-07')
      data first /.true./
c-----------------------------------------------------------------------
      call output(version)
c
c Get inputs
c
      call keyini
c
      call keya ('vis', in(1), ' ')
      call keya ('vis', in(2), ' ')
      if (in(1) .eq. ' ' .or. in(2) .eq. ' ') 
     *      call bug('f', 'Input file names not given, 2 are required')
      call keya('reference',reference,in(2))
      call keya ('out', out, ' ')
      if (out.eq.' ') call bug ('f', 'Output file name not given')
      call keyfin
c
c Open output file now, rather than later, incase it already exists. We
c don't want to waste hours writing a scratch file and then have it fail
c
      call uvopen(lout,out,'new')
c
c Open scratch file
c
      call scropen (lins)
c
c Loop over number of input files
c
      irec = 0
      do ifile= 1, 2
        call uvopen (lin, in(ifile), 'old')
c
c Read first record
c
        call uvread (lin, preamble, data, gflags, maxchan, nread)
        if (nread.eq.0) then
          call bug ('f', 'No data in file '//in(ifile))
        else
          if (first) then
            nchani = nread
            nchano = 2 * nchani
c
            write (line,'(a,i5)') 'Number of input  channels = ', nchani
            call output (' ')
            call output (line)
            write (line,'(a,i5)') 'Number of output channels = ', nchano
            call output (line)
            call output (' ')
            first = .false.
          else
            if (nchani.ne.nread) 
     +         call bug ('f','Number of channels has changed')
          end if
        end if
c
        call output ('Processing input file '//in(ifile))
        do while (nread.gt.0)
          irec = irec + 1
c
c Load visibility into scratch buffer
c
          k = 1
          do j = 1, 3*nchani, 3
            scratch(j) = real(data(k))
            scratch(j+1) = aimag(data(k))
            scratch(j+2) = -1
            if (gflags(k)) scratch(j+2) = 1
            k = k + 1
          end do
c
c Write scratch file
c
          offset = (irec-1)*nchano*3 + (ifile-1)*nchani*3
          call scrwrite (lins, scratch, offset, nchani*3)
c
          call uvread (lin, preamble, data, gflags, maxchan, nread)
        end do

        call uvclose (lin)
        write (line, 100) irec
100     format ('Read ', i8, ' records from this file')
        call output (line)
        irec = 0
      end do
      call output (' ')
      call output (' ')
c
c OK the scratch file is written.  Now pass through the channel
c 1 file again and use it as a template for the variables
c whilst fishing out the glued data
c
      call output ('Copy scratch file to output')
      call uvopen (lin, in(1), 'old')
      call uvopen(lin2,reference,'old')
      call uvset(lin,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call VarInit (lin, 'channel')
c
c Set up output file (its already open)
c
      call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call hdcopy(lin,lout,'history')
      call hisopen(lout,'append')
      call hiswrite(lout,'NOISEGLUE: Miriad '//version)
      call hisinput(lout,'NOISEGLUE:')
      call hisclose(lout)
      call VarOnit(lin,lout,'channel')
c
c Copy variables from channel 1 file, and copy data from
c scratch file
c 
      irec = 0
      call uvread (lin, preamble, data, gflags, maxchan, nread)
      call uvread(lin2,preamble2,data2,gflags2,maxchan,nread2)
c
      do while (nread.gt.0) 
c
c Fish out spectrum from scratch file
c
        irec = irec + 1
        offset = (irec-1)*nchano*3
        call scrread (lins, scratch, offset, nchano*3)
        do ichan = 1, nchano
          ioff = (ichan-1)*3
          data(ichan) = cmplx(scratch(ioff+1),scratch(ioff+2))
          gflags(ichan) = .true.
          if (scratch(ioff+3).lt.0) gflags(ichan) = .false.
        end do
c
c Copy variables
c
        call VarCopy(lin, lout)
        call uvgetvri (lin, 'npol', npol, 1)
        call uvgetvri (lin, 'pol', pol, 1)
c check the spectral channels
        call uvgetvri(lin,'nchan',nchanA,1)
        call uvgetvri(lin2,'nchan',nchanB,1)
        call uvgetvri(lin,'nspect',nspect,1)
        call uvputvri(lout,'nspect',nspect*2,1)
        if(nchanA .ne. nchanB)call bug('f',
     *    'Missmatch in number of channels')
c update ischan
        call uvprobvr(lin,'ischan',type,nischanA,update)
        call uvprobvr(lin2,'ischan',type,nischanB,update2)
        if(nischanA .ne. nischanB) call bug('f',
     *       'Mismatched ischan lengths')
        call uvgetvri(lin,'ischan',ischanA,nischanA)
        call uvgetvri(lin2,'ischan',ischanB,nischanA)
        call copyarri(ischan,ischanA,ischanB,nischanA,nchanA)
        call uvputvri(lout,'ischan',ischan,nischanA*2)
c update restfreq
        call uvprobvr(lin,'restfreq',type,nrestfreqA,update)
        call uvprobvr(lin2,'restfreq',type,nrestfreqB,update2)
        if(nrestfreqA .ne. nrestfreqB) call bug('f',
     *       'Mismatched restfreq lengths')
        call uvgetvrd(lin,'restfreq',restfreqA,nrestfreqA)
        call uvgetvrd(lin2,'restfreq',restfreqB,nrestfreqA)
        call copyarrd(restfreq,restfreqA,restfreqB,nrestfreqA)
        call uvputvrd(lout,'restfreq',restfreq,nrestfreqA*2)
c update sdf
        call uvprobvr(lin,'sdf',type,nsdfA,update)
        call uvprobvr(lin2,'sdf',type,nsdfB,update2)
        if(nsdfA .ne. nsdfB) call bug('f',
     *       'Mismatched sdf lengths')
        call uvgetvrd(lin,'sdf',sdfA,nsdfA)
        call uvgetvrd(lin2,'sdf',sdfB,nsdfA)
        call copyarrd(sdf,sdfA,sdfB,nsdfA)
        call uvputvrd(lout,'sdf',sdf,nsdfA*2)
c update sfreq
        call uvprobvr(lin,'sfreq',type,nsfreqA,update)
        call uvprobvr(lin2,'sfreq',type,nsfreqB,update2)
        if(nsfreqA .ne. nsfreqB) call bug('f',
     *       'Mismatched sfreq lengths')
        call uvgetvrd(lin,'sfreq',sfreqA,nsfreqA)
        call uvgetvrd(lin2,'sfreq',sfreqB,nsfreqA)
        call copyarrd(sfreq,sfreqA,sfreqB,nsfreqA)
        call uvputvrd(lout,'sfreq',sfreq,nsfreqA*2)
c update nschan
        call uvprobvr(lin,'nschan',type,nnschanA,update)
        call uvprobvr(lin2,'nschan',type,nnschanB,update2)
        if(nnschanA .ne. nnschanB) call bug('f',
     *       'Mismatched nschan lengths')
        call uvgetvri(lin,'nschan',nschanA,nnschanA)
        call uvgetvri(lin2,'nschan',nschanB,nnschanA)
        call copyarri(nschan,nschanA,nschanB,nnschanA,0)
        call uvputvri(lout,'nschan',nschan,nnschanA*2)
c update systemp
        call uvprobvr(lin,'systemp',type,nsystempA,update)
        call uvprobvr(lin2,'systemp',type,nsystempB,update2)
        if(nsystempA .ne. nsystempB) call bug('f',
     *       'Mismatched systemp lengths')
        call uvgetvrr(lin,'systemp',systempA,nsystempA)
        call uvgetvrr(lin2,'systemp',systempB,nsystempA)
        call copyarrr(systemp,systempA,systempB,nsystempA)
        call uvputvrr(lout,'systemp',systemp,nsystempA*2)

        call uvputvri (lout, 'npol', npol, 1)
        call uvputvri (lout, 'pol', pol, 1)
c
c Write data
c
        call uvwrite(lout,preamble,data,gflags,nchano)
c
c Read next record
c
        call uvread (lin, preamble, data, gflags, maxchan, nread)
        call uvread (lin2,preamble2,data2,gflags2,maxchan,nread2)
      end do
c
c Bye bye
c
      call uvclose (lin)
      call uvclose (lin2)
      call uvclose (lout)
      call scrclose (lins)
c
      end

c************************************************************************
      subroutine copyarri(output,inA,inB,half,offset)
      implicit none
      integer output(*),inA(*),inB(*)
      integer half,offset
c------------------------------------------------------------------------

      integer i

      do i = 1,half
         output(i) = inA(i)
      enddo
      do i = half+1,half*2
         output(i) = inB(i-half)+offset
      enddo

      end
c************************************************************************
      subroutine copyarrd(output,inA,inB,half)
      implicit none
      double precision output(*),inA(*),inB(*)
      integer half
c------------------------------------------------------------------------

      integer i

      do i = 1,half
         output(i) = inA(i)
      enddo
      do i = half+1,half*2
         output(i) = inB(i-half)
      enddo

      end
c************************************************************************
      subroutine copyarrr(output,inA,inB,half)
      implicit none
      real output(*),inA(*),inB(*)
      integer half
c------------------------------------------------------------------------

      integer i

      do i = 1,half
         output(i) = inA(i)
      enddo
      do i = half+1,half*2
         output(i) = inB(i-half)
      enddo

      end
