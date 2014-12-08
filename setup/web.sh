#!/bin/bash
# HTTP: Turn on a web server serving static files
#################################################

source setup/functions.sh # load our functions
source /etc/mailinabox.conf # load global vars

# Some Ubuntu images start off with Apache. Remove it since we
# will use nginx. Use autoremove to remove any Apache depenencies.
# Same goes for some RHEL/CentOS images.
if [ "$DISTRO" = "Ubuntu" ]; then
	if [ -f /usr/sbin/apache2 ]; then
		echo Removing apache...
		hide_output apt-get -y purge apache2 apache2-*
		hide_output apt-get -y --purge autoremove
	fi
elif [ "$DISTRO" = "RedHat" ]; then
	if [ "`rpm -qa httpd | wc -l`" -eq "1" ]; then
		printf "Removing apache... "
		yum remove httpd -y -q
		echo "done!"
	fi
fi

# Install nginx and a PHP FastCGI daemon.
#
# Turn off nginx's default website.
if [ "$DISTRO" = "Ubuntu" ]; then
	apt_install nginx php5-fpm
elif [ "$DISTRO" = "RedHat" ]; then
	if [ "`rpm -qa nginx-release-centos | wc -l`" -eq "0" ]; then
		if [ "$DISTRO_VERSION" -lt "70" ]; then
			rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm 2>/dev/null
		elif [ "$DISTRO_VERSION" -ge "70" ]; then
			rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm 2>/dev/null
		fi
	fi
	if [ "`rpm -qa remi-release | wc -l`" -eq "0" ]; then
		if [ "$DISTRO_VERSION" -lt "70" ]; then
			rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm 2>/dev/null
		elif [ "$DISTRO_VERSION" -ge "70" ]; then
			rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm 2>/dev/null
		fi
	fi
	yum install nginx php55-php-fpm --enablerepo=nginx,remi,remi-php55 -y -q
fi

rm -f /etc/nginx/sites-enabled/default

# Copy in a nginx configuration file for common and best-practices
# SSL settings from @konklone. Replace STORAGE_ROOT so it can find
# the DH params.
sed "s#STORAGE_ROOT#$STORAGE_ROOT#" \
	conf/nginx-ssl.conf > /etc/nginx/nginx-ssl.conf

# Fix some nginx defaults.
# The server_names_hash_bucket_size seems to prevent long domain names?
tools/editconf.py /etc/nginx/nginx.conf -s \
	server_names_hash_bucket_size="64;"

# Bump up PHP's max_children to support more concurrent connections
tools/editconf.py /etc/php5/fpm/pool.d/www.conf -c ';' \
	pm.max_children=8

# Other nginx settings will be configured by the management service
# since it depends on what domains we're serving, which we don't know
# until mail accounts have been created.

# Create the iOS/OS X Mobile Configuration file which is exposed via the
# nginx configuration at /mailinabox-mobileconfig.
mkdir -p /var/lib/mailinabox
chmod a+rx /var/lib/mailinabox
cat conf/ios-profile.xml \
	| sed "s/PRIMARY_HOSTNAME/$PRIMARY_HOSTNAME/" \
	| sed "s/UUID1/$(cat /proc/sys/kernel/random/uuid)/" \
	| sed "s/UUID2/$(cat /proc/sys/kernel/random/uuid)/" \
	| sed "s/UUID3/$(cat /proc/sys/kernel/random/uuid)/" \
	| sed "s/UUID4/$(cat /proc/sys/kernel/random/uuid)/" \
	 > /var/lib/mailinabox/mobileconfig.xml
chmod a+r /var/lib/mailinabox/mobileconfig.xml

# make a default homepage
if [ -d $STORAGE_ROOT/www/static ]; then mv $STORAGE_ROOT/www/static $STORAGE_ROOT/www/default; fi # migration #NODOC
mkdir -p $STORAGE_ROOT/www/default
if [ ! -f $STORAGE_ROOT/www/default/index.html ]; then
	cp conf/www_default.html $STORAGE_ROOT/www/default/index.html
fi
chown -R $STORAGE_USER $STORAGE_ROOT/www

# We previously installed a custom init script to start the PHP FastCGI daemon. #NODOC
# Remove it now that we're using php5-fpm. #NODOC
if [ "$DISTRO" = "Ubuntu" ]; then
	if [ -L /etc/init.d/php-fastcgi ]; then
		echo "Removing /etc/init.d/php-fastcgi, php5-cgi..." #NODOC
		rm -f /etc/init.d/php-fastcgi #NODOC
		hide_output update-rc.d php-fastcgi remove #NODOC
		apt-get -y purge php5-cgi #NODOC
	fi
fi

# Remove obsoleted scripts. #NODOC
# exchange-autodiscover is now handled by Z-Push. #NODOC
for f in webfinger exchange-autodiscover; do #NODOC
	rm -f /usr/local/bin/mailinabox-$f.php #NODOC
done #NODOC

# Start services.
restart_service nginx
if [ "$DISTRO" = "Ubuntu" ]; then
	restart_service php5-fpm
elif [ "$DISTRO" = "RedHat" ]; then
	restart_service php55-php-fpm
fi

# Open ports.
ufw_allow http
ufw_allow https

