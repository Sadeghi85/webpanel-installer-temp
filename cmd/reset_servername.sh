#!/bin/bash

# $1:server_tag, $2:old_server_name, $3:new_server_name, $4:server_port

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
OLD_SERVER_NAME=$(echo "$2" | tr '[A-Z]' '[a-z]')
NEW_SERVER_NAME=$(echo "$3" | tr '[A-Z]' '[a-z]')
SERVER_PORT="$4"

if ! $(echo "$SERVER_TAG" | grep -Pqs "^web\d{3}$"); then
	echo "SERVER_TAG ($SERVER_TAG) is invalid."
	exit 1
fi

if ! $(echo "$OLD_SERVER_NAME" | grep -Pqs "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$"); then
	echo "OLD_SERVER_NAME ($OLD_SERVER_NAME) is invalid."
	exit 1
fi

if ! $(echo "$NEW_SERVER_NAME" | grep -Pqs "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$"); then
	echo "NEW_SERVER_NAME ($NEW_SERVER_NAME) is invalid."
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
STATUS=$(sed -i -e"s/ServerName [[:space:]]*$SERVER_PORT\.$OLD_SERVER_NAME\([[:space:]]\|\$\).*/ServerName $SERVER_PORT.$NEW_SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/ModPagespeedDomain [[:space:]]*\*$OLD_SERVER_NAME\([[:space:]]\|\$\).*/ModPagespeedDomain *$NEW_SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
STATUS=$(sed -i -e"s/ServerAdmin [[:space:]]*postmaster@$OLD_SERVER_NAME\([[:space:]]\|\$\).*/ServerAdmin postmaster@$NEW_SERVER_NAME/" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)

## nginx
#STATUS=$(sed -i -e"s/\(listen .*\)/\1\n        listen $SERVER_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
#STATUS=$(sed -i -e"s/\(server_name .*?\);/\1 $SERVER_NAME:$SERVER_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
if ! $(grep -Pqs "server_name .*? $NEW_SERVER_NAME \s*" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf"); then
    STATUS=$(sed -i -e"s/\(server_name .*\?\)[[:space:]]$OLD_SERVER_NAME\([[:space:]]\|;\)\(.*\)/\1 $NEW_SERVER_NAME\2\3/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)
fi

## for-humans
STATUS=$(\mv "$HOME/sites-available-for-humans/$SERVER_PORT.$OLD_SERVER_NAME" "$HOME/sites-available-for-humans/$SERVER_PORT.$NEW_SERVER_NAME" 2>&1)
STATUS=$(\mv "$HOME/sites-enabled-for-humans/SERVER_PORT.$OLD_SERVER_NAME" "$HOME/sites-enabled-for-humans/$SERVER_PORT.$NEW_SERVER_NAME" 2>&1)

## hosts
if ! $(grep -Pqs "127.0.0.1\s+$NEW_SERVER_NAME" "/etc/hosts"); then
    STATUS=$(echo "127.0.0.1 $NEW_SERVER_NAME" >> /etc/hosts 2>&1)
fi

##################### Reloading servers
STATUS=$(sh "$SCRIPT_DIR/reload_servers.sh" 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
