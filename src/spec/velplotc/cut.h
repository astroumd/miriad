	real cmaj,cmin,cpa
	common/cmaj/cmaj,cmin,cpa
	integer ncut
	real xcut(128),ycut(128),pa(128)
	common/cuts/xcut,ycut,pa,ncut
	integer ncon
	real con(99,99,4,4)      ! convolution array maximum size
	real cf
	common/convol/ncon,con,cf
	real cpos(2)
	common/cutreferpos/cpos
