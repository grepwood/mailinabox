#!/bin/bash
# You're meant to run this only if you're CentOS

LATEST_UFW=`curl https://launchpad.net/ufw 2>/dev/null | grep Latest\ version\ is | awk '{print $4}'`
cd /tmp
curl -LO https://launchpad.net/ufw/$LATEST_UFW/$LATEST_UFW/+download/ufw-$LATEST_UFW.tar.gz 2>/dev/null
cd ufw-$LATEST_UFW
yum install iptables-ipv6 -y -q
python setup.py install
cd /tmp
rm -rf ufw-$LATEST_UFW{,.tar.gz}
