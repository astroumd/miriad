#! /bin/sh

echo "Initializing build scripts ..."
aclocal
autoheader
libtoolize --force --copy
automake --force --copy --add-missing
autoconf

(cd borrow/pgplot && ./autogen.sh)

echo "Now run 'configure' to generate a Makefile."
