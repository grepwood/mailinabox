DISTRO=""
DISTRO_VERSION=0
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
	DISTRO_VERSION=`lsb_release -r | awk '{print $2}' | sed -e 's:\.:\ :g' | awk '{print $1$2}'`
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
	DISTRO_VERSION=`lsb_release -r | awk '{print $2}' | sed -e 's:\.:\ :g' | awk '{print $1$2}'`
}
