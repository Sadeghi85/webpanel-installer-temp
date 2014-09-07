#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

# Apache
mkdir -p "/usr/lib/cgi-bin"
mkdir -p "/etc/httpd/settings/sites-available"
mkdir -p "/etc/httpd/settings/sites-enabled"
mkdir -p "/etc/httpd/settings/sites-available-for-humans"
mkdir -p "/etc/httpd/settings/sites-enabled-for-humans"
\cp "/var/www/error/noindex.html" "/var/www/html/index.html"
\mv "/etc/httpd/conf.d/php.conf" "/etc/httpd/conf.d/php.conf.disabled"

\cp "/etc/sysconfig/httpd" "/etc/sysconfig/httpd.bak"
\cp "$SCRIPT_DIR/settings/apache/httpd" "/etc/sysconfig/httpd"

\cp "/etc/httpd/conf.d/fastcgi.conf" "/etc/httpd/conf.d/fastcgi.conf.bak"
\cp "$SCRIPT_DIR/settings/apache/fastcgi.conf" "/etc/httpd/conf.d/fastcgi.conf"

\cp "/etc/httpd/conf.d/welcome.conf" "/etc/httpd/conf.d/welcome.conf.bak"
\cp "$SCRIPT_DIR/settings/apache/welcome.conf" "/etc/httpd/conf.d/welcome.conf"

\cp "$SCRIPT_DIR/settings/apache/deflate.conf.disabled" "/etc/httpd/conf.d/deflate.conf.disabled"
\cp "$SCRIPT_DIR/settings/apache/expires.conf.disabled" "/etc/httpd/conf.d/expires.conf.disabled"
\cp "$SCRIPT_DIR/settings/apache/rpaf.conf" "/etc/httpd/conf.d/rpaf.conf"
\cp "$SCRIPT_DIR/settings/apache/php-fpm.conf.disabled" "/etc/httpd/conf.d/php-fpm.conf.disabled"

\cp "/etc/httpd/conf/httpd.conf" "/etc/httpd/conf/httpd.conf.bak"
\cp "$SCRIPT_DIR/settings/apache/httpd.conf" "/etc/httpd/conf/httpd.conf"

# PHP & PHP-FPM & Memcached & PageSpeed
chmod 777 "/var/lib/php/session"
mkdir -p "/etc/php-fpm.d/settings/sites-available"
mkdir -p "/etc/php-fpm.d/settings/sites-enabled"
mkdir -p "/etc/php-fpm.d/settings/sites-available-for-humans"
mkdir -p "/etc/php-fpm.d/settings/sites-enabled-for-humans"
\mv "/etc/php-fpm.d/www.conf" "/etc/php-fpm.d/www.conf.disabled"

\cp "/etc/php.ini" "/etc/php.ini.bak"
\cp "$SCRIPT_DIR/settings/php/php.ini" "/etc/php.ini"

\cp "/etc/sysconfig/memcached" "/etc/sysconfig/memcached.bak"
\cp "$SCRIPT_DIR/settings/memcached/memcached" "/etc/sysconfig/memcached"

\cp "/etc/php.d/opcache.ini" "/etc/php.d/opcache.ini.bak"
\cp "$SCRIPT_DIR/settings/php/opcache.ini" "/etc/php.d/opcache.ini"

\cp "/etc/php-fpm.conf" "/etc/php-fpm.conf.bak"
\cp "$SCRIPT_DIR/settings/php-fpm/php-fpm.conf" "/etc/php-fpm.conf"

\cp "/etc/httpd/conf.d/pagespeed.conf" "/etc/httpd/conf.d/pagespeed.conf.bak"
\cp "$SCRIPT_DIR/settings/apache/pagespeed.conf" "/etc/httpd/conf.d/pagespeed.conf"

# Nginx
\mv "/etc/nginx/conf.d/default.conf" "/etc/nginx/conf.d/default.conf.disabled"
\mv "/etc/nginx/conf.d/example_ssl.conf" "/etc/nginx/conf.d/example_ssl.conf.disabled"
mkdir -p "/etc/nginx/settings/sites-available"
mkdir -p "/etc/nginx/settings/sites-enabled"
mkdir -p "/etc/nginx/settings/sites-available-for-humans"
mkdir -p "/etc/nginx/settings/sites-enabled-for-humans"

\cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.bak"
\cp "$SCRIPT_DIR/settings/nginx/nginx.conf" "/etc/nginx/nginx.conf"
\cp "$SCRIPT_DIR/settings/nginx/nginx_default_server.conf" "/etc/nginx/nginx_default_server.conf"

# Webalizer & Logs schedules
chown root:apache "/var/log/php-fpm"
mkdir -p "/etc/webalizer.d/settings/sites-available"
mkdir -p "/etc/webalizer.d/settings/sites-enabled"
mkdir -p "/etc/webalizer.d/settings/sites-available-for-humans"
mkdir -p "/etc/webalizer.d/settings/sites-enabled-for-humans"

# Disabling default Logrotate & Webalizer schedules
\cp "$SCRIPT_DIR/settings/webalizer/00webalizer" "/etc/cron.daily/00webalizer"
\cp "$SCRIPT_DIR/settings/logrotate/httpd" "/etc/logrotate.d/httpd"
\cp "$SCRIPT_DIR/settings/logrotate/nginx" "/etc/logrotate.d/nginx"
\cp "$SCRIPT_DIR/settings/logrotate/php-fpm" "/etc/logrotate.d/php-fpm"

# Enabling WebPanel schedules
\cp "$SCRIPT_DIR/settings/schedules/webpanel-daily-schedules" "/etc/cron.daily/webpanel-daily-schedules"
chmod 755 "/etc/cron.daily/webpanel-daily-schedules"

# iptables
iptables-save > "/etc/sysconfig/iptables.bak"
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT # Nginx
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 5000 -j ACCEPT # WebPanel
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 10000 -j ACCEPT # Webmin
service iptables save
service iptables restart

# limits
\cp "/etc/security/limits.d/90-nproc.conf" "/etc/security/limits.d/90-nproc.conf.bak"
\cp "$SCRIPT_DIR/settings/limits/90-nproc.conf" "/etc/security/limits.d/90-nproc.conf"

# starting Apache, Memcached, MySQL & Nginx
chkconfig httpd on
chkconfig memcached on
chkconfig mysqld on
chkconfig nginx on
chkconfig php-fpm on

service httpd start
service memcached start
service mysqld start
service nginx start

MYSQL_ROOT_PSSWD="WebPanel"
#mysql_secure_installation
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PSSWD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test';
FLUSH PRIVILEGES;
EXIT;
EOF

