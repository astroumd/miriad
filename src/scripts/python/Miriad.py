#! /usr/bin/env python
##
## Routine to make it easy to read command line arguments in a keyword=value
## style format.  Also has support for --help, help=, -h, etc, and setting
## a debug level.  Finally, includes the warning, error, and dprintf functions
## which may also be useful in scripting.
##
##   15-mar-2003   Created                                   PJT\n
##   16-apr-2003   added run,keyr,keyi,keya\n
##   05-mar-2004   Added help comments nemo style            NLC\n
##   16-may-2004   Deleted all the code we don't use for map2  NLC\n
##   19-feb-2008   Changed keya, keyi, and keyr to not use the 
##                 keypresent function.  This allows the programmer to
##                 specify a default keyword value of nothing.  However,
##                 error checking was added to keyini so that if the user
##                 tries to input an empty keyword on the command line,
##                 than an error message will still occur.  Also, some cleanups
##                 to remove extraneous comments, combined the badkeyword
##                 function with keya, and added the keyf function which works
##                 the same as keyr.
##
import sys, os

#   some global variables (private to Miriad.py)
_version = "1.5 (19-feb-2008)"
_quit    = 0
_mkeyval = {}
_help    = {}
_debuglevel = 0

def keyini(keyval,show=0,gui=0,usage=None):
    """Initialize the values of all keywords, and check to see that
       all required keywords are present.  Also, it user specifies
       help, it calls the show_keyval function

       @param keyval A dictionary of keywords and values
       @param show   If 1, calls show_keyval
       @param gui    If 1, ignores required keywords (???)

       @return None"""
    global _quit, _mkeyval, _help, _debuglevel
    _help = keyval.copy()
    for key in _help.keys():  # Parse for help comments if any
       idx = _help[key].find('\n')
       if idx >= 0: # Found help comment
          _help[key] = _help[key][idx+1:].strip()
          keyval[key] = keyval[key][:idx].strip()
       elif key == '_msg_':
          pass # do nothing since this is the usage statement
       else: # No help comment found
          _help[key] = ""
    # old way of passing usage statement as a separate string.
    if usage:
       _help['_msg_']= usage
    
    # Set default debug level to 0
    _debuglevel = 0
    for arg in sys.argv[1:]:
        i=arg.find("=")
        if arg in ["--help","-h","help"]:
            _quit=1
        elif i > 0:
            key = arg[0:i]
            val = arg[i+1:]
            if len(val) == 0:
               error('keyword %s cannot have a blank value!' %key)
            elif keyval.has_key(key):
                keyval[key] = val
            elif key == "help":
                _quit=1
            elif key == 'debug':
               try:
                  _debuglevel = int(val)
               except ValueError:
                  error('debug=%s must be an integer' %val)
            else:
                error("keyword %s does not exist, try --help or -h" % arg)
        else:
            warning("argument %s not understood, try --help or -h" % arg)
            warning("Skipping and continuing.")
    _mkeyval = keyval.copy() # keep a reference
    if _quit:
        show_keyval(_mkeyval,_help,_quit)
    elif show:
        show_keyval(_mkeyval,_help,_quit)
    if not gui:
       check_required()

def check_required():
   """Checks to see that required arguments (default values of ???) have
   been given new values"""
   global _mkeyval
   usage="Usage: %s " %sys.argv[0]
   _missing=0

   if '???' in _mkeyval.values():
      print "### Fatal Error! Insufficient parameters.  Try --help or -h."
      for i in _mkeyval.keys():
         if _mkeyval[i]=='???':
            usage=usage+"%s=??? " %i
            _missing=_missing+1
      if len(_mkeyval.keys())>_missing:
         usage=usage+"..."
      print usage
      os._exit(0)

def at_file(filename):
   """Tries to read an at-file, a file that contains keyword values.
      Specified by key=@filename.  It converts the file to a
      string of comma separated values.

      @param filename - string name of file.  Assumed to still
      	 contain the leading @ symbol"""

   if os.path.exists(filename[1:]):
      fp = open(filename[1:],'r')
      data=fp.readlines()
      fp.close()
      val=''
      for x in data:
      	 val=val+x[0:-1]+','
      val = val[0:-1] # delete trailing comma
   else:
      error("Keyword value file %s is missing!" %filename[1:])
   return val

def debug():
   '''Gets the current debug level and returns it'''
   return _debuglevel

def keya(key):
   """return keyword value as a string and will give an error message if they
      keyword does not exist."""
   
   if _mkeyval.has_key(key):
      return _mkeyval[key]
   else:
      error('Invalid keyword "%s"!' %key)

def keyi(key):
   """return keyword value as integer"""

   try:
      return int(keya(key))
   except ValueError:
      error("%s is not a valid integer for keyword %s!" %(keya(key),key))

def keyr(key):
   """return keyword value as a float"""   
   try:
      return float(keya(key))
   except ValueError:
      error("%s is not a valid float for keyword %s!" %(keya(key),key))

def keyf(key):
   """A duplicate for the keyr function since this mnemonic may make sense
      to the user."""
   keyr(key)

def keyl(key,val='a'):
   """return keyword value as a list.
   
      The val keyword can be either a (ascii), i (integer), r, or f (float)"""

   temp=keya(key)
   if temp!='':
      if temp[0]=='@':
         temp=at_file(temp).split(',')
      else:
         temp=temp.split(',')
      if val=='i':
         for i in range(0,len(temp)):
            try:
               temp[i]=int(temp[i])
            except:
               error("%s is not a valid integer!" %temp[i])
      elif val=='r' or val == 'f':
         for i in range(0,len(temp)):
            try:
               temp[i]=float(temp[i])
            except:
               error("%s is not a valid float!" %temp[i])
   return temp

def keyb(key):
   """Return keyword value as a boolean True/False.
   
      Can understand True,False,1,0,yes, and no as all valid."""
   temp = keya(key)
   if temp.lower() in ('1','yes','true','y'):
      return True
   elif temp.lower() in ('0','no','false','n'):
      return False
   else:
      error("%s is not a boolean value!" %temp)
   
def show_keyval(keyval,help=0,quit=0):
    """Print out the current keywords, their values and a help message, if
       one is present."""

    if help!=0:
      if help.has_key('_msg_'):
      	 print help['_msg_']
    print "------------------------------------------------------------"
    for k in keyval.keys():
       if k != '_msg_':   
          if help != 0:
             print k + '=' + keyval[k] + '  '+help[k]
          else:
             print k + '=' + keyval[k]
    print "------------------------------------------------------------"
    if quit:
        os._exit(0)

def warning(text):
   """Print a string of text as a warning"""
   sys.stderr.write("### Warning! %s\n" %text)

def error(text):
   """Print a string of text as a fatal error and quit"""
   sys.stderr.write("### Fatal Error! %s\n" %text)
   sys.exit()

def dprint(level,text):
   """Print the debug message text if level is <= _debuglevel"""
   
   try:
      x = int(level)
   except ValueError:
      error('%s is not a valid integer' %str(level))
   if x <= _debuglevel:
      print text

#   If executed... probably they are in an interactive python shell
if __name__ == '__main__':
   print """This program provides commandline argument reading
   for the various python programs.  It is not intended to be
   used as a standalone program."""
