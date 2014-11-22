#!/bin/bash

LOGS_DIRECTORY="/opt/webpanel/wpdata/logs"

TIME=$(date +%F-%H-%M-%S)
YEAR=$(echo "$TIME" | cut -d '-' -f 1)
MONTH=$(echo "$TIME" | cut -d '-' -f 2)
DAY=$(echo "$TIME" | cut -d '-' -f 3)
HOUR=$(echo "$TIME" | cut -d '-' -f 4)
MINUTE=$(echo "$TIME" | cut -d '-' -f 5)
SECOND=$(echo "$TIME" | cut -d '-' -f 6)

# Apache access log
for LOG in /var/log/httpd/*_access.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_apache_access.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_apache_access.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_apache_access.log" 2>&1)
	fi
done

# Apache error log
for LOG in /var/log/httpd/*_error.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_apache_error.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_apache_error.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_apache_error.log" 2>&1)
	fi
done

# Nginx access log
for LOG in /var/log/nginx/*_access.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_nginx_access.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_nginx_access.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_nginx_access.log" 2>&1)
	fi
done

# Nginx error log
for LOG in /var/log/nginx/*_error.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_nginx_error.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_nginx_error.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_nginx_error.log" 2>&1)
	fi
done

# PHP-FPM access log
for LOG in /var/log/php-fpm/*_access.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_access.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_access.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_php_access.log" 2>&1)
	fi
done

# PHP-FPM error log
for LOG in /var/log/php-fpm/*_error.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_error.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_error.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_php_error.log" 2>&1)
	fi
done

# PHP-FPM slow log
for LOG in /var/log/php-fpm/*_slow.log
do
	TAG=$(echo "$LOG" | cut -d '/' -f 5 | cut -d '_' -f 1)
	
	if [[ $TAG != "*" ]]; then
		BY_DATE="$LOGS_DIRECTORY/by_date/$YEAR/$MONTH/$DAY/$TAG"
		BY_SITE="$LOGS_DIRECTORY/by_site/$TAG/$YEAR/$MONTH/$DAY"
		STATUS=$(mkdir -p "$BY_DATE" 2>&1)
		STATUS=$(mkdir -p "$BY_SITE" 2>&1)
		STATUS=$(\mv "$LOG" "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_slow.log" 2>&1)
		STATUS=$(ln -fs "$BY_DATE/${HOUR}_${MINUTE}_${SECOND}_php_slow.log" "$BY_SITE/${HOUR}_${MINUTE}_${SECOND}_php_slow.log" 2>&1)
	fi
done

# Resetting log files
/sbin/service httpd reload > /dev/null 2>/dev/null || true
[ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
/bin/kill -SIGUSR1 `cat /var/run/php-fpm/php-fpm.pid 2>/dev/null` 2>/dev/null || true
