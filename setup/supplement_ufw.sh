#!/bin/bash
# You're meant to run this only if you're CentOS

LATEST_UFW=`curl https://launchpad.net/ufw 2>/dev/null | grep Latest\ version\ is | awk '{print $4}'`
REAL_PWD=`pwd`
cd /tmp
curl -LO https://launchpad.net/ufw/$LATEST_UFW/$LATEST_UFW/+download/ufw-$LATEST_UFW.tar.gz 2>/dev/null
tar -xf ufw-$LATEST_UFW.tar.gz
cd ufw-$LATEST_UFW
if [ "`rpm -qa iptables-ipv6 | wc -l`" -eq "0" ]; then
	yum install iptables-ipv6 -y -q
fi
$PYTHON setup.py install 2>&1 1>/dev/null
cd $REAL_PWD
rm -rf /tmp/ufw-$LATEST_UFW{,.tar.gz}
chmod 644 /etc/default/ufw /etc/ufw/ufw.conf /etc/ufw/applications.d/ufw-*
chmod 755 /lib/ufw/ufw-init /usr/sbin/ufw
