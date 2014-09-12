#!/bin/bash

# $1:server_tag, $2:server_name, $3:server_port

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

# Allow only root execution
if (( $(id -u) != 0 )); then
    echo "This script requires root privileges"
    exit 1
fi

SERVER_TAG=$(echo "$1" | tr '[A-Z]' '[a-z]')
SERVER_NAME=$(echo "$2" | tr '[A-Z]' '[a-z]')
SERVER_PORT="$3"

if ! $(echo "$SERVER_TAG" | grep -Pqs "^web\d{3}$"); then
	echo "SERVER_TAG ($SERVER_TAG) is invalid."
	exit 1
fi

if ! $(echo "$SERVER_NAME" | grep -Pqs "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$"); then
	echo "SERVER_NAME ($SERVER_NAME) is invalid."
	exit 1
fi

if ! $(echo "$SERVER_PORT" | grep -Pqs "^\d+$"); then
	echo "SERVER_PORT ($SERVER_PORT) is invalid."
	exit 1
fi

## deleting config files
# php-fpm
STATUS=$(rm -f "/etc/php-fpm.d/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/php-fpm.d/settings/sites-enabled/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/php-fpm.d/settings/sites-enabled-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/php-fpm.d/settings/sites-available-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
# apache
STATUS=$(rm -f "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/httpd/settings/sites-enabled/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/httpd/settings/sites-enabled-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/httpd/settings/sites-available-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
# nginx
STATUS=$(rm -f "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/nginx/settings/sites-enabled/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/nginx/settings/sites-enabled-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/nginx/settings/sites-available-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
# webalizer
STATUS=$(rm -f "/etc/webalizer.d/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/webalizer.d/settings/sites-enabled/$SERVER_TAG.conf" 2>&1)
STATUS=$(rm -f "/etc/webalizer.d/settings/sites-enabled-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/webalizer.d/settings/sites-available-for-humans/$SERVER_PORT.$SERVER_NAME.conf" 2>&1)

# Reloading servers
STATUS=$(sh "$SCRIPT_DIR/reload_servers.sh" 2>&1)

if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

# deleting user
STATUS=$(userdel "$SERVER_TAG" 2>&1)

if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
