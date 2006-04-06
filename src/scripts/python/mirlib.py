# A module for using functions from the Miriad Library
"""
Module to use Miriad library functions
Available are:
  class uv()
  varlist(miruv,var)
  varvalue(miruv,var)
  prnthis(miruv)
  addhis(mir,string)
  getvarfromhis(file,var):
"""

import uvio

types= {'a' : [1,1], 'i' : [2,4], 'r' : [4,4], 'd' : [5,8]}

class uv:
    """UV I/O access routines"""
    def __init__(self,name):
        self.name = name
        ff = uvio.new_intp()
        uvio.uvopen_c(ff,name,"old")
        self.fh = uvio.intp_value(ff)
        #
        self.maxchan = 4096
        self.p = uvio.doubleArray(5)
        self.f = uvio.intArray(self.maxchan)
        self.d = uvio.floatArray(2*self.maxchan)
        self.nn = uvio.new_intp()
        self.scan = 0
        self.maxscan = 0
    def open(self,name):
        self.name = name
        ff = uvio.new_intp()
        uvio.uvopen_c(ff,name,"old")
        self.fh = uvio.intp_value(ff)
    def rewind(self):
        print "rewinding"
        self.scan = 0
        uvio.uvrewind_c(self.fh)
    def read(self,scan=0):
        """read the next record"""
        if scan == 0:
            uvio.uvread_c(self.fh,self.p,self.d,self.f,self.maxchan,self.nn)
            self.scan =  self.scan + 1
        else:
            if scan < self.scan:
                self.rewind()
            else:
                scan = scan - self.scan
            while scan > 0:
                uvio.uvread_c(self.fh,self.p,self.d,self.f,self.maxchan,self.nn)
                self.scan =  self.scan + 1
                scan = scan - 1
        return uvio.intp_value(self.nn)
    def iscan(self):
        return self.scan
    def nscan(self):
        """return how many records a uv file has"""
        if self.maxscan == 0:
            self.rewind()
            n = 0
            while self.read():
                n = n + 1
            self.rewind()
            self.maxscan = n
            return n
        else:
            return self.maxscan
    def var(self,var,updated=True):
        """get a UV variable, if it has not changed"""
        type=" "
        length=uvio.new_intp()
        upd=uvio.new_intp()
        uvio.uvprobvr_c(self.fh,var,type,length,upd)
        if updated and not uvio.intp_value(upd):
            return []
        # Get the variable from the UV data set
        ctype=uvio.charp_value(type)
        h_type=types[ctype][0]
        bytes=types[ctype][1]

        # print "Type: "+ctype
        length_val=uvio.intp_value(length)
        if ctype =='i':
            varvalue_array=uvio.intArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'r':
            varvalue_array=uvio.floatArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'd':
            varvalue_array=uvio.doubleArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'a':
            length_val=uvio.intp_value(length)+1
            value=length_val*"a"
        else:
            print 'Type '+ctype+' not implemented'
            return None
        
        uvio.uvgetvr_c(self.fh,h_type,var,value,length_val)

        # Handle the result depending on the type of the variable
        if ctype =='i':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(varvalue_array[i])
        elif ctype == 'r':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(float(varvalue_array[i]))
        elif ctype == 'd':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(float(varvalue_array[i]))
        elif ctype == 'a':
            varvalue=value[0:length_val-1]
        else:
            print 'Type '+ctype+' not implemented'
            return None
        return varvalue
        
    def close(self):
        """close the currentlyh open VIS file"""
        uvio.uvclose_c(self.fh)
        self.fh = 0
        

def varlist(miruv,var):
    """
    This function returns the values of a list of variables var
    in a Miriad UV dataset miruv.
    """

    # stack the output
    outvals=[]

    # Open the UV dataset
    ff=uvio.new_intp()
    uvio.uvopen_c(ff,miruv,"old")
    fh=uvio.intp_value(ff)

    # Read the first data from it (needed in order
    # to access the variables.
    maxchan=4096
    p=uvio.doubleArray(4)
    f=uvio.intArray(maxchan)
    d=uvio.floatArray(2*maxchan)
    nn=uvio.new_intp()
    while True:
        uvio.uvread_c(fh,p,d,f,maxchan,nn)
        n = uvio.intp_value(nn)
        if n <= 0: break

        # Test if the variable exists
        type=" "
        length=uvio.new_intp()
        upd=uvio.new_intp()
        uvio.uvprobvr_c(fh,var,type,length,upd)
        if not uvio.intp_value(upd):
            continue

        # Get the variable from the UV data set
        ctype=uvio.charp_value(type)
        h_type=types[ctype][0]
        bytes=types[ctype][1]

        # print "Type: "+ctype
        length_val=uvio.intp_value(length)
        if ctype =='i':
            varvalue_array=uvio.intArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'r':
            varvalue_array=uvio.floatArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'd':
            varvalue_array=uvio.doubleArray(length_val)
            value=uvio.cdata(varvalue_array,length_val*bytes)
        elif ctype == 'a':
            length_val=uvio.intp_value(length)+1
            value=length_val*"a"
        else:
            print 'Type '+ctype+' not implemented'
            return None
        
        uvio.uvgetvr_c(fh,h_type,var,value,length_val)

        # Handle the result depending on the type of the variable
        if ctype =='i':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(varvalue_array[i])
        elif ctype == 'r':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(float(varvalue_array[i]))
        elif ctype == 'd':
            uvio.memmove(varvalue_array,value)
            varvalue=[]
            for i in range(length_val):
                varvalue.append(float(varvalue_array[i]))
        elif ctype == 'a':
            varvalue=value[0:length_val-1]
        else:
            print 'Type '+ctype+' not implemented'
            return None
    
        # print varvalue
        outvals.append(varvalue)
    # Close the UV dataset
    uvio.uvclose_c(fh)
    return outvals
    
        

