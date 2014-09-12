#!/bin/bash

# Allow only root execution
if (( $(id -u) != 0 )); then
    echo "This script requires root privileges"
    exit 1
fi

# testing php-fpm
STATUS=$(/usr/sbin/php-fpm -t 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# testing Apache
STATUS=$(/usr/sbin/httpd -t 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# testing Nginx
STATUS=$(/usr/sbin/nginx -t 2>&1)	
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
