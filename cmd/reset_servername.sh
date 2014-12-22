#!/bin/bash

# $1:server_tag, $2:server_name, $3:server_port

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
HOME="/var/www/WebPanel"

HOME=${HOME%/}
if [[ $HOME == "" ]]; then
	echo "Home directory can't be '/' itself."
	exit 1
fi

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

## testing servers
STATUS=$(sh "$SCRIPT_DIR/test_servers.sh" 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

## backing up configs
# apache
STATUS=$(\cp "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf.bak" 2>&1)
# nginx
STATUS=$(\cp "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf.bak" 2>&1)

## apache
STATUS=$(sed -i -e"s/\(ServerName \).*/\1$SERVER_PORT.$SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/\(ServerAlias \).*/\1$SERVER_PORT.$SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/ModPagespeedDomain .*//g" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/\(ServerAlias .*\)/\1\n    ModPagespeedDomain *$SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)

## nginx
#STATUS=$(sed -i -e"s/\(listen .*\)/\1\n        listen $SERVER_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
#STATUS=$(sed -i -e"s/\(server_name .*?\);/\1 $SERVER_NAME:$SERVER_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/\(server_name \).*/\1$SERVER_NAME;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)

## hosts
STATUS=$(echo "127.0.0.1 $SERVER_NAME" >> /etc/hosts 2>&1)

##################### Reloading servers
STATUS=$(sh "$SCRIPT_DIR/reload_servers.sh" 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
