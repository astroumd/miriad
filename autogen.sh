#!/bin/bash

if test "x$LIBTOOLIZE" = x; then
  export LIBTOOLIZE=libtoolize
  # Determine if this is Mac OS X and react appropriately...
  if test -x /usr/bin/glibtoolize; then
    export LIBTOOLIZE=glibtoolize
  fi 
fi

echo "Initializing build scripts ..."
aclocal -I src/sys/auto
if [ $? -ne 0 ]; then
  echo "ERROR - Exiting..."
  exit 1
fi
autoheader
if [ $? -ne 0 ]; then
  echo "ERROR - Exiting..."
  exit 1
fi
$LIBTOOLIZE --force --copy
if [ $? -ne 0 ]; then
  echo "ERROR - Exiting..."
  exit 1
fi
automake --force --copy --add-missing
if [ $? -ne 0 ]; then
  echo "ERROR - Exiting..."
  exit 1
fi
autoconf
if [ $? -ne 0 ]; then
  echo "ERROR - Exiting..."
  exit 1
fi

(cd borrow/pgplot && ./autogen.sh)

echo "Now run 'configure' to generate a Makefile."
