#!/bin/bash
# You sure you're on CentOS?
LATEST_PYZOR=`curl https://pypi.python.org/pypi/pyzor/ 2>/dev/null | grep "<td><a\ href=\"\/pypi\/pyzor\/" | head -n1 | sed 's/.*nbsp;//' | sed 's/<\/a><\/td>$//'`
REAL_PWD=`pwd`
cd /tmp
curl -O https://pypi.python.org/packages/source/p/pyzor/pyzor-$LATEST_PYZOR.tar.gz
tar -xf pyzor-$LATEST_PYZOR.tar.gz
cd pyzor-$LATEST_PYZOR
$PYTHON setup.py install 2>&1 1>/dev/null
cd $REAL_PWD
rm -rf /tmp/pyzor-$LATEST_PYZOR{,.tar.gz}
