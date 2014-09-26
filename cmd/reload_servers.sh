#!/bin/bash

# Allow only root execution
if (( $(id -u) != 0 )); then
	echo "This script requires root privileges"
	exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

# in case some servers aren't already up
STATUS=$(/sbin/service php-fpm start 2>&1)
STATUS=$(ps aux | grep php[-]fpm 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

STATUS=$(/sbin/service httpd start 2>&1)
STATUS=$(ps aux | grep http[d] 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

STATUS=$(/sbin/service nginx start 2>&1)
STATUS=$(ps aux | grep ngin[x] 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# testing server configs
STATUS=$(sh "$SCRIPT_DIR/test_servers.sh" 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# reloading php-fpm
STATUS=$(/sbin/service php-fpm reload 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# reloading apache
STATUS=$(/sbin/service httpd reload 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# reloading nginx
STATUS=$(/sbin/service nginx reload 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
