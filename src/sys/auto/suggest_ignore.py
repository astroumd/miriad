#! /usr/bin/env python
#
# This is a simple script to suggest additions to the .cvsignore
# files in a checkout. It looks at the files in a build directory
# (not necessarily the same as the checkout directory, thanks to
# the out-of-place capabilities of the autotools) and sees which
# ones are not covered by existing cvsignores.
#
# This script takes two arguments: the top directory of the 
# CVS checkout, and the top directory of the build. They
# both default to "."
#
# This script is actually not Miriad-specific at all. The fact that
# it can take both a source and a build directory is most useful
# when using the autotools, but this script can still work with
# a classic-style build.

import sys, os, os.path
from fnmatch import fnmatch
from os.path import join, exists, isdir

if len (sys.argv) > 3:
    print >>sys.stderr, 'Usage: %s [CVS checkout topdir] [build topdir]' % sys.argv[0]
    sys.exit (1)

if len (sys.argv) < 2:
    topsrc = '.'
else:
    topsrc = sys.argv[1]

if len (sys.argv) < 3:
    topbuild = topsrc
else:
    topbuild = sys.argv[2]

dirs = [(topsrc, '$src/', topbuild, '$build/')]
diridx = 0
anysugg = False

# Built in CVSignores

builtin = ['RCS', 'SCCS', 'CVS', 'CVS.adm', 'RCSLOG',
           'cvslog.*', 'tags', 'TAGS', '.make.state',
           '.nse_depinfo', '*~', '#*', '.#*', ',*',
           '_$*', '*$', '*.old', '*.bak', '*.BAK',
           '*.orig', '*.rej', '.del-*', '*.a', '*.olb',
           '*.o', '*.obj', '*.so', '*.exe', '*.Z', 
           '*.elc', '*.ln', 'core']

while diridx < len (dirs):
    sabs, srel, babs, brel = dirs[diridx]

    # Increment the counter here so we can "continue" with
    # impunity through the rest of the loop.

    diridx += 1

    # Load up the list of patterns in the .cvsignore file, 
    # if it exists.

    patterns = []
    fn = join (sabs, '.cvsignore')

    if exists (fn):
        f = file (fn, 'r')
        for l in f:
            l = l.strip ()
            if len (l) < 1: continue
            patterns.append (l)
    
    # Load up the list of files known to CVS in this 
    # directory

    entries = set ()
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
            entries.add (a[1])
        elif a[0] == '':
            # This entry represents a file that we should check
            # for ignoring.
            entries.add (a[1])
        # otherwise, ignore the line

    # Now the list of files that are in the builddir,
    # excluding ones in the CVS/Entries file

    built = []

    if isdir (babs):
        for fn in os.listdir (babs):
            if fn in entries:
                continue
            built.append (fn)

    # What is in built that isn't matched by an ignore glob?

    for fn in built:
        ignored = False

        for p in builtin:
            if fnmatch (fn, p):
                ignored = True
                break

        if not ignored:
            for p in patterns:
                if fnmatch (fn, p):
                    ignored = True
                    break

        if ignored: continue

        print brel + fn
        anysugg = True

# All done.

if anysugg:
    sys.exit (1)

sys.exit (0)
