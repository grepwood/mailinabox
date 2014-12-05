# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root. Please re-run like this:"
	echo
	echo "sudo $0"
	echo
	exit
fi

source setup/distro_support.sh
detect_distro

# Check that we are running on Ubuntu 14.04 LTS (or 14.04.xx).
if [ "$DISTRO" = "Ubuntu" ]; then
	if [ "`lsb_release -d | sed 's/.*:\s*//' | sed 's/14\.04\.[0-9]/14.04/' `" != "Ubuntu 14.04 LTS" ]; then
		echo "Mail-in-a-Box only supports being installed on Ubuntu 14.04, sorry. You are running:"
		echo
		lsb_release -d | sed 's/^.*:\s*//'
		echo
		echo "We can't write scripts that run on every possible setup, sorry."
		exit
	fi
elif [ "$DISTRO" = "RedHat" ]; then
	CENTOS_VERSION=`lsb_release -d | sed 's/^.*:\s*//' | sed 's/\.[0-9]\ (Final)$//'`
	if [ "$CENTOS_VERSION" != "CentOS release 6" ] && [ "$CENTOS_VERSION" != "CentOS release 7" ]; then
		echo "Mail-in-a-Box only supports being installed on CentOS 6 and 7, sorry. You are running:"
		echo
		lsb_release -d | sed 's/^.*:\s*//'
		echo
		echo "We can't write scripts that run on every possible setup, sorry."
		exit
	fi
fi

# Check that we have enough memory. Skip the check if we appear to be
# running inside of Vagrant, because that's really just for testing.
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
if [ $TOTAL_PHYSICAL_MEM -lt 786432 ]; then
if [ ! -d /vagrant ]; then
	echo "Your Mail-in-a-Box needs more than $TOTAL_PHYSICAL_MEM MB RAM."
	echo "Please provision a machine with at least 768 MB, 1 GB recommended."
	exit
fi
fi
