#!/bin/bash

# $1:server_tag, $2:quota_size (KB)

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
QUOTA_SIZE="$2"

if ! $(echo "$SERVER_TAG" | grep -Pqs "^web\d{3}$"); then
	echo "SERVER_TAG ($SERVER_TAG) is invalid."
	exit 1
fi

if ! $(echo "$QUOTA_SIZE" | grep -Pqs "^\d+$"); then
	echo "QUOTA_SIZE ($QUOTA_SIZE) is invalid."
	exit 1
fi

# Quota
TMP_DIR="/$HOME"
QUOTA_DIR=""
while [[ $TMP_DIR != "" ]]
do
	if [[ $TMP_DIR != "/" ]]; then
		QUOTA_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^\/(.+)$/\1/");
	else
		QUOTA_DIR="/"
	fi
	
	if grep -qs " $QUOTA_DIR " /proc/mounts; then
		break
	fi
	
	TMP_DIR=$(echo "$TMP_DIR" | sed -r -e"s/^(.*)\/.*?$/\1/")
done

# setting quota size
STATUS=$(setquota -u "$SERVER_TAG" -F vfsv0 0 "$QUOTA_SIZE" 0 0 "$QUOTA_DIR" -a 2>&1)
if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
