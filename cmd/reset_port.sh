#!/bin/bash

# $1:server_tag, $2:server_name, $3:old_server_port, $4:new_server_port

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
OLD_SERVER_PORT="$3"
NEW_SERVER_PORT="$4"

if ! $(echo "$SERVER_TAG" | grep -Pqs "^web\d{3}$"); then
	echo "SERVER_TAG ($SERVER_TAG) is invalid."
	exit 1
fi

if ! $(echo "$SERVER_NAME" | grep -Pqs "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$"); then
	echo "SERVER_NAME ($SERVER_NAME) is invalid."
	exit 1
fi

if ! $(echo "$OLD_SERVER_PORT" | grep -Pqs "^\d+$"); then
	echo "OLD_SERVER_PORT ($OLD_SERVER_PORT) is invalid."
	exit 1
fi

if ! $(echo "$NEW_SERVER_PORT" | grep -Pqs "^\d+$"); then
	echo "NEW_SERVER_PORT ($NEW_SERVER_PORT) is invalid."
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
STATUS=$(sed -i -e"s/$OLD_SERVER_PORT\./$NEW_SERVER_PORT./g" "/etc/httpd/settings/sites-available/$SERVER_TAG.conf" 2>&1)
## nginx
STATUS=$(sed -i -e"s/listen [[:space:]]*$OLD_SERVER_PORT.*/listen $NEW_SERVER_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_TAG.conf" 2>&1)

## for-humans
STATUS=$(\mv "$HOME/sites-available-for-humans/$OLD_SERVER_PORT.$SERVER_NAME" "$HOME/sites-available-for-humans/$NEW_SERVER_PORT.$SERVER_NAME" 2>&1)
STATUS=$(\mv "$HOME/sites-enabled-for-humans/$OLD_SERVER_PORT.$SERVER_NAME" "$HOME/sites-enabled-for-humans/$NEW_SERVER_PORT.$SERVER_NAME" 2>&1)

##################### Reloading servers
STATUS=$(sh "$SCRIPT_DIR/reload_servers.sh" 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
