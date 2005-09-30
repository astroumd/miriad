# A module for using functions from the Miriad Library
"""
Module to use Miriad library functions
"""

import uvio

types= {'a' : [1,1], 'i' : [2,4], 'r' : [4,4], 'd' : [5,8]}

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
    

    
        
