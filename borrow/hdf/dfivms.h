/*****************************************************************************
* 
*			  NCSA HDF version 3.10r2
*				Sept 20, 1990
*
* NCSA HDF Version 3.10r2 source code and documentation are in the public
* domain.  Specifically, we give to the public domain all rights for future
* licensing of the source code, all resale rights, and all publishing rights.
* 
* We ask, but do not require, that the following message be included in all
* derived works:
* 
* Portions developed at the National Center for Supercomputing Applications at
* the University of Illinois at Urbana-Champaign.
* 
* THE UNIVERSITY OF ILLINOIS GIVES NO WARRANTY, EXPRESSED OR IMPLIED, FOR THE
* SOFTWARE AND/OR DOCUMENTATION PROVIDED, INCLUDING, WITHOUT LIMITATION,
* WARRANTY OF MERCHANTABILITY AND WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE
* 
*****************************************************************************/

#define DFANIaddentry(type, annref, datatag, dataref) \
        _DFANIaddentry(type, annref, datatag, dataref)
#define DFANIgetann(filename, tag, ref, ann, maxlen, type)  \
        _DFANIgetann(filename, tag, ref, ann, maxlen, type)
#define DFANIgetannlen(filename, tag, ref, type)  \
        _DFANIgetannlen(filename, tag, ref, type)
#define DFANIlablist(filename, tag, reflist, labellist, listsize, maxlen,  \
                                                        startpos, isfortran) \
        _DFANIlablist(filename, tag, reflist, labellist, listsize, maxlen, \
                                                        startpos, isfortran)
#define DFANIlocate(dfile, type, tag, ref)  \
        _DFANIlocate(dfile, type, tag, ref)
#define DFANIopen(filename, access)  \
        _DFANIopen(filename, access)
#define DFANIputann(filename, tag, ref, ann, annlen, type)  \
        _DFANIputann(filename, tag, ref, ann, annlen, type)
#define DFANgetdesc(filename, tag, ref, desc, maxlen)  \
        _DFANgetdesc(filename, tag, ref, desc, maxlen)
#define DFANgetdesclen(filename, tag, ref)  \
        _DFANgetdesclen(filename, tag, ref)
#define DFANgetlabel(filename, tag, ref, label, maxlen)  \
        _DFANgetlabel(filename, tag, ref, label, maxlen)
#define DFANgetlablen(filename, tag, ref)  \
        _DFANgetlablen(filename, tag, ref)
#define DFANlablist(filename,tag,reflist,labellist,listsize,maxlen,startpos)  \
        _DFANlablist(filename,tag, reflist,labellist, listsize,maxlen,startpos)
#define DFANlastref()  \
        _DFANlastref()
#define DFANputdesc(filename, tag, ref, desc, desclen)  \
        _DFANputdesc(filename, tag, ref, desc, desclen)
#define DFANputlabel(filename, tag, ref, label)  \
        _DFANputlabel(filename, tag, ref, label)
#define DFANaddfid \
	_DFANaddfid
#define DFANgetfidlen \
    	_DFANgetfidlen
#define DFANgetfid \
	_DFANgetfid
#define DFANgetfdslen \
	_DFANgetfdslen
#define DFANgetfds \
	_DFANgetfds
#define DFANaddfds(dfile, desc, desclen) \
	_DFANaddfds(dfile, desc, desclen)
/*
#define DFCVieeeF2unicosF(ieee_fp, cray_fp) \
        _DFCVieeeF2unicosF(ieee_fp, cray_fp)
#define DFCVieeeF2vaxF(in, out)  \
        _DFCVieeeF2vaxF(in, out)
#define DFCVunicosF2ieeeF(cray_fp, ieee_fp) \
        _DFCVunicosF2ieeeF(cray_fp, ieee_fp)
#define DFCVvaxF2ieeeF(in, out)  \
        _DFCVvaxF2ieeeF(in, out)
*/
#define DFCimcomp(xdim, ydim, in, out, in_pal, out_pal, mode) \
        _DFCimcomp(xdim, ydim, in, out, in_pal, out_pal, mode)
#define DFCrle(buf,bufto,len)  \
        _DFCrle(buf,bufto,len)
#define DFCunimcomp(xdim, ydim, in, out)  \
        _DFCunimcomp(xdim, ydim, in, out)
#define DFCunrle(buf,bufto,outlen, resetsave)  \
        _DFCunrle(buf,bufto,outlen, resetsave)
#define DFDIgetgroup(filename, diarray, maxdis, groupdi)  \
        _DFDIgetgroup(filename, diarray, maxdis, groupdi)
#define DFDIputgroup(filename, diarray, ndis, groupdi)  \
        _DFDIputgroup(filename, diarray, ndis, groupdi)
