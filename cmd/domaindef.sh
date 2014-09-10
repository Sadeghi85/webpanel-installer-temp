#!/bin/bash

# $1:server_tag, $2:server_name, $3:server_port

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
WEB_ROOT_DIR="web"
SHELL="/sbin/nologin"
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
SERVER_PORT=$(echo "$3" | tr '[A-Z]' '[a-z]')

if [[ ! (echo "$SERVER_TAG" | grep -Pqs "^web\d{3}$" ]]; then
	echo "SERVER_TAG ($SERVER_TAG) is invalid."
	exit 1
fi

if [[ ! (echo "$SERVER_NAME" | grep -Pqs "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$") ]]; then
	echo "SERVER_NAME ($SERVER_NAME) is invalid."
	exit 1
fi

if [[ ! (echo "$SERVER_PORT" | grep -Pqs "^\d+$") ]]; then
	echo "SERVER_PORT ($SERVER_PORT) is invalid."
	exit 1
fi

# check if ftp home already exists
if [[ ! -e "$HOME/sites-available/$SERVER_TAG" ]]; then

	# creating ftp home
	STATUS=$(mkdir -p "$HOME/sites-available/$SERVER_TAG" 2>&1)
	
	if (( $? != 0 )); then
		echo "$STATUS"
		exit 1
	fi

	# creating web root
	STATUS=$(mkdir -p "$HOME/sites-available/$SERVER_TAG/$WEB_ROOT_DIR" 2>&1)
	
	if (( $? != 0 )); then
		echo "$STATUS"
		exit 1
	fi

	# creating user
	STATUS=$(id "$SERVER_TAG" 2>&1)
	
	if (( $? == 0 )); then
		# user exists
		STATUS=$(usermod "$SERVER_TAG" --home "$HOME/sites-available/$SERVER_TAG" --shell "$SHELL" 2>&1)
		
		if (( $? != 0 )); then
			echo "$STATUS"
			exit 1
		fi
	else
		# user doesn't exist
		STATUS=$(useradd "$SERVER_TAG" --home "$HOME/sites-available/$SERVER_TAG" --shell "$SHELL" 2>&1)
		
		if (( $? != 0 )); then
			echo "$STATUS"
			exit 1
		fi
	fi

	# correcting permissions on ftp home
	echo "Correcting permissions on ftp home..."
	STATUS=$(chown -R "u-$SAFE_SERVER_NAME:u-$SAFE_SERVER_NAME" "$HOME/$SERVER_NAME" 2>&1)
	
	if [ $? != 0 ]; then
		echo "Couldn't set permissions on ftp home. Aborting.... message:($STATUS)"
		exit 1
	fi

	STATUS=$(chmod -R 644 "$HOME/$SERVER_NAME" 2>&1)
	
	if [ $? != 0 ]; then
		echo "Couldn't set permissions on ftp home. Aborting.... message:($STATUS)"
		exit 1
	fi

	STATUS=$(chmod -R +X "$HOME/$SERVER_NAME" 2>&1) # to give search bit to all directories, effectively 755 for dirs
	
	if [ $? != 0 ]; then
		echo "Couldn't set permissions on ftp home. Aborting.... message:($STATUS)"
		exit 1
	fi

	# creating pool definition
	echo "Creating pool definition..."
	if [ ! -e "/etc/php-fpm.d/settings/sites-available/$SERVER_NAME.conf" ]; then
		STATUS=$(cp "$SCRIPT_DIR/templates/php-fpm/example.com.conf" "/etc/php-fpm.d/settings/sites-available/$SERVER_NAME.conf" 2>&1)
		
		if [ $? != 0 ]; then
			echo "Couldn't copy the template. Aborting.... message:($STATUS)"
			exit 1
		else
			STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" -e"s/^user\s\+=.*/user = u-$SAFE_SERVER_NAME/" -e"s/^group\s\+=.*/group = u-$SAFE_SERVER_NAME/" "/etc/php-fpm.d/settings/sites-available/$SERVER_NAME.conf" 2>&1)
			
			if [ $? != 0 ]; then
				echo "Couldn't edit the pool definition. Aborting.... message:($STATUS)"
				exit 1
			else
				STATUS=$(ln -fs "../sites-available/$SERVER_NAME.conf" "/etc/php-fpm.d/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)
			
				if [ $? != 0 ]; then
					echo "Couldn't enable the pool. Aborting.... message:($STATUS)"
					exit 1
				fi
			fi
		fi
	else
		echo "WARNING: Pool definition already exists."
	fi

	# creating apache virtual host
	echo "Creating apache virtual host..."
	if [ ! -e "/etc/httpd/settings/sites-available/$SERVER_NAME.conf" ]; then
		STATUS=$(cp "$SCRIPT_DIR/templates/apache/example.com.conf" "/etc/httpd/settings/sites-available/$SERVER_NAME.conf" 2>&1)
		
		if [ $? != 0 ]; then
			echo "Couldn't copy the virtual host template. Aborting.... message:($STATUS)"
			exit 1
		else
			STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" "/etc/httpd/settings/sites-available/$SERVER_NAME.conf" 2>&1)
			
			if [ $? != 0 ]; then
				echo "Couldn't edit the virtual host. Aborting.... message:($STATUS)"
				exit 1
			else
				STATUS=$(ln -fs "../sites-available/$SERVER_NAME.conf" "/etc/httpd/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)
			
				if [ $? != 0 ]; then
					echo "Couldn't enable the virtual host. Aborting.... message:($STATUS)"
					exit 1
				fi
			fi
		fi
	else
		echo "WARNING: Apache virtual host already exists."
	fi

	# creating nginx virtual host
	echo "Creating nginx virtual host..."
	if [ ! -e "/etc/nginx/settings/sites-available/$SERVER_NAME.conf" ]; then
		STATUS=$(cp "$SCRIPT_DIR/templates/nginx/example.com.conf" "/etc/nginx/settings/sites-available/$SERVER_NAME.conf" 2>&1)
		
		if [ $? != 0 ]; then
			echo "Couldn't copy the virtual host template. Aborting.... message:($STATUS)"
			exit 1
		else
			STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" -e"s/\(listen\s\+\).*/\1$IP_PORT;/" "/etc/nginx/settings/sites-available/$SERVER_NAME.conf" 2>&1)
			
			if [ $? != 0 ]; then
				echo "Couldn't edit the virtual host. Aborting.... message:($STATUS)"
				exit 1
			else
				STATUS=$(ln -fs "../sites-available/$SERVER_NAME.conf" "/etc/nginx/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)
			
				if [ $? != 0 ]; then
					echo "Couldn't enable the virtual host. Aborting.... message:($STATUS)"
					exit 1
				fi
			fi
		fi
	else
		echo "WARNING: Nginx virtual host already exists."
	fi

	# copying default index page
	echo "Copying default index page..."
	STATUS=$(cp "$SCRIPT_DIR/templates/web/index.php" "$HOME/$SERVER_NAME/$WEB_ROOT_DIR/index.php" 2>&1)
	
	if [ $? != 0 ]; then
		echo "WARNING: Couldn't copy the default index page. message:($STATUS)"
	else
		STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" "$HOME/$SERVER_NAME/$WEB_ROOT_DIR/index.php" 2>&1)
		STATUS=$(chown "u-$SAFE_SERVER_NAME:u-$SAFE_SERVER_NAME" "$HOME/$SERVER_NAME/$WEB_ROOT_DIR/index.php" 2>&1)
		STATUS=$(chmod 644 "$HOME/$SERVER_NAME/$WEB_ROOT_DIR/index.php" 2>&1)
	fi
	
	# creating webalizer config
	echo "Creating webalizer config..."
	if [ ! -e "/etc/webalizer.d/sites-available/$SERVER_NAME.conf" ]; then
		STATUS=$(cp "$SCRIPT_DIR/templates/webalizer/example.com.conf" "/etc/webalizer.d/settings/sites-available/$SERVER_NAME.conf" 2>&1)
	
		if [ $? != 0 ]; then
			echo "WARNING: Couldn't copy the webalizer template. message:($STATUS)"
		else
			STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" "/etc/webalizer.d/settings/sites-available/$SERVER_NAME.conf" 2>&1)
			
			if [ $? != 0 ]; then
				echo "WARNING: Couldn't edit the webalizer config. message:($STATUS)"
			else
				STATUS=$(ln -fs "../sites-available/$SERVER_NAME.conf" "/etc/webalizer.d/settings/sites-enabled/$SERVER_NAME.conf" 2>&1)
			
				if [ $? != 0 ]; then
					echo "Couldn't enable the webalizer config. message:($STATUS)"
				fi
			fi
		fi
	else
		echo "WARNING: Webalizer config already exists."
	fi

	# Restarting servers
	echo "Restarting servers..."
	STATUS=$(sh "$SCRIPT_DIR/restart_servers.sh" 2>&1)
	
	if [ $? != 0 ]; then
		echo -e "$STATUS\nRestart failed..."
		exit 1
	else
		echo "$STATUS"
	fi

else
	echo "Directory ($HOME/$SERVER_TAG) already exists."
	exit 1
fi

exit 0
