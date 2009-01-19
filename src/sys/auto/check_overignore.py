#! /usr/bin/env python
#
# This is a simple script to check the .cvsignore files
# in a checkout. It will report if any of the .cvsignore
# rules match a file in CVS/Entries, which indicates
# overzealous .cvsignoring. 
#
# This script takes one argument: the top directory of the 
# CVS checkout.
#
# This script is actually not Miriad-specific at all, nor
# is it specific to the autotool build system.

import sys, os, os.path
from fnmatch import fnmatch
from os.path import join, exists

if len (sys.argv) > 2:
    print >>sys.stderr, 'Usage: %s [CVS checkout topdir]' % sys.argv[0]
    sys.exit (1)

if len (sys.argv) == 1:
    topdir = '.'
else:
    topdir = sys.argv[1]

dirs = [(topdir, '')]
diridx = 0
anybad = False

while diridx < len (dirs):
    dabs, drel = dirs[diridx]

    # Increment the counter here so we can "continue" with
    # impunity through the rest of the loop.

    diridx += 1

    # Load up the list of patterns in the .cvsignore file, 
    # if it exists.

    patterns = []
    fn = join (dabs, '.cvsignore')

    if exists (fn):
        f = file (fn, 'r')
        for l in f:
            l = l.strip ()
            if len (l) < 1: continue
            patterns.append (l)
    
    # Load up the list of files known to CVS in this 
    # directory

    entries = []
    fn = join (dabs, 'CVS', 'Entries')

    if not exists (fn):
        print >>sys.stderr, ('Error: Expected, but did not find, '
                             'the file \"%s\"' % fn)
        sys.exit (1)

    f = file (fn, 'r')
    for l in f:
        a = l.strip ().split ('/')

        if len (a) < 2: 
            # Shouldn't happen, but be safe
            continue

        if a[0] == 'D':
            # This entry represents a subdirectory that we should
            # investigate.
            newabs = join (dabs, a[1])
            newrel = drel + a[1] + '/'
            dirs.append ((newabs, newrel))
        elif a[0] == '':
            # This entry represents a file that we should check
            # for ignoring.
            entries.append (a[1])
        # otherwise, ignore the line

    # Short-circuits

    if len (entries) == 0: continue
    if len (patterns) == 0: continue

    # Oh well, we actually have to do the checking.
    # We implement this with the "I don't care" algorithm.

    for e in entries:
        for p in patterns:
            if fnmatch (e, p):
                print drel + p
                anybad = True

# All done.

if anybad:
    sys.exit (1)

sys.exit (0)
