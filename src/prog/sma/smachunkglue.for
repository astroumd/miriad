      program smachunkglue
c------------------------------------------------------------------------
c= smachunkglue - glue spectral chunks together
c& jhz 
c: calibration
c+
c     SMACHUNKGLUE glues together individual multi-chunk files into
c     one mega-multi-chunk file.
c
c     The individual multi-chunk files must be IDENTICAL except for 
c     the values and flags of the correlations.  I.e. they must have 
c     the same preambles.
c
c     For example, if we have 3 files names "vis_1", "vis_2" and 
c     "vis_3", where files contain N1, N2, and N3  spectral chunks, 
c     then the output file will contain N1+N2+N3 spectral chunks 
c     glued together in the order
c     vis_1(1:N1), vis_2(1:N2), vis_3(1:N3)
c
c     The output contains N1+N2+N3 spectral chunks
c
c@ vis
c	Root name of input visibility files.   Files must be named
c	vis_i for the ith file.  No default. NOTE: any calibration
c	tables present in the input datasets are NOT applied in
c	forming the output.
c@ nfiles
c	Number of file to read.  
c@ out
c	Output file name. No default
c
c--
c     jhz  13may05 made the first version for SMA bade on uvglue
c     pjt   4apr08 made it work for unequally sized chunks
c---------------------------------------------------------------------------
      implicit none
c
      include 'maxdim.h'
      character in*80, out*80, name*90, line*80
      double precision preamble(5)
      integer nchani, nchano, lin, lins, lout, nread, irec, ichan,
     +  offset, ioff, npol, pol, nfiles, i, j, k, ifile
      logical gflags(MAXCHAN), first
      complex data(MAXCHAN)
      real scratch(MAXCHAN*3)
      integer MAXSPECT
      parameter(MAXSPECT=48)
      double precision sfreqi(MAXSPECT),
     *  sdfi(MAXSPECT),restfreqi(MAXSPECT)
      double precision sfreq(maxspect),
     *  sdf(MAXSPECT),restfreq(MAXSPECT)
      integer nschan(MAXSPECT), ischan(MAXSPECT)
      integer nschani(MAXSPECT), ischani(MAXSPECT), ischan0, nread0
      character version*(*)
      parameter (version='SMAChunkGlue: Version 9-apr-08')
      integer len1, nspecti, nspect, vupd
      character itoaf*3
      data first /.true./
c-----------------------------------------------------------------------
      call output(version)
c
c Get inputs
c
      call keyini
c
      call keya ('vis', in, ' ')
      if (in.eq.' ') call bug ('f', 'Input root file name not given')
      call keyi ('nfiles', nfiles, 0)
      if (nfiles.eq.0) call bug ('f', 'Number of files not given')
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
c Loop over number of input files to 
c get the header information
c
      nspect=0
      nchano=0
      ischan0=0
      do ifile= 1, nfiles
        name = in(1:len1(in))//'_'//itoaf(ifile)
        call uvopen (lin, name, 'old')
        call uvvarini(lin,vupd)
        call uvvarset(vupd,'nspect')
        call uvvarset(vupd,'sfreq')
        call uvvarset(vupd,'sdf')
        call uvvarset(vupd,'nschan')
c
c Read first record
c
        call uvread (lin, preamble, data, gflags, maxchan, nread)
        call uvrdvri(lin,'nspect',nspecti,0)
        call uvgetvri(lin,'ischan',ischani,nspecti)
        call uvgetvri(lin,'nschan',nschani,nspecti)
        call uvgetvrd(lin,'sfreq',sfreqi,nspecti)
        call uvgetvrd(lin,'sdf',sdfi,nspecti)
        call uvgetvrd(lin,'restfreq',restfreqi,nspecti)
        nchano=nchano+nread        
        do i=1, nspecti
             sfreq(i+nspect) = sfreqi(i)
               sdf(i+nspect) = sdfi(i)
          restfreq(i+nspect) = restfreqi(i)
            nschan(i+nspect) = nschani(i)
          if(ifile.eq.1) then
            ischan(i+nspect) = ischani(i)
          else
            ischan(i+nspect) = ischan0+1
          end if
          ischan0 = ischan0 + nschani(i)
        end do
        write(*,*) 'ischan: ',ischan
        write(*,*) 'nschan: ',nschan
        nspect =  nspect + nspecti
        call uvclose (lin)
      end do
c
c loop over the input data
c
      nchani = 0
      do ifile= 1, nfiles
        irec = 0
        name = in(1:len1(in))//'_'//itoaf(ifile)
        call uvopen (lin, name, 'old')
c
c Read first record
c
        call uvread (lin, preamble, data, gflags, maxchan, nread)
        if (nread.eq.0) call bug ('f', 'No data in file '//name)
        call output ('Processing input file '//name)
        do while (nread.gt.0)
          irec = irec + 1
c
c Load visibility into scratch buffer
c
          k = 1
          do j = 1, 3*nread, 3
            scratch(j) = real(data(k))
            scratch(j+1) = aimag(data(k))
            scratch(j+2) = -1
            if (gflags(k)) scratch(j+2) = 1
            k = k + 1
          end do
c
c Write scratch file
c
          offset = (irec-1)*nchano*3 + nchani*3
          call scrwrite (lins, scratch, offset, nread*3)
c
          call uvread (lin, preamble, data, gflags, maxchan, nread0)
          if (nread0.eq.0) then
             nchani = nchani + nread
             write(*,*) 'EOF rec=',irec
          endif
          nread = nread0
        end do

        call uvclose (lin)
        write (line, 100) irec
100     format ('Read ', i8, ' records from this file')
c        call output (line)
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
      name = in(1:len1(in))//'_1'
      call uvopen (lin, name, 'old')
      call uvset(lin,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call VarInit (lin, 'channel')
c
c Set up output file (its already open)
c
      call uvset(lout,'preamble','uvw/time/baseline',0,0.,0.,0.)
      call hdcopy(lin,lout,'history')
      call hisopen(lout,'append')
      call hiswrite(lout,'SMACHUNKGLUE: Miriad '//version)
      call hisinput(lout,'SMACHUNKGLUE:')
      call hisclose(lout)
      call VarOnit(lin,lout,'channel')
c
c Copy variables from channel 1 file, and copy data from
c scratch file
c 
      irec = 0
      call uvread (lin, preamble, data, gflags, maxchan, nread)
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
c
c write the spectral headers       
c
        call uvputvrd(lout,'sfreq',sfreq,nspect)
        call uvputvrd(lout,'sdf',sdf,nspect)
        call uvputvrd(lout,'restfreq',restfreq,nspect)
        call uvgetvri (lin,'npol', npol, 1)
        call uvgetvri (lin,'pol', pol, 1)
        call uvputvri(lout,'nspect', nspect,1)
        call uvputvri(lout,'nchan', nchano,1)
        call uvputvri(lout,'nschan', nschan,nspect)
        call uvputvri(lout,'ischan', ischan,nspect)
        call uvputvri(lout,'npol', npol, 1)
        call uvputvri(lout,'pol', pol, 1)
c
c Write data
c
        call uvwrite(lout,preamble,data,gflags,nchano)
c
c Read next record
c
        call uvread (lin, preamble, data, gflags, maxchan, nread)
      end do
c
c Bye bye
c
      call uvclose (lin)
      call uvclose (lout)
      call scrclose (lins)
c
      end
