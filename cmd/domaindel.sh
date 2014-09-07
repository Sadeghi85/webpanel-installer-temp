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

SCRIPTDIR=$(dirname $0)

SERVER_NAME="$(echo $1 | tr '[A-Z]' '[a-z]')"

if ! (echo "$SERVER_NAME" | grep -Eq "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$") then
	echo "SERVER_NAME ($SERVER_NAME) doesn't seem to be valid. Aborting...."
	exit 1
fi

SAFE_SERVER_NAME="${SERVER_NAME//./_}"
SAFE_SERVER_NAME="$(echo $SAFE_SERVER_NAME | cut -c1-30)" # truncate to 30 chars, so after adding u- it doesn't go beyond 32 char limit.

echo "Deleting domain: $SERVER_NAME"

# deleting config files
echo "Deleting config files"

# php-fpm
STATUS=$(rm -f "/etc/php-fpm.d/sites-enabled/$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/php-fpm.d/sites-available/$SERVER_NAME.conf" 2>&1)
# apache
STATUS=$(rm -f "/etc/httpd/conf/sites-enabled/$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/httpd/conf/sites-available/$SERVER_NAME.conf" 2>&1)
# nginx
STATUS=$(rm -f "/etc/nginx/conf.d/sites-enabled/$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/nginx/conf.d/sites-available/$SERVER_NAME.conf" 2>&1)
# webalizer
STATUS=$(rm -f "/etc/webalizer.d/sites-enabled/$SERVER_NAME.conf" 2>&1)
STATUS=$(rm -f "/etc/webalizer.d/sites-available/$SERVER_NAME.conf" 2>&1)

# Restarting servers
echo "Restarting servers..."
STATUS=$(sh "$SCRIPTDIR/restart_servers.sh" 2>&1)

if [ $? != 0 ]; then
	echo -e "$STATUS\nRestart failed..."
else
	echo "$STATUS"
fi

# deleting user
echo "Deleting user..."
STATUS=$(userdel "u-$SAFE_SERVER_NAME" 2>&1)

if [ $? != 0 ]; then
	echo "Couldn't delete the user. message:($STATUS)"
fi

exit 0
