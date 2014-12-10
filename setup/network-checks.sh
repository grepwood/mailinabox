function exit_due_to_ncat {
	echo
	echo "Outbound mail (port 25) seems to be blocked by your network."
	echo
	echo "You will not be able to send mail using this machine, so setup"
	echo "cannot continue."
	echo
	echo "Many residential networks block port 25 to prevent hijacked"
	echo "machines from being able to send spam. I just tried to connect"
	echo "to Google's mail server on port 25 but the connection did not"
	echo "succeed."
	echo
	exit 1
}
# Install the 'host', 'sed', and and 'nc' tools. This script is run before
# the rest of the system setup so we may not yet have things installed.
if [ "$DISTRO" = "Ubuntu" ]; then
	hide_output apt-get -y install bind9-host sed netcat-openbsd
elif [ "$DISTRO" = "RedHat" ]; then
	yum install bind-utils sed nc -y -q
fi

# Stop if the PRIMARY_HOSTNAME is listed in the Spamhaus Domain Block List.
# The user might have chosen a name that was previously in use by a spammer
# and will not be able to reliably send mail. Do this after any automatic
# choices made above.
if host $PRIMARY_HOSTNAME.dbl.spamhaus.org > /dev/null; then
	echo
	echo "The hostname you chose '$PRIMARY_HOSTNAME' is listed in the"
	echo "Spamhaus Domain Block List. See http://www.spamhaus.org/dbl/"
	echo "and http://www.spamhaus.org/query/domain/$PRIMARY_HOSTNAME."
	echo
	echo "You will not be able to send mail using this domain name, so"
	echo "setup cannot continue."
	echo
	exit 1
fi

# Stop if the IPv4 address is listed in the ZEN Spamhouse Block List.
# The user might have ended up on an IP address that was previously in use
# by a spammer, or the user may be deploying on a residential network. We
# will not be able to reliably send mail in these cases.
REVERSED_IPV4=$(echo $PUBLIC_IP | sed "s/\([0-9]*\).\([0-9]*\).\([0-9]*\).\([0-9]*\)/\4.\3.\2.\1/")
if host $REVERSED_IPV4.zen.spamhaus.org > /dev/null; then
	echo
	echo "The IP address $PUBLIC_IP is listed in the Spamhaus Block List."
	echo "See http://www.spamhaus.org/query/ip/$PUBLIC_IP."
	echo
	echo "You will not be able to send mail using this machine, so setup"
	echo "cannot continue."
	echo
	echo "Associate a different IP address with this machine if possible."
	echo "Many residential network IP addresses are listed, so Mail-in-a-Box"
	echo "typically cannot be used on a residential Internet connection."
	echo
	exit 1
fi

# Stop if we cannot make an outbound connection on port 25. Many residential
# networks block outbound port 25 to prevent their network from sending spam.
# See if we can reach one of Google's MTAs with a 5-second timeout.
# CentOS 7 comes with a version of netcat that behaves differently than that
# which is included in Ubuntu and CentOS 6. For that reason, we will install
# nmap.
GOOGLE="aspmx.l.google.com"
if [ "$DISTRO" = "RedHat" ] && [ "$DISTRO_VERSION" -ge "70" ]; then
	if [ "`rpm -qa nmap | wc -l`" -eq "0" ]; then
		yum install nmap -y -q
	fi
	if [ "`nmap --open -p 25 $GOOGLE 2>&1 | grep ^25\/tcp.*smtp$ | awk '{print $2}'`" != "open" ]; then
		exit_due_to_ncat
	fi
else
	if ! nc -z -w5 $GOOGLE 25; then
		exit_due_to_ncat
	fi
fi
