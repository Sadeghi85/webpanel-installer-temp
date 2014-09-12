#!/bin/bash

# Allow only root execution
if (( $(id -u) != 0 )); then
    echo "This script requires root privileges"
    exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

STATUS=$(/sbin/service php-fpm start 2>&1)
STATUS=$(/sbin/service httpd start 2>&1)
STATUS=$(/sbin/service nginx start 2>&1)
STATUS=$(/sbin/service memcahced start 2>&1)
STATUS=$(/sbin/service mysqld start 2>&1)

exit 0
