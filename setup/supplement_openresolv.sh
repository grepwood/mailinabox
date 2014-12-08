#!/bin/bash
# You're meant to run this only if you're CentOS
OPENRESOLV_URL=`curl http://roy.marples.name/projects/openresolv/index 2>/dev/null | grep ftp | sed 's/<\/a>//' | sed 's/^.*\">//'`
OPENRESOLV_TARBALL=`echo $OPENRESOLV_URL | sed 's/.*\///'`
OPENRESOLV_DIR=`echo $OPENRESOLV_TARBALL | sed 's/\.tar.*$//'`

cd /tmp
curl -O $OPENRESOLV_URL
if [ "`rpm -qa bzip2 | wc -l`" -ne "1" ]; then
	yum install bzip2 -y -q
fi
tar -xf $OPENRESOLV_TARBALL
cd $OPENRESOLV_DIR
./configure
make install
cd /tmp
rm -rf $OPENRESOLV_DIR $OPENRESOLV_TARBALL
