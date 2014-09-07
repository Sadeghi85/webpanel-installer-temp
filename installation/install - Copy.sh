#!/bin/bash

# Allow only root execution
if [ `id|sed -e s/uid=//g -e s/\(.*//g` -ne 0 ]; then
    echo "This script requires root privileges"
    exit 1
fi

SCRIPTDIR=$(dirname $0)
HOME="/var/www"

################## repos
\cp "$SCRIPTDIR/repos/CentOS-Base/etc/yum.repos.d/CentOS-Base.repo" "/etc/yum.repos.d/CentOS-Base.repo"

\cp "$SCRIPTDIR/repos/epel/etc/yum.repos.d/epel.repo" "/etc/yum.repos.d/epel.repo"
\cp "$SCRIPTDIR/repos/epel/etc/rpm/macros.ghc-srpm" "/etc/rpm/macros.ghc-srpm"

\cp "$SCRIPTDIR/repos/ius/etc/yum.repos.d/ius.repo" "/etc/yum.repos.d/ius.repo"
\cp "$SCRIPTDIR/repos/ius/etc/yum.repos.d/ius-archive.repo" "/etc/yum.repos.d/ius-archive.repo"

\cp "$SCRIPTDIR/repos/nginx/etc/yum.repos.d/nginx.repo" "/etc/yum.repos.d/nginx.repo"

\cp "$SCRIPTDIR/repos/rpmforge/etc/yum.repos.d/rpmforge.repo" "/etc/yum.repos.d/rpmforge.repo"

################## yum plugins
yum -y install yum-plugin-priorities yum-plugin-rpm-warm-cache yum-plugin-local yum-presto yum-plugin-fastestmirror yum-plugin-replace yum-cron

# installing packages
yum -y install iftop iotop bind-utils htop nmap mysql httpd php54 php54-bcmath php54-cli php54-common php54-fpm php54-gd php54-intl php54-mbstring php54-mcrypt php54-mysqlnd php54-odbc php54-pdo php54-pear php54-pecl-mongo php54-pecl-redis php54-pecl-zendopcache php54-tidy php54-xml perl-Net-SSLeay mod_fastcgi nginx quota redis28u webalizer

# installing mysql55
yum -y replace mysql --replace-with mysql55
yum -y install mysql55-server

# install from CentALT
yum -y install --enablerepo "CentALT" mod_rpaf

# Quota
HOMEESC=$(sed 's/[\*\.&\/]/\\&/g' <<<"$HOME")

if [ ! -e "/etc/fstab.$BEFOREBAK" ]; then
	\cp "/etc/fstab" "/etc/fstab.$BEFOREBAK"
	sed -i -r -e"s/($HOMEESC .*?defaults)/\1,usrjquota=aquota\.user,grpjquota=aquota\.group,jqfmt=vfsv0/I" "/etc/fstab"
	\cp "/etc/fstab" "/etc/fstab.$AFTERBAK"
fi

mount -o remount "$HOME" 1>/dev/null
quotacheck -avugm 1>/dev/null
quotaon -avug 1>/dev/null

# config after install
sh "$SCRIPTDIR/config_install.inc"