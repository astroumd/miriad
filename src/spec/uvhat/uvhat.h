c----------------------------------------------
c	uvhat.h - include file for uvhat
c  Unix mods nov-90 by Peter Teuben
c
c	27-nov-90   /hash/ -> /comhash/ since subroutine hash also exists
c	 5-feb-91   merged Mel's and Pjt`s version (i.e. real tchan(512))
c

c----------------------------------------------
c --	common blocks for interferometer data record

	common /rawdata/ type,antennas,day80,utin,lstin,unsin,vnsin,
     .		twidein,awidein,correct,tmultin,itchanin
	character*1 type
	integer antennas
	double precision day80,utin,lstin,unsin,vnsin
	real tmultin
	complex twidein(2),awidein(2),correct(2)
	integer*2 itchanin(2,512)

	byte input(2500)
	equivalence (input(1),type)

	real tchan(512)
	equivalence (tchan,itchanin)

c----------------------------------------------------------------
c -- A list of the header variables read by read_data --
c    Filled by readdata, used by write_data which sets hnum to 0
c	(if hnames = " the last valid name is used)

	parameter (ihmax=500)
	character*8 hnames(ihmax)
c					!name of entry
	integer hsubs(ihmax)
c					!subscript of entry
	integer hnum
c					!number of last entry

	common/headlist/hnum, hnames, hsubs
	data hnum /0/

c-----------------------------------------------------------------
c	--common block storage/ used by com... subroutines--

	parameter (maxstore=2000)
	integer istor32(maxstore)
	double precision stor64(maxstore/2-1)
	real stor32(maxstore)
	integer nextopen
	character*(maxstore*4) cstor8
	common/storage/nextopen,stor32
	equivalence(stor64,stor32(2)),(istor32,stor32)
	equivalence(cstor8,stor32)

c	-storage is a free form array used for storage of all common
c	-variables. The hash pointer points to a header word in stor32
c	-which contains max_subscript+100*var_type.  var_type is
c	-'I' for integer*4/ 'R' for real*4/ 'D' for real*8. stor32 is
c	-initialized by comzero.

c--------------------------------------------------------------------
c	--hash table common/used by com... subroutines--

	parameter (maxhash=512)
	character*8 name
	integer*2 pointer
	common/comhash/name(maxhash),pointer(maxhash)
c
c	-name is the name of the parameter occupying that spot in the
c	-hash table and pointer is the index of the header for the
c	-parameter in common /storage/.  The hash function is the sum
c	-of the individual characters mod maxhash and collisions are
c	-handled by trying lower locations until either a match is
c	-made or an empty location is found as evidenced by pointer=0
