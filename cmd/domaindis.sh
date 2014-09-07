#!/bin/bash

# Check for a valid number of parameters or for the help command
if [ "$1" == '--help' -o "$#" != 1 ]; then
	printf "The usage for this command is:\n"
	printf "\tdomaindis.sh '\e[32msite_name\e[0m'\n"
	printf "\t\e[32msite_name\e[0m\tThe name of the site\n"
	exit 0
fi

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi
SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

SERVER_NAME=$(echo $1 | tr '[A-Z]' '[a-z]')

if ! (echo "$SERVER_NAME" | grep -Eq "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$") then
	echo "SERVER_NAME ($SERVER_NAME) doesn't seem to be valid. Aborting...."
	exit 1
fi

echo "Disabling domain: $SERVER_NAME"

# disabling php-fpm config
STATUS=$(rm -f "/etc/php-fpm.d/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)

# disabling apache config
STATUS=$(rm -f "/etc/httpd/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)

# disabling nginx config
STATUS=$(rm -f "/etc/nginx/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)

# disabling webalizer config
STATUS=$(rm -f "/etc/webalizer.d/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)

# Restarting servers
echo "Restarting servers..."
STATUS=$(sh "$SCRIPT_DIR/restart_servers.sh" 2>&1)

if [ $? != 0 ]; then
	echo -e "$STATUS\nRestart failed..."
	exit 1
else
	echo "$STATUS"
fi

exit 0
