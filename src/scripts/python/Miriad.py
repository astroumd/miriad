#! /usr/bin/env python
#
#  a module that defines various routines useful for miriad processing
#
#   15-mar-2003   1.0 Created                                   PJT
#   16-apr-2003   1.2 added run,keyr,keyi,keya
#   10-nov-2003   1.2a ??? checker                               NC
#

import sys, os, time, string, math, copy

#   some global variables (private to Miriad.py)
_version = "1.2a (10-nov-2003)"
_logger  = ""
_quit    = 0
_mkeyval = []

def run(command,log,fatal):
    """an alias for miriad()"""
    return miriad(command,log,fatal)

def miriad(command,log=0,fatal=1):
    """
    miriad        execute a miriad 'command' (as a list of strings) and accumulate a log
                  either from the default logfile (see setlogger) or by overriding using
                  log=. By default an error results into an exit, though this can be
                  overriden by using fatal=0
                  Example:    miriad(['itemize','in=ngc1365.cm'],log='ngc1365.log')

    Other commands available in PYRAMID are:
    
    doc           show specific help for a MIRIAD task , e.g. doc('invert')
    keys          show all keywords for a MIRIAD task , e.g. keys('invert')
    setlogger     change the default logger for subsequent miriad() commands,
                  e.g. setlogger('rubbish.log')

    zap           delete a miriad dataset (with existence check), e.g. zap('ngc1365.cm')
    zap_all       delate a set of data (unchecked), e.g. zap_all('ncg1365*')
    grepcmd       Return the Nth word on the first occurence of a string match from a command
                  e.g.:    grepcmd('histo in=ngc1365.cm','Maximum',2)
    greplog       Return the Nth word on the first occurence of a string match from a logfile
                  e.g.:    grepcmd('ngc1365.log','naxis1',2)
                  Notice that the index N starts at 0!!

    Some useful classes defined via PYRAMID:

    Timer         mark and compute CPU times between sections of the code

    A number of useful and less useful user contribued PYRAMID scripts
    can be found in and below $MIR/examples/
    
    """
    global _logger
    if (log != 0):
        mycmd = cmd(command) + '> %s 2>&1' % log
    else:
        mycmd = cmd(command) + _logger;
    retval = os.system(mycmd)
    if retval:
        print "###: Error %d from %s" % (retval,command[0])
        if fatal:
            os._exit(retval)

def setlogger(log,append=0):
    """ set the logfile for the miriad() function. By default any old logfile is removed"""
    global _logger
    print "setlogger: default logfile now " + log
    _logger = '>> %s 2>&1' % log
    if append==0:
        zap(log)

def keyini(keyval,help=0,show=0):
    global _quit, _mkeyval
    for arg in sys.argv[1:]:
        i=string.find(arg,"=")
        if arg == "--help" or arg == "-h":
            _quit=1
        elif i > 0:
            key = arg[0:i]
            val = arg[i+1:]
            if keyval.has_key(key):
                keyval[key] = val
            else:
                print "### Error: keyword in %s not understood, try --help or -h" % arg
                os._exit(0)            
        else:
            print "### Error: argument %s not understood, try --help or -h" % arg
            os._exit(0)
    # _mkeyval = keyval[:]                # does not seem to work
    # _mkeyval = copy.copy(keyval)        # makes a (deep?) copy
    _mkeyval = keyval                     # keep a reference
    if _quit:
        show_keyval(keyval,help,_quit)
    elif show:
        show_keyval(keyval,help,_quit)

def keyprsnt(key):
    """does keyword have a value"""
    global _mkeyval
    if _mkeyval[key] == " " or _mkeyval[key] == "":
        return 0
    else:
        return 1
    
def keya(key):
    """return keyword value"""
    global _mkeyval
    return _mkeyval[key]

def keyi(key):
    """return keyword value as integer"""
    global _mkeyval
    return string.atoi(_mkeyval[key])

def keyr(key):
    """return keyword value as real"""
    global _mkeyval
    return string.atof(_mkeyval[key])

def keyl(key):
    """return keyword value as boolean (0,1)"""
    global _mkeyval
    b=_mkeyval[key]
    if b[0]=='1' or b[0]=='t':
	return 1
    elif b[0]=='0' or b[0]=='f':
	return 0
    else:
	return -1

