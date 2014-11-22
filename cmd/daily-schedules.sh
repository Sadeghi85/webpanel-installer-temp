#!/bin/bash

# Allow only root execution
if (( $(id -u) != 0 )); then
	echo "This script requires root privileges"
	exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

STATUS=$(sh "$SCRIPT_DIR/collect_stats.inc.sh" 2>&1)
STATUS=$(sh "$SCRIPT_DIR/collect_logs.inc.sh" 2>&1)