#define DFIc2fstr(str, len)  \
        _DFIc2fstr(str, len)
#define DFIcheck(dfile)  \
        _DFIcheck(dfile)
#define DFIemptyDD(dfile)  \
        _DFIemptyDD(dfile)
#define DFIerr(dfile)  \
        _DFIerr(dfile)
#define DFIf2cstring(filename, flen)  \
        _DFIf2cstring(filename, flen)
#define DFIfind( dfile, tag, ref, isfirst, ltag, lref, cDLEp, cddp)  \
        _DFIfind( dfile, tag, ref, isfirst, ltag, lref, cDLEp, cddp)
#define DFIfreespace(ptr)  \
        _DFIfreespace(ptr)
#define DFIgetspace(qty)  \
        _DFIgetspace(qty)
#define DFImemcopy(from, to, length)  \
        _DFImemcopy(from, to, length)
#define DFIseedDDs(dfile)  \
        _DFIseedDDs(dfile)
#define DFIstrncpy(dest, source, len)  \
        _DFIstrncpy(dest, source, len)
#define DFPIopen(filename, access)  \
        _DFPIopen(filename, access)
#define DFPgetpal(filename, palette)  \
        _DFPgetpal(filename, palette)
#define DFPlastref()  \
        _DFPlastref()
#define DFPnpals(filename)  \
        _DFPnpals(filename)
#define DFPputpal(filename, palette, overwrite, filemode)  \
        _DFPputpal(filename, palette, overwrite, filemode)
#define DFPaddpal _DFPaddpal
#define DFPreadref(filename, ref)  \
        _DFPreadref(filename, ref)
#define DFPrestart()  \
        _DFPrestart()
#define DFPwriteref(filename, ref)  \
        _DFPwriteref(filename, ref)
#define DFR8Iopen(filename, access)  \
        _DFR8Iopen(filename, access)
#define DFR8Iputimage(filename, image, xdim, ydim, compress, op)  \
        _DFR8Iputimage(filename, image, xdim, ydim, compress, op)
#define DFR8Iriginfo(dfile)  \
        _DFR8Iriginfo(dfile)
#define DFR8addimage(filename, image, xdim, ydim, compress)  \
        _DFR8addimage(filename, image, xdim, ydim, compress)
#define DFR8getdims(filename, pxdim, pydim, pispal)  \
        _DFR8getdims(filename, pxdim, pydim, pispal)
#define DFR8getimage(filename, image, xdim, ydim, pal)  \
        _DFR8getimage(filename, image, xdim, ydim, pal)
#define DFR8getrig(dfile, ref, rig)  \
        _DFR8getrig(dfile, ref, rig)
#define DFR8lastref()  \
        _DFR8lastref()
#define DFR8nimages(filename)  \
        _DFR8nimages(filename)
#define DFR8putimage(filename, image, xdim, ydim, compress)  \
        _DFR8putimage(filename, image, xdim, ydim, compress)
#define DFR8putrig(dfile, ref, rig, wdim)  \
        _DFR8putrig(dfile, ref, rig, wdim)
#define DFR8readref(filename, ref)  \
        _DFR8readref(filename, ref)
#define DFR8restart()  \
        _DFR8restart()
#define DFR8setpalette(pal)  \
        _DFR8setpalette(pal)
#define DFR8writeref(filename, ref)  \
        _DFR8writeref(filename, ref)
#define DFSDIclear(sdg)  \
        _DFSDIclear(sdg)
#define DFSDIgetdata(filename, rank, maxsizes, data, isfortran)  \
        _DFSDIgetdata(filename, rank, maxsizes, data, isfortran)
#define DFSDIgetslice(filename, winst, windims, data, dims, isfortran)  \
        _DFSDIgetslice(filename, winst, windims, data, dims, isfortran)
#define DFSDIopen(filename, access)  \
        _DFSDIopen(filename, access)
#define DFSDIputdata(filename, rank, dimsizes, data, accmode, isfortran)  \
        _DFSDIputdata(filename, rank, dimsizes, data, accmode, isfortran)
#define DFSDIputslice(windims, data, dims, isfortran)  \
        _DFSDIputslice(windims, data, dims, isfortran)
#define DFSDIsdginfo(dfile)  \
        _DFSDIsdginfo(dfile)
#define DFSDadddata(filename, rank, dimsizes, data)  \
        _DFSDadddata(filename, rank, dimsizes, data)
#define DFSDclear()  \
        _DFSDclear()
#define DFSDendslice()  \
        _DFSDendslice()
#define DFSDgetdata(filename, rank, maxsizes, data)  \
        _DFSDgetdata(filename, rank, maxsizes, data)
