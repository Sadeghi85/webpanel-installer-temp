#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
ARCH=$(arch)
HOME=/var/www/WebPanel
MYSQL_ROOT_PSSWD="WebPanel"

HOME=${HOME%/}
if [[ $HOME == "" ]]; then
	echo "Home directory can't be '/' itself."
	exit 1
fi

# check if webpanel is already installed
if [[ -f /etc/default/webpanel ]]; then
	echo "WebPanel is already installed."
	exit 1
fi

# Allow only root execution
if (( $(id -u) != 0 )); then
	echo "This script requires root privileges"
	exit 1
fi

################## temporarily disable SELinux
setenforce 0

################## unistall mysql for conflicts
rpm -e --nodeps $(rpm -qa | grep '^mysql')
\mv /var/lib/mysql /var/lib/mysql.old
################## unistall memcached
rpm -e --nodeps $(rpm -qa | grep '^memcached')
################## unistall webalizer
rpm -e --nodeps $(rpm -qa | grep '^webalizer')
\mv /etc/webalizer.d/settings /etc/webalizer.d/settings.old
################## unistall php
rpm -e --nodeps $(rpm -qa | grep '^php')
\mv /etc/php-fpm.d/settings /etc/php-fpm.d/settings.old
################## unistall apache
rpm -e --nodeps $(rpm -qa | grep '^httpd')
\mv /etc/httpd/settings /etc/httpd/settings.old
\mv /var/www /var/www.old
################## unistall nginx
rpm -e --nodeps $(rpm -qa | grep '^nginx')
\mv /etc/nginx/settings /etc/nginx/settings.old
################## unistall vsftpd
rpm -e --nodeps $(rpm -qa | grep '^vsftpd')
\mv /etc/vsftpd/settings /etc/vsftpd/settings.old
################## unistall bind
rpm -e --nodeps $(rpm -qa | grep '^bind')
################## unistall exim
rpm -e --nodeps $(rpm -qa | grep '^exim')
################## unistall rpmforge-release
rpm -e --nodeps $(rpm -qa | grep '^rpmforge-release')
################## unistall epel-release
rpm -e --nodeps $(rpm -qa | grep '^epel-release')


################## repos
\cp "$SCRIPT_DIR/repos/CentOS-Base.repo" /etc/yum.repos.d/CentOS-Base.repo
\cp "$SCRIPT_DIR/repos/epel.repo" /etc/yum.repos.d/epel.repo
\cp "$SCRIPT_DIR/repos/macros.ghc-srpm" /etc/rpm/macros.ghc-srpm
\cp "$SCRIPT_DIR/repos/ius.repo" /etc/yum.repos.d/ius.repo
\cp "$SCRIPT_DIR/repos/ius-archive.repo" /etc/yum.repos.d/ius-archive.repo
\cp "$SCRIPT_DIR/repos/nginx.repo" /etc/yum.repos.d/nginx.repo
\cp "$SCRIPT_DIR/repos/rpmforge.repo" /etc/yum.repos.d/rpmforge.repo

################# yum plugins
# yum -y install yum-plugin-priorities yum-plugin-rpm-warm-cache yum-plugin-local yum-plugin-replace yum-plugin-remove-with-leaves yum-plugin-show-leaves yum-utils

#installing packages
# yum -y install mod_rpaf-0.6-2.el6.i686.rpm mod-pagespeed-stable_current_i386.rpm
# yum -y install iftop iotop bind-utils bind-chroot bind htop nmap openssh-clients httpd php54 php54-bcmath php54-cli php54-common php54-fpm php54-gd php54-intl php54-mbstring php54-mcrypt php54-mysqlnd php54-odbc php54-pdo php54-pear php54-pecl-memcached php54-pecl-zendopcache php54-tidy php54-xml perl-Net-SSLeay mod_fastcgi nginx webalizer vsftpd man net-snmp mail memcached rsync wget exim
# yum -y install mysql

#installing mysql55
# yum -y replace mysql --replace-with mysql55
# yum -y install mysql55-server

# installing packages
# "rpm -U --force" is identixcal to "rpm -U --replacefiles --replacepkgs --oldpackage"
touch /etc/default/mod-pagespeed
rpm -Uvh --replacefiles --replacepkgs --oldpackage --nodeps  $(find "$SCRIPT_DIR/packages/$ARCH" -name "*" | grep -e \.rpm$)
if (( $? != 0 )); then
	echo "Couldn't install packages."
	exit 1
fi

# update operating system
yum clean all
yum -y update

################## server configs
\cp /etc/selinux/config /etc/selinux/config.bak
\cp "$SCRIPT_DIR/settings/selinux/config" /etc/selinux/config

\cp /etc/yum.conf /etc/yum.conf.bak
\cp "$SCRIPT_DIR/settings/yum/yum.conf" /etc/yum.conf

\cp /etc/pam.d/su /etc/pam.d/su.bak
\cp "$SCRIPT_DIR/settings/pam.d/su" /etc/pam.d/su

