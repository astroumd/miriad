import miriad_io
try :
    import mxTools as mx
except ImportError:
    msg = "This package requires the use of the mx package which can be located in the $MIR/scripts/python/mx\n"
    msg += "Please install it and try importing the wrappers again"
    raise Exception,msg

import time
"""
Module to wrap basic miriad IO routines into python
Author: D. N. Friedel
"""

MAXCHAN = 4096
MAXIMG = 65536
MAXNAX = 7
MAXSRC = 100
MAXANT = 64
MAXBASE = 501
MAXPOL = 4

print "Note: This wrapper package has a disclaimer. Type <m>.disclaimer() (where <m> is the name used for importing this module) to read it."

def disclaimer() :
    print "The following disclaimers are given for these wrappers:"
    print "1. Not all of these ~730 wrappers have been tested and thus may not work as expected"
    print "2. Specific subroutines have not been included:"
    print "    a. those dealing directly with pgplot"
    print "    b. those that take external functions as arguments"
    print "    c. those for which the input/output arguments were poorly/not documented"
    print "    d. sma subroutines"
    print "    e. string and i/o manipulation since python has built in functions to do this already"
    print "    f. text file i/o routines as python can do this itself"
    print "    g. matrix manipulation as the numpy and numarray python modules do this quite well"
    print "Feel free to add/edit these wrappers to correct any of the above issues"

def castLogical(item) :
    """ Method to convert a list of 1/0 to True/False
        input :
            item - a list of 1/0 values, or a single 1/0
        returns :
            a list of True/False values or a single True/False, depending on input
    """
    if(isinstance(item,list)) :
        a = []
        for i in item :
            if(i != 0) :
                a.append(True)
            else :
                a.append(False)
        return a
    if(item != 0) :
        return True
    return False

def uncastLogical(item) :
    """ Method to convert a list of True/False to 1/0
        input :
            item - a list of True/False values or a single True/False
        returns :
            a list of 1/0 values, or a single 1/0, depending on input
    """
    if(isinstance(item,list)) :
        a = []
        for i in item:
            if(i) :
                a.append(1)
            else :
                a.append(0)
        return a
    if(item) :
        return [1]
    return [0]

def doubleArrayToList(array,w,x=0,y=0,z=0) :
    """ Method to convert a C array of double values to a list
        input :
            array - the array pointer
            w - the length of the first dimension
            x,y,z - length of the other dimensions
        returns :
            a list of floats with equal dimension to the input array
    """
    alist = []
    #print array
    if(x == 0) :
        for i in range(0,w) :
            #print i,array[i]
            alist.append(float(array[i]))
        return alist
    if(y == 0) :
        for i in range(0,x) :
            row = []
            for j in range(0,w):
                row.append(float(array[(i*w) + j]))
            alist.append(row)
        return alist
    if(z == 0) :
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w):
                    row.append(float(array[(k*x*w)+(i*w) + j]))
                temp.append(row)
            alist.append(temp)
        return alist
    for l in range(0,z) :
        ttemp = []
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w):
                    row.append(float(array[(l*y*x*w) +(k*x*w)+(i*w) + j]))
                temp.append(row)
            ttemp.append(temp)
        alist.append(ttemp)
    return alist

def floatArrayToList(array,w,x=0,y=0,z=0) :
    """ Method to convert a C array of float values to a list
        input :
            array - the array pointer
            w - the length of the first dimension
            x,y,z - length of the other dimensions
        returns :
            a list of floats with equal dimension to the input array
    """
    return doubleArrayToList(array,w,x,y,z)

def intArrayToList(array,w,x=0,y=0,z=0) :
    """ Method to convert a C array of integer values to a list
        input :
            array - the array pointer
            w - the length of the first dimension
            x,y,z - length of the other dimensions
        returns :
            a list of integers of equal dimension to the input array
    """
    alist = []
    if(x == 0) :
        for i in range(0,w) :
            alist.append(int(array[i]))
        return alist
    if(y == 0) :
        for i in range(0,x) :
            row = []
            for j in range(0,w):
                row.append(int(array[(i*w) + j]))
            alist.append(row)
        return alist
    if(z == 0) :
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w):
                    row.append(int(array[(k*x*w)+(i*w) + j]))
                temp.append(row)
            alist.append(temp)
        return alist
    for l in range(0,z) :
        ttemp = []
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for j in range(0,w):
                    row.append(int(array[(l*y*x*w) +(k*x*w)+(i*w) + j]))
                temp.append(row)
            ttemp.append(temp)
        alist.append(ttemp)
    return alist

def complexArrayToList(array,w,x=0,y=0,z=0) :
    """ Method to convert a C array of float values to a list of complex values
        input :
            array - the array pointer
            w - the length of the first dimension
            x,y,z - length of the other dimensions
        returns :
            a list of complex values (length is half that of the input w) the other dimensions are the same as the input array
    """
    alist = []
    if(x == 0) :
        for i in range(0,w,2) :
            alist.append(complex(array[i],array[i+1]))
        return alist
    if(y == 0) :
        for i in range(0,x) :
            row = []
            for j in range(0,w,2):
                row.append(complex(array[(i*w) + j],array[(i*w) + j + 1]))
            alist.append(row)
        return alist
    if(z == 0) :
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w,2):
                    row.append(complex(array[(k*x*w)+(i*w) + j],array[(k*x*w)+(i*w) + j + 1]))
                temp.append(row)
            alist.append(temp)
        return alist
    for l in range(0,z) :
        ttemp = []
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w,2):
                    row.append(complex(array[(l*y*x*w) +(k*x*w)+(i*w) + j],array[(l*y*x*w) +(k*x*w)+(i*w) + j + 1]))
                temp.append(row)
            ttemp.append(temp)
        alist.append(ttemp)
    return alist

def complexListToArray(list) :
    """ Method to convert a list of complex values to an array of floats
        input :
            list - the list of complex values
        returns :
            an array of floats (length is two times that of the input)
    """
    length = len(list)
    array = miriad_io.doubleArray(2*length)
    for i in range(0,2*length,2) :
        array[i] = list[i/2].real
        array[i+1] = list[i/2].imag
    return array

