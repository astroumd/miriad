c********1*********2*********3*********4*********5*********6*********7*c
c
c  Routines to get values for uv-variables which may not be in uv-data.
c
c  ?? What is the purpose of this routine above uvgetvr(d/r) ???
c
c  varmintr -- real valued uv-variable.
c  varmintd -- double precision uv-variable.
c
c  History:
c    mchw 24jun96
c    pjt  26dec97 better ansi, fixed args in call to uvgetvrd()
c-----------------------------------------------------------------------
c*varmintd -- Get double precision uv-variable.
c:uv-data
c& mchw
c+
	subroutine varmintd(tvis,var,value)
	implicit none
	integer tvis
	character var*(*)
	double precision value
c
c  Get value for uv-variable which may not be in uv-data.
c
c  Input:
c    tvis	Handle of the visibility file.
c    var	The name of the uv-variable.
c  Output:
c    value	The value of the uv-variable.
c--
c-----------------------------------------------------------------------
        character vartype*1, telescop*20,lvar*10
        logical updated,ok
	integer varlen,idata
	double precision obsra,obsdec,lst,latitude
	real ha,sinha,cosha,sind,cosd,sinl,cosl,data
c
c  Get the type and length of the variable to be checked.
c
	call uvprobvr(tvis,var,vartype,varlen,updated)
        if(.not.updated)then
c
c  Calculate the elevation and paralactic angle.
c
	  if(var.eq.'chi')then
            call uvrdvrd(tvis,'obsra',obsra,0.d0)
            call uvrdvrd(tvis,'obsdec',obsdec,0.d0)
            call uvrdvrd(tvis,'lst',lst,0.d0)
            call uvrdvra(tvis,'telescop',telescop,'UNKNOWN')
            call obspar(telescop,'latitude',latitude,ok)
c could also call subroutine parang(obsra,obsdec,lst,latitude,chi)
            ha = lst-obsra
            sinha = sin(ha)
            cosha = cos(ha)
            sind = sin(obsdec)
            cosd = cos(obsdec)
            sinl = sin(latitude)
            cosl = cos(latitude)
            value = atan2(sinha*cosl,sinl*cosd-cosl*sind*cosha)
	  else
            lvar = var
	    call output('unknown variable '//lvar)
	  endif
	else if(updated.and.varlen.eq.1)then
c
c  Get the data
c
          if(vartype.eq.'d') then
            call uvgetvrd(tvis,var,value,1)
          else if(vartype.eq.'r') then
            call uvgetvrr(tvis,var,data,1)
            value=data
          else if(vartype.eq.'i') then
            call uvgetvri(tvis,var,idata,varlen)
            value=idata
          else if(vartype.eq.'a') then
	    call output('unused variable type '//vartype)
          else
	    call output('unknown variable type '//vartype)
          endif
        endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
c*varmintr -- Get real value for uv-variable.
c:uv-data
c& mchw
c+
	subroutine varmintr(tvis,var,value)
	implicit none
	integer tvis
	character var*(*)
	real value
c
c  Get value for real uv-variable which may not be in uv-data.
c
c  Input:
c    tvis	Handle of the visibility file.
c    var	The name of the uv-variable.
c  Output:
c    value	The value of the uv-variable.
c--
c-----------------------------------------------------------------------
        character vartype*1, telescop*20, lvar*10
        logical updated,ok
	integer varlen,idata
	double precision obsra,obsdec,lst,latitude,dvalue
	real ha,sinha,cosha,sind,cosd,sinl,cosl,data
c
c  Get the type and length of the variable to be checked.
c
	call uvprobvr(tvis,var,vartype,varlen,updated)
        if(.not.updated)then
c
c  Calculate the elevation and paralactic angle.
c
	  if(var.eq.'chi')then
            call uvrdvrd(tvis,'obsra',obsra,0.d0)
            call uvrdvrd(tvis,'obsdec',obsdec,0.d0)
            call uvrdvrd(tvis,'lst',lst,0.d0)
            call uvrdvra(tvis,'telescop',telescop,'UNKNOWN')
            call obspar(telescop,'latitude',latitude,ok)
            ha = lst-obsra
            sinha = sin(ha)
            cosha = cos(ha)
            sind = sin(obsdec)
            cosd = cos(obsdec)
            sinl = sin(latitude)
            cosl = cos(latitude)
            value = atan2(sinha*cosl,sinl*cosd-cosl*sind*cosha)
	  else
            lvar = var
	    call output('unknown variable '//lvar)
	  endif
	else if(updated.and.varlen.eq.1)then
c
c  Get the data
c
          if(vartype.eq.'d') then
            call uvgetvrd(tvis,var,dvalue,1)
            value = dvalue
          else if(vartype.eq.'r') then
            call uvgetvrr(tvis,var,data,1)
            value=data
          else if(vartype.eq.'i') then
            call uvgetvri(tvis,var,idata,varlen)
            value=idata
          else if(vartype.eq.'a') then
	    call output('unused variable type '//vartype)
          else
	    call output('unknown variable type '//vartype)
          endif
        endif
c
	end
c********1*********2*********3*********4*********5*********6*********7*c