\cp /etc/sudoers /etc/pam.d/sudoers.bak
\cp "$SCRIPT_DIR/settings/sudoers/sudoers" /etc/sudoers

\cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
\cp "$SCRIPT_DIR/settings/ssh/sshd_config" /etc/ssh/sshd_config
service sshd restart

# Quota
# TMP_DIR="/$HOME"
# QUOTA_DIR=""
# QUOTA_DIR_ESC=""
# while [[ $TMP_DIR != "" ]]
# do
	# if [[ $TMP_DIR != "/" ]]; then
		# QUOTA_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^\/(.+)$/\1/");
	# else
		# QUOTA_DIR="/"
	# fi
	
	# if grep -qs " $QUOTA_DIR " /proc/mounts; then
		# QUOTA_DIR_ESC=$(sed 's/[\*\.&\/]/\\&/g' <<<"$QUOTA_DIR")
		# sed -i -r -e"s/( $QUOTA_DIR_ESC .*?defaults)/\1,usrjquota=aquota\.user,grpjquota=aquota\.group,jqfmt=vfsv0/I" /etc/fstab
		# mount -o remount "$QUOTA_DIR" 1>/dev/null
		# break
	# fi
	
	# TMP_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^(.*)\/.*?$/\1/")
# done

# quotacheck -avugm 1>/dev/null 2>/dev/null
# quotaon -avug 1>/dev/null 2>/dev/null

# echo -e "#!/bin/bash\ntouch /forcequotacheck" > /etc/cron.weekly/forcequotacheck
# chmod 755 /etc/cron.weekly/forcequotacheck

################# config after install
chmod 750 $(find "$SCRIPT_DIR/../cmd" -name "*" | grep \.sh$)

# web
mkdir -p "$HOME/sites-available"
mkdir -p "$HOME/sites-enabled"
mkdir -p "$HOME/sites-available-for-humans"
mkdir -p "$HOME/sites-enabled-for-humans"

# Apache
\mv /usr/lib/cgi-bin /usr/lib/cgi-bin.old
mkdir -p /usr/lib/cgi-bin
mkdir -p /etc/httpd/settings/sites-available
mkdir -p /etc/httpd/settings/sites-enabled
mkdir -p /etc/httpd/settings/sites-available-for-humans
mkdir -p /etc/httpd/settings/sites-enabled-for-humans
\cp /var/www/error/noindex.html /var/www/html/index.html
\cp /usr/share/pixmaps/poweredby.png /var/www/icons/powered_by_rh.png
\mv /etc/httpd/conf.d/php.conf /etc/httpd/conf.d/php.conf.disabled
\mv /etc/httpd/conf.d/perl.conf /etc/httpd/conf.d/perl.conf.disabled
\mv /etc/httpd/conf.d/ruby.conf /etc/httpd/conf.d/ruby.conf.disabled
\mv /etc/httpd/conf.d/squid.conf /etc/httpd/conf.d/squid.conf.disabled
\mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled
\mv /etc/httpd/conf.d/webalizer.conf /etc/httpd/conf.d/webalizer.conf.disabled
\mv /etc/httpd/conf.d/wsgi.conf /etc/httpd/conf.d/wsgi.conf.disabled

\cp /etc/sysconfig/httpd /etc/sysconfig/httpd.bak
\cp "$SCRIPT_DIR/settings/apache/httpd" /etc/sysconfig/httpd

\cp /etc/httpd/conf.d/fastcgi.conf /etc/httpd/conf.d/fastcgi.conf.bak
\cp "$SCRIPT_DIR/settings/apache/fastcgi.conf" /etc/httpd/conf.d/fastcgi.conf

\cp /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.bak
\cp "$SCRIPT_DIR/settings/apache/welcome.conf" /etc/httpd/conf.d/welcome.conf

\cp "$SCRIPT_DIR/settings/apache/deflate.conf.disabled" /etc/httpd/conf.d/deflate.conf.disabled
\cp "$SCRIPT_DIR/settings/apache/expires.conf.disabled" /etc/httpd/conf.d/expires.conf.disabled
\cp "$SCRIPT_DIR/settings/apache/rpaf.conf" /etc/httpd/conf.d/rpaf.conf
\cp "$SCRIPT_DIR/settings/apache/php-fpm.conf.disabled" /etc/httpd/conf.d/php-fpm.conf.disabled

\cp /etc/httpd/conf.d/pagespeed.conf /etc/httpd/conf.d/pagespeed.conf.bak
if [[ $ARCH == "i686" ]]; then
	\cp "$SCRIPT_DIR/settings/apache/pagespeed.conf.i686" /etc/httpd/conf.d/pagespeed.conf
else
	\cp "$SCRIPT_DIR/settings/apache/pagespeed.conf.x86_64" /etc/httpd/conf.d/pagespeed.conf
fi

\cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
\cp "$SCRIPT_DIR/settings/apache/httpd.conf" /etc/httpd/conf/httpd.conf

