#!/bin/bash
# OpenDKIM
# --------
#
# OpenDKIM provides a service that puts a DKIM signature on outbound mail.
#
# The DNS configuration for DKIM is done in the management daemon.

source setup/functions.sh # load our functions
source /etc/mailinabox.conf # load global vars

# Install DKIM...
if [ "$DISTRO" = "Ubuntu" ]; then
	apt_install opendkim opendkim-tools
elif [ "$DISTRO" = "RedHat" ]; then
	if [ "`rpm -qa epel-release | wc -l`" -eq "0" ]; then
		if [ "$DISTRO_VERSION" -lt "70" ]; then
			rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm 2>/dev/null
		elif [ "$DISTRO_VERSION" -ge "70" ]; then
			rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-2.noarch.rpm 2>/dev/null
		fi
	fi
	yum install opendkim --enablerepo=epel -y -q
fi

# Make sure configuration directories exist.
mkdir -p /etc/opendkim;
mkdir -p $STORAGE_ROOT/mail/dkim

# Used in InternalHosts and ExternalIgnoreList configuration directives.
# Not quite sure why.
echo "127.0.0.1" > /etc/opendkim/TrustedHosts

if grep -q "ExternalIgnoreList" /etc/opendkim.conf; then
	true # already done #NODOC
else
	# Add various configuration options to the end of `opendkim.conf`.
	cat >> /etc/opendkim.conf << EOF;
MinimumKeyBits          1024
ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable
Socket                  inet:8891@localhost
RequireSafeKeys         false
EOF
fi

# Create a new DKIM key. This creates
# mail.private and mail.txt in $STORAGE_ROOT/mail/dkim. The former
# is the actual private key and the latter is the suggested DNS TXT
# entry which we'll want to include in our DNS setup.
if [ ! -f "$STORAGE_ROOT/mail/dkim/mail.private" ]; then
	# Should we specify -h rsa-sha256?
	opendkim-genkey -r -s mail -D $STORAGE_ROOT/mail/dkim
fi

# Ensure files are owned by the opendkim user and are private otherwise.
chown -R opendkim:opendkim $STORAGE_ROOT/mail/dkim
chmod go-rwx $STORAGE_ROOT/mail/dkim

# Add OpenDKIM as a milter to postfix, which is how it intercepts outgoing
# mail to perform the signing (by adding a mail header).
# Be careful. If we add other milters later, it needs to be concatenated on the smtpd_milters line. #NODOC
tools/editconf.py /etc/postfix/main.cf \
	smtpd_milters=inet:127.0.0.1:8891 \
	non_smtpd_milters=\$smtpd_milters \
	milter_default_action=accept

# Restart services.
restart_service opendkim
restart_service postfix

