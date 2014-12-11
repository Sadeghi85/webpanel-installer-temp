#!/bin/bash

# $1:username, $2:password

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
SHELL="/sbin/nologin"
HOME="/var/www/WebPanel"

USER_NAME=$(echo "$1" | tr '[A-Z]' '[a-z]')
PASSWORD="$2"

if ! $(echo "$USER_NAME" | grep -Pqs "^[a-z0-9_-]+$"); then
	echo "USER_NAME ($USER_NAME) is invalid."
	exit 1
fi

if [[ $USER_NAME == "root" ]]; then
	exit 0
fi

# creating user
STATUS=$(id -u "$USER_NAME" 2>&1)
if (( $? == 0 )); then
	# user exists
	if (( $STATUS != 0 )); then
		echo "non panel user will not be modified."
		exit 1
	fi
	
	STATUS=$(usermod --comment "WebPanel user $USER_NAME" -g apache --home "$HOME" --shell "$SHELL" -u 0 -o "$USER_NAME" 2>&1)
	if (( $? != 0 )); then
		echo "$STATUS"
		exit 1
	fi
else
	# user doesn't exist
	STATUS=$(useradd --comment "WebPanel user $USER_NAME" -g apache --home "$HOME" --shell "$SHELL" -u 0 -o "$USER_NAME" 2>&1)
	if (( $? != 0 )); then
		echo "$STATUS"
		exit 1
	fi
fi

# setting password
STATUS=$(echo "$USER_NAME":"$PASSWORD" | chpasswd 2>&1)

if (( $? != 0 )); then
	echo "$STATUS"
	exit 1
fi

exit 0