# PHP-FPM
chmod 777 /var/lib/php/session
mkdir -p /etc/php-fpm.d/settings/sites-available
mkdir -p /etc/php-fpm.d/settings/sites-enabled
mkdir -p /etc/php-fpm.d/settings/sites-available-for-humans
mkdir -p /etc/php-fpm.d/settings/sites-enabled-for-humans

\mv /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.bak
\cp "$SCRIPT_DIR/settings/php-fpm/server.conf" /etc/php-fpm.d/server.conf

\cp /etc/php-fpm.conf /etc/php-fpm.conf.bak
\cp "$SCRIPT_DIR/settings/php-fpm/php-fpm.conf" /etc/php-fpm.conf

# PHP
\cp /etc/php.ini /etc/php.ini.bak
\cp "$SCRIPT_DIR/settings/php/php.ini" /etc/php.ini

\cp /etc/php.d/opcache.ini /etc/php.d/opcache.ini.bak
if [[ $ARCH == "i686" ]]; then
	\cp "$SCRIPT_DIR/settings/php/opcache.ini.i686" /etc/php.d/opcache.ini
else
	\cp "$SCRIPT_DIR/settings/php/opcache.ini.x86_64" /etc/php.d/opcache.ini
fi

# Memcached
\cp /etc/sysconfig/memcached /etc/sysconfig/memcached.bak
\cp "$SCRIPT_DIR/settings/memcached/memcached" /etc/sysconfig/memcached

# Nginx
\mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled
\mv /etc/nginx/conf.d/example_ssl.conf /etc/nginx/conf.d/example_ssl.conf.disabled
mkdir -p /etc/nginx/settings/sites-available
mkdir -p /etc/nginx/settings/sites-enabled
mkdir -p /etc/nginx/settings/sites-available-for-humans
mkdir -p /etc/nginx/settings/sites-enabled-for-humans

\cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
\cp "$SCRIPT_DIR/settings/nginx/nginx.conf" /etc/nginx/nginx.conf
\cp "$SCRIPT_DIR/settings/nginx/nginx_default_server.conf" /etc/nginx/nginx_default_server.conf

# Webalizer & Logs schedules
chown root:apache /var/log/php-fpm
mkdir -p /etc/webalizer.d/settings/sites-available
mkdir -p /etc/webalizer.d/settings/sites-enabled
mkdir -p /etc/webalizer.d/settings/sites-available-for-humans
mkdir -p /etc/webalizer.d/settings/sites-enabled-for-humans

# Disabling default Logrotate & Webalizer schedules
\cp "$SCRIPT_DIR/settings/webalizer/00webalizer" /etc/cron.daily/00webalizer
\cp "$SCRIPT_DIR/settings/logrotate/httpd" /etc/logrotate.d/httpd
\cp "$SCRIPT_DIR/settings/logrotate/nginx" /etc/logrotate.d/nginx
\cp "$SCRIPT_DIR/settings/logrotate/php-fpm" /etc/logrotate.d/php-fpm

# Enabling WebPanel schedules
\cp "$SCRIPT_DIR/settings/schedules/webpanel-daily-schedules" /etc/cron.daily/webpanel-daily-schedules
chmod 755 /etc/cron.daily/webpanel-daily-schedules

# iptables
# iptables-save > /etc/sysconfig/iptables.bak
# iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT # Nginx
# iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 5000 -j ACCEPT # WebPanel
# iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 10000 -j ACCEPT # Webmin
# service iptables save
# service iptables restart
service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

# limits
\cp /etc/security/limits.d/90-nproc.conf /etc/security/limits.d/90-nproc.conf.bak
\cp "$SCRIPT_DIR/settings/limits/90-nproc.conf" /etc/security/limits.d/90-nproc.conf

# starting servers
chkconfig httpd on
chkconfig mysqld on
chkconfig memcached on
chkconfig nginx on
chkconfig php-fpm on
chkconfig named on
chkconfig vsftpd on

service httpd restart
service mysqld restart
service memcached restart
service nginx restart
service php-fpm restart
service named restart
service vsftpd restart

#mysql_secure_installation
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PSSWD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
USE test;
DROP DATABASE test;
FLUSH PRIVILEGES;
EOF

# installing panel
tar -xzf "/opt/webpanel/lamp-$ARCH/lamp-$ARCH.tar.gz" --directory "/opt/webpanel/lamp-$ARCH"
chmod +x $(find "/opt/webpanel/lamp-$ARCH" -name "*" | grep -e \.sh$)
chown -R daemon:daemon "/opt/webpanel/lamp-$ARCH/mysql/data"


mkdir -p /opt/webpanel/panel/public
mkdir -p /opt/webpanel/panel/app/storage
chown -R daemon:daemon /opt/webpanel/panel/public
chown -R daemon:daemon /opt/webpanel/panel/app/storage



\cp "$SCRIPT_DIR/settings/init.d/webpanel" /etc/init.d/webpanel
chmod +x /etc/init.d/webpanel
chkconfig --add webpanel
chkconfig webpanel on
service webpanel restart

touch /etc/default/webpanel
echo "WebPanel is installed"