#define DFSDgetdatalen(llabel, lunit, lformat, lcoordsys)  \
        _DFSDgetdatalen(llabel, lunit, lformat, lcoordsys)
#define DFSDgetdatastrs(label, unit, format, coordsys)  \
        _DFSDgetdatastrs(label, unit, format, coordsys)
#define DFSDgetdimlen(dim, llabel, lunit, lformat)  \
        _DFSDgetdimlen(dim, llabel, lunit, lformat)
#define DFSDgetdims(filename, prank, sizes, maxrank)  \
        _DFSDgetdims(filename, prank, sizes, maxrank)
#define DFSDgetdimscale(dim, maxsize, scale)  \
        _DFSDgetdimscale(dim, maxsize, scale)
#define DFSDgetdimstrs(dim, label, unit, format)  \
        _DFSDgetdimstrs(dim, label, unit, format)
#define DFSDgetmaxmin(pmax, pmin)  \
        _DFSDgetmaxmin(pmax, pmin)
#define DFSDgetsdg(dfile, ref, sdg)  \
        _DFSDgetsdg(dfile, ref, sdg)
#define DFSDgetslice(filename, winst, windims, data, dims)  \
        _DFSDgetslice(filename, winst, windims, data, dims)
#define DFSDlastref()  \
        _DFSDlastref()
#define DFSDnumber(filename)  \
        _DFSDnumber(filename)
#define DFSDputdata(filename, rank, dimsizes, data)  \
        _DFSDputdata(filename, rank, dimsizes, data)
#define DFSDputsdg(dfile, ref, sdg)  \
        _DFSDputsdg(dfile, ref, sdg)
#define DFSDputslice(windims, data, dims)  \
        _DFSDputslice(windims, data, dims)
#define DFSDrestart()  \
        _DFSDrestart()
#define DFSDsetdatastrs(label, unit, format, coordsys)  \
        _DFSDsetdatastrs(label, unit, format, coordsys)
#define DFSDsetdims(rank, dimsizes)  \
        _DFSDsetdims(rank, dimsizes)
#define DFSDsetdimscale(dim, dimsize, scale)  \
        _DFSDsetdimscale(dim, dimsize, scale)
#define DFSDsetdimstrs(dim, label, unit, format)  \
        _DFSDsetdimstrs(dim, label, unit, format)
#define DFSDsetlengths(maxlen_label,maxlen_unit,maxlen_format,maxlen_coordsys) \
        _DFSDsetlengths(maxlen_label,maxlen_unit,maxlen_format,maxlen_coordsys)
#define DFSDsetmaxmin(max, min)  \
        _DFSDsetmaxmin(max, min)
#define DFSDsettype(datatype, machinetype, numbertype, arrayorder)  \
        _DFSDsettype(datatype, machinetype, numbertype, arrayorder)
#define DFSDstartslice(filename)  \
        _DFSDstartslice(filename)
#define DFSDreadref _DFSDreadref
#define DFaccess(dfile, tag, ref, access)  \
        _DFaccess(dfile, tag, ref, access)
#define DFclose(dfile)  \
        _DFclose(dfile)
/*
#define DFconvert(source, dest, ntype, sourcetype, desttype)  \
        _DFconvert(source, dest, ntype, sourcetype, desttype)
	*/
#define DFdel(dfile, tag, ref)  \
        _DFdel(dfile, tag, ref)
#define DFdescriptors(dfile, ptr, begin, num)  \
        _DFdescriptors(dfile, ptr, begin, num)
#define DFdiget(di)  \
        _DFdiget(di)
#define DFdiput(tag, ref)  \
        _DFdiput(tag, ref)
#define DFdiread(dfile, tag, ref)  \
        _DFdiread(dfile, tag, ref)
#define DFdisetup(maxsize)  \
        _DFdisetup(maxsize)
#define DFdiwrite(dfile, tag, ref)  \
        _DFdiwrite(dfile, tag, ref)
#define DFdup(dfile, itag, iref, otag, oref)  \
        _DFdup(dfile, itag, iref, otag, oref)
#define DFerrno()  \
        _DFerrno()
#define DFfind(dfile, ptr)  \
        _DFfind(dfile, ptr)
#define DFgetcomp(dfile, tag, ref, image, xdim, ydim, scheme)  \
        _DFgetcomp(dfile, tag, ref, image, xdim, ydim, scheme)
#define DFgetelement( dfile, tag, ref, ptr)  \
        _DFgetelement( dfile, tag, ref, ptr)
#define DFishdf(filename)  \
        _DFishdf(filename)
#define DFnewref(dfile)  \
        _DFnewref(dfile)
