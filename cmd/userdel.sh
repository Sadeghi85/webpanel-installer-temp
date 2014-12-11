#!/bin/bash

# $1:username

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

USER_NAME=$(echo "$1" | tr '[A-Z]' '[a-z]')

if ! $(echo "$USER_NAME" | grep -Pqs "^[a-z0-9_-]+$"); then
	echo "USER_NAME ($USER_NAME) is invalid."
	exit 1
fi

if [[ $USER_NAME == "root" ]]; then
	echo "root user will not be removed."
	exit 1
fi

STATUS=$(id -u "$USER_NAME" 2>&1)
if (( $? == 0 )); then
	# user exists
	if (( $STATUS != 0 )); then
		echo "non panel user will not be removed."
		exit 1
	fi
	
	# locking user
	STATUS=$(passwd -l "$USER_NAME" 2>&1)
	if (( $? != 0 )); then
		echo "$STATUS"
	fi
	
	# deleting user
	STATUS=$(userdel "$USER_NAME" 2>&1)
	if (( $? != 0 )); then
		echo "$STATUS"
	fi
fi

exit 0
