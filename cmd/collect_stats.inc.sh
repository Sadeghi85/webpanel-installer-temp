#!/bin/bash

STATS_DIRECTORY="/opt/webpanel/wpdata/stats"

# go through config files and generate stats
for SITE in /etc/webalizer.d/settings/sites-enabled/*.conf;
do
	TAG=$(echo "$SITE" | cut -d '/' -f 6)
	TAG=$(echo "$TAG" | sed -r 's/\.conf$//')
	
	if [[ $TAG != "*" ]]; then
		STATUS=$(mkdir -p "$STATS_DIRECTORY/$TAG" 2>&1)
		/usr/bin/webalizer -c "$SITE"
	fi
done

