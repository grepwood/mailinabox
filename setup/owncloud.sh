#!/bin/bash
# Owncloud
##########################

source setup/functions.sh # load our functions
source /etc/mailinabox.conf # load global vars

# ### Installing ownCloud
if [ "$DISTRO" = "Ubuntu" ]; then
	apt_install \
		dbconfig-common \
		php5-cli php5-sqlite php5-gd php5-imap php5-curl php-pear php-apc curl \
		libapr1 libtool libcurl4-openssl-dev php-xml-parser \
		php5 php5-dev php5-gd php5-fpm memcached php5-memcache unzip

	apt-get purge -qq -y owncloud*
	PHP="php"
elif [ "$DISTRO" = "RedHat" ]; then
	yum install php55-php-{mbstring,pdo,cli,pear,xml,fpm,gd,imap,pecl-{memcache,sqlite}} \
		curl apr libtool libcurl-devel php55 memcached unzip -y -q --enablerepo=remi,remi-php55 >/dev/null
	if [ "`/opt/remi/php55/root/bin/pear list | grep ^Net_IMAP | wc -l`" -eq "0" ]; then
		/opt/remi/php55/root/bin/pear install pear/Net_IMAP
	fi
	PHP="php55"
fi
# Install ownCloud from source of this version:
owncloud_ver=7.0.3
# Check if ownCloud dir exist, and check if version matches owncloud_ver (if either doesn't - install/upgrade)
if [ ! -d /usr/local/lib/owncloud/ ] \
	|| ! grep -q $owncloud_ver /usr/local/lib/owncloud/version.php; then

	echo installing ownCloud...
	rm -rf /tmp/owncloud.zip /usr/local/lib/owncloud
	wget -qO /tmp/owncloud.zip https://download.owncloud.org/community/owncloud-$owncloud_ver.zip
	unzip -u -o -q /tmp/owncloud.zip -d /usr/local/lib #either extracts new or replaces current files
	hide_output $PHP /usr/local/lib/owncloud/occ upgrade #if OC is up-to-date it wont matter
	rm -f /tmp/owncloud.zip
	echo "breakpoint"
fi

# ### Configuring ownCloud

# Setup ownCloud if the ownCloud database does not yet exist. Running setup when
# the database does exist wipes the database and user data.
if [ ! -f $STORAGE_ROOT/owncloud/owncloud.db ]; then
	# Create a configuration file.
	if [ -f "/etc/timezone" ] || [ "`cat /etc/timezone`" = "" ]; then
		tzselect > /etc/timezone
	fi
	TIMEZONE=$(cat /etc/timezone)
	instanceid=oc$(echo $PRIMARY_HOSTNAME | sha1sum | fold -w 10 | head -n 1)
	cat > /usr/local/lib/owncloud/config/config.php <<EOF;
<?php
\$CONFIG = array (
  'datadirectory' => '$STORAGE_ROOT/owncloud',

  'instanceid' => '$instanceid',

  'trusted_domains' => 
    array (
      0 => '$PRIMARY_HOSTNAME',
    ),
  'forcessl' => true, # if unset/false, ownCloud sends a HSTS=0 header, which conflicts with nginx config

  'overwritewebroot' => '/cloud',
  'user_backends' => array(
    array(
      'class'=>'OC_User_IMAP',
      'arguments'=>array('{localhost:993/imap/ssl/novalidate-cert}')
    )
  ),
  "memcached_servers" => array (
    array('localhost', 11211),
  ),
  'mail_smtpmode' => 'sendmail',
  'mail_smtpsecure' => '',
  'mail_smtpauthtype' => 'LOGIN',
  'mail_smtpauth' => false,
  'mail_smtphost' => '',
  'mail_smtpport' => '',
  'mail_smtpname' => '',
  'mail_smtppassword' => '',
  'mail_from_address' => 'owncloud',
  'mail_domain' => '$PRIMARY_HOSTNAME',
  'logtimezone' => '$TIMEZONE',
);
?>
EOF
#	elif [ "$DISTRO" = "RedHat" ]; then
#		cat > /usr/local/lib/owncloud/config/config.php <<EOF;
#<?php
#\$CONFIG = array (
#  'datadirectory' => '$STORAGE_ROOT/owncloud',
#
#  'instanceid' => '$instanceid',
#
#  'trusted_domains' => 
#    array (
#      0 => '$PRIMARY_HOSTNAME',
#    ),
#  'forcessl' => true, # if unset/false, ownCloud sends a HSTS=0 header, which conflicts with nginx config
#
#  'overwritewebroot' => '/cloud',
#  'user_backends' => array(
#    array(
#      'class'=>'OC_User_IMAP',
#      'arguments'=>array('{localhost:993/imap/ssl/novalidate-cert}')
#    )
#  ),
#  "memcached_servers" => array (
#    array('localhost', 11211),
#  ),
#  'mail_smtpmode' => 'sendmail',
#  'mail_smtpsecure' => '',
#  'mail_smtpauthtype' => 'LOGIN',
#  'mail_smtpauth' => false,
#  'mail_smtphost' => '',
#  'mail_smtpport' => '',
#  'mail_smtpname' => '',
#  'mail_smtppassword' => '',
#  'mail_from_address' => 'owncloud',
#  'mail_domain' => '$PRIMARY_HOSTNAME',
#);
#?>
#EOF
#	fi
	# Create an auto-configuration file to fill in database settings
	# when the install script is run. Make an administrator account
	# here or else the install can't finish.
	adminpassword=$(dd if=/dev/random bs=1 count=40 2>/dev/null | sha1sum | fold -w 30 | head -n 1)
	cat > /usr/local/lib/owncloud/config/autoconfig.php <<EOF;
