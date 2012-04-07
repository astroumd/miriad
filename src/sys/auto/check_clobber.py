#! /usr/bin/env python
#
# This is a simple script to check whether the autotools build
# clobbers any files stored in CVS. I need it because I use
# out-of-place build directories, so the built files don't
# live in the same location as the CVS repository.

import sys, os, os.path
from os.path import join, exists, isdir

if len (sys.argv) != 3:
    print >>sys.stderr, 'Usage: %s <CVS-checkout-topdir> <build-topdir>' % sys.argv[0]
    sys.exit (1)

topsrc = sys.argv[1]
topbuild = sys.argv[2]

# Ready to go.

dirs = [(topsrc, '$src/', topbuild, '$build/')]
diridx = 0
clobbered = False

while diridx < len (dirs):
    sabs, srel, babs, brel = dirs[diridx]

    # Increment the counter here so we can "continue" with
    # impunity through the rest of the loop.

    diridx += 1

    # Load up the list of files known to CVS in this 
    # directory

    files = set ()
    subdirs = set ()
    fn = join (sabs, 'CVS', 'Entries')

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
            newsabs = join (sabs, a[1])
            newsrel = srel + a[1] + '/'
            newbabs = join (babs, a[1])
            newbrel = brel + a[1] + '/'
            dirs.append ((newsabs, newsrel, newbabs, newbrel))
            subdirs.add (a[1])
        elif a[0] == '':
            # This entry represents a file that we should check
            # for ignoring.
            files.add (a[1])
        # otherwise, ignore the line

    # Check the builddir for anything overwriting anything
    # in CVS.

    if not isdir (babs):
        continue
    
    for fn in os.listdir (babs):
        if fn in files or (fn in subdirs and not isdir (join (babs, fn))):
            print brel + fn
            clobbered = True
            

# All done.

if clobbered:
    sys.exit (1)

sys.exit (0)
