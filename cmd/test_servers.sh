#!/bin/bash

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

# testing php-fpm
echo "Testing PHP-FPM..."
STATUS=$(/usr/sbin/php-fpm -t 2>&1)
if [ $? != 0 ]; then
	echo "FATAL: PHP-FPM didn't pass the test. Aborting.... message:($STATUS)"
	exit 1
fi

# testing Apache
echo "Testing Apache..."
STATUS=$(/usr/sbin/httpd -t 2>&1)
if [ $? != 0 ]; then
	echo "FATAL: Apache didn't pass the test. Aborting.... message:($STATUS)"
	exit 1
fi

# testing Nginx
echo "Testing Nginx..."
STATUS=$(/usr/sbin/nginx -t 2>&1)	
if [ $? != 0 ]; then
	echo "FATAL: Nginx didn't pass the test. Aborting.... message:($STATUS)"
	exit 1
fi

exit 0
