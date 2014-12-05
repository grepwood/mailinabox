#!/bin/bash
#########################################################
# This script is intended to be run like this:
#
#   curl https://.../bootstrap.sh | sudo bash
#
#########################################################

if [ -z "$TAG" ]; then
	TAG="v0.05"
fi

# Are we running as root?
if [ "`whoami`" != "root" ]; then
	echo "This script must be run as root. Did you leave out sudo?"
	exit
fi

DISTRO=""
SATISFIED=0

function prepare_crossdistro {
	if command -v 2>&1 1>/dev/null; then
		DISTRO="RedHat"
		SATISFIED=1
		if [ "`rpm -qa redhat-lsb | wc -l`" -eq "0" ]; then
			yum install redhat-lsb -y -q
		fi
	elif command -v apt-get 2>&1 1>/dev/null; then
		DISTRO="Ubuntu"
		SATISFIED=1
	else
		echo "Your distro is not supported"
		exit
	fi
}

function detect_distro {
	if command -v 2>&1 1>/dev/null; then
		DISTRO="RedHat"
		SATISFIED=1
	elif command -v apt-get 2>&1 1>/dev/null; then
		DISTRO="Ubuntu"
		SATISFIED=1
	else
		echo "Your distro is not supported"
		exit
	fi
}

prepare_crossdistro
if [ "$DISTRO" == "Ubuntu" ]; then
	apt-get -q -q install -y git < /dev/null
elif [ "$DISTRO" == "RedHat" ]; then
	yum install git -y -q
fi

# Clone the Mail-in-a-Box repository if it doesn't exist.
if [ ! -d $HOME/mailinabox ]; then
	echo Installing git . . .
	if [ "$DISTRO" == "RedHat" ]; then
		CENTOS_FRONTEND=yum install git -y -q
	elif [ "$DISTRO" == "Ubuntu" ]; then
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
	else
		exit
	fi
	echo

	echo Downloading Mail-in-a-Box $TAG. . .
#	git clone \
#		-b $TAG --depth 1 \
#		https://github.com/grepwood/mailinabox \
#		$HOME/mailinabox \
#		< /dev/null 2> /dev/null

	echo
fi

# Change directory to it.
cd $HOME/mailinabox

# Update it.
#if [ "$TAG" != `git describe` ]; then
#	echo Updating Mail-in-a-Box to $TAG . . .
#	git fetch --depth 1 --force --prune origin tag $TAG
#	if ! git checkout -q $TAG; then
#		echo "Update failed. Did you modify something in `pwd`?"
#		exit
#	fi
#	echo
#fi

# Start setup script.
setup/start.sh

