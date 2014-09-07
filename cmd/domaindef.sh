#!/bin/bash

# Check for a valid number of parameters or for the help command
if [ "$1" == '--help' -o "$#" != 2 ]; then
	printf "The usage for this command is:\n"
	printf "\tdomaindef.sh '\e[33mip_address:80\e[0m' '\e[32msite_name\e[0m'\n"
	printf "Where the variables are:\n"
	printf "\t\e[33mip_address\e[0m\tThe address of the server\n"
	printf "\t\e[32msite_name\e[0m\tThe name of the site to add\n"
	exit 0
fi

# Allow only root execution
if [ $(id -u) -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

HOME="/var/www/WebPanel"
WEBROOTDIR="web"
SHELL="/sbin/nologin"
SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

IP_PORT="$1"

if ! (echo "$IP_PORT" | grep -Pq "^(\d{1,3}\.){3}\d{1,3}:\d{2,5}$") then
	echo "IP_PORT ($IP_PORT) doesn't seem to be valid. Aborting...."
	exit 1
fi

SERVER_NAME=$(echo $2 | tr '[A-Z]' '[a-z]')

if ! (echo "$SERVER_NAME" | grep -Eq "^([a-z0-9][-a-z0-9]*\.)+[a-z]+$") then
	echo "SERVER_NAME ($SERVER_NAME) doesn't seem to be valid. Aborting...."
	exit 1
fi

SAFE_SERVER_NAME="${SERVER_NAME//./_}"
SAFE_SERVER_NAME="$(echo $SAFE_SERVER_NAME | cut -c1-30)" # truncate to 30 chars, so after adding u- it doesn't go beyond 32 char limit.

# check if ftp home already exists
if [ ! -e "$HOME/$SERVER_NAME" ]; then

	# creating ftp home
	echo "Creating ftp home..."
	STATUS=$(mkdir -p "$HOME/$SERVER_NAME" 2>&1)
	
	if [ $? != 0 ]; then
		echo "Couldn't create the ftp home directory. Aborting.... message:($STATUS)"
		exit 1
	fi

	# creating web root
	echo "Creating web root..."
	STATUS=$(mkdir -p "$HOME/$SERVER_NAME/$WEBROOTDIR" 2>&1)
	
	if [ $? != 0 ]; then
		echo "Couldn't create the web root directory. Aborting.... message:($STATUS)"
		exit 1
	fi

	# creating user
	echo "Creating user..."
	STATUS=$(id "u-$SAFE_SERVER_NAME" 2>&1)
	
	if [ $? == 0 ]; then
		echo "WARNING: The user already exists. message:($STATUS)"
	else
		STATUS=$(useradd "u-$SAFE_SERVER_NAME" --home "$HOME/$SERVER_NAME" --shell "$SHELL" 2>&1)
		
		if [ $? != 0 ]; then
			echo "Couldn't create the user. Aborting.... message:($STATUS)"
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
	STATUS=$(cp "$SCRIPT_DIR/templates/web/index.php" "$HOME/$SERVER_NAME/$WEBROOTDIR/index.php" 2>&1)
	
	if [ $? != 0 ]; then
		echo "WARNING: Couldn't copy the default index page. message:($STATUS)"
	else
		STATUS=$(sed -i -e"s/example\.com/$SERVER_NAME/g" "$HOME/$SERVER_NAME/$WEBROOTDIR/index.php" 2>&1)
		STATUS=$(chown "u-$SAFE_SERVER_NAME:u-$SAFE_SERVER_NAME" "$HOME/$SERVER_NAME/$WEBROOTDIR/index.php" 2>&1)
		STATUS=$(chmod 644 "$HOME/$SERVER_NAME/$WEBROOTDIR/index.php" 2>&1)
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
	echo "Home directory ($HOME/$SERVER_NAME) already exists. Aborting..."
	exit 1
fi

exit 0
