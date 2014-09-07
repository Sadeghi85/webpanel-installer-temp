#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

# Apache
chkconfig httpd on

mkdir -p "/usr/lib/cgi-bin"
mkdir -p "/etc/httpd/sites-available"
mkdir -p "/etc/httpd/sites-enabled"
mkdir -p "/etc/httpd/sites-available-for-humans"
mkdir -p "/etc/httpd/sites-enabled-for-humans"
\cp "/var/www/error/noindex.html" "/var/www/html/index.html"
\mv "/etc/httpd/conf.d/php.conf" "/etc/httpd/conf.d/php.conf.disabled"

\cp "/etc/sysconfig/httpd" "/etc/sysconfig/httpd.bak"
sed -i -r -e"s/.*?HTTPD=\/usr\/sbin\/httpd.*/HTTPD=\/usr\/sbin\/httpd.event/I" "/etc/sysconfig/httpd"

\cp "/etc/httpd/conf.d/fastcgi.conf" "/etc/httpd/conf.d/fastcgi.conf.bak"
sed -i -r -e"s/FastCgiWrapper.*/FastCgiWrapper Off/I" "/etc/httpd/conf.d/fastcgi.conf"

\cp "/etc/httpd/conf.d/welcome.conf" "/etc/httpd/conf.d/welcome.conf.bak"
sed -i -r -e"s/ErrorDocument\s*403.*/\#ErrorDocument 403 \/error\/HTTP_FORBIDDEN.html.var/I" "/etc/httpd/conf.d/welcome.conf"

\cp "$SCRIPT_DIR/settings/apache/deflate.conf.disabled" "/etc/httpd/conf.d/deflate.conf.disabled"

\cp "$SCRIPT_DIR/settings/apache/expires.conf.disabled" "/etc/httpd/conf.d/expires.conf.disabled"

\cp "$SCRIPT_DIR/settings/apache/rpaf.conf" "/etc/httpd/conf.d/rpaf.conf"

\cp "$SCRIPT_DIR/settings/apache/php-fpm.conf.disabled" "/etc/httpd/conf.d/php-fpm.conf.disabled"

\cp "/etc/httpd/conf/httpd.conf" "/etc/httpd/conf/httpd.conf.bak"
\cp "$SCRIPT_DIR/settings/apache/httpd.conf" "/etc/httpd/conf/httpd.conf"

# PHP & PHP-FPM & Memcached & PageSpeed
chkconfig php-fpm on
chkconfig memcached on

chmod 777 "/var/lib/php/session"
mkdir -p "/etc/php-fpm.d/sites-available"
mkdir -p "/etc/php-fpm.d/sites-enabled"
mkdir -p "/etc/php-fpm.d/sites-available-for-humans"
mkdir -p "/etc/php-fpm.d/sites-enabled-for-humans"
\mv "/etc/php-fpm.d/www.conf" "/etc/php-fpm.d/www.conf.disabled"

\cp "/etc/php.ini" "/etc/php.ini.bak"
sed -i -r -e"s/^error_reporting\s*=.*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/I" "/etc/php.ini"
sed -i -r -e"s/^disable_functions\s*=.*/disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,dl,exec,passthru,shell_exec,system,proc_open,popen,pclose,show_source,proc_terminate,proc_get_status,proc_close,proc_nice,posix_getpwuid,posix_getgrgid,posix_kill,posix_setpgid,posix_setsid,posix_mkfifo,posix_setuid,openlog,syslog,closelog,define_syslog_variables,get_current_user,getmyuid,getmygid,getmypid,getmyinode/I" "/etc/php.ini"
sed -i -r -e"s/^session.save_handler\s*=.*/session.save_handler = memcached/I" "/etc/php.ini"
sed -i -r -e"s/^session.save_path\s*=.*/session.save_path = \"localhost:11211\"/I" "/etc/php.ini"

\cp "/etc/sysconfig/memcached" "/etc/sysconfig/memcached.bak"
sed -i -r -e"s/^CACHESIZE\s*=.*/CACHESIZE = \"128\"/I" "/etc/sysconfig/memcached"

\cp "/etc/php.d/opcache.ini" "/etc/php.d/opcache.ini.bak"
sed -i -r -e"s/^opcache.max_accelerated_files\s*=.*/opcache.max_accelerated_files = 40000/I" "/etc/php.d/opcache.ini"

\cp "/etc/php-fpm.conf" "/etc/php-fpm.conf.bak"
sed -i -r -e"s/^include\s*=.*/include=\/etc\/php-fpm.d\/sites-enabled\/*.conf/I" "/etc/php-fpm.conf"
sed -i -r -e"s/^error_log\s*=.*/error_log = \/var\/log\/php-fpm\/server_error\.log/I" "/etc/php-fpm.conf"

\cp "/etc/httpd/conf.d/pagespeed.conf" "/etc/httpd/conf.d/pagespeed.conf.bak"
\cp "$SCRIPT_DIR/settings/pagespeed/pagespeed.conf" "/etc/httpd/conf.d/pagespeed.conf"

# Nginx
chkconfig nginx on

\mv "/etc/nginx/conf.d/default.conf" "/etc/nginx/conf.d/default.conf.disabled"
\mv "/etc/nginx/conf.d/example_ssl.conf" "/etc/nginx/conf.d/example_ssl.conf.disabled"
mkdir -p "/etc/nginx/sites-available"
mkdir -p "/etc/nginx/sites-enabled"
mkdir -p "/etc/nginx/sites-available-for-humans"
mkdir -p "/etc/nginx/sites-enabled-for-humans"

\cp "/etc/nginx/nginx.conf" "/etc/nginx/nginx.conf.bak"
\cp "$SCRIPT_DIR/settings/nginx/nginx.conf" "/etc/nginx/nginx.conf"

# Webalizer & Logs schedules
chown root:apache "/var/log/php-fpm"
mkdir -p "/etc/webalizer.d"
mkdir -p "/etc/webalizer.d/sites-available"
mkdir -p "/etc/webalizer.d/sites-enabled"
mkdir -p "/etc/webalizer.d/sites-available-for-humans"
mkdir -p "/etc/webalizer.d/sites-enabled-for-humans"

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

# starting Apache & Nginx & Memcached
service httpd start
service nginx start
service memcached start

# MySQL
chkconfig mysqld on
service mysqld start

ROOT_PSSWD="WebPanel"
#mysql_secure_installation
mysql -u root <<EOF
UPDATE mysql.user SET Password=PASSWORD('$ROOT_PSSWD') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test';
FLUSH PRIVILEGES;
EXIT;
EOF

