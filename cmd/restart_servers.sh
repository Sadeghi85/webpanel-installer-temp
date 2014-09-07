#!/bin/bash

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

SCRIPTDIR=$(dirname $0)

# testing server configs
echo "Testing server configs..."
STATUS=$(sh "$SCRIPTDIR/test_servers.sh" 2>&1)

if [ $? != 0 ]; then
	echo -e "$STATUS\nTest failed..."
	exit 1
else
	echo "$STATUS"
fi

# restarting php-fpm
echo "Restarting PHP-FPM..."
STATUS=$(/sbin/service php-fpm restart 2>&1)
if [ $? != 0 ]; then
	echo "FATAL: PHP-FPM is stopped due to an error. message:($STATUS)"
	exit 1
fi

# restarting apache
echo "Restarting Apache..."
STATUS=$(/sbin/service httpd restart 2>&1)
if [ $? != 0 ]; then
	echo "FATAL: Apache is stopped due to an error. message:($STATUS)"
	exit 1
fi

# restarting nginx
echo "Restarting Nginx..."
STATUS=$(/sbin/service nginx restart 2>&1)
if [ $? != 0 ]; then
	echo "FATAL: Nginx is stopped due to an error. message:($STATUS)"
	exit 1
fi

exit 0