def varvalue(miruv,var):
    """
    This function returns the value of a variable var
    in a Miriad UV dataset miruv.
    """

    # Open the UV dataset
    ff=uvio.new_intp()
    uvio.uvopen_c(ff,miruv,"old")
    fh=uvio.intp_value(ff)

    # Read the first data from it (needed in order
    # to access the variables.
    maxchan=4096
    p=uvio.doubleArray(4)
    f=uvio.intArray(maxchan)
    d=uvio.floatArray(2*maxchan)
    nn=uvio.new_intp()
    uvio.uvread_c(fh,p,d,f,maxchan,nn)

    # Test if the variable exists
    type=" "
    length=uvio.new_intp()
    upd=uvio.new_intp()
    uvio.uvprobvr_c(fh,var,type,length,upd)

    # Get the variable from the UV data set
    ctype=uvio.charp_value(type)
    h_type=types[ctype][0]
    bytes=types[ctype][1]

    # print "Type: "+ctype
    length_val=uvio.intp_value(length)
    if ctype =='i':
	varvalue_array=uvio.intArray(length_val)
        value=uvio.cdata(varvalue_array,length_val*bytes)
    elif ctype == 'r':
	varvalue_array=uvio.floatArray(length_val)
        value=uvio.cdata(varvalue_array,length_val*bytes)
    elif ctype == 'd':
	varvalue_array=uvio.doubleArray(length_val)
        value=uvio.cdata(varvalue_array,length_val*bytes)
    elif ctype == 'a':
        length_val=uvio.intp_value(length)+1
        value=length_val*"a"
    else:
        print 'Type '+ctype+' not implemented'
        return None
        
    uvio.uvgetvr_c(fh,h_type,var,value,length_val)

    # Close the UV dataset
    uvio.uvclose_c(fh)
    
    # Handle the result depending on the type of the variable
    if ctype =='i':
        uvio.memmove(varvalue_array,value)
        varvalue=[]
        for i in range(length_val):
            varvalue.append(varvalue_array[i])
    elif ctype == 'r':
        uvio.memmove(varvalue_array,value)
        varvalue=[]
        for i in range(length_val):
            varvalue.append(float(varvalue_array[i]))
    elif ctype == 'd':
        uvio.memmove(varvalue_array,value)
        varvalue=[]
        for i in range(length_val):
            varvalue.append(float(varvalue_array[i]))
    elif ctype == 'a':
        varvalue=value[0:length_val-1]
    else:
        print 'Type '+ctype+' not implemented'
        return None
    
    return varvalue
    
        
def prnthis(miruv):
    """
    This function prints the history of a Miriad UV dataset miruv.
    """

    # Open the UV dataset
    ff=uvio.new_intp()
    uvio.uvopen_c(ff,miruv,"old")
    fh=uvio.intp_value(ff)

    # Open the history
    uvio.hisopen_c(fh,"read")

    # End of file pointer
    eof=uvio.new_intp()
    uvio.intp_assign(eof,0)
    
    while not uvio.intp_value(eof):
        # Define line (does the length really need to be hardcoded?)
        line=80*" "
        uvio.hisread_c(fh,line,80,eof)
        print line

    # Close the history
    uvio.hisclose_c(fh)

    # Close the data set
    uvio.uvclose_c(fh)
    
    return

def getvarfromhis(file,var):
    """
    This function returns the value of a variable if it is listed in
    the history of that dataset
    """

    # Set default value
    varvalue=""
    
    # Open the UV dataset
    ff=uvio.new_intp()
    uvio.uvopen_c(ff,file,"old")
    fh=uvio.intp_value(ff)

    # Open the history
    uvio.hisopen_c(fh,"read")

    # End of file pointer
    eof=uvio.new_intp()
    uvio.intp_assign(eof,0)
    
    while not uvio.intp_value(eof):
        # Define line (does the length really need to be hardcoded?)
        line=80*" "
        uvio.hisread_c(fh,line,80,eof)
        if line.startswith(var):
            varvalue_str=line.split()[-1].replace("\x00","")
            if not varvalue_str.isalpha():
                varvalue=eval(varvalue_str)
            else:
                varvalue=varvalue_str

    
    # Close the history
    uvio.hisclose_c(fh)

    # Close the data set
    uvio.uvclose_c(fh)
    
    return varvalue

def addhis(mir,string):
    """
    This function adds a line to the history of a Miriad dataset mir.
    """

    print mir
    print string
    
    # Open the dataset
    ff=uvio.new_intp()
    uvio.uvopen_c(ff,mir,"old")
    fh=uvio.intp_value(ff)

    # Open the history
    uvio.hisopen_c(fh,"write")

    # Write to history
    uvio.hiswrite_c(fh,string)

    # Close the history
    uvio.hisclose_c(fh)

    # Close the data set
    uvio.uvclose_c(fh)
    
    return
    

    
        