#define DFnumber(dfile, tag)  \
        _DFnumber(dfile, tag)
#define DFopen(name, access, ndds )  \
        _DFopen(name, access, ndds )
#define DFputcomp(dfile, tag, ref, image, xdim, ydim, palette,newpal,scheme)  \
        _DFputcomp(dfile, tag, ref, image, xdim, ydim, palette,newpal,scheme)
#define DFputelement( dfile, tag, ref, ptr, len)  \
        _DFputelement( dfile, tag, ref, ptr, len)
#define DFread(dfile, ptr, len)  \
        _DFread(dfile, ptr, len)
#define DFseek(dfile, offset)  \
        _DFseek(dfile, offset)
#define DFsetfind(dfile, tag, ref)  \
        _DFsetfind(dfile, tag, ref)
#define DFstart(dfile, tag, ref, access)  \
        _DFstart(dfile, tag, ref, access)
#define DFstat(dfile, dfinfo)  \
        _DFstat(dfile, dfinfo)
#define DFupdate(dfile)  \
        _DFupdate(dfile)
#define DFwrite(dfile, ptr, len)  \
        _DFwrite(dfile, ptr, len)
#define DFfindnextref(dfile, tag, lref) \
	_DFfindnextref(dfile, tag, lref)
#define DF24addimage(filename, image, xdim, ydim) \
        _DF24addimage(filename, image, xdim, ydim)
#define DF24getdims(filename, pxdim, pydim, pil) \
        _DF24getdims(filename, pxdim, pydim, pil)
#define DF24getimage(filename, image, xdim, ydim) \
        _DF24getimage(filename, image, xdim, ydim)
#define DF24reqil(il) \
        _DF24reqil(il)
#define DF24setdims(xdim, ydim) \
        _DF24setdims(xdim, ydim)
#define DF24setil(il) \
	_DF24setil(il)
#define DF24restart \
	_DF24restart
#define DF24readref _DF24readref
#define DFGRIaddimlut(filename, imlut, xdim, ydim, type, isfortran) \
        _DFGRIaddimlut(filename, imlut, xdim, ydim, type, isfortran)
#define DFGRIgetdims(filename, pxdim, pydim, pncomps, pil, type) \
        _DFGRIgetdims(filename, pxdim, pydim, pncomps, pil, type)
#define DFGRIgetimlut(filename, imlut, xdim, ydim, type, isfortran) \
        _DFGRIgetimlut(filename, imlut, xdim, ydim, type, isfortran)
#define DFGRIopen(filename, access) \
        _DFGRIopen(filename, access)
#define DFGRIreqil(il, type) \
        _DFGRIreqil(il, type)
#define DFGRIriginfo(dfile) \
        _DFGRIriginfo(dfile)
/*
#define DFGRIsetdims(xdim, ydim, ncomps, il, type) \
        _DFGRIsetdims(xdim, ydim, ncomps, il, type)
	*/
#define DFGRaddimage(filename, image, xdim, ydim) \
        _DFGRaddimage(filename, image, xdim, ydim)
#define DFGRaddlut(filename, lut, xdim, ydim) \
        _DFGRaddlut(filename, lut, xdim, ydim)
#define DFGRaddrig(dfile, ref, rig) \
        _DFGRaddrig(dfile, ref, rig)
#define DFGRgetimage(filename, image, xdim, ydim) \
        _DFGRgetimage(filename, image, xdim, ydim)
#define DFGRgetimdims(filename, pxdim, pydim, pncomps, pil) \
        _DFGRgetimdims(filename, pxdim, pydim, pncomps, pil)
#define DFGRgetlut(filename, lut, xdim, ydim) \
        _DFGRgetlut(filename, lut, xdim, ydim)
#define DFGRgetlutdims(filename, pxdim, pydim, pncomps, pil) \
        _DFGRgetlutdims(filename, pxdim, pydim, pncomps, pil)
#define DFGRgetrig(dfile, ref, rig) \
        _DFGRgetrig(dfile, ref, rig)
#define DFGRreqimil(il) \
        _DFGRreqimil(il)
#define DFGRreqlutil(il) \
        _DFGRreqlutil(il)
#define DFGRsetcompress(scheme) \
        _DFGRsetcompress(scheme)
#define DFGRsetimdims(xdim, ydim, ncomps, il) \
        _DFGRsetimdims(xdim, ydim, ncomps, il)
#define DFGRsetlut(lut, xdim, ydim) \
        _DFGRsetlut(lut, xdim, ydim)
#define DFGRsetlutdims(xdim, ydim, ncomps, il) \
        _DFGRsetlutdims(xdim, ydim, ncomps, il)
#define DFUfptoimage _DFUfptoimage