<?php
\$AUTOCONFIG = array (
  # storage/database
  'directory' => '$STORAGE_ROOT/owncloud',
  'dbtype' => 'sqlite3',

  # create an administrator account with a random password so that
  # the user does not have to enter anything on first load of ownCloud
  'adminlogin'    => 'root',
  'adminpass'     => '$adminpassword',
);
?>
EOF

	# Create user data directory and set permissions
	mkdir -p $STORAGE_ROOT/owncloud
	chown -R www-data.www-data $STORAGE_ROOT/owncloud /usr/local/lib/owncloud
	# Execute ownCloud's setup step, which creates the ownCloud sqlite database.
	# It also wipes it if it exists. And it deletes the autoconfig.php file.
	echo "breakpoint 2"
	(cd /usr/local/lib/owncloud; cp autoconfig.php backup.autoconfig.php;)
	(cd /usr/local/lib/owncloud; sudo -u www-data $PHP /usr/local/lib/owncloud/index.php;)
fi
# Enable/disable apps. Note that this must be done after the ownCloud setup.
# The firstrunwizard gave Josh all sorts of problems, so disabling that.
# user_external is what allows ownCloud to use IMAP for login.
hide_output $PHP /usr/local/lib/owncloud/console.php app:disable firstrunwizard
hide_output $PHP /usr/local/lib/owncloud/console.php app:enable user_external
# Set PHP FPM values to support large file uploads
# (semicolon is the comment character in this file, hashes produce deprecation warnings)
# However on CentOS that file is located elsewhere!
if [ "$DISTRO" = "Ubuntu" ]; then
	PHP_INI="/etc/php5/fpm/php.ini"
elif [ "$DISTRO" = "RedHat" ]; then
	PHP_INI="/opt/remi/php55/root/etc/php.ini"
fi
$PYTHON tools/editconf.py $PHP_INI -c ';' \
	upload_max_filesize=16G \
	post_max_size=16G \
	output_buffering=16384 \
	memory_limit=512M \
	max_execution_time=600 \
	short_open_tag=On

# Set up a cron job for owncloud.
if [ ! -d "/etc/cron.hourly" ]; then mkdir /etc/cron.hourly; fi
cat > /etc/cron.hourly/mailinabox-owncloud << EOF;
#!/bin/bash
# Mail-in-a-Box
sudo -u www-data $PHP -f /usr/local/lib/owncloud/cron.php
EOF
chmod +x /etc/cron.hourly/mailinabox-owncloud

# There's nothing much of interest that a user could do as an admin for ownCloud,
# and there's a lot they could mess up, so we don't make any users admins of ownCloud.
# But if we wanted to, we would do this:
# ```
# for user in $(tools/mail.py user admins); do
#	 sqlite3 $STORAGE_ROOT/owncloud/owncloud.db "INSERT OR IGNORE INTO oc_group_user VALUES ('admin', '$user')"
# done
# ```

# Enable PHP modules and restart PHP.
if [ "$DISTRO" = "Ubuntu" ]; then
	php5enmod imap
	restart_service php5-fpm
elif [ "$DISTRO" = "RedHat" ]; then
	cp /opt/remi/php55/root/usr/share/doc/php55-php-fpm-5.5.*/php-fpm.conf.default /opt/remi/php55/root/etc/php-fpm.d/www.conf
	restart_service php55-php-fpm
fi
