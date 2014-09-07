#!/bin/bash

STATS_FOLDER="/opt/webpanel/wpdata/stats"

# go trough config files and generate stats
for SITE in /etc/webalizer.d/sites-enabled/*.conf;
do
	TAG=$(echo "$SITE" | cut -d '/' -f 5)
	TAG=$(echo "$TAG" | sed -r 's/\.conf$//')
	
	STATUS=$(mkdir -p "$STATS_FOLDER/$TAG" 2>&1)
	
	webalizer -c $SITE;
done

