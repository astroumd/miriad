#! /usr/bin/env python
#
#  a module that defines various routines useful for miriad processing
#
#   15-mar-2003   Created                                   PJT
#

import sys, os, time, string, math

#   some global variables (should class this up and hide the data)
logger = ""

#   set the logfile for the miriad() function
def setlogger(log):
    global logger
    logger = '>> %s 2>&1' % log
    zap(log)

#   remove a possibly existing miriad dataset (no wildcards)
def zap(file):
    if os.path.isdir(file):
        os.system('rm -rf ' + file)

#   remove all datasets (wildcards now allowed via the shell)
def zap_all(files):
    os.system('rm -rf ' + files)

#   execute a miriad 'command' (a list of strings) and accumulate a log 
def miriad(command,log=0):
    global logger
    if (log != 0):
        mycmd = cmd(command) + '> %s 2>&1' % log
    else:
        mycmd = cmd(command) + logger;
    return os.system(mycmd)

#   convert a list of strings to a command string
def cmd(cmdlist):
    str = cmdlist[0] 
    for arg in cmdlist[1:]:
        str = str + ' ' +  arg
    print str
    return str

#   show a little help....
def doc(task):
    os.system('doc %s | less' % task)

#   show just the keywords for a program
def keys(task):
    os.system('doc %s | grep ^Keyword' % task)

#   save CPU info in predefined global slots
def timer(slot):
    global timet, timec
    timec[slot] = time.clock()
    timet[slot] = time.time()

#   create a string to print human readable CPU info between slots 
def cpulen(a,b):
    st = '%.3f ' % (timet[b]-timet[a])
    sc = '%.3f ' % (timec[b]-timec[a])
    return sc + st

#   run a command, grep through the output for a word and return a 0-indexed word
#   should use popen()
def grepcmd(cmd,word,index=0):
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

#   grep through a logfile for a word and return a 0-indexed word
def greplog(log,word,index=0):
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
    print "Welcome to pyramid, a python enabled interface to MIRIAD."
    print 'To get help on miriad tasks,  try e.g.  doc("invert")'
    print 'or keys("invert")'
    print "You are now dropped to the PYTHON prompt, enter ^D to exit"
    print ""
