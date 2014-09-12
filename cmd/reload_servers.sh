#!/bin/bash

# Allow only root execution
if (( $(id -u) != 0 )); then
    echo "This script requires root privileges"
    exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

# testing server configs
STATUS=$(sh "$SCRIPT_DIR/test_servers.sh" 2>&1)

if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
else
	echo ""
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
