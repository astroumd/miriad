C	This header control the plotting enviroment
C	It's good for both implot and velplot

	logical setxy(4)
	common/plotlogical/setxy
	real xyval(4),conargs(50),range(2),datar(2)
	common/plotreal/xyval,conargs,range,datar
	integer annotate,contour,image,windx,windy,boxc,Beam,nconarg
	common/plotinteger/annotate,contour,image,windx,
     &        windy,boxc,Beam,nconarg
	character conflag*10,Units_p*1,boxa*10
	common/plotcharacter/conflag,Units_p,boxa
	
	character itask*1
	common/itask/itask
	real Vrest
	common/Vrest/Vrest
	integer grid
	common/grid/grid

	logical animate,do_animation
	common/animation/animate,do_animation
