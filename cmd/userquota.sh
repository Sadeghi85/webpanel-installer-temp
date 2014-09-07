#!/bin/bash

# Check for a valid number of parameters or for the help command
if [ "$1" == '--help' -o "$#" != 2 ]; then
	printf "The usage for this command is:\n"
	printf "\tuserquota.sh '\e[33msite_name\e[0m' '\e[32mquota_size\e[0m'\n"
	printf "Where the variables are:\n"
	printf "\t\e[33msite_name\e[0m\tThe name of the site\n"
	printf "\t\e[32mquota_size\e[0m\tThe quota size in KB\n"
	exit 0
fi

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

SCRIPTDIR=$(dirname $0)
HOME="/var/www"

SERVER_NAME="$(echo $1 | tr '[A-Z]' '[a-z]')"

if ! (echo "$SERVER_NAME" | grep -Eq "^([a-z0-9][-a-z0-9]*\.)*[a-z]*$") then
	echo "SERVER_NAME ($SERVER_NAME) doesn't seem to be valid. Aborting...."
	exit 1
fi

SAFE_SERVER_NAME="${SERVER_NAME//./_}"
SAFE_SERVER_NAME="$(echo $SAFE_SERVER_NAME | cut -c1-30)" # truncate to 30 chars, so after adding u- it doesn't go beyond 32 char limit.

QUOTASIZE="$2"

if ! (echo "$QUOTASIZE" | grep -Pq "^\d+$") then
	echo "QUOTASIZE ($QUOTASIZE) doesn't seem to be valid. Aborting...."
	exit 1
fi

echo "Setting quota for user: u-$SAFE_SERVER_NAME"
STATUS=$(setquota -u "u-$SAFE_SERVER_NAME" -F vfsv0 0 "$QUOTASIZE" 0 0 "$HOME" -a 2>&1)

if [ $? != 0 ]; then
	echo "Couldn't set the quota. Aborting.... message:($STATUS)"
	exit 1
fi

exit 0
