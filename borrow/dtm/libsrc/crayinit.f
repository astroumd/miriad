C
C                   Data Transfer Mechanism (DTM) v. 2.3
C                           May 1, 1992
C
C UNIVERSITY OF ILLINOIS (UI), NATIONAL CENTER FOR SUPERCOMPUTING
C APPLICATIONS (NCSA), Software Distribution Policy for Public Domain
C Software
C 
C The NCSA software Data Transfer Mechanism [both binary and source (if
C released)] is * in the public domain, available without fee for education,
C research, non-commercial and commercial purposes.  Users may distribute the
C binary or * source code to third parties provided that this statement
C appears on all copies and that no charge is made for such copies.
C 
C UI MAKES NO REPRESENTATIONS ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY
C PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  THE
C UI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY THE USER OF THIS
C SOFTWARE.  The software may have been developed under agreements between
C the UI and the Federal Government which entitle the Government to certain
C rights.
C 
C By copying this program, you, the user, agree to abide by the conditions
C and understandings with respect to any software which is marked with a
C public domain notice.
C



       integer function DTMINIT()
       integer i, tmp, pcnt
       integer DTMMIP, DTMMOP
       character*64 portname

       pcnt = 0

       do 10 i = 1, iargc()

         call getarg(i, portname)
         if (index(portname, '-DTMIN') .NE. 0) then
           call getarg(i+1, portname)
           tmp = DTMMIP(portname)
           pcnt = pcnt + 1
         elseif (index(portname, '-DTMOUT') .NE. 0) then
           call getarg(i+1, portname)
           tmp = DTMMOP(portname)
           pcnt = pcnt + 1
         elseif (index(portname, '-DTM') .NE. 0) then
           call getarg(i+1, portname)
           tmp = DTMMOP(portname)
           pcnt = pcnt + 1
         endif

 10    continue

       DTMINIT = pcnt
       return
       end