def doubleListToArray(alist) :
    """ Method to convert a list of doubles to a C array (flattens multiple dimensions into 1)
        input :
            alist - the list of double values
        returns :
            an array pointer to the array of doubles
    """
    if(not isinstance(alist[0],list)) :
        length = len(alist)
        array = miriad_io.doubleArray(length)
        for i in range(0,length) :
            array[i] = alist[i]
        return array
    if(not isinstance(alist[0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        array = miriad_io.doubleArray(length*length1)
        for i in range(0,length) :
            for j in range(0,length1) :
                array[(i*length1) + j] = alist[i][j]
        return array
    if(not isinstance(alist[0][0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        length2 = len(alist[0][0])
        array = miriad_io.doubleArray(length*length1*length2)
        for i in range(0,length) :
            for j in range(0,length1) :
                for k in range(0,length2) :
                    array[(i*length1*length2) + (j * length2) + k] = alist[i][j][k]
        return array
    length = len(alist)
    length1 = len(alist[0])
    length2 = len(alist[0][0])
    length3 = len(alist[0][0][0])
    array = miriad_io.doubleArray(length*length1*length2*length3)
    for i in range(0,length) :
        for j in range(0,length1) :
            for k in range(0,length2) :
                for l in range(0,length3) :
                    array[(i*length1*length2*length3) + (j * length2*length3) + (k * length3) + l] = alist[i][j][k][l]
    return array

def intListToArray(alist,length = 0) :
    """ Method to convert a list of integers to a C array (flattens multiple dimensions into 1)
        input :
            list - the list of integers values
            length - the length of the list (or subset thereof)
        returns :
            an array pointer to the array of integers
    """
    if(not isinstance(alist[0],list)) :
        if(length == 0) :
            length = len(alist)
        array = miriad_io.intArray(length)
        for i in range(0,length) :
            array[i] = alist[i]
        return array
    if(not isinstance(alist[0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        array = miriad_io.intArray(length*length1)
        for i in range(0,length) :
            for j in range(0,length1) :
                array[(i*length1) + j] = alist[i][j]
        return array
    if(not isinstance(alist[0][0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        length2 = len(alist[0][0])
        array = miriad_io.intArray(length*length1*length2)
        for i in range(0,length) :
            for j in range(0,length1) :
                for k in range(0,length2) :
                    array[(i*length1*length2) + (j * length2) + k] = alist[i][j][k]
        return array
    length = len(alist)
    length1 = len(alist[0])
    length2 = len(alist[0][0])
    length3 = len(alist[0][0][0])
    array = miriad_io.intArray(length*length1*length2*length3)
    for i in range(0,length) :
        for j in range(0,length1) :
            for k in range(0,length2) :
                for l in range(0,length3) :
                    array[(i*length1*length2*length3) + (j * length2*length3) + (k * length3) + l] = alist[i][j][k][l]
    return array

def floatListToArray(alist) :
    """ Method to convert a list of floats to a C array (flattens multiple dimensions into 1)
        input :
            list - the list of float values
        returns :
            an array pointer to the array of floats
    """
    if(not isinstance(alist[0],list)) :
        length = len(alist)
        array = miriad_io.floatArray(length)
        for i in range(0,length) :
            array[i] = alist[i]
        return array
    if(not isinstance(alist[0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        array = miriad_io.floatArray(length*length1)
        for i in range(0,length) :
            for j in range(0,length1) :
                array[(i*length1) + j] = alist[i][j]
        return array
    if(not isinstance(alist[0][0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        length2 = len(alist[0][0])
        array = miriad_io.floatArray(length*length1*length2)
        for i in range(0,length) :
            for j in range(0,length1) :
                for k in range(0,length2) :
                    array[(i*length1*length2) + (j * length2) + k] = alist[i][j][k]
        return array
    length = len(alist)
    length1 = len(alist[0])
    length2 = len(alist[0][0])
    length3 = len(alist[0][0][0])
    array = miriad_io.floatArray(length*length1*length2*length3)
    for i in range(0,length) :
        for j in range(0,length1) :
            for k in range(0,length2) :
                for l in range(0,length3) :
                    array[(i*length1*length2*length3) + (j * length2*length3) + (k * length3) + l] = alist[i][j][k][l]
    return array

def FcomplexListToArray(alist) :
    """ Method to convert a list of complex values to a C/Fortran array (flattens multiple dimensions into 1)
        input :
            list - the list of float values
        returns :
            an array pointer to the array of complex values
    """
    if(not isinstance(alist[0],list)) :
        length = len(alist)
        array = miriad_io.FcomplexArray(length)
        for i in range(0,length) :
            array[i].r = alist[i].real
            array[i].i = alist[i].imag
        return array
    if(not isinstance(alist[0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        array = miriad_io.FcomplexArray(length*length1)
        for i in range(0,length) :
            for j in range(0,length1) :
                array[(i*length1) + j].r = alist[i][j].real
                array[(i*length1) + j].i = alist[i][j].imag
        return array
    if(not isinstance(alist[0][0][0],list)) :
        length = len(alist)
        length1 = len(alist[0])
        length2 = len(alist[0][0])
        array = miriad_io.FcomplexArray(length*length1*length2)
        for i in range(0,length) :
            for j in range(0,length1) :
                for k in range(0,length2) :
                    array[(i*length1*length2) + (j * length2) + k].r = alist[i][j][k].real
                    array[(i*length1*length2) + (j * length2) + k].i = alist[i][j][k].imag
        return array
    length = len(alist)
    length1 = len(alist[0])
    length2 = len(alist[0][0])
    length3 = len(alist[0][0][0])
    array = miriad_io.FcomplexArray(length*length1*length2*length3)
    for i in range(0,length) :
        for j in range(0,length1) :
            for k in range(0,length2) :
                for l in range(0,length3) :
                    array[(i*length1*length2*length3) + (j * length2*length3) + (k * length3) + l].r = alist[i][j][k][l].real
                    array[(i*length1*length2*length3) + (j * length2*length3) + (k * length3) + l].i = alist[i][j][k][l].imag
    return array

def FcomplexArrayToList(array,w,x=0,y=0,z=0) :
    """ Method to convert a C/Fortran array of complex values to a list of python complex values
        input :
            array - the array pointer
            w - the length of the first dimension
            x,y,z - length of the other dimensions
        returns :
            a list of complex values the dimensions are the same as the input array
    """
    alist = []
    if(x == 0) :
        for i in range(0,w) :
            alist.append(complex(array[i].r,array[i].i))
        return alist
    if(y == 0) :
        for i in range(0,x) :
            row = []
            for j in range(0,w):
                row.append(complex(array[(i*w) + j].r,array[(i*w) + j].i))
            alist.append(row)
        return alist
    if(z == 0) :
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w):
                    row.append(complex(array[(k*x)+(i*w) + j].r,array[(k*x)+(i*w) + j].i))
                temp.append(row)
            alist.append(temp)
        return alist
    for l in range(0,z) :
        ttemp = []
        for k in range(0,y) :
            temp = []
            for i in range(0,x) :
                row = []
                for y in range(0,w):
                    row.append(complex(array[(l*y) +(k*x)+(i*w) + j].r,array[(l*y) +(k*x)+(i*w) + j].i))
                temp.append(row)
            ttemp.append(temp)
        alist.append(ttemp)
    return alist

def convertComplex(item) :
    """ Method to convert python complex to C/Fotran complex
        input :
            item - the python complex item
        returns :
            the C/Fortran complex item
    """
    cmplx = miriad_io.Complex()
    cmplx.r = item.real
    cmplx.i = item.imag
    return cmplx
    #miriad_io.Complex(item.real,item.imag)

def unconvertComplex(item) :
    """ Method to convert C/Fortran complex to python complex
        input :
            item - the C/Fortran complex item
        returns :
            the python complex item
    """
    return complex(item.r,item.i)

def intArray(w,x=0,y=0,z=0) :
    """ Method to create an integer array (flattens multiple dimensions to 1)
        inputs :
            w,x,y,z - the dimensions of the array
        returns :
            C array of requested size
    """
    return miriad_io.intArray(max(w,w*x,w*x*y,w*x*y*z))

def floatArray(w,x=0,y=0,z=0) :
    """ Method to create a float array (flattens multiple dimensions to 1)
        inputs :
            w,x,y,z - the dimensions of the array
        returns :
            C array of requested size
    """
    return miriad_io.floatArray(max(w,w*x,w*x*y,w*x*y*z))

def doubleArray(w,x=0,y=0,z=0) :
    """ Method to create a double array (flattens multiple dimensions to 1)
        inputs :
            w,x,y,z - the dimensions of the array
        returns :
            C array of requested size
    """

    return miriad_io.doubleArray(max(w,w*x,w*x*y,w*x*y*z))

def FcomplexArray(w,x=0,y=0,z=0) :
    """ Method to create a C/Fortran complex array (flattens multiple dimensions to 1)
        inputs :
            w,x,y,z - the dimensions of the array
        returns :
            C array of requested size
    """
    return miriad_io.FcomplexArray(max(w,w*x,w*x*y,w*x*y*z))

def checkAlpha(string) :
    len1 = len(string)
    while(True) :
        for i in string :
            if(not (i.isalnum() or "." in i or "/" in i or "\\" in i or "=" in i or "+" in i or "!" in i or "*" in i or "&" in i or "-" in i)) :
                string = string.replace(i,"")
                break
        len2 = len(string)
        if(len1 == len2) :
            break
        len1 = len2
    return string

# The following wrappers are for those functions defined in Fortran (those in C are below)

def alignini(lmodel,lmap,mmap,nmap,omap) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lmodel -
            lmap -
            mmap -
            nmap -
            omap -
        returns :   (as a tuple)
            xoff -
            yoff -
            zoff -
    """
    lmodelX = miriad_io.copy_intp(lmodel)
    lmapX = miriad_io.copy_intp(lmap)
    mmapX = miriad_io.copy_intp(mmap)
    nmapX = miriad_io.copy_intp(nmap)
    omapX = miriad_io.copy_intp(omap)
    xoffX = miriad_io.new_intp()
    yoffX = miriad_io.new_intp()
    zoffX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.alignini_,(lmodelX,lmapX,mmapX,nmapX,omapX,xoffX,yoffX,zoffX))
        del XX
    except :
        pass
    xoffR = miriad_io.intp_value(xoffX)
    yoffR = miriad_io.intp_value(yoffX)
    zoffR = miriad_io.intp_value(zoffX)
    return xoffR,yoffR,zoffR

def alignget(lmodel,runs,nruns,k,ioff,joff,koff,n1,n2,n3,maxdata) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lmodel -
            runs -
            nruns -
            k -
            ioff -
            joff -
            koff -
            n1 -
            n2 -
            n3 -
            maxdata -
        returns :   (as a tuple)
            data -
    """
    lmodelX = miriad_io.copy_intp(lmodel)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    kX = miriad_io.copy_intp(k)
    ioffX = miriad_io.copy_intp(ioff)
    joffX = miriad_io.copy_intp(joff)
    koffX = miriad_io.copy_intp(koff)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    n3X = miriad_io.copy_intp(n3)
    dataX = floatArray(maxdata)
    maxdataX = miriad_io.copy_intp(maxdata)
    ndataX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.alignget_,(lmodelX,runsX,nrunsX,kX,ioffX,joffX,koffX,n1X,n2X,n3X,dataX,maxdataX,ndataX))
        del XX
    except :
        pass
    del runsX
    ndataR = miriad_io.intp_value(ndataX)
    dataR = floatArrayToList(dataX,ndataR)
    del dataX
    return dataR

def amphase(data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            data -
        returns :   (as a tuple)
            amp -
            phase -
    """
    dataX = miriad_io.copy_Fcomplexp(convertComplex(data))
    ampX = miriad_io.new_floatp()
    phaseX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.amphase_,(dataX,ampX,phaseX))
        del XX
    except :
        pass
    ampR = miriad_io.floatp_value(ampX)
    phaseR = miriad_io.floatp_value(phaseX)
    return ampR,phaseR

def antmask(maxant,nant1,nant2,ant1,ant2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            maxant -
            nant1 -
            nant2 -
            ant1 -
            ant2 -
        returns :   (as a tuple)
            blmask -
    """
    maxantX = miriad_io.copy_intp(maxant)
    nant1X = miriad_io.copy_intp(nant1)
    nant2X = miriad_io.copy_intp(nant2)
    ant1X = intListToArray(ant1)
    ant2X = intListToArray(ant2)
    blmaskX = intArray((maxant*(maxant-1))/2)
    try :
        XX = mx.safecall(miriad_io.antmask_,(maxantX,nant1X,nant2X,ant1X,ant2X,blmaskX))
        del XX
    except :
        pass
    del ant1X
    del ant2X
    blmaskR = castLogical(intArrayToList(blmaskX,(maxant*(maxant-1))/2))
    del blmaskX
    return blmaskR

def antind(maxant,a1,a2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            maxant -
            a1 -
            a2 -
        returns :   (as a tuple)
            idx -
    """
    maxantX = miriad_io.copy_intp(maxant)
    a1X = miriad_io.copy_intp(a1)
    a2X = miriad_io.copy_intp(a2)
    idxX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.antind_,(maxantX,a1X,a2X,idxX))
        del XX
    except :
        pass
    idxR = miriad_io.intp_value(idxX)
    return idxR

def assertl(cond,mesg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            cond -
            mesg -
        returns :   (as a tuple)
    """
    condX = miriad_io.copy_intp(uncastLogical(cond))
    try :
        XX = mx.safecall(miriad_io.assertl_,(condX,mesg,len(mesg)))
        del XX
    except :
        pass

def assertf(name,cond,mesg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            cond -
            mesg -
        returns :   (as a tuple)
    """
    condX = miriad_io.copy_intp(uncastLogical(cond))
    try :
        XX = mx.safecall(miriad_io.assertf_,(name,condX,mesg,len(name),len(mesg)))
        del XX
    except :
        pass

def asserti2(i1,i2,mesg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i1 -
            i2 -
            mesg -
        returns :   (as a tuple)
    """
    i1X = miriad_io.copy_intp(i1)
    i2X = miriad_io.copy_intp(i2)
    try :
        XX = mx.safecall(miriad_io.asserti2_,(i1X,i2X,mesg,len(mesg)))
        del XX
    except :
        pass

def assertigti(i1,i2,mesg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i1 -
            i2 -
            mesg -
        returns :   (as a tuple)
    """
    i1X = miriad_io.copy_intp(i1)
    i2X = miriad_io.copy_intp(i2)
    try :
        XX = mx.safecall(miriad_io.assertigti_,(i1X,i2X,mesg,len(mesg)))
        del XX
    except :
        pass

def assertigei(i1,i2,mesg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i1 -
            i2 -
            mesg -
        returns :   (as a tuple)
    """
    i1X = miriad_io.copy_intp(i1)
    i2X = miriad_io.copy_intp(i2)
    try :
        XX = mx.safecall(miriad_io.assertigei_,(i1X,i2X,mesg,len(mesg)))
        del XX
    except :
        pass

def atjones(rad,psi,freq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            rad -
            psi -
            freq -
        returns :   (as a tuple)
            jo -
            pb -
    """
    radX = miriad_io.copy_floatp(rad)
    psiX = miriad_io.copy_floatp(psi)
    freqX = miriad_io.copy_doublep(freq)
    joX = FcomplexArray(2,2)
    pbX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.atjones_,(radX,psiX,freqX,joX,pbX))
        del XX
    except :
        pass
    joR = unconvertComplex(FcomplexListToArray(joX))
    pbR = miriad_io.floatp_value(pbX)
    return joR,pbR

def axistype(lin,axis,plane) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
            axis -
            plane -
        returns :   (as a tuple)
            ctype -
            label -
            value -
            units -
    """
    units = "              "
    label = "              "
    ctype = "          "
    linX = miriad_io.copy_intp(lin)
    axisX = miriad_io.copy_intp(axis)
    planeX = miriad_io.copy_intp(plane)
    valueX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.axistype_,(linX,axisX,planeX,ctype,label,valueX,units,9,13,13))
        del XX
    except :
        pass
    valueR = miriad_io.doublep_value(valueX)
    ctype = ctype.strip()
    label = label.strip()
    units = units.strip()
    return ctype,label,valueR,units

def basant(baseline) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            baseline -
        returns :   (as a tuple)
            ant1 -
            ant2 -
    """
    baselineX = miriad_io.copy_doublep(baseline)
    ant1X = miriad_io.new_intp()
    ant2X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.basant_,(baselineX,ant1X,ant2X))
        del XX
    except :
        pass
    ant1R = miriad_io.intp_value(ant1X)
    ant2R = miriad_io.intp_value(ant2X)
    return ant1R,ant2R

def basanta(baseline) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            baseline -
        returns :   (as a tuple)
            ant1 -
            ant2 -
    """
    baselineX = miriad_io.copy_doublep(baseline)
    ant1X = miriad_io.new_intp()
    ant2X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.basanta_,(baselineX,ant1X,ant2X))
        del XX
    except :
        pass
    ant1R = miriad_io.intp_value(ant1X)
    ant2R = miriad_io.intp_value(ant2X)
    return ant1R,ant2R

def basants(baseline,check) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            baseline -
            check -
        returns :   (as a tuple)
            ant1 -
            ant2 -
    """
    baselineX = miriad_io.copy_doublep(baseline)
    ant1X = miriad_io.new_intp()
    ant2X = miriad_io.new_intp()
    checkX = miriad_io.copy_intp(uncastLogical(check))
    try :
        XX = mx.safecall(miriad_io.basants_,(baselineX,ant1X,ant2X,checkX))
        del XX
    except :
        pass
    ant1R = miriad_io.intp_value(ant1X)
    ant2R = miriad_io.intp_value(ant2X)
    return ant1R,ant2R

def antbas(i1,i2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i1 -
            i2 -
        returns :   (as a tuple)
    """
    i1X = miriad_io.copy_intp(i1)
    i2X = miriad_io.copy_intp(i2)
    XX = -1
    try :
        XX = mx.safecall(miriad_io.antbas_,(i1X,i2X))
    except :
        pass
    return XX

def boxinput(key,file,maxboxes) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            key -
            file -
            maxboxes -
        returns :   (as a tuple)
            boxes -
    """
    boxesX = intArray(maxboxes)
    maxboxesX = miriad_io.copy_intp(maxboxes)
    try :
        XX = mx.safecall(miriad_io.boxinput_,(key,file,boxesX,maxboxesX,len(key),len(file)))
        del XX
    except :
        pass
    boxesR = intListToArray(boxesX,maxboxes)
    del boxesX
    return boxesR

def boxzrnge(spec,k1,k2,ztype,lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            k1 -
            k2 -
            ztype -
            lu -
        returns :   (as a tuple)
            k1 -
            k2 -
            zrange -
    """
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    zrangeX = intArray(2)
    luX = intListToArray(lu)
    try :
        XX = mx.safecall(miriad_io.boxzrnge_,(spec,k1X,k2X,zrangeX,ztype,luX,len(spec),len(ztype)))
        del XX
    except :
        pass
    k1R =  miriad_io.intp_value(k1X)
    k2R =  miriad_io.intp_value(k2X)
    zrangeR = intArrayToList(zrangeX,2)
    del zrangeX
    del luX
    return k1R,k2R,zrangeR

def boxint(spec,k1,k2,modulo,nmax,type__,lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            k1 -
            k2 -
            modulo -
            nmax -
            type__ -
            lu -
        returns :   (as a tuple)
            k1 -
            k2 -
            boxes -
    """
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    boxesX = intArray(nmax)
    nX = miriad_io.new_intp()
    moduloX = miriad_io.copy_intp(modulo)
    nmaxX = miriad_io.copy_intp(nmax)
    luX = intListToArray(lu)
    try :
        XX = mx.safecall(miriad_io.boxint_,(spec,k1X,k2X,boxesX,nX,moduloX,nmaxX,type__,luX,len(spec),len(type__)))
        del XX
    except :
        pass
    k1R =  miriad_io.intp_value(k1X)
    k2R =  miriad_io.intp_value(k2X)
    boxesR = intArrayToList(boxesX,nmax)
    del boxesX
    del luX
    return k1R,k2R,boxesR

def boxpoly(spec,k1,k2,nmax,xytype,lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            k1 -
            k2 -
            nmax -
            xytype -
            lu -
        returns :   (as a tuple)
            k1 -
            k2 -
            verts -
            n -
            xyrange -
    """
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    vertsX = intArray(2,nmax/2)
    nX = miriad_io.new_intp()
    nmaxX = miriad_io.copy_intp(nmax)
    xyrangeX = intArray(4)
    luX = intListToArray(lu)
    try :
        XX = mx.safecall(miriad_io.boxpoly_,(spec,k1X,k2X,vertsX,nX,nmaxX,xyrangeX,xytype,luX,len(spec),len(xytype)))
        del XX
    except :
        pass
    k1R =  miriad_io.intp_value(k1X)
    k2R =  miriad_io.intp_value(k2X)
    vertsR = intArrayToList(vertsX,2,nmax/2)
    del vertsX
    nR = miriad_io.intp_value(nX)
    xyrangeR = intArrayToList(xyrangeX,4)
    del xyrangeX
    del luX
    return k1R,k2R,vertsR,nR,xyrangeR

def boxsort(boxes,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            boxes -
            n -
        returns :   (as a tuple)
            boxes -
            xyrange -
    """
    boxesX = intListToArray(boxes)
    nX = miriad_io.copy_intp(n)
    xyrangeX = intArray(4)
    try :
        XX = mx.safecall(miriad_io.boxsort_,(boxesX,nX,xyrangeX))
        del XX
    except :
        pass
    boxesR = intArrayToList(boxesX,n)
    del boxesX
    xyrangeR = intArrayToList(xyrangeX,4)
    del xyrangeX
    return boxesR,xyrangeR

def boxmsk(spec,k1,k2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            k1 -
            k2 -
        returns :   (as a tuple)
            k1 -
            k2 -
            tno -
            xyzrange -
    """
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    tnoX = miriad_io.new_intp()
    xyzrangeX = intArray(6)
    try :
        XX = mx.safecall(miriad_io.boxmsk_,(spec,k1X,k2X,tnoX,xyzrangeX,len(spec)))
        del XX
    except :
        pass
    k1R =  miriad_io.intp_value(k1X)
    k2R =  miriad_io.intp_value(k2X)
    tnoR = miriad_io.intp_value(tnoX)
    xyzrangeR = intArrayToList(xyzrangeX,6)
    del xyzrangeX
    return k1R,k2R,tnoR,xyzrangeR

def boxmask(tno,boxes) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            boxes -
            maxboxes -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    maxboxes = len(boxes)
    boxesX = intListToArray(boxes)
    maxboxesX = miriad_io.copy_intp(maxboxes)
    try :
        XX = mx.safecall(miriad_io.boxmask_,(tnoX,boxesX,maxboxesX))
        del XX
    except :
        pass
    boxesR = intArrayToList(boxesX,maxboxes)
    del boxesX
    return boxesR

def boxmskpr(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
            xyzrange -
    """
    tnoX = miriad_io.copy_intp(tno)
    xyzrangeX = intArray(6)
    try :
        XX = mx.safecall(miriad_io.boxmskpr_,(tnoX,xyzrangeX))
        del XX
    except :
        pass
    xyzrangeR = intArrayToList(xyzrangeX,6)
    del xyzrangeX
    return xyzrangeR

def boxdef(boxes,naxis,blc,trc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            naxis -
            blc -
            trc -
        returns :   (as a tuple)
            boxes -
    """
    boxesX = intListToArray(boxes)
    l = len(boxes)
    naxisX = miriad_io.copy_intp(naxis)
    blcX = miriad_io.copy_intp(blc)
    trcX = miriad_io.copy_intp(trc)
    try :
        XX = mx.safecall(miriad_io.boxdef_,(boxesX,naxisX,blcX,trcX))
        del XX
    except :
        pass
    boxesR = intArrayToList(boxesX,l)
    del boxesX
    return boxesR

def boxset(boxes,naxis,nsize,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            naxis -
            nsize -
            flags -
        returns :   (as a tuple)
            boxes -
    """
    boxesX = intListToArray(boxes)
    l = len(boxes)
    naxisX = miriad_io.copy_intp(naxis)
    nsizeX = intListToArray(nsize)
    try :
        XX = mx.safecall(miriad_io.boxset_,(boxesX,naxisX,nsizeX,flags,len(flags)))
        del XX
    except :
        pass
    boxesR = intArrayToList(boxesX,l)
    del boxesX
    return boxesR

def boxinfo(boxes,naxis) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            boxes -
            naxis -
        returns :   (as a tuple)
            blc -
            trc -
    """
    boxesX = miriad_io.copy_intp(boxes)
    naxisX = miriad_io.copy_intp(naxis)
    blcX = intArray(naxis)
    trcX = intArray(naxis)
    try :
        XX = mx.safecall(miriad_io.boxinfo_,(boxesX,naxisX,blcX,trcX))
        del XX
    except :
        pass
    blcR = intArrayToList(blcX,naxis)
    del blcX
    trcR = intArrayToList(trcX,naxis)
    del trcX
    return blcR,trcR

def boxrect(boxes) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            boxes -
        returns :   (as a tuple)
            boxrect -
    """
    boxesX = intListToArray(boxes)
    try :
        XX = mx.safecall(miriad_io.boxrect_,(boxesX,))
    except :
        pass
    del boxesX
    return castLogical(XX)

def boxbound(boxes,subcmd,naxis) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            boxes -
            subcmd -
            naxis -
        returns :   (as a tuple)
            type -
            mode -
            blc -
            trc -
    """
    typeX = "      "
    mode = "     "
    boxesX = intListToArray(boxes)
    subcmdX = miriad_io.copy_intp(subcmd)
    naxisX = miriad_io.copy_intp(naxis)
    blcX = intArray(naxis)
    trcX = intArray(naxis)
    try :
        XX = mx.safecall(miriad_io.boxbound_,(boxesX,subcmdX,naxisX,typeX,mode,blcX,trcX,4,3))
        del XX
    except :
        pass
    del boxesX
    blcR = intArrayToList(blcX,naxis)
    del blcX
    trcR = intArrayToList(trcX,naxis)
    del trcX
    return typeX,mode,blcR,trcR

def boxcount(runs,nruns) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            runs -
            nruns -
        returns :   (as a tuple)
            npoint -
    """
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    npointX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.boxcount_,(runsX,nrunsX,npointX))
        del XX
    except :
        pass
    del runsX
    npointR = miriad_io.intp_value(npointX)
    return npointR

def boxruns(plane,flags,boxes,maxruns) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            naxis -
            plane -
            flags -
            boxes -
            maxruns -
        returns :   (as a tuple)
            runs -
            nruns -
            xminv -
            yminv -
            xmaxv -
            ymaxv -
            """
    naxisX = miriad_io.copy_intp(len(plane))
    planeX = intListToArray(plane)
    boxesX = intListToArray(boxes)
    runsX = intArray(3,maxruns)
    maxrunsX = miriad_io.copy_intp(maxruns)
    nrunsX = miriad_io.new_intp()
    xminvX = miriad_io.new_intp()
    xmaxvX = miriad_io.new_intp()
    yminvX = miriad_io.new_intp()
    ymaxvX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.boxruns_,(naxisX,planeX,flags,boxesX,runsX,maxrunsX,nrunsX,xminvX,xmaxvX,yminvX,ymaxvX,len(flags)))
        del XX
    except :
        pass
    del planeX
    del boxesX
    nrunsR = miriad_io.intp_value(nrunsX)
    runsR = intArrayToList(runsX,3,nrunsR)
    del runsX
    xminvR = miriad_io.intp_value(xminvX)
    xmaxvR = miriad_io.intp_value(xmaxvX)
    yminvR = miriad_io.intp_value(yminvX)
    ymaxvR = miriad_io.intp_value(ymaxvX)
    return runsR,xminvR,yminvR,xmaxvR,ymaxvR

def boxand(n1,in1,n2,in2,maxout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n1 -
            in1 -
            n2 -
            in2 -
            maxout -
        returns :   (as a tuple)
            out -
    """
    n1X = miriad_io.copy_intp(n1)
    in1X = intListToArray(in1)
    n2X = miriad_io.copy_intp(n2)
    in2X = intListToArray(in2)
    noutX = miriad_io.new_intp()
    outX = intArray(maxout)
    maxoutX = miriad_io.copy_intp(maxout)
    try :
        XX = mx.safecall(miriad_io.boxand_,(n1X,in1X,n2X,in2X,noutX,outX,maxoutX))
        del XX
    except :
        pass
    del in1X
    del in2X
    noutR = miriad_io.intp_value(noutX)
    outR = intArrayToList(outX,noutR)
    del outX
    return outR

def boxor(n1,in1,n2,in2,maxout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n1 -
            in1 -
            n2 -
            in2 -
            maxout -
        returns :   (as a tuple)
            out -
    """
    n1X = miriad_io.copy_intp(n1)
    in1X = intListToArray(in1)
    n2X = miriad_io.copy_intp(n2)
    in2X = intListToArray(in2)
    noutX = miriad_io.new_intp()
    outX = intArray(maxout)
    maxoutX = miriad_io.copy_intp(maxout)
    try :
        XX = mx.safecall(miriad_io.boxor_,(n1X,in1X,n2X,in2X,noutX,outX,maxoutX))
        del XX
    except :
        pass
    del in1X
    del in2X
    noutR = miriad_io.intp_value(noutX)
    outR = intArrayToList(outX,noutR)
    del outX
    return outR

def boxboxx(maxgoes,j0,nbox,box) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            maxgoes -
            j0 -
            nbox -
            box -
        returns :   (as a tuple)
            goes -
    """
    goesX = intArray(maxgoes)
    maxgoesX = miriad_io.copy_intp(maxgoes)
    j0X = miriad_io.copy_intp(j0)
    nboxX = miriad_io.copy_intp(nbox)
    boxX = intListToArray(box)
    ngoesX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.boxboxx_,(goesX,maxgoesX,j0X,nboxX,boxX,ngoesX))
        del XX
    except :
        pass
    ngoesR = miriad_io.intp_value(ngoesX)
    goesR = intArrayToList(goesX,ngoesR)
    del goesX
    del boxX
    return goesR

def boxpolyx(maxgoes,j0,nverts,verts) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            maxgoes -
            j0 -
            nverts -
            verts -
        returns :   (as a tuple)
            goes -
    """
    goesX = intArray(maxgoes)
    maxgoesX = miriad_io.copy_intp(maxgoes)
    j0X = miriad_io.copy_intp(j0)
    nvertsX = miriad_io.copy_intp(nverts)
    vertsX = intListToArray(verts)
    ngoesX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.boxpolyx_,(goesX,maxgoesX,j0X,nvertsX,vertsX,ngoesX))
        del XX
    except :
        pass
    ngoesR = miriad_io.intp_value(ngoesX)
    goesR = intArrayToList(goesX,ngoesR)
    del goesX
    del vertsX
    return goesR

def boxbug(spec,message) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            message -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.boxbug_,(spec,message,len(spec),len(message)))
        del XX
    except :
        pass

def wrbtype(lun,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            value -
        returns :   (as a tuple)
    """
    lunX = miriad_io.copy_intp(lun)
    try :
        XX = mx.safecall(miriad_io.wrbtype_,(lunX,value,len(value)))
        del XX
    except :
        pass

def rdbtype(lun,defn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            defn -
        returns :   (as a tuple)
            value -
    """
    value = "                       "
    lunX = miriad_io.copy_intp(lun)
    try :
        XX = mx.safecall(miriad_io.rdbtype_,(lunX,value,defn,21,len(defn)))
        del XX
    except :
        pass
    value = value.strip()
    return value

def caopen(tno,dataname,time0,nbl,base,version,status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dataname -- the name of the data set to be opened
            status   -- either 'old', 'new' or 'append'
        outputs/inputs (depending on 'new'/'append' or 'old' in status):
            tno      -- the calibration set handle
            time0    -- time offset
            nbl      -- the number of baselines
            base     -- an array of nbl baseline pairs (see findbase)
            version  -- version as read/write from/to disk
    """
    tnoX = miriad_io.copy_intp(tno)
    time0X = miriad_io.copy_doublep(time0)
    nblX = miriad_io.copy_intp(nbl)
    baseX = intListToArray(base)
    versionX = miriad_io.copy_intp(version)
    try :
        XX = mx.safecall(miriad_io.caopen_,(tnoX,dataname,time0X,nblX,baseX,versionX,status,len(dataname),len(status)))
        del XX
    except :
        pass
    tnoR =  miriad_io.intp_value(tnoX)
    time0R =  miriad_io.intp_value(time0X)
    nblR =  miriad_io.intp_value(nblX)
    baseR = intArrayToList(baseX,nblR)
    del baseX
    versionR =  miriad_io.intp_value(versionX)
    return tnoR,time0R,nblR,baseR,versionR

def caclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.caclose_,(tnoX,))
        del XX
    except :
        pass

def cadread(tno,i) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            i -
        returns :   (as a tuple)
            rtime -
            rdata -
            rflag -
            sindex -
            err -
    """
    tnoX = miriad_io.copy_intp(tno)
    iX = miriad_io.copy_intp(i)
    rtimeX = miriad_io.new_floatp()
    rdataX = floatArray(10000)
    rflagX = intArray(10000)
    sindexX = intArray(10000)
    errX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.cadread_,(tnoX,iX,rtimeX,rdataX,rflagX,sindexX,errX))
        del XX
    except :
        pass
    rtimeR = miriad_io.floatp_value(rtimeX)
    rdataR = floatArrayToList(rdataX,10000)
    del rdataX
    rflagR = intArrayToList(rflagX,10000)
    del rflagX
    sindexR = intArrayToList(sindexX,10000)
    del sindexX
    errR = miriad_io.intp_value(errX)
    return rtimeR,rdataR,rflagR,sindexR,errR

def cadwrite(tno,i,rtime,rdata,rflag,sindex) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            i -
            rtime -
            rdata -
            rflag -
            sindex -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    iX = miriad_io.copy_intp(i)
    rtimeX = miriad_io.copy_floatp(rtime)
    rdataX = floatListToArray(rdata)
    rflagX = intListToArray(rflag)
    sindexX = intListToArray(sindex)
    try :
        XX = mx.safecall(miriad_io.cadwrite_,(tnoX,iX,rtimeX,rdataX,rflagX,sindexX))
        del XX
    except :
        pass
    del rdataX
    del rflagX
    del sindexX

def casread(tno,i) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            i -
        returns :   (as a tuple)
            name -
            plstuff -
            err -
    """
    tnoX = miriad_io.copy_intp(tno)
    iX = miriad_io.copy_intp(i)
    name = "                      "
    plstuffX = floatArray(4)
    errX = miriad_io.new_intp()
    name_len = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.casread_,(tnoX,iX,name,plstuffX,errX,20))
        del XX
    except :
        pass
    plstuffR = floatArrayToList(plstuffX,4)
    del plstuffX
    errR = miriad_io.intp_value(errX)
    return name,plstuffR,errR

def caswrite(tno,i) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            i -
        returns :   (as a tuple)
            name -
            plstuff -
    """
    name = "                      "
    tnoX = miriad_io.copy_intp(tno)
    iX = miriad_io.copy_intp(i)
    plstuffX = floatArray(4)
    try :
        XX = mx.safecall(miriad_io.caswrite_,(tnoX,iX,name,plstuffX,20))
        del XX
    except :
        pass
    plstuffR = floatArrayToList(plstuffX,4)
    del plstuffX
    name = name.strip()
    return name,plstuffR

def caflag(tno,i,rflag) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            i -
            rflag -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    iX = miriad_io.copy_intp(i)
    rflagX = intListToArray(rflag)
    try :
        XX = mx.safecall(miriad_io.caflag_,(tnoX,iX,rflagX))
        del XX
    except :
        pass
    del rflagX

def caerror(iostat,string) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            iostat -
            string -
        returns :   (as a tuple)
    """
    iostatX = miriad_io.copy_intp(iostat)
    try :
        XX = mx.safecall(miriad_io.caerror_,(iostatX,string,len(string)))
        del XX
    except :
        pass

def rdhdia(tno,itemname,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            itemname -
            length -
        returns :   (as a tuple)
            value -
    """
    tnoX = miriad_io.copy_intp(tno)
    lengthX = miriad_io.copy_intp(length)
    valueX = intArray(1000)
    try :
        XX = mx.safecall(miriad_io.rdhdia_,(tnoX,itemname,lengthX,valueX,len(itemname)))
        del XX
    except :
        pass
    valueR = intArrayToList(valueX,1000)
    del valueX
    return valueR

def wrhdia(tno,itemname,length,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            itemname -
            length -
            value -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    lengthX = miriad_io.copy_intp(length)
    valueX = intListToArray(value)
    try :
        XX = mx.safecall(miriad_io.wrhdia_,(tnoX,itemname,lengthX,valueX,len(itemname)))
        del XX
    except :
        pass
    del valueX

def rsplit(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
            split -
    """
    tnoX = miriad_io.copy_intp(tno)
    splitX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.rsplit_,(tnoX,splitX))
        del XX
    except :
        pass
    splitR = castLogical(miriad_io.intp_value(splitX))
    return splitR

def wsplit(tno,split) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
            split -
    """
    tnoX = miriad_io.copy_intp(tno)
    splitX = miriad_io.copy_intp(uncastLogical(split))
    try :
        XX = mx.safecall(miriad_io.wsplit_,(tnoX,splitX))
        del XX
    except :
        pass

def dgefa(a,lda,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            lda -
            n -
        returns :   (as a tuple)
            ipvt -
            info -
    """
    aX = doubleListToArray(a)
    ldaX = miriad_io.copy_intp(lda)
    nX = miriad_io.copy_intp(n)
    ipvtX = intArray(n)
    infoX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.dgefa_,(aX,ldaX,nX,ipvtX,infoX))
        del XX
    except :
        pass
    aR = doubleArrayToList(aX,n)
    del aX
    ipvtR = intArrayToList(ipvtX,n)
    del ipvtX
    infoR = miriad_io.intp_value(infoX)
    return aR,ipvtR,infoR

def dgesl(a,lda,ipvt,b,job) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            lda -
            n -
            ipvt -
            b -
            job -
        returns :   (as a tuple)
            b -
    """
    n = len(b)
    aX = doubleListToArray(a)
    ldaX = miriad_io.copy_intp(lda)
    nX = miriad_io.copy_intp(n)
    ipvtX = intListToArray(ipvt)
    bX = doubleListToArray(b)
    jobX = miriad_io.copy_intp(job)
    try :
        XX = mx.safecall(miriad_io.dgesl_,(aX,ldaX,nX,ipvtX,bX,jobX))
        del XX
    except :
        pass
    del aX
    del ipvtX
    bR = doubleArrayToList(bX,n)
    del bX
    return bR

def vectav(b,p,count,avidx,dtaver,tmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            b -
            p -
            count -
            avidx -
            dtaver -
            tmax -
        returns :   (as a tuple)
            clump -
            nclump -
            x -
            y -
    """
    bX = miriad_io.copy_intp(b)
    pX = miriad_io.copy_intp(p)
    countX = miriad_io.copy_intp(count)
    avidxX = intListToArray(avidx)
    clumpX = intArray(10000,10000)
    nclumpX = miriad_io.new_intp()
    xX = floatArray(10000)
    yX = floatArray(10000)
    dtaverX = miriad_io.copy_floatp(dtaver)
    tmaxX = miriad_io.copy_floatp(tmax)
    try :
        XX = mx.safecall(miriad_io.vectav_,(bX,pX,countX,avidxX,clumpX,nclumpX,xX,yX,dtaverX,tmaxX))
        del XX
    except :
        pass
    del avidxX
    nclumpR = miriad_io.intp_value(nclumpX)
    clumpR = intArrayToList(clumpX,count,nclumpR)
    del clumpX
    xR = floatArrayToList(xX,nclumpR)
    del xX
    yR = floatArrayToList(yX,nclumpR)
    del yX
    return clumpR,nclumpR,xR,yR

def miniflip(npts,phas) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            npts -
            phas -
        returns :   (as a tuple)
            phas -
            flips -
    """
    nptsX = miriad_io.copy_intp(npts)
    phasX = floatListToArray(phas)
    l = len(phas)
    flipsX = intArray(l)
    try :
        XX = mx.safecall(miriad_io.miniflip_,(nptsX,phasX,flipsX))
        del XX
    except :
        pass
    phasR = floatArrayToList(phasX,l)
    flipsR = intArrayToList(flipsX,l)
    del phasX
    del flipsX
    return phasR,flipsR

def flipper(timave,timmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            timave -
            timmax -
        returns :   (as a tuple)
    """
    timaveX = miriad_io.copy_floatp(timave)
    timmaxX = miriad_io.copy_floatp(timmax)
    basediffX = intArray(1000)
    try :
        XX = mx.safecall(miriad_io.flipper_,(timaveX,timmaxX,basediffX))
        del XX
    except :
        pass
    del basediffX

def getclo3(nbl,base) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nbl -
            base -
        returns :   (as a tuple)
            signcl -
    """
    nblX = miriad_io.copy_intp(nbl)
    baseX = intListToArray(base)
    signclX = floatArray(nbl)
    try :
        XX = mx.safecall(miriad_io.getclo3_,(nblX,baseX,signclX))
        del XX
    except :
        pass
    del baseX
    signclR = floatArrayToList(signclX,nbl)
    del signclX
    return signclR

def inipoly():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.inipoly_)
    except :
        pass
    return XX

def getpoly(dataset) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dataset -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.getpoly_,(dataset,len(dataset)))
        del XX
    except :
        pass

def putpoly(dataset) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dataset -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.putpoly_,(dataset,len(dataset)))
        del XX
    except :
        pass

def chkpoly(code) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            code -
        returns :   (as a tuple)
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.chkpoly_,(code,len(code)))
    except :
        pass
    return castLogical(XX)

def evalpoly(t,code,bl) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            t -
            code -
            bl -
        returns :   (as a tuple)
            valid -
            evalpoly -
    """
    tX = miriad_io.copy_floatp(t)
    blX = miriad_io.copy_intp(bl)
    validX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.evalpoly_,(tX,code,blX,validX,len(code)))
    except :
        pass
    validR = miriad_io.intp_value(validX)
    return validR,XX

def fitpoly(n,x,y,code,bl,porder) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            x -
            y -
            code -
            bl -
            porder -
        returns :   (as a tuple)
            fitpoly -
    """
    nX = miriad_io.copy_intp(n)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    blX = miriad_io.copy_intp(bl)
    porderX = miriad_io.copy_intp(porder)
    XX = -1
    try :
        XX = mx.safecall(miriad_io.fitpoly_,(nX,xX,yX,code,blX,porderX,len(code)))
    except :
        pass
    return XX

def addpoly(code,bl,porder,ppoly,valid) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            code -
            bl -
            porder -
            ppoly -
            valid -
        returns :   (as a tuple)
            addpoly -
    """
    validX = floatListToArray(valid)
    ppolyX = floatListToArray(ppoly)
    blX = miriad_io.copy_intp(bl)
    porderX = miriad_io.copy_intp(porder)
    XX = -1
    try :
        XX = mx.safecall(miriad_io.addpoly_,(code,blX,porderX,ppolyX,validX,len(code)))
    except :
        pass
    return XX

def readset(file) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.readset_,(file,len(file)))
        del XX
    except :
        pass

def writeset(file,checksrc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
            checksrc -
        returns :   (as a tuple)
    """
    checksrcX = miriad_io.copy_intp(uncastLogical(checksrc))
    try :
        XX = mx.safecall(miriad_io.writeset_,(file,checksrcX,len(file)))
        del XX
    except :
        pass

def writflag(file) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.writflag_,(file,len(file)))
        del XX
    except :
        pass

def addhist(file,progname,message) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
            progname -
            message -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.addhist_,(file,progname,message,len(file),len(progname),len(message)))
        del XX
    except :
        pass

def hisappn(tno,file,insert) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            file -
            insert -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    insertX = miriad_io.copy_intp(uncastLogical(insert))
    try :
        XX = mx.safecall(miriad_io.hisappn_,(tnoX,file,insertX,len(file)))
        del XX
    except :
        pass

def readbrk(file) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.readbrk_,(file,len(file)))
        del XX
    except :
        pass

def writbrk(file) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.writbrk_,(file,len(file)))
        del XX
    except :
        pass

def putsrc(file) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            file -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.putsrc_,(file,len(file)))
        del XX
    except :
        pass

def calstoke(source,stokes,freq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            source -
            stokes -
            freq -
            nchan -
        returns :   (as a tuple)
            flux -
            ierr -
    """
    nchan = len(freq)
    freqX = doubleListToArray(freq)
    fluxX = floatArray(nchan)
    nchanX = miriad_io.copy_intp(nchan)
    ierrX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.calstoke_,(source,stokes,freqX,fluxX,nchanX,ierrX,len(source),len(stokes)))
        del XX
    except :
        pass
    del freqX
    fluxR = floatArrayToList(fluxX,nchan)
    del fluxX
    ierrR = miriad_io.intp_value(ierrX)
    return fluxR,ierrR

def findbase(bl,base) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bl -
            base -
        returns :
            the index
    """
    blX = miriad_io.copy_intp(bl)
    baseX = intListToArray(base)
    nblX = miriad_io.copy_intp(len(base))
    XX = -1
    try :
        XX = mx.safecall(miriad_io.findbase_,(blX,baseX,nblX))
    except :
        pass
    del baseX
    return XX

def blname(bl) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bl -
        returns :
            blname -
    """
    blX = miriad_io.copy_intp(bl)
    value = "                      "
    try :
        mx.safecall(miriad_io.blname_,(value,20,blX))
    except :
        pass
    value = value.strip()
    return value

def getants(binp,nant) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            binp -
            nant -
        returns :   (as a tuple)
            nant -
            a1 -
            a2 -
    """
    binpX = miriad_io.copy_intp(binp)
    nantX = miriad_io.copy_intp(nant)
    a1X = miriad_io.new_intp()
    a2X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.getants_,(binpX,nantX,a1X,a2X))
        del XX
    except :
        pass
    nantR = miriad_io.copy_intp(nantX)
    a1R = miriad_io.intp_value(a1X)
    a2R = miriad_io.intp_value(a2X)
    return nantR,a1R,a2R

def taver(x,y,dx) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            x -
            y -
            dx -
        returns :   (as a tuple)
            n -
            x -
            y -
    """
    n = len(x)
    nX = miriad_io.copy_intp(n)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    dxX = miriad_io.copy_floatp(dx)
    try :
        XX = mx.safecall(miriad_io.taver_,(nX,xX,yX,dxX))
        del XX
    except :
        pass
    nR = miriad_io.intp_value(nX)
    xR = floatArrayToList(xX,nR)
    del xX
    yR = floatArrayToList(yX,nR)
    del yX
    return nR,xR,yR

def code2s(code) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            code -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.code2s_,(code,len(code)))
        del XX
    except :
        pass

def ampscal(amp,jyflux,scalmode) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            amp -
            jyflux -
            scalmode -
        returns :   (as a tuple)
            amp -
    """
    ampX = miriad_io.copy_floatp(amp)
    jyfluxX = miriad_io.copy_floatp(jyflux)
    scalmodeX = miriad_io.copy_intp(scalmode)
    try :
        XX = mx.safecall(miriad_io.ampscal_,(ampX,jyfluxX,scalmodeX))
        del XX
    except :
        pass
    ampR = miriad_io.floatp_value(ampX)
    return ampR

def setxy(bp,b,p,taver) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bp -
            b -
            p -
            taver -
        returns :   (as a tuple)
            count -
            x -
            y -
    """
    bpX = miriad_io.copy_intp(bp)
    bX = miriad_io.copy_intp(b)
    pX = miriad_io.copy_intp(p)
    countX = miriad_io.new_intp()
    xX = floatArray(10000)
    yX = floatArray(10000)
    taverX = floatListToArray(taver)
    try :
        XX = mx.safecall(miriad_io.setxy_,(bpX,bX,pX,countX,xX,yX,taverX))
        del XX
    except :
        pass
    countR = miriad_io.intp_value(countX)
    xR = floatArrayToList(xX,countR)
    del xX
    yR = floatArrayToList(yX,countR)
    del yX
    del taverX
    return countR,xR,yR

def cnvlinif(lu,n1,n2,ic,jc,param,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            n1 -
            n2 -
            ic -
            jc -
            param -
            flags -
        returns :   (as a tuple)
            handle -
    """
    handleX = miriad_io.new_intp()
    luX = miriad_io.copy_intp(lu)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    paramX = miriad_io.copy_floatp(param)
    try :
        XX = mx.safecall(miriad_io.cnvlinif_,(handleX,luX,n1X,n2X,icX,jcX,paramX,flags,len(flags)))
        del XX
    except :
        pass
    handleR = miriad_io.intp_value(handleX)
    return handleR

def cnvlinia(array,n1,n2,ic,jc,param,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            array -
            n1 -
            n2 -
            ic -
            jc -
            param -
            flags -
        returns :   (as a tuple)
            handle -
    """
    handleX = miriad_io.new_intp()
    arrayX = floatListToArray(array)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    paramX = miriad_io.copy_floatp(param)
    try :
        XX = mx.safecall(miriad_io.cnvlinia_,(handleX,arrayX,n1X,n2X,icX,jcX,paramX,flags,len(flags)))
        del XX
    except :
        pass
    handleR = miriad_io.intp_value(handleX)
    del arrayX
    return handleR

def cnvlcopy(handle) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
        returns :   (as a tuple)
            out -
    """
    outX = miriad_io.new_intp()
    handleX = miriad_io.copy_intp(handle)
    try :
        XX = mx.safecall(miriad_io.cnvlcopy_,(outX,handleX))
        del XX
    except :
        pass
    outR = miriad_io.intp_value(outX)
    return outR

def cnvlco(handle1,handle2,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle1 -
            handle2 -
            flags -
        returns :   (as a tuple)
    """
    handle1X = miriad_io.copy_intp(handle1)
    handle2X = miriad_io.copy_intp(handle2)
    try :
        XX = mx.safecall(miriad_io.cnvlco_,(handle1X,handle2X,flags,len(flags)))
        del XX
    except :
        pass

def cnvlin0(n1,n2,flags,ic,jc,xr,yr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n1 -
            n2 -
            flags -
            ic -
            jc -
            xr -
            yr -
        returns :   (as a tuple)
            handle -
            n1d -
            n2d -
            space -
            trans -
            cdat1 -
            cdat2 -
    """
    handleX = miriad_io.new_intp()
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    n1dX = miriad_io.new_intp()
    n2dX = miriad_io.new_intp()
    spaceX = miriad_io.new_intp()
    transX = miriad_io.new_intp()
    cdat1X = miriad_io.new_intp()
    cdat2X = miriad_io.new_intp()
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    xrX = miriad_io.copy_intp(xr)
    yrX = miriad_io.copy_intp(yr)
    try :
        XX = mx.safecall(miriad_io.cnvlin0_,(handleX,n1X,n2X,n1dX,n2dX,spaceX,transX,cdat1X,cdat2X,flags,icX,jcX,xrX,yrX,len(flags)))
        del XX
    except :
        pass
    handleR = miriad_io.intp_value(handleX)
    n1dR = miriad_io.intp_value(n1dX)
    n2dR = miriad_io.intp_value(n2dX)
    spaceR = miriad_io.intp_value(spaceX)
    transR = miriad_io.intp_value(transX)
    cdat1R = miriad_io.intp_value(cdat1X)
    cdat2R = miriad_io.intp_value(cdat2X)
    return handleR,n1dR,n2dR,spaceR,transR,cdat1R,cdat2R

def cnvla(handle,inp,nx,ny,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
            inp -
            nx -
            ny -
            flags -
        returns :   (as a tuple)
            out -
    """
    handleX = miriad_io.copy_intp(handle)
    inX = floatListToArray(inp)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    outX = floatArray(nx*ny)
    try :
        XX = mx.safecall(miriad_io.cnvla_,(handleX,inX,nxX,nyX,outX,flags,len(flags)))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,nx*ny)
    del outX
    return outR

def cnvlf(handle,lu,nx,ny,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
            lu -
            nx -
            ny -
            flags -
        returns :   (as a tuple)
            out -
    """
    handleX = miriad_io.copy_intp(handle)
    luX = miriad_io.copy_intp(lu)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    outX = floatArray(nx*ny)
    try :
        XX = mx.safecall(miriad_io.cnvlf_,(handleX,luX,nxX,nyX,outX,flags,len(flags)))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,nx*ny)
    del outX
    return outR

def cnvlr(handle,inp,nx,ny,runs,nruns,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
            inp -
            nx -
            ny -
            runs -
            nruns -
            flags -
        returns :   (as a tuple)
            out -
    """
    handleX = miriad_io.copy_intp(handle)
    inX = floatListToArray(inp)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    outX = floatArray(nx*ny)
    try :
        XX = mx.safecall(miriad_io.cnvlr_,(handleX,inX,nxX,nyX,runsX,nrunsX,outX,flags,len(flags)))
        del XX
    except :
        pass
    del inX
    del runsX
    outR = floatArrayToList(outX,nx*ny)
    del outX
    return outR

def cnvlext(handle) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
        returns :   (as a tuple)
            n1 -
            n2 -
            n1d -
            n2d -
    """
    handleX = miriad_io.copy_intp(handle)
    n1X = miriad_io.new_intp()
    n2X = miriad_io.new_intp()
    n1dX = miriad_io.new_intp()
    n2dX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.cnvlext_,(handleX,n1X,n2X,n1dX,n2dX))
        del XX
    except :
        pass
    n1R = miriad_io.intp_value(n1X)
    n2R = miriad_io.intp_value(n2X)
    n1dR = miriad_io.intp_value(n1dX)
    n2dR = miriad_io.intp_value(n2dX)
    return n1R,n2R,n1dR,n2dR

def cnvl0(handle,nx,ny,n1,n2,n1a,n2a,flags,xr,yr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
            nx -
            ny -
            n1 -
            n2 -
            n1a -
            n2a -
            flags -
            xr -
            yr -
        returns :   (as a tuple)
            n1d -
            n2d -
            space -
            trans -
            cdat1 -
            cdat2 -
            sym -
            compr -
            corr -
    """
    handleX = miriad_io.copy_intp(handle)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    n1aX = miriad_io.copy_intp(n1a)
    n2aX = miriad_io.copy_intp(n2a)
    n1dX = miriad_io.new_intp()
    n2dX = miriad_io.new_intp()
    spaceX = miriad_io.new_intp()
    transX = miriad_io.new_intp()
    cdat1X = miriad_io.new_intp()
    cdat2X = miriad_io.new_intp()
    symX = miriad_io.new_intp()
    comprX = miriad_io.new_intp()
    corrX = miriad_io.new_intp()
    xrX = miriad_io.copy_intp(xr)
    yrX = miriad_io.copy_intp(yr)
    try :
        XX = mx.safecall(miriad_io.cnvl0_,(handleX,nxX,nyX,n1X,n2X,n1aX,n2aX,n1dX,n2dX,spaceX,transX,cdat1X,cdat2X,flags,symX,comprX,corrX,xrX,yrX,len(flags)))
        del XX
    except :
        pass
    n1dR = miriad_io.intp_value(n1dX)
    n2dR = miriad_io.intp_value(n2dX)
    spaceR = miriad_io.intp_value(spaceX)
    transR = miriad_io.intp_value(transX)
    cdat1R = miriad_io.intp_value(cdat1X)
    cdat2R = miriad_io.intp_value(cdat2X)
    symR = castLogical(miriad_io.intp_value(symX))
    comprR = castLogical(miriad_io.intp_value(comprX))
    corrR = castLogical(miriad_io.intp_value(corrX))
    return n1dR,n2dR,spaceR,transR,cdat1R,cdat2R,symR,comprR,corrR

def cnvlfin(handle) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle -
        returns :   (as a tuple)
    """
    handleX = miriad_io.copy_intp(handle)
    try :
        XX = mx.safecall(miriad_io.cnvlfin_,(handleX,))
        del XX
    except :
        pass

def convl(inp,n,nx,ny,runs,nruns,beam,n1,n2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            inp -
            n -
            nx -
            ny -
            runs -
            nruns -
            beam -
            n1 -
            n2 -
        returns :   (as a tuple)
            out -
    """
    inX = miriad_io.copy_floatp(inp)
    outX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    runsX = miriad_io.copy_intp(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    beamX = miriad_io.copy_floatp(beam)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    try :
        XX = mx.safecall(miriad_io.convl_,(inX,outX,nX,nxX,nyX,runsX,nrunsX,beamX,n1X,n2X))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,n)
    del outX
    return outR

def sctico(typeX,win) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            typeX -
            win -
        returns :   (as a tuple)
            cti -
    """
    cti = "                       "
    winX = miriad_io.copy_doublep(win)
    try :
        XX = mx.safecall(miriad_io.sctico_,(typeX,winX,cti,len(typeX),20))
        del XX
    except :
        pass
    winR = miriad_io.doublep_value(winX)
    cti = cti.strip()
    return winR,cti

def sctoco(typeX,wout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            typeX -
            wout -
        returns :   (as a tuple)
    """
    woutX = miriad_io.copy_doublep(wout)
    try :
        XX = mx.safecall(miriad_io.sctoco_,(typeX,woutX,len(typeX)))
        del XX
    except :
        pass
    woutR = miriad_io.doublep_value(woutX)
    return woutR

def setoaco(lun,absoff,n,iax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            absoff -
            n -
            iax -
        returns :   (as a tuple)
            types -
    """
    types = "        "
    lunX = miriad_io.copy_intp(lun)
    nX = miriad_io.copy_intp(n)
    iaxX = miriad_io.copy_intp(iax)
    try :
        XX = mx.safecall(miriad_io.setoaco_,(lunX,absoff,nX,iaxX,types,3,n))
        del XX
    except :
        pass
    types = types.strip()
    return types

def specco(lun,iax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            iax -
        returns :   (as a tuple)
            stype -
    """
    stype = "              "
    lunX = miriad_io.copy_intp(lun)
    iaxX = miriad_io.copy_intp(iax)
    try :
        XX = mx.safecall(miriad_io.specco_,(lunX,iaxX,stype,10))
        del XX
    except :
        pass
    stype = stype.strip()
    return stype

def sunitco(lun,iax,typeX) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            iax -
            typeX -
        returns :   (as a tuple)
            units -
    """
    units = "                       "
    lunX = miriad_io.copy_intp(lun)
    iaxX = miriad_io.copy_intp(iax)
    try :
        XX = mx.safecall(miriad_io.sunitco_,(lunX,iaxX,typeX,units,len(typeX),20))
        del XX
    except :
        pass
    units = units.strip()
    return units

def w2wcov(lun,n,typei,win,typeo,valid) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            n -
            typei -
            win -
            typeo -
            valid -
        returns :   (as a tuple)
            wout -
    """
    lunX = miriad_io.copy_intp(lun)
    nX = miriad_io.copy_intp(n)
    winX = doubleListToArray(win)
    woutX = doubleArray(n)
    validX = miriad_io.copy_intp(uncastLogical(valid))
    try :
        XX = mx.safecall(miriad_io.w2wcov_,(lunX,nX,typei,winX,typeo,woutX,validX,len(typei),len(typeo)))
        del XX
    except :
        pass
    del winX
    woutR = doubleArrayToList(woutX,n)
    del woutX
    return woutR

def w2wfco(lun,n,typei,win,typeo,nounit) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            n -
            typei -
            win -
            typeo -
            nounit -
        returns :   (as a tuple)
            strout -
            strlen -
    """
    strout = "                     "
    lunX = miriad_io.copy_intp(lun)
    nX = miriad_io.copy_intp(n)
    winX = doubleListToArray(win)
    nounitX = miriad_io.copy_intp(uncastLogical(nounit))
    strlenX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.w2wfco_,(lunX,nX,typei,winX,typeo,nounitX,strout,strlenX,len(typei),len(typeo),n))
        del XX
    except :
        pass
    del winX
    strlenR = intArrayToList(strlenX,n)
    del strlenX
    return strout,strlenR

def w2wsco(lun,iax,typei,win,typeo) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            iax -
            typei -
            win -
            typeo -
        returns :   (as a tuple)
            wout -
    """
    lunX = miriad_io.copy_intp(lun)
    iaxX = miriad_io.copy_intp(iax)
    winX = miriad_io.copy_doublep(win)
    woutX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.w2wsco_,(lunX,iaxX,typei,winX,typeo,woutX,len(typei),len(typeo)))
        del XX
    except :
        pass
    woutR = miriad_io.doublep_value(woutX)
    return woutR

def w2wsfco(lun,iax,typei,win,typeo,nounit) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            iax -
            typei -
            win -
            typeo -
            nounit -
        returns :   (as a tuple)
            strout -
    """
    strout = "                      "
    lunX = miriad_io.copy_intp(lun)
    iaxX = miriad_io.copy_intp(iax)
    winX = miriad_io.copy_doublep(win)
    nounitX = miriad_io.copy_intp(uncastLogical(nounit))
    strlenX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.w2wsfco_,(lunX,iaxX,typei,winX,typeo,nounitX,strout,strlenX,len(typei),len(typeo),20))
        del XX
    except :
        pass
    strout = strout.strip()
    return strout

def ctrlopen(name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
        returns :   (as a tuple)
            ctrl -
    """
    ctrlX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ctrlopen_,(name,ctrlX,len(name)))
        del XX
    except :
        pass
    ctrlR = castLogical(miriad_io.intp_value(ctrlX))
    return ctrlR

def ctrlinit(name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
        returns :   (as a tuple)
            status -
    """
    statusX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ctrlinit_,(name,statusX,len(name)))
        del XX
    except :
        pass
    statusR = miriad_io.intp_value(statusX)
    return statusR

def ctrlport(name,port) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            port -
        returns :   (as a tuple)
            status -
    """
    portX = miriad_io.copy_intp(port)
    statusX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ctrlport_,(name,portX,statusX,len(name)))
        del XX
    except :
        pass
    statusR = miriad_io.intp_value(statusX)
    return statusR

def ctrlview():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ctrlview_)
    except :
        pass
    return XX

def ctrlclr():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ctrlclr_)
    except :
        pass
    return XX

def ctrlchck(name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
        returns :   (as a tuple)
            changes -
            val1 -
            val2 -
    """
    changesX = miriad_io.new_intp()
    val1X = miriad_io.new_intp()
    val2X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ctrlchck_,(name,changesX,val1X,val2X,len(name)))
        del XX
    except :
        pass
    changesR = miriad_io.intp_value(changesX)
    val1R = miriad_io.intp_value(val1X)
    val2R = miriad_io.intp_value(val2X)
    return changesR,val1R,val2R

def ctrlwait() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            name -
            changes -
            val1 -
            val2 -
    """
    name = "                     "
    changesX = miriad_io.new_intp()
    val1X = miriad_io.new_intp()
    val2X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ctrlwait_,(name,changesX,val1X,val2X,20))
        del XX
    except :
        pass
    changesR = miriad_io.intp_value(changesX)
    val1R = miriad_io.intp_value(val1X)
    val2R = miriad_io.intp_value(val2X)
    name = name.strip()
    return name,changesR,val1R,val2R

def ctrldef(name,typeX,values,nvalues) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            typeX -
            values -
            nvalues -
        returns :   (as a tuple)
    """
    nvaluesX = miriad_io.copy_intp(nvalues)
    try :
        XX = mx.safecall(miriad_io.ctrldef_,(name,typeX,values,nvaluesX,len(name),len(typeX),nvalues))
        del XX
    except :
        pass

def ctrlset(name,values,nvalues) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            values -
            nvalues -
        returns :   (as a tuple)
    """
    valuesX = intListToArray(values)
    nvaluesX = miriad_io.copy_intp(nvalues)
    try :
        XX = mx.safecall(miriad_io.ctrlset_,(name,valuesX,nvaluesX,len(name)))
        del XX
    except :
        pass
    del valuesX

def ctrlseta(name,string) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            string -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.ctrlseta_,(name,string,len(name),len(string)))
        del XX
    except :
        pass

def ctrlfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ctrlfin_)
    except :
        pass
    return XX

def ctrlflsh(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
    """
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.ctrlflsh_,(nX,))
        del XX
    except :
        pass

def ctrlread(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
    """
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.ctrlread_,(nX,))
        del XX
    except :
        pass

def defsmodl(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.defsmodl_,(tnoX,))
        del XX
    except :
        pass

def deghms(a,d) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            d__ -
        returns :   (as a tuple)
            radec -
    """
    radec = "                      "
    aX = miriad_io.copy_doublep(a)
    dX = miriad_io.copy_doublep(d)
    try :
        XX = mx.safecall(miriad_io.deghms_,(aX,dX,radec,20))
        del XX
    except :
        pass
    radec = radec.strip()
    return radec

def radhms(a,d) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            d -
        returns :   (as a tuple)
            radec -
    """
    radec = "                       "
    aX = miriad_io.copy_doublep(a)
    dX = miriad_io.copy_doublep(d)
    try :
        XX = mx.safecall(miriad_io.radhms_,(aX,dX,radec,20))
        del XX
    except :
        pass
    radec = radec.strip()
    return radec

def jul2ut(jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
        returns :   (as a tuple)
            ut -
    """
    jdayX = miriad_io.copy_doublep(jday)
    utX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.jul2ut_,(jdayX,utX))
        del XX
    except :
        pass
    utR = miriad_io.doublep_value(utX)
    return utR

def prerotat(jday,ra,dec,jout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            ra -
            dec -
            jout -
        returns :   (as a tuple)
            theta -
    """
    jdayX = miriad_io.copy_doublep(jday)
    raX = miriad_io.copy_doublep(ra)
    decX = miriad_io.copy_doublep(dec)
    joutX = miriad_io.copy_doublep(jout)
    thetaX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.prerotat_,(jdayX,raX,decX,joutX,thetaX))
        del XX
    except :
        pass
    thetaR = miriad_io.doublep_value(thetaX)
    return thetaR

def precess(jday1,ra1,dec1,jday2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday1 -
            ra1 -
            dec1 -
            jday2 -
        returns :   (as a tuple)
            ra2 -
            dec2 -
    """
    jday1X = miriad_io.copy_doublep(jday1)
    ra1X = miriad_io.copy_doublep(ra1)
    dec1X = miriad_io.copy_doublep(dec1)
    jday2X = miriad_io.copy_doublep(jday2)
    ra2X = miriad_io.new_doublep()
    dec2X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.precess_,(jday1X,ra1X,dec1X,jday2X,ra2X,dec2X))
        del XX
    except :
        pass
    ra2R = miriad_io.doublep_value(ra2X)
    dec2R = miriad_io.doublep_value(dec2X)
    return ra2R,dec2R

def azel(obsra,obsdec,lst,latitude) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            obsra -
            obsdec -
            lst -
            latitude -
        returns :   (as a tuple)
            az -
            el -
    """
    obsraX = miriad_io.copy_doublep(obsra)
    obsdecX = miriad_io.copy_doublep(obsdec)
    lstX = miriad_io.copy_doublep(lst)
    latitudeX = miriad_io.copy_doublep(latitude)
    azX = miriad_io.new_doublep()
    elX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.azel_,(obsraX,obsdecX,lstX,latitudeX,azX,elX))
        del XX
    except :
        pass
    azR = miriad_io.doublep_value(azX)
    elR = miriad_io.doublep_value(elX)
    return azR,elR

def parang(obsra,obsdec,lst,latitude) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            obsra -
            obsdec -
            lst -
            latitude -
        returns :   (as a tuple)
            chi -
    """
    obsraX = miriad_io.copy_doublep(obsra)
    obsdecX = miriad_io.copy_doublep(obsdec)
    lstX = miriad_io.copy_doublep(lst)
    latitudeX = miriad_io.copy_doublep(latitude)
    chiX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.parang_,(obsraX,obsdecX,lstX,latitudeX,chiX))
        del XX
    except :
        pass
    chiR = miriad_io.floatp_value(chiX)
    return chiR

def jullst(jday,long) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            long -
        returns :   (as a tuple)
            lst -
    """
    jdayX = miriad_io.copy_doublep(jday)
    longX = miriad_io.copy_doublep(long)
    lstX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.jullst_,(jdayX,longX,lstX))
        del XX
    except :
        pass
    lstR = miriad_io.doublep_value(lstX)
    return lstR

def xyz2llh(x,y,z) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
            z -
        returns :   (as a tuple)
            lat -
            long -
            height -
    """
    xX = miriad_io.copy_doublep(x)
    yX = miriad_io.copy_doublep(y)
    zX = miriad_io.copy_doublep(z)
    latX = miriad_io.new_doublep()
    longX = miriad_io.new_doublep()
    heightX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.xyz2llh_,(xX,yX,zX,latX,longX,heightX))
        del XX
    except :
        pass
    latR = miriad_io.doublep_value(latX)
    longR = miriad_io.doublep_value(longX)
    heightR = miriad_io.doublep_value(heightX)
    return latR,longR,heightR

def llh2xyz(lat,long,height) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lat -
            long -
            height -
        returns :   (as a tuple)
            x -
            y -
            z -
    """
    latX = miriad_io.copy_doublep(lat)
    longX = miriad_io.copy_doublep(long)
    heightX = miriad_io.copy_doublep(height)
    xX = miriad_io.new_doublep()
    yX = miriad_io.new_doublep()
    zX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.llh2xyz_,(latX,longX,heightX,xX,yX,zX))
        del XX
    except :
        pass
    xR = miriad_io.doublep_value(xX)
    yR = miriad_io.doublep_value(yX)
    zR = miriad_io.doublep_value(zX)
    return xR,yR,zR

def sph2lmn(ra,dec) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ra -
            dec -
        returns :   (as a tuple)
            lmn -
    """
    raX = miriad_io.copy_doublep(ra)
    decX = miriad_io.copy_doublep(dec)
    lmnX = doubleArray(3)
    try :
        XX = mx.safecall(miriad_io.sph2lmn_,(raX,decX,lmnX))
        del XX
    except :
        pass
    lmnR = doubleArrayToList(lmnX,3)
    del lmnX
    return lmnR

def lmn2sph(lmn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lmn -
        returns :   (as a tuple)
            ra -
            dec -
    """
    lmnX = doubleListToArray(lmn)
    raX = miriad_io.new_doublep()
    decX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.lmn2sph_,(lmnX,raX,decX))
        del XX
    except :
        pass
    del lmnX
    raR = miriad_io.doublep_value(raX)
    decR = miriad_io.doublep_value(decX)
    return raR,decR

def aberrate(jday,ra,dec) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            ra -
            dec -
        returns :   (as a tuple)
            rapp -
            dapp -
    """
    jdayX = miriad_io.copy_doublep(jday)
    raX = miriad_io.copy_doublep(ra)
    decX = miriad_io.copy_doublep(dec)
    rappX = miriad_io.new_doublep()
    dappX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.aberrate_,(jdayX,raX,decX,rappX,dappX))
        del XX
    except :
        pass
    rappR = miriad_io.doublep_value(rappX)
    dappR = miriad_io.doublep_value(dappX)
    return rappR,dappR

def nutate(jday,rmean,dmean) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            rmean -
            dmean -
        returns :   (as a tuple)
            rtrue -
            dtrue -
    """
    jdayX = miriad_io.copy_doublep(jday)
    rmeanX = miriad_io.copy_doublep(rmean)
    dmeanX = miriad_io.copy_doublep(dmean)
    rtrueX = miriad_io.new_doublep()
    dtrueX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.nutate_,(jdayX,rmeanX,dmeanX,rtrueX,dtrueX))
        del XX
    except :
        pass
    rtrueR = miriad_io.doublep_value(rtrueX)
    dtrueR = miriad_io.doublep_value(dtrueX)
    return rtrueR,dtrueR

def nuts(jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
        returns :   (as a tuple)
            dpsi -
            deps -
    """
    jdayX = miriad_io.copy_doublep(jday)
    dpsiX = miriad_io.new_doublep()
    depsX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.nuts_,(jdayX,dpsiX,depsX))
        del XX
    except :
        pass
    dpsiR = miriad_io.doublep_value(dpsiX)
    depsR = miriad_io.doublep_value(depsX)
    return dpsiR,depsR

def sunradec(jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
        returns :   (as a tuple)
            ra -
            dec -
    """
    jdayX = miriad_io.copy_doublep(jday)
    raX = miriad_io.new_doublep()
    decX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.sunradec_,(jdayX,raX,decX))
        del XX
    except :
        pass
    raR = miriad_io.doublep_value(raX)
    decR = miriad_io.doublep_value(decX)
    return raR,decR

def fk45z(r1950,d1950,jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            r1950 -
            d1950 -
            jday -
        returns :   (as a tuple)
            r2000 -
            d2000 -
    """
    r1950X = miriad_io.copy_doublep(r1950)
    d1950X = miriad_io.copy_doublep(d1950)
    jdayX = miriad_io.copy_doublep(jday)
    r2000X = miriad_io.new_doublep()
    d2000X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fk45z_,(r1950X,d1950X,jdayX,r2000X,d2000X))
        del XX
    except :
        pass
    r2000R = miriad_io.doublep_value(r2000X)
    d2000R = miriad_io.doublep_value(d2000X)
    return r2000R,d2000R

def fk54z(r2000,d2000,jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            r2000 -
            d2000 -
            jday -
        returns :   (as a tuple)
            r1950 -
            d1950 -
            dr1950 -
            dd1950 -
    """
    r2000X = miriad_io.copy_doublep(r2000)
    d2000X = miriad_io.copy_doublep(d2000)
    jdayX = miriad_io.copy_doublep(jday)
    r1950X = miriad_io.new_doublep()
    d1950X = miriad_io.new_doublep()
    dr1950X = miriad_io.new_doublep()
    dd1950X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fk54z_,(r2000X,d2000X,jdayX,r1950X,d1950X,dr1950X,dd1950X))
        del XX
    except :
        pass
    r1950R = miriad_io.doublep_value(r1950X)
    d1950R = miriad_io.doublep_value(d1950X)
    dr1950R = miriad_io.doublep_value(dr1950X)
    dd1950R = miriad_io.doublep_value(dd1950X)
    return r1950R,d1950R,dr1950R,dd1950R

def fk524(r2000,d2000,dr2000,dd2000,p2000,v2000) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            r2000 -
            d2000 -
            dr2000 -
            dd2000 -
            p2000 -
            v2000 -
        returns :   (as a tuple)
            r1950 -
            d1950 -
            dr1950 -
            dd1950 -
            p1950 -
            v1950 -
    """
    r2000X = miriad_io.copy_doublep(r2000)
    d2000X = miriad_io.copy_doublep(d2000)
    dr2000X = miriad_io.copy_doublep(dr2000)
    dd2000X = miriad_io.copy_doublep(dd2000)
    p2000X = miriad_io.copy_doublep(p2000)
    v2000X = miriad_io.copy_doublep(v2000)
    r1950X = miriad_io.new_doublep()
    d1950X = miriad_io.new_doublep()
    dr1950X = miriad_io.new_doublep()
    dd1950X = miriad_io.new_doublep()
    p1950X = miriad_io.new_doublep()
    v1950X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fk524_,(r2000X,d2000X,dr2000X,dd2000X,p2000X,v2000X,r1950X,d1950X,dr1950X,dd1950X,p1950X,v1950X))
        del XX
    except :
        pass
    r1950R = miriad_io.doublep_value(r1950X)
    d1950R = miriad_io.doublep_value(d1950X)
    dr1950R = miriad_io.doublep_value(dr1950X)
    dd1950R = miriad_io.doublep_value(dd1950X)
    p1950R = miriad_io.doublep_value(p1950X)
    v1950R = miriad_io.doublep_value(v1950X)
    return r1950R,d1950R,dr1950R,dd1950R,p1950R,v1950R

def pm(r0,d0,pr,pd,px,rv,jep0,jep1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            r0 -
            d0 -
            pr -
            pd -
            px -
            rv -
            jep0 -
            jep1 -
        returns :   (as a tuple)
            r1 -
            d1 -
    """
    r0X = miriad_io.copy_doublep(r0)
    d0X = miriad_io.copy_doublep(d0)
    prX = miriad_io.copy_doublep(pr)
    pdX = miriad_io.copy_doublep(pd)
    pxX = miriad_io.copy_doublep(px)
    rvX = miriad_io.copy_doublep(rv)
    jep0X = miriad_io.copy_doublep(jep0)
    jep1X = miriad_io.copy_doublep(jep1)
    r1X = miriad_io.new_doublep()
    d1X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.pm_,(r0X,d0X,prX,pdX,pxX,rvX,jep0X,jep1X,r1X,d1X))
        del XX
    except :
        pass
    r1R = miriad_io.doublep_value(r1X)
    d1R = miriad_io.doublep_value(d1X)
    return r1R,d1R

def fftrc(inp,isn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            in -
            isn -
        returns :   (as a tuple)
            out -
    """
    n = len(inp)
    inX = floatListToArray(inp)
    outX = floatArray(n+2)
    isnX = miriad_io.copy_intp(isn)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.fftrc_,(inX,outX,isnX,nX))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,n+2)
    del outX
    return outR

def fftcr(inp,isn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            in -
            isn -
        returns :   (as a tuple)
            out -
    """
    n = len(inp) - 2
    inX = floatListToArray(inp)
    outX = floatArray(n)
    isnX = miriad_io.copy_intp(isn)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.fftcr_,(inX,outX,isnX,nX))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,n)
    del outX
    return outR

def fftcc(inp,isn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            inp -
            isn -
        returns :   (as a tuple)
            out -
    """
    n = len(inp)
    inX = FcomplexListToArray(inp)
    outX = doubleArray(n*2)
    isnX = miriad_io.copy_intp(isn)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.fftcc_,(inX,outX,isnX,nX))
        del XX
    except :
        pass
    outR = unconvertComplex(doubleArrayToList(outX,n*2))
    return outR

def fftini(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            m -
            ni -
            i1 -
            i2 -
            twiddle -
    """
    nX = miriad_io.copy_intp(n)
    mX = miriad_io.new_intp()
    niX = miriad_io.new_intp()
    i1X = intArray(n/2)
    i2X = intArray(n/2)
    twiddleX = miriad_io.new_Fcomplexp()
    try :
        XX = mx.safecall(miriad_io.fftini_,(nX,mX,niX,i1X,i2X,twiddleX))
        del XX
    except :
        pass
    mR = miriad_io.intp_value(mX)
    niR = miriad_io.intp_value(niX)
    i1R = intArrayToList(i1X,n/2)
    del i1X
    i2R = intArrayToList(i2X,n/2)
    del i2X
    twiddleR = unconvertComplex(miriad_io.doublep_value(twiddleX))
    return mR,niR,i1R,i2R,twiddleR

def fxyopen(name,status,naxis=MAXNAX,nsize=0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            status -
            naxis -
            nsize -
        returns :   (as a tuple)
            lu -
    """
    luX = miriad_io.new_intp()
    naxisX = miriad_io.copy_intp(naxis)
    if(nsize == 0) :
        nsizeX = intArray(naxis)
    else :
        nsizeX = intListToArray(nsize)
    try :
        XX = mx.safecall(miriad_io.fxyopen_,(luX,name,status,naxisX,nsizeX,len(name),len(status)))
        del XX
    except :
        pass
    luR = miriad_io.intp_value(luX)
    nsizeR = intArrayToList(nsizeX,naxis)
    del nsizeX
    return luR,nsizeR

def fxysetpl(lu,naxis,nsize) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            naxis -
            nsize -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    naxisX = miriad_io.copy_intp(naxis)
    nsizeX = intListToArray(nsize)
    try :
        XX = mx.safecall(miriad_io.fxysetpl_,(luX,naxisX,nsizeX))
        del XX
    except :
        pass
    del nsizeX

def fxyread(lu,indx,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            indx -
            length - the expected length
        returns :   (as a tuple)
            data -
    """
    luX = miriad_io.copy_intp(lu)
    indxX = miriad_io.copy_intp(indx)
    dataX = floatArray(length)
    try :
        XX = mx.safecall(miriad_io.fxyread_,(luX,indxX,dataX))
        del XX
    except :
        pass
    dataR = floatArrayToList(dataX,length)
    del dataX
    return dataR

def fxyflgrd(lu,indx) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            indx -
        returns :   (as a tuple)
            flags -
    """
    luX = miriad_io.copy_intp(lu)
    indxX = miriad_io.copy_intp(indx)
    flagsX = intArray(10000)
    try :
        XX = mx.safecall(miriad_io.fxyflgrd_,(luX,indxX,flagsX))
        del XX
    except :
        pass
    flagsR = castLogical(intArrayToList(flagsX,10000))
    del flagsX
    return flagsR

def fxywrite(lu,indx,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            indx -
            data -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    indxX = miriad_io.copy_intp(indx)
    dataX = floatListToArray(data)
    try :
        XX = mx.safecall(miriad_io.fxywrite_,(luX,indxX,dataX))
        del XX
    except :
        pass

def fxyflgwr(lu,indx,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            indx -
            flags -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    indxX = miriad_io.copy_intp(indx)
    flagsX = intListToArray(uncastLogical(flags))
    try :
        XX = mx.safecall(miriad_io.fxyflgwr_,(luX,indxX,flagsX))
        del XX
    except :
        pass
    del flagsX

def fxyclose(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fxyclose_,(luX,))
        del XX
    except :
        pass

def fuvopen(name,status,nvis=0,npol=0,nfreq=0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            status -
            nvis -
            npol -
            nfreq -
        returns :   (as a tuple)
            lu -
            nvis -
            npol -
            nfreq -
    """
    luX = miriad_io.new_intp()
    nvisX = miriad_io.copy_intp(nvis)
    npolX = miriad_io.copy_intp(npol)
    nfreqX = miriad_io.copy_intp(nfreq)
    try :
        XX = mx.safecall(miriad_io.fuvopen_,(luX,name,status,nvisX,npolX,nfreqX,len(name),len(status)))
        del XX
    except :
        pass
    luR = miriad_io.intp_value(luX)
    nvisR = miriad_io.intp_value(nvisX)
    npolR = miriad_io.intp_value(npolX)
    nfreqR = miriad_io.intp_value(nfreqX)
    return luR,nvisR,npolR,nfreqR

def fuvsetpa(lu,nparam,params) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            nparam -
            params -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    nparamX = miriad_io.copy_intp(nparam)
    try :
        XX = mx.safecall(miriad_io.fuvsetpa_,(luX,nparamX,params,len(params)))
        del XX
    except :
        pass

def fuvwrpa(lu,nranfile,params,timoff) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            nranfile -
            params -
            timoff -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    nranfileX = miriad_io.copy_intp(nranfile)
    timoffX = miriad_io.copy_doublep(timoff)
    try :
        XX = mx.safecall(miriad_io.fuvwrpa_,(luX,nranfileX,params,timoffX,len(params)))
        del XX
    except :
        pass

def fuvrdpa(lu,nranfile,nranprog,params) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            nranfile -
            nranprog -
            params -
        returns :   (as a tuple)
            indices1 -
            indices2 -
            scales1 -
            scales2 -
            zeros -
            timoff -
    """
    luX = miriad_io.copy_intp(lu)
    nranfileX = intListToArray(nranfile)
    nranprogX = intListToArray(nranprog)
    indices1X = intArray(nranprog)
    indices2X = intArray(nranprog)
    scales1X = floatArray(nranprog)
    scales2X = floatArray(nranprog)
    zerosX = floatArray(nranprog)
    timoffX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fuvrdpa_,(luX,nranfileX,nranprogX,params,indices1X,indices2X,scales1X,scales2X,zerosX,timoffX,len(params)))
        del XX
    except :
        pass
    del nranfileX
    del nranprogX
    indices1R = intArrayToList(indices1X,nranprog)
    del indices1X
    indices2R = intArrayToList(indices2X,nranprog)
    del indices2X
    scales1R = floatArrayToList(scales1X,nranprog)
    del scales1X
    scales2R = floatArrayToList(scales2X,nranprog)
    del scales2X
    zerosR = floatArrayToList(zerosX,nranprog)
    del zerosX
    timoffR = miriad_io.copy_doublep(timoffX)
    del timoffX
    return indices1R,indices2R,scales1R,scales2R,zerosR,timoffR

def fuvsett0(lu,t0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            t0 -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    t0X = miriad_io.copy_doublep(t0)
    try :
        XX = mx.safecall(miriad_io.fuvsett0_,(luX,t0X))
        del XX
    except :
        pass

def fuvwrhd(lu,coord) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            coord -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    coordX = doubleListToArray(coord)
    try :
        XX = mx.safecall(miriad_io.fuvwrhd_,(luX,coordX))
        del XX
    except :
        pass
    del coordX

def fuvrdhd(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
            coord -
    """
    luX = miriad_io.copy_intp(lu)
    coordX = doubleArray(3,4)
    try :
        XX = mx.safecall(miriad_io.fuvrdhd_,(luX,coordX))
        del XX
    except :
        pass
    coordR = doubleArrayToList(coordX,3,4)
    del coordX
    return coordR

def fuvread(lu,number,count) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            number -
            count -
        returns :   (as a tuple)
            visdat -
    """
    luX = miriad_io.copy_intp(lu)
    visdatX = floatArray(count)
    numberX = miriad_io.copy_intp(number)
    countX = miriad_io.copy_intp(count)
    try :
        XX = mx.safecall(miriad_io.fuvread_,(luX,visdatX,numberX,countX))
        del XX
    except :
        pass
    visdatR = floatArrayToList(visdatX,count)
    del visdatX
    return visdatR

def fuvwrite(lu,number,count,visdat) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            number -
            count -
            visdat -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    visdatX = floatListToArray(visdat)
    numberX = miriad_io.copy_intp(number)
    countX = miriad_io.copy_intp(count)
    try :
        XX = mx.safecall(miriad_io.fuvwrite_,(luX,visdatX,numberX,countX))
        del XX
    except :
        pass
    del visdatX

def fuvclose(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fuvclose_,(luX,))
        del XX
    except :
        pass

def fuvrtrn1(lu,n,inp,ppvisi,ppviso) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            n -
            in -
            ppvisi -
            ppviso -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    nX = miriad_io.copy_intp(n)
    inX = intListToArray(inp)
    ppvisiX = miriad_io.copy_intp(ppvisi)
    outX = floatArray(n)
    ppvisoX = miriad_io.copy_intp(ppviso)
    try :
        XX = mx.safecall(miriad_io.fuvrtrn1_,(luX,nX,inX,ppvisiX,outX,ppvisoX))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,n)
    del outX
    return outR

def fuvrtrn2(lu,n,inp,mask,ppvisi,ppviso) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            n -
            inp -
            mask -
            ppvisi -
            ppviso -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    nX = miriad_io.copy_intp(n)
    inX = floatListToArray(inp)
    maskX = intListToArray(mask)
    ppvisiX = miriad_io.copy_intp(ppvisi)
    outX = floatArray(n)
    ppvisoX = miriad_io.copy_intp(ppviso)
    try :
        XX = mx.safecall(miriad_io.fuvrtrn2_,(luX,nX,inX,maskX,ppvisiX,outX,ppvisoX))
        del XX
    except :
        pass
    del inX
    del maskX
    outR = floatArrayToList(outX,n)
    del outX
    return outR

def fuvmltr1(n,bscale,bzero,a,na,nb) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            bscale -
            bzero -
            a -
            na -
            nb -
        returns :   (as a tuple)
            b -
    """
    nX = miriad_io.copy_intp(n)
    bscaleX = miriad_io.copy_floatp(bscale)
    bzeroX = miriad_io.copy_floatp(bzero)
    aX = intListToArray(a)
    naX = miriad_io.copy_intp(na)
    bX = floatArray(n)
    nbX = miriad_io.copy_intp(nb)
    try :
        XX = mx.safecall(miriad_io.fuvmltr1_,(nX,bscaleX,bzeroX,aX,naX,bX,nbX))
        del XX
    except :
        pass
    del aX
    bR = floatArrayToList(bX,n)
    del bX
    return bR

def fuvgrand(lu,indx) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            indx -
        returns :   (as a tuple)
            rparam -
    """
    luX = miriad_io.copy_intp(lu)
    indxX = miriad_io.copy_intp(indx)
    rparamX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fuvgrand_,(luX,indxX,rparamX))
        del XX
    except :
        pass
    rparamR = miriad_io.doublep_value(rparamX)
    return rparamR

def fuvfreq(lu,freq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            freq -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    freqX = miriad_io.copy_doublep(freq)
    try :
        XX = mx.safecall(miriad_io.fuvfreq_,(luX,freqX))
        del XX
    except :
        pass

def fuvwt(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
            factor -
    """
    luX = miriad_io.copy_intp(lu)
    factorX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.fuvwt_,(luX,factorX))
        del XX
    except :
        pass
    factorR = miriad_io.floatp_value(factorX)
    return factorR

def fuvget(lu,naxis) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            naxis -
        returns :   (as a tuple)
            ncmplx -
            icmplx -
            npol -
            ipol -
            nfreq -
            ifreq -
            nif -
            iif -
    """
    luX = miriad_io.copy_intp(lu)
    naxisX = miriad_io.copy_intp(naxis)
    ncmplxX = miriad_io.new_intp()
    icmplxX = miriad_io.new_intp()
    npolX = miriad_io.new_intp()
    ipolX = miriad_io.new_intp()
    nfreqX = miriad_io.new_intp()
    ifreqX = miriad_io.new_intp()
    nifX = miriad_io.new_intp()
    iifX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.fuvget_,(luX,naxisX,ncmplxX,icmplxX,npolX,ipolX,nfreqX,ifreqX,nifX,iifX))
        del XX
    except :
        pass
    ncmplxR = miriad_io.intp_value(ncmplxX)
    icmplxR = miriad_io.intp_value(icmplxX)
    npolR = miriad_io.intp_value(npolX)
    ipolR = miriad_io.intp_value(ipolX)
    nfreqR = miriad_io.intp_value(nfreqX)
    ifreqR = miriad_io.intp_value(ifreqX)
    nifR = miriad_io.intp_value(nifX)
    iifR = miriad_io.intp_value(iifX)
    return ncmplxR,icmplxR,npolR,ipolR,nfreqR,ifreqR,nifR,iifR

def fitrdhdi(lu,key,default) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            default -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    outX = miriad_io.new_intp()
    default__X = miriad_io.copy_intp(default)
    try :
        XX = mx.safecall(miriad_io.fitrdhdi_,(luX,key,outX,default__X,len(key)))
        del XX
    except :
        pass
    outR = miriad_io.intp_value(outX)
    return outR

def fitrdhdr(lu,key,default) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            default -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    outX = miriad_io.new_floatp()
    default__X = miriad_io.copy_floatp(default)
    try :
        XX = mx.safecall(miriad_io.fitrdhdr_,(luX,key,outX,default__X,len(key)))
        del XX
    except :
        pass
    outR = miriad_io.floatp_value(outX)
    return outR

def fitrdhdd(lu,key,default) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            default -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    outX = miriad_io.new_doublep()
    default__X = miriad_io.copy_doublep(default)
    try :
        XX = mx.safecall(miriad_io.fitrdhdd_,(luX,key,outX,default__X,len(key)))
        del XX
    except :
        pass
    outR = miriad_io.doublep_value(outX)
    return outR

def fitrdhda(lu,key,default) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            default -
        returns :   (as a tuple)
            out -
    """
    out = "                       "
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fitrdhda_,(luX,key,out,default,len(key),20,len(default)))
        del XX
    except :
        pass
    out = out.strip()
    return out

def fitrdhdl(lu,key,default) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            default -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    outX = miriad_io.new_intp()
    default__X = miriad_io.copy_intp(default)
    try :
        XX = mx.safecall(miriad_io.fitrdhdl_,(luX,key,outX,default__X,len(key)))
        del XX
    except :
        pass
    outR = castLogical(miriad_io.intp_value(outX))
    return outR

def fitwrhdh(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fitwrhdh_,(luX,key,value,len(key),len(value)))
        del XX
    except :
        pass

def fitwrhda(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fitwrhda_,(luX,key,value,len(key),len(value)))
        del XX
    except :
        pass

def fitwrhdl(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    valueX = miriad_io.copy_intp(uncastLogical(value))
    try :
        XX = mx.safecall(miriad_io.fitwrhdl_,(luX,key,valueX,len(key)))
        del XX
    except :
        pass

def fitwrhdi(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    valueX = miriad_io.copy_intp(value)
    try :
        XX = mx.safecall(miriad_io.fitwrhdi_,(luX,key,valueX,len(key)))
        del XX
    except :
        pass

def fitwrhdr(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    valueX = miriad_io.copy_floatp(value)
    try :
        XX = mx.safecall(miriad_io.fitwrhdr_,(luX,key,valueX,len(key)))
        del XX
    except :
        pass

def fitwrhdd(lu,key,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
            value -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    valueX = miriad_io.copy_doublep(value)
    try :
        XX = mx.safecall(miriad_io.fitwrhdd_,(luX,key,valueX,len(key)))
        del XX
    except :
        pass

def fitopen(name,status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            status -
        returns :   (as a tuple)
            lu -
    """
    luX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.fitopen_,(luX,name,status,len(name),len(status)))
        del XX
    except :
        pass
    luR = miriad_io.intp_value(luX)
    return luR

def fithdfin(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fithdfin_,(luX,))
        del XX
    except :
        pass

def fitclose(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fitclose_,(luX,))
        del XX
    except :
        pass

def fitcdio(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
            value -
    """
    value = "                      "
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.fitcdio_,(luX,value,20))
        del XX
    except :
        pass
    value = value.strip()
    return value

def fitsrch(lu,key) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            key -
        returns :   (as a tuple)
            found -
    """
    luX = miriad_io.copy_intp(lu)
    foundX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.fitsrch_,(luX,key,foundX,len(key)))
        del XX
    except :
        pass
    foundR = castLogical(miriad_io.intp_value(foundX))
    return foundR

def ftabloc(lu,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
        returns :   (as a tuple)
            found -
    """
    luX = miriad_io.copy_intp(lu)
    foundX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabloc_,(luX,name,foundX,len(name)))
        del XX
    except :
        pass
    foundR = castLogical(miriad_io.intp_value(foundX))
    return foundR

def ftabnxt(lu,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
        returns :   (as a tuple)
            found -
    """
    luX = miriad_io.copy_intp(lu)
    foundX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabnxt_,(luX,name,foundX,len(name)))
        del XX
    except :
        pass
    foundR = castLogical(miriad_io.intp_value(foundX))
    return foundR

def ftabskip(lu,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
        returns :   (as a tuple)
            found -
    """
    luX = miriad_io.copy_intp(lu)
    foundX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabskip_,(luX,name,foundX,len(name)))
        del XX
    except :
        pass
    foundR = castLogical(miriad_io.intp_value(foundX))
    return foundR

def ftabload(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
            ok -
    """
    luX = miriad_io.copy_intp(lu)
    okX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabload_,(luX,okX))
        del XX
    except :
        pass
    okR = castLogical(miriad_io.intp_value(okX))
    return okR

def ftabform(string) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
        returns :   (as a tuple)
            colform -
            colcnt -
    """
    colformX = miriad_io.new_intp()
    colcntX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabform_,(string,colformX,colcntX,len(string)))
        del XX
    except :
        pass
    colformR = miriad_io.intp_value(colformX)
    colcntR = miriad_io.intp_value(colcntX)
    return colformR,colcntR

def ftabinfo(lu,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
        returns :   (as a tuple)
            typeX -
            units -
            nrow -
            nval -
    """
    units = "                      "
    typeX = "   "
    luX = miriad_io.copy_intp(lu)
    nrowX = miriad_io.new_intp()
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ftabinfo_,(luX,name,typeX,units,nrowX,nvalX,len(name),1,20))
        del XX
    except :
        pass
    nrowR = miriad_io.copy_intp(nrowX)
    nvalR = miriad_io.intp_value(nvalX)
    typeX = typeX.strip()
    units = units.strip()
    return typeX,units,nrowR,nvalR

def ftabgeti(lu,name,irow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
        returns :   (as a tuple)
            data -
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = intArray(10000)
    try :
        XX = mx.safecall(miriad_io.ftabgeti_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    dataR = intArrayToList(dataX,10000)
    del dataX
    return dataR

def ftabgetr(lu,name,irow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
        returns :   (as a tuple)
            data -
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = floatArray(10000)
    try :
        XX = mx.safecall(miriad_io.ftabgetr_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    dataR = floatArrayToList(dataX,10000)
    del dataX
    return dataR

def ftabgetc(lu,name,irow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
        returns :   (as a tuple)
            data -
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = FcomplexArray(10000)
    try :
        XX = mx.safecall(miriad_io.ftabgetc_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    dataR = unconvertComplex(FcomplexArrayToList(dataX,100000))
    return dataR

def ftabgetd(lu,name,irow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
        returns :   (as a tuple)
            data -
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = doubleArray(10000)
    try :
        XX = mx.safecall(miriad_io.ftabgetd_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    dataR = doubleArrayToList(dataX,10000)
    del dataX
    return dataR

def ftabgeta(lu,name,irow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
        returns :   (as a tuple)
            data -
    """
    data = "                                                    "
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    try :
        XX = mx.safecall(miriad_io.ftabgeta_,(luX,name,irowX,data,len(name),50))
        del XX
    except :
        pass
    data = data.strip()
    return data

def ftabdini(lu,ename) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            ename -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.ftabdini_,(luX,ename,len(ename)))
        del XX
    except :
        pass

def ftabdfin(lu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    try :
        XX = mx.safecall(miriad_io.ftabdfin_,(luX,))
        del XX
    except :
        pass

def ftabdef(lu,name,typeX,units,nrow,nval) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            typeX -
            units -
            nrow -
            nval -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    nrowX = miriad_io.copy_intp(nrow)
    nvalX = miriad_io.copy_intp(nval)
    try :
        XX = mx.safecall(miriad_io.ftabdef_,(luX,name,typeX,units,nrowX,nvalX,len(name),len(typeX),len(units)))
        del XX
    except :
        pass

def ftabputr(lu,name,irow,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
            data -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = floatListToArray(data)
    try :
        XX = mx.safecall(miriad_io.ftabputr_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    del dataX

def ftabputd(lu,name,irow,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
            data -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = doubleListToArray(data)
    try :
        XX = mx.safecall(miriad_io.ftabputd_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    del dataX

def ftabputi(lu,name,irow,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
            data -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    dataX = intListToArray(data)
    try :
        XX = mx.safecall(miriad_io.ftabputi_,(luX,name,irowX,dataX,len(name)))
        del XX
    except :
        pass
    del dataX

def ftabputa(lu,name,irow,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            name -
            irow -
            data -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    irowX = miriad_io.copy_intp(irow)
    try :
        XX = mx.safecall(miriad_io.ftabputa_,(luX,name,irowX,data,len(name),len(data)))
        del XX
    except :
        pass

def fitdate(lu,keyw) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            keyw -
        returns :   (as a tuple)
            jday -
    """
    luX = miriad_io.copy_intp(lu)
    jdayX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.fitdate_,(luX,keyw,jdayX,len(keyw)))
        del XX
    except :
        pass
    jdayR = miriad_io.doublep_value(jdayX)
    return jdayR


def fbasant(bl) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bl -
        returns :   (as a tuple)
            ant1 -
            ant2 -
            config -
    """
    blX = miriad_io.copy_floatp(bl)
    ant1X = miriad_io.new_intp()
    ant2X = miriad_io.new_intp()
    configX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.fbasant_,(blX,ant1X,ant2X,configX))
        del XX
    except :
        pass
    ant1R = miriad_io.intp_value(ant1X)
    ant2R = miriad_io.intp_value(ant2X)
    configR = miriad_io.intp_value(configX)
    return ant1R,ant2R,configR

def fndaxnum(tinp,typeX) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tinp -
            typeX -
        returns :   (as a tuple)
            axisname -
            axisnr -
    """
    axisname = "                      "
    tinpX = miriad_io.copy_intp(tinp)
    axisnrX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.fndaxnum_,(tinpX,typeX,axisname,axisnrX,len(typeX),20))
        del XX
    except :
        pass
    axisnrR = miriad_io.intp_value(axisnrX)
    axisname = axisname.strip()
    return axisname,axisnrR

def remext(filename) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            filename -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.remext_,(filename,len(filename)))
        del XX
    except :
        pass
    filename = filename.strip()
    return filename

def gser(a,x) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            x -
        returns :   (as a tuple)
            gamser -
            gln -
    """
    aX = miriad_io.copy_floatp(a)
    xX = miriad_io.copy_floatp(x)
    gamserX = miriad_io.new_floatp()
    glnX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.gser_,(aX,xX,gamserX,glnX))
        del XX
    except :
        pass
    gamserR = miriad_io.floatp_value(gamserX)
    glnR = miriad_io.floatp_value(glnX)
    return gamserR,glnR

def gcf(a,x) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            x -
        returns :   (as a tuple)
            gammcf -
            gln -
    """
    aX = miriad_io.copy_floatp(a)
    xX = miriad_io.copy_floatp(x)
    gammcfX = miriad_io.new_floatp()
    glnX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.gcf_,(aX,xX,gammcfX,glnX))
        del XX
    except :
        pass
    gammcfR = miriad_io.floatp_value(gammcfX)
    glnR = miriad_io.floatp_value(glnX)
    return gammcfR,glnR

def gaupar1(lin,bmaj2,bmin2,bpa2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
            bmaj2 -
            bmin2 -
            bpa2 -
        returns :   (as a tuple)
            bunit -
            bmaj -
            bmin -
            bpa -
            fac -
    """
    bunit = "                      "
    linX = miriad_io.copy_intp(lin)
    bmaj2X = miriad_io.copy_floatp(bmaj2)
    bmin2X = miriad_io.copy_floatp(bmin2)
    bpa2X = miriad_io.copy_floatp(bpa2)
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    facX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.gaupar1_,(linX,bmaj2X,bmin2X,bpa2X,bunit,bmajX,bminX,bpaX,facX,20))
        del XX
    except :
        pass
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    facR = miriad_io.floatp_value(facX)
    bunit = bunit.strip()
    return bunit,bmajR,bminR,bpaR,facR

def gaupar2(lin1,lin2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin1 -
            lin2 -
        returns :   (as a tuple)
            bunit -
            bmaj -
            bmin -
            bpa -
            fac -
    """
    bunit = "                       "
    lin1X = miriad_io.copy_intp(lin1)
    lin2X = miriad_io.copy_intp(lin2)
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    facX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.gaupar2_,(lin1X,lin2X,bunit,bmajX,bminX,bpaX,facX,20))
        del XX
    except :
        pass
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    facR = miriad_io.floatp_value(facX)
    bunit = bunit.strip()
    return bunit,bmajR,bminR,bpaR,facR

def gaupar(bunit1x,dx1,dy1,bmaj1,bmin1,bpa1,bunit2x,dx2,dy2,bmaj2,bmin2,bpa2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bunit1x -
            dx1 -
            dy1 -
            bmaj1 -
            bmin1 -
            bpa1 -
            bunit2x -
            dx2 -
            dy2 -
            bmaj2 -
            bmin2 -
            bpa2 -
        returns :   (as a tuple)
            bunit -
            bmaj -
            bmin -
            bpa -
            fac -
    """
    bunit = "              "
    dx1X = miriad_io.copy_doublep(dx1)
    dy1X = miriad_io.copy_doublep(dy1)
    bmaj1X = miriad_io.copy_floatp(bmaj1)
    bmin1X = miriad_io.copy_floatp(bmin1)
    bpa1X = miriad_io.copy_floatp(bpa1)
    dx2X = miriad_io.copy_doublep(dx2)
    dy2X = miriad_io.copy_doublep(dy2)
    bmaj2X = miriad_io.copy_floatp(bmaj2)
    bmin2X = miriad_io.copy_floatp(bmin2)
    bpa2X = miriad_io.copy_floatp(bpa2)
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    facX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.gaupar_,(bunit1x,dx1X,dy1X,bmaj1X,bmin1X,bpa1X,bunit2x,dx2X,dy2X,bmaj2X,bmin2X,bpa2X,bunit,bmajX,bminX,bpaX,facX,len(bunit1x),len(bunit2x),10))
        del XX
    except :
        pass
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    facR = miriad_io.floatp_value(facX)
    bunit = bunit.strip()
    return bunit,bmajR,bminR,bpaR,facR

def gaufac(bmaj1,bmin1,bpa1,bmaj2,bmin2,bpa2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bmaj1 -
            bmin1 -
            bpa1 -
            bmaj2 -
            bmin2 -
            bpa2 -
        returns :   (as a tuple)
            fac -
            bmaj -
            bmin -
            bpa -
            ifail -
    """
    bmaj1X = miriad_io.copy_floatp(bmaj1)
    bmin1X = miriad_io.copy_floatp(bmin1)
    bpa1X = miriad_io.copy_floatp(bpa1)
    bmaj2X = miriad_io.copy_floatp(bmaj2)
    bmin2X = miriad_io.copy_floatp(bmin2)
    bpa2X = miriad_io.copy_floatp(bpa2)
    facX = miriad_io.new_floatp()
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    ifailX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.gaufac_,(bmaj1X,bmin1X,bpa1X,bmaj2X,bmin2X,bpa2X,facX,bmajX,bminX,bpaX,ifailX))
        del XX
    except :
        pass
    facR = miriad_io.floatp_value(facX)
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    ifailR = miriad_io.intp_value(ifailX)
    return facR,bmajR,bminR,bpaR,ifailR

def gaudfac(bmaj1,bmin1,bpa1,bmaj2,bmin2,bpa2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            bmaj1 -
            bmin1 -
            bpa1 -
            bmaj2 -
            bmin2 -
            bpa2 -
        returns :   (as a tuple)
            fac -
            bmaj -
            bmin -
            bpa -
            ifail -
    """
    bmaj1X = miriad_io.copy_floatp(bmaj1)
    bmin1X = miriad_io.copy_floatp(bmin1)
    bpa1X = miriad_io.copy_floatp(bpa1)
    bmaj2X = miriad_io.copy_floatp(bmaj2)
    bmin2X = miriad_io.copy_floatp(bmin2)
    bpa2X = miriad_io.copy_floatp(bpa2)
    facX = miriad_io.new_floatp()
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    ifailX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.gaudfac_,(bmaj1X,bmin1X,bpa1X,bmaj2X,bmin2X,bpa2X,facX,bmajX,bminX,bpaX,ifailX))
        del XX
    except :
        pass
    facR = miriad_io.floatp_value(facX)
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    ifailR = miriad_io.intp_value(ifailX)
    return facR,bmajR,bminR,bpaR,ifailR

def getbeam(lin,naxis) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
            naxis -
        returns :   (as a tuple)
            bunit -
            bmaj -
            bmin -
            omega -
            cbof -
    """
    bunit = "              "
    linX = miriad_io.copy_intp(lin)
    naxisX = miriad_io.copy_intp(naxis)
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    omegaX = miriad_io.new_floatp()
    cbofX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.getbeam_,(linX,naxisX,bunit,bmajX,bminX,omegaX,cbofX,10))
        del XX
    except :
        pass
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    omegaR = miriad_io.floatp_value(omegaX)
    cbofR = miriad_io.floatp_value(cbofX)
    bunit = bunit.strip()
    return bunit,bmajR,bminR,omegaR,cbofR

def getfreq(tin,pix,ifax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin -
            pix -
            ifax -
        returns :   (as a tuple)
            ifax -
            freq -
            finc -
            ierr -
    """
    tinX = miriad_io.copy_intp(tin)
    pixX = miriad_io.copy_floatp(pix)
    ifaxX = miriad_io.copy_intp(ifax)
    freqX = miriad_io.new_doublep()
    fincX = miriad_io.new_doublep()
    ierrX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.getfreq_,(tinX,pixX,ifaxX,freqX,fincX,ierrX))
        del XX
    except :
        pass
    ifaxR =  miriad_io.intp_value(ifaxX)
    freqR = miriad_io.doublep_value(freqX)
    fincR = miriad_io.doublep_value(fincX)
    ierrR = miriad_io.intp_value(ierrX)
    return ifaxR,freqR,fincR,ierrR

def getpb(tno,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            name -
        returns :   (as a tuple)
            pbfwhm -
    """
    tnoX = miriad_io.copy_intp(tno)
    pbfwhmX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.getpb_,(tnoX,name,pbfwhmX,len(name)))
        del XX
    except :
        pass
    pbfwhmR = miriad_io.floatp_value(pbfwhmX)
    return pbfwhmR

def getxy(tno,mxant) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            mxant -
        returns :   (as a tuple)
            fac -
            xyphase -
            count -
            nants -
    """
    tnoX = miriad_io.copy_intp(tno)
    facX = miriad_io.new_floatp()
    xyphaseX = floatArray(mxant)
    countX = intArray(mxant)
    mxantX = miriad_io.copy_intp(mxant)
    nantsX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.getxy_,(tnoX,facX,xyphaseX,countX,mxantX,nantsX))
        del XX
    except :
        pass
    facR = miriad_io.floatp_value(facX)
    xyphaseR = floatArrayToList(xyphaseX,mxant)
    del xyphaseX
    countR = intArrayToList(countX,mxant)
    del countX
    nantsR = miriad_io.intp_value(nantsX)
    return facR,xyphaseR,countR,nantsR

def corrfun(func,n,width,alpha) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            func -
            n -
            width -
            alpha -
        returns :   (as a tuple)
            phi -
    """
    phiX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    widthX = miriad_io.copy_intp(width)
    alphaX = miriad_io.copy_floatp(alpha)
    try :
        XX = mx.safecall(miriad_io.corrfun_,(func,phiX,nX,widthX,alphaX,len(func)))
        del XX
    except :
        pass
    phiR = floatArrayToList(phiX,n)
    del phiX
    return func,phiR

def gcffun(func,n,width,alpha) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            func -
            n -
            width -
            alpha -
        returns :   (as a tuple)
            phi -
    """
    phiX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    widthX = miriad_io.copy_intp(width)
    alphaX = miriad_io.copy_floatp(alpha)
    try :
        XX = mx.safecall(miriad_io.gcffun_,(func,phiX,nX,widthX,alphaX,len(func)))
        del XX
    except :
        pass
    phiR = floatArrayToList(phiX,n)
    del phiX
    return func,phiR

def hcoeffs(nsmth) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nsmth -
        returns :   (as a tuple)
            coeffs -
    """
    nsmthX = miriad_io.copy_intp(nsmth)
    coeffsX = floatArray(nsmth)
    try :
        XX = mx.safecall(miriad_io.hcoeffs_,(nsmthX,coeffsX))
        del XX
    except :
        pass
    coeffsR = floatArrayToList(coeffsX,nsmth)
    del coeffsX
    return coeffsR

def bico(n,k) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            k -
        returns :   (as a tuple)
            c -
    """
    nX = miriad_io.copy_intp(n)
    kX = miriad_io.copy_intp(k)
    cX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.bico_,(nX,kX,cX))
        del XX
    except :
        pass
    cR = miriad_io.floatp_value(cX)
    return cR

def hannsm(nsmth,coeffs,npts,arr,work) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nsmth -
            coeffs -
            npts -
            arr -
            work -
        returns :   (as a tuple)
            arr -
            work -
    """
    nsmthX = miriad_io.copy_intp(nsmth)
    coeffsX = floatListToArray(coeffs)
    nptsX = miriad_io.copy_intp(npts)
    arrX = floatListToArray(arr)
    workX = floatListToArray(work)
    try :
        XX = mx.safecall(miriad_io.hannsm_,(nsmthX,coeffsX,nptsX,arrX,workX))
        del XX
    except :
        pass
    del coeffsX
    arrR = floatArrayToList(arrX,npts)
    del arrX
    workR = floatArrayToList(workX,nsmth)
    del workX
    return arrR,workR

def bcoeffs(nsmth) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nsmth -
        returns :   (as a tuple)
            coeffs -
    """
    nsmthX = miriad_io.copy_intp(nsmth)
    coeffsX = floatArray(1000)
    try :
        XX = mx.safecall(miriad_io.bcoeffs_,(nsmthX,coeffsX))
        del XX
    except :
        pass
    coeffsR = floatArrayToList(coeffsX,1000)
    del coeffsX
    return coeffsR

def boxcarsm(nsmth,coeffs,npts,arr,work) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nsmth -
            coeffs -
            npts -
            arr -
            work -
        returns :   (as a tuple)
            arr -
            work -
    """
    nsmthX = miriad_io.copy_intp(nsmth)
    coeffsX = floatListToArray(coeffs)
    nptsX = miriad_io.copy_intp(npts)
    arrX = floatListToArray(arr)
    workX = floatListToArray(work)
    try :
        XX = mx.safecall(miriad_io.boxcarsm_,(nsmthX,coeffsX,nptsX,arrX,workX))
        del XX
    except :
        pass
    del coeffsX
    arrR = floatArrayToList(arrX,npts)
    del arrX
    workR = floatArrayToList(workX,nsmth)
    del workX
    return arrR,workR


def headcopy(tnoinp,tnoout,axnum,naxis,blc,trc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tnoinp -
            tnoout -
            axnum -
            naxis -
            blc -
            trc -
        returns :   (as a tuple)
    """
    tnoinpX = miriad_io.copy_intp(tnoinp)
    tnooutX = miriad_io.copy_intp(tnoout)
    axnumX = intListToArray(axnum)
    naxisX = miriad_io.copy_intp(naxis)
    blcX = intListToArray(blc)
    trcX = intListToArray(trc)
    try :
        XX = mx.safecall(miriad_io.headcopy_,(tnoinpX,tnooutX,axnumX,naxisX,blcX,trcX))
        del XX
    except :
        pass
    del axnumX
    del blcX
    del trcX

def hisinput(tno,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            name -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.hisinput_,(tnoX,name,len(name)))
        del XX
    except :
        pass

def hsorta(n,array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsorta_,(nX,array,indxX,len(array)))
        del XX
    except :
        pass
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsorti(n,array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsorti_,(nX,arrayX,indxX))
        del XX
    except :
        pass
    del arrayX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsortr(n,array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsortr_,(nX,arrayX,indxX))
        del XX
    except :
        pass
    del arrayX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsortd(n,array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = doubleListToArray(array)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsortd_,(nX,arrayX,indxX))
        del XX
    except :
        pass
    del arrayX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsortar(n,array,second) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            second -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    secondX = floatListToArray(second)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsortar_,(nX,array,secondX,indxX,len(array)))
        del XX
    except :
        pass
    del secondX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsortad(n,array,second) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            second -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    secondX = doubleListToArray(second)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsortad_,(nX,array,secondX,indxX,len(array)))
        del XX
    except :
        pass
    del secondX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def hsortrr(n,array,second) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            second -
        returns :   (as a tuple)
            indx -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    secondX = floatListToArray(second)
    indxX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.hsortrr_,(nX,arrayX,secondX,indxX))
        del XX
    except :
        pass
    del arrayX
    del secondX
    indxR = intArrayToList(indxX,n)
    del indxX
    return indxR

def imminmax(lun,naxis,nsize) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lun -
            naxis -
            nsize -
        returns :   (as a tuple)
            rmin -
            rmax -
    """
    lunX = miriad_io.copy_intp(lun)
    naxisX = miriad_io.copy_intp(naxis)
    nsizeX = intListToArray(nsize)
    rminX = miriad_io.new_floatp()
    rmaxX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.imminmax_,(lunX,naxisX,nsizeX,rminX,rmaxX))
        del XX
    except :
        pass
    del nsizeX
    rminR = miriad_io.floatp_value(rminX)
    rmaxR = miriad_io.floatp_value(rmaxX)
    return rminR,rmaxR

def incini(n,size) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            size -
        returns :   (as a tuple)
            dims -
    """
    nX = miriad_io.copy_intp(n)
    sizeX = intListToArray(uncastLogical(size))
    dimsX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.incini_,(nX,sizeX,dimsX))
        del XX
    except :
        pass
    dimsR = intArrayToList(dimsX,n)
    del sizeX
    del dimsX
    return dimsR

def incoff(n,size1,size2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            size1 -
            size2 -
        returns :   (as a tuple)
            out -
    """
    nX = miriad_io.copy_intp(n)
    size1X = intListToArray(size1)
    size2X = intListToArray(size2)
    outX = intArray(n)
    try :
        XX = mx.safecall(miriad_io.incoff_,(nX,size1X,size2X,outX))
        del XX
    except :
        pass
    del size1X
    del size2X
    outR = intArrayToList(outX,n)
    del outX
    return outR

def intpini(n1,n2,blctrc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n1 -
            n2 -
            blctrc -
        returns :   (as a tuple)
    """
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    blctrcX = floatListToArray(blctrc)
    try :
        XX = mx.safecall(miriad_io.intpini_,(n1X,n2X,blctrcX))
        del XX
    except :
        pass
    del blctrcX

def intprini():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.intprini_)
    except :
        pass
    return XX

def intprd(lu,jj,intpget) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            jj -
            intpget -
        returns :   (as a tuple)
            out -
    """
    luX = miriad_io.copy_intp(lu)
    jjX = miriad_io.copy_intp(jj)
    outX = floatArray(10000)
    intpgetX = miriad_io.copy_intp(intpget)
    try :
        XX = mx.safecall(miriad_io.intprd_,(luX,jjX,outX,intpgetX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,10000)
    del outX
    return outR

def intpolat(n,indx,z0,z1,z2,z3,wx0,wx1,wx2,wx3,wy0,wy1,wy2,wy3) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            indx -
            z0 -
            z1 -
            z2 -
            z3 -
            wx0 -
            wx1 -
            wx2 -
            wx3 -
            wy0 -
            wy1 -
            wy2 -
            wy3 -
        returns :   (as a tuple)
            out -
    """
    outX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    indxX = intListToArray(indx)
    z0X = floatListToArray(z0)
    z1X = floatListToArray(z1)
    z2X = floatListToArray(z2)
    z3X = floatListToArray(z3)
    wx0X = floatListToArray(wx0)
    wx1X = floatListToArray(wx1)
    wx2X = floatListToArray(wx2)
    wx3X = floatListToArray(wx3)
    wy0X = miriad_io.copy_floatp(wy0)
    wy1X = miriad_io.copy_floatp(wy1)
    wy2X = miriad_io.copy_floatp(wy2)
    wy3X = miriad_io.copy_floatp(wy3)
    try :
        XX = mx.safecall(miriad_io.intpolat_,(outX,nX,indxX,z0X,z1X,z2X,z3X,wx0X,wx1X,wx2X,wx3X,wy0X,wy1X,wy2X,wy3X))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,n)
    del outX
    del indxX
    del z0X
    del z1X
    del z2X
    del z3X
    del wx0X
    del wx1X
    del wx2X
    del wx3X
    return outR

def julday(julian,form) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            julian -
            form -
        returns :   (as a tuple)
            calday -
    """
    calday = "                           "
    julianX = miriad_io.copy_doublep(julian)
    try :
        XX = mx.safecall(miriad_io.julday_,(julianX,form,calday,len(form),25))
        del XX
    except :
        pass
    return calday

def julcal(julian) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            julian -
        returns :   (as a tuple)
            year -
            month -
            day -
    """
    julianX = miriad_io.copy_doublep(julian)
    yearX = miriad_io.new_intp()
    monthX = miriad_io.new_intp()
    dayX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.julcal_,(julianX,yearX,monthX,dayX))
        del XX
    except :
        pass
    yearR = miriad_io.intp_value(yearX)
    monthR = miriad_io.intp_value(monthX)
    dayR = miriad_io.doublep_value(dayX)
    return yearR,monthR,dayR

def dayjul(calday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            calday -
        returns :   (as a tuple)
            julian -
    """
    julianX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.dayjul_,(calday,julianX,len(calday)))
        del XX
    except :
        pass
    julianR = miriad_io.doublep_value(julianX)
    return julianR

def datepars(calday,a,z,alpha,delim) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            calday -
            z -
            alpha -
            delim -
        returns :   (as a tuple)
            a -
            iarray -
            ok -
    """
    aX = miriad_io.copy_intp(a)
    zX = miriad_io.copy_intp(z)
    alphaX = miriad_io.copy_intp(uncastLogical(alpha))
    iarrayX = intArray(3)
    okX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.datepars_,(calday,aX,zX,alphaX,delim,iarrayX,okX,len(calday),len(delim)))
        del XX
    except :
        pass
    aR = miriad_io.intp_value(aX)
    iarrayR = intArrayToList(iarrayX,3)
    del iarrayX
    okR = castLogical(miriad_io.intp_value(okX))
    return aR,iarrayR,okR

def todayjul() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            julian -
    """
    julianX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.todayjul_,(julianX,))
        del XX
    except :
        pass
    julianR = miriad_io.doublep_value(julianX)
    return julianR

def lagwt(nwts,fac) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nwts -
            fac -
        returns :   (as a tuple)
            wts -
    """
    wtsX = floatArray(nwts)
    nwtsX = miriad_io.copy_intp(nwts)
    facX = miriad_io.copy_floatp(fac)
    try :
        XX = mx.safecall(miriad_io.lagwt_,(wtsX,nwtsX,facX))
        del XX
    except :
        pass
    wtsR = floatArrayToList(wtsX,nwts)
    del wtsX
    return wtsR

def linetype(unit) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            unit -
        returns :   (as a tuple)
            typeX -
            line -
    """
    typeX = "                "
    unitX = miriad_io.copy_intp(unit)
    lineX = floatArray(4)
    try :
        XX = mx.safecall(miriad_io.linetype_,(unitX,lineX,typeX,15))
        del XX
    except :
        pass
    lineR = floatArrayToList(lineX,4)
    del lineX
    typeX = typeX.strip()
    return typeX,lineR

def logopen(name,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            flags -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.logopen_,(name,flags,len(name),len(flags)))
        del XX
    except :
        pass

def logwrit(line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            line -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.logwrit_,(line,len(line)))
        del XX
    except :
        pass

def logwrite(line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            line -
        returns :   (as a tuple)
            more -
    """
    moreX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.logwrite_,(line,moreX,len(line)))
        del XX
    except :
        pass
    moreR = castLogical(miriad_io.intp_value(moreX))
    return moreR

def logclose():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.logclose_)
    except :
        pass
    return XX

def loginput(name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.loginput_,(name,len(name)))
        del XX
    except :
        pass

def lsearchd(n,x,t) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            x -
            t -
        returns :   (as a tuple)
            i -
    """
    nX = miriad_io.copy_intp(n)
    xX = doubleListToArray(x)
    tX = miriad_io.copy_doublep(t)
    iX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.lsearchd_,(nX,xX,tX,iX))
        del XX
    except :
        pass
    del xX
    iR = miriad_io.intp_value(iX)
    return iR

def lsf(noerr,n,x,y,w) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            noerr -
            n -
            x -
            y -
            w -
        returns :   (as a tuple)
            m -
            b -
            sigm -
            sigb -
            chisq -
            q -
    """
    noerrX = miriad_io.copy_intp(uncastLogical(noerr))
    nX = miriad_io.copy_intp(n)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    wX = floatListToArray(w)
    mX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    sigmX = miriad_io.new_floatp()
    sigbX = miriad_io.new_floatp()
    chisqX = miriad_io.new_floatp()
    qX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.lsf_,(noerrX,nX,xX,yX,wX,mX,bX,sigmX,sigbX,chisqX,qX))
        del XX
    except :
        pass
    del xX
    del yX
    del wX
    mR = miriad_io.floatp_value(mX)
    bR = miriad_io.floatp_value(bX)
    sigmR = miriad_io.floatp_value(sigmX)
    sigbR = miriad_io.floatp_value(sigbX)
    chisqR = miriad_io.floatp_value(chisqX)
    qR = miriad_io.floatp_value(qX)
    return mR,bR,sigmR,sigbR,chisqR,qR

def lspoly(nn,l,x,y,w) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nn -
            l -
            x -
            y -
            w -
        returns :   (as a tuple)
            z -
            coeff -
    """
    nnX = miriad_io.copy_intp(nn)
    lX = miriad_io.copy_intp(l)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    wX = floatListToArray(w)
    zX = floatArray(l)
    coeffX = floatArray(9)
    try :
        XX = mx.safecall(miriad_io.lspoly_,(nnX,lX,xX,yX,wX,zX,coeffX))
        del XX
    except :
        pass
    del xX
    del yX
    del wX
    zR = floatArrayToList(zX,l)
    del zX
    coeffR = floatArrayToList(coeffX,9)
    del coeffX
    return zR,coeffR

def legdr(x,np) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            np -
        returns :   (as a tuple)
            p -
    """
    xX = miriad_io.copy_floatp(x)
    pX = floatArray(np)
    npX = miriad_io.copy_intp(np)
    try :
        XX = mx.safecall(miriad_io.legdr_,(xX,pX,npX))
        del XX
    except :
        pass
    pR = floatArrayToList(pX,np)
    del pX
    return pR

def llsquini(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            x -
            b -
    """
    xX = floatArray(n)
    bX = floatArray(n,n)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.llsquini_,(xX,bX,nX))
        del XX
    except :
        pass
    xR = floatArrayToList(xX,n)
    del xX
    bR = floatArrayToList(bX,n,n)
    del bX
    return xR,bR

def llsquacc(f,a,x,b,m,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            f -
            a -
            x -
            b -
            m -
            n -
        returns :   (as a tuple)
            b -
    """
    fX = floatListToArray(f)
    aX = floatListToArray(a)
    xX = floatListToArray(x)
    bX = floatListToArray(b)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.llsquacc_,(fX,aX,xX,bX,mX,nX))
        del XX
    except :
        pass
    del fX
    del aX
    del xX
    bR = floatArrayToList(bX,n,n)
    del bX
    return bR

def llsqusol(x,b,n,ifail,pivot) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            b -
            n -
            ifail -
            pivot -
        returns :   (as a tuple)
            b -
            x -
            ifail -
    """
    xX = floatListToArray(x)
    bX = floatListToArray(b)
    nX = miriad_io.copy_intp(n)
    ifailX = miriad_io.copy_intp(ifail)
    pivotX = floatListToArray(pivot)
    try :
        XX = mx.safecall(miriad_io.llsqusol_,(xX,bX,nX,ifailX,pivotX))
        del XX
    except :
        pass
    xR = floatArrayToList(xX,n)
    del xX
    bR = floatArrayToList(bX,n,n)
    del bX
    ifailR = miriad_io.intp_value(ifailX)
    del pivotX
    return bR,xR,ifailR

def llsqu(f,a,b,pivot) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            f -
            a -
            n -
            m -
            b -
            pivot -
        returns :   (as a tuple)
            c -
            ifail -
    """
    n = len(pivot)
    m = len(f)
    fX = floatListToArray(f)
    aX = floatListToArray(a)
    nX = miriad_io.copy_intp(n)
    mX = miriad_io.copy_intp(m)
    cX = floatArray(n)
    ifailX = miriad_io.new_intp()
    bX = floatListToArray(b)
    pivotX = intListToArray(pivot)
    try :
        XX = mx.safecall(miriad_io.llsqu_,(fX,aX,nX,mX,cX,ifailX,bX,pivotX))
        del XX
    except :
        pass
    del fX
    del aX
    cR = floatArrayToList(cX,n)
    del cX
    ifailR = miriad_io.intp_value(ifailX)
    del bX
    del pivotX
    return cR,ifailR

def linlsq(xarr,yarr,npnt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            xarr -
            yarr -
            npnt -
        returns :   (as a tuple)
            a1 -
            b1 -
            a2 -
            b2 -
            sigx -
            sigy -
            corr -
    """
    xarrX = floatListToArray(xarr)
    yarrX = floatListToArray(yarr)
    npntX = miriad_io.copy_intp(npnt)
    a1X = miriad_io.new_floatp()
    b1X = miriad_io.new_floatp()
    a2X = miriad_io.new_floatp()
    b2X = miriad_io.new_floatp()
    sigxX = miriad_io.new_floatp()
    sigyX = miriad_io.new_floatp()
    corrX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.linlsq_,(xarrX,yarrX,npntX,a1X,b1X,a2X,b2X,sigxX,sigyX,corrX))
        del XX
    except :
        pass
    del xarrX
    del yarrX
    a1R = miriad_io.floatp_value(a1X)
    b1R = miriad_io.floatp_value(b1X)
    a2R = miriad_io.floatp_value(a2X)
    b2R = miriad_io.floatp_value(b2X)
    sigxR = miriad_io.floatp_value(sigxX)
    sigyR = miriad_io.floatp_value(sigyX)
    corrR = miriad_io.floatp_value(corrX)
    return a1R,b1R,a2R,b2R,sigxR,sigyR,corrR

def mapfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mapfin_)
    except :
        pass
    return XX

def mapini(mode1,tscr1,nvis1,npnt1,umax1,vmax1,offcorr1,totchan1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode1 -
            tscr1 -
            nvis1 -
            npnt1 -
            umax1 -
            vmax1 -
            offcorr1 -
            totchan1 -
        returns :   (as a tuple)
    """
    tscr1X = miriad_io.copy_intp(tscr1)
    nvis1X = miriad_io.copy_intp(nvis1)
    npnt1X = miriad_io.copy_intp(npnt1)
    umax1X = miriad_io.copy_floatp(umax1)
    vmax1X = miriad_io.copy_floatp(vmax1)
    offcorr1X = miriad_io.copy_intp(offcorr1)
    totchan1X = miriad_io.copy_intp(totchan1)
    try :
        XX = mx.safecall(miriad_io.mapini_,(mode1,tscr1X,nvis1X,npnt1X,umax1X,vmax1X,offcorr1X,totchan1X,len(mode1)))
        del XX
    except :
        pass

def mapdef(nchan1,nx1,ny1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nchan1 -
            nx1 -
            ny1 -
        returns :   (as a tuple)
    """
    nchan1X = miriad_io.copy_intp(nchan1)
    nx1X = miriad_io.copy_intp(nx1)
    ny1X = miriad_io.copy_intp(ny1)
    try :
        XX = mx.safecall(miriad_io.mapdef_,(nchan1X,nx1X,ny1X))
        del XX
    except :
        pass

def mapscale(ichan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ichan -
        returns :   (as a tuple)
    """
    ichanX = miriad_io.copy_intp(ichan)
    try :
        XX = mx.safecall(miriad_io.mapscale_,(ichanX,))
        del XX
    except :
        pass

def mapper(ichan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ichan -
        returns :   (as a tuple)
            pmap -
    """
    ichanX = miriad_io.copy_intp(ichan)
    pmapX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mapper_,(ichanX,pmapX))
        del XX
    except :
        pass
    pmapR = miriad_io.intp_value(pmapX)
    return pmapR

def mapbufs(ichan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ichan -
        returns :   (as a tuple)
    """
    ichanX = miriad_io.copy_intp(ichan)
    try :
        XX = mx.safecall(miriad_io.mapbufs_,(ichanX,))
        del XX
    except :
        pass

def mapvsum(dat,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dat -
            n -
        returns :   (as a tuple)
            sum -
    """
    datX = miriad_io.copy_Fcomplexp(convertComplex(dat))
    nX = miriad_io.copy_intp(n)
    sumX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.mapvsum_,(datX,nX,sumX))
        del XX
    except :
        pass
    sumR = miriad_io.floatp_value(sumX)
    return sumR

def mapgrid(ichan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ichan -
        returns :   (as a tuple)
    """
    ichanX = miriad_io.copy_intp(ichan)
    try :
        XX = mx.safecall(miriad_io.mapgrid_,(ichanX,))
        del XX
    except :
        pass

def mapginit():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mapginit_)
    except :
        pass
    return XX

def mapbuf(ichan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ichan -
        returns :   (as a tuple)
    """
    ichanX = miriad_io.copy_intp(ichan)
    try :
        XX = mx.safecall(miriad_io.mapbuf_,(ichanX,))
        del XX
    except :
        pass

def mapvis(tvis,cgf,ncgf,width,nvis,nstart,ncount,vissize,nu,nv,npnt,u0,v0,n1,n2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            cgf -
            ncgf -
            width -
            nvis -
            nstart -
            ncount -
            vissize -
            nu -
            nv -
            npnt -
            u0 -
            v0 -
            n1 -
            n2 -
        returns :   (as a tuple)
            grd -
    """
    tvisX = miriad_io.copy_intp(tvis)
    cgfX = floatListToArray(cgf)
    ncgfX = miriad_io.copy_intp(ncgf)
    widthX = miriad_io.copy_intp(width)
    nvisX = miriad_io.copy_intp(nvis)
    nstartX = miriad_io.copy_intp(nstart)
    ncountX = miriad_io.copy_intp(ncount)
    vissizeX = miriad_io.copy_intp(vissize)
    grdX = FcomplexArray(nu,nv,npnt,ncount)
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    npntX = miriad_io.copy_intp(npnt)
    u0X = miriad_io.copy_intp(u0)
    v0X = miriad_io.copy_intp(v0)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    try :
        XX = mx.safecall(miriad_io.mapvis_,(tvisX,cgfX,ncgfX,widthX,nvisX,nstartX,ncountX,vissizeX,grdX,nuX,nvX,npntX,u0X,v0X,n1X,n2X))
        del XX
    except :
        pass
    del cgfX
    grdR = unconvertComplex(miriad_io.doublep_value(grdX,nu,nv,npnt,ncount))
    return grdR

def mapit(vis,nvis,offset,ncount,npnt,size,grd,nu,nv,u0,v0,n1,n2,cgf,ncgf,width,poff,qoff,goff) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            vis -
            nvis -
            offset -
            ncount -
            npnt -
            size -
            grd -
            nu -
            nv -
            u0 -
            v0 -
            n1 -
            n2 -
            cgf -
            ncgf -
            width -
            poff -
            qoff -
            goff -
        returns :   (as a tuple)
    """
    visX = floatListToArray(vis)
    nvisX = miriad_io.copy_intp(nvis)
    offsetX = miriad_io.copy_intp(offset)
    ncountX = miriad_io.copy_intp(ncount)
    npntX = miriad_io.copy_intp(npnt)
    sizeX = miriad_io.copy_intp(size)
    grdX = miriad_io.copy_Fcomplexp(convertComplex(grd))
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    u0X = miriad_io.copy_intp(u0)
    v0X = miriad_io.copy_intp(v0)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    cgfX = floatListToArray(cgf)
    ncgfX = miriad_io.copy_intp(ncgf)
    widthX = miriad_io.copy_intp(width)
    poffX = intListToArray(poff)
    qoffX = intListToArray(qoff)
    goffX = intListToArray(goff)
    try :
        XX = mx.safecall(miriad_io.mapit_,(visX,nvisX,offsetX,ncountX,npntX,sizeX,grdX,nuX,nvX,u0X,v0X,n1X,n2X,cgfX,ncgfX,widthX,poffX,qoffX,goffX))
        del XX
    except :
        pass
    del visX
    del cgfX
    del poffX
    del qoffX
    del goffX

def mapindx(ncgf,width,nu) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ncgf -
            width -
            nu -
        returns :   (as a tuple)
            poff -
            qoff -
            goff -
    """
    ncgfX = miriad_io.copy_intp(ncgf)
    widthX = miriad_io.copy_intp(width)
    nuX = miriad_io.copy_intp(nu)
    poffX = intArray(width*width)
    qoffX = intArray(width*width)
    goffX = intArray(width*width)
    try :
        XX = mx.safecall(miriad_io.mapindx_,(ncgfX,widthX,nuX,poffX,qoffX,goffX))
        del XX
    except :
        pass
    poffR = intArrayToList(poffX,width*width)
    del poffX
    qoffR = intArrayToList(qoffX,width*width)
    del qoffX
    goffR = intArrayToList(goffX,width*width)
    del goffX
    return poffR,qoffR,goffR

def mapfft2(grd,inoff,outoff,nu,nv,nx,ny,n1,u0,v0,scale,xcorr,ycorr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            grd -
            inoff -
            outoff -
            nu -
            nv -
            nx -
            ny -
            n1 -
            u0 -
            v0 -
            scale -
            xcorr -
            ycorr -
        returns :   (as a tuple)
            grd -
    """
    grdX = floatListToArray(grd)
    l = len(grd)
    inoffX = miriad_io.copy_intp(inoff)
    outoffX = miriad_io.copy_intp(outoff)
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    n1X = miriad_io.copy_intp(n1)
    u0X = miriad_io.copy_intp(u0)
    v0X = miriad_io.copy_intp(v0)
    scaleX = miriad_io.copy_floatp(scale)
    xcorrX = floatListToArray(xcorr)
    ycorrX = floatListToArray(ycorr)
    try :
        XX = mx.safecall(miriad_io.mapfft2_,(grdX,inoffX,outoffX,nuX,nvX,nxX,nyX,n1X,u0X,v0X,scaleX,xcorrX,ycorrX))
        del XX
    except :
        pass
    grdR = floatArrayToList(grdX,l)
    del grdX
    del xcorrX
    del ycorrX
    return grdR

def mapfft1(grd,nu,nv,u0,v0,n2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            grd -
            nu -
            nv -
            u0 -
            v0 -
            n2 -
        returns :   (as a tuple)
            grd -
    """
    grdX = FcomplexListToArray(grd)
    l = len(grd)
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    u0X = miriad_io.copy_intp(u0)
    v0X = miriad_io.copy_intp(v0)
    n2X = miriad_io.copy_intp(n2)
    try :
        XX = mx.safecall(miriad_io.mapfft1_,(grdX,nuX,nvX,u0X,v0X,n2X))
        del XX
    except :
        pass
    grdR = complexArrayToList(grdX,2*l)
    return grdR

def mapslows(tscr,nvis,offcorr,vissize) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tscr -
            nvis -
            offcorr -
            vissize -
        returns :   (as a tuple)
            sum -
    """
    tscrX = miriad_io.copy_intp(tscr)
    nvisX = miriad_io.copy_intp(nvis)
    offcorrX = miriad_io.copy_intp(offcorr)
    vissizeX = miriad_io.copy_intp(vissize)
    sumX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.mapslows_,(tscrX,nvisX,offcorrX,vissizeX,sumX))
        del XX
    except :
        pass
    sumR = miriad_io.floatp_value(sumX)
    return sumR

def mapslow(tscr,mode,nvis,offcorr,vissize,dat,wrk,nx,ny,scale) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tscr -
            mode -
            nvis -
            offcorr -
            vissize -
            dat -
            wrk -
            nx -
            ny -
            scale -
        returns :   (as a tuple)
            map -
    """
    tscrX = miriad_io.copy_intp(tscr)
    nvisX = miriad_io.copy_intp(nvis)
    offcorrX = miriad_io.copy_intp(offcorr)
    vissizeX = miriad_io.copy_intp(vissize)
    datX = miriad_io.copy_floatp(dat)
    wrkX = miriad_io.copy_floatp(wrk)
    mapX = floatArray(nx,ny)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    scaleX = miriad_io.copy_floatp(scale)
    try :
        XX = mx.safecall(miriad_io.mapslow_,(tscrX,mode,nvisX,offcorrX,vissizeX,datX,wrkX,mapX,nxX,nyX,scaleX,len(mode)))
        del XX
    except :
        pass
    mapR = floatArrayToList(mapX,nx,ny)
    del mapX
    return mapR

def whenfeq(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenfeq_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenfne(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenfne_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenflt(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenflt_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenfle(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenfle_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenfgt(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenfgt_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenfge(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = floatListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_floatp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenfge_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenieq(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenieq_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenine(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenine_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenilt(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenilt_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenile(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenile_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenigt(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenigt_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def whenige(n,array,inc,target) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
            array -
            inc -
            target -
        returns :   (as a tuple)
            index -
    """
    nX = miriad_io.copy_intp(n)
    arrayX = intListToArray(array)
    incX = miriad_io.copy_intp(inc)
    targetX = miriad_io.copy_intp(target)
    indexX = intArray(10000)
    nvalX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.whenige_,(nX,arrayX,incX,targetX,indexX,nvalX))
        del XX
    except :
        pass
    del arrayX
    nvalR = miriad_io.intp_value(nvalX)
    indexR = intArrayToList(indexX,nvalR)
    del indexX
    return indexR

def mcinitfg(tno1,bmaj1,bmin1,bpa1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno1 -
            bmaj1 -
            bmin1 -
            bpa1 -
        returns :   (as a tuple)
    """
    tno1X = miriad_io.copy_intp(tno1)
    bmaj1X = miriad_io.copy_floatp(bmaj1)
    bmin1X = miriad_io.copy_floatp(bmin1)
    bpa1X = miriad_io.copy_floatp(bpa1)
    try :
        XX = mx.safecall(miriad_io.mcinitfg_,(tno1X,bmaj1X,bmin1X,bpa1X))
        del XX
    except :
        pass

def mcinitf(tno1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno1 -
        returns :   (as a tuple)
    """
    tno1X = miriad_io.copy_intp(tno1)
    try :
        XX = mx.safecall(miriad_io.mcinitf_,(tno1X,))
        del XX
    except :
        pass

def mcplane(coobj,k) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            k -
        returns :   (as a tuple)
    """
    coobjX = miriad_io.copy_intp(coobj)
    kX = miriad_io.copy_intp(k)
    try :
        XX = mx.safecall(miriad_io.mcplane_,(coobjX,kX))
        del XX
    except :
        pass

def mccnvl(inp,nix,niy,nox,noy) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            in -
            nix -
            niy -
            nox -
            noy -
        returns :   (as a tuple)
            out -
    """
    inX = floatListToArray(inp)
    nixX = miriad_io.copy_intp(nix)
    niyX = miriad_io.copy_intp(niy)
    outX = floatArray(nox,noy)
    noxX = miriad_io.copy_intp(nox)
    noyX = miriad_io.copy_intp(noy)
    try :
        XX = mx.safecall(miriad_io.mccnvl_,(inX,nixX,niyX,outX,noxX,noyX))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,nox,noy)
    del outX
    return outR

def mcplaner(coobj,k,runs,nruns,npoint) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            k -
            runs -
            nruns -
            npoint -
        returns :   (as a tuple)
    """
    coobjX = miriad_io.copy_intp(coobj)
    kX = miriad_io.copy_intp(k)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    npointX = miriad_io.copy_intp(npoint)
    try :
        XX = mx.safecall(miriad_io.mcplaner_,(coobjX,kX,runsX,nrunsX,npointX))
        del XX
    except :
        pass
    del runsX

def mcgain() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            gain -
            npoint -
    """
    gainX = floatArray(1000)
    npointX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mcgain_,(gainX,npointX))
        del XX
    except :
        pass
    npointR = miriad_io.intp_value(npointX)
    gainR = floatArrayToList(gainX,npointR)
    del gainX
    return gainR

def mcgn(wt1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            wt1 -
        returns :   (as a tuple)
            gain -
    """
    gainX = miriad_io.floatArray(len(wt1))
    wt1X = floatListToArray(wt1)
    npointX = miriad_io.copy_intp(len(wt1))
    try :
        XX = mx.safecall(miriad_io.mcgn_,(gainX,wt1X,npointX))
        del XX
    except :
        pass
    gainR = floatArrayToList(gainX,len(wt1))
    del gainX
    del wt1X
    return gainR

def mcsigma2(npoint,noinvert) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            npoint -
            noinvert -
        returns :   (as a tuple)
            sigma2 -
    """
    sigma2X = floatArray(npoint)
    npointX = miriad_io.copy_intp(npoint)
    noinvertX = miriad_io.copy_intp(uncastLogical(noinvert))
    try :
        XX = mx.safecall(miriad_io.mcsigma2_,(sigma2X,npointX,noinvertX))
        del XX
    except :
        pass
    sigma2R = floatArrayToList(sigma2X,npoint)
    del sigma2X
    return sigma2R

def mcsig(wt1,wt2,npoint,noinvert) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            wt1 -
            wt2 -
            npoint -
            noinvert -
        returns :   (as a tuple)
            sigma2 -
    """
    sigma2X = floatArray(npoint)
    wt1X = miriad_io.copy_floatp(wt1)
    wt2X = miriad_io.copy_floatp(wt2)
    npointX = miriad_io.copy_intp(npoint)
    noinvertX = miriad_io.copy_intp(uncastLogical(noinvert))
    try :
        XX = mx.safecall(miriad_io.mcsig_,(sigma2X,wt1X,wt2X,npointX,noinvertX))
        del XX
    except :
        pass
    sigma2R = floatArrayToList(sigma2X,npoint)
    del sigma2X
    return sigma2R

def mccnvlr(inp,runs,nruns) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            inp -
            runs -
            nruns -
        returns :   (as a tuple)
            out -
    """
    inX = floatListToArray(inp)
    l = len(inp)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    outX = floatArray(l)
    try :
        XX = mx.safecall(miriad_io.mccnvlr_,(inX,runsX,nrunsX,outX))
        del XX
    except :
        pass
    del inX
    del runsX
    outR = floatArrayToList(outX,l)
    del outX
    return outR

def mccnvl2(k,cnvl,pbobj,inp,wt1,wt3,xlo,ylo,xhi,yhi,xmin,ymin,xmax,ymax,n,out,runs,nruns,pb,resid,nscr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            k -
            cnvl -
            pbobj -
            inp -
            wt1 -
            wt3 -
            xlo -
            ylo -
            xhi -
            yhi -
            xmin -
            ymin -
            xmax -
            ymax -
            n -
            out -
            runs -
            nruns -
            pb -
            resid -
            nscr -
        returns :   (as a tuple)
    """
    kX = miriad_io.copy_intp(k)
    cnvlX = miriad_io.copy_intp(cnvl)
    pbobjX = miriad_io.copy_intp(pbobj)
    inX = floatListToArray(inp)
    l = len(inp)
    wt1X = floatListToArray(wt1)
    wt3X = miriad_io.copy_floatp(wt3)
    xloX = miriad_io.copy_intp(xlo)
    yloX = miriad_io.copy_intp(ylo)
    xhiX = miriad_io.copy_intp(xhi)
    yhiX = miriad_io.copy_intp(yhi)
    xminX = miriad_io.copy_intp(xmin)
    yminX = miriad_io.copy_intp(ymin)
    xmaxX = miriad_io.copy_intp(xmax)
    ymaxX = miriad_io.copy_intp(ymax)
    nX = miriad_io.copy_intp(n)
    outX = floatListToArray(out)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    pbX = floatListToArray(pb)
    residX = floatListToArray(resid)
    nscrX = miriad_io.copy_intp(nscr)
    try :
        XX = mx.safecall(miriad_io.mccnvl2_,(kX,cnvlX,pbobjX,inX,wt1X,wt3X,xloX,yloX,xhiX,yhiX,xminX,yminX,xmaxX,ymaxX,nX,outX,runsX,nrunsX,pbX,residX,nscrX))
        del XX
    except :
        pass
    del inX
    del wt1X
    outR = floatArrayToList(outX,l)
    del outX
    del runsX
    del pbX
    del residX
    return outR

def mcwt(wts) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            wts -
        returns :   (as a tuple)
            out -
    """
    n = len(wts)
    outX = floatArray(n)
    wtsX = floatListToArray(wts)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.mcwt_,(outX,wtsX,nX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,n)
    del outX
    del wtsX
    return outR

def mcextent(k,pbobj,n1,n2,n1d,n2d) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            k -
            pbobj -
            n1 -
            n2 -
            n1d -
            n2d -
        returns :   (as a tuple)
            xlo -
            ylo -
            xhi -
            yhi -
            xmin -
            ymin -
            xmax -
            ymax -
    """
    kX = miriad_io.copy_intp(k)
    pbobjX = miriad_io.copy_intp(pbobj)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    n1dX = miriad_io.copy_intp(n1d)
    n2dX = miriad_io.copy_intp(n2d)
    xloX = miriad_io.new_intp()
    yloX = miriad_io.new_intp()
    xhiX = miriad_io.new_intp()
    yhiX = miriad_io.new_intp()
    xminX = miriad_io.new_intp()
    yminX = miriad_io.new_intp()
    xmaxX = miriad_io.new_intp()
    ymaxX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mcextent_,(kX,pbobjX,n1X,n2X,n1dX,n2dX,xloX,yloX,xhiX,yhiX,xminX,yminX,xmaxX,ymaxX))
        del XX
    except :
        pass
    xloR = miriad_io.intp_value(xloX)
    yloR = miriad_io.intp_value(yloX)
    xhiR = miriad_io.intp_value(xhiX)
    yhiR = miriad_io.intp_value(yhiX)
    xminR = miriad_io.intp_value(xminX)
    yminR = miriad_io.intp_value(yminX)
    xmaxR = miriad_io.intp_value(xmaxX)
    ymaxR = miriad_io.intp_value(ymaxX)
    return xloR,yloR,xhiR,yhiR,xminR,yminR,xmaxR,ymaxR

def mcinitc(k,cnvl1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            k -
            cnvl1 -
        returns :   (as a tuple)
    """
    kX = miriad_io.copy_intp(k)
    cnvl1X = miriad_io.copy_intp(cnvl1)
    try :
        XX = mx.safecall(miriad_io.mcinitc_,(kX,cnvl1X))
        del XX
    except :
        pass

def mcgaus(tno,n1,n2,ic,jc,bmaj,bmin,bpa) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            n1 -
            n2 -
            ic -
            jc -
            bmaj -
            bmin -
            bpa -
        returns :   (as a tuple)
            beam -
    """
    tnoX = miriad_io.copy_intp(tno)
    beamX = floatArray(n1,n2)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    bmajX = miriad_io.copy_floatp(bmaj)
    bminX = miriad_io.copy_floatp(bmin)
    bpaX = miriad_io.copy_floatp(bpa)
    try :
        XX = mx.safecall(miriad_io.mcgaus_,(tnoX,beamX,n1X,n2X,icX,jcX,bmajX,bminX,bpaX))
        del XX
    except :
        pass
    beamR = floatArrayToList(beamX,n1,n2)
    del beamX
    return beamR

def mcfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mcfin_)
    except :
        pass
    return XX

def medfit(x,y,n,dooff) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
            dooff -
        returns :   (as a tuple)
            a -
            b -
    """
    n = len(x)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    dooffX = miriad_io.copy_intp(uncastLogical(dooff))
    try :
        XX = mx.safecall(miriad_io.medfit_,(xX,yX,nX,aX,bX,dooffX))
        del XX
    except :
        pass
    del xX
    del yX
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    return aR,bR

def median(x) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
        returns :   (as a tuple)
            xmed -
    """
    n = len(x)
    xX = floatListToArray(x)
    nX = miriad_io.copy_intp(n)
    xmedX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.median_,(xX,nX,xmedX))
        del XX
    except :
        pass
    del xX
    xmedR = miriad_io.floatp_value(xmedX)
    return xmedR

def memini():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.memini_)
    except :
        pass
    return XX

def modelini(tmod,tvis,sels,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tmod -
            tvis -
            sels -
            flags -
        returns :   (as a tuple)
    """
    tmodX = miriad_io.copy_intp(tmod)
    tvisX = miriad_io.copy_intp(tvis)
    selsX = floatListToArray(sels)
    try :
        XX = mx.safecall(miriad_io.modelini_,(tmodX,tvisX,selsX,flags,len(flags)))
        del XX
    except :
        pass
    del selsX

def modpolm(tmod) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tmod -
        returns :   (as a tuple)
            polm -
    """
    tmodX = miriad_io.copy_intp(tmod)
    polmX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.modpolm_,(tmodX,polmX))
        del XX
    except :
        pass
    polmR = miriad_io.intp_value(polmX)
    return polmR

def modpolv(tvis) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
        returns :   (as a tuple)
            polv -
    """
    tvisX = miriad_io.copy_intp(tvis)
    polvX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.modpolv_,(tvisX,polvX))
        del XX
    except :
        pass
    polvR = miriad_io.intp_value(polvX)
    return polvR

def modfreqm(tmod) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tmod -
        returns :   (as a tuple)
            freq0 -
    """
    tmodX = miriad_io.copy_intp(tmod)
    freq0X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.modfreqm_,(tmodX,freq0X))
        del XX
    except :
        pass
    freq0R = miriad_io.doublep_value(freq0X)
    return freq0R

def modfft(tvis,tmod,nx,ny,nchan,nxd,nyd,level,polm,doclip,imhead,nv,nu,mfs) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            tmod -
            nx -
            ny -
            nchan -
            nxd -
            nyd -
            level -
            polm -
            doclip -
            imhead -
            nv -
            nu -
            mfs -
        returns :   (as a tuple)
            bufferX -
            xref1 -
            yref1 -
            xref2 -
            yref2 -
    """
    tvisX = miriad_io.copy_intp(tvis)
    tmodX = miriad_io.copy_intp(tmod)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    nchanX = miriad_io.copy_intp(nchan)
    nxdX = miriad_io.copy_intp(nxd)
    nydX = miriad_io.copy_intp(nyd)
    levelX = miriad_io.copy_floatp(level)
    polmX = miriad_io.copy_intp(polm)
    doclipX = miriad_io.copy_intp(uncastLogical(doclip))
    imheadX = miriad_io.copy_intp(uncastLogical(imhead))
    bufferX = FcomplexArray(nv,nu,nchan)
    nvX = miriad_io.copy_intp(nv)
    nuX = miriad_io.copy_intp(nu)
    mfsX = miriad_io.copy_intp(uncastLogical(mfs))
    xref1X = miriad_io.new_doublep()
    yref1X = miriad_io.new_doublep()
    xref2X = miriad_io.new_doublep()
    yref2X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.modfft_,(tvisX,tmodX,nxX,nyX,nchanX,nxdX,nydX,levelX,polmX,doclipX,imheadX,bufferX,nvX,nuX,mfsX,xref1X,yref1X,xref2X,yref2X))
        del XX
    except :
        pass
    bufferR = FcomplexArrayToList(bufferX,nv*2,nu*2,nchan*2)
    xref1R = miriad_io.doublep_value(xref1X)
    yref1R = miriad_io.doublep_value(yref1X)
    xref2R = miriad_io.doublep_value(xref2X)
    yref2R = miriad_io.doublep_value(yref2X)
    return bufferR,xref1R,yref1R,xref2R,yref2R

def modgrid(uu,vv,grd,nu,nv,nchan,u0,v0,gcf,ngcf) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            uu -
            vv -
            grd -
            nu -
            nv -
            nchan -
            u0 -
            v0 -
            gcf -
            ngcf -
        returns :   (as a tuple)
            intp -
    """
    uuX = miriad_io.copy_floatp(uu)
    vvX = miriad_io.copy_floatp(vv)
    grdX = miriad_io.copy_Fcomplexp(convertComplex(grd))
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    nchanX = miriad_io.copy_intp(nchan)
    u0X = miriad_io.copy_intp(u0)
    v0X = miriad_io.copy_intp(v0)
    gcfX = floatListToArray(gcf)
    ngcfX = miriad_io.copy_intp(ngcf)
    intpX = FcomplexArray(nchan)
    try :
        XX = mx.safecall(miriad_io.modgrid_,(uuX,vvX,grdX,nuX,nvX,nchanX,u0X,v0X,gcfX,ngcfX,intpX))
        del XX
    except :
        pass
    del gcfX
    intpR = FcomplexArrayToList(intpX,nchan*2)
    return intpR

def modshift(uu,vv,xref1,yref1,xref2,yref2,freq,intp,nchan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            uu -
            vv -
            xref1 -
            yref1 -
            xref2 -
            yref2 -
            freq -
            intp -
            nchan -
        returns :   (as a tuple)
            intp -
    """
    uuX = miriad_io.copy_doublep(uu)
    vvX = miriad_io.copy_doublep(vv)
    xref1X = miriad_io.copy_doublep(xref1)
    yref1X = miriad_io.copy_doublep(yref1)
    xref2X = miriad_io.copy_doublep(xref2)
    yref2X = miriad_io.copy_doublep(yref2)
    freqX = doubleListToArray(freq)
    intpX = FcomplexListToArray(intp)
    nchanX = miriad_io.copy_intp(nchan)
    try :
        XX = mx.safecall(miriad_io.modshift_,(uuX,vvX,xref1X,yref1X,xref2X,yref2X,freqX,intpX,nchanX))
        del XX
    except :
        pass
    del freqX
    intpR = FcomplexArrayToList(intpX,nchan*2)
    return intpR

def modcorr(nxd,nyd) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nxd -
            nyd -
        returns :   (as a tuple)
            xcorr -
            ycorr -
    """
    xcorrX = floatArray(nxd)
    ycorrX = floatArray(nyd)
    nxdX = miriad_io.copy_intp(nxd)
    nydX = miriad_io.copy_intp(nyd)
    try :
        XX = mx.safecall(miriad_io.modcorr_,(xcorrX,ycorrX,nxdX,nydX))
        del XX
    except :
        pass
    xcorrR = floatArrayToList(xcorrX,nxd)
    del xcorrX
    ycorrR = floatArrayToList(ycorrX,nyd)
    del ycorrX
    return xcorrR,ycorrR

def modplane(tmod,nx,ny,nxd,nyd,xcorr,ycorr,level,nclip,iref,jref,nu,nv) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tmod -
            nx -
            ny -
            nxd -
            nyd -
            xcorr -
            ycorr -
            level -
            nclip -
            iref -
            jref -
            nu -
            nv -
        returns :   (as a tuple)
            buffer -
    """
    tmodX = miriad_io.copy_intp(tmod)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    nxdX = miriad_io.copy_intp(nxd)
    nydX = miriad_io.copy_intp(nyd)
    xcorrX = floatListToArray(xcorr)
    ycorrX = floatListToArray(ycorr)
    levelX = miriad_io.copy_floatp(level)
    nclipX = miriad_io.copy_intp(nclip)
    irefX = miriad_io.copy_intp(iref)
    jrefX = miriad_io.copy_intp(jref)
    bufferX = FcomplexArray(nv,nu)
    nuX = miriad_io.copy_intp(nu)
    nvX = miriad_io.copy_intp(nv)
    try :
        XX = mx.safecall(miriad_io.modplane_,(tmodX,nxX,nyX,nxdX,nydX,xcorrX,ycorrX,levelX,nclipX,irefX,jrefX,bufferX,nuX,nvX))
        del XX
    except :
        pass
    del xcorrX
    del ycorrX
    bufferR = FcomplexArrayToList(bufferX,nv*2,nu*2)
    return bufferR

def modstat(calscale,tvis,out,nchan,calget,level,vispow,modpow) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            calscale -
            tvis -
            out -
            nchan -
            calget -
            level -
        returns :   (as a tuple)
            vispow -
            modpow -

    """
    calscaleX = miriad_io.copy_intp(uncastLogical(calscale))
    tvisX = miriad_io.copy_intp(tvis)
    outX = floatListToArray(out)
    nchanX = miriad_io.copy_intp(nchan)
    calgetX = miriad_io.copy_intp(calget)
    levelX = miriad_io.copy_floatp(level)
    vispowX = miriad_io.copy_floatp(vispow)
    modpowX = miriad_io.copy_floatp(modpow)
    try :
        XX = mx.safecall(miriad_io.modstat_,(calscaleX,tvisX,outX,nchanX,calgetX,levelX,vispowX,modpowX))
        del XX
    except :
        pass
    del outX
    vispowR = miriad_io.floatp_value(vispowX)
    modpowR = miriad_io.floatp_value(modpowX)
    return vispowR,modpowR

def modget(calget,tvis,nchan,a,level) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            calget -
            tvis -
            nchan -
            level -
        returns :   (as a tuple)
            a -
    """
    calgetX = miriad_io.copy_intp(calget)
    tvisX = miriad_io.copy_intp(tvis)
    nchanX = miriad_io.copy_intp(nchan)
    aX = miriad_io.copy_floatp(a)
    levelX = miriad_io.copy_floatp(level)
    try :
        XX = mx.safecall(miriad_io.modget_,(calgetX,tvisX,nchanX,aX,levelX))
        del XX
    except :
        pass
    aR = miriad_io.floatp_value(aX)
    return aR

def modinit():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.modinit_)
    except :
        pass
    return XX

def modprd(tvis,line,k1,k2,lmn) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            line -
            k1 -
            k2 -
            lmn -
        returns :   (as a tuple)
    """
    tvisX = miriad_io.copy_intp(tvis)
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    lmnX = doubleListToArray(lmn)
    try :
        XX = mx.safecall(miriad_io.modprd_,(tvisX,line,k1X,k2X,lmnX,len(line)))
        del XX
    except :
        pass
    del lmnX

def moscini():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.moscini_)
    except :
        pass
    return XX

def moscdone(lin) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
        returns :   (as a tuple)
    """
    linX = miriad_io.copy_intp(lin)
    try :
        XX = mx.safecall(miriad_io.moscdone_,(linX,))
        del XX
    except :
        pass

def moschk(lin) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
        returns :   (as a tuple)
            i -
    """
    linX = miriad_io.copy_intp(lin)
    iX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.moschk_,(linX,iX))
        del XX
    except :
        pass
    iR = miriad_io.intp_value(iX)
    return iR

def moschar() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            ra1 -
            dec1 -
            npnt1 -
            proj -
    """
    proj = "                      "
    ra1X = miriad_io.new_doublep()
    dec1X = miriad_io.new_doublep()
    npnt1X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.moschar_,(ra1X,dec1X,npnt1X,proj,20))
        del XX
    except :
        pass
    ra1R = miriad_io.doublep_value(ra1X)
    dec1R = miriad_io.doublep_value(dec1X)
    npnt1R = miriad_io.intp_value(npnt1X)
    proj = proj.strip()
    return ra1R,dec1R,npnt1R,proj

def mosginit(coobj,nx,ny,nchan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            nx -
            ny -
            nchan -
        returns :   (as a tuple)
            mnx -
            mny -
    """
    coobjX = miriad_io.copy_intp(coobj)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    nchanX = miriad_io.copy_intp(nchan)
    mnxX = miriad_io.new_intp()
    mnyX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mosginit_,(coobjX,nxX,nyX,nchanX,mnxX,mnyX))
        del XX
    except :
        pass
    mnxR = miriad_io.intp_value(mnxX)
    mnyR = miriad_io.intp_value(mnyX)
    return mnxR,mnyR

def mosshift(coobj,npnt1,nchan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            npnt1 -
            nchan -
        returns :   (as a tuple)
            x -
            y -
    """
    coobjX = miriad_io.copy_intp(coobj)
    npnt1X = miriad_io.copy_intp(npnt1)
    nchanX = miriad_io.copy_intp(nchan)
    xX = floatArray(nchan,npnt1)
    yX = floatArray(nchan,npnt1)
    try :
        XX = mx.safecall(miriad_io.mosshift_,(coobjX,npnt1X,nchanX,xX,yX))
        del XX
    except :
        pass
    xR = floatArrayToList(xX,nchan,npnt1)
    del xX
    yR = floatArrayToList(yX,nchan,npnt1)
    del yX
    return xR,yR

def mossizer(nx2,ny2,x,y,npnt,nchan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nx2 -
            ny2 -
            x -
            y -
            npnt -
            nchan -
        returns :   (as a tuple)
            x -
            y -
            mnx -
            mny -
            crpix1 -
            crpix2 -
    """
    nx2X = miriad_io.copy_intp(nx2)
    ny2X = miriad_io.copy_intp(ny2)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    npntX = miriad_io.copy_intp(npnt)
    nchanX = miriad_io.copy_intp(nchan)
    mnxX = miriad_io.new_intp()
    mnyX = miriad_io.new_intp()
    crpix1X = miriad_io.new_doublep()
    crpix2X = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.mossizer_,(nx2X,ny2X,xX,yX,npntX,nchanX,mnxX,mnyX,crpix1X,crpix2X))
        del XX
    except :
        pass
    xR = floatArrayToList(xX,nchan,npnt)
    del xX
    yR = floatArrayToList(yX,nchan,npnt)
    del yX
    mnxR = miriad_io.intp_value(mnxX)
    mnyR = miriad_io.intp_value(mnyX)
    crpix1R = miriad_io.doublep_value(crpix1X)
    crpix2R = miriad_io.doublep_value(crpix2X)
    return xR,yR,mnxR,mnyR,crpix1R,crpix2R

def mosgeom(size,n,nchan,npol,vis,wts) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            size -
            n -
            nchan -
            npol -
            vis -
            wts -
        returns :   (as a tuple)
            vis -
    """
    sizeX = miriad_io.copy_intp(size)
    nX = miriad_io.copy_intp(n)
    nchanX = miriad_io.copy_intp(nchan)
    npolX = miriad_io.copy_intp(npol)
    visX = FcomplexArray(vis)
    wtsX = floatListToArray(wts)
    try :
        XX = mx.safecall(miriad_io.mosgeom_,(sizeX,nX,nchanX,npolX,visX,wtsX))
        del XX
    except :
        pass
    visR = FcomplexArrayToList(visX,size*2,n*2)
    del wtsX
    return visR

def mosload(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
            npnt1 -
    """
    tnoX = miriad_io.copy_intp(tno)
    npnt1X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mosload_,(tnoX,npnt1X))
        del XX
    except :
        pass
    npnt1R = miriad_io.intp_value(npnt1X)
    return npnt1R

def mosprint():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mosprint_)
    except :
        pass
    return XX

def mosinit(nx,ny) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nx -
            ny -
        returns :   (as a tuple)
    """
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    try :
        XX = mx.safecall(miriad_io.mosinit_,(nxX,nyX))
        del XX
    except :
        pass

def mosget(i) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i -
        returns :   (as a tuple)
            ra1 -
            dec1 -
            rms1 -
            pbtype1 -
    """
    pbtype1 = "                                 "
    iX = miriad_io.copy_intp(i)
    ra1X = miriad_io.new_doublep()
    dec1X = miriad_io.new_doublep()
    rms1X = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.mosget_,(iX,ra1X,dec1X,rms1X,pbtype1,30))
        del XX
    except :
        pass
    ra1R = miriad_io.doublep_value(ra1X)
    dec1R = miriad_io.doublep_value(dec1X)
    rms1R = miriad_io.floatp_value(rms1X)
    pbtype1 = pbtype1.strip()
    return ra1R,dec1R,rms1R,pbtype1

def mosset(i,ra1,dec1,rms1,pbtype1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            i -
            ra1 -
            dec1 -
            rms1 -
            pbtype1 -
        returns :   (as a tuple)
    """
    i__X = miriad_io.copy_intp(i)
    ra1X = miriad_io.copy_doublep(ra1)
    dec1X = miriad_io.copy_doublep(dec1)
    rms1X = miriad_io.copy_floatp(rms1)
    try :
        XX = mx.safecall(miriad_io.mosset_,(i__X,ra1X,dec1X,rms1X,pbtype1,len(pbtype1)))
        del XX
    except :
        pass

def mosgetn() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            nx2d -
            ny2d -
            npnt1 -
    """
    nx2dX = miriad_io.new_intp()
    ny2dX = miriad_io.new_intp()
    npnt1X = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.mosgetn_,(nx2dX,ny2dX,npnt1X))
        del XX
    except :
        pass
    nx2dR = miriad_io.intp_value(nx2dX)
    ny2dR = miriad_io.intp_value(ny2dX)
    npnt1R = miriad_io.intp_value(npnt1X)
    return nx2dR,ny2dR,npnt1R

def mossetn(nx2d,ny2d) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nx2d -
            ny2d -
        returns :   (as a tuple)
    """
    nx2dX = miriad_io.copy_intp(nx2d)
    ny2dX = miriad_io.copy_intp(ny2d)
    try :
        XX = mx.safecall(miriad_io.mossetn_,(nx2dX,ny2dX))
        del XX
    except :
        pass

def mossave(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.mossave_,(tnoX,))
        del XX
    except :
        pass

def mosgfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mosgfin_)
    except :
        pass
    return XX

def mosmini(coobj,chan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            chan -
        returns :   (as a tuple)
    """
    coobjX = miriad_io.copy_intp(coobj)
    chanX = miriad_io.copy_floatp(chan)
    try :
        XX = mx.safecall(miriad_io.mosmini_,(coobjX,chanX))
        del XX
    except :
        pass

def mosaicer(inp,nx,ny,npnt1,mnx,mny,runs,maxruns,nruns) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            inp -
            nx -
            ny -
            npnt1 -
            mnx -
            mny -
            runs -
            maxruns -
            nruns -
        returns :   (as a tuple)
            out -
    """
    inX = miriad_io.copy_floatp(inp)
    outX = floatArray(mnx,mny)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    npnt1X = miriad_io.copy_intp(npnt1)
    mnxX = miriad_io.copy_intp(mnx)
    mnyX = miriad_io.copy_intp(mny)
    runsX = miriad_io.copy_intp(runs)
    maxrunsX = miriad_io.copy_intp(maxruns)
    nrunsX = miriad_io.copy_intp(nruns)
    try :
        XX = mx.safecall(miriad_io.mosaicer_,(inX,outX,nxX,nyX,npnt1X,mnxX,mnyX,runsX,maxrunsX,nrunsX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,mnx,mny)
    return outR

def mosaic1(inp,nx,ny,mnx,mny,runs,maxruns,nruns) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            in -
            nx -
            ny -
            mnx -
            mny -
            runs -
            maxruns -
            nruns -
        returns :   (as a tuple)
            out -
    """
    inX = miriad_io.copy_floatp(inp)
    outX = floatArray(mnx,mny)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    mnxX = miriad_io.copy_intp(mnx)
    mnyX = miriad_io.copy_intp(mny)
    runsX = miriad_io.copy_intp(runs)
    maxrunsX = miriad_io.copy_intp(maxruns)
    nrunsX = miriad_io.copy_intp(nruns)
    try :
        XX = mx.safecall(miriad_io.mosaic1_,(inX,outX,nxX,nyX,mnxX,mnyX,runsX,maxrunsX,nrunsX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,mnx,mny)
    return outR

def mosaic2(inp,wts,nx,ny,npnt,mnx,mny,rms2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            inp -
            wts -
            nx -
            ny -
            npnt -
            mnx -
            mny -
            rms2 -
        returns :   (as a tuple)
            out -
    """
    inX = floatListToArray(inp)
    outX = floatArray(mnx,mny)
    wtsX = floatListToArray(wts)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    npntX = miriad_io.copy_intp(npnt)
    mnxX = miriad_io.copy_intp(mnx)
    mnyX = miriad_io.copy_intp(mny)
    rms2X = floatListToArray(rms2)
    try :
        XX = mx.safecall(miriad_io.mosaic2_,(inX,outX,wtsX,nxX,nyX,npntX,mnxX,mnyX,rms2X))
        del XX
    except :
        pass
    del inX
    outR = floatArrayToList(outX,mnx,mny)
    del outX
    del wtsX
    del rms2X
    return outR

def moswt(rms2,npnt,wts,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            rms2 -
            npnt -
            wts -
            n -
        returns :   (as a tuple)
            out -
    """
    rms2X = floatListToArray(rms2)
    npntX = miriad_io.copy_intp(npnt)
    outX = floatArray(n)
    wtsX = floatListToArray(wts)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.moswt_,(rms2X,npntX,outX,wtsX,nX))
        del XX
    except :
        pass
    del rms2X
    outR = floatArrayToList(outX,n)
    del outX
    del wtsX
    return outR

def mosmfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.mosmfin_)
    except :
        pass
    return XX

def mosval(coobj,inp,x) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            inp -
            x -
        returns :   (as a tuple)
            gain -
            rms -
    """
    coobjX = miriad_io.copy_intp(coobj)
    xX = miriad_io.copy_doublep(x)
    gainX = miriad_io.new_floatp()
    rmsX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.mosval_,(coobjX,inp,xX,gainX,rmsX,len(inp)))
        del XX
    except :
        pass
    gainR = miriad_io.floatp_value(gainX)
    rmsR = miriad_io.floatp_value(rmsX)
    return gainR,rmsR

def mospnt(coobj,inp,x,beams,nx,ny,npnt1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj -
            inp -
            x -
            beams -
            nx -
            ny -
            npnt1 -
        returns :   (as a tuple)
            psf -
    """
    coobjX = miriad_io.copy_intp(coobj)
    xX = miriad_io.copy_doublep(x)
    beamsX = miriad_io.copy_floatp(beams)
    psfX = miriad_io.new_floatp()
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    npnt1X = miriad_io.copy_intp(npnt1)
    try :
        XX = mx.safecall(miriad_io.mospnt_,(coobjX,inp,xX,beamsX,psfX,nxX,nyX,npnt1X,len(inp)))
        del XX
    except :
        pass
    psfR = miriad_io.floatp_value(psfX)
    return psfR

def mospnt1(beams,wts,nx,ny,npnt1,xr,yr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            beams -
            wts -
            nx -
            ny -
            npnt1 -
            xr -
            yr -
        returns :   (as a tuple)
            psf -
    """
    beamsX = floatListToArray(beams)
    psfX = floatArray(nx,ny)
    wtsX = floatListToArray(wts)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    npnt1X = miriad_io.copy_intp(npnt1)
    xrX = miriad_io.copy_intp(xr)
    yrX = miriad_io.copy_intp(yr)
    try :
        XX = mx.safecall(miriad_io.mospnt1_,(beamsX,psfX,wtsX,nxX,nyX,npnt1X,xrX,yrX))
        del XX
    except :
        pass
    del beamsX
    psfR = floatArrayToList(psfX,nx,ny)
    del psfX
    del wtsX
    return psfR

def moswts(nx,ny,xoff,yoff) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nx -
            ny -
            xoff -
            yoff -
        returns :   (as a tuple)
            wt1 -
            wt2 -
    """
    wt1X = floatArray(nx,ny)
    wt2X = floatArray(nx,ny)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    xoffX = miriad_io.copy_intp(xoff)
    yoffX = miriad_io.copy_intp(yoff)
    try :
        XX = mx.safecall(miriad_io.moswts_,(wt1X,wt2X,nxX,nyX,xoffX,yoffX))
        del XX
    except :
        pass
    wt1R = floatArrayToList(wt1X,nx,ny)
    del wt1X
    wt2R = floatArrayToList(wt2X,nx,ny)
    del wt2X
    return wt1R,wt2R

def moswtsr(runs,nruns,npix) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            runs -
            nruns -
            npix -
        returns :   (as a tuple)
            wt1 -
            wt2 -
    """
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    wt1X = floatArray(npix)
    wt2X = floatArray(npix)
    npixX = miriad_io.copy_intp(npix)
    try :
        XX = mx.safecall(miriad_io.moswtsr_,(runsX,nrunsX,wt1X,wt2X,npixX))
        del XX
    except :
        pass
    del runsX
    wt1R = floatArrayToList(wt1X,npix)
    del wt1X
    wt2R = floatArrayToList(wt2X,npix)
    del wt2X
    return wt1R,wt2R

def mosradec(k) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            k -
        returns :   (as a tuple)
            ra -
            dec -
    """
    kX = miriad_io.copy_intp(k)
    raX = miriad_io.new_doublep()
    decX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.mosradec_,(kX,raX,decX))
        del XX
    except :
        pass
    raR = miriad_io.doublep_value(raX)
    decR = miriad_io.doublep_value(decX)
    return raR,decR

def nearest(x,y) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
        returns :   (as a tuple)
            indx -
            ip -
            mnmax -
    """
    n = len(x)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    indxX = intArray(n)
    nX = miriad_io.copy_intp(n)
    ipX = intArray(n,5)
    mnmaxX = floatArray(n,5)
    try :
        XX = mx.safecall(miriad_io.nearest_,(xX,yX,indxX,nX,ipX,mnmaxX))
        del XX
    except :
        pass
    del xX
    del yX
    indxR = intArrayToList(indxX,n)
    del indxX
    del ipX
    del mnmaxX
    return indxR

def randset(seed) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            seed -
        returns :   (as a tuple)
    """
    seedX = miriad_io.copy_intp(seed)
    try :
        XX = mx.safecall(miriad_io.randset_,(seedX,))
        del XX
    except :
        pass

def uniform(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            data -
    """
    dataX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.uniform_,(dataX,nX))
        del XX
    except :
        pass
    dataR = floatArrayToList(dataX,n)
    del dataX
    return dataR

def setseed(seed) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            seed -
        returns :   (as a tuple)
    """
    seedX = miriad_io.copy_intp(seed)
    try :
        XX = mx.safecall(miriad_io.setseed_,(seedX,))
        del XX
    except :
        pass

def gaus(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            data -
    """
    dataX = floatArray(n)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.gaus_,(dataX,nX))
        del XX
    except :
        pass
    dataR = floatArrayToList(dataX,n)
    return dataR

def besj(x,alpha,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            alpha -
            n -
        returns :   (as a tuple)
            y -
            nz -
    """
    xX = miriad_io.copy_floatp(x)
    alphaX = miriad_io.copy_floatp(alpha)
    nX = miriad_io.copy_intp(n)
    yX = floatArray(n)
    nzX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.besj_,(xX,alphaX,nX,yX,nzX))
        del XX
    except :
        pass
    yR = floatArrayToList(yX,n)
    nzR = miriad_io.intp_value(nzX)
    return yR,nzR

def jairy(x,rx,c) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            rx -
            c -
        returns :   (as a tuple)
            ai -
            dai -
    """
    xX = miriad_io.copy_floatp(x)
    rxX = miriad_io.copy_floatp(rx)
    cX = miriad_io.copy_floatp(c)
    aiX = miriad_io.new_floatp()
    daiX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.jairy_,(xX,rxX,cX,aiX,daiX))
        del XX
    except :
        pass
    aiR = miriad_io.floatp_value(aiX)
    daiR = miriad_io.floatp_value(daiX)
    return aiR,daiR

def numbpg(mm,pp,form) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mm -
            pp -
            form -
        returns :   (as a tuple)
            string -
            nc -
    """
    string = "                          "
    mmX = miriad_io.copy_intp(mm)
    ppX = miriad_io.copy_intp(pp)
    formX = miriad_io.copy_intp(form)
    ncX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.numbpg_,(mmX,ppX,formX,string,ncX,20))
        del XX
    except :
        pass
    ncR = miriad_io.intp_value(ncX)
    string = string[:ncR]
    return string

def obsprint():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.obsprint_)
    except :
        pass
    return XX

def obspar(observ,objt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            observ -
            objt -
        returns :   (as a tuple)
            value -
            ok -
    """
    valueX = miriad_io.new_doublep()
    okX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.obspar_,(observ,objt,valueX,okX,len(observ),len(objt)))
        del XX
    except :
        pass
    valueR = miriad_io.doublep_value(valueX)
    okR = castLogical(miriad_io.intp_value(okX))
    return valueR,okR

def obsinit():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.obsinit_)
    except :
        pass
    return XX

def obsad(name,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            value -
        returns :   (as a tuple)
    """
    valueX = miriad_io.copy_doublep(value)
    try :
        XX = mx.safecall(miriad_io.obsad_,(name,valueX,len(name)))
        del XX
    except :
        pass

def ofmapp():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmapp_)
    except :
        pass
    return XX

def ofmcol(jofm,imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jofm -
            imin -
            imax -
        returns :   (as a tuple)
    """
    jofmX = miriad_io.copy_intp(jofm)
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmcol_,(jofmX,iminX,imaxX))
        del XX
    except :
        pass

def ofmcmp():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmcmp_)
    except :
        pass
    return XX

def ofmevl():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmevl_)
    except :
        pass
    return XX

def ofmfit():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmfit_)
    except :
        pass
    return XX

def ofmheq(npix,image,mask,imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            npix -
            image -
            mask -
            imin -
            imax -
        returns :   (as a tuple)
    """
    npixX = miriad_io.copy_intp(npix)
    imageX = floatListToArray(image)
    maskX = intListToArray(mask)
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmheq_,(npixX,imageX,maskX,iminX,imaxX))
        del XX
    except :
        pass
    del imageX
    del maskX

def ofmini():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmini_)
    except :
        pass
    return XX

def ofml1m():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofml1m_)
    except :
        pass
    return XX

def ofmlin(x,y,domsg) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
            domsg -
        returns :   (as a tuple)
    """
    xX = miriad_io.copy_floatp(x)
    yX = miriad_io.copy_floatp(y)
    domsgX = miriad_io.copy_intp(uncastLogical(domsg))
    try :
        XX = mx.safecall(miriad_io.ofmlin_,(xX,yX,domsgX))
        del XX
    except :
        pass

def ofmlnf():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmlnf_)
    except :
        pass
    return XX

def ofmlog(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmlog_,(iminX,imaxX))
        del XX
    except :
        pass

def ofmmod(tfvpu,nu,image,mask,imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tfvpu -
            nu -
            image -
            mask -
            imin -
            imax -
        returns :   (as a tuple)
    """
    tfvpuX = floatListToArray(tfvpu)
    nuX = miriad_io.copy_intp(nu)
    imageX = floatListToArray(image)
    maskX = intListToArray(mask)
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmmod_,(tfvpuX,nuX,imageX,maskX,iminX,imaxX))
        del XX
    except :
        pass
    del tfvpuX
    del imageX
    del maskX

def ofmrep():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmrep_)
    except :
        pass
    return XX

def ofmrev():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmrev_)
    except :
        pass
    return XX

def ofmrsf():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmrsf_)
    except :
        pass
    return XX

def ofmsel(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmsel_,(iminX,imaxX))
        del XX
    except :
        pass

def ofmsqr(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmsqr_,(iminX,imaxX))
        del XX
    except :
        pass

def ofmtabw(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmtabw_,(iminX,imaxX))
        del XX
    except :
        pass

def ofmtba(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
            dofcc -
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    dofccX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ofmtba_,(iminX,imaxX,dofccX))
        del XX
    except :
        pass
    dofccR = castLogical(miriad_io.intp_value(dofccX))
    return dofccR

def ofmtbb():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmtbb_)
    except :
        pass
    return XX

def ofmtbw():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmtbw_)
    except :
        pass
    return XX

def ofmtcc(imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            imin -
            imax -
        returns :   (as a tuple)
            dofcc -
    """
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    dofccX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.ofmtcc_,(iminX,imaxX,dofccX))
        del XX
    except :
        pass
    dofccR = castLogical(miriad_io.intp_value(dofccX))
    return dofccR

def ofmtfe():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmtfe_)
    except :
        pass
    return XX

def ofmtff(npix,image,mask,imin,imax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            npix -
            image -
            mask -
            imin -
            imax -
        returns :   (as a tuple)
    """
    npixX = miriad_io.copy_intp(npix)
    imageX = floatListToArray(image)
    maskX = intListToArray(mask)
    iminX = miriad_io.copy_floatp(imin)
    imaxX = miriad_io.copy_floatp(imax)
    try :
        XX = mx.safecall(miriad_io.ofmtff_,(npixX,imageX,maskX,iminX,imaxX))
        del XX
    except :
        pass
    del imageX
    del maskX

def ofmtfp():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.ofmtfp_)
    except :
        pass
    return XX

def ofmuin(x,y) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
        returns :   (as a tuple)
            cch -
    """
    cch = "   "
    xX = miriad_io.copy_floatp(x)
    yX = miriad_io.copy_floatp(y)
    try :
        XX = mx.safecall(miriad_io.ofmuin_,(xX,yX,cch,1))
        del XX
    except :
        pass
    return cch

def options(key,opts,nopt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            key -
            opts -
            nopt -
        returns :   (as a tuple)
            present -
    """
    presentX = intArray(nopt)
    noptX = miriad_io.copy_intp(nopt)
    try :
        XX = mx.safecall(miriad_io.options_,(key,opts,presentX,noptX,len(key),len(opts)))
        del XX
    except :
        pass
    presentR = castLogical(intArrayToList(presentX,nopt))
    del presentX
    return presentR

def keymatch(key,ntype,types,maxout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            key -
            ntype -
            types -
            maxout -
        returns :   (as a tuple)
            out -
            nout -
    """
    out = "                                          "
    ntypeX = miriad_io.copy_intp(ntype)
    maxoutX = miriad_io.copy_intp(maxout)
    noutX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.keymatch_,(key,ntypeX,types,maxoutX,out,noutX,len(key),len(types),maxout))
        del XX
    except :
        pass
    noutR = miriad_io.intp_value(noutX)
    out = out.strip()
    return out,noutR

def pblist():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.pblist_)
    except :
        pass
    return XX

def pbread(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
        returns :   (as a tuple)
            pbtype -
    """
    pbtype = "                                  "
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.pbread_,(tnoX,pbtype,30))
        del XX
    except :
        pass
    pbtype = pbtype.strip()
    return pbtype

def pbwrite(tno,pbtype) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            pbtype -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    try :
        XX = mx.safecall(miriad_io.pbwrite_,(tnoX,pbtype,len(pbtype)))
        del XX
    except :
        pass

def pbencode(pbtype,typeX,val) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            pbtype -
            typeX -
            val -
        returns :   (as a tuple)
    """
    valX = miriad_io.copy_floatp(val)
    try :
        XX = mx.safecall(miriad_io.pbencode_,(pbtype,typeX,valX,len(pbtype),len(typeX)))
        del XX
    except :
        pass

def pbinit(pbtype,coobj) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            pbtype -
            coobj -
        returns :   (as a tuple)
            pbobj -
    """
    pbobjX = miriad_io.new_intp()
    coobjX = miriad_io.copy_intp(coobj)
    try :
        XX = mx.safecall(miriad_io.pbinit_,(pbobjX,pbtype,coobjX,len(pbtype)))
        del XX
    except :
        pass
    pbobjR = miriad_io.intp_value(pbobjX)
    return pbobjR

def pbinitc(typeX,coobj,inp,x1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            typeX -
            coobj -
            inp -
            x1 -
        returns :   (as a tuple)
            pbobj -
    """
    pbobjX = miriad_io.new_intp()
    coobjX = miriad_io.copy_intp(coobj)
    x1X = miriad_io.copy_doublep(x1)
    try :
        XX = mx.safecall(miriad_io.pbinitc_,(pbobjX,typeX,coobjX,inp,x1X,len(typeX),len(inp)))
        del XX
    except :
        pass
    pbobjR = miriad_io.intp_value(pbobjX)
    return pbobjR

def pbfin(pbobj) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            pbobj -
        returns :   (as a tuple)
    """
    pbobjX = miriad_io.copy_intp(pbobj)
    try :
        XX = mx.safecall(miriad_io.pbfin_,(pbobjX,))
        del XX
    except :
        pass

def pbinfo(pbobj) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            pbobj -
        returns :   (as a tuple)
            pbfwhmd -
            cutoffd -
            maxradd -
    """
    pbobjX = miriad_io.copy_intp(pbobj)
    pbfwhmdX = miriad_io.new_floatp()
    cutoffdX = miriad_io.new_floatp()
    maxraddX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.pbinfo_,(pbobjX,pbfwhmdX,cutoffdX,maxraddX))
        del XX
    except :
        pass
    pbfwhmdR = miriad_io.floatp_value(pbfwhmdX)
    cutoffdR = miriad_io.floatp_value(cutoffdX)
    maxraddR = miriad_io.floatp_value(maxraddX)
    return pbfwhmdR,cutoffdR,maxraddR

def pbextent(pbobj) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            pbobj -
        returns :   (as a tuple)
            x -
            y -
            xext -
            yext -
    """
    pbobjX = miriad_io.copy_intp(pbobj)
    xX = miriad_io.new_floatp()
    yX = miriad_io.new_floatp()
    xextX = miriad_io.new_floatp()
    yextX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.pbextent_,(pbobjX,xX,yX,xextX,yextX))
        del XX
    except :
        pass
    xR = miriad_io.floatp_value(xX)
    yR = miriad_io.floatp_value(yX)
    xextR = miriad_io.floatp_value(xextX)
    yextR = miriad_io.floatp_value(yextX)
    return xR,yR,xextR,yextR

def pbfirst():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.pbfirst_)
    except :
        pass
    return XX

def pbadd(tel,f1d,f2d,pbfwhmd,cutoffd,pbtyped,nval,vals,descripd) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tel -
            f1d -
            f2d -
            pbfwhmd -
            cutoffd -
            pbtyped -
            nval -
            vals -
            descripd -
        returns :   (as a tuple)
    """
    f1dX = miriad_io.copy_floatp(f1d)
    f2dX = miriad_io.copy_floatp(f2d)
    pbfwhmdX = miriad_io.copy_floatp(pbfwhmd)
    cutoffdX = miriad_io.copy_floatp(cutoffd)
    pbtypedX = miriad_io.copy_intp(pbtyped)
    nvalX = miriad_io.copy_intp(nval)
    valsX = floatListToArray(vals)
    try :
        XX = mx.safecall(miriad_io.pbadd_,(tel,f1dX,f2dX,pbfwhmdX,cutoffdX,pbtypedX,nvalX,valsX,descripd,len(tel),len(descripd)))
        del XX
    except :
        pass
    del valsX

def pbradp(doinv,cutoff,coeff,ncoeff,pbfwhm) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            doinv -
            cutoff -
            coeff -
            ncoeff -
            pbfwhm -
        returns :   (as a tuple)
            maxrad -
    """
    doinvX = miriad_io.copy_intp(uncastLogical(doinv))
    cutoffX = miriad_io.copy_floatp(cutoff)
    coeffX = floatListToArray(coeff)
    ncoeffX = miriad_io.copy_intp(ncoeff)
    pbfwhmX = miriad_io.copy_floatp(pbfwhm)
    maxradX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.pbradp_,(doinvX,cutoffX,coeffX,ncoeffX,pbfwhmX,maxradX))
        del XX
    except :
        pass
    del coeffX
    maxradR = miriad_io.floatp_value(maxradX)
    return maxradR

def pcvtinit(coobj1d,coobj2d) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            coobj1d -
            coobj2d -
        returns :   (as a tuple)
    """
    coobj1dX = miriad_io.copy_intp(coobj1d)
    coobj2dX = miriad_io.copy_intp(coobj2d)
    try :
        XX = mx.safecall(miriad_io.pcvtinit_,(coobj1dX,coobj2dX))
        del XX
    except :
        pass

def pcvt(x1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x1 -
        returns :   (as a tuple)
            x2 -
    """
    n = len(x1)
    x1X = miriad_io.copy_doublep(x1)
    x2X = doubleArray(n)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.pcvt_,(x1X,x2X,nX))
        del XX
    except :
        pass
    x2R = doubleArrayToList(x2X,n)
    return x2R

def pghline(npts,x,y,gapfac) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            npts -
            x -
            y -
            gapfac -
        returns :   (as a tuple)
    """
    nptsX = miriad_io.copy_intp(npts)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    gapfacX = miriad_io.copy_floatp(gapfac)
    try :
        XX = mx.safecall(miriad_io.pghline_,(nptsX,xX,yX,gapfacX))
        del XX
    except :
        pass
    del xX
    del yX

def pkfit(z,width) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            z -
            width -
        returns :   (as a tuple)
            c -
            zmax -
            pix -
    """
    zX = floatListToArray(z)
    widthX = miriad_io.copy_intp(width)
    zmaxX = miriad_io.new_floatp()
    pixX = doubleArray(2)
    cX = floatArray(6)
    try :
        XX = mx.safecall(miriad_io.pkfit_,(zX,widthX,zmaxX,pixX,cX))
        del XX
    except :
        pass
    del zX
    zmaxR = miriad_io.floatp_value(zmaxX)
    pixR = doubleArrayToList(pixX,2)
    del pixX
    cR = floatArrayToList(cX,6)
    del cX
    return cR,zmaxR,pixR

def getplane(lu,run,nrun,xoff,yoff,nx,ny,maxout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            run -
            nrun -
            xoff -
            yoff -
            nx -
            ny -
            maxout -
        returns :   (as a tuple)
            out -
            nout -
    """
    luX = miriad_io.copy_intp(lu)
    runX = intListToArray(run)
    nrunX = miriad_io.copy_intp(nrun)
    xoffX = miriad_io.copy_intp(xoff)
    yoffX = miriad_io.copy_intp(yoff)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    outX = floatArray(maxout)
    maxoutX = miriad_io.copy_intp(maxout)
    noutX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.getplane_,(luX,runX,nrunX,xoffX,yoffX,nxX,nyX,outX,maxoutX,noutX))
        del XX
    except :
        pass
    del runX
    noutR = miriad_io.intp_value(noutX)
    outR = floatArrayToList(outX,noutR)
    del outX
    return outR

def putplane(lu,run,nrun,xoff,yoff,nx,ny,inp,nin) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lu -
            run -
            nrun -
            xoff -
            yoff -
            nx -
            ny -
            inp -
            nin -
        returns :   (as a tuple)
    """
    luX = miriad_io.copy_intp(lu)
    runX = intListToArray(run)
    nrunX = miriad_io.copy_intp(nrun)
    xoffX = miriad_io.copy_intp(xoff)
    yoffX = miriad_io.copy_intp(yoff)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    inX = floatListToArray(inp)
    ninX = miriad_io.copy_intp(nin)
    try :
        XX = mx.safecall(miriad_io.putplane_,(luX,runX,nrunX,xoffX,yoffX,nxX,nyX,inX,ninX))
        del XX
    except :
        pass
    del runX
    del inX

def putruns(lout,runs,nruns,xoff,yoff,nx,ny) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lout -
            runs -
            nruns -
            xoff -
            yoff -
            nx -
            ny -
        returns :   (as a tuple)
    """
    loutX = miriad_io.copy_intp(lout)
    runsX = intListToArray(runs)
    nrunsX = miriad_io.copy_intp(nruns)
    xoffX = miriad_io.copy_intp(xoff)
    yoffX = miriad_io.copy_intp(yoff)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    try :
        XX = mx.safecall(miriad_io.putruns_,(loutX,runsX,nrunsX,xoffX,yoffX,nxX,nyX))
        del XX
    except :
        pass
    del runsX

def pltbs(iplanet,freq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            iplanet -
            freq -
        returns :   (as a tuple)
            pltbs -
    """
    iplanetX = miriad_io.copy_intp(iplanet)
    freqX = miriad_io.copy_floatp(freq)
    XX = None
    try :
        XX = mx.safecall(miriad_io.pltbs_,(iplanetX,freqX))
    except :
        pass
    return XX

def plradec(jday,np) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            np -
        returns :   (as a tuple)
            ra -
            dec -
    """
    jdayX = miriad_io.copy_doublep(jday)
    npX = miriad_io.copy_intp(np)
    raX = miriad_io.new_doublep()
    decX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.plradec_,(jdayX,npX,raX,decX))
        del XX
    except :
        pass
    raR = miriad_io.doublep_value(raX)
    decR = miriad_io.doublep_value(decX)
    return raR,decR

def plpar(jday,np) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            np -
        returns :   (as a tuple)
            sub -
            dist -
            bmaj -
            bmin -
            bpa -
    """
    jdayX = miriad_io.copy_doublep(jday)
    npX = miriad_io.copy_intp(np)
    subX = doubleArray(3)
    distX = miriad_io.new_doublep()
    bmajX = miriad_io.new_floatp()
    bminX = miriad_io.new_floatp()
    bpaX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.plpar_,(jdayX,npX,subX,distX,bmajX,bminX,bpaX))
        del XX
    except :
        pass
    subR = doubleArrayToList(subX,3)
    del subX
    distR = miriad_io.doublep_value(distX)
    bmajR = miriad_io.floatp_value(bmajX)
    bminR = miriad_io.floatp_value(bminX)
    bpaR = miriad_io.floatp_value(bpaX)
    return subR,distR,bmajR,bminR,bpaR

def plphyeph(jday,np,r) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
            np -
            r -
        returns :   (as a tuple)
            alpha -
            delta -
            w -
            f -
    """
    jdayX = miriad_io.copy_doublep(jday)
    npX = miriad_io.copy_intp(np)
    alphaX = miriad_io.new_doublep()
    deltaX = miriad_io.new_doublep()
    wX = miriad_io.new_doublep()
    rX = miriad_io.copy_doublep(r)
    fX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.plphyeph_,(jdayX,npX,alphaX,deltaX,wX,rX,fX))
        del XX
    except :
        pass
    alphaR = miriad_io.doublep_value(alphaX)
    deltaR = miriad_io.doublep_value(deltaX)
    wR = miriad_io.doublep_value(wX)
    fR = miriad_io.doublep_value(fX)
    return alphaR,deltaR,wR,fR

def plobseph(date,np) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            date -
            np -
        returns :   (as a tuple)
            pv -
            jstat -
    """
    dateX = miriad_io.copy_doublep(date)
    npX = miriad_io.copy_intp(np)
    pvX = doubleArray(6)
    jstatX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.plobseph_,(dateX,npX,pvX,jstatX))
        del XX
    except :
        pass
    pvR = doubleArrayToList(pvX,6)
    del pvX
    jstatR = miriad_io.intp_value(jstatX)
    return pvR,jstatR

def plinit(dist1,plant) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dist1 -
            plant -
        returns :   (as a tuple)
            erad1 -
            prad1 -
    """
    dist1X = miriad_io.copy_floatp(dist1)
    plantX = miriad_io.copy_intp(plant)
    erad1X = miriad_io.new_floatp()
    prad1X = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.plinit_,(dist1X,plantX,erad1X,prad1X))
        del XX
    except :
        pass
    erad1R = miriad_io.floatp_value(erad1X)
    prad1R = miriad_io.floatp_value(prad1X)
    return erad1R,prad1R

def plfake(dist1,lambda1,de) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dist1 -
            lambda1 -
            de -
        returns :   (as a tuple)
    """
    dist1X = miriad_io.copy_floatp(dist1)
    lambdaX = miriad_io.copy_floatp(lambda1)
    deX = miriad_io.copy_floatp(de)
    try :
        XX = mx.safecall(miriad_io.plfake_,(dist1X,lambdaX,deX))
        del XX
    except :
        pass

def plcomm():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.plcomm_)
    except :
        pass
    return XX

def pluvw(uv,time) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            uv -
            time -
        returns :   (as a tuple)
            uvw -
            a -
            b -
            fac1 -
            smatidx -
            bpa1 -
            sub -
    """
    uvX = doubleListToArray(uv)
    timeX = miriad_io.copy_doublep(time)
    uvwX = doubleArray(3)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    fac1X = miriad_io.new_floatp()
    smatidxX = miriad_io.new_intp()
    bpa1X = miriad_io.new_floatp()
    subX = doubleArray(3)
    try :
        XX = mx.safecall(miriad_io.pluvw_,(uvX,timeX,uvwX,aX,bX,fac1X,smatidxX,bpa1X,subX))
        del XX
    except :
        pass
    del uvX
    uvwR = doubleArrayToList(uvwX,3)
    del uvwX
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    fac1R = miriad_io.floatp_value(fac1X)
    smatidxR = miriad_io.intp_value(smatidxX)
    bpa1R = miriad_io.floatp_value(bpa1X)
    subR = doubleArrayToList(subX,3)
    del subX
    return uvwR,aR,bR,fac1R,smatidxR,bpa1R,subR

def rpolyzr(a,nn,ifail) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            nn -
            ifail -
        returns :   (as a tuple)
            roots -
    """
    aX = floatListToArray(a)
    nnX = miriad_io.copy_intp(nn)
    rootsX = FcomplexArray(2*nn)
    ifailX = miriad_io.copy_intp(ifail)
    try :
        XX = mx.safecall(miriad_io.rpolyzr_,(aX,nnX,rootsX,ifailX))
        del XX
    except :
        pass
    del aX
    rootsR = FcomplexArrayToList(rootsX,2*nn)
    del rootsX
    return rootsR

def rpolsolr(tol,x,y,r,rx,j,jx,a,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tol -
            x -
            y -
            r -
            rx -
            j -
            jx -
            a -
            n -
        returns :   (as a tuple)
            sat -
    """
    tolX = miriad_io.copy_floatp(tol)
    xX = miriad_io.copy_floatp(x)
    yX = miriad_io.copy_floatp(y)
    rX = miriad_io.copy_floatp(r)
    rxX = miriad_io.copy_floatp(rx)
    jX = miriad_io.copy_floatp(j)
    jxX = miriad_io.copy_floatp(jx)
    aX = floatListToArray(a)
    nX = miriad_io.copy_intp(n)
    satX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.rpolsolr_,(tolX,xX,yX,rX,rxX,jX,jxX,aX,nX,satX))
        del XX
    except :
        pass
    del aX
    satR = castLogical(miriad_io.intp_value(satX))
    return satR

def dpolyzr(a,nn,ifail) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            a -
            nn -
            ifail -
        returns :   (as a tuple)
            roots -
    """
    aX = doubleListToArray(a)
    nnX = miriad_io.copy_intp(nn)
    rootsX = FcomplexArray(nn)
    ifailX = miriad_io.copy_intp(ifail)
    try :
        XX = mx.safecall(miriad_io.dpolyzr_,(aX,nnX,rootsX,ifailX))
        del XX
    except :
        pass
    del aX
    rootsR = FcomplexArrayToList(rootsX,nn)
    del rootsX
    return rootsR

def dpolsolr(tol,x,y,r,rx,j,jx,a,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tol -
            x -
            y -
            r -
            rx -
            j -
            jx -
            a -
            n -
        returns :   (as a tuple)
            sat -
    """
    tolX = miriad_io.copy_doublep(tol)
    xX = miriad_io.copy_doublep(x)
    yX = miriad_io.copy_doublep(y)
    rX = miriad_io.copy_doublep(r)
    rxX = miriad_io.copy_doublep(rx)
    jX = miriad_io.copy_doublep(j)
    jxX = miriad_io.copy_doublep(jx)
    aX = doubleListToArray(a)
    nX = miriad_io.copy_intp(n)
    satX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.dpolsolr_,(tolX,xX,yX,rX,rxX,jX,jxX,aX,nX,satX))
        del XX
    except :
        pass
    del aX
    satR = castLogical(miriad_io.intp_value(satX))
    return satR

def squares(count,x,y,pmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            count -
            x -
            y -
            pmax -
        returns :   (as a tuple)
    """
    countX = miriad_io.copy_intp(count)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    pmaxX = miriad_io.copy_intp(pmax)
    try :
        XX = mx.safecall(miriad_io.squares_,(countX,xX,yX,pmaxX))
        del XX
    except :
        pass
    del xX
    del yX

def lsqfill(count,x,y,pmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            count -
            x -
            y -
            pmax -
        returns :   (as a tuple)
    """
    countX = miriad_io.copy_intp(count)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    pmaxX = miriad_io.copy_intp(pmax)
    try :
        XX = mx.safecall(miriad_io.lsqfill_,(countX,xX,yX,pmaxX))
        del XX
    except :
        pass
    del xX
    del yX

def solve(nlsq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nlsq -
        returns :   (as a tuple)
    """
    nlsqX = miriad_io.copy_intp(nlsq)
    try :
        XX = mx.safecall(miriad_io.solve_,(nlsqX,))
        del XX
    except :
        pass

def lsqsault(count,x,y,pmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            count -
            x -
            y -
            pmax -
        returns :   (as a tuple)
    """
    countX = miriad_io.copy_intp(count)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    pmaxX = miriad_io.copy_intp(pmax)
    try :
        XX = mx.safecall(miriad_io.lsqsault_,(countX,xX,yX,pmaxX))
        del XX
    except :
        pass
    del xX
    del yX

def opacget(freq,el,t0,p0,h0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            freq -
            el -
            t0 -
            p0 -
            h0 -
        returns :   (as a tuple)
            fac -
            tb -
    """
    nfreq = len(freq)
    nfreqX = miriad_io.copy_intp(nfreq)
    freqX = floatListToArray(freq)
    elX = miriad_io.copy_floatp(el)
    t0X = miriad_io.copy_floatp(t0)
    p0X = miriad_io.copy_floatp(p0)
    h0X = miriad_io.copy_floatp(h0)
    facX = floatArray(nfreq)
    tbX = floatArray(nfreq)
    try :
        XX = mx.safecall(miriad_io.opacget_,(nfreqX,freqX,elX,t0X,p0X,h0X,facX,tbX))
        del XX
    except :
        pass
    del freqX
    facR = floatArrayToList(facX,nfreq)
    del facX
    tbR = floatArrayToList(tbX,nfreq)
    del tbX
    return facR,tbR

def refract(t,pdry,pvap,z,nu,t0,el) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            t -
            pdry -
            pvap -
            z -
            n -
            nu -
            t0 -
            el -
        returns :   (as a tuple)
            tb -
            tau -
            ldry -
            lvap -
    """
    n = len(t)
    tX = floatListToArray(t)
    pdryX = floatListToArray(pdry)
    pvapX = floatListToArray(pvap)
    z__X = miriad_io.copy_floatp(z)
    nX = miriad_io.copy_intp(n)
    nuX = miriad_io.copy_floatp(nu)
    t0X = miriad_io.copy_floatp(t0)
    elX = miriad_io.copy_floatp(el)
    tbX = miriad_io.new_floatp()
    tauX = miriad_io.new_floatp()
    ldryX = miriad_io.new_floatp()
    lvapX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.refract_,(tX,pdryX,pvapX,z__X,nX,nuX,t0X,elX,tbX,tauX,ldryX,lvapX))
        del XX
    except :
        pass
    del tX
    del pdryX
    del pvapX
    tbR = miriad_io.floatp_value(tbX)
    tauR = miriad_io.floatp_value(tauX)
    ldryR = miriad_io.floatp_value(ldryX)
    lvapR = miriad_io.floatp_value(lvapX)
    return tbR,tauR,ldryR,lvapR

def restini(lbeam,nx1,ny1,fwhm1,fwhm2,pa,mode) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lbeam -
            nx1 -
            ny1 -
            fwhm1 -
            fwhm2 -
            pa -
            mode -
        returns :   (as a tuple)
    """
    lbeamX = miriad_io.copy_intp(lbeam)
    nx1X = miriad_io.copy_intp(nx1)
    ny1X = miriad_io.copy_intp(ny1)
    fwhm1X = miriad_io.copy_floatp(fwhm1)
    fwhm2X = miriad_io.copy_floatp(fwhm2)
    paX = miriad_io.copy_floatp(pa)
    try :
        XX = mx.safecall(miriad_io.restini_,(lbeamX,nx1X,ny1X,fwhm1X,fwhm2X,paX,mode,len(mode)))
        del XX
    except :
        pass

def restget(lbeam,n1,n2,nx,ny,ic,jc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lbeam -
            n1 -
            n2 -
            nx -
            ny -
            ic -
            jc -
        returns :   (as a tuple)
            data -
    """
    lbeamX = miriad_io.copy_intp(lbeam)
    dataX = floatArray(nx,ny)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    try :
        XX = mx.safecall(miriad_io.restget_,(lbeamX,dataX,n1X,n2X,nxX,nyX,icX,jcX))
        del XX
    except :
        pass
    dataR = floatArrayToList(dataX,nx,ny)
    del dataX
    return dataR

def restdiff(lbeam,n1,n2,nx,ny,ic,jc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lbeam -
            n1 -
            n2 -
            nx -
            ny -
            ic -
            jc -
        returns :   (as a tuple)
            gaus -
    """
    lbeamX = miriad_io.copy_intp(lbeam)
    gausX = floatArray(nx,ny)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    icX = miriad_io.copy_intp(ic)
    jcX = miriad_io.copy_intp(jc)
    try :
        XX = mx.safecall(miriad_io.restdiff_,(lbeamX,gausX,n1X,n2X,nxX,nyX,icX,jcX))
        del XX
    except :
        pass
    gausR = floatArrayToList(gausX,nx,ny)
    del gausX
    return gausR

def restgaus(nx,ny,x0,y0,bmaj,bmin,bpa) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nx -
            ny -
            x0 -
            y0 -
            bmaj -
            bmin -
            bpa -
        returns :   (as a tuple)
            gaus -
    """
    gausX = floatArray(nx,ny)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    x0X = miriad_io.copy_intp(x0)
    y0X = miriad_io.copy_intp(y0)
    bmajX = miriad_io.copy_floatp(bmaj)
    bminX = miriad_io.copy_floatp(bmin)
    bpaX = miriad_io.copy_floatp(bpa)
    try :
        XX = mx.safecall(miriad_io.restgaus_,(gausX,nxX,nyX,x0X,y0X,bmajX,bminX,bpaX))
        del XX
    except :
        pass
    gausR = floatArrayToList(gausX,nx,ny)
    del gausX
    return gausR

def restore(lmodel,i) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lmodel -
            i -
        returns :   (as a tuple)
            out -
    """
    lmodelX = miriad_io.copy_intp(lmodel)
    iX = miriad_io.copy_intp(i)
    outX = floatArray(100000)
    try :
        XX = mx.safecall(miriad_io.restore_,(lmodelX,iX,outX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,100000)
    del outX
    return outR

def restadd(out,dat,nx,ny) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dat -
            nx -
            ny -
        returns :   (as a tuple)
            out -
    """
    outX = floatListToArray(out)
    datX = floatListToArray(dat)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    try :
        XX = mx.safecall(miriad_io.restadd_,(outX,datX,nxX,nyX))
        del XX
    except :
        pass
    outR = floatArrayToList(outX,nx,ny)
    del outX
    del datX
    return outR

def restfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.restfin_)
    except :
        pass
    return XX

def selinput(key,maxsels) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            key -
            maxsels -
        returns :   (as a tuple)
            sels -
    """
    selsX = floatArray(maxsels)
    maxselsX = miriad_io.copy_intp(maxsels)
    try :
        XX = mx.safecall(miriad_io.selinput_,(key,selsX,maxselsX,len(key)))
        del XX
    except :
        pass
    selsR = floatArrayToList(selsX,maxsels)
    del selsX
    return selsR

def selfudge(dval) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dval -
        returns :   (as a tuple)
            rval -
    """
    rvalX = miriad_io.new_floatp()
    dvalX = miriad_io.copy_doublep(dval)
    try :
        XX = mx.safecall(miriad_io.selfudge_,(rvalX,dvalX))
        del XX
    except :
        pass
    rvalR = miriad_io.floatp_value(rvalX)
    return rvalR

def selbug(spec,message) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            message -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.selbug_,(spec,message,len(spec),len(message)))
        del XX
    except :
        pass

def seldcde(spec,k1,k2,nmax,format) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            spec -
            k1 -
            k2 -
            nmax -
            format -
        returns :   (as a tuple)
            k1 -
            k2 -
            vals -
            n -
    """
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    valsX = doubleArray(nmax)
    nX = miriad_io.new_intp()
    nmaxX = miriad_io.copy_intp(nmax)
    try :
        XX = mx.safecall(miriad_io.seldcde_,(spec,k1X,k2X,valsX,nX,nmaxX,format,len(spec),len(format)))
        del XX
    except :
        pass
    k1R =  miriad_io.intp_value(k1X)
    k2R =  miriad_io.intp_value(k2X)
    nR = miriad_io.intp_value(nX)
    valsR = doubleArrayToList(valsX,nR)
    del valsX
    return k1R,k2R,valsR

def selapply(tno,sels,select) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            sels -
            select -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    selsX = floatListToArray(sels)
    selectX = miriad_io.copy_intp(select)
    try :
        XX = mx.safecall(miriad_io.selapply_,(tnoX,selsX,selectX))
        del XX
    except :
        pass
    del selsX

def sfetra(slon,slat,inv,sys) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            slon -
            slat -
            inv -
            sys -
        returns :   (as a tuple)
            slon -
            slat -
    """
    slonX = miriad_io.copy_floatp(slon)
    slatX = miriad_io.copy_floatp(slat)
    invX = miriad_io.copy_intp(uncastLogical(inv))
    sysX = miriad_io.copy_intp(sys)
    try :
        XX = mx.safecall(miriad_io.sfetra_,(slonX,slatX,invX,sysX))
        del XX
    except :
        pass
    slonR = miriad_io.floatp_value(slonX)
    slatR = miriad_io.floatp_value(slatX)
    return slonR,slatR

def dsfetra(lon,lat,inv,sys) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lon -
            lat -
            inv -
            sys -
        returns :   (as a tuple)
            lon -
            lat -
    """
    lonX = miriad_io.copy_doublep(lon)
    latX = miriad_io.copy_doublep(lat)
    invX = miriad_io.copy_intp(uncastLogical(inv))
    sysX = miriad_io.copy_intp(sys)
    try :
        XX = mx.safecall(miriad_io.dsfetra_,(lonX,latX,invX,sysX))
        del XX
    except :
        pass
    lonR = miriad_io.doublep_value(lonX)
    latR = miriad_io.doublep_value(latX)
    return lonR,latR

def shadowed(tno,ants,limit) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            ants -
            limit -
        returns :
            shadowed -
    """
    tnoX = miriad_io.copy_intp(tno)
    antsX = miriad_io.copy_doublep(ants)
    limitX = miriad_io.copy_floatp(limit)
    XX = None
    try :
        XX = mx.safecall(miriad_io.shadowed_,(tnoX,antsX,limitX))
    except :
        pass
    return XX

def sortr(array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            array -
        returns :   (as a tuple)
            array -
    """
    n = len(array)
    arrayX = floatListToArray(array)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.sortr_,(arrayX,nX))
        del XX
    except :
        pass
    arrayR = floatArrayToList(arrayX,n)
    del arrayX
    return arrayR

def sortd(array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            array -
        returns :   (as a tuple)
            array -
    """
    n = len(array)
    arrayX = doubleListToArray(array)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.sortd_,(arrayX,nX))
        del XX
    except :
        pass
    arrayR = doubleArrayToList(arrayX,n)
    del arrayX
    return arrayR

def sorti(array) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            array -
        returns :   (as a tuple)
            array -
    """
    n = len(array)
    arrayX = intListToArray(array)
    nX = miriad_io.copy_intp(n)
    try :
        XX = mx.safecall(miriad_io.sorti_,(arrayX,nX))
        del XX
    except :
        pass
    arrayR = intArrayToList(arrayX,n)
    del arrayX
    return arrayR

def spaxsw(lh,switch,ctype,cdelt,crval) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lh -
            switch -
            ctype -
            cdelt -
            crval -
        returns :   (as a tuple)
            ctype -
            cdelt -
            crval -
    """
    lhX = miriad_io.copy_intp(lh)
    cdeltX = miriad_io.copy_doublep(cdelt)
    crvalX = miriad_io.copy_doublep(crval)
    try :
        XX = mx.safecall(miriad_io.spaxsw_,(lhX,switch,ctype,cdeltX,crvalX,len(switch),len(ctype)))
        del XX
    except :
        pass
    cdeltR =  miriad_io.intp_value(cdeltX)
    crvalR =  miriad_io.intp_value(crvalX)
    return cdeltR,crvalR

def spline(x,y) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            y -
        returns :   (as a tuple)
            b -
            c -
            d -
    """
    n = len(x)
    nX = miriad_io.copy_intp(n)
    xX = doubleListToArray(x)
    yX = doubleListToArray(y)
    bX = doubleArray(n)
    cX = doubleArray(n)
    dX = doubleArray(n)
    try :
        XX = mx.safecall(miriad_io.spline_,(nX,xX,yX,bX,cX,dX))
        del XX
    except :
        pass
    del xX
    del yX
    bR = doubleArrayToList(bX,n)
    del bX
    cR = doubleArrayToList(cX,n)
    del cX
    dR = doubleArrayToList(dX,n)
    del dX
    return bR,cR,dR

def gettok(string,k1,k2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
            k1 -
            k2 -
        returns :   (as a tuple)
            k1 -
            k2 -
            token -
    """
    token = "             "
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    lengthX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.gettok_,(string,k1X,k2X,token,lengthX,len(string),10))
        del XX
    except :
        pass
    k1R = miriad_io.intp_value(k1X)
    k2R = miriad_io.intp_value(k2X)
    token = token.strip()
    return k1R,k2R,token

def getfield(string,k1,k2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
            k1 -
            k2 -
        returns :   (as a tuple)
            k1 -
            k2 -
            token -
            length -
    """
    token = "             "
    k1X = miriad_io.copy_intp(k1)
    k2X = miriad_io.copy_intp(k2)
    lengthX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.getfield_,(string,k1X,k2X,token,lengthX,len(string),10))
        del XX
    except :
        pass
    k1R = miriad_io.intp_value(k1X)
    k2R = miriad_io.intp_value(k2X)
    lengthR = miriad_io.intp_value(lengthX)
    token = token.strip()
    return k1R,k2R,token,lengthR

def calget(filename,source,freq,delfreq,day,deldate,flux) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            filename -
            source -
            freq -
            delfreq -
            day -
            deldate -
            flux -
        returns :   (as a tuple)
            source -
            freq -
            day -
            flux -
            iostat -
    """
    freqX = miriad_io.copy_floatp(freq)
    delfreqX = miriad_io.copy_floatp(delfreq)
    dayX = miriad_io.copy_doublep(day)
    deldateX = miriad_io.copy_floatp(deldate)
    fluxX = miriad_io.copy_floatp(flux)
    iostatX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.calget_,(filename,source,freqX,delfreqX,dayX,deldateX,fluxX,iostatX,len(filename),len(source)))
        del XX
    except :
        pass
    freqR = miriad_io.floatp_value(freqX)
    dayR = miriad_io.doublep_value(dayX)
    fluxR = miriad_io.floatp_value(fluxX)
    iostatR = miriad_io.intp_value(iostatX)
    source = source.strip()
    return source,freqR,dayR,fluxR,iostatR

def tabflux(filename,source,freq,delfreq,day,delday,flux,line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            filename -
            source -
            freq -
            delfreq -
            day -
            delday -
            flux -
            line -
        returns :   (as a tuple)
            source -
            freq -
            day -
            flux -
            line -
            rms -
            iostat -
    """
    freqX = miriad_io.copy_floatp(freq)
    delfreqX = miriad_io.copy_floatp(delfreq)
    dayX = miriad_io.copy_doublep(day)
    deldayX = miriad_io.copy_floatp(delday)
    fluxX = miriad_io.copy_floatp(flux)
    rmsX = miriad_io.new_floatp()
    lineX = miriad_io.copy_intp(line)
    iostatX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.tabflux_,(filename,source,freqX,delfreqX,dayX,deldayX,fluxX,rmsX,lineX,iostatX,1,len(source)))
        del XX
    except :
        pass
    freqR = miriad_io.floatp_value(freqX)
    dayR = miriad_io.doublep_value(dayX)
    fluxR = miriad_io.floatp_value(fluxX)
    rmsR = miriad_io.floatp_value(rmsX)
    lineR = miriad_io.intp_value(lineX)
    iostatR = miriad_io.intp_value(iostatX)
    source = source.strip()
    return source,freqR,dayR,fluxR,lineR,rmsR,iostatR

def tabload(name,source) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name -
            source -
        returns :   (as a tuple)
            iostat -
    """
    iostatX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.tabload_,(name,source,iostatX,len(name),len(source)))
        del XX
    except :
        pass
    iostatR = miriad_io.intp_value(iostatX)
    return iostatR

def car2bim(string) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.car2bim_,(string,len(string)))
        del XX
    except :
        pass

def tabfind(source,freq,deltnu,day,deltime,line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            source -
            freq -
            deltnu -
            day -
            deltime -
            line -
        returns :   (as a tuple)
            source -
            freq -
            day -
            line -
            flux -
            rms -
            iostat -
    """
    freqX = miriad_io.copy_floatp(freq)
    deltnuX = miriad_io.copy_floatp(deltnu)
    dayX = miriad_io.copy_doublep(day)
    deltimeX = miriad_io.copy_floatp(deltime)
    fluxX = miriad_io.new_floatp()
    rmsX = miriad_io.new_floatp()
    lineX = miriad_io.copy_intp(line)
    iostatX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.tabfind_,(source,freqX,deltnuX,dayX,deltimeX,fluxX,rmsX,lineX,iostatX,len(source)))
        del XX
    except :
        pass
    freqR = miriad_io.floatp_value(freqX)
    dayR = miriad_io.doublep_value(dayX)
    fluxR = miriad_io.floatp_value(fluxX)
    rmsR = miriad_io.floatp_value(rmsX)
    lineR = miriad_io.intp_value(lineX)
    iostatR = miriad_io.intp_value(iostatX)
    return source,freqR,dayR,lineR,fluxR,rmsR,iostatR

def tabparse(string,length,source,nentry) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
            length -
            source -
            nentry -
        returns :   (as a tuple)
            nentry -
    """
    lengthX = miriad_io.copy_intp(length)
    nentryX = miriad_io.copy_intp(nentry)
    try :
        XX = mx.safecall(miriad_io.tabparse_,(string,lengthX,source,nentryX,len(string),len(source)))
        del XX
    except :
        pass
    nentryR = miriad_io.intp_value(nentryX)
    return nentryR

def aliases(source) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            source -
        returns :   (as a tuple)
            srcalias -
    """
    srcalias = "              "
    try :
        XX = mx.safecall(miriad_io.aliases_,(source,srcalias,len(source),12))
        del XX
    except :
        pass
    srcalias = srcalias.strip()
    return srcalias

def addalias(anchor,srcalias) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            anchor -
            srcalias -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.addalias_,(anchor,srcalias,len(anchor),len(srcalias)))
        del XX
    except :
        pass

def namparse(string) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
        returns :   (as a tuple)
    """
    lengthX = miriad_io.copy_intp(len(string))
    try :
        XX = mx.safecall(miriad_io.namparse_,(string,lengthX,len(string)))
        del XX
    except :
        pass

def dectime(string,value,fmt,ok) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            string -
            value -
            fmt -
            ok -
        returns :   (as a tuple)
    """
    valueX = miriad_io.copy_doublep(value)
    okX = miriad_io.copy_intp(uncastLogical(ok))
    try :
        XX = mx.safecall(miriad_io.dectime_,(string,valueX,fmt,okX,len(string),len(fmt)))
        del XX
    except :
        pass

def decangle(angle,fmt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            angle -
            val -
        returns :   (as a tuple)
            fmt -
            ok -
    """
    valX = miriad_io.new_doublep()
    okX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.decangle_,(angle,valX,fmt,okX,len(angle),len(fmt)))
        del XX
    except :
        pass
    valR = miriad_io.doublep_value(valX)
    okR = castLogical(miriad_io.intp_value(okX))
    return valR,okR

def title(lin,naxis,blc,trc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            lin -
            naxis -
            blc -
            trc -
        returns :   (as a tuple)
            cbof -
    """
    linX = miriad_io.copy_intp(lin)
    naxisX = miriad_io.copy_intp(naxis)
    blcX = intListToArray(blc)
    trcX = intListToArray(trc)
    cbofX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.title_,(linX,naxisX,blcX,trcX,cbofX))
        del XX
    except :
        pass
    del blcX
    del trcX
    cbofR = miriad_io.floatp_value(cbofX)
    return cbofR

def imscale(map,mx,nx,ny,pmax) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            map -
            mx -
            nx -
            ny -
        returns :   (as a tuple)
            pmin -
            pmax -
    """
    mapX = floatListToArray(map)
    mxX = miriad_io.copy_intp(mx)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    pminX = miriad_io.new_floatp()
    pmaxX = miriad_io.copy_floatp(pmax)
    try :
        XX = mx.safecall(miriad_io.imscale_,(mapX,mxX,nxX,nyX,pminX,pmaxX))
        del XX
    except :
        pass
    del mapX
    pminR = miriad_io.floatp_value(pminX)
    pmaxR = miriad_io.floatp_value(pmaxX)
    return pminR,pmaxR

def uvdatinp(key,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            key -
            flags -
        returns :   (as a tuple)
    """
    try :
        XX = mx.safecall(miriad_io.uvdatinp_,(key,flags,len(key),len(flags)))
        del XX
    except :
        pass

def uvdatpy(vis1,vis2,ltype=" ",nchan=0,lstart=1.0,lwidth=1.0,lstep=1.0,lflags=1.0,refline=" ",rstart=1.0,rwidth=1.0,flags="") :
    """ Miriad wrapper for uvdatinp routine specifically adapted for python
        input :
            vis1,vis2 - the input visibility files
            ltype,nchan,lstart,lwidth,lflags - line parameters
            refline,,rstart,rwidth - refernce line parameters
            flags - the input flags
    """
    if("elocity" in ltype) :
        if(lstart == 1.0) :
            lstart = 0.0
        if(lwidth == 1.0) :
            lwidth = 0.0
        if(lstep == 1.0) :
            lstep = 0.0
    if("elocity" in refline) :
        if(rstart == 1.0) :
            rstart = 0.0
        if(rwidth == 1.0) :
            rwidth = 0.0
    nchanX = miriad_io.copy_intp(nchan)
    lstartX = miriad_io.copy_floatp(lstart)
    lwidthX = miriad_io.copy_floatp(lwidth)
    lstepX = miriad_io.copy_floatp(lstep)
    lflagsX = miriad_io.copy_floatp(lflags)
    rstartX = miriad_io.copy_floatp(rstart)
    rwidthX = miriad_io.copy_floatp(rwidth)
    #try :
    XX = mx.safecall(miriad_io.uvdatpy_,(vis1,vis2,ltype,nchanX,lstartX,lwidthX,lstepX,lflagsX,refline,rstartX,rwidthX,flags,len(vis1),len(vis2),len(ltype),len(refline),len(flags)))
    print XX
    del XX
    #except :
    #    pass
    return

def uvpolinp(maxpol) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            maxpol -
        returns :   (as a tuple)
            npol -
            pols -
    """
    maxpolX = miriad_io.copy_intp(maxpol)
    npolX = miriad_io.new_intp()
    polsX = intArray(maxpol)
    try :
        XX = mx.safecall(miriad_io.uvpolinp_,(maxpolX,npolX,polsX))
        del XX
    except :
        pass
    npolR = miriad_io.intp_value(npolX)
    polsR = intArrayToList(polsX,npolR)
    del polsX
    return polsR

def uvdatopn() :
    tnoX = miriad_io.new_intp()
    result = None
    #try :
    result = mx.safecall(miriad_io.uvdatopn_,(tnoX,))
    #except :
    #   pass
    tno = miriad_io.intp_value(tnoX)
    return castLogical(result),tno

def uvdatrd(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            preamble -
            data -
            flags -
    """
    preambleX = doubleArray(12)
    dataX = FcomplexArray(n)
    flagsX = intArray(n)
    nX = miriad_io.copy_intp(n)
    nreadX = miriad_io.new_intp()
    print "XXX"
    try :
        XX = mx.safecall(miriad_io.uvdatrd_,(preambleX,dataX,flagsX,nX,nreadX))
        del XX
    except :
        print "ZZZ"
        pass
    print "YYY"
    preambleR = doubleArrayToList(preambleX,12)
    nreadR = miriad_io.intp_value(nreadX)
    dataR = FcomplexArrayToList(dataX,nreadR*2)
    temp = intArrayToList(flagsX,nreadR)
    flagsR = castLogical(temp)
    temp = (preambleR,dataR,flagsR)
    return temp

def uvdatrew():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvdatrew_)
    except :
        pass
    return XX

def uvdatcls():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvdatcls_)
    except :
        pass
    return XX

def uvpolget(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            preamble -
            data -
            flags -
            nread -
    """
    preambleX = doubleArray(12)
    dataX = FcomplexArray(n)
    flagsX = intArray(n)
    nX = miriad_io.copy_intp(n)
    nreadX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.uvpolget_,(preambleX,dataX,flagsX,nX,nreadX))
        del XX
    except :
        pass
    preambleR = doubleArrayToList(preambleX,12)
    del preambleX
    nreadR = miriad_io.intp_value(nreadX)
    dataR = FcomplexArrayToList(dataX,nreadR*2)
    flagsR = castLogical(intArrayToList(flagsX,nreadR))
    del flagsX
    return preambleR,dataR,flagsR

def uvpolchi() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            nochi -
            cos2chi -
            sin2chi -
    """
    nochiX = miriad_io.new_intp()
    cos2chiX = miriad_io.new_floatp()
    sin2chiX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.uvpolchi_,(nochiX,cos2chiX,sin2chiX))
        del XX
    except :
        pass
    nochiR = castLogical(miriad_io.intp_value(nochiX))
    cos2chiR = miriad_io.floatp_value(cos2chiX)
    sin2chiR = miriad_io.floatp_value(sin2chiX)
    return nochiR,cos2chiR,sin2chiR

def uvdatwrd(n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n -
        returns :   (as a tuple)
            data -
            flags -
            nread -
    """
    dataX = FcomplexArray(n)
    flagsX = intArray(n)
    nX = miriad_io.copy_intp(n)
    nreadX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.uvdatwrd_,(dataX,flagsX,nX,nreadX))
        del XX
    except :
        pass
    nreadR = miriad_io.intp_value(nreadX)
    dataR = FcomplexArrayToList(dataX,nreadR*2)
    flagsR = castLogical(intArrayToList(flagsX,nreadR))
    del flagsX
    return dataR,flagsR

def uvdatgti(objt,length = 100) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            objt -
        returns :   (as a tuple)
            ival -
    """
    ivalX = None
    if(length > 1) :
        ivalX = intArray(length)
    else :
        ivalX = miriad_io.new_intp()
    #try :
    print "in"
    XX = mx.safecall(miriad_io.uvdatgti_,(objt,ivalX,len(objt)))
    print "endcall"
    del XX
    #except :
    #    pass
    print "next"
    ivalR = None
    if(length > 1) :
        ivalR = intArrayToList(ivalX,length)
        del ivalX
    else :
        ivalR = miriad_io.intp_value(ivalX)
    print "out"
    return ivalR

def uvdatgtr(objt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            objt -
        returns :   (as a tuple)
            rval -
    """
    rvalX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.uvdatgtr_,(objt,rvalX,len(objt)))
        del XX
    except :
        pass
    rvalR = miriad_io.floatp_value(rvalX)
    return rvalR

def uvdatgta(objt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            objt -
        returns :   (as a tuple)
            aval -
    """
    aval = "                           "
    try :
        XX = mx.safecall(miriad_io.uvdatgta_,(objt,aval,len(objt),20))
        del XX
    except :
        pass
    aval = aval.strip()
    return aval

def uvdatset(objt,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            objt -
            value -
        returns :   (as a tuple)
    """
    valueX = miriad_io.copy_intp(value)
    try :
        XX = mx.safecall(miriad_io.uvdatset_,(objt,valueX,len(objt)))
        del XX
    except :
        pass

def uvlkini():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvlkini_)
    except :
        pass
    return XX

def uvlkcorr(baseline,maxpol,ncoeff,typeX,coeffs,leaks,nleaks) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            baseline -
            maxpol -
            ncoeff -
            typeX -
            coeffs -
            leaks -
            nleaks -
        returns :   (as a tuple)
            typeX -
            coeffs -
    """
    baselineX = miriad_io.copy_doublep(baseline)
    maxpolX = miriad_io.copy_intp(maxpol)
    ncoeffX = miriad_io.copy_intp(ncoeff)
    l = len(typeX)
    typeX = intListToArray(typeX)
    coeffsX = FcomplexListToArray(coeffs)
    leaksX = FcomplexListToArray(leaks)
    nleaksX = miriad_io.copy_intp(nleaks)
    try :
        XX = mx.safecall(miriad_io.uvlkcorr_,(baselineX,maxpolX,ncoeffX,typeX,coeffsX,leaksX,nleaksX))
        del XX
    except :
        pass
    ncoeffR = miriad_io.intp_value(ncoeffX)
    typeR = intArrayToList(typeX,l)
    del typeX
    coeffsR = complexArrayToList(coeffsX,ncoeffR)
    del coeffsX
    del leaksX
    return typeR,coeffsR

def uvfit1(tno,objt,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            objt -
            n -
        returns :   (as a tuple)
            a -
            epsi -
    """
    tnoX = miriad_io.copy_intp(tno)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_doublep()
    epsiX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.uvfit1_,(tnoX,objt,nX,aX,epsiX,len(objt)))
        del XX
    except :
        pass
    aR = miriad_io.doublep_value(aX)
    epsiR = miriad_io.doublep_value(epsiX)
    return aR,epsiR

def uvfit2(tno,objt,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            objt -
            n -
        returns :   (as a tuple)
            a -
            b -
            epsi -
    """
    tnoX = miriad_io.copy_intp(tno)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_doublep()
    bX = miriad_io.new_doublep()
    epsiX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.uvfit2_,(tnoX,objt,nX,aX,bX,epsiX,len(objt)))
        del XX
    except :
        pass
    aR = miriad_io.doublep_value(aX)
    bR = miriad_io.doublep_value(bX)
    epsiR = miriad_io.doublep_value(epsiX)
    return aR,bR,epsiR

def uvgetbl(preambl,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            preambl -
            data -
        returns :   (as a tuple)
            preambl -
            data -
            bl -
    """
    nread = len(data)
    preamblX = doubleListToArray(preambl)
    dataX = FcomplexListToArray(data)
    nreadX = miriad_io.copy_intp(nread)
    blX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.uvgetbl_,(preamblX,dataX,nreadX,blX))
        del XX
    except :
        pass
    preamblR = doubleArrayToList(preamblX,4)
    del preamblX
    dataR = FcomplexArrayToList(data,2*nread)
    del dataX
    blR = miriad_io.intp_value(blX)
    return preamblR,dataR,blR

def uvgnini(tno1,dogains1,dopass1) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno1 -
            dogains1 -
            dopass1 -
        returns :   (as a tuple)
    """
    tno1X = miriad_io.copy_intp(tno1)
    dogains1X = miriad_io.copy_intp(uncastLogical(dogains1))
    dopass1X = miriad_io.copy_intp(uncastLogical(dopass1))
    try :
        XX = mx.safecall(miriad_io.uvgnini_,(tno1X,dogains1X,dopass1X))
        del XX
    except :
        pass

def uvgngnin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvgngnin_)
    except :
        pass
    return XX

def uvgnpsin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvgnpsin_)
    except :
        pass
    return XX

def uvgnfin():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvgnfin_)
    except :
        pass
    return XX

def uvgnfac(time,baseline,pol,dowide,data,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            time -
            baseline -
            pol -
            dowide -
            data -
            flags -
        returns :   (as a tuple)
            data -
            flags -
            grms -
    """
    nread = len(flags)
    timeX = miriad_io.copy_doublep(time)
    baselineX = miriad_io.copy_doublep(baseline)
    polX = miriad_io.copy_intp(pol)
    dowideX = miriad_io.copy_intp(uncastLogical(dowide))
    dataX = FcomplexListToArray(data)
    flagsX = intListToArray(uncastLogical(flags))
    nreadX = miriad_io.copy_intp(nread)
    grmsX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.uvgnfac_,(timeX,baselineX,polX,dowideX,dataX,flagsX,nreadX,grmsX))
        del XX
    except :
        pass
    dataR = FcomplexArrayToList(dataX,nread*2)
    del dataX
    flagsR = castLogical(intArrayToList(flagsX,nread))
    del flagsX
    grmsR = miriad_io.floatp_value(grmsX)
    return dataR,flagsR,grmsR

def uvgncwap(dowide,ant1,ant2,data,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dowide -
            ant1 -
            ant2 -
            data -
            flags -
        returns :   (as a tuple)
            data -
            flags -
    """
    dowideX = miriad_io.copy_intp(uncastLogical(dowide))
    ant1X = miriad_io.copy_intp(ant1)
    ant2X = miriad_io.copy_intp(ant2)
    dataX = FcomplexListToArray(data)
    flagsX = intListToArray(uncastLogical(flags))
    nreadX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.uvgncwap_,(dowideX,ant1X,ant2X,dataX,flagsX,nreadX))
        del XX
    except :
        pass
    nreadR = miriad_io.intp_value(nreadX)
    dataR = FcomplexArrayToList(dataX,nreadR*2)
    del dataX
    flagsR = castLogical(intArrayToList(flagsX,nreadR))
    del flagsX
    return dataR,flagsR

def uvgnget(gitem,solno,nsols,ngains) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            gitem -
            solno -
            nsols -
            ngains -
        returns :   (as a tuple)
            gains -
            flags -
    """
    gitemX = miriad_io.copy_intp(gitem)
    solnoX = miriad_io.copy_intp(solno)
    gainsX = FcomplexArray(ngains)
    flagsX = intArray(ngains)
    nsolsX = miriad_io.copy_intp(nsols)
    ngainsX = miriad_io.copy_intp(ngains)
    try :
        XX = mx.safecall(miriad_io.uvgnget_,(gitemX,solnoX,gainsX,flagsX,nsolsX,ngainsX))
        del XX
    except :
        pass
    gainsR = FcomplexArrayToList(gainsX,ngains)
    del gainsX
    flagsR = castLogical(intArrayToList(flagsX,ngains))
    del flagsX
    return gainsR,flagsR

def uvgnpsap(dowide,ant1,ant2,p,tau,data,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            dowide -
            ant1 -
            ant2 -
            p -
            tau -
            data -
            flags -
            nread -
        returns :   (as a tuple)
            data -
            flags -
    """
    nread = len(flags)
    dowideX = miriad_io.copy_intp(uncastLogical(dowide))
    ant1X = miriad_io.copy_intp(ant1)
    ant2X = miriad_io.copy_intp(ant2)
    pX = miriad_io.copy_intp(p)
    tauX = miriad_io.copy_Fcomplexp(convertComplex(tau))
    dataX = FcomplexListToArray(data)
    flagsX = intListToArray(uncastLogical(flags))
    nreadX = miriad_io.copy_intp(nread)
    try :
        XX = mx.safecall(miriad_io.uvgnpsap_,(dowideX,ant1X,ant2X,pX,tauX,dataX,flagsX,nreadX))
        del XX
    except :
        pass
    dataR = FcomplexArrayToList(dataX,nread*2)
    del dataX
    flagsR = castLogical(intArrayToList(flagsX,nread))
    del flagsX
    return dataR,flagsR

def uvgnps1t(tno,vwide,vline) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            vwide -
            vline -
        returns :   (as a tuple)
    """
    tnoX = miriad_io.copy_intp(tno)
    vwideX = miriad_io.copy_intp(vwide)
    vlineX = miriad_io.copy_intp(vline)
    try :
        XX = mx.safecall(miriad_io.uvgnps1t_,(tnoX,vwideX,vlineX))
        del XX
    except :
        pass

def uvgnpspb(ant1,ant2,p,nfeeds,nants,gains,gflags,data,flags,nread) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ant1 -
            ant2 -
            p -
            nfeeds -
            nants -
            gains -
            gflags -
            data -
            flags -
            nread -
        returns :   (as a tuple)
            data -
            flags -
    """
    ant1X = miriad_io.copy_intp(ant1)
    ant2X = miriad_io.copy_intp(ant2)
    pX = miriad_io.copy_intp(p)
    nfeedsX = miriad_io.copy_intp(nfeeds)
    nantsX = miriad_io.copy_intp(nants)
    gainsX = miriad_io.copy_Fcomplexp(convertComplex(gains))
    gflagsX = intListToArray(uncastLogical(gflags))
    dataX = FcomplexListToArray(data)
    flagsX = intListToArray(uncastLogical(flags))
    nreadX = miriad_io.copy_intp(nread)
    try :
        XX = mx.safecall(miriad_io.uvgnpspb_,(ant1X,ant2X,pX,nfeedsX,nantsX,gainsX,gflagsX,dataX,flagsX,nreadX))
        del XX
    except :
        pass
    del gflagsX
    dataR = FcomplexArrayToList(dataX,nread*2)
    del dataX
    flagsR = castLogical(intArrayToList(flagsX,nread))
    del flagsX
    return dataR,flagsR

def uvgnpsdl(tau,data,freq,freq0,nread) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tau -
            data -
            freq -
            freq0 -
            nread -
        returns :   (as a tuple)
            data -
    """
    tauX = miriad_io.copy_Fcomplexp(convertComplex(tau))
    dataX = FcomplexListToArray(data)
    freqX = doubleListToArray(freq)
    freq0X = miriad_io.copy_doublep(freq0)
    nreadX = miriad_io.copy_intp(nread)
    try :
        XX = mx.safecall(miriad_io.uvgnpsdl_,(tauX,dataX,freqX,freq0X,nreadX))
        del XX
    except :
        pass
    dataR = FcomplexArrayToList(dataX,nread*2)
    del dataX
    del freqX
    return dataR

def uvgnpsld(tno,maxspect,ngains) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            maxspect -
            ngains -
        returns :   (as a tuple)
            nchan -
            nspect -
            sfreq -
            sdf -
            nschan -
            pgains -
            size -
    """
    tnoX = miriad_io.copy_intp(tno)
    maxspectX = miriad_io.copy_intp(maxspect)
    ngainsX = miriad_io.copy_intp(ngains)
    nchanX = miriad_io.new_intp()
    nspectX = miriad_io.new_intp()
    sfreqX = doubleArray(maxspect)
    sdfX = doubleArray(maxspect)
    nschanX = intArray(maxspect)
    pgainsX = miriad_io.new_intp()
    sizeX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.uvgnpsld_,(tnoX,maxspectX,ngainsX,nchanX,nspectX,sfreqX,sdfX,nschanX,pgainsX,sizeX))
        del XX
    except :
        pass
    nchanR = miriad_io.intp_value(nchanX)
    nspectR = miriad_io.intp_value(nspectX)
    sfreqR = doubleArrayToList(sfreqX,nspectR)
    del sfreqX
    sdfR = doubleArrayToList(sdfX,nspectR)
    del sdfX
    nschanR = intArrayToList(nschanX,nspectR)
    del nschanX
    pgainsR = miriad_io.intp_value(pgainsX)
    sizeR = miriad_io.intp_value(sizeX)
    return nchanR,nspectR,sfreqR,sdfR,nschanR,pgainsR,sizeR

def uvgnpsrd(tno,dowide,nread,nchan,nfeeds,nants,aver,sfreq,sdf,nschan,ptab,pflags,pdat,ndat,pfreq,nfreq,dotau,dopass) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            dowide -
            nread -
            nchan -
            nfeeds -
            nants -
            aver -
            sfreq -
            sdf -
            nschan -
            ptab -
            pflags -
            pdat -
            ndat -
            pfreq -
            nfreq -
            dotau -
            dopass -
        returns :   (as a tuple)
            pflags -
            pdat -
            ndat -
            pfreq -
            nfreq -
   """
    nspect = len(sfreq)
    tnoX = miriad_io.copy_intp(tno)
    dowideX = miriad_io.copy_intp(uncastLogical(dowide))
    nreadX = miriad_io.copy_intp(nread)
    nchanX = miriad_io.copy_intp(nchan)
    nfeedsX = miriad_io.copy_intp(nfeeds)
    nantsX = miriad_io.copy_intp(nants)
    averX = miriad_io.copy_intp(uncastLogical(aver))
    nspectX = miriad_io.copy_intp(nspect)
    sfreqX = doubleListToArray(sfreq)
    sdfX = doubleListToArray(sdf)
    nschanX = intListToArray(nschan)
    ptabX = miriad_io.copy_intp(ptab)
    pflagsX = miriad_io.copy_intp(pflags)
    pdatX = miriad_io.copy_intp(pdat)
    ndatX = miriad_io.copy_intp(ndat)
    pfreqX = miriad_io.copy_intp(pfreq)
    nfreqX = miriad_io.copy_intp(nfreq)
    dotauX = miriad_io.copy_intp(uncastLogical(dotau))
    dopassX = miriad_io.copy_intp(uncastLogical(dopass))
    try :
        XX = mx.safecall(miriad_io.uvgnpsrd_,(tnoX,dowideX,nreadX,nchanX,nfeedsX,nantsX,averX,nspectX,sfreqX,sdfX,nschanX,ptabX,pflagsX,pdatX,ndatX,pfreqX,nfreqX,dotauX,dopassX))
        del XX
    except :
        pass
    del sfreqX
    del sdfX
    del nschanX
    pflagsR = miriad_io.intp_value(pflagsX)
    pdatR = miriad_io.intp_value(pdatX)
    ndatR = miriad_io.intp_value(ndatX)
    pfreqR = miriad_io.intp_value(pfreqX)
    nfreqR = miriad_io.intp_value(nfreqX)
    return pflagsR,pdatR,ndatR,pfreqR,nfreqR

def uvgnpsfq(nchan,sfreq,sdf,nschan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nchan -
            nspect -
            sfreq -
            sdf -
            nschan -
        returns :   (as a tuple)
            freq -
    """
    nspect = len(nschan)
    nchanX = miriad_io.copy_intp(nchan)
    nspectX = miriad_io.copy_intp(nspect)
    sfreqX = doubleListToArray(sfreq)
    sdfX = doubleListToArray(sdf)
    nschanX = intListToArray(nschan)
    freqX = doubleArray(nchan)
    try :
        XX = mx.safecall(miriad_io.uvgnpsfq_,(nchanX,nspectX,sfreqX,sdfX,nschanX,freqX))
        del XX
    except :
        pass
    del sfreqX
    del sdfX
    del nschanX
    freqR = doubleArrayToList(freqX,nchan)
    del freqX
    return freqR

def uvgnpsgt(tno,dowide,nread,mspect) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno -
            dowide -
            nread -
            mspect -
        returns :   (as a tuple)
            doaver -
            nspect -
            sfreq -
            sdf -
            swidth -
            nschan -
    """
    tnoX = miriad_io.copy_intp(tno)
    dowideX = miriad_io.copy_intp(uncastLogical(dowide))
    nreadX = miriad_io.copy_intp(nread)
    mspectX = miriad_io.copy_intp(mspect)
    doaverX = miriad_io.new_intp()
    nspectX = miriad_io.new_intp()
    sfreqX = doubleArray(mspect)
    sdfX = doubleArray(mspect)
    swidthX = doubleArray(mspect)
    nschanX = intArray(mspect)
    try :
        XX = mx.safecall(miriad_io.uvgnpsgt_,(tnoX,dowideX,nreadX,mspectX,doaverX,nspectX,sfreqX,sdfX,swidthX,nschanX))
        del XX
    except :
        pass
    doaverR = castLogical(miriad_io.intp_value(doaverX))
    nspectR = miriad_io.intp_value(nspectX)
    sfreqR = doubleArrayToList(sfreqX,mspect)
    del sfreqX
    sdfR = doubleArrayToList(sdfX,mspect)
    del sdfX
    swidthR = doubleArrayToList(swidthX,mspect)
    del swidthX
    nschanR = intArrayToList(nschanX,mspect)
    del nschanX
    return doaverR,nspectR,sfreqR,sdfR,swidthR,nschanR

def uvgninic():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvgninic_)
    except :
        pass
    return XX

def uvgniniw():
    """ Miriad wrapper - see miriad documentation for full description
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.uvgniniw_)
    except :
        pass
    return XX

def width(sdf,nschan) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            sdf -
            nschan -
        returns :   (as a tuple)
            wide -
    """
    nspect = len(sdf)
    nspectX = miriad_io.copy_intp(nspect)
    sdfX = doubleListToArray(sdf)
    nschanX = intListToArray(nschan)
    wideX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.width_,(nspectX,sdfX,nschanX,wideX))
        del XX
    except :
        pass
    del sdfX
    del nschanX
    wideR = miriad_io.floatp_value(wideX)
    return wideR

def varinit(tin,linetype) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin -
            linetype -
        returns :   (as a tuple)
    """
    tinX = miriad_io.copy_intp(tin)
    try :
        XX = mx.safecall(miriad_io.varinit_,(tinX,linetype,len(linetype)))
        del XX
    except :
        pass

def varonit(tin,tout,linetype) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin -
            tout -
            linetype -
        returns :   (as a tuple)
    """
    tinX = miriad_io.copy_intp(tin)
    toutX = miriad_io.copy_intp(tout)
    try :
        XX = mx.safecall(miriad_io.varonit_,(tinX,toutX,linetype,len(linetype)))
        del XX
    except :
        pass

def varwinit(tin) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin -
        returns :   (as a tuple)
    """
    tinX = miriad_io.copy_intp(tin)
    try :
        XX = mx.safecall(miriad_io.varwinit_,(tinX,))
        del XX
    except :
        pass

def varcopy(tin,tout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin -
            tout -
        returns :   (as a tuple)
    """
    tinX = miriad_io.copy_intp(tin)
    toutX = miriad_io.copy_intp(tout)
    try :
        XX = mx.safecall(miriad_io.varcopy_,(tinX,toutX))
        del XX
    except :
        pass

def varwide(tvis,tout,lstart,lwidth,lstep,nchan,avall) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            tout -
            lstart -
            lwidth -
            lstep -
            nchan -
            avall -
        returns :   (as a tuple)
    """
    tvisX = miriad_io.copy_intp(tvis)
    toutX = miriad_io.copy_intp(tout)
    lstartX = miriad_io.copy_intp(lstart)
    lwidthX = miriad_io.copy_intp(lwidth)
    lstepX = miriad_io.copy_intp(lstep)
    nchanX = miriad_io.copy_intp(nchan)
    avallX = miriad_io.copy_intp(uncastLogical(avall))
    try :
        XX = mx.safecall(miriad_io.varwide_,(tvisX,toutX,lstartX,lwidthX,lstepX,nchanX,avallX))
        del XX
    except :
        pass

def varchan(tvis,tout,lstart,lwidth,lstep,nchan,avall) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            tout -
            lstart -
            lwidth -
            lstep -
            nchan -
            avall -
        returns :   (as a tuple)
    """
    tvisX = miriad_io.copy_intp(tvis)
    toutX = miriad_io.copy_intp(tout)
    lstartX = miriad_io.copy_intp(lstart)
    lwidthX = miriad_io.copy_intp(lwidth)
    lstepX = miriad_io.copy_intp(lstep)
    nchanX = miriad_io.copy_intp(nchan)
    avallX = miriad_io.copy_intp(uncastLogical(avall))
    try :
        XX = mx.safecall(miriad_io.varchan_,(tvisX,toutX,lstartX,lwidthX,lstepX,nchanX,avallX))
        del XX
    except :
        pass

def varvelo(tvis,tout,lstart,lstep,nchan,win,avall) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            tout -
            lstart -
            lstep -
            nchan -
            win -
            avall -
        returns :   (as a tuple)
    """
    tvisX = miriad_io.copy_intp(tvis)
    toutX = miriad_io.copy_intp(tout)
    lstartX = miriad_io.copy_floatp(lstart)
    lstepX = miriad_io.copy_floatp(lstep)
    nchanX = miriad_io.copy_intp(nchan)
    winX = miriad_io.copy_intp(win)
    avallX = miriad_io.copy_intp(uncastLogical(avall))
    try :
        XX = mx.safecall(miriad_io.varvelo_,(tvisX,toutX,lstartX,lstepX,nchanX,winX,avallX))
        del XX
    except :
        pass

def varavall(tvis,doav) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            doav -
        returns :   (as a tuple)
    """
    tvisX = miriad_io.copy_intp(tvis)
    doavX = miriad_io.copy_intp(uncastLogical(doav))
    try :
        XX = mx.safecall(miriad_io.varavall_,(tvisX,doavX))
        del XX
    except :
        pass

def varmintd(tvis,var) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            var -
        returns :   (as a tuple)
            value -
    """
    tvisX = miriad_io.copy_intp(tvis)
    valueX = miriad_io.new_doublep()
    try :
        XX = mx.safecall(miriad_io.varmintd_,(tvisX,var,valueX,len(var)))
        del XX
    except :
        pass
    valueR = miriad_io.doublep_value(valueX)
    return var,valueR

def varmintr(tvis,var) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tvis -
            var -
        returns :   (as a tuple)
            value -
    """
    tvisX = miriad_io.copy_intp(tvis)
    valueX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.varmintr_,(tvisX,var,valueX,len(var)))
        del XX
    except :
        pass
    valueR = miriad_io.floatp_value(valueX)
    return var,valueR

def vearth(jday) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            jday -
        returns :   (as a tuple)
            pos -
            vel -
    """
    jdayX = miriad_io.copy_doublep(jday)
    posX = doubleArray(3)
    velX = doubleArray(3)
    try :
        XX = mx.safecall(miriad_io.vearth_,(jdayX,posX,velX))
        del XX
    except :
        pass
    posR = doubleArrayToList(posX,3)
    del posX
    velR = doubleArrayToList(velX,3)
    del velX
    return posR,velR

def vsite(phi,st) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            phi -
            st -
        returns :   (as a tuple)
            vel -
    """
    phiX = miriad_io.copy_doublep(phi)
    stX = miriad_io.copy_doublep(st)
    velX = doubleArray(3)
    try :
        XX = mx.safecall(miriad_io.vsite_,(phiX,stX,velX))
        del XX
    except :
        pass
    velR = doubleArrayToList(velX,3)
    del velX
    return velR

def vsun() :
    """ Miriad wrapper - see miriad documentation for full description
        input :
        returns :   (as a tuple)
            vel -
    """
    velX = doubleArray(3)
    try :
        XX = mx.safecall(miriad_io.vsun_,(velX,))
        del XX
    except :
        pass
    velR = doubleArrayToList(velX,3)
    del velX
    return velR

def wpfit(nd,x,y,w,phi,phix) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            nd -
            x -
            y -
            w -
            phi -
            phix -
        returns :   (as a tuple)
            a -
            rnorm -
            ierr -
    """
    np = len(x)
    ndX = miriad_io.copy_intp(nd)
    npX = miriad_io.copy_intp(np)
    xX = floatListToArray(x)
    yX = floatListToArray(y)
    wX = floatListToArray(w)
    aX = floatArray(nd+1)
    rnormX = miriad_io.new_floatp()
    phiX = floatListToArray(phi)
    phixX = floatListToArray(phix)
    ierrX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.wpfit_,(ndX,npX,xX,yX,wX,aX,rnormX,phiX,phixX,ierrX))
        del XX
    except :
        pass
    del xX
    del yX
    del wX
    aR = floatArrayToList(aX,nd+1)
    del aX
    rnormR = miriad_io.floatp_value(rnormX)
    del phiX
    del phixX
    ierrR = miriad_io.intp_value(ierrX)
    return aR,rnormR,ierrR

def zedscale(luni,freq) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            luni -
            freq -
        returns :   (as a tuple)
            scale -
            noline -
    """
    luniX = miriad_io.copy_intp(luni)
    freqX = miriad_io.copy_floatp(freq)
    scaleX = miriad_io.new_floatp()
    nolineX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.zedscale_,(luniX,freqX,scaleX,nolineX))
        del XX
    except :
        pass
    scaleR = miriad_io.floatp_value(scaleX)
    nolineR = miriad_io.intp_value(nolineX)
    return scaleR,nolineR

def zed(mode,ispect,vspect,m,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ispect -
            vspect -
            m -
            n -
        returns :   (as a tuple)
            a -
            b -
            siga -
            sigb -
            sigi -
            convrg -
    """
    ispectX = miriad_io.copy_floatp(ispect)
    vspectX = miriad_io.copy_floatp(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    sigaX = miriad_io.new_floatp()
    sigbX = miriad_io.new_floatp()
    sigiX = miriad_io.new_floatp()
    convrgX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.zed_,(mode,ispectX,vspectX,mX,nX,aX,bX,sigaX,sigbX,sigiX,convrgX,len(mode)))
        del XX
    except :
        pass
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    sigaR = miriad_io.floatp_value(sigaX)
    sigbR = miriad_io.floatp_value(sigbX)
    sigiR = miriad_io.floatp_value(sigiX)
    convrgR = miriad_io.intp_value(convrgX)
    return aR,bR,sigaR,sigbR,sigiR,convrgR

def zeddelsq(ispect,m,n,a,siga,sigi,delta) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ispect -
            m -
            n -
            a -
            siga -
            sigi -
            delta -
        returns :   (as a tuple)
            a -
            siga -
            convrg -
    """
    ispectX = floatListToArray(ispect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.copy_floatp(a)
    sigaX = miriad_io.copy_floatp(siga)
    sigiX = miriad_io.copy_floatp(sigi)
    deltaX = miriad_io.copy_intp(delta)
    convrgX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.zeddelsq_,(ispectX,mX,nX,aX,sigaX,sigiX,deltaX,convrgX))
        del XX
    except :
        pass
    del ispectX
    aR = miriad_io.floatp_value(aX)
    sigaR = miriad_io.floatp_value(sigaX)
    convrgR = castLogical(miriad_io.intp_value(convrgX))
    return aR,sigaR,convrgR

def zedihat(mode,ispect,vspect,m,n,a,b) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ispect -
            vspect -
            m -
            n -
            a -
            b -
        returns :   (as a tuple)
            ihat -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    ihatX = floatArray(m,n)
    try :
        XX = mx.safecall(miriad_io.zedihat_,(mode,ispectX,vspectX,mX,nX,aX,bX,ihatX,len(mode)))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    ihatR = floatArrayToList(ihatX,m,n)
    del ihatX
    return ihatR

def zedvhat(mode,ihat,m,n,a,b) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ihat -
            m -
            n -
            a -
            b -
        returns :   (as a tuple)
            vhat -
    """
    ihatX = floatListToArray(ihat)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    vhatX = floatArray(m,n)
    try :
        XX = mx.safecall(miriad_io.zedvhat_,(mode,ihatX,mX,nX,aX,bX,vhatX,len(mode)))
        del XX
    except :
        pass
    del ihatX
    vhatR = floatArrayToList(vhatX,m,n)
    del vhatX
    return vhatR

def zedfunc(mode,ispect,vspect,m,n,a,b) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ispect -
            vspect -
            m -
            n -
            a -
            b -
        returns :   (as a tuple)
            sigi -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    sigiX = miriad_io.new_floatp()
    try :
        XX = mx.safecall(miriad_io.zedfunc_,(mode,ispectX,vspectX,mX,nX,aX,bX,sigiX,len(mode)))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    sigiR = miriad_io.floatp_value(sigiX)
    return sigiR

def zedlsq(ispect,vspect,m,n,leak,delta) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ispect -
            vspect -
            m -
            n -
            leak -
            delta -
        returns :   (as a tuple)
            a -
            b -
            siga -
            sigb -
            sigi -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    sigaX = miriad_io.new_floatp()
    sigbX = miriad_io.new_floatp()
    sigiX = miriad_io.new_floatp()
    leakX = miriad_io.copy_intp(uncastLogical(leak))
    deltaX = miriad_io.copy_intp(delta)
    try :
        XX = mx.safecall(miriad_io.zedlsq_,(ispectX,vspectX,mX,nX,aX,bX,sigaX,sigbX,sigiX,leakX,deltaX))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    sigaR = miriad_io.floatp_value(sigaX)
    sigbR = miriad_io.floatp_value(sigbX)
    sigiR = miriad_io.floatp_value(sigiX)
    return aR,bR,sigaR,sigbR,sigiR

def zedml(ispect,vspect,m,n,leak,delta) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ispect -
            vspect -
            m -
            n -
            leak -
            delta -
        returns :   (as a tuple)
            a -
            b -
            siga -
            sigb -
            sigi -
            convrg -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    sigaX = miriad_io.new_floatp()
    sigbX = miriad_io.new_floatp()
    sigiX = miriad_io.new_floatp()
    leakX = miriad_io.copy_intp(uncastLogical(leak))
    deltaX = miriad_io.copy_intp(delta)
    convrgX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.zedml_,(ispectX,vspectX,mX,nX,aX,bX,sigaX,sigbX,sigiX,leakX,deltaX,convrgX))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    sigaR = miriad_io.floatp_value(sigaX)
    sigbR = miriad_io.floatp_value(sigbX)
    sigiR = miriad_io.floatp_value(sigiX)
    convrgR = castLogical(miriad_io.intp_value(convrgX))
    return aR,bR,sigaR,sigbR,sigiR,convrgR

def zed1(ispect,vspect,a,b) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ispect -
            vspect -
            a -
            b -
        returns :   (as a tuple)
            i0 -
    """
    n = len(ispect)
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    nX = miriad_io.copy_intp(n)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    i0X = floatArray(n)
    try :
        XX = mx.safecall(miriad_io.zed1_,(ispectX,vspectX,nX,aX,bX,i0X))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    i0R = floatArrayToList(i0X,n)
    del i0X
    return i0R

def zedfudge(mode,ispect,vspect,m,n1,n2,a,b,rho,beam,nx,ny) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ispect -
            vspect -
            m -
            n1 -
            n2 -
            a -
            b -
            rho -
            beam -
            nx -
            ny -
        returns :   (as a tuple)
            fudge -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    fudgeX = miriad_io.new_floatp()
    rhoX = miriad_io.copy_floatp(rho)
    beamX = floatListToArray(beam)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    try :
        XX = mx.safecall(miriad_io.zedfudge_,(mode,ispectX,vspectX,mX,n1X,n2X,aX,bX,fudgeX,rhoX,beamX,nxX,nyX,len(mode)))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    fudgeR = miriad_io.floatp_value(fudgeX)
    del beamX
    return fudgeR

def zeddi(ispect,vspect,a,b,m,md,n1,n2,n,delta) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            ispect -
            vspect -
            a -
            b -
            m -
            md -
            n1 -
            n2 -
            n -
            delta -
        returns :   (as a tuple)
            di -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    aX = miriad_io.copy_floatp(a)
    bX = miriad_io.copy_floatp(b)
    diX = floatArray(md,n1*n2)
    mX = miriad_io.copy_intp(m)
    mdX = miriad_io.copy_intp(md)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    nX = miriad_io.copy_intp(n)
    deltaX = miriad_io.copy_intp(delta)
    try :
        XX = mx.safecall(miriad_io.zeddi_,(ispectX,vspectX,aX,bX,diX,mX,mdX,n1X,n2X,nX,deltaX))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    diR = floatArrayToList(diX,md,n1*n2)
    del diX
    return diR

def zedxyapp(di,md,n,a) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            di -
            md -
            n -
            a -
        returns :   (as a tuple)
            di -
    """
    diX = floatListToArray(di)
    mdX = miriad_io.copy_intp(md)
    nX = miriad_io.copy_intp(n)
    aX = floatListToArray(a)
    try :
        XX = mx.safecall(miriad_io.zedxyapp_,(diX,mdX,nX,aX))
        del XX
    except :
        pass
    diR = floatArrayToList(diX,md,n)
    del diX
    del aX
    return diR

def zedfapp(di,md,n,gamma,rho) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            di -
            md -
            n -
            gamma -
            rho -
        returns :   (as a tuple)
            di -
    """
    diX = floatListToArray(di)
    mdX = miriad_io.copy_intp(md)
    nX = miriad_io.copy_intp(n)
    gammaX = floatListToArray(gamma)
    rhoX = miriad_io.copy_floatp(rho)
    try :
        XX = mx.safecall(miriad_io.zedfapp_,(diX,mdX,nX,gammaX,rhoX))
        del XX
    except :
        pass
    diR = floatArrayToList(diX,md,n)
    del diX
    del gammaX
    return diR

def zedfcov(md,rho) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            md -
            rho -
        returns :   (as a tuple)
            gamma -
    """
    gammaX = floatArray(md)
    mdX = miriad_io.copy_intp(md)
    rhoX = miriad_io.copy_floatp(rho)
    try :
        XX = mx.safecall(miriad_io.zedfcov_,(gammaX,mdX,rhoX))
        del XX
    except :
        pass
    gammaR = floatArrayToList(gammaX,md)
    del gammaX
    return gammaR

def zedxycov(n1,n2,beam,nx,ny) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            n1 -
            n2 -
            beam -
            nx -
            ny -
        returns :   (as a tuple)
            a -
    """
    aX = floatArray(n1*n2*(n1*n2+1)/2)
    n1X = miriad_io.copy_intp(n1)
    n2X = miriad_io.copy_intp(n2)
    beamX = floatListToArray(beam)
    nxX = miriad_io.copy_intp(nx)
    nyX = miriad_io.copy_intp(ny)
    try :
        XX = mx.safecall(miriad_io.zedxycov_,(aX,n1X,n2X,beamX,nxX,nyX))
        del XX
    except :
        pass
    aR = floatArrayToList(aX,n1*n2*(n1*n2+1)/2)
    del aX
    del beamX
    return aR

def zedrho(mode,ispect,vspect,m,n,rho) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            mode -
            ispect -
            vspect -
            m -
            n -
            rho -
        returns :   (as a tuple)
            a -
            b -
            siga -
            sigb -
            sigi -
            convrg -
    """
    ispectX = floatListToArray(ispect)
    vspectX = floatListToArray(vspect)
    mX = miriad_io.copy_intp(m)
    nX = miriad_io.copy_intp(n)
    rhoX = miriad_io.copy_floatp(rho)
    aX = miriad_io.new_floatp()
    bX = miriad_io.new_floatp()
    sigaX = miriad_io.new_floatp()
    sigbX = miriad_io.new_floatp()
    sigiX = miriad_io.new_floatp()
    convrgX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.zedrho_,(mode,ispectX,vspectX,mX,nX,rhoX,aX,bX,sigaX,sigbX,sigiX,convrgX,len(mode)))
        del XX
    except :
        pass
    del ispectX
    del vspectX
    aR = miriad_io.floatp_value(aX)
    bR = miriad_io.floatp_value(bX)
    sigaR = miriad_io.floatp_value(sigaX)
    sigbR = miriad_io.floatp_value(sigbX)
    sigiR = miriad_io.floatp_value(sigiX)
    convrgR = castLogical(miriad_io.intp_value(convrgX))
    return aR,bR,sigaR,sigbR,sigiR,convrgR

def zedrdr(x,rho) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            rho -
        returns :   (as a tuple)
            x -
    """
    n = len(x)
    xX = floatListToArray(x)
    nX = miriad_io.copy_intp(n)
    rhoX = miriad_io.copy_floatp(rho)
    try :
        XX = mx.safecall(miriad_io.zedrdr_,(xX,nX,rhoX))
        del XX
    except :
        pass
    xR = floatArrayToList(xX,n)
    del xX
    return xR

def zedr(x,rho) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            x -
            rho -
        returns :   (as a tuple)
            x -
    """
    n = len(x)
    xX = miriad_io.copy_floatp(x)
    nX = miriad_io.copy_intp(n)
    rhoX = miriad_io.copy_floatp(rho)
    try :
        XX = mx.safecall(miriad_io.zedr_,(xX,nX,rhoX))
        del XX
    except :
        pass
    xR =  floatArrayToList(xX,n)
    del xX
    return xR

def binfid(iwin,aveop,size,axis,bin,blc,trc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            iwin -
            aveop -
            size -
            axis -
            bin -
            blc -
            trc -
        returns :   (as a tuple)
            bin -
            blc -
            trc -
            nbin -
    """
    iwinX = miriad_io.copy_intp(iwin)
    sizeX = miriad_io.copy_intp(size)
    axisX = miriad_io.copy_intp(axis)
    binX = miriad_io.copy_intp(bin)
    blcX = miriad_io.copy_intp(blc)
    trcX = miriad_io.copy_intp(trc)
    nbinX = miriad_io.new_intp()
    try :
        XX = mx.safecall(miriad_io.binfid_,(iwinX,aveop,sizeX,axisX,binX,blcX,trcX,nbinX,1))
        del XX
    except :
        pass
    binR =  miriad_io.intp_value(binX)
    blcR =  miriad_io.intp_value(blcX)
    trcR =  miriad_io.intp_value(trcX)
    nbinR = miriad_io.intp_value(nbinX)
    return binR,blcR,trcR,nbinR

def binrd2(h1,h2,bin,blc,trc,nbin,row,data1,data2) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            h1 -
            h2 -
            bin -
            blc -
            trc -
            nbin -
            row -
            data1 -
            data2 -
        returns :   (as a tuple)
            row -
            data1 -
            data2 -
    """
    h1X = miriad_io.copy_intp(h1)
    h2X = miriad_io.copy_intp(h2)
    binX = intListToArray(bin)
    blcX = intListToArray(blc)
    trcX = intListToArray(trc)
    nbinX = intListToArray(nbin)
    l1 = len(row)
    rowX = floatListToArray(row)
    ld1 = len(data1)
    data1X = floatListToArray(data1)
    ld2 = len(data2)
    data2X = floatListToArray(data2)
    try :
        XX = mx.safecall(miriad_io.binrd2_,(h1X,h2X,binX,blcX,trcX,nbinX,rowX,data1X,data2X))
        del XX
    except :
        pass
    del binX
    del blcX
    del trcX
    del nbinX
    rowR = floatArrayToList(rowX,l1)
    del rowX
    data1R = floatArrayToList(data1X,ld1)
    del data1X
    data2R = floatArrayToList(data2X,ld2)
    del data2X
    return rowR,data1R,data2R

def binup(data,blc,trc,bin,norm,ipt,binned,wrt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            data -
            blc -
            trc -
            bin -
            norm -
            ipt -
            binned -
            wrt -
        returns :   (as a tuple)
            ipt -
            binned -
    """
    dataX = floatListToArray(data)
    blcX = miriad_io.copy_intp(blc)
    trcX = miriad_io.copy_intp(trc)
    binX = miriad_io.copy_intp(bin)
    normX = miriad_io.copy_floatp(norm)
    iptX = miriad_io.copy_intp(ipt)
    l = len(binned)
    binnedX = floatListToArray(binned)
    wrtX = miriad_io.copy_intp(uncastLogical(wrt))
    try :
        XX = mx.safecall(miriad_io.binup_,(dataX,blcX,trcX,binX,normX,iptX,binnedX,wrtX))
        del XX
    except :
        pass
    del dataX
    iptR =  miriad_io.intp_value(iptX)
    binnedR = floatArrayToList(binnedX,l)
    del binnedX
    return iptR,binnedR

# The following are wrappers for the functions defined in C

def scropen() :
    """ Miriad wrapper - see miriad documentation for full description
        returns :
            handle to the scratch file
    """
    handle = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.scropen_c,(handle,))
    except :
        pass
    h = miriad_io.intp_value(handle)
    return h

def scrclose(handle) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the handle to the scratch file
    """
    try :
        mx.safecall(miriad_io.scrclose_c,(handle,))
    except :
        pass

def scrread(handle,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the handle to the scratch file
            offset - offset bytes
            length - length on bytes
        returns :
            the buffre from the given location
    """
    bufferX = miriad_io.floatArray(length)
    try :
        mx.safecall(miriad_io.scrread_c,(handle,bufferX,offset,length))
    except :
        pass
    b = doubleArrayToList(bufferX,length)
    del bufferX
    return b

def scrwrite(handle,bufferX,offset) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the handle to the scratch file
            bufferX - the value to write
            offset - offset bytes
    """
    b = floatListToArray(bufferX)
    try :
        mx.safecall(miriad_io.scrwrite_c,(handle,b,offset,len(b)))
    except :
        pass
    del b

def uvopen(name, status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name - the name of the miriad file
            status - "old" or "new"
        returns :
            the handle to the file
    """
    tno = miriad_io.new_intp()
    try :
        print "start call again"
        mx.safecall(miriad_io.uvopen_c, (tno, name, status))
        #miriad_io.uvopen_c(tno,miriad_io.zterm(name,len(name)),miriad_io.zterm(status,len(status)))
        print "end call"
    except :
        pass
    t = miriad_io.intp_value(tno)
    return t

def uvtrack(tno,name,switches) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle to the miriad file
            name - name of the variable
            switches - "u" and/or "c"
    """
    try :
        mx.safecall(miriad_io.uvtrack_c,(tno,name,switches))
        #mx.safecall(miriad_io.uvtrack_c,(tno,miriad_io.zterm(name,len(name)),miriad_io.zterm(switches,len(switches))))
    except :
        pass

def uvcopyvr(tin,tout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin - handle to the input file
            tout - handle to the output file
    """
    try :
        mx.safecall(miriad_io.uvcopyvr_c,(tin,tout))
    except :
        pass

def uvvarini(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tin - handle to the miriad file
        returns :
            handle to the variable list
    """
    handle = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.uvvarini_c,(tno,handle))
    except :
        pass
    h = miriad_io.intp_value(handle)
    return h

def uvvarset(handle,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the variable handle
            name - the variable name
    """
    #try :
    mx.safecall(miriad_io.uvvarset_c,(handle,name))
    #mx.safecall(miriad_io.uvvarset_c,(handle,miriad_io.zterm(name,len(name))))
    #except :
    #   pass

def uvvarcpy(handle,tout) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the variable handle
            name - the variable name
    """
    try :
        mx.safecall(miriad_io.uvvarcpy_c,(handle,tout))
    except :
        pass

def uvvarupd(handle) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            handle - the variable handle
    """
    #XX = None
    print "XXXX1"
    #try :
    return castLogical(mx.safecall(miriad_io.uvvarupd_c,(handle,)))
    #print XX
    #except :
    #    pass
    #time.sleep(2)
    #print "YYYY1"
    #if(XX > 0) :
    #    print "PASS"
    #    return True
    #print "FAIL"
    #return False
    #return castLogical(XX)

def uvflush(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
    """
    try :
        mx.safecall(miriad_io.uvflush_c,(tno,))
    except :
        pass

def uvclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
    """
    try :
        mx.safecall(miriad_io.uvclose_c,(tno,))
    except :
        pass

def uvupdate(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
    """
    result = -1
    try :
        result = mx.safecall(miriad_io.uvupdate_c,(tno,))
    except :
        pass
    return castLogical(result)

def uvnext(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
    """
    try :
        mx.safecall(miriad_io.uvnext_c,(tno,))
    except :
        pass

def uvscan(tno,var) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            var - the variable name
        returns :
            0/-1/NUM - success/EOF/error
    """
    result = -1
    try :
        result = mx.safecall( miriad_io.uvscan_c,(tno,var))
        #result = mx.safecall( miriad_io.uvscan_c,(tno,miriad_io.zterm(var,len(var))))
    except :
        pass
    return result

def uvrewind(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
    """
    try :
        mx.safecall(miriad_io.uvrewind_c,(tno,))
    except :
        pass

def uvread(tno,n = MAXCHAN) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            n - maximum number of channels to read (default is 4096)
        returns :
            a tuple of preamble (list),complex data(list), and channel flags (list)
    """
    preamble = miriad_io.doubleArray(10)
    data = miriad_io.floatArray(2*n)
    flags = miriad_io.intArray(n)
    nread = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.uvread_c,(tno,preamble,data,flags,n,nread))
    except :
        pass
    nr = miriad_io.intp_value(nread)
    p = doubleArrayToList(preamble,10)
    d = complexArrayToList(data,2*nr)
    f = castLogical(intArrayToList(flags,nr))
    del preamble
    del data
    del flags
    return p,d,f

def uvwread(tno,n = MAXCHAN) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            n - maximum number of channels to read (default is 4096)
        returns :
            a tuple of the complex data (list) and channel flags (list)
    """
    data = miriad_io.floatArray(2*n)
    flags = miriad_io.intArray(n)
    nread = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.uvwread_c,(tno,data,flags,n,nread))
    except :
        pass
    nr = miriad_io.intp_value(nread)
    d = complexArrayToList(data,2*nr)
    f = castLogical(intArrayToList(flags,nr))
    del data
    del flags
    return d,f

def uvflgwr(tno,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            flags - a logical array with nread (from last uvread call) values
    """
    f = intListToArray(uncastLogical(flags))
    try :
        mx.safecall(miriad_io.uvflgwr_c,(tno,f))
    except :
        pass
    del f

def uvwflgwr(tno,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            flags - a logical array with nread (from last uvwread call) values
    """
    f = intListToArray(uncastLogical(flags))
    try :
        mx.safecall(miriad_io.uvwflgwr_c,(tno,f))
    except :
        pass
    del f

def uvset(tno,objt,typeX,n,p1,p2,p3) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            objt - the name of the objt being set
            typeX - the typeX of data
            n - an integer parameter
            p1,p2,p3 - float parameters
    """
    try :
        mx.safecall(miriad_io.uvset_c,(tno,objt,typeX,n,p1,p2,p3))
        #mx.safecall(miriad_io.uvset_c,(tno,miriad_io.zterm(objt,len(objt)),miriad_io.zterm(typeX,len(typeX)),n,p1,p2,p3))
    except :
        pass

def uvselect(tno,objt,p1,p2,datasel) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            objt - the name of the objt being set
            p1,p2 - range of values to select data upon
            datasel - select/disregard data
    """
    try :
        mx.safecall(miriad_io.uvselect_c,(tno,objt,p1,p2,uncastLogical(datasel)))
        #mx.safecall(miriad_io.uvselect_c,(tno,miriad_io.zterm(objt,len(objt)),p1,p2,uncastLogical(datasel)))
    except :
        pass

def uvsela(tno,objt,string,datasel) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            objt - the name of the object being set
            string - string value to select upon
            datasel - select/disregard data
    """
    try :mx.safecall(miriad_io.uvsela_c,(tno,objt,string,uncastLogical(datasel)))
        
        #mx.safecall(miriad_io.uvsela_c,(tno,miriad_io.zterm(objt,len(objt)),miriad_io.zterm(string,len(string)),uncastLogical(datasel)))
    except :
        pass

def uvinfo(tno,objt) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            objt - what info to return
        returns :
            list containing the requested data
    """
    data = miriad_io.doubleArray(1000)
    try :
        mx.safecall(miriad_io.uvinfo_c,(tno,objt,data))
        #mx.safecall(miriad_io.uvinfo_c,(tno,miriad_io.zterm(objt,len(objt)),data))
    except :
        pass
    d = doubleArrayToList(data,1000)
    del data
    return d

def uvwrite(tno,preamble,data,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            preamble - list of 4 floats (standard miriad preamble)
            data - complex list of uv data
            flags - list of logical values for each channel
    """
    p = doubleListToArray(preamble)
    d = complexListToArray(data)
    f = intListToArray(uncastLogical(flags))
    try :
        mx.safecall(miriad_io.uvwrite_c,(tno,p,d,f,len(flags)))
    except :
        pass
    del p
    del d
    del f

def uvwwrite(tno,data,flags) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            data - complex list of uv data
            flags - list of logical values for each channel
    """
    d = complexListToArray(data)
    f = intListToArray(uncastLogical(flags))
    try :
        mx.safecall(miriad_io.uvwwrite_c,(tno,d,f,len(flags)))
    except :
        pass
    del d
    del f

def uvprobvr(tno,var) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the miriad file handle
            var - the name of the variable
        returns :
            a tuple containing the type, length of variable, and whether it has been updated (logical)
    """
    typeX = " "
    length = miriad_io.new_intp()
    updated = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.uvprobvr_c,(tno,var,typeX,length,updated))
        #mx.safecall(miriad_io.uvprobvr_c,(tno,miriad_io.zterm(var,len(var)),typeX,length,updated))
    except :
        pass
    l = miriad_io.intp_value(length)
    u = castLogical(miriad_io.intp_value(updated))
    typeX = typeX.strip()
    return typeX,l,u

def uvrdvra(tno,var,default = "") :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            default - default value (defaults to "")
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    cdata = "                    "
    try :
        mx.safecall(miriad_io.uvrdvra_,(t,var,cdata,default,len(var),18,len(default)))
    except :
        pass
    cdata = cdata.strip()
    return cdata

def uvrdvri(tno,var,default = 0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            default - default value (defaults to 0)
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.new_intp()
    defaultX = miriad_io.copy_intp(default)
    #try :
    mx.safecall(miriad_io.uvrdvri_,(t,var,data,defaultX,len(var)))
    #except :
    #    pass
    d = miriad_io.intp_value(data)
    return d

def uvrdvrr(tno,var,default = 0.0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            default - default value (defaults to "")
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.new_floatp()
    defaultX = miriad_io.copy_floatp(default)
    try :
        mx.safecall(miriad_io.uvrdvrr_,(t,var,data,defaultX,len(var)))
    except :
        pass
    d = miriad_io.floatp_value(data)
    return d

def uvrdvrd(tno,var,default = 0.0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            default - default value (defaults to 0.0)
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.new_doublep()
    try :
        mx.safecall(miriad_io.uvrdvrd_,(t,var,data,default,len(var)))
    except :
        pass
    d = miriad_io.doublep_value(data)
    return data

def uvrdvrc(tno,var,default = complex(0.0,0.0)) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            default - default value (defaults to 0.0+0.0j)
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.new_floatp()
    try :
        mx.safecall(miriad_io.uvrdvrc_,(t,var,data,default,len(var)))
    except :
        pass
    d = miriad_io.floatp_value(data)
    return d

def uvgetvra(tno,var) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
        returns :
            the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = "                    "
    try :
        mx.safecall(miriad_io.uvgetvra_,(t,var,data,len(var),18))
    except :
        pass
    data = data.strip()
    return data

def uvgetvri(tno,var,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            n - the number of elements to return
        returns :
            an array containgin the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = None
    if(n == 1) :
        data = miriad_io.new_intp()
    else :
        data = miriad_io.intArray(n)
    n1 = miriad_io.copy_intp(n)
    #try :
    mx.safecall(miriad_io.uvgetvri_,(t,var,data,n1,len(var)))
    #except :
    #    pass
    d = None
    if(n == 1) :
        d = miriad_io.intp_value(data)
    else :
        d = intArrayToList(data,n)
        del data
    return d

def uvgetvrj(tno,var,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            n - the number of elements to return
        returns :
            an array containgin the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.intArray(n)
    n1 = miriad_io.copy_intp(n)
    try :
        mx.safecall(miriad_io.uvgetvrj_,(t,var,data,n1,len(var)))
    except :
        pass
    d = intArrayToList(data,n)
    del data
    return d

def uvgetvrr(tno,var,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            n - the number of elements to return
        returns :
            an array containgin the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.floatArray(n)
    n1 = miriad_io.copy_intp(n)
    try :
        mx.safecall(miriad_io.uvgetvrr_,(t,var,data,n1,len(var)))
    except :
        pass
    d = doubleArrayToList(data,n)
    del data
    return d

def uvgetvrd(tno,var,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            n - the number of elements to return
        returns :
            an array containgin the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.doubleArray(n)
    n1 = miriad_io.copy_intp(n)
    try :
        mx.safecall(miriad_io.uvgetvrd_,(t,var,data,n1,len(var)))
    except :
        pass
    d = doubleArrayToList(data,n)
    del data
    return d

def uvgetvrc(tno,var,n) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            n - the number of elements to return
        returns :
            an array containgin the value of the variable
    """
    t = miriad_io.copy_intp(tno)
    data = miriad_io.floatArray(2*n)
    n1 = miriad_io.copy_intp(n)
    try :
        mx.safecall(miriad_io.uvgetvrc_,(t,var,data,n1,len(var)))
    except :
        pass
    d = complexArrayToList(data,2*n)
    del data
    return d

def uvputvri(tno,var,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            data - the data to be written
    """
    t = miriad_io.copy_intp(tno)
    d = intListToArray(data)
    n = miriad_io.copy_intp(len(data))
    try :
        mx.safecall(miriad_io.uvputvri_,(tno,var,d,n,len(var)))
    except :
        pass
    del d

def uvputvrr(tno,var,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            data - the data to be written
    """
    t = miriad_io.copy_intp(tno)
    d = floatListToArray(data)
    n = miriad_io.copy_intp(len(data))
    try :
        mx.safecall(miriad_io.uvputvrr_,(tno,var,d,n,len(var)))
    except :
        pass
    del d

def uvputvrd(tno,var,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            data - the data to be written
    """
    t = miriad_io.copy_intp(tno)
    d = doubleListToArray(data)
    n = miriad_io.copy_intp(len(data))
    try :
        mx.safecall(miriad_io.uvputvri_,(tno,var,d,n,len(var)))
    except :
        pass
    del d

def uvputvrc(tno,var,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            data - the data to be written
    """
    t = miriad_io.copy_intp(tno)
    d = complexListToArray(data)
    n = miriad_io.copy_intp(len(data))
    try :
        mx.safecall(miriad_io.uvputvri_,(tno,var,d,n,len(var)))
    except :
        pass
    del d

def uvputvra(tno,var,data) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - miriad file handle
            var - name of the variable to read
            data - the data to be written
    """
    t = miriad_io.copy_intp(tno)
    n = miriad_io.copy_intp(len(data))
    try :
        mx.safecall(miriad_io.uvputvri_,(tno,var,data,len(var),len(data)))
    except :
        pass

def hopen(name,status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name - name of the miriad data set to open
            status - "old" or "new"
        returns :
            a tuple containing the handle to the data set and the iostatus
    """
    tno = miriad_io.new_intp()
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hopen_c,(tno,name,status,iostat))
        #mx.safecall(miriad_io.hopen_c,(tno,miriad_io.zterm(name,len(name)),miriad_io.zterm(status,len(status)),iostat))
    except :
        pass
    t = miriad_io.intp_value(tno)
    i = miriad_io.intp_value(iostat)
    return t,i

def hclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle to the miriad data
    """
    try :
        mx.safecall(miriad_io.hclose_c,(tno,))
    except :
        pass

def hflush(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data
        returns :
            the iostatus
    """
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hflush_c,(tno,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    return i

def habort() :
    """ Miriad wrapper - see miriad documentation for full description
    """
    try :
        mx.safecall(miriad_io.habort_c)
    except :
        pass

def hrm(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
    """
    try :
        mx.safecall(miriad_io.hrm_c,(tno,))
    except :
        pass

def hdelete(tno,name) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
            name - the name of the item to delete
        returns :
            the iostatus
    """
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hdelete_c,(tno,name,iostat))
        #mx.safecall(miriad_io.hdelete_c,(tno,miriad_io.zterm(name,len(name)),iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    return i

def haccess(tno,name,status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the data set
            name - name of the item
            status - either "read", "write", "append", or "scratch"
        returns :
            the item
            the iostatus
    """
    iostat = miriad_io.new_intp()
    item = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.haccess_c,(tno,item,name,status,iostat))
        #mx.safecall(miriad_io.haccess_c,(tno,item,miriad_io.zterm(name,len(name)),miriad_io.zterm(status,len(status)),iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    it = miriad_io.intp_value(item)
    return it,i

def hmode(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
        returns :
            "", "r", or "rw"
    """
    mode = "   "
    try :
        mx.safecall(miriad_io.hmode_c,(tno,mode))
    except :
        pass
    mode = mode.strip()
    return mode

def hexists(tno,item) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
            item - the name of the item
        returns :
            True or False
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.hexists_c,(tno,item))
        #XX = mx.safecall(miriad_io.hexists_c,(tno,miriad_io.zterm(item,len(item))))
    except :
        pass
    return castLogical(XX)

def hdaccess(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
    """
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hdaccess_c,(tno,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    return i

def hsize(item) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - the handle of the item
        returns :
            the size of the item in bytes
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.hsize_c,(item,))
    except :
        pass
    return XX

def htell(item) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - the handle of the item
        returns :
            current offset of the item
    """
    try :
        mx.safecall(miriad_io.htell_c,(item,))
    except :
        pass

def hseek(item,offset) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle of the item
            offset - the new offset value
    """
    try :
        mx.safecall(miriad_io.hseek_c,(item,offset))
    except :
        pass

def hreada(item) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    line = "                                                                                                      "
    try :
        mx.safecall(miriad_io.hreada_c,(item,line,100,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    line = line.strip()
    return line,i

def hwritea(item,line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            line - what to write
        returns :
            the  iostat
    """
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hwritea_c,(item,line,len(line)+1,iostat))
        #mx.safecall(miriad_io.hwritea_c,(item,miriad_io.zterm(line,len(line)),len(line)+1,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    return i

def hreadb(item,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            offset - the offset of the item
            length - the length of the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    bufferX = "                                                                 "
    try :
        mx.safecall(miriad_io.hreadb_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    bufferX = bufferX.strip()
    return bufferX,i

def hwriteb(item,bufferX,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            bufferX - the value to write
            offset - the offset of the item
            length - the length of the item
        returns :
            the iostat
    """
    iostat = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hwriteb_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    return i

def hreadj(item,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            offset - the offset of the item
            length - the length of the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    bufferX = miriad_io.intArray(length/2)
    try :
        mx.safecall(miriad_io.hreadj_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    c = intArrayToList(bufferX,length/2)
    i = miriad_io.intp_value(iostat)
    del(bufferX)
    return c,i

def hwritej(item,bufferX,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            bufferX - the value to write
            offset - the offset of the item
            length - the length of the item
        returns :
            the iostat
    """
    iostat = miriad_io.new_intp()
    b = intListToArray(bufferX)
    try :
        mx.safecall(miriad_io.hwritej_c,(item,b,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    del b
    return i

def hreadi(item,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            offset - the offset of the item
            length - the length of the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    bufferX = miriad_io.intArray(length/4)
    try :
        mx.safecall(miriad_io.hreadi_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    c = intArrayToList(bufferX,length/4)
    i = miriad_io.intp_value(iostat)
    del bufferX
    return c,i

def hwritei(item,bufferX,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            bufferX - the value to write
            offset - the offset of the item
            length - the length of the item
        returns :
            the iostat
    """
    iostat = miriad_io.new_intp()
    b = intListToArray(bufferX)
    try :
        mx.safecall(miriad_io.hwritei_c,(item,b,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    del b
    return i

def hreadr(item,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            offset - the offset of the item
            length - the length of the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    bufferX = miriad_io.floatArray(length/4)
    try :
        mx.safecall(miriad_io.hreadr_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    c = floatArrayToList(bufferX,length/4)
    i = miriad_io.intp_value(iostat)
    del bufferX
    return c,i

def hwriter(item,bufferX,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            bufferX - the value to write
            offset - the offset of the item
            length - the length of the item
        returns :
            the iostat
    """
    iostat = miriad_io.new_intp()
    b = floatListToArray(bufferX)
    try :
        mx.safecall(miriad_io.hwriter_c,(item,b,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    del b
    return i

def hreadd(item,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            offset - the offset of the item
            length - the length of the item
        returns :
            a tuple containing the item value and iostat
    """
    iostat = miriad_io.new_intp()
    bufferX = miriad_io.doubleArray(length/8)
    try :
        mx.safecall(miriad_io.hreadd_c,(item,bufferX,offset,length,iostat))
    except :
        pass
    c = doubleArrayToList(bufferX,length/8)
    i = miriad_io.intp_value(iostat)
    del bufferX
    return c,i

def hwrited(item,bufferX,offset,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            item - handle to the item
            bufferX - the value to write
            offset - the offset of the item
            length - the length of the item
        returns :
            the iostat
    """
    iostat = miriad_io.new_intp()
    b = doubleListToArray(bufferX)
    try :
        mx.safecall(miriad_io.hwrited_c,(item,b,offset,length,iostat))
    except :
        pass
    i = miriad_io.intp_value(iostat)
    del b
    return i

def hisopen(tno,status) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the open data set
            status - "read", "write", or "append"
    """
    try :
        mx.safecall(miriad_io.hisopen_c,(tno,status))
        #mx.safecall(miriad_io.hisopen_c,(tno,miriad_io.zterm(status,len(status))))
    except :
        pass

def hisread(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the data set
        returns :
            tuple containing a line of history file and logical EOF marker
    """
    line = "                                                                                                  "
    eof = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.hisread_c,(tno,line,eof))
    except :
        pass
    e = castLogical(miriad_io.intp_value(eof))
    line = line.strip()
    return line,e

def hiswrite(tno,line) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the data set
            line - what to write
    """
    try :
        mx.safecall(miriad_io.hiswrite_c,(tno,line))
        #mx.safecall(miriad_io.hiswrite_c,(tno,miriad_io.zterm(line,len(line))))
    except :
        pass

def hisclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the data set
    """
    try :
        mx.safecall(miriad_io.hisclose_c,(tno,))
    except :
        pass

def xyopen(name,status,naxis = MAXNAX,axes = []) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name - the name of the image to open
            status - "new" or "old"
            naxis - maximum number of axes allowed (default 7)
            axes - list of number of elements along each axis (default is [] for read)
        returns :
            a tuple containing the handle and list of number of elements along each axis
    """
    tno = miriad_io.new_intp()
    ax = None
    if(len(axes) == 0) :
        ax = miriad_io.intArray(MAXNAX)
    else :
        ax = intListToArray(axes)
    #ax = intListToArray(axes,naxis)
    #try :
    mx.safecall(miriad_io.xyopen_c,(tno,name, status, naxis,ax))
    #mx.safecall(miriad_io.xyopen_c,(tno,miriad_io.zterm(name,len(name)),miriad_io.zterm(status,len(status)),naxis,ax))
    #except :
    #    pass
    t = miriad_io.intp_value(tno)
    a = intArrayToList(ax,naxis)
    del ax
    return t,a

def xyflush(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
    """
    try :
        mx.safecall(miriad_io.xyflush_c,(tno,))
    except :
        pass

def xyclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
    """
    #try :
    mx.safecall(miriad_io.xyclose_c,(tno,))
    #except :
    #    pass

def xyread(tno,index,size=MAXIMG) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            index - row number to read
        returns :
            a list of floats from the row
    """
    bufferX = miriad_io.floatArray(size)
    try :
        mx.safecall(miriad_io.xyread_c,(tno,index,bufferX))
    except :
        pass
    b = floatArrayToList(bufferX,size)
    del bufferX
    return b

def xywrite(tno,index,bufferX) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle to the image
            index - the row to write
            bufferX - list of floats containing the data
    """
    b = intListToArray(bufferX)
    try :
        mx.safecall(miriad_io.xywrite_c,(tno,index,b))
    except :
        pass
    del b

def xymkrd(tno,index) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle to the image
            index - the row number to select
        returns :
            tuple conatining the mask info (list) and the number of runs read
    """
    bufferX = miriad_io.intArray(MAXIMG)
    nread = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.xymkrd_c,(tno,index,bufferX,MAXIMG,nread))
    except :
        pass
    b = intArrayToList(bufferX,nread)
    nr = miriad_io.intp_value(nread)
    del bufferX
    return b,nr

def xymkwr(tno,index,bufferX) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle of the image
            index - the row number to select
            bufferX - list containing the mask info
    """
    b = intListToArray(bufferX)
    try :
        mx.safecall(miriad_io.xymkwr_c,(tno,index,bufferX,len(bufferX)))
    except :
        pass
    del b

def xyflgrd(tno,index,length) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle of the image
            index - the row to select
            length - the length of the output array
        returns :
            a list of logical values for the flags
    """
    bufferX = miriad_io.intArray(length)
    try :
        mx.safecall(miriad_io.xyflgrd_c,(tno,index,bufferX))
    except :
        pass
    b = castLogical(intArrayToList(bufferX,length))
    del bufferX
    return b

def xyflgwr(tno,index,bufferX) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the handle to the image
            index - the row to select
            bufferX - list containing logical values for the flags
    """
    b = intListToArray(uncastLogical(bufferX))
    try :
        mx.safecall(miriad_io.xyflgwr_c,(tno,index,b))
    except :
        pass
    del b

def xysetpl(tno,naxis,axes) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - the image handle
            naxis - the number of axes
            axes - list containg axis dimensions
    """
    ax = intListToArray(axes,naxis)
    #try :
    mx.safecall(miriad_io.xysetpl_c,(tno,naxis,ax))
    #except :
    #    pass
    #del ax

def hdprobe(tno,keyword) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the miriad data set
            keyword - name of the header variable
        returns :
            tuple containing a description of the item, type, and number of elements
    """
    desc = "                               "
    typeX = "                             "
    n = miriad_io.new_intp()
    #try :
    mx.safecall(miriad_io.hdprobe_c,(tno,keyword,desc,30,typeX,n))
    #mx.safecall(miriad_io.hdprobe_c,(tno,miriad_io.zterm(keyword,len(keyword)),desc,30,typeX,n))
    #except :
    #    pass
    nr = miriad_io.intp_value(n)
    desc = checkAlpha(desc.strip())
    typeX = checkAlpha(typeX.strip())
    return desc,typeX,nr

def rdhdr(tno,keyword,defval = 0.0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            defval - default value (default is 0.0)
        returns :
            the value of the item
    """
    value = miriad_io.new_floatp()
    try :
        mx.safecall(miriad_io.rdhdr_c,(tno,keyword,value,defval))
        #mx.safecall(miriad_io.rdhdr_c,(tno,miriad_io.zterm(keyword,len(keyword)),value,defval))
    except :
        pass
    v = miriad_io.floatp_value(value)
    return v

def rdhdi(tno,keyword,defval = 0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            defval - default value (default is 0)
        returns :
            the value of the item
    """
    value = miriad_io.new_intp()
    #try :
    mx.safecall(miriad_io.rdhdi_c,(tno,keyword,value,defval))
    #mx.safecall(miriad_io.rdhdi_c,(tno,miriad_io.zterm(keyword,len(keyword)),value,defval))
    #except :
    #    pass
    v = miriad_io.intp_value(value)
    return v

def rdhdd(tno,keyword,defval = 0.0) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            defval - default value (default is 0.0)
        returns :
            the value of the item
    """
    value = miriad_io.new_doublep()
    try :
        mx.safecall(miriad_io.rdhdd_c,(tno,keyword,value,defval))
        #mx.safecall(miriad_io.rdhdd_c,(tno,miriad_io.zterm(keyword,len(keyword)),value,defval))
    except :
        pass
    v = miriad_io.doublep_value(value)
    return v

def rdhda(tno,keyword,defval = "1234567890") :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            defval - default value (default is "")
        returns :
            the value of the item
    """
    value = "                     "
#    try :
    mx.safecall(miriad_io.rdhda_c,(tno,keyword,value,defval,10))
    #mx.safecall(miriad_io.rdhda_c,(tno,miriad_io.zterm(keyword,len(keyword)),value,miriad_io.zterm(defval,len(defval)),10))
#    except :
#        pass
    value = checkAlpha(value.strip())
    return value

def rdhdc(tno,keyword,defval=complex(0.0,0.0)) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            defval - default value (default is 0.0+0.0j)
        returns :
            the value of the item
    """
    value = miriad_io.floatArray(2)
    dval = complexListToArray(defval)
    try :
        mx.safecall(miriad_io.rdhdc_c,(tno,keyword,value,dval))
        #mx.safecall(miriad_io.rdhdc_c,(tno,miriad_io.zterm(keyword,len(keyword)),value,dval))
    except :
        pass
    v = complexArrayToList(value,1)
    del value
    del dval
    return v

def wrhdr(tno,keyword,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            value - the value to write
    """
    try :
        mx.safecall(miriad_io.wrhdr_c,(tno,keyword,value))
        #mx.safecall(miriad_io.wrhdr_c,(tno,miriad_io.zterm(keyword,len(keyword)),value))
    except :
        pass

def wrhdd(tno,keyword,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            value - the value to write
    """
    try :
        mx.safecall(miriad_io.wrhdd_c,(tno,keyword,value))
        #mx.safecall(miriad_io.wrhdd_c,(tno,miriad_io.zterm(keyword,len(keyword)),value))
    except :
        pass

def wrhdi(tno,keyword,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            value - the value to write
    """
    try :
        mx.safecall(miriad_io.wrhdi_c,(tno,keyword,value))
        #mx.safecall(miriad_io.wrhdi_c,(tno,miriad_io.zterm(keyword,len(keyword)),value))
    except :
        pass

def wrhdc(tno,keyword,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            value - the value to write
    """
    v = complexListToArray(value)
    try :
        mx.safecall(miriad_io.wrhdc_c,(tno,keyword,v))
        #mx.safecall(miriad_io.wrhdc_c,(tno,miriad_io.zterm(keyword,len(keyword)),v))
    except :
        pass
    del v

def wrhda(tno,keyword,value) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to read
            value - the value to write
    """
    try :
        mx.safecall(miriad_io.wrhda_c,(tno,keyword,value))
        #mx.safecall(miriad_io.wrhda_c,(tno,miriad_io.zterm(keyword,len(keyword)),miriad_io.zterm(value,len(value))))
    except :
        pass

def hdcopy(tIn,tOut,keyword) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tIn - handle to the input data set
            tOut - handle to the output data set
            keyword - the item to copy
    """
    try :
        mx.safecall(miriad_io.hdcopy_c,(tIn,tOut,keyword))
        #mx.safecall(miriad_io.hdcopy_c,(tIn,tOut,miriad_io.zterm(keyword,len(keyword))))
    except :
        pass

def hdprsnt(tno,keyword) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the miriad data set
            keyword - header variable to check
        returns :
            True/False
    """
    XX = None
    try :
        XX = mx.safecall(miriad_io.hdprsnt_c,(tno,keyword))
        #XX = mx.safecall(miriad_io.hdprsnt_c,(tno,miriad_io.zterm(keyword,len(keyword))))
    except :
        pass
    return castLogical(XX)

def xyzopen(name,status,naxis = MAXNAX,axlen = []) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            name - name of the image to open
            status - "new" or "old"
            naxis - number of axes (defualts to 7)
            axlen - list containing axis dimensions
        returns :
            tuple containing the handle, number of axes, and list with the axis dimensions
    """
    tno = miriad_io.new_intp()
    na = miriad_io.copy_intp(naxis)
    aX = None
    if(len(axlen) == 0) :
        aX = miriad_io.intArray(MAXNAX)
    else :
        aX = intListToArray(axlen)
    #try :
    mx.safecall(miriad_io.xyzopen_c,(tno,name,status,na,aX))
    #mx.safecall(miriad_io.xyzopen_c,(tno,miriad_io.zterm(name,len(name)),miriad_io.zterm(status,len(status)),na,aX))
    #except :
    #    pass
    n = miriad_io.intp_value(na)
    a = intArrayToList(aX,n)
    t = miriad_io.intp_value(tno)
    del aX
    return t,n,a

def xyzclose(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
    """
    #try :
    mx.safecall(miriad_io.xyzclose_c,(tno,))
    #except :
    #pass

def xyzflush(tno) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
    """
    try :
        mx.safecall(miriad_io.xyzflush_c,(tno,))
    except :
        pass

def xyzmkbuf() :
    """ Miriad wrapper - see miriad documentation for full description
    """
    try :
        mx.safecall(miriad_io.xyzmkbuf_c)
    except :
        pass

def xyzsetup(tno,subcube,blc,trc) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            subcube - definition of subcube
            blc - coordiantes of bottom left corner
            trc - coordinates of top right corner
        returns :
            tuple containing the length of the virtual axis and size of subcubes
    """
    viraxlen = miriad_io.intArray(MAXNAX)
    vircubesize = miriad_io.intArray(MAXNAX)
    b = intListToArray(blc)
    t = intListToArray(trc)
    try :
        mx.safecall(miriad_io.xyzsetup_c,(tno,subcube,b,t,viraxlen,vircubesize))
        #mx.safecall(miriad_io.xyzsetup_c,(tno,miriad_io.zterm(subcube,len(subcube)),b,t,viraxlen,vircubesize))
    except :
        pass
    del b
    del t
    va = intArrayToList(viraxlen,MAXNAX)
    vc = intArrayToList(vircubesize,MAXNAX)
    del viraxlen
    del vircubesize
    return va,vc

def xyzs2c(tno,subcubenr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the image
            subcubenr - subcube number
        returns :
            coordinates of the bottom left corner
    """
    coords = miriad_io.intArray(MAXNAX)
    try :
        mx.safecall(miriad_io.xyzs2c_c,(tno,subcubenr-1,coords))
    except :
        pass
    c = intArrayToList(coords,MAXNAX)
    del coords
    return c

def xyzc2s(tno,coords) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the image
            coordinates of the bottom left corner
        returns :
            the subcube number
    """
    c = intListToArray(coords)
    sub = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.xyzc2s_c,(tno,coords,sub))
    except :
        pass
    s = miriad_io.intp_value(sub)
    del sub
    del c
    return s

def xyzread(tno,coords) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the image
            coords - list of coordinate values
        returns :
            tuple containing list of data values, logical lists fo mask values, and number of elements read
    """
    c = intListToArray(coords)
    data = miriad_io.floatArray(MAXIMG)
    mask = miriad_io.intArray(MAXIMG)
    ndata = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.xyzread_c,(tno,c,data,mask,ndata))
    except :
        pass
    n = miriad_io.intp_value(ndata)
    d = floatArrayToList(data,n)
    m = castLogical(intArrayToList(mask,n))
    del data
    del mask
    del c
    return d,m,n

def xyzpixrd(tno,pixelnr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            pixelnr - number of the pixel
        returns :
            tuple containing the pixel value and mask value
    """
    data = miriad_io.new_floatp()
    mask = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.xyzpixrd_c,(tno,pixelnr,data,mask))
    except :
        pass
    d = miriad_io.floatp_value(data)
    m = castLogical(miriad_io.intp_value(mask))
    return d,m

def xyzprfrd(tno,profilenr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            profilenr - profile number
        returns :
            tuple containing the data values, mask values, and number of elements
    """
    data = miriad_io.floatArray(MAXNAX)
    mask = miriad_io.intArray(MAXNAX)
    ndata = miriad_io.new_intp()
    try :
        mx.safecall(miriad_io.xyzread_c,(tno,profilenr,data,mask,ndata))
    except :
        pass
    n = miriad_io.intp_value(ndata)
    d = floatArrayToList(data,n)
    m = castLogical(intArrayToList(mask,n))
    del data
    del mask
    return d,m,n

def xyzplnrd(tno,planenr) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the image
            planenr - plane number
        returns :
            tuple containing the data values, mask values, and number of elements
    """
    #print MAXIMG
    data = miriad_io.floatArray(500000)
    #print "Here"
    mask = miriad_io.intArray(500000)
    #print "sadf"
    ndata = miriad_io.new_intp()
    #print "here"
    #try :
    print "xyzplnrd",time.localtime()
    mx.safecall(miriad_io.xyzplnrd_c,(tno,planenr,data,mask,ndata))
    print "done",time.localtime()
    #except :
    #    pass       HERE
    n = miriad_io.intp_value(ndata)
    #print n
    d = floatArrayToList(data,n)
    print "tolist",time.localtime()
    #print d
    m = castLogical(intArrayToList(mask,n))
    print "logic",time.localtime()
#    print m
    del data
    del mask
    return d,m,n

def xyzwrite(tno,coords,data,mask) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle of the image
            coords - coordinates of region to write
            data - list of data values
            mask - logical list of mask values
    """
    c = intListToArray(coords)
    d = floatListToArray(data)
    m = intListToArray(uncastLogical(mask))
    try :
        mx.safecall(miriad_io.xyzwrite_c,(tno,coords,data,mask,len(data)))
    except :
        pass
    del d
    del m
    del c

def xyzpixwr(tno,pixelnr,data,mask) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            pixelnr - pixel number
            data - value of pixel
            mask - logical value of mask
    """
    d = miriad_io.copy_floatp(data)
    m = miriad_io.copy_intp(uncastLogical(mask))
    try :
        mx.safecall(miriad_io.xyzpixwr_,(tno,pixelnr,data,mask))
    except :
        pass

def xyzprfwr(tno,profilenr,data,mask) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            profilenr - profile  number
            data - list containing the data values
            mask - logical list of mask values
    """
    d = floatListToArray(data)
    m = intListToArray(uncastLogical(mask))
    try :
        mx.safecall(miriad_io.xyzprfwr_,(tno,profilenr,data,mask,len(data)))
    except :
        pass
    del d
    del m

def xyzplnwr(tno,planenr,data,mask) :
    """ Miriad wrapper - see miriad documentation for full description
        input :
            tno - handle to the image
            planenr - plane number
            data - list of data values
            mask - logical list of mask values
    """
    d = floatListToArray(data)
    m = intListToArray(uncastLogical(mask))
    try :
        mx.safecall(miriad_io.xyzplnwr_,(tno,planenr,data,mask,len(data)))
    except :
        pass
    del d
    del m

def j1xbyx(arg) :
    argX = miriad_io.copy_floatp(arg)
    value = mx.safecall(miriad_io.j1xbyx_,(argX,))
    return value

def jinc(x) :
    xX = miriad_io.copy_floatp(x)
    value = mx.safecall(miriad_io.jinc_,(xX,))
    return value

def chat(x) :
    xX = miriad_io.copy_floatp(x)
    value = mx.safecall(miriad_io.chat_,(xX,))
    return value

def sortidxd(n,x) :
    xX = doubleListToArray(x)
    idx = miriad_io.intArray(n)
    try :
        mx.safecall(miriad_io.sortidxd_,(n,xX,idx))
    except :
        pass
    idxX = intArrayToList(idx,n)
    return idxX

def sortidxr(n,x) :
    xX = floatListToArray(x)
    idx = miriad_io.intArray(n)
    try :
        mx.safecall(miriad_io.sortidxd_,(n,xX,idx))
    except :
        pass
    idxX = intArrayToList(idx,n)
    return idxX

def sortidxi(n,x) :
    xX = intListToArray(x)
    idx = miriad_io.intArray(n)
    try :
        mx.safecall(miriad_io.sortidxd_,(n,xX,idx))
    except :
        pass
    idxX = intArrayToList(idx,n)
    return idxX

def polspara(code) :
    codeX = miriad_io.copy_intp(code)
    XX = None
    try :
        XX = mx.safecall(miriad_io.polspara_,(code,))
    except :
        pass
    return castLogical(XX)

def polsc2p(code) :
    val = "    "
    codeX = miriad_io.copy_intp(code)
    try :
        mx.safecall(miriad_io.polsc2p_,(val,3,code))
    except :
        pass
    return val.strip()

def polsp2c(mnemo) :
    XX = -999
    try :
        XX = mx.safecall(miriad_io.polsp2c_,(mnemo,len(mnemo)))
    except :
        pass
    return XX

