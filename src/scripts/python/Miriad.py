#! /usr/bin/env python
#
#  a module that defines various routines useful for miriad processing

import sys, os, time, string, math

logger = ""

def setlogger(log):
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
    if (log != 0):
        mycmd = cmd(command) + '> %s.log 2>&1' % command[0]
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



if __name__ == '__main__':
    print "This is the main, it does nothing"