def check_required():
    """Checks to see that required arguments (default values of ???) have
    been given new values"""
    global _mkeyval
    usage="Usage: %s " %sys.argv[0]
    _missing=0
   
    if '???' in _mkeyval.values():
        print "### Error: Insufficient parameters.  Try --help or -h."   
        for i in _mkeyval.keys():
            if _mkeyval[i]=='???':
                usage=usage+"%s=??? " %i
                _missing=_missing+1
        if len(_mkeyval.keys())>_missing:
            usage=usage+"..."
        print usage
        os._exit(0)

def show_keyval(keyval,help=0,quit=0):
    if help != 0:
        print help
    print "------------------------------------------------------------"
    print "Miriad.py: version " + _version 
    print "Current keywords and their defaults are:"
    print "------------------------------------------------------------"
    for k in keyval.keys():
        print k + '=' + keyval[k]
    print "------------------------------------------------------------"
    if quit:
        os._exit(0)


def zap(file):
    """ remove a possibly existing miriad dataset (no wildcards)"""
    if os.path.isdir(file):
        os.system('rm -rf ' + file)
    elif os.path.isfile(file):
        os.system('rm -f ' + file)

def zap_all(files):
    """ remove all datasets (wildcards now allowed via the shell)"""
    os.system('rm -rf ' + files)

def cmd(cmdlist,debug=0):
    """convert a list of strings to a command string"""
    str = cmdlist[0] 
    for arg in cmdlist[1:]:
        str = str + ' ' +  arg
    if debug: print str
    return str

def doc(task):
    """show a little help on a miriad task...."""
    os.system('doc %s | less' % task)

def keys(task):
    """show just the keywords for a miriad task"""
    os.system('doc %s | grep ^Keyword' % task)

def timer(slot):
    """ save CPU info in predefined global slots"""
    global timet, timec
    timec[slot] = time.clock()
    timet[slot] = time.time()

def cpulen(a,b):
    """create a string to print human readable CPU info between slots """
    st = '%.3f ' % (timet[b]-timet[a])
    sc = '%.3f ' % (timec[b]-timec[a])
    return sc + st

#   should use popen()
def grepcmd(cmd,word,index=0):
    """run a command, grep through the output for a word and return a 0-indexed word"""
    log = 'tmp.log'
    os.system(cmd + ' > %s' % log)
    f = open(log,"r")
    v = f.read()
    va=string.split(v,"\n")
    f.close()
    for s in va:
        if string.find(s,word)>=0:
            sa=string.split(s)
            # print 'Match ' + word + '=>' + sa[index]
            return sa[index]
    print 'No match on' + word
    return "no-match"

def greplog(log,word,index=0):
    """ grep through a logfile for a word and return a 0-indexed word"""
    f = open(log,"r")
    v = f.read()
    va=string.split(v,"\n")
    f.close()
    for s in va:
        if string.find(s,word)>=0:
            sa=string.split(s)
            # print 'Match ' + word + '=>' + sa[index]
            return sa[index]
    print 'No match on' + word
    return "no-match"

class Timer:
    """a class to help you compute CPU times the script takes
    between certain tagged locations, e.g.
              t=Timer()
              t.tag()
              .....
              t.tag()
              print "Time passed %g seconds" % t.dt(0,1)
    """
    
    def __init__(self):
        self.n = 0
        self.timec = []
        self.timet = []
    def count(self):
        return self.n
    def tag(self):
        self.n = self.n + 1
        self.timec.append(time.clock())
        self.timet.append(time.time())
    def show(self):
        print "Currently have %d entries" % self.n
        print time.clock()
        print time.time()
    def showall(self):
        print self.timec
        print self.timet
    def clock(self,i):
        return self.timec[i]
    def time(self,i):
        return self.timet[i]
    def dt(self,i,j):
        return self.timet[j]-self.timet[i]
    def dc(self,i,j):
        return self.timec[j]-self.timec[i]
    
    

#   If executed... probably they are in an interactive python shell
if __name__ == '__main__':
    print ""
    print "Welcome to PYRAMID, a python enabled interface to MIRIAD."
    print "Please make sure $MIR/src/scripts/python is part of your"
    print "PYTHONPATH environment variable to make use of all the"
    print "available modules."
    print ""
    print "Type help(miriad) to get more help on this interface, or"
    print 'doc("invert") or keys("invert") to get specific help on a miriad task'
    print "You are now dropped to the PYTHON prompt, enter ^D to exit"
    print ""
