#!/bin/bash
# You're meant to run this only if you're CentOS
OPENRESOLV_URL=`curl http://roy.marples.name/projects/openresolv/index 2>/dev/null | tr -d '\r' | grep ftp | sed 's/<\/a>//' | sed 's/^.*\">//'`
OPENRESOLV_TARBALL=`echo $OPENRESOLV_URL | sed 's/^.*\///'`
OPENRESOLV_DIR=`echo $OPENRESOLV_TARBALL | sed 's/\.tar.*$//'`
REAL_PWD=`pwd`
cd /tmp
curl -O $OPENRESOLV_URL
if [ "`rpm -qa bzip2 | wc -l`" -ne "1" ]; then
	yum install bzip2 -y -q
fi
tar -xf $OPENRESOLV_TARBALL
cd $OPENRESOLV_DIR
./configure 2>&1 1>/dev/null
make install 2>&1 1>/dev/null
cd $REAL_PWD
rm -rf /tmp/$OPENRESOLV_DIR /tmp/$OPENRESOLV_TARBALL
